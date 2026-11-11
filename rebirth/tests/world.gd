extends SceneTree
# Weather per floor, the alchemy notebook, puzzle rooms, the talking nemesis and graves.
const Meta = preload("res://src/meta.gd")
const Combo = preload("res://src/combo.gd")
const Wx = preload("res://src/sky.gd")
const Book = preload("res://src/book.gd")
const Dungeon = preload("res://src/dungeon.gd")
const Nemesis = preload("res://src/nemesis.gd")
const Ext = preload("res://src/ext.gd")
var g
var fails = 0
var vis = DisplayServer.get_name() != "headless"
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for i in n:
		g.p.hp = g.p.mhp
		g.p.inv = 1.0
		await process_frame
func shot(n):
	if vis:
		var im = root.get_texture().get_image()
		im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
		im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_" + n + ".png")
func count_terr(d, kind):
	var n = 0
	for v in d.terr:
		if v == kind:
			n += 1
	return n
# a run seed whose first floor has a puzzle room of this kind
func seed_with(kind):
	for s in range(1, 400):
		var rng = RandomNumberGenerator.new()
		rng.seed = hash([s, 0])
		var d = Dungeon.generate(rng, 0, false, "clear")
		for r in d.rooms:
			if r.type == "puzzle" and r.puzzle == kind:
				return s
	return -1
func puzzle_room():
	for r in g.dg.rooms:
		if r.type == "puzzle":
			return r
	return null
func chest_of(r):
	for it in g.inter:
		if it.kind == "chest" and it.get("room", -1) == r.id:
			return it
	return null
func pop_barrel(r):
	for pr in g.props:
		if pr.get("pz", false) and not pr.dead:
			g.p.pos = pr.pos + Vector2(0, 90 if pr.pos.y < g.rc(r).y else -90)
			g.hurt_prop(pr, 99.0)
func _init():
	Meta.PATH = "user://rebirth_world.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 5: await process_frame
	Meta.S.pet = ""
	g.goto_lobby()

	# ---- weather ----
	check(Wx.weather_for(77, 0) == "clear", "the first floor is always clear")
	var seen = {}
	for s in 40:
		for fl in range(1, 6):
			seen[Wx.weather_for(s, fl)] = true
			check(Wx.weather_for(s, fl) == Wx.weather_for(s, fl), "weather depends only on the seed")
	check(seen.size() == 5, "every kind of weather turns up")
	check(Wx.forecast(Meta.today()) == Wx.forecast(Meta.today()) and Wx.forecast(5).split(" ").size() == 5, "the daily forecast is stable")
	var wet = 0
	var dry = 0
	var brush_wet = 0
	var brush_dry = 0
	for s in 12:
		var ra = RandomNumberGenerator.new()
		ra.seed = s
		var a = Dungeon.generate(ra, 2, false, "rain")
		ra.seed = s
		var b = Dungeon.generate(ra, 2, false, "drought")
		wet += count_terr(a, 1)
		dry += count_terr(b, 1)
		brush_wet += count_terr(a, 4)
		brush_dry += count_terr(b, 4)
	check(wet > dry * 2, "rain floors are full of mire (%d against %d)" % [wet, dry])
	check(brush_dry > brush_wet * 2, "drought floors are full of brush (%d against %d)" % [brush_dry, brush_wet])

	g.start_run(12, false)
	check(g.dg.weather == "clear", "a run starts under a clear sky")
	g.dg.weather = "rain"
	Ext.add_zone(g, g.p.pos + Vector2(300, 0), 10.0, "fire", 4.0)
	check(g.zones[-1].life < 2.0, "rain puts fire out fast")
	check(Wx.conduct_mult(g) > 1.0, "rain makes mire carry lightning harder")
	g.dg.weather = "drought"
	Ext.add_zone(g, g.p.pos + Vector2(300, 0), 10.0, "fire", 4.0)
	check(g.zones[-1].life > 5.0, "drought feeds fire")
	g.dg.weather = "fog"
	check(Wx.sight(g) < 1.0 and Wx.field_life(g, "fire+ice") > 1.0, "fog shortens sight and keeps steam")
	await frames(20)
	shot("sky_fog")
	g.dg.weather = "gale"
	var foe = g.spawn_enemy("goblin", g.p.pos + Vector2(60, 0))
	foe.stun = 999.0
	g.lock = g.dg.rooms[0]
	g.sky_t = 0.0
	await frames(5)
	check(not g.teles.is_empty(), "a gale telegraphs its lightning")
	await frames(40)
	shot("sky_gale")
	g.lock = null
	foe.dead = true
	g.dg.weather = "clear"

	# ---- notebook ----
	check(Book.shown("fire+ice") == "???", "nothing is listed before you find it")
	var e = g.spawn_enemy("goblin", g.p.pos + Vector2(50, 0))
	e.mhp = 99999.0
	e.hp = 99999.0
	e.stun = 999.0
	var gems = Meta.S.gems
	g.hurt_enemy(e, 1.0, "fire")
	g.hurt_enemy(e, 1.0, "ice")
	check(Book.known("fire+ice") and Meta.S.gems == gems + 3, "a first reaction is written down and pays")
	g.hurt_enemy(e, 1.0, "fire")
	g.hurt_enemy(e, 1.0, "ice")
	check(Meta.S.gems == gems + 3, "it only pays once")
	Meta.S.book["fire+ice"] = "GRANDMA SOUP"
	check(not g.fields.is_empty() and Combo.name_of(g.fields[0]) == "GRANDMA SOUP", "the game uses the name you gave")
	g.hurt_enemy(e, 1.0, "bolt")
	check(Book.known("s_tox"), "storms are written down too")
	await frames(10)
	shot("book_name")
	e.dead = true
	g.fields.clear()
	g.book_page = 0
	var rows = Book.rows(g)
	check(rows.size() == Book.PAGE + 1 and rows[0].name == "GRANDMA SOUP" and rows[1].name == "???", "the notebook lists what you know")
	rows[0].fn.call()
	check(g.pending_say == "fire+ice", "a known note can be renamed")
	g.pending_say = ""
	check(g.Wish.clean("s\u00fap b\u00e0 n\u1ed9i!! 12345678901234567890").length() <= 14, "names are trimmed to the font")

	# ---- puzzle rooms ----
	for kind in ["chasm", "braziers", "conduit"]:
		var s = seed_with(kind)
		check(s > 0, "a seed with a %s room exists" % kind)
		if s <= 0:
			continue
		g.goto_lobby()
		g.start_run(s, false)
		var r = puzzle_room()
		check(r != null and r.puzzle == kind, "the run has the %s room" % kind)
		if r == null:
			continue
		check(r.cleared, "a puzzle room never locks")
		var ch = chest_of(r)
		check(ch != null, "the %s room holds a chest" % kind)
		g.p.pos = g.rc(r)
		g.cam = g.p.pos
		await frames(4)
		shot("puzzle_" + kind + "_a")
		if kind == "chasm":
			var c: Vector2i = r.center
			check(g.dg.terr[c.y * g.dg.w + c.x] == 2, "the chasm is a pit")
			check(not ch.sealed, "the chasm chest is only out of reach")
		else:
			check(ch.sealed, "the %s chest starts sealed" % kind)
			g.p.pos = ch.pos + Vector2(0, 4)
			g.interact(ch)
			check(not ch.open, "a sealed chest does not open")
		pop_barrel(r)
		await frames(120 if kind == "braziers" else 30)
		g.p.pos = g.rc(r)
		g.cam = g.p.pos
		await frames(4)
		shot("puzzle_" + kind + "_b")
		if kind == "chasm":
			var c2: Vector2i = r.center
			var col = 0
			for dy in range(-2, 2):
				if g.dg.terr[(c2.y + dy) * g.dg.w + c2.x - 3] == 0:
					col += 1
			check(col == 4, "the ice barrel bridges the chasm (%d of 4 rows)" % col)
		else:
			check(not ch.sealed, "solving the %s room breaks the seal" % kind)
		var relics = g.inter.filter(func(it): return it.kind == "relic").size()
		g.p.pos = ch.pos + Vector2(0, 4)
		g.interact(ch)
		check(ch.open and g.inter.filter(func(it): return it.kind == "relic").size() == relics + 1, "the %s chest pays a relic" % kind)

	# ---- nemesis: speech, mercy, debt ----
	g.goto_lobby()
	g.start_run(12, false)
	var killer = g.spawn_enemy("goblin", g.p.pos + Vector2(30, 0))
	g.p.en = 0.0
	g.el_use = {"fire": 9}
	Nemesis.on_death(g)
	check(Meta.S.nemesis.get("how", "") == "dry", "the nemesis remembers how you died")
	killer.dead = true
	g.p.en = float(g.p.men)
	var n = g.spawn_enemy(Meta.S.nemesis.id, g.p.pos + Vector2(60, 0))
	Nemesis.empower(g, n)
	check(g.banner.sub.find("MANA") >= 0, "it greets you with that memory: " + g.banner.sub)
	await frames(10)
	shot("nemesis_talk")
	g.hurt_enemy(n, 999999.0)
	check(not n.dead and n.get("yielded", false), "a beaten nemesis yields instead of dying")
	var sp = g.inter.filter(func(it): return it.kind == "spare")
	check(sp.size() == 1, "you are offered to spare it")
	g.hurt_enemy(n, 999999.0)
	check(not n.dead, "a stray shot right after does not decide for you")
	await frames(10)
	shot("nemesis_yield")
	if sp.size() == 1:
		g.interact(sp[0])
	check(n.dead and Meta.S.nemesis.is_empty() and Meta.S.ally.get("debt", 0) == 2, "sparing it turns it into a debtor")
	Nemesis.call_ally(g)
	check(g.allies.size() == 1 and g.allies[0].get("friend", false) and int(Meta.S.ally.debt) == 1, "it comes when a boss appears")
	var tgt = g.spawn_enemy("goblin", g.p.pos + Vector2(80, 0))
	tgt.mhp = 99999.0
	tgt.hp = 99999.0
	tgt.stun = 999.0
	await frames(90)
	check(tgt.hp < tgt.mhp, "and it fights for you")
	shot("nemesis_ally")
	tgt.dead = true
	# the other choice
	Meta.S.nemesis = {id = "goblin", name = "GRUK THE PATIENT", el = "", lv = 1, floor = 0, boss = false, how = "shot"}
	g.nem_met = false
	var n2 = g.spawn_enemy("goblin", g.p.pos + Vector2(60, 0))
	Nemesis.empower(g, n2)
	g.hurt_enemy(n2, 999999.0)
	n2.mercy = 0.0
	g.hurt_enemy(n2, 999999.0)
	check(n2.dead and Meta.S.nemesis.is_empty(), "or you finish it")
	check(g.inter.filter(func(it): return it.kind == "spare" and not it.get("gone", false)).is_empty(), "and the offer is gone")

	# ---- graves ----
	Meta.S.graves = []
	g.el_use = {"ice": 5}
	var mine = g.wname(g.p.weapons[g.p.wi])
	Nemesis.bury(g)
	check(Meta.S.graves.size() == 1 and int(Meta.S.graves[0].floor) == g.floor_i, "dying leaves a grave on that floor")
	Meta.save()
	Meta.load_save()
	g.goto_lobby()
	g.start_run(12, false)
	var gr = g.inter.filter(func(it): return it.kind == "grave")
	check(gr.size() == 1, "the next run finds the grave")
	check(g.zones.filter(func(z): return z.get("grave", false) and z.el == "ice").size() == 1, "it seeps your favourite element")
	if gr.size() == 1:
		g.p.pos = gr[0].pos + Vector2(0, 6)
		g.cam = g.p.pos
		await frames(6)
		shot("grave")
		g.interact(gr[0])
		var back = g.inter.filter(func(it): return it.kind == "weapon" and g.wname(it.w) == mine)
		check(back.size() >= 1, "and gives your old weapon back")
		check(Meta.S.graves.is_empty(), "once")
	await frames(30)

	print("WORLD ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(fails)
