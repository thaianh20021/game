class_name Weapon
extends Node2D
## Equipped weapon behavior driven by data/weapons.json stats.
## Stat conversion (1-10 scale -> gameplay values):
##   base damage = dmg * 3, then scaled by the player's class damage_mult
##   and crit roll (x1.5)
##   cooldown = 1.2 - speed * 0.09 (floor 0.15s)
##   melee reach = 14 + range * 6 px; projectile range = range * 24 px
## Every hit applies the player's equipped element (elemental combos, GDD 7).
## Mana costs are ignored until the class resource system covers weapons.

const MELEE_GROUPS := ["sword_1h", "axe", "dagger", "hammer", "spear", "shield"]
const MAGIC_GROUPS := ["staff", "orb", "tome"]
const PROJECTILE_SPEED := 220.0
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")

var data: Dictionary = {}

var _cd_left := 0.0


func equip(id: String) -> void:
	data = WeaponDB.get_weapon(id)
	assert(not data.is_empty(), "Weapon.equip: unknown weapon id " + id)


func display_name() -> String:
	return str(data.get("name", "?"))


func base_damage() -> int:
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
		CombatFxScript.spawn_slash(_fx_parent(), origin + aim * melee_reach() * 0.45, aim)
		_melee_hit(origin, aim)
	else:
		CombatFxScript.spawn_muzzle_flash(_fx_parent(), origin + aim * 10.0, aim)
		_fire_projectile(origin, aim)
	return true


func _player() -> Player:
	return get_parent() as Player


func _fx_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return self
	return tree.current_scene if tree.current_scene != null else tree.root


func _roll_damage() -> int:
	var dmg := float(base_damage())
	var player := _player()
	if player != null:
		dmg *= player.damage_mult
		if randf() < player.crit_chance:
			dmg *= 1.5
	return int(round(dmg))


func _element() -> String:
	var player := _player()
	return player.equipped_element if player != null else ""


## Placeholder melee: circle hit-check offset toward the aim direction.
func _melee_hit(origin: Vector2, aim: Vector2) -> void:
	var reach := melee_reach()
	var hit_center := origin + aim * reach * 0.6
	var landed := false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.global_position.distance_to(hit_center) <= reach:
			enemy.hit(_roll_damage(), _element())
			landed = true
	var player := _player()
	if landed and player != null:
		player.on_hit_landed()


func _fire_projectile(origin: Vector2, aim: Vector2) -> void:
	var projectile := Projectile.new()
	var color := Color(0.5, 0.8, 1.0) if MAGIC_GROUPS.has(str(data.get("group", ""))) \
		else Color(1.0, 0.9, 0.55)
	projectile.setup(aim, PROJECTILE_SPEED, _roll_damage(), projectile_range(),
		color, _element(), _player())
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin + aim * 10.0
