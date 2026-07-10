class_name PoisonKnifeSkill
extends RefCounted

const RANGE := 96.0
const WIDTH := 12.0
const MARK_DURATION := 3.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var aim_dir := Vector2(ctx["aim_dir"])
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	_spawn_fx(ctx["scene"], player.global_position, aim_dir)
	var target := _first_enemy_in_line(player, aim_dir)
	if target == null:
		return
	target.hit(maxi(1, int(float(ctx["base_damage"]) * 0.85)), "poison")
	target.add_status("poison", MARK_DURATION)
	target.add_status("vulnerable", MARK_DURATION)
	target.set_meta("poison_knife_mark_duration_seconds", MARK_DURATION)
	_show_mark_feedback(target)
	_attach_mark_timer(target)

static func _first_enemy_in_line(player: Player, dir: Vector2) -> Enemy:
	var best: Enemy = null
	var best_forward := INF
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Enemy):
			continue
		var rel: Vector2 = enemy.global_position - player.global_position
		var forward: float = rel.dot(dir)
		if forward < 0.0 or forward > RANGE:
			continue
		if absf(rel.cross(dir)) > WIDTH:
			continue
		if forward < best_forward:
			best = enemy
			best_forward = forward
	return best

static func _spawn_fx(scene: Node, origin: Vector2, dir: Vector2) -> void:
	var line := Line2D.new()
	line.name = "PoisonKnifeFx"
	line.points = PackedVector2Array([Vector2.ZERO, dir * RANGE])
	line.width = 2.0
	line.default_color = Color(0.35, 1.0, 0.35, 0.85)
	scene.add_child(line)
	line.global_position = origin
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.16)
	tween.tween_callback(line.queue_free)

static func _show_mark_feedback(target: Enemy) -> void:
	var old := target.get_node_or_null("PoisonKnifeMarkFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "PoisonKnifeMarkFeedback"
	label.text = "MARKED %.0fs" % MARK_DURATION
	label.position = Vector2(-18, -38)
	label.z_index = 9
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.45))
	target.add_child(label)

static func _attach_mark_timer(target: Enemy) -> void:
	var old := target.get_node_or_null("PoisonKnifeMarkExpireTimer")
	if old != null:
		old.queue_free()
	var timer := Timer.new()
	timer.name = "PoisonKnifeMarkExpireTimer"
	timer.wait_time = MARK_DURATION
	timer.one_shot = true
	timer.autostart = true
	var target_ref: WeakRef = weakref(target)
	timer.timeout.connect(func() -> void:
		var live_target := target_ref.get_ref() as Enemy
		if live_target != null:
			_expire_mark(live_target))
	target.add_child(timer)

static func _expire_mark(target: Enemy) -> void:
	if target.has_meta("poison_knife_mark_duration_seconds"):
		target.remove_meta("poison_knife_mark_duration_seconds")
	var feedback := target.get_node_or_null("PoisonKnifeMarkFeedback")
	if feedback != null:
		feedback.queue_free()
	var timer := target.get_node_or_null("PoisonKnifeMarkExpireTimer")
	if timer != null:
		timer.queue_free()
