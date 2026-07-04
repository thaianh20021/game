# DungeonTilesetII Integration Design

## Goal

Integrate 0x72 DungeonTilesetII v1.7 into the Godot MVP while preserving all current gameplay, collision, status, loot, and room progression logic.

## Asset Source

Use the current itch.io download for `https://0x72.itch.io/dungeontileset-ii`, adapting the original v1.4 task to v1.7. Store imported files under `assets/dungeon_tileset/` with a `LICENSE.txt` noting CC0 attribution and source URL.

## Architecture

Add a lazy static `SpriteDB` at `scripts/assets/sprite_db.gd`. It loads the atlas texture and parses the shipped tile list once into `name -> {rect, frames}`. Public APIs return `AtlasTexture`, frame arrays, or `SpriteFrames`; missing names produce one warning per name and return null/empty values so callers can keep old placeholders.

Keep existing node/gameplay structure. Player, enemy, pickup, and portal visuals use real sprites only when `SpriteDB` resolves the requested art. Existing `Polygon2D` placeholders remain as fallback children and are hidden only after sprite setup succeeds.

Room rendering stays in `RoomRenderer._draw()` to avoid a TileMap refactor. It draws texture regions for floor, wall, pillar, and door tiles, with deterministic floor variation by tile coordinate. Collisions and room clearing remain unchanged.

## Components

- `scripts/assets/sprite_db.gd`: atlas/tile-list loader, exact and candidate lookup helpers, animation builder.
- `scenes/player.tscn` and `scripts/player/player.gd`: add `AnimatedSprite2D`, class-to-animation mapping, idle/run switching, horizontal flip.
- `scenes/enemy.tscn`, `scripts/enemies/enemy.gd`, and `scripts/rooms/room_renderer.gd`: add animated enemy visuals, map enemy ids/kinds to v1.7 sprite names, preserve root `modulate`.
- `scripts/rooms/room_renderer.gd`: draw atlas-backed room tiles and doors, fallback to current color rect draw.
- `scripts/loot/pickup.gd` and `scripts/rooms/exit_portal.gd`: use coin/flask/weapon/ladder sprites with current polygon fallback.
- `scripts/tests/sprite_db_smoke.gd`: headless smoke test for asset presence, frame parsing, fallback behavior, and basic animation construction.

## Error Handling

All `SpriteDB` consumers check for null or empty frame results. Missing files or names never crash the game. `SpriteDB` caches warnings per missing sprite name to avoid warning spam.

## Testing

Run Godot headless editor import to refresh global class and resource caches, then run the smoke test and a headless game start. Acceptance is: no parse errors, `SpriteDB` smoke exits 0, game start exits 0, and fallback paths are exercised by test.
