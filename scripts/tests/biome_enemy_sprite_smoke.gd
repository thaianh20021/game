extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

const BIOME_POOLS := [
	{
		"id": "ancient_cave",
		"name": "Ancient Cave",
		"pool": "res://data/enemies_ancient_cave.json",
		"boss_variant": "cave_golem",
	},
	{
		"id": "fungal_depths",
		"name": "Fungal Depths",
		"pool": "res://data/enemies_fungal_depths.json",
		"boss_variant": "spore_golem",
	},
	{
		"id": "ember_forge",
		"name": "Ember Forge",
		"pool": "res://data/enemies_ember_forge.json",
		"boss_variant": "forge_golem",
	},
	{
		"id": "crystal_archive",
		"name": "Crystal Archive",
		"pool": "res://data/enemies_crystal_archive.json",
		"boss_variant": "archive_golem",
	},
]

class DummyTarget:
	extends Node2D

	func take_damage(_amount: int, _from: Vector2 = Vector2.ZERO) -> void:
		pass

func _init() -> void:
	var failures: Array[String] = []
	for biome in BIOME_POOLS:
		await _check_biome_enemy_sprites(biome, failures)
	if failures.is_empty():
		print("Biome enemy sprite smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_biome_enemy_sprites(biome: Dictionary, failures: Array[String]) -> void:
	var pool := EnemySpawner.load_pool(str(biome["pool"]))
	var enemies: Array = pool.get("enemies", [])
	var scene := Node2D.new()
	var renderer := RoomRenderer.new()
	var target := DummyTarget.new()
	root.add_child(scene)
	scene.add_child(target)
	scene.add_child(renderer)
	var plan: Array[Dictionary] = []
	for i in enemies.size():
		var data: Dictionary = enemies[i]
		plan.append({
			"enemy": data.duplicate(true),
			"wave": 1,
			"tile": Vector2i(2 + i % 10, 2 + i / 10),
			"elite": false,
			"modifier": "",
		})
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, target, RoomNode.RoomType.COMBAT, {}, biome)
	await process_frame
	for enemy_data in enemies:
		var enemy_id := str((enemy_data as Dictionary).get("id", ""))
		var enemy := _first_enemy_id(renderer, enemy_id)
		if enemy == null:
			failures.append("%s/%s should spawn for sprite coverage" % [str(biome["id"]), enemy_id])
			continue
		var sprite := enemy.get_node_or_null("Sprite") as AnimatedSprite2D
		var body := enemy.get_node_or_null("Body") as Polygon2D
		if sprite == null or not sprite.visible or sprite.sprite_frames == null:
			failures.append("%s/%s should use a visible DungeonTileset sprite" % [str(biome["id"]), enemy_id])
		if body != null and body.visible:
			failures.append("%s/%s should hide fallback body after sprite setup" % [str(biome["id"]), enemy_id])
	scene.queue_free()
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

func _first_enemy_id(parent: Node, enemy_id: String) -> Enemy:
	for child in parent.get_children():
		if child is Enemy and str(child.get_meta("enemy_id", "")) == enemy_id:
			return child
	return null
