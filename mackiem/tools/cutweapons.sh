#!/usr/bin/env bash
# Cuts the hero's per-weapon sheets (tools/weapons.sh) and the NPC idle sheet, when they exist.
N() { local o=""; for i in $(seq $2 $3); do o="$o,$1_$i"; done; echo "${o:1}"; }
for w in thuong dao chuy phien cung; do
  [ $# -gt 0 ] && [[ " $* " != *" $w "* ]] && continue
  if [ -s gen/raw_w_${w}_move.png ] && [ -s gen/raw_w_${w}_atk.png ]; then
    python tools/cut.py gen/raw_w_${w}_move.png "$(N hero_${w}_run 0 7),$(N hero_${w}_idle 0 3)" 250 anim ref=8,9,10,11:252 > /dev/null || echo "$w move FAILED"
    python tools/cut.py gen/raw_w_${w}_atk.png "$(N hero_${w}_atk 0 7),$(N hero_${w}_act 0 3)" 250 anim ref=8:250 > /dev/null || echo "$w atk FAILED"
    echo "$w cut"
  fi
done
if [ -s gen/raw_npc.png ] && { [ $# -eq 0 ] || [[ " $* " == *" npc "* ]]; }; then
  python tools/cut.py gen/raw_npc.png "$(N merchant_idle 0 3),$(N tea_idle 0 3),$(N hermit_idle 0 3)" 260 anim ref=0,1,2,3:262 > /dev/null && echo "npc cut" || echo "npc FAILED"
fi
