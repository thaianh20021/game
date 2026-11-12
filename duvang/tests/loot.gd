extends SceneTree
# Items: twenty bases, twelve properties, four uniques, the filter and the elite hunt.
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

func setup() -> void:
	g.new_game()
	g.lvl = 10
	g.loot_filter = 0
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

func dummy(kind: String, off: Vector2, hp: float = 5000.0) -> Dictionary:
	var f = g.spawn(kind, g.p.pos + off)
	f.cd = 9999.0
	f.state = "rec"
	f.st = -9999.0
	f.hp = hp
	f.mhp = hp
	return f

func wear(it: Dictionary) -> void:
	g.eq[it.slot] = it
	g.recompute()

func plain(slot: String, stats: Dictionary) -> Dictionary:
	return {"name": "TEST", "slot": slot, "rar": 0, "tier": 0, "stats": stats, "uniq": ""}

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_loot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)

	# --- the tables
	var n = 0
	var names = {}
	var ok = true
	for slot in D.SLOTS:
		for t in 3:
			ok = ok and D.BASES[slot].filter(func(b): return b[1] == t).size() >= 2
		for b in D.BASES[slot]:
			n += 1
			names[b[0]] = true
			for k in b[2]:
				ok = ok and D.STAT_NAME.has(k)
	check("twenty-three base items (three of them bows), all named differently, at least two per slot and tier", n == 23 and names.size() == 23 and ok)
	ok = true
	var stats = {}
	for a in D.AFFIX:
		stats[a[0]] = true
		ok = ok and D.STAT_NAME.has(a[0]) and not a[4].is_empty() and a[2] <= a[3]
	check("twelve properties, each a different stat", D.AFFIX.size() == 12 and stats.size() == 12 and ok)
	for slot in D.SLOTS:
		check("%s can roll at least five properties" % slot, D.AFFIX.filter(func(a): return a[4].has(slot)).size() >= 5)
	ok = true
	for i in 300:
		var it = D.make_item(D.SLOTS[i % 3], i % 3, 2)
		var base = D.BASES[it.slot].filter(func(b): return it.name.begins_with(b[0]))[0]
		var extra = 0
		for k in it.stats:
			if it.stats[k] != base[2].get(k, 0):
				extra += 1
				ok = ok and D.AFFIX.any(func(a): return a[0] == k and a[4].has(it.slot))
		ok = ok and extra == 2
	check("a rare item has exactly two properties, both allowed on its slot", ok)
	check("the starting weapon is always the reed cutter", D.make_item("weapon", 0, 0, 0).name == "DAO CẮT LAU")
	var u = [D.ferry_oar(), D.toll_box(), D.elite_unique("volatile"), D.elite_unique("warding"), D.seed_unique(), D.admiral_unique(), D.forge_unique(), D.eight_unique()]
	ok = true
	for it in u:
		ok = ok and it.rar == 3 and D.UNIQ_TEXT.has(it.uniq) and D.UNIQ_TEXT[it.uniq].length() <= 40
	check("eight uniques, each with its own effect", ok and D.UNIQ_TEXT.size() == 8)

	# --- what the stats do
	await setup()
	var base_reach = g.cur_atk()[4]
	var base_start = g.cur_atk()[0]
	wear(plain("weapon", {"atk": 4, "reach": 8}))
	check("reach lengthens the strike", g.cur_atk()[4] == base_reach + 8.0)
	wear(plain("weapon", {"atk": 4, "haste": 25}))
	check("strike speed shortens the wind-up", absf(g.cur_atk()[0] - base_start / 1.25) < 0.0001)
	wear(plain("weapon", {"atk": 4, "haste": -12}))
	check("a slow weapon lengthens it", g.cur_atk()[0] > base_start)
	g.p.skill = "spin"
	check("skills are not sped up or slowed by the weapon", g.cur_atk()[0] == Sk.SWING.spin[0])
	g.p.skill = ""

	await setup()
	var a = dummy("porter", Vector2(30, 0))
	a.poise = 30.0
	g.hit_foe(a, 10.0, false, 0.0, 0.0)
	var lost = 30.0 - a.poise
	wear(plain("weapon", {"atk": 4, "stag": 50}))
	a.poise = 30.0
	a.hp = 5000.0
	g.hit_foe(a, 10.0, false, 0.0, 0.0)
	check("stance damage empties a stance faster (%.1f against %.1f)" % [30.0 - a.poise, lost], (30.0 - a.poise) > lost * 1.2)

	await setup()
	a = dummy("porter", Vector2(30, 0))
	wear(plain("charm", {"crit": 100}))
	g.hit_foe(a, 100.0, false, 0.0, 0.0)
	check("a critical hit deals double", 5000.0 - a.hp > 175.0)
	wear(plain("charm", {"cdr": 20}))
	g.tree = {"lunge": 1}
	check("cooldown reduction shortens cooldowns", absf(g.skill_cd("lunge") - 4.0) < 0.001)
	wear(plain("charm", {"cdr": 90}))
	check("but never by more than 40%", absf(g.skill_cd("lunge") - 3.0) < 0.001)
	g.tree = {}
	wear(plain("charm", {"regen": 3}))
	g.p.hp = 50.0
	await frames(60)
	check("life per second mends you (%.1f)" % (g.p.hp - 50.0), absf(g.p.hp - 53.0) < 0.3)
	await setup()
	wear(plain("charm", {"gold": 100}))
	var reed = dummy("reed", Vector2(30, 0), 1.0)
	seed(3)
	g.hit_foe(reed, 50.0, false, 0.0, 0.0)
	var rich = 0
	for o in g.drops:
		if o.kind == "gold":
			rich += o.n
	check("gold found raises the coins a foe drops (%d)" % rich, rich >= 2)

	# --- uniques
	await setup()
	g.tree = {"spin": 1}
	g.bar[0] = "spin"
	wear(D.elite_unique("volatile"))
	a = dummy("porter", Vector2(30, 0))
	g.p.rage = 0.0
	check("the wrap: no free skill yet", not g.can_cast("spin"))
	g.sim.move = Vector2.UP
	g.sim.dodge = true
	await frames(2)
	g.sim.dodge = false
	g.hurt(30.0)
	g.sim.move = Vector2.ZERO
	check("the wrap: dodging a hit arms a free skill", g.p.free and g.p.hp == g.stats.mhp and g.can_cast("spin"))
	await frames(30)
	g.p.pos = a.pos + Vector2(-30, 0)
	g.p.rage = 0.0
	await tap("s1")
	await frames(40)
	check("the wrap: the next skill costs nothing, once", a.hp < 5000.0 and not g.p.free and not g.can_cast("spin"))

	await setup()
	wear(D.elite_unique("warding"))
	g.p.hp = 50.0
	reed = dummy("reed", Vector2(30, 0), 1.0)
	g.hit_foe(reed, 50.0, false, 0.0, 0.0)
	check("the wick: an ordinary kill heals nothing", absf(g.p.hp - 50.0) < 3.1)
	var h0 = g.p.hp
	reed = dummy("reed", Vector2(30, 0), 1.0)
	g.mark(reed, "burn")
	g.hit_foe(reed, 50.0, false, 0.0, 0.0)
	check("the wick: killing a burning foe heals 4% life", absf((g.p.hp - h0) - g.stats.mhp * 0.04) < 0.5)

	# --- the hunt for an elite's unique
	await setup()
	var kills = []
	for trial in 40:
		g.flags.erase("pity")
		g.drops.clear()
		var k = 0
		while k < 40:
			k += 1
			var e = dummy("reed", Vector2(300, 0), 1.0)
			g.make_elite(e, "volatile")
			e.hp = 1.0
			g.hit_foe(e, 50.0, false, 0.0, 0.0)
			g.blasts.clear()
			if g.drops.any(func(o): return o.kind == "item" and o.item.uniq == "free"):
				break
		kills.append(k)
	var worst = kills.max()
	var mean = 0.0
	for k in kills:
		mean += k
	mean /= kills.size()
	check("an elite's unique always drops within 16 kills (worst %d, mean %.1f)" % [worst, mean], worst <= 16 and mean > 2.0 and mean < 7.0)
	check("the counter resets after a drop", g.flags.get("pity", 0) == 0)
	g.drops.clear()
	g.flags["pity"] = 15
	var e2 = dummy("heron", Vector2(300, 0), 1.0)
	g.make_elite(e2, "warding")
	e2.hp = 1.0
	g.hit_foe(e2, 50.0, false, 0.0, 0.0)
	check("a warding elite drops the wick, a volatile one the wrap", g.drops.any(func(o): return o.kind == "item" and o.item.uniq == "wick"))

	# --- the filter
	await setup()
	g.drops.clear()
	g.drops.append({"pos": g.p.pos, "vel": Vector2.ZERO, "t": 1.0, "kind": "item", "n": 0, "item": D.make_item("armor", 0, 0)})
	g.drops.append({"pos": g.p.pos, "vel": Vector2.ZERO, "t": 1.0, "kind": "item", "n": 0, "item": D.make_item("armor", 0, 2)})
	await tap("filter")
	check("L steps the filter", g.loot_filter == 1)
	await frames(10)
	check("a filtered item stays on the ground, a better one is picked up", g.inv.size() == 1 and g.inv[0].rar == 2 and g.drops.size() == 1)
	await tap("filter")
	await tap("filter")
	await frames(10)
	check("with the filter off it is picked up too", g.loot_filter == 0 and g.inv.size() == 2 and g.drops.is_empty())
	g.save_game()
	g.loot_filter = 2
	g.load_game()
	check("the filter setting is saved", g.loot_filter == 0)

	# --- selling junk
	g.inv = [D.make_item("armor", 0, 0), D.make_item("charm", 1, 1), D.make_item("weapon", 0, 0), D.ferry_oar(), D.make_item("armor", 2, 2)]
	g.gold = 0
	check("junk selling takes the commons only", g.sell_junk() == 2 and g.inv.size() == 3 and g.gold > 0)
	g.loot_filter = 2
	check("with a rare filter it takes magic items too, never uniques", g.sell_junk() == 1 and g.inv.size() == 2 and g.inv.any(func(it): return it.rar == 3))
	g.loot_filter = 0
	g.open_inv(true)
	g.inv.append(D.make_item("armor", 0, 0))
	await tap("reset")
	check("X in the shop sells the junk", g.inv.size() == 2)
	print("RESULT: %s" % ("OK" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
