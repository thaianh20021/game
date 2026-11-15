extends RefCounted
# Things that make the player move and use the charged dash (owner, 2026-11-15: "monotonous").
#
#   objectives  a trial room is not "kill everything": HOLD a circle, HUNT a courier, SURVIVE a
#               barrage, or beat a CHAMPION (an elite with two affixes). Winning pays.
#   affixes     ordinary foes can be WARDED (only a release breaks the ward), a LEECH (drinks
#               your charges up close), a MARKSMAN (aims a line you must dash out of) or a
#               BROOD (splits if left alive).
#   armor       a boss wears armor: everything but a release is cut down; releases break it,
#               and a boss with broken armor is stunned and takes double damage for a while.
#   slam        a foe knocked hard into a wall is hurt and stunned.
#
# Numbers are in D.STAGE. Host-side only; guests see the marks through the enemy snapshot.

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")
const Px = preload("res://src/font.gd")

const GOAL = {
	"hold": ["HOLD THE CIRCLE", "STAND IN IT UNTIL IT FILLS"],
	"hunt": ["HUNT THE COURIER", "IT RUNS. CATCH IT BEFORE IT GETS AWAY"],
	"survive": ["SURVIVE", "KEEP MOVING. THE SKY IS FALLING"],
	"champion": ["CHAMPION", "ONE FOE, TWO GIFTS"],
	"escort": ["ESCORT THE CORE", "IT MOVES WHILE YOU STAND BY IT"],
	"dark": ["LIGHTS OUT", "A RELEASE LIGHTS THE ROOM"],
}
const AFFIX = {
	"ward": ["WARDED", Color("5cd3f2")],
	"leech": ["LEECH", Color("c57bff")],
	"mark": ["MARKSMAN", Color("ff5a6a")],
	"brood": ["BROOD", Color("a6e84e")],
	"mirror": ["MIRROR", Color("ffd24a")],
}

# ---- affixes ---------------------------------------------------------------------

# Called for every foe that spawns in a locked room (after Twist.mark).
static func mark(g, e: Dictionary) -> void:
	if g.lock != null and g.lock.get("sc_over", false) and not e.is_boss:
		# the objective is over: stragglers that were already on their way fall at once
		g.after(0.05, func(): g.kill(e))
		return
	if e.is_boss or e.d.ai == "dummy" or g.in_lobby:
		return
	if e.elite:
		if g.lock != null and g.lock.get("sc", "") == "champion":
			var ks = AFFIX.keys()
			ks.shuffle()
			for k in ks.slice(0, 2):
				affix(g, e, k)
		else:
			# every other elite drinks your reactions and gives them back
			affix(g, e, "mirror")
		return
	if g.floor_i < 1 or e.has("eats") or g.rng.randf() > D.STAGE.affix + D.STAGE.affix_floor * g.floor_i:
		return
	var plain = AFFIX.keys().filter(func(k): return k != "mirror")
	affix(g, e, plain[g.rng.randi() % plain.size()])

static func affix(g, e: Dictionary, k: String) -> void:
	var l: Array = e.get("afx", [])
	if l.has(k):
		return
	l.append(k)
	e.afx = l
	match k:
		"ward": e.ward = true
		"leech": e.leech_t = 1.0
		"mark": e.aim_t = g.rng.randf_range(1.5, 3.0)
		"brood": e.brood_t = D.STAGE.brood
		"mirror": e.mir = 0

# A reaction went off at c: mirrors close by drink it; three, and they release it back.
static func on_react(g, c: Vector2, col: Color) -> void:
	for e in g.enemies:
		if e.dead or not e.has("mir") or e.has("mir_t") or g.center(e).distance_to(c) > D.STAGE.mirror_r:
			continue
		e.mir += 1
		e.mir_col = col
		g.bolt(c, g.center(e), col)
		g.label(g.center(e) + Vector2(0, -e.h2 - 16.0), "DRINKS %d/%d" % [e.mir, D.STAGE.mirror_n], AFFIX.mirror[1])
		g.tip("mirror", "MIRROR", "IT DRINKS REACTIONS NEAR IT. AT THREE IT RELEASES THEM. KILL IT OR GET CLEAR.")
		if e.mir >= D.STAGE.mirror_n:
			e.mir_t = D.STAGE.mirror_wait
			g.tele_circle(g.center(e), D.STAGE.mirror_blast, D.STAGE.mirror_wait)
			Sfx.play("warn", 0.7)

# What a hit really does, after everything else. rel is true for a release (ring, lance or one
# of its shots).
static func amount(g, e: Dictionary, amt: float, rel: bool) -> float:
	if e.get("ward", false):
		if rel:
			e.ward = false
			g.label(g.center(e) + Vector2(0, -e.h2 - 16.0), "WARD BROKEN", AFFIX.ward[1], true)
			g.burst(g.center(e), 14, AFFIX.ward[1], 120.0, 0.4)
			g.rings.append({pos = g.center(e), r = e.hr + 12.0, t = 0.0, col = AFFIX.ward[1]})
			Sfx.play("freeze", 1.5)
		else:
			amt *= D.STAGE.ward
			g.tip("ward", "WARDED", "ITS WARD SHRUGS OFF HITS. A CHARGED DASH BREAKS IT.")
	if e.is_boss and e.d.ai != "dummy":
		if not e.has("arm"):
			e.arm = D.STAGE.arm
		if e.has("seal"):
			if rel and g.rel_shape == e.seal:
				e.erase("seal")
				e.erase("seal_t")
				e.arm = 0.0
				e.brk = D.STAGE.brk_t * 1.5
				e.cc_free = 0.0
				e.stun = maxf(e.stun, D.STAGE.brk_t * 1.5)
				g.label(g.center(e) + Vector2(0, -e.h2 - 20.0), "SEAL BROKEN", Color("ffd24a"), true)
				g.burst(g.center(e), 30, Color("ffd24a"), 180.0, 0.6)
				g.hitstop = maxf(g.hitstop, 0.15)
				g.shake_add(8.0)
				Sfx.play("boom", 0.6)
			else:
				return amt * D.STAGE.seal
		if float(e.get("brk", 0.0)) > 0.0:
			amt *= D.STAGE.brk
		elif e.arm > 0.0:
			if rel:
				e.arm -= D.STAGE.arm_hit * float(g.st.get("inf_sunder", 1.0))
				if e.arm <= 0.0:
					e.arm = 0.0
					e.brk = D.STAGE.brk_t
					e.cc_free = 0.0
					e.stun = maxf(e.stun, D.STAGE.brk_t)
					g.label(g.center(e) + Vector2(0, -e.h2 - 20.0), "ARMOR BROKEN", Color("ffd24a"), true)
					g.burst(g.center(e), 24, Color("ffd24a"), 160.0, 0.5)
					g.hitstop = maxf(g.hitstop, 0.12)
					g.shake_add(7.0)
					Sfx.play("boom", 0.7)
					g.tip("armor", "ARMOR BROKEN", "IT IS STUNNED AND TAKES DOUBLE DAMAGE. STRIKE NOW.")
				else:
					g.label(g.center(e) + Vector2(0, -e.h2 - 20.0), "ARMOR CRACKS", Color("a8a7b8"))
			else:
				amt *= D.STAGE.arm_cut
	return amt

# Per-foe upkeep, every frame (before the foe acts).
static func tick_foe(g, e: Dictionary, dt: float) -> void:
	if e.has("slam_cd"):
		e.slam_cd -= dt
	if e.has("brk"):
		e.brk -= dt
		if e.brk <= 0.0:
			e.erase("brk")
			e.arm_t = D.STAGE.arm_back
	if e.is_boss and e.d.ai != "dummy" and not e.get("nem", false) and not e.has("sealed") and e.hp < e.mhp * 0.5 and e.hp > 0.0 and not g.in_lobby:
		# half way down it seals itself: only the asked release breaks the seal early
		e.sealed = true
		e.seal = "pure" if g.rng.randf() < 0.5 else "trinity"
		e.seal_t = D.STAGE.seal_t
		g.banner = {text = "SEALED", sub = "THREE EQUAL CHARGES BREAK IT" if e.seal == "pure" else "THREE DIFFERENT CHARGES BREAK IT", t = 3.0}
		g.rings.append({pos = g.center(e), r = e.hr + 24.0, t = 0.0, col = Color("c57bff")})
		Sfx.play("roar", 1.4)
	if e.has("seal_t"):
		e.seal_t -= dt
		if e.seal_t <= 0.0:
			e.erase("seal")
			e.erase("seal_t")
			g.label(g.center(e) + Vector2(0, -e.h2 - 20.0), "SEAL FADES", Color("a8a7b8"))
	if e.has("arm_t"):
		e.arm_t -= dt
		if e.arm_t <= 0.0:
			e.erase("arm_t")
			e.arm = D.STAGE.arm
			g.label(g.center(e) + Vector2(0, -e.h2 - 20.0), "ARMOR RESTORED", Color("a8a7b8"))
	if e.has("mir_t"):
		# nothing stops a mirror that has begun: only killing it does
		e.mir_t -= dt
		if e.mir_t <= 0.0:
			e.erase("mir_t")
			e.mir = 0
			var mc: Vector2 = g.center(e)
			var mcol: Color = e.get("mir_col", AFFIX.mirror[1])
			g.explode(mc, D.STAGE.mirror_blast, 1.0, "", 1, mcol)
			for i in 12:
				g.add_bullet(mc, Vector2.from_angle(i * TAU / 12.0 + g.time) * 95.0, {team = 1, el = e.el, r = 3.0, life = 3.0, dmg = 1})
			g.Pfx.spawn(g, "radiance", mc, D.STAGE.mirror_blast)
			g.label(mc + Vector2(0, -e.h2 - 16.0), "RELEASES", AFFIX.mirror[1], true)
			g.shake_add(4.0)
	if not e.has("afx") or e.frz > 0.0 or e.stun > 0.0 or e.born > 0.0:
		return
	if e.has("leech_t"):
		e.leech_t -= dt
		if e.leech_t <= 0.0:
			e.leech_t = 0.3
			for pl in g.players:
				if pl.get("down", false) or pl.get("inf", []).is_empty() or pl.pos.distance_to(e.pos) > D.STAGE.leech_r:
					continue
				pl.inf.pop_back()
				e.hp = minf(e.mhp, e.hp + e.mhp * 0.15)
				e.leech_t = D.STAGE.leech_cd
				g.bolt(pl.pos + Vector2(0, -6), g.center(e), AFFIX.leech[1])
				g.label(g.center(e) + Vector2(0, -e.h2 - 16.0), "DRINKS A CHARGE", AFFIX.leech[1])
				Sfx.play("deny", 0.8)
				g.tip("leech", "LEECH", "IT DRINKS YOUR CHARGES UP CLOSE. RELEASE BEFORE IT REACHES YOU.")
				break
	if e.has("aim_t"):
		e.aim_t -= dt
		if e.has("aim"):
			# the line follows you, then locks for the last moment
			if e.aim_t > D.STAGE.aim_lock:
				var pl = g.target_for(e.pos)
				e.aim = (pl.pos + Vector2(0, -4) - g.center(e)).normalized()
			if e.aim_t <= 0.0:
				g.add_bullet(g.center(e), e.aim * D.STAGE.aim_speed, {team = 1, el = e.el, r = 3.0, life = 1.4, dmg = 1})
				g.bolts.append({a = g.center(e), b = g.center(e) + e.aim * 60.0, col = AFFIX.mark[1], t = 0.12, straight = true})
				Sfx.play("shoot", 0.6)
				e.erase("aim")
				e.aim_t = g.rng.randf_range(D.STAGE.aim_cd, D.STAGE.aim_cd + 1.5)
		elif e.aim_t <= 0.0:
			e.aim = Vector2.RIGHT
			e.aim_t = D.STAGE.aim_wind
			g.tip("mark", "MARKSMAN", "A RED LINE MEANS A FAST SHOT. DASH OUT OF IT.")
	if e.has("brood_t"):
		e.brood_t -= dt
		if e.brood_t <= 0.0:
			e.erase("brood_t")
			if g.lock != null and g.enemies.size() < D.DIFF.cap:
				e.afx.erase("brood")
				var o = g.spawn_enemy(e.id, e.pos + Vector2(g.rng.randf_range(-10, 10), g.rng.randf_range(-6, 6)))
				o.hp = e.hp
				o.mhp = e.mhp
				o.el = e.el
				g.label(g.center(e) + Vector2(0, -e.h2 - 16.0), "SPLITS", AFFIX.brood[1])
				g.burst(e.pos, 10, AFFIX.brood[1], 80.0, 0.4)
				Sfx.play("deny", 1.3)
				g.tip("brood", "BROOD", "IT SPLITS IF YOU LEAVE IT ALIVE. KILL IT FIRST.")

# The courier of a hunt runs instead of fighting. Returns true if it moved the foe.
static func drive(g, e: Dictionary, dt: float) -> bool:
	if not e.get("courier", false):
		return false
	var pl = g.target_for(e.pos)
	var away: Vector2 = e.pos - pl.pos
	var d = away.length()
	var want: Vector2 = away.normalized() if d > 1.0 else Vector2.RIGHT
	if d > 110.0:
		want = e.get("run", want) * 0.4
	# along the wall rather than into it
	var run: Vector2 = e.get("run", want)
	run = run.lerp(want, minf(1.0, dt * 6.0)).normalized() if want.length() > 0.5 else run
	var before: Vector2 = e.pos
	if g.move(e, run * D.STAGE.courier_spd * dt) and e.pos.distance_to(before) < D.STAGE.courier_spd * dt * 0.5:
		run = run.rotated(PI * 0.5 * (1.0 if e.uid % 2 == 0 else -1.0))
	e.run = run
	e.face = 1 if run.x >= 0.0 else -1
	return true

# A foe thrown hard into a wall.
static func slam(g, e: Dictionary) -> void:
	if e.dead or e.is_boss or float(e.get("slam_cd", 0.0)) > 0.0 or e.d.ai == "dummy":
		return
	e.slam_cd = 0.6
	var c: Vector2 = g.center(e)
	g.full_hit = true
	g.hurt_enemy(e, (D.STAGE.slam + D.STAGE.slam_floor * g.floor_i) * minf(2.0, e.kb.length() / D.STAGE.slam_v), "", Vector2.ZERO, true, Color.WHITE)
	g.full_hit = false
	g.Pfx.spawn(g, "slam", e.pos, 22.0, e.kb.angle())
	e.kb = Vector2.ZERO
	if not e.dead:
		e.stun = maxf(e.stun, 0.35)
	g.label(c + Vector2(0, -e.h2 - 10.0), "SLAM", Color.WHITE)
	g.tally("slam")
	g.burst(c, 8, Color.WHITE, 90.0, 0.3)
	g.shake_add(2.5)
	Sfx.play("hit", 0.6)

# ---- objectives ------------------------------------------------------------------

static func lock_room(g, r: Dictionary) -> void:
	if not r.get("trial", false) or r.type != "fight":
		return
	var ks = GOAL.keys()
	r.sc = ks[g.rng.randi() % ks.size()]
	r.sc_t = 0.0
	r.sc_spawn = 2.5
	r.sc_tick = 1.5
	r.sc_over = false
	r.sc_win = false
	r.prog = 0.0
	g.banner = {text = GOAL[r.sc][0], sub = GOAL[r.sc][1], t = 3.0}
	match r.sc:
		"hold":
			r.goal = D.STAGE.hold
		"escort":
			r.goal = D.STAGE.escort
		"dark":
			r.goal = 0.0
			r.mod = "dark"
		"survive":
			r.goal = D.STAGE.survive
		"hunt":
			r.goal = D.STAGE.hunt
			var roster: Array = D.BIOMES[g.floor_i / 2].roster
			var pos: Vector2 = g.random_room_pos(r, 70.0)
			g.pending += 1
			g.teles.append({kind = "spawn", pos = pos, t = 0.0, dur = 0.8, r = 7.0})
			g.after(0.8, func():
				g.pending -= 1
				var e = g.spawn_enemy(roster[0], pos)
				e.courier = true
				e.mhp *= D.STAGE.courier_hp
				e.hp = e.mhp
				g.label(pos + Vector2(0, -26), "COURIER", Color("ffd24a"), true))
		"champion":
			r.waves = 1
			r.goal = 0.0
			var roster: Array = D.BIOMES[g.floor_i / 2].roster
			g.spawn_tele(roster[g.rng.randi() % roster.size()], g.random_room_pos(r, 70.0), 1.1, true)

# True while the room must not clear or send its next wave on its own.
static func busy(g) -> bool:
	var r = g.lock
	return r != null and r.get("sc", "") in ["hold", "survive", "hunt", "escort"] and not r.sc_over

# Where the circle of a hold or an escort is now.
static func core(g, r: Dictionary) -> Vector2:
	var c: Vector2 = g.rc(r)
	if r.sc != "escort":
		return c
	var half = Vector2(r.rect.size.x * 16.0 * 0.3, 0.0)
	return (c - half).lerp(c + half, clampf(r.prog / r.goal, 0.0, 1.0))

static func update(g, dt: float) -> void:
	g.lit_t = maxf(0.0, g.lit_t - dt)
	var r = g.lock
	if r == null or r.get("sc", "") == "":
		return
	if r.sc_over:
		# whatever the dying leave behind (halves of a split foe, late arrivals) falls too
		if float(r.get("sc_sweep", 0.0)) > 0.0:
			r.sc_sweep -= dt
			sweep(g)
		return
	r.sc_t += dt
	var c: Vector2 = core(g, r)
	match r.sc:
		"hold", "escort":
			var inside = false
			for pl in g.players:
				if not pl.get("down", false) and pl.pos.distance_to(c) < D.STAGE.hold_r:
					inside = true
			if inside:
				r.prog += dt
			feed(g, r, dt)
			if r.prog >= r.goal:
				finish(g, r, true)
			elif r.sc_t > D.STAGE.hold_out:
				finish(g, r, false)
		"survive":
			r.prog = r.sc_t
			feed(g, r, dt)
			r.sc_tick -= dt
			if r.sc_tick <= 0.0:
				r.sc_tick = maxf(0.55, D.STAGE.rain - 0.03 * r.sc_t)
				for pl in g.players:
					if pl.get("down", false):
						continue
					var at: Vector2 = pl.pos + pl.get("v", Vector2.ZERO) * 0.5 + Vector2(g.rng.randf_range(-14, 14), g.rng.randf_range(-14, 14))
					g.tele_circle(at, D.STAGE.rain_r, 0.8)
					g.after(0.8, func():
						if g.lock == r:
							g.explode(at, D.STAGE.rain_r, 1.0, "", 1, Color("ff5a6a")))
			if r.prog >= r.goal:
				finish(g, r, true)
		"hunt":
			r.prog = r.sc_t
			var courier = null
			for e in g.enemies:
				if e.get("courier", false) and not e.dead:
					courier = e
			if courier == null and r.sc_t > 1.0 and g.pending == 0:
				finish(g, r, true)
			elif r.sc_t >= r.goal and courier != null:
				g.burst(courier.pos, 12, Color("ffd24a"), 90.0, 0.4)
				g.label(courier.pos + Vector2(0, -20), "IT GOT AWAY", Color("ff6a6a"), true)
				g.enemies.erase(courier)
				finish(g, r, false)

# Hold and survive keep foes coming.
static func feed(g, r: Dictionary, dt: float) -> void:
	r.sc_spawn -= dt
	if r.sc_spawn > 0.0:
		return
	r.sc_spawn = D.STAGE.feed
	if g.enemies.size() + g.pending >= D.STAGE.feed_cap + g.floor_i:
		return
	var roster: Array = D.BIOMES[g.floor_i / 2].roster
	for i in 2:
		g.spawn_tele(roster[g.rng.randi() % roster.size()], g.random_room_pos(r, 60.0))

static func finish(g, r: Dictionary, win: bool) -> void:
	r.sc_over = true
	r.sc_win = win
	if win:
		g.tally("obj")
	if r.sc in ["hold", "survive", "escort"] or (r.sc == "hunt" and win):
		# the objective ends the fight: whatever is left falls
		r.wave = r.waves
		r.sc_sweep = 1.5
		sweep(g)
	g.label(g.rc(r) + Vector2(0, -30), "OBJECTIVE DONE" if win else "OBJECTIVE LOST", Color("ffd24a") if win else Color("ff6a6a"), true)
	Sfx.play("pick" if win else "deny")
	if win and r.sc == "hunt":
		g.drop("key", g.p.pos, 1)

static func sweep(g) -> void:
	for e in g.enemies.duplicate():
		if not e.dead and not e.is_boss and not e.get("nem", false):
			g.kill(e)

# Called when a room clears. True if it should pay a relic.
static func reward(g, r: Dictionary) -> bool:
	if r.get("sc", "") == "":
		return false
	if r.sc in ["champion", "dark"]:
		r.sc_win = true
	if not r.sc_win:
		return false
	g.drop("coin", g.rc(r), 8)
	return g.rng.randf() < D.STAGE.relic

# ---- drawing ---------------------------------------------------------------------

static func draw(g, ci: CanvasItem) -> void:
	var r = g.lock
	if r == null or not (r.get("sc", "") in ["hold", "escort"]) or r.sc_over:
		return
	var c: Vector2 = core(g, r)
	if r.sc == "escort":
		# the way it will go, and the core itself
		var half = Vector2(r.rect.size.x * 16.0 * 0.3, 0.0)
		var mid: Vector2 = g.rc(r)
		for i in 12:
			ci.draw_rect(Rect2(mid - half + half * 2.0 * i / 11.0 - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.82, 0.3, 0.35))
		var bob = Vector2(0, -6.0 + sin(g.time * 4.0) * 2.0)
		ci.draw_colored_polygon(PackedVector2Array([c + bob + Vector2(0, -6), c + bob + Vector2(5, 0), c + bob + Vector2(0, 6), c + bob + Vector2(-5, 0)]), Color("ffd24a"))
		ci.draw_colored_polygon(PackedVector2Array([c + bob + Vector2(0, -3), c + bob + Vector2(2, 0), c + bob + Vector2(0, 3), c + bob + Vector2(-2, 0)]), Color.WHITE)
	var k = clampf(r.prog / r.goal, 0.0, 1.0)
	var rad: float = D.STAGE.hold_r
	ci.draw_circle(c, rad, Color(1.0, 0.82, 0.3, 0.07))
	ci.draw_arc(c, rad, 0.0, TAU, 40, Color(1.0, 0.82, 0.3, 0.35), 1.0)
	ci.draw_arc(c, rad, -PI / 2.0, -PI / 2.0 + TAU * k, 40, Color("ffd24a"), 2.0)
	for i in 8:
		var a = g.time * 0.6 + i * TAU / 8.0
		ci.draw_rect(Rect2(c + Vector2.from_angle(a) * rad - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.9, 0.6, 0.8))

static func draw_foe(g, ci: CanvasItem, e: Dictionary, topy: float) -> void:
	var c: Vector2 = g.center(e)
	if e.get("courier", false):
		var y = topy - 10.0 + sin(g.time * 8.0) * 1.5
		ci.draw_colored_polygon(PackedVector2Array([Vector2(e.pos.x, y - 5), Vector2(e.pos.x + 4, y), Vector2(e.pos.x, y + 5), Vector2(e.pos.x - 4, y)]), Color("ffd24a"))
		ci.draw_rect(Rect2(e.pos.x - 1, y - 1, 2, 2), Color("16121d"))
	if e.has("seal"):
		var sa = g.time * 1.5
		for i in 6:
			ci.draw_arc(c, e.hr + 10.0, sa + i * TAU / 6.0, sa + i * TAU / 6.0 + 0.7, 6, Color("c57bff"), 2.0)
	if not e.has("afx"):
		return
	var x = e.pos.x - (e.afx.size() - 1) * 5.0
	for k in e.afx:
		var col: Color = AFFIX[k][1]
		var at = Vector2(roundf(x), roundf(topy - 9.0))
		match k:
			"ward":
				if e.get("ward", false):
					var a = g.time * 2.0
					for i in 3:
						ci.draw_arc(c, e.hr + 5.0, a + i * TAU / 3.0, a + i * TAU / 3.0 + 1.4, 8, col, 1.5)
					ci.draw_arc(at, 3.0, 0.0, TAU, 8, col, 1.0)
				else:
					ci.draw_arc(at, 3.0, 0.3, 2.2, 5, Color(col.r, col.g, col.b, 0.4), 1.0)
			"leech":
				ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-3, -3), at + Vector2(3, -3), at + Vector2(0, 4)]), col)
				ci.draw_rect(Rect2(at + Vector2(-1, -2), Vector2(2, 2)), Color.WHITE)
			"mark":
				ci.draw_arc(at, 3.0, 0.0, TAU, 8, col, 1.0)
				ci.draw_line(at + Vector2(-5, 0), at + Vector2(5, 0), col, 1.0)
				ci.draw_line(at + Vector2(0, -5), at + Vector2(0, 5), col, 1.0)
			"brood":
				var bk = 1.0 - clampf(float(e.get("brood_t", 0.0)) / D.STAGE.brood, 0.0, 1.0)
				ci.draw_circle(at + Vector2(-2, 0), 2.0, col)
				ci.draw_circle(at + Vector2(2, 0), 2.0, Color(col.r, col.g, col.b, 0.3 + 0.7 * bk))
			"mirror":
				for i in D.STAGE.mirror_n:
					var on = i < int(e.get("mir", 0))
					var mp = at + Vector2(-5 + i * 5, 0)
					ci.draw_rect(Rect2(mp - Vector2(2, 2), Vector2(4, 4)), Color("16121d"))
					ci.draw_rect(Rect2(mp - Vector2(1, 1), Vector2(2, 2)), (e.get("mir_col", col) if on else Color(col.r, col.g, col.b, 0.3)))
				if e.has("mir_t") and int(g.time * 12.0) % 2 == 0:
					ci.draw_arc(c, e.hr + 6.0, 0.0, TAU, 16, col, 2.0)
		x += 10.0
	if e.has("aim"):
		# the marksman's line: thin while it tracks, bright once it has locked
		var locked = e.aim_t <= D.STAGE.aim_lock
		var far: Vector2 = c + e.aim * 260.0
		ci.draw_line(c, far, Color(1.0, 0.35, 0.42, 0.9 if locked else 0.35), 2.0 if locked else 1.0)

# The objective and its progress, under the top of the HUD sheet.
static func draw_hud(g, ci: CanvasItem) -> void:
	var r = g.lock
	if g.in_lobby or g.state != "play" or r == null or r.get("sc", "") == "" or r.sc_over or g.banner.t > 0.0:
		return
	Px.ctext(ci, Vector2(240, 44), GOAL[r.sc][0], Color("ffd24a"))
	if r.goal <= 0.0:
		return
	var k = clampf(r.prog / r.goal, 0.0, 1.0)
	if r.sc == "hunt":
		k = 1.0 - k
	ci.draw_rect(Rect2(199, 54, 82, 5), Color("16121d"))
	ci.draw_rect(Rect2(200, 55, 80.0 * k, 3), Color("ff6a6a") if (r.sc == "hunt" and k < 0.3) else Color("ffd24a"))
