#!/usr/bin/env bash
# Cuts the sheets from tools/more.sh: the hero's twelve transition frames and four reaction frames per foe.
# The first reaction frame (the flinch) is scaled to the foe's height; the others keep that scale.
N() { local o=""; for i in $(seq $2 $3); do o="$o,$1_$i"; done; echo "${o:1}"; }
if [ -s gen/raw_h2_trans.png ] && { [ $# -eq 0 ] || [[ " $* " == *" hero "* ]]; }; then
  python tools/cut.py gen/raw_h2_trans.png "$(N hero_trans 0 11)" 250 anim scale=0.76 > /dev/null && echo "hero cut" || echo "hero FAILED"
fi
for pair in bandit:240 archer:240 spear:262 assassin:230 brute:315 monk:262 poison:284 shield:216 boss1:385 boss2:355 boss3:375; do
  n=${pair%%:*}; h=${pair##*:}
  [ -s gen/raw_r_$n.png ] || continue
  [ $# -gt 0 ] && [[ " $* " != *" $n "* ]] && continue
  python tools/cut.py gen/raw_r_$n.png "$(N ${n}_react 0 3)" $h anim ref=0:$h > /dev/null && echo "$n cut" || echo "$n FAILED"
done
