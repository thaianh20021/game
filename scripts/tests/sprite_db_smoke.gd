extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	var floor_texture := SpriteDB.texture("floor_1")
	if floor_texture == null:
		failures.append("floor_1 texture missing")
	var pistol_texture := SpriteDB.texture("weapon_pistol_generated")
	if pistol_texture == null:
		failures.append("generated pistol texture missing")
	var key_texture := SpriteDB.texture("pickup_silver_key_generated")
	if key_texture == null:
		failures.append("generated silver key texture missing")
	var blueprint_texture := SpriteDB.texture("pickup_blueprint_generated")
	if blueprint_texture == null:
		failures.append("generated blueprint texture missing")
	var unknown_pickup_texture := SpriteDB.texture("pickup_unknown_generated")
	if unknown_pickup_texture == null:
		failures.append("generated unknown pickup texture missing")
	var fire_patch_texture := SpriteDB.texture("fire_patch_generated")
	if fire_patch_texture == null:
		failures.append("generated fire patch texture missing")

	var coin_frames := SpriteDB.frames("coin_anim")
	if coin_frames.size() != 4:
		failures.append("coin_anim should have 4 frames")
	var pistol_frames := SpriteDB.frames("weapon_pistol_generated")
	if pistol_frames.size() != 1:
		failures.append("generated pistol should have 1 frame")
	var key_frames := SpriteDB.frames("pickup_silver_key_generated")
	if key_frames.size() != 1:
		failures.append("generated silver key should have 1 frame")
	var blueprint_frames := SpriteDB.frames("pickup_blueprint_generated")
	if blueprint_frames.size() != 1:
		failures.append("generated blueprint should have 1 frame")
	var unknown_pickup_frames := SpriteDB.frames("pickup_unknown_generated")
	if unknown_pickup_frames.size() != 1:
		failures.append("generated unknown pickup should have 1 frame")
	var fire_patch_frames := SpriteDB.frames("fire_patch_generated")
	if fire_patch_frames.size() != 4:
		failures.append("generated fire patch should have 4 frames")
	var sprite_db := SpriteDB.new()
	if not sprite_db.has_method("animation_report"):
		failures.append("SpriteDB should expose animation_report for asset release checks")
	else:
		_check_animation_report(sprite_db, "coin_anim", 4, true, failures)
		_check_animation_report(sprite_db, "weapon_pistol_generated", 1, true, failures)
		_check_animation_report(sprite_db, "pickup_silver_key_generated", 1, true, failures)
		_check_animation_report(sprite_db, "pickup_blueprint_generated", 1, true, failures)
		_check_animation_report(sprite_db, "pickup_unknown_generated", 1, true, failures)
		_check_animation_report(sprite_db, "fire_patch_generated", 4, true, failures)
		_check_animation_report(sprite_db, "chest_full_open_anim", 3, true, failures)
		_check_animation_report(sprite_db, "bomb", 3, true, failures)
		var ladder_report: Dictionary = sprite_db.call("animation_report", "floor_ladder")
		if int(ladder_report.get("frame_count", 0)) != 1:
			failures.append("single-frame sprite report should count one frame")
		if not bool(ladder_report.get("stable_size", false)):
			failures.append("single-frame sprite should report stable frame size")

	if not sprite_db.has_method("texture_quiet"):
		failures.append("SpriteDB should expose texture_quiet for intentional missing probes")
	else:
		var missing_texture = sprite_db.call("texture_quiet", "__missing_sprite_for_smoke__")
		if missing_texture != null:
			failures.append("quiet missing sprite should return null")

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

func _check_animation_report(
		sprite_db: SpriteDB,
		sprite_name: String,
		expected_count: int,
		expected_stable: bool,
		failures: Array[String],
) -> void:
	var report: Dictionary = sprite_db.call("animation_report", sprite_name)
	if int(report.get("frame_count", 0)) != expected_count:
		failures.append("%s report should count %d frames" % [sprite_name, expected_count])
	if bool(report.get("stable_size", false)) != expected_stable:
		failures.append("%s stable_size should be %s" % [sprite_name, expected_stable])
	if Vector2(report.get("frame_size", Vector2.ZERO)) == Vector2.ZERO:
		failures.append("%s report should expose non-zero frame size" % sprite_name)
	if float(report.get("fps", 0.0)) <= 0.0:
		failures.append("%s report should expose animation fps" % sprite_name)
	var nontransparent: Array = report.get("frame_nontransparent_px", [])
	if nontransparent.size() != expected_count:
		failures.append("%s report should review non-transparent pixels for every frame" % sprite_name)
	for count in nontransparent:
		if int(count) <= 0:
			failures.append("%s report should reject empty animation frames" % sprite_name)
	if int(report.get("empty_frame_count", -1)) != 0:
		failures.append("%s report should expose zero empty frames" % sprite_name)
	var bounds: Array = report.get("frame_content_bounds_px", [])
	if bounds.size() != expected_count:
		failures.append("%s report should expose content bounds for every frame" % sprite_name)
	for raw_bounds in bounds:
		if not (raw_bounds is Rect2i):
			failures.append("%s content bounds should use Rect2i values" % sprite_name)
			continue
		var rect := raw_bounds as Rect2i
		if rect.size.x <= 0 or rect.size.y <= 0:
			failures.append("%s content bounds should be non-empty" % sprite_name)
		if rect.position.x < 0 or rect.position.y < 0:
			failures.append("%s content bounds should stay inside the frame" % sprite_name)
		var frame_size := Vector2i(Vector2(report.get("frame_size", Vector2.ZERO)))
		if rect.end.x > frame_size.x or rect.end.y > frame_size.y:
			failures.append("%s content bounds should not exceed frame size" % sprite_name)
	if not bool(report.get("content_bounds_ok", false)):
		failures.append("%s report should mark frame content bounds stable" % sprite_name)
	if report.get("origin_px", Vector2.ZERO) != Vector2(report.get("frame_size", Vector2.ZERO)) * 0.5:
		failures.append("%s report should expose centered origin_px for release review" % sprite_name)
