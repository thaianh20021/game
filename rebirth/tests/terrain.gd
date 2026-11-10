extends SceneTree
# Mire and pits, plus blueprints, scrap and crafting.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const More = preload("res://src/more.gd")
const Lobby = preload("res://src/lobby.gd")
var g
var fails = 0
var vis = DisplayServer.get_name() != "headless"
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for i in n: await process_frame
func reach(from: Vector2i) -> Dictionary:
	# every tile a foe on foot can walk to
	var seen = {from: true}
	var q = [from]
	while not q.is_empty():
		var c = q.pop_back()
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n = c + dd
			if seen.has(n) or n.x < 0 or n.y < 0 or n.x >= g.dg.w or n.y >= g.dg.h:
				continue
			if g.dg.grid[n.y * g.dg.w + n.x] != 1 or g.dg.terr[n.y * g.dg.w + n.x] == 2:
				continue
			seen[n] = true
			q.append(n)
	return seen
func _init():
	Meta.PATH = "user://rebirth_terrain.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.goto_lobby()
	check(g.terr_at(g.p.pos) == 0, "the hub has no hazards")
	var mire_n = 0
	var pit_n = 0
	var pit_tile = null
	var mire_tile = null
	for seed in [3, 4, 5, 6, 7, 8]:
		g.start_run(seed, false)
		for fl in 6:
			g.floor_i = fl
			g.new_floor()
			var start = null
			for r in g.dg.rooms:
				if r.type == "start":
					start = r
			var seen = reach(Vector2i(start.center.x, start.rect.position.y))
			for r in g.dg.rooms:
				if r.type != "secret":
					check(seen.has(Vector2i(r.center.x, r.rect.position.y)) and seen.has(Vector2i(r.rect.position.x, r.center.y)), "seed %d floor %d: room %s must stay reachable on foot" % [seed, fl, r.type])
			for y in g.dg.h:
				for x in g.dg.w:
					var t = g.dg.terr[y * g.dg.w + x]
					if t == 1:
						mire_n += 1
						if seed == 8 and fl == 5: mire_tile = Vector2i(x, y)
					elif t == 2:
						pit_n += 1
						if seed == 8 and fl == 5 and g.dg.terr[y * g.dg.w + x - 1] == 0 and g.dg.grid[y * g.dg.w + x - 1] == 1: pit_tile = Vector2i(x, y)
			for pr in g.props:
				check(g.terr_at(pr.pos) == 0, "props stay off hazards")
			for tr in g.traps:
				check(g.terr_at(tr.pos) == 0, "traps stay off hazards")
	print("36 floors: mire tiles ", mire_n, " pit tiles ", pit_n)
	check(mire_n > 100 and pit_n > 50, "hazards should be common")
	# now on seed 8 floor 5: fall into a pit
	if pit_tile != null:
		var pp = Vector2(pit_tile) * 16.0 + Vector2(8, 8)
		g.p.safe = g.p.pos
		var home = g.p.pos
		var before = g.p.hp + g.p.ar
		g.p.inv = 0.0
		g.p.pos = pp
		await frames(2)
		check(g.p.pos.distance_to(home) < 2.0 and g.p.hp + g.p.ar == before - 1, "falling costs one point and puts you back")
		# a walker cannot enter, a flyer can
		var walker = g.spawn_enemy("goblin", pp + Vector2(-16, 0))
		var wp = walker.pos
		var blocked = g.move(walker, Vector2(16, 0)) if g.terr_at(pp + Vector2(-16, 0)) != 2 else true
		var bat = g.spawn_enemy("bat", pp + Vector2(-16, 0))
		g.move(bat, Vector2(16, 0))
		check(blocked and g.terr_at(walker.pos) != 2, "walkers stop at the edge of a pit")
		check(g.terr_at(bat.pos) == 2 or g.terr_at(pp + Vector2(-16, 0)) == 2, "flyers cross pits")
		g.enemies.clear()
		# dashing over is safe
		g.p.pos = pp
		g.p.dash_t = 0.3
		g.p.dash_dir = Vector2.ZERO
		var hp2 = g.p.hp + g.p.ar
		await frames(1)
		check(g.p.hp + g.p.ar == hp2, "a dash carries you over a pit")
	if mire_tile != null:
		g.p.dash_t = 0.0
		g.p.inv = 5.0
		var mp = Vector2(mire_tile) * 16.0 + Vector2(8, 8)
		g.p.pos = mp
		g.sim[KEY_D] = true
		await frames(1)
		var slow = g.p.v.length()
		g.sim.erase(KEY_D)
		check(slow > 20.0 and slow < 60.0, "mire should slow the hero (speed %s)" % slow)
	if vis:
		for r in g.dg.rooms:
			if r.type == "fight" and pit_tile != null and r.rect.has_point(pit_tile):
				g.p.pos = g.rc(r)
		g.p.inv = 9.0
		await frames(100)
		var im = root.get_texture().get_image()
		im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
		im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_terrain.png")
	# crafted weapons never drop as loot
	var leaked = false
	for i in 2000:
		if D.WEAPONS[g.random_weapon().id].get("bp", false):
			leaked = true
	check(not leaked, "blueprint weapons must not appear as random loot")
	# blueprint -> scrap -> bench
	check(More.bp_ids().size() == 6, "six blueprint weapons")
	More.drop_blueprint(g, g.p.pos)
	var bp = g.inter[-1]
	check(bp.kind == "blueprint", "a blueprint should drop")
	g.interact(bp)
	check(Meta.S.blueprints == [bp.id], "picking it up should keep it forever")
	var bench = {kind = "bench", pos = g.p.pos, used = false, name = "X", spr = "bench"}
	g.p.gold = 60
	g.interact(bench)
	check(bench.used and g.p.gold == 10 and g.inter[-1].kind == "weapon" and g.inter[-1].w.id == bp.id, "dungeon bench should build the weapon")
	for i in 30:
		g.kill(g.spawn_enemy("slime", g.p.pos))
	var e = g.spawn_enemy("slime", g.p.pos)
	e.elite = true
	g.kill(e)
	for k in g.pickups:
		k.t = 1.0
	g.p.pos = g.pickups[0].pos
	await frames(60)
	print("scrap after 31 kills: ", Meta.S.scrap)
	check(int(Meta.S.scrap) >= 3, "foes should drop scrap")
	Meta.S.scrap = 20
	g.end_run(false)
	g.goto_lobby()
	g.open_menu("bench")
	var row = null
	for r in g.menu.rows:
		if r.name == D.WEAPONS[bp.id].name:
			row = r
	check(row != null and row.state == "owned", "hub bench should list the known blueprint")
	Lobby.activate(g, row)
	check(int(Meta.S.scrap) == 5 and Meta.S.boons.get("weapon", "") == bp.id, "crafting packs the weapon for the next run")
	if vis:
		await frames(3)
		var im2 = root.get_texture().get_image()
		im2.resize(1440, 810, Image.INTERPOLATE_NEAREST)
		im2.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_bench.png")
	g.set_state("play")
	g.start_run(1, false)
	check(g.p.weapons[1] != null and g.p.weapons[1].id == bp.id, "the crafted weapon should be carried into the run")
	print("TERRAIN ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
