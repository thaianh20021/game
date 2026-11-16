extends RefCounted
# One-shot pixel effects for releases, wall slams and release hits.
#
# Nine of these are adapted from pixelfx (https://github.com/patch-gg/pixelfx, MIT License,
# parts of it after Hugo Duprez's Sprite Fusion pixel art VFX, MIT): frost nova, chain lightning,
# geyser, ground slam, hit flash, fire ring, poison cloud, leaf storm and black hole. Blessing,
# hex sigil and summon rise (for weapon mechanics, src/wmods.gd) follow pixelfx's holy/blessing,
# shadow/hex-sigil and spawn/summon-rise the same way. Their
# palettes, beats and shapes are kept; the originals are side views on their own engine, so the
# drawing is rewritten here for a top-down view and Godot's CanvasItem. "radiance" is ours.
#
# An effect is {k, pos, r, t, dur, seed, ang}; g.pfx holds the live ones (LAN guests get the list).

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")

const DUR = {"frost": 0.9, "chain": 0.5, "geyser": 0.8, "slam": 0.7, "hit": 0.3, "fire": 0.8, "poison": 1.1, "leaf": 0.9, "hole": 1.0, "radiance": 0.6, "bless": 0.8, "hex": 0.7, "summon": 0.7}
# which effect an element brings to a release
const OF = {
	"fire": "fire", "ice": "frost", "bolt": "chain", "tox": "poison", "water": "geyser", "stone": "slam", "earth": "slam",
	"leaf": "leaf", "wood": "leaf", "wind": "leaf", "void": "hole", "light": "radiance", "metal": "hit", "mech": "chain",
}
const PAL = {
	"frost": ["151a3d", "212f6b", "2c58aa", "3a8bd8", "62c8f4", "a6ecff", "dcfbff", "ffffff"],
	"fire": ["4a1712", "8a1f17", "c9281f", "f2561d", "ff8a2a", "ffc23d", "ffe26b", "fff3a6", "ffffff"],
	"slam": ["2a1712", "5e2c1c", "a4502a", "e8893a", "ffc764", "fff0b4", "ffffff"],
	"hit": ["14040a", "3a0a14", "6a101c", "a01824", "d42a30", "ff5a50", "ff9a8a"],
	"leaf": ["1a2420", "2e4038", "4a6656", "7a9a84", "b4d0b8", "eef8e8"],
	"poison": ["0e0816", "24123a", "3e2056", "5a3a62", "6a6a3a", "96aa30", "cce040", "f4ffa0"],
	"geyser": ["0c2a4a", "145a8a", "2a8ac8", "5cc0ee", "a8e8ff", "ffffff"],
	"chain": ["1a1040", "3a2a8a", "6a5ae0", "a0b4ff", "fff2ae", "ffffff"],
	"hole": ["0a0614", "24103e", "4a1f7a", "7a3ab8", "b070e8", "e6c8ff"],
	"radiance": ["6a4a10", "c98a1c", "ffd24a", "fff2ae", "ffffff"],
	"bless": ["5a3a08", "a8741a", "e8b23a", "ffd24a", "fff2ae", "ffffff"],
	"hex": ["14061e", "3a0f52", "6a1f8a", "a83ad0", "e07aff", "ffd0ff"],
	"summon": ["102438", "1e4f6e", "3a8fb0", "7ad8e8", "c8f6ff", "ffffff"],
}

static func spawn(g, k: String, pos: Vector2, r: float, ang: float = 0.0) -> void:
	if not DUR.has(k) or g.pfx.size() > 40:
		return
	g.pfx.append({k = k, pos = pos, r = r, t = 0.0, dur = DUR[k], seed = g.rng.randi() % 1000, ang = ang})
	# its own sound, but never the same one twice within a moment
	if g.time - float(g.pfx_snd.get(k, -9.0)) > 0.09:
		g.pfx_snd[k] = g.time
		Sfx.play("fx_" + k, g.rng.randf_range(0.94, 1.06), -6.0 if k == "hit" else -3.0)

# The effect an element brings ("x" picks any).
static func of(g, el: String) -> String:
	if el == "x":
		return DUR.keys()[g.rng.randi() % DUR.size()]
	return OF.get(el, "hit")

static func update(g, dt: float) -> void:
	if g.pfx.is_empty():
		return
	for q in g.pfx:
		q.t += dt
	g.pfx = g.pfx.filter(func(q): return q.t < q.dur)

static func rnd(s: float, i: float) -> float:
	return fposmod(sin(s * 12.9898 + i * 78.233) * 43758.5453, 1.0)

static func c(k: String, i: int, a: float = 1.0) -> Color:
	var p: Array = PAL[k]
	var col = Color(p[clampi(i, 0, p.size() - 1)])
	col.a = clampf(a, 0.0, 1.0)
	return col

static func dot(ci: CanvasItem, at: Vector2, col: Color, s: float = 1.0) -> void:
	ci.draw_rect(Rect2(floorf(at.x), floorf(at.y), s, s), col)

static func draw(g, ci: CanvasItem) -> void:
	for q in g.pfx:
		if not g.on_screen(q.pos, q.r + 30.0):
			continue
		var u: float = clampf(q.t / q.dur, 0.0, 1.0)
		match q.k:
			"frost": frost(g, ci, q, u)
			"chain": chain(g, ci, q, u)
			"geyser": geyser(g, ci, q, u)
			"slam": slam(g, ci, q, u)
			"hit": hit(g, ci, q, u)
			"fire": fire(g, ci, q, u)
			"poison": poison(g, ci, q, u)
			"leaf": leaf(g, ci, q, u)
			"hole": hole(g, ci, q, u)
			"radiance": radiance(g, ci, q, u)
			"bless": bless(g, ci, q, u)
			"hex": hex(g, ci, q, u)
			"summon": summon(g, ci, q, u)

# Frost nova: frost spirals into a spinning snowflake, then a wave blooms three rings of crystals.
static func frost(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var charge = 0.16
	var fade = clampf((1.0 - u) / 0.25, 0.0, 1.0)
	if u < charge + 0.1:
		var l = 3.0 + q.r * 0.22 * minf(1.0, u / charge)
		var spin = u * 14.0
		var a = 1.0 if u < charge else 1.0 - (u - charge) / 0.1
		for i in 6:
			var d = Vector2.from_angle(spin + i * TAU / 6.0)
			ci.draw_line(p, p + d * l, c("frost", 6, a), 1.0)
			ci.draw_line(p, p + d * l * 0.4, c("frost", 7, a), 1.0)
			for s in [-1.0, 1.0]:
				var b = p + d * l * 0.6
				ci.draw_line(b, b + Vector2.from_angle(d.angle() + s * 0.9) * l * 0.35, c("frost", 5, a), 1.0)
	if u < charge:
		return
	var w = clampf((u - charge) / 0.38, 0.0, 1.0)
	var front = q.r * (1.0 - pow(1.0 - w, 3.0))
	ci.draw_arc(p, front, 0.0, TAU, 40, c("frost", 6, (1.0 - w) * 0.9), 2.0)
	# frost on the floor: a sparse white crust behind the wave
	for i in 46:
		var d = rnd(q.seed, i) * q.r
		if d > front:
			continue
		var at = p + Vector2.from_angle(rnd(q.seed, i + 100.0) * TAU) * d
		dot(ci, at, c("frost", 7 if rnd(q.seed, i + 7.0) < 0.3 else 5, fade * 0.8))
	var rings = [[0.3, 6, 10.0, 4.0], [0.6, 9, 7.0, 3.0], [0.92, 12, 4.5, 2.0]]
	for ri in rings.size():
		var rg = rings[ri]
		var rr: float = q.r * rg[0]
		if front < rr:
			continue
		var grow = clampf((front - rr) / (q.r * 0.25), 0.0, 1.0) * fade
		for i in int(rg[1]):
			var a = q.seed + ri * 0.7 + i * TAU / rg[1]
			var d = Vector2.from_angle(a)
			var base = p + d * rr
			var h: float = rg[2] * grow * (0.75 + 0.5 * rnd(q.seed, ri * 20.0 + i))
			if h < 1.0:
				continue
			var wd: float = rg[3]
			var n = d.orthogonal()
			shape(ci, [base - n * wd, base + d * h, base + n * wd, base - d * h * 0.3], c("frost", 4, fade))
			shape(ci, [base - n * wd, base + d * h, base - d * h * 0.3], c("frost", 6, fade))
			dot(ci, base + d * h, c("frost", 7, fade))

# Chain lightning: the bolt hops from point to point; the links re-strike every other frame.
static func chain(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var n = 6
	var strike = floorf(q.t * 15.0)
	var prev = p
	for i in n:
		var t0 = i * 0.07
		if u < t0:
			break
		var at = p + Vector2.from_angle(q.seed + i * 2.4) * q.r * (0.45 + 0.55 * rnd(q.seed, i))
		var live = clampf(1.0 - (u - t0) / 0.6, 0.0, 1.0)
		if live > 0.0:
			var pl = PackedVector2Array([prev])
			var dv = at - prev
			var nrm = dv.orthogonal().normalized()
			for j in range(1, 6):
				pl.append(prev + dv * j / 6.0 + nrm * (rnd(q.seed + strike, i * 9.0 + j) - 0.5) * 9.0)
			pl.append(at)
			ci.draw_polyline(pl, c("chain", 2, live), 3.0)
			ci.draw_polyline(pl, c("chain", 4, live), 1.0)
			# each point flashes and grounds itself
			var fl = clampf(1.0 - (u - t0) / 0.2, 0.0, 1.0)
			ci.draw_circle(at, 2.0 + 4.0 * fl, c("chain", 5, fl))
			for j in 4:
				var sd = Vector2.from_angle(rnd(q.seed + strike, i * 5.0 + j) * TAU)
				ci.draw_line(at, at + sd * (3.0 + 5.0 * rnd(q.seed, j + strike)), c("chain", 3, live), 1.0)
		prev = at

# Geyser: a white column with a churning foam head; it rains back down in drops.
static func geyser(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var up = clampf(u / 0.25, 0.0, 1.0)
	var down = clampf((u - 0.55) / 0.45, 0.0, 1.0)
	var rad = q.r * 0.38 * (1.0 - pow(1.0 - up, 3.0)) * (1.0 - down)
	if rad > 1.0:
		ci.draw_circle(p, rad, c("geyser", 2, 0.85))
		ci.draw_circle(p, rad * 0.78, c("geyser", 4, 0.9))
		ci.draw_circle(p, rad * 0.5, c("geyser", 5))
		# strands running through the column
		for i in 5:
			var a = q.seed + i * TAU / 5.0 + q.t * 3.0
			ci.draw_line(p + Vector2.from_angle(a) * rad * 0.2, p + Vector2.from_angle(a + 0.5) * rad * 0.9, c("geyser", 3, 0.8), 1.0)
		# the foam head: bubbles churning round the rim
		for i in 14:
			var a = i * TAU / 14.0 + sin(q.t * 20.0 + i) * 0.15
			ci.draw_circle(p + Vector2.from_angle(a) * rad, 1.5 + rnd(q.seed + floorf(q.t * 12.0), i) * 2.0, c("geyser", 5))
	# drops: thrown out, hanging a moment, landing in rings
	for i in 16:
		var a = rnd(q.seed, i) * TAU
		var far = q.r * (0.5 + 0.5 * rnd(q.seed, i + 30.0))
		var t0 = 0.1 + 0.2 * rnd(q.seed, i + 60.0)
		var k = (u - t0) / 0.5
		if k < 0.0:
			continue
		var land = p + Vector2.from_angle(a) * far
		if k < 1.0:
			var at = p.lerp(land, k) + Vector2(0, -sin(k * PI) * 14.0)
			dot(ci, at, c("geyser", 5), 2.0)
			dot(ci, at + Vector2(0, 2), c("geyser", 3))
		else:
			var s = clampf((k - 1.0) / 0.5, 0.0, 1.0)
			ci.draw_arc(land, 1.0 + 5.0 * s, 0.0, TAU, 10, c("geyser", 4, 1.0 - s), 1.0)

# Ground slam: the floor flashes and cracks, two crescent shock waves race out, rocks erupt.
static func slam(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var fade = clampf((1.0 - u) / 0.3, 0.0, 1.0)
	if u < 0.08:
		ci.draw_circle(p, q.r * 0.35, c("slam", 6, 1.0 - u / 0.08))
	# cracks
	var reach = clampf(u / 0.15, 0.0, 1.0)
	for i in 7:
		var a = q.seed + i * TAU / 7.0 + rnd(q.seed, i) * 0.5
		var ln = q.r * (0.45 + 0.5 * rnd(q.seed, i + 9.0)) * reach
		var pl = PackedVector2Array([p])
		for j in range(1, 5):
			pl.append(p + Vector2.from_angle(a + (rnd(q.seed, i * 7.0 + j) - 0.5) * 0.5) * ln * j / 4.0)
		ci.draw_polyline(pl, c("slam", 0, fade), 2.0)
		ci.draw_polyline(pl, c("slam", 3, fade * (1.0 - u)), 1.0)
	# two crescents, ahead and behind
	var wv = 1.0 - pow(1.0 - clampf(u / 0.45, 0.0, 1.0), 2.0)
	for s in [0.0, PI]:
		ci.draw_arc(p, q.r * wv, q.ang + s - 0.9, q.ang + s + 0.9, 14, c("slam", 5, (1.0 - wv) * 0.9), 2.0)
		ci.draw_arc(p, q.r * wv - 3.0, q.ang + s - 0.7, q.ang + s + 0.7, 12, c("slam", 3, (1.0 - wv) * 0.7), 1.0)
	# dust rolling out
	for i in 10:
		var a = i * TAU / 10.0 + q.seed
		var at = p + Vector2.from_angle(a) * q.r * (0.3 + 0.6 * wv)
		ci.draw_circle(at, 2.0 + 4.0 * wv, c("slam", 2 if i % 2 == 0 else 1, 0.5 * fade))
	# rocks erupt, bounce and settle
	for i in 9:
		var a = rnd(q.seed, i + 40.0) * TAU
		var far = q.r * (0.3 + 0.6 * rnd(q.seed, i + 50.0))
		var k = clampf(u / 0.6, 0.0, 1.0)
		var hop = absf(sin(k * PI * 2.0)) * 10.0 * (1.0 - k)
		var at = p + Vector2.from_angle(a) * far * (1.0 - pow(1.0 - k, 2.0)) + Vector2(0, -hop)
		var sz = 2.0 + floorf(rnd(q.seed, i + 70.0) * 2.0)
		dot(ci, at, c("slam", 2, fade), sz)
		dot(ci, at, c("slam", 4, fade))

# Hit flash: a hot burst, and comic hit lines that jab in and are gone.
static func hit(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var sc = maxf(0.6, q.r / 16.0)
	if u < 0.3:
		var k = 0.0 if u < 0.15 else 1.0
		var big = 1.0 if u < 0.15 else 1.3
		for i in 8:
			var d = Vector2.from_angle(i * TAU / 8.0 + 0.2)
			var l = (4.0 if i % 2 else 9.0) * big * sc
			ci.draw_line(p + d * l * 0.45 * k, p + d * l, Color.WHITE if k == 0.0 else c("hit", 6), 1.0 + (1.0 - k))
		if k == 0.0:
			ci.draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Color.WHITE)
	for i in 7:
		var t0 = rnd(q.seed, i) * 0.12
		var w = (u - t0) / 0.55
		if w < 0.0 or w >= 1.0:
			continue
		var a = -PI - 0.3 + ((i + 0.25 + 0.5 * rnd(q.seed, i + 3.0)) / 7.0) * (PI + 0.6)
		var d = Vector2.from_angle(a)
		var d0 = ((15.0 + 4.0 * rnd(q.seed, i + 5.0)) - 6.0 * (1.0 - pow(1.0 - w, 3.0))) * sc
		var l = (6.0 + 3.0 * rnd(q.seed, i + 8.0)) * (1.0 - w) * sc
		if l < 1.0:
			continue
		var n = d.orthogonal() * (2.8 - 1.6 * w) / 2.0
		var tip = p + d * d0
		var fat = p + d * (d0 + l)
		shape(ci, [tip - d, fat + n * 1.5 + d, fat - n * 1.5 + d], c("hit", 3))
		shape(ci, [tip, fat + n, fat - n], Color.WHITE if w < 0.5 else c("hit", 6))

# Fire ring: a white flash, then flames race outward in a ring and burn down behind it.
static func fire(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	if u < 0.1:
		ci.draw_circle(p, q.r * 0.3 * (1.0 - u / 0.1) + 2.0, c("fire", 8, 1.0 - u / 0.1))
	var w = clampf(u / 0.55, 0.0, 1.0)
	var front = q.r * (1.0 - pow(1.0 - w, 2.0))
	var fade = clampf((1.0 - u) / 0.35, 0.0, 1.0)
	# the smouldering scorch
	ci.draw_arc(p, front * 0.9, 0.0, TAU, 36, c("fire", 0, 0.5 * fade), 3.0)
	for i in 30:
		var at = p + Vector2.from_angle(rnd(q.seed, i) * TAU) * front * (0.5 + 0.45 * rnd(q.seed, i + 20.0))
		dot(ci, at, c("fire", 1 if i % 3 else 2, 0.7 * fade))
	# the flames: flaring as the front passes, burning down behind it
	var n = 22
	for i in n:
		var a = q.seed + i * TAU / n
		var d = Vector2.from_angle(a)
		var flick = 0.7 + 0.3 * sin(q.t * 38.0 + i * 2.3)
		var h = (9.0 * (1.0 - w) + 4.0) * flick * fade
		if h < 1.0:
			continue
		var base = p + d * front
		var nrm = d.orthogonal()
		var tip = base + d * h * 0.4 + Vector2(0, -h)
		shape(ci, [base - nrm * 3.0, tip, base + nrm * 3.0], c("fire", 3 if w > 0.6 else 4, fade))
		shape(ci, [base - nrm * 1.5, base.lerp(tip, 0.65), base + nrm * 1.5], c("fire", 6 if w < 0.5 else 5, fade))
		if w < 0.35:
			dot(ci, base.lerp(tip, 0.3), c("fire", 8, fade))
	# sparks
	for i in 10:
		var a = rnd(q.seed, i + 60.0) * TAU
		var at = p + Vector2.from_angle(a) * front * (0.8 + 0.5 * u) + Vector2(0, -22.0 * u * rnd(q.seed, i + 80.0))
		dot(ci, at, c("fire", 7, fade))

# Poison cloud: ragged sheets of gas lit yellow-green from within, fading to violet.
static func poison(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var w = 1.0 - pow(1.0 - clampf(u / 0.5, 0.0, 1.0), 2.0)
	var fade = clampf((1.0 - u) / 0.4, 0.0, 1.0)
	for i in 11:
		# tongues that creep out and curl over at their tips
		var a = q.seed + i * TAU / 11.0 + sin(q.t * 2.0 + i) * 0.25
		var d = q.r * w * (0.35 + 0.6 * rnd(q.seed, i))
		var at = p + Vector2.from_angle(a + w * 0.5) * d
		var rad = 5.0 + 5.0 * rnd(q.seed, i + 10.0)
		ci.draw_circle(at, rad + 2.0, c("poison", 2, 0.35 * fade))
		ci.draw_circle(at, rad, c("poison", 4, 0.45 * fade))
		ci.draw_circle(at + Vector2(-1, -1), rad * 0.55, c("poison", 5, 0.55 * fade))
	ci.draw_circle(p, q.r * 0.3 * w, c("poison", 6, 0.3 * fade))
	# ragged edge: a dither of single pixels
	for i in 40:
		var at = p + Vector2.from_angle(rnd(q.seed, i + 30.0) * TAU) * q.r * w * (0.6 + 0.45 * rnd(q.seed, i + 50.0))
		if (int(at.x) + int(at.y)) % 2 == 0:
			dot(ci, at, c("poison", 5 if i % 4 else 7, 0.8 * fade))
	# bubbles swell and pop
	for i in 6:
		var k = fposmod(q.t * 1.6 + rnd(q.seed, i + 70.0), 1.0)
		var at = p + Vector2.from_angle(rnd(q.seed, i + 90.0) * TAU) * q.r * w * 0.6 * rnd(q.seed, i + 95.0)
		if k < 0.8:
			ci.draw_arc(at, 1.0 + 3.0 * k, 0.0, TAU, 8, c("poison", 7, fade), 1.0)
		else:
			for j in 4:
				dot(ci, at + Vector2.from_angle(j * TAU / 4.0 + 0.7) * 5.0, c("poison", 6, fade))

# Leaf storm: leaves tumble up a spiral, turning and flipping, wrapped in bright bands of wind.
static func leaf(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var fade = clampf((1.0 - u) / 0.3, 0.0, 1.0) * clampf(u / 0.1, 0.0, 1.0)
	for i in 3:
		var a = q.t * 7.0 + i * TAU / 3.0
		var rr = q.r * (0.45 + 0.2 * i)
		ci.draw_arc(p, rr, a, a + 1.5, 12, c("leaf", 5, 0.7 * fade), 1.0)
		ci.draw_arc(p, rr - 2.0, a + 0.3, a + 1.1, 8, c("leaf", 4, 0.5 * fade), 1.0)
	for i in 18:
		var ph = rnd(q.seed, i)
		var a = q.seed + ph * TAU + q.t * (5.0 + 3.0 * rnd(q.seed, i + 5.0))
		var rr = q.r * (0.25 + 0.75 * fposmod(ph + u * 0.8, 1.0))
		var at = p + Vector2.from_angle(a) * rr + Vector2(0, -6.0 * u)
		var turn = q.t * 9.0 + i
		var flip = cos(q.t * 13.0 + i * 1.7)
		if absf(flip) < 0.3:
			flip = 0.3 if flip >= 0.0 else -0.3
		var d = Vector2.from_angle(turn)
		var n = d.orthogonal() * 2.0 * flip
		shape(ci, [at - d * 3.5, at + n, at + d * 3.5, at - n], c("leaf", 3 if flip < 0.0 else 4, fade))
		ci.draw_line(at - d * 2.5, at + d * 2.5, c("leaf", 5, fade * 0.8), 1.0)

# Black hole: banded rings turn round a black disc; debris spirals in, stretches and is swallowed.
static func hole(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var open = clampf(u / 0.15, 0.0, 1.0) * clampf((1.0 - u) / 0.15, 0.0, 1.0)
	var core = q.r * 0.28 * open
	for i in 4:
		var rr = core + 3.0 + i * 3.5
		var a = q.t * (5.0 - i) + i
		ci.draw_arc(p, rr, a, a + 3.6, 20, c("hole", 4 - i if i < 3 else 1, 0.9 * open), 2.0)
		ci.draw_arc(p, rr, a + PI + 0.4, a + PI + 2.2, 12, c("hole", 5 - i, 0.7 * open), 1.0)
	ci.draw_circle(p, core, c("hole", 0))
	ci.draw_arc(p, core, 0.0, TAU, 24, c("hole", 5, open), 1.0)
	for i in 16:
		var k = fposmod(u * 1.6 + rnd(q.seed, i), 1.0)
		var rr = q.r * (1.0 - k) + core * k
		var a = rnd(q.seed, i + 20.0) * TAU + k * 5.0
		var at = p + Vector2.from_angle(a) * rr
		var tan = Vector2.from_angle(a + PI / 2.0 + 0.5) * (2.0 + 7.0 * k)
		ci.draw_line(at, at + tan, c("hole", 5 if i % 3 == 0 else 3, open * (0.4 + 0.6 * k)), 1.0)
	if u > 0.85:
		ci.draw_circle(p, q.r * 0.5 * (1.0 - u) / 0.15, c("hole", 5, 0.8))

# Radiance: a cross of light, then a ring of small sparks carried outward.
static func radiance(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var fl = clampf(1.0 - u / 0.5, 0.0, 1.0)
	for i in 8:
		var d = Vector2.from_angle(i * TAU / 8.0 + q.ang)
		var l = q.r * (1.0 if i % 2 == 0 else 0.5) * (0.3 + 0.7 * minf(1.0, u / 0.15))
		ci.draw_line(p, p + d * l, c("radiance", 2, fl), 3.0 if i % 2 == 0 else 1.0)
		ci.draw_line(p, p + d * l * 0.7, c("radiance", 4, fl), 1.0)
	ci.draw_circle(p, 3.0 + 5.0 * fl, c("radiance", 4, fl))
	var w = 1.0 - pow(1.0 - u, 2.0)
	ci.draw_arc(p, q.r * w, 0.0, TAU, 36, c("radiance", 3, (1.0 - u) * 0.8), 1.0)
	for i in 12:
		var at = p + Vector2.from_angle(i * TAU / 12.0 + q.seed) * q.r * w
		var a = 1.0 - u
		ci.draw_line(at - Vector2(2, 0), at + Vector2(3, 0), c("radiance", 3, a), 1.0)
		ci.draw_line(at - Vector2(0, 2), at + Vector2(0, 3), c("radiance", 3, a), 1.0)
		dot(ci, at, c("radiance", 4, a))

# Blessing: a soft cone of light from above, sparkles drifting down through it.
static func bless(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var a = clampf(u / 0.15, 0.0, 1.0) * clampf((1.0 - u) / 0.3, 0.0, 1.0)
	var top = p + Vector2(0, -q.r * 3.0)
	shape(ci, [top + Vector2(-3, 0), top + Vector2(3, 0), p + Vector2(q.r, 0), p + Vector2(-q.r, 0)], c("bless", 3, 0.22 * a))
	shape(ci, [top + Vector2(-1, 0), top + Vector2(1, 0), p + Vector2(q.r * 0.4, 0), p + Vector2(-q.r * 0.4, 0)], c("bless", 4, 0.3 * a))
	for i in 9:
		var k = fposmod(u * 1.5 + rnd(q.seed, i), 1.0)
		var at = top.lerp(p, k) + Vector2((rnd(q.seed, i + 9.0) - 0.5) * q.r * 1.4 * k, 0)
		var tw = 0.5 + 0.5 * sin(g.time * 20.0 + i)
		dot(ci, at, c("bless", 5 if tw > 0.5 else 4, a))
		if tw > 0.8:
			dot(ci, at + Vector2(-1, 0), c("bless", 4, a * 0.6))
			dot(ci, at + Vector2(1, 0), c("bless", 4, a * 0.6))
	ci.draw_arc(p, q.r * (0.6 + 0.4 * u), 0.0, TAU, 20, c("bless", 3, a * 0.8), 1.0)

# Hex sigil: a burning pen traces a circle and a star, it flares white and crumbles into embers.
static func hex(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var draw_k = clampf(u / 0.45, 0.0, 1.0)
	var fade = clampf((1.0 - u) / 0.3, 0.0, 1.0)
	var flare = u > 0.45 and u < 0.55
	var col = Color.WHITE if flare else c("hex", 4, fade)
	ci.draw_arc(p, q.r, -PI / 2.0, -PI / 2.0 + TAU * draw_k, 20, col, 1.0)
	var star = []
	for i in 5:
		star.append(p + Vector2.from_angle(-PI / 2.0 + i * TAU * 2.0 / 5.0) * q.r * 0.85)
	var segs = int(draw_k * 5.0)
	for i in segs:
		ci.draw_line(star[i], star[(i + 1) % 5], c("hex", 3, fade) if not flare else Color.WHITE, 1.0)
	if u < 0.45:
		# the pen
		var pen = p + Vector2.from_angle(-PI / 2.0 + TAU * draw_k) * q.r
		dot(ci, pen, c("hex", 5), 2.0)
	if u > 0.5:
		for i in 8:
			var at = p + Vector2.from_angle(rnd(q.seed, i) * TAU) * q.r * rnd(q.seed, i + 3.0) + Vector2(0, (u - 0.5) * 30.0 * (0.5 + rnd(q.seed, i + 7.0)))
			dot(ci, at, c("hex", 4 if i % 2 else 5, fade))

# Summon rise: a ring opens on the floor, motes spiral up out of it and a flash marks the arrival.
static func summon(g, ci: CanvasItem, q: Dictionary, u: float) -> void:
	var p: Vector2 = q.pos
	var fade = clampf((1.0 - u) / 0.35, 0.0, 1.0)
	var w = 1.0 - pow(1.0 - clampf(u / 0.3, 0.0, 1.0), 2.0)
	ci.draw_arc(p, q.r * w, 0.0, TAU, 20, c("summon", 3, fade), 2.0)
	ci.draw_arc(p, q.r * w - 3.0, 0.0, TAU, 20, c("summon", 2, fade * 0.7), 1.0)
	for i in 10:
		var k = fposmod(u * 1.3 + rnd(q.seed, i), 1.0)
		var ang = rnd(q.seed, i + 4.0) * TAU + k * 6.0
		var at = p + Vector2(cos(ang) * q.r * (1.0 - k) , sin(ang) * q.r * 0.5 * (1.0 - k) - k * 22.0)
		dot(ci, at, c("summon", 4 if i % 2 else 5, fade))
	if u > 0.25 and u < 0.45:
		ci.draw_circle(p + Vector2(0, -16), 5.0 * (1.0 - (u - 0.25) / 0.2), c("summon", 5, 0.9))

# Three or four points as one flat shape. draw_primitive never triangulates, so a shape squashed
# thin for a frame does not raise an error the way draw_colored_polygon does.
static func shape(ci: CanvasItem, pts: Array, col: Color) -> void:
	var cs = PackedColorArray()
	for i in pts.size():
		cs.append(col)
	ci.draw_primitive(PackedVector2Array(pts), cs, PackedVector2Array())
