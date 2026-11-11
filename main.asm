; -----------------------------------------------------------
; main.asm - DEFINITELY NOT AN IMPOSTOR C64
;   a port of the TIC-80 game: norman reds lives the same
;   day over and over - wake up, walk to the office, work,
;   coffee, walk home, sleep - while three meters (work
;   productivity, impostor syndrome, burnout) push and pull;
;   bit by bit he notices the seams of the simulation he is
;   in, nine steps of ASCENSION up to the choice of breaking
;   the cycle
;
; Files:
;   defs.asm      - constants, memory map, zero page, macros
;   video.asm     - the hires bitmap: text, art, scenes,
;                   figures, focus, glitch, flicker, fade
;   common.asm    - input, random numbers, math
;   state.asm     - the context: meters, day, ascension,
;                   commute glitch, figure lists, the code
;   intro.asm     - title, TTG logo (test mode), the brief
;   menu.asm      - menu, controls, player name, credits,
;                   the test mode's ascension start
;   game.asm      - the game window: screens, HUD, decisions,
;                   the toilet's stat screen
;   discuss.asm   - the discussion window + framed boxes
;   mman.asm      - the mysterious man between the days
;   minigames.asm - button mash, rhythm, DDR
;   ending.asm    - level-up flash, game over, good ending,
;                   to be continued
;   sound.asm     - single-voice SFX driver
;   music.asm     - three-voice music player (the original's tracks)
;   gen_gfx.asm   - generated: scenes, figures, art, arrows
;   gen_text.asm  - generated: discussions, the long texts
;
; Build: acme -f cbm -o impostor-c64.prg main.asm
; -----------------------------------------------------------

* = $0801

; ---- BASIC stub: 10 SYS 2064 ----
!byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $34, $00, $00, $00

* = $0810                ; = 2064

!src "defs.asm"

start:
    sei                  ; no KERNAL IRQ: raster polling must not jitter
    cld
    ldx #$ff
    txs
    lda #BLACK
    sta BORDER
    sta BG
    jsr vid_init         ; ROMs out, the font, the bitmap screen
    jsr sfx_init
    jsr music_init
    jsr ctx_reset
    jsr input_flush

!ifdef AUTOGAME {        ; test builds boot straight into one state
    lda #AUTOGAME
    sta ad_level
    jsr ascdbg_start
} else {
!ifdef AUTOMENU {
    jsr menu_init
} else {
!ifdef AUTOEND {
    jsr end_init
} else {
!ifdef AUTODDR {
    lda #AUTODDR
    sta asc_level
    lda #1
    sta in_game
    lda #AUTODDR - 1
    jsr ddr_start
} else {
!ifdef AUTONEW {
    jsr new_game
} else {
!ifdef AUTOCREDITS {
    jsr credits_init
} else {
!ifdef AUTOOVER {
    lda #AUTOOVER
    sta go_reason
    jsr gameover_init
} else {
!ifdef AUTOFLASH {
    lda #<menu_init
    ldx #>menu_init
    jsr flash_start
} else {
    jsr title_init       ; title, TTG logo, the brief, then the menu
}
}
}
}
}
}
}
}

; ============================================================
; main loop - one state update per PAL frame, synced to the
; raster beam in the lower border; the frame effects (glitch
; stripes, flicker) are taken back before the update draws
; and laid on again after it
; ============================================================
main:
    jsr wait_frame
    inc framectr
    jsr rand8            ; stir the RNG once per frame
    jsr sfx_update
    jsr music_update
    jsr input_scan
    jsr meters_tick
    jsr fx_restore
    jsr call_update
    jsr check_gameover
    jsr fx_apply
    jmp main

call_update:
    jmp (updvec)         ; each update runs one frame, ends with rts

; ---- wait for the next frame (a slow update catches up) ----
wait_frame:
    lda frame_flag       ; the raster interrupt raises it at line 251
    beq wait_frame
    lda #0
    sta frame_flag
    rts

; ---- a meter broke norman, or the days ran out: game over ----
check_gameover:
    lda gameover
    bmi cg_none
    sta go_reason
    lda #$ff
    sta gameover
    lda #0
    sta in_game
    sta SPR_EN
    +fadeto gameover_init
cg_none:
    rts

; ============================================================
; the states and everything they share
; ============================================================
!src "intro.asm"
!src "menu.asm"
!src "game.asm"
!src "discuss.asm"
!src "mman.asm"
!src "minigames.asm"
!src "ending.asm"
!src "state.asm"
!src "common.asm"
!src "video.asm"
!src "sound.asm"
!src "music.asm"
!ifdef SCRIPT {
!src "script.asm"
}
!src "gen_text.asm"
!src "gen_gfx.asm"

!if * > PROG_END {
    !error "the program runs into the sprites at $ca00"
}
