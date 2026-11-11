# Dungeon Core: Elemental Rebirth (remake)

Top-down roguelike shooter, bullet-hell leaning, built around an elemental reaction system.
Godot 4.7, GL Compatibility renderer. No art or audio files: every sprite, tile, sound
and music loop is generated from code at boot.

## What makes it different

You do not shoot foes down; you build weather, and you forge with words.

- Weapons are brushes. They deal modest damage and paint elements; fields and storms do the
  killing (a field out-damages a basic weapon roughly 2.5 to 1).
- The newer elements work on the room too: stone and earth fill pits (earth also firms up
  mire), water floods pits into mire and puts out fire pools, leaf overgrows mire into dry
  brush (which burns), wood lays planks across pits, metal cuts crates and cracked walls,
  gear jams traps for good, and X does what a random other element would.
- Three elements are not always a storm. Only the old four make the hand-made storms. Any
  other triple becomes an effect whose shape comes from the element that COMPLETES it, so
  the order you paint matters: fire eruption rings, ice spikes turning like a star, chain
  lightning, a venom cloud that hunts, meteors (stone), a wandering tornado (wind), two
  sweeping sunbeams (light), a singularity that drags everything in and bursts (void), tides
  rolling along your aim (water), brambles that root (leaf), fissures that quake (earth),
  orbiting blades that cut bullets (metal), a grove of thorn posts (wood), a battery of
  three sentries (gear); X picks one at random. It is named after the field it grew from
  and its form ("MAGMA TORNADO"). See `src/storm.gd`.
- Mana by element. There is no shared energy bar: each of the three carried elements has
  its own pool (a third of the hero's max mana). Painting drains the chosen pool (about
  seven seconds of steady fire), resting pools refill in fifteen. A reaction takes 15% from
  both pools, the element that completes a three-element effect pays 35%, weapons with a
  cost draw on the chosen pool, and everything that used to give energy fills the emptiest
  pool. An empty pool paints nothing until it is a third full. Numbers: `D.SAT`.
- Gathered casts. Keep the element key held (Tab, 1 2 3, the pad's B or d-pad, the touch
  element button) for 0.8 s and let go: one big cast of that element for 40% of its pool,
  shaped by the weapon in hand (a bursting orb, a ring around you for arcs, a lance for
  beams and chains, a drop where you point for lobbers). A short press only switches.
- Weapons are foci. A weapon decides the shape of the shot (the panel names it: bolt, fan,
  burst, lance, seeker, arc, beam, chain, lob); the element decides what it does. Every
  element hits the same through any weapon. The hero wears the chosen element as a ring
  underfoot and three orbiting motes.
- Pause menu (Esc, Start, the II button or the phone's Back): resume, settings, guide (the
  reaction sheet, your blessings and the controls), abandon run or quit to title, exit game.
  Rows that throw something away ask once more. Exiting a solo run keeps the save from the
  start of the floor.
- Difficulty dials in `D.DIFF`: 30% more foes a wave, 30% more health on foes and bosses,
  attack clocks 35% faster, more waves from the third floor on.
- Limits. At most three reaction fields lie on the floor and only one three-element effect
  exists at a time (a new one replaces the old). A foe that gets free of a stun, freeze or
  root cannot be held again for 1.5 s (a chevron shows over it). `D.FIELDS_MAX`, `D.CC_FREE`.
- Close weapons earn mana. Painting with an arc weapon drains its pool at half the rate, and
  every strike that lands gives 6% to both resting pools (up to three foes a swing). Shoot
  to spend, step in to earn it back.
- A first lesson. A new save starts beside the training dummy with ten steps done by doing
  (move, dash, paint, switch, react, storm, rotate, skill, burst, go). Backspace, the pad's
  Back button or a tap skips it; Settings in the Hearth replays it (`src/tutor.gd`).
- The room reacts. Ice freezes mire into firm ground and bridges pits. Fire burns crates and
  walks through dry brush tile by tile. Lightning runs through a whole patch of mire and shocks
  everything standing in it, you included. Venom eats through cracked walls.
- Enemy pools can be hijacked: hit one with a different element and it becomes your field
  (a fire pool hit with ice turns into steam that swallows bullets). Elemental foes leave a
  pool behind whenever they release a charged attack.
- Words are rewards. On the blessing screen you may type a wish instead of taking an offer
  ("health", "xuyen", "hoi sinh"). At the lectern in the Hearth you name skill one and shape it
  ("frost comet big", "bao lua manh"): an element word locks its element, big / fast / strong
  trade area, cooldown and damage. The Word Forge fuses weapons the same way.
- A nemesis that talks. Whatever kills you gets a name, comes back tougher in a later run,
  resists the element you used most and greets you with how you died ("last time your energy
  ran out"). Beat it and it yields: finish it for gems and a relic, or press E to spare it and
  it fights beside you in your next two boss battles. Die to it again and it gains a rank.
- Weather. Every floor after the first has a sky decided by the seed: rain (mire everywhere,
  lightning through mire hits harder, fire dies fast), drought (brush everywhere, fire runs),
  fog (short sight, steam lingers) or gale (lightning strikes the room on its own, foes
  included). The Run Board shows the forecast of the daily run.
- A notebook you write yourself. No reaction is listed anywhere until you make it happen; each
  discovery is written down, pays 3 gems, and can be renamed at the Archive. The game then uses
  your names for fields, storms and bursts.
- Puzzle rooms. Some side rooms have no foes, only a reward and a problem the room's chemistry
  solves: freeze a bridge over a chasm, let fire walk along brush to three braziers, send
  lightning through mire to a rod. A barrel of the needed element always stands in the room.
- Graves. Where a run ends, a grave stands on that floor in later runs: it seeps the element
  you used most and gives back the weapon you died holding.
- Fifteen elements. Fire, ice, storm and venom are the old four (foes, traps and barrels use
  only those). Heroes can also paint stone, wind, light, void, water, leaf, earth, metal,
  wood, gear and X. You carry three into a run (keys 1 2 3 pick which one your weapon
  paints); walk into a crystal in the Hearth to put its element in slot one. Every pair
  reacts and leaves a field (105 of them), every triple makes a storm (455). Only the old
  six reactions and four storms are hand-made; the rest are built in `src/chem.gd` from one
  behaviour per element: stone staggers and stops bullets, wind shoves, light exposes, void
  drags in and slows bullets, water washes foes and bullets outward, leaf is thorns, earth
  quakes under walkers, metal cuts and turns bullets back, wood roots, gear shoots shards
  at the next foe, X acts as a random other element each time.
- Skill training. The lectern in the Hearth trains both skills with gems, no typing: three
  levels each of power (+15% damage), reach (+12% area) and haste (8% quicker) for skill one,
  power and haste for skill two (15, 30, 50 gems a level, per hero). Skill one can be bound
  to one of the three carried elements. The same menu puts together one reaction spell from
  three choices: which pair sets it off, its shape (wall, vortex, wave, rain, orbit, lance)
  and its motion (push, pull, hold, burst). When that pair reacts on a foe the spell appears
  there, then rests for a few seconds.

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
| V | Combine: cast a written recipe from the elements near the aim point |
| Space | Dash (invulnerable) |
| Q | Swap weapon |
| E | Talk, open, pick up, buy, enter |
| Esc | Pause (reaction cheat sheet, foe cunning). O in pause: settings |

## Gamepad

On-screen prompts follow what player one is holding: plug a pad in (or press anything on it) and
every key name becomes that pad's button (Xbox letters, PlayStation shapes as words, Nintendo
letters by position); touch a key or the mouse and they switch back. See `Pad.hint` / `Pad.key_name`.

| Pad | Action |
|---|---|
| Left stick | Move |
| Right stick | Aim (fires when pushed far). Idle: auto-aims at the nearest foe |
| RT | Fire |
| A or LT | Dash |
| LB / RB | Skill one / skill two |
| R3 or d-pad up | Elemental Burst |
| Y | Swap weapon |
| X | Interact |
| START | Pause. In menus: A confirm, B back, d-pad or stick to move |

Touch screens get two virtual sticks and buttons (auto-aim while the fire stick is held near its centre).

## Co-op (two players)

Use the Link Stone in the Hearth.

- Same screen: press F2 in the Hearth (or START on a second gamepad, or use the Link Stone).
  Without a second gamepad, player 2 plays on the keyboard: arrows move, aim is automatic,
  L fire, K dash, I and O skills, P burst, J interact, H swap (numpad 0, Enter, 1-6 also work).
  With one gamepad, "A single gamepad plays: player 2" lets keyboard+mouse be
  player 1 and the pad be player 2. Player 2 picks a hero and element by walking up to them.
- LAN: one player chooses "Host a LAN game"; the other sees the game listed under the Link Stone
  (or types the host's address) and joins. The host starts the run. UDP/TCP port 24242, discovery
  on UDP 24243; both devices must be on the same network.
- A hero at 0 health goes down. Stand next to them for 2.5 seconds to revive them; they also get
  back up when the room is cleared or the next floor starts. The run ends when both are down. On one screen each player picks a blessing in turn (shared over LAN); gold, weapons, relics
  and keys belong to whoever picks them up.
- The host simulates everything and sends 20 snapshots a second; the guest predicts only its own walking.

## Android

Touch menus: the first tap chooses a row, a second tap on it confirms (so nothing is bought
by a stray touch). Typing screens (naming a skill, recipes, notebook, Word Forge, wishes) slide
up above the on-screen keyboard and get OK and CANCEL buttons beside the panel; tapping the wish
line on the blessing screen opens the keyboard. The phone's Back button is Escape.

The view fills any screen at a whole-number pixel scale (sharp pixels; a fractional scale blurred on phones): the world shows more on a wide or tall screen, the 480 x 270 HUD sheet stays
centred, and the status block, the map and the touch controls hug the real edges inside the
safe area (`game.fit`, `hud_off`, `hud_edge`). The big button beside the fire stick changes
element and shows how much of the current one is left. The launcher icon is painted by
`tests/icon.gd` into `icon.png`, `icon_fg.png`, `icon_bg.png` (the only image files in the project).

`export_presets.cfg` has an Android preset (arm64, landscape, network permissions). Building an APK
needs the Android SDK set in Godot's Editor Settings; then: `godot --headless --path rebirth --export-debug Android build/dungeon-core.apk`.

Built on 2026-11-11 with the SDK at
`C:/Users/ADMIN/Documents/Codex/2026-11-05/la/work/android-sdk` (set as Godot's Android SDK path),
install with that SDK's `platform-tools/adb install -r build/dungeon-core.apk` (the old `C:/adb/adb` loses the device). The project needs
`textures/vram_compression/import_etc2_astc=true` for this export; it is set.

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
  - Quartermaster: one station for preparing a run: meals (health, armor, gold, key), packing a
    weapon you have found before, and crafting from blueprints.
  - Tailor: dyes that recolour your heroes.
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
- Shooting one of your own element pools with a different element detonates it; doing the same
  to an enemy pool hijacks it (see above).
- Workshop rooms: upgrade a weapon (+1 to +5), change its element, use the Word Forge, or build a
  blueprint weapon at the bench.
- Hard ground in fight rooms: mire slows anything on foot (heroes and foes) to about half speed;
  pits cost a hero one point and put them back where they last stood. Dashing crosses both safely.
  Foes on foot must walk around pits, flyers ignore them, bullets fly over. The rim of a room and
  the cross through its centre are always clear, so doors are never cut off.
- Crafting: blueprints for six weapons that never drop as loot are found in secret rooms (always),
  after bosses (40%) and elite rooms (30%), and are kept forever. Foes drop scrap (kept between runs).
  The Quartermaster in the Hearth crafts one for the next run (15 scrap plus materials); the bench
  in a workshop room builds a random known one on the spot for 50 gold.
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

Wind-up and attack frames are hand-drawn for all 8 heroes, 11 foe shapes and 9 bosses in
`src/frames.gd` (the rows that change: eyes, mouths, arms, horns, cores). Generated motion
(`Art.pose_frames`, `Art.walk_frames`) is applied on top.

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
| `src/data.gd` | Weapons, heroes, skills, enemies, biomes, blessings, recipes (tune here) |
| `src/meta.gd` | Save file, skill tree effects and generator, hero generator, enemy learning |
| `src/dungeon.gd` | Floor layout, hazards, lobby layout, baking |
| `src/art.gd` | All sprites as character maps, tile generators, pose frames |
| `src/frames.gd` | Hand-drawn wind-up and attack frames, as row edits of the base sprites |
| `src/hud.gd` | Title, HUD, minimap, menus |
| `src/combo.gd` | Element fields left by reactions, three-element storms, cataclysm |
| `src/env.gd` | Rooms reacting to elements; hijacking enemy pools |
| `src/reso.gd` | Elemental resonance: stacks, the four bursts, attunement |
| `src/forge.gd` | Word Forge: command parsing (EN/VI/pad) and forged weapons |
| `src/wish.gd` | Typed wishes for blessings; naming and shaping skill one |
| `src/nemesis.gd` | The foe that killed you returns, talks, can be spared into an ally; graves |
| `src/sky.gd` | Weather of a floor (loaded as `Wx`: `Sky` is a Godot class name) |
| `src/book.gd` | The alchemy notebook: discoveries and the names you give them |
| `src/puzzle.gd` | Puzzle rooms: chasm, braziers, conduit |
| `src/spell.gd` | Lectern: skill training, and the reaction spell (six shapes, four motions) |
| `src/chem.gd` | Chemistry generator: aspects of the fifteen elements, generated reactions, fields and storms |
| `src/tutor.gd` | The first lesson at the training dummy |
| `src/storm.gd` | The fourteen forms a three-element effect can take |
| `src/ext.gd` | Skills, pet follow and shots, mounts, burst, workshop stations, second boss set |
| `src/foes.gd` | Charged specials of ordinary foes; third boss of each biome |
| `src/arms.gd` | Fusion traits; homing and returning projectiles |
| `src/more.gd` | Synergies, relics, secret rooms, blueprints, dungeon bench |
| `src/pets.gd` | Pet skills, hearts, exclusive passives, the pet bowl |
| `src/traps.gd` | Floor traps: placement, timing, drawing |
| `src/fx.gd` | Visual effects: element trails, hits, statuses, reactions, boss auras, fused gear |
| `src/lobby.gd` | The Hearth: stations, menus, signs, secrets |
| `src/hub.gd` | South wing: bounties, trophies, quartermaster, tailor, capsule machine, boons |
| `src/talk.gd` | NPC dialogue rules |
| `src/net.gd` | LAN co-op: host/join, discovery, snapshots |
| `src/pad.gd` | Gamepad input and local player two |
| `src/touch.gd` | Touch sticks and buttons |
| `src/sfx.gd` | Synthesized sound effects and music |
| `src/font.gd` | 5x7 pixel font |

## Tests

    godot --headless --fixed-fps 30 --path rebirth --script res://tests/smoke.gd

`smoke.gd` tours the lobby (buys everything, finds the secrets), then plays a full 6-floor run with
five heroes using a bot in god mode. Every test uses its own save file. Run the others the same way:

| Test | Covers |
|---|---|
| `chem.gd` | Room chemistry, hijacking, wishes, named skills, nemesis, prep station |
| `combo.gd` | Fields, storms, cataclysm |
| `world.gd` | Weather, notebook, puzzle rooms, sparing the nemesis, graves |
| `recipes.gd` | Fifteen elements, generated reactions and storms, element slots, recipes |
| `terra.gd` | The newer elements against terrain, crates, walls and traps; gamepad prompts |
| `lesson.gd` | Element saturation, blessing emblems, the first lesson, touch button layout |
| `forms.gd` | Every three-element form runs, hurts and has its own name (pictures when not headless) |
| `mana.gd` | Mana pools, reaction costs, field limits, control immunity, gathered casts |
| `typing.gd` | Touch-only menus and typing screens: tap twice to confirm, naming a skill, Back is Escape |
| `pause.gd` | Pause menu rows, confirmation of destructive rows, difficulty dials |
| `icon.gd` | Paints the app icon files (run headless after changing the design) |
| `shot4.gd`, `shot5.gd` | Phone-shaped screenshots: wide view, lesson, blessing cards (`--resolution 1400x630`) |
| `shot3.gd` | Screenshot of the fifteen element crystals in the Hearth (run without `--headless`) |
| `forge.gd` | Word Forge and the starting loadout |
| `anim.gd` | Pose frames and animation states |
| `pets.gd` | Materials, seeds, garden, recipes, pets |
| `terrain.gd` | Mire, pits, blueprints, crafting |
| `arms.gd` | Weapons, fusion traits, newest heroes, resonance |
| `foes.gd` | Charged specials, newest bosses, weapon sprites |
| `drops.gd` | Drop and shop rules |
| `traps.gd` | Traps in every biome |
| `resume.gd` | Settings, hints, continuing a saved run |
| `coop.gd` | Local two-player co-op |
| `net_host.gd` + `net_client.gd` | A LAN session (two processes, host first, `--max-fps 60`) |
| `touch.gd`, `pad.gd` | Touch and gamepad input |

Bots play in god mode, so the tests catch crashes and stuck rooms, not balance.
