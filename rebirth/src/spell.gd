extends RefCounted
# Combine: spells written in words before the run, cast from what is on the field.
#
# At the lectern you write up to two recipes: two elements, a shape and a motion
# ("fire ice wall push", "xoay set doc hut"). In a fight the weapons still only paint
# elements. Press V and the game gathers the elements lying around the aim point: fields,
# pools and burning / chilled / shocked / poisoned foes. If they match a recipe, they are
# used up and the spell appears there. No elements, no spell.
#   wall    a line across your aim: stops enemy bullets, hurts what touches it
#   vortex  a circle that lasts: hurts everything inside
#   wave    a front that rolls away from you and clears bullets
#   push    foes are shoved away        pull    foes are dragged in
# The spell also touches the room with both elements (ice bridges, fire burns brush...).

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")
const Px = preload("res://src/font.gd")
const Forge = preload("res://src/forge.gd")

const SLOTS = 2
const GATHER = 64.0
const REACH = 150.0
const SHAPES = {
	"wall": ["wall", "barrier", "line", "tuong", "rao", "thanh"],
	"vortex": ["vortex", "whirl", "spiral", "storm", "xoay", "loc", "voi"],
	"wave": ["wave", "tide", "surge", "song", "lan"],
}
const VERBS = {
	"push": ["push", "repel", "blow", "day", "thoi", "hat"],
	"pull": ["pull", "drag", "suck", "hut", "keo"],
}
const SHAPE_NAME = {"wall": "WALL", "vortex": "VORTEX", "wave": "WAVE"}
const NOTE = {
	"wall": "A LINE ACROSS YOUR AIM. STOPS ENEMY BULLETS.", "vortex": "A CIRCLE THAT LASTS AND GRINDS.", "wave": "A FRONT THAT ROLLS AWAY AND CLEARS BULLETS.",
	"push": "SHOVES FOES AWAY.", "pull": "DRAGS FOES IN.",
}

# ---- words -----------------------------------------------------------------------

static func parse(text: String) -> Dictionary:
	var out = {els = [], shape = "", verb = "", name = "", ok = false}
	var words = Forge.fold(text).to_lower().split(" ", false)
	for w in words:
		for el in Forge.ELEMENTS:
			if Forge.ELEMENTS[el].has(w) and not out.els.has(el) and out.els.size() < 2:
				# "storm" is both an element word and a shape word: the element wins once
				out.els.append(el)
		for sh in SHAPES:
			if SHAPES[sh].has(w) and out.shape == "" and not (w == "storm" and out.els.has("bolt")):
				out.shape = sh
		for v in VERBS:
			if VERBS[v].has(w) and out.verb == "":
				out.verb = v
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
	out.name = nm.strip_edges().substr(0, 22)
	return out

static func recipes() -> Array:
	var out = []
	for r in Meta.S.get("recipes", []):
		if r is Dictionary and r.get("ok", false):
			out.append(r)
	return out

static func slot(i: int) -> Dictionary:
	var l = Meta.S.get("recipes", [])
	return l[i] if (i < l.size() and l[i] is Dictionary) else {}

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

static func rows(g) -> Array:
	var out = [{name = "NAME SKILL ONE", desc = "RENAME AND SHAPE YOUR FIRST SKILL", cost = 0, state = "owned", tag = "WRITE", fn = func(): g.pending_say = "skill"}]
	for i in SLOTS:
		var r = slot(i)
		var desc = "TWO ELEMENTS, A SHAPE (WALL VORTEX WAVE), PUSH OR PULL"
		if r.get("ok", false):
			desc = "%s + %s  %s  %s" % [D.EL_NAME[r.els[0]], D.EL_NAME[r.els[1]], SHAPE_NAME[r.shape], r.verb.to_upper()]
		out.append({name = "RECIPE %d: %s" % [i + 1, r.get("name", "EMPTY") if r.get("ok", false) else "EMPTY"], desc = desc, cost = 0, state = "owned", tag = "WRITE",
			fn = func(): g.pending_say = "rc%d" % i})
	out.append({name = "HOW IT WORKS", desc = "PAINT BOTH ELEMENTS IN A FIGHT, THEN PRESS V TO COMBINE", cost = 0, state = "on", tag = "", fn = func(): pass})
	return out

# ---- gathering -------------------------------------------------------------------

static func aim_point(g) -> Vector2:
	var c: Vector2 = g.pcenter()
	var to: Vector2 = g.mouse() + g.cam_tl - c
	if to.length() > REACH:
		to = to.normalized() * REACH
	return c + to

# Elements lying within reach of pos: el -> list of sources.
static func gather(g, pos: Vector2) -> Dictionary:
	var out = {}
	var add = func(el: String, kind: String, ref):
		if not out.has(el):
			out[el] = []
		out[el].append([kind, ref])
	for f in g.fields:
		if f.life > 0.0 and f.pos.distance_to(pos) < GATHER + f.r:
			for el in f.els:
				add.call(el, "field", f)
	for z in g.zones:
		if z.life > 0.0 and z.el != "" and D.EL.has(z.el) and not z.get("grave", false) and z.pos.distance_to(pos) < GATHER + z.r:
			add.call(z.el, "zone", z)
	for e in g.enemies:
		if e.dead or e.pos.distance_to(pos) > GATHER + e.r:
			continue
		for el in e.st:
			if D.EL.has(el):
				add.call(el, "foe", e)
	return out

# First recipe whose two elements are both lying around pos.
static func ready(g, pos: Vector2):
	var have = gather(g, pos)
	for r in recipes():
		if have.has(r.els[0]) and have.has(r.els[1]):
			return r
	return null

# ---- casting ---------------------------------------------------------------------

static func combine(g) -> bool:
	if g.time < g.spell_cd:
		return false
	var pos = aim_point(g)
	var have = gather(g, pos)
	var pick = null
	for r in recipes():
		if have.has(r.els[0]) and have.has(r.els[1]):
			pick = r
			break
	if pick == null:
		Sfx.play("deny")
		var msg = "WRITE A RECIPE AT THE LECTERN" if recipes().is_empty() else ("NOTHING TO COMBINE HERE" if have.size() < 2 else "NO RECIPE FOR THESE ELEMENTS")
		g.label(g.p.pos + Vector2(0, -24), msg, Color("ff6a6a"))
		g.spell_cd = g.time + 0.3
		return false
	# the elements are used up
	var c = Vector2.ZERO
	var n = 0
	for el in pick.els:
		for s in have[el]:
			match s[0]:
				"field":
					s[1].life = 0.0
					c += s[1].pos
				"zone":
					s[1].life = 0.0
					c += s[1].pos
				"foe":
					s[1].st.erase(el)
					c += g.center(s[1])
			n += 1
			g.bolts.append({a = (s[1].pos if s[0] != "foe" else g.center(s[1])), b = pos, col = D.EL_COL[el], t = 0.18, straight = true})
	c = (c / float(n)).lerp(pos, 0.5)
	cast(g, pick, c, mini(n, 6))
	g.spell_cd = g.time + 1.0
	return true

static func cast(g, r: Dictionary, pos: Vector2, fuel: int) -> void:
	var key: String = r.els[0] + "+" + r.els[1]
	var col: Color = D.REACT[key][1]
	var dir: Vector2 = g.p.aim if g.p.aim.length() > 0.1 else Vector2.RIGHT
	# more fuel, bigger spell
	var k = 0.8 + 0.15 * fuel
	var s = {shape = r.shape, verb = r.verb, els = r.els, col = col, pos = pos, dir = dir, t = 0.0, tick = 0.0, k = k,
		dmg = (10.0 + g.floor_i * 3.0) * g.st.react * k, hit = {}, name = r.name}
	match r.shape:
		"wall":
			s.life = 5.0
			s.len = 56.0 * k
		"vortex":
			s.life = 4.0
			s.r = 46.0 * k
		"wave":
			s.life = 1.1
			s.pos = g.pcenter() + dir * 14.0
			s.len = 44.0 * k
	g.spells.append(s)
	for el in r.els:
		g.Env.touch(g, pos, 34.0, el)
	g.label(g.p.pos + Vector2(0, -30), r.name, col, true)
	g.rings.append({pos = pos, r = 40.0, t = 0.0, col = col})
	g.flash(pos, 160.0, col, 0.4)
	g.shake_add(4.0)
	g.hitstop = maxf(g.hitstop, 0.04)
	g.charge_res(0.5)
	Sfx.play("react", 0.8)
	Sfx.play("roar", 1.8, -6.0)
	g.tip("spell", "COMBINED", "YOUR WORDS, MADE FROM WHAT LAY ON THE FIELD")

# distance from p to the segment a-b
static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var t = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(a + ab * t)

static func shove(e: Dictionary, v: Vector2) -> void:
	if e.d.ai == "dummy":
		return
	e.kb += v * (0.15 if e.is_boss else 1.0)

static func update(g, dt: float) -> void:
	if g.spells.is_empty():
		return
	for s in g.spells:
		s.t += dt
		s.life -= dt
		s.tick -= dt
		var tick = s.tick <= 0.0
		if tick:
			s.tick = 0.3
		var sign = 1.0 if s.verb == "push" else -1.0
		match s.shape:
			"wall":
				var side: Vector2 = s.dir.orthogonal()
				var a: Vector2 = s.pos - side * s.len
				var b: Vector2 = s.pos + side * s.len
				for bl in g.bullets:
					if bl.team == 1 and not bl.dead and seg_dist(bl.pos, a, b) < 7.0 + bl.r:
						bl.dead = true
						g.burst(bl.pos, 2, s.col, 30.0, 0.2)
				for e in g.enemies:
					if e.dead:
						continue
					var c: Vector2 = g.center(e)
					var dist = seg_dist(c, a, b)
					var away = 1.0 if (c - s.pos).dot(s.dir) >= 0.0 else -1.0
					if dist < 9.0 + e.r:
						if tick:
							g.hurt_enemy(e, s.dmg * 0.5, "", Vector2.ZERO, true, s.col)
						if s.verb == "push" and not e.dead:
							shove(e, s.dir * away * 900.0 * dt)
					elif s.verb == "pull" and dist < 90.0:
						shove(e, -s.dir * away * 520.0 * dt)
			"vortex":
				for e in g.enemies:
					if e.dead:
						continue
					var to: Vector2 = g.center(e) - s.pos
					var dist = to.length()
					if dist < s.r + e.r and tick:
						g.hurt_enemy(e, s.dmg * 0.6, "", Vector2.ZERO, true, s.col)
					if e.dead or dist < 4.0:
						continue
					if s.verb == "pull" and dist < s.r * 2.2:
						shove(e, -to / dist * 620.0 * dt + to.orthogonal() / dist * 200.0 * dt)
					elif s.verb == "push" and dist < s.r + e.r + 6.0:
						shove(e, to / dist * 1100.0 * dt)
			"wave":
				s.pos += s.dir * 190.0 * dt
				var side2: Vector2 = s.dir.orthogonal()
				var a2: Vector2 = s.pos - side2 * s.len
				var b2: Vector2 = s.pos + side2 * s.len
				if g.solid_at(s.pos.x, s.pos.y):
					s.life = 0.0
				for bl in g.bullets:
					if bl.team == 1 and not bl.dead and seg_dist(bl.pos, a2, b2) < 10.0 + bl.r:
						bl.dead = true
				for e in g.enemies:
					if e.dead or seg_dist(g.center(e), a2, b2) > 12.0 + e.r:
						continue
					if not s.hit.has(e.uid):
						s.hit[e.uid] = true
						g.hurt_enemy(e, s.dmg * 3.0, "", Vector2.ZERO, true, s.col)
					if not e.dead:
						# push carries foes along with the front; pull throws them back at you
						shove(e, s.dir * sign * (1500.0 if sign > 0.0 else 2600.0) * dt)
		if g.rng.randf() < 0.5:
			var pp: Vector2 = s.pos + Vector2(g.rng.randf_range(-20, 20), g.rng.randf_range(-20, 20))
			g.parts.append({pos = pp, vel = Vector2(0, -30), life = 0.4, max = 0.4, col = D.EL_COL[s.els[g.rng.randi() % 2]], size = 1, grav = 0.0})
	g.spells = g.spells.filter(func(s): return s.life > 0.0)

# ---- drawing ---------------------------------------------------------------------

static func draw(g, ci: CanvasItem) -> void:
	# a ring at the aim point while a recipe can be cast there
	if g.state == "play" and not g.p.is_empty() and not recipes().is_empty():
		var ap = aim_point(g)
		var rd = ready(g, ap)
		if rd != null:
			var rc: Color = D.REACT[rd.els[0] + "+" + rd.els[1]][1]
			ci.draw_arc(ap, GATHER * (0.9 + 0.1 * sin(g.time * 8.0)), 0.0, TAU, 32, Color(rc.r, rc.g, rc.b, 0.8), 1.0)
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

# Recipe strip under the burst bar: lit when the elements are in reach.
static func draw_hud(g, ci: CanvasItem) -> void:
	var list = recipes()
	if list.is_empty() or g.in_lobby and g.enemies.is_empty():
		return
	var have = gather(g, aim_point(g))
	var y = 116
	for r in list:
		var ok = have.has(r.els[0]) and have.has(r.els[1])
		for i in 2:
			var lit = have.has(r.els[i])
			ci.draw_texture(g.Art.T["ic_" + r.els[i]], Vector2(4 + i * 10, y - 2), Color.WHITE if lit else Color(1, 1, 1, 0.25))
		var txt: String = ("V " if ok else "") + r.name
		Px.text(ci, Vector2(26, y), txt, (Color("ffd24a") if int(g.time * 6.0) % 2 == 0 else Color.WHITE) if ok else Color("6b6779"))
		y += 11
	# where the gathering happens
