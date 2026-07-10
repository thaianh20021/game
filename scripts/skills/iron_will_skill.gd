class_name IronWillSkill
extends RefCounted

const DURATION := 3.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var duration := DURATION * float(ctx.get("shield_duration_mult", 1.0))
	player.set("_iframes_left", maxf(float(player.get("_iframes_left")), duration))
	player.set_meta("iron_will_active", true)
	player.set_meta("iron_will_duration_seconds", duration)
	_show_feedback(player, duration)
	player.modulate = Color(1.0, 0.82, 0.45, 0.95)
	var tween := player.create_tween()
	tween.tween_property(player, "modulate", Color.WHITE, 0.24)
	_attach_expiry_timer(player, duration)

static func _show_feedback(player: Player, duration: float) -> void:
	var old := player.get_node_or_null("IronWillFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "IronWillFeedback"
	label.text = "IRON WILL %s" % _duration_text(duration)
	label.position = Vector2(-24, -44)
	label.z_index = 9
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
	player.add_child(label)

static func _attach_expiry_timer(player: Player, duration: float) -> void:
	var old := player.get_node_or_null("IronWillExpireTimer")
	if old != null:
		old.queue_free()
	var timer := Timer.new()
	timer.name = "IronWillExpireTimer"
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
	if player.has_meta("iron_will_active"):
		player.remove_meta("iron_will_active")
	if player.has_meta("iron_will_duration_seconds"):
		player.remove_meta("iron_will_duration_seconds")
	var feedback := player.get_node_or_null("IronWillFeedback")
	if feedback != null:
		feedback.queue_free()
	var timer := player.get_node_or_null("IronWillExpireTimer")
	if timer != null:
		timer.queue_free()

static func _duration_text(duration: float) -> String:
	if is_equal_approx(duration, roundf(duration)):
		return "%.0fs" % duration
	return "%.1fs" % duration
