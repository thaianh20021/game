extends RefCounted
# Weapon mechanics beyond damage: five traits a fused weapon can carry (owner, 2026-11-16).
#
#   charge  GATHERING   hold fire to gather, let go: one shot of up to "charge_mult" more damage
#   summon  SPIRITS     every "summon_n"th hit calls a spirit that flies with you and shoots
#   rally   RALLY       hits stack (up to "rally_max"): more damage and a faster fire rate
#   hex     HEXING      hits hex the foe: it takes more damage (the game's "vuln") for a while
#   heavy   WEIGHT      fires "heavy_cd" times slower, hits "heavy_dmg" times as hard, and pushes
#
# Numbers are in D.WMOD; names and card text in Arms.TRAIT_NAME / TRAIT_DESC. Everything here
# runs on the host with the hero bound (g.p).

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")

const NEW = ["charge", "summon", "rally", "hex", "heavy"]

static func has(p: Dictionary, tr: String) -> bool:
	if p.is_empty() or p.weapons[p.wi] == null:
		return false
	var w: Dictionary = p.weapons[p.wi]
	return w.get("trait", "") == tr or w.get("traits", []).has(tr)

# ---- gathering -------------------------------------------------------------------

# Takes over the fire button for a gathering weapon. Returns true when it did.
static func held(g, dt: float) -> bool:
	var p: Dictionary = g.p
	if not has(p, "charge"):
		p.erase("wchg")
		return false
	if g.firing() and p.spin <= 0.0:
		var was: float = p.get("wchg", 0.0)
		p.wchg = minf(D.WMOD.charge_max, was + dt)
		if p.wchg >= D.WMOD.charge_max and was < D.WMOD.charge_max:
			Sfx.play("arm", 1.5)
			g.rings.append({pos = g.pcenter(), r = 14.0, t = 0.0, col = Color.WHITE})
		return true
	var k: float = p.get("wchg", 0.0)
	p.erase("wchg")
	if k > 0.06 and p.cd <= 0.0:
		p.wk = k / D.WMOD.charge_max
		g.try_fire()
		p.erase("wk")
		g.shake_add(1.0 + 3.0 * k)
	return true

# Called by try_fire on the private copy of the weapon about to fire.
static func shape_shot(g, w: Dictionary) -> void:
	var p: Dictionary = g.p
	if p.has("wk"):
		var k: float = p.wk
		w.dmg *= 1.0 + D.WMOD.charge_mult * k
		w.r = maxf(float(w.get("r", 2)), 2.0 + 3.0 * k)
		w.pierce = int(w.get("pierce", 0)) + int(2.0 * k)
		if w.type == "melee":
			w.range = float(w.range) * (1.0 + 0.4 * k)
		p.cd *= 1.0 + k
	var n = int(p.get("rally", 0))
	if n > 0 and has(p, "rally"):
		w.dmg *= 1.0 + D.WMOD.rally_step * n
		p.cd /= 1.0 + D.WMOD.rally_step * n
	if has(p, "heavy"):
		p.cd *= D.WMOD.heavy_cd

# ---- on hit ----------------------------------------------------------------------

# A direct hit of the hero's weapon landed on e.
static func on_hit(g, e: Dictionary) -> void:
	var p: Dictionary = g.p
	if p.is_empty() or not p.has("weapons") or e.dead:
		return
	if has(p, "hex"):
		var fresh = float(e.get("hex", 0.0)) <= 0.0
		e.hex = D.WMOD.hex_t
		e.vuln = maxf(e.vuln, D.WMOD.hex_t)
		if fresh:
			g.Pfx.spawn(g, "hex", g.center(e) + Vector2(0, -e.h2 - 4.0), 10.0)
			g.tip("hex", "HEXED", "A HEXED FOE TAKES 50% MORE FROM EVERYTHING.")
	if has(p, "heavy") and not e.is_boss:
		e.kb += (g.center(e) - g.pcenter()).normalized() * D.WMOD.heavy_kb
	if has(p, "rally"):
		var was = int(p.get("rally", 0))
		p.rally = mini(D.WMOD.rally_max, was + 1)
		p.rally_t = D.WMOD.rally_t
		if p.rally == D.WMOD.rally_max and was < D.WMOD.rally_max:
			g.Pfx.spawn(g, "bless", p.pos, 16.0)
			g.label(p.pos + Vector2(0, -26), "RALLIED", Color("ffd24a"))
	if has(p, "summon"):
		p.sum_n = int(p.get("sum_n", 0)) + 1
		if p.sum_n >= D.WMOD.summon_n:
			p.sum_n = 0
			summon(g, p)

static func summon(g, p: Dictionary) -> void:
	var mine = g.spirits.filter(func(s): return s.own == int(p.get("idx", 0)))
	if mine.size() >= D.WMOD.spirit_max:
		# the oldest makes room
		g.spirits.erase(mine[0])
	var w: Dictionary = p.weapons[p.wi]
	var el: String = w.el if D.EL_COL.has(w.el) and w.el != "" and w.el != "prism" else ""
	var at: Vector2 = p.pos + Vector2(0, -14)
	g.spirits.append({pos = at, t = D.WMOD.spirit_t, cd = 0.3, el = el, own = int(p.get("idx", 0)), seed = g.rng.randf() * TAU})
	g.Pfx.spawn(g, "summon", p.pos, 14.0)
	g.tip("summon", "SPIRIT", "EVERY EIGHTH HIT CALLS A SPIRIT THAT FIGHTS BESIDE YOU.")

# ---- per frame -------------------------------------------------------------------

static func update(g, dt: float) -> void:
	for pl in g.players:
		if pl.has("rally_t"):
			pl.rally_t -= dt
			if pl.rally_t <= 0.0:
				pl.erase("rally_t")
				pl.rally = 0
	for e in g.enemies:
		if e.has("hex"):
			e.hex -= dt
			if e.hex <= 0.0:
				e.erase("hex")
	if g.spirits.is_empty():
		return
	var keep = []
	for s in g.spirits:
		s.t -= dt
		if s.t <= 0.0:
			g.burst(s.pos, 6, D.EL_COL[s.el] if s.el != "" else Color.WHITE, 50.0, 0.3)
			continue
		keep.append(s)
		var owner: Dictionary = g.players[mini(int(s.own), g.players.size() - 1)]
		var want: Vector2 = owner.pos + Vector2(cos(g.time * 2.2 + s.seed) * 18.0, -14.0 + sin(g.time * 2.2 + s.seed) * 7.0)
		s.pos = s.pos.lerp(want, minf(1.0, dt * 6.0))
		s.cd -= dt
		if s.cd <= 0.0:
			var e = g.nearest_enemy(s.pos, D.WMOD.spirit_r, [])
			if e != null:
				s.cd = D.WMOD.spirit_cd
				var dir: Vector2 = (g.center(e) - s.pos).normalized()
				g.add_bullet(s.pos, dir * 240.0, {dmg = D.WMOD.spirit_dmg + D.WMOD.spirit_floor * g.floor_i, el = s.el, r = 2.5, life = 1.0, kind = "orb", homing = 2.0})
	g.spirits = keep

static func draw(g, ci: CanvasItem) -> void:
	for s in g.spirits:
		var c: Color = D.EL_COL[s.el] if s.el != "" else Color("e6e2ff")
		var a = clampf(s.t, 0.0, 1.0)
		var flap = sin(g.time * 18.0 + s.seed) * 2.0
		var p: Vector2 = s.pos.round()
		ci.draw_line(p + Vector2(-2, 0), p + Vector2(-6, -2 - flap), Color(1, 1, 1, 0.7 * a), 1.0)
		ci.draw_line(p + Vector2(2, 0), p + Vector2(6, -2 - flap), Color(1, 1, 1, 0.7 * a), 1.0)
		ci.draw_circle(p, 3.0, Color(c.r, c.g, c.b, 0.85 * a))
		ci.draw_circle(p, 1.5, Color(1, 1, 1, a))
	for pl in g.players:
		var k: float = pl.get("wchg", 0.0)
		if k > 0.0:
			# a gathering weapon: a ring that closes as it fills, white when full
			var full = k >= D.WMOD.charge_max
			var c2: Vector2 = pl.pos + Vector2(0, -6)
			ci.draw_arc(c2, 12.0, -PI / 2.0, -PI / 2.0 + TAU * k / D.WMOD.charge_max, 20, Color.WHITE if full else Color("ffd24a"), 2.0)
			if full and int(g.time * 12.0) % 2 == 0:
				ci.draw_arc(c2, 15.0, 0.0, TAU, 20, Color(1, 1, 1, 0.6), 1.0)
		var n = int(pl.get("rally", 0))
		for i in n:
			ci.draw_rect(Rect2(pl.pos + Vector2(-n * 2.0 + i * 4.0, 8), Vector2(3, 2)), Color("ffd24a"))
