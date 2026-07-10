class_name AudioCueDB
extends RefCounted

const AssetSourceRegistryScript := preload("res://scripts/assets/asset_source_registry.gd")
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")

const FAMILY_CUES := {
	"blade": {"id": "blade_cast", "label": "Blade cast", "frequency": 760.0},
	"breaker": {"id": "breaker_cast", "label": "Breaker cast", "frequency": 180.0},
	"shadow": {"id": "shadow_cast", "label": "Shadow cast", "frequency": 520.0},
	"guard": {"id": "guard_cast", "label": "Guard cast", "frequency": 300.0},
	"arcane": {"id": "arcane_cast", "label": "Arcane cast", "frequency": 640.0},
	"ranger": {"id": "ranger_cast", "label": "Ranger cast", "frequency": 880.0},
	"gunner": {"id": "gunner_cast", "label": "Gunner cast", "frequency": 420.0},
	"soul": {"id": "soul_cast", "label": "Soul cast", "frequency": 560.0},
	"light": {"id": "light_cast", "label": "Light cast", "frequency": 920.0},
	"tech": {"id": "tech_cast", "label": "Tech cast", "frequency": 700.0},
	"generic": {"id": "generic_cast", "label": "Generic cast", "frequency": 500.0},
}
const WEAPON_CUES := {
	"melee_attack": {"id": "melee_attack", "label": "Melee attack", "frequency": 360.0},
	"ranged_attack": {"id": "ranged_attack", "label": "Ranged attack", "frequency": 620.0},
	"magic_attack": {"id": "magic_attack", "label": "Magic attack", "frequency": 720.0},
}
const ELEMENT_COMBO_CUES := {
	"element_combo_thermal_shock": {
		"id": "element_combo_thermal_shock",
		"label": "Thermal Shock combo",
		"frequency": 1040.0,
		"duration": 0.075,
	},
	"element_combo_plasma": {
		"id": "element_combo_plasma",
		"label": "Plasma combo",
		"frequency": 860.0,
		"duration": 0.075,
	},
	"element_combo_burning_smog": {
		"id": "element_combo_burning_smog",
		"label": "Burning Smog combo",
		"frequency": 620.0,
		"duration": 0.08,
	},
	"element_combo_deep_freeze": {
		"id": "element_combo_deep_freeze",
		"label": "Deep Freeze combo",
		"frequency": 780.0,
		"duration": 0.085,
	},
	"element_combo_frostbane": {
		"id": "element_combo_frostbane",
		"label": "Frostbane combo",
		"frequency": 700.0,
		"duration": 0.08,
	},
	"element_combo_toxic_current": {
		"id": "element_combo_toxic_current",
		"label": "Toxic Current combo",
		"frequency": 940.0,
		"duration": 0.075,
	},
	"element_combo_generic": {
		"id": "element_combo_generic",
		"label": "Element combo",
		"frequency": 820.0,
		"duration": 0.07,
	},
}
const ENEMY_HIT_CUES := {
	"enemy_hit_normal": {
		"id": "enemy_hit_normal",
		"label": "Enemy hit",
		"frequency": 440.0,
		"duration": 0.055,
	},
	"enemy_hit_weak": {
		"id": "enemy_hit_weak",
		"label": "Enemy weak hit",
		"frequency": 760.0,
		"duration": 0.065,
	},
	"enemy_hit_resist": {
		"id": "enemy_hit_resist",
		"label": "Enemy resisted hit",
		"frequency": 260.0,
		"duration": 0.045,
	},
	"enemy_hit_critical": {
		"id": "enemy_hit_critical",
		"label": "Enemy critical hit",
		"frequency": 1120.0,
		"duration": 0.085,
	},
	"enemy_death": {
		"id": "enemy_death",
		"label": "Enemy defeated",
		"frequency": 180.0,
		"duration": 0.11,
	},
}
const PICKUP_CUES := {
	"pickup_gold": {"id": "pickup_gold", "label": "Gold pickup", "frequency": 980.0},
	"pickup_heal": {"id": "pickup_heal", "label": "Heal pickup", "frequency": 760.0},
	"pickup_key": {"id": "pickup_key", "label": "Key pickup", "frequency": 860.0},
	"pickup_weapon": {"id": "pickup_weapon", "label": "Weapon pickup", "frequency": 540.0},
	"pickup_meta": {"id": "pickup_meta", "label": "Meta pickup", "frequency": 700.0},
}
const REWARD_CUES := {
	"reward_choose": {"id": "reward_choose", "label": "Reward chosen", "frequency": 820.0},
	"reward_reroll": {"id": "reward_reroll", "label": "Reward reroll", "frequency": 620.0},
	"reward_skip": {"id": "reward_skip", "label": "Reward skipped", "frequency": 420.0},
	"power_tier_up": {"id": "power_tier_up", "label": "Power tier up", "frequency": 1040.0},
}
const SKILL_UI_CUES := {
	"skill_ready": {
		"id": "skill_ready",
		"label": "Skill ready",
		"frequency": 1040.0,
		"duration": 0.06,
	},
	"skill_blocked": {
		"id": "skill_blocked",
		"label": "Skill blocked",
		"frequency": 240.0,
		"duration": 0.07,
	},
	"dash_ready": {
		"id": "dash_ready",
		"label": "Dash ready",
		"frequency": 920.0,
		"duration": 0.055,
	},
	"ultimate_ready": {
		"id": "ultimate_ready",
		"label": "Ultimate ready",
		"frequency": 1180.0,
		"duration": 0.08,
	},
	"class_resource_full": {
		"id": "class_resource_full",
		"label": "Class resource full",
		"frequency": 1080.0,
		"duration": 0.065,
	},
}
const PLAYER_CUES := {
	"player_revive": {
		"id": "player_revive",
		"label": "Player revived",
		"frequency": 1080.0,
		"duration": 0.12,
	},
	"player_damage_enemy": {
		"id": "player_damage_enemy",
		"label": "Player damage",
		"frequency": 220.0,
		"duration": 0.075,
	},
	"player_damage_trap": {
		"id": "player_damage_trap",
		"label": "Trap damage",
		"frequency": 180.0,
		"duration": 0.09,
	},
	"player_damage_status": {
		"id": "player_damage_status",
		"label": "Status damage",
		"frequency": 360.0,
		"duration": 0.08,
	},
	"player_damage_boss": {
		"id": "player_damage_boss",
		"label": "Boss damage",
		"frequency": 140.0,
		"duration": 0.12,
	},
	"meta_bonus_active": {
		"id": "meta_bonus_active",
		"label": "Meta bonus active",
		"frequency": 980.0,
		"duration": 0.09,
	},
}
const SHOP_CUES := {
	"shop_buy": {"id": "shop_buy", "label": "Shop buy", "frequency": 760.0},
	"shop_leave": {"id": "shop_leave", "label": "Shop leave", "frequency": 360.0},
}
const OVERLAY_CUES := {
	"overlay_resume": {"id": "overlay_resume", "label": "Overlay resume", "frequency": 680.0},
	"overlay_restart": {"id": "overlay_restart", "label": "Overlay restart", "frequency": 300.0},
	"overlay_class_select": {"id": "overlay_class_select", "label": "Back to class select", "frequency": 560.0},
}
const CLASS_SELECT_CUES := {
	"class_select": {"id": "class_select", "label": "Class selected", "frequency": 680.0},
	"element_select": {"id": "element_select", "label": "Element selected", "frequency": 740.0},
	"mode_select": {"id": "mode_select", "label": "Run mode selected", "frequency": 540.0},
	"hub_service": {"id": "hub_service", "label": "Hub service selected", "frequency": 500.0},
	"seed_roll": {"id": "seed_roll", "label": "Seed selected", "frequency": 860.0},
	"meta_buy": {"id": "meta_buy", "label": "Meta upgrade bought", "frequency": 820.0},
	"meta_warn": {"id": "meta_warn", "label": "Meta reset warning", "frequency": 260.0},
	"meta_reset": {"id": "meta_reset", "label": "Meta profile reset", "frequency": 180.0},
	"class_confirm": {"id": "class_confirm", "label": "Run confirmed", "frequency": 940.0},
}
const OBJECTIVE_CUES := {
	"objective_complete": {"id": "objective_complete", "label": "Objective complete", "frequency": 720.0},
	"objective_reward_ready": {
		"id": "objective_reward_ready",
		"label": "Objective reward ready",
		"frequency": 900.0,
	},
	"objective_blocked": {
		"id": "objective_blocked",
		"label": "Objective blocked",
		"frequency": 220.0,
		"duration": 0.09,
	},
}
const ROOM_CLEAR_CUES := {
	"room_clear_reward": {
		"id": "room_clear_reward",
		"label": "Room clear reward ready",
		"frequency": 820.0,
		"duration": 0.09,
	},
	"room_clear_objective": {
		"id": "room_clear_objective",
		"label": "Objective room clear",
		"frequency": 900.0,
		"duration": 0.1,
	},
	"room_clear_boss": {
		"id": "room_clear_boss",
		"label": "Boss room clear",
		"frequency": 520.0,
		"duration": 0.12,
	},
	"room_clear_finale": {
		"id": "room_clear_finale",
		"label": "Final boss clear",
		"frequency": 1040.0,
		"duration": 0.16,
	},
}
const WAVE_CUES := {
	"wave_start": {
		"id": "wave_start",
		"label": "Wave start",
		"frequency": 680.0,
		"duration": 0.07,
	},
}
const TRAP_CUES := {
	"trap_arm": {
		"id": "trap_arm",
		"label": "Trap armed",
		"frequency": 760.0,
		"duration": 0.055,
	},
	"trap_trigger": {
		"id": "trap_trigger",
		"label": "Trap triggered",
		"frequency": 260.0,
		"duration": 0.08,
	},
}
const FLOOR_CUES := {
	"floor_run_start": {"id": "floor_run_start", "label": "Floor run start", "frequency": 640.0},
	"floor_descend": {"id": "floor_descend", "label": "Floor descend", "frequency": 480.0},
}
const RUN_END_CUES := {
	"run_victory": {
		"id": "run_victory",
		"label": "Run victory",
		"frequency": 940.0,
		"duration": 0.14,
	},
	"run_defeat": {
		"id": "run_defeat",
		"label": "Run defeat",
		"frequency": 180.0,
		"duration": 0.16,
	},
}
const BOSS_CUES := {
	"boss_bullet_hell": {"id": "boss_bullet_hell", "label": "Boss bullet hell", "frequency": 190.0},
	"boss_trap_wave": {"id": "boss_trap_wave", "label": "Boss trap wave", "frequency": 240.0},
	"boss_smash": {"id": "boss_smash", "label": "Boss smash", "frequency": 150.0},
	"boss_rock_volley": {"id": "boss_rock_volley", "label": "Boss rock volley", "frequency": 320.0},
	"boss_rolling_charge": {"id": "boss_rolling_charge", "label": "Boss rolling charge", "frequency": 280.0},
	"boss_spore_bloom": {"id": "boss_spore_bloom", "label": "Boss spore bloom", "frequency": 420.0},
	"boss_spore_root_wave": {"id": "boss_spore_root_wave", "label": "Boss spore root wave", "frequency": 360.0},
	"boss_spore_volley": {"id": "boss_spore_volley", "label": "Boss spore volley", "frequency": 460.0},
	"boss_spore_charge": {"id": "boss_spore_charge", "label": "Boss spore charge", "frequency": 300.0},
	"boss_spore_smash": {"id": "boss_spore_smash", "label": "Boss spore smash", "frequency": 210.0},
	"boss_forge_overheat": {"id": "boss_forge_overheat", "label": "Boss forge overheat", "frequency": 520.0},
	"boss_forge_hazard_wave": {"id": "boss_forge_hazard_wave", "label": "Boss forge hazard wave", "frequency": 340.0},
	"boss_forge_shrapnel": {"id": "boss_forge_shrapnel", "label": "Boss forge shrapnel", "frequency": 580.0},
	"boss_forge_charge": {"id": "boss_forge_charge", "label": "Boss forge charge", "frequency": 260.0},
	"boss_forge_slam": {"id": "boss_forge_slam", "label": "Boss forge slam", "frequency": 170.0},
	"boss_archive_prism": {"id": "boss_archive_prism", "label": "Boss archive prism", "frequency": 680.0},
	"boss_archive_lattice": {"id": "boss_archive_lattice", "label": "Boss archive lattice", "frequency": 620.0},
	"boss_archive_shards": {"id": "boss_archive_shards", "label": "Boss archive shards", "frequency": 740.0},
	"boss_archive_charge": {"id": "boss_archive_charge", "label": "Boss archive charge", "frequency": 560.0},
	"boss_archive_slam": {"id": "boss_archive_slam", "label": "Boss archive slam", "frequency": 460.0},
	"boss_generic_attack": {"id": "boss_generic_attack", "label": "Boss attack", "frequency": 220.0},
}
const BOSS_PHASE_CUES := {
	"boss_phase_shift": {
		"id": "boss_phase_shift",
		"label": "Boss phase shift",
		"frequency": 260.0,
		"duration": 0.1,
	},
	"boss_enrage": {
		"id": "boss_enrage",
		"label": "Boss enrage",
		"frequency": 120.0,
		"duration": 0.14,
	},
}
const BOSS_ATTACK_CUE_IDS := {
	"bullet_hell": "boss_bullet_hell",
	"trap_wave": "boss_trap_wave",
	"smash": "boss_smash",
	"rock_volley": "boss_rock_volley",
	"rolling_charge": "boss_rolling_charge",
	"spore_bloom": "boss_spore_bloom",
	"spore_root_wave": "boss_spore_root_wave",
	"spore_volley": "boss_spore_volley",
	"spore_charge": "boss_spore_charge",
	"spore_smash": "boss_spore_smash",
	"forge_overheat": "boss_forge_overheat",
	"forge_hazard_wave": "boss_forge_hazard_wave",
	"forge_shrapnel": "boss_forge_shrapnel",
	"forge_charge": "boss_forge_charge",
	"forge_slam": "boss_forge_slam",
	"archive_prism": "boss_archive_prism",
	"archive_lattice": "boss_archive_lattice",
	"archive_shards": "boss_archive_shards",
	"archive_charge": "boss_archive_charge",
	"archive_slam": "boss_archive_slam",
}
const MELEE_GROUPS := ["sword_1h", "axe", "dagger", "hammer", "spear", "shield"]
const MAGIC_GROUPS := ["staff", "orb", "tome"]

static func skill_cast_cue(skill_id: String) -> Dictionary:
	var profile: Dictionary = CombatFxScript.skill_feedback_profile(skill_id)
	return cue_for_family(str(profile.get("family", "generic")))

static func weapon_attack_cue(weapon_data: Dictionary) -> Dictionary:
	var group := str(weapon_data.get("group", ""))
	var cue_id := "ranged_attack"
	if MELEE_GROUPS.has(group):
		cue_id = "melee_attack"
	elif MAGIC_GROUPS.has(group):
		cue_id = "magic_attack"
	var cue: Dictionary = WEAPON_CUES[cue_id].duplicate(true)
	cue["family"] = group if group != "" else cue_id
	cue["kind"] = "weapon_attack"
	cue["group"] = group
	cue["source"] = "AudioCueDB"
	return cue

static func element_combo_cue(combo_id: String) -> Dictionary:
	var clean := combo_id.strip_edges()
	var cue_id := "element_combo_%s" % clean
	if not ELEMENT_COMBO_CUES.has(cue_id):
		cue_id = "element_combo_generic"
	var cue: Dictionary = ELEMENT_COMBO_CUES[cue_id].duplicate(true)
	cue["family"] = clean if clean != "" else "generic"
	cue["kind"] = "element_combo"
	cue["combo_id"] = clean
	cue["source"] = "AudioCueDB"
	return cue

static func enemy_hit_cue(hit_kind: String, element: String = "", amount: int = 0) -> Dictionary:
	var clean_kind := hit_kind.strip_edges()
	if not ["critical", "normal", "resist", "weak"].has(clean_kind):
		clean_kind = "normal"
	var cue: Dictionary = ENEMY_HIT_CUES["enemy_hit_%s" % clean_kind].duplicate(true)
	cue["family"] = "enemy_hit"
	cue["kind"] = "enemy_hit"
	cue["hit_kind"] = clean_kind
	cue["element"] = element.strip_edges()
	cue["damage_amount"] = amount
	cue["source"] = "AudioCueDB"
	return cue

static func enemy_death_cue(
		hit_kind: String = "normal",
		element: String = "",
		amount: int = 0,
		enemy_id: String = "",
) -> Dictionary:
	var cue: Dictionary = ENEMY_HIT_CUES["enemy_death"].duplicate(true)
	cue["family"] = "enemy_death"
	cue["kind"] = "enemy_death"
	cue["hit_kind"] = hit_kind.strip_edges()
	cue["element"] = element.strip_edges()
	cue["damage_amount"] = amount
	cue["enemy_id"] = enemy_id.strip_edges()
	cue["source"] = "AudioCueDB"
	return cue

static func pickup_cue(pickup_data: Dictionary) -> Dictionary:
	var type := str(pickup_data.get("type", "gold"))
	var cue_id := "pickup_meta"
	match type:
		"gold":
			cue_id = "pickup_gold"
		"potion":
			cue_id = "pickup_heal"
		"silver_key":
			cue_id = "pickup_key"
		"weapon":
			cue_id = "pickup_weapon"
		"meta_currency", "soul_shard", "soul_shards", "element_core", "element_cores", \
				"rune_dust", "blueprint", "blueprints":
			cue_id = "pickup_meta"
	var cue: Dictionary = PICKUP_CUES[cue_id].duplicate(true)
	cue["family"] = type
	cue["kind"] = "pickup"
	cue["pickup_type"] = type
	cue["source"] = "AudioCueDB"
	return cue

static func reward_decision_cue(decision: String) -> Dictionary:
	var clean := decision.strip_edges()
	var cue_id := "reward_choose"
	match clean:
		"reroll":
			cue_id = "reward_reroll"
		"skip":
			cue_id = "reward_skip"
		"choose":
			cue_id = "reward_choose"
	var cue: Dictionary = REWARD_CUES[cue_id].duplicate(true)
	cue["family"] = clean if clean != "" else "choose"
	cue["kind"] = "reward_decision"
	cue["decision"] = clean
	cue["source"] = "AudioCueDB"
	return cue

static func power_tier_cue(previous_tier: String, power_tier: String, power_arc: String = "") -> Dictionary:
	var cue: Dictionary = REWARD_CUES["power_tier_up"].duplicate(true)
	cue["family"] = "power"
	cue["kind"] = "power_tier"
	cue["previous_tier"] = previous_tier.strip_edges()
	cue["power_tier"] = power_tier.strip_edges()
	cue["power_arc"] = power_arc.strip_edges()
	cue["source"] = "AudioCueDB"
	return cue

static func skill_ready_cue(skill_id: String) -> Dictionary:
	var profile: Dictionary = CombatFxScript.skill_feedback_profile(skill_id)
	var cue: Dictionary = SKILL_UI_CUES["skill_ready"].duplicate(true)
	cue["family"] = str(profile.get("family", "generic"))
	cue["kind"] = "skill_ready"
	cue["skill_id"] = skill_id.strip_edges()
	cue["source"] = "AudioCueDB"
	return cue

static func skill_blocked_cue(reason: String) -> Dictionary:
	var clean := reason.strip_edges()
	var cue: Dictionary = SKILL_UI_CUES["skill_blocked"].duplicate(true)
	cue["family"] = clean if clean != "" else "blocked"
	cue["kind"] = "skill_blocked"
	cue["blocked_reason"] = clean
	cue["source"] = "AudioCueDB"
	return cue

static func class_resource_full_cue(resource_kind: String, summary: String = "") -> Dictionary:
	var clean := resource_kind.strip_edges()
	var cue: Dictionary = SKILL_UI_CUES["class_resource_full"].duplicate(true)
	cue["family"] = clean if clean != "" else "class_resource"
	cue["kind"] = "class_resource_full"
	cue["resource_kind"] = clean
	cue["summary"] = summary.strip_edges()
	cue["source"] = "AudioCueDB"
	return cue

static func dash_ready_cue() -> Dictionary:
	var cue: Dictionary = SKILL_UI_CUES["dash_ready"].duplicate(true)
	cue["family"] = "mobility"
	cue["kind"] = "dash_ready"
	cue["source"] = "AudioCueDB"
	return cue

static func ultimate_ready_cue(ultimate_id: String) -> Dictionary:
	var profile: Dictionary = CombatFxScript.skill_feedback_profile(ultimate_id)
	var cue: Dictionary = SKILL_UI_CUES["ultimate_ready"].duplicate(true)
	cue["family"] = str(profile.get("family", "generic"))
	cue["kind"] = "ultimate_ready"
	cue["ultimate_id"] = ultimate_id.strip_edges()
	cue["source"] = "AudioCueDB"
	return cue

static func revive_cue(context: Dictionary = {}) -> Dictionary:
	var cue: Dictionary = PLAYER_CUES["player_revive"].duplicate(true)
	cue["family"] = "revive"
	cue["kind"] = "player_revive"
	cue["revive_source"] = str(context.get("source", ""))
	cue["charges_left"] = int(context.get("charges_left", 0))
	cue["revives_used"] = int(context.get("revives_used", 0))
	cue["source"] = "AudioCueDB"
	return cue

static func player_damage_cue(
		damage_kind: String,
		damage_source: String = "",
		amount: int = 0,
) -> Dictionary:
	var clean_kind := damage_kind.strip_edges()
	if not ["boss", "enemy", "status", "trap"].has(clean_kind):
		clean_kind = "enemy"
	var cue: Dictionary = PLAYER_CUES["player_damage_%s" % clean_kind].duplicate(true)
	cue["family"] = "player_damage"
	cue["kind"] = "player_damage"
	cue["damage_kind"] = clean_kind
	cue["damage_source"] = damage_source.strip_edges()
	cue["damage_amount"] = amount
	cue["source"] = "AudioCueDB"
	return cue

static func meta_bonus_cue(summary: String, meta: Dictionary = {}) -> Dictionary:
	var cue: Dictionary = PLAYER_CUES["meta_bonus_active"].duplicate(true)
	cue["family"] = "meta"
	cue["kind"] = "meta_bonus"
	cue["summary"] = summary.strip_edges()
	cue["upgrade_count"] = _positive_upgrade_count(meta)
	cue["source"] = "AudioCueDB"
	return cue

static func _positive_upgrade_count(meta: Dictionary) -> int:
	var upgrades: Dictionary = meta.get("upgrades", {})
	var count := 0
	for value in upgrades.values():
		if int(value) > 0:
			count += 1
	return count

static func shop_decision_cue(decision: String) -> Dictionary:
	var clean := decision.strip_edges()
	var cue_id := "shop_leave" if clean == "leave" else "shop_buy"
	var cue: Dictionary = SHOP_CUES[cue_id].duplicate(true)
	cue["family"] = clean if clean != "" else "buy"
	cue["kind"] = "shop_decision"
	cue["decision"] = clean
	cue["source"] = "AudioCueDB"
	return cue

static func overlay_action_cue(action: String) -> Dictionary:
	var clean := action.strip_edges()
	var cue_id := "overlay_resume"
	match clean:
		"restart":
			cue_id = "overlay_restart"
		"class_select":
			cue_id = "overlay_class_select"
	var cue: Dictionary = OVERLAY_CUES[cue_id].duplicate(true)
	cue["family"] = clean if clean != "" else "resume"
	cue["kind"] = "overlay_action"
	cue["action"] = clean
	cue["source"] = "AudioCueDB"
	return cue

static func class_select_cue(action: String) -> Dictionary:
	var clean := action.strip_edges()
	var cue_id := "class_select"
	match clean:
		"select_element":
			cue_id = "element_select"
		"select_mode":
			cue_id = "mode_select"
		"hub_service":
			cue_id = "hub_service"
		"daily_seed":
			cue_id = "seed_roll"
		"meta_buy":
			cue_id = "meta_buy"
		"meta_reset_warn":
			cue_id = "meta_warn"
		"meta_reset_confirm":
			cue_id = "meta_reset"
		"confirm_run":
			cue_id = "class_confirm"
		"select_class":
			cue_id = "class_select"
	var cue: Dictionary = CLASS_SELECT_CUES[cue_id].duplicate(true)
	cue["family"] = clean if clean != "" else "select_class"
	cue["kind"] = "class_select"
	cue["action"] = clean
	cue["source"] = "AudioCueDB"
	return cue

static func objective_complete_cue(objective_text: String) -> Dictionary:
	var text := objective_text.strip_edges()
	var lowered := text.to_lower()
	var finale := lowered.contains("final boss") or lowered.contains("run complete")
	var cue_id := "objective_reward_ready" if lowered.contains("reward") \
		else "objective_complete"
	var cue: Dictionary = OBJECTIVE_CUES[cue_id].duplicate(true)
	cue["family"] = "finale" if finale else "reward" if cue_id == "objective_reward_ready" else "objective"
	cue["kind"] = "objective_complete"
	cue["objective_text"] = text
	cue["finale"] = finale
	cue["source"] = "AudioCueDB"
	return cue

static func objective_blocked_cue(reason: String) -> Dictionary:
	var cue: Dictionary = OBJECTIVE_CUES["objective_blocked"].duplicate(true)
	cue["family"] = "blocked"
	cue["kind"] = "objective_blocked"
	cue["blocked_reason"] = reason.strip_edges()
	cue["source"] = "AudioCueDB"
	return cue

static func room_clear_cue(room_type_label: String, objective: bool, banner_text: String = "") -> Dictionary:
	var clean_type := room_type_label.strip_edges()
	var lowered_banner := banner_text.to_lower()
	var finale := lowered_banner.contains("final boss") or lowered_banner.contains("run complete")
	var boss := clean_type == "BOSS" or lowered_banner.contains("boss")
	var cue_id := "room_clear_finale" if finale else "room_clear_boss" if boss \
		else "room_clear_objective" if objective else "room_clear_reward"
	var cue: Dictionary = ROOM_CLEAR_CUES[cue_id].duplicate(true)
	cue["family"] = "finale" if finale else "boss" if boss else "objective" if objective else "reward"
	cue["kind"] = "room_clear"
	cue["room_type"] = clean_type
	cue["objective"] = objective
	cue["finale"] = finale
	cue["banner_text"] = banner_text.strip_edges()
	cue["source"] = "AudioCueDB"
	return cue

static func wave_start_cue(wave_index: int, wave_count: int, enemy_count: int, room_type_label: String) -> Dictionary:
	var cue: Dictionary = WAVE_CUES["wave_start"].duplicate(true)
	cue["family"] = "wave"
	cue["kind"] = "wave_start"
	cue["wave_index"] = wave_index
	cue["wave_count"] = wave_count
	cue["enemy_count"] = enemy_count
	cue["room_type"] = room_type_label.strip_edges()
	cue["source"] = "AudioCueDB"
	return cue

static func trap_trigger_cue(trap_kind: String) -> Dictionary:
	var cue: Dictionary = TRAP_CUES["trap_trigger"].duplicate(true)
	cue["family"] = trap_kind.strip_edges()
	cue["kind"] = "trap_trigger"
	cue["trap_kind"] = trap_kind.strip_edges()
	cue["source"] = "AudioCueDB"
	return cue

static func trap_arm_cue(trap_kind: String) -> Dictionary:
	var cue: Dictionary = TRAP_CUES["trap_arm"].duplicate(true)
	cue["family"] = trap_kind.strip_edges()
	cue["kind"] = "trap_arm"
	cue["trap_kind"] = trap_kind.strip_edges()
	cue["source"] = "AudioCueDB"
	return cue

static func floor_transition_cue(initial: bool) -> Dictionary:
	var cue_id := "floor_run_start" if initial else "floor_descend"
	var cue: Dictionary = FLOOR_CUES[cue_id].duplicate(true)
	cue["family"] = "run_start" if initial else "descend"
	cue["kind"] = "floor_transition"
	cue["initial"] = initial
	cue["source"] = "AudioCueDB"
	return cue

static func run_end_cue(title: String) -> Dictionary:
	var clean := title.strip_edges()
	var lowered := clean.to_lower()
	var victory := lowered.contains("complete") or lowered.contains("victory") or lowered.contains("win")
	var cue_id := "run_victory" if victory else "run_defeat"
	var cue: Dictionary = RUN_END_CUES[cue_id].duplicate(true)
	cue["family"] = "victory" if victory else "defeat"
	cue["kind"] = "run_end"
	cue["result"] = "victory" if victory else "defeat"
	cue["title"] = clean
	cue["source"] = "AudioCueDB"
	return cue

static func boss_attack_cue(status: Dictionary) -> Dictionary:
	var base_attack := str(status.get("attack", "")).strip_edges()
	var variant_attack := str(status.get("variant_attack", "")).strip_edges()
	var lookup := variant_attack if variant_attack != "" else base_attack
	var cue_id := str(BOSS_ATTACK_CUE_IDS.get(lookup, "boss_generic_attack"))
	var cue: Dictionary = BOSS_CUES[cue_id].duplicate(true)
	cue["family"] = lookup if lookup != "" else "boss"
	cue["kind"] = "boss_attack"
	cue["attack"] = base_attack
	cue["variant_attack"] = variant_attack
	cue["source"] = "AudioCueDB"
	return cue

static func boss_phase_cue(status: Dictionary) -> Dictionary:
	var phase_text := str(status.get("phase_text", "")).strip_edges()
	var enraged := bool(status.get("enraged", false)) or phase_text.to_lower().contains("enrage")
	var cue_id := "boss_enrage" if enraged else "boss_phase_shift"
	var cue: Dictionary = BOSS_PHASE_CUES[cue_id].duplicate(true)
	cue["family"] = "boss_enrage" if enraged else "boss_phase"
	cue["kind"] = "boss_phase"
	cue["phase"] = int(status.get("phase", 0))
	cue["phase_text"] = phase_text
	cue["source"] = "AudioCueDB"
	return cue

static func cue_for_family(family: String) -> Dictionary:
	var clean := family.strip_edges()
	if not FAMILY_CUES.has(clean):
		clean = "generic"
	var cue: Dictionary = FAMILY_CUES[clean].duplicate(true)
	cue["family"] = clean
	cue["kind"] = "cast"
	cue["source"] = "AudioCueDB"
	return cue

static func cue_exists(cue_id: String) -> bool:
	for family in FAMILY_CUES.keys():
		if str(FAMILY_CUES[family].get("id", "")) == cue_id:
			return true
	for id in WEAPON_CUES.keys():
		if str(WEAPON_CUES[id].get("id", "")) == cue_id:
			return true
	for id in ELEMENT_COMBO_CUES.keys():
		if str(ELEMENT_COMBO_CUES[id].get("id", "")) == cue_id:
			return true
	for id in ENEMY_HIT_CUES.keys():
		if str(ENEMY_HIT_CUES[id].get("id", "")) == cue_id:
			return true
	for id in PICKUP_CUES.keys():
		if str(PICKUP_CUES[id].get("id", "")) == cue_id:
			return true
	for id in REWARD_CUES.keys():
		if str(REWARD_CUES[id].get("id", "")) == cue_id:
			return true
	for id in SKILL_UI_CUES.keys():
		if str(SKILL_UI_CUES[id].get("id", "")) == cue_id:
			return true
	for id in PLAYER_CUES.keys():
		if str(PLAYER_CUES[id].get("id", "")) == cue_id:
			return true
	for id in SHOP_CUES.keys():
		if str(SHOP_CUES[id].get("id", "")) == cue_id:
			return true
	for id in OVERLAY_CUES.keys():
		if str(OVERLAY_CUES[id].get("id", "")) == cue_id:
			return true
	for id in CLASS_SELECT_CUES.keys():
		if str(CLASS_SELECT_CUES[id].get("id", "")) == cue_id:
			return true
	for id in OBJECTIVE_CUES.keys():
		if str(OBJECTIVE_CUES[id].get("id", "")) == cue_id:
			return true
	for id in ROOM_CLEAR_CUES.keys():
		if str(ROOM_CLEAR_CUES[id].get("id", "")) == cue_id:
			return true
	for id in WAVE_CUES.keys():
		if str(WAVE_CUES[id].get("id", "")) == cue_id:
			return true
	for id in TRAP_CUES.keys():
		if str(TRAP_CUES[id].get("id", "")) == cue_id:
			return true
	for id in FLOOR_CUES.keys():
		if str(FLOOR_CUES[id].get("id", "")) == cue_id:
			return true
	for id in RUN_END_CUES.keys():
		if str(RUN_END_CUES[id].get("id", "")) == cue_id:
			return true
	for id in BOSS_CUES.keys():
		if str(BOSS_CUES[id].get("id", "")) == cue_id:
			return true
	for id in BOSS_PHASE_CUES.keys():
		if str(BOSS_PHASE_CUES[id].get("id", "")) == cue_id:
			return true
	return false

static func release_report(cue_ids: Array) -> Dictionary:
	var failures: Array[String] = []
	var generated_placeholders: Array[String] = []
	var public_release_blockers: Array[String] = []
	var cues := {}
	for raw_id in cue_ids:
		var cue_id := str(raw_id)
		var cue := _cue_entry(cue_id)
		var issues: Array[String] = []
		var frequency := float(cue.get("frequency", 0.0))
		var duration := float(cue.get("duration", 0.07)) if not cue.is_empty() else 0.0
		if cue.is_empty():
			issues.append("missing")
		if frequency <= 0.0:
			issues.append("invalid_frequency")
		if duration <= 0.0:
			issues.append("invalid_duration")
		var source := "missing" if cue.is_empty() else "project_owned_procedural_audio"
		var waveform_ok := not cue.is_empty() and frequency > 0.0 and duration > 0.0
		if source == "generated_audio":
			generated_placeholders.append(cue_id)
			public_release_blockers.append("%s:generated_audio_placeholder" % cue_id)
		elif source == "missing":
			public_release_blockers.append("%s:missing" % cue_id)
		var entry := cue.duplicate(true)
		var policy := AssetSourceRegistryScript.policy_for(source, "audio", issues)
		entry["id"] = cue_id
		entry["source"] = source
		entry["license"] = str(policy.get("license", ""))
		entry["frequency"] = frequency
		entry["duration"] = duration
		entry["waveform_ok"] = waveform_ok
		entry["ready"] = issues.is_empty()
		entry["public_ready"] = bool(policy.get("public_ready", false))
		entry["generated_placeholder"] = source == "generated_audio"
		entry["release_decision"] = str(policy.get("release_decision", "blocked"))
		entry["review_status"] = str(policy.get("review_status", "blocked"))
		entry["replacement_policy"] = str(policy.get("replacement_policy", "replace_before_public"))
		entry["needs_replacement_before_public"] = bool(
			policy.get("needs_replacement_before_public", true))
		_copy_source_policy(entry, policy)
		entry["issues"] = issues.duplicate()
		cues[cue_id] = entry
		for issue in issues:
			failures.append("%s:%s" % [cue_id, issue])
	return {
		"ready": failures.is_empty(),
		"public_ready": failures.is_empty() and public_release_blockers.is_empty(),
		"checked_count": cue_ids.size(),
		"failures": failures,
		"generated_placeholders": generated_placeholders,
		"public_release_blockers": public_release_blockers,
		"cues": cues,
	}

static func _cue_entry(cue_id: String) -> Dictionary:
	for table in _cue_tables():
		for key in table.keys():
			var cue: Dictionary = table[key]
			if str(cue.get("id", "")) == cue_id:
				return cue.duplicate(true)
	return {}

static func _cue_tables() -> Array:
	return [
		FAMILY_CUES,
		WEAPON_CUES,
		ELEMENT_COMBO_CUES,
		ENEMY_HIT_CUES,
		PICKUP_CUES,
		REWARD_CUES,
		SKILL_UI_CUES,
		PLAYER_CUES,
		SHOP_CUES,
		OVERLAY_CUES,
		CLASS_SELECT_CUES,
		OBJECTIVE_CUES,
		ROOM_CLEAR_CUES,
		WAVE_CUES,
		TRAP_CUES,
		FLOOR_CUES,
		RUN_END_CUES,
		BOSS_CUES,
		BOSS_PHASE_CUES,
	]

static func _audio_license(source: String) -> String:
	return "internal_generated_placeholder" if source == "generated_audio" else "missing"

static func _copy_source_policy(entry: Dictionary, policy: Dictionary) -> void:
	for key in [
		"source_policy_id",
		"source_kind",
		"asset_kind",
		"source_url",
		"reference_policy",
		"usable_runtime_asset",
	]:
		entry[key] = policy.get(key, "")

static func _audio_release_decision(source: String, issues: Array[String]) -> String:
	if not issues.is_empty():
		return "blocked"
	return "internal_only" if source == "generated_audio" else "blocked"

static func _audio_review_status(source: String, issues: Array[String]) -> String:
	if not issues.is_empty():
		return "blocked"
	return "stable_internal_only" if source == "generated_audio" else "blocked"

static func _audio_replacement_policy(source: String, issues: Array[String]) -> String:
	if source == "missing":
		return "add_audio_before_public"
	if not issues.is_empty():
		return "fix_waveform_before_release"
	return "replace_before_public"

static func placeholder_stream(cue: Dictionary) -> AudioStreamWAV:
	var frequency := float(cue.get("frequency", 500.0))
	var duration := float(cue.get("duration", 0.07))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 11025
	stream.stereo = false
	var frame_count := int(stream.mix_rate * maxf(duration, 0.02))
	var data := PackedByteArray()
	data.resize(frame_count)
	for i in frame_count:
		var progress := float(i) / float(maxi(frame_count - 1, 1))
		var envelope := 1.0 - progress
		var sample := sin(TAU * frequency * float(i) / float(stream.mix_rate)) * 0.42 * envelope
		data[i] = clampi(int(128.0 + sample * 127.0), 0, 255)
	stream.data = data
	return stream
