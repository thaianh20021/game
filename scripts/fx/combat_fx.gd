class_name CombatFx
extends RefCounted

static func spawn_slash(
		parent: Node,
		origin: Vector2,
		dir: Vector2,
		color: Color = Color(1.0, 0.92, 0.55, 0.9)) -> Node2D:
	var fx := _root(parent, "CombatFxSlash", origin, dir)
	var arc := Line2D.new()
	arc.points = PackedVector2Array([
		Vector2(2, -9),
		Vector2(12, -5),
		Vector2(18, 0),
		Vector2(12, 5),
		Vector2(2, 9),
	])
	arc.width = 3.0
	arc.default_color = color
	fx.add_child(arc)
	_lifetime(fx, 0.18, 1.18)
	return fx

static func spawn_muzzle_flash(
		parent: Node,
		origin: Vector2,
		dir: Vector2,
		color: Color = Color(1.0, 0.84, 0.34, 0.9)) -> Node2D:
	var fx := _root(parent, "CombatFxMuzzleFlash", origin, dir)
	var flash := Polygon2D.new()
	flash.polygon = PackedVector2Array([
		Vector2(0, -3),
		Vector2(13, 0),
		Vector2(0, 3),
		Vector2(4, 0),
	])
	flash.color = color
	fx.add_child(flash)
	_lifetime(fx, 0.12, 1.35)
	return fx

static func spawn_dash_ghost(
		parent: Node,
		source_sprite: AnimatedSprite2D,
		origin: Vector2,
		flip_h: bool = false,
		color: Color = Color(0.55, 0.85, 1.0, 0.36)) -> Node2D:
	var fx := _root(parent, "CombatFxDashGhost", origin, Vector2.RIGHT)
	if source_sprite != null and source_sprite.sprite_frames != null and source_sprite.visible:
		var texture := source_sprite.sprite_frames.get_frame_texture(
			source_sprite.animation, source_sprite.frame)
		if texture != null:
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.offset = source_sprite.offset
			sprite.scale = source_sprite.scale
			sprite.flip_h = flip_h
			sprite.modulate = color
			fx.add_child(sprite)
	if fx.get_child_count() == 0:
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(-5, -5),
			Vector2(5, -5),
			Vector2(5, 5),
			Vector2(-5, 5),
		])
		body.color = color
		fx.add_child(body)
	_lifetime(fx, 0.22, 1.08)
	return fx

static func spawn_telegraph(
		parent: Node,
		origin: Vector2,
		dir: Vector2,
		radius: float,
		duration: float,
		color: Color = Color(1.0, 0.24, 0.18, 0.6)) -> Node2D:
	var fx := _root(parent, "CombatFxTelegraph", origin, dir)
	var ring := Line2D.new()
	var points := PackedVector2Array()
	for i in 33:
		var angle := TAU * float(i) / 32.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
	ring.width = 1.5
	ring.default_color = color
	fx.add_child(ring)
	if dir.length_squared() > 0.0:
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2.ZERO, Vector2(radius, 0)])
		line.width = 1.0
		line.default_color = color
		fx.add_child(line)
	_lifetime(fx, maxf(duration, 0.08), 1.04)
	return fx

static func _root(parent: Node, node_name: String, origin: Vector2, dir: Vector2) -> Node2D:
	var fx := Node2D.new()
	fx.name = node_name
	parent.add_child(fx)
	fx.global_position = origin
	if dir.length_squared() > 0.0:
		fx.rotation = dir.angle()
	return fx

static func _lifetime(fx: Node2D, seconds: float, end_scale: float) -> void:
	var tween := fx.create_tween()
	tween.tween_property(fx, "scale", Vector2.ONE * end_scale, seconds)
	tween.parallel().tween_property(fx, "modulate:a", 0.0, seconds)
	tween.tween_callback(fx.queue_free)
