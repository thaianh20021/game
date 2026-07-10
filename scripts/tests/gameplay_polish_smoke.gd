extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	await _check_door_markers(failures)
	await _check_enemy_feedback(failures)
	await _check_player_damage_feedback(failures)
	await _check_player_heal_feedback(failures)
	await _check_player_resource_feedback(failures)
	await _check_hud_weapon_tooltip(failures)
	_check_tile_polish(failures)

	if failures.is_empty():
		print("Gameplay polish smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_door_markers(failures: Array[String]) -> void:
	if not ResourceLoader.exists("res://scripts/rooms/door_marker.gd"):
		failures.append("DoorMarker script missing")
		return
	if DoorMarker.label_for_type(RoomNode.RoomType.BOSS) != "BOSS":
		failures.append("boss door marker label should be BOSS")
	if DoorMarker.label_for_type(RoomNode.RoomType.TREASURE) != "LOOT":
		failures.append("treasure door marker label should be LOOT")
	if DoorMarker.label_for_type(RoomNode.RoomType.SECRET) != "SECRET":
		failures.append("secret door marker label should be SECRET")

	var grid := TileGrid.new(7, 7, TileGrid.Tile.FLOOR)
	for x in grid.width:
		grid.set_tile(x, 0, TileGrid.Tile.WALL)
		grid.set_tile(x, grid.height - 1, TileGrid.Tile.WALL)
	for y in grid.height:
		grid.set_tile(0, y, TileGrid.Tile.WALL)
		grid.set_tile(grid.width - 1, y, TileGrid.Tile.WALL)
	grid.set_tile(3, 0, TileGrid.Tile.DOOR)
	grid.set_tile(6, 3, TileGrid.Tile.DOOR)

	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	renderer.setup(grid, [], null, null)
	if not renderer.has_method("show_door_markers"):
		failures.append("RoomRenderer missing show_door_markers")
		renderer.free()
		return
	renderer.call("show_door_markers", {
		RoomStamper.Dir.NORTH: {
			"type": RoomNode.RoomType.BOSS,
			"route": "MAIN",
			"preview": "R+",
			"choice_index": 1,
			"input_action": "route_choice_1",
		},
		RoomStamper.Dir.EAST: {
			"type": RoomNode.RoomType.TREASURE,
			"route": "SIDE",
			"preview": "CHEST",
			"choice_index": 2,
			"input_action": "route_choice_2",
		},
	})
	await process_frame
	var marker_count := get_nodes_in_group("door_markers").size()
	if marker_count != 2:
		failures.append("expected 2 door markers, got %d" % marker_count)
	if not _has_label_text(renderer, "MAIN"):
		failures.append("main-path door marker should show route hint")
	if not _has_label_text(renderer, "SIDE"):
		failures.append("side-branch door marker should show route hint")
	if not _has_label_text(renderer, "R+") or not _has_label_text(renderer, "CHEST"):
		failures.append("door marker should show compact reward/threat preview hints")
	if not _has_label_text(renderer, "1 MAIN") or not _has_label_text(renderer, "2 SIDE"):
		failures.append("door marker should show route hotkey index beside route hint")
	var preview_marker := _first_door_marker(renderer)
	if preview_marker != null and str(preview_marker.get_meta("preview_hint", "")) == "":
		failures.append("door marker should expose preview_hint metadata")
	var main_marker := _door_marker_by_choice(renderer, 1)
	if main_marker == null:
		failures.append("door marker should expose route choice index metadata")
	else:
		if str(main_marker.get_meta("route_choice_input_action", "")) != "route_choice_1":
			failures.append("door marker should expose route choice input action metadata")
		if str(main_marker.get_meta("route_hotkey_label", "")) != "1":
			failures.append("door marker should expose route hotkey label metadata")
		main_marker.request_route_choice()
		if not bool(main_marker.get_meta("route_press_feedback", false)):
			failures.append("door marker press should expose immediate click/touch feedback")
		if int(main_marker.get_meta("route_press_feedback_count", 0)) <= 0:
			failures.append("door marker press should count feedback pulses")
		if float(main_marker.get_meta("route_press_pulse_scale", 1.0)) >= 1.0:
			failures.append("door marker press should use a small downscale pulse")
		if float(main_marker.get_meta("route_press_pulse_seconds", 0.0)) <= 0.0:
			failures.append("door marker press should expose pulse duration metadata")
	renderer.call("show_door_markers", {
		RoomStamper.Dir.NORTH: {
			"type": RoomNode.RoomType.TREASURE,
			"route": "MAIN",
			"state": "reward_locked",
			"next_action_key": "reward",
		},
	})
	await process_frame
	var reward_marker := _first_door_marker(renderer)
	if reward_marker == null:
		failures.append("reward-locked door marker should render")
	else:
		if not _has_label_text(reward_marker, "REWARD"):
			failures.append("reward-locked door marker should show reward label")
		if not bool(reward_marker.get_meta("reward_lock_pulse", false)):
			failures.append("reward-locked door marker should pulse for readability")
		if float(reward_marker.get_meta("reward_lock_pulse_scale", 0.0)) <= 1.0:
			failures.append("reward-locked door marker should expose pulse scale metadata")
		if float(reward_marker.get_meta("reward_lock_pulse_seconds", 0.0)) <= 0.0:
			failures.append("reward-locked door marker should expose pulse duration metadata")
	renderer.call("show_door_markers", {
		RoomStamper.Dir.EAST: {"type": RoomNode.RoomType.SECRET, "route": "SIDE"},
	})
	await process_frame
	var secret_marker := _first_door_marker(renderer)
	if secret_marker == null:
		failures.append("secret door marker should render")
	else:
		if not _has_label_text(secret_marker, "SECRET"):
			failures.append("secret door marker should show SECRET cue")
		if not bool(secret_marker.get_meta("secret_wall", false)):
			failures.append("secret door marker should expose secret_wall metadata")
		if str(secret_marker.get_meta("door_cue", "")) != "cracked_wall":
			failures.append("secret door marker should expose cracked_wall cue metadata")
		if int(secret_marker.get_meta("crack_line_count", 0)) < 3:
			failures.append("secret door marker should expose cracked wall line count")
		if str(secret_marker.get_meta("secret_wall_pattern", "")) != "cracked_wall_lines":
			failures.append("secret door marker should expose cracked wall line pattern")
	var marker_probe := DoorMarker.new()
	if not marker_probe.has_method("crack_line_segments"):
		failures.append("DoorMarker should expose crack_line_segments for secret wall cue")
	else:
		var cracks: Array = marker_probe.call("crack_line_segments")
		if cracks.size() < 3:
			failures.append("cracked wall cue should draw at least 3 crack segments")
		for segment in cracks:
			if not (segment is PackedVector2Array) or (segment as PackedVector2Array).size() != 2:
				failures.append("each crack segment should be a two-point line")
	marker_probe.free()
	var floor_source := FileAccess.get_file_as_string("res://scripts/rooms/floor_controller.gd")
	if not floor_source.contains("on_critical_path"):
		failures.append("FloorController should pass route metadata to door markers")
	if not floor_source.contains("_door_marker_preview"):
		failures.append("FloorController should pass compact reward/threat previews to door markers")
	renderer.free()


func _check_enemy_feedback(failures: Array[String]) -> void:
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy: Enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.max_hp = 20
	enemy.hp = 20
	enemy.take_damage(5)
	await process_frame
	if enemy.get_node_or_null("HpBar") == null:
		failures.append("enemy damage should create HpBar")
	if enemy.get_node_or_null("DamageNumber") == null:
		failures.append("enemy damage should create DamageNumber")
	var hit_spark := enemy.get_node_or_null("CombatFxHitSpark") as Node2D
	if hit_spark == null:
		failures.append("enemy damage should create CombatFxHitSpark")
	else:
		if int(hit_spark.get_meta("hit_damage", 0)) != 5:
			failures.append("enemy hit spark should store damage metadata")
		if str(hit_spark.get_meta("hit_kind", "")) != "normal":
			failures.append("enemy hit spark should store normal hit kind")
		if str(hit_spark.get_meta("impact_shape", "")) != "spark":
			failures.append("enemy hit spark should expose impact shape metadata")
	var enemy_hit_sfx := enemy.get_node_or_null("EnemyHitSfx") as AudioStreamPlayer
	if enemy_hit_sfx == null:
		failures.append("enemy damage should create hit sound feedback")
	else:
		if str(enemy_hit_sfx.get_meta("enemy_hit_sound_id", "")) != "enemy_hit_normal":
			failures.append("normal enemy hit should use normal hit cue")
		if str(enemy_hit_sfx.get_meta("enemy_hit_kind", "")) != "normal":
			failures.append("normal enemy hit sound should store hit kind")
		if int(enemy_hit_sfx.get_meta("enemy_hit_amount", 0)) != 5:
			failures.append("normal enemy hit sound should store damage amount")
		if str(enemy_hit_sfx.get_meta("audio_cue_kind", "")) != "enemy_hit":
			failures.append("enemy hit sound should expose enemy_hit cue kind")
		if enemy_hit_sfx.stream == null:
			failures.append("enemy hit sound should assign a procedural stream")
		if not bool(enemy_hit_sfx.get_meta("placeholder_audio_stream", false)):
			failures.append("enemy hit sound should mark placeholder audio metadata")
		if DisplayServer.get_name() == "headless" \
				and not bool(enemy_hit_sfx.get_meta("headless_playback_skipped", false)):
			failures.append("enemy hit sound should skip playback in headless smoke")
	enemy.hp = enemy.max_hp
	enemy.set_meta("incoming_critical", true)
	enemy.take_damage(5)
	await process_frame
	var damage_number := enemy.get_node_or_null("DamageNumber") as Label
	if damage_number == null or not damage_number.text.contains("CRIT"):
		failures.append("critical hit should show CRIT damage feedback")
	elif not bool(damage_number.get_meta("critical", false)) \
			or str(damage_number.get_meta("damage_kind", "")) != "critical" \
			or float(damage_number.scale.x) <= 1.0:
		failures.append("critical damage number should store critical metadata and render larger")
	if not bool(enemy.get_meta("last_hit_critical", false)):
		failures.append("critical hit should store metadata for UI/debug")
	enemy_hit_sfx = enemy.get_node_or_null("EnemyHitSfx") as AudioStreamPlayer
	if enemy_hit_sfx == null or str(enemy_hit_sfx.get_meta("enemy_hit_sound_id", "")) != "enemy_hit_critical":
		failures.append("critical enemy hit should use critical hit cue")
	enemy.hp = 3
	enemy.take_damage(5)
	var enemy_hit_pause_feedback := bool(enemy.get_meta("hit_pause_feedback", false))
	await process_frame
	if not enemy_hit_pause_feedback:
		failures.append("enemy kill should request hit pause feedback")
	var death_feedback := root.get_node_or_null("EnemyDeathFeedback") as Label
	if death_feedback == null:
		failures.append("enemy death should leave EnemyDeathFeedback on parent")
	elif not death_feedback.text.contains("Down"):
		failures.append("enemy death feedback should describe the kill")
	var death_sfx := root.get_node_or_null("EnemyDeathSfx") as AudioStreamPlayer
	if death_sfx == null:
		failures.append("enemy death should leave death sound feedback on parent")
	else:
		if str(death_sfx.get_meta("enemy_death_sound_id", "")) != "enemy_death":
			failures.append("enemy death sound should use enemy death cue")
		if str(death_sfx.get_meta("audio_cue_kind", "")) != "enemy_death":
			failures.append("enemy death sound should expose enemy_death cue kind")
		if int(death_sfx.get_meta("enemy_death_damage_amount", 0)) != 5:
			failures.append("enemy death sound should store killing damage amount")
		if death_sfx.stream == null:
			failures.append("enemy death sound should assign a procedural stream")
		if not bool(death_sfx.get_meta("placeholder_audio_stream", false)):
			failures.append("enemy death sound should mark placeholder audio metadata")
		if DisplayServer.get_name() == "headless" \
				and not bool(death_sfx.get_meta("headless_playback_skipped", false)):
			failures.append("enemy death sound should skip playback in headless smoke")
	await create_timer(0.45).timeout
	if is_instance_valid(enemy):
		enemy.free()


func _check_player_damage_feedback(failures: Array[String]) -> void:
	var player := Player.new()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	player.take_damage(7)
	await process_frame
	if not bool(player.get_meta("hit_pause_feedback", false)):
		failures.append("player damage should request hit pause feedback")
	var damage_number := player.get_node_or_null("PlayerDamageNumber") as Label
	if damage_number == null:
		failures.append("player damage should create PlayerDamageNumber")
	elif not damage_number.text.contains("-7"):
		failures.append("player damage number should show damage taken")
	elif str(damage_number.get_meta("feedback_type", "")) != "player_damage" \
			or int(damage_number.get_meta("damage_amount", 0)) != 7:
		failures.append("player damage number should store feedback type and amount metadata")
	player.queue_free()
	await process_frame

func _check_player_heal_feedback(failures: Array[String]) -> void:
	var player := Player.new()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	player.hp = player.max_hp - 20
	player.heal(12)
	await process_frame
	var heal_number := player.get_node_or_null("PlayerHealNumber") as Label
	if heal_number == null:
		failures.append("player heal should create PlayerHealNumber")
	elif not heal_number.text.contains("+12"):
		failures.append("player heal number should show healed amount")
	player.queue_free()
	await process_frame

func _check_player_resource_feedback(failures: Array[String]) -> void:
	Engine.time_scale = 1.0
	var player := Player.new()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	player.resource = 0.0
	player.on_hit_landed()
	await process_frame
	if Engine.time_scale >= 1.0:
		failures.append("weapon landed hit should pulse a light hit pause")
	if str(player.get_meta("hit_pause_source", "")) != "weapon_hit":
		failures.append("weapon landed hit should expose weapon_hit pause source metadata")
	if not is_equal_approx(float(player.get_meta("hit_pause_seconds", 0.0)), 0.035):
		failures.append("weapon landed hit should expose micro hit pause duration metadata")
	if not is_equal_approx(float(player.get_meta("hit_pause_scale", 0.0)), 0.92):
		failures.append("weapon landed hit should expose micro hit pause scale metadata")
	var resource_number := player.get_node_or_null("PlayerResourceNumber") as Label
	if resource_number == null:
		failures.append("energy gain should create PlayerResourceNumber")
	elif not resource_number.text.contains("+5 EN"):
		failures.append("energy gain feedback should show gained energy")
	await create_timer(0.06, true, false, true).timeout
	if not is_equal_approx(Engine.time_scale, 1.0):
		failures.append("weapon landed hit pause should restore time scale")
		Engine.time_scale = 1.0
	player.queue_free()
	await process_frame

func _check_hud_weapon_tooltip(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	ctrl.current_biome = {"name": "Test Biome", "difficulty_mult": 1.0}
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("arcanist"), "fire", "apprentice_staff")
	hud.bind(player, ctrl)
	await process_frame
	var label := hud.get_node_or_null("WeaponLabel") as Label
	if label == null:
		failures.append("HUD should expose a named WeaponLabel")
	else:
		if str(label.get_meta("weapon_id", "")) != "apprentice_staff":
			failures.append("WeaponLabel should tag active weapon id")
		if str(label.get_meta("weapon_group", "")) != "staff":
			failures.append("WeaponLabel should tag active weapon group")
		if str(label.get_meta("weapon_input_action", "")) != "attack":
			failures.append("WeaponLabel should tag attack input action")
		if str(label.get_meta("weapon_key_label", "")) != "Mouse1":
			failures.append("WeaponLabel should tag attack key label")
		if str(label.get_meta("weapon_resource_type", "")) != "mana":
			failures.append("WeaponLabel should tag mana resource type")
		if not is_equal_approx(float(label.get_meta("weapon_resource_cost", -1.0)), 5.0):
			failures.append("WeaponLabel should tag mana weapon cost")
		if float(label.get_meta("weapon_cooldown_total", 0.0)) <= 0.0:
			failures.append("WeaponLabel should tag weapon cooldown")
		for token in ["Mouse1", "Gay Hoc Do", "CD", "Cost 5"]:
			if not label.tooltip_text.contains(token):
				failures.append("WeaponLabel tooltip should include %s" % token)
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_tile_polish(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	if not renderer.has_method("wall_sprite_name_for_tile"):
		failures.append("RoomRenderer missing wall_sprite_name_for_tile")
		renderer.free()
		return
	var grid := TileGrid.new(3, 3, TileGrid.Tile.FLOOR)
	grid.set_tile(1, 1, TileGrid.Tile.WALL)
	var sprite_name := str(renderer.call("wall_sprite_name_for_tile", grid, 1, 1))
	if sprite_name == "":
		failures.append("wall sprite helper should return a sprite name")
	var strip := TileGrid.new(5, 3, TileGrid.Tile.FLOOR)
	for x in [1, 2, 3]:
		strip.set_tile(x, 1, TileGrid.Tile.WALL)
	var expected := {
		1: "wall_top_left",
		2: "wall_top_mid",
		3: "wall_top_right",
	}
	for x in expected.keys():
		var actual := str(renderer.call("wall_sprite_name_for_tile", strip, int(x), 1))
		if actual != str(expected[x]):
			failures.append("wall sprite helper should choose %s for strip x%d, got %s" % [
				str(expected[x]),
				int(x),
				actual,
			])
	renderer.free()

func _has_label_text(parent: Node, text: String) -> bool:
	for label in parent.find_children("*", "Label", true, false):
		if str(label.text).contains(text):
			return true
	return false

func _first_door_marker(parent: Node) -> DoorMarker:
	for child in parent.get_children():
		if child is DoorMarker:
			return child
	return null

func _door_marker_by_choice(parent: Node, choice_index: int) -> DoorMarker:
	for child in parent.get_children():
		if child is DoorMarker and int(child.get_meta("route_choice_index", 0)) == choice_index:
			return child
	return null
