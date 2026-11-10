extends RefCounted
# The Hearth: a walkable hub with hero swapping, element crystals, NPC menus
# (skill tree, hero upgrades, pets and mounts, hero fusion) and a few secrets.

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")
const Dungeon = preload("res://src/dungeon.gd")
const Net = preload("res://src/net.gd")
const Hub = preload("res://src/hub.gd")
const Pets = preload("res://src/pets.gd")

const TRACKS = ["CAVE THEME", "FORGE THEME", "ARCHIVE THEME", "BOSS THEME", "HEARTH THEME"]
const CRACK = Vector2i(29, 11)
const CODE = [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT]

static func tp(x: float, y: float) -> Vector2:
	return Vector2(x * 16.0 + 8.0, y * 16.0 + 8.0)

static func build(g) -> void:
	g.in_lobby = true
	g.clear_world()
	g.dg = Dungeon.lobby(Meta.S.eggs.has("nook_open"))
	rebake(g)
	g.props = []
	g.light_bg.color = Color(0.36, 0.33, 0.44)
	Hub.ensure_quests()
	g.make_player()
	g.players = [g.p]
	g.p.pos = tp(15, 13)
	g.cam = g.p.pos
	if g.local2 and g.net.mode != "client":
		g.set_local2(true)
	g.floor_i = 0
	g.crack_hp = 10
	g.dummy_hits = 0
	g.code_i = 0
	populate(g)
	g.spawn_enemy("dummy", tp(21, 12))
	g.banner = {text = "THE HEARTH", sub = "STEP INTO THE GATE WHEN READY" if Meta.S.run.is_empty() else "A SAVED RUN WAITS AT THE RUN BOARD", t = 3.0 if Meta.S.run.is_empty() else 5.0}
	Sfx.play_music(4)

static func rebake(g) -> void:
	var imgs = Dungeon.bake(g.dg, 0)
	g.ground.texture = ImageTexture.create_from_image(imgs[0])
	g.over.texture = ImageTexture.create_from_image(imgs[1])

static func populate(g) -> void:
	g.inter.clear()
	g.near = null
	g.inter.append({kind = "gate", pos = tp(15, 5)})
	for i in Meta.hero_count():
		if i != Meta.S.hero:
			g.inter.append({kind = "hero", i = i, pos = tp(5 + i * 2.7, 8)})
	for i in 4:
		g.inter.append({kind = "crystal", i = i, pos = tp(4 + i * 2.5, 16.5)})
	g.inter.append({kind = "npc", menu = "tree", spr = "npc_mentor", name = "MENTOR: SKILL TREE", pos = tp(4, 10)})
	g.inter.append({kind = "npc", menu = "armor", spr = "npc_armorer", name = "ARMORER: HERO UPGRADES", pos = tp(26, 10)})
	g.inter.append({kind = "npc", menu = "beast", spr = "npc_keeper", name = "KEEPER: PETS AND MOUNTS", pos = tp(24, 16)})
	g.inter.append({kind = "npc", menu = "fuse", spr = "altar", name = "SOUL ALTAR: HERO FUSION", pos = tp(18, 16.5)})
	g.inter.append({kind = "npc", menu = "loom", spr = "loom", name = "SOUL LOOM: WEAVE A NEW HERO", pos = tp(11, 12.5)})
	g.inter.append({kind = "egg", egg = "cat", spr = "cat", name = "A CAT", pos = tp(27.5, 17.5), n = 0})
	g.inter.append({kind = "egg", egg = "jukebox", spr = "jukebox", name = "JUKEBOX", pos = tp(3, 5)})
	g.inter.append({kind = "egg", egg = "fountain", spr = "fountain", name = "WISHING FOUNTAIN: 1 GEM", pos = tp(15, 10)})
	g.inter.append({kind = "egg", egg = "tomb", spr = "tomb", name = "OLD GRAVE", pos = tp(27, 5), n = 0})
	g.inter.append({kind = "chest", pos = tp(31, 11), loot = "nook", open = Meta.S.eggs.has("nook")})
	g.inter.append({kind = "npc", menu = "board", spr = "board", name = "RUN BOARD: DAILY, SEEDS, HEAT", pos = tp(18.5, 5.5), notalk = true})
	g.inter.append({kind = "npc", menu = "codex", spr = "shelf", name = "ARCHIVE: CODEX", pos = tp(7, 5.2), notalk = true})
	for i in 3:
		g.inter.append({kind = "plot", i = i, pos = tp(21 + i * 2, 5.5)})
	for i in 2:
		g.inter.append({kind = "plot", i = 3 + i, pos = tp(17.5 + i * 2, 29.6)})
	g.inter.append({kind = "egg", egg = "bowl", spr = "bowl", name = "PET BOWL: FEED A TREAT", pos = tp(22.2, 16.6)})
	g.inter.append({kind = "npc", menu = "quest", spr = "board", name = "BOUNTY BOARD: DAILY TASKS", pos = tp(8, 22.4), notalk = true})
	g.inter.append({kind = "npc", menu = "trophy", spr = "trophy", name = "TROPHY CASE", pos = tp(12, 22.4), notalk = true})
	g.inter.append({kind = "egg", egg = "mail", spr = "mailbox", name = "MAILBOX: DAILY GIFT", pos = tp(23.5, 22.4)})
	g.inter.append({kind = "deco", spr = "rack", pos = tp(20.5, 22.3)})
	g.inter.append({kind = "npc", menu = "armory", spr = "npc_quarter", name = "QUARTERMASTER: PACK A WEAPON", pos = tp(18.5, 23)})
	g.inter.append({kind = "deco", spr = "cauldron", pos = tp(16.6, 26.3)})
	g.inter.append({kind = "npc", menu = "brew", spr = "npc_cook", name = "COOK: MEALS FOR THE ROAD", pos = tp(15, 26)})
	g.inter.append({kind = "deco", spr = "mannequin", pos = tp(6.6, 28)})
	g.inter.append({kind = "npc", menu = "tailor", spr = "npc_tailor", name = "TAILOR: DYES", pos = tp(8.2, 28)})
	g.inter.append({kind = "npc", menu = "bench", spr = "bench", name = "WORKBENCH: CRAFT FROM BLUEPRINTS", pos = tp(12.5, 28.2), notalk = true})
	g.inter.append({kind = "egg", egg = "capsule", spr = "capsule", name = "CAPSULE MACHINE: %d GEMS" % Hub.CAPSULE_COST, pos = tp(22.5, 28)})
	g.inter.append({kind = "npc", menu = "coop", spr = "crystal_prism", name = "LINK STONE: CO-OP", pos = tp(11, 5.4), notalk = true})

static func refresh_player(g) -> void:
	var pos = g.p.pos
	g.make_player()
	g.p.pos = pos

static func gems(g, n: int, text: String) -> void:
	Meta.S.gems += n
	Meta.save()
	g.label(g.p.pos + Vector2(0, -24), text, Color("e56db2"), true)
	g.burst(g.pcenter(), 14, Color("e56db2"), 90.0, 0.6)
	Sfx.play("chest")

static func interact(g, it: Dictionary) -> void:
	if g.p.idx > 0:
		# player two may only swap hero or element, or walk through the gate
		match it.kind:
			"hero":
				var pos = g.p.pos
				g.local2_hero = it.i
				g.set_local2(true)
				g.players[1].pos = pos
				return
			"crystal":
				g.p.weapons[0].el = D.EL[it.i]
				Sfx.play("pick")
				g.label(g.p.pos + Vector2(0, -24), D.EL_NAME[D.EL[it.i]] + " ATTUNED", D.EL_COL[D.EL[it.i]])
				return
			"gate":
				pass
			_:
				return
	match it.kind:
		"gate":
			if g.net.mode == "client":
				g.label(g.p.pos + Vector2(0, -24), "THE HOST STARTS THE RUN", Color("ffd24a"))
			elif g.net.mode == "host" and g.net.joined:
				Net.start(g)
			else:
				g.start_run(0, false)
		"hero":
			Meta.S.hero = it.i
			if Meta.S.fuse == it.i:
				Meta.S.fuse = -1
			Meta.save()
			refresh_player(g)
			populate(g)
			Sfx.play("pick")
			g.burst(g.pcenter(), 14, Color.WHITE, 80.0, 0.4)
			g.label(g.p.pos + Vector2(0, -24), g.p.name, Color("ffd24a"))
		"crystal":
			Meta.S.el = it.i
			Meta.save()
			g.prism_next = false
			g.p.weapons[0].el = D.EL[it.i]
			Sfx.play("pick")
			g.flash(it.pos, 70.0, D.EL_COL[D.EL[it.i]], 0.4)
			g.label(g.p.pos + Vector2(0, -24), D.EL_NAME[D.EL[it.i]] + " ATTUNED", D.EL_COL[D.EL[it.i]])
		"npc":
			if it.get("notalk", false):
				g.open_menu(it.menu)
			else:
				g.start_talk(it.menu, it.menu)
		"plot":
			var pl = Meta.S.garden[it.i]
			if pl.kind == "":
				g.menu_plot = it.i
				g.open_menu("garden")
			elif int(pl.left) > 0:
				g.label(g.p.pos + Vector2(0, -24), "STILL GROWING. FINISH A RUN.", Color("a9e150"))
			else:
				var msg: String = D.SEEDS[pl.kind].name + ": READY FOR YOUR NEXT RUN"
				match pl.kind:
					"bloom": Meta.S.boons.hp = int(Meta.S.boons.get("hp", 0)) + 1
					"root": Meta.S.boons.relic = int(Meta.S.boons.get("relic", 0)) + 1
					"berry":
						Meta.S.treats = int(Meta.S.treats) + 2
						msg = "+2 TREATS. TAKE THEM TO THE PET BOWL."
					"gleam":
						Meta.add_mat("ess", 4)
						msg = "+4 ESSENCE"
					"flax":
						Meta.add_mat("ore", 3)
						Meta.add_mat("fib", 3)
						msg = "+3 ORE, +3 FIBER"
				var vine = pl.kind == "vine"
				pl.kind = ""
				if vine:
					gems(g, 25, "COIN VINE +25")
				else:
					Meta.save()
					Sfx.play("chest")
					g.label(g.p.pos + Vector2(0, -24), msg, Color("a9e150"))
		"egg":
			egg(g, it)

static func egg(g, it: Dictionary) -> void:
	if it.egg == "bowl":
		Pets.feed(g, it)
		return
	if it.egg in ["capsule", "mail"]:
		Hub.egg(g, it)
		return
	var at = g.p.pos + Vector2(0, -24)
	match it.egg:
		"cat":
			it.n += 1
			g.burst(it.pos + Vector2(0, -8), 5, Color("e56db2"), 30.0, 0.7, -40.0)
			Sfx.play("orb", 1.6)
			g.label(it.pos + Vector2(0, -18), ["PURR", "PURRR...", "MRRP?", "PURRRRRR"][it.n % 4], Color("f2812f"))
			if it.n == 5 and not g.session_cat:
				g.session_cat = true
				gems(g, 3, "THE CAT APPROVES +3")
		"jukebox":
			g.juke = (g.juke + 1) % TRACKS.size()
			Sfx.play_music(g.juke)
			g.label(at, TRACKS[g.juke], Color("5cd3f2"))
		"fountain":
			if Meta.S.gems < 1:
				Sfx.play("deny")
				g.label(at, "YOU HAVE NO GEM TO TOSS", Color("ff6a6a"))
				return
			Meta.S.gems -= 1
			Sfx.play("coin")
			g.burst(it.pos + Vector2(0, -6), 8, Color("5cd3f2"), 60.0, 0.5, 120.0)
			if g.rng.randf() < 0.15:
				gems(g, 10, "THE CORE SMILES +10")
			else:
				Meta.save()
				g.label(at, Meta.FORTUNES[g.rng.randi() % Meta.FORTUNES.size()], Color("c6f4ff"))
		"tomb":
			it.n += 1
			g.label(at, ["HERE LIES THE OLD BUILD", "71083 LINES. IT TRIED ITS BEST.", "REST WELL, OLD CODE."][mini(it.n - 1, 2)], Color("a8a7b8"))
			g.burst(it.pos + Vector2(0, -10), 6, Color("c6f4ff"), 20.0, 1.0, -30.0)
			if it.n == 3 and not Meta.S.eggs.has("tomb"):
				Meta.S.eggs["tomb"] = true
				gems(g, 5, "A GIFT FROM THE PAST +5")

static func open_nook_chest(g) -> void:
	if not Meta.S.eggs.has("nook"):
		Meta.S.eggs["nook"] = true
		gems(g, 25, "SECRET STASH +25")

# Called when a player bullet strikes a wall tile while in the hub.
static func hit_wall(g, tx: int, ty: int) -> void:
	if Vector2i(tx, ty) != CRACK or Meta.S.eggs.has("nook_open"):
		return
	g.crack_hp -= 1
	g.burst(tp(CRACK.x - 0.5, CRACK.y), 4, Color("a8a7b8"), 50.0, 0.4, 80.0)
	g.shake_add(1.5)
	if g.crack_hp <= 0:
		Meta.S.eggs["nook_open"] = true
		Meta.save()
		g.dg.grid[CRACK.y * g.dg.w + CRACK.x] = 1
		rebake(g)
		Sfx.play("boom")
		g.shake_add(6.0)
		g.burst(tp(CRACK.x, CRACK.y), 24, Color("a8a7b8"), 110.0, 0.6, 80.0)
		g.label(g.p.pos + Vector2(0, -24), "A SECRET ROOM!", Color("ffd24a"), true)

static func update(g, dt: float) -> void:
	Hub.chatter(g, dt)
	if g.jpk(KEY_F2) and g.net.mode == "":
		g.set_local2(not g.local2)
	# training dummy never dies and remembers how often it got hit
	for e in g.enemies:
		if e.id == "dummy":
			if e.hp < e.mhp:
				g.dummy_hits += 1
				e.hp = e.mhp
				if g.dummy_hits == 100 and not Meta.S.eggs.has("dummy"):
					Meta.S.eggs["dummy"] = true
					gems(g, 5, "OUCH! FINE. TAKE THESE +5")
	# secret code on the arrow keys
	for k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		if g.jpk(k):
			g.code_i = g.code_i + 1 if k == CODE[g.code_i] else (1 if k == CODE[0] else 0)
			if g.code_i >= CODE.size():
				g.code_i = 0
				g.prism_next = true
				g.p.weapons[0].el = "prism"
				Sfx.play("react")
				g.flash(g.pcenter(), 160.0, Color("e58cff"), 0.6)
				g.label(g.p.pos + Vector2(0, -24), "PRISM AWAKENS", Color("e58cff"), true)

# ---- menus -----------------------------------------------------------------------
# A row: {name, desc, cost, state, fn}. state: buy | owned | on | locked

static func rows(g, kind: String) -> Array:
	if kind == "opts":
		var o = Meta.S.opts
		var rs = []
		for k in [["MUSIC VOLUME", "music"], ["SOUND VOLUME", "sfx"]]:
			rs.append({name = "%s: %d%%" % [k[0], int(o[k[1]]) * 25], desc = "0 TO 100 IN STEPS OF 25", cost = 0, state = "owned", tag = "CHANGE",
				fn = func(): o[k[1]] = (int(o[k[1]]) + 1) % 5})
		rs.append({name = "FULLSCREEN: " + ("ON" if o.full else "OFF"), desc = "SWITCH BETWEEN WINDOW AND FULL SCREEN", cost = 0, state = "owned", tag = "CHANGE", fn = func(): o.full = not o.full})
		rs.append({name = "SCREEN SHAKE: " + ("ON" if o.shake else "OFF"), desc = "TURN OFF IF THE SHAKING BOTHERS YOU", cost = 0, state = "owned", tag = "CHANGE", fn = func(): o.shake = not o.shake})
		return rs
	if Hub.KINDS.has(kind):
		return Hub.rows(g, kind)
	var out = []
	var hid: String = g.p.hkey
	var me = Meta.hero(Meta.S.hero)
	match kind:
		"tree":
			var tkey: String = g.p.tkey
			var nodes = Meta.tree(tkey)
			for n in nodes:
				var owned = Meta.has_node(tkey, n.id)
				var prev_ok = n.t == 0 or Meta.has_node(tkey, nodes[n.b * 3 + n.t - 1].id)
				out.append({name = n.name, desc = n.desc, cost = Meta.TREE_COST[n.t], b = n.b, t = n.t,
					state = "owned" if owned else ("buy" if prev_ok else "locked"),
					fn = func():
						if not Meta.S.tree.has(tkey):
							Meta.S.tree[tkey] = []
						Meta.S.tree[tkey].append(n.id)})
		"armor":
			var lv = Meta.hero_lv(hid)
			for i in Meta.HERO_UP.size():
				out.append({name = "RANK %d" % (i + 1), desc = Meta.HERO_UP[i], cost = 30 * (i + 1),
					state = "owned" if i < lv else ("buy" if i == lv else "locked"),
					fn = func(): Meta.S.hero_lv[hid] = lv + 1})
		"beast":
			for id in Meta.PETS:
				var d = Meta.PETS[id]
				out.append({name = d.name, desc = d.desc, cost = d.cost, icon = "pet_" + id,
					state = "on" if Meta.S.pet == id else ("owned" if Meta.S.pets.has(id) else "buy"),
					fn = func():
						if not Meta.S.pets.has(id):
							Meta.S.pets.append(id)
						Meta.S.pet = id})
			out.append({name = "NO PET", desc = "TRAVEL ALONE", cost = 0, state = "on" if Meta.S.pet == "" else "owned", fn = func(): Meta.S.pet = ""})
			for id in Meta.MOUNTS:
				var d = Meta.MOUNTS[id]
				out.append({name = d.name, desc = d.desc, cost = d.cost, icon = "m_" + id,
					state = "on" if Meta.S.mount == id else ("owned" if Meta.S.mounts.has(id) else "buy"),
					fn = func():
						if not Meta.S.mounts.has(id):
							Meta.S.mounts.append(id)
						Meta.S.mount = id})
			out.append({name = "NO MOUNT", desc = "GO ON FOOT", cost = 0, state = "on" if Meta.S.mount == "" else "owned", fn = func(): Meta.S.mount = ""})
		"fuse":
			if not Meta.S.fuse_unlocked:
				out.append({name = "AWAKEN THE ALTAR", desc = "UNLOCK HERO FUSION FOREVER", cost = Meta.FUSE_COST, state = "buy",
					fn = func(): Meta.S.fuse_unlocked = true})
			else:
				for i in Meta.hero_count():
					if i == Meta.S.hero:
						continue
					var o = Meta.hero(i)
					out.append({name = "%s + %s = %s" % [me.name, o.name, Meta.fuse_name(me, o)],
						desc = "SECOND SKILL: " + D.SKILLS[o.skill].name, cost = 0, icon = "h_" + o.id,
						state = "on" if Meta.S.fuse == i else "owned", fn = func(): Meta.S.fuse = i})
				out.append({name = "NO FUSION", desc = "STAY PURE", cost = 0, state = "on" if Meta.S.fuse == -1 else "owned", fn = func(): Meta.S.fuse = -1})
		"coop":
			var n = g.net
			out.append({name = "STATUS", desc = n.status if n.status != "" else "NOT CONNECTED", cost = 0, state = "owned", tag = "", fn = func(): pass})
			if n.mode == "":
				out.append({name = "HOST A LAN GAME", desc = "YOUR ADDRESS IS " + Net.local_ip(), cost = 0, state = "owned", tag = "HOST", fn = func(): Net.host(g)})
				for ip in n.hosts:
					out.append({name = "JOIN " + ip, desc = "A GAME FOUND ON YOUR NETWORK", cost = 0, state = "owned", tag = "JOIN", fn = func(): Net.join(g, ip)})
				out.append({name = "JOIN BY ADDRESS: " + (n.ip_in if n.ip_in != "" else "TYPE IT"), desc = "THE ADDRESS ON THE HOST SCREEN", cost = 0,
					state = "owned" if n.ip_in != "" else "locked", tag = "JOIN", fn = func(): Net.join(g, n.ip_in)})
			else:
				if n.mode == "host" and n.joined:
					out.append({name = "START CO-OP RUN", desc = "BOTH PLAYERS ENTER THE DUNGEON", cost = 0, state = "owned", tag = "START", fn = func(): g.pending_coop = true})
				out.append({name = "DISCONNECT", desc = "LEAVE THE LAN GAME", cost = 0, state = "owned", tag = "LEAVE", fn = func(): Net.leave(g)})
			if n.mode != "client":
				out.append({name = "LOCAL PLAYER 2: " + ("ON" if g.local2 else "OFF"), desc = "F2, OR START ON A SECOND GAMEPAD. NO PAD: ARROWS + HJKL UIOP", cost = 0, state = "owned", tag = "CHANGE",
					fn = func(): g.set_local2(not g.local2)})
				out.append({name = "A SINGLE GAMEPAD PLAYS: " + ("PLAYER 2" if g.pad_p2_first else "PLAYER 1"), desc = "KEYBOARD AND MOUSE ARE PLAYER 1", cost = 0, state = "owned", tag = "CHANGE",
					fn = func(): g.pad_p2_first = not g.pad_p2_first})
		"board":
			if not Meta.S.run.is_empty():
				var rf = int(Meta.S.run.floor)
				out.append({name = "CONTINUE SAVED RUN", desc = "FROM THE START OF FLOOR %d-%d. A NEW RUN ERASES IT." % [rf / 2 + 1, rf % 2 + 1], cost = 0, state = "owned", tag = "CONTINUE",
					fn = func(): g.pending_resume = true})
			out.append({name = "NORMAL RUN", desc = "A FRESH RANDOM DUNGEON AT HEAT %d" % Meta.S.heat, cost = 0, state = "owned", tag = "START",
				fn = func(): g.pending_start = [0, false]})
			var tk = str(Meta.today())
			out.append({name = "DAILY RUN " + tk, desc = "SAME DUNGEON FOR ALL TODAY. BEST %d" % int(Meta.S.daily.get(tk, 0)), cost = 0, state = "owned", tag = "START",
				fn = func(): g.pending_start = [Meta.today(), true]})
			out.append({name = "SEEDED RUN: " + (g.seed_in if g.seed_in != "" else "TYPE DIGITS"), desc = "SAME SEED, SAME DUNGEON. LAST SEED %d" % Meta.S.last_seed, cost = 0, tag = "START",
				state = "owned" if g.seed_in != "" else "locked", fn = func(): g.pending_start = [int(g.seed_in), false]})
			var hd = "NO CURSES" if Meta.S.heat == 0 else D.HEAT[Meta.S.heat - 1]
			out.append({name = "HEAT %d OF %d" % [Meta.S.heat, Meta.S.heat_max], desc = hd + ". +30% GEMS PER LEVEL", cost = 0, state = "owned", tag = "CHANGE",
				fn = func(): Meta.S.heat = (Meta.S.heat + 1) % (Meta.S.heat_max + 1)})
			if Meta.S.heat_max == 0:
				out.append({name = "WIN A RUN TO UNLOCK HEAT 1", desc = "EACH HEAT LEVEL ADDS A CURSE AND STACKS", cost = 0, state = "locked", tag = "", fn = func(): pass})
		"codex":
			var cats = [["WEAPONS", "weapons", D.WEAPONS.size()], ["FOES", "foes", D.ENEMIES.size() - 10], ["BOSSES", "bosses", 9],
				["REACTIONS", "reactions", 6], ["RELICS", "relics", D.RELICS.size()], ["SYNERGIES", "synergies", D.SYNERGIES.size()]]
			var have = 0
			var total = 0
			for c in cats:
				var n = mini(Meta.codex_count(c[1]), c[2])
				have += n
				total += c[2]
				var names = []
				for id in Meta.S.codex.get(c[1], {}):
					match c[1]:
						"weapons": names.append(D.WEAPONS[id].name if D.WEAPONS.has(id) else id)
						"bosses": names.append(D.ENEMIES[id].name if D.ENEMIES.has(id) else id)
						"reactions": names.append(D.REACT[id][0] if D.REACT.has(id) else id)
						"relics": names.append(D.RELICS[id].name if D.RELICS.has(id) else id)
						_: names.append(id.to_upper())
				var line = ", ".join(names)
				if line.length() > 44:
					line = line.substr(0, 41) + "..."
				out.append({name = "%s %d/%d" % [c[0], n, c[2]], desc = line if line != "" else "NOTHING FOUND YET", cost = 0, tag = "DONE" if n >= c[2] else "",
					state = "on" if n >= c[2] else "owned", fn = func(): pass})
			out.push_front({name = "CODEX %d%% COMPLETE" % int(100.0 * have / total), desc = "EVERYTHING YOU HAVE MET IN THE DUNGEON", cost = 0, state = "owned", tag = "", fn = func(): pass})
		"garden":
			for id in D.SEEDS:
				var sd = D.SEEDS[id]
				var have = int(Meta.S.seeds.get(id, 0))
				var row = {name = sd.name, desc = sd.desc, cost = sd.cost, state = "buy", icon = "plant_" + id}
				if have > 0:
					row.state = "owned"
					row.tag = "PLANT (%d)" % have
				out.append(row)
				row.fn = (func():
						if have > 0:
							Meta.S.seeds[id] = have - 1
						Meta.S.garden[g.menu_plot] = {kind = id, left = 1}
						g.menu_close = true)
		"loom":
			var cost = 0 if Meta.S.weaves == 0 else Meta.LOOM_COST
			out.append({name = "WEAVE A NEW SOUL", desc = "REPLACES THE CURRENT WOVEN HERO", cost = cost, state = "buy",
				fn = func():
					Meta.S.gen_seed = g.rng.randi_range(1, 2000000000)
					Meta.S.weaves += 1
					if Meta.S.fuse >= D.HEROES.size():
						Meta.S.fuse = -1
					Meta.S.hero = D.HEROES.size()})
			if Meta.S.gen_seed != 0:
				var h = Meta.gen_hero(Meta.S.gen_seed)
				out.append({name = h.name + " - " + h.arch, desc = "%d HEALTH  %d ARMOR  %d ENERGY" % [h.hp, h.ar, h.en], cost = 0, state = "on", icon = "h_gen", fn = func(): pass})
				out.append({name = D.SKILLS[h.skill].name, desc = "SKILL ONE", cost = 0, state = "on", icon = "sk_" + h.skill, fn = func(): pass})
				out.append({name = D.SKILLS[h.skill2].name, desc = "SKILL TWO", cost = 0, state = "on", icon = "sk_" + h.skill2, fn = func(): pass})
				out.append({name = D.WEAPONS[h.start].name, desc = "STARTING WEAPON", cost = 0, state = "on", fn = func(): pass})
	return out

static func activate(g, row: Dictionary) -> void:
	match row.state:
		"locked":
			Sfx.play("deny")
			return
		"on":
			Sfx.play("ui")
			return
		"owned":
			if g.menu.kind == "tree" or g.menu.kind == "armor":
				Sfx.play("ui")
				return
		"buy":
			if Meta.S.gems < row.cost:
				Sfx.play("deny")
				g.menu.msg = "NOT ENOUGH GEMS"
				return
			Meta.S.gems -= row.cost
	row.fn.call()
	Meta.save()
	if g.pending_coop:
		g.pending_coop = false
		g.set_state("play")
		Net.start(g)
		return
	if g.pending_resume:
		g.pending_resume = false
		g.set_state("play")
		g.resume_run()
		return
	if g.pending_start != null:
		var ps = g.pending_start
		g.pending_start = null
		g.set_state("play")
		for it in g.inter:
			if it.kind == "gate":
				g.start_run(ps[0], ps[1])
				return
		return
	if g.menu_close:
		g.menu_close = false
		g.set_state("play")
		Sfx.play("pick")
		return
	Sfx.play("pick")
	g.menu.msg = ""
	if g.menu.kind == "opts":
		g.apply_opts()
		g.menu.rows = rows(g, "opts")
		return
	refresh_player(g)
	if g.menu.kind == "loom":
		populate(g)
		g.flash(g.pcenter(), 160.0, Color("e58cff"), 0.6)
	g.menu.rows = rows(g, g.menu.kind)
