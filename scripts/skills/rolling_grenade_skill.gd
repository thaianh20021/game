class_name RollingGrenadeSkill
extends RefCounted

const RADIUS := 44.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx["scene"]
	var target_pos := Vector2(ctx["target_position"])
	var base_damage := int(ctx["base_damage"])

	var grenade := _make_grenade_visual()
	scene.add_child(grenade)
	grenade.global_position = target_pos
	grenade.rotation = randf() * TAU

	var player_ref: WeakRef = weakref(player)
	var grenade_ref: WeakRef = weakref(grenade)
	var element := str(ctx["element"])
	player.get_tree().create_timer(0.3).timeout.connect(func() -> void:
		var live_grenade := grenade_ref.get_ref() as Node
		if live_grenade != null:
			live_grenade.queue_free()
		var live_player := player_ref.get_ref() as Player
		if live_player == null:
			return
		_explode(live_player, target_pos, int(base_damage * 1.5), element))

static func _make_grenade_visual() -> Node2D:
	var frames := SpriteDB.build_sprite_frames({"idle": "bomb"})
	if frames != null:
		var sprite := AnimatedSprite2D.new()
		sprite.name = "RollingGrenade"
		sprite.sprite_frames = frames
		sprite.centered = true
		sprite.scale = Vector2.ONE * 1.25
		sprite.z_index = 8
		sprite.play("idle")
		SpriteDB.apply_sprite_metadata(sprite, "bomb")
		return sprite

	var grenade := Polygon2D.new()
	grenade.name = "RollingGrenade"
	grenade.polygon = PackedVector2Array([
		Vector2(0, -5), Vector2(5, 0), Vector2(0, 5), Vector2(-5, 0),
	])
	grenade.color = Color(0.25, 0.85, 0.35, 0.95)
	grenade.set_meta("sprite_fallback", "polygon")
	return grenade

static func _explode(player: Player, pos: Vector2, damage: int, element: String) -> void:
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.global_position.distance_to(pos) <= RADIUS:
			enemy.hit(damage, element)
