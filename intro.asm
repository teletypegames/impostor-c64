; -----------------------------------------------------------
; intro.asm - the front of the game: the title in block
; letters (window.intro.title.lua), the glitching TTG logo
; (window.intro.ttg.lua - press return three times during it
; for the test mode) and the brief about norman, typed out
; line by line (window.intro.brief.lua)
; -----------------------------------------------------------

TITLE_TIME = 150         ; 3 s
TTG_TIME   = 150
BRIEF_HOLD = 150         ; the brief stays 3 s once typed
BRIEF_ROW  = 7

title_init:
    lda #W_OTHER
    sta cur_win
    jsr blank_on
    lda #0
    jsr cls_all
    lda #<art_title
    sta ptr
    lda #>art_title
    sta ptr+1
    ldx #(40 - ART_TITLE_W) / 2
    ldy #(25 - ART_TITLE_H) / 2
    lda #C_ACCENT << 4
    jsr draw_art
    jsr blank_off
    jsr input_flush
    lda #TITLE_TIME
    sta in_timer
    +setupd title_update
    rts

title_update:
    lda in_new
    and #IN_FIRE
    bne tu_go
    dec in_timer
    bne tu_done
tu_go:
    +fadeto ttg_init
tu_done:
    rts

ttg_init:
    jsr blank_on
    lda #0
    jsr cls_all
    lda #<art_ttg
    sta ptr
    lda #>art_ttg
    sta ptr+1
    ldx #(40 - ART_TTG_W) / 2
    ldy #8
    lda #C_ACCENT << 4
    jsr draw_art
    +center 15, C_ACCENT << 4, txt_ttgname
    jsr blank_off
    jsr glitch_show
    jsr input_flush
    lda #0
    sta in_enters
    lda #TTG_TIME
    sta in_timer
    +setupd ttg_update
    rts

ttg_update:
    lda in_new           ; count the return presses
    and #IN_ENTER
    beq tg_noent
    inc in_enters
tg_noent:
    lda in_new
    and #IN_FIRE
    bne tg_end
    dec in_timer
    bne tg_done
tg_end:
    lda in_enters        ; exactly three: the test mode
    cmp #3
    bne tg_go
    lda #1
    sta test_mode
    lda #SFX_SUCCESS
    jsr sfx_play
tg_go:
    jsr glitch_restore
    jsr glitch_hide
    +fadeto brief_init
tg_done:
    rts

brief_init:
    jsr blank_on
    lda #0
    jsr cls_all
    jsr blank_off
    jsr input_flush
    lda #<brief_text
    sta txt
    lda #>brief_text
    sta txt+1
    ldy #0
    lda (txt),y
    sta br_left
    inc txt
    bne bi_d
    inc txt+1
bi_d:
    lda txt
    sta br_ptr
    lda txt+1
    sta br_ptr+1
    lda #BRIEF_ROW
    sta br_row
    lda #0
    sta br_ci
    sta br_wait
    +setupd brief_update
    rts

brief_update:
    lda in_new
    and #IN_FIRE
    bne bu_menu
    lda br_left
    bne bu_type
    dec in_timer         ; all typed: hold, then the menu
    bne bu_done
bu_menu:
    +fadeto menu_init
bu_type:
    lda br_wait
    beq bu_go
    dec br_wait
bu_done:
    rts
bu_go:
    lda br_ptr
    sta txt
    lda br_ptr+1
    sta txt+1
    lda br_ci
    bne bu_char
    jsr text_len         ; a new line: left edge of the centered text
    sta zt0
    lda #40
    sec
    sbc zt0
    lsr
    sta br_col
bu_char:
    ldy br_ci
    lda (txt),y
    beq bu_eol
    pha
    lda br_col
    clc
    adc br_ci
    tax
    ldy br_row
    lda #C_ACCENT << 4
    sta pcolor
    pla
    jsr char_at
    inc br_ci
    lda #1
    sta br_wait
    rts
bu_eol:
    ldy br_ci
    iny
    tya
    clc
    adc br_ptr
    sta br_ptr
    bcc bu_e1
    inc br_ptr+1
bu_e1:
    lda #0
    sta br_ci
    inc br_row
    lda #6
    sta br_wait
    dec br_left
    bne bu_done
    lda #BRIEF_HOLD
    sta in_timer
    rts

; ---- texts ----
txt_ttgname: !scr "Teletype Games", 0

; ---- variables ----
in_timer:  !byte 0
in_enters: !byte 0
br_left:   !byte 0
br_ptr:    !word 0
br_row:    !byte 0
br_col:    !byte 0
br_ci:     !byte 0
br_wait:   !byte 0
