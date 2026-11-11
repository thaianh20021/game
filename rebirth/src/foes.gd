extends RefCounted
# Charged special attacks for ordinary foes, and the third boss of each biome.
#
# Any foe may now and then stop, gather power for a second (ring closing in, "!!"),
# and release a pattern that is not part of its usual routine. Elites do it more often.

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")

const CHARGE = 1.0
# usual behaviour -> charged move
const MOVE = {"chase": "slam", "bat": "burst", "shoot": "volley", "spread": "double", "charge": "quake", "turret": "nova", "blink": "cross"}

static func cooldown(g, e: Dictionary) -> float:
	return g.rng.randf_range(4.0, 8.0) * (0.5 if e.elite else 1.0)

# Returns true while the foe is busy charging (its normal behaviour is skipped).
static func special(g, e: Dictionary, dt: float, dir: Vector2, dist: float) -> bool:
	var kind: String = MOVE.get(e.d.ai, "")
	if kind == "":
		return false
	if not e.has("sp_t"):
		e.sp_t = cooldown(g, e)
		e.sp_c = 0.0
		e.sp_n = 0
	if e.sp_c > 0.0:
		e.sp_c -= dt
		if e.sp_c <= 0.0:
			e.sp_t = cooldown(g, e)
			e.sp_n += 1
			unleash(g, e, kind)
		return true
	if e.state != "" or e.wind > 0.0:
		return false
	e.sp_t -= dt
	if e.sp_t > 0.0 or dist > 170.0:
		return false
	e.sp_c = CHARGE
	e.sp_at = g.p.pos
	if g.on_screen(e.pos):
		Sfx.play("warn", 0.7)
	match kind:
		"slam": g.tele_circle(e.sp_at, 28.0, CHARGE)
		"quake": g.tele_circle(e.pos, 40.0, CHARGE)
	return true

static func unleash(g, e: Dictionary, kind: String) -> void:
	var c: Vector2 = g.center(e)
	var el: String = e.el
	var aim: Vector2 = (g.pcenter() - c).normalized()
	var spd: float = e.d.get("bspd", 100)
	g.flash(c, 60.0, D.EL_COL[el] if el != "" else Color("ff5a6a"), 0.2)
	match kind:
		"slam":
			# leaps to where the hero stood when the charge began
			if g.box_free(e.sp_at, e.r):
				g.bolts.append({a = c, b = e.sp_at, col = e.col, t = 0.15, straight = true})
				e.pos = e.sp_at
			g.explode(e.pos, 28.0, 1.0, el, 1)
		"burst":
			g.ring(c, 10, 100.0, el, g.rng.randf() * TAU)
		"volley":
			g.fan(c, aim, 5, 0.6, spd * 1.5, el)
			g.after(0.25, func():
				if not e.dead:
					g.fan(g.center(e), (g.pcenter() - g.center(e)).normalized(), 4, 0.45, spd * 1.5, el))
		"double":
			var off = g.rng.randf() * TAU
			g.ring(c, 12, spd, el, off)
			g.after(0.3, func():
				if not e.dead:
					g.ring(g.center(e), 12, spd * 1.2, el, off + TAU / 24.0))
		"quake":
			g.explode(e.pos, 40.0, 2.0, el, 1)
			g.ring(c, 8, 90.0, el, g.rng.randf() * TAU)
		"nova":
			for k in 3:
				g.after(k * 0.2, func():
					if not e.dead:
						g.ring(g.center(e), 12, 80.0 + k * 15.0, el, k * 0.26))
		"cross":
			var cand = g.p.pos - g.p.aim * 34.0
			if g.box_free(cand, e.r):
				g.burst(c, 8, e.col, 60.0, 0.3)
				e.pos = cand
			g.ring(g.center(e), 8, 120.0, el, 0.0)
	Sfx.play("shoot", 0.6, -4.0)

static func draw_charge(g, ci: CanvasItem, e: Dictionary) -> void:
	var sc: float = e.get("sp_c", 0.0)
	if sc <= 0.0:
		return
	var k = 1.0 - sc / CHARGE
	var c: Vector2 = g.center(e)
	var col: Color = D.EL_COL[e.el] if e.el != "" else Color("ff5a6a")
	ci.draw_arc(c, lerpf(30.0, e.hr + 2.0, k), 0.0, TAU, 20, Color(col.r, col.g, col.b, 0.4 + 0.6 * k), 2.0)
	ci.draw_arc(c, lerpf(20.0, e.hr, k), g.time * 9.0, g.time * 9.0 + 4.0, 12, Color(1, 1, 1, 0.8), 1.0)
	if int(g.time * 14.0) % 2 == 0:
		ci.draw_circle(c, e.hr * 0.8, Color(1, 1, 1, 0.25 * k))
	g.Px.ctext(ci, Vector2(e.pos.x, c.y - e.h2 - 14.0), "!!", Color("ff4a5e"))
	if g.rng.randf() < 0.6:
		var from = c + Vector2.from_angle(g.rng.randf() * TAU) * 30.0
		g.parts.append({pos = from, vel = (c - from) * 3.5, life = 0.25, max = 0.25, col = col, size = 1, grav = 0.0})

# ---- third bosses ----------------------------------------------------------------

static func room_clamp(g, pos: Vector2) -> Vector2:
	if g.lock == null:
		return pos
	var rc: Rect2i = g.lock.rect.grow(-1)
	return pos.clamp(Vector2(rc.position) * 16.0, Vector2(rc.end) * 16.0)

# A beam along a segment: drawn for a moment, hurts every hero close to it.
static func beam(g, a: Vector2, b: Vector2, w: float, el: String, col: Color) -> void:
	g.bolts.append({a = a, b = b, col = col, t = 0.12, straight = true})
	var keep = g.p
	for pl in g.players:
		if pl.down:
			continue
		var pc: Vector2 = pl.pos + Vector2(0, -3)
		if Geometry2D.get_closest_point_to_segment(pc, a, b).distance_to(pc) < w:
			g.bind(pl)
			g.hurt_player(1, el)
	g.bind(keep)

static func boss(g, e: Dictionary, rage: bool, dir: Vector2) -> void:
	match e.d.boss:
		6: _rootking(g, e, rage)
		7: _wyrm(g, e, rage)
		8: _sentinel(g, e, rage)

static func _rootking(g, e: Dictionary, rage: bool) -> void:
	match e.atk:
		0:
			# roots burst out along marked lines
			var n = 8 if rage else 5
			var base = g.rng.randf() * TAU
			var c: Vector2 = e.pos
			e.t = 1.7
			for i in n:
				var to = c + Vector2.from_angle(base + i * TAU / n) * 170.0
				g.teles.append({kind = "line", pos = c, to = to, t = 0.0, dur = 0.8, r = 0.0})
				g.after(0.8, func():
					if not e.dead:
						beam(g, c, to, 7.0, "", Color("8b5b3b"))
						g.burst(to, 4, Color("4fae4c"), 60.0, 0.4))
			g.after(0.8, func():
				if not e.dead:
					Sfx.play("boom", 1.4, -4.0)
					g.shake_add(4.0))
		1:
			# rings of thorns, each turned half a step so the gaps move
			var n = 4 if rage else 3
			e.t = n * 0.45 + 0.9
			for k in n:
				g.after(k * 0.45, func():
					if not e.dead:
						g.ring(g.center(e), 14, 85.0, "", k * TAU / 28.0)
						Sfx.play("shoot", 0.6, -4.0))
		2:
			# roots grab at the hero's feet again and again
			var n = 7 if rage else 4
			e.t = n * 0.35 + 1.0
			for i in n:
				g.after(i * 0.35, func():
					if e.dead:
						return
					var tp = room_clamp(g, g.p.pos + g.p.v * 0.3)
					g.tele_circle(tp, 18.0, 0.7)
					g.after(0.7, func():
						g.explode(tp, 18.0, 2.0, "", 1)
						g.zones.append({pos = tp, r = 14.0, el = "ice", life = 2.0, team = 1, tick = 0.5})))

static func _wyrm(g, e: Dictionary, rage: bool) -> void:
	match e.atk:
		0:
			# breath that sweeps across the room (and back when enraged)
			var steps = 30 if rage else 16
			var a0 = (g.pcenter() - g.center(e)).angle()
			var side = 1.0 if g.rng.randf() < 0.5 else -1.0
			e.t = steps * 0.09 + 0.8
			for i in steps:
				g.after(0.3 + i * 0.09, func():
					if e.dead:
						return
					var k = float(i) / 15.0
					if k > 1.0:
						k = 2.0 - k
					var a = a0 + side * lerpf(-0.8, 0.8, k)
					g.fan(g.center(e), Vector2.from_angle(a), 3, 0.22, 150.0, "fire")
					if i % 3 == 0:
						Sfx.play("shoot_fire", 1.0, -6.0))
		1:
			# dives onto the hero and leaves the ground burning
			var tp = room_clamp(g, g.p.pos)
			g.tele_circle(tp, 42.0, 0.8)
			e.state = "hop"
			e.t = 0.8
			e.hop_from = e.pos
			e.hop_to = tp
			g.after(0.85, func():
				if e.dead:
					return
				for i in (6 if rage else 4):
					var q = room_clamp(g, tp + Vector2.from_angle(i * TAU / (6 if rage else 4)) * 34.0)
					g.zones.append({pos = q, r = 16.0, el = "fire", life = 3.0, team = 1, tick = 0.4}))
		2:
			# embers rain over the whole room
			var n = 14 if rage else 9
			e.t = n * 0.16 + 1.1
			for i in n:
				g.after(i * 0.16, func():
					if e.dead or g.lock == null:
						return
					var tp = g.random_room_pos(g.lock, 0.0) if i % 3 else room_clamp(g, g.p.pos)
					g.tele_circle(tp, 20.0, 0.9)
					g.after(0.9, func(): g.explode(tp, 20.0, 2.0, "fire", 1)))

static func _sentinel(g, e: Dictionary, rage: bool) -> void:
	match e.atk:
		0:
			# rotating beams, one element each: stand in the gaps and move with them
			var n = 6 if rage else 4
			var base = g.rng.randf() * TAU
			var spin = (0.55 if rage else 0.4) * (1.0 if g.rng.randf() < 0.5 else -1.0)
			var c: Vector2 = g.center(e)
			e.t = 3.4
			for i in n:
				g.teles.append({kind = "line", pos = c, to = c + Vector2.from_angle(base + i * TAU / n) * 180.0, t = 0.0, dur = 0.9, r = 0.0})
			for k in 22:
				g.after(0.9 + k * 0.1, func():
					if e.dead:
						return
					var cc: Vector2 = g.center(e)
					for i in n:
						var el: String = D.EL[i % 4]
						beam(g, cc, cc + Vector2.from_angle(base + spin * k * 0.1 * TAU / 3.0 + i * TAU / n) * 180.0, 5.0, el, D.EL_COL[el])
					if k % 4 == 0:
						Sfx.play("shoot_bolt", 1.3, -8.0))
		1:
			# four rings, one per element
			e.t = 1.9
			for k in 4:
				g.after(k * 0.28, func():
					if not e.dead:
						g.ring(g.center(e), 12 if rage else 9, 70.0 + k * 14.0, D.EL[k], k * 0.2)
						Sfx.play("shoot_" + D.EL[k], 1.0, -6.0))
		2:
			# gathers light, then one enormous fan
			e.t = 2.4
			e.cast_t = 1.1
			g.tele_circle(g.center(e), 26.0, 1.1)
			Sfx.play("portal", 1.5)
			g.after(1.1, func():
				if e.dead:
					return
				var c: Vector2 = g.center(e)
				var aim: Vector2 = (g.pcenter() - c).normalized()
				g.fan(c, aim, 15 if rage else 11, 1.5, 190.0, D.EL[g.rng.randi() % 4])
				g.ring(c, 16, 60.0, "", g.rng.randf() * TAU)
				g.flash(c, 200.0, Color.WHITE, 0.4)
				g.shake_add(6.0)
				Sfx.play("boom"))
