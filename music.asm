; -----------------------------------------------------------
; music.asm - three-voice music player for the original's
; TIC-80 tracks (gen_music.asm, converted note for note by
; tools/build_data.py): the office song (room_work), the work
; minigame (activity_work) and the mysterious man (mystery)
;
; as on the TIC-80, the sound effects take the first voice:
; while one sounds, the music's channel 0 keeps counting but
; leaves the SID voice alone
;
; a tune: frames per row, three instruments, three patterns;
; a pattern is note/length pairs (length in rows) closed by
; MEND, and it starts over at its end
;
; note byte: (octave + 1) in the high nibble, semitone in the
; low one; MREST silences the voice, MTIE lets it ring on
; -----------------------------------------------------------

MREST = 0                ; rest: gate off, the release fades it
MTIE  = 1                ; the note goes on, no new attack
MEND  = $ff              ; end of pattern

; ---- instruments (the original's SFX slots) ----
INS_SINE  = 0            ; sfx 59: its smooth wave, held at full
INS_PULSE = 1            ; sfx 56: a bright wave fading in ~0.2 s
INS_NOISE = 2            ; sfx 61: the noise drum, a short decay

ins_ctrl: !byte $11, $41, $81
ins_ad:   !byte $00, $06, $04
ins_sr:   !byte $f0, $00, $00
ins_pw:   !byte $08, $04, $08

!src "gen_music.asm"

tunelo: !byte <tune_work, <tune_ddr, <tune_mystery
tunehi: !byte >tune_work, >tune_ddr, >tune_mystery

; ============================================================
; driver
; ============================================================

; ---- silence the music, forget the tune ----
music_init:
    lda #$ff
    sta mus_tune
    ; fall through

; ---- stop the music, but remember which tune it was ----
music_stop:
    lda #0
    sta mus_on
    sta SID+$0b          ; voices 2 and 3: waveform, gate, pitch
    sta SID+$07
    sta SID+$08
    sta SID+$12
    sta SID+$0e
    sta SID+$0f
    lda sfx_timer        ; voice 1 too, unless an effect sounds
    bne ms_done
    sta SID+$04
    sta SID+$00
    sta SID+$01
ms_done:
    rts

; ---- A = tune id: start it, unless it is already running
; at the same tempo (mus_slow = extra frames per row) ----
music_play:
    cmp mus_tune
    bne music_start
    ldy mus_on
    beq music_start
    ldy mus_slow
    cpy mus_curslow
    beq mp_done          ; the same tune is on: let it run on
music_start:
    sta mus_tune
    tax
    lda tunelo,x
    sta musptr
    lda tunehi,x
    sta musptr+1
    ldy #0
    lda (musptr),y       ; frames per row
    clc
    adc mus_slow
    sta mus_speed
    lda mus_slow
    sta mus_curslow
    ldx #0
ms_ch:
    txa
    clc
    adc #1
    tay
    lda (musptr),y       ; the channel's instrument
    tay
    lda ins_ctrl,y
    sta chctrl,x
    lda ins_ad,y
    sta chad,x
    lda ins_sr,y
    sta chsr,x
    lda ins_pw,y
    sta chpw,x
    txa
    asl
    clc
    adc #4
    tay
    lda (musptr),y       ; the channel's pattern
    sta patstlo,x
    sta patlo,x
    iny
    lda (musptr),y
    sta patsthi,x
    sta pathi,x
    lda #1
    sta chdur,x          ; the first event plays on the first row
    inx
    cpx #3
    bne ms_ch
    lda #1
    sta mus_tick
    sta mus_on
mp_done:
    rts

; ============================================================
; once a frame from the main loop
; ============================================================
music_update:
    lda mus_on
    beq mu_off
    dec mus_tick
    bne mu_off
    lda mus_speed
    sta mus_tick
    ldx #2
mu_rows:
    dec chdur,x
    bne mu_next
    jsr mx_fetch
mu_next:
    dex
    bpl mu_rows
mu_off:
    rts

; ---- channel X: the next event of its pattern ----
mx_fetch:
    lda patlo,x
    sta musptr
    lda pathi,x
    sta musptr+1
    ldy #0
    lda (musptr),y
    cmp #MEND
    bne mx_event
    lda patstlo,x        ; the pattern starts over
    sta patlo,x
    sta musptr
    lda patsthi,x
    sta pathi,x
    sta musptr+1
    lda (musptr),y
mx_event:
    sta mtmp
    iny
    lda (musptr),y
    sta chdur,x
    lda patlo,x
    clc
    adc #2
    sta patlo,x
    bcc mx_nc
    inc pathi,x
mx_nc:
    lda mtmp
    cmp #MTIE
    beq mx_done
    cpx #0               ; voice 1 belongs to a sounding effect
    bne mx_play
    ldy sfx_timer
    bne mx_done
mx_play:
    ldy chofs,x
    cmp #MREST
    bne mx_note
    lda chctrl,x         ; gate down, the release carries it out
    and #$fe
    sta SID+4,y
mx_done:
    rts
mx_note:
    pha
    and #$0f             ; the semitone picks the top octave's pitch
    tay
    lda notefl,y
    sta chflo,x
    lda notefh,y
    sta chfhi,x
    pla
    lsr
    lsr
    lsr
    lsr                  ; octave + 1: shift down from octave 6
    sta mtmp
    lda #7
    sec
    sbc mtmp
    beq mx_gate
    tay
mx_oct:
    lsr chfhi,x
    ror chflo,x
    dey
    bne mx_oct
mx_gate:
    ldy chofs,x
    lda chad,x
    sta SID+5,y
    lda chsr,x
    sta SID+6,y
    lda #0
    sta SID+2,y
    lda chpw,x
    sta SID+3,y
    lda #0
    sta SID+4,y          ; gate down first: a clean retrigger
    lda chflo,x
    sta SID+0,y
    lda chfhi,x
    sta SID+1,y
    lda chctrl,x
    sta SID+4,y          ; waveform + gate: the note sounds
    rts

; ============================================================
; tables
; ============================================================

; ---- octave 6, c-6 to b-6; the lower octaves are these
; halved, which the note code shifts out ----
notefl: !byte $9c, $c0, $23, $c8, $b4, $eb, $72, $4c, $80, $12, $08, $68
notefh: !byte $45, $49, $4e, $52, $57, $5c, $62, $68, $6e, $75, $7c, $83

; ---- the voices' register offsets from $d400 ----
chofs:  !byte $00, $07, $0e

; ---- the commute glitch slows the office song: TIC-80 speed 6
; at levels 0-1, then 2 more ticks a row per level, as extra
; PAL frames over its own 4 ----
cg_slow: !byte 1, 1, 3, 4, 6, 8, 9, 9

; ============================================================
; player variables
; ============================================================
mus_tune:  !byte $ff     ; the tune that plays (or played last)
mus_on:    !byte 0       ; 1 while a tune runs
mus_slow:  !byte 0       ; extra frames per row for the next play
mus_curslow: !byte 0     ; the drag the running tune got
mus_speed: !byte 5       ; frames per row
mus_tick:  !byte 1       ; frames left of this row
mtmp:      !byte 0       ; scratch

patstlo: !byte 0, 0, 0   ; the start of each channel's pattern
patsthi: !byte 0, 0, 0
patlo:   !byte 0, 0, 0   ; the next event
pathi:   !byte 0, 0, 0
chdur:   !byte 0, 0, 0   ; rows left of the current event
chflo:   !byte 0, 0, 0   ; the note's pitch
chfhi:   !byte 0, 0, 0
chctrl:  !byte 0, 0, 0   ; the instrument, unpacked per channel
chad:    !byte 0, 0, 0
chsr:    !byte 0, 0, 0
chpw:    !byte 0, 0, 0
