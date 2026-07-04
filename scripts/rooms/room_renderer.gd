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
const FLOOR_SPRITES := [
	"floor_1", "floor_2", "floor_3", "floor_4",
	"floor_5", "floor_6", "floor_7", "floor_8",
]
const ENEMY_SPRITES := {
	"stone_rat": {"idle": ["imp_idle_anim"], "run": ["imp_run_anim"]},
	"crystal_bat": {"idle": ["swampy_anim", "imp_idle_anim"], "run": ["swampy_anim", "imp_run_anim"]},
	"web_spider": {"idle": ["spider_idle_anim", "skelet_idle_anim"], "run": ["spider_run_anim", "skelet_run_anim"]},
	"rubble_golem": {"idle": ["ogre_idle_anim", "orc_warrior_idle_anim"], "run": ["ogre_run_anim", "orc_warrior_run_anim"]},
	"cave_slime": {"idle": ["slug_anim", "tiny_zombie_idle_anim"], "run": ["slug_anim", "tiny_zombie_run_anim"]},
	"glow_beetle": {"idle": ["necromancer_anim", "imp_idle_anim"], "run": ["necromancer_anim", "imp_run_anim"]},
	"quartz_shaman": {"idle": ["wogol_idle_anim", "ice_zombie_anim"], "run": ["wogol_run_anim", "ice_zombie_anim"]},
	"cave_crab": {"idle": ["orc_shaman_idle_anim", "masked_orc_idle_anim"], "run": ["orc_shaman_run_anim", "masked_orc_run_anim"]},
	"stalactite_wisp": {"idle": ["wraith_idle_anim", "skelet_idle_anim"], "run": ["wraith_run_anim", "skelet_run_anim"]},
	"beast_herder": {"idle": ["orc_warlord_idle_anim", "big_zombie_idle_anim"], "run": ["orc_warlord_run_anim", "big_zombie_run_anim"]},
	"cave_golem_boss": {"idle": ["big_demon_idle_anim"], "run": ["big_demon_run_anim"]},
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
	"boss": 40.0,
}

var grid: TileGrid
var is_cleared := false

var _plan: Array[Dictionary] = []
var _enemy_scene: PackedScene
var _player: Node2D
var _alive := 0
var _current_wave := 0
var _door_bodies: Array[StaticBody2D] = []
var _door_markers: Array[Node2D] = []


func setup(p_grid: TileGrid, plan: Array[Dictionary], enemy_scene: PackedScene, player: Node2D) -> void:
	clear_door_markers()
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


func clear_door_markers() -> void:
	for marker in _door_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_door_markers.clear()


func show_door_markers(door_targets: Dictionary) -> void:
	clear_door_markers()
	if grid == null:
		return
	for dir in door_targets.keys():
		var tiles := RoomStamper.door_tiles(grid, int(dir))
		if tiles.is_empty():
			continue
		var marker := DoorMarker.new()
		marker.configure(int(door_targets[dir]))
		marker.position = _door_marker_position(int(dir), tiles)
		add_child(marker)
		marker.add_to_group("door_markers")
		_door_markers.append(marker)


func _draw() -> void:
	if grid == null:
		return
	for y in grid.height:
		for x in grid.width:
			var t := grid.get_tile(x, y)
			var rect := Rect2(x * TILE, y * TILE, TILE, TILE)
			if _draw_tile_texture(t, x, y, rect):
				continue
			var color: Color
			if t == TileGrid.Tile.DOOR:
				color = DOOR_OPEN_COLOR if is_cleared else DOOR_LOCKED_COLOR
			else:
				color = TILE_COLORS[t]
			draw_rect(rect, color)

func _draw_tile_texture(tile: int, x: int, y: int, rect: Rect2) -> bool:
	var sprite_name := ""
	var tint := Color.WHITE
	match tile:
		TileGrid.Tile.FLOOR:
			sprite_name = FLOOR_SPRITES[_floor_variant(x, y)]
		TileGrid.Tile.WALL:
			sprite_name = wall_sprite_name_for_tile(grid, x, y)
		TileGrid.Tile.PILLAR:
			sprite_name = SpriteDB.first_existing(["column", "column_wall", "wall_mid"])
		TileGrid.Tile.DOOR:
			sprite_name = "doors_leaf_open" if is_cleared else "doors_leaf_closed"
		TileGrid.Tile.GRASS:
			sprite_name = "floor_1"
			tint = Color(0.55, 0.95, 0.55)
		TileGrid.Tile.WATER:
			sprite_name = "floor_1"
			tint = Color(0.45, 0.65, 1.0)
		TileGrid.Tile.PIT:
			sprite_name = SpriteDB.first_existing(["hole", "edge_down"])
	if sprite_name == "":
		return false
	var tex := SpriteDB.texture(sprite_name)
	if tex == null:
		return false
	draw_texture_rect(tex, rect, false, tint)
	return true


func wall_sprite_name_for_tile(p_grid: TileGrid, x: int, y: int) -> String:
	if p_grid == null:
		return "wall_mid"
	var below_is_floor := y + 1 < p_grid.height and p_grid.get_tile(x, y + 1) == TileGrid.Tile.FLOOR
	if below_is_floor and SpriteDB.has_sprite("wall_top_mid"):
		return "wall_top_mid"
	if SpriteDB.has_sprite("wall_mid"):
		return "wall_mid"
	return SpriteDB.first_existing(["wall_top_mid", "wall_side_mid_left", "wall_side_mid_right"])


func _door_marker_position(dir: int, tiles: Array[Vector2i]) -> Vector2:
	var pos := Vector2.ZERO
	for tile in tiles:
		pos += tile_to_world(tile)
	pos /= maxf(float(tiles.size()), 1.0)
	match dir:
		RoomStamper.Dir.NORTH:
			return pos + Vector2(0, TILE)
		RoomStamper.Dir.SOUTH:
			return pos + Vector2(0, -TILE)
		RoomStamper.Dir.WEST:
			return pos + Vector2(TILE, 0)
		RoomStamper.Dir.EAST:
			return pos + Vector2(-TILE, 0)
	return pos


func _floor_variant(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % FLOOR_SPRITES.size()


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
	var data: Dictionary = entry["enemy"]
	var kind := str(data["kind"])
	var enemy: Enemy
	if kind == "boss":
		enemy = _make_boss()
	else:
		enemy = _enemy_scene.instantiate()
	enemy.kind = kind
	enemy.max_hp = int(data["hp"])
	enemy.contact_damage = int(data["dmg"])
	enemy.speed = SPEED_BY_KIND.get(kind, 55.0)
	if bool(entry["elite"]):
		enemy.max_hp *= 3
		enemy.scale = Vector2(1.4, 1.4)
		enemy.base_tint = Color(1.0, 0.85, 0.4)  # elite tint until real VFX
	enemy.target = _player
	enemy.position = tile_to_world(entry["tile"])
	enemy.z_index = 2
	enemy.died.connect(_on_enemy_died.bind(entry))
	add_child(enemy)
	_apply_enemy_sprite(enemy, str(data.get("id", "")))


## Bosses have no scene yet: build the node tree in code.
func _make_boss() -> Enemy:
	var boss := BossGolem.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 20)
	shape.shape = rect
	boss.add_child(shape)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-11, -11), Vector2(11, -11), Vector2(11, 11), Vector2(-11, 11),
	])
	body.color = Color(0.55, 0.5, 0.45)
	boss.add_child(body)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.visible = false
	boss.add_child(sprite)
	boss.sight_range = 400.0
	boss.contact_range = 16.0
	return boss

func _apply_enemy_sprite(enemy: Enemy, enemy_id: String) -> void:
	var mapping: Dictionary = ENEMY_SPRITES.get(enemy_id, {})
	if mapping.is_empty():
		return
	var idle_name := SpriteDB.first_existing(mapping["idle"])
	var run_name := SpriteDB.first_existing(mapping["run"])
	if idle_name == "":
		return
	enemy.configure_visual(idle_name, run_name)


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
