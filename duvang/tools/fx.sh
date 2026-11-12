# Combat effect sprites: projectiles (pointing right), two flame frames, a hit spark. Needs DV_KEYS (never write keys
# to a file). Run: DV_KEYS="..." bash tools/fx.sh ; then: bash tools/fx.sh conv
cd /e/AI/game/duvang
GD="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7-stable_win64_console.exe"
if [ "${1:-}" = "conv" ]; then
  timeout 100 "$GD" --headless --path . --script res://tools/pix.gd -- "E:/AI/game/duvang/gen/raw_fx.png" 18 fx_fire,fx_ice,fx_dart,fx_arrow,fx_cog,fx_flame_a,fx_flame_b,fx_spark fit 2>&1 | grep -aE "ERROR|x[0-9]"
  exit 0
fi
ST="Style: pixel art effect sprites for a 2D action RPG, crisp hard-edged square pixels, dark 1-pixel outline, bold flat colours, no anti-aliasing, no text. Exactly EIGHT sprites in one row, all about the same size, wide empty gaps between them, on a flat solid pure magenta #FF00FF background. Use no pink, purple or magenta in the sprites themselves."
DV_MODELS="cx/gpt-image-2.5 cx/gpt-image-2.6-flare" bash tools/gen.sh fx "From left to right: (1) a fire bolt flying to the right, a bright orange-yellow ball with a short flame tail behind it on the left, (2) an ice shard flying to the right, a pale blue pointed crystal with a small frosty trail, (3) a poison dart flying to the right, a thin dark needle with a bright green glowing tip and green feather, (4) a wooden arrow flying to the right with an iron head and white feathers, (5) a small brass cog-shaped bullet flying to the right with an amber glow trail, (6) a tall flame tongue rising from the ground, orange with a yellow core, leaning left, (7) the same flame in another frame, leaning right and a bit shorter, (8) a hit spark: a white and yellow four-pointed starburst with small sparks." "$ST"
