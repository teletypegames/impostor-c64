"""TIC-80 asset reader and C64 hires converter for Impostor C64.

Reads the TIC-80 cart sections (tiles, sprites, map, palette) and the
RLE full-screen images of the original game, and turns them into C64
hires cells: 8x8 pixels, two colors each (ink = 1 bits, paper = 0 bits).
"""
import itertools
import re

C64_RGB = [
    (0x00, 0x00, 0x00), (0xff, 0xff, 0xff), (0x81, 0x33, 0x38), (0x75, 0xce, 0xc8),
    (0x8e, 0x3c, 0x97), (0x56, 0xac, 0x4d), (0x2e, 0x2c, 0x9b), (0xed, 0xf1, 0x71),
    (0x8e, 0x50, 0x29), (0x55, 0x38, 0x00), (0xc4, 0x6c, 0x71), (0x4a, 0x4a, 0x4a),
    (0x7b, 0x7b, 0x7b), (0xa9, 0xff, 0x9f), (0x70, 0x6d, 0xeb), (0xb2, 0xb2, 0xb2),
]

# pico-8 palette index of the original -> C64 color
PAL2C64 = [0, 11, 15, 6, 1, 8, 2, 7, 5, 14, 12, 13, 10, 10, 15, 10]
TRANSPARENT = 12
NONE = -1


def cdist(a, b):
    ra, ga, ba = C64_RGB[a]
    rb, gb, bb = C64_RGB[b]
    return 2 * (ra - rb) ** 2 + 4 * (ga - gb) ** 2 + 3 * (ba - bb) ** 2


def load_tic(path):
    txt = open(path).read()

    def sec(name):
        m = re.search(r'-- <%s>\n(.*?)-- </%s>' % (name, name), txt, re.S)
        out = {}
        for line in m.group(1).splitlines():
            mm = re.match(r'-- (\d+):(\w+)', line)
            if mm:
                out[int(mm.group(1))] = mm.group(2)
        return out

    def gfx(d):
        return {k: [[int(v[y * 8 + x], 16) for x in range(8)] for y in range(8)]
                for k, v in d.items()}

    tiles = gfx(sec('TILES'))
    sprites = gfx(sec('SPRITES'))
    mp = {}
    for k, v in sec('MAP').items():
        mp[k] = [int(v[i * 2 + 1] + v[i * 2], 16) for i in range(len(v) // 2)]
    return tiles, sprites, mp


class Canvas:
    """A pico-8 indexed image; NONE marks transparent pixels."""

    def __init__(self, w, h, fill=NONE):
        self.w, self.h = w, h
        self.px = [[fill] * w for _ in range(h)]

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def blit(self, glyph, x, y, flip_y=False, key=TRANSPARENT, scale=1):
        for gy in range(8):
            sy = 7 - gy if flip_y else gy
            for gx in range(8):
                c = glyph[sy][gx]
                if c == key:
                    continue
                for dy in range(scale):
                    for dx in range(scale):
                        self.put(x + gx * scale + dx, y + gy * scale + dy, c)


def render_map(tiles, mp, from_x):
    cv = Canvas(240, 136, 0)
    for ty in range(17):
        row = mp.get(ty, [])
        for tx in range(30):
            t = row[from_x + tx] if from_x + tx < len(row) else 0
            g = tiles.get(t)
            if g:
                cv.blit(g, tx * 8, ty * 8, key=None)
    return cv


def render_rle(values, runs):
    cv = Canvas(240, 136, 0)
    vi, run = -1, 0
    for y in range(136):
        for x in range(240):
            if run == 0:
                vi += 1
                run = runs[vi]
            run -= 1
            cv.px[y][x] = values[vi]
    return cv


def lua_rle_arrays(path):
    txt = open(path).read()
    vals = re.findall(r'local img_values = \{([^}]*)\}', txt)
    runs = re.findall(r'local img_runs = \{([^}]*)\}', txt)
    out = []
    for v, r in zip(vals, runs):
        out.append(([int(x) for x in v.split(',')], [int(x) for x in r.split(',')]))
    return out


def cell_pixels(cv, cx, cy):
    """C64 colors of an 8x8 cell, NONE kept for transparency."""
    out = []
    for y in range(8):
        row = []
        for x in range(8):
            c = cv.px[cy * 8 + y][cx * 8 + x] if (cy * 8 + y < cv.h and cx * 8 + x < cv.w) else NONE
            row.append(NONE if c == NONE else PAL2C64[c])
        out.append(row)
    return out


def best_pair(colors):
    """Pick two C64 colors that represent the given pixel colors best."""
    counts = {}
    for c in colors:
        counts[c] = counts.get(c, 0) + 1
    present = sorted(counts, key=lambda c: -counts[c])
    if len(present) <= 2:
        return (present + present)[:2] if present else (0, 0)
    best = None
    for a, b in itertools.combinations(present, 2):
        err = sum(n * min(cdist(c, a), cdist(c, b)) for c, n in counts.items())
        if best is None or err < best[0]:
            best = (err, a, b)
    return best[1], best[2]


def nearest(c, a, b):
    return a if cdist(c, a) <= cdist(c, b) else b


def opaque_cell(px):
    """Fully opaque cell -> (8 bytes, ink, paper); paper = the more frequent color."""
    flat = [c for row in px for c in row]
    a, b = best_pair(flat)
    q = [nearest(c, a, b) for c in flat]
    if q.count(a) > q.count(b):
        a, b = b, a
    ink, paper = a, b
    data = []
    for y in range(8):
        v = 0
        for x in range(8):
            v = (v << 1) | (1 if q[y * 8 + x] == ink and ink != paper else 0)
        data.append(v)
    return data, ink, paper


def sprite_cell(px):
    """Cell of a figure: None if empty, else (kind, mask, bits, c1, c2)."""
    flat = [c for row in px for c in row]
    solid = [c for c in flat if c != NONE]
    if not solid:
        return None
    if len(solid) == 64:
        data, ink, paper = opaque_cell(px)
        return ('opaque', None, data, ink, paper)
    a, b = best_pair(solid)
    mask, bits = [], []
    for y in range(8):
        m = v = 0
        for x in range(8):
            c = px[y][x]
            m <<= 1
            v <<= 1
            if c != NONE:
                m |= 1
                if nearest(c, a, b) == a and a != b:
                    v |= 1
        mask.append(m)
        bits.append(v)
    return ('partial', mask, bits, a, b)


def cells_of(cv):
    return [[cell_pixels(cv, cx, cy) for cx in range(cv.w // 8)] for cy in range(cv.h // 8)]


def preview_scene(cv, path, figures=()):
    """Render the C64 hires conversion of a scene (with figures) to PNG."""
    from PIL import Image
    im = Image.new('RGB', (cv.w, cv.h))
    full = Canvas(cv.w, cv.h, 0)
    full.px = [row[:] for row in cv.px]
    for fig, fx, fy in figures:
        for y in range(fig.h):
            for x in range(fig.w):
                if fig.px[y][x] != NONE:
                    full.put(fx + x, fy + y, fig.px[y][x])
    for cy in range(cv.h // 8):
        for cx in range(cv.w // 8):
            data, ink, paper = opaque_cell(cell_pixels(full, cx, cy))
            for y in range(8):
                for x in range(8):
                    c = ink if data[y] & (0x80 >> x) else paper
                    im.putpixel((cx * 8 + x, cy * 8 + y), C64_RGB[c])
    im.resize((cv.w * 3, cv.h * 3), Image.NEAREST).save(path)


# ------------------------------------------------------------ multicolor

HALF_RULE = 'black'


def mc_half(px, transparent=False):
    """An 8x8 cell of C64 colors (NONE = see-through) -> 4x8 multicolor pixels.
    Of two different neighbours black wins (the outlines and the lines stay whole),
    else the color that covers more of the cell (flat, calm surfaces); an opaque
    pixel always beats a see-through one."""
    flat = [c for row in px for c in row if c != NONE]
    out = []
    for row in px:
        r = []
        for x in range(4):
            a, b = row[2 * x], row[2 * x + 1]
            if a == b:
                r.append(a)
            elif a == NONE or b == NONE:
                r.append(b if a == NONE else a)
            elif HALF_RULE == 'black' and (a == 0 or b == 0):
                r.append(0)
            elif HALF_RULE == 'rare':
                r.append(a if flat.count(a) <= flat.count(b) else b)
            else:
                r.append(a if flat.count(a) >= flat.count(b) else b)
        out.append(r)
    return out


def mc_palette(pixels, free, fixed=()):
    """Up to `free` colors for the pixels (besides the fixed ones), least error."""
    counts = {}
    for c in pixels:
        if c != NONE and c not in fixed:
            counts[c] = counts.get(c, 0) + 1
    cols = sorted(counts, key=lambda c: -counts[c])
    if len(cols) <= free:
        return list(cols)
    best = None
    for combo in itertools.combinations(cols, free):
        pal = list(fixed) + list(combo)
        err = sum(n * min(cdist(c, p) for p in pal) for c, n in counts.items())
        if best is None or err < best[0]:
            best = (err, list(combo))
    return best[1]


def mc_scene_cell(px):
    """-> (8 bytes, screen byte, color RAM byte); black is the %00 background."""
    half = mc_half(px)
    flat = [c for row in half for c in row]
    pal = mc_palette(flat, 3, fixed=(0,))
    full = [0] + pal
    data = []
    for row in half:
        v = 0
        for c in row:
            q = min(full, key=lambda p: cdist(c, p))
            v = (v << 2) | full.index(q)
        data.append(v)
    pal = pal + [0] * (3 - len(pal))
    return data, (pal[0] << 4) | pal[1], pal[2]


def mc_figure_cell(px):
    """-> None (empty) or (8 bytes with %00 = see-through, (c1 << 4) | c2, c3)."""
    half = mc_half(px, transparent=True)
    flat = [c for row in half for c in row if c != NONE]
    if not flat:
        return None
    pal = mc_palette(flat, 3)
    data = []
    for row in half:
        v = 0
        for c in row:
            code = 0 if c == NONE else 1 + pal.index(min(pal, key=lambda p: cdist(c, p)))
            v = (v << 2) | code
        data.append(v)
    pal = pal + [0] * (3 - len(pal))
    return data, (pal[0] << 4) | pal[1], pal[2]


# ------------------------------------------------------------ multicolor, v2

# the scenes' palettes: the office's navy floor is a blue / dark grey dither,
# calmer than the C64's bright blue
SCENE_PAL = {
    'office': [0, 11, 15, (6, 11), 1, 8, 2, 7, 5, 14, 12, 13, 10, 10, 15, 10],
}

# the conversion works on the original's palette indexes at multicolor
# resolution; a scene palette maps them to C64 colors, an entry may be a pair
# (a, b): a checkerboard of the two (to darken a color the C64 does not have)

def half_scene(cv):
    """The scene at multicolor resolution: black wins a pair (lines, outlines),
    else the color covering more of its 8x8 cell (calm surfaces)."""
    w = cv.w // 2
    out = [[0] * w for _ in range(cv.h)]
    for cy in range(cv.h // 8):
        for cx in range(cv.w // 8):
            cell = [cv.px[cy * 8 + y][cx * 8 + x] for y in range(8) for x in range(8)]
            for y in range(8):
                for x in range(4):
                    a = cv.px[cy * 8 + y][cx * 8 + 2 * x]
                    b = cv.px[cy * 8 + y][cx * 8 + 2 * x + 1]
                    row = cv.px[cy * 8 + y]
                    gx = cx * 8 + 2 * x
                    nxt = row[gx + 2] if gx + 2 < cv.w else row[gx]
                    if a == b:
                        c = a
                    elif a == 0 or b == 0:
                        c = 0
                    elif nxt == a:
                        # a dither of two colors stays a dither
                        c = a if ((cx * 4 + x + cy * 8 + y) & 1) == 0 else b
                    else:
                        c = a if cell.count(a) >= cell.count(b) else b
                    out[cy * 8 + y][cx * 4 + x] = c
    return out


def half_figure(cv):
    """A figure at multicolor resolution: an opaque pixel beats a see-through one,
    black wins at the row's edges (the contour), inside the rarer one of the row
    stays (the eyes, the buttons)."""
    w = cv.w // 2
    out = [[NONE] * w for _ in range(cv.h)]
    for y in range(cv.h):
        row = cv.px[y]
        solid = [c for c in row if c != NONE]
        for x in range(w):
            a, b = row[2 * x], row[2 * x + 1]
            if a == b:
                c = a
            elif a == NONE or b == NONE:
                c = b if a == NONE else a
            elif 0 in (a, b):
                left = row[2 * x - 1] if x > 0 else NONE
                right = row[2 * x + 2] if 2 * x + 2 < cv.w else NONE
                if left == NONE or right == NONE:
                    c = 0
                else:
                    other = b if a == 0 else a
                    c = 0 if solid.count(0) <= solid.count(other) else other
            else:
                c = a if solid.count(a) <= solid.count(b) else b
            out[y][x] = c
    return out


def to_c64(half, pal):
    """Original palette indexes -> C64 colors (NONE stays); pal[i] is a color or a
    (a, b) checkerboard."""
    out = []
    for y, row in enumerate(half):
        r = []
        for x, c in enumerate(row):
            if c == NONE:
                r.append(NONE)
                continue
            m = pal[c]
            if isinstance(m, tuple):
                m = m[(x + y) & 1]
            r.append(m)
        out.append(r)
    return out


def mc_cells(img, transparent=False):
    """Multicolor pixels (C64 colors) -> cells: scene (data, screen, colram) or
    figure None / (data, c12, c3)."""
    h, w = len(img) // 8, len(img[0]) // 4
    cells = []
    for cy in range(h):
        row = []
        for cx in range(w):
            px = [img[cy * 8 + y][cx * 4:cx * 4 + 4] for y in range(8)]
            flat = [c for r in px for c in r]
            if transparent:
                solid = [c for c in flat if c != NONE]
                if not solid:
                    row.append(None)
                    continue
                pal = mc_palette(solid, 3)
                data = []
                for r in px:
                    v = 0
                    for c in r:
                        code = 0 if c == NONE else 1 + pal.index(min(pal, key=lambda p: cdist(c, p)))
                        v = (v << 2) | code
                    data.append(v)
                pal = pal + [0] * (3 - len(pal))
                row.append((data, (pal[0] << 4) | pal[1], pal[2]))
            else:
                pal = mc_palette(flat, 3, fixed=(0,))
                full = [0] + pal
                data = []
                for r in px:
                    v = 0
                    for c in r:
                        v = (v << 2) | full.index(min(full, key=lambda p: cdist(c, p)))
                    data.append(v)
                pal = pal + [0] * (3 - len(pal))
                row.append((data, (pal[0] << 4) | pal[1], pal[2]))
        cells.append(row)
    return cells


# ------------------------------------------------------------ the drawn figures

FIG_LETTERS = {'.': NONE, 'K': 0, 'W': 1, 'R': 2, 'C': 3, 'P': 4, 'G': 5, 'B': 6, 'Y': 7,
               'O': 8, 'N': 9, 'L': 10, 'D': 11, 'M': 12, 'E': 13, 'U': 14, 'S': 15}


def load_figures(path):
    """figures.txt -> {name: rows of C64 colors (NONE = see-through)}; checks the
    three-color limit of every 4x8 block."""
    figs, name, problems = {}, None, []
    for line in open(path):
        line = line.rstrip('\n')
        if line.startswith('#') or not line.strip():
            continue
        if line.startswith('== '):
            name = line[3:].strip()
            figs[name] = []
            continue
        figs[name].append([FIG_LETTERS[ch] for ch in line])
    for name, rows in figs.items():
        w = len(rows[0])
        assert all(len(r) == w for r in rows), name
        assert w % 4 == 0 and len(rows) % 8 == 0, name
        for by in range(len(rows) // 8):
            for bx in range(w // 4):
                cols = {rows[by * 8 + y][bx * 4 + x] for y in range(8) for x in range(4)} - {NONE}
                if len(cols) > 3:
                    problems.append('%s block %d,%d: %d colors' % (name, bx, by, len(cols)))
    return figs, problems


def load_patches(path):
    """scene_patches.txt -> {scene: [(x, y, rows of C64 colors or NONE)]}"""
    out, cur = {}, None
    for line in open(path):
        line = line.rstrip('\n')
        if line.startswith('#') or not line.strip():
            continue
        if line.startswith('== '):
            name, x, y = line[3:].split()
            cur = []
            out.setdefault(name, []).append((int(x), int(y), cur))
            continue
        cur.append([FIG_LETTERS[ch] for ch in line])
    return out


def apply_patches(img, patches):
    for x0, y0, rows in patches:
        for y, row in enumerate(rows):
            for x, c in enumerate(row):
                if c != NONE:
                    img[y0 + y][x0 + x] = c
    return img
