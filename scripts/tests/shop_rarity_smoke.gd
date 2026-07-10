extends SceneTree

class DummyPlayer:
	extends Node2D
	signal gold_changed(total: int)
	signal weapon_changed(display_name: String)

	var gold := 100
	var picked_weapons: Array[String] = []

	func pickup_weapon(id: String) -> void:
		picked_weapons.append(id)
		weapon_changed.emit(id)

func _init() -> void:
	var failures: Array[String] = []

	await _check_shop_choice_rarity_normalization(failures)
	await _check_shop_overlay_rarity_treatment(failures)

	if failures.is_empty():
		print("Shop rarity smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_shop_choice_rarity_normalization(failures: Array[String]) -> void:
	var parent := Node2D.new()
	var dummy := DummyPlayer.new()
	var shop := RoomInteractable.new()
	root.add_child(parent)
	parent.add_child(dummy)
	parent.add_child(shop)
	shop.configure("shop", dummy, {
		"shop_choices": [
			{"reward": {"type": "weapon", "id": "hunting_crossbow"}},
			{"reward": {"type": "weapon", "id": "scrap_pistol"}},
			{"name": "Red Flask", "reward": {"type": "potion", "value": 30}},
		],
	})
	await process_frame
	var choices := shop.get_shop_choices()
	if choices.size() != 3:
		failures.append("shop should keep exactly three choices")
	if str(choices[0].get("name", "")) != "No San":
		failures.append("weapon shop choice should inherit name from weapon db")
	if str(choices[0].get("rarity", "")) != "uncommon":
		failures.append("weapon shop choice should inherit rarity from weapon db")
	if str(choices[0].get("category", "")) != "Weapon":
		failures.append("weapon shop choice should normalize category")
	if not Array(choices[0].get("tags", [])).has("weapon") or not Array(choices[0].get("tags", [])).has("crossbow"):
		failures.append("weapon shop choice should expose build tags")
	if int(choices[0].get("cost", 0)) <= int(choices[1].get("cost", 0)):
		failures.append("uncommon weapon should cost more than common weapon")
	if str(choices[2].get("rarity", "")) != "common":
		failures.append("potion shop choice should default to common rarity")
	if str(choices[2].get("category", "")) != "Healing":
		failures.append("potion shop choice should normalize category")
	if not Array(choices[2].get("tags", [])).has("healing"):
		failures.append("potion shop choice should expose healing tag")
	parent.queue_free()
	await process_frame

func _check_shop_overlay_rarity_treatment(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.show_shop_choices([
		{"name": "No San", "cost": 20, "rarity": "uncommon", "category": "Weapon", "reward": {"type": "weapon", "id": "hunting_crossbow"}},
		{"name": "Luc Tu Che", "cost": 12, "rarity": "common", "category": "Weapon", "reward": {"type": "weapon", "id": "scrap_pistol"}},
		{"name": "Orb Tro Tan", "cost": 20, "rarity": "uncommon", "category": "Weapon", "reward": {"type": "weapon", "id": "cinder_orb"}},
	], 100)
	await process_frame
	var button := overlay.find_child("ShopChoice_0", true, false) as Button
	if button == null:
		failures.append("shop overlay should create named buttons")
	else:
		if str(button.get_meta("rarity", "")) != "uncommon":
			failures.append("shop button should store rarity metadata")
		if str(button.get_meta("category", "")) != "Weapon":
			failures.append("shop button should store category metadata")
		var tags: Array = button.get_meta("tags", [])
		if not tags.has("weapon") or not tags.has("crossbow"):
			failures.append("shop button should store tags metadata")
		if button.text.find("[UNCOMMON]") == -1:
			failures.append("shop button should show rarity label")
		if button.text.find("Weapon") == -1:
			failures.append("shop button should show category label")
		if button.text.find("Tags:") == -1 or button.text.find("Crossbow") == -1:
			failures.append("shop button should show readable tags")
		if button.modulate == Color.WHITE:
			failures.append("shop button should tint non-common rarity")
	overlay.callv("show_shop_choices", [[
		{"name": "No San", "cost": 20, "rarity": "uncommon", "category": "Weapon", "tags": ["weapon", "crossbow"], "reward": {"type": "weapon", "id": "hunting_crossbow"}},
		{"name": "Red Flask", "cost": 8, "rarity": "common", "category": "Healing", "tags": ["healing"], "reward": {"type": "potion", "value": 30}},
		{"name": "Gold Cache", "cost": 10, "rarity": "common", "category": "Loot", "tags": ["gold", "economy"], "reward": {"type": "gold", "value": 15}},
	], 100, ["crossbow", "weapon"]])
	await process_frame
	button = overlay.find_child("ShopChoice_0", true, false) as Button
	if button == null:
		failures.append("shop build match overlay should keep named buttons")
	else:
		if not bool(button.get_meta("build_match", false)):
			failures.append("shop button should store build match metadata")
		if button.text.find("Synergy:") == -1 or button.text.find("Crossbow") == -1:
			failures.append("shop button should show readable build synergy")
	overlay.queue_free()
	await process_frame
