class_name Player
extends CharacterBody2D
## MVP player controller: 8-way movement + dash with i-frames (GDD sections 2 and 5).
## Class stats (speed, HP, energy) are loaded from data/classes.json later;
## the exported defaults below match the Blade Warden baseline.

signal hp_changed(current: int, max_value: int)
signal died

@export var move_speed := 90.0
@export var dash_speed := 260.0
@export var dash_duration := 0.15
@export var dash_iframes := 0.2  # GDD: 0.2s invulnerability on dash
@export var dash_cooldown := 1.2
@export var max_hp := 100

var hp: int
var _dash_time_left := 0.0
var _dash_cd_left := 0.0
var _iframes_left := 0.0
var _dash_dir := Vector2.ZERO


func _ready() -> void:
	hp = max_hp


func _physics_process(delta: float) -> void:
	_dash_cd_left = maxf(_dash_cd_left - delta, 0.0)
	_iframes_left = maxf(_iframes_left - delta, 0.0)

	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		velocity = _dash_dir * dash_speed
	else:
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input_dir * move_speed
		if Input.is_action_just_pressed("dash") \
				and _dash_cd_left == 0.0 and input_dir != Vector2.ZERO:
			_start_dash(input_dir)

	move_and_slide()


func is_invulnerable() -> bool:
	return _iframes_left > 0.0


func take_damage(amount: int) -> void:
	if is_invulnerable():
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	if hp == 0:
		died.emit()


func _start_dash(dir: Vector2) -> void:
	_dash_dir = dir.normalized()
	_dash_time_left = dash_duration
	_iframes_left = dash_iframes
	_dash_cd_left = dash_cooldown
