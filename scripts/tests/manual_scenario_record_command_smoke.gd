extends SceneTree

const RunSummaryScript := preload("res://scripts/ui/run_summary.gd")

func _init() -> void:
	var failures: Array[String] = []
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		failures.append("main scene should load for manual scenario record command")
	else:
		var main := packed.instantiate()
		if not main.has_method("_manual_scenario_record_command"):
			failures.append("Main should expose manual scenario record command helper")
		else:
			main.set("run_seed", 420105)
			main.set("_run_mode", "elemental_chaos")
			var command := str(main.call("_manual_scenario_record_command", "ranger"))
			for token in [
				"record_manual_scenario_evidence.gd",
				"--scenario-index=5",
				"--result=pass",
				"--evidence_source=manual_playtest",
				"--confirm-human-playtest=true",
				"--notes=<human notes>",
				"--screenshot_or_seed=<screenshot or seed>",
			]:
				if not command.contains(token):
					failures.append("manual scenario record command missing token: %s" % token)
			if command.contains("headless_rehearsal"):
				failures.append("manual scenario record command should not use headless evidence")
			main.set("run_seed", 123)
			var hidden := str(main.call("_manual_scenario_record_command", "ranger"))
			if hidden != "":
				failures.append("manual scenario record command should hide for non-checklist runs")
		if not main.has_method("_manual_scenario_issue_record_command"):
			failures.append("Main should expose manual scenario issue record command helper")
		else:
			main.set("run_seed", 420105)
			main.set("_run_mode", "elemental_chaos")
			var issue_command := str(main.call("_manual_scenario_issue_record_command", "ranger"))
			for token in [
				"record_manual_playtest_issue.gd",
				"--scenario-index=5",
				"--result=blocked",
				"--issue_type=<issue_type>",
				"--evidence_source=manual_playtest",
				"--confirm-human-playtest=true",
				"--notes=<human issue notes>",
			]:
				if not issue_command.contains(token):
					failures.append("manual scenario issue command missing token: %s" % token)
			if issue_command.contains("headless_rehearsal"):
				failures.append("manual scenario issue command should not use headless evidence")
		if not main.has_method("_manual_scenario_issue_resolve_command"):
			failures.append("Main should expose manual scenario issue resolve command helper")
		else:
			main.set("run_seed", 420105)
			main.set("_run_mode", "elemental_chaos")
			var resolve_command := str(main.call("_manual_scenario_issue_resolve_command", "ranger"))
			for token in [
				"resolve_manual_playtest_issue.gd",
				"--scenario-index=5",
				"--issue_type=<issue_type>",
				"--resolution_result=fixed_retest_pass",
				"--evidence_source=manual_playtest",
				"--confirm-human-retest=true",
				"--resolution_notes=<human retest notes>",
			]:
				if not resolve_command.contains(token):
					failures.append("manual scenario issue resolve command missing token: %s" % token)
			if resolve_command.contains("manual_scenario_results"):
				failures.append("manual scenario issue resolve command should not create scenario pass evidence")
		main.free()
	var summary := RunSummaryScript.end_message("defeat", 2, {"gold": 10}, {
		"banked_gold": 0,
		"last_rewards": {"gold": 0},
	}, {
		"manual_scenario_record_command":
			"godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=5 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>",
		"manual_scenario_issue_record_command":
			"godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=5 --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes>",
		"manual_scenario_issue_resolve_command":
			"godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=5 --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes>",
	})
	if not summary.contains("Manual Evidence Command:"):
		failures.append("run summary should show manual evidence record command")
	if not summary.contains("--confirm-human-playtest=true"):
		failures.append("run summary manual command should require human confirmation")
	if not summary.contains("--screenshot_or_seed=<screenshot or seed>"):
		failures.append("run summary manual command should require screenshot or seed evidence")
	if not summary.contains("Manual Issue Command:"):
		failures.append("run summary should show manual issue record command")
	if not summary.contains("record_manual_playtest_issue.gd"):
		failures.append("run summary manual issue command should name recorder tool")
	if not summary.contains("Manual Resolve Command:"):
		failures.append("run summary should show manual issue resolve command")
	if not summary.contains("--confirm-human-retest=true"):
		failures.append("run summary manual resolve command should require human retest")
	if failures.is_empty():
		print("Manual scenario record command smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
