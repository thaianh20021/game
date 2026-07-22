extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	await _check_main_scene_boots_into_playable_run(failures)
	await _check_door_marker_can_choose_route(failures)

	if failures.is_empty():
		print("Playable boot smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_main_scene_boots_into_playable_run(failures: Array[String]) -> void:
	var main_scene := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if main_scene != "res://scenes/main.tscn":
		failures.append("project should boot through scenes/main.tscn")
		return
	var packed := load(main_scene) as PackedScene
	if packed == null:
		failures.append("main scene should load as PackedScene")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame

	var player := main.get_node_or_null("Player") as Player
	if player == null:
		failures.append("main scene should instantiate Player")
	var select := _first_class_select(main)
	if select == null:
		failures.append("main scene should show class select before run start")
	if not main.has_method("boot_status"):
		failures.append("Main should expose boot_status for playable run readiness smoke")
		main.queue_free()
		await process_frame
		return

	select.set("_selected_class", "blade_warden")
	select.set("_selected_element", "fire")
	select.call("_on_start")
	await process_frame
	await process_frame

	var status: Dictionary = main.call("boot_status")
	if not bool(status.get("run_started", false)):
		failures.append("boot_status should mark run_started after class select confirm")
	if not bool(status.get("player_ready", false)):
		failures.append("boot_status should mark player_ready after run start")
	if not bool(status.get("floor_ready", false)):
		failures.append("boot_status should mark floor_ready after FloorController start")
	if not bool(status.get("hud_ready", false)):
		failures.append("boot_status should mark hud_ready after run start")
	if not bool(status.get("overlay_ready", false)):
		failures.append("boot_status should mark overlay_ready after run start")
	if str(status.get("class_id", "")) != "blade_warden":
		failures.append("boot_status should expose selected class id")
	if str(status.get("element", "")) != "fire":
		failures.append("boot_status should expose selected element")
	if int(status.get("seed", 0)) <= 0:
		failures.append("boot_status should expose a positive run seed")
	if str(status.get("release_decision", "")) == "":
		failures.append("boot_status should include release audit decision")
	var readiness: Dictionary = status.get("first_run_readiness", {})
	if readiness.is_empty():
		failures.append("boot_status should expose first_run_readiness for first-play UX gate")
	else:
		if not bool(readiness.get("ready", false)):
			failures.append("first_run_readiness should pass when objective, route, controls, seed, and mode are visible")
		if str(readiness.get("next_action_key", "")) != "door":
			failures.append("first_run_readiness should mark entrance next action as door")
		if not str(readiness.get("objective_text", "")).to_lower().contains("door"):
			failures.append("first_run_readiness should preserve visible door objective text")
		if int(readiness.get("route_options_count", 0)) <= 0:
			failures.append("first_run_readiness should count available route options")
		var route_summary := str(readiness.get("route_options_summary", ""))
		if not route_summary.contains("Choices:") \
				or (not route_summary.contains("MAIN") and not route_summary.contains("SIDE")):
			failures.append("first_run_readiness should expose readable route option summary")
		if not bool(readiness.get("control_hint_visible", false)):
			failures.append("first_run_readiness should confirm in-run control hint is visible")
		var control_hint := str(readiness.get("control_hint_text", ""))
		for token in ["Esc/P", "1-4", "E/C skills", "Q cycle", "V ultimate", "Mouse", "F4 clean HUD"]:
			if not control_hint.contains(token):
				failures.append("first_run_readiness control hint missing token: %s" % token)
		if int(readiness.get("run_seed", 0)) <= 0:
			failures.append("first_run_readiness should expose current run seed")
		if str(readiness.get("run_mode", "")) == "":
			failures.append("first_run_readiness should expose current run mode")
	if player != null and not player.is_physics_processing():
		failures.append("player physics should be enabled in playable run")
	var hud := main.get("_hud") as HUD
	if hud == null:
		failures.append("playable run should keep HUD instance")
	else:
		var control_hint_label := hud.get_node_or_null("ControlsHintLabel") as Label
		if control_hint_label == null:
			failures.append("HUD should expose ControlsHintLabel during first run")
		elif not control_hint_label.visible or not control_hint_label.text.contains("1-4"):
			failures.append("HUD ControlsHintLabel should stay visible with route hotkey hint")
		if not main.has_method("_toggle_clean_playtest_hud"):
			failures.append("Main should expose F4 clean HUD toggle helper")
		else:
			var clean_event := InputEventKey.new()
			clean_event.keycode = KEY_F4
			clean_event.pressed = true
			main.call("_unhandled_input", clean_event)
			await process_frame
			if not bool(hud.get_meta("clean_playtest_mode", false)):
				failures.append("F4 should enable clean playtest HUD mode")
			if control_hint_label != null and control_hint_label.visible:
				failures.append("F4 clean HUD should hide visible control hint text")
			var minimap := hud.get_node_or_null("Minimap") as Minimap
			if minimap == null or not minimap.visible:
				failures.append("F4 clean HUD should keep minimap visible")
			clean_event = InputEventKey.new()
			clean_event.keycode = KEY_F4
			clean_event.pressed = true
			main.call("_unhandled_input", clean_event)
			await process_frame
			await process_frame
			if bool(hud.get_meta("clean_playtest_mode", true)):
				failures.append("second F4 should disable clean playtest HUD mode")
			if control_hint_label != null and (not control_hint_label.visible or not control_hint_label.text.contains("1-4")):
				failures.append("second F4 should restore compact control hint text")
	var transition_card := main.find_child("FloorTransitionCard", true, false) as Label
	if transition_card == null:
		failures.append("run start should show a floor transition card")
	else:
		if transition_card.text.contains("\n") or transition_card.text.length() > 72:
			failures.append("run start floor transition card should stay one-line compact")
		if transition_card.position.y > 76.0:
			failures.append("run start floor transition card should stay in the upper HUD band")
		var full_text := str(transition_card.get_meta("floor_transition_full_text", ""))
		for token in ["Build:", "Gold", "Keys", "HP"]:
			if not full_text.contains(token):
				failures.append("compact floor transition card should preserve %s detail in metadata" % token)
	if _first_class_select(main) != null:
		failures.append("class select should be removed after confirming run start")
	var floor_ctrl := main.get("_floor_ctrl") as FloorController
	if floor_ctrl == null:
		failures.append("main should keep a FloorController after run start")
	elif not floor_ctrl.has_method("choose_current_route"):
		failures.append("FloorController should expose choose_current_route for route hotkeys")
	else:
		for action in ["route_choice_1", "route_choice_2", "route_choice_3", "route_choice_4"]:
			if not InputMap.has_action(action):
				failures.append("project input map should include %s action" % action)
		var options: Array = floor_ctrl.call("current_room_route_options")
		if options.is_empty():
			failures.append("playable run entrance should expose route choices")
		else:
			var target_id := int(Dictionary(options[0]).get("room_id", -1))
			var target_type := int(Dictionary(options[0]).get("room_type", -1))
			var event := InputEventAction.new()
			event.action = "route_choice_1"
			event.pressed = true
			main.call("_unhandled_input", event)
			await process_frame
			await process_frame
			if floor_ctrl.current_room == null or floor_ctrl.current_room.id != target_id:
				failures.append("route_choice_1 input should enter the first route option room")
			if floor_ctrl.current_room != null and floor_ctrl.current_room.type != target_type:
				failures.append("route_choice_1 input should preserve target room type")
			var route_result: Dictionary = floor_ctrl.get_meta("last_route_choice_result", {})
			if not bool(route_result.get("accepted", false)):
				failures.append("route choice input should store an accepted transition result")
			if int(route_result.get("choice_index", 0)) != 1:
				failures.append("route choice result should store selected choice index")
			var accepted_feedback := main.get_node_or_null("RouteChoiceAcceptedToast") as Label
			if accepted_feedback == null:
				failures.append("accepted route choice should show an entering-room feedback toast")
			else:
				if str(accepted_feedback.get_meta("route_choice_feedback_kind", "")) != "accepted":
					failures.append("accepted route choice toast should store feedback kind")
				if int(accepted_feedback.get_meta("route_choice_index", 0)) != 1:
					failures.append("accepted route choice toast should store selected choice index")
				if str(accepted_feedback.get_meta("request_source", "")) != "hotkey":
					failures.append("accepted route choice toast should preserve request source")
				if int(accepted_feedback.get_meta("to_room_id", -1)) != target_id:
					failures.append("accepted route choice toast should store target room id")
			var accepted_sfx := main.get_node_or_null("RouteChoiceAcceptedSfx") as AudioStreamPlayer
			if accepted_sfx == null:
				failures.append("accepted route choice should create a sound placeholder")
			else:
				if str(accepted_sfx.get_meta("route_choice_sound_id", "")) != "objective_complete":
					failures.append("accepted route choice sound should use objective_complete cue")
				if str(accepted_sfx.get_meta("audio_cue_kind", "")) != "objective_complete":
					failures.append("accepted route choice sound should expose objective_complete cue kind")
				if int(accepted_sfx.get_meta("route_choice_index", 0)) != 1:
					failures.append("accepted route choice sound should store selected choice index")
				if str(accepted_sfx.get_meta("request_source", "")) != "hotkey":
					failures.append("accepted route choice sound should preserve request source")
				if not bool(accepted_sfx.get_meta("placeholder_audio_stream", false)):
					failures.append("accepted route choice sound should use placeholder audio stream")
				if not bool(accepted_sfx.get_meta("playback_requested", false)):
					failures.append("accepted route choice sound should mark playback requested")
			main.call("_unhandled_input", event)
			await process_frame
			var feedback := main.get_node_or_null("RouteChoiceFeedbackToast") as Label
			if feedback == null:
				failures.append("blocked route choice input should show a route feedback toast")
			else:
				if str(feedback.get_meta("route_choice_feedback_kind", "")) != "blocked":
					failures.append("blocked route choice toast should store feedback kind")
				if str(feedback.get_meta("blocked_reason", "")) != "room_locked":
					failures.append("blocked route choice toast should explain room_locked")
				if int(feedback.get_meta("route_choice_index", 0)) != 1:
					failures.append("blocked route choice toast should store selected choice index")
			var blocked_sfx := main.get_node_or_null("RouteChoiceBlockedSfx") as AudioStreamPlayer
			if blocked_sfx == null:
				failures.append("blocked route choice input should create a sound placeholder")
			else:
				if str(blocked_sfx.get_meta("route_choice_sound_id", "")) != "objective_blocked":
					failures.append("blocked route choice sound should use objective_blocked cue")
				if str(blocked_sfx.get_meta("blocked_reason", "")) != "room_locked":
					failures.append("blocked route choice sound should store blocked reason")
				if int(blocked_sfx.get_meta("route_choice_index", 0)) != 1:
					failures.append("blocked route choice sound should store selected choice index")
				if not bool(blocked_sfx.get_meta("placeholder_audio_stream", false)):
					failures.append("blocked route choice sound should use placeholder audio stream")
				if not bool(blocked_sfx.get_meta("playback_requested", false)):
					failures.append("blocked route choice sound should mark playback requested")
				if DisplayServer.get_name() == "headless" \
						and not bool(blocked_sfx.get_meta("headless_playback_skipped", false)):
					failures.append("blocked route choice sound should skip playback in headless smoke")

	main.queue_free()
	await process_frame

func _check_door_marker_can_choose_route(failures: Array[String]) -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		failures.append("main scene should load for door marker route choice smoke")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	var select := _first_class_select(main)
	if select == null:
		failures.append("door marker route smoke should start from class select")
		main.queue_free()
		await process_frame
		return
	select.set("_selected_class", "blade_warden")
	select.set("_selected_element", "fire")
	select.call("_on_start")
	await process_frame
	await process_frame

	var floor_ctrl := main.get("_floor_ctrl") as FloorController
	if floor_ctrl == null:
		failures.append("door marker route smoke should have FloorController")
		main.queue_free()
		await process_frame
		return
	var options: Array = floor_ctrl.call("current_room_route_options")
	if options.is_empty():
		failures.append("door marker route smoke should expose route options")
		main.queue_free()
		await process_frame
		return
	var first_option := Dictionary(options[0])
	var target_id := int(first_option.get("room_id", -1))
	var marker := _door_marker_by_choice(floor_ctrl, 1)
	if marker == null:
		failures.append("door marker route smoke should render a clickable choice marker")
	elif not marker.has_method("request_route_choice"):
		failures.append("door marker should expose request_route_choice for mouse/touch routing")
	else:
		marker.call("request_route_choice")
		await process_frame
		await process_frame
		if floor_ctrl.current_room == null or floor_ctrl.current_room.id != target_id:
			failures.append("door marker request should enter the selected route room")
		var route_result: Dictionary = floor_ctrl.get_meta("last_route_choice_result", {})
		if str(route_result.get("request_source", "")) != "door_marker":
			failures.append("door marker route result should preserve request_source metadata")

	main.queue_free()
	await process_frame

func _first_class_select(parent: Node) -> ClassSelectScreen:
	for child in parent.get_children():
		if child is ClassSelectScreen:
			return child
	return null

func _door_marker_by_choice(parent: Node, choice_index: int) -> DoorMarker:
	for child in parent.get_children():
		if child is DoorMarker and int(child.get_meta("route_choice_index", 0)) == choice_index:
			return child
		var found := _door_marker_by_choice(child, choice_index)
		if found != null:
			return found
	return null
