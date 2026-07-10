class_name FortressUltimate
extends RefCounted

const DURATION := 3.0
const RADIUS := 72.0
const BLAST_DAMAGE_MULT := 2.5

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx.get("scene", player)
	player.set_meta("fortress_active", true)
	player.set_meta("fortress_blocked_damage", 0)
	_spawn_guard_fx(scene, player.global_position)
	_taunt(player)

	var base_damage := int(ctx["base_damage"])
	var element := str(ctx["element"])
	var tree := player.get_tree()
	if tree != null:
		var player_id := player.get_instance_id()
		var scene_id := scene.get_instance_id()
		tree.create_timer(DURATION).timeout.connect(func() -> void:
			_release(instance_from_id(player_id) as Player, instance_from_id(scene_id) as Node, base_damage, element))

static func _taunt(player: Player) -> void:
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.global_position.distance_to(player.global_position) <= RADIUS:
			enemy.target = player
			enemy.add_status("taunted", DURATION)

static func _release(player: Player, scene: Node, base_damage: int, element: String) -> void:
	if player == null or not is_instance_valid(player):
		return
	var blocked := int(player.get_meta("fortress_blocked_damage", 0))
	player.set_meta("fortress_active", false)
	player.set_meta("fortress_blocked_damage", 0)
	var damage := maxi(1, int(round(float(base_damage) * BLAST_DAMAGE_MULT)) + blocked)
	var origin := player.global_position
	var fx_parent := scene if is_instance_valid(scene) else player.get_tree().current_scene
	if fx_parent != null:
		_spawn_blast_fx(fx_parent, origin)
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.global_position.distance_to(origin) <= RADIUS:
			enemy.hit(damage, element)

static func _spawn_guard_fx(scene: Node, pos: Vector2) -> void:
	var ring := Line2D.new()
	ring.name = "FortressFx"
	ring.points = _circle_points(RADIUS)
	ring.width = 3.0
	ring.default_color = Color(0.55, 0.75, 1.0, 0.75)
	scene.add_child(ring)
	ring.global_position = pos
	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.2, DURATION)
	tween.tween_callback(ring.queue_free)

static func _spawn_blast_fx(scene: Node, pos: Vector2) -> void:
	var ring := Line2D.new()
	ring.name = "FortressBlastFx"
	ring.points = _circle_points(RADIUS)
	ring.width = 6.0
	ring.default_color = Color(0.8, 0.92, 1.0, 0.9)
	scene.add_child(ring)
	ring.global_position = pos
	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ring.queue_free)

static func _circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 25:
		points.append(Vector2(radius, 0).rotated(TAU * float(i) / 24.0))
	return points
