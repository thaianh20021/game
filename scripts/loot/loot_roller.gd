class_name LootRoller
extends RefCounted
## In-run drop rolls (GDD section 14). Gold scales with the enemy's spawn
## budget cost; elites boost potion/weapon chances; mini-bosses guarantee a
## weapon. Weapon rarity is rolled from loot_tables.json weights, restricted
## to rarities that actually exist in the weapon pool.
## NOTE: uses a non-seeded RNG for now; drops will move into the per-room
## SeededRNG spawn plan for Daily Seed determinism.

const LOOT_TABLE_PATH := "res://data/loot_tables.json"

static var _rng := RandomNumberGenerator.new()
static var _cfg: Dictionary = {}


static func _config() -> Dictionary:
	if _cfg.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOOT_TABLE_PATH))
		assert(data is Dictionary, "LootRoller: invalid JSON at " + LOOT_TABLE_PATH)
		_cfg = data
	return _cfg


static func roll_drops(entry: Dictionary) -> Array[Dictionary]:
	var enemy: Dictionary = entry["enemy"]
	var elite := bool(entry["elite"])
	var kind := str(enemy["kind"])
	var drops: Array[Dictionary] = []

	var gold := 2 + int(float(enemy.get("cost", 1.0)) * 2.0)
	if elite:
		gold *= 3
	if kind == "miniboss":
		gold = 60
	drops.append({"type": "gold", "value": gold})

	var potion_chance := 0.23 if elite else 0.08
	if _rng.randf() < potion_chance:
		drops.append({"type": "potion", "value": 20})

	var weapon_chance := 0.05
	if elite:
		weapon_chance = 0.25
	if kind == "miniboss":
		weapon_chance = 1.0
	if _rng.randf() < weapon_chance:
		var id := _roll_weapon_id()
		if id != "":
			drops.append({"type": "weapon", "id": id})
	return drops


static func _roll_weapon_id() -> String:
	var by_rarity := {}
	for id in WeaponDB.all_ids():
		var weapon := WeaponDB.get_weapon(str(id))
		var rarity := str(weapon.get("rarity", "common"))
		if not by_rarity.has(rarity):
			by_rarity[rarity] = []
		by_rarity[rarity].append(str(id))

	var weights: Dictionary = _config()["rarity_weights"]
	var total := 0.0
	for rarity in by_rarity.keys():
		total += float(weights.get(rarity, 0.0))
	if total <= 0.0:
		return ""
	var roll := _rng.randf() * total
	for rarity in by_rarity.keys():
		roll -= float(weights.get(rarity, 0.0))
		if roll <= 0.0:
			var ids: Array = by_rarity[rarity]
			return ids[_rng.randi_range(0, ids.size() - 1)]
	return ""
