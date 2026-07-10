extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"
const RECORD_TOOL_PATH := "res://scripts/tools/record_manual_playtest_issue.gd"
const RESOLVE_TOOL_PATH := "res://scripts/tools/resolve_manual_playtest_issue.gd"

func _init() -> void:
	var failures: Array[String] = []
	var release_audit: Variant = load(RELEASE_AUDIT_PATH)
	if release_audit == null:
		failures.append("ReleaseAudit should load for issue type validation")
	elif not release_audit.has_method("manual_playtest_issue_type_valid"):
		failures.append("ReleaseAudit should expose manual_playtest_issue_type_valid")
	elif not release_audit.has_method("manual_playtest_issue_type_normalized"):
		failures.append("ReleaseAudit should expose manual_playtest_issue_type_normalized")
	else:
		if not bool(release_audit.call(
				"manual_playtest_issue_type_valid", "polygon_collision")):
			failures.append("known manual issue type should validate")
		if not bool(release_audit.call(
				"manual_playtest_issue_type_valid", "poligon_collision")):
			failures.append("common polygon typo should validate as an alias")
		if str(release_audit.call(
				"manual_playtest_issue_type_normalized",
				"poligon_collision")) != "polygon_collision":
			failures.append("poligon_collision should normalize to polygon_collision")
		if str(release_audit.call(
				"manual_playtest_issue_type_normalized", "polygon")) != "polygon_collision":
			failures.append("polygon should normalize to polygon_collision")
		if str(release_audit.call(
				"manual_playtest_issue_type_normalized", "animation")) != "asset_animation":
			failures.append("animation should normalize to asset_animation")
		if bool(release_audit.call(
				"manual_playtest_issue_type_valid", "random_manual_issue")):
			failures.append("unknown manual issue type should be rejected")
	_check_tool(RECORD_TOOL_PATH, failures)
	_check_tool(RESOLVE_TOOL_PATH, failures)
	if failures.is_empty():
		print("Manual playtest issue type validation smoke OK")
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
		"manual_playtest_issue_type_valid",
		"manual_playtest_issue_type_normalized",
		"manual_playtest_issue_type_summary",
		"Invalid manual playtest issue_type",
	]:
		if not source.contains(token):
			failures.append("%s missing validation token: %s" % [path, token])
