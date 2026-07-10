class_name Minimap
extends Control
## Fog-of-war floor minimap: shows visited rooms, their known neighbors and
## the current room. Critical path is drawn as a row (x = depth); each side
## branch hangs as a vertical chain off its anchor.

const GAP := 14.0
const NODE := 8.0

const COLOR_BG := Color(0, 0, 0, 0.55)
const COLOR_EDGE := Color(0.5, 0.5, 0.5, 0.8)
const COLOR_MAIN_PATH := Color(0.95, 0.78, 0.24, 0.95)
const COLOR_KNOWN := Color(0.35, 0.35, 0.38)
const COLOR_VISITED := Color(0.85, 0.6, 0.2)
const COLOR_CLEARED := Color(0.35, 0.75, 0.35)
const COLOR_BOSS := Color(0.8, 0.25, 0.25)
const COLOR_SPECIAL := Color(0.2, 0.75, 0.95)
const COLOR_CURRENT_BORDER := Color(1, 1, 1)
const COLOR_TEXT := Color(0.92, 0.9, 0.78)

var _ctrl: FloorController
var _layout := {}  # room_id -> Vector2 (abstract grid coords)
var _legend: Control

func bind(ctrl: FloorController) -> void:
	_ctrl = ctrl
	_layout = _compute_layout(ctrl.rooms)
	_ensure_legend()
	ctrl.state_changed.connect(queue_redraw)
	queue_redraw()

func known_room_ids() -> Array:
	var known := {}
	if _ctrl == null:
		return []
	for id in _ctrl.visited_rooms.keys():
		var room_id := int(id)
		known[room_id] = true
		if room_id >= 0 and room_id < _ctrl.rooms.size():
			for n in _ctrl.rooms[room_id].neighbors:
				known[int(n)] = true
	var ids := known.keys()
	ids.sort()
	return ids

func critical_path_room_ids() -> Array:
	if _ctrl == null:
		return []
	var rooms: Array[RoomNode] = []
	for room in _ctrl.rooms:
		if room.on_critical_path:
			rooms.append(room)
	rooms.sort_custom(func(a: RoomNode, b: RoomNode) -> bool:
		return a.depth < b.depth)
	var ids := []
	for room in rooms:
		ids.append(room.id)
	return ids

func room_route_label(room_id: int) -> String:
	if _ctrl == null or room_id < 0 or room_id >= _ctrl.rooms.size():
		return "Unknown route"
	return "Main path" if _ctrl.rooms[room_id].on_critical_path else "Side branch"

func room_glyph(room_type: int) -> String:
	match room_type:
		RoomNode.RoomType.ENTRANCE:
			return "IN"
		RoomNode.RoomType.COMBAT:
			return "C"
		RoomNode.RoomType.ELITE:
			return "E"
		RoomNode.RoomType.SHOP:
			return "$"
		RoomNode.RoomType.SHRINE:
			return "A"
		RoomNode.RoomType.TREASURE:
			return "T"
		RoomNode.RoomType.EVENT:
			return "!"
		RoomNode.RoomType.SECRET:
			return "?"
		RoomNode.RoomType.MINIBOSS:
			return "M"
		RoomNode.RoomType.HEAL:
			return "+"
		RoomNode.RoomType.BOSS:
			return "B"
	return ""

func room_reward_risk_hint(room_type: int) -> String:
	match room_type:
		RoomNode.RoomType.COMBAT:
			return "Reward: Upgrade"
		RoomNode.RoomType.ELITE:
			return "Risk: Elite | Reward: Rare+"
		RoomNode.RoomType.MINIBOSS:
			return "Risk: Miniboss | Reward: Rare+"
		RoomNode.RoomType.BOSS:
			return "Risk: Boss | Reward: Rare+ + Portal"
		RoomNode.RoomType.TREASURE:
			return "Reward: Chest + Upgrade"
		RoomNode.RoomType.SHOP:
			return "Reward: Choose 1 of 3"
		RoomNode.RoomType.HEAL:
			return "Safety: Heal once"
		RoomNode.RoomType.SHRINE:
			return "Build: Elemental Altar"
		RoomNode.RoomType.EVENT:
			return "Risk: Trap | Reward: Cache"
		RoomNode.RoomType.SECRET:
			return "Reward: Secret Cache"
	return "Route choice"

func tooltip_text(room_id: int) -> String:
	if _ctrl == null or room_id < 0 or room_id >= _ctrl.rooms.size():
		return "-"
	var room := _ctrl.rooms[room_id]
	var state := "Known"
	if _ctrl.current_room != null and _ctrl.current_room.id == room_id:
		state = "Current"
	elif _ctrl.cleared_rooms.has(room_id):
		state = "Cleared"
	elif _ctrl.visited_rooms.has(room_id):
		state = "Visited"
	var parts := [
		"%s Room %02d" % [state, room_id],
		_room_type_label(room.type),
		room_route_label(room_id),
		room_reward_risk_hint(room.type),
	]
	if _ctrl.has_method("current_threat_label"):
		parts.append(str(_ctrl.call("current_threat_label")))
	return " / ".join(parts)

func _room_type_label(room_type: int) -> String:
	match room_type:
		RoomNode.RoomType.SHRINE:
			return "ALTAR"
		_:
			return RoomNode.RoomType.keys()[room_type]

func _ensure_legend() -> void:
	if _legend != null and is_instance_valid(_legend):
		return
	_legend = Control.new()
	_legend.name = "MinimapLegend"
	_legend.position = Vector2(8, 56)
	_legend.size = Vector2(172, 38)
	add_child(_legend)
	var rows := [
		{"text": "C Current", "pos": Vector2(0, 0), "color": COLOR_CURRENT_BORDER},
		{"text": "V Visited", "pos": Vector2(66, 0), "color": COLOR_VISITED},
		{"text": "P Main", "pos": Vector2(0, 13), "color": COLOR_MAIN_PATH},
		{"text": "B Boss", "pos": Vector2(66, 13), "color": COLOR_BOSS},
		{"text": "$ Shop", "pos": Vector2(0, 26), "color": COLOR_SPECIAL},
		{"text": "T Loot", "pos": Vector2(66, 26), "color": COLOR_SPECIAL},
	]
	for row in rows:
		var label := Label.new()
		label.text = str(row["text"])
		label.position = row["pos"]
		label.add_theme_font_size_override("font_size", 8)
		label.modulate = row["color"]
		_legend.add_child(label)

func _compute_layout(rooms: Array[RoomNode]) -> Dictionary:
	var layout := {}
	for r in rooms:
		if r.on_critical_path:
			layout[r.id] = Vector2(r.depth, 0)
	for r in rooms:
		if not r.on_critical_path:
			continue
		var side := 1 if r.depth % 2 == 0 else -1
		for n in r.neighbors:
			if rooms[n].on_critical_path or layout.has(n):
				continue
			var step := 1
			var prev_id := r.id
			var current: RoomNode = rooms[n]
			while current != null and not layout.has(current.id):
				layout[current.id] = Vector2(r.depth, side * step)
				step += 1
				var next: RoomNode = null
				for m in current.neighbors:
					if m != prev_id and not rooms[m].on_critical_path and not layout.has(m):
						next = rooms[m]
				prev_id = current.id
				current = next
	return layout

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG)
	if _ctrl == null or _ctrl.rooms.is_empty():
		return

	var known_ids := known_room_ids()
	if known_ids.is_empty():
		return
	var known := {}
	for id in known_ids:
		known[int(id)] = true

	var min_x := INF
	for id in known_ids:
		var p: Vector2 = _layout.get(id, Vector2.ZERO)
		min_x = minf(min_x, p.x)
	var origin := Vector2(10.0, size.y * 0.5)

	var node_pos := func(id: int) -> Vector2:
		var p: Vector2 = _layout.get(id, Vector2.ZERO)
		return origin + Vector2((p.x - min_x) * GAP, p.y * GAP)

	for id in known_ids:
		for n in _ctrl.rooms[int(id)].neighbors:
			if known.has(n) and n > int(id):
				var edge_color := COLOR_MAIN_PATH if _is_main_path_edge(int(id), int(n)) else COLOR_EDGE
				draw_line(node_pos.call(int(id)), node_pos.call(n), edge_color, 1.0)

	for id in known_ids:
		var room: RoomNode = _ctrl.rooms[int(id)]
		var rect := Rect2(node_pos.call(int(id)) - Vector2(NODE, NODE) * 0.5, Vector2(NODE, NODE))
		draw_rect(rect, _room_color(int(id)))
		if _ctrl.current_room != null and _ctrl.current_room.id == int(id):
			draw_rect(rect.grow(1.5), COLOR_CURRENT_BORDER, false, 1.0)
		_draw_glyph(room_glyph(room.type), rect.position + Vector2(-1.0, -2.0))

func _room_color(room_id: int) -> Color:
	if _ctrl == null or room_id < 0 or room_id >= _ctrl.rooms.size():
		return COLOR_KNOWN
	var room: RoomNode = _ctrl.rooms[room_id]
	var color := COLOR_KNOWN
	if _ctrl.cleared_rooms.has(room_id):
		color = COLOR_CLEARED
	elif _ctrl.visited_rooms.has(room_id):
		color = COLOR_VISITED
	if room.on_critical_path:
		color = color.lerp(COLOR_MAIN_PATH, 0.24)
	if _is_special(room.type):
		color = color.lerp(COLOR_SPECIAL, 0.55)
	if room.type == RoomNode.RoomType.BOSS:
		color = color.lerp(COLOR_BOSS, 0.65)
	return color

func _is_special(room_type: int) -> bool:
	return room_type == RoomNode.RoomType.SHOP \
		or room_type == RoomNode.RoomType.SHRINE \
		or room_type == RoomNode.RoomType.TREASURE \
		or room_type == RoomNode.RoomType.EVENT \
		or room_type == RoomNode.RoomType.SECRET \
		or room_type == RoomNode.RoomType.MINIBOSS \
		or room_type == RoomNode.RoomType.HEAL \
		or room_type == RoomNode.RoomType.BOSS

func _is_main_path_edge(a: int, b: int) -> bool:
	if _ctrl == null or a < 0 or b < 0 or a >= _ctrl.rooms.size() or b >= _ctrl.rooms.size():
		return false
	var ra: RoomNode = _ctrl.rooms[a]
	var rb: RoomNode = _ctrl.rooms[b]
	return ra.on_critical_path and rb.on_critical_path and absi(ra.depth - rb.depth) == 1

func _draw_glyph(text: String, pos: Vector2) -> void:
	if text == "":
		return
	var font := ThemeDB.fallback_font
	if font == null:
		return
	draw_string(font, pos, text.left(1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 7, COLOR_TEXT)
