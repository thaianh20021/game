| `src/meta.gd` | Save file, skill tree effects and generator, hero generator, enemy learning |
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
using a bot in god mode. Uses its own save file. `tests/shot.gd` saves screenshots to the temp folder.
