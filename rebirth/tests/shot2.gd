extends SceneTree
const Meta = preload("res://src/meta.gd")
const Lobby = preload("res://src/lobby.gd")
const OUT = "C:/Users/ADMIN/AppData/Local/Temp/"
var g
func shot(n):
	var im = root.get_texture().get_image()
	im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
	im.save_png(OUT + "rb_" + n + ".png")
func frames(n):
	for i in n:
		if g.state == "play" and not g.in_lobby:
			g.p.hp = g.p.mhp
		await process_frame
func _init() -> void:
	Meta.PATH = "user://rebirth_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	g.sim["mouse"] = Vector2(300, 120)
	await frames(10)
	g.goto_lobby()
	g.p.pos = Lobby.tp(15, 11)
	await frames(200)
	shot("n_hall")
	g.p.pos = Lobby.tp(15, 25)
	await frames(60)
	shot("n_wing")
	g.start_run(77, false)
	g.floor_i = 3
	g.new_floor()
	for r in g.dg.rooms:
		if r.type == "fight":
			g.p.pos = g.rc(r) + Vector2(0, 30)
			break
	g.sim["fire"] = true
	for i in 260:
		if not g.enemies.is_empty():
			g.sim["mouse"] = g.center(g.enemies[0]) - g.cam_tl
		await frames(1)
	shot("n_fight")
	quit(0)
