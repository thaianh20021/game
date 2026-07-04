extends Node2D
## Demo entry point: generates a floor, stamps its first combat room, spawns
## enemy waves from the budget system and lets the player clear the room.
## Next milestone: room transitions through doors + full floor flow.

const DEMO_SEED := 20260704
const FLOOR_INDEX := 1
const DIFFICULTY_MULT := 1.0
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

@onready var player: Player = $Player


func _ready() -> void:
	# 1. Floor graph.
	var builder := GraphBuilder.new()
	var rooms := builder.build(DEMO_SEED, FLOOR_INDEX)
	var errors := FloorValidator.validate(rooms)
	print("=== Dungeon Core demo (seed %d) ===" % DEMO_SEED)
	print("Floor: %d rooms | validation: %s" % [rooms.size(), "OK" if errors.is_empty() else str(errors)])

	# 2. Stamp the first critical-path combat room.
	var room := _first_combat_room(rooms)
	var rng := SeededRNG.new(DEMO_SEED, 1000 + room.id)
	var stamper := RoomStamper.new()
	var door_dirs := stamper.pick_door_dirs(room, rng)
	var grid := stamper.stamp(room, rng, door_dirs)

	# 3. Roll the spawn plan.
	var pool := EnemySpawner.load_pool("res://data/enemies_ancient_cave.json")
	var doors := grid.door_positions()
	var entry: Vector2i = doors[0]
	var spawner := EnemySpawner.new()
	var plan := spawner.roll_spawn_plan(room, grid, rng, FLOOR_INDEX, DIFFICULTY_MULT, pool, entry)

	# 4. Render + play.
	var renderer := RoomRenderer.new()
	add_child(renderer)
	move_child(renderer, 0)
	renderer.setup(grid, plan, ENEMY_SCENE, player)
	renderer.room_cleared.connect(func() -> void:
		print("Demo complete - next milestone: door transitions."))

	# Place the player just inside the entry door.
	var center := renderer.tile_to_world(Vector2i(grid.width / 2, grid.height / 2))
	var door_pos := renderer.tile_to_world(entry)
	player.position = door_pos + (center - door_pos).normalized() * 24.0

	print("Room %02d (%s): %dx%d tiles, %d doors, %d enemies planned" % [
		room.id, room.type_name(), grid.width, grid.height, doors.size(), plan.size(),
	])


func _first_combat_room(rooms: Array[RoomNode]) -> RoomNode:
	for r in rooms:
		if r.type == RoomNode.RoomType.COMBAT and r.on_critical_path:
			return r
	return rooms[0]
