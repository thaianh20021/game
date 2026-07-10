class_name AssetSourceRegistry
extends RefCounted
## Release policy for runtime assets, placeholders, and reference-only sources.

const SOURCE_PROFILES := {
	"0x72_dungeontileset_ii": {
		"source_kind": "third_party_licensed",
		"license": "0x72 DungeonTilesetII",
		"release_decision": "public_ok",
		"review_status": "stable_public_ok",
		"replacement_policy": "licensed_ok",
		"usable_runtime_asset": true,
		"public_ready": true,
	},
	"internal_generated_placeholder": {
		"source_kind": "internal_generated",
		"license": "internal_generated_placeholder",
		"release_decision": "internal_only",
		"review_status": "stable_internal_only",
		"replacement_policy": "replace_before_public",
		"generated_placeholder": true,
		"usable_runtime_asset": true,
		"public_ready": false,
	},
	"generated_audio": {
		"source_kind": "internal_generated",
		"license": "internal_generated_placeholder",
		"release_decision": "internal_only",
		"review_status": "stable_internal_only",
		"replacement_policy": "replace_before_public",
		"generated_placeholder": true,
		"usable_runtime_asset": true,
		"public_ready": false,
	},
	"procedural_godot_shapes": {
		"source_kind": "project_owned",
		"license": "project_owned_procedural",
		"release_decision": "public_ok",
		"review_status": "stable_procedural_ok",
		"replacement_policy": "owned_ok",
		"reference_policy": "fanmade_reference_only_no_copy",
		"usable_runtime_asset": true,
		"public_ready": true,
	},
	"project_owned_procedural_audio": {
		"source_kind": "project_owned",
		"license": "project_owned_procedural_audio",
		"release_decision": "public_ok",
		"review_status": "stable_procedural_audio_ok",
		"replacement_policy": "owned_ok",
		"reference_policy": "fanmade_reference_only_no_copy",
		"usable_runtime_asset": true,
		"public_ready": true,
	},
	"project_owned_pixel_art": {
		"source_kind": "project_owned",
		"license": "project_owned_pixel_art",
		"release_decision": "public_ok",
		"review_status": "stable_project_owned_ok",
		"replacement_policy": "owned_ok",
		"reference_policy": "fanmade_reference_only_no_copy",
		"usable_runtime_asset": true,
		"public_ready": true,
	},
	"project_owned_collision_polygon": {
		"source_kind": "project_owned",
		"license": "project_owned_collision_polygon",
		"release_decision": "public_ok",
		"review_status": "stable_collision_ok",
		"replacement_policy": "owned_ok",
		"reference_policy": "fanmade_reference_only_no_copy",
		"usable_runtime_asset": true,
		"public_ready": true,
		"requires_collision_review": true,
	},
	"fanmade_reference_only": {
		"source_kind": "reference",
		"license": "reference_only_no_runtime_asset",
		"release_decision": "reference_only",
		"review_status": "reference_ok_no_copy",
		"replacement_policy": "do_not_copy_assets_or_code",
		"usable_runtime_asset": false,
		"public_ready": false,
	},
	"fanmade_direct_copy": {
		"source_kind": "forbidden",
		"license": "unlicensed_fanmade_copy",
		"release_decision": "blocked",
		"review_status": "blocked",
		"replacement_policy": "replace_before_public",
		"usable_runtime_asset": false,
		"public_ready": false,
		"default_issue": "direct_copy_not_allowed",
	},
	"free_itchio": {
		"source_kind": "third_party_free",
		"license": "license_required",
		"release_decision": "public_ok",
		"review_status": "license_metadata_present",
		"replacement_policy": "licensed_ok",
		"usable_runtime_asset": true,
		"public_ready": true,
		"requires_license_metadata": true,
		"requires_itchio_source_url": true,
		"requires_frame_grid_review": true,
	},
	"user_local_assets": {
		"source_kind": "user_local_asset",
		"license": "license_required",
		"release_decision": "public_ok",
		"review_status": "local_provenance_and_frame_review_present",
		"replacement_policy": "licensed_ok",
		"usable_runtime_asset": true,
		"public_ready": true,
		"requires_license_metadata": true,
		"requires_local_source_path": true,
		"requires_frame_grid_review": true,
	},
	"godot_asset_library": {
		"source_kind": "third_party_free",
		"license": "license_required",
		"release_decision": "public_ok",
		"review_status": "license_metadata_present",
		"replacement_policy": "licensed_ok",
		"usable_runtime_asset": true,
		"public_ready": true,
		"requires_license_metadata": true,
		"requires_godot_asset_library_source_url": true,
		"requires_frame_grid_review": true,
	},
	"ai_generated": {
		"source_kind": "project_owned_generated",
		"license": "license_required",
		"release_decision": "public_ok",
		"review_status": "generation_metadata_and_frame_review_present",
		"replacement_policy": "owned_ok",
		"usable_runtime_asset": true,
		"public_ready": true,
		"requires_license_metadata": true,
		"requires_generation_metadata": true,
		"requires_frame_grid_review": true,
	},
	"missing": {
		"source_kind": "missing",
		"license": "missing",
		"release_decision": "blocked",
		"review_status": "blocked",
		"usable_runtime_asset": false,
		"public_ready": false,
		"default_issue": "missing",
	},
}
const FANMADE_RUNTIME_SOURCE_URL_TOKENS := [
	"calvinwan0101/soul-knight",
	"leoyin1127/soul-knights",
	"soul-knight",
	"soul_knight",
	"zulan_the_colossus",
	"elemental-dungeons-replication",
	"e:/ai/asset/src/",
	"e:/ai/asset/src2/",
]
const LOCAL_ASSET_SOURCE_ROOTS := [
	"e:/ai/asset/",
	"e:/ai/gameasset/",
]
const LICENSE_PLACEHOLDER_VALUES := [
	"license_required",
	"unknown",
	"todo",
	"tbd",
	"unlicensed",
]

static func source_exists(source_id: String) -> bool:
	return SOURCE_PROFILES.has(source_id)

static func policy_for(
		source_id: String,
		asset_kind: String,
		issues: Array = [],
		metadata: Dictionary = {},
) -> Dictionary:
	var policy_issues := _normalized_issues(issues)
	var merged_metadata := _with_generation_manifest_metadata(metadata, policy_issues, asset_kind)
	var profile: Dictionary = SOURCE_PROFILES.get(source_id, {})
	var policy_id := source_id
	if profile.is_empty():
		profile = SOURCE_PROFILES["missing"]
		policy_id = "missing"
		_add_issue(policy_issues, "unknown_source")
	var default_issue := str(profile.get("default_issue", ""))
	if default_issue != "":
		_add_issue(policy_issues, default_issue)
	if bool(profile.get("usable_runtime_asset", false)) \
			and _has_fanmade_runtime_source(merged_metadata):
		_add_issue(policy_issues, "fanmade_runtime_source_forbidden")
	if bool(profile.get("requires_license_metadata", false)):
		var license_text := str(merged_metadata.get("license", "")).strip_edges()
		if license_text == "":
			_add_issue(policy_issues, "license_missing")
		elif _is_license_placeholder(license_text):
			_add_issue(policy_issues, "license_placeholder")
		if str(merged_metadata.get("source_url", "")).strip_edges() == "" \
				and str(merged_metadata.get("generation_manifest", "")).strip_edges() == "":
			_add_issue(policy_issues, "source_url_missing")
	if bool(profile.get("requires_itchio_source_url", false)) \
			and not _is_itchio_source_url(str(merged_metadata.get("source_url", ""))):
		_add_issue(policy_issues, "itchio_source_url_required")
	if bool(profile.get("requires_godot_asset_library_source_url", false)) \
			and not _is_godot_asset_library_source_url(str(merged_metadata.get("source_url", ""))):
		_add_issue(policy_issues, "godot_asset_library_source_url_required")
	if bool(profile.get("requires_local_source_path", false)):
		var source_path := str(merged_metadata.get("source_path", "")).strip_edges()
		if source_path == "":
			_add_issue(policy_issues, "source_path_missing")
		elif not _is_allowed_local_asset_path(source_path):
			_add_issue(policy_issues, "local_asset_source_root_not_allowed")
		if not bool(merged_metadata.get(
				"provenance_reviewed", merged_metadata.get("ownership_reviewed", false))):
			_add_issue(policy_issues, "local_asset_provenance_not_reviewed")
	if bool(profile.get("requires_generation_metadata", false)):
		if str(merged_metadata.get("generation_tool", "")).strip_edges() == "":
			_add_issue(policy_issues, "generation_tool_missing")
	if bool(profile.get("requires_frame_grid_review", false)) \
			and ["sprite", "vfx", "object_visual"].has(asset_kind):
		if not bool(merged_metadata.get("frame_grid_ok", false)):
			_add_issue(policy_issues, "frame_grid_not_reviewed")
		if int(merged_metadata.get("frame_count", 0)) <= 0:
			_add_issue(policy_issues, "frame_count_missing")
		var frame_size := _metadata_size(merged_metadata, "frame_size")
		if frame_size == Vector2.ZERO:
			_add_issue(policy_issues, "frame_size_missing")
		var expected_size := _metadata_size(merged_metadata, "expected_frame_size")
		if expected_size == Vector2.ZERO:
			_add_issue(policy_issues, "expected_frame_size_missing")
		elif frame_size != Vector2.ZERO and frame_size != expected_size:
			_add_issue(policy_issues, "frame_size_mismatch")
		if not bool(merged_metadata.get("stable_size", false)):
			_add_issue(policy_issues, "animation_size_not_stable")
		if float(merged_metadata.get("fps", 0.0)) <= 0.0:
			_add_issue(policy_issues, "animation_fps_missing")
		if not bool(merged_metadata.get("animation_stability_reviewed", false)):
			_add_issue(policy_issues, "animation_stability_not_reviewed")
		if not bool(merged_metadata.get("motion_reviewed", false)):
			_add_issue(policy_issues, "animation_motion_not_reviewed")
		if not bool(merged_metadata.get("origin_alignment_reviewed", false)):
			_add_issue(policy_issues, "origin_alignment_not_reviewed")
		if not _has_origin_px(merged_metadata):
			_add_issue(policy_issues, "origin_px_missing")
		elif _origin_px_outside_frame(_metadata_size(merged_metadata, "origin_px"), frame_size):
			_add_issue(policy_issues, "origin_px_outside_frame")
		_review_allowed_frame_center_drift(policy_issues, merged_metadata)
		_review_sheet_grid(policy_issues, merged_metadata, frame_size, int(merged_metadata.get("frame_count", 0)))
	if asset_kind == "vfx" and ["free_itchio", "user_local_assets", "godot_asset_library", "ai_generated"].has(policy_id):
		if not bool(merged_metadata.get("geometry_ok", false)):
			_add_issue(policy_issues, "vfx_geometry_not_reviewed")
		if float(merged_metadata.get("duration", 0.0)) <= 0.0:
			_add_issue(policy_issues, "vfx_duration_missing")
	if asset_kind == "audio" and ["free_itchio", "user_local_assets", "godot_asset_library", "ai_generated"].has(policy_id):
		if not bool(merged_metadata.get("waveform_ok", false)):
			_add_issue(policy_issues, "audio_waveform_not_reviewed")
		if float(merged_metadata.get("duration", 0.0)) <= 0.0:
			_add_issue(policy_issues, "audio_duration_missing")
	if asset_kind == "object_visual" and ["free_itchio", "user_local_assets", "godot_asset_library", "ai_generated"].has(policy_id):
		if not bool(merged_metadata.get("runtime_object_sprite_ok", false)):
			_add_issue(policy_issues, "runtime_object_sprite_not_reviewed")
		var fallback_points := int(merged_metadata.get(
			"fallback_polygon_points", merged_metadata.get("polygon_points", 0)))
		var fallback_area := float(merged_metadata.get(
			"fallback_polygon_area_px", merged_metadata.get("polygon_area_px", 0.0)))
		if not bool(merged_metadata.get("polygon_ok", false)) or fallback_points < 3:
			_add_issue(policy_issues, "fallback_polygon_not_reviewed")
		elif fallback_area <= 0.0:
			_add_issue(policy_issues, "fallback_polygon_area_not_reviewed")
	var needs_collision_review := asset_kind == "collision" and (
			bool(profile.get("requires_collision_review", false))
			or bool(profile.get("public_ready", false))
			or ["free_itchio", "user_local_assets", "godot_asset_library", "ai_generated"].has(policy_id))
	if needs_collision_review and asset_kind == "collision":
		if not bool(merged_metadata.get("shape_ok", false)):
			_add_issue(policy_issues, "collision_shape_not_reviewed")
		if not bool(merged_metadata.get("polygon_ok", false)) or int(merged_metadata.get("polygon_points", 0)) < 3:
			_add_issue(policy_issues, "collision_polygon_not_reviewed")
		elif float(merged_metadata.get("polygon_area_px", 0.0)) <= 0.0:
			_add_issue(policy_issues, "collision_polygon_area_not_reviewed")

	var blocked := not policy_issues.is_empty() \
		and not ["internal_generated_placeholder", "generated_audio"].has(policy_id)
	var release_decision := "blocked" if blocked else str(profile.get("release_decision", "blocked"))
	var review_status := "blocked" if blocked else str(profile.get("review_status", "blocked"))
	var replacement_policy := _replacement_policy(
		policy_id, asset_kind, profile, blocked, policy_issues)
	var public_ready := bool(profile.get("public_ready", false)) and not blocked
	var needs_replacement := not ["public_ok", "reference_only"].has(release_decision)
	return {
		"source_policy_id": policy_id,
		"source_kind": str(profile.get("source_kind", "")),
		"asset_kind": asset_kind,
		"license": str(merged_metadata.get("license", profile.get("license", ""))),
		"source_url": str(merged_metadata.get("source_url", "")),
		"source_path": str(merged_metadata.get("source_path", "")),
		"reference_source_url": str(merged_metadata.get("reference_source_url", "")),
		"pattern_reference_sources": Array(
			merged_metadata.get("pattern_reference_sources", [])).duplicate(),
		"pattern_reference_notes": str(merged_metadata.get("pattern_reference_notes", "")),
		"pattern_reference_policy": "pattern_reference_only_no_runtime_copy",
		"generation_manifest": str(merged_metadata.get("generation_manifest", "")),
		"manifest_reviewed": bool(merged_metadata.get("manifest_reviewed", false)),
		"review_notes": str(merged_metadata.get("review_notes", "")),
		"frame_center_drift_reviewed": bool(merged_metadata.get("frame_center_drift_reviewed", false)),
		"frame_center_drift_reason": str(merged_metadata.get("frame_center_drift_reason", "")),
		"reference_policy": str(profile.get("reference_policy", "")),
		"release_decision": release_decision,
		"review_status": review_status,
		"replacement_policy": replacement_policy,
		"needs_replacement_before_public": needs_replacement,
		"generated_placeholder": bool(profile.get("generated_placeholder", false)),
		"usable_runtime_asset": bool(profile.get("usable_runtime_asset", false)),
		"public_ready": public_ready,
		"ready": release_decision != "blocked",
		"issues": policy_issues,
	}

static func apply_policy(
		entry: Dictionary,
		source_id: String,
		asset_kind: String,
		issues: Array = [],
		metadata: Dictionary = {},
) -> Dictionary:
	var policy := policy_for(source_id, asset_kind, issues, metadata)
	for key in policy.keys():
		entry[key] = policy[key]
	return entry

static func generation_manifest_report(path: String) -> Dictionary:
	var issues: Array[String] = []
	var clean_path := path.strip_edges()
	if clean_path == "":
		return {"ready": false, "issues": ["manifest_path_missing"], "metadata": {}}
	if not FileAccess.file_exists(clean_path):
		return {"ready": false, "issues": ["manifest_missing"], "metadata": {"generation_manifest": clean_path}}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(clean_path))
	if not (parsed is Dictionary):
		return {"ready": false, "issues": ["manifest_json_invalid"], "metadata": {"generation_manifest": clean_path}}
	var data := (parsed as Dictionary).duplicate(true)
	var metadata := _manifest_metadata(clean_path, data, issues)
	return {
		"ready": issues.is_empty(),
		"issues": issues,
		"metadata": metadata,
	}

static func public_release_gate(entries: Array) -> Dictionary:
	var blockers: Array[String] = []
	for entry in entries:
		if not entry is Dictionary:
			continue
		var label := str(entry.get("id", entry.get("source_policy_id", "asset")))
		if bool(entry.get("generated_placeholder", false)):
			blockers.append("%s:generated_placeholder" % label)
		for issue in Array(entry.get("issues", [])):
			blockers.append("%s:%s" % [label, str(issue)])
		if not bool(entry.get("public_ready", false)) \
				and str(entry.get("release_decision", "")) != "reference_only":
			blockers.append("%s:%s" % [label, str(entry.get("release_decision", "blocked"))])
	return {
		"public_ready": blockers.is_empty(),
		"public_release_blockers": blockers,
	}

static func _normalized_issues(issues: Array) -> Array[String]:
	var out: Array[String] = []
	for issue in issues:
		_add_issue(out, str(issue))
	return out

static func _add_issue(issues: Array[String], issue: String) -> void:
	if issue != "" and not issues.has(issue):
		issues.append(issue)

static func _with_generation_manifest_metadata(
		metadata: Dictionary,
		issues: Array[String],
		asset_kind: String,
) -> Dictionary:
	var merged := metadata.duplicate(true)
	var manifest_path := str(merged.get("generation_manifest", "")).strip_edges()
	if manifest_path == "":
		return merged
	var report := generation_manifest_report(manifest_path)
	for issue in Array(report.get("issues", [])):
		_add_issue(issues, str(issue))
	var manifest_metadata: Dictionary = report.get("metadata", {})
	var manifest_kind := str(manifest_metadata.get("asset_kind", "")).strip_edges()
	if manifest_kind != "" and manifest_kind != asset_kind:
		_add_issue(issues, "manifest_asset_kind_mismatch")
	for key in manifest_metadata.keys():
		if not merged.has(key) or merged[key] == null or str(merged[key]).strip_edges() == "":
			merged[key] = manifest_metadata[key]
	merged["manifest_reviewed"] = bool(report.get("ready", false))
	return merged

static func _manifest_metadata(
		path: String,
		data: Dictionary,
		issues: Array[String],
) -> Dictionary:
	var asset_kind := str(data.get("asset_kind", "sprite")).strip_edges()
	if asset_kind == "":
		asset_kind = "sprite"
	var supported_asset_kinds := ["sprite", "vfx", "audio", "collision", "object_visual"]
	var origin_px_present := data.has("origin_px")
	var polygon_points_px := _manifest_points(data, "polygon_points_px")
	var fallback_polygon_points_px := _manifest_points(data, "fallback_polygon_points_px")
	var polygon_point_count := int(data.get("polygon_points", data.get("fallback_polygon_points", 0)))
	if polygon_point_count <= 0:
		polygon_point_count = polygon_points_px.size()
	var polygon_area_px := float(data.get(
		"polygon_area_px", data.get("fallback_polygon_area_px", 0.0)))
	if polygon_area_px <= 0.0 and not polygon_points_px.is_empty():
		polygon_area_px = _polygon_area_px(polygon_points_px)
	var fallback_polygon_point_count := int(data.get("fallback_polygon_points", 0))
	if fallback_polygon_point_count <= 0:
		fallback_polygon_point_count = fallback_polygon_points_px.size()
	if fallback_polygon_point_count <= 0:
		fallback_polygon_point_count = polygon_point_count
	var fallback_polygon_area_px := float(data.get(
		"fallback_polygon_area_px", data.get("polygon_area_px", 0.0)))
	if fallback_polygon_area_px <= 0.0 and not fallback_polygon_points_px.is_empty():
		fallback_polygon_area_px = _polygon_area_px(fallback_polygon_points_px)
	if fallback_polygon_area_px <= 0.0:
		fallback_polygon_area_px = polygon_area_px
	var metadata := {
		"generation_manifest": path,
		"asset_id": str(data.get("asset_id", "")),
		"asset_kind": asset_kind,
		"license": str(data.get("license", "")),
		"source_url": str(data.get("source_url", "")),
		"source_path": str(data.get("source_path", "")),
		"provenance_reviewed": bool(data.get(
			"provenance_reviewed", data.get("ownership_reviewed", false))),
		"reference_source_url": str(data.get("reference_source_url", "")),
		"reference_asset_url": str(data.get("reference_asset_url", "")),
		"reference_repo": str(data.get("reference_repo", "")),
		"reference_sources": Array(data.get("reference_sources", [])).duplicate(),
		"pattern_reference_sources": Array(data.get("pattern_reference_sources", [])).duplicate(),
		"pattern_reference_notes": str(data.get("pattern_reference_notes", "")),
		"derived_from_source_url": str(data.get("derived_from_source_url", "")),
		"generation_tool": str(data.get("generation_tool", "")),
		"prompt_summary": str(data.get("prompt_summary", "")),
		"review_notes": str(data.get("review_notes", "")),
		"image_path": str(data.get("image_path", "")),
		"image_size": Vector2.ZERO,
		"frame_grid_ok": bool(data.get("frame_grid_ok", false)),
		"frame_count": int(data.get("frame_count", 0)),
		"frame_size": _manifest_size(data, "frame_size"),
		"expected_frame_size": _manifest_size(data, "expected_frame_size"),
		"stable_size": bool(data.get("stable_size", false)),
		"fps": float(data.get("fps", 0.0)),
		"animation_stability_reviewed": bool(data.get("animation_stability_reviewed", false)),
		"motion_reviewed": bool(data.get("motion_reviewed", false)),
		"origin_alignment_reviewed": bool(data.get("origin_alignment_reviewed", false)),
		"origin_px_present": origin_px_present,
		"origin_px": _manifest_size(data, "origin_px") if origin_px_present else Vector2.ZERO,
		"allow_frame_edge_contact": bool(data.get("allow_frame_edge_contact", false)),
		"allow_frame_center_drift": bool(data.get("allow_frame_center_drift", false)),
		"frame_center_drift_reviewed": bool(data.get("frame_center_drift_reviewed", false)),
		"frame_center_drift_reason": str(data.get("frame_center_drift_reason", "")),
		"max_frame_center_drift_px": float(data.get("max_frame_center_drift_px", 3.0)),
		"sheet_size": _manifest_size(data, "sheet_size"),
		"columns": int(data.get("columns", 0)),
		"rows": int(data.get("rows", 0)),
		"runtime_object_sprite_ok": bool(data.get("runtime_object_sprite_ok", false)),
		"shape_ok": bool(data.get("shape_ok", false)),
		"polygon_ok": bool(data.get("polygon_ok", false)),
		"polygon_points": polygon_point_count,
		"polygon_points_px": polygon_points_px,
		"polygon_area_px": polygon_area_px,
		"fallback_polygon_points": fallback_polygon_point_count,
		"fallback_polygon_points_px": fallback_polygon_points_px,
		"fallback_polygon_area_px": fallback_polygon_area_px,
		"geometry_ok": bool(data.get("geometry_ok", false)),
		"waveform_ok": bool(data.get("waveform_ok", false)),
		"duration": float(data.get("duration", 0.0)),
	}
	var license_text := str(metadata.get("license", "")).strip_edges()
	if license_text == "":
		_add_issue(issues, "manifest_license_missing")
	elif _is_license_placeholder(license_text):
		_add_issue(issues, "manifest_license_placeholder")
	var manifest_source_url := str(metadata.get("source_url", "")).strip_edges()
	var has_reviewable_external_source := _is_itchio_source_url(manifest_source_url) \
			or _is_godot_asset_library_source_url(manifest_source_url)
	if str(metadata.get("generation_tool", "")).strip_edges() == "" \
			and not has_reviewable_external_source:
		_add_issue(issues, "manifest_generation_tool_missing")
	if str(metadata.get("review_notes", "")).strip_edges() == "":
		_add_issue(issues, "manifest_review_notes_missing")
	if not supported_asset_kinds.has(asset_kind):
		_add_issue(issues, "manifest_asset_kind_unknown")
	if ["sprite", "vfx", "object_visual"].has(asset_kind):
		if str(metadata.get("image_path", "")).strip_edges() == "":
			_add_issue(issues, "manifest_image_path_missing")
		if int(metadata.get("frame_count", 0)) <= 0:
			_add_issue(issues, "manifest_frame_count_missing")
		if metadata.get("frame_size", Vector2.ZERO) == Vector2.ZERO:
			_add_issue(issues, "manifest_frame_size_missing")
		if metadata.get("expected_frame_size", Vector2.ZERO) == Vector2.ZERO:
			_add_issue(issues, "manifest_expected_frame_size_missing")
		if not bool(metadata.get("frame_grid_ok", false)):
			_add_issue(issues, "manifest_frame_grid_not_reviewed")
		if not bool(metadata.get("stable_size", false)):
			_add_issue(issues, "manifest_stable_size_missing")
		if float(metadata.get("fps", 0.0)) <= 0.0:
			_add_issue(issues, "manifest_animation_fps_missing")
		if not bool(metadata.get("animation_stability_reviewed", false)):
			_add_issue(issues, "manifest_animation_stability_not_reviewed")
		if not bool(metadata.get("motion_reviewed", false)):
			_add_issue(issues, "manifest_animation_motion_not_reviewed")
		if not bool(metadata.get("origin_alignment_reviewed", false)):
			_add_issue(issues, "manifest_origin_alignment_not_reviewed")
		if not bool(metadata.get("origin_px_present", false)):
			_add_issue(issues, "manifest_origin_px_missing")
		elif _origin_px_outside_frame(metadata.get("origin_px", Vector2.ZERO),
				metadata.get("frame_size", Vector2.ZERO)):
			_add_issue(issues, "manifest_origin_px_outside_frame")
		_review_allowed_frame_center_drift(issues, metadata, "manifest_")
		_review_sheet_grid(issues, metadata, metadata.get("frame_size", Vector2.ZERO),
			int(metadata.get("frame_count", 0)), "manifest_")
	if asset_kind == "vfx":
		if not bool(metadata.get("geometry_ok", false)):
			_add_issue(issues, "manifest_vfx_geometry_missing")
		if float(metadata.get("duration", 0.0)) <= 0.0:
			_add_issue(issues, "manifest_duration_missing")
	if asset_kind == "audio":
		if not bool(metadata.get("waveform_ok", false)):
			_add_issue(issues, "manifest_audio_waveform_missing")
		if float(metadata.get("duration", 0.0)) <= 0.0:
			_add_issue(issues, "manifest_duration_missing")
	if asset_kind == "object_visual":
		if not bool(metadata.get("runtime_object_sprite_ok", false)):
			_add_issue(issues, "manifest_runtime_object_sprite_missing")
		var fallback_area := float(metadata.get(
			"fallback_polygon_area_px", metadata.get("polygon_area_px", 0.0)))
		if not bool(metadata.get("polygon_ok", false)) \
				or int(metadata.get("fallback_polygon_points", 0)) < 3:
			_add_issue(issues, "manifest_fallback_polygon_missing")
		elif fallback_area <= 0.0:
			_add_issue(issues, "manifest_fallback_polygon_area_missing")
		var object_polygon_points := fallback_polygon_points_px
		if object_polygon_points.is_empty():
			object_polygon_points = polygon_points_px
		if object_polygon_points.is_empty():
			_add_issue(issues, "manifest_fallback_polygon_points_px_missing")
		var polygon_frame_size: Vector2 = metadata.get("frame_size", Vector2.ZERO)
		if polygon_frame_size == Vector2.ZERO:
			polygon_frame_size = metadata.get("expected_frame_size", Vector2.ZERO)
		if _polygon_points_outside_frame(object_polygon_points, polygon_frame_size):
			_add_issue(issues, "manifest_fallback_polygon_outside_frame")
	if asset_kind == "collision":
		if not bool(metadata.get("shape_ok", false)):
			_add_issue(issues, "manifest_collision_shape_missing")
		if not bool(metadata.get("polygon_ok", false)) \
				or int(metadata.get("polygon_points", 0)) < 3:
			_add_issue(issues, "manifest_collision_polygon_missing")
		elif float(metadata.get("polygon_area_px", 0.0)) <= 0.0:
			_add_issue(issues, "manifest_collision_polygon_area_missing")
	_review_manifest_image_contract(metadata, issues)
	return metadata

static func _review_manifest_image_contract(metadata: Dictionary, issues: Array[String]) -> void:
	var image_path := str(metadata.get("image_path", "")).strip_edges()
	if image_path == "":
		return
	if not FileAccess.file_exists(image_path):
		_add_issue(issues, "manifest_image_missing")
		return
	var image := _load_manifest_review_image(image_path, metadata)
	if image == null:
		_add_issue(issues, "manifest_image_load_failed")
		return
	var actual_size := Vector2(image.get_width(), image.get_height())
	metadata["image_size"] = actual_size
	var expected_size := _manifest_expected_image_size(metadata)
	if expected_size != Vector2.ZERO and actual_size != expected_size:
		_add_issue(issues, "manifest_image_size_mismatch")
	var frame_size: Vector2 = metadata.get("frame_size", Vector2.ZERO)
	if frame_size == Vector2.ZERO:
		return
	var frame_w := int(frame_size.x)
	var frame_h := int(frame_size.y)
	if frame_w <= 0 or frame_h <= 0:
		return
	if int(actual_size.x) % frame_w != 0 or int(actual_size.y) % frame_h != 0:
		_add_issue(issues, "manifest_image_not_divisible_by_frame_size")
		return
	var image_columns := int(actual_size.x / frame_w)
	var image_rows := int(actual_size.y / frame_h)
	var image_cells := image_columns * image_rows
	metadata["image_columns"] = image_columns
	metadata["image_rows"] = image_rows
	metadata["image_grid_cell_count"] = image_cells
	var frame_count := int(metadata.get("frame_count", 0))
	if frame_count > image_cells:
		_add_issue(issues, "manifest_image_frame_count_exceeds_grid")
	elif frame_count > 0 and frame_count != image_cells:
		_add_issue(issues, "manifest_image_frame_count_mismatch")
	_review_frame_occupancy(image, image_columns, frame_w, frame_h,
		mini(maxi(frame_count, 0), image_cells), metadata, issues)

static func _load_manifest_review_image(image_path: String, metadata: Dictionary) -> Image:
	if image_path.begins_with("res://"):
		var texture := ResourceLoader.load(image_path) as Texture2D
		if texture == null:
			return null
		var image := texture.get_image()
		if image != null:
			metadata["manifest_image_loader"] = "resource_texture"
		return image
	var image := Image.new()
	if image.load(image_path) != OK:
		return null
	metadata["manifest_image_loader"] = "raw_image_file"
	return image

static func _manifest_expected_image_size(metadata: Dictionary) -> Vector2:
	var sheet_size: Vector2 = metadata.get("sheet_size", Vector2.ZERO)
	if sheet_size != Vector2.ZERO:
		return sheet_size
	var frame_size: Vector2 = metadata.get("frame_size", Vector2.ZERO)
	if frame_size == Vector2.ZERO:
		return Vector2.ZERO
	var columns := int(metadata.get("columns", 0))
	var rows := int(metadata.get("rows", 0))
	if columns > 0 and rows > 0:
		return Vector2(frame_size.x * columns, frame_size.y * rows)
	if int(metadata.get("frame_count", 0)) == 1:
		return frame_size
	return Vector2.ZERO

static func _replacement_policy(
		source_id: String,
		asset_kind: String,
		profile: Dictionary,
		blocked: bool,
		policy_issues: Array[String],
) -> String:
	if source_id == "missing":
		match asset_kind:
			"audio":
				return "add_audio_before_public"
			"vfx":
				return "add_procedural_fx_before_release"
			_:
				return "add_asset_before_public"
	if ["free_itchio", "godot_asset_library"].has(source_id) and blocked:
		if _has_any(policy_issues, ["license_missing", "license_placeholder", "source_url_missing"]):
			return "add_license_before_public"
		if policy_issues.has("itchio_source_url_required"):
			return "add_itchio_source_before_public"
		if policy_issues.has("godot_asset_library_source_url_required"):
			return "add_godot_asset_library_source_before_public"
		return _blocked_replacement_policy(asset_kind, policy_issues)
	if source_id == "user_local_assets" and blocked:
		if _has_any(policy_issues, [
			"license_missing", "license_placeholder", "source_path_missing",
			"local_asset_source_root_not_allowed",
			"local_asset_provenance_not_reviewed",
		]):
			return "add_local_asset_provenance_before_public"
		return _blocked_replacement_policy(asset_kind, policy_issues)
	if source_id == "ai_generated" and blocked:
		if _has_any(policy_issues, [
			"license_missing", "license_placeholder", "source_url_missing",
			"generation_tool_missing",
		]):
			return "add_source_metadata_before_public"
		return _blocked_replacement_policy(asset_kind, policy_issues)
	if source_id == "project_owned_collision_polygon" and blocked:
		return "fix_collision_polygon_before_public"
	return str(profile.get("replacement_policy", "replace_before_public"))

static func _blocked_replacement_policy(asset_kind: String, policy_issues: Array[String]) -> String:
	match asset_kind:
		"audio":
			return "fix_waveform_before_release"
		"vfx":
			if _has_any(policy_issues, ["vfx_geometry_not_reviewed", "vfx_duration_missing"]):
				return "fix_vfx_geometry_before_release"
			return "fix_frame_grid_before_release"
		"collision":
			return "fix_collision_polygon_before_public"
		"sprite":
			return "fix_frame_grid_before_release"
	return "replace_before_public"

static func _has_any(values: Array[String], candidates: Array[String]) -> bool:
	for candidate in candidates:
		if values.has(candidate):
			return true
	return false

static func _has_fanmade_runtime_source(metadata: Dictionary) -> bool:
	for key in ["source_url", "source_path", "image_path", "generation_manifest",
			"reference_source_url", "reference_asset_url", "reference_repo",
			"derived_from_source_url"]:
		if _is_fanmade_reference_url(str(metadata.get(key, ""))):
			return true
	for source in Array(metadata.get("reference_sources", [])):
		if _is_fanmade_reference_url(str(source)):
			return true
	return false

static func _is_fanmade_reference_url(source_url: String) -> bool:
	var clean := source_url.strip_edges().to_lower().replace("\\", "/")
	for token in FANMADE_RUNTIME_SOURCE_URL_TOKENS:
		if clean.contains(token):
			return true
	return false

static func _is_license_placeholder(license_text: String) -> bool:
	var clean := license_text.strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	return LICENSE_PLACEHOLDER_VALUES.has(clean)

static func _is_allowed_local_asset_path(source_path: String) -> bool:
	var clean := source_path.strip_edges().to_lower().replace("\\", "/")
	for root in LOCAL_ASSET_SOURCE_ROOTS:
		if clean.begins_with(root):
			return true
	return false

static func _is_itchio_source_url(source_url: String) -> bool:
	var clean := source_url.strip_edges().to_lower()
	return clean == "https://itch.io" \
			or clean == "http://itch.io" \
			or clean.begins_with("https://itch.io/") \
			or clean.begins_with("http://itch.io/") \
			or clean.contains(".itch.io/")

static func _is_godot_asset_library_source_url(source_url: String) -> bool:
	var clean := source_url.strip_edges().to_lower()
	return clean.begins_with("https://godotengine.org/asset-library") \
			or clean.begins_with("http://godotengine.org/asset-library")

static func _metadata_size(metadata: Dictionary, key: String) -> Vector2:
	var value: Variant = metadata.get(key, Vector2.ZERO)
	return _size_value(value)

static func _has_origin_px(metadata: Dictionary) -> bool:
	return bool(metadata.get("origin_px_present", metadata.has("origin_px")))

static func _origin_px_outside_frame(origin_px: Vector2, frame_size: Vector2) -> bool:
	if frame_size == Vector2.ZERO:
		return false
	return origin_px.x < 0.0 or origin_px.y < 0.0 \
			or origin_px.x > frame_size.x or origin_px.y > frame_size.y

static func _manifest_size(data: Dictionary, key: String) -> Vector2:
	var value: Variant = data.get(key, Vector2.ZERO)
	return _size_value(value)

static func _manifest_points(data: Dictionary, key: String) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var value: Variant = data.get(key, [])
	if not (value is Array):
		return points
	var raw_points: Array = value
	for raw_point in raw_points:
		_append_point(points, raw_point)
	return points

static func _append_point(points: Array[Vector2], value: Variant) -> void:
	if value is Vector2:
		points.append(value)
	elif value is Vector2i:
		points.append(Vector2(value))
	elif value is Array:
		var values: Array = value
		if values.size() >= 2:
			points.append(Vector2(float(values[0]), float(values[1])))
	elif value is Dictionary:
		var values: Dictionary = value
		if values.has("x") and values.has("y"):
			points.append(Vector2(float(values["x"]), float(values["y"])))

static func _polygon_area_px(points: Array[Vector2]) -> float:
	if points.size() < 3:
		return 0.0
	var area := 0.0
	for index in points.size():
		var current := points[index]
		var next := points[(index + 1) % points.size()]
		area += current.x * next.y - next.x * current.y
	return absf(area) * 0.5

static func _polygon_points_outside_frame(points: Array[Vector2], frame_size: Vector2) -> bool:
	if points.is_empty() or frame_size == Vector2.ZERO:
		return false
	for point in points:
		if point.x < 0.0 or point.y < 0.0 \
				or point.x > frame_size.x or point.y > frame_size.y:
			return true
	return false

static func _size_value(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value)
	if value is Array:
		var values: Array = value
		if values.size() >= 2:
			return Vector2(float(values[0]), float(values[1]))
	if value is Dictionary:
		var values: Dictionary = value
		if values.has("x") and values.has("y"):
			return Vector2(float(values["x"]), float(values["y"]))
		if values.has("width") and values.has("height"):
			return Vector2(float(values["width"]), float(values["height"]))
	return Vector2.ZERO

static func _review_sheet_grid(
		issues: Array[String],
		metadata: Dictionary,
		frame_size: Vector2,
		frame_count: int,
		issue_prefix: String = "",
) -> void:
	var sheet_size := _metadata_size(metadata, "sheet_size")
	var columns := int(metadata.get("columns", 0))
	var rows := int(metadata.get("rows", 0))
	if sheet_size == Vector2.ZERO and columns <= 0 and rows <= 0:
		if frame_count > 1:
			_add_issue(issues, issue_prefix + "frame_sheet_grid_missing")
		return
	if frame_size == Vector2.ZERO:
		return
	if columns <= 0 or rows <= 0:
		_add_issue(issues, issue_prefix + "frame_grid_dimensions_missing")
	elif frame_count > 0 and columns * rows != frame_count:
		_add_issue(issues, issue_prefix + "frame_grid_cell_count_mismatch")
	if sheet_size == Vector2.ZERO:
		return
	var sheet_w := int(sheet_size.x)
	var sheet_h := int(sheet_size.y)
	var frame_w := int(frame_size.x)
	var frame_h := int(frame_size.y)
	if sheet_w <= 0 or sheet_h <= 0 or frame_w <= 0 or frame_h <= 0:
		_add_issue(issues, issue_prefix + "sheet_size_missing")
		return
	if sheet_w % frame_w != 0 or sheet_h % frame_h != 0:
		_add_issue(issues, issue_prefix + "sheet_size_not_divisible_by_frame_size")
		return
	var inferred_columns := int(sheet_w / frame_w)
	var inferred_rows := int(sheet_h / frame_h)
	if columns > 0 and columns != inferred_columns:
		_add_issue(issues, issue_prefix + "sheet_columns_mismatch")
	if rows > 0 and rows != inferred_rows:
		_add_issue(issues, issue_prefix + "sheet_rows_mismatch")
	var declared_columns := columns if columns > 0 else inferred_columns
	var declared_rows := rows if rows > 0 else inferred_rows
	var declared_cells := declared_columns * declared_rows
	if frame_count > 0 and declared_cells != frame_count:
		_add_issue(issues, issue_prefix + "frame_grid_cell_count_mismatch")

static func _review_allowed_frame_center_drift(
		issues: Array[String],
		metadata: Dictionary,
		issue_prefix: String = "",
) -> void:
	if not bool(metadata.get("allow_frame_center_drift", false)):
		return
	if not bool(metadata.get("frame_center_drift_reviewed", false)) \
			or str(metadata.get("frame_center_drift_reason", "")).strip_edges() == "":
		_add_issue(issues, issue_prefix + "frame_center_drift_review_missing")

static func _review_frame_occupancy(
		image: Image,
		image_columns: int,
		frame_w: int,
		frame_h: int,
		frame_count: int,
		metadata: Dictionary,
		issues: Array[String],
) -> void:
	var counts: Array[int] = []
	var bounds: Array[Dictionary] = []
	var centers: Array[Vector2] = []
	if frame_count <= 0 or image_columns <= 0:
		metadata["frame_nontransparent_px"] = counts
		metadata["frame_content_bounds_px"] = bounds
		metadata["frame_content_centers_px"] = centers
		metadata["frame_center_drift_px"] = 0.0
		return
	var allow_edge_contact := bool(metadata.get("allow_frame_edge_contact", false))
	var allow_center_drift := bool(metadata.get("allow_frame_center_drift", false))
	var max_center_drift := maxf(float(metadata.get("max_frame_center_drift_px", 3.0)), 0.0)
	var first_center := Vector2.ZERO
	var max_drift := 0.0
	for frame_index in range(frame_count):
		var frame_x := (frame_index % image_columns) * frame_w
		var frame_y := int(frame_index / image_columns) * frame_h
		var nontransparent := 0
		var min_x := frame_w
		var min_y := frame_h
		var max_x := -1
		var max_y := -1
		for y in range(frame_h):
			for x in range(frame_w):
				if image.get_pixel(frame_x + x, frame_y + y).a > 0.01:
					nontransparent += 1
					min_x = mini(min_x, x)
					min_y = mini(min_y, y)
					max_x = maxi(max_x, x)
					max_y = maxi(max_y, y)
		counts.append(nontransparent)
		if nontransparent <= 0:
			bounds.append({})
			centers.append(Vector2.ZERO)
			_add_issue(issues, "manifest_frame_empty")
			continue
		var center := Vector2((float(min_x) + float(max_x)) * 0.5,
			(float(min_y) + float(max_y)) * 0.5)
		centers.append(center)
		if centers.size() == 1:
			first_center = center
		else:
			max_drift = maxf(max_drift, first_center.distance_to(center))
		bounds.append({
			"min": Vector2(min_x, min_y),
			"max": Vector2(max_x, max_y),
			"size": Vector2(max_x - min_x + 1, max_y - min_y + 1),
		})
		if not allow_edge_contact and (min_x <= 0 or min_y <= 0
				or max_x >= frame_w - 1 or max_y >= frame_h - 1):
			_add_issue(issues, "manifest_frame_content_clipped")
	metadata["frame_nontransparent_px"] = counts
	metadata["frame_content_bounds_px"] = bounds
	metadata["frame_content_centers_px"] = centers
	metadata["frame_center_drift_px"] = max_drift
	if not allow_center_drift and max_drift > max_center_drift:
		_add_issue(issues, "manifest_frame_origin_jitter")
