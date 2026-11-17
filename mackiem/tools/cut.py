# Cuts an AI sheet (figures on magenta) into separate transparent sprites.
# Usage: python tools/cut.py gen/raw_x.png name1,name2,... <height_px> [each] [flip=i,j]
# Without "each" the first figure sets the scale for the whole sheet; with it every figure gets that height.
import sys, numpy as np
from PIL import Image
from scipy import ndimage as ndi
src, names, H = sys.argv[1], sys.argv[2].split(','), int(sys.argv[3])
each = 'each' in sys.argv
flips = []
for a in sys.argv:
    if a.startswith('flip='): flips = [int(x) for x in a[5:].split(',')]
im = np.asarray(Image.open(src).convert('RGB')).astype(np.float32) / 255.0
r, g, b = im[..., 0], im[..., 1], im[..., 2]
m = np.minimum(r, b) - g
alpha = np.clip(1.0 - (m - 0.18) / 0.25, 0, 1)
solid = alpha > 0.5
lab, n = ndi.label(ndi.binary_dilation(solid, iterations=5))
sizes = ndi.sum(solid, lab, range(1, n + 1))
order = np.argsort(-sizes)[:len(names)]
boxes = ndi.find_objects(lab)
figs = [(i + 1, boxes[i]) for i in order if sizes[i] > 400]
tall = max(s[0].stop - s[0].start for _, s in figs)
def key(f):
    s = f[1]
    return (round(((s[0].start + s[0].stop) / 2) / (tall * 0.6)), s[1].start)
figs.sort(key=key)
if len(figs) != len(names):
    print('ERROR: found', len(figs), 'figures, expected', len(names)); sys.exit(1)
# despill: pull pink fringe back to neutral
k = np.clip(m, 0, 1) * 0.9
rgb = np.stack([r - k, g, b - k], -1).clip(0, 1)
scale = None
outs = []
for idx, (id_, s) in enumerate(figs):
    a = alpha[s] * (lab[s] == id_)
    a = ndi.gaussian_filter(a, 0.6) * (a > 0)
    ys, xs = np.where(a > 0.3)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    c = rgb[s][y0:y1, x0:x1]; a = a[y0:y1, x0:x1]
    pm = np.dstack([c * a[..., None], a])
    if each or scale is None: scale = H / (y1 - y0)
    w, h = max(1, round((x1 - x0) * scale)), max(1, round((y1 - y0) * scale))
    chans = [np.asarray(Image.fromarray(pm[..., i]).resize((w, h), Image.LANCZOS)) for i in range(4)]
    pm2 = np.dstack(chans).clip(0, 1)
    a2 = pm2[..., 3:4]
    out = np.dstack([np.where(a2 > 0.003, pm2[..., :3] / np.maximum(a2, 0.003), 0).clip(0, 1), a2])
    img = Image.fromarray((out * 255).astype(np.uint8))
    if idx in flips: img = img.transpose(Image.FLIP_LEFT_RIGHT)
    # pad so the feet (bottom rows) sit at the horizontal centre: Unity pivots at bottom centre
    al = np.asarray(img)[..., 3]; rows = al[int(al.shape[0] * 0.9):]
    xs2 = np.where(rows > 60)[1]; ax = int(xs2.mean()) if len(xs2) else img.width // 2
    half = max(ax, img.width - ax) + 2
    pad = Image.new('RGBA', (half * 2, img.height + 2), (0, 0, 0, 0)); pad.paste(img, (half - ax, 0)); img = pad
    img.save('Assets/Resources/Art/%s.png' % names[idx]); outs.append(img)
    print(names[idx], img.size)
W = sum(o.width + 10 for o in outs); Hh = max(o.height for o in outs) + 10
sheet = Image.new('RGBA', (W, Hh), (214, 204, 180, 255)); x = 5
for o in outs:
    sheet.alpha_composite(o, (x, Hh - 5 - o.height)); x += o.width + 10
sheet.convert('RGB').save('shots/cut_%s.png' % names[0])
