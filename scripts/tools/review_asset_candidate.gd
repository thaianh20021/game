extends SceneTree

const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var manifest := _arg("manifest")
	var kind := _arg("kind")
	var source := _arg("source")
	if manifest == "" and kind == "":
		_print_usage()
		quit(1)
		return
	if manifest != "":
		var candidate: Dictionary = ReleaseAuditScript.review_manifest_candidate(manifest, source)
		_print_candidate(candidate)
		print("No release evidence recorded")
		quit(0 if _candidate_ready(candidate) else 1)
		return
	_print_checklist(ReleaseAuditScript.asset_release_review_checklist(kind))
	print("No release evidence recorded")
	quit(0)

func _print_usage() -> void:
	print("Usage: godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --manifest=<manifest.json> [--source=<source_id>]")
	print("Usage: godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --kind=<sprite|vfx|audio|collision|object_visual>")

func _print_candidate(candidate: Dictionary) -> void:
	var plan: Dictionary = ReleaseAuditScript.asset_replacement_plan(str(candidate.get("kind", "")))
	print("Asset Candidate: %s kind=%s source=%s decision=%s" % [
		str(candidate.get("id", "")),
		str(candidate.get("kind", "")),
		str(candidate.get("manifest_source_id", candidate.get("source", ""))),
		str(candidate.get("release_decision", "")),
	])
	print("Self Review: %s" % ("OK" if bool(candidate.get("release_self_review_ok", false)) else "BLOCKED"))
	_print_plan(plan)
	_print_candidate_contracts(candidate)
	_print_array("Issues", Array(candidate.get("issues", [])) + Array(candidate.get("manifest_issues", [])))
	_print_array("Blockers", Array(candidate.get("release_self_review_blockers", [])))
	_print_array("Allowed Sources", Array(candidate.get("allowed_replacement_sources", [])))
	_print_array("Reference Only", Array(candidate.get("reference_only_sources", [])))
	print("Fanmade Policy: %s" % str(candidate.get("fanmade_policy", plan.get("fanmade_policy", ""))))
	_print_array("Pattern References", Array(candidate.get("pattern_reference_sources", [])))
	_print_array("Review Gate", Array(candidate.get("release_self_review_gate", [])))

func _print_checklist(checklist: Dictionary) -> void:
	var plan: Dictionary = ReleaseAuditScript.asset_replacement_plan(str(checklist.get("kind", "")))
	print("Asset Review Checklist: kind=%s" % str(checklist.get("kind", "")))
	_print_plan(plan)
	_print_array("Allowed Sources", Array(checklist.get("allowed_runtime_sources", [])))
	_print_array("Reference Only", Array(checklist.get("reference_only_sources", [])))
	_print_array("Forbidden Sources", Array(checklist.get("forbidden_sources", [])))
	print("Fanmade Policy: %s" % str(checklist.get("fanmade_policy", plan.get("fanmade_policy", ""))))
	_print_array("Pattern References", Array(checklist.get("reference_only_sources", [])))
	_print_array("Review Gate", Array(checklist.get("release_self_review_gate", [])))
	_print_array("Review Steps", Array(checklist.get("review_steps", [])))

func _print_plan(plan: Dictionary) -> void:
	print("Source Priority: %s" % str(plan.get("source_order_text", "")))
	_print_array("Manifest Required Fields", Array(plan.get("manifest_required_fields", [])))
	print("Frame Grid Rule: %s" % str(plan.get("frame_grid_rule", "")))
	print("AI Frame Prompt Guard: %s" % str(plan.get("ai_frame_prompt_guard", "")))
	print("Polygon Rule: %s" % str(plan.get("polygon_rule", "")))
	_print_array("Missing Polygon Next Actions", Array(plan.get("missing_polygon_next_actions", [])))
	print("Release Rule: %s" % str(plan.get("release_decision_rule", "")))

func _print_candidate_contracts(candidate: Dictionary) -> void:
	var frame_contract: Dictionary = candidate.get("frame_contract", {})
	if not frame_contract.is_empty():
		print("Frame Contract: size=%s expected=%s fps=%.1f" % [
			str(frame_contract.get("frame_size", Vector2.ZERO)),
			str(frame_contract.get("expected_frame_size", Vector2.ZERO)),
			float(frame_contract.get("fps", 0.0)),
		])
		print("Frame Cells: declared=%d image=%d" % [
			int(frame_contract.get("grid_cell_count", 0)),
			int(frame_contract.get("image_grid_cell_count", 0)),
		])
		print("Frame Center Drift: %.2f px" % float(
			frame_contract.get("frame_center_drift_px", 0.0)))
		print("Frame Occupancy: %s" % str(frame_contract.get("frame_nontransparent_px", [])))
		print("Frame Content Bounds: %s" % str(frame_contract.get("frame_content_bounds_px", [])))
		print("Animation Stability: %s" % _flag_status(
			bool(frame_contract.get("animation_stability_reviewed", false))))
		print("Motion Reviewed: %s" % _flag_status(
			bool(frame_contract.get("motion_reviewed", false))))
		print("Origin Alignment: %s origin=%s" % [
			_flag_status(bool(frame_contract.get("origin_alignment_reviewed", false))),
			str(frame_contract.get("origin_px", Vector2.ZERO)),
		])
		print("No Clipped Frames: %s" % _issue_status(candidate, [
			"manifest_frame_content_clipped",
		]))
	var object_contract: Dictionary = candidate.get("object_visual_contract", {})
	if not object_contract.is_empty():
		print("Object Polygon: points=%d area=%.1f fallback_polygon_inside_frame=%s" % [
			int(object_contract.get("fallback_polygon_points", 0)),
			float(object_contract.get("fallback_polygon_area_px", 0.0)),
			_fallback_polygon_inside_frame_status(candidate),
		])

func _fallback_polygon_inside_frame_status(candidate: Dictionary) -> String:
	var issues := Array(candidate.get("issues", []))
	for issue in ["fallback_polygon_not_reviewed", "fallback_polygon_area_not_reviewed",
			"manifest_fallback_polygon_missing", "manifest_fallback_polygon_area_missing",
			"manifest_fallback_polygon_points_px_missing",
			"manifest_fallback_polygon_outside_frame"]:
		if issues.has(issue):
			return "BLOCKED"
	return "OK"

func _candidate_ready(candidate: Dictionary) -> bool:
	return bool(candidate.get("release_self_review_ok", false)) \
		and str(candidate.get("release_decision", "")) == "public_ok"

func _flag_status(ok: bool) -> String:
	return "OK" if ok else "BLOCKED"

func _issue_status(candidate: Dictionary, blocking_issues: Array) -> String:
	var issues := Array(candidate.get("issues", [])) + Array(candidate.get("manifest_issues", []))
	for issue in blocking_issues:
		if issues.has(str(issue)):
			return "BLOCKED"
	return "OK"

func _print_array(label: String, values: Array) -> void:
	print("%s: %s" % [label, _join(values)])

func _join(values: Array) -> String:
	var parts: Array[String] = []
	for value in values:
		var text := str(value).strip_edges()
		if text != "" and not parts.has(text):
			parts.append(text)
	if parts.is_empty():
		return "none"
	return ", ".join(parts)

func _arg(name: String) -> String:
	var prefix := "--%s=" % name
	for raw_arg in OS.get_cmdline_user_args():
		var text := str(raw_arg).strip_edges()
		if text.begins_with(prefix):
			return text.trim_prefix(prefix).strip_edges()
	return ""
