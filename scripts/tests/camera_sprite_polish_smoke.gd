extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame

	if str(ProjectSettings.get_setting("display/window/stretch/mode", "")) != "viewport":
		failures.append("project should stretch the low-res viewport to the debug window")
	if str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) != "keep":
		failures.append("project should keep 16:9 stretch aspect")
	if str(ProjectSettings.get_setting("display/window/stretch/scale_mode", "")) != "fractional":
		failures.append("project should use fractional stretch scale so 1280x720 debug windows do not fall back to 1x")
	if not is_equal_approx(float(ProjectSettings.get_setting("display/window/stretch/scale", 1.0)), 1.0):
		failures.append("project stretch scale should stay 1.0; the 1280x720 window provides the 2x upscale")

	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		failures.append("player missing Camera2D")
	else:
		if not camera.enabled:
			failures.append("player Camera2D is disabled")
		if camera.zoom != Vector2(2.2, 2.2):
			failures.append("player Camera2D zoom should sit slightly closer for readable class sprites, got %s" % camera.zoom)
		var standard_room := Vector2(14.0 * 16.0, 10.0 * 16.0)
		var viewport := Vector2(640.0, 360.0)
		if standard_room.y * camera.zoom.y / viewport.y < 0.9:
			failures.append("standard rooms should fill enough vertical screen space for readable playtests")
		if standard_room.x * camera.zoom.x / viewport.x < 0.75:
			failures.append("standard rooms should fill enough horizontal screen space for readable playtests")

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
		player.on_hit_landed()
		if not bool(camera.get_meta("camera_impact_active", false)):
			failures.append("weapon hit should pulse camera impact feedback")
		if str(camera.get_meta("camera_impact_source", "")) != "weapon_hit":
			failures.append("camera impact should tag weapon hit source")
		if float(camera.get_meta("camera_impact_strength", 0.0)) <= 0.0:
			failures.append("camera impact should store non-zero strength")
		if camera.offset.length() <= 0.0:
			failures.append("camera impact should move camera offset briefly")
		await create_timer(0.08, true, false, true).timeout
		if camera.offset != Vector2.ZERO:
			failures.append("camera impact should restore camera offset")
		if bool(camera.get_meta("camera_impact_active", true)):
			failures.append("camera impact should clear active metadata after restore")
		Engine.time_scale = 1.0

	player.apply_class(
		PlayerClassDB.get_class_data("blade_warden"),
		"fire",
		"warden_sword"
	)
	var player_sprite := player.get_node("Sprite") as AnimatedSprite2D
	var player_content_height := _sprite_content_height(player_sprite)
	if player_content_height < 30.5 or player_content_height > 32.5:
		failures.append("player sprite visible height should stay readable and class-normalized, got %.2f" % player_content_height)
	var player_camera_height := player_content_height * camera.zoom.y if camera != null else 0.0
	if player_camera_height < 66.0 or player_camera_height > 74.0:
		failures.append("player camera-space height should be readable without over-zooming, got %.2f" % player_camera_height)
	if absf(player_sprite.offset.x) > 0.01:
		failures.append("player sprite x offset should stay centered")
	if player_sprite.offset.y < -24.0 or player_sprite.offset.y > -6.0:
		failures.append("player sprite should align manifest origin to collision feet, got offset %s" % player_sprite.offset)

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
		await _check_debug_window_scale(failures)

	if failures.is_empty():
		print("Camera/sprite polish smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _sprite_content_height(sprite: AnimatedSprite2D) -> float:
	if sprite == null or sprite.sprite_frames == null:
		return 0.0
	var texture := sprite.sprite_frames.get_frame_texture("idle", 0)
	if texture == null:
		return 0.0
	var image := texture.get_image()
	if image == null or image.is_empty():
		return 0.0
	var min_y := image.get_height()
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= 0.01:
				continue
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)
	return 0.0 if max_y < min_y else float(max_y - min_y + 1) * sprite.scale.y

func _check_debug_window_scale(failures: Array[String]) -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	if not main.has_method("_apply_debug_window_scale"):
		failures.append("main should force the debug window to scale the 640x360 viewport")
	else:
		var state: Dictionary = main.call("_apply_debug_window_scale", true)
		if state.get("window_size", Vector2i.ZERO) != Vector2i(1280, 720):
			failures.append("debug window should target 1280x720, got %s" % state.get("window_size", Vector2i.ZERO))
		if state.get("content_scale_size", Vector2i.ZERO) != Vector2i(640, 360):
			failures.append("debug content scale should keep the gameplay viewport at 640x360 before window upscale, got %s" % state.get("content_scale_size", Vector2i.ZERO))
		if int(state.get("content_scale_mode", -1)) != Window.CONTENT_SCALE_MODE_VIEWPORT:
			failures.append("debug window should use viewport content scaling")
		if int(state.get("content_scale_aspect", -1)) != Window.CONTENT_SCALE_ASPECT_KEEP:
			failures.append("debug window should preserve 16:9 aspect")
		if not is_equal_approx(float(state.get("content_scale_factor", 0.0)), 1.0):
			failures.append("debug content scale factor should stay 1.0 so the 640x360 viewport fills the 1280x720 window, got %.2f" % float(state.get("content_scale_factor", 0.0)))
		if not bool(state.get("dry_run", false)):
			failures.append("debug window scale dry-run should mark dry_run")
	main.queue_free()
