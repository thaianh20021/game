extends SceneTree
# The second mastery (Elementalist) and the link tree (Tempest Blade).
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

func setup(ranks: Dictionary) -> void:
	g.new_game()
	g.qs["m6"] = "done"
	g.lvl = 30
	g.tree = {}
	g.bar = ["", "", "", "", ""]
	for id in ranks:
		g.tree[id] = ranks[id]
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
	g.p.rage = 100.0
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.sim.mouse = g.p.pos + Vector2(60, 0)
	g.sim.ui_mouse = Vector2.ZERO
	g.hitstop = 0.0
	g.buf = ""

func dummy(kind: String, off: Vector2, hp: float = 5000.0) -> Dictionary:
	var f = g.spawn(kind, g.p.pos + off)
	f.cd = 9999.0
	f.state = "rec"
	f.st = -9999.0
	f.hp = hp
	f.mhp = hp
	return f

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_second.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)

	# --- gates
	g.new_game()
	g.lvl = 30
	g.recompute()
	g.fresh_hero()
	check("the second mastery is shut before the chapter ends", not g.learn("ember") and Sk.blocked(g.tree, "ember", 30, false) == Sk.NO_SECOND)
	g.qs["m6"] = "done"
	check("it opens when the shard wakes", g.learn("ember") and g.bar[0] == "ember")
	check("a link needs 3 points in each mastery", not g.learn("stoke"))
	g.learn("kindle")
	g.learn("kindle")
	g.learn("spin")
	g.learn("bloodlust")
	check("still shut with 3 and 2", not g.learn("stoke"))
	g.learn("bloodlust")
	check("open with 3 and 3", g.learn("stoke"))
	check("the link keystone needs 6 in each", not g.learn("tempest") and Sk.blocked(g.tree, "tempest", 30, true) == "CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ")
	check("link points count for neither mastery", Sk.mastery_points(g.tree, 0) == 3 and Sk.mastery_points(g.tree, 1) == 3 and Sk.mastery_points(g.tree, 2) == 1)

	# --- the three spells
	await setup({"ember": 1})
	var a = dummy("porter", Vector2(80, 0))
	await tap("s1")
	await frames(30)
	check("ember bolt flies, hits and sets a burn", a.hp < 5000.0 and a.burn > 0.0 and absf(g.p.rage - 90.0) < 3.0)
	var h1 = a.hp
	await frames(60)
	check("a burn deals 30 percent of attack a second (%.1f)" % (h1 - a.hp), absf((h1 - a.hp) - g.stats.atk * 0.3) < g.stats.atk * 0.05)
	await frames(240)
	check("and ends after 4 seconds", a.burn <= 0.0)

	await setup({"ember": 1, "kindle": 3})
	a = dummy("porter", Vector2(30, 0))
	g.mark(a, "burn")
	check("kindling: 60% stronger burns", absf(a.burn_dps - g.stats.atk * 0.3 * 1.6) < 0.001)

	await setup({"ring": 1, "deep": 2})
	a = dummy("reed", Vector2(40, 0))
	var b = dummy("reed", Vector2(0, 120))
	await tap("s1")
	await frames(4)
	check("frost ring chills what is near and not what is far", a.chill > 5.0 and b.chill == 0.0 and a.hp < 5000.0)
	a.state = "chase"
	a.cd = 99.0
	a.pos = g.p.pos + Vector2(200, 0)
	b.state = "chase"
	b.cd = 99.0
	b.pos = g.p.pos + Vector2(-200, 0)
	g.hitstop = 0.0
	await frames(60)
	var da = 200.0 - a.pos.distance_to(g.p.pos)
	var db = 200.0 - b.pos.distance_to(g.p.pos)
	check("a chilled foe walks at half speed (%.0f against %.0f)" % [da, db], absf(da / db - 0.5) < 0.1)

	await setup({"spark": 1, "static": 2})
	var line = []
	for i in 5:
		line.append(dummy("reed", Vector2(50 + i * 50, 0)))
	await tap("s1")
	await frames(4)
	var hit = line.filter(func(f): return f.shock > 0.0).size()
	check("chain spark hits the nearest and jumps to 3 more (%d)" % hit, hit == 4 and line[4].shock == 0.0)
	check("a shocked foe takes 25% more with two ranks of static", absf(g.dmg_mult(line[0]) - 1.25) < 0.001 and g.dmg_mult(line[4]) == 1.0)
	await setup({"spark": 1})
	g.p.rage = 100.0
	await tap("s1")
	check("with nothing in reach the spark is not spent", absf(g.p.rage - 100.0) < 1.0 and not g.p.cds.has("spark"))

	# --- keystones of the second mastery
	await setup({"ember": 1, "kindle": 3, "pyre": 1})
	a = dummy("reed", Vector2(30, 0), 5.0)
	b = dummy("reed", Vector2(60, 0), 5.0)
	var c = dummy("porter", Vector2(45, 30))
	g.mark(a, "burn")
	g.mark(b, "burn")
	check("pyre halves burn time", absf(a.burn - 2.0) < 0.001)
	g.hit_foe(a, 50.0, false, 0.0, 0.0)
	check("pyre: a burning death bursts on its neighbours", a.state == "dead" and b.state == "dead" and c.hp < 5000.0)
	var once = 5000.0 - c.hp
	check("pyre: the second death did not burst again (%.0f)" % once, once < g.stats.atk * 1.5 * 1.15)

	await setup({"ring": 1, "deep": 3, "brittle": 1})
	a = dummy("porter", Vector2(30, 0))
	g.mark(a, "chill")
	check("brittle: 25% more to a chilled foe", absf(g.dmg_mult(a) - 1.25) < 0.001)
	g.sim.move = Vector2.RIGHT
	await tap("dodge")
	g.sim.move = Vector2.ZERO
	var cd0 = g.p.dodge_cd
	await frames(60)
	check("brittle: the dodge recharges at half speed", absf((cd0 - g.p.dodge_cd) - 0.5) < 0.1)

	await setup({"spark": 1, "static": 3, "overload": 1})
	line = []
	for i in 8:
		line.append(dummy("reed", Vector2(50 + i * 50, 0)))
	await tap("s1")
	await frames(4)
	check("overload: 7 foes struck, for 35 rage", line.filter(func(f): return f.shock > 0.0).size() == 7 and absf(g.p.rage - 65.0) < 3.0)

	# --- the eight links
	await setup({"bulwark": 1, "charged": 1})
	a = dummy("porter", Vector2(30, 0))
	await tap("s1")
	g.hurt(20.0)
	check("charged guard: a block charges three strikes", g.p.charged == 3)
	await tap("atk")
	await frames(30)
	check("charged guard: the strike shocks", a.shock > 0.0 and g.p.charged == 2)

	await setup({"bulwark": 1, "coldiron": 1})
	a = dummy("porter", Vector2(30, 0))
	b = dummy("reed", Vector2(0, 150))
	await tap("s1")
	g.hurt(20.0)
	check("cold iron: a block chills foes close by only", a.chill > 0.0 and b.chill == 0.0)
	g.p.guard = 0.0
	a.chill = 0.0
	g.p.inv = 0.0
	g.hurt(20.0)
	check("cold iron: an unblocked hit does nothing", a.chill == 0.0)

	await setup({"spin": 1, "stoke": 1})
	a = dummy("porter", Vector2(30, 0))
	b = dummy("porter", Vector2(-30, 0))
	await tap("s1")
	await frames(40)
	check("stoke: spin with nothing burning lights nothing", a.burn <= 0.0 and b.burn <= 0.0)
	g.mark(a, "burn")
	g.p.rage = 100.0
	await tap("s1")
	await frames(40)
	check("stoke: spin through one burning foe lights the other", b.burn > 0.0)

	await setup({"ember": 1, "furnace": 1})
	g.p.rage = 0.0
	line = []
	for i in 5:
		line.append(dummy("porter", Vector2(100 + i * 30, 0)))
		g.mark(line[i], "burn")
	await frames(60)
	check("furnace heart: five burning foes feed 6 rage a second, not 10 (%.1f)" % g.p.rage, absf(g.p.rage - 6.0) < 0.6)

	await setup({"toll": 1, "afterglow": 1})
	a = dummy("porter", Vector2(60, 0))
	await tap("ult")
	await frames(34)
	check("afterglow: the toll leaves all three marks", a.burn > 0.0 and a.chill > 0.0 and a.shock > 0.0)

	await setup({"ring": 1, "shatter": 1})
	a = dummy("porter", Vector2(30, 0))
	g.mark(a, "chill")
	for i in 2:
		await tap("atk")
		for j in 90:
			if g.p.state == "idle":
				break
			await process_frame
	check("shatter: the first two strikes leave the chill", a.chill > 0.0)
	a.hp = 5000.0
	a.state = "rec"
	await tap("atk")
	await frames(30)
	var broke = 5000.0 - a.hp
	check("shatter: the last strike breaks it, hard, and staggers a heavy foe (%.0f)" % broke, a.chill == 0.0 and a.state == "stun" and broke > g.stats.atk * 1.8 * 1.8 * 0.85)

	await setup({"lunge": 1, "conduct": 1})
	a = dummy("reed", Vector2(40, 0))
	b = dummy("reed", Vector2(40, 60))
	g.mark(a, "shock")
	await tap("s1")
	await frames(30)
	check("conductor: lunging through a shocked foe throws a spark to another", b.shock > 0.0 and b.hp < 5000.0)
	check("conductor: it then waits 2 seconds", g.p.cond_cd > 1.0)
	await setup({"lunge": 1, "conduct": 1})
	a = dummy("reed", Vector2(40, 0))
	b = dummy("reed", Vector2(40, 60))
	await tap("s1")
	await frames(30)
	check("conductor: nothing without a shock", b.hp == 5000.0)

	await setup({"ember": 1, "ring": 1, "tempest": 1})
	a = dummy("porter", Vector2(30, 0))
	await tap("atk")
	await frames(30)
	check("tempest blade: a plain strike leaves no mark", a.burn <= 0.0 and a.chill == 0.0)
	g.sim.mouse = g.p.pos + Vector2(0, -80)
	await tap("s1")
	g.sim.mouse = a.pos
	await frames(20)
	check("tempest blade: spells recharge 30% slower", absf(g.skill_cd("ember") - 1.95) < 0.001 and g.p.elem == "burn")
	await tap("atk")
	await frames(30)
	check("tempest blade: after a fire spell the chain burns", a.burn > 0.0)
	await tap("s2")
	await frames(4)
	a.chill = 0.0
	g.p.combo = 0
	await tap("atk")
	await frames(30)
	check("tempest blade: after a frost spell the chain chills", a.chill > 0.0)
	g.p.elem_t = 0.0
	a.chill = 0.0
	g.p.combo = 0
	await tap("atk")
	await frames(30)
	check("tempest blade: it wears off", a.chill == 0.0)

	# --- the screen
	await setup({})
	await tap("tree")
	var view = g.get_viewport_rect().size
	g.sim.ui_mouse = g.Ui.tab_rect(view, 1).get_center()
	await tap("atk")
	check("clicking a tab shows that mastery", g.tab == 1)
	g.sim.ui_mouse = g.Ui.tree_cell(view, "ring").get_center()
	await tap("atk")
	check("clicking a node there learns it", g.tree.get("ring", 0) == 1 and not g.tree.has("spin"))
	g.save_game()
	g.new_game()
	check("second-mastery nodes are saved", g.load_game() and g.tree.get("ring", 0) == 1)
	print("RESULT: %s" % ("OK" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
