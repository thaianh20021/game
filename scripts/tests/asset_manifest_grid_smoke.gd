extends SceneTree

const AssetSourceRegistryScript := preload("res://scripts/assets/asset_source_registry.gd")

func _init() -> void:
	var failures: Array[String] = []
	_check_image_grid_capacity(failures)
	_check_image_grid_extra_cells(failures)
	_check_expected_frame_size_required(failures)
	_check_origin_px_required(failures)
	_check_empty_animation_frame_blocked(failures)
	_check_frame_content_edge_contact_blocked(failures)
	_check_frame_center_jitter_blocked(failures)
	_check_allowed_frame_center_drift_requires_review(failures)
	_check_license_placeholder_blocked(failures)
	_check_ai_fanmade_reference_url_blocked(failures)
	_check_ai_fanmade_pattern_reference_allowed(failures)
	_check_polygon_points_px_derives_area(failures)
	_check_polygon_points_px_blocks_flat_polygon(failures)
	_check_object_visual_polygon_points_px_required(failures)
	_check_object_visual_polygon_points_stay_inside_frame(failures)
	if failures.is_empty():
		print("Asset manifest grid smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_image_grid_capacity(failures: Array[String]) -> void:
	var image_path := "user://ai_grid_capacity_32.png"
	var manifest_path := "user://ai_grid_capacity_bad.json"
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	if image.save_png(image_path) != OK:
		failures.append("fixture image should save")
		return
	var manifest := {
		"asset_id": "bad_ai_grid_capacity",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": 5,
		"frame_size": [16, 16],
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("fixture manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var issues: Array = report.get("issues", [])
	if bool(report.get("ready", true)):
		failures.append("manifest should block frame_count that exceeds image grid capacity")
	if not issues.has("manifest_image_frame_count_exceeds_grid"):
		failures.append("manifest should explain frame_count exceeds image grid capacity")
	var metadata: Dictionary = report.get("metadata", {})
	if int(metadata.get("image_grid_cell_count", 0)) != 4:
		failures.append("manifest metadata should expose inferred image grid cell count")

func _check_image_grid_extra_cells(failures: Array[String]) -> void:
	var image_path := "user://ai_grid_extra_cells_64x32.png"
	var manifest_path := "user://ai_grid_extra_cells_bad.json"
	var image := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	if image.save_png(image_path) != OK:
		failures.append("extra-cell fixture image should save")
		return
	var manifest := {
		"asset_id": "bad_ai_grid_extra_cells",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": [16, 16],
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("extra-cell fixture manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var issues: Array = report.get("issues", [])
	if bool(report.get("ready", true)):
		failures.append("manifest should block image grids with extra cells outside frame_count")
	if not issues.has("manifest_image_frame_count_mismatch"):
		failures.append("manifest should explain image grid cell count must match frame_count")
	var metadata: Dictionary = report.get("metadata", {})
	if int(metadata.get("image_grid_cell_count", 0)) != 8:
		failures.append("manifest metadata should expose extra image grid cells")

func _check_expected_frame_size_required(failures: Array[String]) -> void:
	var image_path := "user://ai_grid_expected_size_64x16.png"
	var manifest_path := "user://ai_grid_expected_size_bad.json"
	var image := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	if image.save_png(image_path) != OK:
		failures.append("expected-size fixture image should save")
		return
	var manifest := {
		"asset_id": "bad_ai_grid_expected_size",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": [16, 16],
		"sheet_size": [64, 16],
		"columns": 4,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("expected-size fixture manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var issues: Array = report.get("issues", [])
	if bool(report.get("ready", true)):
		failures.append("manifest should block generated animation sheets without expected_frame_size")
	if not issues.has("manifest_expected_frame_size_missing"):
		failures.append("manifest should explain missing expected_frame_size")

func _check_origin_px_required(failures: Array[String]) -> void:
	var manifest_path := "user://ai_grid_origin_px_bad.json"
	var manifest := {
		"asset_id": "bad_ai_grid_origin_px",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": [16, 16],
		"expected_frame_size": [16, 16],
		"sheet_size": [64, 16],
		"columns": 4,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"review_notes": "Origin was reviewed visually but numeric origin_px is missing.",
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("origin fixture manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var issues: Array = report.get("issues", [])
	if bool(report.get("ready", true)):
		failures.append("manifest should block generated animation sheets without numeric origin_px")
	if not issues.has("manifest_origin_px_missing"):
		failures.append("manifest should explain missing numeric origin_px")

func _check_empty_animation_frame_blocked(failures: Array[String]) -> void:
	var image_path := "user://ai_grid_empty_frame_32x16.png"
	var manifest_path := "user://ai_grid_empty_frame_bad.json"
	var image := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x in range(16):
		for y in range(16):
			image.set_pixel(x, y, Color.WHITE)
	if image.save_png(image_path) != OK:
		failures.append("empty-frame fixture image should save")
		return
	var manifest := {
		"asset_id": "bad_ai_empty_frame",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": 2,
		"frame_size": [16, 16],
		"expected_frame_size": [16, 16],
		"sheet_size": [32, 16],
		"columns": 2,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": [8, 8],
		"review_notes": "Second frame is accidentally blank and should be blocked.",
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("empty-frame fixture manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var issues: Array = report.get("issues", [])
	if bool(report.get("ready", true)):
		failures.append("manifest should block animation sheets with an empty frame")
	if not issues.has("manifest_frame_empty"):
		failures.append("manifest should explain empty animation frame")
	var metadata: Dictionary = report.get("metadata", {})
	var counts: Array = metadata.get("frame_nontransparent_px", [])
	if counts.size() != 2 or int(counts[0]) <= 0 or int(counts[1]) != 0:
		failures.append("manifest should expose per-frame non-transparent pixel counts")

func _check_frame_content_edge_contact_blocked(failures: Array[String]) -> void:
	var image_path := "user://ai_grid_cropped_frame_32x16.png"
	var manifest_path := "user://ai_grid_cropped_frame_bad.json"
	var image := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x in range(0, 16):
		for y in range(4, 12):
			image.set_pixel(x, y, Color.WHITE)
	for x in range(20, 28):
		for y in range(4, 12):
			image.set_pixel(x, y, Color.WHITE)
	if image.save_png(image_path) != OK:
		failures.append("cropped-frame fixture image should save")
		return
	var manifest := {
		"asset_id": "bad_ai_cropped_frame",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": 2,
		"frame_size": [16, 16],
		"expected_frame_size": [16, 16],
		"sheet_size": [32, 16],
		"columns": 2,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": [8, 8],
		"review_notes": "First frame touches both horizontal edges and should be treated as cropped.",
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("cropped-frame fixture manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var issues: Array = report.get("issues", [])
	if bool(report.get("ready", true)):
		failures.append("manifest should block animation frames whose visible content touches frame edges")
	if not issues.has("manifest_frame_content_clipped"):
		failures.append("manifest should explain clipped frame content")
	var metadata: Dictionary = report.get("metadata", {})
	var bounds: Array = metadata.get("frame_content_bounds_px", [])
	if bounds.size() != 2:
		failures.append("manifest should expose per-frame content bounds")

func _check_frame_center_jitter_blocked(failures: Array[String]) -> void:
	var image_path := "user://ai_grid_jitter_frame_32x16.png"
	var manifest_path := "user://ai_grid_jitter_frame_bad.json"
	var image := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x in range(4, 8):
		for y in range(4, 12):
			image.set_pixel(x, y, Color.WHITE)
	for x in range(26, 30):
		for y in range(4, 12):
			image.set_pixel(x, y, Color.WHITE)
	if image.save_png(image_path) != OK:
		failures.append("jitter-frame fixture image should save")
		return
	var manifest := {
		"asset_id": "bad_ai_jitter_frame",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": 2,
		"frame_size": [16, 16],
		"expected_frame_size": [16, 16],
		"sheet_size": [32, 16],
		"columns": 2,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": [8, 8],
		"review_notes": "Both frames are valid cells, but content center jumps too far.",
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("jitter fixture manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var issues: Array = report.get("issues", [])
	if bool(report.get("ready", true)):
		failures.append("manifest should block animation frames whose content center jitters between frames")
	if not issues.has("manifest_frame_origin_jitter"):
		failures.append("manifest should explain unstable frame center/origin jitter")
	var metadata: Dictionary = report.get("metadata", {})
	if float(metadata.get("frame_center_drift_px", 0.0)) <= 0.0:
		failures.append("manifest should expose measured frame center drift")

func _check_allowed_frame_center_drift_requires_review(failures: Array[String]) -> void:
	var image_path := "user://ai_grid_allowed_drift_32x16.png"
	var image := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x in range(4, 8):
		for y in range(4, 12):
			image.set_pixel(x, y, Color.WHITE)
	for x in range(26, 30):
		for y in range(4, 12):
			image.set_pixel(x, y, Color.WHITE)
	if image.save_png(image_path) != OK:
		failures.append("allowed-drift fixture image should save")
		return
	var base_manifest := {
		"asset_id": "allowed_ai_drift_frame",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": 2,
		"frame_size": [16, 16],
		"expected_frame_size": [16, 16],
		"sheet_size": [32, 16],
		"columns": 2,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": [8, 8],
		"allow_frame_center_drift": true,
		"review_notes": "Dash smear intentionally moves across the cell.",
	}
	var unreviewed_manifest_path := "user://ai_grid_allowed_drift_unreviewed.json"
	var file := FileAccess.open(unreviewed_manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("allowed-drift unreviewed manifest should open for write")
		return
	file.store_string(JSON.stringify(base_manifest))
	file.close()
	var unreviewed_report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(
		unreviewed_manifest_path)
	var unreviewed_issues: Array = unreviewed_report.get("issues", [])
	if bool(unreviewed_report.get("ready", true)):
		failures.append("allowed frame drift should require explicit drift review before release")
	if not unreviewed_issues.has("manifest_frame_center_drift_review_missing"):
		failures.append("allowed frame drift should explain missing drift review")

	var reviewed_manifest := base_manifest.duplicate(true)
	reviewed_manifest["frame_center_drift_reviewed"] = true
	reviewed_manifest["frame_center_drift_reason"] = "Intentional dash trail smear; origin remains at [8, 8]."
	var reviewed_manifest_path := "user://ai_grid_allowed_drift_reviewed.json"
	file = FileAccess.open(reviewed_manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("allowed-drift reviewed manifest should open for write")
		return
	file.store_string(JSON.stringify(reviewed_manifest))
	file.close()
	var reviewed_report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(
		reviewed_manifest_path)
	if not bool(reviewed_report.get("ready", false)):
		failures.append("reviewed intentional frame drift should pass manifest review")

func _check_license_placeholder_blocked(failures: Array[String]) -> void:
	var manifest_path := "user://ai_grid_license_placeholder_bad.json"
	var manifest := {
		"asset_id": "bad_ai_license_placeholder",
		"asset_kind": "sprite",
		"license": "license_required",
		"generation_tool": "gpt-image",
		"frame_grid_ok": true,
		"frame_count": 1,
		"frame_size": [16, 16],
		"expected_frame_size": [16, 16],
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": [8, 8],
		"review_notes": "License placeholder should be replaced with a concrete license before release.",
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("license placeholder fixture manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var issues: Array = report.get("issues", [])
	if bool(report.get("ready", true)):
		failures.append("manifest should block placeholder license metadata")
	if not issues.has("manifest_license_placeholder"):
		failures.append("manifest should explain placeholder license metadata")

func _check_ai_fanmade_reference_url_blocked(failures: Array[String]) -> void:
	var manifest_path := "user://ai_grid_fanmade_reference_bad.json"
	var manifest := {
		"asset_id": "bad_ai_fanmade_reference",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"reference_source_url": "https://github.com/CalvinWan0101/soul-knight/tree/master/assets",
		"frame_grid_ok": true,
		"frame_count": 1,
		"frame_size": [16, 16],
		"expected_frame_size": [16, 16],
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": [8, 8],
		"review_notes": "AI output must not be released when it uses fanmade repo art as runtime reference/source.",
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("fanmade-reference manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var policy: Dictionary = AssetSourceRegistryScript.policy_for("ai_generated", "sprite", [], {
		"generation_manifest": manifest_path,
	})
	var issues: Array = policy.get("issues", [])
	if str(policy.get("release_decision", "")) != "blocked":
		failures.append("AI manifest should block fanmade repo runtime references")
	if not issues.has("fanmade_runtime_source_forbidden"):
		failures.append("AI manifest should explain fanmade runtime reference/source is forbidden")
	if bool(policy.get("public_ready", true)):
		failures.append("AI manifest with fanmade runtime reference should not be public-ready")

func _check_ai_fanmade_pattern_reference_allowed(failures: Array[String]) -> void:
	var image_path := "user://ai_grid_fanmade_pattern_reference_ok.png"
	var manifest_path := "user://ai_grid_fanmade_pattern_reference_ok.json"
	var image := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for frame_index in 4:
		for x in range(3, 13):
			for y in range(3, 13):
				image.set_pixel(frame_index * 16 + x, y, Color(0.35, 0.55, 0.9, 1.0))
	if image.save_png(image_path) != OK:
		failures.append("pattern-reference image fixture should save")
		return
	var pattern_sources := [
		"https://github.com/CalvinWan0101/soul-knight#animation-pattern-only",
		"https://github.com/leoyin1127/Soul-knights#dash-recoil-pattern-only",
	]
	var manifest := {
		"asset_id": "clean_ai_dash_trail",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"pattern_reference_sources": pattern_sources,
		"pattern_reference_notes": "Studied recoil/slash timing only; no source sprite, frame, audio, or code copied.",
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": [16, 16],
		"expected_frame_size": [16, 16],
		"sheet_size": [64, 16],
		"columns": 4,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": [8, 8],
		"review_notes": "Frame grid, origin, motion timing, and release provenance reviewed for public use.",
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("pattern-reference manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var policy: Dictionary = AssetSourceRegistryScript.policy_for("ai_generated", "sprite", [], {
		"generation_manifest": manifest_path,
	})
	var issues: Array = policy.get("issues", [])
	if str(policy.get("release_decision", "")) != "public_ok":
		failures.append("AI manifest should allow fanmade repos when marked as pattern-only references")
	if issues.has("fanmade_runtime_source_forbidden"):
		failures.append("pattern-only fanmade references should not be treated as runtime asset sources")
	if not bool(policy.get("public_ready", false)):
		failures.append("AI manifest with clean pattern-only references should be public-ready")
	if Array(policy.get("pattern_reference_sources", [])) != pattern_sources:
		failures.append("AI manifest should expose pattern reference sources for release review")
	if str(policy.get("pattern_reference_policy", "")) != "pattern_reference_only_no_runtime_copy":
		failures.append("AI manifest should label pattern references as no-runtime-copy")

func _check_polygon_points_px_derives_area(failures: Array[String]) -> void:
	var manifest_path := "user://ai_collision_points_px_ok.json"
	var manifest := {
		"asset_id": "trap_room_polygon_ai",
		"asset_kind": "collision",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"shape_ok": true,
		"polygon_ok": true,
		"polygon_points_px": [[0, 0], [16, 0], [16, 16], [0, 16]],
		"review_notes": "Four reviewed points define a square fallback collision polygon.",
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("polygon fixture manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	if not bool(report.get("ready", false)):
		failures.append("manifest should accept reviewed polygon_points_px without duplicate count/area metadata")
	var metadata: Dictionary = report.get("metadata", {})
	if int(metadata.get("polygon_points", 0)) != 4:
		failures.append("manifest should derive polygon point count from polygon_points_px")
	if float(metadata.get("polygon_area_px", 0.0)) <= 0.0:
		failures.append("manifest should derive non-zero polygon area from polygon_points_px")

func _check_polygon_points_px_blocks_flat_polygon(failures: Array[String]) -> void:
	var manifest_path := "user://ai_collision_points_px_flat.json"
	var manifest := {
		"asset_id": "flat_trap_polygon_ai",
		"asset_kind": "collision",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"shape_ok": true,
		"polygon_ok": true,
		"polygon_points_px": [[0, 0], [8, 0], [16, 0]],
		"review_notes": "Three collinear points must not pass release collision review.",
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("flat polygon fixture manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var issues: Array = report.get("issues", [])
	if bool(report.get("ready", true)):
		failures.append("manifest should block flat polygon_points_px")
	if not issues.has("manifest_collision_polygon_area_missing"):
		failures.append("manifest should explain flat polygon area is invalid")

func _check_object_visual_polygon_points_px_required(failures: Array[String]) -> void:
	var image_path := "user://ai_object_visual_polygon_points_missing.png"
	var manifest_path := "user://ai_object_visual_polygon_points_missing.json"
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x in range(8, 24):
		for y in range(8, 24):
			image.set_pixel(x, y, Color(0.4, 0.85, 0.45, 1.0))
	if image.save_png(image_path) != OK:
		failures.append("object visual polygon points fixture image should save")
		return
	var manifest := {
		"asset_id": "bad_object_visual_polygon_points_missing",
		"asset_kind": "object_visual",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"runtime_object_sprite_ok": true,
		"frame_grid_ok": true,
		"frame_count": 1,
		"frame_size": [32, 32],
		"expected_frame_size": [32, 32],
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": [16, 16],
		"polygon_ok": true,
		"fallback_polygon_points": 4,
		"fallback_polygon_area_px": 128.0,
		"review_notes": "Count and area alone are not enough to review polygon placement.",
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("object visual polygon points manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var issues: Array = report.get("issues", [])
	if bool(report.get("ready", true)):
		failures.append("manifest should block object visuals without fallback_polygon_points_px")
	if not issues.has("manifest_fallback_polygon_points_px_missing"):
		failures.append("manifest should explain missing fallback_polygon_points_px")

func _check_object_visual_polygon_points_stay_inside_frame(failures: Array[String]) -> void:
	var image_path := "user://ai_object_visual_polygon_outside_frame.png"
	var manifest_path := "user://ai_object_visual_polygon_outside_frame.json"
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x in range(8, 24):
		for y in range(8, 24):
			image.set_pixel(x, y, Color(0.9, 0.3, 0.2, 1.0))
	if image.save_png(image_path) != OK:
		failures.append("object visual polygon bounds fixture image should save")
		return
	var manifest := {
		"asset_id": "bad_object_visual_polygon_bounds",
		"asset_kind": "object_visual",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"runtime_object_sprite_ok": true,
		"frame_grid_ok": true,
		"frame_count": 1,
		"frame_size": [32, 32],
		"expected_frame_size": [32, 32],
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": [16, 16],
		"polygon_ok": true,
		"fallback_polygon_points_px": [[-2, 4], [20, 4], [20, 20], [4, 20]],
		"review_notes": "Polygon has area, but one point sits outside the 32x32 frame.",
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("object visual polygon bounds manifest should open for write")
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var report: Dictionary = AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var issues: Array = report.get("issues", [])
	if bool(report.get("ready", true)):
		failures.append("manifest should block object visual fallback polygons outside the frame")
	if not issues.has("manifest_fallback_polygon_outside_frame"):
		failures.append("manifest should explain fallback polygon points outside the frame")
