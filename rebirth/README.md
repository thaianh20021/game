| `src/lobby.gd` | The Hearth: stations, menus, secrets |
| `src/hub.gd` | South wing: bounties, trophies, quartermaster, cook, tailor, capsule machine, boons || `src/net.gd` | LAN co-op: host/join, discovery, snapshots |
| `src/pad.gd` | Gamepad input and local player two |
| `src/touch.gd` | Touch sticks and buttons |
| `src/pets.gd` | Pet skills, hearts, exclusive passives, the pet bowl |
| `src/combo.gd` | Element fields left by reactions, three-element storms, cataclysm |
| `src/forge.gd` | Word Forge: command parsing (EN/VI/pad) and forged weapons |
| `src/reso.gd` | Elemental resonance: stacks, the four bursts, attunement |
| `src/arms.gd` | Fusion traits; homing and returning projectiles |
| `src/foes.gd` | Charged specials of ordinary foes; third boss of each biome |
| `src/fx.gd` | Visual effects: element trails, hits, statuses, reactions, boss auras, fused gear |
| `src/traps.gd` | Floor traps: placement, timing, drawing |
| `src/more.gd` | Synergies, relics, active items, secret rooms |
| `src/talk.gd` | NPC dialogue rules |
| `src/sfx.gd` || R | Elemental Burst (when the bar is full) |
| C | Active item || `src/meta.gd` | Save file, skill tree effects and generator, hero generator, enemy learning |
| `src/talk.gd` | NPC dialogue rules |# Dungeon Core: Elemental Rebirth (remake)

Top-down roguelike shooter: two-weapon gunplay plus an elemental reaction system.
Godot 4.7, GL Compatibility renderer. No art or audio files: every sprite, tile, sound
and music loop is generated from code at boot.

## Run

Open this `rebirth` folder in Godot 4.7 and press F5, or:

    godot --path rebirth

## Controls

| Input | Action |
|---|---|
| WASD / arrows | Move |
| Mouse | Aim |
| Left click (hold) | Fire |
| Right click / Shift | Skill one |
| F | Skill two |
| R | Elemental Burst (when the bar is full) |
| Space | Dash (invulnerable) |
| Q | Swap weapon |
| E | Talk, open, pick up, buy, enter |
| Esc | Pause (reaction cheat sheet, foe cunning). O in pause: settings |

## Gamepad

| Pad | Action |
|---|---|
| Left stick | Move |
| Right stick | Aim (fires when pushed far). Idle: auto-aims at the nearest foe |
| RT | Fire |
| A or LT | Dash |
| LB / RB | Skill one / skill two |
| R3 or d-pad up | Elemental Burst |
| B | Active item |
| Y | Swap weapon |
| X | Interact |
| START | Pause. In menus: A confirm, B back, d-pad or stick to move |

Touch screens get two virtual sticks and buttons (auto-aim while the fire stick is held near its centre).

## Co-op (two players)

Use the Link Stone in the Hearth.

- Same screen: press F2 in the Hearth (or START on a second gamepad, or use the Link Stone).
  Without a second gamepad, player 2 plays on the keyboard: arrows move, aim is automatic,
  L fire, K dash, I and O skills, P burst, U item, J interact, H swap (numpad 0, Enter, 1-6 also work). With one gamepad, "A single gamepad plays: player 2" lets keyboard+mouse be
  player 1 and the pad be player 2. Player 2 picks a hero and element by walking up to them.
- LAN: one player chooses "Host a LAN game"; the other sees the game listed under the Link Stone
  (or types the host's address) and joins. The host starts the run. UDP/TCP port 24242, discovery
  on UDP 24243; both devices must be on the same network.
- A hero at 0 health goes down. Stand next to them for 2.5 seconds to revive them; they also get
  back up when the room is cleared or the next floor starts. The run ends when both are down. On one screen each player picks a blessing in turn (shared over LAN); gold, weapons, relics
  and keys belong to whoever picks them up.
- The host simulates everything and sends 20 snapshots a second; the guest predicts only its own walking.

## Android

`export_presets.cfg` has an Android preset (arm64, landscape, network permissions). Building an APK
needs the Android SDK set in Godot's Editor Settings; then: `godot --headless --path rebirth --export-debug Android build/dungeon-core.apk`.

## The Hearth (lobby)

Every station has a name plate and each area a coloured rug (heroes, starting element, garden,
daily, supplies, craft). Arrows on the floor point to the shops in the south wing.

Every run starts and ends here. Gems earned in runs are spent here and are kept forever.

- Walk up to another hero and press E to play as them. Touch a crystal to pick your starting element.
- 8 heroes. Mentor: a 9-node skill tree per hero (Power / Flow / Element); newer heroes, fusions and woven heroes each get a different tree.
- Armorer: 5 permanent hero ranks.
- Keeper: 4 pets (one per element) and 2 mounts.
- Soul Altar: fuse your hero with another one: best stats of both, their main skill as your second
  skill, and a skill tree rolled for that exact pairing.
- Soul Loom: weaves a brand-new hero from a random seed (first one free, then 40 gems): sprite,
  archetype, stats, starting weapon, two skills and its own skill tree. Rule-based, no AI model.
- NPCs talk before opening their menu; lines depend on your gems, runs and current hero.
- South wing (walk down from the hall):
  - Bounty Board: three daily tasks for gems. Trophy Case: lifetime achievements.
  - Quartermaster: pack a weapon you have found before as your second weapon for the next run.
  - Cook: one-run meals (health, armor, gold, key, item). Tailor: dyes that recolour your heroes.
  - Capsule Machine: 12 gems for a random prize. Mailbox: a daily gift with a streak bonus.
  - Whatever is queued for the next run is listed bottom-left in the Hearth.
- Secrets: a cat, a jukebox, a wishing fountain, an old grave, a training dummy, a hollow wall
  and a code on the arrow keys.

## Saving and settings

- A solo run is saved at the start of every floor after the first. Close the game and pick
  "Continue saved run" at the Run Board later. Dying, winning or starting a new run erases it.
- Settings (O on the pause screen): music and sound volume, fullscreen, screen shake.
- First-time hints explain weapon swapping, reactions, the Burst bar and armor.

## In the dungeon

- Carry 2 weapons, each with an element (fire, ice, storm, venom). Two different elements on one foe
  trigger a reaction: Melt, Blast, Overload, Shatter, Blight, Plague. Reactions charge the Burst bar.
- Word Forge (the altar in workshop rooms, 30 gold): melts both carried weapons into one stronger,
  partly random weapon steered by a command. Type what you want in English or Vietnamese, with or
  without accents ("fast fire bow", "cung lửa nhanh", "kiem bang manh"), or press pad buttons
  (d-pad up/right/down/left = fire/storm/ice/venom, A many, B blast, X pierce, Y seek, RB fast,
  R3 strong, LB undo, START forge, BACK cancel). Words pick element, shape and up to two traits;
  anything not mentioned is rolled. The result gets +30-60% damage, +1 level, a trait inherited
  from a parent and its own name. Keyword matching only, no AI model (`src/forge.gd`).
- You start every run with two weapons of different elements; Q (Y on a pad) swaps. The other
  weapon is carried on your back.
- Difficulty is bullet-hell leaning: bigger waves, shooters fire three-shot fans, rings and fans are
  denser, bosses rest less. A white dot on the hero marks the only spot enemy bullets can hit.
- Combinations you can see: every reaction leaves a field on the ground for 5 seconds, labelled with
  its name and the elements that made it: Steam (fire + ice, swallows enemy bullets), Wildfire
  (fire + venom), Plasma (storm + fire, stuns), Hail (storm + ice), Rot (ice + venom, +50% damage
  taken), Miasma (storm + venom). Hit a foe inside a field, or blast the field, with a third
  element and it becomes a storm covering a large area for 6 seconds: Thunderstorm (fire + ice +
  storm), Acid Rain (fire + ice + venom), Firestorm (fire + storm + venom), Blizzard (ice + storm
  + venom, also swallows bullets). The fourth element on a storm ends it in a Cataclysm: a huge
  blast that clears every enemy bullet. Pets, barrels, traps and skills all count as sources.
- Resonance (for single-element builds): every direct hit of the same element on one foe adds a stack,
  shown as motes circling it. At 5 stacks (4 if the party carries that element twice, +2 on bosses) the
  element erupts: Eruption (fire: blast and burning ground), Glacier (ice: freezes the target and chills
  neighbours), Thunderstrike (storm: strike that chains to 5 foes and stuns), Bloom (venom: cloud that
  maxes poison). Stacks fade after 4 seconds; a different element or a reaction resets them. Pools and
  burns do not add stacks.
- Fire and ice counter each other, storm and venom counter each other (+50% damage).
- Shooting an element pool with a different element detonates it.
- Workshop rooms: upgrade a weapon (+1 to +5), change its element, or fuse both weapons into one
  dual-element weapon that sets off reactions by itself.
- Hard ground in fight rooms: mire slows anything on foot (heroes and foes) to about half speed;
  pits cost a hero one point and put them back where they last stood. Dashing crosses both safely.
  Foes on foot must walk around pits, flyers ignore them, bullets fly over. The rim of a room and
  the cross through its centre are always clear, so doors are never cut off.
- Crafting: blueprints for six weapons that never drop as loot are found in secret rooms (always),
  after bosses (40%) and elite rooms (30%), and are kept forever. Foes drop scrap (kept between runs).
  The Workbench in the Hearth's south wing spends 15 scrap to pack a blueprint weapon for the next
  run; the bench in a workshop room builds a random known one on the spot for 50 gold.
- Materials: foes sometimes leave ore (ground foes), fiber (flyers) or essence (elemental foes);
  reward chests always hold one or two; elites and bosses leave more. Blueprint weapons at the hub
  Workbench now cost 15 scrap plus a recipe of materials.
- Seeds: chests (25%), foes (rarely) and every boss leave a seed. A found seed is planted for free;
  seeds can still be bought with gems. The garden has five plots (three in the hall, two in the
  south wing) and three new plants: Pet Berry (2 treats), Gleam Moss (4 essence), Iron Flax (3 ore, 3 fiber).
- Pets cast their own skill when a foe is near (9 second cooldown): Flame Pounce, Frost Gust,
  Overcharge, Spore Belch. Feed treats at the pet bowl by the Keeper to earn hearts: each heart
  cuts the cooldown by 10%, and at 3 hearts the pet unlocks its exclusive passive (pup: shots
  explode; owl: blocks one hit per room; mote: kills restore energy; toad: venom cloud when you are hurt).
- Traps: floor spikes everywhere, plus one trap per biome: spore vents (venom cloud) in the Ancient
  Cave, flame jets in the Ember Forge, storm runes (triggered by stepping close) in the Crystal
  Archive. Traps also hurt foes and apply their element, so luring foes in can start a reaction.
  Flying foes ignore spikes; dashing through a trap is safe.
- Charged attacks: any foe may stop, gather power for a second (closing ring and "!!") and release a
  move outside its usual routine: slimes leap, shooters fire a double volley, chargers quake, and so on.
  Elites do it twice as often.
- Nine bosses, three per biome, picked per floor. At half health a boss enrages.
- Health is scarce on purpose. Foes drop energy and gold, never hearts. Hearts come from smashing
  crates (about 1 in 7; a few crates hide an ambush instead), from the single potion each shop sells
  (heals 2), and one heart after a boss. Armor still regenerates.
- Shrines trade 1 max health for a blessing. Shops sell weapons, potions and tomes.
- Talk to the peddler, smith and alchemist: they comment on your gold, health and elements, and the
  peddler tells you the weakness of the boss ahead.
- Fight rooms can be elite, dark, frenzied or element-surged. Layouts, room shapes and the boss of
  each biome (three candidates each, nine in total) are rolled per floor.
- Pick a blessing after every floor.

## Foes that learn

Saved between runs in the same file as your progress:

- Shooters track whether aiming straight or leading the target hits you more, and favour what works.
- Bosses weight each attack by how much damage it has dealt to you before.
- "Cunning" rises when you clear rooms untouched and drops when you struggle. It raises spawn budgets,
  shortens boss rests, and makes more foes dodge shots and punish dashes.

## Animation

All frames are generated from each base sprite at boot (`Art.pose_frames`, `Art.walk_frames`).

- Heroes: walk cycle with a body bob and dust under the feet, idle breathing, a forward lean when
  firing, swinging or casting, and a stretch along the dash.
- Foes and bosses: rise out of the ground when spawned, crouch and tremble while winding up or
  charging, lean into the attack when they fire, squash when struck, and flatten and fade when
  they die. Bosses leave afterimages while dashing and squash on landing.
- Dungeon floors carry four kinds of small set dressing per biome and banners on the walls.

## Layout

| File | What |
|---|---|
| `src/game.gd` | Simulation, combat, enemies, first boss set, world drawing, lighting |
| `src/ext.gd` | Skills, pets, mounts, burst, workshop, second boss set |
| `src/lobby.gd` | The Hearth: stations, menus, secrets |
| `src/meta.gd` | Save file, skill tree and shop data, enemy learning |
| `src/hud.gd` | Title, HUD, minimap, menus |
| `src/art.gd` | All sprites as character maps + tile generators |
| `src/data.gd` | Weapons, heroes, skills, enemies, biomes, blessings (tune here) |
| `src/dungeon.gd` | Floor layout, lobby layout, baking |
| `src/sfx.gd` | Synthesized sound effects and music |
| `src/font.gd` | 5x7 pixel font |

## Tests

    godot --headless --fixed-fps 30 --path rebirth --script res://tests/smoke.gd

Tours the lobby (buys everything, finds the secrets), then plays a full 6-floor run with each hero
using a bot in god mode. Uses its own save file. `tests/anim.gd` checks pose frames and animation states; `tests/combo.gd` checks fields, storms and the cataclysm; `tests/forge.gd` checks the Word Forge and starting loadout; `tests/pets.gd` checks materials, seeds, garden, recipes and pets; `tests/terrain.gd` checks mire, pits, blueprints and crafting; `tests/arms.gd` checks new weapons, fusion traits, the newest heroes and resonance; `tests/drops.gd` checks the drop and shop rules; `tests/foes.gd` checks charged specials, the newest bosses and weapon sprites; `tests/traps.gd` checks traps in every biome; `tests/resume.gd` checks settings, hints and continuing a saved run; `tests/coop.gd` plays local two-player co-op; `tests/net_host.gd` + `tests/net_client.gd` (run as two
processes, host first) check a LAN session; `tests/touch.gd` and `tests/pad.gd` drive touch and pad input.
