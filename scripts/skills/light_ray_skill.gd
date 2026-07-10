class_name LightRaySkill
extends RefCounted

const RANGE := 135.0
const WIDTH := 12.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx["scene"]
	var aim_dir := Vector2(ctx["aim_dir"])
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	var base_damage := int(ctx["base_damage"])
	var damage := int(base_damage * 1.1)
	_spawn_ray_fx(scene, player.global_position, aim_dir, damage, "lightning")
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and _in_ray(player.global_position, enemy.global_position, aim_dir):
			enemy.hit(damage, "lightning")
			enemy.add_status("stun", 0.35)

static func _in_ray(origin: Vector2, point: Vector2, dir: Vector2) -> bool:
	var rel := point - origin
	var forward := rel.dot(dir)
	if forward < 0.0 or forward > RANGE:
		return false
	return absf(rel.cross(dir)) <= WIDTH

static func _spawn_ray_fx(scene: Node, origin: Vector2, dir: Vector2, damage: int, element: String) -> void:
	var ray := Line2D.new()
	ray.name = "LightRayFx"
	ray.points = PackedVector2Array([Vector2.ZERO, dir * RANGE])
	ray.width = 4.0
	ray.default_color = Color(1.0, 0.95, 0.45, 0.9)
	ray.set_meta("skill_id", "light_ray")
	ray.set_meta("shape", "aim_ray")
	ray.set_meta("range_px", RANGE)
	ray.set_meta("width_px", WIDTH)
	ray.set_meta("damage", damage)
	ray.set_meta("element", element)
	scene.add_child(ray)
	ray.global_position = origin
	var tween := ray.create_tween()
	tween.tween_property(ray, "modulate:a", 0.0, 0.18)
	tween.tween_callback(ray.queue_free)
