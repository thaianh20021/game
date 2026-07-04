class_name Pickup
extends Node2D
## In-run drop on the floor: gold, potion or weapon. Gold and potions magnet
## to the player; weapons must be walked over deliberately (they replace the
## active weapon slot). Debug shapes until pickup sprites exist.

const MAGNET_RADIUS := 44.0
const COLLECT_RADIUS := 10.0
const MAGNET_SPEED := 150.0

const RARITY_COLORS := {
	"common": Color(0.85, 0.85, 0.85),
	"uncommon": Color(0.4, 0.9, 0.4),
	"rare": Color(0.35, 0.6, 1.0),
	"epic": Color(0.75, 0.4, 1.0),
	"legendary": Color(1.0, 0.6, 0.2),
	"mythic": Color(1.0, 0.3, 0.3),
}

var data: Dictionary = {}

var _player: Node2D
var _sprite: AnimatedSprite2D


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
		"weapon":
			visual.polygon = PackedVector2Array([
				Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4),
			])
			var weapon := WeaponDB.get_weapon(str(data.get("id", "")))
			visual.color = RARITY_COLORS.get(str(weapon.get("rarity", "common")), Color.WHITE)
	add_child(visual)

func _try_sprite_visual() -> bool:
	var type := str(data.get("type", "gold"))
	_sprite = AnimatedSprite2D.new()
	var sprite_frames: SpriteFrames
	match type:
		"gold":
			sprite_frames = SpriteDB.build_sprite_frames({"idle": "coin_anim"})
		"potion":
			sprite_frames = _single_frame_anim("flask_red")
		"weapon":
			var weapon := WeaponDB.get_weapon(str(data.get("id", "")))
			var group := str(weapon.get("group", ""))
			var sprite_name := _weapon_sprite_name(group)
			sprite_frames = _single_frame_anim(sprite_name)
	if sprite_frames == null:
		return false
	_sprite.sprite_frames = sprite_frames
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

func _weapon_sprite_name(group: String) -> String:
	match group:
		"sword_1h":
			return SpriteDB.first_existing(["weapon_regular_sword", "weapon_knight_sword"])
		"bow", "crossbow":
			return SpriteDB.first_existing(["weapon_bow", "weapon_bow_2"])
		"staff", "orb", "tome":
			return SpriteDB.first_existing(["weapon_red_magic_staff", "weapon_green_magic_staff"])
		"dagger":
			return SpriteDB.first_existing(["weapon_knife"])
		"axe":
			return SpriteDB.first_existing(["weapon_axe", "weapon_waraxe"])
		"hammer":
			return SpriteDB.first_existing(["weapon_hammer", "weapon_big_hammer"])
		"spear":
			return SpriteDB.first_existing(["weapon_spear"])
		_:
			return SpriteDB.first_existing(["weapon_regular_sword"])


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= COLLECT_RADIUS:
		_collect()
		return
	if str(data.get("type", "")) != "weapon" and dist <= MAGNET_RADIUS:
		global_position = global_position.move_toward(
			_player.global_position, MAGNET_SPEED * delta)


func _collect() -> void:
	match str(data.get("type", "gold")):
		"gold":
			_player.add_gold(int(data.get("value", 0)))
		"potion":
			_player.heal(int(data.get("value", 0)))
		"weapon":
			_player.pickup_weapon(str(data.get("id", "")))
	queue_free()
