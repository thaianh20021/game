# Dungeon Core: Elemental Rebirth

The game lives in `rebirth/` (Godot 4.7, GDScript, GL Compatibility). The repository root holds the
old prototype and is kept only for reference: do not edit it.

## What the game is

Top-down roguelike shooter, bullet-hell leaning, built around an elemental reaction system.
The owner asked (2026-11-11) that heroes and weapons must NOT resemble Soul Knight: the cast is
creatures and constructs (Brassheart, Lantern, Kestrel, Veil, Croak, Ramskull, Rivet, Mosscap) and
weapons are horns, pods, bells, lenses and the like, not guns. Keep new content in that style and
never copy another game's characters, names or assets. Internal ids (warden, pistol, rail...) are
old and do not match display names.
All sprites, tiles, sounds and music are generated from code at boot (no asset files).
In-game text is English capitals only (the pixel font has no other glyphs). The owner writes in Vietnamese.

## Run and test

Godot console binary on this machine:
`%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe`

- Play: `<godot> --path rebirth`
- Regression (about 5 minutes): `<godot> --headless --fixed-fps 30 --path rebirth --script res://tests/smoke.gd`
- Local co-op: same with `res://tests/coop.gd`
- LAN: start `tests/net_host.gd`, then `tests/net_client.gd`, as two processes with `--max-fps 60` (no `--fixed-fps`)
- Screenshots: run `tests/shot.gd`, `tests/shot2.gd`, `tests/pad.gd` without `--headless`; PNGs go to the temp folder

Tests use their own save files (`Meta.PATH`). Always run smoke.gd after touching `src/game.gd`.

## Architecture rules

- `src/game.gd` owns the simulation. Actors are plain dictionaries, no physics engine, no scene files.
- `players` is the list of heroes; `p` and `st` point at the hero being simulated or drawn. Call
  `bind(pl)` before code that reads `p`; `_process` rebinds `players[me]` every frame.
- Input goes through `jpk()`, `key()`, `mouse()`, `firing()`. `cin` replaces keyboard/mouse while a
  pad, touch-less remote or simulated player is updated (`input_for`).
- LAN: host-authoritative, see `src/net.gd`. Anything a guest must see has to be in `Net.snapshot`.
- Floor layout must depend only on `run_seed` and `floor_i` (uses `drng`), so seeds and LAN guests match.
- Tunable content is in `src/data.gd`; persistent progress and generators in `src/meta.gd`.
- `README.md` in `rebirth/` lists every file and the controls; keep it current.

## State of the work (2026-11)

Done: lobby, 8 heroes + woven heroes, 25 weapons, fusion, skill trees, pets, mounts, weapon workshop, relics,
active items, synergies, secret rooms, codex, heat levels, daily/seeded runs, garden, 9 bosses,
learning foes, touch controls, gamepads, local and LAN co-op (player two can use the keyboard),
hub south wing (bounties, trophies, quartermaster, cook, tailor, capsule machine, mailbox),
settings menu, first-time hints, solo run save and continue, floor traps (spikes + one per biome,
`src/traps.gd`), charged specials for ordinary foes (`src/foes.gd`), per-weapon sprites and
element/reaction/boss visual effects (`src/fx.gd`), elemental resonance (`src/reso.gd`), fusion
traits and homing/returning shots (`src/arms.gd`), mire and pits (`dg.terr`, generated in
`src/dungeon.gd`), blueprints, scrap and workbenches (`src/more.gd`, `src/hub.gd`), crafting materials and recipes,
seed drops and a five-plot garden, pet skills with hearts and exclusive passives (`src/pets.gd`), Word Forge (`src/forge.gd`), two starting
weapons, hub name plates and rugs, harder bullet-dense tuning, element fields and three-element
storms (`src/combo.gd`), generated pose frames and spawn/attack/death animation, floor decor, hand-drawn wind-up and
attack frames for every hero, foe shape and boss (`src/frames.gd`: add an entry there when adding a sprite). Next steps are in `rebirth/ROADMAP.md`.

Not done or unverified: balance has never been tuned by hand-play; gamepads were not tested on a
physical controller; no Android APK was built (Android SDK missing on this machine); LAN was tested
only between two processes on one PC; text is English only.

Work happens on branch `done`; `main` still has only the old prototype.
