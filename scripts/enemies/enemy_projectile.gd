class_name EnemyProjectile
extends Area2D
## Enemy projectile: flies straight, damages the player on contact, despawns
## on walls or when its range is exhausted. Passes through other enemies.

# ponytail: current reviewed projectile art faces left; move offsets into SpriteDB if mixed arrow art ships.
const ARROW_VISUAL_FORWARD_OFFSET := PI

var _dir := Vector2.RIGHT
var _speed := 150.0
var _damage := 5
var _range := 220.0
var _travelled := 0.0
var _hit_status := ""
var _hit_status_duration := 0.0
var _readability_color := Color(1.0, 0.45, 0.35)


func setup(dir: Vector2, speed: float, damage: int, range_px: float) -> void:
	_dir = dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT
	_speed = speed
	_damage = damage
	_range = range_px


func setup_status(status_name: String, duration: float) -> void:
	_hit_status = status_name
	_hit_status_duration = duration
	if status_name != "":
		set_meta("hit_status", status_name)
		set_meta("hit_status_duration", duration)

func setup_readability(variant_id: String, color: Color, source: String = "boss") -> void:
	if variant_id == "":
		return
	_readability_color = color
	set_meta("projectile_variant", variant_id)
	set_meta("projectile_color", color)
	match source:
		"enemy":
			set_meta("enemy_projectile_variant", variant_id)
			set_meta("enemy_projectile_color", color)
		_:
			set_meta("boss_projectile_variant", variant_id)
			set_meta("boss_projectile_color", color)


func _ready() -> void:
	set_meta("arrow_visual_forward_offset_rad", ARROW_VISUAL_FORWARD_OFFSET)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.0
	shape.shape = circle
	add_child(shape)

	if not _add_sprite_visual():
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(0, -2.5), Vector2(2.5, 0), Vector2(0, 2.5), Vector2(-2.5, 0),
		])
		body.color = _readability_color
		body.set_meta("sprite_fallback", "polygon")
		add_child(body)

	_sync_visual_rotation()
	z_index = 3
	body_entered.connect(_on_body_entered)

func _add_sprite_visual() -> bool:
	var sprite_name := SpriteDB.first_existing(["zerie_arrow_projectile", "weapon_arrow"])
	var frames := SpriteDB.build_sprite_frames({"idle": sprite_name})
	if frames == null:
		return false
	var sprite := AnimatedSprite2D.new()
	sprite.name = "EnemyProjectileSprite"
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.modulate = _readability_color
	sprite.z_index = 1
	sprite.play("idle")
	SpriteDB.apply_sprite_metadata(sprite, sprite_name)
	sprite.set_meta("projectile_color", _readability_color)
	add_child(sprite)
	return true

func _physics_process(delta: float) -> void:
	_sync_visual_rotation()
	var step := _dir * _speed * delta
	position += step
	_travelled += step.length()
	if _travelled >= _range:
		queue_free()

func _sync_visual_rotation() -> void:
	rotation = _dir.angle() + ARROW_VISUAL_FORWARD_OFFSET


func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		return  # friendly fire off
	if body is Player:
		body.take_damage(_damage, global_position, _damage_source_label())
		if _hit_status != "" and body.has_method("add_status"):
			body.add_status(_hit_status, _hit_status_duration)
		queue_free()
	elif body is StaticBody2D:
		queue_free()

func _damage_source_label() -> String:
	var variant_label := str(get_meta("boss_variant_attack_label", "")).strip_edges()
	if variant_label != "":
		return "Boss: %s" % variant_label
	var boss_label := str(get_meta("boss_attack_label", "")).strip_edges()
	if boss_label != "":
		return "Boss: %s" % boss_label
	var boss_attack := str(get_meta("boss_attack", "")).strip_edges()
	if boss_attack != "":
		return "Boss: %s" % boss_attack.replace("_", " ").capitalize()
	var enemy_label := str(get_meta("enemy_attack_label", "")).strip_edges()
	if enemy_label != "":
		return "Enemy: %s" % enemy_label
	var enemy_attack := str(get_meta("enemy_attack", "")).strip_edges()
	if enemy_attack != "":
		return "Enemy: %s" % enemy_attack.replace("_", " ").capitalize()
	return "Projectile"
