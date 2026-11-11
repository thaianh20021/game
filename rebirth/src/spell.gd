extends RefCounted
# Recipes: spells written in words before the run, set off by reactions during it.
#
# At the lectern you write up to three recipes: two elements, a shape, a motion and
# optional size words ("fire ice wall push", "xoay set doc hut", "stone wind rain burst
# big"). In a fight nothing has to be pressed: when the two elements of a recipe react
# on a foe, the spell appears there, then that recipe rests for a few seconds.
#   15 elements -> 105 pairs, x 6 shapes x 4 motions x 8 size mixes = 20160 spells.
# Shapes
#   wall    a line across your aim: stops enemy bullets, hurts what touches it
#   vortex  a circle that lasts and grinds
#   wave    a front that rolls away from you and clears bullets
#   rain    strikes falling on an area
#   orbit   three orbs circling you: they hit foes and eat bullets
#   lance   one piercing beam along your aim
# Motions: push (shove away), pull (drag in), hold (pin in place), burst (explode at the end)
# Size words: big (wider), long (lasts), strong (hits harder); each adds to the rest time.
# Every hit also carries the aspects of both elements (chem.gd), and the spell touches the
# room with both (ice bridges pits, fire burns brush, stone fills pits...).

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")
const Px = preload("res://src/font.gd")
const Forge = preload("res://src/forge.gd")
const Chem = preload("res://src/chem.gd")

const SLOTS = 3
const REST = 5.0
const SHAPES = {
	"wall": ["wall", "barrier", "line", "tuong", "rao"],
	"vortex": ["vortex", "whirl", "spiral", "xoay", "loc"],
	"wave": ["wave", "tide", "surge", "song", "lan"],
	"rain": ["rain", "shower", "meteor", "mua", "roi"],
	"orbit": ["orbit", "orb", "ring", "shield", "moon", "quay", "vong", "khien"],
	"lance": ["lance", "beam", "spear", "ray", "tia", "giao", "lao"],
}
const VERBS = {
	"push": ["push", "repel", "blow", "day", "thoi", "hat"],
	"pull": ["pull", "drag", "suck", "hut", "keo"],
	"hold": ["hold", "root", "bind", "trap", "giu", "troi", "khoa"],
	"burst": ["burst", "explode", "boom", "blast", "no", "bung", "phat"],
}
const MODS = {
	"big": ["big", "huge", "wide", "giant", "to", "lon", "rong"],
	"long": ["long", "lasting", "lau", "ben", "dai"],
	"strong": ["strong", "mighty", "heavy", "manh", "khoe"],
}
const NOTE = {
	"wall": "A LINE ACROSS YOUR AIM. STOPS ENEMY BULLETS.", "vortex": "A CIRCLE THAT LASTS AND GRINDS.", "wave": "A FRONT THAT ROLLS AWAY AND CLEARS BULLETS.",
	"rain": "STRIKES FALLING ON AN AREA.", "orbit": "THREE ORBS CIRCLE YOU AND EAT BULLETS.", "lance": "ONE PIERCING BEAM ALONG YOUR AIM.",
	"push": "SHOVES FOES AWAY.", "pull": "DRAGS FOES IN.", "hold": "PINS FOES IN PLACE.", "burst": "EXPLODES WHEN IT ENDS.",
	"big": "WIDER", "long": "LASTS LONGER", "strong": "HITS HARDER",
}
# the word the random generator writes for each element
const EL_WORD = {"fire": "fire", "ice": "ice", "bolt": "storm", "tox": "venom", "stone": "stone", "wind": "wind", "light": "light", "void": "void",
	"water": "water", "leaf": "leaf", "earth": "earth", "metal": "metal", "wood": "wood", "mech": "gear", "x": "x"}

# ---- words -----------------------------------------------------------------------

static func parse(text: String) -> Dictionary:
	var out = {els = [], shape = "", verb = "", mods = [], name = "", ok = false}
	for w in Forge.fold(text).to_lower().split(" ", false):
		for el in Forge.ELEMENTS:
			if (Forge.ELEMENTS[el].has(w) or w == el) and not out.els.has(el) and out.els.size() < 2:
				out.els.append(el)
		for sh in SHAPES:
			if SHAPES[sh].has(w) and out.shape == "":
				out.shape = sh
		for v in VERBS:
			if VERBS[v].has(w) and out.verb == "":
				out.verb = v
		for m in MODS:
			if MODS[m].has(w) and not out.mods.has(m):
				out.mods.append(m)
	out.els.sort()
	out.ok = out.els.size() == 2
	if out.shape == "":
		out.shape = "wave"
	if out.verb == "":
		out.verb = "push"
	var nm = ""
	for ch in Forge.fold(text).to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == " ":
			nm += ch
	out.name = nm.strip_edges().substr(0, 24)
	return out

static func rest_of(r: Dictionary) -> float:
	return REST + 1.5 * r.get("mods", []).size()

# The generator: a recipe nobody wrote.
static func random_text(rng: RandomNumberGenerator) -> String:
	var a: String = D.ALL[rng.randi() % D.ALL.size()]
	var b: String = a
	while b == a:
		b = D.ALL[rng.randi() % D.ALL.size()]
	var words = [EL_WORD[a], EL_WORD[b], SHAPES.keys()[rng.randi() % SHAPES.size()], VERBS.keys()[rng.randi() % VERBS.size()]]
	for m in MODS:
		if rng.randf() < 0.3:
			words.append(m)
	return " ".join(words)

static func slot(i: int) -> Dictionary:
	var l = Meta.S.get("recipes", [])
	return l[i] if (i < l.size() and l[i] is Dictionary) else {}

static func recipes() -> Array:
	var out = []
	for i in SLOTS:
		if slot(i).get("ok", false):
			out.append(slot(i))
	return out

static func write(i: int, text: String) -> bool:
	while Meta.S.recipes.size() < SLOTS:
		Meta.S.recipes.append({})
	if text.strip_edges() == "":
		Meta.S.recipes[i] = {}
		return true
	var r = parse(text)
	if not r.ok:
		return false
	Meta.S.recipes[i] = r
	return true

static func describe(r: Dictionary) -> String:
	var s = "%s + %s  %s  %s" % [D.EL_NAME[r.els[0]], D.EL_NAME[r.els[1]], r.shape.to_upper(), r.verb.to_upper()]
	for m in r.get("mods", []):
		s += "  " + m.to_upper()
	return s

static func rows(g) -> Array:
	var out = [{name = "NAME SKILL ONE", desc = "RENAME AND SHAPE YOUR FIRST SKILL", cost = 0, state = "owned", tag = "WRITE", fn = func(): g.pending_say = "skill"}]
	for i in SLOTS:
		var r = slot(i)
		var ok: bool = r.get("ok", false)
		out.append({name = "RECIPE %d: %s" % [i + 1, r.name if ok else "EMPTY"], desc = describe(r) if ok else "TWO ELEMENTS, A SHAPE, A MOTION. ENGLISH OR VIETNAMESE.", cost = 0, state = "owned", tag = "WRITE",
			fn = func(): g.pending_say = "rc%d" % i})
	out.append({name = "ROLL A RANDOM RECIPE", desc = "THE LECTERN WRITES ONE FOR YOU INTO SLOT %d" % (g.roll_slot + 1), cost = 0, state = "owned", tag = "ROLL",
		fn = func():
			write(g.roll_slot, random_text(g.rng))
			g.roll_slot = (g.roll_slot + 1) % SLOTS
			g.menu_next = "spell"})
	out.append({name = "HOW IT WORKS", desc = "WHEN A RECIPE'S TWO ELEMENTS REACT, IT CASTS ITSELF", cost = 0, state = "on", tag = "", fn = func(): pass})
	return out

# ---- casting ---------------------------------------------------------------------

# A reaction of this pair happened at pos: the first rested recipe for it goes off.
static func on_react(g, key: String, pos: Vector2) -> bool:
	for i in SLOTS:
		var r = slot(i)
		if not r.get("ok", false) or Chem.pair_key(r.els[0], r.els[1]) != key or g.time < g.spell_cds[i]:
			continue
		g.spell_cds[i] = g.time + rest_of(r)
		cast(g, r, pos)
		return true
	return false

static func cast(g, r: Dictionary, pos: Vector2) -> void:
	var key: String = Chem.pair_key(r.els[0], r.els[1])
	var col: Color = D.REACT[key][1]
	var dir: Vector2 = g.p.aim if g.p.aim.length() > 0.1 else Vector2.RIGHT
	var mods: Array = r.get("mods", [])
	var area = 1.3 if mods.has("big") else 1.0
	var dur = 1.5 if mods.has("long") else 1.0
	var s = {shape = r.shape, verb = r.verb, els = r.els, col = col, pos = pos, dir = dir, t = 0.0, tick = 0.0, area = area,
		dmg = (10.0 + g.floor_i * 3.0) * g.st.react * (1.3 if mods.has("strong") else 1.0), hit = {}, name = r.name, owner = g.p}
	match r.shape:
		"wall":
			s.life = 5.0 * dur
			s.len = 56.0 * area
		"vortex":
			s.life = 4.0 * dur
			s.r = 46.0 * area
		"wave":
			s.life = 1.1 * dur
			s.pos = g.pcenter() + dir * 14.0
			s.len = 44.0 * area
		"rain":
			s.life = 3.0 * dur
			s.r = 52.0 * area
		"orbit":
			s.life = 6.0 * dur
			s.r = 30.0 * area
			s.pos = g.pcenter()
		"lance":
			s.life = 0.35
			s.pos = g.pcenter()
			var reach = 0.0
			while reach < 200.0 * area and not g.solid_at(s.pos.x + dir.x * (reach + 8.0), s.pos.y + dir.y * (reach + 8.0)):
				reach += 8.0
			s.end = s.pos + dir * reach
			for e in g.enemies:
				if not e.dead and seg_dist(g.center(e), s.pos, s.end) < 9.0 * area + e.r:
					strike(g, s, e, s.dmg * 4.0, g.center(e) - dir * 20.0, 320.0)
			for b in g.bullets:
				if b.team == 1 and not b.dead and seg_dist(b.pos, s.pos, s.end) < 8.0 * area + b.r:
					b.dead = true
	g.spells.append(s)
	for el in r.els:
		g.Env.touch(g, pos, 34.0 * area, el)
	g.label(g.p.pos + Vector2(0, -30), r.name, col, true)
	g.rings.append({pos = pos, r = 40.0, t = 0.0, col = col})
	g.flash(pos, 160.0, col, 0.4)
	g.shake_add(4.0)
	g.charge_res(0.5)
	Sfx.play("roar", 1.8, -6.0)
	g.tip("spell", "YOUR RECIPE", "IT CASTS ITSELF WHEN ITS TWO ELEMENTS REACT")

# distance from p to the segment a-b
static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var t = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(a + ab * t)

static func seg_point(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	return a + ab * clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)

# The motion of the recipe on one foe. from is what the foe is pushed from / pulled to.
static func motion(g, s: Dictionary, e: Dictionary, from: Vector2, force: float) -> void:
	if e.dead or e.d.ai == "dummy":
		return
	match s.verb:
		"push":
			Chem.shove(g, e, from, force)
		"pull":
			Chem.shove(g, e, from, -force)
		"hold":
			if e.is_boss:
				e.stun = maxf(e.stun, 0.1)
			else:
				e.frz = maxf(e.frz, 0.35)

# One damaging hit of a spell: damage, both element aspects, then the motion.
static func strike(g, s: Dictionary, e: Dictionary, dmg: float, from: Vector2, force: float) -> void:
	g.hurt_enemy(e, dmg, "", Vector2.ZERO, true, s.col)
	for el in s.els:
		Chem.touch(g, e, el, dmg * 0.5, s.pos, s.col)
	motion(g, s, e, from, force)

static func eat_bullets(g, s: Dictionary, a: Vector2, b: Vector2, w: float) -> void:
	for bl in g.bullets:
		if bl.team == 1 and not bl.dead and seg_dist(bl.pos, a, b) < w + bl.r:
			bl.dead = true
			g.parts.append({pos = bl.pos, vel = Vector2(0, -20), life = 0.25, max = 0.25, col = s.col, size = 2, grav = 0.0})

static func update(g, dt: float) -> void:
	if g.spells.is_empty():
		return
	for s in g.spells:
		s.t += dt
		s.life -= dt
		s.tick -= dt
		var tick: bool = s.tick <= 0.0
		if tick:
			s.tick = 0.3
		match s.shape:
			"wall":
				var side: Vector2 = s.dir.orthogonal()
				var a: Vector2 = s.pos - side * s.len
				var b: Vector2 = s.pos + side * s.len
				eat_bullets(g, s, a, b, 7.0)
				for e in g.enemies:
					if e.dead:
						continue
					var c: Vector2 = g.center(e)
					var near: Vector2 = seg_point(c, a, b)
					var dist = c.distance_to(near)
					if dist < 9.0 + e.r:
						if tick:
							strike(g, s, e, s.dmg * 0.5, near, 0.0)
						motion(g, s, e, near if dist > 3.0 else near - s.dir * 4.0, 900.0 * dt)
					elif s.verb == "pull" and dist < 90.0:
						motion(g, s, e, near, 520.0 * dt)
			"vortex":
				for e in g.enemies:
					if e.dead:
						continue
					var dist = g.center(e).distance_to(s.pos)
					if dist < s.r + e.r and tick:
						strike(g, s, e, s.dmg * 0.6, s.pos, 0.0)
					if s.verb == "pull" and dist < s.r * 2.2:
						motion(g, s, e, s.pos, 620.0 * dt)
					elif s.verb != "pull" and dist < s.r + e.r + 6.0:
						motion(g, s, e, s.pos, 1100.0 * dt)
			"wave":
				s.pos += s.dir * 190.0 * dt
				var side2: Vector2 = s.dir.orthogonal()
				var a2: Vector2 = s.pos - side2 * s.len
				var b2: Vector2 = s.pos + side2 * s.len
				if g.solid_at(s.pos.x, s.pos.y):
					s.life = 0.0
				eat_bullets(g, s, a2, b2, 10.0)
				for e in g.enemies:
					if e.dead or seg_dist(g.center(e), a2, b2) > 12.0 + e.r:
						continue
					if not s.hit.has(e.uid):
						s.hit[e.uid] = true
						strike(g, s, e, s.dmg * 3.0, g.center(e), 0.0)
					# push carries foes along with the front; pull throws them back at you
					motion(g, s, e, g.center(e) - s.dir * 20.0, (1500.0 if s.verb == "push" else 2600.0) * dt)
			"rain":
				if tick:
					s.tick = 0.2
					var q: Vector2 = s.pos + Vector2.from_angle(g.rng.randf() * TAU) * g.rng.randf() * s.r
					var inside = g.enemies.filter(func(e): return not e.dead and g.center(e).distance_to(s.pos) < s.r + e.r)
					if not inside.is_empty() and g.rng.randf() < 0.65:
						q = g.center(inside[g.rng.randi() % inside.size()])
					g.bolts.append({a = q + Vector2(g.rng.randf_range(-10, 10), -120), b = q, col = D.EL_COL[s.els[g.rng.randi() % 2]], t = 0.12, straight = true})
					g.rings.append({pos = q, r = 16.0, t = 0.0, col = s.col})
					for e in inside:
						if g.center(e).distance_to(q) < 18.0 + e.r:
							strike(g, s, e, s.dmg * 1.2, s.pos if s.verb == "pull" else q, 200.0)
			"orbit":
				s.pos = s.owner.pos + Vector2(0, -6)
				for i in 3:
					var op: Vector2 = s.pos + Vector2.from_angle(s.t * 3.4 + i * TAU / 3.0) * s.r
					eat_bullets(g, s, op, op, 6.0)
					for e in g.enemies:
						if e.dead or g.center(e).distance_to(op) > 8.0 + e.r:
							continue
						if g.time >= float(s.hit.get(e.uid, 0.0)):
							s.hit[e.uid] = g.time + 0.4
							strike(g, s, e, s.dmg * 1.0, s.pos, 260.0)
		if s.life <= 0.0 and s.verb == "burst":
			var at: Vector2 = s.get("end", s.pos)
			g.explode(at, 44.0 * s.area, s.dmg * 2.5, "", 0, s.col)
			for e in g.enemies:
				if not e.dead and g.center(e).distance_to(at) < 46.0 * s.area:
					for el in s.els:
						Chem.touch(g, e, el, s.dmg, at, s.col)
		if g.rng.randf() < 0.5 and s.shape != "lance":
			var pp: Vector2 = s.pos + Vector2(g.rng.randf_range(-20, 20), g.rng.randf_range(-20, 20))
			g.parts.append({pos = pp, vel = Vector2(0, -30), life = 0.4, max = 0.4, col = D.EL_COL[s.els[g.rng.randi() % 2]], size = 1, grav = 0.0})
	g.spells = g.spells.filter(func(s): return s.life > 0.0)

# ---- drawing ---------------------------------------------------------------------

static func draw(g, ci: CanvasItem) -> void:
	for s in g.spells:
		var a = clampf(s.life * 2.0, 0.0, 1.0) * clampf(s.t * 6.0, 0.0, 1.0)
		var c1: Color = D.EL_COL[s.els[0]]
		var c2: Color = D.EL_COL[s.els[1]]
		match s.shape:
			"wall", "wave":
				var side: Vector2 = s.dir.orthogonal()
				var n = int(s.len / 4.0)
				for i in range(-n, n + 1):
					var p: Vector2 = s.pos + side * i * 4.0
					var h = 10.0 + sin(g.time * 9.0 + i * 0.9) * 4.0 if s.shape == "wall" else 5.0
					var back: Vector2 = Vector2.ZERO if s.shape == "wall" else -s.dir * (6.0 + sin(g.time * 14.0 + i) * 3.0)
					var cc: Color = c1 if (i + int(g.time * 8.0)) % 2 == 0 else c2
					ci.draw_rect(Rect2((p + back - Vector2(2, h)).round(), Vector2(4, h + 2.0)), Color(cc.r, cc.g, cc.b, 0.75 * a))
					ci.draw_rect(Rect2((p - Vector2(1, h + 2.0)).round(), Vector2(2, 2)), Color(1, 1, 1, 0.8 * a))
				ci.draw_line(s.pos - side * s.len, s.pos + side * s.len, Color(s.col.r, s.col.g, s.col.b, 0.9 * a), 1.0)
			"vortex":
				ci.draw_circle(s.pos, s.r, Color(s.col.r, s.col.g, s.col.b, 0.13 * a))
				var spin = g.time * (4.0 if s.verb == "pull" else -4.0)
				for arm in 4:
					for j in 9:
						var k = j / 9.0
						var ang = spin + arm * TAU / 4.0 + k * 2.4
						var p2: Vector2 = s.pos + Vector2(cos(ang), sin(ang) * 0.8) * s.r * k
						var cc2: Color = c1 if arm % 2 == 0 else c2
						ci.draw_rect(Rect2((p2 - Vector2(1, 1)).round(), Vector2(3, 3)), Color(cc2.r, cc2.g, cc2.b, (0.35 + 0.6 * k) * a))
				ci.draw_arc(s.pos, s.r, 0.0, TAU, 28, Color(s.col.r, s.col.g, s.col.b, 0.7 * a), 1.0)
			"rain":
				ci.draw_circle(s.pos, s.r, Color(s.col.r, s.col.g, s.col.b, 0.08 * a))
				for i in 10:
					var a0 = i * TAU / 10.0 + g.time * 0.6
					ci.draw_arc(s.pos, s.r, a0, a0 + 0.35, 5, Color(s.col.r, s.col.g, s.col.b, 0.8 * a), 1.0)
				for i in 8:
					var fx = fmod(i * 37.0 + g.time * 23.0, s.r * 2.0) - s.r
					var fy = fmod(i * 53.0 + g.time * 170.0, s.r * 1.6) - s.r * 0.8
					if Vector2(fx, fy).length() < s.r:
						ci.draw_rect(Rect2((s.pos + Vector2(fx, fy)).round(), Vector2(1, 5)), Color(c1.r, c1.g, c1.b, 0.7 * a) if i % 2 == 0 else Color(c2.r, c2.g, c2.b, 0.7 * a))
			"orbit":
				ci.draw_arc(s.pos, s.r, 0.0, TAU, 24, Color(s.col.r, s.col.g, s.col.b, 0.25 * a), 1.0)
				for i in 3:
					var op: Vector2 = s.pos + Vector2.from_angle(s.t * 3.4 + i * TAU / 3.0) * s.r
					var oc: Color = c1 if i % 2 == 0 else c2
					ci.draw_circle(op, 5.0, Color(oc.r, oc.g, oc.b, 0.85 * a))
					ci.draw_circle(op, 2.0, Color(1, 1, 1, 0.9 * a))
					var tp: Vector2 = s.pos + Vector2.from_angle(s.t * 3.4 + i * TAU / 3.0 - 0.35) * s.r
					ci.draw_line(tp, op, Color(oc.r, oc.g, oc.b, 0.5 * a), 2.0)
			"lance":
				var k2 = clampf(s.life / 0.35, 0.0, 1.0)
				ci.draw_line(s.pos, s.end, Color(c1.r, c1.g, c1.b, 0.6 * k2), 9.0 * s.area * k2)
				ci.draw_line(s.pos, s.end, Color(c2.r, c2.g, c2.b, 0.8 * k2), 5.0 * s.area * k2)
				ci.draw_line(s.pos, s.end, Color(1, 1, 1, k2), 1.0)

# Recipe strip under the burst bar: bright when rested, dim with a bar while resting.
static func draw_hud(g, ci: CanvasItem) -> void:
	if g.in_lobby:
		return
	var y = 116
	for i in SLOTS:
		var r = slot(i)
		if not r.get("ok", false):
			continue
		var left = maxf(0.0, g.spell_cds[i] - g.time)
		var on = left <= 0.0
		for j in 2:
			ci.draw_texture(g.Art.T["ic_" + r.els[j]], Vector2(4 + j * 10, y - 2), Color.WHITE if on else Color(1, 1, 1, 0.3))
		Px.text(ci, Vector2(26, y), r.name, Color("d9d4c7") if on else Color("6b6779"))
		if not on:
			ci.draw_rect(Rect2(4, y + 7, 18.0 * (1.0 - left / rest_of(r)), 1), Color("7adfff"))
		y += 12
