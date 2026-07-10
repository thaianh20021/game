class_name LungeSkill
extends RefCounted

const DISTANCE := 64.0
const LANE_WIDTH := 12.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var aim_dir := Vector2(ctx["aim_dir"])
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	var start := player.global_position
	var end := start + aim_dir * DISTANCE
	var damage := maxi(1, int(float(ctx["base_damage"]) * 0.9))
	player.global_position = end
	player.set("_iframes_left", maxf(float(player.get("_iframes_left")), 0.18))
	_spawn_trail_fx(ctx["scene"], start, end, damage, str(ctx["element"]))
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and _distance_to_segment(enemy.global_position, start, end) <= LANE_WIDTH:
			if enemy.has_method("hit_from"):
				enemy.hit_from(damage, str(ctx["element"]), start)
			else:
				enemy.hit(damage, str(ctx["element"]))

static func _spawn_trail_fx(scene: Node, start: Vector2, end: Vector2, damage: int, element: String) -> void:
	var trail := Line2D.new()
	trail.name = "LungeTrailFx"
	trail.points = PackedVector2Array([start, end])
	trail.width = 4.0
	trail.default_color = Color(0.8, 0.95, 1.0, 0.72)
	trail.set_meta("skill_id", "lunge")
	trail.set_meta("shape", "dash_trail")
	trail.set_meta("distance_px", DISTANCE)
	trail.set_meta("lane_width_px", LANE_WIDTH)
	trail.set_meta("damage", damage)
	trail.set_meta("element", element)
	scene.add_child(trail)
	var tween := trail.create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.16)
	tween.tween_callback(trail.queue_free)

static func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	if segment.length_squared() <= 0.0:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * t)
