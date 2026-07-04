class_name FloorValidator
extends RefCounted
## Structural checks for a generated floor (step 9 of the pipeline).
## Run over many seeds in automated tests: 10k seeds must produce 0 errors.


## Returns an empty array when the floor is valid, otherwise a list of errors.
static func validate(rooms: Array[RoomNode]) -> Array[String]:
	var errors: Array[String] = []
	if rooms.is_empty():
		return ["floor has no rooms"]

	var entrance_id := -1
	var boss_count := 0
	var entrance_count := 0
	for r in rooms:
		match r.type:
			RoomNode.RoomType.ENTRANCE:
				entrance_count += 1
				entrance_id = r.id
			RoomNode.RoomType.BOSS:
				boss_count += 1
	if entrance_count != 1:
		errors.append("expected exactly 1 entrance, got %d" % entrance_count)
	if boss_count != 1:
		errors.append("expected exactly 1 boss room, got %d" % boss_count)
	if entrance_id == -1:
		return errors

	# Every room must be reachable from the entrance (BFS).
	var visited := {}
	var queue: Array[int] = [entrance_id]
	visited[entrance_id] = true
	while not queue.is_empty():
		var current: int = queue.pop_front()
		for n in rooms[current].neighbors:
			if not visited.has(n):
				visited[n] = true
				queue.append(n)
	if visited.size() != rooms.size():
		errors.append("unreachable rooms: %d of %d" % [rooms.size() - visited.size(), rooms.size()])

	for r in rooms:
		# No two adjacent elite rooms.
		if r.type == RoomNode.RoomType.ELITE:
			for n in r.neighbors:
				if rooms[n].type == RoomNode.RoomType.ELITE:
					errors.append("adjacent elite rooms: %d and %d" % [r.id, n])
		# Heal room must be adjacent to the boss room.
		if r.type == RoomNode.RoomType.HEAL:
			var next_to_boss := false
			for n in r.neighbors:
				if rooms[n].type == RoomNode.RoomType.BOSS:
					next_to_boss = true
			if not next_to_boss:
				errors.append("heal room %d is not adjacent to the boss" % r.id)

	return errors


## Smoke test helper: builds [count] floors and reports failures.
static func run_seed_sweep(count: int, floor_index: int = 1) -> int:
	var failures := 0
	var builder := GraphBuilder.new()
	for s in count:
		var rooms := builder.build(s, floor_index)
		var errors := validate(rooms)
		if not errors.is_empty():
			failures += 1
			push_error("seed %d failed: %s" % [s, errors])
	return failures
