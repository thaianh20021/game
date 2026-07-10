class_name MiniTurretSkill
extends RefCounted

const ATTACK_RADIUS := 160.0
const ATTACK_INTERVAL_SECONDS := 0.65
const LIFETIME_SECONDS := 15.0
const MAX_TURRETS := 2
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx["scene"]
	var aim_dir := Vector2(ctx["aim_dir"])
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	var base_damage := int(ctx["base_damage"])
	var pet_mult := float(ctx.get("pet_damage_mult", 1.0))
	var attack_damage := maxi(1, int(base_damage * 0.55 * pet_mult))
	var element := str(ctx["element"])

	_trim_old_turrets(scene, player)
	var turret := Node2D.new()
	turret.name = "MiniTurret"
	turret.set_meta("summon_type", "mini_turret")
	turret.set_meta("owner_id", player.get_instance_id())
	turret.set_meta("duration_seconds", LIFETIME_SECONDS)
	turret.set_meta("attack_radius_px", ATTACK_RADIUS)
	turret.set_meta("attack_interval_seconds", ATTACK_INTERVAL_SECONDS)
	turret.set_meta("pet_damage_mult", pet_mult)
	turret.set_meta("attack_damage", attack_damage)
	turret.add_to_group("player_summons")
	scene.add_child(turret)
	turret.global_position = player.global_position + aim_dir * 20.0

	if not _add_sprite_visual(turret):
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(-6, -5), Vector2(6, -5), Vector2(7, 4), Vector2(-7, 4),
		])
		body.color = Color(0.95, 0.7, 0.28, 0.95)
		body.set_meta("sprite_fallback", "polygon")
		turret.add_child(body)

	var feedback := Label.new()
	feedback.name = "TurretFeedback"
	feedback.text = "TURRET 15s | DMG x%.1f" % pet_mult
	feedback.position = Vector2(-24, -24)
	feedback.add_theme_font_size_override("font_size", 7)
	turret.add_child(feedback)

	var timer := Timer.new()
	timer.wait_time = ATTACK_INTERVAL_SECONDS
	timer.autostart = true
	var turret_ref: WeakRef = weakref(turret)
	var player_ref: WeakRef = weakref(player)
	timer.timeout.connect(func() -> void:
		var live_turret := turret_ref.get_ref() as Node2D
		var live_player := player_ref.get_ref() as Player
		if live_turret != null and live_player != null:
			_attack_nearest(live_turret, live_player, attack_damage, element))
	turret.add_child(timer)
	player.get_tree().create_timer(LIFETIME_SECONDS).timeout.connect(func() -> void:
		var live_turret := turret_ref.get_ref() as Node2D
		if live_turret != null:
			live_turret.queue_free())

static func _trim_old_turrets(scene: Node, player: Player) -> void:
	var turrets: Array[Node] = []
	for child in scene.get_children():
		if child.is_in_group("player_summons") \
				and str(child.get_meta("summon_type", "")) == "mini_turret" \
				and int(child.get_meta("owner_id", player.get_instance_id())) == player.get_instance_id():
			turrets.append(child)
	while turrets.size() >= MAX_TURRETS:
		var oldest: Node = turrets.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

static func _attack_nearest(turret: Node2D, player: Player, damage: int, element: String) -> void:
	if not is_instance_valid(turret):
		return
	var best: Enemy = null
	var best_dist := INF
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy:
			var dist: float = enemy.global_position.distance_to(turret.global_position)
			if dist < best_dist and dist <= ATTACK_RADIUS:
				best = enemy
				best_dist = dist
	if best != null:
		best.hit(damage, element)
		_record_attack_feedback(turret, best, damage, element)

static func _record_attack_feedback(turret: Node2D, target: Enemy, damage: int, element: String) -> void:
	turret.set_meta("attack_count", int(turret.get_meta("attack_count", 0)) + 1)
	turret.set_meta("last_target_id", target.get_instance_id())
	turret.set_meta("last_attack_damage", damage)
	turret.set_meta("last_attack_element", element)
	var old := turret.get_node_or_null("TurretAttackFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "TurretAttackFeedback"
	label.text = "TURRET HIT -%d" % damage
	label.position = Vector2(-22, -34)
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42))
	label.set_meta("target_id", target.get_instance_id())
	label.set_meta("damage", damage)
	label.set_meta("element", element)
	turret.add_child(label)
	_spawn_attack_bolt(turret, target, damage, element)
	_play_attack_sfx(turret, target, damage, element)

static func _spawn_attack_bolt(turret: Node2D, target: Enemy, damage: int, element: String) -> void:
	var old := turret.get_node_or_null("TurretAttackBolt")
	if old != null:
		old.queue_free()
	var bolt := Line2D.new()
	bolt.name = "TurretAttackBolt"
	bolt.points = PackedVector2Array([Vector2.ZERO, target.global_position - turret.global_position])
	bolt.width = 2.5
	bolt.default_color = Color(1.0, 0.78, 0.25, 0.9)
	bolt.z_index = 6
	bolt.set_meta("target_id", target.get_instance_id())
	bolt.set_meta("damage", damage)
	bolt.set_meta("element", element)
	bolt.set_meta("source_policy_id", "procedural_godot_shapes")
	turret.add_child(bolt)
	var tween := bolt.create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, 0.1)
	tween.tween_callback(Callable(bolt, "queue_free"))

static func _play_attack_sfx(turret: Node2D, target: Enemy, damage: int, element: String) -> void:
	var cue: Dictionary = AudioCueDBScript.enemy_hit_cue("normal", element, damage)
	var sfx := turret.get_node_or_null("TurretAttackSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "TurretAttackSfx"
		turret.add_child(sfx)
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

static func _add_sprite_visual(turret: Node2D) -> bool:
	var sprite_name := "weapon_bow_2"
	var frames := SpriteDB.build_sprite_frames({"idle": sprite_name})
	if frames == null:
		return false
	var sprite := AnimatedSprite2D.new()
	sprite.name = "TurretSprite"
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.rotation = PI / 2.0
	sprite.scale = Vector2.ONE * 0.9
	sprite.z_index = 4
	sprite.play("idle")
	SpriteDB.apply_sprite_metadata(sprite, sprite_name)
	turret.add_child(sprite)
	return true
