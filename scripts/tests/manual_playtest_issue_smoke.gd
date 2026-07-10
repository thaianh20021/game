extends SceneTree

const SAVE_PATH := "user://manual_playtest_issue_smoke.json"

func _init() -> void:
	var failures: Array[String] = []
	var meta_script = load("res://scripts/progression/meta_progression.gd")
	var audit_script = load("res://scripts/assets/release_audit.gd")
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	_check_issue_remediation(audit_script, failures)

	if not _script_has_method(meta_script, "record_release_candidate_manual_playtest_issue"):
		failures.append("MetaProgression should record manual playtest issues separately from pass evidence")
	else:
		meta_script.call("record_release_candidate_evidence", {
			"full_smoke_suite": {"passed": true, "count": 80},
		}, SAVE_PATH)
		var issue := {
			"scenario_index": 4,
			"seed": 420104,
			"mode": "hardcore",
			"class_id": "nightblade",
			"goal": "verify lethal damage/readability feels fair",
			"result": "blocked",
			"issue_type": "polygon_collision",
			"evidence_source": "manual_playtest",
			"notes": "saw trap polygon hits outside visible frame; do not release",
			"screenshot_or_seed": "seed 420104 room trap_cache",
		}
		var recorded: Dictionary = meta_script.call(
			"record_release_candidate_manual_playtest_issue", issue, SAVE_PATH)
		var evidence: Dictionary = meta_script.call("release_candidate_evidence", recorded)
		if int(Dictionary(evidence.get("full_smoke_suite", {})).get("count", 0)) != 80:
			failures.append("manual playtest issue recorder should preserve existing evidence")
		if not Array(evidence.get("manual_scenario_results", [])).is_empty():
			failures.append("manual playtest issues must not count as scenario passes")
		var issues: Array = evidence.get("manual_playtest_issues", [])
		if issues.size() != 1:
			failures.append("manual playtest issue recorder should append one issue")
		else:
			var stored: Dictionary = issues[0]
			if str(stored.get("result", "")) != "blocked":
				failures.append("manual playtest issue should preserve non-pass result")
			if str(stored.get("issue_type", "")) != "polygon_collision":
				failures.append("manual playtest issue should preserve issue type")
			if str(stored.get("evidence_source", "")) != "manual_playtest":
				failures.append("manual playtest issue should preserve manual source")
		var summary: Dictionary = audit_script.call("release_candidate_summary", recorded)
		if bool(summary.get("manual_scenarios_ready", true)):
			failures.append("manual playtest issue should not satisfy manual scenarios")
		if int(summary.get("manual_playtest_issue_count", 0)) != 1:
			failures.append("release summary should expose manual playtest issue count")
		if not Array(summary.get("blockers", [])).has("manual_playtest_issues_open"):
			failures.append("release summary should block release when manual playtest issues are open")
		if not str(summary.get("next_action", "")).contains("manual playtest issue"):
			failures.append("release summary should direct fixes toward open manual playtest issues")

		var pass_like_issue := issue.duplicate(true)
		pass_like_issue["result"] = "pass"
		pass_like_issue["notes"] = "pass-like issue should not overwrite issue list"
		var rejected: Dictionary = meta_script.call(
			"record_release_candidate_manual_playtest_issue", pass_like_issue, SAVE_PATH)
		var rejected_evidence: Dictionary = meta_script.call("release_candidate_evidence", rejected)
		if Array(rejected_evidence.get("manual_playtest_issues", [])).size() != 1:
			failures.append("manual playtest issue recorder should reject pass-like results")
		if not _script_has_method(meta_script, "resolve_release_candidate_manual_playtest_issue"):
			failures.append("MetaProgression should resolve fixed manual playtest issues after human retest")
		else:
			var resolved: Dictionary = meta_script.call(
				"resolve_release_candidate_manual_playtest_issue", {
					"scenario_index": 4,
					"seed": 420104,
					"mode": "hardcore",
					"class_id": "nightblade",
					"goal": "verify lethal damage/readability feels fair",
					"issue_type": "polygon_collision",
					"resolution_result": "fixed_retest_pass",
					"evidence_source": "manual_playtest",
					"resolution_notes": "polygon adjusted and replayed seed 420104 without phantom hit",
				}, SAVE_PATH)
			var resolved_evidence: Dictionary = meta_script.call(
				"release_candidate_evidence", resolved)
			if not Array(resolved_evidence.get("manual_playtest_issues", [])).is_empty():
				failures.append("resolved manual playtest issue should leave no open issue")
			var resolved_issues: Array = resolved_evidence.get(
				"manual_playtest_resolved_issues", [])
			if resolved_issues.size() != 1:
				failures.append("manual playtest issue resolution should keep audit history")
			elif str(Dictionary(resolved_issues[0]).get("resolution_result", "")) \
					!= "fixed_retest_pass":
				failures.append("manual playtest issue resolution should preserve retest result")
			if not Array(resolved_evidence.get("manual_scenario_results", [])).is_empty():
				failures.append("manual playtest issue resolution must not create scenario pass evidence")
			var resolved_summary: Dictionary = audit_script.call(
				"release_candidate_summary", resolved)
			if int(resolved_summary.get("manual_playtest_issue_count", -1)) != 0:
				failures.append("release summary should count only open manual playtest issues")
			if Array(resolved_summary.get("blockers", [])).has("manual_playtest_issues_open"):
				failures.append("release summary should clear manual issue blocker after resolution")

	var tool_path := "res://scripts/tools/record_manual_playtest_issue.gd"
	if not ResourceLoader.exists(tool_path):
		failures.append("release workflow should include a manual playtest issue recorder tool")
	else:
		var tool_source := FileAccess.get_file_as_string(tool_path)
		for token in ["record_release_candidate_manual_playtest_issue",
				"confirm-human-playtest", "issue_type", "manual_scenario_results",
				"Manual playtest issue requires --screenshot_or_seed=",
				"manual_playtest_issue_remediation",
				"Asset Review:",
				"Asset Replacement Plan:",
				"Allowed Sources:",
				"Fanmade Policy:",
				"Self Review Gate:",
				"Missing Polygon Next Actions:"]:
			if not tool_source.contains(token):
				failures.append("manual playtest issue recorder tool missing token: %s" % token)
	var resolve_tool_path := "res://scripts/tools/resolve_manual_playtest_issue.gd"
	if not ResourceLoader.exists(resolve_tool_path):
		failures.append("release workflow should include a manual playtest issue resolver tool")
	else:
		var resolve_tool_source := FileAccess.get_file_as_string(resolve_tool_path)
		for token in ["resolve_release_candidate_manual_playtest_issue",
				"confirm-human-retest", "resolution_result", "manual_scenario_results",
				"Manual playtest issue resolution requires --screenshot_or_seed="]:
			if not resolve_tool_source.contains(token):
				failures.append("manual playtest issue resolver tool missing token: %s" % token)
	var plan: Dictionary = audit_script.call("release_candidate_manual_recording_plan", {})
	for raw_status in Array(plan.get("scenario_statuses", [])):
		if not (raw_status is Dictionary):
			failures.append("manual recording plan scenario status should be a dictionary")
			continue
		var status: Dictionary = raw_status
		var issue_command := str(status.get("issue_command", "")).strip_edges()
		var resolve_command := str(status.get("resolve_command", "")).strip_edges()
		if issue_command == "":
			failures.append("manual recording plan should include issue command per scenario")
		elif not issue_command.contains("record_manual_playtest_issue.gd"):
			failures.append("manual recording plan issue command should name recorder tool")
		if resolve_command == "":
			failures.append("manual recording plan should include resolve command per scenario")
		elif not resolve_command.contains("resolve_manual_playtest_issue.gd"):
			failures.append("manual recording plan resolve command should name resolver tool")
		break
	var status_tool_path := "res://scripts/tools/release_candidate_status.gd"
	if not ResourceLoader.exists(status_tool_path):
		failures.append("release workflow should include release candidate status tool")
	else:
		var status_tool_source := FileAccess.get_file_as_string(status_tool_path)
		for token in ["Issue:", "Resolve:", "issue_command", "resolve_command",
				"manual_playtest_issue_remediation", "Asset Review:",
				"asset_replacement_plan", "Asset Replacement Plan:",
				"Asset Replacement Plans:",
				"print_asset_replacement_plan.gd"]:
			if not status_tool_source.contains(token):
				failures.append("release candidate status tool missing issue workflow token: %s" % token)
		for asset_kind in ["sprite", "vfx", "audio", "collision", "object_visual"]:
			if not status_tool_source.contains("\"%s\"" % asset_kind):
				failures.append("release candidate status tool missing replacement plan kind: %s" % asset_kind)

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	if failures.is_empty():
		print("Manual playtest issue smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _script_has_method(script: Script, method_name: String) -> bool:
	for method in script.get_script_method_list():
		if String(method.get("name", "")) == method_name:
			return true
	return false

func _check_issue_remediation(audit_script: Script, failures: Array[String]) -> void:
	if not _script_has_method(audit_script, "manual_playtest_issue_remediation"):
		failures.append("ReleaseAudit should expose manual_playtest_issue_remediation")
		return
	var polygon: Dictionary = audit_script.call(
		"manual_playtest_issue_remediation", "poligon")
	if str(polygon.get("issue_type", "")) != "polygon_collision":
		failures.append("poligon remediation should normalize to polygon_collision")
	if str(polygon.get("asset_kind", "")) != "collision":
		failures.append("polygon collision remediation should review collision assets")
	if not str(polygon.get("asset_review_command", "")).contains("--kind=collision"):
		failures.append("polygon collision remediation should include collision review command")
	if not str(polygon.get("asset_replacement_plan_command", "")).contains("--kind=collision"):
		failures.append("polygon collision remediation should include collision replacement plan command")
	if not str(polygon.get("source_order_text", "")).contains("project polygon"):
		failures.append("polygon collision remediation should expose source order text")
	if not Array(polygon.get("release_self_review_gate", [])).has("polygon_points_px"):
		failures.append("polygon collision remediation should require polygon point review")
	if not Array(polygon.get("missing_polygon_next_actions", [])).has("attach_polygon_points_px"):
		failures.append("polygon collision remediation should include concrete polygon next actions")
	var animation: Dictionary = audit_script.call(
		"manual_playtest_issue_remediation", "animation")
	if str(animation.get("issue_type", "")) != "asset_animation":
		failures.append("animation remediation should normalize to asset_animation")
	if str(animation.get("asset_kind", "")) != "sprite":
		failures.append("asset animation remediation should review sprite frame grids")
	if not str(animation.get("asset_review_command", "")).contains("--kind=sprite"):
		failures.append("asset animation remediation should include sprite review command")
	if not str(animation.get("asset_replacement_plan_command", "")).contains("--kind=sprite"):
		failures.append("asset animation remediation should include sprite replacement plan command")
	if not Array(animation.get("release_self_review_gate", [])).has("origin_px"):
		failures.append("asset animation remediation should require origin_px review")
	var missing: Dictionary = audit_script.call(
		"manual_playtest_issue_remediation", "missing_asset_source")
	if not str(missing.get("asset_review_command", "")).contains("--manifest=<manifest.json>"):
		failures.append("missing asset remediation should include manifest review template")
	if not str(missing.get("asset_replacement_plan_command", "")).contains("--kind=object_visual"):
		failures.append("missing asset remediation should include object visual replacement plan command")
	if Array(missing.get("allowed_replacement_sources", [])).has("fanmade_direct_copy"):
		failures.append("missing asset remediation should not allow fanmade direct copy")
	if str(missing.get("fanmade_policy", "")) == "":
		failures.append("missing asset remediation should expose fanmade reference-only policy")
