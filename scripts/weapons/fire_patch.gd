class_name FirePatch
extends Area2D

var damage := 4
var radius := 18.0
var duration := 2.0
var tick_interval := 0.45
var element := "fire"

var _spawned_at := 0.0
var _last_hit_by_id := {}

func configure(
		p_damage: int,
		p_radius: float,
		p_duration: float,
		p_tick_interval: float,
		p_element: String = "fire",
) -> void:
	damage = maxi(p_damage, 1)
	radius = maxf(p_radius, 1.0)
	duration = maxf(p_duration, 0.1)
	tick_interval = maxf(p_tick_interval, 0.05)
	element = p_element
	_refresh_shape()

func _ready() -> void:
	add_to_group("player_fire_patches")
	monitoring = true
	_spawned_at = _now()
	_refresh_shape()
	_spawn_visual()

func _physics_process(_delta: float) -> void:
	var now := _now()
	if now - _spawned_at >= duration:
		queue_free()
		return
	for body in get_overlapping_bodies():
		if body is Enemy:
			apply_to(body, now)

func apply_to(target: Node, now: float) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var id := target.get_instance_id()
	if now - float(_last_hit_by_id.get(id, -999.0)) < tick_interval:
		return false
	_last_hit_by_id[id] = now
	if target.has_method("hit"):
		target.call("hit", damage, element)
	elif target.has_method("take_damage"):
		target.call("take_damage", damage)
	if target.has_method("add_status"):
		target.call("add_status", element, 2.0)
	return true

func _refresh_shape() -> void:
	if not is_inside_tree():
		return
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null:
		shape = CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		add_child(shape)
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle

func _spawn_visual() -> void:
	if _add_sprite_visual():
		return
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = Color(1.0, 0.28, 0.08, 0.55)
	var points := PackedVector2Array()
	for i in 12:
		var r := radius * (0.7 if i % 2 == 0 else 1.0)
		points.append(Vector2(r, 0).rotated(TAU * float(i) / 12.0))
	visual.polygon = points
	add_child(visual)
	var tween := visual.create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, duration)

func _add_sprite_visual() -> bool:
	var sprite_name := "fire_patch_generated"
	var frames := SpriteDB.build_sprite_frames({"idle": sprite_name})
	if frames == null:
		return false
	var sprite := AnimatedSprite2D.new()
	sprite.name = "FirePatchSprite"
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.modulate = Color(1.0, 0.62, 0.28, 0.78)
	sprite.scale = Vector2.ONE * maxf(radius / 8.0, 1.0)
	sprite.z_index = 2
	sprite.play("idle")
	SpriteDB.apply_sprite_metadata(sprite, sprite_name)
	add_child(sprite)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, duration)
	return true

func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0
