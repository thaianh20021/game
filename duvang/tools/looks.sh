# Class look sheets: three views x six poses for each main mastery. Needs DV_KEYS (never write keys to a file).
# Run: DV_MODELS="cx/gpt-image-2.5 cx/gpt-image-2.6-flare" DV_KEYS="..." bash tools/looks.sh ; one sheet: bash tools/look1.sh k6 s
# Then convert each gen/raw_<k>_<s|d|u>.png with tools/pix.gd at height 38 into <k>_<h|hd|hu>_<idle,w1,w2,w3,wind,slash>.
cd /e/AI/game/duvang
ST="Style: cute chibi pixel art hero for a 2D action RPG, big head and small body (about 2 heads tall), crisp hard-edged square pixels, thick black 1-pixel outline, bold flat colours, no anti-aliasing, no text, no ground shadow. Wide landscape image, all six figures the same size and the same character, wide empty gaps between them, on a flat solid pure magenta #FF00FF background."
gen3() {
  local id=$1; local who=$2; local strike=$3
  bash tools/gen.sh ${id}_s "Exactly SIX poses in one row of the same character seen from the SIDE, facing right: (1) standing idle, (2) (3) (4) three walking steps, (5) winding up to attack, (6) $strike. The character: $who" "$ST"
  bash tools/gen.sh ${id}_d "Exactly SIX poses in one row of the same character seen from the FRONT, facing the viewer: (1) standing idle, (2) (3) (4) three walking steps, (5) winding up to attack, (6) $strike. The character: $who" "$ST"
  bash tools/gen.sh ${id}_u "Exactly SIX poses in one row of the same character seen from BEHIND, back to the viewer: (1) standing idle, (2) (3) (4) three walking steps, (5) winding up to attack, (6) $strike. The character: $who" "$ST"
}
gen3 k1 "a young man with short messy brown hair and teal eyes, an elementalist in a robe of deep teal with orange trim and the pointed hood always pulled up over his head, a short staff topped with a crystal glowing orange, pale blue and violet." "thrusting the staff forward with a burst of light"
gen3 k3 "a lean assassin in a dark purple hood and mask, a short cape, a curved dagger in each hand." "slashing with both daggers"
gen3 k6 "a soul warlock in a long pale grey robe with the hood up, the face hidden in deep shadow under the hood so only two glowing teal eyes show, a scythe with a pale teal glowing blade, small teal soul wisps around." "sweeping the scythe"
gen3 k10 "a stocky guardian in heavy bronze plate armour and a closed helmet, a big round bronze shield and a short sword, no plume or crest on the helmet." "bashing forward with the shield"
gen3 k15 "a ranger in a green hooded cloak and leather armour, a short bow, a quiver on the back." "loosing an arrow from the bow"
gen3 k21 "a gentle priest in white and gold robes with a soft golden halo, holding a wooden temple fish drum and a mallet." "striking the drum, a ring of golden light"
gen3 k28 "a young artificer with brass goggles on the forehead, a leather apron, a small brass backpack with pipes, holding a big wrench." "swinging the wrench, a puff of steam"
echo BATCH_DONE
