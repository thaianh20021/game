# DungeonTilesetII Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace placeholder visuals with 0x72 DungeonTilesetII v1.7 sprites while preserving gameplay logic.

**Architecture:** Add a lazy `SpriteDB` as the only asset lookup layer. Existing scenes keep placeholder polygons as fallbacks; scripts hide placeholders only after sprite setup succeeds. Room rendering remains draw-based for minimal risk.

**Tech Stack:** Godot 4 GDScript, AtlasTexture, SpriteFrames, AnimatedSprite2D, Node2D draw API, PowerShell verification commands.

---

## File Structure

- Create `assets/dungeon_tileset/`: atlas image, tile list, license.
- Create `scripts/assets/sprite_db.gd`: asset parser and SpriteFrames builder.
- Create `scripts/tests/sprite_db_smoke.gd`: headless assertions for parser and fallback behavior.
- Modify `scenes/player.tscn`: add `AnimatedSprite2D` child while keeping `Body`.
- Modify `scripts/player/player.gd`: class-to-animation mapping, animation update, flip.
- Modify `scenes/enemy.tscn`: add `AnimatedSprite2D` child while keeping `Body`.
- Modify `scripts/enemies/enemy.gd`: visual configuration method and movement animation update.
- Modify `scripts/rooms/room_renderer.gd`: sprite tile drawing and enemy visual assignment.
- Modify `scripts/loot/pickup.gd`: sprite/animation visuals with polygon fallback.
- Modify `scripts/rooms/exit_portal.gd`: ladder sprite with polygon fallback.

### Task 1: Import Asset Pack

- [ ] Download current DungeonTilesetII zip from itch.io.
- [ ] Extract atlas and tile list into `assets/dungeon_tileset/`.
- [ ] Add `assets/dungeon_tileset/LICENSE.txt` with `0x72 DungeonTilesetII v1.7 - CC0 - https://0x72.itch.io/dungeontileset-ii`.
- [ ] Verify files exist with `Get-ChildItem assets/dungeon_tileset`.

### Task 2: SpriteDB Red Test

- [ ] Create `scripts/tests/sprite_db_smoke.gd` that loads `SpriteDB`, asserts a floor texture exists, asserts an animation has multiple frames, asserts a missing texture returns null, and exits nonzero on failure.
- [ ] Run `Godot_v4.7-stable_win64_console.exe --headless --path . --script scripts/tests/sprite_db_smoke.gd`.
- [ ] Expected: fail because `SpriteDB` does not exist.

### Task 3: SpriteDB Implementation

- [ ] Create `scripts/assets/sprite_db.gd` with `class_name SpriteDB`.
- [ ] Implement lazy atlas loading, tile-list parsing for `name x y w h [nframes]`, `texture(name)`, `frames(name)`, `build_sprite_frames(anims)`, and warning de-duplication.
- [ ] Add candidate lookup helper so code can try v1.4/v1.7 name variants without crashing.
- [ ] Run the smoke test; expected: pass.

### Task 4: Player Visuals

- [ ] Add `AnimatedSprite2D` child named `Sprite` to `scenes/player.tscn`.
- [ ] In `Player`, cache `Sprite` and `Body`, map class ids to candidate idle/run names, call `SpriteDB.build_sprite_frames()` in `apply_class()`.
- [ ] In `_physics_process()`, play `run` when velocity is nonzero, else `idle`; set `flip_h` from move direction or aim direction.
- [ ] Run headless game start; expected: exit 0.

### Task 5: Enemy Visuals

- [ ] Add `AnimatedSprite2D` child named `Sprite` to `scenes/enemy.tscn`.
- [ ] Add `Enemy.configure_visual(id, kind, idle_candidates, run_candidates, tint)` or equivalent narrow API.
- [ ] Update enemy animation from velocity and flip toward movement/target.
- [ ] In `RoomRenderer._spawn_enemy()`, map enemy data id/kind to sprite candidates and call the visual API.
- [ ] Update `_make_boss()` to attach big demon animation if available, otherwise keep polygon.
- [ ] Run headless game start; expected: exit 0.

### Task 6: Room Tile Drawing

- [ ] Add sprite name constants for floor variants, walls, pillars, open/closed doors.
- [ ] Replace `_draw()` color-only path with texture-region drawing when available.
- [ ] Keep `TILE_COLORS` fallback for any missing region or unsupported tile type.
- [ ] Use deterministic floor index from x/y hash.
- [ ] Run headless game start; expected: exit 0.

### Task 7: Pickups and Portal

- [ ] In `Pickup._ready()`, try coin animation, potion sprite, weapon sprite candidates, then current polygon fallback.
- [ ] In `ExitPortal._ready()`, try ladder sprite, then current pulsing polygon fallback.
- [ ] Keep collection and portal trigger logic unchanged.
- [ ] Run headless game start; expected: exit 0.

### Task 8: Final Verification and Commit

- [ ] Run headless editor import: `Godot_v4.7-stable_win64_console.exe --headless --editor --path . --quit`.
- [ ] Run smoke test: `Godot_v4.7-stable_win64_console.exe --headless --path . --script scripts/tests/sprite_db_smoke.gd`.
- [ ] Run game start: `Godot_v4.7-stable_win64_console.exe --headless --path . --quit`.
- [ ] Check `git status --short`.
- [ ] Commit tracked implementation files with message `Integrate 0x72 DungeonTilesetII sprites`.

## Self-Review

Spec coverage: asset import, `SpriteDB`, player/enemy visuals, room tiles, pickups/portal, fallbacks, verification, and commit are covered.

Placeholder scan: no deferred placeholders remain in this plan.

Type consistency: public names match the design: `SpriteDB.texture`, `SpriteDB.frames`, `SpriteDB.build_sprite_frames`, plus a narrow enemy visual configuration method.
