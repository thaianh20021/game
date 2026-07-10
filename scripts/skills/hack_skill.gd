class_name HackSkill
extends RefCounted

const RANGE := 84.0
const DISABLE_SECONDS := 10.0
const REPURPOSE_CHANCE := 0.3

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var trap := _nearest_trap(player)
	if trap == null:
		return
	var repurposed := _try_repurpose(player, trap)
	trap.set_meta("hacked", true)
	trap.set_meta("hack_duration_seconds", DISABLE_SECONDS)
	trap.set_meta("pre_hack_modulate", trap.modulate)
	trap.remove_from_group("room_traps")
	trap.add_to_group("player_traps")
	trap.modulate = Color(0.4, 0.95, 1.0, 0.95)
	_show_hack_feedback(trap, repurposed)
	if repurposed:
		trap.set_meta("repurposed", true)
		trap.set_meta("hacked_permanent", true)
	else:
		_attach_expiry_timer(trap)

static func _nearest_trap(player: Player) -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for trap in player.get_tree().get_nodes_in_group("room_traps"):
		if trap is Node2D:
			var dist: float = trap.global_position.distance_to(player.global_position)
			if dist <= RANGE and dist < best_dist:
				best = trap
				best_dist = dist
	return best

static func _try_repurpose(player: Player, trap: Node2D) -> bool:
	if player == null or not player.has_method("has_passive") \
			or not bool(player.call("has_passive", "repurpose")):
		return false
	trap.set_meta("repurpose_chance", REPURPOSE_CHANCE)
	if bool(player.get_meta("repurpose_force_success", false)):
		trap.set_meta("repurpose_roll", 0.0)
		return true
	var roll := fposmod(absf(trap.global_position.x * 17.0 + trap.global_position.y * 31.0), 100.0) / 100.0
	trap.set_meta("repurpose_roll", roll)
	return roll < REPURPOSE_CHANCE

static func _show_hack_feedback(trap: Node2D, repurposed: bool = false) -> void:
	var old := trap.get_node_or_null("HackFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "HackFeedback"
	label.text = "REPURPOSED" if repurposed else "HACKED %.0fs" % DISABLE_SECONDS
	label.position = Vector2(-18, -24)
	label.z_index = 9
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.42, 1.0, 0.78))
	trap.add_child(label)

static func _attach_expiry_timer(trap: Node2D) -> void:
	var old := trap.get_node_or_null("HackExpireTimer")
	if old != null:
		old.queue_free()
	var timer := Timer.new()
	timer.name = "HackExpireTimer"
	timer.wait_time = DISABLE_SECONDS
	timer.one_shot = true
	timer.autostart = true
	var trap_ref: WeakRef = weakref(trap)
	timer.timeout.connect(func() -> void:
		var live_trap := trap_ref.get_ref() as Node2D
		if live_trap != null:
			_expire_hack(live_trap))
	trap.add_child(timer)

static func _expire_hack(trap: Node2D) -> void:
	trap.set_meta("hacked", false)
	trap.remove_from_group("player_traps")
	trap.add_to_group("room_traps")
	if trap.has_meta("pre_hack_modulate"):
		trap.modulate = trap.get_meta("pre_hack_modulate")
	else:
		trap.modulate = Color.WHITE
	var feedback := trap.get_node_or_null("HackFeedback")
	if feedback != null:
		feedback.queue_free()
	var timer := trap.get_node_or_null("HackExpireTimer")
	if timer != null:
		timer.queue_free()
