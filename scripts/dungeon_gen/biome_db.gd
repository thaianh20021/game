class_name BiomeDB
extends RefCounted
## Lightweight floor-biome config. Enemy pools can split later; for now the
## first three floor biomes have distinct enemy pools plus stat/visual modifiers.

const BIOMES := [
	{
		"id": "ancient_cave",
		"name": "Ancient Cave",
		"enemy_pool": "res://data/enemies_ancient_cave.json",
		"boss_variant": "cave_golem",
		"boss_pool": ["cave_golem", "spore_golem"],
		"room_tint": Color.WHITE,
		"enemy_hp_mult": 1.0,
		"enemy_damage_mult": 1.0,
		"enemy_speed_mult": 1.0,
		"shop_min_rarity": "common",
		"locked_chest_chance": 0.12,
	},
	{
		"id": "fungal_depths",
		"name": "Fungal Depths",
		"enemy_pool": "res://data/enemies_fungal_depths.json",
		"boss_variant": "spore_golem",
		"boss_pool": ["spore_golem", "cave_golem", "archive_golem"],
		"room_tint": Color(0.82, 1.0, 0.86),
		"enemy_hp_mult": 1.18,
		"enemy_damage_mult": 1.12,
		"enemy_speed_mult": 1.04,
		"shop_min_rarity": "uncommon",
		"locked_chest_chance": 0.28,
	},
	{
		"id": "ember_forge",
		"name": "Ember Forge",
		"enemy_pool": "res://data/enemies_ember_forge.json",
		"boss_variant": "forge_golem",
		"boss_pool": ["forge_golem", "cave_golem", "archive_golem"],
		"room_tint": Color(1.0, 0.82, 0.68),
		"enemy_hp_mult": 1.35,
		"enemy_damage_mult": 1.25,
		"enemy_speed_mult": 1.08,
		"shop_min_rarity": "rare",
		"locked_chest_chance": 0.42,
	},
	{
		"id": "crystal_archive",
		"name": "Crystal Archive",
		"enemy_pool": "res://data/enemies_crystal_archive.json",
		"boss_variant": "archive_golem",
		"boss_pool": ["archive_golem", "forge_golem", "spore_golem"],
		"room_tint": Color(0.76, 0.88, 1.0),
		"enemy_hp_mult": 1.55,
		"enemy_damage_mult": 1.38,
		"enemy_speed_mult": 1.12,
		"shop_min_rarity": "epic",
		"locked_chest_chance": 0.55,
		"run_finale": true,
	},
	{
		"id": "shadow_crypt",
		"name": "Shadow Crypt",
		"enemy_pool": "res://data/enemies_shadow_crypt.json",
		"boss_variant": "void_golem",
		"boss_pool": ["void_golem", "archive_golem", "forge_golem"],
		"room_tint": Color(0.62, 0.58, 0.78),
		"enemy_hp_mult": 1.6,
		"enemy_damage_mult": 1.42,
		"enemy_speed_mult": 1.14,
		"shop_min_rarity": "epic",
		"locked_chest_chance": 0.6,
		"endless_theme": true,
	},
]

static func floor_biome(floor_index: int) -> Dictionary:
	var idx := clampi(floor_index - 1, 0, BIOMES.size() - 1)
	return BIOMES[idx].duplicate(true)

static func enemy_pool_path(biome: Dictionary) -> String:
	return str(biome.get("enemy_pool", "res://data/enemies_ancient_cave.json"))

static func enemy_codex_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for i in range(BIOMES.size()):
		var biome: Dictionary = BIOMES[i]
		var pool := _load_enemy_pool(enemy_pool_path(biome))
		for raw_enemy in Array(pool.get("enemies", [])):
			if not (raw_enemy is Dictionary):
				continue
			var enemy := (raw_enemy as Dictionary).duplicate(true)
			var kind := str(enemy.get("kind", ""))
			enemy["biome_id"] = str(biome.get("id", ""))
			enemy["biome_name"] = str(biome.get("name", ""))
			enemy["floor_index"] = i + 1
			enemy["run_finale"] = bool(biome.get("run_finale", false))
			enemy["is_boss"] = kind == "boss"
			enemy["is_miniboss"] = kind == "miniboss"
			enemy["weak_text"] = _list_text(Array(enemy.get("weak", [])))
			enemy["resist_text"] = _list_text(Array(enemy.get("resist", [])))
			entries.append(enemy)
	return entries

static func enemy_codex_summary(max_biomes: int = 4) -> String:
	var parts: Array[String] = []
	for i in range(mini(max_biomes, BIOMES.size())):
		var biome: Dictionary = BIOMES[i]
		var pool := _load_enemy_pool(enemy_pool_path(biome))
		var enemies: Array = pool.get("enemies", [])
		var boss := _boss_entry(enemies)
		var boss_text := ""
		if not boss.is_empty():
			boss_text = " | Boss %s%s Weak %s Resist %s" % [
				str(boss.get("name", boss.get("id", "Boss"))),
				" finale" if bool(biome.get("run_finale", false)) else "",
				_list_text(Array(boss.get("weak", []))),
				_list_text(Array(boss.get("resist", []))),
			]
		parts.append("%s %d%s" % [
			str(biome.get("name", "")),
			enemies.size(),
			boss_text,
		])
	return "Enemy Roster: %s" % " / ".join(parts)

static func boss_variant_for_run(
		biome: Dictionary,
		run_seed: int,
		floor_index: int,
		recent_bosses: Array = [],
) -> String:
	var fallback := str(biome.get("boss_variant", "cave_golem")).strip_edges()
	var pool: Array = biome.get("boss_pool", [])
	if pool.is_empty():
		return fallback
	var variants: Array[String] = []
	for entry in pool:
		var variant := str(entry).strip_edges()
		if variant != "" and not variants.has(variant):
			variants.append(variant)
	if variants.is_empty():
		return fallback
	var key := "%s:%d:%d" % [str(biome.get("id", "biome")), run_seed, floor_index]
	var picked := variants[absi(key.hash()) % variants.size()]
	if not recent_bosses.has(picked) or variants.size() <= 1:
		return picked
	for offset in range(1, variants.size()):
		var candidate := variants[(variants.find(picked) + offset) % variants.size()]
		if not recent_bosses.has(candidate):
			return candidate
	return picked

static func _load_enemy_pool(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}

static func _boss_entry(enemies: Array) -> Dictionary:
	for raw_enemy in enemies:
		if raw_enemy is Dictionary and str((raw_enemy as Dictionary).get("kind", "")) == "boss":
			return raw_enemy as Dictionary
	return {}

static func _list_text(values: Array) -> String:
	var parts: Array[String] = []
	for value in values:
		var text := str(value).strip_edges()
		if text != "":
			parts.append(text)
	return "none" if parts.is_empty() else "/".join(parts)
