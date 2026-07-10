class_name ShieldBastionSkill
extends RefCounted

const IFRAME_TIME := 1.5

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var duration := IFRAME_TIME * float(ctx.get("shield_duration_mult", 1.0))
	player.set("_iframes_left", maxf(float(player.get("_iframes_left")), duration))
	player.set_meta("shield_bastion_duration_seconds", duration)
	_spawn_shield_fx(player, duration)
	_show_feedback(player, duration)
	_attach_expiry_timer(player, duration)

static func _spawn_shield_fx(player: Player, duration: float) -> void:
	var old := player.get_node_or_null("ShieldBastionFx")
	if old != null:
		old.queue_free()
	var shield := Line2D.new()
	shield.name = "ShieldBastionFx"
	var points := PackedVector2Array()
	for i in 13:
		points.append(Vector2(14, 0).rotated(TAU * float(i) / 12.0))
	shield.points = points
	shield.width = 2.0
	shield.default_color = Color(0.4, 0.75, 1.0, 0.9)
	player.add_child(shield)
	var tween := shield.create_tween()
	tween.tween_interval(duration)
	tween.tween_property(shield, "modulate:a", 0.0, 0.2)
	tween.tween_callback(shield.queue_free)

static func _show_feedback(player: Player, duration: float) -> void:
	var old := player.get_node_or_null("ShieldBastionFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "ShieldBastionFeedback"
	label.text = "SHIELD %.1fs" % duration
	label.position = Vector2(-22, -44)
	label.z_index = 9
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0))
	player.add_child(label)

static func _attach_expiry_timer(player: Player, duration: float) -> void:
	var old := player.get_node_or_null("ShieldBastionExpireTimer")
	if old != null:
		old.queue_free()
	var timer := Timer.new()
	timer.name = "ShieldBastionExpireTimer"
	timer.wait_time = duration
	timer.one_shot = true
	timer.autostart = true
	var player_ref: WeakRef = weakref(player)
	timer.timeout.connect(func() -> void:
		var live_player := player_ref.get_ref() as Player
		if live_player != null:
			_expire(live_player))
	player.add_child(timer)

static func _expire(player: Player) -> void:
	if player.has_meta("shield_bastion_duration_seconds"):
		player.remove_meta("shield_bastion_duration_seconds")
	var feedback := player.get_node_or_null("ShieldBastionFeedback")
	if feedback != null:
		feedback.queue_free()
	var timer := player.get_node_or_null("ShieldBastionExpireTimer")
	if timer != null:
		timer.queue_free()
