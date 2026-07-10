extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")

func _init() -> void:
	var failures: Array[String] = []

	await _check_class_select_meta_shop(failures)
	await _check_class_select_replay_last_run(failures)
	await _check_class_select_active_bonus_summary(failures)

	if failures.is_empty():
		print("Meta shop UI smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_class_select_meta_shop(failures: Array[String]) -> void:
	var save_path := MetaProgressionScript.SAVE_PATH
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var seeded_meta := MetaProgressionScript.default_data()
	seeded_meta["banked_gold"] = 100
	seeded_meta["soul_shards"] = 8
	seeded_meta["element_cores"] = 1
	seeded_meta["rune_dust"] = 6
	seeded_meta["blueprints"] = 1
	seeded_meta["runs_finished"] = 1
	seeded_meta["victories"] = 1
	seeded_meta["last_result"] = "victory"
	seeded_meta["last_floor"] = 3
	seeded_meta["best_floor"] = 3
	seeded_meta["current_win_streak"] = 1
	seeded_meta["best_win_streak"] = 1
	seeded_meta["last_seed"] = 20260705
	seeded_meta["last_seed_label"] = "Daily Seed"
	seeded_meta["last_class"] = "Blade Warden"
	seeded_meta["last_element"] = "fire"
	seeded_meta["last_mode"] = "Boss Rush"
	seeded_meta["last_path"] = "Path: Entrance -> Combat -> Boss"
	seeded_meta["last_build_archetype"] = "Fire Duelist"
	seeded_meta["last_build_summary"] = "Power Rune x2, Dash Spring"
	seeded_meta["last_build_tags"] = "damage/fire/dash"
	seeded_meta["last_daily_seed"] = 20260705
	seeded_meta["last_daily_fingerprint_hash"] = "daily-abc"
	seeded_meta["last_daily_fingerprint"] = {
		"hash": "daily-abc",
		"floor_index": 3,
		"room_count": 19,
		"spawn_count": 42,
		"boss_variant": "forge_golem",
	}
	seeded_meta["daily_seed_attempts"] = 1
	seeded_meta["daily_seed_victories"] = 1
	seeded_meta["last_rewards"] = {
		"gold": 80,
		"soul_shards": 3,
		"element_cores": 1,
		"rune_dust": 2,
		"blueprints": 1,
		"challenge_bonus": "+12 gold, Dust +2",
	}
	seeded_meta["class_records"] = {
		"blade_warden": {
			"label": "Blade Warden",
			"runs": 2,
			"victories": 1,
			"best_floor": 3,
			"best_seed": 20260705,
		},
	}
	seeded_meta["mode_records"] = {
		"boss_rush": {
			"label": "Boss Rush",
			"runs": 1,
			"victories": 1,
			"best_floor": 3,
			"best_seed": 20260705,
		},
	}
	seeded_meta["element_records"] = {
		"fire": {
			"label": "Fire",
			"runs": 2,
			"victories": 1,
			"best_floor": 3,
			"best_seed": 20260705,
		},
	}
	seeded_meta["biome_records"] = {
		"ember_forge": {
			"label": "Ember Forge",
			"runs": 1,
			"victories": 1,
			"best_floor": 3,
			"best_seed": 20260705,
			"last_boss_variant": "forge_golem",
		},
	}
	seeded_meta["boss_records"] = {
		"forge_golem": {
			"label": "Forge Golem",
			"biome_id": "ember_forge",
			"biome": "Ember Forge",
			"runs": 1,
			"victories": 1,
			"best_floor": 3,
			"best_seed": 20260705,
		},
	}
	seeded_meta["recent_runs"] = [
		{
			"result": "victory",
			"floor": 3,
			"seed": 20260705,
			"seed_label": "Daily Seed",
			"daily_fingerprint_hash": "daily-abc",
			"daily_fingerprint": {
				"hash": "daily-abc",
				"floor_index": 3,
				"room_count": 19,
				"spawn_count": 42,
				"boss_variant": "cave_golem",
			},
			"class": "Blade Warden",
			"element": "fire",
			"mode": "Boss Rush",
			"path": "Path: Entrance -> Combat -> Boss",
			"biome_id": "ancient_cave",
			"boss_variant": "cave_golem",
			"boss": "Golem Thuc Tinh",
			"archetype": "Fire Duelist",
			"build": "Power Rune x2, Dash Spring",
			"tags": "damage/fire/dash",
			"banked_gold": 5,
			"soul_shards": 4,
			"rune_dust": 2,
			"challenge_bonus": "+12 gold, Dust +2",
			"pace": "Avg 12.5s | Boss 85.0s | Target 2 | Slow 1",
			"pace_timed_rooms": 3,
			"pace_avg_sec": 12.5,
			"pace_boss_sec": 85.0,
			"pace_slowest_sec": 85.0,
			"pace_slowest_room": "Boss",
			"pace_fast_count": 0,
			"pace_target_count": 2,
			"pace_slow_count": 1,
			"economy_gold_earned": 64,
			"economy_soul_shards": 4,
			"economy_element_cores": 1,
			"economy_rune_dust": 6,
			"economy_blueprints": 1,
			"decision_reward_picks": 3,
			"decision_reward_skips": 1,
			"decision_reward_rerolls": 2,
			"decision_shop_buys": 2,
			"decision_shop_leaves": 1,
			"release_decision": "blocked",
			"release_replacements": 1,
			"release_next_action": "Next Action: Fix collision:breakable_prop | add_or_fix_collision_polygon_before_public",
			"playtest_objective": "Playtest Objective: P1 cave_golem_boss boss_ttk | Current 85.0s | Target 120.0-240.0s | RunSummary Pace boss clear time",
			"tuning_patch": "Tuning Patch: P1 cave_golem_boss | test 1.41x boss_effective_hp_or_phase_downtime | Evidence required: RunSummary Pace boss clear time",
		},
		{
			"result": "defeat",
			"floor": 2,
			"seed": 20260704,
			"seed_label": "Seed",
			"class": "Ranger",
			"element": "ice",
			"mode": "Normal",
			"banked_gold": 3,
			"pace_avg_sec": 15.5,
			"pace_boss_sec": 75.0,
			"economy_gold_earned": 56,
			"decision_reward_picks": 2,
			"decision_reward_skips": 0,
			"decision_reward_rerolls": 0,
			"decision_shop_buys": 1,
			"decision_shop_leaves": 0,
		},
	]
	MetaProgressionScript.save_data(seeded_meta, MetaProgressionScript.SAVE_PATH)

	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame

	await _check_hub_services(screen, failures)

	var boss_rush_button := screen.find_child("RunMode_BossRush", true, false) as Button
	if boss_rush_button == null:
		failures.append("class select should expose boss rush mode button")
	else:
		boss_rush_button.emit_signal("pressed")
		await process_frame
		_expect_class_select_sfx(
			screen,
			"select_mode",
			"mode_select",
			"class_select_run_mode",
			"boss_rush",
			failures)
		_check_run_mode_preview(screen, failures)

	var label := screen.find_child("MetaBankLabel", true, false) as Label
	if label == null:
		failures.append("class select should show meta bank label")
	elif not label.text.contains("100"):
		failures.append("meta bank label should show current banked gold")
	elif not label.text.contains("8") or not label.text.contains("1") or not label.text.contains("6"):
		failures.append("meta bank label should show non-gold meta currencies")
	elif not label.text.contains("Best F3") or not label.text.contains("Streak 1"):
		failures.append("meta bank label should show best floor and win streak")
	elif not label.text.contains("Daily Seed 20260705") or not label.text.contains("Blade Warden") \
			or not label.text.contains("Boss Rush"):
		failures.append("meta bank label should show last run record and mode")
	elif not label.text.contains("Daily 1/1"):
		failures.append("meta bank label should show daily seed win/attempt record")
	var last_run := screen.find_child("LastRunSummaryLabel", true, false) as Label
	if last_run == null:
		failures.append("class select should expose last run recap label")
	else:
		for token in [
			"Last Run:",
			"Victory F3",
			"Daily Seed 20260705",
			"Daily Hash daily-abc",
			"Rooms 19",
			"Spawns 42",
			"Blade Warden/fire",
			"Boss Rush",
			"Rewards:",
			"+80g",
			"Shard +3",
			"Core +1",
			"Dust +2",
			"BP +1",
			"Challenge +12 gold, Dust +2",
			"Entrance -> Combat -> Boss",
			"Build: Fire Duelist",
			"Power Rune x2",
			"damage/fire/dash",
		]:
			if not last_run.text.contains(token):
				failures.append("last run recap missing token: %s" % token)
		if str(last_run.get_meta("last_run_seed", "")) != "20260705":
			failures.append("last run recap should expose seed metadata")
		if str(last_run.get_meta("last_run_result", "")) != "victory":
			failures.append("last run recap should expose result metadata")
		if str(last_run.get_meta("last_daily_fingerprint_hash", "")) != "daily-abc":
			failures.append("last run recap should expose Daily Seed fingerprint metadata")
	screen.set("_selected_class", "blade_warden")
	screen.call("_update")
	await process_frame
	var class_record := screen.find_child("ClassDetailRecord", true, false) as Label
	if class_record == null:
		failures.append("class detail should expose selected class record")
	elif not class_record.text.contains("Runs 2") or not class_record.text.contains("Wins 1") \
			or not class_record.text.contains("Best F3") or not class_record.text.contains("Seed 20260705"):
		failures.append("class detail should show selected class run record")
	var class_skills := screen.find_child("ClassDetailSkills", true, false) as Label
	if class_skills == null:
		failures.append("class detail should expose selected class skill preview")
	elif not class_skills.text.contains("Wind Edge") or not class_skills.text.contains("Cost 20") \
			or not class_skills.text.contains("CD 6.0s") or not class_skills.text.contains("Lunge") \
			or not class_skills.text.contains("Phantom Slash") or not class_skills.text.contains("Charge 100") \
			or class_skills.text.contains("wind_edge"):
		failures.append("class detail should show readable skill names, costs, cooldowns, and ultimate charge")
	var hp_button := screen.find_child("MetaBuy_training_hp", true, false) as Button
	if hp_button == null:
		failures.append("class select should expose training_hp buy button")
	else:
		if not hp_button.text.contains("Next:") or not hp_button.text.contains("+10 HP"):
			failures.append("meta buy button should preview next level benefit")
		hp_button.emit_signal("pressed")
		await process_frame
		var meta := MetaProgressionScript.load_data()
		if int(meta.get("banked_gold", 0)) != 70:
			failures.append("training_hp button should spend 30 banked gold")
		if int(meta.get("upgrades", {}).get("training_hp", 0)) != 1:
			failures.append("training_hp button should buy one level")
		if label != null and not label.text.contains("70"):
			failures.append("meta bank label should refresh after buying")
		_expect_class_select_sfx(
			screen,
			"meta_buy",
			"meta_buy",
			"class_select_upgrade_id",
			"training_hp",
			failures)
	var core_button := screen.find_child("MetaBuy_core_affinity", true, false) as Button
	if core_button == null:
		failures.append("class select should expose core_affinity buy button")
	elif not core_button.text.contains("Core") or not core_button.text.contains("Shard"):
		failures.append("core_affinity button should show multi-currency cost")
	else:
		core_button.emit_signal("pressed")
		await process_frame
		var meta_after_core := MetaProgressionScript.load_data()
		if int(meta_after_core.get("element_cores", 0)) != 0:
			failures.append("core_affinity button should spend element core")
		if int(meta_after_core.get("soul_shards", 0)) != 4:
			failures.append("core_affinity button should spend soul shards")
		if int(meta_after_core.get("upgrades", {}).get("core_affinity", 0)) != 1:
			failures.append("core_affinity button should buy one level")
	var key_button := screen.find_child("MetaBuy_starter_key", true, false) as Button
	if key_button == null:
		failures.append("class select should expose starter_key buy button")
	elif not key_button.text.contains("Key") or not key_button.text.contains("Dust"):
		failures.append("starter_key button should show key benefit and dust cost")
	var gold_button := screen.find_child("MetaBuy_gold_pouch", true, false) as Button
	if gold_button == null:
		failures.append("class select should expose gold_pouch buy button")
	elif not gold_button.text.contains("Gold") or not gold_button.text.contains("Shard"):
		failures.append("gold_pouch button should show starting gold benefit and shard cost")
	var revive_button := screen.find_child("MetaBuy_revive_charm", true, false) as Button
	if revive_button == null:
		failures.append("class select should expose revive_charm buy button")
	elif not revive_button.text.contains("Revive") or not revive_button.text.contains("Core"):
		failures.append("revive_charm button should show second chance benefit and core cost")
	if hp_button != null:
		hp_button.emit_signal("pressed")
		await process_frame
		hp_button.emit_signal("pressed")
		await process_frame
		var after_max := MetaProgressionScript.load_data()
		if int(after_max.get("upgrades", {}).get("training_hp", 0)) != MetaProgressionScript.upgrade_max_level("training_hp"):
			failures.append("training_hp button should stop at max level")
		if not hp_button.disabled:
			failures.append("maxed meta upgrade button should be disabled")
		if not hp_button.text.contains("MAX"):
			failures.append("maxed meta upgrade button should show MAX")
	var reset_button := screen.find_child("MetaResetProfile", true, false) as Button
	var meta_status := screen.find_child("MetaStatusLabel", true, false) as Label
	if reset_button == null:
		failures.append("class select should expose reset profile button")
	elif not reset_button.text.contains("RESET"):
		failures.append("reset profile button should use an explicit destructive label")
	else:
		if str(reset_button.get_meta("meta_input_action", "")) != "reset_profile":
			failures.append("reset profile button should expose reset_profile input metadata")
		if not reset_button.tooltip_text.contains("Reset") or not reset_button.tooltip_text.contains("profile"):
			failures.append("reset profile button should expose destructive action tooltip")
		reset_button.emit_signal("pressed")
		await process_frame
		var after_first_press := MetaProgressionScript.load_data()
		if int(after_first_press.get("banked_gold", 0)) == 0:
			failures.append("first reset press should ask for confirmation, not erase")
		if meta_status == null or not meta_status.text.contains("again"):
			failures.append("first reset press should show confirmation text")
		_expect_class_select_sfx(
			screen,
			"meta_reset_warn",
			"meta_warn",
			"class_select_reset_pending",
			"true",
			failures)
		reset_button.emit_signal("pressed")
		await process_frame
		var after_reset := MetaProgressionScript.load_data()
		if int(after_reset.get("banked_gold", -1)) != 0:
			failures.append("confirmed reset should clear banked gold")
		if int(after_reset.get("soul_shards", -1)) != 0:
			failures.append("confirmed reset should clear soul shards")
		if not after_reset.get("upgrades", {}).is_empty():
			failures.append("confirmed reset should clear upgrades")
		if label != null and not label.text.contains("Bank: 0g"):
			failures.append("reset should refresh meta bank label")
		_expect_class_select_sfx(
			screen,
			"meta_reset_confirm",
			"meta_reset",
			"class_select_reset_pending",
			"false",
			failures)

	screen.queue_free()
	await process_frame

func _check_run_mode_preview(screen: ClassSelectScreen, failures: Array[String]) -> void:
	var preview := screen.find_child("RunModePreviewLabel", true, false) as Label
	if preview == null:
		failures.append("class select should expose RunModePreviewLabel")
		return
	for token in ["Boss Rush", "short route", "Boss", "Reward"]:
		if not preview.text.contains(token):
			failures.append("run mode preview missing token: %s" % token)
	if str(preview.get_meta("run_mode_id", "")) != "boss_rush":
		failures.append("run mode preview should expose selected run mode id")
	if str(preview.get_meta("run_mode_label", "")) != "Boss Rush":
		failures.append("run mode preview should expose selected run mode label")
	if str(preview.get_meta("run_mode_difficulty", "")) == "":
		failures.append("run mode preview should expose difficulty metadata")
	if str(preview.get_meta("run_mode_reward_preview", "")) == "":
		failures.append("run mode preview should expose reward metadata")

func _check_class_select_replay_last_run(failures: Array[String]) -> void:
	var seeded_meta := MetaProgressionScript.default_data()
	seeded_meta["runs_finished"] = 1
	seeded_meta["last_seed"] = 20260705
	seeded_meta["last_seed_label"] = "Daily Seed"
	seeded_meta["last_class_id"] = "blade_warden"
	seeded_meta["last_class"] = "Blade Warden"
	seeded_meta["last_element"] = "fire"
	seeded_meta["last_mode"] = "Boss Rush"
	MetaProgressionScript.save_data(seeded_meta, MetaProgressionScript.SAVE_PATH)

	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame

	var replay_button := screen.find_child("ReplayLastRunButton", true, false) as Button
	if replay_button == null:
		failures.append("class select should expose replay last run button")
	else:
		if not replay_button.text.contains("REPLAY"):
			failures.append("replay last run button should use an explicit replay label")
		if str(replay_button.get_meta("replay_input_action", "")) != "replay_last_run":
			failures.append("replay last run button should expose input metadata")
		if int(replay_button.get_meta("replay_seed", 0)) != 20260705:
			failures.append("replay last run button should expose last seed")
		if str(replay_button.get_meta("replay_class_id", "")) != "blade_warden":
			failures.append("replay last run button should expose last class id")
		if str(replay_button.get_meta("replay_element", "")) != "fire":
			failures.append("replay last run button should expose last element")
		if str(replay_button.get_meta("replay_run_mode", "")) != "boss_rush":
			failures.append("replay last run button should expose last run mode")

		var emitted := {"count": 0, "class": "", "element": "", "seed": -1, "mode": ""}
		screen.confirmed.connect(func(class_id: String, element: String, seed: int, mode: String) -> void:
			emitted["count"] = int(emitted["count"]) + 1
			emitted["class"] = class_id
			emitted["element"] = element
			emitted["seed"] = seed
			emitted["mode"] = mode)
		replay_button.emit_signal("pressed")
		await process_frame
		if int(emitted["count"]) != 1:
			failures.append("replay last run button should emit one confirmed run")
		if str(emitted["class"]) != "blade_warden" or str(emitted["element"]) != "fire":
			failures.append("replay last run should emit previous class and element")
		if int(emitted["seed"]) != 20260705:
			failures.append("replay last run should emit previous seed")
		if str(emitted["mode"]) != "boss_rush":
			failures.append("replay last run should emit normalized previous mode")

	if is_instance_valid(screen):
		screen.queue_free()
	await process_frame

func _check_hub_services(screen: ClassSelectScreen, failures: Array[String]) -> void:
	var hub_label := screen.find_child("HubServicesLabel", true, false) as Label
	if hub_label == null:
		failures.append("hub should expose a services label")
	elif not hub_label.text.contains("Hub") or not hub_label.text.contains("Blacksmith") \
			or not hub_label.text.contains("Codex"):
		failures.append("hub services label should name available hub services")
	var expected := {
		"HubService_DungeonGate": {"label": "Dungeon Gate", "service": "DungeonGate", "key": "D", "hotkey": KEY_D},
		"HubService_ClassHall": {"label": "Class Hall", "service": "ClassHall", "key": "H", "hotkey": KEY_H},
		"HubService_TrainingGround": {"label": "Training Ground", "service": "TrainingGround", "key": "T", "hotkey": KEY_T},
		"HubService_Blacksmith": {"label": "Blacksmith", "service": "Blacksmith", "key": "K", "hotkey": KEY_K},
		"HubService_Codex": {"label": "Codex", "service": "Codex", "key": "X", "hotkey": KEY_X},
	}
	for node_name in expected.keys():
		var button := screen.find_child(node_name, true, false) as Button
		var spec: Dictionary = expected[node_name]
		if button == null:
			failures.append("hub should expose %s button" % str(spec.get("label", "")))
			continue
		if not button.text.contains(str(spec.get("label", ""))):
			failures.append("%s button should show readable service name" % str(spec.get("label", "")))
		if str(button.get_meta("hub_service_input_action", "")) != "select_hub_service":
			failures.append("%s button should expose hub service input metadata" % str(spec.get("label", "")))
		if str(button.get_meta("hub_service_id", "")) != str(spec.get("service", "")):
			failures.append("%s button should expose service id metadata" % str(spec.get("label", "")))
		if str(button.get_meta("hub_service_key_label", "")) != str(spec.get("key", "")):
			failures.append("%s button should expose key label %s" % [str(spec.get("label", "")), str(spec.get("key", ""))])
		if int(button.get_meta("hub_service_hotkey", 0)) != int(spec.get("hotkey", 0)):
			failures.append("%s button should expose hotkey metadata" % str(spec.get("label", "")))
		if not button.tooltip_text.contains(str(spec.get("label", ""))) \
				or not button.tooltip_text.contains(str(spec.get("key", ""))):
			failures.append("%s button should expose readable key tooltip" % str(spec.get("label", "")))
	var status := screen.find_child("HubServiceStatusLabel", true, false) as Label
	if status == null:
		failures.append("hub should expose service status copy")
	else:
		var blacksmith := screen.find_child("HubService_Blacksmith", true, false) as Button
		if blacksmith != null:
			blacksmith.emit_signal("pressed")
			await process_frame
			_expect_class_select_sfx(
				screen,
				"hub_service",
				"hub_service",
				"class_select_service_id",
				"Blacksmith",
				failures)
			if not status.text.contains("Rune") or not status.text.contains("Socket"):
				failures.append("blacksmith service status should explain rune/socket upgrades")
			if not status.text.contains("Ready: Rune Stability"):
				failures.append("blacksmith service status should recommend an affordable blacksmith upgrade")
	await _check_hub_service_hotkeys(screen, failures)
	await _check_codex_hub_panel(screen, failures)
	await _check_hub_service_upgrade_filters(screen, failures)

func _check_hub_service_hotkeys(screen: ClassSelectScreen, failures: Array[String]) -> void:
	var status := screen.find_child("HubServiceStatusLabel", true, false) as Label
	var expected := [
		{"key": KEY_T, "service": "TrainingGround", "token": "permanent training"},
		{"key": KEY_K, "service": "Blacksmith", "token": "Rune"},
		{"key": KEY_H, "service": "ClassHall", "token": "ultimate"},
		{"key": KEY_X, "service": "Codex", "token": "records"},
		{"key": KEY_D, "service": "DungeonGate", "token": "enter the run"},
	]
	for item in expected:
		_press_key(screen, int(item["key"]))
		await process_frame
		if str(screen.get("_active_hub_service")) != str(item["service"]):
			failures.append("%s hotkey should select %s hub service" % [
				OS.get_keycode_string(int(item["key"])),
				str(item["service"]),
			])
		if status == null or not status.text.contains(str(item["token"])):
			failures.append("%s hotkey should refresh hub service status" % OS.get_keycode_string(int(item["key"])))
		if str(item["service"]) == "TrainingGround" and status != null \
				and not status.text.contains("Ready: +HP"):
			failures.append("training hotkey should show the next affordable training upgrade")

	var codex_summary := screen.find_child("CodexSummaryLabel", true, false) as Label
	if codex_summary == null:
		failures.append("hub hotkeys should keep codex summary available")
	else:
		_press_key(screen, KEY_X)
		await process_frame
		if not codex_summary.visible:
			failures.append("X hotkey should show codex summary")
		_press_key(screen, KEY_D)
		await process_frame
		if codex_summary.visible:
			failures.append("D hotkey should hide codex summary")

func _check_codex_hub_panel(screen: ClassSelectScreen, failures: Array[String]) -> void:
	var codex := screen.find_child("HubService_Codex", true, false) as Button
	if codex == null:
		failures.append("hub should expose Codex button")
		return
	codex.emit_signal("pressed")
	await process_frame
	var status := screen.find_child("HubServiceStatusLabel", true, false) as Label
	if status == null or not status.text.contains("Codex") or not status.text.contains("elements"):
		failures.append("codex service status should explain elements/classes records")
	var summary := screen.find_child("CodexSummaryLabel", true, false) as Label
	if summary == null:
		failures.append("codex service should expose summary label")
	else:
		for token in ["Classes 10", "Played 1", "Modes 1", "Elements 4",
				"Mastered 1", "Combos 6", "Biomes 5", "Daily 1/1"]:
			if not summary.text.contains(token):
				failures.append("codex summary missing token: %s" % token)
		if not summary.text.contains("Bosses 1"):
			failures.append("codex summary should count boss records")
		for combo_name in ["Thermal Shock", "Plasma", "Deep Freeze"]:
			if not summary.text.contains(combo_name):
				failures.append("codex summary should preview combo %s" % combo_name)
		if not summary.text.contains("Modes: Boss Rush F3 1W/1R Seed 20260705"):
			failures.append("codex summary should preview mode record details")
		if not summary.text.contains("Element Records: Fire F3 1W/2R Seed 20260705"):
			failures.append("codex summary should preview element record details")
		if not summary.text.contains("Biome Records: Ember Forge F3 1W/1R Seed 20260705"):
			failures.append("codex summary should preview biome record details")
		if not summary.text.contains("Boss Records: Forge Golem F3 1W/1R Ember Forge Seed 20260705"):
			failures.append("codex summary should preview boss record details")
		for token in ["Public Gate:", "public_ok", "No replacements required"]:
			if not summary.text.contains(token):
				failures.append("codex summary should expose release gate token: %s" % token)
	var detail := screen.find_child("CodexDetailLabel", true, false) as Label
	if detail == null:
		failures.append("codex service should expose detailed rule label")
	else:
		for token in [
			"Elements:",
			"Fire: burn DoT",
			"Ice: slow",
			"Lightning: stun",
			"Poison: long DoT",
			"Combo Effects:",
			"Thermal Shock: Instant burst damage",
			"Plasma: Vulnerability window",
			"Daily Trials:",
			"Last Run:",
			"Victory F3",
			"Rewards: +80g",
			"Entrance -> Combat -> Boss",
			"Recent Runs:",
			"Victory F3 Fire Boss Rush Seed 20260705 Fire Duelist",
			"Reward +5g Shard +4 Dust +2",
			"Challenge +12 gold, Dust +2",
			"Release blocked Fix x1",
			"Next Fix collision:breakable_prop",
			"Objective P1 cave_golem_boss boss_ttk",
			"Patch P1 cave_golem_boss",
			"Playtest Evidence:",
			"cave_golem_boss",
			"85.0s",
			"Pace Avg 12.5s",
			"Playtest Trend:",
			"Runs 2",
			"Win 1/2",
			"Avg Pace 14.0s",
			"Boss 80.0s",
			"Gold 60.0",
			"Rewards 2.5/0.5",
			"Rerolls 1.0",
			"Shop 1.5/0.5",
			"Glass Edges",
			"Bonus",
			"Best Class:",
			"Blade Warden F3",
			"Best Element:",
			"Fire F3",
			"Best Biome:",
			"Ember Forge F3",
			"Best Boss:",
			"Forge Golem F3",
			"Ember Forge",
			"Release Gate:",
			"Next Action:",
			"Playtest",
			"Tuning Focus",
			"Playtest Objective:",
			"Tuning Patch:",
			"Current",
			"Target",
			"Internal playtest:",
			"Public release:",
			"Frame grid",
			"Collision",
			"Asset Sources:",
			"Fanmade refs: pattern only",
			"Self-review:",
			"No replacement backlog",
		]:
			if not detail.text.contains(token):
				failures.append("codex detail missing token: %s" % token)
		if detail.visible != summary.visible:
			failures.append("codex detail visibility should match codex summary")
		var preview_runs: Array = MetaProgressionScript.load_data().get("recent_runs", [])
		if preview_runs.is_empty():
			failures.append("codex recent preview fixture should include one recent run")
		else:
			var recent_preview := str(screen.call("_recent_run_preview", preview_runs[0]))
			if not recent_preview.contains("Challenge +12 gold, Dust +2"):
				failures.append("codex recent preview should include challenge bonus in reward line")
			if not recent_preview.contains("Daily Hash daily-abc"):
				failures.append("codex recent preview should include Daily Seed fingerprint hash")
			if not recent_preview.contains("Pace Avg 12.5s Boss 85.0s Slow 1"):
				failures.append("codex recent preview should include structured boss pace and slow count")
			if not recent_preview.contains("Decisions R3/S1 RR2 Shop 2/1"):
				failures.append("codex recent preview should include structured reward/shop decisions")
	var hp_button := screen.find_child("MetaBuy_training_hp", true, false) as Button
	if hp_button != null:
		if hp_button.visible:
			failures.append("codex service should hide meta upgrade buttons")
		if str(hp_button.get_meta("hub_service", "")) != "Codex":
			failures.append("codex service should tag meta buttons with active service")

func _check_hub_service_upgrade_filters(screen: ClassSelectScreen, failures: Array[String]) -> void:
	var training := screen.find_child("HubService_TrainingGround", true, false) as Button
	var blacksmith := screen.find_child("HubService_Blacksmith", true, false) as Button
	var class_hall := screen.find_child("HubService_ClassHall", true, false) as Button
	var dungeon_gate := screen.find_child("HubService_DungeonGate", true, false) as Button
	if training == null or blacksmith == null or class_hall == null or dungeon_gate == null:
		return

	training.emit_signal("pressed")
	await process_frame
	_expect_meta_visible(screen, "training_hp", true, "TrainingGround", "training", failures)
	_expect_recommended_meta_upgrade(screen, "training_hp", failures)
	_expect_meta_visible(screen, "training_damage", true, "TrainingGround", "training", failures)
	_expect_meta_visible(screen, "revive_charm", true, "TrainingGround", "training", failures)
	_expect_meta_visible(screen, "rune_stability", false, "TrainingGround", "blacksmith", failures)
	_expect_meta_visible(screen, "blueprint_socket", false, "TrainingGround", "blacksmith", failures)

	blacksmith.emit_signal("pressed")
	await process_frame
	_expect_meta_visible(screen, "rune_stability", true, "Blacksmith", "blacksmith", failures)
	_expect_recommended_meta_upgrade(screen, "rune_stability", failures)
	_expect_meta_visible(screen, "blueprint_socket", true, "Blacksmith", "blacksmith", failures)
	_expect_meta_visible(screen, "starter_key", true, "Blacksmith", "blacksmith", failures)
	_expect_meta_visible(screen, "training_hp", false, "Blacksmith", "training", failures)

	class_hall.emit_signal("pressed")
	await process_frame
	_expect_meta_visible(screen, "core_affinity", true, "ClassHall", "class_hall", failures)
	_expect_meta_visible(screen, "rune_stability", false, "ClassHall", "blacksmith", failures)

	dungeon_gate.emit_signal("pressed")
	await process_frame
	_expect_meta_visible(screen, "training_hp", true, "DungeonGate", "training", failures)
	_expect_meta_visible(screen, "rune_stability", true, "DungeonGate", "blacksmith", failures)

func _expect_meta_visible(
		screen: ClassSelectScreen,
		upgrade_id: String,
		expected_visible: bool,
		expected_service: String,
		expected_category: String,
		failures: Array[String]) -> void:
	var button := screen.find_child("MetaBuy_%s" % upgrade_id, true, false) as Button
	if button == null:
		failures.append("%s button should exist for hub filtering" % upgrade_id)
		return
	if button.visible != expected_visible:
		failures.append("%s should be %s for %s service" % [
			upgrade_id,
			"visible" if expected_visible else "hidden",
			expected_service,
		])
	if str(button.get_meta("hub_service", "")) != expected_service:
		failures.append("%s should store %s hub service metadata" % [upgrade_id, expected_service])
	if str(button.get_meta("hub_category", "")) != expected_category:
		failures.append("%s should store %s hub category metadata" % [upgrade_id, expected_category])
	if str(button.get_meta("meta_input_action", "")) != "buy_hub_upgrade":
		failures.append("%s should expose buy_hub_upgrade input metadata" % upgrade_id)
	if str(button.get_meta("upgrade_id", "")) != upgrade_id:
		failures.append("%s should expose upgrade id metadata" % upgrade_id)
	if not button.tooltip_text.contains(expected_category) or not button.tooltip_text.contains(expected_service):
		failures.append("%s should expose hub service/category tooltip" % upgrade_id)

func _expect_recommended_meta_upgrade(
		screen: ClassSelectScreen,
		upgrade_id: String,
		failures: Array[String]) -> void:
	var button := screen.find_child("MetaBuy_%s" % upgrade_id, true, false) as Button
	if button == null:
		failures.append("%s should exist for recommendation metadata" % upgrade_id)
		return
	if not bool(button.get_meta("recommended_hub_upgrade", false)):
		failures.append("%s should be marked as the recommended hub upgrade" % upgrade_id)
	if not button.text.begins_with("NEXT | "):
		failures.append("%s recommended button should get a NEXT prefix" % upgrade_id)
	if button.focus_mode == Control.FOCUS_NONE:
		failures.append("%s recommended button should stay keyboard-focusable" % upgrade_id)
	if not button.has_focus():
		failures.append("%s recommended button should receive focus for hub navigation" % upgrade_id)

func _expect_class_select_sfx(
		screen: ClassSelectScreen,
		expected_action: String,
		expected_sound_id: String,
		expected_meta_key: String,
		expected_meta_value: String,
		failures: Array[String]) -> void:
	var sfx := screen.get_node_or_null("ClassSelectSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("class select should play %s placeholder sound" % expected_action)
		return
	if str(sfx.get_meta("class_select_action", "")) != expected_action:
		failures.append("class select sound should tag %s action" % expected_action)
	if str(sfx.get_meta("class_select_sound_id", "")) != expected_sound_id:
		failures.append("class select sound should use %s cue" % expected_sound_id)
	if str(sfx.get_meta(expected_meta_key, "")) != expected_meta_value:
		failures.append("class select sound should tag %s=%s" % [
			expected_meta_key,
			expected_meta_value,
		])
	if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
		failures.append("class select sound should come from AudioCueDB")
	if str(sfx.get_meta("audio_cue_kind", "")) != "class_select":
		failures.append("class select sound should tag class_select cue kind")
	if not bool(sfx.get_meta("placeholder_audio_stream", false)):
		failures.append("class select sound should use generated placeholder stream")
	if not bool(sfx.get_meta("playback_requested", false)):
		failures.append("class select sound should request playback")
	if DisplayServer.get_name() == "headless" \
			and not bool(sfx.get_meta("headless_playback_skipped", false)):
		failures.append("class select sound should skip playback in headless smoke")

func _press_key(screen: ClassSelectScreen, keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	if screen.has_method("_unhandled_input"):
		screen.call("_unhandled_input", event)

func _check_class_select_active_bonus_summary(failures: Array[String]) -> void:
	var seeded_meta := MetaProgressionScript.default_data()
	seeded_meta["upgrades"] = {
		"training_hp": 2,
		"training_damage": 1,
		"core_affinity": 1,
		"rune_stability": 1,
		"blueprint_socket": 1,
		"starter_key": 1,
		"gold_pouch": 1,
		"revive_charm": 1,
	}
	MetaProgressionScript.save_data(seeded_meta, MetaProgressionScript.SAVE_PATH)
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	var bonus := screen.find_child("MetaBonusSummaryLabel", true, false) as Label
	if bonus == null:
		failures.append("class select should expose active meta bonus summary")
	else:
		for token in ["Active Bonuses", "+20 HP", "+4% damage", "+3% elemental",
				"-0.04s dash", "+1 projectile", "Key +1", "Gold +10", "Revive x1"]:
			if not bonus.text.contains(token):
				failures.append("active meta bonus summary missing token: %s" % token)
		if str(bonus.get_meta("active_bonus_summary", "")) == "":
			failures.append("active meta bonus summary should store summary metadata")
	screen.queue_free()
	await process_frame
