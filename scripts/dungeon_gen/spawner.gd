class_name EnemySpawner
extends RefCounted
## Steps 5 (enemies) of the pipeline: rolls a deterministic spawn plan for a
## room using the budget system from docs/gdd/10-dungeon-gen.md.
##
## Fairness constraints (GDD hard rules):
## - nothing spawns within PLAYER_SAFE_RADIUS tiles of the entry door
## - ranged/caster enemies spawn at least RANGED_MIN_DOOR_DIST tiles away

const BASE_BUDGET := 10.0
const WAVE1_SHARE := 0.6
const PLAYER_SAFE_RADIUS := 3
const RANGED_MIN_DOOR_DIST := 6
const ELITE_BUDGET_MULT := 1.4
const MAX_PICK_GUARD := 50

const COMBAT_ROOM_TYPES: Array[RoomNode.RoomType] = [
	RoomNode.RoomType.COMBAT,
	RoomNode.RoomType.ELITE,
	RoomNode.RoomType.MINIBOSS,
	RoomNode.RoomType.BOSS,
]


static func load_pool(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	assert(data is Dictionary, "EnemySpawner.load_pool: invalid JSON at " + path)
	return data


## Returns entries: { "enemy": Dictionary, "wave": int, "tile": Vector2i,
## "elite": bool, "modifier": String }. Empty for non-combat rooms.
func roll_spawn_plan(
		room: RoomNode,
		grid: TileGrid,
		rng: SeededRNG,
		floor_index: int,
		difficulty_mult: float,
		pool_data: Dictionary,
		entry: Vector2i,
) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	if not COMBAT_ROOM_TYPES.has(room.type):
		return plan

	# Mini-boss / boss rooms spawn their dedicated enemy instead of a wave.
	if room.type == RoomNode.RoomType.MINIBOSS or room.type == RoomNode.RoomType.BOSS:
		var kind := "boss" if room.type == RoomNode.RoomType.BOSS else "miniboss"
		var special := _find_kind(pool_data, kind)
		if not special.is_empty():
			plan.append({
				"enemy": special,
				"wave": 1,
				"tile": Vector2i(grid.width / 2, grid.height / 2),
				"elite": false,
				"modifier": "",
			})
		return plan

	var budget := BASE_BUDGET * (1.0 + 0.25 * floor_index) * difficulty_mult
	if room.type == RoomNode.RoomType.ELITE:
		budget *= ELITE_BUDGET_MULT

	var pool: Array = pool_data["enemies"].filter(
		func(e: Dictionary) -> bool: return float(e["cost"]) > 0.0
	)
	if pool.is_empty():
		return plan

	var picks: Array[Dictionary] = []
	var guard := 0
	while budget > 0.0 and guard < MAX_PICK_GUARD:
		guard += 1
		var affordable: Array = pool.filter(
			func(e: Dictionary) -> bool: return float(e["cost"]) <= budget
		)
		if affordable.is_empty():
			break
		var e: Dictionary = rng.pick(affordable)
		budget -= float(e["cost"])
		picks.append(e)

	var wave_count := 3 if floor_index >= 2 or room.type == RoomNode.RoomType.ELITE else 2
	for i in picks.size():
		var e: Dictionary = picks[i]
		var is_elite: bool = room.type == RoomNode.RoomType.ELITE and i == 0
		var tile := _pick_spawn_tile(grid, rng, entry, str(e["kind"]))
		if tile.x < 0:
			continue
		plan.append({
			"enemy": e,
			"wave": _wave_for_pick(i, picks.size(), wave_count),
			"tile": tile,
			"elite": is_elite,
			"modifier": rng.pick(pool_data["elite_modifiers"]) if is_elite else "",
		})
	return plan

func _wave_for_pick(index: int, total: int, wave_count: int) -> int:
	if wave_count <= 2 or total < 3:
		var wave1_count: int = maxi(1, ceili(total * WAVE1_SHARE))
		return 1 if index < wave1_count else 2
	var wave1_end := maxi(1, ceili(total * 0.5))
	var wave2_end := clampi(ceili(total * 0.8), wave1_end + 1, total - 1)
	if index < wave1_end:
		return 1
	if index < wave2_end:
		return 2
	return 3


func _find_kind(pool_data: Dictionary, kind: String) -> Dictionary:
	for e in pool_data["enemies"]:
		if str(e["kind"]) == kind:
			return e
	return {}


func _pick_spawn_tile(grid: TileGrid, rng: SeededRNG, entry: Vector2i, kind: String) -> Vector2i:
	var min_dist := float(PLAYER_SAFE_RADIUS + 1)
	if kind == "ranged" or kind == "caster":
		min_dist = float(RANGED_MIN_DOOR_DIST)
	for attempt in 40:
		var p := Vector2i(
			rng.randi_range(1, grid.width - 2),
			rng.randi_range(1, grid.height - 2),
		)
		if not grid.is_walkable_at(p.x, p.y):
			continue
		if grid.get_tile(p.x, p.y) == TileGrid.Tile.DOOR:
			continue
		if Vector2(p - entry).length() < min_dist:
			continue
		return p
	return _fallback_spawn_tile(grid, entry, min_dist)

func _fallback_spawn_tile(grid: TileGrid, entry: Vector2i, min_dist: float) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := -1.0
	for y in range(1, grid.height - 1):
		for x in range(1, grid.width - 1):
			if not grid.is_walkable_at(x, y):
				continue
			if grid.get_tile(x, y) == TileGrid.Tile.DOOR:
				continue
			var p := Vector2i(x, y)
			var dist := Vector2(p - entry).length()
			if dist < min_dist:
				continue
			if dist > best_dist:
				best = p
				best_dist = dist
	return best
