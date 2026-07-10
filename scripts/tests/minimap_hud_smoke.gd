extends SceneTree

const UpgradeDBScript := preload("res://scripts/progression/upgrade_db.gd")
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

func _init() -> void:
	var failures: Array[String] = []

	await _check_minimap_legend_and_room_semantics(failures)
	await _check_hud_player_status_feedback(failures)
	await _check_hud_meta_bonus_feedback(failures)
	await _check_hud_biome_mastery_feedback(failures)
	await _check_hud_element_combo_feedback(failures)
	await _check_hud_skill_cast_feedback(failures)
	await _check_hud_skill_ready_feedback(failures)
	await _check_hud_dash_cooldown_feedback(failures)
	await _check_hud_playable_compact_layout(failures)
	await _check_hud_run_stats_feedback(failures)
	await _check_hud_floor_difficulty_feedback(failures)
	await _check_hud_boss_status_feedback(failures)
	await _check_hud_boss_phase_signal_feedback(failures)
	await _check_hud_boss_attack_signal_feedback(failures)
	await _check_hud_trap_room_live_objective(failures)
	await _check_hud_combat_wave_live_objective(failures)
	await _check_hud_room_objective_clear_feedback(failures)
	await _check_hud_clean_playtest_mode(failures)

	if failures.is_empty():
		print("Minimap HUD smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_minimap_legend_and_room_semantics(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	root.add_child(ctrl)
	var builder := GraphBuilder.new()
	ctrl.rooms = builder.build(1234, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.ENTRANCE)
	ctrl.visited_rooms[ctrl.current_room.id] = true
	ctrl.cleared_rooms[ctrl.current_room.id] = true

	var minimap := Minimap.new()
	minimap.size = Vector2(188, 96)
	root.add_child(minimap)
	minimap.bind(ctrl)
	await process_frame

	if minimap.get_node_or_null("MinimapLegend") == null:
		failures.append("minimap should expose a compact legend")
	if not _has_label_containing(minimap, "Current"):
		failures.append("minimap legend should label the current room state")
	if not _has_label_containing(minimap, "Visited"):
		failures.append("minimap legend should label visited rooms")
	if not _has_label_containing(minimap, "Main"):
		failures.append("minimap legend should label the main path")
	if not minimap.has_method("known_room_ids"):
		failures.append("minimap should expose known_room_ids for fog-of-war verification")
	else:
		var known: Array = minimap.call("known_room_ids")
		if not known.has(ctrl.current_room.id):
			failures.append("known_room_ids should include the current room")
		for neighbor in ctrl.current_room.neighbors:
			if not known.has(neighbor):
				failures.append("known_room_ids should include direct neighbors of visited rooms")
				break
	if not minimap.has_method("room_glyph"):
		failures.append("minimap should expose ASCII room glyphs")
	else:
		for room_type in [RoomNode.RoomType.SHOP, RoomNode.RoomType.TREASURE, RoomNode.RoomType.HEAL, RoomNode.RoomType.BOSS]:
			if str(minimap.call("room_glyph", room_type)) == "":
				failures.append("minimap room glyph should not be blank for %s" % RoomNode.RoomType.keys()[room_type])
		if str(minimap.call("room_glyph", RoomNode.RoomType.SHRINE)) != "A":
			failures.append("minimap shrine room glyph should read as elemental altar")
	if not minimap.has_method("tooltip_text"):
		failures.append("minimap should expose tooltip text for room inspection")
	else:
		var boss := _first_room_of_type(ctrl.rooms, RoomNode.RoomType.BOSS)
		var text := str(minimap.call("tooltip_text", boss.id))
		if not text.contains("BOSS"):
			failures.append("minimap tooltip should include room type name")
		if not text.contains("Main path"):
			failures.append("minimap tooltip should mark boss as main path")
		if not text.contains("Risk: Boss") or not text.contains("Reward: Rare+ + Portal"):
			failures.append("minimap boss tooltip should explain boss risk and reward")
		if not text.contains("Threat x"):
			failures.append("minimap tooltip should include current floor threat")
		var side := _first_side_branch(ctrl.rooms)
		if side != null and not str(minimap.call("tooltip_text", side.id)).contains("Side branch"):
			failures.append("minimap tooltip should mark side branch rooms")
		var shrine := _first_room_of_type(ctrl.rooms, RoomNode.RoomType.SHRINE)
		if shrine != null and not str(minimap.call("tooltip_text", shrine.id)).contains("ALTAR"):
			failures.append("minimap tooltip should label shrine rooms as ALTAR")
		var treasure := _first_room_of_type(ctrl.rooms, RoomNode.RoomType.TREASURE)
		if treasure != null:
			var treasure_text := str(minimap.call("tooltip_text", treasure.id))
			if not treasure_text.contains("Reward: Chest + Upgrade"):
				failures.append("minimap treasure tooltip should preview chest reward")
		var shop := _first_room_of_type(ctrl.rooms, RoomNode.RoomType.SHOP)
		if shop != null:
			var shop_text := str(minimap.call("tooltip_text", shop.id))
			if not shop_text.contains("Reward: Choose 1 of 3"):
				failures.append("minimap shop tooltip should preview 3-item choice")
		var heal := _first_room_of_type(ctrl.rooms, RoomNode.RoomType.HEAL)
		if heal != null:
			var heal_text := str(minimap.call("tooltip_text", heal.id))
			if not heal_text.contains("Safety: Heal once"):
				failures.append("minimap heal tooltip should preview one-use heal shrine")
	if not minimap.has_method("critical_path_room_ids"):
		failures.append("minimap should expose critical_path_room_ids")
	else:
		var path: Array = minimap.call("critical_path_room_ids")
		var boss := _first_room_of_type(ctrl.rooms, RoomNode.RoomType.BOSS)
		if path.is_empty() or int(path[0]) != ctrl.current_room.id:
			failures.append("critical_path_room_ids should start at entrance")
		if path.is_empty() or int(path[path.size() - 1]) != boss.id:
			failures.append("critical_path_room_ids should end at boss")

	minimap.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_clean_playtest_mode(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var builder := GraphBuilder.new()
	ctrl.rooms = builder.build(420101, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.COMBAT)
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	hud.bind(player, ctrl)
	if not hud.has_method("set_clean_playtest_mode"):
		failures.append("HUD should expose set_clean_playtest_mode for uncluttered manual playtests")
	else:
		hud.call("set_clean_playtest_mode", true)
	await process_frame
	for label_name in [
		"WeaponLabel",
		"GoldLabel",
		"FloorLabel",
		"RoomLabel",
		"ObjectiveLabel",
		"ObjectiveNextActionLabel",
		"SkillLabel",
		"SecondarySkillLabel",
		"UltimateLabel",
		"BuildLabel",
		"RewardPathLabel",
		"RunDecisionLabel",
		"RunStatsLabel",
		"RunRouteLabel",
		"LootPityLabel",
		"RunSeedLabel",
		"RunModeLabel",
		"RunModifierLabel",
		"RunModifierGoalLabel",
		"ControlsHintLabel",
		"StatusEffectsLabel",
		"ElementComboCounterLabel",
	]:
		var label := hud.get_node_or_null(label_name) as Label
		if label != null and label.visible:
			failures.append("clean playtest HUD should hide %s" % label_name)
	for i in range(1, 5):
		var route_label := hud.get_node_or_null("RouteChoiceLabel%d" % i) as Label
		if route_label != null and route_label.visible:
			failures.append("clean playtest HUD should hide RouteChoiceLabel%d" % i)
	var minimap := hud.get_node_or_null("Minimap") as Minimap
	if minimap == null or not minimap.visible:
		failures.append("clean playtest HUD should keep minimap visible")
	if not bool(hud.get_meta("clean_playtest_mode", false)):
		failures.append("clean playtest HUD should store clean_playtest_mode metadata")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_playable_compact_layout(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var builder := GraphBuilder.new()
	ctrl.rooms = builder.build(8484556, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.ENTRANCE)
	ctrl.visited_rooms[ctrl.current_room.id] = true
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("tinkerer"), "fire", "scrap_pistol")
	player.gold = 10
	player.silver_keys = 1
	hud.bind(player, ctrl)
	await process_frame
	for name in [
		"BuildLabel",
		"RewardPathLabel",
		"RunDecisionLabel",
		"RunStatsLabel",
		"RunRouteLabel",
		"LootPityLabel",
		"RunSeedLabel",
		"RunModeLabel",
		"RunModifierLabel",
		"RunModifierGoalLabel",
		"ElementComboCounterLabel",
	]:
		var label := hud.get_node_or_null(name) as Label
		if label != null and label.visible:
			failures.append("playable HUD should keep verbose %s hidden by default" % name)
	for name in [
		"WeaponLabel",
		"GoldLabel",
		"FloorLabel",
		"RoomLabel",
		"ObjectiveLabel",
		"ObjectiveNextActionLabel",
		"SkillLabel",
		"SecondarySkillLabel",
		"UltimateLabel",
		"ControlsHintLabel",
	]:
		var label := hud.get_node_or_null(name) as Label
		if label == null:
			failures.append("playable HUD should expose %s" % name)
			continue
		if label.visible and label.get_global_rect().end.y > 360.0:
			failures.append("playable HUD %s should fit inside the 640x360 viewport" % name)
		if label.visible and label.text.length() > 64:
			failures.append("playable HUD %s should use compact visible text" % name)
	var minimap := hud.get_node_or_null("Minimap") as Minimap
	if minimap == null:
		failures.append("playable HUD should keep minimap")
	elif minimap.get_global_rect().end.x > 640.0 or minimap.get_global_rect().end.y > 120.0:
		failures.append("playable HUD minimap should stay compact in the top-right")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_element_combo_feedback(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var builder := GraphBuilder.new()
	ctrl.rooms = builder.build(2468, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.ENTRANCE)
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("arcanist"), "fire", "storm_scepter")
	hud.bind(player, ctrl)
	await process_frame
	if not player.has_signal("element_combo_recorded"):
		failures.append("Player should emit element_combo_recorded for live HUD feedback")
	var counter := hud.get_node_or_null("ElementComboCounterLabel") as Label
	if counter == null:
		failures.append("HUD should expose a live element combo counter label")
	var flash := hud.get_node_or_null("ElementComboFlashLabel") as Label
	if flash == null:
		failures.append("HUD should expose an element combo flash label")
	player.record_element_combo({"id": "thermal_shock", "name": "Thermal Shock"})
	await process_frame
	if counter == null or not counter.visible or not counter.text.contains("Combos: 1"):
		failures.append("HUD element combo counter should show the first live combo")
	if flash == null or not flash.visible or not flash.text.contains("Thermal Shock x1"):
		failures.append("HUD should flash the latest element combo")
	elif str(flash.get_meta("combo_id", "")) != "thermal_shock":
		failures.append("HUD element combo flash should store combo id metadata")
	player.record_element_combo({"id": "thermal_shock", "name": "Thermal Shock"})
	await process_frame
	if counter == null or not counter.text.contains("Combos: 2") \
			or not counter.text.contains("Thermal Shock x2"):
		failures.append("HUD element combo counter should update repeated combo count")
	if flash == null or not flash.text.contains("Thermal Shock x2") \
			or int(flash.get_meta("combo_total_count", 0)) != 2:
		failures.append("HUD element combo flash should update repeated combo metadata")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_player_status_feedback(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var builder := GraphBuilder.new()
	ctrl.rooms = builder.build(4321, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.ENTRANCE)
	var player := Player.new()
	player.silver_keys = 2
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("arcanist"), "fire", "storm_scepter")
	hud.bind(player, ctrl)
	player.add_status("cursed", 4.0)
	player.set_meta("iron_will_duration_seconds", 3.0)
	player.set_meta("temporary_armor", 2)
	player.set_meta("temporary_armor_duration_seconds", 3.0)
	player.set_meta("special_rounds_left", 6)
	player.set_meta("element_altar_boon_id", "element_damage")
	player.set_meta("element_altar_boon_element", "ice")
	player.set_meta("element_altar_damage_bonus", 0.10)
	player.set_meta("element_altar_boon_duration", "run")
	await process_frame
	if hud.get_node_or_null("StatusEffectsLabel") == null:
		failures.append("HUD should expose a status effects label")
	if hud.get_node_or_null("LowHpWarningLabel") == null:
		failures.append("HUD should expose a low HP warning label")
	var damage_flash := hud.get_node_or_null("DamageFlashLabel") as Label
	if damage_flash == null:
		failures.append("HUD should expose a damage flash label")
	var damage_vignette := hud.get_node_or_null("DamageVignetteOverlay") as ColorRect
	if damage_vignette == null:
		failures.append("HUD should expose a damage vignette overlay")
	var damage_icon := hud.get_node_or_null("DamageTypeIcon") as TextureRect
	if damage_icon == null:
		failures.append("HUD should expose a damage type icon")
	var hp_icon := hud.get_node_or_null("HpHeartIcon") as TextureRect
	if hp_icon == null:
		failures.append("HUD should expose a 0x72 HP heart icon")
	elif hp_icon.texture == null or str(hp_icon.get_meta("hp_icon_sprite", "")) != "ui_heart_full":
		failures.append("HUD HP heart icon should start full")
	var resource_icon := hud.get_node_or_null("ResourceIcon") as TextureRect
	if resource_icon == null:
		failures.append("HUD should expose a 0x72 resource icon")
	elif resource_icon.texture == null or str(resource_icon.get_meta("resource_icon_sprite", "")) != "flask_big_blue":
		failures.append("HUD resource icon should use the blue flask sprite")
	var gold_icon := hud.get_node_or_null("GoldIcon") as TextureRect
	if gold_icon == null:
		failures.append("HUD should expose a 0x72 gold icon")
	elif gold_icon.texture == null or str(gold_icon.get_meta("gold_icon_sprite", "")) != "coin_anim":
		failures.append("HUD gold icon should use the coin sprite")
	var revive_flash := hud.get_node_or_null("ReviveFlashLabel") as Label
	if revive_flash == null:
		failures.append("HUD should expose a revive flash label")
	if not _has_label_containing(hud, "Cursed"):
		failures.append("HUD should show active cursed status")
	if not _has_label_containing(hud, "Buffs:"):
		failures.append("HUD should expose active skill buffs")
	if not _has_label_containing(hud, "Iron Will 3.0s"):
		failures.append("HUD should show iron_will buff duration")
	if not _has_label_containing(hud, "Armor +2 3.0s"):
		failures.append("HUD should show temporary armor buff duration")
	if not _has_label_containing(hud, "Rounds 6"):
		failures.append("HUD should show special rounds charges")
	if not _has_label_containing(hud, "Ice +10% dmg"):
		failures.append("HUD should show elemental altar damage boon")
	var status_label := hud.get_node_or_null("StatusEffectsLabel") as Label
	if status_label != null:
		if str(status_label.get_meta("element_altar_boon_element", "")) != "ice":
			failures.append("HUD status label should store elemental altar boon element")
		if not is_equal_approx(float(status_label.get_meta("element_altar_damage_bonus", 0.0)), 0.10):
			failures.append("HUD status label should store elemental altar boon damage bonus")
	if not _has_label_containing(hud, "Keys: 2"):
		failures.append("HUD should show current silver key count")
	var gold_flash := hud.get_node_or_null("GoldFlashLabel") as Label
	if gold_flash == null:
		failures.append("HUD should expose a gold gain flash label")
	player.add_gold(12)
	await process_frame
	if not _has_label_containing(hud, "Gold: 12"):
		failures.append("HUD should update when gold is gained")
	if gold_flash == null or not gold_flash.visible or not gold_flash.text.contains("Gold +12"):
		failures.append("HUD should flash gained gold")
	var key_flash := hud.get_node_or_null("KeyFlashLabel") as Label
	if key_flash == null:
		failures.append("HUD should expose a silver key flash label")
	player.add_key(1)
	await process_frame
	if not _has_label_containing(hud, "Keys: 3"):
		failures.append("HUD should update when silver keys are gained")
	if key_flash == null or not key_flash.visible or not key_flash.text.contains("Key +1"):
		failures.append("HUD should flash gained silver keys")
	player.spend_key()
	await process_frame
	if not _has_label_containing(hud, "Keys: 2"):
		failures.append("HUD should update when silver keys are spent")
	UpgradeDBScript.apply_upgrade(player, "split_socket")
	UpgradeDBScript.apply_upgrade(player, "ember_rune")
	hud.call("_on_weapon_changed", player.current_weapon().display_name())
	await process_frame
	if not _has_label_containing(hud, "Sockets: 1/3"):
		failures.append("HUD weapon label should show socket usage")
	if not _has_label_containing(hud, "Sockets 1/3"):
		failures.append("HUD build label should show rune/socket socket usage")
	if not _has_label_containing(hud, "Fire x1"):
		failures.append("HUD build label should show elemental rune stacks")
	if not _has_label_containing(hud, "Archetype: Fire Damage"):
		failures.append("HUD build label should show readable live build archetype")
	if not _has_label_containing(hud, "Power Arc: 2 picks | Tier I | Fire Damage"):
		failures.append("HUD build label should show live run power arc")
	player.pet_damage_mult = 1.4
	player.shield_duration_mult = 1.5
	player.dash_cooldown = 0.9
	hud.call("_on_upgrades_changed", player.upgrade_summary())
	await process_frame
	if not _has_label_containing(hud, "Power Stats:"):
		failures.append("HUD build label should show live run stat multipliers")
	for token in ["Pet x1.4", "Shield x1.5", "Dash 0.9s"]:
		if not _has_label_containing(hud, token):
			failures.append("HUD build label missing run stat token: %s" % token)
	var build_label := hud.get_node_or_null("BuildLabel") as Label
	if build_label == null:
		failures.append("HUD should expose a named build label")
	elif str(build_label.get_meta("build_archetype", "")) != "Fire Damage":
		failures.append("HUD build label should store build archetype metadata")
	elif not str(build_label.get_meta("run_power_arc", "")).contains("2 picks"):
		failures.append("HUD build label should store run power arc metadata")
	elif not str(build_label.get_meta("run_stat_summary", "")).contains("Pet x1.4"):
		failures.append("HUD build label should store run stat summary metadata")
	var weapon_flash := hud.get_node_or_null("WeaponSwapFlashLabel") as Label
	if weapon_flash == null:
		failures.append("HUD should expose a weapon swap flash label")
	else:
		hud.call("_on_weapon_changed", "Training Sword")
		await process_frame
		if not weapon_flash.visible or not weapon_flash.text.contains("Equipped: Training Sword"):
			failures.append("HUD should flash the equipped weapon name")
		hud.call("_on_element_changed", "ice")
		await process_frame
		if not weapon_flash.visible or not weapon_flash.text.contains("Element: ice"):
			failures.append("HUD should flash the selected element")
	player._tick_statuses(4.1)
	await process_frame
	if _has_label_containing(hud, "Cursed"):
		failures.append("HUD should clear expired player statuses")
	hud.call("_on_hp_changed", 100, 100)
	await process_frame
	hud.call("_on_hp_changed", 82, 100)
	await process_frame
	if damage_flash == null or not damage_flash.visible:
		failures.append("HUD should flash when player HP drops")
	elif not damage_flash.text.contains("Damage -18") or not damage_flash.text.contains("82/100"):
		failures.append("HUD damage flash should show damage amount and remaining HP")
	else:
		if int(damage_flash.get_meta("damage_amount", 0)) != 18:
			failures.append("HUD damage flash should store damage amount metadata")
		if not is_equal_approx(float(damage_flash.get_meta("hp_ratio", -1.0)), 0.82):
			failures.append("HUD damage flash should store remaining HP ratio")
	if damage_vignette == null or not damage_vignette.visible:
		failures.append("HUD should pulse a damage vignette when player HP drops")
	else:
		if damage_vignette.color.a <= 0.0:
			failures.append("HUD damage vignette should use visible alpha")
		if str(damage_vignette.get_meta("hud_flash_kind", "")) != "damage_vignette":
			failures.append("HUD damage vignette should tag flash kind metadata")
		if int(damage_vignette.get_meta("damage_amount", 0)) != 18:
			failures.append("HUD damage vignette should store damage amount metadata")
		if not is_equal_approx(float(damage_vignette.get_meta("hp_ratio", -1.0)), 0.82):
			failures.append("HUD damage vignette should store remaining HP ratio")
	player.hp = 100
	hud.call("_on_hp_changed", 100, 100)
	await process_frame
	player.take_damage(11, Vector2(80, 0), "Trap: Spike")
	await process_frame
	if damage_flash != null:
		if str(damage_flash.get_meta("damage_source", "")) != "Trap: Spike":
			failures.append("HUD damage flash should preserve player damage source label")
		if str(damage_flash.get_meta("damage_kind", "")) != "trap":
			failures.append("HUD damage flash should classify trap damage source")
		if str(damage_flash.get_meta("damage_color_role", "")) != "trap":
			failures.append("HUD damage flash should expose trap damage color role")
	if damage_icon != null:
		if not damage_icon.visible or damage_icon.texture == null:
			failures.append("HUD trap damage should show a type icon")
		if str(damage_icon.get_meta("damage_icon_sprite", "")) != "floor_spikes_anim":
			failures.append("HUD trap damage icon should use the spike sprite")
		if str(damage_icon.get_meta("damage_kind", "")) != "trap":
			failures.append("HUD trap damage icon should store damage kind metadata")
	var damage_sfx := hud.get_node_or_null("DamageFeedbackSfx") as AudioStreamPlayer
	if damage_sfx == null:
		failures.append("HUD trap damage should create a damage feedback sound")
	else:
		if str(damage_sfx.get_meta("damage_sound_id", "")) != "player_damage_trap":
			failures.append("HUD trap damage sound should use the trap damage cue")
		if str(damage_sfx.get_meta("damage_kind", "")) != "trap":
			failures.append("HUD trap damage sound should store damage kind")
		if str(damage_sfx.get_meta("damage_source", "")) != "Trap: Spike":
			failures.append("HUD trap damage sound should store damage source")
		if str(damage_sfx.get_meta("audio_cue_kind", "")) != "player_damage":
			failures.append("HUD damage sound should expose player_damage cue kind")
		if damage_sfx.stream == null:
			failures.append("HUD damage sound should assign a procedural stream")
		if not bool(damage_sfx.get_meta("placeholder_audio_stream", false)):
			failures.append("HUD damage sound should mark placeholder audio metadata")
		if DisplayServer.get_name() == "headless" \
				and not bool(damage_sfx.get_meta("headless_playback_skipped", false)):
			failures.append("HUD damage sound should skip playback in headless smoke")
	if damage_vignette != null:
		if str(damage_vignette.get_meta("damage_source", "")) != "Trap: Spike":
			failures.append("HUD damage vignette should preserve player damage source label")
		if str(damage_vignette.get_meta("damage_kind", "")) != "trap":
			failures.append("HUD damage vignette should classify trap damage source")
		if str(damage_vignette.get_meta("vignette_color_role", "")) != "trap":
			failures.append("HUD damage vignette should expose trap color role")
		if damage_vignette.color.g <= damage_vignette.color.b:
			failures.append("HUD trap damage vignette should read as warm hazard feedback")
	hud.call("_show_damage_flash", 8, 74, 100, {"source": "Burning", "kind": "status"})
	await process_frame
	if damage_flash != null and str(damage_flash.get_meta("damage_color_role", "")) != "status":
		failures.append("HUD status damage flash should expose status color role")
	if damage_icon != null and str(damage_icon.get_meta("damage_icon_sprite", "")) != "flask_big_green":
		failures.append("HUD status damage icon should use the green flask sprite")
	damage_sfx = hud.get_node_or_null("DamageFeedbackSfx") as AudioStreamPlayer
	if damage_sfx == null or str(damage_sfx.get_meta("damage_sound_id", "")) != "player_damage_status":
		failures.append("HUD status damage sound should use the status damage cue")
	if damage_vignette != null:
		if str(damage_vignette.get_meta("vignette_color_role", "")) != "status":
			failures.append("HUD status damage vignette should expose status color role")
		if damage_vignette.color.g <= damage_vignette.color.r:
			failures.append("HUD status damage vignette should read as toxic/status feedback")
	hud.call("_show_damage_flash", 22, 52, 100, {"source": "Boss: Smash", "kind": "boss"})
	await process_frame
	if damage_flash != null and str(damage_flash.get_meta("damage_color_role", "")) != "boss":
		failures.append("HUD boss damage flash should expose boss color role")
	if damage_icon != null and str(damage_icon.get_meta("damage_icon_sprite", "")) != "skull":
		failures.append("HUD boss damage icon should use the skull sprite")
	damage_sfx = hud.get_node_or_null("DamageFeedbackSfx") as AudioStreamPlayer
	if damage_sfx == null or str(damage_sfx.get_meta("damage_sound_id", "")) != "player_damage_boss":
		failures.append("HUD boss damage sound should use the boss damage cue")
	if damage_vignette != null:
		if str(damage_vignette.get_meta("vignette_color_role", "")) != "boss":
			failures.append("HUD boss damage vignette should expose boss color role")
		if damage_vignette.color.b <= damage_vignette.color.g:
			failures.append("HUD boss damage vignette should read as heavy boss feedback")
	hud.call("_on_hp_changed", 20, 100)
	await process_frame
	var low_hp := hud.get_node_or_null("LowHpWarningLabel") as Label
	if low_hp == null or not low_hp.visible or not low_hp.text.contains("LOW HP"):
		failures.append("HUD should show LOW HP warning below 30 percent health")
	if hp_icon != null and str(hp_icon.get_meta("hp_icon_sprite", "")) != "ui_heart_half":
		failures.append("HUD HP heart should switch to half icon at low HP")
	hud.call("_on_hp_changed", 0, 100)
	await process_frame
	if hp_icon != null and str(hp_icon.get_meta("hp_icon_sprite", "")) != "ui_heart_empty":
		failures.append("HUD HP heart should switch to empty icon at 0 HP")
	hud.call("_on_hp_changed", 70, 100)
	await process_frame
	if low_hp != null and low_hp.visible:
		failures.append("HUD should hide LOW HP warning after health recovers")
	if hp_icon != null and str(hp_icon.get_meta("hp_icon_sprite", "")) != "ui_heart_full":
		failures.append("HUD HP heart should restore full icon after health recovers")
	player.max_hp = 100
	player.hp = 10
	player.apply_meta_bonuses({"upgrades": {"revive_charm": 1}})
	player.take_damage(99, Vector2.ZERO, "Boss: Smash")
	await process_frame
	if revive_flash == null or not revive_flash.visible:
		failures.append("HUD should flash when revive_charm saves the player")
	elif not revive_flash.text.contains("Revived") or not revive_flash.text.contains("HP"):
		failures.append("HUD revive flash should show revive and restored HP")
	else:
		if int(revive_flash.get_meta("revives_used", 0)) != 1:
			failures.append("HUD revive flash should store revives_used metadata")
		if int(revive_flash.get_meta("charges_left", -1)) != 0:
			failures.append("HUD revive flash should store charges_left metadata")
	var revive_sfx := hud.get_node_or_null("ReviveSfx") as AudioStreamPlayer
	if revive_sfx == null:
		failures.append("HUD revive should create sound placeholder")
	else:
		if str(revive_sfx.get_meta("revive_sound_id", "")) != "player_revive":
			failures.append("HUD revive sound should expose player_revive cue id")
		if str(revive_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("HUD revive sound should come from AudioCueDB")
		if str(revive_sfx.get_meta("revive_source", "")) != "Boss: Smash":
			failures.append("HUD revive sound should preserve lethal source metadata")
		if int(revive_sfx.get_meta("charges_left", -1)) != 0:
			failures.append("HUD revive sound should store remaining charges")
		if revive_sfx.stream == null:
			failures.append("HUD revive sound should assign an audio stream")
		if not bool(revive_sfx.get_meta("placeholder_audio_stream", false)):
			failures.append("HUD revive sound should mark placeholder stream metadata")
		if DisplayServer.get_name() == "headless" \
				and not bool(revive_sfx.get_meta("headless_playback_skipped", false)):
			failures.append("HUD revive sound should skip playback in headless smoke")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_meta_bonus_feedback(failures: Array[String]) -> void:
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	if hud.get_node_or_null("MetaBonusFlashLabel") == null:
		failures.append("HUD should expose a run-start meta bonus flash label")
	if not hud.has_method("show_meta_bonus_summary"):
		failures.append("HUD should expose show_meta_bonus_summary for run-start meta feedback")
	else:
		hud.call("show_meta_bonus_summary", "+20 HP / +4% damage / Revive x1", {
			"upgrades": {
				"training_hp": 2,
				"training_damage": 1,
				"revive_charm": 1,
			},
		})
		await process_frame
		var flash := hud.get_node_or_null("MetaBonusFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("HUD should flash active meta bonuses at run start")
		elif not flash.text.contains("Meta Bonus") or not flash.text.contains("+20 HP") \
				or not flash.text.contains("Revive x1"):
			failures.append("meta bonus flash should show readable active bonuses")
		else:
			if str(flash.get_meta("meta_bonus_summary", "")) != "+20 HP / +4% damage / Revive x1":
				failures.append("meta bonus flash should store summary metadata")
			if int(flash.get_meta("meta_bonus_upgrade_count", 0)) != 3:
				failures.append("meta bonus flash should store active upgrade count")
		var sfx := hud.get_node_or_null("MetaBonusSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("HUD meta bonus feedback should create sound placeholder")
		else:
			if str(sfx.get_meta("meta_bonus_sound_id", "")) != "meta_bonus_active":
				failures.append("meta bonus sound should expose cue id")
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("meta bonus sound should come from AudioCueDB")
			if int(sfx.get_meta("meta_bonus_upgrade_count", 0)) != 3:
				failures.append("meta bonus sound should store active upgrade count")
			if sfx.stream == null:
				failures.append("meta bonus sound should assign an audio stream")
			if DisplayServer.get_name() == "headless" \
					and not bool(sfx.get_meta("headless_playback_skipped", false)):
				failures.append("meta bonus sound should skip playback in headless smoke")
	hud.queue_free()
	await process_frame

func _check_hud_biome_mastery_feedback(failures: Array[String]) -> void:
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	if hud.get_node_or_null("BiomeMasteryFlashLabel") == null:
		failures.append("HUD should expose a biome mastery flash label")
	if not hud.has_method("show_biome_mastery_feedback"):
		failures.append("HUD should expose show_biome_mastery_feedback for mastered biome feedback")
	else:
		hud.call("show_biome_mastery_feedback", "Ember Forge", 0.03)
		await process_frame
		var flash := hud.get_node_or_null("BiomeMasteryFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("HUD should flash when biome mastery activates")
		elif not flash.text.contains("Biome Mastery") or not flash.text.contains("Ember Forge") \
				or not flash.text.contains("+3%"):
			failures.append("biome mastery flash should show biome label and bonus percent")
		else:
			if str(flash.get_meta("hud_flash_kind", "")) != "biome_mastery":
				failures.append("biome mastery flash should store flash kind metadata")
			if str(flash.get_meta("biome_mastery_label", "")) != "Ember Forge":
				failures.append("biome mastery flash should store biome label metadata")
			if not is_equal_approx(float(flash.get_meta("biome_mastery_bonus", 0.0)), 0.03):
				failures.append("biome mastery flash should store bonus metadata")
	hud.queue_free()
	await process_frame

func _check_hud_skill_cast_feedback(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var builder := GraphBuilder.new()
	ctrl.rooms = builder.build(2468, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.ENTRANCE)
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	hud.bind(player, ctrl)
	await process_frame
	if not _has_label_containing(hud, "Wind Edge"):
		failures.append("HUD should show a readable primary skill name")
	var skill_label := hud.get_node_or_null("SkillLabel") as Label
	if skill_label == null or int(skill_label.get_meta("skill_cost", 0)) != 20:
		failures.append("HUD should store primary skill cost metadata")
	if skill_label == null or not is_equal_approx(float(skill_label.get_meta("skill_cooldown_total", 0.0)), 6.0):
		failures.append("HUD should store primary skill cooldown metadata")
	if not _has_label_containing(hud, "Lunge"):
		failures.append("HUD should show a readable secondary skill name")
	if not _has_label_containing(hud, "Phantom Slash"):
		failures.append("HUD should show a readable ultimate name")
	var primary_fill := hud.get_node_or_null("SkillCooldownFill") as ColorRect
	var secondary_fill := hud.get_node_or_null("SecondarySkillCooldownFill") as ColorRect
	var primary_icon := hud.get_node_or_null("SkillCooldownIcon") as ColorRect
	var secondary_icon := hud.get_node_or_null("SecondarySkillCooldownIcon") as ColorRect
	var primary_badge := hud.get_node_or_null("SkillCooldownBadge") as Label
	var secondary_badge := hud.get_node_or_null("SecondarySkillCooldownBadge") as Label
	if primary_fill == null or primary_icon == null or primary_badge == null:
		failures.append("HUD should expose primary skill cooldown slot pieces")
	else:
		if str(primary_fill.get_meta("skill_slot", "")) != "primary":
			failures.append("primary cooldown fill should store skill_slot metadata")
		if str(primary_fill.get_meta("skill_input_action", "")) != "skill":
			failures.append("primary cooldown fill should store input action metadata")
		if str(primary_fill.get_meta("skill_key_label", "")) != "E":
			failures.append("primary cooldown fill should store key label metadata")
		if not is_equal_approx(float(primary_fill.get_meta("skill_cooldown_fraction", -1.0)), 0.0):
			failures.append("primary cooldown fill should expose ready cooldown fraction")
		if not bool(primary_fill.get_meta("skill_ready", false)):
			failures.append("primary cooldown fill should expose ready state")
		if not primary_icon.tooltip_text.contains("E") or not primary_icon.tooltip_text.contains("READY"):
			failures.append("primary skill icon tooltip should show key and ready state")
		if str(primary_badge.get_meta("skill_key_label", "")) != "E":
			failures.append("primary badge should expose key label metadata")
	if secondary_fill == null or secondary_icon == null or secondary_badge == null:
		failures.append("HUD should expose secondary skill cooldown slot pieces")
	else:
		if str(secondary_fill.get_meta("skill_slot", "")) != "secondary":
			failures.append("secondary cooldown fill should store skill_slot metadata")
		if str(secondary_fill.get_meta("skill_input_action", "")) != "skill_alt":
			failures.append("secondary cooldown fill should store input action metadata")
		if str(secondary_fill.get_meta("skill_key_label", "")) != "C":
			failures.append("secondary cooldown fill should store key label metadata")
		if not is_equal_approx(float(secondary_fill.get_meta("skill_cooldown_fraction", -1.0)), 0.0):
			failures.append("secondary cooldown fill should expose ready cooldown fraction")
		if not bool(secondary_fill.get_meta("skill_ready", false)):
			failures.append("secondary cooldown fill should expose ready state")
		if not secondary_icon.tooltip_text.contains("C") or not secondary_icon.tooltip_text.contains("READY"):
			failures.append("secondary skill icon tooltip should show key and ready state")
		if str(secondary_badge.get_meta("skill_key_label", "")) != "C":
			failures.append("secondary badge should expose key label metadata")
	var flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
	if flash == null:
		failures.append("HUD should expose a skill cast flash label")
	if not hud.has_method("_on_skill_cast"):
		failures.append("HUD should handle skill cast feedback")
	else:
		hud.call("_on_skill_cast", "wind_edge", 1.2)
		await process_frame
		flash = hud.get_node_or_null("SkillCastFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("skill cast flash should become visible on cast")
		elif not flash.text.contains("Wind Edge"):
			failures.append("skill cast flash should show the readable cast skill name")
		elif not flash.text.contains("SFX") or not flash.text.contains("blade_cast"):
			failures.append("skill cast flash should show sound placeholder cue")
		var pulse := hud.get_node_or_null("SkillCastPulse") as ColorRect
		var profile: Dictionary = CombatFxScript.skill_feedback_profile("wind_edge")
		if pulse == null:
			failures.append("skill cast should create a HUD cast pulse")
		else:
			if not pulse.visible:
				failures.append("skill cast pulse should become visible on cast")
			if str(pulse.get_meta("skill_id", "")) != "wind_edge":
				failures.append("skill cast pulse should tag skill id")
			if str(pulse.get_meta("skill_slot", "")) != "primary":
				failures.append("skill cast pulse should tag primary slot")
			if str(pulse.get_meta("skill_sound_id", "")) != "blade_cast":
				failures.append("skill cast pulse should tag sound cue id")
			if str(pulse.get_meta("skill_family", "")) != str(profile.get("family", "")):
				failures.append("skill cast pulse should tag skill family")
			if str(pulse.get_meta("skill_style", "")) != str(profile.get("style", "")):
				failures.append("skill cast pulse should tag skill style")
			if str(pulse.get_meta("skill_feel_tier", "")) != str(profile.get("feel_tier", "")):
				failures.append("skill cast pulse should tag skill feel tier")
			if str(pulse.get_meta("skill_cooldown_hint", "")) != str(profile.get("cooldown_hint", "")):
				failures.append("skill cast pulse should tag skill cooldown hint")
			if str(pulse.get_meta("skill_input_role", "")) != "primary":
				failures.append("skill cast pulse should tag skill input role")
			if not _colors_close(pulse.color, profile.get("color", Color.WHITE)):
				failures.append("skill cast pulse should use skill profile color")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_skill_ready_feedback(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var builder := GraphBuilder.new()
	ctrl.rooms = builder.build(1357, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.ENTRANCE)
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	hud.bind(player, ctrl)
	await process_frame
	hud.call("_on_skill_cooldown_changed", "wind_edge", 1.0, 2.0)
	await process_frame
	hud.call("_on_skill_cooldown_changed", "wind_edge", 0.0, 2.0)
	await process_frame
	var flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
	if flash == null or not flash.visible:
		failures.append("skill ready flash should become visible when cooldown reaches zero")
	elif not flash.text.contains("Ready: Wind Edge"):
		failures.append("skill ready flash should name the readable ready skill")
	var sfx := hud.get_node_or_null("SkillReadySfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("skill ready should create sound placeholder")
	else:
		if str(sfx.get_meta("skill_ready_id", "")) != "wind_edge":
			failures.append("skill ready sound should store skill id metadata")
		if str(sfx.get_meta("skill_ready_sound_id", "")) != "skill_ready":
			failures.append("skill ready sound should expose ready cue id")
		if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("skill ready sound should come from AudioCueDB")
		if sfx.stream == null:
			failures.append("skill ready sound should assign an audio stream")
		if DisplayServer.get_name() == "headless" \
				and not bool(sfx.get_meta("headless_playback_skipped", false)):
			failures.append("skill ready sound should skip playback in headless smoke")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_dash_cooldown_feedback(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var builder := GraphBuilder.new()
	ctrl.rooms = builder.build(8642, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.ENTRANCE)
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	if not player.has_signal("dash_cooldown_changed"):
		failures.append("Player should expose dash_cooldown_changed for HUD feedback")
	hud.bind(player, ctrl)
	await process_frame
	if hud.get_node_or_null("DashCooldownIcon") == null:
		failures.append("HUD should expose dash cooldown icon")
	if hud.get_node_or_null("DashCooldownFill") == null:
		failures.append("HUD should expose dash cooldown fill")
	if not hud.has_method("_on_dash_cooldown_changed"):
		failures.append("HUD should handle dash cooldown changes")
	else:
		hud.call("_on_dash_cooldown_changed", 0.6, 1.2)
		await process_frame
		if not _has_label_containing(hud, "Dash: 0.6s"):
			failures.append("HUD should show active dash cooldown text")
		hud.call("_on_dash_cooldown_changed", 0.0, 1.2)
		await process_frame
		var flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("dash ready should reuse combat flash feedback")
		elif not flash.text.contains("Dash ready"):
			failures.append("dash ready flash should name dash readiness")
		var sfx := hud.get_node_or_null("DashReadySfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("dash ready should create sound placeholder")
		else:
			if str(sfx.get_meta("dash_ready_sound_id", "")) != "dash_ready":
				failures.append("dash ready sound should expose ready cue id")
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("dash ready sound should come from AudioCueDB")
			if sfx.stream == null:
				failures.append("dash ready sound should assign an audio stream")
			if DisplayServer.get_name() == "headless" \
					and not bool(sfx.get_meta("headless_playback_skipped", false)):
				failures.append("dash ready sound should skip playback in headless smoke")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_run_stats_feedback(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var entrance := RoomNode.new()
	entrance.id = 0
	entrance.type = RoomNode.RoomType.ENTRANCE
	entrance.depth = 0
	entrance.on_critical_path = true
	entrance.neighbors = [1, 2]
	entrance.door_map = {0: 1, 1: 2}
	var shop := RoomNode.new()
	shop.id = 1
	shop.type = RoomNode.RoomType.SHOP
	shop.depth = 1
	shop.on_critical_path = false
	shop.neighbors = [0]
	var boss := RoomNode.new()
	boss.id = 2
	boss.type = RoomNode.RoomType.BOSS
	boss.depth = 1
	boss.on_critical_path = true
	boss.neighbors = [0]
	var rooms: Array[RoomNode] = [entrance, shop, boss]
	ctrl.rooms = rooms
	ctrl.current_room = entrance
	ctrl.cleared_rooms[ctrl.current_room.id] = true
	ctrl.call("_record_room_visit", ctrl.current_room)
	ctrl.call("_record_room_visit", shop)
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	hud.bind(player, ctrl)
	await process_frame
	var stats := hud.get_node_or_null("RunStatsLabel") as Label
	if stats == null:
		failures.append("HUD should expose a live run stats label")
	elif not stats.text.contains("Rooms 1/") or not stats.text.contains("Kills 0") \
			or not stats.text.contains("Upgrades 0"):
		failures.append("HUD run stats should show rooms, kills, and upgrades")
	var route := hud.get_node_or_null("RunRouteLabel") as Label
	if route == null:
		failures.append("HUD should expose a live route label")
	else:
		if not route.text.contains("Route:") or not route.text.contains("Visited 2/") \
				or not route.text.contains("Path:"):
			failures.append("HUD route label should show visited count and path summary")
		if int(route.get_meta("visited_room_count", 0)) != 2:
			failures.append("HUD route label should store visited room count metadata")
		if str(route.get_meta("path_summary", "")).find("Path:") != 0:
			failures.append("HUD route label should store path summary metadata")
		if not ctrl.has_method("current_room_route_options_summary"):
			failures.append("FloorController should expose current_room_route_options_summary for HUD")
		else:
			var choices := str(ctrl.call("current_room_route_options_summary"))
			if not choices.contains("Choices:") or not choices.contains("SIDE SHOP 3 BUY") \
					or not choices.contains("MAIN BOSS R+"):
				failures.append("route option summary should preview side shop and main boss rewards")
			if not route.text.contains("Choices:") or not route.text.contains("SHOP 3 BUY") \
					or not route.text.contains("BOSS R+"):
				failures.append("HUD route label should preview current room route choices")
			if str(route.get_meta("route_options_summary", "")) != choices:
				failures.append("HUD route label should store route option summary metadata")
			if int(route.get_meta("route_options_count", 0)) != 2:
				failures.append("HUD route label should store structured route option count")
			if int(route.get_meta("route_main_count", 0)) != 1 \
					or int(route.get_meta("route_side_count", 0)) != 1:
				failures.append("HUD route label should store main/side route counts")
			if str(route.get_meta("route_first_option_summary", "")) != "SIDE SHOP 3 BUY":
				failures.append("HUD route label should store first route option summary")
			var hud_options_meta: Array = route.get_meta("route_options", [])
			if hud_options_meta.size() != 2:
				failures.append("HUD route label should mirror structured route options metadata")
			var route_choice_1 := hud.get_node_or_null("RouteChoiceLabel1") as Label
			var route_choice_2 := hud.get_node_or_null("RouteChoiceLabel2") as Label
			if route_choice_1 == null or route_choice_2 == null:
				failures.append("HUD should expose compact route choice labels for each visible door option")
			else:
				if not route_choice_1.visible or not route_choice_1.text.contains("SIDE SHOP 3 BUY"):
					failures.append("first route choice label should show side shop reward preview")
				if not route_choice_2.visible or not route_choice_2.text.contains("MAIN BOSS R+"):
					failures.append("second route choice label should show main boss reward preview")
				if int(route_choice_1.get_meta("door_dir", -1)) != 0 \
						or str(route_choice_1.get_meta("route_role", "")) != "side" \
						or str(route_choice_1.get_meta("reward_preview", "")) != "3 BUY":
					failures.append("route choice labels should preserve door, role, and reward metadata")
				if str(route_choice_2.get_meta("route_role", "")) != "main" \
						or int(route_choice_2.get_meta("room_id", -1)) != boss.id:
					failures.append("route choice labels should preserve main route target metadata")
				var player_center_safe_zone := Rect2(Vector2(240, 130), Vector2(160, 120))
				for route_choice in [route_choice_1, route_choice_2]:
					var rect: Rect2 = route_choice.get_global_rect()
					if rect.position.y < 292.0 or rect.end.y > 318.0:
						failures.append("route choice labels should sit in the bottom HUD band")
					if rect.intersects(player_center_safe_zone):
						failures.append("route choice labels should not overlap the player action zone")
			var route_icon_1 := hud.get_node_or_null("RouteChoiceIcon1") as TextureRect
			var route_icon_2 := hud.get_node_or_null("RouteChoiceIcon2") as TextureRect
			if route_icon_1 == null or route_icon_2 == null:
				failures.append("HUD should expose route choice sprite icons beside compact route labels")
			else:
				if not route_icon_1.visible or route_icon_1.texture == null \
						or str(route_icon_1.get_meta("route_choice_icon_sprite", "")) != "coin_anim":
					failures.append("first route choice icon should use the shop coin sprite")
				if int(route_icon_1.get_meta("room_id", -1)) != shop.id \
						or str(route_icon_1.get_meta("route_role", "")) != "side":
					failures.append("route choice icons should preserve side route metadata")
				if not route_icon_2.visible or route_icon_2.texture == null \
						or str(route_icon_2.get_meta("route_choice_icon_sprite", "")) != "skull":
					failures.append("second route choice icon should use the boss skull sprite")
				if int(route_icon_2.get_meta("room_id", -1)) != boss.id \
						or str(route_icon_2.get_meta("route_role", "")) != "main":
					failures.append("route choice icons should preserve main route metadata")
				for route_icon in [route_icon_1, route_icon_2]:
					var rect: Rect2 = route_icon.get_global_rect()
					if rect.position.y < 292.0 or rect.end.y > 318.0:
						failures.append("route choice icons should sit in the bottom HUD band")
					if rect.intersects(Rect2(Vector2(240, 130), Vector2(160, 120))):
						failures.append("route choice icons should not overlap the player action zone")
			var route_choice_3 := hud.get_node_or_null("RouteChoiceLabel3") as Label
			if route_choice_3 != null and route_choice_3.visible:
				failures.append("unused route choice labels should stay hidden")
			var route_icon_3 := hud.get_node_or_null("RouteChoiceIcon3") as TextureRect
			if route_icon_3 != null and route_icon_3.visible:
				failures.append("unused route choice icons should stay hidden")
		if not ctrl.has_method("current_room_route_options"):
			failures.append("FloorController should expose structured route options for HUD/minimap")
		else:
			var options: Array = ctrl.call("current_room_route_options")
			if options.size() != 2:
				failures.append("structured route options should include both open doors")
			else:
				var side: Dictionary = options[0]
				var main: Dictionary = options[1]
				if str(side.get("route_role", "")) != "side" \
						or str(side.get("room_type_name", "")) != "SHOP" \
						or str(side.get("reward_preview", "")) != "3 BUY":
					failures.append("structured route option should preserve side shop reward preview")
				if str(main.get("route_role", "")) != "main" \
						or str(main.get("room_type_name", "")) != "BOSS" \
						or str(main.get("reward_preview", "")) != "R+":
					failures.append("structured route option should preserve main boss reward preview")
				if int(main.get("room_depth", -1)) != 1 or int(side.get("door_dir", -1)) != 0:
					failures.append("structured route options should preserve room depth and door direction")
				if not str(side.get("summary", "")).contains("SIDE SHOP 3 BUY"):
					failures.append("structured route option should expose the same compact summary token")
	var seed_label := hud.get_node_or_null("RunSeedLabel") as Label
	if seed_label == null:
		failures.append("HUD should expose a run seed label")
	var mode_label := hud.get_node_or_null("RunModeLabel") as Label
	if mode_label == null:
		failures.append("HUD should expose a run mode label")
	if not hud.has_method("set_run_seed"):
		failures.append("HUD should expose set_run_seed")
	else:
		hud.call("set_run_seed", 777123)
		await process_frame
		if seed_label == null or not seed_label.text.contains("Seed: 777123"):
			failures.append("HUD should show active run seed")
	if not hud.has_method("set_run_mode"):
		failures.append("HUD should expose set_run_mode")
	else:
		hud.call("set_run_mode", "Boss Rush")
		await process_frame
		if mode_label == null or not mode_label.text.contains("Mode: Boss Rush"):
			failures.append("HUD should show active run mode")
	player.on_enemy_killed()
	UpgradeDBScript.apply_upgrade(player, "power_rune")
	await process_frame
	if stats != null and (not stats.text.contains("Kills 1") or not stats.text.contains("Upgrades 1")):
		failures.append("HUD run stats should update kills and upgrades live")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_floor_difficulty_feedback(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	ctrl.rooms = [RoomNode.new()]
	ctrl.current_room = ctrl.rooms[0]
	ctrl.floor_index = 2
	ctrl.current_biome = {"name": "Test Biome", "difficulty_mult": 1.2}
	ctrl.difficulty_mult = 1.3
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	if not ctrl.has_method("current_difficulty_label"):
		failures.append("FloorController should expose current_difficulty_label")
	else:
		var label := str(ctrl.call("current_difficulty_label"))
		if not label.contains("x1.56"):
			failures.append("FloorController difficulty label should combine mode and biome multipliers")
	if not ctrl.has_method("current_threat_label"):
		failures.append("FloorController should expose current_threat_label for floor spawn-budget pressure")
	else:
		var threat := str(ctrl.call("current_threat_label"))
		if not threat.contains("Threat x2.34"):
			failures.append("FloorController threat label should include floor spawn-budget scaling")
	hud.bind(player, ctrl)
	await process_frame
	if not _has_label_containing(hud, "x1.56"):
		failures.append("HUD floor label should show effective difficulty multiplier")
	if not _has_label_containing(hud, "Threat x2.34"):
		failures.append("HUD floor label should show floor threat multiplier")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_boss_status_feedback(failures: Array[String]) -> void:
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	if hud.get_node_or_null("BossHealthLabel") == null:
		failures.append("HUD should expose a boss health label")
	if hud.get_node_or_null("BossHealthFill") == null:
		failures.append("HUD should expose a boss health fill")
	if hud.get_node_or_null("BossPhaseFlashLabel") == null:
		failures.append("HUD should expose a boss phase flash label")
	if hud.get_node_or_null("BossEnrageWarningLabel") == null:
		failures.append("HUD should expose a persistent boss enrage warning label")
	if hud.get_node_or_null("BossPatternCueLabel") == null:
		failures.append("HUD should expose a boss pattern cue label")
	if hud.get_node_or_null("BossAttackCueFlashLabel") == null:
		failures.append("HUD should expose a boss attack cue flash label")
	if hud.get_node_or_null("BossLastAttackLabel") == null:
		failures.append("HUD should expose a persistent boss last-attack label")
	if not hud.has_method("_on_boss_status_changed"):
		failures.append("HUD should handle boss status updates")
	else:
		hud.call("_on_boss_status_changed", {
			"name": "Golem Thuc Tinh",
			"hp": 45,
			"max_hp": 100,
			"phase": 3,
			"phase_text": "ENRAGE + BULLET HELL",
			"enraged": true,
			"enrage_warning": "ENRAGED: Bullet hell + traps",
			"pattern": "enrage_bullet_hell",
			"pattern_label": "Pattern: Bullet Hell + Trap Wave",
			"pattern_steps": ["Bullet hell", "Trap wave", "Dash gaps"],
			"pattern_step_index": 1,
			"current_pattern_step": "Trap wave",
			"next_pattern_step": "Dash gaps",
			"pattern_timeline": "Now: Trap wave | Next: Dash gaps",
			"counter_hint": "Keep moving between bullet lanes",
			"dodge_cue": "Rotate through bullet gaps",
			"punish_window_seconds": 0.5,
			"safe_window_hint": "Punish after charge whiffs",
			"next_attack": "Next: Bullet hell 0.8s",
			"next_attack_id": "bullet_hell",
			"next_attack_label": "Bullet Hell",
			"next_attack_warning": "Dodge radial bullets",
			"arena_pressure_summary": "Bullets x12 | Traps 5 | Guns 4 | Intensity high",
			"enrage_intensity": "high",
			"active_trap_count": 5,
			"floating_gun_count": 4,
			"enrage_bullet_count": 12,
		})
		await process_frame
		if not _has_label_containing(hud, "Golem Thuc Tinh"):
			failures.append("HUD boss label should show boss name")
		if not _has_label_containing(hud, "45/100"):
			failures.append("HUD boss label should show boss hp")
		if not _has_label_containing(hud, "ENRAGE"):
			failures.append("HUD boss label should show boss phase")
		if not _has_label_containing(hud, "Bullet hell"):
			failures.append("HUD boss label should show next attack cue")
		var enrage_warning := hud.get_node_or_null("BossEnrageWarningLabel") as Label
		if enrage_warning == null or not enrage_warning.visible:
			failures.append("HUD should show persistent boss enrage warning")
		elif not enrage_warning.text.contains("Bullet hell") or not enrage_warning.text.contains("traps"):
			failures.append("boss enrage warning should explain bullet hell and traps")
		elif not bool(enrage_warning.get_meta("boss_enraged", false)) \
				or int(enrage_warning.get_meta("boss_phase", 0)) != 3 \
				or str(enrage_warning.get_meta("boss_pattern", "")) != "enrage_bullet_hell":
			failures.append("boss enrage warning should store phase/enrage/pattern metadata")
		var pattern_cue := hud.get_node_or_null("BossPatternCueLabel") as Label
		if pattern_cue == null or not pattern_cue.visible:
			failures.append("HUD should show persistent boss pattern cue")
		elif not pattern_cue.text.contains("Bullet Hell") or not pattern_cue.text.contains("Trap Wave"):
			failures.append("boss pattern cue should name the active pattern")
		elif not pattern_cue.text.contains("Steps:") or not pattern_cue.text.contains("Dash gaps"):
			failures.append("boss pattern cue should list readable pattern steps")
		elif not pattern_cue.text.contains("Now: Trap wave") \
				or not pattern_cue.text.contains("Next: Dash gaps"):
			failures.append("boss pattern cue should show current and next pattern step")
		elif not pattern_cue.text.contains("Counter:") or not pattern_cue.text.contains("bullet lanes"):
			failures.append("boss pattern cue should show counterplay hint")
		elif not pattern_cue.text.contains("Dodge:") or not pattern_cue.text.contains("bullet gaps"):
			failures.append("boss pattern cue should show concise dodge cue")
		elif not pattern_cue.text.contains("Punish:") or not pattern_cue.text.contains("0.5s"):
			failures.append("boss pattern cue should show punish window timing")
		elif not pattern_cue.text.contains("Upcoming: Bullet Hell") \
				or not pattern_cue.text.contains("Dodge radial bullets"):
			failures.append("boss pattern cue should show structured upcoming attack preview")
		elif not pattern_cue.text.contains("Pressure:") \
				or not pattern_cue.text.contains("Traps 5") \
				or not pattern_cue.text.contains("Guns 4"):
			failures.append("boss pattern cue should show readable arena pressure")
		if pattern_cue != null:
			if not str(pattern_cue.get_meta("counter_hint", "")).contains("bullet lanes"):
				failures.append("boss pattern cue should store counter hint metadata")
			if not str(pattern_cue.get_meta("dodge_cue", "")).contains("bullet gaps"):
				failures.append("boss pattern cue should store dodge cue metadata")
			if not str(pattern_cue.get_meta("pattern_steps", "")).contains("Trap wave"):
				failures.append("boss pattern cue should store pattern steps metadata")
			if int(pattern_cue.get_meta("pattern_step_index", -1)) != 1:
				failures.append("boss pattern cue should store pattern step index metadata")
			if str(pattern_cue.get_meta("current_pattern_step", "")) != "Trap wave":
				failures.append("boss pattern cue should store current pattern step metadata")
			if str(pattern_cue.get_meta("next_pattern_step", "")) != "Dash gaps":
				failures.append("boss pattern cue should store next pattern step metadata")
			if not str(pattern_cue.get_meta("pattern_timeline", "")).contains("Now: Trap wave"):
				failures.append("boss pattern cue should store readable pattern timeline metadata")
			if float(pattern_cue.get_meta("punish_window_seconds", 0.0)) <= 0.0:
				failures.append("boss pattern cue should store punish window metadata")
			if not str(pattern_cue.get_meta("safe_window_hint", "")).contains("Punish"):
				failures.append("boss pattern cue should store safe-window hint metadata")
			if str(pattern_cue.get_meta("next_attack_id", "")) != "bullet_hell":
				failures.append("boss pattern cue should store structured next attack id")
			if str(pattern_cue.get_meta("next_attack_label", "")) != "Bullet Hell":
				failures.append("boss pattern cue should store structured next attack label")
			if not str(pattern_cue.get_meta("next_attack_warning", "")).contains("radial"):
				failures.append("boss pattern cue should store structured next attack warning")
			if not str(pattern_cue.get_meta("arena_pressure_summary", "")).contains("Bullets x12"):
				failures.append("boss pattern cue should store arena pressure summary metadata")
			if str(pattern_cue.get_meta("enrage_intensity", "")) != "high":
				failures.append("boss pattern cue should store enrage intensity metadata")
			if int(pattern_cue.get_meta("active_trap_count", 0)) != 5:
				failures.append("boss pattern cue should store active trap pressure count")
			if int(pattern_cue.get_meta("floating_gun_count", 0)) != 4:
				failures.append("boss pattern cue should store floating gun pressure count")
			if int(pattern_cue.get_meta("enrage_bullet_count", 0)) != 12:
				failures.append("boss pattern cue should store planned enrage bullet count")
		var fill := hud.get_node_or_null("BossHealthFill") as ColorRect
		if fill == null or fill.size.x <= 0.0 or fill.size.x >= 160.0:
			failures.append("HUD boss fill should scale with boss hp ratio")
		var health_label := hud.get_node_or_null("BossHealthLabel") as Label
		if health_label != null:
			if str(health_label.get_meta("boss_name", "")) != "Golem Thuc Tinh":
				failures.append("HUD boss label should expose structured boss name metadata")
			if int(health_label.get_meta("boss_hp_current", 0)) != 45 \
					or int(health_label.get_meta("boss_hp_max", 0)) != 100:
				failures.append("HUD boss label should expose structured boss HP metadata")
			if not is_equal_approx(float(health_label.get_meta("boss_hp_ratio", 0.0)), 0.45):
				failures.append("HUD boss label should expose structured boss HP ratio metadata")
		if fill != null:
			if str(fill.get_meta("boss_name", "")) != "Golem Thuc Tinh":
				failures.append("HUD boss fill should expose structured boss name metadata")
			if int(fill.get_meta("boss_hp_current", 0)) != 45 \
					or int(fill.get_meta("boss_hp_max", 0)) != 100:
				failures.append("HUD boss fill should expose structured boss HP metadata")
			if not is_equal_approx(float(fill.get_meta("boss_hp_ratio", 0.0)), 0.45):
				failures.append("HUD boss fill should expose structured boss HP ratio metadata")
		if not hud.has_method("_on_boss_phase_changed"):
			failures.append("HUD should handle boss phase changed signal payload")
		else:
			hud.call("_on_boss_phase_changed", {
				"name": "Golem Thuc Tinh",
				"phase_text": "ENRAGE + BULLET HELL",
				"phase": 3,
				"enraged": true,
				"pattern": "enrage_bullet_hell",
				"pattern_label": "Pattern: Bullet Hell + Trap Wave",
				"pattern_steps": ["Bullet hell", "Trap wave", "Dash gaps"],
				"pattern_step_index": 1,
				"current_pattern_step": "Trap wave",
				"next_pattern_step": "Dash gaps",
				"pattern_timeline": "Now: Trap wave | Next: Dash gaps",
				"counter_hint": "Keep moving between bullet lanes",
				"dodge_cue": "Rotate through bullet gaps",
				"punish_window_seconds": 0.5,
				"safe_window_hint": "Punish after charge whiffs",
				"elapsed_seconds": 28.0,
			})
			await process_frame
			var phase_flash := hud.get_node_or_null("BossPhaseFlashLabel") as Label
			if phase_flash == null or not phase_flash.visible:
				failures.append("boss phase flash should become visible on phase change")
			elif not phase_flash.text.contains("ENRAGE"):
				failures.append("boss phase flash should show readable phase text")
			elif not phase_flash.text.contains("28.0s"):
				failures.append("boss phase flash should show elapsed phase timing")
			if phase_flash != null and not is_equal_approx(
					float(phase_flash.get_meta("boss_phase_elapsed_seconds", -1.0)), 28.0):
				failures.append("boss phase flash should store elapsed phase timing metadata")
			var phase_sfx := hud.get_node_or_null("BossPhaseSfx") as AudioStreamPlayer
			if phase_sfx == null:
				failures.append("HUD should create boss enrage sound placeholder")
			else:
				if str(phase_sfx.get_meta("boss_phase_sound_id", "")) != "boss_enrage":
					failures.append("boss enrage sound placeholder should expose enrage cue id")
				if not is_equal_approx(float(phase_sfx.get_meta("boss_phase_elapsed_seconds", -1.0)), 28.0):
					failures.append("boss phase sound placeholder should store elapsed phase timing metadata")
				if str(phase_sfx.get_meta("audio_cue_kind", "")) != "boss_phase":
					failures.append("boss phase sound placeholder should store cue kind metadata")
				if not bool(phase_sfx.get_meta("boss_enraged", false)):
					failures.append("boss phase sound placeholder should store enrage metadata")
				if str(phase_sfx.get_meta("boss_pattern", "")) != "enrage_bullet_hell":
					failures.append("boss phase sound placeholder should store pattern metadata")
				if not str(phase_sfx.get_meta("boss_pattern_label", "")).contains("Bullet Hell"):
					failures.append("boss phase sound placeholder should store pattern label metadata")
				if not str(phase_sfx.get_meta("boss_pattern_steps", "")).contains("Trap wave"):
					failures.append("boss phase sound placeholder should store pattern steps metadata")
				if int(phase_sfx.get_meta("boss_pattern_step_index", -1)) != 1:
					failures.append("boss phase sound placeholder should store pattern step index metadata")
				if str(phase_sfx.get_meta("boss_current_pattern_step", "")) != "Trap wave":
					failures.append("boss phase sound placeholder should store current pattern step metadata")
				if str(phase_sfx.get_meta("boss_next_pattern_step", "")) != "Dash gaps":
					failures.append("boss phase sound placeholder should store next pattern step metadata")
				if not str(phase_sfx.get_meta("boss_pattern_timeline", "")).contains("Now: Trap wave"):
					failures.append("boss phase sound placeholder should store readable timeline metadata")
				if not str(phase_sfx.get_meta("boss_counter_hint", "")).contains("bullet lanes"):
					failures.append("boss phase sound placeholder should store counter hint metadata")
				if not str(phase_sfx.get_meta("boss_dodge_cue", "")).contains("bullet gaps"):
					failures.append("boss phase sound placeholder should store dodge cue metadata")
				if float(phase_sfx.get_meta("boss_punish_window_seconds", 0.0)) <= 0.0:
					failures.append("boss phase sound placeholder should store punish window metadata")
				if not str(phase_sfx.get_meta("boss_safe_window_hint", "")).contains("Punish"):
					failures.append("boss phase sound placeholder should store safe-window hint metadata")
				if str(phase_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
					failures.append("boss phase sound placeholder should come from AudioCueDB")
				if phase_sfx.stream == null:
					failures.append("boss phase sound placeholder should assign an audio stream")
				if not bool(phase_sfx.get_meta("placeholder_audio_stream", false)):
					failures.append("boss phase sound placeholder should mark generated audio stream metadata")
				if DisplayServer.get_name() == "headless" \
						and not bool(phase_sfx.get_meta("headless_playback_skipped", false)):
					failures.append("boss phase sound placeholder should skip playback in headless smoke")
		hud.call("_on_boss_status_changed", {})
		await process_frame
		var label := hud.get_node_or_null("BossHealthLabel") as Label
		if label != null and label.visible:
			failures.append("HUD boss label should hide when no boss status exists")
		if label != null:
			if label.text != "":
				failures.append("HUD boss label should clear stale boss text when no status exists")
			if str(label.get_meta("next_attack_id", "")) != "":
				failures.append("HUD boss label should clear stale next-attack metadata")
			if str(label.get_meta("boss_name", "")) != "" \
					or int(label.get_meta("boss_hp_current", 0)) != 0 \
					or int(label.get_meta("boss_hp_max", 0)) != 0 \
					or not is_equal_approx(float(label.get_meta("boss_hp_ratio", 0.0)), 0.0):
				failures.append("HUD boss label should clear stale boss HP metadata")
		if fill != null and fill.size != Vector2.ZERO:
			failures.append("HUD boss fill should reset size when no boss status exists")
		if fill != null:
			if str(fill.get_meta("boss_name", "")) != "" \
					or int(fill.get_meta("boss_hp_current", 0)) != 0 \
					or int(fill.get_meta("boss_hp_max", 0)) != 0 \
					or not is_equal_approx(float(fill.get_meta("boss_hp_ratio", 0.0)), 0.0):
				failures.append("HUD boss fill should clear stale boss HP metadata")
		if enrage_warning != null and enrage_warning.visible:
			failures.append("HUD boss enrage warning should hide when no boss status exists")
		if enrage_warning != null:
			if enrage_warning.text != "":
				failures.append("HUD boss enrage warning should clear stale text")
			if bool(enrage_warning.get_meta("boss_enraged", false)) \
					or int(enrage_warning.get_meta("boss_phase", 0)) != 0 \
					or str(enrage_warning.get_meta("boss_pattern", "")) != "" \
					or str(enrage_warning.get_meta("enrage_warning", "")) != "":
				failures.append("HUD boss enrage warning should clear stale phase/enrage metadata")
		if pattern_cue != null and pattern_cue.visible:
			failures.append("HUD boss pattern cue should hide when no boss status exists")
		if pattern_cue != null:
			if pattern_cue.text != "":
				failures.append("HUD boss pattern cue should clear stale text")
			if str(pattern_cue.get_meta("pattern_steps", "")) != "" \
					or int(pattern_cue.get_meta("pattern_step_index", -1)) != -1 \
					or str(pattern_cue.get_meta("current_pattern_step", "")) != "" \
					or str(pattern_cue.get_meta("next_pattern_step", "")) != "" \
					or str(pattern_cue.get_meta("next_attack_id", "")) != "":
				failures.append("HUD boss pattern cue should clear stale pattern metadata")
		var last_attack := hud.get_node_or_null("BossLastAttackLabel") as Label
		if last_attack != null and last_attack.visible:
			failures.append("HUD boss last-attack label should hide when no boss status exists")
		if last_attack != null:
			if last_attack.text != "":
				failures.append("HUD boss last-attack label should clear stale text when not preserved")
			if str(last_attack.get_meta("boss_attack", "")) != "" \
					or str(last_attack.get_meta("boss_attack_label", "")) != "":
				failures.append("HUD boss last-attack label should clear stale attack metadata when not preserved")
	hud.queue_free()
	await process_frame

func _check_hud_boss_phase_signal_feedback(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var builder := GraphBuilder.new()
	ctrl.rooms = builder.build(9753, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.BOSS)
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	hud.bind(player, ctrl)
	if not ctrl.has_signal("boss_phase_changed"):
		failures.append("FloorController should expose boss_phase_changed for HUD binding")
	else:
		ctrl.emit_signal("boss_phase_changed", {
			"name": "Golem Thuc Tinh",
			"phase_text": "VOLLEY + TRAPS",
			"phase": 2,
			"pattern": "volley_traps",
			"pattern_label": "Pattern: Rock Volley + Trap Wave",
		})
		await process_frame
		var flash := hud.get_node_or_null("BossPhaseFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("HUD should flash boss phase when FloorController emits boss_phase_changed")
		elif not flash.text.contains("VOLLEY"):
			failures.append("HUD boss phase signal flash should show phase text")
		var sfx := hud.get_node_or_null("BossPhaseSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("HUD should create boss phase sound placeholder")
		else:
			if str(sfx.get_meta("boss_phase_sound_id", "")) != "boss_phase_shift":
				failures.append("boss phase sound placeholder should expose phase cue id")
			if int(sfx.get_meta("boss_phase", 0)) != 2:
				failures.append("boss phase sound placeholder should store phase metadata")
			if str(sfx.get_meta("boss_pattern", "")) != "volley_traps":
				failures.append("boss phase signal sound placeholder should store pattern metadata")
			if not str(sfx.get_meta("boss_pattern_label", "")).contains("Rock Volley"):
				failures.append("boss phase signal sound placeholder should store pattern label metadata")
			if DisplayServer.get_name() == "headless" \
					and not bool(sfx.get_meta("headless_playback_skipped", false)):
				failures.append("boss phase signal sound placeholder should skip playback in headless smoke")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_boss_attack_signal_feedback(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var builder := GraphBuilder.new()
	ctrl.rooms = builder.build(9754, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.BOSS)
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	hud.bind(player, ctrl)
	if not ctrl.has_signal("boss_attack_cued"):
		failures.append("FloorController should expose boss_attack_cued for HUD binding")
	elif not hud.has_method("_on_boss_attack_cued"):
		failures.append("HUD should handle boss_attack_cued payloads")
	else:
		ctrl.emit_signal("boss_attack_cued", {
			"name": "Golem Thuc Tinh",
			"attack": "bullet_hell",
			"attack_label": "Bullet Hell",
			"projectile_count": 8,
			"pattern_label": "Pattern: Bullet Hell + Trap Wave",
			"warning": "Dodge radial bullets",
			"counter_hint": "Keep moving between bullet lanes",
			"punish_window_seconds": 0.45,
			"safe_window_hint": "Punish briefly after charge whiffs",
			"attack_sequence_index": 7,
			"previous_attack": "trap_wave",
			"recent_attack_summary": "Trap Wave x4 -> Bullet Hell x8",
			"elapsed_seconds": 31.2,
		})
		await process_frame
		var flash := hud.get_node_or_null("BossAttackCueFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("HUD should flash boss attack cue when FloorController emits boss_attack_cued")
		elif not flash.text.contains("Bullet Hell") or not flash.text.contains("8"):
			failures.append("boss attack cue flash should show attack label and count")
		elif not flash.text.contains("31.2s"):
			failures.append("boss attack cue flash should show elapsed attack timing")
		if flash != null and not is_equal_approx(
				float(flash.get_meta("boss_attack_elapsed_seconds", -1.0)), 31.2):
			failures.append("boss attack cue flash should store elapsed attack timing metadata")
		var last_attack := hud.get_node_or_null("BossLastAttackLabel") as Label
		if last_attack == null or not last_attack.visible:
			failures.append("HUD should keep a persistent boss last-attack label after attack cues")
		else:
			if not last_attack.text.contains("Last: Bullet Hell") \
					or not last_attack.text.contains("Dodge radial bullets") \
					or not last_attack.text.contains("Pattern: Bullet Hell + Trap Wave"):
				failures.append("boss last-attack label should show last attack, warning, and pattern")
			if not last_attack.text.contains("Recent: Trap Wave x4 -> Bullet Hell x8"):
				failures.append("boss last-attack label should show readable recent attack history")
			if str(last_attack.get_meta("boss_attack", "")) != "bullet_hell":
				failures.append("boss last-attack label should store attack metadata")
			if str(last_attack.get_meta("boss_attack_label", "")) != "Bullet Hell":
				failures.append("boss last-attack label should store attack label metadata")
			if int(last_attack.get_meta("boss_attack_count", 0)) != 8:
				failures.append("boss last-attack label should store projectile/hazard count metadata")
			if not str(last_attack.get_meta("boss_pattern_label", "")).contains("Bullet Hell"):
				failures.append("boss last-attack label should store pattern metadata")
			if str(last_attack.get_meta("boss_attack_warning", "")) != "Dodge radial bullets":
				failures.append("boss last-attack label should store warning metadata")
			if not str(last_attack.get_meta("boss_counter_hint", "")).contains("Keep moving"):
				failures.append("boss last-attack label should store counter hint metadata")
			if float(last_attack.get_meta("boss_punish_window_seconds", 0.0)) <= 0.0:
				failures.append("boss last-attack label should store punish window metadata")
			if not str(last_attack.get_meta("boss_safe_window_hint", "")).contains("Punish"):
				failures.append("boss last-attack label should store safe window metadata")
			if int(last_attack.get_meta("boss_attack_sequence_index", 0)) != 7:
				failures.append("boss last-attack label should store attack sequence metadata")
			if str(last_attack.get_meta("boss_previous_attack", "")) != "trap_wave":
				failures.append("boss last-attack label should store previous attack metadata")
			if not str(last_attack.get_meta("boss_recent_attack_summary", "")).contains("Trap Wave"):
				failures.append("boss last-attack label should store recent attack summary metadata")
			if not is_equal_approx(float(last_attack.get_meta("boss_attack_elapsed_seconds", -1.0)), 31.2):
				failures.append("boss last-attack label should store elapsed attack timing metadata")
		var sfx := hud.get_node_or_null("BossAttackSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("HUD should create boss attack sound placeholder")
		else:
			if str(sfx.get_meta("boss_sound_id", "")) != "boss_bullet_hell":
				failures.append("boss attack sound placeholder should expose boss cue id")
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("boss attack sound placeholder should come from AudioCueDB")
			if str(sfx.get_meta("boss_attack", "")) != "bullet_hell":
				failures.append("boss attack sound placeholder should store boss attack metadata")
			if int(sfx.get_meta("boss_attack_count", 0)) != 8:
				failures.append("boss attack sound placeholder should store projectile/hazard count metadata")
			if str(sfx.get_meta("boss_attack_warning", "")) != "Dodge radial bullets":
				failures.append("boss attack sound placeholder should store warning metadata")
			if not str(sfx.get_meta("boss_pattern_label", "")).contains("Bullet Hell"):
				failures.append("boss attack sound placeholder should store pattern metadata")
			if not str(sfx.get_meta("boss_counter_hint", "")).contains("Keep moving"):
				failures.append("boss attack sound placeholder should store counter hint metadata")
			if float(sfx.get_meta("boss_punish_window_seconds", 0.0)) <= 0.0:
				failures.append("boss attack sound placeholder should store punish window metadata")
			if not str(sfx.get_meta("boss_safe_window_hint", "")).contains("Punish"):
				failures.append("boss attack sound placeholder should store safe-window metadata")
			if int(sfx.get_meta("boss_attack_sequence_index", 0)) != 7:
				failures.append("boss attack sound placeholder should store attack sequence metadata")
			if str(sfx.get_meta("boss_previous_attack", "")) != "trap_wave":
				failures.append("boss attack sound placeholder should store previous attack metadata")
			if not str(sfx.get_meta("boss_recent_attack_summary", "")).contains("Trap Wave"):
				failures.append("boss attack sound placeholder should store recent attack summary metadata")
			if not is_equal_approx(float(sfx.get_meta("boss_attack_elapsed_seconds", -1.0)), 31.2):
				failures.append("boss attack sound placeholder should store elapsed attack timing metadata")
			if str(sfx.get_meta("audio_cue_kind", "")) != "boss_attack":
				failures.append("boss attack sound placeholder should store cue kind metadata")
			if sfx.stream == null:
				failures.append("boss attack sound placeholder should assign an audio stream")
			if not bool(sfx.get_meta("placeholder_audio_stream", false)):
				failures.append("boss attack sound placeholder should mark generated audio stream metadata")
			if DisplayServer.get_name() == "headless" \
					and not bool(sfx.get_meta("headless_playback_skipped", false)):
				failures.append("boss attack sound placeholder should skip playback in headless smoke")
		ctrl.emit_signal("boss_attack_cued", {
			"name": "Spore Golem",
			"attack": "bullet_hell",
			"attack_label": "Bullet Hell",
			"variant_attack": "spore_bloom",
			"variant_attack_label": "Spore Bloom",
			"projectile_count": 12,
			"pattern_label": "Pattern: Spore Bullet Hell + Trap Wave",
			"warning": "Dodge radial bullets",
			"variant_warning": "Poison bloom: keep moving through gaps",
			"counter_hint": "Keep moving through poison gaps",
			"punish_window_seconds": 0.45,
			"safe_window_hint": "Punish after bloom",
		})
		await process_frame
		flash = hud.get_node_or_null("BossAttackCueFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("HUD should flash boss variant attack cue")
		elif not flash.text.contains("Spore Bloom") or not flash.text.contains("Poison bloom") \
				or not flash.text.contains("12"):
			failures.append("boss variant attack cue flash should show variant label, warning, and count")
		last_attack = hud.get_node_or_null("BossLastAttackLabel") as Label
		if last_attack == null or not last_attack.visible:
			failures.append("HUD should keep variant attack as persistent last-attack label")
		else:
			if not last_attack.text.contains("Last: Spore Bloom") \
					or not last_attack.text.contains("Poison bloom") \
					or not last_attack.text.contains("Pattern: Spore Bullet Hell"):
				failures.append("boss last-attack label should update to variant label, warning, and pattern")
			if str(last_attack.get_meta("boss_variant_attack", "")) != "spore_bloom":
				failures.append("boss last-attack label should store variant attack metadata")
			if str(last_attack.get_meta("boss_attack_label", "")) != "Spore Bloom":
				failures.append("boss last-attack label should store variant attack label metadata")
			if not str(last_attack.get_meta("boss_counter_hint", "")).contains("poison"):
				failures.append("boss last-attack label should update variant counter metadata")
		sfx = hud.get_node_or_null("BossAttackSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("HUD should refresh boss variant attack sound placeholder")
		else:
			if str(sfx.get_meta("boss_sound_id", "")) != "boss_spore_bloom":
				failures.append("boss variant attack sound placeholder should expose variant cue id")
			if str(sfx.get_meta("boss_variant_attack", "")) != "spore_bloom":
				failures.append("boss variant attack sound placeholder should store variant attack metadata")
			if not str(sfx.get_meta("boss_counter_hint", "")).contains("poison"):
				failures.append("boss variant attack sound placeholder should store variant counter metadata")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _check_hud_trap_room_live_objective(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var player := Player.new()
	var renderer := RoomRenderer.new()
	var hud := HUD.new()
	var room := RoomNode.new()
	room.id = 88
	room.type = RoomNode.RoomType.EVENT
	ctrl.rooms = [room]
	ctrl.current_room = room
	ctrl.set("_renderer", renderer)
	root.add_child(ctrl)
	root.add_child(player)
	ctrl.add_child(renderer)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	renderer.setup(_basic_grid(), [], null, player, RoomNode.RoomType.EVENT)
	hud.bind(player, ctrl)
	await process_frame
	var next_action := hud.get_node_or_null("ObjectiveNextActionLabel") as Label
	if next_action == null:
		failures.append("HUD should expose trap room live objective label")
	else:
		if not next_action.text.contains("Survive") or not next_action.text.contains("4s") \
				or not next_action.text.contains("Cache locked"):
			failures.append("HUD trap room next action should show survival countdown and locked cache")
		if str(next_action.get_meta("objective_state", "")) != "survive":
			failures.append("HUD trap room next action should expose survive objective state")
		if float(next_action.get_meta("time_left_seconds", 0.0)) <= 0.0:
			failures.append("HUD trap room next action should expose live time-left metadata")
		if str(next_action.get_meta("reward_kind", "")) != "trap_cache":
			failures.append("HUD trap room next action should expose trap cache reward kind")
		if not bool(next_action.get_meta("reward_locked", false)):
			failures.append("HUD trap room next action should expose locked reward metadata")
	renderer.call("_update_trap_room_survival_countdown", 1.0)
	hud.call("_update_room_objective", ctrl)
	next_action = hud.get_node_or_null("ObjectiveNextActionLabel") as Label
	if next_action == null or not next_action.text.contains("Hurry"):
		failures.append("HUD trap room next action should surface urgent final-second warning")
	elif str(next_action.get_meta("countdown_urgency", "")) != "urgent":
		failures.append("HUD trap room next action should expose urgent countdown metadata")
	renderer.complete_trap_room_survival()
	await process_frame
	next_action = hud.get_node_or_null("ObjectiveNextActionLabel") as Label
	if next_action == null or not next_action.text.contains("Cache unlocked"):
		failures.append("HUD trap room next action should update when survival unlocks cache")
	elif str(next_action.get_meta("objective_state", "")) != "complete":
		failures.append("HUD trap room next action should expose complete objective state")
	elif bool(next_action.get_meta("reward_locked", true)):
		failures.append("HUD trap room next action should clear locked reward metadata after survival")
	hud.queue_free()
	ctrl.queue_free()
	player.queue_free()
	await process_frame

func _check_hud_combat_wave_live_objective(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var player := Player.new()
	var renderer := RoomRenderer.new()
	var hud := HUD.new()
	var room := RoomNode.new()
	room.id = 89
	room.type = RoomNode.RoomType.COMBAT
	ctrl.rooms = [room]
	ctrl.current_room = room
	ctrl.set("_renderer", renderer)
	root.add_child(ctrl)
	root.add_child(player)
	ctrl.add_child(renderer)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	var plan: Array[Dictionary] = [
		{"enemy": {"id": "hud_w1", "kind": "melee", "hp": 5, "dmg": 1}, "wave": 1, "tile": Vector2i(3, 3), "elite": false, "modifier": ""},
		{"enemy": {"id": "hud_w2", "kind": "melee", "hp": 5, "dmg": 1}, "wave": 2, "tile": Vector2i(4, 3), "elite": false, "modifier": ""},
		{"enemy": {"id": "hud_w3", "kind": "melee", "hp": 5, "dmg": 1}, "wave": 3, "tile": Vector2i(5, 3), "elite": false, "modifier": ""},
	]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, player, RoomNode.RoomType.COMBAT)
	hud.bind(player, ctrl)
	await process_frame
	var objective := hud.get_node_or_null("ObjectiveLabel") as Label
	if objective == null:
		failures.append("HUD should expose a stable objective label node")
	else:
		if not objective.text.contains("Wave 1/3") or not objective.text.contains("1 left"):
			failures.append("HUD objective label should show live combat wave progress")
		if int(objective.get_meta("wave_index", 0)) != 1:
			failures.append("HUD objective label should expose wave_index metadata")
		if int(objective.get_meta("wave_count", 0)) != 3:
			failures.append("HUD objective label should expose wave_count metadata")
		if int(objective.get_meta("enemies_left", 0)) != 1:
			failures.append("HUD objective label should expose enemies_left metadata")
		if not str(objective.get_meta("wave_progress_text", "")).contains("Wave 1/3"):
			failures.append("HUD objective label should expose wave_progress_text metadata")
	var next_action := hud.get_node_or_null("ObjectiveNextActionLabel") as Label
	if next_action == null:
		failures.append("HUD should expose combat wave next-action label")
	else:
		if not next_action.text.contains("Defeat") or not next_action.text.contains("Wave 1/3"):
			failures.append("HUD combat next-action should include live wave progress")
		if int(next_action.get_meta("wave_index", 0)) != 1:
			failures.append("HUD combat next-action should expose wave_index metadata")
		if int(next_action.get_meta("wave_count", 0)) != 3:
			failures.append("HUD combat next-action should expose wave_count metadata")
		if int(next_action.get_meta("enemies_left", 0)) != 1:
			failures.append("HUD combat next-action should expose enemies_left metadata")
	renderer.queue_free()
	hud.queue_free()
	ctrl.queue_free()
	player.queue_free()
	await process_frame

func _check_hud_room_objective_clear_feedback(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var builder := GraphBuilder.new()
	ctrl.rooms = builder.build(24601, 1)
	ctrl.current_room = _first_room_of_type(ctrl.rooms, RoomNode.RoomType.COMBAT)
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	hud.bind(player, ctrl)
	await process_frame
	if not ctrl.has_signal("room_objective_completed"):
		failures.append("FloorController should expose room_objective_completed for HUD objective feedback")
	if not ctrl.has_signal("room_mastery_awarded"):
		failures.append("FloorController should expose room_mastery_awarded for HUD mastery feedback")
	if hud.get_node_or_null("ObjectiveCompleteFlashLabel") == null:
		failures.append("HUD should expose objective complete flash label")
	if hud.get_node_or_null("RoomMasteryFlashLabel") == null:
		failures.append("HUD should expose room mastery flash label")
	if not hud.has_method("_on_room_mastery_awarded"):
		failures.append("HUD should handle room mastery payloads")
	var next_action := hud.get_node_or_null("ObjectiveNextActionLabel") as Label
	if next_action == null:
		failures.append("HUD should expose a persistent next-action objective label")
	else:
		if not next_action.text.contains("Next:") or not next_action.text.contains("Defeat"):
			failures.append("HUD next-action label should tell the player what to do in combat")
		if str(next_action.get_meta("next_action_key", "")) != "combat":
			failures.append("HUD next-action label should store semantic action metadata")
	if ctrl.has_signal("room_objective_completed"):
		ctrl.cleared_rooms[ctrl.current_room.id] = true
		ctrl.emit_signal("room_objective_completed", "COMBAT complete | Reward ready")
		await process_frame
		var flash := hud.get_node_or_null("ObjectiveCompleteFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("HUD should flash when room objective completes")
		elif not flash.text.contains("Objective complete") or not flash.text.contains("Reward ready"):
			failures.append("objective flash should explain completion and reward")
		else:
			if str(flash.get_meta("objective_state", "")) != "reward_ready":
				failures.append("objective flash should expose reward_ready state metadata")
			if str(flash.get_meta("objective_room_type", "")) != "COMBAT":
				failures.append("objective flash should expose completed room type metadata")
			if str(flash.get_meta("objective_next_action_key", "")) != "reward":
				failures.append("objective flash should expose next reward action metadata")
		var sfx := hud.get_node_or_null("ObjectiveCompleteSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("HUD objective clear should create sound placeholder")
		else:
			if str(sfx.get_meta("objective_sound_id", "")) != "objective_reward_ready":
				failures.append("objective clear sound should expose reward-ready cue id")
			if not str(sfx.get_meta("objective_text", "")).contains("Reward ready"):
				failures.append("objective clear sound should store objective text metadata")
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("objective clear sound should come from AudioCueDB")
			if sfx.stream == null:
				failures.append("objective clear sound should assign an audio stream")
			if DisplayServer.get_name() == "headless" \
					and not bool(sfx.get_meta("headless_playback_skipped", false)):
				failures.append("objective clear sound should skip playback in headless smoke")
		next_action = hud.get_node_or_null("ObjectiveNextActionLabel") as Label
		if next_action == null or not next_action.text.contains("Pick") \
				or not next_action.text.contains("upgrade"):
			failures.append("HUD next-action label should update to reward pickup after objective clear")
		elif str(next_action.get_meta("next_action_key", "")) != "reward":
			failures.append("HUD next-action metadata should update after objective clear")
		var boss := RoomNode.new()
		boss.id = 9001
		boss.type = RoomNode.RoomType.BOSS
		ctrl.current_room = boss
		ctrl.current_biome = {"id": "crystal_archive", "run_finale": true}
		ctrl.cleared_rooms[boss.id] = true
		ctrl.emit_signal("room_objective_completed", "FINAL BOSS complete | Run complete portal ready")
		await process_frame
		var finale_flash := hud.get_node_or_null("ObjectiveCompleteFlashLabel") as Label
		if finale_flash == null or not bool(finale_flash.get_meta("objective_run_finale", false)):
			failures.append("HUD final objective flash should expose run finale metadata")
		var finale_sfx := hud.get_node_or_null("ObjectiveCompleteSfx") as AudioStreamPlayer
		if finale_sfx == null or str(finale_sfx.get_meta("audio_cue_family", "")) != "finale":
			failures.append("HUD final objective sound should expose finale audio family")
		elif not bool(finale_sfx.get_meta("objective_finale", false)):
			failures.append("HUD final objective sound should expose finale metadata")
		next_action = hud.get_node_or_null("ObjectiveNextActionLabel") as Label
		if next_action == null or not next_action.text.contains("run complete portal"):
			failures.append("HUD final boss next-action label should point to run complete portal")
	if ctrl.has_signal("room_mastery_awarded"):
		ctrl.emit_signal("room_mastery_awarded", {
			"room_id": ctrl.current_room.id,
			"room_type_name": "COMBAT",
			"summary": "Perfect | Reward",
			"badges": ["Perfect", "Reward"],
			"perfect_clear": true,
			"close_call": false,
			"damage_taken": 0,
		})
		await process_frame
		var mastery_flash := hud.get_node_or_null("RoomMasteryFlashLabel") as Label
		if mastery_flash == null or not mastery_flash.visible:
			failures.append("HUD should flash when room mastery is awarded")
		elif not mastery_flash.text.contains("Mastery:") or not mastery_flash.text.contains("Perfect"):
			failures.append("room mastery flash should show readable mastery badges")
		else:
			if str(mastery_flash.get_meta("mastery_room_type", "")) != "COMBAT":
				failures.append("room mastery flash should store room type metadata")
			if not bool(mastery_flash.get_meta("perfect_clear", false)):
				failures.append("room mastery flash should store perfect clear metadata")
			if int(mastery_flash.get_meta("damage_taken", -1)) != 0:
				failures.append("room mastery flash should store damage taken metadata")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _first_room_of_type(rooms: Array[RoomNode], room_type: int) -> RoomNode:
	for room in rooms:
		if room.type == room_type:
			return room
	return rooms[0]

func _first_side_branch(rooms: Array[RoomNode]) -> RoomNode:
	for room in rooms:
		if not room.on_critical_path:
			return room
	return null

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

func _has_label_containing(parent: Node, text: String) -> bool:
	for child in parent.find_children("*", "Label", true, false):
		if str(child.text).contains(text):
			return true
	return false

func _colors_close(actual: Color, expected: Color) -> bool:
	return absf(actual.r - expected.r) < 0.01 \
		and absf(actual.g - expected.g) < 0.01 \
		and absf(actual.b - expected.b) < 0.01
