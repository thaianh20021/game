extends SceneTree
# The Warrior skill tree: points, gates, every active skill, every keystone, reset, save.
const D = preload("res://src/data.gd")
const Sk = preload("res://src/skills.gd")
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

# a level 20 hero with the given ranks, alone in the middle of the marsh
func setup(ranks: Dictionary) -> void:
	g.new_game()
	g.lvl = 20
	g.tree = {}
	g.bar = ["", "", "", "", ""]
	for id in ranks:
		for i in ranks[id]:
			g.tree[id] = g.tree.get(id, 0) + 1
		if Sk.NODES[id].kind == "a":
			g.bar[g.bar.find("")] = id
	g.recompute()
	g.sim.no_spawns = true
	g.enter_zone("field", Vector2.ZERO)
	g.sim.no_spawns = false
	g.mode = "play"
	g.fresh_hero()
	g.p.pos = Vector2(34 * 16, 23 * 16)
	g.p.aim = Vector2.RIGHT
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.sim.mouse = g.p.pos + Vector2(60, 0)
	g.sim.ui_mouse = Vector2.ZERO
	g.hitstop = 0.0
	g.buf = ""

# a foe that stands still and never attacks
func dummy(kind: String, off: Vector2) -> Dictionary:
	var f = g.spawn(kind, g.p.pos + off)
	f.cd = 9999.0
	f.state = "rec"
	f.st = -9999.0
	f.hp = 5000.0
	f.mhp = 5000.0
	return f

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_skills.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)

	# --- the data is sound
	var seen = {}
	var ok = true
	var actives = 0
	for id in Sk.NODES:
		var N = Sk.NODES[id]
		var key = "%d:%d:%d:%d" % [N.get("m", 0), N.b, N.pos[0], N.pos[1]]
		ok = ok and not seen.has(key) and N.desc != "" and N.abbr.length() == 2
		seen[key] = true
		if N.kind == "a":
			actives += 1
	check("376 nodes, no two in the same place", ok and Sk.NODES.size() == 376)
	check("48 active skills, 52 keystones, 8 ultimates", actives == 48 and Sk.NODES.values().filter(func(n): return n.kind == "k").size() == 52 and Sk.NODES.values().filter(func(n): return n.kind == "u").size() == 8)

	# --- points and gates
	g.new_game()
	g.recompute()
	g.fresh_hero()
	check("level 1 has one point", g.points_left() == 1)
	check("the second row is locked at first", not g.learn("rush") and Sk.blocked(g.tree, "rush", g.lvl, false) == "CẦN 2 ĐIỂM Ở NHÁNH THỦ")
	check("a learned skill goes on the first key", g.learn("spin") and g.bar[0] == "spin" and g.points_left() == 0)
	check("no points, no rank", not g.learn("bloodlust"))
	g.lvl = 20
	g.recompute()
	var def0 = g.stats.def
	var hp0 = g.stats.mhp
	check("passives take three ranks and no more", g.learn("iron") and g.learn("iron") and g.learn("iron") and not g.learn("iron"))
	check("iron skin adds armor", g.stats.def == def0 + 9.0)
	g.learn("steady")
	check("steady adds life", g.stats.mhp == hp0 + 12.0)
	check("the keystone needs five points in its branch", not g.learn("unbroken") and g.learn("bulwark") and g.learn("unbroken"))
	check("the ultimate needs eight points spent", Sk.spent(g.tree) == 7 and not g.learn("toll") and g.learn("hotblood") and g.learn("toll"))
	check("hot blood raises rage gain", g.stats.rage == 15.0)
	g.assign("spin", 3)
	check("a skill can be moved to another key", g.bar[3] == "spin" and g.bar[0] == "" and g.bar.count("spin") == 1)
	g.save_game()
	var snap = [g.tree.duplicate(), g.bar.duplicate()]
	g.new_game()
	check("the tree is saved and loaded", g.load_game() and g.tree == snap[0] and g.bar == snap[1])
	g.reset_tree()
	check("reset gives every point back", g.tree.is_empty() and g.points_left() == 20 and g.stats.def == def0 and g.bar == ["", "", "", "", ""])

	# --- active skills
	await setup({"spin": 1})
	var a = dummy("porter", Vector2(30, 0))
	var b = dummy("porter", Vector2(-30, 0))
	await tap("s1")
	await frames(30)
	check("spin does nothing without rage", a.hp == 5000.0)
	g.p.rage = 100.0
	await tap("s1")
	await frames(40)
	check("spin costs 40 rage and hits both sides", absf(g.p.rage - 60.0) < 3.0 and a.hp < 5000.0 and b.hp < 5000.0)

	await setup({"bulwark": 1, "counter": 2})
	a = dummy("porter", Vector2(30, 0))
	await tap("atk")
	await frames(30)
	var plain = 5000.0 - a.hp
	g.p.combo = 0
	await tap("s1")
	check("bulwark raises a guard and starts its cooldown", g.p.guard > 0.0 and g.p.cds.has("bulwark"))
	g.p.rage = 0.0
	var h0 = g.p.hp
	g.hurt(50.0)
	var want = 50.0 * 60.0 / (60.0 + g.stats.def * 4.0) * 0.2
	check("a blocked hit deals a fifth (%.1f)" % (h0 - g.p.hp), absf((h0 - g.p.hp) - want) < 0.01 and g.p.state != "dead")
	check("counterweight turns the block into rage", absf(g.p.rage - 30.0) < 1.0)
	a.hp = 5000.0
	await tap("atk")
	await frames(30)
	check("the strike after a block hits twice as hard (%.0f then %.0f)" % [plain, 5000.0 - a.hp], 5000.0 - a.hp > plain * 1.6)
	a.hp = 5000.0
	g.p.combo = 0
	await tap("atk")
	await frames(30)
	check("and only that one", 5000.0 - a.hp < plain * 1.3)

	await setup({"iron": 2, "rush": 1})
	a = dummy("porter", Vector2(50, 0))
	g.p.rage = 100.0
	var x0 = g.p.pos.x
	await tap("s1")
	await frames(8)
	check("shield rush charges, hits and staggers a heavy foe", a.hp < 5000.0 and a.state == "stun")
	await frames(40)
	check("it carries you about 90 paces (%.0f)" % (g.p.pos.x - x0), g.p.pos.x - x0 > 70.0 and g.p.pos.x - x0 < 110.0 and g.p.state == "idle")

	await setup({"lunge": 1})
	a = dummy("reed", Vector2(30, 0))
	b = dummy("reed", Vector2(70, 0))
	g.p.rage = 100.0
	await tap("s1")
	await frames(40)
	check("lunge goes through the line and hits both", a.hp < 5000.0 and b.hp < 5000.0 and absf(g.p.rage - 85.0) < 3.0)
	await tap("s1")
	await frames(10)
	check("lunge is on cooldown afterwards", g.p.cds.has("lunge") and g.p.state == "idle")

	await setup({"reach": 2, "slam": 1})
	a = dummy("porter", Vector2(55, 0))
	b = dummy("reed", Vector2(0, -50))
	g.p.rage = 100.0
	await tap("s1")
	await frames(50)
	check("ground slam reaches a wide ring", a.hp < 5000.0 and b.hp < 5000.0)

	await setup({"spin": 1, "bloodlust": 1, "cry": 1, "laststand": 2})
	a = dummy("porter", Vector2(30, 0))
	check("no bonus at rest", g.dmg_mult(a) == 1.0)
	await tap("s2")
	check("war cry gives rage and its buff", absf(g.p.rage - 30.0) < 0.5 and g.p.cry > 5.0 and absf(g.dmg_mult(a) - 1.3) < 0.001)
	h0 = g.p.hp
	g.hurt(50.0)
	check("and you take a fifth more while it lasts", absf((h0 - g.p.hp) - 50.0 * 1.2 * 60.0 / (60.0 + g.stats.def * 4.0)) < 0.01)
	g.p.cry = 0.0
	g.p.hp = g.stats.mhp * 0.3
	check("last stand: 24% more below 35% life", absf(g.dmg_mult(a) - 1.24) < 0.001)

	await setup({"lunge": 1, "reach": 1, "sunder": 2})
	a = dummy("porter", Vector2(30, 0))
	g.stagger(a, 5.0)
	check("sunder: 20% more against a staggered foe", absf(g.dmg_mult(a) - 1.2) < 0.001)
	check("long reach lengthens the strike", g.cur_atk()[4] == g.ATK[0][4] + 3.0)

	# --- keystones
	await setup({"bulwark": 1, "iron": 3, "steady": 1, "unbroken": 1})
	check("unbroken: one dodge only", g.max_dodges() == 1 and g.p.dodges == 1)
	await tap("s1")
	check("unbroken: bulwark recharges in half the time", absf(g.p.cds.bulwark - 3.0) < 0.2)
	g.p.hp = 100.0
	g.hurt(50.0)
	check("unbroken: a block heals", g.p.hp > 100.0)

	await setup({"spin": 1, "bloodlust": 3, "hotblood": 1, "price": 1})
	a = dummy("porter", Vector2(30, 0))
	g.p.rage = 0.0
	h0 = g.p.hp
	await tap("s1")
	await frames(40)
	check("blood price: spin with no rage costs 8% life instead", a.hp < 5000.0 and absf((h0 - g.p.hp) - g.stats.mhp * 0.08) < g.stats.mhp * 0.07)
	g.p.rage = 100.0
	g.p.cds.clear()
	await tap("s1")
	await frames(40)
	check("blood price: rage is kept, and full rage is 30% damage", g.p.rage > 90.0 and absf(g.dmg_mult(a) - (1.0 + 0.3 * g.p.rage / 100.0)) < 0.001)

	await setup({"lunge": 1, "reach": 3, "heavy": 1, "fourth": 1})
	a = dummy("porter", Vector2(30, 0))
	var idxs = []
	for i in 5:
		g.sim.mouse = a.pos
		await tap("atk")
		idxs.append(g.p.idx)
		for j in 90:
			if g.p.state == "idle":
				break
			await process_frame
	check("fourth strike: the chain runs 0 1 2 3 and starts again (%s)" % str(idxs), idxs == [0, 1, 2, 3, 0])
	g.p.idx = 0
	g.p.skill = ""
	check("fourth strike: every strike starts a frame later", absf(g.cur_atk()[0] - (g.ATK[0][0] + g.F)) < 0.0001)

	# --- the ultimate
	await setup({"spin": 1, "bloodlust": 3, "hotblood": 3, "lunge": 1, "toll": 1})
	a = dummy("porter", Vector2(80, 0))
	b = dummy("reed", Vector2(-60, 40))
	await tap("ult")
	await frames(34)
	check("the toll hits far and stuns everything it hits", a.hp < 5000.0 and b.hp < 5000.0 and a.state == "stun" and b.state == "stun" and a.stun == 1.5)
	check("the toll has a long cooldown", g.p.cds.get("toll", 0.0) > 40.0)

	# --- the screen
	await setup({})
	await tap("tree")
	check("T opens the tree", g.mode == "tree")
	var view = g.get_viewport_rect().size
	g.sim.ui_mouse = g.Ui.tree_cell(view, "lunge").get_center()
	await tap("atk")
	check("clicking a node learns it", g.tree.get("lunge", 0) == 1 and g.bar[0] == "lunge")
	await tap("s3")
	check("pressing 3 over it moves it to key 3", g.bar[2] == "lunge" and g.bar[0] == "")
	g.sim.ui_mouse = g.Ui.tree_cell(view, "fourth").get_center()
	await tap("atk")
	check("clicking a locked node does nothing", not g.tree.has("fourth"))
	await tap("reset")
	check("X takes the points back", g.tree.is_empty())
	await tap("tree")
	check("T closes it", g.mode == "play")
	print("RESULT: %s" % ("OK" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
