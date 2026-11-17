# Exit 0 when a sheet has a clean white (or transparent) border, 1 when the model painted a dark one.
import sys
import numpy as np
from PIL import Image

raw = Image.open(sys.argv[1])
a = np.asarray(raw.convert('RGBA')).astype(float) / 255.0
if np.concatenate([a[:6, :, 3].ravel(), a[-6:, :, 3].ravel()]).mean() < 0.1:
    sys.exit(0)
im = a[..., :3]
e = np.concatenate([im[:8].reshape(-1, 3), im[-8:].reshape(-1, 3), im[:, :8].reshape(-1, 3), im[:, -8:].reshape(-1, 3)])
sys.exit(0 if np.median(e) > 0.85 and (e.min(axis=1) > 0.7).mean() > 0.9 else 1)
