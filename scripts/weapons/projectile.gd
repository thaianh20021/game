class_name Projectile
extends Area2D
## Player projectile: flies straight, damages the first enemy hit (applying
## the shooter's element), despawns on walls or when range is exhausted.

const FirePatchScript := preload("res://scripts/weapons/fire_patch.gd")

var _dir := Vector2.RIGHT
var _speed := 220.0
var _damage := 5
var _range := 140.0
var _color := Color(1.0, 0.9, 0.55)
var _element := ""
var _shooter: Node = null
var _pierce_left := 0
var _critical := false
var _homing_strength := 0.0
var _chain_left := 0
var _chain_radius := 0.0
var _chain_damage_mult := 0.0
var _split_count := 0
var _split_angle_rad := 0.0
var _split_damage_mult := 0.0
var _fire_patch_damage := 0
var _fire_patch_radius := 0.0
var _fire_patch_duration := 0.0
var _fire_patch_tick := 0.0
var _travelled := 0.0


func setup(
		dir: Vector2,
		speed: float,
		damage: int,
		range_px: float,
		color: Color,
		element: String = "",
		shooter: Node = null,
		pierce_count: int = 0,
		critical: bool = false,
		homing_strength: float = 0.0,
) -> void:
	_dir = dir.normalized()
	_speed = speed
	_damage = damage
	_range = range_px
	_color = color
	_element = element
	_shooter = shooter
	_pierce_left = maxi(pierce_count, 0)
	_critical = critical
	_homing_strength = maxf(homing_strength, 0.0)

func configure_chain(count: int, radius: float, damage_mult: float) -> void:
	_chain_left = maxi(count, 0)
	_chain_radius = maxf(radius, 0.0)
	_chain_damage_mult = maxf(damage_mult, 0.0)


func configure_split(count: int, angle_deg: float, damage_mult: float) -> void:
	_split_count = maxi(count, 0)
	_split_angle_rad = deg_to_rad(maxf(angle_deg, 0.0))
	_split_damage_mult = maxf(damage_mult, 0.0)


func configure_fire_patch(damage: int, radius: float, duration: float, tick_interval: float) -> void:
	_fire_patch_damage = maxi(damage, 0)
	_fire_patch_radius = maxf(radius, 0.0)
	_fire_patch_duration = maxf(duration, 0.0)
	_fire_patch_tick = maxf(tick_interval, 0.0)


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.0
	shape.shape = circle
	add_child(shape)

	if not _add_sprite_visual():
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(-3, -1.5), Vector2(3, -1.5), Vector2(3, 1.5), Vector2(-3, 1.5),
		])
		body.color = _color
		body.set_meta("sprite_fallback", "polygon")
		add_child(body)

	rotation = _dir.angle()
	z_index = 3
	body_entered.connect(_on_body_entered)

func _add_sprite_visual() -> bool:
	var sprite_name := SpriteDB.first_existing(["zerie_arrow_projectile", "weapon_arrow"])
	var frames := SpriteDB.build_sprite_frames({"idle": sprite_name})
	if frames == null:
		return false
	var sprite := AnimatedSprite2D.new()
	sprite.name = "ProjectileSprite"
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.rotation = PI / 2.0
	sprite.modulate = _color
	sprite.z_index = 1
	sprite.play("idle")
	SpriteDB.apply_sprite_metadata(sprite, sprite_name)
	add_child(sprite)
	return true


func _physics_process(delta: float) -> void:
	_apply_homing(delta)
	var step := _dir * _speed * delta
	position += step
	_travelled += step.length()
	if _travelled >= _range:
		queue_free()

func _apply_homing(delta: float) -> void:
	var strength := _homing_strength
	if _shooter != null and is_instance_valid(_shooter) \
			and bool(_shooter.get_meta("suppressing_fire_homing", false)):
		strength = maxf(strength, 4.0)
	if strength <= 0.0:
		return
	var target := _nearest_enemy()
	if target == null:
		return
	var desired := target.global_position - global_position
	if desired.length_squared() <= 0.0:
		return
	_dir = _dir.lerp(desired.normalized(), minf(delta * strength, 0.35)).normalized()

func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var best_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy:
			var dist := global_position.distance_squared_to(enemy.global_position)
			if dist < best_dist:
				best_dist = dist
				best = enemy
	return best


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("breakable_props") and body.has_method("hit"):
		body.hit(_damage)
		queue_free()
	elif body is Enemy:
		var damage := _target_adjusted_damage(body)
		body.set_meta("incoming_critical", _critical)
		if body.has_method("hit_from"):
			body.hit_from(damage, _element, global_position)
		else:
			body.hit(damage, _element)
		_try_chain(body)
		_try_split()
		_spawn_fire_patch()
		if _shooter != null and is_instance_valid(_shooter) \
				and _shooter.has_method("on_hit_landed"):
			_shooter.on_hit_landed()
		if _pierce_left <= 0:
			queue_free()
		else:
			_pierce_left -= 1
	elif body is StaticBody2D:
		queue_free()
	# The player (CharacterBody2D, not Enemy) is ignored on purpose.

func _target_adjusted_damage(target: Node) -> int:
	var damage := _damage
	if _shooter != null and is_instance_valid(_shooter) \
			and _shooter.has_method("target_damage_multiplier"):
		var mult := float(_shooter.call("target_damage_multiplier", target))
		if mult > 1.0:
			damage = maxi(1, int(round(float(damage) * mult)))
			target.set_meta("target_damage_mult", mult)
	return damage

func _try_chain(source: Enemy) -> void:
	if _chain_left <= 0 or _chain_radius <= 0.0 or _chain_damage_mult <= 0.0:
		return
	var target := _nearest_chain_target(source)
	if target == null:
		return
	_chain_left -= 1
	var damage := maxi(1, int(round(float(_damage) * _chain_damage_mult)))
	target.set_meta("incoming_critical", false)
	if target.has_method("hit_from"):
		target.hit_from(damage, _element, source.global_position)
	else:
		target.hit(damage, _element)
	_spawn_chain_fx(source.global_position, target.global_position)

func _nearest_chain_target(source: Enemy) -> Enemy:
	var best: Enemy = null
	var best_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy != source and is_instance_valid(enemy) \
				and not enemy.is_queued_for_deletion():
			var dist := source.global_position.distance_squared_to(enemy.global_position)
			if dist <= _chain_radius * _chain_radius and dist < best_dist:
				best_dist = dist
				best = enemy
	return best

func _spawn_chain_fx(from_pos: Vector2, to_pos: Vector2) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var parent := tree.current_scene if tree.current_scene != null else tree.root
	var line := Line2D.new()
	line.name = "ProjectileChainFx"
	line.width = 2.0
	line.default_color = Color(0.55, 0.8, 1.0, 0.75)
	line.points = PackedVector2Array([from_pos, to_pos])
	parent.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.12)
	tween.finished.connect(line.queue_free)


func _try_split() -> void:
	if _split_count <= 0 or _split_angle_rad <= 0.0 or _split_damage_mult <= 0.0:
		return
	var parent := get_parent()
	if parent == null:
		return
	var count := _split_count
	_split_count = 0
	var damage := maxi(1, int(round(float(_damage) * _split_damage_mult)))
	var range_left := maxf(_range - _travelled, _range * 0.45)
	for i in count:
		var offset := float(i) - (float(count) - 1.0) * 0.5
		var shard := Projectile.new()
		shard.name = "SplitProjectile"
		shard.setup(_dir.rotated(_split_angle_rad * offset), _speed, damage, range_left,
			_color, _element, _shooter, 0, false, _homing_strength)
		parent.add_child(shard)
		shard.global_position = global_position


func _spawn_fire_patch() -> void:
	if _fire_patch_damage <= 0 or _fire_patch_radius <= 0.0 or _fire_patch_duration <= 0.0:
		return
	var parent := get_parent()
	if parent == null:
		return
	var patch := FirePatchScript.new()
	patch.name = "FirePatch"
	patch.configure(_fire_patch_damage, _fire_patch_radius, _fire_patch_duration,
		_fire_patch_tick, "fire")
	parent.add_child(patch)
	patch.global_position = global_position
