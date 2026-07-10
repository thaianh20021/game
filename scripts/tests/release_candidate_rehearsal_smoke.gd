extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_headless_scenario_rehearsal(failures)
	if failures.is_empty():
		print("Release candidate rehearsal smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_headless_scenario_rehearsal(failures: Array[String]) -> void:
	var release_audit: Variant = load(RELEASE_AUDIT_PATH)
	if not release_audit.has_method("release_candidate_rehearsal_results"):
		failures.append("ReleaseAudit should expose release_candidate_rehearsal_results")
		return
	var rehearsal: Dictionary = release_audit.call("release_candidate_rehearsal_results")
	if str(rehearsal.get("review_type", "")) != "headless_scenario_contract_rehearsal":
		failures.append("rehearsal should identify itself as headless scenario contract evidence")
	if bool(rehearsal.get("manual_playtest_replacement", true)):
		failures.append("headless rehearsal should not claim to replace manual playtest")
	if not bool(rehearsal.get("passed", false)):
		failures.append("headless rehearsal should pass when checklist scenario contracts are valid")
	var checklist: Dictionary = release_audit.call("manual_playtest_checklist")
	var scenarios: Array = checklist.get("scenario_runs", [])
	var results: Array = rehearsal.get("results", [])
	if results.size() != scenarios.size():
		failures.append("headless rehearsal should return one result per manual scenario")
	var modes := {}
	var classes := {}
	for raw in results:
		if not (raw is Dictionary):
			failures.append("headless rehearsal result should be a dictionary")
			continue
		var result: Dictionary = raw
		modes[str(result.get("mode", ""))] = true
		classes[str(result.get("class_id", ""))] = true
		for key in ["seed", "mode", "class_id", "goal", "result", "notes", "evidence_source"]:
			if not result.has(key) or str(result.get(key, "")).strip_edges() == "":
				failures.append("headless rehearsal result missing %s" % key)
		if int(result.get("seed", 0)) <= 0:
			failures.append("headless rehearsal should preserve a positive seed")
		if str(result.get("result", "")) != "pass":
			failures.append("headless rehearsal should use pass for valid scenario contracts")
		if str(result.get("evidence_source", "")) != "headless_rehearsal":
			failures.append("headless rehearsal should mark evidence_source=headless_rehearsal")
		if not bool(result.get("class_contract_ok", false)):
			failures.append("headless rehearsal should verify class contract")
		if not bool(result.get("mode_contract_ok", false)):
			failures.append("headless rehearsal should verify mode contract")
		if not str(result.get("notes", "")).to_lower().contains("human"):
			failures.append("headless rehearsal notes should keep human playtest requirement explicit")
	for mode in ["normal", "boss_rush", "endless", "hardcore", "elemental_chaos", "balance_lab"]:
		if not modes.has(mode):
			failures.append("headless rehearsal missing mode %s" % mode)
	if classes.size() < 6:
		failures.append("headless rehearsal should cover at least six classes")
	var candidate: Dictionary = release_audit.call("release_candidate_summary", {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": _complete_notes(),
		"headless_scenario_rehearsal": rehearsal,
		"asset_self_review": release_audit.call("release_asset_self_review"),
		"export_package": {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		},
	})
	if not bool(candidate.get("scenario_rehearsal_ready", false)):
		failures.append("release candidate should expose ready headless scenario rehearsal evidence")
	if bool(candidate.get("manual_scenarios_ready", true)):
		failures.append("headless rehearsal should not satisfy manual scenario gate")
	if not Array(candidate.get("blockers", [])).has("manual_scenarios_missing"):
		failures.append("release candidate should still require manual scenario evidence")

func _complete_notes() -> Dictionary:
	return {
		"seed": 420101,
		"class_id": "blade_warden",
		"mode": "normal",
		"replay_last_run_result": "same seed/class/mode verified",
		"daily_fingerprint_hash": "daily-420101-ok",
		"pace_avg_sec": 42.0,
		"pace_boss_sec": 85.0,
		"asset_animation_notes": "idle/run/dash/attack frames stable",
		"polygon_collision_notes": "runtime polygons match sprite silhouettes",
		"wave_hud_audio_notes": "wave counter, enemies left, and wave cues verified",
		"blocker_screenshot_or_seed": "none",
		"release_decision": "public_ok",
	}
