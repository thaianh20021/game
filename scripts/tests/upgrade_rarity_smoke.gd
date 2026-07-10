extends SceneTree

const UpgradeDBScript := preload("res://scripts/progression/upgrade_db.gd")

func _init() -> void:
	var failures: Array[String] = []

	await _check_upgrade_rarity_metadata(failures)
	await _check_upgrade_tags_and_overlay_readability(failures)
	await _check_room_tier_reward_rarity(failures)
	await _check_build_tag_synergy_roll(failures)
	await _check_available_reward_roll_filters_blocked(failures)
	await _check_overlay_rarity_treatment(failures)

	if failures.is_empty():
		print("Upgrade rarity smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_upgrade_rarity_metadata(failures: Array[String]) -> void:
	for upgrade in UpgradeDBScript.UPGRADES:
		var rarity := str(upgrade.get("rarity", ""))
		if not UpgradeDBScript.RARITIES.has(rarity):
			failures.append("%s should have a valid rarity" % str(upgrade.get("id", "?")))
	var choices := UpgradeDBScript.roll_choices(123, 5, 2)
	for choice in choices:
		if not choice.has("rarity"):
			failures.append("rolled upgrade should include rarity")

func _check_upgrade_tags_and_overlay_readability(failures: Array[String]) -> void:
	var upgrade_db := UpgradeDBScript.new()
	if not upgrade_db.has_method("tag_summary"):
		failures.append("UpgradeDB should expose tag_summary for build-readable rewards")
	for upgrade in UpgradeDBScript.UPGRADES:
		var tags: Array = upgrade.get("tags", [])
		if tags.is_empty():
			failures.append("%s should define build tags" % str(upgrade.get("id", "?")))
	if upgrade_db.has_method("tag_summary"):
		var summary := str(upgrade_db.call("tag_summary", {"tags": ["damage", "fire", "element"]}))
		if not summary.contains("Damage") or not summary.contains("Fire"):
			failures.append("tag_summary should title-case build tags")

	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.show_upgrade_choices([
		{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage", "rarity": "rare", "tags": ["damage", "fire", "element"]},
		{"id": "split_socket", "name": "Split Socket", "desc": "+1 projectile", "rarity": "epic", "tags": ["projectile", "socket"]},
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP", "rarity": "common", "tags": ["survival", "hp"]},
	], {"ember_rune": 1})
	await process_frame
	var ember := overlay.find_child("Upgrade_ember_rune", true, false) as Button
	if ember == null:
		failures.append("tag overlay should create named ember upgrade button")
	else:
		var tags: Array = ember.get_meta("tags", [])
		if not tags.has("fire"):
			failures.append("upgrade button should store build tags metadata")
		if not str(ember.text).contains("Fire") or not str(ember.text).contains("Damage"):
			failures.append("upgrade button should show readable build tags")

	overlay.callv("show_upgrade_choices", [[
		{"id": "ember_rune", "name": "Ember Rune", "desc": "+15% fire damage", "rarity": "rare", "tags": ["damage", "fire", "element"]},
		{"id": "vital_core", "name": "Vital Core", "desc": "+20 Max HP", "rarity": "common", "tags": ["survival", "hp"]},
		{"id": "lucky_coin", "name": "Lucky Coin", "desc": "+15 gold", "rarity": "common", "tags": ["economy", "gold"]},
	], {}, false, ["fire", "damage"]])
	await process_frame
	ember = overlay.find_child("Upgrade_ember_rune", true, false) as Button
	if ember == null:
		failures.append("build match overlay should keep named ember upgrade button")
	else:
		if not bool(ember.get_meta("build_match", false)):
			failures.append("upgrade button should store build match metadata")
		if not str(ember.text).contains("Synergy"):
			failures.append("upgrade button should show readable build synergy")
	overlay.queue_free()
	await process_frame

func _check_room_tier_reward_rarity(failures: Array[String]) -> void:
	var upgrade_db := UpgradeDBScript.new()
	if not upgrade_db.has_method("roll_room_choices"):
		failures.append("UpgradeDB should expose roll_room_choices for room-tier rewards")
		return
	if not bool(upgrade_db.call("_guarantees_rare_plus", RoomNode.RoomType.BOSS)):
		failures.append("boss reward should guarantee rare+ upgrade tier")
	for room_type in [
		RoomNode.RoomType.ELITE,
		RoomNode.RoomType.MINIBOSS,
		RoomNode.RoomType.BOSS,
		RoomNode.RoomType.TREASURE,
		RoomNode.RoomType.EVENT,
	]:
		var choices: Array = upgrade_db.call("roll_room_choices", 9001, int(room_type) + 17, 2, room_type)
		if choices.size() != 3:
			failures.append("room-tier reward should still offer three choices")
		if not _has_rare_plus(choices):
			failures.append("%s reward should include at least one rare+ upgrade" % RoomNode.RoomType.keys()[room_type])
		if _unique_ids(choices).size() != choices.size():
			failures.append("room-tier reward choices should stay unique")

func _check_build_tag_synergy_roll(failures: Array[String]) -> void:
	var upgrade_db := UpgradeDBScript.new()
	if not upgrade_db.has_method("roll_synergy_room_choices"):
		failures.append("UpgradeDB should expose roll_synergy_room_choices for build-aware rewards")
		return
	var choices: Array = upgrade_db.call(
		"roll_synergy_room_choices",
		111,
		7,
		2,
		RoomNode.RoomType.COMBAT,
		["fire", "damage"])
	if choices.size() != 3:
		failures.append("synergy reward should still offer three choices")
	if _unique_ids(choices).size() != choices.size():
		failures.append("synergy reward choices should stay unique")
	if not _has_tag_overlap(choices, ["fire", "damage"]):
		failures.append("synergy reward should include at least one build-tag match")

	var elite_choices: Array = upgrade_db.call(
		"roll_synergy_room_choices",
		112,
		8,
		2,
		RoomNode.RoomType.ELITE,
		["mobility", "dash"])
	if elite_choices.size() != 3:
		failures.append("elite synergy reward should still offer three choices")
	if not _has_rare_plus(elite_choices):
		failures.append("elite synergy reward should keep rare+ guarantee")
	if not _has_tag_overlap(elite_choices, ["mobility", "dash"]):
		failures.append("elite synergy reward should include a build-tag match")

	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	UpgradeDBScript.apply_upgrade(player, "ember_rune")
	if not player.has_method("upgrade_build_tags"):
		failures.append("Player should expose upgrade_build_tags for build-aware rewards")
	else:
		var tags: Array = player.call("upgrade_build_tags")
		if not tags.has("fire") or not tags.has("damage"):
			failures.append("applied upgrades should record build tags")
	if not player.has_method("upgrade_tag_summary"):
		failures.append("Player should expose upgrade_tag_summary for readable build direction")
	else:
		var summary := str(player.call("upgrade_tag_summary"))
		if not summary.contains("Fire") or not summary.contains("Damage"):
			failures.append("upgrade_tag_summary should show readable build tags")
	if not player.has_method("build_archetype_summary"):
		failures.append("Player should expose build_archetype_summary for readable build identity")
	else:
		var archetype := str(player.call("build_archetype_summary"))
		if archetype != "Fire Damage":
			failures.append("fire damage runes should identify the build as Fire Damage")
	player.queue_free()
	await process_frame

func _check_available_reward_roll_filters_blocked(failures: Array[String]) -> void:
	var upgrade_db := UpgradeDBScript.new()
	if not upgrade_db.has_method("roll_available_synergy_room_choices"):
		failures.append("UpgradeDB should expose roll_available_synergy_room_choices for reward anti-waste rolls")
		return
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	for _i in 3:
		UpgradeDBScript.apply_upgrade(player, "power_rune")
	for _i in 4:
		UpgradeDBScript.apply_upgrade(player, "ember_rune")
	var blocked_ids := {"power_rune": true, "ember_rune": true}
	for seed in range(1, 33):
		var choices: Array = upgrade_db.call(
			"roll_available_synergy_room_choices",
			seed,
			19,
			2,
			RoomNode.RoomType.ELITE,
			player.upgrade_build_tags(),
			player)
		if choices.size() != 3:
			failures.append("available reward roll should still offer three choices")
			continue
		if _unique_ids(choices).size() != choices.size():
			failures.append("available reward choices should stay unique")
		if not _has_rare_plus(choices):
			failures.append("available elite reward should keep rare+ guarantee")
		if not _has_tag_overlap(choices, player.upgrade_build_tags()):
			failures.append("available reward should keep build-tag synergy when possible")
		for choice in choices:
			var id := str(choice.get("id", ""))
			if blocked_ids.has(id):
				failures.append("available reward roll should skip maxed upgrade: %s" % id)
			var reason := UpgradeDBScript.upgrade_block_reason(player, id)
			if reason != "":
				failures.append("available reward roll should skip blocked %s: %s" % [id, reason])
	player.queue_free()
	await process_frame

func _check_overlay_rarity_treatment(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.show_upgrade_choices([
		{"id": "a", "name": "A", "desc": "common", "rarity": "common"},
		{"id": "b", "name": "B", "desc": "rare", "rarity": "rare"},
		{"id": "c", "name": "C", "desc": "epic", "rarity": "epic"},
	])
	await process_frame
	var rare_button := overlay.find_child("Upgrade_b", true, false) as Button
	var epic_button := overlay.find_child("Upgrade_c", true, false) as Button
	if rare_button == null or epic_button == null:
		failures.append("rarity overlay should create named upgrade buttons")
	else:
		if str(rare_button.get_meta("rarity", "")) != "rare":
			failures.append("upgrade button should store rarity metadata")
		if rare_button.modulate == Color.WHITE:
			failures.append("rare upgrade button should be color tinted")
		if epic_button.text.find("[EPIC]") == -1:
			failures.append("epic upgrade button should show rarity label")
	overlay.queue_free()
	await process_frame

func _has_rare_plus(choices: Array) -> bool:
	for choice in choices:
		if ["rare", "epic"].has(str(choice.get("rarity", ""))):
			return true
	return false

func _unique_ids(choices: Array) -> Dictionary:
	var ids := {}
	for choice in choices:
		ids[str(choice.get("id", ""))] = true
	return ids

func _has_tag_overlap(choices: Array, tags: Array) -> bool:
	for choice in choices:
		for raw_tag in choice.get("tags", []):
			if tags.has(str(raw_tag)):
				return true
	return false
