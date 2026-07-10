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
				"F1",
				"hide",
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
				if label.size.x > 460.0 or label.size.y > 120.0:
					failures.append("manual scenario overlay label should stay compact, got %s" % label.size)
				if label.get_theme_font_size("font_size") > 10:
					failures.append("manual scenario overlay font should not dominate playtest view")
				if not str(label.get_meta("manual_asset_review_hints", "")).contains(
						"review_asset_candidate.gd"):
					failures.append("manual scenario overlay should store asset review hints metadata")
				if not str(label.get_meta("manual_evidence_notes_skeleton", "")).contains(
						"asset_animation_notes="):
					failures.append("manual scenario overlay should store notes skeleton metadata")
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
