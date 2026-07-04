class_name RunOverlay
extends CanvasLayer
## Fullscreen dimmed message for run end states (death / victory).

var _title: Label
var _subtitle: Label


func _ready() -> void:
	layer = 20
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_title = Label.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	add_child(_title)

	_subtitle = Label.new()
	_subtitle.set_anchors_preset(Control.PRESET_FULL_RECT)
	_subtitle.offset_top = 60.0
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 12)
	add_child(_subtitle)


func show_message(title: String, subtitle: String) -> void:
	_title.text = title
	_subtitle.text = subtitle
	visible = true
