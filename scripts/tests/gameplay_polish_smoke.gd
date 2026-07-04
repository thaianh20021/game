extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	await _check_door_markers(failures)
	await _check_enemy_feedback(failures)
	_check_tile_polish(failures)

	if failures.is_empty():
		print("Gameplay polish smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_door_markers(failures: Array[String]) -> void:
	if not ResourceLoader.exists("res://scripts/rooms/door_marker.gd"):
		failures.append("DoorMarker script missing")
		return
	if DoorMarker.label_for_type(RoomNode.RoomType.BOSS) != "BOSS":
		failures.append("boss door marker label should be BOSS")
	if DoorMarker.label_for_type(RoomNode.RoomType.TREASURE) != "LOOT":
		failures.append("treasure door marker label should be LOOT")

	var grid := TileGrid.new(7, 7, TileGrid.Tile.FLOOR)
	for x in grid.width:
		grid.set_tile(x, 0, TileGrid.Tile.WALL)
		grid.set_tile(x, grid.height - 1, TileGrid.Tile.WALL)
	for y in grid.height:
		grid.set_tile(0, y, TileGrid.Tile.WALL)
		grid.set_tile(grid.width - 1, y, TileGrid.Tile.WALL)
	grid.set_tile(3, 0, TileGrid.Tile.DOOR)
	grid.set_tile(6, 3, TileGrid.Tile.DOOR)

	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	renderer.setup(grid, [], null, null)
	if not renderer.has_method("show_door_markers"):
		failures.append("RoomRenderer missing show_door_markers")
		renderer.free()
		return
	renderer.call("show_door_markers", {
		RoomStamper.Dir.NORTH: RoomNode.RoomType.BOSS,
		RoomStamper.Dir.EAST: RoomNode.RoomType.TREASURE,
	})
	await process_frame
	var marker_count := get_nodes_in_group("door_markers").size()
	if marker_count != 2:
		failures.append("expected 2 door markers, got %d" % marker_count)
	renderer.free()


func _check_enemy_feedback(failures: Array[String]) -> void:
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy: Enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.max_hp = 20
	enemy.hp = 20
	enemy.take_damage(5)
	await process_frame
	if enemy.get_node_or_null("HpBar") == null:
		failures.append("enemy damage should create HpBar")
	if enemy.get_node_or_null("DamageNumber") == null:
		failures.append("enemy damage should create DamageNumber")
	await create_timer(0.45).timeout
	enemy.free()


func _check_tile_polish(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	if not renderer.has_method("wall_sprite_name_for_tile"):
		failures.append("RoomRenderer missing wall_sprite_name_for_tile")
		renderer.free()
		return
	var grid := TileGrid.new(3, 3, TileGrid.Tile.FLOOR)
	grid.set_tile(1, 1, TileGrid.Tile.WALL)
	var sprite_name := str(renderer.call("wall_sprite_name_for_tile", grid, 1, 1))
	if sprite_name == "":
		failures.append("wall sprite helper should return a sprite name")
	renderer.free()
