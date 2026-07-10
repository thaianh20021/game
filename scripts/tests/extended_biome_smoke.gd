extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

class DummyTarget:
	extends Node2D

	func take_damage(_amount: int, _from: Vector2 = Vector2.ZERO) -> void:
		pass

func _init() -> void:
	var failures: Array[String] = []

	_check_floor_four_biome_contract(failures)
	_check_archive_enemy_pool(failures)
	await _check_archive_enemy_sprites(failures)
	await _check_archive_boss_variant(failures)

	if failures.is_empty():
		print("Extended biome smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_floor_four_biome_contract(failures: Array[String]) -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not main_source.contains("const MAX_FLOORS := 4"):
		failures.append("Main should extend normal runs to 4 floors")
	var biome_db: Variant = load("res://scripts/dungeon_gen/biome_db.gd")
	var floor_3: Dictionary = biome_db.floor_biome(3)
	var floor_4: Dictionary = biome_db.floor_biome(4)
	if str(floor_4.get("id", "")) != "crystal_archive":
		failures.append("floor 4 should introduce crystal_archive biome")
	if str(floor_4.get("boss_variant", "")) != "archive_golem":
		failures.append("floor 4 should use archive_golem boss variant")
	if str(floor_4.get("enemy_pool", "")) != "res://data/enemies_crystal_archive.json":
		failures.append("crystal_archive should declare its own enemy pool")
	if float(floor_4.get("enemy_hp_mult", 0.0)) <= float(floor_3.get("enemy_hp_mult", 0.0)):
		failures.append("floor 4 biome should raise enemy hp pressure")
	if float(floor_4.get("enemy_damage_mult", 0.0)) <= float(floor_3.get("enemy_damage_mult", 0.0)):
		failures.append("floor 4 biome should raise enemy damage pressure")
	if str(floor_4.get("shop_min_rarity", "")) != "epic":
		failures.append("floor 4 shop should bias toward epic weapons")
	if float(floor_4.get("locked_chest_chance", 0.0)) <= float(floor_3.get("locked_chest_chance", 0.0)):
		failures.append("floor 4 locked chest chance should continue progression")
	if not bool(floor_4.get("run_finale", false)):
		failures.append("floor 4 should mark crystal_archive as the run finale")

func _check_archive_enemy_pool(failures: Array[String]) -> void:
	var path := "res://data/enemies_crystal_archive.json"
	if not FileAccess.file_exists(path):
		failures.append("crystal_archive enemy pool should exist")
		return
	var pool: Dictionary = EnemySpawner.load_pool(path)
	if str(pool.get("biome", "")) != "crystal_archive":
		failures.append("crystal_archive pool should declare matching biome")
	if _budget_enemy_ids(pool).size() < 8:
		failures.append("crystal_archive should include at least eight budget enemies")
	if str(_find_kind(pool, "miniboss").get("id", "")) != "archive_curator":
		failures.append("crystal_archive should include archive_curator miniboss")
	if str(_find_kind(pool, "boss").get("id", "")) != "archive_golem_boss":
		failures.append("crystal_archive should include archive_golem_boss")
	var room := RoomNode.new()
	room.id = 404
	room.type = RoomNode.RoomType.BOSS
	var plan := EnemySpawner.new().roll_spawn_plan(
		room,
		_basic_grid(),
		SeededRNG.new(4040, 4),
		4,
		1.0,
		pool,
		Vector2i(6, 0))
	if plan.is_empty() or str((plan[0]["enemy"] as Dictionary).get("id", "")) != "archive_golem_boss":
		failures.append("floor 4 boss plan should use archive_golem_boss")
	var combat := RoomNode.new()
	combat.id = 405
	combat.type = RoomNode.RoomType.COMBAT
	var combat_plan := EnemySpawner.new().roll_spawn_plan(
		combat,
		_basic_grid(),
		SeededRNG.new(4040, 5),
		4,
		1.0,
		pool,
		Vector2i(6, 0))
	if combat_plan.is_empty():
		failures.append("crystal_archive combat room should roll a spawn plan")
	for entry in combat_plan:
		var enemy_id := str((entry["enemy"] as Dictionary).get("id", ""))
		if enemy_id.begins_with("forge_") or enemy_id.begins_with("spore_"):
			failures.append("crystal_archive combat should use archive enemies, got %s" % enemy_id)

func _check_archive_enemy_sprites(failures: Array[String]) -> void:
	var scene := Node2D.new()
	var renderer := RoomRenderer.new()
	var target := DummyTarget.new()
	root.add_child(scene)
	scene.add_child(target)
	scene.add_child(renderer)
	var ids_and_kinds := [
		["archive_mite", "melee"],
		["prism_bat", "flyer"],
		["index_lancer", "melee_charger"],
		["glyph_archer", "ranged"],
		["mirror_acolyte", "caster"],
		["crystal_warden", "tanker"],
		["glass_bomber", "exploder"],
		["shelf_stalker", "ambusher"],
		["archive_curator", "miniboss"],
		["archive_golem_boss", "boss"],
	]
	var plan: Array[Dictionary] = []
	for i in ids_and_kinds.size():
		var data: Array = ids_and_kinds[i]
		plan.append({
			"enemy": {"id": str(data[0]), "kind": str(data[1]), "hp": 20, "dmg": 4},
			"wave": 1,
			"tile": Vector2i(2 + i % 9, 2 + i / 9),
			"elite": false,
			"modifier": "",
		})
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, target, RoomNode.RoomType.COMBAT, {}, {
		"id": "crystal_archive",
		"name": "Crystal Archive",
		"boss_variant": "archive_golem",
	})
	await process_frame
	for data in ids_and_kinds:
		var enemy := _first_enemy_id(renderer, str(data[0]))
		if enemy == null:
			failures.append("%s should spawn for sprite check" % str(data[0]))
			continue
		var sprite := enemy.get_node_or_null("Sprite") as AnimatedSprite2D
		var body := enemy.get_node_or_null("Body") as Polygon2D
		if sprite == null or not sprite.visible or sprite.sprite_frames == null:
			failures.append("%s should use a visible DungeonTileset sprite" % str(data[0]))
		if body != null and body.visible:
			failures.append("%s should hide fallback body after sprite setup" % str(data[0]))
	scene.queue_free()
	await process_frame

func _check_archive_boss_variant(failures: Array[String]) -> void:
	var scene := Node2D.new()
	var target := DummyTarget.new()
	var boss := BossGolem.new()
	root.add_child(scene)
	scene.add_child(target)
	scene.add_child(boss)
	await process_frame
	boss.max_hp = 100
	boss.hp = 30
	boss.contact_damage = 12
	boss.target = target
	boss.configure_variant("archive_golem")
	boss.call("_update_phase")
	if str(boss.get_meta("boss_variant", "")) != "archive_golem":
		failures.append("archive boss variant should be stored as metadata")
	if str(boss.call("phase_pattern")).find("archive") == -1:
		failures.append("archive boss phase pattern should include archive prefix")
	var events: Array[Dictionary] = []
	boss.boss_attack_cued.connect(func(status: Dictionary) -> void:
		events.append(status))
	boss.spawn_bullet_hell(4)
	var bullet_event: Dictionary = events.back() if not events.is_empty() else {}
	if bullet_event.is_empty():
		failures.append("archive boss should emit attack cue")
	else:
		if str(bullet_event.get("variant_attack", "")) != "archive_prism":
			failures.append("archive bullet hell should expose archive_prism variant attack")
		if not str(bullet_event.get("variant_warning", "")).contains("Chill"):
			failures.append("archive attack warning should explain chill pressure")
	await process_frame
	if _has_projectile_status(scene, "chilled"):
		failures.append("archive boss projectiles should wait for readable telegraph before chilled shots")
	if _has_projectile_readability(scene, "archive_golem"):
		failures.append("archive boss projectiles should wait for telegraph before readability metadata")
	await _wait_readable_attack_telegraph()
	if not _has_projectile_status(scene, "chilled"):
		failures.append("archive boss projectiles should apply chilled status")
	if not _has_projectile_readability(scene, "archive_golem"):
		failures.append("archive boss projectiles should expose archive readability metadata")
	boss.phase = 2
	boss.summon_phase_traps(2)
	if not _all_group_children_have_variant_attack(boss, "room_traps", "archive_lattice"):
		failures.append("archive trap wave should tag archive_lattice variant attack")
	scene.queue_free()
	await process_frame

func _wait_readable_attack_telegraph() -> void:
	await create_timer(0.55).timeout

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

func _first_enemy_id(parent: Node, enemy_id: String) -> Enemy:
	for child in parent.get_children():
		if child is Enemy and str(child.get_meta("enemy_id", "")) == enemy_id:
			return child
	return null

func _has_projectile_status(parent: Node, status_name: String) -> bool:
	for child in parent.get_children():
		if child is EnemyProjectile and str(child.get_meta("hit_status", "")) == status_name:
			return true
	return false

func _has_projectile_readability(parent: Node, variant_id: String) -> bool:
	for child in parent.get_children():
		if child is EnemyProjectile \
				and str(child.get_meta("boss_projectile_variant", "")) == variant_id \
				and child.has_meta("boss_projectile_color"):
			return true
	return false

func _all_group_children_have_variant_attack(parent: Node, group_name: String, expected: String) -> bool:
	var seen := 0
	for child in parent.get_children():
		if child.is_in_group(group_name):
			seen += 1
			if str(child.get_meta("boss_variant_attack", "")) != expected:
				return false
			if str(child.get_meta("boss_variant_attack_label", "")) == "":
				return false
	return seen > 0
