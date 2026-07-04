class_name ExitPortal
extends Node2D
## Stairway to the next floor. Spawns in the boss room once the boss is dead;
## stepping on it emits [signal entered]. Pulsing diamond until portal art exists.

signal entered

const TRIGGER_RADIUS := 12.0

var _player: Node2D
var _visual: Polygon2D
var _time := 0.0
var _triggered := false


func configure(player: Node2D) -> void:
	_player = player


func _ready() -> void:
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([
		Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0),
	])
	_visual.color = Color(0.4, 0.9, 1.0)
	add_child(_visual)
	z_index = 1


func _process(delta: float) -> void:
	_time += delta
	_visual.scale = Vector2.ONE * (1.0 + 0.15 * sin(_time * 4.0))
	if _triggered or _player == null or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= TRIGGER_RADIUS:
		_triggered = true
		entered.emit()
