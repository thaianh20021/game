extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const RunSummaryScript := preload("res://scripts/ui/run_summary.gd")

func _init() -> void:
	var failures: Array[String] = []
	await _check_class_select_elemental_chaos(failures)
	_check_main_elemental_chaos_mode(failures)
	_check_main_elemental_chaos_rewards(failures)
	_check_floor_elemental_chaos_mode(failures)
	_check_meta_records_elemental_chaos(failures)
	_check_elemental_chaos_summary_text(failures)
	await _check_room_clear_element_shift(failures)

	if failures.is_empty():
		print("Elemental Chaos mode smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_class_select_elemental_chaos(failures: Array[String]) -> void:
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame

	var chaos_button := screen.find_child("RunMode_ElementalChaos", true, false) as Button
	if chaos_button == null:
		failures.append("class select should expose Elemental Chaos mode button")
	else:
		if str(chaos_button.text) != "Elemental Chaos":
			failures.append("Elemental Chaos button should use readable label")
		if str(chaos_button.get_meta("run_mode_id", "")) != "elemental_chaos":
			failures.append("Elemental Chaos button should expose elemental_chaos mode id metadata")
		if str(chaos_button.get_meta("run_mode_key_label", "")) != "O":
			failures.append("Elemental Chaos button should expose O key label")
		if int(chaos_button.get_meta("run_mode_hotkey", 0)) != KEY_O:
			failures.append("Elemental Chaos button should expose O hotkey metadata")
		chaos_button.emit_signal("pressed")
		await process_frame
		if str(screen.call("selected_run_mode")) != "elemental_chaos":
			failures.append("Elemental Chaos button should select elemental_chaos mode")
		var start_button := screen.find_child("StartRunButton", true, false) as Button
		if start_button == null:
			failures.append("class select should expose a start button")
		elif not start_button.text.contains("ELEMENTAL CHAOS"):
			failures.append("Elemental Chaos selection should update the start button label")

	screen = ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	_press_key(screen, KEY_O)
	await process_frame
	if str(screen.call("selected_run_mode")) != "elemental_chaos":
		failures.append("O hotkey should select Elemental Chaos mode")
	var emitted := {"mode": ""}
	screen.confirmed.connect(func(_class_id: String, _element: String, _seed: int, mode: String) -> void:
		emitted["mode"] = mode)
	screen.set("_selected_class", "blade_warden")
	screen.set("_selected_element", "fire")
	screen.call("_on_start")
	await process_frame
	if str(emitted["mode"]) != "elemental_chaos":
		failures.append("class select should emit elemental_chaos run mode")
	if is_instance_valid(screen):
		screen.queue_free()
	await process_frame

func _check_main_elemental_chaos_mode(failures: Array[String]) -> void:
	var script: GDScript = load("res://scripts/main.gd")
	var main: Node = script.new()
	if str(main.call("_normalized_run_mode", "elemental_chaos")) != "elemental_chaos":
		failures.append("Main should accept elemental_chaos run mode")
	main.set("_run_mode", "elemental_chaos")
	if str(main.call("_run_mode_label")) != "Elemental Chaos":
		failures.append("Main should label elemental_chaos run mode")
	if bool(main.call("_run_continues_after_floor_cap")):
		failures.append("Elemental Chaos should keep the normal floor cap")
	main.free()

func _check_main_elemental_chaos_rewards(failures: Array[String]) -> void:
	var script: GDScript = load("res://scripts/main.gd")
	var main: Node = script.new()
	var player := Player.new()
	player.gold = 20
	player.element_cores = 1
	main.set("player", player)
	main.set("_run_mode", "elemental_chaos")
	var rewards: Dictionary = main.call("_run_rewards_for_banking", 4)
	if int(rewards.get("element_cores", 0)) != 5:
		failures.append("Elemental Chaos floor 4 should add Core +4 to banked rewards")
	if int(rewards.get("rune_dust", 0)) != 1:
		failures.append("Elemental Chaos floor 4 should add Dust +1 to banked rewards")
	if str(rewards.get("elemental_chaos_bonus", "")) != "Floor 4: Core +4 / Dust +1":
		failures.append("Elemental Chaos rewards should include readable bonus summary")
	player.free()
	main.free()

func _check_floor_elemental_chaos_mode(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	if str(ctrl.call("_normalized_run_mode", "elemental_chaos")) != "elemental_chaos":
		failures.append("FloorController should accept elemental_chaos run mode")
	var normal_floor_2 := float(ctrl.call("run_difficulty_multiplier", "normal", 2))
	var chaos_floor_2 := float(ctrl.call("run_difficulty_multiplier", "elemental_chaos", 2))
	var chaos_floor_4 := float(ctrl.call("run_difficulty_multiplier", "elemental_chaos", 4))
	var hardcore_floor_4 := float(ctrl.call("run_difficulty_multiplier", "hardcore", 4))
	if chaos_floor_2 <= normal_floor_2:
		failures.append("Elemental Chaos difficulty should start above normal")
	if chaos_floor_4 <= chaos_floor_2:
		failures.append("Elemental Chaos difficulty should scale by floor")
	if chaos_floor_4 >= hardcore_floor_4:
		failures.append("Elemental Chaos should stay lighter than Hardcore")
	ctrl.run_mode = "elemental_chaos"
	ctrl.floor_index = 4
	ctrl.current_biome = {"run_finale": true}
	var boss := RoomNode.new()
	boss.type = RoomNode.RoomType.BOSS
	ctrl.current_room = boss
	var objective := ctrl.current_room_objective()
	if not objective.contains("final boss") and not objective.contains("Final boss"):
		failures.append("Elemental Chaos floor cap should still use normal finale objective")
	ctrl.queue_free()

func _check_meta_records_elemental_chaos(failures: Array[String]) -> void:
	var path := "user://elemental_chaos_meta_smoke.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var data: Dictionary = MetaProgressionScript.bank_run_rewards(
		{"gold": 20, "floor": 4, "element_cores": 4, "rune_dust": 1,
			"elemental_chaos_bonus": "Floor 4: Core +4 / Dust +1"},
		"victory",
		path,
		{
			"seed": 20260707,
			"seed_label": "Seed",
			"class_id": "arcanist",
			"class": "Arcanist",
			"element": "fire",
			"mode": "Elemental Chaos",
			"path": "Path: Entrance -> Combat -> Boss",
		})
	var record: Dictionary = Dictionary(data.get("mode_records", {})).get("elemental_chaos", {})
	if record.is_empty():
		failures.append("Meta progression should record Elemental Chaos mode")
	else:
		if str(record.get("label", "")) != "Elemental Chaos":
			failures.append("Elemental Chaos mode record should keep readable label")
		if int(record.get("victories", 0)) != 1:
			failures.append("Elemental Chaos mode record should count victories")
	var last_rewards: Dictionary = data.get("last_rewards", {})
	if str(last_rewards.get("elemental_chaos_bonus", "")) != "Floor 4: Core +4 / Dust +1":
		failures.append("Meta progression should persist Elemental Chaos bonus summary")
	var recent_runs: Array = data.get("recent_runs", [])
	if recent_runs.is_empty() \
			or str(Dictionary(recent_runs[0]).get("elemental_chaos_bonus", "")) \
					!= "Floor 4: Core +4 / Dust +1":
		failures.append("Recent run should store Elemental Chaos bonus summary")
	DirAccess.remove_absolute(path)

func _check_elemental_chaos_summary_text(failures: Array[String]) -> void:
	var meta := MetaProgressionScript.default_data()
	meta["last_rewards"] = {
		"gold": 20,
		"element_cores": 4,
		"rune_dust": 1,
		"elemental_chaos_bonus": "Floor 4: Core +4 / Dust +1",
	}
	var message := RunSummaryScript.end_message("victory", 4, {"gold": 20}, meta, {
		"seed": 20260707,
		"mode": "Elemental Chaos",
		"run_finale": true,
	})
	if not message.contains("Mode: Elemental Chaos"):
		failures.append("Elemental Chaos run summary should show Elemental Chaos mode")
	if not message.contains("Elemental Chaos Bonus Floor 4: Core +4 / Dust +1"):
		failures.append("Elemental Chaos run summary should show bonus summary")

func _check_room_clear_element_shift(failures: Array[String]) -> void:
	var script: GDScript = load("res://scripts/main.gd")
	var main: Node = script.new()
	var player := Player.new()
	root.add_child(player)
	var floor := FloorController.new()
	root.add_child(floor)
	var hud := HUD.new()
	root.add_child(hud)
	hud.bind(player, floor)
	await process_frame
	player.equipped_element = "fire"
	player.max_resource = 50.0
	player.resource = 10.0
	var resource_events := {"count": 0}
	player.resource_changed.connect(func(_current: float, _max_value: float) -> void:
		resource_events["count"] = int(resource_events["count"]) + 1)
	main.set("player", player)
	main.set("_run_mode", "elemental_chaos")
	main.call("_on_room_mastery_awarded", {"room_type": RoomNode.RoomType.COMBAT})
	if player.equipped_element != "ice":
		failures.append("Elemental Chaos should cycle player element after a cleared room")
	var shift_feedback := player.get_node_or_null("ElementShiftFeedback") as Label
	if shift_feedback == null:
		failures.append("Elemental Chaos should show readable element shift feedback")
	else:
		if not shift_feedback.text.contains("FIRE -> ICE"):
			failures.append("Element shift feedback should show the old and new element")
		if str(shift_feedback.get_meta("from_element", "")) != "fire":
			failures.append("Element shift feedback should expose previous element metadata")
		if str(shift_feedback.get_meta("to_element", "")) != "ice":
			failures.append("Element shift feedback should expose new element metadata")
		if str(shift_feedback.get_meta("source", "")) != "cycle_element":
			failures.append("Element shift feedback should expose source metadata")
	var decisions := player.room_decision_history_summary(3)
	if not decisions.contains("Elemental Chaos") or not decisions.contains("Fire -> Ice"):
		failures.append("Elemental Chaos should record the forced element shift as a room decision")
	if not player.has_method("activate_chaos_surge"):
		failures.append("Player should expose activate_chaos_surge for Elemental Chaos combat feedback")
	if not bool(player.get_meta("chaos_surge_active", false)):
		failures.append("Elemental Chaos should activate Chaos Surge after an element shift")
	if str(player.get_meta("chaos_surge_element", "")) != "ice":
		failures.append("Chaos Surge should track the newly equipped element")
	if float(player.get_meta("chaos_surge_left", 0.0)) <= 0.0:
		failures.append("Chaos Surge should expose remaining duration metadata")
	if player.resource <= 10.0:
		failures.append("Chaos Surge should refund a small amount of player resource")
	if int(resource_events["count"]) <= 0:
		failures.append("Chaos Surge resource refund should emit resource_changed")
	if float(player.element_damage_multiplier("ice")) <= 1.0:
		failures.append("Chaos Surge should boost the newly equipped element damage")
	if float(player.element_damage_multiplier("fire")) > 1.001:
		failures.append("Chaos Surge should not boost the previous element")
	await process_frame
	if not _has_label_containing(hud, "Chaos Surge"):
		failures.append("HUD should show active Chaos Surge in the buff line")
	if player.has_method("_tick_chaos_surge"):
		player.call("_tick_chaos_surge", 4.1)
		if bool(player.get_meta("chaos_surge_active", false)):
			failures.append("Chaos Surge should expire after its short duration")
		if float(player.element_damage_multiplier("ice")) > 1.001:
			failures.append("Chaos Surge element damage bonus should expire")
	hud.queue_free()
	floor.queue_free()
	player.free()
	main.free()
	await process_frame

func _press_key(screen: ClassSelectScreen, keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	screen.call("_unhandled_input", event)

func _has_label_containing(parent: Node, text: String) -> bool:
	for child in parent.find_children("*", "Label", true, false):
		if str(child.text).contains(text):
			return true
	return false
