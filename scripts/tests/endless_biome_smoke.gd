extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

class DummyTarget:
	extends Node2D

	func take_damage(_amount: int, _from: Vector2 = Vector2.ZERO) -> void:
		pass

	func add_status(status_name: String, duration: float) -> void:
		set_meta("status_" + status_name + "_left", duration)

func _init() -> void:
	var failures: Array[String] = []

	_check_endless_biome_contract(failures)
	_check_shadow_enemy_pool(failures)
	await _check_shadow_enemy_sprites(failures)
	await _check_void_boss_variant(failures)
	_check_codex_lists_shadow_biome(failures)

	if failures.is_empty():
		print("Endless biome smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_endless_biome_contract(failures: Array[String]) -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not main_source.contains("const MAX_FLOORS := 4"):
		failures.append("normal run should stay capped at 4 floors while endless extends content")
	var biome_db: Variant = load("res://scripts/dungeon_gen/biome_db.gd")
	if biome_db.BIOMES.size() < 5:
		failures.append("BiomeDB should expose a fifth biome for endless/post-finale runs")
		return
	var floor_4: Dictionary = biome_db.floor_biome(4)
	var floor_5: Dictionary = biome_db.floor_biome(5)
	if str(floor_4.get("id", "")) != "crystal_archive" or not bool(floor_4.get("run_finale", false)):
		failures.append("floor 4 should remain the normal-run finale")
	if str(floor_5.get("id", "")) != "shadow_crypt":
		failures.append("floor 5 should introduce shadow_crypt biome")
	if bool(floor_5.get("run_finale", false)):
		failures.append("shadow_crypt should be endless content, not the normal finale")
	if not bool(floor_5.get("endless_theme", false)):
		failures.append("shadow_crypt should mark itself as endless/post-finale content")
	if str(floor_5.get("boss_variant", "")) != "void_golem":
		failures.append("shadow_crypt should use void_golem boss variant")
	if str(floor_5.get("enemy_pool", "")) != "res://data/enemies_shadow_crypt.json":
		failures.append("shadow_crypt should declare its own enemy pool")
	if float(floor_5.get("enemy_hp_mult", 0.0)) < float(floor_4.get("enemy_hp_mult", 0.0)):
		failures.append("shadow_crypt hp pressure should not regress after crystal_archive")
	if str(floor_5.get("shop_min_rarity", "")) != "epic":
		failures.append("shadow_crypt shop should stay at epic rarity pressure")

func _check_shadow_enemy_pool(failures: Array[String]) -> void:
	var path := "res://data/enemies_shadow_crypt.json"
	if not FileAccess.file_exists(path):
		failures.append("shadow_crypt enemy pool should exist")
		return
	var pool: Dictionary = EnemySpawner.load_pool(path)
	if str(pool.get("biome", "")) != "shadow_crypt":
		failures.append("shadow_crypt pool should declare matching biome")
	if _budget_enemy_ids(pool).size() < 8:
		failures.append("shadow_crypt should include at least eight budget enemies")
	if str(_find_kind(pool, "miniboss").get("id", "")) != "crypt_revenant":
		failures.append("shadow_crypt should include crypt_revenant miniboss")
	if str(_find_kind(pool, "boss").get("id", "")) != "void_golem_boss":
		failures.append("shadow_crypt should include void_golem_boss")
	var room := RoomNode.new()
	room.id = 505
	room.type = RoomNode.RoomType.BOSS
	var plan := EnemySpawner.new().roll_spawn_plan(
		room,
		_basic_grid(),
		SeededRNG.new(5050, 5),
		5,
		1.0,
		pool,
		Vector2i(6, 0))
	if plan.is_empty() or str((plan[0]["enemy"] as Dictionary).get("id", "")) != "void_golem_boss":
		failures.append("shadow_crypt boss plan should use void_golem_boss")

func _check_shadow_enemy_sprites(failures: Array[String]) -> void:
	var scene := Node2D.new()
	var renderer := RoomRenderer.new()
	var target := DummyTarget.new()
	root.add_child(scene)
	scene.add_child(target)
	scene.add_child(renderer)
	var ids_and_kinds := [
		["crypt_rat", "melee"],
		["shade_bat", "flyer"],
		["bone_lancer", "melee_charger"],
		["grave_archer", "ranged"],
		["hex_scribe", "caster"],
		["tomb_guard", "tanker"],
		["soul_bomber", "exploder"],
		["veil_stalker", "ambusher"],
		["crypt_revenant", "miniboss"],
		["void_golem_boss", "boss"],
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
		"id": "shadow_crypt",
		"name": "Shadow Crypt",
		"boss_variant": "void_golem",
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
			failures.append("%s should hide polygon fallback when sprite exists" % str(data[0]))
	scene.queue_free()
	await process_frame

func _check_void_boss_variant(failures: Array[String]) -> void:
	var scene := Node2D.new()
	var target := DummyTarget.new()
	root.add_child(scene)
	scene.add_child(target)
	target.global_position = Vector2(96, 0)
	current_scene = scene
	var boss := BossGolem.new()
	boss.contact_damage = 10
	boss.target = target
	boss.configure_variant("void_golem")
	scene.add_child(boss)
	await process_frame
	boss.max_hp = 100
	boss.hp = 25
	boss.phase = 3
	boss.enraged = true
	var status: Dictionary = boss.boss_status()
	if str(status.get("variant", "")) != "void_golem":
		failures.append("void boss should expose void_golem variant id")
	if str(status.get("next_variant_attack", "")) != "void_collapse":
		failures.append("void boss next attack should expose void_collapse")
	if not str(status.get("next_attack_label", "")).contains("Void"):
		failures.append("void boss attack label should be readable")
	if not str(status.get("next_attack_warning", "")).contains("Curse"):
		failures.append("void boss warning should explain curse pressure")
	if not str(status.get("variant_pressure", "")).contains("Curse"):
		failures.append("void boss pressure should mention curse")
	if not str(status.get("variant_counter_hint", "")).contains("center"):
		failures.append("void boss counter hint should explain centerline dodge timing")
	if str(status.get("variant_status", "")) != "cursed":
		failures.append("void boss projectiles should expose cursed status identity")
	boss.spawn_bullet_hell(4)
	await process_frame
	if _all_projectiles_have_variant_attack(scene, "void_collapse"):
		failures.append("void boss projectiles should wait until telegraph resolves")
	await _wait_readable_attack_telegraph()
	if not _all_projectiles_have_variant_attack(scene, "void_collapse"):
		failures.append("void boss projectiles should tag void_collapse attack")
	if not _has_projectile_status(scene, "cursed"):
		failures.append("void boss projectiles should apply cursed status")
	scene.queue_free()
	await process_frame

func _check_codex_lists_shadow_biome(failures: Array[String]) -> void:
	var biome_db: Variant = load("res://scripts/dungeon_gen/biome_db.gd")
	var summary := str(biome_db.enemy_codex_summary(5))
	for token in ["Shadow Crypt 10", "Void Golem", "Weak light", "Resist dark"]:
		if not summary.contains(token):
			failures.append("enemy codex should include shadow biome token: %s" % token)

func _budget_enemy_ids(pool: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for raw in Array(pool.get("enemies", [])):
		if not (raw is Dictionary):
			continue
		var enemy := raw as Dictionary
		if int(enemy.get("cost", 0)) > 0:
			out.append(str(enemy.get("id", "")))
	return out

func _find_kind(pool: Dictionary, kind: String) -> Dictionary:
	for raw in Array(pool.get("enemies", [])):
		if raw is Dictionary and str((raw as Dictionary).get("kind", "")) == kind:
			return raw as Dictionary
	return {}

func _first_enemy_id(parent: Node, enemy_id: String) -> Enemy:
	for child in parent.get_children():
		var enemy := child as Enemy
		if enemy != null and str(enemy.get_meta("enemy_id", "")) == enemy_id:
			return enemy
	return null

func _all_projectiles_have_variant_attack(parent: Node, expected: String) -> bool:
	var found := false
	for child in parent.get_children():
		if child.get_class() == "Area2D" and child.has_meta("boss_projectile_variant"):
			found = true
			if str(child.get_meta("boss_variant_attack", "")) != expected:
				return false
	return found

func _has_projectile_status(parent: Node, status_name: String) -> bool:
	for child in parent.get_children():
		if child.get_class() == "Area2D" and str(child.get_meta("hit_status", "")) == status_name:
			return true
	return false

func _wait_readable_attack_telegraph() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for _i in 10:
		await tree.create_timer(0.08).timeout

func _basic_grid() -> TileGrid:
	var grid := TileGrid.new(14, 10, TileGrid.Tile.FLOOR)
	for x in grid.width:
		grid.set_tile(x, 0, TileGrid.Tile.WALL)
		grid.set_tile(x, grid.height - 1, TileGrid.Tile.WALL)
	for y in grid.height:
		grid.set_tile(0, y, TileGrid.Tile.WALL)
		grid.set_tile(grid.width - 1, y, TileGrid.Tile.WALL)
	return grid
