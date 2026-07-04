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


func configure(p_data: Dictionary, player: Node2D) -> void:
	data = p_data
	_player = player


func _ready() -> void:
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
