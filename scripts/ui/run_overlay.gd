class_name RunOverlay
extends CanvasLayer
## Fullscreen dimmed UI for run end states and room-clear upgrades.

const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")
const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

signal upgrade_chosen(upgrade_id: String)
signal reward_skipped(gold: int)
signal reward_reroll_requested(cost: int)
signal shop_choice_chosen(index: int)
signal resume_requested
signal restart_requested
signal class_select_requested
signal settings_changed(settings: Dictionary)

var _title: Label
var _subtitle: Label
var _choice_scroll: ScrollContainer
var _choice_box: VBoxContainer
const UPGRADE_SKIP_GOLD := 10
const UPGRADE_REROLL_COST := 8
var _overlay_mode := ""
var _upgrade_hotkey_ids: Array[String] = []
var _upgrade_hotkey_disabled: Array[bool] = []
var _upgrade_hotkey_contexts: Array[Dictionary] = []
var _upgrade_choice_buttons: Array[Button] = []
var _upgrade_hotkey_can_reroll := false
var _upgrade_hotkey_reroll_blocked_reason := "Reroll unavailable"
var _shop_hotkey_indices: Array[int] = []
var _shop_hotkey_disabled: Array[bool] = []
var _shop_choice_contexts: Array[Dictionary] = []
var _shop_choice_buttons: Array[Button] = []
var _message_choice_buttons: Array[Button] = []
var _message_choice_disabled: Array[bool] = []
var _controller_selection_index := -1
var _accessibility_settings := {
	"master_volume": 1.0,
	"damage_flash_enabled": true,
	"damage_vignette_enabled": true,
	"screen_shake_scale": 1.0,
	"hit_pause_scale": 1.0,
	"high_contrast_cues": false,
}
var _pause_settings_label: Label
var _rarity_colors := {
	"common": Color.WHITE,
	"uncommon": Color(0.56, 0.95, 0.58),
	"rare": Color(0.55, 0.78, 1.0),
	"epic": Color(0.96, 0.62, 1.0),
	"legendary": Color(1.0, 0.72, 0.34),
	"mythic": Color(1.0, 0.42, 0.42),
}


func _ready() -> void:
	layer = 20
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_title = Label.new()
	_title.name = "OverlayTitle"
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.position = Vector2(-300, 76)
	_title.custom_minimum_size = Vector2(600, 44)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	add_child(_title)

	_subtitle = Label.new()
	_subtitle.name = "OverlaySubtitle"
	_subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_subtitle.position = Vector2(-300, 126)
	_subtitle.custom_minimum_size = Vector2(600, 24)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 12)
	add_child(_subtitle)

	_choice_scroll = ScrollContainer.new()
	_choice_scroll.name = "ChoiceScroll"
	_choice_scroll.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_choice_scroll.position = Vector2(-190, 164)
	_choice_scroll.custom_minimum_size = Vector2(380, 390)
	_choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_choice_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_choice_scroll)

	_choice_box = VBoxContainer.new()
	_choice_box.custom_minimum_size = Vector2(360, 0)
	_choice_scroll.add_child(_choice_box)

func show_message(title: String, subtitle: String) -> void:
	_clear_choices()
	_overlay_mode = "message"
	_play_run_end_sfx(title)
	_title.text = title
	_subtitle.text = subtitle
	var restart := Button.new()
	restart.name = "RunEndRestart"
	restart.text = "Restart Run"
	restart.custom_minimum_size = Vector2(220, 34)
	restart.pressed.connect(func() -> void:
		_emit_restart_requested())
	_choice_box.add_child(restart)
	_message_choice_buttons.append(restart)
	_message_choice_disabled.append(false)
	var class_select := Button.new()
	class_select.name = "RunEndClassSelect"
	class_select.text = "Class Select"
	class_select.custom_minimum_size = Vector2(220, 34)
	class_select.pressed.connect(func() -> void:
		_emit_class_select_requested())
	_choice_box.add_child(class_select)
	_message_choice_buttons.append(class_select)
	_message_choice_disabled.append(false)
	_set_controller_selection("message", _first_enabled_index(_message_choice_disabled))
	visible = true

func show_upgrade_choices(
		choices: Array,
		stack_counts: Dictionary = {},
		can_reroll: bool = false,
		build_tags: Array = [],
		reroll_state: String = "",
		history_summary: String = "",
		effect_previews: Dictionary = {},
		rune_socket_summary: String = "",
		build_archetype: String = "",
		power_arc_summary: String = "",
		run_modifier_summary: String = "",
		next_power_milestone: String = "",
		tag_stack_counts: Dictionary = {},
		run_goal_summary: String = "",
		challenge_bonus_status: String = "",
) -> void:
	_clear_choices()
	_title.text = "CHOOSE UPGRADE"
	_subtitle.text = "Pick one reward"
	_populate_upgrade_choices(
		choices, stack_counts, can_reroll, build_tags, "", reroll_state,
		history_summary, effect_previews, rune_socket_summary, build_archetype,
		power_arc_summary, run_modifier_summary, next_power_milestone,
		tag_stack_counts, run_goal_summary, challenge_bonus_status)

func show_room_upgrade_choices(
		choices: Array,
		room_type: int,
		stack_counts: Dictionary = {},
		can_reroll: bool = false,
		build_tags: Array = [],
		reroll_state: String = "",
		history_summary: String = "",
		effect_previews: Dictionary = {},
		rune_socket_summary: String = "",
		build_archetype: String = "",
		power_arc_summary: String = "",
		run_modifier_summary: String = "",
		next_power_milestone: String = "",
		tag_stack_counts: Dictionary = {},
		run_goal_summary: String = "",
		challenge_bonus_status: String = "",
) -> void:
	_clear_choices()
	_title.text = _room_reward_title(room_type)
	_subtitle.text = _room_reward_subtitle(room_type)
	_add_reward_flow_cue(room_type, choices.size(), build_archetype, power_arc_summary)
	_populate_upgrade_choices(
		choices, stack_counts, can_reroll, build_tags,
		_reward_recap_text(room_type, choices.size(), can_reroll, reroll_state),
		reroll_state,
		history_summary,
		effect_previews,
		rune_socket_summary,
		build_archetype,
		power_arc_summary,
		run_modifier_summary,
		next_power_milestone,
		tag_stack_counts,
		run_goal_summary,
		challenge_bonus_status)

func show_room_upgrade_choices_with_socket_context(
		choices: Array,
		room_type: int,
		stack_counts: Dictionary = {},
		can_reroll: bool = false,
		build_tags: Array = [],
		reroll_state: String = "",
		history_summary: String = "",
		effect_previews: Dictionary = {},
		rune_socket_summary: String = "",
		build_archetype: String = "",
		power_arc_summary: String = "",
		run_modifier_summary: String = "",
		next_power_milestone: String = "",
		tag_stack_counts: Dictionary = {},
		run_goal_summary: String = "",
		challenge_bonus_status: String = "",
) -> void:
	show_room_upgrade_choices(
		choices,
		room_type,
		stack_counts,
		can_reroll,
		build_tags,
		reroll_state,
		history_summary,
		effect_previews,
		rune_socket_summary,
		build_archetype,
		power_arc_summary,
		run_modifier_summary,
		next_power_milestone,
		tag_stack_counts,
		run_goal_summary,
		challenge_bonus_status)

func _populate_upgrade_choices(
		choices: Array,
		stack_counts: Dictionary = {},
		can_reroll: bool = false,
		build_tags: Array = [],
		recap_text: String = "",
		reroll_state: String = "",
		history_summary: String = "",
		effect_previews: Dictionary = {},
		rune_socket_summary: String = "",
		build_archetype: String = "",
		power_arc_summary: String = "",
		run_modifier_summary: String = "",
		next_power_milestone: String = "",
		tag_stack_counts: Dictionary = {},
		run_goal_summary: String = "",
		challenge_bonus_status: String = "",
) -> void:
	_overlay_mode = "upgrade"
	_upgrade_hotkey_can_reroll = can_reroll
	_upgrade_hotkey_reroll_blocked_reason = _reroll_state_text(can_reroll, reroll_state)
	if recap_text != "":
		var recap := Label.new()
		recap.name = "RewardRecapLabel"
		recap.text = recap_text
		recap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		recap.add_theme_font_size_override("font_size", 9)
		recap.add_theme_color_override("font_color", Color(0.72, 0.9, 1.0))
		_choice_box.add_child(recap)
	if power_arc_summary != "":
		var power_arc := Label.new()
		power_arc.name = "RewardPowerArcLabel"
		power_arc.text = "Power Arc: %s" % power_arc_summary
		power_arc.set_meta("run_power_arc", power_arc_summary)
		power_arc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		power_arc.add_theme_font_size_override("font_size", 9)
		power_arc.add_theme_color_override("font_color", Color(0.76, 1.0, 0.72))
		_choice_box.add_child(power_arc)
	if next_power_milestone != "":
		var next_milestone := Label.new()
		next_milestone.name = "RewardNextMilestoneLabel"
		next_milestone.text = next_power_milestone
		next_milestone.set_meta("next_power_milestone", next_power_milestone)
		next_milestone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		next_milestone.add_theme_font_size_override("font_size", 9)
		next_milestone.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
		_choice_box.add_child(next_milestone)
	if build_archetype != "":
		var archetype := Label.new()
		archetype.name = "RewardBuildArchetypeLabel"
		archetype.text = "Archetype: %s" % build_archetype
		archetype.set_meta("build_archetype", build_archetype)
		archetype.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		archetype.add_theme_font_size_override("font_size", 9)
		archetype.add_theme_color_override("font_color", Color(0.78, 0.96, 1.0))
		_choice_box.add_child(archetype)
	if run_modifier_summary != "":
		var challenge := Label.new()
		challenge.name = "RewardChallengeLabel"
		challenge.text = "Challenge: %s" % run_modifier_summary
		challenge.set_meta("run_modifier", run_modifier_summary)
		challenge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		challenge.add_theme_font_size_override("font_size", 9)
		challenge.add_theme_color_override("font_color", Color(1.0, 0.78, 0.45))
		_choice_box.add_child(challenge)
	if run_goal_summary != "" or challenge_bonus_status != "":
		var goal := Label.new()
		goal.name = "RewardChallengeGoalLabel"
		var parts: Array[String] = []
		if run_goal_summary != "":
			parts.append(run_goal_summary)
		if challenge_bonus_status != "":
			parts.append("Bonus: %s" % challenge_bonus_status)
		goal.text = " | ".join(parts)
		goal.set_meta("run_goal_summary", run_goal_summary)
		goal.set_meta("challenge_bonus_status", challenge_bonus_status)
		goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		goal.add_theme_font_size_override("font_size", 9)
		goal.add_theme_color_override("font_color", Color(0.96, 0.9, 0.58))
		_choice_box.add_child(goal)
	var last_pick := _last_pick_text(history_summary)
	if last_pick != "":
		var cue := Label.new()
		cue.name = "RewardHistoryCueLabel"
		cue.text = "Last pick: %s" % last_pick
		cue.set_meta("full_history", history_summary)
		cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cue.add_theme_font_size_override("font_size", 9)
		cue.add_theme_color_override("font_color", Color(0.9, 0.86, 0.58))
		_choice_box.add_child(cue)
	if rune_socket_summary != "":
		var socket_cue := Label.new()
		socket_cue.name = "RewardRuneSocketCueLabel"
		socket_cue.text = "Rune/Socket: %s" % rune_socket_summary
		socket_cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		socket_cue.add_theme_font_size_override("font_size", 9)
		socket_cue.add_theme_color_override("font_color", Color(0.86, 0.78, 1.0))
		_choice_box.add_child(socket_cue)
	var best_fit_index := _best_upgrade_fit_index(
		choices, build_tags, stack_counts, effect_previews, rune_socket_summary,
		build_archetype, tag_stack_counts)
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.name = "Upgrade_%s" % str(choice.get("id", ""))
		var rarity := str(choice.get("rarity", "common"))
		var label := _rarity_label(rarity)
		var id := str(choice.get("id", ""))
		var matching_tags := _matching_tags(choice, build_tags)
		var maxed := _is_upgrade_maxed(choice, stack_counts)
		var disabled_reason := _upgrade_disabled_reason(choice, stack_counts)
		var effect_preview := str(effect_previews.get(id, ""))
		var socket_context := rune_socket_summary if _choice_tags(choice).has("socket") else ""
		var synergy_reason := _build_match_reason(matching_tags, build_archetype)
		var recommendation := _upgrade_recommendation_text(choice, matching_tags, build_archetype)
		var set_progress := _choice_set_progress(choice, tag_stack_counts)
		var fit_score := _choice_fit_score(
			choice, matching_tags, recommendation, effect_preview, disabled_reason,
			"", socket_context, set_progress)
		var fit_reasons := _choice_fit_reasons(
			choice, matching_tags, recommendation, effect_preview, disabled_reason,
			"", socket_context, set_progress)
		var best_fit := i == best_fit_index
		button.text = "Choice %d/%d | %s%s\n%s%s%s%s" % [
			i + 1,
			choices.size(),
			label,
			choice.get("name", "?"),
			choice.get("desc", ""),
			_effect_preview(effect_preview) + _tag_preview(choice),
			_build_match_preview(matching_tags, build_archetype) + _stack_preview(choice, stack_counts) \
				+ _upgrade_recommendation_preview(recommendation) \
				+ _set_progress_preview(set_progress) \
				+ _fit_score_preview(fit_score, fit_reasons, best_fit) + _disabled_preview(disabled_reason),
			_socket_context_preview(socket_context),
		]
		_prepare_choice_button(button)
		button.set_meta("choice_index", i + 1)
		button.set_meta("choice_count", choices.size())
		_set_choice_input_meta(
			button,
			"reward_choose",
			str(i + 1),
			_choice_hotkey_for_index(i),
			"Choose reward %d" % [i + 1])
		button.set_meta("rarity", rarity)
		button.set_meta("tags", choice.get("tags", []))
		button.set_meta("build_match", not matching_tags.is_empty())
		button.set_meta("build_match_tags", matching_tags)
		button.set_meta("synergy_reason", synergy_reason)
		button.set_meta("recommended", recommendation != "")
		button.set_meta("recommendation", recommendation)
		button.set_meta("effect_preview", effect_preview)
		button.set_meta("fit_score", fit_score)
		button.set_meta("fit_reasons", _fit_reasons_text(fit_reasons))
		button.set_meta("best_fit", best_fit)
		button.set_meta("disabled_reason", disabled_reason)
		button.set_meta("socket_context", socket_context)
		_apply_set_progress_meta(button, set_progress)
		_apply_choice_icon(button, _upgrade_icon_sprite_name(choice))
		button.modulate = _rarity_colors.get(rarity, Color.WHITE)
		button.disabled = maxed or bool(choice.get("disabled", false))
		var decision_context := {
			"choice_index": i + 1,
			"choice_count": choices.size(),
			"rarity": rarity,
			"tags": _choice_tags(choice),
			"build_match_tags": matching_tags,
			"synergy_reason": synergy_reason,
			"recommendation": recommendation,
			"effect_preview": effect_preview,
			"fit_score": fit_score,
			"fit_reasons": fit_reasons,
			"best_fit": best_fit,
			"socket_context": socket_context,
			"disabled_reason": disabled_reason,
		}
		for key in set_progress.keys():
			decision_context[str(key)] = set_progress[key]
		_set_upgrade_choice_tooltip(button, choice, decision_context)
		button.pressed.connect(_on_upgrade_button_pressed.bind(id, decision_context))
		_choice_box.add_child(button)
		_upgrade_hotkey_ids.append(id)
		_upgrade_hotkey_disabled.append(button.disabled)
		_upgrade_hotkey_contexts.append(decision_context)
		_upgrade_choice_buttons.append(button)
	var reroll := Button.new()
	reroll.name = "UpgradeReroll"
	reroll.text = _reroll_button_text(can_reroll, reroll_state)
	reroll.custom_minimum_size = Vector2(360, 32)
	reroll.disabled = not can_reroll
	reroll.set_meta("disabled_reason", _upgrade_hotkey_reroll_blocked_reason)
	_set_choice_input_meta(reroll, "reward_reroll", "R", KEY_R, "Reroll rewards")
	reroll.pressed.connect(_on_upgrade_reroll_pressed)
	_choice_box.add_child(reroll)
	var skip := Button.new()
	skip.name = "UpgradeSkip"
	skip.text = "Skip (+%d gold)" % UPGRADE_SKIP_GOLD
	skip.custom_minimum_size = Vector2(360, 32)
	_set_choice_input_meta(skip, "reward_skip", "S", KEY_S, "Skip reward")
	skip.pressed.connect(_on_upgrade_skip_pressed)
	_choice_box.add_child(skip)
	_set_controller_selection("upgrade", _first_enabled_index(_upgrade_hotkey_disabled))
	visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _handle_action_input(event):
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var handled := false
	var choice_index := _reward_choice_index_for_key(key.keycode)
	match _overlay_mode:
		"upgrade":
			if choice_index >= 0:
				handled = _choose_upgrade_hotkey(choice_index)
			elif key.keycode == KEY_R:
				if _upgrade_hotkey_can_reroll:
					_on_upgrade_reroll_pressed()
					handled = true
				else:
					_show_hotkey_blocked_feedback("reward", _upgrade_hotkey_reroll_blocked_reason)
					handled = true
			elif key.keycode == KEY_S:
				_on_upgrade_skip_pressed()
				handled = true
		"shop":
			if choice_index >= 0:
				handled = _choose_shop_hotkey(choice_index)
			elif key.keycode == KEY_L or key.keycode == KEY_ESCAPE:
				_on_shop_choice_button_pressed(-1)
				handled = true
		"pause":
			if key.keycode == KEY_ESCAPE:
				_emit_resume_requested()
				handled = true
			elif key.keycode == KEY_R:
				_emit_restart_requested()
				handled = true
			elif key.keycode == KEY_C:
				_emit_class_select_requested()
				handled = true
		"message":
			if key.keycode == KEY_R:
				_emit_restart_requested()
				handled = true
			elif key.keycode == KEY_C:
				_emit_class_select_requested()
				handled = true
	if handled:
		get_viewport().set_input_as_handled()

func _handle_action_input(event: InputEvent) -> bool:
	var choice_index := _reward_choice_index_for_action(event)
	match _overlay_mode:
		"upgrade":
			if choice_index >= 0:
				_choose_upgrade_hotkey(choice_index)
				return true
			if event.is_action_pressed("menu_next"):
				_move_controller_selection("upgrade", 1)
				return true
			if event.is_action_pressed("menu_prev"):
				_move_controller_selection("upgrade", -1)
				return true
			if event.is_action_pressed("menu_confirm"):
				var selected := _selected_or_first_enabled_index(_upgrade_hotkey_disabled)
				if selected >= 0:
					_choose_upgrade_hotkey(selected)
				return true
			if event.is_action_pressed("menu_back"):
				_on_upgrade_skip_pressed()
				return true
		"shop":
			if choice_index >= 0:
				_choose_shop_hotkey(choice_index)
				return true
			if event.is_action_pressed("menu_next"):
				_move_controller_selection("shop", 1)
				return true
			if event.is_action_pressed("menu_prev"):
				_move_controller_selection("shop", -1)
				return true
			if event.is_action_pressed("menu_confirm"):
				var selected := _selected_or_first_enabled_index(_shop_hotkey_disabled)
				if selected >= 0:
					_choose_shop_hotkey(selected)
				return true
			if event.is_action_pressed("menu_back"):
				_on_shop_choice_button_pressed(-1, {"choice_count": _shop_hotkey_indices.size()})
				return true
		"pause":
			if event.is_action_pressed("menu_back") or event.is_action_pressed("menu_confirm"):
				_emit_resume_requested()
				return true
		"message":
			if event.is_action_pressed("menu_next"):
				_move_controller_selection("message", 1)
				return true
			if event.is_action_pressed("menu_prev"):
				_move_controller_selection("message", -1)
				return true
			if event.is_action_pressed("menu_confirm"):
				var selected := _selected_or_first_enabled_index(_message_choice_disabled)
				if selected == 1:
					_emit_class_select_requested()
				else:
					_emit_restart_requested()
				return true
			if event.is_action_pressed("menu_back"):
				_emit_class_select_requested()
				return true
	return false

func _reward_choice_index_for_key(keycode: int) -> int:
	match keycode:
		KEY_1, KEY_KP_1:
			return 0
		KEY_2, KEY_KP_2:
			return 1
		KEY_3, KEY_KP_3:
			return 2
	return -1

func _reward_choice_index_for_action(event: InputEvent) -> int:
	for index in 4:
		if event.is_action_pressed("route_choice_%d" % (index + 1)):
			return index
	return -1

func _first_enabled_index(disabled_flags: Array[bool]) -> int:
	for index in disabled_flags.size():
		if not bool(disabled_flags[index]):
			return index
	return -1

func _selected_or_first_enabled_index(disabled_flags: Array[bool]) -> int:
	if _controller_selection_index >= 0 \
			and _controller_selection_index < disabled_flags.size() \
			and not bool(disabled_flags[_controller_selection_index]):
		return _controller_selection_index
	return _first_enabled_index(disabled_flags)

func _move_controller_selection(mode: String, delta: int) -> bool:
	var disabled_flags := _controller_disabled_flags(mode)
	if disabled_flags.is_empty():
		return false
	var start := _controller_selection_index
	if start < 0 or start >= disabled_flags.size():
		start = _first_enabled_index(disabled_flags)
	if start < 0:
		return false
	for step in range(1, disabled_flags.size() + 1):
		var index := wrapi(start + delta * step, 0, disabled_flags.size())
		if not bool(disabled_flags[index]):
			_set_controller_selection(mode, index)
			return true
	return false

func _set_controller_selection(mode: String, index: int) -> void:
	_controller_selection_index = index
	set_meta("controller_selection_mode", mode)
	set_meta("controller_selection_index", index)
	var buttons := _controller_buttons(mode)
	for i in buttons.size():
		var button := buttons[i]
		if button == null:
			continue
		var selected := i == index
		button.set_meta("controller_selected", selected)
		if selected and is_instance_valid(button):
			button.grab_focus()
			set_meta("controller_selection_label", button.text.get_slice("\n", 0))

func _controller_disabled_flags(mode: String) -> Array[bool]:
	match mode:
		"upgrade":
			return _upgrade_hotkey_disabled
		"shop":
			return _shop_hotkey_disabled
		"message":
			return _message_choice_disabled
	return []

func _controller_buttons(mode: String) -> Array[Button]:
	match mode:
		"upgrade":
			return _upgrade_choice_buttons
		"shop":
			return _shop_choice_buttons
		"message":
			return _message_choice_buttons
	return []

func _choice_hotkey_for_index(index: int) -> int:
	match index:
		0:
			return KEY_1
		1:
			return KEY_2
		2:
			return KEY_3
	return 0

func _set_choice_input_meta(
		button: Button,
		action: String,
		key_label: String,
		hotkey: int,
		action_text: String,
		alt_hotkey: int = 0,
) -> void:
	button.set_meta("choice_input_action", action)
	button.set_meta("choice_key_label", key_label)
	button.set_meta("choice_hotkey", hotkey)
	button.set_meta("choice_action_text", action_text)
	button.tooltip_text = "%s [%s]" % [action_text, key_label]
	if alt_hotkey != 0:
		button.set_meta("choice_alt_hotkey", alt_hotkey)
		button.tooltip_text += " / Esc"

func _set_upgrade_choice_tooltip(
		button: Button,
		choice: Dictionary,
		context: Dictionary,
) -> void:
	var parts: Array[String] = [button.tooltip_text]
	var name := str(choice.get("name", "?")).strip_edges()
	var rarity := str(context.get("rarity", "common")).strip_edges()
	if rarity != "" and rarity != "common":
		name = "%s (%s)" % [name, rarity.capitalize()]
	if name != "":
		parts.append(name)
	var desc := str(choice.get("desc", "")).strip_edges()
	if desc != "":
		parts.append(desc)
	var preview := str(context.get("effect_preview", "")).strip_edges()
	if preview != "":
		parts.append("Preview: %s" % preview)
	var tags := _readable_tags(context.get("tags", []))
	if tags != "":
		parts.append("Tags: %s" % tags)
	var synergy := str(context.get("synergy_reason", "")).strip_edges()
	if synergy != "":
		parts.append("Synergy: %s" % synergy)
	var recommendation := str(context.get("recommendation", "")).strip_edges()
	if recommendation != "":
		parts.append("Recommended: %s" % recommendation)
	var set_progress := str(context.get("set_progress_hint", "")).strip_edges()
	if set_progress != "":
		parts.append("Set Progress: %s" % set_progress)
	var set_bonus_effect := str(context.get("set_bonus_effect", "")).strip_edges()
	if set_bonus_effect != "":
		parts.append("Set Bonus: %s" % set_bonus_effect)
	var set_bonus_next_effect := str(context.get("set_bonus_next_effect", "")).strip_edges()
	if set_bonus_next_effect != "":
		parts.append("Set Bonus Next: %s" % set_bonus_next_effect)
	var fit := "Fit: %d%% | %s" % [
		int(context.get("fit_score", 0)),
		_fit_reasons_text(context.get("fit_reasons", [])),
	]
	if bool(context.get("best_fit", false)):
		fit += " | Best Fit"
	parts.append(fit)
	var socket := str(context.get("socket_context", "")).strip_edges()
	if socket != "":
		parts.append("Socket Plan: %s" % socket)
	var disabled := str(context.get("disabled_reason", "")).strip_edges()
	if disabled != "":
		parts.append("Unavailable: %s" % disabled)
	button.tooltip_text = "\n".join(parts)

func _set_shop_choice_tooltip(button: Button, context: Dictionary) -> void:
	var parts: Array[String] = [button.tooltip_text]
	var name := str(context.get("item_name", "")).strip_edges()
	var rarity := str(context.get("rarity", "common")).strip_edges()
	if rarity != "" and rarity != "common":
		name = "%s (%s)" % [name, rarity.capitalize()]
	if name != "":
		parts.append(name)
	var category := str(context.get("category", "")).strip_edges()
	var cost := int(context.get("cost", 0))
	if category != "":
		parts.append("%s | %d gold" % [category, cost])
	else:
		parts.append("%d gold" % cost)
	var tags := _readable_tags(context.get("tags", []))
	if tags != "":
		parts.append("Tags: %s" % tags)
	var recommendation := str(context.get("recommendation", "")).strip_edges()
	if recommendation != "":
		parts.append("Recommended: %s" % recommendation)
	var comparison := str(context.get("weapon_comparison", "")).strip_edges()
	if comparison != "":
		parts.append(comparison)
	var fit := "Fit: %d%% | %s" % [
		int(context.get("fit_score", 0)),
		_fit_reasons_text(context.get("fit_reasons", [])),
	]
	if bool(context.get("best_fit", false)):
		fit += " | Best Fit"
	parts.append(fit)
	var disabled := str(context.get("disabled_reason", "")).strip_edges()
	if disabled != "":
		parts.append("Unavailable: %s" % disabled)
	button.tooltip_text = "\n".join(parts)

func _choose_upgrade_hotkey(index: int) -> bool:
	if index < 0 or index >= _upgrade_hotkey_ids.size():
		return false
	if bool(_upgrade_hotkey_disabled[index]):
		var blocked_context: Dictionary = _upgrade_hotkey_contexts[index] \
			if index < _upgrade_hotkey_contexts.size() else {}
		_show_hotkey_blocked_feedback("reward", str(blocked_context.get("disabled_reason", "Unavailable")))
		return false
	var context: Dictionary = _upgrade_hotkey_contexts[index] \
		if index < _upgrade_hotkey_contexts.size() else {}
	_on_upgrade_button_pressed(_upgrade_hotkey_ids[index], context)
	return true

func _choose_shop_hotkey(index: int) -> bool:
	if index < 0 or index >= _shop_hotkey_indices.size():
		return false
	var choice_index := int(_shop_hotkey_indices[index])
	if bool(_shop_hotkey_disabled[index]):
		var blocked_context: Dictionary = _shop_choice_contexts[choice_index] \
			if choice_index >= 0 and choice_index < _shop_choice_contexts.size() else {}
		_show_hotkey_blocked_feedback("shop", str(blocked_context.get("disabled_reason", "Unavailable")))
		return false
	var context: Dictionary = _shop_choice_contexts[choice_index] \
		if choice_index >= 0 and choice_index < _shop_choice_contexts.size() else {}
	_on_shop_choice_button_pressed(choice_index, context)
	return true

func _show_hotkey_blocked_feedback(kind: String, reason: String) -> void:
	var clean_reason := reason.strip_edges()
	if clean_reason == "":
		clean_reason = "Unavailable"
	_subtitle.text = "Unavailable: %s" % clean_reason
	_subtitle.set_meta("hotkey_blocked_kind", kind)
	_subtitle.set_meta("hotkey_blocked_reason", clean_reason)
	set_meta("last_hotkey_blocked_kind", kind)
	set_meta("last_hotkey_blocked_reason", clean_reason)

func _room_reward_title(room_type: int) -> String:
	match room_type:
		RoomNode.RoomType.ELITE:
			return "ELITE REWARD"
		RoomNode.RoomType.MINIBOSS:
			return "MINIBOSS REWARD"
		RoomNode.RoomType.BOSS:
			return "BOSS REWARD"
		RoomNode.RoomType.TREASURE:
			return "TREASURE REWARD"
		RoomNode.RoomType.EVENT:
			return "EVENT REWARD"
		RoomNode.RoomType.SECRET:
			return "SECRET REWARD"
		_:
			return "ROOM REWARD"

func _room_reward_subtitle(room_type: int) -> String:
	match room_type:
		RoomNode.RoomType.ELITE, RoomNode.RoomType.MINIBOSS, RoomNode.RoomType.BOSS, \
				RoomNode.RoomType.TREASURE, RoomNode.RoomType.EVENT:
			return "Pick one reward | Rare+ guaranteed"
		_:
			return "Pick one reward"

func _reward_recap_text(
		room_type: int,
		choice_count: int,
		can_reroll: bool,
		reroll_state: String = "",
) -> String:
	var reroll_text := _reroll_state_text(can_reroll, reroll_state)
	return "%s cleared | Choose 1/%d | %s | Skip +%d gold" % [
		_room_reward_title(room_type).replace(" REWARD", ""),
		maxi(choice_count, 1),
		reroll_text,
		UPGRADE_SKIP_GOLD,
	]

func _add_reward_flow_cue(
		room_type: int,
		choice_count: int,
		build_archetype: String = "",
		power_arc_summary: String = "",
) -> void:
	var next_action_key := "portal" if room_type == RoomNode.RoomType.BOSS else "door"
	var next_action_text := "Portal" if next_action_key == "portal" else "Door opens"
	var cue := Label.new()
	cue.name = "RewardFlowCueLabel"
	cue.text = "Claim 1/%d -> Build stronger -> Next: %s" % [
		maxi(choice_count, 1),
		next_action_text,
	]
	cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cue.add_theme_font_size_override("font_size", 9)
	cue.add_theme_color_override("font_color", Color(0.7, 0.92, 1.0))
	cue.set_meta("flow_kind", "reward")
	cue.set_meta("choice_count", maxi(choice_count, 1))
	cue.set_meta("room_type_name", _room_type_name(room_type))
	cue.set_meta("next_action_key", next_action_key)
	cue.set_meta("next_action_text", next_action_text)
	cue.set_meta("build_archetype", build_archetype)
	cue.set_meta("run_power_arc", power_arc_summary)
	_choice_box.add_child(cue)

func _add_shop_flow_cue(choice_count: int, gold: int) -> void:
	var cue := Label.new()
	cue.name = "ShopFlowCueLabel"
	cue.text = "Choose 1/%d -> Gold %d -> Next: Door opens" % [
		maxi(choice_count, 1),
		gold,
	]
	cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cue.add_theme_font_size_override("font_size", 9)
	cue.add_theme_color_override("font_color", Color(0.95, 0.86, 0.58))
	cue.set_meta("flow_kind", "shop")
	cue.set_meta("choice_count", maxi(choice_count, 1))
	cue.set_meta("gold", gold)
	cue.set_meta("next_action_key", "door")
	cue.set_meta("next_action_text", "Door opens")
	_choice_box.add_child(cue)

func _room_type_name(room_type: int) -> String:
	var names := RoomNode.RoomType.keys()
	return str(names[room_type]) if room_type >= 0 and room_type < names.size() else "ROOM"

func _reroll_button_text(can_reroll: bool, reroll_state: String = "") -> String:
	if can_reroll:
		return "Reroll (-%d gold)" % UPGRADE_REROLL_COST
	return _reroll_state_text(can_reroll, reroll_state)

func _reroll_state_text(can_reroll: bool, reroll_state: String = "") -> String:
	if can_reroll:
		return "Reroll once"
	match reroll_state:
		"used":
			return "Reroll used"
		"need_gold":
			return "Reroll needs %d gold" % UPGRADE_REROLL_COST
		_:
			return "Reroll unavailable"

func show_shop_choices(
		choices: Array,
		gold: int,
		build_tags: Array = [],
		weapon_context: Dictionary = {},
		run_goal_summary: String = "",
		challenge_bonus_status: String = "",
) -> void:
	_clear_choices()
	_overlay_mode = "shop"
	_title.text = "SHOP"
	_subtitle.text = "Gold: %d" % gold
	_add_shop_flow_cue(choices.size(), gold)
	if run_goal_summary != "" or challenge_bonus_status != "":
		var goal := Label.new()
		goal.name = "ShopChallengeGoalLabel"
		var parts: Array[String] = []
		if run_goal_summary != "":
			parts.append(run_goal_summary)
		if challenge_bonus_status != "":
			parts.append("Bonus: %s" % challenge_bonus_status)
		goal.text = " | ".join(parts)
		goal.set_meta("run_goal_summary", run_goal_summary)
		goal.set_meta("challenge_bonus_status", challenge_bonus_status)
		goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		goal.add_theme_font_size_override("font_size", 9)
		goal.add_theme_color_override("font_color", Color(0.96, 0.9, 0.58))
		_choice_box.add_child(goal)
	var best_fit_index := _best_shop_fit_index(choices, gold, build_tags, weapon_context)
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.name = "ShopChoice_%d" % i
		var rarity := str(choice.get("rarity", "common"))
		var category := str(choice.get("category", "Item"))
		var cost := int(choice.get("cost", 0))
		var matching_tags := _matching_tags(choice, build_tags)
		var disabled_reason := _shop_disabled_reason(cost, gold)
		var comparison := _weapon_comparison_text(choice, weapon_context)
		var recommendation := _shop_recommendation_text(matching_tags)
		var fit_score := _choice_fit_score(
			choice, matching_tags, recommendation, "", disabled_reason, comparison, "")
		var fit_reasons := _choice_fit_reasons(
			choice, matching_tags, recommendation, "", disabled_reason, comparison, "")
		var best_fit := i == best_fit_index
		var context := _shop_choice_context(
			choice, i, choices.size(), rarity, category, cost,
			matching_tags, recommendation, comparison, fit_score, fit_reasons, best_fit, disabled_reason)
		button.text = "Choice %d/%d | %s%s\n%s | %d gold%s" % [
			i + 1,
			choices.size(),
			_rarity_label(rarity),
			choice.get("name", "?"),
			category,
			cost,
			_tag_preview(choice) + _build_match_preview(matching_tags) \
				+ _shop_recommendation_preview(recommendation) \
				+ _weapon_comparison_preview(comparison) \
				+ _fit_score_preview(fit_score, fit_reasons, best_fit) \
				+ _disabled_preview(disabled_reason),
		]
		_prepare_choice_button(button)
		button.set_meta("rarity", rarity)
		button.set_meta("category", category)
		button.set_meta("tags", _choice_tags(choice))
		button.set_meta("build_match", not matching_tags.is_empty())
		button.set_meta("build_match_tags", matching_tags)
		button.set_meta("recommended", recommendation != "")
		button.set_meta("recommendation", recommendation)
		button.set_meta("weapon_comparison", comparison)
		button.set_meta("fit_score", fit_score)
		button.set_meta("fit_reasons", _fit_reasons_text(fit_reasons))
		button.set_meta("best_fit", best_fit)
		button.set_meta("disabled_reason", disabled_reason)
		button.set_meta("choice_index", i)
		button.set_meta("choice_display_index", i + 1)
		button.set_meta("choice_count", choices.size())
		_set_choice_input_meta(
			button,
			"shop_choose",
			str(i + 1),
			_choice_hotkey_for_index(i),
			"Choose shop item %d" % [i + 1])
		button.set_meta("item_name", str(context.get("item_name", "")))
		button.set_meta("cost", cost)
		_apply_choice_icon(button, _shop_icon_sprite_name(choice))
		button.modulate = _rarity_colors.get(rarity, Color.WHITE)
		button.disabled = disabled_reason != ""
		_set_shop_choice_tooltip(button, context)
		button.pressed.connect(_on_shop_choice_button_pressed.bind(i, context))
		_choice_box.add_child(button)
		_shop_hotkey_indices.append(i)
		_shop_hotkey_disabled.append(button.disabled)
		_shop_choice_contexts.append(context)
		_shop_choice_buttons.append(button)
	var leave := Button.new()
	leave.name = "ShopLeave"
	leave.text = "Leave"
	leave.custom_minimum_size = Vector2(360, 28)
	_set_choice_input_meta(leave, "shop_leave", "L", KEY_L, "Leave shop", KEY_ESCAPE)
	leave.pressed.connect(_on_shop_choice_button_pressed.bind(-1, {
		"choice_count": choices.size(),
	}))
	_choice_box.add_child(leave)
	_set_controller_selection("shop", _first_enabled_index(_shop_hotkey_disabled))
	visible = true

func show_pause_menu(
		floor_index: int,
		biome_label: String,
		build_summary: String,
		history_summary: String = "None",
		tag_summary: String = "None",
		run_snapshot: String = "",
		rune_socket_summary: String = "",
		build_archetype: String = "",
		run_power_arc: String = "",
		power_milestones: String = "",
		room_mastery_summary: String = "",
		release_audit_summary: String = "",
		public_release_decision: String = "",
		replace_before_public_count: int = -1,
		daily_fingerprint: Dictionary = {},
) -> void:
	_clear_choices()
	_overlay_mode = "pause"
	_title.text = "PAUSED"
	_subtitle.text = "Floor %d: %s" % [floor_index, biome_label]
	var build := Label.new()
	build.name = "PauseBuildSummary"
	build.text = "Build: %s" % (build_summary if build_summary != "" else "None")
	build.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	build.add_theme_font_size_override("font_size", 10)
	_choice_box.add_child(build)
	var tags := Label.new()
	tags.name = "PauseBuildTags"
	tags.text = "Tags: %s" % (tag_summary if tag_summary != "" else "None")
	tags.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tags.add_theme_font_size_override("font_size", 9)
	_choice_box.add_child(tags)
	if build_archetype != "":
		var archetype := Label.new()
		archetype.name = "PauseBuildArchetype"
		archetype.text = "Archetype: %s" % build_archetype
		archetype.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		archetype.add_theme_font_size_override("font_size", 9)
		archetype.add_theme_color_override("font_color", Color(0.78, 0.96, 1.0))
		_choice_box.add_child(archetype)
	if run_power_arc != "" and run_power_arc != "None":
		var power_arc := Label.new()
		power_arc.name = "PausePowerArcSummary"
		power_arc.text = "Power Arc: %s" % run_power_arc
		power_arc.set_meta("run_power_arc", run_power_arc)
		power_arc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		power_arc.add_theme_font_size_override("font_size", 9)
		power_arc.add_theme_color_override("font_color", Color(0.76, 1.0, 0.72))
		_choice_box.add_child(power_arc)
	if power_milestones != "" and power_milestones != "None":
		var milestones := Label.new()
		milestones.name = "PausePowerMilestones"
		milestones.text = "Power Milestones: %s" % power_milestones
		milestones.set_meta("power_milestones", power_milestones)
		milestones.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		milestones.add_theme_font_size_override("font_size", 9)
		milestones.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52))
		_choice_box.add_child(milestones)
	if room_mastery_summary != "" and room_mastery_summary != "None":
		var mastery := Label.new()
		mastery.name = "PauseRoomMasterySummary"
		mastery.text = "Mastery: %s" % room_mastery_summary
		mastery.set_meta("room_mastery_summary", room_mastery_summary)
		mastery.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mastery.add_theme_font_size_override("font_size", 9)
		mastery.add_theme_color_override("font_color", Color(0.9, 0.86, 1.0))
		_choice_box.add_child(mastery)
	var rune_socket := Label.new()
	rune_socket.name = "PauseRuneSocketSummary"
	rune_socket.text = "Sockets: %s" % (rune_socket_summary if rune_socket_summary != "" else "None")
	rune_socket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rune_socket.add_theme_font_size_override("font_size", 9)
	rune_socket.add_theme_color_override("font_color", Color(0.9, 0.82, 0.58))
	_choice_box.add_child(rune_socket)
	var history := Label.new()
	history.name = "PauseBuildHistory"
	var history_text := history_summary if history_summary != "" else "None"
	history.text = _pause_history_text(history_text)
	history.set_meta("full_history", history_text)
	history.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	history.add_theme_font_size_override("font_size", 9)
	_choice_box.add_child(history)
	var snapshot := Label.new()
	snapshot.name = "PauseRunSnapshotLabel"
	snapshot.text = run_snapshot
	snapshot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	snapshot.add_theme_font_size_override("font_size", 9)
	snapshot.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0))
	_choice_box.add_child(snapshot)
	var daily_fingerprint_text := _daily_fingerprint_text(daily_fingerprint)
	if daily_fingerprint_text != "":
		var daily := Label.new()
		daily.name = "PauseDailySeedFingerprint"
		daily.text = daily_fingerprint_text
		daily.set_meta("daily_fingerprint_hash", str(daily_fingerprint.get("hash", "")).strip_edges())
		daily.set_meta("daily_fingerprint_floor", int(daily_fingerprint.get("floor_index", 0)))
		daily.set_meta("daily_fingerprint_room_count", int(daily_fingerprint.get("room_count", 0)))
		daily.set_meta("daily_fingerprint_spawn_count", int(daily_fingerprint.get("spawn_count", 0)))
		daily.set_meta("daily_fingerprint_boss_variant",
			str(daily_fingerprint.get("boss_variant", "")).strip_edges())
		daily.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		daily.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		daily.add_theme_font_size_override("font_size", 8)
		daily.add_theme_color_override("font_color", Color(0.66, 1.0, 0.96))
		_choice_box.add_child(daily)
	var audit_report := ReleaseAuditScript.runtime_report()
	var audit_summary := release_audit_summary if release_audit_summary != "" \
		else ReleaseAuditScript.summary_text()
	var audit_decision := public_release_decision if public_release_decision != "" \
		else str(audit_report.get("decision", "blocked"))
	var replacement_count := replace_before_public_count if replace_before_public_count >= 0 \
		else Array(audit_report.get("replace_before_public", [])).size()
	var release_audit := Label.new()
	release_audit.name = "PauseReleaseAuditSummary"
	release_audit.text = "Release Audit: %s" % audit_summary
	release_audit.set_meta("public_release_decision", audit_decision)
	release_audit.set_meta("replace_before_public_count", replacement_count)
	release_audit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	release_audit.add_theme_font_size_override("font_size", 8)
	release_audit.add_theme_color_override("font_color", Color(1.0, 0.78, 0.48))
	_choice_box.add_child(release_audit)
	var release_backlog := Label.new()
	release_backlog.name = "PauseReleaseBacklogSummary"
	release_backlog.text = ReleaseAuditScript.replacement_backlog_summary(3)
	release_backlog.set_meta("replacement_backlog_count",
		ReleaseAuditScript.replacement_backlog().size())
	release_backlog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	release_backlog.add_theme_font_size_override("font_size", 8)
	release_backlog.add_theme_color_override("font_color", Color(1.0, 0.66, 0.38))
	_choice_box.add_child(release_backlog)
	var release_next := Label.new()
	release_next.name = "PauseReleaseNextAction"
	var next_action := ReleaseAuditScript.next_release_action()
	release_next.text = next_action
	release_next.set_meta("release_next_action", next_action)
	release_next.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	release_next.add_theme_font_size_override("font_size", 8)
	release_next.add_theme_color_override("font_color", Color(0.82, 1.0, 0.7))
	_choice_box.add_child(release_next)
	var playtest_objective := Label.new()
	playtest_objective.name = "PausePlaytestObjective"
	var objective := ReleaseAuditScript.playtest_objective_summary()
	playtest_objective.text = objective
	playtest_objective.set_meta("playtest_objective", objective)
	playtest_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	playtest_objective.add_theme_font_size_override("font_size", 8)
	playtest_objective.add_theme_color_override("font_color", Color(0.74, 0.9, 1.0))
	_choice_box.add_child(playtest_objective)
	var tuning_patch := Label.new()
	tuning_patch.name = "PauseTuningPatchPreview"
	var patch := ReleaseAuditScript.tuning_patch_summary()
	tuning_patch.text = patch
	tuning_patch.set_meta("tuning_patch", patch)
	tuning_patch.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tuning_patch.add_theme_font_size_override("font_size", 8)
	tuning_patch.add_theme_color_override("font_color", Color(0.92, 0.86, 1.0))
	_choice_box.add_child(tuning_patch)
	_add_pause_accessibility_settings()
	var resume := Button.new()
	resume.name = "PauseResume"
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(220, 34)
	resume.pressed.connect(func() -> void:
		_emit_resume_requested())
	_choice_box.add_child(resume)
	var restart := Button.new()
	restart.name = "PauseRestart"
	restart.text = "Restart Run"
	restart.custom_minimum_size = Vector2(220, 34)
	restart.pressed.connect(func() -> void:
		_emit_restart_requested())
	_choice_box.add_child(restart)
	var class_select := Button.new()
	class_select.name = "PauseClassSelect"
	class_select.text = "Class Select"
	class_select.custom_minimum_size = Vector2(220, 34)
	class_select.pressed.connect(func() -> void:
		_emit_class_select_requested())
	_choice_box.add_child(class_select)
	visible = true

func apply_accessibility_settings(settings: Dictionary) -> void:
	_accessibility_settings = _normalized_accessibility_settings(settings)
	set_meta("accessibility_settings", _accessibility_settings.duplicate(true))
	_update_pause_settings_summary()

func _add_pause_accessibility_settings() -> void:
	_pause_settings_label = Label.new()
	_pause_settings_label.name = "PauseAccessibilitySettings"
	_pause_settings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_settings_label.add_theme_font_size_override("font_size", 8)
	_pause_settings_label.add_theme_color_override("font_color", Color(0.76, 0.96, 1.0))
	_choice_box.add_child(_pause_settings_label)
	var row := HBoxContainer.new()
	row.name = "PauseAccessibilitySettingsControls"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_box.add_child(row)
	row.add_child(_settings_button("PauseVolumeDown", "Vol-", "Lower master volume",
		func() -> void:
			_accessibility_settings["master_volume"] = clampf(
				float(_accessibility_settings.get("master_volume", 1.0)) - 0.1, 0.0, 1.0)
			_emit_settings_changed()))
	row.add_child(_settings_button("PauseVolumeUp", "Vol+", "Raise master volume",
		func() -> void:
			_accessibility_settings["master_volume"] = clampf(
				float(_accessibility_settings.get("master_volume", 1.0)) + 0.1, 0.0, 1.0)
			_emit_settings_changed()))
	row.add_child(_settings_button("PauseToggleFlash", "Flash", "Toggle damage flash",
		func() -> void:
			var enabled := not bool(_accessibility_settings.get("damage_flash_enabled", true))
			_accessibility_settings["damage_flash_enabled"] = enabled
			_accessibility_settings["damage_vignette_enabled"] = enabled
			_emit_settings_changed()))
	row.add_child(_settings_button("PauseToggleShake", "Shake", "Toggle camera impact shake",
		func() -> void:
			_accessibility_settings["screen_shake_scale"] = 0.0 \
				if float(_accessibility_settings.get("screen_shake_scale", 1.0)) > 0.0 else 1.0
			_emit_settings_changed()))
	row.add_child(_settings_button("PauseToggleContrast", "Contrast", "Toggle high contrast cues",
		func() -> void:
			_accessibility_settings["high_contrast_cues"] = not bool(
				_accessibility_settings.get("high_contrast_cues", false))
			_emit_settings_changed()))
	_update_pause_settings_summary()

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
	_accessibility_settings = _normalized_accessibility_settings(_accessibility_settings)
	set_meta("accessibility_settings", _accessibility_settings.duplicate(true))
	_update_pause_settings_summary()
	settings_changed.emit(_accessibility_settings.duplicate(true))

func _update_pause_settings_summary() -> void:
	if _pause_settings_label == null:
		return
	_pause_settings_label.text = _accessibility_settings_summary(_accessibility_settings)
	_pause_settings_label.set_meta("accessibility_settings", _accessibility_settings.duplicate(true))

func _normalized_accessibility_settings(settings: Dictionary) -> Dictionary:
	return {
		"master_volume": clampf(float(settings.get("master_volume", 1.0)), 0.0, 1.0),
		"damage_flash_enabled": bool(settings.get("damage_flash_enabled", true)),
		"damage_vignette_enabled": bool(settings.get("damage_vignette_enabled",
			settings.get("damage_flash_enabled", true))),
		"screen_shake_scale": clampf(float(settings.get("screen_shake_scale", 1.0)), 0.0, 1.0),
		"hit_pause_scale": clampf(float(settings.get("hit_pause_scale", 1.0)), 0.0, 1.0),
		"high_contrast_cues": bool(settings.get("high_contrast_cues", false)),
	}

func _accessibility_settings_summary(settings: Dictionary) -> String:
	return "Settings: Vol %d%% | Flash %s | Shake %s | Contrast %s" % [
		roundi(float(settings.get("master_volume", 1.0)) * 100.0),
		"On" if bool(settings.get("damage_flash_enabled", true)) else "Off",
		"On" if float(settings.get("screen_shake_scale", 1.0)) > 0.0 else "Off",
		"High" if bool(settings.get("high_contrast_cues", false)) else "Std",
	]

func _emit_resume_requested() -> void:
	_play_overlay_action_sfx("resume")
	resume_requested.emit()

func _emit_restart_requested() -> void:
	_play_overlay_action_sfx("restart")
	restart_requested.emit()

func _emit_class_select_requested() -> void:
	_play_overlay_action_sfx("class_select")
	class_select_requested.emit()

func _play_overlay_action_sfx(action: String) -> void:
	var cue: Dictionary = AudioCueDBScript.overlay_action_cue(action)
	var sfx := get_node_or_null("OverlayActionSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "OverlayActionSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("overlay_action", action)
	sfx.set_meta("overlay_sound_id", str(cue.get("id", "overlay_resume")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "overlay_action")))
	sfx.set_meta("overlay_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _play_run_end_sfx(title: String) -> void:
	var cue: Dictionary = AudioCueDBScript.run_end_cue(title)
	var sfx := get_node_or_null("RunEndSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "RunEndSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("run_end_title", title)
	sfx.set_meta("run_end_result", str(cue.get("result", "defeat")))
	sfx.set_meta("run_end_sound_id", str(cue.get("id", "run_defeat")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "run_end")))
	sfx.set_meta("run_end_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _on_upgrade_button_pressed(id: String, context: Dictionary = {}) -> void:
	set_meta("last_reward_decision_upgrade_id", id)
	set_meta("last_reward_decision_context", context.duplicate(true))
	set_meta("last_reward_decision_reason", _reward_decision_reason_text(context))
	_play_reward_decision_sfx("choose", id, context)
	upgrade_chosen.emit(id)

func _reward_decision_reason_text(context: Dictionary) -> String:
	var parts: Array[String] = []
	var reasons := _fit_reasons_text(context.get("fit_reasons", []))
	if reasons != "" and reasons != "Baseline":
		parts.append(reasons)
	var synergy := str(context.get("synergy_reason", "")).strip_edges()
	if synergy != "":
		parts.append(synergy)
	var recommendation := str(context.get("recommendation", "")).strip_edges()
	if recommendation != "":
		parts.append(recommendation)
	var preview := str(context.get("effect_preview", "")).strip_edges()
	if preview != "":
		parts.append("Preview")
	if bool(context.get("best_fit", false)):
		parts.append("Best Fit")
	return _fit_reasons_text(parts)

func _pause_history_text(history_summary: String, max_visible: int = 6) -> String:
	if history_summary == "" or history_summary == "None":
		return "History: None"
	var parts := history_summary.split(" -> ", false)
	if parts.size() <= max_visible:
		return "History: %s" % history_summary
	var recent := parts.slice(parts.size() - max_visible)
	return "Recent %d/%d: %s" % [max_visible, parts.size(), " -> ".join(recent)]

func _daily_fingerprint_text(daily_fingerprint: Dictionary) -> String:
	var hash_text := str(daily_fingerprint.get("hash", "")).strip_edges()
	if hash_text == "":
		return ""
	var parts: Array[String] = ["Hash %s" % hash_text]
	var floor_index := int(daily_fingerprint.get("floor_index", 0))
	if floor_index > 0:
		parts.append("Floor %d" % floor_index)
	var room_count := int(daily_fingerprint.get("room_count", 0))
	if room_count > 0:
		parts.append("Rooms %d" % room_count)
	var spawn_count := int(daily_fingerprint.get("spawn_count", 0))
	if spawn_count > 0:
		parts.append("Spawns %d" % spawn_count)
	var boss_variant := str(daily_fingerprint.get("boss_variant", "")).strip_edges()
	if boss_variant != "":
		parts.append("Boss %s" % boss_variant)
	return "Daily Fingerprint: %s" % " | ".join(parts)

func _last_pick_text(history_summary: String) -> String:
	if history_summary == "" or history_summary == "None":
		return ""
	var parts := history_summary.split(" -> ", false)
	if parts.is_empty():
		return ""
	return str(parts[parts.size() - 1])

func _on_upgrade_skip_pressed() -> void:
	_play_reward_decision_sfx("skip")
	reward_skipped.emit(UPGRADE_SKIP_GOLD)

func _on_upgrade_reroll_pressed() -> void:
	_play_reward_decision_sfx("reroll")
	reward_reroll_requested.emit(UPGRADE_REROLL_COST)

func _play_reward_decision_sfx(
		decision: String,
		upgrade_id: String = "",
		context: Dictionary = {},
) -> void:
	var cue: Dictionary = AudioCueDBScript.reward_decision_cue(decision)
	var sfx := get_node_or_null("RewardDecisionSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "RewardDecisionSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("reward_decision", decision)
	sfx.set_meta("reward_upgrade_id", upgrade_id)
	sfx.set_meta("reward_sound_id", str(cue.get("id", "reward_choose")))
	sfx.set_meta("reward_choice_index", int(context.get("choice_index", 0)))
	sfx.set_meta("reward_choice_count", int(context.get("choice_count", 0)))
	sfx.set_meta("reward_choice_rarity", str(context.get("rarity", "")))
	sfx.set_meta("reward_choice_tags", _readable_tags(context.get("tags", [])))
	sfx.set_meta("reward_build_match_tags", _readable_tags(context.get("build_match_tags", [])))
	sfx.set_meta("reward_synergy_reason", str(context.get("synergy_reason", "")))
	sfx.set_meta("reward_recommendation", str(context.get("recommendation", "")))
	sfx.set_meta("reward_effect_preview", str(context.get("effect_preview", "")))
	sfx.set_meta("reward_set_progress_hint", str(context.get("set_progress_hint", "")))
	sfx.set_meta("reward_set_progress_tag", str(context.get("set_progress_tag", "")))
	sfx.set_meta("reward_set_bonus_effect", str(context.get("set_bonus_effect", "")))
	sfx.set_meta("reward_set_bonus_next_effect", str(context.get("set_bonus_next_effect", "")))
	sfx.set_meta("reward_fit_score", int(context.get("fit_score", 0)))
	sfx.set_meta("reward_fit_reasons", _fit_reasons_text(context.get("fit_reasons", [])))
	sfx.set_meta("reward_best_fit", bool(context.get("best_fit", false)))
	sfx.set_meta("reward_socket_context", str(context.get("socket_context", "")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "reward_decision")))
	sfx.set_meta("reward_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _on_shop_choice_button_pressed(index: int, context: Dictionary = {}) -> void:
	set_meta("last_shop_decision_index", index)
	set_meta("last_shop_decision_context", context.duplicate(true))
	set_meta("last_shop_decision_reason",
		"Left shop" if index < 0 else _shop_decision_reason_text(context))
	_play_shop_decision_sfx("leave" if index < 0 else "buy", index, context)
	shop_choice_chosen.emit(index)

func _shop_decision_reason_text(context: Dictionary) -> String:
	var parts: Array[String] = []
	var reasons := _fit_reasons_text(context.get("fit_reasons", []))
	if reasons != "" and reasons != "Baseline":
		parts.append(reasons)
	var recommendation := str(context.get("recommendation", "")).strip_edges()
	if recommendation != "":
		parts.append(recommendation)
	var comparison := str(context.get("weapon_comparison", "")).strip_edges()
	if comparison != "":
		parts.append("Weapon compare")
	if bool(context.get("best_fit", false)):
		parts.append("Best Fit")
	return _fit_reasons_text(parts)

func _play_shop_decision_sfx(decision: String, index: int, context: Dictionary = {}) -> void:
	var cue: Dictionary = AudioCueDBScript.shop_decision_cue(decision)
	var sfx := get_node_or_null("ShopDecisionSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "ShopDecisionSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("shop_decision", decision)
	sfx.set_meta("shop_choice_index", index)
	sfx.set_meta("shop_choice_display_index", int(context.get(
		"choice_display_index", index + 1 if index >= 0 else 0)))
	sfx.set_meta("shop_choice_count", int(context.get("choice_count", 0)))
	sfx.set_meta("shop_item_name", str(context.get("item_name", "")))
	sfx.set_meta("shop_cost", int(context.get("cost", 0)))
	sfx.set_meta("shop_choice_rarity", str(context.get("rarity", "")))
	sfx.set_meta("shop_choice_category", str(context.get("category", "")))
	sfx.set_meta("shop_choice_tags", _readable_tags(context.get("tags", [])))
	sfx.set_meta("shop_build_match_tags", _readable_tags(context.get("build_match_tags", [])))
	sfx.set_meta("shop_recommendation", str(context.get("recommendation", "")))
	sfx.set_meta("shop_weapon_comparison", str(context.get("weapon_comparison", "")))
	sfx.set_meta("shop_fit_score", int(context.get("fit_score", 0)))
	sfx.set_meta("shop_fit_reasons", _fit_reasons_text(context.get("fit_reasons", [])))
	sfx.set_meta("shop_best_fit", bool(context.get("best_fit", false)))
	sfx.set_meta("shop_reward_type", str(context.get("reward_type", "")))
	sfx.set_meta("shop_reward_id", str(context.get("reward_id", "")))
	sfx.set_meta("shop_sound_id", str(cue.get("id", "shop_buy")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "shop_decision")))
	sfx.set_meta("shop_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _shop_choice_context(
		choice: Dictionary,
		index: int,
		count: int,
		rarity: String,
		category: String,
		cost: int,
		matching_tags: Array,
		recommendation: String,
		comparison: String,
		fit_score: int = 0,
		fit_reasons: Array = [],
		best_fit: bool = false,
		disabled_reason: String = "",
) -> Dictionary:
	var reward: Dictionary = {}
	var raw_reward: Variant = choice.get("reward", {})
	if raw_reward is Dictionary:
		reward = raw_reward as Dictionary
	return {
		"choice_index": index,
		"choice_display_index": index + 1,
		"choice_count": count,
		"item_name": str(choice.get("name", "?")),
		"cost": cost,
		"rarity": rarity,
		"category": category,
		"tags": _choice_tags(choice),
		"build_match_tags": matching_tags,
		"recommendation": recommendation,
		"weapon_comparison": comparison,
		"fit_score": fit_score,
		"fit_reasons": fit_reasons,
		"best_fit": best_fit,
		"disabled_reason": disabled_reason,
		"reward_type": str(reward.get("type", "")),
		"reward_id": str(reward.get("id", "")),
	}

func hide_overlay() -> void:
	visible = false
	_clear_choices()

func _rarity_label(rarity: String) -> String:
	if rarity == "common":
		return ""
	return "[%s] " % rarity.to_upper()

func _stack_preview(choice_or_id, stack_counts: Dictionary) -> String:
	var upgrade_id := str(choice_or_id.get("id", "") if choice_or_id is Dictionary else choice_or_id)
	var max_stack := int(choice_or_id.get("max_stack", 0)) if choice_or_id is Dictionary else 0
	var current := int(stack_counts.get(upgrade_id, 0))
	if current <= 0:
		return ""
	if max_stack > 0 and current >= max_stack:
		return "\nOwned x%d/%d | MAX" % [current, max_stack]
	return "\nOwned x%d | Next x%d" % [current, current + 1]

func _is_upgrade_maxed(choice: Dictionary, stack_counts: Dictionary) -> bool:
	var max_stack := int(choice.get("max_stack", 0))
	if max_stack <= 0:
		return false
	return int(stack_counts.get(str(choice.get("id", "")), 0)) >= max_stack

func _upgrade_disabled_reason(choice: Dictionary, stack_counts: Dictionary) -> String:
	var explicit := str(choice.get("disabled_reason", ""))
	if explicit != "":
		return explicit
	return "Max stack" if _is_upgrade_maxed(choice, stack_counts) else ""

func _disabled_preview(reason: String) -> String:
	return "" if reason == "" else "\nUnavailable: %s" % reason

func _choice_button_size(text: String) -> Vector2:
	var line_count := text.split("\n", false).size()
	return Vector2(360, maxf(42.0, 18.0 + float(line_count) * 14.0))

func _prepare_choice_button(button: Button) -> void:
	button.custom_minimum_size = _choice_button_size(button.text)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = false

func _shop_disabled_reason(cost: int, gold: int) -> String:
	if cost <= gold:
		return ""
	return "Need %d gold" % (cost - gold)

func _tag_preview(choice: Dictionary) -> String:
	var text := _readable_tags(_choice_tags(choice))
	return "" if text == "" else "\nTags: %s" % text

func _effect_preview(text: String) -> String:
	return "" if text == "" else "\nPreview: %s" % text

func _build_match_preview(tags: Array, build_archetype: String = "") -> String:
	var reason := _build_match_reason(tags, build_archetype)
	return "" if reason == "" else "\nSynergy: %s" % reason

func _build_match_reason(tags: Array, build_archetype: String = "") -> String:
	var text := _readable_tags(tags)
	if text == "":
		return ""
	var archetype := build_archetype.strip_edges()
	if archetype == "":
		return text
	return "%s | Fits %s" % [text, archetype]

func _upgrade_recommendation_preview(text: String) -> String:
	return "" if text == "" else "\nRecommended: %s" % text

func _set_progress_preview(progress: Dictionary) -> String:
	var hint := str(progress.get("set_progress_hint", "")).strip_edges()
	if hint == "":
		return ""
	var effect := str(progress.get("set_bonus_effect", "")).strip_edges()
	var next_effect := str(progress.get("set_bonus_next_effect", "")).strip_edges()
	return "\nSet: %s%s%s" % [
		hint,
		"\nBonus: %s" % effect if effect != "" else "",
		"\nNext: %s" % next_effect if next_effect != "" else "",
	]

func _choice_set_progress(choice: Dictionary, tag_stack_counts: Dictionary) -> Dictionary:
	if tag_stack_counts.is_empty():
		return {}
	var choice_tags := _choice_tags(choice)
	var best_tag := ""
	var best_count := 0
	for tag in ["damage", "mobility", "element", "pet", "shield", "projectile", "socket"]:
		if not choice_tags.has(tag):
			continue
		var count := int(tag_stack_counts.get(tag, 0))
		if count > best_count:
			best_count = count
			best_tag = tag
	if best_tag == "" or best_count <= 0:
		return {}
	var after := best_count + 1
	var ready := best_count < 3 and after >= 3
	var hint := "%s %d/3 -> %d/3%s" % [
		best_tag.replace("_", " ").capitalize(),
		best_count,
		mini(after, 3),
		" ready" if ready else "",
	]
	return {
		"set_progress_hint": hint,
		"set_progress_tag": best_tag,
		"set_progress_before": best_count,
		"set_progress_after": after,
		"set_progress_ready": ready,
		"set_bonus_effect": _set_bonus_effect_text(best_tag) if ready else "",
		"set_bonus_next_effect": _set_bonus_effect_text(best_tag) if not ready and after == 2 else "",
	}

func _set_bonus_effect_text(tag: String) -> String:
	match tag:
		"damage":
			return "Damage x3 +8% dmg"
		"mobility":
			return "Mobility x3 -8% dash CD"
		"element":
			return "Element x3 +6% elem dmg"
		"pet":
			return "Pet x3 +12% pet dmg"
		"shield":
			return "Shield x3 +10% shield dur"
		"projectile":
			return "Projectile x3 +1 projectile"
	return ""

func _apply_set_progress_meta(button: Button, progress: Dictionary) -> void:
	for key in [
		"set_progress_hint",
		"set_progress_tag",
		"set_progress_before",
		"set_progress_after",
		"set_progress_ready",
		"set_bonus_effect",
		"set_bonus_next_effect",
	]:
		button.set_meta(key, progress.get(key,
			"" if key.ends_with("hint") or key.ends_with("tag") or key.begins_with("set_bonus_") else 0))

func _upgrade_recommendation_text(
		choice: Dictionary,
		matching_tags: Array,
		build_archetype: String = "",
) -> String:
	var match_text := _readable_tags(matching_tags)
	if match_text != "":
		var archetype := build_archetype.strip_edges()
		return "Build fit: %s" % (archetype if archetype != "" else match_text)
	if str(choice.get("rarity", "common")) == "epic":
		return "High-impact upgrade"
	return ""

func _socket_context_preview(text: String) -> String:
	return "" if text == "" else "\nSocket Plan: %s" % text

func _shop_recommendation_preview(text: String) -> String:
	return "" if text == "" else "\nRecommended: %s" % text

func _weapon_comparison_preview(text: String) -> String:
	return "" if text == "" else "\n%s" % text

func _fit_score_preview(score: int, reasons: Array, best_fit: bool = false) -> String:
	var text := "\nFit: %d%% | %s" % [clampi(score, 0, 100), _fit_reasons_text(reasons)]
	return "%s\nBest Fit" % text if best_fit else text

func _best_upgrade_fit_index(
		choices: Array,
		build_tags: Array,
		stack_counts: Dictionary,
		effect_previews: Dictionary,
		rune_socket_summary: String,
		build_archetype: String,
		tag_stack_counts: Dictionary = {},
) -> int:
	var best_index := -1
	var best_score := -1
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var id := str(choice.get("id", ""))
		var matching_tags := _matching_tags(choice, build_tags)
		var disabled_reason := _upgrade_disabled_reason(choice, stack_counts)
		if disabled_reason != "" or bool(choice.get("disabled", false)):
			continue
		var effect_preview := str(effect_previews.get(id, ""))
		var socket_context := rune_socket_summary if _choice_tags(choice).has("socket") else ""
		var recommendation := _upgrade_recommendation_text(choice, matching_tags, build_archetype)
		var set_progress := _choice_set_progress(choice, tag_stack_counts)
		var score := _choice_fit_score(
			choice, matching_tags, recommendation, effect_preview, disabled_reason,
			"", socket_context, set_progress)
		if score > best_score:
			best_score = score
			best_index = i
	return best_index

func _best_shop_fit_index(
		choices: Array,
		gold: int,
		build_tags: Array,
		weapon_context: Dictionary,
) -> int:
	var best_index := -1
	var best_score := -1
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var matching_tags := _matching_tags(choice, build_tags)
		var disabled_reason := _shop_disabled_reason(int(choice.get("cost", 0)), gold)
		if disabled_reason != "":
			continue
		var comparison := _weapon_comparison_text(choice, weapon_context)
		var recommendation := _shop_recommendation_text(matching_tags)
		var score := _choice_fit_score(
			choice, matching_tags, recommendation, "", disabled_reason, comparison, "")
		if score > best_score:
			best_score = score
			best_index = i
	return best_index

func _fit_reasons_text(reasons) -> String:
	var raw: Array = reasons if reasons is Array else [reasons]
	var out: Array[String] = []
	var seen := {}
	for reason in raw:
		var text := str(reason).strip_edges()
		if text == "" or seen.has(text):
			continue
		seen[text] = true
		out.append(text)
	return "Baseline" if out.is_empty() else " / ".join(out)

func _choice_fit_score(
		choice: Dictionary,
		matching_tags: Array,
		recommendation: String,
		effect_preview: String,
		disabled_reason: String = "",
		comparison: String = "",
		socket_context: String = "",
		set_progress: Dictionary = {},
) -> int:
	var score := 35
	score += mini(matching_tags.size(), 2) * 18
	if recommendation.strip_edges() != "":
		score += 10
	score += _rarity_fit_bonus(str(choice.get("rarity", "common")))
	if effect_preview.strip_edges() != "":
		score += 5
	if comparison.strip_edges() != "":
		score += 5
	if socket_context.strip_edges() != "":
		score += 5
	if bool(set_progress.get("set_progress_ready", false)):
		score += 16
	elif str(set_progress.get("set_progress_hint", "")).strip_edges() != "":
		score += 6
	if disabled_reason.strip_edges() != "":
		score -= 45
	return clampi(score, 0, 100)

func _choice_fit_reasons(
		choice: Dictionary,
		matching_tags: Array,
		recommendation: String,
		effect_preview: String,
		disabled_reason: String = "",
		comparison: String = "",
		socket_context: String = "",
		set_progress: Dictionary = {},
) -> Array[String]:
	var reasons: Array[String] = []
	if disabled_reason.strip_edges() != "":
		reasons.append("Blocked")
	if not matching_tags.is_empty():
		reasons.append("Build match")
	var rarity := str(choice.get("rarity", "common"))
	if rarity != "common":
		reasons.append(rarity.capitalize())
	if effect_preview.strip_edges() != "":
		reasons.append("Preview")
	if comparison.strip_edges() != "":
		reasons.append("Weapon compare")
	if socket_context.strip_edges() != "":
		reasons.append("Socket plan")
	if bool(set_progress.get("set_progress_ready", false)):
		reasons.append("Set ready")
	elif str(set_progress.get("set_progress_hint", "")).strip_edges() != "":
		reasons.append("Set progress")
	if recommendation.strip_edges() != "" and matching_tags.is_empty():
		reasons.append("Recommended")
	if reasons.is_empty():
		reasons.append("Baseline")
	return reasons

func _rarity_fit_bonus(rarity: String) -> int:
	match rarity:
		"uncommon":
			return 4
		"rare":
			return 8
		"epic":
			return 12
		"legendary":
			return 16
		"mythic":
			return 20
	return 0

func _shop_recommendation_text(tags: Array) -> String:
	var filtered: Array[String] = []
	for raw_tag in tags:
		var tag := str(raw_tag)
		if ["weapon", "common", "uncommon", "rare", "epic", "legendary", "mythic"].has(tag):
			continue
		filtered.append(tag)
	var readable := _readable_tags(filtered if not filtered.is_empty() else tags)
	return readable

func _weapon_comparison_text(choice: Dictionary, weapon_context: Dictionary) -> String:
	var reward: Dictionary = choice.get("reward", {})
	if str(reward.get("type", "")) != "weapon":
		return ""
	var new_weapon := WeaponDB.get_weapon(str(reward.get("id", "")))
	if new_weapon.is_empty() or weapon_context.is_empty():
		return ""
	var current_id := str(weapon_context.get("id", ""))
	var current_weapon := WeaponDB.get_weapon(current_id) if current_id != "" else weapon_context
	if current_weapon.is_empty():
		current_weapon = weapon_context
	var current_name := str(weapon_context.get("name", current_weapon.get("name", "Current")))
	var parts: Array[String] = []
	parts.append("Dmg %s" % _signed_delta(int(new_weapon.get("dmg", 0)) - int(current_weapon.get("dmg", 0))))
	parts.append("Speed %s" % _signed_delta(int(new_weapon.get("speed", 0)) - int(current_weapon.get("speed", 0))))
	parts.append("Range %s" % _signed_delta(int(new_weapon.get("range", 0)) - int(current_weapon.get("range", 0))))
	parts.append("Sockets %s" % _signed_delta(int(new_weapon.get("sockets", 0)) - int(current_weapon.get("sockets", 0))))
	return "Vs %s: %s" % [current_name, " / ".join(parts)]

func _signed_delta(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)

func _readable_tags(tags: Array) -> String:
	var parts: Array[String] = []
	var seen := {}
	for raw_tag in tags:
		var tag := str(raw_tag)
		if tag == "" or seen.has(tag):
			continue
		seen[tag] = true
		parts.append(tag.replace("_", " ").capitalize())
	return "" if parts.is_empty() else " / ".join(parts)

func _matching_tags(choice: Dictionary, build_tags: Array) -> Array[String]:
	var build_tag_set := {}
	for raw_tag in build_tags:
		var tag := str(raw_tag)
		if tag != "":
			build_tag_set[tag] = true
	var out: Array[String] = []
	if build_tag_set.is_empty():
		return out
	for raw_tag in _choice_tags(choice):
		var tag := str(raw_tag)
		if build_tag_set.has(tag) and not out.has(tag):
			out.append(tag)
	return out

func _choice_tags(choice: Dictionary) -> Array:
	var tags: Array = choice.get("tags", [])
	if not tags.is_empty():
		return tags
	var reward: Dictionary = choice.get("reward", {})
	match str(reward.get("type", "")):
		"weapon":
			var out := ["weapon"]
			var weapon := WeaponDB.get_weapon(str(reward.get("id", "")))
			var group := str(weapon.get("group", ""))
			if group != "":
				out.append(group)
			return out
		"potion":
			return ["healing"]
		"gold":
			return ["gold", "economy"]
		"rune_dust":
			return ["rune", "craft"]
		"soul_shards":
			return ["meta", "soul"]
		"blueprints":
			return ["blueprint", "socket"]
	var category := str(choice.get("category", ""))
	return [] if category == "" else [category.to_lower()]

func _apply_choice_icon(button: Button, sprite_name: String) -> void:
	if sprite_name == "":
		return
	var texture := SpriteDB.texture(sprite_name)
	if texture == null:
		return
	button.icon = texture
	button.expand_icon = true
	button.set_meta("icon_sprite_name", sprite_name)

func _upgrade_icon_sprite_name(choice: Dictionary) -> String:
	match str(choice.get("id", "")):
		"vital_core":
			return "flask_big_red"
		"focus_cell":
			return "flask_big_blue"
		"lucky_coin":
			return "coin_anim"
		"ember_rune":
			return "flask_red"
		"frost_rune":
			return "flask_blue"
		"storm_rune":
			return "flask_yellow"
		"venom_rune":
			return "flask_green"
		"split_socket", "power_rune", "precision_lens", "tempo_glove":
			return "weapon_red_gem_sword"
		"aegis_socket":
			return "weapon_knight_sword"
		"familiar_rune":
			return "skull"
	for tag in _choice_tags(choice):
		match str(tag):
			"gold", "economy":
				return "coin_anim"
			"hp", "survival":
				return "flask_big_red"
			"fire":
				return "flask_red"
			"ice":
				return "flask_blue"
			"lightning":
				return "flask_yellow"
			"poison":
				return "flask_green"
	return "weapon_regular_sword"

func _shop_icon_sprite_name(choice: Dictionary) -> String:
	var reward: Dictionary = choice.get("reward", {})
	match str(reward.get("type", "")):
		"potion":
			return "flask_red"
		"gold":
			return "coin_anim"
		"weapon":
			return _weapon_icon_sprite_name(str(reward.get("id", "")))
	return _upgrade_icon_sprite_name(choice)

func _weapon_icon_sprite_name(weapon_id: String) -> String:
	return WeaponDB.preview_sprite_name_for_weapon(weapon_id)

func _clear_choices() -> void:
	_overlay_mode = ""
	_upgrade_hotkey_ids.clear()
	_upgrade_hotkey_disabled.clear()
	_upgrade_hotkey_contexts.clear()
	_upgrade_choice_buttons.clear()
	_upgrade_hotkey_can_reroll = false
	_upgrade_hotkey_reroll_blocked_reason = "Reroll unavailable"
	_shop_hotkey_indices.clear()
	_shop_hotkey_disabled.clear()
	_shop_choice_contexts.clear()
	_shop_choice_buttons.clear()
	_message_choice_buttons.clear()
	_message_choice_disabled.clear()
	_controller_selection_index = -1
	set_meta("controller_selection_mode", "")
	set_meta("controller_selection_index", -1)
	set_meta("controller_selection_label", "")
	if _choice_box == null:
		return
	for child in _choice_box.get_children():
		_choice_box.remove_child(child)
		child.queue_free()
