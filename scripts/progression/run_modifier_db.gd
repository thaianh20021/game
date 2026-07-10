class_name RunModifierDB
extends RefCounted

const MODIFIERS := [
	{
		"id": "glass_edges",
		"name": "Glass Edges",
		"desc": "Enemies scale +12%",
		"difficulty_mult": 1.12,
		"reward_bonus": {"gold": 12, "rune_dust": 2},
		"goals": [
			{"id": "elite_hunt", "label": "Elite Hunt", "event": "clear_elite", "target": 1},
			{"id": "clean_clears", "label": "Perfect Clears", "event": "perfect_clear", "target": 2},
		],
		"tags": ["daily", "danger"],
	},
	{
		"id": "ember_pressure",
		"name": "Ember Pressure",
		"desc": "Enemies scale +10%",
		"difficulty_mult": 1.10,
		"reward_bonus": {"gold": 10, "rune_dust": 2},
		"goals": [
			{"id": "event_runner", "label": "Event Room", "event": "clear_event", "target": 1},
			{"id": "mini_boss", "label": "Miniboss", "event": "clear_miniboss", "target": 1},
		],
		"tags": ["daily", "fire"],
	},
	{
		"id": "storm_tempo",
		"name": "Storm Tempo",
		"desc": "Enemies scale +8%",
		"difficulty_mult": 1.08,
		"reward_bonus": {"gold": 8, "rune_dust": 1},
		"goals": [
			{"id": "room_tempo", "label": "Rooms Cleared", "event": "clear_room", "target": 5},
			{"id": "shopper", "label": "Shop Buy", "event": "buy_shop", "target": 1},
		],
		"tags": ["daily", "speed"],
	},
	{
		"id": "iron_trial",
		"name": "Iron Trial",
		"desc": "Enemies scale +15%",
		"difficulty_mult": 1.15,
		"reward_bonus": {"gold": 15, "rune_dust": 2, "soul_shards": 1},
		"goals": [
			{"id": "elite_hunt", "label": "Elite Hunt", "event": "clear_elite", "target": 1},
			{"id": "mini_boss", "label": "Miniboss", "event": "clear_miniboss", "target": 1},
		],
		"tags": ["daily", "elite"],
	},
]

static func all_modifiers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for modifier in MODIFIERS:
		out.append((modifier as Dictionary).duplicate(true))
	return out

static func daily_modifier_for_seed(seed: int) -> Dictionary:
	if seed <= 0 or MODIFIERS.is_empty():
		return {}
	var index := absi((seed * 1103515245 + 12345) % MODIFIERS.size())
	return (MODIFIERS[index] as Dictionary).duplicate(true)

static func balance_lab_modifier(experiment_patch: Dictionary) -> Dictionary:
	if not bool(experiment_patch.get("enabled", false)):
		return {}
	var boss_id := str(experiment_patch.get("id", "boss")).strip_edges()
	var multiplier := float(experiment_patch.get("hp_multiplier", 1.0))
	if boss_id == "" or multiplier <= 0.0:
		return {}
	var patch := experiment_patch.duplicate(true)
	patch["enabled"] = true
	return {
		"id": "balance_lab",
		"name": "Balance Lab",
		"desc": "%s boss HP %.2fx from playtest evidence" % [boss_id, multiplier],
		"difficulty_mult": 1.0,
		"boss_tuning_patch": patch,
		"reward_bonus": {},
		"goals": [
			{"id": "boss_pace", "label": "Boss Pace", "event": "clear_boss", "target": 1},
		],
		"tags": ["balance", "playtest"],
	}

static func summary(modifier: Dictionary) -> String:
	var name := str(modifier.get("name", "")).strip_edges()
	if name == "":
		return ""
	var desc := str(modifier.get("desc", "")).strip_edges()
	return name if desc == "" else "%s: %s" % [name, desc]

static func reward_bonus(modifier: Dictionary) -> Dictionary:
	var raw: Dictionary = modifier.get("reward_bonus", {})
	var out := {}
	for key in ["gold", "soul_shards", "element_cores", "rune_dust", "blueprints"]:
		var amount := maxi(int(raw.get(key, 0)), 0)
		if amount > 0:
			out[key] = amount
	return out

static func reward_bonus_summary(modifier: Dictionary) -> String:
	var bonus := reward_bonus(modifier)
	if bonus.is_empty():
		return ""
	var parts: Array[String] = []
	if int(bonus.get("gold", 0)) > 0:
		parts.append("+%d gold" % int(bonus["gold"]))
	for key in ["soul_shards", "element_cores", "rune_dust", "blueprints"]:
		var amount := int(bonus.get(key, 0))
		if amount <= 0:
			continue
		parts.append("%s +%d" % [_currency_label(key), amount])
	return ", ".join(parts)

static func earned_reward_bonus(modifier: Dictionary, progress: Dictionary) -> Dictionary:
	if modifier.is_empty():
		return {}
	var goals := _goals(modifier)
	if not goals.is_empty() and completed_goal_count(progress) < goals.size():
		return {}
	return reward_bonus(modifier)

static func earned_reward_bonus_summary(modifier: Dictionary, progress: Dictionary) -> String:
	var potential := reward_bonus_summary(modifier)
	if potential == "":
		return ""
	var goals := _goals(modifier)
	if goals.is_empty():
		return "Earned: %s" % potential
	var completed := completed_goal_count(progress)
	if completed < goals.size():
		return "Locked %d/%d goals" % [completed, goals.size()]
	return "Earned: %s" % potential

static func initial_goal_progress(modifier: Dictionary) -> Dictionary:
	var progress := {}
	for goal in _goals(modifier):
		var id := str(goal.get("id", "")).strip_edges()
		if id == "":
			continue
		var target := maxi(int(goal.get("target", 1)), 1)
		progress[id] = {
			"id": id,
			"label": str(goal.get("label", id.capitalize())),
			"event": str(goal.get("event", "")),
			"current": 0,
			"target": target,
			"completed": false,
		}
	return progress

static func advance_goal_progress(
		modifier: Dictionary,
		progress: Dictionary,
		event_id: String,
		amount: int = 1,
) -> Dictionary:
	var out := progress.duplicate(true)
	var delta := maxi(amount, 0)
	if delta <= 0:
		return out
	for goal in _goals(modifier):
		if str(goal.get("event", "")) != event_id:
			continue
		var id := str(goal.get("id", "")).strip_edges()
		if id == "":
			continue
		var target := maxi(int(goal.get("target", 1)), 1)
		var state: Dictionary = out.get(id, {})
		if state.is_empty():
			state = {
				"id": id,
				"label": str(goal.get("label", id.capitalize())),
				"event": event_id,
				"current": 0,
				"target": target,
				"completed": false,
			}
		var current := clampi(int(state.get("current", 0)) + delta, 0, target)
		state["current"] = current
		state["target"] = target
		state["completed"] = current >= target
		out[id] = state
	return out

static func goal_progress_summary(modifier: Dictionary, progress: Dictionary) -> String:
	var goals := _goals(modifier)
	if goals.is_empty():
		return ""
	var parts: Array[String] = []
	var completed := 0
	for goal in goals:
		var id := str(goal.get("id", "")).strip_edges()
		if id == "":
			continue
		var target := maxi(int(goal.get("target", 1)), 1)
		var state: Dictionary = progress.get(id, {})
		var current := clampi(int(state.get("current", 0)), 0, target)
		if current >= target:
			completed += 1
		parts.append("%s %d/%d" % [
			str(goal.get("label", id.capitalize())),
			current,
			target,
		])
	if parts.is_empty():
		return ""
	var prefix := "Goals Complete" if completed >= parts.size() else "Goals"
	return "%s: %s" % [prefix, " | ".join(parts)]

static func completed_goal_count(progress: Dictionary) -> int:
	var count := 0
	for state in progress.values():
		if not (state is Dictionary):
			continue
		var item := state as Dictionary
		if bool(item.get("completed", false)) \
				or int(item.get("current", 0)) >= int(item.get("target", 1)):
			count += 1
	return count

static func _goals(modifier: Dictionary) -> Array:
	var goals: Array = modifier.get("goals", [])
	return goals

static func _currency_label(key: String) -> String:
	match key:
		"soul_shards":
			return "Shard"
		"element_cores":
			return "Core"
		"rune_dust":
			return "Dust"
		"blueprints":
			return "BP"
		_:
			return key.replace("_", " ").capitalize()
