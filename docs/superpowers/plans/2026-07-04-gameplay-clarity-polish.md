# Gameplay Clarity And Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add door reward previews, combat feedback, and low-risk tile visual polish.

**Architecture:** `FloorController` passes room-type intent into `RoomRenderer`; `RoomRenderer` creates world-space `DoorMarker` nodes. `Enemy` owns local combat feedback nodes. Tile polish stays inside `RoomRenderer` helpers so collision and generation are untouched.

**Tech Stack:** Godot 4.7, GDScript, 0x72 DungeonTilesetII `SpriteDB`, headless smoke tests.

---

### Task 1: Door Reward Preview

**Files:**
- Create: `scripts/rooms/door_marker.gd`
- Modify: `scripts/rooms/room_renderer.gd`
- Modify: `scripts/rooms/floor_controller.gd`
- Test: `scripts/tests/gameplay_polish_smoke.gd`

- [ ] Write failing smoke test that expects `DoorMarker.label_for_type(RoomNode.RoomType.BOSS) == "BOSS"` and `RoomRenderer.show_door_markers()` to add one marker per target door.
- [ ] Run the test and confirm it fails because `DoorMarker` or `show_door_markers()` does not exist.
- [ ] Add `DoorMarker` with `configure(room_type)` plus static label/color helpers.
- [ ] Add `RoomRenderer.clear_door_markers()` and `show_door_markers(door_targets)`.
- [ ] Call marker display from `FloorController._on_room_cleared()`.

### Task 2: Combat Feel

**Files:**
- Modify: `scripts/enemies/enemy.gd`
- Test: `scripts/tests/gameplay_polish_smoke.gd`

- [ ] Extend the smoke test to damage an enemy and expect HP bar plus damage number nodes.
- [ ] Run the test and confirm it fails because feedback nodes are missing.
- [ ] Add enemy HP bar creation/update after damage.
- [ ] Add floating damage number label with short lifetime.

### Task 3: Tile Polish

**Files:**
- Modify: `scripts/rooms/room_renderer.gd`
- Test: `scripts/tests/gameplay_polish_smoke.gd`

- [ ] Extend the smoke test to verify a wall sprite name helper returns a non-empty wall sprite for a wall tile.
- [ ] Run the test and confirm it fails because the helper is missing.
- [ ] Add helper-driven wall sprite choice and use it from `_draw_tile_texture()`.
- [ ] Keep sprite fallback to old color drawing.

### Task 4: Verify And Push

**Files:**
- Stage only touched source, tests, docs, and new `.uid` files for new tests/scripts.

- [ ] Run Godot editor import.
- [ ] Run `sprite_db_smoke.gd`, `visual_sprite_smoke.gd`, `camera_sprite_polish_smoke.gd`, and `gameplay_polish_smoke.gd`.
- [ ] Run headless launch.
- [ ] Commit and push `feature/godot-mvp-scaffold`.
