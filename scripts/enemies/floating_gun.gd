class_name FloatingGun
extends Node2D
## Boss child weapon that orbits and fires simple readable projectiles.

var owner_node: Node2D
var target: Node2D
var orbit_radius := 26.0
var orbit_speed := 1.8
var fire_cooldown := 1.35
var projectile_damage := 5

var _index := 0
var _count := 1
var _angle := 0.0
var _fire_left := 0.4

func configure(owner: Node2D, p_target: Node2D, index: int, count: int) -> void:
	owner_node = owner
	target = p_target
	_index = index
	_count = maxi(count, 1)
	_angle = TAU * float(_index) / float(_count)

func _ready() -> void:
	add_to_group("floating_guns")
	z_index = 4
	if not _add_sprite_visual():
		var body := Polygon2D.new()
		body.name = "Visual"
		body.polygon = PackedVector2Array([
			Vector2(-5, -3), Vector2(5, -3), Vector2(7, 0), Vector2(5, 3), Vector2(-5, 3),
		])
		body.color = Color(0.82, 0.72, 0.95)
		body.set_meta("sprite_fallback", "polygon")
		add_child(body)

func _add_sprite_visual() -> bool:
	var sprite_name := "weapon_red_magic_staff"
	var frames := SpriteDB.build_sprite_frames({"idle": sprite_name})
	if frames == null:
		return false
	var sprite := AnimatedSprite2D.new()
	sprite.name = "FloatingGunSprite"
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.rotation = PI / 2.0
	sprite.modulate = Color(0.92, 0.82, 1.0)
	sprite.play("idle")
	SpriteDB.apply_sprite_metadata(sprite, sprite_name)
	add_child(sprite)
	return true

func _physics_process(delta: float) -> void:
	if owner_node != null and is_instance_valid(owner_node):
		_angle += orbit_speed * delta
		global_position = owner_node.global_position + Vector2(orbit_radius, 0).rotated(_angle)
	if target == null or not is_instance_valid(target):
		return
	var dir := target.global_position - global_position
	if dir.length_squared() > 0.0:
		rotation = dir.angle()
	_fire_left -= delta
	if _fire_left <= 0.0:
		_fire_left = fire_cooldown + float(_index) * 0.18
		_fire(dir.normalized())

func _fire(dir: Vector2) -> void:
	var projectile := EnemyProjectile.new()
	projectile.setup(dir, 150.0, projectile_damage, 210.0)
	if owner_node != null and is_instance_valid(owner_node):
		if owner_node.has_method("phase_pattern"):
			projectile.set_meta("boss_pattern", str(owner_node.call("phase_pattern")))
		if owner_node.has_method("pattern_label"):
			projectile.set_meta("boss_pattern_label", str(owner_node.call("pattern_label")))
		projectile.set_meta("boss_attack", "floating_gun")
		projectile.set_meta("boss_attack_label", "Floating Gun")
	var parent := _shot_parent()
	parent.add_child(projectile)
	projectile.global_position = global_position + dir * 7.0

func _shot_parent() -> Node:
	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		return tree.current_scene
	if get_parent() != null:
		return get_parent()
	return self
