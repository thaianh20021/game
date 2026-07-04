class_name Minimap
extends Control
## Fog-of-war floor minimap: shows visited rooms, their known neighbors and
## the current room. Critical path is drawn as a row (x = depth); each side
## branch hangs as a vertical chain off its anchor (anchors are distinct by
## construction, so chains never collide). Debug style until real UI art.

const GAP := 14.0
const NODE := 8.0

const COLOR_BG := Color(0, 0, 0, 0.55)
const COLOR_EDGE := Color(0.5, 0.5, 0.5, 0.8)
const COLOR_KNOWN := Color(0.35, 0.35, 0.38)
const COLOR_VISITED := Color(0.85, 0.6, 0.2)
const COLOR_CLEARED := Color(0.35, 0.75, 0.35)
const COLOR_BOSS := Color(0.8, 0.25, 0.25)
const COLOR_CURRENT_BORDER := Color(1, 1, 1)

var _ctrl: FloorController
var _layout := {}  # room_id -> Vector2 (abstract grid coords)


func bind(ctrl: FloorController) -> void:
	_ctrl = ctrl
	_layout = _compute_layout(ctrl.rooms)
	ctrl.state_changed.connect(queue_redraw)
	queue_redraw()


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
			# Walk the branch chain vertically away from its anchor.
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

	# Fog of war: visited rooms + their direct neighbors are known.
	var known := {}
	for id in _ctrl.visited_rooms.keys():
		known[id] = true
		for n in _ctrl.rooms[id].neighbors:
			known[n] = true

	var min_x := INF
	for id in known.keys():
		var p: Vector2 = _layout.get(id, Vector2.ZERO)
		min_x = minf(min_x, p.x)
	var origin := Vector2(10.0, size.y * 0.5)

	var node_pos := func(id: int) -> Vector2:
		var p: Vector2 = _layout.get(id, Vector2.ZERO)
		return origin + Vector2((p.x - min_x) * GAP, p.y * GAP)

	for id in known.keys():
		for n in _ctrl.rooms[id].neighbors:
			if known.has(n) and n > id:
				draw_line(node_pos.call(id), node_pos.call(n), COLOR_EDGE, 1.0)

	for id in known.keys():
		var room: RoomNode = _ctrl.rooms[id]
		var color := COLOR_KNOWN
		if _ctrl.cleared_rooms.has(id):
			color = COLOR_CLEARED
		elif _ctrl.visited_rooms.has(id):
			color = COLOR_VISITED
		if room.type == RoomNode.RoomType.BOSS:
			color = color.lerp(COLOR_BOSS, 0.6)
		var rect := Rect2(node_pos.call(id) - Vector2(NODE, NODE) * 0.5, Vector2(NODE, NODE))
		draw_rect(rect, color)
		if _ctrl.current_room != null and _ctrl.current_room.id == id:
			draw_rect(rect.grow(1.5), COLOR_CURRENT_BORDER, false, 1.0)
