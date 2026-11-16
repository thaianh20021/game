extends SceneTree
# Picture of the first room of the Training Grounds (run without --headless).
const Meta = preload("res://src/meta.gd")
const Drill = preload("res://src/drill.gd")
var g
func frames(n):
	for k in n: await process_frame
func _initialize():
	Meta.PATH = "user://rebirth_shot14.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(10)
	Meta.S.pet = ""
	Meta.S["tut"] = true
	g.tin.on = true
	g.sim["zoom"] = true
	Drill.start(g)
	g.fit()
	await frames(10)
	var r = g.dg.rooms.filter(func(q): return q.type == "fight")[0]
	g.p.pos = g.rc(r)
	g.p.inv = 99.0
	await frames(140)
	g.p.inf = [{key = "fire+ice", col = Color("d8f6ff")}]
	g.p.inf_t = 8.0
	g.banner.t = 0.0
	await frames(5)
	root.get_texture().get_image().save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_drill.png")
	quit()
