extends RefCounted
# Three things that make the player look before painting:
#   eaters   some foes feed on one of the elements you carry (it grows, splits or heals)
#   echo     a boss absorbs the first three-element effect that touches it and casts it back
#   shards   a strange element lying on a floor replaces your third slot until the floor ends

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")
const Px = preload("res://src/font.gd")

# ---- eaters ----------------------------------------------------------------------

const EAT = {
	"grow": ["GROWS ON", 3], "split": ["SPLITS ON", 1], "feed": ["HEALS IN", 6],
}
const EAT_CHANCE = 0.22

# Called for every ordinary foe that spawns in a locked room.
static func mark(g, e: Dictionary) -> void:
	if g.floor_i < 1 or e.is_boss or e.elite or e.d.ai == "dummy" or g.rng.randf() > EAT_CHANCE or not g.p.has("els"):
		return
	e.eats = g.p.els[g.rng.randi() % g.p.els.size()]
	e.eat_kind = EAT.keys()[g.rng.randi() % EAT.size()]
	e.eat_n = int(EAT[e.eat_kind][1])

static func sated(g, e: Dictionary) -> void:
	e.eat_n = int(e.eat_n) - 1
	if e.eat_n <= 0:
		e.erase("eats")
		g.label(g.center(e) + Vector2(0, -e.h2 - 14.0), "FULL", Color("a8a7b8"))

# The damage a hit really does. Direct hits of the eaten element feed the foe instead.
static func amount(g, e: Dictionary, amt: float, el: String, dot: bool) -> float:
	if dot or el == "" or e.get("eats", "") != el or e.eat_kind == "feed":
		return amt
	var col: Color = D.EL_COL[el]
	g.tip("eater", "IT EATS " + D.EL_NAME[el], "LOOK AT THE MARK OVER A FOE. PAINT IT WITH SOMETHING ELSE.")
	if e.eat_kind == "grow":
		e.hp = minf(e.mhp * 1.6, e.hp + e.mhp * 0.2)
		e.sc *= 1.12
		e.h2 *= 1.12
		e.hr *= 1.12
		e.r *= 1.06
		e.rage = float(e.get("rage", 1.0)) * 1.15
		g.label(g.center(e) + Vector2(0, -e.h2 - 14.0), "FED!", col)
		g.rings.append({pos = g.center(e), r = 18.0, t = 0.0, col = col})
		Sfx.play("deny", 0.7)
		sated(g, e)
		return 0.0
	# split: two smaller ones, each with what was left
	var pos: Vector2 = e.pos
	var hp: float = maxf(4.0, e.hp * 0.6)
	e.erase("eats")
	e.hp = hp
	e.mhp = maxf(hp, e.mhp * 0.6)
	e.sc *= 0.8
	e.h2 *= 0.8
	e.hr *= 0.8
	g.label(g.center(e) + Vector2(0, -e.h2 - 14.0), "SPLIT!", col)
	Sfx.play("deny", 1.3)
	g.after(0.05, func():
		if g.lock == null:
			return
		var o = g.spawn_enemy(e.id, pos + Vector2(g.rng.randf_range(-10, 10), g.rng.randf_range(-6, 6)))
		o.hp = hp
		o.mhp = e.mhp
		o.sc = e.sc
		o.h2 = e.h2
		o.hr = e.hr
		o.el = e.el
		g.burst(pos, 8, col, 70.0, 0.4))
	return 0.0

# ---- per frame -------------------------------------------------------------------

static func update(g, dt: float) -> void:
	if g.in_lobby:
		return
	g.twist_t -= dt
	if g.twist_t <= 0.0:
		g.twist_t = 0.5
		for e in g.enemies:
			if e.dead or e.get("eats", "") == "" or e.eat_kind != "feed" or e.hp >= e.mhp:
				continue
			var fed = false
			for f in g.fields:
				if f.life > 0.0 and f.els.has(e.eats) and g.center(e).distance_to(f.pos) < f.r + e.hr:
					fed = true
			for z in g.zones:
				if z.team == 0 and z.life > 0.0 and z.el == e.eats and e.pos.distance_to(z.pos) < z.r + e.hr:
					fed = true
			if fed:
				e.hp = minf(e.mhp, e.hp + e.mhp * 0.12)
				g.label(g.center(e) + Vector2(0, -e.h2 - 14.0), "HEALS", D.EL_COL[e.eats])
				g.tip("eater", "IT EATS " + D.EL_NAME[e.eats], "LOOK AT THE MARK OVER A FOE. PAINT IT WITH SOMETHING ELSE.")
				sated(g, e)
	echo_update(g, dt)

# ---- boss echo -------------------------------------------------------------------

const FAMILY = {
	"ring": ["fire", "earth", "metal", "s_ice"],
	"fall": ["stone", "bolt", "mech", "wood", "s_tox"],
	"fan": ["ice", "light", "water", "s_fire"],
	"pool": ["tox", "void", "leaf", "wind", "s_bolt"],
}

static func echo_update(g, dt: float) -> void:
	var b = g.boss
	if b == null or b.dead:
		return
	if not b.has("echo"):
		for f in g.fields:
			if f.tier == 3 and f.life > 0.0 and g.center(b).distance_to(f.pos) < f.r + b.hr + 24.0:
				var id: String = f.get("form", "s_" + str(f.key))
				var fam = "ring"
				for k in FAMILY:
					if FAMILY[k].has(id):
						fam = k
				var el = ""
				for q in f.els:
					if D.EL.has(q):
						el = q
				b.echo = {fam = fam, el = el, t = 3.5, name = g.Combo.name_of(f), col = g.Combo.col_of(f)}
				g.banner = {text = "IT LEARNS " + b.echo.name, sub = "THE BOSS WILL CAST YOUR OWN WEATHER BACK AT YOU", t = 3.4}
				g.rings.append({pos = g.center(b), r = 60.0, t = 0.0, col = b.echo.col})
				g.flash(g.center(b), 160.0, b.echo.col, 0.5)
				Sfx.play("roar", 1.3)
				return
		return
	var ec = b.echo
	ec.t -= dt
	if ec.t > 0.0 or b.frz > 0.0 or b.stun > 0.0:
		return
	ec.t = 6.0
	var c: Vector2 = g.center(b)
	var at: Vector2 = g.p.pos
	g.label(c + Vector2(0, -b.h2 - 20.0), ec.name, ec.col, true)
	Sfx.play("roar", 1.6, -4.0)
	match ec.fam:
		"ring":
			for k in 3:
				g.after(k * 0.45, func():
					if not b.dead:
						g.ring(g.center(b), 12, 70.0 + k * 14.0, ec.el, k * 0.26))
		"fan":
			var a0: float = (at - c).angle()
			for i in 6:
				g.fan(c, Vector2.from_angle(a0 + i * TAU / 6.0), 3, 0.24, 105.0, ec.el)
		"fall":
			for k in 5:
				var q: Vector2 = at + (Vector2.ZERO if k == 0 else Vector2.from_angle(g.rng.randf() * TAU) * g.rng.randf_range(24.0, 64.0))
				g.after(k * 0.22, func():
					g.tele_circle(q, 22.0, 0.75)
					g.after(0.75, func(): g.explode(q, 22.0, 1.0, ec.el, 1, ec.col)))
		"pool":
			g.tele_circle(at, 34.0, 0.8)
			g.after(0.8, func():
				g.zones.append({pos = at, r = 34.0, el = ec.el if ec.el != "" else "tox", life = 4.5, team = 1, tick = 0.3})
				g.rings.append({pos = at, r = 34.0, t = 0.0, col = ec.col}))

# ---- shards ----------------------------------------------------------------------

static func floor_start(g) -> void:
	for pl in g.players:
		if pl.has("els_home"):
			pl.els = pl.els_home
			pl.erase("els_home")
	if g.floor_i < 1 or g.rng.randf() > 0.5 or not g.p.has("els"):
		return
	var rooms = g.dg.rooms.filter(func(r): return r.type == "fight")
	if rooms.is_empty():
		return
	var pool = D.ALL.filter(func(q): return not g.p.els.has(q))
	var el: String = pool[g.rng.randi() % pool.size()]
	var r = rooms[g.rng.randi() % rooms.size()]
	g.inter.append({kind = "shard", el = el, spr = "crystal_" + el, name = "", pos = g.random_room_pos(r, 30.0)})

static func take_shard(g, it: Dictionary) -> void:
	var p = g.p
	if not p.has("els"):
		return
	it.gone = true
	if not p.has("els_home"):
		p.els_home = p.els.duplicate()
	p.els = p.els.duplicate()
	p.els[2] = it.el
	g.sat_init(p)
	p.sat[2] = 1.0
	p.spent[2] = false
	g.mana_total(p)
	var col: Color = D.EL_COL[it.el]
	g.banner = {text = D.EL_NAME[it.el] + " SHARD", sub = "YOUR THIRD ELEMENT IS " + D.EL_NAME[it.el] + " UNTIL THIS FLOOR ENDS", t = 3.4}
	g.rings.append({pos = g.pcenter(), r = 30.0, t = 0.0, col = col})
	g.burst(it.pos, 14, col, 90.0, 0.6)
	Sfx.play("chest", 1.2)

# ---- drawing ---------------------------------------------------------------------

# The mark over a foe that eats an element: its icon in a toothed frame.
static func draw_foe(g, ci: CanvasItem, e: Dictionary, topy: float) -> void:
	var el: String = e.get("eats", "")
	if el == "":
		return
	var col: Color = D.EL_COL[el]
	var at = Vector2(roundf(e.pos.x) - 5.0, roundf(topy - 24.0 + sin(g.time * 5.0 + e.uid) * 1.0))
	ci.draw_rect(Rect2(at, Vector2(11, 11)), Color(0.05, 0.02, 0.06, 0.9))
	ci.draw_rect(Rect2(at, Vector2(11, 11)), Color("ff4a5e"), false, 1.0)
	for i in 3:
		ci.draw_rect(Rect2(at + Vector2(1 + i * 4, 11), Vector2(2, 2)), Color("ff4a5e"))
	ci.draw_texture(g.Art.T["ic_" + el], at + Vector2(2, 2))
	ci.draw_arc(e.pos + Vector2(0, e.r - 1.0), e.r * 1.7 + sin(g.time * 6.0), 0.0, TAU, 16, Color(col.r, col.g, col.b, 0.7), 1.0)

