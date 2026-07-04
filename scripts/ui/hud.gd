class_name HUD
extends CanvasLayer
## In-run HUD: HP bar, active weapon, gold counter and a fog-of-war minimap.
## Built in code until proper UI scenes/art exist.

const BAR_W := 100.0
const BAR_H := 8.0

var _hp_fill: ColorRect
var _hp_label: Label
var _weapon_label: Label
var _gold_label: Label
var _minimap: Minimap


func _ready() -> void:
	layer = 10

	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(8, 8)
	bar_bg.size = Vector2(BAR_W + 4, BAR_H + 4)
	bar_bg.color = Color(0, 0, 0, 0.6)
	add_child(bar_bg)

	_hp_fill = ColorRect.new()
	_hp_fill.position = Vector2(10, 10)
	_hp_fill.size = Vector2(BAR_W, BAR_H)
	_hp_fill.color = Color(0.8, 0.2, 0.2)
	add_child(_hp_fill)

	_hp_label = _make_label(Vector2(118, 6))
	_weapon_label = _make_label(Vector2(8, 24))
	_gold_label = _make_label(Vector2(8, 40))

	_minimap = Minimap.new()
	_minimap.position = Vector2(444, 8)
	_minimap.size = Vector2(188, 96)
	add_child(_minimap)


func bind(player: Player, floor_ctrl: FloorController) -> void:
	player.hp_changed.connect(_on_hp_changed)
	player.gold_changed.connect(_on_gold_changed)
	player.weapon_changed.connect(_on_weapon_changed)
	_on_hp_changed(player.hp, player.max_hp)
	_on_gold_changed(player.gold)
	var weapon := player.current_weapon()
	_on_weapon_changed(weapon.display_name() if weapon != null else "-")
	_minimap.bind(floor_ctrl)


func _make_label(pos: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", 10)
	add_child(label)
	return label


func _on_hp_changed(current: int, max_value: int) -> void:
	_hp_fill.size.x = BAR_W * float(current) / float(max_value)
	_hp_label.text = "%d/%d" % [current, max_value]


func _on_gold_changed(total: int) -> void:
	_gold_label.text = "Gold: %d" % total


func _on_weapon_changed(weapon_name: String) -> void:
	_weapon_label.text = "Weapon: %s" % weapon_name
