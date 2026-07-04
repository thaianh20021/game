# Combat Animation V1 Design

## Scope

Add a safe combat animation slice inspired by Soul Knight-like feel without copying any unlicensed assets or source. The shipped repository uses only existing 0x72 sprites and code-native Godot shapes/tweens.

Temporary unlicensed reference assets may be used for local experiments under `assets/_tmp_unlicensed/`, but that folder must stay ignored and must not be pushed. This slice does not require those files.

## Animation Beats

Combat needs four readable micro-animations:

1. Melee attacks spawn a short slash arc in the aim direction.
2. Ranged and magic attacks spawn a muzzle flash at the projectile origin.
3. Dash creates a brief ghost/trail copy of the player sprite or fallback body.
4. Enemy/boss telegraphs create a ring/line hint before dash, fuse, or smash damage.

These effects are visual-only. Damage, cooldowns, invulnerability, AI state timing, loot, class stats, and projectile behavior do not change.

## Architecture

Create `CombatFx`, a small static helper in `scripts/fx/combat_fx.gd`. It owns construction of transient `Node2D` effects using `Line2D`, `Polygon2D`, `ColorRect`, and tweens. Game objects call this helper at existing event points:

- `Weapon.try_attack()` calls melee slash or muzzle flash after cooldown succeeds.
- `Player._start_dash()` spawns dash ghosts.
- `Enemy` and `BossGolem` spawn telegraph effects when entering telegraph/fuse states.

Effects name their root nodes predictably so smoke tests can assert that they spawned.

## Testing

Add `scripts/tests/combat_animation_smoke.gd`. It verifies:

- `CombatFx.spawn_slash()` creates and cleans up a `CombatFxSlash` node.
- `CombatFx.spawn_muzzle_flash()` creates a `CombatFxMuzzleFlash` node.
- A successful melee weapon attack spawns slash FX.
- A successful projectile weapon attack spawns muzzle FX.
- Player dash spawns a `CombatFxDashGhost`.
- Enemy telegraph spawn path creates a `CombatFxTelegraph`.

Run the new test plus existing smoke tests before commit/push.
