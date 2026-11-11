extends SceneTree
# Element saturation, blessing emblems and the first lesson.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Art = preload("res://src/art.gd")
const Tutor = preload("res://src/tutor.gd")
const Combo = preload("res://src/combo.gd")
const Ext = preload("res://src/ext.gd")
const Touch = preload("res://src/touch.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for i in n: await process_frame
func _init():
	Meta.PATH = "user://rebirth_lesson.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""

	# ---- emblems ----
	for b in D.BUFFS:
		check(Art.T.has("bl_" + b.id), "blessing has its own emblem: " + b.id)

	# ---- the lesson ----
	g.goto_lobby()
	check(not Tutor.active(g), "tests do not get the lesson unasked")
	g.sim.tutor = true
	g.goto_lobby()
	check(Tutor.active(g) and g.tut.i == 0, "a new save starts the lesson")
	var d = Tutor.dummy(g)
	check(d != null and g.p.pos.distance_to(d.pos) < 80.0, "it starts beside the dummy")
	await frames(3)
	var seen = []
	for n in 40:
		if not Tutor.active(g):
			break
		var id: String = Tutor.STEPS[g.tut.i][0]
		if not seen.has(id):
			seen.append(id)
		match id:
			"move": g.tut.walked = 100.0
			"dash": g.p.dash_t = 0.2
			"paint": g.dummy_hits += 3
			"switch": g.set_el((int(g.p.eli) + 1) % 3)
			"react": Combo.spawn(g, d.pos, "fire+ice")
			"storm":
				if g.fields.is_empty():
					Combo.spawn(g, d.pos, "fire+ice")
				Combo.touch(g, g.fields[0].pos, "bolt")
			"bars": g.tut.t = 8.0
			"skill":
				g.p.skill_cd = 0.0
				Ext.cast(g, 0, d.pos)
			"burst":
				g.tut.t = 1.0
				check(g.p.res >= 1.0, "the burst step fills the bar")
				g.p.res = 0.0
			"go": g.tut.t = 8.0
		await frames(26)
	check(seen.size() == Tutor.STEPS.size(), "every step was reached: " + str(seen))
	check(not Tutor.active(g) and Meta.S.get("tut", false), "the lesson ends and is remembered")
	g.goto_lobby()
	check(not Tutor.active(g), "it does not start twice")
	Tutor.start(g)
	check(Tutor.active(g), "it can be replayed")
	g.jp[KEY_BACKSPACE] = true
	await frames(2)
	check(not Tutor.active(g), "and skipped")
	g.sim.erase("tutor")

	# ---- saturation ----
	g.start_run(5, false)
	await frames(5)
	g.p.weapons[g.p.wi] = {id = "pistol", el = "fire", el2 = "", lv = 0}
	g.set_el(0)
	var first: String = g.p.els[0]
	check(g.paint_el(0.5) == first and g.p.sat[0] < 1.0, "painting drains the chosen element")
	var n = 0
	while not g.p.spent[0] and n < 40:
		g.paint_el(0.5)
		n += 1
	check(g.p.spent[0] and n >= 10 and n <= 16, "about seven seconds of fire empties it: %d shots of 0.5 s" % n)
	check(g.paint_el(0.5) == "", "a spent element paints nothing")
	g.set_el(1)
	check(g.paint_el(0.2) == g.p.els[1], "the next element still paints")
	await frames(60)
	check(not g.p.spent[0] and g.p.sat[0] > D.SAT.back, "a resting element comes back")
	check(g.p.sat[2] >= 1.0, "an untouched element stays full")
	# touch layout: the element button is big and beside the fire stick
	var el = Touch.BUTTONS["el"]
	check(el[1] >= 16.0 and el[0].distance_to(Vector2(412, 208)) < 70.0, "the element button sits by the fire stick")
	for a in Touch.BUTTONS:
		for b in Touch.BUTTONS:
			if a < b:
				check(Touch.BUTTONS[a][0].distance_to(Touch.BUTTONS[b][0]) > Touch.BUTTONS[a][1] + Touch.BUTTONS[b][1], "buttons do not overlap: %s %s" % [a, b])
	await frames(10)
	print("LESSON OK" if fails == 0 else "LESSON FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
