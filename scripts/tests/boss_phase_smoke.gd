extends SceneTree

class DummyTarget:
	extends Node2D
	var damage_taken := 0

	func take_damage(amount: int) -> void:
		damage_taken += amount

func _init() -> void:
	var failures: Array[String] = []

	await _check_boss_phase_v2(failures)
	await _check_boss_trap_wave_fairness(failures)
	await _check_boss_attack_cue_events(failures)
	await _check_boss_damage_sources(failures)

	if failures.is_empty():
		print("Boss phase smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_boss_phase_v2(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var target := DummyTarget.new()
	target.global_position = Vector2(96, 0)
	scene.add_child(target)
	var boss := BossGolem.new()
	boss.max_hp = 100
	boss.hp = 100
	boss.contact_damage = 10
	boss.speed = 40.0
	boss.target = target
	scene.add_child(boss)
	await process_frame

	var phase_events: Array[Dictionary] = []
	if not boss.has_signal("boss_phase_changed"):
		failures.append("boss should expose boss_phase_changed signal for HUD/SFX hooks")
	else:
		boss.connect("boss_phase_changed", func(status: Dictionary) -> void:
			phase_events.append(status))

	boss.hp = 60
	boss.call("_update_phase")
	if boss.phase != 2:
		failures.append("boss should enter phase 2 below 66% hp")
	if phase_events.is_empty():
		failures.append("boss phase change should emit boss_phase_changed")
	elif int(phase_events.back().get("phase", 0)) != 2:
		failures.append("boss phase change signal should include updated phase")
	elif float(phase_events.back().get("elapsed_seconds", -1.0)) < 0.0:
		failures.append("boss phase change signal should include elapsed seconds for timing evidence")
	if not boss.has_method("phase_pattern"):
		failures.append("boss should expose phase_pattern")
	elif str(boss.call("phase_pattern")) != "volley_traps":
		failures.append("phase 2 should advertise volley_traps pattern")
	if not boss.has_method("phase_warning_text"):
		failures.append("boss should expose readable phase warning text")
	elif not str(boss.call("phase_warning_text")).contains("VOLLEY"):
		failures.append("phase 2 warning should name the volley pattern")
	if not boss.has_method("pattern_steps"):
		failures.append("boss should expose readable pattern_steps")
	else:
		var phase2_steps: Array = boss.call("pattern_steps")
		if phase2_steps.size() < 2 or not str(phase2_steps[0]).contains("Rock") \
				or not _array_has_text(phase2_steps, "Trap"):
			failures.append("phase 2 pattern_steps should explain volley into traps")
	if not boss.has_method("current_pattern_step"):
		failures.append("boss should expose current_pattern_step for HUD timeline")
	elif not str(boss.call("current_pattern_step")).contains("Rock"):
		failures.append("phase 2 current pattern step should start on rock volley")
	if not boss.has_method("next_pattern_step"):
		failures.append("boss should expose next_pattern_step for HUD timeline")
	elif not str(boss.call("next_pattern_step")).contains("Trap"):
		failures.append("phase 2 next pattern step should preview trap wave")
	if not boss.has_method("advance_pattern_step"):
		failures.append("boss should expose advance_pattern_step for pattern timeline")
	else:
		boss.call("advance_pattern_step")
		if not str(boss.call("current_pattern_step")).contains("Trap"):
			failures.append("advance_pattern_step should rotate to the next readable boss step")
	if not boss.has_method("counter_hint"):
		failures.append("boss should expose counter_hint")
	elif not str(boss.call("counter_hint")).contains("Strafe"):
		failures.append("phase 2 counter_hint should teach strafe counterplay")
	if not boss.has_method("dodge_cue"):
		failures.append("boss should expose concise dodge_cue for HUD readability")
	elif not str(boss.call("dodge_cue")).contains("Strafe"):
		failures.append("phase 2 dodge_cue should tell the player to strafe")
	if not boss.has_method("punish_window_seconds"):
		failures.append("boss should expose punish_window_seconds for readable counterattack timing")
	elif float(boss.call("punish_window_seconds")) <= 0.0:
		failures.append("boss punish_window_seconds should be positive")
	if not boss.has_method("safe_window_hint"):
		failures.append("boss should expose safe_window_hint for boss counterplay UI")
	elif not str(boss.call("safe_window_hint")).contains("Punish"):
		failures.append("boss safe_window_hint should explain when to punish")
	var phase_label := boss.find_child("BossPhaseWarning", true, false) as Label
	if phase_label == null:
		failures.append("phase change should spawn a boss warning label")
	elif not phase_label.text.contains("VOLLEY"):
		failures.append("boss warning label should show current phase pattern")
	else:
		if not phase_label.text.contains("@") or not phase_label.text.contains("s"):
			failures.append("boss warning label should show elapsed phase timing")
		if int(phase_label.get_meta("boss_phase", 0)) != 2:
			failures.append("boss warning label should expose phase metadata")
		if float(phase_label.get_meta("boss_phase_elapsed_seconds", -1.0)) < 0.0:
			failures.append("boss warning label should store elapsed phase timing metadata")
		if str(phase_label.get_meta("boss_pattern", "")) != "volley_traps":
			failures.append("boss warning label should expose pattern metadata")
		if not str(phase_label.get_meta("boss_counter_hint", "")).contains("Strafe"):
			failures.append("boss warning label should expose counter hint metadata")
	var phase_sfx := boss.get_node_or_null("BossPhaseSfx") as AudioStreamPlayer
	if phase_sfx == null:
		failures.append("phase change should create boss phase sound placeholder")
	else:
		if str(phase_sfx.get_meta("boss_phase_sound_id", "")) != "boss_phase_shift":
			failures.append("phase change sound should use boss_phase_shift cue")
		if int(phase_sfx.get_meta("boss_phase", 0)) != 2:
			failures.append("phase change sound should store phase metadata")
		if not bool(phase_sfx.get_meta("placeholder_audio_stream", false)):
			failures.append("phase change sound should use placeholder audio stream")
		if str(phase_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("phase change sound should come from AudioCueDB")
		if str(phase_sfx.get_meta("boss_pattern", "")) != "volley_traps":
			failures.append("phase change sound should store boss pattern metadata")
		if not str(phase_sfx.get_meta("boss_pattern_label", "")).contains("Rock Volley"):
			failures.append("phase change sound should store readable pattern label metadata")
		if int(phase_sfx.get_meta("boss_pattern_step_index", -1)) != 0:
			failures.append("phase change sound should store phase-start pattern step index")
		if not str(phase_sfx.get_meta("boss_current_pattern_step", "")).contains("Rock"):
			failures.append("phase change sound should store current pattern step metadata")
		if not str(phase_sfx.get_meta("boss_next_pattern_step", "")).contains("Trap"):
			failures.append("phase change sound should store next pattern step metadata")
		if not str(phase_sfx.get_meta("boss_pattern_timeline", "")).contains("Now:") \
				or not str(phase_sfx.get_meta("boss_pattern_timeline", "")).contains("Next:"):
			failures.append("phase change sound should store readable pattern timeline metadata")
		if not str(phase_sfx.get_meta("boss_counter_hint", "")).contains("Strafe"):
			failures.append("phase change sound should store counter hint metadata")
		if not str(phase_sfx.get_meta("boss_dodge_cue", "")).contains("Strafe"):
			failures.append("phase change sound should store concise dodge cue metadata")
		if float(phase_sfx.get_meta("boss_punish_window_seconds", 0.0)) <= 0.0:
			failures.append("phase change sound should store punish window metadata")
		if not str(phase_sfx.get_meta("boss_safe_window_hint", "")).contains("Punish"):
			failures.append("phase change sound should store safe-window hint metadata")
	if _child_group_count(boss, "room_traps") < 2:
		failures.append("phase 2 should summon traps")
	if not _all_group_children_have_meta(boss, "room_traps", "boss_trap_warning"):
		failures.append("boss trap waves should mark spawned hazard warnings")
	if not _all_group_children_have_child(boss, "room_traps", "BossTrapWarning"):
		failures.append("boss trap waves should show readable trap warning labels")
	await _assert_boss_traps_are_floor_hazards(boss, failures)

	var before_bullets := _child_type_count(scene, "EnemyProjectile")
	if not boss.has_method("spawn_bullet_hell"):
		failures.append("boss should expose spawn_bullet_hell")
	else:
		boss.call("spawn_bullet_hell", 8)
		await process_frame
		if _child_type_count(scene, "EnemyProjectile") != before_bullets:
			failures.append("boss bullet hell should wait for readable telegraph before radial projectiles")
		if _child_named(scene, "CombatFxTelegraph") == null:
			failures.append("boss bullet hell should telegraph before radial shots")
		await _wait_readable_attack_telegraph()
		if _child_type_count(scene, "EnemyProjectile") - before_bullets < 8:
			failures.append("boss bullet hell should spawn radial projectiles after telegraph")
		if not _all_projectiles_have_pattern(scene, "volley_traps"):
			failures.append("boss bullet waves should tag projectiles with the active pattern id")

	boss.hp = 25
	boss.call("_update_phase")
	if boss.phase != 3:
		failures.append("boss should enter phase 3 below 33% hp")
	if phase_events.size() < 2:
		failures.append("boss enrage transition should emit boss_phase_changed")
	elif not bool(phase_events.back().get("enraged", false)):
		failures.append("boss enrage signal should include enraged state")
	if not bool(boss.get("enraged")):
		failures.append("boss should enrage below 30% hp")
	if boss.has_method("phase_pattern") and str(boss.call("phase_pattern")) != "enrage_bullet_hell":
		failures.append("phase 3 should advertise enrage_bullet_hell pattern")
	if boss.has_method("phase_warning_text") and not str(boss.call("phase_warning_text")).contains("ENRAGE"):
		failures.append("enrage warning should name enrage state")
	phase_label = boss.find_child("BossPhaseWarning", true, false) as Label
	if phase_label == null:
		failures.append("enrage should update the boss warning label")
	else:
		if not phase_label.text.contains("@") or not phase_label.text.contains("s"):
			failures.append("enrage warning label should show elapsed phase timing")
		if float(phase_label.get_meta("boss_phase_elapsed_seconds", -1.0)) < 0.0:
			failures.append("enrage warning label should store elapsed phase timing metadata")
		if not bool(phase_label.get_meta("boss_enraged", false)):
			failures.append("enrage warning label should expose enraged metadata")
		if str(phase_label.get_meta("boss_pattern", "")) != "enrage_bullet_hell":
			failures.append("enrage warning label should expose enrage pattern metadata")
		if not str(phase_label.get_meta("boss_dodge_cue", "")).contains("Rotate"):
			failures.append("enrage warning label should expose dodge cue metadata")
	phase_sfx = boss.get_node_or_null("BossPhaseSfx") as AudioStreamPlayer
	if phase_sfx == null:
		failures.append("enrage should create boss phase sound placeholder")
	else:
		if str(phase_sfx.get_meta("boss_phase_sound_id", "")) != "boss_enrage":
			failures.append("enrage sound should use boss_enrage cue")
		if not bool(phase_sfx.get_meta("boss_enraged", false)):
			failures.append("enrage sound should store enraged metadata")
	if not boss.has_method("boss_status"):
		failures.append("boss should expose boss_status for HUD")
	else:
		var status: Dictionary = boss.call("boss_status")
		if int(status.get("hp", 0)) != 25 or int(status.get("max_hp", 0)) != 100:
			failures.append("boss_status should report current hp and max hp")
		if not str(status.get("phase_text", "")).contains("ENRAGE"):
			failures.append("boss_status should report readable phase text")
		if not str(status.get("pattern_label", "")).contains("Bullet Hell"):
			failures.append("boss_status should include a readable pattern label")
		if str(status.get("name", "")) == "":
			failures.append("boss_status should include display name")
		if str(status.get("next_attack", "")) == "":
			failures.append("boss_status should include next attack cue")
		if float(status.get("next_attack_seconds", -1.0)) < 0.0:
			failures.append("boss_status should include non-negative next attack countdown")
		if str(status.get("next_attack_id", "")) == "":
			failures.append("boss_status should expose structured next_attack_id")
		if str(status.get("next_attack_label", "")) == "":
			failures.append("boss_status should expose structured next_attack_label")
		if str(status.get("next_attack_warning", "")) == "":
			failures.append("boss_status should expose structured next_attack_warning")
		if str(status.get("next_attack_id", "")) != "bullet_hell":
			failures.append("enraged boss next_attack_id should preview bullet_hell")
		if not str(status.get("next_attack", "")).contains("Bullet"):
			failures.append("enraged boss next attack cue should name bullet pressure")
		if str(status.get("enrage_warning", "")) == "":
			failures.append("enraged boss_status should expose persistent enrage warning text")
		elif not str(status.get("enrage_warning", "")).contains("Bullet") \
				or not str(status.get("enrage_warning", "")).contains("traps"):
			failures.append("enrage warning should explain bullet pressure and trap waves")
		var steps: Array = status.get("pattern_steps", [])
		if steps.size() < 2 or not _array_has_text(steps, "Bullet") \
				or not _array_has_text(steps, "Trap"):
			failures.append("enraged boss_status should expose readable bullet/trap pattern steps")
		if not str(status.get("counter_hint", "")).contains("Keep moving"):
			failures.append("enraged boss_status should expose movement counterplay hint")
		if not str(status.get("dodge_cue", "")).contains("Rotate") \
				or not str(status.get("dodge_cue", "")).contains("gaps"):
			failures.append("enraged boss_status should expose a short dodge cue")
		if float(status.get("punish_window_seconds", 0.0)) <= 0.0:
			failures.append("boss_status should expose positive punish window seconds")
		if not str(status.get("safe_window_hint", "")).contains("Punish"):
			failures.append("boss_status should expose a readable safe-window punish hint")
		if int(status.get("pattern_step_index", -1)) < 0:
			failures.append("boss_status should expose pattern_step_index")
		if str(status.get("current_pattern_step", "")) == "":
			failures.append("boss_status should expose current_pattern_step")
		if str(status.get("next_pattern_step", "")) == "":
			failures.append("boss_status should expose next_pattern_step")
		if not str(status.get("pattern_timeline", "")).contains("Now:"):
			failures.append("boss_status should expose readable pattern_timeline")
		if str(status.get("enrage_intensity", "")) != "high":
			failures.append("enraged boss_status should expose high enrage intensity")
		if float(status.get("elapsed_seconds", -1.0)) < 0.0:
			failures.append("boss_status should expose elapsed seconds for balance timing evidence")
		if int(status.get("active_trap_count", -1)) < 4:
			failures.append("enraged boss_status should expose active trap pressure count")
		if int(status.get("floating_gun_count", -1)) < 4:
			failures.append("enraged boss_status should expose floating gun pressure count")
		if int(status.get("enrage_bullet_count", 0)) < 8:
			failures.append("enraged boss_status should expose planned bullet hell count")
		var arena_pressure := str(status.get("arena_pressure_summary", ""))
		if not arena_pressure.contains("Bullets") or not arena_pressure.contains("Traps") \
				or not arena_pressure.contains("Guns"):
			failures.append("enraged boss_status should expose readable arena pressure summary")
	if _child_group_count(boss, "floating_guns") < 4:
		failures.append("enraged boss should keep four floating guns")
	var traps_before_enrage_tick := _child_group_count(boss, "room_traps")
	boss.call("_behave", 2.1)
	await process_frame
	if _child_group_count(boss, "room_traps") <= traps_before_enrage_tick:
		failures.append("enraged boss should keep summoning trap waves")
	for i in 8:
		boss.call("summon_phase_traps", 3)
	await process_frame
	if _child_group_count(boss, "room_traps") > 12:
		failures.append("boss trap waves should cap active hazards for arena readability")
	if not _all_group_children_have_meta(boss, "room_traps", "boss_trap"):
		failures.append("boss trap waves should tag spawned hazards")
	if not _all_group_children_have_meta(boss, "room_traps", "boss_pattern"):
		failures.append("boss trap waves should tag spawned hazards with active pattern id")
	if not _all_group_children_have_meta_float_at_least(boss, "room_traps", "telegraph_seconds", 0.5):
		failures.append("boss trap waves should keep readable >=0.5s telegraphs")

	scene.queue_free()
	await process_frame

func _check_boss_trap_wave_fairness(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var target := DummyTarget.new()
	target.global_position = Vector2(42, 0)
	scene.add_child(target)
	var boss := BossGolem.new()
	boss.max_hp = 100
	boss.hp = 60
	boss.contact_damage = 10
	boss.target = target
	boss.phase = 2
	scene.add_child(boss)
	await process_frame

	boss.call("summon_phase_traps", 4)
	await process_frame
	var traps := _boss_traps(boss)
	if traps.size() < 4:
		failures.append("boss trap fairness smoke should spawn the requested trap wave")
	var safe_radius := 28.0
	for trap in traps:
		if trap.global_position.distance_to(target.global_position) < safe_radius:
			failures.append("boss trap wave should avoid spawning directly under the player")
			break
	var min_spacing := 20.0
	for i in traps.size():
		for j in range(i + 1, traps.size()):
			if traps[i].global_position.distance_to(traps[j].global_position) < min_spacing:
				failures.append("boss trap wave should keep hazards visually separated")
				break

	scene.queue_free()
	await process_frame

func _check_boss_attack_cue_events(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var target := DummyTarget.new()
	target.global_position = Vector2(96, 0)
	scene.add_child(target)
	var boss := BossGolem.new()
	boss.max_hp = 100
	boss.hp = 60
	boss.contact_damage = 10
	boss.target = target
	boss.phase = 2
	scene.add_child(boss)
	await process_frame

	var attack_events: Array[Dictionary] = []
	if not boss.has_signal("boss_attack_cued"):
		failures.append("boss should expose boss_attack_cued signal for per-attack HUD/SFX hooks")
	else:
		boss.connect("boss_attack_cued", func(status: Dictionary) -> void:
			attack_events.append(status))

	boss.call("summon_phase_traps", 2)
	await process_frame
	if attack_events.is_empty():
		failures.append("boss trap waves should emit boss_attack_cued")
	else:
		var trap_event: Dictionary = attack_events.back()
		if str(trap_event.get("attack", "")) != "trap_wave":
			failures.append("trap attack cue should identify trap_wave attack")
		if not str(trap_event.get("attack_label", "")).contains("Trap"):
			failures.append("trap attack cue should include readable trap label")
		if int(trap_event.get("hazard_count", 0)) < 2:
			failures.append("trap attack cue should include hazard count")
		if int(trap_event.get("attack_sequence_index", 0)) != 1:
			failures.append("first boss attack cue should expose attack_sequence_index 1")
		if str(trap_event.get("previous_attack", "")) != "":
			failures.append("first boss attack cue should not report a previous attack")
		if not str(trap_event.get("recent_attack_summary", "")).contains("Trap Wave"):
			failures.append("boss attack cue should summarize recent readable attacks")
	if not _all_group_children_have_meta_value(boss, "room_traps", "boss_attack", "trap_wave"):
		failures.append("boss traps should store boss_attack metadata")
	var attack_sfx := boss.get_node_or_null("BossAttackSfx") as AudioStreamPlayer
	if attack_sfx == null:
		failures.append("boss trap wave should create attack sound placeholder")
	else:
		if str(attack_sfx.get_meta("boss_attack_sound_id", "")) != "boss_trap_wave":
			failures.append("boss trap wave sound should use boss_trap_wave cue")
		if str(attack_sfx.get_meta("boss_attack", "")) != "trap_wave":
			failures.append("boss attack sound should store attack id metadata")
		if not bool(attack_sfx.get_meta("placeholder_audio_stream", false)):
			failures.append("boss attack sound should use placeholder audio stream")
		if str(attack_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("boss attack sound should come from AudioCueDB")

	attack_events.clear()
	var before_bullets := _child_type_count(scene, "EnemyProjectile")
	boss.call("spawn_bullet_hell", 4)
	await process_frame
	if attack_events.is_empty():
		failures.append("boss bullet hell should emit boss_attack_cued")
	else:
		var bullet_event: Dictionary = attack_events.back()
		if str(bullet_event.get("attack", "")) != "bullet_hell":
			failures.append("bullet attack cue should identify bullet_hell attack")
		if not str(bullet_event.get("attack_label", "")).contains("Bullet"):
			failures.append("bullet attack cue should include readable bullet label")
		if int(bullet_event.get("attack_sequence_index", 0)) != 2:
			failures.append("second boss attack cue should increment attack_sequence_index")
		if str(bullet_event.get("previous_attack", "")) != "trap_wave":
			failures.append("bullet attack cue should report previous trap_wave attack")
		if not str(bullet_event.get("recent_attack_summary", "")).contains("Trap Wave") \
				or not str(bullet_event.get("recent_attack_summary", "")).contains("Bullet Hell"):
			failures.append("boss attack cue should keep a readable recent attack timeline")
		if int(bullet_event.get("projectile_count", 0)) < 4:
			failures.append("bullet attack cue should include projectile count")
		if str(bullet_event.get("pattern_label", "")) == "":
			failures.append("attack cue should include current pattern label")
		if float(bullet_event.get("punish_window_seconds", 0.0)) <= 0.0:
			failures.append("attack cue should include punish window timing")
		if not str(bullet_event.get("safe_window_hint", "")).contains("Punish"):
			failures.append("attack cue should include safe-window punish hint")
		if str(bullet_event.get("current_pattern_step", "")) == "":
			failures.append("attack cue should include current pattern step")
		if str(bullet_event.get("next_pattern_step", "")) == "":
			failures.append("attack cue should include next pattern step")
		if not str(bullet_event.get("pattern_timeline", "")).contains("Next:"):
			failures.append("attack cue should include readable pattern timeline")
		var attack_label := boss.find_child("BossAttackWarning", true, false) as Label
		var expected_count := int(bullet_event.get("projectile_count", 0))
		if attack_label == null:
			failures.append("boss bullet hell should show an in-arena attack warning")
		else:
			if not attack_label.text.contains("Bullet Hell") \
					or not attack_label.text.contains("x%d" % expected_count) \
					or not attack_label.text.contains("Dodge radial bullets"):
				failures.append("boss attack warning label should show label, count, and dodge warning")
			if not attack_label.text.contains("Punish"):
				failures.append("boss attack warning label should show punish timing")
			if not attack_label.text.contains("@") or not attack_label.text.contains("s"):
				failures.append("boss attack warning label should show elapsed attack timing")
			if str(attack_label.get_meta("attack", "")) != "bullet_hell":
				failures.append("boss attack warning should store attack metadata")
			if float(attack_label.get_meta("boss_attack_elapsed_seconds", -1.0)) < 0.0:
				failures.append("boss attack warning should store elapsed attack timing metadata")
			if int(attack_label.get_meta("projectile_count", 0)) != expected_count:
				failures.append("boss attack warning should store projectile count metadata")
			if str(attack_label.get_meta("warning", "")) != "Dodge radial bullets":
				failures.append("boss attack warning should store dodge warning metadata")
			if int(attack_label.get_meta("attack_sequence_index", 0)) != 2:
				failures.append("boss attack warning should store attack sequence metadata")
			if str(attack_label.get_meta("previous_attack", "")) != "trap_wave":
				failures.append("boss attack warning should store previous attack metadata")
			if not str(attack_label.get_meta("recent_attack_summary", "")).contains("Trap Wave"):
				failures.append("boss attack warning should store recent attack summary metadata")
			if str(attack_label.get_meta("counter_hint", "")) == "":
				failures.append("boss attack warning should store counter hint metadata")
			if float(attack_label.get_meta("punish_window_seconds", 0.0)) <= 0.0:
				failures.append("boss attack warning should store punish window metadata")
			if float(attack_label.get_meta("next_attack_seconds", -1.0)) < 0.0:
				failures.append("boss attack warning should store countdown metadata")
			if str(attack_label.get_meta("current_pattern_step", "")) == "":
				failures.append("boss attack warning should store current pattern step metadata")
			if not str(attack_label.get_meta("pattern_timeline", "")).contains("Next:"):
				failures.append("boss attack warning should store readable pattern timeline metadata")
		attack_sfx = boss.get_node_or_null("BossAttackSfx") as AudioStreamPlayer
		if attack_sfx == null:
			failures.append("boss bullet hell should create attack sound placeholder")
		else:
			if str(attack_sfx.get_meta("boss_attack_sound_id", "")) != "boss_bullet_hell":
				failures.append("boss bullet hell sound should use boss_bullet_hell cue")
			if str(attack_sfx.get_meta("boss_attack", "")) != "bullet_hell":
				failures.append("boss bullet hell sound should store attack metadata")
			if int(attack_sfx.get_meta("boss_attack_count", 0)) != expected_count:
				failures.append("boss bullet hell sound should store projectile count metadata")
			if str(attack_sfx.get_meta("boss_attack_warning", "")) != "Dodge radial bullets":
				failures.append("boss bullet hell sound should store readable warning metadata")
			if str(attack_sfx.get_meta("boss_counter_hint", "")) == "":
				failures.append("boss bullet hell sound should store counter hint metadata")
			if float(attack_sfx.get_meta("boss_punish_window_seconds", 0.0)) <= 0.0:
				failures.append("boss bullet hell sound should store punish window metadata")
			if not str(attack_sfx.get_meta("boss_safe_window_hint", "")).contains("Punish"):
				failures.append("boss bullet hell sound should store safe-window hint metadata")
	var status_after_cues: Dictionary = boss.call("boss_status")
	if int(status_after_cues.get("attack_sequence_count", 0)) < 2:
		failures.append("boss_status should expose attack_sequence_count after attack cues")
	if str(status_after_cues.get("last_attack", "")) != "bullet_hell":
		failures.append("boss_status should expose latest attack id")
	if str(status_after_cues.get("previous_attack", "")) != "trap_wave":
		failures.append("boss_status should expose previous attack id")
	if not str(status_after_cues.get("recent_attack_summary", "")).contains("Trap Wave") \
			or not str(status_after_cues.get("recent_attack_summary", "")).contains("Bullet Hell"):
		failures.append("boss_status should expose readable recent attack summary")
	if _child_type_count(scene, "EnemyProjectile") != before_bullets:
		failures.append("boss bullet hell cue should not spawn projectiles before telegraph resolves")
	await _wait_readable_attack_telegraph()
	if not _all_projectiles_have_meta_value(scene, "boss_attack", "bullet_hell"):
		failures.append("boss bullet hell projectiles should store boss_attack metadata")

	scene.queue_free()
	await process_frame

func _check_boss_damage_sources(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := Player.new()
	scene.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	player.global_position = Vector2(24, 0)
	var boss := BossGolem.new()
	boss.max_hp = 100
	boss.hp = 100
	boss.contact_damage = 10
	boss.speed = 0.0
	boss.target = player
	boss.global_position = Vector2.ZERO
	boss.phase = 1
	boss.set("_state", "telegraph")
	boss.set("_state_timer", 0.01)
	scene.add_child(boss)
	await process_frame
	boss.call("_behave", 0.02)
	await process_frame
	var melee_summary := str(player.call("damage_taken_summary"))
	if not melee_summary.contains("Boss: Smash"):
		failures.append("boss smash should record Boss: Smash damage source")

	player.call("record_damage_taken", "Reset Marker", 0)
	var before_hp := player.hp
	boss.call("spawn_bullet_hell", 1)
	await process_frame
	if _first_projectile(scene) != null:
		failures.append("boss bullet source smoke should wait for telegraph before projectile")
	await _wait_readable_attack_telegraph()
	var projectile := _first_projectile(scene)
	if projectile == null:
		failures.append("boss bullet source smoke should spawn a projectile")
	else:
		projectile.call("_on_body_entered", player)
		await process_frame
		if player.hp >= before_hp:
			failures.append("boss projectile source smoke should damage the player")
		var projectile_summary := str(player.call("damage_taken_summary"))
		if not projectile_summary.contains("Boss: Bullet Hell"):
			failures.append("boss bullet projectile should record Boss: Bullet Hell damage source")
	scene.queue_free()
	await process_frame

func _wait_readable_attack_telegraph() -> void:
	await create_timer(0.55).timeout

func _child_group_count(parent: Node, group_name: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.is_in_group(group_name):
			count += 1
	return count

func _child_type_count(parent: Node, class_name_text: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.get_class() == class_name_text or child.get_script() != null \
				and child.get_script().get_global_name() == class_name_text:
			count += 1
	return count

func _child_named(parent: Node, child_name: String) -> Node:
	for child in parent.get_children():
		if child.name == child_name:
			return child
	return null

func _all_group_children_have_meta(parent: Node, group_name: String, meta_key: String) -> bool:
	var saw := false
	for child in parent.get_children():
		if child.is_in_group(group_name):
			saw = true
			if not child.has_meta(meta_key):
				return false
	return saw

func _all_group_children_have_child(parent: Node, group_name: String, child_name: String) -> bool:
	var saw := false
	for child in parent.get_children():
		if child.is_in_group(group_name):
			saw = true
			if child.get_node_or_null(child_name) == null:
				return false
	return saw

func _assert_boss_traps_are_floor_hazards(boss: BossGolem, failures: Array[String]) -> void:
	var traps: Array[Node2D] = []
	for child in boss.get_children():
		if child is Node2D and child.is_in_group("room_traps"):
			traps.append(child)
	if traps.is_empty():
		return
	var first := traps[0]
	var before := first.global_position
	var old_boss_pos := boss.global_position
	boss.global_position += Vector2(32, 12)
	await process_frame
	if not first.top_level:
		failures.append("boss trap waves should set traps top_level so hazards stay on the floor")
	if first.global_position.distance_to(before) > 0.01:
		failures.append("boss trap waves should not move spawned floor hazards with the boss")
	boss.global_position = old_boss_pos

func _boss_traps(boss: BossGolem) -> Array[Node2D]:
	var traps: Array[Node2D] = []
	for child in boss.get_children():
		if child is Node2D and child.is_in_group("room_traps"):
			traps.append(child)
	return traps

func _all_projectiles_have_pattern(parent: Node, pattern_id: String) -> bool:
	var saw := false
	for child in parent.get_children():
		if child.get_class() == "EnemyProjectile" or child.get_script() != null \
				and child.get_script().get_global_name() == "EnemyProjectile":
			saw = true
			if str(child.get_meta("boss_pattern", "")) != pattern_id:
				return false
	return saw

func _all_group_children_have_meta_value(
		parent: Node,
		group_name: String,
		meta_key: String,
		expected: String,
) -> bool:
	var saw := false
	for child in parent.get_children():
		if child.is_in_group(group_name):
			saw = true
			if str(child.get_meta(meta_key, "")) != expected:
				return false
	return saw

func _all_group_children_have_meta_float_at_least(
		parent: Node,
		group_name: String,
		meta_key: String,
		min_value: float,
) -> bool:
	var saw := false
	for child in parent.get_children():
		if child.is_in_group(group_name):
			saw = true
			if float(child.get_meta(meta_key, 0.0)) < min_value:
				return false
	return saw

func _all_projectiles_have_meta_value(parent: Node, meta_key: String, expected: String) -> bool:
	var saw := false
	for child in parent.get_children():
		if child.get_class() == "EnemyProjectile" or child.get_script() != null \
				and child.get_script().get_global_name() == "EnemyProjectile":
			saw = true
			if str(child.get_meta(meta_key, "")) != expected:
				return false
	return saw

func _first_projectile(parent: Node) -> Node:
	for child in parent.get_children():
		if child.get_class() == "EnemyProjectile" or child.get_script() != null \
				and child.get_script().get_global_name() == "EnemyProjectile":
			return child
	return null

func _array_has_text(items: Array, token: String) -> bool:
	for item in items:
		if str(item).contains(token):
			return true
	return false
