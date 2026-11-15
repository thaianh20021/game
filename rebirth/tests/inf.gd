extends SceneTree
# Infuse: weather is cut down, reactions charge the weapon, a dash lets the charge out.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Combo = preload("res://src/combo.gd")
const Inf = preload("res://src/infuse.gd")
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
		if not g.p.get("inf", []).is_empty():
			g.p.inf_arm = 2.0
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
	# ---- layers ----
	check(Inf.shape([{key = "a"}, {key = "a"}, {key = "a"}]) == "pure" and Inf.shape([{key = "a"}, {key = "b"}, {key = "c"}]) == "trinity" and Inf.shape([{key = "a"}, {key = "b"}, {key = "a"}]) == "", "pure, trinity and plain")
	g.enemies.clear()
	g.fields.clear()
	g.bullets.clear()
	g.infx.clear()
	g.p.weapons[g.p.wi] = {id = "blade", el = "fire", el2 = "", lv = 0}
	g.p.pos = c + Vector2(-60, 0)
	var t1 = foe(c)
	g.p.inf = []
	for k in ["fire+water", "bolt+ice", "light+void"]:
		g.infuse(k, Color.WHITE)
	await dash(Vector2.RIGHT)
	await frames(12)
	var tri = 1000.0 - t1.hp
	check(g.infx.size() == 3 or tri > one * 3.0, "three different charges go off as three layers: %d layers, %.1f" % [g.infx.size(), tri])
	check(tri > one * 3.0, "and a trinity out-damages three single releases: %.1f vs %.1f" % [tri, one * 3.0])
	var keys = {}
	for f in g.fields:
		if f.get("trail", false):
			keys[f.key] = true
	check(keys.size() == 3 and Combo.plain(g) == 0, "the strip has all three reactions and no full field: " + str(keys.keys()))
	# ---- perfect ----
	g.fields.clear()
	g.bullets.clear()
	t1.hp = 1000.0
	t1.pos = c
	t1.kb = Vector2.ZERO
	g.p.pos = c + Vector2(-60, 0)
	g.p.inf = [{key = "fire+water", col = Color.WHITE}]
	g.add_bullet(c + Vector2(-40, -3), Vector2.ZERO, {dmg = 1.0, el = "", life = 3.0, team = 1})
	g.bullets[0].team = 1
	var hp_p = g.p.hp
	await dash(Vector2.RIGHT)
	check(1000.0 - t1.hp > one * 1.2, "a dash through a shot is perfect: %.1f vs %.1f" % [1000.0 - t1.hp, one])
	check(g.p.inf.size() == 1 and g.p.hp == hp_p, "and gives a charge back, unhurt: %d" % g.p.inf.size())
	g.bullets.clear()
	g.slowmo = 0.0
	# ---- chain ----
	g.enemies.clear()
	g.fields.clear()
	g.p.pos = c + Vector2(-60, 0)
	for i in 5:
		foe(c + Vector2.from_angle(i * TAU / 5.0) * 22.0)
	g.p.sat = [0.2, 0.2, 0.2]
	g.p.inf = [{key = "fire+ice", col = Color.WHITE}]
	await dash(Vector2.RIGHT)
	await frames(int(D.INF.chain_t * 30) + 6)
	check(g.p.sat[1] > 0.3, "a chain of five refills mana: %.2f" % g.p.sat[1])
	check(g.p.inf.size() == 1 and not g.p.has("inf_ch"), "and gives a charge back: %d" % g.p.inf.size())
	# ---- blessings ----
	g.enemies.clear()
	g.p.inf = []
	g.apply_buff("inf_cap")
	for i in 6:
		g.infuse("fire+ice", Color.WHITE)
	check(g.p.inf.size() == D.INF.max + 1, "fourth vessel holds one more: %d" % g.p.inf.size())
	g.apply_buff("inf_hold")
	await frames(int((D.INF.life + D.INF.fade) * 30) + 10)
	check(g.p.inf.size() == D.INF.max + 1, "sealed flask keeps them")
	g.apply_buff("inf_keep")
	g.p.pos = c + Vector2(-60, 0)
	await dash(Vector2.RIGHT)
	check(g.p.inf.size() == 1, "ember heart keeps the last charge: %d" % g.p.inf.size())
	g.apply_buff("inf_reap")
	g.fields.clear()
	g.p.pos = c + Vector2(-60, 0)
	var weak = foe(c)
	weak.hp = 1.0
	g.p.inf = [{key = "fire+ice", col = Color.WHITE}]
	await dash(Vector2.RIGHT)
	check(g.p.inf.size() == 2, "reaping pours a charge back on a kill (plus the kept one): %d" % g.p.inf.size())
	for bf in D.BUFFS:
		check(g.Art.T.has("bl_" + bf.id), "emblem for " + bf.id)
	# ---- a bare dash does not release: the weapon must be armed by gathering ----
	g.p.buffs = []
	g.calc_stats()
	g.enemies.clear()
	g.fields.clear()
	g.bullets.clear()
	g.p.weapons[g.p.wi] = {id = "blade", el = "fire", el2 = "", lv = 0}
	g.p.pos = c + Vector2(-60, 0)
	g.p.inf = [{key = "fire+ice", col = Color.WHITE}]
	g.p.erase("inf_arm")
	g.p.dash_cd = 0.0
	g.sim[KEY_D] = true
	for n in 12:
		g.p.erase("inf_arm")
		g.jp[KEY_SPACE] = true
		await frames(1)
		if g.p.dash_t > 0.0:
			break
	await frames(10)
	g.sim.erase(KEY_D)
	check(g.p.inf.size() == 1 and g.fields.is_empty(), "a bare dash keeps the charge")
	g.p.sat = [1.0, 1.0, 1.0]
	g.p.spent = [false, false, false]
	g.hitstop = 0.0
	g.slowmo = 0.0
	g.sim["elh"] = true
	for n in 60:
		await frames(1)
		if float(g.p.get("chg", 0.0)) >= D.SAT.charge + 0.05:
			break
	g.sim.erase("elh")
	await frames(3)
	check(float(g.p.get("inf_arm", 0.0)) > 0.0 and g.p.sat[g.p.eli] < 0.05 and g.p.spent[g.p.eli], "gathering arms the weapon and empties that element")
	g.p.pos = c + Vector2(-60, 0)
	g.p.dash_cd = 0.0
	g.sim[KEY_D] = true
	for n in 12:
		g.jp[KEY_SPACE] = true
		await frames(1)
		if g.p.dash_t > 0.0:
			break
	await frames(10)
	g.sim.erase(KEY_D)
	check(g.p.inf.is_empty() and not g.p.has("inf_arm"), "an armed dash releases")
	g.p.inf = [{key = "fire+ice", col = Color.WHITE}]
	g.p.inf_arm = 0.1
	await frames(8)
	check(not g.p.has("inf_arm") and g.p.inf.size() == 1, "arming wears off, the charge stays")
	g.p.sat = [1.0, 1.0, 1.0]
	g.p.spent = [false, false, false]
	# ---- the weapon decides how it charges ----
	g.enemies.clear()
	g.fields.clear()
	g.bullets.clear()
	g.p.buffs = []
	g.calc_stats()
	g.p.weapons[g.p.wi] = {id = "blade", el = "fire", el2 = "", lv = 0}
	g.p.inf = []
	g.infuse("fire+ice", Color.WHITE, g.p.pos + Vector2(20, 0))
	check(g.p.inf.size() == 2, "a blade charges twice from a reaction beside it: %d" % g.p.inf.size())
	g.p.inf = []
	g.infuse("fire+ice", Color.WHITE, g.p.pos + Vector2(200, 0))
	check(g.p.inf.size() == 1, "but once from afar")
	g.p.weapons[g.p.wi] = {id = "beam", el = "fire", el2 = "", lv = 0}
	g.p.inf = []
	g.infuse("fire+ice", Color.WHITE)
	check(absf(g.p.inf_t - D.INF.life * D.INF.beam_life) < 0.01, "a lens holds charges longer: %.1f" % g.p.inf_t)
	var lobs = D.WEAPONS.keys().filter(func(k): return D.WEAPONS[k].type == "lob")
	g.p.weapons[g.p.wi] = {id = lobs[0], el = "fire", el2 = "", lv = 0}
	g.p.pos = c + Vector2(-60, 0)
	var far = foe(c + Vector2(40, 0))
	g.sim["mouse"] = Vector2(9000, 135)  # far to the right: the release lands at full range that way
	g.p.inf = [{key = "fire+ice", col = Color.WHITE}]
	await dash(Vector2.LEFT)
	await frames(14)
	check(1000.0 - far.hp > D.INF.dmg * 0.9, "a mortar drops the release where you aim: %.1f" % (1000.0 - far.hp))
	g.sim.erase("mouse")
	g.enemies.clear()
	g.p.weapons[g.p.wi] = {id = "pistol", el = "fire", el2 = "", lv = 0}
	g.p.inf = [{key = "fire+ice", col = Color.WHITE}]
	await dash(Vector2.RIGHT)
	check(g.p.has("inf_rush"), "a horn fires faster after its volley")
	# ---- the notebook and the effects ----
	check(g.Meta.S.get("rels", {}).size() >= 3, "new releases are written down: " + str(g.Meta.S.get("rels", {}).keys()))
	g.pfx.clear()
	for k in g.Pfx.DUR:
		g.Pfx.spawn(g, k, g.p.pos, 40.0)
	check(g.pfx.size() == g.Pfx.DUR.size(), "every effect spawns")
	for el in D.ALL:
		check(g.Pfx.DUR.has(g.Pfx.of(g, el)), "an effect for " + el)
	await frames(40)
	check(g.pfx.is_empty(), "and they end")
	# ---- relics and synergies of the charged weapon ----
	g.p.buffs = []
	g.p.relics = ["flint", "fuse", "siphon"]
	g.calc_stats()
	g.More.refresh_syn(g)
	check(absf(g.gather_t() - D.SAT.charge * 0.5) < 0.001, "quick flint halves the gather")
	check(g.p.syn.has("hairtrigger") and g.st.get("inf_graze", 1.0) == 2.0, "flint and fuse make hair trigger")
	g.p.sat = [1.0, 1.0, 1.0]
	g.p.spent = [false, false, false]
	g.p.inf = [{key = "fire+ice", col = Color.WHITE}]
	Inf.arm(g)
	check(absf(g.p.inf_arm - D.INF.arm * 2.0) < 0.01 and absf(g.p.sat[g.p.eli] - 0.5) < 0.01, "long fuse doubles the armed time, siphon keeps half: %.1f %.2f" % [g.p.inf_arm, g.p.sat[g.p.eli]])
	g.p.erase("inf_arm")
	g.p.relics = ["chalice", "eye"]
	g.p.buffs = ["inf_cap", "inf_hold", "inf_reap", "inf_keep"]
	g.calc_stats()
	g.More.refresh_syn(g)
	check(g.p.syn.has("overflow") and g.p.syn.has("harvest") and g.st.get("inf_dmg", 1.0) == 1.25 and g.st.get("inf_chain", 3) == 2, "overflow and harvest")
	g.p.buffs = []
	g.calc_stats()
	g.More.refresh_syn(g)
	g.calc_stats()
	g.enemies.clear()
	g.fields.clear()
	g.infx.clear()
	g.p.weapons[g.p.wi] = {id = "blade", el = "fire", el2 = "", lv = 0}
	g.p.pos = c + Vector2(-60, 0)
	foe(c)
	g.p.inf = [{key = "fire+water", col = Color.WHITE}, {key = "bolt+ice", col = Color.WHITE}, {key = "light+void", col = Color.WHITE}]
	await dash(Vector2.RIGHT)
	var most = 0
	for k in 14:
		await frames(1)
		most = maxi(most, g.infx.size())
	check(most == 4, "third eye echoes the first layer of a trinity: %d" % most)
	g.p.hp = g.p.mhp - 2
	g.p.pos = c + Vector2(-60, 0)
	g.p.inf = []
	for i in 3:
		g.infuse("fire+ice", Color.WHITE)
	await dash(Vector2.RIGHT)
	check(g.p.hp == g.p.mhp - 1, "pure chalice heals one")
	check(int(g.rs.get("rel", 0)) > 5 and int(g.rs.get("trinity", 0)) >= 1 and int(g.rs.get("pure", 0)) >= 1 and int(g.rs.get("perf", 0)) >= 1 and int(g.rs.get("chain", 0)) >= 5, "the run is tallied: " + str(g.rs))
	for id in D.RELICS:
		check(g.Art.T.has("relic_" + id), "relic sprite " + id)
	for k in g.Pfx.DUR:
		check(g.Sfx.S.has("fx_" + k), "a sound for " + k)
	check(g.Sfx.S.has("arm"), "a sound for arming")
	g.p.relics = []
	g.calc_stats()
	# the dummy is never cut
	var d = g.spawn_enemy("dummy", c + Vector2(0, -50))
	var dh = d.hp
	g.hurt_enemy(d, 10.0, "", Vector2.ZERO, true)
	check(absf(dh - d.hp - 10.0) < 0.5, "the dummy shows full numbers")
	print("INF OK" if fails == 0 else "INF FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
