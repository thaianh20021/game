extends SceneTree
# Picture of the end-of-run screen with the charged-weapon tally (run without --headless).
const Meta = preload("res://src/meta.gd")
var g
func frames(n):
	for k in n: await process_frame
func _initialize():
	Meta.PATH = "user://rebirth_shot12.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(10)
	Meta.S.pet = ""
	Meta.S["tut"] = true
	g.start_run(5, false)
	await frames(20)
	g.rs = {rel = 23, pure = 4, trinity = 2, perf = 3, chain = 6, slam = 9, obj = 2, new = 7}
	g.kills = 143
	g.end_run(false)
	await frames(50)
	root.get_texture().get_image().save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_end.png")
	quit()
