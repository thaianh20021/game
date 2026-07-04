class_name ElementSystem
extends RefCounted
## Elemental statuses and combo reactions (GDD section 7, MVP subset of 4
## elements). A combo triggers when an enemy carrying status A is hit by
## element B (A != B). All 6 pairs of the MVP elements are implemented:
##
## | Combo              | Effect                                          |
## | fire + ice         | Thermal Shock: instant burst damage             |
## | fire + lightning   | Plasma: +25% damage taken for 3s (vulnerable)   |
## | fire + poison      | Burning Smog: AoE damage to nearby enemies      |
## | ice + lightning    | Deep Freeze: frozen solid for 2.5s              |
## | ice + poison       | Frostbane: heavy slow + poison DoT              |
## | lightning + poison | Toxic Current: poison chains to 2 neighbors     |

const ELEMENTS := ["fire", "ice", "lightning", "poison"]

## Status duration in seconds when an element is applied.
const DURATIONS := {
	"fire": 4.0,
	"ice": 3.0,
	"lightning": 2.5,  # combo window; the stun itself is 0.3s
	"poison": 5.0,
}


static func is_element(status_name: String) -> bool:
	return ELEMENTS.has(status_name)


static func status_duration(element: String) -> float:
	return DURATIONS.get(element, 3.0)


## [param enemy] is untyped to avoid a cyclic reference with Enemy.
static func trigger_combo(enemy, a: String, b: String) -> void:
	var pair := [a, b]
	pair.sort()
	var key := "%s+%s" % [pair[0], pair[1]]
	match key:
		"fire+ice":  # Thermal Shock
			enemy.take_damage(18)
		"fire+lightning":  # Plasma
			enemy.add_status("vulnerable", 3.0)
		"fire+poison":  # Burning Smog
			for other in enemy.get_tree().get_nodes_in_group("enemies"):
				if other != enemy and is_instance_valid(other) \
						and other.global_position.distance_to(enemy.global_position) <= 44.0:
					other.take_damage(10)
			enemy.take_damage(10)
		"ice+lightning":  # Deep Freeze
			enemy.add_status("frozen", 2.5)
		"ice+poison":  # Frostbane
			enemy.add_status("frostbane", 4.0)
			enemy.add_status("poison", 5.0)
		"lightning+poison":  # Toxic Current
			var chained := 0
			for other in enemy.get_tree().get_nodes_in_group("enemies"):
				if other == enemy or not is_instance_valid(other):
					continue
				if other.global_position.distance_to(enemy.global_position) <= 70.0:
					other.add_status("poison", 5.0)
					chained += 1
					if chained >= 2:
						break
			enemy.add_status("poison", 5.0)
