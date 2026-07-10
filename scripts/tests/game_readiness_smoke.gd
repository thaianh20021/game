extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_game_readiness_report(failures)
	if failures.is_empty():
		print("Game readiness smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_game_readiness_report(failures: Array[String]) -> void:
	var release_audit = load(RELEASE_AUDIT_PATH)
	if not release_audit.has_method("game_readiness_report"):
		failures.append("ReleaseAudit should expose game_readiness_report for MVP/release goal audit")
		return
	var report: Dictionary = release_audit.call("game_readiness_report")
	if not bool(report.get("ready", false)):
		failures.append("game readiness report should be ready when all MVP gates pass")
	if not Array(report.get("blockers", [])).is_empty():
		failures.append("game readiness report should expose no blockers for current MVP gates")

	var milestones: Dictionary = report.get("milestones", {})
	_expect_milestone_ready(milestones, "class_roster", failures)
	_expect_milestone_ready(milestones, "starter_loadouts", failures)
	_expect_milestone_ready(milestones, "weapon_pool", failures)
	_expect_milestone_ready(milestones, "enemy_roster", failures)
	_expect_milestone_ready(milestones, "relic_pool", failures)
	_expect_milestone_ready(milestones, "element_system", failures)
	_expect_milestone_ready(milestones, "first_run_boot", failures)
	_expect_milestone_ready(milestones, "run_progression", failures)
	_expect_milestone_ready(milestones, "room_objectives", failures)
	_expect_milestone_ready(milestones, "skill_feedback", failures)
	_expect_milestone_ready(milestones, "boss_phase", failures)
	_expect_milestone_ready(milestones, "combat_readability", failures)
	_expect_milestone_ready(milestones, "input_controls", failures)
	_expect_milestone_ready(milestones, "run_lifecycle", failures)
	_expect_milestone_ready(milestones, "hub_meta", failures)
	_expect_milestone_ready(milestones, "meta_persistence", failures)
	_expect_milestone_ready(milestones, "hub_navigation", failures)
	_expect_milestone_ready(milestones, "run_modes", failures)
	_expect_milestone_ready(milestones, "asset_release_gate", failures)

	var class_roster: Dictionary = milestones.get("class_roster", {})
	if int(class_roster.get("class_count", 0)) < 10:
		failures.append("readiness should count at least 10 classes")
	if int(class_roster.get("active_skill_script_count", 0)) < 20:
		failures.append("readiness should verify scripts for two active skills per class")
	if int(class_roster.get("ultimate_script_count", 0)) < 10:
		failures.append("readiness should verify one ultimate script per class")

	var weapon_pool: Dictionary = milestones.get("weapon_pool", {})
	if int(weapon_pool.get("weapon_count", 0)) < 12:
		failures.append("readiness should count at least 12 weapons")

	var enemy_roster: Dictionary = milestones.get("enemy_roster", {})
	if int(enemy_roster.get("normal_enemy_count", 0)) < 10:
		failures.append("readiness should count at least 10 normal enemies")
	if int(enemy_roster.get("boss_count", 0)) < 2:
		failures.append("readiness should count at least 2 bosses")
	if int(enemy_roster.get("enemy_pool_count", 0)) < 1:
		failures.append("readiness should verify enemy pool coverage")

	var relic_pool: Dictionary = milestones.get("relic_pool", {})
	if int(relic_pool.get("relic_count", 0)) < 15:
		failures.append("readiness should count at least 15 relic/build upgrades")
	if int(relic_pool.get("rarity_count", 0)) < 3:
		failures.append("readiness should verify common/rare/epic relic rarities")

	var element_system: Dictionary = milestones.get("element_system", {})
	if int(element_system.get("element_count", 0)) < 4:
		failures.append("readiness should count 4 MVP elements")
	if int(element_system.get("combo_count", 0)) < 6:
		failures.append("readiness should count 6 MVP element combos")

	var first_run_boot: Dictionary = milestones.get("first_run_boot", {})
	if str(first_run_boot.get("main_scene_path", "")) != "res://scenes/main.tscn":
		failures.append("readiness should verify project boots through main scene")
	if not bool(first_run_boot.get("class_select_boot_contract", false)):
		failures.append("readiness should verify class select appears before a run starts")
	if not bool(first_run_boot.get("start_run_contract", false)):
		failures.append("readiness should verify start_run creates playable run systems")
	if not bool(first_run_boot.get("boot_status_contract", false)):
		failures.append("readiness should verify boot_status exposes first-run state")
	if not bool(first_run_boot.get("first_run_readiness_contract", false)):
		failures.append("readiness should verify first-run UX readiness contract")
	if not bool(first_run_boot.get("route_choice_contract", false)):
		failures.append("readiness should verify first-room route choice contract")
	if int(first_run_boot.get("start_run_system_count", 0)) < 4:
		failures.append("readiness should count player/floor/HUD/overlay boot systems")
	if int(first_run_boot.get("first_run_required_signal_count", 0)) < 6:
		failures.append("readiness should count boot signal hooks")

	var run_progression: Dictionary = milestones.get("run_progression", {})
	if int(run_progression.get("biome_count", 0)) < 4:
		failures.append("readiness should verify at least 4 floor biomes")
	if int(run_progression.get("finale_biome_count", 0)) < 1:
		failures.append("readiness should verify a run finale biome")
	if int(run_progression.get("endless_biome_count", 0)) < 1:
		failures.append("readiness should verify an endless/post-finale biome")

	var room_objectives: Dictionary = milestones.get("room_objectives", {})
	if int(room_objectives.get("objective_room_count", 0)) < 6:
		failures.append("readiness should verify core objective room types")
	if int(room_objectives.get("reward_choice_count", 0)) != 3:
		failures.append("readiness should verify 1-of-3 room reward choices")
	if int(room_objectives.get("shop_choice_count", 0)) != 3:
		failures.append("readiness should verify 3 shop choices")
	if not bool(room_objectives.get("heal_shrine_one_shot", false)):
		failures.append("readiness should verify heal shrine one-shot contract")
	if not bool(room_objectives.get("locked_chest_key_gate", false)):
		failures.append("readiness should verify locked chest key gate")
	if int(room_objectives.get("trap_kind_count", 0)) < 4:
		failures.append("readiness should verify trap room hazard variants")

	var skill_feedback: Dictionary = milestones.get("skill_feedback", {})
	if int(skill_feedback.get("active_skill_feedback_count", 0)) < 20:
		failures.append("readiness should verify feedback profiles for two active skills per class")
	if int(skill_feedback.get("cooldown_icon_count", 0)) < 20:
		failures.append("readiness should verify cooldown icon tokens for active skills")
	if int(skill_feedback.get("cast_sound_cue_count", 0)) < 20:
		failures.append("readiness should verify cast sound placeholders for active skills")
	if int(skill_feedback.get("hit_pause_profile_count", 0)) < 20:
		failures.append("readiness should verify light hit pause profiles for active skills")
	if not bool(skill_feedback.get("hud_cooldown_icon_contract", false)):
		failures.append("readiness should verify HUD cooldown icon contract")
	if int(skill_feedback.get("class_resource_feedback_count", 0)) < 4:
		failures.append("readiness should verify class resource feedback for pet/trap/ammo classes")
	if not bool(skill_feedback.get("blocked_feedback_contract", false)):
		failures.append("readiness should verify blocked skill/dash/weapon feedback contract")

	var boss_phase: Dictionary = milestones.get("boss_phase", {})
	if int(boss_phase.get("phase_pattern_count", 0)) < 3:
		failures.append("readiness should verify three readable boss phase patterns")
	if not bool(boss_phase.get("bullet_hell_contract", false)):
		failures.append("readiness should verify boss bullet hell contract")
	if not bool(boss_phase.get("trap_wave_contract", false)):
		failures.append("readiness should verify boss trap wave contract")
	if not bool(boss_phase.get("enrage_contract", false)):
		failures.append("readiness should verify boss enrage contract")
	if not bool(boss_phase.get("floating_gun_contract", false)):
		failures.append("readiness should verify boss floating gun pressure")
	if float(boss_phase.get("attack_telegraph_seconds", 0.0)) < 0.5:
		failures.append("readiness should verify readable boss attack telegraph timing")
	if not bool(boss_phase.get("boss_cue_contract", false)):
		failures.append("readiness should verify boss phase/attack cue audio hooks")

	var combat_readability: Dictionary = milestones.get("combat_readability", {})
	if float(combat_readability.get("min_attack_telegraph_seconds", 0.0)) < 0.5:
		failures.append("readiness should verify enemy attack telegraphs are at least 0.5s")
	if float(combat_readability.get("trap_min_telegraph_seconds", 0.0)) < 0.5:
		failures.append("readiness should verify trap telegraphs are at least 0.5s")
	if not bool(combat_readability.get("enemy_projectile_windup_contract", false)):
		failures.append("readiness should verify projectile windup contract")
	if not bool(combat_readability.get("enemy_contact_windup_contract", false)):
		failures.append("readiness should verify contact damage windup contract")
	if not bool(combat_readability.get("trap_telegraph_contract", false)):
		failures.append("readiness should verify trap telegraph contract")
	if not bool(combat_readability.get("boss_attack_warning_contract", false)):
		failures.append("readiness should verify boss warning/readability contract")
	if not bool(combat_readability.get("boss_bullet_hell_delay_contract", false)):
		failures.append("readiness should verify boss bullet hell delay contract")
	if not bool(combat_readability.get("damage_source_contract", false)):
		failures.append("readiness should verify readable damage source labels")
	if not bool(combat_readability.get("hud_damage_feedback_contract", false)):
		failures.append("readiness should verify HUD/player damage feedback contract")
	if not bool(combat_readability.get("hidden_one_shot_guard_contract", false)):
		failures.append("readiness should verify no normal readable hit can one-shot base HP")
	if int(combat_readability.get("max_single_hit_damage", 999)) >= int(
			combat_readability.get("min_player_hp", 0)):
		failures.append("readiness should keep max single hit below minimum class HP")

	var input_controls: Dictionary = milestones.get("input_controls", {})
	if int(input_controls.get("critical_action_count", 0)) < int(
			input_controls.get("required_critical_action_count", 17)):
		failures.append("readiness should verify all critical gameplay input actions")
	if str(input_controls.get("ultimate_key_label", "")) != "V":
		failures.append("readiness should verify V is the ultimate key")
	if str(input_controls.get("cycle_key_label", "")) != "Q":
		failures.append("readiness should verify Q cycles elements")
	if str(input_controls.get("restart_key_label", "")) != "R":
		failures.append("readiness should verify R remains restart")
	if not bool(input_controls.get("ultimate_restart_separated", false)):
		failures.append("readiness should verify ultimate and restart do not share a key")
	if not bool(input_controls.get("ultimate_cycle_separated", false)):
		failures.append("readiness should verify ultimate and cycle element do not share a key")
	if not bool(input_controls.get("hud_hint_contract", false)):
		failures.append("readiness should verify in-run HUD control hint")
	if not bool(input_controls.get("onboarding_hint_contract", false)):
		failures.append("readiness should verify class select control hint")

	var run_lifecycle: Dictionary = milestones.get("run_lifecycle", {})
	if not bool(run_lifecycle.get("pause_resume_contract", false)):
		failures.append("readiness should verify pause/resume flow")
	if not bool(run_lifecycle.get("restart_contract", false)):
		failures.append("readiness should verify restart flow")
	if not bool(run_lifecycle.get("class_select_return_contract", false)):
		failures.append("readiness should verify return-to-class-select flow")
	if not bool(run_lifecycle.get("defeat_overlay_contract", false)):
		failures.append("readiness should verify defeat overlay flow")
	if not bool(run_lifecycle.get("victory_overlay_contract", false)):
		failures.append("readiness should verify victory overlay flow")
	if not bool(run_lifecycle.get("run_summary_context_contract", false)):
		failures.append("readiness should verify run summary context")
	if int(run_lifecycle.get("overlay_action_count", 0)) < 3:
		failures.append("readiness should verify pause overlay action buttons")
	if int(run_lifecycle.get("run_end_action_count", 0)) < 2:
		failures.append("readiness should verify run end action buttons")
	if int(run_lifecycle.get("run_end_cue_count", 0)) < 2:
		failures.append("readiness should verify victory/defeat cues")

	var hub_meta: Dictionary = milestones.get("hub_meta", {})
	if int(hub_meta.get("hub_service_count", 0)) < 5:
		failures.append("readiness should verify the 5 core hub services")
	if int(hub_meta.get("meta_upgrade_count", 0)) < 8:
		failures.append("readiness should verify the meta upgrade set")

	var meta_persistence: Dictionary = milestones.get("meta_persistence", {})
	if str(meta_persistence.get("save_path", "")) != "user://meta_progression.json":
		failures.append("readiness should verify the real meta progression save path")
	if int(meta_persistence.get("meta_currency_count", 0)) < 4:
		failures.append("readiness should verify all meta currencies persist")
	if int(meta_persistence.get("upgrade_count", 0)) < 8:
		failures.append("readiness should verify persistent meta upgrades")
	if int(meta_persistence.get("record_contract_count", 0)) < 6:
		failures.append("readiness should verify class/mode/element/biome/boss/enemy records")
	for key in [
			"persistence_contract",
			"run_banking_contract",
			"profile_reset_contract",
			"upgrade_purchase_contract",
			"meta_bonus_contract",
			"recent_run_telemetry_contract",
			"balance_evidence_contract",
	]:
		if not bool(meta_persistence.get(key, false)):
			failures.append("readiness should verify meta persistence %s" % key)

	var hub_navigation: Dictionary = milestones.get("hub_navigation", {})
	if int(hub_navigation.get("hub_service_button_count", 0)) < 5:
		failures.append("readiness should verify all hub service buttons")
	if int(hub_navigation.get("hub_service_hotkey_count", 0)) < 5:
		failures.append("readiness should verify all hub service hotkeys")
	if int(hub_navigation.get("run_mode_count", 0)) < 6:
		failures.append("readiness should verify all run mode buttons")
	if int(hub_navigation.get("run_mode_hotkey_count", 0)) < 6:
		failures.append("readiness should verify all run mode hotkeys")
	if int(hub_navigation.get("class_hotkey_count", 0)) < 10:
		failures.append("readiness should verify class hotkeys 1-0")
	if int(hub_navigation.get("element_hotkey_count", 0)) < 4:
		failures.append("readiness should verify element hotkeys")
	for key in [
			"daily_seed_contract",
			"start_hotkey_contract",
			"codex_panel_contract",
			"hub_upgrade_filter_contract",
			"reset_confirm_contract",
			"class_select_sfx_contract",
			"loadout_preview_contract",
			"replay_last_run_contract",
	]:
		if not bool(hub_navigation.get(key, false)):
			failures.append("readiness should verify hub navigation %s" % key)

	var run_modes: Dictionary = milestones.get("run_modes", {})
	if int(run_modes.get("accepted_run_mode_count", 0)) < 6:
		failures.append("readiness should verify all supported run modes")
	if int(run_modes.get("daily_modifier_count", 0)) < 4:
		failures.append("readiness should verify the daily modifier pool")
	if int(run_modes.get("daily_goal_event_count", 0)) < 4:
		failures.append("readiness should verify daily goal event coverage")
	for key in [
			"run_cap_contract",
			"boss_rush_contract",
			"endless_contract",
			"hardcore_contract",
			"elemental_chaos_contract",
			"balance_lab_contract",
			"daily_reward_contract",
			"run_modifier_hud_contract",
			"run_summary_contract",
			"floor_modifier_contract",
	]:
		if not bool(run_modes.get(key, false)):
			failures.append("readiness should verify run mode %s" % key)

	var release_gate: Dictionary = milestones.get("asset_release_gate", {})
	if str(release_gate.get("release_decision", "")) != "public_ok":
		failures.append("readiness should include public_ok release decision")
	if int(release_gate.get("collision_polygon_checked_count", 0)) <= 0:
		failures.append("readiness should include collision polygon review evidence")
	if int(release_gate.get("object_visual_checked_count", 0)) <= 0:
		failures.append("readiness should include object visual review evidence")

	var summary := str(report.get("summary_text", ""))
	for token in ["Classes", "Weapons", "Enemies", "Relics", "Objectives", "Feedback", "Elements",
			"Boot", "Boss", "Controls", "Lifecycle", "MetaSave", "HubNav",
			"RunModes", "Readability",
			"Release public_ok",
			"fanmade reference-only"]:
		if not summary.contains(token):
			failures.append("readiness summary missing token %s" % token)

func _expect_milestone_ready(
		milestones: Dictionary,
		id: String,
		failures: Array[String],
) -> void:
	if not milestones.has(id):
		failures.append("readiness should expose %s milestone" % id)
		return
	var milestone: Dictionary = milestones.get(id, {})
	if not bool(milestone.get("ready", false)):
		failures.append("%s milestone should be ready" % id)
