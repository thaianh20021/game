class_name VerdictUltimate
extends RefCounted

const RADIUS := 52.0
const DAMAGE_MULT := 3.0
const STUN_DURATION := 1.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx.get("scene", player)
	var target := Vector2(ctx.get("target_position", player.global_position))
	var damage := maxi(1, int(round(float(ctx["base_damage"]) * DAMAGE_MULT)))
	var element := str(ctx["element"])
	_spawn_fx(scene, target)
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.global_position.distance_to(target) <= RADIUS:
			enemy.hit(damage, element)
			if is_instance_valid(enemy):
				enemy.add_status("stun", STUN_DURATION)
	_clear_zones(player, target)

static func _clear_zones(player: Player, target: Vector2) -> void:
	for group_name in ["poison_zones", "curse_zones"]:
		for zone in player.get_tree().get_nodes_in_group(group_name):
			if zone is Node2D and zone.global_position.distance_to(target) <= RADIUS:
				zone.queue_free()

static func _spawn_fx(scene: Node, pos: Vector2) -> void:
	var fx := Line2D.new()
	fx.name = "VerdictFx"
	fx.points = PackedVector2Array([Vector2(0, -56), Vector2.ZERO, Vector2(0, 56)])
	fx.width = 10.0
	fx.default_color = Color(1.0, 0.94, 0.5, 0.9)
	scene.add_child(fx)
	fx.global_position = pos
	var tween := fx.create_tween()
	tween.tween_property(fx, "modulate:a", 0.0, 0.28)
	tween.tween_callback(fx.queue_free)
