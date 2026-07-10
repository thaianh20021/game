extends SceneTree

const UpgradeDBScript := preload("res://scripts/progression/upgrade_db.gd")

func _init() -> void:
	var failures: Array[String] = []

	await _check_upgrade_stacks_and_hud(failures)
	await _check_mobility_set_bonus(failures)
	await _check_element_set_bonus(failures)
	await _check_pet_set_bonus(failures)
	await _check_shield_set_bonus(failures)
	await _check_projectile_set_bonus(failures)
	await _check_skill_set_bonus(failures)
	await _check_resource_set_bonus(failures)

	if failures.is_empty():
		print("Upgrade stack smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_upgrade_stacks_and_hud(failures: Array[String]) -> void:
	var player := await _make_player()
	var floor := FloorController.new()
	root.add_child(floor)
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, floor)

	var emitted := {"count": 0}
	if not _has_signal(player, "upgrades_changed"):
		failures.append("player should expose upgrades_changed signal")
	else:
		player.connect("upgrades_changed", func(_summary: String) -> void:
			emitted["count"] += 1)
	if not player.has_method("upgrade_stack_count"):
		failures.append("player should expose upgrade_stack_count")
	if not player.has_method("upgrade_summary"):
		failures.append("player should expose upgrade_summary")
	if not player.has_method("upgrade_history_summary"):
		failures.append("player should expose ordered upgrade_history_summary")
	if not player.has_method("upgrade_history_count"):
		failures.append("player should expose upgrade_history_count for compact history UI")
	if not player.has_method("next_power_milestone_hint"):
		failures.append("player should expose next_power_milestone_hint for run progression clarity")
	if not player.has_method("upgrade_set_bonus_summary"):
		failures.append("player should expose upgrade_set_bonus_summary for build set bonuses")
	var damage_before := player.damage_mult

	UpgradeDBScript.apply_upgrade(player, "power_rune")
	UpgradeDBScript.apply_upgrade(player, "power_rune")
	UpgradeDBScript.apply_upgrade(player, "dash_spring")
	UpgradeDBScript.apply_upgrade(player, "power_rune")
	var blocked_power := UpgradeDBScript.apply_upgrade(player, "power_rune")
	await process_frame

	if player.has_method("upgrade_stack_count") and int(player.call("upgrade_stack_count", "power_rune")) != 3:
		failures.append("player should stack repeated upgrades")
	if player.has_method("upgrade_summary") and not str(player.call("upgrade_summary")).contains("Power Rune x3"):
		failures.append("upgrade summary should include stacked display names")
	if player.has_method("upgrade_history_summary") \
			and str(player.call("upgrade_history_summary")).find("Power Rune -> Power Rune -> Dash Spring -> Power Rune") == -1:
		failures.append("upgrade history should preserve pickup order")
	if player.has_method("upgrade_history_count") and int(player.call("upgrade_history_count")) != 4:
		failures.append("upgrade_history_count should track full pickup history length")
	if player.has_method("next_power_milestone_hint") \
			and str(player.call("next_power_milestone_hint")) != "Next: Tier III in 2 picks":
		failures.append("next_power_milestone_hint should show the next tier and remaining picks")
	if player.has_method("upgrade_set_bonus_summary"):
		var set_bonus := str(player.call("upgrade_set_bonus_summary"))
		if not set_bonus.contains("Damage x3") or not set_bonus.contains("+8% dmg"):
			failures.append("upgrade set bonus summary should show the damage x3 set bonus")
	if player.damage_mult < damage_before + 0.43:
		failures.append("damage x3 set bonus should add bonus damage beyond three power_rune stacks")
	player.record_room_decision("Reward", "Rerolled -8 Gold")
	player.record_room_decision("Reward", "Skipped +10 Gold")
	player.record_shop_purchase("Swift Boots", "Best Fit")
	await process_frame
	if blocked_power:
		failures.append("maxed upgrade should reject extra applications")
	if player.has_method("upgrade_stack_count") and int(player.call("upgrade_stack_count", "power_rune")) != 3:
		failures.append("rejected maxed upgrade should not increase stacks")
	if int(emitted["count"]) < 4:
		failures.append("upgrades_changed should emit after each applied upgrade")
	if not _has_label_containing(hud, "Power Rune x3"):
		failures.append("HUD should show upgrade stack summary")
	var reward_path := hud.get_node_or_null("RewardPathLabel") as Label
	if reward_path == null:
		failures.append("HUD should expose a compact reward path label")
	else:
		if not reward_path.text.contains("Reward Path:") \
				or not reward_path.text.contains("Dash Spring -> Power Rune"):
			failures.append("HUD reward path should store recent ordered reward picks")
		if int(reward_path.get_meta("upgrade_history_count", 0)) != 4:
			failures.append("HUD reward path should store full upgrade history count")
		if str(reward_path.get_meta("last_reward_pick", "")) != "Power Rune":
			failures.append("HUD reward path should store the last reward pick")
		if not str(reward_path.get_meta("upgrade_history", "")).contains("Dash Spring"):
			failures.append("HUD reward path should store readable upgrade history")
	var decision_path := hud.get_node_or_null("RunDecisionLabel") as Label
	if decision_path == null:
		failures.append("HUD should expose a compact run decision label")
	else:
		if not decision_path.text.contains("Run Decisions:") \
				or not decision_path.text.contains("Skipped +10 Gold") \
				or not decision_path.text.contains("Shop: Swift Boots"):
			failures.append("HUD run decision label should store reward/shop decision history")
		if not str(decision_path.get_meta("room_decision_history", "")).contains("Rerolled -8 Gold"):
			failures.append("HUD run decision label should store room decision history metadata")
		if not str(decision_path.get_meta("shop_purchase_history", "")).contains("Swift Boots"):
			failures.append("HUD run decision label should store shop decision history metadata")
		if str(decision_path.get_meta("last_run_decision", "")) != "Shop: Swift Boots (Best Fit)":
			failures.append("HUD run decision label should store the latest readable decision")
	var build_label := hud.get_node_or_null("BuildLabel") as Label
	if build_label == null:
		failures.append("HUD should expose build label")
	elif not str(build_label.text).contains("Next: Tier III in 2 picks") \
			or str(build_label.get_meta("next_power_milestone", "")) != "Next: Tier III in 2 picks":
		failures.append("HUD should show and store the next power milestone hint")
	elif not str(build_label.text).contains("Set Bonuses: Damage x3 +8% dmg") \
			or not str(build_label.get_meta("upgrade_set_bonuses", "")).contains("Damage x3"):
		failures.append("HUD build label should show and store upgrade set bonuses")
	var power_flash := hud.get_node_or_null("PowerTierFlashLabel") as Label
	if power_flash == null:
		failures.append("HUD should expose a power tier flash label")
	elif not power_flash.visible or not power_flash.text.contains("Power Tier") \
			or not power_flash.text.contains("Tier II"):
		failures.append("HUD should flash the new run power tier after enough upgrades")
	else:
		if str(power_flash.get_meta("previous_power_tier", "")) != "Tier I":
			failures.append("power tier flash should store previous tier metadata")
		if str(power_flash.get_meta("power_tier", "")) != "Tier II":
			failures.append("power tier flash should store new tier metadata")
	var power_sfx := hud.get_node_or_null("PowerTierSfx") as AudioStreamPlayer
	if power_sfx == null:
		failures.append("HUD power tier feedback should create sound placeholder")
	else:
		if str(power_sfx.get_meta("power_tier_sound_id", "")) != "power_tier_up":
			failures.append("power tier sound should expose cue id")
		if str(power_sfx.get_meta("power_tier", "")) != "Tier II":
			failures.append("power tier sound should store new tier metadata")
		if str(power_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("power tier sound should come from AudioCueDB")
		if power_sfx.stream == null:
			failures.append("power tier sound should assign an audio stream")
		if DisplayServer.get_name() == "headless" \
				and not bool(power_sfx.get_meta("headless_playback_skipped", false)):
			failures.append("power tier sound should skip playback in headless smoke")

	hud.queue_free()
	floor.queue_free()
	player.queue_free()
	await process_frame

func _check_mobility_set_bonus(failures: Array[String]) -> void:
	var player := await _make_player()
	var floor := FloorController.new()
	root.add_child(floor)
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, floor)

	UpgradeDBScript.apply_upgrade(player, "swift_boots")
	UpgradeDBScript.apply_upgrade(player, "dash_spring")
	var dash_after_dash_spring := player.dash_cooldown
	UpgradeDBScript.apply_upgrade(player, "swift_boots")
	await process_frame

	if player.has_method("upgrade_tag_stack_count") \
			and int(player.call("upgrade_tag_stack_count", "mobility")) != 3:
		failures.append("mobility set bonus should count all mobility-tagged upgrade stacks")
	var expected_dash := maxf(dash_after_dash_spring * 0.92, 0.25)
	if absf(player.dash_cooldown - expected_dash) > 0.001:
		failures.append("mobility x3 set bonus should reduce dash cooldown once")
	if player.has_method("upgrade_set_bonus_summary"):
		var set_bonus := str(player.call("upgrade_set_bonus_summary"))
		if not set_bonus.contains("Mobility x3") or not set_bonus.contains("-8% dash CD"):
			failures.append("upgrade set bonus summary should show the mobility x3 set bonus")
	var build_label := hud.get_node_or_null("BuildLabel") as Label
	if build_label == null:
		failures.append("HUD should expose build label for mobility set bonus")
	elif not str(build_label.text).contains("Set Bonuses: Mobility x3 -8% dash CD") \
			or not str(build_label.get_meta("upgrade_set_bonuses", "")).contains("Mobility x3"):
		failures.append("HUD build label should show and store mobility set bonuses")

	hud.queue_free()
	floor.queue_free()
	player.queue_free()
	await process_frame

func _check_element_set_bonus(failures: Array[String]) -> void:
	var player := await _make_player()
	var floor := FloorController.new()
	root.add_child(floor)
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, floor)

	UpgradeDBScript.apply_upgrade(player, "ember_rune")
	UpgradeDBScript.apply_upgrade(player, "frost_rune")
	UpgradeDBScript.apply_upgrade(player, "storm_rune")
	await process_frame

	if player.has_method("upgrade_tag_stack_count") \
			and int(player.call("upgrade_tag_stack_count", "element")) != 3:
		failures.append("element set bonus should count all element-tagged rune stacks")
	if absf(player.element_damage_multiplier("fire") - 1.21) > 0.001 \
			or absf(player.element_damage_multiplier("ice") - 1.21) > 0.001 \
			or absf(player.element_damage_multiplier("lightning") - 1.21) > 0.001 \
			or absf(player.element_damage_multiplier("poison") - 1.06) > 0.001:
		failures.append("element x3 set bonus should add +6% elemental damage to every element")
	if player.has_method("upgrade_set_bonus_summary"):
		var set_bonus := str(player.call("upgrade_set_bonus_summary"))
		if not set_bonus.contains("Element x3") or not set_bonus.contains("+6% elem dmg"):
			failures.append("upgrade set bonus summary should show the element x3 set bonus")
	var build_label := hud.get_node_or_null("BuildLabel") as Label
	if build_label == null:
		failures.append("HUD should expose build label for element set bonus")
	elif not str(build_label.text).contains("Element x3 +6% elem dmg") \
			or not str(build_label.get_meta("upgrade_set_bonuses", "")).contains("Element x3"):
		failures.append("HUD build label should show and store element set bonuses")

	hud.queue_free()
	floor.queue_free()
	player.queue_free()
	await process_frame

func _check_pet_set_bonus(failures: Array[String]) -> void:
	var player := await _make_player()
	var floor := FloorController.new()
	root.add_child(floor)
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, floor)

	UpgradeDBScript.apply_upgrade(player, "familiar_rune")
	UpgradeDBScript.apply_upgrade(player, "familiar_rune")
	UpgradeDBScript.apply_upgrade(player, "familiar_rune")
	await process_frame

	if player.has_method("upgrade_tag_stack_count") \
			and int(player.call("upgrade_tag_stack_count", "pet")) != 3:
		failures.append("pet set bonus should count all pet-tagged upgrade stacks")
	if absf(player.pet_damage_multiplier() - 1.72) > 0.001:
		failures.append("pet x3 set bonus should add +12% pet damage beyond rune stacks")
	if player.has_method("upgrade_set_bonus_summary"):
		var set_bonus := str(player.call("upgrade_set_bonus_summary"))
		if not set_bonus.contains("Pet x3") or not set_bonus.contains("+12% pet dmg"):
			failures.append("upgrade set bonus summary should show the pet x3 set bonus")
	var build_label := hud.get_node_or_null("BuildLabel") as Label
	if build_label == null:
		failures.append("HUD should expose build label for pet set bonus")
	elif not str(build_label.text).contains("Pet x3 +12% pet dmg") \
			or not str(build_label.get_meta("upgrade_set_bonuses", "")).contains("Pet x3"):
		failures.append("HUD build label should show and store pet set bonuses")

	hud.queue_free()
	floor.queue_free()
	player.queue_free()
	await process_frame

func _check_shield_set_bonus(failures: Array[String]) -> void:
	var player := await _make_player()
	var weapon := player.current_weapon()
	if weapon != null:
		weapon.equip("storm_scepter")
	var floor := FloorController.new()
	root.add_child(floor)
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, floor)

	UpgradeDBScript.apply_upgrade(player, "aegis_socket")
	UpgradeDBScript.apply_upgrade(player, "aegis_socket")
	UpgradeDBScript.apply_upgrade(player, "aegis_socket")
	await process_frame

	if player.has_method("socket_capacity") and int(player.call("socket_capacity")) < 3:
		failures.append("shield set bonus smoke needs a three-socket weapon")
	if player.has_method("socket_upgrade_count") and int(player.call("socket_upgrade_count")) != 3:
		failures.append("shield set bonus should use three real weapon sockets")
	if player.has_method("upgrade_tag_stack_count") \
			and int(player.call("upgrade_tag_stack_count", "shield")) != 3:
		failures.append("shield set bonus should count all shield-tagged socket stacks")
	if absf(player.shield_duration_mult - 1.85) > 0.001:
		failures.append("shield x3 set bonus should add +10% shield duration beyond socket stacks")
	if player.has_method("upgrade_set_bonus_summary"):
		var set_bonus := str(player.call("upgrade_set_bonus_summary"))
		if not set_bonus.contains("Shield x3") or not set_bonus.contains("+10% shield dur"):
			failures.append("upgrade set bonus summary should show the shield x3 set bonus")
	var build_label := hud.get_node_or_null("BuildLabel") as Label
	if build_label == null:
		failures.append("HUD should expose build label for shield set bonus")
	elif not str(build_label.text).contains("Shield x3 +10% shield dur") \
			or not str(build_label.get_meta("upgrade_set_bonuses", "")).contains("Shield x3"):
		failures.append("HUD build label should show and store shield set bonuses")

	hud.queue_free()
	floor.queue_free()
	player.queue_free()
	await process_frame

func _check_projectile_set_bonus(failures: Array[String]) -> void:
	var player := await _make_player()
	var weapon := player.current_weapon()
	if weapon != null:
		weapon.equip("storm_scepter")
	var floor := FloorController.new()
	root.add_child(floor)
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, floor)

	UpgradeDBScript.apply_upgrade(player, "split_socket")
	UpgradeDBScript.apply_upgrade(player, "split_socket")
	UpgradeDBScript.apply_upgrade(player, "split_socket")
	await process_frame

	if player.has_method("socket_capacity") and int(player.call("socket_capacity")) < 3:
		failures.append("projectile set bonus smoke needs a three-socket weapon")
	if player.has_method("socket_upgrade_count") and int(player.call("socket_upgrade_count")) != 3:
		failures.append("projectile set bonus should use three real weapon sockets")
	if player.has_method("upgrade_tag_stack_count") \
			and int(player.call("upgrade_tag_stack_count", "projectile")) != 3:
		failures.append("projectile set bonus should count all projectile-tagged socket stacks")
	if int(player.projectile_bonus) != 4:
		failures.append("projectile x3 set bonus should add +1 projectile beyond socket stacks")
	elif weapon == null or weapon.projectile_count() != 5:
		failures.append("projectile x3 set bonus should affect active weapon projectile count")
	if player.has_method("upgrade_set_bonus_summary"):
		var set_bonus := str(player.call("upgrade_set_bonus_summary"))
		if not set_bonus.contains("Projectile x3") or not set_bonus.contains("+1 projectile"):
			failures.append("upgrade set bonus summary should show the projectile x3 set bonus")
	var build_label := hud.get_node_or_null("BuildLabel") as Label
	if build_label == null:
		failures.append("HUD should expose build label for projectile set bonus")
	elif not str(build_label.text).contains("Projectile x3 +1 projectile") \
			or not str(build_label.get_meta("upgrade_set_bonuses", "")).contains("Projectile x3"):
		failures.append("HUD build label should show and store projectile set bonuses")

	hud.queue_free()
	floor.queue_free()
	player.queue_free()
	await process_frame

func _check_skill_set_bonus(failures: Array[String]) -> void:
	var player := await _make_player()
	var floor := FloorController.new()
	root.add_child(floor)
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, floor)

	UpgradeDBScript.apply_upgrade(player, "spell_thread")
	UpgradeDBScript.apply_upgrade(player, "spell_thread")
	var cooldown_after_two := player.skill_cooldown_multiplier()
	UpgradeDBScript.apply_upgrade(player, "spell_thread")
	await process_frame

	if player.has_method("upgrade_tag_stack_count") \
			and int(player.call("upgrade_tag_stack_count", "skill")) != 3:
		failures.append("skill set bonus should count all skill-tagged upgrade stacks")
	var expected_cd := maxf(cooldown_after_two * 0.9 * 0.92, 0.55)
	if absf(player.skill_cooldown_multiplier() - expected_cd) > 0.001:
		failures.append("skill x3 set bonus should reduce active skill cooldown beyond spell_thread stacks")
	if player.has_method("upgrade_set_bonus_summary"):
		var set_bonus := str(player.call("upgrade_set_bonus_summary"))
		if not set_bonus.contains("Skill x3") or not set_bonus.contains("-8% skill CD"):
			failures.append("upgrade set bonus summary should show the skill x3 set bonus")
	var build_label := hud.get_node_or_null("BuildLabel") as Label
	if build_label == null:
		failures.append("HUD should expose build label for skill set bonus")
	elif not str(build_label.text).contains("Skill x3 -8% skill CD") \
			or not str(build_label.get_meta("upgrade_set_bonuses", "")).contains("Skill x3"):
		failures.append("HUD build label should show and store skill set bonuses")

	hud.queue_free()
	floor.queue_free()
	player.queue_free()
	await process_frame

func _check_resource_set_bonus(failures: Array[String]) -> void:
	var player := await _make_player()
	var floor := FloorController.new()
	root.add_child(floor)
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, floor)

	UpgradeDBScript.apply_upgrade(player, "focus_cell")
	UpgradeDBScript.apply_upgrade(player, "soul_capacitor")
	var max_resource_after_two := player.max_resource
	var charge_after_two := player.ultimate_charge_gain_multiplier()
	UpgradeDBScript.apply_upgrade(player, "soul_capacitor")
	await process_frame

	if player.has_method("upgrade_tag_stack_count") \
			and int(player.call("upgrade_tag_stack_count", "resource")) != 3:
		failures.append("resource set bonus should count resource-tagged focus/capacitor stacks")
	if absf(player.max_resource - (max_resource_after_two + 10.0)) > 0.001:
		failures.append("resource x3 set bonus should add max resource beyond focus_cell")
	if absf(player.ultimate_charge_gain_multiplier() - (charge_after_two + 0.2 + 0.1)) > 0.001:
		failures.append("resource x3 set bonus should add ultimate charge gain beyond soul_capacitor stacks")
	player.ultimate_charge = 0.0
	player.add_ultimate_charge(10.0)
	if absf(player.ultimate_charge - (10.0 * player.ultimate_charge_gain_multiplier())) > 0.001:
		failures.append("resource x3 set bonus should affect real ultimate charge gains")
	if player.has_method("upgrade_set_bonus_summary"):
		var set_bonus := str(player.call("upgrade_set_bonus_summary"))
		if not set_bonus.contains("Resource x3") or not set_bonus.contains("+10 res") \
				or not set_bonus.contains("+10% ult charge"):
			failures.append("upgrade set bonus summary should show the resource x3 set bonus")
	var build_label := hud.get_node_or_null("BuildLabel") as Label
	if build_label == null:
		failures.append("HUD should expose build label for resource set bonus")
	elif not str(build_label.text).contains("Resource x3 +10 res / +10% ult charge") \
			or not str(build_label.get_meta("upgrade_set_bonuses", "")).contains("Resource x3"):
		failures.append("HUD build label should show and store resource set bonuses")

	hud.queue_free()
	floor.queue_free()
	player.queue_free()
	await process_frame

func _make_player() -> Player:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	return player

func _has_signal(node: Object, signal_name: String) -> bool:
	for info in node.get_signal_list():
		if str(info.get("name", "")) == signal_name:
			return true
	return false

func _has_label_containing(parent: Node, text: String) -> bool:
	for child in parent.find_children("*", "Label", true, false):
		if str(child.text).contains(text):
			return true
	return false
