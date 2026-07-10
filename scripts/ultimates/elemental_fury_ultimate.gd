class_name ElementalFuryUltimate
extends RefCounted

const STRIKE_COUNT := 12
const DURATION := 3.0
const STRIKE_RADIUS := 28.0
const SPREAD_RADIUS := 22.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx.get("scene", player)
	var target := Vector2(ctx.get("target_position", player.global_position))
	var damage := maxi(1, int(ctx["base_damage"]))
	var element := str(ctx["element"])
	var fx := Node2D.new()
	fx.name = "ElementalFuryFx"
	scene.add_child(fx)
	fx.global_position = target

	_strike(player, scene, fx, target, damage, element)
	var tree := player.get_tree()
	if tree == null:
		return
	for i in range(1, STRIKE_COUNT):
		var strike_pos := target + _strike_offset(i)
		_schedule_strike(tree, player, scene, fx, strike_pos,
			float(i) * DURATION / float(STRIKE_COUNT - 1), damage, element)
	var fx_id := fx.get_instance_id()
	tree.create_timer(DURATION + 0.35).timeout.connect(func() -> void:
		var node := instance_from_id(fx_id) as Node
		if node != null:
			node.queue_free())

static func _schedule_strike(
		tree: SceneTree,
		player: Player,
		scene: Node,
		fx: Node2D,
		pos: Vector2,
		delay: float,
		damage: int,
		element: String,
) -> void:
	var player_id := player.get_instance_id()
	var scene_id := scene.get_instance_id()
	var fx_id := fx.get_instance_id()
	tree.create_timer(delay).timeout.connect(func() -> void:
		var p := instance_from_id(player_id) as Player
		var s := instance_from_id(scene_id) as Node
		var f := instance_from_id(fx_id) as Node2D
		if p != null and s != null and f != null:
			_strike(p, s, f, pos, damage, element))

static func _strike(player: Player, _scene: Node, fx: Node2D, pos: Vector2, damage: int, element: String) -> void:
	var marker := Line2D.new()
	marker.name = "FuryStrike"
	marker.points = _circle_points(STRIKE_RADIUS)
	marker.width = 2.0
	marker.default_color = _element_color(element)
	fx.add_child(marker)
	marker.global_position = pos
	var tween := marker.create_tween()
	tween.tween_property(marker, "modulate:a", 0.0, 0.2)
	tween.tween_callback(marker.queue_free)

	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.global_position.distance_to(pos) <= STRIKE_RADIUS:
			enemy.hit(damage, element)

static func _strike_offset(index: int) -> Vector2:
	var angle := TAU * float(index) / float(STRIKE_COUNT - 1)
	var radius := SPREAD_RADIUS * (0.45 + 0.55 * float((index % 3) + 1) / 3.0)
	return Vector2(radius, 0).rotated(angle)

static func _circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 17:
		points.append(Vector2(radius, 0).rotated(TAU * float(i) / 16.0))
	return points

static func _element_color(element: String) -> Color:
	match element:
		"fire":
			return Color(1.0, 0.45, 0.18, 0.88)
		"ice":
			return Color(0.45, 0.82, 1.0, 0.88)
		"lightning":
			return Color(1.0, 0.95, 0.35, 0.88)
		"poison":
			return Color(0.45, 1.0, 0.45, 0.88)
	return Color(0.85, 0.65, 1.0, 0.88)
