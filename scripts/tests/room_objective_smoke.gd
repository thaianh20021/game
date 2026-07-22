extends SceneTree

const RoomInteractableScript := preload("res://scripts/rooms/room_interactable.gd")

class DummyPlayer:
	extends Node2D
	signal hp_changed(current: int, max_value: int)
	signal gold_changed(total: int)
	signal weapon_changed(display_name: String)

	var hp := 45
	var max_hp := 100
	var gold := 90
	var silver_keys := 0
	var picked_weapons: Array[String] = []
	var statuses := {}
	var meta_rewards := {}
	var room_decisions: Array[String] = []
	var element := "fire"
	var element_damage_bonus := {}
	var element_cycles := 0

	func heal(amount: int) -> void:
		hp = mini(hp + amount, max_hp)
		hp_changed.emit(hp, max_hp)

	func add_gold(amount: int) -> void:
		gold += amount
		gold_changed.emit(gold)

	func add_key(amount: int) -> void:
		silver_keys += amount

	func spend_key(amount: int = 1) -> bool:
		if silver_keys < amount:
			return false
		silver_keys -= amount
		return true

	func pickup_weapon(id: String) -> void:
		picked_weapons.append(id)
		weapon_changed.emit(id)

	func add_status(status_name: String, duration: float) -> void:
		statuses[status_name] = duration

	func add_meta_currency(currency_id: String, amount: int) -> void:
		meta_rewards[currency_id] = int(meta_rewards.get(currency_id, 0)) + amount

	func cycle_element() -> void:
		element_cycles += 1
		element = "ice" if element == "fire" else "fire"

	func record_room_decision(label: String, reason: String = "") -> void:
		room_decisions.append("%s (%s)" % [label, reason] if reason != "" else label)

	func room_decision_history_summary(_max_items: int = 6) -> String:
		return "None" if room_decisions.is_empty() else " -> ".join(room_decisions)

class FragilePlayer:
	extends Node2D
	signal hp_changed(current: int, max_value: int)

	var hp := 8
	var max_hp := 100
	var damage_taken := 0

	func take_damage(amount: int, _source_position: Vector2 = Vector2.ZERO) -> void:
		damage_taken += amount
		hp = maxi(hp - amount, 0)
		hp_changed.emit(hp, max_hp)

	func add_meta_currency(_currency_id: String, _amount: int) -> void:
		pass

func _init() -> void:
	var failures: Array[String] = []

	await _check_floor_controller_objective_copy(failures)
	await _check_floor_controller_next_action_cues(failures)
	await _check_floor_controller_objective_context(failures)
	await _check_floor_controller_objective_complete_signal(failures)
	await _check_objective_rooms_gate_clear(failures)
	await _check_special_room_live_objective_context(failures)
	await _check_shop_has_three_choices(failures)
	await _check_heal_shrine_is_one_shot(failures)
	await _check_full_hp_heal_room_can_complete(failures)
	await _check_elemental_altar_room(failures)
	await _check_locked_chest_key_gate(failures)
	await _check_secret_cache_reward(failures)
	await _check_optional_locked_chest_spawn(failures)
	await _check_trap_room_features(failures)
	await _check_trap_entered_body_arms_and_triggers(failures)
	await _check_trap_room_survival_persists_on_reenter(failures)
	await _check_floor_remembers_trap_room_survival_before_cache_claim(failures)
	await _check_claimed_room_interactables_do_not_respawn(failures)
	await _check_claimed_optional_combat_chest_does_not_respawn(failures)
	await _check_event_interactable_variants(failures)
	await _check_blood_altar_low_hp_gate(failures)
	await _check_interactable_used_markers(failures)
	await _check_interactable_completion_sfx(failures)

	if failures.is_empty():
		print("Room objective smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_floor_controller_objective_copy(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var cases := [
		{"type": RoomNode.RoomType.COMBAT, "contains": ["Clear room", "Choose reward"]},
		{"type": RoomNode.RoomType.ELITE, "contains": ["Elite fight", "Rare+"]},
		{"type": RoomNode.RoomType.MINIBOSS, "contains": ["Miniboss fight", "Rare+"]},
		{"type": RoomNode.RoomType.BOSS, "contains": ["Defeat boss"]},
		{"type": RoomNode.RoomType.TREASURE, "contains": ["Open chest"]},
		{"type": RoomNode.RoomType.SHOP, "contains": ["Choose", "shop item"]},
	]
	for c in cases:
		var room := RoomNode.new()
		room.type = int(c["type"])
		ctrl.current_room = room
		var objective := ctrl.current_room_objective()
		for part in c["contains"]:
			if not objective.contains(str(part)):
				failures.append("%s objective should include %s, got %s" % [
					RoomNode.RoomType.keys()[int(c["type"])],
					str(part),
					objective,
				])
	ctrl.free()

func _check_floor_controller_next_action_cues(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	if not ctrl.has_method("current_room_next_action"):
		failures.append("FloorController should expose current_room_next_action for HUD next-step cues")
		ctrl.free()
		return
	if not ctrl.has_method("current_room_next_action_key"):
		failures.append("FloorController should expose current_room_next_action_key for HUD cue semantics")
		ctrl.free()
		return
	var cases := [
		{
			"type": RoomNode.RoomType.COMBAT,
			"before": ["Next:", "Defeat"],
			"after": ["Pick", "upgrade"],
			"key_before": "combat",
			"key_after": "reward",
		},
		{
			"type": RoomNode.RoomType.TREASURE,
			"before": ["Next:", "chest", "pick 1 upgrade"],
			"after": ["Pick", "upgrade"],
			"key_before": "interact",
			"key_after": "reward",
		},
		{
			"type": RoomNode.RoomType.SHOP,
			"before": ["Next:", "shop", "1 of 3"],
			"after": ["door"],
			"key_before": "shop",
			"key_after": "door",
		},
		{
			"type": RoomNode.RoomType.BOSS,
			"before": ["Next:", "boss"],
			"after": ["portal"],
			"key_before": "boss",
			"key_after": "portal",
		},
	]
	for i in cases.size():
		var c: Dictionary = cases[i]
		var room := RoomNode.new()
		room.id = i + 10
		room.type = int(c["type"])
		ctrl.current_room = room
		ctrl.cleared_rooms.clear()
		var before := str(ctrl.call("current_room_next_action"))
		for part in c["before"]:
			if not before.contains(str(part)):
				failures.append("%s next action should include %s before clear, got %s" % [
					RoomNode.RoomType.keys()[int(c["type"])],
					str(part),
					before,
				])
		var key_before := str(ctrl.call("current_room_next_action_key"))
		if key_before != str(c["key_before"]):
			failures.append("%s next action key should be %s before clear, got %s" % [
				RoomNode.RoomType.keys()[int(c["type"])],
				str(c["key_before"]),
				key_before,
			])
		ctrl.cleared_rooms[room.id] = true
		var after := str(ctrl.call("current_room_next_action"))
		for part in c["after"]:
			if not after.contains(str(part)):
				failures.append("%s next action should include %s after clear, got %s" % [
					RoomNode.RoomType.keys()[int(c["type"])],
					str(part),
					after,
				])
		var key_after := str(ctrl.call("current_room_next_action_key"))
		if key_after != str(c["key_after"]):
			failures.append("%s next action key should be %s after clear, got %s" % [
				RoomNode.RoomType.keys()[int(c["type"])],
				str(c["key_after"]),
				key_after,
			])
	ctrl.free()

func _check_floor_controller_objective_context(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	if not ctrl.has_method("current_room_objective_context"):
		failures.append("FloorController should expose current_room_objective_context for HUD reward-ready metadata")
		ctrl.free()
		return
	var room := RoomNode.new()
	room.id = 77
	room.type = RoomNode.RoomType.ELITE
	ctrl.current_room = room
	var before: Dictionary = ctrl.call("current_room_objective_context")
	if bool(before.get("reward_ready", true)):
		failures.append("objective context should not mark reward ready before room clear")
	if str(before.get("room_type_name", "")) != "ELITE":
		failures.append("objective context should expose room type name before clear")
	if str(before.get("next_action_key", "")) != "combat":
		failures.append("objective context should expose combat next-action key before clear")
	ctrl.cleared_rooms[room.id] = true
	var after: Dictionary = ctrl.call("current_room_objective_context")
	if not bool(after.get("reward_ready", false)):
		failures.append("objective context should mark reward ready after reward room clear")
	if str(after.get("objective_state", "")) != "reward_ready":
		failures.append("objective context should expose reward_ready objective state")
	if str(after.get("next_action_key", "")) != "reward":
		failures.append("objective context should expose reward next-action key after clear")
	if not str(after.get("completion_text", "")).contains("ELITE complete"):
		failures.append("objective context should include room completion copy")
	ctrl.free()

func _check_floor_controller_objective_complete_signal(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 3
	room.type = RoomNode.RoomType.TREASURE
	var events: Array[String] = []
	if not ctrl.has_signal("room_objective_completed"):
		failures.append("FloorController should expose room_objective_completed")
		return
	ctrl.room_objective_completed.connect(func(text: String) -> void:
		events.append(text))
	ctrl.call("_on_room_cleared", room)
	if events.is_empty():
		failures.append("FloorController should emit room_objective_completed when room clears")
	elif not events.back().contains("TREASURE") or not events.back().contains("Reward"):
		failures.append("objective completion signal should include room type and reward cue")
	ctrl.free()

func _check_objective_rooms_gate_clear(failures: Array[String]) -> void:
	var cases := [
		{"type": RoomNode.RoomType.TREASURE, "label": "treasure"},
		{"type": RoomNode.RoomType.SHOP, "label": "shop"},
		{"type": RoomNode.RoomType.HEAL, "label": "heal"},
		{"type": RoomNode.RoomType.SHRINE, "label": "shrine"},
		{"type": RoomNode.RoomType.EVENT, "label": "event"},
		{"type": RoomNode.RoomType.SECRET, "label": "secret"},
	]
	for c in cases:
		var renderer := RoomRenderer.new()
		root.add_child(renderer)
		var dummy := DummyPlayer.new()
		root.add_child(dummy)
		var clears := {"count": 0}
		renderer.room_cleared.connect(func() -> void:
			clears["count"] += 1)
		renderer.setup(_basic_grid(), [], null, dummy, int(c["type"]))
		await process_frame
		if renderer.is_cleared:
			failures.append("%s room should stay locked until objective use" % c["label"])
		if int(clears["count"]) != 0:
			failures.append("%s room should not emit clear before objective use" % c["label"])

		var objective := _first_interactable(renderer)
		if objective == null:
			failures.append("%s room should spawn an objective interactable" % c["label"])
		else:
			if str(objective.kind) == "shop":
				objective.call("buy_choice", 1)
			elif int(c["type"]) == RoomNode.RoomType.EVENT:
				if not renderer.has_method("complete_trap_room_survival"):
					failures.append("event room should expose complete_trap_room_survival for trap objective gating")
				else:
					renderer.call("complete_trap_room_survival")
					objective.use()
			else:
				objective.use()
			await process_frame
			if not renderer.is_cleared:
				failures.append("%s room should clear after objective use" % c["label"])
			if int(clears["count"]) != 1:
				failures.append("%s room should emit clear once after objective use" % c["label"])
			var banner := renderer.get_node_or_null("RoomClearBanner") as Label
			if banner == null:
				failures.append("%s room should show an objective completion banner" % c["label"])
			elif not banner.text.contains("Objective") or not banner.text.contains("Reward"):
				failures.append("%s objective banner should mention objective and reward" % c["label"])
			var sfx := renderer.get_node_or_null("RoomClearSfx") as AudioStreamPlayer
			if sfx == null:
				failures.append("%s objective clear should create room clear sound placeholder" % c["label"])
			else:
				if str(sfx.get_meta("room_clear_sound_id", "")) != "room_clear_objective":
					failures.append("%s objective clear sound should expose objective cue id" % c["label"])
				if not bool(sfx.get_meta("room_clear_objective", false)):
					failures.append("%s objective clear sound should mark objective clear" % c["label"])
				if str(sfx.get_meta("room_clear_type", "")) != RoomNode.RoomType.keys()[int(c["type"])]:
					failures.append("%s objective clear sound should store room type" % c["label"])
		renderer.queue_free()
		dummy.queue_free()
		await process_frame

func _check_special_room_live_objective_context(failures: Array[String]) -> void:
	var cases := [
		{
			"type": RoomNode.RoomType.TREASURE,
			"label": "treasure",
			"kind": "chest",
			"ready": "Chest ready",
			"used": "Chest opened",
			"key": "interact",
			"reward_kind": "loot_cache",
			"reward_label": "Chest reward",
			"reward_preview": "Gold + Potion",
		},
		{
			"type": RoomNode.RoomType.SHOP,
			"label": "shop",
			"kind": "shop",
			"ready": "Choose 1 of 3",
			"used": "Shop resolved",
			"key": "shop",
			"reward_kind": "shop_choice",
			"reward_label": "Shop choice",
			"reward_preview": "Choose 1 of 3",
		},
		{
			"type": RoomNode.RoomType.HEAL,
			"label": "heal",
			"kind": "shrine",
			"ready": "Heal shrine ready",
			"used": "Heal shrine used",
			"key": "interact",
			"reward_kind": "heal",
			"reward_label": "Heal shrine",
			"reward_preview": "Heal +30",
		},
		{
			"type": RoomNode.RoomType.SHRINE,
			"label": "shrine",
			"kind": "element_altar",
			"ready": "Element altar ready",
			"used": "Element altar used",
			"key": "interact",
			"reward_kind": "element_boon",
			"reward_label": "Element boon",
			"reward_preview": "Core + element damage",
		},
		{
			"type": RoomNode.RoomType.SECRET,
			"label": "secret",
			"kind": "secret_cache",
			"ready": "Secret cache ready",
			"used": "Secret cache opened",
			"key": "interact",
			"reward_kind": "secret_cache",
			"reward_label": "Secret cache",
			"reward_preview": "Key + Rune Dust + Gold",
		},
	]
	for c in cases:
		var renderer := RoomRenderer.new()
		root.add_child(renderer)
		var dummy := DummyPlayer.new()
		if int(c["type"]) == RoomNode.RoomType.HEAL:
			dummy.hp = 40
		root.add_child(dummy)
		renderer.setup(_basic_grid(), [], null, dummy, int(c["type"]))
		await process_frame
		var before: Dictionary = renderer.call("live_objective_context")
		if before.is_empty():
			failures.append("%s room should expose live objective context before use" % c["label"])
		else:
			if str(before.get("interactable_kind", "")) != str(c["kind"]):
				failures.append("%s live context should expose interactable kind" % c["label"])
			if str(before.get("objective_state", "")) != "available":
				failures.append("%s live context should start available" % c["label"])
			if int(before.get("uses_remaining", 0)) != 1:
				failures.append("%s live context should expose one use remaining" % c["label"])
			if not str(before.get("objective_text", "")).contains(str(c["ready"])):
				failures.append("%s live context should show ready objective text" % c["label"])
			if str(before.get("next_action_key", "")) != str(c["key"]):
				failures.append("%s live context should expose next action key" % c["label"])
			if str(before.get("reward_kind", "")) != str(c["reward_kind"]):
				failures.append("%s live context should expose reward kind" % c["label"])
			if str(before.get("reward_label", "")) != str(c["reward_label"]):
				failures.append("%s live context should expose reward label" % c["label"])
			if not str(before.get("reward_preview", "")).contains(str(c["reward_preview"])):
				failures.append("%s live context should expose reward preview" % c["label"])
			if bool(before.get("reward_claimed", true)):
				failures.append("%s live context should start with reward unclaimed" % c["label"])
		var objective := _first_interactable(renderer)
		if objective == null:
			failures.append("%s live context fixture should spawn an objective" % c["label"])
		elif str(objective.kind) == "shop":
			objective.call("buy_choice", 0)
		else:
			objective.use()
		await process_frame
		var after: Dictionary = renderer.call("live_objective_context")
		if after.is_empty():
			failures.append("%s room should expose live objective context after use" % c["label"])
		else:
			if str(after.get("objective_state", "")) != "used":
				failures.append("%s live context should mark objective used after use" % c["label"])
			if int(after.get("uses_remaining", -1)) != 0:
				failures.append("%s live context should expose zero uses after use" % c["label"])
			if not str(after.get("objective_text", "")).contains(str(c["used"])):
				failures.append("%s live context should show resolved objective text after use" % c["label"])
			if str(after.get("next_action_key", "")) != "door":
				failures.append("%s live context should point to doors after use" % c["label"])
			if str(after.get("reward_kind", "")) != str(c["reward_kind"]):
				failures.append("%s used context should preserve reward kind" % c["label"])
			if not bool(after.get("reward_claimed", false)):
				failures.append("%s used context should mark reward claimed" % c["label"])
		renderer.queue_free()
		dummy.queue_free()
		await process_frame

func _check_shop_has_three_choices(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	dummy.position = Vector2(100, 0)
	parent.add_child(dummy)
	var shop := RoomInteractableScript.new()
	shop.configure("shop", dummy)
	parent.add_child(shop)
	await process_frame

	var choices: Array = shop.call("get_shop_choices")
	if choices.size() != 3:
		failures.append("shop should expose three choices")
	for choice in choices:
		if not choice.has("name") or not choice.has("cost") or not choice.has("reward"):
			failures.append("shop choice should include name/cost/reward")
	var before_gold := dummy.gold
	if not bool(shop.call("buy_choice", 2)):
		failures.append("shop should buy a selected choice")
	if dummy.gold >= before_gold:
		failures.append("shop choice should spend gold")
	if _child_group_count(parent, "room_pickups") != 1:
		failures.append("shop selected choice should spawn one pickup")
	if bool(shop.call("buy_choice", 0)):
		failures.append("shop should not allow buying twice")
	parent.queue_free()
	await process_frame

func _check_heal_shrine_is_one_shot(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	dummy.position = Vector2(100, 0)
	parent.add_child(dummy)
	var shrine := RoomInteractableScript.new()
	shrine.configure("shrine", dummy)
	parent.add_child(shrine)
	await process_frame
	var before_hp := dummy.hp
	if not shrine.use():
		failures.append("heal shrine should be usable once")
	if dummy.hp <= before_hp:
		failures.append("heal shrine should restore hp")
	if str(shrine.get_meta("objective_state", "")) != "used":
		failures.append("used heal shrine should expose used objective_state metadata")
	if int(shrine.get_meta("uses_remaining", -1)) != 0:
		failures.append("used heal shrine should expose zero uses_remaining metadata")
	var used_marker := shrine.get_node_or_null("InteractableUsedMarker") as Label
	if used_marker == null:
		failures.append("used heal shrine should show a one-shot used marker")
	else:
		if not used_marker.text.contains("USED"):
			failures.append("used heal shrine marker should say USED")
		if str(used_marker.get_meta("interactable_kind", "")) != "shrine":
			failures.append("used heal shrine marker should store shrine kind metadata")
		if int(used_marker.get_meta("uses_remaining", -1)) != 0:
			failures.append("used heal shrine marker should store zero uses remaining")
	var shrine_sprite := shrine.get_node_or_null("ObjectSprite") as AnimatedSprite2D
	if shrine_sprite == null:
		failures.append("used heal shrine should still expose an object sprite")
	else:
		if not bool(shrine_sprite.get_meta("disabled_after_use", false)):
			failures.append("used heal shrine sprite should expose disabled_after_use metadata")
		if int(shrine_sprite.get_meta("uses_remaining", -1)) != 0:
			failures.append("used heal shrine sprite should expose zero uses remaining")
	var shrine_history := str(dummy.call("room_decision_history_summary"))
	if not shrine_history.contains("Heal Shrine (Healed +30)"):
		failures.append("heal shrine should record heal room decision history")
	var after_hp := dummy.hp
	if shrine.use():
		failures.append("heal shrine should reject second use")
	if dummy.hp != after_hp:
		failures.append("heal shrine should not heal twice")
	var reused := shrine.get_node_or_null("BlockedFeedback") as Label
	if reused == null:
		failures.append("used heal shrine should give feedback when pressed again")
	elif not reused.text.contains("Already used"):
		failures.append("used heal shrine reuse feedback should explain it is already used")
	if str(shrine.get_meta("last_blocked_reason", "")) != "Already used":
		failures.append("used heal shrine should store already-used blocked reason")
	var reused_sfx := shrine.get_node_or_null("InteractableBlockedSfx") as AudioStreamPlayer
	if reused_sfx == null:
		failures.append("used heal shrine should play blocked sound on second use")
	elif str(reused_sfx.get_meta("blocked_reason", "")) != "Already used":
		failures.append("used heal shrine blocked sound should store already-used reason")
	parent.queue_free()
	await process_frame

	var full_parent := Node2D.new()
	root.add_child(full_parent)
	var full := DummyPlayer.new()
	full.hp = full.max_hp
	full_parent.add_child(full)
	var full_shrine := RoomInteractableScript.new()
	full_shrine.configure("shrine", full)
	full_parent.add_child(full_shrine)
	await process_frame
	await physics_frame
	var prompt := full_shrine.get_node_or_null("Prompt") as Label
	if prompt == null:
		failures.append("full-hp shrine should expose prompt")
	elif not prompt.text.contains("Full HP"):
		failures.append("full-hp shrine prompt should explain heal is unavailable")
	if full_shrine.use():
		failures.append("full-hp shrine should not be consumed")
	if full_shrine.used:
		failures.append("full-hp shrine should stay unused")
	var full_history := str(full.call("room_decision_history_summary"))
	if not full_history.contains("Heal Shrine (Blocked: Full HP)"):
		failures.append("full-hp shrine should record blocked heal room decision")
	var blocked := full_shrine.get_node_or_null("BlockedFeedback") as Label
	if blocked == null:
		failures.append("full-hp shrine use should show blocked feedback")
	elif not str(blocked.text).contains("Full HP"):
		failures.append("full-hp shrine blocked feedback should explain heal is unavailable")
	full_parent.queue_free()
	await process_frame

func _check_full_hp_heal_room_can_complete(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	var dummy := DummyPlayer.new()
	dummy.hp = dummy.max_hp
	root.add_child(dummy)
	var clears := {"count": 0}
	renderer.room_cleared.connect(func() -> void:
		clears["count"] += 1)
	renderer.setup(_basic_grid(), [], null, dummy, RoomNode.RoomType.HEAL)
	await process_frame
	var shrine := _first_interactable(renderer)
	if shrine == null:
		failures.append("full-hp heal room should spawn a shrine objective")
	else:
		if not shrine.use():
			failures.append("full-hp heal room shrine should allow objective completion")
		await process_frame
		if not renderer.is_cleared:
			failures.append("full-hp heal room should clear after acknowledging shrine")
		if int(clears["count"]) != 1:
			failures.append("full-hp heal room should emit room_cleared once")
		var feedback := shrine.get_node_or_null("CompletedFeedback") as Label
		if feedback == null or not feedback.text.contains("Full HP"):
			failures.append("full-hp heal room shrine should explain no healing was needed")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_elemental_altar_room(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	var clears := {"count": 0}
	renderer.room_cleared.connect(func() -> void:
		clears["count"] += 1)
	renderer.setup(_basic_grid(), [], null, dummy, RoomNode.RoomType.SHRINE)
	await process_frame
	var altar := _first_interactable(renderer)
	if altar == null:
		failures.append("shrine room should spawn an elemental altar objective")
	else:
		if str(altar.kind) != "element_altar":
			failures.append("shrine room should use element_altar instead of heal shrine")
		var prompt := altar.get_node_or_null("Prompt") as Label
		if prompt == null:
			failures.append("elemental altar should expose a prompt")
		elif not prompt.text.contains("Element"):
			failures.append("elemental altar prompt should preview element cycling")
		var live_before: Dictionary = renderer.call("live_objective_context")
		if not str(live_before.get("objective_text", "")).contains("Core") \
				or not str(live_before.get("objective_text", "")).contains("damage"):
			failures.append("elemental altar live objective should preview core and damage boon")
		var payloads: Array[Dictionary] = []
		altar.objective_completed.connect(func(_kind: String, payload: Dictionary) -> void:
			payloads.append(payload.duplicate(true)))
		if not altar.use():
			failures.append("elemental altar should be usable once")
		await process_frame
		if dummy.element_cycles != 1 or dummy.element != "ice":
			failures.append("elemental altar should cycle the player's element")
		if payloads.is_empty() or str(payloads.back().get("element", "")) != "ice":
			failures.append("elemental altar payload should include the new element")
		elif str(payloads.back().get("boon_id", "")) != "element_damage" \
				or str(payloads.back().get("boon_element", "")) != "ice" \
				or not is_equal_approx(float(payloads.back().get("damage_bonus", 0.0)), 0.10):
			failures.append("elemental altar payload should include the granted element damage boon")
		if not is_equal_approx(float(dummy.element_damage_bonus.get("ice", 0.0)), 0.10):
			failures.append("elemental altar should grant +10% damage to the shifted element")
		if str(altar.get_meta("element_altar_boon_element", "")) != "ice" \
				or not is_equal_approx(float(altar.get_meta("element_altar_damage_bonus", 0.0)), 0.10):
			failures.append("elemental altar should expose boon metadata for HUD/release review")
		if not _has_pickup_type(renderer, "element_cores"):
			failures.append("elemental altar should drop an element core")
		if not renderer.is_cleared or int(clears["count"]) != 1:
			failures.append("elemental altar should complete the shrine room objective")
		var banner := renderer.get_node_or_null("RoomClearBanner") as Label
		if banner == null or not banner.text.contains("Altar"):
			failures.append("elemental altar clear banner should label the room as Altar")
		var feedback := altar.get_node_or_null("CompletedFeedback") as Label
		if feedback == null or not feedback.text.contains("Ice"):
			failures.append("elemental altar completion feedback should mention the new element")
		var reward_feedback := altar.get_node_or_null("RewardFeedback") as Label
		if reward_feedback == null or not reward_feedback.text.contains("Core") \
				or not reward_feedback.text.contains("Ice +10%"):
			failures.append("elemental altar reward feedback should summarize core and damage boon")
		var pulse := altar.get_node_or_null("ElementAltarPulse")
		if pulse == null:
			failures.append("elemental altar should spawn a readable pulse VFX")
		elif str(pulse.get_meta("element", "")) != "ice":
			failures.append("elemental altar pulse should store the new element")
		elif str(pulse.get_meta("boon_id", "")) != "element_damage":
			failures.append("elemental altar pulse should store boon metadata")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_locked_chest_key_gate(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	dummy.position = Vector2(100, 0)
	parent.add_child(dummy)
	var chest := RoomInteractableScript.new()
	chest.configure("locked_chest", dummy)
	parent.add_child(chest)
	await process_frame
	var prompt := chest.get_node_or_null("Prompt") as Label
	if prompt == null:
		failures.append("locked chest should expose a prompt")
	elif not prompt.text.to_lower().contains("key x1") or not prompt.text.contains("Gold") \
			or not prompt.text.contains("Weapon"):
		failures.append("locked chest prompt should preview key cost and rewards")
	if chest.use():
		failures.append("locked chest should not open without a key")
	if chest.used:
		failures.append("locked chest should remain unused without a key")
	var blocked_history := str(dummy.call("room_decision_history_summary"))
	if not blocked_history.contains("Locked Chest (Blocked: Need key x1)"):
		failures.append("locked chest should record blocked key decision history")
	if _child_group_count(parent, "room_pickups") != 0:
		failures.append("locked chest should not drop loot without a key")
	var blocked := chest.get_node_or_null("BlockedFeedback") as Label
	if blocked == null:
		failures.append("locked chest without key should show blocked feedback")
	elif not blocked.text.to_lower().contains("key x1") or not blocked.text.contains("Gold") \
			or not blocked.text.contains("Weapon"):
		failures.append("locked chest blocked feedback should preview key cost and rewards")
	dummy.silver_keys = 1
	chest.call("_update_prompt_text")
	if prompt != null and str(prompt.text) != "F":
		failures.append("locked chest prompt should return to interact key when player has a key")
	if not chest.use():
		failures.append("locked chest should open with a key")
	if dummy.silver_keys != 0:
		failures.append("locked chest should consume one key")
	var open_history := str(dummy.call("room_decision_history_summary"))
	if not open_history.contains("Locked Chest (Spent key / Gold + Weapon)"):
		failures.append("locked chest should record opened key-spend decision history")
	if not _has_pickup_type(parent, "gold"):
		failures.append("locked chest should drop gold")
	if not _has_pickup_type(parent, "weapon"):
		failures.append("locked chest should drop a weapon reward")
	var reward_feedback := chest.get_node_or_null("RewardFeedback") as Label
	if reward_feedback == null:
		failures.append("locked chest should show reward summary feedback")
	elif not reward_feedback.text.contains("Gold") or not reward_feedback.text.contains("Weapon"):
		failures.append("locked chest reward feedback should summarize dropped loot")
	parent.queue_free()
	await process_frame

func _check_secret_cache_reward(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	dummy.position = Vector2(100, 0)
	parent.add_child(dummy)
	var cache := RoomInteractableScript.new()
	cache.configure("secret_cache", dummy)
	parent.add_child(cache)
	await process_frame
	if not cache.use():
		failures.append("secret cache should be usable once")
	if cache.use():
		failures.append("secret cache should reject second use")
	if not _has_pickup_type(parent, "silver_key"):
		failures.append("secret cache should drop a silver key")
	if not _has_pickup_type(parent, "rune_dust"):
		failures.append("secret cache should drop rune dust")
	var reward_feedback := cache.get_node_or_null("RewardFeedback") as Label
	if reward_feedback == null:
		failures.append("secret cache should show reward summary feedback")
	elif not reward_feedback.text.contains("Key") or not reward_feedback.text.contains("Rune"):
		failures.append("secret cache reward feedback should summarize key and rune dust")
	parent.queue_free()
	await process_frame

func _check_optional_locked_chest_spawn(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	renderer.setup(_basic_grid(), [], null, dummy, RoomNode.RoomType.COMBAT, {}, {"locked_chest": true})
	await process_frame
	var chest := _first_interactable(renderer)
	if chest == null or str(chest.kind) != "locked_chest":
		failures.append("combat rooms with locked_chest biome flag should spawn an optional locked chest")
	if not renderer.is_cleared:
		failures.append("optional locked chest should not block combat room clear")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_trap_room_features(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	renderer.setup(_basic_grid(), [], null, dummy, RoomNode.RoomType.EVENT)
	await process_frame
	if _child_group_count(renderer, "room_traps") < 4:
		failures.append("event trap room should spawn at least four traps")
	var warning := renderer.get_node_or_null("TrapRoomWarning") as Label
	if warning == null:
		failures.append("event trap room should show a risk/reward warning")
	elif not warning.text.contains("Trap Room") or not warning.text.contains("Reward"):
		failures.append("trap room warning should name the risk and reward")
	elif int(warning.get_meta("trap_count", 0)) < 4:
		failures.append("trap room warning should expose trap count metadata")
	var countdown := renderer.get_node_or_null("TrapRoomSurvivalCountdown") as Label
	if countdown == null:
		failures.append("event trap room should show a survival countdown")
	else:
		if not countdown.text.contains("Survive") or not countdown.text.contains("4s"):
			failures.append("trap room countdown should show the survival objective and remaining seconds")
		if str(countdown.get_meta("objective_state", "")) != "survive":
			failures.append("trap room countdown should expose survive objective state")
		if float(countdown.get_meta("survive_seconds", 0.0)) != 4.0:
			failures.append("trap room countdown should expose survival duration metadata")
		if float(countdown.get_meta("time_left_seconds", 0.0)) <= 0.0:
			failures.append("trap room countdown should expose positive time-left metadata")
		renderer.call("_update_trap_room_survival_countdown", 1.0)
		if not countdown.text.contains("Hurry") or not countdown.text.contains("1s"):
			failures.append("trap room countdown should show urgent final-second warning")
		if str(countdown.get_meta("countdown_urgency", "")) != "urgent":
			failures.append("trap room countdown should expose urgent countdown metadata")
		if float(countdown.get_meta("time_left_seconds", 0.0)) != 1.0:
			failures.append("trap room urgent countdown should preserve live time-left metadata")
	var live_before: Dictionary = renderer.call("live_objective_context")
	if str(live_before.get("reward_kind", "")) != "trap_cache":
		failures.append("event live context should expose trap cache reward kind")
	if str(live_before.get("countdown_urgency", "")) != "urgent":
		failures.append("event live context should expose urgent trap countdown metadata")
	if not str(live_before.get("objective_text", "")).contains("Hurry"):
		failures.append("event live context should include urgent trap countdown text")
	if str(live_before.get("reward_label", "")) != "Event cache":
		failures.append("event live context should expose event cache reward label")
	if not str(live_before.get("reward_preview", "")).contains("Survive"):
		failures.append("event live context should preview survival-gated cache reward")
	if not bool(live_before.get("reward_locked", false)):
		failures.append("event live context should mark cache reward locked before survival")
	var trap_kinds := {}
	for child in renderer.get_children():
		if not child.is_in_group("room_traps"):
			continue
		trap_kinds[str(child.get("kind"))] = true
		if str(child.get_meta("trap_kind", "")) == "":
			failures.append("event traps should expose trap_kind metadata")
		if int(child.get_meta("damage", 0)) <= 0:
			failures.append("event traps should expose damage metadata")
		if float(child.get_meta("telegraph_seconds", 0.0)) < 0.5:
			failures.append("event traps should expose readable >=0.5s telegraph metadata")
	if trap_kinds.size() < 3:
		failures.append("event trap room should mix at least three trap patterns")
	if _child_group_count(renderer, "room_interactables") != 1:
		failures.append("event trap room should spawn one objective interactable")
	var cache := _first_interactable(renderer)
	if cache == null:
		failures.append("event trap room should expose a reward cache")
	else:
		if not bool(cache.get_meta("interaction_locked", false)):
			failures.append("event trap cache should start locked until survival completes")
		if cache.use():
			failures.append("event trap cache should not open before survival completes")
		var blocked := cache.get_node_or_null("BlockedFeedback") as Label
		if blocked == null or not blocked.text.contains("Survive"):
			failures.append("event trap cache should explain survival gate when blocked")
		if not renderer.has_method("complete_trap_room_survival"):
			failures.append("event trap room should expose complete_trap_room_survival")
		else:
			renderer.call("complete_trap_room_survival")
			await process_frame
			var live_after: Dictionary = renderer.call("live_objective_context")
			if str(live_after.get("reward_kind", "")) != "trap_cache":
				failures.append("event unlocked context should preserve trap cache reward kind")
			if bool(live_after.get("reward_locked", true)):
				failures.append("event unlocked context should mark cache reward unlocked")
			if bool(cache.get_meta("interaction_locked", false)):
				failures.append("event trap cache should unlock after survival completes")
			var survival_history := str(dummy.call("room_decision_history_summary"))
			if not survival_history.contains("Trap Room (Survived") \
					or not survival_history.contains("Cache unlocked"):
				failures.append("event trap room should record survival gate room decision")
			var unlock := renderer.get_node_or_null("TrapRoomSurvived") as Label
			if unlock == null or not unlock.text.contains("Cache unlocked"):
				failures.append("event trap room should show cache unlocked feedback")
			var unlock_sfx := renderer.get_node_or_null("TrapRoomSurvivedSfx") as AudioStreamPlayer
			if unlock_sfx == null:
				failures.append("event trap room should create cache-unlocked sound placeholder")
			else:
				if not bool(unlock_sfx.get_meta("trap_room_survived", false)):
					failures.append("trap room unlock sound should store survived metadata")
				if str(unlock_sfx.get_meta("objective_state", "")) != "complete":
					failures.append("trap room unlock sound should store complete objective state")
				if str(unlock_sfx.get_meta("trap_room_sound_id", "")) != "objective_complete":
					failures.append("trap room unlock sound should expose objective_complete cue")
				if str(unlock_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
					failures.append("trap room unlock sound should come from AudioCueDB")
				if str(unlock_sfx.get_meta("audio_cue_kind", "")) != "objective_complete":
					failures.append("trap room unlock sound should expose objective_complete cue kind")
				if unlock_sfx.stream == null:
					failures.append("trap room unlock sound should assign placeholder stream")
				if DisplayServer.get_name() == "headless" \
						and not bool(unlock_sfx.get_meta("headless_playback_skipped", false)):
					failures.append("trap room unlock sound should skip playback in headless smoke")
			countdown = renderer.get_node_or_null("TrapRoomSurvivalCountdown") as Label
			if countdown == null:
				failures.append("event trap room countdown should remain visible after survival completes")
			else:
				if not countdown.text.contains("Cache unlocked"):
					failures.append("trap room countdown should show cache unlocked after survival completes")
				if str(countdown.get_meta("objective_state", "")) != "complete":
					failures.append("trap room countdown should expose complete objective state")
				if float(countdown.get_meta("time_left_seconds", 1.0)) != 0.0:
					failures.append("trap room countdown should reset time-left metadata after completion")
				if str(countdown.get_meta("countdown_urgency", "")) != "complete":
					failures.append("trap room countdown should clear urgency after completion")
			if not cache.use():
				failures.append("event trap cache should open after survival completes")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_trap_entered_body_arms_and_triggers(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var trap := Trap.new()
	trap.configure("spike", 5, 0.1, 0.5)
	parent.add_child(trap)
	var target := FragilePlayer.new()
	parent.add_child(target)
	await process_frame
	if not trap.has_method("_on_body_entered"):
		failures.append("trap should arm from body_entered, not only polling overlaps")
	else:
		trap.call("_on_body_entered", target)
		if not bool(trap.get_meta("armed_feedback", false)):
			failures.append("trap body_entered should show armed feedback")
		trap.apply_to(target, float(Time.get_ticks_msec()) / 1000.0 + 0.6)
		if target.damage_taken <= 0:
			failures.append("armed trap should damage after telegraph")
	parent.queue_free()
	await process_frame

func _check_trap_room_survival_persists_on_reenter(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	var plan: Array[Dictionary] = []
	renderer.setup(_basic_grid(), plan, null, dummy, RoomNode.RoomType.EVENT, {}, {}, 0, {
		"trap_room_survived": true,
	})
	await process_frame
	if not bool(renderer.get_meta("trap_room_survived", false)):
		failures.append("re-entered survived trap room should restore survived metadata")
	var timer := renderer.get_node_or_null("TrapRoomSurvivalTimer") as Timer
	if timer != null and not timer.is_stopped():
		failures.append("re-entered survived trap room should not restart the survival timer")
	var countdown := renderer.get_node_or_null("TrapRoomSurvivalCountdown") as Label
	if countdown == null:
		failures.append("re-entered survived trap room should still show cache-unlocked status")
	elif not countdown.text.contains("Cache unlocked") \
			or str(countdown.get_meta("objective_state", "")) != "complete":
		failures.append("re-entered survived trap room should restore complete countdown state")
	var cache := _first_interactable(renderer)
	if cache == null:
		failures.append("re-entered survived trap room should keep its cache available")
	elif bool(cache.get_meta("interaction_locked", false)):
		failures.append("re-entered survived trap cache should stay unlocked before claim")
	var live: Dictionary = renderer.call("live_objective_context")
	if bool(live.get("reward_locked", true)):
		failures.append("re-entered survived trap room live context should mark cache reward unlocked")
	if str(live.get("next_action_key", "")) != "interact":
		failures.append("re-entered survived trap room should direct player to open cache")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_floor_remembers_trap_room_survival_before_cache_claim(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	root.add_child(ctrl)
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")

	var entrance := RoomNode.new()
	entrance.id = 0
	entrance.type = RoomNode.RoomType.ENTRANCE
	entrance.door_map = {RoomStamper.Dir.NORTH: 1}
	var event := RoomNode.new()
	event.id = 1
	event.type = RoomNode.RoomType.EVENT
	event.door_map = {RoomStamper.Dir.SOUTH: 0}
	ctrl.rooms = [entrance, event]
	ctrl.floor_seed = 5551313
	ctrl.floor_index = 1
	ctrl._player = player
	ctrl.call("_enter_room", event, entrance.id)
	await process_frame
	var first_renderer := ctrl.get("_renderer") as RoomRenderer
	if first_renderer == null:
		failures.append("floor-level event room should create a renderer")
	else:
		first_renderer.complete_trap_room_survival()
		await process_frame
	var survived_rooms = ctrl.get("trap_room_survived_rooms")
	if not (survived_rooms is Dictionary) or not (survived_rooms as Dictionary).has(event.id):
		failures.append("FloorController should remember survived trap room before cache claim")
	ctrl.call("_enter_room", entrance, event.id)
	await process_frame
	ctrl.call("_enter_room", event, entrance.id)
	await process_frame
	var revisited_renderer := ctrl.get("_renderer") as RoomRenderer
	if revisited_renderer == null:
		failures.append("floor-level re-entered event room should create a renderer")
	else:
		var timer := revisited_renderer.get_node_or_null("TrapRoomSurvivalTimer") as Timer
		if timer != null and not timer.is_stopped():
			failures.append("floor-level re-entered survived trap room should not restart timer")
		var cache := _first_interactable(revisited_renderer)
		if cache == null:
			failures.append("floor-level re-entered survived trap room should keep cache available")
		elif bool(cache.get_meta("interaction_locked", false)):
			failures.append("floor-level re-entered survived trap cache should stay unlocked")
	ctrl.queue_free()
	player.queue_free()
	await process_frame

func _check_claimed_room_interactables_do_not_respawn(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	if _method_arg_count(renderer, "setup") < 9:
		failures.append("RoomRenderer.setup should accept room state options for claimed objectives")
	else:
		var plan: Array[Dictionary] = []
		renderer.callv("setup", [_basic_grid(), plan, null, dummy, RoomNode.RoomType.TREASURE, {}, {}, 0, {
			"interactables_claimed": true,
		}])
		await process_frame
		if _child_group_count(renderer, "room_interactables") != 0:
			failures.append("claimed treasure room should not respawn a reclaimable chest")
		if not renderer.is_cleared:
			failures.append("claimed objective room should reopen doors without another claim")
	var source := FileAccess.get_file_as_string("res://scripts/rooms/floor_controller.gd")
	if not source.contains("interactable_claimed_rooms"):
		failures.append("FloorController should remember rooms whose interactable reward was claimed")
	if not source.contains("interactables_claimed"):
		failures.append("FloorController should pass claimed interactable state into RoomRenderer")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

	var ctrl := FloorController.new()
	root.add_child(ctrl)
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")

	var entrance := RoomNode.new()
	entrance.id = 0
	entrance.type = RoomNode.RoomType.ENTRANCE
	entrance.door_map = {RoomStamper.Dir.NORTH: 1}
	var treasure := RoomNode.new()
	treasure.id = 1
	treasure.type = RoomNode.RoomType.TREASURE
	treasure.door_map = {RoomStamper.Dir.SOUTH: 0}
	ctrl.rooms = [entrance, treasure]
	ctrl.floor_seed = 5551212
	ctrl.floor_index = 1
	ctrl._player = player
	ctrl.call("_enter_room", treasure, entrance.id)
	await process_frame
	var first_renderer := ctrl.get("_renderer") as RoomRenderer
	var first_chest := _first_interactable(first_renderer)
	if first_chest == null:
		failures.append("floor-level treasure room should spawn its first chest")
	elif not first_chest.use():
		failures.append("floor-level treasure chest should be claimable")
	await process_frame
	if not ctrl.interactable_claimed_rooms.has(treasure.id):
		failures.append("FloorController should record claimed treasure room id")
	ctrl.call("_enter_room", entrance, treasure.id)
	await process_frame
	ctrl.call("_enter_room", treasure, entrance.id)
	await process_frame
	var revisited_renderer := ctrl.get("_renderer") as RoomRenderer
	if _first_interactable(revisited_renderer) != null:
		failures.append("re-entered claimed treasure room should not spawn another chest")
	if _child_group_count(revisited_renderer, "room_interactables") != 0:
		failures.append("re-entered claimed treasure room should have no reclaimable interactables")
	if revisited_renderer != null and not revisited_renderer.is_cleared:
		failures.append("re-entered claimed treasure room should stay cleared")
	ctrl.queue_free()
	player.queue_free()
	await process_frame

func _check_claimed_optional_combat_chest_does_not_respawn(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	root.add_child(ctrl)
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	player.silver_keys = 1

	var entrance := RoomNode.new()
	entrance.id = 0
	entrance.type = RoomNode.RoomType.ENTRANCE
	entrance.door_map = {RoomStamper.Dir.NORTH: 1}
	var combat := RoomNode.new()
	combat.id = 1
	combat.type = RoomNode.RoomType.COMBAT
	combat.door_map = {RoomStamper.Dir.SOUTH: 0}
	ctrl.rooms = [entrance, combat]
	ctrl.floor_seed = 5551414
	ctrl.floor_index = 1
	ctrl.current_biome = {"id": "locked_chest_smoke", "locked_chest": true}
	ctrl._player = player
	ctrl.cleared_rooms[combat.id] = true
	ctrl.call("_enter_room", combat, entrance.id)
	await process_frame
	var first_renderer := ctrl.get("_renderer") as RoomRenderer
	var first_chest := _first_interactable(first_renderer)
	if first_chest == null or str(first_chest.kind) != "locked_chest":
		failures.append("combat room with optional chest should spawn its first locked chest")
	elif not first_chest.use():
		failures.append("combat optional locked chest should be claimable once")
	await process_frame
	if not ctrl.interactable_claimed_rooms.has(combat.id):
		failures.append("FloorController should record claimed optional combat chest room id")
	ctrl.call("_enter_room", entrance, combat.id)
	await process_frame
	ctrl.call("_enter_room", combat, entrance.id)
	await process_frame
	var revisited_renderer := ctrl.get("_renderer") as RoomRenderer
	if _first_interactable(revisited_renderer) != null:
		failures.append("re-entered combat room should not respawn claimed optional locked chest")
	if _child_group_count(revisited_renderer, "room_interactables") != 0:
		failures.append("re-entered combat room should have no reclaimable optional chest")
	if _child_group_count(revisited_renderer, "room_traps") < 2:
		failures.append("re-entered combat room should keep non-claim room features after optional chest claim")
	ctrl.queue_free()
	player.queue_free()
	await process_frame

func _check_event_interactable_variants(failures: Array[String]) -> void:
	await _check_event_variant("blood_altar", failures)
	await _check_event_variant("rune_cache", failures)
	await _check_event_variant("cursed_chest", failures)
	var renderer_source := FileAccess.get_file_as_string("res://scripts/rooms/room_renderer.gd")
	if not renderer_source.contains("_event_interactable_kind"):
		failures.append("RoomRenderer should choose event interactable variants")

func _check_blood_altar_low_hp_gate(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var fragile := FragilePlayer.new()
	parent.add_child(fragile)
	var altar := RoomInteractableScript.new()
	altar.configure("blood_altar", fragile)
	parent.add_child(altar)
	await process_frame
	await physics_frame
	var prompt := altar.get_node_or_null("Prompt") as Label
	if prompt == null:
		failures.append("low-hp blood altar should expose a prompt")
	elif not prompt.text.contains("Need HP") or not prompt.text.contains("Soul"):
		failures.append("low-hp blood altar prompt should explain HP cost and reward")
	if altar.use():
		failures.append("blood altar should not activate when HP is too low")
	if altar.used:
		failures.append("blocked blood altar should stay unused")
	if fragile.hp <= 0 or fragile.damage_taken > 0:
		failures.append("blocked blood altar should not damage or kill the player")
	if _child_group_count(parent, "room_pickups") != 0:
		failures.append("blocked blood altar should not spawn rewards")
	var blocked := altar.get_node_or_null("BlockedFeedback") as Label
	if blocked == null:
		failures.append("low-hp blood altar should show blocked feedback")
	elif not blocked.text.contains("Need HP") or not blocked.text.contains("Soul"):
		failures.append("low-hp blood altar blocked feedback should explain HP cost and reward")
	if str(altar.get_meta("last_blocked_reason", "")) != "Need HP":
		failures.append("low-hp blood altar should store compact blocked reason")
	fragile.hp = 25
	altar.call("_update_prompt_text")
	if prompt != null and str(prompt.text) != "F":
		failures.append("blood altar prompt should return to interact key after HP is safe")
	if not altar.use():
		failures.append("blood altar should activate once HP can pay the cost")
	if fragile.hp >= 25:
		failures.append("blood altar should damage the player after successful use")
	if not _has_pickup_type(parent, "soul_shards"):
		failures.append("blood altar should spawn soul shard reward after successful use")
	parent.queue_free()
	await process_frame

func _check_interactable_used_markers(failures: Array[String]) -> void:
	for case in [
		{"kind": "chest", "text": "OPENED", "role": "opened", "keys": 0},
		{"kind": "locked_chest", "text": "OPENED", "role": "opened", "keys": 1},
		{"kind": "rune_cache", "text": "OPENED", "role": "opened", "keys": 0},
		{"kind": "secret_cache", "text": "OPENED", "role": "opened", "keys": 0},
		{"kind": "cursed_chest", "text": "OPENED", "role": "opened", "keys": 0},
		{"kind": "trap_cache", "text": "OPENED", "role": "opened", "keys": 0},
		{"kind": "shrine", "text": "USED", "role": "used", "keys": 0},
		{"kind": "element_altar", "text": "USED", "role": "used", "keys": 0},
		{"kind": "blood_altar", "text": "USED", "role": "used", "keys": 0},
		{"kind": "shop", "text": "USED", "role": "used", "keys": 0, "action": "buy"},
	]:
		var parent := Node2D.new()
		root.add_child(parent)
		var dummy := DummyPlayer.new()
		dummy.silver_keys = int(case["keys"])
		parent.add_child(dummy)
		var object := RoomInteractableScript.new()
		object.configure(str(case["kind"]), dummy)
		parent.add_child(object)
		await process_frame
		var completed := bool(object.call("buy_choice", 0)) \
			if str(case.get("action", "use")) == "buy" else object.use()
		if not completed:
			failures.append("%s should complete for used marker smoke" % str(case["kind"]))
		await process_frame
		var marker := object.get_node_or_null("InteractableUsedMarker") as Label
		if marker == null:
			failures.append("%s should show a persistent used marker after completion" % str(case["kind"]))
		else:
			if not marker.text.contains(str(case["text"])):
				failures.append("%s used marker should read %s" % [str(case["kind"]), str(case["text"])])
			if str(marker.get_meta("interactable_kind", "")) != str(case["kind"]):
				failures.append("%s used marker should store interactable kind" % str(case["kind"]))
			if str(marker.get_meta("objective_state", "")) != "used":
				failures.append("%s used marker should store used objective state" % str(case["kind"]))
			if int(marker.get_meta("uses_remaining", -1)) != 0:
				failures.append("%s used marker should store zero uses remaining" % str(case["kind"]))
			if str(marker.get_meta("used_marker_text", "")) != str(case["text"]):
				failures.append("%s used marker should store text metadata" % str(case["kind"]))
			if str(marker.get_meta("used_marker_role", "")) != str(case["role"]):
				failures.append("%s used marker should store marker role metadata" % str(case["kind"]))
		parent.queue_free()
		await process_frame

func _check_interactable_completion_sfx(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	parent.add_child(dummy)
	var cache := RoomInteractableScript.new()
	cache.configure("rune_cache", dummy)
	parent.add_child(cache)
	await process_frame
	if not cache.use():
		failures.append("rune cache should complete for SFX smoke")
	await process_frame
	var completed := cache.get_node_or_null("CompletedFeedback") as Label
	if completed == null:
		failures.append("interactable completion should show completed feedback")
	else:
		if str(completed.get_meta("interactable_kind", "")) != "rune_cache":
			failures.append("completed feedback should store interactable kind")
		if str(completed.get_meta("objective_state", "")) != "used":
			failures.append("completed feedback should store used objective state")
		if str(completed.get_meta("completion_text", "")) != completed.text:
			failures.append("completed feedback should store readable completion text")
	var reward_feedback := cache.get_node_or_null("RewardFeedback") as Label
	if reward_feedback == null:
		failures.append("interactable reward should show reward feedback")
	else:
		if str(reward_feedback.get_meta("interactable_kind", "")) != "rune_cache":
			failures.append("reward feedback should store interactable kind")
		if str(reward_feedback.get_meta("objective_state", "")) != "used":
			failures.append("reward feedback should store used objective state")
		if str(reward_feedback.get_meta("reward_summary", "")) != reward_feedback.text:
			failures.append("reward feedback should store readable reward summary")
		if int(reward_feedback.get_meta("reward_part_count", 0)) < 2:
			failures.append("reward feedback should expose reward part count")
	var sfx := cache.get_node_or_null("InteractableCompleteSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("interactable completion should create sound placeholder")
	else:
		if str(sfx.get_meta("interactable_kind", "")) != "rune_cache":
			failures.append("interactable completion sound should store interactable kind")
		if str(sfx.get_meta("objective_sound_id", "")) != "objective_complete":
			failures.append("interactable completion sound should expose objective cue id")
		if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("interactable completion sound should come from AudioCueDB")
		if sfx.stream == null:
			failures.append("interactable completion sound should assign an audio stream")
		if not bool(sfx.get_meta("placeholder_audio_stream", false)):
			failures.append("interactable completion sound should mark placeholder stream metadata")
		if DisplayServer.get_name() == "headless" \
				and not bool(sfx.get_meta("headless_playback_skipped", false)):
			failures.append("interactable completion sound should skip playback in headless smoke")
	parent.queue_free()
	await process_frame

func _check_event_variant(kind: String, failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	dummy.position = Vector2(100, 0)
	parent.add_child(dummy)
	var event := RoomInteractableScript.new()
	event.configure(kind, dummy)
	parent.add_child(event)
	await process_frame
	var before_hp := dummy.hp
	if not event.use():
		failures.append("%s should be usable once" % kind)
	if event.use():
		failures.append("%s should reject second use" % kind)
	match kind:
		"blood_altar":
			if dummy.hp >= before_hp:
				failures.append("blood altar should cost hp")
			if not _has_pickup_type(parent, "soul_shards"):
				failures.append("blood altar should spawn soul shard reward")
		"rune_cache":
			if not _has_pickup_type(parent, "rune_dust"):
				failures.append("rune cache should spawn rune dust")
		"cursed_chest":
			if not dummy.statuses.has("cursed"):
				failures.append("cursed chest should apply cursed status")
			if not _has_pickup_type(parent, "blueprints"):
				failures.append("cursed chest should spawn blueprint reward")
	parent.queue_free()
	await process_frame

func _basic_grid() -> TileGrid:
	var grid := TileGrid.new(14, 10, TileGrid.Tile.FLOOR)
	for x in grid.width:
		grid.set_tile(x, 0, TileGrid.Tile.WALL)
		grid.set_tile(x, grid.height - 1, TileGrid.Tile.WALL)
	for y in grid.height:
		grid.set_tile(0, y, TileGrid.Tile.WALL)
		grid.set_tile(grid.width - 1, y, TileGrid.Tile.WALL)
	grid.set_tile(6, 0, TileGrid.Tile.DOOR)
	grid.set_tile(7, 0, TileGrid.Tile.DOOR)
	return grid

func _first_interactable(parent: Node) -> RoomInteractable:
	for child in parent.get_children():
		if child is RoomInteractable:
			return child
	return null

func _child_group_count(parent: Node, group_name: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.is_in_group(group_name):
			count += 1
	return count

func _has_pickup_type(parent: Node, pickup_type: String) -> bool:
	for child in parent.get_children():
		if child is Pickup and str(child.data.get("type", "")) == pickup_type:
			return true
	return false

func _method_arg_count(node: Object, method_name: String) -> int:
	for info in node.get_method_list():
		if str(info.get("name", "")) == method_name:
			return Array(info.get("args", [])).size()
	return -1
