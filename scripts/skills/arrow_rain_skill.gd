class_name ArrowRainSkill
extends RefCounted

const RADIUS := 42.0
const DELAY_SECONDS := 0.5

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx["scene"]
	var zone_center := Vector2(ctx["target_position"])
	var base_damage := int(ctx["base_damage"])
	var element := str(ctx["element"])
	_spawn_telegraph(scene, zone_center, element)
	var player_ref: WeakRef = weakref(player)
	player.get_tree().create_timer(DELAY_SECONDS).timeout.connect(func() -> void:
		var live_player := player_ref.get_ref() as Player
		if live_player == null:
			return
		for enemy in live_player.get_tree().get_nodes_in_group("enemies"):
			if enemy is Enemy and is_instance_valid(enemy) \
					and enemy.global_position.distance_to(zone_center) <= RADIUS:
				enemy.hit(int(base_damage * 1.6), element))

static func _spawn_telegraph(scene: Node, pos: Vector2, element: String) -> void:
	var ring := Line2D.new()
	ring.name = "ArrowRainTelegraph"
	var points := PackedVector2Array()
	for i in 17:
		points.append(Vector2(RADIUS, 0).rotated(TAU * float(i) / 16.0))
	ring.points = points
	ring.width = 2.0
	ring.default_color = Color(0.56, 0.9, 0.42, 0.82)
	ring.set_meta("skill_id", "arrow_rain")
	ring.set_meta("shape", "impact_zone")
	ring.set_meta("radius_px", RADIUS)
	ring.set_meta("delay_seconds", DELAY_SECONDS)
	ring.set_meta("element", element)
	scene.add_child(ring)
	ring.global_position = pos
	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.25, DELAY_SECONDS)
	tween.tween_callback(ring.queue_free)
