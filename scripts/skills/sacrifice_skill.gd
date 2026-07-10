class_name SacrificeSkill
extends RefCounted

const RADIUS := 54.0
const MANA_RESTORE := 15.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var pet := _first_pet(player)
	if pet == null:
		return
	var pos := pet.global_position
	var element := str(ctx["element"])
	var damage := maxi(1, int(float(ctx["base_damage"]) * 1.8 * float(ctx.get("pet_damage_mult", 1.0))))
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.global_position.distance_to(pos) <= RADIUS:
			enemy.hit(damage, element)
	pet.queue_free()
	player.resource = minf(player.resource + MANA_RESTORE, player.max_resource)
	player.resource_changed.emit(player.resource, player.max_resource)
	_spawn_burst(ctx["scene"], pos, damage, element)

static func _first_pet(player: Player) -> Node2D:
	for summon in player.get_tree().get_nodes_in_group("player_summons"):
		if summon is Node2D and is_instance_valid(summon) and not summon.is_queued_for_deletion():
			return summon
	return null

static func _spawn_burst(scene: Node, pos: Vector2, damage: int, element: String) -> void:
	var ring := Line2D.new()
	ring.name = "SacrificeFx"
	var points := PackedVector2Array()
	for i in 17:
		points.append(Vector2(RADIUS, 0).rotated(TAU * float(i) / 16.0))
	ring.points = points
	ring.width = 3.0
	ring.default_color = Color(0.55, 1.0, 0.95, 0.85)
	ring.set_meta("skill_id", "sacrifice")
	ring.set_meta("shape", "sacrifice_burst")
	ring.set_meta("radius_px", RADIUS)
	ring.set_meta("damage", damage)
	ring.set_meta("mana_restore", MANA_RESTORE)
	ring.set_meta("element", element)
	scene.add_child(ring)
	ring.global_position = pos
	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.2)
	tween.tween_callback(ring.queue_free)
