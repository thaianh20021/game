extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(
		PlayerClassDB.get_class_data("blade_warden"),
		"ice",
		"warden_sword"
	)
	if player.class_id != "blade_warden":
		failures.append("player class_id not applied: %s" % player.class_id)
	if not SpriteDB.has_sprite("knight_m_idle_anim"):
		failures.append("SpriteDB cannot resolve knight_m_idle_anim")
	if SpriteDB.first_existing(["knight_m_idle_anim"]) == "":
		failures.append("first_existing cannot resolve knight_m_idle_anim")
	if player._sprite == null:
		failures.append("player cached _sprite is null")
	if player._body == null:
		failures.append("player cached _body is null")
	var player_sprite := player.get_node("Sprite") as AnimatedSprite2D
	var player_body := player.get_node("Body") as Polygon2D
	if not player_sprite.visible:
		failures.append("player sprite stays hidden after apply_class")
	if player_body.visible:
		failures.append("player placeholder body stays visible after apply_class")

	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy: Enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.configure_visual("imp_idle_anim", "imp_run_anim")
	var enemy_sprite := enemy.get_node("Sprite") as AnimatedSprite2D
	var enemy_body := enemy.get_node("Body") as Polygon2D
	if not enemy_sprite.visible:
		failures.append("enemy sprite stays hidden after configure_visual")
	if enemy_body.visible:
		failures.append("enemy placeholder body stays visible after configure_visual")

	if failures.is_empty():
		print("Visual sprite smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
