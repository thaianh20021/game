extends SceneTree

const UpgradeDBScript := preload("res://scripts/progression/upgrade_db.gd")

func _init() -> void:
	var failures: Array[String] = []

	await _check_rune_upgrade_hooks(failures)

	if failures.is_empty():
		print("Rune upgrade smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_rune_upgrade_hooks(failures: Array[String]) -> void:
	var player := await _make_player()
	var weapon := player.current_weapon()
	if weapon == null:
		failures.append("player should have a weapon for rune smoke")
		player.queue_free()
		await process_frame
		return

	if not _pool_has("ember_rune"):
		failures.append("upgrade pool should include ember_rune")
	if not _pool_has("frost_rune"):
		failures.append("upgrade pool should include frost_rune")
	if not _pool_has("storm_rune"):
		failures.append("upgrade pool should include storm_rune")
	if not _pool_has("venom_rune"):
		failures.append("upgrade pool should include venom_rune")
	if not _pool_has("split_socket"):
		failures.append("upgrade pool should include split_socket")
	if not _pool_has("familiar_rune"):
		failures.append("upgrade pool should include familiar_rune")
	if not _pool_has("aegis_socket"):
		failures.append("upgrade pool should include aegis_socket")
	if not _pool_has("spell_thread"):
		failures.append("upgrade pool should include spell_thread")
	if not _pool_has("soul_capacitor"):
		failures.append("upgrade pool should include soul_capacitor")
	if not weapon.has_method("socket_capacity"):
		failures.append("weapon should expose socket_capacity")
	if not player.has_method("socket_capacity"):
		failures.append("player should expose active weapon socket_capacity")
	if not player.has_method("socket_upgrade_count"):
		failures.append("player should expose socket_upgrade_count")
	if not player.has_method("rune_socket_summary"):
		failures.append("player should expose rune_socket_summary for HUD/pause build breakdown")

	var before_skill_base := 0
	if not player.has_method("skill_base_damage"):
		failures.append("player should expose skill_base_damage for rune-scaled skills")
	else:
		before_skill_base = int(player.call("skill_base_damage"))
	if not UpgradeDBScript.apply_upgrade(player, "ember_rune"):
		failures.append("ember_rune should apply")
	var element_bonus = player.get("element_damage_bonus")
	if not (element_bonus is Dictionary) or float(element_bonus.get("fire", 0.0)) <= 0.0:
		failures.append("ember_rune should add fire damage bonus")
	if player.has_method("skill_base_damage") and int(player.call("skill_base_damage")) <= before_skill_base:
		failures.append("ember_rune should increase fire active skill base damage")
	_check_element_rune(player, "frost_rune", "ice", failures)
	_check_element_rune(player, "storm_rune", "lightning", failures)
	_check_element_rune(player, "venom_rune", "poison", failures)

	weapon.equip("storm_scepter")
	var before_projectiles := weapon.projectile_count()
	if not UpgradeDBScript.apply_upgrade(player, "split_socket"):
		failures.append("split_socket should apply")
	if int(player.get("projectile_bonus")) <= 0:
		failures.append("split_socket should add projectile_bonus")
	if weapon.projectile_count() <= before_projectiles:
		failures.append("split_socket should increase projectile_count")
	if player.has_method("socket_capacity") and int(player.call("socket_capacity")) < 3:
		failures.append("storm_scepter should provide three upgrade sockets")
	if player.has_method("socket_upgrade_count") and int(player.call("socket_upgrade_count")) != 1:
		failures.append("split_socket should occupy one weapon socket")

	var before_pet := float(player.get("pet_damage_mult"))
	if not UpgradeDBScript.apply_upgrade(player, "familiar_rune"):
		failures.append("familiar_rune should apply")
	if float(player.get("pet_damage_mult")) <= before_pet:
		failures.append("familiar_rune should increase pet damage")

	var before_shield := float(player.get("shield_duration_mult"))
	if not UpgradeDBScript.apply_upgrade(player, "aegis_socket"):
		failures.append("aegis_socket should apply")
	if float(player.get("shield_duration_mult")) <= before_shield:
		failures.append("aegis_socket should increase shield duration")
	if player.has_method("socket_upgrade_count") and int(player.call("socket_upgrade_count")) != 2:
		failures.append("aegis_socket should occupy a weapon socket")
	if player.has_method("rune_socket_summary"):
		var breakdown := str(player.call("rune_socket_summary"))
		if not breakdown.contains("Sockets 2/3"):
			failures.append("rune_socket_summary should show used weapon sockets")
		if not breakdown.contains("Fire x1") or not breakdown.contains("Ice x1") \
				or not breakdown.contains("Lightning x1") or not breakdown.contains("Poison x1"):
			failures.append("rune_socket_summary should show applied elemental rune stacks")
		if not breakdown.contains("Split Socket") or not breakdown.contains("Aegis Socket"):
			failures.append("rune_socket_summary should name socket upgrades")

	var before_dash := player.dash_cooldown
	if not UpgradeDBScript.apply_upgrade(player, "dash_spring"):
		failures.append("dash_spring should apply")
	if player.dash_cooldown >= before_dash:
		failures.append("dash_spring should reduce dash cooldown")

	var before_skill_cd_mult := 1.0
	if not player.has_method("skill_cooldown_multiplier"):
		failures.append("player should expose skill_cooldown_multiplier")
	else:
		before_skill_cd_mult = float(player.call("skill_cooldown_multiplier"))
	if not UpgradeDBScript.apply_upgrade(player, "spell_thread"):
		failures.append("spell_thread should apply")
	elif player.has_method("skill_cooldown_multiplier") \
			and float(player.call("skill_cooldown_multiplier")) >= before_skill_cd_mult:
		failures.append("spell_thread should reduce skill cooldown multiplier")
	if player.has_method("skill_cooldown_multiplier"):
		var cooldown_event := {"total": 0.0}
		player.skill = {"id": "wind_edge", "cost": 0, "cooldown": 6.0}
		player.skill_cooldown_changed.connect(func(id: String, _left: float, total: float) -> void:
			if id == "wind_edge":
				cooldown_event["total"] = total)
		player.call("_try_skill")
		await process_frame
		if float(cooldown_event["total"]) >= 6.0 or float(cooldown_event["total"]) <= 0.0:
			failures.append("spell_thread should shorten real skill cast cooldown")

	var before_charge_mult := 1.0
	if not player.has_method("ultimate_charge_gain_multiplier"):
		failures.append("player should expose ultimate_charge_gain_multiplier")
	else:
		before_charge_mult = float(player.call("ultimate_charge_gain_multiplier"))
	if not UpgradeDBScript.apply_upgrade(player, "soul_capacitor"):
		failures.append("soul_capacitor should apply")
	elif player.has_method("ultimate_charge_gain_multiplier") \
			and float(player.call("ultimate_charge_gain_multiplier")) <= before_charge_mult:
		failures.append("soul_capacitor should increase ultimate charge gain multiplier")
	player.ultimate_charge = 0.0
	player.call("add_ultimate_charge", 10.0)
	if float(player.ultimate_charge) <= 10.0:
		failures.append("soul_capacitor should increase real ultimate charge gains")
	var stat_summary := player.run_stat_summary()
	if not stat_summary.contains("Skill CD") or not stat_summary.contains("Ult charge"):
		failures.append("run_stat_summary should show skill cooldown and ultimate charge upgrades")

	player.queue_free()
	await process_frame

	await _check_socket_capacity_gate(failures)

func _pool_has(id: String) -> bool:
	for upgrade in UpgradeDBScript.UPGRADES:
		if str(upgrade.get("id", "")) == id:
			return true
	return false

func _check_element_rune(
		player: Player,
		upgrade_id: String,
		element: String,
		failures: Array[String],
) -> void:
	player.equipped_element = element
	var before_bonus := float(player.element_damage_bonus.get(element, 0.0))
	var before_damage := int(player.call("skill_base_damage")) if player.has_method("skill_base_damage") else 0
	if not UpgradeDBScript.apply_upgrade(player, upgrade_id):
		failures.append("%s should apply" % upgrade_id)
		return
	if float(player.element_damage_bonus.get(element, 0.0)) <= before_bonus:
		failures.append("%s should add %s damage bonus" % [upgrade_id, element])
	if player.has_method("skill_base_damage") and int(player.call("skill_base_damage")) <= before_damage:
		failures.append("%s should increase %s active skill base damage" % [upgrade_id, element])

func _check_socket_capacity_gate(failures: Array[String]) -> void:
	var player := await _make_player()
	var weapon := player.current_weapon()
	if weapon == null:
		failures.append("socket capacity gate needs a starter weapon")
		return
	weapon.equip("warden_sword")
	if player.has_method("socket_capacity") and int(player.call("socket_capacity")) != 1:
		failures.append("warden_sword should expose one socket")
	if not UpgradeDBScript.apply_upgrade(player, "split_socket"):
		failures.append("first socket upgrade should fit a one-socket weapon")
	if UpgradeDBScript.can_apply_upgrade(player, "aegis_socket"):
		failures.append("second socket upgrade should be blocked on a one-socket weapon")
	var upgrade_db := UpgradeDBScript.new()
	if not upgrade_db.has_method("upgrade_block_reason"):
		failures.append("UpgradeDB should explain unavailable upgrades")
	elif not str(upgrade_db.call("upgrade_block_reason", player, "aegis_socket")).contains("Sockets full"):
		failures.append("socket-blocked upgrade should explain sockets full")
	if UpgradeDBScript.apply_upgrade(player, "aegis_socket"):
		failures.append("blocked socket upgrade should not apply")
	player.queue_free()
	await process_frame

func _make_player() -> Player:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	return player
