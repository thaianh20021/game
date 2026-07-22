extends SceneTree

const LAUNCHER_PATH := "res://scripts/tools/launch_manual_scenario.ps1"

func _init() -> void:
	var failures: Array[String] = []
	if not FileAccess.file_exists(LAUNCHER_PATH):
		failures.append("manual scenario launcher should exist")
	else:
		_check_launcher_dry_run(failures)
		_check_launcher_detached_dry_run(failures)
		_check_launcher_next_dry_run(failures)
	if failures.is_empty():
		print("Manual scenario launcher dry-run smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_launcher_dry_run(failures: Array[String]) -> void:
	var launcher := ProjectSettings.globalize_path(LAUNCHER_PATH)
	var output: Array = []
	var exit_code := OS.execute("powershell", [
		"-NoProfile",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		launcher,
		"-ScenarioIndex",
		"1",
		"-DryRun",
	], output, true)
	var text := "\n".join(output)
	if exit_code != 0:
		failures.append("manual scenario launcher dry-run should exit 0, got %d: %s" % [
			exit_code,
			text,
		])
	for token in [
		"Dry Run",
		"Manual Scenario Checklist",
		"Launching manual playtest scenario 1",
		"--manual-scenario=1",
		"--element=fire",
		"Manual Notes Required: animation, polygon, wave, HUD, audio",
		"Wave/HUD/Audio",
		"wave_hud_audio_notes",
		"Notes Skeleton:",
		"asset_animation_notes",
		"polygon_collision_notes",
		"wave_hud_audio_notes=<human wave hud audio notes>",
		"Suggested Screenshot:",
		"dungeon_core_manual_scenario_1.png",
		"Capture Screenshot:",
		"--screenshot_or_seed=",
		"Final Notes:",
		"record_playtest_notes_evidence.gd",
		"record_manual_scenario_evidence.gd",
		"Record Issue:",
		"record_manual_playtest_issue.gd",
		"Resolve Issue:",
		"resolve_manual_playtest_issue.gd",
		"Issue aliases: poligon -> polygon_collision",
		"No Godot window launched",
	]:
		if not text.contains(token):
			failures.append("manual scenario launcher dry-run output missing token: %s" % token)

func _check_launcher_detached_dry_run(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(LAUNCHER_PATH)
	if not source.contains("[switch]$Detached"):
		failures.append("manual scenario launcher should expose -Detached for non-blocking visible playtests")
	if not source.contains("Godot_v4.7-stable_win64.exe"):
		failures.append("manual scenario detached launcher should use the visible Godot executable")
	if not source.contains("Start-Process"):
		failures.append("manual scenario detached launcher should use Start-Process")
	if not source.contains("SetForegroundWindow") or not source.contains("SetWindowPos"):
		failures.append("manual scenario detached launcher should restore and foreground the Godot window")
	var launcher := ProjectSettings.globalize_path(LAUNCHER_PATH)
	var output: Array = []
	var exit_code := OS.execute("powershell", [
		"-NoProfile",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		launcher,
		"-ScenarioIndex",
		"1",
		"-Detached",
		"-DryRun",
	], output, true)
	var text := "\n".join(output)
	if exit_code != 0:
		failures.append("manual scenario detached dry-run should exit 0, got %d: %s" % [
			exit_code,
			text,
		])
	for token in [
		"Detached Launch",
		"Start-Process",
		"Godot_v4.7-stable_win64.exe",
		"--manual-scenario=1",
		"--element=fire",
		"Foreground:",
		"No Godot window launched",
	]:
		if not text.contains(token):
			failures.append("manual scenario detached dry-run output missing token: %s" % token)

func _check_launcher_next_dry_run(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(LAUNCHER_PATH)
	if not source.contains("print_next_manual_scenario.gd"):
		failures.append("manual scenario launcher should resolve -Next from release evidence")
	var launcher := ProjectSettings.globalize_path(LAUNCHER_PATH)
	var output: Array = []
	var exit_code := OS.execute("powershell", [
		"-NoProfile",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		launcher,
		"-Next",
		"-DryRun",
	], output, true)
	var text := "\n".join(output)
	if exit_code != 0:
		failures.append("manual scenario launcher -Next dry-run should exit 0, got %d: %s" % [
			exit_code,
			text,
		])
	for token in [
		"Next missing manual scenario: 1",
		"seed=420101",
		"mode=normal",
		"class=blade_warden",
		"Goal: clear floor 1 and choose one upgrade",
		"Launch: powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 1",
		"Launch: powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 1 -Detached",
		"Record Pass: godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=1",
		"Record Issue: godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=1",
		"Resolve Issue: godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=1",
		"Manual Notes Required: animation, polygon, wave, HUD, audio",
		"Notes Skeleton:",
		"Suggested Screenshot:",
		"dungeon_core_manual_scenario_1.png",
		"Capture Screenshot:",
		"--screenshot_or_seed=",
		"Final Notes:",
		"record_playtest_notes_evidence.gd",
		"Launching manual playtest scenario 1",
		"Dry Run: --manual-scenario=1",
		"No Godot window launched",
	]:
		if not text.contains(token):
			failures.append("manual scenario launcher -Next dry-run output missing token: %s" % token)
