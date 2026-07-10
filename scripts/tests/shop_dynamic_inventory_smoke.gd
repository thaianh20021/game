extends SceneTree

class DummyPlayer:
	extends Node2D
	signal gold_changed(total: int)
	signal weapon_changed(display_name: String)

	var gold := 200
	var picked_weapons: Array[String] = []

	func pickup_weapon(id: String) -> void:
		picked_weapons.append(id)
		weapon_changed.emit(id)

func _init() -> void:
	var failures: Array[String] = []

	await _check_generated_shop_uses_weapon_pool(failures)

	if failures.is_empty():
		print("Shop dynamic inventory smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_generated_shop_uses_weapon_pool(failures: Array[String]) -> void:
	var parent := Node2D.new()
	var dummy := DummyPlayer.new()
	var shop := RoomInteractable.new()
	root.add_child(parent)
	parent.add_child(dummy)
	parent.add_child(shop)
	shop.configure("shop", dummy, {"min_weapon_rarity": "rare"})
	await process_frame
	var choices := shop.get_shop_choices()
	if choices.size() != 3:
		failures.append("generated shop should still offer three choices")
	var weapon_count := 0
	var rare_plus_count := 0
	for choice in choices:
		var reward: Dictionary = choice.get("reward", {})
		if str(reward.get("type", "")) == "weapon":
			weapon_count += 1
			var rarity := str(choice.get("rarity", "common"))
			if _rarity_rank(rarity) >= _rarity_rank("rare"):
				rare_plus_count += 1
			if str(choice.get("name", "")) == "":
				failures.append("generated weapon choice should inherit a name")
	if weapon_count < 2:
		failures.append("generated shop should offer at least two weapons")
	if rare_plus_count < 2:
		failures.append("generated shop should honor min_weapon_rarity")
	parent.queue_free()
	await process_frame

func _rarity_rank(rarity: String) -> int:
	return ["common", "uncommon", "rare", "epic", "legendary", "mythic"].find(rarity)
