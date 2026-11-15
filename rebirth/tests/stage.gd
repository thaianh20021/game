extends SceneTree
# Objectives, affixes, boss armor and wall slams.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Stage = preload("res://src/stage.gd")
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
func safe():
	g.p.hp = g.p.mhp
	g.p.inv = 9.0
func room_for(sc):
	# a fresh fight room, locked with the wanted objective
	g.enemies.clear()
	g.bullets.clear()
	g.teles.clear()
	g.timers.clear()
	g.pending = 0
	g.lock = null
	var r = null
	for q in g.dg.rooms:
		if q.type == "fight" and (r == null or not q.cleared):
			r = q
	r.cleared = false
	r.trial = true
	for k in 200:
		for key in ["sc", "sc_t", "sc_over", "sc_win", "prog", "goal"]:
			r.erase(key)
		Stage.lock_room(g, r)
		if r.sc == sc:
			break
		g.timers.clear()
		g.teles.clear()
		g.pending = 0
	g.enemies.clear()
	g.lock = r
	for gt in r.gates:
		g.dg.grid[gt.y * g.dg.w + gt.x] = 2
	r.wave = 1
	return r
func _init():
	Meta.PATH = "user://rebirth_stage.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.start_run(5, false)
	g.floor_i = 2
	g.new_floor()
	await frames(5)
	g.st.crit = 0.0
	var room = null
	for r in g.dg.rooms:
		if r.type == "fight":
			room = r
			break
	room.cleared = true
	var c: Vector2 = g.rc(room)
	g.p.pos = c + Vector2(-70, 20)
	g.enemies.clear()

	# ---- affixes ----
	var n = 0
	g.lock = null
	for i in 600:
		var t = {is_boss = false, elite = false, d = {ai = "walk"}}
		Stage.mark(g, t)
		if t.has("afx"):
			n += 1
	check(n > 40 and n < 180, "some foes carry an affix: %d of 600" % n)
	var w = foe(c)
	Stage.affix(g, w, "ward")
	g.hurt_enemy(w, 100.0, "")
	check(absf((1000.0 - w.hp) - 100.0 * g.st.dmg * D.STAGE.ward) < 1.0 and w.ward, "a ward shrugs off a hit: %.1f" % (1000.0 - w.hp))
	w.hp = 1000.0
	g.rel_hit = true
	g.hurt_enemy(w, 100.0, "", Vector2.ZERO, true)
	g.rel_hit = false
	check(not w.ward and 1000.0 - w.hp > 25.0, "a release breaks it")
	g.enemies.clear()
	var l = foe(g.p.pos + Vector2(20, 0))
	l.stun = 0.0
	l.hp = 500.0
	Stage.affix(g, l, "leech")
	g.p.inf = [{key = "fire+ice", col = Color.WHITE}, {key = "fire+ice", col = Color.WHITE}]
	l.leech_t = 0.0
	for k in 6:
		l.pos = g.p.pos + Vector2(20, 0)
		safe()
		await frames(1)
	check(g.p.inf.size() == 1 and l.hp > 500.0, "a leech drinks one charge and heals: %d %.0f" % [g.p.inf.size(), l.hp])
	g.p.inf = []
	g.enemies.clear()
	var m = foe(g.p.pos + Vector2(80, 0))
	m.stun = 0.0
	Stage.affix(g, m, "mark")
	m.aim_t = 0.0
	var shot = false
	for k in int((D.STAGE.aim_wind + 0.3) * 30):
		m.t = 9.0
		safe()
		await frames(1)
		if g.bullets.any(func(b): return b.team == 1 and b.vel.length() > 300.0):
			shot = true
	check(shot and not m.has("aim"), "a marksman aims, then fires a fast shot")
	g.enemies.clear()
	g.bullets.clear()
	var b2 = foe(c)
	b2.stun = 0.0
	Stage.affix(g, b2, "brood")
	b2.brood_t = 0.05
	g.lock = room
	safe()
	await frames(4)
	check(g.enemies.size() == 2 and not b2.afx.has("brood"), "a brood splits once: %d" % g.enemies.size())
	g.lock = null
	g.enemies.clear()

	# ---- slam ----
	var s = foe(c)
	var wall = Vector2.ZERO
	for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		for k in range(1, 30):
			if not g.box_free(c + d * k * 8.0, s.r):
				wall = d
				s.pos = c + d * (k - 1) * 8.0
				break
		if wall != Vector2.ZERO:
			break
	s.kb = wall * 400.0
	await frames(6)
	check(1000.0 - s.hp > D.STAGE.slam, "a foe thrown into a wall is hurt: %.1f" % (1000.0 - s.hp))
	g.enemies.clear()

	# ---- boss armor ----
	var boss = g.spawn_enemy(g.dg.boss_id, c)
	boss.born = 0.0
	boss.stun = 99.0
	var h0 = boss.hp
	g.hurt_enemy(boss, 100.0, "")
	check(absf((h0 - boss.hp) - 100.0 * g.st.dmg * D.STAGE.arm_cut) < 1.0, "armor cuts ordinary hits: %.1f" % (h0 - boss.hp))
	g.rel_hit = true
	for k in 3:
		g.hurt_enemy(boss, 1.0, "", Vector2.ZERO, true)
	g.rel_hit = false
	check(boss.arm == 0.0 and boss.get("brk", 0.0) > 0.0, "three release layers break it")
	h0 = boss.hp
	g.hurt_enemy(boss, 100.0, "")
	check(absf((h0 - boss.hp) - 100.0 * g.st.dmg * D.STAGE.brk) < 1.0, "a broken boss takes double: %.1f" % (h0 - boss.hp))
	g.hitstop = 0.0
	boss.brk = 0.05
	await frames(4)
	boss.arm_t = 0.05
	boss.stun = 99.0
	await frames(4)
	check(boss.arm == D.STAGE.arm and not boss.has("brk"), "armor grows back")
	g.enemies.clear()
	g.boss = null

	# ---- objectives ----
	var seen = {}
	var rr = null
	for q in g.dg.rooms:
		if q.type == "fight" and not q.cleared:
			rr = q
			break
	rr.trial = true
	for k in 80:
		Stage.lock_room(g, rr)
		seen[rr.sc] = true
		g.timers.clear()
		g.teles.clear()
		g.pending = 0
	check(seen.size() == 6, "six objectives: " + str(seen.keys()))
	g.enemies.clear()

	var r = room_for("hold")
	g.p.pos = g.rc(r) + Vector2(60, 0)
	safe()
	await frames(30)
	check(r.prog == 0.0 and Stage.busy(g) and not r.cleared, "hold: nothing fills outside the circle")
	g.p.pos = g.rc(r)
	var k2 = 0
	while not r.cleared and k2 < int((D.STAGE.hold + 4.0) * 30):
		g.p.pos = g.rc(r)
		safe()
		await frames(1)
		k2 += 1
	check(r.cleared and r.sc_win, "hold: standing in it wins and clears the room" + " prog %.1f over %s enemies %d pending %d wave %d/%d lock %s" % [r.prog, str(r.sc_over), g.enemies.size(), g.pending, r.wave, r.waves, str(g.lock != null)])

	r = room_for("survive")
	g.p.pos = g.rc(r)
	var rained = false
	k2 = 0
	while not r.cleared and k2 < int((D.STAGE.survive + 4.0) * 30):
		safe()
		rained = rained or g.teles.any(func(t): return t.kind == "circle")
		await frames(1)
		k2 += 1
	check(rained and r.cleared and r.sc_win, "survive: blasts fall, then the timer wins")

	r = room_for("hunt")
	g.p.pos = g.rc(r)
	g.timers.clear()
	g.pending = 0
	g.teles.clear()
	var cr = foe(g.rc(r) + Vector2(30, 0))
	cr.stun = 0.0
	cr.courier = true
	var p0: Vector2 = cr.pos
	for k in 20:
		safe()
		await frames(1)
	check(cr.pos.distance_to(g.p.pos) > p0.distance_to(g.p.pos) and Stage.busy(g), "hunt: the courier runs from you")
	g.kill(cr)
	g.enemies.clear()
	for k in 40:
		safe()
		await frames(1)
	check(r.sc_win and r.cleared, "hunt: catching it wins")
	r = room_for("hunt")
	g.p.pos = g.rc(r)
	g.timers.clear()
	g.pending = 0
	g.teles.clear()
	cr = foe(g.rc(r) + Vector2(30, 0))
	cr.courier = true
	r.sc_t = D.STAGE.hunt - 0.1
	for k in 10:
		safe()
		await frames(1)
	check(r.sc_over and not r.sc_win and not g.enemies.has(cr), "hunt: or it gets away")

	r = room_for("champion")
	check(not Stage.busy(g) and r.waves == 1, "champion: an ordinary single wave")
	var ch = foe(g.rc(r))
	ch.elite = true
	Stage.mark(g, ch)
	check(ch.get("afx", []).size() == 2, "champion: the elite has two affixes: " + str(ch.get("afx", [])))
	r = room_for("escort")
	var e0: Vector2 = Stage.core(g, r)
	g.p.pos = e0
	var kk = 0
	while not r.cleared and kk < int((D.STAGE.escort + 4.0) * 30):
		g.p.pos = Stage.core(g, r)
		safe()
		await frames(1)
		kk += 1
	check(r.cleared and r.sc_win and Stage.core(g, r).distance_to(e0) > 40.0, "escort: walking beside the core carries it across")

	r = room_for("dark")
	check(not Stage.busy(g) and r.mod == "dark", "dark: an ordinary fight in the dark")
	g.lit_t = 0.0
	g.p.pos = g.rc(r)
	g.p.inf = [{key = "fire+ice", col = Color.WHITE}]
	g.p.dash_cd = 0.0
	g.sim[KEY_D] = true
	for k in 12:
		if not g.p.get("inf", []).is_empty():
			g.p.inf_arm = 2.0
		g.jp[KEY_SPACE] = true
		await frames(1)
		if g.p.dash_t > 0.0:
			break
	g.sim.erase(KEY_D)
	await frames(10)
	check(g.lit_t > 0.0, "dark: a release lights the room")
	g.enemies.clear()
	g.lock = null

	# ---- the seal ----
	var sb = g.spawn_enemy(g.dg.boss_id, g.p.pos + Vector2(60, 0))
	sb.born = 0.0
	sb.stun = 99.0
	sb.hp = sb.mhp * 0.4
	safe()
	await frames(3)
	check(sb.has("seal") and sb.seal in ["pure", "trinity"], "a boss seals itself at half health")
	var sh0 = sb.hp
	g.rel_hit = true
	g.rel_shape = "trinity" if sb.seal == "pure" else "pure"
	g.hurt_enemy(sb, 100.0, "", Vector2.ZERO, true)
	check(sb.has("seal") and sh0 - sb.hp < 100.0 * D.STAGE.seal + 1.0, "the wrong release barely scratches it: %.1f" % (sh0 - sb.hp))
	g.rel_shape = sb.seal
	g.hurt_enemy(sb, 100.0, "", Vector2.ZERO, true)
	g.rel_hit = false
	g.rel_shape = ""
	check(not sb.has("seal") and sb.get("brk", 0.0) > 0.0, "the asked release breaks the seal")
	g.hitstop = 0.0
	g.enemies.clear()
	var sb2 = g.spawn_enemy(g.dg.boss_id, g.p.pos + Vector2(60, 0))
	sb2.born = 0.0
	sb2.stun = 99.0
	sb2.hp = sb2.mhp * 0.4
	await frames(3)
	sb2.seal_t = 0.05
	sb2.stun = 99.0
	await frames(4)
	check(not sb2.has("seal") and sb2.sealed, "or it fades by itself, once")
	g.enemies.clear()
	await frames(5)
	print("STAGE OK" if fails == 0 else "STAGE FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
