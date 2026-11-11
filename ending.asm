; -----------------------------------------------------------
; ending.asm - the level-up flash (Ascension.start_flash),
; game over (window.gameover.lua), the good ending with the
; player's code (window.end.lua) and the test mode's "to be
; continued" card (window.continued.lua)
; -----------------------------------------------------------

; ============================================================
; the level-up flash: the screen pulses white / light grey
; for two seconds, then the routine in A/X takes over and
; the newest ASCENSION letter fades in
; ============================================================
flash_start:
    sta flret
    stx flret+1
    jsr fx_restore
    lda #W_OTHER
    sta cur_win
    lda #0
    sta SPR_EN
    sta fl_t
    jsr blank_on
    lda #BLACK << 4 | WHITE
    sta fl_col
    jsr cls_all
    lda #<txt_levelup
    sta txt
    lda #>txt_levelup
    sta txt+1
    ldy #9
    lda #BLACK << 4 | WHITE
    jsr print_big_center
    +center 13, BLACK << 4 | WHITE, txt_closer
    jsr blank_off
    +setupd flash_update
    rts

flash_update:
    inc fl_t
    lda fl_t
    cmp #FLASHFRAMES
    bcs fl_end
    ; six pulses: light grey at the edges of each, white inside
    ldx #0
fl_mod:
    cmp #17
    bcc fl_m
    sbc #17
    bne fl_mod
fl_m:
    ldx #BLACK << 4 | LGREY
    cmp #3
    bcc fl_set
    cmp #14
    bcs fl_set
    ldx #BLACK << 4 | WHITE
fl_set:
    cpx fl_col
    beq fl_done
    stx fl_col
    txa
    ldx #0
fl_fill:
    sta SCRRAM,x
    sta SCRRAM+$100,x
    sta SCRRAM+$200,x
    sta SCRRAM+$2e8,x
    inx
    bne fl_fill
fl_done:
    rts
fl_end:
    lda #ASCFADE
    sta asc_fade
    lda #1
    sta hud_dirty
    jsr input_flush
    jmp (flret)

; ============================================================
; game over: the meter that broke norman (or the hundred
; days) names the reason; fire starts over from the menu
; ============================================================
gameover_init:
    lda #0
    sta in_game
    sta SPR_EN
    sta flick_on
    jsr music_stop
    jsr blank_on
    lda #0
    jsr cls_all
    lda #<art_gameover
    sta ptr
    lda #>art_gameover
    sta ptr+1
    ldx #(40 - ART_GAMEOVER_W) / 2
    ldy #3
    lda #LRED << 4
    jsr draw_art
    ldx go_reason
    lda goreasonlo,x
    sta txt
    lda goreasonhi,x
    sta txt+1
    ldy #17
    lda #WHITE << 4
    jsr print_center
    +center 22, LGREY << 4, txt_restart
    jsr blank_off
    jsr glitch_show
    jsr input_flush
    lda #W_OTHER
    sta cur_win
    +setupd gameover_update
    rts

gameover_update:
    lda in_new
    and #IN_FIRE
    beq gou_done
    jsr ctx_reset
    +fadeto menu_init
gou_done:
    rts

goreasonlo: !byte <txt_r_days, <txt_r_ism, <txt_r_bm, <txt_r_days
goreasonhi: !byte >txt_r_days, >txt_r_ism, >txt_r_bm, >txt_r_days

; ============================================================
; the good ending: the code to take to the BBS
; ============================================================
end_init:
    lda #0
    sta in_game
    sta SPR_EN
    sta flick_on
    jsr glitch_hide
    jsr music_stop
    jsr code_make
    jsr blank_on
    lda #0
    jsr cls_all
    +center 1, C_ACCENT << 4, txt_goodend
    ; Congratulations, NAME!
    lda #<txt_congrats
    sta txt
    lda #>txt_congrats
    sta txt+1
    ldx #9
    ldy #3
    lda #WHITE << 4
    jsr print_at
    lda #<player_name
    sta txt
    lda #>player_name
    sta txt+1
    ldx #26
    ldy #3
    lda #WHITE << 4
    jsr print_at
    lda #$21             ; !
    ldx #29
    ldy #3
    jsr char_at
    ; the code in a box
    lda #9
    sta fr_col
    lda #5
    sta fr_row
    lda #22
    sta fr_w
    lda #6
    sta fr_h
    lda #BLUE << 4
    jsr draw_box
    +center 6, LGREY << 4, txt_yourcode
    lda #<code_txt
    sta txt
    lda #>code_txt
    sta txt+1
    ldy #8
    lda #WHITE << 4
    jsr print_big_center
    +center 12, C_ITEM << 4, txt_writeit
    lda #0               ; two thin rules
    sta fr_col
    lda #14
    sta fr_row
    lda #40
    sta fr_w
    lda #1
    sta fr_h
    lda #$10
    sta fr_byte
    lda #DGREY << 4
    sta fr_color
    jsr end_rule
    +center 15, LGREY << 4, txt_telnet
    +center 17, WHITE << 4, txt_telnet2
    lda #19
    sta fr_row
    jsr end_rule
    +center 21, DGREY << 4, txt_tomenu
    jsr blank_off
    jsr input_flush
    lda #W_OTHER
    sta cur_win
    +setupd end_update
    rts

; ---- a horizontal rule across fr_row, columns 2-37 ----
end_rule:
    lda #2
    sta fr_col
    lda #36
    sta fr_w
    lda #1
    sta fr_h
    lda #$ff
    sta fr_byte
    lda #DGREY << 4
    sta fr_color
    jsr fill_rect
    ; only the middle line: clear the others
    ldx #2
    ldy fr_row
    jsr cell_ptrs
    ldx #36
er_cell:
    ldy #7
er_b:
    lda #0
    cpy #4
    bne er_put
    lda #$ff
er_put:
    sta (dst),y
    dey
    bpl er_b
    jsr adv_cell
    dex
    bne er_cell
    rts

end_update:
    lda in_new
    and #IN_FIRE
    beq eu_done
    jsr ctx_reset
    +fadeto menu_init
eu_done:
    rts

; ============================================================
; to be continued (test mode)
; ============================================================
continued_init:
    jsr blank_on
    lda #0
    jsr cls_all
    lda #<art_continued
    sta ptr
    lda #>art_continued
    sta ptr+1
    ldx #(40 - ART_CONTINUED_W) / 2
    ldy #7
    lda #C_ACCENT << 4
    jsr draw_art
    jsr blank_off
    jsr input_flush
    lda #250
    sta ct_timer
    +setupd continued_update
    rts

continued_update:
    lda in_new
    and #IN_FIRE
    bne cu_go
    dec ct_timer
    bne cu_done
cu_go:
    +fadeto menu_init
cu_done:
    rts

; ---- texts ----
txt_levelup:  !scr "Level Up!", 0
txt_closer:   !scr "One step closer to ascension", 0
txt_restart:  !scr "Press fire to restart", 0
txt_r_ism:    !scr "Your impostor syndrome consumed you.", 0
txt_r_bm:     !scr "You burned out like a cheap candle.", 0
txt_r_days:   !scr "100 days passed. The cycle never broke.", 0
txt_goodend:  !scr "* GOOD ENDING *", 0
txt_congrats: !scr "Congratulations, ", 0
txt_yourcode: !scr "your code", 0
txt_writeit:  !scr "Write it down!", 0
txt_telnet:   !scr "To continue via telnet:", 0
txt_telnet2:  !scr "teletypegames.org  2324", 0
txt_tomenu:   !scr "Press fire to return to menu", 0

; ---- variables ----
fl_t:     !byte 0
fl_col:   !byte 0
go_reason: !byte 0
ct_timer: !byte 0
