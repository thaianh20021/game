extends SceneTree
# The 28 link trees (one for each pair of masteries). For every link node: some game code reads it.
# For every pair: a hero with both masteries and the whole link tree fights a small pack, casting every
# active skill of both masteries, and nothing breaks (finite numbers, foes hurt, the hero still standing).
# Script errors are printed by Godot itself; the runner greps for them. Run with --fixed-fps 60.
const D = preload("res://src/data.gd")
const Sk = preload("res://src/skills.gd")
var g
var fails = 0
var passes = 0
const LOCKS = {"bulwark": ["lb_twin"], "summon": ["th_fire"], "sacrifice": ["ch_send", "th_fire"]}

func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if ok:
		passes += 1
	else:
		fails += 1

func frames(n: int) -> void:
	for i in n:
		await process_frame

func finite(v: Vector2) -> bool:
	return not (is_nan(v.x) or is_nan(v.y) or is_inf(v.x) or is_inf(v.y))

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_links.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)

	# ---- every link node is read somewhere outside the skill data
	var code = ""
	for f in ["game.gd", "ui.gd", "world.gd", "data.gd"]:
		code += FileAccess.get_file_as_string("res://src/" + f)
	var unread = []
	var count = 0
	for id in Sk.NODES:
		if Sk.LINKS.has(Sk.NODES[id].get("m", 0)):
			count += 1
			if code.find('"%s"' % id) < 0:
				unread.append(id)
	check("there are 224 link nodes (28 trees x 8), got %d" % count, count == 224)
	check("every link node is read by the game" + ("" if unread.is_empty() else ": unread " + str(unread)), unread.is_empty())

	# ---- each pair in a fight
	for link in Sk.LINKS:
		var a: int = Sk.LINKS[link][0]
		var b: int = Sk.LINKS[link][1]
		var tag = "%s + %s" % [Sk.MASTERY[a], Sk.MASTERY[b]]
		var tree = {}
		var acts = []
		for id in Sk.NODES:
			var n = Sk.NODES[id]
			var nm = n.get("m", 0)
			if nm == a or nm == b or nm == link:
				tree[id] = n.max
				if n.kind == "a" and nm != link:
					acts.append(id)
		g.new_game()
		g.main_m = a
		g.second_m = b
		g.qs["m6"] = "done"
		g.lvl = 60
		g.tree = tree
		g.bar = ["", "", "", "", ""]
		for i in mini(5, acts.size()):
			g.bar[i] = acts[i]
		g.recompute()
		g.sim.no_spawns = true
		g.mode = "play"
		g.enter_zone("field", Vector2.ZERO)
		g.fresh_hero()
		g.p.pos = Vector2(34 * 16, 23 * 16)
		g.p.aim = Vector2.RIGHT
		g.p.mhp = 99999.0
		g.p.hp = 99999.0
		for k in g.KEYS:
			g.sim[k] = false
		g.sim.move = Vector2.ZERO
		g.sim.ui_mouse = Vector2(-50, -50)
		var pack = []
		for i in 5:
			var f = g.spawn("reed", g.p.pos + Vector2(40, 0).rotated(i * 0.6 - 1.2))
			f.hp = 3000.0
			f.mhp = 3000.0
			pack.append(f)
		g.sim.mouse = pack[2].pos
		var cast_ok = 0
		var denied = []
		for id in acts:
			# keystones that take a skill away on purpose
			if LOCKS.has(id) and LOCKS[id].any(func(k): return g.tree.has(k)):
				cast_ok += 1
				continue
			g.p.state = "idle"
			g.p.rage = 100.0
			g.p.cp = 5
			g.p.souls = g.soul_cap()
			g.p.cds.erase(id)
			if g.cast(id):
				cast_ok += 1
			else:
				denied.append(id)
			await frames(20)
		g.sim.atk = true
		await frames(120)
		g.sim.atk = false
		var ult = g.cur_ult()
		if ult != "":
			g.p.state = "idle"
			g.p.rage = 100.0
			g.p.cds.erase(ult)
			g.cast(ult)
			await frames(60)
		var hurt = 0.0
		for f in pack:
			hurt += 3000.0 - maxf(f.hp, 0.0)
		var ok = cast_ok == acts.size() and hurt > 0.0 and g.p.hp > 0.0 and not is_nan(g.p.hp) and finite(g.p.pos)
		for f in g.foes:
			if not finite(f.pos) or is_nan(f.hp):
				ok = false
		check("%s: %d/%d skills cast%s, pack took %d, hero standing" % [tag, cast_ok, acts.size(), "" if denied.is_empty() else " (denied " + str(denied) + ")", int(hurt)], ok)
		g.sim.mouse = g.p.pos + Vector2(60, 0)

	print("== links pass=%d fail=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
