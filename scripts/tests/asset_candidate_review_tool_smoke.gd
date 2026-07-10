extends SceneTree

const TOOL_PATH := "res://scripts/tools/review_asset_candidate.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_review_tool(failures)
	if failures.is_empty():
		print("Asset candidate review tool smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_review_tool(failures: Array[String]) -> void:
	if not ResourceLoader.exists(TOOL_PATH):
		failures.append("release workflow should include an asset candidate review dry-run tool")
		return
	var source := FileAccess.get_file_as_string(TOOL_PATH)
	for token in [
			"OS.get_cmdline_user_args",
			"review_manifest_candidate",
			"asset_release_review_checklist",
			"release_self_review_ok",
			"release_self_review_blockers",
			"Allowed Sources",
			"Source Priority",
			"Reference Only",
			"Fanmade Policy",
			"Pattern References",
			"Manifest Required Fields",
			"Frame Grid Rule",
			"Polygon Rule",
			"Missing Polygon Next Actions",
			"Frame Contract",
			"Frame Cells",
			"Frame Center Drift",
			"Frame Occupancy",
			"Frame Content Bounds",
			"Animation Stability",
			"Motion Reviewed",
			"Origin Alignment",
			"No Clipped Frames",
			"AI Frame Prompt Guard",
			"Object Polygon",
			"fallback_polygon_inside_frame",
			"_fallback_polygon_inside_frame_status",
			"Release Rule",
			"No release evidence recorded",
	]:
		if not source.contains(token):
			failures.append("asset candidate review tool missing token: %s" % token)
	if source.contains("record_release_candidate"):
		failures.append("asset candidate review tool must be dry-run only")
