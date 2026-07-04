class_name Player
extends CharacterBody2D
## MVP player controller: 8-way movement, dash with i-frames, and a weapon
## loadout driven by data/weapons.json.
## Controls: WASD move, Space dash, hold LMB attack, Tab swap weapon.

signal hp_changed(current: int, max_value: int)
signal died

## Pre-run loadout placeholder; later chosen in the hub (GDD section 4).
const STARTING_WEAPONS: Array[String] = ["warden_sword", "hardwood_bow"]

@export var move_speed := 90.0
@export var dash_speed := 260.0
@export var dash_duration := 0.15
@export var dash_iframes := 0.2  # GDD: 0.2s invulnerability on dash
@export var dash_cooldown := 1.2
@export var max_hp := 100

var hp: int

var _weapons: Array[Weapon] = []
var _active := 0
var _dash_time_left := 0.0
var _dash_cd_left := 0.0
var _iframes_left := 0.0
var _dash_dir := Vector2.ZERO


func _ready() -> void:
	hp = max_hp
	for id in STARTING_WEAPONS:
		var weapon := Weapon.new()
		add_child(weapon)
		weapon.equip(id)
		_weapons.append(weapon)
	if not _weapons.is_empty():
		print("Equipped: %s (Tab to swap)" % _weapons[_active].display_name())


func current_weapon() -> Weapon:
	return _weapons[_active] if not _weapons.is_empty() else null


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

	if Input.is_action_just_pressed("swap_weapon") and _weapons.size() > 1:
		_active = (_active + 1) % _weapons.size()
		print("Equipped: %s" % _weapons[_active].display_name())

	# Hold to attack; the weapon's own cooldown gates the fire rate.
	if Input.is_action_pressed("attack"):
		var weapon := current_weapon()
		if weapon != null:
			var aim := (get_global_mouse_position() - global_position).normalized()
			if aim == Vector2.ZERO:
				aim = Vector2.RIGHT
			weapon.try_attack(global_position, aim)

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
