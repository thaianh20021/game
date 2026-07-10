class_name Pickup
extends Node2D
## In-run drop on the floor: gold, potion or weapon. Gold and potions magnet
## to the player; weapons must be walked over deliberately (they replace the
## active weapon slot). Uses atlas/generated sprites first, with polygon fallback.

const MAGNET_RADIUS := 44.0
const COLLECT_RADIUS := 10.0
const MAGNET_SPEED := 150.0
const MAGNET_TRAIL_COLOR := Color(1.0, 0.92, 0.42, 0.55)
const TOAST_LIFETIME := 0.65
const TOAST_FLOAT_OFFSET := Vector2(0, -14)
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")

const RARITY_COLORS := {
	"common": Color(0.85, 0.85, 0.85),
	"uncommon": Color(0.4, 0.9, 0.4),
	"rare": Color(0.35, 0.6, 1.0),
	"epic": Color(0.75, 0.4, 1.0),
	"legendary": Color(1.0, 0.6, 0.2),
	"mythic": Color(1.0, 0.3, 0.3),
}
const META_CURRENCY_COLORS := {
	"soul_shards": Color(0.45, 0.85, 1.0),
	"element_cores": Color(1.0, 0.45, 0.25),
	"rune_dust": Color(0.75, 0.55, 1.0),
	"blueprints": Color(0.3, 0.7, 1.0),
}

var data: Dictionary = {}

var _player: Node2D
var _sprite: AnimatedSprite2D
var _collected := false

static func release_geometry_contract(runtime_id: String) -> Dictionary:
	var pickup_id := runtime_id.get_slice(":", 1) if runtime_id.contains(":") else runtime_id
	return {
		"shape_size": Vector2(COLLECT_RADIUS * 2.0, COLLECT_RADIUS * 2.0),
		"fallback_polygon": release_fallback_polygon(pickup_id),
	}

static func release_fallback_polygon(pickup_id: String) -> PackedVector2Array:
	var pickup_type := pickup_id
	if pickup_id.begins_with("weapon_"):
		pickup_type = "weapon"
	match pickup_type:
		"gold":
			return PackedVector2Array([
				Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0),
			])
		"potion":
			return PackedVector2Array([
				Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3),
			])
		"silver_key":
			return PackedVector2Array([
				Vector2(-5, -1), Vector2(-1, -5), Vector2(4, 0), Vector2(1, 3), Vector2(-2, 2),
			])
		"weapon":
			return PackedVector2Array([
				Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4),
			])
		"meta_currency", "soul_shard", "soul_shards", "element_core", "element_cores", "rune_dust", "blueprint", "blueprints":
			return PackedVector2Array([
				Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0),
			])
	return PackedVector2Array([
		Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3),
	])

func configure(p_data: Dictionary, player: Node2D) -> void:
	data = p_data
	_player = player


func _ready() -> void:
	if _try_sprite_visual():
		return
	var visual := Polygon2D.new()
	match str(data.get("type", "gold")):
		"gold":
			visual.polygon = PackedVector2Array([
				Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0),
			])
			visual.color = Color(1.0, 0.85, 0.2)
		"potion":
			visual.polygon = PackedVector2Array([
				Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3),
			])
			visual.color = Color(0.9, 0.25, 0.3)
		"silver_key":
			visual.polygon = PackedVector2Array([
				Vector2(-5, -1), Vector2(-1, -5), Vector2(4, 0), Vector2(1, 3), Vector2(-2, 2),
			])
			visual.color = Color(0.78, 0.88, 1.0)
		"weapon":
			visual.polygon = PackedVector2Array([
				Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4),
			])
			var weapon := WeaponDB.get_weapon(str(data.get("id", "")))
			visual.color = RARITY_COLORS.get(str(weapon.get("rarity", "common")), Color.WHITE)
		"meta_currency", "soul_shard", "soul_shards", "element_core", "element_cores", "rune_dust", "blueprint", "blueprints":
			visual.polygon = PackedVector2Array([
				Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0),
			])
			visual.color = META_CURRENCY_COLORS.get(_meta_currency_id(), Color(0.7, 0.9, 1.0))
	add_child(visual)

func _try_sprite_visual() -> bool:
	var type := str(data.get("type", "gold"))
	var sprite_name := ""
	var sprite_frames: SpriteFrames
	match type:
		"gold":
			sprite_name = "coin_anim"
			sprite_frames = SpriteDB.build_sprite_frames({"idle": sprite_name})
		"potion":
			sprite_name = "flask_red"
			sprite_frames = _single_frame_anim(sprite_name)
		"silver_key":
			sprite_name = "pickup_silver_key_generated"
			sprite_frames = _single_frame_anim(sprite_name)
		"weapon":
			var weapon := WeaponDB.get_weapon(str(data.get("id", "")))
			var group := str(weapon.get("group", ""))
			sprite_name = WeaponDB.sprite_name_for_group(group)
			sprite_frames = _single_frame_anim(sprite_name)
		"meta_currency", "soul_shard", "soul_shards", "element_core", "element_cores", "rune_dust", "blueprint", "blueprints":
			sprite_name = _meta_currency_sprite_name(_meta_currency_id())
			sprite_frames = _single_frame_anim(sprite_name)
		_:
			sprite_name = "pickup_unknown_generated"
			sprite_frames = _single_frame_anim(sprite_name)
	if sprite_frames == null:
		return false
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "PickupSprite"
	_sprite.sprite_frames = sprite_frames
	SpriteDB.apply_sprite_metadata(_sprite, sprite_name)
	_sprite.play("idle")
	add_child(_sprite)
	return true

func _single_frame_anim(sprite_name: String) -> SpriteFrames:
	if sprite_name == "":
		return null
	var tex := SpriteDB.texture(sprite_name)
	if tex == null:
		return null
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.add_frame("idle", tex)
	return frames

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= COLLECT_RADIUS:
		_clear_magnet_feedback()
		_collect()
		return
	if str(data.get("type", "")) != "weapon" and dist <= MAGNET_RADIUS:
		_update_magnet_feedback(dist)
		global_position = global_position.move_toward(
			_player.global_position, MAGNET_SPEED * delta)
	else:
		_clear_magnet_feedback()


func _collect() -> void:
	if _collected:
		return
	if str(data.get("type", "gold")) == "potion" and _player_is_full_hp():
		if not bool(get_meta("blocked_full_hp", false)):
			set_meta("blocked_full_hp", true)
			_show_pickup_toast("Full HP")
		return
	_collected = true
	var toast_text := _pickup_toast_text()
	match str(data.get("type", "gold")):
		"gold":
			_player.add_gold(int(data.get("value", 0)))
		"potion":
			_player.heal(int(data.get("value", 0)))
		"silver_key":
			if _player.has_method("add_key"):
				_player.add_key(int(data.get("value", 1)))
		"weapon":
			_player.pickup_weapon(str(data.get("id", "")))
		"meta_currency", "soul_shard", "soul_shards", "element_core", "element_cores", "rune_dust", "blueprint", "blueprints":
			if _player.has_method("add_meta_currency"):
				_player.add_meta_currency(_meta_currency_id(), int(data.get("value", 0)))
	_record_pickup_history()
	_play_pickup_sfx()
	_show_pickup_toast(toast_text)
	queue_free()

func _record_pickup_history() -> void:
	if _player == null or not is_instance_valid(_player) or not _player.has_method("record_pickup"):
		return
	var label := _pickup_history_label()
	if label != "":
		_player.call("record_pickup", label)

func _pickup_history_label() -> String:
	var value := int(data.get("value", 0))
	match str(data.get("type", "gold")):
		"potion":
			return "Potion +%d HP" % value
		"silver_key":
			return "Key +%d" % maxi(value, 1)
		"weapon":
			var weapon := WeaponDB.get_weapon(str(data.get("id", "")))
			return "Weapon: %s" % str(weapon.get("name", data.get("id", "Weapon")))
		"meta_currency", "soul_shard", "soul_shards", "element_core", "element_cores", "rune_dust", "blueprint", "blueprints":
			return "%s +%d" % [_meta_currency_id().replace("_", " ").capitalize(), value]
	return ""

func _update_magnet_feedback(distance_before: float) -> void:
	set_meta("magnet_active", true)
	set_meta("magnet_distance_before", distance_before)
	var trail := get_node_or_null("PickupMagnetTrail") as Line2D
	if trail == null:
		trail = Line2D.new()
		trail.name = "PickupMagnetTrail"
		trail.width = 1.0
		trail.default_color = MAGNET_TRAIL_COLOR
		trail.z_index = -1
		add_child(trail)
	trail.visible = true
	trail.points = PackedVector2Array([Vector2.ZERO, to_local(_player.global_position)])

func _clear_magnet_feedback() -> void:
	set_meta("magnet_active", false)
	var trail := get_node_or_null("PickupMagnetTrail") as Line2D
	if trail != null:
		trail.visible = false

func _player_is_full_hp() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var max_value = _player.get("max_hp")
	var current = _player.get("hp")
	if max_value == null or current == null:
		return false
	return int(current) >= int(max_value)

func _show_pickup_toast(text: String) -> void:
	if text == "" or get_parent() == null:
		return
	var toast := Label.new()
	toast.name = "PickupToast"
	toast.text = text
	toast.global_position = global_position + Vector2(-20, -20)
	toast.add_theme_font_size_override("font_size", 9)
	toast.add_theme_color_override("font_color", _pickup_toast_color())
	toast.z_index = 20
	toast.set_meta("auto_cleanup_seconds", TOAST_LIFETIME)
	toast.set_meta("float_offset", TOAST_FLOAT_OFFSET)
	_apply_pickup_feedback_metadata(toast)
	get_parent().add_child(toast)
	var tween := toast.create_tween()
	tween.set_parallel(true)
	tween.tween_property(toast, "global_position", toast.global_position + TOAST_FLOAT_OFFSET, TOAST_LIFETIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(toast, "modulate:a", 0.0, TOAST_LIFETIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(Callable(toast, "queue_free"))

func _play_pickup_sfx() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var old := parent.get_node_or_null("PickupSfx")
	if old != null:
		old.queue_free()
	var cue: Dictionary = AudioCueDBScript.pickup_cue(data)
	var sfx := AudioStreamPlayer.new()
	sfx.name = "PickupSfx"
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("pickup_type", str(data.get("type", "gold")))
	sfx.set_meta("pickup_id", str(data.get("id", "")))
	sfx.set_meta("pickup_sound_id", str(cue.get("id", "pickup_meta")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "pickup")))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("pickup_sound_frequency", float(cue.get("frequency", 500.0)))
	sfx.set_meta("playback_requested", true)
	_apply_pickup_feedback_metadata(sfx)
	parent.add_child(sfx)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
	else:
		sfx.set_meta("headless_playback_skipped", false)
		sfx.play()
	sfx.call_deferred("queue_free")

func _apply_pickup_feedback_metadata(target: Object) -> void:
	var context := _pickup_feedback_context()
	target.set_meta("pickup_label", str(context.get("label", "")))
	target.set_meta("pickup_category", str(context.get("category", "")))
	target.set_meta("pickup_feedback_tier", str(context.get("feedback_tier", "common")))
	if context.has("value"):
		target.set_meta("pickup_value", int(context.get("value", 0)))
	if context.has("rarity"):
		target.set_meta("pickup_rarity", str(context.get("rarity", "common")))

func _pickup_feedback_context() -> Dictionary:
	var type := str(data.get("type", "gold"))
	var context: Dictionary = {
		"label": type.capitalize(),
		"category": "currency",
		"feedback_tier": "common",
	}
	if data.has("value"):
		context["value"] = int(data.get("value", 0))
	match type:
		"gold":
			context["label"] = "Gold"
			context["category"] = "currency"
		"potion":
			context["label"] = "HP"
			context["category"] = "healing"
		"silver_key":
			context["label"] = "Key"
			context["category"] = "key"
			context["feedback_tier"] = "uncommon"
		"weapon":
			var weapon := WeaponDB.get_weapon(str(data.get("id", "")))
			var rarity := str(weapon.get("rarity", "common"))
			context["label"] = str(weapon.get("name", data.get("id", "Weapon")))
			context["category"] = "weapon"
			context["rarity"] = rarity
			context["feedback_tier"] = rarity
		"meta_currency", "soul_shard", "soul_shards", "element_core", "element_cores", "rune_dust", "blueprint", "blueprints":
			var currency_id := _meta_currency_id()
			context["label"] = currency_id.replace("_", " ").capitalize()
			context["category"] = "meta_currency"
			context["feedback_tier"] = _meta_currency_feedback_tier(currency_id)
	return context

func _meta_currency_feedback_tier(currency_id: String) -> String:
	match currency_id:
		"element_cores", "blueprints":
			return "rare"
		"rune_dust", "soul_shards":
			return "uncommon"
		_:
			return "common"

func _pickup_toast_text() -> String:
	var value := int(data.get("value", 0))
	match str(data.get("type", "gold")):
		"gold":
			return "+%d Gold" % value
		"potion":
			return "+%d HP" % value
		"silver_key":
			return "+%d Key" % maxi(value, 1)
		"weapon":
			var weapon := WeaponDB.get_weapon(str(data.get("id", "")))
			var rarity := str(weapon.get("rarity", "common")).capitalize()
			return "Weapon: %s [%s]" % [
				str(weapon.get("name", data.get("id", "Weapon"))),
				rarity,
			]
		"meta_currency", "soul_shard", "soul_shards", "element_core", "element_cores", "rune_dust", "blueprint", "blueprints":
			return "+%d %s" % [value, _meta_currency_id().replace("_", " ").capitalize()]
	return ""

func _pickup_toast_color() -> Color:
	match str(data.get("type", "gold")):
		"gold":
			return Color(1.0, 0.88, 0.28)
		"potion":
			return Color(1.0, 0.45, 0.45)
		"weapon":
			var weapon := WeaponDB.get_weapon(str(data.get("id", "")))
			return RARITY_COLORS.get(str(weapon.get("rarity", "common")), Color.WHITE)
		"meta_currency", "soul_shard", "soul_shards", "element_core", "element_cores", "rune_dust", "blueprint", "blueprints":
			return META_CURRENCY_COLORS.get(_meta_currency_id(), Color(0.7, 0.9, 1.0))
	return Color.WHITE

func _meta_currency_sprite_name(currency_id: String) -> String:
	match currency_id:
		"soul_shards":
			return "skull"
		"element_cores":
			return "flask_big_yellow"
		"rune_dust":
			return "flask_big_blue"
		"blueprints":
			return "pickup_blueprint_generated"
	return ""

func _meta_currency_id() -> String:
	var type := str(data.get("type", ""))
	if type == "meta_currency":
		return str(data.get("id", "soul_shards"))
	match type:
		"soul_shard":
			return "soul_shards"
		"element_core":
			return "element_cores"
		"blueprint":
			return "blueprints"
		_:
			return type
