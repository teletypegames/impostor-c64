; -----------------------------------------------------------
; menu.asm - the main menu (window.menu.lua), the controls,
; the player name (window.player_name.lua), the credits
; (window.credits.lua) and the test mode's ascension start
; (window.ascend_debug.lua)
; -----------------------------------------------------------

MI_RESUME   = 0
MI_NEWGAME  = 1
MI_CONTROLS = 2
MI_CREDITS  = 3
MI_DEBUG    = 4          ; the "Debug Menu" header
MI_FLASH    = 5
MI_CONT     = 6
MI_DDRTEST  = 7
MI_ASCEND   = 8
MI_ENDSCR   = 9
MI_NAME     = 10
MI_EXIT     = 11

MENU_COL  = 22
MENU_ROW  = 8

; ============================================================
; the main menu
; ============================================================
menu_init:
    lda #W_OTHER
    sta cur_win
    lda #0
    sta in_minigame
    sta SPR_EN
    sta flick_on
    jsr glitch_hide
    ; MenuWindow.refresh_menu_items
    ldx #0
    lda in_game
    beq mi_ng
    lda #MI_RESUME
    sta mn_items,x
    inx
mi_ng:
    lda #MI_NEWGAME
    sta mn_items,x
    inx
    lda #MI_CONTROLS
    sta mn_items,x
    inx
    lda #MI_CREDITS
    sta mn_items,x
    inx
    lda test_mode
    beq mi_exit
    ldy #MI_DEBUG
mi_dbg:
    tya
    sta mn_items,x
    inx
    iny
    cpy #MI_EXIT
    bne mi_dbg
mi_exit:
    lda #MI_EXIT
    sta mn_items,x
    inx
    stx mn_n
    lda #0
    sta mn_sel
    lda mn_n             ; short lists: every other row
    cmp #7
    lda #MENU_ROW
    ldx #2
    bcc mi_row
    lda #MENU_ROW - 3
    ldx #1
mi_row:
    sta mn_row
    stx mn_step
    ; the screen: a black header over blue
    jsr blank_on
    lda #BLUE << 4 | BLUE
    jsr cls_all
    lda #0
    ldx #0
    ldy #4
    jsr clear_rows
    lda #0               ; the light blue rule under the header
    sta fr_col
    lda #3
    sta fr_row
    lda #40
    sta fr_w
    lda #1
    sta fr_h
    lda #$00
    sta fr_byte
    lda #LBLUE << 4 | BLACK
    sta fr_color
    jsr fill_rect
    ldx #0
    ldy #3
    jsr cell_ptrs
    ldx #40
mi_rule:
    ldy #6
    lda #$ff
    sta (dst),y
    iny
    sta (dst),y
    jsr adv_cell
    dex
    bne mi_rule
    lda #<txt_subtitle
    sta txt
    lda #>txt_subtitle
    sta txt+1
    ldx #11
    lda test_mode
    beq mi_sub
    ldx #7
mi_sub:
    ldy #0
    lda #LGREY << 4
    jsr print_at
    lda test_mode
    beq mi_notest
    +print 26, 0, LGREY << 4, txt_test
mi_notest:
    lda #<txt_impostor
    sta txt
    lda #>txt_impostor
    sta txt+1
    ldy #1
    lda #C_ITEM << 4
    jsr print_big_center
    +print 29, 2, C_ACCENT << 4, txt_c64
    ; norman, big, on the left
    lda #0
    sta fig_flags
    lda #FIG_BIGNORMAN
    ldx #2
    ldy #7
    jsr fig_draw_abs
    +print 36, 23, LBLUE << 4 | BLUE, txt_ttg3
    jsr menu_items
    jsr blank_off
    jsr input_flush
    +setupd menu_update
    rts

; ---- the item list, the selected one marked ----
menu_items:
    lda #0
    sta zt5
mit_lp:
    lda zt5
    ldx mn_step
    cpx #1
    beq mit_one
    asl
mit_one:
    clc
    adc mn_row
    sta zt6
    tax                  ; clear the marker cell
    lda #BLUE << 4 | BLUE
    sta pcolor
    lda #$20
    ldx #MENU_COL - 2
    ldy zt6
    jsr char_at
    ldx zt5
    cpx mn_sel
    bne mit_txt
    lda #LBLUE << 4 | BLUE
    sta pcolor
    lda #$3e             ; >
    ldx #MENU_COL - 2
    ldy zt6
    jsr char_at
mit_txt:
    ldx zt5
    lda mn_items,x
    tax
    lda mnlbllo,x
    sta txt
    lda mnlblhi,x
    sta txt+1
    lda #LBLUE << 4 | BLUE
    cpx #MI_DEBUG
    bne mit_c
    lda #DGREY << 4 | BLUE
mit_c:
    ldx #MENU_COL
    ldy zt6
    jsr print_at
    inc zt5
    lda zt5
    cmp mn_n
    bne mit_lp
    rts

menu_update:
    lda in_new
    and #IN_UP
    beq mu_noup
    jsr sfx_beep
mu_up:
    dec mn_sel
    bpl mu_upc
    ldx mn_n
    dex
    stx mn_sel
mu_upc:
    ldx mn_sel
    lda mn_items,x
    cmp #MI_DEBUG
    beq mu_up
    jmp menu_items
mu_noup:
    lda in_new
    and #IN_DOWN
    beq mu_nodown
    jsr sfx_beep
mu_down:
    inc mn_sel
    lda mn_sel
    cmp mn_n
    bcc mu_downc
    lda #0
    sta mn_sel
mu_downc:
    ldx mn_sel
    lda mn_items,x
    cmp #MI_DEBUG
    beq mu_down
    jmp menu_items
mu_nodown:
    lda in_new
    and #IN_FIRE
    beq mnu_done
    lda #SFX_SELECT
    jsr sfx_play
    ldx mn_sel
    lda mn_items,x
    asl
    tax
    lda mnact+1,x
    pha
    lda mnact,x
    pha
mnu_done:
    rts

mnact:
    !word ma_resume-1, ma_newgame-1, ma_controls-1, ma_credits-1, mnu_done-1
    !word ma_flash-1, ma_cont-1, ma_ddrtest-1, ma_ascend-1, ma_endscr-1
    !word ma_name-1, ma_exit-1

ma_resume:
    +fadeto game_enter
ma_newgame:
    lda #NAME_NEWGAME
    sta nm_confirm
    +fadeto name_init
ma_name:
    lda #NAME_MENU
    sta nm_confirm
    +fadeto name_init
ma_controls:
    +fadeto controls_init
ma_credits:
    +fadeto credits_init
ma_flash:
    lda #<menu_init
    ldx #>menu_init
    jmp flash_start
ma_cont:
    +fadeto continued_init
ma_ddrtest:
    lda #1
    sta ddr_test
    +fadeto ma_ddrgo
ma_ddrgo:
    lda #DDR_NOTHING
    jmp ddr_start
ma_ascend:
    +fadeto ascdbg_init
ma_endscr:
    +fadeto end_init
ma_exit:
    lda #$37             ; the ROMs back, then a reset
    sta CPUPORT
    jmp ($fffc)

mnlbllo: !byte <ml_resume, <ml_new, <ml_controls, <ml_credits, <ml_debug, <ml_flash
         !byte <ml_cont, <ml_ddr, <ml_ascend, <ml_end, <ml_name, <ml_exit
mnlblhi: !byte >ml_resume, >ml_new, >ml_controls, >ml_credits, >ml_debug, >ml_flash
         !byte >ml_cont, >ml_ddr, >ml_ascend, >ml_end, >ml_name, >ml_exit

ml_resume:   !scr "Resume Game", 0
ml_new:      !scr "New Game", 0
ml_controls: !scr "Controls", 0
ml_credits:  !scr "Credits", 0
ml_debug:    !scr "Debug Menu", 0
ml_flash:    !scr "Level Up Flash", 0
ml_cont:     !scr "To Be Continued...", 0
ml_ddr:      !scr "DDR Test", 0
ml_ascend:   !scr "Start at ASCEND N", 0
ml_end:      !scr "End Screen", 0
ml_name:     !scr "Player Name", 0
ml_exit:     !scr "Exit", 0
txt_subtitle: !scr "Definitely not an", 0
txt_test:    !scr "[TEST]", 0
txt_impostor: !scr "IMPOSTOR", 0
txt_c64:     !scr "C64", 0
txt_ttg3:    !scr "TTG", 0

; ============================================================
; controls
; ============================================================
controls_init:
    jsr blank_on
    lda #0
    jsr cls_all
    lda #<txt_controls
    sta txt
    lda #>txt_controls
    sta txt+1
    jsr top_bar
    +print 1, 3, LGREY << 4, txt_c_action
    +print 15, 3, LGREY << 4, txt_c_keys
    +print 31, 3, LGREY << 4, txt_c_stick
    +print 1, 6, WHITE << 4, txt_c_nav
    +print 15, 6, LBLUE << 4, txt_c_navk
    +print 31, 6, LBLUE << 4, txt_c_navs
    +print 15, 7, LBLUE << 4, txt_c_navk2
    +print 1, 9, WHITE << 4, txt_c_sel
    +print 15, 9, LBLUE << 4, txt_c_selk
    +print 31, 9, LBLUE << 4, txt_c_sels
    +print 1, 12, WHITE << 4, txt_c_back
    +print 15, 12, LBLUE << 4, txt_c_backk
    +print 15, 13, LBLUE << 4, txt_c_backk2
    +print 1, 16, LGREY << 4, txt_c_note1
    +print 1, 17, LGREY << 4, txt_c_note2
    +center 23, LGREY << 4, txt_c_return
    jsr blank_off
    jsr input_flush
    +setupd controls_update
    rts

controls_update:
    lda in_new
    and #IN_FIRE | IN_BACK
    beq cnu_done
    +fadeto menu_init
cnu_done:
    rts

; ---- a dark grey title bar on row 0: txt ----
top_bar:
    lda #DGREY << 4 | DGREY
    ldx #0
    ldy #1
    jsr clear_rows
    ldx #1
    ldy #0
    lda #LBLUE << 4 | DGREY
    jmp print_at

txt_controls: !scr "Controls", 0
txt_c_action: !scr "Action", 0
txt_c_keys:   !scr "Keyboard", 0
txt_c_stick:  !scr "Joystick", 0
txt_c_nav:    !scr "Navigate", 0
txt_c_navk:   !scr "W A S D", 0
txt_c_navk2:  !scr "cursor keys", 0
txt_c_navs:   !scr "stick", 0
txt_c_sel:    !scr "Select / OK", 0
txt_c_selk:   !scr "Space or Z", 0
txt_c_sels:   !scr "fire", 0
txt_c_back:   !scr "Back", 0
txt_c_backk:  !scr "Del, X, <-", 0
txt_c_backk2: !scr "or Run/Stop", 0
txt_c_note1:  !scr "Either joystick port works.", 0
txt_c_note2:  !scr "Back in the game: to the menu.", 0
txt_c_return: !scr "fire or back to return", 0

; ============================================================
; the player name: three letters, kept for the ending's code
; ============================================================
NAME_NEWGAME = 0
NAME_MENU    = 1
NM_ROW = 6               ; the boxes: rows 6-9

name_init:
    lda #0
    sta nm_pos
    sta nm_pos+1
    sta nm_pos+2
    sta nm_cur
    sta nm_frame
    jsr blank_on
    lda #0
    jsr cls_all
    lda #<txt_pname
    sta txt
    lda #>txt_pname
    sta txt+1
    ldy #1
    lda #WHITE << 4
    jsr print_big_center
    ; the warning band
    lda #0
    sta fr_col
    lda #17
    sta fr_row
    lda #40
    sta fr_w
    lda #5
    sta fr_h
    lda #LBLUE << 4
    jsr draw_box
    lda #0
    sta fr_col
    lda #18
    sta fr_row
    lda #40
    sta fr_w
    lda #3
    sta fr_h
    lda #WHITE << 4 | BLUE
    jsr color_rect
    lda #17              ; the frame on blue too: top and bottom rows
    sta fr_row
    lda #1
    sta fr_h
    lda #LBLUE << 4 | BLUE
    jsr color_rect
    lda #21
    sta fr_row
    lda #LBLUE << 4 | BLUE
    jsr color_rect
    lda #17              ; and the two sides
    sta fr_row
    lda #5
    sta fr_h
    lda #1
    sta fr_w
    lda #LBLUE << 4 | BLUE
    jsr color_rect
    lda #39
    sta fr_col
    lda #LBLUE << 4 | BLUE
    jsr color_rect
    +center 18, WHITE << 4 | BLUE, txt_remember
    +center 20, LGREY << 4 | BLUE, txt_needit
    jsr name_draw
    jsr blank_off
    jsr input_flush
    +setupd name_update
    rts

name_draw:
    lda #0
    sta zt5
nd_box:
    ; frame: white = current, light blue = done, dark grey = the rest
    ldx zt5
    lda nmcol,x
    sta fr_col
    lda #NM_ROW
    sta fr_row
    lda #4
    sta fr_w
    sta fr_h
    lda #DGREY << 4
    ldy nm_cur
    cpy #3
    bne nd_ndone
    lda #LBLUE << 4
    bne nd_frame
nd_ndone:
    cpx nm_cur
    bne nd_frame
    lda #WHITE << 4
nd_frame:
    jsr draw_box
    ; the inside: blue while it is the current one
    ldx zt5
    lda nmcol,x
    clc
    adc #1
    sta fr_col
    lda #NM_ROW+1
    sta fr_row
    lda #2
    sta fr_w
    sta fr_h
    lda #0
    sta fr_byte
    lda #WHITE << 4 | BLACK
    ldy nm_cur
    cpx nm_cur
    bne nd_fill
    lda #WHITE << 4 | BLUE
nd_fill:
    sta fr_color
    jsr fill_rect
    ; the letter (blinking while it is the current one)
    ldx zt5
    cpx nm_cur
    bne nd_show
    lda nm_frame
    and #32
    bne nd_next
nd_show:
    lda nm_pos,x
    clc
    adc #$41             ; 'A'
    sta nm_char
    lda #0
    sta nm_char+1
    lda #<nm_char
    sta txt
    lda #>nm_char
    sta txt+1
    ldx zt5
    lda nmcol,x
    clc
    adc #1
    tax
    ldy #NM_ROW+1
    lda #WHITE << 4 | BLUE
    ldy zt5
    cpy nm_cur
    beq nd_lc
    lda #LGREY << 4 | BLACK
nd_lc:
    ldy #NM_ROW+1
    jsr print_big
nd_next:
    inc zt5
    lda zt5
    cmp #3
    beq nd_caret
    jmp nd_box
nd_caret:
    ; the caret under the current box, and the help line
    lda #0
    ldx #NM_ROW+4
    ldy #1
    jsr clear_rows
    lda nm_cur
    cmp #3
    bcs nd_help
    tax
    lda nmcol,x
    clc
    adc #1
    tax
    lda #WHITE << 4
    sta pcolor
    ldy #NM_ROW+4
    lda #30              ; the up arrow
    jsr char_at
nd_help:
    lda #0
    ldx #12
    ldy #1
    jsr clear_rows
    lda nm_cur
    cmp #3
    bcc nd_h1
    +center 12, LBLUE << 4, txt_nm_done
    rts
nd_h1:
    +center 12, DGREY << 4, txt_nm_edit
    rts

nmcol: !byte 12, 18, 24

name_update:
    inc nm_frame
    lda nm_frame
    and #31
    bne nu_in
    jsr name_draw        ; blink
nu_in:
    lda nm_cur
    cmp #3
    bcc nu_edit
    lda in_new
    and #IN_FIRE
    beq nu_dback
    ldx #2               ; save the name
nu_save:
    lda nm_pos,x
    clc
    adc #$41
    sta player_name,x
    dex
    bpl nu_save
    lda nm_confirm
    bne nu_menu
    +fadeto new_game
nu_menu:
    +fadeto menu_init
nu_dback:
    lda in_new
    and #IN_BACK
    beq nu_done
    dec nm_cur
    jmp name_draw
nu_edit:
    ldx nm_cur
    lda in_rep
    and #IN_UP
    beq nu_noup
    inc nm_pos,x
    lda nm_pos,x
    cmp #26
    bcc nu_moved
    lda #0
    sta nm_pos,x
    beq nu_moved
nu_noup:
    lda in_rep
    and #IN_DOWN
    beq nu_nodown
    dec nm_pos,x
    bpl nu_moved
    lda #25
    sta nm_pos,x
nu_moved:
    jmp name_draw
nu_nodown:
    lda in_new
    and #IN_RIGHT
    beq nu_noright
    cpx #2
    bcs nu_done
    inc nm_cur
    jmp name_draw
nu_noright:
    lda in_new
    and #IN_FIRE
    beq nu_noselect
    inc nm_cur
    jmp name_draw
nu_noselect:
    lda in_new
    and #IN_LEFT | IN_BACK
    beq nu_done
    lda nm_cur
    beq nu_menu
    dec nm_cur
    jmp name_draw
nu_done:
    rts

txt_pname:    !scr "Player Name", 0
txt_remember: !scr "Remember your name!", 0
txt_needit:   !scr "You will need it to load the game.", 0
txt_nm_done:  !scr "fire: save name   back: edit", 0
txt_nm_edit:  !scr "up/dn: letter  lft/rgt: move  fire: ok", 0

; ============================================================
; the credits: the title drops in, the crew slides in, the
; color bars roll and the scroller runs along the bottom
; ============================================================
CR_SCROLL_ROW = 23
CR_SCRBASE = BITMAP + CR_SCROLL_ROW * 320

credits_init:
    jsr blank_on
    lda #0
    jsr cls_all
    +center 7, LGREY << 4, txt_authors
    ; the color bars: striped cells on rows 5 and 20
    lda #0
    sta fr_col
    lda #40
    sta fr_w
    lda #1
    sta fr_h
    lda #$aa
    sta fr_byte
    lda #0
    sta fr_color
    lda #5
    sta fr_row
    jsr fill_rect
    lda #20
    sta fr_row
    jsr fill_rect
    ldx #0
    ldy #5
    jsr cell_ptrs
    jsr cr_stripe
    ldx #0
    ldy #20
    jsr cell_ptrs
    jsr cr_stripe
    ; the scroller row: three color zones
    lda #0
    sta fr_byte
    sta fr_col
    lda #CR_SCROLL_ROW
    sta fr_row
    lda #13
    sta fr_w
    lda #C_ITEM << 4
    sta fr_color
    jsr fill_rect
    lda #13
    sta fr_col
    lda #WHITE << 4
    sta fr_color
    jsr fill_rect
    lda #26
    sta fr_col
    lda #14
    sta fr_w
    lda #LBLUE << 4
    sta fr_color
    jsr fill_rect
    jsr blank_off
    jsr input_flush
    lda #0
    sta cr_t
    sta cr_t+1
    sta cr_phase
    sta cr_bit
    lda #<scroll_text
    sta cr_sptr
    lda #>scroll_text
    sta cr_sptr+1
    ldx #13
cri_l:
    lda #$ff             ; nothing drawn yet
    sta cr_lrow,x
    dex
    bpl cri_l
    ldx #3
cri_a:
    lda #40
    sta cr_acol,x
    dex
    bpl cri_a
    +setupd credits_update
    rts

; ---- horizontal stripes: every other line set ----
cr_stripe:
    ldx #40
crs_c:
    ldy #7
crs_b:
    tya
    and #1
    beq crs_z
    lda #$ff
crs_z:
    sta (dst),y
    dey
    bpl crs_b
    jsr adv_cell
    dex
    bne crs_c
    rts

credits_update:
    lda in_new
    and #IN_FIRE | IN_BACK
    beq cu_run
    +fadeto menu_init
cu_run:
    inc cr_t
    bne cu_t
    inc cr_t+1
cu_t:
    jsr cr_title
    jsr cr_authors
    jsr cr_bars
    jsr cr_scroll
    jmp cr_scroll

; ---- TELETYPE GAMES: each letter drops from the top, the
; middle ones first ----
cr_title:
    ldx #0
crt_lp:
    stx zt5
    lda cr_t+1
    bne crt_down
    lda cr_t
    sec
    sbc crtdelay,x
    bcc crt_next         ; not yet
    lsr                  ; a row every 2 frames
    cmp #4
    bcc crt_row
crt_down:
    lda #4
crt_row:
    sec
    sbc #3               ; -3..1: from above the screen to row 1
    bmi crt_next
    cmp cr_lrow,x
    beq crt_next
    pha
    lda cr_lrow,x        ; erase where it was
    bmi crt_new
    tay
    lda crtcol,x
    tax
    lda #0
    sta fr_byte
    sta fr_color
    stx fr_col
    sty fr_row
    lda #2
    sta fr_w
    sta fr_h
    jsr fill_rect
crt_new:
    pla
    ldx zt5
    sta cr_lrow,x
    sta brow
    lda crtcol,x
    sta bcol
    lda txt_ttg_title,x
    cmp #$20
    beq crt_next
    pha
    lda #C_ACCENT << 4
    sta pcolor
    pla
    jsr big_char
crt_next:
    ldx zt5
    inx
    cpx #14
    bne crt_lp
    rts

txt_ttg_title: !scr "TELETYPE GAMES"
crtcol:   !for i, 0, 13 { !byte 6 + i * 2 }
crtdelay: !byte 54, 45, 36, 27, 18, 9, 0, 0, 9, 18, 27, 36, 45, 54

; ---- the crew slides in from the right, one by one ----
cr_authors:
    ldx #3
cra_lp:
    stx zt5
    lda cr_acol,x
    cmp #4
    beq cra_next
    lda cr_t+1
    bne cra_go
    lda cr_t
    cmp cradelay,x
    bcc cra_next
cra_go:
    lda cr_acol,x
    sec
    sbc #2
    cmp #4
    bcs cra_ok
    lda #4
cra_ok:
    sta cr_acol,x
    lda crarow,x
    tax
    lda #0
    ldy #1
    jsr clear_rows
    ldx zt5
    lda cralo,x
    sta txt
    lda crahi,x
    sta txt+1
    lda cr_acol,x
    sta zt6
    jsr print_clip
cra_next:
    ldx zt5
    dex
    bpl cra_lp
    rts

; ---- print txt from column zt6 on row crarow,x, stop at 40 ----
print_clip:
    ldy crarow,x
    ldx zt6
    jsr cell_ptrs
    lda #C_ACCENT << 4
    sta pcolor
    lda #0
    sta pidx
pcl_lp:
    lda zt6
    cmp #40
    bcs pcl_done
    ldy pidx
    lda (txt),y
    beq pcl_done
    jsr put_char
    inc pidx
    inc zt6
    bne pcl_lp
pcl_done:
    rts

crarow:   !byte 9, 11, 13, 15
cradelay: !byte 40, 72, 104, 136
cralo: !byte <txt_au1, <txt_au2, <txt_au3, <txt_au4
crahi: !byte >txt_au1, >txt_au2, >txt_au3, >txt_au4

; ---- the bars: the raster colors roll along rows 5 and 20 ----
cr_bars:
    lda cr_t
    and #1
    bne crb_done
    inc cr_phase
    ldx #39
crb_lp:
    txa
    clc
    adc cr_phase
    lsr
    lsr
    and #15
    tay
    lda rastcol,y
    sta SCRRAM + 5 * 40,x
    txa
    sec
    sbc cr_phase
    lsr
    lsr
    and #15
    tay
    lda rastcol,y
    sta SCRRAM + 20 * 40,x
    dex
    bpl crb_lp
crb_done:
    rts

rastcol: !byte $06, $0e, $03, $0d, $07, $01, $07, $0d
         !byte $03, $0e, $06, $0b, $06, $0e, $06, $0b

; ---- the scroller: the bottom row slides left a pixel, the
; next column of the text comes in on the right ----
cr_scroll:
    ldy #0
    lda (cr_sptr),y
    bne crs_char
    lda #<scroll_text    ; the text starts over
    sta cr_sptr
    lda #>scroll_text
    sta cr_sptr+1
    lda (cr_sptr),y
crs_char:
    ldx #0               ; its font bytes
    stx src+1
    asl
    rol src+1
    asl
    rol src+1
    asl
    rol src+1
    sta src
    lda src+1
    clc
    adc #>FONT
    sta src+1
    ldx cr_bit
    lda bitmask,x
    sta zt0
!for y, 0, 7 {
    ldy #y
    lda (src),y
    and zt0
    cmp #1               ; carry = the incoming pixel
    ldy #8               ; columns 39-32
    ldx #56
-   rol CR_SCRBASE + 256 + y,x
    dex
    dex
    dex
    dex
    dex
    dex
    dex
    dex
    dey
    bne -
    ldy #32              ; columns 31-0
    ldx #248
-   rol CR_SCRBASE + y,x
    dex
    dex
    dex
    dex
    dex
    dex
    dex
    dex
    dey
    bne -
}
    inc cr_bit
    lda cr_bit
    cmp #8
    bne crs_done
    lda #0
    sta cr_bit
    inc cr_sptr
    bne crs_done
    inc cr_sptr+1
crs_done:
    rts

txt_authors: !scr "Authors", 0
txt_au1: !scr "Mr. Zero  - Zsolt Tasnadi", 0
txt_au2: !scr "Mr. One   - Ballz", 0
txt_au3: !scr "Mr. Two   - Zoltan Timar", 0
txt_au4: !scr "Mr. Three - Bela Mezo", 0
scroll_text:
    !scr "WEB: TELETYPEGAMES.ORG    *    "
    !scr "BBS: TELETYPEGAMES.ORG:2323    *    "
    !scr "IRC: LIBERA.CHAT #TELETYPEGAMES    *    "
    !scr "YOUTUBE.COM/@TELETYPEGAMES    *    ", 0

; ============================================================
; test mode: start the game at any ascension level
; ============================================================
ascdbg_init:
    lda #0
    sta ad_level
    jsr blank_on
    lda #0
    jsr cls_all
    lda #<txt_ascdbg
    sta txt
    lda #>txt_ascdbg
    sta txt+1
    jsr top_bar
    +center 23, DGREY << 4, txt_ad_help
    jsr ad_draw
    jsr blank_off
    jsr input_flush
    +setupd ascdbg_update
    rts

ad_draw:
    lda #0
    ldx #12
    ldy #1
    jsr clear_rows
    lda ad_level
    sta numval
    jsr num_text
    +print 12, 12, WHITE << 4, txt_ad_start
    lda #<numtxt
    sta txt
    lda #>numtxt
    sta txt+1
    ldx #26
    ldy #12
    lda #WHITE << 4
    jsr print_at
    lda #WHITE << 4
    sta pcolor
    lda ad_level
    beq ad_nol
    ldx #9
    ldy #12
    lda #$3c
    jsr char_at
ad_nol:
    lda ad_level
    cmp #ASC_MAX
    bcs ad_nor
    ldx #29
    ldy #12
    lda #$3e
    jmp char_at
ad_nor:
    rts

ascdbg_update:
    lda in_new
    and #IN_LEFT
    beq adu_nl
    lda ad_level
    beq adu_done
    dec ad_level
    jmp ad_draw
adu_nl:
    lda in_new
    and #IN_RIGHT
    beq adu_nr
    lda ad_level
    cmp #ASC_MAX
    bcs adu_done
    inc ad_level
    jmp ad_draw
adu_nr:
    lda in_new
    and #IN_FIRE
    beq adu_nf
    lda #SFX_SELECT
    jsr sfx_play
    +fadeto ascdbg_start
adu_nf:
    lda in_new
    and #IN_BACK
    beq adu_done
    lda #SFX_DESELECT
    jsr sfx_play
    +fadeto menu_init
adu_done:
    rts

; ---- Context.new_game_debug(level) ----
ascdbg_start:
    jsr ctx_reset
    lda #0
    sta test_mode        ; as in the original: the debug start ends it
    lda #1
    sta in_game
    sta home_norman
    lda ad_level
    sta asc_level
    beq ads_0
    clc
    adc #3
    sta day
    lda #1
    sta met_sumphore
ads_0:
    lda #SC_HOME
    jsr goto_screen
    jmp game_enter

txt_ascdbg:   !scr "ASCEND Debug Start", 0
txt_ad_start: !scr "Start at:", 0
txt_ad_help:  !scr "fire: start   back: menu", 0

; ---- variables ----
mn_items:   !fill 12, 0
mn_n:       !byte 0
mn_sel:     !byte 0
mn_row:     !byte 0
mn_step:    !byte 1
nm_confirm: !byte 0
nm_pos:     !fill 3, 0
nm_cur:     !byte 0
nm_frame:   !byte 0
nm_char:    !fill 2, 0
cr_t:       !word 0
cr_phase:   !byte 0
cr_bit:     !byte 0
cr_lrow:    !fill 14, 0
cr_acol:    !fill 4, 0
ad_level:   !byte 0
ddr_test:   !byte 0
