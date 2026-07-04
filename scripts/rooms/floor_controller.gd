class_name FloorController
extends Node2D
## Runs one dungeon floor end to end: enters rooms from the graph, rolls
## spawn plans, handles locked-door transitions, remembers cleared rooms
## and announces floor completion when the boss room is cleared.
##
## Determinism: each room re-stamps from SeededRNG(seed, 1000 + room.id),
## so revisiting an uncleared room reproduces the exact same layout + spawns.

## Emitted on room enter and on room clear; the HUD/minimap redraw on it.
signal state_changed

## Emitted when the player steps on the exit portal after the boss is dead.
signal floor_completed

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const ENEMY_POOL_PATH := "res://data/enemies_ancient_cave.json"
const ENTER_OFFSET := 24.0  # px the player is placed inside the entry door

var floor_seed: int
var floor_index: int
var difficulty_mult := 1.0

var rooms: Array[RoomNode] = []
var current_room: RoomNode
var cleared_rooms := {}  # room_id -> true
var visited_rooms := {}  # room_id -> true (fog of war for the minimap)

var _player: Player
var _renderer: RoomRenderer
var _grid: TileGrid
var _stamper := RoomStamper.new()
var _spawner := EnemySpawner.new()
var _pool: Dictionary
var _transitioning := false


## Can be called again with the next floor index: resets all per-floor state.
func start(p_seed: int, p_floor_index: int, player: Player) -> void:
	floor_seed = p_seed
	floor_index = p_floor_index
	_player = player
	cleared_rooms.clear()
	visited_rooms.clear()
	current_room = null
	_transitioning = false
	if _renderer != null:
		_renderer.queue_free()
		_renderer = null
	if _pool.is_empty():
		_pool = EnemySpawner.load_pool(ENEMY_POOL_PATH)

	var builder := GraphBuilder.new()
	rooms = builder.build(floor_seed, floor_index)
	var errors := FloorValidator.validate(rooms)
	print("Floor %d (seed %d): %d rooms | validation: %s" % [
		floor_index, floor_seed, rooms.size(), "OK" if errors.is_empty() else str(errors),
	])
	_enter_room(_entrance(), -1)


func _entrance() -> RoomNode:
	for r in rooms:
		if r.type == RoomNode.RoomType.ENTRANCE:
			return r
	return rooms[0]


## Door transition check: once the room is cleared, standing on a door tile
## moves the player to the room on the other side of that door.
func _physics_process(_delta: float) -> void:
	if _renderer == null or _grid == null or _transitioning:
		return
	if not _renderer.is_cleared:
		return
	var tile := _renderer.world_to_tile(_player.global_position)
	if not _grid.in_bounds(tile.x, tile.y):
		return
	if _grid.get_tile(tile.x, tile.y) != TileGrid.Tile.DOOR:
		return
	var dir := RoomStamper.dir_of_door_tile(_grid, tile)
	if current_room.door_map.has(dir):
		_transitioning = true
		# Deferred: never free the renderer mid-physics-step.
		_enter_room.call_deferred(rooms[current_room.door_map[dir]], current_room.id)


func _enter_room(room: RoomNode, from_room_id: int) -> void:
	if _renderer != null:
		_renderer.queue_free()
	current_room = room

	var rng := SeededRNG.new(floor_seed, 1000 + room.id)
	var door_dirs: Array[int] = []
	for d in room.door_map.keys():
		door_dirs.append(d)
	door_dirs.sort()  # stable carving order regardless of dict iteration
	_grid = _stamper.stamp(room, rng, door_dirs)

	# Which door leads back to the room we came from?
	var entry_dir := -1
	for d in room.door_map.keys():
		if room.door_map[d] == from_room_id:
			entry_dir = d
	var center_tile := Vector2i(_grid.width / 2, _grid.height / 2)
	var entry_tile := center_tile
	if entry_dir != -1:
		var tiles := RoomStamper.door_tiles(_grid, entry_dir)
		if not tiles.is_empty():
			entry_tile = tiles[0]

	var plan: Array[Dictionary] = []
	if not cleared_rooms.has(room.id):
		plan = _spawner.roll_spawn_plan(
			room, _grid, rng, floor_index, difficulty_mult, _pool, entry_tile)

	_renderer = RoomRenderer.new()
	add_child(_renderer)
	move_child(_renderer, 0)
	# Connect BEFORE setup: empty-plan rooms emit room_cleared during setup.
	_renderer.room_cleared.connect(_on_room_cleared.bind(room))
	_renderer.setup(_grid, plan, ENEMY_SCENE, _player)
	_player.configure_camera_for_room(Rect2(
		Vector2.ZERO,
		Vector2(_grid.width, _grid.height) * RoomRenderer.TILE
	))

	var center := _renderer.tile_to_world(center_tile)
	if entry_dir != -1:
		var door_pos := _renderer.tile_to_world(entry_tile)
		_player.global_position = door_pos + door_pos.direction_to(center) * ENTER_OFFSET
	else:
		_player.global_position = center

	# Re-entering an already-cleared boss room: the portal must still be there.
	if room.type == RoomNode.RoomType.BOSS and cleared_rooms.has(room.id):
		_spawn_exit_portal()

	_transitioning = false
	visited_rooms[room.id] = true
	state_changed.emit()
	print("Entered room %02d (%s) | doors: %s" % [room.id, room.type_name(), room.door_map])


func _on_room_cleared(room: RoomNode) -> void:
	cleared_rooms[room.id] = true
	state_changed.emit()
	if room.type == RoomNode.RoomType.BOSS:
		print("Boss down! Exit portal opened (%d/%d rooms visited)" % [
			cleared_rooms.size(), rooms.size(),
		])
		_spawn_exit_portal()


func _spawn_exit_portal() -> void:
	var portal := ExitPortal.new()
	portal.configure(_player)
	portal.position = _renderer.tile_to_world(Vector2i(_grid.width / 2, _grid.height / 2))
	portal.entered.connect(func() -> void: floor_completed.emit())
	_renderer.add_child(portal)
