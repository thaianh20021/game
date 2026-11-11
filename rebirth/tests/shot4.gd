extends SceneTree
# Wide-screen check: run without --headless and with a phone-shaped window, e.g.
#   --resolution 1400x630
# Saves the title, the Hearth and a fight with touch controls on.
const Meta = preload("res://src/meta.gd")
const OUT = "C:/Users/ADMIN/AppData/Local/Temp/"
var g

func shot(n):
	root.get_texture().get_image().save_png(OUT + "rb_wide_" + n + ".png")

func _initialize():
	Meta.PATH = "user://rebirth_shot4.json"
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 20: await process_frame
	print("view ", g.VW, "x", g.VH, " off ", g.hud_off)
	shot("title")
	g.goto_lobby()
	for i in 60: await process_frame
	shot("lobby")
	g.start_run(7, false)
	g.tin.on = true
	for r in g.dg.rooms:
		if r.type == "fight":
			g.p.pos = g.rc(r)
			break
	for i in 100: await process_frame
	shot("fight")
	g.state = "pause"
	for i in 5: await process_frame
	shot("pause")
	quit()
