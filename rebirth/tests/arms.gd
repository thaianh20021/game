extends SceneTree
# New weapons, fusion traits, the two newest heroes and elemental resonance.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Arms = preload("res://src/arms.gd")
const Ext = preload("res://src/ext.gd")
const Reso = preload("res://src/reso.gd")
const Art = preload("res://src/art.gd")
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
		g.p.en = float(g.p.men)
		await process_frame
func dummy(pos):
	var e = g.spawn_enemy("goblin", pos)
	e.mhp = 99999.0
	e.hp = 99999.0
	e.stun = 999.0
	return e
func _init():
	Meta.PATH = "user://rebirth_arms.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 5: await process_frame
	Meta.S.hero = 6
	Meta.S.pet = ""
	g.goto_lobby()
	g.start_run(8, false)
	check(g.p.name == "RIVET" and g.p.weapons[0].id == "crossbow", "engineer should start with a crossbow")
	var c = g.p.pos
	g.sim["mouse"] = Vector2(340, 135)
	# every new weapon fires and hurts a foe in front of the hero
	for id in ["crossbow", "boomerang", "spear", "twins", "hammer", "chakram", "grimoire", "launcher"]:
		check(Art.T.has(Art.wtex({id = id, el = "ice", el2 = ""})), "sprite for " + id)
		g.enemies.clear()
		g.bullets.clear()
		var e = dummy(c + Vector2(34, -2))
		g.p.pos = c
		g.p.weapons = [{id = id, el = "", el2 = "", lv = 0}, null]
		g.p.wi = 0
		g.sim["fire"] = true
		await frames(50)
		g.sim.erase("fire")
		check(e.hp < 99999.0, id + " should hit a foe")
	# the boomerang comes back
	g.enemies.clear()
	g.bullets.clear()
	g.p.weapons = [{id = "boomerang", el = "", el2 = "", lv = 0}, null]
	g.p.cd = 0.0
	g.sim["fire"] = true
	await frames(2)
	g.sim.erase("fire")
	var far = 0.0
	var came_back = false
	for i in 60:
		for b in g.bullets:
			far = max(far, b.pos.distance_to(g.p.pos))
		if far > 50.0 and g.bullets.is_empty():
			came_back = true
		await frames(1)
	check(far > 60.0 and came_back, "boomerang should fly out and return")
	# homing shots bend toward a foe that is off to the side
	g.bullets.clear()
	var side = dummy(c + Vector2(70, 46))
	g.p.weapons = [{id = "grimoire", el = "", el2 = "", lv = 0}, null]
	g.sim["fire"] = true
	await frames(70)
	g.sim.erase("fire")
	check(side.hp < 99999.0, "homing shots should curve into a foe")
	# fusion keeps the better weapon and inherits a trait from the other
	g.enemies.clear()
	g.bullets.clear()
	g.p.gold = 100
	g.p.weapons = [{id = "rail", el = "bolt", el2 = "", lv = 1}, {id = "scatter", el = "fire", el2 = "", lv = 0}]
	g.p.wi = 0
	Ext.station(g, {kind = "fuse", pos = c})
	var fw = g.p.weapons[0]
	check(fw.id == "rail" and fw.get("trait", "") == "multi" and fw.el2 == "fire", "railgun + scattergun should fuse into a splitting railgun")
	check(g.wname(fw).ends_with("OF SPLITTING"), "fused name should carry the trait: " + g.wname(fw))
	g.sim["fire"] = true
	var most = 0
	for i in 40:
		most = max(most, g.bullets.size())
		await frames(1)
	g.sim.erase("fire")
	check(most >= 3, "splitting railgun should fire three shots at once")
	for id in D.WEAPONS:
		check(Arms.TRAIT_NAME.has(Arms.trait_of(id)), "trait for " + id)
	# resonance: the same element five times on one foe
	for el in D.EL:
		g.enemies.clear()
		g.zones.clear()
		g.p.weapons = [{id = "pistol", el = el, el2 = "", lv = 0}, null]
		var e = dummy(c + Vector2(40, 0))
		var o = dummy(c + Vector2(60, 10))
		for i in 4:
			g.hurt_enemy(e, 1.0, el)
		check(e.rs != null and e.rs.n == 4 and e.rs.need == 5, el + ": four hits should leave four stacks")
		var hp_o = o.hp
		g.hurt_enemy(e, 1.0, el)
		check(e.get("rs", null) == null, el + ": fifth hit should spend the stacks")
		match el:
			"fire": check(g.zones.size() == 1 and o.hp < hp_o, "eruption should burn the ground and hit neighbours")
			"ice": check(e.frz > 1.0 and o.frz > 0.5, "glacier should freeze target and neighbours")
			"bolt": check(o.hp < hp_o and o.stun > 0.0, "thunderstrike should chain")
			"tox": check(o.tox_n == 5 and g.zones.size() == 1, "bloom should max out poison nearby")
		if vis and el == "bolt":
			await frames(3)
			var im = root.get_texture().get_image()
			im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
			im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_reso.png")
	# attuned: two sources of one element need a stack fewer; pools do not build stacks
	g.enemies.clear()
	g.zones.clear()
	g.p.weapons = [{id = "pistol", el = "ice", el2 = "", lv = 0}, {id = "wand", el = "ice", el2 = "", lv = 0}]
	var e2 = dummy(c + Vector2(40, 0))
	g.hurt_enemy(e2, 1.0, "ice")
	check(e2.rs.need == 4 and Reso.attuned(g) == ["ice"], "two ice sources should be attuned")
	g.hurt_enemy(e2, 1.0, "ice", Vector2.ZERO, true)
	check(e2.rs.n == 1, "damage over time should not add stacks")
	g.hurt_enemy(e2, 1.0, "fire")
	check(e2.get("rs", null) == null or e2.rs.el != "ice", "another element should break the chain")
	# skills of the two newest heroes
	g.enemies.clear()
	var e3 = dummy(c + Vector2(30, 0))
	e3.stun = 0.0
	for sk in ["turret", "pulse", "vines", "spirits"]:
		g.p.skills[0] = sk
		g.p.skill_cd = 0.0
		Ext.cast(g, 0, c + Vector2(40, 0))
		await frames(20)
	check(g.allies.size() == 1, "sentry should be deployed")
	check(e3.frz > 0.0 or e3.stun > 0.0, "vines or pulse should hold the foe")
	check(Meta.fuse_name(D.HEROES[6], D.HEROES[7]) == "RIVSCAP", "fusion names are spliced: " + Meta.fuse_name(D.HEROES[6], D.HEROES[7]))
	if vis:
		g.goto_lobby()
		g.p.pos = Vector2(14 * 16, 10 * 16)
		for i in 60: await process_frame
		var im2 = root.get_texture().get_image()
		im2.resize(1440, 810, Image.INTERPOLATE_NEAREST)
		im2.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_heroes8.png")
	print("ARMS ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
