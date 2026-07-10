class_name DoorMarker
extends Area2D

signal route_choice_requested(choice_index: int)

const REWARD_LOCK_PULSE_SCALE := 1.08
const REWARD_LOCK_PULSE_SECONDS := 0.32
const SECRET_DOOR_CUE := "cracked_wall"
const SECRET_WALL_PATTERN := "cracked_wall_lines"
const CLICK_RECT := Rect2(-24, -10, 48, 20)
const PRESS_PULSE_SCALE := 0.94
const PRESS_PULSE_SECONDS := 0.12

var room_type := RoomNode.RoomType.COMBAT
var route_hint := ""
var gate_state := ""
var next_action_key := ""
var preview_hint := ""
var route_choice_index := 0
var route_choice_input_action := ""
var route_hotkey_label := ""
var _label: Label
var _click_shape: CollisionShape2D
var _pulse_tween: Tween
var _press_tween: Tween

static func label_for_type(type: int) -> String:
	match type:
		RoomNode.RoomType.ENTRANCE:
			return "IN"
		RoomNode.RoomType.COMBAT:
			return "FIGHT"
		RoomNode.RoomType.ELITE:
			return "ELITE"
		RoomNode.RoomType.TREASURE:
			return "LOOT"
		RoomNode.RoomType.SHOP:
			return "SHOP"
		RoomNode.RoomType.SHRINE:
			return "ALTAR"
		RoomNode.RoomType.EVENT:
			return "EVENT"
		RoomNode.RoomType.SECRET:
			return "SECRET"
		RoomNode.RoomType.MINIBOSS:
			return "MINI"
		RoomNode.RoomType.HEAL:
			return "HEAL"
		RoomNode.RoomType.BOSS:
			return "BOSS"
		_:
			return "ROOM"

static func color_for_type(type: int) -> Color:
	match type:
		RoomNode.RoomType.TREASURE:
			return Color(1.0, 0.76, 0.22)
		RoomNode.RoomType.SHOP:
			return Color(0.35, 0.85, 0.95)
		RoomNode.RoomType.SHRINE:
			return Color(0.75, 0.45, 1.0)
		RoomNode.RoomType.HEAL:
			return Color(0.35, 1.0, 0.45)
		RoomNode.RoomType.ELITE, RoomNode.RoomType.MINIBOSS:
			return Color(1.0, 0.45, 0.25)
		RoomNode.RoomType.BOSS:
			return Color(1.0, 0.22, 0.18)
		RoomNode.RoomType.SECRET:
			return Color(0.65, 0.65, 0.7)
		_:
			return Color(0.92, 0.92, 0.82)

static func crack_line_segments() -> Array[PackedVector2Array]:
	return [
		PackedVector2Array([Vector2(-8, -6), Vector2(-2, 0)]),
		PackedVector2Array([Vector2(-2, 0), Vector2(5, -5)]),
		PackedVector2Array([Vector2(-1, 1), Vector2(6, 7)]),
	]

func configure(
		type: int,
		p_route_hint: String = "",
		p_gate_state: String = "",
		p_next_action_key: String = "",
		p_preview_hint: String = "",
		p_route_choice_index: int = 0,
		p_route_choice_input_action: String = "",
) -> void:
	room_type = type
	route_hint = p_route_hint
	gate_state = p_gate_state
	next_action_key = p_next_action_key
	preview_hint = p_preview_hint
	route_choice_index = maxi(p_route_choice_index, 0)
	route_choice_input_action = p_route_choice_input_action
	if route_choice_input_action == "" and route_choice_index > 0:
		route_choice_input_action = "route_choice_%d" % route_choice_index
	route_hotkey_label = str(route_choice_index) if route_choice_index > 0 else ""
	set_meta("gate_state", gate_state)
	set_meta("next_action_key", next_action_key)
	set_meta("route_hint", route_hint)
	set_meta("preview_hint", preview_hint)
	set_meta("route_choice_index", route_choice_index)
	set_meta("route_choice_input_action", route_choice_input_action)
	set_meta("route_hotkey_label", route_hotkey_label)
	set_meta("route_clickable", route_choice_index > 0)
	set_meta("room_type", room_type)
	set_meta("secret_wall", room_type == RoomNode.RoomType.SECRET)
	set_meta("door_cue", SECRET_DOOR_CUE if room_type == RoomNode.RoomType.SECRET else "standard")
	set_meta("secret_wall_pattern", SECRET_WALL_PATTERN if room_type == RoomNode.RoomType.SECRET else "")
	set_meta("crack_line_count", crack_line_segments().size() if room_type == RoomNode.RoomType.SECRET else 0)
	add_to_group("door_markers")
	_ensure_click_shape()
	_apply_label()
	_update_reward_lock_pulse()
	queue_redraw()

func _ready() -> void:
	input_pickable = true
	_ensure_click_shape()
	_label = Label.new()
	_label.name = "Label"
	_label.position = Vector2(-29, -18)
	_label.size = Vector2(58, 20)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 7)
	add_child(_label)
	_apply_label()
	_update_reward_lock_pulse()

func _draw() -> void:
	draw_rect(CLICK_RECT, Color(0.02, 0.02, 0.025, 0.82), true)
	draw_rect(CLICK_RECT, _marker_color(), false, 1.0)
	if room_type == RoomNode.RoomType.SECRET:
		_draw_secret_wall_cracks()

func request_route_choice() -> void:
	if route_choice_index <= 0:
		return
	set_meta("route_choice_request_count",
		int(get_meta("route_choice_request_count", 0)) + 1)
	_play_press_feedback()
	route_choice_requested.emit(route_choice_index)

func _input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	request_route_choice()
	if viewport != null:
		viewport.set_input_as_handled()

func _apply_label() -> void:
	if _label == null:
		return
	if gate_state == "reward_locked":
		var locked_top := "REWARD" if route_hotkey_label == "" else "%s REWARD" % route_hotkey_label
		_label.text = "%s\nPICK" % locked_top
	else:
		var detail := _route_detail_text()
		if preview_hint != "":
			detail = preview_hint if detail == "" else "%s %s" % [detail, preview_hint]
		_label.text = label_for_type(room_type) if detail == "" \
			else "%s\n%s" % [label_for_type(room_type), detail]
	_label.modulate = _marker_color()

func _route_detail_text() -> String:
	if route_hotkey_label == "":
		return route_hint
	if route_hint == "":
		return route_hotkey_label
	return "%s %s" % [route_hotkey_label, route_hint]

func _marker_color() -> Color:
	if gate_state == "reward_locked":
		return Color(1.0, 0.86, 0.42)
	return color_for_type(room_type)

func _draw_secret_wall_cracks() -> void:
	var crack_color := Color(0.92, 0.92, 0.86, 0.92)
	for segment in crack_line_segments():
		draw_line(segment[0], segment[1], crack_color, 1.0)

func _ensure_click_shape() -> void:
	if _click_shape == null:
		_click_shape = CollisionShape2D.new()
		_click_shape.name = "ClickShape"
		add_child(_click_shape)
	if _click_shape.shape == null:
		var rect := RectangleShape2D.new()
		rect.size = CLICK_RECT.size
		_click_shape.shape = rect
	_click_shape.position = CLICK_RECT.position + CLICK_RECT.size * 0.5
	_click_shape.disabled = route_choice_index <= 0

func _play_press_feedback() -> void:
	set_meta("route_press_feedback", true)
	set_meta("route_press_feedback_count",
		int(get_meta("route_press_feedback_count", 0)) + 1)
	set_meta("route_press_pulse_scale", PRESS_PULSE_SCALE)
	set_meta("route_press_pulse_seconds", PRESS_PULSE_SECONDS)
	if gate_state == "reward_locked" or not is_inside_tree():
		return
	if _press_tween != null:
		_press_tween.kill()
		_press_tween = null
	scale = Vector2.ONE * PRESS_PULSE_SCALE
	_press_tween = create_tween()
	_press_tween.tween_property(self, "scale", Vector2.ONE, PRESS_PULSE_SECONDS)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _update_reward_lock_pulse() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	if gate_state != "reward_locked":
		scale = Vector2.ONE
		set_meta("reward_lock_pulse", false)
		return
	set_meta("reward_lock_pulse", true)
	set_meta("reward_lock_pulse_scale", REWARD_LOCK_PULSE_SCALE)
	set_meta("reward_lock_pulse_seconds", REWARD_LOCK_PULSE_SECONDS)
	if not is_inside_tree():
		return
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2.ONE * REWARD_LOCK_PULSE_SCALE,
		REWARD_LOCK_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE,
		REWARD_LOCK_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
