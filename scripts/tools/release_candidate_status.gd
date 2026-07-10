extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var meta := MetaProgressionScript.load_data()
	var evidence := MetaProgressionScript.release_candidate_evidence(meta)
	var summary: Dictionary = ReleaseAuditScript.release_candidate_summary(meta)
	var plan: Dictionary = ReleaseAuditScript.release_candidate_manual_recording_plan(meta)
	print(MetaProgressionScript.release_candidate_evidence_summary(meta))
	print("Release Candidate: %s | %s" % [
		str(summary.get("status", "")),
		str(summary.get("next_action", "")),
	])
	print("Blockers: %s" % ", ".join(Array(summary.get("blockers", []))))
	print("Playtest Notes: %s" % ("OK" if bool(plan.get("playtest_notes_ready", false)) else "Missing"))
	if not bool(plan.get("playtest_notes_ready", false)):
		print("Notes Command: %s" % str(Dictionary(plan.get("commands", {})).get(
			"playtest_notes", "")))
		print("Notes Dry Run: %s" % str(Dictionary(plan.get("commands", {})).get(
			"playtest_notes_dry_run", "")))
		var notes_draft: Dictionary = plan.get("playtest_notes_draft", {})
		if not notes_draft.is_empty():
			print("Notes Draft: %s" % str(notes_draft.get("command", "")))
	print("Manual Scenarios: %d/%d recorded | %d missing" % [
		int(plan.get("manual_scenario_count", 0)),
		int(plan.get("required_manual_scenario_count", 0)),
		int(plan.get("missing_manual_scenario_count", 0)),
	])
	print("Manual Notes Required: %s" % ", ".join(Array(
		plan.get("manual_scenario_notes_required_tokens", []))))
	print("Manual Scenario List: powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -List")
	if int(plan.get("next_missing_manual_index", 0)) > 0:
		print("Next Missing Manual Scenario: %d" % int(
			plan.get("next_missing_manual_index", 0)))
		print("Next Missing Manual Launch Dry Run: %s" % str(
			plan.get("next_missing_manual_launch_dry_run_command", "")))
		print("Next Missing Manual Launch: %s" % str(
			plan.get("next_missing_manual_launch_command", "")))
		print("Next Missing Manual Dry Run: %s" % str(
			plan.get("next_missing_manual_dry_run_command", "")))
	var progress_table := str(plan.get("progress_table_text", ""))
	if progress_table != "":
		print(progress_table)
	var issues := Array(evidence.get("manual_playtest_issues", []))
	var resolved_issues := Array(evidence.get("manual_playtest_resolved_issues", []))
	print("Manual Playtest Issues: %d open | %d resolved" % [
		issues.size(),
		resolved_issues.size(),
	])
	print("Issue Types: %s" % str(ReleaseAuditScript.manual_playtest_issue_type_summary()))
	print("Issue Aliases: %s" % str(
		ReleaseAuditScript.manual_playtest_issue_type_alias_summary()))
	print("Asset Replacement Plans:")
	for asset_kind in ["sprite", "vfx", "audio", "collision", "object_visual"]:
		print("  %s: %s" % [asset_kind, _asset_replacement_plan_command(asset_kind)])
	for raw_issue in issues.slice(0, 3):
		if not (raw_issue is Dictionary):
			continue
		var issue: Dictionary = raw_issue
		print("  Issue seed=%d mode=%s class=%s type=%s result=%s | %s" % [
			int(issue.get("seed", 0)),
			str(issue.get("mode", "")),
			str(issue.get("class_id", "")),
			str(issue.get("issue_type", "")),
			str(issue.get("result", "")),
			str(issue.get("notes", "")),
		])
		var remediation: Dictionary = ReleaseAuditScript.manual_playtest_issue_remediation(
			str(issue.get("issue_type", "")))
		var asset_review := str(remediation.get("asset_review_command", "")).strip_edges()
		if asset_review != "":
			print("    Asset Review: %s" % asset_review)
		var asset_kind := str(remediation.get("asset_kind", "")).strip_edges()
		if asset_kind != "":
			var replacement_plan: Dictionary = ReleaseAuditScript.asset_replacement_plan(asset_kind)
			print("    Asset Replacement Plan: %s" % _asset_replacement_plan_command(
				str(replacement_plan.get("kind", asset_kind))))
		var fix_hint := str(remediation.get("fix_hint", "")).strip_edges()
		if fix_hint != "":
			print("    Fix Hint: %s" % fix_hint)
	for raw_status in Array(plan.get("scenario_statuses", [])):
		if not (raw_status is Dictionary):
			continue
		var status: Dictionary = raw_status
		print("Scenario %d [%s] seed=%d mode=%s class=%s | %s" % [
			int(status.get("index", 0)),
			str(status.get("status", "")),
			int(status.get("seed", 0)),
			str(status.get("mode", "")),
			str(status.get("class_id", "")),
			str(status.get("goal", "")),
		])
		if str(status.get("status", "")) == "missing":
			print("  Launch Dry Run: %s" % str(status.get("launch_dry_run_command", "")))
			print("  Launch: %s" % str(status.get("launch_command", "")))
			print("  Dry Run: %s" % str(status.get("dry_run_command", "")))
			print("  Command: %s" % str(status.get("command", "")))
			print("  Issue Dry Run: %s" % str(status.get("issue_dry_run_command", "")))
			print("  Issue: %s" % str(status.get("issue_command", "")))
			print("  Resolve Dry Run: %s" % str(status.get("resolve_dry_run_command", "")))
			print("  Resolve: %s" % str(status.get("resolve_command", "")))
	if not Array(evidence.get("manual_scenario_results", [])).is_empty():
		print("manual_scenario_results already present: %d" % Array(
			evidence.get("manual_scenario_results", [])).size())
	quit(0)

func _asset_replacement_plan_command(asset_kind: String) -> String:
	return "godot --headless --path . --script res://scripts/tools/print_asset_replacement_plan.gd -- --kind=%s" % asset_kind
