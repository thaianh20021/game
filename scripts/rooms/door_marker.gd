class_name DoorMarker
extends Node2D

var room_type := RoomNode.RoomType.COMBAT
var _label: Label

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
			return "?"
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

func configure(type: int) -> void:
	room_type = type
	add_to_group("door_markers")
	_apply_label()
	queue_redraw()

func _ready() -> void:
	_label = Label.new()
	_label.name = "Label"
	_label.position = Vector2(-18, -14)
	_label.size = Vector2(36, 12)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 7)
	add_child(_label)
	_apply_label()

func _draw() -> void:
	var rect := Rect2(-15, -7, 30, 14)
	draw_rect(rect, Color(0.02, 0.02, 0.025, 0.82), true)
	draw_rect(rect, color_for_type(room_type), false, 1.0)

func _apply_label() -> void:
	if _label == null:
		return
	_label.text = label_for_type(room_type)
	_label.modulate = color_for_type(room_type)
