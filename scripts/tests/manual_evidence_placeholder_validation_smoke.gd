extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"
const TOOL_PATHS := [
	"res://scripts/tools/record_playtest_notes_evidence.gd",
	"res://scripts/tools/record_manual_scenario_evidence.gd",
	"res://scripts/tools/record_manual_playtest_issue.gd",
	"res://scripts/tools/resolve_manual_playtest_issue.gd",
]

func _init() -> void:
	var failures: Array[String] = []
	var release_audit: Variant = load(RELEASE_AUDIT_PATH)
	if release_audit == null:
		failures.append("ReleaseAudit should load for placeholder validation")
	elif not release_audit.has_method("manual_evidence_value_placeholder"):
		failures.append("ReleaseAudit should expose manual_evidence_value_placeholder")
	else:
		if not bool(release_audit.call(
				"manual_evidence_value_placeholder", "<human notes>")):
			failures.append("angle-bracket human notes should be treated as placeholder")
		if not bool(release_audit.call(
				"manual_evidence_value_placeholder", "<avg sec>")):
			failures.append("angle-bracket metric should be treated as placeholder")
		if not bool(release_audit.call(
				"manual_evidence_value_placeholder", "human retest notes")):
			failures.append("template text without brackets should be treated as placeholder")
		if bool(release_audit.call(
				"manual_evidence_value_placeholder",
				"replayed seed 420101, no animation jitter, collision matched sprite")):
			failures.append("specific human note should not be treated as placeholder")
		if not release_audit.has_method("manual_scenario_notes_review_complete"):
			failures.append("ReleaseAudit should expose manual_scenario_notes_review_complete")
		else:
			if bool(release_audit.call(
					"manual_scenario_notes_review_complete",
					"cleared seed 420101, felt okay")):
				failures.append("manual scenario notes should require animation/polygon/wave/HUD/audio review")
			if not bool(release_audit.call(
					"manual_scenario_notes_review_complete",
					"animation stable; polygon collision matched sprite; wave HUD audio cues clear")):
				failures.append("manual scenario notes with animation/polygon/wave/HUD/audio should pass review")
	if release_audit != null:
		if not release_audit.has_method("manual_evidence_source_valid"):
			failures.append("ReleaseAudit should expose manual_evidence_source_valid")
		else:
			if not bool(release_audit.call("manual_evidence_source_valid", "manual_playtest")):
				failures.append("manual_playtest should be valid manual evidence source")
			if bool(release_audit.call("manual_evidence_source_valid", "")):
				failures.append("missing manual evidence source should be invalid")
			if bool(release_audit.call("manual_evidence_source_valid", "headless_rehearsal")):
				failures.append("headless rehearsal should be invalid manual evidence source")
	for path in TOOL_PATHS:
		_check_tool(path, failures)
	if failures.is_empty():
		print("Manual evidence placeholder validation smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_tool(path: String, failures: Array[String]) -> void:
	if not ResourceLoader.exists(path):
		failures.append("%s should exist" % path)
		return
	var source := FileAccess.get_file_as_string(path)
	for token in [
		"manual_evidence_value_placeholder",
		"Placeholder evidence is not valid",
	]:
		if not source.contains(token):
			failures.append("%s missing placeholder validation token: %s" % [path, token])
	if path.ends_with("record_manual_scenario_evidence.gd") \
			and not source.contains("screenshot_or_seed"):
		failures.append("manual scenario evidence tool should require screenshot_or_seed")
	if path.ends_with("record_manual_scenario_evidence.gd") \
			and not source.contains("Manual scenario evidence requires --evidence_source=manual_playtest"):
		failures.append("manual scenario evidence tool should require manual evidence_source")
	if path.ends_with("record_manual_scenario_evidence.gd") \
			and not source.contains("manual_scenario_notes_review_complete"):
		failures.append("manual scenario evidence tool should require review-complete notes")
	if path.ends_with("record_manual_playtest_issue.gd") \
			and not source.contains("Manual playtest issue requires --evidence_source=manual_playtest"):
		failures.append("manual playtest issue tool should require manual evidence_source")
	if path.ends_with("resolve_manual_playtest_issue.gd") \
			and not source.contains("Manual playtest issue resolution requires --evidence_source=manual_playtest"):
		failures.append("manual playtest issue resolver should require manual evidence_source")
	if path.ends_with("record_manual_scenario_evidence.gd") \
			or path.ends_with("record_manual_playtest_issue.gd") \
			or path.ends_with("resolve_manual_playtest_issue.gd"):
		if not source.contains("manual_evidence_source_valid"):
			failures.append("%s should use shared manual evidence source validation" % path)
