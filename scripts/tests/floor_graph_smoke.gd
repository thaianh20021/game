extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	_check_special_room_quota(failures)
	_check_boss_rush_graph(failures)
	_check_boss_rush_escalation(failures)

	if failures.is_empty():
		print("Floor graph smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_special_room_quota(failures: Array[String]) -> void:
	var builder := GraphBuilder.new()
	for floor_index in [1, 2, 3]:
		for seed in range(0, 40):
			var rooms := builder.build(seed, floor_index)
			var validation_errors := FloorValidator.validate(rooms)
			if not validation_errors.is_empty():
				failures.append("seed %d floor %d should validate: %s" % [seed, floor_index, validation_errors])
			var counts := _type_counts(rooms)
			for required_type in [
				RoomNode.RoomType.SHOP,
				RoomNode.RoomType.SHRINE,
				RoomNode.RoomType.TREASURE,
				RoomNode.RoomType.EVENT,
				RoomNode.RoomType.MINIBOSS,
				RoomNode.RoomType.HEAL,
				RoomNode.RoomType.BOSS,
			]:
				if int(counts.get(required_type, 0)) < 1:
					failures.append("seed %d floor %d missing %s room" % [
						seed, floor_index, RoomNode.RoomType.keys()[required_type],
					])
			if int(counts.get(RoomNode.RoomType.TREASURE, 0)) > 2:
				failures.append("seed %d floor %d should cap treasure rooms at two" % [seed, floor_index])
			for room in rooms:
				if _is_branch_reward(room.type) and room.neighbors.size() != 1:
					failures.append("reward room %d should be a branch leaf" % room.id)

func _type_counts(rooms: Array[RoomNode]) -> Dictionary:
	var counts := {}
	for room in rooms:
		counts[room.type] = int(counts.get(room.type, 0)) + 1
	return counts

func _is_branch_reward(room_type: int) -> bool:
	return room_type == RoomNode.RoomType.SHOP \
		or room_type == RoomNode.RoomType.SHRINE \
		or room_type == RoomNode.RoomType.TREASURE \
		or room_type == RoomNode.RoomType.SECRET

func _check_boss_rush_graph(failures: Array[String]) -> void:
	var builder := GraphBuilder.new()
	if not builder.has_method("build_boss_rush"):
		failures.append("GraphBuilder should expose build_boss_rush")
		return
	for floor_index in [1, 2, 3]:
		for seed in range(0, 20):
			var rooms: Array[RoomNode] = builder.call("build_boss_rush", seed, floor_index)
			var validation_errors := FloorValidator.validate(rooms)
			if not validation_errors.is_empty():
				failures.append("boss rush seed %d floor %d should validate: %s" % [
					seed, floor_index, validation_errors,
				])
			if rooms.size() != 3:
				failures.append("boss rush should build exactly 3 rooms")
				continue
			var counts := _type_counts(rooms)
			if int(counts.get(RoomNode.RoomType.ENTRANCE, 0)) != 1 \
					or int(counts.get(RoomNode.RoomType.HEAL, 0)) != 1 \
					or int(counts.get(RoomNode.RoomType.BOSS, 0)) != 1:
				failures.append("boss rush should be Entrance -> Heal -> Boss")
			for banned_type in [
				RoomNode.RoomType.SHOP,
				RoomNode.RoomType.SHRINE,
				RoomNode.RoomType.TREASURE,
				RoomNode.RoomType.EVENT,
				RoomNode.RoomType.MINIBOSS,
				RoomNode.RoomType.SECRET,
			]:
				if int(counts.get(banned_type, 0)) > 0:
					failures.append("boss rush should not include %s rooms" % RoomNode.RoomType.keys()[banned_type])

func _check_boss_rush_escalation(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	if not ctrl.has_method("run_difficulty_multiplier"):
		failures.append("FloorController should expose run_difficulty_multiplier")
	else:
		if not is_equal_approx(float(ctrl.call("run_difficulty_multiplier", "normal", 3)), 1.0):
			failures.append("normal mode should keep base difficulty multiplier")
		var rush_floor_1 := float(ctrl.call("run_difficulty_multiplier", "boss_rush", 1))
		var rush_floor_2 := float(ctrl.call("run_difficulty_multiplier", "boss_rush", 2))
		var rush_floor_3 := float(ctrl.call("run_difficulty_multiplier", "boss_rush", 3))
		if rush_floor_1 <= 1.0 or rush_floor_2 <= rush_floor_1 or rush_floor_3 <= rush_floor_2:
			failures.append("boss rush difficulty should escalate each floor")
		var endless_floor_1 := float(ctrl.call("run_difficulty_multiplier", "endless", 1))
		var endless_floor_3 := float(ctrl.call("run_difficulty_multiplier", "endless", 3))
		var endless_floor_5 := float(ctrl.call("run_difficulty_multiplier", "endless", 5))
		if not is_equal_approx(endless_floor_1, 1.0) \
				or endless_floor_3 <= endless_floor_1 \
				or endless_floor_5 <= endless_floor_3:
			failures.append("endless difficulty should start fair and scale after floor one")
	ctrl.run_mode = "boss_rush"
	ctrl.floor_index = 2
	var boss := RoomNode.new()
	boss.type = RoomNode.RoomType.BOSS
	ctrl.current_room = boss
	var objective := ctrl.current_room_objective()
	if not objective.contains("Boss Rush") or not objective.contains("Chain 2"):
		failures.append("boss rush boss objective should show mode and chain progress")
	ctrl.run_mode = "endless"
	ctrl.floor_index = 4
	ctrl.current_biome = {"run_finale": true}
	objective = ctrl.current_room_objective()
	if not objective.contains("Endless") or not objective.contains("Depth 4"):
		failures.append("endless boss objective should show endless depth progress")
	if objective.contains("Final boss") or objective.contains("run complete"):
		failures.append("endless floor 4 boss should not be treated as run finale")
	ctrl.queue_free()
