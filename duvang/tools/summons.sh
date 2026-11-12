# Sprites for things the later classes put on the field: the Soul Warlock's ghost, the Artificer's devices,
# the Hunter's traps. Needs DV_KEYS (never write keys to a file). GPT only, so they match the class looks.
# Run: DV_KEYS="k1 k2 k3" bash tools/summons.sh   (three sheets at once, one key each first)
# Then: bash tools/summons.sh conv
cd /e/AI/game/duvang
GD="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7-stable_win64_console.exe"
G=E:/AI/game/duvang/gen
ST="Style: cute chibi pixel art for a 2D action RPG, crisp hard-edged square pixels, thick black 1-pixel outline, bold flat colours, no anti-aliasing, no text, no ground shadow. Wide landscape image, wide empty gaps between the figures, on a flat solid pure magenta #FF00FF background."
if [ "${1:-}" = "conv" ]; then
  timeout 100 "$GD" --headless --path . --script res://tools/pix.gd -- "$G/raw_sum_ghost.png" 30 ghost_i,ghost_w,ghost_k 2>&1 | grep -aE "ERROR|x[0-9]"
  timeout 100 "$GD" --headless --path . --script res://tools/pix.gd -- "$G/raw_sum_dev.png" 24 dev_turret,dev_drum,dev_bell fit 2>&1 | grep -aE "ERROR|x[0-9]"
  timeout 100 "$GD" --headless --path . --script res://tools/pix.gd -- "$G/raw_sum_trap.png" 14 dev_mine,trap_snare,trap_pot fit 2>&1 | grep -aE "ERROR|x[0-9]"
  exit 0
fi
set -- $DV_KEYS
k1=$1; k2=${2:-$1}; k3=${3:-$1}
export DV_MODELS="cx/gpt-image-2.5 cx/gpt-image-2.6-flare"
DV_KEYS="$k1 $k2" bash tools/gen.sh sum_ghost "Exactly THREE poses in one row of the same small floating ghost, seen from the side facing right: (1) hovering still, (2) drifting forward, (3) lunging to strike with its misty claws. The ghost: a small hooded phantom of pale teal glowing mist, a ragged hood with two bright white-teal eyes and no face, thin misty arms with little claws, no legs, its body tapering into a wispy curling tail." "$ST" &
DV_KEYS="$k2 $k3" bash tools/gen.sh sum_dev "Exactly THREE objects in one row, each about the same size, seen from the front and a little above: (1) a small brass clockwork crossbow turret on a short tripod with a gear on its side, (2) a small round wooden war drum on a brass stand with little gears and pipes, (3) a bronze bell hanging in a small dark wooden frame." "$ST" &
DV_KEYS="$k3 $k1" bash tools/gen.sh sum_trap "Exactly THREE small objects in one row, each about the same size, seen from a little above: (1) a flat round brass clockwork landmine with one glowing amber light in the middle, (2) a hunter's rope snare loop pinned to the ground by three wooden stakes, (3) a round clay pot bomb with a short lit fuse." "$ST" &
wait
