# one sheet of a look: bash tools/look1.sh <k> <s|d|u> ; keys from DV_KEYS
cd /e/AI/game/duvang
ST=$(grep '^ST=' tools/looks.sh | sed 's/^ST="//; s/"$//')
k=$1; v=$2
who=$(grep "^gen3 $k " tools/looks.sh | sed "s/^gen3 $k \"//; s/\" \".*//")
strike=$(grep "^gen3 $k " tools/looks.sh | sed 's/.*" "//; s/"$//')
case $v in
  s) view="seen from the SIDE, facing right" ;;
  d) view="seen from the FRONT, facing the viewer" ;;
  u) view="seen from BEHIND, back to the viewer" ;;
esac
DV_MODELS="cx/gpt-image-2.5 cx/gpt-image-2.6-flare" bash tools/gen.sh ${k}_$v "Exactly SIX poses in one row of the same character $view: (1) standing idle, (2) (3) (4) three walking steps, (5) winding up to attack, (6) $strike. The character: $who" "$ST" 2>&1 | grep -aE " 200 | FAILED" | cut -c1-60
