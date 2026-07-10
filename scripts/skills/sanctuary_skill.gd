class_name SanctuarySkill
extends RefCounted

const RADIUS := 54.0
const DURATION := 5.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx["scene"]
	player.heal(maxi(1, int(float(player.max_hp) * 0.03)))
	_clear_player_statuses(player)
	var zone := Node2D.new()
	zone.name = "SanctuaryZone"
	zone.set_meta("duration_seconds", DURATION)
	zone.add_to_group("player_zones")
	scene.add_child(zone)
	zone.global_position = player.global_position
	_spawn_zone_fx(zone)
	_show_feedback(zone)
	var player_ref: WeakRef = weakref(player)
	var timer := Timer.new()
	timer.name = "SanctuaryHealTimer"
	timer.wait_time = 1.0
	timer.autostart = true
	var zone_ref: WeakRef = weakref(zone)
	timer.timeout.connect(func() -> void:
		var live_player := player_ref.get_ref() as Player
		var live_zone := zone_ref.get_ref() as Node2D
		if live_player != null and live_zone != null \
				and live_player.global_position.distance_to(live_zone.global_position) <= RADIUS:
			live_player.heal(maxi(1, int(float(live_player.max_hp) * 0.03))))
	zone.add_child(timer)
	var expire := Timer.new()
	expire.name = "SanctuaryExpireTimer"
	expire.wait_time = DURATION
	expire.one_shot = true
	expire.autostart = true
	expire.timeout.connect(func() -> void:
		var live_zone := zone_ref.get_ref() as Node2D
		if live_zone != null:
			live_zone.queue_free())
	zone.add_child(expire)

static func _clear_player_statuses(player: Player) -> void:
	var statuses = player.get("_statuses")
	if statuses is Dictionary:
		for status_name in statuses.keys():
			if player.has_meta("status_" + str(status_name) + "_left"):
				player.remove_meta("status_" + str(status_name) + "_left")
		statuses.clear()

static func _spawn_zone_fx(zone: Node2D) -> void:
	var ring := Line2D.new()
	ring.name = "SanctuaryFx"
	var points := PackedVector2Array()
	for i in 25:
		points.append(Vector2(RADIUS, 0).rotated(TAU * float(i) / 24.0))
	ring.points = points
	ring.width = 3.0
	ring.default_color = Color(1.0, 0.95, 0.45, 0.82)
	ring.set_meta("skill_id", "sanctuary")
	ring.set_meta("shape", "healing_ring")
	ring.set_meta("radius_px", RADIUS)
	ring.set_meta("duration_seconds", DURATION)
	ring.set_meta("effect", "heal_and_cleanse")
	zone.add_child(ring)

static func _show_feedback(zone: Node2D) -> void:
	var label := Label.new()
	label.name = "SanctuaryFeedback"
	label.text = "SANCTUARY %.0fs" % DURATION
	label.position = Vector2(-32, -28)
	label.z_index = 9
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.45))
	zone.add_child(label)
