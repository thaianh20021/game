class_name ShadowStepSkill
extends RefCounted

const STEP_DISTANCE := 48.0
const IFRAME_TIME := 0.8

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var aim_dir := Vector2(ctx["aim_dir"])
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	player.global_position += aim_dir.normalized() * STEP_DISTANCE
	player.set("_iframes_left", maxf(float(player.get("_iframes_left")), IFRAME_TIME))
	player.set_meta("shadow_step_duration_seconds", IFRAME_TIME)
	if player.has_method("prime_guaranteed_crit"):
		player.call("prime_guaranteed_crit")
	else:
		player.set_meta("guaranteed_crit", true)
	_show_feedback(player)
	player.modulate = Color(0.55, 0.45, 0.95, 0.72)
	var tween := player.create_tween()
	tween.tween_property(player, "modulate", Color.WHITE, 0.25)
	_attach_expiry_timer(player)

static func _show_feedback(player: Player) -> void:
	var old := player.get_node_or_null("ShadowStepFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "ShadowStepFeedback"
	label.text = "SHADOW STEP CRIT"
	label.position = Vector2(-34, -44)
	label.z_index = 9
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.7, 0.55, 1.0))
	player.add_child(label)

static func _attach_expiry_timer(player: Player) -> void:
	var old := player.get_node_or_null("ShadowStepExpireTimer")
	if old != null:
		old.queue_free()
	var timer := Timer.new()
	timer.name = "ShadowStepExpireTimer"
	timer.wait_time = IFRAME_TIME
	timer.one_shot = true
	timer.autostart = true
	var player_ref: WeakRef = weakref(player)
	timer.timeout.connect(func() -> void:
		var live_player := player_ref.get_ref() as Player
		if live_player != null:
			_expire(live_player))
	player.add_child(timer)

static func _expire(player: Player) -> void:
	if player.has_meta("shadow_step_duration_seconds"):
		player.remove_meta("shadow_step_duration_seconds")
	var feedback := player.get_node_or_null("ShadowStepFeedback")
	if feedback != null:
		feedback.queue_free()
	var timer := player.get_node_or_null("ShadowStepExpireTimer")
	if timer != null:
		timer.queue_free()
