extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	await _check_two_weapon_slots(failures)
	await _check_gunner_tool_belt_third_slot(failures)
	await _check_gunner_active_reload(failures)
	await _check_magic_weapon_spends_mana(failures)
	await _check_cinder_orb_innate_fire(failures)
	await _check_apprentice_staff_light_homing(failures)
	await _check_storm_scepter_chains_once(failures)
	await _check_star_orb_splits_after_first_hit(failures)
	await _check_ember_cannon_leaves_fire_patch(failures)
	await _check_warden_sword_third_hit_knockback(failures)
	await _check_pioneer_axe_bonus_vs_props(failures)
	await _check_bone_knife_backstab_bonus(failures)
	await _check_cave_javelin_pierces_line(failures)
	await _check_nightwatch_mace_can_stun(failures)
	await _check_twin_fang_ramps_attack_speed(failures)
	await _check_scrap_pistol_last_round_bonus(failures)
	await _check_void_halberd_third_thrust_wave(failures)
	await _check_hardwood_bow_full_charge_pierces(failures)
	await _check_hunting_crossbow_stationary_bonus(failures)
	await _check_spiked_board_front_block(failures)

	if failures.is_empty():
		print("Weapon inventory smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_two_weapon_slots(failures: Array[String]) -> void:
	var player := await _make_player()
	var first_name := player.current_weapon().display_name()
	player.pickup_weapon("scrap_pistol")
	if not player.has_method("weapon_slot_count"):
		failures.append("player should expose weapon_slot_count")
		player.queue_free()
		await process_frame
		return
	if int(player.call("weapon_slot_count")) != 2:
		failures.append("first weapon pickup should fill the second slot")
	if player.current_weapon().display_name() != "Luc Tu Che":
		failures.append("first pickup should equip the new second-slot weapon")
	if not player.has_method("weapon_loadout_summary"):
		failures.append("player should expose weapon_loadout_summary")
	else:
		var loadout := str(player.call("weapon_loadout_summary"))
		if not loadout.contains("%s / Luc Tu Che (active)" % first_name):
			failures.append("weapon loadout summary should show slot order and active weapon")
	var add_feedback := str(player.get_meta("last_weapon_pickup_feedback", ""))
	if add_feedback != "Added: Luc Tu Che (Slot 2/2)":
		failures.append("first pickup should store added weapon slot feedback")
	if player.get_node_or_null("WeaponPickupFeedback") == null:
		failures.append("first pickup should show weapon pickup feedback")

	if not player.has_method("swap_weapon_slot"):
		failures.append("player should expose swap_weapon_slot")
		player.queue_free()
		await process_frame
		return
	player.call("swap_weapon_slot")
	if player.current_weapon().display_name() != first_name:
		failures.append("swap should return to starter weapon")
	elif player.has_method("weapon_loadout_summary") \
			and not str(player.call("weapon_loadout_summary")).contains("%s (active) / Luc Tu Che" % first_name):
		failures.append("weapon loadout summary should update active marker after swap")

	player.pickup_weapon("hardwood_bow")
	if int(player.call("weapon_slot_count")) != 2:
		failures.append("weapon inventory should stay capped at two slots")
	if player.current_weapon().display_name() != "Cung Go Cung":
		failures.append("pickup with two slots should replace active slot")
	if not str(player.get_meta("last_weapon_pickup_feedback", "")).contains("Swapped:"):
		failures.append("slot-capped pickup should store swap feedback")
	if not str(player.get_meta("last_weapon_pickup_feedback", "")).contains("Replaced slot 1/2"):
		failures.append("slot-capped pickup should explain replaced slot")
	var swap_feedback := player.get_node_or_null("WeaponPickupFeedback") as Label
	if swap_feedback == null or not swap_feedback.text.contains("Swapped"):
		failures.append("slot-capped pickup should show swap feedback")

	player.call("swap_weapon_slot")
	if player.current_weapon().display_name() != "Luc Tu Che":
		failures.append("inactive second slot should be preserved while replacing active")

	player.queue_free()
	await process_frame

func _check_gunner_tool_belt_third_slot(failures: Array[String]) -> void:
	var player := await _make_player("gunner", "scrap_pistol")
	if not player.has_method("has_passive"):
		failures.append("player should expose has_passive for class passive hooks")
	else:
		if not bool(player.call("has_passive", "tool_belt")):
			failures.append("gunner should activate tool_belt passive")

	player.pickup_weapon("hardwood_bow")
	player.pickup_weapon("warden_sword")
	if int(player.call("weapon_slot_count")) != 3:
		failures.append("tool_belt should allow a third weapon slot")
	if player.current_weapon().display_name() != "Kiem Ve Binh":
		failures.append("third pickup should equip the new third-slot weapon")
	var tool_belt_feedback := player.get_node_or_null("WeaponPickupFeedback") as Label
	if tool_belt_feedback == null:
		failures.append("tool_belt third pickup should show weapon pickup feedback")
	else:
		if not tool_belt_feedback.text.contains("TOOL BELT"):
			failures.append("tool_belt third pickup feedback should name the passive")
		if not tool_belt_feedback.text.contains("Slot 3/3"):
			failures.append("tool_belt third pickup feedback should show slot 3/3")
		if str(tool_belt_feedback.get_meta("passive_id", "")) != "tool_belt":
			failures.append("tool_belt third pickup feedback should expose passive metadata")
		if int(tool_belt_feedback.get_meta("weapon_slot_count", 0)) != 3:
			failures.append("tool_belt third pickup feedback should expose slot count metadata")

	player.pickup_weapon("bone_knife")
	if int(player.call("weapon_slot_count")) != 3:
		failures.append("tool_belt inventory should stay capped at three slots")
	if player.current_weapon().display_name() != "Dao Xuong":
		failures.append("pickup after three slots should replace active slot")
	player.call("swap_weapon_slot")
	if player.current_weapon().display_name() != "Luc Tu Che":
		failures.append("third-slot swap should wrap back to starter weapon")

	player.queue_free()
	await process_frame

func _check_gunner_active_reload(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("gunner", "scrap_pistol", scene)
	player.crit_chance = 0.0
	var weapon := player.current_weapon()
	if not player.has_method("try_active_reload"):
		failures.append("gunner should expose try_active_reload for Active Reload")
		scene.queue_free()
		await process_frame
		return
	if weapon == null or not weapon.has_method("active_reload_window_status"):
		failures.append("gunner weapon should expose active_reload_window_status")
		scene.queue_free()
		await process_frame
		return
	weapon.data["magazine_size"] = 2
	weapon.data["last_round_damage_mult"] = 1.0
	var first_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	first_enemy.global_position = Vector2(80, 0)
	scene.add_child(first_enemy)
	await process_frame
	first_enemy.max_hp = 100
	first_enemy.hp = 100
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	var first_projectile := _first_projectile(scene)
	if first_projectile == null:
		failures.append("active reload smoke needs a first pistol projectile")
		scene.queue_free()
		await process_frame
		return
	first_projectile.call("_on_body_entered", first_enemy)
	var first_damage := 100 - first_enemy.hp
	_queue_free_projectiles(scene)
	await process_frame

	weapon.call("_process", weapon.cooldown() * 0.4)
	if bool(player.call("try_active_reload")):
		failures.append("Active Reload should fail before the gold timing window")
	weapon.call("_process", weapon.cooldown() * 0.3)
	var status: Dictionary = weapon.call("active_reload_window_status")
	if not bool(status.get("in_window", false)):
		failures.append("Active Reload should expose the gold timing window near reload end")
	if not bool(player.call("try_active_reload")):
		failures.append("Gunner should hit Active Reload inside the gold timing window")
	if int(weapon.get_meta("active_reload_successes", 0)) <= 0:
		failures.append("Active Reload should store success metadata")
	if int(weapon.get_meta("active_reload_rounds_left", 0)) != 2:
		failures.append("Active Reload should empower the next magazine")
	if float(weapon.get_meta("active_reload_damage_mult", 0.0)) < 1.09:
		failures.append("Active Reload should grant +10% next-magazine damage")
	if float(weapon.call("cooldown_left")) > 0.01:
		failures.append("Active Reload should instantly finish the reload cooldown")
	var active_reload_feedback := player.get_node_or_null("ActiveReloadFeedback") as Label
	if active_reload_feedback == null:
		failures.append("Active Reload should show success feedback")
	else:
		if not active_reload_feedback.text.contains("+10%"):
			failures.append("Active Reload success feedback should show the damage bonus")
		if not active_reload_feedback.text.contains("MAG"):
			failures.append("Active Reload success feedback should explain the next magazine bonus")
		if str(active_reload_feedback.get_meta("active_reload_weapon_id", "")) != "scrap_pistol":
			failures.append("Active Reload feedback should expose weapon id metadata")
		if str(active_reload_feedback.get_meta("active_reload_weapon_name", "")) != "Luc Tu Che":
			failures.append("Active Reload feedback should expose weapon name metadata")

	var second_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	second_enemy.global_position = Vector2(80, 0)
	scene.add_child(second_enemy)
	await process_frame
	second_enemy.max_hp = 100
	second_enemy.hp = 100
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	var second_projectile := _first_projectile(scene)
	if second_projectile == null:
		failures.append("active reload smoke needs an empowered pistol projectile")
		scene.queue_free()
		await process_frame
		return
	second_projectile.call("_on_body_entered", second_enemy)
	var second_damage := 100 - second_enemy.hp
	if second_damage <= first_damage:
		failures.append("Active Reload empowered magazine should deal more damage")
	if int(weapon.get_meta("active_reload_rounds_left", -1)) != 1:
		failures.append("Active Reload should consume one empowered round per attack")

	scene.queue_free()
	await process_frame

func _check_magic_weapon_spends_mana(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("arcanist", "apprentice_staff", scene)
	var weapon := player.current_weapon()
	if weapon == null:
		failures.append("magic weapon mana smoke needs a starter weapon")
		scene.queue_free()
		await process_frame
		return
	var before_resource := player.resource
	var resource_events := {"count": 0}
	player.resource_changed.connect(func(_current: float, _max_value: float) -> void:
		resource_events["count"] = int(resource_events["count"]) + 1)
	if not weapon.try_attack(player.global_position, Vector2.RIGHT):
		failures.append("magic weapon should attack when mana is available")
	var cost := float(weapon.data.get("mana_cost", 0.0))
	if cost <= 0.0:
		failures.append("apprentice_staff should define mana_cost")
	elif not is_equal_approx(player.resource, before_resource - cost):
		failures.append("magic weapon attack should spend mana_cost")
	if int(resource_events["count"]) <= 0:
		failures.append("magic weapon mana spend should emit resource_changed")
	weapon.call("_process", weapon.cooldown() + 0.05)
	player.resource = maxf(cost - 1.0, 0.0)
	var blocked_resource := player.resource
	if weapon.try_attack(player.global_position, Vector2.RIGHT):
		failures.append("magic weapon should not attack without enough mana")
	if not is_equal_approx(player.resource, blocked_resource):
		failures.append("blocked magic weapon attack should not change resource")
	scene.queue_free()
	await process_frame

func _check_cinder_orb_innate_fire(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("soulbinder", "cinder_orb", scene)
	player.equipped_element = "ice"
	player.resource = player.max_resource
	var weapon := player.current_weapon()
	if weapon == null:
		failures.append("cinder orb innate fire smoke needs a starter weapon")
		scene.queue_free()
		await process_frame
		return
	weapon.try_attack(player.global_position, Vector2.RIGHT)
	var projectile: Projectile = null
	for child in scene.get_children():
		if child is Projectile:
			projectile = child
			break
	if projectile == null:
		failures.append("cinder orb should fire a projectile for innate element check")
		scene.queue_free()
		await process_frame
		return
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	scene.add_child(enemy)
	await process_frame
	enemy.max_hp = 100
	enemy.hp = 100
	projectile.call("_on_body_entered", enemy)
	if not enemy.has_status("fire"):
		failures.append("cinder orb projectiles should apply innate fire even when player element is ice")
	scene.queue_free()
	await process_frame

func _check_apprentice_staff_light_homing(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("arcanist", "apprentice_staff", scene)
	player.resource = player.max_resource
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	enemy.global_position = Vector2(80, -60)
	scene.add_child(enemy)
	await process_frame
	var weapon := player.current_weapon()
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	var projectile: Projectile = null
	for child in scene.get_children():
		if child is Projectile:
			projectile = child
			break
	if projectile == null:
		failures.append("apprentice staff should fire a projectile for homing check")
		scene.queue_free()
		await process_frame
		return
	var before_y := projectile.global_position.y
	projectile.call("_physics_process", 0.1)
	if projectile.global_position.y >= before_y:
		failures.append("apprentice staff projectile should lightly home toward nearby enemies")
	scene.queue_free()
	await process_frame

func _check_storm_scepter_chains_once(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("arcanist", "storm_scepter", scene)
	player.resource = player.max_resource
	var primary: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	primary.global_position = Vector2(80, 0)
	scene.add_child(primary)
	var chained: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	chained.global_position = Vector2(104, 0)
	scene.add_child(chained)
	await process_frame
	primary.max_hp = 100
	primary.hp = 100
	chained.max_hp = 100
	chained.hp = 100
	var weapon := player.current_weapon()
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	var projectile: Projectile = null
	for child in scene.get_children():
		if child is Projectile:
			projectile = child
			break
	if projectile == null:
		failures.append("storm scepter should fire a projectile for chain check")
		scene.queue_free()
		await process_frame
		return
	projectile.call("_on_body_entered", primary)
	if chained.hp >= 100:
		failures.append("storm scepter projectile should chain lightning once to a nearby enemy")
	if not chained.has_status("lightning"):
		failures.append("storm scepter chain should apply lightning status")
	scene.queue_free()
	await process_frame

func _check_star_orb_splits_after_first_hit(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("soulbinder", "star_orb", scene)
	player.resource = player.max_resource
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	enemy.global_position = Vector2(80, 0)
	scene.add_child(enemy)
	await process_frame
	enemy.max_hp = 100
	enemy.hp = 100
	var weapon := player.current_weapon()
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	var projectile: Projectile = null
	for child in scene.get_children():
		if child is Projectile:
			projectile = child
			break
	if projectile == null:
		failures.append("star orb should fire a projectile for split check")
		scene.queue_free()
		await process_frame
		return
	var before_projectiles := _projectile_count(scene)
	projectile.call("_on_body_entered", enemy)
	var after_projectiles := _projectile_count(scene)
	if after_projectiles - before_projectiles < 2:
		failures.append("star orb projectile should split into two shards after first hit")
	scene.queue_free()
	await process_frame

func _check_ember_cannon_leaves_fire_patch(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("gunner", "ember_cannon", scene)
	var primary: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	primary.global_position = Vector2(80, 0)
	scene.add_child(primary)
	var patch_target: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	patch_target.global_position = Vector2(84, 0)
	scene.add_child(patch_target)
	await process_frame
	primary.max_hp = 100
	primary.hp = 100
	patch_target.max_hp = 100
	patch_target.hp = 100
	var weapon := player.current_weapon()
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	var projectile: Projectile = null
	for child in scene.get_children():
		if child is Projectile:
			projectile = child
			break
	if projectile == null:
		failures.append("ember cannon should fire a projectile for fire patch check")
		scene.queue_free()
		await process_frame
		return
	projectile.call("_on_body_entered", primary)
	var patch := scene.get_node_or_null("FirePatch")
	if patch == null:
		failures.append("ember cannon projectile should leave a FirePatch after hitting an enemy")
	elif not patch.has_method("apply_to"):
		failures.append("FirePatch should expose apply_to for testable hazard damage")
	else:
		_assert_fire_patch_sprite(patch, failures)
		patch.call("apply_to", patch_target, 999.0)
		if patch_target.hp >= 100:
			failures.append("FirePatch should damage enemies standing in it")
		if not patch_target.has_status("fire"):
			failures.append("FirePatch should apply fire status")
	scene.queue_free()
	await process_frame

func _assert_fire_patch_sprite(patch: Node, failures: Array[String]) -> void:
	var sprite := patch.get_node_or_null("FirePatchSprite") as AnimatedSprite2D
	if sprite == null or not sprite.visible:
		failures.append("FirePatch should use FirePatchSprite visual")
		return
	var sprite_name := "fire_patch_generated"
	var report := SpriteDB.animation_report(sprite_name)
	if str(sprite.get_meta("sprite_name", "")) != sprite_name:
		failures.append("FirePatch sprite metadata should name %s" % sprite_name)
	if int(sprite.get_meta("frame_count", 0)) != 4:
		failures.append("FirePatch generated animation should use 4 frames")
	if int(report.get("frame_count", 0)) != 4:
		failures.append("FirePatch source animation should report 4 frames")
	if not bool(sprite.get_meta("stable_size", false)) or not bool(report.get("stable_size", false)):
		failures.append("FirePatch sprite should expose stable frame grid metadata")
	var release := SpriteDB.release_report([sprite_name])
	var entry: Dictionary = Dictionary(release.get("sprites", {})).get(sprite_name, {})
	if str(sprite.get_meta("asset_source", "")) != str(entry.get("source", "")):
		failures.append("FirePatch sprite should expose asset_source release metadata")
	if str(sprite.get_meta("release_decision", "")) != str(entry.get("release_decision", "")):
		failures.append("FirePatch sprite should expose release_decision metadata")
	if str(sprite.get_meta("review_status", "")) != str(entry.get("review_status", "")):
		failures.append("FirePatch sprite should expose review_status metadata")
	if str(sprite.get_meta("replacement_policy", "")) != str(entry.get("replacement_policy", "")):
		failures.append("FirePatch sprite should expose replacement_policy metadata")
	if bool(sprite.get_meta("needs_replacement_before_public", true)) \
			!= bool(entry.get("needs_replacement_before_public", false)):
		failures.append("FirePatch sprite should expose replacement gate metadata")
	if bool(sprite.get_meta("frame_grid_ok", false)) != bool(entry.get("frame_grid_ok", false)):
		failures.append("FirePatch sprite should expose frame_grid_ok metadata")
	for child in patch.get_children():
		if child is Polygon2D and child.visible:
			failures.append("FirePatch should hide polygon placeholder when sprite exists")

func _check_warden_sword_third_hit_knockback(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("blade_warden", "warden_sword", scene)
	player.crit_chance = 0.0
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	enemy.global_position = Vector2(26, 0)
	scene.add_child(enemy)
	await process_frame
	enemy.max_hp = 100
	enemy.hp = 100
	var weapon := player.current_weapon()
	for _i in 2:
		weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
		weapon.call("_process", weapon.cooldown() + 0.05)
	var before_x := enemy.global_position.x
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	if enemy.global_position.x <= before_x + 1.0:
		failures.append("warden sword third hit should knock enemies back")
	if int(enemy.get_meta("weapon_knockback_hits", 0)) <= 0:
		failures.append("warden sword knockback should be trackable for feedback/debug")
	scene.queue_free()
	await process_frame

func _check_pioneer_axe_bonus_vs_props(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("breaker", "pioneer_axe", scene)
	player.crit_chance = 0.0
	var prop := BreakableProp.new()
	prop.configure("crate", 100, {})
	prop.global_position = Vector2(16, 0)
	scene.add_child(prop)
	await process_frame
	var weapon := player.current_weapon()
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	var actual_damage := 100 - prop.hp
	var expected_min := int(round(float(weapon.base_damage()) * player.damage_mult * 1.45))
	if actual_damage < expected_min:
		failures.append("pioneer axe should deal about +50% damage to breakable props")
	scene.queue_free()
	await process_frame

func _check_bone_knife_backstab_bonus(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("nightblade", "bone_knife", scene)
	player.global_position = Vector2(-20, 0)
	player.crit_chance = 0.0
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	enemy.global_position = Vector2(10, 0)
	var facing_target := Node2D.new()
	facing_target.global_position = Vector2(60, 0)
	scene.add_child(facing_target)
	scene.add_child(enemy)
	await process_frame
	enemy.target = facing_target
	enemy.max_hp = 100
	enemy.hp = 100
	var weapon := player.current_weapon()
	weapon.try_attack(player.global_position, Vector2.RIGHT)
	var actual_damage := 100 - enemy.hp
	var expected_min := int(round(float(weapon.base_damage()) * player.damage_mult * 1.25))
	if actual_damage < expected_min:
		failures.append("bone knife should gain backstab damage from behind")
	if int(enemy.get_meta("backstab_hits", 0)) <= 0:
		failures.append("bone knife backstab should store readable hit metadata")
	scene.queue_free()
	await process_frame

func _check_cave_javelin_pierces_line(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("ranger", "cave_javelin", scene)
	player.crit_chance = 0.0
	var near_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	near_enemy.global_position = Vector2(28, 0)
	scene.add_child(near_enemy)
	var far_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	far_enemy.global_position = Vector2(76, 0)
	scene.add_child(far_enemy)
	await process_frame
	near_enemy.max_hp = 100
	near_enemy.hp = 100
	far_enemy.max_hp = 100
	far_enemy.hp = 100
	var weapon := player.current_weapon()
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	if near_enemy.hp >= 100:
		failures.append("cave javelin should still hit the first enemy")
	if far_enemy.hp >= 100:
		failures.append("cave javelin thrust should pierce enemies in a line")
	scene.queue_free()
	await process_frame

func _check_nightwatch_mace_can_stun(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("lightkeeper", "nightwatch_mace", scene)
	player.crit_chance = 0.0
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	enemy.global_position = Vector2(28, 0)
	scene.add_child(enemy)
	await process_frame
	enemy.max_hp = 100
	enemy.hp = 100
	var weapon := player.current_weapon()
	weapon.data["stun_chance"] = 1.0
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	if not enemy.has_status("stun"):
		failures.append("nightwatch mace stun effect should apply stun when its chance succeeds")
	scene.queue_free()
	await process_frame

func _check_twin_fang_ramps_attack_speed(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("nightblade", "twin_fang", scene)
	player.crit_chance = 0.0
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	enemy.global_position = Vector2(20, 0)
	scene.add_child(enemy)
	await process_frame
	enemy.max_hp = 200
	enemy.hp = 200
	var weapon := player.current_weapon()
	var base_cd := weapon.cooldown()
	for _i in 3:
		weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
		weapon.call("_process", weapon.cooldown() + 0.05)
	if weapon.cooldown() >= base_cd:
		failures.append("twin fang landed strikes should ramp attack speed")
	if float(weapon.get_meta("attack_speed_bonus", 0.0)) <= 0.0:
		failures.append("twin fang ramp should expose attack_speed_bonus metadata")
	scene.queue_free()
	await process_frame

func _check_scrap_pistol_last_round_bonus(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("gunner", "scrap_pistol", scene)
	player.crit_chance = 0.0
	var weapon := player.current_weapon()
	weapon.data["magazine_size"] = 2
	weapon.data["last_round_damage_mult"] = 1.5
	var first_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	first_enemy.global_position = Vector2(80, 0)
	scene.add_child(first_enemy)
	await process_frame
	first_enemy.max_hp = 100
	first_enemy.hp = 100
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	var first_projectile := _first_projectile(scene)
	if first_projectile == null:
		failures.append("scrap pistol should fire projectile for last-round check")
		scene.queue_free()
		await process_frame
		return
	first_projectile.call("_on_body_entered", first_enemy)
	var first_damage := 100 - first_enemy.hp
	_queue_free_projectiles(scene)
	await process_frame
	weapon.call("_process", weapon.cooldown() + 0.05)
	var second_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	second_enemy.global_position = Vector2(80, 0)
	scene.add_child(second_enemy)
	await process_frame
	second_enemy.max_hp = 100
	second_enemy.hp = 100
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	var second_projectile := _first_projectile(scene)
	if second_projectile == null:
		failures.append("scrap pistol should fire second projectile for last-round check")
		scene.queue_free()
		await process_frame
		return
	second_projectile.call("_on_body_entered", second_enemy)
	var second_damage := 100 - second_enemy.hp
	if second_damage <= first_damage:
		failures.append("scrap pistol magazine last round should deal bonus damage")
	if int(weapon.get_meta("last_round_bonus_shots", 0)) <= 0:
		failures.append("scrap pistol last round should store bonus shot metadata")
	scene.queue_free()
	await process_frame

func _check_void_halberd_third_thrust_wave(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("blade_warden", "void_halberd", scene)
	player.crit_chance = 0.0
	var close_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	close_enemy.global_position = Vector2(32, 0)
	scene.add_child(close_enemy)
	var far_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	far_enemy.global_position = Vector2(112, 0)
	scene.add_child(far_enemy)
	await process_frame
	close_enemy.max_hp = 200
	close_enemy.hp = 200
	far_enemy.max_hp = 100
	far_enemy.hp = 100
	var weapon := player.current_weapon()
	for _i in 3:
		weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
		weapon.call("_process", weapon.cooldown() + 0.05)
	var wave := scene.get_node_or_null("ShadowWaveProjectile")
	if wave == null:
		failures.append("void halberd third thrust should fire a shadow wave")
	elif wave is Projectile:
		wave.call("_on_body_entered", far_enemy)
		if far_enemy.hp >= 100:
			failures.append("void halberd shadow wave should damage enemies downrange")
	scene.queue_free()
	await process_frame

func _check_hardwood_bow_full_charge_pierces(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("ranger", "hardwood_bow", scene)
	player.crit_chance = 0.0
	var first_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	first_enemy.global_position = Vector2(80, 0)
	scene.add_child(first_enemy)
	var second_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	second_enemy.global_position = Vector2(104, 0)
	scene.add_child(second_enemy)
	await process_frame
	first_enemy.max_hp = 100
	first_enemy.hp = 100
	second_enemy.max_hp = 100
	second_enemy.hp = 100
	var weapon := player.current_weapon()
	if weapon == null or not weapon.has_method("try_charged_attack") \
			or not weapon.has_method("charge_time_full"):
		failures.append("hardwood bow should expose charged attack helpers")
		scene.queue_free()
		await process_frame
		return
	if not bool(weapon.call("try_charged_attack", Vector2.ZERO, Vector2.RIGHT,
			float(weapon.call("charge_time_full")))):
		failures.append("hardwood bow should fire from a full charge")
	var projectile := _first_projectile(scene)
	if projectile == null:
		failures.append("hardwood bow should spawn a projectile for charge pierce check")
		scene.queue_free()
		await process_frame
		return
	projectile.call("_on_body_entered", first_enemy)
	projectile.call("_on_body_entered", second_enemy)
	if first_enemy.hp >= 100 or second_enemy.hp >= 100:
		failures.append("hardwood bow full charge should pierce one extra target")
	if float(weapon.get_meta("last_charge_ratio", 0.0)) < 1.0:
		failures.append("hardwood bow should expose full-charge metadata for feedback")
	scene.queue_free()
	await process_frame

func _check_hunting_crossbow_stationary_bonus(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("gunner", "hunting_crossbow", scene)
	player.crit_chance = 0.0
	var weapon := player.current_weapon()
	var still_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	still_enemy.global_position = Vector2(80, 0)
	scene.add_child(still_enemy)
	await process_frame
	still_enemy.max_hp = 100
	still_enemy.hp = 100
	player.velocity = Vector2.ZERO
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	var still_projectile := _first_projectile(scene)
	if still_projectile == null:
		failures.append("hunting crossbow should fire projectile for stationary bonus check")
		scene.queue_free()
		await process_frame
		return
	still_projectile.call("_on_body_entered", still_enemy)
	var still_damage := 100 - still_enemy.hp
	_queue_free_projectiles(scene)
	await process_frame
	weapon.call("_process", weapon.cooldown() + 0.05)

	var moving_enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	moving_enemy.global_position = Vector2(80, 0)
	scene.add_child(moving_enemy)
	await process_frame
	moving_enemy.max_hp = 100
	moving_enemy.hp = 100
	player.velocity = Vector2(90, 0)
	weapon.try_attack(Vector2.ZERO, Vector2.RIGHT)
	var moving_projectile := _first_projectile(scene)
	if moving_projectile == null:
		failures.append("hunting crossbow should fire moving comparison projectile")
		scene.queue_free()
		await process_frame
		return
	moving_projectile.call("_on_body_entered", moving_enemy)
	var moving_damage := 100 - moving_enemy.hp
	if still_damage <= moving_damage:
		failures.append("hunting crossbow should deal more damage while standing still")
	if int(weapon.get_meta("stationary_bonus_shots", 0)) <= 0:
		failures.append("hunting crossbow should expose stationary bonus metadata")
	scene.queue_free()
	await process_frame

func _check_spiked_board_front_block(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := await _make_player("bulwark", "spiked_board", scene)
	player.set_physics_process(false)
	player.set_meta("block_facing_dir", Vector2.RIGHT)
	var weapon := player.current_weapon()
	if weapon == null or not weapon.has_method("front_block_damage"):
		failures.append("spiked board should expose front block damage helper")
		scene.queue_free()
		await process_frame
		return
	var front_hp := player.hp
	player.call("take_damage", 10, player.global_position + Vector2.RIGHT * 20.0)
	var front_damage := front_hp - player.hp
	var rear_hp := player.hp
	player.call("take_damage", 10, player.global_position + Vector2.LEFT * 20.0)
	var rear_damage := rear_hp - player.hp
	if front_damage > 5:
		failures.append("spiked board front block should reduce frontal damage by 50%")
	if rear_damage <= front_damage:
		failures.append("spiked board should not reduce rear damage like a front block")
	if weapon == null or int(weapon.get_meta("front_blocks", 0)) <= 0:
		failures.append("spiked board should expose front block metadata")
	scene.queue_free()
	await process_frame

func _make_player(
		class_id: String = "blade_warden",
		starter_weapon: String = "warden_sword",
		parent: Node = null,
) -> Player:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	(parent if parent != null else root).add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data(class_id), "fire", starter_weapon)
	return player

func _projectile_count(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is Projectile:
			count += 1
		count += _projectile_count(child)
	return count

func _first_projectile(parent: Node) -> Projectile:
	for child in parent.get_children():
		if child is Projectile and not child.is_queued_for_deletion():
			return child
		var nested := _first_projectile(child)
		if nested != null:
			return nested
	return null

func _queue_free_projectiles(parent: Node) -> void:
	for child in parent.get_children():
		if child is Projectile:
			child.queue_free()
		else:
			_queue_free_projectiles(child)
