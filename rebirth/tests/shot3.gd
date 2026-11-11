extends SceneTree
# Screenshot of the element crystals in the Hearth and of a fight with the newest elements.
const Meta = preload("res://src/meta.gd")
const Lobby = preload("res://src/lobby.gd")
const OUT = "C:/Users/ADMIN/AppData/Local/Temp/"
var g

func shot(n):
	var im = root.get_texture().get_image()
	im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
	im.save_png(OUT + "rb_" + n + ".png")

func _initialize():
	Meta.PATH = "user://rebirth_shot3.json"
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 5: await process_frame
	g.goto_lobby()
	g.p.pos = Lobby.tp(8, 15)
	for i in 60: await process_frame
	shot("crystals")
	quit()
