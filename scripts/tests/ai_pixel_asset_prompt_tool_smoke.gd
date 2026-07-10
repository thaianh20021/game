extends SceneTree

const TOOL_PATH := "res://scripts/tools/print_ai_pixel_asset_prompt.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_prompt_api(failures)
	_check_prompt_tool(failures)
	if failures.is_empty():
		print("AI pixel asset prompt tool smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_prompt_api(failures: Array[String]) -> void:
	var release_audit = load("res://scripts/assets/release_audit.gd")
	if not release_audit.has_method("ai_pixel_asset_prompt"):
		failures.append("ReleaseAudit should expose ai_pixel_asset_prompt")
		return
	if not release_audit.has_method("ai_pixel_asset_manifest_template"):
		failures.append("ReleaseAudit should expose ai_pixel_asset_manifest_template")
		return
	var prompt: Dictionary = release_audit.call(
		"ai_pixel_asset_prompt", "object_visual", "trap_spike_ai", Vector2(32, 32), 4)
	if str(prompt.get("kind", "")) != "object_visual":
		failures.append("AI pixel prompt should preserve asset kind")
	if str(prompt.get("asset_id", "")) != "trap_spike_ai":
		failures.append("AI pixel prompt should preserve asset id")
	if prompt.get("frame_size", Vector2.ZERO) != Vector2(32, 32):
		failures.append("AI pixel prompt should preserve requested frame size")
	if int(prompt.get("frame_count", 0)) != 4:
		failures.append("AI pixel prompt should preserve requested frame count")
	for token in [
			"transparent PNG sprite sheet",
			"same frame_size",
			"same frame_count",
			"origin_px",
			"fallback_polygon_points_px",
			"no empty frames",
			"no clipped frames",
			"top-down dungeon pixel art",
	]:
		if not str(prompt.get("prompt_text", "")).contains(token):
			failures.append("AI pixel prompt text missing token: %s" % token)
	for field in ["image_path", "origin_px", "fallback_polygon_points_px",
			"fallback_polygon_area_px", "review_notes"]:
		if not Array(prompt.get("manifest_required_fields", [])).has(field):
			failures.append("AI pixel prompt manifest fields missing %s" % field)
	if not str(prompt.get("review_command", "")).contains("review_asset_candidate.gd"):
		failures.append("AI pixel prompt should include candidate review command")
	var template: Dictionary = release_audit.call(
		"ai_pixel_asset_manifest_template",
		"object_visual", "trap_spike_ai", Vector2(32, 32), 4,
		"res://docs/asset_generation/trap_spike_ai.png")
	if str(template.get("asset_kind", "")) != "object_visual":
		failures.append("AI pixel manifest template should preserve kind")
	if str(template.get("asset_id", "")) != "trap_spike_ai":
		failures.append("AI pixel manifest template should preserve asset id")
	if template.get("frame_size", Vector2.ZERO) != Vector2(32, 32):
		failures.append("AI pixel manifest template should preserve frame_size")
	if int(template.get("frame_count", 0)) != 4:
		failures.append("AI pixel manifest template should preserve frame_count")
	if template.get("origin_px", Vector2.ZERO) != Vector2(16, 16):
		failures.append("AI pixel manifest template should default origin to frame center")
	if Array(template.get("fallback_polygon_points_px", [])).size() < 3:
		failures.append("AI object visual template should include fallback polygon points")
	if float(template.get("fallback_polygon_area_px", 0.0)) <= 0.0:
		failures.append("AI object visual template should include fallback polygon area")
	for key in ["generation_tool", "frame_grid_ok", "animation_stability_reviewed",
			"motion_reviewed", "origin_alignment_reviewed", "review_notes"]:
		if not template.has(key):
			failures.append("AI manifest template missing key: %s" % key)

func _check_prompt_tool(failures: Array[String]) -> void:
	if not ResourceLoader.exists(TOOL_PATH):
		failures.append("AI pixel asset prompt print tool should exist")
		return
	var source := FileAccess.get_file_as_string(TOOL_PATH)
	for token in [
			"ai_pixel_asset_prompt",
			"AI Pixel Asset Prompt",
			"Manifest Template",
			"Manifest Required Fields",
			"Review Command",
			"No release evidence recorded",
	]:
		if not source.contains(token):
			failures.append("AI pixel asset prompt tool missing token: %s" % token)
