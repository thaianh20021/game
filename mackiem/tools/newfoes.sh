#!/usr/bin/env bash
# Sheets for the foes designed with Gemini (walk/wind-up/strike and hit/stagger/fall/lie) and the chapter IV scenery,
# drawn by Gemini's image model on magenta. Usage: MK_KEYS="key" tools/newfoes.sh
export MK_MODELS=${MK_MODELS:-"ag/gemini-3.1-flash-image cx/gpt-image-2"}
S="Style: traditional Chinese ink wash painting (sumi-e) 2D game animation sprite sheet, bold expressive black brush outlines, muted desaturated colours with one vermilion accent, 3 to 4 tones of shading. Every frame shows the SAME character with identical face, costume, colours, proportions and size, full body, side-on three-quarter view facing RIGHT. Frames in one row with wide gaps, never touching. Flat solid pure magenta #FF00FF background everywhere, no ground, no shadow, no text, no frame borders."
one() { [ -s gen/raw_$1.png ] && { echo "$1 have"; return; }; tools/gen.sh "$1" "$2 $S" ""; sleep 1; }
foe() {
  one a_$1 "ANIMATION FRAMES of $2. Six frames in one row: 1 walk right leg forward, 2 walk passing pose, 3 walk left leg forward, 4 walk passing pose other arm forward, 5 attack wind-up: $3, 6 attack strike: $4."
  one r_$1 "ANIMATION FRAMES of $2. Four frames in one row: 1 HIT flinching backward with the head snapped back, 2 STAGGERED dazed and bent over off balance, 3 FALLING backward in mid-fall, 4 DEFEATED lying flat on the ground on the back with the weapon beside."
}
foe lantern "a gaunt temple monk in tattered grey robes and straw sandals, hunched, holding a long iron polearm with a swinging bronze oil lantern" "lantern pole raised high overhead" "lantern swung down in front spilling burning oil"
foe bellguard "a broad-shouldered temple guardian in cracked bronze lamellar armour and iron greaves, gripping a heavy cracked bronze temple bell and a short iron mallet" "mallet raised to strike the bell" "striking the bell with a shockwave burst"
foe frostsword "a lean swordsman in a ragged frost-rimmed indigo cloak and fur-wrapped boots, holding a slender pale steel sword coated in rime ice" "sword drawn back low, crouched to lunge" "long lunging thrust with the icy sword"
foe cloudtao "a tall white-bearded hermit in layered snow-stained hemp robes and wooden clogs, raising a gnarled pine staff tied with blank talisman strips" "staff raised with both hands, robes lifting" "staff thrust forward releasing a gust"
foe inkwraith "a dripping silhouette of living black ink wearing torn scholar sleeves, barefoot, clutching jagged brush-stroke daggers in both hands" "crouched low with daggers crossed" "leaping slash with both daggers"
foe scrollguard "a towering armoured figure made of folded blank parchment and black ink plates, bearing a huge unrolled scroll as a shield and an ink halberd" "halberd raised behind the scroll shield" "halberd smashing down in front"
tools/gen.sh bg4 "Top-down orthographic view of a game boss arena seen from directly above: a wide EMPTY floor of pale blank rice paper filling the middle 80 percent, with faint drifting ink wisps, ringed at the edges by giant unrolled scrolls, brush strokes rising like mountains and pools of black ink. Traditional Chinese ink wash painting, almost monochrome with one vermilion seal. No text, no characters, no UI." ""
tools/gen.sh g4 "Seamless tileable ground texture seen from directly above for a 2D top-down game: pale blank rice paper with faint fibres, scattered thin ink speckles and very light grey washes, flat even lighting over the whole image, uniform density, no objects, no characters, no text, no border, fills the entire frame edge to edge." ""
echo NEWFOES DONE
