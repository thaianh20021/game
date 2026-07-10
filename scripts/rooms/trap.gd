class_name Trap
extends Area2D
## Room hazard with a short telegraph before damage.

var kind := "spike"
var damage := 6
var cooldown := 0.7
const MIN_TELEGRAPH_SECONDS := 0.5
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")

var telegraph_time := MIN_TELEGRAPH_SECONDS

var _armed := false
var _armed_at := -999.0
var _last_damage_at := -999.0
var _target: Node = null
var _visual: Polygon2D
var _sprite_visual: AnimatedSprite2D

static func release_geometry_contract(runtime_id: String) -> Dictionary:
	var runtime_kind := runtime_id.get_slice(":", 1) if runtime_id.contains(":") else runtime_id
	return {
		"shape_size": Vector2(14, 14),
		"fallback_polygon": release_fallback_polygon(runtime_kind),
	}

static func release_fallback_polygon(runtime_kind: String) -> PackedVector2Array:
	match runtime_kind:
		"fire":
			return PackedVector2Array([
				Vector2(-5, 5), Vector2(-2, -6), Vector2(1, -1),
				Vector2(4, -7), Vector2(6, 5),
			])
		"saw":
			return PackedVector2Array([
				Vector2(0, -7), Vector2(2, -2), Vector2(7, 0), Vector2(2, 2),
				Vector2(0, 7), Vector2(-2, 2), Vector2(-7, 0), Vector2(-2, -2),
			])
		"arrow":
			return PackedVector2Array([
				Vector2(-7, -3), Vector2(4, -3), Vector2(4, -6),
				Vector2(8, 0), Vector2(4, 6), Vector2(4, 3), Vector2(-7, 3),
			])
	return PackedVector2Array([
		Vector2(-7, 6), Vector2(-4, -5), Vector2(0, 5),
		Vector2(4, -5), Vector2(7, 6),
	])

func configure(p_kind: String, p_damage: int, p_cooldown: float, p_telegraph_time: float) -> void:
	kind = p_kind
	damage = p_damage
	cooldown = p_cooldown
	telegraph_time = maxf(p_telegraph_time, MIN_TELEGRAPH_SECONDS)
	set_meta("trap_kind", kind)
	set_meta("damage", damage)
	set_meta("cooldown_seconds", cooldown)
	set_meta("telegraph_seconds", telegraph_time)
	set_meta("requested_telegraph_seconds", p_telegraph_time)
	_update_visual()

func _ready() -> void:
	add_to_group("room_traps")
	monitoring = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 7.0
		shape.shape = circle
		add_child(shape)
	_update_visual()

func _physics_process(_delta: float) -> void:
	var now := float(Time.get_ticks_msec()) / 1000.0
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			apply_to(body, now)
			return

func apply_to(target: Node, now: float) -> bool:
	if target == null or not target.has_method("take_damage"):
		return false
	if bool(get_meta("hacked", false)) and target is Player:
		return false
	if now - _last_damage_at < cooldown:
		return false
	if _armed and _target == target:
		if now - _armed_at >= telegraph_time:
			var source_label := "Trap: %s" % kind.capitalize()
			if target is Player:
				target.take_damage(damage, global_position, source_label)
			else:
				target.take_damage(damage)
				if target.has_method("record_damage_taken"):
					target.record_damage_taken(source_label, damage)
			if target.has_method("record_room_decision"):
				target.record_room_decision("Trap Hit", "%s -%d HP" % [kind.capitalize(), damage])
			_last_damage_at = now
			_armed = false
			_target = null
			_update_visual()
			_show_trigger_feedback(damage)
			return true
		return false
	_armed = true
	_armed_at = now
	_target = target
	_update_visual()
	_show_armed_feedback()
	return false

func _on_body_entered(body: Node) -> void:
	if body != null and body.has_method("take_damage"):
		apply_to(body, float(Time.get_ticks_msec()) / 1000.0)

func _on_body_exited(body: Node) -> void:
	if body == _target:
		_armed = false
		_target = null
		_update_visual()

func _update_visual() -> void:
	if not is_inside_tree():
		return
	if _try_sprite_visual():
		return
	if _visual == null or not is_instance_valid(_visual):
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		add_child(_visual)
	_visual.visible = true
	match kind:
		"fire":
			_visual.polygon = PackedVector2Array([
				Vector2(-5, 5), Vector2(-2, -6), Vector2(1, -1),
				Vector2(4, -7), Vector2(6, 5),
			])
			_visual.color = Color(1.0, 0.35, 0.12, 0.8)
		"saw":
			_visual.polygon = PackedVector2Array([
				Vector2(0, -7), Vector2(2, -2), Vector2(7, 0), Vector2(2, 2),
				Vector2(0, 7), Vector2(-2, 2), Vector2(-7, 0), Vector2(-2, -2),
			])
			_visual.color = Color(0.75, 0.78, 0.82, 0.85)
		"arrow":
			_visual.polygon = PackedVector2Array([
				Vector2(-7, -3), Vector2(4, -3), Vector2(4, -6),
				Vector2(8, 0), Vector2(4, 6), Vector2(4, 3), Vector2(-7, 3),
			])
			_visual.color = Color(0.9, 0.72, 0.38, 0.85)
		_:
			_visual.polygon = PackedVector2Array([
				Vector2(-7, 6), Vector2(-4, -5), Vector2(0, 5),
				Vector2(4, -5), Vector2(7, 6),
			])
			_visual.color = Color(0.72, 0.74, 0.78, 0.85)
	if _armed:
		_visual.color = Color(1.0, 0.2, 0.12, 0.9)

func _try_sprite_visual() -> bool:
	var sprite_name := _sprite_visual_name()
	if sprite_name == "":
		return false
	var frames := SpriteDB.build_sprite_frames({"idle": sprite_name})
	if frames == null:
		return false
	if _sprite_visual == null or not is_instance_valid(_sprite_visual):
		_sprite_visual = AnimatedSprite2D.new()
		_sprite_visual.name = "ObjectSprite"
		_sprite_visual.centered = true
		add_child(_sprite_visual)
	_sprite_visual.sprite_frames = frames
	_sprite_visual.visible = true
	_sprite_visual.modulate = Color(1.25, 0.75, 0.6) if _armed else Color.WHITE
	_sprite_visual.play("idle")
	SpriteDB.apply_sprite_metadata(_sprite_visual, sprite_name)
	if _visual != null and is_instance_valid(_visual):
		_visual.visible = false
	return true

func _sprite_visual_name() -> String:
	match kind:
		"spike":
			return "floor_spikes_anim"
		"fire":
			return "bomb"
		"saw":
			return "weapon_saw_sword"
		"arrow":
			return "weapon_arrow"
	return ""

func _show_trigger_feedback(amount: int) -> void:
	_play_trigger_sfx()
	var old := get_node_or_null("TrapTriggeredFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "TrapTriggeredFeedback"
	label.text = "-%d" % amount
	label.position = Vector2(-8, -18)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.38, 0.2))
	add_child(label)
	set_meta("triggered_feedback", true)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -10), 0.35)
	tween.tween_property(label, "modulate:a", 0.0, 0.35)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_armed_feedback() -> void:
	_play_arm_sfx()
	var old := get_node_or_null("TrapArmedWarning")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "TrapArmedWarning"
	label.text = "!"
	label.position = Vector2(-3, -18)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.12))
	add_child(label)
	set_meta("armed_feedback", true)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE * 1.25, telegraph_time)
	tween.tween_property(label, "modulate:a", 0.0, telegraph_time)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _play_arm_sfx() -> void:
	_play_trap_sfx("TrapArmedSfx", AudioCueDBScript.trap_arm_cue(kind))

func _play_trigger_sfx() -> void:
	_play_trap_sfx("TrapTriggeredSfx", AudioCueDBScript.trap_trigger_cue(kind))

func _play_trap_sfx(node_name: String, cue: Dictionary) -> void:
	var sfx := get_node_or_null(node_name) as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = node_name
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("trap_kind", kind)
	sfx.set_meta("trap_sound_id", str(cue.get("id", "trap_trigger")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "trap_trigger")))
	sfx.set_meta("trap_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()
