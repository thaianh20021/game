class_name UpgradeDB
extends RefCounted
## In-run upgrade pool for room-clear rewards.

const UPGRADES := [
	{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP", "rarity": "common", "max_stack": 5, "tags": ["survival", "hp"]},
	{"id": "power_rune", "name": "Power Rune", "desc": "+12% damage", "rarity": "rare", "max_stack": 3, "tags": ["damage", "core"]},
	{"id": "swift_boots", "name": "Swift Boots", "desc": "+8 move speed", "rarity": "common", "max_stack": 5, "tags": ["mobility", "speed"]},
	{"id": "dash_spring", "name": "Dash Spring", "desc": "-10% dash cooldown", "rarity": "rare", "max_stack": 5, "tags": ["mobility", "dash"]},
	{"id": "focus_cell", "name": "Focus Cell", "desc": "+10 max resource", "rarity": "common", "max_stack": 5, "tags": ["resource", "skill"]},
	{"id": "lucky_coin", "name": "Lucky Coin", "desc": "+15 gold", "rarity": "common", "max_stack": 8, "tags": ["economy", "gold"]},
	{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage", "rarity": "rare", "max_stack": 4, "tags": ["damage", "fire", "element"]},
	{"id": "frost_rune", "name": "Frost Rune", "desc": "+15% ice damage", "rarity": "rare", "max_stack": 4, "tags": ["damage", "ice", "element"]},
	{"id": "storm_rune", "name": "Storm Rune", "desc": "+15% lightning damage", "rarity": "rare", "max_stack": 4, "tags": ["damage", "lightning", "element"]},
	{"id": "venom_rune", "name": "Venom Rune", "desc": "+15% poison damage", "rarity": "rare", "max_stack": 4, "tags": ["damage", "poison", "element"]},
	{"id": "split_socket", "name": "Split Socket", "desc": "+1 projectile", "rarity": "epic", "max_stack": 4, "tags": ["projectile", "socket"]},
	{"id": "familiar_rune", "name": "Familiar Rune", "desc": "+20% pet damage", "rarity": "rare", "max_stack": 5, "tags": ["pet", "summon"]},
	{"id": "aegis_socket", "name": "Aegis Socket", "desc": "+25% shield duration", "rarity": "rare", "max_stack": 4, "tags": ["shield", "defense", "socket"]},
	{"id": "precision_lens", "name": "Precision Lens", "desc": "+6% crit chance", "rarity": "rare", "max_stack": 5, "tags": ["damage", "crit"]},
	{"id": "tempo_glove", "name": "Tempo Glove", "desc": "-8% weapon cooldown", "rarity": "rare", "max_stack": 5, "tags": ["weapon", "speed"]},
	{"id": "spell_thread", "name": "Spell Thread", "desc": "-10% active skill cooldown", "rarity": "rare", "max_stack": 5, "tags": ["skill", "cooldown"]},
	{"id": "soul_capacitor", "name": "Soul Capacitor", "desc": "+20% ultimate charge gain", "rarity": "epic", "max_stack": 4, "tags": ["ultimate", "resource"]},
]

const RARITIES := ["common", "rare", "epic"]

static func roll_choices(
		run_seed: int,
		room_id: int,
		floor_index: int,
		count: int = 3,
) -> Array[Dictionary]:
	return _roll_choices_from_pool(_upgrade_pool(), _choice_seed(run_seed, room_id, floor_index), count)

static func roll_room_choices(
		run_seed: int,
		room_id: int,
		floor_index: int,
		room_type: int,
		count: int = 3,
) -> Array[Dictionary]:
	return _roll_room_choices_from_pool(_upgrade_pool(),
		run_seed, room_id, floor_index, room_type, count)

static func roll_synergy_room_choices(
		run_seed: int,
		room_id: int,
		floor_index: int,
		room_type: int,
		build_tags: Array,
		count: int = 3,
) -> Array[Dictionary]:
	var choices := roll_room_choices(run_seed, room_id, floor_index, room_type, count)
	return _ensure_build_tag_match(
		choices, run_seed, room_id, floor_index, room_type, build_tags)

static func roll_available_synergy_room_choices(
		run_seed: int,
		room_id: int,
		floor_index: int,
		room_type: int,
		build_tags: Array,
		player: Player,
		count: int = 3,
) -> Array[Dictionary]:
	var pool := _available_upgrade_pool(player)
	if pool.size() < count:
		return roll_synergy_room_choices(
			run_seed, room_id, floor_index, room_type, build_tags, count)
	var choices := _roll_room_choices_from_pool(pool,
		run_seed, room_id, floor_index, room_type, count)
	return _ensure_build_tag_match(
		choices, run_seed, room_id, floor_index, room_type, build_tags, {}, pool)

static func reroll_room_choices(
		run_seed: int,
		room_id: int,
		floor_index: int,
		room_type: int,
		previous_choices: Array,
		count: int = 3,
) -> Array[Dictionary]:
	return _reroll_room_choices_from_pool(_upgrade_pool(),
		run_seed, room_id, floor_index, room_type, previous_choices, count)

static func reroll_synergy_room_choices(
		run_seed: int,
		room_id: int,
		floor_index: int,
		room_type: int,
		previous_choices: Array,
		build_tags: Array,
		count: int = 3,
) -> Array[Dictionary]:
	var choices := reroll_room_choices(
		run_seed, room_id, floor_index, room_type, previous_choices, count)
	var excluded := {}
	for choice in previous_choices:
		if choice is Dictionary:
			excluded[str(choice.get("id", ""))] = true
	return _ensure_build_tag_match(
		choices, run_seed + 1709, room_id + 43, floor_index, room_type, build_tags, excluded)

static func reroll_available_synergy_room_choices(
		run_seed: int,
		room_id: int,
		floor_index: int,
		room_type: int,
		previous_choices: Array,
		build_tags: Array,
		player: Player,
		count: int = 3,
) -> Array[Dictionary]:
	var pool := _available_upgrade_pool(player)
	if pool.size() < count:
		return reroll_synergy_room_choices(
			run_seed, room_id, floor_index, room_type, previous_choices, build_tags, count)
	var choices := _reroll_room_choices_from_pool(pool,
		run_seed, room_id, floor_index, room_type, previous_choices, count)
	var excluded := _choice_id_set(previous_choices)
	return _ensure_build_tag_match(
		choices, run_seed + 1709, room_id + 43, floor_index, room_type, build_tags, excluded, pool)

static func _roll_room_choices_from_pool(
		pool: Array[Dictionary],
		run_seed: int,
		room_id: int,
		floor_index: int,
		room_type: int,
		count: int = 3,
) -> Array[Dictionary]:
	var choices := _roll_choices_from_pool(pool, _choice_seed(run_seed, room_id, floor_index), count)
	return _apply_room_rarity_guarantee(
		choices, run_seed, room_id, floor_index, room_type, {}, pool)

static func _reroll_room_choices_from_pool(
		source_pool: Array[Dictionary],
		run_seed: int,
		room_id: int,
		floor_index: int,
		room_type: int,
		previous_choices: Array,
		count: int = 3,
) -> Array[Dictionary]:
	var excluded := _choice_id_set(previous_choices)
	var pool: Array[Dictionary] = []
	for upgrade in source_pool:
		var id := str(upgrade.get("id", ""))
		if not excluded.has(id):
			pool.append(upgrade.duplicate())
	if pool.size() < count:
		pool = _duplicate_pool(source_pool)
	var seed := _choice_seed(run_seed + 1709, room_id + 43, floor_index + int(room_type) + 11)
	var out := _roll_choices_from_pool(pool, seed, count)
	return _apply_room_rarity_guarantee(
		out, run_seed + 1709, room_id + 43, floor_index, room_type, excluded, source_pool)

static func _apply_room_rarity_guarantee(
		choices: Array[Dictionary],
		run_seed: int,
		room_id: int,
		floor_index: int,
		room_type: int,
		excluded_ids: Dictionary = {},
		source_pool: Array[Dictionary] = [],
) -> Array[Dictionary]:
	if not _guarantees_rare_plus(room_type) or _has_rare_plus(choices):
		return choices
	var ids := {}
	for choice in choices:
		ids[str(choice.get("id", ""))] = true
	var rare_pool: Array[Dictionary] = []
	var candidates := _upgrade_pool() if source_pool.is_empty() else source_pool
	for upgrade in candidates:
		var rarity := str(upgrade.get("rarity", ""))
		var id := str(upgrade.get("id", ""))
		if ["rare", "epic"].has(rarity) and not ids.has(id) and not excluded_ids.has(id):
			rare_pool.append(upgrade.duplicate())
	if rare_pool.is_empty():
		return choices
	var rng := RandomNumberGenerator.new()
	rng.seed = _choice_seed(run_seed + 97, room_id + 31, floor_index + int(room_type))
	choices[choices.size() - 1] = rare_pool[rng.randi_range(0, rare_pool.size() - 1)]
	return choices

static func apply_upgrade(player: Player, upgrade_id: String, decision_reason: String = "") -> bool:
	if not can_apply_upgrade(player, upgrade_id):
		return false
	match upgrade_id:
		"vital_core":
			player.max_hp += 20
			player.hp = mini(player.hp + 20, player.max_hp)
			player.hp_changed.emit(player.hp, player.max_hp)
		"power_rune":
			player.damage_mult += 0.12
		"swift_boots":
			player.move_speed += 8.0
		"dash_spring":
			player.dash_cooldown = maxf(player.dash_cooldown * 0.9, 0.25)
		"focus_cell":
			player.max_resource += 10.0
			player.resource = minf(player.resource + 10.0, player.max_resource)
			player.resource_changed.emit(player.resource, player.max_resource)
		"lucky_coin":
			player.add_gold(15)
		"ember_rune":
			_add_element_bonus(player, "fire", 0.15)
		"frost_rune":
			_add_element_bonus(player, "ice", 0.15)
		"storm_rune":
			_add_element_bonus(player, "lightning", 0.15)
		"venom_rune":
			_add_element_bonus(player, "poison", 0.15)
		"split_socket":
			player.projectile_bonus += 1
		"familiar_rune":
			player.pet_damage_mult += 0.2
		"aegis_socket":
			player.shield_duration_mult += 0.25
		"precision_lens":
			player.crit_chance += 0.06
		"tempo_glove":
			player.weapon_cooldown_upgrade_mult = maxf(player.weapon_cooldown_upgrade_mult * 0.92, 0.55)
		"spell_thread":
			player.skill_cooldown_upgrade_mult = maxf(player.skill_cooldown_upgrade_mult * 0.9, 0.55)
		"soul_capacitor":
			player.ultimate_charge_gain_mult += 0.2
		_:
			return false
	player.record_upgrade(upgrade_id, upgrade_name(upgrade_id), upgrade_tags(upgrade_id), decision_reason)
	print("Upgrade: %s" % upgrade_id)
	return true

static func upgrade_effect_preview(player: Player, upgrade_id: String) -> String:
	if player == null:
		return ""
	match upgrade_id:
		"vital_core":
			return "Max HP %d -> %d" % [player.max_hp, player.max_hp + 20]
		"power_rune":
			return "Damage x%.2f -> x%.2f" % [player.damage_mult, player.damage_mult + 0.12]
		"swift_boots":
			return "Speed %.0f -> %.0f" % [player.move_speed, player.move_speed + 8.0]
		"dash_spring":
			return "Dash CD %.2fs -> %.2fs" % [
				player.dash_cooldown,
				maxf(player.dash_cooldown * 0.9, 0.25),
			]
		"focus_cell":
			return "Resource %.0f -> %.0f" % [player.max_resource, player.max_resource + 10.0]
		"lucky_coin":
			return "Gold +15"
		"ember_rune":
			return _element_preview(player, "fire", "Fire")
		"frost_rune":
			return _element_preview(player, "ice", "Ice")
		"storm_rune":
			return _element_preview(player, "lightning", "Lightning")
		"venom_rune":
			return _element_preview(player, "poison", "Poison")
		"split_socket":
			var current_projectiles := _player_projectile_count(player)
			return "Projectiles %d -> %d" % [current_projectiles, current_projectiles + 1]
		"familiar_rune":
			return "Pet damage x%.2f -> x%.2f" % [
				player.pet_damage_mult,
				player.pet_damage_mult + 0.2,
			]
		"aegis_socket":
			return "Shield duration x%.2f -> x%.2f" % [
				player.shield_duration_mult,
				player.shield_duration_mult + 0.25,
			]
		"precision_lens":
			return "Crit %d%% -> %d%%" % [
				int(round(player.crit_chance * 100.0)),
				int(round((player.crit_chance + 0.06) * 100.0)),
			]
		"tempo_glove":
			return "Weapon CD x%.2f -> x%.2f" % [
				player.weapon_cooldown_multiplier(),
				player.weapon_cooldown_multiplier() * 0.92,
			]
		"spell_thread":
			return "Skill CD x%.2f -> x%.2f" % [
				player.skill_cooldown_multiplier(),
				maxf(player.skill_cooldown_multiplier() * 0.9, 0.55),
			]
		"soul_capacitor":
			return "Ult charge x%.2f -> x%.2f" % [
				player.ultimate_charge_gain_multiplier(),
				player.ultimate_charge_gain_multiplier() + 0.2,
			]
	return ""

static func can_apply_upgrade(player: Player, upgrade_id: String) -> bool:
	return upgrade_block_reason(player, upgrade_id) == ""

static func upgrade_block_reason(player: Player, upgrade_id: String) -> String:
	var max_stack := upgrade_max_stack(upgrade_id)
	if player == null:
		return ""
	if _is_socket_upgrade(upgrade_id) and player.has_method("socket_upgrade_count") \
			and player.has_method("socket_capacity") \
			and int(player.call("socket_upgrade_count")) >= int(player.call("socket_capacity")):
		return "Sockets full"
	if max_stack <= 0 or not player.has_method("upgrade_stack_count"):
		return ""
	if int(player.call("upgrade_stack_count", upgrade_id)) >= max_stack:
		return "Max stack"
	return ""

static func upgrade_max_stack(upgrade_id: String) -> int:
	for upgrade in UPGRADES:
		if str(upgrade.get("id", "")) == upgrade_id:
			return int(upgrade.get("max_stack", 0))
	return 0

static func _is_socket_upgrade(upgrade_id: String) -> bool:
	return upgrade_tags(upgrade_id).has("socket")

static func _add_element_bonus(player: Player, element: String, amount: float) -> void:
	var current := float(player.element_damage_bonus.get(element, 0.0))
	player.element_damage_bonus[element] = current + amount

static func _element_preview(player: Player, element: String, label: String) -> String:
	var current := player.element_damage_multiplier(element)
	return "%s damage x%.2f -> x%.2f" % [label, current, current + 0.15]

static func _player_projectile_count(player: Player) -> int:
	var weapon := player.current_weapon()
	if weapon != null and weapon.has_method("projectile_count"):
		return int(weapon.call("projectile_count"))
	return maxi(int(player.projectile_bonus) + 1, 1)

static func upgrade_name(upgrade_id: String) -> String:
	for upgrade in UPGRADES:
		if str(upgrade.get("id", "")) == upgrade_id:
			return str(upgrade.get("name", upgrade_id))
	return upgrade_id

static func upgrade_tags(upgrade_id: String) -> Array[String]:
	for upgrade in UPGRADES:
		if str(upgrade.get("id", "")) == upgrade_id:
			return _string_tags(upgrade.get("tags", []))
	return []

static func tag_summary(upgrade: Dictionary) -> String:
	var parts: Array[String] = []
	for raw_tag in upgrade.get("tags", []):
		var tag := str(raw_tag)
		if tag == "":
			continue
		parts.append(tag.replace("_", " ").capitalize())
	return " / ".join(parts)

static func _guarantees_rare_plus(room_type: int) -> bool:
	return room_type == RoomNode.RoomType.ELITE \
		or room_type == RoomNode.RoomType.MINIBOSS \
		or room_type == RoomNode.RoomType.BOSS \
		or room_type == RoomNode.RoomType.TREASURE \
		or room_type == RoomNode.RoomType.EVENT

static func _has_rare_plus(choices: Array[Dictionary]) -> bool:
	for choice in choices:
		if ["rare", "epic"].has(str(choice.get("rarity", ""))):
			return true
	return false

static func _ensure_build_tag_match(
		choices: Array[Dictionary],
		run_seed: int,
		room_id: int,
		floor_index: int,
		room_type: int,
		build_tags: Array,
		excluded_ids: Dictionary = {},
		source_pool: Array[Dictionary] = [],
) -> Array[Dictionary]:
	var tag_set := _tag_set(build_tags)
	if tag_set.is_empty() or _choices_have_tag_match(choices, tag_set):
		return choices
	if choices.is_empty():
		return choices
	var ids := {}
	for choice in choices:
		ids[str(choice.get("id", ""))] = true
	var pool: Array[Dictionary] = []
	var candidates := _upgrade_pool() if source_pool.is_empty() else source_pool
	for upgrade in candidates:
		var id := str(upgrade.get("id", ""))
		if ids.has(id) or excluded_ids.has(id):
			continue
		if _choice_has_tag_match(upgrade, tag_set):
			pool.append(upgrade.duplicate())
	if pool.is_empty():
		return choices
	var rng := RandomNumberGenerator.new()
	rng.seed = _choice_seed(run_seed + 313, room_id + 71, floor_index + int(room_type) + 17)
	var replacement := pool[rng.randi_range(0, pool.size() - 1)]
	choices[_build_tag_replace_index(choices, room_type, replacement)] = replacement
	return _apply_room_rarity_guarantee(
		choices, run_seed + 313, room_id + 71, floor_index, room_type, excluded_ids, source_pool)

static func _build_tag_replace_index(
		choices: Array[Dictionary],
		room_type: int,
		replacement: Dictionary,
) -> int:
	if choices.is_empty():
		return 0
	var replacement_rare_plus := ["rare", "epic"].has(str(replacement.get("rarity", "")))
	var rare_count := 0
	for choice in choices:
		if ["rare", "epic"].has(str(choice.get("rarity", ""))):
			rare_count += 1
	if _guarantees_rare_plus(room_type) and rare_count <= 1 and not replacement_rare_plus:
		for i in choices.size():
			if not ["rare", "epic"].has(str(choices[i].get("rarity", ""))):
				return i
	return choices.size() - 1

static func _choices_have_tag_match(choices: Array[Dictionary], tag_set: Dictionary) -> bool:
	for choice in choices:
		if _choice_has_tag_match(choice, tag_set):
			return true
	return false

static func _choice_has_tag_match(choice: Dictionary, tag_set: Dictionary) -> bool:
	for raw_tag in choice.get("tags", []):
		if tag_set.has(str(raw_tag)):
			return true
	return false

static func _tag_set(tags: Array) -> Dictionary:
	var out := {}
	for raw_tag in tags:
		var tag := str(raw_tag)
		if tag != "":
			out[tag] = true
	return out

static func _string_tags(tags: Array) -> Array[String]:
	var out: Array[String] = []
	for raw_tag in tags:
		var tag := str(raw_tag)
		if tag != "":
			out.append(tag)
	return out

static func _upgrade_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for upgrade in UPGRADES:
		pool.append(upgrade.duplicate())
	return pool

static func _available_upgrade_pool(player: Player) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for upgrade in UPGRADES:
		var id := str(upgrade.get("id", ""))
		if can_apply_upgrade(player, id):
			pool.append(upgrade.duplicate())
	return pool

static func _duplicate_pool(source_pool: Array[Dictionary]) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for upgrade in source_pool:
		pool.append(upgrade.duplicate())
	return pool

static func _roll_choices_from_pool(
		source_pool: Array[Dictionary],
		seed: int,
		count: int,
) -> Array[Dictionary]:
	var pool := _duplicate_pool(source_pool)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var out: Array[Dictionary] = []
	while not pool.is_empty() and out.size() < count:
		var idx := rng.randi_range(0, pool.size() - 1)
		out.append(pool.pop_at(idx))
	return out

static func _choice_id_set(choices: Array) -> Dictionary:
	var ids := {}
	for choice in choices:
		if choice is Dictionary:
			ids[str(choice.get("id", ""))] = true
	return ids

static func _choice_seed(run_seed: int, room_id: int, floor_index: int) -> int:
	return int(abs((run_seed * 73856093) ^ (room_id * 19349663) ^ (floor_index * 83492791)))
