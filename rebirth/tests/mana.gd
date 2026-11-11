extends SceneTree
# Mana per element, reaction costs, one effect at a time, control immunity, gathered casts.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Combo = preload("res://src/combo.gd")
const Hud = preload("res://src/hud.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for i in n: await process_frame
func foe(pos):
	var e = g.spawn_enemy("goblin", pos)
	e.mhp = 99999.0
	e.hp = 99999.0
	e.born = 0.0
	return e
func fill():
	g.p.sat = [1.0, 1.0, 1.0]
	g.p.spent = [false, false, false]
	g.mana_total(g.p)
func _init():
	Meta.PATH = "user://rebirth_mana.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.start_run(5, false)
	await frames(5)
	var room = null
	for r in g.dg.rooms:
		if r.type == "fight":
			room = r
			break
	room.cleared = true
	var c: Vector2 = g.rc(room)
	g.p.pos = c + Vector2(-60, 20)
	g.p.aim = Vector2.RIGHT
	g.enemies.clear()
	var men = float(g.p.men)
	var k = D.SAT.base / men

	# ---- energy is the sum of the three pools ----
	fill()
	check(absf(g.p.en - men) < 0.5, "full pools are full mana")
	g.p.eli = 1
	g.p.en -= men / 6.0
	g.mana_sync(g.p)
	check(absf(g.p.sat[1] - 0.5) < 0.02 and g.p.sat[0] == 1.0, "a loss comes out of the chosen pool: " + str(g.p.sat))
	g.p.en += men / 6.0
	g.mana_sync(g.p)
	check(absf(g.p.sat[1] - 1.0) < 0.02, "a gain goes to the emptiest pool")
	g.p.eli = 0

	# ---- a reaction takes from both pools ----
	fill()
	g.p.els = ["fire", "ice", "bolt"]
	var e = foe(c)
	e.stun = 99.0
	g.hurt_enemy(e, 1.0, "fire")
	g.hurt_enemy(e, 1.0, "ice")
	check(g.fields.size() == 1, "fire and ice react")
	check(absf(g.p.sat[0] - (1.0 - D.SAT.react * k)) < 0.01 and absf(g.p.sat[1] - (1.0 - D.SAT.react * k)) < 0.01 and g.p.sat[2] == 1.0, "the reaction took mana from both: " + str(g.p.sat))
	# ---- completing an effect takes more, from the completing element ----
	Combo.touch(g, g.fields[0].pos, "bolt")
	check(g.fields[0].tier == 3 and absf(g.p.sat[2] - (1.0 - D.SAT.storm * k)) < 0.01, "the third element pays for the storm: " + str(g.p.sat))

	# ---- one three-element effect at a time, three fields at most ----
	Combo.spawn(g, c + Vector2(90, 0), "fire+tox")
	Combo.touch(g, c + Vector2(90, 0), "ice")
	var live = g.fields.filter(func(f): return f.tier == 3 and f.life > 0.0)
	check(live.size() == 1 and live[0].pos.distance_to(c + Vector2(90, 0)) < 1.0, "a new effect replaces the old one")
	g.fields.clear()
	for i in 5:
		Combo.spawn(g, c + Vector2(i * 60 - 120, 60), ["fire+ice", "fire+tox", "bolt+fire", "bolt+ice", "ice+tox"][i])
	check(g.fields.size() == D.FIELDS_MAX, "no more than %d fields: %d" % [D.FIELDS_MAX, g.fields.size()])
	check(g.fields.back().key == "ice+tox", "the newest field stays")
	g.fields.clear()

	# ---- control immunity ----
	g.enemies.clear()
	g.zones.clear()
	var e2 = foe(c + Vector2(40, 0))
	e2.stun = 0.3
	await frames(15)
	check(e2.stun <= 0.0 and float(e2.get("cc_free", 0.0)) > 0.5, "a freed foe is immune for a while")
	e2.stun = 2.0
	e2.frz = 2.0
	await frames(2)
	check(e2.stun <= 0.0 and e2.frz <= 0.0, "it cannot be held during that time")
	await frames(50)
	e2.stun = 1.0
	await frames(2)
	check(e2.stun > 0.0, "then it can be held again")

	# ---- no weapon penalty, weapon names its form ----
	check(Hud.form_name(D.WEAPONS["blade"]) == "ARC" and Hud.form_name(D.WEAPONS["pistol"]) == "BOLT", "weapons name the shape they give")
	for id in D.WEAPONS:
		check(Hud.form_name(D.WEAPONS[id]) != "", "form for " + id)

	# ---- gathered cast ----
	g.enemies.clear()
	g.bullets.clear()
	fill()
	g.p.weapons[g.p.wi] = {id = "pistol", el = "fire", el2 = "", lv = 0}
	g.p.eli = 0
	g.sim.elh = true
	await frames(10)
	check(g.bullets.is_empty() and float(g.p.chg) > 0.2, "holding the element key gathers")
	await frames(20)
	g.sim.erase("elh")
	await frames(2)
	check(g.bullets.size() == 1 and g.bullets[0].el == "fire" and g.bullets[0].aoe > 30.0, "letting go throws one big orb")
	check(g.p.sat[0] < 1.0 - D.SAT.cast * k + 0.1, "the cast costs mana: " + str(g.p.sat[0]))
	g.bullets.clear()
	# a short press only switches
	g.sim.elh = true
	await frames(5)
	g.sim.erase("elh")
	await frames(2)
	check(g.bullets.is_empty(), "a short press does not cast")
	# every weapon type casts without error, an empty pool does not
	for id in ["blade", "pistol"] + D.WEAPONS.keys().filter(func(q): return D.WEAPONS[q].type in ["beam", "chain", "lob"]):
		fill()
		g.p.weapons[g.p.wi] = {id = id, el = "ice", el2 = "", lv = 0}
		var n0 = int(g.p.get("casts", 0))
		g.cast_big(c)
		check(int(g.p.casts) == n0 + 1, "cast through " + id)
		await frames(15)
	g.p.sat[g.p.eli] = 0.0
	g.p.spent[g.p.eli] = true
	var n1 = int(g.p.casts)
	g.cast_big(c)
	check(int(g.p.casts) == n1, "no mana, no cast")

	# ---- close weapons earn mana back ----
	g.enemies.clear()
	fill()
	g.p.eli = 0
	g.p.sat = [1.0, 0.2, 0.2]
	g.p.weapons[g.p.wi] = {id = "blade", el = "fire", el2 = "", lv = 0}
	var near = foe(g.p.pos + Vector2(16, 0))
	near.stun = 99.0
	g.p.aim = Vector2.RIGHT
	g.p.cd = 0.0
	g.try_fire()
	check(absf(g.p.sat[1] - (0.2 + D.SAT.strike)) < 0.01 and absf(g.p.sat[2] - (0.2 + D.SAT.strike)) < 0.01, "a strike that lands feeds the resting pools: " + str(g.p.sat))
	var spent_melee = 1.0 - g.p.sat[0]
	g.p.sat[0] = 1.0
	g.p.weapons[g.p.wi] = {id = "pistol", el = "fire", el2 = "", lv = 0}
	g.p.cd = 0.0
	g.try_fire()
	check(spent_melee > 0.0 and spent_melee / D.WEAPONS["blade"].cd < (1.0 - g.p.sat[0]) / D.WEAPONS["pistol"].cd * 0.6, "painting with a blade drains half as fast")
	g.enemies.clear()
	g.bullets.clear()

	# ---- a weapon with a cost needs mana in the chosen pool ----
	var costly = ""
	for id in D.WEAPONS:
		if D.WEAPONS[id].cost > 0.0 and D.WEAPONS[id].type == "bullet":
			costly = id
			break
	if costly != "":
		g.p.weapons[g.p.wi] = {id = costly, el = "", el2 = "", lv = 0}
		g.p.sat[g.p.eli] = 0.0
		g.p.spent[g.p.eli] = true
		g.mana_total(g.p)
		g.bullets.clear()
		g.p.cd = 0.0
		g.try_fire()
		check(g.bullets.is_empty(), "an empty pool cannot feed a costly weapon")
		g.set_el((int(g.p.eli) + 1) % 3)
		g.p.sat[g.p.eli] = 1.0
		g.p.spent[g.p.eli] = false
		g.mana_total(g.p)
		g.p.cd = 0.0
		var before: float = g.p.sat[g.p.eli]
		g.try_fire()
		check(not g.bullets.is_empty() and g.p.sat[g.p.eli] < before, "another pool can")
	await frames(20)
	print("MANA OK" if fails == 0 else "MANA FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
