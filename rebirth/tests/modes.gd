extends SceneTree
# Boss Rush (one boss per zone, the Loom last) and the daily run's single sky.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Wx = preload("res://src/sky.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for k in n: await process_frame
func _init():
	Meta.PATH = "user://rebirth_modes.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.goto_lobby()
	await frames(3)
	g.open_menu("board")
	check(g.menu.rows.any(func(r): return r.name.begins_with("BOSS RUSH")), "the run board offers a boss rush")
	g.set_state("play")
	# ---- boss rush ----
	g.start_run(321, false, "rush")
	await frames(5)
	check(g.run_mode == "rush" and g.floor_i == 1, "a rush starts on the first boss floor")
	var main = g.dg.rooms.filter(func(r): return r.type in ["start", "fight", "boss"])
	check(main.size() == 3 and g.dg.rooms.any(func(r): return r.type == "boss") and g.dg.rooms.all(func(r): return r.type in ["start", "fight", "boss", "shop"]), "a short floor: start, one fight, the boss, a shop: " + str(g.dg.rooms.map(func(r): return r.type)))
	var seen = [g.dg.boss_id]
	for k in 3:
		g.next_floor()
		await frames(2)
		check(g.state == "buff", "a blessing between bosses")
		g.take_buff(g.buff_choices[0])
		g.buff_turn = 0
		g.floor_i += 2
		g.new_floor()
		g.set_state("play")
		await frames(2)
		seen.append(g.dg.boss_id)
	check(g.floor_i == 7 and seen[-1] == "loom", "the rush ends with the Loom: " + str(seen))
	check(seen[0] in D.BIOMES[0].bosses and seen[1] in D.BIOMES[1].bosses and seen[2] in D.BIOMES[2].bosses, "one boss from each zone")
	g.boss_kills = 4
	g.next_floor()
	await frames(3)
	check(g.state == "win" and int(Meta.S.get("rush", 0)) == 4, "beating the last wins and is remembered")
	# the floor step in a real pick of a blessing
	g.goto_lobby()
	await frames(2)
	g.start_run(321, false, "rush")
	await frames(3)
	g.next_floor()
	await frames(2)
	g.buff_sel = 0
	g.pick_buff(0)
	await frames(3)
	check(g.floor_i == 3, "taking a blessing goes on to the next zone's boss: %d" % g.floor_i)
	# ---- the daily: one sky for every floor ----
	var today = Meta.today()
	var k = Wx.daily_kind(today)
	check(k in ["rain", "drought", "fog", "gale"], "the daily has a real sky: " + k)
	for f in range(1, 8):
		check(Wx.floor_weather(today, f, true) == k, "daily floor %d is %s" % [f, k])
	check(Wx.floor_weather(today, 0, true) == "clear", "the first floor is still clear")
	g.goto_lobby()
	await frames(2)
	g.start_run(today, true)
	await frames(3)
	g.floor_i = 3
	g.new_floor()
	check(g.dg.weather == k, "a daily floor has the day's sky")
	print("MODES OK" if fails == 0 else "MODES FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
