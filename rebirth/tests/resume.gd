extends SceneTree
# Settings menu, first-time hints, and saving / continuing a solo run.
const Meta = preload("res://src/meta.gd")
const Lobby = preload("res://src/lobby.gd")
const Sfx = preload("res://src/sfx.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for i in n: await process_frame
func boot():
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	g.goto_lobby()
	await frames(3)
func _init():
	Meta.PATH = "user://rebirth_resume.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	await boot()
	# settings
	g.open_menu("opts")
	Lobby.activate(g, g.menu.rows[0])
	check(int(Meta.S.opts.music) == 0 and Sfx.vol_music == 0.0, "music volume should cycle to 0")
	Lobby.activate(g, g.menu.rows[3])
	g.shake = 0.0
	g.shake_add(5.0)
	check(g.shake == 0.0, "screen shake off should stop shaking")
	g.set_state("play")
	# run, hints, save
	Meta.S.hero = 4
	g.start_run(4321, false)
	check(Meta.S.run.is_empty(), "floor one is not saved")
	g.spawn_enemy("slime", g.p.pos + Vector2(40, 0))
	g.apply_el(g.enemies[0], "fire", 0.0)
	g.apply_el(g.enemies[0], "ice", 0.0)
	check(Meta.S.tips.has("react") and g.banner.text.begins_with("REACTION"), "first reaction should show a hint")
	g.p.gold = 77
	g.p.weapons[1] = {id = "rail", el = "bolt", el2 = "", lv = 2}
	g.apply_buff("vital")
	g.kills = 12
	g.next_floor()
	g.pick_buff(0)
	await frames(3)
	check(not Meta.S.run.is_empty() and int(Meta.S.run.floor) == 1, "second floor should be saved")
	var name = g.p.name
	var mhp = g.p.mhp
	var grid = g.dg.grid.duplicate()
	var nbuffs = g.p.buffs.size()
	# quit the program and come back
	g.queue_free()
	await frames(3)
	await boot()
	check(not Meta.S.run.is_empty(), "save should survive a restart")
	g.open_menu("board")
	check(g.menu.rows[0].name == "CONTINUE SAVED RUN", "run board should offer to continue")
	Lobby.activate(g, g.menu.rows[0])
	await frames(3)
	check(not g.in_lobby and g.state == "play" and g.floor_i == 1 and g.run_seed == 4321, "continue should enter floor two of the same run")
	print("  restored: ", g.p.name, " gold=", g.p.gold, " mhp=", g.p.mhp, "/", mhp, " buffs=", g.p.buffs.size(), "/", nbuffs, " kills=", g.kills)
	check(g.p.name == name and g.p.gold == 77 and g.p.mhp == mhp and g.p.buffs.size() == nbuffs and g.kills == 12, "hero should be restored")
	check(g.p.weapons[1] != null and g.p.weapons[1].id == "rail" and int(g.p.weapons[1].lv) == 2, "weapons should be restored")
	check(g.dg.grid == grid, "floor layout should be the same")
	check(g.p.pos is Vector2 and g.st.has("dmg"), "restored hero should be simulatable")
	g.sim["fire"] = true
	await frames(60)
	check(g.state == "play", "restored run should keep running")
	g.end_run(false)
	check(Meta.S.run.is_empty(), "ending the run should erase the save")
	print("RESUME ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
