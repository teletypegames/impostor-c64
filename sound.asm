; -----------------------------------------------------------
; sound.asm - single-voice SFX driver (blessing of ra's):
; each effect is a waveform + start pitch + per-frame pitch
; slide + duration, played on SID voice 1; the alarm clock
; also warbles (its pitch flips every few frames)
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
    lda sfxwarb,x
    sta sfx_warb
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
    lda sfx_warb
    beq su_bend
    lda sfx_timer        ; the alarm: flip the pitch every 4 frames
    and #3
    bne su_bend
    lda sfx_fh
    eor sfx_warb
    sta sfx_fh
    sta SID_V1FH
    lda sfx_timer        ; and ring in bursts
    and #$10
    beq su_gate
    lda sfx_ctrl
    and #$fe
    sta SID_V1CR
    rts
su_gate:
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

; ---- effect tables:
; select, deselect, beep, success, bloop, alarm, drum, hit ----
sfxfreq:  !byte $30, $40, $48, $28, $08, $50, $60, $30
sfxslide: !byte $04, $fc, $00, $02, $ff, $00, $fa, $00
sfxctrl:  !byte $21, $21, $11, $11, $21, $41, $81, $11
sfxad:    !byte $08, $08, $04, $0a, $0a, $00, $04, $08
sfxdur:   !byte $0a, $0a, $04, $28, $14, $c8, $03, $0c
sfxwarb:  !byte $00, $00, $00, $00, $00, $0c, $00, $00
sfxsr:    !byte $00, $00, $00, $00, $00, $f0, $00, $00

; ---- driver variables ----
sfx_timer: !byte 0       ; frames left of the current effect
sfx_fh:    !byte 0       ; frequency high byte shadow
sfx_slide: !byte 0       ; signed per-frame pitch step
sfx_ctrl:  !byte 0       ; control register shadow
sfx_warb:  !byte 0       ; pitch flip mask (the alarm), 0 = none
sfx_pitch: !byte 0       ; start pitch of the next effect
