extends SceneTree
# Plays the whole first chapter: intro, six main quests, two side quests, a choice, the scene in the
# dungeon, the boss, loot, the shop, save and return.
const Bot = preload("res://tests/bot.gd")
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

func idle_input() -> void:
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.sim.mouse = g.p.pos + Vector2(40, 0)
	g.sim.ui_mouse = Vector2.ZERO

# press E until the talk ends or stops at a choice
func read_on() -> void:
	var n = 0
	while g.mode == "talk" and not g.Ui.choosing(g) and n < 30:
		await tap("use")
		n += 1

func talk_to(id: String) -> void:
	for n in g.zone.npcs:
		if n.id == id:
			g.p.pos = n.pos + Vector2(0, 16)
	await tap("use")
	await read_on()

func look_at(id: String) -> bool:
	for th in g.zone.things:
		if th.id == id:
			g.p.pos = th.pos
			await tap("use")
			await read_on()
			return true
	return false

func arena(zone: String) -> void:
	g.sim.no_spawns = true
	g.enter_zone(zone, Vector2.ZERO)
	g.sim.no_spawns = false
	g.mode = "play"
	g.fresh_hero()
	if zone == "field":
		g.p.pos = Vector2(34 * 16, 23 * 16)   # middle of the dyke, away from the exits
		g.cam = g.p.pos
	idle_input()

# fight until `done` says so, keeping the hero alive
func fight(done: Callable, limit: int) -> int:
	var n = 0
	while not done.call() and n < limit:
		Bot.drive(g)
		g.p.hp = g.stats.mhp
		await process_frame
		n += 1
	idle_input()
	return n

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)
	idle_input()
	check("a new game opens on the narrated intro", g.mode == "talk" and g.talk.name == "" and g.talk.lines == D.INTRO)
	await read_on()
	check("starts in town, level 1, with a weapon", g.mode == "play" and g.zone.id == "town" and g.lvl == 1 and g.eq.weapon != null)
	var art_ok = true
	for n in g.Art.SPRITES:
		art_ok = art_ok and g.Art.T.has(n)
	check("every sprite loaded", art_ok)
	for id in ["town", "field", "dungeon"]:
		var z = g.World.build(id)
		var ok = g.World.build(id).spawns.size() == z.spawns.size() and g.World.build(id).decor.size() == z.decor.size()
		for po in z.portals:
			var dest = g.World.build(po.to)
			ok = ok and dest.grid[int(po.at.y / 16)][int(po.at.x / 16)] != 0
		check("zone %s is stable and its exits land on ground" % id, ok)
	var fz = g.World.build("field")
	check("the marsh has its three sandals, the boat, the sign, a debtor and a mute clapper", fz.things.size() == 7)
	for id in D.ORDER:
		for a in D.QUESTS[id].after:
			if D.ORDER.find(a) < 0:
				check("quest %s names a real prerequisite" % id, false)

	# --- combat rules
	arena("field")
	var f = g.spawn("reed", g.p.pos + Vector2(26, 0))
	f.cd = 99.0
	await tap("atk")
	await frames(18)
	check("first strike lands", f.hp < f.mhp and f.hp > 0.0)
	g.sim.mouse = f.pos
	await tap("atk")
	await frames(22)
	g.sim.mouse = f.pos
	await tap("atk")
	await frames(40)
	check("three-hit chain kills a reed shade", f.hp <= 0.0)
	check("the kill gives experience", g.xp > 0)

	arena("field")
	var x0 = g.p.pos.x
	g.sim.move = Vector2.RIGHT
	await tap("dodge")
	g.sim.move = Vector2.ZERO
	await frames(40)
	check("dodge travels about 64 px (%.1f)" % (g.p.pos.x - x0), g.p.pos.x - x0 > 50.0 and g.p.pos.x - x0 < 80.0)
	check("dodge spends a charge", g.p.dodges == 1)

	arena("field")
	f = g.spawn("porter", g.p.pos + Vector2(30, 0))
	f.state = "chase"
	f.cd = 0.0
	await frames(150)
	check("standing in a slam hurts", g.p.hp < g.stats.mhp)

	arena("field")
	f = g.spawn("reed", g.p.pos + Vector2(20, 0))
	f.state = "chase"
	f.cd = 0.0
	var dodged = false
	for i in 240:
		if f.state == "wind" and f.st >= 0.36 and not dodged:
			dodged = true
			g.sim.move = Vector2.UP
			g.sim.dodge = true
		elif dodged:
			g.sim.dodge = false
		await process_frame
		if dodged and f.state == "rec":
			break
	check("dodging through a swipe avoids it", dodged and g.p.hp == g.stats.mhp)
	idle_input()

	arena("field")
	f = g.spawn("reed", g.p.pos + Vector2(140, 0))
	await frames(30)
	check("a far foe stays idle", f.state == "idle")
	f.pos = g.p.pos + Vector2(60, 0)
	await frames(10)
	check("a near foe gives chase", f.state != "idle")

	# --- the chapter
	g.new_game()
	g.recompute()
	arena("town")
	check("only Madam Say has work at first", g.npc_mark("say") == "!" and g.npc_mark("kham") == "" and g.npc_mark("dien") == "")
	await talk_to("say")
	check("m1: sent to Ngai", g.qs.get("m1") == "active" and g.npc_mark("ngai") == "?")
	await talk_to("ngai")
	check("m1: Ngai tunes the shard", g.qs.get("m1") == "done" and g.xp > 0)
	await talk_to("say")
	check("m2: reed shades", g.qs.get("m2") == "active")
	arena("field")
	for i in 6:
		g.spawn("reed", g.p.pos + Vector2.from_angle(i) * 50.0)
	var n = await fight(func(): return g.qs.get("m2") == "ready", 60 * 120)
	check("m2: six reed shades make it ready (%d frames)" % n, g.qs.get("m2") == "ready")
	arena("town")
	await talk_to("say")
	# the reward is the last thing put in the bag; foes may have dropped other items before it
	var vest = g.inv.size() - 1
	check("m2: handed in for gold and a vest", g.qs.get("m2") == "done" and g.gold >= 30 and vest >= 0 and g.inv[vest].slot == "armor" and g.inv[vest].rar == 1)
	var def0 = g.stats.def
	g.eq.armor = null
	g.recompute()
	g.equip(vest)
	check("wearing the vest raises armor", g.stats.def > def0)

	g.sim.no_spawns = true
	g.enter_zone("field", Vector2.ZERO)
	g.sim.no_spawns = false
	g.p.pos = g.zone.portals[1].rect.get_center() + Vector2(0, 30)
	g.sim.move = Vector2.UP
	await frames(90)
	check("the ferry road is barred before its quest", g.zone.id == "field")
	idle_input()

	arena("town")
	await talk_to("kham")
	check("m3: Kham wants echo ash, and the shop stays shut", g.qs.get("m3") == "active" and g.mode == "play")
	await talk_to("dien")
	check("m4: the warden wants the porter down", g.qs.get("m4") == "active")
	await talk_to("say")
	check("s1: a side quest from Madam Say", g.qs.get("s1") == "active")
	await talk_to("ngai")
	check("s2: a side quest from Ngai", g.qs.get("s2") == "active")
	arena("field")
	for i in 4:
		g.spawn("heron", g.p.pos + Vector2.from_angle(i * 1.5) * 70.0)
	g.spawn("porter", g.p.pos + Vector2(0, 60))
	n = await fight(func(): return g.qs.get("m3") == "ready" and g.qs.get("m4") == "ready", 60 * 180)
	check("m3 and m4: ash gathered, porter down (%d frames)" % n, g.qs.get("m3") == "ready" and g.qs.get("m4") == "ready")

	# side quests out in the marsh
	var seen = 0
	for id in ["sandal_a", "sandal_b", "sandal_c"]:
		if await look_at(id):
			seen += 1
	check("s2: three pairs of sandals found", seen == 3 and g.qs.get("s2") == "ready")
	await look_at("widow")
	check("s1: the net-mender ends in a choice", g.mode == "talk" and g.Ui.choosing(g))
	await tap("use")
	check("a choice cannot be skipped", g.mode == "talk" and g.Ui.choosing(g))
	await tap("opt1")
	await read_on()
	check("s1: forgiving the debt is remembered", g.flags.get("debt", -1) == 0 and g.qs.get("s1") == "ready" and g.mode == "play")
	await look_at("widow")
	check("the net-mender is gone afterwards", g.mode == "play")

	arena("town")
	await talk_to("kham")
	check("m3: handed in for a better weapon", g.qs.get("m3") == "done")
	await talk_to("dien")
	check("m4: handed in", g.qs.get("m4") == "done")
	var gold1 = g.gold
	await talk_to("say")
	check("s1: the kind ending pays in a charm, not gold", g.qs.get("s1") == "done" and g.gold == gold1)
	await talk_to("say")
	check("m5: sent to the Old Ferry", g.qs.get("m5") == "active")
	await talk_to("ngai")
	check("s2: handed in", g.qs.get("s2") == "done")
	g.inv.insert(0, D.make_item("charm", 0, 0))
	var before = g.inv.size()
	await talk_to("kham")
	check("with no quest business Kham opens the shop", g.mode == "inv" and g.shop)
	g.sim.ui_mouse = g.Ui.bag_cell(g.get_viewport_rect().size, 0).get_center()
	var gold0 = g.gold
	await tap("atk")
	check("clicking an item in the shop sells it", g.inv.size() == before - 1 and g.gold > gold0)
	var pots = g.potions
	await tap("buy")
	check("B buys a potion", g.potions == pots + 1)
	await tap("inv")
	check("the bag closes", g.mode == "play")
	g.p.hp = 10.0
	await talk_to("ngai")
	check("Ngai restores life", g.p.hp == g.stats.mhp)

	arena("field")
	g.p.pos = g.zone.portals[1].rect.get_center() + Vector2(0, 30)
	g.sim.move = Vector2.UP
	await frames(120)
	check("the ferry road now leads to the dungeon", g.zone.id == "dungeon")
	idle_input()
	var boss = null
	for q in g.foes:
		if q.kind == "boss":
			boss = q
	g.foes = [boss]
	g.p.pos = g.zone.scenes[0].rect.get_center()
	await frames(3)
	check("walking into the toll yard plays Van's echo", g.mode == "talk" and g.talk.has("ghost"))
	await read_on()
	check("the scene is remembered", g.flags.has("seen_van") and g.mode == "play")
	await frames(5)
	check("the scene does not replay", g.mode == "play")

	g.p.pos = boss.pos + Vector2(-80, 0)
	var used = {}
	n = 0
	while boss.hp > 0.0 and n < 60 * 240:
		Bot.drive(g)
		g.p.hp = g.stats.mhp
		if boss.state == "wind":
			used[boss.atk] = true
		await process_frame
		n += 1
	idle_input()
	check("the Ferryman falls (%d frames)" % n, boss.hp <= 0.0)
	check("he used sweep, slam and volley, and called help (%s, %d)" % [str(used.keys()), boss.sum], used.has("sweep") and used.has("slam") and used.has("volley") and boss.sum == 2)
	check("m5: seeing Van and ending the crossing make it ready", g.qs.get("m5") == "ready")
	await fight(func(): return g.foes.is_empty(), 60 * 60)
	for i in 600:
		var best = null
		for o in g.drops:
			if o.kind == "item" and (best == null or o.item.rar > best.item.rar):
				best = o
		if best == null:
			break
		g.sim.move = (best.pos - g.p.pos).limit_length(1.0)
		await process_frame
	idle_input()
	var idx = -1
	for i in g.inv.size():
		if g.inv[i].uniq == "wave":
			idx = i
	check("the oar is picked up", idx >= 0)
	if idx >= 0:
		g.equip(idx)
		arena("field")
		f = g.spawn("porter", g.p.pos + Vector2(90, 0))
		f.cd = 99.0
		f.state = "stun"
		f.stun = 99.0
		g.sim.mouse = f.pos
		for i in 3:
			await tap("atk")
			await frames(24)
		await frames(30)
		check("the third strike with the oar throws a wave that reaches a far foe", f.hp < f.mhp)

	arena("town")
	await talk_to("say")
	check("m5 handed in, m6 starts by itself", g.qs.get("m5") == "done" and g.qs.get("m6") == "active")
	await talk_to("ngai")
	check("m6: the chapter ends with the second face of the shard", g.qs.get("m6") == "done" and g.main_done() == 6)

	var lv0 = g.lvl
	var hp0 = g.stats.mhp
	g.give_xp(D.xp_need(g.lvl))
	check("experience raises the level and life", g.lvl == lv0 + 1 and g.stats.mhp > hp0)

	# save and return
	var snap = [g.lvl, g.gold, g.inv.size(), g.eq.weapon.name, g.qs.duplicate(), g.flags.get("debt")]
	g.save_game()
	g.new_game()
	check("a saved game loads back the same", g.load_game() and snap == [g.lvl, g.gold, g.inv.size(), g.eq.weapon.name, g.qs, g.flags.get("debt")])

	# death
	arena("field")
	g.gold = 100
	g.hurt(99999.0)
	await frames(60 * 4)
	check("falling wakes you in town for a tenth of your gold", g.zone.id == "town" and g.p.state != "dead" and g.gold == 90 and g.p.hp == g.stats.mhp)
	print("RESULT: %s" % ("OK" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
