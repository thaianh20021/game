class_name SoulKingdomUltimate
extends RefCounted

const DURATION := 8.0
const SPIRIT_DURATION := 8.0
const ATTACK_RADIUS := 120.0
const ATTACK_INTERVAL_SECONDS := 0.9
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx.get("scene", player)
	var base_damage := int(ctx.get("base_damage", 10))
	var pet_mult := float(ctx.get("pet_damage_mult", 1.0))
	var attack_damage := maxi(1, int(round(float(base_damage) * 0.55 * pet_mult)))
	var element := str(ctx.get("element", "spirit"))
	player.set_meta("soul_kingdom_active", true)
	player.set_meta("soul_kingdom_attack_damage", attack_damage)
	player.set_meta("soul_kingdom_pet_damage_mult", pet_mult)
	player.set_meta("soul_kingdom_element", element)
	_spawn_fx(scene, player.global_position)
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy:
			bind_spawned_enemy(enemy, scene, player)
	var tree := player.get_tree()
	if tree != null:
		var player_id := player.get_instance_id()
		tree.create_timer(DURATION).timeout.connect(func() -> void:
			var p := instance_from_id(player_id) as Player
			if p != null:
				p.set_meta("soul_kingdom_active", false))

static func bind_spawned_enemy(enemy: Enemy, scene: Node, player: Player) -> bool:
	if enemy == null or scene == null or player == null:
		return false
	if not bool(player.get_meta("soul_kingdom_active", false)):
		return false
	var owner_id := player.get_instance_id()
	if int(enemy.get_meta("soul_kingdom_bound_owner_id", 0)) == owner_id:
		return false
	enemy.set_meta("soul_kingdom_bound_owner_id", owner_id)
	var scene_id := scene.get_instance_id()
	var attack_damage := int(player.get_meta("soul_kingdom_attack_damage", 1))
	var pet_mult := float(player.get_meta("soul_kingdom_pet_damage_mult", 1.0))
	var element := str(player.get_meta("soul_kingdom_element", "spirit"))
	enemy.died.connect(func(dead_enemy: Enemy) -> void:
		var s := instance_from_id(scene_id) as Node
		var p := instance_from_id(owner_id) as Player
		if s != null and p != null and bool(p.get_meta("soul_kingdom_active", false)) \
				and is_instance_valid(dead_enemy):
			_spawn_spirit(s, dead_enemy.global_position, attack_damage, pet_mult, element))
	return true

static func _spawn_fx(scene: Node, pos: Vector2) -> void:
	var ring := Line2D.new()
	ring.name = "SoulKingdomFx"
	ring.points = _circle_points(58.0)
	ring.width = 3.0
	ring.default_color = Color(0.62, 0.45, 1.0, 0.75)
	scene.add_child(ring)
	ring.global_position = pos
	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.2, DURATION)
	tween.tween_callback(ring.queue_free)

static func _spawn_spirit(
		scene: Node,
		pos: Vector2,
		attack_damage: int = 1,
		pet_mult: float = 1.0,
		element: String = "spirit",
) -> void:
	var spirit := Node2D.new()
	spirit.name = "SoulKingdomSpirit"
	spirit.add_to_group("player_summons")
	spirit.set_meta("summon_type", "soul_kingdom")
	spirit.set_meta("duration_seconds", SPIRIT_DURATION)
	spirit.set_meta("attack_radius_px", ATTACK_RADIUS)
	spirit.set_meta("attack_interval_seconds", ATTACK_INTERVAL_SECONDS)
	spirit.set_meta("pet_damage_mult", pet_mult)
	spirit.set_meta("attack_damage", attack_damage)
	spirit.set_meta("attack_element", element)
	scene.add_child(spirit)
	spirit.global_position = pos
	if not _add_spirit_sprite(spirit):
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(0, -8), Vector2(7, 0), Vector2(0, 8), Vector2(-7, 0),
		])
		body.color = Color(0.55, 0.8, 1.0, 0.78)
		body.set_meta("sprite_fallback", "polygon")
		spirit.add_child(body)
	var feedback := Label.new()
	feedback.name = "SoulSpiritFeedback"
	feedback.text = "SPIRIT 8s | DMG x%.1f" % pet_mult
	feedback.position = Vector2(-22, -24)
	feedback.add_theme_font_size_override("font_size", 7)
	feedback.add_theme_color_override("font_color", Color(0.74, 0.88, 1.0))
	spirit.add_child(feedback)
	var attack_timer := Timer.new()
	attack_timer.wait_time = ATTACK_INTERVAL_SECONDS
	attack_timer.autostart = true
	var spirit_ref: WeakRef = weakref(spirit)
	attack_timer.timeout.connect(func() -> void:
		var live_spirit := spirit_ref.get_ref() as Node2D
		if live_spirit != null:
			_attack_nearest(live_spirit, attack_damage, element))
	spirit.add_child(attack_timer)
	var tree := spirit.get_tree()
	if tree != null:
		var spirit_id := spirit.get_instance_id()
		tree.create_timer(SPIRIT_DURATION).timeout.connect(func() -> void:
			var node := instance_from_id(spirit_id) as Node
			if node != null:
				node.queue_free())

static func _attack_nearest(spirit: Node2D, damage: int, element: String) -> void:
	if not is_instance_valid(spirit):
		return
	var best: Enemy = null
	var best_dist := INF
	for enemy in spirit.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy:
			var dist: float = enemy.global_position.distance_to(spirit.global_position)
			if dist < best_dist and dist <= ATTACK_RADIUS:
				best = enemy
				best_dist = dist
	if best == null:
		return
	best.hit(maxi(1, damage), element)
	spirit.set_meta("attack_count", int(spirit.get_meta("attack_count", 0)) + 1)
	spirit.set_meta("last_target_id", best.get_instance_id())
	spirit.set_meta("last_attack_damage", maxi(1, damage))
	spirit.set_meta("last_attack_element", element)
	_spawn_attack_bolt(spirit, best, maxi(1, damage), element)
	_play_attack_sfx(spirit, best, maxi(1, damage), element)

static func _spawn_attack_bolt(
		spirit: Node2D,
		target: Enemy,
		damage: int,
		element: String,
) -> void:
	var old := spirit.get_node_or_null("SoulSpiritAttackBolt")
	if old != null:
		old.queue_free()
	var bolt := Line2D.new()
	bolt.name = "SoulSpiritAttackBolt"
	bolt.points = PackedVector2Array([Vector2.ZERO, target.global_position - spirit.global_position])
	bolt.width = 2.0
	bolt.default_color = Color(0.62, 0.45, 1.0, 0.82)
	bolt.z_index = 7
	bolt.set_meta("target_id", target.get_instance_id())
	bolt.set_meta("damage", damage)
	bolt.set_meta("element", element)
	bolt.set_meta("source_policy_id", "procedural_godot_shapes")
	spirit.add_child(bolt)

static func _play_attack_sfx(
		spirit: Node2D,
		target: Enemy,
		damage: int,
		element: String,
) -> void:
	var cue: Dictionary = AudioCueDBScript.enemy_hit_cue("normal", element, damage)
	var sfx := spirit.get_node_or_null("SoulSpiritAttackSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "SoulSpiritAttackSfx"
		spirit.add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("summon_attack_sound_id", str(cue.get("id", "enemy_hit_normal")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "enemy_hit")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "enemy_hit")))
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

static func _add_spirit_sprite(spirit: Node2D) -> bool:
	var sprite_name := "necromancer_anim"
	var frames := SpriteDB.build_sprite_frames({"idle": sprite_name})
	if frames == null:
		return false
	var sprite := AnimatedSprite2D.new()
	sprite.name = "SoulKingdomSpiritSprite"
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.modulate = Color(0.62, 0.85, 1.0, 0.88)
	sprite.z_index = 6
	sprite.play("idle")
	SpriteDB.apply_sprite_metadata(sprite, sprite_name)
	spirit.add_child(sprite)
	return true

static func _circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 21:
		points.append(Vector2(radius, 0).rotated(TAU * float(i) / 20.0))
	return points
