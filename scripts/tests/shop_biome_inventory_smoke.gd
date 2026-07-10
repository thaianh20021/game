extends SceneTree

class DummyPlayer:
	extends Node2D
	signal gold_changed(total: int)

	var gold := 200

func _init() -> void:
	var failures: Array[String] = []

	await _check_shop_uses_biome_rarity_context(failures)

	if failures.is_empty():
		print("Shop biome inventory smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_shop_uses_biome_rarity_context(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(renderer)
	root.add_child(dummy)
	renderer.setup(_basic_grid(), [], null, dummy, RoomNode.RoomType.SHOP, {}, {
		"id": "ember_forge",
		"name": "Ember Forge",
		"shop_min_rarity": "rare",
	})
	await process_frame

	var shop := _first_interactable(renderer)
	if shop == null:
		failures.append("shop room should spawn a shop interactable")
	else:
		var choices := shop.get_shop_choices()
		var weapon_count := 0
		var rare_plus_count := 0
		for choice in choices:
			var reward: Dictionary = choice.get("reward", {})
			if str(reward.get("type", "")) == "weapon":
				weapon_count += 1
				if _rarity_rank(str(choice.get("rarity", "common"))) >= _rarity_rank("rare"):
					rare_plus_count += 1
		if weapon_count < 2:
			failures.append("biome shop should generate at least two weapon choices")
		if rare_plus_count < 2:
			failures.append("biome shop should honor shop_min_rarity")
	renderer.queue_free()
	dummy.queue_free()
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

func _rarity_rank(rarity: String) -> int:
	return ["common", "uncommon", "rare", "epic", "legendary", "mythic"].find(rarity)
