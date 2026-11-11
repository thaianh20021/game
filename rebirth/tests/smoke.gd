extends SceneTree
# Exercises the hub (every station, menu and secret) and then plays full runs
# with every hero by teleporting room to room in god mode.
const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Lobby = preload("res://src/lobby.gd")
const More = preload("res://src/more.gd")
const Forge = preload("res://src/forge.gd")
var g
var fails = 0

func check(cond: bool, what: String) -> void:
	if not cond:
		print("FAIL ", what)
		fails += 1

func step(n: int = 1) -> void:
	for i in n:
		if g.state == "play" and not g.in_lobby:
			g.p.hp = g.p.mhp
			g.p.en = float(g.p.men)
			var f = Engine.get_process_frames()
			if not g.enemies.is_empty():
				g.sim["mouse"] = g.center(g.enemies[0]) - g.cam_tl
				if f % 45 == 0:
					for off in [Vector2(14, 0), Vector2(-14, 0), Vector2(0, 14), Vector2(0, -14)]:
						var cand = g.enemies[0].pos + off
						if g.box_free(cand, g.p.r):
							g.p.pos = cand
							break
			if f % 90 == 0: g.jp["m2"] = true
			if f % 110 == 0: g.jp[KEY_F] = true
			if f % 50 == 0: g.jp[KEY_R] = true
			if f % 70 == 0: g.jp[KEY_SPACE] = true
			if f % 120 == 0: g.jp[KEY_Q] = true
			if f % 130 == 0: g.jp[KEY_C] = true
			if (f / 50) % 2 == 0: g.sim[KEY_D] = true
			else: g.sim.erase(KEY_D)
		await process_frame

func lobby_tour() -> void:
	g.goto_lobby()
	await step(5)
	check(g.in_lobby and g.state == "play", "lobby should be playable")
	Meta.S.gems = 5000
	# every station once
	for it in g.inter.duplicate():
		if it.kind in ["gate", "hero"] or it.get("menu", "") in ["board", "coop"]:
			continue
		g.p.pos = it.pos + Vector2(0, 8)
		await step(2)
		for k in 6:
			if g.state == "play":
				g.interact(it)
			while g.state == "talk":
				g.jp[KEY_E] = true
				await step(8)
			if g.state == "say":
				g.set_state("play")
		if g.state == "menu":
			for i in g.menu.rows.size() * 2:
				g.menu.sel = i % g.menu.rows.size()
				Lobby.activate(g, g.menu.rows[g.menu.sel])
				await step(1)
				if g.menu.rows.is_empty():
					break
			g.set_state("play")
		await step(2)
	check(Meta.S.fuse_unlocked, "altar should unlock fusion")
	check(Meta.S.pets.size() == 4 and Meta.S.mounts.size() == 2, "all pets and mounts bought")
	check(Meta.S.tree.values().any(func(v): return v.size() == 9), "full skill tree bought")
	check(Meta.S.gen_seed != 0 and Meta.hero_count() == D.HEROES.size() + 1, "loom should weave a hero")
	# secret wall, then its chest
	g.sim["fire"] = true
	g.p.weapons[0] = {id = "pistol", el = "fire", el2 = "", lv = 0}
	g.p.pos = Lobby.tp(26, 11)
	g.sim["mouse"] = Lobby.tp(29, 11) - g.cam_tl
	for i in 200:
		g.sim["mouse"] = Lobby.tp(29, 11) - g.cam_tl
		await step(1)
	check(Meta.S.eggs.has("nook_open"), "cracked wall should break")
	for it in g.inter:
		if it.kind == "chest":
			g.interact(it)
	check(Meta.S.eggs.has("nook"), "nook chest should pay out")
	# secret code
	for k in Lobby.CODE:
		g.jp[k] = true
		await step(1)
	check(g.prism_next, "secret code should arm prism")
	g.sim.erase("fire")
	# dummy
	g.dummy_hits = 99
	g.hurt_enemy(g.enemies[0], 5.0)
	await step(2)
	check(Meta.S.eggs.has("dummy"), "dummy egg")

func run_hero(hero: int, fuse: int, pet: String, mount: String) -> void:
	Meta.S.hero = hero
	Meta.S.el = hero % 4
	Meta.S.fuse = fuse
	Meta.S.pet = pet
	Meta.S.mount = mount
	g.goto_lobby()
	await step(3)
	for it in g.inter:
		if it.kind == "gate":
			g.interact(it)
	check(not g.in_lobby, "gate should start a run")
	g.sim["fire"] = true
	var wids = D.WEAPONS.keys()
	var wk = hero * 3
	var seen_boss = {}
	var floors = 0
	while g.state == "play" and floors < 8:
		floors += 1
		for c in g.dg.cracks:
			for k in 6:
				More.hit_crack(g, c.cell.x, c.cell.y)
			check(c.open, "crack should open")
		var rooms = g.dg.rooms.duplicate()
		rooms.sort_custom(func(a, b): return (a.type == "boss" or a.type == "exit") < (b.type == "boss" or b.type == "exit"))
		for r in rooms:
			g.p.weapons = [{id = wids[wk % wids.size()], el = D.EL[wk % 4], el2 = "", lv = wk % 3},
				{id = wids[(wk + 5) % wids.size()], el = ["", "fire", "ice", "bolt", "tox", "prism"][(wk + 1) % 6], el2 = "", lv = 0}]
			wk += 1
			g.p.pos = g.rc(r) + Vector2(0, 20)
			# never land in a pit: the fall would throw the bot back into the previous room
			for o in [Vector2(0, 20), Vector2(0, -20), Vector2(24, 0), Vector2(-24, 0), Vector2.ZERO, Vector2(32, 24), Vector2(-32, 24), Vector2(0, 40), Vector2(0, -40)]:
				if g.terr_at(g.rc(r) + o) != 2:
					g.p.pos = g.rc(r) + o
					break
			g.p.safe = g.p.pos
			g.p.gold = 500
			await step(20)
			var n = 0
			while not r.cleared and n < 5000 and g.state == "play":
				if g.boss != null:
					seen_boss[g.boss.id] = true
				await step(1)
				n += 1
			if not r.cleared:
				print("FAIL room not cleared: floor ", g.floor_i, " type ", r.type, " enemies ", g.enemies.map(func(e): return e.id), " pending ", g.pending, " state ", g.state)
				fails += 1
			for it in g.inter.duplicate():
				if it.kind in ["portal", "deco"] or g.state != "play" or (it.kind == "shrine" and g.p.mhp < 6):
					continue
				g.p.pos = it.pos + Vector2(0, 6)
				await step(2)
				g.interact(it)
				if g.state == "forge":
					g.forge.text = ["lua nhanh", "ice bow many", "", "sấm nổ kiếm"][wk % 4]
					Forge.confirm(g)
				while g.state == "talk":
					g.jp[KEY_E] = true
					await step(8)
				if g.state == "buff":
					g.pick_buff(0)
			await step(20)
		var portal = null
		for it in g.inter:
			if it.kind == "portal":
				portal = it
		if portal == null:
			print("FAIL no portal on floor ", g.floor_i)
			fails += 1
			break
		var fl = g.floor_i
		g.interact(portal)
		await step(2)
		if g.state == "buff":
			g.pick_buff(fl % 3)
		await step(5)
	print("  relics=", g.p.relics, " syn=", g.p.syn, " active=", g.p.active, " keys=", g.p.keys)
	print("hero ", g.p.name, " state=", g.state, " floor=", g.floor_i, " kills=", g.kills, " bosses=", seen_boss.keys(), " gems+", g.gems_won, " weapon=", g.wname(g.p.weapons[0]))
	check(g.state == "win", "run should end in a win")
	g.sim.erase("fire")
	g.goto_lobby()
	await step(3)

func _init() -> void:
	Meta.PATH = "user://rebirth_test.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await step(5)
	await lobby_tour()
	await run_hero(0, 1, "pup", "boar")
	await run_hero(6, -1, "owl", "strider")
	await run_hero(7, 8, "mote", "")
	await run_hero(8, 4, "", "boar")
	await run_hero(2, 3, "toad", "")
	# garden grew during the runs, board starts a daily run
	check(Meta.S.garden[0].kind != "" and int(Meta.S.garden[0].left) == 0, "plant should be ripe")
	for it in g.inter:
		if it.kind == "plot":
			g.interact(it)
	check(Meta.S.garden[0].kind == "", "harvest should empty the plot")
	g.open_menu("board")
	Lobby.activate(g, g.menu.rows[1])
	await step(3)
	check(not g.in_lobby and g.run_daily and g.run_seed == Meta.today(), "board should start the daily run")
	print("codex ", Meta.S.codex.keys().map(func(k): return "%s=%d" % [k, Meta.S.codex[k].size()]), " heat_max=", Meta.S.heat_max)
	g.goto_lobby()
	await step(3)
	# death path
	g.start_run()
	g.p.mount = null
	g.p.relics = []
	g.p.feather = false
	g.p.wind2 = false
	g.p.inv = 0.0
	g.hurt_player(99)
	await step(5)
	check(g.state == "dead", "lethal hit should end the run")
	print("ai ", Meta.S.ai)
	print("SMOKE ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
