extends SceneTree

const LAUNCHER_PATH := "res://scripts/tools/launch_manual_scenario.ps1"

func _init() -> void:
	var failures: Array[String] = []
	if not FileAccess.file_exists(LAUNCHER_PATH):
		failures.append("manual scenario launcher should exist")
	else:
		_check_launcher_list(failures)
		_check_launcher_uses_release_audit_list(failures)
	if failures.is_empty():
		print("Manual scenario launcher list smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_launcher_list(failures: Array[String]) -> void:
	var launcher := ProjectSettings.globalize_path(LAUNCHER_PATH)
	var output: Array = []
	var exit_code := OS.execute("powershell", [
		"-NoProfile",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		launcher,
		"-List",
	], output, true)
	var text := "\n".join(output)
	if exit_code != 0:
		failures.append("manual scenario launcher list should exit 0, got %d: %s" % [
			exit_code,
			text,
		])
	for token in [
		"Manual Scenarios",
		"Scenario 1",
		"Scenario 6",
		"420101",
		"420106",
		"element=fire",
		"normal",
		"balance_lab",
		"blade_warden",
		"gunner",
		"Launch: powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 1",
		"Launch: powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 1 -Detached",
		"Launch Dry Run",
		"-ScenarioIndex 1 -Detached -DryRun",
		"Manual Notes Required: animation, polygon, wave, HUD, audio",
		"Record Pass: godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=1",
		"Record Issue: godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=1",
		"Resolve Issue: godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=1",
		"Issue aliases: poligon -> polygon_collision",
		"Launch: powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 6",
		"Launch: powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 6 -Detached",
		"-ScenarioIndex 6 -Detached -DryRun",
		"Record Pass: godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=6",
		"Record Issue: godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=6",
		"Resolve Issue: godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=6",
		"No Godot window launched",
	]:
		if not text.contains(token):
			failures.append("manual scenario launcher list output missing token: %s" % token)

func _check_launcher_uses_release_audit_list(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(LAUNCHER_PATH)
	if not source.contains("print_manual_scenario_list.gd"):
		failures.append("manual scenario launcher list should read scenarios from ReleaseAudit tool")
	if source.contains("@{ Index ="):
		failures.append("manual scenario launcher should not duplicate scenario seed/class/mode data")
