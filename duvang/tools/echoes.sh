# Sprites for things to look at that had none: four echoes of the Debts of the Dead, the lighthouse keeper and the
# guild ledger. Needs DV_KEYS (never write keys to a file). Run: DV_KEYS="..." bash tools/echoes.sh ; then: bash tools/echoes.sh conv
cd /e/AI/game/duvang
GD="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7-stable_win64_console.exe"
if [ "${1:-}" = "conv" ]; then
  timeout 100 "$GD" --headless --path . --script res://tools/pix.gd -- "E:/AI/game/duvang/gen/raw_echoes.png" 32 th_potter,th_mother,th_ferry,th_diver,th_keeper,th_ledger 2>&1 | grep -aE "ERROR|x[0-9]"
  exit 0
fi
ST="Style: cute chibi pixel art for a 2D action RPG (big heads, small bodies), crisp hard-edged square pixels, thick black 1-pixel outline, bold flat colours, no anti-aliasing, no text, no ground shadow. Wide landscape image, all six the same scale, wide empty gaps between them, on a flat solid pure magenta #FF00FF background."
DV_MODELS="cx/gpt-image-2.5 cx/gpt-image-2.6-flare" bash tools/gen.sh echoes "Exactly SIX separate figures in one row, seen from the front and a little to the side. The first four are ghostly echoes of dead villagers drawn in pale washed-out blue-grey and soft teal: (1) a potter sitting on a stool beside a small cold clay kiln, shaping a cracked clay jar, (2) a thin mother kneeling on the ground counting copper coins out of a cloth pouch, (3) a ferryman kneeling and carving the half-built wooden hull of a small boat with an adze, (4) a pearl diver sitting and polishing an old brass diving helmet with his sleeve. Then in normal warm colours: (5) a very old lighthouse keeper with a long white beard sitting on a stool beside a lit oil lantern, holding a torn paper calendar, (6) a thick open ledger book on a small wooden lectern, a bronze ring tied with red thread lying on its pages." "$ST"
