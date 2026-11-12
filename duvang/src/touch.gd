extends RefCounted
# Touch controls for phones. Only active once a finger has touched the screen (g.touch_on).
# In play: a floating stick on the left half, buttons on the right. Everywhere else a tap is a mouse click
# (Godot emulates the mouse from touch), so menus, the bag and the skill tree work by tapping.
# Attacks and skills aim at the nearest foe, or along the stick, or where the hero last faced.

const Art = preload("res://src/art.gd")
const Txt = preload("res://src/font.gd")
const Sk = preload("res://src/skills.gd")

const STICK_R = 30.0
const INK = Color("1a1420")
const FACE = Color(0.95, 0.92, 0.82, 0.18)
const RIM = Color(0.95, 0.92, 0.82, 0.55)

# [key, centre offset from the bottom-right (or top-right when the y is positive), radius, label]
static func buttons(view: Vector2) -> Array:
	var w = view.x
	var h = view.y
	return [
		["atk", Vector2(w - 50, h - 52), 25.0, ""],
		["dodge", Vector2(w - 104, h - 26), 17.0, "NÉ"],
		["s1", Vector2(w - 108, h - 72), 15.0, ""],
		["s2", Vector2(w - 92, h - 112), 15.0, ""],
		["s3", Vector2(w - 54, h - 132), 15.0, ""],
		["s4", Vector2(w - 16, h - 112), 15.0, ""],
		["s5", Vector2(w - 146, h - 54), 15.0, ""],
		["ult", Vector2(w - 142, h - 98), 15.0, "R"],
		["potion", Vector2(w - 176, h - 22), 13.0, ""],
		["use", Vector2(w - 130, h - 140), 14.0, "E"],
		["swap", Vector2(w - 176, h - 62), 13.0, "ĐỔI"],
		["s6", Vector2(w - 16, h - 152), 13.0, "6"],
		["menu", Vector2(w - 16, 40), 12.0, "II"],
		["inv", Vector2(w - 16, 70), 12.0, "TÚI"],
		["tree", Vector2(w - 16, 100), 12.0, "KN"],
	]

# called from game._input for every touch event
static func event(g, ev: InputEvent) -> void:
	if not (ev is InputEventScreenTouch or ev is InputEventScreenDrag):
		return
	g.touch_on = true
	g.pad = false
	var view = g.get_viewport_rect().size
	var pos: Vector2 = ev.position
	if ev is InputEventScreenTouch:
		if ev.pressed:
			var b = hit(g, view, pos)
			if b != "":
				g.touch_fingers[ev.index] = b
			elif pos.x < view.x * 0.5 and g.mode == "play":
				g.touch_fingers[ev.index] = "stick"
				g.touch_stick = {"centre": pos, "at": pos}
		else:
			if g.touch_fingers.get(ev.index, "") == "stick":
				g.touch_stick = {}
			g.touch_fingers.erase(ev.index)
	elif g.touch_fingers.get(ev.index, "") == "stick":
		g.touch_stick.at = pos

static func hit(g, view: Vector2, pos: Vector2) -> String:
	if g.mode != "play":
		return ""
	for b in buttons(view):
		if b[0] == "s6" and not g.tree.has("prototype"):
			continue
		if pos.distance_to(b[1]) < b[2] + 6.0:
			return b[0]
	return ""

static func held(g, n: String) -> bool:
	return g.touch_on and g.touch_fingers.values().has(n)

static func move(g) -> Vector2:
	if g.touch_stick.is_empty():
		return Vector2.ZERO
	return ((g.touch_stick.at - g.touch_stick.centre) / STICK_R).limit_length(1.0)

# where the hero aims on a phone: the nearest foe in reach, else along the stick, else the way it faced
static func aim(g) -> Vector2:
	var f = g.foe_near(g.p.pos, 170.0, [])
	if f != null:
		return f.pos
	var mv = move(g)
	if mv.length() > 0.3:
		g.pad_aim = mv.normalized()
	return g.p.pos + g.pad_aim * 60.0

static func draw(g, view: Vector2) -> void:
	if not g.touch_on or g.mode != "play":
		return
	if not g.touch_stick.is_empty():
		var c: Vector2 = g.touch_stick.centre
		g.draw_arc(c, STICK_R, 0.0, TAU, 32, RIM, 1.0)
		g.draw_circle(c + move(g) * STICK_R, 10.0, FACE)
	for b in buttons(view):
		var k: String = b[0]
		if k == "s6" and not g.tree.has("prototype"):
			continue
		var on = held(g, k)
		g.draw_circle(b[1], b[2], Color(1, 1, 1, 0.28) if on else FACE)
		g.draw_arc(b[1], b[2], 0.0, TAU, 28, RIM, 1.0)
		var id = ""
		if k.begins_with("s") and k.length() == 2:
			var i = int(k.substr(1)) - 1
			id = g.bar[i] if i < 5 else g.proto
		elif k == "ult":
			id = g.cur_ult()
		if id != "" and Art.T.has("sk_" + id):
			var tex: Texture2D = Art.T["sk_" + id]
			var ok = g.can_cast(id)
			g.draw_texture(tex, (b[1] - tex.get_size() / 2.0).floor(), Color.WHITE if ok else Color(0.45, 0.45, 0.5))
			if g.p.cds.has(id):
				Txt.ctext(g, b[1] + Vector2(0, -3), str(int(ceil(g.p.cds[id]))), Color.WHITE)
		elif k == "potion":
			g.draw_texture(Art.T["potion"], (b[1] - Vector2(5, 5)).floor())
			Txt.ctext(g, b[1] + Vector2(7, 2), str(g.potions), Color.WHITE)
		elif k == "atk":
			g.draw_line(b[1] + Vector2(-8, 8), b[1] + Vector2(8, -8), RIM, 3.0)
		elif b[3] != "":
			Txt.ctext(g, b[1] + Vector2(0, -3), b[3], RIM)
