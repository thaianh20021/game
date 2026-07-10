extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	_check_daily_seed_fingerprint_contract(failures)
	if failures.is_empty():
		print("Daily seed determinism smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_daily_seed_fingerprint_contract(failures: Array[String]) -> void:
	var script: Variant = load("res://scripts/rooms/floor_controller.gd")
	if not script.has_method("daily_seed_fingerprint"):
		failures.append("FloorController should expose daily_seed_fingerprint for Daily Seed QA/share checks")
		return
	var first: Dictionary = script.call("daily_seed_fingerprint", 20260705, 2, "normal")
	var again: Dictionary = script.call("daily_seed_fingerprint", 20260705, 2, "normal")
	if first != again:
		failures.append("daily seed fingerprint should be stable for same seed/floor/mode")
	if str(first.get("mode", "")) != "normal" or int(first.get("seed", 0)) != 20260705:
		failures.append("daily seed fingerprint should preserve seed and mode")
	if str(first.get("hash", "")) == "":
		failures.append("daily seed fingerprint should expose a compact hash")
	if int(first.get("room_count", 0)) <= 0:
		failures.append("daily seed fingerprint should count generated rooms")
	if str(first.get("biome_id", "")) == "" or str(first.get("boss_variant", "")) == "":
		failures.append("daily seed fingerprint should include biome and boss variant")
	var rooms: Array = first.get("rooms", [])
	if rooms.is_empty():
		failures.append("daily seed fingerprint should include room entries")
	else:
		var room: Dictionary = rooms[0]
		for key in ["id", "type", "depth", "critical", "doors", "spawns"]:
			if not room.has(key):
				failures.append("daily seed fingerprint room missing %s" % key)
	var spawn_room_count := int(first.get("spawn_room_count", 0))
	if spawn_room_count <= 0:
		failures.append("daily seed fingerprint should include at least one spawn-bearing room")
	var different_seed: Dictionary = script.call("daily_seed_fingerprint", 20260706, 2, "normal")
	if str(different_seed.get("hash", "")) == str(first.get("hash", "")):
		failures.append("different daily seeds should usually produce different map/spawn fingerprints")
	var boss_rush: Dictionary = script.call("daily_seed_fingerprint", 20260705, 2, "boss_rush")
	if str(boss_rush.get("mode", "")) != "boss_rush" or int(boss_rush.get("room_count", 0)) != 3:
		failures.append("boss rush daily seed fingerprint should use the boss rush graph")
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := Player.new()
	scene.add_child(player)
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	var ctrl := FloorController.new()
	scene.add_child(ctrl)
	ctrl.start(20260705, 1, player)
	if not ctrl.has_method("current_floor_fingerprint"):
		failures.append("FloorController should expose current_floor_fingerprint for run summary")
	else:
		var current: Dictionary = ctrl.call("current_floor_fingerprint")
		if str(current.get("hash", "")) == "":
			failures.append("current floor fingerprint should expose a compact hash")
		if str(current.get("boss_variant", "")) != str(ctrl.current_biome.get("boss_variant", "")):
			failures.append("current floor fingerprint should use the actually selected boss variant")
	scene.queue_free()
