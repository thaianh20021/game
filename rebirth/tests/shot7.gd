extends SceneTree
# Picture of the skill training menu at the lectern (run without --headless).
const Meta = preload("res://src/meta.gd")
const Lobby = preload("res://src/lobby.gd")
var g
func _initialize():
	Meta.PATH = "user://rebirth_shot7.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 10: await process_frame
	Meta.S.gems = 300
	Meta.S["tut"] = true
	g.goto_lobby()
	g.tin.on = true
	g.open_menu("spell")
	for k in [0, 0, 0, 1, 3, 6, 7]:
		Lobby.activate(g, g.menu.rows[k])
	g.menu.sel = 4
	for i in 10: await process_frame
	root.get_texture().get_image().save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_train.png")
	quit()
