extends SceneTree
# Materials, seeds, the bigger garden, recipe crafting, pet skills, hearts and passives.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Pets = preload("res://src/pets.gd")
const Lobby = preload("res://src/lobby.gd")
var g
var fails = 0
var vis = DisplayServer.get_name() != "headless"
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for i in n: await process_frame
func dummy(pos):
	var e = g.spawn_enemy("goblin", pos)
	e.mhp = 99999.0
	e.hp = 99999.0
	e.stun = 999.0
	return e
func _init():
	Meta.PATH = "user://rebirth_pets.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	g.goto_lobby()
	check(Meta.S.garden.size() == 5 and g.inter.filter(func(it): return it.kind == "plot").size() == 5, "five garden plots")
	g.start_run(21, false)
	# foes and chests leave materials and seeds
	var c = g.p.pos
	for i in 300:
		g.kill(g.spawn_enemy(["slime", "bat", "wisp"][i % 3], c + Vector2(300, 0)))
	var kinds = {}
	for k in g.pickups:
		kinds[k.kind] = kinds.get(k.kind, 0) + 1
	print("300 foes -> ", kinds)
	check(kinds.get("m_ore", 0) > 5 and kinds.get("m_ess", 0) > 5 and kinds.get("m_fib", 0) > 5, "each kind of foe leaves its own material")
	check(kinds.get("seed", 0) >= 2, "foes sometimes leave seeds")
	g.pickups.clear()
	for i in 40:
		g.interact({kind = "chest", pos = c + Vector2(300, 0), loot = "reward", open = false})
	var mats = g.pickups.filter(func(k): return k.kind.begins_with("m_")).size()
	var seeds = g.pickups.filter(func(k): return k.kind == "seed").size()
	print("40 chests -> materials ", mats, " seeds ", seeds)
	check(mats >= 40 and seeds >= 3, "chests always hold materials and sometimes a seed")
	g.pickups = g.pickups.filter(func(k): return k.kind.begins_with("m_") or k.kind == "seed")
	for k in g.pickups:
		k.t = 1.0
		k.pos = g.p.pos
	await frames(3)
	check(Meta.mat("ore") + Meta.mat("ess") + Meta.mat("fib") == mats, "picked materials are banked")
	var nseeds = 0
	for id in Meta.S.seeds:
		nseeds += int(Meta.S.seeds[id])
	check(nseeds == seeds, "picked seeds are banked")
	# pet skills
	for id in ["pup", "owl", "mote", "toad"]:
		g.enemies.clear()
		g.zones.clear()
		g.p.pet = {id = id, pos = g.p.pos, t = 99.0, face = 1, moving = false, sk = 0.0, guard = true, hearts = 0}
		g.p.en = 10.0
		var e = dummy(g.p.pos + Vector2(40, 0))
		await frames(3)
		check(e.hp < 99999.0 and g.p.pet.sk > 5.0, id + " should cast its skill and go on cooldown")
		match id:
			"owl": check(e.frz > 0.0, "frost gust freezes")
			"mote": check(g.p.en >= 24.0, "overcharge restores energy")
			"toad": check(g.zones.size() >= 1, "spore belch leaves a cloud")
	g.p.pet.hearts = 2
	g.p.pet.sk = 0.0
	await frames(2)
	check(absf(g.p.pet.sk - Pets.CD * 0.8) < 0.3, "hearts shorten the cooldown")
	# passives at three hearts
	g.enemies.clear()
	g.p.mount = null
	g.p.pet = {id = "owl", pos = g.p.pos, t = 99.0, face = 1, moving = false, sk = 99.0, guard = true, hearts = 3}
	var hp = g.p.hp + g.p.ar
	g.p.inv = 0.0
	g.hurt_player(1)
	check(g.p.hp + g.p.ar == hp, "owl blocks the first hit")
	g.p.inv = 0.0
	g.hurt_player(1)
	check(g.p.hp + g.p.ar == hp - 1, "but only once per room")
	g.p.pet.id = "toad"
	g.zones.clear()
	g.p.inv = 0.0
	g.hurt_player(1)
	check(g.zones.size() == 1 and g.zones[0].el == "tox", "toad answers a hit with a venom cloud")
	g.p.pet.id = "mote"
	g.p.en = 10.0
	g.kill(g.spawn_enemy("slime", c + Vector2(300, 0)))
	check(g.p.en == 13.0, "mote restores energy on kills")
	g.p.hp = g.p.mhp
	# garden: plant a found seed for free, harvest berries, feed the pet
	Meta.S.seeds = {"berry": 1}
	Meta.S.pet = "pup"
	Meta.S.gems = 0
	g.end_run(false)
	g.goto_lobby()
	g.menu_plot = 4
	g.open_menu("garden")
	var row = null
	for r in g.menu.rows:
		if r.name == "PET BERRY":
			row = r
	check(row != null and row.state == "owned", "an owned seed can be planted without gems")
	Lobby.activate(g, row)
	check(Meta.S.garden[4].kind == "berry" and int(Meta.S.seeds.berry) == 0, "planting uses the seed")
	Meta.S.garden[4].left = 0
	for it in g.inter:
		if it.kind == "plot" and it.i == 4:
			g.interact(it)
	check(int(Meta.S.treats) == 2, "berries give two treats")
	Meta.S.treats = 3
	var bowl = null
	for it in g.inter:
		if it.get("egg", "") == "bowl":
			bowl = it
	check(bowl != null, "the hub has a pet bowl")
	for i in 4:
		g.interact(bowl)
	check(Pets.hearts("pup") == 3 and int(Meta.S.treats) == 0, "three treats make three hearts")
	check(g.p.pet.hearts == 3 and Pets.has_passive(g.p, "pup"), "the passive unlocks at three hearts")
	if vis:
		g.p.pos = bowl.pos + Vector2(-14, 8)
		await frames(40)
		var im = root.get_texture().get_image()
		im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
		im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_pets.png")
	# recipes at the workbench
	Meta.S.blueprints = ["quake"]
	Meta.S.scrap = 15
	Meta.S.mats = {ore = 6, ess = 0, fib = 1}
	g.open_menu("bench")
	row = g.menu.rows.filter(func(r): return r.name == "QUAKE HAMMER")[0]
	check(row.state == "locked", "not enough ore: cannot craft")
	Meta.add_mat("ore", 1)
	g.open_menu("bench")
	row = g.menu.rows.filter(func(r): return r.name == "QUAKE HAMMER")[0]
	check(row.state == "owned", "with the materials it can be crafted")
	Lobby.activate(g, row)
	check(Meta.mat("ore") == 0 and Meta.mat("fib") == 0 and int(Meta.S.scrap) == 0 and Meta.S.boons.get("weapon", "") == "quake", "crafting spends the recipe")
	if vis:
		await frames(3)
		var im2 = root.get_texture().get_image()
		im2.resize(1440, 810, Image.INTERPOLATE_NEAREST)
		im2.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_bench2.png")
	print("PETS ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
