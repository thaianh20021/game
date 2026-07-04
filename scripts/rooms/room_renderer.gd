class_name RoomRenderer
extends Node2D
## Debug renderer for a stamped room: draws tiles as colored rects, builds
## wall/pillar/pit collisions, locks doors (collision + red tint) until the
## room is cleared, and runs the wave spawn flow from a spawn plan.
## Will be replaced by a real TileMapLayer + biome tileset once art exists.

signal room_cleared

const TILE := 16

const TILE_COLORS := {
	TileGrid.Tile.FLOOR: Color(0.16, 0.14, 0.13),
	TileGrid.Tile.WALL: Color(0.36, 0.31, 0.28),
	TileGrid.Tile.PIT: Color(0.04, 0.04, 0.06),
	TileGrid.Tile.WATER: Color(0.15, 0.30, 0.45),
	TileGrid.Tile.GRASS: Color(0.18, 0.28, 0.16),
	TileGrid.Tile.PILLAR: Color(0.47, 0.42, 0.37),
}
const DOOR_OPEN_COLOR := Color(0.55, 0.45, 0.20)
const DOOR_LOCKED_COLOR := Color(0.45, 0.15, 0.12)

# Placeholder movement speeds per enemy kind (px/s) until real AIs land.
const SPEED_BY_KIND := {
	"melee_charger": 75.0,
	"flyer": 65.0,
	"ranged": 45.0,
	"caster": 45.0,
	"tanker": 35.0,
	"melee": 55.0,
	"exploder": 60.0,
	"armored_melee": 45.0,
	"ambusher": 70.0,
	"miniboss": 50.0,
}

var grid: TileGrid
var is_cleared := false

var _plan: Array[Dictionary] = []
var _enemy_scene: PackedScene
var _player: Node2D
var _alive := 0
var _current_wave := 0
var _door_bodies: Array[StaticBody2D] = []


func setup(p_grid: TileGrid, plan: Array[Dictionary], enemy_scene: PackedScene, player: Node2D) -> void:
	grid = p_grid
	_plan = plan
	_enemy_scene = enemy_scene
	_player = player
	z_index = -1
	_build_collisions()
	queue_redraw()
	_spawn_wave(1)


func tile_to_world(t: Vector2i) -> Vector2:
	return Vector2(t.x + 0.5, t.y + 0.5) * TILE


func world_to_tile(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))


func _draw() -> void:
	if grid == null:
		return
	for y in grid.height:
		for x in grid.width:
			var t := grid.get_tile(x, y)
			var color: Color
			if t == TileGrid.Tile.DOOR:
				color = DOOR_OPEN_COLOR if is_cleared else DOOR_LOCKED_COLOR
			else:
				color = TILE_COLORS[t]
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), color)


func _build_collisions() -> void:
	for y in grid.height:
		for x in grid.width:
			var t := grid.get_tile(x, y)
			var locked_door := t == TileGrid.Tile.DOOR
			if not TileGrid.blocking(t) and not locked_door:
				continue
			var body := _make_tile_body(x, y)
			if locked_door:
				_door_bodies.append(body)


func _make_tile_body(x: int, y: int) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	body.add_child(shape)
	body.position = tile_to_world(Vector2i(x, y))
	add_child(body)
	return body


func _spawn_wave(wave: int) -> void:
	_current_wave = wave
	var count := 0
	for entry in _plan:
		if int(entry["wave"]) == wave:
			_spawn_enemy(entry)
			count += 1
	_alive = count
	if count == 0:
		_advance()


func _spawn_enemy(entry: Dictionary) -> void:
	var enemy: Enemy = _enemy_scene.instantiate()
	var data: Dictionary = entry["enemy"]
	enemy.max_hp = int(data["hp"])
	enemy.contact_damage = int(data["dmg"])
	enemy.speed = SPEED_BY_KIND.get(str(data["kind"]), 55.0)
	if bool(entry["elite"]):
		enemy.max_hp *= 3
		enemy.scale = Vector2(1.4, 1.4)
		enemy.modulate = Color(1.0, 0.85, 0.4)  # elite tint until real VFX
	enemy.target = _player
	enemy.position = tile_to_world(entry["tile"])
	enemy.z_index = 2
	enemy.died.connect(_on_enemy_died.bind(entry))
	add_child(enemy)


func _on_enemy_died(enemy: Enemy, entry: Dictionary) -> void:
	_drop_loot(enemy.position, entry)
	_alive -= 1
	if _alive <= 0:
		_advance()


func _drop_loot(at: Vector2, entry: Dictionary) -> void:
	var drops := LootRoller.roll_drops(entry)
	for i in drops.size():
		var pickup := Pickup.new()
		pickup.configure(drops[i], _player)
		pickup.position = at + Vector2((i - (drops.size() - 1) * 0.5) * 9.0, 5.0)
		pickup.z_index = 1
		add_child(pickup)


func _advance() -> void:
	if _current_wave == 1 and _has_wave(2):
		_spawn_wave(2)
		return
	if is_cleared:
		return
	is_cleared = true
	_unlock_doors()
	queue_redraw()
	if not _plan.is_empty():
		print("Room cleared!")
	room_cleared.emit()


func _unlock_doors() -> void:
	for body in _door_bodies:
		body.queue_free()
	_door_bodies.clear()


func _has_wave(wave: int) -> bool:
	for entry in _plan:
		if int(entry["wave"]) == wave:
			return true
	return false
