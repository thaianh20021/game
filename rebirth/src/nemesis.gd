extends RefCounted
# Your nemesis: whatever kills you gets a name, grows stronger, learns to resist the element
# you leaned on, and waits for you in the next run. Kill it for a reward; die to it again
# and it rises a rank.

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")

const NAME_A = ["GRUK", "VASH", "MORL", "SKAR", "THUN", "ZEK", "BRAK", "OLM", "YIR", "DRUN", "KHEL", "NASK"]
const NAME_B = ["THE PATIENT", "WHO REMEMBERS", "THE UNBURNT", "OF THE LONG GRUDGE", "THE STUBBORN", "WHO WAITS", "THE SCARRED", "KINGSLAYER"]

static func current() -> Dictionary:
	var n = Meta.S.get("nemesis", {})
	return n if (n is Dictionary and n.has("id") and D.ENEMIES.has(n.id)) else {}

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
	var fav = ""
	var most = 0
	for el in g.el_use:
		if int(g.el_use[el]) > most:
			most = int(g.el_use[el])
			fav = el
	var old = current()
	if killer.get("nem", false) and not old.is_empty():
		old.lv = int(old.lv) + 1
		old.floor = g.floor_i
		if fav != "":
			old.el = fav
		Meta.S.nemesis = old
	else:
		Meta.S.nemesis = {id = killer.id, name = NAME_A[g.rng.randi() % NAME_A.size()] + " " + NAME_B[g.rng.randi() % NAME_B.size()],
			el = fav, lv = 1, floor = g.floor_i, boss = killer.is_boss}

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
	g.banner = {text = "NEMESIS: " + e.nem_name, sub = ("IT RESISTS " + D.EL_NAME[n.el]) if str(n.el) != "" else "IT REMEMBERS YOU", t = 4.0}
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

static func slain(g, e: Dictionary) -> void:
	var n = current()
	var gems = 25 + 15 * int(n.get("lv", 1))
	Meta.S.gems += gems
	Meta.S.nemesis = {}
	Meta.save()
	g.banner = {text = "NEMESIS SLAIN", sub = "+%d GEMS" % gems, t = 4.0}
	g.drop("coin", e.pos, 20)
	if not e.is_boss:
		g.inter.append({kind = "relic", id = g.More.random_relic(g), pos = e.pos})
	g.hitstop = maxf(g.hitstop, 0.2)
	g.flash(e.pos, 200.0, Color("ffd24a"), 0.6)
	Sfx.play("chest")
