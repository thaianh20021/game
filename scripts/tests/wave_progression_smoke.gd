extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

class DummyPlayer:
	extends Node2D
	func take_damage(_amount: int) -> void:
		pass

func _init() -> void:
	var failures: Array[String] = []

	await _check_spawner_late_floor_wave_three(failures)
	await _check_renderer_advances_three_waves(failures)
	await _check_boss_clear_banner(failures)
	await _check_final_boss_clear_banner(failures)

	if failures.is_empty():
		print("Wave progression smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_spawner_late_floor_wave_three(failures: Array[String]) -> void:
	var room := RoomNode.new()
	room.id = 1
	room.type = RoomNode.RoomType.COMBAT
	var spawner := EnemySpawner.new()
	var pool := {
		"enemies": [
			{"id": "smoke_a", "name": "A", "kind": "melee", "cost": 1, "hp": 5, "dmg": 1},
			{"id": "smoke_b", "name": "B", "kind": "ranged", "cost": 1, "hp": 5, "dmg": 1},
		],
		"elite_modifiers": ["armored"],
	}
	var plan := spawner.roll_spawn_plan(room, _basic_grid(), SeededRNG.new(222, 2),
		2, 1.0, pool, Vector2i(6, 1))
	var waves := {}
	for entry in plan:
		waves[int(entry.get("wave", 0))] = true
	if not waves.has(3):
		failures.append("floor 2+ combat rooms should support a third wave")

func _check_renderer_advances_three_waves(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var objective_events: Array[Dictionary] = []
	if not renderer.has_signal("objective_context_changed"):
		failures.append("renderer should expose objective_context_changed for live HUD updates")
	else:
		renderer.connect("objective_context_changed", func(context: Dictionary) -> void:
			objective_events.append(context.duplicate(true)))
	var plan: Array[Dictionary] = [
		{"enemy": {"id": "w1", "kind": "melee", "hp": 5, "dmg": 1}, "wave": 1, "tile": Vector2i(3, 3), "elite": false, "modifier": ""},
		{"enemy": {"id": "w2", "kind": "melee", "hp": 5, "dmg": 1}, "wave": 2, "tile": Vector2i(4, 3), "elite": false, "modifier": ""},
		{"enemy": {"id": "w3", "kind": "melee", "hp": 5, "dmg": 1}, "wave": 3, "tile": Vector2i(5, 3), "elite": false, "modifier": ""},
	]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.COMBAT)
	await process_frame
	if _enemy_count(renderer) != 1:
		failures.append("renderer should spawn only first wave initially")
	_assert_combat_live_context(renderer, 1, 3, 1, failures)
	_assert_objective_event(objective_events, 1, 3, 1, failures)
	await _kill_current_wave(renderer)
	if _enemy_count(renderer) != 1 or _current_wave(renderer) != 2:
		failures.append("renderer should advance to wave 2")
	_assert_wave_cue(renderer, 2, 3, 1, failures)
	_assert_combat_live_context(renderer, 2, 3, 1, failures)
	_assert_objective_event(objective_events, 2, 3, 1, failures)
	await _kill_current_wave(renderer)
	if _enemy_count(renderer) != 1 or _current_wave(renderer) != 3:
		failures.append("renderer should advance to wave 3")
	_assert_wave_cue(renderer, 3, 3, 1, failures)
	_assert_combat_live_context(renderer, 3, 3, 1, failures)
	_assert_objective_event(objective_events, 3, 3, 1, failures)
	await _kill_current_wave(renderer)
	if not renderer.is_cleared:
		failures.append("renderer should clear only after final wave")
	var banner := renderer.get_node_or_null("RoomClearBanner") as Label
	if banner == null:
		failures.append("renderer should show a room clear banner after final wave")
	elif not banner.text.contains("Room Cleared") or not banner.text.contains("Reward"):
		failures.append("room clear banner should mention clear and reward")
	var sfx := renderer.get_node_or_null("RoomClearSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("combat room clear should create room clear sound placeholder")
	else:
		if str(sfx.get_meta("room_clear_sound_id", "")) != "room_clear_reward":
			failures.append("combat room clear sound should expose reward clear cue id")
		if str(sfx.get_meta("room_clear_type", "")) != "COMBAT":
			failures.append("combat room clear sound should store room type")
		if bool(sfx.get_meta("room_clear_objective", true)):
			failures.append("combat room clear sound should mark non-objective clear")
		if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("combat room clear sound should come from AudioCueDB")
		if sfx.stream == null:
			failures.append("combat room clear sound should assign an audio stream")
		if DisplayServer.get_name() == "headless" \
				and not bool(sfx.get_meta("headless_playback_skipped", false)):
			failures.append("combat room clear sound should skip playback in headless smoke")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_boss_clear_banner(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [
		{"enemy": {"id": "boss_smoke", "kind": "melee", "hp": 5, "dmg": 1}, "wave": 1, "tile": Vector2i(3, 3), "elite": false, "modifier": ""},
	]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.BOSS)
	await process_frame
	await _kill_current_wave(renderer)
	var banner := renderer.get_node_or_null("RoomClearBanner") as Label
	if banner == null:
		failures.append("boss clear should show a clear banner")
	else:
		if not banner.text.contains("Boss defeated"):
			failures.append("boss clear banner should say boss defeated")
		if not banner.text.contains("Portal"):
			failures.append("boss clear banner should mention the exit portal")
		if not banner.text.contains("reward"):
			failures.append("boss clear banner should mention the boss reward")
	var sfx := renderer.get_node_or_null("RoomClearSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("boss clear should create room clear sound placeholder")
	else:
		if str(sfx.get_meta("room_clear_sound_id", "")) != "room_clear_boss":
			failures.append("boss clear sound should expose boss clear cue id")
		if str(sfx.get_meta("room_clear_type", "")) != "BOSS":
			failures.append("boss clear sound should store boss room type")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_final_boss_clear_banner(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [
		{"enemy": {"id": "boss_smoke", "kind": "melee", "hp": 5, "dmg": 1}, "wave": 1, "tile": Vector2i(3, 3), "elite": false, "modifier": ""},
	]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.BOSS, {}, {
		"id": "crystal_archive",
		"name": "Crystal Archive",
		"run_finale": true,
	})
	await process_frame
	await _kill_current_wave(renderer)
	var banner := renderer.get_node_or_null("RoomClearBanner") as Label
	if banner == null:
		failures.append("final boss clear should show a clear banner")
	else:
		if not banner.text.contains("Final Boss"):
			failures.append("final boss clear banner should say Final Boss")
		if not banner.text.contains("Run complete"):
			failures.append("final boss clear banner should mention run completion")
		if not banner.text.contains("reward"):
			failures.append("final boss clear banner should still mention reward")
	var sfx := renderer.get_node_or_null("RoomClearSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("final boss clear should create room clear sound placeholder")
	else:
		if not bool(sfx.get_meta("room_clear_run_finale", false)):
			failures.append("final boss clear sound should expose run finale metadata")
		if str(sfx.get_meta("room_clear_sound_id", "")) != "room_clear_finale":
			failures.append("final boss clear sound should use finale clear cue id")
		if str(sfx.get_meta("audio_cue_family", "")) != "finale":
			failures.append("final boss clear sound should expose finale audio family")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _kill_current_wave(renderer: RoomRenderer) -> void:
	var enemy := _first_enemy(renderer)
	if enemy != null:
		enemy.take_damage(999)
	await process_frame
	await process_frame

func _current_wave(renderer: RoomRenderer) -> int:
	return int(renderer.get("_current_wave"))

func _assert_wave_cue(
		renderer: RoomRenderer,
		wave_index: int,
		wave_count: int,
		enemy_count: int,
		failures: Array[String],
) -> void:
	var cue := renderer.get_node_or_null("WaveStartCue") as Label
	if cue == null:
		failures.append("renderer should show a wave start cue for wave %d/%d" % [wave_index, wave_count])
		return
	var expected_text := "Wave %d/%d" % [wave_index, wave_count]
	if not cue.text.contains(expected_text):
		failures.append("wave start cue should mention %s" % expected_text)
	if int(cue.get_meta("wave_index", 0)) != wave_index:
		failures.append("wave start cue should expose wave_index metadata")
	if int(cue.get_meta("wave_count", 0)) != wave_count:
		failures.append("wave start cue should expose wave_count metadata")
	if int(cue.get_meta("enemy_count", 0)) != enemy_count:
		failures.append("wave start cue should expose enemy_count metadata")
	if str(cue.get_meta("room_type", "")) != "COMBAT":
		failures.append("wave start cue should expose room_type metadata")
	var sfx := renderer.get_node_or_null("WaveStartSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("wave start cue should create a sound placeholder")
		return
	if str(sfx.get_meta("wave_start_sound_id", "")) != "wave_start":
		failures.append("wave start sound should use wave_start cue")
	if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
		failures.append("wave start sound should come from AudioCueDB")
	if int(sfx.get_meta("wave_index", 0)) != wave_index:
		failures.append("wave start sound should expose wave_index metadata")
	if int(sfx.get_meta("wave_count", 0)) != wave_count:
		failures.append("wave start sound should expose wave_count metadata")
	if int(sfx.get_meta("enemy_count", 0)) != enemy_count:
		failures.append("wave start sound should expose enemy_count metadata")
	if str(sfx.get_meta("room_type", "")) != "COMBAT":
		failures.append("wave start sound should expose room_type metadata")
	if sfx.stream == null:
		failures.append("wave start sound should assign an audio stream")
	if DisplayServer.get_name() == "headless" \
			and not bool(sfx.get_meta("headless_playback_skipped", false)):
		failures.append("wave start sound should skip playback in headless smoke")

func _assert_combat_live_context(
		renderer: RoomRenderer,
		wave_index: int,
		wave_count: int,
		enemies_left: int,
		failures: Array[String],
) -> void:
	var context: Dictionary = renderer.call("live_objective_context")
	if context.is_empty():
		failures.append("combat room should expose live wave objective context")
		return
	var expected_wave := "Wave %d/%d" % [wave_index, wave_count]
	if not str(context.get("objective_text", "")).contains(expected_wave):
		failures.append("combat live objective should mention %s" % expected_wave)
	if not str(context.get("next_action_text", "")).contains("Defeat"):
		failures.append("combat live objective should tell the player to defeat enemies")
	if int(context.get("wave_index", 0)) != wave_index:
		failures.append("combat live objective should expose wave_index metadata")
	if int(context.get("wave_count", 0)) != wave_count:
		failures.append("combat live objective should expose wave_count metadata")
	if int(context.get("enemies_left", 0)) != enemies_left:
		failures.append("combat live objective should expose enemies_left metadata")
	if str(context.get("next_action_key", "")) != "combat":
		failures.append("combat live objective should expose combat next-action key")
	if str(context.get("room_type", "")) != "COMBAT":
		failures.append("combat live objective should expose room type")

func _assert_objective_event(
		events: Array[Dictionary],
		wave_index: int,
		wave_count: int,
		enemies_left: int,
		failures: Array[String],
) -> void:
	for event in events:
		if int(event.get("wave_index", 0)) == wave_index \
				and int(event.get("wave_count", 0)) == wave_count \
				and int(event.get("enemies_left", 0)) == enemies_left:
			return
	failures.append("renderer objective_context_changed should emit wave %d/%d with %d enemies left" % [
		wave_index,
		wave_count,
		enemies_left,
	])

func _first_enemy(parent: Node) -> Enemy:
	for child in parent.get_children():
		if child is Enemy:
			return child
	return null

func _enemy_count(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is Enemy:
			count += 1
	return count

func _basic_grid() -> TileGrid:
	var grid := TileGrid.new(14, 10, TileGrid.Tile.FLOOR)
	for x in grid.width:
		grid.set_tile(x, 0, TileGrid.Tile.WALL)
		grid.set_tile(x, grid.height - 1, TileGrid.Tile.WALL)
	for y in grid.height:
		grid.set_tile(0, y, TileGrid.Tile.WALL)
		grid.set_tile(grid.width - 1, y, TileGrid.Tile.WALL)
	grid.set_tile(6, 0, TileGrid.Tile.DOOR)
	grid.set_tile(7, 0, TileGrid.Tile.DOOR)
	return grid
