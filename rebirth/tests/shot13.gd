extends SceneTree
# Pictures of item cards and of the screen at its own resolution (run without --headless).
const Meta = preload("res://src/meta.gd")
var g
func frames(n):
	for k in n: await process_frame
func _initialize():
	Meta.PATH = "user://rebirth_shot13.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(10)
	Meta.S.pet = ""
	Meta.S["tut"] = true
	g.start_run(5, false)
	g.sim["zoom"] = true
	g.tin.on = true
	g.fit()
	await frames(60)
	g.banner.t = 0.0
	var at: Vector2 = g.p.pos + Vector2(10, 0)
	var items = [
		{kind = "weapon", pos = at, w = {"id": "rail", "el": "bolt", "el2": "", "lv": 2, "trait": "pierce"}},
		{kind = "relic", pos = at, id = "eye"},
		{kind = "weapon", pos = at, w = {id = "axe", el = "ice", el2 = "fire", lv = 0}},
	]
	for i in items.size():
		g.inter = g.inter.filter(func(q): return not q.has("shot"))
		items[i].shot = true
		g.inter.append(items[i])
		await frames(8)
		print("size ", root.get_texture().get_size(), " near ", g.near.kind if g.near != null else "none")
		root.get_texture().get_image().save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_card_%d.png" % i)
	quit()
