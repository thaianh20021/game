extends SceneTree
# The Assassin mastery, its two link trees, and choosing the second mastery.
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

func quiet() -> void:
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.sim.mouse = g.p.pos + Vector2(60, 0)
	g.sim.ui_mouse = Vector2(-50, -50)
	g.hitstop = 0.0
	g.buf = ""

# an Assassin (first mastery) with `second` as the other one, and the given ranks
func rogue(ranks: Dictionary, second: int = 0) -> void:
	g.new_game()
	g.main_m = 3
	g.second_m = second
	g.qs["m6"] = "done"
	g.lvl = 40
	g.tree = ranks.duplicate()
	g.bar = ["", "", "", "", ""]
	for id in ranks:
		if Sk.NODES[id].kind == "a":
			g.bar[g.bar.find("")] = id
	g.recompute()
	g.sim.no_spawns = true
	g.mode = "play"
	g.enter_zone("field", Vector2.ZERO)
	g.sim.no_spawns = false
	g.fresh_hero()
	g.p.pos = Vector2(34 * 16, 23 * 16)
	g.p.aim = Vector2.RIGHT
	g.p.rage = 100.0
	quiet()

# a foe that stands still, never attacks, and faces right (so its back is to the left)
func dummy(kind: String, off: Vector2, hp: float = 5000.0) -> Dictionary:
	var f = g.spawn(kind, g.p.pos + off)
	f.cd = 9999.0
	f.state = "rec"
	f.st = -9999.0
	f.hp = hp
	f.mhp = hp
	f.flip = false
	f.guard = 99999.0   # its stance never breaks, so it is stunned only when a test says so
	return f

func strike(f: Dictionary) -> void:
	g.sim.mouse = f.pos
	await tap("atk")
	for j in 90:
		if g.p.state == "idle":
			break
		await process_frame
	g.hitstop = 0.0

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_rogue.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)

	# --- data
	var pos = {}
	var ok = true
	for id in Sk.NODES:
		var N = Sk.NODES[id]
		var key = "%d:%d:%d:%d" % [N.get("m", 0), N.b, N.pos[0], N.pos[1]]
		ok = ok and not pos.has(key) and g.Art.T.has("sk_" + id)
		pos[key] = true
	check("every node has its own place and its own icon", ok)
	check("the link tree of a pair is found either way round", Sk.link_of(0, 3) == 4 and Sk.link_of(3, 0) == 4 and Sk.link_of(3, 1) == 5 and Sk.link_of(1, 0) == 2)

	# --- gates
	await rogue({}, 0)
	g.qs.erase("m6")
	check("an Assassin starts with the Assassin tree only", g.learn("slash") and not g.learn("spin") and Sk.blocked(g.tree, "spin", 40, false, 3, 0) == Sk.NO_SECOND)
	check("a mastery that is neither of yours stays shut", Sk.blocked(g.tree, "ember", 40, true, 3, 0) == Sk.NOT_YOURS)
	g.qs["m6"] = "done"
	check("with the Warrior as second: its tree and the Shadow Blade links, not the Night Thunder ones", g.learn("spin") and g.tabs() == [3, 0, 4, 38] and Sk.blocked(g.tree, "dl_mark", 40, true, 3, 0) == Sk.NOT_YOURS)
	check("the danger point bar shows for an Assassin", g.uses_cp())

	# --- danger points
	await rogue({"slash": 1, "keen": 1})
	var a = dummy("porter", Vector2(30, 0))
	check("you stand behind a foe that faces away", g.is_behind(a))
	await strike(a)
	check("a strike from behind gives a danger point", g.p.cp == 1)
	a.flip = true
	await strike(a)
	check("a strike from the front gives none", g.p.cp == 1 and not g.is_behind(a))
	g.stagger(a, 9.0)
	await strike(a)
	check("a strike on a stunned foe gives one", g.p.cp == 2)
	g.p.cp = 5
	a.state = "rec"
	await strike(a)
	g.add_cp(3)
	check("five is the most", g.p.cp == 5)
	g.p.cp = 0
	g.sim.move = Vector2.UP
	g.sim.dodge = true
	await frames(2)
	g.sim.dodge = false
	g.hurt(20.0)
	g.sim.move = Vector2.ZERO
	check("dodging a hit gives one", g.p.cp == 1 and g.p.hp == g.stats.mhp)
	await frames(30)

	# --- finishers
	await rogue({"slash": 1, "vital": 2, "exec": 1})
	a = dummy("porter", Vector2(30, 0))
	a.flip = true
	g.sim.mouse = a.pos
	seed(5)
	await tap("s1")
	await frames(30)
	var zero = 5000.0 - a.hp
	check("slash with no points is weak, and still usable (%.0f)" % zero, zero > 0.0 and zero < g.stats.atk * 0.6 * 1.15)
	a.hp = 5000.0
	g.p.cds.clear()
	g.p.cp = 4
	seed(5)
	await tap("s1")
	await frames(30)
	check("slash with four points hits five times as hard and spends them (%.0f)" % (5000.0 - a.hp), absf((5000.0 - a.hp) - g.stats.atk * 3.0) < g.stats.atk * 0.36 and g.p.cp == 0)
	g.p.cp = 0
	check("execute needs a point", not g.can_cast("exec"))
	var weak = dummy("reed", Vector2(30, 20), 1000.0)
	weak.hp = 150.0
	weak.flip = true
	g.p.cp = 3
	g.sim.mouse = weak.pos
	a.pos += Vector2(300, 0)
	await frames(2)
	await tap("s2")
	await frames(30)
	check("execute kills an ordinary foe under 6% life per point", weak.state == "dead")
	var elite = dummy("reed", Vector2(30, 0), 1000.0)
	g.make_elite(elite, "warding")
	elite.hp = 150.0
	elite.flip = true
	g.p.cds.clear()
	g.p.cp = 3
	g.sim.mouse = elite.pos
	await frames(2)
	await tap("s2")
	await frames(30)
	check("but only hurts an elite", elite.hp < 150.0 and elite.state != "dead" or elite.hp <= 0.0 and g.stats.atk * 3.0 >= 150.0)

	# --- shadow step, smoke
	await rogue({"shadow": 1, "light": 1, "backstab": 3, "smoke": 1, "slash": 1})
	a = dummy("porter", Vector2(100, 0))
	a.flip = true
	g.sim.mouse = a.pos
	await frames(2)
	await tap("s1")
	check("shadow step puts you behind the foe", g.is_behind(a) and g.p.pos.distance_to(a.pos) < 40.0)
	await strike(a)
	check("and the next strike is sure to give a point", g.p.cp == 1)
	g.p.cds.clear()
	g.sim.mouse = g.p.pos + Vector2(0, -300)
	a.pos += Vector2(0, 400)
	await frames(2)
	g.p.rage = 100.0
	await tap("s1")
	check("with no foe in reach it is not spent", not g.p.cds.has("shadow") and absf(g.p.rage - 100.0) < 1.0)
	a.pos = g.p.pos + Vector2(60, 0)
	a.state = "chase"
	a.cd = 99.0
	var boss = dummy("keeper", Vector2(-80, 0))
	boss.state = "chase"
	boss.cd = 99.0
	await tap("s2")
	await frames(6)
	check("smoke makes an ordinary foe lose you, but not a boss", a.state == "idle" and boss.state == "chase" and g.p.smoke > 2.0)
	boss.pos += Vector2(-400, 0)
	a.state = "rec"
	a.flip = true
	a.hp = 5000.0
	seed(9)
	g.sim.mouse = a.pos
	await strike(a)
	check("the first strike out of the smoke is a critical one and ends it (%.0f)" % (5000.0 - a.hp), 5000.0 - a.hp > g.stats.atk * 1.75 and g.p.smoke == 0.0)

	# --- poison
	await rogue({"venom": 1, "potent": 1, "darts": 1, "slash": 1})
	a = dummy("porter", Vector2(30, 0))
	a.flip = true
	await strike(a)
	check("no poison without the coating", a.get("poison", 0) == 0)
	await tap("s1")
	await strike(a)
	await strike(a)
	check("coated strikes stack poison", a.poison == 2)
	a.hp = 5000.0
	g.p.venom = 0.0
	await frames(60)
	var per = 5000.0 - a.hp
	check("two stacks deal twice a fifth of attack a second, with potency (%.1f)" % per, absf(per - 2.0 * g.poison_dps()) < g.stats.atk * 0.05 and absf(g.poison_dps() - g.stats.atk * 0.22) < 0.001)
	g.poison(a, 9)
	check("five stacks at most", a.poison == 5)
	await frames(260)
	check("poison wears off", a.poison == 0)
	var b = dummy("reed", Vector2(90, 0))
	g.sim.mouse = b.pos
	a.pos += Vector2(0, 300)
	await frames(2)
	await tap("s2")
	await frames(30)
	check("darts poison at range", b.get("poison", 0) >= 1 and b.hp < 5000.0)

	# --- keystones
	await rogue({"venom": 1, "potent": 3, "linger": 1, "burst": 1, "slash": 1})
	a = dummy("porter", Vector2(30, 0))
	a.flip = true
	g.poison(a, 9)
	check("burst: three stacks at most", a.poison == 3)
	var owed = a.poison * a.poison_t * g.poison_dps()
	g.sim.mouse = a.pos
	seed(3)
	await tap("s2")
	await frames(30)
	check("burst: a finisher makes the remaining poison act at once (%.0f owed)" % owed, a.poison == 0 and 5000.0 - a.hp > owed)

	await rogue({"slash": 1, "keen": 3, "vital": 1, "six": 1})
	check("six: a sixth point", g.cp_cap() == 6)
	await rogue({"shadow": 1, "light": 3, "backstab": 1, "unseen": 1, "slash": 1})
	check("unseen: a fifth less life", absf(g.stats.mhp - (90.0 + 40 * 10.0) * 0.8) < 0.01)
	a = dummy("porter", Vector2(30, 0))
	g.sim.mouse = a.pos
	await tap("s2")
	check("unseen: a finisher hides you", g.p.smoke > 1.0)

	# --- the ultimate
	await rogue({"slash": 1, "keen": 3, "vital": 3, "ruthless": 1, "cuts": 1})
	var line = []
	for i in 7:
		line.append(dummy("reed", Vector2(30 + i * 20, (i % 2) * 30)))
	await tap("ult")
	await frames(4)
	check("a thousand cuts strikes six foes and fills the points", line.filter(func(f): return f.hp < 5000.0).size() == 6 and g.p.cp == 5 and g.p.cds.get("cuts", 0.0) > 40.0)

	# --- Shadow Blade links (Warrior + Assassin)
	await rogue({"slash": 1, "bulwark": 1, "lb_open": 1}, 0)
	await tap("s2")
	g.hurt(20.0)
	check("opening: a blocked hit gives two points", g.p.cp == 2)

	await rogue({"slash": 1, "lb_last": 1}, 0)
	a = dummy("porter", Vector2(30, 0))
	a.flip = true
	await strike(a)
	await strike(a)
	check("the last cut: no point before the end of the chain", g.p.cp == 0)
	await strike(a)
	check("the last cut: the third strike gives one, even from the front", g.p.cp == 1)

	await rogue({"slash": 1, "lb_fallen": 1}, 0)
	a = dummy("porter", Vector2(30, 0))
	a.flip = true
	g.stagger(a, 9.0)
	g.p.cp = 4
	g.sim.mouse = a.pos
	await tap("s1")
	await frames(30)
	check("cutting the fallen: slash on a stunned foe keeps the points", g.p.cp == 4)
	g.p.cds.clear()
	await tap("s1")
	await frames(30)
	check("but not twice within four seconds", g.p.cp == 0)

	await rogue({"venom": 1, "spin": 1, "lb_ring": 1}, 0)
	a = dummy("porter", Vector2(30, 0))
	b = dummy("porter", Vector2(-30, 0))
	g.poison(a, 4)
	await tap("s2")
	await frames(40)
	check("ring of poison: spin spreads the highest stack", b.poison == 4)

	await rogue({"exec": 1, "slash": 1, "keen": 1, "lb_boil": 1}, 0)
	weak = dummy("reed", Vector2(30, 0), 1000.0)
	weak.hp = 50.0
	g.p.cp = 2
	g.p.rage = 0.0
	g.sim.mouse = weak.pos
	await tap("s1")
	await frames(30)
	check("boiling blood: an execution that kills gives 30 rage", weak.state == "dead" and g.p.rage >= 30.0)

	await rogue({"smoke": 1, "shadow": 1, "light": 1, "cry": 1, "spin": 1, "bloodlust": 1, "lb_cry": 1}, 0)
	await tap("s1")
	var s0 = g.p.smoke
	g.cast("cry")
	check("a cry in the smoke lengthens it", g.p.smoke > s0 + 1.5)

	await rogue({"shadow": 1, "lunge": 1, "lb_follow": 1}, 0)
	check("following the shadow: shadow step costs rage as a rule", g.skill_cost("shadow") == 10.0)
	g.cast("lunge")
	check("and nothing for three seconds after a lunge", g.skill_cost("shadow") == 0.0)

	await rogue({"slash": 1, "bulwark": 1, "lb_twin": 1}, 0)
	a = dummy("porter", Vector2(30, 0))
	a.flip = true
	check("twin blades: faster strikes, and no guard", absf(g.cur_atk()[0] - g.ATK[0][0] * 0.8) < 0.0001 and not g.can_cast("bulwark"))
	await strike(a)
	check("twin blades: the first strike carries no poison", a.get("poison", 0) == 0)
	await strike(a)
	check("twin blades: the second one does", a.poison == 1)

	# --- Night Thunder links (Elementalist + Assassin)
	await rogue({"slash": 1, "ember": 1, "dl_mark": 1}, 1)
	check("with the Elementalist as second the tabs change", g.tabs() == [3, 1, 5, 38])
	a = dummy("porter", Vector2(200, 0))
	g.mark(a, "burn")
	check("opening mark: a new mark gives a point", g.p.cp == 1)
	g.mark(a, "burn")
	g.mark(a, "chill")
	check("not a mark the foe already has, and not twice in a row", g.p.cp == 1)

	await rogue({"slash": 1, "ember": 1, "kindle": 1, "dl_rupture": 1}, 1)
	a = dummy("porter", Vector2(30, 0))
	a.flip = true
	g.mark(a, "burn")
	owed = a.burn * a.burn_dps
	g.sim.mouse = a.pos
	seed(4)
	await tap("s1")
	await frames(30)
	check("rupture: slash cashes in the burn and puts it out (%.0f owed)" % owed, a.burn == 0.0 and 5000.0 - a.hp > owed)

	await rogue({"slash": 1, "ring": 1, "dl_frozen": 1}, 1)
	a = dummy("porter", Vector2(30, 0))
	a.flip = true
	check("a foe seen from the front is not open", not g.is_behind(a))
	g.mark(a, "chill")
	check("chilled is open: a chilled foe always counts as seen from behind", g.is_behind(a))

	await rogue({"smoke": 1, "shadow": 1, "light": 1, "ring": 1, "dl_fog": 1}, 1)
	a = dummy("porter", Vector2(200, 0))
	g.mark(a, "chill")
	var plain = a.chill
	g.p.smoke = 3.0
	g.mark(a, "chill")
	check("frost fog: chill laid from inside the smoke lasts twice as long", absf(a.chill - plain * 2.0) < 0.01)

	await rogue({"shadow": 1, "spark": 1, "dl_step": 1}, 1)
	a = dummy("porter", Vector2(100, 0))
	b = dummy("reed", Vector2(80, 16))
	g.sim.mouse = a.pos
	await frames(2)
	await tap("s1")
	check("thunder step: foes at the place you arrive are shocked", a.shock > 0.0 and b.shock > 0.0)

	await rogue({"venom": 1, "ember": 1, "ring": 1, "dl_coat": 1}, 1)
	a = dummy("porter", Vector2(30, 0))
	a.flip = true
	g.p.venom = 8.0
	g.p.elem = "chill"
	await strike(a)
	check("elemental coating: a coated strike leaves the mark of your last spell", a.chill > 0.0 and a.poison == 1)

	await rogue({"exec": 1, "slash": 1, "keen": 1, "spark": 1, "dl_judge": 1}, 1)
	a = dummy("porter", Vector2(30, 0))
	b = dummy("reed", Vector2(30, 60))
	g.mark(a, "shock")
	g.p.cp = 2
	g.sim.mouse = a.pos
	await tap("s1")
	await frames(30)
	check("judged by lightning: executing a shocked foe throws a spark on", b.shock > 0.0 and b.hp < 5000.0)

	await rogue({"slash": 1, "ember": 1, "ring": 1, "spark": 1, "dl_three": 1}, 1)
	a = dummy("porter", Vector2(30, 0))
	a.flip = true
	g.mark(a, "burn")
	check("three poisons: your marks are 30% shorter", absf(a.burn - 4.0 * 0.7) < 0.01)
	g.p.cp = 2
	seed(6)
	g.sim.mouse = a.pos
	await tap("s1")
	await frames(30)
	var two = 5000.0 - a.hp
	a.hp = 5000.0
	for mk in ["burn", "chill", "shock"]:
		g.mark(a, mk)
	g.p.cds.clear()
	g.p.cp = 2
	seed(6)
	await tap("s1")
	await frames(30)
	check("three poisons: a finisher on all three marks hits much harder and clears them (%.0f against %.0f)" % [5000.0 - a.hp, two], 5000.0 - a.hp > two * 1.5 and a.burn == 0.0 and a.chill == 0.0 and a.shock == 0.0)

	# --- choosing the second mastery, with menus on
	D.MENUS = 1
	g.new_game()
	g.main_m = 0
	g.mode = "play"
	g.enter_zone("town", Vector2.ZERO)
	g.fresh_hero()
	quiet()
	for id in ["m1", "m2", "m3", "m4", "m5"]:
		g.qs[id] = "done"
	g.qs["m6"] = "active"
	g.qc["m6"] = {}
	g.turnin("m6")
	check("when the shard wakes, a Warrior is asked to choose", g.mode == "second" and g.second_m == -1)
	var view = g.get_viewport_rect().size
	g.sim.ui_mouse = g.Menu.card_rect(view, 0).get_center()
	await tap("atk")
	check("the first mastery cannot be chosen again", g.csel != 0)
	await tap("menu")
	check("the choice cannot be escaped", g.mode == "second")
	g.sim.ui_mouse = g.Menu.card_rect(view, 3).get_center()
	await tap("atk")
	g.sim.ui_mouse = g.Menu.start_rect(view).get_center()
	await tap("atk")
	g.sim.ui_mouse = Vector2(-50, -50)
	check("choosing the Assassin makes a Shadow Blade", g.mode == "play" and g.second_m == 3 and g.tabs() == [0, 3, 4, 36])
	g.lvl = 10
	check("its tree opens", g.learn("slash") and not g.learn("ember"))
	g.save_game()
	g.new_game()
	check("the choice is saved", g.load_game() and g.second_m == 3 and g.tree.has("slash"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH.replace(".json", "_opt.json")))
	print("RESULT: %s" % ("OK" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
