extends SceneTree

const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var failures: Array[String] = []
	var expected_types := [
		"polygon_collision",
		"asset_animation",
		"missing_asset_source",
		"combat_readability",
		"balance_pace",
		"ui_overlap",
	]
	var release_audit: Variant = load("res://scripts/assets/release_audit.gd")
	if release_audit == null:
		failures.append("ReleaseAudit should load for issue type suggestions")
	elif not release_audit.has_method("manual_playtest_issue_type_suggestions"):
		failures.append("ReleaseAudit should expose manual playtest issue type suggestions")
	elif not release_audit.has_method("manual_playtest_issue_type_alias_summary"):
		failures.append("ReleaseAudit should expose manual playtest issue type alias summary")
	else:
		var suggestions := Array(release_audit.call("manual_playtest_issue_type_suggestions"))
		for issue_type in expected_types:
			if not suggestions.has(issue_type):
				failures.append("issue type suggestions missing %s" % issue_type)
		var alias_summary := str(release_audit.call("manual_playtest_issue_type_alias_summary"))
		for token in ["poligon -> polygon_collision", "polygon -> polygon_collision",
				"animation -> asset_animation"]:
			if not alias_summary.contains(token):
				failures.append("issue type alias summary missing %s" % token)
	_check_status_tool(failures)
	_check_packet(expected_types, failures)
	_check_overlay(expected_types, failures)
	if failures.is_empty():
		print("Manual playtest issue type suggestions smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_packet(expected_types: Array, failures: Array[String]) -> void:
	var packet := ReleaseAuditScript.release_candidate_playtest_packet()
	var packet_types := Array(packet.get("issue_type_suggestions", []))
	for issue_type in expected_types:
		if not packet_types.has(issue_type):
			failures.append("packet issue type suggestions missing %s" % issue_type)
	var markdown := str(packet.get("markdown", ""))
	if not markdown.contains("Issue types:"):
		failures.append("packet markdown should list issue types")
	for issue_type in expected_types:
		if not markdown.contains(issue_type):
			failures.append("packet markdown missing issue type %s" % issue_type)
	for token in ["Issue aliases:", "poligon -> polygon_collision", "animation -> asset_animation"]:
		if not markdown.contains(token):
			failures.append("packet markdown missing issue alias token %s" % token)
	for raw_draft in Array(packet.get("scenario_drafts", [])):
		if not (raw_draft is Dictionary):
			continue
		var draft: Dictionary = raw_draft
		var draft_types := Array(draft.get("issue_type_suggestions", []))
		for issue_type in expected_types:
			if not draft_types.has(issue_type):
				failures.append("scenario draft issue type suggestions missing %s" % issue_type)

func _check_overlay(expected_types: Array, failures: Array[String]) -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		failures.append("main scene should load for issue type overlay smoke")
		return
	var main := packed.instantiate()
	root.add_child(main)
	var request: Dictionary = main.call(
		"_manual_playtest_launch_request_from_args", ["--manual-scenario=2"])
	var text := str(main.call("_manual_playtest_overlay_text", request))
	if text.contains("Issue types:"):
		failures.append("manual scenario overlay should keep issue types out of visible text")
	main.call("_show_manual_playtest_overlay", request)
	var label := main.find_child("ManualPlaytestScenarioLabel", true, false) as Label
	if label == null:
		failures.append("manual scenario overlay should create a label for issue metadata")
		main.queue_free()
		return
	var issue_summary := str(label.get_meta("manual_issue_type_summary", ""))
	for issue_type in expected_types:
		if not issue_summary.contains(issue_type):
			failures.append("manual scenario overlay metadata missing issue type %s" % issue_type)
	var alias_summary := str(label.get_meta("manual_issue_alias_summary", ""))
	for token in ["Issue aliases:", "poligon -> polygon_collision", "animation -> asset_animation"]:
		var metadata_token: String = token.trim_prefix("Issue aliases:").strip_edges()
		if metadata_token != "" and not alias_summary.contains(metadata_token):
			failures.append("manual scenario overlay metadata missing issue alias token %s" % token)
	main.queue_free()

func _check_status_tool(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/tools/release_candidate_status.gd")
	for token in [
		"Issue Aliases:",
		"manual_playtest_issue_type_alias_summary",
	]:
		if not source.contains(token):
			failures.append("release candidate status missing issue alias token %s" % token)
