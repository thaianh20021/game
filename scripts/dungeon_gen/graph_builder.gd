class_name GraphBuilder
extends RefCounted
## Builds the floor layout as a graph of rooms (steps 1-3 of the pipeline in
## docs/gdd/10-dungeon-gen.md). The critical path is generated FIRST, so the
## floor can never be blocked. Deterministic for a given (seed, floor_index).

const BRANCH_MIN := 2
const BRANCH_MAX := 4
const BRANCH_LEN_MIN := 1
const BRANCH_LEN_MAX := 3
const ELITE_CHANCE_ON_BRANCH := 0.3

var rng: SeededRNG
var rooms: Array[RoomNode] = []


func build(seed_value: int, floor_index: int) -> Array[RoomNode]:
	rng = SeededRNG.new(seed_value, floor_index)
	rooms = []

	var path_len := 8 + floor_index * 2
	var path := _build_critical_path(path_len)
	_assign_critical_types(path)
	_attach_branches(path)
	return rooms


func _new_room() -> RoomNode:
	var r := RoomNode.new()
	r.id = rooms.size()
	rooms.append(r)
	return r


func _connect_rooms(a: RoomNode, b: RoomNode) -> void:
	if not a.neighbors.has(b.id):
		a.neighbors.append(b.id)
	if not b.neighbors.has(a.id):
		b.neighbors.append(a.id)


## Step 1: linear chain Entrance -> ... -> Boss. Generated first so the run
## is always completable regardless of what branches roll.
func _build_critical_path(path_len: int) -> Array[RoomNode]:
	var path: Array[RoomNode] = []
	var prev: RoomNode = null
	for i in path_len:
		var r := _new_room()
		r.depth = i
		r.on_critical_path = true
		if prev != null:
			_connect_rooms(prev, r)
		path.append(r)
		prev = r
	return path


## Step 3a: fixed roles on the critical path.
func _assign_critical_types(path: Array[RoomNode]) -> void:
	path[0].type = RoomNode.RoomType.ENTRANCE
	path[path.size() - 1].type = RoomNode.RoomType.BOSS
	# Heal room sits directly before the boss (GDD rule).
	path[path.size() - 2].type = RoomNode.RoomType.HEAL

	# Mini-boss at 60-75% of the path.
	var lo := int(path.size() * 0.6)
	var hi := int(path.size() * 0.75)
	var mb: int = clampi(rng.randi_range(lo, hi), 2, path.size() - 3)
	path[mb].type = RoomNode.RoomType.MINIBOSS

	# One event room on the path, never adjacent to the mini-boss.
	var candidates: Array[int] = []
	for i in range(1, path.size() - 2):
		if path[i].type == RoomNode.RoomType.COMBAT and absi(i - mb) > 1:
			candidates.append(i)
	if not candidates.is_empty():
		var idx: int = rng.pick(candidates)
		path[idx].type = RoomNode.RoomType.EVENT


## Steps 2 + 3b: side branches, each ending in a reward room.
## Reward quota: shop=1, shrine=1, treasure=1-2, secret=0-1.
func _attach_branches(path: Array[RoomNode]) -> void:
	var rewards: Array = [
		RoomNode.RoomType.SHOP,
		RoomNode.RoomType.SHRINE,
		RoomNode.RoomType.TREASURE,
	]
	if rng.randf() < 0.4:
		rewards.append(RoomNode.RoomType.SECRET)
	else:
		rewards.append(RoomNode.RoomType.TREASURE)

	var branch_count := rng.randi_range(BRANCH_MIN, BRANCH_MAX)
	var used_anchors: Array[int] = []

	for b in branch_count:
		var reward: RoomNode.RoomType = rewards[b % rewards.size()]
		var anchor_index := _pick_anchor(path, reward, used_anchors)
		used_anchors.append(anchor_index)

		var prev := path[anchor_index]
		var branch_len := rng.randi_range(BRANCH_LEN_MIN, BRANCH_LEN_MAX)
		for i in branch_len:
			var r := _new_room()
			r.depth = prev.depth + 1
			var is_last := i == branch_len - 1
			if is_last:
				r.type = reward
			elif rng.randf() < ELITE_CHANCE_ON_BRANCH \
					and prev.type != RoomNode.RoomType.ELITE:
				# Constraint: no two adjacent elite rooms.
				r.type = RoomNode.RoomType.ELITE
			else:
				r.type = RoomNode.RoomType.COMBAT
			_connect_rooms(prev, r)
			prev = r


## Anchor rules: only mid-path rooms (never entrance/heal/boss).
## Shops are never adjacent to the entrance.
func _pick_anchor(path: Array[RoomNode], reward: RoomNode.RoomType, used: Array[int]) -> int:
	var lo := 2 if reward == RoomNode.RoomType.SHOP else 1
	var candidates: Array[int] = []
	for i in range(lo, path.size() - 2):
		if not used.has(i):
			candidates.append(i)
	if candidates.is_empty():
		return rng.randi_range(1, path.size() - 3)
	return rng.pick(candidates)
