class_name Enemy
extends CharacterBody2D
## Placeholder chase AI used by the room demo. Real per-kind behaviors
## (charger, flyer, ranged, caster...) come in the enemy AI milestone.

signal died(enemy: Enemy)

@export var speed := 55.0
@export var max_hp := 20
@export var contact_damage := 5
@export var sight_range := 150.0
@export var contact_range := 12.0

var hp: int
var target: Node2D
var _hit_cd := 0.0


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	_hit_cd = maxf(_hit_cd - delta, 0.0)
	if target == null or not is_instance_valid(target):
		return

	var to_target := target.global_position - global_position
	if to_target.length() <= sight_range:
		velocity = to_target.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	if _hit_cd == 0.0 and to_target.length() <= contact_range \
			and target.has_method("take_damage"):
		target.take_damage(contact_damage)
		_hit_cd = 0.6


func take_damage(amount: int) -> void:
	hp -= amount
	modulate = Color(1.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	if hp <= 0:
		died.emit(self)
		queue_free()
