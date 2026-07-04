extends SceneTree

const EXPECTED_IDS := [
	"blade_warden",
	"breaker",
	"nightblade",
	"bulwark",
	"arcanist",
	"ranger",
	"gunner",
	"soulbinder",
	"lightkeeper",
	"tinkerer",
]

func _init() -> void:
	var failures: Array[String] = []

	_check_class_data(failures)
	await _check_apply_class(failures)
	await _check_class_select_layout(failures)

	if failures.is_empty():
		print("Ten class roster smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_class_data(failures: Array[String]) -> void:
	var classes := PlayerClassDB.all()
	if classes.size() != EXPECTED_IDS.size():
		failures.append("expected 10 classes, got %d" % classes.size())
	var seen := {}
	for data in classes:
		var id := str(data.get("id", ""))
		seen[id] = true
		for key in ["name", "role", "resource", "stats", "preferred_weapons", "actives", "passives", "ultimate"]:
			if not data.has(key):
				failures.append("%s missing key %s" % [id, key])
		var stats: Dictionary = data.get("stats", {})
		for key in ["hp", "armor", "resource", "speed", "damage", "crit"]:
			if not stats.has(key):
				failures.append("%s stats missing %s" % [id, key])
		if data.get("preferred_weapons", []).is_empty():
			failures.append("%s needs at least one preferred weapon group" % id)
		if data.get("actives", []).size() < 2:
			failures.append("%s needs two active metadata entries" % id)
	for id in EXPECTED_IDS:
		if not seen.has(id):
			failures.append("missing class id %s" % id)

func _check_apply_class(failures: Array[String]) -> void:
	for id in EXPECTED_IDS:
		var player_scene: PackedScene = load("res://scenes/player.tscn")
		var player: Player = player_scene.instantiate()
		root.add_child(player)
		await process_frame
		var data := PlayerClassDB.get_class_data(id)
		if data.is_empty():
			player.free()
			continue
		player.apply_class(data, "fire", "warden_sword")
		if player.class_id != id:
			failures.append("%s did not apply class_id" % id)
		if player.hp <= 0 or player.max_hp <= 0:
			failures.append("%s produced invalid hp" % id)
		if player.current_weapon() == null:
			failures.append("%s did not equip a starter weapon" % id)
		player.free()

func _check_class_select_layout(failures: Array[String]) -> void:
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	var scroll := screen.find_child("ClassScroll", true, false) as ScrollContainer
	var grid := screen.find_child("ClassGrid", true, false) as GridContainer
	if scroll == null:
		failures.append("class select missing ClassScroll")
	if grid == null:
		failures.append("class select missing ClassGrid")
	else:
		var class_buttons := 0
		for child in grid.get_children():
			if child is Button:
				class_buttons += 1
		if class_buttons != EXPECTED_IDS.size():
			failures.append("expected 10 class buttons, got %d" % class_buttons)
	screen.free()
