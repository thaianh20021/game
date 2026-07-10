class_name WeaponDB
extends RefCounted
## Static lookup over data/weapons.json. Loaded once, keyed by weapon id.

const PATH := "res://data/weapons.json"
const STARTER_WEAPONS := {
	"blade_warden": "warden_sword",
	"breaker": "pioneer_axe",
	"nightblade": "bone_knife",
	"bulwark": "spiked_board",
	"arcanist": "apprentice_staff",
	"ranger": "hardwood_bow",
	"gunner": "scrap_pistol",
	"soulbinder": "cinder_orb",
	"lightkeeper": "nightwatch_mace",
	"tinkerer": "scrap_pistol",
}

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

static func starter_weapon_for_class(class_id: String) -> String:
	return str(STARTER_WEAPONS.get(class_id, "warden_sword"))

static func preview_sprite_name_for_weapon(weapon_id: String) -> String:
	var weapon := get_weapon(weapon_id)
	return sprite_name_for_group(str(weapon.get("group", "")))

static func sprite_name_for_group(group: String) -> String:
	match group:
		"sword_1h":
			return SpriteDB.first_existing(["weapon_regular_sword", "weapon_knight_sword"])
		"bow", "crossbow":
			return SpriteDB.first_existing(["weapon_bow", "weapon_bow_2"])
		"pistol":
			return SpriteDB.first_existing(["weapon_pistol_generated"])
		"staff", "orb", "tome":
			return SpriteDB.first_existing(["weapon_red_magic_staff", "weapon_green_magic_staff"])
		"dagger":
			return SpriteDB.first_existing(["weapon_knife"])
		"axe":
			return SpriteDB.first_existing(["weapon_axe", "weapon_waraxe"])
		"hammer", "shield":
			return SpriteDB.first_existing(["weapon_hammer", "weapon_big_hammer"])
		"spear":
			return SpriteDB.first_existing(["weapon_spear"])
		_:
			return SpriteDB.first_existing(["weapon_regular_sword"])
