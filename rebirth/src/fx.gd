extends RefCounted
# Purely visual effects: element trails, muzzle flashes, hit sparks, status overlays on
# foes, one distinct burst per reaction, boss auras and the look of fused gear.
# Nothing in here changes the simulation.

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")

static func part(g, pos: Vector2, vel: Vector2, life: float, col: Color, size: int = 1, grav: float = 0.0) -> void:
	if g.parts.size() < 800:
		g.parts.append({pos = pos, vel = vel, life = life, max = life, col = col, size = size, grav = grav})

static func rv(g, r: float) -> Vector2:
	return Vector2(g.rng.randf_range(-r, r), g.rng.randf_range(-r, r))

# ---- projectiles -----------------------------------------------------------------

static func trail(g, b: Dictionary) -> void:
	var col: Color = D.EL_COL[b.el]
	part(g, b.pos, Vector2.ZERO, 0.18, col)
	if g.rng.randf() > 0.35:
		return
	match b.el:
		"fire": part(g, b.pos + rv(g, 1.5), Vector2(g.rng.randf_range(-8, 8), -30), 0.35, Color("ffd24a"))
		"ice": part(g, b.pos + rv(g, 3.0), Vector2.ZERO, 0.3, Color.WHITE)
		"bolt": part(g, b.pos + rv(g, 4.0), rv(g, 20.0), 0.12, Color("fff2ae"), 2)
		"tox": part(g, b.pos, Vector2(0, 10), 0.4, Color("4fae4c"), 1, 90.0)

static func tail(ci: CanvasItem, b: Dictionary, col: Color) -> void:
	if b.vel.length_squared() < 1.0:
		return
	var back: Vector2 = -b.vel.normalized()
	ci.draw_line(b.pos + back * (9.0 if b.team == 0 else 6.0), b.pos, Color(col.r, col.g, col.b, 0.3), 3.0)
	ci.draw_line(b.pos + back * 5.0, b.pos, Color(col.r, col.g, col.b, 0.6), 1.0)

static func muzzle(g, origin: Vector2, dir: Vector2, el: String) -> void:
	var col: Color = D.EL_COL[el]
	for i in 4:
		part(g, origin, dir.rotated(g.rng.randf_range(-0.5, 0.5)) * g.rng.randf_range(60.0, 130.0), 0.12, Color.WHITE if i == 0 else col, 1 + i % 2)
	match el:
		"fire":
			for i in 2:
				part(g, origin, dir.rotated(g.rng.randf_range(-0.3, 0.3)) * 50.0 + Vector2(0, -20), 0.3, Color("f2812f"), 2)
		"ice":
			part(g, origin + dir * 4.0, Vector2.ZERO, 0.2, Color("c6f4ff"), 2)
		"bolt":
			g.bolts.append({a = origin, b = origin + dir.rotated(g.rng.randf_range(-0.6, 0.6)) * 11.0, col = col, t = 0.07, straight = false})
		"tox":
			part(g, origin, dir * 30.0, 0.4, Color("a6e84e"), 2, 160.0)

static func hit(g, pos: Vector2, el: String) -> void:
	match el:
		"fire":
			for i in 3:
				part(g, pos + rv(g, 3.0), Vector2(g.rng.randf_range(-15, 15), -45), 0.4, Color("ffb347") if i else Color("fff2ae"))
		"ice":
			for i in 5:
				part(g, pos, Vector2.from_angle(i * TAU / 5.0 + g.rng.randf()) * 90.0, 0.16, Color.WHITE if i % 2 else Color("7adfff"), 2)
		"bolt":
			g.bolts.append({a = pos, b = pos + rv(g, 12.0), col = D.EL_COL["bolt"], t = 0.08, straight = false})
		"tox":
			for i in 3:
				part(g, pos + rv(g, 4.0), Vector2(0, -14), 0.5, Color("a6e84e"), 2, -30.0)

# ---- status effects worn by a foe ------------------------------------------------

static func status(g, ci: CanvasItem, e: Dictionary, base: Vector2, topy: float) -> void:
	if e.st.is_empty() and e.vuln <= 0.0:
		return
	var t: float = g.time
	var c: Vector2 = g.center(e)
	var w: float = e.h2 * 0.8
	if e.st.has("fire"):
		for i in 3:
			var x = e.pos.x + (i - 1) * w * 0.6
			var fh = 3.0 + 2.0 * sin(t * 13.0 + i * 2.1 + e.uid)
			ci.draw_rect(Rect2(x - 1.0, topy + 2.0 - fh, 2, fh), Color("f2812f"))
			ci.draw_rect(Rect2(x - 1.0, topy + 2.0 - fh * 0.5, 1, fh * 0.5), Color("fff2ae"))
		if g.rng.randf() < 0.15:
			part(g, Vector2(e.pos.x + g.rng.randf_range(-w, w), topy), Vector2(0, -28), 0.4, Color("ffd24a"))
	if e.st.has("ice"):
		for i in 4:
			var q = c + Vector2.from_angle(t * 1.4 + i * TAU / 4.0) * Vector2(w + 4.0, w * 0.6 + 3.0)
			ci.draw_rect(Rect2(q.round() - Vector2(1, 0), Vector2(3, 1)), Color("c6f4ff"))
			ci.draw_rect(Rect2(q.round() - Vector2(0, 1), Vector2(1, 3)), Color.WHITE)
	if e.st.has("bolt"):
		for i in 2:
			var a = c + rv(g, w)
			var pts = PackedVector2Array([a, a + rv(g, 5.0), a + rv(g, 7.0)])
			ci.draw_polyline(pts, Color("ffe45c"), 1.0)
	if e.st.has("tox"):
		if g.rng.randf() < 0.12 + 0.04 * e.tox_n:
			part(g, c + rv(g, w), Vector2(0, -10), 0.6, Color("a6e84e"), 1 + e.tox_n / 3, -25.0)
		ci.draw_rect(Rect2(e.pos.x - w, base.y - 1.0, w * 2.0, 1), Color(0.3, 0.68, 0.3, 0.6))
	if e.vuln > 0.0:
		ci.draw_arc(c, e.h2 + 4.0 + sin(t * 8.0), 0.0, TAU, 14, Color(0.43, 0.88, 0.69, 0.7), 1.0)
	g.Chem.draw_status(g, ci, e)

# ---- reactions: one signature burst each -----------------------------------------

static func react(g, c: Vector2, key: String) -> void:
	match key:
		"fire+ice":
			for i in 16:
				part(g, c + rv(g, 8.0), Vector2(g.rng.randf_range(-20, 20), -40), 0.8, Color(1, 1, 1, 0.8), 2, -40.0)
			g.rings.append({pos = c, r = 22.0, t = 0.0, col = Color.WHITE})
		"fire+tox":
			for i in 14:
				part(g, c, Vector2.from_angle(g.rng.randf() * TAU) * g.rng.randf_range(60, 160), 0.45, Color("ff8a3a") if i % 2 else Color("a6e84e"), 2, 120.0)
			g.rings.append({pos = c, r = 54.0, t = 0.0, col = Color("ffd24a")})
		"bolt+fire":
			for i in 6:
				var a = i * TAU / 6.0 + g.rng.randf() * 0.4
				g.bolts.append({a = c, b = c + Vector2.from_angle(a) * 34.0, col = Color("ff7ad9"), t = 0.18, straight = false})
			g.rings.append({pos = c, r = 46.0, t = 0.0, col = Color("ffe45c")})
		"bolt+ice":
			for i in 12:
				part(g, c, Vector2.from_angle(i * TAU / 12.0) * 190.0, 0.22, Color.WHITE if i % 2 else Color("b8c8ff"), 2)
			g.rings.append({pos = c, r = 28.0, t = 0.0, col = Color("7adfff")})
		"ice+tox":
			for i in 8:
				var q = c + Vector2.from_angle(i * TAU / 8.0) * 16.0
				part(g, q, Vector2.ZERO, 0.9, Color("6fe0b0"), 2)
				part(g, q + Vector2(0, -2), Vector2.ZERO, 0.9, Color.WHITE)
			g.rings.append({pos = c, r = 20.0, t = 0.0, col = Color("6fe0b0")})
		"bolt+tox":
			for i in 3:
				g.after(i * 0.1, func(): g.rings.append({pos = c, r = 30.0 + i * 24.0, t = 0.0, col = Color("d4f04a")}))
			for i in 10:
				part(g, c + rv(g, 30.0), Vector2(0, -12), 0.7, Color("a6e84e"), 2, -20.0)

# ---- bosses ----------------------------------------------------------------------

static func enrage(g, e: Dictionary) -> void:
	var c: Vector2 = g.center(e)
	g.label(c + Vector2(0, -e.h2 - 16.0), "ENRAGED", Color("ff4a5e"), true)
	g.rings.append({pos = c, r = 60.0, t = 0.0, col = Color("ff4a5e")})
	g.rings.append({pos = c, r = 90.0, t = 0.0, col = Color("ffd24a")})
	g.flash(c, 220.0, Color("ff4a5e"), 0.5)
	g.burst(c, 30, Color("ff4a5e"), 150.0, 0.7)
	g.shake_add(8.0)
	g.hitstop = maxf(g.hitstop, 0.12)
	Sfx.play("roar", 0.8)

static func boss_fx(g, ci: CanvasItem, e: Dictionary) -> void:
	var t: float = g.time
	var col: Color = D.EL_COL[e.el] if e.el != "" else Color("d9d4c7")
	var foot: Vector2 = e.pos + Vector2(0, e.r)
	ci.draw_set_transform(foot, 0.0, Vector2(1.0, 0.45))
	ci.draw_arc(Vector2.ZERO, e.r * 2.0 + sin(t * 3.0) * 2.0, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.45), 1.0)
	if e.get("raged", false):
		ci.draw_arc(Vector2.ZERO, e.r * 2.6 + sin(t * 9.0) * 3.0, 0.0, TAU, 24, Color(1.0, 0.3, 0.37, 0.7), 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if g.rng.randf() < (0.5 if e.get("raged", false) else 0.2):
		part(g, foot + Vector2(g.rng.randf_range(-e.r * 2.0, e.r * 2.0), g.rng.randf_range(-3, 3)), Vector2(0, -34),
			0.7, Color("ff4a5e") if (e.get("raged", false) and g.rng.randf() < 0.5) else col, 1 + g.rng.randi() % 2)
	if e.cast_t > 0.0:
		var c: Vector2 = g.center(e)
		for i in 2:
			var from = c + Vector2.from_angle(g.rng.randf() * TAU) * 40.0
			part(g, from, (c - from) * 4.0, 0.22, col, 2)

# ---- fused gear ------------------------------------------------------------------

static func weapon_aura(g, ci: CanvasItem, hand: Vector2, w: Dictionary) -> void:
	var el2 = w.get("el2", "")
	if el2 == "":
		return
	var t: float = g.time
	for i in 2:
		var q = hand + Vector2.from_angle(t * 5.0 + i * PI) * Vector2(9.0, 4.0) + g.p.aim * 7.0
		ci.draw_rect(Rect2(q.round(), Vector2(2, 2)), D.EL_COL[w.el if i == 0 else el2])
		ci.draw_rect(Rect2(q.round(), Vector2(1, 1)), Color.WHITE)

static func fuse_aura(g, ci: CanvasItem, pl: Dictionary) -> void:
	if pl.look.k != "fuse":
		return
	var t: float = g.time
	var foot: Vector2 = pl.pos + Vector2(0, pl.r)
	for i in 3:
		var a = t * 2.2 + i * TAU / 3.0
		var q = foot + Vector2(cos(a) * 9.0, sin(a) * 3.0 - 1.0)
		ci.draw_rect(Rect2(q.round(), Vector2(1, 1)), Color("ffd24a") if sin(a) > 0.0 else Color(1.0, 0.82, 0.3, 0.45))
	if g.rng.randf() < 0.06:
		part(g, pl.pos + Vector2(g.rng.randf_range(-5, 5), -4), Vector2(0, -22), 0.5, Color("ffd24a"))

# ---- the release of a charged dash -------------------------------------------------
# Drawn from the two elements that made the charge: each has its own mark (flames, spikes,
# zigzags, bubbles...), and they alternate along the shape the weapon gives the release.
const INF_T = 0.5

static func infuse(g, ci: CanvasItem, q: Dictionary) -> void:
	var k: float = clampf(q.t / INF_T, 0.0, 1.0)
	var ease = 1.0 - (1.0 - k) * (1.0 - k)
	var fade = 1.0 - k
	var ca: Color = D.EL_COL[q.a] if q.a != "" else q.col
	var cb: Color = D.EL_COL[q.b] if q.b != "" else Color.WHITE
	var pts = []   # [position, normal]
	match q.kind:
		"ring":
			var rr: float = q.r * (0.35 + 0.65 * ease)
			ci.draw_arc(q.pos, rr, 0.0, TAU, 32, Color(ca.r, ca.g, ca.b, 0.85 * fade), 3.0)
			ci.draw_arc(q.pos, rr - 3.0, 0.0, TAU, 32, Color(cb.r, cb.g, cb.b, 0.7 * fade), 2.0)
			ci.draw_arc(q.pos, rr + 2.0, 0.0, TAU, 32, Color(1, 1, 1, 0.8 * fade), 1.0)
			var cnt = 12 + 2 * int(q.n)
			for i in cnt:
				var d = Vector2.from_angle(q.ang + TAU * i / cnt + k * 0.6)
				pts.append([q.pos + d * rr, d])
		"lance":
			var dir = Vector2.from_angle(q.ang)
			var far: Vector2 = q.pos + dir * q.r
			var w = (3.0 + 2.0 * q.n) * fade
			ci.draw_line(q.pos, far, Color(ca.r, ca.g, ca.b, 0.8 * fade), w + 3.0)
			ci.draw_line(q.pos, far, Color(cb.r, cb.g, cb.b, 0.9 * fade), w)
			ci.draw_line(q.pos, far, Color(1, 1, 1, fade), 1.0)
			var perp = dir.orthogonal()
			var cnt = int(q.r / 14.0)
			for i in cnt:
				var side = 1.0 if i % 2 == 0 else -1.0
				pts.append([q.pos + dir * (10.0 + i * 14.0) + perp * side * (3.0 + 6.0 * ease), perp * side])
		_:
			var half = 0.22 * int(q.n) + 0.15
			var rr: float = q.r * (0.4 + 1.2 * ease)
			ci.draw_arc(q.pos, rr, q.ang - half, q.ang + half, 12, Color(ca.r, ca.g, ca.b, 0.85 * fade), 3.0)
			ci.draw_arc(q.pos, rr - 3.0, q.ang - half, q.ang + half, 12, Color(cb.r, cb.g, cb.b, 0.8 * fade), 2.0)
			var cnt = 5 + 2 * int(q.n)
			for i in cnt:
				var d = Vector2.from_angle(q.ang - half + 2.0 * half * i / (cnt - 1))
				pts.append([q.pos + d * rr, d])
	var s = 7.0 + 2.0 * q.n
	for i in pts.size():
		mark(g, ci, q.a if i % 2 == 0 else q.b, pts[i][0], pts[i][1], k, s, i)

# One element's mark at a point, pointing along nrm. k is 0..1 through the effect.
static func mark(g, ci: CanvasItem, el: String, at: Vector2, nrm: Vector2, k: float, s: float, i: int) -> void:
	var fade = 1.0 - k
	if el == "x":
		var wild = ["fire", "ice", "bolt", "tox", "stone", "wind", "light", "void", "water", "leaf", "metal"]
		el = wild[(i + int(g.time * 10.0)) % wild.size()]
	var c: Color = D.EL_COL[el] if el != "" else Color.WHITE
	c.a = fade
	var white = Color(1, 1, 1, fade)
	var perp = nrm.orthogonal()
	var flick = sin(g.time * 30.0 + i * 1.7)
	match el:
		"fire":
			var tip = at + nrm * s * (1.1 + 0.3 * flick) + perp * flick * 2.0
			shape(ci, [at - perp * 3.0, tip, at + perp * 3.0], c)
			shape(ci, [at - perp * 1.5, at + nrm * s * 0.6, at + perp * 1.5], Color(1.0, 0.9, 0.4, fade))
		"ice":
			shape(ci, [at - perp * 1.5, at + nrm * s * 1.5, at + perp * 1.5], c)
			ci.draw_line(at, at + nrm * s * 1.3, white, 1.0)
			ci.draw_line(at + nrm * s * 0.5 - perp * 3.0, at + nrm * s * 0.5 + perp * 3.0, white, 1.0)
		"bolt":
			var pl = PackedVector2Array([at])
			for j in 4:
				var jit = sin(i * 12.9 + j * 78.2 + floor(g.time * 20.0) * 3.1) * 3.5
				pl.append(at + nrm * s * 0.4 * (j + 1) + perp * jit)
			ci.draw_polyline(pl, c, 2.0)
			ci.draw_polyline(pl, white, 1.0)
		"tox":
			ci.draw_circle(at + nrm * s * k, 2.5 * fade + 1.0, c)
			ci.draw_circle(at + nrm * s * (0.4 + k) + perp * 3.0, 1.5 * fade + 0.5, c)
			ci.draw_circle(at + nrm * s * k - perp + nrm, 1.0, white)
		"stone", "earth":
			var cc = at + nrm * s * k
			ci.draw_set_transform(cc, k * 4.0 + i, Vector2.ONE)
			ci.draw_rect(Rect2(-3, -3, 6, 6), c)
			ci.draw_rect(Rect2(-3, -3, 3, 2), Color(1, 1, 1, 0.5 * fade))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"wind":
			var a = nrm.angle()
			ci.draw_arc(at - nrm * s, s * 1.2, a - 0.7 + k * 1.2, a + 0.3 + k * 1.2, 8, c, 1.5)
			ci.draw_arc(at - nrm * s, s * 0.8, a - 0.3 + k * 1.6, a + 0.5 + k * 1.6, 8, white, 1.0)
		"light":
			ci.draw_line(at, at + nrm * s * 1.8, c, 2.0)
			ci.draw_line(at, at + nrm * s * 1.8, white, 1.0)
			ci.draw_circle(at, 1.5, white)
		"void":
			var cc = at + nrm * s * (1.0 - k)
			ci.draw_circle(cc, 3.5 * fade + 1.0, Color(0.08, 0.02, 0.14, fade))
			ci.draw_arc(cc, 4.5 * fade + 1.0, 0.0, TAU, 10, c, 1.0)
		"water":
			var a = nrm.angle()
			ci.draw_arc(at - nrm * s * 0.5, s * 0.8, a - 0.9, a + 0.9, 8, c, 2.5)
			ci.draw_arc(at - nrm * s * 0.5, s * 0.8 + 2.0, a - 0.5, a + 0.5, 6, white, 1.0)
			ci.draw_circle(at + nrm * s * (0.6 + k) + perp * 2.0 * flick, 1.0, white)
		"leaf":
			var cc = at + nrm * s * k + perp * flick * 2.0
			shape(ci, [cc - nrm * 4.0, cc + perp * 2.0, cc + nrm * 4.0, cc - perp * 2.0], c)
			ci.draw_line(cc - nrm * 3.0, cc + nrm * 3.0, Color(1, 1, 1, 0.6 * fade), 1.0)
		"wood":
			ci.draw_line(at, at + nrm * s * 1.2, c, 2.0)
			ci.draw_line(at + nrm * s * 0.6, at + nrm * s * 1.0 + perp * 4.0, c, 1.5)
			ci.draw_line(at + nrm * s * 0.4, at + nrm * s * 0.8 - perp * 4.0, c, 1.5)
		"metal":
			ci.draw_line(at - perp * s * 0.7 + nrm * 2.0, at + perp * s * 0.7 + nrm * s * 0.6, c, 2.0)
			ci.draw_line(at - perp * s * 0.7 + nrm * 2.0, at + perp * s * 0.7 + nrm * s * 0.6, white, 1.0)
		"mech":
			var cc = at + nrm * s * 0.5
			ci.draw_set_transform(cc, g.time * 8.0 + i, Vector2.ONE)
			ci.draw_rect(Rect2(-3, -1, 6, 2), c)
			ci.draw_rect(Rect2(-1, -3, 2, 6), c)
			ci.draw_rect(Rect2(-1, -1, 2, 2), white)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_:
			ci.draw_circle(at + nrm * s * k, 2.0, c)

# Three or four points as one flat shape. draw_primitive never triangulates, so a shape squashed
# thin for a frame does not raise an error the way draw_colored_polygon does.
static func shape(ci: CanvasItem, pts: Array, col: Color) -> void:
	var cs = PackedColorArray()
	for i in pts.size():
		cs.append(col)
	ci.draw_primitive(PackedVector2Array(pts), cs, PackedVector2Array())
