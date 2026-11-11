; -----------------------------------------------------------
; minigames.asm - the three minigames of the original:
;   button mash (window.minigame.mash.lua): the alarm rings,
;     hammer fire to wake norman - the light of the room
;     opens up as the bar fills
;   rhythm (window.minigame.rhythm.lua): to sleep, hit fire
;     while the beat line crosses the shrinking target; the
;     light closes in with every hit
;   DDR (window.minigame.ddr.lua): the work itself - arrows
;     fall to the four targets; at ascensions 1-3 the rules
;     quietly change (only the white ones / only the left
;     ones / none at all) and obeying them is how norman
;     notices the seams
; their UI sits in the HUD rows under the scene
; -----------------------------------------------------------

MASH_NEWGAME = 0         ; the very first morning
MASH_WAKE    = 1         ; every other morning
RH_SLEEP     = 0

DDR_NORMAL   = 0
DDR_SPECIAL  = 1         ; only the white arrows
DDR_LEFT     = 2         ; only the left arrows
DDR_NOTHING  = 3         ; hit nothing

MG_BAR_ROW = 20          ; the progress bar: columns 5-34
MG_TXT_ROW = 18
MG_BTN_ROW = 22

; ---- the scene behind mash and rhythm: the bedroom with
; norman asleep in it, then the focus closes over it ----
mg_scene:
    lda #W_MINI
    sta cur_win
    lda #1
    sta in_minigame
    sta meters_hidden
    lda #0
    sta flick_on
    jsr input_flush
    jsr fx_restore
    jsr blank_on
    lda #0
    sta SPR_EN
    jsr cls_all
    lda #BG_BEDROOM
    jsr scene_load
    lda #0
    sta fig_flags
    lda #FIG_SLEEPING
    ldx #POS_SLEEPING_X
    ldy #POS_SLEEPING_Y
    jsr fig_draw
    jsr shadow_save
    lda #LAY_SCENE
    jsr set_layout
    lda #24              ; (98, 50) in 4 px units
    sta focus_x
    lda #12
    sta focus_y
    jmp focus_center

; ---- a 30-cell bar on MG_BAR_ROW: A = filled pixels 0-240,
; mg_barcol = fill color, paper light grey ----
mg_bar:
    sta zt3
    ldx #SCN_X
    ldy #MG_BAR_ROW
    jsr cell_ptrs
    lda #0
    sta zt5
mgb_cell:
    lda zt5
    asl
    asl
    asl
    sta zt6
    lda zt3
    sec
    sbc zt6
    bcs mgb_pos
    lda #0
mgb_pos:
    cmp #8
    bcc mgb_n
    lda #8
mgb_n:
    tax
    lda leftmask,x
    ldy #7
mgb_rows:
    sta (dst),y
    dey
    bpl mgb_rows
    lda mg_barcol
    asl
    asl
    asl
    asl
    ora #LGREY
    ldy #0
    sta (cdst),y
    jsr adv_cell
    inc zt5
    lda zt5
    cmp #SCN_W
    bne mgb_cell
    rts

; ---- the fire button under the bar, lit while pressed ----
mg_button:
    lda #LGREY << 4
    ldx mg_pressed
    beq mgbt_c
    lda #BLACK << 4 | LBLUE
mgbt_c:
    pha
    lda #<txt_firebtn
    sta txt
    lda #>txt_firebtn
    sta txt+1
    pla
    ldy #MG_BTN_ROW
    jmp print_center

; ---- the success box: in the middle of the DDR screen, on the
; instruction row under the multicolor scene of mash and rhythm ----
win_overlay:
    lda layout
    cmp #LAY_HIRES
    beq wo_box
    lda txt
    pha
    lda txt+1
    pha
    lda #0
    ldx #MG_TXT_ROW
    ldy #1
    jsr clear_rows
    pla
    sta txt+1
    pla
    sta txt
    ldy #MG_TXT_ROW
    lda #BLACK << 4 | WHITE
    jmp print_center
wo_box:
    lda txt
    pha
    lda txt+1
    pha
    lda #14
    sta fr_col
    lda #6
    sta fr_row
    lda #12
    sta fr_w
    lda #3
    sta fr_h
    lda #WHITE << 4
    jsr draw_box
    pla
    sta txt+1
    pla
    sta txt
    ldy #7
    lda #WHITE << 4
    jmp print_center

; ============================================================
; button mash
; ============================================================
mash_start:
    sta mash_mode
    jsr music_stop
    jsr mg_scene
    lda #0
    sta mash_fill
    sta mash_fill+1
    sta mg_pressed
    sta mg_win
    sta mash_time
    sta mash_time+1
    sta focus_r
!ifdef QUICKMINI {
    lda #99              ; test builds: one press from awake
    sta mash_fill+1
    lda #0
}
    lda #$ff
    sta mg_lastr
    jsr focus_apply
    +center MG_TXT_ROW, C_ACCENT << 4, txt_wakenorman
    jsr mash_bar
    jsr mg_button
    jsr blank_off
    +setupd mash_update
    rts

mash_bar:
    lda mash_fill+1      ; 0-100 -> 0-240 pixels: * 12 / 5
    ldx #12
    jsr mul8
    lda mullo
    sta divlo
    lda mulhi
    sta divhi
    lda #5
    jsr div16
    lda #LBLUE
    ldx mash_fill+1
    cpx #34
    bcc mbr_c
    lda #BLUE
    cpx #67
    bcc mbr_c
    lda #C_ITEM
mbr_c:
    sta mg_barcol
    lda divlo
    jmp mg_bar

mash_update:
    lda mg_win
    beq mu_play
    dec mg_win
    beq mu_won
    rts
mu_won:
    ; the success box is over: rewards, then the morning
    jsr meter_wakeup     ; both mornings pay the wake-up reward
    lda gameover
    bmi mu_ok
    rts
mu_ok:
    lda #1
    sta home_norman
    lda #0
    sta done_work
    sta been_office
    sta meters_hidden
    lda #MUS_WORK
    jsr play_tune
    lda mash_mode
    beq mu_enter
    lda mm_flashwake     ; after the man's words: the level-up flash
    beq mu_enter
    lda #0
    sta mm_flashwake
    jsr game_enter
    lda #<game_enter
    ldx #>game_enter
    jmp flash_start
mu_enter:
    jmp game_enter
mu_play:
    inc mash_time
    bne mu_t
    inc mash_time+1
mu_t:
    lda in_new
    and #IN_FIRE
    beq mu_decay
    lda #SFX_DRUM
    jsr sfx_play
    lda mash_fill+1
    clc
    adc #8
    cmp #100
    bcc mu_cap
    lda #100
mu_cap:
    sta mash_fill+1
    lda #7
    sta mg_pressed
    jsr mg_button
mu_decay:
    lda mash_fill+1
    cmp #100
    bcc mu_deg
    ; full: success
    lda #SFX_SELECT
    jsr sfx_play
    lda #WIN_TIME
    sta mg_win
    jsr mash_bar
    lda #<txt_success
    sta txt
    lda #>txt_success
    sta txt+1
    jmp win_overlay
mu_deg:
    ; degradation 0.18 + fill * 0.0072 a frame (PAL-scaled), in 1/256
    lda mash_fill+1
    ldx #215
    jsr mul8
    lda mulhi
    clc
    adc mash_fill+1
    adc #46
    sta zt0
    lda mash_fill
    sec
    sbc zt0
    sta mash_fill
    lda mash_fill+1
    sbc #0
    bcs mu_dset
    lda #0
    sta mash_fill
mu_dset:
    sta mash_fill+1
    lda mg_pressed
    beq mu_np
    dec mg_pressed
    bne mu_np
    jsr mg_button
mu_np:
    jsr mash_bar
    ; the light: radius = fill% of 42
    lda mash_fill+1
    ldx #107
    jsr mul8
    lda mulhi
    cmp mg_lastr
    beq mu_done
    sta mg_lastr
    sta focus_r
    jsr focus_apply
mu_done:
    rts

; ============================================================
; rhythm: the beat line bounces over the bar (sprite 7)
; ============================================================
RH_SPEED = 1106          ; 0.018 of 240 px a frame, in 1/256
RH_COOL  = 12            ; frames between two presses

rhythm_start:
    jsr music_stop
    jsr mg_scene
    lda #0
    sta rh_pos
    sta rh_pos+1
    sta rh_dir
    sta rh_score
    sta rh_cool
    sta mg_pressed
    sta mg_win
    lda #$ff
    sta mg_lastr
!ifdef QUICKMINI {
    lda #9               ; test builds: one hit from asleep
    sta rh_score
}
    jsr rh_focus
    +center MG_TXT_ROW, C_ACCENT << 4, txt_sleepnorman
    jsr rh_bar
    jsr mg_button
    ; the beat line sprite
    lda #SPRBLK+4
    sta SPRPTR+7
    lda #LBLUE
    sta SPRCOL+7
    lda #50 + MG_BAR_ROW*8
    sta SPRY0+14
    jsr rh_sprite
    lda #$80
    sta SPR_EN
    jsr blank_off
    +setupd rhythm_update
    rts

; ---- the light closes in: radius = (1 - score/10) of 42 ----
rh_focus:
    lda #10
    sec
    sbc rh_score
    tax
    lda rhrad,x
    cmp mg_lastr
    beq rhf_done
    sta mg_lastr
    sta focus_r
    jmp focus_apply
rhf_done:
    rts

rhrad: !byte 0, 4, 8, 13, 17, 21, 25, 29, 34, 38, 42

; ---- the bar: the target in yellow on dark grey ----
rh_bar:
    ldx rh_score
    lda rhwidth,x
    sta zt2
    lsr
    sta zt0
    lda #120
    sec
    sbc zt0
    sta rh_left
    clc
    adc zt2
    sta rh_right
    ldx #SCN_X
    ldy #MG_BAR_ROW
    jsr cell_ptrs
    lda #0
    sta zt5
rhb_cell:
    lda #0
    sta zt4              ; the cell's bits
    lda zt5
    asl
    asl
    asl
    sta zt6              ; first pixel
    ldx #0
rhb_px:
    lda zt4
    asl
    sta zt4
    txa
    clc
    adc zt6
    cmp rh_left
    bcc rhb_off
    cmp rh_right
    bcs rhb_off
    inc zt4
rhb_off:
    inx
    cpx #8
    bne rhb_px
    lda zt4
    ldy #7
rhb_rows:
    sta (dst),y
    dey
    bpl rhb_rows
    lda #C_ITEM << 4 | DGREY
    ldy #0
    sta (cdst),y
    jsr adv_cell
    inc zt5
    lda zt5
    cmp #SCN_W
    bne rhb_cell
    rts

; target widths (0.3 * 0.9^score of 240 px)
rhwidth: !byte 72, 65, 58, 52, 47, 43, 38, 34, 31, 28, 25

rh_sprite:
    lda rh_pos+1
    clc
    adc #24 + SCN_X*8 - 1
    sta SPRX0+14
    lda SPRMSB
    and #$7f
    bcc rhs_lo
    ora #$80
rhs_lo:
    sta SPRMSB
    rts

rhythm_update:
    lda mg_win
    beq ru_play
    dec mg_win
    beq ru_won
    rts
ru_won:
    lda #0
    sta SPR_EN
    jsr meter_flat       ; Meter.on_minigame_complete(false)
    lda gameover
    bmi ru_ok
    rts
ru_ok:
    jmp sleep_won
ru_play:
    ; move the line, bounce at the ends
    lda rh_dir
    bne ru_left
    lda rh_pos
    clc
    adc #<RH_SPEED
    sta rh_pos
    lda rh_pos+1
    adc #>RH_SPEED
    sta rh_pos+1
    cmp #240
    bcc ru_moved
    lda #239
    sta rh_pos+1
    lda #1
    sta rh_dir
    bne ru_moved
ru_left:
    lda rh_pos
    sec
    sbc #<RH_SPEED
    sta rh_pos
    lda rh_pos+1
    sbc #>RH_SPEED
    sta rh_pos+1
    bcs ru_moved
    lda #0
    sta rh_pos
    sta rh_pos+1
    sta rh_dir
ru_moved:
    jsr rh_sprite
    lda rh_cool
    beq ru_cool
    dec rh_cool
ru_cool:
    lda in_new
    and #IN_FIRE
    beq ru_nopress
    lda rh_cool
    bne ru_nopress
    lda #RH_COOL
    sta rh_cool
    lda #8
    sta mg_pressed
    jsr mg_button
!ifdef QUICKMINI {
    jmp ru_hit           ; test builds: every press hits
}
    lda rh_pos+1
    cmp rh_left
    bcc ru_miss
    cmp rh_right
    bcs ru_miss
ru_hit:
    inc rh_score
    lda #SFX_BEEP
    jsr sfx_play
    jmp ru_scored
ru_miss:
    lda #SFX_BLOOP
    jsr sfx_play
    lda rh_score
    beq ru_scored
    dec rh_score
ru_scored:
    jsr rh_bar
    jsr rh_focus
    lda rh_score
    cmp #10
    bcc ru_nopress
    lda #SFX_SELECT
    jsr sfx_play
    lda #WIN_TIME
    sta mg_win
    lda #<txt_success
    sta txt
    lda #>txt_success
    sta txt+1
    jmp win_overlay
ru_nopress:
    lda mg_pressed
    beq ru_done
    dec mg_pressed
    bne ru_done
    jmp mg_button
ru_done:
    rts

; ---- asleep: the man's words, then the next morning ----
sleep_won:
    lda asc_level
    cmp #8               ; breaking the loop at 8 reaches 9
    bne sw_go
    jsr asc_increase
sw_go:
    jsr asc_consume
    jsr mman_after_sleep
    jmp game_enter

; ============================================================
; DDR: arrows ride the sprites 0-7
; ============================================================
DDR_NOTES  = 30          ; arrows in a song
DDR_Y0     = 32          ; they appear here (scene pixels)
DDR_TY     = 120         ; the targets' line
DDR_HIT    = 8           ; +-8 px counts as a hit
DDR_COOL   = 8           ; frames between presses of one direction
DDR_LIT    = 7           ; frames a target stays lit
DDR_ROWF   = 20          ; frames per pattern row (24 at 60 Hz)

ddr_start:
    sta ddr_mode
    lda #W_MINI
    sta cur_win
    lda #1
    sta in_minigame
    sta meters_hidden
    lda #0
    sta flick_on
    jsr input_flush
    jsr fx_restore
    lda #MUS_DDR
    jsr play_tune
    ; the song: 30 arrows on generated rows
    lda #0
    sta zt0
    sta dd_t
    sta dd_t+1
    sta ddr_nspec
dds_gen:
    jsr rand8            ; 2-4 rows after the last one
    and #3
    beq dds_gen
    clc
    adc #1
    tax
dds_rows:
    lda dd_t
    clc
    adc #DDR_ROWF
    sta dd_t
    bcc dds_r1
    inc dd_t+1
dds_r1:
    dex
    bne dds_rows
    ldx zt0
    lda dd_t
    sta pat_flo,x
    lda dd_t+1
    sta pat_fhi,x
    jsr rand8
    and #3
    sta pat_dir,x
    lda #0
    sta pat_spec,x
    lda ddr_mode
    cmp #DDR_SPECIAL     ; every fifth one is special
    bne dds_nsp
    lda ddr5,x
    sta pat_spec,x
dds_nsp:
    ; what the end check counts: the left ones or the specials
    lda ddr_mode
    cmp #DDR_LEFT
    bne dds_cs
    lda pat_dir,x
    bne dds_next
    inc ddr_nspec
    bne dds_next
dds_cs:
    lda pat_spec,x
    beq dds_next
    inc ddr_nspec
dds_next:
    inc zt0
    lda zt0
    cmp #DDR_NOTES
    bne dds_gen
    ; the rest of the state
    lda #0
    sta dd_fill
    sta dd_frame
    sta dd_frame+1
    sta dd_pidx
    sta dd_misses
    sta dd_counter
    sta mg_win
    ldx #7
dds_clr:
    sta ar_on,x
    dex
    bpl dds_clr
    ldx #3
dds_c2:
    sta dd_cool,x
    sta dd_lit,x
    dex
    bpl dds_c2
    lda #1
    sta dd_cond
!ifdef QUICKMINI {
    lda #100             ; test builds: the song is won at once
    sta dd_fill
}
    ; slow workers get slower arrows (wpm < 100)
    lda #<461            ; 1.8 px a frame
    sta dd_speed
    lda #>461
    sta dd_speed+1
    lda mhi+M_WPM
    bne dds_draw
    lda mlo+M_WPM
    cmp #100
    bcs dds_draw
    lda #<768            ; 3.0
    sta dd_speed
    lda #>768
    sta dd_speed+1
dds_draw:
    jsr blank_on
    lda #0
    sta SPR_EN
    jsr cls_all
    lda #BG_DDR
    jsr scene_load
    jsr ddr_targets
    +center MG_TXT_ROW, C_ACCENT << 4, txt_hitarrows
    jsr ddr_bar
    ldx #7
dds_spr:
    lda #LBLUE
    sta SPRCOL,x
    dex
    bpl dds_spr
    lda #0
    sta SPRMSB
    jsr blank_off
    +setupd ddr_update
    rts

ddr5: !for i, 0, DDR_NOTES-1 { !byte ((i + 1) % 5 = 0) & 1 }

; ---- the four targets: 2x2 cells on rows 15-16 ----
ddr_targets:
    lda #0
    sta zt5
dt_lp:
    ldx zt5
    lda #LGREY << 4
    ldy dd_lit,x
    beq dt_c
    lda #CYAN << 4
dt_c:
    sta pcolor
    lda zt5              ; the shape: 32 bytes per direction
    asl
    asl
    asl
    asl
    asl
    clc
    adc #<arrow_cells
    sta src
    lda #>arrow_cells
    adc #0
    sta src+1
    lda ddrcol,x
    tax
    ldy #15
    jsr cell_ptrs
    jsr clk_two
    ldx zt5
    lda ddrcol,x
    tax
    ldy #16
    jsr cell_ptrs
    jsr clk_two
    inc zt5
    lda zt5
    cmp #4
    bne dt_lp
    rts

ddrcol: !byte SCN_X+6, SCN_X+11, SCN_X+17, SCN_X+22   ; target columns
ddrsx:  !byte 24+(SCN_X+6)*8, 24+(SCN_X+11)*8, 24+(SCN_X+17)*8, 24+(SCN_X+22)*8
; the hit tones per direction (left, down, up, right), as the
; original turns notes into arrows: C left, A down, D/E up, F/G right
ddrtone: !byte $22, $39, $2b, $33     ; C-5, A-5, E-5, G-5 (the notes the original maps to them)

ddr_bar:
    lda dd_fill          ; 0-100 -> 0-240 pixels
    ldx #12
    jsr mul8
    lda mullo
    sta divlo
    lda mulhi
    sta divhi
    lda #5
    jsr div16
    lda #LBLUE
    ldx dd_fill
    cpx #34
    bcc dbr_c
    lda #BLUE
    cpx #67
    bcc dbr_c
    lda #C_ITEM
dbr_c:
    sta mg_barcol
    lda divlo
    jmp mg_bar

ddr_update:
    lda mg_win
    beq du_play
    dec mg_win
    beq du_over
    rts
du_over:
    lda #0
    sta SPR_EN
    jsr music_stop
    lda ddr_test         ; the test mode's DDR test: back to the menu
    beq du_real
    lda #0
    sta ddr_test
    sta in_minigame
    +fadeto menu_init
du_real:
    lda dd_misses
    jsr meter_ddr
    lda gameover
    bpl du_ret
    ; on_win: obeying the hidden rule at ascension 1-3 moves on
    lda dd_cond
    beq du_won
    lda asc_level
    beq du_won
    cmp #4
    bcs du_won
    lda #1
    sta should_ascend
du_won:
    lda #0
    sta meters_hidden
    lda #1
    sta done_work
    lda #SC_OFFICE
    jsr goto_screen
    jmp game_enter
du_ret:
    rts
du_play:
    lda dd_fill
    cmp #100
    bcc du_run
    jmp ddr_end
du_run:
    inc dd_frame
    bne du_f1
    inc dd_frame+1
du_f1:
    ; the song is over once its last arrow is gone
    lda dd_pidx
    cmp #DDR_NOTES
    bcc du_spawn
    ldx #7
du_any:
    lda ar_on,x
    bne du_move
    dex
    bpl du_any
    jmp ddr_end
du_spawn:
    ldx dd_pidx
    lda dd_frame+1
    cmp pat_fhi,x
    bcc du_move
    bne du_sp
    lda dd_frame
    cmp pat_flo,x
    bcc du_move
du_sp:
    jsr ddr_spawn
    inc dd_pidx
    lda dd_pidx
    cmp #DDR_NOTES
    bcc du_spawn
du_move:
    ; fall, and count the ones that slip by
    ldx #7
du_mv:
    lda ar_on,x
    beq du_mvn
    lda ar_ylo,x
    clc
    adc dd_speed
    sta ar_ylo,x
    lda ar_y,x
    adc dd_speed+1
    sta ar_y,x
    cmp #DDR_TY+DDR_HIT+1
    bcc du_mvn
    lda #0
    sta ar_on,x
    lda dd_fill
    sec
    sbc #5
    bcs du_pen
    lda #0
du_pen:
    sta dd_fill
    jsr dd_miss
    jsr ddr_bar
du_mvn:
    dex
    bpl du_mv
    ; cool-downs and lit targets
    ldx #3
du_cd:
    lda dd_cool,x
    beq du_cd1
    dec dd_cool,x
du_cd1:
    lda dd_lit,x
    beq du_cd2
    dec dd_lit,x
    bne du_cd2
    lda #1
    sta dd_redraw
du_cd2:
    dex
    bpl du_cd
    ; the presses: left, down, up, right
    ldx #3
du_in:
    lda in_new
    and ddrbit,x
    beq du_inn
    lda dd_cool,x
    bne du_inn
    lda #DDR_COOL
    sta dd_cool,x
    lda #DDR_LIT
    sta dd_lit,x
    lda #1
    sta dd_redraw
    stx dd_d
    jsr ddr_press
    ldx dd_d
du_inn:
    dex
    bpl du_in
    lda dd_redraw
    beq du_spr
    lda #0
    sta dd_redraw
    jsr ddr_targets
du_spr:
    jmp ddr_sprites

ddrbit: !byte IN_LEFT, IN_DOWN, IN_UP, IN_RIGHT

; ---- a new arrow from pattern entry X ----
ddr_spawn:
    ldy #7
dsp_f:
    lda ar_on,y
    beq dsp_got
    dey
    bpl dsp_f
    rts                  ; all eight sprites busy: skip it
dsp_got:
    lda #1
    sta ar_on,y
    lda #DDR_Y0
    sta ar_y,y
    lda #0
    sta ar_ylo,y
    lda pat_dir,x
    sta ar_dir,y
    lda pat_spec,x
    sta ar_spec,y
    rts

; ---- direction dd_d pressed: the first arrow in its window ----
ddr_press:
    ldx #7
dp_lp:
    lda ar_on,x
    beq dp_next
    lda ar_dir,x
    cmp dd_d
    bne dp_next
    lda ar_y,x
    sec
    sbc #DDR_TY
    bcs dp_abs
    eor #$ff
    adc #1
dp_abs:
    cmp #DDR_HIT+1
    bcs dp_next
    ; a hit
    lda #0
    sta ar_on,x
    jsr ddr_hit_special
    lda dd_fill
    clc
    adc #10
    cmp #100
    bcc dp_cap
    lda #100
dp_cap:
    sta dd_fill
    jmp ddr_bar
dp_next:
    dex
    bpl dp_lp
    ; nothing to hit: -2 and a mistake
    lda dd_fill
    sec
    sbc #2
    bcs dp_pen
    lda #0
dp_pen:
    sta dd_fill
    jsr dd_miss
    jmp ddr_bar

dd_miss:
    lda dd_misses
    cmp #$ff
    beq ddm_d
    inc dd_misses
ddm_d:
    rts

; ---- on_arrow_hit_special: arrow X was hit ----
ddr_hit_special:
    lda ddr_mode
    beq dhs_tone         ; normal: just the tone
    cmp #DDR_SPECIAL
    bne dhs_left
    lda ar_spec,x
    beq dhs_wrong
    inc dd_counter
    jmp dhs_tone
dhs_left:
    cmp #DDR_LEFT
    bne dhs_wrong        ; only_nothing: any hit is wrong
    lda ar_dir,x
    bne dhs_wrong
    inc dd_counter
    lda dd_fill          ; a left hit may not end the song early
    clc
    adc #10
    cmp #100
    bcc dhs_tone
    lda dd_fill
    sec
    sbc #10
    sta dd_fill
dhs_tone:
    lda ar_dir,x
    tay
    lda ddrtone,y
    jmp sfx_hit
dhs_wrong:
    jsr dd_miss
    lda dd_cond
    beq dhs_w2
    lda #SFX_BLOOP
    jsr sfx_play
dhs_w2:
    lda #0
    sta dd_cond
    rts

; ---- the song is over (MinigameDDRWindow.on_end) ----
ddr_end:
    lda #SFX_SELECT
    jsr sfx_play
    lda #WIN_TIME
    sta mg_win
    lda #0
    sta SPR_EN
    lda ddr_mode
    cmp #DDR_NOTHING
    beq de_cond
    lda dd_counter
    cmp ddr_nspec
    beq de_cond
    lda #0
    sta dd_cond
de_cond:
    lda dd_cond
    beq de_meh
    lda ddr_mode
    beq de_success
    lda #100
    sta dd_fill
    jsr ddr_bar
de_success:
    lda #<txt_successq
    sta txt
    lda #>txt_successq
    sta txt+1
    jmp win_overlay
de_meh:
    lda #<txt_meh
    sta txt
    lda #>txt_meh
    sta txt+1
    jmp win_overlay

; ---- the arrows onto the sprites ----
ddr_sprites:
    lda #0
    sta zt0
    ldx #7
dsr_lp:
    lda ar_on,x
    beq dsr_n
    lda zt0
    ora sprbit,x
    sta zt0
    lda ar_dir,x
    tay
    clc
    adc #SPRBLK
    sta SPRPTR,x
    txa
    asl
    tay
    lda ar_y,x
    clc
    adc #50
    sta SPRY0,y
    lda ar_dir,x
    stx zt1
    tax
    lda ddrsx,x
    ldx zt1
    sta SPRX0,y
    lda #LBLUE
    ldy ar_spec,x
    beq dsr_c
    lda #WHITE
dsr_c:
    sta SPRCOL,x
dsr_n:
    dex
    bpl dsr_lp
    lda zt0
    sta SPR_EN
    rts

sprbit: !byte 1, 2, 4, 8, 16, 32, 64, 128

; ---- texts ----
txt_firebtn:    !scr " FIRE ", 0
txt_wakenorman: !scr "Wake up Norman!", 0
txt_sleepnorman: !scr "Sleep Norman ... Sleep!", 0
txt_hitarrows:  !scr "Hit the arrows!", 0
txt_success:    !scr "SUCCESS", 0
txt_successq:   !scr "SUCCESS...?", 0
txt_meh:        !scr "MEH...", 0

; ---- variables ----
mash_mode:  !byte 0
mash_fill:  !word 0      ; 8.8: 0-100
mg_pressed: !byte 0
mg_win:     !byte 0
mg_lastr:   !byte 0
mg_barcol:  !byte 0
rh_pos:     !word 0      ; 8.8 pixels 0-239
rh_dir:     !byte 0
rh_score:   !byte 0
rh_cool:    !byte 0
rh_left:    !byte 0
rh_right:   !byte 0
ddr_mode:   !byte 0
ddr_nspec:  !byte 0
dd_t:       !word 0
dd_fill:    !byte 0
dd_frame:   !word 0
dd_pidx:    !byte 0
dd_misses:  !byte 0
dd_counter: !byte 0
dd_cond:    !byte 0
dd_speed:   !word 0
dd_redraw:  !byte 0
dd_d:       !byte 0
dd_cool:    !fill 4, 0
dd_lit:     !fill 4, 0
pat_flo:    !fill DDR_NOTES, 0
pat_fhi:    !fill DDR_NOTES, 0
pat_dir:    !fill DDR_NOTES, 0
pat_spec:   !fill DDR_NOTES, 0
ar_on:      !fill 8, 0
ar_y:       !fill 8, 0
ar_ylo:     !fill 8, 0
ar_dir:     !fill 8, 0
ar_spec:    !fill 8, 0
