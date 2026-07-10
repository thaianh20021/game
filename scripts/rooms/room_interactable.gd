class_name RoomInteractable
extends Area2D
## One-shot room object: chest, shrine, or shop machine.

signal objective_completed(kind: String, payload: Dictionary)
signal shop_requested(interactable: RoomInteractable, choices: Array)

const SHOP_COST := 12
const SHOP_COST_BY_RARITY := {
	"common": 12,
	"uncommon": 20,
	"rare": 32,
	"epic": 48,
	"legendary": 72,
	"mythic": 96,
}
const BLOOD_ALTAR_HP_COST := 12
const ELEMENT_ALTAR_DAMAGE_BONUS := 0.10
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")
const SHOP_CHOICES := [
	{
		"id": "scrap_pistol",
		"name": "Scrap Pistol",
		"cost": 12,
		"rarity": "common",
		"reward": {"type": "weapon", "id": "scrap_pistol"},
	},
	{
		"id": "hardwood_bow",
		"name": "Hardwood Bow",
		"cost": 14,
		"rarity": "common",
		"reward": {"type": "weapon", "id": "hardwood_bow"},
	},
	{
		"id": "red_flask",
		"name": "Red Flask",
		"cost": 8,
		"rarity": "common",
		"reward": {"type": "potion", "value": 30},
	},
]

var kind := "chest"
var used := false
var shop_choices: Array[Dictionary] = []
var _shop_request_open := false
var _reward_feedback_parts: Array[String] = []
var _allow_full_hp_complete := false
var _interaction_locked := false
var _interaction_locked_text := "Locked"

var _player: Node = null
var _visual: Polygon2D
var _sprite_visual: AnimatedSprite2D
var _prompt: Label

static func release_geometry_contract(runtime_id: String) -> Dictionary:
	var runtime_kind := runtime_id.get_slice(":", 1) if runtime_id.contains(":") else runtime_id
	return {
		"shape_size": Vector2(24, 24),
		"fallback_polygon": release_fallback_polygon(runtime_kind),
	}

static func release_fallback_polygon(runtime_kind: String) -> PackedVector2Array:
	match runtime_kind:
		"shrine":
			return PackedVector2Array([
				Vector2(0, -9), Vector2(7, -1), Vector2(4, 8), Vector2(-4, 8), Vector2(-7, -1),
			])
		"element_altar":
			return PackedVector2Array([
				Vector2(0, -11), Vector2(8, -3), Vector2(8, 5), Vector2(0, 11),
				Vector2(-8, 5), Vector2(-8, -3),
			])
		"shop":
			return PackedVector2Array([
				Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8),
			])
		"trap_cache":
			return PackedVector2Array([
				Vector2(-6, -8), Vector2(6, -8), Vector2(9, 0), Vector2(0, 9), Vector2(-9, 0),
			])
		"blood_altar":
			return PackedVector2Array([
				Vector2(0, -10), Vector2(8, 5), Vector2(3, 9), Vector2(-3, 9), Vector2(-8, 5),
			])
		"rune_cache":
			return PackedVector2Array([
				Vector2(0, -9), Vector2(8, -2), Vector2(6, 8), Vector2(-6, 8), Vector2(-8, -2),
			])
		"cursed_chest":
			return PackedVector2Array([
				Vector2(-8, -6), Vector2(8, -6), Vector2(9, 7), Vector2(-9, 7),
			])
		"locked_chest":
			return PackedVector2Array([
				Vector2(-9, -6), Vector2(9, -6), Vector2(10, 7), Vector2(-10, 7),
			])
		"secret_cache":
			return PackedVector2Array([
				Vector2(0, -10), Vector2(9, -2), Vector2(5, 9), Vector2(-5, 9), Vector2(-9, -2),
			])
	return PackedVector2Array([
		Vector2(-8, -5), Vector2(8, -5), Vector2(8, 7), Vector2(-8, 7),
	])

func configure(p_kind: String, player: Node = null, options: Dictionary = {}) -> void:
	kind = p_kind
	_player = player
	_allow_full_hp_complete = bool(options.get("allow_full_hp_complete", false))
	_interaction_locked = bool(options.get("interaction_locked", false))
	_interaction_locked_text = str(options.get("locked_prompt_text", "Locked")).strip_edges()
	if _interaction_locked_text == "":
		_interaction_locked_text = "Locked"
	set_meta("interaction_locked", _interaction_locked)
	set_meta("locked_prompt_text", _interaction_locked_text)
	set_meta("objective_state", "used" if used else "available")
	set_meta("uses_remaining", 0 if used else 1)
	_bind_player_feedback_signals()
	if kind == "shop":
		if options.has("shop_choices"):
			_set_shop_choices(options.get("shop_choices", SHOP_CHOICES))
		elif options.has("min_weapon_rarity"):
			_set_shop_choices(_generate_shop_choices(options))
		else:
			_set_shop_choices(SHOP_CHOICES)
	_update_visual()

func _ready() -> void:
	add_to_group("room_interactables")
	monitoring = true
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 12.0
		shape.shape = circle
		add_child(shape)
	_ensure_prompt()
	_update_visual()

func _physics_process(_delta: float) -> void:
	if used or _player == null or not is_instance_valid(_player):
		_set_prompt_visible(false)
		return
	var in_range := global_position.distance_to(_player.global_position) <= 13.0
	if in_range:
		_update_prompt_text()
	_set_prompt_visible(in_range)
	if in_range and Input.is_action_just_pressed("interact"):
		use()

func use() -> bool:
	if used:
		_show_blocked_feedback("Already used")
		return false
	if _interaction_locked:
		_show_blocked_feedback(_blocked_prompt_text())
		return false
	_reward_feedback_parts.clear()
	match kind:
		"shrine":
			if _is_player_full_hp():
				if _allow_full_hp_complete:
					_finish({"heal": 0, "full_hp": true})
					return true
				_show_blocked_feedback(_blocked_prompt_text())
				return false
			if _player != null and _player.has_method("heal"):
				_player.heal(30)
				_finish({"heal": 30})
		"element_altar":
			var previous_element := _player_element_name()
			if _player != null and _player.has_method("cycle_element"):
				_player.call("cycle_element")
			var next_element := _player_element_name()
			if next_element == "":
				next_element = previous_element if previous_element != "" else "fire"
			_grant_element_altar_boon(next_element)
			_spawn_element_altar_pulse(next_element)
			_spawn_pickup({"type": "element_cores", "value": 1}, Vector2(0, 10))
			_finish({
				"reward": "element_altar",
				"previous_element": previous_element,
				"element": next_element,
				"boon_id": "element_damage",
				"boon_element": next_element,
				"damage_bonus": ELEMENT_ALTAR_DAMAGE_BONUS,
				"duration": "run",
			})
		"shop":
			if _shop_request_open:
				_show_blocked_feedback("Choose item")
				return false
			_shop_request_open = true
			shop_requested.emit(self, get_shop_choices())
			return false
		"trap_cache":
			_spawn_pickup({"type": "gold", "value": 12}, Vector2(-7, 8))
			_spawn_pickup({"type": "potion", "value": 12}, Vector2(7, 8))
			_finish({"reward": "trap_cache"})
		"blood_altar":
			if not _can_pay_blood_altar_cost():
				_show_blocked_feedback(_blocked_prompt_text())
				return false
			if _player != null and _player.has_method("take_damage"):
				if _player is Player:
					_player.take_damage(BLOOD_ALTAR_HP_COST, global_position, "Blood Altar")
				else:
					_player.take_damage(BLOOD_ALTAR_HP_COST)
					if _player.has_method("record_damage_taken"):
						_player.record_damage_taken("Blood Altar", BLOOD_ALTAR_HP_COST)
			elif _player != null:
				_player.set("hp", maxi(int(_player.get("hp")) - BLOOD_ALTAR_HP_COST, 1))
			_spawn_pickup({"type": "soul_shards", "value": 2}, Vector2(-7, 8))
			_spawn_pickup({"type": "rune_dust", "value": 1}, Vector2(7, 8))
			_finish({"reward": "blood_altar", "cost": "hp"})
		"rune_cache":
			_spawn_pickup({"type": "rune_dust", "value": 4}, Vector2(-7, 8))
			_spawn_pickup({"type": "gold", "value": 10}, Vector2(7, 8))
			_finish({"reward": "rune_cache"})
		"cursed_chest":
			if _player != null and _player.has_method("add_status"):
				_player.add_status("cursed", 8.0)
			_spawn_pickup({"type": "blueprints", "value": 1}, Vector2(-7, 8))
			_spawn_pickup({"type": "gold", "value": 20}, Vector2(7, 8))
			_finish({"reward": "cursed_chest", "status": "cursed"})
		"locked_chest":
			if not _try_spend_key(1):
				_show_blocked_feedback(_blocked_prompt_text())
				return false
			_spawn_pickup({"type": "gold", "value": 24}, Vector2(-7, 8))
			var weapon_id := LootRoller.roll_weapon_id("rare")
			if weapon_id == "":
				weapon_id = "scrap_pistol"
			_spawn_pickup({"type": "weapon", "id": weapon_id}, Vector2(7, 8))
			_finish({"reward": "locked_chest", "cost": "silver_key"})
		"secret_cache":
			_spawn_pickup({"type": "silver_key", "value": 1}, Vector2(-8, 8))
			_spawn_pickup({"type": "rune_dust", "value": 3}, Vector2(0, 10))
			_spawn_pickup({"type": "gold", "value": 30}, Vector2(8, 8))
			_finish({"reward": "secret_cache"})
		_:
			_spawn_pickup({"type": "gold", "value": 18}, Vector2(-7, 8))
			_spawn_pickup({"type": "potion", "value": 15}, Vector2(7, 8))
			_finish({"reward": "chest"})
	return used

func set_interaction_locked(locked: bool, text: String = "") -> void:
	_interaction_locked = locked
	if text.strip_edges() != "":
		_interaction_locked_text = text.strip_edges()
	set_meta("interaction_locked", _interaction_locked)
	set_meta("locked_prompt_text", _interaction_locked_text)
	_update_prompt_text()
	_update_visual()

func get_shop_choices() -> Array:
	var out := []
	for choice in shop_choices:
		out.append(choice.duplicate(true))
	return out

func buy_choice(index: int) -> bool:
	if used:
		_show_blocked_feedback("Already used")
		return false
	if kind != "shop":
		return false
	if index < 0 or index >= shop_choices.size():
		_show_blocked_feedback("Invalid choice")
		return false
	var choice := shop_choices[index]
	var cost := int(choice.get("cost", SHOP_COST))
	if not _try_spend_gold(cost):
		_show_blocked_feedback("Need %d gold" % maxi(cost - _player_gold(), 0))
		return false
	_reward_feedback_parts.clear()
	_spawn_pickup(choice.get("reward", {"type": "weapon", "id": "scrap_pistol"}), Vector2(0, 10))
	_shop_request_open = false
	_finish({"choice": choice.duplicate(true)})
	return true

func skip_shop() -> bool:
	if used:
		_show_blocked_feedback("Already used")
		return false
	if kind != "shop":
		return false
	_shop_request_open = false
	_finish({"skipped": true})
	return true

func _set_shop_choices(choices: Array) -> void:
	shop_choices.clear()
	for choice in choices:
		if choice is Dictionary:
			shop_choices.append(_normalize_shop_choice(choice))
	while shop_choices.size() < 3:
		shop_choices.append(_normalize_shop_choice(SHOP_CHOICES[shop_choices.size()]))
	if shop_choices.size() > 3:
		shop_choices.resize(3)

func _generate_shop_choices(options: Dictionary) -> Array[Dictionary]:
	var min_rarity := str(options.get("min_weapon_rarity", "common"))
	var choices: Array[Dictionary] = []
	var used_weapon_ids := {}
	var desired_weapon_count := 2
	for i in desired_weapon_count:
		var id := _roll_shop_weapon_id(min_rarity, used_weapon_ids)
		if id == "":
			continue
		used_weapon_ids[id] = true
		choices.append({"reward": {"type": "weapon", "id": id}})
	choices.append({
		"id": "red_flask",
		"name": "Red Flask",
		"cost": 8,
		"rarity": "common",
		"reward": {"type": "potion", "value": 30},
	})
	return choices

func _roll_shop_weapon_id(min_rarity: String, used_weapon_ids: Dictionary) -> String:
	var fallback := ""
	for attempt in 8:
		var id := LootRoller.roll_weapon_id(min_rarity)
		if id == "":
			continue
		if fallback == "":
			fallback = id
		if not used_weapon_ids.has(id):
			return id
	return fallback

func _normalize_shop_choice(choice: Dictionary) -> Dictionary:
	var out := choice.duplicate(true)
	var reward: Dictionary = out.get("reward", {})
	var category := str(out.get("category", ""))
	if category == "":
		match str(reward.get("type", "")):
			"weapon":
				category = "Weapon"
			"potion":
				category = "Healing"
			"gold", "soul_shards", "rune_dust", "blueprints":
				category = "Loot"
			_:
				category = "Utility"
	out["category"] = category
	var rarity := str(out.get("rarity", ""))
	if rarity == "" and str(reward.get("type", "")) == "weapon":
		var weapon := WeaponDB.get_weapon(str(reward.get("id", "")))
		rarity = str(weapon.get("rarity", "common"))
		if not out.has("name"):
			out["name"] = str(weapon.get("name", "?"))
	if rarity == "":
		rarity = "common"
	out["rarity"] = rarity
	if not out.has("cost"):
		out["cost"] = int(SHOP_COST_BY_RARITY.get(rarity, SHOP_COST))
	if not out.has("name"):
		out["name"] = "Potion" if str(reward.get("type", "")) == "potion" else "Mystery"
	if not out.has("id") and reward.has("id"):
		out["id"] = str(reward.get("id", ""))
	if not out.has("tags") or Array(out.get("tags", [])).is_empty():
		out["tags"] = _shop_choice_tags(out, reward)
	return out

func _shop_choice_tags(choice: Dictionary, reward: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	match str(reward.get("type", "")):
		"weapon":
			tags.append("weapon")
			var weapon := WeaponDB.get_weapon(str(reward.get("id", "")))
			var group := str(weapon.get("group", ""))
			if group != "":
				tags.append(group)
			var rarity := str(choice.get("rarity", weapon.get("rarity", "")))
			if rarity != "":
				tags.append(rarity)
		"potion":
			tags.append("healing")
		"gold":
			tags.append("gold")
			tags.append("economy")
		"soul_shards":
			tags.append("meta")
			tags.append("soul")
		"rune_dust":
			tags.append("rune")
			tags.append("craft")
		"blueprints":
			tags.append("blueprint")
			tags.append("socket")
		_:
			var category := str(choice.get("category", "utility")).to_lower()
			tags.append(category)
	return tags

func _finish(payload: Dictionary) -> void:
	used = true
	set_meta("objective_state", "used")
	set_meta("uses_remaining", 0)
	_set_prompt_visible(false)
	_update_visual()
	_record_room_decision(_room_decision_label(), _room_decision_reason(payload))
	_play_complete_sfx(payload)
	_show_used_marker()
	_show_completed_feedback(_completed_feedback_text(payload))
	_show_reward_feedback()
	objective_completed.emit(kind, payload)

func _play_complete_sfx(payload: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.objective_complete_cue(_completed_feedback_text(payload))
	var sfx := get_node_or_null("InteractableCompleteSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "InteractableCompleteSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("interactable_kind", kind)
	sfx.set_meta("objective_sound_id", str(cue.get("id", "objective_complete")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "objective_complete")))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _completed_feedback_text(payload: Dictionary) -> String:
	match kind:
		"shrine":
			if bool(payload.get("full_hp", false)):
				return "Full HP"
			return "Healed +%d" % int(payload.get("heal", 0))
		"element_altar":
			return "Element: %s" % _readable_element(str(payload.get("element", "")))
		"shop":
			return "Bought" if payload.has("choice") else "Shop left"
		"locked_chest", "secret_cache", "cursed_chest", "trap_cache", "rune_cache", "chest":
			return "Opened"
	return "Done"

func _show_completed_feedback(text: String) -> void:
	if text == "":
		return
	var old := get_node_or_null("CompletedFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "CompletedFeedback"
	label.text = text
	label.position = Vector2(-18, -38)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.68))
	label.set_meta("interactable_kind", kind)
	label.set_meta("objective_state", "used")
	label.set_meta("completion_text", text)
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -10), 0.65)
	tween.tween_property(label, "modulate:a", 0.0, 0.65)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_reward_feedback() -> void:
	if _reward_feedback_parts.is_empty():
		return
	var old := get_node_or_null("RewardFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "RewardFeedback"
	label.text = " + ".join(_reward_feedback_parts)
	label.position = Vector2(-24, -50)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	label.set_meta("interactable_kind", kind)
	label.set_meta("objective_state", "used")
	label.set_meta("reward_summary", label.text)
	label.set_meta("reward_part_count", _reward_feedback_parts.size())
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -9), 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.7)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _show_used_marker() -> void:
	var marker := get_node_or_null("InteractableUsedMarker") as Label
	if marker == null:
		marker = Label.new()
		marker.name = "InteractableUsedMarker"
		marker.position = Vector2(-14, -18)
		marker.add_theme_font_size_override("font_size", 8)
		marker.add_theme_color_override("font_color", Color(0.62, 0.78, 0.68))
		add_child(marker)
	var marker_text := _used_marker_text()
	marker.text = marker_text
	marker.visible = true
	marker.set_meta("interactable_kind", kind)
	marker.set_meta("objective_state", "used")
	marker.set_meta("uses_remaining", 0)
	marker.set_meta("used_marker_text", marker_text)
	marker.set_meta("used_marker_role", _used_marker_role())

func _used_marker_text() -> String:
	match kind:
		"locked_chest", "secret_cache", "cursed_chest", "trap_cache", "rune_cache", "chest":
			return "OPENED"
	return "USED"

func _used_marker_role() -> String:
	return "opened" if _used_marker_text() == "OPENED" else "used"

func _ensure_prompt() -> void:
	if _prompt != null and is_instance_valid(_prompt):
		return
	_prompt = Label.new()
	_prompt.name = "Prompt"
	_prompt.text = _prompt_text()
	_prompt.position = Vector2(-4, -26)
	_prompt.add_theme_font_size_override("font_size", 10)
	_prompt.visible = false
	add_child(_prompt)
	_apply_prompt_contract()

func _update_prompt_text() -> void:
	if _prompt == null or not is_instance_valid(_prompt):
		return
	_prompt.text = _prompt_text()
	_prompt.position.x = -18.0 if _prompt.text.length() > 1 else -4.0
	_apply_prompt_contract()

func _apply_prompt_contract() -> void:
	if _prompt == null or not is_instance_valid(_prompt):
		return
	var blocked := _compact_blocked_reason(_blocked_prompt_text())
	var reward := _prompt_reward_preview()
	var role := "blocked" if blocked != "" else "interact"
	var state := "blocked" if blocked != "" else ("used" if used else "available")
	_prompt.set_meta("interactable_kind", kind)
	_prompt.set_meta("interactable_label", _room_decision_label())
	_prompt.set_meta("interact_input_action", "interact")
	_prompt.set_meta("interact_key_label", "F")
	_prompt.set_meta("prompt_role", role)
	_prompt.set_meta("objective_state", state)
	_prompt.set_meta("uses_remaining", 0 if used else 1)
	_prompt.set_meta("blocked_reason", blocked)
	_prompt.set_meta("reward_preview", reward)
	_prompt.tooltip_text = "%s [F]%s%s" % [
		_room_decision_label(),
		" | %s" % blocked if blocked != "" else "",
		" | %s" % reward if reward != "" else "",
	]

func _prompt_reward_preview() -> String:
	match kind:
		"shrine":
			return "Heal +30"
		"element_altar":
			return "Element +10% dmg"
		"shop":
			return "Choose 1 of 3"
		"locked_chest":
			return _locked_chest_reward_hint()
		"secret_cache":
			return "Key + Rune Dust + Gold"
		"cursed_chest":
			return "Blueprint + Gold"
		"trap_cache":
			return "Gold + Potion"
		"blood_altar":
			return _blood_altar_reward_hint()
		"rune_cache":
			return "Rune Dust + Gold"
	return "Gold + Potion"

func _prompt_text() -> String:
	var blocked := _blocked_prompt_text()
	if blocked != "":
		return blocked
	match kind:
		"element_altar":
			return "F Element"
	return "F"

func _blocked_prompt_text() -> String:
	if _interaction_locked:
		return _interaction_locked_text
	match kind:
		"shrine":
			return "" if not _is_player_full_hp() else "Full HP"
		"locked_chest":
			return "" if _player_key_count() >= 1 else "Need key x1 | %s" % _locked_chest_reward_hint()
		"blood_altar":
			return "" if _can_pay_blood_altar_cost() else "Need HP >%d | %s" % [
				BLOOD_ALTAR_HP_COST,
				_blood_altar_reward_hint(),
			]
	return ""

func _locked_chest_reward_hint() -> String:
	return "Gold + Weapon"

func _blood_altar_reward_hint() -> String:
	return "Soul + Rune Dust"

func _grant_element_altar_boon(element: String) -> void:
	var clean_element := element.strip_edges()
	if clean_element == "":
		return
	set_meta("element_altar_boon_id", "element_damage")
	set_meta("element_altar_boon_element", clean_element)
	set_meta("element_altar_damage_bonus", ELEMENT_ALTAR_DAMAGE_BONUS)
	set_meta("element_altar_boon_duration", "run")
	_reward_feedback_parts.append("%s +10%% dmg" % clean_element.capitalize())
	if _player == null:
		return
	_player.set_meta("element_altar_boon_id", "element_damage")
	_player.set_meta("element_altar_boon_element", clean_element)
	_player.set_meta("element_altar_damage_bonus", ELEMENT_ALTAR_DAMAGE_BONUS)
	_player.set_meta("element_altar_boon_duration", "run")
	var bonuses_value: Variant = _player.get("element_damage_bonus")
	if not (bonuses_value is Dictionary):
		return
	var bonuses: Dictionary = bonuses_value
	bonuses[clean_element] = float(bonuses.get(clean_element, 0.0)) + ELEMENT_ALTAR_DAMAGE_BONUS
	_player.set("element_damage_bonus", bonuses)
	if _player.has_signal("upgrades_changed"):
		_player.emit_signal("upgrades_changed", "%s +10%%" % clean_element.capitalize())

func _can_pay_blood_altar_cost() -> bool:
	return _player_stat_int("hp", 0) > BLOOD_ALTAR_HP_COST

func _player_key_count() -> int:
	return _player_stat_int("silver_keys", 0)

func _is_player_full_hp() -> bool:
	var max_value := _player_stat_int("max_hp", 0)
	if max_value <= 0:
		return false
	return _player_stat_int("hp", max_value) >= max_value

func _player_stat_int(property_name: String, fallback: int = 0) -> int:
	if _player == null:
		return fallback
	var value = _player.get(property_name)
	return int(value) if value != null else fallback

func _bind_player_feedback_signals() -> void:
	if _player == null:
		return
	_connect_player_feedback_signal("key_changed", "_on_player_key_changed")
	_connect_player_feedback_signal("hp_changed", "_on_player_hp_changed")

func _connect_player_feedback_signal(signal_name: String, method_name: String) -> void:
	if _player == null or not _player.has_signal(signal_name):
		return
	var callback := Callable(self, method_name)
	if not _player.is_connected(signal_name, callback):
		_player.connect(signal_name, callback)

func _on_player_key_changed(_total: int) -> void:
	_update_prompt_text()

func _on_player_hp_changed(_current: int, _max_value: int) -> void:
	_update_prompt_text()

func _set_prompt_visible(value: bool) -> void:
	if _prompt == null or not is_instance_valid(_prompt):
		return
	_prompt.visible = value

func _show_blocked_feedback(text: String) -> void:
	if text == "":
		return
	var compact_reason := _compact_blocked_reason(text)
	set_meta("last_blocked_reason", compact_reason)
	_record_room_decision(_room_decision_label(), "Blocked: %s" % compact_reason)
	_play_blocked_sfx(compact_reason)
	var old := get_node_or_null("BlockedFeedback")
	if old != null:
		remove_child(old)
		old.queue_free()
	var label := Label.new()
	label.name = "BlockedFeedback"
	label.text = text
	label.position = Vector2(-18, -38)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.35))
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -10), 0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.55)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _play_blocked_sfx(reason: String) -> void:
	var cue: Dictionary = AudioCueDBScript.objective_blocked_cue(reason)
	var sfx := get_node_or_null("InteractableBlockedSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "InteractableBlockedSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("interactable_kind", kind)
	sfx.set_meta("blocked_reason", reason)
	sfx.set_meta("objective_sound_id", str(cue.get("id", "objective_blocked")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "objective_blocked")))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _compact_blocked_reason(text: String) -> String:
	if text.begins_with("Need key x1"):
		return "Need key x1"
	if text.begins_with("Need HP"):
		return "Need HP"
	return text

func _record_room_decision(label: String, reason: String = "") -> void:
	if kind == "shop" and not reason.begins_with("Blocked:"):
		return
	if label == "" or _player == null \
			or not _player.has_method("record_room_decision"):
		return
	var entry := "%s|%s" % [label, reason]
	if str(get_meta("last_room_decision_entry", "")) == entry:
		return
	set_meta("last_room_decision_entry", entry)
	_player.call("record_room_decision", label, reason)

func _room_decision_label() -> String:
	match kind:
		"shrine":
			return "Heal Shrine"
		"element_altar":
			return "Element Altar"
		"locked_chest":
			return "Locked Chest"
		"secret_cache":
			return "Secret Cache"
		"cursed_chest":
			return "Cursed Chest"
		"trap_cache":
			return "Trap Cache"
		"blood_altar":
			return "Blood Altar"
		"rune_cache":
			return "Rune Cache"
		"chest":
			return "Chest"
	return kind.replace("_", " ").capitalize()

func _room_decision_reason(payload: Dictionary) -> String:
	match kind:
		"shrine":
			if bool(payload.get("full_hp", false)):
				return "Full HP"
			return "Healed +%d" % int(payload.get("heal", 0))
		"element_altar":
			return "Element: %s" % _readable_element(str(payload.get("element", "")))
		"locked_chest":
			return "Spent key / Gold + Weapon"
		"secret_cache":
			return "Opened / Key + Rune Dust + Gold"
		"cursed_chest":
			return "Opened / Blueprint + Gold / Cursed"
		"trap_cache":
			return "Opened / Gold + Potion"
		"blood_altar":
			return "Paid HP / Soul + Rune Dust"
		"rune_cache":
			return "Opened / Rune Dust + Gold"
		"chest":
			return "Opened / Gold + Potion"
	return _completed_feedback_text(payload)

func _spawn_element_altar_pulse(element: String) -> void:
	var old := get_node_or_null("ElementAltarPulse")
	if old != null:
		old.queue_free()
	var pulse := Line2D.new()
	pulse.name = "ElementAltarPulse"
	pulse.set_meta("element", element)
	pulse.set_meta("boon_id", "element_damage")
	pulse.set_meta("damage_bonus", ELEMENT_ALTAR_DAMAGE_BONUS)
	var radius := 15.0
	var points := PackedVector2Array()
	for i in 25:
		var angle := TAU * float(i) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	pulse.points = points
	pulse.width = 2.0
	pulse.default_color = _element_color(element)
	pulse.z_index = 4
	add_child(pulse)
	var tween := pulse.create_tween()
	tween.tween_property(pulse, "scale", Vector2.ONE * 1.18, 0.5)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(pulse, "queue_free"))

func _player_element_name() -> String:
	if _player == null:
		return ""
	for property_name in ["equipped_element", "element"]:
		var value = _player.get(property_name)
		if value != null and str(value) != "":
			return str(value)
	return ""

func _readable_element(element: String) -> String:
	if element == "":
		return "Shifted"
	return element.capitalize()

func _element_color(element: String) -> Color:
	match element:
		"fire":
			return Color(1.0, 0.42, 0.22, 0.9)
		"ice":
			return Color(0.55, 0.82, 1.0, 0.9)
		"lightning":
			return Color(1.0, 0.92, 0.35, 0.9)
		"poison":
			return Color(0.58, 1.0, 0.42, 0.9)
	return Color(0.72, 0.9, 1.0, 0.9)

func _try_spend_gold(cost: int) -> bool:
	if _player == null:
		return false
	var current := _player_gold()
	if current < cost:
		return false
	var next := current - cost
	_player.set("gold", next)
	if _player.has_signal("gold_changed"):
		_player.emit_signal("gold_changed", next)
	return true

func _player_gold() -> int:
	if _player == null:
		return 0
	var value = _player.get("gold")
	return int(value) if value != null else 0

func _try_spend_key(cost: int) -> bool:
	if _player == null:
		return false
	if _player.has_method("spend_key"):
		return bool(_player.call("spend_key", cost))
	var current := int(_player.get("silver_keys"))
	if current < cost:
		return false
	_player.set("silver_keys", current - cost)
	return true

func _spawn_pickup(data: Dictionary, offset: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	_reward_feedback_parts.append(_pickup_feedback_text(data))
	var pickup := Pickup.new()
	pickup.name = "InteractableDrop"
	pickup.configure(data, _player)
	pickup.global_position = global_position + offset
	pickup.add_to_group("room_pickups")
	parent.add_child(pickup)

func _pickup_feedback_text(data: Dictionary) -> String:
	match str(data.get("type", "")):
		"gold":
			return "Gold +%d" % int(data.get("value", 0))
		"potion":
			return "Potion +%d" % int(data.get("value", 0))
		"silver_key":
			return "Key +%d" % int(data.get("value", 0))
		"rune_dust":
			return "Rune Dust +%d" % int(data.get("value", 0))
		"soul_shards":
			return "Soul +%d" % int(data.get("value", 0))
		"element_cores":
			return "Core +%d" % int(data.get("value", 0))
		"blueprints":
			return "Blueprint +%d" % int(data.get("value", 0))
		"weapon":
			var weapon := WeaponDB.get_weapon(str(data.get("id", "")))
			return "Weapon: %s" % str(weapon.get("name", data.get("id", "Weapon")))
	return "Reward"

func _update_visual() -> void:
	if not is_inside_tree():
		return
	if _try_sprite_visual():
		return
	if _visual == null or not is_instance_valid(_visual):
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		add_child(_visual)
	_visual.visible = true
	match kind:
		"shrine":
			_visual.polygon = PackedVector2Array([
				Vector2(0, -9), Vector2(7, -1), Vector2(4, 8), Vector2(-4, 8), Vector2(-7, -1),
			])
			_visual.color = Color(0.45, 0.9, 0.75)
		"element_altar":
			_visual.polygon = PackedVector2Array([
				Vector2(0, -11), Vector2(8, -3), Vector2(8, 5), Vector2(0, 11),
				Vector2(-8, 5), Vector2(-8, -3),
			])
			_visual.color = Color(0.5, 0.75, 1.0)
		"shop":
			_visual.polygon = PackedVector2Array([
				Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8),
			])
			_visual.color = Color(0.95, 0.7, 0.28)
		"trap_cache":
			_visual.polygon = PackedVector2Array([
				Vector2(-6, -8), Vector2(6, -8), Vector2(9, 0), Vector2(0, 9), Vector2(-9, 0),
			])
			_visual.color = Color(0.75, 0.35, 0.95)
		"blood_altar":
			_visual.polygon = PackedVector2Array([
				Vector2(0, -10), Vector2(8, 5), Vector2(3, 9), Vector2(-3, 9), Vector2(-8, 5),
			])
			_visual.color = Color(0.9, 0.18, 0.22)
		"rune_cache":
			_visual.polygon = PackedVector2Array([
				Vector2(0, -9), Vector2(8, -2), Vector2(6, 8), Vector2(-6, 8), Vector2(-8, -2),
			])
			_visual.color = Color(0.5, 0.55, 1.0)
		"cursed_chest":
			_visual.polygon = PackedVector2Array([
				Vector2(-8, -6), Vector2(8, -6), Vector2(9, 7), Vector2(-9, 7),
			])
			_visual.color = Color(0.5, 0.18, 0.7)
		"locked_chest":
			_visual.polygon = PackedVector2Array([
				Vector2(-9, -6), Vector2(9, -6), Vector2(10, 7), Vector2(-10, 7),
			])
			_visual.color = Color(0.42, 0.56, 0.95)
		"secret_cache":
			_visual.polygon = PackedVector2Array([
				Vector2(0, -10), Vector2(9, -2), Vector2(5, 9), Vector2(-5, 9), Vector2(-9, -2),
			])
			_visual.color = Color(0.8, 0.55, 1.0)
		_:
			_visual.polygon = PackedVector2Array([
				Vector2(-8, -5), Vector2(8, -5), Vector2(8, 7), Vector2(-8, 7),
			])
			_visual.color = Color(0.72, 0.42, 0.18)
	if used:
		_visual.color = _visual.color.darkened(0.45)
	elif _interaction_locked:
		_visual.color = _visual.color.darkened(0.28)

func _try_sprite_visual() -> bool:
	var sprite_name := _sprite_visual_name()
	if sprite_name == "":
		return false
	var frames := SpriteDB.build_sprite_frames({"idle": sprite_name})
	if frames == null:
		return false
	if _sprite_visual == null or not is_instance_valid(_sprite_visual):
		_sprite_visual = AnimatedSprite2D.new()
		_sprite_visual.name = "ObjectSprite"
		_sprite_visual.centered = true
		add_child(_sprite_visual)
	_sprite_visual.sprite_frames = frames
	_sprite_visual.visible = true
	_sprite_visual.modulate = Color.WHITE
	SpriteDB.apply_sprite_metadata(_sprite_visual, sprite_name)
	_sprite_visual.set_meta("objective_state", "used" if used else "available")
	_sprite_visual.set_meta("uses_remaining", 0 if used else 1)
	_sprite_visual.set_meta("disabled_after_use", used)
	if used:
		_sprite_visual.play("idle")
		_sprite_visual.modulate = _sprite_visual.modulate.darkened(0.45)
	else:
		_sprite_visual.stop()
		_sprite_visual.frame = 0
	if _interaction_locked:
		_sprite_visual.modulate = _sprite_visual.modulate.darkened(0.28)
	if _visual != null and is_instance_valid(_visual):
		_visual.visible = false
	return true

func _sprite_visual_name() -> String:
	match kind:
		"shrine":
			return "flask_big_red"
		"shop":
			return "coin_anim"
		"element_altar":
			return "flask_big_yellow"
		"blood_altar":
			return "skull"
		"cursed_chest", "trap_cache":
			return "chest_mimic_open_anim"
		"chest", "locked_chest", "secret_cache", "rune_cache":
			return "chest_empty_open_anim" if used else "chest_full_open_anim"
	return ""
