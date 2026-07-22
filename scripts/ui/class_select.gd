class_name ClassSelectScreen
extends CanvasLayer
## Pre-run loadout screen (GDD section 4, MVP subset): pick 1 class and
## 1 starting element, then enter the dungeon. Built in code until UI art.

signal confirmed(class_id: String, element: String, seed: int, run_mode: String)
signal settings_changed(settings: Dictionary)

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const BiomeDBScript := preload("res://scripts/dungeon_gen/biome_db.gd")
const RunModifierDBScript := preload("res://scripts/progression/run_modifier_db.gd")
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")
const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")
const AccessibilitySettingsScript := preload("res://scripts/ui/accessibility_settings.gd")
const CLASS_ICON_TARGET_SIZE := Vector2i(32, 32)
const ELEMENT_LABELS := {
	"fire": "Fire", "ice": "Ice", "lightning": "Lightning", "poison": "Poison",
}
const HUB_UPGRADE_GROUPS := {
	"DungeonGate": [],
	"ClassHall": ["core_affinity"],
	"TrainingGround": ["training_hp", "training_damage", "revive_charm"],
	"Blacksmith": ["rune_stability", "blueprint_socket", "starter_key"],
	"Codex": [],
}
const HUB_UPGRADE_CATEGORIES := {
	"training_hp": "training",
	"training_damage": "training",
	"core_affinity": "class_hall",
	"rune_stability": "blacksmith",
	"blueprint_socket": "blacksmith",
	"starter_key": "blacksmith",
	"gold_pouch": "dungeon_gate",
	"revive_charm": "training",
}
const RUN_MODE_LABELS := {
	"normal": "Normal",
	"boss_rush": "Boss Rush",
	"endless": "Endless",
	"hardcore": "Hardcore",
	"elemental_chaos": "Elemental Chaos",
	"balance_lab": "Balance Lab",
}

var _selected_class := ""
var _selected_element := ""
var _selected_run_mode := "normal"
var _active_hub_service := "DungeonGate"
var _status: Label
var _start: Button
var _replay_last_run_button: Button
var _meta_bank_label: Label
var _meta_bonus_label: Label
var _last_run_label: Label
var _meta_status_label: Label
var _hub_service_status_label: Label
var _codex_summary_label: Label
var _codex_detail_label: Label
var _hub_row: HBoxContainer
var _seed_input: LineEdit
var _class_grid: GridContainer
var _class_detail_sprite: TextureRect
var _class_detail_weapon_sprite: TextureRect
var _class_detail_weapon_summary: Label
var _class_detail_name: Label
var _class_detail_role: Label
var _class_detail_record: Label
var _class_detail_stats: Label
var _class_detail_skills: Label
var _class_detail_gameplan: Label
var _element_row: HBoxContainer
var _element_preview_label: Label
var _run_mode_row: HBoxContainer
var _run_mode_preview_label: Label
var _loadout_preview_label: Label
var _class_buttons: Array[Button] = []
var _hub_service_buttons := {}
var _element_buttons := {}
var _run_mode_buttons := {}
var _reset_pending := false
var _accessibility_settings := AccessibilitySettingsScript.DEFAULTS.duplicate(true)
var _accessibility_settings_label: Label


func _ready() -> void:
	layer = 15

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.05, 0.08, 0.97)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "ClassSelectMainPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24
	panel.offset_top = 16
	panel.offset_right = -24
	panel.offset_bottom = -16
	panel.custom_minimum_size = Vector2(0, 0)
	add_child(panel)

	var panel_margin := MarginContainer.new()
	panel_margin.name = "ClassSelectMainMargin"
	panel_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_margin.add_theme_constant_override("margin_left", 8)
	panel_margin.add_theme_constant_override("margin_top", 6)
	panel_margin.add_theme_constant_override("margin_right", 8)
	panel_margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(panel_margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel_margin.add_child(box)

	var title := Label.new()
	title.name = "ClassSelectTitle"
	title.text = "DUNGEON CORE"
	title.custom_minimum_size = Vector2(400, 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	box.add_child(title)

	var hint := Label.new()
	hint.text = "Choose your class and starting element"
	hint.custom_minimum_size = Vector2(400, 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	box.add_child(hint)

	var controls := Label.new()
	controls.name = "ControlsLegendLabel"
	controls.text = "WASD move | Mouse aim/attack | Space dash | E skill | C alt | Q cycle | V ultimate | 1-4 route/reward | Esc/P pause | R restart | F4 clean HUD | Pad: LS move, RS aim, RB attack, A dash, X/Y skills, RT ultimate | Pad menu: LB/RB class, D-pad element, A confirm, B back"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 8)
	controls.add_theme_color_override("font_color", Color(0.72, 0.78, 0.86))
	controls.set_meta("control_legend_scope", "gameplay")
	controls.set_meta("control_legend_action_count", 14)
	controls.visible = false
	box.add_child(controls)
	_add_accessibility_settings_controls(box)

	var hub_label := Label.new()
	hub_label.name = "HubServicesLabel"
	hub_label.text = "Hub: Dungeon Gate | Class Hall | Training Ground | Blacksmith | Codex"
	hub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hub_label.add_theme_font_size_override("font_size", 10)
	hub_label.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0))
	hub_label.visible = false
	box.add_child(hub_label)

	var hub_row := HBoxContainer.new()
	_hub_row = hub_row
	hub_row.name = "HubServicesRow"
	hub_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hub_row.add_theme_constant_override("separation", 6)
	hub_row.visible = false
	box.add_child(hub_row)
	for service in [
		{"id": "DungeonGate", "label": "Dungeon Gate"},
		{"id": "ClassHall", "label": "Class Hall"},
		{"id": "TrainingGround", "label": "Training Ground"},
		{"id": "Blacksmith", "label": "Blacksmith"},
		{"id": "Codex", "label": "Codex"},
	]:
		var service_button := Button.new()
		service_button.name = "HubService_%s" % str(service["id"])
		service_button.text = str(service["label"])
		service_button.custom_minimum_size = Vector2(100, 30)
		_apply_hub_service_button_input_hint(
			service_button, str(service["id"]), str(service["label"]))
		_hub_service_buttons[str(service["id"])] = service_button
		service_button.pressed.connect(_on_hub_service_pressed.bind(str(service["id"]), hub_row))
		hub_row.add_child(service_button)

	_hub_service_status_label = Label.new()
	_hub_service_status_label.name = "HubServiceStatusLabel"
	_hub_service_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hub_service_status_label.add_theme_font_size_override("font_size", 9)
	_hub_service_status_label.visible = false
	box.add_child(_hub_service_status_label)

	_codex_summary_label = Label.new()
	_codex_summary_label.name = "CodexSummaryLabel"
	_codex_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_codex_summary_label.add_theme_font_size_override("font_size", 9)
	_codex_summary_label.add_theme_color_override("font_color", Color(0.86, 0.92, 1.0))
	_codex_summary_label.visible = false
	box.add_child(_codex_summary_label)

	_codex_detail_label = Label.new()
	_codex_detail_label.name = "CodexDetailLabel"
	_codex_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_codex_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_codex_detail_label.custom_minimum_size = Vector2(420, 0)
	_codex_detail_label.add_theme_font_size_override("font_size", 8)
	_codex_detail_label.add_theme_color_override("font_color", Color(0.9, 0.86, 0.68))
	_codex_detail_label.visible = false
	box.add_child(_codex_detail_label)

	var seed_row := HBoxContainer.new()
	seed_row.name = "RunSeedRow"
	seed_row.alignment = BoxContainer.ALIGNMENT_CENTER
	seed_row.add_theme_constant_override("separation", 6)
	seed_row.visible = false
	box.add_child(seed_row)
	var seed_label := Label.new()
	seed_label.name = "RunSeedLabel"
	seed_label.text = "Seed"
	seed_label.add_theme_font_size_override("font_size", 10)
	seed_row.add_child(seed_label)
	_seed_input = LineEdit.new()
	_seed_input.name = "RunSeedInput"
	_seed_input.placeholder_text = "Random"
	_seed_input.custom_minimum_size = Vector2(160, 28)
	_seed_input.text_changed.connect(func(_text: String) -> void: _update())
	seed_row.add_child(_seed_input)
	var daily_seed := Button.new()
	daily_seed.name = "DailySeedButton"
	daily_seed.text = "Daily Seed"
	daily_seed.custom_minimum_size = Vector2(100, 28)
	_apply_daily_seed_button_input_hint(daily_seed)
	daily_seed.pressed.connect(_on_daily_seed_pressed)
	seed_row.add_child(daily_seed)
	_replay_last_run_button = Button.new()
	_replay_last_run_button.name = "ReplayLastRunButton"
	_replay_last_run_button.text = "REPLAY LAST"
	_replay_last_run_button.custom_minimum_size = Vector2(112, 28)
	_replay_last_run_button.pressed.connect(_on_replay_last_run_pressed)
	seed_row.add_child(_replay_last_run_button)

	var run_mode_row := HBoxContainer.new()
	_run_mode_row = run_mode_row
	run_mode_row.name = "RunModeRow"
	run_mode_row.alignment = BoxContainer.ALIGNMENT_CENTER
	run_mode_row.add_theme_constant_override("separation", 6)
	run_mode_row.visible = false
	box.add_child(run_mode_row)
	var run_mode_label := Label.new()
	run_mode_label.name = "RunModeLabel"
	run_mode_label.text = "Mode"
	run_mode_label.add_theme_font_size_override("font_size", 10)
	run_mode_row.add_child(run_mode_label)
	for mode_id in ["normal", "boss_rush", "endless", "hardcore", "elemental_chaos", "balance_lab"]:
		var mode_button := Button.new()
		mode_button.name = "RunMode_%s" % _run_mode_node_suffix(mode_id)
		mode_button.text = str(RUN_MODE_LABELS.get(mode_id, mode_id))
		mode_button.custom_minimum_size = Vector2(112, 28)
		mode_button.toggle_mode = true
		mode_button.button_pressed = mode_id == _selected_run_mode
		_apply_run_mode_button_input_hint(mode_button, mode_id, str(mode_button.text))
		_run_mode_buttons[mode_id] = mode_button
		mode_button.pressed.connect(_on_run_mode_pressed.bind(mode_id, mode_button, run_mode_row))
		run_mode_row.add_child(mode_button)

	_run_mode_preview_label = Label.new()
	_run_mode_preview_label.name = "RunModePreviewLabel"
	_run_mode_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_run_mode_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_run_mode_preview_label.custom_minimum_size = Vector2(520, 0)
	_run_mode_preview_label.add_theme_font_size_override("font_size", 9)
	_run_mode_preview_label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	_run_mode_preview_label.visible = false
	box.add_child(_run_mode_preview_label)

	_meta_bank_label = Label.new()
	_meta_bank_label.name = "MetaBankLabel"
	_meta_bank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta_bank_label.add_theme_font_size_override("font_size", 10)
	_meta_bank_label.visible = false
	box.add_child(_meta_bank_label)

	_meta_bonus_label = Label.new()
	_meta_bonus_label.name = "MetaBonusSummaryLabel"
	_meta_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta_bonus_label.add_theme_font_size_override("font_size", 9)
	_meta_bonus_label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.76))
	_meta_bonus_label.visible = false
	box.add_child(_meta_bonus_label)

	_last_run_label = Label.new()
	_last_run_label.name = "LastRunSummaryLabel"
	_last_run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_last_run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_last_run_label.custom_minimum_size = Vector2(420, 0)
	_last_run_label.add_theme_font_size_override("font_size", 9)
	_last_run_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.58))
	_last_run_label.visible = false
	box.add_child(_last_run_label)

	var meta_row := GridContainer.new()
	meta_row.columns = 2
	meta_row.add_theme_constant_override("h_separation", 8)
	meta_row.add_theme_constant_override("v_separation", 6)
	meta_row.visible = false
	box.add_child(meta_row)
	for upgrade_id in MetaProgressionScript.all_upgrade_ids():
		var button := Button.new()
		button.name = "MetaBuy_%s" % upgrade_id
		button.custom_minimum_size = Vector2(206, 44)
		button.pressed.connect(_on_meta_buy_pressed.bind(upgrade_id))
		meta_row.add_child(button)

	var reset_row := HBoxContainer.new()
	reset_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reset_row.visible = false
	box.add_child(reset_row)
	var reset_button := Button.new()
	reset_button.name = "MetaResetProfile"
	reset_button.text = "RESET PROFILE"
	reset_button.custom_minimum_size = Vector2(190, 32)
	_apply_reset_profile_button_input_hint(reset_button)
	reset_button.pressed.connect(_on_reset_profile_pressed.bind(reset_button))
	reset_row.add_child(reset_button)

	_meta_status_label = Label.new()
	_meta_status_label.name = "MetaStatusLabel"
	_meta_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta_status_label.add_theme_font_size_override("font_size", 10)
	_meta_status_label.visible = false
	box.add_child(_meta_status_label)

	var class_scroll := ScrollContainer.new()
	class_scroll.name = "ClassScroll"
	class_scroll.custom_minimum_size = Vector2(400, 88)
	class_scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	class_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	class_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(class_scroll)

	var class_grid := GridContainer.new()
	_class_grid = class_grid
	class_grid.name = "ClassGrid"
	class_grid.columns = 1
	class_grid.custom_minimum_size = Vector2(388, 0)
	class_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	class_grid.add_theme_constant_override("h_separation", 8)
	class_grid.add_theme_constant_override("v_separation", 2)
	class_scroll.add_child(class_grid)
	for c in PlayerClassDB.all():
		var class_id := str(c["id"])
		var class_index := _class_buttons.size()
		var button := Button.new()
		button.name = "Class_%s" % class_id
		button.text = str(c["name"])
		button.custom_minimum_size = Vector2(388, 18)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.add_theme_font_size_override("font_size", 9)
		_apply_class_button_icon(button, class_id)
		_apply_class_button_input_hint(button, class_index, str(c["name"]), str(c.get("role", "")))
		_class_buttons.append(button)
		button.pressed.connect(_on_class_pressed.bind(class_id, button, class_grid))
		class_grid.add_child(button)

	var detail := PanelContainer.new()
	detail.name = "ClassDetailPanel"
	detail.custom_minimum_size = Vector2(400, 52)
	box.add_child(detail)

	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 3)
	detail.add_child(detail_box)
	var preview_row := HBoxContainer.new()
	preview_row.name = "ClassDetailPreviewRow"
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_row.add_theme_constant_override("separation", 8)
	detail_box.add_child(preview_row)
	_class_detail_sprite = TextureRect.new()
	_class_detail_sprite.name = "ClassDetailSpritePreview"
	_class_detail_sprite.custom_minimum_size = Vector2(32, 32)
	_class_detail_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_class_detail_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_class_detail_sprite.visible = false
	preview_row.add_child(_class_detail_sprite)
	_class_detail_weapon_sprite = TextureRect.new()
	_class_detail_weapon_sprite.name = "ClassDetailWeaponPreview"
	_class_detail_weapon_sprite.custom_minimum_size = Vector2(32, 32)
	_class_detail_weapon_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_class_detail_weapon_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_class_detail_weapon_sprite.visible = false
	preview_row.add_child(_class_detail_weapon_sprite)
	_class_detail_name = Label.new()
	_class_detail_name.name = "ClassDetailName"
	_class_detail_name.add_theme_font_size_override("font_size", 9)
	detail_box.add_child(_class_detail_name)
	_class_detail_role = Label.new()
	_class_detail_role.name = "ClassDetailRole"
	_class_detail_role.add_theme_font_size_override("font_size", 9)
	_class_detail_role.visible = false
	detail_box.add_child(_class_detail_role)
	_class_detail_weapon_summary = Label.new()
	_class_detail_weapon_summary.name = "ClassDetailWeaponSummary"
	_class_detail_weapon_summary.add_theme_font_size_override("font_size", 9)
	_class_detail_weapon_summary.add_theme_color_override("font_color", Color(0.95, 0.86, 0.58))
	_class_detail_weapon_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_class_detail_weapon_summary.custom_minimum_size = Vector2(380, 0)
	_class_detail_weapon_summary.visible = false
	detail_box.add_child(_class_detail_weapon_summary)
	_class_detail_record = Label.new()
	_class_detail_record.name = "ClassDetailRecord"
	_class_detail_record.add_theme_font_size_override("font_size", 9)
	_class_detail_record.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0))
	_class_detail_record.visible = false
	detail_box.add_child(_class_detail_record)
	_class_detail_stats = Label.new()
	_class_detail_stats.name = "ClassDetailStats"
	_class_detail_stats.add_theme_font_size_override("font_size", 9)
	_class_detail_stats.visible = false
	detail_box.add_child(_class_detail_stats)
	_class_detail_skills = Label.new()
	_class_detail_skills.name = "ClassDetailSkills"
	_class_detail_skills.add_theme_font_size_override("font_size", 9)
	_class_detail_skills.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_class_detail_skills.visible = false
	detail_box.add_child(_class_detail_skills)
	_class_detail_gameplan = Label.new()
	_class_detail_gameplan.name = "ClassDetailGameplan"
	_class_detail_gameplan.add_theme_font_size_override("font_size", 9)
	_class_detail_gameplan.add_theme_color_override("font_color", Color(0.9, 0.88, 0.62))
	_class_detail_gameplan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_class_detail_gameplan.custom_minimum_size = Vector2(380, 0)
	_class_detail_gameplan.visible = false
	detail_box.add_child(_class_detail_gameplan)

	var element_row := HBoxContainer.new()
	_element_row = element_row
	element_row.alignment = BoxContainer.ALIGNMENT_CENTER
	element_row.add_theme_constant_override("separation", 8)
	box.add_child(element_row)
	for element in ElementSystem.ELEMENTS:
		var button := Button.new()
		button.name = "Element_%s" % element
		button.text = ELEMENT_LABELS.get(element, element)
		_apply_element_button_icon(button, element)
		_apply_element_button_input_hint(button, element, str(button.text))
		_element_buttons[element] = button
		button.pressed.connect(_on_element_pressed.bind(element, button, element_row))
		element_row.add_child(button)

	_element_preview_label = Label.new()
	_element_preview_label.name = "ElementPreviewLabel"
	_element_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_element_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_element_preview_label.custom_minimum_size = Vector2(400, 0)
	_element_preview_label.add_theme_font_size_override("font_size", 9)
	_element_preview_label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	_element_preview_label.visible = false
	box.add_child(_element_preview_label)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 10)
	_status.visible = false
	box.add_child(_status)

	_loadout_preview_label = Label.new()
	_loadout_preview_label.name = "RunLoadoutPreviewLabel"
	_loadout_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loadout_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loadout_preview_label.custom_minimum_size = Vector2(400, 0)
	_loadout_preview_label.add_theme_font_size_override("font_size", 9)
	_loadout_preview_label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	_loadout_preview_label.visible = false
	box.add_child(_loadout_preview_label)

	_start = Button.new()
	_start.name = "StartRunButton"
	_start.text = "ENTER THE DUNGEON"
	_start.custom_minimum_size = Vector2(220, 24)
	_apply_start_button_input_hint(_start)
	_start.pressed.connect(_on_start)
	box.add_child(_start)

	# Keep the actual run-start path above hub/meta so class picking is immediate.
	box.move_child(class_scroll, 2)
	box.move_child(detail, 3)
	box.move_child(element_row, 4)
	box.move_child(_element_preview_label, 5)
	box.move_child(_start, 6)
	box.move_child(_status, 7)
	box.move_child(_loadout_preview_label, 8)
	box.move_child(seed_row, 9)
	box.move_child(run_mode_row, 10)
	box.move_child(_run_mode_preview_label, 11)

	var classes := PlayerClassDB.all()
	if _selected_class == "" and not classes.is_empty() and not _class_buttons.is_empty():
		_selected_class = str(classes[0].get("id", ""))
		_mark_selected(_class_buttons[0], _class_grid)
	if _selected_element == "" and not ElementSystem.ELEMENTS.is_empty():
		_selected_element = str(ElementSystem.ELEMENTS[0])
		var element_button := _element_buttons.get(_selected_element) as Button
		if element_button != null:
			_mark_selected(element_button, _element_row)
	_update()
	_set_hub_service_status("DungeonGate")

func apply_accessibility_settings(settings: Dictionary) -> void:
	_accessibility_settings = AccessibilitySettingsScript.normalized(settings)
	set_meta("accessibility_settings", _accessibility_settings.duplicate(true))
	_update_accessibility_settings_summary()

func _add_accessibility_settings_controls(parent: VBoxContainer) -> void:
	_accessibility_settings_label = Label.new()
	_accessibility_settings_label.name = "ClassSelectAccessibilitySettings"
	_accessibility_settings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_accessibility_settings_label.add_theme_font_size_override("font_size", 8)
	_accessibility_settings_label.add_theme_color_override("font_color", Color(0.76, 0.96, 1.0))
	_accessibility_settings_label.visible = false
	parent.add_child(_accessibility_settings_label)
	var row := HBoxContainer.new()
	row.name = "ClassSelectAccessibilitySettingsControls"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.visible = false
	parent.add_child(row)
	row.add_child(_settings_button("ClassSelectVolumeDown", "Vol-", "Lower master volume",
		func() -> void:
			_accessibility_settings["master_volume"] = clampf(
				float(_accessibility_settings.get("master_volume", 1.0)) - 0.1, 0.0, 1.0)
			_emit_settings_changed()))
	row.add_child(_settings_button("ClassSelectVolumeUp", "Vol+", "Raise master volume",
		func() -> void:
			_accessibility_settings["master_volume"] = clampf(
				float(_accessibility_settings.get("master_volume", 1.0)) + 0.1, 0.0, 1.0)
			_emit_settings_changed()))
	row.add_child(_settings_button("ClassSelectToggleFlash", "Flash", "Toggle damage flash",
		func() -> void:
			var enabled := not bool(_accessibility_settings.get("damage_flash_enabled", true))
			_accessibility_settings["damage_flash_enabled"] = enabled
			_accessibility_settings["damage_vignette_enabled"] = enabled
			_emit_settings_changed()))
	row.add_child(_settings_button("ClassSelectToggleShake", "Shake", "Toggle camera impact shake",
		func() -> void:
			_accessibility_settings["screen_shake_scale"] = 0.0 \
				if float(_accessibility_settings.get("screen_shake_scale", 1.0)) > 0.0 else 1.0
			_emit_settings_changed()))
	row.add_child(_settings_button("ClassSelectToggleContrast", "Contrast", "Toggle high contrast cues",
		func() -> void:
			_accessibility_settings["high_contrast_cues"] = not bool(
				_accessibility_settings.get("high_contrast_cues", false))
			_emit_settings_changed()))
	_update_accessibility_settings_summary()

func _settings_button(
		node_name: String,
		label: String,
		tooltip: String,
		callback: Callable,
) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(48, 24)
	button.pressed.connect(callback)
	return button

func _emit_settings_changed() -> void:
	_accessibility_settings = AccessibilitySettingsScript.normalized(_accessibility_settings)
	set_meta("accessibility_settings", _accessibility_settings.duplicate(true))
	_update_accessibility_settings_summary()
	settings_changed.emit(_accessibility_settings.duplicate(true))

func _update_accessibility_settings_summary() -> void:
	if _accessibility_settings_label == null:
		return
	_accessibility_settings_label.text = "Settings: %s" % AccessibilitySettingsScript.summary(
		_accessibility_settings)
	_accessibility_settings_label.set_meta(
		"accessibility_settings", _accessibility_settings.duplicate(true))

func _apply_element_button_icon(button: Button, element: String) -> void:
	var sprite_name := ElementSystem.element_icon_sprite(element)
	var texture := SpriteDB.texture(sprite_name)
	if texture == null:
		return
	button.icon = texture
	button.expand_icon = true
	button.set_meta("element", element)
	button.set_meta("element_icon_sprite", sprite_name)
	SpriteDB.apply_sprite_metadata(button, sprite_name)


func _apply_class_button_icon(button: Button, class_id: String) -> void:
	button.set_meta("class_id", class_id)
	var sprite_names := Player.class_sprite_names(class_id)
	if sprite_names.is_empty():
		return
	var idle_name := str(sprite_names.get("idle", ""))
	var texture := SpriteDB.preview_texture(idle_name)
	if texture == null:
		return
	button.icon = _normalized_ui_icon_texture(texture, CLASS_ICON_TARGET_SIZE)
	button.expand_icon = true
	SpriteDB.apply_sprite_metadata(button, idle_name)
	button.set_meta("class_idle_sprite", idle_name)
	button.set_meta("class_run_sprite", str(sprite_names.get("run", "")))
	button.set_meta("class_preview_texture_size", button.icon.get_size())
	button.set_meta("class_icon_target_size", Vector2(CLASS_ICON_TARGET_SIZE))

func _normalized_ui_icon_texture(texture: Texture2D, target_size: Vector2i) -> Texture2D:
	var source := texture.get_image()
	if source == null or source.is_empty():
		return texture
	var target_w := maxi(target_size.x, 1)
	var target_h := maxi(target_size.y, 1)
	var src_w := maxi(source.get_width(), 1)
	var src_h := maxi(source.get_height(), 1)
	var scale := minf(float(target_w) / float(src_w), float(target_h) / float(src_h))
	var scaled_size := Vector2i(
		maxi(1, roundi(float(src_w) * scale)),
		maxi(1, roundi(float(src_h) * scale)))
	var scaled := source.duplicate()
	if scaled.get_format() != Image.FORMAT_RGBA8:
		scaled.convert(Image.FORMAT_RGBA8)
	scaled.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)
	var canvas := Image.create(target_w, target_h, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var dst := Vector2i((target_w - scaled_size.x) / 2, (target_h - scaled_size.y) / 2)
	canvas.blit_rect(scaled, Rect2i(Vector2i.ZERO, scaled_size), dst)
	return ImageTexture.create_from_image(canvas)


func _apply_class_button_input_hint(
		button: Button,
		index: int,
		class_label: String,
		role: String = "",
) -> void:
	var key_label := "0" if index == 9 else str(index + 1)
	var hotkey := KEY_0 if index == 9 else KEY_1 + index
	button.set_meta("class_input_action", "select_class")
	button.set_meta("class_key_label", key_label)
	button.set_meta("class_hotkey", hotkey)
	var short_tooltip := "Select %s [%s]" % [class_label, key_label]
	button.set_meta("class_input_hint", short_tooltip)
	button.tooltip_text = ""
	var class_id := str(button.get_meta("class_id", ""))
	var data := PlayerClassDB.get_class_data(class_id)
	if data.is_empty():
		return
	var parts: Array[String] = [short_tooltip]
	if role.strip_edges() != "":
		parts.append("Role: %s" % role)
	parts.append("Resource: %s" % str(data.get("resource", "-")))
	parts.append("Weapons: %s" % ", ".join(data.get("preferred_weapons", [])))
	var weapon_id := WeaponDB.starter_weapon_for_class(class_id)
	var weapon := WeaponDB.get_weapon(weapon_id)
	if not weapon.is_empty():
		parts.append("Starter: %s" % str(weapon.get("name", weapon_id)))
	var actives: Array = data.get("actives", [])
	var skill_names: Array[String] = []
	for active in actives:
		if active is Dictionary:
			skill_names.append(_readable_id(str((active as Dictionary).get("id", ""))))
	if not skill_names.is_empty():
		parts.append("Skills: %s" % " / ".join(skill_names))
	var ultimate: Dictionary = data.get("ultimate", {})
	if not ultimate.is_empty():
		parts.append("Ultimate: %s" % _readable_id(str(ultimate.get("id", ""))))
	button.set_meta("class_tooltip_detail", "\n".join(parts))


func _apply_element_button_input_hint(button: Button, element: String, label: String) -> void:
	var key_label := _element_key_label(element)
	var hotkey := _element_hotkey(element)
	button.set_meta("element_input_action", "select_element")
	button.set_meta("element_key_label", key_label)
	button.set_meta("element_hotkey", hotkey)
	button.tooltip_text = "Select %s [%s]" % [label, key_label]


func _apply_hub_service_button_input_hint(
		button: Button,
		service_id: String,
		label: String,
) -> void:
	var key_label := _hub_service_key_label(service_id)
	button.set_meta("hub_service_input_action", "select_hub_service")
	button.set_meta("hub_service_id", service_id)
	button.set_meta("hub_service_key_label", key_label)
	button.set_meta("hub_service_hotkey", _hub_service_hotkey(service_id))
	button.tooltip_text = "Open %s [%s]" % [label, key_label]


func _apply_daily_seed_button_input_hint(button: Button) -> void:
	button.set_meta("seed_input_action", "daily_seed")
	button.set_meta("seed_key_label", "Y")
	button.set_meta("seed_hotkey", KEY_Y)
	button.tooltip_text = "Daily Seed [Y]"


func _apply_replay_last_run_button_input_hint(button: Button, meta: Dictionary) -> void:
	var replay := _last_run_replay_data(meta)
	var ready := bool(replay.get("ready", false))
	button.disabled = not ready
	button.set_meta("replay_input_action", "replay_last_run")
	button.set_meta("replay_class_id", str(replay.get("class_id", "")))
	button.set_meta("replay_element", str(replay.get("element", "")))
	button.set_meta("replay_seed", int(replay.get("seed", 0)))
	button.set_meta("replay_run_mode", str(replay.get("run_mode", "")))
	if not ready:
		button.tooltip_text = "Replay last run unavailable"
		return
	button.tooltip_text = "Replay %s / %s / %s / Seed %d" % [
		str(replay.get("class_label", replay.get("class_id", ""))),
		str(replay.get("element", "")).capitalize(),
		str(RUN_MODE_LABELS.get(str(replay.get("run_mode", "")), replay.get("run_mode", ""))),
		int(replay.get("seed", 0)),
	]


func _apply_run_mode_button_input_hint(button: Button, mode_id: String, label: String) -> void:
	var key_label := _run_mode_key_label(mode_id)
	var preview := _run_mode_preview(mode_id)
	button.set_meta("run_mode_input_action", "select_run_mode")
	button.set_meta("run_mode_id", mode_id)
	button.set_meta("run_mode_key_label", key_label)
	button.set_meta("run_mode_hotkey", _run_mode_hotkey(mode_id))
	button.set_meta("run_mode_goal", str(preview.get("goal", "")))
	button.set_meta("run_mode_difficulty", str(preview.get("difficulty", "")))
	button.set_meta("run_mode_reward_preview", str(preview.get("reward", "")))
	button.tooltip_text = "Select %s [%s]\n%s\nReward: %s" % [
		label,
		key_label,
		str(preview.get("goal", "")),
		str(preview.get("reward", "")),
	]


func _apply_start_button_input_hint(button: Button) -> void:
	button.set_meta("start_input_action", "start_run")
	button.set_meta("start_key_label", "Enter")
	button.set_meta("start_hotkey", KEY_ENTER)
	button.set_meta("start_alt_hotkey", KEY_KP_ENTER)
	button.set_meta("start_class_id", _selected_class)
	button.set_meta("start_element", _selected_element)
	button.set_meta("start_run_mode", _selected_run_mode)
	button.set_meta("start_seed", selected_seed())
	var disabled_reason := _start_disabled_reason()
	button.set_meta("start_disabled_reason", disabled_reason)
	var parts: Array[String] = ["%s [Enter]" % button.text]
	if disabled_reason != "":
		parts.append("Need: %s" % disabled_reason)
	else:
		var class_data := PlayerClassDB.get_class_data(_selected_class)
		var weapon_id := WeaponDB.starter_weapon_for_class(_selected_class)
		var weapon := WeaponDB.get_weapon(weapon_id)
		var weapon_name := str(weapon.get("name", weapon_id))
		button.set_meta("starter_weapon_name", weapon_name)
		parts.append("Class: %s" % str(class_data.get("name", _selected_class)))
		parts.append("Element: %s" % _selected_element)
		parts.append("Mode: %s" % str(RUN_MODE_LABELS.get(_selected_run_mode, _selected_run_mode)))
		parts.append("Seed: %s" % ("Random" if selected_seed() < 0 else str(selected_seed())))
		parts.append("Starter: %s" % weapon_name)
	button.tooltip_text = "\n".join(parts)

func _start_disabled_reason() -> String:
	var missing: Array[String] = []
	if _selected_class == "":
		missing.append("class")
	if _selected_element == "":
		missing.append("element")
	return " + ".join(missing)


func _apply_reset_profile_button_input_hint(button: Button) -> void:
	button.set_meta("meta_input_action", "reset_profile")
	button.tooltip_text = "Reset profile (press twice to confirm)"


func _element_key_label(element: String) -> String:
	match element:
		"fire":
			return "F"
		"ice":
			return "I"
		"lightning":
			return "L"
		"poison":
			return "P"
	return ""


func _element_hotkey(element: String) -> int:
	match element:
		"fire":
			return KEY_F
		"ice":
			return KEY_I
		"lightning":
			return KEY_L
		"poison":
			return KEY_P
	return 0


func _run_mode_key_label(mode_id: String) -> String:
	match mode_id:
		"normal":
			return "N"
		"boss_rush":
			return "B"
		"endless":
			return "E"
		"hardcore":
			return "C"
		"elemental_chaos":
			return "O"
		"balance_lab":
			return "A"
	return ""


func _run_mode_hotkey(mode_id: String) -> int:
	match mode_id:
		"normal":
			return KEY_N
		"boss_rush":
			return KEY_B
		"endless":
			return KEY_E
		"hardcore":
			return KEY_C
		"elemental_chaos":
			return KEY_O
		"balance_lab":
			return KEY_A
	return 0

func _run_mode_node_suffix(mode_id: String) -> String:
	match mode_id:
		"boss_rush":
			return "BossRush"
		"balance_lab":
			return "BalanceLab"
		"elemental_chaos":
			return "ElementalChaos"
	return mode_id.capitalize()


func _hub_service_key_label(service_id: String) -> String:
	match service_id:
		"DungeonGate":
			return "D"
		"ClassHall":
			return "H"
		"TrainingGround":
			return "T"
		"Blacksmith":
			return "K"
		"Codex":
			return "X"
	return ""


func _hub_service_hotkey(service_id: String) -> int:
	match service_id:
		"DungeonGate":
			return KEY_D
		"ClassHall":
			return KEY_H
		"TrainingGround":
			return KEY_T
		"Blacksmith":
			return KEY_K
		"Codex":
			return KEY_X
	return 0


func _on_class_pressed(id: String, button: Button, row: Container) -> void:
	_selected_class = id
	_mark_selected(button, row)
	_play_class_select_sfx("select_class", {"class_id": id})
	_update()


func _on_element_pressed(element: String, button: Button, row: Container) -> void:
	_selected_element = element
	_mark_selected(button, row)
	_play_class_select_sfx("select_element", {"element": element})
	_update()


func _mark_selected(selected: Button, row: Container) -> void:
	for child in row.get_children():
		if child is Button:
			child.toggle_mode = true
			child.button_pressed = child == selected
			child.disabled = false
			child.set_meta("selected", child == selected)

func _unhandled_input(event: InputEvent) -> void:
	if _seed_input != null and _seed_input.has_focus():
		return
	if _handle_menu_action(event):
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var keycode := key_event.keycode
	if keycode == 0:
		keycode = key_event.physical_keycode
	if keycode >= KEY_1 and keycode <= KEY_9:
		if _select_class_by_index(keycode - KEY_1):
			_mark_input_handled()
		return
	if keycode == KEY_0:
		if _select_class_by_index(9):
			_mark_input_handled()
		return
	match keycode:
		KEY_F:
			if _select_element("fire"):
				_mark_input_handled()
		KEY_I:
			if _select_element("ice"):
				_mark_input_handled()
		KEY_L:
			if _select_element("lightning"):
				_mark_input_handled()
		KEY_P:
			if _select_element("poison"):
				_mark_input_handled()
		KEY_B:
			if _select_run_mode("boss_rush"):
				_mark_input_handled()
		KEY_E:
			if _select_run_mode("endless"):
				_mark_input_handled()
		KEY_C:
			if _select_run_mode("hardcore"):
				_mark_input_handled()
		KEY_O:
			if _select_run_mode("elemental_chaos"):
				_mark_input_handled()
		KEY_N:
			if _select_run_mode("normal"):
				_mark_input_handled()
		KEY_A:
			if _select_run_mode("balance_lab"):
				_mark_input_handled()
		KEY_Y:
			if _seed_input != null:
				_on_daily_seed_pressed()
				_mark_input_handled()
		KEY_D:
			if _select_hub_service("DungeonGate"):
				_mark_input_handled()
		KEY_H:
			if _select_hub_service("ClassHall"):
				_mark_input_handled()
		KEY_T:
			if _select_hub_service("TrainingGround"):
				_mark_input_handled()
		KEY_K:
			if _select_hub_service("Blacksmith"):
				_mark_input_handled()
		KEY_X:
			if _select_hub_service("Codex"):
				_mark_input_handled()
		KEY_ENTER, KEY_KP_ENTER:
			if _start != null and not _start.disabled:
				_on_start()
				_mark_input_handled()

func _handle_menu_action(event: InputEvent) -> bool:
	var element := _element_for_route_action(event)
	if element != "":
		if _select_element(element):
			_mark_input_handled()
			return true
	if event.is_action_pressed("menu_next"):
		if _select_relative_class(1):
			_mark_input_handled()
			return true
	if event.is_action_pressed("menu_prev"):
		if _select_relative_class(-1):
			_mark_input_handled()
			return true
	if event.is_action_pressed("menu_confirm"):
		if _start != null and not _start.disabled:
			_on_start()
			_mark_input_handled()
			return true
	if event.is_action_pressed("menu_back"):
		if _select_hub_service("DungeonGate"):
			_mark_input_handled()
			return true
	return false

func _element_for_route_action(event: InputEvent) -> String:
	if not (event is InputEventAction or event is InputEventJoypadButton):
		return ""
	if event.is_action_pressed("route_choice_1"):
		return "fire"
	if event.is_action_pressed("route_choice_2"):
		return "ice"
	if event.is_action_pressed("route_choice_3"):
		return "lightning"
	if event.is_action_pressed("route_choice_4"):
		return "poison"
	return ""

func _select_relative_class(delta: int) -> bool:
	var classes := PlayerClassDB.all()
	var count := mini(classes.size(), _class_buttons.size())
	if count <= 0:
		return false
	var selected_index := -1
	for index in range(count):
		var class_data: Dictionary = classes[index]
		if str(class_data.get("id", "")) == _selected_class:
			selected_index = index
			break
	var next_index := 0 if selected_index < 0 and delta > 0 else count - 1
	if selected_index >= 0:
		next_index = wrapi(selected_index + delta, 0, count)
	return _select_class_by_index(next_index)

func _select_class_by_index(index: int) -> bool:
	var classes := PlayerClassDB.all()
	if index < 0 or index >= classes.size() or index >= _class_buttons.size() or _class_grid == null:
		return false
	var button := _class_buttons[index]
	if button == null:
		return false
	var class_data: Dictionary = classes[index]
	_on_class_pressed(str(class_data.get("id", "")), button, _class_grid)
	return true

func _select_element(element: String) -> bool:
	if _element_row == null or not _element_buttons.has(element):
		return false
	var button := _element_buttons[element] as Button
	if button == null:
		return false
	_on_element_pressed(element, button, _element_row)
	return true

func _select_run_mode(mode_id: String) -> bool:
	if _run_mode_row == null or not _run_mode_buttons.has(mode_id):
		return false
	var button := _run_mode_buttons[mode_id] as Button
	if button == null:
		return false
	_on_run_mode_pressed(mode_id, button, _run_mode_row)
	return true

func _select_hub_service(service_id: String) -> bool:
	if _hub_row == null or not _hub_service_buttons.has(service_id):
		return false
	var button := _hub_service_buttons[service_id] as Button
	if button == null:
		return false
	_on_hub_service_pressed(service_id, _hub_row)
	return true

func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _play_class_select_sfx(action: String, details: Dictionary = {}) -> void:
	var cue: Dictionary = AudioCueDBScript.class_select_cue(action)
	var sfx := get_node_or_null("ClassSelectSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "ClassSelectSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("class_select_action", action)
	sfx.set_meta("class_select_sound_id", str(cue.get("id", "class_select")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "class_select")))
	sfx.set_meta("class_select_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	for key in details.keys():
		sfx.set_meta("class_select_%s" % str(key), details[key])
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _on_hub_service_pressed(service_id: String, row: Container) -> void:
	for child in row.get_children():
		if child is Button:
			child.disabled = child.name == "HubService_%s" % service_id
	_play_class_select_sfx("hub_service", {"service_id": service_id})
	_set_hub_service_status(service_id)

func _set_hub_service_status(service_id: String) -> void:
	_active_hub_service = service_id
	if _hub_service_status_label == null:
		return
	match service_id:
		"DungeonGate":
			_hub_service_status_label.text = "Dungeon Gate: choose class + element, then enter the run."
		"ClassHall":
			_hub_service_status_label.text = "Class Hall: compare role, stats, skills, and ultimate."
		"TrainingGround":
			_hub_service_status_label.text = "Training Ground: spend meta currency on permanent training."
		"Blacksmith":
			_hub_service_status_label.text = "Blacksmith: improve Rune and Socket options for future runs."
		"Codex":
			_hub_service_status_label.text = "Codex: review classes, elements, combos, biomes, and records."
		_:
			_hub_service_status_label.text = ""
	var meta := MetaProgressionScript.load_data()
	_append_hub_upgrade_hint(service_id, meta)
	_update_codex_summary(meta)
	_update_meta_buttons(meta, true)

func _append_hub_upgrade_hint(service_id: String, meta: Dictionary) -> void:
	if _hub_service_status_label == null or service_id == "Codex":
		return
	var hint := MetaProgressionScript.upgrade_purchase_hint(meta, _hub_upgrade_ids(service_id))
	if hint != "":
		_hub_service_status_label.text += " | %s" % hint

func _hub_upgrade_ids(service_id: String) -> Array:
	var allowed: Array = HUB_UPGRADE_GROUPS.get(service_id, [])
	return MetaProgressionScript.all_upgrade_ids() if allowed.is_empty() else allowed.duplicate()

func selected_seed() -> int:
	if _seed_input == null:
		return -1
	var text := _seed_input.text.strip_edges()
	if text == "" or not text.is_valid_int():
		return -1
	return maxi(int(text), -1)

func selected_run_mode() -> String:
	return _selected_run_mode

func daily_seed_for_date(year: int, month: int, day: int) -> int:
	return maxi(year, 0) * 10000 + clampi(month, 1, 12) * 100 + clampi(day, 1, 31)

func daily_seed_today() -> int:
	var date := Time.get_date_dict_from_system()
	return daily_seed_for_date(
		int(date.get("year", 0)),
		int(date.get("month", 1)),
		int(date.get("day", 1)))

func _on_daily_seed_pressed() -> void:
	if _seed_input != null:
		var seed := daily_seed_today()
		_seed_input.text = str(seed)
		_play_class_select_sfx("daily_seed", {"seed": seed})
		_update()

func _on_replay_last_run_pressed() -> void:
	var replay := _last_run_replay_data(MetaProgressionScript.load_data())
	if not bool(replay.get("ready", false)):
		_update()
		return
	_selected_class = str(replay.get("class_id", ""))
	_selected_element = str(replay.get("element", ""))
	_selected_run_mode = str(replay.get("run_mode", "normal"))
	if _seed_input != null:
		_seed_input.text = str(int(replay.get("seed", 0)))
	_play_class_select_sfx("confirm_run", {
		"class_id": _selected_class,
		"element": _selected_element,
		"run_mode": _selected_run_mode,
		"seed": int(replay.get("seed", 0)),
		"replay_last_run": true,
	})
	confirmed.emit(_selected_class, _selected_element, int(replay.get("seed", 0)), _selected_run_mode)
	queue_free()

func _on_run_mode_pressed(mode_id: String, button: Button, row: Container) -> void:
	_selected_run_mode = mode_id
	_mark_selected(button, row)
	_play_class_select_sfx("select_mode", {"run_mode": mode_id})
	_update()


func _update() -> void:
	var meta := MetaProgressionScript.load_data()
	_status.text = "Class: %s   |   Element: %s   |   Mode: %s" % [
		_selected_class if _selected_class != "" else "-",
		_selected_element if _selected_element != "" else "-",
		RUN_MODE_LABELS.get(_selected_run_mode, _selected_run_mode),
	]
	if _meta_bank_label != null:
		_meta_bank_label.text = "Bank: %dg | Shard %d | Core %d | Dust %d | BP %d | Runs %d | Best F%d | Streak %d%s" % [
			int(meta.get("banked_gold", 0)),
			int(meta.get("soul_shards", 0)),
			int(meta.get("element_cores", 0)),
			int(meta.get("rune_dust", 0)),
			int(meta.get("blueprints", 0)),
			int(meta.get("runs_finished", 0)),
			int(meta.get("best_floor", 0)),
			int(meta.get("current_win_streak", 0)),
			_meta_record_summary(meta),
		]
	if _meta_bonus_label != null:
		var active_bonuses := MetaProgressionScript.active_bonus_summary(meta)
		_meta_bonus_label.text = "Active Bonuses: %s" % active_bonuses
		_meta_bonus_label.set_meta("active_bonus_summary", active_bonuses)
	if _last_run_label != null:
		_last_run_label.text = _last_run_summary(meta)
		_last_run_label.set_meta("last_run_seed", int(meta.get("last_seed", 0)))
		_last_run_label.set_meta("last_run_result", str(meta.get("last_result", "")))
		_last_run_label.set_meta("last_daily_fingerprint_hash",
			str(meta.get("last_daily_fingerprint_hash", "")))
	if _replay_last_run_button != null:
		_apply_replay_last_run_button_input_hint(_replay_last_run_button, meta)
	_update_codex_summary(meta)
	_update_meta_buttons(meta)
	_update_class_detail()
	_update_element_preview()
	_update_run_mode_preview()
	_start.text = _start_label_for_mode(_selected_run_mode)
	_start.disabled = _selected_class == "" or _selected_element == ""
	_apply_start_button_input_hint(_start)
	_update_loadout_preview()

func _start_label_for_mode(mode_id: String) -> String:
	match mode_id:
		"boss_rush":
			return "START BOSS RUSH"
		"endless":
			return "START ENDLESS"
		"hardcore":
			return "START HARDCORE"
		"elemental_chaos":
			return "START ELEMENTAL CHAOS"
		"balance_lab":
			return "START BALANCE LAB"
		_:
			return "ENTER THE DUNGEON"

func _run_mode_preview(mode_id: String) -> Dictionary:
	match mode_id:
		"boss_rush":
			return {
				"label": "Boss Rush",
				"goal": "short route into Boss fights",
				"difficulty": "High",
				"reward": "Boss rewards faster",
			}
		"endless":
			return {
				"label": "Endless",
				"goal": "keep climbing after floor cap",
				"difficulty": "Scaling",
				"reward": "depth bonus",
			}
		"hardcore":
			return {
				"label": "Hardcore",
				"goal": "no safety net",
				"difficulty": "High",
				"reward": "clear bonus",
			}
		"elemental_chaos":
			return {
				"label": "Elemental Chaos",
				"goal": "element shifts and combo pressure",
				"difficulty": "Chaotic",
				"reward": "element core bonus",
			}
		"balance_lab":
			return {
				"label": "Balance Lab",
				"goal": "playtest tuning target",
				"difficulty": "Experimental",
				"reward": "evidence for tuning",
			}
		_:
			return {
				"label": "Normal",
				"goal": "standard 3-floor run",
				"difficulty": "Balanced",
				"reward": "full route rewards",
			}

func _update_run_mode_preview() -> void:
	if _run_mode_preview_label == null:
		return
	var preview := _run_mode_preview(_selected_run_mode)
	var label := str(preview.get("label", _selected_run_mode))
	var goal := str(preview.get("goal", ""))
	var difficulty := str(preview.get("difficulty", ""))
	var reward := str(preview.get("reward", ""))
	_run_mode_preview_label.text = "%s: %s | Difficulty %s | Reward: %s" % [
		label,
		goal,
		difficulty,
		reward,
	]
	_run_mode_preview_label.set_meta("run_mode_id", _selected_run_mode)
	_run_mode_preview_label.set_meta("run_mode_label", label)
	_run_mode_preview_label.set_meta("run_mode_goal", goal)
	_run_mode_preview_label.set_meta("run_mode_difficulty", difficulty)
	_run_mode_preview_label.set_meta("run_mode_reward_preview", reward)

func _update_loadout_preview() -> void:
	if _loadout_preview_label == null:
		return
	var disabled_reason := _start_disabled_reason()
	var seed := selected_seed()
	var mode_label := str(RUN_MODE_LABELS.get(_selected_run_mode, _selected_run_mode))
	_loadout_preview_label.visible = false
	_loadout_preview_label.set_meta("start_class_id", _selected_class)
	_loadout_preview_label.set_meta("start_element", _selected_element)
	_loadout_preview_label.set_meta("start_run_mode", _selected_run_mode)
	_loadout_preview_label.set_meta("start_seed", seed)
	_loadout_preview_label.set_meta("start_disabled_reason", disabled_reason)
	_loadout_preview_label.set_meta("loadout_ready", disabled_reason == "")
	if disabled_reason != "":
		_loadout_preview_label.text = "Loadout: choose %s | Mode: %s | Seed: %s" % [
			disabled_reason,
			mode_label,
			"Random" if seed < 0 else str(seed),
		]
		_loadout_preview_label.set_meta("starter_weapon_name", "")
		return
	var class_data := PlayerClassDB.get_class_data(_selected_class)
	var weapon_id := WeaponDB.starter_weapon_for_class(_selected_class)
	var weapon := WeaponDB.get_weapon(weapon_id)
	var weapon_name := str(weapon.get("name", weapon_id))
	_loadout_preview_label.set_meta("starter_weapon_name", weapon_name)
	_loadout_preview_label.text = "Ready: %s / %s / %s / Seed %s / %s" % [
		str(class_data.get("name", _selected_class)),
		_selected_element.capitalize(),
		mode_label,
		"Random" if seed < 0 else str(seed),
		weapon_name,
	]

func _update_element_preview() -> void:
	if _element_preview_label == null:
		return
	if _selected_element == "":
		_element_preview_label.text = "Element: -"
		_element_preview_label.set_meta("selected_element", "")
		_element_preview_label.set_meta("combo_count", 0)
		_element_preview_label.set_meta("combo_names", "")
		return
	var preview := ElementSystem.element_preview(_selected_element)
	var combo_names := _element_combo_names(Array(preview.get("combos", [])))
	_element_preview_label.text = "%s: %s %.1fs | %s\nCombos: %s" % [
		str(preview.get("name", _selected_element.capitalize())),
		str(preview.get("status", "")),
		float(preview.get("duration", 0.0)),
		str(preview.get("effect", "")),
		" / ".join(combo_names),
	]
	_element_preview_label.set_meta("selected_element", _selected_element)
	_element_preview_label.set_meta("element_status", str(preview.get("status", "")))
	_element_preview_label.set_meta("element_duration", float(preview.get("duration", 0.0)))
	_element_preview_label.set_meta("combo_count", combo_names.size())
	_element_preview_label.set_meta("combo_names", " / ".join(combo_names))

func _element_combo_names(combos: Array) -> Array[String]:
	var names: Array[String] = []
	for combo in combos:
		if combo is Dictionary:
			names.append(str((combo as Dictionary).get("name", "")))
	return names

func _update_class_detail() -> void:
	if _class_detail_name == null:
		return
	if _selected_class == "":
		_clear_class_sprite_preview()
		_clear_class_weapon_preview()
		_class_detail_name.text = "Select a class"
		_class_detail_role.text = "Stats, skills, and ultimate preview"
		if _class_detail_weapon_summary != null:
			_class_detail_weapon_summary.text = "Starter: -"
		_class_detail_record.text = "Record: -"
		_class_detail_stats.text = "HP - | ARM - | RES - | SPD - | DMG - | CRIT -"
		_class_detail_skills.text = "E - | C - | Ult - | Passives -"
		_class_detail_skills.set_meta("class_detail_full_text", _class_detail_skills.text)
		_class_detail_skills.tooltip_text = _class_detail_skills.text
		_update_class_gameplan({})
		return
	var data := PlayerClassDB.get_class_data(_selected_class)
	_update_class_sprite_preview(_selected_class)
	_update_class_weapon_preview(_selected_class)
	var stats: Dictionary = data.get("stats", {})
	var actives: Array = data.get("actives", [])
	var passives: Array = data.get("passives", [])
	var skill_e: Dictionary = actives[0] if actives.size() > 0 else {}
	var skill_c: Dictionary = actives[1] if actives.size() > 1 else {}
	var ultimate: Dictionary = data.get("ultimate", {})
	_class_detail_name.text = str(data.get("name", _selected_class))
	_class_detail_role.text = "Role: %s | Res: %s" % [
		str(data.get("role", "-")),
		str(data.get("resource", "-")),
	]
	_class_detail_record.text = _class_record_text(_selected_class)
	_class_detail_stats.text = "HP %d | ARM %d | RES %d | SPD %d | DMG %d | CRIT %d" % [
		int(stats.get("hp", 0)),
		int(stats.get("armor", 0)),
		int(stats.get("resource", 0)),
		int(stats.get("speed", 0)),
		int(stats.get("damage", 0)),
		int(stats.get("crit", 0)),
	]
	var skill_full_text := "%s | %s | %s | %s" % [
		_skill_preview("E", skill_e),
		_skill_preview("C", skill_c),
		_ultimate_preview(ultimate),
		_passives_preview(passives),
	]
	_class_detail_skills.text = "%s\n%s\n%s | %s" % [
		_skill_preview("E", skill_e),
		_skill_preview("C", skill_c),
		_ultimate_preview(ultimate),
		_passives_preview(passives),
	]
	_class_detail_skills.set_meta("class_detail_full_text", skill_full_text)
	_class_detail_skills.tooltip_text = skill_full_text
	_update_class_gameplan(data)

func _update_class_gameplan(data: Dictionary) -> void:
	if _class_detail_gameplan == null:
		return
	if data.is_empty():
		_class_detail_gameplan.text = "Gameplan: choose a class"
		_class_detail_gameplan.set_meta("class_detail_full_text", _class_detail_gameplan.text)
		_class_detail_gameplan.tooltip_text = _class_detail_gameplan.text
		_class_detail_gameplan.set_meta("class_id", "")
		_class_detail_gameplan.set_meta("class_role", "")
		_class_detail_gameplan.set_meta("class_ease", "")
		_class_detail_gameplan.set_meta("recommended_upgrade_tags", "")
		return
	var role := str(data.get("role", ""))
	var guide := _class_gameplan_for_role(role)
	var tags := str(guide.get("tags", ""))
	var full_text := "Ease: %s | Plan: %s | Risk: %s | Upgrade Tags: %s" % [
		str(guide.get("ease", "Medium")),
		str(guide.get("plan", "Play around your cooldown window")),
		str(guide.get("risk", "Poor positioning")),
		tags,
	]
	_class_detail_gameplan.text = "Ease: %s | Plan: %s\nRisk: %s | Upgrade Tags: %s" % [
		str(guide.get("ease", "Medium")),
		str(guide.get("plan", "Play around your cooldown window")),
		str(guide.get("risk", "Poor positioning")),
		tags,
	]
	_class_detail_gameplan.set_meta("class_detail_full_text", full_text)
	_class_detail_gameplan.tooltip_text = full_text
	_class_detail_gameplan.set_meta("class_id", str(data.get("id", "")))
	_class_detail_gameplan.set_meta("class_role", role)
	_class_detail_gameplan.set_meta("class_ease", str(guide.get("ease", "Medium")))
	_class_detail_gameplan.set_meta("recommended_upgrade_tags", tags)

func _class_gameplan_for_role(role: String) -> Dictionary:
	match role:
		"balanced_melee":
			return {"ease": "Easy", "plan": "chain slashes, dash through gaps", "risk": "overextending", "tags": "damage / mobility / shield"}
		"heavy_melee_burst":
			return {"ease": "Medium", "plan": "commit to slam windows, then reposition", "risk": "slow windup", "tags": "damage / shield / mobility"}
		"crit_mobility":
			return {"ease": "Hard", "plan": "mark, flank, burst, leave", "risk": "low HP mistakes", "tags": "crit / mobility / poison"}
		"tank_counter":
			return {"ease": "Easy", "plan": "hold front line and punish blocks", "risk": "slow clears", "tags": "shield / damage / hp"}
		"elemental_caster":
			return {"ease": "Hard", "plan": "kite while chaining element combos", "risk": "low HP and mana gaps", "tags": "element / projectile / cooldown"}
		"ranged_precision":
			return {"ease": "Medium", "plan": "root targets, charge shots, pierce lanes", "risk": "crowded rooms", "tags": "projectile / crit / mobility"}
		"continuous_ranged_dps":
			return {"ease": "Medium", "plan": "keep firing lanes open and reload safely", "risk": "being cornered", "tags": "projectile / damage / element"}
		"pet_army":
			return {"ease": "Hard", "plan": "build pets, sacrifice when surrounded", "risk": "weak early room tempo", "tags": "pet / mana / damage"}
		"sustain_support":
			return {"ease": "Easy", "plan": "hold safe zones and outlast mistakes", "risk": "low burst damage", "tags": "healing / shield / element"}
		"zone_control":
			return {"ease": "Medium", "plan": "set turret/trap zones before fights peak", "risk": "setup time", "tags": "pet / projectile / mobility"}
	return {"ease": "Medium", "plan": "use skills on cooldown windows", "risk": "unknown matchup", "tags": "damage / mobility"}

func _clear_class_sprite_preview() -> void:
	if _class_detail_sprite == null:
		return
	_class_detail_sprite.texture = null
	_class_detail_sprite.visible = false
	for key in ["class_id", "class_idle_sprite", "class_run_sprite"]:
		_class_detail_sprite.set_meta(key, "")

func _clear_class_weapon_preview() -> void:
	if _class_detail_weapon_sprite == null:
		return
	_class_detail_weapon_sprite.texture = null
	_class_detail_weapon_sprite.visible = false
	if _class_detail_weapon_summary != null:
		_class_detail_weapon_summary.text = "Starter: -"
	for key in [
		"class_id",
		"starter_weapon_id",
		"starter_weapon_group",
		"starter_weapon_name",
		"weapon_sprite_name",
	]:
		_class_detail_weapon_sprite.set_meta(key, "")

func _update_class_sprite_preview(class_id: String) -> void:
	if _class_detail_sprite == null:
		return
	var sprite_names := Player.class_sprite_names(class_id)
	if sprite_names.is_empty():
		_clear_class_sprite_preview()
		return
	var idle_name := str(sprite_names["idle"])
	var texture := SpriteDB.preview_texture(idle_name)
	if texture == null:
		_clear_class_sprite_preview()
		return
	_class_detail_sprite.texture = _normalized_ui_icon_texture(texture, CLASS_ICON_TARGET_SIZE)
	_class_detail_sprite.visible = true
	SpriteDB.apply_sprite_metadata(_class_detail_sprite, idle_name)
	_class_detail_sprite.set_meta("class_id", class_id)
	_class_detail_sprite.set_meta("class_idle_sprite", idle_name)
	_class_detail_sprite.set_meta("class_run_sprite", str(sprite_names["run"]))
	_class_detail_sprite.set_meta("class_preview_texture_size", _class_detail_sprite.texture.get_size())
	_class_detail_sprite.set_meta("class_icon_target_size", Vector2(CLASS_ICON_TARGET_SIZE))

func _update_class_weapon_preview(class_id: String) -> void:
	if _class_detail_weapon_sprite == null:
		return
	var weapon_id := WeaponDB.starter_weapon_for_class(class_id)
	var weapon := WeaponDB.get_weapon(weapon_id)
	var sprite_name := WeaponDB.preview_sprite_name_for_weapon(weapon_id)
	var texture := SpriteDB.texture(sprite_name)
	if weapon.is_empty() or texture == null:
		_clear_class_weapon_preview()
		return
	_class_detail_weapon_sprite.texture = texture
	_class_detail_weapon_sprite.visible = true
	_class_detail_weapon_sprite.tooltip_text = str(weapon.get("name", weapon_id))
	SpriteDB.apply_sprite_metadata(_class_detail_weapon_sprite, sprite_name)
	_class_detail_weapon_sprite.set_meta("class_id", class_id)
	_class_detail_weapon_sprite.set_meta("starter_weapon_id", weapon_id)
	_class_detail_weapon_sprite.set_meta("starter_weapon_group", str(weapon.get("group", "")))
	_class_detail_weapon_sprite.set_meta("starter_weapon_name", str(weapon.get("name", weapon_id)))
	_class_detail_weapon_sprite.set_meta("weapon_sprite_name", sprite_name)
	if _class_detail_weapon_summary != null:
		_class_detail_weapon_summary.text = _starter_weapon_summary(weapon)
		_class_detail_weapon_summary.set_meta("class_id", class_id)
		_class_detail_weapon_summary.set_meta("starter_weapon_id", weapon_id)
		_class_detail_weapon_summary.set_meta("starter_weapon_group", str(weapon.get("group", "")))

func _starter_weapon_summary(weapon: Dictionary) -> String:
	var effect := str(weapon.get("effect", "")).strip_edges()
	var line := "Starter: %s | DMG %d | SPD %d | RNG %d | Sockets %d" % [
		str(weapon.get("name", "Weapon")),
		int(weapon.get("dmg", 0)),
		int(weapon.get("speed", 0)),
		int(weapon.get("range", 0)),
		int(weapon.get("sockets", 0)),
	]
	return line if effect == "" else "%s\n%s" % [line, effect]

func _skill_preview(slot: String, skill_data: Dictionary) -> String:
	if skill_data.is_empty():
		return "%s: -" % slot
	return "%s: %s | Cost %d | CD %.1fs" % [
		slot,
		_readable_id(str(skill_data.get("id", "-"))),
		int(skill_data.get("cost", 0)),
		float(skill_data.get("cooldown", 0.0)),
	]

func _ultimate_preview(ultimate_data: Dictionary) -> String:
	if ultimate_data.is_empty():
		return "Ultimate: -"
	return "Ultimate: %s | Charge %d" % [
		_readable_id(str(ultimate_data.get("id", "-"))),
		int(ultimate_data.get("cost", 0)),
	]

func _passives_preview(passives: Array) -> String:
	if passives.is_empty():
		return "Passives: -"
	var names: Array[String] = []
	for passive in passives:
		if not (passive is Dictionary):
			continue
		var passive_id := str((passive as Dictionary).get("id", ""))
		if passive_id != "":
			names.append(_readable_id(passive_id))
	return "Passives: %s" % " / ".join(names)

func _readable_id(id: String) -> String:
	var clean := id.strip_edges()
	if clean == "" or clean == "-":
		return "-"
	return clean.replace("_", " ").capitalize()

func _meta_record_summary(meta: Dictionary) -> String:
	var seed := int(meta.get("last_seed", 0))
	if seed <= 0:
		return ""
	var seed_label := str(meta.get("last_seed_label", "Seed"))
	if seed_label == "":
		seed_label = "Seed"
	var class_label := str(meta.get("last_class", "-"))
	var element := str(meta.get("last_element", "-"))
	var mode := str(meta.get("last_mode", ""))
	var daily_wins := int(meta.get("daily_seed_victories", 0))
	var daily_attempts := int(meta.get("daily_seed_attempts", 0))
	return " | Last: %s %d | %s/%s%s | Daily %d/%d" % [
		seed_label,
		seed,
		class_label if class_label != "" else "-",
		element if element != "" else "-",
		" | %s" % mode if mode != "" else "",
		daily_wins,
		daily_attempts,
	]

func _last_run_replay_data(meta: Dictionary) -> Dictionary:
	var seed := int(meta.get("last_seed", 0))
	var element := str(meta.get("last_element", "")).strip_edges().to_lower()
	var mode_id := _run_mode_id_from_label(str(meta.get("last_mode", "")))
	var class_id := str(meta.get("last_class_id", "")).strip_edges()
	if class_id == "":
		class_id = _class_id_from_last_run(meta, seed)
	if mode_id == "":
		mode_id = "normal"
	var data := {
		"ready": false,
		"class_id": class_id,
		"class_label": str(meta.get("last_class", class_id)),
		"element": element,
		"seed": seed,
		"run_mode": mode_id,
	}
	if seed <= 0 or class_id == "" or PlayerClassDB.get_class_data(class_id).is_empty():
		return data
	if element == "" or not ELEMENT_LABELS.has(element):
		return data
	data["ready"] = true
	return data

func _class_id_from_last_run(meta: Dictionary, seed: int) -> String:
	var runs: Array = meta.get("recent_runs", [])
	for raw_run in runs:
		if not (raw_run is Dictionary):
			continue
		var run: Dictionary = raw_run
		if seed > 0 and int(run.get("seed", 0)) != seed:
			continue
		var run_class_id := str(run.get("class_id", "")).strip_edges()
		if run_class_id != "":
			return run_class_id
	return _class_id_from_label(str(meta.get("last_class", "")))

func _class_id_from_label(label: String) -> String:
	var clean := label.strip_edges()
	if clean == "":
		return ""
	for class_data in PlayerClassDB.all():
		var class_id := str(class_data.get("id", ""))
		if class_id == clean:
			return class_id
		if str(class_data.get("name", "")).to_lower() == clean.to_lower():
			return class_id
	return ""

func _run_mode_id_from_label(label: String) -> String:
	var clean := label.strip_edges()
	if clean == "":
		return "normal"
	if RUN_MODE_LABELS.has(clean):
		return clean
	var lowered := clean.to_lower()
	for mode_id in RUN_MODE_LABELS.keys():
		if str(RUN_MODE_LABELS[mode_id]).to_lower() == lowered:
			return str(mode_id)
	return lowered.replace(" ", "_")

func _class_record_text(class_id: String) -> String:
	var meta := MetaProgressionScript.load_data()
	var records: Dictionary = meta.get("class_records", {})
	var record: Dictionary = records.get(class_id, {})
	if record.is_empty():
		return "Record: No runs yet"
	return "Record: Runs %d | Wins %d | Best F%d | Seed %d" % [
		int(record.get("runs", 0)),
		int(record.get("victories", 0)),
		int(record.get("best_floor", 0)),
		int(record.get("best_seed", 0)),
	]

func _update_codex_summary(meta: Dictionary) -> void:
	if _codex_summary_label == null:
		return
	var class_records: Dictionary = meta.get("class_records", {})
	var mode_records: Dictionary = meta.get("mode_records", {})
	var element_records: Dictionary = meta.get("element_records", {})
	var biome_records: Dictionary = meta.get("biome_records", {})
	var boss_records: Dictionary = meta.get("boss_records", {})
	var enemy_records: Dictionary = meta.get("enemy_records", {})
	var element_count := ElementSystem.ELEMENTS.size()
	var combos := ElementSystem.combo_codex_entries()
	var mode_preview := _mode_record_preview(mode_records)
	var mode_line := "\nModes: %s" % mode_preview if mode_preview != "" else ""
	var element_preview := _element_record_preview(element_records)
	var element_line := "\nElement Records: %s" % element_preview if element_preview != "" else ""
	var biome_preview := _biome_record_preview(biome_records)
	var biome_line := "\nBiome Records: %s" % biome_preview if biome_preview != "" else ""
	var boss_preview := _boss_record_preview(boss_records)
	var boss_line := "\nBoss Records: %s" % boss_preview if boss_preview != "" else ""
	var enemy_preview := MetaProgressionScript.enemy_record_preview({"enemy_records": enemy_records})
	var enemy_line := "\nEnemy Records: %s" % enemy_preview if enemy_preview != "" else ""
	_codex_summary_label.text = "Codex: Classes %d | Played %d | Modes %d | Elements %d | Mastered %d | Combos %d | Bosses %d | Enemies %d | Biomes %d | Daily %d/%d\nCombos: %s%s%s%s%s%s\n%s" % [
		PlayerClassDB.all().size(),
		class_records.size(),
		mode_records.size(),
		element_count,
		_mastered_element_count(element_records),
		combos.size(),
		boss_records.size(),
		enemy_records.size(),
		BiomeDBScript.BIOMES.size(),
		int(meta.get("daily_seed_victories", 0)),
		int(meta.get("daily_seed_attempts", 0)),
		_combo_preview(combos),
		mode_line,
		element_line,
		biome_line,
		boss_line,
		enemy_line,
		_codex_release_summary(meta),
	]
	_codex_summary_label.visible = _active_hub_service == "Codex"
	if _codex_detail_label != null:
		_codex_detail_label.text = _codex_detail_text(meta, combos)
		_codex_detail_label.visible = _codex_summary_label.visible

func _codex_detail_text(meta: Dictionary, combos: Array) -> String:
	return "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s" % [
		_element_codex_line(),
		_combo_effect_line(combos),
		_enemy_codex_line(),
		_enemy_records_line(meta),
		_daily_modifier_line(),
		_last_run_summary(meta),
		_recent_runs_line(meta),
		MetaProgressionScript.recent_run_playtest_summary(meta),
		_best_class_line(meta),
		_best_element_line(meta),
		_best_biome_line(meta),
		_best_boss_line(meta),
		_codex_release_detail_line(meta),
	]

func _last_run_summary(meta: Dictionary) -> String:
	if int(meta.get("runs_finished", 0)) <= 0:
		return "Last Run: No runs yet"
	var seed := int(meta.get("last_seed", 0))
	var seed_label := str(meta.get("last_seed_label", "Seed")).strip_edges()
	if seed_label == "":
		seed_label = "Seed"
	var class_label := str(meta.get("last_class", "-")).strip_edges()
	var element := str(meta.get("last_element", "-")).strip_edges()
	var mode := str(meta.get("last_mode", "")).strip_edges()
	var path := _clean_path(str(meta.get("last_path", "")).strip_edges())
	var path_text := " | Path: %s" % path if path != "" else ""
	var mode_text := " | %s" % mode if mode != "" else ""
	var build_text := _last_build_line(meta)
	var fingerprint := _daily_fingerprint_preview(
		meta.get("last_daily_fingerprint", {}),
		str(meta.get("last_daily_fingerprint_hash", "")))
	var fingerprint_text := "\n%s" % fingerprint if fingerprint != "" else ""
	return "Last Run: %s F%d | %s %d | %s/%s%s%s\nRewards: %s%s%s" % [
		_result_label(str(meta.get("last_result", ""))),
		int(meta.get("last_floor", 0)),
		seed_label,
		seed,
		class_label if class_label != "" else "-",
		element if element != "" else "-",
		mode_text,
		fingerprint_text,
		_last_reward_summary(Dictionary(meta.get("last_rewards", {}))),
		path_text,
		build_text,
	]

func _recent_runs_line(meta: Dictionary) -> String:
	var runs: Array = meta.get("recent_runs", [])
	if runs.is_empty():
		return "Recent Runs: No runs yet"
	var parts: Array[String] = []
	for raw_run in runs.slice(0, 3):
		if raw_run is Dictionary:
			parts.append(_recent_run_preview(raw_run as Dictionary))
	return "Recent Runs: %s" % " / ".join(parts)

func _recent_run_preview(run: Dictionary) -> String:
	var result := _result_label(str(run.get("result", "")))
	var element := str(run.get("element", "")).strip_edges()
	var mode := str(run.get("mode", "")).strip_edges()
	var seed := int(run.get("seed", 0))
	var parts: Array[String] = [
		"%s F%d" % [result, int(run.get("floor", 0))],
		element.capitalize() if element != "" else "-",
	]
	if mode != "":
		parts.append(mode)
	if seed > 0:
		parts.append("Seed %d" % seed)
	var archetype := str(run.get("archetype", "")).strip_edges()
	if archetype != "":
		parts.append(archetype)
	var fingerprint := _daily_fingerprint_preview(
		run.get("daily_fingerprint", {}),
		str(run.get("daily_fingerprint_hash", "")))
	if fingerprint != "":
		parts.append(fingerprint)
	var reward := _recent_reward_preview(run)
	if reward != "":
		parts.append("Reward %s" % reward)
	var release_decision := str(run.get("release_decision", "")).strip_edges()
	var release_replacements := int(run.get("release_replacements", 0))
	if release_decision != "" or release_replacements > 0:
		var release_text := "Release %s" % (
			release_decision if release_decision != "" else "review")
		if release_replacements > 0:
			release_text += " Fix x%d" % release_replacements
		parts.append(release_text)
	var next_action := str(run.get("release_next_action", "")).strip_edges()
	if next_action != "":
		var next_head := next_action.trim_prefix("Next Action: ").get_slice("|", 0).strip_edges()
		if next_head != "":
			parts.append("Next %s" % next_head)
	var objective := str(run.get("playtest_objective", "")).strip_edges()
	if objective != "":
		var objective_head := objective.trim_prefix("Playtest Objective: ").get_slice("|", 0).strip_edges()
		if objective_head != "":
			parts.append("Objective %s" % objective_head)
	var patch := str(run.get("tuning_patch", "")).strip_edges()
	if patch != "":
		var patch_head := patch.trim_prefix("Tuning Patch: ").get_slice("|", 0).strip_edges()
		if patch_head != "":
			parts.append("Patch %s" % patch_head)
	var pace_preview := ""
	if run.has("pace_avg_sec"):
		var pace_parts: Array[String] = ["Avg %.1fs" % float(run.get("pace_avg_sec", 0.0))]
		if run.has("pace_boss_sec"):
			pace_parts.append("Boss %.1fs" % float(run.get("pace_boss_sec", 0.0)))
		var slow_count := int(run.get("pace_slow_count", 0))
		if slow_count > 0:
			pace_parts.append("Slow %d" % slow_count)
		pace_preview = " ".join(pace_parts)
	else:
		var pace := str(run.get("pace", "")).strip_edges()
		if pace != "":
			pace_preview = pace.get_slice("|", 0).strip_edges()
	if pace_preview != "":
		parts.append("Pace %s" % pace_preview)
	var decision_preview := _recent_decision_preview(run)
	if decision_preview != "":
		parts.append("Decisions %s" % decision_preview)
	return " ".join(parts)

func _daily_fingerprint_preview(value, hash_fallback: String = "") -> String:
	var hash_text := hash_fallback.strip_edges()
	var floor_index := 0
	var room_count := 0
	var spawn_count := 0
	var boss_variant := ""
	if value is Dictionary:
		var data: Dictionary = value
		hash_text = str(data.get("hash", hash_text)).strip_edges()
		floor_index = maxi(int(data.get("floor_index", 0)), 0)
		room_count = maxi(int(data.get("room_count", 0)), 0)
		spawn_count = maxi(int(data.get("spawn_count", 0)), 0)
		boss_variant = str(data.get("boss_variant", "")).strip_edges()
	if hash_text == "":
		return ""
	var parts: Array[String] = ["Daily Hash %s" % hash_text]
	if floor_index > 0:
		parts.append("Floor %d" % floor_index)
	if room_count > 0:
		parts.append("Rooms %d" % room_count)
	if spawn_count > 0:
		parts.append("Spawns %d" % spawn_count)
	if boss_variant != "":
		parts.append("Boss %s" % boss_variant)
	return " | ".join(parts)

func _recent_decision_preview(run: Dictionary) -> String:
	var reward_picks := int(run.get("decision_reward_picks", 0))
	var reward_skips := int(run.get("decision_reward_skips", 0))
	var rerolls := int(run.get("decision_reward_rerolls", 0))
	var shop_buys := int(run.get("decision_shop_buys", 0))
	var shop_leaves := int(run.get("decision_shop_leaves", 0))
	if reward_picks + reward_skips + rerolls + shop_buys + shop_leaves <= 0:
		return ""
	var parts: Array[String] = []
	if reward_picks > 0 or reward_skips > 0:
		parts.append("R%d/S%d" % [reward_picks, reward_skips])
	if rerolls > 0:
		parts.append("RR%d" % rerolls)
	if shop_buys > 0 or shop_leaves > 0:
		parts.append("Shop %d/%d" % [shop_buys, shop_leaves])
	return " ".join(parts)

func _recent_reward_preview(run: Dictionary) -> String:
	var parts: Array[String] = []
	var gold := int(run.get("banked_gold", 0))
	if gold > 0:
		parts.append("+%dg" % gold)
	var currencies := {
		"soul_shards": "Shard",
		"element_cores": "Core",
		"rune_dust": "Dust",
		"blueprints": "BP",
	}
	for key in ["soul_shards", "element_cores", "rune_dust", "blueprints"]:
		var amount := int(run.get(key, 0))
		if amount > 0:
			parts.append("%s +%d" % [str(currencies[key]), amount])
	var challenge_bonus := str(run.get("challenge_bonus", "")).strip_edges()
	if challenge_bonus != "":
		parts.append("Challenge %s" % challenge_bonus)
	var endless_bonus := str(run.get("endless_depth_bonus", "")).strip_edges()
	if endless_bonus != "":
		parts.append(endless_bonus)
	var hardcore_bonus := str(run.get("hardcore_clear_bonus", "")).strip_edges()
	if hardcore_bonus != "":
		parts.append("Hardcore %s" % hardcore_bonus)
	var chaos_bonus := str(run.get("elemental_chaos_bonus", "")).strip_edges()
	if chaos_bonus != "":
		parts.append("Chaos %s" % chaos_bonus)
	return " ".join(parts)

func _last_build_line(meta: Dictionary) -> String:
	var archetype := str(meta.get("last_build_archetype", "")).strip_edges()
	var build := str(meta.get("last_build_summary", "")).strip_edges()
	var tags := str(meta.get("last_build_tags", "")).strip_edges()
	var parts: Array[String] = []
	if archetype != "":
		parts.append(archetype)
	if build != "":
		parts.append(build)
	if tags != "":
		parts.append(tags)
	return "" if parts.is_empty() else "\nBuild: %s" % " | ".join(parts)

func _result_label(result: String) -> String:
	var clean := result.strip_edges()
	if clean == "":
		return "Run"
	return clean.capitalize()

func _last_reward_summary(rewards: Dictionary) -> String:
	if rewards.is_empty():
		return "-"
	var parts: Array[String] = []
	var gold := int(rewards.get("gold", 0))
	if gold > 0:
		parts.append("+%dg" % gold)
	var currencies := {
		"soul_shards": "Shard",
		"element_cores": "Core",
		"rune_dust": "Dust",
		"blueprints": "BP",
	}
	for key in ["soul_shards", "element_cores", "rune_dust", "blueprints"]:
		var amount := int(rewards.get(key, 0))
		if amount > 0:
			parts.append("%s +%d" % [str(currencies[key]), amount])
	var challenge_bonus := str(rewards.get("challenge_bonus", "")).strip_edges()
	if challenge_bonus != "":
		parts.append("Challenge %s" % challenge_bonus)
	var hardcore_bonus := str(rewards.get("hardcore_clear_bonus", "")).strip_edges()
	if hardcore_bonus != "":
		parts.append("Hardcore %s" % hardcore_bonus)
	var chaos_bonus := str(rewards.get("elemental_chaos_bonus", "")).strip_edges()
	if chaos_bonus != "":
		parts.append("Chaos %s" % chaos_bonus)
	return "-" if parts.is_empty() else " / ".join(parts)

func _clean_path(path: String) -> String:
	return path.substr(6) if path.begins_with("Path: ") else path

func _element_codex_line() -> String:
	return "Elements: Fire: burn DoT | Ice: slow | Lightning: stun | Poison: long DoT"

func _combo_effect_line(combos: Array) -> String:
	var parts: Array[String] = []
	for combo in combos:
		if not (combo is Dictionary):
			continue
		var data := combo as Dictionary
		parts.append("%s: %s" % [
			str(data.get("name", "")),
			str(data.get("effect", "")),
		])
		if parts.size() >= 6:
			break
	return "Combo Effects: %s" % " / ".join(parts)

func _enemy_codex_line() -> String:
	return BiomeDBScript.enemy_codex_summary()

func _enemy_records_line(meta: Dictionary) -> String:
	var preview := MetaProgressionScript.enemy_record_preview(meta, 4)
	return "Enemy Records: No encounters yet" if preview == "" else "Enemy Records: %s" % preview

func _daily_modifier_line() -> String:
	var parts: Array[String] = []
	for modifier in RunModifierDBScript.all_modifiers():
		parts.append("%s Bonus %s" % [
			str(modifier.get("name", "")),
			RunModifierDBScript.reward_bonus_summary(modifier),
		])
		if parts.size() >= 4:
			break
	return "Daily Trials: %s" % " / ".join(parts)

func _best_class_line(meta: Dictionary) -> String:
	var records: Dictionary = meta.get("class_records", {})
	var best_label := "-"
	var best_floor := -1
	var best_wins := 0
	for class_id in records.keys():
		var record: Dictionary = records.get(class_id, {})
		var floor := int(record.get("best_floor", 0))
		if floor > best_floor:
			best_floor = floor
			best_wins = int(record.get("victories", 0))
			best_label = str(record.get("label", class_id))
	if best_floor < 0:
		return "Best Class: No runs yet"
	return "Best Class: %s F%d | Wins %d" % [best_label, best_floor, best_wins]

func _best_element_line(meta: Dictionary) -> String:
	var records: Dictionary = meta.get("element_records", {})
	var best_label := "-"
	var best_floor := -1
	var best_wins := 0
	for element_id in records.keys():
		var record: Dictionary = records.get(element_id, {})
		var floor := int(record.get("best_floor", 0))
		if floor > best_floor:
			best_floor = floor
			best_wins = int(record.get("victories", 0))
			best_label = str(record.get("label", element_id))
	if best_floor < 0:
		return "Best Element: No runs yet"
	return "Best Element: %s F%d | Wins %d" % [best_label, best_floor, best_wins]

func _best_biome_line(meta: Dictionary) -> String:
	var records: Dictionary = meta.get("biome_records", {})
	var best_label := "-"
	var best_floor := -1
	var best_wins := 0
	for biome_id in records.keys():
		var record: Dictionary = records.get(biome_id, {})
		var floor := int(record.get("best_floor", 0))
		if floor > best_floor:
			best_floor = floor
			best_wins = int(record.get("victories", 0))
			best_label = str(record.get("label", biome_id))
	if best_floor < 0:
		return "Best Biome: No runs yet"
	return "Best Biome: %s F%d | Wins %d" % [best_label, best_floor, best_wins]

func _best_boss_line(meta: Dictionary) -> String:
	var records: Dictionary = meta.get("boss_records", {})
	var best_label := "-"
	var best_biome := ""
	var best_floor := -1
	var best_wins := 0
	for boss_id in records.keys():
		var record: Dictionary = records.get(boss_id, {})
		var floor := int(record.get("best_floor", 0))
		if floor > best_floor:
			best_floor = floor
			best_wins = int(record.get("victories", 0))
			best_label = str(record.get("label", boss_id))
			best_biome = str(record.get("biome", "")).strip_edges()
	if best_floor < 0:
		return "Best Boss: No runs yet"
	var biome_text := " | %s" % best_biome if best_biome != "" else ""
	return "Best Boss: %s F%d | Wins %d%s" % [best_label, best_floor, best_wins, biome_text]

func _codex_release_summary(meta: Dictionary = {}) -> String:
	var backlog_size := ReleaseAuditScript.replacement_backlog().size()
	return "Public Gate: %s | %s" % [
		ReleaseAuditScript.public_release_decision(meta),
		"Replace %d before public" % backlog_size if backlog_size > 0
			else "No replacements required",
	]

func _codex_release_detail_line(meta: Dictionary = {}) -> String:
	return "Release Gate: %s | %s | %s | %s | %s | %s | %s | %s" % [
		ReleaseAuditScript.summary_text(meta),
		ReleaseAuditScript.replacement_backlog_summary(3),
		ReleaseAuditScript.next_release_action(meta),
		ReleaseAuditScript.balance_playtest_summary(3, meta),
		ReleaseAuditScript.playtest_objective_summary(meta),
		ReleaseAuditScript.tuning_patch_summary(meta),
		ReleaseAuditScript.balance_playtest_evidence_summary(meta),
		ReleaseAuditScript.source_policy_summary(),
	]

func _mode_record_preview(records: Dictionary) -> String:
	var parts: Array[String] = []
	var keys := records.keys()
	keys.sort()
	for key in keys:
		var record: Dictionary = records.get(key, {})
		if record.is_empty():
			continue
		parts.append("%s F%d %dW/%dR Seed %d" % [
			str(record.get("label", key)),
			int(record.get("best_floor", 0)),
			int(record.get("victories", 0)),
			int(record.get("runs", 0)),
			int(record.get("best_seed", 0)),
		])
		if parts.size() >= 3:
			break
	return " / ".join(parts)

func _element_record_preview(records: Dictionary) -> String:
	var parts: Array[String] = []
	var keys := records.keys()
	keys.sort()
	for key in keys:
		var record: Dictionary = records.get(key, {})
		if record.is_empty():
			continue
		parts.append("%s F%d %dW/%dR Seed %d" % [
			str(record.get("label", key)),
			int(record.get("best_floor", 0)),
			int(record.get("victories", 0)),
			int(record.get("runs", 0)),
			int(record.get("best_seed", 0)),
		])
		if parts.size() >= 3:
			break
	return " / ".join(parts)

func _biome_record_preview(records: Dictionary) -> String:
	var parts: Array[String] = []
	var keys := records.keys()
	keys.sort()
	for key in keys:
		var record: Dictionary = records.get(key, {})
		if record.is_empty():
			continue
		parts.append("%s F%d %dW/%dR Seed %d" % [
			str(record.get("label", key)),
			int(record.get("best_floor", 0)),
			int(record.get("victories", 0)),
			int(record.get("runs", 0)),
			int(record.get("best_seed", 0)),
		])
		if parts.size() >= 3:
			break
	return " / ".join(parts)

func _boss_record_preview(records: Dictionary) -> String:
	var parts: Array[String] = []
	var keys := records.keys()
	keys.sort()
	for key in keys:
		var record: Dictionary = records.get(key, {})
		if record.is_empty():
			continue
		var biome := str(record.get("biome", "")).strip_edges()
		parts.append("%s F%d %dW/%dR%s Seed %d" % [
			str(record.get("label", key)),
			int(record.get("best_floor", 0)),
			int(record.get("victories", 0)),
			int(record.get("runs", 0)),
			" %s" % biome if biome != "" else "",
			int(record.get("best_seed", 0)),
		])
		if parts.size() >= 3:
			break
	return " / ".join(parts)

func _mastered_element_count(records: Dictionary) -> int:
	var count := 0
	for key in records.keys():
		var record: Dictionary = records.get(key, {})
		if int(record.get("victories", 0)) > 0:
			count += 1
	return count

func _combo_preview(combos: Array) -> String:
	var names: Array[String] = []
	for combo in combos.slice(0, 4):
		if combo is Dictionary:
			names.append(str((combo as Dictionary).get("name", "")))
	return " / ".join(names)


func _update_meta_buttons(meta: Dictionary, focus_recommended := false) -> void:
	var recommended_upgrade := _recommended_hub_upgrade_id(meta)
	for upgrade_id in MetaProgressionScript.all_upgrade_ids():
		var button := find_child("MetaBuy_%s" % upgrade_id, true, false) as Button
		if button == null:
			continue
		var visible_for_service := _upgrade_visible_for_service(upgrade_id)
		button.visible = visible_for_service
		button.set_meta("meta_input_action", "buy_hub_upgrade")
		button.set_meta("upgrade_id", upgrade_id)
		button.set_meta("hub_service", _active_hub_service)
		button.set_meta("hub_category", _upgrade_hub_category(upgrade_id))
		var costs := MetaProgressionScript.upgrade_costs(upgrade_id)
		var level := int(meta.get("upgrades", {}).get(upgrade_id, 0))
		var max_level := MetaProgressionScript.upgrade_max_level(upgrade_id)
		var label := MetaProgressionScript.upgrade_label(upgrade_id)
		var next_effect := MetaProgressionScript.upgrade_next_effect(upgrade_id, level)
		var recommended: bool = str(upgrade_id) == recommended_upgrade
		button.set_meta("recommended_hub_upgrade", recommended)
		button.tooltip_text = "%s | %s | %s" % [
			label,
			_active_hub_service,
			_upgrade_hub_category(upgrade_id),
		]
		if level >= max_level:
			button.text = "%s Lv%d/%d | MAX" % [label, level, max_level]
			button.disabled = true
		else:
			var can_afford := _can_afford(meta, costs)
			button.text = "%s%s Lv%d/%d (%s)\nNext: %s" % [
				"NEXT | " if recommended else "",
				label,
				level,
				max_level,
				_format_costs(costs),
				next_effect,
			]
			button.disabled = (not visible_for_service) or (not can_afford)
		if focus_recommended and recommended and visible_for_service and not button.disabled:
			button.grab_focus()

func _upgrade_visible_for_service(upgrade_id: String) -> bool:
	if _active_hub_service == "Codex":
		return false
	var allowed: Array = HUB_UPGRADE_GROUPS.get(_active_hub_service, [])
	return allowed.is_empty() or allowed.has(upgrade_id)

func _upgrade_hub_category(upgrade_id: String) -> String:
	return str(HUB_UPGRADE_CATEGORIES.get(upgrade_id, "dungeon_gate"))

func _recommended_hub_upgrade_id(meta: Dictionary) -> String:
	if _active_hub_service == "Codex":
		return ""
	var fallback := ""
	for upgrade_id in _hub_upgrade_ids(_active_hub_service):
		var id := str(upgrade_id)
		var level := int(meta.get("upgrades", {}).get(id, 0))
		if level >= MetaProgressionScript.upgrade_max_level(id):
			continue
		if fallback == "":
			fallback = id
		if _can_afford(meta, MetaProgressionScript.upgrade_costs(id)):
			return id
	return fallback


func _on_meta_buy_pressed(upgrade_id: String) -> void:
	_reset_pending = false
	if _meta_status_label != null:
		_meta_status_label.text = ""
	MetaProgressionScript.buy_upgrade(upgrade_id)
	_play_class_select_sfx("meta_buy", {"upgrade_id": upgrade_id})
	_update()

func _on_reset_profile_pressed(button: Button) -> void:
	if not _reset_pending:
		_reset_pending = true
		button.text = "CONFIRM RESET PROFILE"
		if _meta_status_label != null:
			_meta_status_label.text = "Press reset again to erase meta progress."
		_play_class_select_sfx("meta_reset_warn", {"reset_pending": true})
		return
	MetaProgressionScript.reset_profile()
	_reset_pending = false
	button.text = "RESET PROFILE"
	if _meta_status_label != null:
		_meta_status_label.text = "Meta profile reset."
	_play_class_select_sfx("meta_reset_confirm", {"reset_pending": false})
	_update()

func _format_costs(costs: Dictionary) -> String:
	var parts: Array[String] = []
	for key in ["banked_gold", "soul_shards", "element_cores", "rune_dust", "blueprints"]:
		var amount := int(costs.get(key, 0))
		if amount <= 0:
			continue
		parts.append("%d %s" % [amount, _currency_label(key)])
	return " + ".join(parts)

func _currency_label(key: String) -> String:
	match key:
		"banked_gold":
			return "Gold"
		"soul_shards":
			return "Shard"
		"element_cores":
			return "Core"
		"rune_dust":
			return "Dust"
		"blueprints":
			return "BP"
		_:
			return key

func _can_afford(meta: Dictionary, costs: Dictionary) -> bool:
	for key in costs.keys():
		if int(meta.get(key, 0)) < int(costs[key]):
			return false
	return not costs.is_empty()


func _on_start() -> void:
	_play_class_select_sfx("confirm_run", {
		"class_id": _selected_class,
		"element": _selected_element,
		"run_mode": _selected_run_mode,
		"seed": selected_seed(),
	})
	confirmed.emit(_selected_class, _selected_element, selected_seed(), selected_run_mode())
	queue_free()
