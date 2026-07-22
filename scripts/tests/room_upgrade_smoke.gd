extends SceneTree

const UpgradeDBScript := preload("res://scripts/progression/upgrade_db.gd")

func _init() -> void:
	var failures: Array[String] = []

	await _check_upgrade_db(failures)
	await _check_upgrade_overlay(failures)
	_check_upgrade_overlay_stack_preview(failures)
	await _check_reward_choice_set_progress_hint(failures)
	await _check_upgrade_overlay_synergy_reason(failures)
	await _check_reward_history_cue(failures)
	await _check_reward_decision_context(failures)
	await _check_upgrade_best_fit_skips_unavailable(failures)
	await _check_reward_choice_numbering_and_socket_cue(failures)
	await _check_reward_choice_visible_text_is_compact(failures)
	await _check_reward_choice_input_metadata(failures)
	await _check_reward_flow_cue(failures)
	await _check_reward_overlay_challenge_goal_context(failures)
	_check_upgrade_taken_feedback_copy(failures)
	await _check_reward_claimed_toast_metadata(failures)
	_check_reward_claimed_next_action_pacing(failures)
	await _check_reward_gate_blocks_door_transition(failures)
	await _check_reward_economy_toast_metadata(failures)
	await _check_reward_reroll_blocked_gold_feedback(failures)
	await _check_reward_economy_decision_history(failures)
	await _check_upgrade_taken_toast_metadata(failures)
	_check_duplicate_reward_pending_guard(failures)
	_check_main_passes_upgrade_stacks(failures)
	_check_floor_reward_filter(failures)

	if failures.is_empty():
		print("Room upgrade smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_upgrade_db(failures: Array[String]) -> void:
	if not ResourceLoader.exists("res://scripts/progression/upgrade_db.gd"):
		failures.append("UpgradeDB script missing")
		return
	if UpgradeDBScript.UPGRADES.size() < 15:
		failures.append("upgrade pool should cover at least 15 MVP relics")
	var choices := UpgradeDBScript.roll_choices(123, 4, 1)
	if choices.size() != 3:
		failures.append("roll_choices should return 3 upgrades")
	var ids := {}
	for choice in choices:
		if not choice.has("id") or not choice.has("name") or not choice.has("desc"):
			failures.append("upgrade choice missing id/name/desc")
		ids[str(choice.get("id", ""))] = true
	if ids.size() != choices.size():
		failures.append("roll_choices should return unique upgrades")
	var upgrade_db := UpgradeDBScript.new()
	if not upgrade_db.has_method("reroll_room_choices"):
		failures.append("UpgradeDB should expose reroll_room_choices")
	else:
		var rerolled: Array = upgrade_db.call(
			"reroll_room_choices",
			123,
			4,
			1,
			RoomNode.RoomType.ELITE,
			choices)
		if rerolled.size() != 3:
			failures.append("reroll_room_choices should return three choices")
		if _overlaps(choices, rerolled):
			failures.append("reroll_room_choices should avoid previous options")
		if not _has_rare_plus(rerolled):
			failures.append("elite reroll choices should keep rare+ guarantee")

	var player := await _make_player()
	if not upgrade_db.has_method("upgrade_effect_preview"):
		failures.append("UpgradeDB should expose upgrade_effect_preview for reward choice previews")
	else:
		var power_preview := str(upgrade_db.call("upgrade_effect_preview", player, "power_rune"))
		if not power_preview.contains("Damage") or not power_preview.contains("x1.08 -> x1.20"):
			failures.append("power_rune preview should show projected damage multiplier")
		var dash_preview := str(upgrade_db.call("upgrade_effect_preview", player, "dash_spring"))
		if not dash_preview.contains("Dash CD") or not dash_preview.contains("1.20s -> 1.08s"):
			failures.append("dash_spring preview should show projected dash cooldown")
		var crit_preview := str(upgrade_db.call("upgrade_effect_preview", player, "precision_lens"))
		if not crit_preview.contains("Crit") or not crit_preview.contains("->"):
			failures.append("precision_lens preview should show projected crit chance")
		var tempo_preview := str(upgrade_db.call("upgrade_effect_preview", player, "tempo_glove"))
		if not tempo_preview.contains("Weapon CD") or not tempo_preview.contains("->"):
			failures.append("tempo_glove preview should show projected weapon cooldown multiplier")
		var weapon := player.current_weapon()
		if weapon != null:
			weapon.equip("cinder_orb")
			var split_preview := str(upgrade_db.call("upgrade_effect_preview", player, "split_socket"))
			if not split_preview.contains("Projectiles 2 -> 3"):
				failures.append("split_socket preview should show projected weapon projectile count")
	var before_hp := player.max_hp
	UpgradeDBScript.apply_upgrade(player, "vital_core")
	if player.max_hp <= before_hp:
		failures.append("vital_core should increase max_hp")
	var before_gold := player.gold
	UpgradeDBScript.apply_upgrade(player, "lucky_coin")
	if player.gold <= before_gold:
		failures.append("lucky_coin should add gold")
	var before_crit := player.crit_chance
	if not UpgradeDBScript.apply_upgrade(player, "precision_lens"):
		failures.append("precision_lens should apply")
	elif player.crit_chance <= before_crit:
		failures.append("precision_lens should increase crit chance")
	var before_weapon_cd_mult := float(player.call("weapon_cooldown_multiplier"))
	if not UpgradeDBScript.apply_upgrade(player, "tempo_glove"):
		failures.append("tempo_glove should apply")
	elif float(player.call("weapon_cooldown_multiplier")) >= before_weapon_cd_mult:
		failures.append("tempo_glove should reduce weapon cooldown multiplier")
	player.queue_free()
	await process_frame

func _check_upgrade_overlay(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame

	var choices := [
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP"},
		{"id": "power_rune", "name": "Power Rune", "desc": "+12% damage"},
		{"id": "swift_boots", "name": "Swift Boots", "desc": "+8 move speed"},
	]
	var chosen := {"id": ""}
	var skipped := {"gold": 0}
	var rerolled := {"cost": 0}
	overlay.upgrade_chosen.connect(func(id: String) -> void:
		chosen["id"] = id)
	if not _has_signal(overlay, "reward_skipped"):
		failures.append("upgrade overlay should expose reward_skipped signal")
	else:
		overlay.connect("reward_skipped", func(gold: int) -> void:
			skipped["gold"] = gold)
	if not _has_signal(overlay, "reward_reroll_requested"):
		failures.append("upgrade overlay should expose reward_reroll_requested signal")
	else:
		overlay.connect("reward_reroll_requested", func(cost: int) -> void:
			rerolled["cost"] = cost)
	overlay.call("show_upgrade_choices", choices, {}, true)
	await process_frame
	if not overlay.visible:
		failures.append("upgrade overlay should be visible")
	var scroll := overlay.find_child("ChoiceScroll", true, false) as ScrollContainer
	if scroll == null:
		failures.append("upgrade overlay should keep reward choices inside a scroll container")
	elif scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		failures.append("upgrade overlay choice scroll should allow vertical access")
	elif scroll.anchor_top > 0.1 or scroll.position.y > 240.0:
		failures.append("upgrade overlay choices should be anchored in the upper half of the screen")
	if _button_count(overlay) != 5:
		failures.append("upgrade overlay should create three upgrade buttons plus reroll and skip")
	var reroll := overlay.find_child("UpgradeReroll", true, false) as Button
	if reroll == null:
		failures.append("upgrade overlay should create a reroll button")
	else:
		if not reroll.text.contains("Reroll") or not reroll.text.contains("gold"):
			failures.append("reroll button should name the gold cost")
		reroll.emit_signal("pressed")
		await process_frame
		if int(rerolled["cost"]) <= 0:
			failures.append("reroll button should emit positive gold cost")
		var sfx := overlay.get_node_or_null("RewardDecisionSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("reward reroll should create decision sound placeholder")
		else:
			if str(sfx.get_meta("reward_sound_id", "")) != "reward_reroll":
				failures.append("reward reroll sound should expose reroll cue id")
			if str(sfx.get_meta("reward_decision", "")) != "reroll":
				failures.append("reward reroll sound should store decision metadata")
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("reward reroll sound should come from AudioCueDB")
			if sfx.stream == null:
				failures.append("reward reroll sound should assign an audio stream")
			if DisplayServer.get_name() == "headless" \
					and not bool(sfx.get_meta("headless_playback_skipped", false)):
				failures.append("reward reroll sound should skip playback in headless smoke")
	var skip := overlay.find_child("UpgradeSkip", true, false) as Button
	if skip == null:
		failures.append("upgrade overlay should create a skip-for-gold button")
	else:
		if not skip.text.contains("Skip") or not skip.text.contains("gold"):
			failures.append("skip reward button should name the gold payout")
		skip.emit_signal("pressed")
		await process_frame
		if int(skipped["gold"]) <= 0:
			failures.append("skip reward button should emit positive gold payout")
		var sfx := overlay.get_node_or_null("RewardDecisionSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("reward skip should create decision sound placeholder")
		else:
			if str(sfx.get_meta("reward_sound_id", "")) != "reward_skip":
				failures.append("reward skip sound should expose skip cue id")
			if str(sfx.get_meta("reward_decision", "")) != "skip":
				failures.append("reward skip sound should store decision metadata")
	var first := _first_button(overlay)
	if first == null:
		failures.append("upgrade overlay missing first button")
	else:
		first.emit_signal("pressed")
		await process_frame
		if str(chosen["id"]) != "vital_core":
			failures.append("upgrade overlay should emit chosen id")
		var sfx := overlay.get_node_or_null("RewardDecisionSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("reward choose should create decision sound placeholder")
		else:
			if str(sfx.get_meta("reward_sound_id", "")) != "reward_choose":
				failures.append("reward choose sound should expose choose cue id")
			if str(sfx.get_meta("reward_decision", "")) != "choose":
				failures.append("reward choose sound should store decision metadata")
			if str(sfx.get_meta("reward_upgrade_id", "")) != "vital_core":
				failures.append("reward choose sound should store chosen upgrade id")
	chosen["id"] = ""
	rerolled["cost"] = 0
	skipped["gold"] = 0
	overlay.call("show_upgrade_choices", choices, {}, true)
	await process_frame
	if not _press_key(overlay, KEY_2):
		failures.append("upgrade overlay should handle reward keyboard shortcuts")
	else:
		await process_frame
		if str(chosen["id"]) != "power_rune":
			failures.append("pressing 2 should choose the second reward")
		_press_key(overlay, KEY_R)
		await process_frame
		if int(rerolled["cost"]) <= 0:
			failures.append("pressing R should request a reward reroll")
		_press_key(overlay, KEY_S)
		await process_frame
		if int(skipped["gold"]) <= 0:
			failures.append("pressing S should skip reward for gold")
	chosen["id"] = ""
	overlay.show_upgrade_choices([
		{"id": "power_rune", "name": "Power Rune", "desc": "+12% damage", "max_stack": 1},
	], {"power_rune": 1})
	await process_frame
	if _press_key(overlay, KEY_1):
		await process_frame
		if str(chosen["id"]) != "":
			failures.append("reward hotkey should not choose a disabled upgrade")
	var blocked_subtitle := overlay.find_child("OverlaySubtitle", true, false) as Label
	if blocked_subtitle == null:
		failures.append("disabled reward hotkey should keep overlay subtitle available")
	else:
		if not blocked_subtitle.text.contains("Unavailable: Max stack"):
			failures.append("disabled reward hotkey should show the disabled reason")
		if str(blocked_subtitle.get_meta("hotkey_blocked_kind", "")) != "reward":
			failures.append("disabled reward hotkey should tag blocked reward metadata")
		if str(blocked_subtitle.get_meta("hotkey_blocked_reason", "")) != "Max stack":
			failures.append("disabled reward hotkey should tag max stack reason metadata")
	if str(overlay.get_meta("last_hotkey_blocked_reason", "")) != "Max stack":
		failures.append("disabled reward hotkey should remember last blocked reason")
	if not overlay.has_method("show_room_upgrade_choices"):
		failures.append("upgrade overlay should expose room-tier reward presentation")
	else:
		overlay.call("show_room_upgrade_choices", choices, RoomNode.RoomType.BOSS, {}, true)
		await process_frame
		var title := overlay.find_child("OverlayTitle", true, false) as Label
		var subtitle := overlay.find_child("OverlaySubtitle", true, false) as Label
		if title == null or not str(title.text).contains("BOSS REWARD"):
			failures.append("boss reward overlay should name the boss reward")
		if subtitle == null or not str(subtitle.text).contains("Rare+"):
			failures.append("boss reward overlay should show rare+ guarantee")
		var recap := overlay.find_child("RewardRecapLabel", true, false) as Label
		if recap == null:
			failures.append("room reward overlay should expose a reward recap label")
		elif not str(recap.text).contains("BOSS") or not str(recap.text).contains("1/3") \
				or not str(recap.text).contains("Skip"):
			failures.append("reward recap should show room tier, choice count, and skip option")
		overlay.show_room_upgrade_choices(choices, RoomNode.RoomType.ELITE, {}, false, [], "used")
		await process_frame
		recap = overlay.find_child("RewardRecapLabel", true, false) as Label
		reroll = overlay.find_child("UpgradeReroll", true, false) as Button
		if recap == null or not str(recap.text).contains("Reroll used"):
			failures.append("reward recap should explain when reroll was already used")
		if reroll == null or not str(reroll.text).contains("Reroll used"):
			failures.append("disabled reroll button should explain used state")
		rerolled["cost"] = 0
		_press_key(overlay, KEY_R)
		await process_frame
		if int(rerolled["cost"]) != 0:
			failures.append("disabled reroll hotkey should not request a reroll")
		if subtitle == null or not str(subtitle.text).contains("Unavailable: Reroll used"):
			failures.append("disabled reroll hotkey should explain why reroll is unavailable")
		elif str(subtitle.get_meta("hotkey_blocked_reason", "")) != "Reroll used":
			failures.append("disabled reroll hotkey should tag the reroll blocked reason")
		if str(overlay.get_meta("last_hotkey_blocked_reason", "")) != "Reroll used":
			failures.append("disabled reroll hotkey should remember last blocked reroll reason")
	overlay.queue_free()
	await process_frame

func _check_floor_reward_filter(failures: Array[String]) -> void:
	if not FloorController.rewards_room_type(RoomNode.RoomType.COMBAT):
		failures.append("combat rooms should reward upgrades")
	if not FloorController.rewards_room_type(RoomNode.RoomType.ELITE):
		failures.append("elite rooms should reward upgrades")
	if not FloorController.rewards_room_type(RoomNode.RoomType.MINIBOSS):
		failures.append("miniboss rooms should reward upgrades")
	if not FloorController.rewards_room_type(RoomNode.RoomType.BOSS):
		failures.append("boss rooms should reward upgrades after defeat")
	if not FloorController.rewards_room_type(RoomNode.RoomType.EVENT):
		failures.append("event trap rooms should reward upgrades")
	if not FloorController.rewards_room_type(RoomNode.RoomType.TREASURE):
		failures.append("treasure rooms should reward upgrades after opening chest")
	if not FloorController.rewards_room_type(RoomNode.RoomType.SECRET):
		failures.append("secret rooms should reward upgrades after opening cache")
	if FloorController.rewards_room_type(RoomNode.RoomType.SHOP):
		failures.append("shop rooms should not auto reward upgrades")

func _check_reward_claimed_toast_metadata(failures: Array[String]) -> void:
	var main_script: Script = load("res://scripts/main.gd")
	var main = main_script.new()
	var player := Player.new()
	player.name = "Player"
	player.record_upgrade("power_rune", "Power Rune", ["damage", "fire"])
	player.record_upgrade("dash_spring", "Dash Spring", ["dash", "mobility"])
	main.add_child(player)
	root.add_child(main)
	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 55
	room.type = RoomNode.RoomType.ELITE
	ctrl.current_room = room
	ctrl.cleared_rooms[room.id] = true
	main.add_child(ctrl)
	main._floor_ctrl = ctrl
	main._pending_reward_room_id = room.id
	main._pending_reward_room_type = room.type
	main.call("_show_reward_claimed_feedback")
	await process_frame
	var toast := main.get_node_or_null("RewardClaimedToast") as Label
	if toast == null:
		failures.append("reward claimed should create a toast")
	else:
		if int(toast.get_meta("room_id", -1)) != room.id:
			failures.append("reward claimed toast should store room_id metadata")
		if int(toast.get_meta("room_type", -1)) != RoomNode.RoomType.ELITE:
			failures.append("reward claimed toast should store room_type metadata")
		if str(toast.get_meta("room_type_name", "")) != "ELITE":
			failures.append("reward claimed toast should store room_type_name metadata")
		if str(toast.get_meta("objective_state", "")) != "reward_ready":
			failures.append("reward claimed toast should store objective_state metadata")
		if str(toast.get_meta("next_action_key", "")) != "reward":
			failures.append("reward claimed toast should store next_action_key metadata")
		if str(toast.get_meta("next_action_chain", "")) != "reward":
			failures.append("reward claimed toast should store pre-claim reward action chain")
		if not str(toast.text).contains("Power Arc:"):
			failures.append("reward claimed toast should show the run power arc")
		if int(toast.get_meta("run_power_pick_count", -1)) != 2:
			failures.append("reward claimed toast should store run power pick count")
		if str(toast.get_meta("run_power_tier", "")) != "Tier I":
			failures.append("reward claimed toast should store readable run power tier")
		var power_arc := str(toast.get_meta("run_power_arc", ""))
		if not power_arc.contains("2 picks") or not power_arc.contains("Tier I") \
				or not power_arc.contains("Fire Damage"):
			failures.append("reward claimed toast should store readable run power arc summary")
	var boss := RoomNode.new()
	boss.id = 56
	boss.type = RoomNode.RoomType.BOSS
	ctrl.current_room = boss
	ctrl.current_biome = {"id": "crystal_archive", "run_finale": true}
	ctrl.cleared_rooms[boss.id] = true
	main._pending_reward_room_id = boss.id
	main._pending_reward_room_type = boss.type
	main.call("_show_boss_reward_claimed_feedback")
	await process_frame
	var boss_toast := main.get_node_or_null("BossRewardClaimedToast") as Label
	if boss_toast == null:
		failures.append("boss reward claimed should create a toast")
	else:
		if not boss_toast.text.contains("Run complete portal ready"):
			failures.append("final boss reward claimed toast should point to run complete portal")
		if not bool(boss_toast.get_meta("run_finale", false)):
			failures.append("final boss reward claimed toast should store run_finale metadata")
		if str(boss_toast.get_meta("next_action_chain", "")) != "reward -> portal":
			failures.append("final boss reward claimed toast should store pre-claim reward chain")
		if str(boss_toast.get_meta("next_action_priority", "")) != "reward":
			failures.append("final boss reward claimed toast should prioritize reward before portal")
	main.queue_free()
	await process_frame

func _check_reward_claimed_next_action_pacing(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	if not ctrl.has_method("mark_room_reward_claimed"):
		failures.append("FloorController should expose mark_room_reward_claimed for post-reward pacing")
		ctrl.free()
		return
	var combat := RoomNode.new()
	combat.id = 81
	combat.type = RoomNode.RoomType.COMBAT
	ctrl.current_room = combat
	ctrl.cleared_rooms[combat.id] = true
	ctrl.call("mark_room_reward_claimed", combat.id)
	if str(ctrl.call("current_room_next_action_key")) != "door":
		failures.append("claimed combat reward should advance next action to door")
	if not str(ctrl.call("current_room_next_action")).contains("door"):
		failures.append("claimed combat reward should tell the player to move to a door")
	var combat_context: Dictionary = ctrl.call("current_room_objective_context")
	if bool(combat_context.get("reward_ready", true)):
		failures.append("claimed combat reward should clear reward_ready context")
	if str(combat_context.get("objective_state", "")) != "reward_claimed":
		failures.append("claimed combat reward should expose reward_claimed objective state")
	if str(combat_context.get("next_action_priority", "")) != "door":
		failures.append("claimed combat reward should prioritize doors after reward")

	var boss := RoomNode.new()
	boss.id = 82
	boss.type = RoomNode.RoomType.BOSS
	ctrl.current_room = boss
	ctrl.cleared_rooms[boss.id] = true
	if str(ctrl.call("current_room_next_action_chain")) != "reward -> portal":
		failures.append("uncleared boss reward should expose reward -> portal chain before claim")
	ctrl.call("mark_room_reward_claimed", boss.id)
	if str(ctrl.call("current_room_next_action_key")) != "portal":
		failures.append("claimed boss reward should advance next action to portal")
	if str(ctrl.call("current_room_next_action_chain")) != "portal":
		failures.append("claimed boss reward chain should collapse to portal")
	if str(ctrl.call("current_room_next_action_priority")) != "portal":
		failures.append("claimed boss reward should prioritize portal")
	ctrl.free()

func _check_reward_overlay_challenge_goal_context(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var choices := [
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP"},
		{"id": "power_rune", "name": "Power Rune", "desc": "+12% damage"},
		{"id": "swift_boots", "name": "Swift Boots", "desc": "+8 move speed"},
	]
	overlay.show_room_upgrade_choices(
		choices,
		RoomNode.RoomType.COMBAT,
		{},
		true,
		[],
		"available",
		"",
		{},
		"",
		"",
		"",
		"Glass Edges: Enemies scale +12%",
		"Next power tier after 1 pick",
		{},
		"Goals: Elite Hunt 1/1 | Shop Buy 0/1",
		"Locked 1/2 goals")
	await process_frame
	var goal := overlay.find_child("RewardChallengeGoalLabel", true, false) as Label
	if goal == null:
		failures.append("reward overlay should expose daily challenge goal progress")
	else:
		if not goal.visible or not goal.text.contains("Elite Hunt 1/1") \
				or not goal.text.contains("Locked 1/2 goals"):
			failures.append("reward overlay challenge goal label should show progress and bonus status")
		if str(goal.get_meta("run_goal_summary", "")) != "Goals: Elite Hunt 1/1 | Shop Buy 0/1":
			failures.append("reward overlay challenge goal label should store raw goal summary metadata")
		if str(goal.get_meta("challenge_bonus_status", "")) != "Locked 1/2 goals":
			failures.append("reward overlay challenge goal label should store bonus status metadata")
	overlay.queue_free()
	await process_frame

func _check_reward_gate_blocks_door_transition(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	root.add_child(ctrl)
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame

	var grid := _reward_gate_transition_grid()
	var renderer := RoomRenderer.new()
	ctrl.add_child(renderer)
	renderer.setup(grid, [], null, player, RoomNode.RoomType.COMBAT)
	renderer.is_cleared = true

	var combat := RoomNode.new()
	combat.id = 0
	combat.type = RoomNode.RoomType.COMBAT
	combat.door_map = {RoomStamper.Dir.NORTH: 1}
	var treasure := RoomNode.new()
	treasure.id = 1
	treasure.type = RoomNode.RoomType.TREASURE
	treasure.door_map = {RoomStamper.Dir.SOUTH: 0}
	ctrl.rooms = [combat, treasure]
	ctrl.current_room = combat
	ctrl.cleared_rooms[combat.id] = true
	ctrl._grid = grid
	ctrl._renderer = renderer
	ctrl._player = player
	ctrl.call("_show_door_markers", combat)
	await process_frame
	var reward_marker := _first_door_marker(renderer)
	if reward_marker == null:
		failures.append("reward-gated cleared room should still show door markers")
	else:
		if str(reward_marker.get_meta("gate_state", "")) != "reward_locked":
			failures.append("unclaimed reward door marker should expose reward_locked gate state")
		if str(reward_marker.get_meta("next_action_key", "")) != "reward":
			failures.append("unclaimed reward door marker should point next action to reward")
		if not _node_has_label_text(reward_marker, "REWARD"):
			failures.append("unclaimed reward door marker should tell player to pick reward first")
	ctrl.call("mark_room_reward_claimed", combat.id)
	await process_frame
	reward_marker = _first_door_marker(renderer)
	if reward_marker == null:
		failures.append("claimed reward room should keep route door markers visible")
	else:
		if str(reward_marker.get_meta("gate_state", "")) == "reward_locked":
			failures.append("claimed reward door marker should clear reward_locked gate state")
		if str(reward_marker.get_meta("route_hint", "")) == "":
			failures.append("claimed reward door marker should preserve route hint metadata")
		if _node_has_label_text(reward_marker, "MAIN") \
				or _node_has_label_text(reward_marker, "SIDE"):
			failures.append("claimed reward door marker should keep route role out of visible playfield text")
	ctrl.reward_claimed_rooms.erase(combat.id)
	ctrl.call("_show_door_markers", combat)
	await process_frame

	var door_tiles := RoomStamper.door_tiles(grid, RoomStamper.Dir.NORTH)
	if door_tiles.is_empty():
		failures.append("reward gate transition smoke should have a north door")
	else:
		player.global_position = renderer.tile_to_world(door_tiles[0])
		ctrl.call("_physics_process", 0.1)
		if bool(ctrl.get("_transitioning")) or ctrl.current_room != combat:
			failures.append("unclaimed room reward should block door transition")
		var blocked_hint := renderer.get_node_or_null("RewardDoorBlockedHint") as Label
		if blocked_hint == null:
			failures.append("unclaimed room reward should explain blocked door transition")
		else:
			if not blocked_hint.text.contains("Pick reward"):
				failures.append("blocked reward door hint should tell the player to pick reward")
			if str(blocked_hint.get_meta("blocked_reason", "")) != "reward_unclaimed":
				failures.append("blocked reward door hint should store reward_unclaimed reason metadata")
			if int(blocked_hint.get_meta("room_id", -1)) != combat.id:
				failures.append("blocked reward door hint should store current room id")
		var blocked_sfx := renderer.get_node_or_null("RewardDoorBlockedSfx") as AudioStreamPlayer
		if blocked_sfx == null:
			failures.append("blocked reward door should create objective blocked sound placeholder")
		else:
			if str(blocked_sfx.get_meta("reward_blocked_reason", "")) != "reward_unclaimed":
				failures.append("blocked reward door sound should store reward_unclaimed reason")
			if int(blocked_sfx.get_meta("room_id", -1)) != combat.id:
				failures.append("blocked reward door sound should store current room id")
			if str(blocked_sfx.get_meta("next_action_key", "")) != "reward":
				failures.append("blocked reward door sound should point next action to reward")
			if str(blocked_sfx.get_meta("reward_blocked_sound_id", "")) != "objective_blocked":
				failures.append("blocked reward door sound should use objective_blocked cue")
			if str(blocked_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("blocked reward door sound should come from AudioCueDB")
			if str(blocked_sfx.get_meta("audio_cue_kind", "")) != "objective_blocked":
				failures.append("blocked reward door sound should expose objective_blocked cue kind")
			if blocked_sfx.stream == null:
				failures.append("blocked reward door sound should assign placeholder stream")
			if DisplayServer.get_name() == "headless" \
					and not bool(blocked_sfx.get_meta("headless_playback_skipped", false)):
				failures.append("blocked reward door sound should skip playback in headless smoke")
		var claimed_door_world := renderer.tile_to_world(door_tiles[0])
		player.global_position = renderer.tile_to_world(Vector2i(3, 3))
		ctrl.call("mark_room_reward_claimed", combat.id)
		var stale_hint := renderer.get_node_or_null("RewardDoorBlockedHint") as Label
		if stale_hint != null and stale_hint.visible:
			failures.append("claiming room reward should clear stale blocked-door hint")
		await process_frame
		var open_hint := renderer.get_node_or_null("RewardDoorOpenHint") as Label
		if open_hint == null:
			failures.append("claiming room reward should show doors-open feedback")
		else:
			if not open_hint.text.contains("Doors open"):
				failures.append("doors-open feedback should tell the player doors are open")
			if int(open_hint.get_meta("room_id", -1)) != combat.id:
				failures.append("doors-open feedback should store current room id")
			if str(open_hint.get_meta("objective_state", "")) != "reward_claimed":
				failures.append("doors-open feedback should store reward_claimed state")
			if str(open_hint.get_meta("next_action_key", "")) != "door":
				failures.append("doors-open feedback should point next action to door")
		var open_sfx := renderer.get_node_or_null("RewardDoorOpenSfx") as AudioStreamPlayer
		if open_sfx == null:
			failures.append("claiming room reward should create doors-open sound placeholder")
		else:
			if str(open_sfx.get_meta("reward_open_reason", "")) != "reward_claimed":
				failures.append("doors-open sound should store reward_claimed reason")
			if int(open_sfx.get_meta("room_id", -1)) != combat.id:
				failures.append("doors-open sound should store current room id")
			if str(open_sfx.get_meta("next_action_key", "")) != "door":
				failures.append("doors-open sound should point next action to door")
			if str(open_sfx.get_meta("reward_open_sound_id", "")) != "objective_complete":
				failures.append("doors-open sound should use objective_complete cue")
			if str(open_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("doors-open sound should come from AudioCueDB")
			if str(open_sfx.get_meta("audio_cue_kind", "")) != "objective_complete":
				failures.append("doors-open sound should expose objective_complete cue kind")
			if open_sfx.stream == null:
				failures.append("doors-open sound should assign placeholder stream")
			if DisplayServer.get_name() == "headless" \
					and not bool(open_sfx.get_meta("headless_playback_skipped", false)):
				failures.append("doors-open sound should skip playback in headless smoke")
		player.global_position = claimed_door_world
		ctrl.call("_physics_process", 0.1)
		await process_frame
		await process_frame
		if ctrl.current_room != treasure:
			failures.append("claimed room reward should allow door transition to target room")
		if bool(ctrl.get("_transitioning")):
			failures.append("reward-claimed door transition should finish deferred enter-room step")
		if not ctrl.visited_rooms.has(treasure.id):
			failures.append("reward-claimed door transition should mark target room visited")

	ctrl.queue_free()
	player.queue_free()
	await process_frame

func _first_door_marker(parent: Node) -> Node:
	for child in parent.get_children():
		if child is DoorMarker:
			return child
	return null

func _node_has_label_text(parent: Node, text: String) -> bool:
	for child in parent.find_children("*", "Label", true, false):
		var label := child as Label
		if label != null and label.text.contains(text):
			return true
	return false

func _reward_gate_transition_grid() -> TileGrid:
	var grid := TileGrid.new(7, 7, TileGrid.Tile.FLOOR)
	for x in grid.width:
		grid.set_tile(x, 0, TileGrid.Tile.WALL)
		grid.set_tile(x, grid.height - 1, TileGrid.Tile.WALL)
	for y in grid.height:
		grid.set_tile(0, y, TileGrid.Tile.WALL)
		grid.set_tile(grid.width - 1, y, TileGrid.Tile.WALL)
	grid.set_tile(3, 0, TileGrid.Tile.DOOR)
	grid.set_tile(4, 0, TileGrid.Tile.DOOR)
	return grid

func _check_upgrade_taken_toast_metadata(failures: Array[String]) -> void:
	var main_script: Script = load("res://scripts/main.gd")
	var main = main_script.new()
	var player := Player.new()
	player.name = "Player"
	main.add_child(player)
	root.add_child(main)
	await process_frame
	if _method_arg_count(main, "_show_upgrade_taken_feedback") < 4:
		failures.append("upgrade taken feedback should accept chosen upgrade context metadata")
		main.queue_free()
		await process_frame
		return
	main.call("_show_upgrade_taken_feedback",
		"Power Rune",
		1,
		["damage", "core"],
		{
			"upgrade_id": "power_rune",
			"effect_preview": "Damage x1.08 -> x1.20",
			"decision_reason": "Best Fit / Preview",
			"room_id": 55,
			"room_type": RoomNode.RoomType.ELITE,
			"room_type_name": "ELITE",
		})
	await process_frame
	var toast := main.get_node_or_null("UpgradeTakenToast") as Label
	if toast == null:
		failures.append("upgrade taken should create a toast")
	else:
		if str(toast.get_meta("upgrade_id", "")) != "power_rune":
			failures.append("upgrade taken toast should store upgrade id metadata")
		if str(toast.get_meta("upgrade_effect_preview", "")) != "Damage x1.08 -> x1.20":
			failures.append("upgrade taken toast should store effect preview metadata")
		if str(toast.get_meta("upgrade_decision_reason", "")) != "Best Fit / Preview":
			failures.append("upgrade taken toast should store decision reason metadata")
		if int(toast.get_meta("reward_room_id", -1)) != 55:
			failures.append("upgrade taken toast should store reward room id metadata")
		if int(toast.get_meta("reward_room_type", -1)) != RoomNode.RoomType.ELITE:
			failures.append("upgrade taken toast should store reward room type metadata")
		if str(toast.get_meta("reward_room_type_name", "")) != "ELITE":
			failures.append("upgrade taken toast should store reward room type name metadata")
		if not toast.text.contains("Preview: Damage x1.08 -> x1.20") \
				or not toast.text.contains("Room: ELITE") \
				or not toast.text.contains("Reason: Best Fit / Preview"):
			failures.append("upgrade taken toast should summarize preview, decision reason, and room context")
	main.queue_free()
	await process_frame

func _check_reward_economy_toast_metadata(failures: Array[String]) -> void:
	var main_script: Script = load("res://scripts/main.gd")
	var main = main_script.new()
	var player := Player.new()
	player.name = "Player"
	main.add_child(player)
	root.add_child(main)
	await process_frame
	main.call("_show_reward_economy_feedback", "Reroll", -12)
	await process_frame
	var toast := main.get_node_or_null("RewardEconomyToast") as Label
	if toast == null:
		failures.append("reward economy feedback should create a toast")
	else:
		if not toast.text.contains("Reroll") or not toast.text.contains("-12 Gold"):
			failures.append("reward economy toast should summarize reason and signed gold delta")
		if str(toast.get_meta("reward_economy_reason", "")) != "Reroll":
			failures.append("reward economy toast should store reason metadata")
		if int(toast.get_meta("reward_gold_delta", 0)) != -12:
			failures.append("reward economy toast should store signed gold delta metadata")
		if str(toast.get_meta("reward_economy_kind", "")) != "spend":
			failures.append("reward economy toast should classify negative deltas as spend")
	main.queue_free()
	await process_frame

func _check_reward_reroll_blocked_gold_feedback(failures: Array[String]) -> void:
	var main_script: Script = load("res://scripts/main.gd")
	var main = main_script.new()
	var player := Player.new()
	player.name = "Player"
	player.gold = 3
	main.add_child(player)
	root.add_child(main)
	await process_frame
	var pending: Array[Dictionary] = [{"id": "power_rune"}]
	main._pending_upgrades = pending
	main._reward_rerolled = false
	main._reward_reroll_count = 0
	var before_gold := player.gold
	main.call("_on_upgrade_reward_reroll_requested", 12)
	await process_frame
	if player.gold != before_gold:
		failures.append("blocked reward reroll should not spend gold")
	if bool(main.get("_reward_rerolled")):
		failures.append("blocked reward reroll should not mark reroll as used")
	if int(main.get("_reward_reroll_count")) != 0:
		failures.append("blocked reward reroll should not increment reroll count")
	var toast := main.get_node_or_null("RewardEconomyToast") as Label
	if toast == null:
		failures.append("blocked reward reroll should show economy feedback")
	else:
		if not toast.text.contains("Reroll needs 9 Gold"):
			failures.append("blocked reward reroll should explain missing gold")
		if toast.text.contains("+0") or toast.text.contains("-0"):
			failures.append("blocked reward reroll feedback should not show zero gold delta")
		if str(toast.get_meta("reward_economy_reason", "")) != "Reroll needs 9 Gold":
			failures.append("blocked reward reroll should store readable reason metadata")
		if int(toast.get_meta("reward_gold_delta", -99)) != 0:
			failures.append("blocked reward reroll should store zero signed delta metadata")
		if int(toast.get_meta("reward_gold_missing", 0)) != 9:
			failures.append("blocked reward reroll should store missing gold metadata")
		if str(toast.get_meta("reward_economy_kind", "")) != "blocked":
			failures.append("blocked reward reroll should classify feedback as blocked")
	var history := str(player.call("room_decision_history_summary"))
	if not history.contains("Reward (Blocked: Need 9 Gold)"):
		failures.append("blocked reward reroll should record room decision history")
	main.queue_free()
	await process_frame

func _check_reward_economy_decision_history(failures: Array[String]) -> void:
	var main_script: Script = load("res://scripts/main.gd")
	var main = main_script.new()
	var player := Player.new()
	player.name = "Player"
	player.gold = 30
	main.add_child(player)
	root.add_child(main)
	var overlay := RunOverlay.new()
	main.add_child(overlay)
	main._overlay = overlay
	await process_frame

	main.call("_on_upgrade_reward_skipped", 8)
	await process_frame
	var skip_history := str(player.call("room_decision_history_summary"))
	if not skip_history.contains("Reward (Skipped +8 Gold)"):
		failures.append("skipping reward should record reward economy decision history")

	var pending: Array[Dictionary] = [{"id": "power_rune"}]
	main._pending_upgrades = pending
	main._reward_rerolled = false
	main._reward_reroll_count = 0
	main.call("_on_upgrade_reward_reroll_requested", 12)
	await process_frame
	var reroll_history := str(player.call("room_decision_history_summary"))
	if not reroll_history.contains("Reward (Rerolled -12 Gold)"):
		failures.append("rerolling reward should record reward economy decision history")
	main.queue_free()
	await process_frame

func _check_duplicate_reward_pending_guard(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 42
	room.type = RoomNode.RoomType.COMBAT
	var counts := {"reward": 0, "objective": 0}
	ctrl.room_reward_pending.connect(func(_room_id: int, _room_type: int) -> void:
		counts["reward"] = int(counts["reward"]) + 1)
	ctrl.room_objective_completed.connect(func(_text: String) -> void:
		counts["objective"] = int(counts["objective"]) + 1)
	ctrl.call("_on_room_cleared", room)
	ctrl.call("_on_room_cleared", room)
	if int(counts["reward"]) != 1:
		failures.append("cleared room should not emit duplicate reward pending events")
	if int(counts["objective"]) != 1:
		failures.append("cleared room should not emit duplicate objective-complete events")
	ctrl.free()

func _check_upgrade_overlay_stack_preview(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame

	overlay.show_upgrade_choices([
		{"id": "power_rune", "name": "Power Rune", "desc": "+12% damage", "rarity": "rare"},
		{"id": "dash_spring", "name": "Dash Spring", "desc": "-10% dash cooldown", "rarity": "rare"},
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP", "rarity": "common"},
	], {"power_rune": 2})
	await process_frame

	var power := overlay.find_child("Upgrade_power_rune", true, false) as Button
	if power == null:
		failures.append("upgrade stack preview should keep named upgrade button")
	elif not str(power.text).contains("Owned x2") or not str(power.text).contains("Next x3"):
		failures.append("upgrade stack preview should show owned and next stack")
	var max_preview := str(overlay.call(
		"_stack_preview",
		{"id": "power_rune", "max_stack": 3},
		{"power_rune": 3}))
	if not max_preview.contains("MAX"):
		failures.append("maxed upgrade stack preview should read MAX")
	overlay.show_upgrade_choices([
		{"id": "power_rune", "name": "Power Rune", "desc": "+12% damage", "rarity": "rare", "max_stack": 3},
	], {"power_rune": 3})
	await process_frame
	power = overlay.find_child("Upgrade_power_rune", true, false) as Button
	if power == null:
		failures.append("max stack preview should keep named upgrade button")
	elif not str(power.text).contains("MAX") or not power.disabled:
		failures.append("maxed upgrade should show MAX and disable selection")
	elif str(power.get_meta("disabled_reason", "")) != "Max stack" \
			or not str(power.text).contains("Unavailable: Max stack"):
		failures.append("maxed upgrade should expose explicit Max stack disabled reason")
	overlay.show_upgrade_choices([
		{
			"id": "aegis_socket",
			"name": "Aegis Socket",
			"desc": "+25% shield duration",
			"rarity": "rare",
			"disabled": true,
			"disabled_reason": "Sockets full",
		},
	], {})
	await process_frame
	var socket := overlay.find_child("Upgrade_aegis_socket", true, false) as Button
	if socket == null:
		failures.append("disabled upgrade preview should keep named upgrade button")
	elif not socket.disabled or not str(socket.text).contains("Sockets full"):
		failures.append("unavailable upgrade choices should disable and show reason")

	overlay.queue_free()
	await process_frame

func _check_reward_choice_set_progress_hint(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var choices := [
		{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage", "rarity": "rare", "tags": ["damage", "fire", "element"]},
		{"id": "dash_spring", "name": "Dash Spring", "desc": "-10% dash cooldown", "rarity": "rare", "tags": ["mobility", "dash"]},
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP", "rarity": "common", "tags": ["survival", "hp"]},
	]
	overlay.callv("show_room_upgrade_choices", [
		choices,
		RoomNode.RoomType.ELITE,
		{},
		false,
		["damage", "fire"],
		"",
		"Power Rune -> Precision Lens",
		{"ember_rune": "Fire damage x1.15 -> x1.30"},
		"",
		"Fire Damage",
		"2 picks | Tier I | Fire Damage | Damage / Fire",
		"",
		"Next: Tier II in 1 pick",
		{"damage": 2, "mobility": 1},
	])
	await process_frame
	var ember := overlay.find_child("Upgrade_ember_rune", true, false) as Button
	if ember == null:
		failures.append("set progress hint should keep named ember button")
	else:
		if not str(ember.text).contains("Set: Damage 2/3 -> 3/3 ready"):
			failures.append("reward choice should show set progress when a pick completes a set bonus")
		if str(ember.get_meta("set_progress_hint", "")) != "Damage 2/3 -> 3/3 ready":
			failures.append("reward choice should store readable set progress hint")
		if str(ember.get_meta("set_progress_tag", "")) != "damage":
			failures.append("reward choice should store set progress tag")
		if int(ember.get_meta("set_progress_before", 0)) != 2 \
				or int(ember.get_meta("set_progress_after", 0)) != 3:
			failures.append("reward choice should store before/after set progress counts")
		if not bool(ember.get_meta("set_progress_ready", false)):
			failures.append("reward choice should flag a ready set completion")
		if str(ember.get_meta("set_bonus_effect", "")) != "Damage x3 +8% dmg":
			failures.append("reward choice should store the ready set bonus effect")
		if not str(ember.text).contains("Bonus: Damage x3 +8% dmg"):
			failures.append("reward choice should show the ready set bonus effect")
		if not str(ember.tooltip_text).contains("Set Progress: Damage 2/3 -> 3/3 ready"):
			failures.append("reward choice tooltip should include set progress")
		if not str(ember.tooltip_text).contains("Set Bonus: Damage x3 +8% dmg"):
			failures.append("reward choice tooltip should include ready set bonus effect")
		ember.emit_signal("pressed")
		await process_frame
		var context: Dictionary = overlay.get_meta("last_reward_decision_context", {})
		if str(context.get("set_progress_hint", "")) != "Damage 2/3 -> 3/3 ready":
			failures.append("reward decision context should preserve set progress hint")
		if str(context.get("set_bonus_effect", "")) != "Damage x3 +8% dmg":
			failures.append("reward decision context should preserve ready set bonus effect")
		var sfx := overlay.get_node_or_null("RewardDecisionSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("reward choose with set progress should create decision sound placeholder")
		elif str(sfx.get_meta("reward_set_progress_hint", "")) != "Damage 2/3 -> 3/3 ready":
			failures.append("reward choose sound should store set progress hint")
		elif str(sfx.get_meta("reward_set_bonus_effect", "")) != "Damage x3 +8% dmg":
			failures.append("reward choose sound should store set bonus effect")
	var dash := overlay.find_child("Upgrade_dash_spring", true, false) as Button
	if dash != null and not str(dash.get_meta("set_progress_hint", "")).contains("Mobility 1/3 -> 2/3"):
		failures.append("non-completing set progress should still show next set step")
	elif dash != null:
		if str(dash.get_meta("set_bonus_next_effect", "")) != "Mobility x3 -8% dash CD":
			failures.append("non-completing set progress should store the next set bonus effect")
		if not str(dash.text).contains("Next: Mobility x3 -8% dash CD"):
			failures.append("non-completing set progress should preview the next set bonus effect")
		if not str(dash.tooltip_text).contains("Set Bonus Next: Mobility x3 -8% dash CD"):
			failures.append("non-completing set progress tooltip should include the next set bonus effect")
	overlay.callv("show_room_upgrade_choices", [
		[
			{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage", "rarity": "rare", "tags": ["damage", "fire", "element"]},
			{"id": "split_socket", "name": "Split Socket", "desc": "+1 projectile", "rarity": "epic", "tags": ["projectile", "socket"]},
			{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP", "rarity": "common", "tags": ["survival", "hp"]},
		],
		RoomNode.RoomType.ELITE,
		{},
		false,
		[],
		"",
		"Power Rune -> Precision Lens",
		{},
		"",
		"",
		"2 picks | Tier I | Damage",
		"",
		"Next: Tier II in 1 pick",
		{"damage": 2},
	])
	await process_frame
	ember = overlay.find_child("Upgrade_ember_rune", true, false) as Button
	var split := overlay.find_child("Upgrade_split_socket", true, false) as Button
	if ember == null or split == null:
		failures.append("set-ready best-fit check should keep reward buttons")
	else:
		if not bool(ember.get_meta("best_fit", false)) \
				or not str(ember.text).contains("Best Fit"):
			failures.append("set-ready reward should become Best Fit over unrelated epic choices")
		if int(ember.get_meta("fit_score", 0)) <= int(split.get_meta("fit_score", 0)):
			failures.append("set-ready reward should score above unrelated epic choices")
		if not str(ember.get_meta("fit_reasons", "")).contains("Set ready"):
			failures.append("set-ready reward should expose Set ready fit reason")
		if bool(split.get_meta("best_fit", false)):
			failures.append("unrelated epic should not keep Best Fit over set-ready reward")
	overlay.queue_free()
	await process_frame

func _check_upgrade_overlay_synergy_reason(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.show_upgrade_choices([
		{"id": "power_rune", "name": "Power Rune", "desc": "+12% damage", "rarity": "rare", "tags": ["damage", "core"]},
		{"id": "dash_spring", "name": "Dash Spring", "desc": "-10% dash cooldown", "rarity": "rare", "tags": ["mobility", "dash"]},
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP", "rarity": "common", "tags": ["survival", "hp"]},
	], {}, false, ["damage", "fire"], "", "", {}, "", "Fire Damage")
	await process_frame
	var power := overlay.find_child("Upgrade_power_rune", true, false) as Button
	if power == null:
		failures.append("synergy preview should keep named upgrade button")
	elif not str(power.text).contains("Synergy:") or not str(power.text).contains("Damage"):
		failures.append("build-matching upgrade should explain synergy reason")
	elif not str(power.text).contains("Fits Fire Damage"):
		failures.append("build-matching upgrade should explain matching build archetype")
	elif not str(power.text).contains("Recommended"):
		failures.append("build-matching upgrade should show a recommendation cue")
	elif not str(power.text).contains("Fit:") or not str(power.text).contains("Build match"):
		failures.append("build-matching upgrade should show readable fit score reasons")
	elif not str(power.text).contains("Best Fit"):
		failures.append("highest-fit upgrade should show Best Fit badge")
	if power != null and not bool(power.get_meta("build_match", false)):
		failures.append("build-matching upgrade should keep build_match metadata")
	if power != null and not str(power.get_meta("synergy_reason", "")).contains("Fits Fire Damage"):
		failures.append("build-matching upgrade should store synergy reason metadata")
	if power != null and str(power.get_meta("recommendation", "")) == "":
		failures.append("build-matching upgrade should store recommendation metadata")
	if power != null and int(power.get_meta("fit_score", 0)) < 60:
		failures.append("build-matching upgrade should store a strong fit score")
	if power != null and not str(power.get_meta("fit_reasons", "")).contains("Build match"):
		failures.append("build-matching upgrade should store readable fit reasons")
	if power != null and not bool(power.get_meta("best_fit", false)):
		failures.append("highest-fit upgrade should store best_fit metadata")
	overlay.queue_free()
	await process_frame

func _check_upgrade_best_fit_skips_unavailable(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.show_upgrade_choices([
		{
			"id": "locked_mythic",
			"name": "Locked Mythic",
			"desc": "Strong but unavailable",
			"rarity": "mythic",
			"tags": ["damage", "fire"],
			"disabled": true,
			"disabled_reason": "Class locked",
		},
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP", "rarity": "common"},
		{"id": "swift_boots", "name": "Swift Boots", "desc": "+8 move speed", "rarity": "common"},
	], {}, false, ["damage", "fire"])
	await process_frame
	var locked := overlay.find_child("Upgrade_locked_mythic", true, false) as Button
	var vital := overlay.find_child("Upgrade_vital_core", true, false) as Button
	if locked == null:
		failures.append("best-fit unavailable check should keep locked upgrade button")
	elif not locked.disabled:
		failures.append("locked high-fit upgrade should be disabled")
	elif str(locked.text).contains("Best Fit") or bool(locked.get_meta("best_fit", false)):
		failures.append("disabled upgrade should not receive Best Fit badge")
	if vital == null:
		failures.append("best-fit unavailable check should keep fallback upgrade button")
	elif not str(vital.text).contains("Best Fit") or not bool(vital.get_meta("best_fit", false)):
		failures.append("best available upgrade should receive Best Fit badge")

	overlay.show_upgrade_choices([
		{
			"id": "locked_fire",
			"name": "Locked Fire",
			"desc": "Unavailable",
			"rarity": "mythic",
			"tags": ["damage", "fire"],
			"disabled": true,
			"disabled_reason": "Class locked",
		},
		{
			"id": "locked_dash",
			"name": "Locked Dash",
			"desc": "Unavailable",
			"rarity": "rare",
			"tags": ["dash"],
			"disabled": true,
			"disabled_reason": "Already owned",
		},
	], {}, false, ["damage", "fire"])
	await process_frame
	if _has_upgrade_best_fit(overlay):
		failures.append("all-disabled upgrades should not show any Best Fit badge")
	overlay.queue_free()
	await process_frame

func _check_reward_history_cue(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var choices := [
		{"id": "power_rune", "name": "Power Rune", "desc": "+12% damage"},
		{"id": "dash_spring", "name": "Dash Spring", "desc": "-10% dash cooldown"},
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP"},
	]
	overlay.callv("show_room_upgrade_choices", [
		choices,
		RoomNode.RoomType.COMBAT,
		{},
		false,
		[],
		"",
		"Power Rune -> Dash Spring",
	])
	await process_frame
	var cue := overlay.find_child("RewardHistoryCueLabel", true, false) as Label
	if cue == null:
		failures.append("reward overlay should show a last-picked history cue")
	else:
		if not str(cue.text).contains("Last pick: Dash Spring"):
			failures.append("reward history cue should show the most recent upgrade")
		if str(cue.get_meta("full_history", "")) != "Power Rune -> Dash Spring":
			failures.append("reward history cue should keep full history metadata")
	overlay.show_room_upgrade_choices(choices, RoomNode.RoomType.COMBAT)
	await process_frame
	cue = overlay.find_child("RewardHistoryCueLabel", true, false) as Label
	if cue != null:
		failures.append("empty reward history should not show last-picked cue")
	overlay.callv("show_room_upgrade_choices", [
		choices,
		RoomNode.RoomType.COMBAT,
		{},
		false,
		[],
		"",
		"",
		{"power_rune": "Damage x1.00 -> x1.12"},
	])
	await process_frame
	var power := overlay.find_child("Upgrade_power_rune", true, false) as Button
	if power == null:
		failures.append("reward effect preview should keep named power upgrade button")
	elif not str(power.text).contains("Preview: Damage x1.00 -> x1.12") \
			or str(power.get_meta("effect_preview", "")) != "Damage x1.00 -> x1.12":
		failures.append("reward overlay should show and store upgrade effect preview")
	overlay.queue_free()
	await process_frame

func _check_reward_decision_context(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var choices := [
		{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage", "tags": ["damage", "fire"]},
		{"id": "dash_spring", "name": "Dash Spring", "desc": "-10% dash cooldown", "tags": ["dash"]},
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP", "tags": ["survival"]},
	]
	overlay.callv("show_room_upgrade_choices", [
		choices,
		RoomNode.RoomType.ELITE,
		{},
		false,
		["damage", "fire"],
		"",
		"Power Rune -> Ember Rune",
		{"ember_rune": "Fire damage x1.15 -> x1.30"},
		"Sockets 2/3 | Runes Fire x1",
		"Fire Damage",
		"3 picks | Tier II | Fire Damage | Damage / Fire",
		"Glass Edges: Enemies scale +12%",
		"Next: Tier III in 3 picks",
	])
	await process_frame
	var power_arc := overlay.find_child("RewardPowerArcLabel", true, false) as Label
	if power_arc == null:
		failures.append("reward overlay should show current run power arc")
	elif not str(power_arc.text).contains("Power Arc: 3 picks | Tier II | Fire Damage") \
			or str(power_arc.get_meta("run_power_arc", "")) != "3 picks | Tier II | Fire Damage | Damage / Fire":
		failures.append("reward power arc cue should name and store current run power arc")
	var next_milestone := overlay.find_child("RewardNextMilestoneLabel", true, false) as Label
	if next_milestone == null:
		failures.append("reward overlay should show the next power milestone")
	elif not str(next_milestone.text).contains("Next: Tier III in 3 picks") \
			or str(next_milestone.get_meta("next_power_milestone", "")) != "Next: Tier III in 3 picks":
		failures.append("reward next milestone cue should name and store remaining picks")
	var archetype := overlay.find_child("RewardBuildArchetypeLabel", true, false) as Label
	if archetype == null:
		failures.append("reward overlay should show current build archetype")
	elif not str(archetype.text).contains("Archetype: Fire Damage") \
			or str(archetype.get_meta("build_archetype", "")) != "Fire Damage":
		failures.append("reward archetype cue should name and store current build archetype")
	var challenge := overlay.find_child("RewardChallengeLabel", true, false) as Label
	if challenge == null:
		failures.append("reward overlay should show active daily challenge")
	elif not str(challenge.text).contains("Challenge: Glass Edges") \
			or str(challenge.get_meta("run_modifier", "")) != "Glass Edges: Enemies scale +12%":
		failures.append("reward challenge cue should name and store active daily challenge")
	var ember := overlay.find_child("Upgrade_ember_rune", true, false) as Button
	if ember == null:
		failures.append("reward decision context should keep named ember button")
	else:
		ember.emit_signal("pressed")
		await process_frame
		var sfx := overlay.get_node_or_null("RewardDecisionSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("reward choose context should create decision sound placeholder")
		else:
			if int(sfx.get_meta("reward_choice_index", 0)) != 1:
				failures.append("reward choose sound should store 1-based choice index")
			if str(sfx.get_meta("reward_choice_rarity", "")) == "":
				failures.append("reward choose sound should store chosen rarity")
			if not str(sfx.get_meta("reward_synergy_reason", "")).contains("Fits Fire Damage"):
				failures.append("reward choose sound should store chosen synergy reason")
			if not str(sfx.get_meta("reward_recommendation", "")).contains("Build fit"):
				failures.append("reward choose sound should store recommendation context")
			if str(sfx.get_meta("reward_effect_preview", "")) != "Fire damage x1.15 -> x1.30":
				failures.append("reward choose sound should store selected effect preview")
			if int(sfx.get_meta("reward_fit_score", 0)) < 60:
				failures.append("reward choose sound should store selected fit score")
			if not str(sfx.get_meta("reward_fit_reasons", "")).contains("Build match"):
				failures.append("reward choose sound should store selected fit reasons")
			if not bool(sfx.get_meta("reward_best_fit", false)):
				failures.append("reward choose sound should store selected best-fit flag")
		if str(overlay.get_meta("last_reward_decision_upgrade_id", "")) != "ember_rune":
			failures.append("reward overlay should remember last chosen upgrade id for run history")
		if not str(overlay.get_meta("last_reward_decision_reason", "")).contains("Build match"):
			failures.append("reward overlay should remember readable pick reason for run history")
		var last_context: Dictionary = overlay.get_meta("last_reward_decision_context", {})
		if not str(last_context.get("fit_reasons", "")).contains("Build match") \
				or str(last_context.get("effect_preview", "")) != "Fire damage x1.15 -> x1.30":
			failures.append("reward overlay should preserve selected context for main reward history")
	overlay.callv("show_room_upgrade_choices", [
		choices,
		RoomNode.RoomType.ELITE,
		{},
		false,
		["damage", "fire"],
		"",
		"Power Rune -> Ember Rune",
		{"ember_rune": "Fire damage x1.15 -> x1.30"},
		"Sockets 2/3 | Runes Fire x1",
		"Fire Damage",
		"3 picks | Tier II | Fire Damage | Damage / Fire",
		"Glass Edges: Enemies scale +12%",
		"Next: Tier III in 3 picks",
	])
	await process_frame
	if not _press_key(overlay, KEY_1):
		failures.append("reward overlay should handle numeric hotkeys")
	else:
		await process_frame
		var hotkey_context: Dictionary = overlay.get_meta("last_reward_decision_context", {})
		if not str(hotkey_context.get("fit_reasons", "")).contains("Build match") \
				or str(hotkey_context.get("effect_preview", "")) != "Fire damage x1.15 -> x1.30":
			failures.append("reward hotkey should preserve selected context for main reward history")
		var hotkey_sfx := overlay.get_node_or_null("RewardDecisionSfx") as AudioStreamPlayer
		if hotkey_sfx == null:
			failures.append("reward hotkey choose should create decision sound placeholder")
		else:
			if int(hotkey_sfx.get_meta("reward_choice_index", 0)) != 1:
				failures.append("reward hotkey sound should store 1-based choice index")
			if not str(hotkey_sfx.get_meta("reward_synergy_reason", "")).contains("Fits Fire Damage"):
				failures.append("reward hotkey sound should store selected synergy reason")
			if str(hotkey_sfx.get_meta("reward_effect_preview", "")) != "Fire damage x1.15 -> x1.30":
				failures.append("reward hotkey sound should store selected effect preview")
			if int(hotkey_sfx.get_meta("reward_fit_score", 0)) < 60:
				failures.append("reward hotkey sound should store selected fit score")
			if not bool(hotkey_sfx.get_meta("reward_best_fit", false)):
				failures.append("reward hotkey sound should store selected best-fit flag")
	overlay.show_room_upgrade_choices(choices, RoomNode.RoomType.COMBAT)
	await process_frame
	if overlay.find_child("RewardPowerArcLabel", true, false) != null:
		failures.append("empty run power arc should not show reward power arc cue")
	if overlay.find_child("RewardBuildArchetypeLabel", true, false) != null:
		failures.append("empty build archetype should not show reward archetype cue")
	if overlay.find_child("RewardChallengeLabel", true, false) != null:
		failures.append("empty run modifier should not show reward challenge cue")
	overlay.queue_free()
	await process_frame

func _check_reward_choice_numbering_and_socket_cue(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var choices := [
		{
			"id": "split_socket",
			"name": "Split Socket",
			"desc": "+1 projectile",
			"rarity": "epic",
			"tags": ["projectile", "socket"],
		},
		{
			"id": "ember_rune",
			"name": "Ember Rune",
			"desc": "+15% fire damage",
			"rarity": "rare",
			"tags": ["damage", "fire", "element"],
		},
		{
			"id": "dash_spring",
			"name": "Dash Spring",
			"desc": "-10% dash cooldown",
			"rarity": "rare",
			"tags": ["mobility", "dash"],
		},
	]
	overlay.callv("show_room_upgrade_choices", [
		choices,
		RoomNode.RoomType.TREASURE,
		{},
		true,
		["fire", "damage"],
		"",
		"Ember Rune",
		{"split_socket": "Projectiles 2 -> 3"},
	])
	await process_frame
	var split := overlay.find_child("Upgrade_split_socket", true, false) as Button
	if split == null:
		failures.append("choice numbering should keep named split socket button")
	else:
		if not str(split.text).contains("Choice 1/3"):
			failures.append("reward choice buttons should show their 1/3 choice number")
		if int(split.get_meta("choice_index", 0)) != 1 or int(split.get_meta("choice_count", 0)) != 3:
			failures.append("reward choice buttons should store choice index/count metadata")
		var split_tooltip := str(split.tooltip_text)
		for token in ["Choose reward 1", "[1]", "Split Socket", "epic",
				"Projectiles 2 -> 3", "Fit:"]:
			if not split_tooltip.to_lower().contains(token.to_lower()):
				failures.append("reward choice tooltip missing token: %s" % token)
	var ember := overlay.find_child("Upgrade_ember_rune", true, false) as Button
	if ember == null:
		failures.append("choice numbering should keep named ember rune button")
	elif not str(ember.text).contains("Choice 2/3"):
		failures.append("second reward choice should show Choice 2/3")
	if not overlay.has_method("show_room_upgrade_choices_with_socket_context"):
		failures.append("reward overlay should expose socket-context reward presentation")
	else:
		overlay.callv("show_room_upgrade_choices_with_socket_context", [
			choices,
			RoomNode.RoomType.TREASURE,
			{},
			true,
			["fire", "damage"],
			"",
			"Ember Rune",
			{"split_socket": "Projectiles 2 -> 3"},
			"Sockets 1/3 | Runes Fire x1",
		])
		await process_frame
		var cue := overlay.find_child("RewardRuneSocketCueLabel", true, false) as Label
		if cue == null:
			failures.append("reward overlay should show a rune/socket build cue")
		elif not str(cue.text).contains("Sockets 1/3") or not str(cue.text).contains("Fire x1"):
			failures.append("rune/socket cue should summarize socket usage and runes")
		split = overlay.find_child("Upgrade_split_socket", true, false) as Button
		if split != null:
			if str(split.text).contains("Socket Plan:"):
				failures.append("socket upgrade choices should keep socket pressure in tooltip/meta, not visible button text")
			if str(split.get_meta("socket_context", "")) != "Sockets 1/3 | Runes Fire x1":
				failures.append("socket upgrade choices should store socket context metadata")
			if not str(split.tooltip_text).contains("Socket Plan: Sockets 1/3"):
				failures.append("socket upgrade tooltip should include socket pressure")
	overlay.queue_free()
	await process_frame

func _check_reward_choice_visible_text_is_compact(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var choices := [
		{
			"id": "split_socket",
			"name": "Split Socket",
			"desc": "+1 projectile",
			"rarity": "epic",
			"tags": ["projectile", "socket"],
		},
		{
			"id": "ember_rune",
			"name": "Ember Rune",
			"desc": "+15% fire damage",
			"rarity": "rare",
			"tags": ["damage", "fire", "element"],
		},
		{
			"id": "dash_spring",
			"name": "Dash Spring",
			"desc": "-10% dash cooldown",
			"rarity": "rare",
			"tags": ["mobility", "dash"],
		},
	]
	overlay.callv("show_room_upgrade_choices", [
		choices,
		RoomNode.RoomType.TREASURE,
		{"split_socket": 1},
		true,
		["projectile", "socket", "fire"],
		"reroll_ready",
		"Power Rune -> Ember Rune -> Dash Spring",
		{"split_socket": "Projectiles 2 -> 3"},
		"Sockets 1/3 | Runes Fire x1",
		"Socket Engineer",
		"5 picks | Tier II | Socket Engineer | Projectile / Socket",
		"Glass Edges: Enemies scale +12%",
		"Next: Tier III in 1 pick",
		{"projectile": 2, "socket": 1},
	])
	await process_frame
	var split := overlay.find_child("Upgrade_split_socket", true, false) as Button
	if split == null:
		failures.append("compact reward text check should keep split socket button")
	else:
		var visible := str(split.text)
		if visible.split("\n", false).size() > 3:
			failures.append("reward choice visible text should stay within 3 lines, got: %s" % visible)
		for noisy in ["Preview:", "Tags:", "Synergy:", "Recommended:", "Set:", "Fit:", "Socket Plan:", "Owned"]:
			if visible.contains(noisy):
				failures.append("reward choice visible text should move %s detail into tooltip/meta" % noisy)
		for token in ["Choice 1/3", "Split Socket", "+1 projectile"]:
			if not visible.contains(token):
				failures.append("compact reward choice visible text should still include %s" % token)
		for token in ["Projectiles 2 -> 3", "Socket Plan: Sockets 1/3", "Fit:", "Set Progress:"]:
			if not str(split.tooltip_text).contains(token):
				failures.append("compact reward choice tooltip should preserve %s" % token)
		if str(split.get_meta("visible_text_contract", "")) != "compact_reward_choice":
			failures.append("compact reward choice should tag its visible text contract")
	overlay.queue_free()
	await process_frame

func _check_reward_choice_input_metadata(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.show_room_upgrade_choices([
		{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage"},
		{"id": "dash_spring", "name": "Dash Spring", "desc": "-10% dash cooldown"},
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP"},
	], RoomNode.RoomType.COMBAT, {}, true)
	await process_frame
	_assert_choice_input_meta(
		overlay.find_child("Upgrade_ember_rune", true, false) as Button,
		"reward_choose",
		"1",
		KEY_1,
		failures)
	_assert_choice_input_meta(
		overlay.find_child("Upgrade_dash_spring", true, false) as Button,
		"reward_choose",
		"2",
		KEY_2,
		failures)
	_assert_choice_input_meta(
		overlay.find_child("Upgrade_vital_core", true, false) as Button,
		"reward_choose",
		"3",
		KEY_3,
		failures)
	_assert_choice_input_meta(
		overlay.find_child("UpgradeReroll", true, false) as Button,
		"reward_reroll",
		"R",
		KEY_R,
		failures)
	_assert_choice_input_meta(
		overlay.find_child("UpgradeSkip", true, false) as Button,
		"reward_skip",
		"S",
		KEY_S,
		failures)
	overlay.queue_free()
	await process_frame

func _check_reward_flow_cue(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var choices := [
		{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage", "tags": ["fire"]},
		{"id": "dash_spring", "name": "Dash Spring", "desc": "-10% dash cooldown", "tags": ["dash"]},
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP", "tags": ["survival"]},
	]
	overlay.callv("show_room_upgrade_choices", [
		choices,
		RoomNode.RoomType.TREASURE,
		{},
		true,
		["fire"],
		"",
		"Power Rune -> Ember Rune",
		{"ember_rune": "Fire damage x1.15 -> x1.30"},
		"Sockets 1/3 | Runes Fire x1",
		"Fire Damage",
		"3 picks | Tier II | Fire Damage",
		"Glass Edges: Enemies scale +12%",
		"Next: Tier III in 3 picks",
	])
	await process_frame
	var flow := overlay.find_child("RewardFlowCueLabel", true, false) as Label
	if flow == null:
		failures.append("reward overlay should show a reward flow cue after room clear")
	else:
		for token in ["Claim 1/3", "Build stronger", "Next: Door opens"]:
			if not flow.text.contains(token):
				failures.append("reward flow cue missing token: %s" % token)
		if str(flow.get_meta("flow_kind", "")) != "reward":
			failures.append("reward flow cue should expose reward flow metadata")
		if int(flow.get_meta("choice_count", 0)) != 3:
			failures.append("reward flow cue should store choice count")
		if str(flow.get_meta("next_action_key", "")) != "door":
			failures.append("treasure reward flow should lead back to doors")
		if str(flow.get_meta("build_archetype", "")) != "Fire Damage":
			failures.append("reward flow cue should store build archetype context")
		if not str(flow.get_meta("run_power_arc", "")).contains("Tier II"):
			failures.append("reward flow cue should store run power arc context")
	overlay.show_room_upgrade_choices(choices, RoomNode.RoomType.BOSS)
	await process_frame
	flow = overlay.find_child("RewardFlowCueLabel", true, false) as Label
	if flow == null:
		failures.append("boss reward overlay should keep reward flow cue")
	else:
		if not flow.text.contains("Next: Portal"):
			failures.append("boss reward flow should point to the portal")
		if str(flow.get_meta("next_action_key", "")) != "portal":
			failures.append("boss reward flow should expose portal next action metadata")
	overlay.queue_free()
	await process_frame

func _check_upgrade_taken_feedback_copy(failures: Array[String]) -> void:
	var main_script = load("res://scripts/main.gd")
	var main_node = main_script.new()
	if not main_node.has_method("_upgrade_taken_text"):
		failures.append("Main should expose _upgrade_taken_text for post-pick build feedback copy")
		main_node.free()
		return
	var args := [
		"Ember Rune",
		2,
		["damage", "fire", "element"],
		"Power Rune, Ember Rune x2",
		"Fire Damage",
		"Sockets 2/3 | Runes Fire x2",
	]
	var text := str(main_node.callv("_upgrade_taken_text", args))
	for token in [
		"Ember Rune x2",
		"Tags: Damage / Fire / Element",
		"Build: Power Rune, Ember Rune x2",
		"Archetype: Fire Damage",
		"Rune/Socket: Sockets 2/3 | Runes Fire x2",
	]:
		if not text.contains(token):
			failures.append("upgrade taken feedback missing token: %s" % token)
	main_node.free()

func _check_main_passes_upgrade_stacks(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("upgrade_stack_count"):
		failures.append("Main should read player upgrade stacks for reward preview")
	if not source.contains("show_room_upgrade_choices(_annotated_pending_upgrades(),"):
		failures.append("Main should pass upgrade stacks into reward overlay")
	if not source.contains("_annotated_pending_upgrades"):
		failures.append("Main should annotate unavailable upgrade choices")
	if not source.contains("upgrade_block_reason"):
		failures.append("Main should include upgrade block reasons in reward choices")
	if not source.contains("reward_skipped"):
		failures.append("Main should listen for skipped upgrade reward")
	if not source.contains("add_gold"):
		failures.append("Main should grant gold when skipping upgrade reward")
	if not source.contains("reward_reroll_requested"):
		failures.append("Main should listen for reward reroll requests")
	if not source.contains("reroll_available_synergy_room_choices"):
		failures.append("Main should ask UpgradeDB for available build-aware rerolled choices")
	if not source.contains("roll_available_synergy_room_choices"):
		failures.append("Main should ask UpgradeDB for available build-aware reward choices")
	if not source.contains("upgrade_build_tags"):
		failures.append("Main should pass player build tags into reward rolls")
	if not source.contains("show_room_upgrade_choices(_annotated_pending_upgrades()") \
			or not source.contains("player.upgrade_build_tags()"):
		failures.append("Main should pass player build tags into reward overlay")
	if not source.contains("show_room_upgrade_choices"):
		failures.append("Main should pass room type into reward overlay presentation")
	if not source.contains("_show_upgrade_taken_feedback"):
		failures.append("Main should show feedback after choosing a room upgrade")
	if not source.contains("UpgradeDBScript.upgrade_name(upgrade_id)"):
		failures.append("upgrade chosen feedback should use readable upgrade names")
	if not source.contains("player.upgrade_stack_count(upgrade_id)"):
		failures.append("upgrade chosen feedback should include the resulting stack count")
	if not source.contains("UpgradeDBScript.upgrade_tags(upgrade_id)"):
		failures.append("upgrade chosen feedback should include readable upgrade tags")
	if not source.contains("Tags:"):
		failures.append("upgrade chosen toast should label upgrade tags")
	if not source.contains("_upgrade_taken_text"):
		failures.append("upgrade chosen toast should include post-pick build context")
	if not source.contains("_show_reward_claimed_feedback"):
		failures.append("Main should show a reward claimed summary after choosing an upgrade")
	if not source.contains("RewardClaimedToast"):
		failures.append("reward claimed feedback should create a named toast")
	if not source.contains("Build: %s"):
		failures.append("reward claimed feedback should summarize the current build")
	if not source.contains("Reward claimed | %s | Build:"):
		failures.append("reward claimed feedback should include room tier")
	if not source.contains("Tags: %s"):
		failures.append("reward claimed feedback should include build tags")
	if not source.contains("BossRewardClaimedToast"):
		failures.append("boss reward claimed feedback should create a boss-specific toast")
	if not source.contains("Boss reward claimed | Portal ready"):
		failures.append("boss reward claimed feedback should point the player to the portal")
	if not source.contains("_show_reward_economy_feedback"):
		failures.append("Main should show feedback for reward skip/reroll gold deltas")
	if not source.contains("RewardEconomyToast"):
		failures.append("reward economy feedback should create a named toast")
	if not source.contains("_show_reward_economy_feedback(\"Skip reward\", gold)"):
		failures.append("skipping reward should show positive gold feedback")
	if not source.contains("_show_reward_economy_feedback(\"Reroll\", -cost)"):
		failures.append("rerolling reward should show negative gold feedback")
	if not source.contains("_reward_reroll_state()"):
		failures.append("Main should pass explicit reroll state into reward overlay")
	if not source.contains("_reward_reroll_state(),\n\t\tplayer.upgrade_history_summary(),"):
		failures.append("Main should pass upgrade history into reward overlay")
	if not source.contains("_upgrade_effect_previews"):
		failures.append("Main should build upgrade effect previews for reward choices")
	if not source.contains("UpgradeDBScript.upgrade_effect_preview(player"):
		failures.append("Main should ask UpgradeDB for player-specific upgrade previews")
	if not source.contains("_upgrade_effect_previews(_pending_upgrades)"):
		failures.append("Main should pass upgrade effect previews into reward overlay")
	if not source.contains("player.rune_socket_summary()"):
		failures.append("Main should pass rune/socket summary into reward overlay and reward feedback")
	if not source.contains("Rune/Socket: %s"):
		failures.append("reward claimed feedback should include rune/socket summary")
	if not source.contains("Power Arc: %s"):
		failures.append("reward claimed feedback should include run power arc")
	if not source.contains("run_power_arc_summary"):
		failures.append("Main should read player run power arc for reward feedback")
	if not source.contains("run_power_pick_count"):
		failures.append("reward claimed feedback should store run power pick count metadata")
	if not source.contains("player.rune_socket_summary(),\n\t\tplayer.build_archetype_summary(),\n\t\tplayer.run_power_arc_summary(),\n\t\t_run_modifier_summary(),\n\t\tplayer.next_power_milestone_hint(),"):
		failures.append("Main should pass archetype, power arc, challenge, and next milestone context into reward overlay")
	if not source.contains("_upgrade_tag_stack_counts(_pending_upgrades)"):
		failures.append("Main should pass tag stack counts into reward overlay set-progress hints")
	if not source.contains("_reward_decision_reason"):
		failures.append("Main should preserve reward decision reason when applying upgrades")
	if not source.contains("last_reward_decision_context"):
		failures.append("Main should read selected reward context from overlay")

func _make_player() -> Player:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	return player

func _button_count(parent: Node) -> int:
	var count := 0
	for child in parent.find_children("*", "Button", true, false):
		count += 1
	return count

func _first_button(parent: Node) -> Button:
	for child in parent.find_children("*", "Button", true, false):
		if not str(child.name).contains("Skip"):
			return child as Button
	return null

func _has_upgrade_best_fit(parent: Node) -> bool:
	for child in parent.find_children("Upgrade_*", "Button", true, false):
		var button := child as Button
		if button != null and (bool(button.get_meta("best_fit", false)) or str(button.text).contains("Best Fit")):
			return true
	return false

func _has_signal(node: Object, signal_name: String) -> bool:
	for info in node.get_signal_list():
		if str(info.get("name", "")) == signal_name:
			return true
	return false

func _method_arg_count(node: Object, method_name: String) -> int:
	for info in node.get_method_list():
		if str(info.get("name", "")) == method_name:
			return Array(info.get("args", [])).size()
	return -1

func _press_key(node: Node, keycode: int) -> bool:
	if not node.has_method("_unhandled_input"):
		return false
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	node.call("_unhandled_input", event)
	return true

func _assert_choice_input_meta(
		button: Button,
		action: String,
		key_label: String,
		hotkey: int,
		failures: Array[String],
) -> void:
	if button == null:
		failures.append("reward choice input metadata target should exist")
		return
	if str(button.get_meta("choice_input_action", "")) != action:
		failures.append("%s should store input action %s" % [button.name, action])
	if str(button.get_meta("choice_key_label", "")) != key_label:
		failures.append("%s should store key label %s" % [button.name, key_label])
	if int(button.get_meta("choice_hotkey", 0)) != hotkey:
		failures.append("%s should store hotkey %d" % [button.name, hotkey])
	var action_text := str(button.get_meta("choice_action_text", ""))
	if action_text == "":
		failures.append("%s should store readable choice action text" % button.name)
	if not button.tooltip_text.contains(action_text) or not button.tooltip_text.contains(key_label):
		failures.append("%s should expose key/action tooltip text" % button.name)

func _overlaps(a: Array, b: Array) -> bool:
	var ids := {}
	for choice in a:
		ids[str(choice.get("id", ""))] = true
	for choice in b:
		if ids.has(str(choice.get("id", ""))):
			return true
	return false

func _has_rare_plus(choices: Array) -> bool:
	for choice in choices:
		if ["rare", "epic"].has(str(choice.get("rarity", ""))):
			return true
	return false
