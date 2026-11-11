; -----------------------------------------------------------
; mman.asm - the mysterious man (screen.mysterious_man.lua):
; between the days the man behind the simulation talks about
; norman; his words are typed out line by line under his
; picture, then the day card shows the new day and norman
; wakes up (the alarm-clock button mash) - at ascension 4 he
; may stay in bed, at the end he may break the cycle
; -----------------------------------------------------------

MM_TEXT    = 0
MM_DAY     = 1
MM_CHOICE  = 2
MM_PENDING = 3

MMCB_NONE    = 0
MMCB_NEWGAME = 1         ; the very first text: then the alarm rings

MMT_ROW0 = 18            ; the text window: rows 18-24
MMT_ROWS = 7
HOLD_TIME = 100          ; the last line stays 2 s
DAY_TIME  = 100          ; the day card stays 2 s

; ---- a new day after the man: A = 1 when ascension rose
; (then his text for the level comes first) ----
mman_after_sleep:
    ldx #0
    ldy asc_level
    cpy #ASC_MAX
    bcc mas_set
    ldx #1               ; the last step: the cycle can be broken
mas_set:
    stx mm_break
    jmp mad_go
mman_after_day:
    ldx #0
    stx mm_break
mad_go:
    ldx #MMCB_NONE
    stx mm_cb
    cmp #0
    beq mad_skip
    ldx asc_level
    lda mmtlo-1,x
    sta mm_text
    lda mmthi-1,x
    sta mm_text+1
    jmp mman_start
mad_skip:
    lda #0
    sta mm_text+1
    ; fall through

; ---- MysteriousManScreen.start: mm_text (high byte 0 = skip
; the text), mm_break, mm_cb; the caller enters the window ----
mman_start:
    lda #0
    sta mm_sel
    sta mm_pending
    lda #1
    sta meters_hidden
    lda mm_text+1
    beq ms_skip
    lda #1
    sta mm_show
    sta mm_flashwake
    lda #MM_TEXT
    sta mm_state
    jsr mmt_init
    jmp ms_screen
ms_skip:
    lda #0
    sta mm_show
    sta mm_flashwake
    lda #MM_DAY
    sta mm_state
    lda #DAY_TIME
    sta mm_timer
ms_screen:
    lda #SC_MMAN
    jmp goto_screen

; ---- the typewriter starts on the text ----
mmt_init:
    lda mm_text
    sta mm_tptr
    lda mm_text+1
    sta mm_tptr+1
    ldy #0
    lda (mm_tptr),y
    sta mm_left
    inc mm_tptr
    bne mti_d
    inc mm_tptr+1
mti_d:
    lda #0
    sta mm_ci
    sta mm_done
    sta mm_wait
    lda #MMT_ROW0-1
    sta mm_row
    rts

; ---- the whole screen (game_redraw) ----
mman_draw:
    lda mm_state
    cmp #MM_DAY
    bne md_nday
    jmp mm_draw_day
md_nday:
    cmp #MM_PENDING
    bne md_npend
    jmp mm_draw_pending
md_npend:
    cmp #MM_CHOICE
    bne md_text
    lda mm_break
    beq md_text
    jmp mm_draw_break
md_text:
    lda mm_show
    beq md_black
    lda #BG_MMAN
    jsr scene_load
md_black:
    lda mm_state
    cmp #MM_CHOICE
    bne md_done
    jmp mm_draw_menu
md_done:
    rts

mm_draw_day:
    lda #BG_DAY
    jsr scene_load
    lda day
    sta numval
    jsr num_text
    lda #<txt_dayn
    sta txt
    lda #>txt_dayn
    sta txt+1
    jsr text_len
    sta zt0
    lda #<numtxt
    sta txt
    lda #>numtxt
    sta txt+1
    jsr text_len
    clc
    adc zt0
    sta zt0
    lda #40
    sec
    sbc zt0
    lsr
    tax
    stx zt1
    ldy #8
    lda #<txt_dayn
    sta txt
    lda #>txt_dayn
    sta txt+1
    lda #WHITE << 4
    jsr print_at
    lda #<numtxt
    sta txt
    lda #>numtxt
    sta txt+1
    lda zt1
    clc
    adc #4
    tax
    ldy #8
    lda #WHITE << 4
    jmp print_at

mm_draw_menu:
    lda #0
    ldx #MMT_ROW0
    ldy #MMT_ROWS
    jsr clear_rows
    lda #C_ACCENT << 4
    sta pcolor
    ldx #15
    ldy #19
    lda mm_sel
    bne mdm_2
    lda #$3e             ; >
    jsr char_at
    jmp mdm_t
mdm_2:
    ldy #21
    lda #$3e
    jsr char_at
mdm_t:
    +print 17, 19, C_ACCENT << 4, txt_wakeup
    +print 17, 21, C_ACCENT << 4, txt_stay
    rts

mm_draw_break:
    lda #0
    sta fig_flags
    lda #FIG_BIGNORMAN
    ldx #11
    ldy #0
    jsr fig_draw
    +center 13, C_ITEM << 4, txt_brk1
    +center 14, C_ITEM << 4, txt_brk2
    +center 15, C_ITEM << 4, txt_brk3
    +center 16, C_ITEM << 4, txt_brk4
mm_break_choices:
    lda #0
    ldx #19
    ldy #1
    jsr clear_rows
    ldx #LBLUE << 4
    ldy #WHITE << 4
    lda mm_sel
    beq mbc_c
    ldx #WHITE << 4
    ldy #LBLUE << 4
mbc_c:
    sty zt6
    txa
    pha
    lda #<txt_break
    sta txt
    lda #>txt_break
    sta txt+1
    lda mm_sel
    beq mbc_b1
    lda #<txt_break_n
    sta txt
    lda #>txt_break_n
    sta txt+1
mbc_b1:
    pla
    ldx #10
    ldy #19
    jsr print_at
    lda #<txt_cont_n
    sta txt
    lda #>txt_cont_n
    sta txt+1
    lda mm_sel
    beq mbc_c1
    lda #<txt_cont
    sta txt
    lda #>txt_cont
    sta txt+1
mbc_c1:
    ldx #20
    ldy #19
    lda zt6
    jmp print_at

mm_draw_pending:
    lda #ASC_MAX         ; all nine letters, the last one fading in
    sta zt5
    lda #0
    sta zt4
mdp_lp:
    lda #WHITE << 4
    sta pcolor
    ldx zt4
    inx
    cpx zt5
    bne mdp_lit
    lda asc_fade
    beq mdp_lit
    ldx #BLACK << 4
    cmp #67
    bcs mdp_c
    ldx #DGREY << 4
    cmp #34
    bcs mdp_c
    ldx #LGREY << 4
mdp_c:
    stx pcolor
mdp_lit:
    lda zt4
    asl
    clc
    adc #11
    tax
    ldy #12
    jsr cell_ptrs
    ldx zt4
    lda txt_ascension,x
    jsr put_char
    inc zt4
    lda zt4
    cmp zt5
    bne mdp_lp
    rts

; ============================================================
; once a frame
; ============================================================
mman_update:
    lda mm_state
    asl
    tax
    lda mmupd+1,x
    pha
    lda mmupd,x
    pha
    rts

mmupd: !word mmu_text-1, mmu_day-1, mmu_choice-1, mmu_pending-1

; ---- may the player hurry it? (not at ascension 8) ----
mm_fire_skip:
    lda asc_level
    cmp #8
    beq mfs_no
    lda in_new
    and #IN_FIRE
    rts
mfs_no:
    lda #0
    rts

mmu_text:
    lda mm_done
    beq mmt_typing
    jmp mmt_hold
mmt_typing:
    lda asc_level        ; skippable below ascension 8
    cmp #8
    bcs mmt_type
    lda in_new
    and #IN_FIRE
    beq mmt_type
    jmp mm_to_day
mmt_type:
    lda mm_wait
    beq mmt_go
    dec mm_wait
    rts
mmt_go:
    lda mm_ci
    bne mmt_char
    lda mm_left          ; a new line
    bne mmt_line
    lda #1
    sta mm_done
    lda #HOLD_TIME
    sta mm_timer
    rts
mmt_line:
    inc mm_row
    lda mm_row
    cmp #MMT_ROW0+MMT_ROWS
    bcc mmt_rowok
    jsr mmt_scroll
    lda #MMT_ROW0+MMT_ROWS-1
    sta mm_row
mmt_rowok:
    lda mm_tptr          ; center the line
    sta txt
    lda mm_tptr+1
    sta txt+1
    jsr text_len
    sta zt0
    lda #40
    sec
    sbc zt0
    lsr
    sta mm_col
mmt_char:
    ldy mm_ci
    lda (mm_tptr),y
    beq mmt_eol
    pha
    lda mm_col
    clc
    adc mm_ci
    tax
    ldy mm_row
    lda #LGREY << 4
    sta pcolor
    pla
    jsr char_at
    inc mm_ci
    rts
mmt_eol:
    ldy mm_ci            ; on to the next line
    iny
    tya
    clc
    adc mm_tptr
    sta mm_tptr
    bcc mmt_e1
    inc mm_tptr+1
mmt_e1:
    lda #10              ; a pause after each line, longer if empty
    ldx mm_ci
    bne mmt_e2
    lda #18
mmt_e2:
    sta mm_wait
    lda #0
    sta mm_ci
    dec mm_left
    rts
mmt_hold:
    jsr mm_fire_skip
    bne mm_to_day
    dec mm_timer
    bne mmh_done
    jmp mm_to_day
mmh_done:
    rts

; ---- scroll the text window up one row ----
mmt_scroll:
    ldx #MMT_ROW0
mms_row:
    ldy #0
    lda bmrowlo,x
    sta dst
    lda bmrowhi,x
    sta dst+1
    lda bmrowlo+1,x
    sta src
    lda bmrowhi+1,x
    sta src+1
mms_b1:
    lda (src),y
    sta (dst),y
    iny
    bne mms_b1
    inc src+1
    inc dst+1
mms_b2:
    lda (src),y
    sta (dst),y
    iny
    cpy #320-256
    bne mms_b2
    lda scrrowlo,x
    sta cdst
    lda scrrowhi,x
    sta cdst+1
    lda scrrowlo+1,x
    sta ptr
    lda scrrowhi+1,x
    sta ptr+1
    ldy #39
mms_c:
    lda (ptr),y
    sta (cdst),y
    dey
    bpl mms_c
    inx
    cpx #MMT_ROW0+MMT_ROWS-1
    bne mms_row
    lda #0
    ldx #MMT_ROW0+MMT_ROWS-1
    ldy #1
    jmp clear_rows

; ---- go_to_day_state: the callback first (the new game's
; alarm), then the day card - unless the callback left ----
mm_to_day:
    lda mm_cb
    beq mtd_card
    lda #MMCB_NONE
    sta mm_cb
    jsr mm_newgame_cb
    lda cur_screen
    cmp #SC_MMAN
    beq mtd_card
    rts
mtd_card:
    lda #MM_DAY
    sta mm_state
    lda #DAY_TIME
    sta mm_timer
    jsr blank_on
    lda #0
    jsr cls_all
    jsr mm_draw_day
    jmp blank_off

mmu_day:
    jsr mm_fire_skip
    bne mmd_go
    dec mm_timer
    bne mmd_done
mmd_go:
    lda mm_break
    bne mmd_choice
    lda mm_flashwake
    bne mm_wake
    lda asc_level
    cmp #4
    bne mm_wake
mmd_choice:
    lda #MM_CHOICE
    sta mm_state
    lda #0
    sta mm_sel
    jsr input_flush
    jsr blank_on
    lda #0
    jsr cls_all
    jsr mman_draw
    jmp blank_off
mmd_done:
    rts

; ---- norman wakes up: the alarm-clock mash in the bedroom ----
mm_wake:
    lda #0
    sta home_norman
    lda #SC_HOME
    jsr goto_screen
    lda #MASH_WAKE
    jmp mash_start

; ---- norman stays in bed (the choice at ascension 4) ----
mm_stay:
    lda asc_level
    cmp #4
    bne mms_plain
    lda #1
    sta should_ascend
    jsr day_increase
    lda gameover
    bpl mms_over
    jsr asc_consume
    lda #1
    sta mm_flashwake
    sta mm_show
    ldx asc_level
    lda mmtlo-1,x
    sta mm_text
    lda mmthi-1,x
    sta mm_text+1
    lda #MM_TEXT
    sta mm_state
    jsr mmt_init
    jmp game_redraw
mms_plain:
    jsr day_increase
    lda gameover
    bpl mms_over
    jmp mtd_card
mms_over:
    rts

mmu_choice:
    lda mm_break
    bne mmc_break
    lda in_new
    and #IN_UP | IN_DOWN
    beq mmc_fire
    jsr sfx_beep
    lda mm_sel
    eor #1
    sta mm_sel
    jsr mm_draw_menu
mmc_fire:
    lda in_new
    and #IN_FIRE
    beq mmc_done
    lda #SFX_SELECT
    jsr sfx_play
    lda mm_sel
    bne mm_stay
    jmp mm_wake
mmc_done:
    rts
mmc_break:
    lda in_new
    and #IN_LEFT | IN_UP
    beq mmc_nl
    lda mm_sel
    beq mmc_fb
    jsr sfx_beep
    lda #0
    sta mm_sel
    jsr mm_break_choices
    jmp mmc_fb
mmc_nl:
    lda in_new
    and #IN_RIGHT | IN_DOWN
    beq mmc_fb
    lda mm_sel
    bne mmc_fb
    jsr sfx_beep
    lda #1
    sta mm_sel
    jsr mm_break_choices
mmc_fb:
    lda in_new
    and #IN_FIRE
    beq mmc_done
    lda #SFX_SELECT
    jsr sfx_play
    lda mm_sel
    bne mmc_continue
    ; BREAK: the level-up flash, the last letter, the ending
    lda #MM_PENDING
    sta mm_state
    lda #<game_enter
    ldx #>game_enter
    jmp flash_start
mmc_continue:
    ; CONTINUE: everything starts over, norman already at home
    jsr ctx_reset
    lda #1
    sta in_game
    sta home_norman
    jsr glitch_hide
    lda #0
    sta meters_hidden
    lda #SC_HOME
    jsr goto_screen
    jmp game_enter

mmu_pending:
    lda asc_fade         ; the letter has faded in: the end
    bne mmp_wait
    +fadeto end_init
mmp_wait:
    lda hud_dirty        ; meters_tick marks each fade step
    beq mmp_done
    lda #0
    sta hud_dirty
    jmp mm_draw_pending
mmp_done:
    rts

; ---- the new game's text is over: the alarm rings ----
mm_newgame_cb:
    lda #SFX_ALARM
    jsr sfx_play
    lda #0
    sta home_norman
    lda #SC_HOME
    jsr goto_screen
    lda #MASH_NEWGAME
    jmp mash_start

; ---- Context.new_game ----
new_game:
    jsr ctx_reset
    lda #1
    sta in_game
    lda #SC_HOME
    jsr goto_screen
    lda #<mmt_new
    sta mm_text
    lda #>mmt_new
    sta mm_text+1
    lda #0
    sta mm_break
    lda #MMCB_NEWGAME
    sta mm_cb
    jsr mman_start
    jmp game_enter

; ---- texts ----
txt_dayn:   !scr "day ", 0
txt_wakeup: !scr "Wake Up", 0
txt_stay:   !scr "Stay in Bed", 0
txt_brk1:   !scr "This is not a workplace.", 0
txt_brk2:   !scr "This is a cycle.", 0
txt_brk3:   !scr "And if it is a cycle...", 0
txt_brk4:   !scr "it can be broken.", 0
txt_break:  !scr "> BREAK", 0
txt_break_n: !scr "  BREAK", 0
txt_cont:   !scr "> CONTINUE", 0
txt_cont_n: !scr "  CONTINUE", 0

; ---- variables ----
mm_state:  !byte 0
mm_text:   !word 0
mm_left:   !byte 0       ; lines still to type
mm_ci:     !byte 0       ; char index in the line
mm_col:    !byte 0
mm_row:    !byte 0
mm_wait:   !byte 0
mm_done:   !byte 0
mm_timer:  !byte 0
mm_cb:     !byte 0
mm_break:  !byte 0
mm_show:   !byte 0
mm_flashwake: !byte 0
mm_sel:    !byte 0
mm_pending: !byte 0
