#!/usr/bin/env bash
# Animation sheets (several frames of one character per sheet). Usage: MK_KEYS="key" tools/anim.sh [name ...]
# MK_BG=white asks for a white sheet (the GPT image models ignore a magenta one); cut.py handles both
if [ "${MK_BG:-magenta}" = white ]; then BGTXT="The whole sheet has a perfectly plain flat pure white #FFFFFF background, evenly lit like a scanned model sheet, every figure closed by a continuous black outline"; else BGTXT="Flat solid pure magenta #FF00FF background"; fi
S="Style: traditional Chinese ink wash painting (sumi-e) 2D game animation sprite sheet, bold expressive black brush outlines, muted desaturated colours with a single vermilion red accent, rich detail, layered clothing with 3 to 4 shades."
F="Every frame shows the SAME character with identical costume, proportions and size, full body, side-on three-quarter view facing RIGHT, dynamic exaggerated poses with strong line of action, flowing cloth and hair showing motion. Frames evenly spaced in a grid with wide gaps, never touching. $BGTXT, no ground, no shadow, no glow, no vignette, no text, no numbers, no frame borders, no motion lines."
H="a wandering swordsman: wide conical bamboo hat, tattered dark indigo robe over grey trousers, black boots, long vermilion scarf, straight jian sword"
want() { [ ${#ARGS[@]} -eq 0 ] && return 0; for n in "${ARGS[@]}"; do [ "$n" = "$1" ] && return 0; done; return 1; }
g() { if want "$1"; then tools/gen.sh "$1" "$2" "$S $F"; sleep 2; fi; }
ARGS=("$@")
g a_hero_run "RUN CYCLE of $H, eight frames in two rows of four, sprinting to the right leaning forward with the sword held back low in the right hand and scarf streaming behind: 1 right foot strikes ground far ahead, 2 body sinks over right leg, 3 left knee drives forward passing, 4 airborne push-off both feet off ground, 5 left foot strikes ground far ahead, 6 body sinks over left leg, 7 right knee drives forward passing, 8 airborne push-off."
g a_hero_atk "SWORD COMBO of $H, six frames in two rows of three: 1 wind-up crouched with sword pulled back at the left hip, 2 fast horizontal slash mid-swing body twisting, 3 follow-through sword arm fully extended to the right, 4 wind-up with sword raised high over the shoulder, 5 downward diagonal slash stepping forward, 6 deep low lunge thrust with sword stretched far forward."
g a_hero_misc "ACTION POSES of $H, six frames in two rows of three: 1 idle standing relaxed with sword lowered, 2 idle same stance breathing in with shoulders slightly raised, 3 guard stance with sword held upright in front of the body blocking, 4 hit recoil staggering backwards with head thrown back, 5 low crouched forward dash body almost horizontal with scarf trailing, 6 spinning slash with robe whirling around."
foe() { g "a_$1" "ANIMATION FRAMES of $2, six frames in two rows of three: 1 walk with right leg forward, 2 walk passing pose legs together, 3 walk with left leg forward, 4 walk passing pose other arm forward, 5 attack wind-up: $3, 6 attack strike: $4."; }
foe bandit "a scruffy mountain bandit with a topknot, patched brown vest and a curved saber" "saber pulled far back over the shoulder, snarling" "wide horizontal saber slash, arm fully extended, lunging"
foe archer "a masked archer in a green tunic with a quiver and a recurve bow" "bow fully drawn aiming forward" "arrow just released, string arm flung back"
foe spear "a soldier in blue lamellar armour and iron helmet with a long red-tasselled spear" "spear pulled back with both hands, crouched" "long lunging spear thrust, body stretched forward"
foe assassin "a hooded assassin all in black with a face mask and twin daggers" "crouched low with both daggers crossed" "leaping stab with one dagger thrust forward"
foe brute "a huge bare-chested bearded brute with a great iron hammer" "hammer raised high overhead with both hands" "hammer smashed down to the ground in front, body bent"
foe monk "a fallen monk in torn grey robes and a conical straw hat with an iron staff" "staff swung back behind the body" "wide sweeping staff strike, robes whirling"
foe poison "a poison mistress in a dark green robe with red sash holding a paper umbrella" "arm drawn back holding small darts, umbrella tilted" "arm flung forward throwing darts"
foe shield "an armoured soldier crouching behind a big round rattan shield with a short blade" "blade drawn back behind the raised shield" "stabbing forward past the shield"
foe boss1 "a towering bandit king with a tiger pelt over his shoulders and a huge nine-ring broadsword" "broadsword raised overhead with both hands, roaring" "massive downward cleave, sword hitting forward"
foe boss2 "a blind old abbot in ochre robes with giant prayer beads and a bronze hand bell" "bell raised high, beads swinging" "palm strike thrust forward, robes billowing"
foe boss3 "a white-haired sword saint in flowing white robes with a long thin sword" "sword drawn back level at the cheek, poised" "lightning lunge thrust, robes and hair streaming behind"
