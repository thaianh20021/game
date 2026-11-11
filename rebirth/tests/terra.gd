extends SceneTree
# The seven newest elements against the room, and prompts that follow the gamepad.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Env = preload("res://src/env.gd")
const Pad = preload("res://src/pad.gd")
const Book = preload("res://src/book.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for i in n: await process_frame
func at(cell: Vector2i) -> int:
	return g.dg.terr[cell.y * g.dg.w + cell.x]
func put(cell: Vector2i, t: int) -> void:
	g.dg.terr[cell.y * g.dg.w + cell.x] = t
func _init():
	Meta.PATH = "user://rebirth_terra.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.goto_lobby()
	g.start_run(5, false)
	await frames(5)
	if g.dg.terr.size() == 0:
		g.dg.terr.resize(g.dg.w * g.dg.h)
	var c: Vector2 = g.p.pos
	var cell = Vector2i((c / 16.0).floor())
	var mid: Vector2 = Env.cell_pos(cell)

	# ---- terrain ----
	put(cell, 2)
	Env.touch(g, mid, 6.0, "water")
	check(at(cell) == 1 and g.patches.back().kind == "pond", "water floods a pit into mire")
	check(Book.known("e_water"), "the notebook records the flood")
	Env.touch(g, mid, 6.0, "leaf")
	check(at(cell) == 4 and g.patches.back().kind == "growth", "leaf overgrows mire into brush")
	Env.touch(g, mid, 6.0, "fire")
	check(at(cell) == 0 and g.patches.back().kind == "ash", "that brush burns like any other")
	g.zones.clear()
	put(cell, 1)
	Env.touch(g, mid, 6.0, "earth")
	check(at(cell) == 0 and g.patches.back().kind == "soil", "earth firms up mire")
	put(cell, 2)
	Env.touch(g, mid, 6.0, "earth")
	check(at(cell) == 0 and g.patches.back().kind == "rubble", "earth fills a pit")
	put(cell, 2)
	Env.touch(g, mid, 6.0, "wood")
	check(at(cell) == 0 and g.patches.back().kind == "plank", "wood bridges a pit")
	put(cell, 2)
	Env.touch(g, mid, 6.0, "metal")
	Env.touch(g, mid, 6.0, "mech")
	check(at(cell) == 2, "metal and gear leave pits alone")
	put(cell, 0)

	# water puts out fire pools, but not a grave's
	g.zones.append({pos = mid, r = 12.0, el = "fire", life = 5.0, team = 0, tick = 0.3})
	g.zones.append({pos = mid, r = 12.0, el = "tox", life = 5.0, team = 0, tick = 0.3})
	Env.touch(g, mid, 6.0, "water")
	check(g.zones[0].life <= 0.0 and g.zones[1].life > 0.0, "water puts out fire and only fire")
	g.zones.clear()

	# metal cuts crates and cracked walls
	var crate = {kind = "crate", pos = mid + Vector2(10, 0), hp = 6.0, dead = false, flash = 0.0}
	g.props.append(crate)
	Env.touch(g, mid, 8.0, "metal")
	check(crate.dead, "metal cuts a crate")
	if g.dg.cracks.size() > 0:
		var cr = g.dg.cracks[0]
		Env.touch(g, Env.cell_pos(cr.cell), 6.0, "metal")
		check(cr.open, "metal cuts a cracked wall")

	# gear jams a trap for good
	var tr = {kind = "spike", pos = mid + Vector2(8, 0), t = 0.0, dir = Vector2.ZERO, tick = 0.0, st = "idle"}
	g.traps.append(tr)
	Env.touch(g, mid, 8.0, "mech")
	check(tr.get("off", false), "gear jams a trap")
	var hp0 = g.p.hp
	g.p.pos = tr.pos
	g.p.inv = 0.0
	await frames(120)
	check(g.p.hp == hp0, "a jammed trap never fires")
	g.traps.erase(tr)

	# X borrows another element's behaviour: sooner or later it changes a pit
	put(cell, 2)
	for i in 80:
		Env.touch(g, mid, 6.0, "x")
	check(at(cell) != 2, "X ends up acting on the room")
	put(cell, 0)

	# ---- prompts follow the pad ----
	g.p1_pad = false
	check(Pad.key_name(g, "E") == "E" and Pad.hint(g, "Q SWAP  E USE") == "Q SWAP  E USE", "keyboard prompts are untouched")
	g.p1_pad = true
	g.sim.pad_style = "xbox"
	check(Pad.key_name(g, "E") == "X", "xbox: interact is X")
	check(Pad.hint(g, "WASD MOVE  MOUSE AIM  LMB FIRE  RMB + F SKILLS  R BURST  SPACE DASH  Q SWAP  E USE") == "L-STICK MOVE  R-STICK AIM  RT FIRE  LB + RB SKILLS  R3 BURST  A DASH  Y SWAP  X USE", "xbox line: " + Pad.hint(g, "WASD MOVE  MOUSE AIM  LMB FIRE  RMB + F SKILLS  R BURST  SPACE DASH  Q SWAP  E USE"))
	check(Pad.hint(g, "PRESS ENTER TO RETURN TO THE HEARTH") == "PRESS A TO RETURN TO THE HEARTH", "words that contain key letters are left alone")
	check(Pad.hint(g, "W/S CHOOSE   ENTER OR CLICK CONFIRM   ESC CLOSE") == "D-PAD CHOOSE   A CONFIRM   B CLOSE", "menu line: " + Pad.hint(g, "W/S CHOOSE   ENTER OR CLICK CONFIRM   ESC CLOSE"))
	g.sim.pad_style = "ps"
	check(Pad.key_name(g, "E") == "SQUARE" and Pad.hint(g, "SPACE DASH  RMB SKILL") == "CROSS DASH  L1 SKILL", "playstation names")
	g.sim.pad_style = "nin"
	check(Pad.key_name(g, "E") == "Y" and Pad.key_name(g, "SPACE") == "B", "nintendo letters follow position")
	g.sim.erase("pad_style")
	# a real frame with pad prompts must draw
	await frames(10)
	g.p1_pad = false

	print("TERRA OK" if fails == 0 else "TERRA FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
