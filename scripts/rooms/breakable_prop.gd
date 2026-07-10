class_name BreakableProp
extends StaticBody2D
## Small room prop that can be destroyed by weapon hits.

var kind := "crate"
var max_hp := 2
var hp := 2
var drop_data: Dictionary = {"type": "gold", "value": 2}

var _player: Node = null
var _broken := false
var _visual: Polygon2D
var _sprite_visual: AnimatedSprite2D

static func release_geometry_contract(runtime_id: String) -> Dictionary:
	var runtime_kind := runtime_id.get_slice(":", 1) if runtime_id.contains(":") else runtime_id
	return {
		"shape_size": Vector2(10, 10),
		"fallback_polygon": release_fallback_polygon(runtime_kind),
	}

static func release_fallback_polygon(runtime_kind: String) -> PackedVector2Array:
	match runtime_kind:
		"vase":
			return PackedVector2Array([
				Vector2(-4, -6), Vector2(4, -6), Vector2(6, -1),
				Vector2(4, 6), Vector2(-4, 6), Vector2(-6, -1),
			])
	return PackedVector2Array([
		Vector2(-6, -6), Vector2(6, -6), Vector2(6, 6), Vector2(-6, 6),
	])

func configure(p_kind: String, p_hp: int, p_drop_data: Dictionary, player: Node = null) -> void:
	kind = p_kind
	max_hp = maxi(p_hp, 1)
	hp = max_hp
	drop_data = p_drop_data
	_player = player
	_update_visual()

func _ready() -> void:
	add_to_group("breakable_props")
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(10, 10)
		shape.shape = rect
		add_child(shape)
	_update_visual()

func take_damage(amount: int) -> bool:
	return hit(amount)

func hit(amount: int) -> bool:
	if _broken:
		return false
	hp -= maxi(amount, 0)
	if hp <= 0:
		_break()
		return true
	_flash(maxi(amount, 0))
	return false

func _break() -> void:
	_broken = true
	_show_break_feedback()
	_spawn_drop()
	queue_free()

func _spawn_drop() -> void:
	var parent := get_parent()
	if parent == null or drop_data.is_empty():
		return
	var pickup := Pickup.new()
	pickup.name = "PropDrop"
	pickup.configure(drop_data, _player)
	pickup.global_position = global_position
	pickup.add_to_group("room_pickups")
	parent.add_child(pickup)

func _show_break_feedback() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var old := parent.get_node_or_null("PropBreakFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "PropBreakFeedback"
	label.text = "Break"
	label.global_position = global_position + Vector2(-12, -16)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	parent.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -10), 0.35)
	tween.tween_property(label, "modulate:a", 0.0, 0.35)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _flash(amount: int) -> void:
	modulate = Color(1.35, 1.2, 0.75)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)
	_show_hit_feedback(amount)

func _show_hit_feedback(amount: int) -> void:
	var old := get_node_or_null("PropHitFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "PropHitFeedback"
	label.text = "-%d" % amount
	label.position = Vector2(-8, -16)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.46))
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -8), 0.28)
	tween.tween_property(label, "modulate:a", 0.0, 0.28)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

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
		"vase":
			_visual.polygon = PackedVector2Array([
				Vector2(-4, -6), Vector2(4, -6), Vector2(6, -1),
				Vector2(4, 6), Vector2(-4, 6), Vector2(-6, -1),
			])
			_visual.color = Color(0.45, 0.62, 0.78)
		_:
			_visual.polygon = PackedVector2Array([
				Vector2(-6, -6), Vector2(6, -6), Vector2(6, 6), Vector2(-6, 6),
			])
			_visual.color = Color(0.55, 0.36, 0.18)

func _try_sprite_visual() -> bool:
	var sprite_name := _sprite_visual_name()
	if sprite_name == "":
		return false
	var texture := SpriteDB.texture(sprite_name)
	if texture == null:
		return false
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.add_frame("idle", texture)
	if _sprite_visual == null or not is_instance_valid(_sprite_visual):
		_sprite_visual = AnimatedSprite2D.new()
		_sprite_visual.name = "ObjectSprite"
		_sprite_visual.centered = true
		add_child(_sprite_visual)
	_sprite_visual.sprite_frames = frames
	_sprite_visual.visible = true
	_sprite_visual.play("idle")
	SpriteDB.apply_sprite_metadata(_sprite_visual, sprite_name)
	if _visual != null and is_instance_valid(_visual):
		_visual.visible = false
	return true

func _sprite_visual_name() -> String:
	match kind:
		"crate":
			return "crate"
		"vase":
			return "flask_big_blue"
	return ""
