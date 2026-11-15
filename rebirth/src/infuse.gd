extends RefCounted
# Infuse: reactions pour charges into the weapon, a dash lets them out.
#
#   charges   each one remembers the reaction that made it. They are released as LAYERS: equal
#             charges merge into one stronger layer, different ones go off one after another.
#             Three equal = PURE (one big layer, wider, leaves the full field).
#             Three different = TRINITY (three layers, each with its own two aspects).
#   shape     the weapon decides it: a ring (melee), a lance (beam, chain), a fan of shots (rest).
#   perfect   dash through an enemy shot while carrying charges: more damage, one charge back,
#             a moment of slowed time.
#   chain     foes struck by one release are counted; three or more refill mana, five or more
#             give a charge back.
#   blessings inf_cap, inf_keep, inf_hold, inf_wide, inf_reap (see game.calc_stats).
#
# All numbers are in D.INF. Everything here is called with the hero bound (g.p).

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")

const WORD = {"ring": "SLASH", "lance": "LANCE", "fan": "VOLLEY", "lob": "MORTAR"}
# what each kind of weapon does with charges, told once
const RULE = {
	"melee": ["BLADE CHARGE", "REACTIONS RIGHT BESIDE YOU CHARGE TWICE. THE RELEASE IS A RING."],
	"beam": ["LENS CHARGE", "CHARGES LAST TWICE AS LONG. THE RELEASE IS A LANCE."],
	"chain": ["FORK CHARGE", "CHARGES LAST TWICE AS LONG. THE RELEASE IS A LANCE."],
	"lob": ["MORTAR CHARGE", "THE RELEASE LANDS WHERE YOU AIM. NO NEED TO DASH IN."],
	"bullet": ["HORN CHARGE", "THE RELEASE IS A VOLLEY, THEN YOU FIRE FASTER FOR A WHILE."],
}

static func wtype(p: Dictionary) -> String:
	return D.WEAPONS[p.weapons[p.wi].id].type

static func life(p: Dictionary) -> float:
	return D.INF.life * (D.INF.beam_life if wtype(p) in ["beam", "chain"] else 1.0)
const LANCE_OFF = [0.0, 0.2, -0.2, 0.4, -0.4]

static func cap(p: Dictionary) -> int:
	return int(p.get("st", {}).get("inf_max", D.INF.max))

# Charges grouped by reaction, in the order they were first poured.
static func layers_of(rel: Array) -> Array:
	var out = []
	for c in rel:
		var found = false
		for l in out:
			if l.key == c.key:
				l.k += 1
				found = true
				break
		if not found:
			out.append({key = c.key, col = c.get("col", Color.WHITE), k = 1})
	return out

# "pure", "trinity" or "".
static func shape(rel: Array) -> String:
	var l = layers_of(rel)
	if l.size() == 1 and l[0].k >= 3:
		return "pure"
	if l.size() >= 3:
		return "trinity"
	return ""

static func give(g, p: Dictionary, c: Dictionary) -> void:
	var inf: Array = p.get("inf", [])
	while inf.size() >= cap(p):
		inf.pop_front()
	inf.append({key = c.key, col = c.col})
	p.inf = inf
	p.inf_t = life(p)

static func add(g, key: String, col: Color, at = null) -> void:
	var p: Dictionary = g.p
	if not p.has("els"):
		return
	give(g, p, {key = key, col = col})
	g.tip("inf1", "WEAPON CHARGED", "HOLD THE ELEMENT BUTTON TO ARM IT, THEN DASH TO RELEASE." if g.tin.on else g.Pad.hint(g, "HOLD 1 2 3 TO ARM IT, THEN DASH (SPACE) TO RELEASE."))
	var wt = wtype(p)
	if RULE.has(wt):
		g.tip("w_" + wt, RULE[wt][0], RULE[wt][1])
	if g.rng.randf() < float(p.st.get("inf_twice", 0.0)) and p.inf.size() < cap(p):
		give(g, p, {key = key, col = col})
		g.label(p.pos + Vector2(0, -22), "ALCHEMY +1", col)
	if wt == "melee" and at != null and p.pos.distance_to(at) < D.INF.near and p.inf.size() < cap(p):
		# the risk of standing close pays twice
		give(g, p, {key = key, col = col})
		g.label(p.pos + Vector2(0, -22), "CLOSE +1", col)
	if p.inf.size() == cap(p):
		var sh = shape(p.inf)
		g.label(p.pos + Vector2(0, -30), {"pure": "PURE CHARGE", "trinity": "TRINITY CHARGE"}.get(sh, "FULL CHARGE"), Color("ffd24a"))
		Sfx.play("ui", 1.6)
		g.tip("inf", "FULL CHARGE", "ARM IT (HOLD THE ELEMENT), THEN DASH INTO THE FOES.")

static func tick(g, dt: float) -> void:
	var p: Dictionary = g.p
	if p.has("inf_ch") and g.time - float(p.inf_ch.t) > D.INF.chain_t:
		chain_end(g, p)
	if p.has("inf_arm"):
		p.inf_arm -= dt
		if p.inf_arm <= 0.0 or p.get("inf", []).is_empty():
			if p.inf_arm <= 0.0:
				g.label(p.pos + Vector2(0, -22), "UNARMED", Color("a8a7b8"))
			p.erase("inf_arm")
	if p.has("inf_rush"):
		p.inf_rush -= dt
		if p.inf_rush <= 0.0:
			p.erase("inf_rush")
	if p.get("inf", []).is_empty() or p.get("st", {}).get("inf_hold", false):
		return
	p.inf_t = float(p.get("inf_t", D.INF.life)) - dt
	if p.inf_t <= 0.0:
		p.inf.pop_front()
		p.inf_t = D.INF.fade

# A dash takes the charges; they burst out where it ends.
# Gathered mana arms the weapon: it empties the chosen element's pool, like a gathered cast.
static func arm(g) -> void:
	var p: Dictionary = g.p
	var i: int = p.eli
	if p.spent[i] or p.sat[i] < 0.1:
		g.label(p.pos + Vector2(0, -22), "NO MANA", Color("ff6a6a"))
		Sfx.play("deny")
		return
	var need = D.SAT.cast * D.SAT.base / maxf(1.0, float(p.men))
	p.inf_pow = 0.7 + 0.3 * clampf(p.sat[i] / need, 0.3, D.SAT.cast_max)
	if p.st.get("inf_thrift", false):
		p.sat[i] *= 0.5
		p.spent[i] = p.sat[i] < D.SAT.back
	else:
		p.sat[i] = 0.0
		p.spent[i] = true
	g.mana_total(p)
	p.inf_arm = D.INF.arm * float(p.st.get("inf_armx", 1.0))
	g.label(p.pos + Vector2(0, -30), "ARMED", Color("ffd24a"), true)
	g.rings.append({pos = g.pcenter(), r = 22.0, t = 0.0, col = Color("ffd24a")})
	Sfx.play("arm")
	g.tip("arm", "ARMED", "DASH NOW: THE CHARGES BURST OUT WHERE THE DASH ENDS.")

static func take(g) -> void:
	var p: Dictionary = g.p
	if p.get("inf", []).is_empty() or float(p.get("inf_arm", 0.0)) <= 0.0:
		return
	p.erase("inf_arm")
	p.inf_rel = p.inf
	p.inf_from = p.pos
	p.inf = []
	p.inf_perf = false
	p.inv = maxf(p.inv, 0.25)

# Called every frame of a charged dash: passing through an enemy shot makes it perfect.
static func graze(g) -> void:
	var p: Dictionary = g.p
	if not p.has("inf_rel") or p.get("inf_perf", false):
		return
	var pc: Vector2 = g.pcenter()
	for b in g.bullets:
		if b.team == 1 and not b.dead and b.pos.distance_squared_to(pc) < pow(D.INF.graze * float(p.st.get("inf_graze", 1.0)), 2.0):
			p.inf_perf = true
			g.burst(b.pos, 6, Color.WHITE, 70.0, 0.25)
			return

static func release(g) -> void:
	var p: Dictionary = g.p
	var rel: Array = p.inf_rel
	p.erase("inf_rel")
	var n = rel.size()
	if n == 0:
		return
	var perfect: bool = p.get("inf_perf", false)
	p.erase("inf_perf")
	var layers = layers_of(rel)
	var sh = shape(rel)
	var wi = p.weapons[p.wi]
	var kind = "fan"
	match D.WEAPONS[wi.id].type:
		"melee": kind = "ring"
		"beam", "chain": kind = "lance"
		"lob": kind = "lob"
	var base: float = (D.INF.dmg + D.INF.per_floor * g.floor_i) * g.st.react * g.Ext.wdmg(wi)
	base *= float(p.get("inf_pow", 1.0))
	base *= float(p.st.get("inf_dmg", 1.0))
	if perfect:
		base *= D.INF.perfect
	if sh == "trinity":
		base *= D.INF.trinity
	var pc: Vector2 = g.pcenter()
	var dir: Vector2 = p.dash_dir.normalized() if p.dash_dir != Vector2.ZERO else Vector2.RIGHT
	var from: Vector2 = p.get("inf_from", p.pos)
	var to: Vector2 = p.pos + dir * (10.0 + 10.0 * n)
	var wait = 0.0
	if kind == "lob":
		# a lobbed weapon drops the release where you aim
		pc += (g.mworld() - pc).limit_length(D.INF.lob_range)
		from = pc - dir * 22.0
		to = pc + dir * 22.0
		wait = D.INF.lob_wait
		g.tele_circle(pc, D.INF.radius + 14.0 * n, wait)
	elif kind == "fan":
		p.inf_rush = D.INF.rush * n
	g.lit_t = D.STAGE.lit
	var wide: float = p.st.get("inf_wide", 1.0)
	var last: Dictionary = rel[n - 1]
	p.inf_ch = {ids = [], t = g.time, key = last.key, col = last.col, reaped = false}
	for i in layers.size():
		var l: Dictionary = layers[i]
		if i == 0 and wait <= 0.0:
			layer(g, p, l, i, n, kind, base, pc, dir, wide, sh)
		else:
			g.after(wait + D.INF.gap * i, func(): layer(g, p, l, i, n, kind, base, pc, dir, wide, sh))
		if l.key != "":
			# the dash leaves its reactions along the way: fire and water, a strip of steam
			g.Combo.trail(g, from.lerp(to, float(i) / layers.size()), from.lerp(to, float(i + 1) / layers.size()), l.key, l.k)
	if sh == "trinity" and p.st.get("inf_echo", false):
		# the third eye: the first layer comes round again
		var l0: Dictionary = layers[0]
		var ni = layers.size()
		g.after(wait + D.INF.gap * ni, func(): layer(g, p, l0, ni, n, kind, base, pc, dir, wide, sh))
	if sh == "pure" and p.st.get("inf_heal", false) and p.hp < p.mhp:
		p.hp += 1
		g.label(p.pos + Vector2(0, -22), "+1", Color("a6e84e"))
	g.tally("rel")
	if sh != "":
		g.tally(sh)
	if sh == "pure" and last.key != "":
		g.Combo.spawn(g, pc + dir * 20.0, last.key)
	var txt: String
	if sh == "pure":
		txt = "PURE " + (str(D.REACT[last.key][0]) if last.key != "" else "CHARGE")
	elif sh == "trinity":
		txt = "TRINITY " + WORD[kind]
	elif layers.size() == 2:
		txt = "DOUBLE " + WORD[kind]
	else:
		txt = ("INFUSE" if last.key == "" else str(D.REACT[last.key][0])) + " " + WORD[kind]
	var big = sh != "" or n >= cap(p)
	g.label(pc + Vector2(0, -28), txt, Color("ffd24a") if big else Color.WHITE, true)
	var col: Color = last.col
	g.burst(pc, 10 + 6 * n, col, 120.0 + 30.0 * n, 0.4)
	g.burst(pc, 6, Color.WHITE, 80.0, 0.25)
	g.flash(pc, 80.0 + 30.0 * n, col, 0.35)
	g.hitstop = maxf(g.hitstop, 0.02 + 0.02 * n)
	g.shake_add(2.0 + 2.0 * n)
	g.cam_kick(dir * (2.0 + 1.5 * n))
	Sfx.play("boom", 1.3 - 0.1 * n, -2.0)
	g.charge_res(0.3 * n)
	# what comes back
	if p.st.get("inf_keep", false):
		give(g, p, last)
	if perfect:
		give(g, p, rel[0])
		g.slowmo = D.INF.slow
		g.tally("perf")
		g.label(pc + Vector2(0, -40), "PERFECT", Color("7adfff"), true)
		Sfx.play("fx_radiance", 1.4)
		g.tip("perf", "PERFECT", "DASH THROUGH A SHOT WHILE CHARGED: MORE DAMAGE, ONE CHARGE BACK.")

# One layer of a release: its damage, both aspects of its reaction, and its picture.
static func layer(g, p: Dictionary, l: Dictionary, i: int, n: int, kind: String, base: float, pc: Vector2, dir: Vector2, wide: float, sh: String) -> void:
	var pure = sh == "pure"
	var els: Array = Array(l.key.split("+")) if l.key != "" else []
	var dmg: float = base * (1.0 + D.INF.same * (l.k - 1))
	var hit = []
	var reach = 26.0
	var ang = dir.angle()
	match kind:
		"ring", "lob":
			# rings spread outward, one beyond the other
			reach = (D.INF.radius + 14.0 * n) * wide * (1.0 + 0.18 * i) * (1.25 if pure else 1.0)
			for e in g.enemies:
				if not e.dead and g.center(e).distance_to(pc) < reach + e.hr:
					hit.append(e)
		"lance":
			# lances fork: straight on, then to either side
			ang += LANCE_OFF[mini(i, LANCE_OFF.size() - 1)]
			reach = (150.0 + 40.0 * n) * wide
			var far: Vector2 = pc + Vector2.from_angle(ang) * reach
			var half = (10.0 + 4.0 * l.k) * (1.4 if pure else 1.0)
			for e in g.enemies:
				if not e.dead and Geometry2D.get_closest_point_to_segment(g.center(e), pc, far).distance_to(g.center(e)) < half + e.hr:
					hit.append(e)
			g.bolts.append({a = pc, b = far, col = l.col, t = 0.35, straight = true})
			g.bolts.append({a = pc, b = far, col = Color.WHITE, t = 0.18, straight = true})
		_:
			# a fan of heavy shots; later layers fly a little slower, so they arrive as waves
			var k = 1 + 2 * l.k + (2 if pure else 0)
			for j in k:
				var a = ang + (j - (k - 1) / 2.0) * 0.22
				g.add_bullet(pc + dir * 8.0, Vector2.from_angle(a) * (260.0 - 30.0 * i), {dmg = dmg * 0.6, el = "", r = 4.0, life = 1.0, aoe = (20.0 + 6.0 * n) * wide, kind = "orb", inf = els, inf_sh = sh})
	g.full_hit = true
	g.rel_hit = true
	g.rel_shape = sh
	var killed = false
	for e in hit:
		g.hurt_enemy(e, dmg, "", (g.center(e) - pc).normalized() * 200.0, true, l.col)
		if not e.dead and not e.is_boss:
			e.stun = maxf(e.stun, 0.2 * n)
		for el in els:
			g.Chem.touch(g, e, el, dmg * 0.5, pc, D.EL_COL[el])
		killed = killed or e.dead
		chain_hit(g, p, e)
		g.Pfx.spawn(g, "hit", g.center(e), e.hr + 8.0)
	g.full_hit = false
	g.rel_hit = false
	g.rel_shape = ""
	var dv = Vector2.from_angle(ang)
	for j in els.size():
		# each element brings its own effect: frost blooms, fire rings, lightning hops...
		var fx: String = g.Pfx.of(g, els[j])
		if kind == "lance":
			g.Pfx.spawn(g, fx, pc + dv * reach * (0.3 + 0.4 * j), 34.0, ang)
		elif kind == "fan":
			g.Pfx.spawn(g, fx, pc + dv * 14.0, 26.0, ang)
		else:
			g.Pfx.spawn(g, fx, pc, reach * (1.0 if j == 0 else 0.7), ang)
	note(g, p, kind, l.key)
	g.infx.append({pos = pc, ang = ang, kind = "ring" if kind == "lob" else kind, r = reach, t = 0.0, a = els[0] if els.size() > 0 else "", b = els[1] if els.size() > 1 else "", n = mini(n, 3), col = l.col})
	for el in els:
		g.burst(pc, 8, D.EL_COL[el], 110.0, 0.45)
	if i > 0:
		Sfx.play("boom", 1.3 + 0.15 * i, -5.0)
		g.shake_add(1.5)
	if killed:
		reap(g, p, l)

# The reaping blessing: a release that kills pours one charge back (once per release).
static func reap(g, p: Dictionary, l: Dictionary) -> void:
	if not p.st.get("inf_reap", false) or not p.has("inf_ch") or p.inf_ch.reaped:
		return
	p.inf_ch.reaped = true
	give(g, p, l)
	g.label(p.pos + Vector2(0, -22), "REAPED", l.col)

# A foe struck by the release in flight (ring, lance or one of its shots).
static func chain_hit(g, p: Dictionary, e: Dictionary) -> void:
	if not p.has("inf_ch") or p.inf_ch.ids.has(e.uid):
		return
	p.inf_ch.ids.append(e.uid)
	p.inf_ch.t = g.time
	if e.dead:
		reap(g, p, {key = p.inf_ch.key, col = p.inf_ch.col})

static func chain_end(g, p: Dictionary) -> void:
	var ch: Dictionary = p.inf_ch
	p.erase("inf_ch")
	var n: int = ch.ids.size()
	var cmin = int(p.get("st", {}).get("inf_chain", D.INF.chain_min))
	g.tally("chain", n, true)
	if n < cmin:
		return
	var txt = "CHAIN X%d" % n
	if p.has("sat"):
		for i in 3:
			p.sat[i] = minf(1.0, p.sat[i] + D.INF.chain_mana * (n - cmin + 1))
			if p.spent[i] and p.sat[i] >= D.SAT.back:
				p.spent[i] = false
		g.mana_total(p)
	if n >= D.INF.chain_charge:
		give(g, p, ch)
		txt += " +CHARGE"
	g.label(p.pos + Vector2(0, -36), txt, Color("ffd24a") if n >= D.INF.chain_charge else Color("7adfff"), true)
	Sfx.play("pick", 1.0 + 0.06 * mini(n, 8))
	g.tip("chain", "CHAIN", "ONE RELEASE THAT STRIKES THREE FOES REFILLS MANA. FIVE GIVE A CHARGE BACK.")

# The notebook of releases: every new pairing of a reaction and a weapon shape is written down
# (one gem), and every tenth of one shape pays more.
static func note(g, p: Dictionary, kind: String, key: String) -> void:
	if key == "" or g.in_lobby:
		return
	var Meta = g.Meta
	var book: Dictionary = Meta.S.get("rels", {})
	var id = kind + ":" + key
	if book.has(id):
		return
	book[id] = true
	g.tally("new")
	Meta.S["rels"] = book
	Meta.S.gems += 1
	var n = 0
	for k in book:
		if k.begins_with(kind + ":"):
			n += 1
	g.label(p.pos + Vector2(0, -48), "NEW RELEASE  %d FOUND" % book.size(), Color("a6e84e"))
	if n % 10 == 0:
		Meta.S.gems += 25
		g.banner = {text = "%d %sS FOUND" % [n, WORD[kind]], sub = "+25 GEMS", t = 2.6}
		Sfx.play("pick", 1.4)
