class_name RoomStamper
extends RefCounted
## Step 4 of the pipeline: turns a RoomNode into a TileGrid.
## Base room + carved doors + mutated terrain, validated for fairness.
## Retries with fewer obstacles when validation fails; the final fallback
## is an empty room, so stamping can never produce an unfair layout.

enum Dir { NORTH, EAST, SOUTH, WEST }

const DEFAULT_MIN := Vector2i(20, 12)
const DEFAULT_MAX := Vector2i(28, 16)
const SIZE_BY_TYPE := {
	RoomNode.RoomType.ENTRANCE: Vector2i(20, 12),
	RoomNode.RoomType.MINIBOSS: Vector2i(30, 18),
	RoomNode.RoomType.BOSS: Vector2i(36, 22),
}
const DOOR_CLEARANCE := 3  # Chebyshev distance kept obstacle-free around doors
const MAX_ATTEMPTS := 5


## Side of the room a border tile sits on, or -1 for interior tiles.
static func dir_of_door_tile(grid: TileGrid, tile: Vector2i) -> int:
	if tile.y == 0:
		return Dir.NORTH
	if tile.y == grid.height - 1:
		return Dir.SOUTH
	if tile.x == 0:
		return Dir.WEST
	if tile.x == grid.width - 1:
		return Dir.EAST
	return -1


## All door tiles on the given side of the room.
static func door_tiles(grid: TileGrid, dir: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in grid.door_positions():
		if dir_of_door_tile(grid, d) == dir:
			out.append(d)
	return out


func stamp(room: RoomNode, rng: SeededRNG, door_dirs: Array[int]) -> TileGrid:
	var size := _room_size(room, rng)
	var features := _feature_count(room, rng)
	for attempt in MAX_ATTEMPTS:
		var grid := _base_room(size)
		_carve_doors(grid, door_dirs)
		_mutate(grid, rng, maxi(features - attempt, 0))
		if grid.is_fair():
			return grid
	# Fallback: obstacle-free room is always fair.
	var plain := _base_room(size)
	_carve_doors(plain, door_dirs)
	return plain


func _room_size(room: RoomNode, rng: SeededRNG) -> Vector2i:
	if SIZE_BY_TYPE.has(room.type):
		return SIZE_BY_TYPE[room.type]
	return Vector2i(
		rng.randi_range(DEFAULT_MIN.x, DEFAULT_MAX.x),
		rng.randi_range(DEFAULT_MIN.y, DEFAULT_MAX.y),
	)


func _feature_count(room: RoomNode, rng: SeededRNG) -> int:
	match room.type:
		RoomNode.RoomType.ENTRANCE, RoomNode.RoomType.HEAL, RoomNode.RoomType.SHOP:
			return rng.randi_range(0, 2)
		RoomNode.RoomType.BOSS, RoomNode.RoomType.MINIBOSS:
			return rng.randi_range(2, 4)  # boss arenas stay readable
		_:
			return rng.randi_range(4, 7)


func _base_room(size: Vector2i) -> TileGrid:
	var grid := TileGrid.new(size.x, size.y, TileGrid.Tile.FLOOR)
	for x in size.x:
		grid.set_tile(x, 0, TileGrid.Tile.WALL)
		grid.set_tile(x, size.y - 1, TileGrid.Tile.WALL)
	for y in size.y:
		grid.set_tile(0, y, TileGrid.Tile.WALL)
		grid.set_tile(size.x - 1, y, TileGrid.Tile.WALL)
	return grid


## 2-tile wide door opening in the middle of each requested side.
func _carve_doors(grid: TileGrid, door_dirs: Array[int]) -> void:
	var cx := grid.width / 2
	var cy := grid.height / 2
	for dir in door_dirs:
		match dir:
			Dir.NORTH:
				grid.set_tile(cx - 1, 0, TileGrid.Tile.DOOR)
				grid.set_tile(cx, 0, TileGrid.Tile.DOOR)
			Dir.SOUTH:
				grid.set_tile(cx - 1, grid.height - 1, TileGrid.Tile.DOOR)
				grid.set_tile(cx, grid.height - 1, TileGrid.Tile.DOOR)
			Dir.WEST:
				grid.set_tile(0, cy - 1, TileGrid.Tile.DOOR)
				grid.set_tile(0, cy, TileGrid.Tile.DOOR)
			Dir.EAST:
				grid.set_tile(grid.width - 1, cy - 1, TileGrid.Tile.DOOR)
				grid.set_tile(grid.width - 1, cy, TileGrid.Tile.DOOR)


func _mutate(grid: TileGrid, rng: SeededRNG, features: int) -> void:
	var doors := grid.door_positions()
	for f in features:
		var roll := rng.randf()
		if roll < 0.35:
			_stamp_blob(grid, rng, doors, TileGrid.Tile.PILLAR, Vector2i(rng.randi_range(1, 2), rng.randi_range(1, 2)))
		elif roll < 0.55:
			_stamp_blob(grid, rng, doors, TileGrid.Tile.PIT, Vector2i(2, 2))
		elif roll < 0.75:
			_stamp_blob(grid, rng, doors, TileGrid.Tile.WATER, Vector2i(3, 3))
		else:
			_stamp_blob(grid, rng, doors, TileGrid.Tile.GRASS, Vector2i(3, 3))


## Places a rectangle of [tile] at a random interior spot that keeps
## DOOR_CLEARANCE tiles free around every door. Gives up silently after
## a few tries (fairness is re-checked by the caller anyway).
func _stamp_blob(grid: TileGrid, rng: SeededRNG, doors: Array[Vector2i], tile: TileGrid.Tile, size: Vector2i) -> void:
	for attempt in 12:
		var x := rng.randi_range(2, grid.width - 2 - size.x)
		var y := rng.randi_range(2, grid.height - 2 - size.y)
		if _too_close_to_doors(Rect2i(x, y, size.x, size.y), doors):
			continue
		for dy in size.y:
			for dx in size.x:
				grid.set_tile(x + dx, y + dy, tile)
		return


func _too_close_to_doors(rect: Rect2i, doors: Array[Vector2i]) -> bool:
	for d in doors:
		var closest := Vector2i(
			clampi(d.x, rect.position.x, rect.position.x + rect.size.x - 1),
			clampi(d.y, rect.position.y, rect.position.y + rect.size.y - 1),
		)
		var dist := maxi(absi(d.x - closest.x), absi(d.y - closest.y))
		if dist <= DOOR_CLEARANCE:
			return true
	return false
