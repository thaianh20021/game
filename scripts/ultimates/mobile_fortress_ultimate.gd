class_name MobileFortressUltimate
extends RefCounted

const DURATION := 8.0
const SPEED_MULT := 0.7
const CANNON_SPEED := 230.0
const CANNON_RANGE := 170.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx.get("scene", player)
	var aim_dir := Vector2(ctx.get("aim_dir", Vector2.RIGHT))
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	if not bool(player.get_meta("mobile_fortress_active", false)):
		player.set_meta("mobile_fortress_base_speed", player.move_speed)
	player.set_meta("mobile_fortress_active", true)
	player.move_speed = float(player.get_meta("mobile_fortress_base_speed", player.move_speed)) * SPEED_MULT
	_spawn_fx(scene, player.global_position)
	_fire_cannons(scene, player, aim_dir, int(ctx["base_damage"]), str(ctx["element"]))
	var tree := player.get_tree()
	if tree != null:
		var player_id := player.get_instance_id()
		tree.create_timer(DURATION).timeout.connect(func() -> void:
			var p := instance_from_id(player_id) as Player
			if p != null:
				p.set_meta("mobile_fortress_active", false)
				p.move_speed = float(p.get_meta("mobile_fortress_base_speed", p.move_speed)))

static func _fire_cannons(scene: Node, player: Player, dir: Vector2, damage: int, element: String) -> void:
	var side := dir.orthogonal()
	for offset in [-7.0, 7.0]:
		var projectile := Projectile.new()
		projectile.setup(dir, CANNON_SPEED, maxi(1, damage), CANNON_RANGE,
			Color(0.8, 0.92, 1.0), element, player, 1)
		scene.add_child(projectile)
		projectile.global_position = player.global_position + dir * 10.0 + side * offset

static func _spawn_fx(scene: Node, pos: Vector2) -> void:
	var fx := Line2D.new()
	fx.name = "MobileFortressFx"
	fx.points = PackedVector2Array([
		Vector2(-14, -14), Vector2(14, -14), Vector2(14, 14),
		Vector2(-14, 14), Vector2(-14, -14),
	])
	fx.width = 3.0
	fx.default_color = Color(0.65, 0.9, 1.0, 0.75)
	scene.add_child(fx)
	fx.global_position = pos
