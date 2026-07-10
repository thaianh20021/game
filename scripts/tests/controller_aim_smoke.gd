extends SceneTree

const AIM_ACTIONS := ["aim_left", "aim_right", "aim_up", "aim_down"]

func _init() -> void:
	var failures: Array[String] = []
	_check_aim_actions(failures)
	_check_aim_hints(failures)
	await _check_player_uses_right_stick_aim(failures)
	_release_aim_actions()
	if failures.is_empty():
		print("Controller aim smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_aim_actions(failures: Array[String]) -> void:
	for action in AIM_ACTIONS:
		if not InputMap.has_action(action):
			failures.append("project input map should include %s for right-stick aim" % action)
		elif not _action_has_gamepad_motion(action):
			failures.append("%s should expose a right-stick gamepad motion binding" % action)

func _check_aim_hints(failures: Array[String]) -> void:
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	var select_source := FileAccess.get_file_as_string("res://scripts/ui/class_select.gd")
	if not hud_source.contains("RS aim"):
		failures.append("HUD controls hint should mention RS aim")
	if not select_source.contains("RS aim"):
		failures.append("class select controls hint should mention RS aim")

func _check_player_uses_right_stick_aim(failures: Array[String]) -> void:
	for action in AIM_ACTIONS:
		if not InputMap.has_action(action):
			return
	var player := Player.new()
	player.global_position = Vector2(120, 80)
	root.add_child(player)
	await process_frame

	_release_aim_actions()
	Input.action_press("aim_right", 1.0)
	var right_aim := Vector2(player.call("_aim_dir"))
	if right_aim.dot(Vector2.RIGHT) < 0.99:
		failures.append("player aim should prefer right-stick aim_right over mouse aim")
	if str(player.get_meta("last_aim_input_source", "")) != "controller":
		failures.append("player should tag controller as the last aim input source")
	if not player.has_method("_aim_target_position"):
		failures.append("player should expose _aim_target_position for controller-targeted skills")
	else:
		var right_target := Vector2(player.call("_aim_target_position"))
		var target_delta := right_target - player.global_position
		if target_delta.dot(Vector2.RIGHT) <= 32.0:
			failures.append("controller aim target should project in the stick direction")

	_release_aim_actions()
	Input.action_press("aim_up", 1.0)
	var up_aim := Vector2(player.call("_aim_dir"))
	if up_aim.dot(Vector2.UP) < 0.99:
		failures.append("player aim should read aim_up as upward controller aim")

	player.queue_free()

func _action_has_gamepad_motion(action: String) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			return true
	return false

func _release_aim_actions() -> void:
	for action in AIM_ACTIONS:
		if InputMap.has_action(action):
			Input.action_release(action)
