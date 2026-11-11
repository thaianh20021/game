extends SceneTree
# Combine: recipes written in words, cast from the elements lying on the field.
const Meta = preload("res://src/meta.gd")
const Spell = preload("res://src/spell.gd")
const Lobby = preload("res://src/lobby.gd")
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
func dummy(pos):
	var e = g.spawn_enemy("goblin", pos)
	e.mhp = 99999.0
	e.hp = 99999.0
	e.stun = 999.0
	return e
# cast with the aim point held inside the room (a headless mouse sits in a corner)
var ap = Vector2.ZERO
func comb():
	g.cin = {jp = {}, mw = ap}
	g.p.aim = (ap - g.pcenter()).normalized()
	var ok = Spell.combine(g)
	g.cin = null
	return ok
func wipe():
	for e in g.enemies:
		e.dead = true
	g.fields.clear()
	g.zones.clear()
	g.spells.clear()
	g.bullets.clear()
	g.spell_cd = 0.0
func _init():
	Meta.PATH = "user://rebirth_spell.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 5: await process_frame
	Meta.S.pet = ""
	g.goto_lobby()

	# ---- words ----
	var r = Spell.parse("fire ice wall push")
	check(r.ok and r.els == ["fire", "ice"] and r.shape == "wall" and r.verb == "push", "english recipe")
	r = Spell.parse("xo\u00e1y s\u00e9t \u0111\u1ed9c h\u00fat")
	check(r.ok and r.els == ["bolt", "tox"] and r.shape == "vortex" and r.verb == "pull", "vietnamese recipe: " + str(r))
	r = Spell.parse("storm fire wave")
	check(r.ok and r.els == ["bolt", "fire"] and r.shape == "wave" and r.verb == "push", "storm is an element first; motion defaults to push")
	check(not Spell.parse("fire wall").ok and not Spell.parse("fire flame wall").ok, "one element is not a recipe")
	check(not Spell.write(0, "big wall") and Spell.recipes().is_empty(), "a bad recipe is not saved")
	check(Spell.write(0, "fire ice wall push") and Spell.write(1, "xoay set doc hut") and Spell.recipes().size() == 2, "two recipes are saved")
	var rows = Lobby.rows(g, "spell")
	check(rows.size() == 4 and rows[1].name.find("FIRE ICE WALL PUSH") >= 0, "the lectern lists them")
	rows[2].fn.call()
	check(g.pending_say == "rc1", "a slot can be rewritten")
	g.pending_say = ""
	Meta.save()
	Meta.load_save()
	check(Spell.recipes().size() == 2 and Spell.recipes()[0].shape == "wall", "recipes survive a reload")

	# the writing screen draws
	g.say_mode = "rc0"
	g.say = "lua bang tuong day"
	g.set_state("say")
	await frames(4)
	shot("spell_write")
	g.say_mode = ""
	g.open_menu("spell")
	await frames(4)
	shot("spell_menu")
	g.set_state("play")
	g.start_run(12, false)
	await frames(3)
	ap = g.pcenter() + Vector2(60, 0)
	var dir = Vector2.RIGHT
	g.p.aim = dir

	# ---- nothing on the field, nothing to cast ----
	check(not comb() and g.spells.is_empty(), "no elements, no spell")
	g.spell_cd = 0.0
	var a = dummy(ap + Vector2(-12, 0))
	g.hurt_enemy(a, 1.0, "fire")
	check(Spell.ready(g, ap) == null and not comb(), "one element is not enough")
	g.spell_cd = 0.0

	# ---- wall + push, fuelled by two painted foes ----
	var b = dummy(ap + Vector2(12, 0))
	g.hurt_enemy(b, 1.0, "ice")
	check(Spell.ready(g, ap) != null and Spell.ready(g, ap).shape == "wall", "fire on one foe and ice on another match the wall recipe")
	await frames(2)
	shot("spell_ready")
	check(comb(), "combine casts")
	check(g.spells.size() == 1 and g.spells[0].shape == "wall", "the wall stands")
	check(not a.st.has("fire") and not b.st.has("ice"), "the elements are used up")
	check(not comb(), "it cannot be spammed")
	var wall = g.spells[0]
	var foe = dummy(wall.pos + wall.dir * 4.0)
	var hp0 = foe.hp
	g.add_bullet(wall.pos - wall.dir * 3.0, wall.dir * 10.0, {team = 1, el = "", r = 3.0, life = 5.0})
	await frames(20)
	shot("spell_wall")
	check(foe.hp < hp0, "the wall hurts what touches it")
	check((foe.pos - wall.pos).dot(wall.dir) > 12.0, "and pushes it away (%.1f)" % (foe.pos - wall.pos).dot(wall.dir))
	check(g.bullets.filter(func(q): return q.team == 1 and not q.dead).is_empty(), "and stops enemy bullets")
	await frames(160)
	check(g.spells.is_empty(), "the wall ends")
	wipe()

	# ---- vortex + pull, fuelled by a pool and a foe ----
	g.zones.append({pos = ap, r = 14.0, el = "tox", life = 5.0, team = 0, tick = 0.3})
	var c = dummy(ap + Vector2(0, 14))
	g.hurt_enemy(c, 1.0, "bolt")
	var far = dummy(ap + Vector2(0, -55))
	check(comb() and g.spells.size() == 1 and g.spells[0].shape == "vortex", "a pool and a shocked foe make the vortex")
	check(g.zones.filter(func(z): return z.life > 0.0 and z.el == "tox").is_empty(), "the pool is drunk up")
	var vx = g.spells[0]
	var d0 = far.pos.distance_to(vx.pos)
	await frames(45)
	shot("spell_vortex")
	check(far.pos.distance_to(vx.pos) < d0 - 15.0, "the vortex drags foes in (%.1f to %.1f)" % [d0, far.pos.distance_to(vx.pos)])
	check(far.hp < far.mhp or c.hp < c.mhp, "and grinds them")
	wipe()

	# ---- wave + push, fuelled by a reaction field ----
	check(Spell.write(0, "song lua bang day"), "the first slot is rewritten as a wave")
	var w0 = dummy(ap)
	g.hurt_enemy(w0, 1.0, "fire")
	g.hurt_enemy(w0, 1.0, "ice")
	check(not g.fields.is_empty(), "a reaction leaves a field")
	w0.dead = true
	var tgt = dummy(g.pcenter() + dir * 32.0)
	var t0 = tgt.pos
	check(comb() and g.spells[0].shape == "wave", "the field alone fuels the wave")
	check(g.fields.filter(func(f): return f.life > 0.0).is_empty(), "the field is used up")
	await frames(8)
	shot("spell_wave")
	await frames(30)
	check(tgt.hp < tgt.mhp, "the wave hits what it rolls over")
	check((tgt.pos - t0).dot(dir) > 12.0, "and carries it along (%.1f)" % (tgt.pos - t0).dot(dir))
	check(g.spells.is_empty(), "the wave ends")
	wipe()

	# ---- the room feels it ----
	if g.dg.terr.size() == 0:
		g.dg.terr.resize(g.dg.w * g.dg.h)
	var cell = Vector2i((ap / 16.0).floor())
	g.dg.terr[cell.y * g.dg.w + cell.x] = 1
	Spell.cast(g, Spell.parse("fire ice vortex pull"), ap, 2)
	check(g.dg.terr[cell.y * g.dg.w + cell.x] == 0, "a spell with ice freezes the mire under it")
	await frames(10)

	# ---- the key ----
	wipe()
	ap = Spell.aim_point(g)
	var k1 = dummy(ap + Vector2(-10, 0))
	var k2 = dummy(ap + Vector2(10, 0))
	g.hurt_enemy(k1, 1.0, "fire")
	g.hurt_enemy(k2, 1.0, "ice")
	g.jp[KEY_V] = true
	await frames(2)
	check(g.spells.size() == 1, "pressing V combines")

	print("SPELL ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(fails)
