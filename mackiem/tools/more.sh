#!/usr/bin/env bash
# Extra whole-body frames: the hero's transitions between actions, and a hit / stagger / fall / lie set for every foe.
# Usage: MK_KEYS="key" tools/more.sh [hero bandit archer ...]   -> gen/raw_h2_trans.png, gen/raw_r_<foe>.png
export MK_MODELS=${MK_MODELS:-"cx/gpt-image-2 cx/gpt-6-sol-image cx/gpt-image-1.5"}
S="Style: traditional Chinese ink wash painting (sumi-e) 2D game animation sprite sheet, bold expressive black brush outlines, muted desaturated colours with one vermilion accent, cloth shaded in 3 to 4 tones. Every frame shows the SAME character with identical face, costume, colours, proportions and size, full body, side-on three-quarter view facing RIGHT, strong line of action. Frames laid out in an even grid with wide gaps, never touching or overlapping. The whole sheet has a perfectly plain flat pure white #FFFFFF background, evenly lit like a scanned model sheet, every figure closed by a continuous black outline, no ground, no shadow, no glow, no vignette, no text, no numbers, no frame borders, no speed lines, no blood."
HERO="a lean wandering swordsman about thirty with a short dark beard and long black hair tied back: wide conical woven bamboo hat, tattered dark indigo knee-length robe with a grey sash, loose charcoal-grey trousers, black cloth boots, a long vermilion red scarf, a straight double-edged jian sword with a plain dark hilt in the right hand"
want() { [ ${#ARGS[@]} -eq 0 ] && return 0; for n in "${ARGS[@]}"; do [ "$n" = "$1" ] && return 0; done; return 1; }
ARGS=("$@")
one() {
  for try in 1 2 3 4 5; do
    if [ -s gen/raw_$1.png ] && python tools/white.py gen/raw_$1.png; then echo "$1 ok"; return; fi
    [ $try = 5 ] && { echo "$1 still bad"; return; }
    echo "$1 try $try"; tools/gen.sh "$1" "$2" "$S"; sleep 2
  done
}
want hero && one h2_trans "SPRITE SHEET of $HERO. Twelve TRANSITION frames in three rows of four. Row 1: 1 starting to run, weight shifting forward from a standing pose with the first step lifting, 2 first push-off leaning forward, 3 stopping from a run, front foot planted and body leaning back to brake, 4 settling from the stop back to standing. Row 2: 5 turning around, body half turned toward the viewer mid-turn, 6 three-quarter back view finishing the turn, 7 recovering after a sword slash, arm coming back in with the sword lowering, 8 returning to the relaxed stance with the sword low. Row 3: 9 landing out of a dash, knees bent deep and one hand near the ground, 10 rising from the landing, 11 recovering from being hit, straightening up and shaking it off, 12 regaining the guard with the sword raised."
foe() {
  want $1 || return
  one r_$1 "SPRITE SHEET of $2. Four frames in one row, a hit reaction set: 1 HIT, flinching backward with the head snapped back and arms thrown out, 2 STAGGERED and dazed, bent over off balance with the weapon drooping, 3 FALLING backward in mid-fall, feet leaving the ground, 4 DEFEATED lying flat on the ground on his back with the weapon dropped beside him."
}
foe bandit "a scruffy mountain bandit with a topknot, patched brown vest and a curved saber"
foe archer "a masked archer in a green tunic with a quiver and a recurve bow"
foe spear "a soldier in blue lamellar armour and iron helmet with a long red-tasselled spear"
foe assassin "a hooded assassin all in black with a face mask and twin daggers"
foe brute "a huge bare-chested bearded brute with a great iron hammer"
foe monk "a fallen monk in torn grey robes and a conical straw hat with an iron staff"
foe poison "a poison mistress in a dark green robe with red sash holding a paper umbrella"
foe shield "an armoured soldier with a big round rattan shield and a short blade"
foe boss1 "a towering bandit king with a tiger pelt over his shoulders and a huge nine-ring broadsword"
foe boss2 "a blind old abbot in ochre robes with giant prayer beads and a bronze hand bell"
foe boss3 "a white-haired sword saint in flowing white robes with a long thin sword"
echo MORE DONE
