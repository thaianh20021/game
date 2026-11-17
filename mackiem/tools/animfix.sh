#!/usr/bin/env bash
# Draws every foe animation sheet that is missing or came back on a dark background (the GPT image
# models only sometimes obey the white sheet), up to three tries each. Usage: MK_KEYS="key" tools/animfix.sh
export MK_BG=white
export MK_MODELS=${MK_MODELS:-"cx/gpt-image-2 cx/gpt-image-1.5 cx/gpt-6-sol-image"}
good() { [ -s "$1" ] && python -c "
import sys, numpy as np
from PIL import Image
im = np.asarray(Image.open(sys.argv[1]).convert('RGB')) / 255.0
e = np.concatenate([im[:8].reshape(-1, 3), im[-8:].reshape(-1, 3), im[:, :8].reshape(-1, 3), im[:, -8:].reshape(-1, 3)])
sys.exit(0 if np.median(e) > 0.85 and (e.min(axis=1) > 0.7).mean() > 0.9 else 1)" "$1"; }
for n in bandit archer spear assassin brute monk poison shield boss1 boss2 boss3; do
  for try in 1 2 3; do
    if good gen/raw_a_$n.png; then echo "$n ok"; break; fi
    echo "$n try $try"
    tools/anim.sh a_$n
  done
done
echo ALL DONE
