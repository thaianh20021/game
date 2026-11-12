# Dư Vang: first chapter (single player)

A pixel action RPG in the spirit of the classic mobile RPGs: a town with people to talk to, quests,
a hunting ground, a dungeon with a boss, levels, loot you wear, a shop, and a save file. It is the
single-player slice of the Dư Vang design; nothing here is online yet.

Godot 4.7, GDScript, GL Compatibility, 640x360 internal, integer scaling.

## Run

`<godot>` is the console binary named in the repository's `CLAUDE.md`.

- Play: `<godot> --path duvang`
- After adding or changing a PNG in `assets/`: `<godot> --headless --path duvang --import`
- Regression (about 1 minute, plays the whole chapter, 58 checks): `<godot> --headless --fixed-fps 60 --path duvang --script res://tests/smoke.gd`
- Skill tree (48 checks): same command with `res://tests/skills.gd`; second mastery and links (43 checks): `res://tests/second.gd`; foes, elites and the gate: `res://tests/foes.gd`; items, filter and the elite hunt: `res://tests/loot.gd`; chapter two: `res://tests/ch2.gd`; menus and the Elementalist: `res://tests/menu.gd`; the Assassin and its links: `res://tests/rogue.gd`; chapters three to five, side chains, tide, stones, reforging (30 checks): `res://tests/late.gd`; the five later masteries and the solo trees (74 checks): `res://tests/masteries.gd`; font: `tests/font.gd`; music: `tests/music.gd`
- Screenshots (no `--headless`): `--script res://tests/shot.gd` and `tests/shot_tree.gd`, PNGs go to `duvang/shots/`

The save is `user://duvang_save.json`; delete it to start over. Tests use their own file (`D.SAVE_PATH`).

## Controls

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move | WASD or arrows | left stick |
| Aim | mouse | right stick |
| Strike (3-hit chain, hold to repeat) | left button or J | X |
| Skills on keys 1 to 5 | 1 2 3 4 5 (right button is also 1, Q is also 2) | B, left shoulder |
| Sixth skill (Prototype keystone only) | 6 | |
| Ultimate (with two learned: R over one in the tree picks it) | R | left stick click |
| Skill tree | T | D-pad up |
| Next tab in the skill tree | G | D-pad right |
| Choose in bag, shop and tree (cursor) | Space | A |
| In a shop: take apart, reforge | K, U | D-pad down, D-pad left |
| Swap weapon sets (each keeps its own five skills) | C | D-pad down |
| Skill tree (click a node to learn, X takes all points back) | T | through the pause menu |
| Dodge (2 charges) | Space or Shift | A |
| Talk, next line | E or Enter | Y |
| Bag (click an item to wear it) | I or Tab | Back |
| Pause menu (skills, bag, journal, settings, title) | Esc | Start |
| Potion | F | right shoulder |
| Buy a potion in the shop | B | not mapped yet |
| Loot filter: all, magic and better, rare and better | L | not mapped yet |
| Sell all junk in the shop | X | not mapped yet |

The bag and shop need the mouse; they have no gamepad navigation yet.

## What is in the chapter

- **Woodclapper Town**: Madam Say (quests), Master Kham (shop), Ngai (restores life), Warden To Dien.
- **Ashreed Marsh**: reed shades, ash herons, drowned porters, mud leeches, net throwers. Foes notice you at a distance, give up
  if led too far, and return after a while.
- **The Old Ferry**: six islands joined by bridges. Midway stands the Toll Keeper, who holds the gate east shut;
  his long amber call heals him and brings help unless a heavy hit cuts it short. At the end, the Shoreless Ferryman (sweep, slam, and below half
  life a lantern volley; calls reed shades at two thirds and one third life).
- Six main quests and two side quests lead through all of it, from four quest givers. The ferry road
  is barred until "The Old Ferry" is taken. A narrated intro opens a new game.
- Things in the world can be examined (E): the clapper, a grave, sandals on the shore. One of them,
  the net-mender's echo, ends in a choice that changes a quest's ending and reward.
- A scene replays inside the dungeon the first time you reach the toll yard.
- Items: weapon, armor, charm; common, magic (one extra property), rare (two). Twenty bases that fight differently
  (dirks strike faster, spears reach further, mauls are slow and break stances), twelve properties limited by slot,
  four uniques: Ferryman's Oar (boss), Keeper's Toll Box (Toll Keeper), Ashwalker's Wrap (volatile elites),
  Lamplighter's Wick (warding elites). An elite's unique starts at 12% and gains 6% per elite that drops none.
- Loot filter (L): items below it stay on the ground. In the shop, X sells every item below the filter (commons at least).
- The first unique made was the
  Ferryman's Oar, whose third strike throws a wave.
- Seven foes: reed shade (swipe), ash heron (spit), drowned porter (slam, has a stance), mud leech (circles, then lunges
  in a line), net thrower (a net where you stand; caught means slowed), lantern wisp (mends a wounded ally), Toll Keeper.
- Two elite marks: VOLATILE bursts a second after it dies, WARDING halves the damage foes near it take.
  Elites have 1.8 times the life, always drop an item and give triple experience and gold.
- Falling wakes you in town and costs a tenth of your gold.
- **Chapter two, the Breathing Forest**: reached from the east end of the dyke. Whisper Village (Lão Rêu, Bà Mận), the forest
  itself and the dungeon inside the Remembering Tree. Three foes: memory wolves (fast bite, come in threes), spore sowers
  (a pod that leaves a cloud you must leave), hollow stags (a long straight charge, then a long recovery). Boss: the
  tree-mother, who never moves: root lines, spore pods, an amber call for wolves; five lines and three pods below half life.
  Five main quests (m7 to m11) and one side quest; m11 is a choice with no right answer, to seal the village or keep it.
  Fifth unique: Hạt Ngàn Tên, +8% damage per mark on the foe.
- **Solo trees (Độc Tấu)**: a hero who leaves the second mastery empty gets an 8-node solo tree for the main mastery and 3 extra ranks in each of its active skills (6% faster cooldown each).
- **Tone stones (runes)**: eight stones that each give one stat and take another; magic items have one socket, rare items two. Set at a shop, never removed.
- **Bows**: three bow bases; with a bow the chain of strikes becomes three arrows, the third goes through.
- **Warrior mastery**: one point per level, free reset. Guard (Bulwark, Shield Rush), Fury (Spin, War Cry),
  Arms (Lunge, Ground Slam), nine passives, three keystones that change a rule at a price, and the
  ultimate The Toll after eight points. Five skills fit on the bar.
- The first mastery is chosen at character creation: Warrior, Elementalist, Assassin, Soul Warlock, Guardian, Hunter, Priest or Artificer (all eight from `docs/`).
  When the shard wakes at the end of chapter one the player picks the second one; the pair decides which link tree they get.
- **Assassin mastery** (19 nodes): danger points (up to 5) from strikes from behind, on stunned or chilled foes, or a dodged hit;
  Slash and Execute spend them. Shadow Step, Smoke, Venom Coating, Poison Darts, the ultimate A Thousand Cuts. Poison stacks to 5.
  Link trees: Lưỡi Bóng (with Warrior) and Dạ Lôi (with Elementalist), 8 nodes each.
- **Soul Warlock mastery** (19 nodes): souls (up to 5) from foes that die nearby and from each tenth of a boss's life.
  Call Echo (an ally that cannot be hit), Sacrifice, Weakening Curse, Soul Chain, Scythe, Soul Form, the ultimate Little Night.
  Link trees: Kiếm Tang (Warrior), Tro Hồn (Elementalist), Gặt Hồn (Assassin). **Written without tests**: see ROADMAP.
- **Guardian mastery** (19 nodes): a shield (up to 100) taken before life, fading after 4 s without a blow.
  Raise Shield, Shield Wall (blocks shots and paths), Shield Bash, Verdict (spends the shield as damage), Taunt, Cover Ring,
  the ultimate Bronze Gate. Link trees: Trấn Thủ (Warrior), Lũy Sấm (Elementalist), Dạ Vệ (Assassin), Mộ Vệ (Soul Warlock).
  **Written without tests**: see ROADMAP.
- **Hunter mastery** (19 nodes): focus (two seconds with no foe within 80 makes the next blow 40% stronger), a spirit hound
  that bites and falls, snares and mines (up to 3), Aimed Shot (stand and draw), Arrow Rain, Hunter's Mark, the ultimate The Hunt.
  Link trees: Tiên Phong (Warrior), Thiên Tiễn (Elementalist), Truy Ảnh (Assassin), Hồn Lạp (Soul Warlock), Biên Vệ (Guardian).
  **Written without tests**: see ROADMAP.
- **Priest mastery** (19 nodes): devotion (0-100) from the Priest's own heals and from standing on holy ground; holy light
  marks foes (lit: +5% damage taken). Temple Drum (heal), Holy Ground, Seal, Purge (strips elite marks for 4 s), Blessing, Vow,
  the ultimate Third Watch. Link trees: Kiếm Nguyện, Nhật Quang, Phán Quan, Chiêu Hồn, Thánh Vệ, Tuần Lâm.
  **Written without tests**: see ROADMAP.
- **Artificer mastery** (19 nodes): heat instead of rage (above 70 devices hit 20% harder, at 100 the kit overheats for 4 s).
  Crossbow Turret, Bell Mine, Vent (spends all heat as a steam cone), Boost, Grapple Hook, Mute Bell (foes inside cannot wind up),
  the ultimate Bell Engine; the Prototype keystone opens a sixth skill slot on key 6. Seven link trees, one with each other mastery.
  **Written without tests**: see ROADMAP.
  The other one wakes at the end of chapter one.
- **Elementalist mastery** (19 nodes, like the Warrior): Ember Bolt, Fire Wall, Frost Ring, Ice Shard, Chain Spark, Lightning Cage,
  nine passives, three keystones, the ultimate Tam Tai. Casting a spell of another element than the last one within 6 s resonates (+20%).
  In short: Ember Bolt (burn), Frost Ring (chill), Chain Spark
  (shock), three passives, three keystones. Burn is damage over time, chill halves speed, shock raises damage taken.
- **Tempest Blade link tree** (needs 3 points in each mastery, its keystone 6): eight nodes where a skill of one
  mastery changes the other, for example a block that charges the blade, or a chain finisher that shatters a chill.
  Guards against loops: a Pyre burst never sets off another, Conductor fires at most once every 2 seconds,
  Furnace Heart counts at most 3 foes, marks never trigger anything by themselves.

## Files

- `src/game.gd`: the simulation and world drawing. Actors are dictionaries; `sim` lets tests drive the hero.
- `src/data.gd`: foes, elite marks, item bases, properties and uniques, quests, dialogue, prices.
- `src/world.gd`: the five places (town, marsh, Old Ferry, forest, Remembering Tree). Layout depends only on the zone id.
  A zone can name a `theme`; `Art.THEMES` then swaps the tile colours when its map is painted.
- `src/skills.gd`: eight masteries (Warrior, Elementalist, Assassin, Soul Warlock, Guardian, Hunter, Priest, Artificer; 19 nodes each), twenty-eight link trees (8 each, `LINKS` names the pair of each), eight solo trees (8 each, `SOLO`) and the rules for buying a rank.
- `src/ui.gd`: HUD, skill bar, skill tree screen, talk box, bag and shop.
- `src/menu.gd`: title, character creation (pick the first mastery), pause, settings, journal, full-screen story text.
  Menus only appear with the real save file (`D.MENUS`), so tests boot straight into play. Settings live next to the save, in `<save>_opt.json`.
- `src/art.gd`: loads character sprites from `assets/`; paints tiles, props and icons from code.
- `src/sfx.gd`: synthesized sound effects and four music loops (town, marsh, dungeon, boss), built on a thread at boot.
- `src/font.gd`: 5x7 pixel font, capitals only, with every Vietnamese letter built from a base letter, a shape mark and a tone mark.
- `assets/`: hero frames (side `h_`, front `hd_`, back `hu_`), foes, bosses, NPCs, houses, scenery, 36 skill icons (`sk_<node id>`) and 24 item icons (`it_<key>`).
- `tools/gen.sh`: asks the image model for a sheet (key in the `DV_KEY` environment variable, never in a file).
- `tools/pix.gd`: turns such a sheet into real sprites (finds each figure, shrinks it to a true pixel grid).
- `tests/bot.gd`: simple auto-player shared by `smoke.gd` and `shot.gd`.

## Making a new sprite

1. `DV_KEY=... bash tools/gen.sh <name> "<what to draw>" "<style>"` writes `gen/raw_<name>.png`.
   Ask for figures in one row on a flat magenta background with wide gaps. Send one request at a time.
2. `<godot> --headless --path duvang --script res://tools/pix.gd -- <full path to raw png> <height> <name1,name2,...>`
   writes `assets/<name>.png`. The first figure sets the scale.
3. Add the names to `SPRITES` in `src/art.gd`, then run `--import`.

A new foe also needs an entry in `D.FOES`, its moves in `update_foes` and `strike`, and its warning in `_draw`.
Foes need three poses named `<kind>_i`, `<kind>_w`, `<kind>_k` (idle, wind-up, strike), facing right.
The hero is a chibi knight (the earlier tall design is kept in `gen/old_hero/`) with six frames per facing: side (mirrored for left), front and back. Side frames: `h_idle`, `h_w1`,
`h_w2`, `h_w3` (walk), `h_wind`, `h_slash`. They are mirrored to face left. Generate all frames of a
character in ONE request, or the design drifts between pictures.
Foes are one still picture per pose; their hop, breathing and lunge are done in `draw_foe`.
Icons: ask for six per sheet, convert with `fit` as the last argument (each figure scaled on its own into a square), then
name them `sk_<node id>` or `it_<key>` (`D.icon` gives the key: slot letter and base index, or `u_<effect>` for uniques).
A missing icon falls back to the two-letter label or the slot picture. `gen/convert.sh` lists every sheet and its names;
`tests/sheet.gd` writes all icons to `shots/icons.png`.
Scenery props go in `world.gd` as decor; give a prop `"bw"` (block width) when only its base should stop the hero.

Class design lives in `docs/`: `CLASSES.md` (rules and the eight masteries), `HYBRIDS.md` and `HYBRIDS_2.md` (the 28 pairs and their link trees). Only Warrior, part of Elementalist and their link tree are built.
Quests, dialogue, examinable things and scenes are data in `src/data.gd` (`QUESTS`, `ORDER`, `CHAT`,
`THINGS`, `SCENES`); the rules that run them are at the end of `src/game.gd`. Where the project is
heading, and what the brief still asks for, is in `ROADMAP.md`.

## Rules already in the code

- One animation frame is 1/12 s. Strike: 2 startup, 1 active, 2 recovery; third strike 3/1/3.
  Dodge cancels startup and recovery; the next strike can start one frame into recovery.
- Vermilion `#FF4B2B` is reserved for enemy ground warnings. Do not use it for anything else.
- All on-screen text is Vietnamese, in capitals. Ids, code comments and this file stay English. Line spacing in
  panels is 10 px; a tone mark reaches 3 px above a letter and a dot 1 px below, so keep at least that.
- Each warning has its own pitch: low (slam), middle (swipe, sweep), high (spit, volley).
- Amber `#FFC83D` is reserved for casts that can be interrupted (a turning ring of dots). Any hit interrupts a light
  foe; a heavy foe needs a heavy hit: the last strike of the chain, a skill swing or a charge.
- Light foes stagger on any hit. Heavy foes have a poise pool; emptying it breaks their stance, and
  they cannot be broken again for a few seconds (3 s porter, 7 s boss).
- A strike that catches spit in its arc destroys it.
- Item stats: reach (px), strike speed (scales wind-up and recovery of chain strikes only), stance damage, critical
  (double damage), cooldown reduction (capped at 40%), life per second, gold found.
- Damage dealt is attack x move multiplier (1, 1, 1.8, spin 2.4). Damage taken is raw x 60 / (60 + 4 x armor).

## Not done

The other six masteries, skill variants, an ultimate for the second mastery, a fourth hand-drawn facing (left is the right side mirrored),
gamepad control of the bag, lower-case letters in the font, any networking. Balance has
only been played by the test bot.

## Android

`export_presets.cfg` has an Android preset (arm64, landscape, immersive). With the Android SDK set in Godot's Editor Settings
(on this machine `C:/Users/ADMIN/Documents/Codex/2026-11-05/la/work/android-sdk`, JDK 17 at `C:/Java/jdk-17.0.19+10`):
`godot --headless --path duvang --export-debug Android build/du-vang.apk`, then install with that SDK's
`platform-tools/adb install -r build/du-vang.apk` (accept the install prompt on the phone).
The launcher icons (`icon.png`, `icon_fg.png`, `icon_bg.png`) are cut from a generated picture by `tools/icon.gd`.

Touch controls (`src/touch.gd`) appear once a finger touches the screen: a floating stick on the left half, and on the right
the attack button, dodge, five skills with their icons, the ultimate, a potion, E (talk, look), and the bag, skill tree and
pause at the right edge. Attacks and skills aim at the nearest foe. Menus, the bag, the shop and the skill tree work by tapping.
The phone's Back button opens and closes the pause menu. Not yet tried on a phone.
