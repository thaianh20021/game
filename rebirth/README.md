| `src/lobby.gd` | The Hearth: stations, menus, secrets |
| `src/hub.gd` | South wing: bounties, trophies, quartermaster, cook, tailor, capsule machine, boons || `src/net.gd` | LAN co-op: host/join, discovery, snapshots |
| `src/pad.gd` | Gamepad input and local player two |
| `src/touch.gd` | Touch sticks and buttons |
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
| Esc | Pause (reaction cheat sheet, foe cunning) |

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

Every run starts and ends here. Gems earned in runs are spent here and are kept forever.

- Walk up to another hero and press E to play as them. Touch a crystal to pick your starting element.
- 6 heroes. Mentor: a 9-node skill tree per hero (Power / Flow / Element); newer heroes, fusions and woven heroes each get a different tree.
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

## In the dungeon

- Carry 2 weapons, each with an element (fire, ice, storm, venom). Two different elements on one foe
  trigger a reaction: Melt, Blast, Overload, Shatter, Blight, Plague. Reactions charge the Burst bar.
- Fire and ice counter each other, storm and venom counter each other (+50% damage).
- Shooting an element pool with a different element detonates it.
- Workshop rooms: upgrade a weapon (+1 to +5), change its element, or fuse both weapons into one
  dual-element weapon that sets off reactions by itself.
- Shrines trade 1 max health for a blessing. Shops sell weapons, potions and tomes.
- Talk to the peddler, smith and alchemist: they comment on your gold, health and elements, and the
  peddler tells you the weakness of the boss ahead.
- Fight rooms can be elite, dark, frenzied or element-surged. Layouts, room shapes and the boss of
  each biome (two candidates each, six in total) are rolled per floor.
- Pick a blessing after every floor.

## Foes that learn

Saved between runs in the same file as your progress:

- Shooters track whether aiming straight or leading the target hits you more, and favour what works.
- Bosses weight each attack by how much damage it has dealt to you before.
- "Cunning" rises when you clear rooms untouched and drops when you struggle. It raises spawn budgets,
  shortens boss rests, and makes more foes dodge shots and punish dashes.

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
using a bot in god mode. Uses its own save file. `tests/coop.gd` plays local two-player co-op; `tests/net_host.gd` + `tests/net_client.gd` (run as two
processes, host first) check a LAN session; `tests/touch.gd` and `tests/pad.gd` drive touch and pad input.
