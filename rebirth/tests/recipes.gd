extends SceneTree
# Eight elements, three carried slots, generated reactions and storms, and recipes that
# cast themselves when their two elements react.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Spell = preload("res://src/spell.gd")
const Chem = preload("res://src/chem.gd")
const Book = preload("res://src/book.gd")
const Combo = preload("res://src/combo.gd")
const Lobby = preload("res://src/lobby.gd")
const Env = preload("res://src/env.gd")
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
func wipe():
	for e in g.enemies:
		e.dead = true
	g.fields.clear()
	g.zones.clear()
	g.spells.clear()
	g.bullets.clear()
	g.spell_cds = [0.0, 0.0, 0.0]
# cast a recipe text at pos with the hero aiming right
func cast(text, pos):
	g.p.aim = Vector2.RIGHT
	Spell.cast(g, Spell.parse(text), pos)
	return g.spells[-1]
func _init():
	Meta.PATH = "user://rebirth_recipes.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 5: await process_frame
	Meta.S.pet = ""
	g.goto_lobby()

	# ---- the table: every pair and every triple exists ----
	check(D.ALL.size() == 15 and Chem.pair_keys().size() == 105, "fifteen elements make 105 pairs")
	for pk in Chem.pair_keys():
		check(D.REACT.has(pk), "reaction has a name: " + pk)
	for el in D.ALL:
		check(D.EL_NAME.has(el) and D.EL_COL.has(el) and D.EL_PREFIX.has(el) and Chem.ADJ.has(el) and Chem.ASPECT.has(el) and g.Art.T.has("ic_" + el) and g.Art.T.has("b_" + el) and g.Reso.NAME.has(el) and Spell.EL_WORD.has(el) and g.Forge.ELEMENTS.has(el), "element is complete: " + el)
	for key in Chem.pair_keys():
		check(D.REACT.has(key) and Chem.field_name(key) != "", "pair " + key + " has a reaction")
	var names = {}
	var n3 = 0
	for i in 8:
		for j in range(i + 1, 8):
			for k in range(j + 1, 8):
				var sk = Chem.storm_key([D.ALL[i], D.ALL[j], D.ALL[k]])
				names[Chem.storm_name(sk)] = true
				n3 += 1
				check(Chem.storm_els(sk).size() == 3, "storm " + sk + " knows its elements")
	check(n3 == 56 and names.size() == 56, "56 storms, each with its own name (%d)" % names.size())
	check(Chem.storm_name(Chem.storm_key(["fire", "ice", "bolt"])) == "THUNDERSTORM", "the old storms keep their names")
	check(Chem.storm_name(Chem.storm_key(["wind", "fire", "stone"])) == "HOWLING MAGMA", "a new storm is named from words: " + Chem.storm_name(Chem.storm_key(["wind", "fire", "stone"])))

	# ---- words ----
	var r = Spell.parse("fire ice wall push")
	check(r.ok and r.els == ["fire", "ice"] and r.shape == "wall" and r.verb == "push" and r.mods.is_empty(), "english recipe")
	r = Spell.parse("xo\u00e1y s\u00e9t \u0111\u1ed9c h\u00fat")
	check(r.ok and r.els == ["bolt", "tox"] and r.shape == "vortex" and r.verb == "pull", "vietnamese recipe: " + str(r))
	r = Spell.parse("\u0111\u00e1 gi\u00f3 m\u01b0a n\u1ed5 to")
	check(r.ok and r.els == ["stone", "wind"] and r.shape == "rain" and r.verb == "burst" and r.mods == ["big"], "new elements in vietnamese: " + str(r))
	r = Spell.parse("light void lance hold strong long")
	check(r.ok and r.els == ["light", "void"] and r.shape == "lance" and r.verb == "hold" and r.mods.size() == 2, "lance, hold and two size words")
	check(Spell.rest_of(r) > Spell.rest_of(Spell.parse("light void lance")), "size words cost rest time")
	check(Spell.parse("stone fire orbit pull").shape == "orbit", "orbit")
	check(not Spell.parse("fire wall").ok and not Spell.parse("fire flame wall").ok, "one element is not a recipe")
	var rr = RandomNumberGenerator.new()
	rr.seed = 5
	var kinds = {}
	for i in 60:
		var t = Spell.random_text(rr)
		var q = Spell.parse(t)
		check(q.ok, "the generator writes valid recipes: " + t)
		kinds[q.shape + q.verb] = true
	check(kinds.size() >= 15, "and many different ones (%d)" % kinds.size())
	check(not Spell.write(0, "big wall") and Spell.recipes().is_empty(), "a bad recipe is not saved")
	check(Spell.write(0, "fire ice wall push") and Spell.write(1, "stone wind rain burst big") and Spell.recipes().size() == 2, "recipes are saved")
	var rows = Lobby.rows(g, "spell")
	check(rows.size() == 6 and rows[1].name.find("FIRE ICE WALL PUSH") >= 0, "the lectern lists them")
	g.roll_slot = 2
	rows[4].fn.call()
	check(Spell.recipes().size() == 3 and g.menu_next == "spell", "the lectern can roll one")
	g.menu_next = ""
	check(Spell.write(2, ""), "a slot can be cleared")

	# ---- three carried elements ----
	check(Meta.slots() == ["fire", "ice", "bolt"], "the default slots")
	var cr = g.inter.filter(func(it): return it.kind == "crystal")
	check(cr.size() == D.ALL.size(), "the hub has a crystal for each element")
	g.p.pos = cr[4].pos + Vector2(0, 6)
	g.interact(cr[4])
	check(Meta.slots() == ["stone", "fire", "ice"] and g.p.els == ["stone", "fire", "ice"], "a crystal puts its element first: " + str(Meta.slots()))
	await frames(8)
	shot("slots_hub")
	Meta.save()
	Meta.load_save()
	check(Meta.slots() == ["stone", "fire", "ice"] and Spell.recipes().size() == 2, "slots and recipes survive a reload")

	g.start_run(12, false)
	await frames(3)
	check(g.p.els == ["stone", "fire", "ice"] and g.p.eli == 0 and g.cur_el() == "stone", "the run starts painting slot one")
	g.jp[KEY_2] = true
	await frames(2)
	check(g.p.eli == 1 and g.cur_el() == "fire", "2 switches to the second element")
	g.jp[KEY_TAB] = true
	await frames(2)
	check(g.p.eli == 2 and g.cur_el() == "ice", "tab cycles")
	g.jp[KEY_1] = true
	await frames(2)
	check(g.p.eli == 0, "1 goes back")
	# native bonus
	g.p.weapons[g.p.wi] = {id = "pistol", el = "stone", el2 = "", lv = 0}
	var dm = []
	for i in 2:
		g.p.eli = i
		g.bullets.clear()
		g.p.cd = 0.0
		g.p.en = float(g.p.men)
		g.try_fire()
		dm.append(g.bullets[-1].dmg)
		check(g.bullets[-1].el == g.p.els[i], "the shot carries the chosen element")
	check(absf(dm[1] / dm[0] - 1.0) < 0.01, "every element hits the same through any weapon (%.2f)" % (dm[1] / dm[0]))
	g.p.eli = 0
	g.bullets.clear()
	await frames(2)
	shot("slots_hud")

	var c: Vector2 = g.pcenter() + Vector2(55, 0)

	# ---- a new element: status, generated reaction, field, storm ----
	wipe()
	Spell.write(0, "")
	Spell.write(1, "")
	var e = dummy(c)
	var o = dummy(c + Vector2(18, 8))
	g.hurt_enemy(e, 1.0, "stone")
	check(e.st.has("stone"), "stone sticks to a foe")
	var hp_o = o.hp
	g.hurt_enemy(e, 1.0, "fire")
	check(not e.st.has("stone") and g.fields.size() == 1 and g.fields[0].key == "fire+stone", "stone + fire reacts")
	check(Combo.name_of(g.fields[0]) == "MAGMA" and Book.known("fire+stone"), "it is magma, and it is written down")
	check(o.hp < hp_o, "the generated blast hits the foe beside it")
	g.add_bullet(c + Vector2(10, 0), Vector2(1, 0), {team = 1, el = "", r = 3.0, life = 5.0})
	hp_o = o.hp
	await frames(24)
	shot("gen_field")
	check(o.hp < hp_o, "the generated field keeps hurting")
	check(g.bullets.filter(func(b): return b.team == 1 and not b.dead).is_empty(), "a field with stone stops bullets")
	g.hurt_enemy(e, 1.0, "wind")
	check(g.fields[0].tier == 3 and g.fields[0].key == "fire+stone+wind" and Combo.name_of(g.fields[0]) == "MAGMA TORNADO" and g.fields[0].form == "wind", "a third element gives the field a form: " + Combo.name_of(g.fields[0]))
	check(Book.known("s_fire+stone+wind"), "and the storm is written down")
	hp_o = o.hp
	await frames(30)
	shot("gen_storm")
	check(o.hp < hp_o, "the generated storm hurts")
	Combo.touch(g, g.fields[0].pos, "void")
	check(g.fields.filter(func(f): return f.life > 0.0).is_empty(), "a fourth element is still a cataclysm")
	wipe()
	# aspects
	var w1 = dummy(c)
	var d0 = w1.pos.distance_to(g.p.pos)
	g.hurt_enemy(w1, 1.0, "wind")
	await frames(6)
	check(w1.pos.distance_to(g.p.pos) > d0 + 3.0, "wind shoves a foe back")
	var l1 = dummy(c + Vector2(0, 30))
	g.hurt_enemy(l1, 1.0, "light")
	check(l1.vuln > 0.0, "light exposes a foe")
	g.p.en = 10.0
	g.hurt_enemy(l1, 1.0, "void")
	check(g.p.en > 10.0, "void feeds energy")
	wipe()
	# the room
	if g.dg.terr.size() == 0:
		g.dg.terr.resize(g.dg.w * g.dg.h)
	var cell = Vector2i((c / 16.0).floor())
	g.dg.terr[cell.y * g.dg.w + cell.x] = 2
	Env.touch(g, c, 10.0, "stone")
	check(g.dg.terr[cell.y * g.dg.w + cell.x] == 0, "stone fills a pit")

	# ---- recipes cast themselves ----
	Spell.write(0, "fire ice wall push")
	Spell.write(1, "stone wind rain burst big")
	var a = dummy(c)
	g.hurt_enemy(a, 1.0, "fire")
	check(g.spells.is_empty(), "one element casts nothing")
	g.hurt_enemy(a, 1.0, "ice")
	check(g.spells.size() == 1 and g.spells[0].shape == "wall", "fire meeting ice casts the wall by itself")
	a.react_cd = 0.0
	g.hurt_enemy(a, 1.0, "fire")
	g.hurt_enemy(a, 1.0, "ice")
	check(g.spells.size() == 1, "the recipe rests before it can go again")
	a.react_cd = 0.0
	g.hurt_enemy(a, 1.0, "stone")
	g.hurt_enemy(a, 1.0, "wind")
	check(g.spells.size() == 2 and g.spells[1].shape == "rain", "another pair sets off another recipe")
	await frames(6)
	shot("recipe_auto")
	g.jp[KEY_V] = true
	await frames(2)
	check(g.spells.size() == 2, "nothing is bound to V any more")
	wipe()

	# ---- shapes and motions ----
	var s = cast("fire ice wall push", c)
	var foe = dummy(s.pos + Vector2(4, 0))
	g.add_bullet(s.pos - Vector2(3, 0), Vector2(10, 0), {team = 1, el = "", r = 3.0, life = 5.0})
	await frames(20)
	shot("shape_wall")
	check(foe.hp < foe.mhp and foe.pos.x - s.pos.x > 12.0, "wall push: hurts and shoves (%.1f)" % (foe.pos.x - s.pos.x))
	check(g.bullets.filter(func(q): return q.team == 1 and not q.dead).is_empty(), "wall: stops bullets")
	wipe()

	s = cast("bolt tox vortex pull", c)
	var far = dummy(c + Vector2(0, -55))
	var d1 = far.pos.distance_to(c)
	await frames(45)
	shot("shape_vortex")
	check(far.pos.distance_to(c) < d1 - 15.0 and far.hp < far.mhp, "vortex pull: drags in and grinds")
	wipe()

	var tgt = dummy(g.pcenter() + Vector2(32, 0))
	var t0 = tgt.pos
	s = cast("fire ice wave push", c)
	await frames(8)
	shot("shape_wave")
	await frames(30)
	check(tgt.hp < tgt.mhp and tgt.pos.x - t0.x > 12.0 and g.spells.is_empty(), "wave push: hits, carries, ends")
	wipe()

	var rn = dummy(c)
	s = cast("stone wind rain hold", c)
	var pinned = false
	for i in 40:
		await frames(1)
		if rn.frz > 0.0:
			pinned = true
	shot("shape_rain")
	check(rn.hp < rn.mhp, "rain: strikes fall on foes inside")
	check(pinned, "hold: pins the foe")
	wipe()

	var ob = dummy(g.pcenter() + Vector2(30, 0))
	s = cast("light void orbit push", c)
	g.add_bullet(g.pcenter() + Vector2(0, -30), Vector2.ZERO, {team = 1, el = "", r = 3.0, life = 9.0})
	await frames(60)
	shot("shape_orbit")
	check(ob.hp < ob.mhp, "orbit: the orbs hit what stands near you")
	check(g.bullets.filter(func(q): return q.team == 1 and not q.dead).is_empty(), "orbit: the orbs eat bullets")
	check(g.spells.size() == 1 and g.spells[0].pos.distance_to(g.pcenter()) < 12.0, "orbit: follows the hero")
	wipe()

	var ln1 = dummy(g.pcenter() + Vector2(40, 0))
	var ln2 = dummy(g.pcenter() + Vector2(70, 2))
	var off = dummy(g.pcenter() + Vector2(40, 50))
	s = cast("fire void lance pull", c)
	check(ln1.hp < ln1.mhp and ln2.hp < ln2.mhp and off.hp == off.mhp, "lance: pierces the line and nothing else")
	await frames(4)
	shot("shape_lance")
	await frames(12)
	check(g.spells.is_empty(), "lance: is over at once")
	wipe()

	var bt = dummy(c + Vector2(20, 0))
	s = cast("fire stone vortex burst", c)
	s.life = 0.2
	var hb = bt.hp
	await frames(4)
	hb = bt.hp
	await frames(8)
	check(bt.hp < hb and g.spells.is_empty(), "burst: explodes when the spell ends")
	wipe()

	var big = cast("fire ice vortex push big", c)
	var small = cast("fire ice vortex push", c)
	check(big.r > small.r * 1.2, "big: wider")
	check(cast("fire ice vortex push long", c).life > small.life * 1.3, "long: lasts")
	check(cast("fire ice vortex push strong", c).dmg > small.dmg * 1.2, "strong: hits harder")
	wipe()

	# the writing screen draws
	g.say_mode = "rc0"
	g.say = "da gio mua no to"
	g.set_state("say")
	await frames(4)
	shot("recipe_write")
	g.say_mode = ""
	g.open_menu("spell")
	await frames(4)
	shot("recipe_menu")
	g.set_state("play")
	await frames(3)

	print("RECIPES ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(fails)
