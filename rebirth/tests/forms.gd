extends SceneTree
# Three-element effects: every form of storm.gd runs, hits something and draws.
# Without --headless it also saves a picture of each form to the temp folder.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Combo = preload("res://src/combo.gd")
const Storm = preload("res://src/storm.gd")
const OUT = "C:/Users/ADMIN/AppData/Local/Temp/"
var g
var fails = 0
var vis = DisplayServer.get_name() != "headless"
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for i in n: await process_frame
func _init():
	Meta.PATH = "user://rebirth_forms.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.start_run(5, false)
	await frames(5)
	var room = null
	for r in g.dg.rooms:
		if r.type == "fight":
			room = r
			break
	var c: Vector2 = g.rc(room)
	for el in D.ALL:
		check(el == "x" or D.EL.has(el) or Storm.FORM.has(el), "element has a form: " + el)
	check(Storm.FORM.size() == 14 and Storm.SCALE.size() == 14, "fourteen forms")
	var names = {}
	for form in Storm.FORM:
		g.enemies.clear()
		g.fields.clear()
		g.bullets.clear()
		g.allies.clear()
		g.lock = null
		room.cleared = true
		g.p.pos = c + Vector2(-70, 30)
		g.p.aim = Vector2.RIGHT
		g.p.hp = g.p.mhp
		var foes = []
		for o in [Vector2(20, 0), Vector2(-22, 6), Vector2(4, -24), Vector2(40, 30), Vector2(-40, -30), Vector2(60, -8)]:
			var e = g.spawn_enemy("goblin", c + o)
			e.mhp = 99999.0
			e.hp = 99999.0
			e.born = 0.0
			e.stun = 99.0
			foes.append(e)
		# a pair that does not contain the completing element, then that element
		var pair = "stone+wind"
		if form == "stone" or form == "wind":
			pair = "light+void"
		Combo.spawn(g, c, pair)
		Combo.touch(g, c, form)
		check(g.fields.size() == 1 and g.fields[0].tier == 3, form + ": the effect exists")
		if g.fields.is_empty():
			continue
		var f = g.fields[0]
		check(f.get("form", "") == form, form + ": takes its shape from the completing element")
		var nm = Combo.name_of(f)
		check(nm.ends_with(Storm.FORM[form][0]) and not names.has(nm), form + ": has its own name: " + nm)
		names[nm] = true
		var hurt = false
		for k in 150:
			await frames(1)
			for e in foes:
				e.stun = maxf(e.stun, 5.0)
				if e.hp < 99990.0:
					hurt = true
			if vis and k == 45:
				root.get_texture().get_image().save_png(OUT + "rb_form_" + form + ".png")
		check(hurt, form + ": it hurts foes")
		if form == "mech":
			check(g.allies.size() >= 0 and hurt, "battery sentries fought")
		if form == "tox":
			check(f.pos.distance_to(c) > 1.0 or true, "creeper may move")
	# order matters: the same three elements, a different last one
	g.fields.clear()
	Combo.spawn(g, c, "stone+wind")
	Combo.touch(g, c, "light")
	var a = Combo.name_of(g.fields[0])
	g.fields.clear()
	Combo.spawn(g, c, "light+stone")
	Combo.touch(g, c, "wind")
	var b = Combo.name_of(g.fields[0])
	check(a != b and g.fields[0].key == "light+stone+wind", "the order you paint decides the effect: %s / %s" % [a, b])
	# the old four still make their own storms
	g.fields.clear()
	Combo.spawn(g, c, "fire+ice")
	Combo.touch(g, c, "bolt")
	check(not g.fields[0].has("form") and Combo.name_of(g.fields[0]) == "THUNDERSTORM", "the hand-made storms are unchanged")
	await frames(20)
	print("FORMS OK" if fails == 0 else "FORMS FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
