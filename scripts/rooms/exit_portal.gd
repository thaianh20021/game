class_name ExitPortal
extends Node2D
## Stairway to the next floor. Spawns in the boss room once the boss is dead;
## stepping on it emits [signal entered]. Uses 0x72 ladder/stairs when available.

signal entered

const TRIGGER_RADIUS := 12.0

var _player: Node2D
var _visual: Polygon2D
var _sprite: Sprite2D
var _prompt: Label
var _time := 0.0
var _triggered := false
var _run_finale := false

static func release_geometry_contract(_runtime_id: String) -> Dictionary:
	return {
		"shape_size": Vector2(TRIGGER_RADIUS * 2.0, TRIGGER_RADIUS * 2.0),
		"fallback_polygon": PackedVector2Array([
			Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0),
		]),
	}

func configure(player: Node2D, run_finale: bool = false) -> void:
	_player = player
	_run_finale = run_finale
	_apply_portal_metadata()
	_apply_portal_visual()
	_apply_prompt_state()


func set_run_finale(enabled: bool) -> void:
	_run_finale = enabled
	_apply_portal_metadata()
	_apply_portal_visual()
	_apply_prompt_state()


func _ready() -> void:
	_apply_portal_metadata()
	if SpriteDB.texture(_portal_sprite_name()) != null:
		_sprite = Sprite2D.new()
		_sprite.name = "PortalSprite"
		add_child(_sprite)
		_apply_portal_visual()
		z_index = 1
	else:
		_visual = Polygon2D.new()
		_visual.polygon = PackedVector2Array([
			Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0),
		])
		_visual.color = Color(0.4, 0.9, 1.0)
		add_child(_visual)
	z_index = 1
	_ensure_prompt()


func _process(delta: float) -> void:
	_time += delta
	if _visual != null:
		_visual.scale = Vector2.ONE * (1.0 + 0.15 * sin(_time * 4.0))
	if _triggered or _player == null or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= TRIGGER_RADIUS:
		_triggered = true
		entered.emit()

func _ensure_prompt() -> void:
	_prompt = Label.new()
	_prompt.name = "PortalPrompt"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 8)
	add_child(_prompt)
	_apply_prompt_state()


func _apply_portal_metadata() -> void:
	set_meta("ready_for_next_floor", not _run_finale)
	set_meta("ready_for_run_complete", _run_finale)


func _apply_prompt_state() -> void:
	if _prompt == null:
		return
	_prompt.text = "Run Complete" if _run_finale else "Next Floor"
	_prompt.position = Vector2(-36, -24) if _run_finale else Vector2(-24, -24)
	_prompt.size = Vector2(72, 12) if _run_finale else Vector2(48, 12)
	_prompt.modulate = Color(1.0, 0.86, 0.46) if _run_finale else Color(0.62, 0.94, 1.0)

func _portal_sprite_name() -> String:
	return "floor_stairs" if _run_finale else "floor_ladder"

func _apply_portal_visual() -> void:
	if _sprite == null:
		return
	var sprite_name := _portal_sprite_name()
	var texture := SpriteDB.texture(sprite_name)
	if texture == null:
		return
	_sprite.texture = texture
	_sprite.set_meta("portal_sprite", sprite_name)
	SpriteDB.apply_sprite_metadata(_sprite, sprite_name)
