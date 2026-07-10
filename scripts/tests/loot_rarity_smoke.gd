extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	_check_weapon_pool_has_rare_plus(failures)
	_check_min_rarity_weapon_roll(failures)
	_check_pity_context_forces_rare_plus(failures)
	_check_meta_currency_drops(failures)
	_check_key_drops(failures)

	if failures.is_empty():
		print("Loot rarity smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_weapon_pool_has_rare_plus(failures: Array[String]) -> void:
	var rarities := {}
	for id in WeaponDB.all_ids():
		var weapon := WeaponDB.get_weapon(str(id))
		rarities[str(weapon.get("rarity", "common"))] = true
	if not rarities.has("rare"):
		failures.append("weapon pool should include rare weapons")
	if not rarities.has("epic"):
		failures.append("weapon pool should include epic weapons")

func _check_min_rarity_weapon_roll(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/loot/loot_roller.gd")
	if not source.contains("roll_weapon_id"):
		failures.append("LootRoller should expose roll_weapon_id")
		return
	var loot_script: Variant = load("res://scripts/loot/loot_roller.gd")
	var id := str(loot_script.call("roll_weapon_id", "rare"))
	if id == "":
		failures.append("rare+ weapon roll should return an id")
		return
	var rarity := str(WeaponDB.get_weapon(id).get("rarity", "common"))
	if _rarity_rank(rarity) < _rarity_rank("rare"):
		failures.append("rare+ weapon roll should not return common/uncommon")

func _check_pity_context_forces_rare_plus(failures: Array[String]) -> void:
	var entry := {
		"enemy": {"id": "loot_smoke", "kind": "miniboss", "cost": 0, "hp": 1, "dmg": 1},
		"elite": false,
	}
	var loot_script: Variant = load("res://scripts/loot/loot_roller.gd")
	var drops: Array = loot_script.callv("roll_drops", [entry, {"pity_rooms_without_rare_plus": 10}])
	var weapon_drop: Dictionary = {}
	for drop in drops:
		if str(drop.get("type", "")) == "weapon":
			weapon_drop = drop
	if weapon_drop.is_empty():
		failures.append("pity/miniboss context should produce a weapon")
		return
	var rarity := str(WeaponDB.get_weapon(str(weapon_drop.get("id", ""))).get("rarity", "common"))
	if _rarity_rank(rarity) < _rarity_rank("rare"):
		failures.append("pity context should force rare+ weapon")

func _check_meta_currency_drops(failures: Array[String]) -> void:
	var loot_script: Variant = load("res://scripts/loot/loot_roller.gd")
	var elite_drops: Array = loot_script.callv("roll_drops", [{
		"enemy": {"id": "elite_smoke", "kind": "normal", "cost": 2, "hp": 1, "dmg": 1},
		"elite": true,
	}, {}])
	if _drop_value(elite_drops, "soul_shards") < 1:
		failures.append("elite enemies should drop soul shards")
	var miniboss_drops: Array = loot_script.callv("roll_drops", [{
		"enemy": {"id": "miniboss_smoke", "kind": "miniboss", "cost": 5, "hp": 1, "dmg": 1},
		"elite": false,
	}, {}])
	if _drop_value(miniboss_drops, "soul_shards") < 3:
		failures.append("miniboss should drop a larger soul shard bundle")
	if _drop_value(miniboss_drops, "rune_dust") < 1:
		failures.append("miniboss should drop rune dust")
	var boss_drops: Array = loot_script.callv("roll_drops", [{
		"enemy": {"id": "boss_smoke", "kind": "boss", "cost": 10, "hp": 1, "dmg": 1},
		"elite": false,
	}, {}])
	if _drop_value(boss_drops, "element_cores") < 1:
		failures.append("boss should drop element cores")
	if _drop_value(boss_drops, "blueprints") < 1:
		failures.append("boss should drop blueprints")

func _check_key_drops(failures: Array[String]) -> void:
	var loot_script: Variant = load("res://scripts/loot/loot_roller.gd")
	var miniboss_drops: Array = loot_script.callv("roll_drops", [{
		"enemy": {"id": "key_miniboss_smoke", "kind": "miniboss", "cost": 5, "hp": 1, "dmg": 1},
		"elite": false,
	}, {}])
	if _drop_value(miniboss_drops, "silver_key") < 1:
		failures.append("miniboss should drop a silver key for locked chests")
	var boss_drops: Array = loot_script.callv("roll_drops", [{
		"enemy": {"id": "key_boss_smoke", "kind": "boss", "cost": 10, "hp": 1, "dmg": 1},
		"elite": false,
	}, {}])
	if _drop_value(boss_drops, "silver_key") < 1:
		failures.append("boss should drop a silver key for late locked chests")

func _drop_value(drops: Array, drop_type: String) -> int:
	var total := 0
	for drop in drops:
		if str(drop.get("type", "")) == drop_type:
			total += int(drop.get("value", 0))
	return total

func _rarity_rank(rarity: String) -> int:
	return ["common", "uncommon", "rare", "epic", "legendary", "mythic"].find(rarity)
