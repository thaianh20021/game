class_name Projectile
extends Area2D
## Player projectile: flies straight, damages the first enemy hit, despawns
## on walls or when its range is exhausted. Built entirely in code until
## per-weapon projectile art exists.

var _dir := Vector2.RIGHT
var _speed := 220.0
var _damage := 5
var _range := 140.0
var _color := Color(1.0, 0.9, 0.55)
var _travelled := 0.0


func setup(dir: Vector2, speed: float, damage: int, range_px: float, color: Color) -> void:
	_dir = dir.normalized()
	_speed = speed
	_damage = damage
	_range = range_px
	_color = color


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.0
	shape.shape = circle
	add_child(shape)

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-3, -1.5), Vector2(3, -1.5), Vector2(3, 1.5), Vector2(-3, 1.5),
	])
	body.color = _color
	add_child(body)

	rotation = _dir.angle()
	z_index = 3
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step := _dir * _speed * delta
	position += step
	_travelled += step.length()
	if _travelled >= _range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.take_damage(_damage)
		queue_free()
	elif body is StaticBody2D:
		queue_free()
	# The player (CharacterBody2D, not Enemy) is ignored on purpose.
