class_name WeaponDB
extends RefCounted
## Static lookup over data/weapons.json. Loaded once, keyed by weapon id.

const PATH := "res://data/weapons.json"

static var _by_id: Dictionary = {}


static func _load() -> void:
	if not _by_id.is_empty():
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert(data is Dictionary, "WeaponDB: invalid JSON at " + PATH)
	for w in data["weapons"]:
		_by_id[str(w["id"])] = w


static func get_weapon(id: String) -> Dictionary:
	_load()
	return _by_id.get(id, {})


static func all_ids() -> Array:
	_load()
	return _by_id.keys()
