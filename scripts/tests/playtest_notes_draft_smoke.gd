extends SceneTree

const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var failures: Array[String] = []
	_check_empty_progress_draft(failures)
	_check_next_missing_scenario_draft(failures)
	if failures.is_empty():
		print("Playtest notes draft smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_empty_progress_draft(failures: Array[String]) -> void:
	var plan := ReleaseAuditScript.release_candidate_manual_recording_plan()
	var draft: Dictionary = plan.get("playtest_notes_draft", {})
	_expect_draft_for_scenario(draft, 1, failures)
	var packet := ReleaseAuditScript.release_candidate_playtest_packet()
	var packet_draft: Dictionary = packet.get("playtest_notes_draft", {})
	_expect_draft_for_scenario(packet_draft, 1, failures)
	var markdown := str(packet.get("markdown", ""))
	for token in [
		"Playtest Notes Draft",
		"--seed=420101",
		"--class_id=blade_warden",
		"--mode=normal",
		"--replay_last_run_result=<human result>",
		"--asset_animation_notes=<human animation notes>",
		"--polygon_collision_notes=<human polygon notes>",
		"--wave_hud_audio_notes=<human wave hud audio notes>",
	]:
		if not markdown.contains(token):
			failures.append("packet markdown missing playtest draft token: %s" % token)

func _check_next_missing_scenario_draft(failures: Array[String]) -> void:
	var scenario_one := _scenario_result(1)
	var plan := ReleaseAuditScript.release_candidate_manual_recording_plan({
		"manual_scenario_results": [scenario_one],
	})
	var draft: Dictionary = plan.get("playtest_notes_draft", {})
	_expect_draft_for_scenario(draft, 2, failures)

func _expect_draft_for_scenario(
		draft: Dictionary,
		scenario_index: int,
		failures: Array[String],
) -> void:
	var scenario := _scenario_result(scenario_index)
	if int(draft.get("scenario_index", 0)) != scenario_index:
		failures.append("playtest notes draft should target scenario %d" % scenario_index)
	for field in ["seed", "class_id", "mode"]:
		if str(draft.get(field, "")) != str(scenario.get(field, "")):
			failures.append("draft %s should match scenario %d" % [field, scenario_index])
	var command := str(draft.get("command", ""))
	for token in [
		"record_playtest_notes_evidence.gd",
		"--seed=%d" % int(scenario.get("seed", 0)),
		"--class_id=%s" % str(scenario.get("class_id", "")),
		"--mode=%s" % str(scenario.get("mode", "")),
		"--replay_last_run_result=<human result>",
		"--daily_fingerprint_hash=<daily hash>",
		"--pace_avg_sec=<avg sec>",
		"--pace_boss_sec=<boss sec>",
		"--asset_animation_notes=<human animation notes>",
		"--polygon_collision_notes=<human polygon notes>",
		"--wave_hud_audio_notes=<human wave hud audio notes>",
		"--blocker_screenshot_or_seed=<screenshot or seed>",
		"--release_decision=<hold or ready>",
	]:
		if not command.contains(token):
			failures.append("playtest notes draft command missing token: %s" % token)
	if command.contains("manual_scenario_results") or command.contains("headless_rehearsal"):
		failures.append("playtest notes draft must not record manual scenario evidence")

func _scenario_result(scenario_index: int) -> Dictionary:
	var scenarios := Array(ReleaseAuditScript.manual_playtest_checklist().get("scenario_runs", []))
	var scenario: Dictionary = scenarios[scenario_index - 1]
	var result := scenario.duplicate(true)
	result["result"] = "pass"
	result["evidence_source"] = "manual_playtest"
	result["notes"] = "animation stable; polygon collision matched sprite; wave HUD audio cues clear"
	result["screenshot_or_seed"] = "seed_%d_manual_pass" % int(result.get("seed", 0))
	return result
