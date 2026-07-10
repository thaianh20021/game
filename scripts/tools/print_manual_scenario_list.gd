extends SceneTree

const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var scenarios := Array(ReleaseAuditScript.manual_playtest_checklist().get("scenario_runs", []))
	print("Manual Scenarios")
	print("Manual Notes Required: animation, polygon, wave, HUD, audio")
	print("Issue aliases: %s" % ReleaseAuditScript.manual_playtest_issue_type_alias_summary())
	for i in scenarios.size():
		var scenario: Dictionary = scenarios[i] if scenarios[i] is Dictionary else {}
		var index := i + 1
		print("Scenario %d: seed=%d mode=%s class=%s element=fire | %s" % [
			index,
			int(scenario.get("seed", 0)),
			str(scenario.get("mode", "")),
			str(scenario.get("class_id", "")),
			str(scenario.get("goal", "")),
		])
		print("  Launch: powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex %d" % index)
		print("  Launch Dry Run: powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex %d -DryRun" % index)
		print("  Record Pass: godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=%d --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>" % index)
		print("  Record Issue: godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=%d --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=<screenshot or seed>" % index)
		print("  Resolve Issue: godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=%d --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=<screenshot or seed>" % index)
	print("No Godot window launched")
	quit(0)
