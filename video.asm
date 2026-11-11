; -----------------------------------------------------------
; video.asm - the hires bitmap screen: VIC setup, clearing,
; text (normal and 2x big), block art, the packed scenes,
; the figures (composited into the cells under them), the
; focus circle, the glitch stripes, the background flicker
; and the fade to black between screens
;
; every 8x8 cell has two colors: the high nibble of its
; color matrix byte paints the 1 bits (ink), the low nibble
; the 0 bits (paper)
; -----------------------------------------------------------

vid_init:
    lda #$33             ; char ROM in: copy the lower/upper case font
    sta CPUPORT
    ldx #0
vi_font:
    lda $d800,x
    sta FONT,x
    lda $d900,x
    sta FONT+$100,x
    lda $da00,x
    sta FONT+$200,x
    lda $db00,x
    sta FONT+$300,x
    inx
    bne vi_font
    lda #$35             ; BASIC + KERNAL out, I/O in
    sta CPUPORT
    lda #<nmi_stub       ; restore key: ignore it
    sta $fffa
    lda #>nmi_stub
    sta $fffb
    lda #<nmi_stub
    sta $fffe
    lda #>nmi_stub
    sta $ffff
    lda CIA2_PA          ; VIC bank 3: $c000-$ffff
    and #$fc
    sta CIA2_PA
    lda #((SCRRAM - $c000) / $400) << 4 | $08
    sta VMCSB            ; color matrix at $cc00, bitmap at $e000
    lda #$08             ; hires, 40 columns
    sta SCRCTL2
    lda #0
    sta SPR_EN
    sta SPRMCEN
    sta SPRDBLX
    sta SPRDBLY
    sta SPRPRI
    sta SPRMSB
    ; the fade table: both nibbles one step darker
    ldx #0
vi_fade:
    txa
    and #15
    tay
    lda fadetbl,y
    sta zt0
    txa
    lsr
    lsr
    lsr
    lsr
    tay
    lda fadetbl,y
    asl
    asl
    asl
    asl
    ora zt0
    sta fadebyte,x
    inx
    bne vi_fade
    ; the sprite shapes: four DDR arrows + the rhythm line
    ldx #0
vi_spr:
    lda arrow_sprites,x
    sta SPRDATA,x
    inx
    bne vi_spr
    ldx #63
vi_line:
    lda line_sprite,x
    sta SPRDATA+256,x
    dex
    bpl vi_line
    ; the raster interrupt: the CIA timers go quiet, the VIC calls
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d
    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff
    lda #$3b             ; bitmap mode on, 25 rows, display on
    sta SCRCTL
    lda #1
    sta $d01a            ; raster interrupts only
    sta $d019
    lda #0
    jsr cls_all          ; (sets the hires layout and lets the IRQs in)
    rts

; ============================================================
; the raster interrupt: the scene rows are multicolor, the rest
; hires; a layout is a list of (raster line, $d016) pairs ended
; by the frame's own line (251), which raises frame_flag for the
; main loop; each switch happens in the right border of the
; last pixel line of the row before
; ============================================================
LAY_HIRES  = 0           ; everything hires
LAY_SCENE  = 1           ; scene rows 0-16 multicolor
LAY_DISC   = 2           ; ... but rows 3-10 hires: the question box
LAY_TOILET = 3           ; only rows 8-16 multicolor: the circle
MODE_MC    = $18
MODE_HI    = $08

irq:
    pha
    txa
    pha
    tya
    pha
    lda #1
    sta $d019            ; acknowledge
    ldx irq_i
    lda irq_mode,x
    bmi irq_frame
    ldy irq_line,x
    iny
irq_wl:
    cpy RASTER           ; wait for the next line ...
    bne irq_wl
    ldy #9               ; ... and on into its right border
irq_wd:
    dey
    bne irq_wd
    sta SCRCTL2
    inx
    bne irq_next
irq_frame:
    lda #MODE_HI         ; the frame ends hires
    sta SCRCTL2
    inc frame_flag
    ldx #0
irq_next:
    stx irq_i
    lda irq_line,x
    sta RASTER
    pla
    tay
    pla
    tax
    pla
nmi_stub:
    rti

; ---- A = LAY_*: the layout from the next frame on ----
set_layout:
    cmp layout
    beq sly_done
    sta layout
    tax
    lda laylo,x
    sta ptr
    lda layhi,x
    sta ptr+1
    sei
    ldy #0
    ldx #0
sly_copy:
    lda (ptr),y
    sta irq_line,x
    iny
    lda (ptr),y
    sta irq_mode,x
    iny
    inx
    cmp #$ff
    bne sly_copy
    ldx #0
    stx irq_i
    lda irq_line
    sta RASTER
    lda #MODE_HI
    sta SCRCTL2
    cli
sly_done:
    rts

laylo: !byte <lay_hires, <lay_scene, <lay_disc, <lay_toilet
layhi: !byte >lay_hires, >lay_scene, >lay_disc, >lay_toilet
lay_hires:  !byte 251, $ff
lay_scene:  !byte 49, MODE_MC, 185, MODE_HI, 251, $ff
lay_disc:   !byte 49, MODE_MC, 73, MODE_HI, 137, MODE_MC, 185, MODE_HI, 251, $ff
lay_toilet: !byte 113, MODE_MC, 185, MODE_HI, 251, $ff

; ---- blank / show the display while a screen is built ----
; (written whole: a read of $d011 below line 255 would bring the
; raster's ninth bit along and push the interrupt line past 255)
blank_on:
    lda #$2b             ; bitmap mode, 25 rows, display off
    sta SCRCTL
    rts

blank_off:
    lda #$3b             ; ... display on
    sta SCRCTL
    rts

; ---- clear the whole bitmap and the color RAM, fill the color
; matrix with A; the layout goes back to all hires ----
cls_all:
    pha
    lda #LAY_HIRES
    jsr set_layout
    lda #0
    tax
ca_cram:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $dae8,x
    inx
    bne ca_cram
    pla
ca_col:
    sta SCRRAM,x
    sta SCRRAM+$100,x
    sta SCRRAM+$200,x
    sta SCRRAM+$2e8,x
    inx
    bne ca_col
    lda #<BITMAP
    sta dst
    lda #>BITMAP
    sta dst+1
    ldx #31              ; 31 full pages + the 64-byte tail
    lda #0
    tay
ca_pg:
    sta (dst),y
    iny
    bne ca_pg
    inc dst+1
    dex
    bne ca_pg
ca_tail:
    sta (dst),y
    iny
    cpy #$40
    bne ca_tail
    rts

; ---- X = column, Y = row -> dst = bitmap cell, cdst = color ----
cell_ptrs:
    clc
    lda bmrowlo,y
    adc col8lo,x
    sta dst
    lda bmrowhi,y
    adc col8hi,x
    sta dst+1
    txa
    clc
    adc scrrowlo,y
    sta cdst
    lda scrrowhi,y
    adc #0
    sta cdst+1
    rts

; ---- fill a rectangle of cells: fr_col, fr_row, fr_w, fr_h,
; every bitmap byte = fr_byte, every color = fr_color ----
fill_rect:
    lda fr_row
    sta zt2
    lda fr_h
    sta zt3
fr_row_lp:
    ldx fr_col
    ldy zt2
    jsr cell_ptrs
    ldx fr_w
fr_cell:
    ldy #7
    lda fr_byte
fr_byte_lp:
    sta (dst),y
    dey
    bpl fr_byte_lp
    ldy #0
    lda fr_color
    sta (cdst),y
    jsr adv_cell
    dex
    bne fr_cell
    inc zt2
    dec zt3
    bne fr_row_lp
    rts

; ---- clear whole rows: A = color, X = first row, Y = count ----
clear_rows:
    sta fr_color
    stx fr_row
    sty fr_h
    lda #0
    sta fr_col
    sta fr_byte
    lda #40
    sta fr_w
    jmp fill_rect

; ---- recolor a rectangle (bitmap untouched): fr_* + A ----
color_rect:
    sta fr_color
    lda fr_row
    sta zt2
    lda fr_h
    sta zt3
cr_row:
    ldx fr_col
    ldy zt2
    jsr cell_ptrs
    ldy fr_w
    dey
    lda fr_color
cr_cell:
    sta (cdst),y
    dey
    bpl cr_cell
    inc zt2
    dec zt3
    bne cr_row
    rts

; ---- step dst / cdst one cell to the right ----
adv_cell:
    lda dst
    clc
    adc #8
    sta dst
    bcc ac_c
    inc dst+1
ac_c:
    inc cdst
    bne ac_done
    inc cdst+1
ac_done:
    rts

; ============================================================
; text
; ============================================================

; ---- length of the 0-terminated text at txt -> A ----
text_len:
    ldy #0
tl_lp:
    lda (txt),y
    beq tl_done
    iny
    bne tl_lp
tl_done:
    tya
    rts

; ---- print the text at txt: X = column, Y = row, A = color ----
print_at:
    sta pcolor
    jsr cell_ptrs
    lda #0
    sta pidx
pa_lp:
    ldy pidx
    lda (txt),y
    beq pa_done
    jsr put_char
    inc pidx
    bne pa_lp
pa_done:
    rts

; ---- print centered on row Y, color A ----
print_center:
    sta pcolor
    sty zt4
    jsr text_len
    sta zt5
    lda #40
    sec
    sbc zt5
    lsr
    tax
    ldy zt4
    lda pcolor
    jmp print_at

; ---- one character: A = screen code, at dst / cdst, then
; both pointers step one cell right ----
put_char:
    ldx #0
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
    ldy #7
pc_lp:
    lda (src),y
    sta (dst),y
    dey
    bpl pc_lp
    iny
    lda pcolor
    sta (cdst),y
    jmp adv_cell

; ---- print one char A at X = column, Y = row, color pcolor ----
char_at:
    pha
    jsr cell_ptrs
    pla
    jmp put_char

; ---- print a byte (0-255) in decimal at X/Y, color A ----
print_num:
    sta pcolor
    jsr cell_ptrs
    lda numval
    ldx #0
    stx zt6              ; a digit printed already
    ldx #100
    jsr pn_digit
    ldx #10
    jsr pn_digit
    lda #1
    sta zt6
    ldx #1
pn_digit:
    stx zt7
    ldx #0
pn_sub:
    lda numval
    cmp zt7
    bcc pn_got
    sbc zt7
    sta numval
    inx
    bne pn_sub
pn_got:
    txa
    bne pn_put
    lda zt6
    beq pn_skip
pn_put:
    lda #1
    sta zt6
    txa
    clc
    adc #$30
    jmp put_char
pn_skip:
    rts

; ---- the decimal digits of numval as text in numtxt (0-term.) ----
num_text:
    ldx #0
    lda numval
    ldy #0
nt_100:
    cmp #100
    bcc nt_10
    sbc #100
    iny
    bne nt_100
nt_10:
    sta zt7
    tya
    beq nt_n100
    ora #$30
    sta numtxt,x
    inx
nt_n100:
    lda zt7
    ldy #0
nt_10b:
    cmp #10
    bcc nt_1
    sbc #10
    iny
    bne nt_10b
nt_1:
    sta zt7
    cpx #0
    bne nt_w10
    tya
    beq nt_n10
nt_w10:
    tya
    ora #$30
    sta numtxt,x
    inx
nt_n10:
    lda zt7
    ora #$30
    sta numtxt,x
    inx
    lda #0
    sta numtxt,x
    rts

; ---- big 2x text: X = column, Y = row (each char 2x2 cells) ----
print_big:
    sta pcolor
    stx bcol
    sty brow
    lda #0
    sta pidx
pb_lp:
    ldy pidx
    lda (txt),y
    beq pb_done
    cmp #$20
    beq pb_next
    jsr big_char
pb_next:
    inc bcol
    inc bcol
    inc pidx
    bne pb_lp
pb_done:
    rts

print_big_center:
    sta pcolor
    sty brow
    jsr text_len
    asl
    sta zt5
    lda #40
    sec
    sbc zt5
    lsr
    tax
    ldy brow
    lda pcolor
    jmp print_big

big_char:
    ldx #0
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
    ldx bcol
    ldy brow
    jsr cell_ptrs
    lda dst              ; ptr = the cell below
    clc
    adc #<320
    sta ptr
    lda dst+1
    adc #>320
    sta ptr+1
    lda #0
    sta zt0              ; font row
bc_row:
    ldy zt0
    lda (src),y
    pha
    lsr
    lsr
    lsr
    lsr
    tax
    lda dbltbl,x
    sta zt1              ; left half
    pla
    and #15
    tax
    lda dbltbl,x
    sta zt2              ; right half
    lda zt0
    cmp #4
    bcs bc_low
    asl                  ; rows 0-3 -> top cells, 2 lines each
    tay
    lda zt1
    sta (dst),y
    iny
    sta (dst),y
    tya
    clc
    adc #7
    tay
    lda zt2
    sta (dst),y
    iny
    sta (dst),y
    jmp bc_next
bc_low:
    sec
    sbc #4
    asl
    tay
    lda zt1
    sta (ptr),y
    iny
    sta (ptr),y
    tya
    clc
    adc #7
    tay
    lda zt2
    sta (ptr),y
    iny
    sta (ptr),y
bc_next:
    inc zt0
    lda zt0
    cmp #8
    bne bc_row
    lda pcolor
    ldy #0
    sta (cdst),y
    iny
    sta (cdst),y
    ldy #40
    sta (cdst),y
    iny
    sta (cdst),y
    rts

; ============================================================
; block art (gen_gfx.asm art_*): one byte per cell, its four
; quadrants in bits 3-0 (top left, top right, bottom left,
; bottom right)
; ptr = art, X = column, Y = row, A = color
; ============================================================
draw_art:
    sta pcolor
    stx bcol
    sty brow
    ldy #0
    lda (ptr),y
    sta zt3              ; width
    iny
    lda (ptr),y
    sta zt4              ; height
    lda ptr
    clc
    adc #2
    sta ptr
    bcc da_row
    inc ptr+1
da_row:
    ldx bcol
    ldy brow
    jsr cell_ptrs
    lda #0
    sta zt5
da_cell:
    ldy zt5
    lda (ptr),y
    beq da_skip
    tax
    lda quadtop,x
    ldy #0
    sta (dst),y
    iny
    sta (dst),y
    iny
    sta (dst),y
    iny
    sta (dst),y
    lda quadbot,x
    iny
    sta (dst),y
    iny
    sta (dst),y
    iny
    sta (dst),y
    iny
    sta (dst),y
    ldy #0
    lda pcolor
    sta (cdst),y
da_skip:
    jsr adv_cell
    inc zt5
    lda zt5
    cmp zt3
    bne da_cell
    lda ptr
    clc
    adc zt3
    sta ptr
    bcc da_nc
    inc ptr+1
da_nc:
    inc brow
    dec zt4
    bne da_row
    rts

; ============================================================
; scenes: A = BG_* id -> the scene area (rows 0-16, columns
; 5-34); a scene is a dictionary of its distinct cells (a
; count byte, then 8 bytes each), then one packed stream of
; the 17 x 30 cell indexes and the 17 x 30 colors; packed:
; a byte b < $80 starts b+1 literal bytes, b >= $80 repeats
; the next byte b-$7d times
; ============================================================
scene_load:
    cmp #BG_NONE
    bne sl_go
    lda #0               ; no background: a black stage
    sta fr_color
    sta fr_byte
    sta fr_row
    lda #SCN_X
    sta fr_col
    lda #SCN_W
    sta fr_w
    lda #SCN_H
    sta fr_h
    jmp fill_rect
sl_go:
    sta sl_id
    tax
    lda scnlo,x
    sta src
    lda scnhi,x
    sta src+1
    ldy #0
    lda (src),y          ; cells in the dictionary (0 = 256)
    sta zt1
    inc src
    bne sl_d1
    inc src+1
sl_d1:
    lda src
    sta sl_dict
    lda src+1
    sta sl_dict+1
    lda #0               ; the stream starts after count * 8 bytes
    sta zt2
    lda zt1
    bne sl_d2
    lda #8               ; 256 cells: 2048 bytes
    sta zt2
    lda #0
    beq sl_d3
sl_d2:
    asl
    rol zt2
    asl
    rol zt2
    asl
    rol zt2
sl_d3:
    clc
    adc src
    sta src
    lda zt2
    adc src+1
    sta src+1
    lda #0
    sta rle_cnt
    sta zt0              ; row
sl_brow:
    ldy zt0
    ldx #SCN_X
    jsr cell_ptrs
    lda #SCN_W
    sta zt3
sl_bcell:
    jsr rle_get          ; the cell's index -> its 8 bytes
    sta ptr
    lda #0
    asl ptr
    rol
    asl ptr
    rol
    asl ptr
    rol
    sta ptr+1
    lda ptr
    clc
    adc sl_dict
    sta ptr
    lda ptr+1
    adc sl_dict+1
    sta ptr+1
    ldy #7
sl_copy:
    lda (ptr),y
    sta (dst),y
    dey
    bpl sl_copy
    lda dst
    clc
    adc #8
    sta dst
    bcc sl_bn
    inc dst+1
sl_bn:
    dec zt3
    bne sl_bcell
    inc zt0
    lda zt0
    cmp #SCN_H
    bne sl_brow
    lda #0
    sta zt0
sl_crow:
    ldy zt0
    ldx #SCN_X
    jsr cell_ptrs
    ldy #0
sl_cbyte:
    jsr rle_get
    sta (cdst),y
    iny
    cpy #SCN_W
    bne sl_cbyte
    inc zt0
    lda zt0
    cmp #SCN_H
    bne sl_crow
    lda sl_id            ; the multicolor scenes: the color RAM too
    cmp #BG_MMAN
    bcs sl_done
    lda #0
    sta zt0
sl_rrow:
    ldy zt0
    ldx #SCN_X
    jsr cell_ptrs
    jsr cram_ptr
    ldy #0
sl_rbyte:
    jsr rle_get
    sta (ptr3),y
    iny
    cpy #SCN_W
    bne sl_rbyte
    inc zt0
    lda zt0
    cmp #SCN_H
    bne sl_rrow
sl_done:
    rts

; ---- ptr3 = the color RAM cell under cdst ----
cram_ptr:
    lda cdst
    sta ptr3
    lda cdst+1
    clc
    adc #>($d800 - SCRRAM)
    sta ptr3+1
    rts

; ---- next unpacked byte -> A (keeps X and Y) ----
rle_get:
    sty rle_y
    lda rle_cnt
    bne rg_have
    ldy #0
    lda (src),y
    inc src
    bne rg_t1
    inc src+1
rg_t1:
    cmp #$80
    bcs rg_run
    adc #1               ; literal: b+1 bytes follow
    sta rle_cnt
    lda #0
    sta rle_mode
    beq rg_have
rg_run:
    sec
    sbc #$7d
    sta rle_cnt
    lda (src),y
    sta rle_val
    inc src
    bne rg_t2
    inc src+1
rg_t2:
    lda #1
    sta rle_mode
rg_have:
    dec rle_cnt
    lda rle_mode
    bne rg_val
    ldy #0
    lda (src),y
    inc src
    bne rg_done
    inc src+1
    ldy rle_y
    rts
rg_val:
    lda rle_val
rg_done:
    ldy rle_y
    rts

scnlo: !byte <scn_bedroom, <scn_street, <scn_office, <scn_mman, <scn_dayswitch, <scn_ddrbg
scnhi: !byte >scn_bedroom, >scn_street, >scn_office, >scn_mman, >scn_dayswitch, >scn_ddrbg

; ============================================================
; figures (gen_gfx.asm fig_*): A = figure, X = column inside
; the scene, Y = row, fig_flags = FF_FLIP / FF_ECHO
;
; a figure is w x h cells, row by row; a cell is
;   0                     empty: the scene shows through
;   1, 8 bits, colors     opaque
;   2, 8 mask, 8 bits, colors   partly see-through
; the partly see-through cells are merged with the scene
; cell under them: of the four colors in play (the figure's
; two, the scene's two) the two that cover the most pixels
; win, the others go to the closer one by brightness
; ============================================================
fig_draw:
    stx fd_col
    sty fd_row
    cmp #FIG_BIGNORMAN
    beq fd_big
    jmp mcfig_draw
fd_big:
    lda #<fig_bignorman
    sta src
    lda #>fig_bignorman
    sta src+1
    ldy #0
    lda (src),y
    sta fd_w
    iny
    lda (src),y
    sta fd_h
    lda src
    clc
    adc #2
    sta src
    bcc fd_s
    inc src+1
fd_s:
    lda #0
    sta fd_r
fd_rowlp:
    lda #0
    sta fd_c
fd_celllp:
    ldy #0
    lda (src),y          ; cell kind
    sta fd_kind
    jsr fig_inc1
    lda fd_kind
    bne fd_have
    jmp fd_next
fd_have:
    ; read the cell into fbuf (mask) / fbits, flipped if asked
    cmp #2
    bne fd_nomask
    ldx #fmask - fbuf
    jsr fig_read8
fd_nomask:
    ldx #fbits - fbuf
    jsr fig_read8
    ldy #0
    lda (src),y
    sta fd_colors
    jsr fig_inc1
    ; the target cell
    lda fig_flags
    and #FF_FLIP
    beq fd_noflip
    lda fd_h
    sec
    sbc fd_r
    sec
    sbc #1
    jmp fd_trow
fd_noflip:
    lda fd_r
fd_trow:
    clc
    adc fd_row
    cmp fig_hmax
    bcs fd_next          ; below the scene (or above: wrapped)
    tay
    lda fd_col
    clc
    adc fd_c
    cmp fig_wmax
    bcs fd_next
    adc fig_x0
    tax
    jsr cell_ptrs
    ; the figure's colors, remapped for the echo
    lda fd_colors
    lsr
    lsr
    lsr
    lsr
    tax
    lda fig_flags
    and #FF_ECHO
    beq fd_c1
    lda echotbl,x
    tax
fd_c1:
    stx fc1
    lda fd_colors
    and #15
    tax
    lda fig_flags
    and #FF_ECHO
    beq fd_c2
    lda echotbl,x
    tax
fd_c2:
    stx fc2
    lda fd_kind
    cmp #1
    bne fd_merge
    ldy #7               ; opaque: just copy
fd_op:
    lda fbits,y
    sta (dst),y
    dey
    bpl fd_op
    lda fc1
    asl
    asl
    asl
    asl
    ora fc2
    ldy #0
    sta (cdst),y
    jmp fd_next
fd_merge:
    jsr fig_merge
fd_next:
    inc fd_c
    lda fd_c
    cmp fd_w
    beq fd_rowend
    jmp fd_celllp
fd_rowend:
    inc fd_r
    lda fd_r
    cmp fd_h
    beq fd_done
    jmp fd_rowlp
fd_done:
    rts

; ============================================================
; multicolor figures (gen_gfx.asm fig_*): A = figure, fd_col /
; fd_row = its cell in the scene, fig_flags = FF_FLIP / FF_ECHO
;
; a cell is 0 (empty) or 1, 8 bytes of 4 two-bit pixels (%00 =
; see-through, %01-%11 = its three colors), (c1 << 4) | c2, c3;
; it is laid over the scene cell pixel by pixel, then the cell
; takes the three colors that matter most (the figure's pixels
; count four times) besides the black background, and every
; other color goes to the closest of them
; ============================================================
mcfig_draw:
    tax
    lda figlo,x
    sta src
    lda fighi,x
    sta src+1
    ldy #0
    lda (src),y
    sta fd_w
    iny
    lda (src),y
    sta fd_h
    lda src
    clc
    adc #2
    sta src
    bcc mf_s
    inc src+1
mf_s:
    lda #0
    sta fd_r
mf_rowlp:
    lda #0
    sta fd_c
mf_celllp:
    ldy #0
    lda (src),y
    sta fd_kind
    jsr fig_inc1
    lda fd_kind
    bne mf_have
    jmp mf_next
mf_have:
    ldx #fbits - fbuf    ; the pixels, flipped if asked
    jsr fig_read8
    ldy #0
    lda (src),y
    sta fd_colors
    iny
    lda (src),y
    and #15
    sta mf_c3
    lda src
    clc
    adc #2
    sta src
    bcc mf_t
    inc src+1
mf_t:
    lda fig_flags
    and #FF_FLIP
    beq mf_noflip
    lda fd_h
    sec
    sbc fd_r
    sec
    sbc #1
    jmp mf_trow
mf_noflip:
    lda fd_r
mf_trow:
    clc
    adc fd_row
    cmp #SCN_H
    bcs mf_next
    tay
    lda fd_col
    clc
    adc fd_c
    cmp #SCN_W
    bcs mf_next
    adc #SCN_X
    tax
    jsr cell_ptrs
    jsr cram_ptr
    ; the figure's colors (%01, %10, %11), remapped for the echo
    lda fd_colors
    lsr
    lsr
    lsr
    lsr
    sta mf_fcol+1
    lda fd_colors
    and #15
    sta mf_fcol+2
    lda mf_c3
    sta mf_fcol+3
    lda fig_flags
    and #FF_ECHO
    beq mf_merge
    ldx #3
mf_echo:
    ldy mf_fcol,x
    lda echotbl,y
    sta mf_fcol,x
    dex
    bne mf_echo
mf_merge:
    jsr mc_merge
mf_next:
    inc fd_c
    lda fd_c
    cmp fd_w
    beq mf_rowend
    jmp mf_celllp
mf_rowend:
    inc fd_r
    lda fd_r
    cmp fd_h
    beq mf_done
    jmp mf_rowlp
mf_done:
    rts

; ---- lay the figure cell (fbits, mf_fcol) over the multicolor
; cell at dst / cdst / ptr3 ----
mc_merge:
    ; the scene cell's colors: %00 black, %01, %10, %11
    lda #0
    sta mf_bcol
    ldy #0
    lda (cdst),y
    pha
    lsr
    lsr
    lsr
    lsr
    sta mf_bcol+1
    pla
    and #15
    sta mf_bcol+2
    lda (ptr3),y
    and #15
    sta mf_bcol+3
    ldx #15              ; no color counted yet
    lda #0
mq_clr:
    sta mf_cnt,x
    dex
    bpl mq_clr
    ; every pixel: the figure's if it is there, else the scene's
    ldx #0               ; pixel 0-31
    ldy #0               ; row
mq_row:
    lda (dst),y
    sta zt0
    lda fbits,y
    sta zt1
    sty zt2
    lda #4
    sta zt3
mq_px:
    lda #0
    asl zt1
    rol
    asl zt1
    rol
    beq mq_scene
    tay                  ; a figure pixel: weight 4
    lda mf_fcol,y
    sta mf_px,x
    tay
    lda mf_cnt,y
    clc
    adc #4
    sta mf_cnt,y
    asl zt0
    asl zt0
    jmp mq_pnext
mq_scene:
    asl zt0
    rol
    asl zt0
    rol
    tay
    lda mf_bcol,y
    sta mf_px,x
    tay
    lda mf_cnt,y
    clc
    adc #1
    sta mf_cnt,y
mq_pnext:
    inx
    dec zt3
    bne mq_px
    ldy zt2
    iny
    cpy #8
    bne mq_row
    ; the three heaviest colors besides black
    lda #0
    sta mf_cnt           ; black is free: never picked
    ldy #1
mq_pick:
    lda #0
    sta zt4              ; best count
    sta zt5              ; best color
    ldx #15
mq_best:
    lda mf_cnt,x
    beq mq_bn
    cmp zt4
    bcc mq_bn
    sta zt4
    stx zt5
mq_bn:
    dex
    bne mq_best
    lda zt5
    sta mf_out,y
    beq mq_pnone
    tax
    lda #0
    sta mf_cnt,x         ; picked: out of the race
mq_pnone:
    iny
    cpy #4
    bne mq_pick
    lda #0
    sta mf_out
    ; every color's code: its own slot, or the closest one
    ldx #15
mq_map:
    stx zt5
    lda #0               ; black
    cpx #0
    beq mq_mset
    ldy #3
mq_own:
    txa
    cmp mf_out,y
    beq mq_owny
    dey
    bne mq_own
    ; the closest of the four (black and the three picked)
    txa
    asl
    asl
    asl
    asl
    sta zt6              ; this color's row in coldist
    lda #$ff
    sta zt4
    lda #0
    sta zt7
    ldy #0
mq_near:
    lda mf_out,y
    bne mq_nc
    cpy #0
    bne mq_nnext         ; an empty slot
mq_nc:
    clc
    adc zt6
    tax
    lda coldist,x
    cmp zt4
    bcs mq_nnext
    sta zt4
    sty zt7
mq_nnext:
    iny
    cpy #4
    bne mq_near
    lda zt7
    jmp mq_mset
mq_owny:
    tya
mq_mset:
    ldx zt5
    sta mf_code,x
    dex
    bpl mq_map
    ; encode the cell
    ldx #0
    ldy #0
mq_enc:
    lda #0
    sta zt0
    lda #4
    sta zt3
mq_ep:
    asl zt0
    asl zt0
    stx zt1
    lda mf_px,x
    tax
    lda mf_code,x
    ora zt0
    sta zt0
    ldx zt1
    inx
    dec zt3
    bne mq_ep
    lda zt0
    sta (dst),y
    iny
    cpy #8
    bne mq_enc
    lda mf_out+1
    asl
    asl
    asl
    asl
    ora mf_out+2
    ldy #0
    sta (cdst),y
    lda mf_out+3
    sta (ptr3),y
    rts

; ---- a figure anywhere on the screen: X = absolute column ----
fig_draw_abs:
    pha
    lda #0
    sta fig_x0
    lda #40
    sta fig_wmax
    lda #25
    sta fig_hmax
    pla
    jsr fig_draw
    lda #SCN_X
    sta fig_x0
    lda #SCN_W
    sta fig_wmax
    lda #SCN_H
    sta fig_hmax
    rts

fig_inc1:
    inc src
    bne fi_d
    inc src+1
fi_d:
    rts

; ---- read 8 bytes from src into fbuf+X.., reversed when flipped ----
fig_read8:
    lda fig_flags
    and #FF_FLIP
    beq fr8_plain
    txa
    clc
    adc #7
    tax
    ldy #0
fr8_rev:
    lda (src),y
    sta fbuf,x
    dex
    iny
    cpy #8
    bne fr8_rev
    beq fr8_adv
fr8_plain:
    ldy #0
fr8_lp:
    lda (src),y
    sta fbuf,x
    inx
    iny
    cpy #8
    bne fr8_lp
fr8_adv:
    lda src
    clc
    adc #8
    sta src
    bcc fr8_d
    inc src+1
fr8_d:
    rts

; ---- merge the see-through cell in fmask / fbits (colors fc1
; for 1 bits, fc2 for 0 bits) into the scene cell at dst ----
fig_merge:
    ldy #0
    lda (cdst),y
    pha
    lsr
    lsr
    lsr
    lsr
    sta gcol+2           ; scene ink
    pla
    and #15
    sta gcol+3           ; scene paper
    lda fc1
    sta gcol
    lda fc2
    sta gcol+1
    lda #0
    sta gcnt
    sta gcnt+1
    sta gcnt+2
    sta gcnt+3
    ; the four pixel groups, byte by byte, and their sizes
    ldy #7
fm_grp:
    lda fmask,y
    and fbits,y
    sta g1,y
    tax
    lda popcnt,x
    clc
    adc gcnt
    sta gcnt
    lda fbits,y
    eor #$ff
    and fmask,y
    sta g2,y
    tax
    lda popcnt,x
    clc
    adc gcnt+1
    sta gcnt+1
    lda fmask,y
    eor #$ff
    sta zt0
    and (dst),y
    sta g3,y
    tax
    lda popcnt,x
    clc
    adc gcnt+2
    sta gcnt+2
    lda (dst),y
    eor #$ff
    and zt0
    sta g4,y
    tax
    lda popcnt,x
    clc
    adc gcnt+3
    sta gcnt+3
    dey
    bpl fm_grp
    ; fold groups of the same color into the first of them
    ldx #0
fm_fi:
    txa
    tay
    iny
fm_fj:
    cpy #4
    beq fm_fnext
    lda gcol,x
    cmp gcol,y
    bne fm_fskip
    lda gcnt,x
    clc
    adc gcnt,y
    sta gcnt,x
    lda #0
    sta gcnt,y
fm_fskip:
    iny
    bne fm_fj
fm_fnext:
    inx
    cpx #3
    bne fm_fi
    ; the winner: most pixels
    ldx #0
    ldy #1
fm_max1:
    lda gcnt,y
    cmp gcnt,x
    bcc fm_m1n
    beq fm_m1n
    tya
    tax
fm_m1n:
    iny
    cpy #4
    bne fm_max1
    stx zt1              ; winner index
    lda gcol,x
    sta fink
    ; the runner-up: most pixels among the other colors
    lda #$ff
    sta zt2
    ldy #0
fm_max2:
    cpy zt1
    beq fm_m2n
    lda gcnt,y
    beq fm_m2n
    lda gcol,y
    cmp fink
    beq fm_m2n
    ldx zt2
    bmi fm_m2take
    lda gcnt,y
    cmp gcnt,x
    bcc fm_m2n
    beq fm_m2n
fm_m2take:
    sty zt2
fm_m2n:
    iny
    cpy #4
    bne fm_max2
    ldx zt2
    bmi fm_one
    lda gcol,x
    sta fpaper
    jmp fm_map
fm_one:
    lda fink             ; one color only: ink = paper
    sta fpaper
fm_map:
    ; which groups paint with the ink? (gsel bit per group)
    ldx #3
fm_sel:
    lda gcol,x
    cmp fink
    beq fm_ink
    cmp fpaper
    beq fm_pap
    tay                  ; neither: the closer by brightness
    lda luma,y
    sta zt0
    ldy fink
    lda luma,y
    sec
    sbc zt0
    bcs fm_d1
    eor #$ff
    adc #1
fm_d1:
    sta zt3
    ldy fpaper
    lda luma,y
    sec
    sbc zt0
    bcs fm_d2
    eor #$ff
    adc #1
fm_d2:
    cmp zt3
    bcc fm_pap
fm_ink:
    lda #1
    bne fm_store
fm_pap:
    lda #0
fm_store:
    sta gsel,x
    dex
    bpl fm_sel
    ; build the cell
    ldy #7
fm_out:
    lda #0
    ldx gsel
    beq fm_o1
    ora g1,y
fm_o1:
    ldx gsel+1
    beq fm_o2
    ora g2,y
fm_o2:
    ldx gsel+2
    beq fm_o3
    ora g3,y
fm_o3:
    ldx gsel+3
    beq fm_o4
    ora g4,y
fm_o4:
    sta (dst),y
    dey
    bpl fm_out
    lda fink
    asl
    asl
    asl
    asl
    ora fpaper
    ldy #0
    sta (cdst),y
    rts

; ============================================================
; the focus circle (logic.focus.lua): everything in the scene
; outside the circle goes black; the colors come back from
; the shadow copy of the color matrix
; focus_x / focus_y = center, focus_r = radius, all in 4 px
; ============================================================

; ---- copy the scene's colors (30 x 17) into the shadow ----
shadow_save:
    ldx #0
ss_row:
    stx zt0
    lda scrrowlo,x
    clc
    adc #SCN_X
    sta cdst
    lda scrrowhi,x
    adc #0
    sta cdst+1
    lda shrowlo,x
    sta ptr
    lda shrowhi,x
    sta ptr+1
    jsr cram_ptr
    lda shrowlo,x
    clc
    adc #<(CRSHADOW - COLSHADOW)
    sta ptr2
    lda shrowhi,x
    adc #>(CRSHADOW - COLSHADOW)
    sta ptr2+1
    ldy #SCN_W-1
ss_cell:
    lda (cdst),y
    sta (ptr),y
    lda (ptr3),y
    and #15
    sta (ptr2),y
    dey
    bpl ss_cell
    ldx zt0
    inx
    cpx #SCN_H
    bne ss_row
    rts

; ---- the distance of every scene cell from the center, once
; per center (fdist, 4 px units, at most 63) ----
focus_center:
    lda #<fdist
    sta ptr2
    lda #>fdist
    sta ptr2+1
    lda #0
    sta zt0              ; row
fc_row:
    lda zt0
    asl
    ora #1               ; row center
    sec
    sbc focus_y
    bcs fc_dy
    eor #$ff
    adc #1
fc_dy:
    cmp #64
    bcc fc_dyok
    lda #63
fc_dyok:
    sta zt3              ; the distance is at least dy
    tax
    lda sqlo,x
    sta fdy
    lda sqhi,x
    sta fdy+1
    ldy #0
fc_cell:
    tya
    asl
    ora #1
    sec
    sbc focus_x
    bcs fc_dx
    eor #$ff
    adc #1
fc_dx:
    cmp #64
    bcc fc_dxok
    lda #63
fc_dxok:
    tax
    lda sqlo,x
    clc
    adc fdy
    sta zt1
    lda sqhi,x
    adc fdy+1
    sta zt2
fc_up:                   ; the next square still fits: one more
    ldx zt3
    cpx #63
    bcs fc_down
    lda sqhi+1,x
    cmp zt2
    bcc fc_inc
    bne fc_down
    lda sqlo+1,x
    cmp zt1
    beq fc_inc
    bcs fc_down
fc_inc:
    inc zt3
    jmp fc_up
fc_down:                 ; this square is too big: one less
    ldx zt3
    beq fc_put
    lda sqhi,x
    cmp zt2
    bcc fc_put
    bne fc_dec
    lda sqlo,x
    cmp zt1
    beq fc_put
    bcc fc_put
fc_dec:
    dec zt3
    jmp fc_down
fc_put:
    lda zt3
    sta (ptr2),y
    iny
    cpy #SCN_W
    bne fc_cell
    lda ptr2
    clc
    adc #SCN_W
    sta ptr2
    bcc fc_next
    inc ptr2+1
fc_next:
    inc zt0
    lda zt0
    cmp #SCN_H
    beq fc_end
    jmp fc_row
fc_end:
    rts

; ---- black outside radius focus_r, the shadow's colors inside ----
focus_apply:
    lda #<fdist
    sta ptr2
    lda #>fdist
    sta ptr2+1
    ldx #0
fa_row:
    lda scrrowlo,x
    clc
    adc #SCN_X
    sta cdst
    lda scrrowhi,x
    adc #0
    sta cdst+1
    jsr cram_ptr
    lda shrowlo,x
    sta ptr
    lda shrowhi,x
    sta ptr+1
    lda shrowlo,x
    clc
    adc #<(CRSHADOW - COLSHADOW)
    sta src
    lda shrowhi,x
    adc #>(CRSHADOW - COLSHADOW)
    sta src+1
    ldy #SCN_W-1
fa_cell:
    lda (ptr2),y
    cmp focus_r
    beq fa_in
    bcc fa_in
    lda #0
    sta (cdst),y
    sta (ptr3),y
    dey
    bpl fa_cell
    bmi fa_rowend
fa_in:
    lda (ptr),y
    sta (cdst),y
    lda (src),y
    sta (ptr3),y
    dey
    bpl fa_cell
fa_rowend:
    lda ptr2
    clc
    adc #SCN_W
    sta ptr2
    bcc fa_n
    inc ptr2+1
fa_n:
    inx
    cpx #SCN_H
    bne fa_row
    rts

; ============================================================
; glitch (logic.glitch.lua): while on, it alternates between
; bursts of random vertical stripes (each repeats the pixel it
; starts on downwards) and quiet spells; the bytes it touches
; are saved and put back first thing next frame
; ============================================================
glitch_restore:
    ldx gl_n
    beq gx_done
gx_lp:
    dex
    lda gl_lo,x
    sta ptr
    lda gl_hi,x
    sta ptr+1
    lda gl_val,x
    ldy #0
    sta (ptr),y
    cpx #0
    bne gx_lp
    stx gl_n
gx_done:
    rts

glitch_apply:
    lda glitch_on
    bne ga_on
    rts
ga_on:
    dec gl_timer
    bne ga_state
    lda gl_active        ; flip between bursts and quiet spells
    eor #1
    sta gl_active
    beq ga_wait
    jsr rand8            ; a burst: 40-100 TIC frames
    and #63
    clc
    adc #33
    sta gl_timer
    jmp ga_state
ga_wait:
    jsr rand8            ; a quiet spell: 20-60
    and #31
    clc
    adc #17
    sta gl_timer
ga_state:
    lda gl_active
    bne ga_burst
    rts
ga_burst:
    lda #8               ; stripes this frame
    sta zt6
ga_stripe:
    ; x: 0-319
    jsr rand8
    sta zt0
    jsr rand8
    and #1
    beq ga_xlo
    lda zt0
    and #63
    sta zt0
    lda #1
ga_xlo:
    sta zt1              ; x high bit
    ; y: 0-199
ga_y:
    jsr rand8
    cmp #200
    bcs ga_y
    sta zt2
    ; length 2-24
    jsr rand8
    and #15
    clc
    adc #2
    sta zt3
    jsr rand8
    and #7
    clc
    adc zt3
    sta zt3
    ; the bit within the byte
    lda zt0
    and #7
    tax
    lda bitmask,x
    sta zt4
    ; byte address of (x, y): row*320 + col*8 + (y and 7)
    lda zt0
    lsr
    lsr
    lsr
    ldx zt1
    beq ga_cx
    ora #$20             ; x >= 256: columns 32-39
ga_cx:
    tax
    lda zt2
    lsr
    lsr
    lsr
    tay
    jsr cell_ptrs
    lda zt2
    and #7
    sta zt5              ; line in the cell
    clc
    adc dst
    sta ptr
    lda dst+1
    adc #0
    sta ptr+1
    ldy #0
    lda (ptr),y
    and zt4
    sta zt7              ; the pixel to repeat: 0 or the bit
ga_line:
    ldx gl_n
    cpx #GLMAX
    bcs ga_full
    lda ptr
    sta gl_lo,x
    lda ptr+1
    sta gl_hi,x
    ldy #0
    lda (ptr),y
    sta gl_val,x
    inc gl_n
    and zt4
    eor zt7              ; differs from the repeated pixel?
    beq ga_same
    lda (ptr),y
    eor zt4
    sta (ptr),y
ga_same:
    inc zt2
    lda zt2
    cmp #200
    bcs ga_sdone
    inc zt5
    lda zt5
    cmp #8
    bne ga_inc1
    lda #0               ; next cell row: +320-7
    sta zt5
    lda ptr
    clc
    adc #<313
    sta ptr
    lda ptr+1
    adc #>313
    sta ptr+1
    jmp ga_cont
ga_inc1:
    inc ptr
    bne ga_cont
    inc ptr+1
ga_cont:
    dec zt3
    bne ga_line
ga_sdone:
    dec zt6
    beq ga_full
    jmp ga_stripe
ga_full:
    rts

glitch_show:
    lda #1
    sta glitch_on
    lda #1
    sta gl_timer
    lda #0
    sta gl_active
    rts

glitch_hide:
    lda #0
    sta glitch_on
    rts

; ============================================================
; background flicker (commute_glitch draw_background_flicker):
; every third frame six random scene cells flash a random
; color for one frame
; ============================================================
flick_restore:
    ldx fk_n
    beq fk_rdone
fk_rlp:
    dex
    lda fk_lo,x
    sta ptr
    lda fk_hi,x
    sta ptr+1
    lda fk_val,x
    ldy #0
    sta (ptr),y
    lda ptr+1
    clc
    adc #>($d800 - SCRRAM)
    sta ptr+1
    lda fk_cr,x
    sta (ptr),y
    cpx #0
    bne fk_rlp
    stx fk_n
fk_rdone:
    rts

flick_apply:
    lda flick_on
    beq fk_adone
    inc fk_tick
    lda fk_tick
    cmp #3
    bcc fk_adone
    lda #0
    sta fk_tick
    lda #6
    sta zt6
fk_cell:
    jsr rand8
    and #31
    cmp #SCN_W
    bcs fk_cell
    adc #SCN_X
    tax
fk_r:
    jsr rand8
    and #31
    cmp #SCN_H
    bcs fk_r
    tay
    jsr cell_ptrs
    ldx fk_n
    lda cdst
    sta fk_lo,x
    lda cdst+1
    sta fk_hi,x
    ldy #0
    lda (cdst),y
    sta fk_val,x
    jsr cram_ptr
    lda (ptr3),y
    sta fk_cr,x
    inc fk_n
    jsr rand8
    and #15
    sta zt0
    sta (ptr3),y
    asl
    asl
    asl
    asl
    ora zt0
    sta (cdst),y
    dec zt6
    bne fk_cell
fk_adone:
    rts

; ============================================================
; fade to black: six passes darken every color matrix byte
; (half the screen per frame), then the routine left in
; fadevec builds the next screen
; ============================================================
fade_start:
    jsr fx_restore
    lda #1
    sta fading
    lda #0
    sta fadecnt
    sta fadehalf
    +setupd fade_update
    rts

fade_update:
    lda fadehalf
    eor #1
    sta fadehalf
    bne fu_hi
    ldx #0
fu_lo:
    ldy SCRRAM,x
    lda fadebyte,y
    sta SCRRAM,x
    ldy SCRRAM+$100,x
    lda fadebyte,y
    sta SCRRAM+$100,x
    lda $d800,x
    and #15
    tay
    lda fadetbl,y
    sta $d800,x
    lda $d900,x
    and #15
    tay
    lda fadetbl,y
    sta $d900,x
    inx
    bne fu_lo
    rts
fu_hi:
    ldx #0
fu_hi2:
    ldy SCRRAM+$200,x
    lda fadebyte,y
    sta SCRRAM+$200,x
    ldy SCRRAM+$2e8,x
    lda fadebyte,y
    sta SCRRAM+$2e8,x
    lda $da00,x
    and #15
    tay
    lda fadetbl,y
    sta $da00,x
    lda $dae8,x
    and #15
    tay
    lda fadetbl,y
    sta $dae8,x
    inx
    bne fu_hi2
    ldx #7               ; the sprites sink with the screen
fu_spr:
    lda SPRCOL,x
    and #15
    tay
    lda fadetbl,y
    sta SPRCOL,x
    dex
    bpl fu_spr
    inc fadecnt
    lda fadecnt
    cmp #6
    bne fu_stay
    lda #0
    sta SPR_EN
    sta fading
    jmp (fadevec)
fu_stay:
    rts

; ---- the frame effects: put back what they touched ----
fx_restore:
    jsr flick_restore
    jmp glitch_restore

fx_apply:
    lda fading
    bne fxa_done
    jsr flick_apply
    jmp glitch_apply
fxa_done:
    rts

; ============================================================
; tables
; ============================================================
bmrowlo: !for r, 0, 24 { !byte <(BITMAP + r * 320) }
bmrowhi: !for r, 0, 24 { !byte >(BITMAP + r * 320) }
scrrowlo: !for r, 0, 24 { !byte <(SCRRAM + r * 40) }
scrrowhi: !for r, 0, 24 { !byte >(SCRRAM + r * 40) }
shrowlo: !for r, 0, SCN_H-1 { !byte <(COLSHADOW + r * SCN_W) }
shrowhi: !for r, 0, SCN_H-1 { !byte >(COLSHADOW + r * SCN_W) }
col8lo: !for c, 0, 39 { !byte <(c * 8) }
col8hi: !for c, 0, 39 { !byte >(c * 8) }
popcnt: !for i, 0, 255 { !byte (i & 1) + ((i >> 1) & 1) + ((i >> 2) & 1) + ((i >> 3) & 1) + ((i >> 4) & 1) + ((i >> 5) & 1) + ((i >> 6) & 1) + ((i >> 7) & 1) }
sqlo: !for i, 0, 63 { !byte <(i * i) }
sqhi: !for i, 0, 63 { !byte >(i * i) }
dbltbl: !for n, 0, 15 { !byte ((n >> 3) & 1) * $c0 + ((n >> 2) & 1) * $30 + ((n >> 1) & 1) * $0c + (n & 1) * $03 }
quadtop: !for n, 0, 15 { !byte ((n >> 3) & 1) * $f0 + ((n >> 2) & 1) * $0f }
quadbot: !for n, 0, 15 { !byte ((n >> 1) & 1) * $f0 + (n & 1) * $0f }
bitmask: !byte $80, $40, $20, $10, $08, $04, $02, $01

; brightness of each C64 color, for the color merge
luma:    !byte 0, 32, 10, 24, 12, 18, 8, 28, 12, 7, 18, 11, 16, 28, 18, 23
; norman's echo, a ghost of him: white turns cyan, blue purple, skin and
; hair grey
echotbl: !byte 0, 3, 2, 3, 4, 5, 4, 7, 12, 9, 15, 11, 12, 13, 14, 15
; each color one step darker
fadetbl: !byte $00, $0f, $09, $0c, $0b, $0b, $00, $08
         !byte $02, $00, $02, $00, $0b, $05, $06, $0c

; the rhythm game's beat line: 2 px wide, 21 tall
line_sprite:
    !for i, 0, 9 { !byte $c0, 0, 0 }
    !fill 34, 0

; ---- video variables ----
pcolor:  !byte 0
pidx:    !byte 0
bcol:    !byte 0
brow:    !byte 0
numval:  !byte 0
numtxt:  !fill 4, 0
fr_col:  !byte 0
fr_row:  !byte 0
fr_w:    !byte 0
fr_h:    !byte 0
fr_byte: !byte 0
fr_color: !byte 0
rle_cnt: !byte 0
rle_mode: !byte 0
rle_val: !byte 0
rle_y:   !byte 0
sl_id:   !byte 0
sl_dict: !word 0
fd_col:  !byte 0
fd_row:  !byte 0
fd_w:    !byte 0
fd_h:    !byte 0
fd_r:    !byte 0
fd_c:    !byte 0
fd_kind: !byte 0
fd_colors: !byte 0
fig_flags: !byte 0
mf_c3:   !byte 0
mf_fcol: !fill 4, 0
mf_bcol: !fill 4, 0
mf_out:  !fill 4, 0
mf_cnt:  !fill 16, 0
mf_code: !fill 16, 0
mf_px:   !fill 32, 0
fig_x0:  !byte SCN_X
fig_wmax: !byte SCN_W
fig_hmax: !byte SCN_H
fc1:     !byte 0
fc2:     !byte 0
fink:    !byte 0
fpaper:  !byte 0
fbuf:
fmask:   !fill 8, 0
fbits:   !fill 8, 0
g1:      !fill 8, 0
g2:      !fill 8, 0
g3:      !fill 8, 0
g4:      !fill 8, 0
gcol:    !fill 4, 0
gcnt:    !fill 4, 0
gsel:    !fill 4, 0
focus_x: !byte 0
focus_y: !byte 0
focus_r: !byte 0
fdy:     !word 0
fdist:   !fill SCN_W * SCN_H, 0
glitch_on: !byte 0
gl_timer: !byte 1
gl_active: !byte 0
gl_n:    !byte 0
flick_on: !byte 0
fk_tick: !byte 0
fk_n:    !byte 0
fk_lo:   !fill 8, 0
fk_cr:   !fill 8, 0
fk_hi:   !fill 8, 0
fk_val:  !fill 8, 0
fading:  !byte 0
layout:  !byte $ff
irq_i:   !byte 0
frame_flag: !byte 0
irq_line: !fill 8, 0
irq_mode: !fill 8, 0
CRSHADOW = crshadow
crshadow: !fill SCN_W * SCN_H, 0
fadecnt: !byte 0
fadehalf: !byte 0
fadebyte: !fill 256, 0
gl_lo:   !fill GLMAX, 0
gl_hi:   !fill GLMAX, 0
gl_val:  !fill GLMAX, 0
