class_name EarthbreakerSkill
extends RefCounted

const RADIUS := 54.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx["scene"]
	var base_damage := int(ctx["base_damage"])
	var element := str(ctx["element"])
	var damage := int(base_damage * 2.0)

	_spawn_slam_fx(scene, player.global_position, damage, element)
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.global_position.distance_to(player.global_position) <= RADIUS:
			enemy.hit(damage, element)
			enemy.add_status("stun", 1.0)
	for prop in player.get_tree().get_nodes_in_group("breakable_props"):
		if prop is Node2D and prop.has_method("hit") \
				and prop.global_position.distance_to(player.global_position) <= RADIUS:
			prop.hit(damage)

static func _spawn_slam_fx(scene: Node, pos: Vector2, damage: int, element: String) -> void:
	var ring := Line2D.new()
	ring.name = "EarthbreakerFx"
	var points := PackedVector2Array()
	for i in 17:
		points.append(Vector2(RADIUS, 0).rotated(TAU * float(i) / 16.0))
	ring.points = points
	ring.width = 3.0
	ring.default_color = Color(0.8, 0.55, 0.25, 0.85)
	ring.set_meta("skill_id", "earthbreaker")
	ring.set_meta("shape", "slam_ring")
	ring.set_meta("radius_px", RADIUS)
	ring.set_meta("damage", damage)
	ring.set_meta("element", element)
	scene.add_child(ring)
	ring.global_position = pos
	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ring.queue_free)
