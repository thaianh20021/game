# Item icons for the four slots added on 2026-11-12 (helm, gloves, boots, ring): six bases each, in the order of
# D.BASES. Needs DV_KEYS (never write keys to a file). Run: DV_KEYS="..." bash tools/gear_icons.sh ; then: bash tools/gear_icons.sh conv
cd /e/AI/game/duvang
GD="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7-stable_win64_console.exe"
if [ "${1:-}" = "conv" ]; then
  timeout 100 "$GD" --headless --path . --script res://tools/pix.gd -- "E:/AI/game/duvang/gen/raw_gear_a.png" 22 it_h0,it_h1,it_h2,it_h3,it_h4,it_h5,it_g0,it_g1,it_g2,it_g3,it_g4,it_g5 fit 2>&1 | grep -aE "ERROR"
  timeout 100 "$GD" --headless --path . --script res://tools/pix.gd -- "E:/AI/game/duvang/gen/raw_gear_b.png" 22 it_b0,it_b1,it_b2,it_b3,it_b4,it_b5,it_r0,it_r1,it_r2,it_r3,it_r4,it_r5 fit 2>&1 | grep -aE "ERROR"
  exit 0
fi
ST="Style: pixel art inventory icons for a 2D RPG, each a single object seen at a slight angle, crisp hard-edged square pixels, thick black 1-pixel outline, bold flat colours, no anti-aliasing, no text, no frames or boxes around them. Exactly TWO rows of SIX icons, all the same size, wide empty gaps between them, on a flat solid pure magenta #FF00FF background."
set -- $DV_KEYS
export DV_MODELS="cx/gpt-image-2.5 cx/gpt-image-2.6-flare"
DV_KEYS="$1 ${2:-$1}" bash tools/gen.sh gear_a "Top row, six head pieces from left to right: (1) a conical woven palm-leaf hat, (2) a dark cloth head wrap, (3) a helmet woven from dry reeds, (4) a plain dented iron helmet, (5) a bronze helmet shaped like a small bell, (6) a stern bronze toll-collector's half mask. Bottom row, six hand pieces from left to right: (7) plain cloth hand wraps, (8) fishing gloves with a little hook, (9) fish-skin leather gloves, (10) padded rowing gloves, (11) bronze gauntlets, (12) heavy blacksmith gloves with brass studs." "$ST" &
DV_KEYS="${2:-$1} ${3:-$1}" bash tools/gen.sh gear_b "Top row, six foot pieces from left to right: (1) woven rush sandals, (2) cloth leg wraps, (3) tall wading boots, (4) sturdy dock shoes, (5) bronze-plated boots, (6) light shoes with a white wave pattern. Bottom row, six rings from left to right: (7) a ring of knotted cord, (8) a ring carved from fish bone, (9) a plain copper ring, (10) a small wooden ring with a tiny clapper bell, (11) a silver ring crusted with sea salt crystals, (12) a bronze ring tied with red thread." "$ST" &
wait
