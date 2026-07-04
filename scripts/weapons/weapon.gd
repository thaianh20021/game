class_name Weapon
extends Node2D
## Equipped weapon behavior driven by data/weapons.json stats.
## Stat conversion (1-10 scale -> gameplay values):
##   damage   = dmg * 3
##   cooldown = 1.2 - speed * 0.09 (floor 0.15s)
##   melee reach       = 14 + range * 6 px
##   projectile range  = range * 24 px
## Mana costs are ignored until the class resource system lands.

const MELEE_GROUPS := ["sword_1h", "axe", "dagger", "hammer", "spear", "shield"]
const MAGIC_GROUPS := ["staff", "orb", "tome"]
const PROJECTILE_SPEED := 220.0

var data: Dictionary = {}

var _cd_left := 0.0


func equip(id: String) -> void:
	data = WeaponDB.get_weapon(id)
	assert(not data.is_empty(), "Weapon.equip: unknown weapon id " + id)


func display_name() -> String:
	return str(data.get("name", "?"))


func damage() -> int:
	return int(data.get("dmg", 1)) * 3


func cooldown() -> float:
	return maxf(1.2 - float(data.get("speed", 5)) * 0.09, 0.15)


func is_melee() -> bool:
	return MELEE_GROUPS.has(str(data.get("group", "")))


func melee_reach() -> float:
	return 14.0 + float(data.get("range", 2)) * 6.0


func projectile_range() -> float:
	return float(data.get("range", 6)) * 24.0


func _process(delta: float) -> void:
	_cd_left = maxf(_cd_left - delta, 0.0)


func try_attack(origin: Vector2, aim: Vector2) -> bool:
	if data.is_empty() or _cd_left > 0.0:
		return false
	_cd_left = cooldown()
	if is_melee():
		_melee_hit(origin, aim)
	else:
		_fire_projectile(origin, aim)
	return true


## Placeholder melee: circle hit-check offset toward the aim direction.
## Real weapon animations + hitboxes come with the art milestone.
func _melee_hit(origin: Vector2, aim: Vector2) -> void:
	var reach := melee_reach()
	var hit_center := origin + aim * reach * 0.6
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.global_position.distance_to(hit_center) <= reach:
			enemy.take_damage(damage())


func _fire_projectile(origin: Vector2, aim: Vector2) -> void:
	var projectile := Projectile.new()
	var color := Color(0.5, 0.8, 1.0) if MAGIC_GROUPS.has(str(data.get("group", ""))) \
		else Color(1.0, 0.9, 0.55)
	projectile.setup(aim, PROJECTILE_SPEED, damage(), projectile_range(), color)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin + aim * 10.0
