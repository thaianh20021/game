class_name PhantomSlashUltimate
extends RefCounted

const RANGE := 120.0
const WIDTH := 16.0
const HIT_COUNT := 3
const DAMAGE_MULT := 0.8

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var aim_dir := Vector2(ctx["aim_dir"])
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	var base_damage := int(ctx["base_damage"])
	var element := str(ctx["element"])
	_spawn_line_fx(ctx.get("scene", player), player.global_position, aim_dir)
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and _in_line(player.global_position, enemy.global_position, aim_dir):
			for _hit in HIT_COUNT:
				enemy.hit(maxi(1, int(base_damage * DAMAGE_MULT)), element)
	player.global_position += aim_dir * 64.0

static func _in_line(origin: Vector2, point: Vector2, dir: Vector2) -> bool:
	var rel := point - origin
	var forward := rel.dot(dir)
	if forward < 0.0 or forward > RANGE:
		return false
	return absf(rel.cross(dir)) <= WIDTH

static func _spawn_line_fx(scene: Node, origin: Vector2, dir: Vector2) -> void:
	var line := Line2D.new()
	line.name = "PhantomSlashFx"
	line.points = PackedVector2Array([Vector2.ZERO, dir * RANGE])
	line.width = 5.0
	line.default_color = Color(0.65, 0.9, 1.0, 0.9)
	scene.add_child(line)
	line.global_position = origin
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.18)
	tween.tween_callback(line.queue_free)
