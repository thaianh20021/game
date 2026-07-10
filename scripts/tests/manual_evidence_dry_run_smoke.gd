extends SceneTree

const TOOL_SPECS := [
	{
		"path": "res://scripts/tools/record_playtest_notes_evidence.gd",
		"record_token": "record_release_candidate_playtest_notes_result",
		"ok_token": "Playtest notes dry run OK",
	},
	{
		"path": "res://scripts/tools/record_manual_scenario_evidence.gd",
		"record_token": "record_release_candidate_manual_scenario_result",
		"ok_token": "Manual scenario evidence dry run OK",
	},
	{
		"path": "res://scripts/tools/record_manual_playtest_issue.gd",
		"record_token": "record_release_candidate_manual_playtest_issue",
		"ok_token": "Manual playtest issue dry run OK",
	},
	{
		"path": "res://scripts/tools/resolve_manual_playtest_issue.gd",
		"record_token": "resolve_release_candidate_manual_playtest_issue",
		"ok_token": "Manual playtest issue resolution dry run OK",
	},
]

func _init() -> void:
	var failures: Array[String] = []
	_check_tools(failures)
	_check_release_plan_commands(failures)
	_check_playtest_notes_dry_run_output(failures)
	if failures.is_empty():
		print("Manual evidence dry-run smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_tools(failures: Array[String]) -> void:
	for spec in TOOL_SPECS:
		var path := str(spec.get("path", ""))
		if not ResourceLoader.exists(path):
			failures.append("manual evidence dry-run tool missing: %s" % path)
			continue
		var source := FileAccess.get_file_as_string(path)
		for token in ["dry-run", "_dry_run", "No release evidence recorded", str(spec.get("ok_token", ""))]:
			if not source.contains(token):
				failures.append("%s missing dry-run token: %s" % [path, token])
		var dry_run_index := source.find("_dry_run()")
		var record_index := source.find(str(spec.get("record_token", "")))
		if dry_run_index < 0 or record_index < 0 or dry_run_index > record_index:
			failures.append("%s should validate dry-run before recording evidence" % path)

func _check_release_plan_commands(failures: Array[String]) -> void:
	var release_audit = load("res://scripts/assets/release_audit.gd")
	var plan: Dictionary = release_audit.call("release_candidate_manual_recording_plan")
	var commands: Dictionary = plan.get("commands", {})
	var notes_dry_run := str(commands.get("playtest_notes_dry_run", ""))
	if not notes_dry_run.contains("--dry-run=true"):
		failures.append("manual recording plan should expose playtest notes dry-run command")
	_assert_executable_dry_run(notes_dry_run, "playtest notes dry-run command", failures)
	var statuses: Array = plan.get("scenario_statuses", [])
	if statuses.is_empty():
		failures.append("manual recording plan should include scenario statuses for dry-run commands")
	else:
		var first: Dictionary = statuses[0]
		for key in ["dry_run_command", "issue_dry_run_command", "resolve_dry_run_command"]:
			var command := str(first.get(key, ""))
			if not command.contains("--dry-run=true"):
				failures.append("manual scenario status should expose %s" % key)
			_assert_executable_dry_run(command, key, failures)
		if not str(first.get("dry_run_command", "")).contains("--screenshot_or_seed=seed_420101_dry_run"):
			failures.append("manual scenario pass dry-run should include seed evidence")
		if not str(first.get("issue_dry_run_command", "")).contains("--issue_type=polygon_collision"):
			failures.append("issue dry-run command should use a valid default issue type")
		if not str(first.get("resolve_dry_run_command", "")).contains("--issue_type=polygon_collision"):
			failures.append("resolve dry-run command should use a valid default issue type")
	var packet: Dictionary = release_audit.call("release_candidate_playtest_packet")
	var markdown := str(packet.get("markdown", ""))
	if not markdown.contains("--dry-run=true") or not markdown.contains("Dry Run"):
		failures.append("playtest packet markdown should show dry-run commands")

func _assert_executable_dry_run(command: String, label: String, failures: Array[String]) -> void:
	if command.contains("<") or command.contains(">"):
		failures.append("%s should be executable without placeholder edits" % label)

func _check_playtest_notes_dry_run_output(failures: Array[String]) -> void:
	var output: Array = []
	var exit_code := OS.execute(OS.get_executable_path(), [
		"--headless",
		"--path",
		ProjectSettings.globalize_path("res://"),
		"--script",
		"res://scripts/tools/record_playtest_notes_evidence.gd",
		"--",
		"--seed=420101",
		"--class_id=blade_warden",
		"--mode=normal",
		"--replay_last_run_result=replayed seed 420101 same class and mode",
		"--daily_fingerprint_hash=hash_420101_manual_check",
		"--pace_avg_sec=40",
		"--pace_boss_sec=90",
		"--asset_animation_notes=animation stable attack hurt death frames reviewed",
		"--polygon_collision_notes=polygon collision matched visible sprite",
		"--wave_hud_audio_notes=wave HUD audio cues clear",
		"--blocker_screenshot_or_seed=seed_420101_no_blocker",
		"--release_decision=hold",
		"--dry-run=true",
	], output, true)
	var text := "\n".join(output)
	if exit_code != 0:
		failures.append("playtest notes dry-run should exit 0, got %d: %s" % [
			exit_code,
			text,
		])
	for token in [
		"Playtest notes dry run OK: seed 420101, class blade_warden, mode normal",
		"Coverage: animation, polygon, wave, HUD, audio",
		"Release decision: hold",
		"No release evidence recorded",
	]:
		if not text.contains(token):
			failures.append("playtest notes dry-run output missing token: %s" % token)
