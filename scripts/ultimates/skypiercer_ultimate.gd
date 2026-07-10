class_name SkypiercerUltimate
extends RefCounted

const BACK_SWEEP := 18.0
const RANGE := 240.0
const WIDTH := 18.0
const PROJECTILE_DRAG_WIDTH := 36.0
const DAMAGE_MULT := 5.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx.get("scene", player)
	var aim_dir := Vector2(ctx.get("aim_dir", Vector2.RIGHT))
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	var origin := player.global_position
	var damage := maxi(1, int(round(float(ctx["base_damage"]) * DAMAGE_MULT)))
	var element := str(ctx["element"])

	_spawn_arrow_fx(scene, origin, aim_dir)
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and _in_lane(origin, enemy.global_position, aim_dir, WIDTH):
			enemy.hit(damage, element)
	_drag_enemy_projectiles(scene, origin, aim_dir)

static func _in_lane(origin: Vector2, point: Vector2, dir: Vector2, width: float) -> bool:
	var rel := point - origin
	var forward := rel.dot(dir)
	if forward < -BACK_SWEEP or forward > RANGE:
		return false
	return absf(rel.cross(dir)) <= width

static func _drag_enemy_projectiles(node: Node, origin: Vector2, dir: Vector2) -> void:
	for child in node.get_children():
		if child is EnemyProjectile:
			_drag_projectile(child, origin, dir)
		_drag_enemy_projectiles(child, origin, dir)

static func _drag_projectile(projectile: EnemyProjectile, origin: Vector2, dir: Vector2) -> void:
	var rel := projectile.global_position - origin
	var forward := rel.dot(dir)
	if forward < -BACK_SWEEP or forward > RANGE:
		return
	var side := dir.orthogonal()
	var lateral := rel.dot(side)
	if absf(lateral) > PROJECTILE_DRAG_WIDTH:
		return
	var clamped_lateral := clampf(lateral * 0.18, -WIDTH * 0.4, WIDTH * 0.4)
	projectile.global_position = origin + dir * minf(forward + 18.0, RANGE) + side * clamped_lateral
	projectile.set_meta("skypiercer_dragged", true)

static func _spawn_arrow_fx(scene: Node, origin: Vector2, dir: Vector2) -> void:
	var fx := Line2D.new()
	fx.name = "SkypiercerFx"
	fx.points = PackedVector2Array([-dir * BACK_SWEEP, dir * RANGE])
	fx.width = 8.0
	fx.default_color = Color(0.6, 0.95, 0.78, 0.95)
	scene.add_child(fx)
	fx.global_position = origin
	var tween := fx.create_tween()
	tween.tween_property(fx, "width", 2.0, 0.2)
	tween.parallel().tween_property(fx, "modulate:a", 0.0, 0.2)
	tween.tween_callback(fx.queue_free)
