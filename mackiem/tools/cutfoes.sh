#!/usr/bin/env bash
# Cuts every foe animation sheet that exists: four walk frames, the wind-up and the strike.
# The number is twice the foe's height in Data.cs (sprites are imported at 200 px per unit).
for pair in bandit:250 archer:250 spear:274 assassin:240 brute:330 monk:274 poison:296 shield:226 boss1:400 boss2:370 boss3:390; do
  n=${pair%%:*}; h=${pair##*:}
  [ -s gen/raw_a_$n.png ] || continue
  [ $# -gt 0 ] && [[ " $* " != *" $n "* ]] && continue
  python tools/cut.py gen/raw_a_$n.png ${n}_walk_0,${n}_walk_1,${n}_walk_2,${n}_walk_3,${n}_wind,${n}_hit $h med anim | tr '\n' ' '; echo
done
