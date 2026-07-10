class_name SpecialRoundsSkill
extends RefCounted

const SHOTS := 6

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	player.set_meta("special_rounds_left", SHOTS)
	player.set_meta("special_round_limit", SHOTS)
	player.set_meta("special_rounds_element", str(ctx["element"]))
	_show_feedback(player)
	player.modulate = Color(0.55, 0.9, 1.0, 0.9)
	var tween := player.create_tween()
	tween.tween_property(player, "modulate", Color.WHITE, 0.22)

static func _show_feedback(player: Player) -> void:
	var old := player.get_node_or_null("SpecialRoundsFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "SpecialRoundsFeedback"
	label.text = "ROUNDS %d" % SHOTS
	label.position = Vector2(-24, -42)
	label.z_index = 9
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	player.add_child(label)
