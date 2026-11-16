extends RefCounted
# The fourth zone, the Storm Spire, and its last boss, the Tempest Loom (owner, 2026-11-16).
#
# The Loom weaves the weather. It has four phases (D.SPIRE.phases): at the start of each it
# sets the floor's weather and draws a weave around itself that turns away nine tenths of every
# hit, weather included. Only a storm (a three-element field) that goes off close to it tears
# the weave; then it is stunned and takes more for a while. A weave that is never torn frays by
# itself after D.SPIRE.weave_t seconds, so nobody is stuck.
#
# Its three attacks: rows of thread with a gap to slip through, strikes of the current
# weather's element on marked circles, and a shuttle spiral.

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")
const Px = preload("res://src/font.gd")

const ID = "loom"
const BIOME = 3
# the element each weather strikes with
const WX_EL = {"rain": "water", "gale": "bolt", "drought": "fire", "fog": "void", "clear": "wind"}

static func here(g) -> bool:
	return not g.in_lobby and g.floor_i / 2 == BIOME

static func is_loom(e) -> bool:
	return e != null and e.get("id", "") == ID

# Per frame for the Loom (from Stage.tick_foe).
static func tick(g, e: Dictionary, dt: float) -> void:
	if not is_loom(e) or e.dead:
		return
	var ph: Array = D.SPIRE.phases
	var want = 0
	for i in ph.size():
		if e.hp <= e.mhp * float(ph[i][1]):
			want = i
	if int(e.get("ph", -1)) < want:
		phase(g, e, want)
	if e.get("weave", false):
		e.weave_t -= dt
		if e.weave_t <= 0.0:
			e.weave = false
			g.label(g.center(e) + Vector2(0, -e.h2 - 20.0), "THE WEAVE FRAYS", Color("a8a7b8"))
	if e.has("torn"):
		e.torn -= dt
		if e.torn <= 0.0:
			e.erase("torn")

static func phase(g, e: Dictionary, i: int) -> void:
	e.ph = i
	var wx: String = D.SPIRE.phases[i][0]
	g.dg.weather = wx
	e.el = WX_EL[wx] if D.EL.has(WX_EL[wx]) else ""
	e.weave = true
	e.weave_t = D.SPIRE.weave_t
	var c: Vector2 = g.center(e)
	g.banner = {text = "THE LOOM WEAVES " + g.Wx.NAME[wx], sub = "A STORM CLOSE TO IT TEARS THE WEAVE", t = 3.5}
	g.rings.append({pos = c, r = D.SPIRE.storm_r, t = 0.0, col = D.EL_COL[WX_EL[wx]]})
	g.flash(c, 160.0, D.EL_COL[WX_EL[wx]], 0.5)
	g.shake_add(5.0)
	Sfx.play("roar", 1.2)
	g.tip("weave", "THE WEAVE", "IT TURNS AWAY HITS. MAKE A STORM (THREE ELEMENTS IN ONE FIELD) NEAR THE LOOM.")

# A storm was born at pos (from Combo).
static func on_storm(g, pos: Vector2) -> void:
	for e in g.enemies:
		if not is_loom(e) or e.dead or not e.get("weave", false):
			continue
		if g.center(e).distance_to(pos) > D.SPIRE.storm_r + e.hr:
			continue
		e.weave = false
		e.torn = D.SPIRE.torn_t
		e.stun = maxf(e.stun, D.SPIRE.stun_t)
		var c: Vector2 = g.center(e)
		g.banner = {text = "WEAVE TORN", sub = "STRIKE NOW", t = 2.0}
		g.burst(c, 36, Color("b8f0d0"), 200.0, 0.7)
		g.Pfx.spawn(g, "radiance", c, 50.0)
		g.hitstop = maxf(g.hitstop, 0.15)
		g.shake_add(8.0)
		g.buzz(200, 1.0)
		Sfx.play("boom", 0.6)
		g.tally("torn")

# Every hit on the Loom passes through here.
static func amount(g, e: Dictionary, amt: float) -> float:
	if e.get("weave", false):
		return amt * D.SPIRE.weave_cut
	if e.has("torn"):
		return amt * D.SPIRE.torn_mult
	return amt

static func boss(g, e: Dictionary, rage: bool, dir: Vector2) -> void:
	var wx: String = g.dg.get("weather", "clear")
	var el: String = WX_EL.get(wx, "wind")
	var bel: String = el if D.EL_COL.has(el) else ""
	match e.atk % 3:
		0:
			# rows of thread, each with a gap: find it and stay in it
			e.t = 2.8
			var rows = 5 if rage else 4
			for k in rows:
				g.after(0.4 + k * 0.42, func():
					if e.dead:
						return
					var c: Vector2 = g.center(e)
					var aim: Vector2 = (g.pcenter() - c).normalized()
					var side: Vector2 = aim.orthogonal()
					var gap = g.rng.randi_range(-4, 3)
					for i in range(-8, 9):
						if i == gap or i == gap + 1:
							continue
						g.ebullet(c + side * i * 11.0, aim * 78.0, bel)
					Sfx.play("shoot_wind", 0.8, -6.0))
		1:
			# the weather strikes on marked circles
			e.t = 2.4
			var n = 7 if rage else 5
			for i in n:
				var at: Vector2 = g.random_room_pos(g.lock, 0.0) if g.lock != null else g.p.pos
				if i < 2:
					at = g.players[i % g.players.size()].pos + Vector2(g.rng.randf_range(-18, 18), g.rng.randf_range(-18, 18))
				g.tele_circle(at, 22.0, 1.0)
				g.after(1.0 + i * 0.06, func():
					var col: Color = D.EL_COL[el]
					if el == "bolt":
						g.bolt(at + Vector2(g.rng.randf_range(-16, 16), -150), at, col)
					g.explode(at, 22.0, 1.0, "", 1, col)
					g.Env.touch(g, at, 14.0, el)
					Sfx.play("shoot_" + el, 0.7, -4.0))
		2:
			# the shuttle: a spiral that turns while it fires
			e.t = 3.0
			var base = g.rng.randf() * TAU
			var turn = (0.42 if rage else 0.34) * (1.0 if g.rng.randf() < 0.5 else -1.0)
			for k in 26:
				g.after(k * 0.08, func():
					if e.dead:
						return
					var c: Vector2 = g.center(e)
					for j in (3 if rage else 2):
						g.ebullet(c, Vector2.from_angle(base + k * turn + j * TAU / (3.0 if rage else 2.0)) * 92.0, bel)
					if k % 5 == 0:
						Sfx.play("shoot_mech", 1.2, -9.0))

static func draw_foe(g, ci: CanvasItem, e: Dictionary) -> void:
	if not is_loom(e):
		return
	var c: Vector2 = g.center(e)
	var col: Color = D.EL_COL[WX_EL.get(str(g.dg.get("weather", "clear")), "wind")]
	if e.get("weave", false):
		# threads crossing around it, slowly turning
		var a = g.time * 0.6
		for i in 6:
			var p1 = c + Vector2.from_angle(a + i * TAU / 6.0) * (e.hr + 14.0)
			var p2 = c + Vector2.from_angle(a + (i + 2) * TAU / 6.0) * (e.hr + 14.0)
			ci.draw_line(p1, p2, Color(col.r, col.g, col.b, 0.55), 1.0)
		ci.draw_arc(c, e.hr + 14.0, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.8), 1.0)
		# where a storm has to land
		ci.draw_arc(c, D.SPIRE.storm_r, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.12 + 0.08 * sin(g.time * 3.0)), 1.0)
	elif e.has("torn") and int(g.time * 10.0) % 2 == 0:
		ci.draw_arc(c, e.hr + 10.0, 0.0, TAU, 20, Color("ffd24a"), 1.0)
