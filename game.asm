; -----------------------------------------------------------
; game.asm - the game window (window.game.lua): the scene
; of the current screen with its figures, the HUD below it
; (meters, clock, ASCENSION) and the decision bar; the
; screens (screen.*.lua) and the decisions (decision.*.lua)
; -----------------------------------------------------------

W_GAME = 0
W_DISC = 1
W_MINI = 2
W_OTHER = 3

; ============================================================
; screens
; ============================================================

; ---- Util.go_to_screen_by_id: A = screen ----
goto_screen:
    pha
    lda cur_screen
    cmp #SC_MMAN         ; the mysterious man's exit: music off
    bne gs_noexit
    jsr music_stop
gs_noexit:
    pla
    sta cur_screen
    asl
    tax
    lda scr_init+1,x
    pha
    lda scr_init,x
    pha
    rts                  ; jump to the screen's init

scr_init:
    !word si_home-1, si_toilet-1, si_walkoff-1, si_office-1
    !word si_walkhome-1, si_work-1, si_mman-1

si_home:
    jsr cg_max
    bcc sh_normal
    lda #MUS_MYSTERY
    jsr play_tune
    jmp glitch_show
sh_normal:
    lda #MUS_WORK
    jmp play_tune

si_toilet:
    lda #MUS_MYSTERY
    jsr play_tune
    lda #1
    sta stat_active
    sta meters_hidden
    rts

si_walkoff:
    jsr cg_max
    bcc swo_normal
    lda #MUS_MYSTERY
    jsr play_tune
    lda #1
    jsr list_make
    jmp list_corrupt
swo_normal:
    lda #MUS_WORK
    jsr play_tune
    lda #1
    jmp list_make

si_office:
    lda #1
    sta been_office
    jsr cg_max
    bcc so_normal
    lda #MUS_MYSTERY
    jsr play_tune
    lda #0
    sta ln
    rts
so_normal:
    jsr cg_music_slow
    lda #MUS_WORK
    jsr music_play
    lda #0
    jsr list_make
    jsr cg_active
    bcc so_done
    jmp list_corrupt
so_done:
    rts

si_walkhome:
    jsr cg_max
    bcc swh_normal
    lda #MUS_MYSTERY
    jsr play_tune
    lda #0
    sta ln
    rts
swh_normal:
    jsr cg_music_slow
    lda #MUS_WORK
    jsr music_play
    lda #1
    jsr list_make
    jsr cg_active
    bcc swh_done
    jmp list_corrupt
swh_done:
    rts

si_work:
    rts

si_mman:
    lda #MUS_MYSTERY
    jmp play_tune

; ---- play a tune at its own tempo ----
play_tune:
    ldx #0
    stx mus_slow
    jmp music_play

; ============================================================
; the window
; ============================================================

; ---- Window.set_current("game") + a full redraw ----
game_enter:
    lda #W_GAME
    sta cur_win
    lda #0
    sta in_minigame
    sta dec_sel
    jsr input_flush
    jsr game_redraw
    +setupd game_update
    rts

game_redraw:
    jsr blank_on
    lda #0
    sta SPR_EN
    jsr cls_all
    lda cur_screen
    cmp #SC_MMAN
    bne gr_scene
    jsr mman_draw
    jmp gr_done
gr_scene:
    cmp #SC_TOILET
    bne gr_normal
    lda stat_active
    beq gr_normal
    jsr toilet_draw
    lda #LAY_TOILET
    jsr set_layout
    jmp gr_done
gr_normal:
    jsr scene_draw
    jsr shadow_save
    jsr hud_draw
    jsr dec_build
    jsr dec_draw
    lda cur_screen       ; the map scenes are multicolor
    cmp #SC_WORK
    bcs gr_done
    lda #LAY_SCENE
    jsr set_layout
gr_done:
    jsr blank_off
    rts

game_update:
    lda in_new
    and #IN_BACK
    beq gu_noback
    lda #0
    sta flick_on
    +fadeto menu_init
gu_noback:
    lda cur_screen
    cmp #SC_MMAN
    bne gu_toilet
    jmp mman_update
gu_toilet:
    cmp #SC_TOILET
    bne gu_hud
    lda stat_active
    beq gu_hud
    lda in_new
    and #IN_FIRE
    beq gu_done
    lda #0               ; leave the stat screen: back home
    sta stat_active
    sta meters_hidden
    lda #SC_HOME
    jsr goto_screen
    jmp game_redraw
gu_hud:
    jsr hud_update
    lda dec_n
    beq gu_done
    lda in_new
    and #IN_LEFT
    beq gu_noleft
    jsr sfx_beep
    dec dec_sel
    bpl gu_moved
    ldx dec_n
    dex
    stx dec_sel
    jmp gu_moved
gu_noleft:
    lda in_new
    and #IN_RIGHT
    beq gu_noright
    jsr sfx_beep
    inc dec_sel
    lda dec_sel
    cmp dec_n
    bcc gu_moved
    lda #0
    sta dec_sel
gu_moved:
    jsr dec_draw
gu_noright:
    lda in_new
    and #IN_FIRE
    beq gu_done
    lda #SFX_SELECT
    jsr sfx_play
    ldx dec_sel
    lda dec_list,x
    jmp dec_handle
gu_done:
    rts

sfx_beep:
    lda #SFX_BEEP
    jmp sfx_play

; ============================================================
; the scene of the current screen
; ============================================================
scene_draw:
    lda #0
    sta flick_on
    lda cur_screen
    asl
    tax
    lda scr_draw+1,x
    pha
    lda scr_draw,x
    pha
    rts

scr_draw:
    !word sd_home-1, sd_home-1, sd_walkoff-1, sd_office-1
    !word sd_walkhome-1, sd_work-1, sd_work-1

; ---- the flicker of commute glitch max / ascension 8 ----
flick_check:
    jsr cg_max
    bcs fc_on
    lda asc_level
    cmp #8
    bne fc_off
fc_on:
    lda cur_win
    cmp #W_MINI
    beq fc_off
    lda #1
    sta flick_on
fc_off:
    rts

sd_home:
    lda #BG_BEDROOM
    jsr scene_load
    lda home_norman
    beq sdh_nonorman
    lda #0
    sta fig_flags
    lda #FIG_NORMAN
    ldx #POS_HOME_NORMAN_X
    ldy #POS_HOME_NORMAN_Y
    jsr fig_draw
sdh_nonorman:
    lda cur_win
    cmp #W_GAME
    bne sdh_done
    jmp flick_check
sdh_done:
    rts

sd_work:
    lda #BLUE << 4 | BLUE
    sta fr_color
    lda #0
    sta fr_byte
    sta fr_row
    lda #SCN_X
    sta fr_col
    lda #SCN_W
    sta fr_w
    lda #SCN_H
    sta fr_h
    jmp fill_rect

; ---- the street: norman, sumphore, the pizza stand, the guard ----
street_common:
    jsr cg_max
    lda #BG_STREET
    bcc stc_bg
    lda #BG_NONE
stc_bg:
    jsr scene_load
    lda #0
    sta fig_flags
    ldx #POS_STREET_NORMAN_X
    lda food_near
    beq stc_nx
    ldx #POS_STREET_NORMAN_FOOD_X
stc_nx:
    lda #FIG_NORMAN
    ldy #POS_STREET_NORMAN_Y
    jsr fig_draw
    lda asc_level
    cmp #8
    beq stc_nosumph
    lda #FIG_SUMPHORE
    ldx #POS_SUMPHORE_X
    ldy #POS_SUMPHORE_Y
    jsr fig_draw
stc_nosumph:
    rts

sd_walkoff:
    jsr street_common
    lda food_eaten
    cmp #3
    bcs swo_novend
    lda #FIG_VENDOR
    ldx #POS_VENDOR_X
    ldy #POS_VENDOR_Y
    jsr fig_draw
swo_novend:
    lda #FIG_GUARD
    ldx #POS_GUARD_OFFICE_X
    ldy #POS_GUARD_OFFICE_Y
    jsr fig_draw
    lda #0               ; Sprite.draw_list: no echo colors here
    jmp list_draw

sd_walkhome:
    jsr street_common
    jsr cg_max
    bcs swh_list
    lda food_eaten
    cmp #3
    bcs swh_novend
    lda #FIG_VENDOR
    ldx #POS_VENDOR_X
    ldy #POS_VENDOR_Y
    jsr fig_draw
swh_novend:
    lda #FIG_GUARD
    ldx #POS_GUARD_HOME_X
    ldy #POS_GUARD_HOME_Y
    jsr fig_draw
swh_list:
    lda #FF_ECHO
    jsr list_draw
    jmp flick_check

sd_office:
    jsr cg_max
    lda #BG_OFFICE
    bcc sdo_bg
    lda #BG_NONE
sdo_bg:
    jsr scene_load
    lda #0
    sta fig_flags
    lda #FIG_NORMAN
    ldx #POS_OFFICE_NORMAN_X
    ldy #POS_OFFICE_NORMAN_Y
    jsr fig_draw
    jsr cg_max
    bcc sdo_list
    lda #FF_ECHO
    sta fig_flags
    lda #FIG_NORMAN
    ldx #POS_OFFICE_ECHO_X
    ldy #POS_OFFICE_ECHO_Y
    jsr fig_draw
    jmp flick_check
sdo_list:
    lda #FF_ECHO
    jsr list_draw
    jmp flick_check

; ---- draw the figure list; A = the flags it may keep ----
list_draw:
    sta zt7
    lda #0
    sta ld_i
ld_lp:
    ldx ld_i
    cpx ln
    bcs ld_done
    lda lflags,x
    and zt7
    sta fig_flags
    lda lflags,x
    and #FF_FLIP
    ora fig_flags
    sta fig_flags
    lda lfig,x
    ldy ly,x
    pha
    lda lx,x
    tax
    pla
    jsr fig_draw
    inc ld_i
    bne ld_lp
ld_done:
    rts

; ============================================================
; the HUD: meters + clock + ASCENSION
; ============================================================
hud_draw:
    lda #0
    ldx #SCN_H
    ldy #BAR_TOP - SCN_H
    jsr clear_rows
    lda #0
    sta hud_dirty
    sta clock_dirty
    lda meters_hidden
    beq hd_show
    rts
hd_show:
    jsr clock_draw
    +print 2, HUD_METERS, LBLUE << 4, txt_wpm
    +print 15, HUD_METERS, YELLOW << 4, txt_ism
    +print 28, HUD_METERS, LRED << 4, txt_bm
    ldx #M_WPM
    jsr bar_draw
    ldx #M_ISM
    jsr bar_draw
    ldx #M_BM
    jsr bar_draw
    jmp asc_draw

hud_update:
    lda meters_hidden
    bne hu_done
    lda clock_dirty
    beq hu_bars
    lda #0
    sta clock_dirty
    jsr clock_draw
hu_bars:
    lda hud_dirty
    beq hu_done
    lda #0
    sta hud_dirty
    ldx #M_WPM
    jsr bar_draw
    ldx #M_ISM
    jsr bar_draw
    ldx #M_BM
    jsr bar_draw
    jmp asc_draw
hu_done:
    rts

; ---- the clock: 2x2 cells at the HUD's left edge ----
clock_draw:
    lda clock_ph         ; frame * 32
    lsr
    lsr
    lsr
    sta zt0
    lda clock_ph
    asl
    asl
    asl
    asl
    asl
    clc
    adc #<clock_cells
    sta src
    lda zt0
    adc #>clock_cells
    sta src+1
    lda clock_ph         ; the color by quarter
    lsr
    lsr
    tax
    lda clockcol,x
    sta pcolor
    ldx #0
    ldy #HUD_METERS
    jsr cell_ptrs
    jsr clk_two
    ldx #0
    ldy #HUD_METERS+1
    jsr cell_ptrs
clk_two:
    ldy #0
clk_c1:
    lda (src),y
    sta (dst),y
    iny
    cpy #16
    bne clk_c1
    ldy #0
    lda pcolor
    sta (cdst),y
    iny
    sta (cdst),y
    lda src
    clc
    adc #16
    sta src
    bcc clk_d
    inc src+1
clk_d:
    rts

clockcol: !byte DGREY << 4, LBLUE << 4, BLUE << 4, LRED << 4

; ---- one meter bar: X = meter; 8 cells, 64 px for 0-1000 ----
bar_draw:
    stx bd_m
    lda mlo,x
    sta divlo
    lda mhi,x
    jsr bar_px
    sta bd_new
    sta bd_lo
    sta bd_hi
    ldx bd_m
    lda #0
    sta bd_fl
    lda mflash,x
    beq bd_cells
    lda moldlo,x
    sta divlo
    lda moldhi,x
    jsr bar_px
    sta bd_old
    cmp bd_new
    beq bd_cells
    lda #1
    sta bd_fl
    lda bd_old           ; the flashing span: between old and new
    cmp bd_new
    bcc bd_up
    sta bd_hi
    lda bd_new
    sta bd_lo
    jmp bd_cells
bd_up:
    sta bd_lo
bd_cells:
    ldx bd_m
    lda barcol,x
    sta bd_col
    ldy #HUD_METERS
    lda barx,x
    tax
    jsr cell_ptrs
    lda #0
    sta zt5              ; cell 0-7
bd_cell:
    lda zt5
    asl
    asl
    asl
    sta zt6              ; its first pixel
    lda bd_col           ; ink: the meter, white where it flashes
    sta zt4
    lda bd_new
    sta zt3              ; filled up to
    lda bd_fl
    beq bd_fill
    lda zt6
    clc
    adc #8
    cmp bd_lo
    bcc bd_fill          ; the cell ends before the flash
    beq bd_fill
    lda zt6
    cmp bd_hi
    bcs bd_fill          ; starts after it
    lda #WHITE
    sta zt4
    lda bd_hi
    sta zt3
bd_fill:
    lda zt3
    sec
    sbc zt6
    bcs bd_pos
    lda #0
bd_pos:
    cmp #8
    bcc bd_n
    lda #8
bd_n:
    tax
    lda leftmask,x
    ldy #6
bd_rows:
    sta (dst),y
    dey
    bne bd_rows
    lda #0
    sta (dst),y
    ldy #7
    sta (dst),y
    lda zt4
    asl
    asl
    asl
    asl
    ora #C_METERBG
    ldy #0
    sta (cdst),y
    jsr adv_cell
    inc zt5
    lda zt5
    cmp #8
    bne bd_cell
    rts

; ---- divlo + A (high byte) = meter value -> A = pixels 0-64 ----
bar_px:
    sta divhi
    asl divlo            ; * 8
    rol divhi
    asl divlo
    rol divhi
    asl divlo
    rol divhi
    lda #125             ; / 125
    jsr div16
    lda divlo
    rts

barx:   !byte 6, 19, 31
barcol: !byte C_WPM, C_ISM, C_BM
leftmask: !byte $00, $80, $c0, $e0, $f0, $f8, $fc, $fe, $ff

; ---- ASCENSION: one letter per level, the newest fades in ----
asc_draw:
    lda #0
    ldx #HUD_ASC
    ldy #1
    jsr clear_rows
    lda asc_level
    bne ad_go
    rts
ad_go:
    lda #0
    sta zt5
ad_lp:
    lda #WHITE << 4
    sta pcolor
    ldx zt5
    inx
    cpx asc_level
    bne ad_lit
    lda asc_fade         ; the newest letter: black, grey, light grey
    beq ad_lit
    ldx #BLACK << 4
    cmp #67
    bcs ad_fc
    ldx #DGREY << 4
    cmp #34
    bcs ad_fc
    ldx #LGREY << 4
ad_fc:
    stx pcolor
ad_lit:
    lda zt5
    asl
    clc
    adc #11
    tax
    ldy #HUD_ASC
    jsr cell_ptrs
    ldx zt5
    lda txt_ascension,x
    jsr put_char
    inc zt5
    lda zt5
    cmp asc_level
    bne ad_lp
    rts

; ============================================================
; decisions
; ============================================================

; ---- the decisions of the screen whose condition holds ----
dec_build:
    lda #0
    sta dec_n
    lda stat_active
    bne db_done
    ldx cur_screen
    lda scrdeclo,x
    sta ptr2
    lda scrdechi,x
    sta ptr2+1
    ldy #0
db_lp:
    sty db_i
    lda (ptr2),y
    bmi db_done
    sta db_id
    jsr dec_cond
    bcc db_skip
    ldx dec_n
    lda db_id
    sta dec_list,x
    inc dec_n
db_skip:
    ldy db_i
    iny
    bne db_lp
db_done:
    lda dec_sel
    cmp dec_n
    bcc db_ok
    lda #0
    sta dec_sel
db_ok:
    rts

scrdeclo: !byte <sdec_home, <sdec_toilet, <sdec_walkoff, <sdec_office, <sdec_walkhome, <sdec_none, <sdec_none
scrdechi: !byte >sdec_home, >sdec_toilet, >sdec_walkoff, >sdec_office, >sdec_walkhome, >sdec_none, >sdec_none
sdec_home:    !byte DC_TOILET, DC_WALKOFF, DC_SLEEP, $ff
sdec_toilet:  !byte DC_GO_HOME, $ff
sdec_walkoff: !byte DC_GO_HOME, DC_GO_OFFICE, DC_SUMPHORE, DC_FOOD, $ff
sdec_office:  !byte DC_WORK, DC_WALKHOME, DC_COFFEE, DC_TALKTRUTH, $ff
sdec_walkhome: !byte DC_GO_HOME, DC_GO_OFFICE, DC_SUMPHORE, DC_FOOD, DC_TRUTH, $ff
sdec_none:    !byte $ff

; ---- the bar: < label > on rows 21-23 ----
dec_draw:
    lda #DGREY << 4 | DGREY
    ldx #BAR_TOP
    ldy #3
    jsr clear_rows
    lda dec_n
    bne dd_go
    rts
dd_go:
    lda #C_ITEM << 4 | DGREY
    sta pcolor
    ldx #1
    ldy #BAR_ROW
    lda #$3c             ; <
    jsr char_at
    ldx #38
    ldy #BAR_ROW
    lda #$3e             ; >
    jsr char_at
    ldx dec_sel
    lda dec_list,x
    jsr dec_label
    ldy #BAR_ROW
    lda #C_ITEM << 4 | DGREY
    jmp print_center

; ---- A = decision -> txt = its label ----
dec_label:
    cmp #DC_SLEEP
    bne dl_sumph
    lda asc_level
    cmp #8
    bcc dl_sleep
    lda #<lbl_break
    ldx #>lbl_break
    bne dl_set
dl_sleep:
    lda #<lbl_sleep
    ldx #>lbl_sleep
    bne dl_set
dl_sumph:
    cmp #DC_SUMPHORE
    bne dl_table
    lda met_sumphore
    beq dl_homeless
    lda #<lbl_sumph
    ldx #>lbl_sumph
    bne dl_set
dl_homeless:
    lda #<lbl_homeless
    ldx #>lbl_homeless
    bne dl_set
dl_table:
    tay
    lda declbllo,y
    ldx declblhi,y
dl_set:
    sta txt
    stx txt+1
    rts

declbllo: !byte <lbl_home, <lbl_toilet, <lbl_walkoff, <lbl_office, <lbl_truth, <lbl_walkhome
          !byte <lbl_sleep, <lbl_work, <lbl_coffee, <lbl_sumph, <lbl_talktruth, <lbl_food
declblhi: !byte >lbl_home, >lbl_toilet, >lbl_walkoff, >lbl_office, >lbl_truth, >lbl_walkhome
          !byte >lbl_sleep, >lbl_work, >lbl_coffee, >lbl_sumph, >lbl_talktruth, >lbl_food

; ---- A = decision -> carry set if its condition holds ----
dec_cond:
    asl
    tax
    lda dcond+1,x
    pha
    lda dcond,x
    pha
    rts

dcond:
    !word dk_home-1, dk_yes-1, dk_yes-1, dk_office-1, dk_truth-1, dk_walkhome-1
    !word dk_sleep-1, dk_work-1, dk_coffee-1, dk_sumph-1, dk_talktruth-1, dk_food-1

dk_yes:
    sec
    rts
dk_no:
    clc
    rts

; work done today, after a visit to the office
dk_sleep:
    lda been_office
    beq dk_no
    lda done_work
    beq dk_no
    sec
    rts

dk_home:
    lda asc_level
    cmp #8
    bcs dk_sleep
    jsr cg_active
    bcc dk_sleep
    jsr cg_level_get
    cmp #4
    bcc dk_sleep
    cmp #7
    bcc dk_no            ; levels 4-6: no way home
    lda talked_echo
    beq dk_no
    lda talked_sumph
    beq dk_no
    sec
    rts

dk_office:
    jsr cg_active
    bcc dk_yes
    jsr cg_level_get
    cmp #6
    bcs dk_no
    sec
    rts

dk_truth:
    jsr cg_active
    bcc dk_no
    jsr cg_level_get
    cmp #6
    bne dk_no
    sec
    rts

dk_walkhome:
    jsr cg_active
    bcc dk_yes
    jsr cg_level_get
    cmp #7
    bne dk_yes
    lda talked_echo
    beq dk_no
    sec
    rts

dk_work:
    jsr cg_active
    bcc dk_yes
    jsr cg_level_get
    cmp #5
    bcs dk_no
    sec
    rts

dk_coffee:
    lda asc_level
    cmp #8
    bcs dk_no
    jsr cg_max
    bcs dk_no
    sec
    rts

dk_no2:
    clc
    rts

dk_sumph:
    lda asc_level
    cmp #8
    bcs dk_no2
    sec
    rts

dk_talktruth:
    jmp cg_max

dk_food:
    jsr cg_active
    bcs dkf_active
    lda food_eaten
    cmp #3
    bcs dk_no2
    sec
    rts
dkf_active:
    jsr cg_level_get
    cmp #5
    bcs dk_no2
    sec
    rts

; ---- A = decision: run it ----
dec_handle:
    asl
    tax
    lda dhand+1,x
    pha
    lda dhand,x
    pha
    rts

dhand:
    !word dh_home-1, dh_toilet-1, dh_walkoff-1, dh_office-1, dh_truth-1, dh_walkhome-1
    !word dh_sleep-1, dh_work-1, dh_coffee-1, dh_sumph-1, dh_talktruth-1, dh_food-1

; ---- go to a screen and show it ----
goto_redraw:
    jsr goto_screen
    jsr fx_restore
    jmp game_enter

dh_toilet:
    lda done_work
    bne dht_eve
    lda toilet_morning
    bne dht_go
    jsr meter_toilet
    lda #1
    sta toilet_morning
    bne dht_go
dht_eve:
    lda been_office
    beq dht_go
    lda toilet_evening
    bne dht_go
    jsr meter_toilet
    lda #1
    sta toilet_evening
dht_go:
    lda #SC_TOILET
    jmp goto_redraw

dh_walkoff:
    lda #SC_WALKOFF
    jmp goto_redraw

dh_walkhome:
    lda #SC_WALKHOME
    jmp goto_redraw

dh_office:
    jsr cg_active
    bcc dho_go
    jsr cg_increment
dho_go:
    lda #SC_OFFICE
    jmp goto_redraw

dh_truth:
    lda #7               ; CommuteGlitch.enter_truth
    sta cg_level
    jsr glitch_show
    lda #SC_OFFICE
    jsr goto_screen
    lda #<game_enter
    ldx #>game_enter
    jmp flash_start

dh_home:
    lda asc_level
    cmp #8
    bcs dhh_plain
    jsr cg_max
    bcc dhh_active
    lda #1               ; through the truth: the cycle moves on
    sta should_ascend
    jsr cg_reset
    lda #1
    sta meters_hidden
    jsr day_increase
    lda gameover
    bpl dhh_over
    jsr asc_consume
    jsr mman_after_day
    jmp game_enter
dhh_over:
    rts
dhh_active:
    jsr cg_active
    bcc dhh_plain
    jsr cg_reset
dhh_plain:
    lda #SC_HOME
    jmp goto_redraw

dh_sleep:
    lda #1
    sta meters_hidden
    jsr day_increase
    lda gameover
    bpl dhs_over
    lda #RH_SLEEP
    jmp rhythm_start
dhs_over:
    rts

dh_work:
    lda #1
    sta meters_hidden
    lda #SC_WORK
    jsr goto_screen
    ldx asc_level        ; the special mode of the ascension
    lda #DDR_NORMAL
    cpx #4
    bcs dhw_mode
    lda ddrmodes,x
dhw_mode:
    jmp ddr_start

ddrmodes: !byte DDR_NORMAL, DDR_SPECIAL, DDR_LEFT, DDR_NOTHING

dh_coffee:
    lda asc_level
    bne dhc_1
    lda #D_COWORKER_DISC_0
    jmp dhc_start
dhc_1:
    cmp #6
    bcs dhc_6
    tax                  ; 1-5: before or after work
    dex
    lda done_work
    beq dhc_before
    lda cw_asc,x
    jmp dhc_start
dhc_before:
    lda cw_plain,x
    jmp dhc_start
dhc_6:
    bne dhc_7
    lda glitch_today
    bne dhc_6plain
    lda glitch_count
    cmp #6
    bcs dhc_6plain
    lda #1
    sta glitch_today
    inc glitch_count
    jsr glitch_show
    ldx glitch_count
    dex
    lda cw_glitch,x
    jmp dhc_start
dhc_6plain:
    ldx #4
    lda done_work
    beq dhc_before
    lda cw_asc,x
    jmp dhc_start
dhc_7:
    jsr cg_level_get     ; only levels 2-6 have something to say
    cmp #2
    bcc dhc_none
    cmp #7
    bcs dhc_none
    tax
    lda cw_cg-2,x
dhc_start:
    ldx #0
    jmp disc_start
dhc_none:
    rts

cw_plain: !byte D_COWORKER_DISC_1, D_COWORKER_DISC_2, D_COWORKER_DISC_3, D_COWORKER_DISC_4, D_COWORKER_DISC_5
cw_asc:   !byte D_COWORKER_DISC_ASC_1, D_COWORKER_DISC_ASC_2, D_COWORKER_DISC_ASC_3, D_COWORKER_DISC_ASC_4, D_COWORKER_DISC_ASC_5
cw_glitch: !byte D_COWORKER_DISC_ASC_6_1, D_COWORKER_DISC_ASC_6_2, D_COWORKER_DISC_ASC_6_3
          !byte D_COWORKER_DISC_ASC_6_4, D_COWORKER_DISC_ASC_6_5, D_COWORKER_DISC_ASC_6_6
cw_cg:    !byte D_COWORKER_DISC_CG_2, D_COWORKER_DISC_CG_3, D_COWORKER_DISC_CG_4
          !byte D_COWORKER_DISC_CG_5, D_COWORKER_DISC_CG_6

dh_sumph:
    lda asc_level
    bne dhs_1
    ldx #0
    lda met_sumphore
    beq dhs_hg
    ldx #3               ; met him already: start at step 4
dhs_hg:
    lda #D_HOMELESS_GUY
    jmp disc_start
dhs_1:
    ldx met_sumphore
    bne dhs_met
    ldx #0
    lda #D_HOMELESS_GUY
    jmp disc_start
dhs_met:
    ldx #0
    cmp #6
    bcs dhs_6
    tay
    lda sp_asc-1,y
    jmp disc_start
dhs_6:
    bne dhs_7
    lda glitch_count
    cmp #6
    lda #D_SUMPHORE_DISC_ASC_6
    bcs dhs_6go
    lda #D_SUMPHORE_DISC_ASC_6_WAITING
dhs_6go:
    jmp disc_start
dhs_7:
    jsr cg_level_get
    tay
    lda sp_cg,y
    ldx #0
    jmp disc_start

sp_asc: !byte D_SUMPHORE_DISC_ASC_1, D_SUMPHORE_DISC_ASC_2, D_SUMPHORE_DISC_ASC_3
        !byte D_SUMPHORE_DISC_ASC_4, D_SUMPHORE_DISC_ASC_5
sp_cg:  !byte D_SUMPHORE_DISC_CG_0, D_SUMPHORE_DISC_CG_1, D_SUMPHORE_DISC_CG_2, D_SUMPHORE_DISC_CG_3
        !byte D_SUMPHORE_DISC_CG_4, D_SUMPHORE_DISC_CG_5, D_SUMPHORE_DISC_CG_6, D_SUMPHORE_DISC_CG_7

dh_talktruth:
    lda #D_NORMAN_TRUTH
    ldx #0
    jmp disc_start

dh_food:
    lda #1
    sta food_near
    lda #D_PIZZA_VENDOR_DISC
    ldx #0
    jmp disc_start

; ============================================================
; the toilet's stat screen (screen.toilet.lua): norman in a
; small circle of light, the day, the meters with their
; daily decay and combo percentages, ASCENSION
; ============================================================
toilet_draw:
    lda #BG_BEDROOM
    jsr scene_load
    lda #0
    sta fig_flags
    lda #FIG_NORMAN
    ldx #POS_TOILET_NORMAN_X
    ldy #POS_TOILET_NORMAN_Y
    jsr fig_draw
    jsr shadow_save
    lda #45              ; (180, 102) in 4 px units, radius 15%
    sta focus_x
    lda #25
    sta focus_y
    lda #8
    sta focus_r
    jsr focus_center
    jsr focus_apply      ; only the circle's rows stay multicolor
    ; day N
    lda day
    sta numval
    jsr num_text
    +print 17, 1, WHITE << 4, txt_day
    lda #<numtxt
    sta txt
    lda #>numtxt
    sta txt+1
    ldx #21
    ldy #1
    lda #WHITE << 4
    jsr print_at
    +center 3, LGREY << 4, txt_toilet1
    +center 4, LGREY << 4, txt_toilet2
    ; ASCENSION, centered
    lda asc_level
    beq td_noasc
    asl
    sta zt5
    lda #41
    sec
    sbc zt5
    lsr
    sta zt6              ; first column
    lda #0
    sta zt5
td_asc:
    lda #WHITE << 4
    sta pcolor
    lda zt5
    asl
    clc
    adc zt6
    tax
    ldy #6
    jsr cell_ptrs
    ldx zt5
    lda txt_ascension,x
    jsr put_char
    inc zt5
    lda zt5
    cmp asc_level
    bne td_asc
td_noasc:
    ; the three meters under the scene
    lda #0
    sta td_i
td_m:
    ldx td_i
    lda tmlabello,x
    sta txt
    lda tmlabelhi,x
    sta txt+1
    lda barcol,x
    asl
    asl
    asl
    asl
    pha
    lda tmrow,x
    tay
    pla
    jsr print_center
    ldx td_i
    jsr tbar_draw
    inc td_i
    lda td_i
    cmp #3
    bne td_m
    lda asc_level
    cmp #8
    bne td_done
    lda #1
    sta flick_on
td_done:
    +center 24, DGREY << 4, txt_firecont
    rts

; ---- a stat bar: X = meter; -2% left, the combo % right,
; 20 cells (160 px for 0-1000) on the row under its label ----
tbar_draw:
    stx bd_m
    lda tmrow,x
    clc
    adc #1
    sta zt6
    tay
    lda #<txt_decay
    sta txt
    lda #>txt_decay
    sta txt+1
    ldx #4
    lda #LBLUE << 4
    jsr print_at
    jsr combo_step
    ldx bd_m
    cpx #M_WPM
    bne tb_ism
    tax
    lda cwpmlo,x
    sta txt
    lda cwpmhi,x
    sta txt+1
    jmp tb_pct
tb_ism:
    tax
    lda cismlo,x
    sta txt
    lda cismhi,x
    sta txt+1
tb_pct:
    ldx #29
    ldy zt6
    lda #LBLUE << 4
    jsr print_at
    ; the bar: value * 16 / 100 pixels
    ldx bd_m
    lda mlo,x
    sta divlo
    lda mhi,x
    sta divhi
    asl divlo
    rol divhi
    asl divlo
    rol divhi
    asl divlo
    rol divhi
    asl divlo
    rol divhi
    lda #100
    jsr div16
    lda divlo
    sta zt3
    ldx bd_m
    lda barcol,x
    asl
    asl
    asl
    asl
    ora #C_METERBG
    sta zt4
    ldx #8
    ldy zt6
    jsr cell_ptrs
    lda #0
    sta zt5x
tb_cell:
    lda zt5x
    asl
    asl
    asl
    sta zt7
    lda zt3
    sec
    sbc zt7
    bcs tb_pos
    lda #0
tb_pos:
    cmp #8
    bcc tb_n
    lda #8
tb_n:
    tax
    lda leftmask,x
    ldy #6
tb_rows:
    sta (dst),y
    dey
    bne tb_rows
    lda #0
    sta (dst),y
    ldy #7
    sta (dst),y
    lda zt4
    ldy #0
    sta (cdst),y
    jsr adv_cell
    inc zt5x
    lda zt5x
    cmp #20
    bne tb_cell
    rts

tmrow: !byte 17, 19, 21
tmlabello: !byte <txt_wpm_long, <txt_ism_long, <txt_bm_long
tmlabelhi: !byte >txt_wpm_long, >txt_ism_long, >txt_bm_long
; the combo percentages for combo 0, 1, 2, 3, 4+
cwpmlo: !byte <txt_p0, <txt_m2, <txt_m4, <txt_m7, <txt_m14
cwpmhi: !byte >txt_p0, >txt_m2, >txt_m4, >txt_m7, >txt_m14
cismlo: !byte <txt_p0, <txt_p2, <txt_p4, <txt_p8, <txt_p15
cismhi: !byte >txt_p0, >txt_p2, >txt_p4, >txt_p8, >txt_p15

; ---- texts ----
txt_wpm:  !scr "WPM", 0
txt_ism:  !scr "ISM", 0
txt_bm:   !scr "BM", 0
txt_ascension: !scr "ASCENSION"
txt_day:  !scr "day", 0
txt_toilet1: !scr "reflecting on my past and present...", 0
txt_toilet2: !scr "both eventually flushed...", 0
txt_wpm_long: !scr "Work Productivity Meter", 0
txt_ism_long: !scr "Impostor Syndrome Meter", 0
txt_bm_long:  !scr "Burnout Meter", 0
txt_decay: !scr "-2%", 0
txt_p0:  !scr "+0%", 0
txt_m2:  !scr "-2%", 0
txt_m4:  !scr "-4%", 0
txt_m7:  !scr "-7%", 0
txt_m14: !scr "-14%", 0
txt_p2:  !scr "+2%", 0
txt_p4:  !scr "+4%", 0
txt_p8:  !scr "+8%", 0
txt_p15: !scr "+15%", 0
txt_firecont: !scr "fire: back home", 0
lbl_home:     !scr "Go Home", 0
lbl_toilet:   !scr "Go to Toilet", 0
lbl_walkoff:  !scr "Walk to office", 0
lbl_office:   !scr "Go to Office", 0
lbl_truth:    !scr "Go to Truth", 0
lbl_walkhome: !scr "Walk home", 0
lbl_sleep:    !scr "Go to Sleep", 0
lbl_break:    !scr "Break the Loop", 0
lbl_work:     !scr "Do Work", 0
lbl_coffee:   !scr "Have a Coffee", 0
lbl_sumph:    !scr "Talk to Sumphore", 0
lbl_homeless: !scr "Talk to the homeless guy", 0
lbl_talktruth: !scr "Talk to ????", 0
lbl_food:     !scr "Eat Fast Food", 0

; ---- window variables ----
cur_win:  !byte W_OTHER
dec_n:    !byte 0
dec_sel:  !byte 0
dec_list: !fill MAXDEC, 0
db_i:     !byte 0
db_id:    !byte 0
ld_i:     !byte 0
bd_m:     !byte 0
bd_new:   !byte 0
bd_old:   !byte 0
bd_lo:    !byte 0
bd_hi:    !byte 0
bd_fl:    !byte 0
bd_col:   !byte 0
zt5x:     !byte 0
td_i:     !byte 0
