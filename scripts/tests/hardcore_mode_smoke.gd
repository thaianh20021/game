extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")

func _init() -> void:
	var failures: Array[String] = []
	await _check_class_select_hardcore(failures)
	_check_main_hardcore_mode(failures)
	_check_main_hardcore_rewards(failures)
	_check_floor_hardcore_mode(failures)
	_check_meta_records_hardcore(failures)
	_check_hardcore_summary_text(failures)

	if failures.is_empty():
		print("Hardcore mode smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_class_select_hardcore(failures: Array[String]) -> void:
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame

	var hardcore_button := screen.find_child("RunMode_Hardcore", true, false) as Button
	if hardcore_button == null:
		failures.append("class select should expose Hardcore mode button")
	else:
		if str(hardcore_button.text) != "Hardcore":
			failures.append("Hardcore button should use readable label")
		if str(hardcore_button.get_meta("run_mode_id", "")) != "hardcore":
			failures.append("Hardcore button should expose hardcore mode id metadata")
		if str(hardcore_button.get_meta("run_mode_key_label", "")) != "C":
			failures.append("Hardcore button should expose C key label")
		if int(hardcore_button.get_meta("run_mode_hotkey", 0)) != KEY_C:
			failures.append("Hardcore button should expose C hotkey metadata")
		hardcore_button.emit_signal("pressed")
		await process_frame
		if str(screen.call("selected_run_mode")) != "hardcore":
			failures.append("Hardcore button should select hardcore mode")
		var start_button := screen.find_child("StartRunButton", true, false) as Button
		if start_button == null:
			failures.append("class select should expose a start button")
		elif not start_button.text.contains("HARDCORE"):
			failures.append("Hardcore selection should update the start button label")

	screen = ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	_press_key(screen, KEY_C)
	await process_frame
	if str(screen.call("selected_run_mode")) != "hardcore":
		failures.append("C hotkey should select Hardcore mode")
	var emitted := {"mode": ""}
	screen.confirmed.connect(func(_class_id: String, _element: String, _seed: int, mode: String) -> void:
		emitted["mode"] = mode)
	screen.set("_selected_class", "blade_warden")
	screen.set("_selected_element", "fire")
	screen.call("_on_start")
	await process_frame
	if str(emitted["mode"]) != "hardcore":
		failures.append("class select should emit hardcore run mode")
	if is_instance_valid(screen):
		screen.queue_free()
	await process_frame

func _check_main_hardcore_mode(failures: Array[String]) -> void:
	var script: GDScript = load("res://scripts/main.gd")
	var main: Node = script.new()
	if str(main.call("_normalized_run_mode", "hardcore")) != "hardcore":
		failures.append("Main should accept hardcore run mode")
	if str(main.call("_normalized_run_mode", "unknown")) != "normal":
		failures.append("Main should still normalize unknown modes to normal")
	main.set("_run_mode", "hardcore")
	if str(main.call("_run_mode_label")) != "Hardcore":
		failures.append("Main should label hardcore run mode")
	if bool(main.call("_run_continues_after_floor_cap")):
		failures.append("Hardcore should keep the normal floor cap")
	main.free()

func _check_main_hardcore_rewards(failures: Array[String]) -> void:
	var script: GDScript = load("res://scripts/main.gd")
	var main: Node = script.new()
	var player := Player.new()
	player.gold = 20
	player.rune_dust = 1
	main.set("player", player)
	main.set("_run_mode", "hardcore")
	var rewards: Dictionary = main.call("_run_rewards_for_banking", 4)
	if int(rewards.get("rune_dust", 0)) != 5:
		failures.append("Hardcore floor 4 should add Dust +4 to banked rewards")
	if int(rewards.get("soul_shards", 0)) != 1:
		failures.append("Hardcore floor 4 should add Shard +1 to banked rewards")
	if str(rewards.get("hardcore_clear_bonus", "")) != "Floor 4: Dust +4 / Shard +1":
		failures.append("Hardcore rewards should include readable bonus summary")
	player.free()
	main.free()

func _check_floor_hardcore_mode(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	if str(ctrl.call("_normalized_run_mode", "hardcore")) != "hardcore":
		failures.append("FloorController should accept hardcore run mode")
	var normal_floor_1 := float(ctrl.call("run_difficulty_multiplier", "normal", 1))
	var hardcore_floor_1 := float(ctrl.call("run_difficulty_multiplier", "hardcore", 1))
	var hardcore_floor_4 := float(ctrl.call("run_difficulty_multiplier", "hardcore", 4))
	var endless_floor_4 := float(ctrl.call("run_difficulty_multiplier", "endless", 4))
	if not is_equal_approx(normal_floor_1, 1.0):
		failures.append("normal floor 1 should keep base difficulty")
	if hardcore_floor_1 <= normal_floor_1:
		failures.append("hardcore difficulty should start above normal")
	if hardcore_floor_4 <= hardcore_floor_1:
		failures.append("hardcore difficulty should scale by floor")
	if hardcore_floor_4 >= endless_floor_4:
		failures.append("hardcore floor 4 should stay below endless pressure")
	ctrl.run_mode = "hardcore"
	ctrl.floor_index = 4
	ctrl.current_biome = {"run_finale": true}
	var boss := RoomNode.new()
	boss.type = RoomNode.RoomType.BOSS
	ctrl.current_room = boss
	var objective := ctrl.current_room_objective()
	if not objective.contains("final boss") and not objective.contains("Final boss"):
		failures.append("Hardcore floor cap should still use normal finale objective")
	ctrl.queue_free()

func _check_meta_records_hardcore(failures: Array[String]) -> void:
	var path := "user://hardcore_mode_meta_smoke.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var data: Dictionary = MetaProgressionScript.bank_run_rewards(
		{"gold": 20, "floor": 4, "hardcore_clear_bonus": "Floor 4: Dust +4 / Shard +1"},
		"victory",
		path,
		{
			"seed": 20260707,
			"seed_label": "Seed",
			"class_id": "blade_warden",
			"class": "Blade Warden",
			"element": "fire",
			"mode": "Hardcore",
			"path": "Path: Entrance -> Combat -> Boss",
		})
	var record: Dictionary = Dictionary(data.get("mode_records", {})).get("hardcore", {})
	if record.is_empty():
		failures.append("Meta progression should record Hardcore mode")
	else:
		if str(record.get("label", "")) != "Hardcore":
			failures.append("Hardcore mode record should keep readable label")
		if int(record.get("victories", 0)) != 1:
			failures.append("Hardcore mode record should count victories")
	var last_rewards: Dictionary = data.get("last_rewards", {})
	if str(last_rewards.get("hardcore_clear_bonus", "")) != "Floor 4: Dust +4 / Shard +1":
		failures.append("Meta progression should persist Hardcore bonus summary")
	var recent_runs: Array = data.get("recent_runs", [])
	if recent_runs.is_empty() \
			or str(Dictionary(recent_runs[0]).get("hardcore_clear_bonus", "")) \
					!= "Floor 4: Dust +4 / Shard +1":
		failures.append("Recent run should store Hardcore bonus summary")
	DirAccess.remove_absolute(path)

func _check_hardcore_summary_text(failures: Array[String]) -> void:
	var script: GDScript = load("res://scripts/ui/run_summary.gd")
	var meta := MetaProgressionScript.default_data()
	meta["last_rewards"] = {
		"gold": 20,
		"rune_dust": 4,
		"soul_shards": 1,
		"hardcore_clear_bonus": "Floor 4: Dust +4 / Shard +1",
	}
	var message := str(script.call("end_message", "victory", 4, {"gold": 20}, meta, {
		"seed": 20260707,
		"mode": "Hardcore",
		"run_finale": true,
	}))
	if not message.contains("Mode: Hardcore"):
		failures.append("Hardcore run summary should show Hardcore mode")
	if not message.contains("Hardcore Bonus Floor 4: Dust +4 / Shard +1"):
		failures.append("Hardcore run summary should show bonus summary")

func _press_key(screen: ClassSelectScreen, keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	screen.call("_unhandled_input", event)
