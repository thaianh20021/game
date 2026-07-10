extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_asset_release_review_checklist(failures)
	if failures.is_empty():
		print("Asset release review checklist smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_asset_release_review_checklist(failures: Array[String]) -> void:
	var release_audit = load(RELEASE_AUDIT_PATH)
	if not release_audit.has_method("asset_release_review_checklist"):
		failures.append("ReleaseAudit should expose asset_release_review_checklist before release")
		return
	var checklist: Dictionary = release_audit.call("asset_release_review_checklist", "object_visual")
	if str(checklist.get("kind", "")) != "object_visual":
		failures.append("asset release checklist should preserve requested asset kind")
	for source_id in [
			"0x72_dungeontileset_ii",
			"project_owned_collision_polygon",
			"procedural_godot_shapes",
			"free_itchio",
			"godot_asset_library",
			"ai_generated",
	]:
		if not Array(checklist.get("allowed_runtime_sources", [])).has(source_id):
			failures.append("asset release checklist should allow %s for missing object visuals" % source_id)
	if Array(checklist.get("allowed_runtime_sources", [])).has("fanmade_direct_copy"):
		failures.append("asset release checklist should never allow fanmade direct copies")
	if not Array(checklist.get("reference_only_sources", [])).has("CalvinWan0101/soul-knight") \
			or not Array(checklist.get("reference_only_sources", [])).has("leoyin1127/Soul-knights"):
		failures.append("asset release checklist should keep fanmade repos as pattern references")
	if str(checklist.get("fanmade_policy", "")) != "study_patterns_only_never_copy_runtime_assets_or_code":
		failures.append("asset release checklist should state fanmade repos are pattern-only")
	var gate: Array = checklist.get("release_self_review_gate", [])
	for required in [
			"source_url_or_generation_manifest",
			"frame_grid_ok",
			"expected_frame_size",
			"animation_stability_reviewed",
			"motion_reviewed",
			"origin_alignment_reviewed",
			"origin_px",
			"image_backed_frame_review",
			"no_empty_animation_frames",
			"no_clipped_animation_frames",
			"frame_center_drift_reviewed",
			"fallback_polygon_points",
			"fallback_polygon_points_px",
			"fallback_polygon_area_px",
			"fallback_polygon_inside_frame",
			"no_direct_fanmade_copy",
	]:
		if not gate.has(required):
			failures.append("asset release checklist gate missing %s" % required)
	var release_checklist: Array = checklist.get("release_review_checklist", [])
	for required in [
			"fallback_polygon_points_px",
			"fallback_polygon_inside_frame",
	]:
		if not release_checklist.has(required):
			failures.append("asset release checklist should require %s" % required)
	var steps: Array = checklist.get("review_steps", [])
	for required in [
			"confirm_license_or_generation_manifest",
			"inspect_frame_grid_count_size_fps",
			"inspect_frame_occupancy_bounds_and_center_drift",
			"inspect_origin_motion_and_loop_stability",
			"verify_collision_polygon_points_and_area",
			"verify_polygon_points_inside_frame",
			"run_smoke_suite_before_release",
	]:
		if not steps.has(required):
			failures.append("asset release checklist review steps missing %s" % required)
	if str(checklist.get("release_decision_rule", "")) != "release_only_after_frame_polygon_motion_review":
		failures.append("asset release checklist should block release until frame/polygon/motion review")

	var collision_checklist: Dictionary = release_audit.call("asset_release_review_checklist", "collision")
	var collision_gate: Array = collision_checklist.get("release_self_review_gate", [])
	for required in [
			"collision_polygon_points",
			"polygon_points_px",
			"polygon_area_px",
	]:
		if not collision_gate.has(required):
			failures.append("collision release checklist gate missing %s" % required)
