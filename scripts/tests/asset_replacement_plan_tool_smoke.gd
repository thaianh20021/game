extends SceneTree

const TOOL_PATH := "res://scripts/tools/print_asset_replacement_plan.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_asset_replacement_plan_api(failures)
	_check_asset_replacement_plan_tool(failures)
	if failures.is_empty():
		print("Asset replacement plan tool smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_asset_replacement_plan_api(failures: Array[String]) -> void:
	var release_audit = load("res://scripts/assets/release_audit.gd")
	if not release_audit.has_method("asset_replacement_plan"):
		failures.append("ReleaseAudit should expose asset_replacement_plan for missing polygon/animation fixes")
		return
	if not release_audit.has_method("asset_review_commands"):
		failures.append("ReleaseAudit should expose asset_review_commands for release tooling")
		return

	var collision_plan: Dictionary = release_audit.call("asset_replacement_plan", "collision")
	if str(collision_plan.get("kind", "")) != "collision":
		failures.append("collision replacement plan should preserve kind")
	for source_id in ["project_owned_collision_polygon", "free_itchio", "godot_asset_library", "ai_generated"]:
		if not Array(collision_plan.get("source_priority", [])).has(source_id):
			failures.append("collision replacement plan should allow %s" % source_id)
	if Array(collision_plan.get("forbidden_sources", [])).has("fanmade_direct_copy") == false:
		failures.append("replacement plan should forbid direct fanmade copies")
	if not Array(collision_plan.get("reference_only_sources", [])).has("CalvinWan0101/soul-knight") \
			or not Array(collision_plan.get("reference_only_sources", [])).has("leoyin1127/Soul-knights"):
		failures.append("replacement plan should keep fanmade repos as pattern-only references")
	for gate in ["polygon_points_px", "polygon_area_px", "no_direct_fanmade_copy"]:
		if not Array(collision_plan.get("release_self_review_gate", [])).has(gate):
			failures.append("collision replacement plan gate missing %s" % gate)
	if not str(collision_plan.get("checklist_command", "")).contains("--kind=collision"):
		failures.append("collision replacement plan should include collision checklist command")
	if not str(collision_plan.get("manifest_candidate_command", "")).contains("--manifest=<manifest.json>"):
		failures.append("replacement plan should include manifest candidate review command")
	if not str(collision_plan.get("source_order_text", "")).contains("free itch.io"):
		failures.append("replacement plan should expose human-readable source order")
	var collision_next_actions: Array = collision_plan.get("missing_polygon_next_actions", [])
	for action in ["author_project_owned_polygon", "attach_polygon_points_px",
			"review_manifest_candidate_before_release"]:
		if not collision_next_actions.has(action):
			failures.append("collision missing polygon next actions should include %s" % action)

	var object_plan: Dictionary = release_audit.call("asset_replacement_plan", "object_visual")
	for gate in ["fallback_polygon_points_px", "fallback_polygon_inside_frame",
			"image_backed_frame_review", "frame_center_drift_reviewed"]:
		if not Array(object_plan.get("release_self_review_gate", [])).has(gate):
			failures.append("object visual replacement plan gate missing %s" % gate)
	for field in ["image_path", "origin_px", "fallback_polygon_points_px"]:
		if not Array(object_plan.get("manifest_required_fields", [])).has(field):
			failures.append("object visual replacement manifest fields missing %s" % field)
	var object_next_actions: Array = object_plan.get("missing_polygon_next_actions", [])
	for action in ["keep_fallback_polygon_inside_frame", "review_frame_occupancy",
			"release_only_after_manual_self_review"]:
		if not object_next_actions.has(action):
			failures.append("object visual missing polygon next actions should include %s" % action)

	var sprite_plan: Dictionary = release_audit.call("asset_replacement_plan", "sprite")
	for gate in ["frame_grid_ok", "image_backed_frame_review",
			"no_empty_animation_frames", "no_clipped_animation_frames"]:
		if not Array(sprite_plan.get("release_self_review_gate", [])).has(gate):
			failures.append("sprite replacement plan gate missing %s" % gate)
	if not str(sprite_plan.get("frame_grid_rule", "")).contains("frame_size"):
		failures.append("sprite replacement plan should describe stable frame grid rule")
	var ai_frame_prompt_guard := str(sprite_plan.get("ai_frame_prompt_guard", ""))
	for token in ["same frame_size", "same frame_count", "same fps", "origin_px",
			"no empty frames", "no clipped frames"]:
		if not ai_frame_prompt_guard.contains(token):
			failures.append("sprite replacement plan AI frame guard missing %s" % token)

	var commands: Dictionary = release_audit.call("asset_review_commands")
	for key in ["sprite_checklist", "collision_checklist", "object_visual_checklist",
			"manifest_candidate_template", "replacement_plan"]:
		if not commands.has(key):
			failures.append("asset review commands missing %s" % key)

func _check_asset_replacement_plan_tool(failures: Array[String]) -> void:
	if not FileAccess.file_exists(TOOL_PATH):
		failures.append("print_asset_replacement_plan tool should exist")
		return
	var source := FileAccess.get_file_as_string(TOOL_PATH)
	for token in [
			"asset_replacement_plan",
			"Source Priority",
			"Pattern Reference Only",
			"Manifest Required Fields",
			"Missing Polygon Next Actions",
			"Release Rule",
			"AI Frame Prompt Guard",
	]:
		if not source.contains(token):
			failures.append("print_asset_replacement_plan tool should print %s" % token)
