extends RefCounted
# The dungeon's memory of you.
#
# Nemesis: whatever kills you gets a name, grows stronger, learns to resist the element you
# leaned on, and waits in a later run. When you meet, it tells you how you died. Beat it and
# it yields: finish it for gems and a relic, or spare it and it will fight beside you in
# your next boss battles.
# Graves: where a run ended, a grave stands on that floor in later runs, holding the weapon
# you carried and seeping your favourite element until you take the weapon back.

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")

const NAME_A = ["GRUK", "VASH", "MORL", "SKAR", "THUN", "ZEK", "BRAK", "OLM", "YIR", "DRUN", "KHEL", "NASK"]
const NAME_B = ["THE PATIENT", "WHO REMEMBERS", "THE UNBURNT", "OF THE LONG GRUDGE", "THE STUBBORN", "WHO WAITS", "THE SCARRED", "KINGSLAYER"]
const TAUNT = {
	"dry": "LAST TIME YOUR ENERGY RAN OUT. I WATCHED IT HAPPEN.",
	"greedy": "YOU DIED WITH YOUR POCKETS FULL OF GOLD. I KEPT IT.",
	"hasty": "YOU RUSHED IN LAST TIME. PLEASE, RUSH AGAIN.",
	"close": "YOU LET ME GET CLOSE. YOU WILL AGAIN.",
	"shot": "MY SHOT FOUND YOU ONCE. IT KNOWS THE WAY NOW.",
}

static func current() -> Dictionary:
	var n = Meta.S.get("nemesis", {})
	return n if (n is Dictionary and n.has("id") and D.ENEMIES.has(n.id)) else {}

static func favourite(g) -> String:
	var fav = ""
	var most = 0
	for el in g.el_use:
		if int(g.el_use[el]) > most:
			most = int(g.el_use[el])
			fav = el
	return fav

# Called when a run ends in death.
static func on_death(g) -> void:
	var killer = null
	var bd = INF
	for e in g.enemies:
		if e.dead or e.d.ai == "dummy":
			continue
		var d = e.pos.distance_to(g.p.pos) * (0.3 if e.is_boss else 1.0) * (0.2 if e.get("nem", false) else 1.0)
		if d < bd:
			bd = d
			killer = e
	if killer == null:
		return
	var how = "shot"
	if g.p.en < 10.0:
		how = "dry"
	elif g.p.gold >= 60:
		how = "greedy"
	elif g.run_time < 150.0:
		how = "hasty"
	elif killer.pos.distance_to(g.p.pos) < 20.0:
		how = "close"
	var fav = favourite(g)
	var old = current()
	if killer.get("nem", false) and not old.is_empty():
		old.lv = int(old.lv) + 1
		old.floor = g.floor_i
		old.how = how
		if fav != "":
			old.el = fav
		Meta.S.nemesis = old
	else:
		Meta.S.nemesis = {id = killer.id, name = NAME_A[g.rng.randi() % NAME_A.size()] + " " + NAME_B[g.rng.randi() % NAME_B.size()],
			el = fav, lv = 1, floor = g.floor_i, boss = killer.is_boss, how = how}

static func title(n: Dictionary) -> String:
	return str(n.name) + (" " + "I".repeat(mini(int(n.lv), 3)) if int(n.lv) > 1 else "")

# Decide where it waits on this floor.
static func plan(g) -> void:
	var n = current()
	if n.is_empty() or g.nem_met:
		return
	var bi = g.floor_i / 2
	if bool(n.boss):
		if g.floor_i % 2 == 1 and D.BIOMES[bi].bosses.has(n.id) and g.floor_i >= int(n.floor):
			g.dg.boss_id = n.id
			g.dg.nem_boss = true
		return
	if g.floor_i < mini(int(n.floor), 4):
		return
	for r in g.dg.rooms:
		if r.type == "fight":
			r.nemesis = true
			return

static func empower(g, e: Dictionary) -> void:
	var n = current()
	g.nem_met = true
	e.nem = true
	e.nem_name = title(n)
	var k = 1.0 + 0.5 * int(n.lv)
	if not e.is_boss:
		e.elite = true
		e.smart = true
		e.mhp *= 3.0 * k
		e.sc *= 1.5
		e.h2 *= 1.5
		e.hr *= 1.5
	else:
		e.mhp *= 1.0 + 0.25 * int(n.lv)
	e.hp = e.mhp
	if str(n.el) != "":
		e.el = n.el
	# it greets you with the way you died
	g.banner = {text = e.nem_name, sub = TAUNT.get(str(n.get("how", "shot")), TAUNT["shot"]), t = 5.0}
	if str(n.el) != "":
		g.after(1.5, func():
			if not e.dead:
				g.label(g.center(e) + Vector2(0, -e.h2 - 26.0), "I HAVE LEARNED YOUR " + D.EL_NAME[n.el], D.EL_COL[n.el]))
	Sfx.play("roar", 0.7)
	g.shake_add(6.0)

static func spawn(g, r: Dictionary) -> void:
	var n = current()
	var pos: Vector2 = g.random_room_pos(r, 70.0)
	g.pending += 1
	g.teles.append({kind = "circle", pos = pos, t = 0.0, dur = 1.2, r = 16.0})
	g.after(1.2, func():
		g.pending -= 1
		empower(g, g.spawn_enemy(n.id, pos)))

# ---- mercy -----------------------------------------------------------------------

# Called when a foe would die. A beaten nemesis kneels instead, once.
static func try_yield(g, e: Dictionary) -> bool:
	if not e.get("nem", false) or e.is_boss or e.get("yielded", false):
		return false
	e.yielded = true
	e.hp = 1.0
	e.stun = 99999.0
	e.mercy = g.time + 2.5
	e.st = {}
	e.kb = Vector2.ZERO
	g.inter.append({kind = "spare", pos = e.pos, uid = e.uid, name = e.nem_name})
	g.banner = {text = e.nem_name + " YIELDS", sub = "E: SPARE IT AND IT WILL OWE YOU. OR FINISH IT.", t = 5.0}
	g.rings.append({pos = g.center(e), r = 30.0, t = 0.0, col = Color.WHITE})
	Sfx.play("door", 0.7)
	for b in g.bullets:
		if b.team == 1:
			b.dead = true
	return true

static func spare(g, it: Dictionary) -> void:
	var n = current()
	it.gone = true
	for e in g.enemies:
		if e.uid == it.uid:
			e.dead = true
			g.burst(g.center(e), 16, Color("a6e84e"), 80.0, 0.6)
	if n.is_empty():
		return
	Meta.S.ally = {id = n.id, name = n.name, el = str(n.el), lv = int(n.lv), debt = 2}
	Meta.S.nemesis = {}
	Meta.S.gems += 10
	Meta.save()
	g.banner = {text = str(n.name) + " IS IN YOUR DEBT", sub = "IT WILL STAND WITH YOU AGAINST THE NEXT TWO BOSSES", t = 4.5}
	Sfx.play("chest")

static func slain(g, e: Dictionary) -> void:
	var n = current()
	var gems = 25 + 15 * int(n.get("lv", 1))
	Meta.S.gems += gems
	Meta.S.nemesis = {}
	Meta.save()
	for it in g.inter:
		if it.kind == "spare" and it.uid == e.uid:
			it.gone = true
	g.banner = {text = "NEMESIS SLAIN", sub = "+%d GEMS" % gems, t = 4.0}
	g.drop("coin", e.pos, 20)
	if not e.is_boss:
		g.inter.append({kind = "relic", id = g.More.random_relic(g), pos = e.pos})
	g.hitstop = maxf(g.hitstop, 0.2)
	g.flash(e.pos, 200.0, Color("ffd24a"), 0.6)
	Sfx.play("chest")

# ---- the spared one repays its debt in boss fights --------------------------------

static func call_ally(g) -> void:
	var a = Meta.S.get("ally", {})
	if not (a is Dictionary) or not a.has("id") or not D.ENEMIES.has(a.id):
		return
	g.allies.append({friend = true, spr = "e_" + str(a.id), name = str(a.name), pos = g.p.pos + Vector2(-18, 0), life = 75.0, t = 0.6,
		el = str(a.el), lv = int(a.lv), face = 1})
	g.label(g.p.pos + Vector2(0, -34), str(a.name) + " STANDS WITH YOU", Color("a6e84e"), true)
	g.burst(g.p.pos + Vector2(-18, 0), 14, Color("a6e84e"), 80.0, 0.5)
	Sfx.play("pick")
	a.debt = int(a.debt) - 1
	Meta.S.ally = a if int(a.debt) > 0 else {}

static func ally_tick(g, a: Dictionary, dt: float) -> void:
	var to: Vector2 = g.p.pos + Vector2(-20, 6) - a.pos
	if to.length() > 14.0:
		a.pos += to.normalized() * minf(to.length(), 100.0 * dt)
	if a.t > 0.0:
		return
	var e = g.nearest_enemy(a.pos, 170.0, [])
	if e == null:
		return
	a.t = 0.7
	var dir: Vector2 = (g.center(e) - a.pos).normalized()
	a.face = 1 if dir.x >= 0.0 else -1
	for i in 3:
		g.add_bullet(a.pos + Vector2(0, -6), dir.rotated((i - 1) * 0.18) * 240.0,
			{dmg = (4.0 + g.floor_i * 1.5) * (1.0 + 0.3 * int(a.lv)), el = a.el, r = 2.0, life = 1.0})

# ---- graves ----------------------------------------------------------------------

static func bury(g) -> void:
	if g.net.mode == "client":
		return
	var w = g.p.weapons[g.p.wi]
	if w == null:
		return
	Meta.S.graves.push_front({floor = g.floor_i, hero = str(g.p.name), w = var_to_str(w), el = favourite(g)})
	while Meta.S.graves.size() > 3:
		Meta.S.graves.pop_back()

static func place_grave(g) -> void:
	for gr in Meta.S.graves:
		if int(gr.floor) != g.floor_i:
			continue
		var gw = str_to_var(str(gr.w))
		if not (gw is Dictionary) or not D.WEAPONS.has(str(gw.get("id", ""))):
			continue
		for r in g.dg.rooms:
			if r.type != "fight":
				continue
			var pos: Vector2 = g.random_room_pos(r, 0.0)
			g.inter.append({kind = "grave", spr = "tomb", pos = pos, hero = str(gr.hero), w = gw, name = ""})
			if str(gr.el) != "":
				g.zones.append({pos = pos, r = 22.0, el = str(gr.el), life = 99999.0, team = 0, tick = 0.5, grave = true})
			return
		return

static func take_grave(g, it: Dictionary) -> void:
	it.gone = true
	for i in Meta.S.graves.size():
		if str(Meta.S.graves[i].hero) == it.hero and int(Meta.S.graves[i].floor) == g.floor_i:
			Meta.S.graves.remove_at(i)
			break
	Meta.save()
	for z in g.zones:
		if z.get("grave", false):
			z.life = 0.0
	var w: Dictionary = it.w.duplicate(true)
	w.lv = int(w.get("lv", 0))
	g.inter.append({kind = "weapon", w = w, pos = it.pos + Vector2(0, 18)})
	g.label(g.p.pos + Vector2(0, -24), "HERE FELL " + it.hero, Color("a8a7b8"), true)
	g.burst(it.pos + Vector2(0, -8), 12, Color("c6f4ff"), 40.0, 0.9, -30.0)
	Sfx.play("chest", 0.8)
