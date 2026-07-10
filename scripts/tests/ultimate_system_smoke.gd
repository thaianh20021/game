extends SceneTree

const UltimateRunnerPath := "res://scripts/ultimates/ultimate_runner.gd"
const UltimateRunnerScript := preload("res://scripts/ultimates/ultimate_runner.gd")
const SoulKingdomUltimateScript := preload("res://scripts/ultimates/soul_kingdom_ultimate.gd")
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")

func _init() -> void:
	var failures: Array[String] = []

	_check_ultimate_files_and_input(failures)
	await _check_blade_warden_phantom_slash(failures)
	await _check_breaker_skyfall(failures)
	await _check_ranger_skypiercer(failures)
	await _check_nightblade_death_dance(failures)
	await _check_bulwark_fortress(failures)
	await _check_arcanist_elemental_fury(failures)
	await _check_gunner_suppressing_fire(failures)
	await _check_soulbinder_soul_kingdom(failures)
	await _check_lightkeeper_verdict(failures)
	await _check_tinkerer_mobile_fortress(failures)
	await _check_hud_ultimate_charge(failures)
	await _check_ultimate_blocked_feedback(failures)

	if failures.is_empty():
		print("Ultimate system smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_ultimate_files_and_input(failures: Array[String]) -> void:
	if not ResourceLoader.exists(UltimateRunnerPath):
		failures.append("UltimateRunner should exist")
	var project_source := FileAccess.get_file_as_string("res://project.godot")
	if not project_source.contains("ultimate={"):
		failures.append("project input map should include ultimate action")
	if not _action_has_key("ultimate", KEY_V):
		failures.append("ultimate should bind V to avoid restart/cycle input conflicts")
	if _actions_share_key("ultimate", "restart"):
		failures.append("ultimate input should not share a key with restart")
	if _actions_share_key("ultimate", "cycle_element"):
		failures.append("ultimate input should not share a key with cycle_element")
	if not UltimateRunnerScript.has_ultimate("phantom_slash"):
		failures.append("UltimateRunner should register phantom_slash")
	if not UltimateRunnerScript.has_ultimate("skyfall"):
		failures.append("UltimateRunner should register skyfall")
	if not UltimateRunnerScript.has_ultimate("skypiercer"):
		failures.append("UltimateRunner should register skypiercer")
	if not UltimateRunnerScript.has_ultimate("death_dance"):
		failures.append("UltimateRunner should register death_dance")
	if not UltimateRunnerScript.has_ultimate("fortress"):
		failures.append("UltimateRunner should register fortress")
	if not UltimateRunnerScript.has_ultimate("elemental_fury"):
		failures.append("UltimateRunner should register elemental_fury")
	if not UltimateRunnerScript.has_ultimate("suppressing_fire"):
		failures.append("UltimateRunner should register suppressing_fire")
	if not UltimateRunnerScript.has_ultimate("soul_kingdom"):
		failures.append("UltimateRunner should register soul_kingdom")
	if not UltimateRunnerScript.has_ultimate("verdict"):
		failures.append("UltimateRunner should register verdict")
	if not UltimateRunnerScript.has_ultimate("mobile_fortress"):
		failures.append("UltimateRunner should register mobile_fortress")

func _check_blade_warden_phantom_slash(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "UltimateSmokeScene"
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player(scene, "blade_warden", "warden_sword")
	var aim_dir := Vector2(player.call("_aim_dir"))
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	var side := aim_dir.orthogonal()
	var enemy_a := await _make_enemy(scene, aim_dir * 40.0, 100)
	var enemy_b := await _make_enemy(scene, aim_dir * 82.0 + side * 3.0, 100)
	var off_line := await _make_enemy(scene, aim_dir * 45.0 + side * 45.0, 100)

	if not player.has_method("add_ultimate_charge") or not player.has_method("_try_ultimate"):
		failures.append("player should expose ultimate charge/cast methods")
		scene.queue_free()
		await process_frame
		return
	var cast_seen := {"value": false}
	if player.has_signal("ultimate_cast"):
		player.connect("ultimate_cast", func(id: String) -> void:
			if id == "phantom_slash":
				cast_seen["value"] = true)
	else:
		failures.append("player should emit ultimate_cast")
	player.call("add_ultimate_charge", 999.0)
	var before_pos := player.global_position
	player.call("_try_ultimate")
	await process_frame

	if enemy_a.hp >= 100 or enemy_b.hp >= 100:
		failures.append("phantom_slash should damage enemies in a forward line")
	if off_line.hp < 100:
		failures.append("phantom_slash should ignore enemies outside the line")
	if (player.global_position - before_pos).dot(aim_dir) <= 0.0:
		failures.append("phantom_slash should move the player forward")
	if not bool(cast_seen["value"]):
		failures.append("phantom_slash should emit ultimate_cast")
	if float(player.get("ultimate_charge")) > 0.01:
		failures.append("casting ultimate should spend charge")

	scene.queue_free()
	await process_frame

func _check_breaker_skyfall(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "SkyfallSmokeScene"
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player(scene, "breaker", "pioneer_axe")
	var target := Vector2(72.0, 0.0)
	var near_enemy := await _make_enemy(scene, target + Vector2(10.0, 0.0), 220)
	var wave_enemy := await _make_enemy(scene, target + Vector2(78.0, 0.0), 220)
	var outside_enemy := await _make_enemy(scene, target + Vector2(0.0, 110.0), 220)

	var executed := UltimateRunnerScript.execute("skyfall", {
		"player": player,
		"ultimate": PlayerClassDB.get_class_data("breaker").get("ultimate", {}),
		"base_damage": 20,
		"aim_dir": Vector2.RIGHT,
		"target_position": target,
		"element": "earth",
		"scene": scene,
	})
	await process_frame

	if not executed:
		failures.append("skyfall should execute through UltimateRunner")
	if near_enemy.hp >= 220:
		failures.append("skyfall should damage enemies near the landing point")
	if wave_enemy.hp >= 220:
		failures.append("skyfall should send stone waves from the landing point")
	if outside_enemy.hp < 220:
		failures.append("skyfall should ignore enemies outside slam and waves")
	if player.global_position.distance_to(target) > 3.0:
		failures.append("skyfall should move the player to the landing point")
	if scene.get_node_or_null("SkyfallFx") == null:
		failures.append("skyfall should spawn a landing FX node")

	var cast_seen := {"value": false}
	if player.has_signal("ultimate_cast"):
		player.connect("ultimate_cast", func(id: String) -> void:
			if id == "skyfall":
				cast_seen["value"] = true)
	player.call("add_ultimate_charge", 999.0)
	player.call("_try_ultimate")
	await process_frame
	if not bool(cast_seen["value"]):
		failures.append("skyfall should emit ultimate_cast")
	if float(player.get("ultimate_charge")) > 0.01:
		failures.append("skyfall cast should spend charge")

	scene.queue_free()
	await process_frame

func _check_ranger_skypiercer(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "SkypiercerSmokeScene"
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player(scene, "ranger", "hardwood_bow")
	var line_enemy := await _make_enemy(scene, Vector2(92.0, 4.0), 260)
	var far_line_enemy := await _make_enemy(scene, Vector2(174.0, -6.0), 260)
	var off_line_enemy := await _make_enemy(scene, Vector2(92.0, 44.0), 260)
	var enemy_projectile := EnemyProjectile.new()
	enemy_projectile.setup(Vector2.LEFT, 0.0, 5, 120.0)
	scene.add_child(enemy_projectile)
	await process_frame
	enemy_projectile.global_position = Vector2(60.0, 22.0)

	var executed := UltimateRunnerScript.execute("skypiercer", {
		"player": player,
		"ultimate": PlayerClassDB.get_class_data("ranger").get("ultimate", {}),
		"base_damage": 18,
		"aim_dir": Vector2.RIGHT,
		"target_position": Vector2(140.0, 0.0),
		"element": "wind",
		"scene": scene,
	})
	await process_frame

	if not executed:
		failures.append("skypiercer should execute through UltimateRunner")
	if line_enemy.hp >= 260 or far_line_enemy.hp >= 260:
		failures.append("skypiercer should damage enemies in a long line")
	if off_line_enemy.hp < 260:
		failures.append("skypiercer should ignore enemies outside the arrow lane")
	if absf(enemy_projectile.global_position.y) >= 22.0:
		failures.append("skypiercer should drag enemy projectiles toward the arrow lane")
	if scene.get_node_or_null("SkypiercerFx") == null:
		failures.append("skypiercer should spawn a giant arrow FX node")

	var cast_seen := {"value": false}
	if player.has_signal("ultimate_cast"):
		player.connect("ultimate_cast", func(id: String) -> void:
			if id == "skypiercer":
				cast_seen["value"] = true)
	player.call("add_ultimate_charge", 999.0)
	player.call("_try_ultimate")
	await process_frame
	if not bool(cast_seen["value"]):
		failures.append("skypiercer should emit ultimate_cast")
	if float(player.get("ultimate_charge")) > 0.01:
		failures.append("skypiercer cast should spend charge")

	scene.queue_free()
	await process_frame

func _check_nightblade_death_dance(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "DeathDanceSmokeScene"
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player(scene, "nightblade", "bone_knife")
	var enemies: Array[Enemy] = []
	for pos in [Vector2(32.0, 0.0), Vector2(58.0, 8.0), Vector2(82.0, -6.0), Vector2(110.0, 12.0), Vector2(136.0, -10.0)]:
		enemies.append(await _make_enemy(scene, pos, 180))
	var ignored_enemy := await _make_enemy(scene, Vector2(210.0, 48.0), 180)

	var executed := UltimateRunnerScript.execute("death_dance", {
		"player": player,
		"ultimate": PlayerClassDB.get_class_data("nightblade").get("ultimate", {}),
		"base_damage": 20,
		"aim_dir": Vector2.RIGHT,
		"target_position": Vector2(120.0, 0.0),
		"element": "poison",
		"scene": scene,
	})
	await process_frame

	if not executed:
		failures.append("death_dance should execute through UltimateRunner")
	for enemy in enemies:
		if enemy.hp >= 180:
			failures.append("death_dance should slash five nearby targets")
			break
	if ignored_enemy.hp < 180:
		failures.append("death_dance should cap its target chain at five enemies")
	if player.global_position.distance_to(Vector2.ZERO) <= 1.0:
		failures.append("death_dance should teleport the player through targets")
	if scene.get_node_or_null("DeathDanceFx") == null:
		failures.append("death_dance should spawn a chain slash FX node")

	await _check_cast_spends_and_emits(player, "death_dance", failures)
	scene.queue_free()
	await process_frame

func _check_bulwark_fortress(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "FortressSmokeScene"
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player(scene, "bulwark", "spiked_board")
	var enemy := await _make_enemy(scene, Vector2(42.0, 0.0), 260)
	var hp_before := player.hp

	var executed := UltimateRunnerScript.execute("fortress", {
		"player": player,
		"ultimate": PlayerClassDB.get_class_data("bulwark").get("ultimate", {}),
		"base_damage": 20,
		"aim_dir": Vector2.RIGHT,
		"target_position": Vector2.ZERO,
		"element": "earth",
		"scene": scene,
	})
	await process_frame

	if not executed:
		failures.append("fortress should execute through UltimateRunner")
	if not bool(player.get_meta("fortress_active", false)):
		failures.append("fortress should mark the player invulnerable")
	if scene.get_node_or_null("FortressFx") == null:
		failures.append("fortress should spawn a guard FX node")
	if enemy.target != player:
		failures.append("fortress should taunt nearby enemies")
	player.take_damage(40)
	await process_frame
	if player.hp != hp_before:
		failures.append("fortress should prevent damage during the guard window")
	if int(player.get_meta("fortress_blocked_damage", 0)) < 40:
		failures.append("fortress should track blocked damage for the blast")
	await create_timer(3.15).timeout
	if bool(player.get_meta("fortress_active", false)):
		failures.append("fortress should end after the guard window")
	if enemy.hp >= 260:
		failures.append("fortress should blast nearby enemies when guard ends")

	await _check_cast_spends_and_emits(player, "fortress", failures)
	scene.queue_free()
	await process_frame

func _check_arcanist_elemental_fury(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "ElementalFurySmokeScene"
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player(scene, "arcanist", "apprentice_staff")
	var target := Vector2(68.0, 0.0)
	var target_enemy := await _make_enemy(scene, target + Vector2(4.0, 0.0), 260)
	var outside_enemy := await _make_enemy(scene, target + Vector2(96.0, 0.0), 260)

	var executed := UltimateRunnerScript.execute("elemental_fury", {
		"player": player,
		"ultimate": PlayerClassDB.get_class_data("arcanist").get("ultimate", {}),
		"base_damage": 18,
		"aim_dir": Vector2.RIGHT,
		"target_position": target,
		"element": "ice",
		"scene": scene,
	})
	await process_frame

	if not executed:
		failures.append("elemental_fury should execute through UltimateRunner")
	if scene.get_node_or_null("ElementalFuryFx") == null:
		failures.append("elemental_fury should spawn a storm FX controller")
	await create_timer(0.65).timeout
	if target_enemy.hp >= 260:
		failures.append("elemental_fury should rain elemental strikes near the target")
	if outside_enemy.hp < 260:
		failures.append("elemental_fury should not damage enemies far outside the storm")

	await _check_cast_spends_and_emits(player, "elemental_fury", failures)
	scene.queue_free()
	await process_frame

func _check_gunner_suppressing_fire(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "SuppressingFireSmokeScene"
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player(scene, "gunner", "scrap_pistol")
	var weapon := player.current_weapon()
	var before_cd := weapon.cooldown()

	var executed := UltimateRunnerScript.execute("suppressing_fire", {
		"player": player,
		"ultimate": PlayerClassDB.get_class_data("gunner").get("ultimate", {}),
		"base_damage": 16,
		"aim_dir": Vector2.RIGHT,
		"target_position": Vector2(90.0, 0.0),
		"element": "fire",
		"scene": scene,
	})
	await process_frame

	if not executed:
		failures.append("suppressing_fire should execute through UltimateRunner")
	if weapon.cooldown() >= before_cd:
		failures.append("suppressing_fire should increase fire rate through lower cooldown")
	if not bool(player.get_meta("suppressing_fire_active", false)):
		failures.append("suppressing_fire should mark homing fire active")
	if scene.get_node_or_null("SuppressingFireFx") == null:
		failures.append("suppressing_fire should spawn a muzzle-barrage FX node")
	var enemy := await _make_enemy(scene, Vector2(70.0, 28.0), 180)
	var projectile := Projectile.new()
	projectile.setup(Vector2.RIGHT, 160.0, 5, 120.0, Color.WHITE, "fire", player)
	scene.add_child(projectile)
	projectile.global_position = Vector2.ZERO
	await create_timer(0.2).timeout
	if is_instance_valid(projectile) and projectile.global_position.y <= 0.0 and is_instance_valid(enemy):
		failures.append("suppressing_fire projectiles should gently home toward enemies")

	await _check_cast_spends_and_emits(player, "suppressing_fire", failures)
	scene.queue_free()
	await process_frame

func _check_soulbinder_soul_kingdom(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "SoulKingdomSmokeScene"
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player(scene, "soulbinder", "cinder_orb")
	player.pet_damage_mult = 1.5
	var enemy := await _make_enemy(scene, Vector2(48.0, 0.0), 30)

	var executed := UltimateRunnerScript.execute("soul_kingdom", {
		"player": player,
		"ultimate": PlayerClassDB.get_class_data("soulbinder").get("ultimate", {}),
		"base_damage": 12,
		"aim_dir": Vector2.RIGHT,
		"target_position": Vector2.ZERO,
		"element": "spirit",
		"pet_damage_mult": player.pet_damage_multiplier(),
		"scene": scene,
	})
	await process_frame
	enemy.take_damage(999)
	await process_frame

	if not executed:
		failures.append("soul_kingdom should execute through UltimateRunner")
	if scene.get_node_or_null("SoulKingdomFx") == null:
		failures.append("soul_kingdom should spawn a kingdom aura FX node")
	var spirit := scene.get_node_or_null("SoulKingdomSpirit")
	if spirit == null:
		failures.append("soul_kingdom should revive killed enemies as allied spirits")
	else:
		_assert_soul_kingdom_spirit_sprite(spirit, failures)
		var spirit_feedback := spirit.get_node_or_null("SoulSpiritFeedback") as Label
		if spirit_feedback == null:
			failures.append("soul_kingdom spirit should show readable duration/damage feedback")
		elif not spirit_feedback.text.contains("SPIRIT") \
				or not spirit_feedback.text.contains("8s") \
				or not spirit_feedback.text.contains("DMG x1.5"):
			failures.append("soul_kingdom spirit feedback should show duration and pet damage multiplier")
		if float(spirit.get_meta("pet_damage_mult", 0.0)) < 1.5:
			failures.append("soul_kingdom spirit should expose pet damage multiplier metadata")
		if int(spirit.get_meta("attack_damage", 0)) <= int(12 * 0.55):
			failures.append("soul_kingdom spirit should scale attack damage with pet build")
		if float(spirit.get_meta("attack_radius_px", 0.0)) < 100.0:
			failures.append("soul_kingdom spirit should expose attack radius metadata for playtest readability")
		if float(spirit.get_meta("attack_interval_seconds", 0.0)) <= 0.0:
			failures.append("soul_kingdom spirit should expose attack interval metadata for balance review")
		var target := await _make_enemy(scene, spirit.global_position + Vector2(26.0, 0.0), 80)
		var soul_kingdom := SoulKingdomUltimateScript.new()
		if not soul_kingdom.has_method("_attack_nearest"):
			failures.append("soul_kingdom spirit should expose attack helper for pet-scaled spirits")
		else:
			soul_kingdom.call("_attack_nearest",
				spirit, int(spirit.get_meta("attack_damage", 0)), "spirit")
			if target.hp >= 80:
				failures.append("soul_kingdom spirit should damage nearby enemies")
			if int(spirit.get_meta("attack_count", 0)) != 1:
				failures.append("soul_kingdom spirit attack should count fired attacks")
			if int(spirit.get_meta("last_target_id", 0)) != target.get_instance_id():
				failures.append("soul_kingdom spirit attack should record target id")
			if spirit.get_node_or_null("SoulSpiritAttackBolt") == null:
				failures.append("soul_kingdom spirit should show attack bolt feedback")
			var spirit_sfx := spirit.get_node_or_null("SoulSpiritAttackSfx") as AudioStreamPlayer
			if spirit_sfx == null:
				failures.append("soul_kingdom spirit should play attack sound placeholder")
			else:
				if spirit_sfx.stream == null:
					failures.append("soul_kingdom spirit attack SFX should assign placeholder stream")
				if str(spirit_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
					failures.append("soul_kingdom spirit attack SFX should come from AudioCueDB")
				if not bool(spirit_sfx.get_meta("placeholder_audio_stream", false)):
					failures.append("soul_kingdom spirit attack SFX should mark placeholder stream")
				if int(spirit_sfx.get_meta("target_id", 0)) != target.get_instance_id():
					failures.append("soul_kingdom spirit attack SFX should record target id")
				if str(spirit_sfx.get_meta("element", "")) != "spirit":
					failures.append("soul_kingdom spirit attack SFX should record spirit element")
				if not bool(spirit_sfx.get_meta("headless_playback_skipped", false)):
					failures.append("soul_kingdom spirit attack SFX should skip playback in headless smoke")
		var late_enemy := await _make_enemy(scene, Vector2(78.0, 0.0), 30)
		var spirit_count_before_late := _soul_kingdom_spirit_count(scene)
		if not soul_kingdom.has_method("bind_spawned_enemy"):
			failures.append("soul_kingdom should expose bind_spawned_enemy for enemies spawned during the ultimate")
		else:
			soul_kingdom.call("bind_spawned_enemy", late_enemy, scene, player)
			late_enemy.take_damage(999)
			await process_frame
			if _soul_kingdom_spirit_count(scene) <= spirit_count_before_late:
				failures.append("soul_kingdom should revive enemies spawned after the cast while active")

	await _check_cast_spends_and_emits(player, "soul_kingdom", failures)
	scene.queue_free()
	await process_frame

func _check_lightkeeper_verdict(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "VerdictSmokeScene"
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player(scene, "lightkeeper", "nightwatch_mace")
	var target := Vector2(62.0, 0.0)
	var enemy := await _make_enemy(scene, target + Vector2(4.0, 0.0), 220)
	var poison_zone := Node2D.new()
	poison_zone.name = "PoisonZone"
	poison_zone.add_to_group("poison_zones")
	scene.add_child(poison_zone)
	poison_zone.global_position = target

	var executed := UltimateRunnerScript.execute("verdict", {
		"player": player,
		"ultimate": PlayerClassDB.get_class_data("lightkeeper").get("ultimate", {}),
		"base_damage": 18,
		"aim_dir": Vector2.RIGHT,
		"target_position": target,
		"element": "lightning",
		"scene": scene,
	})
	await process_frame

	if not executed:
		failures.append("verdict should execute through UltimateRunner")
	if enemy.hp >= 220:
		failures.append("verdict should damage enemies in the light pillar")
	if not Dictionary(enemy.get("_statuses")).has("stun"):
		failures.append("verdict should stun enemies in the light pillar")
	if is_instance_valid(poison_zone) and not poison_zone.is_queued_for_deletion():
		failures.append("verdict should clear poison zones inside the pillar")
	if scene.get_node_or_null("VerdictFx") == null:
		failures.append("verdict should spawn a light pillar FX node")

	await _check_cast_spends_and_emits(player, "verdict", failures)
	scene.queue_free()
	await process_frame

func _check_tinkerer_mobile_fortress(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "MobileFortressSmokeScene"
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player(scene, "tinkerer", "scrap_pistol")
	var speed_before := player.move_speed
	var hp_before := player.hp

	var executed := UltimateRunnerScript.execute("mobile_fortress", {
		"player": player,
		"ultimate": PlayerClassDB.get_class_data("tinkerer").get("ultimate", {}),
		"base_damage": 16,
		"aim_dir": Vector2.RIGHT,
		"target_position": Vector2(90.0, 0.0),
		"element": "fire",
		"scene": scene,
	})
	await process_frame

	if not executed:
		failures.append("mobile_fortress should execute through UltimateRunner")
	if not bool(player.get_meta("mobile_fortress_active", false)):
		failures.append("mobile_fortress should mark mech shell active")
	if player.move_speed >= speed_before:
		failures.append("mobile_fortress should slow the player while active")
	player.take_damage(50)
	await process_frame
	if player.hp != hp_before:
		failures.append("mobile_fortress should block incoming damage while active")
	if _count_projectiles(scene) < 2:
		failures.append("mobile_fortress should fire two opening cannon shots")
	if scene.get_node_or_null("MobileFortressFx") == null:
		failures.append("mobile_fortress should spawn a mech shell FX node")

	await _check_cast_spends_and_emits(player, "mobile_fortress", failures)
	scene.queue_free()
	await process_frame

func _check_hud_ultimate_charge(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	ctrl.current_biome = {"name": "Test Biome", "difficulty_mult": 1.0}
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	hud.bind(player, ctrl)
	await process_frame
	var icon := hud.get_node_or_null("UltimateChargeIcon") as ColorRect
	var fill := hud.get_node_or_null("UltimateChargeFill") as ColorRect
	if icon == null:
		failures.append("HUD should expose an ultimate charge icon")
	if fill == null:
		failures.append("HUD should expose an ultimate charge fill")
	if not hud.has_method("_on_ultimate_charge_changed"):
		failures.append("HUD should handle ultimate charge updates")
	else:
		hud.call("_on_ultimate_charge_changed", 40.0, 100.0)
		await process_frame
		if not _has_label_containing(hud, "Ultimate"):
			failures.append("HUD should show ultimate charge text")
		hud.call("_on_ultimate_charge_changed", 100.0, 100.0)
		await process_frame
		var flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("ultimate ready flash should become visible when charge reaches full")
		elif not flash.text.contains("Ultimate Ready") \
				or not flash.text.contains("Phantom Slash"):
			failures.append("ultimate ready flash should name the readable ready ultimate")
		if flash != null:
			if str(flash.get_meta("hud_flash_kind", "")) != "ultimate_ready":
				failures.append("ultimate ready flash should store ultimate_ready kind metadata")
			if str(flash.get_meta("ultimate_ready_id", "")) != "phantom_slash":
				failures.append("ultimate ready flash should store ready ultimate id metadata")
			if str(flash.get_meta("ultimate_ready_slot", "")) != "ultimate":
				failures.append("ultimate ready flash should tag the ultimate slot")
		var ready_sfx := hud.get_node_or_null("UltimateReadySfx") as AudioStreamPlayer
		if ready_sfx == null:
			failures.append("ultimate ready should create sound placeholder")
		else:
			if str(ready_sfx.get_meta("ultimate_ready_id", "")) != "phantom_slash":
				failures.append("ultimate ready sound should store ultimate id metadata")
			if str(ready_sfx.get_meta("ultimate_ready_sound_id", "")) != "ultimate_ready":
				failures.append("ultimate ready sound should expose ready cue id")
			if str(ready_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("ultimate ready sound should come from AudioCueDB")
			if ready_sfx.stream == null:
				failures.append("ultimate ready sound should assign an audio stream")
			if DisplayServer.get_name() == "headless" \
					and not bool(ready_sfx.get_meta("headless_playback_skipped", false)):
				failures.append("ultimate ready sound should skip playback in headless smoke")
		var profile: Dictionary = CombatFxScript.skill_feedback_profile("phantom_slash")
		for node in [icon, fill]:
			if node == null:
				continue
			if str(node.get_meta("ultimate_id", "")) != "phantom_slash":
				failures.append("%s should tag the active ultimate id" % node.name)
			if str(node.get_meta("skill_family", "")) != str(profile.get("family", "")):
				failures.append("%s should tag the active ultimate family" % node.name)
			if str(node.get_meta("skill_style", "")) != str(profile.get("style", "")):
				failures.append("%s should tag the active ultimate style" % node.name)
			_assert_ultimate_charge_tooltip(node, "Phantom Slash", true, 100.0, 100.0, 100.0, failures)
		if fill != null and not _colors_close(fill.color, profile.get("color", Color.WHITE)):
			failures.append("HUD ultimate charge fill should use the ultimate feedback profile color")
		_assert_ultimate_sprite_icon(icon, failures)
	if not hud.has_method("_on_ultimate_cast"):
		failures.append("HUD should handle ultimate cast feedback")
	else:
		hud.call("_on_ultimate_cast", "phantom_slash")
		await process_frame
		var cast_flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
		if cast_flash == null or not cast_flash.visible:
			failures.append("ultimate cast flash should become visible")
		elif not cast_flash.text.contains("Ultimate: Phantom Slash") \
				or not cast_flash.text.contains("SFX blade_cast"):
			failures.append("ultimate cast flash should show readable ultimate name and sound cue")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	if not hud_source.contains("player.ultimate_cast.connect(_on_ultimate_cast)"):
		failures.append("HUD bind should connect player ultimate_cast signal")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_ultimate_blocked_feedback(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "UltimateBlockedFeedbackScene"
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player(scene, "blade_warden", "warden_sword")
	if not _has_signal(player, "ultimate_blocked"):
		failures.append("Player should expose ultimate_blocked for blocked ultimate input feedback")
	else:
		var blocked_events: Array[Dictionary] = []
		player.connect("ultimate_blocked", func(ultimate_id: String, reason: String, detail: Dictionary) -> void:
			blocked_events.append({
				"ultimate_id": ultimate_id,
				"reason": reason,
				"detail": detail,
			}))
		player.ultimate_charge = 0.0
		player.call("_try_ultimate")
		await process_frame
		if blocked_events.is_empty():
			failures.append("blocked ultimate input should emit ultimate_blocked")
		else:
			var event: Dictionary = blocked_events[0]
			if str(event.get("ultimate_id", "")) != "phantom_slash":
				failures.append("ultimate_blocked should include ultimate id")
			if str(event.get("reason", "")) != "charge":
				failures.append("ultimate_blocked should explain missing charge")
			var detail: Dictionary = event.get("detail", {})
			if float(detail.get("cost", 0.0)) <= 0.0:
				failures.append("ultimate_blocked charge detail should include ultimate cost")
			if str(player.get_meta("last_ultimate_blocked_reason", "")) != "charge":
				failures.append("Player should store last blocked ultimate reason metadata")
			if str(player.get_meta("last_ultimate_blocked_id", "")) != "phantom_slash":
				failures.append("Player should store last blocked ultimate id metadata")

	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(hud)
	await process_frame
	hud.bind(player, ctrl)
	await process_frame
	if not hud.has_method("_on_ultimate_blocked"):
		failures.append("HUD should handle blocked ultimate feedback")
	else:
		hud.call("_on_ultimate_blocked", "phantom_slash", "charge", {
			"charge": 0.0,
			"cost": 100.0,
		})
		await process_frame
		var flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("blocked ultimate should show HUD flash feedback")
		elif not flash.text.contains("Blocked: Phantom Slash") or not flash.text.contains("0/100"):
			failures.append("blocked ultimate flash should name ultimate and charge shortfall")
		var sfx := hud.get_node_or_null("UltimateBlockedSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("blocked ultimate should create sound placeholder")
		else:
			if str(sfx.get_meta("ultimate_blocked_id", "")) != "phantom_slash":
				failures.append("blocked ultimate sound should store ultimate id metadata")
			if str(sfx.get_meta("ultimate_blocked_reason", "")) != "charge":
				failures.append("blocked ultimate sound should store blocked reason metadata")
			if str(sfx.get_meta("ultimate_blocked_sound_id", "")) != "skill_blocked":
				failures.append("blocked ultimate sound should reuse blocked cue id")
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("blocked ultimate sound should come from AudioCueDB")
			if sfx.stream == null:
				failures.append("blocked ultimate sound should assign an audio stream")
			if DisplayServer.get_name() == "headless" \
					and not bool(sfx.get_meta("headless_playback_skipped", false)):
				failures.append("blocked ultimate sound should skip playback in headless smoke")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	if not hud_source.contains("player.ultimate_blocked.connect(_on_ultimate_blocked)"):
		failures.append("HUD bind should connect player ultimate_blocked signal")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	scene.queue_free()
	await process_frame

func _assert_ultimate_sprite_icon(icon: Node, failures: Array[String]) -> void:
	if icon == null:
		return
	var sprite := icon.get_node_or_null("UltimateChargeSprite") as TextureRect
	if sprite == null:
		failures.append("UltimateChargeIcon should expose a sprite child")
		return
	if sprite.texture == null:
		failures.append("UltimateChargeSprite should assign a sprite texture")
	if str(sprite.get_meta("cooldown_icon_token", "")) != "blade":
		failures.append("UltimateChargeSprite should store blade icon token")
	if str(sprite.get_meta("icon_sprite_name", "")) != "weapon_regular_sword":
		failures.append("UltimateChargeSprite should use weapon_regular_sword")

func _assert_ultimate_charge_tooltip(
		node: Control,
		readable_name: String,
		ready: bool,
		current: float,
		max_value: float,
		cost: float,
		failures: Array[String]) -> void:
	if str(node.get_meta("ultimate_key_label", "")) != "V":
		failures.append("%s should tag ultimate key label V" % node.name)
	if str(node.get_meta("ultimate_input_action", "")) != "ultimate":
		failures.append("%s should tag ultimate input action" % node.name)
	if not bool(node.get_meta("ultimate_ready", false)) == ready:
		failures.append("%s should tag ultimate ready state" % node.name)
	if not is_equal_approx(float(node.get_meta("ultimate_charge_current", -1.0)), current):
		failures.append("%s should tag current ultimate charge" % node.name)
	if not is_equal_approx(float(node.get_meta("ultimate_charge_max", -1.0)), max_value):
		failures.append("%s should tag max ultimate charge" % node.name)
	if not is_equal_approx(float(node.get_meta("ultimate_charge_cost", -1.0)), cost):
		failures.append("%s should tag ultimate charge cost" % node.name)
	if node.tooltip_text.strip_edges() == "":
		failures.append("%s should expose ultimate tooltip" % node.name)
	for token in ["V", readable_name, "READY" if ready else "%d%%" % int(round(current / maxf(max_value, 0.001) * 100.0)), "Cost %d" % int(cost)]:
		if not node.tooltip_text.contains(token):
			failures.append("%s ultimate tooltip should include %s" % [node.name, token])

func _action_has_key(action: String, keycode: int) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null and key.physical_keycode == keycode:
			return true
	return false

func _actions_share_key(left: String, right: String) -> bool:
	if not InputMap.has_action(left) or not InputMap.has_action(right):
		return false
	var right_keys := {}
	for event in InputMap.action_get_events(right):
		var right_key := event as InputEventKey
		if right_key != null:
			right_keys[right_key.physical_keycode] = true
	for event in InputMap.action_get_events(left):
		var left_key := event as InputEventKey
		if left_key != null and right_keys.has(left_key.physical_keycode):
			return true
	return false

func _make_player(scene: Node2D, class_id: String, starter_weapon: String) -> Player:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	scene.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data(class_id), "fire", starter_weapon)
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

func _has_label_containing(parent: Node, text: String) -> bool:
	for child in parent.find_children("*", "Label", true, false):
		if str(child.text).contains(text):
			return true
	return false

func _has_signal(node: Object, signal_name: String) -> bool:
	for info in node.get_signal_list():
		if str(info.get("name", "")) == signal_name:
			return true
	return false

func _assert_soul_kingdom_spirit_sprite(spirit: Node, failures: Array[String]) -> void:
	var sprite := spirit.get_node_or_null("SoulKingdomSpiritSprite") as AnimatedSprite2D
	if sprite == null or not sprite.visible:
		failures.append("soul_kingdom spirit should use SoulKingdomSpiritSprite visual")
		return
	var sprite_name := "necromancer_anim"
	var report := SpriteDB.animation_report(sprite_name)
	if str(sprite.get_meta("sprite_name", "")) != sprite_name:
		failures.append("soul_kingdom spirit sprite metadata should name %s" % sprite_name)
	if int(sprite.get_meta("frame_count", 0)) != int(report.get("frame_count", 0)):
		failures.append("soul_kingdom spirit sprite should store frame count metadata")
	if not bool(sprite.get_meta("stable_size", false)) or not bool(report.get("stable_size", false)):
		failures.append("soul_kingdom spirit sprite should expose stable frame grid metadata")
	if not bool(sprite.get_meta("frame_grid_ok", false)):
		failures.append("soul_kingdom spirit sprite should pass frame grid review")
	if not bool(sprite.get_meta("animation_stability_reviewed", false)):
		failures.append("soul_kingdom spirit sprite should expose animation stability review metadata")
	if not bool(sprite.get_meta("motion_reviewed", false)):
		failures.append("soul_kingdom spirit sprite should expose motion review metadata")
	if not bool(sprite.get_meta("origin_alignment_reviewed", false)):
		failures.append("soul_kingdom spirit sprite should expose origin alignment review metadata")
	if str(sprite.get_meta("asset_source", "")) == "":
		failures.append("soul_kingdom spirit sprite should expose asset source metadata")
	if str(sprite.get_meta("release_decision", "")) != "public_ok":
		failures.append("soul_kingdom spirit sprite should be public_ok for release")
	if bool(sprite.get_meta("needs_replacement_before_public", true)):
		failures.append("soul_kingdom spirit sprite should not need replacement before public release")
	for child in spirit.get_children():
		if child is Polygon2D and child.visible:
			failures.append("soul_kingdom spirit should hide polygon placeholder when sprite exists")

func _count_projectiles(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is Projectile:
			count += 1
		count += _count_projectiles(child)
	return count

func _check_cast_spends_and_emits(player: Player, ultimate_id: String, failures: Array[String]) -> void:
	var cast_seen := {"value": false}
	if player.has_signal("ultimate_cast"):
		player.connect("ultimate_cast", func(id: String) -> void:
			if id == ultimate_id:
				cast_seen["value"] = true)
	player.call("add_ultimate_charge", 999.0)
	Engine.time_scale = 1.0
	player.call("_try_ultimate")
	var sfx := player.get_node_or_null("SkillCastSfx")
	if sfx == null:
		failures.append("%s ultimate should create cast sound placeholder" % ultimate_id)
	else:
		if str(sfx.get_meta("cast_kind", "")) != "ultimate":
			failures.append("%s cast sound should be tagged as ultimate" % ultimate_id)
		if str(sfx.get_meta("ultimate_id", "")) != ultimate_id:
			failures.append("%s cast sound should store ultimate id metadata" % ultimate_id)
		if str(sfx.get_meta("skill_family", "")) == "":
			failures.append("%s ultimate sound should expose feedback family" % ultimate_id)
		if str(player.get_meta("last_ultimate_sound_id", "")) != str(sfx.get_meta("skill_sound_id", "")):
			failures.append("%s should store last ultimate sound id for HUD/audio hooks" % ultimate_id)
	if Engine.time_scale >= 1.0:
		failures.append("%s ultimate should pulse hit pause" % ultimate_id)
	var fx := _child_named(player.get_parent(), "CombatFxSkillCast")
	if fx == null:
		failures.append("%s ultimate should spawn shared cast VFX" % ultimate_id)
	else:
		if str(fx.get_meta("cast_kind", "")) != "ultimate":
			failures.append("%s cast VFX should be tagged as ultimate" % ultimate_id)
		if str(fx.get_meta("ultimate_id", "")) != ultimate_id:
			failures.append("%s cast VFX should store ultimate id metadata" % ultimate_id)
	await process_frame
	if not bool(cast_seen["value"]):
		failures.append("%s should emit ultimate_cast" % ultimate_id)
	if float(player.get("ultimate_charge")) > 0.01:
		failures.append("%s cast should spend charge" % ultimate_id)
	await create_timer(0.12, true, false, true).timeout
	if not is_equal_approx(Engine.time_scale, 1.0):
		failures.append("%s ultimate should restore hit pause time scale" % ultimate_id)
		Engine.time_scale = 1.0
	await process_frame
	if player.get_node_or_null("SkillCastSfx") != null:
		failures.append("%s ultimate cast sound placeholder should self-clean" % ultimate_id)

func _child_named(parent: Node, child_name: String) -> Node:
	if parent == null:
		return null
	for child in parent.get_children():
		if child.name == child_name:
			return child
	return null

func _child_named_count(parent: Node, child_name: String) -> int:
	if parent == null:
		return 0
	var count := 0
	for child in parent.get_children():
		if child.name == child_name:
			count += 1
	return count

func _soul_kingdom_spirit_count(parent: Node) -> int:
	if parent == null:
		return 0
	var count := 0
	for child in parent.get_children():
		if child.is_in_group("player_summons") \
				and str(child.get_meta("summon_type", "")) == "soul_kingdom":
			count += 1
	return count

func _colors_close(actual: Color, expected: Color) -> bool:
	return absf(actual.r - expected.r) < 0.01 \
		and absf(actual.g - expected.g) < 0.01 \
		and absf(actual.b - expected.b) < 0.01
