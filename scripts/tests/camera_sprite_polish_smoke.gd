extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame

	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		failures.append("player missing Camera2D")
	else:
		if not camera.enabled:
			failures.append("player Camera2D is disabled")
		if camera.zoom != Vector2(2.0, 2.0):
			failures.append("player Camera2D zoom should be 2x, got %s" % camera.zoom)

	if not player.has_method("configure_camera_for_room"):
		failures.append("Player missing configure_camera_for_room")
	elif camera != null:
		player.configure_camera_for_room(Rect2(Vector2(16, 32), Vector2(320, 192)))
		if camera.limit_left != 16:
			failures.append("camera limit_left not applied")
		if camera.limit_top != 32:
			failures.append("camera limit_top not applied")
		if camera.limit_right != 336:
			failures.append("camera limit_right not applied")
		if camera.limit_bottom != 224:
			failures.append("camera limit_bottom not applied")

	player.apply_class(
		PlayerClassDB.get_class_data("blade_warden"),
		"fire",
		"warden_sword"
	)
	var player_sprite := player.get_node("Sprite") as AnimatedSprite2D
	if player_sprite.scale != Vector2.ONE:
		failures.append("player sprite scale should stay 1:1")
	if absf(player_sprite.offset.x) > 0.01:
		failures.append("player sprite x offset should stay centered")
	if player_sprite.offset.y > -8.5:
		failures.append("player sprite should align feet to collision, got offset %s" % player_sprite.offset)

	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy: Enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.configure_visual("big_demon_idle_anim", "big_demon_run_anim")
	var enemy_sprite := enemy.get_node("Sprite") as AnimatedSprite2D
	if enemy_sprite.scale != Vector2.ONE:
		failures.append("enemy sprite scale should stay 1:1")
	if absf(enemy_sprite.offset.x) > 0.01:
		failures.append("enemy sprite x offset should stay centered")
	if enemy_sprite.offset.y > -9.0:
		failures.append("tall enemy sprite should align feet to collision, got offset %s" % enemy_sprite.offset)

	if failures.is_empty():
		print("Camera/sprite polish smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
