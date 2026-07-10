# Soul-Like Expansion Design

## Goal

Add a local prototype pass inspired by Soul Knight patterns without copying fanmade assets, audio, or code into shippable project content.

## Source Policy

The folders under `_reference_unlicensed/` are study-only. They stay ignored and hidden from Godot import. Patterns are allowed: recoil timing, slash arcs, dash trails, trap telegraphs, treasure/shop room roles, boss floating-gun pressure. Direct copied sprites, frames, audio, or code are not used for committed gameplay.

Temporary runtime placeholder art may use simple Godot shapes or already integrated licensed project sprites. Any future unlicensed prototype asset must live in an ignored runtime folder and be replaced before public, portfolio, or commercial use.

## Scope

1. Traps and breakable props: rooms can spawn spikes/fire hazards and crate/vase props. Traps telegraph before damage and respect cooldowns. Props have HP, break on hits, and can drop small gold or potion pickups.
2. Special rooms: treasure rooms spawn a chest, heal rooms spawn a shrine, and shop rooms spawn a vending machine. Each room becomes interactive even without enemies.
3. Weapon pattern v2: weapons can express spread shots, burst shots, and light recoil through data-safe behavior.
4. Boss pressure: the boss can add orbiting floating guns that fire simple projectiles, giving readable Soul-like arena pressure.
5. HUD polish: show room type and a compact objective hint so the player understands why a non-combat room matters.

## Architecture

Keep new gameplay nodes focused and testable:

- `Trap`: hazard timing, telegraph state, damage application.
- `BreakableProp`: HP, hit API, visual state, optional pickup drops.
- `RoomInteractable`: chest, shrine, and shop interactions using existing `Pickup` and `Player` APIs.
- `FloatingGun`: child pressure unit for boss arenas.

`RoomRenderer` owns room-local placement because it already owns tile-to-world conversion, clear state, pickups, and per-room lifecycle. Placement is deterministic from grid and room type, avoiding path blocking by using only walkable floor/grass/water tiles away from doors and center entry.

## Data Flow

`FloorController` passes the current room type into `RoomRenderer.setup`. `RoomRenderer` builds collisions, spawns combat waves, then spawns room features based on room type and grid. Existing enemy drops still use `LootRoller`; props and interactables create `Pickup` nodes directly.

Weapon v2 behavior is derived from current weapon group/stats. Ranged weapons with high speed gain burst feel, bows/crossbows gain spread options, and all attacks apply a tiny visual recoil offset without changing damage formulas.

Boss floating guns are spawned by `BossGolem` and fire at the current target through a small local projectile. They are readable shape placeholders until final art.

## Testing

Add one smoke test that proves the feature surface works in headless Godot:

- `Trap.apply_to()` damages a dummy player only after telegraph/cooldown rules.
- `BreakableProp.hit()` breaks the prop and spawns a pickup.
- `RoomInteractable.use()` handles chest, shrine, and shop effects.
- `RoomRenderer.setup()` spawns expected feature groups for treasure/heal/shop/combat rooms.
- Weapon pattern helpers expose spread/burst counts.
- `BossGolem` can spawn floating guns.

## Non-Goals

No direct copied fanmade asset/code use. No full economy balancing, shop inventory UI, final trap sprites, or advanced boss phases in this pass.

## Self-Review

No placeholders. Scope is broad but each subsystem is small and independently testable. The asset policy is explicit: study-only references, no shippable copied content.
