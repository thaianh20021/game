extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

class DummyPlayer:
	extends Node2D
	signal hp_changed(current: int, max_value: int)

	var hp := 100
	var max_hp := 100

	func take_damage(amount: int) -> void:
		hp = maxi(hp - amount, 0)
		hp_changed.emit(hp, max_hp)

func _init() -> void:
	var failures: Array[String] = []

	await _check_biome_db(failures)
	_check_distinct_biome_enemy_pools(failures)
	_check_spawner_uses_biome_pool_identity(failures)
	await _check_renderer_biome_application(failures)
	await _check_biome_locked_chest_progression(failures)
	_check_floor_controller_biome_source(failures)

	if failures.is_empty():
		print("Biome progression smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_biome_db(failures: Array[String]) -> void:
	if not ResourceLoader.exists("res://scripts/dungeon_gen/biome_db.gd"):
		failures.append("BiomeDB script missing")
		return
	var biome_db: Variant = load("res://scripts/dungeon_gen/biome_db.gd")
	var floor_1: Dictionary = biome_db.floor_biome(1)
	var floor_2: Dictionary = biome_db.floor_biome(2)
	var floor_3: Dictionary = biome_db.floor_biome(3)
	if str(floor_1.get("id", "")) != "ancient_cave":
		failures.append("floor 1 should use ancient_cave")
	if str(floor_2.get("id", "")) == str(floor_1.get("id", "")):
		failures.append("floor 2 should introduce a different biome")
	if str(floor_3.get("boss_variant", "")) == str(floor_1.get("boss_variant", "")):
		failures.append("later floor should expose a different boss variant")
	for biome in [floor_1, floor_2, floor_3]:
		if str(biome.get("name", "")) == "":
			failures.append("biome should have a display name")
		if str(biome.get("enemy_pool", "")) == "":
			failures.append("biome should declare an enemy pool")

func _check_distinct_biome_enemy_pools(failures: Array[String]) -> void:
	var biome_db: Variant = load("res://scripts/dungeon_gen/biome_db.gd")
	var floor_1: Dictionary = biome_db.floor_biome(1)
	var floor_2: Dictionary = biome_db.floor_biome(2)
	var floor_3: Dictionary = biome_db.floor_biome(3)
	var paths := [
		str(floor_1.get("enemy_pool", "")),
		str(floor_2.get("enemy_pool", "")),
		str(floor_3.get("enemy_pool", "")),
	]
	if paths[0] == paths[1] or paths[1] == paths[2] or paths[0] == paths[2]:
		failures.append("each biome should use a distinct enemy pool file")
	for biome in [floor_1, floor_2, floor_3]:
		var pool_path := str(biome.get("enemy_pool", ""))
		if not FileAccess.file_exists(pool_path):
			failures.append("%s enemy pool should exist" % str(biome.get("id", "")))
			continue
		var pool: Dictionary = EnemySpawner.load_pool(pool_path)
		if str(pool.get("biome", "")) != str(biome.get("id", "")):
			failures.append("%s enemy pool should declare matching biome id" % str(biome.get("id", "")))
		if _budget_enemy_ids(pool).size() < 6:
			failures.append("%s enemy pool should include at least six budget enemies" % str(biome.get("id", "")))
		if _find_kind(pool, "miniboss").is_empty():
			failures.append("%s enemy pool should include a miniboss" % str(biome.get("id", "")))
		if _find_kind(pool, "boss").is_empty():
			failures.append("%s enemy pool should include a boss" % str(biome.get("id", "")))
		if not pool.has("elite_modifiers") or not (pool["elite_modifiers"] is Array) \
				or pool["elite_modifiers"].is_empty():
			failures.append("%s enemy pool should include elite modifiers" % str(biome.get("id", "")))

func _check_spawner_uses_biome_pool_identity(failures: Array[String]) -> void:
	var biome_db: Variant = load("res://scripts/dungeon_gen/biome_db.gd")
	var ancient_ids := _budget_enemy_ids(EnemySpawner.load_pool(
		str(biome_db.floor_biome(1).get("enemy_pool", ""))))
	for floor_index in [2, 3]:
		var biome: Dictionary = biome_db.floor_biome(floor_index)
		var pool := EnemySpawner.load_pool(str(biome.get("enemy_pool", "")))
		var plan := _roll_plan_for_pool(floor_index, pool, RoomNode.RoomType.COMBAT)
		if plan.is_empty():
			failures.append("%s combat room should roll a spawn plan" % str(biome.get("id", "")))
			continue
		for entry in plan:
			var enemy_id := str((entry["enemy"] as Dictionary).get("id", ""))
			if ancient_ids.has(enemy_id):
				failures.append("%s combat plan should not reuse ancient cave enemy %s" % [
					str(biome.get("id", "")), enemy_id])
	var floor2_pool := EnemySpawner.load_pool(str(biome_db.floor_biome(2).get("enemy_pool", "")))
	var floor3_pool := EnemySpawner.load_pool(str(biome_db.floor_biome(3).get("enemy_pool", "")))
	var floor2_boss := _roll_plan_for_pool(2, floor2_pool, RoomNode.RoomType.BOSS)
	var floor3_miniboss := _roll_plan_for_pool(3, floor3_pool, RoomNode.RoomType.MINIBOSS)
	if floor2_boss.is_empty() or str((floor2_boss[0]["enemy"] as Dictionary).get("id", "")) != "spore_golem_boss":
		failures.append("floor 2 boss room should use fungal biome boss")
	if floor3_miniboss.is_empty() or str((floor3_miniboss[0]["enemy"] as Dictionary).get("id", "")) != "forge_captain":
		failures.append("floor 3 miniboss room should use ember forge miniboss")

func _check_renderer_biome_application(failures: Array[String]) -> void:
	if not ResourceLoader.exists("res://scripts/dungeon_gen/biome_db.gd"):
		return
	var biome_db: Variant = load("res://scripts/dungeon_gen/biome_db.gd")
	var biome: Dictionary = biome_db.floor_biome(2)
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [
		{
			"enemy": {"id": "smoke_melee", "kind": "melee", "hp": 10, "dmg": 2},
			"wave": 1,
			"tile": Vector2i(4, 4),
			"elite": false,
			"modifier": "",
		},
	]
	renderer.callv("setup", [_basic_grid(), plan, ENEMY_SCENE, dummy,
		RoomNode.RoomType.COMBAT, {}, biome])
	await process_frame
	if str(renderer.get_meta("biome", "")) != str(biome.get("id", "")):
		failures.append("renderer should store active biome metadata")
	if renderer.modulate == Color.WHITE:
		failures.append("renderer should tint room by biome")
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("biome smoke should spawn enemy")
	else:
		if str(enemy.get_meta("biome", "")) != str(biome.get("id", "")):
			failures.append("enemy should store biome metadata")
		if enemy.max_hp <= 10:
			failures.append("biome should scale enemy hp")
		if enemy.contact_damage <= 2:
			failures.append("biome should scale enemy damage")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_biome_locked_chest_progression(failures: Array[String]) -> void:
	var biome_db: Variant = load("res://scripts/dungeon_gen/biome_db.gd")
	var floor_1: Dictionary = biome_db.floor_biome(1)
	var floor_2: Dictionary = biome_db.floor_biome(2)
	var floor_3: Dictionary = biome_db.floor_biome(3)
	if float(floor_2.get("locked_chest_chance", 0.0)) <= float(floor_1.get("locked_chest_chance", 0.0)):
		failures.append("later biomes should increase optional locked chest chance")
	if float(floor_3.get("locked_chest_chance", 0.0)) < float(floor_2.get("locked_chest_chance", 0.0)):
		failures.append("floor 3 locked chest chance should not regress")
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var forced := floor_2.duplicate(true)
	forced["locked_chest_chance"] = 1.0
	renderer.setup(_basic_grid(), [], ENEMY_SCENE, dummy, RoomNode.RoomType.COMBAT, {}, forced)
	await process_frame
	if not _has_interactable_kind(renderer, "locked_chest"):
		failures.append("biome locked chest chance should spawn optional locked chests")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_floor_controller_biome_source(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/rooms/floor_controller.gd")
	if not source.contains("BiomeDB"):
		failures.append("FloorController should select a biome per floor")
	if not source.contains("current_biome_label"):
		failures.append("FloorController should expose current_biome_label for HUD")

func _basic_grid() -> TileGrid:
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

func _first_enemy(parent: Node) -> Enemy:
	for child in parent.get_children():
		if child is Enemy:
			return child
	return null

func _has_interactable_kind(parent: Node, kind: String) -> bool:
	for child in parent.get_children():
		if child is RoomInteractable and str(child.kind) == kind:
			return true
	return false

func _roll_plan_for_pool(floor_index: int, pool: Dictionary, room_type: int) -> Array[Dictionary]:
	var room := RoomNode.new()
	room.id = 99 + floor_index
	room.type = room_type
	return EnemySpawner.new().roll_spawn_plan(
		room,
		_basic_grid(),
		SeededRNG.new(9001, floor_index),
		floor_index,
		1.0,
		pool,
		Vector2i(6, 0))

func _budget_enemy_ids(pool: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for enemy in pool.get("enemies", []):
		if float(enemy.get("cost", 0.0)) > 0.0:
			ids.append(str(enemy.get("id", "")))
	return ids

func _find_kind(pool: Dictionary, kind: String) -> Dictionary:
	for enemy in pool.get("enemies", []):
		if str(enemy.get("kind", "")) == kind:
			return enemy
	return {}
