class_name PlayerSnareTrap
extends Area2D

var damage := 5
var root_duration := 1.5
var duration := 12.0

func configure(p_damage: int, p_root_duration: float, p_duration: float = 12.0) -> void:
	damage = p_damage
	root_duration = p_root_duration
	duration = p_duration
	set_meta("root_duration_seconds", root_duration)
	set_meta("duration_seconds", duration)

func _ready() -> void:
	add_to_group("player_traps")
	monitoring = true
	set_meta("root_duration_seconds", root_duration)
	set_meta("duration_seconds", duration)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	if not _add_sprite_visual():
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(-7, -4), Vector2(7, -4), Vector2(5, 5), Vector2(-5, 5),
		])
		body.color = Color(0.35, 0.85, 0.45, 0.85)
		body.set_meta("sprite_fallback", "polygon")
		add_child(body)
	_show_feedback()
	_attach_expiry_timer()

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Enemy:
			trigger(body)
			return

func trigger(target: Node) -> bool:
	var enemy := target as Enemy
	if enemy == null:
		return false
	enemy.hit(damage, "")
	enemy.add_status("rooted", root_duration)
	queue_free()
	return true

func _add_sprite_visual() -> bool:
	var sprite_name := "floor_spikes_anim"
	var frames := SpriteDB.build_sprite_frames({"idle": sprite_name})
	if frames == null:
		return false
	var sprite := AnimatedSprite2D.new()
	sprite.name = "SnareTrapSprite"
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.modulate = Color(0.65, 1.0, 0.65)
	sprite.z_index = 3
	sprite.play("idle")
	SpriteDB.apply_sprite_metadata(sprite, sprite_name)
	add_child(sprite)
	return true

func _show_feedback() -> void:
	var old := get_node_or_null("SnareTrapFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "SnareTrapFeedback"
	label.text = "SNARE %.0fs" % duration
	label.position = Vector2(-18, -24)
	label.z_index = 9
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	add_child(label)

func _attach_expiry_timer() -> void:
	var old := get_node_or_null("SnareTrapExpireTimer")
	if old != null:
		old.queue_free()
	var timer := Timer.new()
	timer.name = "SnareTrapExpireTimer"
	timer.wait_time = duration
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)
