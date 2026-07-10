extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

class DummyPlayer:
	extends Node2D
	func take_damage(_amount: int) -> void:
		pass

func _init() -> void:
	var failures: Array[String] = []

	await _check_renderer_pity_context_and_reset(failures)
	_check_floor_controller_stores_pity(failures)
	await _check_floor_pity_summary_and_hud(failures)
	await process_frame
	await process_frame

	if failures.is_empty():
		print("Loot pity run smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_renderer_pity_context_and_reset(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var pity_updates: Array[int] = []
	if not renderer.has_signal("loot_pity_changed"):
		failures.append("renderer should emit loot_pity_changed")
		renderer.queue_free()
		dummy.queue_free()
		await process_frame
		return
	renderer.connect("loot_pity_changed", func(count: int) -> void:
		pity_updates.append(count))
	var plan: Array[Dictionary] = [
		{
			"enemy": {"id": "pity_miniboss", "kind": "miniboss", "cost": 0, "hp": 5, "dmg": 1},
			"wave": 1,
			"tile": Vector2i(4, 4),
			"elite": false,
			"modifier": "",
		},
	]
	renderer.callv("setup", [_basic_grid(), plan, ENEMY_SCENE, dummy,
		RoomNode.RoomType.MINIBOSS, {}, {}, 10])
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("pity smoke should spawn miniboss")
	else:
		enemy.take_damage(999)
	await process_frame
	await process_frame
	if pity_updates.is_empty() or int(pity_updates.back()) != 0:
		failures.append("rare+ weapon drop should reset run pity")
	var found_rare_plus := false
	for pickup in renderer.get_children():
		if pickup is Pickup and str(pickup.data.get("type", "")) == "weapon":
			var rarity := str(WeaponDB.get_weapon(str(pickup.data.get("id", ""))).get("rarity", "common"))
			found_rare_plus = _rarity_rank(rarity) >= _rarity_rank("rare")
	if not found_rare_plus:
		failures.append("pity context should force a rare+ pickup in-room")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_floor_controller_stores_pity(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/rooms/floor_controller.gd")
	if not source.contains("loot_pity_rooms_without_rare_plus"):
		failures.append("FloorController should store run loot pity")
	if not source.contains("loot_pity_changed"):
		failures.append("FloorController should listen to renderer pity updates")

func _check_floor_pity_summary_and_hud(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	ctrl.rooms = GraphBuilder.new().build(2026, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.ENTRANCE)
	ctrl.call("_record_room_visit", ctrl.current_room)
	ctrl.loot_pity_rooms_without_rare_plus = 3
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	hud.bind(player, ctrl)
	await process_frame

	if not ctrl.has_method("loot_pity_threshold"):
		failures.append("FloorController should expose loot_pity_threshold")
	if not ctrl.has_method("loot_pity_summary"):
		failures.append("FloorController should expose loot_pity_summary")
	if ctrl.has_method("loot_pity_threshold") and int(ctrl.call("loot_pity_threshold")) != 10:
		failures.append("FloorController pity threshold should come from loot_tables.json")
	if ctrl.has_method("loot_pity_summary") \
			and str(ctrl.call("loot_pity_summary")) != "Rare pity: 3/10":
		failures.append("FloorController pity summary should show current progress")

	var label := hud.get_node_or_null("LootPityLabel") as Label
	if label == null:
		failures.append("HUD should expose a loot pity label")
	else:
		if not label.text.contains("Rare pity: 3/10"):
			failures.append("HUD loot pity label should show pity progress")
		if int(label.get_meta("pity_rooms_without_rare_plus", -1)) != 3:
			failures.append("HUD loot pity label should store pity progress metadata")
		if int(label.get_meta("pity_threshold", -1)) != 10:
			failures.append("HUD loot pity label should store pity threshold metadata")
		if bool(label.get_meta("rare_plus_guaranteed", true)):
			failures.append("HUD loot pity label should not mark rare+ guaranteed before threshold")

	ctrl.loot_pity_rooms_without_rare_plus = 10
	await process_frame
	if ctrl.has_method("loot_pity_summary") \
			and str(ctrl.call("loot_pity_summary")) != "Rare+ guaranteed next drop":
		failures.append("FloorController pity summary should announce guarantee at threshold")
	if label != null:
		if not label.text.contains("Rare+ guaranteed next drop"):
			failures.append("HUD loot pity label should announce guaranteed rare+ drop")
		if not bool(label.get_meta("rare_plus_guaranteed", false)):
			failures.append("HUD loot pity label should mark rare+ guaranteed at threshold")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _first_enemy(parent: Node) -> Enemy:
	for child in parent.get_children():
		if child is Enemy:
			return child
	return null

func _first_room_of_type(rooms: Array[RoomNode], room_type: int) -> RoomNode:
	for room in rooms:
		if room.type == room_type:
			return room
	return rooms[0]

func _rarity_rank(rarity: String) -> int:
	return ["common", "uncommon", "rare", "epic", "legendary", "mythic"].find(rarity)

func _basic_grid() -> TileGrid:
	var grid := TileGrid.new(12, 8, TileGrid.Tile.FLOOR)
	for x in grid.width:
		grid.set_tile(x, 0, TileGrid.Tile.WALL)
		grid.set_tile(x, grid.height - 1, TileGrid.Tile.WALL)
	for y in grid.height:
		grid.set_tile(0, y, TileGrid.Tile.WALL)
		grid.set_tile(grid.width - 1, y, TileGrid.Tile.WALL)
	grid.set_tile(5, 0, TileGrid.Tile.DOOR)
	grid.set_tile(6, 0, TileGrid.Tile.DOOR)
	return grid
