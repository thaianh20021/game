extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	_check_boss_pool_api(failures)
	await _check_floor_controller_uses_picker(failures)
	if failures.is_empty():
		print("Biome boss picker smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_boss_pool_api(failures: Array[String]) -> void:
	var biome_db: Variant = load("res://scripts/dungeon_gen/biome_db.gd")
	if not biome_db.has_method("boss_variant_for_run"):
		failures.append("BiomeDB should expose boss_variant_for_run for deterministic boss pool selection")
		return
	for floor_index in range(1, 5):
		var biome: Dictionary = biome_db.floor_biome(floor_index)
		var pool: Array = biome.get("boss_pool", [])
		if pool.size() < 2 or pool.size() > 3:
			failures.append("%s should expose a 2-3 entry boss_pool" % str(biome.get("id", "")))
			continue
		if not pool.has(str(biome.get("boss_variant", ""))):
			failures.append("%s boss_pool should include its default boss_variant" % str(biome.get("id", "")))
		var first := str(biome_db.boss_variant_for_run(biome, 20260705, floor_index))
		var again := str(biome_db.boss_variant_for_run(biome, 20260705, floor_index))
		if first == "" or first != again:
			failures.append("%s boss picker should be deterministic for seed/floor" % str(biome.get("id", "")))
		if not pool.has(first):
			failures.append("%s boss picker should return a variant from boss_pool" % str(biome.get("id", "")))
		var avoided := str(biome_db.boss_variant_for_run(biome, 20260705, floor_index, [first]))
		if pool.size() > 1 and avoided == first:
			failures.append("%s boss picker should avoid the recently fought boss when alternatives exist" % str(biome.get("id", "")))
		if avoided != "" and not pool.has(avoided):
			failures.append("%s avoided boss picker result should still come from boss_pool" % str(biome.get("id", "")))

func _check_floor_controller_uses_picker(failures: Array[String]) -> void:
	var biome_db: Variant = load("res://scripts/dungeon_gen/biome_db.gd")
	if not biome_db.has_method("boss_variant_for_run"):
		return
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := Player.new()
	scene.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	var ctrl := FloorController.new()
	scene.add_child(ctrl)
	var seed := 424242
	ctrl.start(seed, 1, player)
	await process_frame
	var expected_first := str(biome_db.boss_variant_for_run(biome_db.floor_biome(1), seed, 1))
	if str(ctrl.current_biome.get("boss_variant", "")) != expected_first:
		failures.append("FloorController should store the picked floor boss variant in current_biome")
	ctrl.start(seed, 2, player)
	await process_frame
	var expected_second := str(biome_db.boss_variant_for_run(
		biome_db.floor_biome(2), seed, 2, [expected_first]))
	if str(ctrl.current_biome.get("boss_variant", "")) != expected_second:
		failures.append("FloorController should pass recent boss history into the picker")
	scene.queue_free()
	await process_frame
