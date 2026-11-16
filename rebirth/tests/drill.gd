extends SceneTree
# The Training Grounds: six scripted rooms, nobody dies, the portal leads home.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Drill = preload("res://src/drill.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for k in n: await process_frame
func _init():
	Meta.PATH = "user://rebirth_drill.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.goto_lobby()
	await frames(3)
	check(g.pause_rows().any(func(r): return r[0] == "drill"), "the pause menu in the Hearth offers the grounds")
	var gems0 = int(Meta.S.gems)
	Drill.start(g)
	await frames(5)
	check(Drill.active(g) and not g.in_lobby, "the grounds start as a floor")
	var fights = g.dg.rooms.filter(func(r): return r.type == "fight")
	check(fights.size() == Drill.ROOMS.size() and g.dg.rooms.all(func(r): return r.type in ["start", "fight", "exit"]), "six fight rooms and nothing beside: %d" % fights.size())
	check(g.pause_rows().any(func(r): return r[1] == "LEAVE TRAINING"), "it can be left from the pause menu")
	# nobody dies
	g.p.hp = 1
	g.p.ar = 0
	g.p.inv = 0.0
	g.hurt_player(5)
	check(g.p.hp == g.p.mhp and g.state == "play", "a fatal hit puts you back on your feet")
	for i in fights.size():
		var r = fights[i]
		g.p.pos = g.rc(r)
		g.p.safe = g.p.pos
		g.p.inv = 99.0
		var n = 0
		while g.lock != r and n < 40:
			g.p.pos = g.rc(r)
			await frames(1)
			n += 1
		check(g.lock == r and g.drill.room == i, "room %d teaches lesson %d" % [i, i])
		await frames(40)
		var id: String = Drill.ROOMS[i][0]
		check(id == "armor" and g.boss != null or id != "armor" and not g.enemies.is_empty(), "lesson %s has foes" % id)
		if id == "ward":
			check(g.enemies.all(func(e): return e.get("ward", false)), "the ward room's foes are warded")
		if id == "mirror":
			check(g.enemies.any(func(e): return e.get("afx", []).has("mirror")), "the mirror room has a mirror")
		if id == "perfect":
			check(g.enemies.all(func(e): return e.get("afx", []).has("mark")), "the perfect room has marksmen")
		if id in ["charge", "shape", "perfect"]:
			for e in g.enemies.duplicate():
				g.kill(e)
			await frames(40)
			check(not r.cleared and Drill.busy(g), "%s: killing the foes is not enough" % id)
			check(not g.enemies.is_empty() or g.pending > 0, "%s: more foes come" % id)
			match id:
				"charge": g.tally("rel")
				"shape": g.tally("pure")
				"perfect": g.tally("perf")
		else:
			for e in g.enemies.duplicate():
				g.kill(e)
			g.boss = null
		n = 0
		while not r.cleared and n < 200:
			g.p.inv = 99.0
			await frames(1)
			n += 1
		check(r.cleared, "lesson %s lets you go on" % id)
	# a stuck lesson moves on by itself
	check(Drill.GIVE_UP < 120.0, "nobody is stuck for long")
	# the exit portal leads home
	g.next_floor()
	await frames(5)
	check(g.in_lobby and g.drill.is_empty() and Meta.S.get("drill", false) and int(Meta.S.gems) == gems0 + 20, "the portal leads home with a reward")
	check(Meta.S.run.is_empty(), "nothing is saved as a run")
	# leaving early
	Drill.start(g)
	await frames(5)
	g.end_run(false)
	await frames(5)
	check(g.in_lobby and g.drill.is_empty(), "leaving goes home without a defeat")
	print("DRILL OK" if fails == 0 else "DRILL FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
