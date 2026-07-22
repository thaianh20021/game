class_name HUD
extends CanvasLayer
## In-run HUD: HP + resource bars, active weapon/element, gold, floor and a
## fog-of-war minimap. Built in code until proper UI scenes/art exist.

const BAR_W := 100.0
const BAR_H := 8.0
const BOSS_BAR_W := 160.0
const CLASS_RESOURCE_AVAILABLE_COLOR := Color(0.58, 0.95, 1.0)
const CLASS_RESOURCE_EMPTY_COLOR := Color(0.55, 0.68, 0.76)
const CLASS_RESOURCE_FULL_COLOR := Color(1.0, 0.84, 0.42)
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")

var _player: Player
var _floor_ctrl: FloorController
var _hp_fill: ColorRect
var _hp_heart_icon: TextureRect
var _hp_label: Label
var _low_hp_label: Label
var _damage_flash_label: Label
var _damage_type_icon: TextureRect
var _damage_vignette: ColorRect
var _revive_flash_label: Label
var _resource_icon: TextureRect
var _resource_fill: ColorRect
var _weapon_label: Label
var _weapon_flash_label: Label
var _active_reload_window_label: Label
var _gold_flash_label: Label
var _key_flash_label: Label
var _meta_currency_flash_label: Label
var _meta_bonus_flash_label: Label
var _biome_mastery_flash_label: Label
var _power_tier_flash_label: Label
var _gold_icon: TextureRect
var _gold_label: Label
var _floor_label: Label
var _room_label: Label
var _objective_label: Label
var _objective_next_label: Label
var _objective_flash_label: Label
var _room_mastery_flash_label: Label
var _skill_label: Label
var _skill_cd_badge: Label
var _skill_cd_fill: ColorRect
var _skill_alt_label: Label
var _skill_alt_cd_badge: Label
var _skill_alt_cd_fill: ColorRect
var _dash_label: Label
var _dash_cd_fill: ColorRect
var _skill_cast_flash_label: Label
var _skill_cast_pulse: ColorRect
var _skill_was_cooling: Dictionary = {}
var _dash_was_cooling := false
var _ultimate_was_ready := false
var _last_power_tier := ""
var _ultimate_label: Label
var _ultimate_charge_fill: ColorRect
var _build_label: Label
var _reward_path_label: Label
var _run_decision_label: Label
var _run_stats_label: Label
var _run_route_label: Label
var _route_choice_labels: Array[Label] = []
var _route_choice_icons: Array[TextureRect] = []
var _loot_pity_label: Label
var _run_seed_label: Label
var _run_mode_label: Label
var _run_modifier_label: Label
var _run_modifier_goal_label: Label
var _controls_hint_label: Label
var _class_resource_label: Label
var _element_combo_counter_label: Label
var _element_combo_flash_label: Label
var _class_resource_last_kind := ""
var _class_resource_last_state := ""
var _class_resource_full_pulse_count := 0
var _status_label: Label
var _boss_bg: ColorRect
var _boss_fill: ColorRect
var _boss_label: Label
var _boss_phase_flash_label: Label
var _boss_enrage_warning_label: Label
var _boss_pattern_cue_label: Label
var _boss_attack_flash_label: Label
var _boss_last_attack_label: Label
var _minimap: Minimap
var _last_hp_current := -1
var _last_gold_total := -1
var _last_key_total := -1
var _run_seed := 0
var _run_seed_label_text := "Seed"
var _run_mode := "Normal"
var _run_modifier: Dictionary = {}
var _run_modifier_goal_progress: Dictionary = {}
var _boss_last_attack_hold := 0.0
var _master_volume := 1.0
var _damage_flash_enabled := true
var _damage_vignette_enabled := true
var _high_contrast_cues := false
var _clean_playtest_mode := false
var _compact_gameplay_hud := true


func _ready() -> void:
	layer = 10

	_damage_vignette = ColorRect.new()
	_damage_vignette.name = "DamageVignetteOverlay"
	_damage_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_vignette.z_index = -20
	_damage_vignette.color = Color(0.9, 0.05, 0.03, 0.0)
	_damage_vignette.visible = false
	add_child(_damage_vignette)

	var hp_bg := ColorRect.new()
	hp_bg.position = Vector2(8, 8)
	hp_bg.size = Vector2(BAR_W + 4, BAR_H + 4)
	hp_bg.color = Color(0, 0, 0, 0.6)
	add_child(hp_bg)

	_hp_fill = ColorRect.new()
	_hp_fill.position = Vector2(10, 10)
	_hp_fill.size = Vector2(BAR_W, BAR_H)
	_hp_fill.color = Color(0.8, 0.2, 0.2)
	add_child(_hp_fill)

	_hp_heart_icon = TextureRect.new()
	_hp_heart_icon.name = "HpHeartIcon"
	_hp_heart_icon.position = Vector2(118, 8)
	_hp_heart_icon.size = Vector2(13, 12)
	_hp_heart_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_heart_icon)
	_set_hp_heart_icon("ui_heart_full")

	var resource_bg := ColorRect.new()
	resource_bg.position = Vector2(8, 22)
	resource_bg.size = Vector2(BAR_W + 4, BAR_H)
	resource_bg.color = Color(0, 0, 0, 0.6)
	add_child(resource_bg)

	_resource_fill = ColorRect.new()
	_resource_fill.position = Vector2(10, 24)
	_resource_fill.size = Vector2(BAR_W, BAR_H - 4)
	_resource_fill.color = Color(0.3, 0.55, 0.95)
	add_child(_resource_fill)
	_resource_icon = _make_sprite_icon(
		"ResourceIcon", Vector2(118, 20), Vector2(16, 16),
		"flask_big_blue", "resource_icon_sprite")

	_hp_label = _make_label(Vector2(134, 6))
	_hp_label.name = "HpLabel"
	_low_hp_label = _make_label(Vector2(172, 30))
	_low_hp_label.name = "LowHpWarningLabel"
	_low_hp_label.text = "LOW HP"
	_low_hp_label.visible = false
	_low_hp_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.25))
	_damage_type_icon = _make_sprite_icon(
		"DamageTypeIcon", Vector2(134, 18), Vector2(12, 12),
		"ui_heart_full", "damage_icon_sprite")
	_damage_type_icon.visible = false
	_damage_type_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_damage_type_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_damage_flash_label = _make_label(Vector2(150, 18))
	_damage_flash_label.name = "DamageFlashLabel"
	_damage_flash_label.visible = false
	_damage_flash_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.34))
	_revive_flash_label = _make_label(Vector2(172, 154))
	_revive_flash_label.name = "ReviveFlashLabel"
	_revive_flash_label.visible = false
	_revive_flash_label.add_theme_color_override("font_color", Color(0.66, 1.0, 0.86))
	_weapon_label = _make_label(Vector2(8, 34))
	_weapon_label.name = "WeaponLabel"
	_weapon_label.visible = false
	_weapon_flash_label = _make_label(Vector2(172, 42))
	_weapon_flash_label.name = "WeaponSwapFlashLabel"
	_weapon_flash_label.visible = false
	_weapon_flash_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.48))
	_active_reload_window_label = _make_label(Vector2(320, 58))
	_active_reload_window_label.name = "ActiveReloadWindowLabel"
	_active_reload_window_label.visible = false
	_active_reload_window_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.36))
	_gold_flash_label = _make_label(Vector2(172, 58))
	_gold_flash_label.name = "GoldFlashLabel"
	_gold_flash_label.visible = false
	_gold_flash_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.28))
	_key_flash_label = _make_label(Vector2(172, 74))
	_key_flash_label.name = "KeyFlashLabel"
	_key_flash_label.visible = false
	_key_flash_label.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0))
	_meta_currency_flash_label = _make_label(Vector2(172, 90))
	_meta_currency_flash_label.name = "MetaCurrencyFlashLabel"
	_meta_currency_flash_label.visible = false
	_meta_currency_flash_label.add_theme_color_override("font_color", Color(0.72, 0.62, 1.0))
	_meta_bonus_flash_label = _make_label(Vector2(172, 170))
	_meta_bonus_flash_label.name = "MetaBonusFlashLabel"
	_meta_bonus_flash_label.visible = false
	_meta_bonus_flash_label.add_theme_color_override("font_color", Color(0.78, 0.92, 1.0))
	_biome_mastery_flash_label = _make_label(Vector2(172, 202))
	_biome_mastery_flash_label.name = "BiomeMasteryFlashLabel"
	_biome_mastery_flash_label.visible = false
	_biome_mastery_flash_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.76))
	_power_tier_flash_label = _make_label(Vector2(172, 186))
	_power_tier_flash_label.name = "PowerTierFlashLabel"
	_power_tier_flash_label.visible = false
	_power_tier_flash_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42))
	_gold_icon = _make_sprite_icon(
		"GoldIcon", Vector2(8, 48), Vector2(10, 10),
		"coin_anim", "gold_icon_sprite")
	_gold_label = _make_label(Vector2(22, 50))
	_gold_label.name = "GoldLabel"
	_floor_label = _make_label(Vector2(8, 66))
	_floor_label.name = "FloorLabel"
	_floor_label.visible = false
	_room_label = _make_label(Vector2(8, 82))
	_room_label.name = "RoomLabel"
	_room_label.visible = false
	_objective_label = _make_label(Vector2(8, 98))
	_objective_label.name = "ObjectiveLabel"
	_objective_label.visible = false
	_objective_next_label = _make_label(Vector2(172, 122))
	_objective_next_label.name = "ObjectiveNextActionLabel"
	_objective_next_label.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	_objective_flash_label = _make_label(Vector2(172, 106))
	_objective_flash_label.name = "ObjectiveCompleteFlashLabel"
	_objective_flash_label.visible = false
	_objective_flash_label.add_theme_color_override("font_color", Color(0.74, 1.0, 0.7))
	_room_mastery_flash_label = _make_label(Vector2(172, 138))
	_room_mastery_flash_label.name = "RoomMasteryFlashLabel"
	_room_mastery_flash_label.visible = false
	_room_mastery_flash_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42))
	var skill_icon := ColorRect.new()
	skill_icon.name = "SkillCooldownIcon"
	skill_icon.position = Vector2(8, 116)
	skill_icon.size = Vector2(12, 12)
	skill_icon.color = Color(0.06, 0.07, 0.08, 0.75)
	add_child(skill_icon)
	_attach_cooldown_sprite_icon(skill_icon, "SkillCooldownSprite", "skill")
	_skill_cd_badge = _make_cooldown_badge("SkillCooldownBadge", "E", Vector2(10, 113))
	_skill_cd_fill = ColorRect.new()
	_skill_cd_fill.name = "SkillCooldownFill"
	_skill_cd_fill.position = skill_icon.position
	_skill_cd_fill.size = skill_icon.size
	_skill_cd_fill.color = Color(0.35, 0.7, 1.0, 0.85)
	add_child(_skill_cd_fill)
	_skill_label = _make_label(Vector2(24, 112))
	_skill_label.name = "SkillLabel"
	_skill_label.visible = false
	var skill_alt_icon := ColorRect.new()
	skill_alt_icon.name = "SecondarySkillCooldownIcon"
	skill_alt_icon.position = Vector2(8, 132)
	skill_alt_icon.size = Vector2(12, 12)
	skill_alt_icon.color = Color(0.06, 0.07, 0.08, 0.75)
	add_child(skill_alt_icon)
	_attach_cooldown_sprite_icon(skill_alt_icon, "SecondarySkillCooldownSprite", "skill")
	_skill_alt_cd_badge = _make_cooldown_badge("SecondarySkillCooldownBadge", "C", Vector2(10, 129))
	_skill_alt_cd_fill = ColorRect.new()
	_skill_alt_cd_fill.name = "SecondarySkillCooldownFill"
	_skill_alt_cd_fill.position = skill_alt_icon.position
	_skill_alt_cd_fill.size = skill_alt_icon.size
	_skill_alt_cd_fill.color = Color(0.35, 1.0, 0.55, 0.85)
	add_child(_skill_alt_cd_fill)
	_skill_alt_label = _make_label(Vector2(24, 128))
	_skill_alt_label.name = "SecondarySkillLabel"
	_skill_alt_label.visible = false
	var dash_icon := ColorRect.new()
	dash_icon.name = "DashCooldownIcon"
	dash_icon.position = Vector2(8, 148)
	dash_icon.size = Vector2(12, 12)
	dash_icon.color = Color(0.06, 0.07, 0.08, 0.75)
	add_child(dash_icon)
	_attach_cooldown_sprite_icon(dash_icon, "DashCooldownSprite", "dash")
	_dash_cd_fill = ColorRect.new()
	_dash_cd_fill.name = "DashCooldownFill"
	_dash_cd_fill.position = dash_icon.position
	_dash_cd_fill.size = dash_icon.size
	_dash_cd_fill.color = Color(0.85, 0.85, 1.0, 0.85)
	add_child(_dash_cd_fill)
	_dash_label = _make_label(Vector2(24, 144))
	_dash_label.name = "DashLabel"
	_dash_label.visible = false
	_skill_cast_flash_label = _make_label(Vector2(8, 162))
	_skill_cast_flash_label.name = "SkillCastFlashLabel"
	_skill_cast_flash_label.visible = false
	_skill_cast_flash_label.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	_skill_cast_pulse = ColorRect.new()
	_skill_cast_pulse.name = "SkillCastPulse"
	_skill_cast_pulse.position = Vector2(6, 114)
	_skill_cast_pulse.size = Vector2(16, 16)
	_skill_cast_pulse.color = Color(0.75, 0.9, 1.0, 0.0)
	_skill_cast_pulse.visible = false
	_skill_cast_pulse.z_index = 1
	add_child(_skill_cast_pulse)
	var ultimate_icon := ColorRect.new()
	ultimate_icon.name = "UltimateChargeIcon"
	ultimate_icon.position = Vector2(8, 180)
	ultimate_icon.size = Vector2(12, 12)
	ultimate_icon.color = Color(0.08, 0.05, 0.1, 0.78)
	add_child(ultimate_icon)
	_attach_cooldown_sprite_icon(ultimate_icon, "UltimateChargeSprite", "blade")
	_ultimate_charge_fill = ColorRect.new()
	_ultimate_charge_fill.name = "UltimateChargeFill"
	_ultimate_charge_fill.position = ultimate_icon.position
	_ultimate_charge_fill.size = Vector2.ZERO
	_ultimate_charge_fill.color = Color(0.9, 0.55, 1.0, 0.9)
	add_child(_ultimate_charge_fill)
	_ultimate_label = _make_label(Vector2(24, 176))
	_ultimate_label.name = "UltimateLabel"
	_ultimate_label.visible = false
	_build_label = _make_label(Vector2(8, 194))
	_build_label.name = "BuildLabel"
	_build_label.visible = false
	_reward_path_label = _make_label(Vector2(8, 210))
	_reward_path_label.name = "RewardPathLabel"
	_reward_path_label.visible = false
	_reward_path_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.58))
	_run_decision_label = _make_label(Vector2(8, 226))
	_run_decision_label.name = "RunDecisionLabel"
	_run_decision_label.visible = false
	_run_decision_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.72))
	_run_stats_label = _make_label(Vector2(8, 242))
	_run_stats_label.name = "RunStatsLabel"
	_run_stats_label.visible = false
	_run_stats_label.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0))
	_run_route_label = _make_label(Vector2(8, 258))
	_run_route_label.name = "RunRouteLabel"
	_run_route_label.visible = false
	_run_route_label.add_theme_color_override("font_color", Color(0.76, 0.82, 0.96))
	_setup_route_choice_labels()
	_loot_pity_label = _make_label(Vector2(8, 274))
	_loot_pity_label.name = "LootPityLabel"
	_loot_pity_label.visible = false
	_loot_pity_label.add_theme_color_override("font_color", Color(0.84, 0.92, 1.0))
	_run_seed_label = _make_label(Vector2(8, 306))
	_run_seed_label.name = "RunSeedLabel"
	_run_seed_label.visible = false
	_run_seed_label.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0))
	_update_run_seed_label()
	_run_mode_label = _make_label(Vector2(8, 322))
	_run_mode_label.name = "RunModeLabel"
	_run_mode_label.visible = false
	_run_mode_label.add_theme_color_override("font_color", Color(0.88, 0.82, 1.0))
	_update_run_mode_label()
	_run_modifier_label = _make_label(Vector2(8, 338))
	_run_modifier_label.name = "RunModifierLabel"
	_run_modifier_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.45))
	_update_run_modifier_label()
	_run_modifier_goal_label = _make_label(Vector2(8, 354))
	_run_modifier_goal_label.name = "RunModifierGoalLabel"
	_run_modifier_goal_label.visible = false
	_run_modifier_goal_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.58))
	_controls_hint_label = _make_label(Vector2(444, 106))
	_controls_hint_label.name = "ControlsHintLabel"
	var full_controls_hint := "Mouse1 attack | E/C skills | Q cycle element | V ultimate | Space dash | 1-4 doors | Esc/P pause | F4 clean HUD | Pad: LS move, RS aim, RB attack, A dash, X/Y skills, RT ultimate"
	_controls_hint_label.text = "M1 atk | E/C | Sp | 1-4"
	_controls_hint_label.tooltip_text = full_controls_hint
	_controls_hint_label.visible = true
	_controls_hint_label.size = Vector2(188, 12)
	_controls_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_controls_hint_label.add_theme_font_size_override("font_size", 8)
	_controls_hint_label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.94))
	_controls_hint_label.set_meta("control_hint_scope", "in_run")
	_controls_hint_label.set_meta("control_hint_action_count", 6)
	_controls_hint_label.set_meta("full_control_hint", full_controls_hint)
	_controls_hint_label.set_meta(
			"gamepad_hint",
			"Pad: LS move, RS aim, RB attack, A dash, X/Y skills, RT ultimate")
	_class_resource_label = _make_label(Vector2(8, 290))
	_class_resource_label.name = "ClassResourceLabel"
	_class_resource_label.visible = false
	_class_resource_label.add_theme_color_override("font_color", Color(0.58, 0.95, 1.0))
	_status_label = _make_label(Vector2(8, 338))
	_status_label.name = "StatusEffectsLabel"
	_status_label.visible = false
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42))
	_element_combo_counter_label = _make_label(Vector2(8, 386))
	_element_combo_counter_label.name = "ElementComboCounterLabel"
	_element_combo_counter_label.visible = false
	_element_combo_counter_label.add_theme_color_override("font_color", Color(0.62, 0.96, 1.0))
	_element_combo_flash_label = _make_label(Vector2(172, 218))
	_element_combo_flash_label.name = "ElementComboFlashLabel"
	_element_combo_flash_label.visible = false
	_element_combo_flash_label.add_theme_color_override("font_color", Color(0.62, 0.96, 1.0))

	_boss_bg = ColorRect.new()
	_boss_bg.name = "BossHealthBackground"
	_boss_bg.position = Vector2(172, 8)
	_boss_bg.size = Vector2(BOSS_BAR_W + 4, 8)
	_boss_bg.color = Color(0.02, 0.02, 0.02, 0.74)
	_boss_bg.visible = false
	add_child(_boss_bg)
	_boss_fill = ColorRect.new()
	_boss_fill.name = "BossHealthFill"
	_boss_fill.position = Vector2(174, 10)
	_boss_fill.size = Vector2.ZERO
	_boss_fill.color = Color(0.9, 0.16, 0.18, 0.94)
	_boss_fill.visible = false
	add_child(_boss_fill)
	_boss_label = _make_label(Vector2(172, 18))
	_boss_label.name = "BossHealthLabel"
	_boss_label.visible = false
	_boss_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.42))
	_boss_phase_flash_label = _make_label(Vector2(172, 34))
	_boss_phase_flash_label.name = "BossPhaseFlashLabel"
	_boss_phase_flash_label.visible = false
	_boss_phase_flash_label.add_theme_color_override("font_color", Color(1.0, 0.48, 0.32))
	_boss_enrage_warning_label = _make_label(Vector2(172, 50))
	_boss_enrage_warning_label.name = "BossEnrageWarningLabel"
	_boss_enrage_warning_label.visible = false
	_boss_enrage_warning_label.add_theme_color_override("font_color", Color(1.0, 0.38, 0.26))
	_boss_pattern_cue_label = _make_label(Vector2(172, 66))
	_boss_pattern_cue_label.name = "BossPatternCueLabel"
	_boss_pattern_cue_label.visible = false
	_boss_pattern_cue_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.48))
	_boss_attack_flash_label = _make_label(Vector2(172, 82))
	_boss_attack_flash_label.name = "BossAttackCueFlashLabel"
	_boss_attack_flash_label.visible = false
	_boss_attack_flash_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.46))
	_boss_last_attack_label = _make_label(Vector2(172, 98))
	_boss_last_attack_label.name = "BossLastAttackLabel"
	_boss_last_attack_label.visible = false
	_boss_last_attack_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.52))

	_minimap = Minimap.new()
	_minimap.name = "Minimap"
	_minimap.position = Vector2(536, 8)
	_minimap.size = Vector2(96, 52)
	add_child(_minimap)


func set_clean_playtest_mode(enabled: bool) -> void:
	_clean_playtest_mode = enabled
	set_meta("clean_playtest_mode", _clean_playtest_mode)
	if _clean_playtest_mode:
		_apply_clean_playtest_visibility()
	else:
		_restore_compact_playtest_visibility()


func apply_accessibility_settings(settings: Dictionary) -> void:
	_master_volume = clampf(float(settings.get("master_volume", _master_volume)), 0.0, 1.0)
	_damage_flash_enabled = bool(settings.get("damage_flash_enabled", _damage_flash_enabled))
	_damage_vignette_enabled = bool(settings.get(
		"damage_vignette_enabled", _damage_flash_enabled))
	_high_contrast_cues = bool(settings.get("high_contrast_cues", _high_contrast_cues))
	set_meta("master_volume", _master_volume)
	set_meta("damage_flash_enabled", _damage_flash_enabled)
	set_meta("damage_vignette_enabled", _damage_vignette_enabled)
	set_meta("high_contrast_cues", _high_contrast_cues)


func bind(player: Player, floor_ctrl: FloorController) -> void:
	_player = player
	_floor_ctrl = floor_ctrl
	player.hp_changed.connect(_on_hp_changed)
	if player.has_signal("revived"):
		player.revived.connect(_on_player_revived)
	player.gold_changed.connect(_on_gold_changed)
	player.key_changed.connect(_on_key_changed)
	player.meta_currency_changed.connect(_on_meta_currency_changed)
	player.weapon_changed.connect(_on_weapon_changed)
	player.weapon_attack_blocked.connect(_on_weapon_attack_blocked)
	if player.has_signal("active_reload_window_changed"):
		player.connect("active_reload_window_changed", _on_active_reload_window_changed)
	if player.has_signal("active_reload_performed"):
		player.connect("active_reload_performed", _on_active_reload_performed)
	player.resource_changed.connect(_on_resource_changed)
	player.dash_cooldown_changed.connect(_on_dash_cooldown_changed)
	player.dash_blocked.connect(_on_dash_blocked)
	player.skill_cooldown_changed.connect(_on_skill_cooldown_changed)
	player.skill_cast.connect(_on_skill_cast)
	player.skill_blocked.connect(_on_skill_blocked)
	player.ultimate_charge_changed.connect(_on_ultimate_charge_changed)
	player.ultimate_cast.connect(_on_ultimate_cast)
	player.ultimate_blocked.connect(_on_ultimate_blocked)
	player.element_changed.connect(_on_element_changed)
	player.upgrades_changed.connect(_on_upgrades_changed)
	if player.has_signal("element_combo_recorded"):
		player.connect("element_combo_recorded", _on_element_combo_recorded)
	_on_hp_changed(player.hp, player.max_hp)
	_on_gold_changed(player.gold)
	_on_key_changed(player.silver_keys)
	_on_resource_changed(player.resource, player.max_resource)
	_on_dash_cooldown_changed(0.0, player.dash_cooldown)
	if player.resource_type == "energy":
		_resource_fill.color = Color(0.95, 0.75, 0.2)
	var weapon := player.current_weapon()
	_on_weapon_changed(weapon.display_name() if weapon != null else "-")
	if player.has_method("active_reload_window_status"):
		_on_active_reload_window_changed(player.call("active_reload_window_status") as Dictionary)
	_on_skill_cooldown_changed(str(player.skill.get("id", "-")), 0.0, 1.0)
	_on_skill_cooldown_changed(str(player.skill_alt.get("id", "-")), 0.0, 1.0)
	_on_ultimate_charge_changed(player.ultimate_charge, player.ultimate_max_charge)
	_on_upgrades_changed(player.upgrade_summary())
	_update_element_combo_counter()
	_update_class_resource_summary()
	_minimap.bind(floor_ctrl)
	floor_ctrl.state_changed.connect(func() -> void:
		_floor_label.text = _floor_label_text(floor_ctrl)
		_update_room_objective(floor_ctrl))
	if floor_ctrl.has_signal("boss_phase_changed"):
		floor_ctrl.connect("boss_phase_changed", _on_boss_phase_changed)
	if floor_ctrl.has_signal("boss_attack_cued"):
		floor_ctrl.connect("boss_attack_cued", _on_boss_attack_cued)
	if floor_ctrl.has_signal("room_objective_completed"):
		floor_ctrl.connect("room_objective_completed", _on_room_objective_completed)
	if floor_ctrl.has_signal("room_mastery_awarded"):
		floor_ctrl.connect("room_mastery_awarded", _on_room_mastery_awarded)
	_floor_label.text = _floor_label_text(floor_ctrl)
	_update_room_objective(floor_ctrl)
	_on_boss_status_changed(floor_ctrl.current_boss_status())

func set_run_seed(seed: int) -> void:
	_run_seed = seed
	_update_run_seed_label()

func set_run_seed_label(label: String) -> void:
	var clean := label.strip_edges()
	_run_seed_label_text = clean if clean != "" else "Seed"
	_update_run_seed_label()

func set_run_mode(mode_label: String) -> void:
	_run_mode = mode_label if mode_label.strip_edges() != "" else "Normal"
	_update_run_mode_label()

func set_run_modifier(modifier: Dictionary) -> void:
	_run_modifier = modifier.duplicate(true)
	_update_run_modifier_label()

func set_run_modifier_goals(summary: String, progress: Dictionary = {}) -> void:
	_run_modifier_goal_progress = progress.duplicate(true)
	if _run_modifier_goal_label == null:
		return
	var clean := summary.strip_edges()
	_run_modifier_goal_label.visible = clean != ""
	_run_modifier_goal_label.text = clean
	_run_modifier_goal_label.set_meta("run_goal_summary", clean)
	_run_modifier_goal_label.set_meta("run_goal_progress", _run_modifier_goal_progress.duplicate(true))
	var total := 0
	var completed := 0
	for state in _run_modifier_goal_progress.values():
		if not (state is Dictionary):
			continue
		total += 1
		if bool((state as Dictionary).get("completed", false)) \
				or int((state as Dictionary).get("current", 0)) >= int((state as Dictionary).get("target", 1)):
			completed += 1
	_run_modifier_goal_label.set_meta("run_goal_count", total)
	_run_modifier_goal_label.set_meta("run_goal_completed_count", completed)

func show_run_goal_completed(
		goal_label: String,
		summary: String,
		completed_count: int,
		goal_count: int,
) -> void:
	var clean_label := goal_label.strip_edges()
	var clean_summary := summary.strip_edges()
	_show_skill_flash("Goal complete: %s | %d/%d" % [
		clean_label if clean_label != "" else "Daily goal",
		completed_count,
		goal_count,
	], {
		"hud_flash_kind": "run_goal_complete",
		"run_goal_label": clean_label,
		"run_goal_summary": clean_summary,
		"run_goal_completed_count": completed_count,
		"run_goal_count": goal_count,
	})
	_play_objective_complete_sfx("Goal complete: %s" % clean_label)

func show_meta_bonus_summary(summary: String, meta: Dictionary = {}) -> void:
	if _meta_bonus_flash_label == null:
		return
	var clean := summary.strip_edges()
	var upgrade_count := _meta_bonus_upgrade_count(meta)
	_meta_bonus_flash_label.set_meta("meta_bonus_summary", clean)
	_meta_bonus_flash_label.set_meta("meta_bonus_upgrade_count", upgrade_count)
	if clean == "" or clean == "None":
		_meta_bonus_flash_label.text = ""
		_meta_bonus_flash_label.visible = false
		return
	_meta_bonus_flash_label.text = "Meta Bonus: %s" % clean
	_meta_bonus_flash_label.visible = true
	_meta_bonus_flash_label.modulate.a = 1.0
	_play_meta_bonus_sfx(clean, meta)
	var tween := _meta_bonus_flash_label.create_tween()
	tween.tween_property(_meta_bonus_flash_label, "modulate:a", 0.0, 1.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _meta_bonus_flash_label != null:
			_meta_bonus_flash_label.visible = false)

func show_biome_mastery_feedback(biome_label: String, bonus: float) -> void:
	if _biome_mastery_flash_label == null:
		return
	var clean := biome_label.strip_edges()
	_biome_mastery_flash_label.set_meta("hud_flash_kind", "biome_mastery")
	_biome_mastery_flash_label.set_meta("biome_mastery_label", clean)
	_biome_mastery_flash_label.set_meta("biome_mastery_bonus", bonus)
	if clean == "" or bonus <= 0.0:
		_biome_mastery_flash_label.text = ""
		_biome_mastery_flash_label.visible = false
		return
	_biome_mastery_flash_label.text = "Biome Mastery: %s +%d%% dmg" % [
		clean,
		roundi(bonus * 100.0),
	]
	_biome_mastery_flash_label.visible = true
	_biome_mastery_flash_label.modulate.a = 1.0
	var tween := _biome_mastery_flash_label.create_tween()
	tween.tween_property(_biome_mastery_flash_label, "modulate:a", 0.0, 1.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _biome_mastery_flash_label != null:
			_biome_mastery_flash_label.visible = false)

func _on_element_combo_recorded(info: Dictionary, total_count: int) -> void:
	_update_element_combo_counter()
	if _element_combo_flash_label == null:
		return
	var label := str(info.get("label", info.get("name", "Combo"))).strip_edges()
	if label == "":
		label = "Combo"
	var combo_count := maxi(int(info.get("count", 1)), 1)
	_element_combo_flash_label.text = "Combo: %s x%d" % [label, combo_count]
	_element_combo_flash_label.visible = true
	_element_combo_flash_label.modulate.a = 1.0
	_element_combo_flash_label.set_meta("hud_flash_kind", "element_combo")
	_element_combo_flash_label.set_meta("combo_id", str(info.get("id", "")))
	_element_combo_flash_label.set_meta("combo_label", label)
	_element_combo_flash_label.set_meta("combo_count", combo_count)
	_element_combo_flash_label.set_meta("combo_total_count", total_count)
	var tween := _element_combo_flash_label.create_tween()
	tween.tween_property(_element_combo_flash_label, "modulate:a", 0.0, 0.9)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if _element_combo_flash_label != null:
			_element_combo_flash_label.visible = false)

func _update_element_combo_counter() -> void:
	if _element_combo_counter_label == null:
		return
	if _player == null or not is_instance_valid(_player) \
			or not _player.has_method("element_combo_count") \
			or not _player.has_method("element_combo_summary"):
		_element_combo_counter_label.visible = false
		return
	var total := int(_player.call("element_combo_count"))
	if total <= 0:
		_element_combo_counter_label.text = ""
		_element_combo_counter_label.visible = false
		return
	var summary := str(_player.call("element_combo_summary", 3))
	_element_combo_counter_label.text = "Combos: %d | %s" % [total, summary]
	_element_combo_counter_label.visible = true
	_element_combo_counter_label.set_meta("combo_total_count", total)
	_element_combo_counter_label.set_meta("combo_summary", summary)

func _update_run_seed_label() -> void:
	if _run_seed_label == null:
		return
	_run_seed_label.text = "%s: %d" % [_run_seed_label_text, _run_seed] \
		if _run_seed > 0 else "%s: Random" % _run_seed_label_text
	_run_seed_label.set_meta("run_seed", _run_seed)
	_run_seed_label.set_meta("run_seed_label", _run_seed_label_text)

func _update_run_mode_label() -> void:
	if _run_mode_label == null:
		return
	_run_mode_label.text = "Mode: %s" % _run_mode
	_run_mode_label.set_meta("run_mode", _run_mode)

func _update_run_modifier_label() -> void:
	if _run_modifier_label == null:
		return
	var name := str(_run_modifier.get("name", "")).strip_edges()
	var desc := str(_run_modifier.get("desc", "")).strip_edges()
	_run_modifier_label.visible = name != "" and not _compact_gameplay_hud
	_run_modifier_label.text = "" if name == "" else "Challenge: %s%s" % [
		name,
		" | %s" % desc if desc != "" else "",
	]
	_run_modifier_label.set_meta("run_modifier_id", str(_run_modifier.get("id", "")))
	_run_modifier_label.set_meta("difficulty_mult", float(_run_modifier.get("difficulty_mult", 1.0)))

func _process(delta: float) -> void:
	_update_class_resource_summary()
	_update_status_effects()
	_update_run_decision_label()
	_update_run_stats()
	if _floor_ctrl != null and is_instance_valid(_floor_ctrl):
		_update_room_objective(_floor_ctrl)
		_boss_last_attack_hold = maxf(_boss_last_attack_hold - delta, 0.0)
		var status: Dictionary = _floor_ctrl.current_boss_status()
		_on_boss_status_changed(status, status.is_empty() and _boss_last_attack_hold > 0.0)
	_apply_clean_playtest_visibility()

func _apply_clean_playtest_visibility() -> void:
	if not _clean_playtest_mode:
		return
	for label in [
		_hp_label,
		_low_hp_label,
		_damage_flash_label,
		_revive_flash_label,
		_weapon_label,
		_weapon_flash_label,
		_gold_flash_label,
		_key_flash_label,
		_meta_currency_flash_label,
		_gold_label,
		_floor_label,
		_room_label,
		_objective_label,
		_objective_next_label,
		_objective_flash_label,
		_room_mastery_flash_label,
		_skill_label,
		_skill_alt_label,
		_dash_label,
		_skill_cast_flash_label,
		_ultimate_label,
		_build_label,
		_reward_path_label,
		_run_decision_label,
		_run_stats_label,
		_run_route_label,
		_loot_pity_label,
		_run_seed_label,
		_run_mode_label,
		_run_modifier_label,
		_run_modifier_goal_label,
		_controls_hint_label,
		_class_resource_label,
		_status_label,
		_element_combo_counter_label,
		_element_combo_flash_label,
		_meta_bonus_flash_label,
		_biome_mastery_flash_label,
		_power_tier_flash_label,
	]:
		if label != null:
			label.visible = false
	for label in _route_choice_labels:
		if label != null:
			label.visible = false
	for icon in _route_choice_icons:
		if icon != null:
			icon.visible = false
	if _minimap != null:
		_minimap.visible = true

func _restore_compact_playtest_visibility() -> void:
	if _controls_hint_label != null:
		_controls_hint_label.visible = true
	if _floor_ctrl != null and is_instance_valid(_floor_ctrl):
		_update_room_objective(_floor_ctrl)
		_update_route_label()
		_update_loot_pity_label()
	_update_status_effects()
	_update_class_resource_summary()

func _make_label(pos: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)
	return label

func _compact_name(text: String, max_chars: int) -> String:
	var clean := text.strip_edges()
	if clean.length() <= max_chars:
		return clean
	return "%s..." % clean.substr(0, maxi(max_chars - 3, 1))

func _make_cooldown_badge(node_name: String, text: String, pos: Vector2) -> Label:
	var badge := _make_label(pos)
	badge.name = node_name
	badge.text = text
	badge.custom_minimum_size = Vector2(10, 10)
	badge.add_theme_font_size_override("font_size", 8)
	badge.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 0.95))
	badge.z_index = 2
	return badge

func _make_sprite_icon(
		node_name: String,
		pos: Vector2,
		size: Vector2,
		sprite_name: String,
		meta_key: String,
) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = node_name
	icon.position = pos
	icon.size = size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	_set_sprite_icon(icon, sprite_name, meta_key)
	return icon

func _floor_label_text(floor_ctrl: FloorController) -> String:
	var difficulty := ""
	if floor_ctrl.has_method("current_difficulty_label"):
		difficulty = str(floor_ctrl.call("current_difficulty_label"))
	var threat := ""
	if floor_ctrl.has_method("current_threat_label"):
		threat = str(floor_ctrl.call("current_threat_label"))
	if _compact_gameplay_hud:
		return "F%d %s %s %s" % [
			floor_ctrl.floor_index,
			_compact_name(floor_ctrl.current_biome_label(), 10),
			_compact_difficulty_label(difficulty),
			_compact_threat_label(threat),
		]
	return "Floor %d: %s%s%s" % [
		floor_ctrl.floor_index,
		floor_ctrl.current_biome_label(),
		" | %s" % difficulty if difficulty != "" else "",
		" | %s" % threat if threat != "" else "",
	]

func _compact_difficulty_label(text: String) -> String:
	var clean := text.replace("Difficulty ", "").strip_edges()
	return clean if clean != "" else "x1.00"

func _compact_threat_label(text: String) -> String:
	var clean := text.replace("Threat x", "T").replace("Threat ", "T").strip_edges()
	return clean if clean != "" else "T1.00"

func _on_hp_changed(current: int, max_value: int) -> void:
	var safe_max := maxi(max_value, 1)
	var previous := _last_hp_current
	_hp_fill.size.x = BAR_W * float(current) / float(safe_max)
	_hp_label.text = "%d/%d" % [current, max_value]
	_update_hp_heart_icon(current, max_value)
	if _low_hp_label != null:
		_low_hp_label.visible = max_value > 0 and float(current) / float(max_value) <= 0.3
	if previous >= 0 and current < previous:
		var amount := previous - current
		_show_damage_flash(amount, current, safe_max, _damage_feedback_context(amount))
	_last_hp_current = current

func _show_damage_flash(
		amount: int,
		current: int,
		max_value: int,
		context: Dictionary = {},
) -> void:
	if _damage_flash_label == null or amount <= 0:
		return
	var ratio := clampf(float(current) / float(maxi(max_value, 1)), 0.0, 1.0)
	var damage_source := str(context.get("source", "Unknown"))
	var damage_kind := str(context.get("kind", "unknown"))
	var color_role := _damage_color_role(damage_kind)
	if not _damage_flash_enabled:
		set_meta("damage_flash_suppressed", true)
		_play_damage_feedback_sfx(amount, damage_source, damage_kind, color_role)
		return
	set_meta("damage_flash_suppressed", false)
	_damage_flash_label.text = "Damage -%d | HP %d/%d" % [amount, current, max_value]
	_damage_flash_label.visible = true
	_damage_flash_label.modulate.a = 1.0
	_damage_flash_label.add_theme_color_override("font_color", _damage_feedback_color(color_role))
	_update_damage_type_icon(damage_kind, damage_source, color_role)
	_damage_flash_label.set_meta("hud_flash_kind", "player_damage")
	_damage_flash_label.set_meta("damage_amount", amount)
	_damage_flash_label.set_meta("damage_source", damage_source)
	_damage_flash_label.set_meta("damage_kind", damage_kind)
	_damage_flash_label.set_meta("damage_color_role", color_role)
	_damage_flash_label.set_meta("hp_current", current)
	_damage_flash_label.set_meta("hp_max", max_value)
	_damage_flash_label.set_meta("hp_ratio", ratio)
	_play_damage_feedback_sfx(amount, damage_source, damage_kind, color_role)
	_show_damage_vignette(amount, ratio, damage_source, damage_kind, color_role)
	var tween := _damage_flash_label.create_tween()
	tween.tween_property(_damage_flash_label, "modulate:a", 0.0, 0.65)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if _damage_flash_label != null:
			_damage_flash_label.visible = false
		if _damage_type_icon != null:
			_damage_type_icon.visible = false)

func _show_damage_vignette(
		amount: int,
		hp_ratio: float,
		damage_source: String = "Unknown",
		damage_kind: String = "unknown",
		color_role: String = "",
) -> void:
	if _damage_vignette == null:
		return
	if not _damage_vignette_enabled:
		set_meta("damage_vignette_suppressed", true)
		return
	set_meta("damage_vignette_suppressed", false)
	var alpha := clampf(0.08 + float(amount) * 0.004 + (1.0 - hp_ratio) * 0.08, 0.1, 0.24)
	var role := _damage_color_role(damage_kind) if color_role == "" else color_role
	_damage_vignette.visible = true
	_damage_vignette.color = _damage_feedback_color(role, alpha)
	_damage_vignette.modulate.a = 1.0
	_damage_vignette.set_meta("hud_flash_kind", "damage_vignette")
	_damage_vignette.set_meta("damage_amount", amount)
	_damage_vignette.set_meta("damage_source", damage_source)
	_damage_vignette.set_meta("damage_kind", damage_kind)
	_damage_vignette.set_meta("vignette_color_role", role)
	_damage_vignette.set_meta("hp_ratio", hp_ratio)
	_damage_vignette.set_meta("vignette_alpha", alpha)
	var tween := _damage_vignette.create_tween()
	tween.tween_property(_damage_vignette, "modulate:a", 0.0, 0.35)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if _damage_vignette != null:
			_damage_vignette.visible = false)

func _damage_feedback_context(amount: int) -> Dictionary:
	if _player == null or int(_player.get_meta("last_damage_amount", -1)) != amount:
		return {"source": "Unknown", "kind": "unknown"}
	return {
		"source": str(_player.get_meta("last_damage_source", "Unknown")),
		"kind": str(_player.get_meta("last_damage_kind", "unknown")),
	}

func _play_damage_feedback_sfx(
		amount: int,
		damage_source: String,
		damage_kind: String,
		color_role: String,
) -> void:
	var cue: Dictionary = AudioCueDBScript.player_damage_cue(damage_kind, damage_source, amount)
	var sfx := get_node_or_null("DamageFeedbackSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "DamageFeedbackSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("damage_sound_id", str(cue.get("id", "player_damage_enemy")))
	sfx.set_meta("damage_kind", str(cue.get("damage_kind", damage_kind)))
	sfx.set_meta("damage_source", str(cue.get("damage_source", damage_source)))
	sfx.set_meta("damage_amount", int(cue.get("damage_amount", amount)))
	sfx.set_meta("damage_color_role", color_role)
	sfx.volume_db = linear_to_db(maxf(_master_volume, 0.001))
	sfx.set_meta("master_volume", _master_volume)
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "player_damage")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "player_damage")))
	sfx.set_meta("damage_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _damage_color_role(damage_kind: String) -> String:
	return damage_kind if ["boss", "trap", "status"].has(damage_kind) else "enemy"

func _damage_feedback_color(color_role: String, alpha: float = 1.0) -> Color:
	if _high_contrast_cues:
		match color_role:
			"boss":
				return Color(1.0, 0.0, 1.0, alpha)
			"trap":
				return Color(1.0, 0.82, 0.0, alpha)
			"status":
				return Color(0.0, 1.0, 0.28, alpha)
		return Color(1.0, 0.05, 0.05, alpha)
	match color_role:
		"boss":
			return Color(0.94, 0.18, 1.0, alpha)
		"trap":
			return Color(1.0, 0.48, 0.12, alpha)
		"status":
			return Color(0.32, 1.0, 0.42, alpha)
	return Color(1.0, 0.36, 0.28, alpha)

func _update_damage_type_icon(damage_kind: String, damage_source: String, color_role: String) -> void:
	if _damage_type_icon == null:
		return
	var sprite_name := _damage_icon_sprite_name(color_role)
	var texture := SpriteDB.texture(sprite_name)
	if texture == null:
		_damage_type_icon.visible = false
		return
	_damage_type_icon.texture = texture
	_damage_type_icon.visible = true
	_damage_type_icon.modulate = _damage_feedback_color(color_role)
	_damage_type_icon.set_meta("damage_icon_sprite", sprite_name)
	_damage_type_icon.set_meta("damage_source", damage_source)
	_damage_type_icon.set_meta("damage_kind", damage_kind)
	_damage_type_icon.set_meta("damage_color_role", color_role)

func _damage_icon_sprite_name(color_role: String) -> String:
	match color_role:
		"boss":
			return "skull"
		"trap":
			return "floor_spikes_anim"
		"status":
			return "flask_big_green"
	return "ui_heart_full"

func _update_hp_heart_icon(current: int, max_value: int) -> void:
	if _hp_heart_icon == null:
		return
	var sprite_name := "ui_heart_empty"
	if max_value > 0:
		var ratio := clampf(float(current) / float(max_value), 0.0, 1.0)
		if ratio > 0.5:
			sprite_name = "ui_heart_full"
		elif ratio > 0.0:
			sprite_name = "ui_heart_half"
	_set_hp_heart_icon(sprite_name)

func _set_hp_heart_icon(sprite_name: String) -> void:
	_set_sprite_icon(_hp_heart_icon, sprite_name, "hp_icon_sprite")

func _set_sprite_icon(icon: TextureRect, sprite_name: String, meta_key: String) -> void:
	if icon == null:
		return
	var texture := SpriteDB.texture(sprite_name)
	if texture == null:
		return
	icon.texture = texture
	icon.set_meta(meta_key, sprite_name)

func _attach_cooldown_sprite_icon(parent: ColorRect, node_name: String, token: String) -> void:
	if parent == null:
		return
	var icon := parent.get_node_or_null(node_name) as TextureRect
	if icon == null:
		icon = TextureRect.new()
		icon.name = node_name
		icon.position = Vector2(1, 1)
		icon.size = Vector2(10, 10)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(icon)
	_update_cooldown_sprite_icon(parent, token)

func _update_cooldown_sprite_icon(parent: ColorRect, token: String) -> void:
	if parent == null:
		return
	var icon := _first_texture_child(parent)
	if icon == null:
		return
	var sprite_name := _cooldown_icon_sprite_name(token)
	_set_sprite_icon(icon, sprite_name, "icon_sprite_name")
	icon.set_meta("cooldown_icon_token", token)

func _first_texture_child(parent: Node) -> TextureRect:
	for child in parent.get_children():
		if child is TextureRect:
			return child
	return null

func _cooldown_icon_sprite_name(token: String) -> String:
	match token:
		"blade", "skill":
			return "weapon_regular_sword"
		"dash":
			return "weapon_spear"
		"hammer":
			return "weapon_hammer"
		"shield":
			return "ui_heart_full"
		"shadow", "soul", "wisp":
			return "skull"
		"knife":
			return "weapon_knife"
		"roar":
			return "weapon_mace"
		"orb", "ring", "sanctuary", "ray":
			return "weapon_red_magic_staff"
		"arrow":
			return "weapon_arrow"
		"trap":
			return "floor_spikes_anim"
		"grenade":
			return "bomb"
		"rounds":
			return "weapon_pistol_generated"
		"turret", "hack":
			return "weapon_bow_2"
	return "pickup_unknown_generated"

func _on_player_revived(context: Dictionary) -> void:
	_show_revive_flash(context)

func _show_revive_flash(context: Dictionary) -> void:
	if _revive_flash_label == null:
		return
	var hp := int(context.get("hp", _player.hp if _player != null else 0))
	var max_hp := int(context.get("max_hp", _player.max_hp if _player != null else hp))
	var used := int(context.get("revives_used", 0))
	var left := int(context.get("charges_left", 0))
	_revive_flash_label.text = "Revived x%d | HP %d/%d | Left %d" % [maxi(used, 1), hp, max_hp, left]
	_revive_flash_label.visible = true
	_revive_flash_label.modulate.a = 1.0
	_revive_flash_label.set_meta("revives_used", used)
	_revive_flash_label.set_meta("charges_left", left)
	_revive_flash_label.set_meta("revive_hp", hp)
	_revive_flash_label.set_meta("revive_max_hp", max_hp)
	_revive_flash_label.set_meta("revive_source", str(context.get("source", "")))
	_revive_flash_label.set_meta("prevented_damage", int(context.get("prevented_damage", 0)))
	_play_revive_sfx(context)
	var tween := _revive_flash_label.create_tween()
	tween.tween_property(_revive_flash_label, "modulate:a", 0.0, 0.9)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _revive_flash_label != null:
			_revive_flash_label.visible = false)

func _play_revive_sfx(context: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.revive_cue(context)
	var sfx := get_node_or_null("ReviveSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "ReviveSfx"
		add_child(sfx)
	else:
		sfx.stop()
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
	_request_hud_sfx_playback(sfx)


func _on_resource_changed(current: float, max_value: float) -> void:
	_resource_fill.size.x = BAR_W * current / maxf(max_value, 1.0)


func _on_gold_changed(total: int) -> void:
	if _last_gold_total >= 0 and total > _last_gold_total:
		_show_gold_flash("Gold +%d" % (total - _last_gold_total))
	_last_gold_total = total
	var keys := _player.silver_keys if _player != null else 0
	_gold_label.text = "Gold: %d Keys: %d" % [total, keys] if _compact_gameplay_hud \
		else "Gold: %d  Keys: %d" % [total, keys]

func _on_key_changed(total: int) -> void:
	if _last_key_total >= 0 and total > _last_key_total:
		_show_key_flash("Key +%d" % (total - _last_key_total))
	_last_key_total = total
	var gold := _player.gold if _player != null else 0
	_on_gold_changed(gold)

func _on_meta_currency_changed(currency_id: String, amount: int, _total: int) -> void:
	if amount <= 0:
		return
	_show_meta_currency_flash("%s +%d" % [_readable_meta_currency(currency_id), amount])


func _on_weapon_changed(weapon_name: String) -> void:
	var element := _player.equipped_element if _player != null else "-"
	var sockets := ""
	if _player != null and _player.has_method("socket_upgrade_count") \
			and _player.has_method("socket_capacity"):
		sockets = " S%d/%d" % [
			int(_player.call("socket_upgrade_count")),
			int(_player.call("socket_capacity")),
		]
	_weapon_label.text = "%s %s%s" % [
		_compact_name(weapon_name, 16),
		_compact_element_label(element),
		sockets,
	] if _compact_gameplay_hud else "Weapon: %s  [%s]%s" % [weapon_name, element, sockets]
	_set_weapon_label_contract(weapon_name, element)
	_show_weapon_flash("Equipped: %s" % weapon_name)

func _compact_element_label(element: String) -> String:
	var clean := element.strip_edges()
	return "[%s]" % clean if clean != "" else "[-]"

func _set_weapon_label_contract(weapon_name: String, element: String) -> void:
	if _weapon_label == null:
		return
	var weapon := _player.current_weapon() if _player != null else null
	var weapon_id := str(weapon.data.get("id", "")) if weapon != null else ""
	var group := str(weapon.data.get("group", "")) if weapon != null else ""
	var cooldown := weapon.cooldown() if weapon != null else 0.0
	var cost := weapon.resource_cost() if weapon != null else 0.0
	var resource_type := _player.resource_type if _player != null else "energy"
	var resource_label := "MP" if resource_type == "mana" else "EN"
	_weapon_label.set_meta("weapon_id", weapon_id)
	_weapon_label.set_meta("weapon_group", group)
	_weapon_label.set_meta("weapon_element", element)
	_weapon_label.set_meta("weapon_input_action", "attack")
	_weapon_label.set_meta("weapon_key_label", "Mouse1")
	_weapon_label.set_meta("weapon_cooldown_total", cooldown)
	_weapon_label.set_meta("weapon_resource_type", resource_type)
	_weapon_label.set_meta("weapon_resource_cost", cost)
	_weapon_label.tooltip_text = "%s [Mouse1] | %s | CD %.1fs%s" % [
		weapon_name,
		element,
		cooldown,
		" | Cost %d %s" % [int(ceilf(cost)), resource_label] if cost > 0.0 else "",
	]

func _on_element_changed(element: String) -> void:
	var weapon := _player.current_weapon() if _player != null else null
	_on_weapon_changed(weapon.display_name() if weapon != null else "-")
	_show_weapon_flash("Element: %s" % element)


func _update_room_objective(floor_ctrl: FloorController) -> void:
	var context := {}
	if floor_ctrl.has_method("current_room_objective_context"):
		context = floor_ctrl.call("current_room_objective_context")
	_room_label.text = floor_ctrl.current_room_label() if _compact_gameplay_hud \
		else "Room: %s" % floor_ctrl.current_room_label()
	_objective_label.text = str(context.get("objective_text", floor_ctrl.current_room_objective()))
	_objective_label.set_meta("objective_state", str(context.get("objective_state", "")))
	_objective_label.set_meta("time_left_seconds", float(context.get("time_left_seconds", 0.0)))
	_objective_label.set_meta("survive_seconds", float(context.get("survive_seconds", 0.0)))
	_objective_label.set_meta("countdown_urgency", str(context.get("countdown_urgency", "")))
	_objective_label.set_meta("reward_kind", str(context.get("reward_kind", "")))
	_objective_label.set_meta("reward_label", str(context.get("reward_label", "")))
	_objective_label.set_meta("reward_preview", str(context.get("reward_preview", "")))
	_objective_label.set_meta("reward_locked", bool(context.get("reward_locked", false)))
	_objective_label.set_meta("reward_claimed", bool(context.get("reward_claimed", false)))
	_objective_label.set_meta("wave_index", int(context.get("wave_index", 0)))
	_objective_label.set_meta("wave_count", int(context.get("wave_count", 0)))
	_objective_label.set_meta("enemies_left", int(context.get("enemies_left", 0)))
	_objective_label.set_meta("wave_progress_text", str(context.get("wave_progress_text", "")))
	if _objective_next_label != null:
		var next_action := ""
		var next_action_key := ""
		if floor_ctrl.has_method("current_room_next_action"):
			next_action = str(floor_ctrl.call("current_room_next_action"))
		if floor_ctrl.has_method("current_room_next_action_key"):
			next_action_key = str(floor_ctrl.call("current_room_next_action_key"))
		next_action = str(context.get("next_action_text", next_action))
		next_action_key = str(context.get("next_action_key", next_action_key))
		_objective_next_label.text = _compact_name(next_action, 64) if _compact_gameplay_hud else next_action
		_objective_next_label.visible = next_action != "" and not _compact_gameplay_hud
		_objective_next_label.set_meta("next_action_key", next_action_key)
		_objective_next_label.set_meta("next_action_text", next_action)
		_objective_next_label.set_meta("objective_state", str(context.get("objective_state", "")))
		_objective_next_label.set_meta("next_action_chain", str(context.get("next_action_chain", next_action_key)))
		_objective_next_label.set_meta(
			"next_action_priority",
			str(context.get("next_action_priority", next_action_key)))
		_objective_next_label.set_meta("time_left_seconds", float(context.get("time_left_seconds", 0.0)))
		_objective_next_label.set_meta("survive_seconds", float(context.get("survive_seconds", 0.0)))
		_objective_next_label.set_meta("countdown_urgency", str(context.get("countdown_urgency", "")))
		_objective_next_label.set_meta("reward_kind", str(context.get("reward_kind", "")))
		_objective_next_label.set_meta("reward_label", str(context.get("reward_label", "")))
		_objective_next_label.set_meta("reward_preview", str(context.get("reward_preview", "")))
		_objective_next_label.set_meta("reward_locked", bool(context.get("reward_locked", false)))
		_objective_next_label.set_meta("reward_claimed", bool(context.get("reward_claimed", false)))
		_objective_next_label.set_meta("wave_index", int(context.get("wave_index", 0)))
		_objective_next_label.set_meta("wave_count", int(context.get("wave_count", 0)))
		_objective_next_label.set_meta("enemies_left", int(context.get("enemies_left", 0)))
		_objective_next_label.set_meta("wave_progress_text", str(context.get("wave_progress_text", "")))

func _on_room_objective_completed(text: String) -> void:
	var context := {}
	if _floor_ctrl != null and is_instance_valid(_floor_ctrl):
		_update_room_objective(_floor_ctrl)
		if _floor_ctrl.has_method("current_room_objective_context"):
			context = _floor_ctrl.call("current_room_objective_context")
	_play_objective_complete_sfx(text)
	_show_objective_complete_flash("Objective complete | %s" % text, context)

func _play_objective_complete_sfx(text: String) -> void:
	var cue: Dictionary = AudioCueDBScript.objective_complete_cue(text)
	var sfx := get_node_or_null("ObjectiveCompleteSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "ObjectiveCompleteSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("objective_text", text)
	sfx.set_meta("objective_sound_id", str(cue.get("id", "objective_complete")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "objective_complete")))
	sfx.set_meta("objective_finale", bool(cue.get("finale", false)))
	sfx.set_meta("objective_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _show_objective_complete_flash(text: String, context: Dictionary = {}) -> void:
	if _objective_flash_label == null:
		return
	_objective_flash_label.text = text
	_objective_flash_label.visible = true
	_objective_flash_label.modulate.a = 1.0
	var fallback_state := "reward_ready" if text.to_lower().contains("reward") else "complete"
	var fallback_room := _objective_room_type_from_text(text)
	_objective_flash_label.set_meta("objective_state", str(context.get("objective_state", fallback_state)))
	_objective_flash_label.set_meta("objective_room_type", str(context.get("room_type_name", fallback_room)))
	_objective_flash_label.set_meta(
		"objective_next_action_key",
		str(context.get("next_action_key", "reward" if fallback_state == "reward_ready" else "door")))
	_objective_flash_label.set_meta(
		"objective_next_action_chain",
		str(context.get("next_action_chain", context.get("next_action_key", ""))))
	_objective_flash_label.set_meta(
		"objective_next_action_priority",
		str(context.get("next_action_priority", context.get("next_action_key", ""))))
	_objective_flash_label.set_meta("objective_text", text)
	_objective_flash_label.set_meta("objective_reward_ready", bool(context.get("reward_ready", fallback_state == "reward_ready")))
	_objective_flash_label.set_meta("objective_run_finale", bool(context.get("run_finale", false)))
	var tween := _objective_flash_label.create_tween()
	tween.tween_property(_objective_flash_label, "modulate:a", 0.0, 0.85)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _objective_flash_label != null:
			_objective_flash_label.visible = false)

func _on_room_mastery_awarded(context: Dictionary) -> void:
	_show_room_mastery_flash(context)

func _show_room_mastery_flash(context: Dictionary) -> void:
	if _room_mastery_flash_label == null:
		return
	var raw_badges: Variant = context.get("badges", [])
	var badges: Array = []
	if raw_badges is Array:
		badges = raw_badges
	var summary := str(context.get("summary", "")).strip_edges()
	if summary == "" and not badges.is_empty():
		var parts: Array[String] = []
		for badge in badges:
			parts.append(str(badge))
		summary = " | ".join(parts)
	if summary == "":
		summary = "Clear"
	_room_mastery_flash_label.text = "Mastery: %s" % summary
	_room_mastery_flash_label.visible = true
	_room_mastery_flash_label.modulate.a = 1.0
	_room_mastery_flash_label.set_meta("mastery_room_id", int(context.get("room_id", -1)))
	_room_mastery_flash_label.set_meta("mastery_room_type", str(context.get("room_type_name", "")))
	_room_mastery_flash_label.set_meta("mastery_summary", summary)
	_room_mastery_flash_label.set_meta("mastery_badges", badges.duplicate(true))
	_room_mastery_flash_label.set_meta("perfect_clear", bool(context.get("perfect_clear", false)))
	_room_mastery_flash_label.set_meta("close_call", bool(context.get("close_call", false)))
	_room_mastery_flash_label.set_meta("critical_path", bool(context.get("critical_path", false)))
	_room_mastery_flash_label.set_meta("reward_room", bool(context.get("reward_room", false)))
	_room_mastery_flash_label.set_meta("damage_taken", int(context.get("damage_taken", 0)))
	var tween := _room_mastery_flash_label.create_tween()
	tween.tween_property(_room_mastery_flash_label, "modulate:a", 0.0, 0.75)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _room_mastery_flash_label != null:
			_room_mastery_flash_label.visible = false)

func _objective_room_type_from_text(text: String) -> String:
	var marker := " complete"
	var idx := text.find(marker)
	if idx < 0:
		return "ROOM"
	var prefix := text.substr(0, idx)
	var parts := prefix.split("|")
	return str(parts[parts.size() - 1]).strip_edges()

func _on_skill_cooldown_changed(skill_id: String, left: float, total: float) -> void:
	var is_alt := _player != null and str(_player.skill_alt.get("id", "")) == skill_id
	var label := _skill_alt_label if is_alt else _skill_label
	var fill := _skill_alt_cd_fill if is_alt else _skill_cd_fill
	var badge := _skill_alt_cd_badge if is_alt else _skill_cd_badge
	if label == null or fill == null:
		return
	var icon := get_node_or_null("SecondarySkillCooldownIcon" if is_alt else "SkillCooldownIcon") as ColorRect
	var profile: Dictionary = CombatFxScript.skill_feedback_profile(skill_id)
	_apply_skill_cooldown_profile(skill_id, profile, label, fill, icon, badge, is_alt)
	var ratio := clampf(left / maxf(total, 0.001), 0.0, 1.0)
	var was_cooling := bool(_skill_was_cooling.get(skill_id, false))
	var skill_data := _skill_data_for(skill_id, is_alt)
	var cooldown := float(skill_data.get("cooldown", total))
	var cost := int(skill_data.get("cost", 0))
	var slot_text := "C" if is_alt else "E"
	var ready_text := "R" if left <= 0.0 else "%.1fs" % left
	label.text = "%s %s %s" % [
		slot_text,
		_compact_name(_readable_id(skill_id), 12),
		"R" if left <= 0.0 else ready_text,
	] if _compact_gameplay_hud else "%s: %s %s | Cost %d | CD %.1fs" % [
		slot_text,
		_readable_id(skill_id),
		"READY" if left <= 0.0 else "%.1fs" % left,
		cost,
		cooldown,
	]
	var base_y := 132.0 if is_alt else 116.0
	fill.size.y = 12.0 * (1.0 - ratio)
	fill.position.y = base_y + 12.0 * ratio
	_set_skill_cooldown_state([label, fill, icon, badge], left, ratio)
	_set_skill_cooldown_contract([label, fill, icon, badge],
		cost, left, cooldown, is_alt)
	_set_hud_tooltip([label, fill, icon, badge], "%s [%s] %s | Cost %d | CD %.1fs" % [
		_readable_id(skill_id),
		"C" if is_alt else "E",
		"READY" if left <= 0.0 else "%.1fs" % left,
		cost,
		cooldown,
	])
	_skill_was_cooling[skill_id] = left > 0.0
	if was_cooling and left <= 0.0:
		var slot_label := "C" if is_alt else "E"
		var ready_cue: Dictionary = AudioCueDBScript.skill_ready_cue(skill_id)
		_show_skill_flash("%s Ready: %s" % [slot_label, _readable_id(skill_id)], {
			"hud_flash_kind": "skill_ready",
			"skill_ready_id": skill_id,
			"skill_ready_slot": "secondary" if is_alt else "primary",
			"skill_ready_input_action": "skill_alt" if is_alt else "skill",
			"skill_ready_key_label": slot_label,
			"skill_ready_cooldown_hint": str(profile.get("cooldown_hint", "")),
			"skill_ready_feel_tier": str(profile.get("feel_tier", "steady")),
			"skill_ready_sound_id": str(ready_cue.get("id", "skill_ready")),
		})
		_play_skill_ready_sfx(skill_id, is_alt)

func _apply_skill_cooldown_profile(
		skill_id: String,
		profile: Dictionary,
		label: Label,
		fill: ColorRect,
		icon: ColorRect,
		badge: Label,
		is_alt: bool) -> void:
	var family := str(profile.get("family", "generic"))
	var style := str(profile.get("style", "generic"))
	var cast_label := str(profile.get("cast_label", _readable_id(skill_id)))
	var cooldown_icon := str(profile.get("cooldown_icon", "skill"))
	var feedback_hint := str(profile.get("feedback_hint", ""))
	var impact_cue := str(profile.get("impact_cue", ""))
	var feel_tier := str(profile.get("feel_tier", "steady"))
	var cooldown_hint := str(profile.get("cooldown_hint", ""))
	var color: Color = profile.get("color", Color(0.75, 0.9, 1.0, 0.9))
	var slot := "secondary" if is_alt else "primary"
	for node in [label, fill, icon, badge]:
		if node == null:
			continue
		node.set_meta("skill_id", skill_id)
		node.set_meta("skill_family", family)
		node.set_meta("skill_style", style)
		node.set_meta("skill_cast_label", cast_label)
		node.set_meta("skill_cooldown_icon", cooldown_icon)
		node.set_meta("skill_feedback_hint", feedback_hint)
		node.set_meta("skill_impact_cue", impact_cue)
		node.set_meta("skill_feel_tier", feel_tier)
		node.set_meta("skill_cooldown_hint", cooldown_hint)
		node.set_meta("skill_slot", slot)
	fill.color = color
	if icon != null:
		var icon_color := color.darkened(0.62)
		icon_color.a = 0.78
		icon.color = icon_color
		_update_cooldown_sprite_icon(icon, cooldown_icon)
	if badge != null:
		badge.add_theme_color_override("font_color", color.lightened(0.18))

func _set_skill_cooldown_state(nodes: Array, left: float, ratio: float) -> void:
	var state := "ready" if left <= 0.0 else "cooling"
	for node in nodes:
		if node == null:
			continue
		node.set_meta("cooldown_state", state)
		node.set_meta("cooldown_left", left)
		node.set_meta("cooldown_ratio", ratio)
		node.set_meta("skill_cooldown_fraction", ratio)
		node.set_meta("skill_cooldown_progress_fraction", 1.0 - ratio)

func _set_skill_cooldown_contract(
		nodes: Array,
		cost: int,
		left: float,
		total: float,
		is_alt: bool,
) -> void:
	var input_label := "C" if is_alt else "E"
	var ready_text := "READY" if left <= 0.0 else "%.1fs" % left
	for node in nodes:
		if node == null:
			continue
		node.set_meta("skill_input_label", input_label)
		node.set_meta("skill_input_action", "skill_alt" if is_alt else "skill")
		node.set_meta("skill_key_label", input_label)
		node.set_meta("skill_ready_text", ready_text)
		node.set_meta("skill_cost", cost)
		node.set_meta("skill_cooldown_left", left)
		node.set_meta("skill_cooldown_total", total)
		node.set_meta("skill_ready", left <= 0.0)

func _set_hud_tooltip(nodes: Array, text: String) -> void:
	for node in nodes:
		if node is Control:
			(node as Control).tooltip_text = text

func _on_skill_cast(skill_id: String, cooldown: float) -> void:
	_show_skill_cast_pulse(skill_id, cooldown)
	var profile: Dictionary = CombatFxScript.skill_feedback_profile(skill_id)
	var impact_cue := str(profile.get("impact_cue", ""))
	_show_skill_flash("Cast: %s | %s | %.1fs CD | SFX %s" % [
		_readable_id(skill_id),
		impact_cue,
		cooldown,
		_skill_sound_id(skill_id),
	], {
		"hud_flash_kind": "skill_cast",
		"skill_cast_id": skill_id,
		"skill_impact_cue": impact_cue,
		"skill_sound_id": _skill_sound_id(skill_id),
		"skill_cooldown": cooldown,
	})

func _on_skill_blocked(skill_id: String, reason: String, detail: Dictionary) -> void:
	_show_skill_flash(_skill_blocked_text(skill_id, reason, detail))
	_play_skill_blocked_sfx(skill_id, reason, detail)

func _on_dash_blocked(reason: String, detail: Dictionary) -> void:
	_show_skill_flash(_dash_blocked_text(reason, detail))
	_play_dash_blocked_sfx(reason, detail)

func _on_weapon_attack_blocked(weapon_id: String, reason: String, detail: Dictionary) -> void:
	_show_skill_flash(_weapon_attack_blocked_text(weapon_id, reason, detail))
	_play_weapon_attack_blocked_sfx(weapon_id, reason, detail)

func _on_active_reload_window_changed(status: Dictionary) -> void:
	if _active_reload_window_label == null:
		return
	if not bool(status.get("in_window", false)):
		_clear_active_reload_window_label()
		return
	var left := float(status.get("cooldown_left", 0.0))
	var damage_mult := float(status.get("damage_mult", 1.0))
	_active_reload_window_label.text = "Active Reload [X] %.1fs" % left
	_active_reload_window_label.visible = true
	_active_reload_window_label.modulate.a = 1.0
	_active_reload_window_label.tooltip_text = "Active Reload [X] | +%d%% next magazine" % int(round((damage_mult - 1.0) * 100.0))
	_active_reload_window_label.set_meta("active_reload_in_window", true)
	_active_reload_window_label.set_meta("active_reload_cooldown_left", left)
	_active_reload_window_label.set_meta(
		"active_reload_window_seconds",
		float(status.get("window_seconds", 0.0)))
	_active_reload_window_label.set_meta("active_reload_damage_mult", damage_mult)
	_active_reload_window_label.set_meta("active_reload_weapon_id", str(status.get("weapon_id", "")))
	_active_reload_window_label.set_meta("active_reload_weapon_name", str(status.get("weapon_name", "")))

func _on_active_reload_performed(status: Dictionary) -> void:
	_clear_active_reload_window_label()
	var bonus := int(round((float(status.get("damage_mult", 1.0)) - 1.0) * 100.0))
	_show_weapon_flash("Active Reload +%d%%" % bonus)

func _clear_active_reload_window_label() -> void:
	if _active_reload_window_label == null:
		return
	_active_reload_window_label.text = ""
	_active_reload_window_label.visible = false
	_active_reload_window_label.tooltip_text = ""
	_active_reload_window_label.set_meta("active_reload_in_window", false)
	_active_reload_window_label.set_meta("active_reload_cooldown_left", 0.0)
	_active_reload_window_label.set_meta("active_reload_window_seconds", 0.0)
	_active_reload_window_label.set_meta("active_reload_damage_mult", 1.0)
	_active_reload_window_label.set_meta("active_reload_weapon_id", "")
	_active_reload_window_label.set_meta("active_reload_weapon_name", "")

func _weapon_attack_blocked_text(weapon_id: String, reason: String, detail: Dictionary) -> String:
	var weapon_name := str(detail.get("weapon_name", _readable_id(weapon_id)))
	match reason:
		"cooldown":
			return "Blocked: %s | %.1fs CD" % [
				weapon_name,
				float(detail.get("cooldown_left", 0.0)),
			]
		"resource":
			return "Blocked: %s | Need %d %s" % [
				weapon_name,
				int(ceilf(float(detail.get("cost", 0.0)))),
				_resource_short_label(str(detail.get("resource_type", "resource"))),
			]
		_:
			return "Blocked: %s" % weapon_name

func _resource_short_label(resource_id: String) -> String:
	match resource_id:
		"mana":
			return "MP"
		"energy":
			return "EN"
		_:
			return "resource"

func _dash_blocked_text(reason: String, detail: Dictionary) -> String:
	match reason:
		"cooldown":
			return "Dash blocked | %.1fs CD" % float(detail.get("cooldown_left", 0.0))
		_:
			return "Dash blocked"

func _skill_blocked_text(skill_id: String, reason: String, detail: Dictionary) -> String:
	match reason:
		"cooldown":
			return "Blocked: %s | %.1fs CD" % [
				_readable_id(skill_id),
				float(detail.get("cooldown_left", 0.0)),
			]
		"resource":
			return "Blocked: %s | Need %d resource" % [
				_readable_id(skill_id),
				int(detail.get("cost", 0)),
			]
		"soul_slots":
			return "Blocked: %s | Soul Slots %d/%d" % [
				_readable_id(skill_id),
				int(detail.get("slots_used", 0)),
				int(detail.get("slot_limit", 0)),
			]
		"no_summon":
			return "Blocked: %s | Need summon" % _readable_id(skill_id)
		"no_trap":
			return "Blocked: %s | Need trap" % _readable_id(skill_id)
		"empty":
			return "Blocked: No skill"
		_:
			return "Blocked: %s" % _readable_id(skill_id)

func _show_skill_cast_pulse(skill_id: String, cooldown: float) -> void:
	if _skill_cast_pulse == null:
		return
	var is_alt := _player != null and str(_player.skill_alt.get("id", "")) == skill_id
	var profile: Dictionary = CombatFxScript.skill_feedback_profile(skill_id)
	var color: Color = profile.get("color", Color(0.75, 0.9, 1.0, 0.9))
	color.a = 0.9
	_skill_cast_pulse.position = Vector2(6.0, 130.0 if is_alt else 114.0)
	_skill_cast_pulse.size = Vector2(16, 16)
	_skill_cast_pulse.color = color
	_skill_cast_pulse.visible = true
	_skill_cast_pulse.modulate.a = 1.0
	_skill_cast_pulse.set_meta("skill_id", skill_id)
	_skill_cast_pulse.set_meta("skill_slot", "secondary" if is_alt else "primary")
	_skill_cast_pulse.set_meta("skill_cooldown", cooldown)
	_skill_cast_pulse.set_meta("skill_sound_id", _skill_sound_id(skill_id))
	_skill_cast_pulse.set_meta("skill_family", str(profile.get("family", "generic")))
	_skill_cast_pulse.set_meta("skill_style", str(profile.get("style", "generic")))
	_skill_cast_pulse.set_meta("skill_impact_cue", str(profile.get("impact_cue", "")))
	_skill_cast_pulse.set_meta("skill_feel_tier", str(profile.get("feel_tier", "steady")))
	_skill_cast_pulse.set_meta("skill_cooldown_hint", str(profile.get("cooldown_hint", "")))
	_skill_cast_pulse.set_meta("skill_input_role", "secondary" if is_alt else "primary")
	var tween := _skill_cast_pulse.create_tween()
	tween.tween_property(_skill_cast_pulse, "modulate:a", 0.0, 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _skill_cast_pulse != null:
			_skill_cast_pulse.visible = false)

func _skill_sound_id(skill_id: String) -> String:
	var cue: Dictionary = AudioCueDBScript.skill_cast_cue(skill_id)
	return str(cue.get("id", "generic_cast"))

func _play_skill_ready_sfx(skill_id: String, is_alt: bool) -> void:
	var cue: Dictionary = AudioCueDBScript.skill_ready_cue(skill_id)
	var profile: Dictionary = CombatFxScript.skill_feedback_profile(skill_id)
	var sfx := get_node_or_null("SkillReadySfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "SkillReadySfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("skill_ready_id", skill_id)
	sfx.set_meta("skill_ready_slot", "secondary" if is_alt else "primary")
	sfx.set_meta("skill_ready_input_action", "skill_alt" if is_alt else "skill")
	sfx.set_meta("skill_ready_key_label", "C" if is_alt else "E")
	sfx.set_meta("skill_ready_sound_id", str(cue.get("id", "skill_ready")))
	sfx.set_meta("skill_ready_cooldown_hint", str(profile.get("cooldown_hint", "")))
	sfx.set_meta("skill_ready_feel_tier", str(profile.get("feel_tier", "steady")))
	sfx.set_meta("skill_family", str(cue.get("family", "generic")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "skill_ready")))
	sfx.set_meta("skill_ready_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _play_skill_blocked_sfx(skill_id: String, reason: String, detail: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.skill_blocked_cue(reason)
	var sfx := get_node_or_null("SkillBlockedSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "SkillBlockedSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("skill_blocked_id", skill_id)
	sfx.set_meta("skill_blocked_reason", reason)
	sfx.set_meta("skill_blocked_slot", str(detail.get("slot", "")))
	sfx.set_meta("skill_blocked_sound_id", str(cue.get("id", "skill_blocked")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "skill_blocked")))
	sfx.set_meta("skill_blocked_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _play_dash_blocked_sfx(reason: String, detail: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.skill_blocked_cue(reason)
	var sfx := get_node_or_null("DashBlockedSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "DashBlockedSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("dash_blocked_reason", reason)
	sfx.set_meta("dash_blocked_cooldown_left", float(detail.get("cooldown_left", 0.0)))
	sfx.set_meta("dash_blocked_sound_id", str(cue.get("id", "skill_blocked")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "skill_blocked")))
	sfx.set_meta("dash_blocked_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _play_weapon_attack_blocked_sfx(weapon_id: String, reason: String, detail: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.skill_blocked_cue(reason)
	var sfx := get_node_or_null("WeaponBlockedSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "WeaponBlockedSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("weapon_blocked_id", weapon_id)
	sfx.set_meta("weapon_blocked_name", str(detail.get("weapon_name", "")))
	sfx.set_meta("weapon_blocked_reason", reason)
	sfx.set_meta("weapon_blocked_cost", float(detail.get("cost", 0.0)))
	sfx.set_meta("weapon_blocked_cooldown_left", float(detail.get("cooldown_left", 0.0)))
	sfx.set_meta("weapon_blocked_sound_id", str(cue.get("id", "skill_blocked")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "skill_blocked")))
	sfx.set_meta("weapon_blocked_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _play_dash_ready_sfx() -> void:
	var cue: Dictionary = AudioCueDBScript.dash_ready_cue()
	var sfx := get_node_or_null("DashReadySfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "DashReadySfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("dash_ready_sound_id", str(cue.get("id", "dash_ready")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "dash_ready")))
	sfx.set_meta("dash_ready_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _play_ultimate_ready_sfx(ultimate_id: String) -> void:
	var cue: Dictionary = AudioCueDBScript.ultimate_ready_cue(ultimate_id)
	var sfx := get_node_or_null("UltimateReadySfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "UltimateReadySfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("ultimate_ready_id", ultimate_id)
	sfx.set_meta("ultimate_ready_sound_id", str(cue.get("id", "ultimate_ready")))
	sfx.set_meta("skill_family", str(cue.get("family", "generic")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "ultimate_ready")))
	sfx.set_meta("ultimate_ready_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _play_ultimate_blocked_sfx(ultimate_id: String, reason: String, detail: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.skill_blocked_cue(reason)
	var sfx := get_node_or_null("UltimateBlockedSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "UltimateBlockedSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("ultimate_blocked_id", ultimate_id)
	sfx.set_meta("ultimate_blocked_reason", reason)
	sfx.set_meta("ultimate_blocked_charge", float(detail.get("charge", 0.0)))
	sfx.set_meta("ultimate_blocked_cost", float(detail.get("cost", 0.0)))
	sfx.set_meta("ultimate_blocked_sound_id", str(cue.get("id", "skill_blocked")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "skill_blocked")))
	sfx.set_meta("ultimate_blocked_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _on_dash_cooldown_changed(left: float, total: float) -> void:
	if _dash_label == null or _dash_cd_fill == null:
		return
	var ratio := clampf(left / maxf(total, 0.001), 0.0, 1.0)
	var was_cooling := _dash_was_cooling
	var dash_icon := get_node_or_null("DashCooldownIcon") as ColorRect
	_update_cooldown_sprite_icon(dash_icon, "dash")
	_dash_label.text = "Dash %s" % ("R" if left <= 0.0 else "%.1fs" % left) \
		if _compact_gameplay_hud else "Dash: %s" % ("READY" if left <= 0.0 else "%.1fs" % left)
	_dash_cd_fill.size.y = 12.0 * (1.0 - ratio)
	_dash_cd_fill.position.y = 148.0 + 12.0 * ratio
	var ready_text := "READY" if left <= 0.0 else "%.1fs" % left
	for node in [_dash_label, _dash_cd_fill, dash_icon]:
		if node == null:
			continue
		node.set_meta("cooldown_state", "ready" if left <= 0.0 else "cooling")
		node.set_meta("cooldown_left", left)
		node.set_meta("cooldown_ratio", ratio)
		node.set_meta("dash_input_action", "dash")
		node.set_meta("dash_key_label", "Space")
		node.set_meta("dash_ready_text", ready_text)
		node.set_meta("dash_cooldown_left", left)
		node.set_meta("dash_cooldown_total", total)
		node.set_meta("dash_ready", left <= 0.0)
	_set_hud_tooltip([_dash_label, _dash_cd_fill, dash_icon], "Dash [Space] %s | CD %.1fs" % [
		"READY" if left <= 0.0 else "%.1fs" % left,
		total,
	])
	_dash_was_cooling = left > 0.0
	if was_cooling and left <= 0.0:
		_show_skill_flash("Dash ready")
		_play_dash_ready_sfx()

func _show_skill_flash(text: String, metadata: Dictionary = {}) -> void:
	if _skill_cast_flash_label == null:
		return
	_skill_cast_flash_label.text = text
	_skill_cast_flash_label.visible = true
	_skill_cast_flash_label.modulate.a = 1.0
	for key in [
		"hud_flash_kind",
		"skill_ready_id",
		"skill_ready_slot",
		"skill_ready_input_action",
		"skill_ready_key_label",
		"skill_ready_cooldown_hint",
		"skill_ready_feel_tier",
		"skill_ready_sound_id",
		"ultimate_ready_id",
		"ultimate_ready_slot",
		"skill_cast_id",
		"skill_impact_cue",
		"skill_sound_id",
		"skill_cooldown",
	]:
		if _skill_cast_flash_label.has_meta(key):
			_skill_cast_flash_label.remove_meta(key)
	for key in metadata.keys():
		_skill_cast_flash_label.set_meta(str(key), metadata[key])
	var tween := _skill_cast_flash_label.create_tween()
	tween.tween_property(_skill_cast_flash_label, "modulate:a", 0.0, 0.55)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _skill_cast_flash_label != null:
			_skill_cast_flash_label.visible = false)

func _show_weapon_flash(text: String) -> void:
	if _weapon_flash_label == null:
		return
	_weapon_flash_label.text = text
	_weapon_flash_label.visible = true
	_weapon_flash_label.modulate.a = 1.0
	var tween := _weapon_flash_label.create_tween()
	tween.tween_property(_weapon_flash_label, "modulate:a", 0.0, 0.65)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _weapon_flash_label != null:
			_weapon_flash_label.visible = false)

func _show_key_flash(text: String) -> void:
	if _key_flash_label == null:
		return
	_key_flash_label.text = text
	_key_flash_label.visible = true
	_key_flash_label.modulate.a = 1.0
	var tween := _key_flash_label.create_tween()
	tween.tween_property(_key_flash_label, "modulate:a", 0.0, 0.65)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _key_flash_label != null:
			_key_flash_label.visible = false)

func _show_meta_currency_flash(text: String) -> void:
	if _meta_currency_flash_label == null:
		return
	_meta_currency_flash_label.text = text
	_meta_currency_flash_label.visible = true
	_meta_currency_flash_label.modulate.a = 1.0
	var tween := _meta_currency_flash_label.create_tween()
	tween.tween_property(_meta_currency_flash_label, "modulate:a", 0.0, 0.65)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _meta_currency_flash_label != null:
			_meta_currency_flash_label.visible = false)

func _readable_meta_currency(currency_id: String) -> String:
	return currency_id.replace("_", " ").capitalize()

func _play_meta_bonus_sfx(summary: String, meta: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.meta_bonus_cue(summary, meta)
	var sfx := get_node_or_null("MetaBonusSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "MetaBonusSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("meta_bonus_sound_id", str(cue.get("id", "meta_bonus_active")))
	sfx.set_meta("meta_bonus_summary", str(cue.get("summary", summary)))
	sfx.set_meta("meta_bonus_upgrade_count", int(cue.get("upgrade_count", 0)))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "meta_bonus")))
	sfx.set_meta("meta_bonus_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _meta_bonus_upgrade_count(meta: Dictionary) -> int:
	var upgrades: Dictionary = meta.get("upgrades", {})
	var count := 0
	for value in upgrades.values():
		if int(value) > 0:
			count += 1
	return count

func _show_gold_flash(text: String) -> void:
	if _gold_flash_label == null:
		return
	_gold_flash_label.text = text
	_gold_flash_label.visible = true
	_gold_flash_label.modulate.a = 1.0
	var tween := _gold_flash_label.create_tween()
	tween.tween_property(_gold_flash_label, "modulate:a", 0.0, 0.65)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _gold_flash_label != null:
			_gold_flash_label.visible = false)

func _on_ultimate_charge_changed(current: float, max_value: float) -> void:
	if _ultimate_label == null or _ultimate_charge_fill == null:
		return
	var ratio := clampf(current / maxf(max_value, 0.001), 0.0, 1.0)
	var was_ready := _ultimate_was_ready
	_ultimate_was_ready = ratio >= 1.0
	var ultimate_id := str(_player.ultimate.get("id", "")) if _player != null else "ultimate"
	_apply_ultimate_charge_profile(ultimate_id)
	var cost := float(_player.ultimate.get("cost", max_value)) if _player != null else max_value
	var ready_text := "READY" if ratio >= 1.0 else "%d%%" % int(round(ratio * 100.0))
	_ultimate_label.text = "V %s %s" % [
		_compact_name(_readable_id(ultimate_id), 13),
		"R" if ratio >= 1.0 else "%d%%" % int(round(ratio * 100.0)),
	] if _compact_gameplay_hud else "Ultimate: %s %s | Cost %d" % [
		_readable_id(ultimate_id),
		ready_text,
		int(cost),
	]
	_ultimate_charge_fill.size = Vector2(12.0, 12.0 * ratio)
	_ultimate_charge_fill.position = Vector2(8.0, 180.0 + 12.0 * (1.0 - ratio))
	var icon := get_node_or_null("UltimateChargeIcon") as ColorRect
	_set_ultimate_charge_contract(
		[_ultimate_label, _ultimate_charge_fill, icon],
		ultimate_id, ready_text, ratio, current, max_value, cost)
	if not was_ready and _ultimate_was_ready:
		_show_skill_flash("Ultimate Ready: %s" % _readable_id(ultimate_id), {
			"hud_flash_kind": "ultimate_ready",
			"ultimate_ready_id": ultimate_id,
			"ultimate_ready_slot": "ultimate",
		})
		_play_ultimate_ready_sfx(ultimate_id)

func _set_ultimate_charge_contract(
		nodes: Array,
		ultimate_id: String,
		ready_text: String,
		ratio: float,
		current: float,
		max_value: float,
		cost: float) -> void:
	var tooltip := "%s [V] %s | Charge %d/%d | Cost %d" % [
		_readable_id(ultimate_id),
		ready_text,
		int(current),
		int(max_value),
		int(cost),
	]
	for node in nodes:
		if node == null:
			continue
		node.set_meta("ultimate_input_action", "ultimate")
		node.set_meta("ultimate_key_label", "V")
		node.set_meta("ultimate_ready", ratio >= 1.0)
		node.set_meta("ultimate_ready_text", ready_text)
		node.set_meta("ultimate_charge_current", current)
		node.set_meta("ultimate_charge_max", max_value)
		node.set_meta("ultimate_charge_ratio", ratio)
		node.set_meta("ultimate_charge_cost", cost)
		if node is Control:
			(node as Control).tooltip_text = tooltip

func _apply_ultimate_charge_profile(ultimate_id: String) -> void:
	var profile: Dictionary = CombatFxScript.skill_feedback_profile(ultimate_id)
	var family := str(profile.get("family", "generic"))
	var style := str(profile.get("style", "generic"))
	var color: Color = profile.get("color", Color(0.9, 0.55, 1.0, 0.9))
	var icon := get_node_or_null("UltimateChargeIcon") as ColorRect
	for node in [_ultimate_label, _ultimate_charge_fill, icon]:
		if node == null:
			continue
		node.set_meta("ultimate_id", ultimate_id)
		node.set_meta("skill_family", family)
		node.set_meta("skill_style", style)
	_ultimate_charge_fill.color = color
	_ultimate_label.add_theme_color_override("font_color", color.lightened(0.08))
	if icon != null:
		var icon_color := color.darkened(0.62)
		icon_color.a = 0.78
		icon.color = icon_color
		_update_cooldown_sprite_icon(icon, str(profile.get("cooldown_icon", "blade")))

func _on_ultimate_cast(ultimate_id: String) -> void:
	_show_skill_flash("Ultimate: %s | SFX %s" % [
		_readable_id(ultimate_id),
		_skill_sound_id(ultimate_id),
	])

func _on_ultimate_blocked(ultimate_id: String, reason: String, detail: Dictionary) -> void:
	_show_skill_flash(_ultimate_blocked_text(ultimate_id, reason, detail))
	_play_ultimate_blocked_sfx(ultimate_id, reason, detail)

func _ultimate_blocked_text(ultimate_id: String, reason: String, detail: Dictionary) -> String:
	match reason:
		"charge":
			return "Blocked: %s | Charge %d/%d" % [
				_readable_id(ultimate_id),
				int(detail.get("charge", 0.0)),
				int(detail.get("cost", 0.0)),
			]
		"empty":
			return "Blocked: No ultimate"
		_:
			return "Blocked: %s" % _readable_id(ultimate_id)

func _skill_data_for(skill_id: String, is_alt: bool) -> Dictionary:
	if _player == null:
		return {"id": skill_id}
	var candidate: Dictionary = _player.skill_alt if is_alt else _player.skill
	if str(candidate.get("id", "")) == skill_id:
		return candidate
	var other: Dictionary = _player.skill if is_alt else _player.skill_alt
	if str(other.get("id", "")) == skill_id:
		return other
	return {"id": skill_id}

func _readable_id(id: String) -> String:
	var clean := id.strip_edges()
	if clean == "":
		return "-"
	return clean.replace("_", " ").capitalize()

func _on_upgrades_changed(summary: String) -> void:
	if _build_label == null:
		return
	var breakdown := ""
	if _player != null and _player.has_method("rune_socket_summary"):
		breakdown = str(_player.call("rune_socket_summary"))
	var archetype := ""
	if _player != null and _player.has_method("build_archetype_summary"):
		archetype = str(_player.call("build_archetype_summary"))
	var power_arc := ""
	if _player != null and _player.has_method("run_power_arc_summary"):
		power_arc = str(_player.call("run_power_arc_summary"))
	var power_tier := ""
	if _player != null and _player.has_method("run_power_tier"):
		power_tier = str(_player.call("run_power_tier"))
	var next_milestone := ""
	if _player != null and _player.has_method("next_power_milestone_hint"):
		next_milestone = str(_player.call("next_power_milestone_hint"))
	var stat_summary := ""
	if _player != null and _player.has_method("run_stat_summary"):
		stat_summary = str(_player.call("run_stat_summary"))
	var set_bonuses := ""
	if _player != null and _player.has_method("upgrade_set_bonus_summary"):
		set_bonuses = str(_player.call("upgrade_set_bonus_summary"))
	var lines: Array[String] = ["Build: %s" % summary]
	if power_arc != "":
		lines.append("Power Arc: %s" % power_arc)
	if next_milestone != "":
		lines.append(next_milestone)
	if archetype != "":
		lines.append("Archetype: %s" % archetype)
	if breakdown != "":
		lines.append(breakdown)
	if set_bonuses != "" and set_bonuses != "None":
		lines.append("Set Bonuses: %s" % set_bonuses)
	if stat_summary != "":
		lines.append("Power Stats: %s" % stat_summary)
	_build_label.text = "\n".join(lines)
	_build_label.visible = not _compact_gameplay_hud
	_build_label.set_meta("build_archetype", archetype)
	_build_label.set_meta("rune_socket_summary", breakdown)
	_build_label.set_meta("run_power_arc", power_arc)
	_build_label.set_meta("next_power_milestone", next_milestone)
	_build_label.set_meta("run_stat_summary", stat_summary)
	_build_label.set_meta("upgrade_set_bonuses", set_bonuses)
	_update_reward_path_label()
	_update_power_tier_feedback(power_tier, power_arc)

func _update_reward_path_label() -> void:
	if _reward_path_label == null:
		return
	if _player == null or not is_instance_valid(_player) \
			or not _player.has_method("upgrade_history_summary"):
		_reward_path_label.text = ""
		_reward_path_label.visible = false
		return
	var history := str(_player.call("upgrade_history_summary", 4)).strip_edges()
	var count := int(_player.call("upgrade_history_count")) \
		if _player.has_method("upgrade_history_count") else 0
	if history == "" or history == "None" or count <= 0:
		_reward_path_label.text = ""
		_reward_path_label.visible = false
		_reward_path_label.set_meta("upgrade_history_count", count)
		_reward_path_label.set_meta("upgrade_history", "")
		_reward_path_label.set_meta("last_reward_pick", "")
		return
	var picks := history.split(" -> ", false)
	var last_pick := str(picks[picks.size() - 1]) if not picks.is_empty() else ""
	_reward_path_label.text = "Reward Path: %s" % history
	_reward_path_label.visible = not _compact_gameplay_hud
	_reward_path_label.set_meta("upgrade_history_count", count)
	_reward_path_label.set_meta("upgrade_history", history)
	_reward_path_label.set_meta("last_reward_pick", last_pick)

func _update_run_decision_label() -> void:
	if _run_decision_label == null:
		return
	if _player == null or not is_instance_valid(_player):
		_clear_run_decision_label()
		return
	var room_history := _player_history("room_decision_history_summary", 3)
	var shop_history := _player_history("shop_purchase_history_summary", 2)
	var parts: Array[String] = []
	if room_history != "":
		parts.append(room_history)
	if shop_history != "":
		parts.append("Shop: %s" % shop_history)
	if parts.is_empty():
		_clear_run_decision_label()
		return
	var text := " | ".join(parts)
	var last_decision := _last_decision_from(parts)
	_run_decision_label.text = "Run Decisions: %s" % text
	_run_decision_label.visible = not _compact_gameplay_hud
	_run_decision_label.set_meta("room_decision_history", room_history)
	_run_decision_label.set_meta("shop_purchase_history", shop_history)
	_run_decision_label.set_meta("last_run_decision", last_decision)

func _player_history(method_name: String, max_items: int) -> String:
	if _player == null or not _player.has_method(method_name):
		return ""
	var history := str(_player.call(method_name, max_items)).strip_edges()
	return "" if history == "" or history == "None" else history

func _last_decision_from(parts: Array[String]) -> String:
	if parts.is_empty():
		return ""
	var last := str(parts[parts.size() - 1])
	var entries := last.split(" -> ", false)
	return str(entries[entries.size() - 1]) if not entries.is_empty() else last

func _clear_run_decision_label() -> void:
	_run_decision_label.text = ""
	_run_decision_label.visible = false
	_run_decision_label.set_meta("room_decision_history", "")
	_run_decision_label.set_meta("shop_purchase_history", "")
	_run_decision_label.set_meta("last_run_decision", "")

func _update_power_tier_feedback(power_tier: String, power_arc: String) -> void:
	var clean := power_tier.strip_edges()
	if clean == "":
		return
	if _last_power_tier == "":
		_last_power_tier = clean
		return
	if clean == _last_power_tier:
		return
	var previous := _last_power_tier
	_last_power_tier = clean
	_show_power_tier_flash(previous, clean, power_arc)

func _show_power_tier_flash(previous_tier: String, power_tier: String, power_arc: String) -> void:
	if _power_tier_flash_label == null:
		return
	_power_tier_flash_label.text = "Power Tier: %s" % power_tier
	_power_tier_flash_label.visible = true
	_power_tier_flash_label.modulate.a = 1.0
	_power_tier_flash_label.set_meta("previous_power_tier", previous_tier)
	_power_tier_flash_label.set_meta("power_tier", power_tier)
	_power_tier_flash_label.set_meta("run_power_arc", power_arc)
	_play_power_tier_sfx(previous_tier, power_tier, power_arc)
	var tween := _power_tier_flash_label.create_tween()
	tween.tween_property(_power_tier_flash_label, "modulate:a", 0.0, 0.95)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _power_tier_flash_label != null:
			_power_tier_flash_label.visible = false)

func _play_power_tier_sfx(previous_tier: String, power_tier: String, power_arc: String) -> void:
	var cue: Dictionary = AudioCueDBScript.power_tier_cue(previous_tier, power_tier, power_arc)
	var sfx := get_node_or_null("PowerTierSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "PowerTierSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("power_tier_sound_id", str(cue.get("id", "power_tier_up")))
	sfx.set_meta("previous_power_tier", str(cue.get("previous_tier", previous_tier)))
	sfx.set_meta("power_tier", str(cue.get("power_tier", power_tier)))
	sfx.set_meta("run_power_arc", str(cue.get("power_arc", power_arc)))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "power_tier")))
	sfx.set_meta("power_tier_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _on_boss_status_changed(status: Dictionary, preserve_last_attack: bool = false) -> void:
	if _boss_label == null or _boss_fill == null or _boss_bg == null:
		return
	if status.is_empty() or int(status.get("hp", 0)) <= 0:
		_clear_boss_status_labels(preserve_last_attack)
		return
	var hp := int(status.get("hp", 0))
	var max_value := maxi(int(status.get("max_hp", 1)), 1)
	var ratio := clampf(float(hp) / float(max_value), 0.0, 1.0)
	var boss_name := str(status.get("name", "Boss"))
	_boss_label.visible = true
	_boss_fill.visible = true
	_boss_bg.visible = true
	_boss_fill.size = Vector2(BOSS_BAR_W * ratio, 4.0)
	var parts: Array[String] = ["Boss: %s %d/%d" % [
		boss_name,
		hp,
		max_value,
	]]
	var phase_text := str(status.get("phase_text", ""))
	if phase_text != "":
		parts.append(phase_text)
	var next_attack := str(status.get("next_attack", ""))
	if next_attack == "":
		next_attack = _structured_next_attack_text(status)
	if next_attack != "":
		parts.append(next_attack)
	_boss_label.text = " | ".join(parts)
	_boss_label.set_meta("boss_name", boss_name)
	_boss_label.set_meta("boss_hp_current", hp)
	_boss_label.set_meta("boss_hp_max", max_value)
	_boss_label.set_meta("boss_hp_ratio", ratio)
	_boss_label.set_meta("next_attack_id", str(status.get("next_attack_id", "")))
	_boss_label.set_meta("next_attack_label", str(status.get("next_attack_label", "")))
	_boss_label.set_meta("next_attack_warning", str(status.get("next_attack_warning", "")))
	_boss_fill.set_meta("boss_name", boss_name)
	_boss_fill.set_meta("boss_hp_current", hp)
	_boss_fill.set_meta("boss_hp_max", max_value)
	_boss_fill.set_meta("boss_hp_ratio", ratio)
	_update_boss_enrage_warning(status)
	_update_boss_pattern_cue(status)

func _clear_boss_status_labels(preserve_last_attack: bool = false) -> void:
	_boss_label.visible = false
	_boss_label.text = ""
	_boss_label.set_meta("boss_name", "")
	_boss_label.set_meta("boss_hp_current", 0)
	_boss_label.set_meta("boss_hp_max", 0)
	_boss_label.set_meta("boss_hp_ratio", 0.0)
	_boss_label.set_meta("next_attack_id", "")
	_boss_label.set_meta("next_attack_label", "")
	_boss_label.set_meta("next_attack_warning", "")
	_boss_fill.visible = false
	_boss_fill.size = Vector2.ZERO
	_boss_fill.set_meta("boss_name", "")
	_boss_fill.set_meta("boss_hp_current", 0)
	_boss_fill.set_meta("boss_hp_max", 0)
	_boss_fill.set_meta("boss_hp_ratio", 0.0)
	_boss_bg.visible = false
	_update_boss_enrage_warning({})
	_update_boss_pattern_cue({})
	if _boss_last_attack_label == null or preserve_last_attack:
		return
	_boss_last_attack_label.visible = false
	_boss_last_attack_label.text = ""
	_boss_last_attack_label.set_meta("boss_attack", "")
	_boss_last_attack_label.set_meta("boss_attack_label", "")
	_boss_last_attack_label.set_meta("boss_variant_attack", "")
	_boss_last_attack_label.set_meta("boss_attack_count", 0)
	_boss_last_attack_label.set_meta("boss_pattern_label", "")
	_boss_last_attack_label.set_meta("boss_attack_warning", "")
	_boss_last_attack_label.set_meta("boss_counter_hint", "")
	_boss_last_attack_label.set_meta("boss_dodge_cue", "")
	_boss_last_attack_label.set_meta("boss_punish_window_seconds", 0.0)
	_boss_last_attack_label.set_meta("boss_safe_window_hint", "")
	_boss_last_attack_label.set_meta("boss_attack_sequence_index", 0)
	_boss_last_attack_label.set_meta("boss_previous_attack", "")
	_boss_last_attack_label.set_meta("boss_recent_attack_summary", "")

func _update_boss_enrage_warning(status: Dictionary) -> void:
	if _boss_enrage_warning_label == null:
		return
	var text := str(status.get("enrage_warning", ""))
	if text == "" and bool(status.get("enraged", false)):
		text = "ENRAGED"
	_boss_enrage_warning_label.text = text
	_boss_enrage_warning_label.visible = text != ""
	_boss_enrage_warning_label.set_meta("boss_enraged", bool(status.get("enraged", false)))
	_boss_enrage_warning_label.set_meta("boss_phase", int(status.get("phase", 0)))
	_boss_enrage_warning_label.set_meta("boss_phase_text", str(status.get("phase_text", "")))
	_boss_enrage_warning_label.set_meta("boss_pattern", str(status.get("pattern", "")))
	_boss_enrage_warning_label.set_meta("boss_pattern_label", str(status.get("pattern_label", "")))
	_boss_enrage_warning_label.set_meta("enrage_warning", text)

func _update_boss_pattern_cue(status: Dictionary) -> void:
	if _boss_pattern_cue_label == null:
		return
	var text := str(status.get("pattern_label", ""))
	if text == "" and str(status.get("pattern", "")) != "":
		text = "Pattern: %s" % str(status.get("pattern", "")).replace("_", " ").capitalize()
	var steps: Array = status.get("pattern_steps", [])
	if not steps.is_empty():
		text = "%s | Steps: %s" % [text, " -> ".join(steps)]
	var timeline := str(status.get("pattern_timeline", ""))
	if timeline == "":
		var current_step := str(status.get("current_pattern_step", ""))
		var next_step := str(status.get("next_pattern_step", ""))
		if current_step != "" or next_step != "":
			timeline = "Now: %s | Next: %s" % [current_step, next_step]
	if timeline != "":
		text = "%s | %s" % [text, timeline]
	var counter_hint := str(status.get("counter_hint", ""))
	if counter_hint != "":
		text = "%s | Counter: %s" % [text, counter_hint]
	var dodge_cue := str(status.get("dodge_cue", ""))
	if dodge_cue != "":
		text = "%s | Dodge: %s" % [text, dodge_cue]
	var punish_window := float(status.get("punish_window_seconds", 0.0))
	var safe_window_hint := str(status.get("safe_window_hint", ""))
	if punish_window > 0.0 or safe_window_hint != "":
		var punish_text := safe_window_hint if safe_window_hint != "" else "Counterattack"
		if punish_window > 0.0:
			punish_text = "%s %.1fs" % [punish_text, punish_window]
		text = "%s | Punish: %s" % [text, punish_text]
	var next_attack_preview := _structured_next_attack_preview(status)
	if next_attack_preview != "":
		text = "%s | Upcoming: %s" % [text, next_attack_preview]
	var arena_pressure := str(status.get("arena_pressure_summary", "")).strip_edges()
	if arena_pressure != "":
		text = "%s | Pressure: %s" % [text, arena_pressure]
	_boss_pattern_cue_label.text = text
	_boss_pattern_cue_label.visible = text != ""
	_boss_pattern_cue_label.set_meta("pattern_steps", " -> ".join(steps))
	_boss_pattern_cue_label.set_meta("pattern_step_index", int(status.get("pattern_step_index", -1)))
	_boss_pattern_cue_label.set_meta("current_pattern_step", str(status.get("current_pattern_step", "")))
	_boss_pattern_cue_label.set_meta("next_pattern_step", str(status.get("next_pattern_step", "")))
	_boss_pattern_cue_label.set_meta("pattern_timeline", timeline)
	_boss_pattern_cue_label.set_meta("counter_hint", counter_hint)
	_boss_pattern_cue_label.set_meta("dodge_cue", dodge_cue)
	_boss_pattern_cue_label.set_meta("punish_window_seconds", punish_window)
	_boss_pattern_cue_label.set_meta("safe_window_hint", safe_window_hint)
	_boss_pattern_cue_label.set_meta("next_attack_id", str(status.get("next_attack_id", "")))
	_boss_pattern_cue_label.set_meta("next_attack_label", str(status.get("next_attack_label", "")))
	_boss_pattern_cue_label.set_meta("next_attack_warning", str(status.get("next_attack_warning", "")))
	_boss_pattern_cue_label.set_meta("arena_pressure_summary", arena_pressure)
	_boss_pattern_cue_label.set_meta("enrage_intensity", str(status.get("enrage_intensity", "")))
	_boss_pattern_cue_label.set_meta("active_trap_count", int(status.get("active_trap_count", 0)))
	_boss_pattern_cue_label.set_meta("floating_gun_count", int(status.get("floating_gun_count", 0)))
	_boss_pattern_cue_label.set_meta("enrage_bullet_count", int(status.get("enrage_bullet_count", 0)))

func _structured_next_attack_text(status: Dictionary) -> String:
	var label := str(status.get("next_attack_label", "")).strip_edges()
	if label == "":
		return ""
	var seconds := float(status.get("next_attack_seconds", -1.0))
	return "Next: %s %.1fs" % [label, maxf(seconds, 0.0)]

func _structured_next_attack_preview(status: Dictionary) -> String:
	var label := str(status.get("next_attack_label", "")).strip_edges()
	if label == "":
		return ""
	var warning := str(status.get("next_attack_warning", "")).strip_edges()
	return label if warning == "" else "%s | %s" % [label, warning]

func _on_boss_phase_changed(status: Dictionary) -> void:
	if _boss_phase_flash_label == null:
		return
	_play_boss_phase_sfx(status)
	var phase_text := str(status.get("phase_text", ""))
	if phase_text == "":
		phase_text = "Phase %d" % int(status.get("phase", 0))
	var boss_name := str(status.get("name", "Boss"))
	var elapsed := float(status.get("elapsed_seconds", -1.0))
	var elapsed_text := " @%.1fs" % elapsed if elapsed >= 0.0 else ""
	_boss_phase_flash_label.text = "%s: %s%s" % [boss_name, phase_text, elapsed_text]
	_boss_phase_flash_label.visible = true
	_boss_phase_flash_label.set_meta("boss_phase_elapsed_seconds", elapsed)
	_boss_phase_flash_label.modulate.a = 1.0
	var tween := _boss_phase_flash_label.create_tween()
	tween.tween_property(_boss_phase_flash_label, "modulate:a", 0.0, 0.9)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _boss_phase_flash_label != null:
			_boss_phase_flash_label.visible = false)

func _play_boss_phase_sfx(status: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.boss_phase_cue(status)
	var sfx := get_node_or_null("BossPhaseSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "BossPhaseSfx"
		add_child(sfx)
	else:
		sfx.stop()
	var pattern_steps: Array = status.get("pattern_steps", [])
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("boss_phase", int(status.get("phase", 0)))
	sfx.set_meta("boss_phase_text", str(status.get("phase_text", "")))
	sfx.set_meta("boss_phase_elapsed_seconds", float(status.get("elapsed_seconds", -1.0)))
	sfx.set_meta("boss_enraged", bool(status.get("enraged", false)))
	sfx.set_meta("boss_pattern", str(status.get("pattern", "")))
	sfx.set_meta("boss_pattern_label", str(status.get("pattern_label", "")))
	sfx.set_meta("boss_pattern_steps", " -> ".join(pattern_steps))
	sfx.set_meta("boss_pattern_step_index", int(status.get("pattern_step_index", -1)))
	sfx.set_meta("boss_current_pattern_step", str(status.get("current_pattern_step", "")))
	sfx.set_meta("boss_next_pattern_step", str(status.get("next_pattern_step", "")))
	sfx.set_meta("boss_pattern_timeline", str(status.get("pattern_timeline", "")))
	sfx.set_meta("boss_counter_hint", str(status.get("counter_hint", "")))
	sfx.set_meta("boss_dodge_cue", str(status.get("dodge_cue", "")))
	sfx.set_meta("boss_punish_window_seconds", float(status.get("punish_window_seconds", 0.0)))
	sfx.set_meta("boss_safe_window_hint", str(status.get("safe_window_hint", "")))
	sfx.set_meta("boss_phase_sound_id", str(cue.get("id", "boss_phase_shift")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "boss_phase")))
	sfx.set_meta("boss_phase_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _on_boss_attack_cued(status: Dictionary) -> void:
	if _boss_attack_flash_label == null:
		return
	_play_boss_attack_sfx(status)
	_boss_last_attack_hold = 2.0
	_update_boss_last_attack(status)
	var label := str(status.get("variant_attack_label", status.get("attack_label", "Boss Attack")))
	var count_text := ""
	if int(status.get("projectile_count", 0)) > 0:
		count_text = " x%d" % int(status.get("projectile_count", 0))
	elif int(status.get("hazard_count", 0)) > 0:
		count_text = " x%d" % int(status.get("hazard_count", 0))
	var warning := str(status.get("variant_warning", status.get("warning", "")))
	var elapsed := float(status.get("elapsed_seconds", -1.0))
	_boss_attack_flash_label.text = "%s%s%s" % [
		label,
		count_text,
		"%s%s" % [
			" | %s" % warning if warning != "" else "",
			_boss_elapsed_text(elapsed),
		],
	]
	_boss_attack_flash_label.visible = true
	_boss_attack_flash_label.set_meta("boss_attack_elapsed_seconds", elapsed)
	_boss_attack_flash_label.modulate.a = 1.0
	var tween := _boss_attack_flash_label.create_tween()
	tween.tween_property(_boss_attack_flash_label, "modulate:a", 0.0, 0.55)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if _boss_attack_flash_label != null:
			_boss_attack_flash_label.visible = false)

func _update_boss_last_attack(status: Dictionary) -> void:
	if _boss_last_attack_label == null:
		return
	var label := str(status.get("variant_attack_label", status.get("attack_label", "Boss Attack")))
	var count := int(status.get("projectile_count", status.get("hazard_count", 0)))
	var warning := str(status.get("variant_warning", status.get("warning", "")))
	var pattern := str(status.get("pattern_label", ""))
	var parts: Array[String] = ["Last: %s%s" % [
		label,
		" x%d" % count if count > 0 else "",
	]]
	if warning != "":
		parts.append(warning)
	if pattern != "":
		parts.append(pattern)
	var recent_summary := str(status.get("recent_attack_summary", ""))
	if recent_summary != "":
		parts.append("Recent: %s" % recent_summary)
	_boss_last_attack_label.text = " | ".join(parts)
	_boss_last_attack_label.visible = true
	_boss_last_attack_label.set_meta("boss_attack", str(status.get("attack", "")))
	_boss_last_attack_label.set_meta("boss_attack_label", label)
	_boss_last_attack_label.set_meta("boss_variant_attack", str(status.get("variant_attack", "")))
	_boss_last_attack_label.set_meta("boss_attack_count", count)
	_boss_last_attack_label.set_meta("boss_pattern_label", pattern)
	_boss_last_attack_label.set_meta("boss_attack_warning", warning)
	_boss_last_attack_label.set_meta("boss_counter_hint", str(status.get("counter_hint", "")))
	_boss_last_attack_label.set_meta("boss_dodge_cue", str(status.get("dodge_cue", "")))
	_boss_last_attack_label.set_meta(
		"boss_punish_window_seconds",
		float(status.get("punish_window_seconds", 0.0)))
	_boss_last_attack_label.set_meta("boss_safe_window_hint", str(status.get("safe_window_hint", "")))
	_boss_last_attack_label.set_meta(
		"boss_attack_sequence_index",
		int(status.get("attack_sequence_index", 0)))
	_boss_last_attack_label.set_meta("boss_previous_attack", str(status.get("previous_attack", "")))
	_boss_last_attack_label.set_meta(
		"boss_recent_attack_summary",
		recent_summary)
	_boss_last_attack_label.set_meta(
		"boss_attack_elapsed_seconds",
		float(status.get("elapsed_seconds", -1.0)))

func _play_boss_attack_sfx(status: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.boss_attack_cue(status)
	var sfx := get_node_or_null("BossAttackSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "BossAttackSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("boss_attack", str(status.get("attack", "")))
	sfx.set_meta("boss_attack_label", str(status.get(
		"variant_attack_label",
		status.get("attack_label", "Boss Attack"))))
	sfx.set_meta("boss_variant_attack", str(status.get("variant_attack", "")))
	sfx.set_meta("boss_attack_count", int(status.get("projectile_count", status.get("hazard_count", 0))))
	sfx.set_meta("boss_attack_warning", str(status.get(
		"variant_warning",
		status.get("warning", ""))))
	sfx.set_meta("boss_pattern_label", str(status.get("pattern_label", "")))
	sfx.set_meta("boss_counter_hint", str(status.get("counter_hint", "")))
	sfx.set_meta("boss_dodge_cue", str(status.get("dodge_cue", "")))
	sfx.set_meta(
		"boss_punish_window_seconds",
		float(status.get("punish_window_seconds", 0.0)))
	sfx.set_meta("boss_safe_window_hint", str(status.get("safe_window_hint", "")))
	sfx.set_meta("boss_attack_sequence_index", int(status.get("attack_sequence_index", 0)))
	sfx.set_meta("boss_previous_attack", str(status.get("previous_attack", "")))
	sfx.set_meta("boss_recent_attack_summary", str(status.get("recent_attack_summary", "")))
	sfx.set_meta("boss_attack_elapsed_seconds", float(status.get("elapsed_seconds", -1.0)))
	sfx.set_meta("boss_sound_id", str(cue.get("id", "boss_generic_attack")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "boss_attack")))
	sfx.set_meta("boss_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _boss_elapsed_text(elapsed: float) -> String:
	return " @%.1fs" % elapsed if elapsed >= 0.0 else ""

func _request_hud_sfx_playback(sfx: AudioStreamPlayer) -> void:
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _update_run_stats() -> void:
	if _run_stats_label == null:
		return
	if _player == null or not is_instance_valid(_player) \
			or _floor_ctrl == null or not is_instance_valid(_floor_ctrl):
		_run_stats_label.text = ""
		_update_route_label()
		_update_loot_pity_label()
		return
	var kills := int(_player.call("run_kill_count")) if _player.has_method("run_kill_count") else 0
	var upgrades := int(_player.call("upgrade_count")) if _player.has_method("upgrade_count") else 0
	_run_stats_label.text = "Run: Rooms %d/%d | Kills %d | Upgrades %d" % [
		int(_floor_ctrl.call("cleared_room_count")) if _floor_ctrl.has_method("cleared_room_count") else 0,
		int(_floor_ctrl.call("total_room_count")) if _floor_ctrl.has_method("total_room_count") else 0,
		kills,
		upgrades,
	]
	_run_stats_label.visible = not _compact_gameplay_hud
	_update_route_label()
	_update_loot_pity_label()

func _update_route_label() -> void:
	if _run_route_label == null:
		return
	if _floor_ctrl == null or not is_instance_valid(_floor_ctrl):
		_run_route_label.text = ""
		_update_route_choice_labels([])
		return
	var visited := _floor_ctrl.visited_rooms.size()
	var total := int(_floor_ctrl.call("total_room_count")) if _floor_ctrl.has_method("total_room_count") else 0
	var path := str(_floor_ctrl.call("visited_room_path_summary")) \
		if _floor_ctrl.has_method("visited_room_path_summary") else "Path: -"
	var options := str(_floor_ctrl.call("current_room_route_options_summary")) \
		if _floor_ctrl.has_method("current_room_route_options_summary") else ""
	var route_options: Array = _floor_ctrl.call("current_room_route_options") \
		if _floor_ctrl.has_method("current_room_route_options") else []
	var route_parts: Array[String] = ["Visited %d/%d" % [visited, total], path]
	if options != "":
		route_parts.append(options)
	_run_route_label.text = "Route: %s" % " | ".join(route_parts)
	_run_route_label.visible = not _compact_gameplay_hud
	_run_route_label.set_meta("visited_room_count", visited)
	_run_route_label.set_meta("total_room_count", total)
	_run_route_label.set_meta("path_summary", path)
	_run_route_label.set_meta("route_options_summary", options)
	_run_route_label.set_meta("route_options", route_options.duplicate(true))
	_run_route_label.set_meta("route_options_count", route_options.size())
	_run_route_label.set_meta("route_first_option_summary",
		str(route_options[0].get("summary", "")) if not route_options.is_empty() else "")
	_run_route_label.set_meta("route_main_count", _route_option_role_count(route_options, "main"))
	_run_route_label.set_meta("route_side_count", _route_option_role_count(route_options, "side"))
	_update_route_choice_labels(route_options)

func _setup_route_choice_labels() -> void:
	_route_choice_labels.clear()
	_route_choice_icons.clear()
	for i in 4:
		var column_x := 68.0 + i * 128.0
		var icon := _make_sprite_icon(
			"RouteChoiceIcon%d" % (i + 1),
			Vector2(column_x, 276),
			Vector2(10, 10),
			"floor_ladder",
			"route_choice_icon_sprite")
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.visible = false
		_route_choice_icons.append(icon)
		var label := _make_label(Vector2(column_x + 14.0, 274))
		label.name = "RouteChoiceLabel%d" % (i + 1)
		label.visible = false
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0))
		label.custom_minimum_size = Vector2(106, 12)
		_route_choice_labels.append(label)

func _update_route_choice_labels(route_options: Array) -> void:
	for i in _route_choice_labels.size():
		var label := _route_choice_labels[i]
		var icon := _route_choice_icons[i] if i < _route_choice_icons.size() else null
		if i >= route_options.size() or not (route_options[i] is Dictionary):
			_clear_route_choice_label(label)
			_clear_route_choice_icon(icon)
			continue
		var option := route_options[i] as Dictionary
		var summary := str(option.get("summary", "")).strip_edges()
		var sprite_name := _route_choice_icon_sprite(option)
		label.text = "%d %s" % [i + 1, _compact_name(summary, 16)]
		label.visible = summary != ""
		label.add_theme_color_override(
			"font_color",
			Color(1.0, 0.86, 0.46) if str(option.get("route_role", "")) == "main"
				else Color(0.72, 0.88, 1.0))
		label.tooltip_text = "Door %d | %s | %s" % [
			int(option.get("door_dir", -1)),
			str(option.get("route_label", "")),
			str(option.get("reward_preview", "")),
		]
		_set_route_choice_meta(label, option, summary, i)
		if icon != null:
			_set_sprite_icon(icon, sprite_name, "route_choice_icon_sprite")
			icon.visible = summary != ""
			icon.tooltip_text = label.tooltip_text
			_set_route_choice_meta(icon, option, summary, i)

func _clear_route_choice_label(label: Label) -> void:
	label.text = ""
	label.visible = false
	label.tooltip_text = ""
	_clear_route_choice_meta(label)

func _clear_route_choice_icon(icon: TextureRect) -> void:
	if icon == null:
		return
	icon.visible = false
	icon.tooltip_text = ""
	_clear_route_choice_meta(icon)

func _set_route_choice_meta(target: Node, option: Dictionary, summary: String, index: int) -> void:
	target.set_meta("route_choice_index", int(option.get("choice_index", index + 1)))
	target.set_meta("door_dir", int(option.get("door_dir", -1)))
	target.set_meta("room_id", int(option.get("room_id", -1)))
	target.set_meta("room_type", int(option.get("room_type", -1)))
	target.set_meta("room_type_name", str(option.get("room_type_name", "")))
	target.set_meta("route_role", str(option.get("route_role", "")))
	target.set_meta("route_label", str(option.get("route_label", "")))
	target.set_meta("reward_preview", str(option.get("reward_preview", "")))
	target.set_meta("route_summary", summary)

func _clear_route_choice_meta(target: Node) -> void:
	target.set_meta("route_choice_index", 0)
	target.set_meta("door_dir", -1)
	target.set_meta("room_id", -1)
	target.set_meta("room_type", -1)
	target.set_meta("room_type_name", "")
	target.set_meta("route_role", "")
	target.set_meta("route_label", "")
	target.set_meta("reward_preview", "")
	target.set_meta("route_summary", "")

func _route_choice_icon_sprite(option: Dictionary) -> String:
	match int(option.get("room_type", -1)):
		RoomNode.RoomType.SHOP:
			return "coin_anim"
		RoomNode.RoomType.BOSS, RoomNode.RoomType.MINIBOSS, RoomNode.RoomType.ELITE:
			return "skull"
		RoomNode.RoomType.TREASURE, RoomNode.RoomType.SECRET:
			return "chest_full_open_anim"
		RoomNode.RoomType.HEAL:
			return "flask_big_red"
		RoomNode.RoomType.SHRINE:
			return "flask_big_yellow"
		RoomNode.RoomType.EVENT:
			return "floor_spikes_anim"
		RoomNode.RoomType.COMBAT:
			return "weapon_regular_sword"
	return "floor_ladder"

func _route_option_role_count(options: Array, role: String) -> int:
	var count := 0
	for option in options:
		if option is Dictionary and str((option as Dictionary).get("route_role", "")) == role:
			count += 1
	return count

func _update_loot_pity_label() -> void:
	if _loot_pity_label == null:
		return
	if _floor_ctrl == null or not is_instance_valid(_floor_ctrl) \
			or not _floor_ctrl.has_method("loot_pity_summary"):
		_loot_pity_label.text = ""
		_loot_pity_label.visible = false
		return
	var threshold := int(_floor_ctrl.call("loot_pity_threshold")) \
		if _floor_ctrl.has_method("loot_pity_threshold") else 0
	var rooms_without_rare := maxi(int(_floor_ctrl.get("loot_pity_rooms_without_rare_plus")), 0)
	var guaranteed := threshold > 0 and rooms_without_rare >= threshold
	_loot_pity_label.text = str(_floor_ctrl.call("loot_pity_summary"))
	_loot_pity_label.visible = _loot_pity_label.text != "" and not _compact_gameplay_hud
	_loot_pity_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.88, 0.42) if guaranteed else Color(0.84, 0.92, 1.0))
	_loot_pity_label.set_meta("pity_rooms_without_rare_plus", rooms_without_rare)
	_loot_pity_label.set_meta("pity_threshold", threshold)
	_loot_pity_label.set_meta("rare_plus_guaranteed", guaranteed)

func _update_status_effects() -> void:
	if _status_label == null:
		return
	if _player == null or not is_instance_valid(_player):
		_status_label.text = ""
		_status_label.visible = false
		return
	var parts: Array[String] = []
	for status in [
		{"id": "burning", "label": "Burning"},
		{"id": "poisoned", "label": "Poison"},
		{"id": "chilled", "label": "Chilled"},
		{"id": "cursed", "label": "Cursed"},
	]:
		var status_id := str(status["id"])
		if not _player.has_status(status_id):
			continue
		var left := float(_player.get_meta("status_" + status_id + "_left", 0.0))
		parts.append("%s %.1fs" % [str(status["label"]), left])
	var buff_parts := _active_skill_buff_parts()
	var sections: Array[String] = []
	if not parts.is_empty():
		sections.append("Status: %s" % " / ".join(parts))
	if not buff_parts.is_empty():
		sections.append("Buffs: %s" % " / ".join(buff_parts))
	_status_label.text = " | ".join(sections)
	_status_label.visible = _status_label.text != "" and not _clean_playtest_mode
	_status_label.set_meta("element_altar_boon_element",
		str(_player.get_meta("element_altar_boon_element", "")))
	_status_label.set_meta("element_altar_damage_bonus",
		float(_player.get_meta("element_altar_damage_bonus", 0.0)))

func _update_class_resource_summary() -> void:
	if _class_resource_label == null:
		return
	if _player == null or not is_instance_valid(_player):
		_clear_class_resource_summary(true)
		return
	if _player.has_method("class_resource_status"):
		var status := _player.call("class_resource_status") as Dictionary
		if not status.is_empty():
			_show_class_resource_status(status)
			return
	_clear_class_resource_summary(true)

func _show_class_resource_status(status: Dictionary) -> void:
	var previous_kind := _class_resource_last_kind
	var previous_state := _class_resource_last_state
	_clear_class_resource_summary(false)
	var kind := str(status.get("kind", ""))
	var text := str(status.get("text", ""))
	if not text.is_empty():
		var used := int(status.get("used", 0))
		var limit := int(status.get("limit", 0))
		var state := str(status.get("state", "available"))
		_class_resource_label.text = text
		_class_resource_label.visible = true
		_class_resource_label.add_theme_color_override("font_color", _class_resource_color(state))
		_class_resource_label.set_meta("class_resource_kind", kind)
		_class_resource_label.set_meta("class_resource_text", text)
		_class_resource_label.set_meta("class_resource_state", state)
		_class_resource_label.set_meta("class_resource_color_role", state)
		if state == "full":
			_class_resource_label.set_meta("class_resource_pulse_state", "full")
			if previous_state != "full" or previous_kind != kind:
				_pulse_class_resource_label(kind, text)
		else:
			_class_resource_label.set_meta("class_resource_pulse_state", "")
		match kind:
			"soul_slots":
				_class_resource_label.set_meta("soul_slots_used", used)
				_class_resource_label.set_meta("soul_slot_limit", limit)
			"turrets":
				_class_resource_label.set_meta("turrets_used", used)
				_class_resource_label.set_meta("turret_limit", limit)
			"snares":
				_class_resource_label.set_meta("snares_used", used)
				_class_resource_label.set_meta("snare_limit", limit)
			"rounds":
				_class_resource_label.set_meta("rounds_left", used)
				_class_resource_label.set_meta("round_limit", limit)
		_class_resource_last_kind = kind
		_class_resource_last_state = state

func _clear_class_resource_summary(reset_transition: bool = true) -> void:
	_class_resource_label.text = ""
	_class_resource_label.visible = false
	_class_resource_label.add_theme_color_override("font_color", CLASS_RESOURCE_AVAILABLE_COLOR)
	_class_resource_label.set_meta("class_resource_kind", "")
	_class_resource_label.set_meta("class_resource_text", "")
	_class_resource_label.set_meta("class_resource_state", "")
	_class_resource_label.set_meta("class_resource_color_role", "")
	_class_resource_label.set_meta("class_resource_pulse_state", "")
	_class_resource_label.set_meta("soul_slots_used", 0)
	_class_resource_label.set_meta("soul_slot_limit", 0)
	_class_resource_label.set_meta("turrets_used", 0)
	_class_resource_label.set_meta("turret_limit", 0)
	_class_resource_label.set_meta("snares_used", 0)
	_class_resource_label.set_meta("snare_limit", 0)
	_class_resource_label.set_meta("rounds_left", 0)
	_class_resource_label.set_meta("round_limit", 0)
	if reset_transition:
		_class_resource_last_kind = ""
		_class_resource_last_state = ""

func _class_resource_color(state: String) -> Color:
	match state:
		"empty":
			return CLASS_RESOURCE_EMPTY_COLOR
		"full":
			return CLASS_RESOURCE_FULL_COLOR
		_:
			return CLASS_RESOURCE_AVAILABLE_COLOR

func _pulse_class_resource_label(kind: String, summary: String) -> void:
	_class_resource_full_pulse_count += 1
	_class_resource_label.set_meta("class_resource_pulse_kind", kind)
	_class_resource_label.set_meta("class_resource_pulse_count", _class_resource_full_pulse_count)
	_class_resource_label.scale = Vector2(1.08, 1.08)
	var tween := _class_resource_label.create_tween()
	tween.tween_property(_class_resource_label, "scale", Vector2.ONE, 0.16)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_play_class_resource_full_sfx(kind, summary)

func _play_class_resource_full_sfx(kind: String, summary: String) -> void:
	var cue: Dictionary = AudioCueDBScript.class_resource_full_cue(kind, summary)
	var sfx := get_node_or_null("ClassResourceFullSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "ClassResourceFullSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("class_resource_sound_id", str(cue.get("id", "class_resource_full")))
	sfx.set_meta("class_resource_kind", str(cue.get("resource_kind", kind)))
	sfx.set_meta("class_resource_summary", str(cue.get("summary", summary)))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "class_resource_full")))
	sfx.set_meta("class_resource_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_hud_sfx_playback(sfx)

func _active_skill_buff_parts() -> Array[String]:
	var parts: Array[String] = []
	if _player == null or not is_instance_valid(_player):
		return parts
	if _player.has_meta("iron_will_duration_seconds"):
		parts.append("Iron Will %.1fs" % float(_player.get_meta("iron_will_duration_seconds", 0.0)))
	var armor := int(_player.get_meta("temporary_armor", 0))
	if armor > 0:
		parts.append("Armor +%d %.1fs" % [
			armor,
			float(_player.get_meta("temporary_armor_duration_seconds", 0.0)),
		])
	var rounds := int(_player.get_meta("special_rounds_left", 0))
	if rounds > 0:
		parts.append("Rounds %d" % rounds)
	if _player.has_meta("shield_bastion_duration_seconds"):
		parts.append("Shield %.1fs" % float(_player.get_meta("shield_bastion_duration_seconds", 0.0)))
	if _player.has_meta("shadow_step_duration_seconds"):
		parts.append("Shadow Step %.1fs" % float(_player.get_meta("shadow_step_duration_seconds", 0.0)))
	var altar_element := str(_player.get_meta("element_altar_boon_element", "")).strip_edges()
	var altar_bonus := float(_player.get_meta("element_altar_damage_bonus", 0.0))
	if altar_element != "" and altar_bonus > 0.0:
		parts.append("%s +%d%% dmg" % [altar_element.capitalize(), roundi(altar_bonus * 100.0)])
	if bool(_player.get_meta("chaos_surge_active", false)):
		parts.append("Chaos Surge %s +%d%% %.1fs" % [
			str(_player.get_meta("chaos_surge_element", "")).capitalize(),
			roundi(float(_player.get_meta("chaos_surge_damage_bonus", 0.0)) * 100.0),
			float(_player.get_meta("chaos_surge_left", 0.0)),
		])
	return parts
