class_name FloorController
extends Node2D
## Runs one dungeon floor end to end: enters rooms from the graph, rolls
## spawn plans, handles locked-door transitions, remembers cleared rooms
## and announces floor completion when the boss room is cleared.
##
## Determinism: each room re-stamps from SeededRNG(seed, 1000 + room.id),
## so revisiting an uncleared room reproduces the exact same layout + spawns.

## Emitted on room enter and on room clear; the HUD/minimap redraw on it.
signal state_changed

## Emitted when the player steps on the exit portal after the boss is dead.
signal floor_completed

## Emitted after combat-style room clears so Main can offer run upgrades.
signal room_reward_pending(room_id: int, room_type: int)

## Emitted after any room objective completes so HUD can flash clear feedback.
signal room_objective_completed(text: String)

## Emitted after a room clear receives readable performance badges.
signal room_mastery_awarded(context: Dictionary)

## Emitted when a shop terminal asks Main to show the 3-item choice UI.
signal shop_choice_requested(shop: RoomInteractable, choices: Array)

## Emitted when the active boss enters a new phase/enrage state.
signal boss_phase_changed(status: Dictionary)
signal boss_attack_cued(status: Dictionary)

## Emitted when a rendered door marker is clicked/touched.
signal route_choice_requested(choice_index: int)

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const ENEMY_POOL_PATH := "res://data/enemies_ancient_cave.json"
const ENTER_OFFSET := 24.0  # px the player is placed inside the entry door
const BOSS_RUSH_CHAIN_FLOORS := 3
const LOOT_TABLE_PATH := "res://data/loot_tables.json"
const RoomAffixDBScript := preload("res://scripts/rooms/room_affix_db.gd")
const BiomeDBScript := preload("res://scripts/dungeon_gen/biome_db.gd")
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")

var floor_seed: int
var floor_index: int
var run_mode := "normal"
var difficulty_mult := 1.0
var current_biome: Dictionary = {}
var run_modifier: Dictionary = {}
var _recent_boss_variants: Array[String] = []

var rooms: Array[RoomNode] = []
var current_room: RoomNode
var cleared_rooms := {}  # room_id -> true
var room_mastery := {}  # room_id -> clear performance context
var reward_claimed_rooms := {}  # room_id -> true once the reward overlay is resolved
var interactable_claimed_rooms := {}  # room_id -> true once a one-shot room object is resolved
var trap_room_survived_rooms := {}  # room_id -> true once an event cache survival gate is cleared
var visited_rooms := {}  # room_id -> true (fog of war for the minimap)
var loot_pity_rooms_without_rare_plus := 0

var _visited_room_order: Array[int] = []
var _room_enter_hp := {}  # room_id -> { hp, max_hp }
var _room_enter_ticks_msec := {}  # room_id -> Time.get_ticks_msec() on entry
var _player: Player
var _renderer: RoomRenderer
var _grid: TileGrid
var _stamper := RoomStamper.new()
var _spawner := EnemySpawner.new()
var _pool: Dictionary
var _pool_path := ""
var _transitioning := false
var _loot_pity_threshold_cache := -1


## Can be called again with the next floor index: resets all per-floor state.
func start(
		p_seed: int,
		p_floor_index: int,
		player: Player,
		p_run_mode: String = "normal",
		p_run_modifier: Dictionary = {},
) -> void:
	floor_seed = p_seed
	floor_index = p_floor_index
	run_mode = _normalized_run_mode(p_run_mode)
	set_run_modifier(p_run_modifier)
	difficulty_mult = run_difficulty_multiplier(run_mode, floor_index)
	current_biome = _apply_run_modifier_to_biome(BiomeDBScript.floor_biome(floor_index))
	var picked_boss := ""
	if bool(current_biome.get("balance_experiment_active", false)):
		picked_boss = str(current_biome.get("boss_variant", "")).strip_edges()
	if picked_boss == "":
		picked_boss = BiomeDBScript.boss_variant_for_run(
			current_biome, floor_seed, floor_index, _recent_boss_variants)
	current_biome["boss_variant"] = picked_boss
	_remember_boss_variant(picked_boss)
	_player = player
	cleared_rooms.clear()
	room_mastery.clear()
	reward_claimed_rooms.clear()
	interactable_claimed_rooms.clear()
	trap_room_survived_rooms.clear()
	visited_rooms.clear()
	_room_enter_hp.clear()
	_room_enter_ticks_msec.clear()
	_visited_room_order.clear()
	current_room = null
	_transitioning = false
	if _renderer != null:
		_renderer.queue_free()
		_renderer = null
	var next_pool_path := BiomeDBScript.enemy_pool_path(current_biome)
	if next_pool_path == "":
		next_pool_path = ENEMY_POOL_PATH
	if _pool.is_empty() or _pool_path != next_pool_path:
		_pool_path = next_pool_path
		_pool = EnemySpawner.load_pool(_pool_path)

	var builder := GraphBuilder.new()
	rooms = builder.build_boss_rush(floor_seed, floor_index) if run_mode == "boss_rush" else builder.build(floor_seed, floor_index)
	var errors := FloorValidator.validate(rooms)
	print("Floor %d (seed %d, mode %s): %d rooms | validation: %s" % [
		floor_index, floor_seed, run_mode, rooms.size(), "OK" if errors.is_empty() else str(errors),
	])
	_enter_room(_entrance(), -1)

func _remember_boss_variant(variant_id: String) -> void:
	var clean := variant_id.strip_edges()
	if clean == "":
		return
	if not _recent_boss_variants.is_empty() and _recent_boss_variants.back() == clean:
		return
	_recent_boss_variants.append(clean)
	while _recent_boss_variants.size() > 3:
		_recent_boss_variants.remove_at(0)


func _entrance() -> RoomNode:
	for r in rooms:
		if r.type == RoomNode.RoomType.ENTRANCE:
			return r
	return rooms[0]


## Door transition check: once the room is cleared, standing on a door tile
## moves the player to the room on the other side of that door.
func _physics_process(_delta: float) -> void:
	if _renderer == null or _grid == null or _transitioning:
		return
	if not _renderer.is_cleared:
		return
	var tile := _renderer.world_to_tile(_player.global_position)
	if not _grid.in_bounds(tile.x, tile.y):
		return
	if _grid.get_tile(tile.x, tile.y) != TileGrid.Tile.DOOR:
		return
	var dir := RoomStamper.dir_of_door_tile(_grid, tile)
	if current_room.door_map.has(dir):
		if _current_room_reward_blocks_transition():
			_show_reward_door_blocked_feedback()
			return
		_transitioning = true
		# Deferred: never free the renderer mid-physics-step.
		_enter_room.call_deferred(rooms[current_room.door_map[dir]], current_room.id)


func _enter_room(room: RoomNode, from_room_id: int) -> void:
	if _renderer != null:
		_renderer.queue_free()
	current_room = room
	_record_room_mastery_start(room)

	var rng := SeededRNG.new(floor_seed, 1000 + room.id)
	var door_dirs: Array[int] = []
	for d in room.door_map.keys():
		door_dirs.append(d)
	door_dirs.sort()  # stable carving order regardless of dict iteration
	_grid = _stamper.stamp(room, rng, door_dirs)

	# Which door leads back to the room we came from?
	var entry_dir := -1
	for d in room.door_map.keys():
		if room.door_map[d] == from_room_id:
			entry_dir = d
	var center_tile := Vector2i(_grid.width / 2, _grid.height / 2)
	var entry_tile := center_tile
	if entry_dir != -1:
		var tiles := RoomStamper.door_tiles(_grid, entry_dir)
		if not tiles.is_empty():
			entry_tile = tiles[0]

	var plan: Array[Dictionary] = []
	if not cleared_rooms.has(room.id):
		plan = _spawner.roll_spawn_plan(
			room, _grid, rng, floor_index,
			effective_difficulty_multiplier(),
			_pool, entry_tile)

	_renderer = RoomRenderer.new()
	add_child(_renderer)
	move_child(_renderer, 0)
	# Connect BEFORE setup: empty-plan rooms emit room_cleared during setup.
	_renderer.room_cleared.connect(_on_room_cleared.bind(room))
	_renderer.shop_choice_requested.connect(_on_shop_choice_requested)
	_renderer.interactable_completed.connect(_on_interactable_completed.bind(room))
	_renderer.loot_pity_changed.connect(_on_loot_pity_changed)
	if _renderer.has_signal("boss_phase_changed"):
		_renderer.connect("boss_phase_changed", func(status: Dictionary) -> void:
			boss_phase_changed.emit(status))
	if _renderer.has_signal("boss_attack_cued"):
		_renderer.connect("boss_attack_cued", func(status: Dictionary) -> void:
			boss_attack_cued.emit(status))
	if _renderer.has_signal("route_choice_requested"):
		_renderer.connect("route_choice_requested", func(choice_index: int) -> void:
			route_choice_requested.emit(choice_index))
	if _renderer.has_signal("objective_context_changed"):
		_renderer.connect("objective_context_changed", func(_context: Dictionary) -> void:
			state_changed.emit())
	if _renderer.has_signal("trap_room_survived"):
		_renderer.connect("trap_room_survived", func() -> void:
			_on_trap_room_survived(room))
	var room_affix := RoomAffixDBScript.roll_for_room(room.type, floor_seed, room.id, floor_index)
	_renderer.setup(_grid, plan, ENEMY_SCENE, _player, room.type, room_affix,
		current_biome, loot_pity_rooms_without_rare_plus, {
			"interactables_claimed": interactable_claimed_rooms.has(room.id),
			"trap_room_survived": trap_room_survived_rooms.has(room.id),
		})
	_player.configure_camera_for_room(Rect2(
		Vector2.ZERO,
		Vector2(_grid.width, _grid.height) * RoomRenderer.TILE
	))

	var center := _renderer.tile_to_world(center_tile)
	if entry_dir != -1:
		var door_pos := _renderer.tile_to_world(entry_tile)
		_player.global_position = door_pos + door_pos.direction_to(center) * ENTER_OFFSET
	else:
		_player.global_position = center

	# Re-entering an already-cleared boss room: the portal must still be there.
	if room.type == RoomNode.RoomType.BOSS and cleared_rooms.has(room.id):
		_spawn_exit_portal()

	_transitioning = false
	_record_room_visit(room)
	state_changed.emit()
	print("Entered room %02d (%s) | doors: %s" % [room.id, room.type_name(), room.door_map])


func _on_room_cleared(room: RoomNode) -> void:
	if cleared_rooms.has(room.id):
		return
	cleared_rooms[room.id] = true
	var mastery_context := _record_room_mastery_clear(room)
	_show_door_markers(room)
	state_changed.emit()
	room_objective_completed.emit(room_objective_completed_text(room))
	if not mastery_context.is_empty():
		room_mastery_awarded.emit(mastery_context)
	if rewards_room_type(room.type):
		room_reward_pending.emit(room.id, room.type)
	if room.type == RoomNode.RoomType.BOSS:
		print("Boss down! Exit portal opened (%d/%d rooms visited)" % [
			cleared_rooms.size(), rooms.size(),
		])
		_spawn_exit_portal()

func _on_shop_choice_requested(shop: RoomInteractable, choices: Array) -> void:
	shop_choice_requested.emit(shop, choices)

func _on_interactable_completed(_kind: String, _payload: Dictionary, room: RoomNode) -> void:
	if room != null:
		interactable_claimed_rooms[room.id] = true

func _on_trap_room_survived(room: RoomNode) -> void:
	if room == null:
		return
	trap_room_survived_rooms[room.id] = true
	state_changed.emit()

func _on_loot_pity_changed(rooms_without_rare_plus: int) -> void:
	loot_pity_rooms_without_rare_plus = rooms_without_rare_plus

func loot_pity_threshold() -> int:
	if _loot_pity_threshold_cache <= 0:
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOOT_TABLE_PATH))
		var cfg: Dictionary = data if data is Dictionary else {}
		var pity: Dictionary = cfg.get("pity", {})
		_loot_pity_threshold_cache = maxi(1, int(pity.get("rooms_without_rare_plus", 10)))
	return _loot_pity_threshold_cache

func loot_pity_summary() -> String:
	var threshold := loot_pity_threshold()
	if loot_pity_rooms_without_rare_plus >= threshold:
		return "Rare+ guaranteed next drop"
	return "Rare pity: %d/%d" % [
		mini(maxi(loot_pity_rooms_without_rare_plus, 0), threshold),
		threshold,
	]

static func rewards_room_type(room_type: int) -> bool:
	return room_type == RoomNode.RoomType.COMBAT \
		or room_type == RoomNode.RoomType.ELITE \
		or room_type == RoomNode.RoomType.MINIBOSS \
		or room_type == RoomNode.RoomType.BOSS \
		or room_type == RoomNode.RoomType.EVENT \
		or room_type == RoomNode.RoomType.TREASURE \
		or room_type == RoomNode.RoomType.SECRET

static func daily_seed_fingerprint(
		p_seed: int,
		p_floor_index: int,
		p_run_mode: String = "normal",
		recent_bosses: Array = [],
		boss_variant_override: String = "",
) -> Dictionary:
	var mode := _normalized_run_mode_value(p_run_mode)
	var biome := BiomeDBScript.floor_biome(p_floor_index)
	var boss_variant := boss_variant_override.strip_edges()
	if boss_variant == "":
		boss_variant = BiomeDBScript.boss_variant_for_run(
			biome, p_seed, p_floor_index, recent_bosses)
	biome["boss_variant"] = boss_variant
	var builder := GraphBuilder.new()
	var floor_rooms := builder.build_boss_rush(p_seed, p_floor_index) \
		if mode == "boss_rush" else builder.build(p_seed, p_floor_index)
	var stamper := RoomStamper.new()
	var spawner := EnemySpawner.new()
	var pool_path := BiomeDBScript.enemy_pool_path(biome)
	if pool_path == "":
		pool_path = ENEMY_POOL_PATH
	var pool := EnemySpawner.load_pool(pool_path)
	var difficulty := _run_difficulty_multiplier_value(mode, p_floor_index) \
		* float(biome.get("difficulty_mult", 1.0))
	var room_entries: Array[Dictionary] = []
	var spawn_room_count := 0
	var spawn_count := 0
	for room in floor_rooms:
		var rng := SeededRNG.new(p_seed, 1000 + room.id)
		var door_dirs := _sorted_ints(room.door_map.keys())
		var stamped := stamper.stamp(room, rng, door_dirs)
		var entry_tile := _fingerprint_entry_tile(room, stamped)
		var plan := spawner.roll_spawn_plan(
			room, stamped, rng, p_floor_index, difficulty, pool, entry_tile)
		if not plan.is_empty():
			spawn_room_count += 1
			spawn_count += plan.size()
		room_entries.append({
			"id": room.id,
			"type": room.type_name(),
			"type_id": room.type,
			"depth": room.depth,
			"critical": room.on_critical_path,
			"neighbors": _sorted_ints(room.neighbors),
			"doors": _door_fingerprint(room.door_map),
			"entry_tile": [entry_tile.x, entry_tile.y],
			"grid": _grid_fingerprint(stamped),
			"spawns": _spawn_fingerprint(plan),
		})
	var body := {
		"seed": p_seed,
		"floor_index": p_floor_index,
		"mode": mode,
		"biome_id": str(biome.get("id", "")),
		"biome_name": str(biome.get("name", "")),
		"boss_variant": boss_variant,
		"room_count": floor_rooms.size(),
		"spawn_room_count": spawn_room_count,
		"spawn_count": spawn_count,
		"rooms": room_entries,
	}
	body["hash"] = str(JSON.stringify(body).hash())
	return body

func current_floor_fingerprint() -> Dictionary:
	if floor_seed <= 0 or floor_index <= 0:
		return {}
	return daily_seed_fingerprint(
		floor_seed,
		floor_index,
		run_mode,
		[],
		str(current_biome.get("boss_variant", "")))

func mark_room_reward_claimed(room_id: int) -> void:
	if room_id < 0:
		return
	reward_claimed_rooms[room_id] = true
	if current_room != null and current_room.id == room_id:
		_clear_reward_door_blocked_feedback()
		_show_door_markers(current_room)
		_show_reward_door_open_feedback()
	state_changed.emit()

func room_objective_completed_text(room: RoomNode) -> String:
	if room == null:
		return "Objective complete"
	var type_keys := RoomNode.RoomType.keys()
	var room_name := str(type_keys[room.type]) if room.type >= 0 and room.type < type_keys.size() else "ROOM"
	var reward_text := "Reward ready" if rewards_room_type(room.type) else "Doors open"
	if room.type == RoomNode.RoomType.BOSS:
		if _is_run_finale_floor():
			return "FINAL BOSS complete | Run complete portal ready"
		reward_text = "Reward + portal ready"
	return "%s complete | %s" % [room_name, reward_text]


func _show_door_markers(room: RoomNode) -> void:
	if _renderer == null:
		return
	var door_targets := {}
	var reward_locked := _current_room_reward_blocks_transition()
	var dirs := room.door_map.keys()
	dirs.sort()
	var choice_index := 1
	for dir in dirs:
		var target_id := int(room.door_map[dir])
		if target_id >= 0 and target_id < rooms.size():
			var target := rooms[target_id]
			var marker_context := {
				"type": target.type,
				"route": "MAIN" if target.on_critical_path else "SIDE",
				"preview": _door_marker_preview(target),
				"choice_index": choice_index,
				"input_action": "route_choice_%d" % choice_index,
			}
			if reward_locked:
				marker_context["state"] = "reward_locked"
				marker_context["next_action_key"] = "reward"
			door_targets[int(dir)] = marker_context
			choice_index += 1
	_renderer.show_door_markers(door_targets)

func _door_marker_preview(room: RoomNode) -> String:
	if room == null:
		return ""
	match room.type:
		RoomNode.RoomType.COMBAT:
			return "UPG"
		RoomNode.RoomType.ELITE, RoomNode.RoomType.MINIBOSS, RoomNode.RoomType.BOSS:
			return "R+"
		RoomNode.RoomType.TREASURE:
			return "CHEST"
		RoomNode.RoomType.SHOP:
			return "3 BUY"
		RoomNode.RoomType.HEAL:
			return "HP"
		RoomNode.RoomType.SHRINE:
			return "ALTAR"
		RoomNode.RoomType.EVENT:
			return "TRAP"
		RoomNode.RoomType.SECRET:
			return "CACHE"
	return ""

func current_room_route_options_summary(max_options: int = 4) -> String:
	var options := current_room_route_options(max_options)
	if options.is_empty():
		return ""
	var parts: Array[String] = []
	for option in options:
		parts.append(str(option.get("summary", "")))
	var extra := current_room.door_map.size() - parts.size()
	var summary := "Choices: %s" % " | ".join(parts)
	if extra > 0:
		summary += " (+%d)" % extra
	if _current_room_reward_blocks_transition():
		summary += " | Pick reward first"
	return summary

func current_room_route_options(max_options: int = 4) -> Array[Dictionary]:
	if current_room == null or current_room.door_map.is_empty():
		return []
	var dirs := current_room.door_map.keys()
	dirs.sort()
	var options: Array[Dictionary] = []
	for dir in dirs:
		if options.size() >= maxi(max_options, 1):
			break
		var target_id := int(current_room.door_map[dir])
		if target_id < 0 or target_id >= rooms.size():
			continue
		var target := rooms[target_id]
		if target == null:
			continue
		var route_label := "MAIN" if target.on_critical_path else "SIDE"
		var route_role := "main" if target.on_critical_path else "side"
		var type_name := target.type_name()
		var preview := _door_marker_preview(target)
		var compact := "%s %s%s" % [
			route_label,
			type_name,
			" %s" % preview if preview != "" else "",
		]
		options.append({
			"choice_index": options.size() + 1,
			"door_dir": int(dir),
			"room_id": target.id,
			"room_depth": target.depth,
			"room_type": target.type,
			"room_type_name": type_name,
			"route_label": route_label,
			"route_role": route_role,
			"on_critical_path": target.on_critical_path,
			"reward_preview": preview,
			"summary": compact,
		})
	return options

func choose_current_route(choice_index: int, request_source: String = "hotkey") -> Dictionary:
	var result := _route_choice_result(choice_index, false, "not_ready", request_source)
	if _transitioning:
		result["blocked_reason"] = "transitioning"
		return _store_route_choice_result(result)
	if current_room == null:
		result["blocked_reason"] = "missing_current_room"
		return _store_route_choice_result(result)
	if _renderer == null or not bool(_renderer.get("is_cleared")):
		result["blocked_reason"] = "room_locked"
		return _store_route_choice_result(result)
	if _current_room_reward_blocks_transition():
		_show_reward_door_blocked_feedback()
		result["blocked_reason"] = "reward_unclaimed"
		return _store_route_choice_result(result)
	var options := current_room_route_options()
	if choice_index < 1 or choice_index > options.size():
		result["blocked_reason"] = "invalid_choice"
		result["option_count"] = options.size()
		return _store_route_choice_result(result)
	var option := options[choice_index - 1]
	var target_id := int(option.get("room_id", -1))
	if target_id < 0 or target_id >= rooms.size():
		result["blocked_reason"] = "missing_target_room"
		return _store_route_choice_result(result)
	var target := rooms[target_id]
	if target == null:
		result["blocked_reason"] = "missing_target_room"
		return _store_route_choice_result(result)
	result = _route_choice_result(choice_index, true, "", request_source)
	for key in option.keys():
		result[str(key)] = option[key]
	result["from_room_id"] = current_room.id
	result["to_room_id"] = target.id
	_transitioning = true
	_store_route_choice_result(result)
	_enter_room.call_deferred(target, current_room.id)
	return result

func _route_choice_result(
		choice_index: int,
		accepted: bool,
		blocked_reason: String,
		request_source: String = "",
) -> Dictionary:
	return {
		"choice_index": choice_index,
		"accepted": accepted,
		"blocked_reason": blocked_reason,
		"request_source": request_source,
	}

func _store_route_choice_result(result: Dictionary) -> Dictionary:
	set_meta("last_route_choice_result", result.duplicate(true))
	return result


func _spawn_exit_portal() -> void:
	var portal := ExitPortal.new()
	portal.configure(_player, _is_run_finale_floor())
	portal.position = _renderer.tile_to_world(Vector2i(_grid.width / 2, _grid.height / 2))
	portal.entered.connect(func() -> void: floor_completed.emit())
	_renderer.add_child(portal)

func current_room_label() -> String:
	if current_room == null:
		return "-"
	var label := current_room.type_name()
	if _renderer != null and _renderer.has_method("room_affix_name"):
		var affix_name := str(_renderer.call("room_affix_name"))
		if affix_name != "":
			label = "%s / %s" % [label, affix_name]
	return label

func current_biome_label() -> String:
	return str(current_biome.get("name", "-"))

func effective_difficulty_multiplier() -> float:
	return difficulty_mult * float(current_biome.get("difficulty_mult", 1.0)) \
		* run_modifier_difficulty_multiplier()

func current_difficulty_label() -> String:
	return "x%.2f" % effective_difficulty_multiplier()

func floor_spawn_budget_multiplier() -> float:
	return 1.0 + 0.25 * float(maxi(floor_index, 0))

func current_threat_multiplier() -> float:
	return effective_difficulty_multiplier() * floor_spawn_budget_multiplier()

func current_threat_label() -> String:
	return "Threat x%.2f" % current_threat_multiplier()

func set_run_modifier(modifier: Dictionary) -> void:
	run_modifier = modifier.duplicate(true)

func _apply_run_modifier_to_biome(biome: Dictionary) -> Dictionary:
	var out := biome.duplicate(true)
	var patch: Dictionary = run_modifier.get("boss_tuning_patch", {})
	if not bool(patch.get("enabled", false)):
		return out
	var patch_biome := str(patch.get("biome", "")).strip_edges()
	var biome_id := str(out.get("id", "")).strip_edges()
	if patch_biome != "" and patch_biome != biome_id:
		return out
	out["boss_tuning_patch"] = patch.duplicate(true)
	var patch_variant := str(patch.get("boss_variant", "")).strip_edges()
	if patch_variant != "":
		out["boss_variant"] = patch_variant
	out["balance_experiment_active"] = true
	return out

func run_modifier_difficulty_multiplier() -> float:
	return maxf(float(run_modifier.get("difficulty_mult", 1.0)), 0.1)

func cleared_room_count() -> int:
	return cleared_rooms.size()

func total_room_count() -> int:
	return rooms.size()

func _record_room_mastery_start(room: RoomNode) -> void:
	if room == null or cleared_rooms.has(room.id):
		return
	_room_enter_ticks_msec[room.id] = Time.get_ticks_msec()
	if _player == null:
		return
	_room_enter_hp[room.id] = {
		"hp": int(_player.hp),
		"max_hp": int(_player.max_hp),
		"damage_taken_total": _player_damage_taken_total(),
	}

func _record_room_mastery_clear(room: RoomNode) -> Dictionary:
	if room == null:
		return {}
	var now_ticks := Time.get_ticks_msec()
	var enter_ticks := int(_room_enter_ticks_msec.get(room.id, now_ticks))
	var clear_time_sec := maxf(0.0, float(now_ticks - enter_ticks) / 1000.0)
	var pace_target := _pace_target_for_room_type(room.type)
	var pace_rating := _pace_rating(clear_time_sec, pace_target)
	var start: Dictionary = _room_enter_hp.get(room.id, {})
	var start_hp := int(start.get("hp", _player.hp if _player != null else 0))
	var max_hp := int(start.get("max_hp", _player.max_hp if _player != null else start_hp))
	var clear_hp := int(_player.hp if _player != null else start_hp)
	max_hp = maxi(max_hp, 1)
	var hp_damage_taken := maxi(0, start_hp - clear_hp)
	var damage_delta := maxi(
		0, _player_damage_taken_total() - int(start.get("damage_taken_total", 0)))
	var damage_taken := maxi(hp_damage_taken, damage_delta)
	var perfect_clear := damage_taken <= 0
	var close_call := float(clear_hp) / float(max_hp) <= 0.3
	var reward_room := rewards_room_type(room.type)
	var critical_path := bool(room.on_critical_path)
	var badges: Array[String] = []
	if perfect_clear:
		badges.append("Perfect")
	if close_call:
		badges.append("Close Call")
	if critical_path:
		badges.append("Critical Path")
	if reward_room:
		badges.append("Reward")
	if badges.is_empty():
		badges.append("Clear")
	var context := {
		"room_id": room.id,
		"room_type": room.type,
		"room_type_name": _room_type_label(room),
		"start_hp": start_hp,
		"clear_hp": clear_hp,
		"max_hp": max_hp,
		"damage_taken": damage_taken,
		"clear_time_sec": clear_time_sec,
		"pace_target_sec": pace_target,
		"pace_rating": pace_rating,
		"boss_room": room.type == RoomNode.RoomType.BOSS,
		"perfect_clear": perfect_clear,
		"close_call": close_call,
		"critical_path": critical_path,
		"reward_room": reward_room,
		"badges": badges,
		"summary": " | ".join(badges),
	}
	room_mastery[room.id] = context
	return context

func room_mastery_context(room_id: int = -1) -> Dictionary:
	var target_id := room_id
	if target_id < 0 and current_room != null:
		target_id = current_room.id
	var context: Dictionary = room_mastery.get(target_id, {})
	return context.duplicate(true)

func room_mastery_summary() -> String:
	if room_mastery.is_empty():
		return ""
	var perfect_count := 0
	var close_call_count := 0
	var critical_count := 0
	var reward_count := 0
	var clear_count := 0
	for context in room_mastery.values():
		if not (context is Dictionary):
			continue
		clear_count += 1
		if bool(context.get("perfect_clear", false)):
			perfect_count += 1
		if bool(context.get("close_call", false)):
			close_call_count += 1
		if bool(context.get("critical_path", false)):
			critical_count += 1
		if bool(context.get("reward_room", false)):
			reward_count += 1
	var parts: Array[String] = []
	if perfect_count > 0:
		parts.append("Perfect %d" % perfect_count)
	if close_call_count > 0:
		parts.append("Close Call %d" % close_call_count)
	if critical_count > 0:
		parts.append("Critical Path %d" % critical_count)
	if reward_count > 0:
		parts.append("Reward Rooms %d" % reward_count)
	if parts.is_empty():
		parts.append("Clears %d" % clear_count)
	return " | ".join(parts)

func room_timing_context() -> Dictionary:
	if room_mastery.is_empty():
		return {}
	var total := 0.0
	var timed_count := 0
	var boss_time := -1.0
	var slowest_time := -1.0
	var slowest_label := ""
	var fast_count := 0
	var target_count := 0
	var slow_count := 0
	for context in room_mastery.values():
		if not (context is Dictionary):
			continue
		var data := context as Dictionary
		var time_sec := float(data.get("clear_time_sec", -1.0))
		if time_sec < 0.0:
			continue
		timed_count += 1
		total += time_sec
		if bool(data.get("boss_room", false)):
			boss_time = time_sec
		if time_sec >= slowest_time:
			slowest_time = time_sec
			slowest_label = str(data.get("room_type_name", "Room"))
		match str(data.get("pace_rating", "")).to_lower():
			"fast":
				fast_count += 1
			"target":
				target_count += 1
			"slow":
				slow_count += 1
	if timed_count <= 0:
		return {}
	return {
		"timed_room_count": timed_count,
		"avg_clear_time_sec": total / float(timed_count),
		"boss_clear_time_sec": boss_time,
		"slowest_clear_time_sec": slowest_time,
		"slowest_room_type_name": slowest_label,
		"fast_room_count": fast_count,
		"target_room_count": target_count,
		"slow_room_count": slow_count,
	}

func room_timing_summary() -> String:
	var timing := room_timing_context()
	if timing.is_empty():
		return ""
	var parts: Array[String] = ["Avg %.1fs" % float(timing.get("avg_clear_time_sec", 0.0))]
	var boss_time := float(timing.get("boss_clear_time_sec", -1.0))
	if boss_time >= 0.0:
		parts.append("Boss %.1fs" % boss_time)
	var slowest_time := float(timing.get("slowest_clear_time_sec", -1.0))
	if slowest_time >= 0.0:
		var slowest_label := str(timing.get("slowest_room_type_name", "")).strip_edges()
		parts.append("Slowest %s %.1fs" % [
			slowest_label if slowest_label != "" else "Room",
			slowest_time,
		])
	var fast_count := int(timing.get("fast_room_count", 0))
	if fast_count > 0:
		parts.append("Fast %d" % fast_count)
	var target_count := int(timing.get("target_room_count", 0))
	if target_count > 0:
		parts.append("Target %d" % target_count)
	var slow_count := int(timing.get("slow_room_count", 0))
	if slow_count > 0:
		parts.append("Slow %d" % slow_count)
	return " | ".join(parts)

func _player_damage_taken_total() -> int:
	if _player == null:
		return 0
	if _player.has_method("total_damage_taken"):
		return maxi(int(_player.call("total_damage_taken")), 0)
	var raw: Variant = _player.get("damage_taken")
	return maxi(int(raw), 0) if raw != null else 0

func _pace_target_for_room_type(room_type: int) -> Vector2:
	match room_type:
		RoomNode.RoomType.BOSS:
			return Vector2(120.0, 240.0)
		RoomNode.RoomType.MINIBOSS:
			return Vector2(45.0, 120.0)
		RoomNode.RoomType.ELITE:
			return Vector2(20.0, 75.0)
		RoomNode.RoomType.COMBAT:
			return Vector2(8.0, 35.0)
		RoomNode.RoomType.EVENT:
			return Vector2(8.0, 40.0)
		RoomNode.RoomType.TREASURE, RoomNode.RoomType.SECRET:
			return Vector2(2.0, 20.0)
		RoomNode.RoomType.SHOP, RoomNode.RoomType.HEAL, RoomNode.RoomType.SHRINE, \
				RoomNode.RoomType.ENTRANCE:
			return Vector2(1.0, 18.0)
	return Vector2(8.0, 35.0)

func _pace_rating(clear_time_sec: float, target: Vector2) -> String:
	if clear_time_sec < target.x:
		return "fast"
	if clear_time_sec > target.y:
		return "slow"
	return "target"

func _record_room_visit(room: RoomNode) -> void:
	if room == null:
		return
	visited_rooms[room.id] = true
	if not _visited_room_order.has(room.id):
		_visited_room_order.append(room.id)

func visited_room_path_summary(max_rooms: int = 8) -> String:
	var ids := _visited_ids_for_summary()
	if ids.is_empty():
		return "Path: -"
	var labels: Array[String] = []
	var visible_count := mini(maxi(max_rooms, 1), ids.size())
	for i in visible_count:
		labels.append(_room_type_label(_room_by_id(int(ids[i]))))
	var extra := ids.size() - visible_count
	var text := "Path: %s" % " -> ".join(labels)
	if extra > 0:
		text += " (+%d)" % extra
	return text

func _visited_ids_for_summary() -> Array[int]:
	var ids: Array[int] = []
	for room_id in _visited_room_order:
		if visited_rooms.has(room_id) and not ids.has(room_id):
			ids.append(room_id)
	if not ids.is_empty():
		return ids
	for room in rooms:
		if room != null and visited_rooms.has(room.id):
			ids.append(room.id)
	return ids

func _room_by_id(room_id: int) -> RoomNode:
	for room in rooms:
		if room != null and room.id == room_id:
			return room
	return null

func _room_type_label(room: RoomNode) -> String:
	if room == null:
		return "Room"
	var keys := RoomNode.RoomType.keys()
	if room.type >= 0 and room.type < keys.size():
		return str(keys[room.type]).to_lower().capitalize()
	return "Room"

func current_boss_status() -> Dictionary:
	if _renderer == null or not _renderer.has_method("boss_status"):
		return {}
	return _renderer.call("boss_status")

func current_room_objective() -> String:
	if current_room == null:
		return "-"
	var cleared := cleared_rooms.has(current_room.id)
	if cleared and _current_room_reward_claimed() and rewards_room_type(current_room.type):
		if current_room.type == RoomNode.RoomType.BOSS:
			if _is_run_finale_floor():
				return "Final boss reward claimed | Enter run complete portal"
			return "Boss reward claimed | Enter exit portal"
		return "Reward claimed | Doors open"
	match current_room.type:
		RoomNode.RoomType.COMBAT:
			return "Clear room | Choose reward"
		RoomNode.RoomType.ELITE:
			return "Elite fight | Rare+ reward"
		RoomNode.RoomType.MINIBOSS:
			return "Miniboss fight | Rare+ reward"
		RoomNode.RoomType.TREASURE:
			return "Open chest"
		RoomNode.RoomType.HEAL:
			return "Use heal shrine"
		RoomNode.RoomType.SHRINE:
			return "Use elemental altar"
		RoomNode.RoomType.SHOP:
			return "Choose 1 shop item"
		RoomNode.RoomType.EVENT:
			return "Survive traps"
		RoomNode.RoomType.SECRET:
			return "Open secret cache"
		RoomNode.RoomType.BOSS:
			if run_mode == "boss_rush":
				var chain := "Chain %d/%d" % [floor_index, BOSS_RUSH_CHAIN_FLOORS]
				var finale := floor_index >= BOSS_RUSH_CHAIN_FLOORS
				if cleared_rooms.has(current_room.id):
					if finale:
						return "Boss Rush final reward ready | %s | Enter run complete portal" % chain
					return "Boss Rush reward ready | %s | Enter exit portal" % chain
				if finale:
					return "Boss Rush: Defeat final boss | %s" % chain
				return "Boss Rush: Defeat boss | %s" % chain
			if run_mode == "endless":
				if cleared_rooms.has(current_room.id):
					return "Endless reward ready | Depth %d | Enter exit portal" % floor_index
				return "Endless: Defeat boss | Depth %d" % floor_index
			if _is_run_finale_floor():
				if cleared_rooms.has(current_room.id):
					return "Final boss reward ready | Enter run complete portal"
				return "Defeat final boss"
			if cleared_rooms.has(current_room.id):
				return "Boss reward ready | Enter exit portal"
			return "Defeat boss"
		RoomNode.RoomType.ENTRANCE:
			return "Pick a door"
		_:
			return "Clear room"

func current_room_next_action() -> String:
	if current_room == null:
		return ""
	var cleared := cleared_rooms.has(current_room.id)
	if cleared:
		if current_room.type == RoomNode.RoomType.BOSS:
			if _is_run_finale_floor():
				return "Next: Enter run complete portal" if _current_room_reward_claimed() \
					else "Next: Pick reward, then enter run complete portal"
			return "Next: Enter exit portal" if _current_room_reward_claimed() \
				else "Next: Pick reward, then enter portal"
		if rewards_room_type(current_room.type):
			if _current_room_reward_claimed():
				return "Next: Move to a door"
			return "Next: Pick 1 upgrade"
		return "Next: Move to a door"
	match current_room.type:
		RoomNode.RoomType.COMBAT:
			return "Next: Defeat all enemies"
		RoomNode.RoomType.ELITE:
			return "Next: Defeat elite"
		RoomNode.RoomType.MINIBOSS:
			return "Next: Defeat miniboss"
		RoomNode.RoomType.TREASURE:
			return "Next: Open chest, then pick 1 upgrade"
		RoomNode.RoomType.HEAL:
			return "Next: Use heal shrine once"
		RoomNode.RoomType.SHRINE:
			return "Next: Use elemental altar"
		RoomNode.RoomType.SHOP:
			return "Next: Open shop, choose 1 of 3 or leave"
		RoomNode.RoomType.EVENT:
			return "Next: Survive traps, open cache"
		RoomNode.RoomType.SECRET:
			return "Next: Open secret cache"
		RoomNode.RoomType.BOSS:
			return "Next: Defeat boss"
		RoomNode.RoomType.ENTRANCE:
			return "Next: Choose a door"
		_:
			return "Next: Clear room"

func current_room_next_action_key() -> String:
	if current_room == null:
		return "none"
	var cleared := cleared_rooms.has(current_room.id)
	if cleared:
		if current_room.type == RoomNode.RoomType.BOSS:
			return "portal"
		if rewards_room_type(current_room.type):
			return "door" if _current_room_reward_claimed() else "reward"
		return "door"
	match current_room.type:
		RoomNode.RoomType.COMBAT, RoomNode.RoomType.ELITE, RoomNode.RoomType.MINIBOSS:
			return "combat"
		RoomNode.RoomType.BOSS:
			return "boss"
		RoomNode.RoomType.SHOP:
			return "shop"
		RoomNode.RoomType.ENTRANCE:
			return "door"
		RoomNode.RoomType.TREASURE, RoomNode.RoomType.HEAL, RoomNode.RoomType.SHRINE, \
				RoomNode.RoomType.EVENT, RoomNode.RoomType.SECRET:
			return "interact"
		_:
			return "combat"

func current_room_objective_context() -> Dictionary:
	if current_room == null:
		return {
			"room_id": -1,
			"room_type": -1,
			"room_type_name": "NONE",
			"cleared": false,
			"reward_room": false,
			"reward_ready": false,
			"objective_state": "none",
			"objective_text": current_room_objective(),
			"next_action_text": current_room_next_action(),
			"next_action_key": current_room_next_action_key(),
			"next_action_chain": "none",
			"next_action_priority": "none",
			"completion_text": "Objective complete",
			"run_finale": false,
		}
	var type_keys := RoomNode.RoomType.keys()
	var type_name := str(type_keys[current_room.type]) \
		if current_room.type >= 0 and current_room.type < type_keys.size() else "ROOM"
	var cleared := cleared_rooms.has(current_room.id)
	var reward_room := rewards_room_type(current_room.type)
	var reward_claimed := cleared and reward_room and _current_room_reward_claimed()
	var reward_ready := cleared and reward_room and not reward_claimed
	var objective_state := "reward_claimed" if reward_claimed \
		else ("reward_ready" if reward_ready else ("cleared" if cleared else "active"))
	var context := {
		"room_id": current_room.id,
		"room_type": current_room.type,
		"room_type_name": type_name,
		"cleared": cleared,
		"reward_room": reward_room,
		"reward_ready": reward_ready,
		"objective_state": objective_state,
		"objective_text": current_room_objective(),
		"next_action_text": current_room_next_action(),
		"next_action_key": current_room_next_action_key(),
		"next_action_chain": current_room_next_action_chain(),
		"next_action_priority": current_room_next_action_priority(),
		"completion_text": room_objective_completed_text(current_room),
		"run_finale": _is_run_finale_floor(),
	}
	var live_context := _current_renderer_live_objective_context()
	for key in live_context.keys():
		context[str(key)] = live_context[key]
	return context

func _current_renderer_live_objective_context() -> Dictionary:
	if _renderer == null or not is_instance_valid(_renderer) \
			or not _renderer.has_method("live_objective_context"):
		return {}
	var context = _renderer.call("live_objective_context")
	return context if context is Dictionary else {}

func current_room_next_action_chain() -> String:
	if current_room == null:
		return "none"
	if _current_room_reward_claimed():
		if current_room.type == RoomNode.RoomType.BOSS:
			return "portal"
		if rewards_room_type(current_room.type):
			return "door"
	if cleared_rooms.has(current_room.id) and current_room.type == RoomNode.RoomType.BOSS:
		return "reward -> portal"
	return current_room_next_action_key()

func current_room_next_action_priority() -> String:
	var chain := current_room_next_action_chain()
	if chain.contains(" -> "):
		return str(chain.split(" -> ", false)[0])
	return chain

func _current_room_reward_claimed() -> bool:
	return current_room != null and reward_claimed_rooms.has(current_room.id)

func _current_room_reward_blocks_transition() -> bool:
	return current_room != null \
		and cleared_rooms.has(current_room.id) \
		and rewards_room_type(current_room.type) \
		and not _current_room_reward_claimed()

func _show_reward_door_blocked_feedback() -> void:
	if _renderer == null or _player == null:
		return
	var label := _renderer.get_node_or_null("RewardDoorBlockedHint") as Label
	if label == null:
		label = Label.new()
		label.name = "RewardDoorBlockedHint"
		label.z_index = 30
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
		_renderer.add_child(label)
	label.text = "Pick reward first"
	label.position = _player.global_position + Vector2(-38, -24)
	label.modulate.a = 1.0
	label.set_meta("blocked_reason", "reward_unclaimed")
	label.set_meta("room_id", current_room.id if current_room != null else -1)
	label.set_meta("room_type", current_room.type if current_room != null else -1)
	label.set_meta("next_action_key", "reward")
	_play_reward_door_blocked_sfx()
	if is_inside_tree():
		var tween := label.create_tween()
		tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
		tween.parallel().tween_property(label, "modulate:a", 0.35, 0.45)

func _clear_reward_door_blocked_feedback() -> void:
	if _renderer == null:
		return
	var label := _renderer.get_node_or_null("RewardDoorBlockedHint") as Label
	if label != null:
		label.visible = false
		label.queue_free()

func _show_reward_door_open_feedback() -> void:
	if _renderer == null:
		return
	var label := _renderer.get_node_or_null("RewardDoorOpenHint") as Label
	if label == null:
		label = Label.new()
		label.name = "RewardDoorOpenHint"
		label.z_index = 30
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.68))
		_renderer.add_child(label)
	label.text = "Doors open"
	label.position = _reward_feedback_origin() + Vector2(-28, -24)
	label.modulate.a = 1.0
	label.set_meta("reward_open_reason", "reward_claimed")
	label.set_meta("objective_state", "reward_claimed")
	label.set_meta("room_id", current_room.id if current_room != null else -1)
	label.set_meta("room_type", current_room.type if current_room != null else -1)
	label.set_meta("next_action_key", "door")
	_play_reward_door_open_sfx()
	if is_inside_tree():
		var tween := label.create_tween()
		tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.55)
		tween.parallel().tween_property(label, "modulate:a", 0.3, 0.55)

func _reward_feedback_origin() -> Vector2:
	if _player != null and is_instance_valid(_player):
		return _player.global_position
	if _renderer != null and _grid != null:
		return _renderer.tile_to_world(Vector2i(_grid.width / 2, _grid.height / 2))
	return Vector2.ZERO

func _play_reward_door_blocked_sfx() -> void:
	var cue: Dictionary = AudioCueDBScript.objective_blocked_cue("reward_unclaimed")
	var sfx := _renderer.get_node_or_null("RewardDoorBlockedSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "RewardDoorBlockedSfx"
		_renderer.add_child(sfx)
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("reward_blocked_reason", "reward_unclaimed")
	sfx.set_meta("room_id", current_room.id if current_room != null else -1)
	sfx.set_meta("room_type", current_room.type if current_room != null else -1)
	sfx.set_meta("next_action_key", "reward")
	sfx.set_meta("reward_blocked_sound_id", str(cue.get("id", "objective_blocked")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "objective_blocked")))
	sfx.set_meta("reward_blocked_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _play_reward_door_open_sfx() -> void:
	var cue: Dictionary = AudioCueDBScript.objective_complete_cue("Doors open")
	var sfx := _renderer.get_node_or_null("RewardDoorOpenSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "RewardDoorOpenSfx"
		_renderer.add_child(sfx)
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("reward_open_reason", "reward_claimed")
	sfx.set_meta("room_id", current_room.id if current_room != null else -1)
	sfx.set_meta("room_type", current_room.type if current_room != null else -1)
	sfx.set_meta("next_action_key", "door")
	sfx.set_meta("reward_open_sound_id", str(cue.get("id", "objective_complete")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "objective_complete")))
	sfx.set_meta("reward_open_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _is_run_finale_floor() -> bool:
	if run_mode == "boss_rush":
		return floor_index >= BOSS_RUSH_CHAIN_FLOORS
	return bool(current_biome.get("run_finale", false)) \
			and ["normal", "hardcore", "elemental_chaos"].has(run_mode)

func run_difficulty_multiplier(mode: String, p_floor_index: int) -> float:
	return _run_difficulty_multiplier_value(mode, p_floor_index)

static func _run_difficulty_multiplier_value(mode: String, p_floor_index: int) -> float:
	match mode:
		"boss_rush":
			return 1.0 + 0.15 * float(maxi(p_floor_index, 1))
		"endless":
			return 1.0 + 0.10 * float(maxi(p_floor_index - 1, 0))
		"hardcore":
			return 1.08 + 0.04 * float(maxi(p_floor_index, 1))
		"elemental_chaos":
			return 1.04 + 0.03 * float(maxi(p_floor_index, 1))
		_:
			return 1.0

func _normalized_run_mode(mode: String) -> String:
	return _normalized_run_mode_value(mode)

static func _normalized_run_mode_value(mode: String) -> String:
	return mode if ["boss_rush", "endless", "hardcore", "elemental_chaos", "balance_lab"].has(mode) else "normal"

static func _sorted_ints(values: Array) -> Array[int]:
	var out: Array[int] = []
	for value in values:
		out.append(int(value))
	out.sort()
	return out

static func _fingerprint_entry_tile(room: RoomNode, grid: TileGrid) -> Vector2i:
	var parent_id := _fingerprint_parent_room_id(room)
	var entry_dir := -1
	for dir in room.door_map.keys():
		if int(room.door_map[dir]) == parent_id:
			entry_dir = int(dir)
			break
	if entry_dir >= 0:
		var tiles := RoomStamper.door_tiles(grid, entry_dir)
		if not tiles.is_empty():
			return tiles[0]
	return Vector2i(grid.width / 2, grid.height / 2)

static func _fingerprint_parent_room_id(room: RoomNode) -> int:
	if room.on_critical_path and room.depth <= 0:
		return -1
	var parent := 2147483647
	for raw_neighbor in room.neighbors:
		var neighbor := int(raw_neighbor)
		if neighbor < room.id:
			parent = mini(parent, neighbor)
	return -1 if parent == 2147483647 else parent

static func _door_fingerprint(door_map: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for dir in _sorted_ints(door_map.keys()):
		out.append({"dir": dir, "to": int(door_map[dir])})
	return out

static func _grid_fingerprint(grid: TileGrid) -> Dictionary:
	var rows: Array[String] = []
	var doors: Array = []
	for y in grid.height:
		var cells: Array[String] = []
		for x in grid.width:
			var tile := int(grid.get_tile(x, y))
			cells.append(str(tile))
			if tile == TileGrid.Tile.DOOR:
				doors.append([x, y])
		rows.append(",".join(cells))
	return {
		"size": [grid.width, grid.height],
		"doors": doors,
		"rows": rows,
	}

static func _spawn_fingerprint(plan: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for spawn in plan:
		var enemy: Dictionary = spawn.get("enemy", {})
		var tile: Vector2i = spawn.get("tile", Vector2i(-1, -1))
		out.append({
			"enemy_id": str(enemy.get("id", "")),
			"enemy_kind": str(enemy.get("kind", "")),
			"wave": int(spawn.get("wave", 0)),
			"tile": [tile.x, tile.y],
			"elite": bool(spawn.get("elite", false)),
			"modifier": str(spawn.get("modifier", "")),
		})
	return out
