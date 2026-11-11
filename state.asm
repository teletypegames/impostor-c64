; -----------------------------------------------------------
; state.asm - the game context and its rules, as in the
; original's init.context, logic.meter, logic.day,
; logic.ascension and logic.commute_glitch:
;   three meters 0-1000 (work productivity, impostor
;   syndrome, burnout), the day counter, the nine steps of
;   ASCENSION and the seven levels of the commute glitch
; -----------------------------------------------------------

; ---- the whole context back to a fresh start ----
ctx_reset:
    ldx #ctx_end - ctx_start - 1
    lda #0
cr_lp:
    sta ctx_start,x
    dex
    bpl cr_lp
    lda #1
    sta day
    lda #<WPM_INIT
    sta mlo+M_WPM
    lda #>WPM_INIT
    sta mhi+M_WPM
    lda #<ISM_INIT
    sta mlo+M_ISM
    lda #>ISM_INIT
    sta mhi+M_ISM
    lda #<BM_INIT
    sta mlo+M_BM
    lda #>BM_INIT
    sta mhi+M_BM
    lda #SC_HOME
    sta cur_screen
    lda #$ff
    sta gameover
    jsr glitch_hide
    lda #0
    sta flick_on
    sta asc_fade
    rts

; ============================================================
; meters
; ============================================================

; ---- Meter.add: X = meter, madd (signed 16-bit) = amount ----
meter_add:
    stx ma_idx
    lda madd+1
    bmi ma_go            ; adding: a full ism / bm meter ends it
    ora madd
    beq ma_go
    cpx #M_WPM
    beq ma_go
    lda mhi,x
    cmp #>METER_MAX
    bcc ma_go
    bne ma_over
    lda mlo,x
    cmp #<METER_MAX
    bcc ma_go
ma_over:
    stx gameover         ; the meter index is the reason
    lda #0
    sta in_game
    rts
ma_go:
    lda mlo,x            ; the old value, for the flash
    sta ma_old
    lda mhi,x
    sta ma_old+1
    clc
    lda mlo,x
    adc madd
    sta zt0
    lda mhi,x
    adc madd+1
    sta zt1
    bpl ma_nonneg        ; below zero: clamp
    lda #0
    sta zt0
    sta zt1
ma_nonneg:
    lda zt1              ; above the max: clamp
    cmp #>METER_MAX
    bcc ma_store
    bne ma_cap
    lda zt0
    cmp #<METER_MAX
    bcc ma_store
ma_cap:
    lda #<METER_MAX
    sta zt0
    lda #>METER_MAX
    sta zt1
ma_store:
    lda zt0
    sta mlo,x
    lda zt1
    sta mhi,x
    cmp ma_old+1         ; changed: start the flash
    bne ma_mflash
    lda zt0
    cmp ma_old
    beq ma_rule
ma_mflash:
    lda ma_old
    sta moldlo,x
    lda ma_old+1
    sta moldhi,x
    lda #FLASH_TIME
    sta mflash,x
    lda #1
    sta hud_dirty
ma_rule:
    ; drained the work meter at ascension 5: that is the way on
    cpx #M_WPM
    bne ma_done
    lda ma_old
    ora ma_old+1
    beq ma_done
    lda mlo,x
    ora mhi,x
    bne ma_done
    lda in_game
    beq ma_done
    lda asc_level
    cmp #5
    bne ma_done
    lda #1
    sta should_ascend
ma_done:
    rts

; ---- the combo multiplier step for the toilet: 0-4 ----
combo_step:
    lda combo
    cmp #5
    bcc cs_ok
    lda #4
cs_ok:
    rts

; ---- Meter.on_minigame_complete(false): a flat +10% ----
meter_flat:
    +madd M_WPM, 100
    +madd M_ISM, 100
    +madd M_BM, 100
    rts

; ---- the wake-up mash: faster is better (elapsed frames in
; mash_time, PAL: 2 s = 100 frames) ----
meter_wakeup:
    lda mash_time+1
    bne mw_bad
    lda mash_time
    cmp #100
    bcc mw_perfect
    cmp #151
    bcc mw_good
mw_bad:
    +madd M_WPM, -50
    +madd M_ISM, 100
    +madd M_BM, 100
    rts
mw_good:
    +madd M_WPM, 100
    +madd M_ISM, 50
    +madd M_BM, 50
    rts
mw_perfect:
    +madd M_WPM, 200
    rts

; ---- after the work minigame: A = mistakes ----
meter_ddr:
    sta zt7
    lda mhi+M_WPM        ; wpm > 900 before the change?
    cmp #>901
    bcc md_low
    bne md_high
    lda mlo+M_WPM
    cmp #<901
    bcc md_low
md_high:
    lda #1
    bne md_set
md_low:
    lda #0
md_set:
    sta md_high_flag
    lda zt7
    bne md_some
    +madd M_WPM, -100
    +madd M_ISM, 50
    +madd M_BM, 50
    jmp md_extra
md_some:
    cmp #4
    bcs md_many
    +madd M_WPM, -50
md_many:
    +madd M_ISM, 100
    +madd M_BM, 100
md_extra:
    lda md_high_flag
    beq md_combo
    +madd M_ISM, 50
    +madd M_BM, 50
md_combo:
    inc combo
    lda #0
    sta combo_t
    sta combo_t+1
    rts

; ---- coffee with a coworker: one random meter shifts 10% ----
meter_coworker:
    lda cw_applied
    bne mc_done
    lda #3
    jsr rand_below
    cmp #1
    bcc mc_ism
    beq mc_wpm
    +madd M_BM, 100
    jmp mc_set
mc_ism:
    +madd M_ISM, 100
    jmp mc_set
mc_wpm:
    +madd M_WPM, -100
mc_set:
    lda #1
    sta cw_applied
mc_done:
    rts

; ---- a word with sumphore: the highest meter drops 10% ----
meter_sumphore:
    lda sp_applied
    bne msp_done
    ldx #M_ISM           ; ties go to ism, then wpm, then bm
    ldy #M_WPM
    jsr msp_cmp
    ldy #M_BM
    jsr msp_cmp
    lda #<-100
    sta madd
    lda #>-100
    sta madd+1
    jsr meter_add
    lda #1
    sta sp_applied
msp_done:
    rts
msp_cmp:                 ; X = the biggest so far; Y beats it?
    lda mhi,x
    cmp mhi,y
    bcc msp_take
    bne msp_keep
    lda mlo,x
    cmp mlo,y
    bcs msp_keep
msp_take:
    tya
    tax
msp_keep:
    rts

; ---- the toilet at home: burnout -15%, impostor -10%, work +5% ----
meter_toilet:
    +madd M_BM, -150
    +madd M_ISM, -100
    +madd M_WPM, 50
    rts

; ---- once a frame while a game runs (not in a minigame):
; the combo runs out, the meter flashes fade, the clock ticks ----
meters_tick:
    lda in_game
    beq mt_done
    lda in_minigame
    bne mt_flash
    lda combo
    beq mt_clock
    inc combo_t
    bne mt_ct
    inc combo_t+1
mt_ct:
    lda combo_t+1
    cmp #>COMBO_TIMEOUT
    bcc mt_clock
    lda combo_t
    cmp #<COMBO_TIMEOUT
    bcc mt_clock
    lda #0
    sta combo
    sta combo_t
    sta combo_t+1
mt_clock:
    inc clock_t
    lda clock_t
    cmp #CLOCK_STEP
    bcc mt_flash
    lda #0
    sta clock_t
    lda clock_ph
    clc
    adc #1
    and #15
    sta clock_ph
    lda #1
    sta clock_dirty
mt_flash:
    ldx #2
mt_fl:
    lda mflash,x
    beq mt_fn
    dec mflash,x
    bne mt_fn
    lda #1
    sta hud_dirty
mt_fn:
    dex
    bpl mt_fl
    lda asc_fade
    beq mt_done
    dec asc_fade
    lda asc_fade         ; the letter steps: black, grey, light, white
    beq mt_step
    cmp #66
    beq mt_step
    cmp #33
    bne mt_done
mt_step:
    lda #1
    sta hud_dirty
mt_done:
    rts

; ============================================================
; the day (logic.day.lua)
; ============================================================
day_increase:
    inc day
    lda day
    cmp #3
    bne di_100
    lda #1
    sta should_ascend
di_100:
    cmp #100
    bcc di_handlers
    lda asc_level
    cmp #ASC_MAX
    bcs di_handlers
    lda #3               ; 100 days and the cycle never broke
    sta gameover
    lda #0
    sta in_game
    rts
di_handlers:
    ldx #2               ; every meter decays 20
di_decay:
    lda mlo,x
    sec
    sbc #DECAY
    sta zt0
    lda mhi,x
    sbc #0
    bcs di_dset
    lda #0
    sta zt0
di_dset:
    sta mhi,x
    lda zt0
    sta mlo,x
    dex
    bpl di_decay
    lda #0               ; the daily flags start over
    sta toilet_morning
    sta toilet_evening
    sta cw_applied
    sta sp_applied
    sta glitch_today
    sta food_eaten
    lda should_ascend
    beq di_done
    jsr asc_increase
    lda #0
    sta should_ascend
di_done:
    rts

; ============================================================
; ascension (logic.ascension.lua)
; ============================================================
asc_increase:
    lda asc_level
    cmp #ASC_MAX
    bcs ai_max
    inc asc_level
ai_max:
    lda #1
    sta asc_inc
    rts

; ---- A = 1 if it increased since the last call (and clear) ----
asc_consume:
    lda asc_inc
    ldx #0
    stx asc_inc
    rts

; ============================================================
; the commute glitch (logic.commute_glitch.lua) - active at
; ascension 7, its level climbs with every trip to the office
; ============================================================

; ---- A = level (7 from ascension 8 on) ----
cg_level_get:
    lda asc_level
    cmp #8
    bcc cgl_ctx
    lda #7
    rts
cgl_ctx:
    lda cg_level
    rts

; ---- carry set = active ----
cg_active:
    lda asc_level
    cmp #7
    beq cga_yes
    clc
    rts
cga_yes:
    sec
    rts

; ---- carry set = at its max (level 7) ----
cg_max:
    jsr cg_active
    bcc cgm_no
    jsr cg_level_get
    cmp #7
    rts                  ; carry set when >= 7
cgm_no:
    rts

cg_increment:
    lda cg_level
    cmp #7
    bcs cgi_done
    cmp #6
    bcs cgi_done
    inc cg_level
cgi_done:
    rts

cg_reset:
    lda #0
    sta cg_level
    jmp glitch_hide

; ---- the office song drags with the glitch ----
cg_music_slow:
    lda #0
    sta mus_slow
    jsr cg_level_get
    cmp #2
    bcc cms_done
    sec
    sbc #1
    asl
    sta mus_slow
cms_done:
    rts

; ============================================================
; the figure lists of the office and the street
; (Sprite.list_randomize + CommuteGlitch.corrupt_sprite_list)
; ============================================================

; ---- A = 0: the office's nine coworkers, 1: the street's four ----
list_make:
    sta zt6
    beq lm_office
    lda #NSTREETPOS
    sta zt5
    lda #4
    sta ln
    ldx #3
lm_sfig:
    lda street_figs,x
    sta lfig,x
    dex
    bpl lm_sfig
    ldx #NSTREETPOS-1
lm_spos:
    lda street_posx,x
    sta shx,x
    lda street_posy,x
    sta shy,x
    dex
    bpl lm_spos
    jmp lm_shuffle
lm_office:
    lda #NOFFICEPOS
    sta zt5
    lda #9
    sta ln
    ldx #8
lm_ofig:
    lda office_figs,x
    sta lfig,x
    dex
    bpl lm_ofig
    ldx #NOFFICEPOS-1
lm_opos:
    lda office_posx,x
    sta shx,x
    lda office_posy,x
    sta shy,x
    dex
    bpl lm_opos
lm_shuffle:
    ; Fisher-Yates over the positions
    ldx zt5
    dex
lm_sh:
    stx zt4
    txa
    clc
    adc #1
    jsr rand_below
    tay
    ldx zt4
    lda shx,x
    pha
    lda shx,y
    sta shx,x
    pla
    sta shx,y
    lda shy,x
    pha
    lda shy,y
    sta shy,x
    pla
    sta shy,y
    dex
    bne lm_sh
    ; the figures take the first positions
    ldx ln
    dex
lm_assign:
    lda shx,x
    sta lx,x
    ldy lfig,x
    lda shy,x
    clc
    adc figycorr,y
    sta ly,x
    lda #0
    sta lflags,x
    dex
    bpl lm_assign
    rts

; ---- the glitch corrupts the list from level 3 on ----
list_corrupt:
    jsr cg_level_get
    cmp #3
    bcc lc_done
    sta zt6
    cmp #7
    bcc lc_partial
    ldx ln               ; level 7: all of them are norman's echo
    dex
lc_all:
    lda #FIG_NORMAN
    sta lfig,x
    lda #FF_ECHO
    sta lflags,x
    dex
    bpl lc_all
    rts
lc_partial:
    lda #1               ; upside down: 1 (2 from level 5)
    sta zt4
    lda #0               ; echoes: 0, 1 at level 4, 2 from level 5
    sta zt5
    lda zt6
    cmp #4
    bcc lc_go
    inc zt5
    cmp #5
    bcc lc_go
    inc zt4
    inc zt5
lc_go:
    ldx #0
lc_lp:
    cpx ln
    bcs lc_done
    cpx zt4
    bcs lc_echo
    lda #FF_FLIP
    sta lflags,x
    bne lc_next
lc_echo:
    txa
    sec
    sbc zt4
    cmp zt5
    bcs lc_next
    lda #FIG_NORMAN
    sta lfig,x
    lda #FF_ECHO
    sta lflags,x
lc_next:
    inx
    bne lc_lp
lc_done:
    rts

office_figs:
    !byte FIG_PM, FIG_HR, FIG_INTROVERT, FIG_EXTROVERT, FIG_GURU
    !byte FIG_OPERATOR, FIG_BUDDY, FIG_BOY, FIG_GIRL
street_figs:
    !byte FIG_TRINITY, FIG_NEO, FIG_ORACULUM, FIG_ARCHITECT

; ============================================================
; the code of the good ending (logic.codegenerator.lua):
; three letters -> six base-36 digits
; ============================================================
code_make:
    ldx #0
cm_lp:
    stx zt6
    lda player_name,x
    sec
    sbc #$41             ; 'A' = 0
    bcs cm_ok
    lda #0
cm_ok:
    clc                  ; + salt * 26
    adc code_salt26lo,x
    sta divlo
    lda code_salt26hi,x
    adc #0
    sta divhi
    lda #36
    jsr div16            ; divlo = high digit, A = low digit
    sta zt7
    lda zt6
    asl
    tax
    ldy divlo
    lda base36,y
    sta code_txt,x
    ldy zt7
    lda base36,y
    sta code_txt+1,x
    ldx zt6
    inx
    cpx #3
    bne cm_lp
    lda #0
    sta code_txt+6
    rts

; salts: 27471 % 36 = 3, 27471/36 % 36 = 7, 27471/1296 % 36 = 21
code_salt26lo: !byte <(3 * 26), <(7 * 26), <(21 * 26)
code_salt26hi: !byte >(3 * 26), >(7 * 26), >(21 * 26)
base36: !scr "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
code_txt: !fill 7, 0

; ============================================================
; the context (Context.initial_data); ctx_reset zeroes it all
; ============================================================
ctx_start:
in_game:        !byte 0  ; game_in_progress
mlo:            !fill 3, 0 ; the meters: wpm, ism, bm
mhi:            !fill 3, 0
moldlo:         !fill 3, 0 ; the value before the last change
moldhi:         !fill 3, 0
mflash:         !fill 3, 0 ; frames left of the change flash
meters_hidden:  !byte 0
combo:          !byte 0
combo_t:        !word 0
clock_t:        !byte 0
clock_ph:       !byte 0  ; the clock: 0-15
day:            !byte 0
asc_level:      !byte 0
asc_inc:        !byte 0
asc_fade:       !byte 0  ; frames left of the new letter's fade
cg_level:       !byte 0  ; commute_glitch_level
should_ascend:  !byte 0
home_norman:    !byte 0  ; home_norman_visible
been_office:    !byte 0
done_work:      !byte 0
toilet_morning: !byte 0
toilet_evening: !byte 0
cw_applied:     !byte 0  ; coworker_discussion_meter_applied_today
sp_applied:     !byte 0  ; sumphore_discussion_meter_applied_today
glitch_count:   !byte 0  ; glitch_conversation_count
glitch_today:   !byte 0  ; glitch_conversation_done_today
met_sumphore:   !byte 0
food_near:      !byte 0  ; fast_food_approaching
food_eaten:     !byte 0  ; fast_food_eaten_today
talked_echo:    !byte 0  ; talked_to_norman_echo
talked_sumph:   !byte 0  ; talked_to_true_sumphore
stat_active:    !byte 0  ; the toilet's stat screen
in_minigame:    !byte 0
cur_screen:     !byte 0
gameover:       !byte 0  ; $ff = no; else 0 wpm, 1 ism, 2 bm, 3 days
ln:             !byte 0  ; the figure list of the screen
lfig:           !fill 9, 0
lx:             !fill 9, 0
ly:             !fill 9, 0
lflags:         !fill 9, 0
ctx_end:

; ---- kept across games ----
test_mode:   !byte 0
player_name: !scr "AAA"
             !byte 0
shx:         !fill 12, 0 ; positions being shuffled
shy:         !fill 12, 0
madd:        !word 0
ma_idx:      !byte 0
ma_old:      !word 0
md_high_flag: !byte 0
mash_time:   !word 0
hud_dirty:   !byte 0
clock_dirty: !byte 0
