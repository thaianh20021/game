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
	"swap": [Vector2(332, 146), 12.0, "Q", KEY_Q],
	# changing element is the main verb after firing: a big button right beside the fire stick
	"el": [Vector2(366, 172), 17.0, "", KEY_TAB],
	"use": [Vector2(338, 212), 13.0, "E", KEY_E],
	"pause": [Vector2(240, 12), 9.0, "II", KEY_ESCAPE],
}

# Where a control really sits, in HUD coordinates: controls keep their distance from the
# nearest screen edge, so on a wide phone they move out to where the thumbs are.
static func at(g, v: Vector2) -> Vector2:
	var o = Vector2(g.hud_edge, g.hud_off.y)
	return v + Vector2(o.x if v.x > 300.0 else (-o.x if v.x < 180.0 else 0.0), o.y if v.y > 100.0 else -o.y)

static func fresh() -> Dictionary:
	return {on = false, mv = Vector2.ZERO, aim = Vector2.ZERO, fire = false, tap = Vector2(240, 135),
		l_id = -1, l_base = Vector2.ZERO, l_pos = Vector2.ZERO, r_id = -1, r_base = Vector2.ZERO, r_pos = Vector2.ZERO, held = {}}

static func handle(g, ev: InputEvent) -> void:
	var t = g.tin
	if ev is InputEventScreenTouch:
		t.on = true
		var pos: Vector2 = ev.position - g.hud_off
		if ev.pressed:
			t.tap = pos
			g.jp["m1"] = true
			if g.state != "play":
				return
			if not g.tut.is_empty() and g.Tutor.SKIP.grow(6.0).has_point(pos):
				return
			for id in BUTTONS:
				var b = BUTTONS[id]
				if pos.distance_to(at(g, b[0])) <= b[1] + 5.0:
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
			t.l_pos = ev.position - g.hud_off
			var d: Vector2 = (t.l_pos - t.l_base) / STICK_R
			t.mv = d.limit_length(1.0) if d.length() > 0.18 else Vector2.ZERO
		elif ev.index == t.r_id:
			t.r_pos = ev.position - g.hud_off
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
	var lb: Vector2 = t.l_base if t.l_id != -1 else at(g, Vector2(64, 204))
	var lp: Vector2 = lb + t.mv * STICK_R
	ci.draw_circle(lb, STICK_R, Color(1, 1, 1, 0.07))
	ci.draw_arc(lb, STICK_R, 0.0, TAU, 24, faint, 1.0)
	ci.draw_circle(lp, 10.0, Color(1, 1, 1, 0.3))
	var rb: Vector2 = t.r_base if t.r_id != -1 else at(g, Vector2(412, 208))
	var rp: Vector2 = rb + t.aim * STICK_R
	ci.draw_circle(rb, STICK_R, Color(1.0, 0.4, 0.4, 0.09 if not t.fire else 0.16))
	ci.draw_arc(rb, STICK_R, 0.0, TAU, 24, Color(1.0, 0.6, 0.6, 0.3), 1.0)
	ci.draw_circle(rp, 10.0, Color(1.0, 0.6, 0.6, 0.4))
	if t.r_id == -1:
		Px.ctext(ci, rb + Vector2(0, -3), "FIRE", Color(1, 1, 1, 0.45), 1, false)
	for id in BUTTONS:
		var b = BUTTONS[id]
		var down = t.held.values().has(id)
		var bp: Vector2 = at(g, b[0])
		if id == "el" and g.p.has("els"):
			# shows what you paint with now, how much of it is left, and what comes next
			var cur: String = g.p.els[g.p.eli]
			var nxt: String = g.p.els[(int(g.p.eli) + 1) % g.p.els.size()]
			var ec: Color = g.D.EL_COL[cur]
			var left = float(g.p.sat[g.p.eli]) if g.p.has("sat") else 1.0
			ci.draw_circle(bp, b[1], Color(ec.r, ec.g, ec.b, 0.38 if down else 0.2))
			ci.draw_arc(bp, b[1], 0.0, TAU, 24, Color(1, 1, 1, 0.25), 1.0)
			ci.draw_arc(bp, b[1], -PI / 2.0, -PI / 2.0 + TAU * left, 24, Color(ec.r, ec.g, ec.b, 0.95), 2.0)
			var it: Texture2D = g.Art.T["ic_" + cur]
			ci.draw_set_transform(bp + Vector2(-7, -8), 0.0, Vector2(2, 2))
			ci.draw_texture(it, Vector2.ZERO)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			ci.draw_texture(g.Art.T["ic_" + nxt], bp + Vector2(8, 6), Color(1, 1, 1, 0.75))
			continue
		ci.draw_circle(bp, b[1], Color(1, 1, 1, 0.3 if down else 0.1))
		ci.draw_arc(bp, b[1], 0.0, TAU, 18, Color(1, 1, 1, 0.35), 1.0)
		Px.ctext(ci, bp + Vector2(0, -3), b[2], Color(1, 1, 1, 0.7), 1, false)
