class_name Player
extends CharacterBody2D
## Player controller with class-driven stats (data/classes.json), elemental
## loadout, energy/mana resource and one active skill.
## Controls: WASD move, Space dash, hold LMB attack, E skill, Tab swap weapon.

signal hp_changed(current: int, max_value: int)
signal died
signal gold_changed(total: int)
signal weapon_changed(display_name: String)
signal resource_changed(current: float, max_value: float)

const MANA_REGEN_PER_S := 4.0  # GDD: mana regens over time
const ENERGY_PER_HIT := 5.0    # GDD: energy builds on successful hits
const CLASS_SPRITES := {
	"blade_warden": {
		"idle": ["knight_m_idle_anim"],
		"run": ["knight_m_run_anim"],
	},
	"arcanist": {
		"idle": ["wizzard_m_idle_anim"],
		"run": ["wizzard_m_run_anim"],
	},
	"ranger": {
		"idle": ["elf_m_idle_anim"],
		"run": ["elf_m_run_anim"],
	},
}

@export var move_speed := 90.0
@export var dash_speed := 260.0
@export var dash_duration := 0.15
@export var dash_iframes := 0.2  # GDD: 0.2s invulnerability on dash
@export var dash_cooldown := 1.2
@export var max_hp := 100

var hp: int
var gold := 0

# Class-driven stats, set by apply_class().
var class_id := ""
var equipped_element := "fire"
var damage_mult := 1.0
var crit_chance := 0.1
var resource_type := "energy"  # "energy" or "mana"
var max_resource := 50.0
var resource := 25.0
var skill: Dictionary = {}

var _weapons: Array[Weapon] = []
var _active := 0
var _skill_cd_left := 0.0
var _dash_time_left := 0.0
var _dash_cd_left := 0.0
var _iframes_left := 0.0
var _dash_dir := Vector2.ZERO
@onready var _sprite: AnimatedSprite2D = get_node_or_null("Sprite")
@onready var _body: Polygon2D = get_node_or_null("Body")


func _ready() -> void:
	hp = max_hp


## Applies class stats + starting loadout. Called once before the run starts.
## Stat conversion (1-10 scale): HP x20, speed 60+x*7, dmg mult 1+(x-5)*0.08,
## crit x*2%, resource pool x*10.
func apply_class(data: Dictionary, element: String, starter_weapon_id: String) -> void:
	class_id = str(data["id"])
	equipped_element = element
	var stats: Dictionary = data["stats"]
	max_hp = int(stats["hp"]) * 20
	hp = max_hp
	move_speed = 60.0 + float(stats["speed"]) * 7.0
	damage_mult = 1.0 + (float(stats["damage"]) - 5.0) * 0.08
	crit_chance = float(stats["crit"]) * 0.02
	resource_type = str(data["resource"])
	max_resource = float(stats["resource"]) * 10.0
	resource = max_resource if resource_type == "mana" else max_resource * 0.5
	skill = data["actives"][0]

	for weapon in _weapons:
		weapon.queue_free()
	_weapons.clear()
	_active = 0
	var starter := Weapon.new()
	add_child(starter)
	starter.equip(starter_weapon_id)
	_weapons.append(starter)
	_apply_class_sprite()

	hp_changed.emit(hp, max_hp)
	resource_changed.emit(resource, max_resource)
	weapon_changed.emit(starter.display_name())
	print("Class: %s | Element: %s | Weapon: %s | Skill (E): %s" % [
		class_id, element, starter.display_name(), str(skill.get("id", "-")),
	])


func current_weapon() -> Weapon:
	return _weapons[_active] if not _weapons.is_empty() else null


func _physics_process(delta: float) -> void:
	_dash_cd_left = maxf(_dash_cd_left - delta, 0.0)
	_iframes_left = maxf(_iframes_left - delta, 0.0)
	_skill_cd_left = maxf(_skill_cd_left - delta, 0.0)
	if resource_type == "mana":
		_gain_resource(MANA_REGEN_PER_S * delta)

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
		weapon_changed.emit(_weapons[_active].display_name())
		print("Equipped: %s" % _weapons[_active].display_name())

	if Input.is_action_just_pressed("skill"):
		_try_skill()

	# Hold to attack; the weapon's own cooldown gates the fire rate.
	if Input.is_action_pressed("attack"):
		var weapon := current_weapon()
		if weapon != null:
			weapon.try_attack(global_position, _aim_dir())

	move_and_slide()
	_update_sprite_anim()


func _aim_dir() -> Vector2:
	var aim := get_global_mouse_position() - global_position
	return aim.normalized() if aim != Vector2.ZERO else Vector2.RIGHT


func _apply_class_sprite() -> void:
	if _sprite == null:
		return
	var mapping: Dictionary = CLASS_SPRITES.get(class_id, {})
	if mapping.is_empty():
		_show_placeholder()
		return
	var idle_name := SpriteDB.first_existing(mapping["idle"])
	var run_name := SpriteDB.first_existing(mapping["run"])
	if idle_name == "" or run_name == "":
		_show_placeholder()
		return
	var sprite_frames := SpriteDB.build_sprite_frames({
		"idle": idle_name,
		"run": run_name,
	})
	if sprite_frames == null:
		_show_placeholder()
		return
	_sprite.sprite_frames = sprite_frames
	_sprite.visible = true
	_sprite.play("idle")
	if _body != null:
		_body.visible = false


func _show_placeholder() -> void:
	if _sprite != null:
		_sprite.visible = false
	if _body != null:
		_body.visible = true


func _update_sprite_anim() -> void:
	if _sprite == null or not _sprite.visible or _sprite.sprite_frames == null:
		return
	var anim := "run" if velocity.length_squared() > 1.0 else "idle"
	if _sprite.animation != anim:
		_sprite.play(anim)
	var face_dir := velocity
	if face_dir.length_squared() <= 1.0:
		face_dir = _aim_dir()
	if absf(face_dir.x) > 0.01:
		_sprite.flip_h = face_dir.x < 0.0


## Called by weapons/projectiles when a hit lands (energy classes build up).
func on_hit_landed() -> void:
	if resource_type == "energy":
		_gain_resource(ENERGY_PER_HIT)


func _gain_resource(amount: float) -> void:
	if amount <= 0.0 or resource >= max_resource:
		return
	resource = minf(resource + amount, max_resource)
	resource_changed.emit(resource, max_resource)


func _try_skill() -> void:
	if skill.is_empty() or _skill_cd_left > 0.0:
		return
	var cost := float(skill.get("cost", 0))
	if resource < cost:
		return
	resource -= cost
	resource_changed.emit(resource, max_resource)
	_skill_cd_left = float(skill.get("cooldown", 6.0))

	var weapon := current_weapon()
	var base := int((weapon.base_damage() if weapon != null else 10) * damage_mult)
	var aim_dir := _aim_dir()

	match str(skill.get("id", "")):
		"wind_edge":  # Blade Warden: 360 AoE slash, 130%
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if enemy is Enemy \
						and enemy.global_position.distance_to(global_position) <= 38.0:
					enemy.hit(int(base * 1.3), equipped_element)
		"element_orb":  # Arcanist: elemental projectile, 120%
			var orb := Projectile.new()
			orb.setup(aim_dir, 240.0, int(base * 1.2), 170.0,
				Color(0.5, 0.9, 1.0), equipped_element, self)
			get_tree().current_scene.add_child(orb)
			orb.global_position = global_position + aim_dir * 10.0
		"arrow_rain":  # Ranger: delayed zone at cursor, 160%
			var zone_center := get_global_mouse_position()
			get_tree().create_timer(0.5).timeout.connect(func() -> void:
				for enemy in get_tree().get_nodes_in_group("enemies"):
					if enemy is Enemy and is_instance_valid(enemy) \
							and enemy.global_position.distance_to(zone_center) <= 42.0:
						enemy.hit(int(base * 1.6), equipped_element))


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


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)


## Replaces the active weapon slot (in-run pickup; full inventory later).
func pickup_weapon(id: String) -> void:
	var weapon := current_weapon()
	if weapon == null:
		return
	var old_name := weapon.display_name()
	weapon.equip(id)
	weapon_changed.emit(weapon.display_name())
	print("Weapon swapped: %s -> %s" % [old_name, weapon.display_name()])
