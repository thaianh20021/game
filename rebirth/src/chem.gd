extends RefCounted
# The chemistry generator.
#
# Fifteen elements. The first four (D.EL) are the old ones: foes, traps and barrels use only
# those, and their six reactions and four storms are hand-made. The four new ones (D.EL2)
# are painted only by heroes. Every pair and every triple that is not hand-made is BUILT
# here from one small behaviour per element (its aspect), so 105 reactions, 105 fields and
# 455 storms exist without hand-written cases:
#   fire  burns (extra damage)        stone staggers, and its fields stop bullets
#   ice   freezes for a moment        wind  shoves away from the centre
#   bolt  stuns                       light exposes (+50% damage taken)
#   tox   poisons                     void  drags to the centre, feeds you energy,
#                                           and its fields slow bullets
#   water washes foes and bullets outward   leaf   thorns (damage, a little exposure)
#   earth quakes under foes that walk       metal  cuts; its fields send bullets back
#   wood  roots foes where they stand       mech   shoots shards at the next foe
#   x     behaves as a random other element each time
# A generated storm is named from words: an adjective of its last element plus the name of
# the field of the other two ("HOWLING MAGMA").

const D = preload("res://src/data.gd")

const ADJ = {
	"fire": "BURNING", "ice": "FROZEN", "bolt": "CHARGED", "tox": "TOXIC",
	"stone": "CRUSHING", "wind": "HOWLING", "light": "RADIANT", "void": "HOLLOW",
	"water": "DROWNING", "leaf": "VERDANT", "earth": "QUAKING", "metal": "IRON", "wood": "ROOTED", "mech": "CLOCKWORK", "x": "UNKNOWN",
}
const ASPECT = {
	"fire": "BURNS", "ice": "FREEZES", "bolt": "STUNS", "tox": "POISONS",
	"stone": "STAGGERS, STOPS BULLETS", "wind": "SHOVES AWAY", "light": "EXPOSES", "void": "DRAGS IN, SLOWS BULLETS",
	"water": "WASHES FOES AND BULLETS AWAY", "leaf": "THORNS", "earth": "QUAKES UNDER WALKERS", "metal": "CUTS, TURNS BULLETS BACK",
	"wood": "ROOTS IN PLACE", "mech": "SHOOTS SHARDS", "x": "COPIES A RANDOM ELEMENT",
}
# names of the four hand-made storms, by the old element that is missing
# what the X element may turn into
const WILD = ["fire", "ice", "bolt", "tox", "stone", "wind", "light", "void", "water", "leaf", "earth", "metal", "wood", "mech"]
const OLD_STORM = {"tox": "THUNDERSTORM", "bolt": "ACID RAIN", "ice": "FIRESTORM", "fire": "BLIZZARD"}
const OLD_FIELD = {"fire+ice": "STEAM", "fire+tox": "WILDFIRE", "bolt+fire": "PLASMA", "bolt+ice": "HAIL", "ice+tox": "ROT", "bolt+tox": "MIASMA"}

static func pair_key(a: String, b: String) -> String:
	return a + "+" + b if a < b else b + "+" + a

static func is_old(els: Array) -> bool:
	for el in els:
		if not D.EL.has(el):
			return false
	return true

# All 28 pair keys, the six hand-made ones first.
static func pair_keys() -> Array:
	var out = []
	for i in D.ALL.size():
		for j in range(i + 1, D.ALL.size()):
			out.append(pair_key(D.ALL[i], D.ALL[j]))
	return out

static func field_name(key: String) -> String:
	return OLD_FIELD[key] if OLD_FIELD.has(key) else D.REACT[key][0]

static func field_note(key: String) -> String:
	var els = key.split("+")
	return "%s + %s. %s. %s." % [D.EL_NAME[els[0]], D.EL_NAME[els[1]], ASPECT[els[0]], ASPECT[els[1]]]

# ---- storms ----------------------------------------------------------------------

# Key of the storm made of these three elements: the missing old element for the four
# hand-made ones (as before), otherwise the three names sorted.
static func storm_key(els: Array) -> String:
	if is_old(els):
		for q in D.EL:
			if not els.has(q):
				return q
	var s = els.duplicate()
	s.sort()
	return "+".join(s)

static func storm_els(key: String) -> Array:
	if OLD_STORM.has(key):
		return D.EL.filter(func(q): return q != key)
	return Array(key.split("+"))

static func storm_name(key: String) -> String:
	if OLD_STORM.has(key):
		return OLD_STORM[key]
	var els = key.split("+")
	return ADJ[els[2]] + " " + field_name(pair_key(els[0], els[1]))

static func storm_note(key: String) -> String:
	var els = storm_els(key)
	return "%s + %s + %s." % [D.EL_NAME[els[0]], D.EL_NAME[els[1]], D.EL_NAME[els[2]]]

static func storm_col(key: String) -> Color:
	var els = storm_els(key)
	var c: Color = D.EL_COL[els[0]]
	return c.lerp(D.EL_COL[els[1]], 0.5).lerp(D.EL_COL[els[2]], 0.34).lightened(0.15)

# ---- aspects ---------------------------------------------------------------------

# One element's behaviour on one foe. power is a damage figure; centre is where the
# field, storm or spell sits (wind pushes from it, void pulls to it).
static func touch(g, e: Dictionary, el: String, power: float, centre: Vector2, col: Color) -> void:
	if e.dead:
		return
	match el:
		"fire":
			g.hurt_enemy(e, power * 0.6, "", Vector2.ZERO, true, col)
		"ice":
			if not e.is_boss:
				e.frz = maxf(e.frz, 0.25)
		"bolt":
			e.stun = maxf(e.stun, 0.12 if e.is_boss else 0.35)
		"tox":
			e.vuln = maxf(e.vuln, 0.6)
			g.hurt_enemy(e, power * 0.3, "", Vector2.ZERO, true, col)
		"stone":
			if not e.is_boss:
				e.stun = maxf(e.stun, 0.2)
			g.hurt_enemy(e, power * 0.4, "", Vector2.ZERO, true, col)
		"wind":
			shove(g, e, centre, 260.0)
		"light":
			e.vuln = maxf(e.vuln, 1.5)
		"void":
			shove(g, e, centre, -220.0)
			g.p.en = minf(float(g.p.men), g.p.en + 0.5)
		"water":
			shove(g, e, centre, 120.0)
			g.hurt_enemy(e, power * 0.3, "", Vector2.ZERO, true, col)
		"leaf":
			e.vuln = maxf(e.vuln, 0.4)
			g.hurt_enemy(e, power * 0.5, "", Vector2.ZERO, true, col)
		"earth":
			if not e.d.get("fly", false):
				if not e.is_boss:
					e.stun = maxf(e.stun, 0.1)
				g.hurt_enemy(e, power * 0.7, "", Vector2.ZERO, true, col)
		"metal":
			g.hurt_enemy(e, power * 0.55, "", Vector2.ZERO, true, col)
		"wood":
			e.kb = Vector2.ZERO
			if not e.is_boss:
				e.stun = maxf(e.stun, 0.3)
		"mech":
			var o = g.nearest_enemy(g.center(e), 120.0, [e])
			if o != null:
				g.add_bullet(g.center(e), (g.center(o) - g.center(e)).normalized() * 260.0, {dmg = power * 0.6, el = "", r = 2.0, life = 0.7})
			else:
				g.hurt_enemy(e, power * 0.4, "", Vector2.ZERO, true, col)
		"x":
			touch(g, e, WILD[g.rng.randi() % WILD.size()], power, centre, col)

static func shove(g, e: Dictionary, centre: Vector2, force: float) -> void:
	if e.d.ai == "dummy":
		return
	var to: Vector2 = g.center(e) - centre
	if to.length() < 3.0:
		to = Vector2.from_angle(g.rng.randf() * TAU)
	e.kb += to.normalized() * force * (0.15 if e.is_boss else 1.0)

# What a new element does the moment it lands on a foe (the old four are in game.gd).
static func on_hit(g, e: Dictionary, el: String) -> void:
	match el:
		"stone":
			if not e.is_boss:
				e.stun = maxf(e.stun, 0.1)
		"wind":
			shove(g, e, g.p.pos, 150.0)
		"light":
			e.vuln = maxf(e.vuln, 2.0)
		"void":
			g.p.en = minf(float(g.p.men), g.p.en + 1.5)
		"water":
			shove(g, e, g.p.pos, 70.0)
		"leaf":
			e.vuln = maxf(e.vuln, 0.8)
		"earth", "wood":
			if not e.is_boss and not (el == "earth" and e.d.get("fly", false)):
				e.stun = maxf(e.stun, 0.12)
		"metal":
			g.hurt_enemy(e, 1.0 + g.floor_i * 0.3, "", Vector2.ZERO, true)
		"x":
			on_hit(g, e, WILD[g.rng.randi() % WILD.size()])

# Per-frame work of a field or storm on enemy bullets.
static func bullets(g, els: Array, pos: Vector2, r: float, col: Color) -> void:
	var stop = els.has("stone")
	var slow = els.has("void")
	var turn = els.has("metal")
	var wash = els.has("water")
	if not stop and not slow and not turn and not wash:
		return
	for b in g.bullets:
		if b.team != 1 or b.dead or b.pos.distance_to(pos) > r:
			continue
		if stop and not b.get("lob", false):
			b.dead = true
			g.parts.append({pos = b.pos, vel = Vector2(0, -20), life = 0.3, max = 0.3, col = col, size = 2, grav = 0.0})
		elif turn and not b.get("lob", false):
			# metal sends the shot back as yours
			b.team = 0
			b.own = 0
			b.hit = []
			b.vel = -b.vel
			b.dmg = 4.0 + g.floor_i * 1.5
			b.el = ""
		elif wash and not b.has("washed"):
			# water carries shots out along the current
			b.washed = true
			var out: Vector2 = b.pos - pos
			if out.length() > 1.0:
				b.vel = out.normalized() * b.vel.length()
		elif slow and not b.has("slowed"):
			b.slowed = true
			b.vel *= 0.35

# A generated reaction: a blast, then both aspects on everything close.
static func react(g, e: Dictionary, key: String, base: float, col: Color) -> void:
	var c: Vector2 = g.center(e)
	var els = key.split("+")
	g.explode(c, 40.0, base * 1.1, "", 0, col)
	for o in g.enemies:
		if not o.dead and g.center(o).distance_to(c) < 46.0:
			for el in els:
				touch(g, o, el, base, c, col)
	for i in 14:
		var d = Vector2.from_angle(g.rng.randf() * TAU)
		g.parts.append({pos = c + d * 4.0, vel = d * g.rng.randf_range(40, 110), life = 0.5, max = 0.5, col = D.EL_COL[els[i % 2]], size = 1 + i % 2, grav = 0.0})

# A generated field or storm ticking on the foes inside it.
static func tick(g, els: Array, inside: Array, pos: Vector2, power: float, col: Color) -> void:
	for e in inside:
		g.hurt_enemy(e, power, "", Vector2.ZERO, true, col)
		for el in els:
			touch(g, e, el, power, pos, col)

# Dots around a foe for the new elements it carries.
static func draw_status(g, ci: CanvasItem, e: Dictionary) -> void:
	var c: Vector2 = g.center(e)
	var n = 0
	for el in D.EL2:
		if not e.st.has(el):
			continue
		var col: Color = D.EL_COL[el]
		for i in 3:
			var a = g.time * 5.0 + i * TAU / 3.0 + n * 1.0
			ci.draw_rect(Rect2((c + Vector2(cos(a), sin(a) * 0.5) * (e.h2 + 3.0) - Vector2(1, 1)).round(), Vector2(2, 2)), col)
		n += 1
