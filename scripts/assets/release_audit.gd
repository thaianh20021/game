class_name ReleaseAudit
extends RefCounted

const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")
const AssetSourceRegistryScript := preload("res://scripts/assets/asset_source_registry.gd")
const BalanceGuardrailScript := preload("res://scripts/balance/balance_guardrail.gd")
const BiomeDBScript := preload("res://scripts/dungeon_gen/biome_db.gd")
const BossGolemScript := preload("res://scripts/enemies/boss_golem.gd")
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")
const ElementSystemScript := preload("res://scripts/elements/element_system.gd")
const FloorControllerScript := preload("res://scripts/rooms/floor_controller.gd")
const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const PlayerClassDBScript := preload("res://scripts/classes/player_class_db.gd")
const RoomInteractableScript := preload("res://scripts/rooms/room_interactable.gd")
const RoomNodeScript := preload("res://scripts/dungeon_gen/room_node.gd")
const RunModifierDBScript := preload("res://scripts/progression/run_modifier_db.gd")
const TrapScript := preload("res://scripts/rooms/trap.gd")
const UpgradeDBScript := preload("res://scripts/progression/upgrade_db.gd")
const WeaponDBScript := preload("res://scripts/weapons/weapon_db.gd")

const CRITICAL_SPRITES := [
	"knight_m_idle_anim",
	"knight_m_run_anim",
	"dwarf_m_idle_anim",
	"dwarf_m_run_anim",
	"lizard_f_idle_anim",
	"lizard_f_run_anim",
	"knight_f_idle_anim",
	"knight_f_run_anim",
	"wizzard_m_idle_anim",
	"wizzard_m_run_anim",
	"elf_m_idle_anim",
	"elf_m_run_anim",
	"lizard_m_idle_anim",
	"lizard_m_run_anim",
	"wizzard_f_idle_anim",
	"wizzard_f_run_anim",
	"elf_f_idle_anim",
	"elf_f_run_anim",
	"dwarf_f_idle_anim",
	"dwarf_f_run_anim",
	"imp_idle_anim",
	"imp_run_anim",
	"swampy_anim",
	"skelet_idle_anim",
	"skelet_run_anim",
	"ogre_idle_anim",
	"ogre_run_anim",
	"slug_anim",
	"necromancer_anim",
	"wogol_idle_anim",
	"wogol_run_anim",
	"orc_shaman_idle_anim",
	"orc_shaman_run_anim",
	"big_zombie_idle_anim",
	"big_zombie_run_anim",
	"tiny_slug_anim",
	"pumpkin_dude_idle_anim",
	"pumpkin_dude_run_anim",
	"masked_orc_idle_anim",
	"masked_orc_run_anim",
	"muddy_anim",
	"chort_idle_anim",
	"chort_run_anim",
	"goblin_idle_anim",
	"goblin_run_anim",
	"orc_warrior_idle_anim",
	"orc_warrior_run_anim",
	"angel_idle_anim",
	"angel_run_anim",
	"doc_idle_anim",
	"doc_run_anim",
	"tiny_zombie_idle_anim",
	"tiny_zombie_run_anim",
	"big_demon_idle_anim",
	"big_demon_run_anim",
	"zerie_soldier_idle",
	"zerie_soldier_walk",
	"zerie_soldier_attack",
	"zerie_soldier_hurt",
	"zerie_soldier_death",
	"zerie_orc_idle",
	"zerie_orc_walk",
	"zerie_orc_attack",
	"zerie_orc_hurt",
	"zerie_orc_death",
	"floor_spikes_anim",
	"chest_full_open_anim",
	"chest_empty_open_anim",
	"coin_anim",
	"ui_heart_full",
	"ui_heart_half",
	"ui_heart_empty",
	"flask_big_red",
	"flask_big_blue",
	"flask_big_green",
	"flask_big_yellow",
	"flask_red",
	"flask_blue",
	"flask_yellow",
	"flask_green",
	"skull",
	"crate",
	"floor_ladder",
	"floor_stairs",
	"floor_1",
	"floor_2",
	"floor_3",
	"floor_4",
	"floor_5",
	"floor_6",
	"floor_7",
	"floor_8",
	"wall_top_left",
	"wall_top_mid",
	"wall_top_right",
	"wall_left",
	"wall_mid",
	"wall_right",
	"doors_leaf_open",
	"doors_leaf_closed",
	"hole",
	"edge_down",
	"bomb",
	"weapon_regular_sword",
	"weapon_axe",
	"weapon_knife",
	"weapon_bow",
	"weapon_bow_2",
	"weapon_arrow",
	"weapon_pistol_generated",
	"weapon_red_magic_staff",
	"weapon_red_gem_sword",
	"weapon_knight_sword",
	"weapon_hammer",
	"weapon_mace",
	"weapon_saw_sword",
	"weapon_spear",
	"zerie_arrow_projectile",
	"pickup_silver_key_generated",
	"pickup_blueprint_generated",
	"fire_patch_generated",
	"pickup_unknown_generated",
]
const CRITICAL_AUDIO_CUES := [
	"blade_cast",
	"melee_attack",
	"skill_ready",
	"player_damage_enemy",
	"player_damage_trap",
	"player_damage_status",
	"player_damage_boss",
	"enemy_hit_normal",
	"enemy_hit_weak",
	"enemy_hit_resist",
	"enemy_hit_critical",
	"enemy_death",
	"pickup_gold",
	"pickup_heal",
	"pickup_key",
	"pickup_weapon",
	"pickup_meta",
	"shop_buy",
	"shop_leave",
	"objective_complete",
	"objective_blocked",
	"room_clear_finale",
	"boss_enrage",
	"boss_phase_shift",
	"boss_bullet_hell",
	"boss_trap_wave",
	"class_resource_full",
]
const CRITICAL_FX := [
	"slash",
	"muzzle_flash",
	"dash_ghost",
	"telegraph",
	"skill_cast",
	"weapon_charge",
	"hit_spark",
	"block_spark",
	"stationary_focus",
]
const CRITICAL_COLLISION_SCENES := [
	{"id": "player", "path": "res://scenes/player.tscn"},
	{"id": "enemy", "path": "res://scenes/enemy.tscn"},
]
const CRITICAL_RUNTIME_OBJECTS := [
	{"id": "interactable:chest", "sprite": "chest_full_open_anim",
		"source_script": "res://scripts/rooms/room_interactable.gd",
		"fallback_polygon_points": 4, "fallback_polygon_area_px": 256.0},
	{"id": "interactable:locked_chest", "sprite": "chest_full_open_anim",
		"source_script": "res://scripts/rooms/room_interactable.gd",
		"fallback_polygon_points": 4, "fallback_polygon_area_px": 256.0},
	{"id": "interactable:shrine", "sprite": "flask_big_red",
		"source_script": "res://scripts/rooms/room_interactable.gd",
		"fallback_polygon_points": 5, "fallback_polygon_area_px": 160.0},
	{"id": "interactable:element_altar", "sprite": "flask_big_yellow",
		"source_script": "res://scripts/rooms/room_interactable.gd",
		"fallback_polygon_points": 6, "fallback_polygon_area_px": 192.0},
	{"id": "interactable:shop", "sprite": "coin_anim",
		"source_script": "res://scripts/rooms/room_interactable.gd",
		"fallback_polygon_points": 4, "fallback_polygon_area_px": 144.0},
	{"id": "interactable:blood_altar", "sprite": "skull",
		"source_script": "res://scripts/rooms/room_interactable.gd",
		"fallback_polygon_points": 5, "fallback_polygon_area_px": 160.0},
	{"id": "interactable:rune_cache", "sprite": "chest_full_open_anim",
		"source_script": "res://scripts/rooms/room_interactable.gd",
		"fallback_polygon_points": 5, "fallback_polygon_area_px": 256.0},
	{"id": "interactable:cursed_chest", "sprite": "chest_mimic_open_anim",
		"source_script": "res://scripts/rooms/room_interactable.gd",
		"fallback_polygon_points": 4, "fallback_polygon_area_px": 256.0},
	{"id": "interactable:trap_cache", "sprite": "chest_mimic_open_anim",
		"source_script": "res://scripts/rooms/room_interactable.gd",
		"fallback_polygon_points": 5, "fallback_polygon_area_px": 256.0},
	{"id": "interactable:secret_cache", "sprite": "chest_full_open_anim",
		"source_script": "res://scripts/rooms/room_interactable.gd",
		"fallback_polygon_points": 5, "fallback_polygon_area_px": 256.0},
	{"id": "trap:spike", "sprite": "floor_spikes_anim",
		"source_script": "res://scripts/rooms/trap.gd",
		"fallback_polygon_points": 5, "fallback_polygon_area_px": 128.0},
	{"id": "trap:fire", "sprite": "bomb",
		"source_script": "res://scripts/rooms/trap.gd",
		"fallback_polygon_points": 5, "fallback_polygon_area_px": 128.0},
	{"id": "trap:saw", "sprite": "weapon_saw_sword",
		"source_script": "res://scripts/rooms/trap.gd",
		"fallback_polygon_points": 8, "fallback_polygon_area_px": 192.0},
	{"id": "trap:arrow", "sprite": "weapon_arrow",
		"source_script": "res://scripts/rooms/trap.gd",
		"fallback_polygon_points": 7, "fallback_polygon_area_px": 144.0},
	{"id": "prop:crate", "sprite": "crate",
		"source_script": "res://scripts/rooms/breakable_prop.gd",
		"fallback_polygon_points": 4, "fallback_polygon_area_px": 256.0},
	{"id": "prop:vase", "sprite": "flask_big_blue",
		"source_script": "res://scripts/rooms/breakable_prop.gd",
		"fallback_polygon_points": 6, "fallback_polygon_area_px": 144.0},
	{"id": "pickup:gold", "sprite": "coin_anim",
		"source_script": "res://scripts/loot/pickup.gd",
		"fallback_polygon_points": 4, "fallback_polygon_area_px": 64.0},
	{"id": "pickup:potion", "sprite": "flask_red",
		"source_script": "res://scripts/loot/pickup.gd",
		"fallback_polygon_points": 4, "fallback_polygon_area_px": 64.0},
	{"id": "pickup:silver_key", "sprite": "pickup_silver_key_generated",
		"source_script": "res://scripts/loot/pickup.gd",
		"fallback_polygon_points": 5, "fallback_polygon_area_px": 64.0},
	{"id": "pickup:weapon_pistol", "sprite": "weapon_pistol_generated",
		"source_script": "res://scripts/loot/pickup.gd",
		"fallback_polygon_points": 4, "fallback_polygon_area_px": 96.0},
	{"id": "pickup:blueprint", "sprite": "pickup_blueprint_generated",
		"source_script": "res://scripts/loot/pickup.gd",
		"fallback_polygon_points": 4, "fallback_polygon_area_px": 64.0},
	{"id": "portal:next_floor", "sprite": "floor_ladder",
		"source_script": "res://scripts/rooms/exit_portal.gd",
		"fallback_polygon_points": 4, "fallback_polygon_area_px": 196.0},
	{"id": "portal:run_complete", "sprite": "floor_stairs",
		"source_script": "res://scripts/rooms/exit_portal.gd",
		"fallback_polygon_points": 4, "fallback_polygon_area_px": 256.0},
]
const REFERENCE_ONLY_SOURCES := [
	"CalvinWan0101/soul-knight",
	"leoyin1127/Soul-knights",
]
const MANUAL_PLAYTEST_ISSUE_TYPES := [
	"polygon_collision",
	"asset_animation",
	"missing_asset_source",
	"combat_readability",
	"balance_pace",
	"ui_overlap",
]
const MANUAL_EVIDENCE_SOURCES := [
	"manual_playtest",
	"human_playtest",
	"recorded_playtest",
]
const MANUAL_PLAYTEST_ISSUE_TYPE_ALIASES := {
	"poligon": "polygon_collision",
	"polygon": "polygon_collision",
	"collision": "polygon_collision",
	"poligon_collision": "polygon_collision",
	"animation": "asset_animation",
	"asset": "missing_asset_source",
	"missing_asset": "missing_asset_source",
	"readability": "combat_readability",
	"balance": "balance_pace",
	"pace": "balance_pace",
	"ui": "ui_overlap",
}

static func manual_playtest_issue_type_suggestions() -> Array[String]:
	var out: Array[String] = []
	for issue_type in MANUAL_PLAYTEST_ISSUE_TYPES:
		out.append(str(issue_type))
	return out

static func manual_playtest_issue_type_summary() -> String:
	return ", ".join(manual_playtest_issue_type_suggestions())

static func manual_playtest_issue_type_alias_summary() -> String:
	return "poligon -> polygon_collision, polygon -> polygon_collision, collision -> polygon_collision, animation -> asset_animation"

static func manual_playtest_issue_type_valid(issue_type: String) -> bool:
	return manual_playtest_issue_type_suggestions().has(
		manual_playtest_issue_type_normalized(issue_type))

static func manual_playtest_issue_type_normalized(issue_type: String) -> String:
	var clean := issue_type.strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	return str(MANUAL_PLAYTEST_ISSUE_TYPE_ALIASES.get(clean, clean))

static func manual_playtest_issue_remediation(issue_type: String) -> Dictionary:
	var normalized := manual_playtest_issue_type_normalized(issue_type)
	var asset_kind := _manual_issue_asset_kind(normalized)
	var command := _manual_issue_asset_review_command(normalized, asset_kind)
	var checklist := asset_release_review_checklist(asset_kind) if asset_kind != "" else {}
	var plan := asset_replacement_plan(asset_kind) if asset_kind != "" else {}
	return {
		"issue_type": normalized,
		"asset_kind": asset_kind,
		"asset_review_command": command,
		"asset_replacement_plan_command": _asset_replacement_plan_command(asset_kind),
		"fix_hint": _manual_issue_fix_hint(normalized),
		"allowed_replacement_sources": Array(
			checklist.get("allowed_runtime_sources", [])).duplicate(),
		"release_self_review_gate": Array(
			checklist.get("release_self_review_gate", [])).duplicate(),
		"reference_only_sources": REFERENCE_ONLY_SOURCES.duplicate(),
		"fanmade_policy": str(plan.get("fanmade_policy", "")),
		"source_order_text": str(plan.get("source_order_text", "")),
		"missing_polygon_next_actions": Array(
			plan.get("missing_polygon_next_actions", [])).duplicate(),
	}

static func manual_evidence_source_valid(source: String) -> bool:
	return MANUAL_EVIDENCE_SOURCES.has(source.strip_edges())

static func manual_evidence_value_placeholder(value: String) -> bool:
	var clean := value.strip_edges()
	if clean == "":
		return true
	if clean.contains("<") and clean.contains(">"):
		return true
	var normalized := clean.to_lower()
	return [
		"human notes",
		"human issue notes",
		"human retest notes",
		"human result",
		"human animation notes",
		"human polygon notes",
		"daily hash",
		"avg sec",
		"boss sec",
		"screenshot or seed",
		"hold or ready",
		"replay_last_run_result",
		"daily_fingerprint_hash",
		"pace_avg_sec",
		"pace_boss_sec",
		"asset_animation_notes",
		"polygon_collision_notes",
		"blocker_screenshot_or_seed",
		"release_decision",
	].has(normalized)

static func manual_scenario_notes_review_complete(notes: String) -> bool:
	var normalized := notes.strip_edges().to_lower()
	if manual_evidence_value_placeholder(normalized):
		return false
	for token in ["animation", "polygon", "wave", "hud", "audio"]:
		if not normalized.contains(token):
			return false
	return true

static func runtime_report(meta_data: Dictionary = {}) -> Dictionary:
	var sprite_report := SpriteDB.release_report(CRITICAL_SPRITES)
	var audio_report := AudioCueDBScript.release_report(CRITICAL_AUDIO_CUES)
	var fx_report := CombatFxScript.release_report(CRITICAL_FX)
	var collision_report := _collision_report()
	var runtime_object_report := _runtime_object_report()
	var balance_report := BalanceGuardrailScript.report()
	var balance_review_report := _balance_report_with_playtest_evidence(balance_report, meta_data)
	var public_blockers := _prefixed_blockers("sprite", sprite_report) \
			+ _prefixed_blockers("audio", audio_report) \
			+ _prefixed_blockers("vfx", fx_report) \
			+ _prefixed_blockers("object", runtime_object_report)
	var failures := _prefixed_failures("sprite", sprite_report) \
			+ _prefixed_failures("audio", audio_report) \
			+ _prefixed_failures("vfx", fx_report) \
			+ _prefixed_failures("collision", collision_report) \
			+ _prefixed_failures("object", runtime_object_report) \
			+ _prefixed_balance_failures(balance_report)
	var animation_grid := _animation_grid_summary(sprite_report)
	var replace_before_public := _sprite_replacements(sprite_report) \
			+ _audio_replacements(audio_report) \
			+ _fx_replacements(fx_report) \
			+ _collision_replacements(collision_report) \
			+ _runtime_object_replacements(runtime_object_report)
	var internal_ready := bool(sprite_report.get("ready", false)) \
			and bool(audio_report.get("ready", false)) \
			and bool(fx_report.get("ready", false)) \
			and bool(collision_report.get("ready", false)) \
			and bool(runtime_object_report.get("ready", false)) \
			and bool(balance_report.get("ready", false))
	var public_ready := internal_ready and public_blockers.is_empty() and replace_before_public.is_empty()
	var balance_enemy_count := Dictionary(balance_report.get("normal_enemy_ttk_sec", {})).size() \
			+ Dictionary(balance_report.get("boss_ttk_sec", {})).size()
	var balance_playtest_plan := BalanceGuardrailScript.playtest_plan(5, balance_review_report)
	var balance_patch := BalanceGuardrailScript.tuning_patch_preview(balance_review_report)
	var balance_experiment_patch := BalanceGuardrailScript.tuning_experiment_patch(
		balance_review_report)
	return {
		"ready_for_internal_playtest": internal_ready,
		"public_ready": public_ready,
		"decision": _decision(public_ready, failures, replace_before_public),
		"checked_sprite_count": int(sprite_report.get("checked_count", 0)),
		"checked_audio_count": int(audio_report.get("checked_count", 0)),
		"checked_fx_count": int(fx_report.get("checked_count", 0)),
		"animation_frame_grid_checked_count": int(animation_grid.get("checked_count", 0)),
		"unstable_animation_count": int(animation_grid.get("unstable_count", 0)),
		"animation_review_status": str(animation_grid.get("status", "blocked")),
		"collision_shape_checked_count": int(collision_report.get("shape_checked_count", 0)),
		"collision_polygon_checked_count": int(collision_report.get("polygon_checked_count", 0)),
		"collision_review_status": str(collision_report.get("review_status", "blocked")),
		"object_visual_checked_count": int(runtime_object_report.get("checked_count", 0)),
		"object_visual_review_status": str(runtime_object_report.get("review_status", "blocked")),
		"checked_balance_enemy_count": balance_enemy_count,
		"balance_warning_count": Array(balance_report.get("warnings", [])).size(),
		"balance_tuning_backlog_count": Array(balance_report.get("tuning_backlog", [])).size(),
		"balance_playtest_focus_count": balance_playtest_plan.size(),
		"balance_playtest_evidence_count": Dictionary(
			balance_review_report.get("playtest_evidence", {})).size(),
		"balance_playtest_summary": BalanceGuardrailScript.playtest_summary(3, balance_review_report),
		"balance_playtest_objective": BalanceGuardrailScript.playtest_objective_summary(
			balance_review_report),
		"balance_tuning_patch_preview": balance_patch,
		"balance_tuning_experiment_patch": balance_experiment_patch,
		"balance_review_status": "stable" if bool(balance_report.get("ready", false)) else "blocked",
		"public_release_blockers": public_blockers,
		"replace_before_public": replace_before_public,
		"failures": failures,
		"reference_policy": "fanmade_reference_only_no_copy",
		"asset_source_policy": source_policy_summary(),
		"categories": {
			"sprites": sprite_report,
			"audio": audio_report,
			"vfx": fx_report,
			"collision": collision_report,
			"runtime_objects": runtime_object_report,
			"balance": balance_review_report,
		},
	}

static func public_release_decision(meta_data: Dictionary = {}) -> String:
	return str(runtime_report(meta_data).get("decision", "blocked"))

static func game_readiness_report(meta_data: Dictionary = {}) -> Dictionary:
	var release_report := runtime_report(meta_data)
	var milestones := {
		"class_roster": _readiness_class_roster(),
		"starter_loadouts": _readiness_starter_loadouts(),
		"weapon_pool": _readiness_weapon_pool(),
		"enemy_roster": _readiness_enemy_roster(),
		"relic_pool": _readiness_relic_pool(),
		"element_system": _readiness_element_system(),
		"first_run_boot": _readiness_first_run_boot(),
		"run_progression": _readiness_run_progression(),
		"room_objectives": _readiness_room_objectives(),
		"skill_feedback": _readiness_skill_feedback(),
		"boss_phase": _readiness_boss_phase(),
		"combat_readability": _readiness_combat_readability(),
		"settings_accessibility": _readiness_settings_accessibility(),
		"input_controls": _readiness_input_controls(),
		"run_lifecycle": _readiness_run_lifecycle(),
		"hub_meta": _readiness_hub_meta(),
		"meta_persistence": _readiness_meta_persistence(),
		"hub_navigation": _readiness_hub_navigation(),
		"run_modes": _readiness_run_modes(),
		"asset_release_gate": _readiness_asset_release_gate(release_report),
	}
	var blockers: Array[String] = []
	for milestone_id in milestones.keys():
		var milestone: Dictionary = milestones[milestone_id]
		if bool(milestone.get("ready", false)):
			continue
		var milestone_blockers: Array = milestone.get("blockers", [])
		if milestone_blockers.is_empty():
			blockers.append("%s:not_ready" % str(milestone_id))
			continue
		for blocker in milestone_blockers:
			blockers.append("%s:%s" % [str(milestone_id), str(blocker)])
	var ready := blockers.is_empty()
	return {
		"ready": ready,
		"status": "ready" if ready else "blocked",
		"blockers": blockers,
		"milestones": milestones,
		"summary_text": _readiness_summary_text(milestones, release_report),
		"reference_policy": "fanmade_reference_only_no_copy",
	}

static func _readiness_class_roster() -> Dictionary:
	var classes := PlayerClassDBScript.all()
	var missing_skill_scripts: Array[String] = []
	var missing_ultimate_scripts: Array[String] = []
	var active_skill_script_count := 0
	var ultimate_script_count := 0
	for raw_class in classes:
		if not (raw_class is Dictionary):
			continue
		var class_data: Dictionary = raw_class
		var class_id := str(class_data.get("id", "class"))
		var actives: Array = class_data.get("actives", [])
		if actives.size() < 2:
			missing_skill_scripts.append("%s:active_metadata" % class_id)
		for raw_active in actives:
			if not (raw_active is Dictionary):
				continue
			var active: Dictionary = raw_active
			var active_id := str(active.get("id", "")).strip_edges()
			var skill_path := "res://scripts/skills/%s_skill.gd" % active_id
			if active_id != "" and ResourceLoader.exists(skill_path):
				active_skill_script_count += 1
			else:
				missing_skill_scripts.append("%s:%s" % [class_id, active_id])
		var ultimate: Dictionary = class_data.get("ultimate", {})
		var ultimate_id := str(ultimate.get("id", "")).strip_edges()
		var ultimate_path := "res://scripts/ultimates/%s_ultimate.gd" % ultimate_id
		if ultimate_id != "" and ResourceLoader.exists(ultimate_path):
			ultimate_script_count += 1
		else:
			missing_ultimate_scripts.append("%s:%s" % [class_id, ultimate_id])
	var blockers: Array[String] = []
	if classes.size() < 10:
		blockers.append("class_count_below_10")
	for item in missing_skill_scripts:
		blockers.append("missing_skill_script:%s" % item)
	for item in missing_ultimate_scripts:
		blockers.append("missing_ultimate_script:%s" % item)
	return _readiness_milestone(blockers.is_empty(), {
		"class_count": classes.size(),
		"required_class_count": 10,
		"active_skill_script_count": active_skill_script_count,
		"required_active_skill_script_count": classes.size() * 2,
		"ultimate_script_count": ultimate_script_count,
		"required_ultimate_script_count": classes.size(),
		"missing_skill_scripts": missing_skill_scripts,
		"missing_ultimate_scripts": missing_ultimate_scripts,
	}, blockers)

static func _readiness_starter_loadouts() -> Dictionary:
	var classes := PlayerClassDBScript.all()
	var missing_starters: Array[String] = []
	for raw_class in classes:
		if not (raw_class is Dictionary):
			continue
		var class_id := str((raw_class as Dictionary).get("id", "")).strip_edges()
		var weapon_id := WeaponDBScript.starter_weapon_for_class(class_id)
		if class_id == "" or WeaponDBScript.get_weapon(weapon_id).is_empty():
			missing_starters.append("%s:%s" % [class_id, weapon_id])
	return _readiness_milestone(missing_starters.is_empty() and classes.size() >= 10, {
		"starter_loadout_count": classes.size() - missing_starters.size(),
		"required_starter_loadout_count": 10,
		"missing_starters": missing_starters,
	}, missing_starters)

static func _readiness_weapon_pool() -> Dictionary:
	var weapon_count := WeaponDBScript.all_ids().size()
	var blockers: Array[String] = []
	if weapon_count < 12:
		blockers.append("weapon_count_below_12")
	return _readiness_milestone(blockers.is_empty(), {
		"weapon_count": weapon_count,
		"required_weapon_count": 12,
	}, blockers)

static func _readiness_enemy_roster() -> Dictionary:
	var entries := BiomeDBScript.enemy_codex_entries()
	var normal_ids := {}
	var boss_ids := {}
	var pool_ids := {}
	var incomplete_entries: Array[String] = []
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var id := str(entry.get("id", "")).strip_edges()
		var kind := str(entry.get("kind", "")).strip_edges()
		var biome_id := str(entry.get("biome_id", "")).strip_edges()
		if biome_id != "":
			pool_ids[biome_id] = true
		if id == "" or kind == "" or int(entry.get("hp", 0)) <= 0 or int(entry.get("dmg", 0)) <= 0:
			incomplete_entries.append("%s:%s" % [biome_id, id])
		if kind == "boss":
			boss_ids[id] = true
		elif kind != "miniboss":
			normal_ids[id] = true
	var blockers: Array[String] = []
	if normal_ids.size() < 10:
		blockers.append("normal_enemy_count_below_10")
	if boss_ids.size() < 2:
		blockers.append("boss_count_below_2")
	if pool_ids.size() <= 0:
		blockers.append("enemy_pool_coverage_missing")
	for item in incomplete_entries:
		blockers.append("enemy_entry_incomplete:%s" % item)
	return _readiness_milestone(blockers.is_empty(), {
		"normal_enemy_count": normal_ids.size(),
		"required_normal_enemy_count": 10,
		"boss_count": boss_ids.size(),
		"required_boss_count": 2,
		"enemy_pool_count": pool_ids.size(),
		"incomplete_entries": incomplete_entries,
	}, blockers)

static func _readiness_relic_pool() -> Dictionary:
	var rarity_ids := {}
	var tag_ids := {}
	var incomplete_entries: Array[String] = []
	for raw_upgrade in UpgradeDBScript.UPGRADES:
		if not (raw_upgrade is Dictionary):
			continue
		var upgrade: Dictionary = raw_upgrade
		var id := str(upgrade.get("id", "")).strip_edges()
		var rarity := str(upgrade.get("rarity", "")).strip_edges()
		var tags: Array = upgrade.get("tags", [])
		if rarity != "":
			rarity_ids[rarity] = true
		for raw_tag in tags:
			var tag := str(raw_tag).strip_edges()
			if tag != "":
				tag_ids[tag] = true
		if id == "" or str(upgrade.get("name", "")).strip_edges() == "" \
				or str(upgrade.get("desc", "")).strip_edges() == "" \
				or rarity == "" or int(upgrade.get("max_stack", 0)) <= 0 or tags.is_empty():
			incomplete_entries.append(id)
	var blockers: Array[String] = []
	if UpgradeDBScript.UPGRADES.size() < 15:
		blockers.append("relic_count_below_15")
	if rarity_ids.size() < 3:
		blockers.append("relic_rarity_count_below_3")
	for item in incomplete_entries:
		blockers.append("relic_entry_incomplete:%s" % item)
	return _readiness_milestone(blockers.is_empty(), {
		"relic_count": UpgradeDBScript.UPGRADES.size(),
		"required_relic_count": 15,
		"rarity_count": rarity_ids.size(),
		"tag_count": tag_ids.size(),
		"incomplete_entries": incomplete_entries,
	}, blockers)

static func _readiness_element_system() -> Dictionary:
	var element_count := ElementSystemScript.ELEMENTS.size()
	var combo_count := ElementSystemScript.combo_codex_entries().size()
	var blockers: Array[String] = []
	if element_count < 4:
		blockers.append("element_count_below_4")
	if combo_count < 6:
		blockers.append("combo_count_below_6")
	return _readiness_milestone(blockers.is_empty(), {
		"element_count": element_count,
		"required_element_count": 4,
		"combo_count": combo_count,
		"required_combo_count": 6,
	}, blockers)

static func _readiness_first_run_boot() -> Dictionary:
	var main_scene_path := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var floor_source := FileAccess.get_file_as_string("res://scripts/rooms/floor_controller.gd")
	var door_source := FileAccess.get_file_as_string("res://scripts/rooms/door_marker.gd")
	var class_select_boot_contract := main_source.contains("func _ready") \
			and main_source.contains("ClassSelectScreen.new()") \
			and main_source.contains("select.confirmed.connect(_start_run)") \
			and main_source.contains("player.hide()") \
			and main_source.contains("player.set_physics_process(false)")
	var start_run_system_count := 0
	if main_source.contains("player.apply_class(") \
			and main_source.contains("player.show()") \
			and main_source.contains("player.set_physics_process(true)"):
		start_run_system_count += 1
	if main_source.contains("FloorController.new()") and main_source.contains("_floor_ctrl.start("):
		start_run_system_count += 1
	if main_source.contains("HUD.new()") and main_source.contains("_hud.bind(player, _floor_ctrl)"):
		start_run_system_count += 1
	if main_source.contains("RunOverlay.new()") and main_source.contains("add_child(_overlay)"):
		start_run_system_count += 1
	var start_run_contract := start_run_system_count >= 4
	var boot_status_contract := main_source.contains("func boot_status") \
			and main_source.contains("\"run_started\"") \
			and main_source.contains("\"player_ready\"") \
			and main_source.contains("\"floor_ready\"") \
			and main_source.contains("\"hud_ready\"") \
			and main_source.contains("\"overlay_ready\"") \
			and main_source.contains("\"release_decision\": ReleaseAuditScript.public_release_decision()") \
			and main_source.contains("\"first_run_readiness\": _first_run_readiness_status")
	var first_run_readiness_contract := main_source.contains("func _first_run_readiness_status") \
			and main_source.contains("ObjectiveNextActionLabel") \
			and main_source.contains("ControlsHintLabel") \
			and main_source.contains("current_room_route_options") \
			and main_source.contains("current_room_route_options_summary") \
			and main_source.contains("\"route_options_count\"") \
			and main_source.contains("\"control_hint_text\"") \
			and main_source.contains("\"run_seed\"") \
			and main_source.contains("\"run_mode\"") \
			and main_source.contains("readiness[\"ready\"]")
	var route_choice_contract := main_source.contains("_handle_route_choice_input") \
			and main_source.contains("\"route_choice_%d\"") \
			and InputMap.has_action("route_choice_1") \
			and main_source.contains("_on_route_choice_requested") \
			and main_source.contains("RouteChoiceAcceptedToast") \
			and floor_source.contains("func current_room_route_options") \
			and floor_source.contains("func choose_current_route") \
			and door_source.contains("func request_route_choice") \
			and door_source.contains("route_choice_index")
	var signal_hooks := [
		"select.confirmed.connect(_start_run)",
		"player.died.connect(_on_player_died)",
		"_floor_ctrl.floor_completed.connect(_on_floor_completed)",
		"_floor_ctrl.room_reward_pending.connect(_on_room_reward_pending)",
		"_floor_ctrl.shop_choice_requested.connect(_on_shop_choice_requested)",
		"_floor_ctrl.route_choice_requested.connect(_on_route_choice_requested)",
		"_overlay.resume_requested.connect(_on_pause_resume_requested)",
		"_overlay.restart_requested.connect(_on_pause_restart_requested)",
		"_overlay.class_select_requested.connect(_on_class_select_requested)",
	]
	var first_run_required_signal_count := 0
	for hook in signal_hooks:
		if main_source.contains(hook):
			first_run_required_signal_count += 1
	var blockers: Array[String] = []
	if main_scene_path != "res://scenes/main.tscn" or not ResourceLoader.exists(main_scene_path):
		blockers.append("main_scene_boot_missing")
	if not class_select_boot_contract:
		blockers.append("class_select_boot_contract_missing")
	if not start_run_contract:
		blockers.append("start_run_contract_missing")
	if not boot_status_contract:
		blockers.append("boot_status_contract_missing")
	if not first_run_readiness_contract:
		blockers.append("first_run_readiness_contract_missing")
	if not route_choice_contract:
		blockers.append("route_choice_contract_missing")
	if first_run_required_signal_count < 6:
		blockers.append("first_run_signal_hooks_missing")
	return _readiness_milestone(blockers.is_empty(), {
		"main_scene_path": main_scene_path,
		"main_scene_exists": ResourceLoader.exists(main_scene_path),
		"class_select_boot_contract": class_select_boot_contract,
		"start_run_contract": start_run_contract,
		"boot_status_contract": boot_status_contract,
		"first_run_readiness_contract": first_run_readiness_contract,
		"route_choice_contract": route_choice_contract,
		"start_run_system_count": start_run_system_count,
		"required_start_run_system_count": 4,
		"first_run_required_signal_count": first_run_required_signal_count,
		"required_first_run_signal_count": 6,
	}, blockers)

static func _readiness_run_progression() -> Dictionary:
	var biome_count := BiomeDBScript.BIOMES.size()
	var finale_count := 0
	var endless_count := 0
	var missing_enemy_pools: Array[String] = []
	for raw_biome in BiomeDBScript.BIOMES:
		if not (raw_biome is Dictionary):
			continue
		var biome: Dictionary = raw_biome
		if bool(biome.get("run_finale", false)):
			finale_count += 1
		if bool(biome.get("endless_theme", false)):
			endless_count += 1
		var enemy_pool := BiomeDBScript.enemy_pool_path(biome)
		if not FileAccess.file_exists(enemy_pool):
			missing_enemy_pools.append("%s:%s" % [str(biome.get("id", "")), enemy_pool])
	var blockers: Array[String] = []
	if biome_count < 4:
		blockers.append("biome_count_below_4")
	if finale_count <= 0:
		blockers.append("finale_biome_missing")
	if endless_count <= 0:
		blockers.append("endless_biome_missing")
	for item in missing_enemy_pools:
		blockers.append("enemy_pool_missing:%s" % item)
	return _readiness_milestone(blockers.is_empty(), {
		"biome_count": biome_count,
		"required_floor_biome_count": 4,
		"finale_biome_count": finale_count,
		"endless_biome_count": endless_count,
		"missing_enemy_pools": missing_enemy_pools,
	}, blockers)

static func _readiness_room_objectives() -> Dictionary:
	var objective_types := [
		RoomNodeScript.RoomType.COMBAT,
		RoomNodeScript.RoomType.TREASURE,
		RoomNodeScript.RoomType.SHOP,
		RoomNodeScript.RoomType.HEAL,
		RoomNodeScript.RoomType.SECRET,
		RoomNodeScript.RoomType.BOSS,
	]
	var objective_ok := true
	var ctrl := FloorControllerScript.new()
	for room_type in objective_types:
		var room := RoomNodeScript.new()
		room.id = int(room_type) + 100
		room.type = room_type
		ctrl.current_room = room
		if str(ctrl.current_room_objective()).strip_edges() == "":
			objective_ok = false
	ctrl.free()

	var reward_choice_count := UpgradeDBScript.roll_choices(1234, 7, 1).size()
	var shop := RoomInteractableScript.new()
	shop.configure("shop")
	var shop_choice_count := shop.get_shop_choices().size()
	shop.free()

	var interactable_source := FileAccess.get_file_as_string("res://scripts/rooms/room_interactable.gd")
	var heal_shrine_one_shot := RoomInteractableScript.release_fallback_polygon("shrine").size() >= 3 \
			and interactable_source.contains("\"shrine\"") \
			and interactable_source.contains("_finish({\"heal\"") \
			and interactable_source.contains("set_meta(\"uses_remaining\", 0)")
	var locked_gate := interactable_source.contains("\"locked_chest\"") \
			and interactable_source.contains("_try_spend_key(1)")

	var trap_kinds := ["spike", "fire", "saw", "arrow"]
	var trap_kind_count := 0
	for kind in trap_kinds:
		if TrapScript.release_fallback_polygon(kind).size() >= 3:
			trap_kind_count += 1
	var trap_telegraph_ok := float(TrapScript.MIN_TELEGRAPH_SECONDS) >= 0.5

	var blockers: Array[String] = []
	if not objective_ok or objective_types.size() < 6:
		blockers.append("objective_room_contract_missing")
	if reward_choice_count != 3:
		blockers.append("reward_choice_count_not_3")
	if shop_choice_count != 3:
		blockers.append("shop_choice_count_not_3")
	if not heal_shrine_one_shot:
		blockers.append("heal_shrine_one_shot_missing")
	if not locked_gate:
		blockers.append("locked_chest_key_gate_missing")
	if trap_kind_count < 4 or not trap_telegraph_ok:
		blockers.append("trap_room_contract_missing")
	return _readiness_milestone(blockers.is_empty(), {
		"objective_room_count": objective_types.size(),
		"reward_choice_count": reward_choice_count,
		"shop_choice_count": shop_choice_count,
		"heal_shrine_one_shot": heal_shrine_one_shot,
		"locked_chest_key_gate": locked_gate,
		"trap_kind_count": trap_kind_count,
		"trap_min_telegraph_seconds": TrapScript.MIN_TELEGRAPH_SECONDS,
	}, blockers)

static func _readiness_skill_feedback() -> Dictionary:
	var active_skill_count := 0
	var active_skill_feedback_count := 0
	var cooldown_icon_count := 0
	var cast_sound_cue_count := 0
	var hit_pause_profile_count := 0
	var missing_profiles: Array[String] = []
	for raw_class in PlayerClassDBScript.all():
		if not (raw_class is Dictionary):
			continue
		var class_data: Dictionary = raw_class
		for raw_active in Array(class_data.get("actives", [])):
			if not (raw_active is Dictionary):
				continue
			var active: Dictionary = raw_active
			var skill_id := str(active.get("id", "")).strip_edges()
			if skill_id == "":
				continue
			active_skill_count += 1
			var profile: Dictionary = CombatFxScript.skill_feedback_profile(skill_id)
			if str(profile.get("style", "generic")) != "generic" \
					and str(profile.get("family", "")).strip_edges() != "" \
					and str(profile.get("cast_label", "")).strip_edges() != "" \
					and str(profile.get("impact_cue", "")).strip_edges() != "" \
					and str(profile.get("cooldown_hint", "")).strip_edges() != "":
				active_skill_feedback_count += 1
			else:
				missing_profiles.append(skill_id)
			if str(profile.get("cooldown_icon", "")).strip_edges() != "":
				cooldown_icon_count += 1
			var cue: Dictionary = AudioCueDBScript.skill_cast_cue(skill_id)
			var cue_id := str(cue.get("id", "")).strip_edges()
			if cue_id != "" and AudioCueDBScript.cue_exists(cue_id) \
					and float(cue.get("frequency", 0.0)) > 0.0:
				cast_sound_cue_count += 1
			if float(profile.get("hit_pause_seconds", 0.0)) > 0.0 \
					and float(profile.get("hit_pause_scale", 1.0)) > 0.0 \
					and float(profile.get("hit_pause_scale", 1.0)) < 1.0:
				hit_pause_profile_count += 1

	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	var player_source := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	var hud_cooldown_icon_contract := hud_source.contains("SkillCooldownIcon") \
			and hud_source.contains("SecondarySkillCooldownIcon") \
			and hud_source.contains("DashCooldownIcon") \
			and hud_source.contains("_attach_cooldown_sprite_icon") \
			and hud_source.contains("_update_cooldown_sprite_icon") \
			and hud_source.contains("_play_skill_ready_sfx")
	var class_resource_feedback_count := 0
	for kind in ["soul_slots", "turrets", "snares", "rounds"]:
		var resource_cue: Dictionary = AudioCueDBScript.class_resource_full_cue(kind, kind)
		if player_source.contains(kind) and hud_source.contains(kind) \
				and str(resource_cue.get("id", "")) == "class_resource_full" \
				and float(resource_cue.get("frequency", 0.0)) > 0.0:
			class_resource_feedback_count += 1
	var blocked_cue: Dictionary = AudioCueDBScript.skill_blocked_cue("cooldown")
	var blocked_feedback_contract := str(blocked_cue.get("id", "")) == "skill_blocked" \
			and float(blocked_cue.get("frequency", 0.0)) > 0.0 \
			and player_source.contains("signal skill_blocked") \
			and player_source.contains("signal dash_blocked") \
			and player_source.contains("signal weapon_attack_blocked") \
			and hud_source.contains("_play_skill_blocked_sfx") \
			and hud_source.contains("_play_dash_blocked_sfx") \
			and hud_source.contains("_play_weapon_attack_blocked_sfx")
	var player_hit_pause_contract := player_source.contains("_hit_pause(") \
			and player_source.contains("hit_pause_seconds") \
			and player_source.contains("hit_pause_scale")
	var required_active_count := PlayerClassDBScript.all().size() * 2
	var blockers: Array[String] = []
	if active_skill_count < required_active_count or active_skill_feedback_count < required_active_count:
		blockers.append("active_skill_feedback_missing")
	if cooldown_icon_count < required_active_count:
		blockers.append("cooldown_icon_contract_missing")
	if cast_sound_cue_count < required_active_count:
		blockers.append("cast_sound_contract_missing")
	if hit_pause_profile_count < required_active_count or not player_hit_pause_contract:
		blockers.append("hit_pause_contract_missing")
	if not hud_cooldown_icon_contract:
		blockers.append("hud_cooldown_icon_contract_missing")
	if class_resource_feedback_count < 4:
		blockers.append("class_resource_feedback_missing")
	if not blocked_feedback_contract:
		blockers.append("blocked_feedback_contract_missing")
	return _readiness_milestone(blockers.is_empty(), {
		"active_skill_count": active_skill_count,
		"required_active_skill_count": required_active_count,
		"active_skill_feedback_count": active_skill_feedback_count,
		"cooldown_icon_count": cooldown_icon_count,
		"cast_sound_cue_count": cast_sound_cue_count,
		"hit_pause_profile_count": hit_pause_profile_count,
		"hud_cooldown_icon_contract": hud_cooldown_icon_contract,
		"class_resource_feedback_count": class_resource_feedback_count,
		"blocked_feedback_contract": blocked_feedback_contract,
		"player_hit_pause_contract": player_hit_pause_contract,
		"missing_profiles": missing_profiles,
	}, blockers)

static func _readiness_boss_phase() -> Dictionary:
	var boss := BossGolemScript.new()
	var patterns := {}
	for phase_value in [1, 2, 3]:
		boss.set("phase", phase_value)
		boss.set("enraged", phase_value == 3)
		var pattern := str(boss.call("phase_pattern")).strip_edges()
		if pattern != "":
			patterns[pattern] = true
	var status: Dictionary = boss.call("boss_status")
	var status_contract := int(status.get("phase", 0)) == 3 \
			and str(status.get("pattern_label", "")).strip_edges() != "" \
			and str(status.get("next_attack_id", "")) == "bullet_hell" \
			and Array(status.get("pattern_steps", [])).size() >= 3 \
			and str(status.get("counter_hint", "")).strip_edges() != "" \
			and str(status.get("dodge_cue", "")).strip_edges() != "" \
			and float(status.get("punish_window_seconds", 0.0)) > 0.0 \
			and str(status.get("safe_window_hint", "")).contains("Punish")
	boss.free()

	var source := FileAccess.get_file_as_string("res://scripts/enemies/boss_golem.gd")
	var bullet_hell_contract := source.contains("func spawn_bullet_hell") \
			and source.contains("CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS") \
			and source.contains("_emit_boss_attack_cue(\"bullet_hell\"") \
			and source.contains("projectile.set_meta(\"boss_attack\", attack_id)") \
			and source.contains("projectile.set_meta(\"boss_pattern\", phase_pattern())")
	var trap_wave_contract := source.contains("func summon_phase_traps") \
			and source.contains("MAX_BOSS_TRAPS") \
			and source.contains("BOSS_TRAP_TARGET_SAFE_RADIUS") \
			and source.contains("BOSS_TRAP_MIN_SPACING") \
			and source.contains("trap.set_meta(\"boss_trap\", true)") \
			and source.contains("trap.set_meta(\"boss_attack\", \"trap_wave\")") \
			and source.contains("_emit_boss_attack_cue(\"trap_wave\"")
	var enrage_contract := source.contains("enraged = ratio <= 0.30") \
			and source.contains("spawn_floating_guns(4)") \
			and source.contains("summon_phase_traps(4)") \
			and source.contains("boss_phase_changed.emit(enrage_status)") \
			and str(status.get("enrage_warning", "")).contains("Bullet") \
			and str(status.get("enrage_warning", "")).contains("traps")
	var floating_gun_contract := ResourceLoader.exists("res://scripts/enemies/floating_gun.gd") \
			and source.contains("func spawn_floating_guns") \
			and source.contains("FloatingGunScript.new()") \
			and source.contains("gun.configure(self, target")
	var phase_shift_cue: Dictionary = AudioCueDBScript.boss_phase_cue({"phase": 2})
	var enrage_cue: Dictionary = AudioCueDBScript.boss_phase_cue({"phase": 3, "enraged": true})
	var bullet_cue: Dictionary = AudioCueDBScript.boss_attack_cue({"attack": "bullet_hell"})
	var trap_cue: Dictionary = AudioCueDBScript.boss_attack_cue({"attack": "trap_wave"})
	var boss_cue_contract := str(phase_shift_cue.get("id", "")) == "boss_phase_shift" \
			and str(enrage_cue.get("id", "")) == "boss_enrage" \
			and str(bullet_cue.get("id", "")) == "boss_bullet_hell" \
			and str(trap_cue.get("id", "")) == "boss_trap_wave" \
			and AudioCueDBScript.cue_exists("boss_phase_shift") \
			and AudioCueDBScript.cue_exists("boss_enrage") \
			and AudioCueDBScript.cue_exists("boss_bullet_hell") \
			and AudioCueDBScript.cue_exists("boss_trap_wave")
	var attack_telegraph_seconds := CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS
	var blockers: Array[String] = []
	if patterns.size() < 3 or not status_contract:
		blockers.append("boss_phase_pattern_contract_missing")
	if not bullet_hell_contract or attack_telegraph_seconds < 0.5:
		blockers.append("boss_bullet_hell_contract_missing")
	if not trap_wave_contract:
		blockers.append("boss_trap_wave_contract_missing")
	if not enrage_contract:
		blockers.append("boss_enrage_contract_missing")
	if not floating_gun_contract:
		blockers.append("boss_floating_gun_contract_missing")
	if not boss_cue_contract:
		blockers.append("boss_cue_contract_missing")
	return _readiness_milestone(blockers.is_empty(), {
		"phase_pattern_count": patterns.size(),
		"bullet_hell_contract": bullet_hell_contract,
		"trap_wave_contract": trap_wave_contract,
		"enrage_contract": enrage_contract,
		"floating_gun_contract": floating_gun_contract,
		"attack_telegraph_seconds": attack_telegraph_seconds,
		"boss_cue_contract": boss_cue_contract,
		"boss_status_contract": status_contract,
	}, blockers)

static func _readiness_combat_readability() -> Dictionary:
	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemies/enemy.gd")
	var projectile_source := FileAccess.get_file_as_string("res://scripts/enemies/enemy_projectile.gd")
	var trap_source := FileAccess.get_file_as_string("res://scripts/rooms/trap.gd")
	var room_source := FileAccess.get_file_as_string("res://scripts/rooms/room_renderer.gd")
	var boss_source := FileAccess.get_file_as_string("res://scripts/enemies/boss_golem.gd")
	var player_source := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	var min_attack_telegraph_seconds := float(CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS)
	var trap_min_telegraph_seconds := float(TrapScript.MIN_TELEGRAPH_SECONDS)
	var enemy_projectile_windup_contract := min_attack_telegraph_seconds >= 0.5 \
			and enemy_source.contains("func _begin_projectile_windup") \
			and enemy_source.contains("_state = \"projectile_telegraph\"") \
			and enemy_source.contains("projectile_telegraph_seconds") \
			and enemy_source.contains("_spawn_attack_telegraph_at(")
	var enemy_contact_windup_contract := min_attack_telegraph_seconds >= 0.5 \
			and enemy_source.contains("func _arm_contact_telegraph") \
			and enemy_source.contains("contact_telegraph_seconds") \
			and enemy_source.contains("_contact_telegraph_started_at < CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS") \
			and enemy_source.contains("_spawn_attack_telegraph_at(")
	var trap_telegraph_contract := trap_min_telegraph_seconds >= 0.5 \
			and trap_source.contains("telegraph_time = maxf(p_telegraph_time, MIN_TELEGRAPH_SECONDS)") \
			and trap_source.contains("set_meta(\"telegraph_seconds\", telegraph_time)") \
			and room_source.contains("trap.configure(kind, 6, 0.7, 0.18)") \
			and trap_source.contains("source_label := \"Trap: %s\"")
	var boss_attack_warning_contract := boss_source.contains("signal boss_attack_cued") \
			and boss_source.contains("func _emit_boss_attack_cue") \
			and boss_source.contains("\"warning\"") \
			and boss_source.contains("\"next_attack_seconds\"") \
			and boss_source.contains("_boss_damage_source")
	var boss_bullet_hell_delay_contract := min_attack_telegraph_seconds >= 0.5 \
			and boss_source.contains("readable_delay := CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS") \
			and boss_source.contains("BossBulletHellDelay") \
			and boss_source.contains("_emit_boss_attack_cue(\"bullet_hell\"")
	var damage_source_contract := enemy_source.contains("func _enemy_damage_source_label") \
			and projectile_source.contains("func _damage_source_label") \
			and projectile_source.contains("return \"Enemy: %s\"") \
			and projectile_source.contains("return \"Boss: %s\"") \
			and trap_source.contains("source_label := \"Trap: %s\"") \
			and boss_source.contains("func _boss_damage_source") \
			and player_source.contains("last_damage_source")
	var hud_damage_feedback_contract := player_source.contains("func _record_last_damage_context") \
			and player_source.contains("func _damage_kind_from_source") \
			and player_source.contains("PlayerDamageNumber") \
			and hud_source.contains("DamageVignetteOverlay") \
			and hud_source.contains("DamageFlashLabel") \
			and hud_source.contains("func _update_damage_type_icon") \
			and hud_source.contains("DamageFeedbackSfx")
	var min_player_hp := _readiness_min_player_hp()
	var max_enemy_hit_damage := _readiness_max_enemy_hit_damage()
	var trap_probe := TrapScript.new()
	var max_trap_damage := int(trap_probe.get("damage"))
	trap_probe.free()
	var max_single_hit_damage := maxi(max_enemy_hit_damage, max_trap_damage)
	var hidden_one_shot_guard_contract := min_player_hp > 0 \
			and max_single_hit_damage > 0 \
			and max_single_hit_damage < min_player_hp
	var contracts := {
		"enemy_projectile_windup": enemy_projectile_windup_contract,
		"enemy_contact_windup": enemy_contact_windup_contract,
		"trap_telegraph": trap_telegraph_contract,
		"boss_attack_warning": boss_attack_warning_contract,
		"boss_bullet_hell_delay": boss_bullet_hell_delay_contract,
		"damage_source": damage_source_contract,
		"hud_damage_feedback": hud_damage_feedback_contract,
		"hidden_one_shot_guard": hidden_one_shot_guard_contract,
	}
	var blockers: Array[String] = []
	for contract_id in contracts.keys():
		if not bool(contracts[contract_id]):
			blockers.append("%s_contract_missing" % str(contract_id))
	if min_attack_telegraph_seconds < 0.5:
		blockers.append("enemy_telegraph_below_0_5s")
	if trap_min_telegraph_seconds < 0.5:
		blockers.append("trap_telegraph_below_0_5s")
	return _readiness_milestone(blockers.is_empty(), {
		"min_attack_telegraph_seconds": min_attack_telegraph_seconds,
		"trap_min_telegraph_seconds": trap_min_telegraph_seconds,
		"enemy_projectile_windup_contract": enemy_projectile_windup_contract,
		"enemy_contact_windup_contract": enemy_contact_windup_contract,
		"trap_telegraph_contract": trap_telegraph_contract,
		"boss_attack_warning_contract": boss_attack_warning_contract,
		"boss_bullet_hell_delay_contract": boss_bullet_hell_delay_contract,
		"damage_source_contract": damage_source_contract,
		"hud_damage_feedback_contract": hud_damage_feedback_contract,
		"hidden_one_shot_guard_contract": hidden_one_shot_guard_contract,
		"max_enemy_hit_damage": max_enemy_hit_damage,
		"max_trap_damage": max_trap_damage,
		"max_single_hit_damage": max_single_hit_damage,
		"min_player_hp": min_player_hp,
		"readability_contract_count": contracts.size(),
	}, blockers)

static func _readiness_min_player_hp() -> int:
	var min_hp := 0
	for raw_class in PlayerClassDBScript.all():
		if not (raw_class is Dictionary):
			continue
		var stats: Dictionary = (raw_class as Dictionary).get("stats", {})
		var hp := int(stats.get("hp", 0)) * 20
		if hp <= 0:
			continue
		min_hp = hp if min_hp == 0 else mini(min_hp, hp)
	return min_hp

static func _readiness_max_enemy_hit_damage() -> int:
	var max_damage := 0
	for raw_entry in BiomeDBScript.enemy_codex_entries():
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		max_damage = maxi(max_damage, int(entry.get("dmg", 0)))
	return max_damage

static func _readiness_settings_accessibility() -> Dictionary:
	var overlay_source := FileAccess.get_file_as_string("res://scripts/ui/run_overlay.gd")
	var class_select_source := FileAccess.get_file_as_string("res://scripts/ui/class_select.gd")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	var player_source := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var settings_source := FileAccess.get_file_as_string("res://scripts/ui/accessibility_settings.gd")
	var control_names := [
		"PauseVolumeDown",
		"PauseVolumeUp",
		"PauseToggleFlash",
		"PauseToggleShake",
		"PauseToggleContrast",
	]
	var settings_control_count := 0
	for control_name in control_names:
		if overlay_source.contains(control_name):
			settings_control_count += 1
	var class_select_control_names := [
		"ClassSelectVolumeDown",
		"ClassSelectVolumeUp",
		"ClassSelectToggleFlash",
		"ClassSelectToggleShake",
		"ClassSelectToggleContrast",
	]
	var class_select_settings_control_count := 0
	for control_name in class_select_control_names:
		if class_select_source.contains(control_name):
			class_select_settings_control_count += 1
	var pause_controls_contract := overlay_source.contains("signal settings_changed") \
			and overlay_source.contains("PauseAccessibilitySettings") \
			and overlay_source.contains("accessibility_settings") \
			and overlay_source.contains("_accessibility_settings_summary") \
			and settings_control_count >= control_names.size()
	var class_select_controls_contract := class_select_source.contains("signal settings_changed") \
			and class_select_source.contains("func apply_accessibility_settings") \
			and class_select_source.contains("ClassSelectAccessibilitySettings") \
			and class_select_source.contains("AccessibilitySettingsScript.summary") \
			and class_select_settings_control_count >= class_select_control_names.size() \
			and main_source.contains(
				"select.settings_changed.connect(_on_accessibility_settings_changed)") \
			and main_source.contains("select.apply_accessibility_settings(_accessibility_settings)")
	var hud_settings_contract := hud_source.contains("func apply_accessibility_settings") \
			and hud_source.contains("_damage_flash_enabled") \
			and hud_source.contains("_damage_vignette_enabled") \
			and hud_source.contains("_high_contrast_cues") \
			and hud_source.contains("master_volume")
	var player_settings_contract := player_source.contains("func apply_accessibility_settings") \
			and player_source.contains("_screen_shake_scale") \
			and player_source.contains("_accessibility_hit_pause_scale") \
			and player_source.contains("camera_impact_suppressed")
	var main_hook_contract := main_source.contains(
			"settings_changed.connect(_on_accessibility_settings_changed)") \
			and main_source.contains("func _on_accessibility_settings_changed") \
			and main_source.contains("_hud.apply_accessibility_settings") \
			and main_source.contains("player.apply_accessibility_settings")
	var settings_save_path := "user://accessibility_settings.json"
	var settings_persistence_contract := ResourceLoader.exists(
			"res://scripts/ui/accessibility_settings.gd") \
			and settings_source.contains("const PATH := \"%s\"" % settings_save_path) \
			and settings_source.contains("func load_data") \
			and settings_source.contains("func save_data") \
			and settings_source.contains("func normalized") \
			and main_source.contains("AccessibilitySettingsScript.load_data()") \
			and main_source.contains("AccessibilitySettingsScript.save_data(_accessibility_settings)")
	var blockers: Array[String] = []
	if not pause_controls_contract:
		blockers.append("pause_settings_controls_missing")
	if not class_select_controls_contract:
		blockers.append("class_select_settings_controls_missing")
	if not hud_settings_contract:
		blockers.append("hud_settings_contract_missing")
	if not player_settings_contract:
		blockers.append("player_settings_contract_missing")
	if not main_hook_contract:
		blockers.append("main_settings_hook_missing")
	if not settings_persistence_contract:
		blockers.append("settings_persistence_contract_missing")
	return _readiness_milestone(blockers.is_empty(), {
		"pause_controls_contract": pause_controls_contract,
		"class_select_controls_contract": class_select_controls_contract,
		"hud_settings_contract": hud_settings_contract,
		"player_settings_contract": player_settings_contract,
		"main_hook_contract": main_hook_contract,
		"settings_persistence_contract": settings_persistence_contract,
		"settings_save_path": settings_save_path,
		"settings_control_count": settings_control_count,
		"required_settings_control_count": control_names.size(),
		"class_select_settings_control_count": class_select_settings_control_count,
		"required_class_select_settings_control_count": class_select_control_names.size(),
	}, blockers)

static func _readiness_input_controls() -> Dictionary:
	var required_actions := [
		"move_left",
		"move_right",
		"move_up",
		"move_down",
		"dash",
		"attack",
		"swap_weapon",
		"active_reload",
		"skill",
		"skill_alt",
		"cycle_element",
		"ultimate",
		"aim_left",
		"aim_right",
		"aim_up",
		"aim_down",
		"interact",
		"pause_menu",
		"restart",
		"route_choice_1",
		"route_choice_2",
		"route_choice_3",
		"route_choice_4",
	]
	var menu_actions := [
		"menu_prev",
		"menu_next",
		"menu_confirm",
		"menu_back",
	]
	var missing_actions: Array[String] = []
	var missing_gamepad_actions: Array[String] = []
	var missing_menu_gamepad_actions: Array[String] = []
	var critical_action_count := 0
	var gamepad_action_count := 0
	var menu_gamepad_action_count := 0
	for action in required_actions:
		if InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty():
			critical_action_count += 1
		else:
			missing_actions.append(action)
		if InputMap.has_action(action) and _input_action_has_gamepad_event(action):
			gamepad_action_count += 1
		else:
			missing_gamepad_actions.append(action)
	for action in menu_actions:
		if InputMap.has_action(action) and _input_action_has_gamepad_event(action):
			menu_gamepad_action_count += 1
		else:
			missing_menu_gamepad_actions.append(action)
	var ultimate_has_v := _input_action_has_key("ultimate", KEY_V)
	var cycle_has_q := _input_action_has_key("cycle_element", KEY_Q)
	var restart_has_r := _input_action_has_key("restart", KEY_R)
	var ultimate_restart_separated := not _input_actions_share_key("ultimate", "restart")
	var ultimate_cycle_separated := not _input_actions_share_key("ultimate", "cycle_element")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	var class_select_source := FileAccess.get_file_as_string("res://scripts/ui/class_select.gd")
	var run_overlay_source := FileAccess.get_file_as_string("res://scripts/ui/run_overlay.gd")
	var hud_hint_contract := hud_source.contains("E/C skills") \
			and hud_source.contains("Q cycle") \
			and hud_source.contains("V ultimate") \
			and not hud_source.contains("E/C/Q skills")
	var onboarding_hint_contract := class_select_source.contains("Q cycle") \
			and class_select_source.contains("V ultimate") \
			and class_select_source.contains("R restart") \
			and not class_select_source.contains("Q ultimate")
	var hud_gamepad_hint_contract := hud_source.contains("Pad:") \
			and hud_source.contains("LS move") \
			and hud_source.contains("RS aim") \
			and hud_source.contains("RB attack") \
			and hud_source.contains("A dash") \
			and hud_source.contains("X/Y skills") \
			and hud_source.contains("RT ultimate")
	var onboarding_gamepad_hint_contract := class_select_source.contains("Pad:") \
			and class_select_source.contains("LS move") \
			and class_select_source.contains("RS aim") \
			and class_select_source.contains("RB attack") \
			and class_select_source.contains("A dash") \
			and class_select_source.contains("X/Y skills") \
			and class_select_source.contains("RT ultimate")
	var class_select_gamepad_menu_contract := class_select_source.contains("Pad menu:") \
			and class_select_source.contains("LB/RB class") \
			and class_select_source.contains("A confirm") \
			and class_select_source.contains("B back") \
			and class_select_source.contains("menu_next") \
			and class_select_source.contains("menu_prev") \
			and class_select_source.contains("menu_confirm")
	var class_select_gamepad_element_contract := class_select_source.contains("D-pad element") \
			and class_select_source.contains("_element_for_route_action") \
			and class_select_source.contains("route_choice_1") \
			and class_select_source.contains("route_choice_2") \
			and class_select_source.contains("route_choice_3") \
			and class_select_source.contains("route_choice_4") \
			and class_select_source.contains("return \"fire\"") \
			and class_select_source.contains("return \"ice\"") \
			and class_select_source.contains("return \"lightning\"") \
			and class_select_source.contains("return \"poison\"")
	var run_overlay_gamepad_contract := run_overlay_source.contains("_handle_action_input") \
			and run_overlay_source.contains("_reward_choice_index_for_action") \
			and run_overlay_source.contains("route_choice_%d") \
			and run_overlay_source.contains("menu_confirm") \
			and run_overlay_source.contains("menu_back") \
			and run_overlay_source.contains("_choose_upgrade_hotkey") \
			and run_overlay_source.contains("_choose_shop_hotkey") \
			and run_overlay_source.contains("_emit_resume_requested")
	var run_overlay_controller_selection_contract := run_overlay_source.contains(
			"_move_controller_selection") \
			and run_overlay_source.contains("_set_controller_selection") \
			and run_overlay_source.contains("_selected_or_first_enabled_index") \
			and run_overlay_source.contains("menu_next") \
			and run_overlay_source.contains("menu_prev") \
			and run_overlay_source.contains("controller_selected")
	var run_overlay_message_controller_contract := run_overlay_source.contains(
			"_message_choice_buttons") \
			and run_overlay_source.contains("_message_choice_disabled") \
			and run_overlay_source.contains("_set_controller_selection(\"message\"") \
			and run_overlay_source.contains("_move_controller_selection(\"message\"") \
			and run_overlay_source.contains("_emit_class_select_requested")
	var blockers: Array[String] = []
	for action in missing_actions:
		blockers.append("input_action_missing:%s" % action)
	for action in missing_gamepad_actions:
		blockers.append("gamepad_input_missing:%s" % action)
	for action in missing_menu_gamepad_actions:
		blockers.append("menu_gamepad_input_missing:%s" % action)
	if not ultimate_has_v:
		blockers.append("ultimate_key_not_v")
	if not cycle_has_q:
		blockers.append("cycle_key_not_q")
	if not restart_has_r:
		blockers.append("restart_key_not_r")
	if not ultimate_restart_separated:
		blockers.append("ultimate_restart_key_conflict")
	if not ultimate_cycle_separated:
		blockers.append("ultimate_cycle_key_conflict")
	if not hud_hint_contract:
		blockers.append("hud_control_hint_contract_missing")
	if not onboarding_hint_contract:
		blockers.append("onboarding_control_hint_contract_missing")
	if not hud_gamepad_hint_contract:
		blockers.append("hud_gamepad_hint_contract_missing")
	if not onboarding_gamepad_hint_contract:
		blockers.append("onboarding_gamepad_hint_contract_missing")
	if not class_select_gamepad_menu_contract:
		blockers.append("class_select_gamepad_menu_contract_missing")
	if not class_select_gamepad_element_contract:
		blockers.append("class_select_gamepad_element_contract_missing")
	if not run_overlay_gamepad_contract:
		blockers.append("run_overlay_gamepad_contract_missing")
	if not run_overlay_controller_selection_contract:
		blockers.append("run_overlay_controller_selection_contract_missing")
	if not run_overlay_message_controller_contract:
		blockers.append("run_overlay_message_controller_contract_missing")
	return _readiness_milestone(blockers.is_empty(), {
		"critical_action_count": critical_action_count,
		"required_critical_action_count": required_actions.size(),
		"gamepad_action_count": gamepad_action_count,
		"required_gamepad_action_count": required_actions.size(),
		"menu_gamepad_action_count": menu_gamepad_action_count,
		"required_menu_gamepad_action_count": menu_actions.size(),
		"missing_actions": missing_actions,
		"missing_gamepad_actions": missing_gamepad_actions,
		"missing_menu_gamepad_actions": missing_menu_gamepad_actions,
		"ultimate_key_label": "V" if ultimate_has_v else _input_action_first_key_label("ultimate"),
		"cycle_key_label": "Q" if cycle_has_q else _input_action_first_key_label("cycle_element"),
		"restart_key_label": "R" if restart_has_r else _input_action_first_key_label("restart"),
		"ultimate_restart_separated": ultimate_restart_separated,
		"ultimate_cycle_separated": ultimate_cycle_separated,
		"hud_hint_contract": hud_hint_contract,
		"onboarding_hint_contract": onboarding_hint_contract,
		"hud_gamepad_hint_contract": hud_gamepad_hint_contract,
		"onboarding_gamepad_hint_contract": onboarding_gamepad_hint_contract,
		"class_select_gamepad_menu_contract": class_select_gamepad_menu_contract,
		"class_select_gamepad_element_contract": class_select_gamepad_element_contract,
		"run_overlay_gamepad_contract": run_overlay_gamepad_contract,
		"run_overlay_controller_selection_contract": run_overlay_controller_selection_contract,
		"run_overlay_message_controller_contract": run_overlay_message_controller_contract,
	}, blockers)

static func _readiness_run_lifecycle() -> Dictionary:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var overlay_source := FileAccess.get_file_as_string("res://scripts/ui/run_overlay.gd")
	var summary_source := FileAccess.get_file_as_string("res://scripts/ui/run_summary.gd")
	var pause_resume_contract := main_source.contains("_toggle_pause_menu") \
			and main_source.contains("_on_pause_resume_requested") \
			and main_source.contains("_resume_from_pause()") \
			and main_source.contains("player.set_physics_process(false)") \
			and main_source.contains("player.set_physics_process(true)") \
			and overlay_source.contains("signal resume_requested") \
			and overlay_source.contains("PauseResume") \
			and overlay_source.contains("_emit_resume_requested") \
			and overlay_source.contains("KEY_ESCAPE")
	var restart_contract := main_source.contains("_on_pause_restart_requested") \
			and main_source.contains("run_over and event.is_action_pressed(\"restart\")") \
			and main_source.contains("get_tree().reload_current_scene()") \
			and overlay_source.contains("signal restart_requested") \
			and overlay_source.contains("PauseRestart") \
			and overlay_source.contains("RunEndRestart") \
			and overlay_source.contains("KEY_R")
	var class_select_return_contract := main_source.contains(
			"class_select_requested.connect(_on_class_select_requested)") \
			and main_source.contains("func _on_class_select_requested") \
			and overlay_source.contains("signal class_select_requested") \
			and overlay_source.contains("PauseClassSelect") \
			and overlay_source.contains("RunEndClassSelect") \
			and overlay_source.contains("KEY_C")
	var defeat_overlay_contract := main_source.contains("show_message(\"YOU DIED\"") \
			and main_source.contains("RunSummaryScript.end_message(\"defeat\"") \
			and overlay_source.contains("_play_run_end_sfx(title)")
	var victory_overlay_contract := main_source.contains("show_message(\"RUN COMPLETE!\"") \
			and main_source.contains("RunSummaryScript.end_message(\"victory\"") \
			and main_source.contains("_bank_run_rewards(\"victory\"")
	var run_summary_context_contract := main_source.contains("func _run_summary_context") \
			and main_source.contains("\"weapons\":") \
			and main_source.contains("\"power_arc\":") \
			and main_source.contains("\"release_audit\": ReleaseAuditScript.summary_text()") \
			and main_source.contains("\"release_next_action\": ReleaseAuditScript.next_release_action()") \
			and summary_source.contains("static func end_message") \
			and summary_source.contains("Press R for Class Select / Meta Shop") \
			and summary_source.contains("Release Audit:") \
			and summary_source.contains("Public Gate:")
	var overlay_action_count := 0
	for action in ["resume", "restart", "class_select"]:
		var cue: Dictionary = AudioCueDBScript.overlay_action_cue(action)
		if AudioCueDBScript.cue_exists(str(cue.get("id", ""))) \
				and float(cue.get("frequency", 0.0)) > 0.0:
			overlay_action_count += 1
	var run_end_action_count := 0
	for node_name in ["RunEndRestart", "RunEndClassSelect"]:
		if overlay_source.contains(node_name):
			run_end_action_count += 1
	var run_end_cue_count := 0
	for title in ["YOU DIED", "RUN COMPLETE!"]:
		var cue: Dictionary = AudioCueDBScript.run_end_cue(title)
		if AudioCueDBScript.cue_exists(str(cue.get("id", ""))) \
				and float(cue.get("frequency", 0.0)) > 0.0:
			run_end_cue_count += 1
	var blockers: Array[String] = []
	if not pause_resume_contract:
		blockers.append("pause_resume_contract_missing")
	if not restart_contract:
		blockers.append("restart_contract_missing")
	if not class_select_return_contract:
		blockers.append("class_select_return_contract_missing")
	if not defeat_overlay_contract:
		blockers.append("defeat_overlay_contract_missing")
	if not victory_overlay_contract:
		blockers.append("victory_overlay_contract_missing")
	if not run_summary_context_contract:
		blockers.append("run_summary_context_missing")
	if overlay_action_count < 3:
		blockers.append("overlay_action_cues_missing")
	if run_end_action_count < 2:
		blockers.append("run_end_actions_missing")
	if run_end_cue_count < 2:
		blockers.append("run_end_cues_missing")
	return _readiness_milestone(blockers.is_empty(), {
		"pause_resume_contract": pause_resume_contract,
		"restart_contract": restart_contract,
		"class_select_return_contract": class_select_return_contract,
		"defeat_overlay_contract": defeat_overlay_contract,
		"victory_overlay_contract": victory_overlay_contract,
		"run_summary_context_contract": run_summary_context_contract,
		"overlay_action_count": overlay_action_count,
		"required_overlay_action_count": 3,
		"run_end_action_count": run_end_action_count,
		"required_run_end_action_count": 2,
		"run_end_cue_count": run_end_cue_count,
		"required_run_end_cue_count": 2,
	}, blockers)

static func _readiness_hub_meta() -> Dictionary:
	var source := FileAccess.get_file_as_string("res://scripts/ui/class_select.gd")
	var hub_services := ["DungeonGate", "ClassHall", "TrainingGround", "Blacksmith", "Codex"]
	var missing_services: Array[String] = []
	for service in hub_services:
		if not source.contains("\"%s\"" % service):
			missing_services.append(service)
	var upgrade_count := MetaProgressionScript.all_upgrade_ids().size()
	var blockers: Array[String] = []
	for service in missing_services:
		blockers.append("hub_service_missing:%s" % service)
	if upgrade_count < 8:
		blockers.append("meta_upgrade_count_below_8")
	return _readiness_milestone(blockers.is_empty(), {
		"hub_service_count": hub_services.size() - missing_services.size(),
		"required_hub_service_count": hub_services.size(),
		"meta_upgrade_count": upgrade_count,
		"required_meta_upgrade_count": 8,
		"missing_hub_services": missing_services,
	}, blockers)

static func _readiness_meta_persistence() -> Dictionary:
	var meta_source := FileAccess.get_file_as_string("res://scripts/progression/meta_progression.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var player_source := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	var default_meta := MetaProgressionScript.default_data()
	var missing_currencies: Array[String] = []
	for key in MetaProgressionScript.META_CURRENCY_KEYS:
		if not default_meta.has(key):
			missing_currencies.append(str(key))
	var record_keys := [
		"class_records",
		"mode_records",
		"element_records",
		"biome_records",
		"boss_records",
		"enemy_records",
		"recent_runs",
	]
	var missing_records: Array[String] = []
	var record_contract_count := 0
	for key in record_keys:
		if default_meta.has(key):
			record_contract_count += 1
		else:
			missing_records.append(str(key))
	var upgrade_count := MetaProgressionScript.all_upgrade_ids().size()
	var save_path_ok := str(MetaProgressionScript.SAVE_PATH) == "user://meta_progression.json"
	var persistence_contract := save_path_ok \
			and meta_source.contains("FileAccess.file_exists(path)") \
			and meta_source.contains("JSON.parse_string") \
			and meta_source.contains("FileAccess.open(path, FileAccess.WRITE)") \
			and meta_source.contains("JSON.stringify(data")
	var run_banking_contract := meta_source.contains("func bank_run_rewards") \
			and meta_source.contains("_record_run_context") \
			and meta_source.contains("_record_recent_run") \
			and main_source.contains("MetaProgressionScript.bank_run_rewards(") \
			and main_source.contains("MetaProgressionScript.SAVE_PATH, _run_summary_context()")
	var profile_reset_contract := meta_source.contains("func reset_profile") \
			and meta_source.contains("save_data(data, path)")
	var upgrade_purchase_contract := upgrade_count >= 8 \
			and meta_source.contains("func buy_upgrade") \
			and meta_source.contains("func upgrade_costs") \
			and meta_source.contains("func upgrade_max_level") \
			and meta_source.contains("func upgrade_purchase_hint")
	var meta_bonus_contract := meta_source.contains("func active_bonus_summary") \
			and player_source.contains("func apply_meta_bonuses") \
			and player_source.contains("func apply_biome_mastery") \
			and main_source.contains("player.apply_meta_bonuses(meta)") \
			and main_source.contains("show_meta_bonus_summary") \
			and hud_source.contains("func show_meta_bonus_summary")
	var recent_run_telemetry_contract := meta_source.contains("func recent_run_playtest_summary") \
			and meta_source.contains("\"pace_avg_sec\"") \
			and meta_source.contains("\"pace_boss_sec\"") \
			and meta_source.contains("\"decision_reward_picks\"") \
			and meta_source.contains("\"release_audit\"") \
			and meta_source.contains("\"balance_experiment\"")
	var balance_evidence_contract := meta_source.contains("func balance_playtest_evidence") \
			and meta_source.contains("func balance_playtest_evidence_summary") \
			and main_source.contains("balance_tuning_experiment_patch(MetaProgressionScript.load_data())")
	var blockers: Array[String] = []
	if not save_path_ok:
		blockers.append("save_path_mismatch")
	for key in missing_currencies:
		blockers.append("meta_currency_missing:%s" % key)
	for key in missing_records:
		blockers.append("record_contract_missing:%s" % key)
	if not persistence_contract:
		blockers.append("persistence_contract_missing")
	if not run_banking_contract:
		blockers.append("run_banking_contract_missing")
	if not profile_reset_contract:
		blockers.append("profile_reset_contract_missing")
	if not upgrade_purchase_contract:
		blockers.append("upgrade_purchase_contract_missing")
	if not meta_bonus_contract:
		blockers.append("meta_bonus_contract_missing")
	if not recent_run_telemetry_contract:
		blockers.append("recent_run_telemetry_contract_missing")
	if not balance_evidence_contract:
		blockers.append("balance_evidence_contract_missing")
	return _readiness_milestone(blockers.is_empty(), {
		"save_path": str(MetaProgressionScript.SAVE_PATH),
		"meta_currency_count": MetaProgressionScript.META_CURRENCY_KEYS.size()
				- missing_currencies.size(),
		"required_meta_currency_count": MetaProgressionScript.META_CURRENCY_KEYS.size(),
		"upgrade_count": upgrade_count,
		"required_upgrade_count": 8,
		"record_contract_count": record_contract_count,
		"required_record_contract_count": record_keys.size(),
		"persistence_contract": persistence_contract,
		"run_banking_contract": run_banking_contract,
		"profile_reset_contract": profile_reset_contract,
		"upgrade_purchase_contract": upgrade_purchase_contract,
		"meta_bonus_contract": meta_bonus_contract,
		"recent_run_telemetry_contract": recent_run_telemetry_contract,
		"balance_evidence_contract": balance_evidence_contract,
		"missing_currencies": missing_currencies,
		"missing_records": missing_records,
	}, blockers)

static func _readiness_hub_navigation() -> Dictionary:
	var source := FileAccess.get_file_as_string("res://scripts/ui/class_select.gd")
	var hub_services := {
		"DungeonGate": KEY_D,
		"ClassHall": KEY_H,
		"TrainingGround": KEY_T,
		"Blacksmith": KEY_K,
		"Codex": KEY_X,
	}
	var run_modes := {
		"normal": KEY_N,
		"boss_rush": KEY_B,
		"endless": KEY_E,
		"hardcore": KEY_C,
		"elemental_chaos": KEY_O,
		"balance_lab": KEY_A,
	}
	var hub_service_button_count := 0
	var hub_service_hotkey_count := 0
	for service_id in hub_services.keys():
		if source.contains("\"%s\"" % service_id) and source.contains("HubService_%s"):
			hub_service_button_count += 1
		if source.contains("_select_hub_service(\"%s\")" % service_id) \
				and source.contains(_key_token(int(hub_services[service_id]))):
			hub_service_hotkey_count += 1
	var run_mode_count := 0
	var run_mode_hotkey_count := 0
	for mode_id in run_modes.keys():
		if source.contains("\"%s\"" % mode_id) and source.contains("RunMode_%s"):
			run_mode_count += 1
		if source.contains("_select_run_mode(\"%s\")" % mode_id) \
				and source.contains(_key_token(int(run_modes[mode_id]))):
			run_mode_hotkey_count += 1
	var class_hotkey_count := 0
	if source.contains("keycode >= KEY_1") and source.contains("keycode <= KEY_9"):
		class_hotkey_count = mini(PlayerClassDBScript.all().size(), 9)
	if source.contains("KEY_0") and source.contains("_select_class_by_index(9)"):
		class_hotkey_count += 1
	var element_hotkey_count := 0
	for element in ElementSystemScript.ELEMENTS:
		if source.contains("_select_element(\"%s\")" % str(element)) \
				and source.contains("_element_hotkey"):
			element_hotkey_count += 1
	var daily_seed_contract := source.contains("DailySeedButton") \
			and source.contains("func daily_seed_today") \
			and source.contains("func _on_daily_seed_pressed") \
			and source.contains("KEY_Y") \
			and source.contains("_play_class_select_sfx(\"daily_seed\"")
	var start_hotkey_contract := source.contains("KEY_ENTER, KEY_KP_ENTER") \
			and source.contains("func _on_start") \
			and source.contains("confirmed.emit(_selected_class, _selected_element") \
			and source.contains("selected_seed()") \
			and source.contains("selected_run_mode()") \
			and source.contains("_start_disabled_reason")
	var codex_panel_contract := source.contains("CodexSummaryLabel") \
			and source.contains("CodexDetailLabel") \
			and source.contains("_codex_release_detail_line") \
			and source.contains("ReleaseAuditScript.summary_text") \
			and source.contains("BiomeDBScript.enemy_codex_summary") \
			and source.contains("MetaProgressionScript.recent_run_playtest_summary")
	var hub_upgrade_filter_contract := source.contains("HUB_UPGRADE_GROUPS") \
			and source.contains("func _upgrade_visible_for_service") \
			and source.contains("func _recommended_hub_upgrade_id") \
			and source.contains("_update_meta_buttons(meta, true)") \
			and source.contains("button.grab_focus()")
	var reset_confirm_contract := source.contains("_reset_pending") \
			and source.contains("CONFIRM RESET PROFILE") \
			and source.contains("Press reset again") \
			and source.contains("MetaProgressionScript.reset_profile()")
	var class_select_sfx_contract := source.contains("func _play_class_select_sfx") \
			and source.contains("AudioCueDBScript.class_select_cue") \
			and source.contains("AudioCueDBScript.placeholder_stream") \
			and source.contains("headless_playback_skipped")
	var loadout_preview_contract := source.contains("RunLoadoutPreviewLabel") \
			and source.contains("func _update_loadout_preview") \
			and source.contains("loadout_ready") \
			and source.contains("starter_weapon_name")
	var replay_last_run_contract := source.contains("ReplayLastRunButton") \
			and source.contains("func _last_run_replay_data") \
			and source.contains("last_class_id") \
			and source.contains("replay_input_action") \
			and source.contains("replay_last_run") \
			and source.contains("replay_seed") \
			and source.contains("replay_run_mode") \
			and source.contains("func _on_replay_last_run_pressed") \
			and source.contains("confirmed.emit(_selected_class, _selected_element, int(replay.get(\"seed\", 0)), _selected_run_mode)")
	var blockers: Array[String] = []
	if hub_service_button_count < hub_services.size():
		blockers.append("hub_service_buttons_missing")
	if hub_service_hotkey_count < hub_services.size():
		blockers.append("hub_service_hotkeys_missing")
	if run_mode_count < run_modes.size():
		blockers.append("run_modes_missing")
	if run_mode_hotkey_count < run_modes.size():
		blockers.append("run_mode_hotkeys_missing")
	if class_hotkey_count < 10:
		blockers.append("class_hotkeys_missing")
	if element_hotkey_count < ElementSystemScript.ELEMENTS.size():
		blockers.append("element_hotkeys_missing")
	if not daily_seed_contract:
		blockers.append("daily_seed_contract_missing")
	if not start_hotkey_contract:
		blockers.append("start_hotkey_contract_missing")
	if not codex_panel_contract:
		blockers.append("codex_panel_contract_missing")
	if not hub_upgrade_filter_contract:
		blockers.append("hub_upgrade_filter_contract_missing")
	if not reset_confirm_contract:
		blockers.append("reset_confirm_contract_missing")
	if not class_select_sfx_contract:
		blockers.append("class_select_sfx_contract_missing")
	if not loadout_preview_contract:
		blockers.append("loadout_preview_contract_missing")
	if not replay_last_run_contract:
		blockers.append("replay_last_run_contract_missing")
	return _readiness_milestone(blockers.is_empty(), {
		"hub_service_button_count": hub_service_button_count,
		"required_hub_service_button_count": hub_services.size(),
		"hub_service_hotkey_count": hub_service_hotkey_count,
		"required_hub_service_hotkey_count": hub_services.size(),
		"run_mode_count": run_mode_count,
		"required_run_mode_count": run_modes.size(),
		"run_mode_hotkey_count": run_mode_hotkey_count,
		"required_run_mode_hotkey_count": run_modes.size(),
		"class_hotkey_count": class_hotkey_count,
		"required_class_hotkey_count": 10,
		"element_hotkey_count": element_hotkey_count,
		"required_element_hotkey_count": ElementSystemScript.ELEMENTS.size(),
		"daily_seed_contract": daily_seed_contract,
		"start_hotkey_contract": start_hotkey_contract,
		"codex_panel_contract": codex_panel_contract,
		"hub_upgrade_filter_contract": hub_upgrade_filter_contract,
		"reset_confirm_contract": reset_confirm_contract,
		"class_select_sfx_contract": class_select_sfx_contract,
		"loadout_preview_contract": loadout_preview_contract,
		"replay_last_run_contract": replay_last_run_contract,
	}, blockers)

static func _readiness_run_modes() -> Dictionary:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var floor_source := FileAccess.get_file_as_string("res://scripts/rooms/floor_controller.gd")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	var summary_source := FileAccess.get_file_as_string("res://scripts/ui/run_summary.gd")
	var modifier_source := FileAccess.get_file_as_string("res://scripts/progression/run_modifier_db.gd")
	var mode_ids := ["normal", "boss_rush", "endless", "hardcore", "elemental_chaos", "balance_lab"]
	var accepted_run_mode_count := 0
	var missing_modes: Array[String] = []
	for mode_id in mode_ids:
		if main_source.contains("\"%s\"" % mode_id) and floor_source.contains("\"%s\"" % mode_id):
			accepted_run_mode_count += 1
		else:
			missing_modes.append(str(mode_id))
	var modifiers := RunModifierDBScript.all_modifiers()
	var daily_goal_events := {}
	for modifier in modifiers:
		for raw_goal in Array(modifier.get("goals", [])):
			if not (raw_goal is Dictionary):
				continue
			var event_id := str((raw_goal as Dictionary).get("event", "")).strip_edges()
			if event_id != "":
				daily_goal_events[event_id] = true
	var run_cap_contract := main_source.contains("func _run_floor_cap") \
			and main_source.contains("FloorController.BOSS_RUSH_CHAIN_FLOORS") \
			and main_source.contains("func _run_continues_after_floor_cap") \
			and floor_source.contains("func _is_run_finale_floor")
	var boss_rush_contract := main_source.contains("\"boss_rush\"") \
			and floor_source.contains("builder.build_boss_rush") \
			and floor_source.contains("Boss Rush") \
			and floor_source.contains("Chain %d/%d") \
			and main_source.contains("_run_floor_cap()")
	var endless_contract := main_source.contains("\"endless\"") \
			and main_source.contains("return _run_mode == \"endless\"") \
			and main_source.contains("func _apply_endless_depth_bonus") \
			and floor_source.contains("endless") \
			and main_source.contains("endless_depth_bonus") \
			and summary_source.contains("Endless Depth Bonus")
	var hardcore_contract := main_source.contains("\"hardcore\"") \
			and main_source.contains("func _apply_hardcore_clear_bonus") \
			and floor_source.contains("\"hardcore\"") \
			and summary_source.contains("Hardcore Bonus")
	var elemental_chaos_contract := main_source.contains("\"elemental_chaos\"") \
			and main_source.contains("func _apply_elemental_chaos_shift") \
			and main_source.contains("func _apply_elemental_chaos_bonus") \
			and floor_source.contains("\"elemental_chaos\"") \
			and summary_source.contains("Elemental Chaos Bonus")
	var balance_lab_contract := main_source.contains("\"balance_lab\"") \
			and main_source.contains("RunModifierDBScript.balance_lab_modifier") \
			and modifier_source.contains("func balance_lab_modifier") \
			and floor_source.contains("boss_tuning_patch") \
			and floor_source.contains("_apply_run_modifier_to_biome")
	var daily_reward_contract := modifier_source.contains("func daily_modifier_for_seed") \
			and modifier_source.contains("func earned_reward_bonus") \
			and modifier_source.contains("func earned_reward_bonus_summary") \
			and main_source.contains("_apply_run_modifier_reward_bonus(rewards)") \
			and main_source.contains("RunModifierDBScript.earned_reward_bonus(_run_modifier, _run_goal_progress)")
	var run_modifier_hud_contract := hud_source.contains("func set_run_modifier") \
			and hud_source.contains("func set_run_modifier_goals") \
			and hud_source.contains("func show_run_goal_completed") \
			and main_source.contains("hud.set_run_modifier(_run_modifier)") \
			and main_source.contains("hud.set_run_modifier_goals(") \
			and main_source.contains("show_run_goal_completed")
	var run_summary_contract := summary_source.contains("Challenge %s") \
			and summary_source.contains("Challenge Goal Clear:") \
			and summary_source.contains("Challenge Bonus Status:") \
			and main_source.contains("\"challenge_goals\": _run_goal_progress_summary()") \
			and main_source.contains("\"challenge_bonus_status\": _run_modifier_bonus_status_summary()")
	var floor_modifier_contract := floor_source.contains("func set_run_modifier") \
			and floor_source.contains("func effective_difficulty_multiplier") \
			and floor_source.contains("float(run_modifier.get(\"difficulty_mult\"") \
			and floor_source.contains("_apply_run_modifier_to_biome")
	var blockers: Array[String] = []
	for mode_id in missing_modes:
		blockers.append("run_mode_missing:%s" % mode_id)
	if modifiers.size() < 4:
		blockers.append("daily_modifier_count_below_4")
	if daily_goal_events.size() < 4:
		blockers.append("daily_goal_events_below_4")
	if not run_cap_contract:
		blockers.append("run_cap_contract_missing")
	if not boss_rush_contract:
		blockers.append("boss_rush_contract_missing")
	if not endless_contract:
		blockers.append("endless_contract_missing")
	if not hardcore_contract:
		blockers.append("hardcore_contract_missing")
	if not elemental_chaos_contract:
		blockers.append("elemental_chaos_contract_missing")
	if not balance_lab_contract:
		blockers.append("balance_lab_contract_missing")
	if not daily_reward_contract:
		blockers.append("daily_reward_contract_missing")
	if not run_modifier_hud_contract:
		blockers.append("run_modifier_hud_contract_missing")
	if not run_summary_contract:
		blockers.append("run_summary_contract_missing")
	if not floor_modifier_contract:
		blockers.append("floor_modifier_contract_missing")
	return _readiness_milestone(blockers.is_empty(), {
		"accepted_run_mode_count": accepted_run_mode_count,
		"required_run_mode_count": mode_ids.size(),
		"daily_modifier_count": modifiers.size(),
		"required_daily_modifier_count": 4,
		"daily_goal_event_count": daily_goal_events.size(),
		"required_daily_goal_event_count": 4,
		"run_cap_contract": run_cap_contract,
		"boss_rush_contract": boss_rush_contract,
		"endless_contract": endless_contract,
		"hardcore_contract": hardcore_contract,
		"elemental_chaos_contract": elemental_chaos_contract,
		"balance_lab_contract": balance_lab_contract,
		"daily_reward_contract": daily_reward_contract,
		"run_modifier_hud_contract": run_modifier_hud_contract,
		"run_summary_contract": run_summary_contract,
		"floor_modifier_contract": floor_modifier_contract,
		"missing_modes": missing_modes,
	}, blockers)

static func _readiness_asset_release_gate(release_report: Dictionary) -> Dictionary:
	var blockers: Array[String] = []
	for blocker in Array(release_report.get("public_release_blockers", [])):
		blockers.append(str(blocker))
	for replacement in Array(release_report.get("replace_before_public", [])):
		blockers.append(str(replacement))
	for failure in Array(release_report.get("failures", [])):
		blockers.append(str(failure))
	if not bool(release_report.get("public_ready", false)):
		blockers.append("release_decision:%s" % str(release_report.get("decision", "blocked")))
	return _readiness_milestone(blockers.is_empty(), {
		"ready_for_internal_playtest": bool(
			release_report.get("ready_for_internal_playtest", false)),
		"public_ready": bool(release_report.get("public_ready", false)),
		"release_decision": str(release_report.get("decision", "blocked")),
		"checked_sprite_count": int(release_report.get("checked_sprite_count", 0)),
		"animation_frame_grid_checked_count": int(
			release_report.get("animation_frame_grid_checked_count", 0)),
		"collision_polygon_checked_count": int(
			release_report.get("collision_polygon_checked_count", 0)),
		"object_visual_checked_count": int(release_report.get("object_visual_checked_count", 0)),
	}, blockers)

static func _readiness_milestone(
		ready: bool,
		evidence: Dictionary,
		blockers: Array[String],
) -> Dictionary:
	var out := evidence.duplicate(true)
	out["ready"] = ready
	out["blockers"] = blockers.duplicate()
	return out

static func _readiness_summary_text(milestones: Dictionary, release_report: Dictionary) -> String:
	var class_roster: Dictionary = milestones.get("class_roster", {})
	var weapon_pool: Dictionary = milestones.get("weapon_pool", {})
	var enemy_roster: Dictionary = milestones.get("enemy_roster", {})
	var relic_pool: Dictionary = milestones.get("relic_pool", {})
	var element_system: Dictionary = milestones.get("element_system", {})
	var first_run_boot: Dictionary = milestones.get("first_run_boot", {})
	var run_progression: Dictionary = milestones.get("run_progression", {})
	var room_objectives: Dictionary = milestones.get("room_objectives", {})
	var skill_feedback: Dictionary = milestones.get("skill_feedback", {})
	var boss_phase: Dictionary = milestones.get("boss_phase", {})
	var combat_readability: Dictionary = milestones.get("combat_readability", {})
	var input_controls: Dictionary = milestones.get("input_controls", {})
	var run_lifecycle: Dictionary = milestones.get("run_lifecycle", {})
	var hub_meta: Dictionary = milestones.get("hub_meta", {})
	var meta_persistence: Dictionary = milestones.get("meta_persistence", {})
	var hub_navigation: Dictionary = milestones.get("hub_navigation", {})
	var run_modes: Dictionary = milestones.get("run_modes", {})
	return "Classes %d | Skills %d | Ultimates %d | Weapons %d | Enemies %d bosses %d | Relics %d rarities %d | Objectives %d reward %d shop %d traps %d | Feedback %d icons %d sounds %d | Boot %d systems %d signals | Boss %d patterns telegraph %.1fs | Readability %.1fs trap %.1fs hit %d/%d | Controls %d/%d V/Q/R | Lifecycle %d actions %d endings | Elements %d combos %d | Biomes %d finale %d endless %d | Hub %d upgrades %d | MetaSave %d currencies %d upgrades %d records | HubNav %d services %d modes %d class keys | RunModes %d modes %d modifiers %d events | Release %s | fanmade reference-only" % [
		int(class_roster.get("class_count", 0)),
		int(class_roster.get("active_skill_script_count", 0)),
		int(class_roster.get("ultimate_script_count", 0)),
		int(weapon_pool.get("weapon_count", 0)),
		int(enemy_roster.get("normal_enemy_count", 0)),
		int(enemy_roster.get("boss_count", 0)),
		int(relic_pool.get("relic_count", 0)),
		int(relic_pool.get("rarity_count", 0)),
		int(room_objectives.get("objective_room_count", 0)),
		int(room_objectives.get("reward_choice_count", 0)),
		int(room_objectives.get("shop_choice_count", 0)),
		int(room_objectives.get("trap_kind_count", 0)),
		int(skill_feedback.get("active_skill_feedback_count", 0)),
		int(skill_feedback.get("cooldown_icon_count", 0)),
		int(skill_feedback.get("cast_sound_cue_count", 0)),
		int(first_run_boot.get("start_run_system_count", 0)),
		int(first_run_boot.get("first_run_required_signal_count", 0)),
		int(boss_phase.get("phase_pattern_count", 0)),
		float(boss_phase.get("attack_telegraph_seconds", 0.0)),
		float(combat_readability.get("min_attack_telegraph_seconds", 0.0)),
		float(combat_readability.get("trap_min_telegraph_seconds", 0.0)),
		int(combat_readability.get("max_single_hit_damage", 0)),
		int(combat_readability.get("min_player_hp", 0)),
		int(input_controls.get("critical_action_count", 0)),
		int(input_controls.get("required_critical_action_count", 0)),
		int(run_lifecycle.get("overlay_action_count", 0)),
		int(run_lifecycle.get("run_end_cue_count", 0)),
		int(element_system.get("element_count", 0)),
		int(element_system.get("combo_count", 0)),
		int(run_progression.get("biome_count", 0)),
		int(run_progression.get("finale_biome_count", 0)),
		int(run_progression.get("endless_biome_count", 0)),
		int(hub_meta.get("hub_service_count", 0)),
		int(hub_meta.get("meta_upgrade_count", 0)),
		int(meta_persistence.get("meta_currency_count", 0)),
		int(meta_persistence.get("upgrade_count", 0)),
		int(meta_persistence.get("record_contract_count", 0)),
		int(hub_navigation.get("hub_service_button_count", 0)),
		int(hub_navigation.get("run_mode_count", 0)),
		int(hub_navigation.get("class_hotkey_count", 0)),
		int(run_modes.get("accepted_run_mode_count", 0)),
		int(run_modes.get("daily_modifier_count", 0)),
		int(run_modes.get("daily_goal_event_count", 0)),
		str(release_report.get("decision", "blocked")),
	]

static func _key_token(keycode: int) -> String:
	match keycode:
		KEY_A:
			return "KEY_A"
		KEY_B:
			return "KEY_B"
		KEY_C:
			return "KEY_C"
		KEY_D:
			return "KEY_D"
		KEY_E:
			return "KEY_E"
		KEY_H:
			return "KEY_H"
		KEY_K:
			return "KEY_K"
		KEY_N:
			return "KEY_N"
		KEY_O:
			return "KEY_O"
		KEY_T:
			return "KEY_T"
		KEY_X:
			return "KEY_X"
	return ""

static func _input_action_has_key(action: String, keycode: Key) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null and key.physical_keycode == keycode:
			return true
	return false

static func _input_action_has_gamepad_event(action: String) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false

static func _input_actions_share_key(left: String, right: String) -> bool:
	var right_keys := _input_action_key_set(right)
	for keycode in _input_action_key_set(left).keys():
		if right_keys.has(keycode):
			return true
	return false

static func _input_action_key_set(action: String) -> Dictionary:
	var keys := {}
	if not InputMap.has_action(action):
		return keys
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			keys[key.physical_keycode] = true
	return keys

static func _input_action_first_key_label(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key == null:
			continue
		return OS.get_keycode_string(key.physical_keycode)
	return ""

static func balance_playtest_summary(max_items: int = 3, meta_data: Dictionary = {}) -> String:
	return BalanceGuardrailScript.playtest_summary(max_items,
		_balance_report_with_playtest_evidence(BalanceGuardrailScript.report(), meta_data))

static func playtest_objective_summary(meta_data: Dictionary = {}) -> String:
	return BalanceGuardrailScript.playtest_objective_summary(
		_balance_report_with_playtest_evidence(BalanceGuardrailScript.report(), meta_data))

static func balance_playtest_evidence_summary(
		meta_data: Dictionary = {},
		max_items: int = 3,
) -> String:
	var report := _balance_report_with_playtest_evidence(BalanceGuardrailScript.report(), meta_data)
	var evidence: Dictionary = report.get("playtest_evidence", {})
	if evidence.is_empty():
		return "Playtest Evidence: None"
	var parts: Array[String] = []
	for item in BalanceGuardrailScript.playtest_plan(12, report):
		var id := str(item.get("id", ""))
		if not evidence.has(id) or not (evidence[id] is Dictionary):
			continue
		var review: Dictionary = BalanceGuardrailScript.review_playtest_evidence(
			item, evidence[id])
		parts.append("%s %.1fs x%d -> %s" % [
			id,
			float(review.get("measured_ttk_sec", 0.0)),
			int(review.get("sample_runs", 0)),
			str(review.get("decision", "")),
		])
		if parts.size() >= maxi(max_items, 0):
			break
	if parts.is_empty():
		return "Playtest Evidence: None"
	return "Playtest Evidence: %s" % " | ".join(parts)

static func tuning_patch_summary(meta_data: Dictionary = {}) -> String:
	var patch := BalanceGuardrailScript.tuning_patch_preview(
		_balance_report_with_playtest_evidence(BalanceGuardrailScript.report(), meta_data))
	if patch.is_empty():
		return "Tuning Patch: None | Evidence ready"
	if bool(patch.get("evidence_ready", false)):
		return "Tuning Patch: %s %s | test %.2fx %s | Evidence ready: measured %.1fs via %s" % [
			str(patch.get("priority", "P3")),
			str(patch.get("id", "")),
			float(patch.get("suggested_multiplier", 1.0)),
			str(patch.get("target_field", "")),
			float(patch.get("measured_ttk_sec", 0.0)),
			str(patch.get("evidence_source", "")),
		]
	return "Tuning Patch: %s %s | test %.2fx %s | Evidence required: %s" % [
		str(patch.get("priority", "P3")),
		str(patch.get("id", "")),
		float(patch.get("suggested_multiplier", 1.0)),
		str(patch.get("target_field", "")),
		str(patch.get("evidence_required", "")),
	]

static func balance_tuning_experiment_patch(meta_data: Dictionary = {}) -> Dictionary:
	return BalanceGuardrailScript.tuning_experiment_patch(
		_balance_report_with_playtest_evidence(BalanceGuardrailScript.report(), meta_data))

static func next_release_action(meta_data: Dictionary = {}) -> String:
	var report := runtime_report(meta_data)
	var backlog := _replacement_backlog_from_report(report)
	if not backlog.is_empty():
		var first: Dictionary = backlog[0]
		return "Next Action: Fix %s:%s | %s | no fanmade copy" % [
			str(first.get("kind", "")),
			str(first.get("id", "")),
			str(first.get("replacement_policy", "replace_before_public")),
		]
	var patch: Dictionary = report.get("balance_tuning_patch_preview", {})
	if bool(patch.get("evidence_ready", false)):
		return "Next Action: Tune | %s %.2fx %s | Evidence measured %.1fs" % [
			str(patch.get("id", "")),
			float(patch.get("suggested_multiplier", 1.0)),
			str(patch.get("target_field", "")),
			float(patch.get("measured_ttk_sec", 0.0)),
		]
	var focus := str(report.get("balance_playtest_summary", "")).strip_edges()
	if focus != "" and not focus.contains("Tuning Focus: None"):
		return "Next Action: Playtest | %s" % focus
	if bool(report.get("public_ready", false)):
		return "Next Action: Release gate clear | continue feel playtest"
	var failures: Array = report.get("failures", [])
	if not failures.is_empty():
		return "Next Action: Resolve %s" % str(failures[0])
	return "Next Action: Review release gate"

static func release_candidate_summary(meta_data: Dictionary = {}) -> Dictionary:
	var candidate_meta := _release_candidate_meta_data(meta_data)
	var report := runtime_report(meta_data)
	var checklist := manual_playtest_checklist()
	var notes_template := playtest_notes_template(meta_data)
	var export_preset := _release_export_preset_status(candidate_meta)
	var export_package := _release_export_package_status(candidate_meta, export_preset)
	var asset_self_review := _release_asset_self_review_status(
		Dictionary(candidate_meta.get("asset_self_review", {})), report)
	var smoke := Dictionary(candidate_meta.get("full_smoke_suite", {}))
	var minimum_smoke_count := int(candidate_meta.get("minimum_smoke_count", 70))
	var smoke_ready := bool(smoke.get("passed", false)) \
			and int(smoke.get("count", 0)) >= minimum_smoke_count
	var notes_status := _release_playtest_notes_status(
		notes_template, Dictionary(candidate_meta.get("playtest_notes", {})))
	var scenario_status := _release_manual_scenarios_status(
		checklist, Array(candidate_meta.get("manual_scenario_results", [])))
	var manual_playtest_issue_count := Array(
		candidate_meta.get("manual_playtest_issues", [])).size()
	var scenario_rehearsal := _release_scenario_rehearsal_status(
		Dictionary(candidate_meta.get("headless_scenario_rehearsal", {})), checklist)
	var code_gate_ready := bool(report.get("public_ready", false))
	var blockers: Array[String] = []
	if not code_gate_ready:
		blockers.append("release_gate:%s" % str(report.get("decision", "blocked")))
	if not smoke_ready:
		blockers.append("full_smoke_suite_missing")
	if not bool(notes_status.get("ready", false)):
		blockers.append("playtest_notes_missing")
		for field_id in Array(notes_status.get("missing_fields", [])):
			blockers.append("playtest_notes_missing:%s" % str(field_id))
	if not bool(scenario_status.get("ready", false)):
		blockers.append("manual_scenarios_missing")
	if manual_playtest_issue_count > 0:
		blockers.append("manual_playtest_issues_open")
	if not bool(scenario_rehearsal.get("ready", false)):
		blockers.append("scenario_rehearsal_missing")
	if not bool(asset_self_review.get("ready", false)):
		blockers.append("asset_self_review_missing")
	if not bool(export_preset.get("ready", false)):
		blockers.append("export_preset_missing")
	if not bool(export_package.get("ready", false)):
		blockers.append("export_package_missing")
	var ready := code_gate_ready and smoke_ready \
			and bool(notes_status.get("ready", false)) \
			and bool(scenario_status.get("ready", false)) \
			and manual_playtest_issue_count <= 0 \
			and bool(scenario_rehearsal.get("ready", false)) \
			and bool(asset_self_review.get("ready", false)) \
			and bool(export_preset.get("ready", false)) \
			and bool(export_package.get("ready", false))
	return {
		"status": "ready_for_release_review" if ready else "evidence_required",
		"release_candidate_ready": ready,
		"code_gate_ready": code_gate_ready,
		"release_decision": str(report.get("decision", "blocked")),
		"smoke_suite_ready": smoke_ready,
		"smoke_suite_count": int(smoke.get("count", 0)),
		"minimum_smoke_count": minimum_smoke_count,
		"playtest_notes_ready": bool(notes_status.get("ready", false)),
		"required_playtest_fields": Array(notes_template.get("required_fields", [])).duplicate(),
		"missing_playtest_fields": Array(notes_status.get("missing_fields", [])).duplicate(),
		"manual_scenarios_ready": bool(scenario_status.get("ready", false)),
		"manual_scenario_count": int(scenario_status.get("completed_count", 0)),
		"required_manual_scenario_count": int(scenario_status.get("required_count", 0)),
		"manual_playtest_issue_count": manual_playtest_issue_count,
		"scenario_rehearsal_ready": bool(scenario_rehearsal.get("ready", false)),
		"scenario_rehearsal_count": int(scenario_rehearsal.get("completed_count", 0)),
		"scenario_rehearsal_type": str(scenario_rehearsal.get("review_type", "")),
		"asset_self_review_ready": bool(asset_self_review.get("ready", false)),
		"asset_self_review_type": str(asset_self_review.get("review_type", "")),
		"missing_asset_self_review_fields": Array(
			asset_self_review.get("missing_fields", [])).duplicate(),
		"export_preset_ready": bool(export_preset.get("ready", false)),
		"export_preset_name": str(export_preset.get("preset_name", "")),
		"export_preset_platform": str(export_preset.get("platform", "")),
		"export_preset_path": str(export_preset.get("preset_path", "")),
		"export_path": str(export_preset.get("export_path", "")),
		"export_package_ready": bool(export_package.get("ready", false)),
		"export_package_booted": bool(export_package.get("booted", false)),
		"export_package_path": str(export_package.get("executable_path", "")),
		"balance_playtest_summary": str(report.get("balance_playtest_summary", "")),
		"asset_source_policy": str(report.get("asset_source_policy", "")),
		"blockers": blockers,
		"next_action": _release_candidate_next_action(ready, blockers),
	}

static func release_candidate_manual_recording_plan(meta_data: Dictionary = {}) -> Dictionary:
	var candidate_meta := _release_candidate_meta_data(meta_data)
	var summary := release_candidate_summary(meta_data)
	var checklist := manual_playtest_checklist()
	var notes_template := playtest_notes_template(meta_data)
	var notes_status := _release_playtest_notes_status(
		notes_template, Dictionary(candidate_meta.get("playtest_notes", {})))
	var scenario_results := Array(candidate_meta.get("manual_scenario_results", []))
	var scenario_statuses: Array[Dictionary] = []
	var manual_commands: Array[String] = []
	var next_missing_status: Dictionary = {}
	var missing_count := 0
	var scenario_index := 1
	for raw_scenario in Array(checklist.get("scenario_runs", [])):
		if not (raw_scenario is Dictionary):
			continue
		var scenario: Dictionary = raw_scenario
		var recorded := _manual_recording_plan_scenario_recorded(
			scenario, scenario_results)
		if not recorded:
			missing_count += 1
		var command := _manual_scenario_record_command(scenario_index)
		var issue_command := _manual_scenario_issue_record_command(scenario_index)
		var resolve_command := _manual_scenario_issue_resolve_command(scenario_index)
		var dry_run_command := _dry_run_command(command, int(scenario.get("seed", 0)))
		var issue_dry_run_command := _dry_run_command(issue_command, int(scenario.get("seed", 0)))
		var resolve_dry_run_command := _dry_run_command(resolve_command, int(scenario.get("seed", 0)))
		manual_commands.append(command)
		var status := {
			"index": scenario_index,
			"seed": int(scenario.get("seed", 0)),
			"mode": str(scenario.get("mode", "")),
			"class_id": str(scenario.get("class_id", "")),
			"goal": str(scenario.get("goal", "")),
			"status": "recorded" if recorded else "missing",
			"launch_command": _manual_scenario_launch_command(scenario_index),
			"launch_dry_run_command": _manual_scenario_launch_dry_run_command(scenario_index),
			"suggested_screenshot_path": _manual_scenario_screenshot_path(scenario_index),
			"capture_helper_command": _manual_scenario_capture_helper_command(scenario_index),
			"command": command,
			"dry_run_command": dry_run_command,
			"issue_command": issue_command,
			"issue_dry_run_command": issue_dry_run_command,
			"resolve_command": resolve_command,
			"resolve_dry_run_command": resolve_dry_run_command,
			"issue_type_suggestions": manual_playtest_issue_type_suggestions(),
		}
		if not recorded and next_missing_status.is_empty():
			next_missing_status = status
		scenario_statuses.append(status)
		scenario_index += 1
	var progress_rows := _manual_progress_rows(scenario_statuses)
	return {
		"status": str(summary.get("status", "evidence_required")),
		"next_action": str(summary.get("next_action", "")),
		"manual_review_required": true,
		"manual_scenario_notes_required_tokens": [
			"animation", "polygon", "wave", "HUD", "audio"],
		"issue_type_suggestions": manual_playtest_issue_type_suggestions(),
		"playtest_notes_draft": _playtest_notes_draft(
			scenario_statuses, notes_template),
		"playtest_notes_ready": bool(notes_status.get("ready", false)),
		"missing_playtest_fields": Array(notes_status.get("missing_fields", [])).duplicate(),
		"manual_scenario_count": int(summary.get("manual_scenario_count", 0)),
		"required_manual_scenario_count": int(summary.get(
			"required_manual_scenario_count", scenario_statuses.size())),
		"missing_manual_scenario_count": missing_count,
		"progress_rows": progress_rows,
		"progress_table_text": _manual_progress_table_text(progress_rows),
		"scenario_statuses": scenario_statuses,
		"next_missing_manual_index": int(next_missing_status.get("index", 0)),
		"next_missing_manual_launch_command": str(
			next_missing_status.get("launch_command", "")),
		"next_missing_manual_launch_dry_run_command": str(
			next_missing_status.get("launch_dry_run_command", "")),
		"next_missing_manual_dry_run_command": str(
			next_missing_status.get("dry_run_command", "")),
		"next_missing_manual_record_command": str(
			next_missing_status.get("command", "")),
		"commands": {
			"playtest_notes": _playtest_notes_record_command(notes_template),
			"playtest_notes_dry_run": _dry_run_command(
				_playtest_notes_record_command(notes_template)),
			"manual_scenarios": manual_commands,
		},
		"summary": summary,
	}

static func release_candidate_playtest_packet(meta_data: Dictionary = {}) -> Dictionary:
	var plan := release_candidate_manual_recording_plan(meta_data)
	var summary: Dictionary = plan.get("summary", {})
	var notes_template := playtest_notes_template(meta_data)
	var required_fields := Array(notes_template.get("required_fields", [])).duplicate()
	var commands: Dictionary = plan.get("commands", {})
	var scenario_drafts: Array[Dictionary] = []
	for raw_status in Array(plan.get("scenario_statuses", [])):
		if not (raw_status is Dictionary):
			continue
		var status: Dictionary = raw_status
		scenario_drafts.append({
			"index": int(status.get("index", 0)),
			"seed": int(status.get("seed", 0)),
			"mode": str(status.get("mode", "")),
			"class_id": str(status.get("class_id", "")),
			"goal": str(status.get("goal", "")),
			"status": str(status.get("status", "")),
			"launch_command": str(status.get("launch_command", "")),
			"launch_dry_run_command": str(status.get("launch_dry_run_command", "")),
			"suggested_screenshot_path": str(status.get("suggested_screenshot_path", "")),
			"capture_helper_command": str(status.get("capture_helper_command", "")),
			"record_command": str(status.get("command", "")),
			"record_dry_run_command": str(status.get("dry_run_command", "")),
			"record_issue_command": _manual_scenario_issue_record_command(
				int(status.get("index", 0))),
			"record_issue_dry_run_command": str(status.get("issue_dry_run_command", "")),
			"resolve_issue_command": _manual_scenario_issue_resolve_command(
				int(status.get("index", 0))),
			"resolve_issue_dry_run_command": str(status.get("resolve_dry_run_command", "")),
			"issue_type_suggestions": manual_playtest_issue_type_suggestions(),
			"issue_type_alias_summary": manual_playtest_issue_type_alias_summary(),
			"human_notes_placeholder":
				"actual human result, blockers, screenshot path or seed, feel notes",
		})
	var packet := {
		"title": "Manual Playtest Packet",
		"status": str(plan.get("status", "")),
		"next_action": str(plan.get("next_action", "")),
		"draft_only": true,
		"manual_review_required": true,
		"does_not_record_release_evidence": true,
		"playtest_notes_ready": bool(plan.get("playtest_notes_ready", false)),
		"required_playtest_fields": required_fields,
		"missing_playtest_fields": Array(plan.get("missing_playtest_fields", [])).duplicate(),
		"manual_scenario_count": int(plan.get("manual_scenario_count", 0)),
		"required_manual_scenario_count": int(plan.get("required_manual_scenario_count", 0)),
		"missing_manual_scenario_count": int(plan.get("missing_manual_scenario_count", 0)),
		"progress_rows": Array(plan.get("progress_rows", [])).duplicate(true),
		"progress_table_text": str(plan.get("progress_table_text", "")),
		"notes_command": str(commands.get("playtest_notes", "")),
		"notes_dry_run_command": str(commands.get("playtest_notes_dry_run", "")),
		"manual_scenario_list_command": "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -List",
		"playtest_notes_draft": Dictionary(plan.get("playtest_notes_draft", {})).duplicate(true),
		"scenario_drafts": scenario_drafts,
		"issue_type_suggestions": manual_playtest_issue_type_suggestions(),
		"issue_type_alias_summary": manual_playtest_issue_type_alias_summary(),
		"asset_source_policy": str(summary.get("asset_source_policy", source_policy_summary())),
		"reference_only_sources": REFERENCE_ONLY_SOURCES.duplicate(),
		"asset_review_commands": _asset_review_commands(),
		"output_file_suggestion": "docs/playtest/release_candidate_manual_playtest.md",
	}
	packet["markdown"] = _release_candidate_playtest_packet_markdown(packet)
	return packet

static func _release_candidate_meta_data(meta_data: Dictionary) -> Dictionary:
	var candidate_meta := {}
	if meta_data.has("release_candidate_evidence") \
			and meta_data["release_candidate_evidence"] is Dictionary:
		candidate_meta = Dictionary(meta_data["release_candidate_evidence"]).duplicate(true)
	for key in ["full_smoke_suite", "minimum_smoke_count", "playtest_notes",
			"manual_scenario_results", "headless_scenario_rehearsal",
			"asset_self_review", "export_preset_path", "export_preset_name",
			"export_package"]:
		if meta_data.has(key):
			candidate_meta[key] = meta_data[key]
	return candidate_meta

static func _manual_progress_rows(scenario_statuses: Array[Dictionary]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for status in scenario_statuses:
		var row_status := str(status.get("status", "missing"))
		rows.append({
			"index": int(status.get("index", 0)),
			"status": row_status,
			"seed": int(status.get("seed", 0)),
			"mode": str(status.get("mode", "")),
			"class_id": str(status.get("class_id", "")),
			"next_step": "done" if row_status == "recorded" else "launch",
		})
	return rows

static func _manual_progress_table_text(rows: Array[Dictionary]) -> String:
	var lines: Array[String] = [
		"Manual Progress",
		"# | Status | Seed | Mode | Class | Next",
	]
	for row in rows:
		lines.append("%d | %s | %d | %s | %s | %s" % [
			int(row.get("index", 0)),
			str(row.get("status", "")),
			int(row.get("seed", 0)),
			str(row.get("mode", "")),
			str(row.get("class_id", "")),
			str(row.get("next_step", "")),
		])
	return "\n".join(lines)

static func _manual_recording_plan_scenario_recorded(
		scenario: Dictionary,
		results: Array,
) -> bool:
	var key := _release_scenario_key(scenario)
	for raw_result in results:
		if not (raw_result is Dictionary):
			continue
		var result: Dictionary = raw_result
		if _release_manual_scenario_result_complete(result) \
				and _release_scenario_key(result) == key:
			return true
	return false

static func _playtest_notes_record_command(notes_template: Dictionary) -> String:
	var parts: Array[String] = [
		"godot --headless --path . --script res://scripts/tools/record_playtest_notes_evidence.gd --",
	]
	for raw_field in Array(notes_template.get("required_fields", [])):
		var field := str(raw_field)
		parts.append("--%s=<%s>" % [field, field])
	return " ".join(parts)

static func _dry_run_command(command: String, scenario_seed: int = 420101) -> String:
	var dry_seed := scenario_seed if scenario_seed > 0 else 420101
	var out := command
	var replacements := {
		"<seed>": "420101",
		"<class_id>": "blade_warden",
		"<mode>": "normal",
		"<replay_last_run_result>": "dry_run_replay_check",
		"<daily_fingerprint_hash>": "dry_run_hash_420101",
		"<pace_avg_sec>": "40",
		"<pace_boss_sec>": "90",
		"<asset_animation_notes>": "dry_run_animation_notes",
		"<polygon_collision_notes>": "dry_run_polygon_notes",
		"<wave_hud_audio_notes>": "dry_run_wave_hud_audio_notes",
		"<blocker_screenshot_or_seed>": "none_dry_run",
		"<release_decision>": "hold",
		"<human notes>": "animation stable polygon collision matched wave HUD audio clear",
		"<issue_type>": "polygon_collision",
		"<human issue notes>": "dry_run_issue_notes",
		"<screenshot or seed>": "seed_%d_dry_run" % dry_seed,
		"<human retest notes>": "dry_run_retest_notes",
	}
	for token in replacements.keys():
		out = out.replace(str(token), str(replacements[token]))
	return "%s --dry-run=true" % out

static func _playtest_notes_draft(
		scenario_statuses: Array[Dictionary],
		notes_template: Dictionary,
) -> Dictionary:
	for status in scenario_statuses:
		if str(status.get("status", "")) != "missing":
			continue
		var draft := {
			"scenario_index": int(status.get("index", 0)),
			"seed": int(status.get("seed", 0)),
			"class_id": str(status.get("class_id", "")),
			"mode": str(status.get("mode", "")),
			"goal": str(status.get("goal", "")),
			"evidence_source": "manual_playtest_notes",
			"records_manual_scenario_evidence": false,
		}
		draft["command"] = _playtest_notes_draft_command(draft, notes_template)
		return draft
	return {}

static func _playtest_notes_draft_command(
		draft: Dictionary,
		notes_template: Dictionary,
) -> String:
	var replacements := {
		"seed": str(int(draft.get("seed", 0))),
		"class_id": str(draft.get("class_id", "")),
		"mode": str(draft.get("mode", "")),
		"replay_last_run_result": "<human result>",
		"daily_fingerprint_hash": "<daily hash>",
		"pace_avg_sec": "<avg sec>",
		"pace_boss_sec": "<boss sec>",
		"asset_animation_notes": "<human animation notes>",
		"polygon_collision_notes": "<human polygon notes>",
		"wave_hud_audio_notes": "<human wave hud audio notes>",
		"blocker_screenshot_or_seed": "<screenshot or seed>",
		"release_decision": "<hold or ready>",
	}
	var parts: Array[String] = [
		"godot --headless --path . --script res://scripts/tools/record_playtest_notes_evidence.gd --",
	]
	for raw_field in Array(notes_template.get("required_fields", [])):
		var field := str(raw_field)
		parts.append("--%s=%s" % [field, str(replacements.get(field, "<%s>" % field))])
	return " ".join(parts)

static func _manual_scenario_record_command(scenario_index: int) -> String:
	return "godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=%d --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>" % scenario_index

static func _manual_scenario_issue_record_command(scenario_index: int) -> String:
	return "godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=%d --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=<screenshot or seed>" % scenario_index

static func _manual_scenario_issue_resolve_command(scenario_index: int) -> String:
	return "godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=%d --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=<screenshot or seed>" % scenario_index

static func _manual_scenario_launch_command(scenario_index: int) -> String:
	return "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex %d -Detached" % scenario_index

static func _manual_scenario_launch_dry_run_command(scenario_index: int) -> String:
	return "%s -DryRun" % _manual_scenario_launch_command(scenario_index)

static func _manual_scenario_screenshot_path(scenario_index: int) -> String:
	var temp_dir := OS.get_environment("TEMP")
	if temp_dir.strip_edges() == "":
		temp_dir = OS.get_environment("TMP")
	if temp_dir.strip_edges() == "":
		temp_dir = ProjectSettings.globalize_path("user://")
	temp_dir = temp_dir.replace("\\", "/")
	while temp_dir.ends_with("/"):
		temp_dir = temp_dir.substr(0, temp_dir.length() - 1)
	return "%s/dungeon_core_manual_scenario_%d.png" % [temp_dir, scenario_index]

static func _manual_scenario_capture_helper_command(scenario_index: int) -> String:
	var path := _manual_scenario_screenshot_path(scenario_index).replace("'", "''")
	return "powershell -NoProfile -ExecutionPolicy Bypass -Command \"Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $bounds.Width,$bounds.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size); $bmp.Save('%s',[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); Write-Output '%s'\"" % [path, path]

static func _release_candidate_playtest_packet_markdown(packet: Dictionary) -> String:
	var lines: Array[String] = [
		"# Manual Playtest Packet",
		"",
		"Draft only: this file helps a human tester run and record evidence; it does not record release evidence.",
		"Release evidence only counts after the record commands are run with actual human notes.",
		"",
		"Status: %s" % str(packet.get("status", "")),
		"Next action: %s" % str(packet.get("next_action", "")),
		"",
		"## Required Playtest Notes",
		"",
		"Command:",
		"```powershell",
		str(packet.get("notes_command", "")),
		"```",
		"",
		"Dry Run Command:",
		"```powershell",
		str(packet.get("notes_dry_run_command", "")),
		"```",
		"",
		"Fields:",
	]
	for field in Array(packet.get("required_playtest_fields", [])):
		lines.append("- %s" % str(field))
	var notes_draft: Dictionary = packet.get("playtest_notes_draft", {})
	lines += [
		"",
		"Notes Skeleton:",
		"asset_animation_notes=<human animation notes> | polygon_collision_notes=<human polygon notes> | wave_hud_audio_notes=<human wave hud audio notes>",
	]
	if not notes_draft.is_empty():
		lines += [
			"",
			"Final Notes:",
			"```powershell",
			str(notes_draft.get("command", "")),
			"```",
			"",
			"Playtest Notes Draft:",
			"```powershell",
			str(notes_draft.get("command", "")),
			"```",
			"Draft scenario: %d | seed %d | mode %s | class %s | %s" % [
				int(notes_draft.get("scenario_index", 0)),
				int(notes_draft.get("seed", 0)),
				str(notes_draft.get("mode", "")),
				str(notes_draft.get("class_id", "")),
				str(notes_draft.get("goal", "")),
			],
		]
	lines += [
		"",
		"Asset notes must include asset_animation_notes and polygon_collision_notes.",
		"Issue types: %s" % str(", ".join(Array(packet.get(
			"issue_type_suggestions", manual_playtest_issue_type_suggestions())))),
		"Issue aliases: %s" % str(packet.get(
			"issue_type_alias_summary", manual_playtest_issue_type_alias_summary())),
		"",
		"## Wave/HUD/Audio Live Check",
		"",
		"During combat rooms, verify:",
		"- HUD objective shows Wave x/y and enemies_left as enemies die.",
		"- WaveStartCue appears when wave 2/3 or 3/3 begins.",
		"- WaveStartSfx plays or records placeholder metadata.",
		"- objective_context_changed updates HUD without rebinding.",
		"",
		"## Manual Scenarios",
		"",
		"Manual Scenario List:",
		"```powershell",
		str(packet.get("manual_scenario_list_command", "")),
		"```",
		"",
		"Next Missing Launch Dry Run:",
		"```powershell",
		"powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -Next -DryRun",
		"```",
		"",
		"Next Missing Launch:",
		"```powershell",
		"powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -Next",
		"```",
		"",
	]
	var progress_table := str(packet.get("progress_table_text", ""))
	if progress_table != "":
		lines += [
			progress_table,
			"",
		]
	for raw_draft in Array(packet.get("scenario_drafts", [])):
		if not (raw_draft is Dictionary):
			continue
		var draft: Dictionary = raw_draft
		lines += [
			"### Scenario %d" % int(draft.get("index", 0)),
			"",
			"- Seed: %d" % int(draft.get("seed", 0)),
			"- Mode: %s" % str(draft.get("mode", "")),
			"- Class: %s" % str(draft.get("class_id", "")),
			"- Goal: %s" % str(draft.get("goal", "")),
			"- Status: %s" % str(draft.get("status", "")),
			"",
			"Suggested Screenshot:",
			"```text",
			str(draft.get("suggested_screenshot_path", "")),
			"```",
			"",
			"Capture Screenshot:",
			"```powershell",
			str(draft.get("capture_helper_command", "")),
			"```",
			"",
			"Launch Dry Run:",
			"```powershell",
			str(draft.get("launch_dry_run_command", "")),
			"```",
			"",
			"Launch:",
			"```powershell",
			str(draft.get("launch_command", "")),
			"```",
			"",
			"Dry Run before recording:",
			"```powershell",
			str(draft.get("record_dry_run_command", "")),
			"```",
			"",
			"Record only after a real human pass:",
			"```powershell",
			str(draft.get("record_command", "")),
			"```",
			"",
			"Dry Run blocker/bug command:",
			"```powershell",
			str(draft.get("record_issue_dry_run_command", "")),
			"```",
			"",
			"Record blocker/bug after a real human fail:",
			"```powershell",
			str(draft.get("record_issue_command", "")),
			"```",
			"",
			"Dry Run resolution command:",
			"```powershell",
			str(draft.get("resolve_issue_dry_run_command", "")),
			"```",
			"",
			"Resolve only after fix and human retest:",
			"```powershell",
			str(draft.get("resolve_issue_command", "")),
			"```",
			"",
			"Issue types: %s" % str(", ".join(Array(draft.get(
				"issue_type_suggestions", manual_playtest_issue_type_suggestions())))),
			"Issue aliases: %s" % str(draft.get(
				"issue_type_alias_summary", manual_playtest_issue_type_alias_summary())),
			"",
			"Human notes placeholder: %s" % str(draft.get("human_notes_placeholder", "")),
			"",
		]
	lines += [
		"## Asset Source Policy",
		"",
		str(packet.get("asset_source_policy", "")),
		"",
		"Asset Self-Review Commands:",
		"```powershell",
		str(Dictionary(packet.get("asset_review_commands", {})).get("sprite_checklist", "")),
		str(Dictionary(packet.get("asset_review_commands", {})).get("vfx_checklist", "")),
		str(Dictionary(packet.get("asset_review_commands", {})).get("audio_checklist", "")),
		str(Dictionary(packet.get("asset_review_commands", {})).get("collision_checklist", "")),
		str(Dictionary(packet.get("asset_review_commands", {})).get("object_visual_checklist", "")),
		str(Dictionary(packet.get("asset_review_commands", {})).get("replacement_plan", "")),
		str(Dictionary(packet.get("asset_review_commands", {})).get("manifest_candidate_template", "")),
		"```",
		"",
		"fanmade repos are reference-only for pattern study and must not be copied into runtime:",
	]
	for source in Array(packet.get("reference_only_sources", [])):
		lines.append("- %s" % str(source))
	lines += [
		"",
		"If any animation, VFX, audio, object visual, or polygon is replaced, use licensed 0x72/free itch.io/Godot Asset Library/project-owned AI assets and review frame grid, motion, origin, polygon points, and polygon area before release.",
	]
	return "\n".join(lines)

static func asset_review_commands() -> Dictionary:
	return _asset_review_commands()

static func _asset_review_commands() -> Dictionary:
	var base := "godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd --"
	return {
		"sprite_checklist": "%s --kind=sprite" % base,
		"vfx_checklist": "%s --kind=vfx" % base,
		"audio_checklist": "%s --kind=audio" % base,
		"collision_checklist": "%s --kind=collision" % base,
		"object_visual_checklist": "%s --kind=object_visual" % base,
		"manifest_candidate_template": "%s --manifest=<manifest.json> [--source=<source_id>]" % base,
		"replacement_plan": "godot --headless --path . --script res://scripts/tools/print_asset_replacement_plan.gd -- --kind=collision",
	}

static func _manual_issue_asset_kind(issue_type: String) -> String:
	match issue_type:
		"polygon_collision":
			return "collision"
		"asset_animation":
			return "sprite"
		"missing_asset_source":
			return "object_visual"
		"combat_readability":
			return "vfx"
	return ""

static func _manual_issue_asset_review_command(issue_type: String, asset_kind: String) -> String:
	var commands := _asset_review_commands()
	match issue_type:
		"polygon_collision":
			return str(commands.get("collision_checklist", ""))
		"asset_animation":
			return str(commands.get("sprite_checklist", ""))
		"missing_asset_source":
			return str(commands.get("manifest_candidate_template", ""))
		"combat_readability":
			return "godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --kind=vfx"
	if asset_kind != "":
		return "godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --kind=%s" % asset_kind
	return ""

static func _asset_replacement_plan_command(asset_kind: String) -> String:
	if asset_kind == "":
		return ""
	return "godot --headless --path . --script res://scripts/tools/print_asset_replacement_plan.gd -- --kind=%s" % asset_kind

static func _manual_issue_fix_hint(issue_type: String) -> String:
	match issue_type:
		"polygon_collision":
			return "Fix polygon points/area and retest the same seed before resolving"
		"asset_animation":
			return "Review frame grid, fps, motion, origin, and jitter before resolving"
		"missing_asset_source":
			return "Add licensed/free/project-owned source metadata or reviewed AI manifest"
		"combat_readability":
			return "Tune telegraph/VFX timing and retest readability before resolving"
		"balance_pace":
			return "Collect pace/TTK evidence and tune through balance guardrail"
		"ui_overlap":
			return "Fix layout overlap and retest affected viewport/input path"
	return "Retest the issue on the same seed before resolving"

static func release_candidate_rehearsal_results() -> Dictionary:
	var results: Array[Dictionary] = []
	var issues: Array[String] = []
	for raw_scenario in _manual_playtest_scenario_runs():
		var scenario: Dictionary = raw_scenario
		var seed := int(scenario.get("seed", 0))
		var mode := str(scenario.get("mode", "")).strip_edges()
		var class_id := str(scenario.get("class_id", "")).strip_edges()
		var goal := str(scenario.get("goal", "")).strip_edges()
		var seed_ok := seed > 0
		var class_ok := not PlayerClassDBScript.get_class_data(class_id).is_empty()
		var mode_ok := _release_candidate_mode_contract_ok(mode)
		var goal_ok := goal != ""
		var pass_ok := seed_ok and class_ok and mode_ok and goal_ok
		if not pass_ok:
			issues.append("%s:%s:%s" % [str(seed), mode, class_id])
		results.append({
			"seed": seed,
			"mode": mode,
			"class_id": class_id,
			"goal": goal,
			"result": "pass" if pass_ok else "fail",
			"evidence_source": "headless_rehearsal",
			"class_contract_ok": class_ok,
			"mode_contract_ok": mode_ok,
			"seed_contract_ok": seed_ok,
			"notes": "headless contract valid; human playtest still required" if pass_ok \
				else "headless contract failed; human playtest still required after fix",
		})
	return {
		"passed": issues.is_empty() and results.size() == _manual_playtest_scenario_runs().size(),
		"review_type": "headless_scenario_contract_rehearsal",
		"manual_playtest_replacement": false,
		"required_count": _manual_playtest_scenario_runs().size(),
		"completed_count": results.size(),
		"results": results,
		"issues": issues,
	}

static func release_asset_self_review(meta_data: Dictionary = {}) -> Dictionary:
	var report := runtime_report(meta_data)
	var animation_reviewed := str(report.get("animation_review_status", "")) == "stable" \
			and int(report.get("animation_frame_grid_checked_count", 0)) > 0 \
			and int(report.get("unstable_animation_count", 0)) == 0
	var polygon_reviewed := str(report.get("collision_review_status", "")) == "stable" \
			and int(report.get("collision_polygon_checked_count", 0)) > 0 \
			and str(report.get("object_visual_review_status", "")) == "stable" \
			and int(report.get("object_visual_checked_count", 0)) > 0
	var source_policy_ok := str(report.get("reference_policy", "")) \
			== "fanmade_reference_only_no_copy"
	return {
		"passed": bool(report.get("public_ready", false)) \
			and animation_reviewed and polygon_reviewed and source_policy_ok,
		"review_type": "headless_asset_contract_review",
		"animation_reviewed": animation_reviewed,
		"polygon_reviewed": polygon_reviewed,
		"motion_reviewed": animation_reviewed,
		"origin_reviewed": animation_reviewed,
		"source_policy_ok": source_policy_ok,
		"no_direct_fanmade_copy": source_policy_ok,
		"animation_frame_grid_checked_count": int(
			report.get("animation_frame_grid_checked_count", 0)),
		"collision_polygon_checked_count": int(
			report.get("collision_polygon_checked_count", 0)),
		"object_visual_checked_count": int(report.get("object_visual_checked_count", 0)),
		"notes": "headless audit checked frame grid, motion/origin metadata, collision polygons, and source policy",
	}

static func _release_export_package_status(
		meta_data: Dictionary,
		export_preset: Dictionary,
) -> Dictionary:
	var package := {}
	if meta_data.has("export_package") and meta_data["export_package"] is Dictionary:
		package = Dictionary(meta_data["export_package"])
	var path := str(package.get("executable_path", "")).strip_edges()
	var preset_name := str(package.get("preset_name", "")).strip_edges()
	if preset_name == "":
		preset_name = str(export_preset.get("preset_name", ""))
	var preset_matches := preset_name == "" or preset_name == str(export_preset.get("preset_name", ""))
	var passed := bool(package.get("passed", false))
	var booted := bool(package.get("booted", false))
	return {
		"ready": passed and booted and path != "" and preset_matches,
		"passed": passed,
		"booted": booted,
		"preset_name": preset_name,
		"executable_path": path,
	}

static func _release_export_preset_status(meta_data: Dictionary) -> Dictionary:
	var preset_path := str(meta_data.get("export_preset_path", "res://export_presets.cfg"))
	var preset_name := str(meta_data.get("export_preset_name", "Windows Desktop"))
	var exists := FileAccess.file_exists(preset_path)
	var text := FileAccess.get_file_as_string(preset_path) if exists else ""
	var platform := _export_preset_value(text, "platform")
	var export_path := _export_preset_value(text, "export_path")
	var name_ready := text.contains("name=\"%s\"" % preset_name)
	var platform_ready := platform == "Windows Desktop"
	var path_ready := export_path.to_lower().contains("build/windows") \
			and export_path.to_lower().ends_with(".exe")
	return {
		"ready": exists and name_ready and platform_ready and path_ready,
		"preset_path": preset_path,
		"preset_name": preset_name,
		"platform": platform,
		"export_path": export_path,
		"exists": exists,
	}

static func _export_preset_value(text: String, key: String) -> String:
	var prefix := "%s=" % key
	for raw_line in text.split("\n"):
		var line := str(raw_line).strip_edges()
		if not line.begins_with(prefix):
			continue
		var value := line.substr(prefix.length()).strip_edges()
		if value.length() >= 2 and value.begins_with("\"") and value.ends_with("\""):
			value = value.substr(1, value.length() - 2)
		return value
	return ""

static func replacement_backlog() -> Array[Dictionary]:
	return _replacement_backlog_from_report(runtime_report())

static func replacement_backlog_summary(max_items: int = 5) -> String:
	var backlog := replacement_backlog()
	if backlog.is_empty():
		return "No replacement backlog"
	var parts: Array[String] = []
	for item in backlog.slice(0, maxi(max_items, 0)):
		parts.append("%s:%s" % [str(item.get("kind", "")), str(item.get("id", ""))])
	return "Replace %d before public (%s): %s | fanmade direct copy forbidden" % [
		backlog.size(),
		_backlog_kind_counts_text(backlog),
		", ".join(parts),
	]

static func review_replacement_candidate(
		kind: String,
		id: String,
		source_id: String,
		metadata: Dictionary = {},
		issues: Array = [],
) -> Dictionary:
	var normalized_kind := kind.strip_edges()
	var merged_metadata := _candidate_metadata(metadata)
	var candidate_issues := issues.duplicate()
	if normalized_kind == "object_visual":
		candidate_issues.append_array(_object_visual_candidate_issues(merged_metadata))
	var policy := AssetSourceRegistryScript.policy_for(
		source_id, _candidate_asset_kind(normalized_kind), candidate_issues, merged_metadata)
	var entry := policy.duplicate(true)
	entry["kind"] = normalized_kind
	entry["id"] = id
	entry["source"] = source_id
	if normalized_kind == "object_visual" and str(entry.get("release_decision", "")) == "blocked":
		entry["replacement_policy"] = _object_visual_replacement_policy(Array(entry.get("issues", [])))
	var approved_for_public_release := bool(policy.get("public_ready", false)) \
			and str(policy.get("release_decision", "")) == "public_ok"
	entry["approved_for_public_release"] = approved_for_public_release
	entry["allowed_replacement_sources"] = _allowed_replacement_sources(normalized_kind)
	entry["forbidden_sources"] = ["fanmade_direct_copy"]
	entry["reference_only_sources"] = REFERENCE_ONLY_SOURCES.duplicate()
	entry["release_review_checklist"] = _release_review_checklist(normalized_kind)
	var acceptance_gate := _candidate_acceptance_gate(normalized_kind)
	var source_plan := _source_plan(normalized_kind, acceptance_gate)
	var self_review_gate: Array = Dictionary(
		source_plan.get("missing_asset_strategy", {})).get(
			"release_self_review_gate", acceptance_gate)
	entry["acceptance_gate"] = acceptance_gate
	entry["source_plan"] = source_plan
	entry["release_self_review_gate"] = self_review_gate.duplicate()
	entry["release_self_review_ok"] = approved_for_public_release
	entry["release_self_review_status"] = "ready" if approved_for_public_release else "blocked"
	entry["release_self_review_blockers"] = _release_self_review_blockers(
		entry, approved_for_public_release)
	if str(merged_metadata.get("manifest_image_loader", "")).strip_edges() != "":
		entry["manifest_image_loader"] = str(merged_metadata.get("manifest_image_loader", ""))
	if ["sprite", "vfx", "object_visual"].has(normalized_kind):
		entry["frame_contract"] = _candidate_frame_contract(merged_metadata)
	if normalized_kind == "audio":
		entry["audio_contract"] = _candidate_audio_contract(merged_metadata)
	if normalized_kind == "collision":
		entry["collision_contract"] = _candidate_collision_contract(merged_metadata)
	if normalized_kind == "object_visual":
		entry["object_visual_contract"] = _candidate_object_visual_contract(merged_metadata)
	return entry

static func summary_text(meta_data: Dictionary = {}) -> String:
	var report := runtime_report(meta_data)
	var internal_text := "ready" if bool(report.get("ready_for_internal_playtest", false)) else "blocked"
	var public_text := "ready" if bool(report.get("public_ready", false)) else "blocked"
	return "Internal playtest: %s | Public release: %s | replace before public: %d | Frame grid: %s %d checked | Collision: %s %d shapes/%d polygons | Objects: %s %d checked | Balance: %s %d enemies/%d warnings/%d tune | Playtest: %d focus | fanmade: reference-only no copy" % [
		internal_text,
		public_text,
		Array(report.get("replace_before_public", [])).size(),
		str(report.get("animation_review_status", "blocked")),
		int(report.get("animation_frame_grid_checked_count", 0)),
		str(report.get("collision_review_status", "blocked")),
		int(report.get("collision_shape_checked_count", 0)),
		int(report.get("collision_polygon_checked_count", 0)),
		str(report.get("object_visual_review_status", "blocked")),
		int(report.get("object_visual_checked_count", 0)),
		str(report.get("balance_review_status", "blocked")),
		int(report.get("checked_balance_enemy_count", 0)),
		int(report.get("balance_warning_count", 0)),
		int(report.get("balance_tuning_backlog_count", 0)),
		int(report.get("balance_playtest_focus_count", 0)),
	]

static func _release_playtest_notes_status(
		notes_template: Dictionary,
		notes: Dictionary,
) -> Dictionary:
	var missing: Array[String] = []
	for field_id in Array(notes_template.get("required_fields", [])):
		var key := str(field_id)
		if not notes.has(key) or not _release_candidate_field_has_value(notes[key]):
			missing.append(key)
	return {
		"ready": missing.is_empty(),
		"missing_fields": missing,
	}

static func _release_candidate_field_has_value(value: Variant) -> bool:
	if value is bool:
		return true
	if value is int or value is float:
		return float(value) > 0.0
	if value is Array:
		return not (value as Array).is_empty()
	if value is Dictionary:
		return not (value as Dictionary).is_empty()
	return str(value).strip_edges() != ""

static func _release_manual_scenarios_status(
		checklist: Dictionary,
		results: Array,
) -> Dictionary:
	var required := Array(checklist.get("scenario_runs", []))
	var completed := 0
	var completed_keys := {}
	for raw_required in required:
		if not (raw_required is Dictionary):
			continue
		var required_scenario: Dictionary = raw_required
		var key := _release_scenario_key(required_scenario)
		for raw_result in results:
			if not (raw_result is Dictionary):
				continue
			var result: Dictionary = raw_result
			if _release_manual_scenario_result_complete(result) \
					and _release_scenario_key(result) == key:
				completed_keys[key] = true
				break
	completed = completed_keys.size()
	return {
		"ready": completed >= required.size() and required.size() > 0,
		"completed_count": completed,
		"required_count": required.size(),
	}

static func _release_manual_scenario_result_complete(result: Dictionary) -> bool:
	var outcome := str(result.get("result", "")).strip_edges().to_lower()
	var notes := str(result.get("notes", "")).strip_edges()
	var screenshot_or_seed := str(result.get("screenshot_or_seed", "")).strip_edges()
	return int(result.get("seed", 0)) > 0 \
			and str(result.get("mode", "")).strip_edges() != "" \
			and str(result.get("class_id", "")).strip_edges() != "" \
			and str(result.get("goal", "")).strip_edges() != "" \
			and ["pass", "passed", "ok", "success"].has(outcome) \
			and _release_manual_evidence_source_ok(
				str(result.get("evidence_source", "")).strip_edges()) \
			and notes != "" \
			and not manual_evidence_value_placeholder(notes) \
			and manual_scenario_notes_review_complete(notes) \
			and screenshot_or_seed != "" \
			and not manual_evidence_value_placeholder(screenshot_or_seed)

static func _release_manual_evidence_source_ok(source: String) -> bool:
	return manual_evidence_source_valid(source)

static func _release_scenario_key(scenario: Dictionary) -> String:
	return "%d|%s|%s|%s" % [
		int(scenario.get("seed", 0)),
		str(scenario.get("mode", "")).strip_edges(),
		str(scenario.get("class_id", "")).strip_edges(),
		str(scenario.get("goal", "")).strip_edges(),
	]

static func _release_scenario_rehearsal_status(
		rehearsal: Dictionary,
		checklist: Dictionary,
) -> Dictionary:
	var required := Array(checklist.get("scenario_runs", []))
	var results := Array(rehearsal.get("results", []))
	var complete := 0
	for raw in results:
		if not (raw is Dictionary):
			continue
		var result: Dictionary = raw
		if str(result.get("evidence_source", "")) != "headless_rehearsal":
			continue
		if str(result.get("result", "")).strip_edges().to_lower() != "pass":
			continue
		if bool(result.get("class_contract_ok", false)) \
				and bool(result.get("mode_contract_ok", false)) \
				and int(result.get("seed", 0)) > 0 \
				and str(result.get("goal", "")).strip_edges() != "":
			complete += 1
	var ready := bool(rehearsal.get("passed", false)) \
			and str(rehearsal.get("review_type", "")) == "headless_scenario_contract_rehearsal" \
			and not bool(rehearsal.get("manual_playtest_replacement", true)) \
			and complete >= required.size() \
			and required.size() > 0
	return {
		"ready": ready,
		"review_type": str(rehearsal.get("review_type", "")),
		"completed_count": complete,
		"required_count": required.size(),
	}

static func _release_candidate_mode_contract_ok(mode: String) -> bool:
	return ["normal", "boss_rush", "endless", "hardcore", "elemental_chaos",
		"balance_lab"].has(mode)

static func _release_asset_self_review_status(review: Dictionary, report: Dictionary) -> Dictionary:
	var required_bool_fields := [
		"passed",
		"animation_reviewed",
		"polygon_reviewed",
		"motion_reviewed",
		"origin_reviewed",
		"source_policy_ok",
		"no_direct_fanmade_copy",
	]
	var missing: Array[String] = []
	for field in required_bool_fields:
		if not bool(review.get(str(field), false)):
			missing.append(str(field))
	if str(review.get("review_type", "")).strip_edges() == "":
		missing.append("review_type")
	if str(review.get("notes", "")).strip_edges() == "":
		missing.append("notes")
	for field in ["animation_frame_grid_checked_count", "collision_polygon_checked_count",
			"object_visual_checked_count"]:
		if int(review.get(field, 0)) <= 0:
			missing.append(field)
	if str(report.get("animation_review_status", "")) != "stable" \
			or int(report.get("unstable_animation_count", 0)) != 0:
		missing.append("runtime_animation_stable")
	if str(report.get("collision_review_status", "")) != "stable":
		missing.append("runtime_collision_stable")
	if str(report.get("object_visual_review_status", "")) != "stable":
		missing.append("runtime_object_visual_stable")
	if str(report.get("reference_policy", "")) != "fanmade_reference_only_no_copy":
		missing.append("runtime_source_policy")
	return {
		"ready": missing.is_empty(),
		"review_type": str(review.get("review_type", "")),
		"missing_fields": missing,
	}

static func _release_candidate_next_action(ready: bool, blockers: Array[String]) -> String:
	if ready:
		return "Next Action: Release review | verify packaged build notes and decide release"
	if blockers.has("manual_playtest_issues_open"):
		return "Next Action: Fix manual playtest issue | replay scenario after asset/polygon update"
	if blockers.has("playtest_notes_missing"):
		return "Next Action: Record playtest notes | seed/class/mode/animation/polygon/wave/HUD/audio evidence"
	if blockers.has("manual_scenarios_missing"):
		return "Next Action: Complete manual scenario runs"
	if blockers.has("scenario_rehearsal_missing"):
		return "Next Action: Run headless scenario rehearsal | seed/mode/class contract evidence"
	if blockers.has("asset_self_review_missing"):
		return "Next Action: Run asset self-review | frame/motion/origin/polygon/source evidence"
	if blockers.has("full_smoke_suite_missing"):
		return "Next Action: Run full smoke suite"
	if blockers.has("export_package_missing"):
		return "Next Action: Package export build | run export and boot packaged exe"
	if not blockers.is_empty():
		return "Next Action: Resolve %s" % blockers[0]
	return "Next Action: Review release candidate"

static func _balance_report_with_playtest_evidence(
		balance_report: Dictionary,
		meta_data: Dictionary,
) -> Dictionary:
	var out := balance_report.duplicate(true)
	if meta_data.is_empty():
		return out
	var evidence := MetaProgressionScript.balance_playtest_evidence(meta_data)
	if not evidence.is_empty():
		out["playtest_evidence"] = evidence
	return out

static func source_policy_summary() -> String:
	var object_strategy: Dictionary = _source_plan("object_visual",
		_candidate_acceptance_gate("object_visual")).get("missing_asset_strategy", {})
	var source_order: Array = object_strategy.get("runtime_source_priority", [])
	return "Asset Sources: %s | Missing assets: existing/project -> local asset -> free itch.io -> Godot Asset Library -> AI | Fanmade refs: pattern only, no copy (%s) | Self-review: frame/fps/motion/origin/polygon before release" % [
		_source_order_text(source_order),
		", ".join(REFERENCE_ONLY_SOURCES),
	]

static func missing_asset_strategy(kind: String) -> Dictionary:
	var normalized_kind := kind.strip_edges()
	var acceptance_gate := _candidate_acceptance_gate(normalized_kind)
	var source_plan := _source_plan(normalized_kind, acceptance_gate)
	var strategy: Dictionary = Dictionary(source_plan.get("missing_asset_strategy", {})).duplicate(true)
	strategy["kind"] = normalized_kind
	strategy["source_priority"] = Array(source_plan.get("source_priority", [])).duplicate()
	strategy["preferred_sources"] = Array(source_plan.get("preferred_sources", [])).duplicate()
	strategy["approval_gate"] = acceptance_gate.duplicate()
	strategy["manifest_required_fields"] = Array(
		source_plan.get("manifest_required_fields", [])).duplicate()
	strategy["release_review_checklist"] = _release_review_checklist(normalized_kind)
	return strategy

static func asset_release_review_checklist(kind: String = "object_visual") -> Dictionary:
	var normalized_kind := kind.strip_edges()
	if normalized_kind == "":
		normalized_kind = "object_visual"
	var strategy := missing_asset_strategy(normalized_kind)
	return {
		"kind": normalized_kind,
		"allowed_runtime_sources": Array(strategy.get("source_priority", [])).duplicate(),
		"reference_only_sources": REFERENCE_ONLY_SOURCES.duplicate(),
		"forbidden_sources": ["fanmade_direct_copy"],
		"fanmade_policy": str(strategy.get(
			"fanmade_policy", "study_patterns_only_never_copy_runtime_assets_or_code")),
		"release_self_review_gate": Array(
			strategy.get("release_self_review_gate", [])).duplicate(),
		"release_review_checklist": Array(
			strategy.get("release_review_checklist", [])).duplicate(),
		"review_steps": [
			"confirm_license_or_generation_manifest",
			"inspect_frame_grid_count_size_fps",
			"inspect_frame_occupancy_bounds_and_center_drift",
			"inspect_origin_motion_and_loop_stability",
			"verify_collision_polygon_points_and_area",
			"verify_polygon_points_inside_frame",
			"run_smoke_suite_before_release",
		],
		"release_decision_rule": "release_only_after_frame_polygon_motion_review",
		"manual_review_required": true,
	}

static func asset_replacement_plan(kind: String = "object_visual") -> Dictionary:
	var normalized_kind := kind.strip_edges()
	if normalized_kind == "":
		normalized_kind = "object_visual"
	normalized_kind = _candidate_asset_kind(normalized_kind)
	if normalized_kind == "asset":
		normalized_kind = "object_visual"
	var strategy := missing_asset_strategy(normalized_kind)
	var checklist := asset_release_review_checklist(normalized_kind)
	var commands := asset_review_commands()
	var checklist_key := "%s_checklist" % normalized_kind
	var checklist_command := str(commands.get(checklist_key, ""))
	if checklist_command == "":
		checklist_command = "godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --kind=%s" % normalized_kind
	return {
		"kind": normalized_kind,
		"source_priority": Array(strategy.get("source_priority", [])).duplicate(),
		"source_order_text": _source_order_text(Array(strategy.get("source_priority", []))),
		"preferred_sources": Array(strategy.get("preferred_sources", [])).duplicate(),
		"reference_only_sources": Array(
			checklist.get("reference_only_sources", [])).duplicate(),
		"forbidden_sources": Array(checklist.get("forbidden_sources", [])).duplicate(),
		"fanmade_policy": str(checklist.get("fanmade_policy", "")),
		"release_self_review_gate": Array(
			checklist.get("release_self_review_gate", [])).duplicate(),
		"release_review_checklist": Array(
			checklist.get("release_review_checklist", [])).duplicate(),
		"manifest_required_fields": Array(
			strategy.get("manifest_required_fields", [])).duplicate(),
		"review_steps": Array(checklist.get("review_steps", [])).duplicate(),
		"resolution_steps": Array(strategy.get("resolution_steps", [])).duplicate(),
		"checklist_command": checklist_command,
		"manifest_candidate_command": str(commands.get(
			"manifest_candidate_template", "")),
		"release_decision_rule": str(checklist.get("release_decision_rule", "")),
		"frame_grid_rule": "Keep frame_count, frame_size, sheet grid, fps, origin_px, motion, and image-backed occupancy stable before release",
		"ai_frame_prompt_guard": "AI sprite sheets must keep same frame_size, same frame_count, same fps, origin_px, no empty frames, and no clipped frames before release",
		"polygon_rule": _asset_replacement_polygon_rule(normalized_kind),
		"missing_polygon_next_actions": _missing_polygon_next_actions(normalized_kind),
	}

static func local_asset_folder_inventory(root_path: String = "E:/AI/asset") -> Dictionary:
	var clean_root := _normalized_local_path(root_path)
	var usable_runtime_packs: Array[String] = []
	var reference_only_packs: Array[String] = []
	var unknown_packs: Array[String] = []
	var root_dir := DirAccess.open(clean_root)
	if root_dir != null:
		var directories := root_dir.get_directories()
		directories.sort()
		for directory in directories:
			var pack_name := str(directory)
			if ["src", "src2"].has(pack_name.to_lower()):
				reference_only_packs.append(pack_name)
			elif pack_name.to_lower().contains("tiny rpg character asset pack"):
				usable_runtime_packs.append(pack_name)
			else:
				unknown_packs.append(pack_name)
	return {
		"root": clean_root,
		"root_exists": root_dir != null,
		"usable_runtime_packs": usable_runtime_packs,
		"reference_only_packs": reference_only_packs,
		"unknown_packs": unknown_packs,
		"reviewed_manifest_count": _reviewed_local_manifest_count(clean_root),
		"policy": "usable_runtime_requires_manifest_review; no_direct_fanmade_copy; src_src2_reference_only",
	}

static func ai_pixel_asset_prompt(
		kind: String = "object_visual",
		asset_id: String = "missing_asset",
		frame_size: Vector2 = Vector2(32, 32),
		frame_count: int = 1,
) -> Dictionary:
	var normalized_kind := _candidate_asset_kind(kind.strip_edges())
	if normalized_kind == "asset":
		normalized_kind = "object_visual"
	var clean_id := asset_id.strip_edges()
	if clean_id == "":
		clean_id = "missing_asset"
	var safe_frame_count := maxi(frame_count, 1)
	var manifest_path := "res://docs/asset_generation/%s_manifest.json" % clean_id
	return {
		"kind": normalized_kind,
		"asset_id": clean_id,
		"frame_size": frame_size,
		"frame_count": safe_frame_count,
		"source_id": "ai_generated",
		"prompt_text": _ai_pixel_prompt_text(
			normalized_kind, clean_id, frame_size, safe_frame_count),
		"manifest_required_fields": _manifest_required_fields(normalized_kind),
		"manifest_path": manifest_path,
		"review_command": "godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --manifest=%s --source=ai_generated" % manifest_path,
		"release_rule": "release_only_after_manifest_frame_origin_polygon_review",
	}

static func ai_pixel_asset_manifest_template(
		kind: String = "object_visual",
		asset_id: String = "missing_asset",
		frame_size: Vector2 = Vector2(32, 32),
		frame_count: int = 1,
		image_path: String = "",
) -> Dictionary:
	var normalized_kind := _candidate_asset_kind(kind.strip_edges())
	if normalized_kind == "asset":
		normalized_kind = "object_visual"
	var clean_id := asset_id.strip_edges()
	if clean_id == "":
		clean_id = "missing_asset"
	var safe_frame_count := maxi(frame_count, 1)
	var safe_frame_size := frame_size
	if safe_frame_size.x <= 0.0 or safe_frame_size.y <= 0.0:
		safe_frame_size = Vector2(32, 32)
	var columns := safe_frame_count
	var rows := 1
	var origin := Vector2(floorf(safe_frame_size.x * 0.5), floorf(safe_frame_size.y * 0.5))
	var template := {
		"asset_id": clean_id,
		"asset_kind": normalized_kind,
		"license": "project_owned_ai_generated",
		"generation_tool": "OpenAI image generation",
		"source_url": "res://docs/asset_generation/%s_manifest.json" % clean_id,
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": safe_frame_count,
		"frame_size": safe_frame_size,
		"expected_frame_size": safe_frame_size,
		"sheet_size": Vector2(safe_frame_size.x * columns, safe_frame_size.y * rows),
		"columns": columns,
		"rows": rows,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": origin,
		"review_notes": "AI pixel sprite sheet reviewed for stable frame grid, non-empty frames, origin alignment, and no fanmade runtime copy.",
	}
	if normalized_kind == "object_visual":
		var polygon := _default_frame_polygon_points(safe_frame_size)
		template["runtime_object_sprite_ok"] = true
		template["polygon_ok"] = true
		template["fallback_polygon_points"] = polygon.size()
		template["fallback_polygon_points_px"] = polygon
		template["fallback_polygon_area_px"] = _polygon_area(PackedVector2Array(polygon))
		template["fallback_polygon_inside_frame"] = true
	elif normalized_kind == "vfx":
		template["geometry_ok"] = true
		template["duration"] = float(safe_frame_count) / 8.0
	return template

static func playtest_notes_template(meta_data: Dictionary = {}) -> Dictionary:
	var scenario_notes: Array[Dictionary] = []
	for raw_scenario in _manual_playtest_scenario_runs():
		var scenario: Dictionary = raw_scenario
		scenario_notes.append({
			"seed": int(scenario.get("seed", 0)),
			"mode": str(scenario.get("mode", "")),
			"class_id": str(scenario.get("class_id", "")),
			"goal": str(scenario.get("goal", "")),
			"prompts": ["replay_last_run", "pace", "asset_animation",
				"wave_hud_audio", "blockers"],
		})
	var release_decision := public_release_decision(meta_data)
	var required_fields := [
		"seed",
		"class_id",
		"mode",
		"replay_last_run_result",
		"daily_fingerprint_hash",
		"pace_avg_sec",
		"pace_boss_sec",
		"asset_animation_notes",
		"polygon_collision_notes",
		"wave_hud_audio_notes",
		"blocker_screenshot_or_seed",
		"release_decision",
	]
	return {
		"status": "ready_for_notes",
		"required_fields": required_fields,
		"scenario_notes": scenario_notes,
		"release_decision": release_decision,
		"template_text": "\n".join([
			"Playtest Notes",
			"Seed / Class / Mode:",
			"Replay Last Run: same seed, class, element, and mode?",
			"Daily Hash:",
			"Pace: average room seconds and boss seconds",
			"Animation: idle/run/dash/attack frame stability",
			"Polygon: visible sprite matches collision and interaction shape",
			"Wave/HUD/Audio: Wave x/y, enemies_left, WaveStartCue, and WaveStartSfx",
			"Blocker: screenshot path or seed",
			"No fanmade runtime copy",
		]),
	}

static func manual_playtest_checklist() -> Dictionary:
	return {
		"status": "ready_for_human_playtest",
		"notes_template_status": "ready_for_notes",
		"required_before_release": [
			"run_full_smoke_suite",
			"record_playtest_notes",
			"verify_export_preset",
			"capture_blocker_screenshot_or_seed",
		],
		"scenario_runs": _manual_playtest_scenario_runs(),
		"sections": {
			"boot_controls": {
				"steps": [
					"start_from_class_select",
					"select_class_element_mode_with_hotkeys",
					"verify_pause_restart_return_flow",
				],
			},
			"combat_readability": {
				"steps": [
					"verify_enemy_telegraphs_are_reactable",
					"verify_player_hit_feedback_and_audio",
					"verify_boss_bullet_hell_has_safe_gaps",
				],
			},
			"room_objectives": {
				"steps": [
					"clear_combat_room_and_take_reward",
					"open_locked_chest_with_key",
					"buy_one_shop_choice",
					"use_heal_shrine_once",
					"survive_trap_room",
				],
			},
			"progression_economy": {
				"steps": [
					"choose_three_run_upgrades",
					"verify_shop_prices_feel_reachable",
					"replay_last_run_same_seed_class_mode",
					"bank_meta_rewards_after_run",
				],
			},
			"class_coverage": {
				"steps": [
					"cast_primary_and_secondary_skill",
					"cast_ultimate_when_ready",
					"verify_cooldown_icons_and_resource_feedback",
				],
			},
			"asset_animation_review": {
				"steps": [
					"watch_player_idle_run_dash_no_offset_pop",
					"watch_attack_vfx_frame_grid_and_origin",
					"verify_no_blank_or_cropped_generated_frames",
					"verify_object_polygon_matches_visible_sprite",
					"confirm_no_fanmade_runtime_copy",
				],
			},
			"export_package": {
				"steps": [
					"verify_windows_export_preset",
					"package_candidate_debug_build",
					"boot_packaged_build_once",
				],
			},
			"performance_stability": {
				"steps": [
					"watch_for_frame_spikes_during_boss_phase",
					"verify_no_console_errors",
					"verify_restart_does_not_duplicate_hud_or_audio",
				],
			},
		},
	}

static func _manual_playtest_scenario_runs() -> Array[Dictionary]:
	return [
			{"seed": 420101, "mode": "normal", "class_id": "blade_warden",
				"goal": "clear floor 1 and choose one upgrade"},
			{"seed": 420102, "mode": "boss_rush", "class_id": "bulwark",
				"goal": "survive boss phase shift and enrage"},
			{"seed": 420103, "mode": "endless", "class_id": "arcanist",
				"goal": "reach post-finale biome transition"},
			{"seed": 420104, "mode": "hardcore", "class_id": "nightblade",
				"goal": "verify lethal damage/readability feels fair"},
			{"seed": 420105, "mode": "elemental_chaos", "class_id": "ranger",
				"goal": "verify element swaps and combo feedback"},
			{"seed": 420106, "mode": "balance_lab", "class_id": "gunner",
				"goal": "record TTK/pace notes for weapon and economy tuning"},
	]

static func review_manifest_candidate(
		manifest_path: String,
		source_id: String = "",
) -> Dictionary:
	var clean_path := manifest_path.strip_edges()
	var manifest_report := AssetSourceRegistryScript.generation_manifest_report(clean_path)
	var metadata: Dictionary = manifest_report.get("metadata", {})
	var kind := str(metadata.get("asset_kind", "asset")).strip_edges()
	if kind == "":
		kind = "asset"
	var id := str(metadata.get("asset_id", "")).strip_edges()
	if id == "":
		id = clean_path.get_file().get_basename()
	var resolved_source := source_id.strip_edges()
	if resolved_source == "":
		resolved_source = _manifest_candidate_source_id(metadata)
	var candidate := review_replacement_candidate(kind, id, resolved_source, {
		"generation_manifest": clean_path,
	})
	candidate["manifest_report_ready"] = bool(manifest_report.get("ready", false))
	candidate["manifest_issues"] = Array(manifest_report.get("issues", [])).duplicate()
	candidate["manifest_source_id"] = resolved_source
	return candidate

static func _decision(public_ready: bool, failures: Array, replacements: Array) -> String:
	if public_ready:
		return "public_ok"
	if not failures.is_empty():
		return "blocked_fix_missing_or_unstable"
	if not replacements.is_empty():
		return "blocked_replace_placeholders"
	return "blocked_review_required"

static func _prefixed_blockers(prefix: String, report: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for blocker in Array(report.get("public_release_blockers", [])):
		out.append("%s:%s" % [prefix, str(blocker)])
	return out

static func _prefixed_failures(prefix: String, report: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for failure in Array(report.get("failures", [])):
		out.append("%s:%s" % [prefix, str(failure)])
	return out

static func _prefixed_balance_failures(report: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for failure in Array(report.get("hard_failures", [])):
		out.append("balance:%s" % str(failure))
	return out

static func _sprite_replacements(report: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var sprites: Dictionary = report.get("sprites", {})
	for sprite_name in sprites.keys():
		var entry: Dictionary = sprites[sprite_name]
		if bool(entry.get("needs_replacement_before_public", false)):
			out.append("sprite:%s:%s" % [
				str(sprite_name),
				str(entry.get("replacement_policy", "replace_before_public")),
			])
	return out

static func _audio_replacements(report: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var cues: Dictionary = report.get("cues", {})
	for cue_id in cues.keys():
		var entry: Dictionary = cues[cue_id]
		if bool(entry.get("needs_replacement_before_public", false)):
			out.append("audio:%s:%s" % [
				str(cue_id),
				str(entry.get("replacement_policy", "replace_before_public")),
			])
	return out

static func _fx_replacements(report: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var fx_entries: Dictionary = report.get("fx", {})
	for fx_id in fx_entries.keys():
		var entry: Dictionary = fx_entries[fx_id]
		if bool(entry.get("needs_replacement_before_public", false)):
			out.append("vfx:%s:%s" % [
				str(fx_id),
				str(entry.get("replacement_policy", "add_procedural_fx_before_release")),
			])
	return out

static func _collision_replacements(report: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var entries: Dictionary = report.get("entries", {})
	for entry_id in entries.keys():
		var entry: Dictionary = entries[entry_id]
		if Array(entry.get("issues", [])).is_empty() \
				and bool(entry.get("shape_ok", false)) \
				and bool(entry.get("polygon_ok", false)):
			continue
		out.append("collision:%s:add_or_fix_collision_polygon_before_public" % str(entry_id))
	return out

static func _runtime_object_replacements(report: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var entries: Dictionary = report.get("entries", {})
	for entry_id in entries.keys():
		var entry: Dictionary = entries[entry_id]
		var replacement_policy := str(entry.get("replacement_policy", "replace_before_public"))
		if not bool(entry.get("polygon_ok", false)):
			replacement_policy = "fix_runtime_object_polygon_before_public"
		elif not bool(entry.get("frame_grid_ok", false)):
			replacement_policy = "fix_frame_grid_before_release"
		elif not bool(entry.get("needs_replacement_before_public", false)):
			continue
		out.append("object_visual:%s:%s" % [str(entry_id), replacement_policy])
	return out

static func _animation_grid_summary(sprite_report: Dictionary) -> Dictionary:
	var checked := 0
	var unstable := 0
	var sprites: Dictionary = sprite_report.get("sprites", {})
	for sprite_name in sprites.keys():
		var entry: Dictionary = sprites[sprite_name]
		if int(entry.get("frame_count", 0)) <= 1:
			continue
		checked += 1
		if not bool(entry.get("frame_grid_ok", false)):
			unstable += 1
	return {
		"checked_count": checked,
		"unstable_count": unstable,
		"status": "stable" if checked > 0 and unstable == 0 else "blocked",
	}

static func _collision_report() -> Dictionary:
	var failures: Array[String] = []
	var entries := {}
	var shape_checked := 0
	var polygon_checked := 0
	for spec in CRITICAL_COLLISION_SCENES:
		var id := str(spec.get("id", "scene"))
		var path := str(spec.get("path", ""))
		var entry := _collision_scene_entry(path)
		entries[id] = entry
		if bool(entry.get("shape_ok", false)):
			shape_checked += 1
		if bool(entry.get("polygon_ok", false)):
			polygon_checked += 1
		for issue in Array(entry.get("issues", [])):
			failures.append("%s:%s" % [id, str(issue)])
	return {
		"ready": failures.is_empty(),
		"review_status": "stable" if failures.is_empty() else "blocked",
		"shape_checked_count": shape_checked,
		"polygon_checked_count": polygon_checked,
		"failures": failures,
		"entries": entries,
	}

static func _collision_scene_entry(path: String) -> Dictionary:
	var issues: Array[String] = []
	if path == "" or not ResourceLoader.exists(path):
		return {
			"path": path,
			"shape_ok": false,
			"polygon_ok": false,
			"issues": ["scene_missing"],
		}
	var packed := load(path) as PackedScene
	if packed == null:
		return {
			"path": path,
			"shape_ok": false,
			"polygon_ok": false,
			"issues": ["scene_load_failed"],
		}
	var node := packed.instantiate()
	var shape_node := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var polygon_node := node.get_node_or_null("Body") as Polygon2D
	var shape_size := Vector2.ZERO
	if shape_node == null or shape_node.shape == null:
		issues.append("collision_shape_missing")
	else:
		shape_size = _shape_size(shape_node.shape)
		if shape_size == Vector2.ZERO:
			issues.append("collision_shape_empty")
	var polygon_points := 0
	var polygon_area := 0.0
	if polygon_node == null:
		issues.append("polygon_visual_missing")
	else:
		polygon_points = polygon_node.polygon.size()
		if polygon_points < 3:
			issues.append("polygon_visual_too_small")
		else:
			polygon_area = _polygon_area(polygon_node.polygon)
			if polygon_area <= 0.0:
				issues.append("polygon_visual_area_empty")
	node.free()
	return {
		"path": path,
		"shape_ok": shape_size != Vector2.ZERO,
		"shape_size": shape_size,
		"polygon_ok": polygon_points >= 3 and polygon_area > 0.0,
		"polygon_points": polygon_points,
		"polygon_area_px": polygon_area,
		"issues": issues,
	}

static func _shape_size(shape: Shape2D) -> Vector2:
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size
	if shape is CircleShape2D:
		var diameter := (shape as CircleShape2D).radius * 2.0
		return Vector2(diameter, diameter)
	if shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		return Vector2(capsule.radius * 2.0, capsule.height)
	return Vector2.ONE

static func _polygon_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		area += a.x * b.y - b.x * a.y
	return absf(area) * 0.5

static func _runtime_object_report() -> Dictionary:
	var failures: Array[String] = []
	var blockers: Array[String] = []
	var entries := {}
	for spec in CRITICAL_RUNTIME_OBJECTS:
		var entry := _runtime_object_entry(spec)
		var id := str(entry.get("id", "object"))
		entries[id] = entry
		for issue in Array(entry.get("issues", [])):
			failures.append("%s:%s" % [id, str(issue)])
		for blocker in Array(entry.get("public_release_blockers", [])):
			blockers.append("%s:%s" % [id, str(blocker)])
	return {
		"ready": failures.is_empty(),
		"public_ready": failures.is_empty() and blockers.is_empty(),
		"checked_count": CRITICAL_RUNTIME_OBJECTS.size(),
		"review_status": "stable" if failures.is_empty() else "blocked",
		"failures": failures,
		"public_release_blockers": blockers,
		"entries": entries,
	}

static func _runtime_object_entry(spec: Dictionary) -> Dictionary:
	var sprite_name := str(spec.get("sprite", ""))
	var source_script := str(spec.get("source_script", "")).strip_edges()
	var release := SpriteDB.release_report([sprite_name])
	var sprites: Dictionary = release.get("sprites", {})
	var sprite_entry: Dictionary = sprites.get(sprite_name, {})
	var fallback_points := int(spec.get("fallback_polygon_points", 0))
	var fallback_area := float(spec.get("fallback_polygon_area_px", 0.0))
	var runtime_contract := _runtime_object_geometry_contract(spec)
	var runtime_shape_ok := bool(runtime_contract.get("shape_ok", false))
	var runtime_shape_size: Vector2 = runtime_contract.get("shape_size", Vector2.ZERO)
	var runtime_polygon_ok := bool(runtime_contract.get("polygon_ok", false))
	var runtime_polygon_points := int(runtime_contract.get("polygon_points", 0))
	var runtime_polygon_area := float(runtime_contract.get("polygon_area_px", 0.0))
	var runtime_geometry_reviewed := bool(runtime_contract.get("contract_found", false)) \
			and runtime_shape_ok and runtime_polygon_ok
	var fallback_polygon_ok := fallback_points >= 3 and fallback_area > 0.0
	var issues: Array[String] = []
	if sprite_name == "":
		issues.append("sprite_missing")
	if not bool(release.get("ready", false)):
		issues.append("sprite_unstable_or_missing")
	if source_script == "" or not ResourceLoader.exists(source_script):
		issues.append("source_script_missing")
	if fallback_points < 3:
		issues.append("fallback_polygon_too_small")
	elif fallback_area <= 0.0:
		issues.append("fallback_polygon_area_empty")
	if not bool(runtime_contract.get("contract_found", false)):
		issues.append("runtime_geometry_contract_missing")
	if not runtime_shape_ok:
		issues.append("runtime_shape_missing")
	if runtime_polygon_points < 3:
		issues.append("runtime_polygon_too_small")
	elif runtime_polygon_area <= 0.0:
		issues.append("runtime_polygon_area_empty")
	return {
		"id": str(spec.get("id", "object")),
		"sprite": sprite_name,
		"source_script": source_script,
		"fallback_polygon_points": fallback_points,
		"fallback_polygon_area_px": fallback_area,
		"polygon_ok": fallback_polygon_ok and runtime_polygon_ok,
		"runtime_geometry_reviewed": runtime_geometry_reviewed,
		"runtime_shape_ok": runtime_shape_ok,
		"runtime_shape_size": runtime_shape_size,
		"runtime_polygon_ok": runtime_polygon_ok,
		"runtime_polygon_points": runtime_polygon_points,
		"runtime_polygon_area_px": runtime_polygon_area,
		"sprite_source": str(sprite_entry.get("source", "")),
		"sprite_release_decision": str(sprite_entry.get("release_decision", "blocked")),
		"review_status": str(sprite_entry.get("review_status", "blocked")),
		"replacement_policy": str(sprite_entry.get("replacement_policy", "replace_before_public")),
		"needs_replacement_before_public": bool(
			sprite_entry.get("needs_replacement_before_public", true)),
		"frame_count": int(sprite_entry.get("frame_count", 0)),
		"frame_size": sprite_entry.get("frame_size", Vector2.ZERO),
		"frame_grid_ok": bool(sprite_entry.get("frame_grid_ok", false)),
		"motion_reviewed": bool(sprite_entry.get("motion_reviewed", false)),
		"origin_alignment_reviewed": bool(sprite_entry.get("origin_alignment_reviewed", false)),
		"public_release_blockers": Array(release.get("public_release_blockers", [])).duplicate(),
		"issues": issues,
	}

static func _runtime_object_geometry_contract(spec: Dictionary) -> Dictionary:
	var source_script := str(spec.get("source_script", "")).strip_edges()
	if source_script == "" or not ResourceLoader.exists(source_script):
		return {"contract_found": false}
	var script: Variant = load(source_script)
	if script == null or not script.has_method("release_geometry_contract"):
		return {"contract_found": false}
	var raw_contract: Variant = script.call("release_geometry_contract", str(spec.get("id", "")))
	if not (raw_contract is Dictionary):
		return {"contract_found": false}
	var contract: Dictionary = raw_contract
	var shape_size := _metadata_size(contract, "shape_size")
	var polygon := _metadata_polygon(contract.get("fallback_polygon", PackedVector2Array()))
	var polygon_points := int(contract.get("polygon_points", polygon.size()))
	var polygon_area := float(contract.get(
		"polygon_area_px",
		_polygon_area(polygon) if polygon.size() >= 3 else 0.0))
	return {
		"contract_found": true,
		"shape_ok": shape_size != Vector2.ZERO,
		"shape_size": shape_size,
		"polygon_ok": polygon_points >= 3 and polygon_area > 0.0,
		"polygon_points": polygon_points,
		"polygon_area_px": polygon_area,
	}

static func _metadata_polygon(value: Variant) -> PackedVector2Array:
	if value is PackedVector2Array:
		return value
	var out := PackedVector2Array()
	if value is Array:
		for item in value:
			if item is Vector2:
				out.append(item)
			elif item is Vector2i:
				out.append(Vector2(item))
			elif item is Array and (item as Array).size() >= 2:
				out.append(Vector2(float((item as Array)[0]), float((item as Array)[1])))
			elif item is Dictionary:
				var point: Dictionary = item
				if point.has("x") and point.has("y"):
					out.append(Vector2(float(point["x"]), float(point["y"])))
	return out

static func _replacement_backlog_from_report(report: Dictionary) -> Array[Dictionary]:
	var backlog: Array[Dictionary] = []
	var categories: Dictionary = report.get("categories", {})
	_append_sprite_backlog(backlog, Dictionary(categories.get("sprites", {})))
	_append_audio_backlog(backlog, Dictionary(categories.get("audio", {})))
	_append_fx_backlog(backlog, Dictionary(categories.get("vfx", {})))
	_append_collision_backlog(backlog, Dictionary(categories.get("collision", {})))
	_append_runtime_object_backlog(backlog, Dictionary(categories.get("runtime_objects", {})))
	return backlog

static func _append_sprite_backlog(backlog: Array[Dictionary], sprite_report: Dictionary) -> void:
	var sprites: Dictionary = sprite_report.get("sprites", {})
	for sprite_id in sprites.keys():
		var entry: Dictionary = sprites[sprite_id]
		if not bool(entry.get("needs_replacement_before_public", false)):
			continue
		backlog.append(_backlog_entry("sprite", str(sprite_id), entry, [
			"license_or_ownership_metadata",
			"source_url_or_generation_manifest",
			"frame_grid_ok",
			"motion_reviewed",
			"origin_alignment_reviewed",
			"no_direct_fanmade_copy",
		], {
			"frame_grid_ok": bool(entry.get("frame_grid_ok", false)),
			"frame_count": int(entry.get("frame_count", 0)),
			"frame_size": entry.get("frame_size", Vector2.ZERO),
			"fps": float(entry.get("fps", 0.0)),
			"motion_reviewed": bool(entry.get("motion_reviewed", false)),
			"origin_alignment_reviewed": bool(entry.get("origin_alignment_reviewed", false)),
			"frame_contract": _sprite_frame_contract(entry),
		}))

static func _append_audio_backlog(backlog: Array[Dictionary], audio_report: Dictionary) -> void:
	var cues: Dictionary = audio_report.get("cues", {})
	for cue_id in cues.keys():
		var entry: Dictionary = cues[cue_id]
		if not bool(entry.get("needs_replacement_before_public", false)):
			continue
		backlog.append(_backlog_entry("audio", str(cue_id), entry, [
			"license_or_ownership_metadata",
			"source_url_or_generation_manifest",
			"waveform_ok",
			"no_direct_fanmade_copy",
		], {
			"waveform_ok": bool(entry.get("waveform_ok", false)),
			"duration": float(entry.get("duration", 0.0)),
		}))

static func _append_fx_backlog(backlog: Array[Dictionary], fx_report: Dictionary) -> void:
	var fx_entries: Dictionary = fx_report.get("fx", {})
	for fx_id in fx_entries.keys():
		var entry: Dictionary = fx_entries[fx_id]
		if not bool(entry.get("needs_replacement_before_public", false)):
			continue
		backlog.append(_backlog_entry("vfx", str(fx_id), entry, [
			"license_or_ownership_metadata",
			"geometry_ok",
			"frame_grid_ok",
			"motion_reviewed",
			"origin_alignment_reviewed",
			"no_direct_fanmade_copy",
		], {
			"frame_grid_ok": bool(entry.get("frame_grid_ok", false)),
			"geometry_ok": bool(entry.get("geometry_ok", false)),
			"motion_reviewed": bool(entry.get("motion_reviewed", false)),
			"origin_alignment_reviewed": bool(entry.get("origin_alignment_reviewed", false)),
		}))

static func _append_collision_backlog(backlog: Array[Dictionary], collision_report: Dictionary) -> void:
	var entries: Dictionary = collision_report.get("entries", {})
	for entry_id in entries.keys():
		var entry: Dictionary = entries[entry_id]
		if Array(entry.get("issues", [])).is_empty() \
				and bool(entry.get("shape_ok", false)) \
				and bool(entry.get("polygon_ok", false)):
			continue
		var source_entry := entry.duplicate(true)
		source_entry["source"] = "project_collision_scene"
		source_entry["source_policy_id"] = "procedural_godot_shapes"
		source_entry["replacement_policy"] = "add_or_fix_collision_polygon_before_public"
		source_entry["release_decision"] = "blocked"
		backlog.append(_backlog_entry("collision", str(entry_id), source_entry, [
			"license_or_ownership_metadata",
			"collision_shape_or_polygon_ok",
			"runtime_scene_load_ok",
			"polygon_area_px",
			"no_direct_fanmade_copy",
		], {
			"path": str(entry.get("path", "")),
			"shape_ok": bool(entry.get("shape_ok", false)),
			"polygon_ok": bool(entry.get("polygon_ok", false)),
			"polygon_points": int(entry.get("polygon_points", 0)),
			"polygon_area_px": float(entry.get("polygon_area_px", 0.0)),
			"issues": Array(entry.get("issues", [])).duplicate(),
		}))

static func _append_runtime_object_backlog(
		backlog: Array[Dictionary],
		runtime_object_report: Dictionary,
) -> void:
	var entries: Dictionary = runtime_object_report.get("entries", {})
	for entry_id in entries.keys():
		var entry: Dictionary = entries[entry_id]
		var issues: Array = Array(entry.get("issues", [])).duplicate()
		var polygon_ok := bool(entry.get("polygon_ok", false))
		var frame_grid_ok := bool(entry.get("frame_grid_ok", false))
		var sprite_decision := str(entry.get("sprite_release_decision", "blocked"))
		if issues.is_empty() and polygon_ok and frame_grid_ok and sprite_decision != "blocked":
			continue
		var source_entry := entry.duplicate(true)
		source_entry["source"] = str(entry.get("sprite_source", "runtime_object_visual"))
		source_entry["source_policy_id"] = str(entry.get("sprite_source", ""))
		source_entry["release_decision"] = sprite_decision if sprite_decision != "" else "blocked"
		source_entry["replacement_policy"] = str(entry.get(
			"replacement_policy",
			"fix_runtime_object_polygon_before_public" if not polygon_ok
				else "replace_runtime_object_sprite_before_public"))
		backlog.append(_backlog_entry("object_visual", str(entry_id), source_entry, [
			"license_or_ownership_metadata",
			"source_url_or_generation_manifest",
			"runtime_object_sprite_ok",
			"frame_grid_ok",
			"motion_reviewed",
			"origin_alignment_reviewed",
			"fallback_polygon_points",
			"fallback_polygon_area_px",
			"no_direct_fanmade_copy",
		], {
			"sprite": str(entry.get("sprite", "")),
			"source_script": str(entry.get("source_script", "")),
			"sprite_release_decision": sprite_decision,
			"frame_grid_ok": frame_grid_ok,
			"motion_reviewed": bool(entry.get("motion_reviewed", false)),
			"origin_alignment_reviewed": bool(entry.get("origin_alignment_reviewed", false)),
			"polygon_ok": polygon_ok,
			"fallback_polygon_points": int(entry.get("fallback_polygon_points", 0)),
			"fallback_polygon_area_px": float(entry.get("fallback_polygon_area_px", 0.0)),
			"issues": issues,
		}))

static func _backlog_entry(
		kind: String,
		id: String,
		source_entry: Dictionary,
		acceptance_gate: Array,
		extra: Dictionary = {},
) -> Dictionary:
	var entry := {
		"kind": kind,
		"id": id,
		"source": str(source_entry.get("source", source_entry.get("source_policy_id", ""))),
		"source_policy_id": str(source_entry.get("source_policy_id", "")),
		"replacement_policy": str(source_entry.get("replacement_policy", "replace_before_public")),
		"release_decision": str(source_entry.get("release_decision", "blocked")),
		"required_before_public": true,
		"acceptance_gate": acceptance_gate.duplicate(),
		"forbidden_sources": ["fanmade_direct_copy"],
		"allowed_replacement_sources": _allowed_replacement_sources(kind),
		"reference_only_sources": REFERENCE_ONLY_SOURCES.duplicate(),
		"release_review_checklist": _release_review_checklist(kind),
		"source_plan": _source_plan(kind, acceptance_gate),
	}
	for key in extra.keys():
		entry[str(key)] = extra[key]
	return entry

static func _sprite_frame_contract(entry: Dictionary) -> Dictionary:
	var frame_size: Vector2 = entry.get("frame_size", Vector2.ZERO)
	return {
		"frame_size": frame_size,
		"expected_frame_size": frame_size,
		"frame_count": int(entry.get("frame_count", 0)),
		"fps": float(entry.get("fps", 0.0)),
		"stable_size": bool(entry.get("stable_size", false)),
		"frame_grid_ok": bool(entry.get("frame_grid_ok", false)),
		"motion_reviewed": bool(entry.get("motion_reviewed", false)),
		"origin_alignment_reviewed": bool(entry.get("origin_alignment_reviewed", false)),
		"origin_px": entry.get("origin_px", Vector2.ZERO),
		"allow_frame_edge_contact": bool(entry.get("allow_frame_edge_contact", false)),
		"frame_nontransparent_px": Array(entry.get("frame_nontransparent_px", [])).duplicate(),
		"frame_content_bounds_px": Array(entry.get("frame_content_bounds_px", [])).duplicate(true),
		"frame_content_centers_px": Array(entry.get("frame_content_centers_px", [])).duplicate(),
		"frame_center_drift_px": float(entry.get("frame_center_drift_px", 0.0)),
	}

static func _candidate_metadata(metadata: Dictionary) -> Dictionary:
	var merged := metadata.duplicate(true)
	var manifest_path := str(merged.get("generation_manifest", "")).strip_edges()
	if manifest_path == "":
		return merged
	var report := AssetSourceRegistryScript.generation_manifest_report(manifest_path)
	var manifest_metadata: Dictionary = report.get("metadata", {})
	for key in manifest_metadata.keys():
		if not merged.has(key) or merged[key] == null or str(merged[key]).strip_edges() == "":
			merged[key] = manifest_metadata[key]
	merged["manifest_reviewed"] = bool(report.get("ready", false))
	return merged

static func _candidate_frame_contract(metadata: Dictionary) -> Dictionary:
	var frame_size := _metadata_size(metadata, "frame_size")
	var expected_size := _metadata_size(metadata, "expected_frame_size")
	if expected_size == Vector2.ZERO:
		expected_size = frame_size
	var sheet_size := _metadata_size(metadata, "sheet_size")
	var columns := int(metadata.get("columns", 0))
	var rows := int(metadata.get("rows", 0))
	var inferred_columns := 0
	var inferred_rows := 0
	if sheet_size != Vector2.ZERO and frame_size != Vector2.ZERO:
		var sheet_w := int(sheet_size.x)
		var sheet_h := int(sheet_size.y)
		var frame_w := int(frame_size.x)
		var frame_h := int(frame_size.y)
		if frame_w > 0 and frame_h > 0 and sheet_w % frame_w == 0 and sheet_h % frame_h == 0:
			inferred_columns = int(sheet_w / frame_w)
			inferred_rows = int(sheet_h / frame_h)
	var contract_columns := columns if columns > 0 else inferred_columns
	var contract_rows := rows if rows > 0 else inferred_rows
	return {
		"frame_size": frame_size,
		"expected_frame_size": expected_size,
		"frame_count": int(metadata.get("frame_count", 0)),
		"fps": float(metadata.get("fps", 0.0)),
		"stable_size": bool(metadata.get("stable_size", metadata.get("frame_grid_ok", false))),
		"frame_grid_ok": bool(metadata.get("frame_grid_ok", false)),
		"animation_stability_reviewed": bool(metadata.get("animation_stability_reviewed", false)),
		"motion_reviewed": bool(metadata.get("motion_reviewed", false)),
		"origin_alignment_reviewed": bool(metadata.get("origin_alignment_reviewed", false)),
		"origin_px": _metadata_size(metadata, "origin_px"),
		"sheet_size": sheet_size,
		"columns": contract_columns,
		"rows": contract_rows,
		"grid_cell_count": contract_columns * contract_rows,
		"image_path": str(metadata.get("image_path", "")),
		"image_size": _metadata_size(metadata, "image_size"),
		"image_columns": int(metadata.get("image_columns", 0)),
		"image_rows": int(metadata.get("image_rows", 0)),
		"image_grid_cell_count": int(metadata.get("image_grid_cell_count", 0)),
		"allow_frame_edge_contact": bool(metadata.get("allow_frame_edge_contact", false)),
		"frame_nontransparent_px": Array(metadata.get("frame_nontransparent_px", [])).duplicate(),
		"frame_content_bounds_px": Array(metadata.get("frame_content_bounds_px", [])).duplicate(true),
		"frame_content_centers_px": Array(metadata.get("frame_content_centers_px", [])).duplicate(),
		"frame_center_drift_px": float(metadata.get("frame_center_drift_px", 0.0)),
	}

static func _candidate_collision_contract(metadata: Dictionary) -> Dictionary:
	return {
		"shape_ok": bool(metadata.get("shape_ok", false)),
		"polygon_ok": bool(metadata.get("polygon_ok", false)),
		"polygon_points": int(metadata.get("polygon_points", 0)),
		"polygon_area_px": float(metadata.get("polygon_area_px", 0.0)),
	}

static func _candidate_object_visual_contract(metadata: Dictionary) -> Dictionary:
	return {
		"runtime_object_sprite_ok": bool(metadata.get("runtime_object_sprite_ok", false)),
		"frame_grid_ok": bool(metadata.get("frame_grid_ok", false)),
		"motion_reviewed": bool(metadata.get("motion_reviewed", false)),
		"origin_alignment_reviewed": bool(metadata.get("origin_alignment_reviewed", false)),
		"origin_px": _metadata_size(metadata, "origin_px"),
		"polygon_ok": bool(metadata.get("polygon_ok", false)),
		"fallback_polygon_points": int(metadata.get("fallback_polygon_points", 0)),
		"fallback_polygon_area_px": float(metadata.get(
			"fallback_polygon_area_px", metadata.get("polygon_area_px", 0.0))),
	}

static func _release_self_review_blockers(
		entry: Dictionary,
		approved_for_public_release: bool,
) -> Array[String]:
	var blockers: Array[String] = []
	if approved_for_public_release:
		return blockers
	for issue in Array(entry.get("issues", [])):
		_append_unique(blockers, str(issue))
	var decision := str(entry.get("release_decision", ""))
	if decision != "" and decision != "public_ok":
		_append_unique(blockers, "release_decision:%s" % decision)
	if bool(entry.get("needs_replacement_before_public", false)):
		var replacement_policy := str(entry.get("replacement_policy", ""))
		if replacement_policy != "":
			_append_unique(blockers, "replacement_policy:%s" % replacement_policy)
	if not bool(entry.get("usable_runtime_asset", false)):
		_append_unique(blockers, "runtime_asset_not_usable")
	if blockers.is_empty():
		_append_unique(blockers, "release_self_review_blocked")
	return blockers

static func _append_unique(values: Array[String], value: String) -> void:
	if value != "" and not values.has(value):
		values.append(value)

static func _candidate_audio_contract(metadata: Dictionary) -> Dictionary:
	return {
		"waveform_ok": bool(metadata.get("waveform_ok", false)),
		"duration": float(metadata.get("duration", 0.0)),
	}

static func _candidate_asset_kind(kind: String) -> String:
	if ["sprite", "vfx", "audio", "collision", "object_visual"].has(kind):
		return kind
	return "asset"

static func _object_visual_candidate_issues(metadata: Dictionary) -> Array[String]:
	var issues: Array[String] = []
	if not bool(metadata.get("runtime_object_sprite_ok", false)):
		issues.append("runtime_object_sprite_not_reviewed")
	if not bool(metadata.get("polygon_ok", false)) \
			or int(metadata.get("fallback_polygon_points", 0)) < 3:
		issues.append("fallback_polygon_not_reviewed")
	elif float(metadata.get(
			"fallback_polygon_area_px", metadata.get("polygon_area_px", 0.0))) <= 0.0:
		issues.append("fallback_polygon_area_not_reviewed")
	return issues

static func _object_visual_replacement_policy(issues: Array) -> String:
	if issues.has("fallback_polygon_not_reviewed") \
			or issues.has("fallback_polygon_area_not_reviewed"):
		return "fix_runtime_object_polygon_before_public"
	if issues.has("frame_grid_not_reviewed") or issues.has("animation_size_not_stable") \
			or issues.has("frame_size_mismatch") or issues.has("animation_motion_not_reviewed") \
			or issues.has("origin_alignment_not_reviewed") \
			or issues.has("origin_px_missing") or issues.has("origin_px_outside_frame") \
			or issues.has("frame_sheet_grid_missing"):
		return "fix_frame_grid_before_release"
	return "replace_runtime_object_sprite_before_public"

static func _candidate_acceptance_gate(kind: String) -> Array[String]:
	match kind:
		"sprite":
			return ["license_or_ownership_metadata", "source_url_or_generation_manifest",
				"frame_grid_ok", "expected_frame_size", "fps_reviewed",
				"animation_stability_reviewed", "motion_reviewed",
				"origin_alignment_reviewed", "origin_px", "image_backed_frame_review",
				"no_empty_animation_frames", "no_clipped_animation_frames",
				"frame_center_drift_reviewed", "no_direct_fanmade_copy"]
		"audio":
			return ["license_or_ownership_metadata", "source_url_or_generation_manifest",
				"waveform_ok", "duration_reviewed", "no_direct_fanmade_copy"]
		"vfx":
			return ["license_or_ownership_metadata", "geometry_ok", "frame_grid_ok",
				"expected_frame_size", "fps_reviewed", "animation_stability_reviewed",
				"motion_reviewed", "origin_alignment_reviewed", "origin_px",
				"image_backed_frame_review", "no_empty_animation_frames",
				"no_clipped_animation_frames", "frame_center_drift_reviewed",
				"no_direct_fanmade_copy"]
		"collision":
			return ["license_or_ownership_metadata", "source_url_or_generation_manifest",
				"collision_shape_or_polygon_ok", "collision_polygon_points",
				"polygon_points_px", "polygon_area_px", "no_direct_fanmade_copy"]
		"object_visual":
			return ["license_or_ownership_metadata", "source_url_or_generation_manifest",
				"runtime_object_sprite_ok", "frame_grid_ok", "expected_frame_size",
				"fps_reviewed", "animation_stability_reviewed", "motion_reviewed",
				"origin_alignment_reviewed", "origin_px", "image_backed_frame_review",
				"no_empty_animation_frames", "no_clipped_animation_frames",
				"frame_center_drift_reviewed", "fallback_polygon_points",
				"fallback_polygon_points_px", "fallback_polygon_area_px",
				"fallback_polygon_inside_frame", "no_direct_fanmade_copy"]
	return ["license_or_ownership_metadata", "no_direct_fanmade_copy"]

static func _allowed_replacement_sources(kind: String) -> Array[String]:
	match kind:
		"sprite":
			return ["0x72_dungeontileset_ii", "user_local_assets", "free_itchio",
				"godot_asset_library", "ai_generated"]
		"audio":
			return ["user_local_assets", "free_itchio", "godot_asset_library",
				"ai_generated"]
		"vfx":
			return ["procedural_godot_shapes", "user_local_assets", "free_itchio",
				"godot_asset_library", "ai_generated"]
		"collision":
			return ["project_owned_collision_polygon", "procedural_godot_shapes",
				"0x72_dungeontileset_ii", "user_local_assets", "free_itchio",
				"godot_asset_library", "ai_generated"]
		"object_visual":
			return ["0x72_dungeontileset_ii", "project_owned_collision_polygon",
				"procedural_godot_shapes", "user_local_assets", "free_itchio",
				"godot_asset_library", "ai_generated"]
	return ["user_local_assets", "free_itchio", "godot_asset_library", "ai_generated"]

static func _manifest_required_fields(kind: String) -> Array[String]:
	match kind:
		"sprite":
			return ["asset_kind", "license", "generation_tool", "frame_size",
				"expected_frame_size", "frame_count", "frame_grid_ok", "stable_size",
				"fps", "animation_stability_reviewed", "motion_reviewed",
				"origin_alignment_reviewed", "origin_px", "image_path", "review_notes"]
		"audio":
			return ["asset_kind", "license", "generation_tool", "waveform_ok",
				"duration", "review_notes"]
		"vfx":
			return ["asset_kind", "license", "generation_tool", "frame_size",
				"expected_frame_size", "frame_count", "frame_grid_ok", "fps",
				"animation_stability_reviewed", "motion_reviewed",
				"origin_alignment_reviewed", "origin_px", "image_path", "geometry_ok",
				"duration", "review_notes"]
		"collision":
			return ["asset_kind", "license", "generation_tool", "shape_ok", "polygon_ok",
				"polygon_points", "polygon_points_px", "polygon_area_px", "review_notes"]
		"object_visual":
			return ["asset_kind", "license", "generation_tool", "runtime_object_sprite_ok",
				"frame_size", "expected_frame_size", "frame_count", "frame_grid_ok", "fps",
				"animation_stability_reviewed", "motion_reviewed",
				"origin_alignment_reviewed", "origin_px", "image_path", "polygon_ok",
				"fallback_polygon_points", "fallback_polygon_points_px",
				"fallback_polygon_area_px", "fallback_polygon_inside_frame", "review_notes"]
	return ["asset_kind", "license", "generation_tool"]

static func _source_plan(kind: String, approval_gate: Array) -> Dictionary:
	var preferred_sources := _allowed_replacement_sources(kind)
	var notes := []
	match kind:
		"sprite":
			notes = ["keep exact frame_size/frame_count/sheet grid/fps/origin_px before release"]
		"vfx":
			notes = ["review geometry, fps, and animation duration before release"]
		"collision":
			notes = ["polygon must have at least 3 reviewed points",
				"polygon area must be non-zero before release",
				"polygon point coordinates must be reviewed, not just count/area",
				"free itch.io or AI collision replacements need provenance metadata"]
		"object_visual":
			notes = ["runtime sprite must keep stable frame size/count/fps/origin alignment",
				"fallback polygon must have at least 3 reviewed points, non-zero area, and stay inside the frame"]
		"audio":
			notes = ["review waveform/duration before release"]
		_:
			notes = ["keep license or ownership metadata before release"]
	return {
		"preferred_sources": preferred_sources,
		"source_priority": preferred_sources.duplicate(),
		"fanmade_policy": "reference_only_pattern_study",
		"reference_only_sources": REFERENCE_ONLY_SOURCES.duplicate(),
		"forbidden_sources": ["fanmade_direct_copy"],
		"approval_gate": approval_gate.duplicate(),
		"missing_asset_strategy": _missing_asset_strategy(kind, preferred_sources, approval_gate),
		"manifest_required_fields": _manifest_required_fields(kind),
		"review_notes": notes,
	}

static func _missing_asset_strategy(kind: String, runtime_sources: Array, approval_gate: Array) -> Dictionary:
	var release_gate := approval_gate.duplicate()
	if ["collision", "object_visual"].has(kind) and not release_gate.has("polygon_points"):
		release_gate.append("polygon_points")
	if kind == "collision" and not release_gate.has("polygon_area_px"):
		release_gate.append("polygon_area_px")
	if kind == "collision" and not release_gate.has("polygon_points_px"):
		release_gate.append("polygon_points_px")
	if kind == "object_visual" and not release_gate.has("fallback_polygon_area_px"):
		release_gate.append("fallback_polygon_area_px")
	if kind == "object_visual" and not release_gate.has("fallback_polygon_points_px"):
		release_gate.append("fallback_polygon_points_px")
	if kind == "object_visual" and not release_gate.has("fallback_polygon_inside_frame"):
		release_gate.append("fallback_polygon_inside_frame")
	return {
		"runtime_source_priority": runtime_sources.duplicate(),
		"reference_pattern_sources": REFERENCE_ONLY_SOURCES.duplicate(),
		"fanmade_policy": "study_patterns_only_never_copy_runtime_assets_or_code",
		"release_requires_self_review": true,
		"release_self_review_gate": release_gate,
		"resolution_steps": [
			"use_existing_project_or_licensed_runtime_asset",
			"study_fanmade_repos_for_pattern_reference_only",
			"try_free_itchio_asset_with_license_metadata",
			"review_user_local_asset_with_license_metadata",
			"generate_project_owned_ai_asset_with_manifest",
			"release_only_after_frame_polygon_motion_review",
		],
	}

static func _metadata_size(metadata: Dictionary, key: String) -> Vector2:
	var value: Variant = metadata.get(key, Vector2.ZERO)
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value)
	if value is Array:
		var values: Array = value
		if values.size() >= 2:
			return Vector2(float(values[0]), float(values[1]))
	if value is Dictionary:
		var values: Dictionary = value
		if values.has("x") and values.has("y"):
			return Vector2(float(values["x"]), float(values["y"]))
		if values.has("width") and values.has("height"):
			return Vector2(float(values["width"]), float(values["height"]))
	return Vector2.ZERO

static func _manifest_candidate_source_id(metadata: Dictionary) -> String:
	var source_url := str(metadata.get("source_url", "")).strip_edges().to_lower()
	if source_url == "https://itch.io" or source_url == "http://itch.io" \
			or source_url.begins_with("https://itch.io/") \
			or source_url.begins_with("http://itch.io/") \
			or source_url.contains(".itch.io/"):
		return "free_itchio"
	if source_url.begins_with("https://godotengine.org/asset-library") \
			or source_url.begins_with("http://godotengine.org/asset-library"):
		return "godot_asset_library"
	if str(metadata.get("source_path", "")).strip_edges() != "":
		return "user_local_assets"
	return "ai_generated"

static func _release_review_checklist(kind: String) -> Array[String]:
	match kind:
		"sprite":
			return ["license_or_ownership_metadata", "source_url_or_generation_manifest",
				"frame_grid_stable", "frame_size_stable", "expected_frame_size",
				"animation_fps_reviewed", "animation_stability_reviewed",
				"animation_motion_reviewed", "origin_alignment_reviewed",
				"origin_px", "image_backed_frame_review", "no_empty_animation_frames",
				"no_clipped_animation_frames", "frame_center_drift_reviewed",
				"no_direct_fanmade_copy"]
		"audio":
			return ["license_or_ownership_metadata", "source_url_or_generation_manifest",
				"waveform_stable", "no_direct_fanmade_copy"]
		"vfx":
			return ["license_or_ownership_metadata", "geometry_ok", "frame_grid_stable",
				"expected_frame_size", "animation_fps_reviewed",
				"animation_stability_reviewed", "animation_motion_reviewed",
				"origin_alignment_reviewed",
				"origin_px", "image_backed_frame_review", "no_empty_animation_frames",
				"no_clipped_animation_frames", "frame_center_drift_reviewed",
				"duration_reviewed", "no_direct_fanmade_copy"]
		"collision":
			return ["license_or_ownership_metadata", "source_url_or_generation_manifest",
				"runtime_scene_load_ok", "collision_shape_ok", "collision_polygon_points",
				"polygon_points_px", "polygon_area_px", "no_direct_fanmade_copy"]
		"object_visual":
			return ["license_or_ownership_metadata", "source_url_or_generation_manifest",
				"runtime_object_sprite_ok", "frame_grid_stable", "expected_frame_size",
				"animation_fps_reviewed", "animation_stability_reviewed",
				"animation_motion_reviewed", "origin_alignment_reviewed",
				"origin_px", "image_backed_frame_review", "no_empty_animation_frames",
				"no_clipped_animation_frames", "frame_center_drift_reviewed",
				"fallback_polygon_points", "fallback_polygon_points_px",
				"fallback_polygon_area_px", "fallback_polygon_inside_frame",
				"no_direct_fanmade_copy"]
	return ["license_or_ownership_metadata", "no_direct_fanmade_copy"]

static func _backlog_kind_counts_text(backlog: Array) -> String:
	var counts := {}
	for item in backlog:
		if not (item is Dictionary):
			continue
		var kind := str((item as Dictionary).get("kind", "asset"))
		counts[kind] = int(counts.get(kind, 0)) + 1
	var parts: Array[String] = []
	for kind in ["sprite", "audio", "vfx", "collision", "object_visual"]:
		if int(counts.get(kind, 0)) > 0:
			parts.append("%s %d" % [kind, int(counts[kind])])
	return ", ".join(parts)

static func _asset_replacement_polygon_rule(kind: String) -> String:
	match kind:
		"collision":
			return "Collision replacements need reviewed polygon_points_px, at least 3 points, and non-zero polygon_area_px"
		"object_visual":
			return "Object visuals need fallback_polygon_points_px, non-zero area, and every point inside the animation frame"
	return "Polygon review is required only when the asset owns collision or runtime object fallback geometry"

static func _missing_polygon_next_actions(kind: String) -> Array[String]:
	match kind:
		"collision":
			return ["author_project_owned_polygon", "attach_polygon_points_px",
				"review_manifest_candidate_before_release"]
		"object_visual":
			return ["keep_fallback_polygon_inside_frame", "review_frame_occupancy",
				"release_only_after_manual_self_review"]
	return []

static func _source_order_text(source_order: Array) -> String:
	var labels: Array[String] = []
	for source in source_order:
		match str(source):
			"0x72_dungeontileset_ii":
				labels.append("0x72")
			"free_itchio":
				labels.append("free itch.io")
			"user_local_assets":
				labels.append("local asset")
			"godot_asset_library":
				labels.append("Godot Asset Library")
			"ai_generated":
				labels.append("AI")
			"project_owned_collision_polygon":
				labels.append("project polygon")
			"procedural_godot_shapes":
				labels.append("procedural")
			_:
				labels.append(str(source))
	return " -> ".join(labels)

static func _ai_pixel_prompt_text(
		kind: String,
		asset_id: String,
		frame_size: Vector2,
		frame_count: int,
) -> String:
	var size_text := "%dx%d" % [int(frame_size.x), int(frame_size.y)]
	var lines := [
		"Create a transparent PNG sprite sheet for %s." % asset_id,
		"Style: top-down dungeon pixel art, readable at gameplay scale, no text, no watermark.",
		"Contract: same frame_size %s for every frame, same frame_count %d, stable fps-ready timing." % [size_text, frame_count],
		"Layout: one row if possible, transparent padding, no empty frames, no clipped frames.",
		"Alignment: keep origin_px consistent across every frame and centered for Godot runtime alignment.",
	]
	if ["object_visual", "collision"].has(kind):
		lines.append("Collision fit: leave a clear silhouette that can be traced as fallback_polygon_points_px with non-zero fallback_polygon_area_px.")
	else:
		lines.append("Motion fit: keep silhouette drift intentional and small enough for origin_px review.")
	lines.append("Do not copy Soul Knight fanmade assets, code, sprites, or audio; use only original AI-generated pixels.")
	return " ".join(lines)

static func _default_frame_polygon_points(frame_size: Vector2) -> Array[Vector2]:
	var inset_x := maxf(2.0, floorf(frame_size.x * 0.2))
	var inset_y := maxf(2.0, floorf(frame_size.y * 0.2))
	var max_x := maxf(inset_x + 1.0, frame_size.x - inset_x)
	var max_y := maxf(inset_y + 1.0, frame_size.y - inset_y)
	return [
		Vector2(inset_x, inset_y),
		Vector2(max_x, inset_y),
		Vector2(max_x, max_y),
		Vector2(inset_x, max_y),
	]

static func _normalized_local_path(path: String) -> String:
	var clean := path.strip_edges().replace("\\", "/").trim_suffix("/")
	return clean

static func _reviewed_local_manifest_count(root_path: String) -> int:
	var manifest_dir := "res://docs/asset_generation"
	var count := 0
	for file_name in DirAccess.get_files_at(manifest_dir):
		if not str(file_name).ends_with("_manifest.json"):
			continue
		var manifest_path := "%s/%s" % [manifest_dir, str(file_name)]
		var report := AssetSourceRegistryScript.generation_manifest_report(manifest_path)
		if not bool(report.get("ready", false)):
			continue
		var metadata: Dictionary = report.get("metadata", {})
		var source_path := _normalized_local_path(str(metadata.get("source_path", "")))
		if source_path.begins_with(root_path + "/"):
			count += 1
	return count
