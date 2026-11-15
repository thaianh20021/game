extends SceneTree
# Pictures of the ten release effects, and of the phone view (bigger buttons, closer camera).
# Run without --headless.
const Meta = preload("res://src/meta.gd")
var g
func frames(n):
	for k in n: await process_frame
func _initialize():
	Meta.PATH = "user://rebirth_shot10.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(10)
	Meta.S.pet = ""
	Meta.S["tut"] = true
	g.start_run(5, false)
	await frames(60)
	var room = null
	for r in g.dg.rooms:
		if r.type == "fight":
			room = r
			break
	room.cleared = true
	var c: Vector2 = g.rc(room)
	g.p.pos = c
	g.enemies.clear()
	g.banner.t = 0.0
	await frames(5)
	var ks = g.Pfx.DUR.keys()
	for part in [0.25, 0.55]:
		g.pfx.clear()
		for i in ks.size():
			g.Pfx.spawn(g, ks[i], c + Vector2(-150 + (i % 5) * 75, -40 + (i / 5) * 80), 30.0, 0.4)
			g.pfx[i].t = g.Pfx.DUR[ks[i]] * part
		g.p.pos = c + Vector2(0, 100)
		g.cam = c
		await frames(1)
		var im: Image = root.get_texture().get_image()
		var mid = Vector2i(im.get_width() / 2, im.get_height() / 2)
		im = im.get_region(Rect2i(mid.x - 200, mid.y - 90, 400, 180))
		im.resize(1200, 540, Image.INTERPOLATE_NEAREST)
		im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_pfx_%d.png" % int(part * 100))
	g.pfx.clear()
	# the phone view
	g.sim["zoom"] = true
	g.tin.on = true
	g.fit()
	g.p.pos = c
	for i in 3:
		var e = g.spawn_enemy("goblin", c + Vector2(40 + i * 24, -20 + i * 18))
		e.born = 0.0
		e.stun = 99.0
	g.p.inf = [{key = "fire+ice", col = Color("d8f6ff")}, {key = "fire+ice", col = Color("d8f6ff")}]
	await frames(20)
	root.get_texture().get_image().save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_phone.png")
	quit()
