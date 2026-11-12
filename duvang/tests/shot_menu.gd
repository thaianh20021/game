extends SceneTree
# Run without --headless. Writes shots/20_title.png, 21_create.png, 22_story.png, 23_pause.png, 24_settings.png, 25_journal.png, 26_mage.png.
const D = preload("res://src/data.gd")
var g

func shot(n: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + n + ".png"))

func _init() -> void:
	D.SAVE_PATH = "user://duvang_shot.json"
	D.MENUS = 1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH.replace(".json", "_opt.json")))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await process_frame
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.sim.ui_mouse = Vector2(-50, -50)
	g.sim.mouse = g.p.pos + Vector2(40, 0)
	g.has_save = true
	await shot("20_title")
	g.mode = "create"
	g.csel = 1
	g.msel = 1
	await shot("21_create")
	g.start_new(1)
	await shot("22_story")
	g.mode = "play"
	g.lvl = 12
	for id in ["m1", "m2", "m3", "m4", "m5", "m6", "m7"]:
		g.qs[id] = "done"
	g.qs["m8"] = "active"
	g.qc["m8"] = {}
	g.Menu.open(g, "pause")
	g.msel = 3
	await shot("23_pause")
	g.menu_back = "pause"
	g.Menu.open(g, "settings")
	g.msel = 2
	await shot("24_settings")
	g.mode = "journal"
	await shot("25_journal")
	g.mode = "play"
	for id in ["ember", "kindle", "firewall", "ring", "deep", "shard", "spark", "static", "cage", "tam"]:
		g.learn(id)
	g.sim.no_spawns = true
	g.enter_zone("field", Vector2(34 * 16, 23 * 16))
	g.fresh_hero()
	g.p.rage = 100.0
	g.p.aim = Vector2.RIGHT
	for off in [Vector2(46, 14), Vector2(46, -20), Vector2(120, 10), Vector2(140, -30), Vector2(-70, 30)]:
		var f = g.spawn("reed", g.p.pos + off)
		f.cd = 99.0
		f.hp = 4000.0
		f.mhp = 4000.0
	g.sim.mouse = g.p.pos + Vector2(130, -10)
	g.cast("firewall")
	g.cast("cage")
	for i in 40:
		await process_frame
	g.cast("tam")
	for i in 34:
		await process_frame
	await shot("26_mage")
	g.mode = "tree"
	g.tab = 1
	g.sim.ui_mouse = g.Ui.tree_cell(g.get_viewport_rect().size, "tam").get_center()
	await shot("27_mage_tree")
	quit()
