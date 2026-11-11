; -----------------------------------------------------------
; discuss.asm - the discussion window (window.discussion.lua
; + logic.discussion.lua): the question in a framed box over
; the scene, the answers on the bar below (left / right to
; pick, fire to answer); answers lead to the next step or
; end it, and steps / endings may carry an action
;
; the texts and their tree live in gen_text.asm
; -----------------------------------------------------------

BOX_COL = 2              ; the question box: columns 2-37
BOX_ROW = 3              ; rows 3-10
BOX_W   = 36
BOX_H   = 8

; ---- A = discussion, X = first step (0-based) ----
disc_start:
    sta ds_id
    stx ds_step
    lda #1
    sta meters_hidden
    lda #0
    sta ds_sel
    lda #W_DISC
    sta cur_win
    jsr input_flush
    jsr blank_on
    lda #0
    jsr cls_all
    jsr scene_draw
    jsr shadow_save
    jsr ds_show
    lda cur_screen       ; multicolor scene, the box rows hires
    cmp #SC_WORK
    bcs ds_lay
    lda #LAY_DISC
    jsr set_layout
ds_lay:
    jsr blank_off
    +setupd disc_update
    rts

; ---- the discussion's record -> ptr2 ----
ds_rec:
    ldx ds_id
    lda disclo,x
    sta ptr2
    lda dischi,x
    sta ptr2+1
    rts

; ---- the current step's record -> ptr3 ----
ds_steprec:
    jsr ds_rec
    lda ds_step
    asl
    clc
    adc #2
    tay
    lda (ptr2),y
    sta ptr3
    iny
    lda (ptr2),y
    sta ptr3+1
    rts

; ---- draw the box with the question and the answer bar ----
ds_show:
    lda #BOX_COL
    sta fr_col
    lda #BOX_ROW
    sta fr_row
    lda #BOX_W
    sta fr_w
    lda #BOX_H
    sta fr_h
    lda #LBLUE << 4
    jsr draw_box
    jsr ds_steprec
    ldy #0
    lda (ptr3),y
    sta txt
    iny
    lda (ptr3),y
    sta txt+1
    ; vertically centered in the six text rows
    ldy #0
    lda (txt),y
    sta zt3              ; lines
    lda #6
    sec
    sbc zt3
    lsr
    clc
    adc #BOX_ROW+1
    sta zt4              ; first row
    inc txt
    bne ds_q
    inc txt+1
ds_q:
    lda zt3
    beq ds_qdone
    ldy zt4
    lda #WHITE << 4
    jsr print_center
    jsr text_skip
    inc zt4
    dec zt3
    bne ds_q
ds_qdone:
    jmp ds_bar

; ---- step txt over the 0-terminated line it points at ----
text_skip:
    ldy #0
tsk_lp:
    lda (txt),y
    beq tsk_end
    iny
    bne tsk_lp
tsk_end:
    iny
    tya
    clc
    adc txt
    sta txt
    bcc tsk_d
    inc txt+1
tsk_d:
    rts

; ---- the answer bar: < answer > ----
ds_bar:
    lda #DGREY << 4 | DGREY
    ldx #BAR_TOP
    ldy #3
    jsr clear_rows
    jsr ds_steprec
    ldy #2
    lda (ptr3),y
    sta ds_nans
    lda #C_ITEM << 4 | DGREY
    sta pcolor
    ldx #0
    ldy #BAR_ROW
    lda #$3c             ; <
    jsr char_at
    ldx #39
    ldy #BAR_ROW
    lda #$3e             ; >
    jsr char_at
    jsr ds_ansrec        ; Y = offset of the answer in the step
    lda (ptr3),y
    sta txt
    iny
    lda (ptr3),y
    sta txt+1
    ldy #0
    lda (txt),y
    sta zt3
    lda #BAR_ROW
    sta zt4
    inc txt
    bne ds_a
    inc txt+1
ds_a:
    ldy zt4
    lda #C_ITEM << 4 | DGREY
    jsr print_center
    jsr text_skip
    inc zt4
    dec zt3
    bne ds_a
    rts

; ---- Y = offset of the selected answer's record in the step ----
ds_ansrec:
    lda ds_sel
    asl
    asl
    clc
    adc #3
    tay
    rts

disc_update:
    lda ds_nans
    beq du_done
    lda in_new
    and #IN_LEFT
    beq du_noleft
    jsr sfx_beep
    dec ds_sel
    bpl du_moved
    ldx ds_nans
    dex
    stx ds_sel
    jmp du_moved
du_noleft:
    lda in_new
    and #IN_RIGHT
    beq du_noright
    jsr sfx_beep
    inc ds_sel
    lda ds_sel
    cmp ds_nans
    bcc du_moved
    lda #0
    sta ds_sel
du_moved:
    jmp ds_bar
du_noright:
    lda in_new
    and #IN_FIRE
    beq du_done
    lda #SFX_SELECT
    jsr sfx_play
    jsr ds_steprec
    jsr ds_ansrec
    iny
    iny
    lda (ptr3),y         ; next step (1-based, 0 = the end)
    sta ds_next
    iny
    lda (ptr3),y         ; the answer's action
    jsr run_action
    lda ds_next
    beq ds_finish
    sec
    sbc #1
    sta ds_step
    lda #0
    sta ds_sel
    jsr ds_show
du_done:
    rts

; ---- Discussion.finish: meters back, the ending's action,
; back to the game window ----
ds_finish:
    lda #0
    sta meters_hidden
    sta flick_on
    jsr ds_rec
    ldy #0
    lda (ptr2),y
    jsr run_action
    jsr fx_restore
    jmp game_enter

; ---- the actions of answers and endings: A = ACT_* ----
run_action:
    cmp #0
    beq ra_none
    asl
    tax
    lda acts-1,x
    pha
    lda acts-2,x
    pha
ra_none:
    rts

acts:
    !word ac_coworker-1, ac_sumphore-1, ac_glitch-1, ac_pizza_end-1
    !word ac_sumph6-1, ac_sumph_done-1, ac_echo_done-1, ac_eat-1
    !word ac_met-1, ac_ism10-1, ac_bm10-1, ac_ism5-1, ac_wpm10-1, ac_drain-1

ac_coworker:
    jmp meter_coworker
ac_sumphore:
    jmp meter_sumphore
ac_glitch:
    jsr meter_coworker
    inc glitch_count
    jmp glitch_hide
ac_pizza_end:
    lda #0
    sta food_near
    rts
ac_sumph6:
    jsr meter_sumphore
    lda #1
    sta should_ascend
    jsr day_increase
    lda gameover
    bpl ac_s6over
    lda #1               ; the level's text, no skipping
    jmp mman_after_day
ac_s6over:
    rts
ac_sumph_done:
    lda #1
    sta talked_sumph
    rts
ac_echo_done:
    lda #1
    sta talked_echo
    rts
ac_eat:
    +madd M_WPM, 50
    +madd M_ISM, -50
    +madd M_BM, -50
    inc food_eaten
    rts
ac_met:
    lda #1
    sta met_sumphore
    rts
ac_ism10:
    +madd M_ISM, 10
    rts
ac_bm10:
    +madd M_BM, 10
    rts
ac_ism5:
    +madd M_ISM, 5
    rts
ac_wpm10:
    +madd M_WPM, 10
    rts
ac_drain:
    +madd M_ISM, 5
    +madd M_WPM, -100
    rts

; ============================================================
; a framed box: fr_col, fr_row, fr_w, fr_h, A = frame color;
; the inside is cleared to black
; ============================================================
draw_box:
    sta db_frame
    lda fr_col
    sta db_c0
    lda fr_row
    sta db_r0
    lda fr_w
    sta db_w
    lda fr_h
    sta db_h
    lda #0               ; clear it all
    sta fr_byte
    lda #WHITE << 4
    sta fr_color
    jsr fill_rect
    ; corners and edges
    lda db_r0
    sta zt2
    lda #0
    sta zt3              ; row index
dbx_row:
    ldx db_c0
    ldy zt2
    jsr cell_ptrs
    lda #0
    sta zt4              ; column index
dbx_cell:
    ; pattern: 0 inside, 1 top, 2 bottom, 3 left, 4 right,
    ; 5-8 the corners
    ldx #0
    lda zt3
    bne dbx_nt
    ldx #1
dbx_nt:
    lda zt3
    clc
    adc #1
    cmp db_h
    bne dbx_nb
    ldx #2
dbx_nb:
    lda zt4
    bne dbx_nl
    cpx #1
    bne dbx_l2
    ldx #5
    bne dbx_pat
dbx_l2:
    cpx #2
    bne dbx_l3
    ldx #7
    bne dbx_pat
dbx_l3:
    ldx #3
    bne dbx_pat
dbx_nl:
    lda zt4
    clc
    adc #1
    cmp db_w
    bne dbx_pat
    cpx #1
    bne dbx_r2
    ldx #6
    bne dbx_pat
dbx_r2:
    cpx #2
    bne dbx_r3
    ldx #8
    bne dbx_pat
dbx_r3:
    ldx #4
dbx_pat:
    txa
    beq dbx_next
    asl
    asl
    asl
    tax
    ldy #0
dbx_b:
    lda boxpat-8,x
    sta (dst),y
    inx
    iny
    cpy #8
    bne dbx_b
    ldy #0
    lda db_frame
    sta (cdst),y
dbx_next:
    jsr adv_cell
    inc zt4
    lda zt4
    cmp db_w
    bne dbx_cell
    inc zt2
    inc zt3
    lda zt3
    cmp db_h
    beq dbx_done
    jmp dbx_row
dbx_done:
    rts

boxpat:
    !byte 0, 0, 0, $ff, 0, 0, 0, 0               ; 1 top
    !byte 0, 0, 0, 0, $ff, 0, 0, 0               ; 2 bottom
    !byte $10, $10, $10, $10, $10, $10, $10, $10 ; 3 left
    !byte $08, $08, $08, $08, $08, $08, $08, $08 ; 4 right
    !byte 0, 0, 0, $0f, $10, $10, $10, $10       ; 5 top left
    !byte 0, 0, 0, $f0, $08, $08, $08, $08       ; 6 top right
    !byte $10, $10, $10, $10, $0f, 0, 0, 0       ; 7 bottom left
    !byte $08, $08, $08, $08, $f0, 0, 0, 0       ; 8 bottom right

; ---- variables ----
ds_id:    !byte 0
ds_step:  !byte 0
ds_sel:   !byte 0
ds_nans:  !byte 0
ds_next:  !byte 0
db_frame: !byte 0
db_c0:    !byte 0
db_r0:    !byte 0
db_w:     !byte 0
db_h:     !byte 0
