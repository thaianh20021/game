extends SceneTree
# Every biome has spikes plus its own trap; traps hurt heroes and foes and apply elements.
const Meta = preload("res://src/meta.gd")
const Traps = preload("res://src/traps.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for i in n: await process_frame
func _init():
	Meta.PATH = "user://rebirth_traps.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	g.goto_lobby()
	check(g.traps.is_empty(), "no traps in the hub")
	g.start_run(99, false)
	g.p.pet = null
	for fl in [0, 2, 4]:
		g.floor_i = fl
		g.new_floor()
		var kinds = {}
		for tr in g.traps:
			kinds[tr.kind] = kinds.get(tr.kind, 0) + 1
			check(g.dg.grid[int(tr.pos.y / 16) * g.dg.w + int(tr.pos.x / 16)] == 1, "trap must sit on floor")
		print("floor ", fl, " traps ", kinds)
		var own = Traps.OWN[fl / 2]
		check(kinds.has("spike") and kinds.has(own) and kinds.size() == 2, "biome %d should have spikes and %s only" % [fl / 2, own])
		# stand a hero and a foe on one trap of the biome's own kind through a full cycle
		var tr = null
		for q in g.traps:
			if q.kind == own:
				tr = q
				break
		var spot = tr.pos + (tr.dir * 20.0 if own == "flame" else Vector2(6, 0))
		var e = g.spawn_enemy("goblin", spot)
		e.mhp = 9999.0
		e.hp = 9999.0
		g.p.mhp = 50
		g.p.hp = 50
		g.p.mount = null
		g.p.relics = []
		var hit_hero = false
		var hit_foe = false
		var el_seen = false
		for i in 200:
			g.p.pos = spot
			e.pos = spot
			e.stun = 1.0
			g.p.inv = 0.0
			await process_frame
			if g.p.hp + g.p.ar < 50 + g.p.mar: hit_hero = true
			if hit_hero: g.p.hp = 50
			if e.hp < 9999.0: hit_foe = true
			if not e.st.is_empty(): el_seen = true
		check(hit_hero, own + " should hurt the hero")
		check(hit_foe, own + " should hurt foes")
		check(el_seen, own + " should apply its element to foes")
		check(g.state == "play", "run should still be going")
	check(Meta.S.tips.has("trap"), "first trap hit should show a hint")
	if DisplayServer.get_name() != "headless":
		for fl in [0, 2, 4]:
			g.floor_i = fl
			g.new_floor()
			for r in g.dg.rooms:
				if r.type == "fight":
					g.p.pos = g.rc(r)
					break
			g.p.hp = g.p.mhp
			for i in 140:
				g.p.inv = 1.0
				await process_frame
			var im = root.get_texture().get_image()
			im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
			im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_trap%d.png" % fl)
	print("TRAPS ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
