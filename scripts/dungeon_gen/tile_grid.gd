class_name TileGrid
extends RefCounted
## Tile layer of a single stamped room (step 4 of the pipeline).

enum Tile { FLOOR, WALL, PIT, WATER, GRASS, PILLAR, DOOR }

var width: int
var height: int
var cells: PackedInt32Array


func _init(w: int, h: int, fill: Tile = Tile.FLOOR) -> void:
	width = w
	height = h
	cells.resize(w * h)
	cells.fill(fill)


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height


func get_tile(x: int, y: int) -> int:
	return cells[y * width + x]


func set_tile(x: int, y: int, t: Tile) -> void:
	cells[y * width + x] = t


static func walkable(t: int) -> bool:
	return t == Tile.FLOOR or t == Tile.GRASS or t == Tile.DOOR or t == Tile.WATER


static func blocking(t: int) -> bool:
	return t == Tile.WALL or t == Tile.PILLAR or t == Tile.PIT


func is_walkable_at(x: int, y: int) -> bool:
	return in_bounds(x, y) and TileGrid.walkable(get_tile(x, y))


func door_positions() -> Array[Vector2i]:
	var doors: Array[Vector2i] = []
	for y in height:
		for x in width:
			if get_tile(x, y) == Tile.DOOR:
				doors.append(Vector2i(x, y))
	return doors


func walkable_count() -> int:
	var count := 0
	for c in cells:
		if TileGrid.walkable(c):
			count += 1
	return count


## BFS over walkable tiles (4-directional). Returns a set {Vector2i: true}.
func reachable_from(start: Vector2i) -> Dictionary:
	var visited := {}
	if not is_walkable_at(start.x, start.y):
		return visited
	var queue: Array[Vector2i] = [start]
	visited[start] = true
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = p + offset
			if not visited.has(n) and is_walkable_at(n.x, n.y):
				visited[n] = true
				queue.append(n)
	return visited


## Fairness check: every door reachable from the first door, and at least
## [min_ratio] of all walkable tiles connected (no big dead pockets).
func is_fair(min_ratio := 0.75) -> bool:
	var doors := door_positions()
	if doors.is_empty():
		return false
	var reach := reachable_from(doors[0])
	for d in doors:
		if not reach.has(d):
			return false
	return reach.size() >= int(walkable_count() * min_ratio)
