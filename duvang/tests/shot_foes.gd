extends SceneTree
# Run without --headless. Writes shots/10_market.png, 11_keeper.png, 12_lofts.png.
const D = preload("res://src/data.gd")
var g

func shot(n: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + n + ".png"))

func frames(n: int) -> void:
	for i in n:
		g.p.hp = g.stats.mhp
		await process_frame

func _init() -> void:
	D.SAVE_PATH = "user://duvang_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await process_frame
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.lvl = 8
	g.qs = {"m1": "done", "m2": "done", "m3": "done", "m4": "done", "m5": "active"}
	g.qc = {"m5": {}}
	g.flags["seen_van"] = 1
	g.recompute()
	g.enter_zone("dungeon", Vector2(40.5 * 16, 17.5 * 16))
	g.mode = "play"
	g.fresh_hero()
	g.sim.mouse = g.p.pos + Vector2(40, -20)
	for i in 400:
		g.p.hp = g.stats.mhp
		await process_frame
		if g.foes.filter(func(f): return f.state == "wind" and f.pos.distance_to(g.p.pos) < 160.0).size() >= 2:
			break
	await shot("10_market")
	g.p.pos = Vector2(57 * 16, 15.8 * 16)
	g.cam = g.p.pos
	for f in g.foes:
		if f.kind == "keeper":
			f.hp = f.mhp * 0.6
			f.n = 2
			f.state = "chase"
			f.cd = 0.0
			g.sim.mouse = f.pos
	for i in 300:
		g.p.hp = g.stats.mhp
		await process_frame
		if g.foes.any(func(f): return f.kind == "keeper" and f.state == "wind" and f.st > 1.0):
			break
	await shot("11_keeper")
	g.p.pos = Vector2(79 * 16, 16 * 16)
	g.cam = g.p.pos
	g.sim.mouse = g.p.pos + Vector2(40, -20)
	await frames(50)
	await shot("12_lofts")
	quit()
