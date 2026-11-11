; -----------------------------------------------------------
; defs.asm - hardware registers, memory map, constants,
; zero page and macros; included first by main.asm
; -----------------------------------------------------------

; ---- hardware registers ----
RASTER  = $d012          ; current raster line
BORDER  = $d020          ; border color register
BG      = $d021          ; background color register
SCRCTL  = $d011          ; control 1: raster msb, bitmap mode, blank
SCRCTL2 = $d016          ; control 2: multicolor, x-scroll
VMCSB   = $d018          ; memory setup: screen + bitmap base
SPR_EN  = $d015          ; sprite enable bits
SPRX0   = $d000          ; sprite 0 x (x/y pairs go up from here)
SPRY0   = $d001          ; sprite 0 y
SPRMSB  = $d010          ; 9th x position bit of each sprite
SPRDBLY = $d017          ; sprite y expand
SPRPRI  = $d01b          ; sprite/background priority
SPRMCEN = $d01c          ; sprite multicolor enable
SPRDBLX = $d01d          ; sprite x expand
SPRCOL  = $d027          ; sprite colors, 8 registers
CPUPORT = $01            ; 6510 port: ROM/RAM banking
CIA1_PA = $dc00          ; CIA1 port A: keyboard columns / joystick 2
CIA1_PB = $dc01          ; CIA1 port B: keyboard rows / joystick 1
CIA1_TA = $dc04          ; CIA1 timer A low byte: free-running entropy
CIA2_PA = $dd00          ; CIA2 port A: the VIC bank in bits 0-1

; ---- memory map ----
; the program runs from $0801 up to $c9ff with BASIC and
; KERNAL banked out ($01 = $35); the VIC looks at bank 3:
;   $0200-$03fd  shadow of the scene's colors, 30 x 17 (the
;                focus brings the colors back from it)
;   $0400-$07ff  the ROM font, copied to RAM (128 chars)
;   $ca00-$cb3f  sprite shapes (blocks 40-44)
;   $cc00-$cfe7  color matrix: ink (high nibble) + paper (low)
;   $cff8-$cfff  sprite pointers
;   $e000-$ff3f  the hires bitmap (under the KERNAL)
COLSHADOW = $0200
FONT    = $0400
SPRDATA = $ca00
SPRBLK  = (SPRDATA - $c000) / 64
SCRRAM  = $cc00
SPRPTR  = SCRRAM + $3f8
BITMAP  = $e000
PROG_END = $ca00
GLMAX   = 200            ; glitch stripe bytes kept for the restore

; ---- SID registers ----
; voice 1 belongs to the SFX driver, voices 2 and 3 to the
; music player, which reaches their registers as SID+n,y
SID      = $d400
SID_V1FL = $d400
SID_V1FH = $d401
SID_V1PL = $d402
SID_V1PH = $d403
SID_V1CR = $d404
SID_V1AD = $d405
SID_V1SR = $d406
SID_VOL  = $d418

; ---- colors ----
BLACK   = 0
WHITE   = 1
RED     = 2
CYAN    = 3
PURPLE  = 4
GREEN   = 5
BLUE    = 6
YELLOW  = 7
ORANGE  = 8
BROWN   = 9
LRED    = 10
DGREY   = 11
MGREY   = 12
LGREEN  = 13
LBLUE   = 14
LGREY   = 15

; ink + paper pairs for the color matrix
!macro col .ink, .paper { lda #(.ink << 4) | .paper }

; ---- the palette of the original (TIC-80 Config.colors) ----
C_WPM    = LBLUE         ; work productivity meter
C_ISM    = YELLOW        ; impostor syndrome meter
C_BM     = LRED          ; burnout meter
C_METERBG = DGREY
C_ACCENT = LBLUE         ; the original's light blue: menus, titles
C_ITEM   = YELLOW        ; the original's orange: labels, items

; ---- screen layout: the TIC-80 scene (240x136) sits 1:1
; in the top 30x17 cells, the HUD below it ----
SCN_X    = 5             ; first cell column of the scene
SCN_W    = 30
SCN_H    = 17
HUD_METERS = 18          ; meter row
HUD_ASC  = 20            ; ascension letters row
BAR_TOP  = 21            ; decision / answer bar: rows 21-23
BAR_ROW  = 22            ; its first text row

; ---- joystick / key bits (active high) ----
IN_UP    = 1
IN_DOWN  = 2
IN_LEFT  = 4
IN_RIGHT = 8
IN_FIRE  = 16
IN_BACK  = 32            ; del / arrow left / run-stop
IN_ENTER = 64            ; return (counts the test-mode presses)

; ---- SFX IDs ----
SFX_SELECT   = 0
SFX_DESELECT = 1
SFX_BEEP     = 2
SFX_SUCCESS  = 3
SFX_BLOOP    = 4
SFX_ALARM    = 5
SFX_DRUM     = 6
SFX_HIT      = 7         ; DDR arrow hit; the pitch comes from the arrow
NSFX         = 8

; ---- music IDs ----
MUS_WORK    = 0          ; the office song (room_work)
MUS_DDR     = 1          ; the work minigame (activity_work)
MUS_MYSTERY = 2          ; the mysterious man, the toilet, the glitch
MUS_NONE    = $ff

; ---- screens of the game window (Screen.register ids) ----
SC_HOME      = 0
SC_TOILET    = 1
SC_WALKOFF   = 2         ; walking to office
SC_OFFICE    = 3
SC_WALKHOME  = 4         ; walking to home
SC_WORK      = 5
SC_MMAN      = 6         ; the mysterious man

; ---- decisions (Decision.register ids) ----
DC_GO_HOME   = 0
DC_TOILET    = 1
DC_WALKOFF   = 2
DC_GO_OFFICE = 3
DC_TRUTH     = 4
DC_WALKHOME  = 5
DC_SLEEP     = 6
DC_WORK      = 7
DC_COFFEE    = 8
DC_SUMPHORE  = 9
DC_TALKTRUTH = 10
DC_FOOD      = 11
MAXDEC       = 6

; ---- background scenes (gen_gfx.asm scn_*) ----
BG_BEDROOM = 0
BG_STREET  = 1
BG_OFFICE  = 2
BG_MMAN    = 3
BG_DAY     = 4
BG_DDR     = 5
BG_NONE    = $ff

; ---- figure draw flags ----
FF_FLIP  = 1             ; upside down (the commute glitch)
FF_ECHO  = 2             ; norman's echo: white turns cyan

; ---- the meters of the original (logic.meter.lua) ----
METER_MAX   = 1000
WPM_INIT    = 200
ISM_INIT    = 500
BM_INIT     = 200
DECAY       = 20         ; per day
M_WPM       = 0          ; meter index
M_ISM       = 1
M_BM        = 2
COMBO_TIMEOUT = 500      ; 600 TIC frames at 60 Hz = 10 s
FLASH_TIME  = 100        ; meter change flash: 2 s
ASC_MAX     = 9

; ---- timing (PAL: 50 frames a second) ----
RAS_SYNC   = 251         ; raster line polled for the frame sync
WIN_TIME   = 150         ; minigame "success" overlay: 3 s
FLASHFRAMES = 100        ; ascension level-up flash: 2 s
ASCFADE    = 100         ; the new letter fades in: 2 s
CLOCK_STEP = 94          ; 16 clock frames over 30 s

; ---- zero page ($02-$7f is ours: no BASIC, no KERNAL) ----
src     = $02            ; generic source pointer
dst     = $04            ; bitmap pointer
cdst    = $06            ; color matrix pointer
txt     = $08            ; text pointer
ptr     = $0a            ; scratch pointer
updvec  = $0c            ; state update vector
musptr  = $0e            ; music pattern pointer
ptr2    = $10            ; scratch pointer 2
ptr3    = $12            ; scratch pointer 3
zt0     = $14            ; scratch bytes
zt1     = $15
zt2     = $16
zt3     = $17
zt4     = $18
zt5     = $19
zt6     = $1a
zt7     = $1b
mm_tptr = $1c            ; the typewriter of the mysterious man
cr_sptr = $1e            ; the credits scroller

; ---- set the state update vector ----
!macro setupd .addr {
    lda #<.addr
    sta updvec
    lda #>.addr
    sta updvec+1
}

; ---- leave the current screen: fade to black, then run the
; init routine of the next one ----
!macro fadeto .addr {
    lda #<.addr
    sta fadevec
    lda #>.addr
    sta fadevec+1
    jmp fade_start
}

; ---- print a 0-terminated text at a cell ----
!macro print .col, .row, .color, .text {
    lda #<.text
    sta txt
    lda #>.text
    sta txt+1
    ldx #.col
    ldy #.row
    lda #.color
    jsr print_at
}

; ---- print a 0-terminated text centered on a row ----
!macro center .row, .color, .text {
    lda #<.text
    sta txt
    lda #>.text
    sta txt+1
    ldy #.row
    lda #.color
    jsr print_center
}

; ---- 16-bit helpers ----
!macro mov16 .dst, .val {
    lda #<.val
    sta .dst
    lda #>.val
    sta .dst+1
}

; ---- Meter.add with a constant: +madd M_ISM, -100 ----
!macro madd .meter, .value {
    lda #<.value
    sta madd
    lda #>.value
    sta madd+1
    ldx #.meter
    jsr meter_add
}
