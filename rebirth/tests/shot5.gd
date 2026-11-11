extends SceneTree
# Phone-shaped screenshots of the lesson, the blessing cards and a fight with touch on.
# Run without --headless, e.g. --resolution 1400x630
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const OUT = "C:/Users/ADMIN/AppData/Local/Temp/"
var g
func shot(n):
	root.get_texture().get_image().save_png(OUT + "rb_new_" + n + ".png")
func _initialize():
	Meta.PATH = "user://rebirth_shot5.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 10: await process_frame
	g.tin.on = true
	g.goto_lobby()
	for i in 60: await process_frame
	shot("lesson")
	g.tut.i = 4
	for i in 5: await process_frame
	shot("lesson2")
	g.start_run(7, false)
	g.tin.on = true
	for r in g.dg.rooms:
		if r.type == "fight":
			g.p.pos = g.rc(r)
			break
	g.p.sat = [0.4, 1.0, 0.0]
	g.p.spent = [false, false, true]
	for i in 90: await process_frame
	shot("fight")
	g.buff_choices = [D.BUFFS[0], D.BUFFS[3], D.BUFFS[12]]
	g.set_state("buff")
	for i in 5: await process_frame
	shot("buff")
	g.buff_choices = [D.BUFFS[5], D.BUFFS[9], D.BUFFS[17]]
	for i in 5: await process_frame
	shot("buff2")
	quit()
