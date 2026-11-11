extends RefCounted
# Touch controls: a floating move stick on the left, an aim-and-fire stick on the
# right, and round buttons for everything else. Holding the fire stick near its
# centre auto-aims at the nearest foe; pushing it aims by hand.

const Px = preload("res://src/font.gd")

const STICK_R = 26.0
# id: [centre, radius, label, key pushed into the game's just-pressed set]
const BUTTONS = {
	"dash": [Vector2(458, 150), 14.0, "DASH", KEY_SPACE],
	"s1": [Vector2(430, 124), 13.0, "1", "m2"],
	"s2": [Vector2(398, 112), 13.0, "2", KEY_F],
	"burst": [Vector2(364, 118), 12.0, "R", KEY_R],
	"item": [Vector2(336, 138), 12.0, "C", KEY_C],
	"swap": [Vector2(330, 172), 12.0, "Q", KEY_Q],
	"el": [Vector2(302, 198), 12.0, "EL", KEY_TAB],
	"use": [Vector2(346, 206), 13.0, "E", KEY_E],
	"pause": [Vector2(240, 12), 9.0, "II", KEY_ESCAPE],
}

static func fresh() -> Dictionary:
	return {on = false, mv = Vector2.ZERO, aim = Vector2.ZERO, fire = false, tap = Vector2(240, 135),
		l_id = -1, l_base = Vector2.ZERO, l_pos = Vector2.ZERO, r_id = -1, r_base = Vector2.ZERO, r_pos = Vector2.ZERO, held = {}}

static func handle(g, ev: InputEvent) -> void:
	var t = g.tin
	if ev is InputEventScreenTouch:
		t.on = true
		var pos: Vector2 = ev.position
		if ev.pressed:
			t.tap = pos
			g.jp["m1"] = true
			if g.state != "play":
				return
			for id in BUTTONS:
				var b = BUTTONS[id]
				if pos.distance_to(b[0]) <= b[1] + 3.0:
					g.jp[b[3]] = true
					t.held[ev.index] = id
					return
			if pos.x < 200.0 and t.l_id == -1:
				t.l_id = ev.index
				t.l_base = pos
				t.l_pos = pos
			elif pos.x > 280.0 and t.r_id == -1:
				t.r_id = ev.index
				t.r_base = pos
				t.r_pos = pos
				t.fire = true
		else:
			t.held.erase(ev.index)
			if ev.index == t.l_id:
				t.l_id = -1
				t.mv = Vector2.ZERO
			if ev.index == t.r_id:
				t.r_id = -1
				t.fire = false
				t.aim = Vector2.ZERO
	elif ev is InputEventScreenDrag:
		if ev.index == t.l_id:
			t.l_pos = ev.position
			var d: Vector2 = (t.l_pos - t.l_base) / STICK_R
			t.mv = d.limit_length(1.0) if d.length() > 0.18 else Vector2.ZERO
		elif ev.index == t.r_id:
			t.r_pos = ev.position
			var d: Vector2 = (t.r_pos - t.r_base) / STICK_R
			t.aim = d.limit_length(1.0) if d.length() > 0.35 else Vector2.ZERO

# Direction the player should face this frame, or ZERO to keep the current one.
static func aim_dir(g) -> Vector2:
	var t = g.tin
	if t.aim != Vector2.ZERO:
		return t.aim.normalized()
	var e = g.nearest_enemy(g.pcenter(), 190.0, [])
	if e != null:
		return (g.center(e) - g.pcenter()).normalized()
	if t.mv != Vector2.ZERO:
		return t.mv.normalized()
	return Vector2.ZERO

static func draw(g, ci: CanvasItem) -> void:
	var t = g.tin
	if not t.on or g.state != "play":
		return
	var faint = Color(1, 1, 1, 0.16)
	var lb: Vector2 = t.l_base if t.l_id != -1 else Vector2(64, 204)
	var lp: Vector2 = lb + t.mv * STICK_R
	ci.draw_circle(lb, STICK_R, Color(1, 1, 1, 0.07))
	ci.draw_arc(lb, STICK_R, 0.0, TAU, 24, faint, 1.0)
	ci.draw_circle(lp, 10.0, Color(1, 1, 1, 0.3))
	var rb: Vector2 = t.r_base if t.r_id != -1 else Vector2(412, 208)
	var rp: Vector2 = rb + t.aim * STICK_R
	ci.draw_circle(rb, STICK_R, Color(1.0, 0.4, 0.4, 0.09 if not t.fire else 0.16))
	ci.draw_arc(rb, STICK_R, 0.0, TAU, 24, Color(1.0, 0.6, 0.6, 0.3), 1.0)
	ci.draw_circle(rp, 10.0, Color(1.0, 0.6, 0.6, 0.4))
	if t.r_id == -1:
		Px.ctext(ci, rb + Vector2(0, -3), "FIRE", Color(1, 1, 1, 0.45), 1, false)
	for id in BUTTONS:
		var b = BUTTONS[id]
		var down = t.held.values().has(id)
		ci.draw_circle(b[0], b[1], Color(1, 1, 1, 0.3 if down else 0.1))
		ci.draw_arc(b[0], b[1], 0.0, TAU, 18, Color(1, 1, 1, 0.35), 1.0)
		Px.ctext(ci, b[0] + Vector2(0, -3), b[2], Color(1, 1, 1, 0.7), 1, false)
