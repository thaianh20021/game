class_name ClassSelectScreen
extends CanvasLayer
## Pre-run loadout screen (GDD section 4, MVP subset): pick 1 class and
## 1 starting element, then enter the dungeon. Built in code until UI art.

signal confirmed(class_id: String, element: String)

const ELEMENT_LABELS := {
	"fire": "Fire", "ice": "Ice", "lightning": "Lightning", "poison": "Poison",
}

var _selected_class := ""
var _selected_element := ""
var _status: Label
var _start: Button


func _ready() -> void:
	layer = 15

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.05, 0.08, 0.97)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	var title := Label.new()
	title.text = "DUNGEON CORE: ELEMENTAL REBIRTH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	box.add_child(title)

	var hint := Label.new()
	hint.text = "Choose your class and starting element"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	box.add_child(hint)

	var class_scroll := ScrollContainer.new()
	class_scroll.name = "ClassScroll"
	class_scroll.custom_minimum_size = Vector2(420, 112)
	class_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	class_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(class_scroll)

	var class_grid := GridContainer.new()
	class_grid.name = "ClassGrid"
	class_grid.columns = 2
	class_grid.add_theme_constant_override("h_separation", 8)
	class_grid.add_theme_constant_override("v_separation", 6)
	class_scroll.add_child(class_grid)
	for c in PlayerClassDB.all():
		var button := Button.new()
		button.text = str(c["name"])
		button.custom_minimum_size = Vector2(196, 24)
		button.pressed.connect(_on_class_pressed.bind(str(c["id"]), button, class_grid))
		class_grid.add_child(button)

	var element_row := HBoxContainer.new()
	element_row.alignment = BoxContainer.ALIGNMENT_CENTER
	element_row.add_theme_constant_override("separation", 8)
	box.add_child(element_row)
	for element in ElementSystem.ELEMENTS:
		var button := Button.new()
		button.text = ELEMENT_LABELS.get(element, element)
		button.pressed.connect(_on_element_pressed.bind(element, button, element_row))
		element_row.add_child(button)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 10)
	box.add_child(_status)

	_start = Button.new()
	_start.text = "ENTER THE DUNGEON"
	_start.pressed.connect(_on_start)
	box.add_child(_start)

	_update()


func _on_class_pressed(id: String, button: Button, row: Container) -> void:
	_selected_class = id
	_mark_selected(button, row)
	_update()


func _on_element_pressed(element: String, button: Button, row: Container) -> void:
	_selected_element = element
	_mark_selected(button, row)
	_update()


func _mark_selected(selected: Button, row: Container) -> void:
	for child in row.get_children():
		if child is Button:
			child.disabled = child == selected


func _update() -> void:
	_status.text = "Class: %s   |   Element: %s" % [
		_selected_class if _selected_class != "" else "-",
		_selected_element if _selected_element != "" else "-",
	]
	_start.disabled = _selected_class == "" or _selected_element == ""


func _on_start() -> void:
	confirmed.emit(_selected_class, _selected_element)
	queue_free()
