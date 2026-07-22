extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	await _check_class_select_seed_input(failures)
	await _check_class_select_hotkeys(failures)
	_check_main_uses_selected_seed(failures)
	await _check_main_manual_scenario_launch_args(failures)

	if failures.is_empty():
		print("Run seed smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_class_select_seed_input(failures: Array[String]) -> void:
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame

	var seed_input := screen.find_child("RunSeedInput", true, false) as LineEdit
	if seed_input == null:
		failures.append("class select should expose a run seed input")
	else:
		seed_input.text = "424242"
	var seed_label := screen.find_child("RunSeedLabel", true, false) as Label
	if seed_label == null:
		failures.append("class select should label the seed input")
	elif not seed_label.text.contains("Seed"):
		failures.append("seed input label should mention Seed")
	if not screen.has_method("daily_seed_for_date"):
		failures.append("class select should expose daily_seed_for_date")
	elif int(screen.call("daily_seed_for_date", 2026, 7, 5)) != 20260705:
		failures.append("daily seed should be stable YYYYMMDD")
	var daily_button := screen.find_child("DailySeedButton", true, false) as Button
	if daily_button == null:
		failures.append("class select should expose Daily Seed button")
	elif seed_input != null:
		if str(daily_button.get_meta("seed_input_action", "")) != "daily_seed":
			failures.append("daily seed button should expose daily_seed input metadata")
		if str(daily_button.get_meta("seed_key_label", "")) != "Y":
			failures.append("daily seed button should expose Y key label")
		if int(daily_button.get_meta("seed_hotkey", 0)) != KEY_Y:
			failures.append("daily seed button should expose Y hotkey metadata")
		if not daily_button.tooltip_text.contains("Daily Seed") or not daily_button.tooltip_text.contains("Y"):
			failures.append("daily seed button should expose readable key tooltip")
		seed_input.text = ""
		daily_button.emit_signal("pressed")
		await process_frame
		if not seed_input.text.is_valid_int() or int(seed_input.text) <= 0:
			failures.append("daily seed button should fill a positive numeric seed")
		seed_input.text = "424242"
	var normal_mode := screen.find_child("RunMode_Normal", true, false) as Button
	var boss_rush_mode := screen.find_child("RunMode_BossRush", true, false) as Button
	var endless_mode := screen.find_child("RunMode_Endless", true, false) as Button
	var balance_lab_mode := screen.find_child("RunMode_BalanceLab", true, false) as Button
	if normal_mode == null or boss_rush_mode == null or endless_mode == null \
			or balance_lab_mode == null:
		failures.append("class select should expose Normal, Boss Rush, Endless, and Balance Lab mode buttons")
	else:
		for spec in [
			{"button": normal_mode, "mode": "normal", "key": "N", "hotkey": KEY_N},
			{"button": boss_rush_mode, "mode": "boss_rush", "key": "B", "hotkey": KEY_B},
			{"button": endless_mode, "mode": "endless", "key": "E", "hotkey": KEY_E},
			{"button": balance_lab_mode, "mode": "balance_lab", "key": "A", "hotkey": KEY_A},
		]:
			var button := spec["button"] as Button
			if str(button.get_meta("run_mode_input_action", "")) != "select_run_mode":
				failures.append("%s mode button should expose run mode input metadata" % str(spec["mode"]))
			if str(button.get_meta("run_mode_id", "")) != str(spec["mode"]):
				failures.append("%s mode button should expose mode id metadata" % str(spec["mode"]))
			if str(button.get_meta("run_mode_key_label", "")) != str(spec["key"]):
				failures.append("%s mode button should expose key label %s" % [str(spec["mode"]), str(spec["key"])])
			if int(button.get_meta("run_mode_hotkey", 0)) != int(spec["hotkey"]):
				failures.append("%s mode button should expose hotkey metadata" % str(spec["mode"]))
			if not button.tooltip_text.contains(str(button.text)) or not button.tooltip_text.contains(str(spec["key"])):
				failures.append("%s mode button should expose readable key tooltip" % str(spec["mode"]))
	if not screen.has_method("selected_run_mode"):
		failures.append("class select should expose selected_run_mode")
	elif str(screen.call("selected_run_mode")) != "normal":
		failures.append("class select default run mode should be normal")
	if boss_rush_mode != null:
		boss_rush_mode.emit_signal("pressed")
		await process_frame
		if screen.has_method("selected_run_mode") and str(screen.call("selected_run_mode")) != "boss_rush":
			failures.append("Boss Rush button should select boss_rush mode")
		var start_button := screen.find_child("StartRunButton", true, false) as Button
		if start_button == null:
			failures.append("class select should expose a named start button")
		elif not start_button.text.contains("BOSS RUSH"):
			failures.append("Boss Rush selection should update the start button label")
	if endless_mode != null:
		endless_mode.emit_signal("pressed")
		await process_frame
		if screen.has_method("selected_run_mode") and str(screen.call("selected_run_mode")) != "endless":
			failures.append("Endless button should select endless mode")
		var start_button := screen.find_child("StartRunButton", true, false) as Button
		if start_button == null:
			failures.append("class select should expose a named start button")
		elif not start_button.text.contains("ENDLESS"):
			failures.append("Endless selection should update the start button label")
	if balance_lab_mode != null:
		balance_lab_mode.emit_signal("pressed")
		await process_frame
		if screen.has_method("selected_run_mode") and str(screen.call("selected_run_mode")) != "balance_lab":
			failures.append("Balance Lab button should select balance_lab mode")
		var start_button := screen.find_child("StartRunButton", true, false) as Button
		if start_button == null:
			failures.append("class select should expose a named start button")
		elif not start_button.text.contains("BALANCE LAB"):
			failures.append("Balance Lab selection should update the start button label")
	var emitted := {"class": "", "element": "", "seed": -2, "mode": ""}
	screen.confirmed.connect(func(class_id: String, element: String, seed: int, mode: String) -> void:
		emitted["class"] = class_id
		emitted["element"] = element
		emitted["seed"] = seed
		emitted["mode"] = mode)
	screen.set("_selected_class", "blade_warden")
	screen.set("_selected_element", "fire")
	screen.call("_on_start")
	await process_frame
	if str(emitted["class"]) != "blade_warden" or str(emitted["element"]) != "fire":
		failures.append("class select should still emit class and element")
	if int(emitted["seed"]) != 424242:
		failures.append("class select should emit numeric run seed")
	if str(emitted["mode"]) != "balance_lab":
		failures.append("class select should emit selected run mode")
	await process_frame

	screen = ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	if not screen.has_method("selected_seed"):
		failures.append("class select should expose selected_seed")
	else:
		var blank_seed := int(screen.call("selected_seed"))
		if blank_seed != -1:
			failures.append("blank seed input should mean random seed")
	screen.queue_free()
	await process_frame

func _check_class_select_hotkeys(failures: Array[String]) -> void:
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame

	var emitted := {"count": 0, "class": "", "element": "", "seed": -2, "mode": ""}
	screen.confirmed.connect(func(class_id: String, element: String, seed: int, mode: String) -> void:
		emitted["count"] = int(emitted["count"]) + 1
		emitted["class"] = class_id
		emitted["element"] = element
		emitted["seed"] = seed
		emitted["mode"] = mode)
	_press_key(screen, KEY_ENTER)
	await process_frame
	if int(emitted["count"]) != 1:
		failures.append("Enter should start with default class and element")
	if str(emitted["class"]) != "blade_warden" or str(emitted["element"]) != "fire":
		failures.append("default Enter should emit default class and element")
	if is_instance_valid(screen):
		screen.queue_free()
	await process_frame

	screen = ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	emitted = {"count": 0, "class": "", "element": "", "seed": -2, "mode": ""}
	screen.confirmed.connect(func(class_id: String, element: String, seed: int, mode: String) -> void:
		emitted["count"] = int(emitted["count"]) + 1
		emitted["class"] = class_id
		emitted["element"] = element
		emitted["seed"] = seed
		emitted["mode"] = mode)

	_press_key(screen, KEY_1)
	await process_frame
	if str(screen.get("_selected_class")) != "blade_warden":
		failures.append("1 hotkey should select the first class")
	_press_key(screen, KEY_0)
	await process_frame
	if str(screen.get("_selected_class")) != "tinkerer":
		failures.append("0 hotkey should select the tenth class")

	for pair in [
		{"key": KEY_F, "element": "fire"},
		{"key": KEY_I, "element": "ice"},
		{"key": KEY_L, "element": "lightning"},
		{"key": KEY_P, "element": "poison"},
	]:
		_press_key(screen, int(pair["key"]))
		await process_frame
		if str(screen.get("_selected_element")) != str(pair["element"]):
			failures.append("%s hotkey should select %s" % [OS.get_keycode_string(int(pair["key"])), str(pair["element"])])

	_press_key(screen, KEY_B)
	await process_frame
	if str(screen.call("selected_run_mode")) != "boss_rush":
		failures.append("B hotkey should select Boss Rush")
	var start_button := screen.find_child("StartRunButton", true, false) as Button
	if start_button == null or not start_button.text.contains("BOSS RUSH"):
		failures.append("B hotkey should update the start button label")
	elif str(start_button.get_meta("start_input_action", "")) != "start_run" \
			or str(start_button.get_meta("start_key_label", "")) != "Enter" \
			or int(start_button.get_meta("start_hotkey", 0)) != KEY_ENTER \
			or int(start_button.get_meta("start_alt_hotkey", 0)) != KEY_KP_ENTER \
			or not start_button.tooltip_text.contains("Enter"):
		failures.append("start button should expose Enter/KP Enter input metadata and tooltip")
	var seed_input := screen.find_child("RunSeedInput", true, false) as LineEdit
	if seed_input != null:
		_press_key(screen, KEY_Y)
		await process_frame
		if not seed_input.text.is_valid_int() or int(seed_input.text) <= 0:
			failures.append("Y hotkey should fill the daily seed")
	_press_key(screen, KEY_N)
	await process_frame
	if str(screen.call("selected_run_mode")) != "normal":
		failures.append("N hotkey should select Normal mode")
	if start_button == null or start_button.text.contains("BOSS RUSH"):
		failures.append("N hotkey should restore the normal start button label")
	_press_key(screen, KEY_E)
	await process_frame
	if str(screen.call("selected_run_mode")) != "endless":
		failures.append("E hotkey should select Endless mode")
	if start_button == null or not start_button.text.contains("ENDLESS"):
		failures.append("E hotkey should update the start button label")
	_press_key(screen, KEY_A)
	await process_frame
	if str(screen.call("selected_run_mode")) != "balance_lab":
		failures.append("A hotkey should select Balance Lab mode")
	if start_button == null or not start_button.text.contains("BALANCE LAB"):
		failures.append("A hotkey should update the start button label")
	_press_key(screen, KEY_B)
	await process_frame
	if seed_input != null:
		seed_input.text = "777"
	_press_key(screen, KEY_ENTER)
	await process_frame
	if int(emitted["count"]) != 1:
		failures.append("Enter hotkey should start once class and element are selected")
	if str(emitted["class"]) != "tinkerer" or str(emitted["element"]) != "poison":
		failures.append("Enter hotkey should emit selected class and element")
	if int(emitted["seed"]) != 777 or str(emitted["mode"]) != "boss_rush":
		failures.append("Enter hotkey should emit selected seed and mode")

	screen = ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	var focused_seed := screen.find_child("RunSeedInput", true, false) as LineEdit
	if focused_seed != null:
		focused_seed.grab_focus()
		await process_frame
	var before_class := str(screen.get("_selected_class"))
	_press_key(screen, KEY_0)
	await process_frame
	if str(screen.get("_selected_class")) != before_class:
		failures.append("class hotkeys should not trigger while seed input has focus")
	screen.queue_free()
	await process_frame

func _press_key(screen: ClassSelectScreen, keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	if screen.has_method("_unhandled_input"):
		screen.call("_unhandled_input", event)

func _check_main_uses_selected_seed(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("_start_run(class_id: String, element: String, selected_seed: int"):
		failures.append("Main _start_run should accept selected seed")
	if not source.contains("run_mode: String"):
		failures.append("Main _start_run should accept run mode")
	if not source.contains("selected_seed > 0"):
		failures.append("Main should use positive selected seed")
	if not source.contains("run_seed = selected_seed"):
		failures.append("Main should assign selected seed to run_seed")
	if not source.contains("hud.set_run_seed(run_seed)"):
		failures.append("Main should pass active run seed into HUD")
	if not source.contains("hud.set_run_mode(_run_mode_label())"):
		failures.append("Main should pass active run mode into HUD")
	if not source.contains("_floor_ctrl.start(run_seed, current_floor, player, _run_mode, _run_modifier)"):
		failures.append("Main should pass run mode and modifier into FloorController")
	if not source.contains("\"mode\": _run_mode_label()"):
		failures.append("Main should include run mode in run summary context")
	if not source.contains("_run_continues_after_floor_cap()"):
		failures.append("Main should let Endless continue past the normal floor cap")
	var snapshot_start := source.find("func _pause_run_snapshot")
	var snapshot_end := source.find("func _on_pause_resume_requested")
	if snapshot_start == -1 or snapshot_end == -1 or snapshot_end <= snapshot_start:
		failures.append("Main should expose pause run snapshot")
	else:
		var snapshot_source := source.substr(snapshot_start, snapshot_end - snapshot_start)
		if not snapshot_source.contains("run_seed") or not snapshot_source.contains("Seed") \
				or not snapshot_source.contains("_run_mode_label()") \
				or not snapshot_source.contains("_run_difficulty_label()"):
			failures.append("pause run snapshot should include active run seed, mode, and difficulty")
	if not source.contains("OS.get_cmdline_user_args()"):
		failures.append("Main should inspect command-line args for manual scenario launch")
	if not source.contains("--manual-scenario="):
		failures.append("Main should support --manual-scenario launch args")

func _check_main_manual_scenario_launch_args(failures: Array[String]) -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		failures.append("main scene should load for manual scenario launch args")
		return
	var main := packed.instantiate()
	if not main.has_method("_manual_playtest_launch_request_from_args"):
		failures.append("Main should expose manual scenario launch arg parser")
		main.free()
		return
	var request: Dictionary = main.call(
		"_manual_playtest_launch_request_from_args", ["--manual-scenario=2"])
	if int(request.get("seed", 0)) != 420102:
		failures.append("manual scenario launch args should map scenario 2 seed")
	if str(request.get("mode", "")) != "boss_rush":
		failures.append("manual scenario launch args should map scenario 2 mode")
	if str(request.get("class_id", "")) != "bulwark":
		failures.append("manual scenario launch args should map scenario 2 class")
	if str(request.get("element", "")) != "fire":
		failures.append("manual scenario launch args should default element to fire")
	if str(request.get("source", "")) != "manual_scenario_arg":
		failures.append("manual scenario launch request should mark its source")
	var invalid: Dictionary = main.call(
		"_manual_playtest_launch_request_from_args", ["--manual-scenario=99"])
	if not invalid.is_empty():
		failures.append("invalid manual scenario index should not create a launch request")
	var explicit_element: Dictionary = main.call(
		"_manual_playtest_launch_request_from_args", ["--manual-scenario=1", "--element=ice"])
	if str(explicit_element.get("element", "")) != "ice":
		failures.append("manual scenario launch args should allow explicit element")
	var invalid_element: Dictionary = main.call(
		"_manual_playtest_launch_request_from_args", ["--manual-scenario=1", "--element=void"])
	if str(invalid_element.get("element", "")) != "fire":
		failures.append("manual scenario launch args should fall back to fire for invalid element")
	var overlay_text := str(main.call("_manual_playtest_overlay_text", explicit_element))
	if not overlay_text.contains("element ice"):
		failures.append("manual scenario overlay should show the selected element")
	main.free()
