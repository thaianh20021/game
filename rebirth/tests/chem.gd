extends SceneTree
# Rooms react to elements, enemy pools can be hijacked, wishes, named skills, the nemesis, prep station.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Env = preload("res://src/env.gd")
const Wish = preload("res://src/wish.gd")
const Nemesis = preload("res://src/nemesis.gd")
const Combo = preload("res://src/combo.gd")
const Lobby = preload("res://src/lobby.gd")
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
		await process_frame

func find(kind):
	# a floor that has a tile of this kind; returns its cell
	for seed in range(1, 40):
		g.start_run(seed, false)
		for fl in [0, 2, 4]:
			g.floor_i = fl
			g.new_floor()
			for y in g.dg.h:
				for x in g.dg.w:
					if g.dg.terr[y * g.dg.w + x] == kind:
						return Vector2i(x, y)
	return null

func cp(c):
	return Vector2(c.x * 16 + 8, c.y * 16 + 8)

func type(s):
	for ch in s:
		var ev = InputEventKey.new()
		ev.pressed = true
		ev.unicode = ch.unicode_at(0)
		g._input(ev)

func shot(n):
	if vis:
		var im = root.get_texture().get_image()
		im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
		im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_" + n + ".png")

func _init():
	Meta.PATH = "user://rebirth_chem.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 5:
		await process_frame
	Meta.S.pet = ""
	g.goto_lobby()
	# ice: mire and pits become ground
	var c = find(1)
	Env.touch(g, cp(c), 4.0, "fire")
	check(g.terr_at(cp(c)) == 1, "fire does nothing to mire")
	Env.touch(g, cp(c), 4.0, "ice")
	check(g.terr_at(cp(c)) == 0 and g.patches.size() >= 1, "ice freezes mire")
	c = find(2)
	g.add_bullet(cp(c) + Vector2(-20, 0), Vector2(120, 0), {dmg = 1.0, el = "ice", life = 1.0})
	await frames(12)
	check(g.terr_at(cp(c)) == 0, "an ice shot flying over a pit bridges it")
	g.p.inv = 0.0
	g.p.safe = g.p.pos
	g.p.pos = cp(c)
	await frames(2)
	check(g.p.pos.distance_to(cp(c)) < 3.0, "you can stand on the ice bridge")
	# fire: brush burns and spreads, crates burn
	c = find(4)
	var brush = 0
	for v in g.dg.terr:
		if v == 4:
			brush += 1
	Env.touch(g, cp(c), 4.0, "fire")
	await frames(90)
	var left = 0
	for v in g.dg.terr:
		if v == 4:
			left += 1
	print("brush tiles ", brush, " -> ", left)
	check(left < brush - 2, "fire spreads through dry brush")
	var crates = g.props.filter(func(pr): return pr.kind == "crate")
	if crates.size() > 0:
		Env.touch(g, crates[0].pos, 4.0, "fire")
		check(crates[0].dead, "fire burns crates")
	# storm: runs through mire
	c = find(1)
	var e = g.spawn_enemy("goblin", cp(c))
	e.mhp = 9999.0
	e.hp = 9999.0
	var far = c
	for d in Env.N4:
		if Env.terr(g, c + d) == 1:
			far = c + d
	Env.touch(g, cp(far), 4.0, "bolt")
	check(e.hp < 9999.0 and e.stun > 0.0, "lightning in mire shocks foes standing in it")
	g.enemies.clear()
	# venom: cracked walls
	for seed in range(1, 30):
		g.start_run(seed, false)
		if not g.dg.cracks.is_empty():
			break
	var cr2 = g.dg.cracks[0]
	Env.touch(g, cp(cr2.cell), 6.0, "tox")
	check(cr2.open, "venom eats a cracked wall")
	# hijack: enemy fire pool + ice = steam that is yours
	g.zones.clear()
	g.fields.clear()
	var zp = g.p.pos + Vector2(60, 0)
	g.zones.append({pos = zp, r = 16.0, el = "fire", life = 3.0, team = 1, tick = 0.5})
	g.add_bullet(zp + Vector2(-30, 0), Vector2(200, 0), {dmg = 1.0, el = "ice", life = 1.0})
	await frames(8)
	check(g.zones.filter(func(z): return z.team == 1 and z.life > 0.0).is_empty(), "the enemy pool is gone")
	check(g.fields.size() == 1 and Combo.name_of(g.fields[0]) == "STEAM", "and became a steam field")
	await frames(10)
	shot("hijack")
	# weather out-damages weapons
	g.fields.clear()
	var a = g.spawn_enemy("goblin", g.p.pos + Vector2(40, 0))
	a.mhp = 99999.0
	a.hp = 99999.0
	a.stun = 99.0
	Combo.spawn(g, a.pos, "fire+tox")
	await frames(60)
	var by_field = 99999.0 - a.hp
	g.fields.clear()
	a.hp = 99999.0
	g.p.weapons = [{id = "pistol", el = "", el2 = "", lv = 0}, null]
	g.sim["mouse"] = Vector2(340, 135)
	g.sim["fire"] = true
	await frames(60)
	g.sim.erase("fire")
	print("2s of wildfire ", snapped(by_field, 0.1), " vs 2s of basic weapon ", snapped(99999.0 - a.hp, 0.1))
	check(by_field > (99999.0 - a.hp), "a field should out-damage a basic weapon")
	g.enemies.clear()
	# wishes
	check(Wish.wish_buff("more health please") == "vital" and Wish.wish_buff("xuyên") == "pierce" and Wish.wish_buff("hồi sinh") == "wind2", "wish words")
	g.next_floor()
	check(g.state == "buff", "blessing screen")
	type("giap")
	await frames(12)
	shot("wish")
	var mar = g.p.mar
	g.jp[KEY_ENTER] = true
	await frames(3)
	check(g.state == "play" and g.p.buffs.has("plating") and g.p.mar == mar + 2, "a typed wish grants its blessing")
	# naming a skill
	g.end_run(false)
	g.goto_lobby()
	var lect = g.inter.filter(func(it): return it.get("egg", "") == "lectern")
	check(lect.size() == 1, "the hub has a lectern")
	g.interact(lect[0])
	check(g.state == "menu" and g.menu.kind == "spell", "the lectern opens its menu")
	Meta.S.gems = 500
	g.Lobby.activate(g, g.menu.rows[0])
	g.Lobby.activate(g, g.menu.rows[0])
	g.Lobby.activate(g, g.menu.rows[3])
	shot("say")
	g.set_state("play")
	check(Meta.S.gems == 500 - 15 - 30 and g.p.sk1[0] > 1.29 and g.p.sk_el == "fire", "trained skill: " + str(g.p.sk1) + " " + g.p.sk_el)
	g.start_run(3, false)
	g.p.weapons[0].el = "ice"
	var t = g.spawn_enemy("goblin", g.p.pos + Vector2(20, 0))
	t.mhp = 9999.0
	t.hp = 9999.0
	Ext.cast(g, 0, t.pos)
	await frames(8)
	check(t.st.has("fire"), "the renamed skill uses its own element")
	g.enemies.clear()
	# nemesis: die to a foe, meet it again, kill it
	g.spawn_enemy("goblin", g.p.pos + Vector2(10, 0))
	g.el_use = {"ice": 9, "fire": 2}
	g.p.mount = null
	g.p.relics = []
	g.p.feather = false
	g.p.wind2 = false
	g.p.inv = 0.0
	g.p.dash_t = 0.0
	g.p.shield_t = 0.0
	g.p.spin = 0.0
	g.hurt_player(99)
	await process_frame
	var n = Nemesis.current()
	check(g.state == "dead" and n.get("id", "") == "goblin" and n.get("el", "") == "ice" and int(n.get("lv", 0)) == 1, "the killer becomes the nemesis: " + str(n))
	g.goto_lobby()
	check(g.banner.text.begins_with("NEMESIS"), "the hub warns about it")
	g.start_run(3, false)
	var room = null
	for r in g.dg.rooms:
		if r.get("nemesis", false):
			room = r
	check(room != null, "it waits in a fight room")
	var met = null
	if room != null:
		g.p.pos = g.rc(room) + Vector2(0, 20)
		for i in 900:
			for q in g.enemies:
				if q.get("nem", false):
					met = q
			if met != null:
				break
			for q in g.enemies:
				g.kill(q)
			await frames(1)
	print("nemesis met: ", met != null, " ", [met.el, met.nem_name, met.mhp] if met != null else [])
	check(met != null and met.el == "ice" and met.nem_name == n.name and met.mhp > 60.0, "it returns named, tougher and resistant")
	if met != null:
		await frames(20)
		shot("nemesis")
		var gems = Meta.S.gems
		g.kill(met)
		check(Nemesis.current().is_empty() and Meta.S.gems > gems, "killing it ends the grudge and pays")
	# prep station
	g.end_run(false)
	g.goto_lobby()
	check(g.inter.filter(func(it): return it.get("menu", "") in ["brew", "armory", "bench"]).is_empty(), "the three shops are gone")
	g.open_menu("prep")
	Lobby.activate(g, g.menu.rows[0])
	check(g.state == "menu" and g.menu.kind == "brew", "the quartermaster opens the meals")
	check(g.inter.filter(func(it): return it.kind == "active").is_empty(), "no active items")
	print("CHEM ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
