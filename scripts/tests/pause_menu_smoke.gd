extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	await _check_pause_input(failures)
	await _check_pause_overlay(failures)
	_check_main_pause_hook(failures)

	if failures.is_empty():
		print("Pause menu smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_pause_input(failures: Array[String]) -> void:
	if not InputMap.has_action("pause_menu"):
		failures.append("project should define pause_menu input action")
		return
	if InputMap.action_get_events("pause_menu").is_empty():
		failures.append("pause_menu should bind at least one key")

func _check_pause_overlay(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame

	if not _has_signal(overlay, "resume_requested"):
		failures.append("pause overlay should expose resume_requested signal")
	if not _has_signal(overlay, "restart_requested"):
		failures.append("pause overlay should expose restart_requested signal")
	if not _has_signal(overlay, "class_select_requested"):
		failures.append("run end overlay should expose class_select_requested signal")
	if not overlay.has_method("show_pause_menu"):
		failures.append("pause overlay should expose show_pause_menu")
	else:
		var resume := {"count": 0}
		var restart := {"count": 0}
		var class_select := {"count": 0}
		overlay.connect("resume_requested", func() -> void:
			resume["count"] += 1)
		overlay.connect("restart_requested", func() -> void:
			restart["count"] += 1)
		if _has_signal(overlay, "class_select_requested"):
			overlay.connect("class_select_requested", func() -> void:
				class_select["count"] += 1)
		var daily_fingerprint := {
			"hash": "daily-abc",
			"floor_index": 2,
			"room_count": 18,
			"spawn_count": 37,
			"boss_variant": "spore_golem",
		}
		overlay.callv("show_pause_menu", [2, "Fungal Depths", "Power Rune x2", "Power Rune -> Dash Spring",
			"Damage / Fire", "Gold 42 | Keys 2 | HP 80/100 | EN 25/50",
			"Sockets 2/3 | Runes Fire x1 / Ice x1 | Socket Upgrades: Split Socket / Aegis Socket",
			"Fire Damage",
			"3 picks | Tier II | Fire Damage",
			"Tier I @1 -> Tier II @3",
			"Perfect 2 | Critical Path 3 | Reward Rooms 4",
			"Internal playtest OK | Public release OK",
			"public_ok",
			0,
			daily_fingerprint])
		await process_frame
		if not overlay.visible:
			failures.append("pause overlay should become visible")
		if not _has_label_containing(overlay, "Fungal Depths"):
			failures.append("pause overlay should show current biome")
		if not _has_label_containing(overlay, "Power Rune x2"):
			failures.append("pause overlay should show build summary")
		if not _has_label_containing(overlay, "Power Rune -> Dash Spring"):
			failures.append("pause overlay should show ordered upgrade history")
		if not _has_label_containing(overlay, "Tags: Damage / Fire"):
			failures.append("pause overlay should show readable build tags")
		if not _has_label_containing(overlay, "Archetype: Fire Damage"):
			failures.append("pause overlay should show readable build archetype")
		var power_arc := overlay.find_child("PausePowerArcSummary", true, false) as Label
		if power_arc == null:
			failures.append("pause overlay should expose power arc summary label")
		else:
			if not power_arc.text.contains("Power Arc: 3 picks | Tier II | Fire Damage"):
				failures.append("pause overlay should show run power arc")
			if str(power_arc.get_meta("run_power_arc", "")) != "3 picks | Tier II | Fire Damage":
				failures.append("pause power arc should keep summary metadata")
		var milestones := overlay.find_child("PausePowerMilestones", true, false) as Label
		if milestones == null:
			failures.append("pause overlay should expose power milestones label")
		else:
			if not milestones.text.contains("Power Milestones: Tier I @1 -> Tier II @3"):
				failures.append("pause overlay should show run power milestones")
			if str(milestones.get_meta("power_milestones", "")) != "Tier I @1 -> Tier II @3":
				failures.append("pause power milestones should keep summary metadata")
		var mastery := overlay.find_child("PauseRoomMasterySummary", true, false) as Label
		if mastery == null:
			failures.append("pause overlay should expose room mastery summary label")
		else:
			if not mastery.text.contains("Mastery: Perfect 2 | Critical Path 3 | Reward Rooms 4"):
				failures.append("pause overlay should show room mastery summary")
			if str(mastery.get_meta("room_mastery_summary", "")) != "Perfect 2 | Critical Path 3 | Reward Rooms 4":
				failures.append("pause room mastery should keep summary metadata")
		var rune_socket := overlay.find_child("PauseRuneSocketSummary", true, false) as Label
		if rune_socket == null:
			failures.append("pause overlay should expose rune/socket summary label")
		elif not rune_socket.text.contains("Sockets 2/3") or not rune_socket.text.contains("Fire x1"):
			failures.append("pause overlay should show rune/socket breakdown")
		var pause_daily := overlay.find_child("PauseDailySeedFingerprint", true, false) as Label
		if pause_daily == null:
			failures.append("pause overlay should expose Daily Seed fingerprint label")
		else:
			if not pause_daily.text.contains("Daily Fingerprint: Hash daily-abc | Floor 2 | Rooms 18 | Spawns 37 | Boss spore_golem"):
				failures.append("pause overlay should show shareable Daily Seed fingerprint")
			if str(pause_daily.get_meta("daily_fingerprint_hash", "")) != "daily-abc":
				failures.append("pause Daily Seed fingerprint should keep hash metadata")
			if int(pause_daily.get_meta("daily_fingerprint_floor", 0)) != 2:
				failures.append("pause Daily Seed fingerprint should keep floor metadata")
			if int(pause_daily.get_meta("daily_fingerprint_room_count", 0)) != 18:
				failures.append("pause Daily Seed fingerprint should keep room count metadata")
			if int(pause_daily.get_meta("daily_fingerprint_spawn_count", 0)) != 37:
				failures.append("pause Daily Seed fingerprint should keep spawn count metadata")
			if str(pause_daily.get_meta("daily_fingerprint_boss_variant", "")) != "spore_golem":
				failures.append("pause Daily Seed fingerprint should keep boss variant metadata")
		var long_history := "Power Rune -> Dash Spring -> Ember Rune -> Frost Rune -> Storm Rune -> Vital Core -> Lucky Coin -> Aegis Socket"
		overlay.show_pause_menu(2, "Fungal Depths", "Power Rune x2", long_history,
			"Damage / Fire", "Gold 42 | Keys 2 | HP 80/100 | EN 25/50")
		await process_frame
		var history_label := overlay.find_child("PauseBuildHistory", true, false) as Label
		if history_label == null:
			failures.append("pause overlay should expose build history label")
		else:
			if not history_label.text.contains("Recent 6/8"):
				failures.append("long pause history should show recent count")
			if history_label.text.contains("Power Rune -> Dash Spring"):
				failures.append("long pause history should compact old picks out of visible text")
			if not history_label.has_meta("full_history"):
				failures.append("pause history label should keep full history metadata")
		if overlay.find_child("PauseRunSnapshotLabel", true, false) == null:
			failures.append("pause overlay should expose a run snapshot label")
		if not _has_label_containing(overlay, "Gold 42 | Keys 2 | HP 80/100 | EN 25/50"):
			failures.append("pause overlay should show current run resources")
		var release_audit := overlay.find_child("PauseReleaseAuditSummary", true, false) as Label
		if release_audit == null:
			failures.append("pause overlay should expose release audit summary label")
		else:
			if not release_audit.text.contains("Internal playtest") \
					or not release_audit.text.contains("Public release"):
				failures.append("pause release audit should show internal/public release readiness")
			if str(release_audit.get_meta("public_release_decision", "")) != "public_ok":
				failures.append("pause release audit should keep public release decision metadata")
			if int(release_audit.get_meta("replace_before_public_count", -1)) != 0:
				failures.append("pause release audit should report zero replacement blockers")
		var release_backlog := overlay.find_child("PauseReleaseBacklogSummary", true, false) as Label
		if release_backlog == null:
			failures.append("pause overlay should expose release replacement backlog summary label")
		else:
			if release_backlog.text != "No replacement backlog":
				failures.append("pause replacement backlog should show when public-release asset work is clear")
			if int(release_backlog.get_meta("replacement_backlog_count", -1)) != 0:
				failures.append("pause replacement backlog should keep zero backlog count metadata")
		var release_next := overlay.find_child("PauseReleaseNextAction", true, false) as Label
		if release_next == null:
			failures.append("pause overlay should expose release next action label")
		else:
			if not release_next.text.contains("Next Action:") \
					or not release_next.text.contains("Release gate clear"):
				failures.append("pause release next action should show clear release gate status")
			if not release_next.has_meta("release_next_action"):
				failures.append("pause release next action should keep full action metadata")
		var playtest_objective := overlay.find_child("PausePlaytestObjective", true, false) as Label
		if playtest_objective == null:
			failures.append("pause overlay should expose playtest objective label")
		else:
			for token in ["Playtest Objective", "Current", "Target", "Pace"]:
				if not playtest_objective.text.contains(token):
					failures.append("pause playtest objective missing token: %s" % token)
			if not playtest_objective.has_meta("playtest_objective"):
				failures.append("pause playtest objective should keep full objective metadata")
		var tuning_patch := overlay.find_child("PauseTuningPatchPreview", true, false) as Label
		if tuning_patch == null:
			failures.append("pause overlay should expose tuning patch preview label")
		else:
			for token in ["Tuning Patch: None", "Evidence ready"]:
				if not tuning_patch.text.contains(token):
					failures.append("pause tuning patch preview missing token: %s" % token)
			if not tuning_patch.has_meta("tuning_patch"):
				failures.append("pause tuning patch preview should keep full patch metadata")
		var resume_button := overlay.find_child("PauseResume", true, false) as Button
		var restart_button := overlay.find_child("PauseRestart", true, false) as Button
		var class_select_button := overlay.find_child("PauseClassSelect", true, false) as Button
		if resume_button == null:
			failures.append("pause overlay should create resume button")
		else:
			resume_button.emit_signal("pressed")
			await process_frame
			if int(resume["count"]) != 1:
				failures.append("pause resume button should emit resume_requested")
			var sfx := overlay.get_node_or_null("OverlayActionSfx") as AudioStreamPlayer
			if sfx == null:
				failures.append("pause resume should create overlay action sound placeholder")
			else:
				if str(sfx.get_meta("overlay_sound_id", "")) != "overlay_resume":
					failures.append("pause resume sound should expose resume cue id")
				if str(sfx.get_meta("overlay_action", "")) != "resume":
					failures.append("pause resume sound should store action metadata")
				if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
					failures.append("pause resume sound should come from AudioCueDB")
				if sfx.stream == null:
					failures.append("pause resume sound should assign an audio stream")
				if DisplayServer.get_name() == "headless" \
						and not bool(sfx.get_meta("headless_playback_skipped", false)):
					failures.append("pause resume sound should skip playback in headless smoke")
		if restart_button == null:
			failures.append("pause overlay should create restart button")
		else:
			restart_button.emit_signal("pressed")
			await process_frame
			if int(restart["count"]) != 1:
				failures.append("pause restart button should emit restart_requested")
			var sfx := overlay.get_node_or_null("OverlayActionSfx") as AudioStreamPlayer
			if sfx == null:
				failures.append("pause restart should create overlay action sound placeholder")
			else:
				if str(sfx.get_meta("overlay_sound_id", "")) != "overlay_restart":
					failures.append("pause restart sound should expose restart cue id")
				if str(sfx.get_meta("overlay_action", "")) != "restart":
					failures.append("pause restart sound should store action metadata")
		if class_select_button == null:
			failures.append("pause overlay should create class select button")
		else:
			class_select_button.emit_signal("pressed")
			await process_frame
			if int(class_select["count"]) != 1:
				failures.append("pause class select button should emit class_select_requested")
			var sfx := overlay.get_node_or_null("OverlayActionSfx") as AudioStreamPlayer
			if sfx == null:
				failures.append("pause class select should create overlay action sound placeholder")
			else:
				if str(sfx.get_meta("overlay_sound_id", "")) != "overlay_class_select":
					failures.append("pause class select sound should expose class select cue id")
				if str(sfx.get_meta("overlay_action", "")) != "class_select":
					failures.append("pause class select sound should store action metadata")
		overlay.show_pause_menu(2, "Fungal Depths", "Power Rune x2")
		await process_frame
		if not _press_key(overlay, KEY_ESCAPE):
			failures.append("pause overlay should handle keyboard shortcuts")
		else:
			await process_frame
			if int(resume["count"]) != 2:
				failures.append("pressing Escape should emit resume_requested")
		overlay.show_pause_menu(2, "Fungal Depths", "Power Rune x2")
		await process_frame
		_press_key(overlay, KEY_R)
		await process_frame
		if int(restart["count"]) != 2:
			failures.append("pressing R in pause menu should emit restart_requested")
		overlay.show_pause_menu(2, "Fungal Depths", "Power Rune x2")
		await process_frame
		_press_key(overlay, KEY_C)
		await process_frame
		if int(class_select["count"]) != 2:
			failures.append("pressing C in pause menu should emit class_select_requested")
		overlay.show_message("YOU DIED", "Press R to retry")
		await process_frame
		var run_end_sfx := overlay.get_node_or_null("RunEndSfx") as AudioStreamPlayer
		if run_end_sfx == null:
			failures.append("run defeat overlay should create run end sound placeholder")
		else:
			if str(run_end_sfx.get_meta("run_end_sound_id", "")) != "run_defeat":
				failures.append("run defeat sound should expose defeat cue id")
			if str(run_end_sfx.get_meta("run_end_result", "")) != "defeat":
				failures.append("run defeat sound should store defeat result metadata")
			if str(run_end_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("run defeat sound should come from AudioCueDB")
			if run_end_sfx.stream == null:
				failures.append("run defeat sound should assign an audio stream")
			if DisplayServer.get_name() == "headless" \
					and not bool(run_end_sfx.get_meta("headless_playback_skipped", false)):
				failures.append("run defeat sound should skip playback in headless smoke")
		var run_end_restart := overlay.find_child("RunEndRestart", true, false) as Button
		if run_end_restart == null:
			failures.append("run end overlay should create a clickable restart button")
		else:
			run_end_restart.emit_signal("pressed")
			await process_frame
			if int(restart["count"]) != 3:
				failures.append("run end restart button should emit restart_requested")
			var sfx := overlay.get_node_or_null("OverlayActionSfx") as AudioStreamPlayer
			if sfx == null:
				failures.append("run end restart should create overlay action sound placeholder")
			elif str(sfx.get_meta("overlay_sound_id", "")) != "overlay_restart":
				failures.append("run end restart sound should expose restart cue id")
		var run_end_class_select := overlay.find_child("RunEndClassSelect", true, false) as Button
		if run_end_class_select == null:
			failures.append("run end overlay should create a clickable class select button")
		else:
			run_end_class_select.emit_signal("pressed")
			await process_frame
			if int(class_select["count"]) != 3:
				failures.append("run end class select button should emit class_select_requested")
			var sfx := overlay.get_node_or_null("OverlayActionSfx") as AudioStreamPlayer
			if sfx == null:
				failures.append("run end class select should create overlay action sound placeholder")
			else:
				if str(sfx.get_meta("overlay_sound_id", "")) != "overlay_class_select":
					failures.append("run end class select sound should expose class select cue id")
				if str(sfx.get_meta("overlay_action", "")) != "class_select":
					failures.append("run end class select sound should store action metadata")
		overlay.show_message("YOU DIED", "Press R to retry")
		await process_frame
		_press_key(overlay, KEY_R)
		await process_frame
		if int(restart["count"]) != 4:
			failures.append("pressing R on run end should emit restart_requested")
		_press_key(overlay, KEY_C)
		await process_frame
		if int(class_select["count"]) != 4:
			failures.append("pressing C on run end should emit class_select_requested")
		overlay.show_message("RUN COMPLETE!", "Victory")
		await process_frame
		run_end_sfx = overlay.get_node_or_null("RunEndSfx") as AudioStreamPlayer
		if run_end_sfx == null:
			failures.append("run victory overlay should create run end sound placeholder")
		elif str(run_end_sfx.get_meta("run_end_sound_id", "")) != "run_victory" \
				or str(run_end_sfx.get_meta("run_end_result", "")) != "victory":
			failures.append("run victory sound should expose victory cue metadata")

	overlay.queue_free()
	await process_frame

func _check_main_pause_hook(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("pause_menu"):
		failures.append("Main should handle pause_menu input")
	if not source.contains("resume_requested"):
		failures.append("Main should listen for pause resume")
	if not source.contains("class_select_requested.connect(_on_class_select_requested)"):
		failures.append("Main should listen for run-end class select")
	if not source.contains("func _on_class_select_requested"):
		failures.append("Main should expose run-end class select handler")
	if not source.contains("show_pause_menu"):
		failures.append("Main should show pause menu overlay")
	if not source.contains("upgrade_history_summary"):
		failures.append("Main should pass upgrade history into pause menu")
	if not source.contains("upgrade_tag_summary"):
		failures.append("Main should pass readable build tags into pause menu")
	if not source.contains("build_archetype_summary"):
		failures.append("Main should pass readable build archetype into pause menu")
	if not source.contains("_pause_run_snapshot()"):
		failures.append("Main should pass resource snapshot into pause menu")
	if not source.contains("rune_socket_summary"):
		failures.append("Main should pass rune/socket summary into pause menu")
	if not source.contains("run_power_arc_summary"):
		failures.append("Main should pass run power arc into pause menu")
	if not source.contains("power_milestone_summary"):
		failures.append("Main should pass power milestones into pause menu")
	if not source.contains("_room_mastery_summary()"):
		failures.append("Main should pass room mastery into pause menu")
	if not source.contains("ReleaseAuditScript.summary_text()"):
		failures.append("Main should pass release audit summary into pause menu")
	if not source.contains("_daily_seed_fingerprint_context()"):
		failures.append("Main should pass Daily Seed fingerprint into pause menu")

func _has_signal(node: Object, signal_name: String) -> bool:
	for info in node.get_signal_list():
		if str(info.get("name", "")) == signal_name:
			return true
	return false

func _press_key(node: Node, keycode: int) -> bool:
	if not node.has_method("_unhandled_input"):
		return false
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	node.call("_unhandled_input", event)
	return true

func _has_label_containing(parent: Node, text: String) -> bool:
	for child in parent.find_children("*", "Label", true, false):
		if str(child.text).contains(text):
			return true
	return false
