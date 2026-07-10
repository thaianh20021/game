class_name SpriteDB
extends RefCounted

const AssetSourceRegistryScript := preload("res://scripts/assets/asset_source_registry.gd")
const ATLAS_PATH := "res://assets/dungeon_tileset/0x72_DungeonTilesetII_v1.7.png"
const LIST_PATH := "res://assets/dungeon_tileset/tile_list_v1.7"
const FPS := 8.0
const GENERATED_PISTOL := "weapon_pistol_generated"
const GENERATED_SILVER_KEY := "pickup_silver_key_generated"
const GENERATED_BLUEPRINT := "pickup_blueprint_generated"
const GENERATED_UNKNOWN_PICKUP := "pickup_unknown_generated"
const GENERATED_FIRE_PATCH := "fire_patch_generated"
const LOCAL_MANIFEST_SPRITES := {
	"zerie_soldier_idle": "res://docs/asset_generation/zerie_soldier_idle_manifest.json",
	"zerie_soldier_walk": "res://docs/asset_generation/zerie_soldier_walk_manifest.json",
	"zerie_soldier_attack": "res://docs/asset_generation/zerie_soldier_attack_manifest.json",
	"zerie_soldier_hurt": "res://docs/asset_generation/zerie_soldier_hurt_manifest.json",
	"zerie_soldier_death": "res://docs/asset_generation/zerie_soldier_death_manifest.json",
	"zerie_orc_idle": "res://docs/asset_generation/zerie_orc_idle_manifest.json",
	"zerie_orc_walk": "res://docs/asset_generation/zerie_orc_walk_manifest.json",
	"zerie_orc_attack": "res://docs/asset_generation/zerie_orc_attack_manifest.json",
	"zerie_orc_hurt": "res://docs/asset_generation/zerie_orc_hurt_manifest.json",
	"zerie_orc_death": "res://docs/asset_generation/zerie_orc_death_manifest.json",
	"zerie_arrow_projectile": "res://docs/asset_generation/zerie_arrow_projectile_manifest.json",
}

static var _atlas: Texture2D
static var _entries: Dictionary = {}
static var _generated_textures: Dictionary = {}
static var _local_sprite_cache: Dictionary = {}
static var _loaded := false
static var _warned: Dictionary = {}

static func texture(name: String) -> Texture2D:
	return _texture(name, false)

static func texture_quiet(name: String) -> Texture2D:
	return _texture(name, true)

static func _texture(name: String, quiet: bool) -> Texture2D:
	_ensure_loaded()
	if _is_generated_sprite(name):
		return _generated_texture(name)
	if _is_local_manifest_sprite(name):
		var local_frames := _local_manifest_frames(name)
		if not local_frames.is_empty():
			return local_frames[0]
		if not quiet:
			_warn_missing(name)
		return null
	var entry := _entry_for(name)
	if entry.is_empty():
		if not quiet:
			_warn_missing(name)
		return null
	return _atlas_texture(entry["rect"])

static func frames(name: String) -> Array[Texture2D]:
	return _frames(name, false)

static func _frames(name: String, quiet: bool) -> Array[Texture2D]:
	_ensure_loaded()
	var result: Array[Texture2D] = []
	if _is_generated_sprite(name):
		return _generated_frames(name)
	if _is_local_manifest_sprite(name):
		return _local_manifest_frames(name)
	if _entries.has(name):
		result.append(_atlas_texture(_entries[name]["rect"]))
		return result

	var idx := 0
	while true:
		var frame_name := "%s_f%d" % [name, idx]
		if not _entries.has(frame_name):
			break
		result.append(_atlas_texture(_entries[frame_name]["rect"]))
		idx += 1

	if result.is_empty():
		var entry := _entry_for(name)
		if entry.is_empty():
			if not quiet:
				_warn_missing(name)
		else:
			result.append(_atlas_texture(entry["rect"]))
	return result

static func build_sprite_frames(anims: Dictionary) -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")
	for anim_name in anims.keys():
		var anim_frames := frames(str(anims[anim_name]))
		if anim_frames.is_empty():
			continue
		var anim := str(anim_name)
		sprite_frames.add_animation(anim)
		sprite_frames.set_animation_speed(anim, FPS)
		sprite_frames.set_animation_loop(anim, true)
		for frame in anim_frames:
			sprite_frames.add_frame(anim, frame)
	return sprite_frames if not sprite_frames.get_animation_names().is_empty() else null

static func animation_report(name: String) -> Dictionary:
	return _animation_report(name, false)

static func _animation_report(name: String, quiet: bool) -> Dictionary:
	var anim_frames := _frames(name, quiet)
	var sizes: Array[Vector2] = []
	var nontransparent_counts: Array[int] = []
	var content_bounds: Array[Rect2i] = []
	var first_size := Vector2.ZERO
	var stable := not anim_frames.is_empty()
	var empty_frame_count := 0
	for frame in anim_frames:
		var size := _texture_size(frame)
		if first_size == Vector2.ZERO:
			first_size = size
		elif size != first_size:
			stable = false
		sizes.append(size)
		var content := _frame_content_report(frame)
		var visible_px := int(content.get("nontransparent_px", 0))
		nontransparent_counts.append(visible_px)
		content_bounds.append(content.get("bounds", Rect2i()))
		if visible_px <= 0:
			empty_frame_count += 1
	var frame_grid_ok := not anim_frames.is_empty() and first_size != Vector2.ZERO and stable and FPS > 0.0
	var content_bounds_ok := frame_grid_ok and empty_frame_count == 0 \
			and content_bounds.size() == anim_frames.size()
	var origin_px := first_size * 0.5 if first_size != Vector2.ZERO else Vector2.ZERO
	var source := _sprite_source(name, anim_frames)
	var local_metadata := _local_manifest_metadata(name) if source == "user_local_assets" else {}
	if not local_metadata.is_empty():
		origin_px = _metadata_size(local_metadata, "origin_px")
	return {
		"sprite_name": name,
		"source": source,
		"source_path": _sprite_source_path(name, anim_frames),
		"source_url": str(local_metadata.get("source_url", "")),
		"license": str(local_metadata.get("license", "")),
		"generation_manifest": str(local_metadata.get("generation_manifest", "")),
		"provenance_reviewed": bool(local_metadata.get("provenance_reviewed", false)),
		"expected_frame_size": local_metadata.get("expected_frame_size", first_size),
		"sheet_size": local_metadata.get("sheet_size", Vector2.ZERO),
		"columns": int(local_metadata.get("columns", 0)),
		"rows": int(local_metadata.get("rows", 0)),
		"frame_count": anim_frames.size(),
		"frame_size": first_size,
		"frame_sizes": sizes,
		"stable_size": stable,
		"frame_grid_ok": frame_grid_ok,
		"content_bounds_ok": content_bounds_ok,
		"empty_frame_count": empty_frame_count,
		"frame_nontransparent_px": nontransparent_counts,
		"frame_content_bounds_px": content_bounds,
		"animation_stability_reviewed": frame_grid_ok and content_bounds_ok,
		"motion_reviewed": content_bounds_ok,
		"origin_alignment_reviewed": content_bounds_ok and origin_px != Vector2.ZERO,
		"origin_px": origin_px,
		"fps": float(local_metadata.get("fps", FPS)),
	}

static func apply_sprite_metadata(target: Object, name: String) -> Dictionary:
	var report := animation_report(name)
	target.set_meta("sprite_name", name)
	target.set_meta("frame_count", int(report.get("frame_count", 0)))
	target.set_meta("frame_size", report.get("frame_size", Vector2.ZERO))
	target.set_meta("stable_size", bool(report.get("stable_size", false)))
	target.set_meta("fps", float(report.get("fps", 0.0)))
	target.set_meta("frame_grid_ok", bool(report.get("frame_grid_ok", false)))
	target.set_meta("content_bounds_ok", bool(report.get("content_bounds_ok", false)))
	target.set_meta("empty_frame_count", int(report.get("empty_frame_count", 0)))
	target.set_meta("frame_nontransparent_px", report.get("frame_nontransparent_px", []))
	target.set_meta("frame_content_bounds_px", report.get("frame_content_bounds_px", []))
	target.set_meta("animation_stability_reviewed",
		bool(report.get("animation_stability_reviewed", false)))
	target.set_meta("motion_reviewed", bool(report.get("motion_reviewed", false)))
	target.set_meta("origin_alignment_reviewed",
		bool(report.get("origin_alignment_reviewed", false)))
	target.set_meta("origin_px", report.get("origin_px", Vector2.ZERO))
	var release := release_report([name])
	var sprites: Dictionary = release.get("sprites", {})
	var entry: Dictionary = sprites.get(name, {})
	target.set_meta("asset_source", str(entry.get("source", "")))
	target.set_meta("asset_license", str(entry.get("license", "")))
	target.set_meta("source_path", str(entry.get("source_path", "")))
	target.set_meta("release_decision", str(entry.get("release_decision", "")))
	target.set_meta("review_status", str(entry.get("review_status", "")))
	target.set_meta("replacement_policy", str(entry.get("replacement_policy", "")))
	target.set_meta("needs_replacement_before_public",
		bool(entry.get("needs_replacement_before_public", false)))
	return entry

static func release_report(names: Array) -> Dictionary:
	return _release_report(names, false)

static func release_report_quiet(names: Array) -> Dictionary:
	return _release_report(names, true)

static func _release_report(names: Array, quiet: bool) -> Dictionary:
	var failures: Array[String] = []
	var generated_placeholders: Array[String] = []
	var public_release_blockers: Array[String] = []
	var sprites := {}
	for raw_name in names:
		var sprite_name := str(raw_name)
		var report := _animation_report(sprite_name, quiet)
		var frame_count := int(report.get("frame_count", 0))
		var frame_size: Vector2 = report.get("frame_size", Vector2.ZERO)
		var stable := bool(report.get("stable_size", false))
		var source := str(report.get("source", "missing"))
		var issues: Array[String] = []
		if frame_count <= 0:
			issues.append("missing")
		if frame_size == Vector2.ZERO:
			issues.append("empty_size")
		if not stable:
			issues.append("unstable_size")
		if source == "generated":
			generated_placeholders.append(sprite_name)
			public_release_blockers.append("%s:generated_placeholder" % sprite_name)
		elif source == "missing":
			public_release_blockers.append("%s:missing" % sprite_name)
		var entry := report.duplicate(true)
		var policy_metadata := report if source == "user_local_assets" else {}
		var policy := AssetSourceRegistryScript.policy_for(
			_sprite_source_policy_id(source), "sprite", issues, policy_metadata)
		entry["ready"] = issues.is_empty()
		entry["public_ready"] = bool(policy.get("public_ready", false))
		entry["generated_placeholder"] = source == "generated"
		entry["license"] = str(policy.get("license", ""))
		entry["release_decision"] = str(policy.get("release_decision", "blocked"))
		entry["review_status"] = str(policy.get("review_status", "blocked"))
		entry["replacement_policy"] = str(policy.get("replacement_policy", "replace_before_public"))
		entry["needs_replacement_before_public"] = bool(
			policy.get("needs_replacement_before_public", true))
		_copy_source_policy(entry, policy)
		entry["issues"] = issues.duplicate()
		sprites[sprite_name] = entry
		for issue in issues:
			failures.append("%s:%s" % [sprite_name, issue])
	return {
		"ready": failures.is_empty(),
		"public_ready": failures.is_empty() and public_release_blockers.is_empty(),
		"checked_count": names.size(),
		"failures": failures,
		"generated_placeholders": generated_placeholders,
		"public_release_blockers": public_release_blockers,
		"sprites": sprites,
	}

static func first_existing(candidates: Array) -> String:
	_ensure_loaded()
	for candidate in candidates:
		var sprite_name := str(candidate)
		if has_sprite(sprite_name):
			return sprite_name
	return ""

static func has_sprite(name: String) -> bool:
	_ensure_loaded()
	return _is_generated_sprite(name) \
		or (_is_local_manifest_sprite(name) and not _local_manifest_frames(name).is_empty()) \
		or not _entry_for(name).is_empty()

static func visual_scale(name: String, target_height: float = 24.0) -> Vector2:
	var report := animation_report(name)
	if str(report.get("source", "")) != "user_local_assets":
		return Vector2.ONE
	var frame_size: Vector2 = report.get("frame_size", Vector2.ZERO)
	if frame_size.y <= 0.0:
		return Vector2.ONE
	var scale_value := clampf(target_height / frame_size.y, 0.1, 1.0)
	return Vector2(scale_value, scale_value)

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if ResourceLoader.exists(ATLAS_PATH):
		_atlas = load(ATLAS_PATH)
	if _atlas == null:
		push_warning("SpriteDB atlas missing: %s" % ATLAS_PATH)
		return
	if not FileAccess.file_exists(LIST_PATH):
		push_warning("SpriteDB tile list missing: %s" % LIST_PATH)
		return
	var file := FileAccess.open(LIST_PATH, FileAccess.READ)
	if file == null:
		push_warning("SpriteDB could not open tile list: %s" % LIST_PATH)
		return
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var parts := line.split(" ", false)
		if parts.size() < 5:
			continue
		var sprite_name := str(parts[0])
		var rect := Rect2(
			float(parts[1]),
			float(parts[2]),
			float(parts[3]),
			float(parts[4])
		)
		var frame_count := int(parts[5]) if parts.size() >= 6 else 1
		_entries[sprite_name] = {
			"rect": rect,
			"frames": frame_count,
		}

static func _entry_for(name: String) -> Dictionary:
	if _entries.has(name):
		return _entries[name]
	var first_frame := "%s_f0" % name
	if _entries.has(first_frame):
		return _entries[first_frame]
	return {}

static func _atlas_texture(rect: Rect2) -> AtlasTexture:
	if _atlas == null:
		return null
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = _atlas
	atlas_texture.region = rect
	return atlas_texture

static func _is_generated_sprite(name: String) -> bool:
	return [
		GENERATED_PISTOL,
		GENERATED_SILVER_KEY,
		GENERATED_BLUEPRINT,
		GENERATED_UNKNOWN_PICKUP,
		GENERATED_FIRE_PATCH,
	].has(name)

static func _is_local_manifest_sprite(name: String) -> bool:
	return LOCAL_MANIFEST_SPRITES.has(name)

static func _sprite_source(name: String, anim_frames: Array[Texture2D]) -> String:
	if [GENERATED_PISTOL, GENERATED_SILVER_KEY, GENERATED_BLUEPRINT,
			GENERATED_UNKNOWN_PICKUP, GENERATED_FIRE_PATCH].has(name):
		return "project_owned_pixel_art"
	if _is_local_manifest_sprite(name) and not anim_frames.is_empty():
		return "user_local_assets"
	if _is_generated_sprite(name):
		return "generated"
	if anim_frames.is_empty():
		return "missing"
	return "atlas"

static func _sprite_source_path(name: String, anim_frames: Array[Texture2D]) -> String:
	match _sprite_source(name, anim_frames):
		"generated":
			return "SpriteDB generated placeholder"
		"project_owned_pixel_art":
			return "SpriteDB project-owned pixel art"
		"user_local_assets":
			var metadata := _local_manifest_metadata(name)
			return str(metadata.get("source_path", ""))
		"atlas":
			return ATLAS_PATH
	return ""

static func _sprite_license(source: String) -> String:
	match source:
		"atlas":
			return "0x72 DungeonTilesetII"
		"generated":
			return "internal_generated_placeholder"
	return "missing"

static func _sprite_source_policy_id(source: String) -> String:
	match source:
		"atlas":
			return "0x72_dungeontileset_ii"
		"project_owned_pixel_art":
			return "project_owned_pixel_art"
		"user_local_assets":
			return "user_local_assets"
		"generated":
			return "internal_generated_placeholder"
	return "missing"

static func _copy_source_policy(entry: Dictionary, policy: Dictionary) -> void:
	for key in [
		"source_policy_id",
		"source_kind",
		"asset_kind",
		"source_url",
		"source_path",
		"reference_policy",
		"usable_runtime_asset",
	]:
		entry[key] = policy.get(key, "")

static func _local_manifest_frames(name: String) -> Array[Texture2D]:
	var metadata := _local_manifest_metadata(name)
	if metadata.is_empty():
		return []
	return _local_manifest_textures(name, metadata)

static func _local_manifest_metadata(name: String) -> Dictionary:
	if not _is_local_manifest_sprite(name):
		return {}
	var cache_key := "%s_metadata" % name
	if _local_sprite_cache.has(cache_key):
		return Dictionary(_local_sprite_cache[cache_key]).duplicate(true)
	var manifest_path := str(LOCAL_MANIFEST_SPRITES[name])
	var report := AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	if not bool(report.get("ready", false)):
		return {}
	var metadata: Dictionary = report.get("metadata", {})
	_local_sprite_cache[cache_key] = metadata.duplicate(true)
	return metadata

static func _local_manifest_textures(name: String, metadata: Dictionary) -> Array[Texture2D]:
	var cache_key := "%s_frames" % name
	if _local_sprite_cache.has(cache_key):
		var cached: Array[Texture2D] = []
		for frame in _local_sprite_cache[cache_key]:
			cached.append(frame)
		return cached
	var image_path := str(metadata.get("image_path", "")).strip_edges()
	if image_path == "":
		return []
	var image := Image.new()
	if image.load(image_path) != OK:
		return []
	var texture := ImageTexture.create_from_image(image)
	var frame_size := Vector2i(_metadata_size(metadata, "frame_size"))
	var columns := int(metadata.get("columns", 0))
	var frame_count := int(metadata.get("frame_count", 0))
	if frame_size.x <= 0 or frame_size.y <= 0 or columns <= 0 or frame_count <= 0:
		return []
	var frames: Array[Texture2D] = []
	for index in range(frame_count):
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(
			float((index % columns) * frame_size.x),
			float(int(index / columns) * frame_size.y),
			float(frame_size.x),
			float(frame_size.y))
		frames.append(frame)
	_local_sprite_cache[cache_key] = frames
	return frames

static func _metadata_size(metadata: Dictionary, key: String) -> Vector2:
	var value: Variant = metadata.get(key, Vector2.ZERO)
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

static func _sprite_release_decision(source: String, issues: Array[String]) -> String:
	if not issues.is_empty():
		return "blocked"
	if source == "atlas":
		return "public_ok"
	if source == "generated":
		return "internal_only"
	return "blocked"

static func _sprite_review_status(source: String, issues: Array[String]) -> String:
	if not issues.is_empty():
		return "blocked"
	if source == "atlas":
		return "stable_public_ok"
	if source == "generated":
		return "stable_internal_only"
	return "blocked"

static func _sprite_replacement_policy(source: String, issues: Array[String]) -> String:
	if source == "missing":
		return "add_asset_before_public"
	if not issues.is_empty():
		return "fix_frame_grid_before_release"
	if source == "atlas":
		return "licensed_ok"
	if source == "generated":
		return "replace_before_public"
	return "add_asset_before_public"

static func _generated_frames(name: String) -> Array[Texture2D]:
	if name == GENERATED_FIRE_PATCH:
		return _generated_fire_patch_frames()
	var result: Array[Texture2D] = []
	var tex := _generated_texture(name)
	if tex != null:
		result.append(tex)
	return result

static func _generated_texture(name: String) -> Texture2D:
	if _generated_textures.has(name):
		return _generated_textures[name]
	if name == GENERATED_PISTOL:
		var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		_draw_rect(image, Rect2i(4, 5, 9, 3), Color(0.18, 0.2, 0.24))
		_draw_rect(image, Rect2i(5, 4, 7, 1), Color(0.62, 0.66, 0.72))
		_draw_rect(image, Rect2i(12, 6, 2, 1), Color(0.08, 0.09, 0.11))
		_draw_rect(image, Rect2i(4, 8, 6, 2), Color(0.12, 0.13, 0.16))
		_draw_rect(image, Rect2i(5, 10, 2, 1), Color(0.75, 0.58, 0.32))
		_draw_rect(image, Rect2i(3, 10, 3, 4), Color(0.32, 0.18, 0.12))
		_draw_rect(image, Rect2i(4, 13, 3, 1), Color(0.18, 0.1, 0.08))
		_generated_textures[name] = ImageTexture.create_from_image(image)
	elif name == GENERATED_SILVER_KEY:
		var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		_draw_rect(image, Rect2i(4, 3, 4, 4), Color(0.72, 0.84, 1.0))
		_draw_rect(image, Rect2i(5, 4, 2, 2), Color(0.12, 0.16, 0.24))
		_draw_rect(image, Rect2i(7, 5, 6, 2), Color(0.78, 0.88, 1.0))
		_draw_rect(image, Rect2i(11, 7, 2, 3), Color(0.78, 0.88, 1.0))
		_draw_rect(image, Rect2i(9, 7, 2, 2), Color(0.56, 0.68, 0.92))
		_generated_textures[name] = ImageTexture.create_from_image(image)
	elif name == GENERATED_BLUEPRINT:
		var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		_draw_rect(image, Rect2i(3, 3, 10, 11), Color(0.16, 0.42, 0.82))
		_draw_rect(image, Rect2i(4, 4, 8, 9), Color(0.25, 0.58, 1.0))
		_draw_rect(image, Rect2i(5, 6, 6, 1), Color(0.82, 0.94, 1.0))
		_draw_rect(image, Rect2i(5, 9, 5, 1), Color(0.82, 0.94, 1.0))
		_draw_rect(image, Rect2i(8, 7, 1, 4), Color(0.82, 0.94, 1.0))
		_generated_textures[name] = ImageTexture.create_from_image(image)
	elif name == GENERATED_UNKNOWN_PICKUP:
		var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		# ponytail: generic pickup icon; specialize by item family when the loot table grows.
		_draw_rect(image, Rect2i(4, 3, 8, 10), Color(0.52, 0.56, 0.64))
		_draw_rect(image, Rect2i(5, 4, 6, 8), Color(0.78, 0.82, 0.9))
		_draw_rect(image, Rect2i(6, 5, 4, 1), Color(1.0, 0.9, 0.35))
		_draw_rect(image, Rect2i(7, 7, 2, 1), Color(0.2, 0.24, 0.32))
		_draw_rect(image, Rect2i(7, 9, 2, 2), Color(0.2, 0.24, 0.32))
		_draw_rect(image, Rect2i(7, 12, 2, 1), Color(1.0, 0.9, 0.35))
		_generated_textures[name] = ImageTexture.create_from_image(image)
	elif name == GENERATED_FIRE_PATCH:
		var frames := _generated_fire_patch_frames()
		if not frames.is_empty():
			_generated_textures[name] = frames[0]
	return _generated_textures.get(name, null)

static func _generated_fire_patch_frames() -> Array[Texture2D]:
	var cache_key := "%s_frames" % GENERATED_FIRE_PATCH
	if _generated_textures.has(cache_key):
		var cached: Array[Texture2D] = []
		for frame in _generated_textures[cache_key]:
			cached.append(frame)
		return cached
	var frames: Array[Texture2D] = []
	for i in 4:
		var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		# ponytail: compact fire patch VFX; replace with biome-specific fire when art direction settles.
		_draw_rect(image, Rect2i(3, 9, 10, 4), Color(0.72, 0.08, 0.03, 0.72))
		_draw_rect(image, Rect2i(2 + i % 2, 11, 12 - i % 2, 2), Color(0.95, 0.18, 0.03, 0.78))
		_draw_rect(image, Rect2i(5, 6 - i % 2, 2, 6), Color(1.0, 0.48, 0.04, 0.9))
		_draw_rect(image, Rect2i(8, 5 + i % 2, 2, 7), Color(1.0, 0.35, 0.03, 0.88))
		_draw_rect(image, Rect2i(6 + i % 2, 8, 4, 4), Color(1.0, 0.82, 0.18, 0.95))
		_draw_rect(image, Rect2i(7, 9 - i % 2, 2, 3), Color(1.0, 0.96, 0.42, 0.95))
		frames.append(ImageTexture.create_from_image(image))
	_generated_textures[cache_key] = frames
	_generated_textures[GENERATED_FIRE_PATCH] = frames[0]
	return frames

static func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			image.set_pixel(x, y, color)

static func _texture_size(texture: Texture2D) -> Vector2:
	if texture is AtlasTexture:
		return (texture as AtlasTexture).region.size
	return texture.get_size() if texture != null else Vector2.ZERO

static func _frame_content_report(texture: Texture2D) -> Dictionary:
	var size := Vector2i(_texture_size(texture))
	if texture == null or size.x <= 0 or size.y <= 0:
		return {"nontransparent_px": 0, "bounds": Rect2i()}
	var source_image: Image
	var source_origin := Vector2i.ZERO
	if texture is AtlasTexture:
		var atlas_texture := texture as AtlasTexture
		if atlas_texture.atlas == null:
			return {"nontransparent_px": 0, "bounds": Rect2i()}
		source_image = atlas_texture.atlas.get_image()
		source_origin = Vector2i(atlas_texture.region.position)
	else:
		source_image = texture.get_image()
	if source_image == null:
		return {"nontransparent_px": 0, "bounds": Rect2i()}
	var count := 0
	var min_x := size.x
	var min_y := size.y
	var max_x := -1
	var max_y := -1
	for y in size.y:
		for x in size.x:
			if source_image.get_pixel(source_origin.x + x, source_origin.y + y).a <= 0.01:
				continue
			count += 1
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if count <= 0:
		return {"nontransparent_px": 0, "bounds": Rect2i()}
	return {
		"nontransparent_px": count,
		"bounds": Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1),
	}

static func _warn_missing(name: String) -> void:
	if _warned.has(name):
		return
	_warned[name] = true
	push_warning("SpriteDB missing sprite: %s" % name)
