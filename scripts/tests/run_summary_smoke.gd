extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	_check_run_summary_formatter(failures)
	_check_run_stats_apis(failures)
	_check_main_uses_run_summary(failures)

	if failures.is_empty():
		print("Run summary smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_run_summary_formatter(failures: Array[String]) -> void:
	if not ResourceLoader.exists("res://scripts/ui/run_summary.gd"):
		failures.append("RunSummary formatter script missing")
		return
	var script: Variant = load("res://scripts/ui/run_summary.gd")
	if not script.has_method("end_message"):
		failures.append("RunSummary should expose end_message")
		return
	var run_rewards := {
		"gold": 80,
		"soul_shards": 3,
		"element_cores": 1,
		"rune_dust": 2,
		"blueprints": 1,
	}
	var victory_meta := {
		"banked_gold": 180,
		"soul_shards": 9,
		"element_cores": 2,
		"rune_dust": 7,
		"blueprints": 1,
		"runs_finished": 5,
		"best_floor": 3,
		"current_win_streak": 2,
		"best_win_streak": 2,
		"last_rewards": run_rewards,
		"class_records": {
			"blade_warden": {
				"label": "Blade Warden",
				"runs": 6,
				"victories": 3,
				"best_floor": 4,
				"best_seed": 7777,
				"best_path": "Path: Entrance -> Combat -> Boss",
			},
		},
		"mode_records": {
			"boss_rush": {
				"label": "Boss Rush",
				"runs": 4,
				"victories": 2,
				"best_floor": 3,
				"best_seed": 20260705,
				"best_path": "Path: Entrance -> Combat -> Boss",
			},
		},
	}
	var context := {
		"class_id": "blade_warden",
		"class": "Blade Warden",
		"element": "fire",
		"weapons": "Kiem Ve Binh / Luc Tu Che (active)",
		"power_arc": "3 picks | Tier II | Fire Damage | Damage / Fire",
		"power_milestones": "Tier I @1 -> Tier II @3",
		"archetype": "Fire Damage",
		"build": "Power Rune x2, Dash Spring",
		"tags": "Damage / Fire",
		"rune_socket": "Sockets 2/3 | Runes Fire x1 / Ice x1 | Socket Upgrades: Split Socket / Aegis Socket",
		"stat_summary": "Pet x1.4 | Shield x1.5 | Dash 0.9s",
		"history": "Power Rune -> Power Rune -> Dash Spring",
		"decision_history": "Power Rune (Build match / Rare / Preview) -> Dash Spring (Mobility pivot)",
		"shop_history": "Phao Than Hong (Build match / Best Fit)",
		"loot_history": "Key +1 -> Rune Dust +2 -> Weapon: Luc Tu Che",
		"room_history": "Locked Chest (Spent key / Gold + Weapon) -> Heal Shrine (Healed +30)",
		"skill_history": "Wind Edge x2 / Lunge x1",
		"combo_history": "Thermal Shock x2 / Plasma x1",
		"boss_story": "Phase 2: Rock Volley + Trap Wave -> Bullet Hell x8 (Dodge radial bullets)",
		"boss_pressure": "Bullets x12 | Traps 5 | Guns 4 | Intensity high",
		"boss_phase_timing": "Phase 2 12.5s -> Enrage 28.0s",
		"boss_attack_timing": "Bullet Hell 31.2s -> Trap Wave 34.0s",
		"damage_taken": "Trap: Spike 10 / Enemy 5",
		"survival": "Revived x1 / Blocked 90",
		"final_hit": "Boss: Smash 12",
		"stats": "Rooms 7/12 | Kills 42 | Upgrades 3",
		"decisions": "Rewards 3 | Skips 1 | Rerolls 2 | Shop buys 2 | Shop leaves 1",
		"path": "Path: Entrance -> Combat -> Boss",
		"mastery": "Perfect 2 | Close Call 1 | Critical Path 3",
		"pace": "Avg 12.5s | Boss 85.0s | Slowest Boss 85.0s | Target 2 | Slow 1",
		"tuning_focus": "Tuning Focus: P1 cave_golem_boss boss_ttk | Pace evidence needed",
		"playtest_objective": "Playtest Objective: P1 cave_golem_boss boss_ttk | Current 85.0s | Target 120.0-240.0s | RunSummary Pace boss clear time",
		"tuning_patch": "Tuning Patch: P1 cave_golem_boss | test 1.41x boss_effective_hp_or_phase_downtime | Evidence required: RunSummary Pace boss clear time",
		"balance_experiment": "Balance Lab: cave_golem_boss HP 1.25x from playtest_evidence",
		"floor_recap": "Floor 4 recap: Rooms 7/12 | Kills +18 | Upgrades +2 | Gold +32 | Rewards +2 | Skips +1 | Shops +1/1 leaves",
		"release_audit": "Internal playtest: ready | Public release: ready | replace before public: 0 | fanmade: reference-only no copy",
		"release_decision": "public_ok",
		"release_replacements": 0,
		"release_backlog": "No replacement backlog",
		"release_next_action": "Next Action: Playtest | Tuning Focus: P1 cave_golem_boss boss_ttk | Pace evidence needed",
		"release_candidate_status": "evidence_required",
		"release_candidate_evidence": "Release Evidence: Smoke 74/70 OK | Notes OK | Scenarios 6/6",
		"release_candidate_next_action": "Next Action: Record playtest notes | seed/class/mode/animation/polygon/wave/HUD/audio evidence",
		"release_candidate_blockers": "playtest_notes_missing, manual_scenarios_missing",
		"manual_scenario_evidence_draft": "seed=420101 | mode=normal | class_id=blade_warden | goal=clear floor 1 and choose one upgrade | result=pending | evidence_source=manual_playtest",
		"seed": 123456,
		"mode": "Boss Rush",
		"difficulty": "x1.56",
		"threat": "x2.34",
		"run_finale": true,
		"challenge_bonus": "+12 gold, Dust +2",
		"meta_bonuses": "+20 HP / +4% damage / Key +1",
	}
	victory_meta["last_rewards"]["challenge_bonus"] = "+12 gold, Dust +2"
	var victory := str(script.call("end_message", "victory", 4, run_rewards, victory_meta, context))
	for token in [
		"Seed: 123456",
		"Mode: Boss Rush",
		"Difficulty: x1.56",
		"Threat: x2.34",
		"Finale: Floor 4 | Final Boss defeated | Run Complete",
		"Challenge Bonus: +12 gold, Dust +2",
		"Meta Bonuses: +20 HP / +4% damage / Key +1",
		"Class: Blade Warden",
		"Element: fire",
		"Weapons: Kiem Ve Binh / Luc Tu Che (active)",
		"Power Arc: 3 picks | Tier II | Fire Damage",
		"Power Milestones: Tier I @1 -> Tier II @3",
		"Archetype: Fire Damage",
		"Build: Power Rune x2, Dash Spring",
		"Tags: Damage / Fire",
		"Sockets 2/3",
		"Power Stats: Pet x1.4 | Shield x1.5 | Dash 0.9s",
		"Runes Fire x1 / Ice x1",
		"Socket Upgrades: Split Socket / Aegis Socket",
		"History: Power Rune -> Power Rune -> Dash Spring",
		"Pick Reasons: Power Rune (Build match / Rare / Preview) -> Dash Spring (Mobility pivot)",
		"Shop Picks: Phao Than Hong (Build match / Best Fit)",
		"Loot Picks: Key +1 -> Rune Dust +2 -> Weapon: Luc Tu Che",
		"Room Decisions: Locked Chest (Spent key / Gold + Weapon) -> Heal Shrine (Healed +30)",
		"Skill Use: Wind Edge x2 / Lunge x1",
		"Element Combos: Thermal Shock x2 / Plasma x1",
		"Boss Story: Phase 2: Rock Volley + Trap Wave -> Bullet Hell x8 (Dodge radial bullets)",
		"Boss Pressure: Bullets x12 | Traps 5 | Guns 4 | Intensity high",
		"Boss Phase Timing: Phase 2 12.5s -> Enrage 28.0s",
		"Boss Attack Timing: Bullet Hell 31.2s -> Trap Wave 34.0s",
		"Damage Taken: Trap: Spike 10 / Enemy 5",
		"Survival: Revived x1 / Blocked 90",
		"Final Hit: Boss: Smash 12",
		"Stats: Rooms 7/12 | Kills 42 | Upgrades 3",
		"Decisions: Rewards 3 | Skips 1 | Rerolls 2 | Shop buys 2 | Shop leaves 1",
		"Path: Entrance -> Combat -> Boss",
		"Mastery: Perfect 2 | Close Call 1 | Critical Path 3",
		"Pace: Avg 12.5s | Boss 85.0s | Slowest Boss 85.0s | Target 2 | Slow 1",
		"Tuning Focus: P1 cave_golem_boss boss_ttk | Pace evidence needed",
		"Playtest Objective: P1 cave_golem_boss boss_ttk | Current 85.0s | Target 120.0-240.0s | RunSummary Pace boss clear time",
		"Tuning Patch: P1 cave_golem_boss | test 1.41x boss_effective_hp_or_phase_downtime",
		"Balance Experiment: Balance Lab: cave_golem_boss HP 1.25x from playtest_evidence",
		"Floor Recap: Floor 4 recap: Rooms 7/12 | Kills +18 | Upgrades +2 | Gold +32 | Rewards +2 | Skips +1 | Shops +1/1 leaves",
		"Release Audit: Internal playtest: ready | Public release: ready",
		"Public Gate: public_ok | No replacements required",
		"Release Backlog: No replacement backlog",
		"Release Next: Next Action: Playtest | Tuning Focus: P1 cave_golem_boss boss_ttk | Pace evidence needed",
		"Release Candidate: evidence_required | playtest_notes_missing, manual_scenarios_missing",
		"Manual Evidence Draft: seed=420101 | mode=normal | class_id=blade_warden | goal=clear floor 1 and choose one upgrade | result=pending | evidence_source=manual_playtest",
		"Candidate Next: Next Action: Record playtest notes | seed/class/mode/animation/polygon/wave/HUD/audio evidence",
		"Banked this run",
		"+80g",
		"Shard +3",
		"Core +1",
		"Dust +2",
		"BP +1",
		"Challenge Bonus +12 gold, Dust +2",
		"Total: 180g",
		"Runs 5",
		"Best F3",
		"Streak 2",
		"Class Record: Blade Warden | Runs 6 | Wins 3 | Best F4 | Seed 7777",
		"Class Best Path: Entrance -> Combat -> Boss",
		"Mode Record: Boss Rush | Runs 4 | Wins 2 | Best F3 | Seed 20260705",
		"Mode Best Path: Entrance -> Combat -> Boss",
		"Meta Shop:",
		"Affordable:",
		"Next Hub Upgrade: Ready: +HP (30 Gold)",
		"+HP",
		"Core Affinity",
		"Press R",
		"Class Select",
	]:
		if not victory.contains(token):
			failures.append("victory summary missing token: %s" % token)
	var defeat_meta := victory_meta.duplicate()
	defeat_meta["last_rewards"] = {
		"gold": 40,
		"soul_shards": 3,
		"element_cores": 1,
		"rune_dust": 2,
		"blueprints": 1,
	}
	var defeat := str(script.call("end_message", "defeat", 2, run_rewards, defeat_meta, context))
	for token in ["Floor 2", "Seed: 123456", "Difficulty: x1.56", "Meta Bonuses: +20 HP / +4% damage / Key +1", "Class: Blade Warden", "Weapons: Kiem Ve Binh / Luc Tu Che (active)", "Power Arc: 3 picks | Tier II | Fire Damage", "Power Milestones: Tier I @1 -> Tier II @3", "Archetype: Fire Damage", "Build: Power Rune x2", "Tags: Damage / Fire", "Sockets 2/3", "Power Stats: Pet x1.4 | Shield x1.5 | Dash 0.9s", "Pick Reasons: Power Rune (Build match / Rare / Preview) -> Dash Spring (Mobility pivot)", "Shop Picks: Phao Than Hong (Build match / Best Fit)", "Loot Picks: Key +1 -> Rune Dust +2 -> Weapon: Luc Tu Che", "Room Decisions: Locked Chest (Spent key / Gold + Weapon) -> Heal Shrine (Healed +30)", "Skill Use: Wind Edge x2 / Lunge x1", "Element Combos: Thermal Shock x2 / Plasma x1", "Boss Story: Phase 2: Rock Volley + Trap Wave -> Bullet Hell x8 (Dodge radial bullets)", "Boss Pressure: Bullets x12 | Traps 5 | Guns 4", "Boss Phase Timing: Phase 2 12.5s -> Enrage 28.0s", "Boss Attack Timing: Bullet Hell 31.2s -> Trap Wave 34.0s", "Damage Taken: Trap: Spike 10 / Enemy 5", "Survival: Revived x1 / Blocked 90", "Final Hit: Boss: Smash 12", "Stats: Rooms 7/12", "Decisions: Rewards 3 | Skips 1", "Path: Entrance -> Combat -> Boss", "Pace: Avg 12.5s | Boss 85.0s", "Tuning Focus: P1 cave_golem_boss boss_ttk", "Playtest Objective: P1 cave_golem_boss boss_ttk", "Balance Experiment: Balance Lab: cave_golem_boss HP 1.25x from playtest_evidence", "Floor Recap: Floor 4 recap: Rooms 7/12", "Release Audit: Internal playtest: ready | Public release: ready", "Public Gate: public_ok | No replacements required", "Release Next: Next Action: Playtest", "Release Candidate: evidence_required", "Release Evidence: Smoke 74/70 OK", "Candidate Next: Next Action: Record playtest notes", "+40g of 80g", "Kept", "Shard +3", "Core +1", "Best F3", "Class Record: Blade Warden | Runs 6 | Wins 3 | Best F4 | Seed 7777", "Mode Record: Boss Rush | Runs 4 | Wins 2 | Best F3 | Seed 20260705", "Next Hub Upgrade: Ready: +HP (30 Gold)", "Press R", "Class Select"]:
		if not defeat.contains(token):
			failures.append("defeat summary missing token: %s" % token)
	var daily_context := context.duplicate()
	daily_context["seed"] = 20260705
	daily_context["seed_label"] = "Daily Seed"
	daily_context["daily_fingerprint"] = {
		"hash": "daily-abc",
		"floor_index": 3,
		"room_count": 19,
		"spawn_count": 42,
		"boss_variant": "cave_golem",
	}
	var daily := str(script.call("end_message", "victory", 3, run_rewards, victory_meta, daily_context))
	if not daily.contains("Daily Seed: 20260705"):
		failures.append("daily run summary should label daily seeds")
	if not daily.contains("Daily Fingerprint: Hash daily-abc | Floor 3 | Rooms 19 | Spawns 42 | Boss cave_golem"):
		failures.append("daily run summary should expose shareable map/spawn fingerprint")
	var endless_meta := victory_meta.duplicate(true)
	endless_meta["last_rewards"] = {
		"gold": 12,
		"rune_dust": 2,
		"soul_shards": 1,
		"endless_depth_bonus": "Depth +2: Dust +2 / Shard +1",
	}
	var endless_context := context.duplicate()
	endless_context["mode"] = "Endless"
	endless_context["run_finale"] = false
	var endless := str(script.call("end_message", "defeat", 6, run_rewards, endless_meta, endless_context))
	if not endless.contains("Mode: Endless"):
		failures.append("endless run summary should show Endless mode")
	if not endless.contains("Endless Depth Bonus Depth +2: Dust +2 / Shard +1"):
		failures.append("endless run summary should show depth bonus")
	if endless.contains("Run Complete"):
		failures.append("endless defeat summary should not show run complete finale copy")

func _check_run_stats_apis(failures: Array[String]) -> void:
	var player := Player.new()
	if not player.has_method("run_kill_count"):
		failures.append("Player should expose run_kill_count")
	else:
		player.on_enemy_killed()
		player.on_enemy_killed()
		if int(player.call("run_kill_count")) != 2:
			failures.append("run_kill_count should track enemy kills")
	if not player.has_method("upgrade_count"):
		failures.append("Player should expose upgrade_count")
	else:
		player.record_upgrade("power_rune", "Power Rune", ["damage", "fire"], "Build match / Rare / Preview")
		player.record_upgrade("dash_spring", "Dash Spring", ["dash", "mobility"], "Mobility pivot")
		if int(player.call("upgrade_count")) != 2:
			failures.append("upgrade_count should track selected upgrades")
	if not player.has_method("upgrade_decision_history_summary"):
		failures.append("Player should expose upgrade_decision_history_summary")
	else:
		var decision_history := str(player.call("upgrade_decision_history_summary"))
		if not decision_history.contains("Power Rune (Build match / Rare / Preview)") \
				or not decision_history.contains("Dash Spring (Mobility pivot)"):
			failures.append("upgrade decision history should preserve why each reward was picked")
	if not player.has_method("power_milestone_summary"):
		failures.append("Player should expose power_milestone_summary")
	else:
		var milestone_player := Player.new()
		milestone_player.record_upgrade("power_rune", "Power Rune", ["damage"])
		milestone_player.record_upgrade("dash_spring", "Dash Spring", ["dash"])
		milestone_player.record_upgrade("ember_rune", "Ember Rune", ["fire"])
		var milestones := str(milestone_player.call("power_milestone_summary"))
		if not milestones.contains("Tier I @1") or not milestones.contains("Tier II @3"):
			failures.append("power milestone summary should record tier changes by upgrade pick count")
		milestone_player.free()
	if not player.has_method("record_shop_purchase"):
		failures.append("Player should expose record_shop_purchase")
	else:
		player.call("record_shop_purchase", "Phao Than Hong", "Build match / Best Fit")
		player.call("record_shop_purchase", "Field Ration", "Sustain")
	if not player.has_method("shop_purchase_history_summary"):
		failures.append("Player should expose shop_purchase_history_summary")
	else:
		var shop_history := str(player.call("shop_purchase_history_summary"))
		if not shop_history.contains("Phao Than Hong (Build match / Best Fit)") \
				or not shop_history.contains("Field Ration (Sustain)"):
			failures.append("shop purchase history should preserve why each item was bought")
	if not player.has_method("record_pickup"):
		failures.append("Player should expose record_pickup")
	else:
		player.call("record_pickup", "Key +1")
		player.call("record_pickup", "Rune Dust +2")
		player.call("record_pickup", "Weapon: Luc Tu Che")
	if not player.has_method("pickup_history_summary"):
		failures.append("Player should expose pickup_history_summary")
	else:
		var loot_history := str(player.call("pickup_history_summary"))
		for token in ["Key +1", "Rune Dust +2", "Weapon: Luc Tu Che"]:
			if not loot_history.contains(token):
				failures.append("pickup history should preserve %s" % token)
	if not player.has_method("record_room_decision"):
		failures.append("Player should expose record_room_decision")
	else:
		player.call("record_room_decision", "Locked Chest", "Spent key / Gold + Weapon")
		player.call("record_room_decision", "Heal Shrine", "Healed +30")
	if not player.has_method("room_decision_history_summary"):
		failures.append("Player should expose room_decision_history_summary")
	else:
		var room_history := str(player.call("room_decision_history_summary"))
		if not room_history.contains("Locked Chest (Spent key / Gold + Weapon)") \
				or not room_history.contains("Heal Shrine (Healed +30)"):
			failures.append("room decision history should preserve chest/shrine choices")
		var noisy_player := Player.new()
		noisy_player.call("record_room_decision", "Locked Chest", "Spent key / Gold + Weapon")
		noisy_player.call("record_room_decision", "Heal Shrine", "Healed +30")
		for _i in 8:
			noisy_player.call("record_room_decision", "Trap Hit", "Spike -6 HP")
		var noisy_history := str(noisy_player.call("room_decision_history_summary"))
		if not noisy_history.contains("Locked Chest (Spent key / Gold + Weapon)") \
				or not noisy_history.contains("Heal Shrine (Healed +30)") \
				or not noisy_history.contains("Trap Hit (Spike -6 HP) x8"):
			failures.append("room decision history should collapse trap spam without hiding key decisions")
		noisy_player.free()
	if not player.has_method("record_skill_use"):
		failures.append("Player should expose record_skill_use")
	else:
		player.call("record_skill_use", "wind_edge")
		player.call("record_skill_use", "lunge")
		player.call("record_skill_use", "wind_edge")
	if not player.has_method("skill_usage_summary"):
		failures.append("Player should expose skill_usage_summary")
	else:
		var skill_history := str(player.call("skill_usage_summary"))
		if not skill_history.contains("Wind Edge x2") or not skill_history.contains("Lunge x1"):
			failures.append("skill usage summary should count repeated active skill casts")
	if not player.has_method("record_element_combo"):
		failures.append("Player should expose record_element_combo")
	else:
		player.call("record_element_combo", {"id": "thermal_shock", "name": "Thermal Shock"})
		player.call("record_element_combo", {"id": "plasma", "name": "Plasma"})
		player.call("record_element_combo", {"id": "thermal_shock", "name": "Thermal Shock"})
	if not player.has_method("element_combo_summary"):
		failures.append("Player should expose element_combo_summary")
	else:
		var combo_history := str(player.call("element_combo_summary"))
		if not combo_history.contains("Thermal Shock x2") or not combo_history.contains("Plasma x1"):
			failures.append("element_combo_summary should count repeated element combo reactions")
	if not player.has_method("element_combo_count"):
		failures.append("Player should expose element_combo_count")
	else:
		if int(player.call("element_combo_count")) != 3:
			failures.append("element_combo_count should track all triggered combo reactions")
	if not player.has_method("record_damage_taken"):
		failures.append("Player should expose record_damage_taken")
	else:
		player.call("record_damage_taken", "Trap: Spike", 7)
		player.call("record_damage_taken", "Enemy", 5)
		player.call("record_damage_taken", "Trap: Spike", 3)
	if not player.has_method("damage_taken_summary"):
		failures.append("Player should expose damage_taken_summary")
	else:
		var damage_history := str(player.call("damage_taken_summary"))
		if not damage_history.contains("Trap: Spike 10") or not damage_history.contains("Enemy 5"):
			failures.append("damage_taken_summary should total damage by source")
	if not player.has_method("survival_summary"):
		failures.append("Player should expose survival_summary")
	else:
		player.apply_meta_bonuses({"upgrades": {"revive_charm": 1}})
		player.max_hp = 100
		player.hp = 10
		player.call("take_damage", 99, Vector2.ZERO, "Boss: Smash")
		player.set_meta("fortress_active", true)
		player.call("take_damage", 40, Vector2.ZERO, "Boss: Smash")
		var survival := str(player.call("survival_summary"))
		if not survival.contains("Revived x1") or not survival.contains("Blocked 40"):
			failures.append("survival_summary should recap revives and blocked damage")
	if not player.has_method("final_hit_summary"):
		failures.append("Player should expose final_hit_summary")
	else:
		if player.has_meta("fortress_active"):
			player.remove_meta("fortress_active")
		if player.has_meta("mobile_fortress_active"):
			player.remove_meta("mobile_fortress_active")
		player.max_hp = 50
		player.hp = 8
		player.call("take_damage", 12, Vector2.ZERO, "Boss: Smash")
		var final_hit := str(player.call("final_hit_summary"))
		if not final_hit.contains("Boss: Smash 12"):
			failures.append("final_hit_summary should record the killing damage source")
	if not player.has_method("run_power_tier"):
		failures.append("Player should expose run_power_tier")
	elif str(player.call("run_power_tier")) != "Tier I":
		failures.append("run_power_tier should label early upgrade count")
	if not player.has_method("run_power_arc_summary"):
		failures.append("Player should expose run_power_arc_summary")
	else:
		var power_arc := str(player.call("run_power_arc_summary"))
		if not power_arc.contains("2 picks") or not power_arc.contains("Tier I") \
				or not power_arc.contains("Fire Damage"):
			failures.append("run_power_arc_summary should combine pick count, tier, and archetype")
	player.pet_damage_mult = 1.4
	player.shield_duration_mult = 1.5
	player.dash_cooldown = 0.9
	if not player.has_method("run_stat_summary"):
		failures.append("Player should expose run_stat_summary")
	else:
		var stat_summary := str(player.call("run_stat_summary"))
		for token in ["Pet x1.4", "Shield x1.5", "Dash 0.9s"]:
			if not stat_summary.contains(token):
				failures.append("run_stat_summary missing token: %s" % token)
	player.free()
	var ctrl := FloorController.new()
	ctrl.rooms = [RoomNode.new(), RoomNode.new(), RoomNode.new()]
	ctrl.cleared_rooms[0] = true
	ctrl.cleared_rooms[2] = true
	if not ctrl.has_method("cleared_room_count") or not ctrl.has_method("total_room_count"):
		failures.append("FloorController should expose room count stats")
	else:
		if int(ctrl.call("cleared_room_count")) != 2:
			failures.append("cleared_room_count should count cleared rooms")
		if int(ctrl.call("total_room_count")) != 3:
			failures.append("total_room_count should count floor rooms")
	if not ctrl.has_method("visited_room_path_summary"):
		failures.append("FloorController should expose visited_room_path_summary")
	elif not ctrl.has_method("_record_room_visit"):
		failures.append("FloorController should record ordered room visits")
	else:
		ctrl.rooms.clear()
		var entrance := RoomNode.new()
		entrance.id = 0
		entrance.type = RoomNode.RoomType.ENTRANCE
		var combat := RoomNode.new()
		combat.id = 1
		combat.type = RoomNode.RoomType.COMBAT
		var boss := RoomNode.new()
		boss.id = 2
		boss.type = RoomNode.RoomType.BOSS
		ctrl.rooms = [entrance, combat, boss]
		ctrl.call("_record_room_visit", entrance)
		ctrl.call("_record_room_visit", combat)
		ctrl.call("_record_room_visit", combat)
		ctrl.call("_record_room_visit", boss)
		var path := str(ctrl.call("visited_room_path_summary"))
		if not path.contains("Path: Entrance -> Combat -> Boss"):
			failures.append("visited_room_path_summary should expose ordered unique room route")
	if not ctrl.has_method("room_mastery_context"):
		failures.append("FloorController should expose room_mastery_context")
	if not ctrl.has_method("room_mastery_summary"):
		failures.append("FloorController should expose room_mastery_summary")
	if not ctrl.has_method("room_timing_summary"):
		failures.append("FloorController should expose room_timing_summary")
	if not ctrl.has_method("room_timing_context"):
		failures.append("FloorController should expose structured room_timing_context")
	elif ctrl.has_method("_record_room_mastery_start"):
		ctrl.rooms.clear()
		ctrl.cleared_rooms.clear()
		var mastery_player := Player.new()
		mastery_player.max_hp = 100
		mastery_player.hp = 100
		ctrl._player = mastery_player
		var perfect_room := RoomNode.new()
		perfect_room.id = 10
		perfect_room.type = RoomNode.RoomType.COMBAT
		perfect_room.on_critical_path = true
		var clutch_room := RoomNode.new()
		clutch_room.id = 11
		clutch_room.type = RoomNode.RoomType.ELITE
		var healed_room := RoomNode.new()
		healed_room.id = 13
		healed_room.type = RoomNode.RoomType.COMBAT
		ctrl.rooms = [perfect_room, clutch_room, healed_room]
		ctrl.call("_record_room_mastery_start", perfect_room)
		ctrl.call("_on_room_cleared", perfect_room)
		var perfect_context: Dictionary = ctrl.call("room_mastery_context", perfect_room.id)
		if not bool(perfect_context.get("perfect_clear", false)):
			failures.append("room_mastery_context should mark no-damage clears as perfect")
		if not bool(perfect_context.get("critical_path", false)):
			failures.append("room_mastery_context should preserve critical path rooms")
		if not perfect_context.has("clear_time_sec"):
			failures.append("room_mastery_context should include clear_time_sec for pace tuning")
		if not perfect_context.has("pace_rating"):
			failures.append("room_mastery_context should include pace_rating for room timing review")
		if not perfect_context.has("pace_target_sec"):
			failures.append("room_mastery_context should include pace_target_sec for tuning review")
		mastery_player.hp = 100
		ctrl.call("_record_room_mastery_start", clutch_room)
		mastery_player.hp = 25
		ctrl.call("_on_room_cleared", clutch_room)
		var clutch_context: Dictionary = ctrl.call("room_mastery_context", clutch_room.id)
		if not bool(clutch_context.get("close_call", false)):
			failures.append("room_mastery_context should mark low-hp clears as close calls")
		mastery_player.hp = 100
		ctrl.call("_record_room_mastery_start", healed_room)
		mastery_player.call("record_damage_taken", "Spike", 10)
		mastery_player.hp = 100
		ctrl.call("_on_room_cleared", healed_room)
		var healed_context: Dictionary = ctrl.call("room_mastery_context", healed_room.id)
		if bool(healed_context.get("perfect_clear", true)):
			failures.append("room_mastery_context should not mark healed damage rooms as perfect")
		if int(healed_context.get("damage_taken", 0)) <= 0:
			failures.append("room_mastery_context should preserve damage taken even if HP is restored before clear")
		var mastery := str(ctrl.call("room_mastery_summary"))
		for token in ["Perfect 1", "Close Call 1", "Critical Path 1", "Reward Rooms 3"]:
			if not mastery.contains(token):
				failures.append("room_mastery_summary missing token: %s" % token)
		var boss_room := RoomNode.new()
		boss_room.id = 12
		boss_room.type = RoomNode.RoomType.BOSS
		ctrl.call("_record_room_mastery_start", boss_room)
		ctrl.call("_record_room_mastery_clear", boss_room)
		var timing := str(ctrl.call("room_timing_summary"))
		for token in ["Avg", "Boss", "Slowest"]:
			if not timing.contains(token):
				failures.append("room_timing_summary missing token: %s" % token)
		ctrl.room_mastery.clear()
		ctrl.room_mastery[20] = {
			"clear_time_sec": 2.0,
			"room_type": RoomNode.RoomType.COMBAT,
			"room_type_name": "Combat",
			"boss_room": false,
			"pace_rating": "fast",
		}
		ctrl.room_mastery[21] = {
			"clear_time_sec": 16.0,
			"room_type": RoomNode.RoomType.COMBAT,
			"room_type_name": "Combat",
			"boss_room": false,
			"pace_rating": "target",
		}
		ctrl.room_mastery[22] = {
			"clear_time_sec": 85.0,
			"room_type": RoomNode.RoomType.BOSS,
			"room_type_name": "Boss",
			"boss_room": true,
			"pace_rating": "slow",
		}
		var timing_context: Dictionary = ctrl.call("room_timing_context")
		if int(timing_context.get("timed_room_count", 0)) != 3:
			failures.append("room_timing_context should count timed rooms")
		if absf(float(timing_context.get("avg_clear_time_sec", -1.0)) - (103.0 / 3.0)) > 0.01:
			failures.append("room_timing_context should expose average clear seconds")
		if absf(float(timing_context.get("boss_clear_time_sec", -1.0)) - 85.0) > 0.01:
			failures.append("room_timing_context should expose boss clear seconds")
		if str(timing_context.get("slowest_room_type_name", "")) != "Boss":
			failures.append("room_timing_context should expose slowest room label")
		if int(timing_context.get("fast_room_count", 0)) != 1 \
				or int(timing_context.get("target_room_count", 0)) != 1 \
				or int(timing_context.get("slow_room_count", 0)) != 1:
			failures.append("room_timing_context should expose pace rating counts")
		var pace_breakdown := str(ctrl.call("room_timing_summary"))
		for token in ["Fast 1", "Target 1", "Slow 1"]:
			if not pace_breakdown.contains(token):
				failures.append("room_timing_summary should include pace rating token: %s" % token)
		mastery_player.free()
	ctrl.free()
	var main_script: Variant = load("res://scripts/main.gd")
	var main: Node = main_script.new()
	if not main.has_method("_on_boss_phase_changed") \
			or not main.has_method("_on_boss_attack_cued") \
			or not main.has_method("_boss_story_summary"):
		failures.append("Main should collect boss phase/attack story for run summary")
	else:
		main.call("_on_boss_phase_changed", {
			"phase": 2,
			"pattern_label": "Pattern: Rock Volley + Trap Wave",
			"arena_pressure_summary": "Bullets x8 | Traps 2 | Guns 0 | Intensity medium",
			"elapsed_seconds": 12.5,
		})
		main.call("_on_boss_phase_changed", {
			"phase": 3,
			"enraged": true,
			"phase_text": "ENRAGE + BULLET HELL",
			"arena_pressure_summary": "Bullets x12 | Traps 5 | Guns 4 | Intensity high",
			"elapsed_seconds": 28.0,
		})
		main.call("_on_boss_attack_cued", {
			"attack": "bullet_hell",
			"attack_label": "Bullet Hell",
			"projectile_count": 8,
			"warning": "Dodge radial bullets",
			"counter_hint": "Rotate through bullet gaps",
			"punish_window_seconds": 0.6,
			"safe_window_hint": "Punish after charge line ends",
			"elapsed_seconds": 31.2,
		})
		main.call("_on_boss_attack_cued", {
			"attack": "trap_wave",
			"attack_label": "Trap Wave",
			"hazard_count": 4,
			"warning": "Trap wave spreading",
			"counter_hint": "Leave marked tiles",
			"punish_window_seconds": 0.7,
			"safe_window_hint": "Punish before trap wave closes",
			"arena_pressure_summary": "Bullets x8 | Traps 4 | Guns 0 | Intensity medium",
			"elapsed_seconds": 34.0,
		})
		var boss_story := str(main.call("_boss_story_summary"))
		for token in [
			"Phase 2: Rock Volley + Trap Wave",
			"Bullet Hell x8 (Dodge radial bullets)",
			"Counter: Rotate through bullet gaps",
			"Punish 0.6s",
			"Safe: Punish after charge line ends",
			"Trap Wave x4 (Trap wave spreading)",
			"Counter: Leave marked tiles",
			"Punish 0.7s",
			"Safe: Punish before trap wave closes",
		]:
			if not boss_story.contains(token):
				failures.append("boss story summary missing token: %s" % token)
		if not main.has_method("_boss_pressure_summary"):
			failures.append("Main should expose boss pressure summary for run evidence")
		else:
			var boss_pressure := str(main.call("_boss_pressure_summary"))
			for token in [
				"Bullets x8 | Traps 2 | Guns 0 | Intensity medium",
				"Bullets x12 | Traps 5 | Guns 4 | Intensity high",
				"Bullets x8 | Traps 4 | Guns 0 | Intensity medium",
			]:
				if not boss_pressure.contains(token):
					failures.append("boss pressure summary missing token: %s" % token)
		if not main.has_method("_boss_phase_timing_summary"):
			failures.append("Main should expose boss phase timing summary for balance evidence")
		else:
			var boss_phase_timing := str(main.call("_boss_phase_timing_summary"))
			for token in ["Phase 2 12.5s", "Enrage 28.0s"]:
				if not boss_phase_timing.contains(token):
					failures.append("boss phase timing summary missing token: %s" % token)
		if not main.has_method("_boss_attack_timing_summary"):
			failures.append("Main should expose boss attack timing summary for balance evidence")
		else:
			var boss_attack_timing := str(main.call("_boss_attack_timing_summary"))
			for token in ["Bullet Hell 31.2s", "Trap Wave 34.0s"]:
				if not boss_attack_timing.contains(token):
					failures.append("boss attack timing summary missing token: %s" % token)
	if not main.has_method("_manual_scenario_evidence_draft"):
		failures.append("Main should expose a pending manual scenario evidence draft helper")
	else:
		main.set("run_seed", 420101)
		main.set("_run_mode", "normal")
		var draft := str(main.call("_manual_scenario_evidence_draft", "blade_warden"))
		for token in ["seed=420101", "mode=normal", "class_id=blade_warden",
				"goal=clear floor 1 and choose one upgrade", "result=pending",
				"evidence_source=manual_playtest"]:
			if not draft.contains(token):
				failures.append("manual scenario evidence draft missing token: %s" % token)
		if draft.contains("result=pass"):
			failures.append("manual scenario evidence draft should not auto-pass human evidence")
		main.set("run_seed", 999999)
		var non_checklist_draft := str(main.call("_manual_scenario_evidence_draft", "blade_warden"))
		if non_checklist_draft != "":
			failures.append("manual scenario evidence draft should stay hidden for non-checklist runs")
	if not main.has_method("_record_floor_start_snapshot") \
			or not main.has_method("_floor_delta_summary"):
		failures.append("Main should expose floor recap snapshot helpers")
	else:
		var recap_player := Player.new()
		recap_player.gold = 10
		main.set("player", recap_player)
		main.set("current_floor", 2)
		main.set("_reward_pick_count", 1)
		var recap_ctrl := FloorController.new()
		for i in 3:
			var room := RoomNode.new()
			room.id = i
			recap_ctrl.rooms.append(room)
		main.set("_floor_ctrl", recap_ctrl)
		main.call("_record_floor_start_snapshot")
		recap_player.on_enemy_killed()
		recap_player.on_enemy_killed()
		recap_player.record_upgrade("power_rune", "Power Rune", ["damage"])
		recap_player.gold = 35
		recap_ctrl.cleared_rooms[0] = true
		recap_ctrl.cleared_rooms[1] = true
		recap_ctrl.room_mastery[0] = {
			"perfect_clear": true,
			"reward_room": true,
		}
		main.set("_reward_pick_count", 3)
		main.set("_reward_skip_count", 2)
		main.set("_reward_reroll_count", 1)
		main.set("_shop_buy_count", 1)
		main.set("_shop_leave_count", 1)
		if not main.has_method("_run_economy_context"):
			failures.append("Main should expose structured run economy context")
		else:
			var economy: Dictionary = main.call("_run_economy_context")
			var expected_economy := {
				"economy_gold_earned": 35,
				"decision_reward_picks": 3,
				"decision_reward_skips": 2,
				"decision_reward_rerolls": 1,
				"decision_shop_buys": 1,
				"decision_shop_leaves": 1,
			}
			for key in expected_economy:
				if economy.get(key) != expected_economy[key]:
					failures.append("run economy context should expose %s" % key)
		var floor_recap := str(main.call("_floor_delta_summary"))
		for token in ["Floor 2 recap", "Rooms 2/3", "Kills +2", "Upgrades +1",
				"Gold +25", "Rewards +2", "Skips +2", "Shops +1/1 leaves",
				"Mastery: Perfect 1 | Reward Rooms 1"]:
			if not floor_recap.contains(token):
				failures.append("floor recap missing token: %s" % token)
		recap_player.free()
		recap_ctrl.free()
	main.free()

func _check_main_uses_run_summary(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("RunSummary"):
		failures.append("Main should preload RunSummary")
	if not source.contains("end_message"):
		failures.append("Main should use RunSummary.end_message for run end overlay")
	if not source.contains("_run_summary_context"):
		failures.append("Main should pass class/build context to run summary")
	if not source.contains("upgrade_history_summary"):
		failures.append("Main should include upgrade history in run summary context")
	if not source.contains("upgrade_decision_history_summary"):
		failures.append("Main should include upgrade decision reasons in run summary context")
	if not source.contains("shop_purchase_history_summary"):
		failures.append("Main should include shop purchase reasons in run summary context")
	if not source.contains("\"shop_history\":"):
		failures.append("Main should pass shop_history into run summary context")
	if not source.contains("pickup_history_summary"):
		failures.append("Main should include loot pickup history in run summary context")
	if not source.contains("\"loot_history\":"):
		failures.append("Main should pass loot_history into run summary context")
	if not source.contains("room_decision_history_summary"):
		failures.append("Main should include room decision reasons in run summary context")
	if not source.contains("\"room_history\":"):
		failures.append("Main should pass room_history into run summary context")
	if not source.contains("skill_usage_summary"):
		failures.append("Main should include skill usage in run summary context")
	if not source.contains("\"skill_history\":"):
		failures.append("Main should pass skill_history into run summary context")
	if not source.contains("element_combo_summary"):
		failures.append("Main should include element combo history in run summary context")
	if not source.contains("\"combo_history\":"):
		failures.append("Main should pass combo_history into run summary context")
	if not source.contains("_boss_story_summary"):
		failures.append("Main should include boss phase/attack story in run summary context")
	if not source.contains("\"boss_story\":"):
		failures.append("Main should pass boss_story into run summary context")
	if not source.contains("damage_taken_summary"):
		failures.append("Main should include damage taken summary in run summary context")
	if not source.contains("\"damage_taken\":"):
		failures.append("Main should pass damage_taken into run summary context")
	if not source.contains("survival_summary"):
		failures.append("Main should include survival summary in run summary context")
	if not source.contains("\"survival\":"):
		failures.append("Main should pass survival into run summary context")
	if not source.contains("final_hit_summary"):
		failures.append("Main should include final hit in run summary context")
	if not source.contains("\"final_hit\":"):
		failures.append("Main should pass final_hit into run summary context")
	if not source.contains("boss_phase_changed.connect(_on_boss_phase_changed)"):
		failures.append("Main should listen to boss phase events")
	if not source.contains("boss_attack_cued.connect(_on_boss_attack_cued)"):
		failures.append("Main should listen to boss attack events")
	if not source.contains("upgrade_tag_summary"):
		failures.append("Main should include readable build tags in run summary context")
	if not source.contains("build_archetype_summary"):
		failures.append("Main should include readable build archetype in run summary context")
	if not source.contains("run_power_arc_summary"):
		failures.append("Main should include readable run power arc in run summary context")
	if not source.contains("\"power_arc\":"):
		failures.append("Main should pass power_arc into run summary context")
	if not source.contains("power_milestone_summary"):
		failures.append("Main should include power milestone summary in run summary context")
	if not source.contains("\"power_milestones\":"):
		failures.append("Main should pass power_milestones into run summary context")
	if not source.contains("rune_socket_summary"):
		failures.append("Main should include rune/socket breakdown in run summary context")
	if not source.contains("run_stat_summary"):
		failures.append("Main should include readable run stat summary in run summary context")
	if not source.contains("active_bonus_summary(") \
			or not source.contains("MetaProgressionScript.load_data()") \
			or not source.contains("_floor_ctrl.current_biome"):
		failures.append("Main should include current-biome mastery in run summary meta bonuses")
	if not source.contains("\"stat_summary\": player.run_stat_summary()"):
		failures.append("Main should pass stat_summary into run summary context")
	if not source.contains("_run_stats_summary"):
		failures.append("Main should include run stats in run summary context")
	if not source.contains("_room_path_summary"):
		failures.append("Main should expose room path summary helper")
	if not source.contains("\"path\": _room_path_summary()"):
		failures.append("Main should include room path in run summary context")
	if not source.contains("_room_mastery_summary"):
		failures.append("Main should expose room mastery summary helper")
	if not source.contains("\"mastery\": _room_mastery_summary()"):
		failures.append("Main should include room mastery in run summary context")
	if not source.contains("_room_timing_summary"):
		failures.append("Main should expose room timing summary helper")
	if not source.contains("\"pace\": _room_timing_summary()"):
		failures.append("Main should include pace timing in run summary context")
	if not source.contains("_room_timing_context"):
		failures.append("Main should expose structured room timing context helper")
	for key in ["pace_timed_rooms", "pace_avg_sec", "pace_boss_sec", "pace_slow_count"]:
		if not source.contains("\"%s\"" % key):
			failures.append("Main should include structured timing key: %s" % key)
	if not source.contains("\"tuning_focus\": ReleaseAuditScript.balance_playtest_summary()"):
		failures.append("Main should include balance playtest focus in run summary context")
	if not source.contains("\"playtest_objective\": ReleaseAuditScript.playtest_objective_summary()"):
		failures.append("Main should include playtest objective in run summary context")
	if not source.contains("\"tuning_patch\": ReleaseAuditScript.tuning_patch_summary()"):
		failures.append("Main should include tuning patch preview in run summary context")
	if not source.contains("_balance_experiment_context"):
		failures.append("Main should expose Balance Lab experiment context helper")
	if not source.contains("\"balance_experiment\": _balance_experiment_summary()"):
		failures.append("Main should include Balance Lab experiment summary in run summary context")
	if not source.contains("\"release_audit\": ReleaseAuditScript.summary_text()"):
		failures.append("Main should include release audit in run summary context")
	if not source.contains("\"release_decision\": ReleaseAuditScript.public_release_decision()"):
		failures.append("Main should include public release decision in run summary context")
	if not source.contains("\"release_replacements\": _release_audit_replacement_count()"):
		failures.append("Main should include replacement blocker count in run summary context")
	if not source.contains("\"release_backlog\": ReleaseAuditScript.replacement_backlog_summary()"):
		failures.append("Main should include structured release backlog detail in run summary context")
	if not source.contains("\"release_next_action\": ReleaseAuditScript.next_release_action()"):
		failures.append("Main should pass release next action into run summary context")
	if not source.contains("_release_candidate_context"):
		failures.append("Main should expose release candidate context helper")
	if not source.contains("MetaProgressionScript.load_data(MetaProgressionScript.SAVE_PATH)"):
		failures.append("Main should load persisted release candidate evidence for run summary context")
	if not source.contains("ReleaseAuditScript.release_candidate_summary(meta)"):
		failures.append("Main should pass persisted release candidate evidence into run summary context")
	if not source.contains("\"release_candidate_evidence\": MetaProgressionScript.release_candidate_evidence_summary(meta)"):
		failures.append("Main should pass readable release candidate evidence into run summary context")
	if not source.contains("\"manual_scenario_evidence_draft\": _manual_scenario_evidence_draft()"):
		failures.append("Main should pass a pending manual scenario evidence draft into run summary context")
	if not source.contains("manual_playtest_checklist"):
		failures.append("Main should derive manual scenario evidence drafts from the release checklist")
	for key in ["release_candidate_status", "release_candidate_next_action",
			"release_candidate_blockers", "release_candidate_evidence"]:
		if not source.contains("\"%s\"" % key):
			failures.append("Main should include release candidate key: %s" % key)
	if not source.contains("\"seed\": run_seed"):
		failures.append("Main should include run seed in run summary context")
	if not source.contains("\"seed_label\": _run_seed_context_label()"):
		failures.append("Main should include readable run seed label in summary context")
	if not source.contains("\"daily_fingerprint\": _daily_seed_fingerprint_context()"):
		failures.append("Main should include Daily Seed fingerprint in run summary context")
	if not source.contains("func _daily_seed_fingerprint_context"):
		failures.append("Main should expose Daily Seed fingerprint context helper")
	if not source.contains("\"difficulty\": _run_difficulty_label()"):
		failures.append("Main should include run difficulty in run summary context")
	if not source.contains("\"threat\": _run_threat_label()"):
		failures.append("Main should include run threat in run summary context")
	if not source.contains("active_bonus_summary"):
		failures.append("Main should include active meta bonuses in run summary context")
	if not source.contains("\"meta_bonuses\":"):
		failures.append("Main should pass meta_bonuses into run summary context")
	if not source.contains("weapon_loadout_summary"):
		failures.append("Main should include weapon loadout in run summary context")
	if not source.contains("\"weapons\":"):
		failures.append("Main should pass weapons into run summary context")
	if not source.contains("\"run_finale\": _is_run_finale_summary()"):
		failures.append("Main should flag final boss victory in run summary context")
	if not source.contains("func _is_run_finale_summary"):
		failures.append("Main should expose run finale summary helper")
	if not source.contains("\"decisions\": _run_decision_summary()"):
		failures.append("Main should include run decision counters in run summary context")
	if not source.contains("\"floor_recap\": _run_floor_recap_summary()"):
		failures.append("Main should include latest floor recap in run summary context")
	if not source.contains("_record_floor_start_snapshot()"):
		failures.append("Main should record floor recap snapshot on floor start")
	if not source.contains("_floor_delta_summary()"):
		failures.append("Main should compute delta-based floor recap")
	if not source.contains("_run_decision_summary()"):
		failures.append("Main should expose run decision summary helper")
	if not source.contains("_run_economy_context"):
		failures.append("Main should expose structured economy context helper")
	for key in ["economy_gold_earned", "decision_reward_picks", "decision_shop_buys"]:
		if not source.contains("\"%s\"" % key):
			failures.append("Main should include structured economy key: %s" % key)
	if not source.contains("_reward_pick_count"):
		failures.append("Main should track reward pick count")
	if not source.contains("_shop_buy_count"):
		failures.append("Main should track shop buy count")
	if not source.contains("_shop_leave_count"):
		failures.append("Main should track shop leave count")
	if not source.contains("func _run_seed_context_label"):
		failures.append("Main should expose run seed context label helper")
	if not source.contains("func _run_difficulty_label"):
		failures.append("Main should expose run difficulty label helper")
	if not source.contains("func _run_threat_label"):
		failures.append("Main should expose run threat label helper")
	var summary_source := FileAccess.get_file_as_string("res://scripts/ui/run_summary.gd")
	if not summary_source.contains("upgrade_purchase_hint"):
		failures.append("RunSummary should use MetaProgression upgrade_purchase_hint for post-run hub guidance")
	if not summary_source.contains("Floor Recap:"):
		failures.append("RunSummary should print the latest floor recap when provided")
	if not summary_source.contains("Release Candidate:"):
		failures.append("RunSummary should print release candidate status when provided")
	if not summary_source.contains("release_candidate_evidence"):
		failures.append("RunSummary should print readable release candidate evidence when provided")
	if not summary_source.contains("Manual Evidence Draft:"):
		failures.append("RunSummary should print a pending manual evidence draft when provided")
