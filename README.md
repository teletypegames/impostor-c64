# Definitely not an Impostor C64

The Commodore 64 port of [Definitely not an Impostor](../impostor), the
TIC-80 game (ACME + VICE, in the footsteps of
[Blessing of Ra](../blessingofra)).

Norman Reds lives the same day over and over: the alarm clock, the walk
to the office, the work, the coffee with the coworkers, the walk home,
sleep. Three meters push and pull under it all - **WPM** (work
productivity), **ISM** (impostor syndrome) and **BM** (burnout), 0-1000
each, decaying 20 a day; when the impostor syndrome or the burnout is
full and still grows, or a hundred days pass, the game is over.

Bit by bit Norman notices the seams of the simulation he is in. The
mysterious man behind it talks about him between the days, and the
letters of **ASCENSION** light up one by one:

- at ascensions 1-3 the work itself quietly changes its rules (hit only
  the white arrows / only the left ones / none at all) - obeying them is
  how Norman moves on;
- at 4 he may stay in bed instead of waking up;
- at 5 the work meter has to run dry;
- at 6 the coworkers start to glitch, and the homeless guy, Sumphore,
  knows more than he should;
- at 7 the commute glitches apart, level by level: upside-down people,
  Norman's own echoes, a dragging song, until the road leads to the
  truth;
- at 8 the world flickers, and the bed offers to break the loop;
- at 9 the choice: BREAK the cycle - or CONTINUE.

The good ending gives a six-character code made of the player's three
letters; it continues on the Teletype BBS (`teletypegames.org`, port
2324).

## Controls

Joystick in either port, or the keyboard:

| action      | keys                              |
|-------------|-----------------------------------|
| move        | `w a s d` / cursor keys           |
| select / OK | `space`, `z`, fire                |
| back        | `del`, `x`, `<-`, `run/stop`      |

Left / right picks a decision (or an answer) on the bar under the scene,
fire takes it; back leaves the game for the menu (Resume Game returns).
Three presses of `return` while the TTG logo glitches turn on the test
mode of the original (a debug menu: the level-up flash, the DDR test,
start at any ascension, the end screen).

## The port

- **Screen:** the scenes are a multicolor bitmap - 4 colors in every
  4x8 cell (black + 3) - while the HUD, the decision bar and every text
  are hires: a raster interrupt switches the mode row by row (the scene
  rows 0-16, the question box of a discussion hires again, at the
  toilet only the circle's rows multicolor). The TIC-80's 240x136 scene
  sits in the top 30x17 cells, two of its pixels to one multicolor
  pixel: of two different ones black wins (the outlines and lines stay
  whole), else the color covering more of the cell (calm surfaces), and
  a dither stays a dither. The office's navy floor is a blue / dark grey
  dither. A few props are drawn by hand over the conversion
  (`tools/assets/scene_patches.txt`): the TTG whiteboard, the plant, the
  laptops, papers and mug of the office, the bookshelf and desk of the
  bedroom, the pizza stand's sign. The mysterious man, the day card and
  the work screen are hires pictures.
- **Figures:** every person is drawn by hand for the C64, after the
  original (`tools/assets/figures.txt`): multicolor pixels with a closed
  black outline, at most three colors a cell. They are laid over the
  scene pixel by pixel at run time; every cell then takes the three
  colors that matter most (the figure's pixels count four times) besides
  black. Norman's echo is a ghost of him: cyan, purple and grey.
- **Effects:** the focus circle (the alarm and the sleep minigames, the
  toilet) recolors the scene cells from a shadow copy; the glitch puts
  random vertical stripes into the bitmap and takes them back next
  frame; the commute glitch's flicker flashes random cells; screens
  fade to black between each other.
- **Minigames:** the alarm-clock button mash and the rhythm game run
  their bars in the HUD; the work (DDR) arrows are hardware sprites.
- **Texts:** the mysterious man's words and the brief are typed out
  line by line; the discussions are the original's, word for word.
- **Sound:** the original's three TIC-80 tracks (the office, the work,
  the mystery), converted note for note from the cart
  (`tools/ticmusic.py`), on a three-voice player; the instruments
  follow the original's SFX (its smooth wave as a triangle, the noise
  drum, the fading pulse). As on the TIC-80, a sound effect takes the
  first voice while it sounds, and the effects keep the original's
  pitches; the commute glitch drags the office song as the original's
  speed parameter does.
- **Timing:** PAL, 50 frames a second; the frame-counted timings and
  speeds of the original (60 Hz) are scaled to it.

## Build & run

```
make deps       # macOS: brew install acme vice
make build      # -> impostor-c64.prg
make run        # build + launch in x64sc
make data       # regenerate gen_gfx.asm, gen_text.asm, gen_music.asm (Python 3 + Pillow)
```

The generated sources are committed, so a build needs only ACME.

Test builds can boot straight into one state, or play a script of
joystick presses (`script.asm`):

```
acme -DAUTOGAME=7 -f cbm -o test.prg main.asm     # a game at ascension 7
acme -DAUTOGAME=8 -DSCRIPT=15 -DQUICKMINI=1 ...   # ascension 8 to the end
# also: AUTOMENU, AUTONEW, AUTOEND, AUTOCREDITS, AUTOOVER=1, AUTOFLASH,
# AUTODDR=n; QUICKMINI wins every minigame with one press
```

and a headless run with a screenshot:

```
x64sc -default -autostartprgmode 1 -limitcycles 30000000 \
      -exitscreenshot shot.png -autostart "$PWD/test.prg"
```

## Files

- `main.asm` - entry point, BASIC stub, the per-frame main loop
- `defs.asm` - registers, memory map, constants, zero page, macros
- `video.asm` - the bitmap: text (normal + 2x), block art, scenes,
  figures, focus circle, glitch, flicker, fade
- `common.asm` - input (joysticks + keyboard), RNG, math
- `state.asm` - the context: meters, day, ascension, commute glitch,
  the office / street figure lists, the ending's code
- `intro.asm` - title, TTG logo (test mode), the brief
- `menu.asm` - menu, controls, player name, credits, ascension start
- `game.asm` - the game window: screens, HUD, decisions, the toilet
- `discuss.asm` - the discussion window
- `mman.asm` - the mysterious man: his words, the day card, the
  morning choice, breaking the cycle
- `minigames.asm` - button mash, rhythm, DDR
- `ending.asm` - level-up flash, game over, good ending, to be
  continued
- `sound.asm` / `music.asm` - SFX driver and music player
- `gen_music.asm` - generated: the original's tracks
- `script.asm` - scripted input for test builds
- `gen_gfx.asm` / `gen_text.asm` - generated data
- `tools/` - the converter (`build_data.py`, `gfx.py`, `ticmusic.py`; `preview.py`
  renders a scene with its figures as the C64 shows it, beside the original), the
  drawn figures and props (`assets/figures.txt`, `assets/scene_patches.txt`), the texts
  (`content.py`) and the original's TIC-80 assets (`tools/assets`)

## Memory

BASIC and KERNAL are banked out; the raster interrupt (the mode splits
and the frame sync) comes through `$fffe`. The program runs from `$0801`
to below `$ca00`; the VIC looks at bank 3: sprites at `$ca00`, the color matrix at
`$cc00`, the bitmap under the KERNAL at `$e000`. The ROM font is copied
to `$0400`, the focus's shadow colors live at `$0200`.
