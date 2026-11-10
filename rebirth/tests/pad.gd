extends SceneTree
const Meta = preload("res://src/meta.gd")
const Pad = preload("res://src/pad.gd")
var g
func shot(n):
	var im = root.get_texture().get_image()
	im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
	im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_" + n + ".png")
func btn(dev, b):
	var ev = InputEventJoypadButton.new()
	ev.device = dev
	ev.button_index = b
	ev.pressed = true
	g._input(ev)
func _init():
	Meta.PATH = "user://rebirth_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await create_timer(0.8).timeout
	print("connected pads: ", Input.get_connected_joypads())
	btn(0, JOY_BUTTON_A)
	await create_timer(0.5).timeout
	print("A on title -> lobby=", g.in_lobby, " pad_used=", g.pad_used)
	var r = Pad.read(g, g.p, 0)
	print("read ok mv=", r.mv, " fire=", r.fire)
	g.open_menu("coop")
	await create_timer(0.4).timeout
	if DisplayServer.get_name() != "headless": shot("c_menu")
	btn(0, JOY_BUTTON_DPAD_DOWN)
	await process_frame
	await process_frame
	print("dpad down in menu -> sel=", g.menu.sel)
	btn(0, JOY_BUTTON_B)
	await process_frame
	await process_frame
	print("B closes menu -> state=", g.state)
	g.set_local2(true)
	g.start_run(777, false)
	g.sim_p2 = {mv = Vector2.ZERO, mw = Vector2.ZERO, fire = false, jp = {}}
	for rm in g.dg.rooms:
		if rm.type == "fight":
			g.players[0].pos = g.rc(rm) + Vector2(-20, 20)
			break
	for i in 100:
		g.players[0].hp = g.players[0].mhp
		g.players[1].hp = g.players[1].mhp
		g.sim_p2 = {mv = Vector2(0.4, -0.2) if i < 40 else Vector2.ZERO, mw = g.center(g.enemies[0]) if not g.enemies.is_empty() else g.players[1].pos + Vector2(50, 0), fire = true, jp = {}}
		g.sim["fire"] = true
		if not g.enemies.is_empty(): g.sim["mouse"] = g.center(g.enemies[-1]) - g.cam_tl
		await process_frame
	if DisplayServer.get_name() != "headless": shot("c_play")
	btn(0, JOY_BUTTON_START)
	await process_frame
	await process_frame
	print("START in play -> state=", g.state)
	quit(0)
