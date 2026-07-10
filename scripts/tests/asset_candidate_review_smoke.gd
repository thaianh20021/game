extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	_check_manifest_candidate_review_api(failures)
	if failures.is_empty():
		print("Asset candidate review smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_manifest_candidate_review_api(failures: Array[String]) -> void:
	var release_audit = load("res://scripts/assets/release_audit.gd")
	if not release_audit.has_method("review_manifest_candidate"):
		failures.append("ReleaseAudit should expose review_manifest_candidate for AI/free asset release gates")
		return

	var stable_sprite: Dictionary = release_audit.call("review_manifest_candidate",
		"res://docs/asset_generation/valid_ai_sprite_manifest.json")
	if str(stable_sprite.get("id", "")) != "blade_idle_ai":
		failures.append("manifest candidate review should infer asset_id")
	if str(stable_sprite.get("kind", "")) != "sprite":
		failures.append("manifest candidate review should infer asset_kind")
	if str(stable_sprite.get("release_decision", "")) != "public_ok":
		failures.append("valid AI sprite manifest should pass release review")
	if not bool(stable_sprite.get("manifest_reviewed", false)):
		failures.append("valid AI sprite manifest should mark manifest_reviewed")
	if str(stable_sprite.get("manifest_image_loader", "")) != "resource_texture":
		failures.append("res:// manifest image review should use export-safe resource texture loading")
	if not bool(stable_sprite.get("release_self_review_ok", false)):
		failures.append("valid AI sprite manifest should pass self-review gate")
	var frame_contract: Dictionary = stable_sprite.get("frame_contract", {})
	if int(frame_contract.get("grid_cell_count", 0)) != 4:
		failures.append("manifest candidate review should expose frame grid cell count")
	if Array(frame_contract.get("frame_nontransparent_px", [])).size() != 4:
		failures.append("manifest candidate review should expose per-frame occupancy")
	if Array(frame_contract.get("frame_content_bounds_px", [])).size() != 4:
		failures.append("manifest candidate review should expose per-frame content bounds")
	if not frame_contract.has("frame_center_drift_px"):
		failures.append("manifest candidate review should expose measured frame center drift")
	if not Array(Dictionary(stable_sprite.get("source_plan", {})).get(
			"manifest_required_fields", [])).has("image_path"):
		failures.append("visual AI manifest review should require image_path for pixel grid review")

	var stable_object: Dictionary = release_audit.call("review_manifest_candidate",
		"res://docs/asset_generation/valid_ai_object_visual_manifest.json")
	var object_contract: Dictionary = stable_object.get("object_visual_contract", {})
	if str(stable_object.get("release_decision", "")) != "public_ok":
		failures.append("valid AI object visual manifest should pass release review")
	if not bool(object_contract.get("polygon_ok", false)) \
			or int(object_contract.get("fallback_polygon_points", 0)) < 3 \
			or float(object_contract.get("fallback_polygon_area_px", 0.0)) <= 0.0:
		failures.append("object visual manifest review should preserve fallback polygon contract")
	var object_strategy: Dictionary = stable_object.get("source_plan", {})
	for source_id in ["0x72_dungeontileset_ii", "free_itchio", "godot_asset_library", "ai_generated"]:
		if not Array(object_strategy.get("source_priority", [])).has(source_id):
			failures.append("object visual source plan should allow %s replacements" % source_id)
	if Array(stable_object.get("forbidden_sources", [])).has("fanmade_direct_copy") == false:
		failures.append("manifest candidate review should forbid direct fanmade copies")

	var itch_image_path := "user://free_itch_candidate_64x16.png"
	var itch_image := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	itch_image.fill(Color.TRANSPARENT)
	for frame_index in 4:
		for x in range(3, 13):
			for y in range(3, 13):
				itch_image.set_pixel(frame_index * 16 + x, y, Color(0.9, 0.8, 0.25, 1.0))
	if itch_image.save_png(itch_image_path) != OK:
		failures.append("free itch.io candidate image should save")
	else:
		var itch_manifest_path := "user://free_itch_candidate_manifest.json"
		var itch_file := FileAccess.open(itch_manifest_path, FileAccess.WRITE)
		if itch_file == null:
			failures.append("free itch.io candidate manifest should open")
		else:
			itch_file.store_string(JSON.stringify({
				"asset_id": "licensed_itch_slash",
				"asset_kind": "sprite",
				"license": "CC0",
				"source_url": "https://example.itch.io/free-pack",
				"image_path": itch_image_path,
				"review_notes": "Licensed itch.io sheet; 4x1 stable 16x16 frames reviewed.",
				"frame_grid_ok": true,
				"frame_count": 4,
				"frame_size": [16, 16],
				"expected_frame_size": [16, 16],
				"stable_size": true,
				"fps": 8.0,
				"animation_stability_reviewed": true,
				"motion_reviewed": true,
				"origin_alignment_reviewed": true,
				"origin_px": [8, 8],
				"sheet_size": [64, 16],
				"columns": 4,
				"rows": 1,
			}, "\t"))
			itch_file.close()
			var itch_candidate: Dictionary = release_audit.call(
				"review_manifest_candidate", itch_manifest_path)
			if str(itch_candidate.get("manifest_source_id", "")) != "free_itchio":
				failures.append("itch.io manifest candidate should infer free_itchio source")
			if str(itch_candidate.get("release_decision", "")) != "public_ok":
				failures.append("licensed itch.io candidate should pass without AI generation_tool")
			if not bool(itch_candidate.get("manifest_report_ready", false)):
				failures.append("licensed itch.io manifest should pass source-backed manifest review")
			if str(itch_candidate.get("manifest_image_loader", "")) != "raw_image_file":
				failures.append("user:// manifest image review should keep raw image file loading")
			if Array(itch_candidate.get("issues", [])).has("manifest_generation_tool_missing"):
				failures.append("licensed itch.io manifest should not require AI generation_tool")

	var fanmade_image_path := "user://fanmade_runtime_candidate_64x16.png"
	var fanmade_image := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	fanmade_image.fill(Color.TRANSPARENT)
	for frame_index in 4:
		for x in range(3, 13):
			for y in range(3, 13):
				fanmade_image.set_pixel(frame_index * 16 + x, y, Color(0.4, 0.9, 1.0, 1.0))
	if fanmade_image.save_png(fanmade_image_path) != OK:
		failures.append("fanmade runtime candidate image should save")
	else:
		var fanmade_manifest_path := "user://fanmade_runtime_candidate_manifest.json"
		var fanmade_file := FileAccess.open(fanmade_manifest_path, FileAccess.WRITE)
		if fanmade_file == null:
			failures.append("fanmade runtime candidate manifest should open")
		else:
			fanmade_file.store_string(JSON.stringify({
				"asset_id": "copied_fanmade_knight",
				"asset_kind": "sprite",
				"license": "CC0",
				"source_url": "https://github.com/CalvinWan0101/soul-knight/tree/main/assets",
				"image_path": fanmade_image_path,
				"review_notes": "Intentionally points at fanmade runtime art; frame grid is valid but source must block release.",
				"frame_grid_ok": true,
				"frame_count": 4,
				"frame_size": [16, 16],
				"expected_frame_size": [16, 16],
				"stable_size": true,
				"fps": 8.0,
				"animation_stability_reviewed": true,
				"motion_reviewed": true,
				"origin_alignment_reviewed": true,
				"origin_px": [8, 8],
				"sheet_size": [64, 16],
				"columns": 4,
				"rows": 1,
			}, "\t"))
			fanmade_file.close()
			var fanmade_candidate: Dictionary = release_audit.call(
				"review_manifest_candidate", fanmade_manifest_path)
			if str(fanmade_candidate.get("release_decision", "")) != "blocked":
				failures.append("fanmade runtime source_url should block public release")
			if not Array(fanmade_candidate.get("issues", [])).has(
					"fanmade_runtime_source_forbidden"):
				failures.append("fanmade runtime source_url should explain direct copy is forbidden")
			if bool(fanmade_candidate.get("release_self_review_ok", true)):
				failures.append("fanmade runtime source_url should fail release self-review")

	var broken_object: Dictionary = release_audit.call("review_manifest_candidate",
		"res://docs/asset_generation/invalid_ai_object_visual_manifest.json")
	if str(broken_object.get("release_decision", "")) != "blocked":
		failures.append("broken object visual manifest should be blocked before release")
	if bool(broken_object.get("release_self_review_ok", true)):
		failures.append("broken object visual manifest should fail self-review gate")
	var blockers: Array = broken_object.get("release_self_review_blockers", [])
	if blockers.is_empty():
		failures.append("broken object visual manifest should expose release blockers")
	if not blockers.has("runtime_object_sprite_not_reviewed") \
			or not blockers.has("fallback_polygon_not_reviewed"):
		failures.append("broken object visual manifest should explain sprite/polygon blockers")

	var metadata_only_path := "user://ai_visual_metadata_only.json"
	var file := FileAccess.open(metadata_only_path, FileAccess.WRITE)
	if file == null:
		failures.append("metadata-only visual manifest fixture should open")
	else:
		file.store_string(JSON.stringify({
			"asset_id": "metadata_only_visual_ai",
			"asset_kind": "sprite",
			"license": "project_owned_ai_generated",
			"generation_tool": "gpt-image",
			"review_notes": "Claims a valid 4x1 grid but intentionally omits image_path.",
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": [16, 16],
			"expected_frame_size": [16, 16],
			"stable_size": true,
			"fps": 8.0,
			"animation_stability_reviewed": true,
			"motion_reviewed": true,
			"origin_alignment_reviewed": true,
			"origin_px": [8, 8],
			"sheet_size": [64, 16],
			"columns": 4,
			"rows": 1,
		}, "\t"))
		file.close()
		var metadata_only: Dictionary = release_audit.call(
			"review_manifest_candidate", metadata_only_path)
		if str(metadata_only.get("release_decision", "")) != "blocked":
			failures.append("visual AI manifest should block when image_path is missing")
		var metadata_only_issues: Array = metadata_only.get("issues", [])
		if not metadata_only_issues.has("manifest_image_path_missing"):
			failures.append("visual AI manifest should explain missing image-backed review")
		if bool(metadata_only.get("release_self_review_ok", true)):
			failures.append("visual AI manifest without image should fail release self-review")
