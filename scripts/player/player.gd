class_name Player
extends CharacterBody2D
## Player controller with class-driven stats (data/classes.json), elemental
## loadout, energy/mana resource and two active skills.
## Controls: WASD move, Space dash, hold LMB attack, E/C skills, Tab swap weapon.

signal hp_changed(current: int, max_value: int)
signal revived(context: Dictionary)
signal died
signal gold_changed(total: int)
signal key_changed(total: int)
signal meta_currency_changed(currency_id: String, amount: int, total: int)
signal weapon_changed(display_name: String)
signal weapon_attack_blocked(weapon_id: String, reason: String, detail: Dictionary)
signal active_reload_window_changed(status: Dictionary)
signal active_reload_performed(status: Dictionary)
signal resource_changed(current: float, max_value: float)
signal dash_cooldown_changed(left: float, total: float)
signal dash_blocked(reason: String, detail: Dictionary)
signal skill_cast(skill_id: String, cooldown: float)
signal skill_cooldown_changed(skill_id: String, left: float, total: float)
signal skill_blocked(skill_id: String, reason: String, detail: Dictionary)
signal ultimate_cast(ultimate_id: String)
signal ultimate_blocked(ultimate_id: String, reason: String, detail: Dictionary)
signal ultimate_charge_changed(current: float, max_value: float)
signal element_changed(element: String)
signal upgrades_changed(summary: String)
signal element_combo_recorded(info: Dictionary, total_count: int)

const MANA_REGEN_PER_S := 4.0  # GDD: mana regens over time
const ENERGY_PER_HIT := 5.0    # GDD: energy builds on successful hits
const PRAYER_DELAY_S := 6.0
const PRAYER_HEAL_PCT_PER_S := 0.02
const RESONANCE_DURATION_S := 5.0
const RESONANCE_SKILL_DAMAGE_MULT := 1.2
const QUICK_FINGER_DURATION_S := 3.0
const QUICK_FINGER_FIRE_RATE_PER_STACK := 0.15
const QUICK_FINGER_MAX_STACKS := 3
const PACK_HUNGER_DAMAGE_PER_SUMMON := 0.04
const SOUL_SLOT_LIMIT := 4
const TURRET_SLOT_LIMIT := 2
const SNARE_TRAP_LIMIT := 2
const SPECIAL_ROUND_LIMIT := 6
const SOUL_TETHER_OWNER_DAMAGE_MULT := 0.8
const SCAVENGE_RESOURCE_GAIN := 10.0
const HACK_TRAP_RANGE := 84.0
const BLADE_RHYTHM_HITS := 3
const BLADE_RHYTHM_DAMAGE_MULT := 1.4
const IRON_SKIN_DAMAGE_MULT := 0.8
const DEER_STEP_RANGE := 16.0
const DEER_STEP_DISTANCE := 28.0
const DEER_STEP_COOLDOWN_S := 3.0
const WEAKPOINT_BACK_ATTACK_MULT := 1.6
const WIND_FOOT_DURATION_S := 2.0
const SIPHON_MANA_RESTORE := 10.0
const JUDGEMENT_TARGET_DAMAGE_MULT := 1.3
const REFLEX_WINDOW_S := 0.5
const REFLEX_DASH_COOLDOWN_MULT := 0.5
const STEEL_THORNS_REFLECT_PCT := 0.1
const HEAVY_WINDUP_DAMAGE_MULT := 1.5
const HEAVY_WINDUP_CLEAVE_WIDTH_MULT := 1.3
const STATUS_DOT_INTERVAL := 0.5
const WEAPON_BLOCKED_FEEDBACK_MS := 220
const BIOME_MASTERY_DAMAGE_BONUS := 0.03
const CHAOS_SURGE_DURATION_S := 4.0
const CHAOS_SURGE_ELEMENT_DAMAGE_BONUS := 0.15
const CHAOS_SURGE_RESOURCE_GAIN := 8.0
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")
const SkillRunnerScript := preload("res://scripts/skills/skill_runner.gd")
const UltimateRunnerScript := preload("res://scripts/ultimates/ultimate_runner.gd")
const CLASS_SPRITES := {
	"blade_warden": {
		"idle": ["zerie_soldier_idle", "knight_m_idle_anim"],
		"run": ["zerie_soldier_walk", "knight_m_run_anim"],
		"attack": ["zerie_soldier_attack"],
		"hurt": ["zerie_soldier_hurt"],
		"death": ["zerie_soldier_death"],
	},
	"breaker": {
		"idle": ["dwarf_m_idle_anim"],
		"run": ["dwarf_m_run_anim"],
	},
	"nightblade": {
		"idle": ["lizard_f_idle_anim"],
		"run": ["lizard_f_run_anim"],
	},
	"bulwark": {
		"idle": ["knight_f_idle_anim"],
		"run": ["knight_f_run_anim"],
	},
	"arcanist": {
		"idle": ["wizzard_m_idle_anim"],
		"run": ["wizzard_m_run_anim"],
	},
	"ranger": {
		"idle": ["elf_m_idle_anim"],
		"run": ["elf_m_run_anim"],
	},
	"gunner": {
		"idle": ["lizard_m_idle_anim"],
		"run": ["lizard_m_run_anim"],
	},
	"soulbinder": {
		"idle": ["wizzard_f_idle_anim"],
		"run": ["wizzard_f_run_anim"],
	},
	"lightkeeper": {
		"idle": ["elf_f_idle_anim"],
		"run": ["elf_f_run_anim"],
	},
	"tinkerer": {
		"idle": ["dwarf_f_idle_anim"],
		"run": ["dwarf_f_run_anim"],
	},
}
const PLAYER_VISUAL_TARGET_HEIGHT := 32.0
const CAMERA_ZOOM := Vector2(2.2, 2.2)
const CAMERA_IMPACT_MIN_STRENGTH := 1.0
const CAMERA_IMPACT_MAX_STRENGTH := 5.0
const CONTROLLER_AIM_DEADZONE := 0.25
const CONTROLLER_AIM_TARGET_DISTANCE := 96.0
const AUTO_AIM_RADIUS := 190.0
const RECENT_MOUSE_AIM_MS := 900

static func class_sprite_names(class_id: String) -> Dictionary:
	var mapping: Dictionary = CLASS_SPRITES.get(class_id, {})
	if mapping.is_empty():
		return {}
	var idle_name := SpriteDB.first_existing(Array(mapping.get("idle", [])))
	var run_name := SpriteDB.first_existing(Array(mapping.get("run", [])))
	if idle_name == "" or run_name == "":
		return {}
	var result := {
		"idle": idle_name,
		"run": run_name,
	}
	for optional in ["attack", "hurt", "death"]:
		var optional_name := SpriteDB.first_existing(Array(mapping.get(optional, [])))
		if optional_name != "":
			result[optional] = optional_name
	return result

@export var move_speed := 90.0
@export var dash_speed := 260.0
@export var dash_duration := 0.15
@export var dash_iframes := 0.2  # GDD: 0.2s invulnerability on dash
@export var dash_cooldown := 1.2
@export var max_hp := 100

var hp: int
var gold := 0
var silver_keys := 0
var soul_shards := 0
var element_cores := 0
var rune_dust := 0
var blueprints := 0
var run_kills := 0

# Class-driven stats, set by apply_class().
var class_id := ""
var equipped_element := "fire"
var damage_mult := 1.0
var crit_chance := 0.1
var element_damage_bonus := {}
var projectile_bonus := 0
var pet_damage_mult := 1.0
var shield_duration_mult := 1.0
var weapon_cooldown_upgrade_mult := 1.0
var skill_cooldown_upgrade_mult := 1.0
var ultimate_charge_gain_mult := 1.0
var _upgrade_stacks := {}
var _upgrade_names := {}
var _upgrade_tags := {}
var _upgrade_set_bonuses := {}
var _upgrade_history: Array[String] = []
var _upgrade_decision_history: Array[String] = []
var _power_milestones: Array[String] = []
var _last_power_milestone_tier := ""
var _shop_purchase_history: Array[String] = []
var _pickup_history: Array[String] = []
var _room_decision_history: Array[String] = []
var _skill_usage_counts := {}
var _element_combo_counts := {}
var _damage_taken_by_source := {}
var _enemy_codex_seen := {}
var _enemy_codex_defeated := {}
var _biome_mastery_applied := {}
var _final_hit_summary := ""
var resource_type := "energy"  # "energy" or "mana"
var max_resource := 50.0
var resource := 25.0
var skill: Dictionary = {}
var skill_alt: Dictionary = {}
var ultimate: Dictionary = {}
var ultimate_charge := 0.0
var ultimate_max_charge := 100.0
var _passive_ids := {}
var _max_weapon_slots := 2
var _seconds_since_damage := 0.0
var _passive_heal_accum := 0.0
var _resonance_left := 0.0
var _quick_finger_left := 0.0
var _quick_finger_stacks := 0
var _blade_rhythm_hits := 0
var _blade_rhythm_primed := false
var _deer_step_cd_left := 0.0
var _wind_foot_left := 0.0
var _reflex_left := 0.0
var _chaos_surge_left := 0.0
var _chaos_surge_element := ""
var _statuses := {}
var _status_dot_tick := 0.0
var _revive_charges := 0
var _revives_used := 0
var _last_weapon_attack_blocked_key := ""
var _last_weapon_attack_blocked_msec := -1000000
var _last_active_reload_window_key := ""

var _weapons: Array[Weapon] = []
var _active := 0
var _skill_cd_left := 0.0
var _skill_cd_total := 0.0
var _skill_alt_cd_left := 0.0
var _skill_alt_cd_total := 0.0
var _dash_time_left := 0.0
var _dash_cd_left := 0.0
var _iframes_left := 0.0
var _dash_dir := Vector2.ZERO
var _attack_hold_time := 0.0
var _charge_full_feedback_spawned := false
var _camera_impact_serial := 0
var _screen_shake_scale := 1.0
var _accessibility_hit_pause_scale := 1.0
var _sprite_action_left := 0.0
var _sprite_action := ""
var _dead := false
var _last_move_dir := Vector2.RIGHT
var _last_mouse_motion_msec := -999999
@onready var _camera: Camera2D = get_node_or_null("Camera2D")
@onready var _sprite: AnimatedSprite2D = get_node_or_null("Sprite")
@onready var _body: Polygon2D = get_node_or_null("Body")


func _ready() -> void:
	hp = max_hp
	_dead = false
	_setup_camera()

func _exit_tree() -> void:
	var sfx := get_node_or_null("SkillCastSfx")
	if sfx != null:
		_release_skill_cast_sfx(sfx, false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length_squared() > 0.25:
		_last_mouse_motion_msec = Time.get_ticks_msec()


func configure_camera_for_room(bounds: Rect2) -> void:
	_setup_camera()
	if _camera == null:
		return
	_camera.limit_left = floori(bounds.position.x)
	_camera.limit_top = floori(bounds.position.y)
	_camera.limit_right = ceili(bounds.position.x + bounds.size.x)
	_camera.limit_bottom = ceili(bounds.position.y + bounds.size.y)
	_camera.reset_smoothing()


func _setup_camera() -> void:
	if _camera == null:
		_camera = get_node_or_null("Camera2D")
	if _camera == null:
		return
	_camera.enabled = true
	_camera.zoom = CAMERA_ZOOM
	_camera.position_smoothing_enabled = false
	_camera.make_current()


func apply_accessibility_settings(settings: Dictionary) -> void:
	_screen_shake_scale = clampf(float(settings.get("screen_shake_scale", _screen_shake_scale)),
		0.0, 1.0)
	_accessibility_hit_pause_scale = clampf(float(settings.get(
		"hit_pause_scale", _accessibility_hit_pause_scale)), 0.0, 1.0)
	set_meta("screen_shake_scale", _screen_shake_scale)
	set_meta("hit_pause_accessibility_scale", _accessibility_hit_pause_scale)


## Applies class stats + starting loadout. Called once before the run starts.
## Stat conversion (1-10 scale): HP x20, speed 60+x*7, dmg mult 1+(x-5)*0.08,
## crit x*2%, resource pool x*10.
func apply_class(data: Dictionary, element: String, starter_weapon_id: String) -> void:
	class_id = str(data["id"])
	equipped_element = element
	var stats: Dictionary = data["stats"]
	max_hp = int(stats["hp"]) * 20
	hp = max_hp
	_dead = false
	move_speed = 60.0 + float(stats["speed"]) * 7.0
	damage_mult = 1.0 + (float(stats["damage"]) - 5.0) * 0.08
	crit_chance = float(stats["crit"]) * 0.02
	element_damage_bonus.clear()
	projectile_bonus = 0
	pet_damage_mult = 1.0
	shield_duration_mult = 1.0
	weapon_cooldown_upgrade_mult = 1.0
	_upgrade_stacks.clear()
	_upgrade_names.clear()
	_upgrade_tags.clear()
	_upgrade_set_bonuses.clear()
	_upgrade_history.clear()
	_upgrade_decision_history.clear()
	_power_milestones.clear()
	_last_power_milestone_tier = ""
	_shop_purchase_history.clear()
	_pickup_history.clear()
	_room_decision_history.clear()
	_skill_usage_counts.clear()
	_element_combo_counts.clear()
	_damage_taken_by_source.clear()
	_enemy_codex_seen.clear()
	_enemy_codex_defeated.clear()
	_biome_mastery_applied.clear()
	_final_hit_summary = ""
	run_kills = 0
	_statuses.clear()
	_status_dot_tick = 0.0
	_passive_ids.clear()
	for passive in data.get("passives", []):
		if passive is Dictionary:
			_passive_ids[str(passive.get("id", ""))] = true
	_max_weapon_slots = 3 if has_passive("tool_belt") else 2
	_seconds_since_damage = 0.0
	_passive_heal_accum = 0.0
	_resonance_left = 0.0
	_quick_finger_left = 0.0
	_quick_finger_stacks = 0
	_blade_rhythm_hits = 0
	_blade_rhythm_primed = false
	_deer_step_cd_left = 0.0
	_wind_foot_left = 0.0
	_reflex_left = 0.0
	_chaos_surge_left = 0.0
	_chaos_surge_element = ""
	_clear_chaos_surge_meta()
	_revive_charges = 0
	_revives_used = 0
	resource_type = str(data["resource"])
	max_resource = float(stats["resource"]) * 10.0
	resource = max_resource if resource_type == "mana" else max_resource * 0.5
	var actives: Array = data.get("actives", [])
	skill = actives[0] if actives.size() > 0 else {}
	skill_alt = actives[1] if actives.size() > 1 else {}
	ultimate = data.get("ultimate", {})
	ultimate_max_charge = float(ultimate.get("cost", 100.0))
	ultimate_charge = 0.0
	_skill_cd_left = 0.0
	_skill_cd_total = 0.0
	_skill_alt_cd_left = 0.0
	_skill_alt_cd_total = 0.0

	for weapon in _weapons:
		weapon.queue_free()
	_weapons.clear()
	_active = 0
	var starter := Weapon.new()
	add_child(starter)
	starter.equip(starter_weapon_id)
	_weapons.append(starter)
	_apply_class_sprite()

	hp_changed.emit(hp, max_hp)
	resource_changed.emit(resource, max_resource)
	ultimate_charge_changed.emit(ultimate_charge, ultimate_max_charge)
	weapon_changed.emit(starter.display_name())
	print("Class: %s | Element: %s | Weapon: %s | Skill (E): %s | Skill (C): %s" % [
		class_id, element, starter.display_name(), str(skill.get("id", "-")),
		str(skill_alt.get("id", "-")),
	])

func apply_meta_bonuses(meta: Dictionary) -> void:
	var upgrades: Dictionary = meta.get("upgrades", {})
	var hp_bonus := int(upgrades.get("training_hp", 0)) * 10
	if hp_bonus > 0:
		max_hp += hp_bonus
		hp += hp_bonus
		hp_changed.emit(hp, max_hp)
	var damage_bonus := float(upgrades.get("training_damage", 0)) * 0.04
	if damage_bonus > 0.0:
		damage_mult += damage_bonus
	var core_bonus := float(upgrades.get("core_affinity", 0)) * 0.03
	if core_bonus > 0.0:
		for element in ElementSystem.ELEMENTS:
			element_damage_bonus[element] = float(element_damage_bonus.get(element, 0.0)) + core_bonus
	var element_records: Dictionary = meta.get("element_records", {})
	for element in ElementSystem.ELEMENTS:
		var record: Dictionary = element_records.get(element, {})
		if int(record.get("victories", 0)) <= 0:
			continue
		element_damage_bonus[element] = float(element_damage_bonus.get(element, 0.0)) + 0.02
		set_meta("mastery_%s_bonus" % element, 0.02)
	var rune_levels := int(upgrades.get("rune_stability", 0))
	if rune_levels > 0:
		dash_cooldown = maxf(0.65, dash_cooldown - 0.04 * float(rune_levels))
	projectile_bonus += int(upgrades.get("blueprint_socket", 0))
	var starter_keys := int(upgrades.get("starter_key", 0))
	if starter_keys > 0:
		add_key(starter_keys)
	var pouch_gold := int(upgrades.get("gold_pouch", 0)) * 10
	if pouch_gold > 0:
		add_gold(pouch_gold)
	_revive_charges = maxi(int(upgrades.get("revive_charm", 0)), 0)

func apply_biome_mastery(meta: Dictionary, biome: Dictionary) -> void:
	var biome_id := str(biome.get("id", "")).strip_edges()
	if biome_id == "" or _biome_mastery_applied.has(biome_id):
		return
	var records: Dictionary = meta.get("biome_records", {})
	var record: Dictionary = records.get(biome_id, {})
	if int(record.get("victories", 0)) <= 0:
		return
	var label := str(record.get("label", biome.get("name", biome_id))).strip_edges()
	if label == "":
		label = biome_id.replace("_", " ").capitalize()
	damage_mult += BIOME_MASTERY_DAMAGE_BONUS
	_biome_mastery_applied[biome_id] = true
	set_meta("biome_mastery_id", biome_id)
	set_meta("biome_mastery_label", label)
	set_meta("biome_mastery_bonus", BIOME_MASTERY_DAMAGE_BONUS)
	set_meta("biome_mastery_total_bonus",
		float(get_meta("biome_mastery_total_bonus", 0.0)) + BIOME_MASTERY_DAMAGE_BONUS)

func current_weapon() -> Weapon:
	return _weapons[_active] if not _weapons.is_empty() else null

func weapon_slot_count() -> int:
	return _weapons.size()

func try_active_reload() -> bool:
	var weapon := current_weapon()
	if weapon == null or not weapon.has_method("try_active_reload"):
		set_meta("active_reload_failed_reason", "weapon")
		return false
	var status := active_reload_window_status()
	var ok := bool(weapon.call("try_active_reload"))
	set_meta("active_reload_failed_reason",
		"" if ok else str(weapon.get_meta("active_reload_failed_reason", "timing")))
	if ok:
		status["success"] = true
		status["rounds"] = int(weapon.get_meta("active_reload_rounds_left", 0))
		active_reload_performed.emit(status)
	return ok

func active_reload_window_status() -> Dictionary:
	var weapon := current_weapon()
	if weapon == null or not weapon.has_method("active_reload_window_status"):
		return {
			"enabled": false,
			"in_window": false,
			"cooldown_left": 0.0,
			"cooldown_total": 0.0,
			"window_seconds": 0.0,
			"damage_mult": 1.0,
			"weapon_id": "",
			"weapon_name": "",
		}
	var status := weapon.call("active_reload_window_status") as Dictionary
	var enabled := class_id == "gunner" and bool(status.get("enabled", false))
	status["enabled"] = enabled
	status["in_window"] = enabled and bool(status.get("in_window", false))
	status["weapon_id"] = str(weapon.data.get("id", ""))
	status["weapon_name"] = weapon.display_name()
	return status

func weapon_loadout_summary(max_items: int = 3) -> String:
	if _weapons.is_empty():
		return "None"
	var parts: Array[String] = []
	var shown := mini(max_items, _weapons.size())
	for i in shown:
		var weapon := _weapons[i]
		if weapon == null:
			continue
		var name := weapon.display_name()
		if i == _active:
			name += " (active)"
		parts.append(name)
	if _weapons.size() > shown:
		parts.append("+%d more" % (_weapons.size() - shown))
	return " / ".join(parts) if not parts.is_empty() else "None"

func socket_capacity() -> int:
	var weapon := current_weapon()
	if weapon == null or not weapon.has_method("socket_capacity"):
		return 0
	return int(weapon.call("socket_capacity"))

func socket_upgrade_count() -> int:
	var count := 0
	for upgrade_id in _upgrade_stacks.keys():
		if not Array(_upgrade_tags.get(upgrade_id, [])).has("socket"):
			continue
		count += int(_upgrade_stacks.get(upgrade_id, 0))
	return count

func has_passive(passive_id: String) -> bool:
	return _passive_ids.has(passive_id)

func swap_weapon_slot() -> void:
	if _weapons.size() <= 1:
		return
	_active = (_active + 1) % _weapons.size()
	weapon_changed.emit(_weapons[_active].display_name())
	print("Equipped: %s" % _weapons[_active].display_name())

func cycle_element() -> void:
	var elements := ElementSystem.ELEMENTS
	var before := str(equipped_element)
	var idx := elements.find(equipped_element)
	idx = 0 if idx < 0 else (idx + 1) % elements.size()
	equipped_element = str(elements[idx])
	_show_element_shift_feedback(before, equipped_element, "cycle_element")
	if has_passive("resonance"):
		_resonance_left = RESONANCE_DURATION_S
		_show_resonance_feedback()
	element_changed.emit(equipped_element)
	var weapon := current_weapon()
	if weapon != null:
		weapon_changed.emit(weapon.display_name())
	print("Element: %s" % equipped_element)


func _physics_process(delta: float) -> void:
	_sprite_action_left = maxf(_sprite_action_left - delta, 0.0)
	var previous_dash_cd := _dash_cd_left
	_dash_cd_left = maxf(_dash_cd_left - delta, 0.0)
	if not is_equal_approx(previous_dash_cd, _dash_cd_left):
		dash_cooldown_changed.emit(_dash_cd_left, dash_cooldown)
	_iframes_left = maxf(_iframes_left - delta, 0.0)
	var previous_skill_cd := _skill_cd_left
	_skill_cd_left = maxf(_skill_cd_left - delta, 0.0)
	if not is_equal_approx(previous_skill_cd, _skill_cd_left):
		skill_cooldown_changed.emit(str(skill.get("id", "")), _skill_cd_left, _skill_cd_total)
	var previous_skill_alt_cd := _skill_alt_cd_left
	_skill_alt_cd_left = maxf(_skill_alt_cd_left - delta, 0.0)
	if not is_equal_approx(previous_skill_alt_cd, _skill_alt_cd_left):
		skill_cooldown_changed.emit(str(skill_alt.get("id", "")), _skill_alt_cd_left, _skill_alt_cd_total)
	if resource_type == "mana":
		_gain_resource(MANA_REGEN_PER_S * delta)
	_tick_chaos_surge(delta)
	_tick_statuses(delta)
	_update_passives(delta)

	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		velocity = _dash_dir * dash_speed
	else:
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_dir.length_squared() > 0.01:
			_last_move_dir = input_dir.normalized()
		velocity = input_dir * current_move_speed()
		if Input.is_action_just_pressed("dash"):
			_try_dash(input_dir)

	if Input.is_action_just_pressed("swap_weapon") and _weapons.size() > 1:
		swap_weapon_slot()

	if Input.is_action_just_pressed("cycle_element"):
		cycle_element()

	if InputMap.has_action("active_reload") and Input.is_action_just_pressed("active_reload"):
		try_active_reload()
	_update_active_reload_window_feedback()

	if Input.is_action_just_pressed("skill"):
		_try_skill()

	if Input.is_action_just_pressed("skill_alt"):
		_try_skill_alt()

	if Input.is_action_just_pressed("ultimate"):
		_try_ultimate()

	var weapon := current_weapon()
	if weapon != null and weapon.has_method("uses_charge_attack") \
			and bool(weapon.call("uses_charge_attack")):
		if Input.is_action_pressed("attack"):
			_attack_hold_time += delta
			var full_time := maxf(float(weapon.call("charge_time_full")), 0.001)
			var charge_ratio := clampf(_attack_hold_time / full_time, 0.0, 1.0)
			_update_weapon_charge_feedback(charge_ratio)
			if charge_ratio >= 1.0 and not _charge_full_feedback_spawned:
				CombatFxScript.spawn_weapon_charge(_fx_parent(), global_position, charge_ratio)
				_charge_full_feedback_spawned = true
		if Input.is_action_just_released("attack"):
			weapon.call("try_charged_attack", global_position, _aim_dir(), _attack_hold_time)
			_update_weapon_charge_feedback(0.0, false)
			_attack_hold_time = 0.0
			_charge_full_feedback_spawned = false
	elif Input.is_action_pressed("attack"):
		if weapon != null:
			weapon.try_attack(global_position, _aim_dir())
	else:
		_attack_hold_time = 0.0
		_charge_full_feedback_spawned = false
		_update_weapon_charge_feedback(0.0, false)

	move_and_slide()
	_update_sprite_anim()


func _aim_dir() -> Vector2:
	var controller_aim := _controller_aim_dir()
	if controller_aim != Vector2.ZERO:
		set_meta("last_aim_input_source", "controller")
		set_meta("last_aim_dir", controller_aim)
		return controller_aim
	if _recent_mouse_aim_active():
		var mouse_dir := _mouse_aim_dir()
		if mouse_dir != Vector2.ZERO:
			set_meta("last_aim_input_source", "mouse")
			set_meta("last_aim_dir", mouse_dir)
			return mouse_dir
	var auto_dir := _nearest_enemy_aim_dir()
	if auto_dir != Vector2.ZERO:
		set_meta("last_aim_input_source", "auto_target")
		set_meta("last_aim_dir", auto_dir)
		return auto_dir
	var movement_dir := _movement_aim_dir()
	if movement_dir != Vector2.ZERO:
		set_meta("last_aim_input_source", "movement")
		set_meta("last_aim_dir", movement_dir)
		return movement_dir
	var mouse_dir := _mouse_aim_dir()
	if mouse_dir != Vector2.ZERO:
		set_meta("last_aim_input_source", "mouse")
		set_meta("last_aim_dir", mouse_dir)
		return mouse_dir
	set_meta("last_aim_input_source", "fallback")
	set_meta("last_aim_dir", Vector2.RIGHT)
	return Vector2.RIGHT

func _mouse_aim_dir() -> Vector2:
	if is_inside_tree():
		var mouse_aim := get_global_mouse_position() - global_position
		if mouse_aim != Vector2.ZERO:
			return mouse_aim.normalized()
	return Vector2.ZERO

func _recent_mouse_aim_active() -> bool:
	return Time.get_ticks_msec() - _last_mouse_motion_msec <= RECENT_MOUSE_AIM_MS

func _nearest_enemy_aim_dir() -> Vector2:
	if not is_inside_tree():
		return Vector2.ZERO
	var best: Node2D = null
	var best_dist := AUTO_AIM_RADIUS * AUTO_AIM_RADIUS
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and is_instance_valid(node) and not node.is_queued_for_deletion():
			var enemy := node as Node2D
			var dist := global_position.distance_squared_to(enemy.global_position)
			if dist <= best_dist:
				best_dist = dist
				best = enemy
	if best == null:
		return Vector2.ZERO
	var to_enemy := best.global_position - global_position
	return to_enemy.normalized() if to_enemy.length_squared() > 0.0 else Vector2.ZERO

func _movement_aim_dir() -> Vector2:
	if velocity.length_squared() > 1.0:
		return velocity.normalized()
	return _last_move_dir if _last_move_dir.length_squared() > 0.0 else Vector2.ZERO

func _aim_target_position() -> Vector2:
	var controller_aim := _controller_aim_dir()
	if controller_aim != Vector2.ZERO:
		return global_position + controller_aim * CONTROLLER_AIM_TARGET_DISTANCE
	if _recent_mouse_aim_active():
		var mouse_dir := _mouse_aim_dir()
		if mouse_dir != Vector2.ZERO:
			return global_position + mouse_dir * CONTROLLER_AIM_TARGET_DISTANCE
	var auto_target := _nearest_enemy_within(AUTO_AIM_RADIUS)
	if auto_target != null:
		return auto_target.global_position
	var movement_dir := _movement_aim_dir()
	if movement_dir != Vector2.ZERO:
		return global_position + movement_dir * CONTROLLER_AIM_TARGET_DISTANCE
	if is_inside_tree():
		return get_global_mouse_position()
	return global_position + Vector2.RIGHT * CONTROLLER_AIM_TARGET_DISTANCE

func _controller_aim_dir() -> Vector2:
	for action in ["aim_left", "aim_right", "aim_up", "aim_down"]:
		if not InputMap.has_action(action):
			return Vector2.ZERO
	var aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", CONTROLLER_AIM_DEADZONE)
	return aim.normalized() if aim.length() >= CONTROLLER_AIM_DEADZONE else Vector2.ZERO


func _apply_class_sprite() -> void:
	if _sprite == null:
		return
	var sprite_names := class_sprite_names(class_id)
	if sprite_names.is_empty():
		_show_placeholder()
		return
	var idle_name := str(sprite_names["idle"])
	var run_name := str(sprite_names["run"])
	var anims := {
		"idle": idle_name,
		"run": run_name,
	}
	for optional in ["attack", "hurt", "death"]:
		if sprite_names.has(optional):
			anims[optional] = str(sprite_names[optional])
	var sprite_frames := SpriteDB.build_sprite_frames(anims)
	if sprite_frames == null:
		_show_placeholder()
		return
	_sprite.sprite_frames = sprite_frames
	_sprite.visible = true
	_sprite.scale = SpriteDB.visual_scale(idle_name, PLAYER_VISUAL_TARGET_HEIGHT, true, 2.4)
	SpriteDB.apply_sprite_metadata(_sprite, idle_name)
	_sprite.set_meta("class_idle_sprite", idle_name)
	_sprite.set_meta("class_run_sprite", run_name)
	for optional in ["attack", "hurt", "death"]:
		if sprite_names.has(optional):
			_sprite.set_meta("class_%s_sprite" % optional, str(sprite_names[optional]))
	_align_sprite_to_collision()
	_sprite.play("idle")
	if _body != null:
		_body.visible = false


func _show_placeholder() -> void:
	if _sprite != null:
		_sprite.visible = false
	if _body != null:
		_body.visible = true


func _update_sprite_anim() -> void:
	if _sprite == null or not _sprite.visible or _sprite.sprite_frames == null:
		return
	if _sprite_action_left > 0.0 and _sprite.sprite_frames.has_animation(_sprite_action):
		return
	var anim := "run" if velocity.length_squared() > 1.0 else "idle"
	if _sprite.animation != anim:
		_sprite.play(anim)
	var face_dir := velocity
	if face_dir.length_squared() <= 1.0:
		face_dir = _aim_dir()
	if absf(face_dir.x) > 0.01:
		_sprite.flip_h = face_dir.x < 0.0


func play_sprite_action(anim: String, duration: float = 0.18) -> bool:
	if _sprite == null or _sprite.sprite_frames == null or not _sprite.sprite_frames.has_animation(anim):
		return false
	_sprite_action = anim
	_sprite_action_left = maxf(duration, 0.0)
	_sprite.play(anim)
	set_meta("last_sprite_action_anim", anim)
	set_meta("last_sprite_action_seconds", _sprite_action_left)
	return true


func _align_sprite_to_collision() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var frame_height := _sprite_frame_height()
	if frame_height <= 0.0:
		return
	var scale_y := maxf(absf(_sprite.scale.y), 0.001)
	var frame_width := _sprite_frame_width()
	var origin: Vector2 = _sprite.get_meta("origin_px", Vector2.ZERO)
	if origin == Vector2.ZERO:
		_sprite.offset = Vector2(0.0, _collision_half_height() / scale_y - frame_height * 0.5)
		return
	_sprite.offset = Vector2(
		frame_width * 0.5 - origin.x,
		_collision_half_height() / scale_y + frame_height * 0.5 - origin.y)
	set_meta("sprite_origin_alignment", "manifest_origin_px")
	set_meta("sprite_origin_px", origin)


func _sprite_frame_height() -> float:
	var max_height := 0.0
	for anim_name in _sprite.sprite_frames.get_animation_names():
		for i in _sprite.sprite_frames.get_frame_count(anim_name):
			var frame := _sprite.sprite_frames.get_frame_texture(anim_name, i)
			if frame != null:
				max_height = maxf(max_height, frame.get_size().y)
	return max_height


func _sprite_frame_width() -> float:
	var max_width := 0.0
	for anim_name in _sprite.sprite_frames.get_animation_names():
		for i in _sprite.sprite_frames.get_frame_count(anim_name):
			var frame := _sprite.sprite_frames.get_frame_texture(anim_name, i)
			if frame != null:
				max_width = maxf(max_width, frame.get_size().x)
	return max_width


func _collision_half_height() -> float:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return 0.0
	var rect := collision.shape as RectangleShape2D
	return rect.size.y * 0.5 if rect != null else 0.0


## Called by weapons/projectiles when a hit lands (energy classes build up).
func on_hit_landed() -> void:
	_hit_pause(0.035, 0.92, "weapon_hit")
	if resource_type == "energy":
		_gain_resource(ENERGY_PER_HIT)
	add_ultimate_charge(3.0)
	if has_passive("blade_rhythm") and not _blade_rhythm_primed:
		_blade_rhythm_hits += 1
		if _blade_rhythm_hits >= BLADE_RHYTHM_HITS:
			_blade_rhythm_primed = true
			_show_blade_rhythm_feedback("primed")


func _gain_resource(amount: float) -> void:
	if amount <= 0.0 or resource >= max_resource:
		return
	var old_resource := resource
	resource = minf(resource + amount, max_resource)
	resource_changed.emit(resource, max_resource)
	var gained := int(round(resource - old_resource))
	if gained > 0:
		_spawn_player_resource_number(gained)


func add_ultimate_charge(amount: float) -> void:
	if amount <= 0.0 or ultimate_charge >= ultimate_max_charge:
		return
	ultimate_charge = minf(ultimate_charge + amount * ultimate_charge_gain_multiplier(), ultimate_max_charge)
	ultimate_charge_changed.emit(ultimate_charge, ultimate_max_charge)


func _update_passives(delta: float) -> void:
	_seconds_since_damage += delta
	_resonance_left = maxf(_resonance_left - delta, 0.0)
	_quick_finger_left = maxf(_quick_finger_left - delta, 0.0)
	_deer_step_cd_left = maxf(_deer_step_cd_left - delta, 0.0)
	_wind_foot_left = maxf(_wind_foot_left - delta, 0.0)
	_reflex_left = maxf(_reflex_left - delta, 0.0)
	if _quick_finger_left <= 0.0:
		_quick_finger_stacks = 0
	if has_passive("prayer") and hp < max_hp and _seconds_since_damage >= PRAYER_DELAY_S:
		_passive_heal_accum += float(max_hp) * PRAYER_HEAL_PCT_PER_S * delta
		var heal_amount := int(floorf(_passive_heal_accum))
		if heal_amount > 0:
			_passive_heal_accum -= float(heal_amount)
			heal(heal_amount)
			_show_prayer_feedback(heal_amount)
	if has_passive("deer_step"):
		_try_deer_step()

func deer_step_cooldown_left() -> float:
	return _deer_step_cd_left

func dash_cooldown_left() -> float:
	return _dash_cd_left

func _try_dash(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		return
	if _dash_cd_left > 0.0 and _wind_foot_left <= 0.0:
		_emit_dash_blocked("cooldown", {
			"cooldown_left": _dash_cd_left,
			"cooldown_total": dash_cooldown,
		})
		return
	_start_dash(input_dir)

func _emit_dash_blocked(reason: String, detail: Dictionary) -> void:
	set_meta("last_dash_blocked_reason", reason)
	set_meta("last_dash_blocked_cooldown_left", float(detail.get("cooldown_left", 0.0)))
	dash_blocked.emit(reason, detail)

func notify_weapon_attack_blocked(weapon_data: Dictionary, reason: String, detail: Dictionary) -> void:
	var weapon_id := str(weapon_data.get("id", ""))
	var key := "%s:%s" % [weapon_id, reason]
	var now := Time.get_ticks_msec()
	if key == _last_weapon_attack_blocked_key \
			and now - _last_weapon_attack_blocked_msec < WEAPON_BLOCKED_FEEDBACK_MS:
		return
	_last_weapon_attack_blocked_key = key
	_last_weapon_attack_blocked_msec = now
	var payload := detail.duplicate(true)
	payload["weapon_name"] = str(payload.get("weapon_name", weapon_data.get("name", weapon_id)))
	payload["weapon_group"] = str(payload.get("weapon_group", weapon_data.get("group", "")))
	set_meta("last_weapon_attack_blocked_id", weapon_id)
	set_meta("last_weapon_attack_blocked_reason", reason)
	set_meta("last_weapon_attack_blocked_name", str(payload.get("weapon_name", "")))
	weapon_attack_blocked.emit(weapon_id, reason, payload)

func wind_foot_active_left() -> float:
	return _wind_foot_left

func reflex_window_left() -> float:
	return _reflex_left

func _try_deer_step() -> void:
	if _deer_step_cd_left > 0.0:
		return
	var nearest := _nearest_enemy_within(DEER_STEP_RANGE)
	if nearest == null:
		return
	var away := global_position - nearest.global_position
	if away.length_squared() <= 0.001:
		away = Vector2.LEFT
	away = away.normalized()
	global_position += away * DEER_STEP_DISTANCE
	_deer_step_cd_left = DEER_STEP_COOLDOWN_S
	set_meta("deer_step_distance", DEER_STEP_DISTANCE)
	set_meta("deer_step_trigger_range", DEER_STEP_RANGE)
	set_meta("deer_step_cooldown_seconds", DEER_STEP_COOLDOWN_S)
	set_meta("deer_step_spent_dash_cooldown", false)
	set_meta("deer_step_triggered", true)
	_show_deer_step_feedback()

func _nearest_enemy_within(radius: float) -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var best: Node2D = null
	var best_dist := radius
	for node in tree.get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist <= best_dist:
			best = enemy
			best_dist = dist
	return best

func _show_deer_step_feedback() -> void:
	var old := get_node_or_null("DeerStepFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "DeerStepFeedback"
	label.text = "DEER STEP"
	label.position = Vector2(-24, -30)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.62))
	label.set_meta("passive_id", "deer_step")
	label.set_meta("cooldown_seconds", DEER_STEP_COOLDOWN_S)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -10), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))


func _incoming_damage_after_passives(amount: int) -> int:
	var final_amount := amount
	if has_passive("unyielding") and max_hp > 0 and float(hp) / float(max_hp) < 0.3:
		var before_unyielding := final_amount
		final_amount = int(round(float(final_amount) * 0.7))
		var blocked_unyielding := maxi(before_unyielding - final_amount, 0)
		if blocked_unyielding > 0:
			_show_unyielding_feedback(blocked_unyielding)
	var soul_tether_summons := _living_summon_count()
	if has_passive("soul_tether") and soul_tether_summons > 0:
		var before_soul_tether := final_amount
		final_amount = int(round(float(final_amount) * SOUL_TETHER_OWNER_DAMAGE_MULT))
		var blocked_soul_tether := maxi(before_soul_tether - final_amount, 0)
		if blocked_soul_tether > 0:
			_show_soul_tether_feedback(blocked_soul_tether, soul_tether_summons)
	if has_passive("iron_skin") and velocity.length_squared() <= 1.0:
		var before_iron_skin := final_amount
		final_amount = int(round(float(final_amount) * IRON_SKIN_DAMAGE_MULT))
		var blocked := maxi(before_iron_skin - final_amount, 0)
		if blocked > 0:
			_show_iron_skin_feedback(blocked)
	if has_status("cursed"):
		final_amount = ceili(float(final_amount) * 1.25)
	var temporary_armor := int(get_meta("temporary_armor", 0))
	if temporary_armor > 0:
		final_amount = maxi(final_amount - temporary_armor, 1)
	return maxi(final_amount, 1)


func skill_damage_multiplier() -> float:
	return RESONANCE_SKILL_DAMAGE_MULT if _resonance_left > 0.0 else 1.0

func skill_base_damage() -> int:
	var weapon := current_weapon()
	var base := float(weapon.base_damage() if weapon != null else 10)
	base *= damage_mult
	base *= skill_damage_multiplier()
	base *= element_damage_multiplier(equipped_element)
	return maxi(1, int(round(base)))


func weapon_cooldown_multiplier() -> float:
	var multiplier := 1.0 / (1.0 + QUICK_FINGER_FIRE_RATE_PER_STACK * float(_quick_finger_stacks))
	if bool(get_meta("suppressing_fire_active", false)):
		multiplier *= 1.0 / 1.6
	multiplier *= weapon_cooldown_upgrade_mult
	return multiplier

func skill_cooldown_multiplier() -> float:
	return skill_cooldown_upgrade_mult

func ultimate_charge_gain_multiplier() -> float:
	return ultimate_charge_gain_mult


func weapon_damage_multiplier() -> float:
	return BLADE_RHYTHM_DAMAGE_MULT if _blade_rhythm_primed else 1.0

func back_attack_damage_multiplier() -> float:
	if not has_passive("weakpoint"):
		return 1.0
	_show_weakpoint_feedback()
	return WEAKPOINT_BACK_ATTACK_MULT

func target_damage_multiplier(target: Node) -> float:
	if has_passive("judgement") and _is_judgement_target(target):
		_show_judgement_feedback(_judgement_target_family(target))
		return JUDGEMENT_TARGET_DAMAGE_MULT
	return 1.0

func _is_judgement_target(target: Node) -> bool:
	return _judgement_target_family(target) != ""

func _judgement_target_family(target: Node) -> String:
	if target == null:
		return ""
	for key in ["enemy_family", "family", "enemy_id", "kind"]:
		var value := str(target.get_meta(key, "")).to_lower()
		if value.contains("undead"):
			return "undead"
		if value.contains("shadow"):
			return "shadow"
	return ""

func siphon_mana_restore_amount() -> int:
	return int(SIPHON_MANA_RESTORE)

func charged_attack_damage_multiplier(charge_ratio: float) -> float:
	if has_passive("heavy_windup") and charge_ratio >= 0.999:
		_show_heavy_windup_feedback()
		return HEAVY_WINDUP_DAMAGE_MULT
	return 1.0

func charged_attack_cleave_width_multiplier(charge_ratio: float) -> float:
	if has_passive("heavy_windup") and charge_ratio >= 0.999:
		return HEAVY_WINDUP_CLEAVE_WIDTH_MULT
	return 1.0


func prime_guaranteed_crit() -> void:
	set_meta("guaranteed_crit", true)


func consume_guaranteed_crit() -> bool:
	if not bool(get_meta("guaranteed_crit", false)):
		return false
	set_meta("guaranteed_crit", false)
	return true


func consume_weapon_damage_bonus() -> void:
	if _blade_rhythm_primed:
		_blade_rhythm_primed = false
		_blade_rhythm_hits = 0
		_show_blade_rhythm_feedback("consumed")

func activate_chaos_surge(element: String) -> void:
	var clean_element := element.strip_edges()
	if not ElementSystem.ELEMENTS.has(clean_element):
		clean_element = equipped_element
	_chaos_surge_element = clean_element
	_chaos_surge_left = CHAOS_SURGE_DURATION_S
	set_meta("chaos_surge_active", true)
	set_meta("chaos_surge_element", _chaos_surge_element)
	set_meta("chaos_surge_left", _chaos_surge_left)
	set_meta("chaos_surge_duration_seconds", CHAOS_SURGE_DURATION_S)
	set_meta("chaos_surge_damage_bonus", CHAOS_SURGE_ELEMENT_DAMAGE_BONUS)
	set_meta("chaos_surge_resource_gain", CHAOS_SURGE_RESOURCE_GAIN)
	_gain_resource(CHAOS_SURGE_RESOURCE_GAIN)
	_spawn_chaos_surge_feedback()

func _tick_chaos_surge(delta: float) -> void:
	if _chaos_surge_left <= 0.0:
		return
	_chaos_surge_left = maxf(_chaos_surge_left - delta, 0.0)
	set_meta("chaos_surge_left", _chaos_surge_left)
	if _chaos_surge_left <= 0.0:
		_chaos_surge_element = ""
		_clear_chaos_surge_meta()

func _clear_chaos_surge_meta() -> void:
	set_meta("chaos_surge_active", false)
	set_meta("chaos_surge_element", "")
	set_meta("chaos_surge_left", 0.0)

func _spawn_chaos_surge_feedback() -> void:
	if not is_inside_tree():
		return
	var old := get_node_or_null("ChaosSurgeFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "ChaosSurgeFeedback"
	label.text = "CHAOS SURGE"
	label.position = Vector2(-28, -46)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	label.set_meta("buff_id", "chaos_surge")
	label.set_meta("element", _chaos_surge_element)
	label.set_meta("damage_bonus", CHAOS_SURGE_ELEMENT_DAMAGE_BONUS)
	label.set_meta("duration_seconds", CHAOS_SURGE_DURATION_S)
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -12), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))


func pet_damage_multiplier() -> float:
	var mult := pet_damage_mult
	if has_passive("pack_hunger"):
		mult *= 1.0 + PACK_HUNGER_DAMAGE_PER_SUMMON * float(_living_summon_count())
	return mult


func soul_slot_limit() -> int:
	return SOUL_SLOT_LIMIT if class_id == "soulbinder" else 0


func soul_slots_used() -> int:
	if soul_slot_limit() <= 0:
		return 0
	var tree := get_tree()
	if tree == null:
		return 0
	var slots := 0
	for summon in tree.get_nodes_in_group("player_summons"):
		if is_instance_valid(summon) and not summon.is_queued_for_deletion():
			slots += maxi(int(summon.get_meta("soul_slot_cost", 1)), 1)
	return slots


func soul_slot_summary() -> String:
	var limit := soul_slot_limit()
	return "Soul Slots %d/%d" % [mini(soul_slots_used(), limit), limit]


func turret_slot_limit() -> int:
	return TURRET_SLOT_LIMIT if class_id == "tinkerer" else 0


func turrets_used() -> int:
	if turret_slot_limit() <= 0:
		return 0
	var tree := get_tree()
	if tree == null:
		return 0
	var count := 0
	for summon in tree.get_nodes_in_group("player_summons"):
		if not is_instance_valid(summon) or summon.is_queued_for_deletion():
			continue
		if str(summon.get_meta("summon_type", "")) != "mini_turret":
			continue
		if int(summon.get_meta("owner_id", get_instance_id())) != get_instance_id():
			continue
		count += 1
	return count


func turret_slot_summary() -> String:
	var limit := turret_slot_limit()
	return "Turrets %d/%d" % [mini(turrets_used(), limit), limit]


func snare_trap_limit() -> int:
	return SNARE_TRAP_LIMIT if class_id == "ranger" else 0


func snares_used() -> int:
	if snare_trap_limit() <= 0:
		return 0
	var tree := get_tree()
	if tree == null:
		return 0
	var count := 0
	for trap in tree.get_nodes_in_group("player_traps"):
		if not is_instance_valid(trap) or trap.is_queued_for_deletion():
			continue
		if str(trap.get_meta("trap_type", "")) != "snare_trap":
			continue
		if int(trap.get_meta("owner_id", get_instance_id())) != get_instance_id():
			continue
		count += 1
	return count


func snare_trap_summary() -> String:
	var limit := snare_trap_limit()
	return "Snares %d/%d" % [mini(snares_used(), limit), limit]


func special_round_limit() -> int:
	return SPECIAL_ROUND_LIMIT if class_id == "gunner" else 0


func special_rounds_left() -> int:
	if special_round_limit() <= 0:
		return 0
	return clampi(int(get_meta("special_rounds_left", 0)), 0, special_round_limit())


func special_round_summary() -> String:
	var limit := special_round_limit()
	return "Rounds %d/%d" % [special_rounds_left(), limit]


func class_resource_status() -> Dictionary:
	if soul_slot_limit() > 0:
		var limit := soul_slot_limit()
		return _class_resource_payload("soul_slots", "Soul Slots", soul_slots_used(), limit)
	if turret_slot_limit() > 0:
		var limit := turret_slot_limit()
		return _class_resource_payload("turrets", "Turrets", turrets_used(), limit)
	if snare_trap_limit() > 0:
		var limit := snare_trap_limit()
		return _class_resource_payload("snares", "Snares", snares_used(), limit)
	if special_round_limit() > 0:
		var limit := special_round_limit()
		return _class_resource_payload("rounds", "Rounds", special_rounds_left(), limit)
	return {}


func class_resource_summary() -> String:
	return str(class_resource_status().get("text", ""))


func _class_resource_payload(kind: String, label: String, used_value: int, limit: int) -> Dictionary:
	var used := clampi(used_value, 0, limit)
	var state := "available"
	if used >= limit:
		state = "full"
	elif used <= 0:
		state = "empty"
	return {"kind": kind, "text": "%s %d/%d" % [label, used, limit], "state": state, "used": used, "limit": limit}


func _skill_needs_soul_slot(skill_id: String) -> bool:
	return class_id == "soulbinder" and skill_id == "summon_wisp"


func _skill_needs_living_summon(skill_id: String) -> bool:
	return class_id == "soulbinder" and skill_id == "sacrifice"


func _skill_needs_nearby_trap(skill_id: String) -> bool:
	return class_id == "tinkerer" and skill_id == "hack"


func _nearby_room_trap_count(radius: float) -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var count := 0
	for trap in tree.get_nodes_in_group("room_traps"):
		var node := trap as Node2D
		if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if node.global_position.distance_to(global_position) <= radius:
			count += 1
	return count


func _living_summon_count() -> int:
	if not is_inside_tree():
		return 0
	var tree := get_tree()
	if tree == null:
		return 0
	var count := 0
	for summon in tree.get_nodes_in_group("player_summons"):
		if is_instance_valid(summon) and not summon.is_queued_for_deletion():
			count += 1
	return count


func on_enemy_killed(context: Dictionary = {}) -> void:
	run_kills += 1
	_record_enemy_codex_event(_enemy_codex_defeated, context)
	add_ultimate_charge(15.0)
	if has_passive("quick_finger"):
		_quick_finger_stacks = mini(_quick_finger_stacks + 1, QUICK_FINGER_MAX_STACKS)
		_quick_finger_left = QUICK_FINGER_DURATION_S
		_show_quick_finger_feedback()
	if has_passive("scavenge"):
		var before_resource := resource
		_gain_resource(SCAVENGE_RESOURCE_GAIN)
		var restored := int(round(resource - before_resource))
		if restored > 0:
			_show_scavenge_feedback(restored)
	if has_passive("wind_foot") and _kill_triggers_wind_foot(context):
		_activate_wind_foot()

func on_enemy_seen(context: Dictionary = {}) -> void:
	_record_enemy_codex_event(_enemy_codex_seen, context)

func enemy_codex_context() -> Dictionary:
	return {
		"enemy_codex_seen": _enemy_codex_entries(_enemy_codex_seen),
		"enemy_codex_defeated": _enemy_codex_entries(_enemy_codex_defeated),
	}

func _record_enemy_codex_event(bucket: Dictionary, context: Dictionary) -> void:
	var enemy_id := _enemy_codex_id(context)
	if enemy_id == "":
		return
	var record: Dictionary = bucket.get(enemy_id, {})
	record["id"] = enemy_id
	record["enemy_id"] = enemy_id
	record["name"] = _enemy_codex_label(context, enemy_id)
	record["enemy_name"] = record["name"]
	record["kind"] = _enemy_codex_kind(context)
	record["enemy_kind"] = record["kind"]
	var biome_id := str(context.get("biome_id", context.get("biome", ""))).strip_edges()
	if biome_id != "":
		record["biome_id"] = biome_id
	var biome := str(context.get("biome", "")).strip_edges()
	if biome != "":
		record["biome"] = biome
	record["count"] = int(record.get("count", 0)) + maxi(int(context.get("count", 1)), 1)
	bucket[enemy_id] = record

func _enemy_codex_entries(bucket: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var keys := bucket.keys()
	keys.sort()
	for key in keys:
		var record: Dictionary = bucket.get(key, {})
		if record.is_empty():
			continue
		entries.append(record.duplicate(true))
	return entries

func _enemy_codex_id(context: Dictionary) -> String:
	for key in ["enemy_id", "id"]:
		var id := str(context.get(key, "")).strip_edges()
		if id != "":
			return id
	return ""

func _enemy_codex_label(context: Dictionary, enemy_id: String) -> String:
	for key in ["enemy_name", "name", "label"]:
		var label := str(context.get(key, "")).strip_edges()
		if label != "":
			return label
	return enemy_id.replace("_", " ").capitalize()

func _enemy_codex_kind(context: Dictionary) -> String:
	for key in ["enemy_kind", "kind"]:
		var kind_text := str(context.get(key, "")).strip_edges()
		if kind_text != "":
			return kind_text
	return "enemy"

func _kill_triggers_wind_foot(context: Dictionary) -> bool:
	return bool(context.get("elite", false)) or bool(context.get("marked", false))

func _show_quick_finger_feedback() -> void:
	var old := get_node_or_null("QuickFingerFeedback")
	if old != null:
		old.name = "QuickFingerFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "QuickFingerFeedback"
	label.text = "QUICK FINGER %d/%d" % [_quick_finger_stacks, QUICK_FINGER_MAX_STACKS]
	label.position = Vector2(-32, -48)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.38))
	label.set_meta("passive_id", "quick_finger")
	label.set_meta("stack_count", _quick_finger_stacks)
	label.set_meta("stack_limit", QUICK_FINGER_MAX_STACKS)
	label.set_meta("duration_seconds", QUICK_FINGER_DURATION_S)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_prayer_feedback(heal_amount: int) -> void:
	var old := get_node_or_null("PrayerFeedback")
	if old != null:
		old.name = "PrayerFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "PrayerFeedback"
	label.text = "PRAYER +%d" % heal_amount
	label.position = Vector2(-28, -50)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.86, 1.0, 0.64))
	label.set_meta("passive_id", "prayer")
	label.set_meta("heal_amount", heal_amount)
	label.set_meta("delay_seconds", PRAYER_DELAY_S)
	label.set_meta("heal_pct_per_second", PRAYER_HEAL_PCT_PER_S)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_element_shift_feedback(from_element: String, to_element: String, source: String) -> void:
	var old := get_node_or_null("ElementShiftFeedback")
	if old != null:
		old.name = "ElementShiftFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "ElementShiftFeedback"
	label.text = "%s -> %s" % [from_element.to_upper(), to_element.to_upper()]
	label.position = Vector2(-34, -62)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", _element_feedback_color(to_element))
	label.set_meta("from_element", from_element)
	label.set_meta("to_element", to_element)
	label.set_meta("source", source)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _element_feedback_color(element: String) -> Color:
	match element:
		"fire":
			return Color(1.0, 0.52, 0.28)
		"ice":
			return Color(0.55, 0.9, 1.0)
		"lightning":
			return Color(1.0, 0.9, 0.32)
		"poison":
			return Color(0.58, 1.0, 0.46)
		_:
			return Color(0.9, 0.9, 0.9)

func _show_weakpoint_feedback() -> void:
	var old := get_node_or_null("WeakpointFeedback")
	if old != null:
		old.name = "WeakpointFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "WeakpointFeedback"
	label.text = "WEAKPOINT x1.6"
	label.position = Vector2(-32, -52)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.96, 0.72, 1.0))
	label.set_meta("passive_id", "weakpoint")
	label.set_meta("attack_side", "back")
	label.set_meta("damage_multiplier", WEAKPOINT_BACK_ATTACK_MULT)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_judgement_feedback(target_family: String) -> void:
	var old := get_node_or_null("JudgementFeedback")
	if old != null:
		old.name = "JudgementFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "JudgementFeedback"
	label.text = "JUDGEMENT x1.3"
	label.position = Vector2(-34, -56)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	label.set_meta("passive_id", "judgement")
	label.set_meta("target_family", target_family)
	label.set_meta("damage_multiplier", JUDGEMENT_TARGET_DAMAGE_MULT)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_unyielding_feedback(blocked: int) -> void:
	var old := get_node_or_null("UnyieldingFeedback")
	if old != null:
		old.name = "UnyieldingFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "UnyieldingFeedback"
	label.text = "UNYIELDING -%d" % blocked
	label.position = Vector2(-34, -50)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.68, 0.42))
	label.set_meta("passive_id", "unyielding")
	label.set_meta("blocked_damage", blocked)
	label.set_meta("damage_multiplier", 0.7)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_soul_tether_feedback(blocked: int, summon_count: int) -> void:
	var old := get_node_or_null("SoulTetherFeedback")
	if old != null:
		old.name = "SoulTetherFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "SoulTetherFeedback"
	label.text = "SOUL TETHER -%d" % blocked
	label.position = Vector2(-36, -48)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.72, 0.66, 1.0))
	label.set_meta("passive_id", "soul_tether")
	label.set_meta("blocked_damage", blocked)
	label.set_meta("summon_count", summon_count)
	label.set_meta("damage_multiplier", SOUL_TETHER_OWNER_DAMAGE_MULT)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_iron_skin_feedback(blocked: int) -> void:
	var old := get_node_or_null("IronSkinFeedback")
	if old != null:
		old.name = "IronSkinFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "IronSkinFeedback"
	label.text = "IRON SKIN -%d" % blocked
	label.position = Vector2(-30, -46)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.72, 0.84, 0.94))
	label.set_meta("passive_id", "iron_skin")
	label.set_meta("blocked_damage", blocked)
	label.set_meta("damage_multiplier", IRON_SKIN_DAMAGE_MULT)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_resonance_feedback() -> void:
	var old := get_node_or_null("ResonanceFeedback")
	if old != null:
		old.name = "ResonanceFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "ResonanceFeedback"
	label.text = "RESONANCE +20% SKILL"
	label.position = Vector2(-38, -54)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.62, 0.82, 1.0))
	label.set_meta("passive_id", "resonance")
	label.set_meta("element", equipped_element)
	label.set_meta("duration_seconds", RESONANCE_DURATION_S)
	label.set_meta("skill_damage_multiplier", RESONANCE_SKILL_DAMAGE_MULT)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_scavenge_feedback(restored: int) -> void:
	var old := get_node_or_null("ScavengeFeedback")
	if old != null:
		old.name = "ScavengeFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "ScavengeFeedback"
	label.text = "SCAVENGE +%d %s" % [
		restored,
		"MP" if resource_type == "mana" else "EN",
	]
	label.position = Vector2(-30, -38)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.52, 0.92, 0.62))
	label.set_meta("passive_id", "scavenge")
	label.set_meta("resource_restored", restored)
	label.set_meta("resource_type", resource_type)
	label.set_meta("resource_after", resource)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_siphon_feedback(restored: int, source: String) -> void:
	var old := get_node_or_null("SiphonFeedback")
	if old != null:
		old.name = "SiphonFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "SiphonFeedback"
	label.text = "SIPHON +%d MP" % restored
	label.position = Vector2(-28, -42)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.42, 0.78, 1.0))
	label.set_meta("passive_id", "siphon")
	label.set_meta("source", source)
	label.set_meta("resource_restored", restored)
	label.set_meta("resource_type", resource_type)
	label.set_meta("resource_after", resource)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_heavy_windup_feedback() -> void:
	var old := get_node_or_null("HeavyWindupFeedback")
	if old != null:
		old.name = "HeavyWindupFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "HeavyWindupFeedback"
	label.text = "HEAVY WINDUP x1.5"
	label.position = Vector2(-38, -54)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.38))
	label.set_meta("passive_id", "heavy_windup")
	label.set_meta("damage_multiplier", HEAVY_WINDUP_DAMAGE_MULT)
	label.set_meta("cleave_width_multiplier", HEAVY_WINDUP_CLEAVE_WIDTH_MULT)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_blade_rhythm_feedback(state: String) -> void:
	var old := get_node_or_null("BladeRhythmFeedback")
	if old != null:
		old.name = "BladeRhythmFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "BladeRhythmFeedback"
	label.text = "BLADE RHYTHM %s" % ("READY" if state == "primed" else "USED")
	label.position = Vector2(-34, -58)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color",
		Color(1.0, 0.74, 0.36) if state == "primed" else Color(0.9, 0.9, 0.9))
	label.set_meta("passive_id", "blade_rhythm")
	label.set_meta("state", state)
	label.set_meta("hit_count", BLADE_RHYTHM_HITS if state == "primed" else 0)
	label.set_meta("damage_multiplier", BLADE_RHYTHM_DAMAGE_MULT)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_reflex_feedback(state: String) -> void:
	var old := get_node_or_null("ReflexFeedback")
	if old != null:
		old.name = "ReflexFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "ReflexFeedback"
	label.text = "REFLEX DASH" if state == "dash" else "REFLEX READY"
	label.position = Vector2(-30, -50)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color",
		Color(0.62, 0.9, 1.0) if state == "dash" else Color(0.82, 1.0, 0.72))
	label.set_meta("passive_id", "reflex")
	label.set_meta("state", state)
	label.set_meta("window_seconds", REFLEX_WINDOW_S)
	label.set_meta("cooldown_multiplier", REFLEX_DASH_COOLDOWN_MULT)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _activate_wind_foot() -> void:
	_wind_foot_left = WIND_FOOT_DURATION_S
	set_meta("wind_foot_duration_seconds", WIND_FOOT_DURATION_S)
	set_meta("wind_foot_active", true)
	_show_wind_foot_feedback()

func _show_wind_foot_feedback() -> void:
	var old := get_node_or_null("WindFootFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "WindFootFeedback"
	label.text = "WIND FOOT"
	label.position = Vector2(-24, -42)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0))
	label.set_meta("passive_id", "wind_foot")
	label.set_meta("duration_seconds", WIND_FOOT_DURATION_S)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -10), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func on_melee_attacked(attacker: Node, _incoming_damage: int = 0) -> void:
	if not has_passive("steel_thorns"):
		return
	if attacker == null or not is_instance_valid(attacker) or attacker == self:
		return
	var reflected := maxi(1, int(round(float(max_hp) * STEEL_THORNS_REFLECT_PCT)))
	if attacker.has_method("take_damage"):
		attacker.call("take_damage", reflected)
	elif attacker.has_method("hit"):
		attacker.call("hit", reflected)
	else:
		return
	set_meta("steel_thorns_reflected_damage",
		int(get_meta("steel_thorns_reflected_damage", 0)) + reflected)
	set_meta("steel_thorns_reflect_pct", STEEL_THORNS_REFLECT_PCT)
	_show_steel_thorns_feedback(reflected)

func _show_steel_thorns_feedback(reflected: int) -> void:
	var old := get_node_or_null("SteelThornsFeedback")
	if old != null:
		old.name = "SteelThornsFeedbackOld"
		old.queue_free()
	var label := Label.new()
	label.name = "SteelThornsFeedback"
	label.text = "STEEL THORNS %d" % reflected
	label.position = Vector2(-34, -48)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.46))
	label.set_meta("passive_id", "steel_thorns")
	label.set_meta("reflected_damage", reflected)
	label.set_meta("reflect_pct", STEEL_THORNS_REFLECT_PCT)
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))


func _try_skill() -> void:
	_try_skill_slot(skill, false)

func _try_skill_alt() -> void:
	_try_skill_slot(skill_alt, true)

func _try_skill_slot(skill_data: Dictionary, is_alt: bool) -> void:
	var skill_id := str(skill_data.get("id", ""))
	var slot := "secondary" if is_alt else "primary"
	var cooldown_left := _skill_alt_cd_left if is_alt else _skill_cd_left
	if skill_data.is_empty():
		_emit_skill_blocked(skill_id, "empty", {"slot": slot})
		return
	if cooldown_left > 0.0:
		_emit_skill_blocked(skill_id, "cooldown", {
			"slot": slot,
			"cooldown_left": cooldown_left,
			"cooldown_total": _skill_alt_cd_total if is_alt else _skill_cd_total,
		})
		return
	var cost := float(skill_data.get("cost", 0))
	if resource < cost:
		_emit_skill_blocked(skill_id, "resource", {
			"slot": slot,
			"resource": resource,
			"cost": cost,
		})
		return
	if _skill_needs_soul_slot(skill_id):
		var slots_used := soul_slots_used()
		var slot_limit := soul_slot_limit()
		if slots_used >= slot_limit:
			_emit_skill_blocked(skill_id, "soul_slots", {
				"slot": slot,
				"slots_used": slots_used,
				"slot_limit": slot_limit,
				"slot_cost": 1,
			})
			return
	if _skill_needs_living_summon(skill_id):
		var summon_count := _living_summon_count()
		if summon_count <= 0:
			_emit_skill_blocked(skill_id, "no_summon", {
				"slot": slot,
				"summon_count": summon_count,
			})
			return
	if _skill_needs_nearby_trap(skill_id):
		var trap_count := _nearby_room_trap_count(HACK_TRAP_RANGE)
		if trap_count <= 0:
			_emit_skill_blocked(skill_id, "no_trap", {
				"slot": slot,
				"trap_count": trap_count,
				"range": HACK_TRAP_RANGE,
			})
			return
	var base := skill_base_damage()
	var aim_dir := _aim_dir()
	var executed := SkillRunnerScript.execute(skill_id, {
		"player": self,
		"skill": skill_data,
		"base_damage": base,
		"aim_dir": aim_dir,
		"target_position": _aim_target_position(),
		"element": equipped_element,
		"pet_damage_mult": pet_damage_multiplier(),
		"shield_duration_mult": shield_duration_mult,
		"scene": _scene_parent(),
	})
	if not executed:
		_emit_skill_blocked(skill_id, "failed", {"slot": slot})
		return
	resource -= cost
	resource_changed.emit(resource, max_resource)
	var cooldown_total := maxf(float(skill_data.get("cooldown", 6.0)) * skill_cooldown_multiplier(), 0.25)
	if is_alt:
		_skill_alt_cd_total = cooldown_total
		_skill_alt_cd_left = _skill_alt_cd_total
	else:
		_skill_cd_total = cooldown_total
		_skill_cd_left = _skill_cd_total
	record_skill_use(skill_id)
	_spawn_skill_feedback(skill_id, "skill", slot)
	skill_cast.emit(skill_id, cooldown_total)
	skill_cooldown_changed.emit(skill_id,
		_skill_alt_cd_left if is_alt else _skill_cd_left,
		cooldown_total)

func _emit_skill_blocked(skill_id: String, reason: String, detail: Dictionary) -> void:
	set_meta("last_skill_blocked_id", skill_id)
	set_meta("last_skill_blocked_reason", reason)
	set_meta("last_skill_blocked_slot", str(detail.get("slot", "primary")))
	skill_blocked.emit(skill_id, reason, detail)


func _try_ultimate() -> void:
	var ultimate_id := str(ultimate.get("id", ""))
	if ultimate.is_empty():
		_emit_ultimate_blocked(ultimate_id, "empty", {"charge": ultimate_charge, "cost": 0.0})
		return
	var cost := float(ultimate.get("cost", ultimate_max_charge))
	if ultimate_charge < cost:
		_emit_ultimate_blocked(ultimate_id, "charge", {"charge": ultimate_charge, "cost": cost})
		return
	var base := skill_base_damage()
	var aim_dir := _aim_dir()
	var executed := UltimateRunnerScript.execute(ultimate_id, {
		"player": self,
		"ultimate": ultimate,
		"base_damage": base,
		"aim_dir": aim_dir,
		"target_position": _aim_target_position(),
		"element": equipped_element,
		"pet_damage_mult": pet_damage_multiplier(),
		"scene": _scene_parent(),
	})
	if not executed:
		_emit_ultimate_blocked(ultimate_id, "failed", {"charge": ultimate_charge, "cost": cost})
		return
	ultimate_charge = maxf(ultimate_charge - cost, 0.0)
	ultimate_charge_changed.emit(ultimate_charge, ultimate_max_charge)
	record_skill_use(ultimate_id)
	_spawn_skill_feedback(ultimate_id, "ultimate")
	ultimate_cast.emit(ultimate_id)

func _emit_ultimate_blocked(ultimate_id: String, reason: String, detail: Dictionary) -> void:
	set_meta("last_ultimate_blocked_id", ultimate_id)
	set_meta("last_ultimate_blocked_reason", reason)
	ultimate_blocked.emit(ultimate_id, reason, detail)


func is_invulnerable() -> bool:
	return _iframes_left > 0.0

func add_status(status_name: String, duration: float) -> void:
	if status_name == "" or duration <= 0.0:
		return
	_statuses[status_name] = maxf(duration, float(_statuses.get(status_name, 0.0)))
	set_meta("status_" + status_name + "_left", _statuses[status_name])
	_spawn_player_status_feedback(status_name)

func has_status(status_name: String) -> bool:
	return _statuses.has(status_name)

func current_move_speed() -> float:
	var multiplier := 1.0
	if has_status("chilled"):
		multiplier *= 0.65
	return move_speed * multiplier

func _spawn_player_status_feedback(status_name: String) -> void:
	_spawn_player_status_feedback_text(
		_readable_status_name(status_name),
		status_name,
		"applied",
		float(_statuses.get(status_name, 0.0)))

func _spawn_player_status_feedback_text(
		text: String,
		status_name: String,
		event: String = "feedback",
		duration: float = 0.0,
) -> void:
	var old := get_node_or_null("PlayerStatusFeedback")
	if old != null:
		remove_child(old)
		old.queue_free()
	var label := Label.new()
	label.name = "PlayerStatusFeedback"
	label.text = text
	label.position = Vector2(-18, -52)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", _status_feedback_color(status_name))
	label.set_meta("status_id", status_name)
	label.set_meta("status_event", event)
	label.set_meta("status_duration", duration)
	label.set_meta("status_color_role", status_name)
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -10), 0.42)
	tween.tween_property(label, "modulate:a", 0.0, 0.42)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _readable_status_name(status_name: String) -> String:
	return status_name.replace("_", " ").capitalize()

func _status_feedback_color(status_name: String) -> Color:
	match status_name:
		"burning":
			return Color(1.0, 0.42, 0.24)
		"poisoned":
			return Color(0.55, 1.0, 0.45)
		"chilled":
			return Color(0.55, 0.82, 1.0)
		"cursed":
			return Color(0.9, 0.55, 1.0)
	return Color(1.0, 0.78, 0.35)

func _tick_statuses(delta: float) -> void:
	if _statuses.is_empty():
		return
	var expired: Array[String] = []
	for status_name in _statuses.keys():
		_statuses[status_name] = float(_statuses[status_name]) - delta
		set_meta("status_" + str(status_name) + "_left", maxf(float(_statuses[status_name]), 0.0))
		if float(_statuses[status_name]) <= 0.0:
			expired.append(str(status_name))
	_status_dot_tick += delta
	if _status_dot_tick >= STATUS_DOT_INTERVAL:
		_status_dot_tick -= STATUS_DOT_INTERVAL
		if has_status("burning"):
			take_damage(2, Vector2(1.0e20, 1.0e20), "Burning")
		if has_status("poisoned"):
			take_damage(maxi(1, int(max_hp * 0.01)), Vector2(1.0e20, 1.0e20), "Poisoned")
	for status_name in expired:
		_statuses.erase(status_name)
		remove_meta("status_" + status_name + "_left")
		_spawn_player_status_feedback_text(
			"%s ended" % _readable_status_name(status_name),
			status_name,
			"expired")

func take_damage(
		amount: int,
		source_position: Vector2 = Vector2(1.0e20, 1.0e20),
		source_label: String = "Enemy",
) -> void:
	if _dead:
		return
	if bool(get_meta("fortress_active", false)):
		set_meta("fortress_blocked_damage",
			int(get_meta("fortress_blocked_damage", 0)) + maxi(amount, 0))
		return
	if bool(get_meta("mobile_fortress_active", false)):
		set_meta("mobile_fortress_blocked_damage",
			int(get_meta("mobile_fortress_blocked_damage", 0)) + maxi(amount, 0))
		return
	if is_invulnerable():
		return
	_seconds_since_damage = 0.0
	_passive_heal_accum = 0.0
	var final_damage := _incoming_damage_after_passives(amount)
	final_damage = _incoming_damage_after_weapon(final_damage, source_position)
	_record_last_damage_context(source_label, final_damage)
	if hp - final_damage <= 0 and _revive_charges > 0:
		_revive_charges -= 1
		_revives_used += 1
		set_meta("revives_used", _revives_used)
		set_meta("revive_charges_left", _revive_charges)
		hp = maxi(1, int(round(float(max_hp) * 0.35)))
		_dead = false
		hp_changed.emit(hp, max_hp)
		var revive_context := {
			"revives_used": _revives_used,
			"charges_left": _revive_charges,
			"hp": hp,
			"max_hp": max_hp,
			"source": source_label,
			"prevented_damage": final_damage,
		}
		_show_revive_feedback(revive_context)
		revived.emit(revive_context)
		return
	hp = maxi(hp - final_damage, 0)
	hp_changed.emit(hp, max_hp)
	if final_damage > 0:
		record_damage_taken(source_label, final_damage)
		_play_player_damage_sfx(source_label, final_damage)
		if hp == 0:
			_record_final_hit(source_label, final_damage)
			play_sprite_action("death", 0.35)
			_spawn_death_feedback(source_label, final_damage)
		else:
			play_sprite_action("hurt", 0.18)
		if has_passive("reflex"):
			_reflex_left = REFLEX_WINDOW_S
			set_meta("reflex_window_seconds", REFLEX_WINDOW_S)
			_show_reflex_feedback("ready")
		_hit_pause(0.05, 0.88)
		_spawn_player_damage_number(final_damage)
	if hp == 0 and not _dead:
		_dead = true
		died.emit()

func _record_last_damage_context(source_label: String, amount: int) -> void:
	var label := source_label.strip_edges()
	if label == "":
		label = "Enemy"
	set_meta("last_damage_amount", maxi(amount, 0))
	set_meta("last_damage_source", label)
	set_meta("last_damage_kind", _damage_kind_from_source(label))

func _damage_kind_from_source(source_label: String) -> String:
	var label := source_label.strip_edges().to_lower()
	if label.begins_with("boss:") or label.contains("boss"):
		return "boss"
	if label.begins_with("trap:") or label.contains("trap"):
		return "trap"
	if ["burning", "poisoned", "cursed"].has(label):
		return "status"
	if label.begins_with("enemy:") or label.contains("enemy"):
		return "enemy"
	return "enemy" if label == "" or label == "enemy" else "unknown"

func _show_revive_feedback(context: Dictionary) -> void:
	var old := get_node_or_null("PlayerReviveFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "PlayerReviveFeedback"
	label.text = "Revived | %s | HP %d/%d" % [
		str(context.get("source", "Unknown")),
		int(context.get("hp", hp)),
		int(context.get("max_hp", max_hp)),
	]
	label.position = Vector2(-28, -56)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.66, 1.0, 0.86))
	label.set_meta("revives_used", int(context.get("revives_used", 0)))
	label.set_meta("charges_left", int(context.get("charges_left", 0)))
	label.set_meta("revive_hp", int(context.get("hp", hp)))
	label.set_meta("revive_max_hp", int(context.get("max_hp", max_hp)))
	label.set_meta("revive_source", str(context.get("source", "")))
	label.set_meta("prevented_damage", int(context.get("prevented_damage", 0)))
	add_child(label)
	_play_revive_sfx(context)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -10), 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)

func _play_revive_sfx(context: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.revive_cue(context)
	var old := get_node_or_null("PlayerReviveSfx")
	if old != null:
		old.queue_free()
	var sfx := AudioStreamPlayer.new()
	sfx.name = "PlayerReviveSfx"
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("revive_sound_id", str(cue.get("id", "player_revive")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "player_revive")))
	sfx.set_meta("revive_source", str(cue.get("revive_source", "")))
	sfx.set_meta("revives_used", int(cue.get("revives_used", 0)))
	sfx.set_meta("charges_left", int(cue.get("charges_left", 0)))
	sfx.set_meta("revive_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	add_child(sfx)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _play_player_damage_sfx(source_label: String, amount: int) -> void:
	var kind := _damage_kind_from_source(source_label)
	var cue: Dictionary = AudioCueDBScript.player_damage_cue(kind, source_label, amount)
	var old := get_node_or_null("PlayerDamageSfx")
	if old != null:
		old.queue_free()
	var sfx := AudioStreamPlayer.new()
	sfx.name = "PlayerDamageSfx"
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("player_damage_sound_id", str(cue.get("id", "player_damage_enemy")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "player_damage")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "player_damage")))
	sfx.set_meta("damage_kind", str(cue.get("damage_kind", kind)))
	sfx.set_meta("damage_source", str(cue.get("damage_source", source_label)))
	sfx.set_meta("damage_amount", int(cue.get("damage_amount", amount)))
	sfx.set_meta("player_damage_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	add_child(sfx)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _incoming_damage_after_weapon(amount: int, source_position: Vector2) -> int:
	var weapon := current_weapon()
	if weapon == null or not weapon.has_method("front_block_damage"):
		return amount
	return int(weapon.call("front_block_damage", amount, source_position,
		global_position, _block_facing_dir()))

func _block_facing_dir() -> Vector2:
	var meta_dir = get_meta("block_facing_dir", Vector2.ZERO)
	if meta_dir is Vector2 and meta_dir.length_squared() > 0.0:
		return meta_dir.normalized()
	var aim := _aim_dir()
	if aim.length_squared() > 0.0:
		return aim.normalized()
	if velocity.length_squared() > 1.0:
		return velocity.normalized()
	return Vector2.RIGHT

func _spawn_player_damage_number(amount: int) -> void:
	var old := get_node_or_null("PlayerDamageNumber")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "PlayerDamageNumber"
	label.text = "-%d" % amount
	label.set_meta("feedback_type", "player_damage")
	label.set_meta("damage_amount", amount)
	label.position = Vector2(-10, -28)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.36))
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -14), 0.42)
	tween.tween_property(label, "modulate:a", 0.0, 0.42)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _spawn_death_feedback(source_label: String, amount: int) -> void:
	var old := get_node_or_null("DeathFeedback")
	if old != null:
		old.name = "DeathFeedbackOld"
		old.queue_free()
	var source := source_label.strip_edges()
	if source == "":
		source = "Enemy"
	var label := Label.new()
	label.name = "DeathFeedback"
	label.text = "KO: %s %d" % [source, maxi(amount, 0)]
	label.position = Vector2(-38, -72)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.36))
	label.set_meta("damage_source", source)
	label.set_meta("damage_kind", _damage_kind_from_source(source))
	label.set_meta("damage_amount", maxi(amount, 0))
	add_child(label)
	if not is_inside_tree():
		return
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.55)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _spawn_player_heal_number(amount: int) -> void:
	var old := get_node_or_null("PlayerHealNumber")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "PlayerHealNumber"
	label.text = "+%d" % amount
	label.position = Vector2(-8, -40)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.42, 1.0, 0.58))
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -14), 0.42)
	tween.tween_property(label, "modulate:a", 0.0, 0.42)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _spawn_player_resource_number(amount: int) -> void:
	var old := get_node_or_null("PlayerResourceNumber")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "PlayerResourceNumber"
	label.text = "+%d %s" % [amount, "MP" if resource_type == "mana" else "EN"]
	label.position = Vector2(10, -34)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.45, 0.72, 1.0))
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -12), 0.36)
	tween.tween_property(label, "modulate:a", 0.0, 0.36)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))


func _spawn_skill_feedback(skill_id: String, cast_kind: String = "skill", skill_slot: String = "") -> void:
	var slot := skill_slot if skill_slot != "" else ("ultimate" if cast_kind == "ultimate" else "primary")
	var profile: Dictionary = CombatFxScript.skill_feedback_profile(skill_id)
	var fx := CombatFxScript.spawn_skill_cast(_fx_parent(), global_position, skill_id)
	fx.set_meta("cast_kind", cast_kind)
	fx.set_meta("skill_slot", slot)
	if cast_kind == "ultimate":
		fx.set_meta("ultimate_id", skill_id)
	play_sprite_action("attack", 0.18)
	_play_skill_cast_sfx(skill_id, cast_kind, slot)
	_hit_pause(
		float(profile.get("hit_pause_seconds", 0.08)),
		float(profile.get("hit_pause_scale", 0.82)),
		cast_kind)
	set_meta("hit_pause_skill_style", str(profile.get("style", "generic")))
	set_meta("hit_pause_skill_impact", str(profile.get("impact_shape", "pulse")))
	set_meta("hit_pause_skill_impact_cue", str(profile.get("impact_cue", "")))
	set_meta("hit_pause_skill_feel_tier", str(profile.get("feel_tier", "steady")))
	set_meta("last_skill_cast_slot", slot)

func _update_weapon_charge_feedback(ratio: float, should_show: bool = true) -> void:
	var clamped := clampf(ratio, 0.0, 1.0)
	var meter := get_node_or_null("WeaponChargeMeter") as Node2D
	if meter == null:
		meter = Node2D.new()
		meter.name = "WeaponChargeMeter"
		meter.position = Vector2(-13, -34)
		add_child(meter)
		var bg := ColorRect.new()
		bg.name = "WeaponChargeMeterBg"
		bg.position = Vector2.ZERO
		bg.size = Vector2(26, 4)
		bg.color = Color(0.04, 0.05, 0.06, 0.72)
		meter.add_child(bg)
		var fill := ColorRect.new()
		fill.name = "WeaponChargeMeterFill"
		fill.position = Vector2(1, 1)
		fill.size = Vector2.ZERO
		meter.add_child(fill)
	meter.visible = should_show and clamped > 0.0
	meter.set_meta("charge_ratio", clamped)
	var fill := meter.get_node_or_null("WeaponChargeMeterFill") as ColorRect
	if fill != null:
		fill.size = Vector2(24.0 * clamped, 2.0)
		fill.color = Color(0.48, 0.95, 0.5, 0.95) if clamped >= 1.0 \
			else Color(0.55, 0.82, 1.0, 0.88)

func _update_active_reload_window_feedback() -> void:
	var status := active_reload_window_status()
	var key := "%s:%s:%s" % [
		str(status.get("weapon_id", "")),
		str(status.get("enabled", false)),
		str(status.get("in_window", false)),
	]
	if key == _last_active_reload_window_key:
		return
	_last_active_reload_window_key = key
	active_reload_window_changed.emit(status)

func _play_skill_cast_sfx(skill_id: String, cast_kind: String = "skill", skill_slot: String = "") -> void:
	var old := get_node_or_null("SkillCastSfx")
	if old != null:
		_release_skill_cast_sfx(old)
	var sfx := AudioStreamPlayer.new()
	sfx.name = "SkillCastSfx"
	var cue: Dictionary = AudioCueDBScript.skill_cast_cue(skill_id)
	var profile: Dictionary = CombatFxScript.skill_feedback_profile(skill_id)
	var family := str(cue.get("family", "generic"))
	var style := str(profile.get("style", "generic"))
	var cast_label := str(profile.get("cast_label", skill_id))
	var sound_id := str(cue.get("id", "generic_cast"))
	var frequency := float(cue.get("frequency", 500.0))
	var slot := skill_slot if skill_slot != "" else ("ultimate" if cast_kind == "ultimate" else "primary")
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("skill_id", skill_id)
	sfx.set_meta("cast_kind", cast_kind)
	sfx.set_meta("skill_slot", slot)
	if cast_kind == "ultimate":
		sfx.set_meta("ultimate_id", skill_id)
	sfx.set_meta("skill_family", family)
	sfx.set_meta("skill_style", style)
	sfx.set_meta("skill_cast_label", cast_label)
	sfx.set_meta("skill_telegraph_shape", str(profile.get("telegraph_shape", "self")))
	sfx.set_meta("skill_impact_shape", str(profile.get("impact_shape", "pulse")))
	sfx.set_meta("skill_impact_cue", str(profile.get("impact_cue", "")))
	sfx.set_meta("skill_cooldown_icon", str(profile.get("cooldown_icon", "skill")))
	sfx.set_meta("skill_feedback_hint", str(profile.get("feedback_hint", "")))
	sfx.set_meta("skill_audio_intensity", str(profile.get("audio_intensity", "medium")))
	sfx.set_meta("skill_feel_tier", str(profile.get("feel_tier", "steady")))
	sfx.set_meta("skill_cooldown_hint", str(profile.get("cooldown_hint", "")))
	sfx.set_meta("skill_sound_id", sound_id)
	sfx.set_meta("audio_cue_label", str(cue.get("label", sound_id)))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "cast")))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("skill_sound_frequency", frequency)
	sfx.set_meta("playback_requested", true)
	set_meta("last_cast_sound_id", sound_id)
	set_meta("last_skill_cast_label", cast_label)
	set_meta("last_skill_style", style)
	set_meta("last_skill_impact_cue", str(profile.get("impact_cue", "")))
	set_meta("last_skill_feel_tier", str(profile.get("feel_tier", "steady")))
	set_meta("last_skill_cast_slot", slot)
	if cast_kind == "ultimate":
		set_meta("last_ultimate_sound_id", sound_id)
	else:
		set_meta("last_skill_sound_id", sound_id)
	add_child(sfx)
	if DisplayServer.get_name() != "headless":
		sfx.play()
	call_deferred("_release_skill_cast_sfx", sfx)

func _release_skill_cast_sfx(node: Node, should_queue_free: bool = true) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is AudioStreamPlayer:
		var sfx := node as AudioStreamPlayer
		sfx.stop()
		sfx.stream = null
	if should_queue_free:
		node.queue_free()

func _hit_pause(seconds: float, scale_value: float, source: String = "player") -> void:
	var feedback_scale := clampf(_accessibility_hit_pause_scale, 0.0, 1.0)
	var adjusted_seconds := seconds * feedback_scale
	var adjusted_scale := lerpf(1.0, scale_value, feedback_scale)
	set_meta("hit_pause_feedback", true)
	set_meta("hit_pause_seconds", adjusted_seconds)
	set_meta("hit_pause_scale", adjusted_scale)
	set_meta("hit_pause_accessibility_scale", feedback_scale)
	set_meta("hit_pause_source", source)
	_pulse_camera_impact(adjusted_seconds, adjusted_scale, source)
	if not is_inside_tree() or adjusted_seconds <= 0.0:
		return
	Engine.time_scale = minf(Engine.time_scale, adjusted_scale)
	get_tree().create_timer(adjusted_seconds, true, false, true).timeout.connect(func() -> void:
		Engine.time_scale = 1.0)

func _pulse_camera_impact(seconds: float, scale_value: float, source: String) -> void:
	if not is_inside_tree():
		return
	_setup_camera()
	if _camera == null:
		return
	if _screen_shake_scale <= 0.0 or seconds <= 0.0:
		set_meta("camera_impact_suppressed", true)
		_camera.set_meta("camera_impact_active", false)
		return
	set_meta("camera_impact_suppressed", false)
	var duration := maxf(seconds, 0.03)
	var strength := clampf(
		(1.0 - scale_value) * 24.0 + seconds * 8.0,
		CAMERA_IMPACT_MIN_STRENGTH,
		CAMERA_IMPACT_MAX_STRENGTH) * _screen_shake_scale
	_camera_impact_serial += 1
	var serial := _camera_impact_serial
	var impact_offset := Vector2(strength, -strength * 0.5)
	_camera.offset = impact_offset
	_camera.set_meta("camera_impact_active", true)
	_camera.set_meta("camera_impact_source", source)
	_camera.set_meta("camera_impact_strength", strength)
	_camera.set_meta("camera_impact_seconds", duration)
	set_meta("camera_impact_feedback", true)
	set_meta("camera_impact_source", source)
	set_meta("camera_impact_strength", strength)
	get_tree().create_timer(duration, true, false, true).timeout.connect(func() -> void:
		if _camera_impact_serial != serial or _camera == null:
			return
		_camera.offset = Vector2.ZERO
		_camera.set_meta("camera_impact_active", false))

func _start_dash(dir: Vector2) -> void:
	var free_dash := _wind_foot_left > 0.0
	var reflex_refund := not free_dash and has_passive("reflex") and _reflex_left > 0.0
	_dash_dir = dir.normalized()
	_dash_time_left = dash_duration
	_iframes_left = dash_iframes
	_dash_cd_left = 0.0 if free_dash else dash_cooldown
	if reflex_refund:
		_dash_cd_left *= REFLEX_DASH_COOLDOWN_MULT
		_reflex_left = 0.0
		set_meta("reflex_dash_refunded", true)
		set_meta("reflex_dash_cooldown_mult", REFLEX_DASH_COOLDOWN_MULT)
		_show_reflex_feedback("dash")
	set_meta("wind_foot_free_dash", free_dash)
	if free_dash:
		set_meta("wind_foot_free_dash_left", _wind_foot_left)
	dash_cooldown_changed.emit(_dash_cd_left, dash_cooldown)
	CombatFxScript.spawn_dash_ghost(_fx_parent(), _sprite, global_position,
		_sprite.flip_h if _sprite != null else false)


func _fx_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return self
	return tree.current_scene if tree.current_scene != null else tree.root

func _scene_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return self
	return tree.current_scene if tree.current_scene != null else tree.root


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func add_key(amount: int) -> void:
	silver_keys += maxi(amount, 0)
	key_changed.emit(silver_keys)

func spend_key(amount: int = 1) -> bool:
	var cost := maxi(amount, 0)
	if silver_keys < cost:
		return false
	silver_keys -= cost
	key_changed.emit(silver_keys)
	return true

func add_meta_currency(currency_id: String, amount: int) -> void:
	var safe_amount := maxi(amount, 0)
	if safe_amount <= 0:
		return
	var normalized := _normalized_meta_currency_id(currency_id)
	var total := 0
	match normalized:
		"soul_shards":
			soul_shards += safe_amount
			total = soul_shards
		"element_cores":
			element_cores += safe_amount
			total = element_cores
		"rune_dust":
			rune_dust += safe_amount
			total = rune_dust
		"blueprints":
			blueprints += safe_amount
			total = blueprints
		_:
			return
	if has_passive("siphon") and normalized == "element_cores":
		var before := resource
		_gain_resource(SIPHON_MANA_RESTORE)
		var restored := int(round(resource - before))
		if restored > 0:
			set_meta("siphon_mana_restored",
				int(get_meta("siphon_mana_restored", 0)) + restored)
			set_meta("siphon_source", normalized)
			_show_siphon_feedback(restored, normalized)
	meta_currency_changed.emit(normalized, safe_amount, total)

func _normalized_meta_currency_id(currency_id: String) -> String:
	match currency_id:
		"soul_shard":
			return "soul_shards"
		"element_core":
			return "element_cores"
		"blueprint":
			return "blueprints"
		_:
			return currency_id


func run_rewards() -> Dictionary:
	return {
		"gold": gold,
		"soul_shards": soul_shards,
		"element_cores": element_cores,
		"rune_dust": rune_dust,
		"blueprints": blueprints,
	}

func run_kill_count() -> int:
	return run_kills


func heal(amount: int) -> void:
	if _dead or hp <= 0:
		return
	var old_hp := hp
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)
	var restored := hp - old_hp
	if restored > 0:
		_spawn_player_heal_number(restored)


func element_damage_multiplier(element: String) -> float:
	var mult := 1.0 + float(element_damage_bonus.get(element, 0.0))
	if _chaos_surge_left > 0.0 and element == _chaos_surge_element:
		mult += CHAOS_SURGE_ELEMENT_DAMAGE_BONUS
	return mult

func record_upgrade(
		upgrade_id: String,
		display_name: String,
		tags: Array = [],
		decision_reason: String = "",
) -> void:
	_upgrade_stacks[upgrade_id] = int(_upgrade_stacks.get(upgrade_id, 0)) + 1
	_upgrade_names[upgrade_id] = display_name
	if not tags.is_empty():
		_upgrade_tags[upgrade_id] = _normalized_upgrade_tags(tags)
	_upgrade_history.append(display_name)
	var reason := decision_reason.strip_edges()
	_upgrade_decision_history.append("%s (%s)" % [display_name, reason] if reason != "" else display_name)
	_apply_upgrade_set_bonuses()
	_record_power_milestone()
	upgrades_changed.emit(upgrade_summary())

func upgrade_stack_count(upgrade_id: String) -> int:
	return int(_upgrade_stacks.get(upgrade_id, 0))

func upgrade_count() -> int:
	return _upgrade_history.size()

func upgrade_history_count() -> int:
	return _upgrade_history.size()

func run_power_tier() -> String:
	var count := upgrade_count()
	if count <= 0:
		return "Tier 0"
	if count <= 2:
		return "Tier I"
	if count <= 5:
		return "Tier II"
	if count <= 8:
		return "Tier III"
	return "Tier IV"

func next_power_milestone_hint() -> String:
	var count := upgrade_count()
	var next_tier := ""
	var next_pick_count := 0
	if count <= 0:
		next_tier = "Tier I"
		next_pick_count = 1
	elif count <= 2:
		next_tier = "Tier II"
		next_pick_count = 3
	elif count <= 5:
		next_tier = "Tier III"
		next_pick_count = 6
	elif count <= 8:
		next_tier = "Tier IV"
		next_pick_count = 9
	else:
		return "Max power tier reached"
	var remaining := maxi(next_pick_count - count, 0)
	return "Next: %s in %d %s" % [
		next_tier,
		remaining,
		"pick" if remaining == 1 else "picks",
	]

func run_power_arc_summary(max_tags: int = 3) -> String:
	var picks := upgrade_count()
	var archetype := build_archetype_summary()
	var text := "%d %s | %s | %s" % [
		picks,
		"pick" if picks == 1 else "picks",
		run_power_tier(),
		archetype,
	]
	var tags := upgrade_tag_summary(max_tags)
	if tags != "" and tags != "None":
		text += " | %s" % tags
	return text

func run_stat_summary() -> String:
	var parts: Array[String] = []
	if damage_mult > 1.001:
		parts.append("Damage x%.2f" % damage_mult)
	if pet_damage_mult > 1.001:
		parts.append("Pet x%.1f" % pet_damage_mult)
	if shield_duration_mult > 1.001:
		parts.append("Shield x%.1f" % shield_duration_mult)
	if dash_cooldown < 1.199:
		parts.append("Dash %.1fs" % dash_cooldown)
	if projectile_bonus > 0:
		parts.append("Projectiles +%d" % projectile_bonus)
	if weapon_cooldown_upgrade_mult < 0.999:
		parts.append("Weapon CD x%.2f" % weapon_cooldown_upgrade_mult)
	if skill_cooldown_upgrade_mult < 0.999:
		parts.append("Skill CD x%.2f" % skill_cooldown_upgrade_mult)
	if ultimate_charge_gain_mult > 1.001:
		parts.append("Ult charge x%.2f" % ultimate_charge_gain_mult)
	return " | ".join(parts)

func upgrade_build_tags() -> Array[String]:
	var tags := {}
	for upgrade_id in _upgrade_stacks.keys():
		var stack_count := int(_upgrade_stacks.get(upgrade_id, 0))
		for raw_tag in _upgrade_tags.get(upgrade_id, []):
			var tag := str(raw_tag)
			if tag == "":
				continue
			tags[tag] = int(tags.get(tag, 0)) + stack_count
	var ranked: Array[Dictionary] = []
	for tag in tags.keys():
		ranked.append({"tag": str(tag), "score": int(tags[tag])})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := int(a["score"])
		var score_b := int(b["score"])
		if score_a != score_b:
			return score_a > score_b
		return str(a["tag"]) < str(b["tag"]))
	var out: Array[String] = []
	for entry in ranked:
		out.append(str(entry["tag"]))
	return out

func upgrade_tag_stack_count(tag: String) -> int:
	var total := 0
	for upgrade_id in _upgrade_stacks.keys():
		if not Array(_upgrade_tags.get(upgrade_id, [])).has(tag):
			continue
		total += int(_upgrade_stacks.get(upgrade_id, 0))
	return total

func upgrade_set_bonus_summary() -> String:
	if _upgrade_set_bonuses.is_empty():
		return "None"
	var parts: Array[String] = []
	for bonus_id in _upgrade_set_bonuses.keys():
		parts.append(str(_upgrade_set_bonuses[bonus_id]))
	parts.sort()
	return " / ".join(parts)

func _apply_upgrade_set_bonuses() -> void:
	# ponytail: only early tag set bonuses are live; add a tiny table here
	# when more tag sets need real stat effects.
	if not _upgrade_set_bonuses.has("damage_3") and upgrade_tag_stack_count("damage") >= 3:
		damage_mult += 0.08
		_upgrade_set_bonuses["damage_3"] = "Damage x3 +8% dmg"
	if not _upgrade_set_bonuses.has("mobility_3") and upgrade_tag_stack_count("mobility") >= 3:
		dash_cooldown = maxf(dash_cooldown * 0.92, 0.25)
		_upgrade_set_bonuses["mobility_3"] = "Mobility x3 -8% dash CD"
	if not _upgrade_set_bonuses.has("element_3") and upgrade_tag_stack_count("element") >= 3:
		for element in ElementSystem.ELEMENTS:
			element_damage_bonus[element] = float(element_damage_bonus.get(element, 0.0)) + 0.06
		_upgrade_set_bonuses["element_3"] = "Element x3 +6% elem dmg"
	if not _upgrade_set_bonuses.has("pet_3") and upgrade_tag_stack_count("pet") >= 3:
		pet_damage_mult += 0.12
		_upgrade_set_bonuses["pet_3"] = "Pet x3 +12% pet dmg"
	if not _upgrade_set_bonuses.has("shield_3") and upgrade_tag_stack_count("shield") >= 3:
		shield_duration_mult += 0.10
		_upgrade_set_bonuses["shield_3"] = "Shield x3 +10% shield dur"
	if not _upgrade_set_bonuses.has("projectile_3") and upgrade_tag_stack_count("projectile") >= 3:
		projectile_bonus += 1
		_upgrade_set_bonuses["projectile_3"] = "Projectile x3 +1 projectile"
	if not _upgrade_set_bonuses.has("skill_3") and upgrade_tag_stack_count("skill") >= 3:
		skill_cooldown_upgrade_mult = maxf(skill_cooldown_upgrade_mult * 0.92, 0.55)
		_upgrade_set_bonuses["skill_3"] = "Skill x3 -8% skill CD"
	if not _upgrade_set_bonuses.has("resource_3") and upgrade_tag_stack_count("resource") >= 3:
		max_resource += 10.0
		resource = minf(resource + 10.0, max_resource)
		ultimate_charge_gain_mult += 0.1
		resource_changed.emit(resource, max_resource)
		_upgrade_set_bonuses["resource_3"] = "Resource x3 +10 res / +10% ult charge"

func upgrade_tag_summary(max_tags: int = 6) -> String:
	var tags := upgrade_build_tags()
	if tags.is_empty():
		return "None"
	var parts: Array[String] = []
	for i in mini(max_tags, tags.size()):
		parts.append(str(tags[i]).replace("_", " ").capitalize())
	return " / ".join(parts)

func build_archetype_summary() -> String:
	var tags := upgrade_build_tags()
	if tags.is_empty():
		return "Fresh Run"
	var tag_set := {}
	for tag in tags:
		tag_set[str(tag)] = true
	for element in ["fire", "ice", "lightning", "poison"]:
		if tag_set.has(element) and tag_set.has("damage"):
			return "%s Damage" % element.capitalize()
	if tag_set.has("socket") and tag_set.has("projectile"):
		return "Socket Engineer"
	if tag_set.has("pet") or tag_set.has("summon"):
		return "Summoner"
	if tag_set.has("shield") or tag_set.has("defense"):
		return "Shield Tank"
	if tag_set.has("dash") or tag_set.has("mobility"):
		return "Dash Mobility"
	var first := str(tags[0]).replace("_", " ").capitalize()
	var second := str(tags[1]).replace("_", " ").capitalize() if tags.size() > 1 else "Build"
	return "%s %s" % [first, second]

func rune_socket_summary() -> String:
	var socket_parts: Array[String] = []
	var rune_parts: Array[String] = []
	var socket_used := socket_upgrade_count()
	var socket_max := socket_capacity()
	for upgrade_id in _upgrade_stacks.keys():
		var tags: Array = _upgrade_tags.get(upgrade_id, [])
		var count := int(_upgrade_stacks.get(upgrade_id, 0))
		var name := str(_upgrade_names.get(upgrade_id, upgrade_id))
		if tags.has("socket"):
			socket_parts.append(_stacked_name(name, count))
		if tags.has("element"):
			for element in ["fire", "ice", "lightning", "poison"]:
				if tags.has(element):
					rune_parts.append("%s x%d" % [element.capitalize(), count])
					break
	socket_parts.sort()
	rune_parts.sort()
	var parts: Array[String] = ["Sockets %d/%d" % [socket_used, socket_max]]
	if not rune_parts.is_empty():
		parts.append("Runes %s" % " / ".join(rune_parts))
	if not socket_parts.is_empty():
		parts.append("Socket Upgrades: %s" % " / ".join(socket_parts))
	return " | ".join(parts)

func _stacked_name(display_name: String, count: int) -> String:
	return "%s x%d" % [display_name, count] if count > 1 else display_name

func _normalized_upgrade_tags(tags: Array) -> Array[String]:
	var seen := {}
	var out: Array[String] = []
	for raw_tag in tags:
		var tag := str(raw_tag)
		if tag == "" or seen.has(tag):
			continue
		seen[tag] = true
		out.append(tag)
	return out

func upgrade_summary() -> String:
	if _upgrade_stacks.is_empty():
		return "None"
	var parts: Array[String] = []
	for id in _upgrade_stacks.keys():
		var name := str(_upgrade_names.get(id, id))
		var count := int(_upgrade_stacks[id])
		parts.append("%s x%d" % [name, count] if count > 1 else name)
	parts.sort()
	return ", ".join(parts)

func upgrade_history_summary(max_items: int = 6) -> String:
	if _upgrade_history.is_empty():
		return "None"
	var start := maxi(_upgrade_history.size() - max_items, 0)
	return " -> ".join(_upgrade_history.slice(start))

func power_milestone_summary(max_items: int = 6) -> String:
	if _power_milestones.is_empty():
		return "None"
	var start := maxi(_power_milestones.size() - max_items, 0)
	return " -> ".join(_power_milestones.slice(start))

func _record_power_milestone() -> void:
	var tier := run_power_tier()
	if tier == "Tier 0" or tier == _last_power_milestone_tier:
		return
	_last_power_milestone_tier = tier
	_power_milestones.append("%s @%d" % [tier, upgrade_count()])

func upgrade_decision_history_summary(max_items: int = 6) -> String:
	if _upgrade_decision_history.is_empty():
		return "None"
	var start := maxi(_upgrade_decision_history.size() - max_items, 0)
	return " -> ".join(_upgrade_decision_history.slice(start))

func record_shop_purchase(item_name: String, decision_reason: String = "") -> void:
	var name := item_name.strip_edges()
	if name == "":
		name = "Item"
	var reason := decision_reason.strip_edges()
	_shop_purchase_history.append("%s (%s)" % [name, reason] if reason != "" else name)

func shop_purchase_history_summary(max_items: int = 6) -> String:
	if _shop_purchase_history.is_empty():
		return "None"
	var start := maxi(_shop_purchase_history.size() - max_items, 0)
	return " -> ".join(_shop_purchase_history.slice(start))

func record_pickup(label: String) -> void:
	var clean := label.strip_edges()
	if clean == "":
		return
	_pickup_history.append(clean)

func pickup_history_summary(max_items: int = 6) -> String:
	if _pickup_history.is_empty():
		return "None"
	var start := maxi(_pickup_history.size() - max_items, 0)
	return " -> ".join(_pickup_history.slice(start))

func record_room_decision(label: String, reason: String = "") -> void:
	var name := label.strip_edges()
	if name == "":
		return
	var clean_reason := reason.strip_edges()
	_room_decision_history.append(
		"%s (%s)" % [name, clean_reason] if clean_reason != "" else name)

func room_decision_history_summary(max_items: int = 6) -> String:
	if _room_decision_history.is_empty():
		return "None"
	var entries: Array[String] = []
	var counts: Array[int] = []
	for entry in _room_decision_history:
		if not entries.is_empty() and entries.back() == entry:
			counts[counts.size() - 1] += 1
		else:
			entries.append(entry)
			counts.append(1)
	var parts: Array[String] = []
	for i in entries.size():
		parts.append("%s x%d" % [entries[i], counts[i]] if counts[i] > 1 else entries[i])
	var start := maxi(parts.size() - max_items, 0)
	return " -> ".join(parts.slice(start))

func record_damage_taken(source_label: String, amount: int) -> void:
	var damage := maxi(amount, 0)
	if damage <= 0:
		return
	var label := source_label.strip_edges()
	if label == "":
		label = "Damage"
	_damage_taken_by_source[label] = int(_damage_taken_by_source.get(label, 0)) + damage

func total_damage_taken() -> int:
	var total := 0
	for amount in _damage_taken_by_source.values():
		total += maxi(int(amount), 0)
	return total

func damage_taken_summary(max_items: int = 4) -> String:
	if _damage_taken_by_source.is_empty():
		return "None"
	var entries: Array[Dictionary] = []
	for raw_label in _damage_taken_by_source.keys():
		var label := str(raw_label)
		entries.append({
			"label": label,
			"damage": int(_damage_taken_by_source.get(label, 0)),
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var damage_a := int(a.get("damage", 0))
		var damage_b := int(b.get("damage", 0))
		if damage_a != damage_b:
			return damage_a > damage_b
		return str(a.get("label", "")) < str(b.get("label", "")))
	var parts: Array[String] = []
	for i in mini(max_items, entries.size()):
		var entry := entries[i]
		parts.append("%s %d" % [str(entry.get("label", "")), int(entry.get("damage", 0))])
	return " / ".join(parts)

func _record_final_hit(source_label: String, amount: int) -> void:
	var label := source_label.strip_edges()
	if label == "":
		label = "Damage"
	_final_hit_summary = "%s %d" % [label, maxi(amount, 0)]

func final_hit_summary() -> String:
	return _final_hit_summary if _final_hit_summary != "" else "None"

func survival_summary() -> String:
	var parts: Array[String] = []
	if _revives_used > 0:
		parts.append("Revived x%d" % _revives_used)
	var blocked := int(get_meta("fortress_blocked_damage", 0)) \
		+ int(get_meta("mobile_fortress_blocked_damage", 0))
	if blocked > 0:
		parts.append("Blocked %d" % blocked)
	return " / ".join(parts) if not parts.is_empty() else "None"

func record_skill_use(skill_id: String) -> void:
	var id := skill_id.strip_edges()
	if id == "":
		return
	_skill_usage_counts[id] = int(_skill_usage_counts.get(id, 0)) + 1

func skill_usage_summary(max_items: int = 6) -> String:
	if _skill_usage_counts.is_empty():
		return "None"
	var entries: Array[Dictionary] = []
	for raw_id in _skill_usage_counts.keys():
		var id := str(raw_id)
		entries.append({
			"id": id,
			"label": _skill_usage_label(id),
			"count": int(_skill_usage_counts.get(id, 0)),
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var count_a := int(a.get("count", 0))
		var count_b := int(b.get("count", 0))
		if count_a != count_b:
			return count_a > count_b
		return str(a.get("label", "")) < str(b.get("label", "")))
	var parts: Array[String] = []
	for i in mini(max_items, entries.size()):
		var entry := entries[i]
		parts.append("%s x%d" % [str(entry.get("label", "")), int(entry.get("count", 0))])
	return " / ".join(parts)

func record_element_combo(info: Dictionary) -> void:
	var id := str(info.get("id", "")).strip_edges()
	if id == "":
		return
	var name := str(info.get("name", id.replace("_", " ").capitalize())).strip_edges()
	if name == "":
		name = id.replace("_", " ").capitalize()
	var entry: Dictionary = _element_combo_counts.get(id, {"label": name, "count": 0})
	entry["label"] = name
	entry["count"] = int(entry.get("count", 0)) + 1
	_element_combo_counts[id] = entry
	var payload := info.duplicate(true)
	payload["id"] = id
	payload["name"] = name
	payload["label"] = name
	payload["count"] = int(entry.get("count", 0))
	element_combo_recorded.emit(payload, element_combo_count())

func element_combo_count() -> int:
	var total := 0
	for entry in _element_combo_counts.values():
		if entry is Dictionary:
			total += int((entry as Dictionary).get("count", 0))
	return total

func element_combo_summary(max_items: int = 6) -> String:
	if _element_combo_counts.is_empty():
		return "None"
	var entries: Array[Dictionary] = []
	for raw_id in _element_combo_counts.keys():
		var entry: Dictionary = _element_combo_counts[raw_id]
		entries.append({
			"id": str(raw_id),
			"label": str(entry.get("label", raw_id)),
			"count": int(entry.get("count", 0)),
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var count_a := int(a.get("count", 0))
		var count_b := int(b.get("count", 0))
		if count_a != count_b:
			return count_a > count_b
		return str(a.get("label", "")) < str(b.get("label", "")))
	var parts: Array[String] = []
	for i in mini(max_items, entries.size()):
		var entry := entries[i]
		parts.append("%s x%d" % [str(entry.get("label", "")), int(entry.get("count", 0))])
	return " / ".join(parts)

func _skill_usage_label(skill_id: String) -> String:
	var profile: Dictionary = CombatFxScript.skill_feedback_profile(skill_id)
	var label := str(profile.get("cast_label", "")).strip_edges()
	if label != "":
		return label
	return skill_id.replace("_", " ").capitalize()

## First pickup fills the second slot; later pickups replace the active slot.
func pickup_weapon(id: String) -> void:
	var weapon := current_weapon()
	if weapon == null:
		return
	if _weapons.size() < _max_weapon_slots:
		var added := Weapon.new()
		add_child(added)
		added.equip(id)
		_weapons.append(added)
		_active = _weapons.size() - 1
		weapon_changed.emit(added.display_name())
		var slot_text := "Slot %d/%d" % [_active + 1, _max_weapon_slots]
		var tool_belt_slot := has_passive("tool_belt") and _max_weapon_slots == 3 and _active + 1 == 3
		var feedback_text := "Added: %s (%s)" % [added.display_name(), slot_text]
		var feedback_meta := {
			"weapon_slot_count": _weapons.size(),
			"weapon_slot_max": _max_weapon_slots,
		}
		if tool_belt_slot:
			feedback_text = "Added: %s (TOOL BELT %s)" % [added.display_name(), slot_text]
			feedback_meta["passive_id"] = "tool_belt"
		_show_weapon_pickup_feedback(feedback_text, feedback_meta)
		print("Weapon added: %s" % added.display_name())
		return
	var old_name := weapon.display_name()
	var slot_index := _active + 1
	weapon.equip(id)
	weapon_changed.emit(weapon.display_name())
	_show_weapon_pickup_feedback("Swapped: %s -> %s (Replaced slot %d/%d)" % [old_name, weapon.display_name(), slot_index, _max_weapon_slots])
	print("Weapon swapped: %s -> %s" % [old_name, weapon.display_name()])

func _show_weapon_pickup_feedback(text: String, metadata: Dictionary = {}) -> void:
	set_meta("last_weapon_pickup_feedback", text)
	var old := get_node_or_null("WeaponPickupFeedback")
	if old != null:
		remove_child(old)
		old.queue_free()
	var label := Label.new()
	label.name = "WeaponPickupFeedback"
	label.text = text
	label.position = Vector2(-32, -58)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.34))
	for key in metadata.keys():
		label.set_meta(str(key), metadata[key])
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -10), 0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.55)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))
