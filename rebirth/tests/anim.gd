extends SceneTree
# Pose frames exist for every hero and foe; frame choice follows what the actor is doing.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Art = preload("res://src/art.gd")
var g
var fails = 0
var vis = DisplayServer.get_name() != "headless"
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for i in n:
		g.p.hp = g.p.mhp
		g.p.inv = 1.0
		await process_frame
func shot(n):
	if vis:
		var im = root.get_texture().get_image()
		im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
		im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_" + n + ".png")
func _init():
	Meta.PATH = "user://rebirth_anim.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 5: await process_frame
	for h in D.HEROES:
		for suf in Art.SUF:
			check(Art.T.has("h_" + h.id + suf), "hero frame h_%s%s" % [h.id, suf])
		check(Art.I["h_" + h.id + "_b"].get_data() != Art.I["h_" + h.id].get_data(), h.id + " breathe frame differs")
		check(Art.I["h_" + h.id + "_l"].get_data() != Art.I["h_" + h.id].get_data(), h.id + " lean frame differs")
	check(Art.bad_rows.is_empty(), "hand-drawn rows must keep their length: " + str(Art.bad_rows))
	var Frames = load("res://src/frames.gd")
	print("hand-drawn sprites: ", Frames.HAND.size())
	if vis:
		# contact sheet: base, wind-up, attack for every hand-drawn sprite
		var sheet = Image.create_empty(1500, 860, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("2a2438"))
		var x = 6
		var y = 6
		var rowh = 0
		var names = []
		for h in D.HEROES:
			names.append("h_" + h.id)
		for id in D.ENEMIES:
			if id != "dummy" and not D.ENEMIES[id].has("swap"):
				names.append("e_" + id)
		for n in names:
			var sc = 3 if Art.I[n].get_width() > 20 else 4
			if x + Art.I[n].get_width() * sc * 3 + 30 > 1490:
				x = 6
				y += rowh + 10
				rowh = 0
			for suf in ["", "_b", "_l"]:
				var im: Image = Art.I[n + suf].duplicate()
				im.resize(im.get_width() * sc, im.get_height() * sc, Image.INTERPOLATE_NEAREST)
				sheet.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(x, y))
				x += im.get_width() + 4
				rowh = max(rowh, im.get_height())
			x += 18
		sheet.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_frames.png")
	for id in D.ENEMIES:
		check(Art.T.has("e_" + id + "_b") and Art.T.has("e_" + id + "_l"), "foe frames for " + id)
	# fused, woven and dyed heroes get the full set too
	Meta.S.gen_seed = 4242
	Meta.S.fuse_unlocked = true
	Meta.S.hero = D.HEROES.size()
	Meta.S.fuse = 2
	Meta.S.dye = 1
	Meta.S.dyes = [1]
	g.goto_lobby()
	for suf in Art.SUF:
		check(Art.T.has(g.p.spr + suf), "built hero frame " + g.p.spr + suf)
	Meta.S.hero = 0
	Meta.S.fuse = -1
	Meta.S.dye = -1
	Meta.S.pet = ""
	g.start_run(9, false)
	# spawn-in, attack pose, death echo
	var e = g.spawn_enemy("goblin", g.p.pos + Vector2(60, 0))
	check(e.born > 0.0, "new foes rise in")
	await frames(12)
	check(e.born == 0.0, "the rise ends")
	e.t = 0.0
	var posed = false
	for i in 40:
		if e.atk_t > 0.0:
			posed = true
		await frames(1)
	check(posed, "a shooter strikes a pose when it fires")
	g.sim["mouse"] = Vector2(360, 135)
	g.sim["fire"] = true
	g.sim[KEY_D] = true
	await frames(6)
	shot("anim1")
	g.sim.erase(KEY_D)
	g.sim.erase("fire")
	var n0 = g.echoes.size()
	g.kill(e)
	check(g.echoes.size() == n0 + 1 and g.echoes[-1].squash, "a dying foe leaves a squashing echo")
	await frames(15)
	check(g.echoes.is_empty(), "echoes fade")
	# decor is baked into dungeon floors but not the hub
	var img: Image = g.ground.texture.get_image()
	check(img.get_width() > 100, "floor baked")
	if vis:
		for fl in [0, 2, 4]:
			g.floor_i = fl
			g.new_floor()
			for r in g.dg.rooms:
				if r.type == "fight":
					g.p.pos = g.rc(r) + Vector2(0, 20)
					break
			g.sim["fire"] = true
			for i in 110:
				if not g.enemies.is_empty():
					g.sim["mouse"] = g.center(g.enemies[0]) - g.cam_tl
				await frames(1)
			shot("anim_b%d" % fl)
	print("ANIM ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
