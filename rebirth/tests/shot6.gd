extends SceneTree
# Picture of the mana pools, the element aura and a gathered cast (run without --headless).
const Meta = preload("res://src/meta.gd")
const OUT = "C:/Users/ADMIN/AppData/Local/Temp/"
var g
func _initialize():
	Meta.PATH = "user://rebirth_shot6.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 10: await process_frame
	g.start_run(7, false)
	g.tin.on = true
	for r in g.dg.rooms:
		if r.type == "fight":
			g.p.pos = g.rc(r)
			break
	for i in 60: await process_frame
	g.p.sat = [0.55, 1.0, 0.0]
	g.p.spent = [false, false, true]
	g.mana_total(g.p)
	g.sim.elh = true
	for i in 22: await process_frame
	root.get_texture().get_image().save_png(OUT + "rb_mana.png")
	quit()
