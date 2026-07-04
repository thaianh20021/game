class_name Enemy
extends CharacterBody2D
## Enemy with kind-based AI behaviors and elemental statuses/combos
## (GDD sections 7 and 11). Kind is set by the spawner from enemy data:
##   melee_charger: telegraph 0.5s then locked dash
##   ranged/caster: keep distance, fire projectiles
##   exploder: chase, fuse on contact range, blast
##   flyer: sine-wave chase
##   others: straight chase (tanker is slow via SPEED_BY_KIND)

signal died(enemy: Enemy)

const DOT_INTERVAL := 0.5
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")

@export var speed := 55.0
@export var max_hp := 20
@export var contact_damage := 5
@export var sight_range := 150.0
@export var contact_range := 12.0

var kind := "melee"
var hp: int
var target: Node2D
var base_tint := Color.WHITE  # elite tint, set by the spawner

var _statuses := {}  # status name -> seconds left
var _hit_cd := 0.0
var _attack_cd := 0.0
var _dot_tick := 0.0
var _time := 0.0
var _state := "chase"
var _state_timer := 0.0
var _dash_dir := Vector2.ZERO
var _hp_bar: Node2D
var _hp_fill: ColorRect
@onready var _sprite: AnimatedSprite2D = get_node_or_null("Sprite")
@onready var _body: Polygon2D = get_node_or_null("Body")


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	modulate = base_tint


func _physics_process(delta: float) -> void:
	_time += delta
	_hit_cd = maxf(_hit_cd - delta, 0.0)
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if not _tick_statuses(delta):  # frozen or stunned
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if target == null or not is_instance_valid(target):
		return
	_behave(delta)
	_update_sprite_anim()
	if kind != "exploder":
		_try_contact_damage()


func configure_visual(idle_name: String, run_name: String = "") -> void:
	if _sprite == null or idle_name == "":
		return
	var anims := {"idle": idle_name}
	anims["run"] = run_name if run_name != "" else idle_name
	var sprite_frames := SpriteDB.build_sprite_frames(anims)
	if sprite_frames == null:
		return
	_sprite.sprite_frames = sprite_frames
	_sprite.visible = true
	_sprite.scale = Vector2.ONE
	_align_sprite_to_collision()
	_sprite.play("idle")
	if _body != null:
		_body.visible = false


func _update_sprite_anim() -> void:
	if _sprite == null or not _sprite.visible or _sprite.sprite_frames == null:
		return
	var anim := "run" if velocity.length_squared() > 1.0 else "idle"
	if _sprite.animation != anim:
		_sprite.play(anim)
	var face_dir := velocity
	if face_dir.length_squared() <= 1.0 and target != null and is_instance_valid(target):
		face_dir = target.global_position - global_position
	if absf(face_dir.x) > 0.01:
		_sprite.flip_h = face_dir.x < 0.0


func _align_sprite_to_collision() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var frame_height := _sprite_frame_height()
	if frame_height <= 0.0:
		return
	_sprite.offset = Vector2(0.0, _collision_half_height() - frame_height * 0.5)


func _sprite_frame_height() -> float:
	var max_height := 0.0
	for anim_name in _sprite.sprite_frames.get_animation_names():
		for i in _sprite.sprite_frames.get_frame_count(anim_name):
			var frame := _sprite.sprite_frames.get_frame_texture(anim_name, i)
			if frame != null:
				max_height = maxf(max_height, frame.get_size().y)
	return max_height


func _collision_half_height() -> float:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return 0.0
	var rect := collision.shape as RectangleShape2D
	return rect.size.y * 0.5 if rect != null else 0.0


func _behave(delta: float) -> void:
	match kind:
		"melee_charger":
			_charger_behavior(delta)
		"ranged", "caster":
			_ranged_behavior(delta)
		"exploder":
			_exploder_behavior(delta)
		"flyer":
			_flyer_behavior(delta)
		_:
			_chase_behavior(delta)


func _chase_behavior(_delta: float) -> void:
	var to_target := target.global_position - global_position
	if to_target.length() <= sight_range:
		velocity = to_target.normalized() * speed * _speed_mult()
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _charger_behavior(delta: float) -> void:
	var to_target := target.global_position - global_position
	match _state:
		"telegraph":
			velocity = Vector2.ZERO
			_state_timer -= delta
			_blink(Color(1.6, 1.6, 1.6))
			if _state_timer <= 0.0:
				_state = "dash"
				_state_timer = 0.4
				_dash_dir = to_target.normalized()  # direction locks here
				modulate = _current_tint()
		"dash":
			velocity = _dash_dir * speed * 3.2 * _speed_mult()
			_state_timer -= delta
			if _state_timer <= 0.0:
				_state = "cooldown"
				_state_timer = 0.7
		"cooldown":
			velocity = Vector2.ZERO
			_state_timer -= delta
			if _state_timer <= 0.0:
				_state = "chase"
		_:
			if to_target.length() > sight_range:
				velocity = Vector2.ZERO
			elif to_target.length() <= 70.0:
				_state = "telegraph"
				_state_timer = 0.5
				velocity = Vector2.ZERO
				_show_telegraph_fx(to_target.normalized(), 28.0, _state_timer)
			else:
				velocity = to_target.normalized() * speed * _speed_mult()
	move_and_slide()


func _ranged_behavior(_delta: float) -> void:
	var to_target := target.global_position - global_position
	var dist := to_target.length()
	if dist > sight_range * 1.4:
		velocity = Vector2.ZERO
	elif dist < 60.0:
		velocity = -to_target.normalized() * speed * _speed_mult()
	elif dist > 140.0:
		velocity = to_target.normalized() * speed * _speed_mult()
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if dist <= 180.0 and _attack_cd <= 0.0:
		_attack_cd = 1.8
		_shoot(to_target.normalized(), 150.0, contact_damage, 220.0)


func _exploder_behavior(delta: float) -> void:
	var to_target := target.global_position - global_position
	match _state:
		"fuse":
			velocity = Vector2.ZERO
			_state_timer -= delta
			_blink(Color(2.0, 0.5, 0.5))
			if _state_timer <= 0.0:
				_explode()
		_:
			if to_target.length() <= 26.0:
				_state = "fuse"
				_state_timer = 0.8
				velocity = Vector2.ZERO
				_show_telegraph_fx(to_target.normalized(), 44.0, _state_timer)
			elif to_target.length() <= sight_range:
				velocity = to_target.normalized() * speed * _speed_mult()
			else:
				velocity = Vector2.ZERO
	move_and_slide()


func _flyer_behavior(_delta: float) -> void:
	var to_target := target.global_position - global_position
	if to_target.length() <= sight_range:
		var dir := to_target.normalized()
		var perp := dir.orthogonal() * sin(_time * 6.0) * 0.6
		velocity = (dir + perp).normalized() * speed * _speed_mult()
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _explode() -> void:
	if target != null and is_instance_valid(target) \
			and global_position.distance_to(target.global_position) <= 44.0 \
			and target.has_method("take_damage"):
		target.take_damage(contact_damage)
	died.emit(self)
	queue_free()


func _try_contact_damage() -> void:
	var to_target := target.global_position - global_position
	if _hit_cd == 0.0 and to_target.length() <= contact_range \
			and target.has_method("take_damage"):
		target.take_damage(contact_damage)
		_hit_cd = 0.6


func _shoot(dir: Vector2, speed_px: float, damage: int, range_px: float) -> void:
	var projectile := EnemyProjectile.new()
	projectile.setup(dir, speed_px, damage, range_px)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + dir * 8.0


# --- Damage + elemental statuses -------------------------------------------

## Damage plus element application in one call (used by player weapons/skills).
func hit(amount: int, element: String = "") -> void:
	take_damage(amount)
	if element != "" and hp > 0:
		apply_element(element)


func take_damage(amount: int) -> void:
	if _statuses.has("vulnerable"):  # Plasma combo
		amount = ceili(amount * 1.25)
	hp -= amount
	_show_hit_feedback(amount)
	modulate = Color(1.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(self, "modulate", _current_tint(), 0.15)
	if hp <= 0:
		died.emit(self)
		queue_free()


## Applies an element. If a DIFFERENT element status is already present,
## it is consumed and the matching combo triggers instead.
func apply_element(element: String) -> void:
	for existing in _statuses.keys():
		if existing != element and ElementSystem.is_element(existing):
			_statuses.erase(existing)
			ElementSystem.trigger_combo(self, existing, element)
			modulate = _current_tint()
			return
	_statuses[element] = ElementSystem.status_duration(element)
	if element == "lightning":  # shock: short stun, longer combo window
		add_status("stun", 0.3)
	modulate = _current_tint()


func add_status(status_name: String, duration: float) -> void:
	_statuses[status_name] = maxf(duration, float(_statuses.get(status_name, 0.0)))
	modulate = _current_tint()


## Ticks status timers and DoTs. Returns false while the enemy cannot act.
func _tick_statuses(delta: float) -> bool:
	var expired: Array = []
	for status_name in _statuses.keys():
		_statuses[status_name] -= delta
		if _statuses[status_name] <= 0.0:
			expired.append(status_name)
	for status_name in expired:
		_statuses.erase(status_name)
	if not expired.is_empty():
		modulate = _current_tint()

	_dot_tick += delta
	if _dot_tick >= DOT_INTERVAL:
		_dot_tick -= DOT_INTERVAL
		var dot := 0
		if _statuses.has("fire"):
			dot += 2  # burn: ~4 dmg/s
		if _statuses.has("poison"):
			dot += maxi(1, int(max_hp * 0.01))  # ~2% maxHP/s
		if dot > 0:
			_dot_damage(dot)
	return not (_statuses.has("frozen") or _statuses.has("stun"))


func _dot_damage(amount: int) -> void:
	hp -= amount
	_show_hit_feedback(amount)
	if hp <= 0:
		died.emit(self)
		queue_free()


func _show_hit_feedback(amount: int) -> void:
	_update_hp_bar()
	_spawn_damage_number(amount)


func _update_hp_bar() -> void:
	if _hp_bar == null or not is_instance_valid(_hp_bar):
		_hp_bar = Node2D.new()
		_hp_bar.name = "HpBar"
		_hp_bar.position = Vector2(-10, -18)
		add_child(_hp_bar)
		var bg := ColorRect.new()
		bg.name = "Background"
		bg.position = Vector2.ZERO
		bg.size = Vector2(20, 3)
		bg.color = Color(0.02, 0.02, 0.02, 0.8)
		_hp_bar.add_child(bg)
		_hp_fill = ColorRect.new()
		_hp_fill.name = "Fill"
		_hp_fill.position = Vector2(1, 1)
		_hp_fill.size = Vector2(18, 1)
		_hp_fill.color = Color(0.9, 0.18, 0.14)
		_hp_bar.add_child(_hp_fill)
	if _hp_fill != null:
		var ratio := clampf(float(maxi(hp, 0)) / maxf(float(max_hp), 1.0), 0.0, 1.0)
		_hp_fill.size.x = 18.0 * ratio


func _spawn_damage_number(amount: int) -> void:
	var old := get_node_or_null("DamageNumber")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "DamageNumber"
	label.text = str(amount)
	label.position = Vector2(-8, -30)
	label.add_theme_font_size_override("font_size", 8)
	label.modulate = Color(1.0, 0.82, 0.28)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -10), 0.35)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(label.queue_free)


func _speed_mult() -> float:
	if _statuses.has("frostbane"):
		return 0.4
	if _statuses.has("ice"):
		return 0.6
	return 1.0


func _current_tint() -> Color:
	if _statuses.has("frozen"):
		return base_tint * Color(0.5, 0.8, 1.4)
	if _statuses.has("fire"):
		return base_tint * Color(1.4, 0.8, 0.5)
	if _statuses.has("poison"):
		return base_tint * Color(0.6, 1.3, 0.6)
	if _statuses.has("ice"):
		return base_tint * Color(0.7, 0.9, 1.3)
	if _statuses.has("lightning"):
		return base_tint * Color(1.3, 1.3, 0.6)
	if _statuses.has("vulnerable"):
		return base_tint * Color(1.2, 0.7, 1.2)
	return base_tint


func _blink(color: Color) -> void:
	modulate = color if fmod(_time, 0.2) < 0.1 else _current_tint()


func _show_telegraph_fx(dir: Vector2, radius: float, duration: float) -> void:
	CombatFxScript.spawn_telegraph(_fx_parent(), global_position,
		dir if dir.length_squared() > 0.0 else Vector2.RIGHT, radius, duration)


func _fx_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return self
	return tree.current_scene if tree.current_scene != null else tree.root
