# Cuts the puppet parts sheet (tools/parts.sh) into one sprite per body part and measures the joints.
# Usage: python tools/parts.py gen/raw_parts.png
# Writes Assets/Resources/Art/rig_<part>.png, Assets/Resources/rig.json and shots/rig_parts.png.
# Every piece is drawn hanging straight down (the sword points up): its joint is the middle of the opaque
# pixels in its top rows and its far end the middle of its bottom rows. Points are in sprite pixels,
# origin bottom-left, which is how Rig.cs reads them.
import json
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

NAMES = ['head', 'torso', 'skirt', 'arm', 'fore', 'hand', 'thigh', 'shin', 'sword', 'scarf', 'tail', 'hilt']
# usage for other sheets: python tools/parts.py <sheet> <name1,name2,...> <json name>  (weapons: one pin = the grip)
if len(sys.argv) > 2: NAMES = sys.argv[2].split(',')
OUT = sys.argv[3] if len(sys.argv) > 3 else 'rig'
WEAPONS = len(sys.argv) > 2
SCALE = 0.5   # the sheet is drawn large; half size keeps the sprites about twice their size on screen

rgba = np.asarray(Image.open(sys.argv[1]).convert('RGBA')).astype(np.float32) / 255.0
im = rgba[..., :3].copy()
dist = np.sqrt(((im - 1.0) ** 2).sum(-1))
if np.concatenate([rgba[:6, :, 3].ravel(), rgba[-6:, :, 3].ravel()]).mean() < 0.1:
    outside = rgba[..., 3] < 0.5          # the sheet came with a transparent background
else:
    near = dist < 0.16
    lb, _ = ndi.label(near)
    ids = np.unique(np.concatenate([lb[0], lb[-1], lb[:, 0], lb[:, -1]]))
    outside = np.isin(lb, ids[ids > 0])
# the model draws a pin hole at each joint of the puppet: small white pockets inside a piece.
# They mark the pivots exactly; afterwards they are filled with the colour around them.
lb2, n2 = ndi.label((dist < 0.14) & ~outside)
holes = []
if n2:
    sz = ndi.sum(np.ones_like(lb2), lb2, range(1, n2 + 1))
    for k in np.where((sz > 25) & (sz < 4000))[0]:
        m = lb2 == k + 1
        cy, cx = ndi.center_of_mass(m)
        ring = ndi.binary_dilation(m, iterations=4) & ~ndi.binary_dilation(m, iterations=1) & ~outside
        if ring.sum() > 0:
            im[m] = np.median(im[ring], axis=0)
        holes.append((cy, cx, sz[k]))
if WEAPONS:
    # weapons have no white cloth: any larger white pocket (between a bow and its string) is background
    lb3, n3 = ndi.label((dist < 0.08) & ~outside)
    if n3:
        sz3 = ndi.sum(np.ones_like(lb3), lb3, range(1, n3 + 1))
        outside |= np.isin(lb3, 1 + np.where(sz3 >= 4000)[0])
alpha = ndi.gaussian_filter((~outside).astype(np.float32), 0.7) * (~outside)
solid = alpha > 0.5
lab, n = ndi.label(ndi.binary_dilation(solid, iterations=4))
sizes = ndi.sum(solid, lab, range(1, n + 1))
boxes = ndi.find_objects(lab)
order = np.argsort(-sizes)[:len(NAMES)]
figs = [(i + 1, boxes[i]) for i in order if sizes[i] > 300]
if len(figs) != len(NAMES):
    print('ERROR: found', len(figs), 'pieces, expected', len(NAMES))
    sys.exit(1)
tall = max(s[0].stop - s[0].start for _, s in figs)
mid = im.shape[0] / 2
figs.sort(key=lambda f: (0 if WEAPONS or (f[1][0].start + f[1][0].stop) / 2 < mid else 1, f[1][1].start))   # the weapon sheet is one row

meta = {}
outs = []
for name, (id_, s) in zip(NAMES, figs):
    a = alpha[s] * (lab[s] == id_)
    ys, xs = np.where(a > 0.3)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    a = a[y0:y1, x0:x1]
    c = im[s][y0:y1, x0:x1]
    pm = np.dstack([c * a[..., None], a])
    w, h = max(1, round(a.shape[1] * SCALE)), max(1, round(a.shape[0] * SCALE))
    ch = [np.asarray(Image.fromarray(pm[..., i]).resize((w, h), Image.LANCZOS)) for i in range(4)]
    pm2 = np.dstack(ch).clip(0, 1)
    a2 = pm2[..., 3:4]
    out = np.dstack([np.where(a2 > 0.003, pm2[..., :3] / np.maximum(a2, 0.003), 0).clip(0, 1), a2])
    img = Image.fromarray((out * 255).astype(np.uint8))
    img.save('Assets/Resources/Art/%s_%s.png' % ('rigw' if WEAPONS else 'rig', name))
    al = out[..., 3]

    def mid_x(rows):
        xs_ = np.where(al[rows] > 0.4)[1]
        return float(np.median(xs_)) if len(xs_) else w / 2.0

    band = max(2, h // 12)
    top = [mid_x(slice(0, band)), h - band * 0.6]
    bot = [mid_x(slice(h - band, h)), band * 0.6]
    # pin holes of this piece, in sprite pixels with the origin at the bottom left
    oy, ox = s[0].start + y0, s[1].start + x0
    mine = [((hx - ox) * SCALE, h - (hy - oy) * SCALE, hs) for hy, hx, hs in holes
            if s[0].start + y0 <= hy < s[0].start + y1 and s[1].start + x0 <= hx < s[1].start + x1 and lab[int(hy), int(hx)] == id_]
    mine.sort(key=lambda q: -q[1])
    if WEAPONS:
        # the grip is the biggest pin hole; 'top' stays the tip
        if mine: bot = list(max(mine, key=lambda q: q[2])[:2])
    else:
        if mine and mine[0][1] > h * 0.55: top = list(mine[0][:2])
        if mine and mine[-1][1] < h * 0.45: bot = list(mine[-1][:2])
    if name == 'sword': bot = [bot[0], bot[1] + h * 0.07]   # grip above the pommel pin
    # cut away the pin plates beyond the joints (keep the plate on the sword and the head's hair)
    if name in ('torso', 'skirt', 'arm', 'fore', 'hand', 'thigh', 'shin') and mine:
        arr = np.asarray(img).copy()
        if mine[0][1] > h * 0.55:
            arr[:max(0, int(h - mine[0][1]) - 2), :, 3] = 0
        if mine[-1][1] < h * 0.45 and name not in ('shin',):
            arr[min(h, int(h - mine[-1][1]) + 2):, :, 3] = 0
        img = Image.fromarray(arr)
        img.save('Assets/Resources/Art/%s_%s.png' % ('rigw' if WEAPONS else 'rig', name))
    meta[name] = {'w': w, 'h': h, 'top': top, 'bot': bot, 'pins': len(mine)}
    outs.append(img)
    print(name, (w, h), 'top', [round(v) for v in top], 'bot', [round(v) for v in bot], 'pins', len(mine))

json.dump(meta, open('Assets/Resources/%s.json' % OUT, 'w'), indent=1)
W = sum(o.width + 10 for o in outs)
H = max(o.height for o in outs) + 10
sheet = Image.new('RGBA', (W, H), (214, 204, 180, 255))
x = 5
for o in outs:
    sheet.alpha_composite(o, (x, H - 5 - o.height))
    x += o.width + 10
sheet.convert('RGB').save('shots/%s_parts.png' % OUT)
