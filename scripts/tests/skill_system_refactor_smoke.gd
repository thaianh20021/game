extends SceneTree

const SkillRunnerScript := preload("res://scripts/skills/skill_runner.gd")
const SummonWispSkillScript := preload("res://scripts/skills/summon_wisp_skill.gd")
const MiniTurretSkillScript := preload("res://scripts/skills/mini_turret_skill.gd")

const REMAINING_SKILLS := [
	"earthbreaker",
	"shadow_step",
	"shield_bastion",
	"rolling_grenade",
	"summon_wisp",
	"light_ray",
	"mini_turret",
]

func _init() -> void:
	var failures: Array[String] = []

	_check_skill_files(failures)
	await _check_wind_edge_behavior(failures)
	await _check_element_orb_behavior(failures)
	await _check_arrow_rain_behavior(failures)
	await _check_remaining_skill_behaviors(failures)

	if failures.is_empty():
		print("Skill system refactor smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_skill_files(failures: Array[String]) -> void:
	for path in [
		"res://scripts/skills/skill_runner.gd",
		"res://scripts/skills/wind_edge_skill.gd",
		"res://scripts/skills/element_orb_skill.gd",
		"res://scripts/skills/arrow_rain_skill.gd",
	]:
		if not ResourceLoader.exists(path):
			failures.append("%s missing" % path)
	for id in ["wind_edge", "element_orb", "arrow_rain"] + REMAINING_SKILLS:
		if not SkillRunnerScript.has_skill(id):
			failures.append("SkillRunner missing %s" % id)
	var player_source := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	if player_source.contains('match str(skill.get("id", ""))'):
		failures.append("Player should delegate skill ids instead of matching them inline")

func _check_wind_edge_behavior(failures: Array[String]) -> void:
	var scene := _make_scene("SkillWindEdgeScene")
	var player := await _make_player(scene, "blade_warden")
	var enemy := await _make_enemy(scene, Vector2(24, 0), 100)

	player.skill = {"id": "wind_edge", "cost": 0, "cooldown": 0.1}
	player.call("_try_skill")
	await process_frame
	if enemy.hp >= 100:
		failures.append("wind_edge should still damage nearby enemies")
	var fx := scene.get_node_or_null("WindEdgeFx") as Line2D
	if fx == null:
		failures.append("wind_edge should spawn a readable slash arc VFX")
	else:
		if int(fx.get_meta("damage", 0)) <= 0:
			failures.append("wind_edge VFX should expose damage metadata")
		if str(fx.get_meta("element", "")) != "fire":
			failures.append("wind_edge VFX should expose element metadata")
		if float(fx.get_meta("radius_px", 0.0)) < 38.0:
			failures.append("wind_edge VFX should expose radius metadata")
		if str(fx.get_meta("shape", "")) != "slash_arc":
			failures.append("wind_edge VFX should identify slash_arc shape")
	scene.queue_free()
	await process_frame

func _check_remaining_skill_behaviors(failures: Array[String]) -> void:
	await _check_damage_skill("breaker", "earthbreaker", Vector2(24, 0),
		"earthbreaker should damage nearby enemies", failures)
	await _check_earthbreaker_visual(failures)
	await _check_shadow_step(failures)
	await _check_shield_bastion(failures)
	await _check_delayed_damage_skill("gunner", "rolling_grenade",
		"rolling_grenade should damage enemies near target zone", failures)
	await _check_rolling_grenade_visual(failures)
	await _check_summon_wisp(failures)
	await _check_light_ray(failures)
	await _check_mini_turret(failures)

func _check_damage_skill(
		class_id: String,
		skill_id: String,
		enemy_pos: Vector2,
		message: String,
		failures: Array[String],
) -> void:
	var scene := _make_scene("Skill%sScene" % skill_id)
	var player := await _make_player(scene, class_id)
	var enemy := await _make_enemy(scene, enemy_pos, 100)
	player.skill = {"id": skill_id, "cost": 0, "cooldown": 0.1}
	player.call("_try_skill")
	await process_frame
	if enemy.hp >= 100:
		failures.append(message)
	scene.queue_free()
	await process_frame

func _check_earthbreaker_visual(failures: Array[String]) -> void:
	var scene := _make_scene("SkillEarthbreakerVisualScene")
	var player := await _make_player(scene, "breaker")
	_execute_skill("earthbreaker", player, scene)
	await process_frame
	var fx := scene.get_node_or_null("EarthbreakerFx") as Line2D
	if fx == null:
		failures.append("earthbreaker should spawn a readable slam ring VFX")
	else:
		if str(fx.get_meta("skill_id", "")) != "earthbreaker":
			failures.append("earthbreaker VFX should tag skill_id")
		if str(fx.get_meta("shape", "")) != "slam_ring":
			failures.append("earthbreaker VFX should identify slam_ring shape")
		if float(fx.get_meta("radius_px", 0.0)) < 54.0:
			failures.append("earthbreaker VFX should expose radius metadata")
		if int(fx.get_meta("damage", 0)) <= 0:
			failures.append("earthbreaker VFX should expose damage metadata")
		if str(fx.get_meta("element", "")) != "fire":
			failures.append("earthbreaker VFX should expose element metadata")
	scene.queue_free()
	await process_frame

func _check_delayed_damage_skill(
		class_id: String,
		skill_id: String,
		message: String,
		failures: Array[String],
) -> void:
	var scene := _make_scene("Skill%sScene" % skill_id)
	var player := await _make_player(scene, class_id)
	var enemy := await _make_enemy(scene, player.get_global_mouse_position(), 100)
	player.skill = {"id": skill_id, "cost": 0, "cooldown": 0.1}
	player.call("_try_skill")
	await create_timer(0.45).timeout
	if enemy.hp >= 100:
		failures.append(message)
	scene.queue_free()
	await process_frame

func _check_rolling_grenade_visual(failures: Array[String]) -> void:
	var scene := _make_scene("SkillRollingGrenadeVisualScene")
	var player := await _make_player(scene, "gunner")
	_execute_skill("rolling_grenade", player, scene)
	await process_frame
	var grenade := _child_named(scene, "RollingGrenade")
	if grenade == null:
		failures.append("rolling_grenade should spawn a visible grenade marker")
	elif grenade is Polygon2D:
		failures.append("rolling_grenade should use bomb animation instead of polygon placeholder")
	elif not (grenade is AnimatedSprite2D):
		failures.append("rolling_grenade marker should be AnimatedSprite2D")
	else:
		var sprite := grenade as AnimatedSprite2D
		var report := SpriteDB.animation_report("bomb")
		if str(sprite.get_meta("sprite_name", "")) != "bomb":
			failures.append("rolling_grenade sprite metadata should name bomb")
		if int(sprite.get_meta("frame_count", 0)) != int(report.get("frame_count", 0)):
			failures.append("rolling_grenade sprite should store bomb frame count metadata")
		if not bool(sprite.get_meta("stable_size", false)):
			failures.append("rolling_grenade sprite should expose stable frame grid metadata")
		if not bool(sprite.get_meta("frame_grid_ok", false)):
			failures.append("rolling_grenade sprite should pass frame grid review")
		if not bool(sprite.get_meta("animation_stability_reviewed", false)):
			failures.append("rolling_grenade sprite should expose animation stability review metadata")
		if not bool(sprite.get_meta("motion_reviewed", false)):
			failures.append("rolling_grenade sprite should expose motion review metadata")
		if not bool(sprite.get_meta("origin_alignment_reviewed", false)):
			failures.append("rolling_grenade sprite should expose origin alignment review metadata")
		if str(sprite.get_meta("asset_source", "")) == "":
			failures.append("rolling_grenade sprite should expose asset source metadata")
		if str(sprite.get_meta("release_decision", "")) != "public_ok":
			failures.append("rolling_grenade sprite should be public_ok for release")
		if bool(sprite.get_meta("needs_replacement_before_public", true)):
			failures.append("rolling_grenade sprite should not need replacement before public release")
		if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("idle"):
			failures.append("rolling_grenade sprite should expose an idle animation")
		elif sprite.sprite_frames.get_frame_count("idle") != 3:
			failures.append("rolling_grenade bomb animation should use 3 frames")
	scene.queue_free()
	await process_frame

func _check_shadow_step(failures: Array[String]) -> void:
	var scene := _make_scene("SkillShadowStepScene")
	var player := await _make_player(scene, "nightblade")
	player.skill = {"id": "shadow_step", "cost": 0, "cooldown": 0.1}
	player.crit_chance = 0.0
	player.call("_try_skill")
	await process_frame
	if player.global_position.x <= 0.0 and not player.is_invulnerable():
		failures.append("shadow_step should move or grant invulnerability")
	if float(player.get_meta("shadow_step_duration_seconds", 0.0)) < 0.8:
		failures.append("shadow_step should expose its 0.8s evade duration")
	var feedback := player.get_node_or_null("ShadowStepFeedback") as Label
	if feedback == null:
		failures.append("shadow_step should show readable crit feedback")
	elif not feedback.text.contains("SHADOW STEP") or not feedback.text.contains("CRIT"):
		failures.append("shadow_step feedback should name the skill and next crit")
	var expire_timer := player.get_node_or_null("ShadowStepExpireTimer") as Timer
	if expire_timer == null:
		failures.append("shadow_step should attach a named feedback expiry timer")
	elif not is_equal_approx(expire_timer.wait_time, 0.8) or not expire_timer.one_shot:
		failures.append("shadow_step expiry timer should run once for 0.8s")
	if not bool(player.get_meta("guaranteed_crit", false)):
		failures.append("shadow_step should prime guaranteed crit for the next weapon hit")
	var weapon := player.current_weapon()
	if weapon != null:
		var base_damage := int(weapon.call("base_damage"))
		var first_roll := int(weapon.call("_roll_damage"))
		if first_roll < int(round(float(base_damage) * player.damage_mult * 1.49)):
			failures.append("shadow_step guaranteed crit should boost next weapon damage")
		if bool(player.get_meta("guaranteed_crit", false)):
			failures.append("shadow_step guaranteed crit should consume after one damage roll")
		var second_roll := int(weapon.call("_roll_damage"))
		if second_roll >= first_roll:
			failures.append("shadow_step guaranteed crit should not affect later weapon rolls")
	if expire_timer != null:
		expire_timer.emit_signal("timeout")
		await process_frame
		if player.has_meta("shadow_step_duration_seconds"):
			failures.append("shadow_step should clear duration metadata after expiry")
		if player.get_node_or_null("ShadowStepFeedback") != null:
			failures.append("shadow_step should remove feedback after expiry")
	scene.queue_free()
	await process_frame

func _check_shield_bastion(failures: Array[String]) -> void:
	var scene := _make_scene("SkillShieldBastionScene")
	var player := await _make_player(scene, "bulwark")
	player.skill = {"id": "shield_bastion", "cost": 0, "cooldown": 0.1}
	player.call("_try_skill")
	await process_frame
	if not player.is_invulnerable():
		failures.append("shield_bastion should grant invulnerability")
	if float(player.get_meta("shield_bastion_duration_seconds", 0.0)) < 1.5:
		failures.append("shield_bastion should expose its 1.5s shield duration")
	var feedback := player.get_node_or_null("ShieldBastionFeedback") as Label
	if feedback == null:
		failures.append("shield_bastion should show readable shield feedback")
	elif not feedback.text.contains("SHIELD") or not feedback.text.contains("1.5s"):
		failures.append("shield_bastion feedback should say SHIELD and show duration")
	var expire_timer := player.get_node_or_null("ShieldBastionExpireTimer") as Timer
	if expire_timer == null:
		failures.append("shield_bastion should attach a named feedback expiry timer")
	else:
		if not is_equal_approx(expire_timer.wait_time, 1.5) or not expire_timer.one_shot:
			failures.append("shield_bastion expiry timer should run once for 1.5s")
		expire_timer.emit_signal("timeout")
		await process_frame
		if player.has_meta("shield_bastion_duration_seconds"):
			failures.append("shield_bastion should clear duration metadata after expiry")
		if player.get_node_or_null("ShieldBastionFeedback") != null:
			failures.append("shield_bastion should remove feedback after expiry")
	scene.queue_free()
	await process_frame

func _check_light_ray(failures: Array[String]) -> void:
	var scene := _make_scene("SkillLightRayScene")
	var player := await _make_player(scene, "lightkeeper")
	var aim_dir := Vector2(player.call("_aim_dir"))
	var enemy := await _make_enemy(scene, player.global_position + aim_dir * 50.0, 100)
	player.skill = {"id": "light_ray", "cost": 0, "cooldown": 0.1}
	player.call("_try_skill")
	await process_frame
	if enemy.hp >= 100:
		failures.append("light_ray should damage enemies in aim line")
	var fx := scene.get_node_or_null("LightRayFx") as Line2D
	if fx == null:
		failures.append("light_ray should spawn a readable ray VFX")
	else:
		if str(fx.get_meta("skill_id", "")) != "light_ray":
			failures.append("light_ray VFX should tag skill_id")
		if str(fx.get_meta("shape", "")) != "aim_ray":
			failures.append("light_ray VFX should identify aim_ray shape")
		if float(fx.get_meta("range_px", 0.0)) < 135.0:
			failures.append("light_ray VFX should expose range metadata")
		if float(fx.get_meta("width_px", 0.0)) < 12.0:
			failures.append("light_ray VFX should expose width metadata")
		if int(fx.get_meta("damage", 0)) <= 0:
			failures.append("light_ray VFX should expose damage metadata")
		if str(fx.get_meta("element", "")) != "lightning":
			failures.append("light_ray VFX should expose element metadata")
	scene.queue_free()
	await process_frame

func _check_summon_wisp(failures: Array[String]) -> void:
	var scene := _make_scene("SkillSummonWispScene")
	var player := await _make_player(scene, "soulbinder")
	player.pet_damage_mult = 1.4
	_execute_skill("summon_wisp", player, scene)
	await process_frame
	var wisp := _first_group_node(scene, "player_summons")
	if wisp == null:
		failures.append("summon_wisp should spawn a player summon")
	else:
		if float(wisp.get_meta("duration_seconds", 0.0)) < 30.0:
			failures.append("summon_wisp should expose its 30s duration")
		var feedback := wisp.get_node_or_null("WispFeedback") as Label
		if feedback == null:
			failures.append("summon_wisp should show readable duration feedback")
		elif not feedback.text.contains("WISP") or not feedback.text.contains("30s"):
			failures.append("summon_wisp feedback should say WISP and show duration")
		elif not feedback.text.contains("DMG x1.4"):
			failures.append("summon_wisp feedback should show pet damage multiplier")
		if float(wisp.get_meta("pet_damage_mult", 0.0)) < 1.4:
			failures.append("summon_wisp should expose pet damage multiplier metadata")
		if int(wisp.get_meta("attack_damage", 0)) <= int(30 * 0.7):
			failures.append("summon_wisp should expose pet-scaled attack damage metadata")
		_assert_sprite_visual(wisp, "WispSprite", "angel_idle_anim", 4, "summon_wisp", failures)
		var enemy := await _make_enemy(scene, wisp.global_position + Vector2(24, 0), 100)
		SummonWispSkillScript._attack_nearest(wisp, player, 11, "fire")
		if enemy.hp >= 100:
			failures.append("summon_wisp pet attack should damage nearby enemies")
		if int(wisp.get_meta("attack_count", 0)) != 1:
			failures.append("summon_wisp pet attack should count fired attacks")
		if int(wisp.get_meta("last_target_id", 0)) != enemy.get_instance_id():
			failures.append("summon_wisp pet attack should record the target id")
		if wisp.get_node_or_null("PetAttackFeedback") == null:
			failures.append("summon_wisp pet attack should show readable attack feedback")
		_assert_attack_bolt(wisp, "PetAttackBolt", enemy.get_instance_id(), 11, "summon_wisp", failures)
		_assert_attack_sfx(wisp, "PetAttackSfx", enemy.get_instance_id(), 11, "fire",
			"summon_wisp", failures)
	scene.queue_free()
	await process_frame

func _check_mini_turret(failures: Array[String]) -> void:
	var scene := _make_scene("SkillMiniTurretScene")
	var player := await _make_player(scene, "tinkerer")
	player.pet_damage_mult = 1.4
	_execute_skill("mini_turret", player, scene)
	await process_frame
	var first_turret := _first_group_node(scene, "player_summons")
	if first_turret == null:
		failures.append("mini_turret should spawn a player summon")
	else:
		if float(first_turret.get_meta("duration_seconds", 0.0)) < 15.0:
			failures.append("mini_turret should expose its 15s duration")
		var feedback := first_turret.get_node_or_null("TurretFeedback") as Label
		if feedback == null:
			failures.append("mini_turret should show readable duration feedback")
		elif not feedback.text.contains("TURRET") or not feedback.text.contains("15s"):
			failures.append("mini_turret feedback should say TURRET and show duration")
		elif not feedback.text.contains("DMG x1.4"):
			failures.append("mini_turret feedback should show pet damage multiplier")
		if float(first_turret.get_meta("pet_damage_mult", 0.0)) < 1.4:
			failures.append("mini_turret should expose pet damage multiplier metadata")
		if int(first_turret.get_meta("attack_damage", 0)) <= int(30 * 0.55):
			failures.append("mini_turret should expose pet-scaled attack damage metadata")
		_assert_sprite_visual(first_turret, "TurretSprite", "weapon_bow_2", 1, "mini_turret", failures)
		var enemy := await _make_enemy(scene, first_turret.global_position + Vector2(28, 0), 100)
		MiniTurretSkillScript._attack_nearest(first_turret, player, 9, "fire")
		if enemy.hp >= 100:
			failures.append("mini_turret attack should damage nearby enemies")
		if int(first_turret.get_meta("attack_count", 0)) != 1:
			failures.append("mini_turret attack should count fired attacks")
		if int(first_turret.get_meta("last_target_id", 0)) != enemy.get_instance_id():
			failures.append("mini_turret attack should record the target id")
		if first_turret.get_node_or_null("TurretAttackFeedback") == null:
			failures.append("mini_turret attack should show readable attack feedback")
		_assert_attack_bolt(first_turret, "TurretAttackBolt", enemy.get_instance_id(), 9, "mini_turret", failures)
		_assert_attack_sfx(first_turret, "TurretAttackSfx", enemy.get_instance_id(), 9, "fire",
			"mini_turret", failures)
	_execute_skill("mini_turret", player, scene)
	await process_frame
	_execute_skill("mini_turret", player, scene)
	await process_frame
	if _child_group_count(scene, "player_summons") != 2:
		failures.append("mini_turret should keep at most two active turrets")
	if first_turret != null and is_instance_valid(first_turret) and not first_turret.is_queued_for_deletion():
		failures.append("mini_turret should remove the oldest turret when placing a third")
	scene.queue_free()
	await process_frame

func _check_spawn_skill(
		class_id: String,
		skill_id: String,
		group_name: String,
		message: String,
		failures: Array[String],
) -> void:
	var scene := _make_scene("Skill%sScene" % skill_id)
	var player := await _make_player(scene, class_id)
	player.skill = {"id": skill_id, "cost": 0, "cooldown": 0.1}
	player.call("_try_skill")
	await process_frame
	if _child_group_count(scene, group_name) == 0:
		failures.append(message)
	scene.queue_free()
	await process_frame

func _execute_skill(skill_id: String, player: Player, scene: Node) -> void:
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

func _check_element_orb_behavior(failures: Array[String]) -> void:
	var scene := _make_scene("SkillElementOrbScene")
	var player := await _make_player(scene, "arcanist")

	player.skill = {"id": "element_orb", "cost": 0, "cooldown": 0.1}
	player.call("_try_skill")
	await process_frame
	var orb := scene.get_node_or_null("ElementOrbProjectile") as Projectile
	if orb == null:
		failures.append("element_orb should still spawn a Projectile")
	else:
		if str(orb.get_meta("skill_id", "")) != "element_orb":
			failures.append("element_orb projectile should tag skill_id")
		if str(orb.get_meta("shape", "")) != "orb_projectile":
			failures.append("element_orb projectile should identify orb_projectile shape")
		if float(orb.get_meta("range_px", 0.0)) < 170.0:
			failures.append("element_orb projectile should expose range metadata")
		if float(orb.get_meta("speed_px", 0.0)) < 240.0:
			failures.append("element_orb projectile should expose speed metadata")
		if int(orb.get_meta("damage", 0)) <= 0:
			failures.append("element_orb projectile should expose damage metadata")
		if str(orb.get_meta("element", "")) != "fire":
			failures.append("element_orb projectile should expose element metadata")
	scene.queue_free()
	await process_frame

func _check_arrow_rain_behavior(failures: Array[String]) -> void:
	var scene := _make_scene("SkillArrowRainScene")
	var player := await _make_player(scene, "ranger")
	var enemy := await _make_enemy(scene, player.get_global_mouse_position(), 100)

	player.skill = {"id": "arrow_rain", "cost": 0, "cooldown": 0.1}
	player.call("_try_skill")
	await process_frame
	var telegraph := scene.get_node_or_null("ArrowRainTelegraph") as Line2D
	if telegraph == null:
		failures.append("arrow_rain should telegraph the target zone before delayed damage")
	else:
		if str(telegraph.get_meta("skill_id", "")) != "arrow_rain":
			failures.append("arrow_rain telegraph should tag skill_id")
		if float(telegraph.get_meta("radius_px", 0.0)) < 42.0:
			failures.append("arrow_rain telegraph should expose radius metadata")
		if float(telegraph.get_meta("delay_seconds", 0.0)) < 0.5:
			failures.append("arrow_rain telegraph should expose delayed impact timing")
		if str(telegraph.get_meta("element", "")) != "fire":
			failures.append("arrow_rain telegraph should expose element metadata")
		if int(telegraph.get_meta("arrow_count", 0)) != 7:
			failures.append("arrow_rain telegraph should expose 7-arrow impact count")
		if int(telegraph.get_meta("damage_per_arrow", 0)) <= 0:
			failures.append("arrow_rain telegraph should expose per-arrow damage")
	var arrows := scene.find_children("ArrowRainArrow*", "AnimatedSprite2D", true, false)
	if arrows.size() != 7:
		failures.append("arrow_rain should show the 7 falling arrows promised by class data, got %d" % arrows.size())
	for raw_arrow in arrows:
		var arrow := raw_arrow as AnimatedSprite2D
		if arrow == null:
			continue
		if int(arrow.get_meta("arrow_count", 0)) != 7:
			failures.append("arrow_rain falling arrows should expose total volley count metadata")
		if int(arrow.get_meta("arrow_index", 0)) < 1 or int(arrow.get_meta("arrow_index", 0)) > 7:
			failures.append("arrow_rain falling arrows should expose stable 1..7 volley index")
		if int(arrow.get_meta("damage_per_arrow", 0)) <= 0:
			failures.append("arrow_rain falling arrows should expose per-arrow damage")
		var expected_down_rotation := Vector2.DOWN.angle() + PI
		var down_delta := absf(wrapf(arrow.rotation - expected_down_rotation + PI, 0.0, TAU) - PI)
		if down_delta > 0.05:
			failures.append("arrow_rain falling arrows should rotate the left-facing arrow art downward")
		if not is_equal_approx(float(arrow.get_meta("arrow_visual_forward_offset_rad", 0.0)), PI):
			failures.append("arrow_rain falling arrows should expose the reviewed left-facing art rotation offset")
		if str(arrow.get_meta("skill_id", "")) != "arrow_rain":
			failures.append("arrow_rain falling arrows should tag skill_id")
		if str(arrow.get_meta("sprite_name", "")) != "zerie_arrow_projectile":
			failures.append("arrow_rain falling arrows should use the reviewed Zerie arrow sprite")
	await create_timer(0.6).timeout
	if enemy.hp >= 100:
		failures.append("arrow_rain should still damage enemies near cursor zone")
	scene.queue_free()
	await process_frame

	scene = _make_scene("SkillArrowRainDamageContractScene")
	player = await _make_player(scene, "ranger")
	var target_pos := player.global_position + Vector2(64, 0)
	enemy = await _make_enemy(scene, target_pos, 200)
	SkillRunnerScript.execute("arrow_rain", {
		"player": player,
		"skill": {"id": "arrow_rain", "cost": 0, "cooldown": 0.1},
		"base_damage": 30,
		"aim_dir": Vector2.RIGHT,
		"target_position": target_pos,
		"element": "fire",
		"scene": scene,
	})
	await create_timer(0.6).timeout
	if enemy.hp < 30 or enemy.hp > 32:
		failures.append("arrow_rain should deal 7 impacts at 80%% each from class data, allowing one fire tick, expected hp 30..32 got %d" % enemy.hp)
	scene.queue_free()
	await process_frame

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

func _count_children_of_type(parent: Node, class_name_text: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.get_class() == class_name_text or child.get_script() != null \
				and child.get_script().get_global_name() == class_name_text:
			count += 1
	return count

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

func _assert_attack_bolt(
		parent: Node,
		node_name: String,
		target_id: int,
		damage: int,
		label: String,
		failures: Array[String],
) -> void:
	var bolt := parent.get_node_or_null(node_name) as Line2D
	if bolt == null:
		failures.append("%s should spawn %s attack VFX" % [label, node_name])
		return
	if bolt.points.size() < 2:
		failures.append("%s attack VFX should draw a readable 2-point bolt" % label)
	if int(bolt.get_meta("target_id", 0)) != target_id:
		failures.append("%s attack VFX should record target id" % label)
	if int(bolt.get_meta("damage", 0)) != damage:
		failures.append("%s attack VFX should record damage" % label)
	if str(bolt.get_meta("source_policy_id", "")) != "procedural_godot_shapes":
		failures.append("%s attack VFX should identify procedural source policy" % label)

func _assert_attack_sfx(
		parent: Node,
		node_name: String,
		target_id: int,
		damage: int,
		element: String,
		label: String,
		failures: Array[String],
) -> void:
	var sfx := parent.get_node_or_null(node_name) as AudioStreamPlayer
	if sfx == null:
		failures.append("%s attack should play %s placeholder" % [label, node_name])
		return
	if sfx.stream == null:
		failures.append("%s attack SFX should assign a placeholder stream" % label)
	if str(sfx.get_meta("summon_attack_sound_id", "")) != "enemy_hit_normal":
		failures.append("%s attack SFX should use enemy_hit_normal cue" % label)
	if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
		failures.append("%s attack SFX should come from AudioCueDB" % label)
	if str(sfx.get_meta("audio_cue_kind", "")) != "enemy_hit":
		failures.append("%s attack SFX should expose enemy_hit cue kind" % label)
	if str(sfx.get_meta("audio_cue_family", "")) != "enemy_hit":
		failures.append("%s attack SFX should expose enemy_hit cue family" % label)
	if float(sfx.get_meta("summon_attack_sound_frequency", 0.0)) <= 0.0:
		failures.append("%s attack SFX should expose generated frequency" % label)
	if not bool(sfx.get_meta("placeholder_audio_stream", false)):
		failures.append("%s attack SFX should identify placeholder stream" % label)
	if not bool(sfx.get_meta("playback_requested", false)):
		failures.append("%s attack SFX should record playback request" % label)
	if not bool(sfx.get_meta("headless_playback_skipped", false)):
		failures.append("%s attack SFX should skip playback in headless smoke" % label)
	if int(sfx.get_meta("target_id", 0)) != target_id:
		failures.append("%s attack SFX should record target id" % label)
	if int(sfx.get_meta("damage", 0)) != damage:
		failures.append("%s attack SFX should record damage" % label)
	if str(sfx.get_meta("element", "")) != element:
		failures.append("%s attack SFX should record element" % label)

func _child_named(parent: Node, child_name: String) -> Node:
	for child in parent.get_children():
		if child.name == child_name:
			return child
	return null
