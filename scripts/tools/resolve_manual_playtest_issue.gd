extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	if _arg("confirm-human-retest") != "true":
		push_error("Manual playtest issue resolution requires --confirm-human-retest=true")
		quit(1)
		return
	var scenario := _scenario_from_args()
	if scenario.is_empty():
		push_error("Missing scenario. Use --scenario-index=1..6 or explicit seed/mode/class_id/goal args")
		quit(1)
		return
	var issue_type := _arg("issue_type").strip_edges()
	var normalized_issue_type := ReleaseAuditScript.manual_playtest_issue_type_normalized(
		issue_type)
	var result := _arg("resolution_result").to_lower()
	var evidence_source := _arg("evidence_source")
	var notes := _arg("resolution_notes")
	if issue_type == "":
		push_error("Manual playtest issue resolution requires --issue_type=")
		quit(1)
		return
	if not ReleaseAuditScript.manual_playtest_issue_type_valid(issue_type):
		push_error("Invalid manual playtest issue_type: %s | allowed: %s" % [
			issue_type,
			ReleaseAuditScript.manual_playtest_issue_type_summary(),
		])
		quit(1)
		return
	issue_type = normalized_issue_type
	if not ["fixed", "fixed_retest_pass", "resolved", "verified"].has(result):
		push_error("Manual playtest issue resolution must be fixed/fixed_retest_pass/resolved/verified, not %s" % result)
		quit(1)
		return
	if not ReleaseAuditScript.manual_evidence_source_valid(evidence_source):
		push_error("Manual playtest issue resolution requires --evidence_source=manual_playtest; headless_rehearsal is not valid")
		quit(1)
		return
	if notes == "":
		push_error("Manual playtest issue resolution requires --resolution_notes=")
		quit(1)
		return
	if ReleaseAuditScript.manual_evidence_value_placeholder(notes):
		push_error("Placeholder evidence is not valid for manual playtest issue resolution_notes")
		quit(1)
		return
	var screenshot_or_seed := _arg("screenshot_or_seed")
	if screenshot_or_seed == "":
		push_error("Manual playtest issue resolution requires --screenshot_or_seed=")
		quit(1)
		return
	if ReleaseAuditScript.manual_evidence_value_placeholder(screenshot_or_seed):
		push_error("Placeholder evidence is not valid for manual playtest issue screenshot_or_seed")
		quit(1)
		return
	scenario["scenario_index"] = int(_arg("scenario-index"))
	scenario["issue_type"] = issue_type
	scenario["resolution_result"] = result
	scenario["evidence_source"] = evidence_source
	scenario["resolution_notes"] = notes
	scenario["screenshot_or_seed"] = screenshot_or_seed
	if _dry_run():
		print("Manual playtest issue resolution dry run OK: seed %d | %s | %s" % [
			int(scenario.get("seed", 0)),
			str(scenario.get("mode", "")),
			str(issue_type),
		])
		print("No release evidence recorded")
		quit(0)
		return
	var data := MetaProgressionScript.resolve_release_candidate_manual_playtest_issue(scenario)
	var evidence := MetaProgressionScript.release_candidate_evidence(data)
	var open_count := Array(evidence.get("manual_playtest_issues", [])).size()
	var resolved_count := Array(evidence.get("manual_playtest_resolved_issues", [])).size()
	var pass_count := Array(evidence.get("manual_scenario_results", [])).size()
	if resolved_count <= 0:
		push_error("Manual playtest issue was not resolved; check scenario seed/mode/class/goal and issue_type")
		quit(1)
		return
	print("Manual playtest issue resolved: %d resolved | %d open | scenario passes unchanged %d/6 | seed %d | %s" % [
		resolved_count,
		open_count,
		pass_count,
		int(scenario.get("seed", 0)),
		str(issue_type),
	])
	quit(0)

func _scenario_from_args() -> Dictionary:
	var scenarios := Array(ReleaseAuditScript.manual_playtest_checklist().get("scenario_runs", []))
	var index_text := _arg("scenario-index")
	if index_text != "":
		var raw_index := int(index_text)
		var index := raw_index - 1 if raw_index > 0 else raw_index
		if index >= 0 and index < scenarios.size() and scenarios[index] is Dictionary:
			return Dictionary(scenarios[index]).duplicate(true)
	var seed := int(_arg("seed"))
	var mode := _arg("mode")
	var class_id := _arg("class_id")
	var goal := _arg("goal")
	if seed <= 0 or mode == "" or class_id == "" or goal == "":
		return {}
	return {
		"seed": seed,
		"mode": mode,
		"class_id": class_id,
		"goal": goal,
	}

func _arg(name: String) -> String:
	var prefix := "--%s=" % name
	for raw_arg in OS.get_cmdline_user_args():
		var text := str(raw_arg).strip_edges()
		if text.begins_with(prefix):
			return text.trim_prefix(prefix).strip_edges()
	return ""

func _dry_run() -> bool:
	return ["true", "1", "yes"].has(_arg("dry-run").to_lower()) \
		or ["true", "1", "yes"].has(_arg("dry_run").to_lower())
