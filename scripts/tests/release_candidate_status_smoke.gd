extends SceneTree

const STATUS_TOOL_PATH := "res://scripts/tools/release_candidate_status.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_status_output(failures)
	if failures.is_empty():
		print("Release candidate status smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_status_output(failures: Array[String]) -> void:
	var output: Array = []
	var exit_code := OS.execute(OS.get_executable_path(), [
		"--headless",
		"--path",
		ProjectSettings.globalize_path("res://"),
		"--script",
		STATUS_TOOL_PATH,
	], output, true)
	var text := "\n".join(output)
	if exit_code != 0:
		failures.append("release candidate status should exit 0, got %d: %s" % [
			exit_code,
			text,
		])
	for token in [
		"Release Candidate: evidence_required",
		"Manual Scenario List",
		"launch_manual_scenario.ps1 -List",
		"Next Missing Manual Launch Dry Run",
		"launch_manual_scenario.ps1 -ScenarioIndex 1 -Detached",
		"Asset Replacement Plans",
		"polygon_collision_notes",
		"wave_hud_audio_notes",
		"Manual Notes Required",
		"animation, polygon, wave, HUD, audio",
	]:
		if not text.contains(token):
			failures.append("release candidate status output missing token: %s" % token)
