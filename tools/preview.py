#!/usr/bin/env python3
"""Render what the C64 shows for a scene with its figures (the multicolor cells and
the run-time figure merge of video.asm), beside the TIC-80 original, to a PNG.

Usage: python3 tools/preview.py out_dir
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_data as bd  # noqa: E402
import gfx  # noqa: E402
from gfx import C64_RGB, NONE, Canvas, cell_pixels, load_tic, render_map  # noqa: E402

TICPAL = [(4, 4, 0), (95, 87, 79), (194, 195, 199), (29, 43, 83), (255, 241, 232), (171, 82, 54),
          (126, 37, 83), (255, 163, 0), (0, 135, 81), (41, 173, 255), (131, 118, 156), (0, 228, 54),
          (250, 119, 168), (255, 0, 77), (195, 195, 199), (255, 204, 170)]


def coldist():
    mx = max(gfx.cdist(a, b) for a in range(16) for b in range(16))
    return [[int(round(255 * (gfx.cdist(a, b) / mx) ** 0.5)) for b in range(16)] for a in range(16)]


def decode_scene(data, sc, cr):
    cols = [0, sc >> 4, sc & 15, cr]
    return [[cols[(b >> (6 - 2 * x)) & 3] for x in range(4)] for b in data]


def merge(px, fig, dist):
    """px: 8x4 colors of the scene cell; fig = (bits, c12, c3) -> 8x4 colors as video.asm does it."""
    bits, c12, c3 = fig
    fcol = [None, c12 >> 4, c12 & 15, c3]
    cnt = [0] * 16
    out = []
    for y in range(8):
        row = []
        for x in range(4):
            code = (bits[y] >> (6 - 2 * x)) & 3
            if code:
                c = fcol[code]
                cnt[c] += 4
            else:
                c = px[y][x]
                cnt[c] += 1
            row.append(c)
        out.append(row)
    cnt[0] = 0
    picked = []
    for _ in range(3):
        best, bc = 0, 0
        for c in range(15, 0, -1):
            if cnt[c] and cnt[c] >= best and c not in picked:
                best, bc = cnt[c], c
        picked.append(bc)
    slots = [0] + picked
    code = {}
    for c in range(16):
        if c == 0:
            code[c] = 0
        elif c in picked:
            code[c] = 1 + picked.index(c)
        else:
            best = None
            for i, s in enumerate(slots):
                if s == 0 and i:
                    continue
                d = dist[c][s]
                if best is None or d < best[0]:
                    best = (d, i)
            code[c] = best[1]
    return [[slots[code[c]] for c in row] for row in out]


SCENE_PAL = dict(gfx.SCENE_PAL)
if os.environ.get('OFFICE'):
    _p = list(gfx.PAL2C64)
    for kv in os.environ['OFFICE'].split(';'):
        k, v = kv.split('=')
        _p[int(k)] = tuple(int(x) for x in v.split(',')) if ',' in v else int(v)
    SCENE_PAL['office'] = _p
FIG_PAL = None


def scene_cells(cv, name):
    pal = SCENE_PAL.get(name, gfx.PAL2C64)
    return gfx.mc_cells(gfx.apply_patches(gfx.to_c64(gfx.half_scene(cv), pal), bd.PATCHES.get(name, [])))


DRAWN, PROBLEMS = gfx.load_figures(os.path.join(bd.ASSETS, 'figures.txt'))


def figure_cells(fcv):
    if getattr(fcv, 'drawn', None):
        return gfx.mc_cells(DRAWN[fcv.drawn], transparent=True)
    return gfx.mc_cells(gfx.to_c64(gfx.half_figure(fcv), FIG_PAL or gfx.PAL2C64), transparent=True)


def render(scene_cv, figures, path, scale=4, name=''):
    from PIL import Image
    dist = coldist()
    w, h = scene_cv.w // 8, scene_cv.h // 8
    sc = scene_cells(scene_cv, name)
    cells = [[decode_scene(*sc[cy][cx]) for cx in range(w)] for cy in range(h)]
    for fcv, fx, fy in figures:
        fc = figure_cells(fcv)
        for cy in range(fcv.h // 8):
            for cx in range(fcv.w // 8):
                f = fc[cy][cx]
                tx, ty = fx + cx, fy + cy
                if f and 0 <= tx < w and 0 <= ty < h:
                    cells[ty][tx] = merge(cells[ty][tx], f, dist)
    c64 = Image.new('RGB', (w * 8, h * 8))
    for cy in range(h):
        for cx in range(w):
            for y in range(8):
                for x in range(4):
                    col = C64_RGB[cells[cy][cx][y][x]]
                    c64.putpixel((cx * 8 + 2 * x, cy * 8 + y), col)
                    c64.putpixel((cx * 8 + 2 * x + 1, cy * 8 + y), col)
    full = Canvas(scene_cv.w, scene_cv.h)
    full.px = [r[:] for r in scene_cv.px]
    for fcv, fx, fy in figures:
        for y in range(fcv.h):
            for x in range(fcv.w):
                if fcv.px[y][x] != NONE:
                    full.put(fx * 8 + x, fy * 8 + y, fcv.px[y][x])
    orig = Image.new('RGB', (w * 8, h * 8))
    for y in range(full.h):
        for x in range(full.w):
            orig.putpixel((x, y), TICPAL[full.px[y][x]])
    out = Image.new('RGB', (w * 16 + 8, h * 8), (40, 40, 40))
    out.paste(orig, (0, 0))
    out.paste(c64, (w * 8 + 8, 0))
    out.resize((out.width * scale // 2, out.height * scale // 2), Image.NEAREST).save(path)


def sheet(figs, path):
    """Every figure big: the original, then the C64 on black and on grey."""
    from PIL import Image
    names = list(figs)
    cw, chh = 3 * 32 + 16, 40
    out = Image.new('RGB', (cw * 6, chh * ((len(names) + 5) // 6)), (40, 40, 40))
    dist = coldist()
    for i, n in enumerate(names):
        fcv = figs[n]
        ox, oy = (i % 6) * cw, (i // 6) * chh
        for y in range(fcv.h):
            for x in range(fcv.w):
                c = fcv.px[y][x]
                out.putpixel((ox + x, oy + y), TICPAL[c] if c != NONE else (40, 40, 40))
        fc = figure_cells(fcv)
        for k, bg in enumerate((0, 11)):
            for cy in range(fcv.h // 8):
                for cx in range(fcv.w // 8):
                    base = [[bg] * 4 for _ in range(8)]
                    px = merge(base, fc[cy][cx], dist) if fc[cy][cx] else base
                    for y in range(8):
                        for x in range(4):
                            col = C64_RGB[px[y][x]]
                            for d in (0, 1):
                                out.putpixel((ox + 32 + k * 32 + cx * 8 + 2 * x + d, oy + cy * 8 + y), col)
    out.resize((out.width * 4, out.height * 4), Image.NEAREST).save(path)


def main(out):
    tiles, sprites, mp = load_tic(os.path.join(bd.ASSETS, 'impostor.assets.lua'))
    figs = {n: bd.build_figure(sprites, p)[0] for n, p, _ in bd.FIGDEFS}
    for n, f in figs.items():
        if n in DRAWN:
            f.drawn = n
    for p in PROBLEMS:
        print('PROBLEM', p)
    render(render_map(tiles, mp, 60), [(figs['norman'], 13, 9), (figs['pm'], 6, 4), (figs['hr'], 12, 4),
                                        (figs['introvert'], 16, 4), (figs['extrovert'], 20, 4),
                                        (figs['guru'], 15, 9), (figs['operator'], 17, 8),
                                        (figs['buddy'], 10, 12), (figs['boy'], 22, 11), (figs['girl'], 27, 11)],
           os.path.join(out, 'pv_office.png'), name='office')
    render(render_map(tiles, mp, 30), [(figs['norman'], 7, 3), (figs['sumphore'], 9, 2), (figs['vendor'], 19, 0),
                                        (figs['guard'], 22, 3), (figs['trinity'], 5, 11), (figs['neo'], 9, 11),
                                        (figs['oraculum'], 15, 12), (figs['architect'], 21, 11)],
           os.path.join(out, 'pv_street.png'), name='street')
    render(render_map(tiles, mp, 0), [(figs['norman'], 12, 10)], os.path.join(out, 'pv_bedroom.png'), name='bedroom')
    render(render_map(tiles, mp, 0), [(figs['sleeping'], 11, 5)], os.path.join(out, 'pv_sleep.png'), name='bedroom')
    sheet(figs, os.path.join(out, 'pv_figures.png'))


if __name__ == '__main__':
    main(sys.argv[1])
