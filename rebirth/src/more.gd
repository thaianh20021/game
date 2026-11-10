extends RefCounted
# Run content layered on top: weapon synergies, relics, active items, allies,
# keys and secrets. Every function takes the game node as g.

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")

static func sources(g) -> Array:
	# every element source the player carries, with repeats (two ice weapons = two entries)
	var out = []
	for w in g.p.weapons:
		if w != null:
			for k in [w.el, w.get("el2", "")]:
				if k != "" and k != "prism":
					out.append(k)
	if g.p.pet != null:
		out.append(Meta.PETS[g.p.pet.id].el)
	return out

static func refresh_syn(g) -> void:
	var p = g.p
	var w0 = p.weapons[0]
	var w1 = p.weapons[1]
	var src = sources(g)
	var uniq = []
	for k in src:
		if not uniq.has(k):
			uniq.append(k)
	var ids = [w0.id]
	if w1 != null:
		ids.append(w1.id)
	var act = []
	if (ids.has("bow") or ids.has("kunai")) and uniq.has("bolt"):
		act.append("thunder")
	if uniq.has("fire") and uniq.has("tox"):
		act.append("wildfire")
	if src.count("ice") >= 2:
		act.append("permafrost")
	if src.count("bolt") >= 2:
		act.append("stormfront")
	if src.count("tox") >= 2:
		act.append("plaguedoc")
	if uniq.size() >= 3:
		act.append("prismatic")
	if w1 != null:
		var d0 = D.WEAPONS[w0.id]
		var d1 = D.WEAPONS[w1.id]
		if d0.type == "melee" and d1.type == "melee":
			act.append("duelist")
		if int(w0.get("lv", 0)) >= 3 and int(w1.get("lv", 0)) >= 3:
			act.append("arsenal")
		if w0.el == "" and w1.el == "" and d0.type == "bullet" and d1.type == "bullet":
			act.append("gunslinger")
	if p.pet != null and p.mount != null:
		act.append("beastlord")
	var changed = act.size() != p.syn.size()
	for id in act:
		if not p.syn.has(id):
			changed = true
			for s in D.SYNERGIES:
				if s.id == id and not g.in_lobby:
					g.banner = {text = "SYNERGY: " + s.name, sub = s.desc, t = 3.0}
					Sfx.play("react", 1.3)
					Meta.record("synergies", id)
			if id == "beastlord" and not p.mount.get("bl", false):
				p.mount.bl = true
				p.mount.mhp += 2
				p.mount.hp += 2
	p.syn = act
	if changed:
		g.calc_stats()

static func random_relic(g) -> String:
	var pool = []
	for id in D.RELICS:
		if not g.p.relics.has(id):
			pool.append(id)
	if pool.is_empty():
		pool = D.RELICS.keys()
	return pool[g.rng.randi() % pool.size()]

static func random_active(g) -> String:
	var ids = D.ACTIVES.keys()
	return ids[g.rng.randi() % ids.size()]

static func take_relic(g, id: String) -> void:
	var p = g.p
	p.relics.append(id)
	match id:
		"glass":
			p.mhp = max(1, p.mhp - 2)
			p.hp = min(p.hp, p.mhp)
		"feather":
			p.feather = true
	Meta.record("relics", id)
	g.calc_stats()
	Sfx.play("chest")
	g.flash(g.pcenter(), 90.0, Color("ffd24a"), 0.4)
	g.banner = {text = D.RELICS[id].name, sub = D.RELICS[id].desc, t = 3.0}

static func take_active(g, it: Dictionary) -> void:
	var p = g.p
	var old = p.active
	p.active = {id = it.id, n = D.ACTIVES[it.id].max}
	if old != null:
		it.id = old.id
	else:
		it.gone = true
	Sfx.play("pick")
	g.label(p.pos + Vector2(0, -22), D.ACTIVES[p.active.id].name, Color("5cd3f2"))

static func use_active(g) -> void:
	var p = g.p
	if p.active == null:
		return
	if p.active.n <= 0:
		Sfx.play("deny")
		g.label(p.pos + Vector2(0, -22), "RECHARGES AS YOU CLEAR ROOMS", Color("6b6779"))
		return
	p.active.n -= 1
	var pc: Vector2 = g.pcenter()
	match p.active.id:
		"bomb":
			p.inv = maxf(p.inv, 0.3)
			g.explode(pc, 72.0, 30.0 + g.floor_i * 8.0, "", 0)
		"flask":
			p.hp = min(p.mhp, p.hp + 2)
			g.burst(pc, 14, Color("ff6a7a"), 60.0, 0.6, -60.0)
			g.label(p.pos + Vector2(0, -22), "+2 HEALTH", Color("ff6a7a"))
			Sfx.play("pick")
		"glass":
			for e in g.enemies:
				if not e.dead and g.on_screen(e.pos):
					e.frz = maxf(e.frz, 1.0 if e.is_boss else 2.6)
			g.flash(pc, 300.0, Color("7adfff"), 0.5)
			Sfx.play("freeze")
		"turret":
			g.allies.append({pos = p.pos, life = 8.0, t = 0.2, el = g.cur_el()})
			g.burst(p.pos, 10, Color("5cd3f2"), 60.0, 0.4)
			Sfx.play("door", 1.6)

static func update_allies(g, dt: float) -> void:
	for a in g.allies:
		a.life -= dt
		a.t -= dt
		if a.t <= 0.0:
			var e = g.nearest_enemy(a.pos, 130.0, [])
			if e != null:
				a.t = 0.22
				g.add_bullet(a.pos + Vector2(0, -8), (g.center(e) - a.pos - Vector2(0, -8)).normalized() * 260.0,
					{dmg = 3.0 + g.floor_i, el = a.el, r = 2.0, life = 0.8})
	g.allies = g.allies.filter(func(a): return a.life > 0.0)

# Cracked walls: a player bullet that hits one chips it; when it breaks the secret room opens.
static func hit_crack(g, tx: int, ty: int) -> void:
	for c in g.dg.get("cracks", []):
		if c.open or c.cell != Vector2i(tx, ty):
			continue
		c.hp -= 1
		g.burst(Vector2(c.cell) * 16.0 + Vector2(8, 8), 4, Color("a8a7b8"), 50.0, 0.4, 80.0)
		g.shake_add(1.5)
		if c.hp <= 0:
			c.open = true
			g.dg.grid[c.cell.y * g.dg.w + c.cell.x] = 1
			g.rebake()
			Sfx.play("boom")
			g.shake_add(6.0)
			g.banner = {text = "SECRET ROOM", sub = "", t = 2.0}
			Meta.record("secrets", "room")
