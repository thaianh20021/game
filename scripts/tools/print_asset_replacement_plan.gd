extends SceneTree

const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var kind := _arg("kind")
	if kind == "":
		kind = "object_visual"
	var plan: Dictionary = ReleaseAuditScript.asset_replacement_plan(kind)
	print("Asset Replacement Plan: kind=%s" % str(plan.get("kind", "")))
	print("Source Priority: %s" % str(plan.get("source_order_text", "")))
	_print_array("Allowed Runtime Sources", Array(plan.get("source_priority", [])))
	_print_array("Pattern Reference Only", Array(plan.get("reference_only_sources", [])))
	_print_array("Forbidden Sources", Array(plan.get("forbidden_sources", [])))
	print("Fanmade Policy: %s" % str(plan.get("fanmade_policy", "")))
	_print_array("Release Self-Review Gate", Array(plan.get("release_self_review_gate", [])))
	_print_array("Manifest Required Fields", Array(plan.get("manifest_required_fields", [])))
	_print_array("Review Steps", Array(plan.get("review_steps", [])))
	print("Checklist Command: %s" % str(plan.get("checklist_command", "")))
	print("Manifest Candidate Command: %s" % str(plan.get("manifest_candidate_command", "")))
	print("Frame Grid Rule: %s" % str(plan.get("frame_grid_rule", "")))
	print("AI Frame Prompt Guard: %s" % str(plan.get("ai_frame_prompt_guard", "")))
	print("Polygon Rule: %s" % str(plan.get("polygon_rule", "")))
	_print_array("Missing Polygon Next Actions", Array(plan.get("missing_polygon_next_actions", [])))
	print("Release Rule: %s" % str(plan.get("release_decision_rule", "")))
	print("No release evidence recorded")
	quit(0)

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
