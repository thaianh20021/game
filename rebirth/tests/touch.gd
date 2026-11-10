extends SceneTree
const Meta = preload("res://src/meta.gd")
var g
func touch(i, pos, down):
	var ev = InputEventScreenTouch.new()
	ev.index = i
	ev.position = pos
	ev.pressed = down
	g._input(ev)
func drag(i, pos):
	var ev = InputEventScreenDrag.new()
	ev.index = i
	ev.position = pos
	g._input(ev)
func frames(n):
	for k in n: await process_frame
func _init() -> void:
	Meta.PATH = "user://rebirth_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	touch(0, Vector2(240, 200), true)
	touch(0, Vector2(240, 200), false)
	await frames(30)
	print("after title tap: lobby=", g.in_lobby, " touch_on=", g.tin.on)
	g.start_run(4242, false)
	await frames(10)
	var x0 = g.p.pos.x
	touch(0, Vector2(60, 200), true)
	drag(0, Vector2(90, 200))
	await frames(40)
	print("moved right by ", snapped(g.p.pos.x - x0, 0.1))
	g.spawn_enemy("slime", g.p.pos + Vector2(60, -30))
	touch(1, Vector2(410, 208), true)
	await frames(30)
	print("auto-aim fired bullets=", g.bullets.size(), " aim=", g.p.aim.snapped(Vector2(0.01, 0.01)))
	drag(1, Vector2(410, 180))
	await frames(5)
	print("manual aim=", g.p.aim.snapped(Vector2(0.01, 0.01)))
	var cd = g.p.dash_cd
	touch(2, Vector2(458, 150), true)
	await frames(2)
	print("dash pressed: dash_cd ", cd, " -> ", snapped(g.p.dash_cd, 0.01))
	touch(2, Vector2(458, 150), false)
	touch(3, Vector2(240, 12), true)
	await frames(2)
	print("pause tap -> state=", g.state)
	if DisplayServer.get_name() != "headless":
		g.set_state("play")
		await frames(3)
		var im = root.get_texture().get_image()
		im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
		im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_touch.png")
	quit(0)
