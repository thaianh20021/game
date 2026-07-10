extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

class DummyPlayer:
	extends Node2D
	signal hp_changed(current: int, max_value: int)

	var hp := 100
	var max_hp := 100
	var gold := 0
	var picked_weapon := ""
	var statuses := {}

	func take_damage(amount: int) -> void:
		hp = maxi(hp - amount, 0)
		hp_changed.emit(hp, max_hp)

	func add_gold(amount: int) -> void:
		gold += amount

	func heal(amount: int) -> void:
		hp = mini(max_hp, hp + amount)
		hp_changed.emit(hp, max_hp)

	func pickup_weapon(weapon_id: String) -> void:
		picked_weapon = weapon_id

	func add_status(status_name: String, duration: float) -> void:
		statuses[status_name] = maxf(duration, float(statuses.get(status_name, 0.0)))

	func has_status(status_name: String) -> bool:
		return statuses.has(status_name)

func _init() -> void:
	var failures: Array[String] = []

	await _check_affix_db(failures)
	await _check_renderer_affix_features(failures)
	await _check_elite_modifier_stats(failures)
	await _check_explosive_elite_death_blast(failures)
	await _check_vampiric_elite_contact_heal(failures)
	await _check_splitter_elite_death_spawns_minions(failures)
	await _check_summoner_elite_starts_with_minion(failures)
	await _check_shielded_elite_reduces_hit_damage(failures)
	await _check_berserk_elite_enrages_when_wounded(failures)
	await _check_teleporting_elite_blinks_when_far(failures)
	await _check_burning_and_frozen_elite_contact_status(failures)
	await _check_cursed_mist_contact_status(failures)
	await process_frame
	await process_frame

	if failures.is_empty():
		print("Room affix/elite smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_affix_db(failures: Array[String]) -> void:
	var affix_db: Variant = load("res://scripts/rooms/room_affix_db.gd")
	if affix_db == null:
		failures.append("room affix db script should exist")
		return
	var direct: Dictionary = affix_db.affix("spike_floor")
	if str(direct.get("id", "")) != "spike_floor":
		failures.append("room affix db should expose direct affix lookup")
	var rolled_a: Dictionary = affix_db.roll_for_room(RoomNode.RoomType.COMBAT, 77, 4, 1)
	var rolled_b: Dictionary = affix_db.roll_for_room(RoomNode.RoomType.COMBAT, 77, 4, 1)
	if str(rolled_a.get("id", "")) != str(rolled_b.get("id", "")):
		failures.append("room affix rolls should be deterministic")
	var treasure: Dictionary = affix_db.roll_for_room(RoomNode.RoomType.TREASURE, 77, 4, 1)
	if str(treasure.get("id", "")) != "none":
		failures.append("non-combat rooms should roll no affix")

func _check_renderer_affix_features(failures: Array[String]) -> void:
	var affix_db: Variant = load("res://scripts/rooms/room_affix_db.gd")
	if affix_db == null:
		return
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var empty_plan: Array[Dictionary] = []
	renderer.setup(_basic_grid(), empty_plan, null, dummy, RoomNode.RoomType.COMBAT, affix_db.affix("spike_floor"))
	await process_frame
	if str(renderer.get_meta("room_affix", "")) != "spike_floor":
		failures.append("renderer should store active room affix metadata")
	if _child_group_count(renderer, "room_traps") < 5:
		failures.append("spike floor affix should add extra traps")
	if renderer.find_child("RoomAffixLabel", true, false) == null:
		failures.append("room affix should spawn a readable label")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_elite_modifier_stats(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [
		{
			"enemy": {"id": "smoke_melee", "kind": "melee", "hp": 10, "dmg": 2},
			"wave": 1,
			"tile": Vector2i(4, 4),
			"elite": true,
			"modifier": "armored",
		},
	]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.ELITE, {})
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("elite room should spawn an enemy")
	else:
		if str(enemy.get_meta("elite_modifier", "")) != "armored":
			failures.append("elite enemy should store modifier metadata")
		if str(enemy.get_meta("elite_modifier_label", "")) != "Elite: Armored":
			failures.append("elite enemy should store readable modifier label metadata")
		var label := enemy.find_child("EliteModifierLabel", true, false) as Label
		if label == null or not str(label.text).contains("Elite: Armored"):
			failures.append("elite enemy should show readable modifier label")
		if enemy.max_hp < 60:
			failures.append("armored elite should stack extra hp on base elite hp")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_explosive_elite_death_blast(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_elite_entry("explosive", Vector2i(4, 4))]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.ELITE, {})
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("explosive elite should spawn an enemy")
	else:
		dummy.global_position = enemy.global_position + Vector2(8, 0)
		enemy.take_damage(enemy.hp)
		await process_frame
		if dummy.hp >= dummy.max_hp:
			failures.append("explosive elite death should blast nearby player")
		if renderer.find_child("CombatFxTelegraph", true, false) == null:
			failures.append("explosive elite death should spawn blast warning fx")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_vampiric_elite_contact_heal(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_elite_entry("vampiric", Vector2i(4, 4))]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.ELITE, {})
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("vampiric elite should spawn an enemy")
	else:
		enemy.take_damage(8)
		var wounded_hp := enemy.hp
		dummy.global_position = enemy.global_position
		enemy._try_contact_damage()
		enemy._physics_process(0.51)
		if dummy.hp >= dummy.max_hp:
			failures.append("vampiric elite contact should still damage player")
		if enemy.hp <= wounded_hp:
			failures.append("vampiric elite contact should heal itself")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_splitter_elite_death_spawns_minions(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_elite_entry("splitter", Vector2i(4, 4))]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.ELITE, {})
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("splitter elite should spawn an enemy")
	else:
		enemy.take_damage(enemy.hp)
		await process_frame
		await process_frame
		if _enemy_count(renderer) < 2:
			failures.append("splitter elite death should spawn two minions")
		if _elite_minion_count(renderer, "splitter") < 2:
			failures.append("splitter elite minions should be tagged")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_summoner_elite_starts_with_minion(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_elite_entry("summoner", Vector2i(4, 4))]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.ELITE, {})
	await process_frame
	if _enemy_count(renderer) < 2:
		failures.append("summoner elite should start with a summoned minion")
	if _elite_minion_count(renderer, "summoner") < 1:
		failures.append("summoner elite minion should be tagged")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_shielded_elite_reduces_hit_damage(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_elite_entry("shielded", Vector2i(4, 4))]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.ELITE, {})
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("shielded elite should spawn an enemy")
	else:
		var before_hp := enemy.hp
		enemy.take_damage(10)
		var loss := before_hp - enemy.hp
		if loss > 6:
			failures.append("shielded elite should reduce incoming hit damage")
		if int(enemy.get_meta("shielded_absorbed", 0)) < 4:
			failures.append("shielded elite should track absorbed damage")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_berserk_elite_enrages_when_wounded(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_elite_entry("berserk", Vector2i(4, 4))]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.ELITE, {})
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("berserk elite should spawn an enemy")
	else:
		var before_speed := enemy.speed
		var before_damage := enemy.contact_damage
		enemy.take_damage(ceili(float(enemy.max_hp) * 0.55))
		if not bool(enemy.get_meta("elite_enraged", false)):
			failures.append("berserk elite should enrage below half hp")
		if enemy.speed <= before_speed or enemy.contact_damage <= before_damage:
			failures.append("berserk enrage should boost speed and contact damage")
		if not str(enemy.get_meta("elite_enrage_warning", "")).contains("ENRAGE"):
			failures.append("berserk elite should store readable enrage warning metadata")
		var warning := enemy.find_child("EliteEnrageWarning", true, false) as Label
		if warning == null:
			failures.append("berserk elite should show a readable enrage warning label")
		elif not warning.text.contains("ENRAGE") or not warning.text.contains("DAMAGE"):
			failures.append("berserk elite enrage warning should explain the threat")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_teleporting_elite_blinks_when_far(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_elite_entry("teleporting", Vector2i(4, 4))]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.ELITE, {})
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("teleporting elite should spawn an enemy")
	else:
		dummy.global_position = Vector2(80, 80)
		enemy.global_position = dummy.global_position + Vector2(180, 0)
		enemy._physics_process(1.3)
		if int(enemy.get_meta("elite_teleports", 0)) < 1:
			failures.append("teleporting elite should blink when far from target")
		if enemy.global_position.distance_to(dummy.global_position) > 70.0:
			failures.append("teleporting elite blink should land near target")
		var blink_fx := _first_telegraph_with_meta(root, "elite_modifier", "teleporting")
		if blink_fx == null:
			failures.append("teleporting elite blink should tag telegraph fx with elite modifier")
		else:
			if str(blink_fx.get_meta("enemy_attack", "")) != "blink":
				failures.append("teleporting elite blink fx should tag enemy_attack=blink")
			var label := blink_fx.get_node_or_null("AttackCueLabel") as Label
			if label == null or not label.text.contains("BLINK"):
				failures.append("teleporting elite blink fx should show BLINK cue label")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_burning_and_frozen_elite_contact_status(failures: Array[String]) -> void:
	await _check_contact_status("burning", "burning", failures)
	await _check_contact_status("frozen", "chilled", failures)

func _check_contact_status(modifier: String, status_name: String, failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_elite_entry(modifier, Vector2i(4, 4))]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.ELITE, {})
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("%s elite should spawn an enemy" % modifier)
	else:
		dummy.global_position = enemy.global_position
		enemy._try_contact_damage()
		enemy._physics_process(0.51)
		if not dummy.has_status(status_name):
			failures.append("%s elite contact should apply %s status" % [modifier, status_name])
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_cursed_mist_contact_status(failures: Array[String]) -> void:
	var affix_db: Variant = load("res://scripts/rooms/room_affix_db.gd")
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_elite_entry("", Vector2i(4, 4))]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.COMBAT,
		affix_db.affix("cursed_mist"))
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("cursed mist should spawn an enemy")
	else:
		dummy.global_position = enemy.global_position
		enemy._try_contact_damage()
		enemy._physics_process(0.51)
		if not dummy.has_status("cursed"):
			failures.append("cursed mist enemy contact should apply cursed")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

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

func _elite_minion_count(parent: Node, source: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child is Enemy and str(child.get_meta("elite_minion", "")) == source:
			count += 1
	return count

func _child_group_count(parent: Node, group_name: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.is_in_group(group_name):
			count += 1
	return count

func _first_telegraph_with_meta(parent: Node, key: String, value: Variant) -> Node:
	for child in parent.get_children():
		if child.name == "CombatFxTelegraph" and child.has_meta(key) \
				and child.get_meta(key) == value:
			return child
		var nested := _first_telegraph_with_meta(child, key, value)
		if nested != null:
			return nested
	return null

func _elite_entry(modifier: String, tile: Vector2i) -> Dictionary:
	return {
		"enemy": {"id": "smoke_melee", "kind": "melee", "hp": 10, "dmg": 2},
		"wave": 1,
		"tile": tile,
		"elite": true,
		"modifier": modifier,
		"no_loot": true,
	}
