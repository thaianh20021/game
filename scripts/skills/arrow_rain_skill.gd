class_name ArrowRainSkill
extends RefCounted

const RADIUS := 42.0
const DELAY_SECONDS := 0.5
const ARROW_DAMAGE_MULT := 0.8
const ARROW_FALL_DISTANCE := 34.0
const ARROW_START_OFFSET := 28.0
const ARROW_OFFSETS := [
	Vector2(-24, 4),
	Vector2(-16, -12),
	Vector2(-8, 16),
	Vector2(0, -2),
	Vector2(10, -16),
	Vector2(18, 12),
	Vector2(26, -4),
]
# ponytail: Zerie arrow art faces left at rotation 0; move into SpriteDB when mixed arrow art ships.
const ARROW_VISUAL_FORWARD_OFFSET := PI

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx["scene"]
	var zone_center := Vector2(ctx["target_position"])
	var base_damage := int(ctx["base_damage"])
	var element := str(ctx["element"])
	var arrow_count := ARROW_OFFSETS.size()
	var damage_per_arrow := maxi(1, int(round(float(base_damage) * ARROW_DAMAGE_MULT)))
	_spawn_telegraph(scene, zone_center, element, damage_per_arrow)
	_spawn_falling_arrows(scene, zone_center, element, damage_per_arrow)
	var player_ref: WeakRef = weakref(player)
	player.get_tree().create_timer(DELAY_SECONDS).timeout.connect(func() -> void:
		var live_player := player_ref.get_ref() as Player
		if live_player == null:
			return
		for enemy in live_player.get_tree().get_nodes_in_group("enemies"):
			if enemy is Enemy and is_instance_valid(enemy) \
					and enemy.global_position.distance_to(zone_center) <= RADIUS:
				enemy.hit(damage_per_arrow * arrow_count, element))

static func _spawn_telegraph(
		scene: Node,
		pos: Vector2,
		element: String,
		damage_per_arrow: int,
) -> void:
	var ring := Line2D.new()
	ring.name = "ArrowRainTelegraph"
	var points := PackedVector2Array()
	for i in 17:
		points.append(Vector2(RADIUS, 0).rotated(TAU * float(i) / 16.0))
	ring.points = points
	ring.width = 2.0
	ring.default_color = Color(0.56, 0.9, 0.42, 0.82)
	ring.set_meta("skill_id", "arrow_rain")
	ring.set_meta("shape", "impact_zone")
	ring.set_meta("radius_px", RADIUS)
	ring.set_meta("delay_seconds", DELAY_SECONDS)
	ring.set_meta("element", element)
	ring.set_meta("arrow_count", ARROW_OFFSETS.size())
	ring.set_meta("damage_per_arrow", damage_per_arrow)
	ring.set_meta("damage_multiplier", ARROW_DAMAGE_MULT)
	scene.add_child(ring)
	ring.global_position = pos
	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.25, DELAY_SECONDS)
	tween.tween_callback(ring.queue_free)

static func _spawn_falling_arrows(
		scene: Node,
		pos: Vector2,
		element: String,
		damage_per_arrow: int,
) -> void:
	var sprite_name := SpriteDB.first_existing(["zerie_arrow_projectile", "weapon_arrow"])
	var frames := SpriteDB.build_sprite_frames({"idle": sprite_name})
	if frames == null:
		return
	for i in ARROW_OFFSETS.size():
		var arrow := AnimatedSprite2D.new()
		arrow.name = "ArrowRainArrow%d" % (i + 1)
		arrow.sprite_frames = frames
		arrow.centered = true
		arrow.rotation = Vector2.DOWN.angle() + ARROW_VISUAL_FORWARD_OFFSET
		arrow.z_index = 6
		arrow.modulate = Color(0.9, 1.0, 0.78, 0.92)
		arrow.play("idle")
		SpriteDB.apply_sprite_metadata(arrow, sprite_name)
		arrow.set_meta("arrow_visual_forward_offset_rad", ARROW_VISUAL_FORWARD_OFFSET)
		arrow.set_meta("arrow_index", i + 1)
		arrow.set_meta("arrow_count", ARROW_OFFSETS.size())
		arrow.set_meta("damage_per_arrow", damage_per_arrow)
		arrow.set_meta("damage_multiplier", ARROW_DAMAGE_MULT)
		arrow.set_meta("skill_id", "arrow_rain")
		arrow.set_meta("element", element)
		arrow.set_meta("fall_direction", "down")
		scene.add_child(arrow)
		arrow.global_position = pos + ARROW_OFFSETS[i] + Vector2(0, -ARROW_START_OFFSET)
		var tween := arrow.create_tween()
		tween.set_parallel(true)
		tween.tween_property(
			arrow,
			"global_position",
			pos + ARROW_OFFSETS[i] + Vector2(0, ARROW_FALL_DISTANCE - ARROW_START_OFFSET),
			DELAY_SECONDS)
		tween.tween_property(arrow, "modulate:a", 0.0, DELAY_SECONDS)
		tween.set_parallel(false)
		tween.tween_callback(arrow.queue_free)
