class_name LootRoller
extends RefCounted
## In-run drop rolls (GDD section 14). Gold scales with the enemy's spawn
## budget cost; elites boost potion/weapon chances; mini-bosses guarantee a
## weapon. Weapon rarity is rolled from loot_tables.json weights, restricted
## to rarities that actually exist in the weapon pool.
## NOTE: uses a non-seeded RNG for now; drops will move into the per-room
## SeededRNG spawn plan for Daily Seed determinism.

const LOOT_TABLE_PATH := "res://data/loot_tables.json"
const RARITY_ORDER := ["common", "uncommon", "rare", "epic", "legendary", "mythic"]

static var _rng := RandomNumberGenerator.new()
static var _cfg: Dictionary = {}


static func _config() -> Dictionary:
	if _cfg.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOOT_TABLE_PATH))
		assert(data is Dictionary, "LootRoller: invalid JSON at " + LOOT_TABLE_PATH)
		_cfg = data
	return _cfg


static func roll_drops(entry: Dictionary, context: Dictionary = {}) -> Array[Dictionary]:
	var enemy: Dictionary = entry["enemy"]
	var elite := bool(entry["elite"])
	var kind := str(enemy["kind"])
	var drops: Array[Dictionary] = []

	var gold := 2 + int(float(enemy.get("cost", 1.0)) * 2.0)
	if elite:
		gold *= 3
	if kind == "miniboss":
		gold = 60
	if kind == "boss":
		gold = 120
	drops.append({"type": "gold", "value": gold})
	_add_meta_currency_drops(drops, kind, elite)
	_add_key_drops(drops, kind, elite)

	var potion_chance := 0.23 if elite else 0.08
	if _rng.randf() < potion_chance:
		drops.append({"type": "potion", "value": 20})

	var weapon_chance := 0.05
	if elite:
		weapon_chance = 0.25
	if kind == "miniboss":
		weapon_chance = 1.0
	var min_rarity := _min_weapon_rarity(kind, context)
	if _rng.randf() < weapon_chance:
		var id := roll_weapon_id(min_rarity)
		if id != "":
			drops.append({"type": "weapon", "id": id})
	return drops

static func _add_meta_currency_drops(drops: Array[Dictionary], kind: String, elite: bool) -> void:
	if elite:
		drops.append({"type": "soul_shards", "value": 1})
	if kind == "miniboss":
		drops.append({"type": "soul_shards", "value": 3})
		drops.append({"type": "rune_dust", "value": 2})
	elif kind == "boss":
		drops.append({"type": "soul_shards", "value": 8})
		drops.append({"type": "rune_dust", "value": 5})
		drops.append({"type": "element_cores", "value": 1})
		drops.append({"type": "blueprints", "value": 1})

static func _add_key_drops(drops: Array[Dictionary], kind: String, elite: bool) -> void:
	var key_cfg: Dictionary = _config().get("silver_key", {})
	var amount := int(key_cfg.get(kind, 0))
	if elite and amount <= 0 and _rng.randf() < float(key_cfg.get("elite_chance", 0.0)):
		amount = 1
	if amount > 0:
		drops.append({"type": "silver_key", "value": amount})


static func roll_weapon_id(min_rarity: String = "common") -> String:
	return _roll_weapon_id(min_rarity)

static func _roll_weapon_id(min_rarity: String = "common") -> String:
	var by_rarity := {}
	for id in WeaponDB.all_ids():
		var weapon := WeaponDB.get_weapon(str(id))
		var rarity := str(weapon.get("rarity", "common"))
		if _rarity_rank(rarity) < _rarity_rank(min_rarity):
			continue
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

static func _min_weapon_rarity(kind: String, context: Dictionary) -> String:
	var min_rarity := str(context.get("min_weapon_rarity", "common"))
	if kind == "boss":
		min_rarity = _higher_rarity(min_rarity, str(_config().get("boss_min_rarity", "epic")))
	if context.has("room_type"):
		var room_name := _room_type_name(int(context["room_type"]))
		var bonus: Dictionary = _config().get("room_type_bonus", {}).get(room_name, {})
		min_rarity = _higher_rarity(min_rarity, str(bonus.get("min_rarity", min_rarity)))
	var pity: Dictionary = _config().get("pity", {})
	var pity_count := int(context.get("pity_rooms_without_rare_plus", 0))
	if pity_count >= int(pity.get("rooms_without_rare_plus", 999999)):
		min_rarity = _higher_rarity(min_rarity, str(pity.get("guaranteed_min_rarity", "rare")))
	return min_rarity

static func _higher_rarity(a: String, b: String) -> String:
	return a if _rarity_rank(a) >= _rarity_rank(b) else b

static func _rarity_rank(rarity: String) -> int:
	var idx := RARITY_ORDER.find(rarity)
	return idx if idx >= 0 else 0

static func _room_type_name(room_type: int) -> String:
	var keys := RoomNode.RoomType.keys()
	return str(keys[room_type]) if room_type >= 0 and room_type < keys.size() else ""
