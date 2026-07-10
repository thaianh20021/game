extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

class DummyPlayer:
	extends Node2D
	var damage_taken := 0
	var statuses := {}

	func take_damage(_amount: int) -> void:
		damage_taken += _amount
	func add_status(status_name: String, duration: float) -> void:
		statuses[status_name] = duration
	func has_status(status_name: String) -> bool:
		return statuses.has(status_name)
	func add_gold(_amount: int) -> void:
		pass
	func heal(_amount: int) -> void:
		pass
	func pickup_weapon(_weapon_id: String) -> void:
		pass

func _init() -> void:
	var failures: Array[String] = []

	await _check_rubble_golem_splits_on_death(failures)
	await _check_web_spider_projectile_chills_player(failures)
	await _check_enemy_projectile_readability_metadata(failures)
	await _check_cave_slime_contact_poisons_player(failures)
	await _check_beast_herder_summons_and_enrages(failures)
	await _check_spore_matriarch_summons_and_poisons(failures)
	await _check_forge_captain_buffs_and_charges(failures)
	await _check_archive_curator_chill_lattice(failures)
	await _check_quartz_shaman_volley_buffs_golem(failures)
	await _check_cave_crab_front_shell_blocks_damage(failures)
	await _check_stalactite_wisp_ambush_drop(failures)

	if failures.is_empty():
		print("Enemy family smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_rubble_golem_splits_on_death(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_entry("rubble_golem", "tanker")]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy)
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("rubble_golem should spawn")
	else:
		enemy.take_damage(enemy.hp)
		await process_frame
		await process_frame
		if _enemy_count(renderer) < 2:
			failures.append("rubble_golem death should split into two minions")
		if _family_minion_count(renderer, "rubble_golem") < 2:
			failures.append("rubble_golem split minions should be tagged")
		if renderer.is_cleared:
			failures.append("room should wait for rubble_golem split minions before clearing")
		for child in renderer.get_children():
			if child is Enemy:
				child.take_damage(child.hp)
		await process_frame
		if not renderer.is_cleared:
			failures.append("room should clear after split minions die")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_quartz_shaman_volley_buffs_golem(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	dummy.global_position = Vector2(999, 999)
	scene.add_child(dummy)
	scene.add_child(renderer)
	var plan: Array[Dictionary] = [
		_entry("quartz_shaman", "caster", 20, 5),
		_entry("rubble_golem", "tanker", 20, 4),
	]
	plan[1]["tile"] = Vector2i(6, 4)
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy)
	await process_frame
	var shaman := _first_enemy_id(renderer, "quartz_shaman")
	var golem := _first_enemy_id(renderer, "rubble_golem")
	if shaman == null:
		failures.append("quartz_shaman should spawn")
	elif golem == null:
		failures.append("rubble_golem ally should spawn near quartz_shaman")
	else:
		dummy.global_position = shaman.global_position + Vector2(96, 0)
		shaman.target = dummy
		var before_projectiles := _projectile_count(scene)
		var golem_speed := golem.speed
		var golem_damage := golem.contact_damage
		shaman._ranged_behavior(0.1)
		await process_frame
		shaman._ranged_behavior(0.6)
		await process_frame
		if _projectile_count(scene) - before_projectiles < 3:
			failures.append("quartz_shaman should fire a 3-shot crystal volley")
		if not bool(golem.get_meta("quartz_shaman_buffed", false)):
			failures.append("quartz_shaman should buff nearby golems")
		if golem.speed <= golem_speed or golem.contact_damage <= golem_damage:
			failures.append("quartz_shaman buff should raise golem speed and damage")
	scene.queue_free()
	await process_frame

func _check_cave_crab_front_shell_blocks_damage(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_entry("cave_crab", "armored_melee", 40, 6)]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy)
	await process_frame
	var crab := _first_enemy_id(renderer, "cave_crab")
	if crab == null:
		failures.append("cave_crab should spawn")
	elif not crab.has_method("hit_from"):
		failures.append("cave_crab should expose hit_from for directional armor")
	else:
		dummy.global_position = crab.global_position + Vector2(32, 0)
		var before_hp := crab.hp
		crab.hit_from(10, "", dummy.global_position)
		var front_loss := before_hp - crab.hp
		before_hp = crab.hp
		crab.hit_from(10, "", crab.global_position + Vector2(-32, 0))
		var back_loss := before_hp - crab.hp
		if front_loss >= back_loss:
			failures.append("cave_crab front shell should reduce frontal hit damage")
		if int(crab.get_meta("front_shell_blocked", 0)) <= 0:
			failures.append("cave_crab should track front shell blocked damage")
		var shell_blocked_before := int(crab.get_meta("front_shell_blocked", 0))
		var hp_before_projectile := crab.hp
		var projectile := Projectile.new()
		scene_root_add(projectile)
		projectile.global_position = dummy.global_position
		projectile.setup(Vector2.LEFT, 200.0, 10, 100.0, Color.WHITE, "")
		projectile.call("_on_body_entered", crab)
		var projectile_loss := hp_before_projectile - crab.hp
		if projectile_loss > 5:
			failures.append("player projectile should respect cave_crab front shell")
		if int(crab.get_meta("front_shell_blocked", 0)) <= shell_blocked_before:
			failures.append("projectile front shell hit should increase blocked damage")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_stalactite_wisp_ambush_drop(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	dummy.global_position = Vector2(999, 999)
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_entry("stalactite_wisp", "ambusher", 16, 5)]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy)
	await process_frame
	var wisp := _first_enemy_id(renderer, "stalactite_wisp")
	if wisp == null:
		failures.append("stalactite_wisp should spawn")
	else:
		if not bool(wisp.get_meta("ambush_hidden", false)):
			failures.append("stalactite_wisp should start hidden on ceiling")
		if wisp.visible:
			failures.append("stalactite_wisp should be invisible while hidden")
		dummy.global_position = wisp.global_position + Vector2(10, 0)
		wisp._physics_process(0.1)
		if not bool(wisp.get_meta("ambush_dropped", false)):
			failures.append("stalactite_wisp should drop when player passes close")
		if not wisp.visible:
			failures.append("stalactite_wisp should become visible after dropping")
		if dummy.damage_taken <= 0:
			failures.append("stalactite_wisp drop should damage nearby player")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_web_spider_projectile_chills_player(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	scene.add_child(dummy)
	scene.add_child(renderer)
	var plan: Array[Dictionary] = [_entry("web_spider", "ranged")]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy)
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("web_spider should spawn")
	else:
		enemy._shoot(Vector2.RIGHT, 120.0, 2, 100.0)
		await process_frame
		var projectile := _first_projectile(scene)
		if projectile == null:
			failures.append("web_spider should fire a projectile")
		else:
			if str(projectile.get_meta("hit_status", "")) != "chilled":
				failures.append("web_spider projectile should carry chilled status")
			var player := Player.new()
			scene.add_child(player)
			player.max_hp = 100
			player.hp = 100
			projectile.call("_on_body_entered", player)
			if not player.has_status("chilled"):
				failures.append("web_spider projectile should chill player on hit")
	scene.queue_free()
	await process_frame

func _check_enemy_projectile_readability_metadata(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	scene.add_child(dummy)
	scene.add_child(renderer)
	var plan: Array[Dictionary] = [
		_entry("web_spider", "ranged"),
		_entry("quartz_shaman", "caster"),
	]
	plan[1]["tile"] = Vector2i(6, 4)
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy)
	await process_frame
	var spider := _first_enemy_id(renderer, "web_spider")
	var shaman := _first_enemy_id(renderer, "quartz_shaman")
	if spider == null:
		failures.append("web_spider should spawn for readability smoke")
	else:
		spider._shoot(Vector2.RIGHT, 120.0, 2, 100.0)
		await process_frame
		var projectile := _first_projectile(scene)
		if projectile == null:
			failures.append("web_spider should fire readability projectile")
		else:
			if str(projectile.get_meta("enemy_attack", "")) != "web_shot":
				failures.append("web_spider projectile should tag enemy_attack=web_shot")
			if str(projectile.get_meta("enemy_kind", "")) != "ranged":
				failures.append("web_spider projectile should tag enemy kind")
			if str(projectile.get_meta("enemy_id", "")) != "web_spider":
				failures.append("web_spider projectile should tag enemy id")
			if not projectile.has_meta("enemy_projectile_color"):
				failures.append("web_spider projectile should expose enemy projectile color")
	if shaman == null:
		failures.append("quartz_shaman should spawn for readability smoke")
	else:
		dummy.global_position = shaman.global_position + Vector2(90, 0)
		shaman.target = dummy
		shaman._ranged_behavior(0.1)
		await process_frame
		shaman._ranged_behavior(0.6)
		await process_frame
		if not _has_projectile_attack(scene, "crystal_volley"):
			failures.append("quartz_shaman volley should tag projectiles as crystal_volley")
	scene.queue_free()
	await process_frame

func _check_cave_slime_contact_poisons_player(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var player := Player.new()
	root.add_child(player)
	root.add_child(renderer)
	player.max_hp = 100
	player.hp = 100
	var plan: Array[Dictionary] = [_entry("cave_slime", "melee")]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, player)
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("cave_slime should spawn")
	else:
		player.global_position = enemy.global_position
		enemy._try_contact_damage()
		enemy._physics_process(0.51)
		if not player.has_status("poisoned"):
			failures.append("cave_slime contact should poison player")
	renderer.queue_free()
	player.queue_free()
	await process_frame

func _check_beast_herder_summons_and_enrages(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_entry("beast_herder", "miniboss", 40, 6)]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.MINIBOSS)
	await process_frame
	var herder := _first_enemy_id(renderer, "beast_herder")
	if herder == null:
		failures.append("beast_herder should spawn")
	else:
		if not herder.has_method("family_pattern"):
			failures.append("beast_herder should expose family_pattern")
		elif str(herder.call("family_pattern")) != "summon_enrage":
			failures.append("beast_herder family_pattern should advertise summon_enrage")
		var warning := herder.find_child("FamilyWarning", true, false) as Label
		if warning == null:
			failures.append("beast_herder should show a summon warning label")
		elif not warning.text.contains("SUMMON"):
			failures.append("beast_herder summon warning should name summons")
		if _family_minion_count(renderer, "beast_herder") < 2:
			failures.append("beast_herder should summon two biome minions")
		var minion := _first_family_minion(renderer, "beast_herder")
		var minion_speed := minion.speed if minion != null else 0.0
		var minion_damage := minion.contact_damage if minion != null else 0
		var herder_speed := herder.speed
		var herder_damage := herder.contact_damage
		herder.take_damage(25)
		if not bool(herder.get_meta("family_enraged", false)):
			failures.append("beast_herder should enrage below 50% hp")
		if herder.speed <= herder_speed or herder.contact_damage <= herder_damage:
			failures.append("beast_herder enrage should boost self")
		warning = herder.find_child("FamilyWarning", true, false) as Label
		if warning == null or not warning.text.contains("ENRAGE"):
			failures.append("beast_herder enrage warning should name enrage state")
		if minion != null:
			if not bool(minion.get_meta("beast_herder_buffed", false)):
				failures.append("beast_herder enrage should buff summoned minions")
			if minion.speed <= minion_speed or minion.contact_damage <= minion_damage:
				failures.append("beast_herder buff should raise minion speed and damage")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_spore_matriarch_summons_and_poisons(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_entry("spore_matriarch", "miniboss", 60, 8)]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.MINIBOSS)
	await process_frame
	var matriarch := _first_enemy_id(renderer, "spore_matriarch")
	if matriarch == null:
		failures.append("spore_matriarch should spawn")
	else:
		if str(matriarch.call("family_pattern")) != "summon_poison_enrage":
			failures.append("spore_matriarch should advertise summon_poison_enrage pattern")
		var warning := matriarch.find_child("FamilyWarning", true, false) as Label
		if warning == null or not warning.text.contains("SPORE"):
			failures.append("spore_matriarch warning should name spore summons")
		if _family_minion_count(renderer, "spore_matriarch") < 3:
			failures.append("spore_matriarch should summon three sporelings")
		dummy.global_position = matriarch.global_position + Vector2(8, 0)
		matriarch.take_damage(40)
		if not bool(matriarch.get_meta("family_enraged", false)):
			failures.append("spore_matriarch should enrage below 50% hp")
		if not bool(matriarch.get_meta("spore_matriarch_bloomed", false)):
			failures.append("spore_matriarch enrage should expose poison bloom metadata")
		if not dummy.has_status("poisoned"):
			failures.append("spore_matriarch poison bloom should poison nearby player")
		warning = matriarch.find_child("FamilyWarning", true, false) as Label
		if warning == null or not warning.text.contains("POISON"):
			failures.append("spore_matriarch enrage warning should name poison bloom")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_forge_captain_buffs_and_charges(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_entry("forge_captain", "miniboss", 70, 9)]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.MINIBOSS)
	await process_frame
	var captain := _first_enemy_id(renderer, "forge_captain")
	if captain == null:
		failures.append("forge_captain should spawn")
	else:
		if str(captain.call("family_pattern")) != "buff_charge":
			failures.append("forge_captain should advertise buff_charge pattern")
		var warning := captain.find_child("FamilyWarning", true, false) as Label
		if warning == null or not warning.text.contains("GUARDS"):
			failures.append("forge_captain warning should name guard summons")
		if _family_minion_count(renderer, "forge_captain") < 2:
			failures.append("forge_captain should summon two forge guards")
		var guard := _first_family_minion(renderer, "forge_captain")
		var guard_speed := guard.speed if guard != null else 0.0
		var guard_damage := guard.contact_damage if guard != null else 0
		dummy.global_position = captain.global_position + Vector2(36, 0)
		captain.take_damage(45)
		if not bool(captain.get_meta("family_enraged", false)):
			failures.append("forge_captain should enrage below 50% hp")
		if guard != null:
			if not bool(guard.get_meta("forge_captain_buffed", false)):
				failures.append("forge_captain enrage should buff forge guards")
			if guard.speed <= guard_speed or guard.contact_damage <= guard_damage:
				failures.append("forge_captain buff should raise guard speed and damage")
		var charge_fx := _first_attack_fx(renderer, "forge_charge")
		if charge_fx == null:
			failures.append("forge_captain enrage should telegraph forge_charge")
		warning = captain.find_child("FamilyWarning", true, false) as Label
		if warning == null or not warning.text.contains("CHARGE"):
			failures.append("forge_captain enrage warning should name charge")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_archive_curator_chill_lattice(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [_entry("archive_curator", "miniboss", 90, 12)]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.MINIBOSS, {}, {
		"id": "crystal_archive",
		"name": "Crystal Archive",
		"enemy_hp_mult": 1.0,
		"enemy_damage_mult": 1.0,
		"enemy_speed_mult": 1.0,
	})
	await process_frame
	var curator := _first_enemy_id(renderer, "archive_curator")
	if curator == null:
		failures.append("archive_curator should spawn")
	else:
		if str(curator.call("family_pattern")) != "summon_chill_lattice":
			failures.append("archive_curator should advertise summon_chill_lattice pattern")
		var warning := curator.find_child("FamilyWarning", true, false) as Label
		if warning == null or not warning.text.contains("CONSTRUCTS"):
			failures.append("archive_curator warning should name archive constructs")
		if _family_minion_count(renderer, "archive_curator") < 3:
			failures.append("archive_curator should summon three archive constructs")
		dummy.global_position = curator.global_position + Vector2(24, 0)
		curator.take_damage(50)
		if not bool(curator.get_meta("family_enraged", false)):
			failures.append("archive_curator should enrage below 50% hp")
		if not bool(curator.get_meta("archive_curator_lattice", false)):
			failures.append("archive_curator enrage should expose chill lattice metadata")
		if not dummy.has_status("chilled"):
			failures.append("archive_curator chill lattice should chill nearby player")
		if _first_attack_fx(renderer, "archive_lattice") == null:
			failures.append("archive_curator enrage should telegraph archive_lattice")
		warning = curator.find_child("FamilyWarning", true, false) as Label
		if warning == null or not warning.text.contains("LATTICE"):
			failures.append("archive_curator enrage warning should name lattice")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _basic_grid() -> TileGrid:
	var grid := TileGrid.new(12, 8, TileGrid.Tile.FLOOR)
	for x in grid.width:
		grid.set_tile(x, 0, TileGrid.Tile.WALL)
		grid.set_tile(x, grid.height - 1, TileGrid.Tile.WALL)
	for y in grid.height:
		grid.set_tile(0, y, TileGrid.Tile.WALL)
		grid.set_tile(grid.width - 1, y, TileGrid.Tile.WALL)
	grid.set_tile(5, 0, TileGrid.Tile.DOOR)
	grid.set_tile(6, 0, TileGrid.Tile.DOOR)
	return grid

func _entry(enemy_id: String, kind: String, hp: int = 10, dmg: int = 2) -> Dictionary:
	return {
		"enemy": {"id": enemy_id, "kind": kind, "hp": hp, "dmg": dmg},
		"wave": 1,
		"tile": Vector2i(4, 4),
		"elite": false,
		"modifier": "",
	}

func _first_enemy(parent: Node) -> Enemy:
	for child in parent.get_children():
		if child is Enemy:
			return child
	return null

func _first_enemy_id(parent: Node, enemy_id: String) -> Enemy:
	for child in parent.get_children():
		if child is Enemy and str(child.get_meta("enemy_id", "")) == enemy_id:
			return child
	return null

func _enemy_count(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is Enemy:
			count += 1
	return count

func _family_minion_count(parent: Node, source: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child is Enemy and str(child.get_meta("family_minion", "")) == source:
			count += 1
	return count

func _first_family_minion(parent: Node, source: String) -> Enemy:
	for child in parent.get_children():
		if child is Enemy and str(child.get_meta("family_minion", "")) == source:
			return child
	return null

func _first_projectile(parent: Node) -> EnemyProjectile:
	for child in parent.get_children():
		if child is EnemyProjectile:
			return child
	return null

func _projectile_count(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is EnemyProjectile:
			count += 1
	return count

func _has_projectile_attack(parent: Node, attack_id: String) -> bool:
	for child in parent.get_children():
		if child is EnemyProjectile and str(child.get_meta("enemy_attack", "")) == attack_id:
			return true
	return false

func _first_attack_fx(parent: Node, attack_id: String) -> Node:
	for child in parent.get_children():
		if child.has_meta("enemy_attack") and str(child.get_meta("enemy_attack", "")) == attack_id:
			return child
		var nested := _first_attack_fx(child, attack_id)
		if nested != null:
			return nested
	return null

func scene_root_add(node: Node) -> void:
	root.add_child(node)
