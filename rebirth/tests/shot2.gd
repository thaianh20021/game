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
	for i in n: await process_frame
func _init() -> void:
	Meta.PATH = "user://rebirth_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	g.sim["mouse"] = Vector2(300, 120)
	await frames(10)
	Meta.S.gems = 500
	Meta.S.codex = {"weapons": {"rail": true, "coil": true, "mortar": true, "bow": true, "blade": true}}
	Meta.S.stats = {"kills": 640, "reacts": 120}
	Meta.S.dyes = [2]
	Meta.S.dye = 2
	Meta.S.boons = {"hp": 1, "gold": 30}
	g.goto_lobby()
	g.set_local2(true)
	g.p.pos = Lobby.tp(15, 25)
	g.players[1].pos = Lobby.tp(13, 24)
	await frames(90)
	shot("h_wing")
	for k in ["quest", "trophy", "armory", "brew", "tailor"]:
		g.open_menu(k)
		await frames(3)
		shot("h_" + k)
	g.set_state("play")
	g.start_run(5, false)
	g.next_floor()
	g.pick_buff(0)
	await frames(3)
	shot("h_buff2")
	quit(0)
