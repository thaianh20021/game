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
			if not g.enemies.is_empty():
				g.sim["mouse"] = g.center(g.enemies[0]) - g.cam_tl
		await process_frame
func goto_room(type):
	for r in g.dg.rooms:
		if r.type == type:
			g.p.pos = g.rc(r) + Vector2(-24, 26)
			return r
	return null
func _init() -> void:
	Meta.PATH = "user://rebirth_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	g.sim["mouse"] = Vector2(300, 120)
	await frames(50)
	shot("title")
	Meta.S.gems = 400
	Meta.S.mount = "boar"
	Meta.S.mounts = ["boar"]
	g.goto_lobby()
	await frames(70)
	shot("lobby")
	g.p.pos = Lobby.tp(24, 14)
	await frames(40)
	shot("lobby2")
	g.open_menu("tree")
	Lobby.activate(g, g.menu.rows[0])
	Lobby.activate(g, g.menu.rows[3])
	g.menu.sel = 1
	await frames(3)
	shot("tree")
	g.open_menu("beast")
	await frames(3)
	shot("beast")
	Meta.S.fuse_unlocked = true
	Meta.S.fuse = 1
	g.open_menu("fuse")
	await frames(3)
	shot("fuse")
	g.set_state("play")
	g.start_run()
	g.floor_i = 2
	g.new_floor()
	g.p.gold = 80
	g.p.weapons = [{id = "blade", el = "fire", el2 = "ice", lv = 2}, {id = "coil", el = "bolt", el2 = "", lv = 0}]
	goto_room("workshop")
	await frames(50)
	shot("workshop")
	goto_room("fight")
	await frames(70)
	g.sim["fire"] = true
	await frames(50)
	g.p.res = 1.0
	g.jp[KEY_F] = true
	await frames(12)
	shot("fight")
	g.floor_i = 1
	g.new_floor()
	g.dg.boss_id = "queen"
	goto_room("boss")
	await frames(420)
	g.jp[KEY_R] = true
	await frames(8)
	shot("queen")
	g.floor_i = 3
	g.new_floor()
	g.dg.boss_id = "iron"
	goto_room("boss")
	await frames(520)
	shot("iron")
	g.set_state("pause")
	await frames(3)
	shot("pause")
	quit(0)
