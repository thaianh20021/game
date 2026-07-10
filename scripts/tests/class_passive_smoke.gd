extends SceneTree

const HackSkillScript := preload("res://scripts/skills/hack_skill.gd")
const TrapScript := preload("res://scripts/rooms/trap.gd")

func _init() -> void:
	var failures: Array[String] = []

	await _check_lightkeeper_prayer_regen(failures)
	await _check_lightkeeper_judgement_anti_undead_shadow(failures)
	await _check_bulwark_unyielding_damage_reduction(failures)
	await _check_bulwark_steel_thorns_reflect(failures)
	await _check_arcanist_resonance_skill_damage_window(failures)
	await _check_arcanist_siphon_element_pickup_mana(failures)
	await _check_gunner_quick_finger_fire_rate_stacks(failures)
	await _check_ranger_piercer_projectile_pierce(failures)
	await _check_ranger_deer_step_hopback(failures)
	await _check_nightblade_weakpoint_wind_foot(failures)
	await _check_soulbinder_pet_passives(failures)
	await _check_tinkerer_scavenge_resource_restore(failures)
	await _check_tinkerer_repurpose_hacked_trap(failures)
	await _check_blade_warden_blade_rhythm_bonus(failures)
	await _check_blade_warden_reflex_dash_refund(failures)
	await _check_breaker_iron_skin_standstill_reduction(failures)
	await _check_breaker_heavy_windup_charge_damage(failures)

	if failures.is_empty():
		print("Class passive smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_lightkeeper_prayer_regen(failures: Array[String]) -> void:
	var player := await _make_player("lightkeeper", "nightwatch_mace")
	player.set_physics_process(false)
	if not player.has_method("has_passive") or not bool(player.call("has_passive", "prayer")):
		failures.append("lightkeeper should activate prayer passive")
		player.queue_free()
		await process_frame
		return

	player.take_damage(40)
	var hp_after_hit := player.hp
	player.call("_physics_process", 5.9)
	if player.hp != hp_after_hit:
		failures.append("prayer should not heal before 6s without damage")
	player.call("_physics_process", 1.0)
	if player.hp <= hp_after_hit:
		failures.append("prayer should heal after 6s without damage")
	var healed := player.hp - hp_after_hit
	var feedback := player.get_node_or_null("PrayerFeedback") as Label
	if feedback == null:
		failures.append("prayer should show readable delayed heal feedback")
	else:
		if not feedback.text.contains("PRAYER") or not feedback.text.contains("+%d" % healed):
			failures.append("prayer feedback should name passive and healed amount")
		if str(feedback.get_meta("passive_id", "")) != "prayer":
			failures.append("prayer feedback should expose passive metadata")
		if int(feedback.get_meta("heal_amount", 0)) != healed:
			failures.append("prayer feedback should expose heal amount metadata")
		if float(feedback.get_meta("delay_seconds", 0.0)) < 6.0:
			failures.append("prayer feedback should expose delay metadata")
		if float(feedback.get_meta("heal_pct_per_second", 0.0)) < 0.019:
			failures.append("prayer feedback should expose regen rate metadata")

	player.take_damage(5)
	var hp_after_reset := player.hp
	player.call("_physics_process", 3.0)
	if player.hp != hp_after_reset:
		failures.append("taking damage should reset prayer heal timer")

	player.queue_free()
	await process_frame

func _check_lightkeeper_judgement_anti_undead_shadow(failures: Array[String]) -> void:
	var player := await _make_player("lightkeeper", "nightwatch_mace")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "judgement")):
		failures.append("lightkeeper should activate judgement passive")
		player.queue_free()
		await process_frame
		return
	if not player.has_method("target_damage_multiplier"):
		failures.append("player should expose target_damage_multiplier for judgement passive")
		player.queue_free()
		await process_frame
		return
	var undead := Enemy.new()
	undead.set_meta("enemy_family", "undead")
	var shadow := Enemy.new()
	shadow.set_meta("enemy_family", "shadow")
	var living := Enemy.new()
	living.set_meta("enemy_family", "beast")
	root.add_child(undead)
	root.add_child(shadow)
	root.add_child(living)
	if float(player.call("target_damage_multiplier", undead)) < 1.29:
		failures.append("judgement should grant +30% damage versus undead")
	if float(player.call("target_damage_multiplier", shadow)) < 1.29:
		failures.append("judgement should grant +30% damage versus shadow enemies")
	if not is_equal_approx(float(player.call("target_damage_multiplier", living)), 1.0):
		failures.append("judgement should not affect living non-shadow enemies")
	var weapon := player.current_weapon()
	var boosted := int(weapon.call("_apply_enemy_melee_effects", undead, 100, Vector2.ZERO))
	if boosted < 129:
		failures.append("weapon melee damage should apply judgement multiplier")
	var feedback := player.get_node_or_null("JudgementFeedback") as Label
	if feedback == null:
		failures.append("judgement should show readable target damage feedback")
	else:
		if not feedback.text.contains("JUDGEMENT") or not feedback.text.contains("x1.3"):
			failures.append("judgement feedback should name passive and damage multiplier")
		if str(feedback.get_meta("passive_id", "")) != "judgement":
			failures.append("judgement feedback should expose passive metadata")
		if str(feedback.get_meta("target_family", "")) != "undead":
			failures.append("judgement feedback should expose target family metadata")
		if float(feedback.get_meta("damage_multiplier", 0.0)) < 1.29:
			failures.append("judgement feedback should expose damage multiplier metadata")
	undead.queue_free()
	shadow.queue_free()
	living.queue_free()
	player.queue_free()
	await process_frame

func _check_bulwark_unyielding_damage_reduction(failures: Array[String]) -> void:
	var player := await _make_player("bulwark", "spiked_board")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "unyielding")):
		failures.append("bulwark should activate unyielding passive")
		player.queue_free()
		await process_frame
		return

	player.take_damage(10)
	if player.hp != player.max_hp - 10:
		failures.append("unyielding should not reduce damage above 30% hp")
	player.take_damage(150)
	var low_hp := player.hp
	player.take_damage(10)
	if player.hp != low_hp - 7:
		failures.append("unyielding should reduce incoming damage by 30% below 30% hp")
	var feedback := player.get_node_or_null("UnyieldingFeedback") as Label
	if feedback == null:
		failures.append("unyielding should show readable low-health damage reduction feedback")
	else:
		if not feedback.text.contains("UNYIELDING") or not feedback.text.contains("3"):
			failures.append("unyielding feedback should name passive and blocked damage")
		if str(feedback.get_meta("passive_id", "")) != "unyielding":
			failures.append("unyielding feedback should expose passive metadata")
		if int(feedback.get_meta("blocked_damage", 0)) != 3:
			failures.append("unyielding feedback should expose blocked damage metadata")
		if float(feedback.get_meta("damage_multiplier", 0.0)) > 0.71:
			failures.append("unyielding feedback should expose damage multiplier metadata")

	player.queue_free()
	await process_frame

func _check_bulwark_steel_thorns_reflect(failures: Array[String]) -> void:
	var player := await _make_player("bulwark", "spiked_board")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "steel_thorns")):
		failures.append("bulwark should activate steel_thorns passive")
		player.queue_free()
		await process_frame
		return
	var attacker := Enemy.new()
	attacker.max_hp = 100
	attacker.hp = 100
	attacker.contact_damage = 10
	attacker.target = player
	attacker.global_position = player.global_position
	root.add_child(attacker)
	await process_frame
	attacker.call("_try_contact_damage")
	attacker.call("_physics_process", 0.51)
	await process_frame
	if attacker.hp > 80:
		failures.append("steel_thorns should reflect 10% player max HP to melee attackers")
	if int(player.get_meta("steel_thorns_reflected_damage", 0)) < 20:
		failures.append("steel_thorns should expose reflected damage metadata")
	var feedback := player.get_node_or_null("SteelThornsFeedback") as Label
	if feedback == null:
		failures.append("steel_thorns should show readable reflected damage feedback")
	else:
		if not feedback.text.contains("STEEL THORNS") or not feedback.text.contains("20"):
			failures.append("steel_thorns feedback should name passive and reflected damage")
		if str(feedback.get_meta("passive_id", "")) != "steel_thorns":
			failures.append("steel_thorns feedback should expose passive metadata")
		if int(feedback.get_meta("reflected_damage", 0)) < 20:
			failures.append("steel_thorns feedback should expose reflected damage metadata")
		if float(feedback.get_meta("reflect_pct", 0.0)) < 0.09:
			failures.append("steel_thorns feedback should expose reflect percent metadata")
	attacker.queue_free()
	player.queue_free()
	await process_frame

func _check_arcanist_resonance_skill_damage_window(failures: Array[String]) -> void:
	var player := await _make_player("arcanist", "apprentice_staff")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "resonance")):
		failures.append("arcanist should activate resonance passive")
		player.queue_free()
		await process_frame
		return
	if not player.has_method("skill_damage_multiplier"):
		failures.append("player should expose skill_damage_multiplier for passive skill hooks")
		player.queue_free()
		await process_frame
		return
	if not is_equal_approx(float(player.call("skill_damage_multiplier")), 1.0):
		failures.append("resonance should start inactive")
	player.cycle_element()
	if float(player.call("skill_damage_multiplier")) < 1.19:
		failures.append("resonance should grant +20% skill damage after element swap")
	var feedback := player.get_node_or_null("ResonanceFeedback") as Label
	if feedback == null:
		failures.append("resonance should show readable skill damage window feedback")
	else:
		if not feedback.text.contains("RESONANCE") or not feedback.text.contains("+20%"):
			failures.append("resonance feedback should name passive and skill damage bonus")
		if str(feedback.get_meta("passive_id", "")) != "resonance":
			failures.append("resonance feedback should expose passive metadata")
		if str(feedback.get_meta("element", "")) != player.equipped_element:
			failures.append("resonance feedback should expose current element metadata")
		if float(feedback.get_meta("duration_seconds", 0.0)) < 5.0:
			failures.append("resonance feedback should expose duration metadata")
		if float(feedback.get_meta("skill_damage_multiplier", 0.0)) < 1.19:
			failures.append("resonance feedback should expose skill damage multiplier metadata")
	player.call("_physics_process", 4.9)
	if float(player.call("skill_damage_multiplier")) < 1.19:
		failures.append("resonance should last 5s")
	player.call("_physics_process", 0.2)
	if not is_equal_approx(float(player.call("skill_damage_multiplier")), 1.0):
		failures.append("resonance should expire after 5s")
	player.queue_free()
	await process_frame

func _check_arcanist_siphon_element_pickup_mana(failures: Array[String]) -> void:
	var player := await _make_player("arcanist", "apprentice_staff")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "siphon")):
		failures.append("arcanist should activate siphon passive")
		player.queue_free()
		await process_frame
		return
	if not player.has_method("siphon_mana_restore_amount"):
		failures.append("player should expose siphon_mana_restore_amount")
		player.queue_free()
		await process_frame
		return
	player.resource = 0.0
	player.add_meta_currency("element_cores", 1)
	if float(player.resource) < 10.0:
		failures.append("siphon should restore 10 mana from element core pickups")
	if int(player.get_meta("siphon_mana_restored", 0)) < 10:
		failures.append("siphon should expose restored mana metadata")
	var feedback := player.get_node_or_null("SiphonFeedback") as Label
	if feedback == null:
		failures.append("siphon should show readable mana restore feedback")
	else:
		if not feedback.text.contains("SIPHON") or not feedback.text.contains("+10"):
			failures.append("siphon feedback should name passive and restored mana")
		if str(feedback.get_meta("passive_id", "")) != "siphon":
			failures.append("siphon feedback should expose passive metadata")
		if str(feedback.get_meta("source", "")) != "element_cores":
			failures.append("siphon feedback should expose pickup source metadata")
		if int(feedback.get_meta("resource_restored", 0)) != 10:
			failures.append("siphon feedback should expose restored resource metadata")
		if str(feedback.get_meta("resource_type", "")) != "mana":
			failures.append("siphon feedback should expose mana resource type")
	player.resource = 0.0
	player.add_meta_currency("soul_shards", 1)
	if float(player.resource) > 0.01:
		failures.append("siphon should only trigger from element pickups")
	player.resource = player.max_resource - 4.0
	player.add_meta_currency("element_cores", 1)
	if float(player.resource) > float(player.max_resource):
		failures.append("siphon should cap mana at max resource")
	player.queue_free()
	await process_frame

func _check_gunner_quick_finger_fire_rate_stacks(failures: Array[String]) -> void:
	var player := await _make_player("gunner", "scrap_pistol")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "quick_finger")):
		failures.append("gunner should activate quick_finger passive")
		player.queue_free()
		await process_frame
		return
	if not player.has_method("weapon_cooldown_multiplier"):
		failures.append("player should expose weapon_cooldown_multiplier for fire-rate passives")
		player.queue_free()
		await process_frame
		return
	if not player.has_method("on_enemy_killed"):
		failures.append("player should expose on_enemy_killed for kill-triggered passives")
		player.queue_free()
		await process_frame
		return
	player.call("on_enemy_killed")
	if float(player.call("weapon_cooldown_multiplier")) >= 0.9:
		failures.append("quick_finger should improve weapon fire rate after a kill")
	var feedback := player.get_node_or_null("QuickFingerFeedback") as Label
	if feedback == null:
		failures.append("quick_finger should show readable fire-rate feedback")
	else:
		if not feedback.text.contains("QUICK FINGER") or not feedback.text.contains("1/3"):
			failures.append("quick_finger feedback should name passive and stack count")
		if str(feedback.get_meta("passive_id", "")) != "quick_finger":
			failures.append("quick_finger feedback should expose passive metadata")
		if int(feedback.get_meta("stack_count", 0)) != 1:
			failures.append("quick_finger feedback should expose stack count metadata")
		if float(feedback.get_meta("duration_seconds", 0.0)) < 3.0:
			failures.append("quick_finger feedback should expose duration metadata")
	for i in 3:
		player.call("on_enemy_killed")
	if float(player.call("weapon_cooldown_multiplier")) < 0.68:
		failures.append("quick_finger should cap at three stacks")
	feedback = player.get_node_or_null("QuickFingerFeedback") as Label
	if feedback == null or not feedback.text.contains("3/3"):
		failures.append("quick_finger feedback should update at max stacks")
	player.call("_physics_process", 3.1)
	if not is_equal_approx(float(player.call("weapon_cooldown_multiplier")), 1.0):
		failures.append("quick_finger should expire after 3s")
	player.queue_free()
	await process_frame

func _check_ranger_piercer_projectile_pierce(failures: Array[String]) -> void:
	var player := await _make_player("ranger", "hardwood_bow")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "piercer")):
		failures.append("ranger should activate piercer passive")
		player.queue_free()
		await process_frame
		return
	var weapon := player.current_weapon()
	if weapon == null or not weapon.has_method("projectile_pierce_count"):
		failures.append("weapon should expose projectile_pierce_count for pierce passives")
	else:
		if int(weapon.call("projectile_pierce_count")) < 1:
			failures.append("piercer should grant bow/crossbow projectiles one pierce")
	player.queue_free()
	await process_frame

func _check_ranger_deer_step_hopback(failures: Array[String]) -> void:
	var player := await _make_player("ranger", "hardwood_bow")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "deer_step")):
		failures.append("ranger should activate deer_step passive")
		player.queue_free()
		await process_frame
		return
	if not player.has_method("deer_step_cooldown_left"):
		failures.append("player should expose deer_step_cooldown_left")
		player.queue_free()
		await process_frame
		return
	player.global_position = Vector2.ZERO
	var close_enemy := Node2D.new()
	close_enemy.name = "CloseEnemyForDeerStep"
	close_enemy.global_position = Vector2(12, 0)
	close_enemy.add_to_group("enemies")
	root.add_child(close_enemy)
	var start_pos := player.global_position
	player.call("_physics_process", 0.1)
	await process_frame
	if player.global_position.x >= start_pos.x:
		failures.append("deer_step should hop away from nearby enemies")
	if float(player.call("deer_step_cooldown_left")) < 2.9:
		failures.append("deer_step should start a 3s cooldown after hop")
	if float(player.get_meta("deer_step_distance", 0.0)) < 24.0:
		failures.append("deer_step should store hop distance metadata")
	if float(player.get_meta("deer_step_trigger_range", 0.0)) < 16.0:
		failures.append("deer_step should store one-tile trigger range metadata")
	if bool(player.get_meta("deer_step_spent_dash_cooldown", true)):
		failures.append("deer_step should not spend dash cooldown")
	var after_first_hop := player.global_position
	player.call("_physics_process", 0.5)
	await process_frame
	if player.global_position.distance_to(after_first_hop) > 0.01:
		failures.append("deer_step should not retrigger while on cooldown")
	player.queue_free()
	close_enemy.queue_free()
	await process_frame

func _check_nightblade_weakpoint_wind_foot(failures: Array[String]) -> void:
	var player := await _make_player("nightblade", "bone_knife")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "weakpoint")):
		failures.append("nightblade should activate weakpoint passive")
	if not bool(player.call("has_passive", "wind_foot")):
		failures.append("nightblade should activate wind_foot passive")
	if not player.has_method("wind_foot_active_left"):
		failures.append("player should expose wind_foot_active_left")
		player.queue_free()
		await process_frame
		return
	if not player.has_method("dash_cooldown_left"):
		failures.append("player should expose dash_cooldown_left")
		player.queue_free()
		await process_frame
		return
	var weapon := player.current_weapon()
	var enemy := Enemy.new()
	enemy.velocity = Vector2.RIGHT * 24.0
	root.add_child(enemy)
	var back_damage := int(weapon.call("_apply_enemy_melee_effects", enemy, 100, Vector2(-12, 0)))
	var front_damage := int(weapon.call("_apply_enemy_melee_effects", enemy, 100, Vector2(12, 0)))
	if back_damage < 207:
		failures.append("weakpoint should add +60% back attack damage on top of dagger backstab")
	if front_damage != 100:
		failures.append("weakpoint should not affect front attacks")
	var weakpoint_feedback := player.get_node_or_null("WeakpointFeedback") as Label
	if weakpoint_feedback == null:
		failures.append("weakpoint should show feedback on back attacks")
	else:
		if not weakpoint_feedback.text.contains("WEAKPOINT"):
			failures.append("weakpoint feedback should name the passive")
		if not weakpoint_feedback.text.contains("x1.6"):
			failures.append("weakpoint feedback should show the damage multiplier")
		if str(weakpoint_feedback.get_meta("passive_id", "")) != "weakpoint":
			failures.append("weakpoint feedback should expose passive_id metadata")
		if float(weakpoint_feedback.get_meta("damage_multiplier", 0.0)) < 1.59:
			failures.append("weakpoint feedback should expose damage multiplier metadata")
		if str(weakpoint_feedback.get_meta("attack_side", "")) != "back":
			failures.append("weakpoint feedback should expose attack side metadata")
	player.call("_start_dash", Vector2.RIGHT)
	if float(player.call("dash_cooldown_left")) < 1.0:
		failures.append("normal dash should start cooldown before wind_foot")
	player.call("on_enemy_killed")
	if float(player.call("wind_foot_active_left")) > 0.0:
		failures.append("wind_foot should not trigger from a normal kill")
	player.call("on_enemy_killed", {"marked": true})
	if float(player.call("wind_foot_active_left")) < 1.9:
		failures.append("wind_foot should trigger a 2s free dash window from marked kills")
	player.call("_start_dash", Vector2.LEFT)
	if float(player.call("dash_cooldown_left")) > 0.01:
		failures.append("wind_foot dash should not spend dash cooldown")
	if not bool(player.get_meta("wind_foot_free_dash", false)):
		failures.append("wind_foot dash should expose free dash metadata")
	player.call("_physics_process", 2.1)
	if float(player.call("wind_foot_active_left")) > 0.0:
		failures.append("wind_foot free dash window should expire after 2s")
	enemy.queue_free()
	player.queue_free()
	await process_frame

func _check_soulbinder_pet_passives(failures: Array[String]) -> void:
	var player := await _make_player("soulbinder", "cinder_orb")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "pack_hunger")):
		failures.append("soulbinder should activate pack_hunger passive")
	if not bool(player.call("has_passive", "soul_tether")):
		failures.append("soulbinder should activate soul_tether passive")
	if not player.has_method("pet_damage_multiplier"):
		failures.append("player should expose pet_damage_multiplier for pet passives")
		player.queue_free()
		await process_frame
		return

	var summon_a := Node2D.new()
	var summon_b := Node2D.new()
	summon_a.add_to_group("player_summons")
	summon_b.add_to_group("player_summons")
	root.add_child(summon_a)
	root.add_child(summon_b)
	if float(player.call("pet_damage_multiplier")) < 1.07:
		failures.append("pack_hunger should increase pet damage per living summon")

	var max_hp := player.max_hp
	player.take_damage(10)
	if player.hp != max_hp - 8:
		failures.append("soul_tether should reduce owner damage by 20% while summons live")
	var feedback := player.get_node_or_null("SoulTetherFeedback") as Label
	if feedback == null:
		failures.append("soul_tether should show readable summon damage reduction feedback")
	else:
		if not feedback.text.contains("SOUL TETHER") or not feedback.text.contains("2"):
			failures.append("soul_tether feedback should name passive and blocked damage")
		if str(feedback.get_meta("passive_id", "")) != "soul_tether":
			failures.append("soul_tether feedback should expose passive metadata")
		if int(feedback.get_meta("blocked_damage", 0)) != 2:
			failures.append("soul_tether feedback should expose blocked damage metadata")
		if int(feedback.get_meta("summon_count", 0)) != 2:
			failures.append("soul_tether feedback should expose living summon count")
		if float(feedback.get_meta("damage_multiplier", 0.0)) > 0.81:
			failures.append("soul_tether feedback should expose damage multiplier metadata")
	summon_a.queue_free()
	summon_b.queue_free()
	await process_frame

	player.hp = player.max_hp
	player.take_damage(10)
	if player.hp != player.max_hp - 10:
		failures.append("soul_tether should not reduce damage with no summons")
	if not player.has_method("soul_slot_summary"):
		failures.append("soulbinder should expose Soul Slot summary")
	else:
		var blocked_events: Array[Dictionary] = []
		player.skill_blocked.connect(func(skill_id: String, reason: String, detail: Dictionary) -> void:
			blocked_events.append({
				"skill_id": skill_id,
				"reason": reason,
				"detail": detail,
			}))
		var slot_pets: Array[Node2D] = []
		for i in 4:
			var pet := Node2D.new()
			pet.name = "SoulSlotWisp%d" % i
			pet.add_to_group("player_summons")
			root.add_child(pet)
			slot_pets.append(pet)
		await process_frame
		player.skill = {"id": "summon_wisp", "cost": 0, "cooldown": 2.0}
		player.call("_try_skill")
		await process_frame
		if _player_summon_count() != 4:
			failures.append("soul slot cap should prevent spawning a fifth pet")
		if blocked_events.is_empty():
			failures.append("full Soul Slots should emit skill_blocked")
		else:
			var event: Dictionary = blocked_events[0]
			var detail: Dictionary = event.get("detail", {})
			if str(event.get("skill_id", "")) != "summon_wisp":
				failures.append("Soul Slot block should identify summon_wisp")
			if str(event.get("reason", "")) != "soul_slots":
				failures.append("Soul Slot block should use soul_slots reason")
			if int(detail.get("slots_used", 0)) != 4 or int(detail.get("slot_limit", 0)) != 4:
				failures.append("Soul Slot block detail should expose 4/4 slots")
		if str(player.get_meta("last_skill_blocked_reason", "")) != "soul_slots":
			failures.append("Player should store Soul Slot blocked reason metadata")
		if not str(player.call("soul_slot_summary")).contains("Soul Slots 4/4"):
			failures.append("Soul Slot summary should show 4/4 when capped")
		for pet in slot_pets:
			pet.queue_free()
	player.queue_free()
	await process_frame

func _check_tinkerer_scavenge_resource_restore(failures: Array[String]) -> void:
	var player := await _make_player("tinkerer", "scrap_pistol")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "scavenge")):
		failures.append("tinkerer should activate scavenge passive")
		player.queue_free()
		await process_frame
		return
	player.resource = 0.0
	player.call("on_enemy_killed")
	if float(player.resource) < 10.0:
		failures.append("scavenge should restore 10 resource on kill")
	var feedback := player.get_node_or_null("ScavengeFeedback") as Label
	if feedback == null:
		failures.append("scavenge should show readable resource restore feedback")
	else:
		if not feedback.text.contains("SCAVENGE") or not feedback.text.contains("+10"):
			failures.append("scavenge feedback should name passive and restored amount")
		if str(feedback.get_meta("passive_id", "")) != "scavenge":
			failures.append("scavenge feedback should expose passive metadata")
		if int(feedback.get_meta("resource_restored", 0)) != 10:
			failures.append("scavenge feedback should expose restored resource metadata")
		if str(feedback.get_meta("resource_type", "")) == "":
			failures.append("scavenge feedback should expose resource type metadata")
	player.resource = player.max_resource - 4.0
	player.call("on_enemy_killed")
	if not is_equal_approx(float(player.resource), float(player.max_resource)):
		failures.append("scavenge should cap restored resource at max")
	player.queue_free()
	await process_frame

func _check_tinkerer_repurpose_hacked_trap(failures: Array[String]) -> void:
	var player := await _make_player("tinkerer", "scrap_pistol")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "repurpose")):
		failures.append("tinkerer should activate repurpose passive")
		player.queue_free()
		await process_frame
		return
	player.set_meta("repurpose_force_success", true)
	var trap := TrapScript.new()
	trap.configure("spike", 8, 0.5, 0.1)
	trap.global_position = Vector2(1, 0)
	root.add_child(trap)
	await process_frame
	HackSkillScript.execute({"player": player})
	await process_frame
	if not bool(trap.get_meta("repurposed", false)):
		failures.append("repurpose should mark a successful hacked trap as repurposed")
	if float(trap.get_meta("repurpose_chance", 0.0)) < 0.29:
		failures.append("repurpose should expose its 30% conversion chance")
	if trap.get_node_or_null("HackExpireTimer") != null:
		failures.append("repurposed traps should stay allied for the room instead of expiring")
	if not trap.is_in_group("player_traps") or trap.is_in_group("room_traps"):
		failures.append("repurposed traps should remain allied player traps")
	if trap.apply_to(player, 99.0):
		failures.append("repurposed traps should not damage the player")
	trap.queue_free()
	player.queue_free()
	await process_frame

func _check_blade_warden_blade_rhythm_bonus(failures: Array[String]) -> void:
	var player := await _make_player("blade_warden", "warden_sword")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "blade_rhythm")):
		failures.append("blade warden should activate blade_rhythm passive")
		player.queue_free()
		await process_frame
		return
	if not player.has_method("weapon_damage_multiplier"):
		failures.append("player should expose weapon_damage_multiplier for weapon passives")
		player.queue_free()
		await process_frame
		return
	for i in 3:
		player.on_hit_landed()
	if float(player.call("weapon_damage_multiplier")) < 1.39:
		failures.append("blade_rhythm should prime +40% weapon damage after three hits")
	var feedback := player.get_node_or_null("BladeRhythmFeedback") as Label
	if feedback == null:
		failures.append("blade_rhythm should show readable primed hit feedback")
	else:
		if not feedback.text.contains("BLADE RHYTHM") or not feedback.text.contains("READY"):
			failures.append("blade_rhythm feedback should name passive and ready state")
		if str(feedback.get_meta("passive_id", "")) != "blade_rhythm":
			failures.append("blade_rhythm feedback should expose passive metadata")
		if str(feedback.get_meta("state", "")) != "primed":
			failures.append("blade_rhythm feedback should expose primed state metadata")
		if int(feedback.get_meta("hit_count", 0)) != 3:
			failures.append("blade_rhythm feedback should expose hit count metadata")
		if float(feedback.get_meta("damage_multiplier", 0.0)) < 1.39:
			failures.append("blade_rhythm feedback should expose damage multiplier metadata")
	player.crit_chance = 0.0
	var weapon := player.current_weapon()
	if weapon != null:
		var base_damage := int(weapon.call("base_damage"))
		var rolled_damage := int(weapon.call("_roll_damage"))
		if rolled_damage < int(round(float(base_damage) * player.damage_mult * 1.39)):
			failures.append("blade_rhythm should affect the next weapon damage roll")
		feedback = player.get_node_or_null("BladeRhythmFeedback") as Label
		if feedback == null or not feedback.text.contains("USED") \
				or str(feedback.get_meta("state", "")) != "consumed":
			failures.append("blade_rhythm should show consumed feedback after bonus damage is used")
	if not player.has_method("consume_weapon_damage_bonus"):
		failures.append("player should expose consume_weapon_damage_bonus")
	else:
		player.call("consume_weapon_damage_bonus")
		if not is_equal_approx(float(player.call("weapon_damage_multiplier")), 1.0):
			failures.append("blade_rhythm bonus should consume after use")
	player.queue_free()
	await process_frame

func _check_blade_warden_reflex_dash_refund(failures: Array[String]) -> void:
	var player := await _make_player("blade_warden", "warden_sword")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "reflex")):
		failures.append("blade warden should activate reflex passive")
		player.queue_free()
		await process_frame
		return
	if not player.has_method("reflex_window_left"):
		failures.append("player should expose reflex_window_left")
		player.queue_free()
		await process_frame
		return
	player.take_damage(5)
	if float(player.call("reflex_window_left")) < 0.49:
		failures.append("reflex should open a 0.5s dash refund window after damage")
	var feedback := player.get_node_or_null("ReflexFeedback") as Label
	if feedback == null:
		failures.append("reflex should show ready feedback after damage")
	else:
		if not feedback.text.contains("REFLEX READY"):
			failures.append("reflex ready feedback should name the state")
		if str(feedback.get_meta("passive_id", "")) != "reflex":
			failures.append("reflex ready feedback should expose passive metadata")
		if str(feedback.get_meta("state", "")) != "ready":
			failures.append("reflex ready feedback should expose ready state metadata")
		if float(feedback.get_meta("window_seconds", 0.0)) < 0.49:
			failures.append("reflex ready feedback should expose window duration metadata")
	player.call("_start_dash", Vector2.RIGHT)
	if float(player.call("dash_cooldown_left")) > player.dash_cooldown * 0.51:
		failures.append("reflex should refund 50% dash cooldown when dashing after damage")
	if not bool(player.get_meta("reflex_dash_refunded", false)):
		failures.append("reflex should expose dash refund metadata")
	feedback = player.get_node_or_null("ReflexFeedback") as Label
	if feedback == null:
		failures.append("reflex should show dash refund feedback")
	else:
		if not feedback.text.contains("REFLEX DASH"):
			failures.append("reflex dash feedback should name the state")
		if str(feedback.get_meta("state", "")) != "dash":
			failures.append("reflex dash feedback should expose dash state metadata")
		if float(feedback.get_meta("cooldown_multiplier", 0.0)) > 0.51:
			failures.append("reflex dash feedback should expose cooldown refund metadata")
	player.set("_dash_cd_left", 0.0)
	player.take_damage(5)
	player.call("_physics_process", 0.6)
	player.call("_start_dash", Vector2.RIGHT)
	if float(player.call("dash_cooldown_left")) < player.dash_cooldown * 0.9:
		failures.append("reflex should not refund dashes after its 0.5s window")
	player.queue_free()
	await process_frame

func _check_breaker_iron_skin_standstill_reduction(failures: Array[String]) -> void:
	var player := await _make_player("breaker", "pioneer_axe")
	player.set_physics_process(false)
	if not bool(player.call("has_passive", "iron_skin")):
		failures.append("breaker should activate iron_skin passive")
		player.queue_free()
		await process_frame
		return
	player.velocity = Vector2.ZERO
	player.take_damage(10)
	if player.hp != player.max_hp - 8:
		failures.append("iron_skin should reduce incoming damage by 20% while standing still")
	var feedback := player.get_node_or_null("IronSkinFeedback") as Label
	if feedback == null:
		failures.append("iron_skin should show readable blocked damage feedback")
	else:
		if not feedback.text.contains("IRON SKIN") or not feedback.text.contains("2"):
			failures.append("iron_skin feedback should name passive and blocked damage")
		if str(feedback.get_meta("passive_id", "")) != "iron_skin":
			failures.append("iron_skin feedback should expose passive metadata")
		if int(feedback.get_meta("blocked_damage", 0)) != 2:
			failures.append("iron_skin feedback should expose blocked damage metadata")
		if float(feedback.get_meta("damage_multiplier", 0.0)) > 0.81:
			failures.append("iron_skin feedback should expose damage multiplier metadata")
	player.hp = player.max_hp
	player.velocity = Vector2.RIGHT * 10.0
	player.take_damage(10)
	if player.hp != player.max_hp - 10:
		failures.append("iron_skin should not reduce damage while moving")
	player.queue_free()
	await process_frame

func _check_breaker_heavy_windup_charge_damage(failures: Array[String]) -> void:
	var player := await _make_player("breaker", "pioneer_axe")
	player.set_physics_process(false)
	player.crit_chance = 0.0
	if not bool(player.call("has_passive", "heavy_windup")):
		failures.append("breaker should activate heavy_windup passive")
		player.queue_free()
		await process_frame
		return
	if not player.has_method("charged_attack_damage_multiplier"):
		failures.append("player should expose charged_attack_damage_multiplier")
		player.queue_free()
		await process_frame
		return
	var weapon := player.current_weapon()
	if weapon == null or not weapon.has_method("try_charged_attack") \
			or float(weapon.call("charge_time_full")) <= 0.0:
		failures.append("breaker axe should support charged heavy_windup strikes")
		player.queue_free()
		await process_frame
		return
	var enemy := Enemy.new()
	enemy.max_hp = 120
	enemy.hp = 120
	enemy.global_position = Vector2(25, 0)
	root.add_child(enemy)
	await process_frame
	var full_time := float(weapon.call("charge_time_full"))
	weapon.call("try_charged_attack", player.global_position, Vector2.RIGHT, full_time)
	await process_frame
	if enemy.hp > 80:
		failures.append("heavy_windup full charge should add +50% strike damage")
	if float(weapon.get_meta("heavy_windup_damage_mult", 0.0)) < 1.49:
		failures.append("heavy_windup should expose charge damage multiplier metadata")
	if float(weapon.get_meta("heavy_windup_cleave_width_mult", 0.0)) < 1.29:
		failures.append("heavy_windup should expose +30% cleave width metadata")
	var feedback := player.get_node_or_null("HeavyWindupFeedback") as Label
	if feedback == null:
		failures.append("heavy_windup should show full charge feedback")
	else:
		if not feedback.text.contains("HEAVY WINDUP"):
			failures.append("heavy_windup feedback should name the passive")
		if not feedback.text.contains("x1.5"):
			failures.append("heavy_windup feedback should show damage multiplier")
		if str(feedback.get_meta("passive_id", "")) != "heavy_windup":
			failures.append("heavy_windup feedback should expose passive metadata")
		if float(feedback.get_meta("damage_multiplier", 0.0)) < 1.49:
			failures.append("heavy_windup feedback should expose damage multiplier metadata")
		if float(feedback.get_meta("cleave_width_multiplier", 0.0)) < 1.29:
			failures.append("heavy_windup feedback should expose cleave width metadata")
	enemy.queue_free()
	player.queue_free()
	await process_frame

func _make_player(class_id: String, starter_weapon: String) -> Player:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data(class_id), "fire", starter_weapon)
	return player

func _player_summon_count() -> int:
	var count := 0
	for summon in root.get_tree().get_nodes_in_group("player_summons"):
		if is_instance_valid(summon) and not summon.is_queued_for_deletion():
			count += 1
	return count
