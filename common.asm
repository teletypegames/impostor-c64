; -----------------------------------------------------------
; common.asm - input, random numbers and small math shared
; by every state
;
; controls: joystick in either port, or the keyboard:
;   w a s d / cursor keys   move (shift + cursor: up / left)
;   space / z / fire        select (the original's Z button)
;   del / x / <- / stop     back (the original's B button)
;   return                  counted by the TTG intro (test mode)
; -----------------------------------------------------------

; ---- scan everything once a frame: in_cur = held, in_new =
; pressed this frame, in_rep = new or auto-repeated up/down ----
input_scan:
    lda in_cur
    sta in_prev
!ifdef SCRIPT {
    jsr script_input     ; test builds: the joystick comes from a script
    jmp is_store
}
    lda #$ff             ; no column selected: port B = joystick 1
    sta CIA1_PA
    lda CIA1_PB
    eor #$ff
    and #$1f
    sta jmask            ; those rows are not keys right now
    sta zt0
    lda CIA1_PA          ; joystick 2
    eor #$ff
    and #$1f
    ora zt0
    sta zt0
    ; column 0: del (row 0), return (1), crsr right (2), crsr down (7)
    lda #$fe
    jsr key_col
    sta zt1
    and #$01
    beq is_nodel
    lda zt0
    ora #IN_BACK
    sta zt0
is_nodel:
    lda zt1
    and #$02
    beq is_noret
    lda zt0
    ora #IN_ENTER
    sta zt0
is_noret:
    jsr shift_held
    sta zt2
    lda zt1
    and #$04
    beq is_nocr
    lda zt2
    beq is_right
    lda #IN_LEFT
    bne is_cr
is_right:
    lda #IN_RIGHT
is_cr:
    ora zt0
    sta zt0
is_nocr:
    lda zt1
    and #$80
    beq is_nocd
    lda zt2
    beq is_down
    lda #IN_UP
    bne is_cd
is_down:
    lda #IN_DOWN
is_cd:
    ora zt0
    sta zt0
is_nocd:
    ; column 1: w (row 1), a (2), z (4), s (5)
    lda #$fd
    jsr key_col
    sta zt1
    and #$02
    beq is_now
    lda zt0
    ora #IN_UP
    sta zt0
is_now:
    lda zt1
    and #$04
    beq is_noa
    lda zt0
    ora #IN_LEFT
    sta zt0
is_noa:
    lda zt1
    and #$10
    beq is_noz
    lda zt0
    ora #IN_FIRE
    sta zt0
is_noz:
    lda zt1
    and #$20
    beq is_nos
    lda zt0
    ora #IN_DOWN
    sta zt0
is_nos:
    ; column 2: d (row 2), x (7)
    lda #$fb
    jsr key_col
    sta zt1
    and #$04
    beq is_nod
    lda zt0
    ora #IN_RIGHT
    sta zt0
is_nod:
    lda zt1
    and #$80
    beq is_nox
    lda zt0
    ora #IN_BACK
    sta zt0
is_nox:
    ; column 7: <- (row 1), space (4), run/stop (7)
    lda #$7f
    jsr key_col
    sta zt1
    and #$10
    beq is_nosp
    lda zt0
    ora #IN_FIRE
    sta zt0
is_nosp:
    lda zt1
    and #$82
    beq is_nobk
    lda zt0
    ora #IN_BACK
    sta zt0
is_nobk:
    lda #$ff
    sta CIA1_PA
    lda zt0
is_store:
    sta in_cur
    lda in_prev
    eor #$ff
    and in_cur
    sta in_new
    ; up/down auto-repeat (btnp 20, 4 at 60 Hz)
    lda in_new
    sta in_rep
    lda in_cur
    and #IN_UP | IN_DOWN
    beq is_norep
    cmp rep_dir
    beq is_held
    sta rep_dir
    lda #17
    sta rep_timer
    rts
is_held:
    dec rep_timer
    bne is_repd
    lda #3
    sta rep_timer
    lda in_rep
    ora rep_dir
    sta in_rep
is_repd:
    rts
is_norep:
    sta rep_dir
    rts

; ---- A = column mask -> A = rows held (active high),
; joystick 1's rows masked off ----
key_col:
    sta CIA1_PA
    lda CIA1_PB
    ora jmask
    eor #$ff
    rts

; ---- either shift key held? A != 0 ----
shift_held:
    lda #$fd             ; left shift: column 1, row 7
    jsr key_col
    and #$80
    bne sh_yes
    lda #$bf             ; right shift: column 6, row 4
    jsr key_col
    and #$10
sh_yes:
    rts

; ---- forget what is held, so a press carried over from the
; previous screen does not count as new ----
input_flush:
    lda #$ff
    sta in_cur
    lda #0
    sta in_new
    sta in_rep
    rts

; ---- RNG: 8-bit LFSR stirred with the free-running CIA timer ----
rand8:
    lda seed
    asl
    bcc r8_tap
    eor #$1d
r8_tap:
    eor CIA1_TA
    sta seed
    rts

; ---- A = n -> A = random 0..n-1 ----
rand_below:
    sta zt7
    jsr rand8
    tax
    lda zt7
    jsr mul8             ; (rand * n) >> 8
    lda mulhi
    rts

; ---- A * X -> mullo / mulhi ----
mul8:
    sta mulhi
    stx mullo
    lda #0
    ldx #8
    lsr mullo
m8_lp:
    bcc m8_no
    clc
    adc mulhi
m8_no:
    ror
    ror mullo
    dex
    bne m8_lp
    sta mulhi
    rts

; ---- 16 / 8 division: divlo/divhi / A -> divlo/divhi, rest in A ----
div16:
    sta divby
    lda #0
    ldx #16
d16_lp:
    asl divlo
    rol divhi
    rol
    bcs d16_sub
    cmp divby
    bcc d16_no
d16_sub:
    sbc divby
    inc divlo
d16_no:
    dex
    bne d16_lp
    rts

; ---- shared variables ----
in_cur:    !byte 0
in_prev:   !byte 0
in_new:    !byte 0
in_rep:    !byte 0
rep_dir:   !byte 0
rep_timer: !byte 0
jmask:     !byte 0
seed:      !byte $a7
mullo:     !byte 0
mulhi:     !byte 0
divlo:     !byte 0
divhi:     !byte 0
divby:     !byte 0
framectr:  !byte 0
