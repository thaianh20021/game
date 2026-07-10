extends SceneTree

const RunModifierPath := "res://scripts/progression/run_modifier_db.gd"

func _init() -> void:
	var failures: Array[String] = []

	_check_run_modifier_db(failures)
	await _check_hud_run_modifier_feedback(failures)
	_check_run_summary_modifier_context(failures)
	_check_main_wires_daily_modifier(failures)
	_check_floor_controller_modifier_difficulty(failures)
	_check_balance_lab_modifier(failures)

	if failures.is_empty():
		print("Run modifier smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_run_modifier_db(failures: Array[String]) -> void:
	if not ResourceLoader.exists(RunModifierPath):
		failures.append("RunModifierDB script missing")
		return
	var script: Variant = load(RunModifierPath)
	if not script.has_method("all_modifiers"):
		failures.append("RunModifierDB should expose all_modifiers")
	else:
		var all: Array = script.call("all_modifiers")
		if all.size() < 3:
			failures.append("RunModifierDB should include at least three daily challenge modifiers")
	if not script.has_method("daily_modifier_for_seed"):
		failures.append("RunModifierDB should expose daily_modifier_for_seed")
		return
	if not script.has_method("balance_lab_modifier"):
		failures.append("RunModifierDB should expose balance_lab_modifier for opt-in tuning experiments")
	var first: Dictionary = script.call("daily_modifier_for_seed", 20260705)
	var second: Dictionary = script.call("daily_modifier_for_seed", 20260705)
	if first.is_empty():
		failures.append("daily_modifier_for_seed should return a modifier for positive seeds")
	elif str(first.get("id", "")) == "" or str(first.get("name", "")) == "" \
			or str(first.get("desc", "")) == "":
		failures.append("daily modifier should include id, name, and desc")
	if str(first.get("id", "")) != str(second.get("id", "")):
		failures.append("daily modifier should be deterministic for a seed")
	if float(first.get("difficulty_mult", 1.0)) <= 1.0:
		failures.append("daily modifier should increase effective difficulty")
	var goals: Array = first.get("goals", [])
	if goals.size() < 2:
		failures.append("daily modifier should include at least two run goals")
	else:
		for goal in goals:
			if not (goal is Dictionary):
				failures.append("daily modifier goal should be a dictionary")
				continue
			if str(goal.get("id", "")) == "" or str(goal.get("label", "")) == "" \
					or str(goal.get("event", "")) == "" or int(goal.get("target", 0)) <= 0:
				failures.append("daily modifier goals should include id, label, event, and target")
	if not script.has_method("summary"):
		failures.append("RunModifierDB should expose summary")
	else:
		var summary := str(script.call("summary", first))
		if summary == "" or not summary.contains(str(first.get("name", ""))):
			failures.append("RunModifierDB summary should name the modifier")
	if not script.has_method("initial_goal_progress"):
		failures.append("RunModifierDB should expose initial_goal_progress")
	elif not script.has_method("advance_goal_progress"):
		failures.append("RunModifierDB should expose advance_goal_progress")
	elif not script.has_method("goal_progress_summary"):
		failures.append("RunModifierDB should expose goal_progress_summary")
	elif not script.has_method("completed_goal_count"):
		failures.append("RunModifierDB should expose completed_goal_count")
	else:
		var progress: Dictionary = script.call("initial_goal_progress", first)
		if progress.size() != goals.size():
			failures.append("initial goal progress should include every modifier goal")
		var first_goal: Dictionary = goals[0] if not goals.is_empty() else {}
		var event_id := str(first_goal.get("event", ""))
		progress = script.call("advance_goal_progress", first, progress, event_id, 1)
		var goal_state: Dictionary = progress.get(str(first_goal.get("id", "")), {})
		if int(goal_state.get("current", 0)) != 1:
			failures.append("advance_goal_progress should increment matching goal progress")
		var goal_summary := str(script.call("goal_progress_summary", first, progress))
		if not goal_summary.contains(str(first_goal.get("label", ""))) or not goal_summary.contains("/"):
			failures.append("goal_progress_summary should show readable progress")
		var fixture := {
			"goals": [
				{"id": "elite_hunt", "label": "Elite Hunt", "event": "clear_elite", "target": 1},
				{"id": "shopper", "label": "Shop Buy", "event": "buy_shop", "target": 2},
			],
		}
		var fixture_progress: Dictionary = script.call("initial_goal_progress", fixture)
		if int(script.call("completed_goal_count", fixture_progress)) != 0:
			failures.append("new goal progress should start with zero completed goals")
		fixture_progress = script.call("advance_goal_progress", fixture, fixture_progress, "clear_elite", 1)
		if int(script.call("completed_goal_count", fixture_progress)) != 1:
			failures.append("completed_goal_count should count newly completed daily goals")
		if not bool(Dictionary(fixture_progress.get("elite_hunt", {})).get("completed", false)):
			failures.append("advance_goal_progress should mark completed goals")
	if not script.has_method("reward_bonus"):
		failures.append("RunModifierDB should expose reward_bonus")
	elif not script.has_method("reward_bonus_summary"):
		failures.append("RunModifierDB should expose reward_bonus_summary")
	elif not script.has_method("earned_reward_bonus"):
		failures.append("RunModifierDB should expose earned_reward_bonus")
	elif not script.has_method("earned_reward_bonus_summary"):
		failures.append("RunModifierDB should expose earned_reward_bonus_summary")
	else:
		var bonus: Dictionary = script.call("reward_bonus", first)
		if int(bonus.get("gold", 0)) <= 0:
			failures.append("daily challenge bonus should include bonus gold")
		if int(bonus.get("rune_dust", 0)) <= 0:
			failures.append("daily challenge bonus should include rune dust")
		var bonus_summary := str(script.call("reward_bonus_summary", first))
		if not bonus_summary.contains("gold") or not bonus_summary.contains("Dust"):
			failures.append("daily challenge bonus summary should name gold and dust")
		var gated_modifier := {
			"reward_bonus": {"gold": 12, "rune_dust": 2},
			"goals": [
				{"id": "elite_hunt", "label": "Elite Hunt", "event": "clear_elite", "target": 1},
				{"id": "shopper", "label": "Shop Buy", "event": "buy_shop", "target": 1},
			],
		}
		var gated_progress: Dictionary = script.call("initial_goal_progress", gated_modifier)
		gated_progress = script.call("advance_goal_progress", gated_modifier, gated_progress, "clear_elite", 1)
		if not Dictionary(script.call("earned_reward_bonus", gated_modifier, gated_progress)).is_empty():
			failures.append("daily challenge bonus should stay locked until all goals are complete")
		var locked_summary := str(script.call("earned_reward_bonus_summary", gated_modifier, gated_progress))
		if not locked_summary.contains("Locked") or not locked_summary.contains("1/2"):
			failures.append("locked daily challenge bonus summary should show goal completion count")
		gated_progress = script.call("advance_goal_progress", gated_modifier, gated_progress, "buy_shop", 1)
		var earned: Dictionary = script.call("earned_reward_bonus", gated_modifier, gated_progress)
		if int(earned.get("gold", 0)) != 12 or int(earned.get("rune_dust", 0)) != 2:
			failures.append("daily challenge bonus should unlock when all goals are complete")
		var earned_summary := str(script.call("earned_reward_bonus_summary", gated_modifier, gated_progress))
		if not earned_summary.contains("Earned") or not earned_summary.contains("gold"):
			failures.append("earned daily challenge bonus summary should show unlocked reward")

	if script.has_method("balance_lab_modifier"):
		var patch := {
			"enabled": true,
			"id": "cave_golem_boss",
			"biome": "ancient_cave",
			"boss_variant": "cave_golem",
			"hp_multiplier": 1.25,
			"source": "playtest_evidence",
		}
		var lab: Dictionary = script.call("balance_lab_modifier", patch)
		if str(lab.get("id", "")) != "balance_lab":
			failures.append("balance_lab_modifier should return balance_lab id")
		if str(lab.get("name", "")) != "Balance Lab":
			failures.append("balance_lab_modifier should name the opt-in tuning run")
		if not str(lab.get("desc", "")).contains("cave_golem_boss") \
				or not str(lab.get("desc", "")).contains("1.25x"):
			failures.append("balance_lab_modifier should describe the boss tuning multiplier")
		if Dictionary(lab.get("boss_tuning_patch", {})).get("id", "") != "cave_golem_boss":
			failures.append("balance_lab_modifier should carry the boss tuning patch")
		if Array(lab.get("tags", [])).has("daily"):
			failures.append("balance_lab_modifier should not count as a daily challenge")
		if not Array(lab.get("tags", [])).has("balance") \
				or not Array(lab.get("tags", [])).has("playtest"):
			failures.append("balance_lab_modifier should tag the run as balance playtest")
		if not Dictionary(script.call("balance_lab_modifier", {
			"enabled": false,
			"requires_playtest_evidence": true,
		})).is_empty():
			failures.append("balance_lab_modifier should stay empty until evidence enables a patch")

func _check_hud_run_modifier_feedback(failures: Array[String]) -> void:
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	var modifier_label := hud.get_node_or_null("RunModifierLabel") as Label
	if modifier_label == null:
		failures.append("HUD should expose RunModifierLabel")
	var modifier_goal_label := hud.get_node_or_null("RunModifierGoalLabel") as Label
	if modifier_goal_label == null:
		failures.append("HUD should expose RunModifierGoalLabel")
	if not hud.has_method("set_run_seed_label"):
		failures.append("HUD should expose set_run_seed_label")
	else:
		hud.call("set_run_seed_label", "Daily Seed")
		hud.call("set_run_seed", 20260705)
		await process_frame
		var seed_label := hud.get_node_or_null("RunSeedLabel") as Label
		if seed_label == null or not seed_label.text.contains("Daily Seed: 20260705"):
			failures.append("HUD seed label should support Daily Seed wording")
	if not hud.has_method("set_run_modifier"):
		failures.append("HUD should expose set_run_modifier")
	else:
		hud.call("set_run_modifier", {
			"id": "glass_edges",
			"name": "Glass Edges",
			"desc": "Enemies scale +12%",
			"difficulty_mult": 1.12,
			"goals": [
				{"id": "elite_hunt", "label": "Elite Hunt", "event": "clear_elite", "target": 1},
				{"id": "shopper", "label": "Shop Buy", "event": "buy_shop", "target": 1},
			],
		})
		await process_frame
		modifier_label = hud.get_node_or_null("RunModifierLabel") as Label
		if modifier_label == null or not modifier_label.text.contains("Challenge: Glass Edges"):
			failures.append("HUD should show active daily challenge modifier")
		elif not modifier_label.text.contains("Enemies scale +12%"):
			failures.append("HUD challenge label should include modifier effect")
	if not hud.has_method("set_run_modifier_goals"):
		failures.append("HUD should expose set_run_modifier_goals")
	else:
		hud.call("set_run_modifier_goals", "Goals: Elite Hunt 1/1 | Shop Buy 0/1", {
			"elite_hunt": {"current": 1, "target": 1},
			"shopper": {"current": 0, "target": 1},
		})
		await process_frame
		modifier_goal_label = hud.get_node_or_null("RunModifierGoalLabel") as Label
		if modifier_goal_label == null or not modifier_goal_label.visible:
			failures.append("HUD should show daily goal progress")
		elif not modifier_goal_label.text.contains("Elite Hunt 1/1"):
			failures.append("HUD daily goal progress should include readable goal progress")
		elif int(modifier_goal_label.get_meta("run_goal_completed_count", 0)) != 1:
			failures.append("HUD daily goal progress should count completed goals")
	if not hud.has_method("show_run_goal_completed"):
		failures.append("HUD should expose show_run_goal_completed")
	else:
		hud.call("show_run_goal_completed", "Elite Hunt", "Goals: Elite Hunt 1/1 | Shop Buy 0/1", 1, 2)
		await process_frame
		var flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("completed daily goal should show HUD flash feedback")
		elif not flash.text.contains("Goal complete") or not flash.text.contains("Elite Hunt"):
			failures.append("completed daily goal flash should name the completed goal")
		elif str(flash.get_meta("hud_flash_kind", "")) != "run_goal_complete":
			failures.append("completed daily goal flash should store run_goal_complete metadata")
		elif int(flash.get_meta("run_goal_completed_count", 0)) != 1:
			failures.append("completed daily goal flash should store completed count metadata")
		var sfx := hud.get_node_or_null("ObjectiveCompleteSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("completed daily goal should reuse objective complete sound placeholder")
		elif str(sfx.get_meta("audio_cue_kind", "")) != "objective_complete":
			failures.append("completed daily goal sound should expose objective_complete cue kind")
	hud.queue_free()
	await process_frame

func _check_run_summary_modifier_context(failures: Array[String]) -> void:
	var script: Variant = load("res://scripts/ui/run_summary.gd")
	var text := str(script.call("end_message", "victory", 1, {"gold": 0}, {
		"banked_gold": 0,
		"runs_finished": 1,
		"best_floor": 1,
		"current_win_streak": 1,
		"best_win_streak": 1,
		"last_rewards": {"gold": 0},
	}, {
		"seed": 20260705,
		"seed_label": "Daily Seed",
		"modifier": "Glass Edges: Enemies scale +12%",
		"challenge_goals": "Goals: Elite Hunt 1/1 | Shop Buy 0/1",
		"challenge_goal_completed_count": 1,
		"challenge_goal_count": 2,
		"challenge_bonus_status": "Locked 1/2 goals",
	}))
	if not text.contains("Daily Seed: 20260705"):
		failures.append("summary should still label daily seed")
	if not text.contains("Challenge: Glass Edges"):
		failures.append("summary should include daily challenge modifier")
	if not text.contains("Challenge Goals: Elite Hunt 1/1"):
		failures.append("summary should include daily challenge goal progress")
	if not text.contains("Challenge Goal Clear: 1/2"):
		failures.append("summary should include daily challenge goal completion count")
	if not text.contains("Challenge Bonus Status: Locked 1/2 goals"):
		failures.append("summary should include daily challenge bonus earned/locked status")

func _check_main_wires_daily_modifier(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("RunModifierDBScript"):
		failures.append("Main should preload RunModifierDB")
	if not source.contains("_run_modifier = _modifier_for_run(run_seed)") \
			and not source.contains("_run_modifier = _modifier_for_run(run_seed, _run_mode)"):
		failures.append("Main should resolve active run modifier from seed")
	if not source.contains("_run_modifier = _modifier_for_run(run_seed, _run_mode)"):
		failures.append("Main should resolve Balance Lab modifier from run mode")
	if not source.contains("RunModifierDBScript.balance_lab_modifier"):
		failures.append("Main should use RunModifierDB balance lab modifier for tuning experiments")
	if not source.contains("hud.set_run_seed_label(_run_seed_context_label())"):
		failures.append("Main should pass readable seed label into HUD")
	if not source.contains("hud.set_run_modifier(_run_modifier)"):
		failures.append("Main should pass active run modifier into HUD")
	if not source.contains("_floor_ctrl.start(run_seed, current_floor, player, _run_mode, _run_modifier)"):
		failures.append("Main should pass run modifier into FloorController")
	if not source.contains("\"modifier\": _run_modifier_summary()"):
		failures.append("Main should include run modifier in run summary context")
	if not source.contains("_run_modifier_summary()"):
		failures.append("Main pause/transition text should be able to show run modifier")
	if not source.contains("_apply_run_modifier_reward_bonus(rewards)"):
		failures.append("Main should apply daily challenge bonus to banked run rewards")
	if not source.contains("\"challenge_bonus\": _run_modifier_bonus_summary()"):
		failures.append("Main should include daily challenge bonus in run summary context")
	if not source.contains("\"challenge_bonus_status\": _run_modifier_bonus_status_summary()"):
		failures.append("Main should include daily challenge bonus status in run summary context")
	if not source.contains("var _run_goal_progress"):
		failures.append("Main should track daily challenge goal progress")
	if not source.contains("RunModifierDBScript.initial_goal_progress(_run_modifier)"):
		failures.append("Main should initialize daily challenge goals from the modifier")
	if not source.contains("_advance_run_goal("):
		failures.append("Main should advance daily challenge goals from run events")
	if not source.contains("hud.set_run_modifier_goals("):
		failures.append("Main should pass daily challenge goal progress into HUD")
	if not source.contains("\"challenge_goals\": _run_goal_progress_summary()"):
		failures.append("Main should include daily challenge goal progress in run summary context")
	if not source.contains("\"challenge_goal_completed_count\": _run_goal_completed_count()"):
		failures.append("Main should include daily challenge completed count in run summary context")
	if not source.contains("show_run_goal_completed"):
		failures.append("Main should trigger HUD feedback when a daily goal completes")
	if not source.contains("RunModifierDBScript.earned_reward_bonus(_run_modifier, _run_goal_progress)"):
		failures.append("Main should only bank earned daily challenge bonus rewards")

func _check_floor_controller_modifier_difficulty(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	ctrl.difficulty_mult = 1.1
	ctrl.current_biome = {"difficulty_mult": 1.2}
	if not ctrl.has_method("set_run_modifier"):
		failures.append("FloorController should expose set_run_modifier")
		return
	ctrl.call("set_run_modifier", {"difficulty_mult": 1.25})
	var effective := float(ctrl.call("effective_difficulty_multiplier"))
	if absf(effective - 1.65) > 0.001:
		failures.append("FloorController difficulty should multiply mode, biome, and run modifier")
	if not ctrl.has_method("_apply_run_modifier_to_biome"):
		failures.append("FloorController should merge opt-in boss tuning patch into the active biome")
	else:
		ctrl.call("set_run_modifier", {
			"boss_tuning_patch": {
				"enabled": true,
				"id": "cave_golem_boss",
				"biome": "ancient_cave",
				"boss_variant": "cave_golem",
				"hp_multiplier": 1.25,
				"source": "smoke",
			},
		})
		var tuned_biome: Dictionary = ctrl.call("_apply_run_modifier_to_biome", {
			"id": "ancient_cave",
			"boss_variant": "spore_golem",
		})
		if Dictionary(tuned_biome.get("boss_tuning_patch", {})).is_empty():
			failures.append("FloorController should attach matching boss tuning patch to biome")
		if str(tuned_biome.get("boss_variant", "")) != "cave_golem":
			failures.append("FloorController boss tuning patch should pin the experiment boss variant")
		var skipped_biome: Dictionary = ctrl.call("_apply_run_modifier_to_biome", {
			"id": "fungal_depths",
			"boss_variant": "spore_golem",
		})
		if skipped_biome.has("boss_tuning_patch"):
			failures.append("FloorController should not apply boss tuning patch to a different biome")
	ctrl.free()

func _check_balance_lab_modifier(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("\"balance_lab\""):
		failures.append("Main should recognize Balance Lab as a run mode")
