extends SceneTree

const RoomInteractableScript := preload("res://scripts/rooms/room_interactable.gd")
const MainScript := preload("res://scripts/main.gd")
const PlayerScene := preload("res://scenes/player.tscn")

class DummyPlayer:
	extends Node2D
	signal gold_changed(total: int)

	var gold := 30
	var room_decisions: Array[String] = []

	func record_room_decision(label: String, reason: String = "") -> void:
		room_decisions.append("%s (%s)" % [label, reason] if reason != "" else label)

	func room_decision_history_summary(_max_items: int = 6) -> String:
		return "None" if room_decisions.is_empty() else " -> ".join(room_decisions)

func _init() -> void:
	var failures: Array[String] = []

	await _check_shop_requests_choice_before_buy(failures)
	await _check_shop_buy_insufficient_gold_feedback(failures)
	await _check_shop_overlay_choice_signal(failures)
	await _check_shop_choice_input_metadata(failures)
	await _check_shop_flow_cue(failures)
	await _check_shop_overlay_challenge_goal_context(failures)
	await _check_shop_best_fit_skips_unaffordable(failures)
	await _check_shop_overlay_weapon_comparison(failures)
	await _check_renderer_forwards_shop_choice_request(failures)
	await _check_shop_purchase_feedback_choice_metadata(failures)
	await _check_shop_buy_failed_feedback_metadata(failures)
	_check_main_passes_shop_build_tags(failures)
	_check_main_shows_shop_purchase_feedback(failures)
	_check_main_preserves_shop_after_failed_buy(failures)

	if failures.is_empty():
		print("Shop choice smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_shop_requests_choice_before_buy(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	dummy.position = Vector2(100, 0)
	parent.add_child(dummy)
	var shop := RoomInteractableScript.new()
	shop.configure("shop", dummy)
	parent.add_child(shop)
	await process_frame

	var requested := {"count": 0, "choices": []}
	if not _has_signal(shop, "shop_requested"):
		failures.append("shop should expose shop_requested signal")
	else:
		shop.connect("shop_requested", func(interactable: RoomInteractable, choices: Array) -> void:
			if interactable == shop:
				requested["count"] += 1
				requested["choices"] = choices)
	var before_gold := dummy.gold
	if shop.use():
		failures.append("shop use should request choice, not buy immediately")
	if shop.used:
		failures.append("shop should stay unused while choice UI is open")
	if dummy.gold != before_gold:
		failures.append("shop request should not spend gold")
	if int(requested["count"]) != 1:
		failures.append("shop should emit one choice request")
	if Array(requested["choices"]).size() != 3:
		failures.append("shop choice request should include three items")
	if shop.use():
		failures.append("shop should not re-request while choice UI is already open")
	if int(requested["count"]) != 1:
		failures.append("shop repeated use should not emit duplicate request")
	var repeat_feedback := shop.get_node_or_null("BlockedFeedback") as Label
	if repeat_feedback == null:
		failures.append("shop repeated use while choice is open should show feedback")
	elif not repeat_feedback.text.contains("Choose item"):
		failures.append("shop repeated use feedback should point to the open choice UI")
	var repeat_sfx := shop.get_node_or_null("InteractableBlockedSfx") as AudioStreamPlayer
	if repeat_sfx == null:
		failures.append("shop repeated use should create blocked sound placeholder")
	else:
		if str(repeat_sfx.get_meta("blocked_reason", "")) != "Choose item":
			failures.append("shop repeated use sound should store open-choice reason")
		if str(repeat_sfx.get_meta("interactable_kind", "")) != "shop":
			failures.append("shop repeated use sound should store shop kind metadata")
	if shop.buy_choice(99):
		failures.append("shop should reject invalid choice index")
	var invalid_feedback := shop.get_node_or_null("BlockedFeedback") as Label
	if invalid_feedback == null:
		failures.append("shop invalid choice should show blocked feedback")
	elif not invalid_feedback.text.contains("Invalid choice"):
		failures.append("shop invalid choice feedback should explain the bad choice")
	if str(shop.get_meta("last_blocked_reason", "")) != "Invalid choice":
		failures.append("shop invalid choice should store compact invalid-choice reason")
	if shop.used:
		failures.append("invalid shop choice should keep shop usable")
	var invalid_sfx := shop.get_node_or_null("InteractableBlockedSfx") as AudioStreamPlayer
	if invalid_sfx == null:
		failures.append("shop invalid choice should create blocked sound placeholder")
	elif str(invalid_sfx.get_meta("blocked_reason", "")) != "Invalid choice":
		failures.append("shop invalid choice blocked sound should store invalid-choice reason")
	if not shop.buy_choice(1):
		failures.append("shop selected item should buy")
	if not shop.used:
		failures.append("shop should complete after selected buy")
	if shop.buy_choice(0):
		failures.append("shop should reject stale choice clicks after purchase")
	var stale_feedback := shop.get_node_or_null("BlockedFeedback") as Label
	if stale_feedback == null:
		failures.append("shop stale choice click should show already-used feedback")
	elif not stale_feedback.text.contains("Already used"):
		failures.append("shop stale choice click should explain shop is already used")
	var stale_sfx := shop.get_node_or_null("InteractableBlockedSfx") as AudioStreamPlayer
	if stale_sfx == null:
		failures.append("shop stale choice click should create blocked sound placeholder")
	elif str(stale_sfx.get_meta("blocked_reason", "")) != "Already used":
		failures.append("shop stale choice blocked sound should store already-used reason")
	if shop.skip_shop():
		failures.append("shop should reject stale leave clicks after purchase")
	var stale_leave_feedback := shop.get_node_or_null("BlockedFeedback") as Label
	if stale_leave_feedback == null:
		failures.append("shop stale leave click should show already-used feedback")
	elif not stale_leave_feedback.text.contains("Already used"):
		failures.append("shop stale leave feedback should explain shop is already used")
	parent.queue_free()
	await process_frame

func _check_shop_buy_insufficient_gold_feedback(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	dummy.gold = 1
	parent.add_child(dummy)
	var shop := RoomInteractableScript.new()
	shop.configure("shop", dummy, {"shop_choices": [
		{"name": "Expensive", "cost": 99, "reward": {"type": "gold", "value": 1}},
	]})
	parent.add_child(shop)
	await process_frame
	var before_gold := dummy.gold
	if shop.buy_choice(0):
		failures.append("shop should not sell unaffordable choice")
	if dummy.gold != before_gold:
		failures.append("unaffordable shop choice should not spend gold")
	if shop.used:
		failures.append("unaffordable shop choice should keep shop usable")
	var blocked := shop.get_node_or_null("BlockedFeedback") as Label
	if blocked == null:
		failures.append("unaffordable shop choice should show blocked feedback")
	elif not blocked.text.contains("Need 98 gold"):
		failures.append("shop blocked feedback should explain missing gold")
	if str(shop.get_meta("last_blocked_reason", "")) != "Need 98 gold":
		failures.append("unaffordable shop choice should store compact missing-gold reason")
	var history := str(dummy.call("room_decision_history_summary"))
	if not history.contains("Shop (Blocked: Need 98 gold)"):
		failures.append("unaffordable shop choice should record blocked shop decision history")
	var sfx := shop.get_node_or_null("InteractableBlockedSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("unaffordable shop choice should create blocked sound placeholder")
	else:
		if str(sfx.get_meta("blocked_reason", "")) != "Need 98 gold":
			failures.append("unaffordable shop choice sound should store missing-gold reason")
		if str(sfx.get_meta("interactable_kind", "")) != "shop":
			failures.append("unaffordable shop choice sound should store shop kind metadata")
		if str(sfx.get_meta("objective_sound_id", "")) != "objective_blocked":
			failures.append("unaffordable shop choice sound should expose blocked objective cue")
		if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("unaffordable shop choice sound should come from AudioCueDB")
		if sfx.stream == null:
			failures.append("unaffordable shop choice sound should assign a placeholder stream")
		if DisplayServer.get_name() == "headless" \
				and not bool(sfx.get_meta("headless_playback_skipped", false)):
			failures.append("unaffordable shop choice sound should skip playback in headless smoke")
	parent.queue_free()
	await process_frame

func _check_shop_overlay_choice_signal(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	var chosen := {"index": -99}
	if not _has_signal(overlay, "shop_choice_chosen"):
		failures.append("overlay should expose shop_choice_chosen signal")
	else:
		overlay.connect("shop_choice_chosen", func(index: int) -> void:
			chosen["index"] = index)
	if not overlay.has_method("show_shop_choices"):
		failures.append("overlay should expose show_shop_choices")
	else:
		overlay.call("show_shop_choices", [
			{"name": "A", "cost": 10, "reward": {"type": "gold", "value": 1}},
			{
				"name": "B",
				"cost": 20,
				"rarity": "rare",
				"category": "Weapon",
				"tags": ["weapon", "pistol", "fire"],
				"reward": {"type": "weapon", "id": "ember_cannon"},
			},
			{"name": "C", "cost": 40, "reward": {"type": "gold", "value": 1}},
		], 30, ["pistol", "fire"], {"id": "scrap_pistol", "damage": 2})
	await process_frame
	if not overlay.visible:
		failures.append("shop overlay should be visible")
	var scroll := overlay.find_child("ChoiceScroll", true, false) as ScrollContainer
	if scroll == null:
		failures.append("shop overlay should keep choices inside a scroll container")
	elif scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		failures.append("shop overlay choice scroll should allow vertical access")
	elif scroll.anchor_top > 0.1 or scroll.position.y > 240.0:
		failures.append("shop overlay choices should be anchored in the upper half of the screen")
	if _button_count(overlay) != 4:
		failures.append("shop overlay should show three choices plus leave")
	var buttons := _buttons(overlay)
	if buttons.size() >= 3:
		if not buttons[2].disabled:
			failures.append("unaffordable shop choice should be disabled")
		if str(buttons[2].get_meta("disabled_reason", "")) == "":
			failures.append("unaffordable shop choice should store disabled reason")
		if not buttons[2].text.contains("Need 10 gold"):
			failures.append("unaffordable shop choice should explain missing gold")
		if not str(buttons[2].tooltip_text).contains("Need 10 gold"):
			failures.append("unaffordable shop tooltip should explain missing gold")
	if buttons.size() >= 2:
		if not str(buttons[1].text).contains("Choice 2/3"):
			failures.append("shop choices should show readable 1/3 numbering")
		if int(buttons[1].get_meta("choice_display_index", 0)) != 2 \
				or int(buttons[1].get_meta("choice_count", 0)) != 3:
			failures.append("shop choice buttons should store 1-based display index/count metadata")
		if not str(buttons[1].text).contains("Fit:") or not str(buttons[1].text).contains("Build match"):
			failures.append("recommended shop choice should show fit score reasons")
		if not str(buttons[1].text).contains("Best Fit"):
			failures.append("highest-fit shop choice should show Best Fit badge")
		if int(buttons[1].get_meta("fit_score", 0)) < 70:
			failures.append("recommended shop choice should store strong fit score")
		if not str(buttons[1].get_meta("fit_reasons", "")).contains("Build match"):
			failures.append("recommended shop choice should store fit reasons")
		if not bool(buttons[1].get_meta("best_fit", false)):
			failures.append("highest-fit shop choice should store best_fit metadata")
		var shop_tooltip := str(buttons[1].tooltip_text)
		for token in ["Choose shop item 2", "[2]", "B", "rare", "Weapon",
				"20 gold", "Pistol", "Fire", "Fit:", "Best Fit"]:
			if not shop_tooltip.to_lower().contains(token.to_lower()):
				failures.append("shop choice tooltip missing token: %s" % token)
		buttons[1].emit_signal("pressed")
		await process_frame
		if int(chosen["index"]) != 1:
			failures.append("shop overlay should emit selected index")
		if int(overlay.get_meta("last_shop_decision_index", -99)) != 1:
			failures.append("shop overlay should remember selected shop decision index")
		var last_context: Dictionary = overlay.get_meta("last_shop_decision_context", {})
		if str(last_context.get("item_name", "")) != "B":
			failures.append("shop overlay should remember selected shop decision context")
		var last_reason := str(overlay.get_meta("last_shop_decision_reason", ""))
		if not last_reason.contains("Build match") or not last_reason.contains("Best Fit"):
			failures.append("shop overlay should remember readable shop decision reason")
		var sfx := overlay.get_node_or_null("ShopDecisionSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("shop item choice should create decision sound placeholder")
		else:
			if str(sfx.get_meta("shop_sound_id", "")) != "shop_buy":
				failures.append("shop item choice sound should expose buy cue id")
			if str(sfx.get_meta("shop_decision", "")) != "buy":
				failures.append("shop item choice sound should store buy decision metadata")
			if int(sfx.get_meta("shop_choice_index", -1)) != 1:
				failures.append("shop item choice sound should store selected shop index")
			if int(sfx.get_meta("shop_choice_display_index", 0)) != 2:
				failures.append("shop item choice sound should store readable 1-based choice index")
			if int(sfx.get_meta("shop_choice_count", 0)) != 3:
				failures.append("shop item choice sound should store choice count")
			if str(sfx.get_meta("shop_item_name", "")) != "B":
				failures.append("shop item choice sound should store item name")
			if int(sfx.get_meta("shop_cost", 0)) != 20:
				failures.append("shop item choice sound should store item cost")
			if str(sfx.get_meta("shop_choice_rarity", "")) != "rare":
				failures.append("shop item choice sound should store item rarity")
			if str(sfx.get_meta("shop_choice_category", "")) != "Weapon":
				failures.append("shop item choice sound should store item category")
			if not str(sfx.get_meta("shop_choice_tags", "")).contains("Pistol"):
				failures.append("shop item choice sound should store readable item tags")
			if not str(sfx.get_meta("shop_build_match_tags", "")).contains("Fire"):
				failures.append("shop item choice sound should store build match tags")
			if str(sfx.get_meta("shop_recommendation", "")) != "Pistol / Fire":
				failures.append("shop item choice sound should store recommendation context")
			if int(sfx.get_meta("shop_fit_score", 0)) < 70:
				failures.append("shop item choice sound should store selected fit score")
			if not str(sfx.get_meta("shop_fit_reasons", "")).contains("Build match"):
				failures.append("shop item choice sound should store selected fit reasons")
			if not bool(sfx.get_meta("shop_best_fit", false)):
				failures.append("shop item choice sound should store selected best-fit flag")
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("shop item choice sound should come from AudioCueDB")
			if sfx.stream == null:
				failures.append("shop item choice sound should assign an audio stream")
			if DisplayServer.get_name() == "headless" \
					and not bool(sfx.get_meta("headless_playback_skipped", false)):
				failures.append("shop item choice sound should skip playback in headless smoke")
	chosen["index"] = -99
	overlay.call("show_shop_choices", [
		{"name": "A", "cost": 10, "reward": {"type": "gold", "value": 1}},
		{"name": "B", "cost": 20, "reward": {"type": "gold", "value": 1}},
		{"name": "C", "cost": 40, "reward": {"type": "gold", "value": 1}},
	], 30)
	await process_frame
	if not _press_key(overlay, KEY_2):
		failures.append("shop overlay should handle keyboard shortcuts")
	else:
		await process_frame
		if int(chosen["index"]) != 1:
			failures.append("pressing 2 should choose the second shop item")
	chosen["index"] = -99
	overlay.call("show_shop_choices", [
		{"name": "A", "cost": 10, "reward": {"type": "gold", "value": 1}},
		{"name": "B", "cost": 20, "reward": {"type": "gold", "value": 1}},
		{"name": "C", "cost": 40, "reward": {"type": "gold", "value": 1}},
	], 30)
	await process_frame
	if _press_key(overlay, KEY_3):
		await process_frame
		if int(chosen["index"]) != -99:
			failures.append("shop hotkey should not choose a disabled shop item")
	var blocked_subtitle := overlay.find_child("OverlaySubtitle", true, false) as Label
	if blocked_subtitle == null:
		failures.append("disabled shop hotkey should keep overlay subtitle available")
	else:
		if not blocked_subtitle.text.contains("Unavailable: Need 10 gold"):
			failures.append("disabled shop hotkey should show the disabled reason")
		if str(blocked_subtitle.get_meta("hotkey_blocked_kind", "")) != "shop":
			failures.append("disabled shop hotkey should tag blocked shop metadata")
		if str(blocked_subtitle.get_meta("hotkey_blocked_reason", "")) != "Need 10 gold":
			failures.append("disabled shop hotkey should tag missing gold reason metadata")
	if str(overlay.get_meta("last_hotkey_blocked_reason", "")) != "Need 10 gold":
		failures.append("disabled shop hotkey should remember last blocked reason")
	_press_key(overlay, KEY_L)
	await process_frame
	if int(chosen["index"]) != -1:
		failures.append("pressing L should leave the shop")
	var sfx := overlay.get_node_or_null("ShopDecisionSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("shop leave should create decision sound placeholder")
	else:
		if str(sfx.get_meta("shop_sound_id", "")) != "shop_leave":
			failures.append("shop leave sound should expose leave cue id")
		if str(sfx.get_meta("shop_decision", "")) != "leave":
			failures.append("shop leave sound should store leave decision metadata")
	overlay.queue_free()
	await process_frame

func _check_shop_choice_input_metadata(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.show_shop_choices([
		{"name": "A", "cost": 10, "reward": {"type": "gold", "value": 1}},
		{"name": "B", "cost": 20, "reward": {"type": "potion", "value": 20}},
		{"name": "C", "cost": 30, "reward": {"type": "weapon", "id": "scrap_pistol"}},
	], 99)
	await process_frame
	_assert_choice_input_meta(
		overlay.find_child("ShopChoice_0", true, false) as Button,
		"shop_choose",
		"1",
		KEY_1,
		failures)
	_assert_choice_input_meta(
		overlay.find_child("ShopChoice_1", true, false) as Button,
		"shop_choose",
		"2",
		KEY_2,
		failures)
	_assert_choice_input_meta(
		overlay.find_child("ShopChoice_2", true, false) as Button,
		"shop_choose",
		"3",
		KEY_3,
		failures)
	_assert_choice_input_meta(
		overlay.find_child("ShopLeave", true, false) as Button,
		"shop_leave",
		"L",
		KEY_L,
		failures)
	var leave := overlay.find_child("ShopLeave", true, false) as Button
	if leave != null and int(leave.get_meta("choice_alt_hotkey", 0)) != KEY_ESCAPE:
		failures.append("ShopLeave should expose Escape as alternate hotkey metadata")
	overlay.queue_free()
	await process_frame

func _check_shop_flow_cue(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.call("show_shop_choices", [
		{"name": "A", "cost": 10, "reward": {"type": "gold", "value": 1}},
		{"name": "B", "cost": 20, "reward": {"type": "weapon", "id": "ember_cannon"}},
		{"name": "C", "cost": 40, "reward": {"type": "gold", "value": 1}},
	], 30)
	await process_frame
	var flow := overlay.find_child("ShopFlowCueLabel", true, false) as Label
	if flow == null:
		failures.append("shop overlay should show a shop flow cue")
	else:
		for token in ["Choose 1/3", "Gold 30", "Next: Door opens"]:
			if not flow.text.contains(token):
				failures.append("shop flow cue missing token: %s" % token)
		if str(flow.get_meta("flow_kind", "")) != "shop":
			failures.append("shop flow cue should expose shop flow metadata")
		if int(flow.get_meta("choice_count", 0)) != 3:
			failures.append("shop flow cue should store choice count")
		if int(flow.get_meta("gold", 0)) != 30:
			failures.append("shop flow cue should store current gold")
		if str(flow.get_meta("next_action_key", "")) != "door":
			failures.append("shop flow cue should lead back to doors")
	overlay.queue_free()
	await process_frame

func _check_shop_best_fit_skips_unaffordable(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.call("show_shop_choices", [
		{
			"name": "Locked Ember Cannon",
			"cost": 99,
			"rarity": "mythic",
			"category": "Weapon",
			"tags": ["weapon", "pistol", "fire"],
			"reward": {"type": "weapon", "id": "ember_cannon"},
		},
		{"name": "Field Ration", "cost": 10, "category": "Potion", "reward": {"type": "potion", "value": 12}},
		{"name": "Loose Coin", "cost": 12, "category": "Gold", "reward": {"type": "gold", "value": 4}},
	], 30, ["pistol", "fire"], {"id": "scrap_pistol", "damage": 2})
	await process_frame
	var locked := overlay.find_child("ShopChoice_0", true, false) as Button
	var ration := overlay.find_child("ShopChoice_1", true, false) as Button
	if locked == null:
		failures.append("shop best-fit unavailable check should keep locked item button")
	elif not locked.disabled:
		failures.append("unaffordable high-fit shop item should be disabled")
	elif str(locked.text).contains("Best Fit") or bool(locked.get_meta("best_fit", false)):
		failures.append("unaffordable shop item should not receive Best Fit badge")
	if ration == null:
		failures.append("shop best-fit unavailable check should keep affordable fallback button")
	elif not str(ration.text).contains("Best Fit") or not bool(ration.get_meta("best_fit", false)):
		failures.append("best affordable shop item should receive Best Fit badge")

	overlay.call("show_shop_choices", [
		{"name": "Locked A", "cost": 40, "rarity": "rare", "reward": {"type": "gold", "value": 1}},
		{"name": "Locked B", "cost": 50, "rarity": "mythic", "reward": {"type": "gold", "value": 1}},
	], 1)
	await process_frame
	if _has_shop_best_fit(overlay):
		failures.append("all-unaffordable shop choices should not show any Best Fit badge")
	overlay.queue_free()
	await process_frame

func _check_shop_overlay_weapon_comparison(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.callv("show_shop_choices", [[
		{
			"name": "Phao Than Hong",
			"cost": 32,
			"rarity": "rare",
			"category": "Weapon",
			"reward": {"type": "weapon", "id": "ember_cannon"},
		},
	], 99, ["weapon", "pistol"], {"id": "warden_sword"}])
	await process_frame
	var button := overlay.find_child("ShopChoice_0", true, false) as Button
	if button == null:
		failures.append("shop comparison should keep named weapon button")
	else:
		var compare := str(button.get_meta("weapon_comparison", ""))
		if compare == "":
			failures.append("weapon shop choice should store comparison metadata")
		if not button.text.contains("Vs Kiem Ve Binh"):
			failures.append("weapon shop choice should show current weapon comparison")
		if not button.text.contains("Dmg +3") or not button.text.contains("Sockets +2"):
			failures.append("weapon comparison should show readable stat deltas")
		if not button.text.contains("Recommended: Pistol"):
			failures.append("build-matching shop weapon should show recommendation cue")
		if not bool(button.get_meta("recommended", false)):
			failures.append("build-matching shop weapon should store recommendation metadata")
		if int(button.get_meta("fit_score", 0)) < 70:
			failures.append("build-matching shop weapon should store strong fit score")
		if not str(button.get_meta("fit_reasons", "")).contains("Weapon compare"):
			failures.append("build-matching shop weapon should store weapon comparison fit reason")
		if not bool(button.get_meta("best_fit", false)):
			failures.append("single/highest-fit shop weapon should store best_fit metadata")
		var tooltip := str(button.tooltip_text)
		for token in ["Phao Than Hong", "32 gold", "rare", "Weapon", "Vs Kiem Ve Binh",
				"Dmg +3", "Sockets +2", "Recommended: Pistol", "Fit:", "Best Fit"]:
			if not tooltip.to_lower().contains(token.to_lower()):
				failures.append("shop weapon tooltip missing token: %s" % token)
	overlay.queue_free()
	await process_frame

func _check_renderer_forwards_shop_choice_request(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	var dummy := DummyPlayer.new()
	dummy.position = Vector2(100, 0)
	root.add_child(dummy)
	var requested := {"count": 0}
	if not _has_signal(renderer, "shop_choice_requested"):
		failures.append("renderer should expose shop_choice_requested signal")
	else:
		renderer.connect("shop_choice_requested", func(_shop: RoomInteractable, choices: Array) -> void:
			if choices.size() == 3:
				requested["count"] += 1)
	renderer.setup(_basic_grid(), [], null, dummy, RoomNode.RoomType.SHOP)
	await process_frame
	var shop := _first_interactable(renderer)
	if shop == null:
		failures.append("shop renderer should spawn interactable")
	else:
		shop.use()
		await process_frame
		if int(requested["count"]) != 1:
			failures.append("renderer should forward shop choice requests")
		if renderer.is_cleared:
			failures.append("renderer should not clear shop before a selected choice")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_shop_purchase_feedback_choice_metadata(failures: Array[String]) -> void:
	var main: Node2D = MainScript.new()
	var player := PlayerScene.instantiate()
	player.name = "Player"
	main.add_child(player)
	root.add_child(main)
	await process_frame
	if _method_arg_count(main, "_show_shop_purchase_feedback") < 3:
		failures.append("shop purchase feedback should accept selected choice metadata")
		main.queue_free()
		await process_frame
		return
	var choice := {
		"name": "Phao Than Hong",
		"cost": 32,
		"rarity": "rare",
		"category": "Weapon",
		"tags": ["weapon", "pistol", "fire"],
		"reward": {"type": "weapon", "id": "ember_cannon"},
		"recommendation": "Pistol",
		"weapon_comparison": "Dmg +3",
	}
	main.call("_show_shop_purchase_feedback", "Phao Than Hong", 32, choice)
	await process_frame
	var toast := main.get_node_or_null("ShopPurchaseToast") as Label
	if toast == null:
		failures.append("shop purchase feedback should create a toast node")
	else:
		if str(toast.get_meta("shop_item_name", "")) != "Phao Than Hong":
			failures.append("shop purchase toast should store item name metadata")
		if int(toast.get_meta("shop_cost", -1)) != 32:
			failures.append("shop purchase toast should store cost metadata")
		if str(toast.get_meta("shop_choice_rarity", "")) != "rare":
			failures.append("shop purchase toast should store rarity metadata")
		if str(toast.get_meta("shop_choice_category", "")) != "Weapon":
			failures.append("shop purchase toast should store category metadata")
		if not str(toast.get_meta("shop_choice_tags", "")).contains("Pistol"):
			failures.append("shop purchase toast should store readable choice tags")
		if str(toast.get_meta("shop_reward_type", "")) != "weapon":
			failures.append("shop purchase toast should store reward type metadata")
		if str(toast.get_meta("shop_reward_id", "")) != "ember_cannon":
			failures.append("shop purchase toast should store reward id metadata")
		if str(toast.get_meta("shop_recommendation", "")) != "Pistol":
			failures.append("shop purchase toast should store recommendation metadata")
		if str(toast.get_meta("shop_weapon_comparison", "")) != "Dmg +3":
			failures.append("shop purchase toast should store weapon comparison metadata")
		if int(toast.get_meta("shop_fit_score", 0)) < 70:
			failures.append("shop purchase toast should store selected fit score")
		if not str(toast.get_meta("shop_fit_reasons", "")).contains("Build match"):
			failures.append("shop purchase toast should store selected fit reasons")
		if not toast.text.contains("Tags:") or not toast.text.contains("Recommended: Pistol"):
			failures.append("shop purchase toast should summarize tags and recommendation")
		if not toast.text.contains("Fit:") or not toast.text.contains("Build match"):
			failures.append("shop purchase toast should summarize fit score reasons")
	main.queue_free()
	await process_frame

func _check_shop_buy_failed_feedback_metadata(failures: Array[String]) -> void:
	var main: Node2D = MainScript.new()
	var player := PlayerScene.instantiate()
	player.name = "Player"
	player.gold = 1
	main.add_child(player)
	root.add_child(main)
	await process_frame
	if _method_arg_count(main, "_show_shop_buy_failed_feedback") < 2:
		failures.append("shop buy failed feedback should accept item cost")
		main.queue_free()
		await process_frame
		return
	main.call("_show_shop_buy_failed_feedback", "Expensive", 99)
	await process_frame
	var toast := main.get_node_or_null("ShopBuyFailedToast") as Label
	if toast == null:
		failures.append("shop buy failed feedback should create a toast")
	else:
		if not toast.text.contains("Cannot buy Expensive") or not toast.text.contains("Need 98 Gold"):
			failures.append("shop buy failed toast should explain missing gold")
		if toast.text.contains("+0") or toast.text.contains("-0"):
			failures.append("shop buy failed toast should not show zero gold delta")
		if str(toast.get_meta("shop_item_name", "")) != "Expensive":
			failures.append("shop buy failed toast should store item name metadata")
		if int(toast.get_meta("shop_cost", 0)) != 99:
			failures.append("shop buy failed toast should store item cost metadata")
		if int(toast.get_meta("shop_gold", -1)) != 1:
			failures.append("shop buy failed toast should store current gold metadata")
		if int(toast.get_meta("shop_gold_missing", 0)) != 98:
			failures.append("shop buy failed toast should store missing gold metadata")
		if str(toast.get_meta("shop_feedback_kind", "")) != "blocked":
			failures.append("shop buy failed toast should classify feedback as blocked")
	main.queue_free()
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

func _buttons(parent: Node) -> Array[Button]:
	var out: Array[Button] = []
	for child in parent.find_children("*", "Button", true, false):
		out.append(child as Button)
	return out

func _button_count(parent: Node) -> int:
	return _buttons(parent).size()

func _has_shop_best_fit(parent: Node) -> bool:
	for child in parent.find_children("ShopChoice_*", "Button", true, false):
		var button := child as Button
		if button != null and (bool(button.get_meta("best_fit", false)) or str(button.text).contains("Best Fit")):
			return true
	return false

func _has_signal(node: Object, signal_name: String) -> bool:
	for info in node.get_signal_list():
		if str(info.get("name", "")) == signal_name:
			return true
	return false

func _method_arg_count(node: Object, method_name: String) -> int:
	for info in node.get_method_list():
		if str(info.get("name", "")) == method_name:
			return Array(info.get("args", [])).size()
	return -1

func _press_key(node: Node, keycode: int) -> bool:
	if not node.has_method("_unhandled_input"):
		return false
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	node.call("_unhandled_input", event)
	return true

func _assert_choice_input_meta(
		button: Button,
		action: String,
		key_label: String,
		hotkey: int,
		failures: Array[String],
) -> void:
	if button == null:
		failures.append("shop choice input metadata target should exist")
		return
	if str(button.get_meta("choice_input_action", "")) != action:
		failures.append("%s should store input action %s" % [button.name, action])
	if str(button.get_meta("choice_key_label", "")) != key_label:
		failures.append("%s should store key label %s" % [button.name, key_label])
	if int(button.get_meta("choice_hotkey", 0)) != hotkey:
		failures.append("%s should store hotkey %d" % [button.name, hotkey])
	var action_text := str(button.get_meta("choice_action_text", ""))
	if action_text == "":
		failures.append("%s should store readable choice action text" % button.name)
	if not button.tooltip_text.contains(action_text) or not button.tooltip_text.contains(key_label):
		failures.append("%s should expose key/action tooltip text" % button.name)

func _check_main_passes_shop_build_tags(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("show_shop_choices(choices, player.gold,"):
		failures.append("Main should pass player build tags into shop overlay")
	if not source.contains("_run_goal_progress_summary()") \
			or not source.contains("_run_modifier_bonus_status_summary()"):
		failures.append("Main should pass daily challenge goal context into shop overlay")

func _check_shop_overlay_challenge_goal_context(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.show_shop_choices([
		{"name": "No San", "cost": 20, "rarity": "uncommon", "category": "Weapon",
			"tags": ["weapon", "crossbow"], "reward": {"type": "weapon", "id": "hunting_crossbow"}},
		{"name": "Red Flask", "cost": 8, "rarity": "common", "category": "Healing",
			"tags": ["healing"], "reward": {"type": "potion", "value": 30}},
		{"name": "Gold Cache", "cost": 10, "rarity": "common", "category": "Loot",
			"tags": ["gold", "economy"], "reward": {"type": "gold", "value": 15}},
	], 30, ["weapon"], {}, "Goals: Shop Buy 0/1 | Elite Hunt 1/1", "Locked 1/2 goals")
	await process_frame
	var goal := overlay.find_child("ShopChallengeGoalLabel", true, false) as Label
	if goal == null:
		failures.append("shop overlay should expose daily challenge goal progress")
	else:
		if not goal.visible or not goal.text.contains("Shop Buy 0/1") \
				or not goal.text.contains("Locked 1/2 goals"):
			failures.append("shop overlay challenge goal label should show progress and bonus status")
		if str(goal.get_meta("run_goal_summary", "")) != "Goals: Shop Buy 0/1 | Elite Hunt 1/1":
			failures.append("shop overlay challenge goal label should store raw goal summary metadata")
		if str(goal.get_meta("challenge_bonus_status", "")) != "Locked 1/2 goals":
			failures.append("shop overlay challenge goal label should store bonus status metadata")
	overlay.queue_free()
	await process_frame

func _check_main_shows_shop_purchase_feedback(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("_show_shop_purchase_feedback"):
		failures.append("Main should show feedback after buying a shop choice")
	if not source.contains("_pending_shop.get_shop_choices()"):
		failures.append("shop purchase feedback should read selected shop choice data")
	if not source.contains("ShopPurchaseToast"):
		failures.append("shop purchase feedback should create a named toast")
	if not source.contains("_show_shop_leave_feedback"):
		failures.append("Main should show feedback after leaving a shop")
	if not source.contains("ShopLeaveToast"):
		failures.append("shop leave feedback should create a named toast")
	if not source.contains("Shop left"):
		failures.append("shop leave feedback should explicitly say the shop was left")
	if not source.contains("record_room_decision(\"Shop\""):
		failures.append("shop leave should be recorded as a room decision for run recap")

func _check_main_preserves_shop_after_failed_buy(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("_show_shop_buy_failed_feedback"):
		failures.append("Main should show feedback if a shop buy fails after selection")
	if not source.contains("if not _pending_shop.buy_choice(index):"):
		failures.append("Main should branch on failed shop purchases")
	if not source.contains("_overlay.show_shop_choices(_pending_shop.get_shop_choices(), player.gold"):
		failures.append("failed shop buy should reopen shop choices with current gold")
	if not source.contains("return # keep pending shop open"):
		failures.append("failed shop buy should keep pending shop instead of closing the objective")
	if not source.contains("_show_shop_buy_failed_feedback(str(choice.get(\"name\", \"Item\")), int(choice.get(\"cost\", 0)))"):
		failures.append("failed shop buy feedback should receive selected item cost")
