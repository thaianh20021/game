# Cuts an AI sheet (figures on a flat magenta-ish background) into separate transparent sprites.
# Usage: python tools/cut.py gen/raw_x.png name1,name2,... <height_px> [each] [med] [anim] [flip=i,j]
#   default: the first figure sets the scale for the whole sheet
#   each:    every figure is scaled to that height (icons, props)
#   med:     the median figure height becomes that height (animation sheets)
#   anim:    frames of one character: centre on the upper body (it stays put while legs move)
#            and keep each row's common ground line, so jumps stay in the air
import sys, numpy as np
from PIL import Image
from scipy import ndimage as ndi
src, names, H = sys.argv[1], sys.argv[2].split(','), int(sys.argv[3])
each, med, anim = 'each' in sys.argv, 'med' in sys.argv, 'anim' in sys.argv
flips = []
for a in sys.argv:
    if a.startswith('flip='): flips = [int(x) for x in a[5:].split(',')]
im = np.asarray(Image.open(src).convert('RGB')).astype(np.float32) / 255.0
r, g, b = im[..., 0], im[..., 1], im[..., 2]
# the background colour is whatever the border is painted with
edge = np.concatenate([im[:6].reshape(-1, 3), im[-6:].reshape(-1, 3), im[:, :6].reshape(-1, 3), im[:, -6:].reshape(-1, 3)])
bg = np.median(edge, axis=0)
dist = np.sqrt(((im - bg) ** 2).sum(-1))
m = np.minimum(r, b) - g
if bg.min() > 0.8:
    # white sheet: only the white that is connected to the border is background (outlines keep the inside)
    near = dist < 0.16
    lb, _ = ndi.label(near)
    ids = np.unique(np.concatenate([lb[0], lb[-1], lb[:, 0], lb[:, -1]]))
    outside = np.isin(lb, ids[ids > 0])
    alpha = ndi.gaussian_filter((~outside).astype(np.float32), 0.7)
    alpha = np.where(outside, np.minimum(alpha, 0.0), alpha)
    m = np.zeros_like(m)
else:
    alpha = np.clip((dist - 0.10) / 0.16, 0, 1)
    alpha = np.where((m > 0.22) & (dist < 0.42), 0, alpha)   # brighter or duller patches of the same pink
solid = alpha > 0.5
lab, n = ndi.label(ndi.binary_dilation(solid, iterations=5))
sizes = ndi.sum(solid, lab, range(1, n + 1))
order = np.argsort(-sizes)[:len(names)]
boxes = ndi.find_objects(lab)
figs = [(i + 1, boxes[i]) for i in order if sizes[i] > 400]
tall = max(s[0].stop - s[0].start for _, s in figs)
def row(f):
    s = f[1]
    return round(((s[0].start + s[0].stop) / 2) / (tall * 0.6))
figs.sort(key=lambda f: (row(f), f[1][1].start))
if len(figs) != len(names):
    print('ERROR: found', len(figs), 'figures, expected', len(names)); sys.exit(1)
k = np.clip(m, 0, 1) * 0.9 * (ndi.binary_dilation(~solid, iterations=3))
rgb = np.stack([r - k, g, b - k], -1).clip(0, 1)
cuts = []
for id_, s in figs:
    a = alpha[s] * (lab[s] == id_)
    a = ndi.gaussian_filter(a, 0.6) * (a > 0)
    ys, xs = np.where(a > 0.3)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    cuts.append((rgb[s][y0:y1, x0:x1], a[y0:y1, x0:x1], s[0].start + y1, row((id_, s))))
heights = [c[1].shape[0] for c in cuts]
base = {}
for c in cuts: base[c[3]] = max(base.get(c[3], 0), c[2])
scale = H / (np.median(heights) if med else heights[0])
outs = []
for idx, (c, a, bottom, rw) in enumerate(cuts):
    if each: scale = H / a.shape[0]
    pm = np.dstack([c * a[..., None], a])
    w, h = max(1, round(a.shape[1] * scale)), max(1, round(a.shape[0] * scale))
    chans = [np.asarray(Image.fromarray(pm[..., i]).resize((w, h), Image.LANCZOS)) for i in range(4)]
    pm2 = np.dstack(chans).clip(0, 1)
    a2 = pm2[..., 3:4]
    out = np.dstack([np.where(a2 > 0.003, pm2[..., :3] / np.maximum(a2, 0.003), 0).clip(0, 1), a2])
    img = Image.fromarray((out * 255).astype(np.uint8))
    if idx in flips: img = img.transpose(Image.FLIP_LEFT_RIGHT)
    al = np.asarray(img)[..., 3]
    part = al[:int(al.shape[0] * 0.5)] if anim else al[int(al.shape[0] * 0.9):]
    xs2 = np.where(part > 60)[1]
    ax = int(np.median(xs2)) if len(xs2) else img.width // 2
    half = max(ax, img.width - ax) + 2
    lift = min(int((base[rw] - bottom) * scale), int(h * 0.2)) if anim else 0
    pad = Image.new('RGBA', (half * 2, img.height + 2 + lift), (0, 0, 0, 0)); pad.paste(img, (half - ax, 0)); img = pad
    img.save('Assets/Resources/Art/%s.png' % names[idx]); outs.append(img)
    print(names[idx], img.size)
W = sum(o.width + 10 for o in outs); Hh = max(o.height for o in outs) + 10
sheet = Image.new('RGBA', (W, Hh), (214, 204, 180, 255)); x = 5
for o in outs:
    sheet.alpha_composite(o, (x, Hh - 5 - o.height)); x += o.width + 10
sheet.convert('RGB').save('shots/cut_%s.png' % names[0])
