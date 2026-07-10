class_name NullRingSkill
extends RefCounted

const RADIUS := 72.0
const DURATION := 4.0

static func execute(ctx: Dictionary) -> void:
	var scene: Node = ctx["scene"]
	var pos := Vector2(ctx["target_position"])
	var zone := Node2D.new()
	zone.name = "NullRingZone"
	zone.set_meta("duration_seconds", DURATION)
	zone.add_to_group("player_zones")
	scene.add_child(zone)
	zone.global_position = pos
	_spawn_ring(zone)
	_show_feedback(zone)
	_slow_enemy_projectiles(scene, pos)
	var zone_ref: WeakRef = weakref(zone)
	var expire := Timer.new()
	expire.name = "NullRingExpireTimer"
	expire.wait_time = DURATION
	expire.one_shot = true
	expire.autostart = true
	expire.timeout.connect(func() -> void:
		var live_zone := zone_ref.get_ref() as Node2D
		if live_zone != null:
			live_zone.queue_free())
	zone.add_child(expire)

static func _spawn_ring(zone: Node2D) -> void:
	var ring := Line2D.new()
	ring.name = "NullRingFx"
	var points := PackedVector2Array()
	for i in 25:
		points.append(Vector2(RADIUS, 0).rotated(TAU * float(i) / 24.0))
	ring.points = points
	ring.width = 2.0
	ring.default_color = Color(0.55, 0.75, 1.0, 0.75)
	ring.set_meta("skill_id", "null_ring")
	ring.set_meta("shape", "control_ring")
	ring.set_meta("radius_px", RADIUS)
	ring.set_meta("duration_seconds", DURATION)
	ring.set_meta("effect", "projectile_slow")
	zone.add_child(ring)

static func _show_feedback(zone: Node2D) -> void:
	var label := Label.new()
	label.name = "NullRingFeedback"
	label.text = "NULL RING %.0fs" % DURATION
	label.position = Vector2(-30, -28)
	label.z_index = 9
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.65, 0.8, 1.0))
	zone.add_child(label)

static func _slow_enemy_projectiles(root: Node, pos: Vector2) -> void:
	for child in root.get_children():
		if child is EnemyProjectile and child.global_position.distance_to(pos) <= RADIUS:
			child.set("_speed", float(child.get("_speed")) * 0.5)
			child.set_meta("null_ring_slowed", true)
		_slow_enemy_projectiles(child, pos)
