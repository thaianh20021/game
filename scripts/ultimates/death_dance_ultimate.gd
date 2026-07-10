class_name DeathDanceUltimate
extends RefCounted

const TARGET_RANGE := 170.0
const TARGET_COUNT := 5
const DAMAGE_MULT := 1.5

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx.get("scene", player)
	var origin := player.global_position
	var targets := _targets(player, origin)
	var damage := maxi(1, int(round(float(ctx["base_damage"]) * DAMAGE_MULT)))
	var element := str(ctx["element"])
	var fx := _spawn_fx(scene, origin)
	var last_pos := origin

	for target in targets:
		if not is_instance_valid(target):
			continue
		_add_slash(fx, last_pos - origin, target.global_position - origin)
		target.hit(damage, element)
		last_pos = target.global_position

	if last_pos.distance_to(origin) > 1.0:
		var aim_dir := Vector2(ctx.get("aim_dir", Vector2.RIGHT))
		if aim_dir.length_squared() <= 0.0:
			aim_dir = Vector2.RIGHT
		player.global_position = last_pos - aim_dir.normalized() * 8.0

static func _targets(player: Player, origin: Vector2) -> Array:
	var found := []
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.global_position.distance_to(origin) <= TARGET_RANGE:
			found.append(enemy)
	found.sort_custom(func(a, b) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
	return found.slice(0, mini(found.size(), TARGET_COUNT))

static func _spawn_fx(scene: Node, origin: Vector2) -> Node2D:
	var fx := Node2D.new()
	fx.name = "DeathDanceFx"
	scene.add_child(fx)
	fx.global_position = origin
	var tween := fx.create_tween()
	tween.tween_property(fx, "modulate:a", 0.0, 0.26)
	tween.tween_callback(fx.queue_free)
	return fx

static func _add_slash(fx: Node2D, from_point: Vector2, to_point: Vector2) -> void:
	var slash := Line2D.new()
	slash.name = "ShadowSlash"
	slash.points = PackedVector2Array([from_point, to_point])
	slash.width = 4.0
	slash.default_color = Color(0.62, 0.45, 0.95, 0.9)
	fx.add_child(slash)
