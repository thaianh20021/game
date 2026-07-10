class_name BattleRoarSkill
extends RefCounted

const RADIUS := 80.0
const DURATION := 3.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var duration := DURATION * float(ctx.get("shield_duration_mult", 1.0))
	player.set_meta("temporary_armor", int(player.get_meta("temporary_armor", 0)) + 2)
	player.set_meta("temporary_armor_duration_seconds", duration)
	_show_armor_feedback(player, duration)
	_spawn_roar_fx(ctx["scene"], player.global_position)
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.global_position.distance_to(player.global_position) <= RADIUS:
			enemy.target = player
			enemy.add_status("taunted", duration)
	_attach_expiry_timer(player, duration)

static func _show_armor_feedback(player: Player, duration: float) -> void:
	var old := player.get_node_or_null("BattleRoarFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "BattleRoarFeedback"
	label.text = "ARMOR +2 %s" % _duration_text(duration)
	label.position = Vector2(-26, -44)
	label.z_index = 9
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.25))
	player.add_child(label)

static func _attach_expiry_timer(player: Player, duration: float) -> void:
	var old := player.get_node_or_null("BattleRoarExpireTimer")
	if old != null:
		old.queue_free()
	var timer := Timer.new()
	timer.name = "BattleRoarExpireTimer"
	timer.wait_time = duration
	timer.one_shot = true
	timer.autostart = true
	var player_ref: WeakRef = weakref(player)
	timer.timeout.connect(func() -> void:
		var live_player := player_ref.get_ref() as Player
		if live_player != null:
			_expire_armor(live_player))
	player.add_child(timer)

static func _expire_armor(player: Player) -> void:
	var armor := maxi(int(player.get_meta("temporary_armor", 0)) - 2, 0)
	if armor > 0:
		player.set_meta("temporary_armor", armor)
	else:
		if player.has_meta("temporary_armor"):
			player.remove_meta("temporary_armor")
		if player.has_meta("temporary_armor_duration_seconds"):
			player.remove_meta("temporary_armor_duration_seconds")
	var feedback := player.get_node_or_null("BattleRoarFeedback")
	if feedback != null:
		feedback.queue_free()
	var timer := player.get_node_or_null("BattleRoarExpireTimer")
	if timer != null:
		timer.queue_free()

static func _spawn_roar_fx(scene: Node, pos: Vector2) -> void:
	var ring := Line2D.new()
	ring.name = "BattleRoarFx"
	var points := PackedVector2Array()
	for i in 21:
		points.append(Vector2(RADIUS, 0).rotated(TAU * float(i) / 20.0))
	ring.points = points
	ring.width = 3.0
	ring.default_color = Color(1.0, 0.7, 0.25, 0.8)
	scene.add_child(ring)
	ring.global_position = pos
	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.24)
	tween.tween_callback(ring.queue_free)

static func _duration_text(duration: float) -> String:
	if is_equal_approx(duration, roundf(duration)):
		return "%.0fs" % duration
	return "%.1fs" % duration
