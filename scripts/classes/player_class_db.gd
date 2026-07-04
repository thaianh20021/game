class_name PlayerClassDB
extends RefCounted
## Static lookup over data/classes.json (named to avoid clashing with the
## built-in Godot ClassDB singleton).

const PATH := "res://data/classes.json"

static var _classes: Array = []
static var _by_id: Dictionary = {}


static func _load() -> void:
	if not _by_id.is_empty():
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert(data is Dictionary, "PlayerClassDB: invalid JSON at " + PATH)
	_classes = data["classes"]
	for c in _classes:
		_by_id[str(c["id"])] = c


static func all() -> Array:
	_load()
	return _classes


static func get_class_data(id: String) -> Dictionary:
	_load()
	return _by_id.get(id, {})
