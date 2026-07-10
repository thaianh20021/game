class_name SuppressingFireUltimate
extends RefCounted

const DURATION := 5.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx.get("scene", player)
	player.set_meta("suppressing_fire_active", true)
	player.set_meta("suppressing_fire_homing", true)
	_spawn_fx(scene, player.global_position, Vector2(ctx.get("aim_dir", Vector2.RIGHT)))
	var tree := player.get_tree()
	if tree != null:
		var player_id := player.get_instance_id()
		tree.create_timer(DURATION).timeout.connect(func() -> void:
			var p := instance_from_id(player_id) as Player
			if p != null:
				p.set_meta("suppressing_fire_active", false)
				p.set_meta("suppressing_fire_homing", false))

static func _spawn_fx(scene: Node, pos: Vector2, dir: Vector2) -> void:
	if dir.length_squared() <= 0.0:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	var fx := Node2D.new()
	fx.name = "SuppressingFireFx"
	scene.add_child(fx)
	fx.global_position = pos
	for i in 5:
		var line := Line2D.new()
		line.name = "BarrageLine"
		var spread := dir.rotated(deg_to_rad(-16.0 + float(i) * 8.0))
		line.points = PackedVector2Array([Vector2.ZERO, spread * 68.0])
		line.width = 2.0
		line.default_color = Color(1.0, 0.78, 0.34, 0.8)
		fx.add_child(line)
	var tween := fx.create_tween()
	tween.tween_property(fx, "modulate:a", 0.0, 0.25)
	tween.tween_callback(fx.queue_free)
