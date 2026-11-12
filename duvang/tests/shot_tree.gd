extends SceneTree
# Run without --headless. Writes shots/8_tree.png, 8b_link.png and 9_skills.png.
const D = preload("res://src/data.gd")
var g

func shot(n: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + n + ".png"))

func _init() -> void:
	D.SAVE_PATH = "user://duvang_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await process_frame
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.lvl = 16
	g.qs["m6"] = "done"
	for id in ["spin", "bloodlust", "bloodlust", "bulwark", "lunge", "ember", "kindle", "ring", "spark", "stoke", "shatter", "charged"]:
		g.learn(id)
	var view = g.get_viewport_rect().size
	g.mode = "tree"
	g.tab = 1
	g.sim.ui_mouse = g.Ui.tree_cell(view, "spark").get_center()
	g.sim.mouse = g.p.pos + Vector2(40, 0)
	await shot("8_tree")
	g.tab = 2
	g.sim.ui_mouse = g.Ui.tree_cell(view, "shatter").get_center()
	await shot("8b_link")
	g.sim.no_spawns = true
	g.enter_zone("field", Vector2(34 * 16, 23 * 16))
	g.mode = "play"
	g.fresh_hero()
	g.p.rage = 100.0
	g.sim.mouse = g.p.pos + Vector2(60, 0)
	var fs = []
	for off in [Vector2(50, 0), Vector2(100, 24), Vector2(140, -20), Vector2(-40, 30)]:
		var f = g.spawn("reed", g.p.pos + off)
		f.cd = 99.0
		f.hp = 900.0
		f.mhp = 900.0
		fs.append(f)
	g.mark(fs[3], "burn")
	g.mark(fs[3], "chill")
	g.cast("spark")
	for i in 5:
		await process_frame
	await shot("9_skills")
	quit()
