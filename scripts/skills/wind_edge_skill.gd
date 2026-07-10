class_name WindEdgeSkill
extends RefCounted

const RADIUS := 38.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx["scene"]
	var base_damage := int(ctx["base_damage"])
	var element := str(ctx["element"])
	var damage := int(base_damage * 1.3)
	_spawn_slash_fx(scene, player.global_position, Vector2(ctx.get("aim_dir", Vector2.RIGHT)), damage, element)
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy \
				and enemy.global_position.distance_to(player.global_position) <= RADIUS:
			enemy.hit(damage, element)

static func _spawn_slash_fx(
		scene: Node,
		pos: Vector2,
		aim_dir: Vector2,
		damage: int,
		element: String,
) -> void:
	var arc := Line2D.new()
	arc.name = "WindEdgeFx"
	var dir := aim_dir.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var start_angle := dir.angle() - PI * 0.45
	var points := PackedVector2Array()
	for i in 9:
		points.append(Vector2(RADIUS, 0).rotated(start_angle + PI * 0.9 * float(i) / 8.0))
	arc.points = points
	arc.width = 3.0
	arc.default_color = Color(0.78, 0.95, 1.0, 0.86)
	arc.set_meta("skill_id", "wind_edge")
	arc.set_meta("shape", "slash_arc")
	arc.set_meta("radius_px", RADIUS)
	arc.set_meta("damage", damage)
	arc.set_meta("element", element)
	scene.add_child(arc)
	arc.global_position = pos
	var tween := arc.create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.18)
	tween.tween_callback(arc.queue_free)
