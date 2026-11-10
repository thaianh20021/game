extends SceneTree
# Charged specials of ordinary foes, the third boss of each biome, fused weapon art.
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
func shot(n):
	if vis:
		var im = root.get_texture().get_image()
		im.resize(1440, 810, Image.INTERPOLATE_NEAREST)
		im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_" + n + ".png")
func step(n = 1):
	for i in n:
		if g.state == "play":
			g.p.hp = g.p.mhp
			g.p.en = float(g.p.men)
			if not g.enemies.is_empty():
				g.sim["mouse"] = g.center(g.enemies[0]) - g.cam_tl
		await process_frame
func _init():
	Meta.PATH = "user://rebirth_foes.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await step(5)
	g.goto_lobby()
	g.start_run(31, false)
	g.p.pet = null
	# every ordinary foe with a charged move releases it
	var room = null
	for r in g.dg.rooms:
		if r.type == "start":
			room = r
	var c = g.rc(room)
	var shot_done = false
	for id in ["slime", "bat", "goblin", "shroom", "boar", "turret", "shade", "necro", "skel"]:
		g.enemies.clear()
		g.bullets.clear()
		g.p.pos = c + Vector2(-30, 0)
		var e = g.spawn_enemy(id, c + Vector2(30, 0))
		e.mhp = 99999.0
		e.hp = 99999.0
		e.sp_t = 0.1
		e.sp_c = 0.0
		e.sp_n = 0
		var charged = false
		for i in 90:
			g.p.pos = c + Vector2(-30, 0)
			if e.sp_c > 0.0:
				charged = true
				if not shot_done and e.sp_c < 0.4 and id == "goblin":
					shot("f_charge")
					shot_done = true
			await step(1)
		check(charged and e.sp_n >= 1, id + " should charge and release its special")
	g.enemies.clear()
	g.bullets.clear()
	# fused weapon texture
	var fw = {id = "greatblade", el = "fire", el2 = "ice", lv = 3}
	check(Art.T.has(Art.wtex(fw)) and Art.wtex(fw) != Art.wtex({id = "greatblade", el = "fire", el2 = "", lv = 0}), "fused weapons should have their own sprite")
	for id in D.WEAPONS:
		check(Art.T.has(Art.wtex({id = id, el = "bolt", el2 = ""})), "weapon sprite for " + id)
	# the three new bosses can be fought and beaten
	for bid in ["rootking", "wyrm", "sentinel"]:
		g.floor_i = D.ENEMIES[bid].boss % 3 * 2 + 1
		g.new_floor()
		g.dg.boss_id = bid
		g.p.weapons = [fw, {id = "rail", el = "bolt", el2 = "", lv = 2}]
		g.sim["fire"] = true
		var br = null
		for r in g.dg.rooms:
			if r.type == "boss":
				br = r
		g.p.pos = g.rc(br) + Vector2(0, 40)
		var used = {}
		var raged = false
		var n = 0
		while not br.cleared and n < 4500 and g.state == "play":
			if g.boss != null:
				used[g.boss.atk] = true
				raged = raged or g.boss.get("raged", false)
				if n % 50 == 0:
					for off in [Vector2(0, 46), Vector2(46, 0), Vector2(-46, 0)]:
						if g.box_free(g.boss.pos + off, 4.0):
							g.p.pos = g.boss.pos + off
							break
				if n == 330:
					shot("f_" + bid)
				if n % 3 == 0:
					g.p.wi = 1 - g.p.wi
			await step(1)
			n += 1
		print("   boss=", (str(snapped(g.boss.hp, 1.0)) + " state=" + g.boss.state + " t=" + str(snapped(g.boss.t, 0.1))) if g.boss != null else "none", " enemies=", g.enemies.map(func(e): return e.id), " pending=", g.pending, " state=", g.state, " p=", g.p.pos, " lock=", g.lock != null, " en=", g.p.en)
		print(bid, ": cleared=", br.cleared, " attacks used=", used.keys(), " enraged=", raged, " frames=", n)
		check(br.cleared, bid + " should be beatable")
		check(used.size() >= 2 and raged, bid + " should vary its attacks and enrage")
	print("FOES ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
