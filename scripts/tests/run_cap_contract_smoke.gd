extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	_check_main_floor_caps(failures)
	_check_floor_controller_boss_rush_finale(failures)
	if failures.is_empty():
		print("Run cap contract smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_main_floor_caps(failures: Array[String]) -> void:
	var script: GDScript = load("res://scripts/main.gd")
	var main: Node = script.new()
	if not main.has_method("_run_floor_cap"):
		failures.append("Main should expose _run_floor_cap for mode-specific finale contracts")
		main.free()
		return
	var expected_caps := {
		"normal": 4,
		"hardcore": 4,
		"elemental_chaos": 4,
		"boss_rush": 3,
		"endless": 4,
	}
	for mode in expected_caps.keys():
		main.set("_run_mode", str(mode))
		var cap := int(main.call("_run_floor_cap"))
		if cap != int(expected_caps[mode]):
			failures.append("%s run floor cap should be %d, got %d" % [
				str(mode),
				int(expected_caps[mode]),
				cap,
			])
	main.set("_run_mode", "boss_rush")
	main.set("current_floor", 4)
	if not bool(main.call("_is_run_finale_summary")):
		failures.append("Boss Rush should summarize as finale after chain 3 is cleared")
	if bool(main.call("_run_continues_after_floor_cap")):
		failures.append("Boss Rush should not continue after its chain cap")
	main.set("_run_mode", "endless")
	main.set("current_floor", 5)
	if not bool(main.call("_run_continues_after_floor_cap")):
		failures.append("Endless should be the only mode that continues after cap")
	if bool(main.call("_is_run_finale_summary")):
		failures.append("Endless floor 5 should not summarize as run finale")
	main.free()

func _check_floor_controller_boss_rush_finale(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	ctrl.run_mode = "boss_rush"
	ctrl.floor_index = 3
	var boss := RoomNode.new()
	boss.id = 303
	boss.type = RoomNode.RoomType.BOSS
	ctrl.current_room = boss
	var objective := ctrl.current_room_objective()
	if not objective.contains("Boss Rush") or not objective.contains("Chain 3/3"):
		failures.append("Boss Rush finale objective should keep chain progress")
	if not objective.contains("final boss"):
		failures.append("Boss Rush chain 3 objective should identify the final boss")
	ctrl.cleared_rooms[boss.id] = true
	objective = ctrl.current_room_objective()
	if not objective.contains("run complete portal"):
		failures.append("Boss Rush final reward should point to run complete portal")
	var next_action := ctrl.current_room_next_action()
	if not next_action.contains("run complete portal"):
		failures.append("Boss Rush final next action should enter run complete portal")
	if not bool(ctrl.call("_is_run_finale_floor")):
		failures.append("Boss Rush chain cap should be treated as a run finale floor")
	ctrl.queue_free()
