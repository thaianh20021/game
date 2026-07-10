extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	await _check_reward_choice_icons(failures)
	await _check_shop_choice_icons(failures)

	if failures.is_empty():
		print("Overlay icon smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_reward_choice_icons(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.show_room_upgrade_choices([
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP", "tags": ["survival", "hp"]},
		{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage", "tags": ["damage", "fire"]},
		{"id": "lucky_coin", "name": "Lucky Coin", "desc": "+15 gold", "tags": ["economy", "gold"]},
	], RoomNode.RoomType.TREASURE)
	await process_frame
	_assert_button_icon(overlay, "Upgrade_vital_core", "flask_big_red", failures)
	_assert_button_icon(overlay, "Upgrade_ember_rune", "flask_red", failures)
	_assert_button_icon(overlay, "Upgrade_lucky_coin", "coin_anim", failures)
	overlay.queue_free()
	await process_frame

func _check_shop_choice_icons(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.show_shop_choices([
		{
			"name": "Red Flask",
			"cost": 8,
			"rarity": "common",
			"category": "Healing",
			"reward": {"type": "potion", "value": 30},
		},
		{
			"name": "Gold Cache",
			"cost": 4,
			"rarity": "common",
			"category": "Loot",
			"reward": {"type": "gold", "value": 12},
		},
		{
			"name": "Scrap Pistol",
			"cost": 12,
			"rarity": "common",
			"category": "Weapon",
			"reward": {"type": "weapon", "id": "scrap_pistol"},
		},
	], 99)
	await process_frame
	_assert_button_icon(overlay, "ShopChoice_0", "flask_red", failures)
	_assert_button_icon(overlay, "ShopChoice_1", "coin_anim", failures)
	_assert_button_icon(overlay, "ShopChoice_2", "weapon_pistol_generated", failures)
	overlay.queue_free()
	await process_frame

func _assert_button_icon(parent: Node, node_name: String, sprite_name: String, failures: Array[String]) -> void:
	var button := parent.find_child(node_name, true, false) as Button
	if button == null:
		failures.append("%s should exist" % node_name)
		return
	if button.icon == null:
		failures.append("%s should have an icon texture" % node_name)
	if str(button.get_meta("icon_sprite_name", "")) != sprite_name:
		failures.append("%s should store icon sprite %s" % [node_name, sprite_name])
