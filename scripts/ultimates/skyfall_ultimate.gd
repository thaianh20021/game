class_name SkyfallUltimate
extends RefCounted

const LEAP_DISTANCE := 72.0
const SLAM_RADIUS := 46.0
const WAVE_RANGE := 96.0
const WAVE_WIDTH := 14.0
const SLAM_DAMAGE_MULT := 4.0
const WAVE_DAMAGE_MULT := 2.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx.get("scene", player)
	var aim_dir := Vector2(ctx.get("aim_dir", Vector2.RIGHT))
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	var target := Vector2(ctx.get("target_position", player.global_position + aim_dir * LEAP_DISTANCE))
	if target.distance_to(player.global_position) < 8.0:
		target = player.global_position + aim_dir * LEAP_DISTANCE
	target = player.global_position + (target - player.global_position).limit_length(LEAP_DISTANCE)

	player.global_position = target
	_spawn_skyfall_fx(scene, target)

	var base_damage := int(ctx["base_damage"])
	var element := str(ctx["element"])
	var slam_damage := maxi(1, int(round(float(base_damage) * SLAM_DAMAGE_MULT)))
	var wave_damage := maxi(1, int(round(float(base_damage) * WAVE_DAMAGE_MULT)))
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Enemy):
			continue
		if enemy.global_position.distance_to(target) <= SLAM_RADIUS:
			enemy.hit(slam_damage, element)
		elif _in_any_wave(target, enemy.global_position):
			enemy.hit(wave_damage, element)

static func _in_any_wave(origin: Vector2, point: Vector2) -> bool:
	for dir in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		if _in_wave(origin, point, dir):
			return true
	return false

static func _in_wave(origin: Vector2, point: Vector2, dir: Vector2) -> bool:
	var rel := point - origin
	var forward := rel.dot(dir)
	if forward < SLAM_RADIUS or forward > WAVE_RANGE:
		return false
	return absf(rel.cross(dir)) <= WAVE_WIDTH

static func _spawn_skyfall_fx(scene: Node, pos: Vector2) -> void:
	var fx := Node2D.new()
	fx.name = "SkyfallFx"
	scene.add_child(fx)
	fx.global_position = pos

	var ring := Line2D.new()
	ring.name = "LandingRing"
	var points := PackedVector2Array()
	for i in 21:
		points.append(Vector2(SLAM_RADIUS, 0).rotated(TAU * float(i) / 20.0))
	ring.points = points
	ring.width = 4.0
	ring.default_color = Color(0.9, 0.62, 0.28, 0.9)
	fx.add_child(ring)

	for dir in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		var wave := Line2D.new()
		wave.name = "StoneWave"
		wave.points = PackedVector2Array([dir * SLAM_RADIUS, dir * WAVE_RANGE])
		wave.width = 5.0
		wave.default_color = Color(0.72, 0.55, 0.38, 0.85)
		fx.add_child(wave)

	var tween := fx.create_tween()
	tween.tween_property(fx, "modulate:a", 0.0, 0.28)
	tween.tween_callback(fx.queue_free)
