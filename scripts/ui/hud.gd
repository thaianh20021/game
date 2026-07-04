class_name HUD
extends CanvasLayer
## In-run HUD: HP + resource bars, active weapon/element, gold, floor and a
## fog-of-war minimap. Built in code until proper UI scenes/art exist.

const BAR_W := 100.0
const BAR_H := 8.0

var _player: Player
var _hp_fill: ColorRect
var _hp_label: Label
var _resource_fill: ColorRect
var _weapon_label: Label
var _gold_label: Label
var _floor_label: Label
var _minimap: Minimap


func _ready() -> void:
	layer = 10

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

	_hp_label = _make_label(Vector2(118, 6))
	_weapon_label = _make_label(Vector2(8, 34))
	_gold_label = _make_label(Vector2(8, 50))
	_floor_label = _make_label(Vector2(8, 66))

	_minimap = Minimap.new()
	_minimap.position = Vector2(444, 8)
	_minimap.size = Vector2(188, 96)
	add_child(_minimap)


func bind(player: Player, floor_ctrl: FloorController) -> void:
	_player = player
	player.hp_changed.connect(_on_hp_changed)
	player.gold_changed.connect(_on_gold_changed)
	player.weapon_changed.connect(_on_weapon_changed)
	player.resource_changed.connect(_on_resource_changed)
	_on_hp_changed(player.hp, player.max_hp)
	_on_gold_changed(player.gold)
	_on_resource_changed(player.resource, player.max_resource)
	if player.resource_type == "energy":
		_resource_fill.color = Color(0.95, 0.75, 0.2)
	var weapon := player.current_weapon()
	_on_weapon_changed(weapon.display_name() if weapon != null else "-")
	_minimap.bind(floor_ctrl)
	floor_ctrl.state_changed.connect(func() -> void:
		_floor_label.text = "Floor %d" % floor_ctrl.floor_index)
	_floor_label.text = "Floor %d" % floor_ctrl.floor_index


func _make_label(pos: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", 10)
	add_child(label)
	return label


func _on_hp_changed(current: int, max_value: int) -> void:
	_hp_fill.size.x = BAR_W * float(current) / float(max_value)
	_hp_label.text = "%d/%d" % [current, max_value]


func _on_resource_changed(current: float, max_value: float) -> void:
	_resource_fill.size.x = BAR_W * current / maxf(max_value, 1.0)


func _on_gold_changed(total: int) -> void:
	_gold_label.text = "Gold: %d" % total


func _on_weapon_changed(weapon_name: String) -> void:
	var element := _player.equipped_element if _player != null else "-"
	_weapon_label.text = "Weapon: %s  [%s]" % [weapon_name, element]
