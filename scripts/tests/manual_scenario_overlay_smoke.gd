extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		failures.append("main scene should load for manual scenario overlay")
	else:
		var main := packed.instantiate()
		get_root().add_child(main)
		if not main.has_method("_manual_playtest_launch_request_from_args"):
			failures.append("Main should expose manual scenario launch parser")
		if not main.has_method("_manual_playtest_overlay_text"):
			failures.append("Main should expose manual scenario overlay text")
		if not main.has_method("_show_manual_playtest_overlay"):
			failures.append("Main should expose manual scenario overlay renderer")
		if not main.has_method("_toggle_manual_playtest_overlay"):
			failures.append("Main should expose manual scenario overlay toggle")
		if not main.has_method("_capture_manual_playtest_screenshot"):
			failures.append("Main should expose manual scenario screenshot capture helper")
		if not main.has_method("_copy_manual_playtest_record_command"):
			failures.append("Main should expose manual scenario command copy helper")
		if failures.is_empty():
			var request: Dictionary = main.call(
				"_manual_playtest_launch_request_from_args", ["--manual-scenario=2"])
			var text := str(main.call("_manual_playtest_overlay_text", request))
			for token in [
				"Scenario 2",
				"seed 420102",
				"boss_rush",
				"bulwark",
				"element fire",
				"survive boss phase shift and enrage",
				"Check:",
				"Capture:",
				"dungeon_core_manual_scenario_2.png",
				"F1",
				"hide",
				"F2",
				"F3",
				"copy",
				"human-only",
			]:
				if not text.contains(token):
					failures.append("manual scenario overlay text missing token: %s" % token)
			if text.split("\n").size() > 5:
				failures.append("manual scenario overlay text should stay compact")
			for noisy_token in [
				"godot --headless",
				"Asset Review:",
				"Issue aliases:",
				"record_manual_playtest_issue.gd",
				"resolve_manual_playtest_issue.gd",
				"--manifest=<manifest.json>",
			]:
				if text.contains(noisy_token):
					failures.append("manual scenario overlay should keep noisy token in metadata: %s" % noisy_token)
			main.call("_show_manual_playtest_overlay", request)
			var label := main.find_child("ManualPlaytestScenarioLabel", true, false) as Label
			if label == null:
				failures.append("manual scenario overlay should create ManualPlaytestScenarioLabel")
			else:
				if label.visible:
					failures.append("manual scenario overlay should start hidden so it does not cover playtest")
				if int(label.get_meta("manual_scenario_index", 0)) != 2:
					failures.append("manual scenario overlay should store scenario index metadata")
				if str(label.get_meta("manual_scenario_element", "")) != "fire":
					failures.append("manual scenario overlay should store selected element metadata")
				if str(label.get_meta("manual_scenario_evidence_source", "")) != "manual_playtest":
					failures.append("manual scenario overlay should store manual evidence source metadata")
				if bool(label.get_meta("records_release_evidence", true)):
					failures.append("manual scenario overlay should not record release evidence")
				if str(label.get_meta("manual_overlay_toggle_key", "")) != "F1":
					failures.append("manual scenario overlay should store F1 toggle metadata")
				if str(label.get_meta("manual_capture_key", "")) != "F2":
					failures.append("manual scenario overlay should store F2 capture metadata")
				if str(label.get_meta("manual_copy_key", "")) != "F3":
					failures.append("manual scenario overlay should store F3 copy metadata")
				if label.position.x < 140.0 or label.position.x > 180.0:
					failures.append("manual scenario overlay should use compact upper-right logical x, got %s" % label.position)
				if label.position.y > 76.0:
					failures.append("manual scenario overlay should stay above the player combat lane")
				if label.scale.x > 0.6 or label.scale.y > 0.6:
					failures.append("manual scenario overlay should downscale visual text, got %s" % label.scale)
				if label.size.x > 320.0 or label.size.y > 84.0:
					failures.append("manual scenario overlay label should stay compact, got %s" % label.size)
				if label.get_theme_font_size("font_size") > 7:
					failures.append("manual scenario overlay font should not dominate playtest view")
				if label.get_theme_constant("outline_size") < 4:
					failures.append("manual scenario overlay should use enough outline for dungeon contrast")
				for line in label.text.split("\n"):
					if str(line).length() > 76:
						failures.append("manual scenario overlay line should stay short enough for the compact panel")
				if not str(label.get_meta("manual_asset_review_hints", "")).contains(
						"review_asset_candidate.gd"):
					failures.append("manual scenario overlay should store asset review hints metadata")
				if not str(label.get_meta("manual_evidence_notes_skeleton", "")).contains(
						"asset_animation_notes="):
					failures.append("manual scenario overlay should store notes skeleton metadata")
				if not str(label.get_meta("manual_screenshot_path", "")).contains(
						"dungeon_core_manual_scenario_2.png"):
					failures.append("manual scenario overlay should store deterministic screenshot path metadata")
				if not str(label.get_meta("manual_capture_command", "")).contains(
						"dungeon_core_manual_scenario_2.png"):
					failures.append("manual scenario overlay should store capture helper command metadata")
				if str(label.get_meta("manual_recording_policy", "")) != "human_only_no_auto_evidence":
					failures.append("manual scenario overlay should tag human-only recording policy")
				var capture_result: Dictionary = main.call(
					"_capture_manual_playtest_screenshot", true)
				if not bool(capture_result.get("dry_run", false)):
					failures.append("manual scenario capture dry-run should mark dry_run")
				if bool(capture_result.get("records_release_evidence", true)):
					failures.append("manual scenario capture should not record release evidence")
				if not str(capture_result.get("path", "")).contains(
						"dungeon_core_manual_scenario_2.png"):
					failures.append("manual scenario capture should target deterministic screenshot path")
				if str(label.get_meta("manual_last_capture_path", "")) != str(capture_result.get("path", "")):
					failures.append("manual scenario capture should store last capture path metadata")
				var copy_result: Dictionary = main.call(
					"_copy_manual_playtest_record_command", true)
				if not bool(copy_result.get("dry_run", false)):
					failures.append("manual scenario command copy dry-run should mark dry_run")
				if bool(copy_result.get("copied", true)):
					failures.append("manual scenario command copy dry-run should not touch clipboard")
				if bool(copy_result.get("records_release_evidence", true)):
					failures.append("manual scenario command copy should not record release evidence")
				var copied_command := str(copy_result.get("command", ""))
				for command_token in [
					"record_manual_scenario_evidence.gd",
					"--scenario-index=2",
					"--notes=<human notes>",
					"dungeon_core_manual_scenario_2.png",
				]:
					if not copied_command.contains(command_token):
						failures.append("manual scenario copied command missing token: %s" % command_token)
				if str(label.get_meta("manual_last_copied_command", "")) != copied_command:
					failures.append("manual scenario copy should store last copied command metadata")
				if not str(label.get_meta("manual_pass_command", "")).contains(
						"record_manual_scenario_evidence.gd"):
					failures.append("manual scenario overlay should store pass command metadata")
				if not str(label.get_meta("manual_issue_command", "")).contains(
						"record_manual_playtest_issue.gd"):
					failures.append("manual scenario overlay should store issue command metadata")
				if not str(label.get_meta("manual_resolve_command", "")).contains(
						"resolve_manual_playtest_issue.gd"):
					failures.append("manual scenario overlay should store resolve command metadata")
				if not str(label.get_meta("manual_final_notes_command", "")).contains(
						"record_playtest_notes_evidence.gd"):
					failures.append("manual scenario overlay should store final notes command metadata")
				main.call("_toggle_manual_playtest_overlay")
				if not label.visible:
					failures.append("manual scenario overlay toggle should show the label")
				main.call("_toggle_manual_playtest_overlay")
				if label.visible:
					failures.append("manual scenario overlay toggle should hide the label again")
		main.queue_free()
	if failures.is_empty():
		print("Manual scenario overlay smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
