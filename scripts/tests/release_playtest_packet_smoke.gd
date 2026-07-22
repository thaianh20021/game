extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"
const PACKET_TOOL_PATH := "res://scripts/tools/write_release_playtest_packet.gd"
const PACKET_DOC_PATH := "res://docs/playtest/release_candidate_manual_playtest.md"

func _init() -> void:
	var failures: Array[String] = []
	var script: Variant = load(RELEASE_AUDIT_PATH)
	if script == null:
		failures.append("ReleaseAudit should load before packet smoke")
	elif not script.has_method("release_candidate_playtest_packet"):
		failures.append("ReleaseAudit should expose release_candidate_playtest_packet")
	else:
		_check_packet(script.call("release_candidate_playtest_packet"), failures)
		_check_packet_file(script.call("release_candidate_playtest_packet"), failures)
	if not ResourceLoader.exists(PACKET_TOOL_PATH):
		failures.append("write_release_playtest_packet tool should exist")
	if failures.is_empty():
		print("Release playtest packet smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_packet(packet: Dictionary, failures: Array[String]) -> void:
	if not bool(packet.get("draft_only", false)):
		failures.append("playtest packet should be draft_only")
	if not bool(packet.get("manual_review_required", false)):
		failures.append("playtest packet should require manual review")
	if int(packet.get("required_manual_scenario_count", 0)) != 6:
		failures.append("playtest packet should include six manual scenarios")
	if Array(packet.get("scenario_drafts", [])).size() != 6:
		failures.append("playtest packet should expose six scenario drafts")
	var markdown := str(packet.get("markdown", ""))
	for token in [
		"Manual Playtest Packet",
		"Draft only",
		"does not record release evidence",
		"record_playtest_notes_evidence.gd",
		"Manual Scenario List",
		"launch_manual_scenario.ps1 -List",
		"Next Missing Launch",
		"launch_manual_scenario.ps1 -Next",
		"launch_manual_scenario.ps1 -Next -DryRun",
		"launch_manual_scenario.ps1 -ScenarioIndex 1",
		"launch_manual_scenario.ps1 -ScenarioIndex 1 -Detached",
		"launch_manual_scenario.ps1 -ScenarioIndex 1 -Detached -DryRun",
		"record_manual_scenario_evidence.gd",
		"record_manual_playtest_issue.gd",
		"resolve_manual_playtest_issue.gd",
		"--confirm-human-playtest=true",
		"--confirm-human-retest=true",
		"--issue_type=<issue_type>",
		"--resolution_result=fixed_retest_pass",
		"Notes Skeleton:",
		"Suggested Screenshot:",
		"dungeon_core_manual_scenario_1.png",
		"Capture Screenshot:",
		"--screenshot_or_seed=",
		"Final Notes:",
		"asset_animation_notes",
		"polygon_collision_notes",
		"wave_hud_audio_notes",
		"wave_hud_audio_notes=<human wave hud audio notes>",
		"fanmade",
		"CalvinWan0101/soul-knight",
		"leoyin1127/Soul-knights",
		"review_asset_candidate.gd",
		"print_asset_replacement_plan.gd",
		"--kind=vfx",
		"--kind=audio",
		"--kind=collision",
		"--kind=object_visual",
		"--kind=sprite",
		"--manifest=<manifest.json>",
		"Wave/HUD/Audio Live Check",
		"Wave x/y",
		"enemies_left",
		"WaveStartSfx",
		"objective_context_changed",
	]:
		if not markdown.contains(token):
			failures.append("playtest packet markdown missing token: %s" % token)
	var asset_review_commands: Dictionary = packet.get("asset_review_commands", {})
	for key in [
			"sprite_checklist",
			"vfx_checklist",
			"audio_checklist",
			"collision_checklist",
			"object_visual_checklist",
			"replacement_plan",
	]:
		var command := str(asset_review_commands.get(key, ""))
		if command == "":
			failures.append("playtest packet should include asset review command: %s" % key)
		elif command.contains("<") or command.contains(">"):
			failures.append("asset review checklist command should be executable: %s" % key)
		elif not markdown.contains(command):
			failures.append("playtest packet markdown should include asset review command: %s" % key)
	var manifest_command := str(asset_review_commands.get("manifest_candidate_template", ""))
	if not manifest_command.contains("--manifest=<manifest.json>"):
		failures.append("playtest packet should include manifest candidate review template")
	for raw_draft in Array(packet.get("scenario_drafts", [])):
		if not (raw_draft is Dictionary):
			failures.append("scenario draft should be a dictionary")
			continue
		var draft: Dictionary = raw_draft
		if str(draft.get("record_command", "")).contains("headless_rehearsal"):
			failures.append("scenario draft must not suggest headless rehearsal evidence")
		var launch_dry_run := str(draft.get("launch_dry_run_command", ""))
		if launch_dry_run.strip_edges() == "":
			failures.append("scenario draft should include launcher dry-run command")
		elif not launch_dry_run.contains("-DryRun"):
			failures.append("scenario draft launcher dry-run command should include -DryRun")
		if not str(draft.get("suggested_screenshot_path", "")).contains(
				"dungeon_core_manual_scenario_%d.png" % int(draft.get("index", 0))):
			failures.append("scenario %d should expose a deterministic screenshot path" % int(draft.get("index", 0)))
		if not str(draft.get("capture_helper_command", "")).contains(
				str(draft.get("suggested_screenshot_path", ""))):
			failures.append("scenario %d capture helper should write its suggested screenshot path" % int(draft.get("index", 0)))
		if not str(draft.get("record_command", "")).contains(
				"--screenshot_or_seed=<screenshot or seed>"):
			failures.append("scenario draft should require screenshot/seed for manual pass")
		if str(draft.get("record_issue_command", "")).strip_edges() == "":
			failures.append("scenario draft should include a manual issue record command")
		if str(draft.get("resolve_issue_command", "")).strip_edges() == "":
			failures.append("scenario draft should include a manual issue resolve command")
		if str(draft.get("human_notes_placeholder", "")).strip_edges() == "":
			failures.append("scenario draft should include human notes placeholder")
		var seed_token := "seed_%d_dry_run" % int(draft.get("seed", 0))
		for key in [
			"launch_dry_run_command",
			"record_dry_run_command",
			"record_issue_dry_run_command",
			"resolve_issue_dry_run_command",
		]:
			if not str(draft.get(key, "")).contains(seed_token):
				if key == "launch_dry_run_command":
					if not str(draft.get(key, "")).contains("-ScenarioIndex %d" % int(draft.get("index", 0))):
						failures.append("scenario %d launcher dry-run should use its own scenario index" % int(draft.get("index", 0)))
				else:
					failures.append("scenario %d %s should use its own seed evidence token: %s" % [
						int(draft.get("index", 0)),
						key,
						seed_token,
					])

func _check_packet_file(packet: Dictionary, failures: Array[String]) -> void:
	if not FileAccess.file_exists(PACKET_DOC_PATH):
		failures.append("generated playtest packet doc should exist")
		return
	var markdown := FileAccess.get_file_as_string(PACKET_DOC_PATH)
	_expect_executable_dry_run_command(
		markdown, str(packet.get("notes_dry_run_command", "")),
		"notes dry-run command", failures)
	for raw_draft in Array(packet.get("scenario_drafts", [])):
		if not (raw_draft is Dictionary):
			continue
		var draft: Dictionary = raw_draft
		for key in [
			"launch_dry_run_command",
			"record_dry_run_command",
			"record_issue_dry_run_command",
			"resolve_issue_dry_run_command",
		]:
			_expect_executable_dry_run_command(
				markdown, str(draft.get(key, "")),
				"scenario %d %s" % [int(draft.get("index", 0)), key],
				failures)

func _expect_executable_dry_run_command(
		markdown: String,
		command: String,
		label: String,
		failures: Array[String],
) -> void:
	if command.contains("<") or command.contains(">"):
		failures.append("%s should be executable without placeholder edits" % label)
	if not markdown.contains(command):
		failures.append("packet doc should contain current executable %s" % label)
