extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	var floor_texture := SpriteDB.texture("floor_1")
	if floor_texture == null:
		failures.append("floor_1 texture missing")

	var coin_frames := SpriteDB.frames("coin_anim")
	if coin_frames.size() != 4:
		failures.append("coin_anim should have 4 frames")

	var missing_texture := SpriteDB.texture("__missing_sprite_for_smoke__")
	if missing_texture != null:
		failures.append("missing sprite should return null")

	var sprite_frames := SpriteDB.build_sprite_frames({
		"idle": "knight_m_idle_anim",
		"run": "knight_m_run_anim",
	})
	if sprite_frames == null:
		failures.append("SpriteFrames build returned null")
	else:
		if not sprite_frames.has_animation("idle"):
			failures.append("idle animation missing")
		if not sprite_frames.has_animation("run"):
			failures.append("run animation missing")
		if sprite_frames.get_frame_count("idle") != 4:
			failures.append("idle should have 4 frames")

	if failures.is_empty():
		print("SpriteDB smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
