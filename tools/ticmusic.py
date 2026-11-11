"""TIC-80 music reader: tracks, patterns and the SFX instruments of a cart."""
import re

NOTES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']


def _section(txt, name):
    m = re.search(r'-- <%s>\n(.*?)-- </%s>' % (name, name), txt, re.S)
    out = {}
    for line in m.group(1).splitlines():
        mm = re.match(r'-- (\d+):(\w+)', line)
        if mm:
            h = mm.group(2)
            out[int(mm.group(1))] = bytes(int(h[i + 1] + h[i], 16) for i in range(0, len(h), 2))
    return out


def load(path):
    txt = open(path).read()
    pats = {}
    for k, b in _section(txt, 'PATTERNS').items():
        b = b.ljust(192, b'\0')
        rows = []
        for r in range(64):
            b0, b1, b2 = b[r * 3:r * 3 + 3]
            rows.append(dict(note=b0 & 15, p1=b0 >> 4, p2=b1 & 15, cmd=(b1 >> 4) & 7,
                             sfx=((b1 >> 7) << 5) | (b2 & 31), octave=b2 >> 5))
        pats[k] = rows
    tracks = {}
    for k, b in _section(txt, 'TRACKS').items():
        b = b.ljust(51, b'\0')
        frames = []
        for f in range(16):
            v = b[f * 3] | b[f * 3 + 1] << 8 | b[f * 3 + 2] << 16
            frames.append([(v >> (6 * c)) & 63 for c in range(4)])
        tempo = (b[48] if b[48] < 128 else b[48] - 256) + 150
        rows = 64 - b[49]
        speed = (b[50] if b[50] < 128 else b[50] - 256) + 6
        tracks[k] = dict(frames=frames, tempo=tempo, rows=rows, speed=speed)
    sfx = {}
    for k, b in _section(txt, 'SFX').items():
        b = b.ljust(66, b'\0')
        ticks = [dict(volume=15 - (b[i * 2] & 15), wave=b[i * 2] >> 4, chord=b[i * 2 + 1] & 15,
                      pitch=((b[i * 2 + 1] >> 4) ^ 8) - 8) for i in range(30)]
        h0, h1 = b[60], b[61]
        speed = ((h0 >> 4) & 7)
        speed = speed - 8 if speed >= 4 else speed
        sfx[k] = dict(ticks=ticks, octave=h0 & 7, speed=speed, note=h1 & 15,
                      loops=[(b[62 + i] & 15, b[62 + i] >> 4) for i in range(4)])
    return pats, tracks, sfx


def events(pats, track):
    """[(channel, frame index, row, note 0-95 or 'stop', sfx, cmd, p1, p2)] in play order."""
    out = []
    for fi, frame in enumerate(track['frames']):
        if not any(frame):
            break
        for c, p in enumerate(frame):
            if not p:
                continue
            for r, row in enumerate(pats.get(p - 1, [])[:track['rows']]):
                if row['note'] == 1:
                    out.append((c, fi, r, 'stop', row['sfx'], row['cmd'], row['p1'], row['p2']))
                elif row['note'] >= 4:
                    out.append((c, fi, r, row['octave'] * 12 + row['note'] - 4, row['sfx'], row['cmd'], row['p1'], row['p2']))
    return out


if __name__ == '__main__':
    import sys
    pats, tracks, sfx = load(sys.argv[1])
    for t, tr in sorted(tracks.items()):
        print('track', t, 'tempo', tr['tempo'], 'speed', tr['speed'], 'rows', tr['rows'], 'frames',
              [f for f in tr['frames'] if any(f)])
        for e in events(pats, tr):
            c, fi, r, n, s, cmd, p1, p2 = e
            name = n if n == 'stop' else NOTES[n % 12] + str(n // 12)
            print('  ch%d f%d r%02d %-4s sfx%02d cmd%d %d%d' % (c, fi, r, name, s, cmd, p1, p2))
    for k, s in sorted(sfx.items()):
        print('sfx', k, 'speed', s['speed'], 'waves', [t['wave'] for t in s['ticks'][:12]],
              'vol', [t['volume'] for t in s['ticks'][:16]], 'pitch', [t['pitch'] for t in s['ticks'][:10]], 'loops', s['loops'])
