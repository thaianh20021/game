extends SceneTree
# Infuse: weather is cut down, reactions charge the weapon, a dash lets the charge out.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Combo = preload("res://src/combo.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for k in n: await process_frame
func foe(pos):
	var e = g.spawn_enemy("goblin", pos)
	e.mhp = 1000.0
	e.hp = 1000.0
	e.born = 0.0
	e.stun = 99.0
	return e
func dash(dir):
	var k = KEY_D if dir.x > 0 else KEY_A
	g.p.dash_cd = 0.0
	g.sim[k] = true
	for n in 12:
		g.jp[KEY_SPACE] = true
		await frames(1)
		if g.p.dash_t > 0.0:
			break
	await frames(10)
	g.sim.erase(k)
func _init():
	Meta.PATH = "user://rebirth_inf.json"
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
	g.p.pos = c + Vector2(-80, 20)
	g.enemies.clear()
	g.fields.clear()
	g.st.crit = 0.0
	# weather alone is cut down
	var a = foe(c)
	g.hurt_enemy(a, 100.0, "", Vector2.ZERO, true)
	check(absf((1000.0 - a.hp) - 100.0 * D.INF.passive) < 0.5, "a burn deals %d%%: %.1f" % [int(D.INF.passive * 100), 1000.0 - a.hp])
	a.hp = 1000.0
	g.hurt_enemy(a, 10.0, "")
	check(absf((1000.0 - a.hp) - 10.0 * g.st.dmg) < 0.5, "a direct hit is not cut")
	# a reaction charges the weapon
	a.hp = 1000.0
	g.p.inf = []
	g.hurt_enemy(a, 1.0, "fire")
	g.hurt_enemy(a, 1.0, "water")
	check(g.p.inf.size() == 1 and g.p.inf[0].key == "fire+water", "a reaction pours one charge: " + str(g.p.get("inf")))
	check(1000.0 - a.hp < 25.0, "and deals little itself: %.1f" % (1000.0 - a.hp))
	for i in 5:
		g.infuse("fire+ice", Color.WHITE)
	check(g.p.inf.size() == D.INF.max and g.p.inf[D.INF.max - 1].key == "fire+ice", "charges stop at %d" % D.INF.max)
	# the dash lets it out: a melee weapon rings everything round its end
	g.enemies.clear()
	g.fields.clear()
	g.p.weapons[g.p.wi] = {id = "blade", el = "fire", el2 = "", lv = 0}
	g.p.pos = c + Vector2(-60, 0)
	g.p.inf = [{key = "fire+water", col = Color.WHITE}]
	var b = foe(c)
	var hp0 = b.hp
	await dash(Vector2.RIGHT)
	check(g.p.get("inf", []).is_empty() and not g.p.has("inf_rel"), "the dash spends the charge")
	var one = hp0 - b.hp
	check(one >= D.INF.dmg * 0.9, "and the release lands hard: %.1f" % one)
	var trail = g.fields.filter(func(f): return f.get("trail", false))
	check(trail.size() >= 4 and trail.all(func(f): return f.key == "fire+water"), "a strip of steam along the dash: %d" % trail.size())
	check(Combo.plain(g) == 0, "the strip does not take field slots")
	# three charges hit harder and leave a full field
	g.fields.clear()
	b.hp = 1000.0
	g.p.pos = c + Vector2(-60, 0)
	for i in 3:
		g.infuse("fire+ice", Color.WHITE)
	await dash(Vector2.RIGHT)
	check(1000.0 - b.hp > one * 1.8, "a full release hits much harder: %.1f vs %.1f" % [1000.0 - b.hp, one])
	check(Combo.plain(g) == 1, "and leaves the field it was made of")
	# a ranged weapon fires a fan of heavy shots
	g.fields.clear()
	g.bullets.clear()
	g.p.weapons[g.p.wi] = {id = "pistol", el = "fire", el2 = "", lv = 0}
	g.enemies.clear()
	g.p.inf = [{key = "", col = Color.WHITE}, {key = "", col = Color.WHITE}]
	await dash(Vector2.RIGHT)
	check(g.bullets.filter(func(q): return q.team == 0).size() >= 5, "a ranged weapon fires a fan: %d" % g.bullets.size())
	# a dash without charge does nothing special
	g.bullets.clear()
	await dash(Vector2.LEFT)
	check(g.bullets.is_empty() and g.fields.is_empty(), "an empty dash is just a dash")
	# charges fade
	g.infuse("fire+ice", Color.WHITE)
	await frames(int((D.INF.life + D.INF.fade) * 30) + 10)
	check(g.p.inf.is_empty(), "charges fade when unused")
	# the dummy is never cut
	var d = g.spawn_enemy("dummy", c + Vector2(0, -50))
	var dh = d.hp
	g.hurt_enemy(d, 10.0, "", Vector2.ZERO, true)
	check(absf(dh - d.hp - 10.0) < 0.5, "the dummy shows full numbers")
	print("INF OK" if fails == 0 else "INF FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
