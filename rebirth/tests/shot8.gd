extends SceneTree
# Pictures of charged-dash releases (run without --headless): one per weapon shape and pair.
const Meta = preload("res://src/meta.gd")
var g
func frames(n):
	for k in n: await process_frame
func _initialize():
	Meta.PATH = "user://rebirth_shot8.json"
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
	var shots = [["blade", "fire+water", 3], ["blade", "bolt+ice", 1], ["beam", "light+void", 2], ["pistol", "leaf+metal", 3], ["blade", "stone+wind", 2], ["blade", "mech+tox", 3]]
	for i in shots.size():
		var sh = shots[i]
		g.enemies.clear()
		g.fields.clear()
		g.bullets.clear()
		g.banner.t = 0.0
		g.p.weapons[g.p.wi] = {id = sh[0], el = "fire", el2 = "", lv = 0}
		g.p.pos = c + Vector2(-50, 0)
		for k in 5:
			var e = g.spawn_enemy("goblin", c + Vector2(10 + (k % 3) * 22, -24 + (k / 3) * 40 + (k % 2) * 10))
			e.mhp = 9999.0
			e.hp = 9999.0
			e.born = 0.0
			e.stun = 99.0
		g.p.inf = []
		for k in sh[2]:
			g.infuse(sh[1], g.D.REACT[sh[1]][1])
		await frames(8)
		if i == 0:
			root.get_texture().get_image().save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_inf_charged.png")
		g.p.dash_cd = 0.0
		g.sim[KEY_D] = true
		for n in 12:
			g.jp[KEY_SPACE] = true
			await frames(1)
			if g.p.dash_t > 0.0:
				break
		g.sim.erase(KEY_D)
		while g.p.dash_t > 0.0:
			await frames(1)
		g.hitstop = 0.0
		for fr in [3, 9]:
			await frames(3 if fr == 3 else 6)
			g.banner.t = 0.0
			g.nums.clear()
			await frames(1)
			var im: Image = root.get_texture().get_image()
			var sp: Vector2 = g.p.pos - g.cam_tl
			var zz = im.get_width() / 480.0
			g.nums.clear()
			im = im.get_region(Rect2i(int(sp.x) - 110, int(sp.y) - 75, 220, 150))
			im.resize(660, 450, Image.INTERPOLATE_NEAREST)
			im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_inf_%d_%d.png" % [i, fr])
		await frames(20)
	quit()
