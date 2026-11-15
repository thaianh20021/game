extends SceneTree
# Pictures of objectives, affix marks and boss armor (run without --headless).
const Meta = preload("res://src/meta.gd")
const Stage = preload("res://src/stage.gd")
var g
func frames(n):
	for k in n: await process_frame
func snap(name):
	g.banner.t = 0.0
	g.p.hp = g.p.mhp
	g.p.inv = 9.0
	await frames(2)
	var im: Image = root.get_texture().get_image()
	var sp: Vector2 = g.p.pos - g.cam_tl
	im = im.get_region(Rect2i(clampi(int(sp.x) - 150, 0, im.get_width() - 300), clampi(int(sp.y) - 105, 0, im.get_height() - 190), 300, 190))
	im.resize(900, 570, Image.INTERPOLATE_NEAREST)
	im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_stage_%s.png" % name)
func _initialize():
	Meta.PATH = "user://rebirth_shot9.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(10)
	Meta.S.pet = ""
	Meta.S["tut"] = true
	for k in ["ward", "leech", "mark", "brood", "armor", "inf", "react", "chain", "perf"]:
		Meta.S.tips[k] = true
	g.start_run(5, false)
	g.floor_i = 2
	g.new_floor()
	await frames(60)
	var r = null
	for q in g.dg.rooms:
		if q.type == "fight":
			r = q
			break
	r.trial = true
	for k in 200:
		Stage.lock_room(g, r)
		g.timers.clear()
		g.teles.clear()
		g.pending = 0
		if r.sc == "hold":
			break
	g.lock = r
	r.wave = 1
	r.prog = 5.0
	var c: Vector2 = g.rc(r)
	g.p.pos = c + Vector2(0, 14)
	g.enemies.clear()
	var ks = ["ward", "leech", "mark", "brood"]
	for i in 4:
		var e = g.spawn_enemy("goblin", c + Vector2(-66 + i * 44, 50))
		e.born = 0.0
		e.stun = 99.0
		e.t = 99.0
		Stage.affix(g, e, ks[i])
		if ks[i] == "mark":
			e.aim = (g.p.pos - e.pos).normalized()
			e.aim_t = 0.2
			e.stun = 0.0
	var cr = g.spawn_enemy("goblin", c + Vector2(70, 14))
	cr.born = 0.0
	cr.stun = 99.0
	cr.courier = true
	await frames(3)
	await snap("hold")
	g.enemies.clear()
	g.lock = null
	var b = g.spawn_enemy(g.dg.boss_id, c + Vector2(0, -30))
	b.born = 0.0
	b.stun = 99.0
	g.boss = b
	g.hurt_enemy(b, 1.0, "")
	g.rel_hit = true
	g.hurt_enemy(b, 1.0, "", Vector2.ZERO, true)
	g.rel_hit = false
	g.nums.clear()
	await frames(3)
	await snap("armor")
	quit()
