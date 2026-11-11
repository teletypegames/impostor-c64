; -----------------------------------------------------------
; sound.asm - single-voice SFX driver (blessing of ra's):
; each effect is a waveform + start pitch + per-frame pitch
; slide + duration, played on SID voice 1; the alarm clock
; and the bloop also ring in bursts (the gate opens and shuts)
; -----------------------------------------------------------

sfx_init:
    lda #$0f             ; full volume, no filter
    sta SID_VOL
    lda #0
    sta SID_V1CR
    sta SID_V1FH
    sta SID_V1FL
    sta sfx_timer
    rts

; ---- start effect A ----
sfx_play:
    tax
    lda sfxfreq,x
    sta sfx_pitch
    ; fall through

; ---- start effect X at the pitch in sfx_pitch ----
sfx_play_at:
    lda #0
    sta SID_V1CR         ; retrigger the envelope cleanly
    lda sfxad,x
    sta SID_V1AD
    lda sfxsr,x
    sta SID_V1SR
    lda #0
    sta SID_V1FL
    lda sfx_pitch
    sta SID_V1FH
    sta sfx_fh
    lda #$08             ; 50% pulse width, if a pulse wave is used
    sta SID_V1PH
    lda #0
    sta SID_V1PL
    lda sfxctrl,x
    sta SID_V1CR
    sta sfx_ctrl
    lda sfxslide,x
    sta sfx_slide
    lda sfxgate,x
    sta sfx_gate
    lda sfxdur,x
    sta sfx_timer
    rts

; ---- the DDR arrow hit: A = pitch (high frequency byte) ----
sfx_hit:
    sta sfx_pitch
    ldx #SFX_HIT
    jmp sfx_play_at

; ---- called once per frame by the main loop ----
sfx_update:
    lda sfx_timer
    beq su_idle
    dec sfx_timer
    bne su_slide
    lda #0               ; time is up: hard-silence the voice
    sta SID_V1CR
    sta SID_V1FH
    sta SID_V1FL
    rts
su_slide:
    lda sfx_gate         ; the alarm and the bloop ring in bursts
    beq su_bend
    and sfx_timer
    beq su_gon
    lda sfx_ctrl
    and #$fe
    sta SID_V1CR
    rts
su_gon:
    lda sfx_ctrl
    sta SID_V1CR
    rts
su_bend:
    lda sfx_fh           ; bend the pitch by the slide value
    clc
    adc sfx_slide
    sta sfx_fh
    sta SID_V1FH
su_idle:
    rts

; ---- effect tables, after the original's TIC-80 SFX:
; select (17, C-7), deselect (18, C-7), beep (19, C-6),
; success (16, C-7), bloop (21, C-3), alarm (34, C-5),
; drum (61, C-6: the mash press), hit (56: the arrow's note) ----
sfxfreq:  !byte $8b, $8b, $45, $8b, $08, $22, $45, $30
sfxslide: !byte $00, $00, $00, $00, $00, $00, $00, $00
sfxctrl:  !byte $11, $11, $11, $41, $41, $21, $81, $41
sfxad:    !byte $09, $08, $07, $0a, $00, $00, $04, $06
sfxsr:    !byte $00, $00, $00, $00, $f0, $f0, $00, $00
sfxdur:   !byte $19, $19, $10, $32, $32, $c8, $06, $0c
sfxgate:  !byte $00, $00, $00, $00, $04, $08, $00, $00

; ---- driver variables ----
sfx_timer: !byte 0       ; frames left of the current effect
sfx_fh:    !byte 0       ; frequency high byte shadow
sfx_slide: !byte 0       ; signed per-frame pitch step
sfx_ctrl:  !byte 0       ; control register shadow
sfx_gate:  !byte 0       ; burst mask (alarm, bloop), 0 = none
sfx_pitch: !byte 0       ; start pitch of the next effect
