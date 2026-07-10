class_name SummonWispSkill
extends RefCounted

const ATTACK_RADIUS := 130.0
const ATTACK_INTERVAL_SECONDS := 0.8
const LIFETIME_SECONDS := 30.0
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx["scene"]
	var base_damage := int(ctx["base_damage"])
	var pet_mult := float(ctx.get("pet_damage_mult", 1.0))
	var attack_damage := maxi(1, int(base_damage * 0.7 * pet_mult))
	var element := str(ctx["element"])

	var wisp := Node2D.new()
	wisp.name = "SummonedWisp"
	wisp.set_meta("summon_type", "summon_wisp")
	wisp.set_meta("owner_id", player.get_instance_id())
	wisp.set_meta("duration_seconds", LIFETIME_SECONDS)
	wisp.set_meta("attack_radius_px", ATTACK_RADIUS)
	wisp.set_meta("attack_interval_seconds", ATTACK_INTERVAL_SECONDS)
	wisp.set_meta("pet_damage_mult", pet_mult)
	wisp.set_meta("attack_damage", attack_damage)
	wisp.add_to_group("player_summons")
	scene.add_child(wisp)
	wisp.global_position = player.global_position + Vector2(18, -10)

	if not _add_sprite_visual(wisp):
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(0, -5), Vector2(5, 0), Vector2(0, 5), Vector2(-5, 0),
		])
		body.color = Color(0.55, 0.95, 1.0, 0.9)
		body.set_meta("sprite_fallback", "polygon")
		wisp.add_child(body)

	var feedback := Label.new()
	feedback.name = "WispFeedback"
	feedback.text = "WISP 30s | DMG x%.1f" % pet_mult
	feedback.position = Vector2(-18, -22)
	feedback.add_theme_font_size_override("font_size", 7)
	wisp.add_child(feedback)

	var timer := Timer.new()
	timer.wait_time = ATTACK_INTERVAL_SECONDS
	timer.autostart = true
	var wisp_ref: WeakRef = weakref(wisp)
	var player_ref: WeakRef = weakref(player)
	timer.timeout.connect(func() -> void:
		var live_wisp := wisp_ref.get_ref() as Node2D
		var live_player := player_ref.get_ref() as Player
		if live_wisp != null and live_player != null:
			_attack_nearest(live_wisp, live_player, attack_damage, element))
	wisp.add_child(timer)
	player.get_tree().create_timer(LIFETIME_SECONDS).timeout.connect(func() -> void:
		var live_wisp := wisp_ref.get_ref() as Node2D
		if live_wisp != null:
			live_wisp.queue_free())

static func _attack_nearest(wisp: Node2D, player: Player, damage: int, element: String) -> void:
	if not is_instance_valid(wisp):
		return
	var best: Enemy = null
	var best_dist := INF
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy:
			var dist: float = enemy.global_position.distance_to(wisp.global_position)
			if dist < best_dist and dist <= ATTACK_RADIUS:
				best = enemy
				best_dist = dist
	if best != null:
		best.hit(damage, element)
		_record_attack_feedback(wisp, best, damage, element)

static func _record_attack_feedback(wisp: Node2D, target: Enemy, damage: int, element: String) -> void:
	wisp.set_meta("attack_count", int(wisp.get_meta("attack_count", 0)) + 1)
	wisp.set_meta("last_target_id", target.get_instance_id())
	wisp.set_meta("last_attack_damage", damage)
	wisp.set_meta("last_attack_element", element)
	var old := wisp.get_node_or_null("PetAttackFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "PetAttackFeedback"
	label.text = "WISP HIT -%d" % damage
	label.position = Vector2(-18, -32)
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color(0.62, 0.96, 1.0))
	label.set_meta("target_id", target.get_instance_id())
	label.set_meta("damage", damage)
	label.set_meta("element", element)
	wisp.add_child(label)
	_spawn_attack_bolt(wisp, target, damage, element)
	_play_attack_sfx(wisp, target, damage, element)

static func _spawn_attack_bolt(wisp: Node2D, target: Enemy, damage: int, element: String) -> void:
	var old := wisp.get_node_or_null("PetAttackBolt")
	if old != null:
		old.queue_free()
	var bolt := Line2D.new()
	bolt.name = "PetAttackBolt"
	bolt.points = PackedVector2Array([Vector2.ZERO, target.global_position - wisp.global_position])
	bolt.width = 2.0
	bolt.default_color = Color(0.48, 0.95, 1.0, 0.88)
	bolt.z_index = 6
	bolt.set_meta("target_id", target.get_instance_id())
	bolt.set_meta("damage", damage)
	bolt.set_meta("element", element)
	bolt.set_meta("source_policy_id", "procedural_godot_shapes")
	wisp.add_child(bolt)
	var tween := bolt.create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, 0.12)
	tween.tween_callback(Callable(bolt, "queue_free"))

static func _play_attack_sfx(wisp: Node2D, target: Enemy, damage: int, element: String) -> void:
	var cue: Dictionary = AudioCueDBScript.enemy_hit_cue("normal", element, damage)
	var sfx := wisp.get_node_or_null("PetAttackSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "PetAttackSfx"
		wisp.add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("summon_attack_sound_id", str(cue.get("id", "enemy_hit_normal")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "enemy_hit")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "enemy_hit")))
	sfx.set_meta("summon_attack_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	sfx.set_meta("target_id", target.get_instance_id())
	sfx.set_meta("damage", damage)
	sfx.set_meta("element", element)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

static func _add_sprite_visual(wisp: Node2D) -> bool:
	var sprite_name := "angel_idle_anim"
	var frames := SpriteDB.build_sprite_frames({"idle": sprite_name})
	if frames == null:
		return false
	var sprite := AnimatedSprite2D.new()
	sprite.name = "WispSprite"
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.z_index = 4
	sprite.play("idle")
	SpriteDB.apply_sprite_metadata(sprite, sprite_name)
	wisp.add_child(sprite)
	return true
