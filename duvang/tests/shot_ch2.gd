extends SceneTree
# Run without --headless. Writes shots/16_forest.png, 17_village.png, 18_heart.png, 19_mother.png.
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
	g.lvl = 14
	for id in ["m1", "m2", "m3", "m4", "m5", "m6", "m7"]:
		g.qs[id] = "done"
	g.qs["m8"] = "active"
	g.qc["m8"] = {"wolf": 2}
	g.qs["s3"] = "active"
	g.qc["s3"] = {}
	g.recompute()
	g.enter_zone("forest", Vector2(22 * 16, 17 * 16))
	g.mode = "play"
	g.fresh_hero()
	g.sim.mouse = g.p.pos + Vector2(10, -40)
	await frames(30)
	await shot("17_village")
	g.p.pos = Vector2(50 * 16, 27 * 16)
	g.cam = g.p.pos
	g.sim.mouse = g.p.pos + Vector2(60, 10)
	for i in 500:
		g.p.hp = g.stats.mhp
		await process_frame
		if g.foes.filter(func(f): return f.state == "wind" and f.pos.distance_to(g.p.pos) < 200.0).size() >= 2 or (i > 200 and not g.clouds.is_empty()):
			break
	await shot("16_forest")
	g.qs["m10"] = "active"
	g.qc["m10"] = {}
	g.flags["seen_bell"] = 1
	g.enter_zone("heart", Vector2(45 * 16, 17.5 * 16))
	g.mode = "play"
	g.sim.mouse = g.p.pos + Vector2(60, 0)
	await frames(60)
	await shot("18_heart")
	g.p.pos = Vector2(74 * 16, 20 * 16)
	g.cam = g.p.pos
	for f in g.foes:
		if f.kind == "mother":
			f.hp = f.mhp * 0.45
			f.n = 0
			f.state = "chase"
			f.cd = 0.0
			g.sim.mouse = f.pos
	for i in 300:
		g.p.hp = g.stats.mhp
		await process_frame
		if g.foes.any(func(f): return f.kind == "mother" and f.state == "wind" and f.st > 0.6):
			break
	await shot("19_mother")
	quit()
