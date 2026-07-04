# Gameplay Clarity And Polish Design

## Scope

Ship three thin vertical-slice upgrades in this order:

1. Door reward preview after a room is cleared.
2. Combat feel pass with enemy HP bars and damage numbers.
3. Tile polish pass using 0x72 textures for more readable wall/floor rendering.

## Door Reward Preview

When a room is cleared, each open door shows a world-space marker at the door. The marker uses the target room type from `RoomNode.door_map`: combat, elite, treasure, shop, shrine, heal, miniboss, boss, event, or secret. Markers are removed when entering another room. Door transition rules stay unchanged.

`FloorController` owns graph knowledge and passes per-door target room types to `RoomRenderer`. `RoomRenderer` owns marker placement because it already knows door tile positions. A new `DoorMarker` node owns label/color rendering.

## Combat Feel

Enemies display a small HP bar only after taking damage and spawn a short-lived floating damage number on hit. Existing damage math, statuses, death, and loot behavior do not change. The UI is world-space so it works with the new camera zoom.

`Enemy` owns the HP bar and hit number because damage already enters through `take_damage()`.

## Tile Polish

Keep `RoomRenderer` draw-based for low risk, but add simple edge-aware wall rendering and floor variation using existing 0x72 sprites. Fallback colors stay intact when sprites are missing. Collision, door locking, and grid generation do not change.

## Tests

Add smoke tests for marker labels/placement, enemy hit feedback nodes, and tile helper output. Keep existing sprite and camera tests green.
