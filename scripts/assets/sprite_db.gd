class_name SpriteDB
extends RefCounted

const ATLAS_PATH := "res://assets/dungeon_tileset/0x72_DungeonTilesetII_v1.7.png"
const LIST_PATH := "res://assets/dungeon_tileset/tile_list_v1.7"
const FPS := 8.0

static var _atlas: Texture2D
static var _entries: Dictionary = {}
static var _loaded := false
static var _warned: Dictionary = {}

static func texture(name: String) -> AtlasTexture:
	_ensure_loaded()
	var entry := _entry_for(name)
	if entry.is_empty():
		_warn_missing(name)
		return null
	return _atlas_texture(entry["rect"])

static func frames(name: String) -> Array[AtlasTexture]:
	_ensure_loaded()
	var result: Array[AtlasTexture] = []
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

static func first_existing(candidates: Array[String]) -> String:
	_ensure_loaded()
	for candidate in candidates:
		if has_sprite(candidate):
			return candidate
	return ""

static func has_sprite(name: String) -> bool:
	_ensure_loaded()
	return not _entry_for(name).is_empty()

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

static func _warn_missing(name: String) -> void:
	if _warned.has(name):
		return
	_warned[name] = true
	push_warning("SpriteDB missing sprite: %s" % name)
