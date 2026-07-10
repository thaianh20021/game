extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	_check_spawner_never_uses_unsafe_fallback(failures)
	_check_spawner_respects_entry_safety_over_many_seeds(failures)
	await _check_traps_leave_safe_door_path(failures)

	if failures.is_empty():
		print("Dungeon fairness smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_spawner_never_uses_unsafe_fallback(failures: Array[String]) -> void:
	var room := RoomNode.new()
	room.id = 1
	room.type = RoomNode.RoomType.COMBAT
	var grid := _unsafe_only_grid()
	var spawner := EnemySpawner.new()
	var plan := spawner.roll_spawn_plan(room, grid, SeededRNG.new(7, 1),
		1, 1.0, _basic_pool("melee"), Vector2i(3, 0))
	for entry in plan:
		var tile: Vector2i = entry["tile"]
		if Vector2(tile - Vector2i(3, 0)).length() < float(EnemySpawner.PLAYER_SAFE_RADIUS + 1):
			failures.append("spawner should skip enemies instead of falling back inside player safe radius")
			return

func _check_spawner_respects_entry_safety_over_many_seeds(failures: Array[String]) -> void:
	var room := RoomNode.new()
	room.id = 2
	room.type = RoomNode.RoomType.COMBAT
	var grid := _normal_grid()
	var entry := Vector2i(6, 0)
	var spawner := EnemySpawner.new()
	for seed in range(0, 80):
		var pool := {
			"enemies": [
				{"id": "smoke_melee", "name": "M", "kind": "melee", "cost": 1, "hp": 5, "dmg": 1},
				{"id": "smoke_ranged", "name": "R", "kind": "ranged", "cost": 1, "hp": 5, "dmg": 1},
			],
			"elite_modifiers": ["armored"],
		}
		var plan := spawner.roll_spawn_plan(room, grid, SeededRNG.new(seed, 2),
			2, 1.0, pool, entry)
		for spawn in plan:
			var tile: Vector2i = spawn["tile"]
			var kind := str(spawn.get("enemy", {}).get("kind", ""))
			var min_dist := EnemySpawner.RANGED_MIN_DOOR_DIST if kind == "ranged" else EnemySpawner.PLAYER_SAFE_RADIUS + 1
			if Vector2(tile - entry).length() < float(min_dist):
				failures.append("seed %d spawned %s too close to entry: %s" % [seed, kind, tile])
				return

func _basic_pool(kind: String) -> Dictionary:
	return {
		"enemies": [
			{"id": "smoke", "name": "Smoke", "kind": kind, "cost": 1, "hp": 5, "dmg": 1},
		],
		"elite_modifiers": ["armored"],
	}

func _unsafe_only_grid() -> TileGrid:
	var grid := TileGrid.new(7, 5, TileGrid.Tile.WALL)
	grid.set_tile(3, 0, TileGrid.Tile.DOOR)
	grid.set_tile(3, 2, TileGrid.Tile.FLOOR)
	return grid

func _normal_grid() -> TileGrid:
	var grid := TileGrid.new(14, 10, TileGrid.Tile.FLOOR)
	for x in grid.width:
		grid.set_tile(x, 0, TileGrid.Tile.WALL)
		grid.set_tile(x, grid.height - 1, TileGrid.Tile.WALL)
	for y in grid.height:
		grid.set_tile(0, y, TileGrid.Tile.WALL)
		grid.set_tile(grid.width - 1, y, TileGrid.Tile.WALL)
	grid.set_tile(6, 0, TileGrid.Tile.DOOR)
	grid.set_tile(7, 0, TileGrid.Tile.DOOR)
	return grid

func _check_traps_leave_safe_door_path(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	var dummy := Node2D.new()
	root.add_child(dummy)
	var grid := _one_tile_corridor_grid()
	renderer.setup(grid, [], null, dummy, RoomNode.RoomType.EVENT)
	await process_frame
	var trap_tiles := {}
	for child in renderer.get_children():
		if child.is_in_group("room_traps"):
			trap_tiles[renderer.world_to_tile(child.position)] = true
	var doors := grid.door_positions()
	if doors.size() < 2:
		failures.append("corridor test grid should expose two doors")
	elif not _has_safe_path(grid, doors[0], doors[doors.size() - 1], trap_tiles):
		failures.append("trap rooms should leave at least one door path without damage traps")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _one_tile_corridor_grid() -> TileGrid:
	var grid := TileGrid.new(14, 7, TileGrid.Tile.WALL)
	for x in range(1, grid.width - 1):
		grid.set_tile(x, 3, TileGrid.Tile.FLOOR)
	grid.set_tile(0, 3, TileGrid.Tile.DOOR)
	grid.set_tile(grid.width - 1, 3, TileGrid.Tile.DOOR)
	return grid

func _has_safe_path(grid: TileGrid, start: Vector2i, goal: Vector2i, blocked: Dictionary) -> bool:
	if blocked.has(start) or blocked.has(goal):
		return false
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		if p == goal:
			return true
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = p + offset
			if seen.has(n) or blocked.has(n) or not grid.is_walkable_at(n.x, n.y):
				continue
			seen[n] = true
			queue.append(n)
	return false
