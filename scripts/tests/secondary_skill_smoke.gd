extends SceneTree

const SkillRunnerScript := preload("res://scripts/skills/skill_runner.gd")
const TrapScript := preload("res://scripts/rooms/trap.gd")

const SECONDARY_SKILLS := [
	{"class": "blade_warden", "id": "lunge"},
	{"class": "breaker", "id": "iron_will"},
	{"class": "nightblade", "id": "poison_knife"},
	{"class": "bulwark", "id": "battle_roar"},
	{"class": "arcanist", "id": "null_ring"},
	{"class": "ranger", "id": "snare_trap"},
	{"class": "gunner", "id": "special_rounds"},
	{"class": "soulbinder", "id": "sacrifice"},
	{"class": "lightkeeper", "id": "sanctuary"},
	{"class": "tinkerer", "id": "hack"},
]

func _init() -> void:
	var failures: Array[String] = []

	_check_input_and_registration(failures)
	await _check_second_slot_loads_from_class_data(failures)
	await _check_player_alt_skill_cast_path(failures)
	await _check_secondary_skill_behaviors(failures)

	if failures.is_empty():
		print("Secondary skill smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_input_and_registration(failures: Array[String]) -> void:
	var project_source := FileAccess.get_file_as_string("res://project.godot")
	if not project_source.contains("skill_alt={"):
		failures.append("project input map should include skill_alt action")
	for item in SECONDARY_SKILLS:
		var skill_id := str(item["id"])
		if not SkillRunnerScript.has_skill(skill_id):
			failures.append("SkillRunner missing secondary skill %s" % skill_id)
		if not ResourceLoader.exists("res://scripts/skills/%s_skill.gd" % skill_id):
			failures.append("secondary skill script missing for %s" % skill_id)

func _check_second_slot_loads_from_class_data(failures: Array[String]) -> void:
	var scene := _make_scene("SecondarySlotScene")
	for item in SECONDARY_SKILLS:
		var class_id := str(item["class"])
		var player := await _make_player(scene, class_id)
		var skill_alt = player.get("skill_alt")
		if not (skill_alt is Dictionary) or str(skill_alt.get("id", "")) != str(item["id"]):
			failures.append("%s should load actives[1] into skill_alt" % class_id)
		player.queue_free()
		await process_frame
	scene.queue_free()
	await process_frame

func _check_player_alt_skill_cast_path(failures: Array[String]) -> void:
	var scene := _make_scene("SecondaryCastPathScene")
	var player := await _make_player(scene, "blade_warden")
	var enemy := await _make_enemy(scene, Vector2(36, 0), 100)
	if not player.has_method("_try_skill_alt"):
		failures.append("Player should expose _try_skill_alt for secondary active")
	else:
		var before_pos := player.global_position
		var seen := {"cast": false, "cooldown": false}
		player.skill_cast.connect(func(id: String, cooldown: float) -> void:
			if id == "lunge" and cooldown > 0.0:
				seen["cast"] = true)
		player.skill_cooldown_changed.connect(func(id: String, left: float, total: float) -> void:
			if id == "lunge" and left > 0.0 and total > 0.0:
				seen["cooldown"] = true)
		player.call("_try_skill_alt")
		await process_frame
		if enemy.hp >= 100 and player.global_position.distance_to(before_pos) <= 1.0:
			failures.append("lunge alt cast should move forward or damage line enemy")
		if not bool(seen["cast"]):
			failures.append("secondary skill should emit skill_cast")
		if not bool(seen["cooldown"]):
			failures.append("secondary skill should emit cooldown feedback")
	scene.queue_free()
	await process_frame

func _check_secondary_skill_behaviors(failures: Array[String]) -> void:
	await _check_lunge(failures)
	await _check_iron_will(failures)
	await _check_poison_knife(failures)
	await _check_battle_roar(failures)
	await _check_null_ring(failures)
	await _check_snare_trap(failures)
	await _check_special_rounds(failures)
	await _check_sacrifice(failures)
	await _check_sanctuary(failures)
	await _check_hack(failures)

func _check_lunge(failures: Array[String]) -> void:
	var scene := _make_scene("LungeSkillScene")
	var player := await _make_player(scene, "blade_warden")
	var enemy := await _make_enemy(scene, Vector2(44, 0), 100)
	_execute_secondary("lunge", player, scene)
	await process_frame
	if player.global_position.x < 40.0:
		failures.append("lunge should dash the player forward")
	if enemy.hp >= 100:
		failures.append("lunge should damage enemies along the dash lane")
	var trail := scene.get_node_or_null("LungeTrailFx") as Line2D
	if trail == null:
		failures.append("lunge should spawn a readable dash trail VFX")
	else:
		if str(trail.get_meta("skill_id", "")) != "lunge":
			failures.append("lunge trail should tag skill_id")
		if str(trail.get_meta("shape", "")) != "dash_trail":
			failures.append("lunge trail should identify dash_trail shape")
		if float(trail.get_meta("distance_px", 0.0)) < 64.0:
			failures.append("lunge trail should expose distance metadata")
		if float(trail.get_meta("lane_width_px", 0.0)) < 12.0:
			failures.append("lunge trail should expose lane width metadata")
		if int(trail.get_meta("damage", 0)) <= 0:
			failures.append("lunge trail should expose damage metadata")
		if str(trail.get_meta("element", "")) != "fire":
			failures.append("lunge trail should expose element metadata")
	scene.queue_free()
	await process_frame

func _check_iron_will(failures: Array[String]) -> void:
	var scene := _make_scene("IronWillSkillScene")
	var player := await _make_player(scene, "breaker")
	_execute_secondary("iron_will", player, scene)
	await process_frame
	if not player.is_invulnerable() or not bool(player.get_meta("iron_will_active", false)):
		failures.append("iron_will should grant temporary hyper armor")
	if float(player.get_meta("iron_will_duration_seconds", 0.0)) < 3.0:
		failures.append("iron_will should expose its 3s duration")
	var feedback := player.get_node_or_null("IronWillFeedback") as Label
	if feedback == null:
		failures.append("iron_will should show readable duration feedback")
	elif not feedback.text.contains("IRON WILL") or not feedback.text.contains("3s"):
		failures.append("iron_will feedback should say IRON WILL and show duration")
	var expire_timer := player.get_node_or_null("IronWillExpireTimer") as Timer
	if expire_timer == null:
		failures.append("iron_will should attach a named expiry timer")
	else:
		if not is_equal_approx(expire_timer.wait_time, 3.0) or not expire_timer.one_shot:
			failures.append("iron_will expiry timer should run once for 3s")
		expire_timer.emit_signal("timeout")
		await process_frame
		if player.has_meta("iron_will_active"):
			failures.append("iron_will should clear active metadata after expiry")
		if player.get_node_or_null("IronWillFeedback") != null:
			failures.append("iron_will should remove feedback after expiry")
	player.shield_duration_mult = 1.5
	_execute_secondary("iron_will", player, scene)
	await process_frame
	if float(player.get_meta("iron_will_duration_seconds", 0.0)) < 4.5:
		failures.append("aegis shield duration should extend iron_will duration")
	expire_timer = player.get_node_or_null("IronWillExpireTimer") as Timer
	if expire_timer == null or not is_equal_approx(expire_timer.wait_time, 4.5):
		failures.append("aegis shield duration should extend iron_will expiry timer")
	feedback = player.get_node_or_null("IronWillFeedback") as Label
	if feedback == null or not feedback.text.contains("4.5s"):
		failures.append("iron_will feedback should show aegis-extended duration")
	scene.queue_free()
	await process_frame

func _check_poison_knife(failures: Array[String]) -> void:
	var scene := _make_scene("PoisonKnifeSkillScene")
	var player := await _make_player(scene, "nightblade")
	var enemy := await _make_enemy(scene, Vector2(54, 0), 100)
	_execute_secondary("poison_knife", player, scene)
	await process_frame
	if enemy.hp >= 100:
		failures.append("poison_knife should damage the aimed target")
	if not _enemy_has_status(enemy, "poison") or not _enemy_has_status(enemy, "vulnerable"):
		failures.append("poison_knife should poison and mark the target")
	if float(enemy.get_meta("poison_knife_mark_duration_seconds", 0.0)) < 3.0:
		failures.append("poison_knife should expose its 3s mark duration")
	var feedback := enemy.get_node_or_null("PoisonKnifeMarkFeedback") as Label
	if feedback == null:
		failures.append("poison_knife should show readable target mark feedback")
	elif not feedback.text.contains("MARKED") or not feedback.text.contains("3s"):
		failures.append("poison_knife feedback should say MARKED and show duration")
	var expire_timer := enemy.get_node_or_null("PoisonKnifeMarkExpireTimer") as Timer
	if expire_timer == null:
		failures.append("poison_knife should attach a named mark expiry timer")
	else:
		if not is_equal_approx(expire_timer.wait_time, 3.0) or not expire_timer.one_shot:
			failures.append("poison_knife mark expiry timer should run once for 3s")
		expire_timer.emit_signal("timeout")
		await process_frame
		if enemy.has_meta("poison_knife_mark_duration_seconds"):
			failures.append("poison_knife should clear mark metadata after expiry")
		if enemy.get_node_or_null("PoisonKnifeMarkFeedback") != null:
			failures.append("poison_knife should remove mark feedback after expiry")
	scene.queue_free()
	await process_frame

func _check_battle_roar(failures: Array[String]) -> void:
	var scene := _make_scene("BattleRoarSkillScene")
	var player := await _make_player(scene, "bulwark")
	var enemy := await _make_enemy(scene, Vector2(42, 0), 100)
	_execute_secondary("battle_roar", player, scene)
	await process_frame
	if not _enemy_has_status(enemy, "taunted") or enemy.target != player:
		failures.append("battle_roar should taunt nearby enemies")
	if int(player.get_meta("temporary_armor", 0)) < 2:
		failures.append("battle_roar should grant temporary armor")
	if float(player.get_meta("temporary_armor_duration_seconds", 0.0)) < 3.0:
		failures.append("battle_roar should expose its 3s armor duration")
	var feedback := player.get_node_or_null("BattleRoarFeedback") as Label
	if feedback == null:
		failures.append("battle_roar should show readable armor feedback")
	elif not feedback.text.contains("ARMOR") or not feedback.text.contains("3s"):
		failures.append("battle_roar feedback should name armor and show duration")
	var expire_timer := player.get_node_or_null("BattleRoarExpireTimer") as Timer
	if expire_timer == null:
		failures.append("battle_roar should attach a named expiry timer")
	else:
		if not is_equal_approx(expire_timer.wait_time, 3.0) or not expire_timer.one_shot:
			failures.append("battle_roar expiry timer should run once for 3s")
		expire_timer.emit_signal("timeout")
		await process_frame
		if int(player.get_meta("temporary_armor", 0)) > 0:
			failures.append("battle_roar should remove temporary armor after expiry")
		if player.get_node_or_null("BattleRoarFeedback") != null:
			failures.append("battle_roar should remove feedback after expiry")
	player.shield_duration_mult = 1.5
	_execute_secondary("battle_roar", player, scene)
	await process_frame
	if float(player.get_meta("temporary_armor_duration_seconds", 0.0)) < 4.5:
		failures.append("aegis shield duration should extend battle_roar armor duration")
	expire_timer = player.get_node_or_null("BattleRoarExpireTimer") as Timer
	if expire_timer == null or not is_equal_approx(expire_timer.wait_time, 4.5):
		failures.append("aegis shield duration should extend battle_roar expiry timer")
	feedback = player.get_node_or_null("BattleRoarFeedback") as Label
	if feedback == null or not feedback.text.contains("4.5s"):
		failures.append("battle_roar feedback should show aegis-extended duration")
	scene.queue_free()
	await process_frame

func _check_null_ring(failures: Array[String]) -> void:
	var scene := _make_scene("NullRingSkillScene")
	var player := await _make_player(scene, "arcanist")
	_execute_secondary("null_ring", player, scene)
	await process_frame
	if _child_group_count(scene, "player_zones") == 0:
		failures.append("null_ring should spawn a player zone")
	var zone := _first_group_node(scene, "player_zones")
	if zone == null:
		failures.append("null_ring should expose a spawned zone node")
	else:
		if float(zone.get_meta("duration_seconds", 0.0)) < 4.0:
			failures.append("null_ring zone should expose its 4s duration")
		var fx := zone.get_node_or_null("NullRingFx") as Line2D
		if fx == null:
			failures.append("null_ring should spawn a readable ring VFX")
		else:
			if str(fx.get_meta("skill_id", "")) != "null_ring":
				failures.append("null_ring VFX should tag skill_id")
			if str(fx.get_meta("shape", "")) != "control_ring":
				failures.append("null_ring VFX should identify control_ring shape")
			if float(fx.get_meta("radius_px", 0.0)) < 72.0:
				failures.append("null_ring VFX should expose radius metadata")
			if float(fx.get_meta("duration_seconds", 0.0)) < 4.0:
				failures.append("null_ring VFX should expose duration metadata")
			if str(fx.get_meta("effect", "")) != "projectile_slow":
				failures.append("null_ring VFX should expose projectile slow effect metadata")
		var feedback := zone.get_node_or_null("NullRingFeedback") as Label
		if feedback == null:
			failures.append("null_ring should show readable duration feedback")
		elif not feedback.text.contains("NULL RING") or not feedback.text.contains("4s"):
			failures.append("null_ring feedback should say NULL RING and show duration")
		var expire_timer := zone.get_node_or_null("NullRingExpireTimer") as Timer
		if expire_timer == null:
			failures.append("null_ring should expose a named expiry timer")
		else:
			if not is_equal_approx(expire_timer.wait_time, 4.0) or not expire_timer.one_shot:
				failures.append("null_ring expiry timer should run once for 4s")
			expire_timer.emit_signal("timeout")
			await process_frame
			if is_instance_valid(zone) and not zone.is_queued_for_deletion():
				failures.append("null_ring zone should queue_free after expiry")
	scene.queue_free()
	await process_frame

func _check_snare_trap(failures: Array[String]) -> void:
	var scene := _make_scene("SnareTrapSkillScene")
	var player := await _make_player(scene, "ranger")
	var enemy := await _make_enemy(scene, Vector2(64, 0), 100)
	_execute_secondary("snare_trap", player, scene)
	await process_frame
	if _child_group_count(scene, "player_traps") == 0:
		failures.append("snare_trap should place a player trap")
	var placed_trap := _first_group_node(scene, "player_traps")
	if placed_trap == null:
		failures.append("snare_trap should expose placed trap node")
	else:
		if float(placed_trap.get_meta("root_duration_seconds", 0.0)) < 1.5:
			failures.append("snare_trap should expose its 1.5s root duration")
		if float(placed_trap.get_meta("duration_seconds", 0.0)) < 12.0:
			failures.append("snare_trap should expose its 12s trap duration")
		var feedback := placed_trap.get_node_or_null("SnareTrapFeedback") as Label
		if feedback == null:
			failures.append("snare_trap should show readable trap feedback")
		elif not feedback.text.contains("SNARE") or not feedback.text.contains("12s"):
			failures.append("snare_trap feedback should say SNARE and show duration")
		var expire_timer := placed_trap.get_node_or_null("SnareTrapExpireTimer") as Timer
		if expire_timer == null:
			failures.append("snare_trap should attach a named expiry timer")
		elif not is_equal_approx(expire_timer.wait_time, 12.0) or not expire_timer.one_shot:
			failures.append("snare_trap expiry timer should run once for 12s")
		_assert_sprite_visual(placed_trap, "SnareTrapSprite", "floor_spikes_anim", 4, "snare_trap", failures)
	for trap in scene.get_tree().get_nodes_in_group("player_traps"):
		if trap.has_method("trigger"):
			trap.call("trigger", enemy)
	if not _enemy_has_status(enemy, "rooted"):
		failures.append("snare_trap should root triggered enemies")
	scene.queue_free()
	await process_frame

	scene = _make_scene("SnareTrapLimitScene")
	player = await _make_player(scene, "ranger")
	_execute_secondary("snare_trap", player, scene)
	await process_frame
	var first_trap := _first_group_node(scene, "player_traps")
	_execute_secondary("snare_trap", player, scene)
	await process_frame
	_execute_secondary("snare_trap", player, scene)
	await process_frame
	if _child_group_count(scene, "player_traps") != 2:
		failures.append("snare_trap should keep at most two placed traps")
	if first_trap != null and is_instance_valid(first_trap) and not first_trap.is_queued_for_deletion():
		failures.append("snare_trap should remove the oldest trap when placing a third")
	scene.queue_free()
	await process_frame

func _check_special_rounds(failures: Array[String]) -> void:
	var scene := _make_scene("SpecialRoundsSkillScene")
	var player := await _make_player(scene, "gunner")
	player.pickup_weapon("scrap_pistol")
	_execute_secondary("special_rounds", player, scene)
	await process_frame
	if int(player.get_meta("special_rounds_left", 0)) <= 0:
		failures.append("special_rounds should arm elemental piercing shots")
	var weapon := player.current_weapon()
	if weapon == null or int(weapon.projectile_pierce_count()) <= 0:
		failures.append("special_rounds should add projectile pierce while armed")
	var feedback := player.get_node_or_null("SpecialRoundsFeedback") as Label
	if feedback == null:
		failures.append("special_rounds should show readable magazine feedback")
	elif not feedback.text.contains("ROUNDS") or not feedback.text.contains("6"):
		failures.append("special_rounds feedback should show armed shots")
	if weapon != null:
		weapon.set("_cd_left", 0.0)
		weapon.try_attack(player.global_position, Vector2.RIGHT)
		await process_frame
		if int(player.get_meta("special_rounds_left", 0)) != 5:
			failures.append("special_rounds should consume one round per ranged attack")
		feedback = player.get_node_or_null("SpecialRoundsFeedback") as Label
		if feedback == null or not feedback.text.contains("5"):
			failures.append("special_rounds feedback should update remaining shots")
		for i in 5:
			weapon.set("_cd_left", 0.0)
			weapon.try_attack(player.global_position, Vector2.RIGHT)
			await process_frame
		if int(player.get_meta("special_rounds_left", 0)) > 0 or player.has_meta("special_rounds_element"):
			failures.append("special_rounds should clear armed metadata after the last shot")
		if player.get_node_or_null("SpecialRoundsFeedback") != null:
			failures.append("special_rounds should remove feedback after the last shot")
	scene.queue_free()
	await process_frame

func _check_sacrifice(failures: Array[String]) -> void:
	var scene := _make_scene("SacrificeSkillScene")
	var player := await _make_player(scene, "soulbinder")
	var pet := Node2D.new()
	pet.name = "SacrificeWisp"
	pet.add_to_group("player_summons")
	scene.add_child(pet)
	pet.global_position = Vector2(8, 0)
	var enemy := await _make_enemy(scene, Vector2(18, 0), 100)
	player.resource = 0.0
	_execute_secondary("sacrifice", player, scene)
	await process_frame
	if enemy.hp >= 100:
		failures.append("sacrifice should detonate a pet for AoE damage")
	if player.resource < 15.0:
		failures.append("sacrifice should restore mana")
	if is_instance_valid(pet) and not pet.is_queued_for_deletion():
		failures.append("sacrifice should consume one pet")
	var fx := scene.get_node_or_null("SacrificeFx") as Line2D
	if fx == null:
		failures.append("sacrifice should spawn a readable sacrifice burst VFX")
	else:
		if str(fx.get_meta("skill_id", "")) != "sacrifice":
			failures.append("sacrifice VFX should tag skill_id")
		if str(fx.get_meta("shape", "")) != "sacrifice_burst":
			failures.append("sacrifice VFX should identify sacrifice_burst shape")
		if float(fx.get_meta("radius_px", 0.0)) < 54.0:
			failures.append("sacrifice VFX should expose radius metadata")
		if int(fx.get_meta("damage", 0)) <= 0:
			failures.append("sacrifice VFX should expose damage metadata")
		if float(fx.get_meta("mana_restore", 0.0)) < 15.0:
			failures.append("sacrifice VFX should expose mana restore metadata")
		if str(fx.get_meta("element", "")) != "fire":
			failures.append("sacrifice VFX should expose element metadata")
	scene.queue_free()
	await process_frame

func _check_sanctuary(failures: Array[String]) -> void:
	var scene := _make_scene("SanctuarySkillScene")
	var player := await _make_player(scene, "lightkeeper")
	player.hp = 40
	player.add_status("poisoned", 4.0)
	_execute_secondary("sanctuary", player, scene)
	await process_frame
	if player.hp <= 40:
		failures.append("sanctuary should heal immediately")
	if player.has_status("poisoned"):
		failures.append("sanctuary should purge debuffs")
	if _child_group_count(scene, "player_zones") == 0:
		failures.append("sanctuary should spawn a healing zone")
	var zone := _first_group_node(scene, "player_zones")
	if zone == null:
		failures.append("sanctuary should expose a spawned zone node")
	else:
		if float(zone.get_meta("duration_seconds", 0.0)) < 5.0:
			failures.append("sanctuary zone should expose its 5s duration")
		var fx := zone.get_node_or_null("SanctuaryFx") as Line2D
		if fx == null:
			failures.append("sanctuary should spawn a readable healing ring VFX")
		else:
			if str(fx.get_meta("skill_id", "")) != "sanctuary":
				failures.append("sanctuary VFX should tag skill_id")
			if str(fx.get_meta("shape", "")) != "healing_ring":
				failures.append("sanctuary VFX should identify healing_ring shape")
			if float(fx.get_meta("radius_px", 0.0)) < 54.0:
				failures.append("sanctuary VFX should expose radius metadata")
			if float(fx.get_meta("duration_seconds", 0.0)) < 5.0:
				failures.append("sanctuary VFX should expose duration metadata")
			if str(fx.get_meta("effect", "")) != "heal_and_cleanse":
				failures.append("sanctuary VFX should expose heal/cleanse effect metadata")
		var feedback := zone.get_node_or_null("SanctuaryFeedback") as Label
		if feedback == null:
			failures.append("sanctuary zone should show readable duration feedback")
		elif not feedback.text.contains("SANCTUARY") or not feedback.text.contains("5s"):
			failures.append("sanctuary feedback should say SANCTUARY and show duration")
		player.hp = 50
		var tick_timer := zone.get_node_or_null("SanctuaryHealTimer") as Timer
		if tick_timer == null:
			failures.append("sanctuary should expose a named heal tick timer")
		else:
			tick_timer.emit_signal("timeout")
			await process_frame
			if player.hp <= 50:
				failures.append("sanctuary should heal the player each tick while inside")
		var expire_timer := zone.get_node_or_null("SanctuaryExpireTimer") as Timer
		if expire_timer == null:
			failures.append("sanctuary should expose a named expiry timer")
		else:
			if not is_equal_approx(expire_timer.wait_time, 5.0) or not expire_timer.one_shot:
				failures.append("sanctuary expiry timer should run once for 5s")
			expire_timer.emit_signal("timeout")
			await process_frame
			if is_instance_valid(zone) and not zone.is_queued_for_deletion():
				failures.append("sanctuary zone should queue_free after expiry")
	scene.queue_free()
	await process_frame

func _check_hack(failures: Array[String]) -> void:
	var scene := _make_scene("HackSkillScene")
	var player := await _make_player(scene, "tinkerer")
	var trap := TrapScript.new()
	trap.configure("spike", 8, 0.5, 0.1)
	scene.add_child(trap)
	trap.global_position = Vector2(20, 0)
	_execute_secondary("hack", player, scene)
	await process_frame
	if not bool(trap.get_meta("hacked", false)) or not trap.is_in_group("player_traps"):
		failures.append("hack should convert a nearby trap to allied")
	if float(trap.get_meta("hack_duration_seconds", 0.0)) < 10.0:
		failures.append("hack should expose its 10s trap disable duration")
	var feedback := trap.get_node_or_null("HackFeedback") as Label
	if feedback == null:
		failures.append("hack should show readable feedback on converted trap")
	elif not feedback.text.contains("HACKED") or not feedback.text.contains("10s"):
		failures.append("hack feedback should say HACKED and show duration")
	var expire_timer := trap.get_node_or_null("HackExpireTimer") as Timer
	if expire_timer == null:
		failures.append("hack should attach an expiry timer")
	else:
		if not is_equal_approx(expire_timer.wait_time, 10.0) or not expire_timer.one_shot:
			failures.append("hack expiry timer should run once for 10s")
		expire_timer.emit_signal("timeout")
		await process_frame
		if bool(trap.get_meta("hacked", false)):
			failures.append("hack should clear hacked metadata after expiry")
		if trap.is_in_group("player_traps") or not trap.is_in_group("room_traps"):
			failures.append("hack should restore trap ownership after expiry")
		if trap.get_node_or_null("HackFeedback") != null:
			failures.append("hack should remove feedback after expiry")
	scene.queue_free()
	await process_frame

func _execute_secondary(skill_id: String, player: Player, scene: Node) -> void:
	if not SkillRunnerScript.has_skill(skill_id):
		return
	SkillRunnerScript.execute(skill_id, {
		"player": player,
		"skill": {"id": skill_id, "cost": 0, "cooldown": 0.1},
		"base_damage": 30,
		"aim_dir": Vector2.RIGHT,
		"target_position": player.global_position + Vector2(64, 0),
		"element": player.equipped_element,
		"pet_damage_mult": player.pet_damage_multiplier(),
		"shield_duration_mult": player.shield_duration_mult,
		"scene": scene,
	})

func _make_scene(name: String) -> Node2D:
	var scene := Node2D.new()
	scene.name = name
	root.add_child(scene)
	current_scene = scene
	return scene

func _make_player(scene: Node2D, class_id: String) -> Player:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	scene.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data(class_id), "fire", "warden_sword")
	player.resource = 999.0
	player.global_position = Vector2.ZERO
	return player

func _make_enemy(scene: Node2D, pos: Vector2, hp: int) -> Enemy:
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.max_hp = hp
	enemy.global_position = pos
	scene.add_child(enemy)
	await process_frame
	enemy.hp = hp
	return enemy

func _child_group_count(parent: Node, group_name: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.is_in_group(group_name):
			count += 1
	return count

func _first_group_node(parent: Node, group_name: String) -> Node:
	for child in parent.get_children():
		if child.is_in_group(group_name):
			return child
	return null

func _assert_sprite_visual(
		parent: Node,
		node_name: String,
		sprite_name: String,
		expected_frames: int,
		label: String,
		failures: Array[String],
) -> void:
	var sprite := parent.get_node_or_null(node_name) as AnimatedSprite2D
	if sprite == null or not sprite.visible:
		failures.append("%s should use %s sprite visual" % [label, node_name])
		return
	var report := SpriteDB.animation_report(sprite_name)
	if str(sprite.get_meta("sprite_name", "")) != sprite_name:
		failures.append("%s sprite metadata should name %s" % [label, sprite_name])
	if int(sprite.get_meta("frame_count", 0)) != expected_frames:
		failures.append("%s sprite should store %d frame count metadata" % [label, expected_frames])
	if int(report.get("frame_count", 0)) != expected_frames:
		failures.append("%s source animation should report %d frames" % [label, expected_frames])
	if not bool(sprite.get_meta("stable_size", false)) or not bool(report.get("stable_size", false)):
		failures.append("%s sprite should expose stable frame grid metadata" % label)
	if not bool(sprite.get_meta("frame_grid_ok", false)):
		failures.append("%s sprite should pass frame grid review" % label)
	if not bool(sprite.get_meta("animation_stability_reviewed", false)):
		failures.append("%s sprite should expose animation stability review metadata" % label)
	if not bool(sprite.get_meta("motion_reviewed", false)):
		failures.append("%s sprite should expose motion review metadata" % label)
	if not bool(sprite.get_meta("origin_alignment_reviewed", false)):
		failures.append("%s sprite should expose origin alignment review metadata" % label)
	if str(sprite.get_meta("asset_source", "")) == "":
		failures.append("%s sprite should expose asset source metadata" % label)
	if str(sprite.get_meta("release_decision", "")) != "public_ok":
		failures.append("%s sprite should be public_ok for release" % label)
	if bool(sprite.get_meta("needs_replacement_before_public", true)):
		failures.append("%s sprite should not need replacement before public release" % label)
	for child in parent.get_children():
		if child is Polygon2D and child.visible:
			failures.append("%s should hide polygon placeholder when sprite exists" % label)

func _enemy_has_status(enemy: Enemy, status_name: String) -> bool:
	var statuses = enemy.get("_statuses")
	return statuses is Dictionary and statuses.has(status_name)
