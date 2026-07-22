extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	await _check_reward_overlay_actions(failures)
	await _check_shop_overlay_actions(failures)
	await _check_pause_overlay_actions(failures)
	await _check_run_end_overlay_actions(failures)
	_check_readiness_overlay_contract(failures)
	if failures.is_empty():
		print("Controller overlay smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_reward_overlay_actions(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var chosen := {"id": ""}
	var skipped := {"gold": 0}
	overlay.upgrade_chosen.connect(func(upgrade_id: String) -> void:
		chosen["id"] = upgrade_id)
	overlay.reward_skipped.connect(func(gold: int) -> void:
		skipped["gold"] = gold)
	overlay.show_room_upgrade_choices([
		{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage"},
		{"id": "dash_spring", "name": "Dash Spring", "desc": "-10% dash cooldown"},
		{
			"id": "vital_core",
			"name": "Vital Core",
			"desc": "+20 Max HP",
			"disabled": true,
			"disabled_reason": "Max stack",
		},
	], RoomNode.RoomType.COMBAT, {}, true)
	await process_frame
	_assert_reward_overlay_fits_viewport(overlay, failures)
	_press_action(overlay, "menu_next")
	await process_frame
	if int(overlay.get_meta("controller_selection_index", -1)) != 1:
		failures.append("menu_next should move reward controller selection to the second enabled choice")
	var second_reward := overlay.find_child("Upgrade_dash_spring", true, false) as Button
	if second_reward == null or not bool(second_reward.get_meta("controller_selected", false)):
		failures.append("menu_next should mark the selected reward button")
	_press_action(overlay, "menu_confirm")
	await process_frame
	if str(chosen["id"]) != "dash_spring":
		failures.append("menu_confirm should choose the selected reward")

	chosen["id"] = ""
	overlay.show_room_upgrade_choices([
		{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage"},
		{"id": "dash_spring", "name": "Dash Spring", "desc": "-10% dash cooldown"},
		{
			"id": "vital_core",
			"name": "Vital Core",
			"desc": "+20 Max HP",
			"disabled": true,
			"disabled_reason": "Max stack",
		},
	], RoomNode.RoomType.COMBAT, {}, true)
	await process_frame
	_press_action(overlay, "route_choice_2")
	await process_frame
	if str(chosen["id"]) != "dash_spring":
		failures.append("route_choice_2 action should choose the second reward")

	chosen["id"] = ""
	overlay.show_room_upgrade_choices([
		{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage"},
		{"id": "dash_spring", "name": "Dash Spring", "desc": "-10% dash cooldown"},
		{
			"id": "vital_core",
			"name": "Vital Core",
			"desc": "+20 Max HP",
			"disabled": true,
			"disabled_reason": "Max stack",
		},
	], RoomNode.RoomType.COMBAT, {}, true)
	await process_frame
	_press_action(overlay, "route_choice_3")
	await process_frame
	if str(chosen["id"]) != "":
		failures.append("route_choice_3 action should not choose a disabled reward")
	if str(overlay.get_meta("last_hotkey_blocked_reason", "")) != "Max stack":
		failures.append("disabled reward action should expose blocked reason metadata")

	_press_action(overlay, "menu_back")
	await process_frame
	if int(skipped["gold"]) != 10:
		failures.append("menu_back action should skip reward for gold")
	overlay.queue_free()
	await process_frame

func _check_shop_overlay_actions(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var chosen := {"index": -99}
	overlay.shop_choice_chosen.connect(func(index: int) -> void:
		chosen["index"] = index)
	overlay.show_shop_choices([
		{"name": "A", "cost": 10, "reward": {"type": "gold", "value": 1}},
		{"name": "B", "cost": 20, "reward": {"type": "gold", "value": 1}},
		{"name": "C", "cost": 40, "reward": {"type": "gold", "value": 1}},
	], 30)
	await process_frame
	_press_action(overlay, "menu_next")
	await process_frame
	if int(overlay.get_meta("controller_selection_index", -1)) != 1:
		failures.append("menu_next should move shop controller selection to the second affordable item")
	var second_shop := overlay.find_child("ShopChoice_1", true, false) as Button
	if second_shop == null or not bool(second_shop.get_meta("controller_selected", false)):
		failures.append("menu_next should mark the selected shop button")
	_press_action(overlay, "menu_confirm")
	await process_frame
	if int(chosen["index"]) != 1:
		failures.append("menu_confirm should buy the selected shop item")

	chosen["index"] = -99
	overlay.show_shop_choices([
		{"name": "A", "cost": 10, "reward": {"type": "gold", "value": 1}},
		{"name": "B", "cost": 20, "reward": {"type": "gold", "value": 1}},
		{"name": "C", "cost": 40, "reward": {"type": "gold", "value": 1}},
	], 30)
	await process_frame
	_press_action(overlay, "route_choice_2")
	await process_frame
	if int(chosen["index"]) != 1:
		failures.append("route_choice_2 action should choose the second shop item")

	chosen["index"] = -99
	overlay.show_shop_choices([
		{"name": "A", "cost": 10, "reward": {"type": "gold", "value": 1}},
		{"name": "B", "cost": 20, "reward": {"type": "gold", "value": 1}},
		{"name": "C", "cost": 40, "reward": {"type": "gold", "value": 1}},
	], 30)
	await process_frame
	_press_action(overlay, "route_choice_3")
	await process_frame
	if int(chosen["index"]) != -99:
		failures.append("route_choice_3 action should not buy an unaffordable shop item")
	if str(overlay.get_meta("last_hotkey_blocked_reason", "")) != "Need 10 gold":
		failures.append("disabled shop action should expose missing gold reason")

	_press_action(overlay, "menu_back")
	await process_frame
	if int(chosen["index"]) != -1:
		failures.append("menu_back action should leave the shop")
	overlay.queue_free()
	await process_frame

func _check_pause_overlay_actions(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var resumed := {"count": 0}
	overlay.resume_requested.connect(func() -> void:
		resumed["count"] = int(resumed["count"]) + 1)
	overlay.show_pause_menu(1, "Ancient Cave", "Power Rune", "None")
	await process_frame
	_press_action(overlay, "menu_back")
	await process_frame
	if int(resumed["count"]) != 1:
		failures.append("menu_back action should resume from pause overlay")
	overlay.queue_free()
	await process_frame

func _check_run_end_overlay_actions(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var restarted := {"count": 0}
	var class_selected := {"count": 0}
	overlay.restart_requested.connect(func() -> void:
		restarted["count"] = int(restarted["count"]) + 1)
	overlay.class_select_requested.connect(func() -> void:
		class_selected["count"] = int(class_selected["count"]) + 1)
	overlay.show_message("YOU DIED", "Press R to retry")
	await process_frame
	if int(overlay.get_meta("controller_selection_index", -1)) != 0:
		failures.append("run end overlay should select Restart by default for controller")
	_press_action(overlay, "menu_next")
	await process_frame
	if int(overlay.get_meta("controller_selection_index", -1)) != 1:
		failures.append("menu_next should move run end controller selection to class select")
	var class_button := overlay.find_child("RunEndClassSelect", true, false) as Button
	if class_button == null or not bool(class_button.get_meta("controller_selected", false)):
		failures.append("menu_next should mark run end class select button")
	_press_action(overlay, "menu_confirm")
	await process_frame
	if int(class_selected["count"]) != 1:
		failures.append("menu_confirm should activate selected run end class select")
	overlay.show_message("YOU DIED", "Press R to retry")
	await process_frame
	_press_action(overlay, "menu_confirm")
	await process_frame
	if int(restarted["count"]) != 1:
		failures.append("menu_confirm should restart when run end restart is selected")
	overlay.queue_free()
	await process_frame

func _check_readiness_overlay_contract(failures: Array[String]) -> void:
	var release_audit = load("res://scripts/assets/release_audit.gd")
	var report: Dictionary = release_audit.call("game_readiness_report")
	var controls: Dictionary = Dictionary(report.get("milestones", {})).get("input_controls", {})
	if not bool(controls.get("run_overlay_gamepad_contract", false)):
		failures.append("readiness should verify run overlay gamepad reward/shop/pause contract")
	if not bool(controls.get("run_overlay_controller_selection_contract", false)):
		failures.append("readiness should verify run overlay menu_next/menu_prev selection contract")
	if not bool(controls.get("run_overlay_message_controller_contract", false)):
		failures.append("readiness should verify run end restart/class-select controller contract")

func _press_action(overlay: RunOverlay, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	if overlay.has_method("_unhandled_input"):
		overlay.call("_unhandled_input", event)

func _assert_reward_overlay_fits_viewport(overlay: RunOverlay, failures: Array[String]) -> void:
	for name in ["OverlayTitle", "OverlaySubtitle", "ChoiceScroll"]:
		var control := overlay.find_child(name, true, false) as Control
		if control == null:
			failures.append("reward overlay should expose %s" % name)
			continue
		var rect := control.get_global_rect()
		if rect.position.x < 0.0 or rect.end.x > 640.0 \
				or rect.position.y < 0.0 or rect.end.y > 360.0:
			failures.append("%s should fit inside the 640x360 viewport" % name)
