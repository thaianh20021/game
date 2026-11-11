extends SceneTree
# Reactions leave fields; a third element makes a storm; the fourth a cataclysm.
const Meta = preload("res://src/meta.gd")
const Combo = preload("res://src/combo.gd")
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
func dummy(pos):
	var e = g.spawn_enemy("goblin", pos)
	e.mhp = 99999.0
	e.hp = 99999.0
	e.stun = 999.0
	return e
func _init():
	Meta.PATH = "user://rebirth_combo.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 5: await process_frame
	Meta.S.pet = ""
	g.goto_lobby()
	g.start_run(12, false)
	var c = g.p.pos + Vector2(50, 0)
	var e = dummy(c)
	var o = dummy(c + Vector2(40, 10))
	# fire + ice -> steam
	g.hurt_enemy(e, 1.0, "fire")
	check(g.fields.is_empty(), "one element is not a combination")
	g.hurt_enemy(e, 1.0, "ice")
	check(g.fields.size() == 1 and Combo.name_of(g.fields[0]) == "STEAM", "fire + ice leaves steam")
	g.add_bullet(g.center(e) + Vector2(10, 0), Vector2(1, 0), {team = 1, el = "", r = 3.0, life = 5.0})
	await frames(6)
	check(g.bullets.filter(func(b): return b.team == 1).is_empty(), "steam eats enemy bullets")
	await frames(20)
	shot("combo2")
	# + storm -> thunderstorm
	g.hurt_enemy(e, 1.0, "ice")
	check(g.fields[0].tier == 2, "an element already in the field changes nothing")
	g.hurt_enemy(e, 1.0, "bolt")
	check(g.fields[0].tier == 3 and Combo.name_of(g.fields[0]) == "THUNDERSTORM", "steam + storm makes a thunderstorm")
	var hp_o = o.hp
	await frames(40)
	check(o.hp < hp_o, "the thunderstorm strikes foes across its area")
	shot("combo3")
	# + venom -> cataclysm
	g.add_bullet(g.p.pos + Vector2(200, -60), Vector2.ZERO, {team = 1, el = "", r = 3.0, life = 5.0})
	hp_o = o.hp
	g.hurt_enemy(e, 1.0, "tox")
	await frames(6)
	check(g.fields.filter(func(f): return f.tier == 3).is_empty() and o.hp < hp_o - 20.0, "the fourth element ends in a cataclysm")
	check(g.bullets.filter(func(b): return b.team == 1 and not b.dead).is_empty(), "the cataclysm clears enemy bullets")
	# every pair and every triple has a name
	for key in g.D.REACT:
		check(Combo.FIELD.has(key), "field for " + key)
	g.fields.clear()
	g.enemies.clear()
	var names = {}
	var third = {"fire+tox": "bolt", "ice+tox": "bolt", "bolt+ice": "fire", "fire+ice": "tox"}
	for key in third:
		g.fields.clear()
		Combo.spawn(g, c, key)
		Combo.touch(g, c, third[key])
		names[Combo.name_of(g.fields[0])] = true
		await frames(30)
	print("storms: ", names.keys())
	check(names.size() == 4, "four different storms")
	# a blast (barrel, bomb) of a third element also upgrades a field
	g.fields.clear()
	Combo.spawn(g, c, "bolt+fire")
	g.explode(c + Vector2(30, 0), 30.0, 1.0, "ice", 0)
	check(g.fields[0].tier == 3, "explosions count as a third element")
	print("COMBO ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
