extends SceneTree
const Meta = preload("res://src/meta.gd")
const Lobby = preload("res://src/lobby.gd")
const More = preload("res://src/more.gd")
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
	Meta.S.gems = 500
	Meta.S.heat_max = 2
	Meta.S.garden[0] = {kind = "bloom", left = 0}
	Meta.S.garden[1] = {kind = "vine", left = 1}
	g.goto_lobby()
	g.p.pos = Lobby.tp(20, 7)
	await frames(90)
	shot("m_lobby")
	g.open_menu("board")
	await frames(3)
	shot("m_board")
	g.open_menu("codex")
	await frames(3)
	shot("m_codex")
	g.set_state("play")
	g.start_run(12345, false)
	g.floor_i = 1
	g.new_floor()
	g.dg.boss_id = "queen"
	More.take_relic(g, "glass")
	More.take_relic(g, "compass")
	More.take_relic(g, "lens")
	g.p.active = {id = "bomb", n = 1}
	g.p.keys = 2
	g.p.weapons = [{id = "bow", el = "bolt", el2 = "", lv = 1}, {id = "wand", el = "fire", el2 = "", lv = 0}]
	for r in g.dg.rooms:
		if r.type == "boss":
			g.p.pos = g.rc(r) + Vector2(-30, 30)
	await frames(520)
	shot("m_queen")
	for nm in ["iron", "void"]:
		g.floor_i = 3
		g.new_floor()
		g.dg.boss_id = nm
		for r in g.dg.rooms:
			if r.type == "boss":
				g.p.pos = g.rc(r) + Vector2(-30, 30)
		await frames(420)
		shot("m_" + nm)
	quit(0)
