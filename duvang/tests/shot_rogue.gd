extends SceneTree
# Run without --headless. Writes shots/28_rogue_tree.png, 29_rogue_link.png, 30_rogue.png, 31_second.png.
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
	g.sim.ui_mouse = Vector2(-50, -50)
	g.mode = "play"
	g.main_m = 3
	g.second_m = 0
	g.qs["m6"] = "done"
	g.lvl = 20
	for id in ["slash", "keen", "keen", "exec", "shadow", "backstab", "smoke", "venom", "potent", "darts", "spin", "bloodlust", "lunge", "lb_last", "lb_ring"]:
		g.learn(id)
	var view = g.get_viewport_rect().size
	g.mode = "tree"
	g.tab = 3
	g.sim.ui_mouse = g.Ui.tree_cell(view, "exec").get_center()
	g.sim.mouse = g.p.pos + Vector2(40, 0)
	await shot("28_rogue_tree")
	g.tab = 4
	g.sim.ui_mouse = g.Ui.tree_cell(view, "lb_twin").get_center()
	await shot("29_rogue_link")
	g.sim.ui_mouse = Vector2(-50, -50)
	g.sim.no_spawns = true
	g.mode = "play"
	g.enter_zone("field", Vector2(34 * 16, 23 * 16))
	g.fresh_hero()
	g.p.rage = 100.0
	g.p.cp = 4
	var fs = []
	for off in [Vector2(34, 0), Vector2(70, 26), Vector2(-50, 20), Vector2(90, -24)]:
		var f = g.spawn("reed", g.p.pos + off)
		f.cd = 99.0
		f.hp = 4000.0
		f.mhp = 4000.0
		f.flip = false
		fs.append(f)
	g.poison(fs[0], 4)
	g.poison(fs[1], 2)
	g.mark(fs[1], "chill")
	g.sim.mouse = fs[0].pos
	g.cast("venom")
	g.cast("darts")
	for i in 8:
		await process_frame
	await shot("30_rogue")
	D.MENUS = 1
	g.main_m = 0
	g.Menu.open(g, "second")
	g.csel = 3
	g.msel = 3
	await shot("31_second")
	quit()
