extends SceneTree

const RunSummaryScript := preload("res://scripts/ui/run_summary.gd")

func _init() -> void:
	var failures: Array[String] = []
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		failures.append("main scene should load for playtest notes command")
	else:
		var main := packed.instantiate()
		if not main.has_method("_playtest_notes_record_command"):
			failures.append("Main should expose playtest notes record command helper")
		else:
			main.set("run_seed", 420105)
			main.set("_run_mode", "elemental_chaos")
			var command := str(main.call("_playtest_notes_record_command", "ranger"))
			for token in [
				"record_playtest_notes_evidence.gd",
				"--seed=420105",
				"--class_id=ranger",
				"--mode=elemental_chaos",
				"--replay_last_run_result=<replay_last_run_result>",
				"--daily_fingerprint_hash=<daily_fingerprint_hash>",
				"--pace_avg_sec=<pace_avg_sec>",
				"--pace_boss_sec=<pace_boss_sec>",
				"--asset_animation_notes=<asset_animation_notes>",
				"--polygon_collision_notes=<polygon_collision_notes>",
				"--wave_hud_audio_notes=<wave_hud_audio_notes>",
				"--blocker_screenshot_or_seed=<blocker_screenshot_or_seed>",
				"--release_decision=<release_decision>",
			]:
				if not command.contains(token):
					failures.append("playtest notes command missing token: %s" % token)
			if command.contains("manual_scenario_results") or command.contains("headless_rehearsal"):
				failures.append("playtest notes command should not create scenario evidence")
			main.set("run_seed", 0)
			var hidden := str(main.call("_playtest_notes_record_command", "ranger"))
			if hidden != "":
				failures.append("playtest notes command should hide without a run seed")
		main.free()
	var summary := RunSummaryScript.end_message("defeat", 2, {"gold": 10}, {
		"banked_gold": 0,
		"last_rewards": {"gold": 0},
	}, {
		"playtest_notes_record_command":
			"godot --headless --path . --script res://scripts/tools/record_playtest_notes_evidence.gd -- --seed=420105 --class_id=ranger --mode=elemental_chaos --replay_last_run_result=<replay_last_run_result>",
	})
	if not summary.contains("Playtest Notes Command:"):
		failures.append("run summary should show playtest notes record command")
	if not summary.contains("record_playtest_notes_evidence.gd"):
		failures.append("run summary playtest notes command should name recorder tool")
	if failures.is_empty():
		print("Playtest notes command smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
