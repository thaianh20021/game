class_name RoomRenderer
extends Node2D
## Debug renderer for a stamped room: draws tiles as colored rects, builds
## wall/pillar/pit collisions, locks doors (collision + red tint) until the
## room is cleared, and runs the wave spawn flow from a spawn plan.
## Will be replaced by a real TileMapLayer + biome tileset once art exists.

signal room_cleared
signal shop_choice_requested(shop: RoomInteractable, choices: Array)
signal loot_pity_changed(rooms_without_rare_plus: int)
signal boss_phase_changed(status: Dictionary)
signal boss_attack_cued(status: Dictionary)
signal route_choice_requested(choice_index: int)
signal objective_context_changed(context: Dictionary)
signal interactable_completed(kind: String, payload: Dictionary)
signal trap_room_survived

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
const TRAP_ROOM_SURVIVE_SECONDS := 4.0
const TRAP_ROOM_URGENT_SECONDS := 1.5
const FLOOR_SPRITES := [
	"floor_1", "floor_2", "floor_3", "floor_4",
	"floor_5", "floor_6", "floor_7", "floor_8",
]
const EVENT_INTERACTABLE_KINDS := ["trap_cache", "blood_altar", "rune_cache", "cursed_chest"]
const EVENT_TRAP_KINDS := ["spike", "fire", "saw", "arrow"]
const TrapScript := preload("res://scripts/rooms/trap.gd")
const BreakablePropScript := preload("res://scripts/rooms/breakable_prop.gd")
const RoomInteractableScript := preload("res://scripts/rooms/room_interactable.gd")
const RoomAffixDBScript := preload("res://scripts/rooms/room_affix_db.gd")
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")
const SoulKingdomUltimateScript := preload("res://scripts/ultimates/soul_kingdom_ultimate.gd")
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
	"sporeling": {"idle": ["tiny_slug_anim", "slug_anim"], "run": ["tiny_slug_anim", "slug_anim"]},
	"gloom_moth": {"idle": ["swampy_anim", "angel_idle_anim"], "run": ["swampy_anim", "angel_run_anim"]},
	"mycelium_archer": {"idle": ["elf_f_idle_anim", "goblin_idle_anim"], "run": ["elf_f_run_anim", "goblin_run_anim"]},
	"puffcap_bomber": {"idle": ["pumpkin_dude_idle_anim", "chort_idle_anim"], "run": ["pumpkin_dude_run_anim", "chort_run_anim"]},
	"mold_shambler": {"idle": ["big_zombie_idle_anim", "ogre_idle_anim"], "run": ["big_zombie_run_anim", "ogre_run_anim"]},
	"bracket_crab": {"idle": ["masked_orc_idle_anim", "orc_warrior_idle_anim"], "run": ["masked_orc_run_anim", "orc_warrior_run_anim"]},
	"spore_oracle": {"idle": ["necromancer_anim", "wizzard_f_idle_anim"], "run": ["necromancer_anim", "wizzard_f_run_anim"]},
	"ceiling_puff": {"idle": ["muddy_anim", "tiny_zombie_idle_anim"], "run": ["muddy_anim", "tiny_zombie_run_anim"]},
	"spore_matriarch": {"idle": ["wogol_idle_anim", "ogre_idle_anim"], "run": ["wogol_run_anim", "ogre_run_anim"]},
	"spore_golem_boss": {"idle": ["ogre_idle_anim", "big_zombie_idle_anim"], "run": ["ogre_run_anim", "big_zombie_run_anim"]},
	"coal_imp": {"idle": ["imp_idle_anim"], "run": ["imp_run_anim"]},
	"cinder_wisp": {"idle": ["chort_idle_anim", "imp_idle_anim"], "run": ["chort_run_anim", "imp_run_anim"]},
	"slag_thrower": {"idle": ["goblin_idle_anim", "elf_m_idle_anim"], "run": ["goblin_run_anim", "elf_m_run_anim"]},
	"blast_keg": {"idle": ["chort_idle_anim", "imp_idle_anim"], "run": ["chort_run_anim", "imp_run_anim"]},
	"anvil_guard": {"idle": ["zerie_orc_idle", "orc_warrior_idle_anim", "ogre_idle_anim"], "run": ["zerie_orc_walk", "orc_warrior_run_anim", "ogre_run_anim"]},
	"forge_crab": {"idle": ["masked_orc_idle_anim", "orc_warrior_idle_anim"], "run": ["masked_orc_run_anim", "orc_warrior_run_anim"]},
	"ember_acolyte": {"idle": ["wizzard_m_idle_anim", "chort_idle_anim"], "run": ["wizzard_m_run_anim", "chort_run_anim"]},
	"chain_hook": {"idle": ["lizard_m_idle_anim", "masked_orc_idle_anim"], "run": ["lizard_m_run_anim", "masked_orc_run_anim"]},
	"forge_captain": {"idle": ["dwarf_m_idle_anim", "knight_m_idle_anim"], "run": ["dwarf_m_run_anim", "knight_m_run_anim"]},
	"forge_golem_boss": {"idle": ["big_demon_idle_anim", "ogre_idle_anim"], "run": ["big_demon_run_anim", "ogre_run_anim"]},
	"archive_mite": {"idle": ["tiny_slug_anim", "tiny_zombie_idle_anim"], "run": ["tiny_slug_anim", "tiny_zombie_run_anim"]},
	"prism_bat": {"idle": ["angel_idle_anim", "swampy_anim"], "run": ["angel_run_anim", "swampy_anim"]},
	"index_lancer": {"idle": ["lizard_m_idle_anim", "knight_m_idle_anim"], "run": ["lizard_m_run_anim", "knight_m_run_anim"]},
	"glyph_archer": {"idle": ["elf_m_idle_anim", "skelet_idle_anim"], "run": ["elf_m_run_anim", "skelet_run_anim"]},
	"mirror_acolyte": {"idle": ["wizzard_m_idle_anim", "necromancer_anim"], "run": ["wizzard_m_run_anim", "necromancer_anim"]},
	"crystal_warden": {"idle": ["ogre_idle_anim", "orc_warrior_idle_anim"], "run": ["ogre_run_anim", "orc_warrior_run_anim"]},
	"glass_bomber": {"idle": ["chort_idle_anim", "imp_idle_anim"], "run": ["chort_run_anim", "imp_run_anim"]},
	"shelf_stalker": {"idle": ["masked_orc_idle_anim", "skelet_idle_anim"], "run": ["masked_orc_run_anim", "skelet_run_anim"]},
	"archive_curator": {"idle": ["doc_idle_anim", "wizzard_f_idle_anim"], "run": ["doc_run_anim", "wizzard_f_run_anim"]},
	"archive_golem_boss": {"idle": ["big_demon_idle_anim", "ogre_idle_anim"], "run": ["big_demon_run_anim", "ogre_run_anim"]},
	"crypt_rat": {"idle": ["tiny_zombie_idle_anim", "tiny_slug_anim"], "run": ["tiny_zombie_run_anim", "tiny_slug_anim"]},
	"shade_bat": {"idle": ["wraith_idle_anim", "swampy_anim"], "run": ["wraith_run_anim", "swampy_anim"]},
	"bone_lancer": {"idle": ["skelet_idle_anim", "lizard_m_idle_anim"], "run": ["skelet_run_anim", "lizard_m_run_anim"]},
	"grave_archer": {"idle": ["goblin_idle_anim", "elf_m_idle_anim"], "run": ["goblin_run_anim", "elf_m_run_anim"]},
	"hex_scribe": {"idle": ["necromancer_anim", "wizzard_f_idle_anim"], "run": ["necromancer_anim", "wizzard_f_run_anim"]},
	"tomb_guard": {"idle": ["orc_warlord_idle_anim", "ogre_idle_anim"], "run": ["orc_warlord_run_anim", "ogre_run_anim"]},
	"soul_bomber": {"idle": ["chort_idle_anim", "pumpkin_dude_idle_anim"], "run": ["chort_run_anim", "pumpkin_dude_run_anim"]},
	"veil_stalker": {"idle": ["masked_orc_idle_anim", "wraith_idle_anim"], "run": ["masked_orc_run_anim", "wraith_run_anim"]},
	"crypt_revenant": {"idle": ["big_zombie_idle_anim", "necromancer_anim"], "run": ["big_zombie_run_anim", "necromancer_anim"]},
	"void_golem_boss": {"idle": ["big_demon_idle_anim", "wogol_idle_anim"], "run": ["big_demon_run_anim", "wogol_run_anim"]},
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
var _room_type: int = RoomNode.RoomType.COMBAT
var _room_affix: Dictionary = {}
var _biome: Dictionary = {}
var _alive := 0
var _current_wave := 0
var _objective_pending := false
var _loot_pity_rooms_without_rare_plus := 0
var _room_dropped_rare_plus := false
var _door_bodies: Array[StaticBody2D] = []
var _door_markers: Array[Node2D] = []
var _trap_room_cache: RoomInteractable = null
var _trap_room_survival_complete := false
var _trap_room_countdown_label: Label = null
var _interactables_claimed := false


func setup(
		p_grid: TileGrid,
		plan: Array[Dictionary],
		enemy_scene: PackedScene,
		player: Node2D,
		room_type: int = RoomNode.RoomType.COMBAT,
		room_affix: Dictionary = {},
		biome: Dictionary = {},
		loot_pity_rooms_without_rare_plus: int = 0,
		room_state: Dictionary = {},
) -> void:
	clear_door_markers()
	grid = p_grid
	_plan = plan
	_enemy_scene = enemy_scene
	_player = player
	_room_type = room_type
	_room_affix = room_affix.duplicate()
	if _room_affix.is_empty():
		_room_affix = RoomAffixDBScript.affix("none")
	set_meta("room_affix", str(_room_affix.get("id", "none")))
	_biome = biome.duplicate(true)
	set_meta("biome", str(_biome.get("id", "ancient_cave")))
	var room_tint: Variant = _biome.get("room_tint", Color.WHITE)
	modulate = room_tint if room_tint is Color else Color.WHITE
	_loot_pity_rooms_without_rare_plus = maxi(loot_pity_rooms_without_rare_plus, 0)
	_room_dropped_rare_plus = false
	_trap_room_cache = null
	_trap_room_survival_complete = bool(room_state.get("trap_room_survived", false))
	set_meta("trap_room_survived", _trap_room_survival_complete)
	_trap_room_countdown_label = null
	_interactables_claimed = bool(room_state.get("interactables_claimed", false))
	_objective_pending = _room_requires_objective() and not _interactables_claimed
	z_index = -1
	_build_collisions()
	_spawn_room_features()
	queue_redraw()
	_spawn_wave(1)


func _process(_delta: float) -> void:
	if _room_type != RoomNode.RoomType.EVENT or _trap_room_survival_complete:
		return
	var timer := get_node_or_null("TrapRoomSurvivalTimer") as Timer
	if timer == null:
		return
	_update_trap_room_survival_countdown(maxf(timer.time_left, 0.0))


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
		var target = door_targets[dir]
		var target_type := RoomNode.RoomType.COMBAT
		var route_hint := ""
		var gate_state := ""
		var next_action_key := ""
		var preview_hint := ""
		var choice_index := 0
		var input_action := ""
		if target is Dictionary:
			target_type = int(target.get("type", RoomNode.RoomType.COMBAT))
			route_hint = str(target.get("route", ""))
			gate_state = str(target.get("state", ""))
			next_action_key = str(target.get("next_action_key", ""))
			preview_hint = str(target.get("preview", ""))
			choice_index = int(target.get("choice_index", 0))
			input_action = str(target.get("input_action", ""))
		else:
			target_type = int(target)
		var marker := DoorMarker.new()
		marker.configure(target_type, route_hint, gate_state, next_action_key, preview_hint,
			choice_index, input_action)
		marker.position = _door_marker_position(int(dir), tiles)
		add_child(marker)
		marker.route_choice_requested.connect(func(choice_index: int) -> void:
			route_choice_requested.emit(choice_index))
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
	var left_is_wall := _tile_is_wall(p_grid, x - 1, y)
	var right_is_wall := _tile_is_wall(p_grid, x + 1, y)
	var below_is_floor := _tile_is_floor(p_grid, x, y + 1)
	if below_is_floor:
		if not left_is_wall and right_is_wall and SpriteDB.has_sprite("wall_top_left"):
			return "wall_top_left"
		if left_is_wall and not right_is_wall and SpriteDB.has_sprite("wall_top_right"):
			return "wall_top_right"
		if SpriteDB.has_sprite("wall_top_mid"):
			return "wall_top_mid"
	if not left_is_wall and right_is_wall and SpriteDB.has_sprite("wall_left"):
		return "wall_left"
	if left_is_wall and not right_is_wall and SpriteDB.has_sprite("wall_right"):
		return "wall_right"
	if SpriteDB.has_sprite("wall_mid"):
		return "wall_mid"
	return SpriteDB.first_existing(["wall_top_mid", "wall_top_left", "wall_top_right"])

func _tile_is_wall(p_grid: TileGrid, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < p_grid.width and y < p_grid.height \
		and p_grid.get_tile(x, y) == TileGrid.Tile.WALL

func _tile_is_floor(p_grid: TileGrid, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < p_grid.width and y < p_grid.height \
		and p_grid.get_tile(x, y) == TileGrid.Tile.FLOOR


func _door_marker_position(dir: int, tiles: Array[Vector2i]) -> Vector2:
	var pos := Vector2.ZERO
	for tile in tiles:
		pos += tile_to_world(tile)
	pos /= maxf(float(tiles.size()), 1.0)
	match dir:
		RoomStamper.Dir.NORTH:
			return pos + Vector2(0, TILE * 2.0)
		RoomStamper.Dir.SOUTH:
			return pos + Vector2(0, -TILE * 2.0)
		RoomStamper.Dir.WEST:
			return pos + Vector2(TILE * 2.0, 0)
		RoomStamper.Dir.EAST:
			return pos + Vector2(-TILE * 2.0, 0)
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


func _spawn_room_features() -> void:
	if _interactables_claimed and _room_requires_objective():
		return
	match _room_type:
		RoomNode.RoomType.TREASURE:
			_spawn_interactable("chest", _room_center_tile())
		RoomNode.RoomType.HEAL:
			_spawn_interactable("shrine", _room_center_tile())
		RoomNode.RoomType.SHRINE:
			_spawn_interactable("element_altar", _room_center_tile())
		RoomNode.RoomType.SHOP:
			_spawn_interactable("shop", _room_center_tile())
		RoomNode.RoomType.EVENT:
			var event_trap_count := 6
			var event_tiles := _trap_tiles(event_trap_count)
			for i in mini(event_trap_count, event_tiles.size()):
				_spawn_trap(EVENT_TRAP_KINDS[i % EVENT_TRAP_KINDS.size()], event_tiles[i])
			_spawn_trap_room_warning(mini(event_trap_count, event_tiles.size()))
			_trap_room_cache = _spawn_interactable(_event_interactable_kind(), _room_center_tile())
			_start_trap_room_survival_gate()
		RoomNode.RoomType.SECRET:
			_spawn_interactable("secret_cache", _room_center_tile())
		RoomNode.RoomType.COMBAT, RoomNode.RoomType.ELITE, RoomNode.RoomType.MINIBOSS, RoomNode.RoomType.BOSS:
			var trap_tiles := _trap_tiles(2)
			for i in mini(2, trap_tiles.size()):
				_spawn_trap("spike" if i == 0 else "fire", trap_tiles[i])
			var tiles := _feature_tiles(5)
			for i in range(2, mini(4, tiles.size())):
				_spawn_prop("crate" if i % 2 == 0 else "vase", tiles[i])
			_spawn_optional_locked_chest()
	_spawn_affix_features()

func _spawn_optional_locked_chest() -> void:
	if _interactables_claimed or not _should_spawn_locked_chest():
		return
	var tiles := _feature_tiles(6)
	var tile := tiles[4] if tiles.size() > 4 else _room_center_tile()
	_spawn_interactable("locked_chest", tile)

func _should_spawn_locked_chest() -> bool:
	if bool(_biome.get("locked_chest", false)):
		return true
	var chance := clampf(float(_biome.get("locked_chest_chance", 0.0)), 0.0, 1.0)
	if chance <= 0.0:
		return false
	if chance >= 1.0:
		return true
	var roll_seed := absi(str(_biome.get("id", "ancient_cave")).hash() ^ (grid.width * 73856093) ^ (grid.height * 19349663) ^ (_room_type * 83492791))
	var roll := float(roll_seed % 10000) / 10000.0
	return roll < chance

func _spawn_affix_features() -> void:
	if str(_room_affix.get("id", "none")) == "none":
		return
	_spawn_affix_label()
	var trap_kind := str(_room_affix.get("trap_kind", ""))
	var extra_traps := int(_room_affix.get("extra_traps", 0))
	if trap_kind == "" or extra_traps <= 0:
		return
	var tiles := _trap_tiles(extra_traps)
	for tile in tiles:
		_spawn_trap(trap_kind, tile)

func _spawn_affix_label() -> void:
	var label := Label.new()
	label.name = "RoomAffixLabel"
	label.text = str(_room_affix.get("name", ""))
	label.position = Vector2(8, 8)
	label.add_theme_font_size_override("font_size", 9)
	label.modulate = Color(1.0, 0.86, 0.45)
	label.add_to_group("room_affix_labels")
	add_child(label)


func _spawn_trap(kind: String, tile: Vector2i) -> void:
	var trap := TrapScript.new()
	trap.configure(kind, 6, 0.7, 0.18)
	trap.position = tile_to_world(tile)
	trap.z_index = 1
	add_child(trap)

func _spawn_trap_room_warning(trap_count: int) -> void:
	var old := get_node_or_null("TrapRoomWarning")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "TrapRoomWarning"
	label.text = "Trap Room | Dodge hazards | Reward cache"
	label.position = tile_to_world(Vector2i(grid.width / 2, 1)) + Vector2(-58, 0)
	label.size = Vector2(116, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 6
	label.set_meta("trap_count", trap_count)
	label.set_meta("reward_hint", "event_cache")
	label.set_meta("survive_seconds", TRAP_ROOM_SURVIVE_SECONDS)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	add_child(label)

func _start_trap_room_survival_gate() -> void:
	if _room_type != RoomNode.RoomType.EVENT or _trap_room_cache == null:
		return
	if _trap_room_survival_complete:
		_trap_room_cache.set_interaction_locked(false)
		_complete_trap_room_survival_countdown()
		_emit_objective_context_changed()
		return
	_trap_room_cache.set_interaction_locked(true,
		"Survive traps %.0fs | Cache locked" % TRAP_ROOM_SURVIVE_SECONDS)
	_show_trap_room_survival_countdown(TRAP_ROOM_SURVIVE_SECONDS)
	var timer := Timer.new()
	timer.name = "TrapRoomSurvivalTimer"
	timer.one_shot = true
	timer.wait_time = TRAP_ROOM_SURVIVE_SECONDS
	timer.set_meta("survive_seconds", TRAP_ROOM_SURVIVE_SECONDS)
	timer.timeout.connect(complete_trap_room_survival)
	add_child(timer)
	if is_inside_tree():
		timer.start()
	else:
		timer.autostart = true

func complete_trap_room_survival() -> void:
	if _room_type != RoomNode.RoomType.EVENT or _trap_room_survival_complete:
		return
	_trap_room_survival_complete = true
	set_meta("trap_room_survived", true)
	var timer := get_node_or_null("TrapRoomSurvivalTimer") as Timer
	if timer != null:
		timer.stop()
	if _trap_room_cache != null and is_instance_valid(_trap_room_cache):
		_trap_room_cache.set_interaction_locked(false)
	if _player != null and _player.has_method("record_room_decision"):
		_player.call("record_room_decision", "Trap Room",
			"Survived %.0fs / Cache unlocked" % TRAP_ROOM_SURVIVE_SECONDS)
	_complete_trap_room_survival_countdown()
	_show_trap_room_survived_feedback()
	_play_trap_room_survived_sfx()
	trap_room_survived.emit()
	_emit_objective_context_changed()

func _show_trap_room_survival_countdown(time_left: float) -> void:
	var old := get_node_or_null("TrapRoomSurvivalCountdown")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "TrapRoomSurvivalCountdown"
	label.position = tile_to_world(Vector2i(grid.width / 2, 2)) + Vector2(-56, 0)
	label.size = Vector2(112, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 6
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.48))
	add_child(label)
	_trap_room_countdown_label = label
	_update_trap_room_survival_countdown(time_left)

func _update_trap_room_survival_countdown(time_left: float) -> void:
	if _trap_room_countdown_label == null or not is_instance_valid(_trap_room_countdown_label):
		return
	var seconds_left := maxi(ceili(time_left), 0)
	var urgency := "urgent" if time_left <= TRAP_ROOM_URGENT_SECONDS else "normal"
	_trap_room_countdown_label.text = "Survive %ds | Hurry | Cache locked" % seconds_left \
		if urgency == "urgent" else "Survive %ds | Cache locked" % seconds_left
	_trap_room_countdown_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.45, 0.25) if urgency == "urgent" else Color(1.0, 0.92, 0.48))
	_trap_room_countdown_label.set_meta("objective_state", "survive")
	_trap_room_countdown_label.set_meta("survive_seconds", TRAP_ROOM_SURVIVE_SECONDS)
	_trap_room_countdown_label.set_meta("time_left_seconds", time_left)
	_trap_room_countdown_label.set_meta("countdown_urgency", urgency)

func _complete_trap_room_survival_countdown() -> void:
	if _trap_room_countdown_label == null or not is_instance_valid(_trap_room_countdown_label):
		_show_trap_room_survival_countdown(0.0)
	_trap_room_countdown_label.text = "Cache unlocked"
	_trap_room_countdown_label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.58))
	_trap_room_countdown_label.set_meta("objective_state", "complete")
	_trap_room_countdown_label.set_meta("survive_seconds", TRAP_ROOM_SURVIVE_SECONDS)
	_trap_room_countdown_label.set_meta("time_left_seconds", 0.0)
	_trap_room_countdown_label.set_meta("countdown_urgency", "complete")

func live_objective_context() -> Dictionary:
	if _room_type == RoomNode.RoomType.EVENT:
		return _trap_room_live_objective_context()
	if _is_combat_objective_room():
		return _combat_live_objective_context()
	if not _room_requires_objective():
		return {}
	var objective := _first_live_objective_interactable()
	if objective == null:
		return {}
	return _interactable_live_objective_context(objective)

func _is_combat_objective_room() -> bool:
	return _room_type == RoomNode.RoomType.COMBAT \
		or _room_type == RoomNode.RoomType.ELITE \
		or _room_type == RoomNode.RoomType.MINIBOSS \
		or _room_type == RoomNode.RoomType.BOSS

func _combat_live_objective_context() -> Dictionary:
	if is_cleared or _plan.is_empty():
		return {}
	var wave_count := _wave_count()
	var wave := clampi(_current_wave, 1, wave_count)
	var enemies_left := maxi(_alive, 0)
	var room_type := _room_type_label()
	var target := "Defeat boss" if _room_type == RoomNode.RoomType.BOSS else "Defeat enemies"
	var wave_text := "Wave %d/%d" % [wave, wave_count]
	var enemy_text := "%d left" % enemies_left
	var next_key := "boss" if _room_type == RoomNode.RoomType.BOSS else "combat"
	return {
		"objective_state": "active",
		"objective_text": "%s | %s | %s" % [target, wave_text, enemy_text],
		"next_action_text": "Next: %s | %s" % [target, wave_text],
		"next_action_key": next_key,
		"next_action_chain": next_key,
		"next_action_priority": next_key,
		"room_type": room_type,
		"wave_index": wave,
		"wave_count": wave_count,
		"enemies_left": enemies_left,
		"wave_progress_text": "%s | %s" % [wave_text, enemy_text],
	}

func _trap_room_live_objective_context() -> Dictionary:
	var label := _trap_room_countdown_label
	if label == null or not is_instance_valid(label):
		label = get_node_or_null("TrapRoomSurvivalCountdown") as Label
	if label == null:
		return {}
	var state := str(label.get_meta("objective_state", "survive"))
	var text := str(label.text)
	var cache_used := _trap_room_cache != null and is_instance_valid(_trap_room_cache) \
		and bool(_trap_room_cache.used)
	if cache_used:
		state = "used"
		text = "Cache opened | Door route open"
	elif state == "complete":
		text = "Cache unlocked | Open cache"
	var context := {
		"objective_state": state,
		"objective_text": "Trap Room | %s" % text,
		"next_action_text": "Next: %s" % text,
		"next_action_key": "door" if cache_used else ("survive" if state == "survive" else "interact"),
		"next_action_chain": "survive -> interact" if state == "survive" else (
			"interact -> door" if state == "complete" else "door"),
		"next_action_priority": "survive" if state == "survive" else (
			"interact" if state == "complete" else "door"),
		"survive_seconds": TRAP_ROOM_SURVIVE_SECONDS,
		"time_left_seconds": float(label.get_meta("time_left_seconds", 0.0)),
		"countdown_urgency": str(label.get_meta("countdown_urgency", "")),
		"trap_room_cache_unlocked": state == "complete",
	}
	var reward := _interactable_reward_context("trap_cache", cache_used, state == "survive")
	reward["reward_label"] = "Event cache"
	reward["reward_preview"] = "Survive %.0fs -> %s" % [
		TRAP_ROOM_SURVIVE_SECONDS,
		str(reward.get("reward_preview", "Cache reward")),
	] if state == "survive" else str(reward.get("reward_preview", "Cache reward"))
	for key in reward.keys():
		context[str(key)] = reward[key]
	return context

func _first_live_objective_interactable() -> RoomInteractable:
	for child in get_children():
		if child is RoomInteractable:
			return child
	return null

func _interactable_live_objective_context(objective: RoomInteractable) -> Dictionary:
	var used := bool(objective.used)
	var kind := str(objective.kind)
	var state := "used" if used else "available"
	var text := _interactable_live_objective_text(kind, used)
	var next_key := "door" if used else _interactable_next_action_key(kind)
	var next_text := "Move to a door" if used else text
	var context := {
		"objective_state": state,
		"objective_text": "%s | %s" % [_room_clear_subject(), text],
		"next_action_text": "Next: %s" % next_text,
		"next_action_key": next_key,
		"next_action_chain": next_key,
		"next_action_priority": next_key,
		"interactable_kind": kind,
		"interactable_used": used,
		"uses_remaining": 0 if used else 1,
	}
	var reward := _interactable_reward_context(kind, used)
	for key in reward.keys():
		context[str(key)] = reward[key]
	return context

func _interactable_reward_context(kind: String, claimed: bool, locked: bool = false) -> Dictionary:
	var reward_kind := "interactable"
	var reward_label := kind.replace("_", " ").capitalize()
	var reward_preview := "Reward"
	match kind:
		"chest":
			reward_kind = "loot_cache"
			reward_label = "Chest reward"
			reward_preview = "Gold + Potion"
		"shop":
			reward_kind = "shop_choice"
			reward_label = "Shop choice"
			reward_preview = "Choose 1 of 3 shop items"
		"shrine":
			reward_kind = "heal"
			reward_label = "Heal shrine"
			reward_preview = "Heal +30"
		"element_altar":
			reward_kind = "element_boon"
			reward_label = "Element boon"
			reward_preview = "Core + element damage"
		"locked_chest":
			reward_kind = "locked_chest"
			reward_label = "Locked chest"
			reward_preview = "Key x1 -> Gold + Weapon"
		"secret_cache":
			reward_kind = "secret_cache"
			reward_label = "Secret cache"
			reward_preview = "Key + Rune Dust + Gold"
		"trap_cache":
			reward_kind = "trap_cache"
			reward_label = "Trap cache"
			reward_preview = "Gold + Potion"
		"blood_altar":
			reward_kind = "blood_altar"
			reward_label = "Blood altar"
			reward_preview = "HP -> Soul + Rune Dust"
		"rune_cache":
			reward_kind = "rune_cache"
			reward_label = "Rune cache"
			reward_preview = "Rune Dust + Gold"
		"cursed_chest":
			reward_kind = "cursed_chest"
			reward_label = "Cursed chest"
			reward_preview = "Cursed -> Blueprint + Gold"
	return {
		"reward_kind": reward_kind,
		"reward_label": reward_label,
		"reward_preview": reward_preview,
		"reward_claimed": claimed,
		"reward_locked": locked,
	}

func _interactable_next_action_key(kind: String) -> String:
	return "shop" if kind == "shop" else "interact"

func _interactable_live_objective_text(kind: String, used: bool) -> String:
	if used:
		match kind:
			"chest":
				return "Chest opened | Reward dropped"
			"shop":
				return "Shop resolved | Door route open"
			"shrine":
				return "Heal shrine used | Door route open"
			"element_altar":
				return "Element altar used | Door route open"
			"locked_chest":
				return "Locked chest opened | Reward dropped"
			"secret_cache":
				return "Secret cache opened | Reward dropped"
			"trap_cache":
				return "Cache opened | Door route open"
			"blood_altar":
				return "Blood altar used | Reward dropped"
			"rune_cache":
				return "Rune cache opened | Reward dropped"
			"cursed_chest":
				return "Cursed chest opened | Reward dropped"
		return "Objective used | Door route open"
	match kind:
		"chest":
			return "Chest ready"
		"shop":
			return "Choose 1 of 3 shop items"
		"shrine":
			return "Heal shrine ready"
		"element_altar":
			return "Element altar ready | Core + element damage boon"
		"secret_cache":
			return "Secret cache ready"
		"trap_cache":
			return "Cache ready"
		"blood_altar":
			return "Blood altar ready"
		"rune_cache":
			return "Rune cache ready"
		"cursed_chest":
			return "Cursed chest ready"
		"locked_chest":
			return "Locked chest ready"
	return "Interactable ready"

func _show_trap_room_survived_feedback() -> void:
	var old := get_node_or_null("TrapRoomSurvived")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "TrapRoomSurvived"
	label.text = "Cache unlocked"
	label.position = tile_to_world(Vector2i(grid.width / 2, 3)) + Vector2(-34, 0)
	label.size = Vector2(68, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 6
	label.set_meta("trap_room_survived", true)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.58))
	add_child(label)

func _play_trap_room_survived_sfx() -> void:
	var cue: Dictionary = AudioCueDBScript.objective_complete_cue("Cache unlocked")
	var sfx := get_node_or_null("TrapRoomSurvivedSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "TrapRoomSurvivedSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("trap_room_survived", true)
	sfx.set_meta("objective_state", "complete")
	sfx.set_meta("survive_seconds", TRAP_ROOM_SURVIVE_SECONDS)
	sfx.set_meta("trap_room_sound_id", str(cue.get("id", "objective_complete")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "objective_complete")))
	sfx.set_meta("trap_room_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()


func _spawn_prop(kind: String, tile: Vector2i) -> void:
	var prop := BreakablePropScript.new()
	var drop := {"type": "gold", "value": 3} if kind == "crate" else {"type": "potion", "value": 12}
	prop.configure(kind, 2, drop, _player)
	prop.position = tile_to_world(tile)
	prop.z_index = 1
	add_child(prop)


func _spawn_interactable(kind: String, tile: Vector2i) -> RoomInteractable:
	var interactable := RoomInteractableScript.new()
	interactable.configure(kind, _player, _interactable_options(kind))
	interactable.position = tile_to_world(tile)
	interactable.z_index = 1
	interactable.objective_completed.connect(_on_room_objective_completed)
	interactable.shop_requested.connect(_on_shop_requested)
	add_child(interactable)
	return interactable


func _interactable_options(kind: String) -> Dictionary:
	if _room_type == RoomNode.RoomType.EVENT and EVENT_INTERACTABLE_KINDS.has(kind):
		return {
			"interaction_locked": true,
			"locked_prompt_text": "Survive traps %.0fs | Cache locked" % TRAP_ROOM_SURVIVE_SECONDS,
		}
	if kind == "shrine" and _room_type == RoomNode.RoomType.HEAL:
		return {"allow_full_hp_complete": true}
	if kind != "shop":
		return {}
	if not _biome.has("shop_min_rarity"):
		return {}
	return {"min_weapon_rarity": str(_biome.get("shop_min_rarity", "common"))}

func _event_interactable_kind() -> String:
	if _biome.has("event_kind"):
		return str(_biome.get("event_kind", "trap_cache"))
	var biome_hash := str(_biome.get("id", "ancient_cave")).hash()
	var idx := absi(biome_hash + grid.width * 31 + grid.height * 17) % EVENT_INTERACTABLE_KINDS.size()
	return EVENT_INTERACTABLE_KINDS[idx]

func _room_center_tile() -> Vector2i:
	return Vector2i(grid.width / 2, grid.height / 2)


func _feature_tiles(count: int) -> Array[Vector2i]:
	var scored: Array[Dictionary] = []
	var center := _room_center_tile()
	var doors := grid.door_positions()
	for y in range(1, grid.height - 1):
		for x in range(1, grid.width - 1):
			var p := Vector2i(x, y)
			if not grid.is_walkable_at(x, y):
				continue
			if Vector2(p - center).length() < 2.0:
				continue
			if _near_any_door(p, doors, 3):
				continue
			var score := absi((x * 73856093) ^ (y * 19349663) ^ (_room_type * 83492791))
			scored.append({"tile": p, "score": score})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["score"]) < int(b["score"]))
	var out: Array[Vector2i] = []
	for i in mini(count, scored.size()):
		out.append(scored[i]["tile"])
	return out

func _trap_tiles(count: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var blocked := _current_trap_tiles()
	for tile in _feature_tiles(count + 16):
		blocked[tile] = true
		if _doors_reachable_without_tiles(blocked):
			out.append(tile)
			if out.size() >= count:
				break
		else:
			blocked.erase(tile)
	return out

func _current_trap_tiles() -> Dictionary:
	var blocked := {}
	for child in get_children():
		if child.is_in_group("room_traps"):
			blocked[world_to_tile(child.position)] = true
	return blocked

func _doors_reachable_without_tiles(blocked: Dictionary) -> bool:
	var doors := grid.door_positions()
	if doors.size() < 2:
		return true
	var start := doors[0]
	if blocked.has(start) or not grid.is_walkable_at(start.x, start.y):
		return false
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = p + offset
			if seen.has(n) or blocked.has(n) or not grid.is_walkable_at(n.x, n.y):
				continue
			seen[n] = true
			queue.append(n)
	for door in doors:
		if not seen.has(door):
			return false
	return true


func _near_any_door(tile: Vector2i, doors: Array[Vector2i], radius: int) -> bool:
	for door in doors:
		if maxi(absi(tile.x - door.x), absi(tile.y - door.y)) <= radius:
			return true
	return false


func _spawn_wave(wave: int) -> void:
	_current_wave = wave
	var count := 0
	for entry in _plan:
		if int(entry["wave"]) == wave:
			count += _spawn_enemy(entry)
	_alive = count
	if wave > 1 and count > 0:
		_show_wave_start_cue(wave, count)
	if count == 0:
		_try_advance_after_objective()
	else:
		_emit_objective_context_changed()

func _show_wave_start_cue(wave: int, enemy_count: int) -> void:
	var existing := get_node_or_null("WaveStartCue")
	if existing != null:
		remove_child(existing)
		existing.queue_free()
	var wave_count := _wave_count()
	var label := Label.new()
	label.name = "WaveStartCue"
	label.text = "Wave %d/%d | %d enemies" % [wave, wave_count, enemy_count]
	label.position = tile_to_world(_room_center_tile()) + Vector2(-48, -48)
	label.size = Vector2(96, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 6
	label.set_meta("wave_index", wave)
	label.set_meta("wave_count", wave_count)
	label.set_meta("enemy_count", enemy_count)
	label.set_meta("room_type", _room_type_label())
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	add_child(label)
	_play_wave_start_sfx(wave, wave_count, enemy_count)

func _play_wave_start_sfx(wave: int, wave_count: int, enemy_count: int) -> void:
	var cue: Dictionary = AudioCueDBScript.wave_start_cue(
		wave,
		wave_count,
		enemy_count,
		_room_type_label())
	var sfx := get_node_or_null("WaveStartSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "WaveStartSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("wave_start_sound_id", str(cue.get("id", "wave_start")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "wave_start")))
	sfx.set_meta("wave_index", wave)
	sfx.set_meta("wave_count", wave_count)
	sfx.set_meta("enemy_count", enemy_count)
	sfx.set_meta("room_type", _room_type_label())
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _wave_count() -> int:
	var max_wave := 1
	for entry in _plan:
		max_wave = maxi(max_wave, int(entry["wave"]))
	return max_wave

func _emit_objective_context_changed() -> void:
	var context := live_objective_context()
	if context.is_empty():
		return
	objective_context_changed.emit(context)

func _spawn_enemy(entry: Dictionary) -> int:
	var data: Dictionary = entry["enemy"]
	var kind := str(data["kind"])
	var enemy: Enemy
	if kind == "boss":
		enemy = _make_boss()
	else:
		enemy = _enemy_scene.instantiate()
	enemy.kind = kind
	enemy.set_meta("enemy_id", str(data.get("id", "")))
	enemy.max_hp = int(data["hp"])
	enemy.contact_damage = int(data["dmg"])
	enemy.speed = SPEED_BY_KIND.get(kind, 55.0)
	enemy.configure_element_affinity(data.get("weak", []), data.get("resist", []))
	if bool(entry["elite"]):
		enemy.max_hp *= 3
		enemy.scale = Vector2(1.4, 1.4)
		enemy.base_tint = Color(1.0, 0.85, 0.4)  # elite tint until real VFX
		_apply_elite_modifier(enemy, str(entry.get("modifier", "")))
	_apply_biome_to_enemy(enemy)
	_apply_room_affix_to_enemy(enemy)
	if kind == "boss":
		_apply_boss_tuning_patch(enemy)
	enemy.target = _player
	enemy.position = tile_to_world(entry["tile"])
	enemy.z_index = 2
	enemy.died.connect(_on_enemy_died.bind(entry))
	_connect_enemy_combo_tracking(enemy)
	_bind_soul_kingdom_enemy(enemy)
	_apply_family_spawn_trait(enemy)
	add_child(enemy)
	_apply_enemy_sprite(enemy, str(data.get("id", "")))
	if _player != null and is_instance_valid(_player) and _player.has_method("on_enemy_seen"):
		_player.call("on_enemy_seen", _enemy_codex_payload(enemy, entry))
	var spawned := 1
	if bool(entry["elite"]) and str(entry.get("modifier", "")) == "summoner":
		var minion := _spawn_elite_minion(entry, enemy.global_position + Vector2(18, 0), "summoner")
		if minion != null:
			spawned += 1
	spawned += _spawn_family_start_minions(enemy, entry)
	return spawned

func _apply_family_spawn_trait(enemy: Enemy) -> void:
	match str(enemy.get_meta("enemy_id", "")):
		"stalactite_wisp":
			enemy.visible = false
			enemy.set_meta("ambush_hidden", true)
			enemy.set_meta("ambush_dropped", false)

func _apply_elite_modifier(enemy: Enemy, modifier: String) -> void:
	if modifier == "":
		return
	enemy.set_meta("elite_modifier", modifier)
	match modifier:
		"armored":
			enemy.max_hp = ceili(enemy.max_hp * 2.0)
			enemy.base_tint *= Color(0.78, 0.9, 1.2)
		"berserk":
			enemy.speed *= 1.35
			enemy.contact_damage += 2
			enemy.base_tint *= Color(1.35, 0.75, 0.55)
		"burning":
			enemy.contact_damage += 2
			enemy.base_tint *= Color(1.35, 0.7, 0.35)
		"frozen":
			enemy.speed *= 0.75
			enemy.base_tint *= Color(0.65, 0.9, 1.35)
		"explosive":
			enemy.contact_damage += 4
			enemy.base_tint *= Color(1.3, 0.55, 0.35)
		"vampiric":
			enemy.max_hp = ceili(enemy.max_hp * 1.25)
			enemy.contact_damage += 1
			enemy.base_tint *= Color(1.25, 0.65, 0.85)
		"shielded":
			enemy.max_hp += 20
			enemy.base_tint *= Color(0.7, 1.0, 1.15)
		"teleporting":
			enemy.speed *= 1.2
			enemy.base_tint *= Color(0.95, 0.75, 1.35)
		"splitter", "summoner":
			enemy.max_hp = ceili(enemy.max_hp * 1.2)
			enemy.base_tint *= Color(1.1, 1.0, 0.7)
	if enemy.has_method("show_elite_modifier_label"):
		enemy.call("show_elite_modifier_label", modifier)

func _apply_room_affix_to_enemy(enemy: Enemy) -> void:
	var affix_id := str(_room_affix.get("id", "none"))
	if affix_id == "none":
		return
	enemy.set_meta("room_affix", affix_id)
	enemy.speed *= float(_room_affix.get("enemy_speed_mult", 1.0))
	enemy.contact_damage += int(_room_affix.get("enemy_damage_bonus", 0))
	var tint: Variant = _room_affix.get("enemy_tint", Color.WHITE)
	if tint is Color:
		enemy.base_tint *= tint

func _apply_biome_to_enemy(enemy: Enemy) -> void:
	var biome_id := str(_biome.get("id", ""))
	if biome_id == "":
		return
	enemy.set_meta("biome", biome_id)
	enemy.max_hp = maxi(1, ceili(float(enemy.max_hp) * float(_biome.get("enemy_hp_mult", 1.0))))
	enemy.contact_damage = maxi(1, ceili(float(enemy.contact_damage) * float(_biome.get("enemy_damage_mult", 1.0))))
	enemy.speed *= float(_biome.get("enemy_speed_mult", 1.0))

func _apply_boss_tuning_patch(enemy: Enemy) -> void:
	var patch: Variant = _biome.get("boss_tuning_patch", {})
	if not (patch is Dictionary) or (patch as Dictionary).is_empty():
		return
	if enemy.has_method("apply_tuning_patch"):
		enemy.call("apply_tuning_patch", patch)

func room_affix_name() -> String:
	return str(_room_affix.get("name", ""))

func biome_name() -> String:
	return str(_biome.get("name", ""))

func boss_status() -> Dictionary:
	for child in get_children():
		var boss := child as BossGolem
		if boss == null or boss.is_queued_for_deletion():
			continue
		return boss.boss_status()
	return {}


## Bosses have no scene yet: build the node tree in code.
func _make_boss() -> Enemy:
	var boss := BossGolem.new()
	boss.boss_phase_changed.connect(func(status: Dictionary) -> void:
		boss_phase_changed.emit(status))
	boss.boss_attack_cued.connect(func(status: Dictionary) -> void:
		boss_attack_cued.emit(status))
	boss.configure_variant(str(_biome.get("boss_variant", "cave_golem")))
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 20)
	shape.shape = rect
	boss.add_child(shape)
	var body := Polygon2D.new()
	body.name = "Body"
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

func _enemy_codex_payload(enemy: Enemy, entry: Dictionary) -> Dictionary:
	var data: Dictionary = entry.get("enemy", {})
	var enemy_id := str(enemy.get_meta("enemy_id", data.get("id", ""))).strip_edges()
	var label := str(data.get("name", "")).strip_edges()
	if label == "":
		label = enemy_id.replace("_", " ").capitalize()
	var enemy_kind := str(data.get("kind", enemy.kind)).strip_edges()
	return {
		"id": enemy_id,
		"enemy_id": enemy_id,
		"name": label,
		"enemy_name": label,
		"kind": enemy_kind,
		"enemy_kind": enemy_kind,
		"biome_id": str(_biome.get("id", "")).strip_edges(),
		"biome": str(_biome.get("name", "")).strip_edges(),
	}

func _on_enemy_died(enemy: Enemy, entry: Dictionary) -> void:
	var modifier := str(enemy.get_meta("elite_modifier", ""))
	if modifier == "explosive":
		_trigger_explosive_elite_death(enemy)
	elif modifier == "splitter":
		_alive += _spawn_splitter_minions(enemy, entry)
	_alive += _spawn_family_death_minions(enemy, entry)
	if _player != null and is_instance_valid(_player) and _player.has_method("on_enemy_killed"):
		var kill_context := _enemy_codex_payload(enemy, entry)
		kill_context["elite"] = bool(entry.get("elite", false))
		kill_context["marked"] = enemy.has_meta("poison_knife_mark_duration_seconds") \
				or enemy.has_meta("status_vulnerable_left")
		_player.call("on_enemy_killed", kill_context)
	if not bool(entry.get("no_loot", false)):
		_drop_loot(enemy.position, entry)
	_alive -= 1
	if _alive > 0:
		_emit_objective_context_changed()
	if _alive <= 0:
		_try_advance_after_objective()

func _trigger_explosive_elite_death(enemy: Enemy) -> void:
	var radius := 52.0
	var damage := maxi(6, enemy.contact_damage)
	CombatFxScript.spawn_telegraph(
		self,
		enemy.global_position,
		Vector2.RIGHT,
		radius,
		0.18,
		Color(1.0, 0.38, 0.14, 0.72)
	)
	if _player == null or not is_instance_valid(_player):
		return
	if enemy.global_position.distance_to(_player.global_position) > radius:
		return
	if _player.has_method("take_damage"):
		if _player is Player:
			_player.take_damage(damage, enemy.global_position, "Elite Explosion")
		else:
			_player.take_damage(damage)

func _spawn_splitter_minions(enemy: Enemy, entry: Dictionary) -> int:
	var spawned := 0
	for offset in [Vector2(-14, 0), Vector2(14, 0)]:
		if _spawn_elite_minion(entry, enemy.global_position + offset, "splitter") != null:
			spawned += 1
	return spawned

func _spawn_elite_minion(entry: Dictionary, at: Vector2, source: String) -> Enemy:
	if _enemy_scene == null:
		return null
	var data: Dictionary = entry.get("enemy", {})
	if data.is_empty():
		return null
	var kind := str(data.get("kind", "melee"))
	var minion := _enemy_scene.instantiate() as Enemy
	if minion == null:
		return null
	minion.kind = kind
	minion.max_hp = maxi(1, ceili(float(data.get("hp", 1)) * 0.55))
	minion.contact_damage = maxi(1, ceili(float(data.get("dmg", 1)) * 0.65))
	minion.speed = float(SPEED_BY_KIND.get(kind, 55.0)) * 1.08
	minion.scale = Vector2(0.78, 0.78)
	minion.base_tint = Color(0.85, 1.0, 0.72) if source == "summoner" else Color(1.0, 0.92, 0.58)
	minion.configure_element_affinity(data.get("weak", []), data.get("resist", []))
	_apply_biome_to_enemy(minion)
	_apply_room_affix_to_enemy(minion)
	minion.target = _player
	minion.z_index = 2
	minion.set_meta("elite_minion", source)
	var minion_entry := entry.duplicate(true)
	minion_entry["elite"] = false
	minion_entry["modifier"] = ""
	minion_entry["no_loot"] = true
	minion.died.connect(_on_enemy_died.bind(minion_entry))
	_connect_enemy_combo_tracking(minion)
	_bind_soul_kingdom_enemy(minion)
	add_child(minion)
	minion.global_position = at
	_apply_enemy_sprite(minion, str(data.get("id", "")))
	return minion

func _spawn_family_death_minions(enemy: Enemy, entry: Dictionary) -> int:
	if bool(entry.get("no_family_split", false)):
		return 0
	var enemy_id := str(enemy.get_meta("enemy_id", ""))
	match enemy_id:
		"rubble_golem":
			var spawned := 0
			for offset in [Vector2(-12, 0), Vector2(12, 0)]:
				if _spawn_family_minion(entry, enemy.global_position + offset, enemy_id) != null:
					spawned += 1
			return spawned
	return 0

func _spawn_family_start_minions(enemy: Enemy, entry: Dictionary) -> int:
	match str(enemy.get_meta("enemy_id", "")):
		"beast_herder":
			var specs: Array[Dictionary] = [
				{"id": "stone_rat", "kind": "melee_charger", "hp": 12, "dmg": 3, "weak": ["fire"], "resist": ["earth"]},
				{"id": "cave_slime", "kind": "melee", "hp": 10, "dmg": 2, "weak": ["lightning"], "resist": ["water"]},
			]
			var spawned := 0
			for i in specs.size():
				var offset := Vector2(-18 + i * 36, 12)
				if _spawn_family_minion(entry, enemy.global_position + offset, "beast_herder", specs[i]) != null:
					spawned += 1
			if spawned > 0 and enemy.has_method("show_family_warning"):
				enemy.call("show_family_warning")
			return spawned
		"spore_matriarch":
			var spore_specs: Array[Dictionary] = [
				{"id": "sporeling", "kind": "melee", "hp": 16, "dmg": 4, "weak": ["fire"], "resist": ["poison"]},
				{"id": "sporeling", "kind": "melee", "hp": 16, "dmg": 4, "weak": ["fire"], "resist": ["poison"]},
				{"id": "puffcap_bomber", "kind": "exploder", "hp": 18, "dmg": 8, "weak": ["fire"], "resist": ["poison"]},
			]
			var spore_spawned := 0
			for i in spore_specs.size():
				var offset := Vector2(-24 + i * 24, 16)
				if _spawn_family_minion(entry, enemy.global_position + offset, "spore_matriarch", spore_specs[i]) != null:
					spore_spawned += 1
			if spore_spawned > 0 and enemy.has_method("show_family_warning"):
				enemy.call("show_family_warning")
			return spore_spawned
		"forge_captain":
			var forge_specs: Array[Dictionary] = [
				{"id": "anvil_guard", "kind": "tanker", "hp": 72, "dmg": 9, "weak": ["lightning"], "resist": ["metal", "fire"]},
				{"id": "coal_imp", "kind": "melee_charger", "hp": 24, "dmg": 7, "weak": ["water"], "resist": ["fire"]},
			]
			var forge_spawned := 0
			for i in forge_specs.size():
				var offset := Vector2(-18 + i * 36, 16)
				if _spawn_family_minion(entry, enemy.global_position + offset, "forge_captain", forge_specs[i]) != null:
					forge_spawned += 1
			if forge_spawned > 0 and enemy.has_method("show_family_warning"):
				enemy.call("show_family_warning")
			return forge_spawned
		"archive_curator":
			var archive_specs: Array[Dictionary] = [
				{"id": "archive_mite", "kind": "melee", "hp": 18, "dmg": 5, "weak": ["fire"], "resist": ["ice"]},
				{"id": "glyph_archer", "kind": "ranged", "hp": 36, "dmg": 10, "weak": ["dark"], "resist": ["light"]},
				{"id": "mirror_acolyte", "kind": "caster", "hp": 42, "dmg": 11, "weak": ["fire"], "resist": ["ice", "light"]},
			]
			var archive_spawned := 0
			for i in archive_specs.size():
				var offset := Vector2(-28 + i * 28, 18)
				if _spawn_family_minion(entry, enemy.global_position + offset, "archive_curator", archive_specs[i]) != null:
					archive_spawned += 1
			if archive_spawned > 0 and enemy.has_method("show_family_warning"):
				enemy.call("show_family_warning")
			return archive_spawned
	return 0

func _spawn_family_minion(
		entry: Dictionary,
		at: Vector2,
		source: String,
		override_data: Dictionary = {},
) -> Enemy:
	if _enemy_scene == null:
		return null
	var data: Dictionary = override_data.duplicate(true) if not override_data.is_empty() else entry.get("enemy", {})
	if data.is_empty():
		return null
	var kind := str(data.get("kind", "melee"))
	var minion := _enemy_scene.instantiate() as Enemy
	if minion == null:
		return null
	minion.kind = kind
	var minion_enemy_id := str(data.get("id", source))
	minion.set_meta("enemy_id", minion_enemy_id)
	minion.max_hp = maxi(1, ceili(float(data.get("hp", 1)) * 0.45))
	minion.contact_damage = maxi(1, ceili(float(data.get("dmg", 1)) * 0.6))
	minion.speed = float(SPEED_BY_KIND.get(kind, 55.0)) * 1.12
	minion.scale = Vector2(0.65, 0.65)
	minion.base_tint = Color(0.72, 0.68, 0.58) if source == "rubble_golem" else Color(0.9, 0.78, 0.45)
	minion.configure_element_affinity(data.get("weak", []), data.get("resist", []))
	_apply_biome_to_enemy(minion)
	_apply_room_affix_to_enemy(minion)
	minion.target = _player
	minion.z_index = 2
	minion.set_meta("family_minion", source)
	var minion_entry := entry.duplicate(true)
	minion_entry["elite"] = false
	minion_entry["modifier"] = ""
	minion_entry["enemy"] = data.duplicate(true)
	minion_entry["no_loot"] = true
	minion_entry["no_family_split"] = true
	minion.died.connect(_on_enemy_died.bind(minion_entry))
	_connect_enemy_combo_tracking(minion)
	_bind_soul_kingdom_enemy(minion)
	add_child(minion)
	minion.global_position = at
	_apply_enemy_sprite(minion, minion_enemy_id)
	return minion

func _connect_enemy_combo_tracking(enemy: Enemy) -> void:
	if enemy == null or not enemy.has_signal("element_combo_triggered"):
		return
	enemy.connect("element_combo_triggered", _on_enemy_element_combo)

func _bind_soul_kingdom_enemy(enemy: Enemy) -> void:
	if enemy == null or not (_player is Player):
		return
	SoulKingdomUltimateScript.bind_spawned_enemy(enemy, self, _player)

func _on_enemy_element_combo(info: Dictionary) -> void:
	if _player != null and is_instance_valid(_player) \
			and _player.has_method("record_element_combo"):
		_player.call("record_element_combo", info)

func _on_room_objective_completed(kind: String, payload: Dictionary) -> void:
	_interactables_claimed = true
	interactable_completed.emit(kind, payload)
	if not _room_requires_objective():
		return
	_objective_pending = false
	_try_advance_after_objective()

func _on_shop_requested(shop: RoomInteractable, choices: Array) -> void:
	shop_choice_requested.emit(shop, choices)

func _try_advance_after_objective() -> void:
	if _objective_pending:
		return
	_advance()

func _room_requires_objective() -> bool:
	return _room_type == RoomNode.RoomType.TREASURE \
		or _room_type == RoomNode.RoomType.SHOP \
		or _room_type == RoomNode.RoomType.HEAL \
		or _room_type == RoomNode.RoomType.SHRINE \
		or _room_type == RoomNode.RoomType.EVENT \
		or _room_type == RoomNode.RoomType.SECRET


func _drop_loot(at: Vector2, entry: Dictionary) -> void:
	var drops := LootRoller.roll_drops(entry, {
		"pity_rooms_without_rare_plus": _loot_pity_rooms_without_rare_plus,
		"room_type": _room_type,
	})
	for i in drops.size():
		_note_rare_plus_drop(drops[i])
		var pickup := Pickup.new()
		pickup.configure(drops[i], _player)
		pickup.position = at + Vector2((i - (drops.size() - 1) * 0.5) * 9.0, 5.0)
		pickup.z_index = 1
		add_child(pickup)

func _note_rare_plus_drop(drop: Dictionary) -> void:
	if str(drop.get("type", "")) != "weapon":
		return
	var weapon := WeaponDB.get_weapon(str(drop.get("id", "")))
	var rarity := str(weapon.get("rarity", "common"))
	if _rarity_rank(rarity) >= _rarity_rank("rare"):
		_room_dropped_rare_plus = true

func _rarity_rank(rarity: String) -> int:
	return ["common", "uncommon", "rare", "epic", "legendary", "mythic"].find(rarity)


func _advance() -> void:
	var next_wave := _next_wave_after(_current_wave)
	if next_wave > 0:
		_spawn_wave(next_wave)
		return
	if is_cleared:
		return
	is_cleared = true
	_unlock_doors()
	queue_redraw()
	if not _plan.is_empty() or _room_requires_objective():
		print("Room cleared!")
		_show_room_clear_banner()
		_play_room_clear_sfx()
		_update_loot_pity_after_room()
	room_cleared.emit()

func _show_room_clear_banner() -> void:
	var existing := get_node_or_null("RoomClearBanner")
	if existing != null:
		existing.queue_free()
	var label := Label.new()
	label.name = "RoomClearBanner"
	label.text = _room_clear_banner_text()
	label.position = tile_to_world(_room_center_tile()) + Vector2(-56, -34)
	label.size = Vector2(112, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", _room_clear_banner_color())
	label.z_index = 6
	add_child(label)

func _room_clear_banner_text() -> String:
	if _room_type == RoomNode.RoomType.BOSS:
		if _is_run_finale_boss():
			return "Final Boss defeated | Run complete portal ready | boss reward ready"
		return "Boss defeated | Portal opened | boss reward ready"
	if _room_requires_objective():
		return "%s Objective complete | Reward ready" % _room_clear_subject()
	return "Room Cleared | Reward ready"

func _room_clear_banner_color() -> Color:
	if _is_run_finale_boss():
		return Color(1.0, 0.92, 0.48)
	if _room_type == RoomNode.RoomType.BOSS:
		return Color(1.0, 0.78, 0.36)
	if _room_requires_objective():
		return Color(0.68, 0.88, 1.0)
	return Color(0.72, 1.0, 0.68)

func _room_clear_subject() -> String:
	match _room_type:
		RoomNode.RoomType.TREASURE:
			return "Treasure"
		RoomNode.RoomType.SHOP:
			return "Shop"
		RoomNode.RoomType.HEAL:
			return "Shrine"
		RoomNode.RoomType.SHRINE:
			return "Altar"
		RoomNode.RoomType.EVENT:
			return "Event"
		RoomNode.RoomType.SECRET:
			return "Secret"
	return "Room"

func _play_room_clear_sfx() -> void:
	var banner_text := _room_clear_banner_text()
	var cue: Dictionary = AudioCueDBScript.room_clear_cue(
		_room_type_label(),
		_room_requires_objective(),
		banner_text)
	var sfx := get_node_or_null("RoomClearSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "RoomClearSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("room_clear_type", str(cue.get("room_type", _room_type_label())))
	sfx.set_meta("room_clear_objective", bool(cue.get("objective", false)))
	sfx.set_meta("room_clear_banner", banner_text)
	sfx.set_meta("room_clear_run_finale", _is_run_finale_boss())
	sfx.set_meta("room_clear_sound_id", str(cue.get("id", "room_clear_reward")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "room_clear")))
	sfx.set_meta("room_clear_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _room_type_label() -> String:
	var keys := RoomNode.RoomType.keys()
	if _room_type >= 0 and _room_type < keys.size():
		return str(keys[_room_type])
	return "COMBAT"

func _is_run_finale_boss() -> bool:
	return _room_type == RoomNode.RoomType.BOSS and bool(_biome.get("run_finale", false))

func _update_loot_pity_after_room() -> void:
	if _room_dropped_rare_plus:
		_loot_pity_rooms_without_rare_plus = 0
	else:
		_loot_pity_rooms_without_rare_plus += 1
	loot_pity_changed.emit(_loot_pity_rooms_without_rare_plus)


func _unlock_doors() -> void:
	for body in _door_bodies:
		body.queue_free()
	_door_bodies.clear()


func _has_wave(wave: int) -> bool:
	for entry in _plan:
		if int(entry["wave"]) == wave:
			return true
	return false

func _next_wave_after(wave: int) -> int:
	var next_wave := 999999
	for entry in _plan:
		var entry_wave := int(entry["wave"])
		if entry_wave > wave and entry_wave < next_wave:
			next_wave = entry_wave
	return next_wave if next_wave != 999999 else -1
