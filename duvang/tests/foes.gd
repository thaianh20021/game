extends SceneTree
# The three later foes, the two elite marks, the Toll Keeper and his gate.
const D = preload("res://src/data.gd")
var g
var fails = 0

func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1

func frames(n: int) -> void:
	for i in n:
		await process_frame

func tap(key: String) -> void:
	g.sim[key] = true
	await frames(2)
	g.sim[key] = false
	await frames(2)

func setup(zone: String = "field") -> void:
	g.new_game()
	g.lvl = 10
	g.recompute()
	g.sim.no_spawns = true
	g.enter_zone(zone, Vector2.ZERO)
	g.sim.no_spawns = false
	g.mode = "play"
	g.fresh_hero()
	if zone == "field":
		g.p.pos = Vector2(34 * 16, 23 * 16)
	g.p.aim = Vector2.RIGHT
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.sim.mouse = g.p.pos + Vector2(60, 0)
	g.sim.ui_mouse = Vector2.ZERO
	g.hitstop = 0.0
	g.buf = ""

# a live foe that will attack as soon as it can
func foe(kind: String, off: Vector2) -> Dictionary:
	var f = g.spawn(kind, g.p.pos + off)
	f.state = "chase"
	f.cd = 0.0
	return f

# a foe that stands still and never attacks
func dummy(kind: String, off: Vector2, hp: float = 5000.0) -> Dictionary:
	var f = g.spawn(kind, g.p.pos + off)
	f.cd = 9999.0
	f.state = "rec"
	f.st = -9999.0
	f.hp = hp
	f.mhp = hp
	return f

func wait_for(f: Dictionary, state: String, limit: int = 300) -> bool:
	for i in limit:
		if f.state == state:
			return true
		await process_frame
	return false

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_foes.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)

	# --- data
	var kinds = {}
	for id in ["field", "dungeon"]:
		for s in g.World.build(id).spawns:
			kinds[s.kind] = true
			if not D.FOES.has(s.kind):
				check("spawn kind %s exists" % s.kind, false)
	check("eight kinds of foe are placed in the world, bosses included", kinds.size() == 8)
	var dz = g.World.build("dungeon")
	var ok = true
	for s in dz.spawns:
		ok = ok and dz.grid[int(s.pos.y / 16)][int(s.pos.x / 16)] != 0
	check("every dungeon foe stands on ground", ok)
	check("the dungeon holds both elite marks, one gate and one keeper", dz.spawns.filter(func(s): return s.has("elite")).size() == 2 and dz.gates.size() == 1 and dz.spawns.filter(func(s): return s.kind == "keeper").size() == 1)

	# --- mud leech: lunges in a line
	await setup()
	var f = foe("leech", Vector2(60, 0))
	check("a leech winds up", await wait_for(f, "wind"))
	var x0 = f.pos.x
	await wait_for(f, "rec")
	await frames(20)
	check("standing in its line gets you bitten", g.p.hp < g.stats.mhp)
	check("it travels in a lunge (%.0f)" % absf(f.pos.x - x0), absf(f.pos.x - x0) > 40.0)
	await setup()
	f = foe("leech", Vector2(60, 0))
	await wait_for(f, "wind")
	g.p.pos += Vector2(0, 40)
	await wait_for(f, "rec")
	await frames(20)
	check("stepping out of the line avoids it", g.p.hp == g.stats.mhp)

	# --- net thrower: a circle where you stood, and a slow
	await setup()
	f = foe("netter", Vector2(110, 0))
	await wait_for(f, "wind")
	check("the net is aimed where you stand", f.tpos.distance_to(g.p.pos) < 2.0)
	await wait_for(f, "rec")
	check("caught in the net: hurt and slowed", g.p.hp < g.stats.mhp and g.p.slow > 1.5)
	f.cd = 99.0
	g.p.inv = 0.0
	var px = g.p.pos.x
	g.sim.move = Vector2.LEFT
	await frames(30)
	g.sim.move = Vector2.ZERO
	check("a netted hero walks at under half speed (%.0f)" % (px - g.p.pos.x), px - g.p.pos.x < 0.5 * g.SPEED * 0.55 and px - g.p.pos.x > 10.0)
	await setup()
	f = foe("netter", Vector2(110, 0))
	await wait_for(f, "wind")
	g.p.pos += Vector2(0, 50)
	await wait_for(f, "rec")
	check("leaving the circle avoids the net", g.p.hp == g.stats.mhp and g.p.slow == 0.0)

	# --- lantern wisp: mends allies, and can be cut short
	await setup()
	var hurt = dummy("porter", Vector2(120, 40), 1000.0)
	hurt.hp = 300.0
	f = foe("wisp", Vector2(120, 0))
	await wait_for(f, "wind")
	check("a wisp with a wounded ally starts an amber cast", f.atk == "heal" and f.amber)
	await wait_for(f, "rec")
	check("left alone, it mends 35% of the ally's life", absf(hurt.hp - 650.0) < 1.0)
	await setup()
	hurt = dummy("porter", Vector2(120, 40), 1000.0)
	hurt.hp = 300.0
	f = foe("wisp", Vector2(120, 0))
	await wait_for(f, "wind")
	f.hp = 500.0
	g.hit_foe(f, 5.0, false, 0.0, 0.0)
	check("any hit cuts a light foe's cast short", f.state == "stun" and not f.amber)
	await frames(120)
	check("and the ally is not mended", hurt.hp == 300.0 or f.state == "wind")
	await setup()
	f = foe("wisp", Vector2(120, 0))
	await wait_for(f, "wind")
	check("with no one to mend it spits instead", f.atk == "" and not f.amber)

	# --- elite marks
	await setup()
	var plain = g.spawn("reed", g.p.pos + Vector2(200, 0))
	f = g.spawn("reed", g.p.pos + Vector2(30, 0))
	g.make_elite(f, "volatile")
	check("an elite has 1.8 times the life", absf(f.mhp - plain.mhp * 1.8) < 0.01)
	f.cd = 99.0
	var xp0 = g.xp + g.lvl * 100000
	f.hp = 1.0
	g.hit_foe(f, 50.0, false, 0.0, 0.0)
	check("volatile: its death leaves a warning", f.state == "dead" and g.blasts.size() == 1)
	check("an elite always drops an item", g.drops.any(func(o): return o.kind == "item"))
	g.p.inv = 0.0
	await frames(70)
	check("volatile: standing there a second later hurts", g.p.hp < g.stats.mhp and g.blasts.is_empty())
	await setup()
	f = g.spawn("reed", g.p.pos + Vector2(30, 0))
	g.make_elite(f, "volatile")
	f.hp = 1.0
	g.hit_foe(f, 50.0, false, 0.0, 0.0)
	g.p.pos += Vector2(-90, 0)
	await frames(70)
	check("volatile: stepping away is safe", g.p.hp == g.stats.mhp)

	await setup()
	var w = dummy("heron", Vector2(60, 0))
	g.make_elite(w, "warding")
	w.hp = 5000.0
	var near = dummy("reed", Vector2(60, 60))
	var far = dummy("reed", Vector2(60, 200))
	check("warding covers foes near it, not far ones and not itself", g.warded(near) and not g.warded(far) and not g.warded(w))
	seed(7)
	g.hit_foe(near, 100.0, false, 0.0, 0.0)
	seed(7)
	g.hit_foe(far, 100.0, false, 0.0, 0.0)
	check("a warded foe takes half (%.0f against %.0f)" % [5000.0 - near.hp, 5000.0 - far.hp], absf((5000.0 - near.hp) * 2.0 - (5000.0 - far.hp)) < 0.5)
	w.hp = 1.0
	g.hit_foe(w, 50.0, false, 0.0, 0.0)
	check("kill the warder and the ward is gone", not g.warded(near))

	# --- the Toll Keeper
	await setup()
	f = foe("keeper", Vector2(40, 0))
	f.hp = f.mhp * 0.5
	f.n = 2
	await wait_for(f, "wind")
	check("below 85% life the Keeper calls the toll, in amber", f.atk == "call" and f.amber and f.wind > 2.0)
	g.p.pos += Vector2(-140, 0)
	var h0 = f.hp
	await wait_for(f, "act")
	check("uninterrupted, the call heals him 12% and brings help", absf((f.hp - h0) - f.mhp * 0.12) < 1.0 and g.foes.size() == 3)

	await setup()
	f = foe("keeper", Vector2(40, 0))
	f.hp = f.mhp * 0.5
	f.n = 2
	await wait_for(f, "wind")
	g.hit_foe(f, 5.0, false, 0.0, 0.0)
	check("a light hit does not interrupt a heavy foe", f.state == "wind" and f.amber)
	h0 = f.hp
	g.hit_foe(f, 5.0, true, 0.0, 0.0)
	check("a heavy hit does", f.state == "stun" and not f.amber)
	await frames(100)
	check("and the heal never comes", f.hp <= h0)
	var used = {}
	f.n = 0
	for i in 900:
		g.p.hp = g.stats.mhp
		if f.state == "wind":
			used[f.atk] = true
		g.p.pos = f.pos + Vector2(-40, 0)
		await process_frame
	check("he also sweeps and slams (%s)" % str(used.keys()), used.has("sweep") and used.has("slam"))

	await setup()
	g.eq.charm = D.toll_box()
	g.recompute()
	g.p.hp = 50.0
	f = foe("keeper", Vector2(40, 0))
	f.hp = f.mhp * 0.5
	f.n = 2
	await wait_for(f, "wind")
	g.p.rage = 0.0
	g.hit_foe(f, 5.0, true, 0.0, 0.0)
	check("the toll box: an interrupt heals 10% life and gives 30 rage", absf(g.p.hp - (50.0 + g.stats.mhp * 0.1)) < 1.0 and g.p.rage >= 30.0)

	# --- the gate
	await setup("dungeon")
	var gate = g.zone.gates[0].rect
	var c = gate.get_center()
	check("the gate east of the toll yard is shut", g.blocks.has(gate) and not g.walk(c))
	g.p.pos = c + Vector2(-30, 0)
	g.sim.move = Vector2.RIGHT
	await frames(90)
	g.sim.move = Vector2.ZERO
	check("you cannot walk through it", g.p.pos.x < gate.position.x)
	f = g.spawn("keeper", g.p.pos + Vector2(-60, 0))
	f.hp = 1.0
	g.hit_foe(f, 50.0, false, 0.0, 0.0)
	check("the Keeper's death opens it and drops his box", g.flags.has("keeper_dead") and g.walk(c) and g.drops.any(func(o): return o.kind == "item" and o.item.uniq == "box"))
	g.p.pos = c + Vector2(-30, 0)
	g.sim.move = Vector2.RIGHT
	await frames(90)
	g.sim.move = Vector2.ZERO
	check("now you can walk through", g.p.pos.x > gate.end.x)
	g.enter_zone("dungeon", Vector2.ZERO)
	check("on a later visit the gate stays open and the Keeper stays dead", g.walk(c) and not g.foes.any(func(o): return o.kind == "keeper") and g.foes.any(func(o): return o.kind == "boss"))
	check("elites are placed with their marks", g.foes.filter(func(o): return o.get("elite", "") != "").size() == 2)
	g.save_game()
	g.new_game()
	check("the open gate is saved", g.load_game() and g.flags.has("keeper_dead"))
	print("RESULT: %s" % ("OK" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
