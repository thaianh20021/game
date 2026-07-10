extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	await _check_burning_status_ticks_damage(failures)
	await _check_poisoned_status_ticks_damage(failures)
	await _check_chilled_status_slows_then_expires(failures)
	await _check_cursed_status_increases_incoming_damage_until_expired(failures)
	await _check_revive_charm_signal_feedback(failures)
	await _check_lethal_damage_feedback(failures)
	_check_off_tree_summon_count_guard(failures)

	if failures.is_empty():
		print("Player status smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_burning_status_ticks_damage(failures: Array[String]) -> void:
	var player := Player.new()
	root.add_child(player)
	player.max_hp = 100
	player.hp = 100
	if not player.has_method("add_status"):
		failures.append("player should expose add_status for enemy/trap debuffs")
	else:
		player.add_status("burning", 1.2)
		await process_frame
		var feedback := player.get_node_or_null("PlayerStatusFeedback") as Label
		if feedback == null:
			failures.append("adding player status should show PlayerStatusFeedback")
		elif not feedback.text.contains("Burning"):
			failures.append("player status feedback should show readable status name")
		elif str(feedback.get_meta("status_id", "")) != "burning" \
				or str(feedback.get_meta("status_event", "")) != "applied" \
				or float(feedback.get_meta("status_duration", 0.0)) < 1.19 \
				or str(feedback.get_meta("status_color_role", "")) != "burning":
			failures.append("player status feedback should expose applied status metadata")
		player._tick_statuses(0.6)
		player._tick_statuses(0.6)
		if player.hp >= 100:
			failures.append("burning status should tick damage over time")
	if player.has_method("has_status") and player.has_status("burning"):
		player._tick_statuses(0.6)
		if player.has_status("burning"):
			failures.append("burning status should expire after duration")
	player.queue_free()
	await process_frame

func _check_off_tree_summon_count_guard(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	var start := source.find("func _living_summon_count()")
	if start < 0:
		failures.append("Player should expose living summon count helper")
		return
	var end := source.find("func ", start + 1)
	var body := source.substr(start, end - start if end > start else source.length() - start)
	if not body.contains("is_inside_tree()"):
		failures.append("living summon count should avoid get_tree when player is off-tree")

func _check_lethal_damage_feedback(failures: Array[String]) -> void:
	var player := Player.new()
	root.add_child(player)
	player.max_hp = 30
	player.hp = 12
	var died := {"value": false, "count": 0}
	player.died.connect(func() -> void:
		died["value"] = true
		died["count"] = int(died["count"]) + 1)
	player.take_damage(20, Vector2.ZERO, "Boss: Smash")
	await process_frame
	if not bool(died["value"]):
		failures.append("lethal damage should emit died")
	if int(died["count"]) != 1:
		failures.append("lethal damage should emit died exactly once")
	var feedback := player.get_node_or_null("DeathFeedback") as Label
	if feedback == null:
		failures.append("lethal damage should show death feedback")
	else:
		if not feedback.text.contains("Boss: Smash") or not feedback.text.contains("20"):
			failures.append("death feedback should show lethal source and damage")
		if str(feedback.get_meta("damage_source", "")) != "Boss: Smash":
			failures.append("death feedback should expose source metadata")
		if str(feedback.get_meta("damage_kind", "")) != "boss":
			failures.append("death feedback should expose damage kind metadata")
		if int(feedback.get_meta("damage_amount", 0)) != 20:
			failures.append("death feedback should expose lethal damage metadata")
	var sfx := player.get_node_or_null("PlayerDamageSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("lethal damage should create player damage sound placeholder")
	else:
		if str(sfx.get_meta("player_damage_sound_id", "")) != "player_damage_boss":
			failures.append("lethal boss damage sound should use player_damage_boss cue")
		if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("player damage sound should come from AudioCueDB")
		if str(sfx.get_meta("damage_source", "")) != "Boss: Smash":
			failures.append("player damage sound should preserve damage source")
		if int(sfx.get_meta("damage_amount", 0)) != 20:
			failures.append("player damage sound should expose damage amount")
		if not bool(sfx.get_meta("placeholder_audio_stream", false)):
			failures.append("player damage sound should assign placeholder stream metadata")
		if DisplayServer.get_name() == "headless" and not bool(sfx.get_meta("headless_playback_skipped", false)):
			failures.append("player damage sound should skip playback in headless smoke")
	player.take_damage(5, Vector2.ZERO, "Enemy: Late Hit")
	await process_frame
	if int(died["count"]) != 1:
		failures.append("post-death damage should not emit died again")
	if str(player.get_meta("last_damage_source", "")) != "Boss: Smash":
		failures.append("post-death damage should not replace final hit metadata")
	var damage_sfx := player.get_node_or_null("PlayerDamageSfx") as AudioStreamPlayer
	if damage_sfx != null and str(damage_sfx.get_meta("damage_source", "")) != "Boss: Smash":
		failures.append("post-death damage should not replace lethal damage sound metadata")
	player.heal(10)
	if player.hp != 0:
		failures.append("post-death healing should not revive the player outside revive systems")
	player.queue_free()
	await process_frame

func _check_poisoned_status_ticks_damage(failures: Array[String]) -> void:
	var player := Player.new()
	root.add_child(player)
	player.max_hp = 100
	player.hp = 100
	player.add_status("poisoned", 1.2)
	player._tick_statuses(0.6)
	player._tick_statuses(0.6)
	if player.hp >= 100:
		failures.append("poisoned status should tick damage over time")
	player.queue_free()
	await process_frame

func _check_chilled_status_slows_then_expires(failures: Array[String]) -> void:
	var player := Player.new()
	root.add_child(player)
	player.move_speed = 100.0
	if not player.has_method("add_status"):
		failures.append("player should expose add_status for chilled")
	elif not player.has_method("has_status"):
		failures.append("player should expose has_status for HUD/testable status state")
	elif not player.has_method("current_move_speed"):
		failures.append("player should expose current_move_speed for debuff-aware movement")
	else:
		player.add_status("chilled", 1.0)
		if not player.has_status("chilled"):
			failures.append("chilled status should be stored")
		if float(player.current_move_speed()) >= 100.0:
			failures.append("chilled status should reduce current move speed")
		player._tick_statuses(1.1)
		if player.has_status("chilled"):
			failures.append("chilled status should expire")
		var expired_feedback := player.get_node_or_null("PlayerStatusFeedback") as Label
		if expired_feedback == null:
			failures.append("expired player status should show feedback")
		elif not expired_feedback.text.contains("Chilled ended"):
			failures.append("expired status feedback should name the expired status")
		elif str(expired_feedback.get_meta("status_id", "")) != "chilled" \
				or str(expired_feedback.get_meta("status_event", "")) != "expired" \
				or str(expired_feedback.get_meta("status_color_role", "")) != "chilled":
			failures.append("expired status feedback should expose expired status metadata")
		if not is_equal_approx(float(player.current_move_speed()), 100.0):
			failures.append("move speed should recover after chilled expires")
	player.queue_free()
	await process_frame

func _check_cursed_status_increases_incoming_damage_until_expired(failures: Array[String]) -> void:
	var player := Player.new()
	root.add_child(player)
	player.max_hp = 100
	player.hp = 100
	player.add_status("cursed", 1.0)
	if not player.has_status("cursed"):
		failures.append("cursed status should be stored")
	var cursed_damage := int(player.call("_incoming_damage_after_passives", 20))
	if cursed_damage <= 20:
		failures.append("cursed status should increase incoming damage")
	player._tick_statuses(1.1)
	if player.has_status("cursed"):
		failures.append("cursed status should expire")
	var normal_damage := int(player.call("_incoming_damage_after_passives", 20))
	if normal_damage != 20:
		failures.append("incoming damage should recover after cursed expires")
	player.queue_free()
	await process_frame

func _check_revive_charm_signal_feedback(failures: Array[String]) -> void:
	var player := Player.new()
	root.add_child(player)
	player.max_hp = 100
	player.hp = 10
	if not player.has_signal("revived"):
		failures.append("player should emit revived when revive_charm prevents death")
		player.queue_free()
		await process_frame
		return
	var events: Array[Dictionary] = []
	player.revived.connect(func(context: Dictionary) -> void:
		events.append(context.duplicate(true)))
	player.apply_meta_bonuses({"upgrades": {"revive_charm": 1}})
	var died := {"value": false}
	player.died.connect(func() -> void:
		died["value"] = true)
	player.take_damage(99, Vector2.ZERO, "Boss: Smash")
	await process_frame
	if bool(died["value"]):
		failures.append("revive_charm should prevent the killing hit from emitting died")
	if player.hp <= 0:
		failures.append("revive_charm should restore HP after lethal damage")
	if events.is_empty():
		failures.append("revive_charm should emit revived context")
	else:
		var event: Dictionary = events.back()
		if int(event.get("revives_used", 0)) != 1:
			failures.append("revived context should store revives_used")
		if int(event.get("charges_left", -1)) != 0:
			failures.append("revived context should store remaining charges")
		if int(event.get("hp", 0)) != player.hp or int(event.get("max_hp", 0)) != player.max_hp:
			failures.append("revived context should store restored hp and max hp")
		if str(event.get("source", "")) != "Boss: Smash":
			failures.append("revived context should store lethal source label")
	var feedback := player.get_node_or_null("PlayerReviveFeedback") as Label
	if feedback == null:
		failures.append("revive_charm should show player-local revive feedback")
	else:
		if not feedback.text.contains("Revived") or not feedback.text.contains("Boss: Smash"):
			failures.append("player-local revive feedback should name revive and lethal source")
		if int(feedback.get_meta("revives_used", 0)) != 1:
			failures.append("player-local revive feedback should expose revives_used metadata")
		if int(feedback.get_meta("charges_left", -1)) != 0:
			failures.append("player-local revive feedback should expose charges_left metadata")
		if int(feedback.get_meta("prevented_damage", 0)) <= 0:
			failures.append("player-local revive feedback should expose prevented damage metadata")
	var sfx := player.get_node_or_null("PlayerReviveSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("revive_charm should create player-local revive sound placeholder")
	else:
		if str(sfx.get_meta("revive_sound_id", "")) != "player_revive":
			failures.append("player-local revive sound should expose revive cue id")
		if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("player-local revive sound should come from AudioCueDB")
		if not bool(sfx.get_meta("placeholder_audio_stream", false)):
			failures.append("player-local revive sound should assign placeholder stream metadata")
		if DisplayServer.get_name() == "headless" and not bool(sfx.get_meta("headless_playback_skipped", false)):
			failures.append("player-local revive sound should skip playback in headless smoke")
	player.queue_free()
	await process_frame
