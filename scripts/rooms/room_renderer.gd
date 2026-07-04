class_name RoomRenderer
extends Node2D
## Debug renderer for a stamped room: draws tiles as colored rects, builds
## wall/pillar/pit collisions, and runs the wave spawn flow from a spawn plan.
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
	TileGrid.Tile.DOOR: Color(0.55, 0.45, 0.20),
}

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

var _plan: Array[Dictionary] = []
var _enemy_scene: PackedScene
var _player: Node2D
var _alive := 0
var _current_wave := 0


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


func _draw() -> void:
	if grid == null:
		return
	for y in grid.height:
		for x in grid.width:
			var rect := Rect2(x * TILE, y * TILE, TILE, TILE)
			draw_rect(rect, TILE_COLORS[grid.get_tile(x, y)])


func _build_collisions() -> void:
	for y in grid.height:
		for x in grid.width:
			if not TileGrid.blocking(grid.get_tile(x, y)):
				continue
			var body := StaticBody2D.new()
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(TILE, TILE)
			shape.shape = rect
			body.add_child(shape)
			body.position = tile_to_world(Vector2i(x, y))
			add_child(body)


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
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)


func _on_enemy_died() -> void:
	_alive -= 1
	if _alive <= 0:
		_advance()


func _advance() -> void:
	if _current_wave == 1 and _has_wave(2):
		_spawn_wave(2)
	else:
		print("Room cleared!")
		room_cleared.emit()


func _has_wave(wave: int) -> bool:
	for entry in _plan:
		if int(entry["wave"]) == wave:
			return true
	return false
