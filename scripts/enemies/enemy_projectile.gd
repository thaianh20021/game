class_name EnemyProjectile
extends Area2D
## Enemy projectile: flies straight, damages the player on contact, despawns
## on walls or when its range is exhausted. Passes through other enemies.

var _dir := Vector2.RIGHT
var _speed := 150.0
var _damage := 5
var _range := 220.0
var _travelled := 0.0


func setup(dir: Vector2, speed: float, damage: int, range_px: float) -> void:
	_dir = dir.normalized()
	_speed = speed
	_damage = damage
	_range = range_px


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.0
	shape.shape = circle
	add_child(shape)

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -2.5), Vector2(2.5, 0), Vector2(0, 2.5), Vector2(-2.5, 0),
	])
	body.color = Color(1.0, 0.45, 0.35)
	add_child(body)

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
		return  # friendly fire off
	if body is Player:
		body.take_damage(_damage)
		queue_free()
	elif body is StaticBody2D:
		queue_free()
