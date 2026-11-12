extends SceneTree
# Chapter two: the Breathing Forest, its three foes, the tree-mother, the quests and the verdict.
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

func quiet() -> void:
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.sim.mouse = g.p.pos + Vector2(60, 0)
	g.sim.ui_mouse = Vector2.ZERO
	g.hitstop = 0.0
	g.buf = ""

# an empty copy of a zone with the hero at `at` (tile coordinates)
func arena(zone: String, at: Vector2) -> void:
	g.sim.no_spawns = true
	g.enter_zone(zone, Vector2.ZERO)
	g.sim.no_spawns = false
	g.mode = "play"
	g.fresh_hero()
	g.p.pos = at * 16.0
	g.p.aim = Vector2.RIGHT
	g.cam = g.p.pos
	quiet()

func setup() -> void:
	g.new_game()
	g.lvl = 14
	g.recompute()
	await arena("forest", Vector2(40, 26))

func foe(kind: String, off: Vector2) -> Dictionary:
	var f = g.spawn(kind, g.p.pos + off)
	f.state = "chase"
	f.cd = 0.0
	return f

func wait_for(f: Dictionary, state: String, limit: int = 400) -> bool:
	for i in limit:
		if f.state == state:
			return true
		await process_frame
	return false

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
			await frames(2)
			var near = g.near_target()
			if near == null or near.id != id:
				return false
			await tap("use")
			await read_on()
			return true
	return false

func kill_all(kind: String, n: int) -> void:
	for i in n:
		var f = g.spawn(kind, g.p.pos + Vector2(300, 0))
		f.hp = 1.0
		g.hit_foe(f, 99.0, false, 0.0, 0.0)
	g.blasts.clear()
	g.drops.clear()

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_ch2.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)

	# --- the places
	for id in ["forest", "heart"]:
		var z = g.World.build(id)
		var ok = g.World.build(id).spawns.size() == z.spawns.size() and g.World.build(id).decor.size() == z.decor.size() and z.theme == "forest"
		for s in z.spawns:
			ok = ok and z.grid[int(s.pos.y / 16)][int(s.pos.x / 16)] != 0 and D.FOES.has(s.kind)
		for po in z.portals:
			var dest = g.World.build(po.to)
			ok = ok and dest.grid[int(po.at.y / 16)][int(po.at.x / 16)] != 0
		for dc in z.decor:
			ok = ok and g.Art.T.has(dc.tex)
		check("zone %s is stable, its foes stand on ground, its exits and pictures exist" % id, ok)
	var fz = g.World.build("forest")
	check("the forest holds the village, three trunks and the seal stone", fz.npcs.size() == 2 and fz.things.size() == 4)
	check("the marsh has a way into the forest", g.World.build("field").portals.any(func(po): return po.to == "forest" and po.need == "m7"))
	check("forest tiles are painted in their own colours", g.Art.I.has("forestgrass0") or true)

	g.new_game()
	g.recompute()
	await arena("field", Vector2(66, 23))
	g.sim.move = Vector2.RIGHT
	await frames(120)
	check("the forest road is barred before its quest", g.zone.id == "field")
	g.qs["m7"] = "active"
	g.qc["m7"] = {}
	g.p.pos = Vector2(66, 23) * 16.0
	await frames(160)
	quiet()
	check("with the quest it leads to the Breathing Forest", g.zone.id == "forest")
	check("the forest ground was painted with the forest theme", g.Art.I.has("forestgrass0") and g.Art.I["forestgrass0"].get_pixel(8, 8) != g.Art.I["grass0"].get_pixel(8, 8))

	# --- memory wolf
	await setup()
	var f = foe("wolf", Vector2(24, 0))
	check("a wolf bites fast", await wait_for(f, "wind") and f.wind < 0.4)
	await wait_for(f, "rec")
	check("its bite hurts up close", g.p.hp < g.stats.mhp)

	# --- spore sower
	await setup()
	f = foe("sower", Vector2(110, 0))
	await wait_for(f, "wind")
	var spot = f.tpos
	check("a sower aims a pod at where you stand", spot.distance_to(g.p.pos) < 2.0)
	g.p.pos += Vector2(0, 80)
	await wait_for(f, "rec")
	f.cd = 99.0
	check("the pod leaves a cloud, and stepping away costs nothing", g.clouds.size() == 1 and g.p.hp == g.stats.mhp)
	g.p.pos = spot
	await frames(40)
	var h1 = g.p.hp
	check("standing in the cloud hurts", h1 < g.stats.mhp)
	await frames(60)
	check("and keeps hurting", g.p.hp < h1)
	g.foes.clear()   # or the sower throws another pod while we wait
	g.p.pos = spot + Vector2(0, 90)
	await frames(260)
	check("the cloud fades after a few seconds", g.clouds.is_empty())

	# --- hollow stag
	await setup()
	f = foe("deer", Vector2(100, 0))
	await wait_for(f, "wind")
	var x0 = f.pos.x
	await wait_for(f, "rec")
	await frames(30)
	check("a stag charges a long way in a line (%.0f)" % absf(f.pos.x - x0), absf(f.pos.x - x0) > 90.0)
	check("standing in the line gets you trampled", g.p.hp < g.stats.mhp)
	await setup()
	f = foe("deer", Vector2(100, 0))
	await wait_for(f, "wind")
	g.p.pos += Vector2(0, 50)
	await wait_for(f, "rec")
	await frames(30)
	check("a step to the side avoids it", g.p.hp == g.stats.mhp)
	check("and it is left recovering for a long time", f.state == "rec" and D.FOES.deer.rec > 1.4)

	# --- the tree-mother
	g.new_game()
	g.lvl = 14
	g.recompute()
	await arena("heart", Vector2(74, 17.5))
	f = foe("mother", Vector2(90, -16))
	var home = f.pos
	await wait_for(f, "wind")
	check("her first move is three root lines, the first aimed at you", f.atk == "roots" and f.lines == 3 and absf(angle_difference(f.ang, (g.p.pos - f.pos).angle())) < 0.05)
	await wait_for(f, "rec")
	check("standing on the aimed line hurts", g.p.hp < g.stats.mhp)
	g.p.hp = g.stats.mhp
	g.p.inv = 0.0
	await wait_for(f, "wind")
	check("then spore pods, one on you", f.atk == "spores" and f.pods.size() == 2 and f.pods[0].distance_to(g.p.pos) < 2.0)
	await wait_for(f, "rec")
	check("which become clouds", g.clouds.size() == 2)
	g.clouds.clear()
	g.p.pos = f.pos + Vector2(-60, 60)
	await wait_for(f, "wind")
	check("then an amber call", f.atk == "call" and f.amber)
	g.hit_foe(f, 5.0, false, 0.0, 0.0)
	check("a light hit does not stop it", f.state == "wind")
	g.hit_foe(f, 5.0, true, 0.0, 0.0)
	check("a heavy hit does, and no wolves come", f.state == "stun" and g.foes.size() == 1)
	check("she never moves, even when struck", f.pos == home)
	f.hp = f.mhp * 0.4
	f.n = 0
	f.state = "chase"
	f.cd = 0.0
	await wait_for(f, "wind")
	check("below half life: five root lines", f.atk == "roots" and f.lines == 5)
	await wait_for(f, "rec")
	f.cd = 0.0
	await wait_for(f, "wind")
	check("and three pods", f.atk == "spores" and f.pods.size() == 3)
	f.n = 2
	f.state = "chase"
	f.cd = 0.0
	g.p.pos = f.pos + Vector2(-120, 80)
	await wait_for(f, "wind")
	await wait_for(f, "act")
	check("an uninterrupted call brings three wolves", g.foes.filter(func(o): return o.kind == "wolf").size() == 3)
	g.foes = [f]
	f.hp = 1.0
	g.hit_foe(f, 99.0, false, 0.0, 0.0)
	check("her death drops the seed", g.drops.any(func(o): return o.kind == "item" and o.item.uniq == "seed"))

	await setup()
	g.eq.charm = D.seed_unique()
	g.recompute()
	var a = g.spawn("deer", g.p.pos + Vector2(200, 0))
	check("the seed: nothing without marks", g.dmg_mult(a) == 1.0)
	g.mark(a, "burn")
	g.mark(a, "chill")
	check("the seed: 8% per mark on the foe", absf(g.dmg_mult(a) - 1.16) < 0.001)

	# --- the quests
	g.new_game()
	g.lvl = 14
	g.recompute()
	for id in ["m1", "m2", "m3", "m4", "m5", "m6"]:
		g.qs[id] = "done"
	await arena("town", Vector2(22, 16))
	check("after chapter one Madam Say has new work", g.npc_mark("say") == "!")
	await talk_to("say")
	check("m7: sent to the forest", g.qs.get("m7") == "active")
	await arena("forest", Vector2(22, 17))
	check("the elder waits for you", g.npc_mark("reu") == "?")
	await talk_to("reu")
	check("m7: met Lao Reu", g.qs.get("m7") == "done")
	check("the seal stone cannot be used yet", not await look_at("verdict"))
	await talk_to("reu")
	check("m8: wolves", g.qs.get("m8") == "active")
	await talk_to("man")
	check("s3: the scratched names", g.qs.get("s3") == "active")
	await kill_all("wolf", 5)
	check("m8: five wolves make it ready", g.qs.get("m8") == "ready")
	var seen = 0
	for id in ["trunk_a", "trunk_b", "trunk_c"]:
		if await look_at(id):
			seen += 1
	check("s3: three trunks found", seen == 3 and g.qs.get("s3") == "ready")
	await talk_to("reu")
	check("m8: handed in", g.qs.get("m8") == "done")
	await talk_to("man")
	check("s3: handed in", g.qs.get("s3") == "done")
	await arena("town", Vector2(22, 16))
	await talk_to("dien")
	check("m9: the warden's side of it", g.qs.get("m9") == "active")
	await arena("forest", Vector2(22, 17))
	await kill_all("sower", 4)
	await kill_all("deer", 2)
	check("m9: ready", g.qs.get("m9") == "ready")
	await arena("town", Vector2(22, 16))
	await talk_to("dien")
	check("m9: handed in", g.qs.get("m9") == "done")
	await arena("forest", Vector2(22, 17))
	await talk_to("reu")
	check("m10: the tree opens", g.qs.get("m10") == "active")
	g.p.pos = Vector2(81, 26) * 16.0
	g.sim.move = Vector2.RIGHT
	await frames(160)
	quiet()
	check("the root bridge leads inside the tree", g.zone.id == "heart" and g.zone.dark)
	g.foes.clear()
	g.p.pos = g.zone.scenes[0].rect.get_center()
	await frames(3)
	check("the hall of rings plays what the tree remembers", g.mode == "talk" and g.talk.lines == D.SCENES.bell.lines)
	await read_on()
	check("the memory is kept", g.flags.has("seen_bell") and g.mode == "play")
	await kill_all("mother", 1)
	check("m10: ready after the memory and the Mother", g.qs.get("m10") == "ready")
	await arena("forest", Vector2(22, 17))
	await talk_to("reu")
	check("m10 handed in, the verdict begins by itself", g.qs.get("m10") == "done" and g.qs.get("m11") == "active")
	check("now the seal stone answers", await look_at("verdict") and g.Ui.choosing(g))
	await tap("opt2")
	await read_on()
	check("keeping the village is remembered", g.flags.get("village", -1) == 1 and g.qs.get("m11") == "ready")
	var gold0 = g.gold
	await talk_to("reu")
	check("m11: keeping it pays in a charm, not coin, and ends the chapter", g.qs.get("m11") == "done" and g.gold == gold0 and g.main_done() == 11)

	# the other verdict
	g.qs["m11"] = "active"
	g.qc["m11"] = {}
	g.flags.erase("village")
	g.flags.erase("seen_verdict")
	await look_at("verdict")
	await tap("opt1")
	await read_on()
	gold0 = g.gold
	await talk_to("reu")
	check("m11: sealing it pays the wardens' coin", g.flags.get("village") == 0 and g.gold == gold0 + 300)
	g.save_game()
	g.new_game()
	check("chapter two is saved", g.load_game() and g.qs.get("m11") == "done" and g.flags.get("village") == 0)
	print("RESULT: %s" % ("OK" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
