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
const PREVIEWS := {
	"fire": {"name": "Fire", "status": "Burn DoT", "effect": "Damage over time"},
	"ice": {"name": "Ice", "status": "Slow", "effect": "Movement and attack slow"},
	"lightning": {"name": "Lightning", "status": "Stun", "effect": "Short interrupt window"},
	"poison": {"name": "Poison", "status": "Long DoT", "effect": "Long damage over time"},
}
const ICON_SPRITES := {
	"fire": "flask_red",
	"ice": "flask_blue",
	"lightning": "flask_yellow",
	"poison": "flask_green",
}
const COMBO_DEFS := {
	"fire+ice": {
		"id": "thermal_shock",
		"name": "Thermal Shock",
		"effect": "Instant burst damage",
	},
	"fire+lightning": {
		"id": "plasma",
		"name": "Plasma",
		"effect": "Vulnerability window",
	},
	"fire+poison": {
		"id": "burning_smog",
		"name": "Burning Smog",
		"effect": "Area damage cloud",
	},
	"ice+lightning": {
		"id": "deep_freeze",
		"name": "Deep Freeze",
		"effect": "Short freeze",
	},
	"ice+poison": {
		"id": "frostbane",
		"name": "Frostbane",
		"effect": "Slow plus poison",
	},
	"lightning+poison": {
		"id": "toxic_current",
		"name": "Toxic Current",
		"effect": "Poison chain",
	},
}

static func combo_codex_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for key in ["fire+ice", "fire+lightning", "fire+poison", "ice+lightning", "ice+poison", "lightning+poison"]:
		entries.append(combo_info_from_key(key))
	return entries

static func element_preview(element: String) -> Dictionary:
	var data: Dictionary = PREVIEWS.get(element, {
		"name": element.capitalize(),
		"status": "Status",
		"effect": "",
	})
	var preview := data.duplicate(true)
	preview["id"] = element
	preview["duration"] = status_duration(element)
	preview["combos"] = combos_for_element(element)
	return preview

static func element_icon_sprite(element: String) -> String:
	return str(ICON_SPRITES.get(element, "flask_red"))

static func combos_for_element(element: String) -> Array[Dictionary]:
	var combos: Array[Dictionary] = []
	for combo in combo_codex_entries():
		var elements: Array = combo.get("elements", [])
		if elements.has(element):
			combos.append(combo)
	return combos


static func is_element(status_name: String) -> bool:
	return ELEMENTS.has(status_name)


static func status_duration(element: String) -> float:
	return DURATIONS.get(element, 3.0)


static func combo_info(a: String, b: String) -> Dictionary:
	var pair := [a, b]
	pair.sort()
	return combo_info_from_key("%s+%s" % [pair[0], pair[1]])


static func combo_info_from_key(key: String) -> Dictionary:
	var raw: Dictionary = COMBO_DEFS.get(key, {})
	if raw.is_empty():
		return {}
	var info := raw.duplicate(true)
	info["elements"] = key.split("+")
	return info


## [param enemy] is untyped to avoid a cyclic reference with Enemy.
static func trigger_combo(enemy, a: String, b: String) -> void:
	var pair := [a, b]
	pair.sort()
	var key := "%s+%s" % [pair[0], pair[1]]
	if enemy.has_method("show_combo_feedback"):
		enemy.call("show_combo_feedback", combo_info_from_key(key))
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
