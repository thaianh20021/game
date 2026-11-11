extends RefCounted
# Storm forms. A storm made of three elements used to be one circle that ticked. Now the
# element that COMPLETES the storm (the third one in) decides its shape, so the same three
# elements make three different storms depending on the order you paint them:
#   fire  ERUPTION     rings of fire roll outward        stone METEORS    rocks fall on foes far around
#   ice   SPIKES       six ice lances turn like a star   wind  TORNADO    a funnel wanders, drags and flings
#   storm CHAIN        lightning leaps from foe to foe   light SUNBEAMS   two beams sweep the room
#   venom CREEPER      the cloud hunts the nearest foe   void  SINGULARITY shrinks, drags all in, then bursts
#   water TIDE         waves roll along your aim         leaf  BRAMBLE    vines reach out and root foes
#   earth FISSURE      cracks split the floor and quake  metal BLADES     four blades orbit and cut bullets
#   wood  GROVE        four thorn posts guard a square   gear  BATTERY    three sentries stand up
#   X     a random one of the above
# Whatever a form touches still gets the aspects of all three elements (chem.gd).
# The four hand-made storms of the old elements (thunderstorm, acid rain...) are unchanged.

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")

const FORM = {
	"fire": ["ERUPTION", "RINGS OF FIRE ROLL OUTWARD"],
	"ice": ["SPIKES", "SIX LANCES TURN LIKE A STAR"],
	"bolt": ["CHAIN", "LIGHTNING LEAPS FROM FOE TO FOE"],
	"tox": ["CREEPER", "THE CLOUD HUNTS THE NEAREST FOE"],
	"stone": ["METEORS", "ROCKS FALL ON FOES FAR AROUND"],
	"wind": ["TORNADO", "IT WANDERS, DRAGS AND FLINGS"],
	"light": ["SUNBEAMS", "TWO BEAMS SWEEP THE ROOM"],
	"void": ["SINGULARITY", "IT DRAGS ALL IN, THEN BURSTS"],
	"water": ["TIDE", "WAVES ROLL ALONG YOUR AIM"],
	"leaf": ["BRAMBLE", "VINES REACH OUT AND ROOT FOES"],
	"earth": ["FISSURE", "THE FLOOR SPLITS AND QUAKES"],
	"metal": ["BLADES", "FOUR BLADES ORBIT AND CUT BULLETS"],
	"wood": ["GROVE", "FOUR THORN POSTS HOLD THE GROUND"],
	"mech": ["BATTERY", "THREE SENTRIES STAND UP"],
}
# how hard one touch hits, against the plain circle (narrow or rare touches hit harder)
const SCALE = {"fire": 2.4, "ice": 1.6, "bolt": 1.3, "tox": 1.1, "stone": 3.2, "wind": 1.0, "light": 1.8, "void": 0.8,
	"water": 2.4, "leaf": 0.8, "earth": 1.5, "metal": 1.8, "wood": 1.4, "mech": 0.6}

static func note(f: Dictionary) -> String:
	return FORM[f.form][0] + ": " + FORM[f.form][1]

# Called once when a field becomes a storm.
static func pick(g, f: Dictionary) -> void:
	var form: String = f.els[f.els.size() - 1]
	if not FORM.has(form):
		var ks = FORM.keys()
		form = ks[g.rng.randi() % ks.size()]
	f.form = form
	f.home = f.pos
	f.dir = g.p.aim if g.p.aim != Vector2.ZERO else Vector2.RIGHT
	f.ang = g.rng.randf() * TAU
	f.pulse = 0.0
	f.hit = []
	f.n = 0
	match form:
		"tox":
			f.r = 54.0
		"wind":
			f.r = 38.0
			f.life = 7.0
		"void":
			f.r = 90.0
		"mech":
			f.r = 44.0
			for i in 3:
				var q: Vector2 = f.pos + Vector2.from_angle(f.ang + i * TAU / 3.0) * 30.0
				g.allies.append({pos = q, life = f.life, t = 0.2 + i * 0.2, el = f.els[i % f.els.size()]})
				g.burst(q, 6, D.EL_COL["mech"], 50.0, 0.4)
		"earth":
			f.cracks = [f.ang, f.ang + 1.1 + g.rng.randf() * 0.5, f.ang + 2.3 + g.rng.randf() * 0.5]
		"wood":
			f.posts = []
			for i in 4:
				f.posts.append(f.pos + Vector2.from_angle(f.ang + i * TAU / 4.0) * 46.0)

static func seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	return Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p)

static func foes(g) -> Array:
	return g.enemies.filter(func(e): return not e.dead and e.d.ai != "dummy")

static func drag(e: Dictionary, v: Vector2) -> void:
	e.kb += v * (0.15 if e.is_boss else 1.0)

# ---- every frame -----------------------------------------------------------------

static func frame(g, f: Dictionary, dt: float, power: float, col: Color) -> void:
	match f.form:
		"fire":
			f.pulse += dt * 95.0
			if f.pulse > f.r * 1.7:
				f.pulse = 0.0
				f.hit = []
				Sfx.play("shoot_fire", 0.6, -8.0)
		"ice":
			f.ang += dt * 0.55
		"light":
			f.ang += dt * 1.25
		"metal":
			f.ang += dt * 3.2
			for b in g.bullets:
				if b.team != 1 or b.dead or b.get("lob", false):
					continue
				for q in blades(f):
					if b.pos.distance_to(q) < 10.0:
						b.dead = true
						g.parts.append({pos = b.pos, vel = Vector2(0, -20), life = 0.25, max = 0.25, col = Color.WHITE, size = 2, grav = 0.0})
						break
		"tox":
			var e = g.nearest_enemy(f.pos, 260.0, [])
			if e != null and e.d.ai != "dummy":
				var to: Vector2 = g.center(e) - f.pos
				if to.length() > 6.0:
					f.pos += to.normalized() * 38.0 * dt
		"wind":
			f.ang += dt * (1.4 + sin(f.t * 2.3))
			var v = Vector2.from_angle(f.ang) * 62.0
			if f.pos.distance_to(f.home) > 100.0:
				v = (f.home - f.pos).normalized() * 62.0
				f.ang = v.angle()
			f.pos += v * dt
			for e in foes(g):
				var to: Vector2 = f.pos - g.center(e)
				if to.length() < f.r * 2.4 and to.length() > 4.0:
					drag(e, to.normalized() * 520.0 * dt)
		"void":
			f.r = lerpf(26.0, 90.0, clampf(f.life / 6.0, 0.0, 1.0))
			for e in foes(g):
				var to: Vector2 = f.pos - g.center(e)
				if to.length() < 150.0 and to.length() > 6.0:
					drag(e, to.normalized() * 640.0 * dt)
			if f.life <= 0.0 and not f.has("boom"):
				f.boom = true
				g.explode(f.pos, 84.0, power * 9.0, "", 0, col)
				g.rings.append({pos = f.pos, r = 84.0, t = 0.0, col = Color.WHITE})
				g.shake_add(7.0)
		"water":
			f.pulse += dt * 115.0
			if f.pulse > 200.0:
				f.pulse = 0.0
				f.hit = []

static func blades(f: Dictionary) -> Array:
	var out = []
	for i in 4:
		out.append(f.pos + Vector2.from_angle(f.ang + i * TAU / 4.0) * f.r * 0.75)
	return out

# ---- every tick: who the form touches now ------------------------------------------

static func targets(g, f: Dictionary, power: float, col: Color) -> Array:
	var out = []
	var all = foes(g)
	f.n += 1
	match f.form:
		"fire", "water":
			var side: Vector2 = f.dir.orthogonal()
			for e in all:
				if f.hit.has(e.uid):
					continue
				var c: Vector2 = g.center(e)
				var on = false
				if f.form == "fire":
					on = absf(c.distance_to(f.pos) - f.pulse) < 16.0 + e.hr
				else:
					var rel: Vector2 = c - f.home
					on = absf(rel.dot(f.dir) - f.pulse) < 18.0 + e.hr and absf(rel.dot(side)) < 62.0 + e.hr
					if on:
						drag(e, f.dir * 240.0)
				if on:
					f.hit.append(e.uid)
					out.append(e)
		"ice":
			var ln = f.r * 1.5 * clampf(f.t * 3.0, 0.0, 1.0)
			for e in all:
				for i in 6:
					if seg(g.center(e), f.pos, f.pos + Vector2.from_angle(f.ang + i * TAU / 6.0) * ln) < 7.0 + e.hr:
						out.append(e)
						break
		"light":
			var ln = f.r * 1.6
			for e in all:
				for i in 2:
					var d = Vector2.from_angle(f.ang + i * PI / 2.0) * ln
					if seg(g.center(e), f.pos - d, f.pos + d) < 6.0 + e.hr:
						out.append(e)
						break
		"bolt":
			var from: Vector2 = f.pos
			var reach = f.r * 1.7
			for k in 6:
				var best = null
				var bd = reach
				for e in all:
					if not out.has(e) and g.center(e).distance_to(from) < bd:
						bd = g.center(e).distance_to(from)
						best = e
				if best == null:
					break
				g.bolt(from, g.center(best), col)
				out.append(best)
				from = g.center(best)
				reach = 100.0
			if not out.is_empty():
				Sfx.play("shoot_bolt", 0.9, -8.0)
		"stone":
			if f.n % 2 == 0:
				var q: Vector2 = f.pos + Vector2.from_angle(g.rng.randf() * TAU) * g.rng.randf() * f.r * 1.6
				var near = all.filter(func(e): return g.center(e).distance_to(f.pos) < f.r * 2.0)
				if not near.is_empty():
					q = near[g.rng.randi() % near.size()].pos
				g.tele_circle(q, 20.0, 0.5)
				g.after(0.5, func():
					g.explode(q, 24.0, power * SCALE["stone"], "", 0, col)
					g.parts.append({pos = q + Vector2(0, -40), vel = Vector2(0, 300), life = 0.12, max = 0.12, col = col, size = 3, grav = 0.0})
					g.shake_add(2.0))
		"leaf":
			for e in all:
				if out.size() < 8 and g.center(e).distance_to(f.pos) < f.r * 1.8:
					out.append(e)
					e.kb = Vector2.ZERO
					if not e.is_boss:
						e.stun = maxf(e.stun, 0.25)
					g.bolts.append({a = f.pos, b = e.pos + Vector2(0, e.r), col = D.EL_COL["leaf"], t = 0.35, straight = false})
		"earth":
			var ln = f.r * 2.2
			var quake = f.n % 4 == 0
			if quake:
				g.shake_add(3.0)
				g.rings.append({pos = f.pos, r = f.r * 2.2, t = 0.0, col = col})
			for e in all:
				if e.d.get("fly", false):
					continue
				if quake and g.center(e).distance_to(f.pos) < f.r * 2.2:
					out.append(e)
					continue
				for a in f.cracks:
					var d = Vector2.from_angle(a) * ln
					if seg(e.pos, f.pos - d, f.pos + d) < 9.0 + e.hr:
						out.append(e)
						break
		"metal":
			var bl = blades(f)
			for e in all:
				for q in bl:
					if g.center(e).distance_to(q) < 11.0 + e.hr:
						out.append(e)
						break
		"wood":
			for e in all:
				for q in f.posts:
					if g.center(e).distance_to(q) < 24.0 + e.hr:
						out.append(e)
						break
		_:
			for e in all:
				if g.center(e).distance_to(f.pos) < f.r + e.hr:
					out.append(e)
			if f.form == "wind":
				for e in out:
					drag(e, (g.center(e) - f.pos).orthogonal().normalized() * 260.0)
	return out

# ---- drawing ---------------------------------------------------------------------

static func draw(g, ci: CanvasItem, f: Dictionary, col: Color, a: float) -> void:
	var p: Vector2 = f.pos
	var t: float = g.time
	var soft = Color(col.r, col.g, col.b, 0.12 * a)
	var hard = Color(col.r, col.g, col.b, 0.9 * a)
	var white = Color(1, 1, 1, 0.8 * a)
	# the heart every storm keeps
	ci.draw_circle(p, 9.0 + sin(t * 6.0), Color(col.r, col.g, col.b, 0.35 * a))
	ci.draw_arc(p, 11.0, t * 3.0, t * 3.0 + 4.0, 10, hard, 1.0)
	match f.form:
		"fire":
			ci.draw_arc(p, maxf(2.0, f.pulse), 0.0, TAU, 40, hard, 3.0)
			ci.draw_arc(p, maxf(2.0, f.pulse - 5.0), 0.0, TAU, 40, Color(1.0, 0.95, 0.6, 0.5 * a), 1.0)
			ci.draw_circle(p, f.pulse, Color(col.r, col.g, col.b, 0.06 * a))
		"ice":
			var ln = f.r * 1.5 * clampf(f.t * 3.0, 0.0, 1.0)
			for i in 6:
				var d = Vector2.from_angle(f.ang + i * TAU / 6.0)
				var tip: Vector2 = p + d * ln
				var s: Vector2 = d.orthogonal() * 5.0
				ci.draw_colored_polygon(PackedVector2Array([p + s, p - s, tip]), Color(col.r, col.g, col.b, 0.55 * a))
				ci.draw_line(p, tip, white, 1.0)
		"light":
			var ln = f.r * 1.6
			for i in 2:
				var d = Vector2.from_angle(f.ang + i * PI / 2.0) * ln
				ci.draw_line(p - d, p + d, Color(col.r, col.g, col.b, 0.3 * a), 9.0)
				ci.draw_line(p - d, p + d, hard, 4.0)
				ci.draw_line(p - d, p + d, white, 1.0)
		"bolt":
			ci.draw_arc(p, f.r * 1.7, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.18 * a), 1.0)
			for i in 4:
				var d = Vector2.from_angle(g.rng.randf() * TAU) * 14.0
				ci.draw_line(p, p + d, hard, 1.0)
		"tox", "mech":
			ci.draw_circle(p, f.r, soft)
			for i in 5:
				var q = p + Vector2.from_angle(t * 0.9 + i * TAU / 5.0) * f.r * 0.5
				ci.draw_circle(q, f.r * 0.4 + sin(t * 3.0 + i) * 2.0, soft)
			ci.draw_arc(p, f.r, 0.0, TAU, 32, Color(col.r, col.g, col.b, 0.7 * a), 1.0)
		"stone":
			ci.draw_arc(p, f.r * 1.6, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.2 * a), 1.0)
			for i in 6:
				var a0 = -t * 0.8 + i * TAU / 6.0
				ci.draw_rect(Rect2(p + Vector2.from_angle(a0) * 16.0 - Vector2(2, 2), Vector2(4, 4)), hard)
		"wind":
			for i in 6:
				var k = i / 5.0
				var w = lerpf(8.0, f.r, k)
				var c: Vector2 = p + Vector2(sin(t * 7.0 + i * 0.9) * 4.0 * k, -k * 40.0)
				ci.draw_arc(c, w, t * 9.0 + i, t * 9.0 + i + 4.4, 14, Color(col.r, col.g, col.b, (0.85 - 0.4 * k) * a), 2.0)
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			ci.draw_arc(p, f.r * 2.4, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.1 * a), 1.0)
		"void":
			ci.draw_circle(p, f.r, Color(0.03, 0.0, 0.08, 0.55 * a))
			ci.draw_arc(p, f.r, 0.0, TAU, 40, hard, 2.0)
			for i in 8:
				var a0 = t * 2.0 + i * TAU / 8.0
				var k = fmod(t * 0.9 + i * 0.13, 1.0)
				ci.draw_line(p + Vector2.from_angle(a0) * lerpf(150.0, f.r, k), p + Vector2.from_angle(a0 + 0.2) * lerpf(140.0, f.r * 0.9, k), Color(col.r, col.g, col.b, 0.5 * a * k), 1.0)
		"water":
			var side: Vector2 = f.dir.orthogonal()
			var c: Vector2 = f.home + f.dir * f.pulse
			for i in 3:
				var back: Vector2 = c - f.dir * (i * 7.0)
				ci.draw_line(back - side * (62.0 - i * 8.0), back + side * (62.0 - i * 8.0), Color(col.r, col.g, col.b, (0.9 - i * 0.28) * a), 3.0 - i)
			ci.draw_line(c - side * 62.0 + f.dir * 2.0, c + side * 62.0 + f.dir * 2.0, white, 1.0)
		"leaf":
			ci.draw_arc(p, f.r * 1.8, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.16 * a), 1.0)
			for i in 8:
				var d = Vector2.from_angle(f.ang + i * TAU / 8.0)
				ci.draw_line(p + d * 8.0, p + d * (18.0 + sin(t * 4.0 + i) * 4.0), hard, 2.0)
		"earth":
			var ln = f.r * 2.2 * clampf(f.t * 4.0, 0.0, 1.0)
			for a0 in f.cracks:
				var d = Vector2.from_angle(a0)
				var prev: Vector2 = p - d * ln
				for k in range(1, 9):
					var q: Vector2 = p - d * ln + d * (ln * 2.0 * k / 8.0) + d.orthogonal() * (4.0 if k % 2 == 0 else -4.0) * (0.0 if k == 8 else 1.0)
					ci.draw_line(prev, q, Color(col.r, col.g, col.b, 0.55 * a), 4.0)
					ci.draw_line(prev, q, Color(0.05, 0.03, 0.06, 0.9 * a), 2.0)
					prev = q
		"metal":
			ci.draw_arc(p, f.r * 0.75, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.2 * a), 1.0)
			for q in blades(f):
				var d = Vector2.from_angle(t * 14.0) * 9.0
				ci.draw_line(q - d, q + d, white, 2.0)
				ci.draw_line(q - d.orthogonal(), q + d.orthogonal(), hard, 2.0)
		"wood":
			for i in 4:
				var q: Vector2 = f.posts[i]
				var q2: Vector2 = f.posts[(i + 1) % 4]
				ci.draw_line(q, q2, Color(col.r, col.g, col.b, 0.25 * a), 1.0)
				ci.draw_circle(q, 24.0, soft)
				ci.draw_arc(q, 24.0 - fmod(t * 20.0 + i * 5.0, 20.0), 0.0, TAU, 20, Color(col.r, col.g, col.b, 0.5 * a), 1.0)
				ci.draw_rect(Rect2(q + Vector2(-3, -14), Vector2(6, 16)), Color(0.36, 0.24, 0.12, a))
				ci.draw_rect(Rect2(q + Vector2(-6, -18), Vector2(12, 6)), Color(col.r, col.g, col.b, a))
