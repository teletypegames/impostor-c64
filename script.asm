; -----------------------------------------------------------
; script.asm - test builds only (acme -DSCRIPT=n): the input
; comes from a script instead of the joystick; an entry is
; the frames to wait, then the bits held for 3 frames; a
; zero wait ends the script
; -----------------------------------------------------------

S_U = IN_UP
S_D = IN_DOWN
S_L = IN_LEFT
S_R = IN_RIGHT
S_F = IN_FIRE
S_B = IN_BACK

script_input:
    lda sc_hold
    beq si_wait
    dec sc_hold
    lda sc_bits
    rts
si_wait:
    lda sc_started
    bne si_run
    lda #1
    sta sc_started
    lda #<script_data
    sta sc_ptr
    lda #>script_data
    sta sc_ptr+1
    jsr si_load
si_run:
    lda sc_delay         ; 0: the script is over
    beq si_none
    dec sc_delay
    bne si_none
    lda sc_next          ; the press starts next frame
    sta sc_bits
    lda #3
    sta sc_hold
    lda sc_ptr
    clc
    adc #2
    sta sc_ptr
    bcc si_ld
    inc sc_ptr+1
si_ld:
    jsr si_load
si_none:
    lda #0
    rts
si_load:
    lda sc_ptr
    sta ptr2
    lda sc_ptr+1
    sta ptr2+1
    ldy #0
    lda (ptr2),y
    sta sc_delay
    iny
    lda (ptr2),y
    sta sc_next
    rts

sc_started: !byte 0
sc_ptr:     !word 0
sc_delay:   !byte 0
sc_hold:    !byte 0
sc_bits:    !byte 0
sc_next:    !byte 0

script_data:
!if SCRIPT = 1 {
    ; office: from home walk to the office, go in
    !byte 30, S_R, 20, S_F        ; walk to office
    !byte 60, S_F                 ; go to office
    !byte 0, 0
}
!if SCRIPT = 2 {
    ; walk to office, then talk to the homeless guy
    !byte 30, S_R, 20, S_F
    !byte 60, S_R, 20, S_F
    !byte 0, 0
}
!if SCRIPT = 3 {
    ; office, do work (DDR)
    !byte 30, S_R, 20, S_F
    !byte 60, S_F
    !byte 60, S_F
    !byte 0, 0
}
!if SCRIPT = 4 {
    ; toilet stat screen
    !byte 30, S_F
    !byte 0, 0
}
!if SCRIPT = 5 {
    ; office, coffee with a coworker
    !byte 30, S_R, 20, S_F
    !byte 60, S_F
    !byte 60, S_R, 15, S_R, 20, S_F
    !byte 0, 0
}
!if SCRIPT = 6 {
    ; menu: new game, the name, the man's first text
    !byte 30, S_F                 ; new game
    !byte 50, S_U, 10, S_F        ; B
    !byte 10, S_F, 10, S_F        ; A, A
    !byte 20, S_F                 ; save -> new game
    !byte 0, 0
}
!if SCRIPT = 7 {
    ; ... skip the text, mash the alarm away
    !byte 30, S_F
    !byte 50, S_U, 10, S_F
    !byte 10, S_F, 10, S_F
    !byte 20, S_F
    !byte 200, S_F                ; skip the text
    !byte 60, S_F, 5, S_F, 5, S_F, 5, S_F, 5, S_F, 5, S_F
    !byte 0, 0
}
!if SCRIPT = 8 {
    ; new game, wait the text out, mash until awake
    !byte 30, S_F
    !byte 50, S_U, 10, S_F
    !byte 10, S_F, 10, S_F
    !byte 20, S_F
    !byte 250, 0, 250, 0, 120, 0
    !for i, 1, 40 { !byte 4, S_F }
    !byte 0, 0
}
!if SCRIPT = 9 {
    ; a whole day (with -DQUICKMINI): work, home, sleep
    !byte 30, S_R, 20, S_F        ; walk to office
    !byte 60, S_F                 ; go to office
    !byte 60, S_F                 ; do work -> DDR won at once
    !byte 250, 0                  ; the success box, the office
    !byte 30, S_R, 20, S_F        ; walk home
    !byte 60, S_F                 ; go home
    !byte 60, S_R, 15, S_R, 20, S_F  ; go to sleep -> rhythm
    !for i, 1, 30 { !byte 9, S_F }   ; one hit when the line is in
    !byte 0, 0
}
!if SCRIPT = 10 {
    ; menu: new game -> the name screen
    !byte 30, S_F
    !byte 40, S_U, 6, S_U, 6, S_F
    !byte 0, 0
}
!if SCRIPT = 11 {
    ; menu: controls
    !byte 30, S_D, 10, S_F
    !byte 0, 0
}
!if SCRIPT = 12 {
    ; ascension 4 (-DAUTOGAME=4 -DQUICKMINI): work, home, sleep,
    ; then stay in bed at the choice
    !byte 30, S_R, 20, S_F
    !byte 60, S_F
    !byte 60, S_F
    !byte 250, 0
    !byte 30, S_R, 20, S_F
    !byte 60, S_F
    !byte 60, S_R, 15, S_R, 20, S_F
    !byte 30, S_F                 ; asleep
    !byte 250, 0, 100, 0          ; success box, the day card
    !byte 60, S_D                 ; stay in bed
    !byte 0, 0
}
!if SCRIPT = 13 {
    ; ascension 7: walk to office three times (glitch level 3)
    !byte 30, S_R, 20, S_F        ; walk to office
    !byte 60, S_F                 ; office: cg 1
    !byte 60, S_R, 20, S_F        ; walk home
    !byte 60, S_R, 20, S_F        ; go to office: cg 2
    !byte 60, S_R, 20, S_F
    !byte 60, S_R, 20, S_F        ; cg 3
    !byte 60, S_R, 20, S_F
    !byte 60, S_R, 20, S_F        ; cg 4
    !byte 0, 0
}
!if SCRIPT = 14 {
    ; ascension 7: the commute glitch, level by level, to the truth
    !byte 30, S_R, 20, S_F        ; home -> walk to office
    !byte 80, S_F                 ; -> office (cg 1)
    !byte 80, S_R, 20, S_F        ; -> walk home
    !byte 80, S_F                 ; -> office (cg 2)
    !byte 80, S_R, 20, S_F
    !byte 80, S_F                 ; cg 3
    !byte 80, S_R, 20, S_F
    !byte 80, S_F                 ; cg 4: shot A here
    !byte 250, 0
    !byte 80, S_R, 20, S_F        ; walk home
    !byte 80, S_F                 ; cg 5
    !byte 80, S_F                 ; walk home
    !byte 80, S_F                 ; cg 6
    !byte 80, S_F                 ; walk home: sumphore, truth
    !byte 80, S_R, 20, S_F        ; go to truth: the flash, the office
    !byte 0, 0
}
!if SCRIPT = 15 {
    ; ascension 8 (-DQUICKMINI): work, home, break the loop,
    ; the man's last words, BREAK, the ending
    !byte 30, S_R, 20, S_F        ; walk to office
    !byte 80, S_F                 ; office
    !byte 80, S_F                 ; do work
    !byte 250, 0
    !byte 60, S_R, 20, S_F        ; walk home
    !byte 80, S_F                 ; go home
    !byte 80, S_R, 15, S_R, 20, S_F  ; break the loop -> rhythm
    !byte 30, S_F                 ; asleep
    !for i, 1, 9 { !byte 250, 0 } ; the last words
    !byte 30, S_F                 ; the day card
    !byte 80, S_F                 ; BREAK
    !byte 0, 0
}
