extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	if _arg("confirm-human-playtest") != "true":
		push_error("Manual playtest issue requires --confirm-human-playtest=true")
		quit(1)
		return
	var scenario := _scenario_from_args()
	if scenario.is_empty():
		push_error("Missing scenario. Use --scenario-index=1..6 or explicit seed/mode/class_id/goal args")
		quit(1)
		return
	var result := _arg("result").to_lower()
	var issue_type := _arg("issue_type").strip_edges()
	var normalized_issue_type := ReleaseAuditScript.manual_playtest_issue_type_normalized(
		issue_type)
	var evidence_source := _arg("evidence_source")
	var notes := _arg("notes")
	if not ["fail", "failed", "blocked", "bug", "needs_fix", "regression"].has(result):
		push_error("Manual playtest issue result must be fail/failed/blocked/bug/needs_fix/regression, not %s" % result)
		quit(1)
		return
	if issue_type == "":
		push_error("Manual playtest issue requires --issue_type=")
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
	if not ReleaseAuditScript.manual_evidence_source_valid(evidence_source):
		push_error("Manual playtest issue requires --evidence_source=manual_playtest; headless_rehearsal is not valid")
		quit(1)
		return
	if notes == "":
		push_error("Manual playtest issue requires --notes=")
		quit(1)
		return
	if ReleaseAuditScript.manual_evidence_value_placeholder(notes):
		push_error("Placeholder evidence is not valid for manual playtest issue notes")
		quit(1)
		return
	var screenshot_or_seed := _arg("screenshot_or_seed")
	if screenshot_or_seed == "":
		push_error("Manual playtest issue requires --screenshot_or_seed=")
		quit(1)
		return
	if ReleaseAuditScript.manual_evidence_value_placeholder(screenshot_or_seed):
		push_error("Placeholder evidence is not valid for manual playtest issue screenshot_or_seed")
		quit(1)
		return
	var remediation: Dictionary = ReleaseAuditScript.manual_playtest_issue_remediation(issue_type)
	scenario["scenario_index"] = int(_arg("scenario-index"))
	scenario["result"] = result
	scenario["issue_type"] = issue_type
	scenario["evidence_source"] = evidence_source
	scenario["notes"] = notes
	scenario["screenshot_or_seed"] = screenshot_or_seed
	if _dry_run():
		print("Manual playtest issue dry run OK: seed %d | %s | %s" % [
			int(scenario.get("seed", 0)),
			str(scenario.get("mode", "")),
			str(issue_type),
		])
		_print_remediation(remediation)
		print("No release evidence recorded")
		quit(0)
		return
	var data := MetaProgressionScript.record_release_candidate_manual_playtest_issue(scenario)
	var evidence := MetaProgressionScript.release_candidate_evidence(data)
	var issue_count := Array(evidence.get("manual_playtest_issues", [])).size()
	var pass_count := Array(evidence.get("manual_scenario_results", [])).size()
	if issue_count <= 0:
		push_error("Manual playtest issue was not recorded")
		quit(1)
		return
	print("Manual playtest issue recorded: %d open | scenario passes unchanged %d/6 | seed %d | %s | %s" % [
		issue_count,
		pass_count,
		int(scenario.get("seed", 0)),
		str(scenario.get("mode", "")),
		str(issue_type),
	])
	_print_remediation(remediation)
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

func _print_remediation(remediation: Dictionary) -> void:
	var command := str(remediation.get("asset_review_command", "")).strip_edges()
	var replacement_plan := str(remediation.get("asset_replacement_plan_command", "")).strip_edges()
	var hint := str(remediation.get("fix_hint", "")).strip_edges()
	var source_order := str(remediation.get("source_order_text", "")).strip_edges()
	var fanmade_policy := str(remediation.get("fanmade_policy", "")).strip_edges()
	if command != "":
		print("Asset Review: %s" % command)
	if replacement_plan != "":
		print("Asset Replacement Plan: %s" % replacement_plan)
	if source_order != "":
		print("Allowed Sources: %s" % source_order)
	if fanmade_policy != "":
		print("Fanmade Policy: %s" % fanmade_policy)
	_print_array("Self Review Gate:", Array(remediation.get("release_self_review_gate", [])))
	_print_array("Missing Polygon Next Actions:", Array(
		remediation.get("missing_polygon_next_actions", [])))
	if hint != "":
		print("Fix Hint: %s" % hint)

func _print_array(label: String, values: Array) -> void:
	if values.is_empty():
		return
	var parts: Array[String] = []
	for value in values:
		var text := str(value).strip_edges()
		if text != "" and not parts.has(text):
			parts.append(text)
	if not parts.is_empty():
		var separator := " " if label.ends_with(":") else ": "
		print("%s%s%s" % [label, separator, ", ".join(parts)])
