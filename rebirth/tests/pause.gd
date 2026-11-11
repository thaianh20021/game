extends SceneTree
# The pause menu and the difficulty dials.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for k in n: await process_frame
func press(k):
	g.jp[k] = true
	await frames(2)
func _init():
	Meta.PATH = "user://rebirth_pause.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.goto_lobby()
	await frames(5)
	# ---- in the Hearth ----
	g.set_state("pause")
	await frames(10)
	var ids = g.pause_rows().map(func(r): return r[0])
	check(ids == ["resume", "opts", "guide", "title", "exit"], "hearth rows: " + str(ids))
	await press(KEY_DOWN)
	check(g.pause_sel == 1, "down moves")
	await press(KEY_ENTER)
	check(g.state == "menu" and g.menu.kind == "opts", "settings opens")
	g.set_state("pause")
	await frames(10)
	g.pause_sel = 2
	await press(KEY_ENTER)
	check(g.state == "pause" and g.pause_page == "guide", "the guide opens")
	await frames(10)
	await press(KEY_ESCAPE)
	check(g.state == "pause" and g.pause_page == "", "and closes back to the list")
	await press(KEY_ESCAPE)
	check(g.state == "play", "escape resumes")
	# ---- in a run ----
	g.start_run(5, false)
	await frames(5)
	g.set_state("pause")
	await frames(10)
	ids = g.pause_rows().map(func(r): return r[0])
	check(ids == ["resume", "opts", "guide", "abandon", "exit"], "run rows: " + str(ids))
	g.pause_sel = 3
	await press(KEY_ENTER)
	check(g.state == "pause" and g.pause_arm == "abandon", "abandon asks first")
	await press(KEY_UP)
	check(g.pause_arm == "", "moving away withdraws it")
	g.pause_sel = 3
	await press(KEY_ENTER)
	await press(KEY_ENTER)
	check(g.state == "dead", "the second press abandons: " + g.state)
	# a tap on a row works too
	g.goto_lobby()
	g.tin.on = true
	g.set_state("pause")
	await frames(10)
	var ev = InputEventScreenTouch.new()
	ev.position = g.pause_rect(0).get_center() + g.hud.position
	ev.pressed = true
	g._input(ev)
	await frames(2)
	check(g.state == "play", "tapping RESUME resumes")
	g.tin.on = false
	# ---- difficulty ----
	g.start_run(5, false)
	await frames(5)
	var e = g.spawn_enemy("goblin", g.p.pos + Vector2(40, 0))
	check(absf(e.mhp - D.ENEMIES["goblin"].hp * 1.2 * D.DIFF.hp) < 0.6, "foes carry the health dial: %.1f" % e.mhp)
	e.stun = 0.0
	e.born = 0.0
	e.t = 5.0
	await frames(30)
	check(absf((5.0 - e.t) - D.DIFF.rate) < 0.15, "their attack clock runs at the rate dial: %.2f" % (5.0 - e.t))
	var d = g.spawn_enemy("dummy", g.p.pos + Vector2(80, 0))
	check(d.mhp < 200000.0 and absf(d.mhp - 99999 * 1.2) < 1.0, "the dummy is left alone")
	print("PAUSE OK" if fails == 0 else "PAUSE FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
