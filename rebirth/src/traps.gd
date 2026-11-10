extends RefCounted
# Floor traps. Spikes appear everywhere; each biome adds one trap of its own:
#   Ancient Cave - spore vent (venom cloud), Ember Forge - flame jet (line of fire),
#   Crystal Archive - storm rune (goes off when a hero steps close).
# Traps hurt foes as well and apply their element, so they can be used to set off reactions.

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")

const OWN = ["spore", "flame", "rune"]
# [warning starts, trap switches on, full cycle] in seconds
const CYCLE = {"spike": [2.0, 2.6, 3.4], "spore": [2.6, 3.3, 5.2], "flame": [2.0, 2.7, 4.0]}
const NAME = {"spike": "SPIKES", "spore": "SPORE VENT", "flame": "FLAME JET", "rune": "STORM RUNE"}
const FLAME_LEN = 44.0

# ---- placement (called by the dungeon generator, so it must only use rng) ----------

static func place(rng: RandomNumberGenerator, d: Dictionary, r: Dictionary, floor_i: int) -> void:
	var own: String = OWN[clampi(floor_i / 2, 0, 2)]
	var n = (3 if r.type == "boss" else 2 + rng.randi() % 3) + floor_i / 2
	var taken = {}
	for pr in d.props:
		taken[Vector2i((pr.pos / 16.0).floor())] = true
	for i in n:
		for attempt in 20:
			var c = r.rect.position + Vector2i(1 + rng.randi() % (r.rect.size.x - 2), 1 + rng.randi() % (r.rect.size.y - 2))
			if d.grid[c.y * d.w + c.x] != 1 or taken.has(c):
				continue
			if abs(c.x - r.center.x) + abs(c.y - r.center.y) < 3:
				continue
			var kind = own if (i % 2 == 0 or r.type == "boss") else "spike"
			var dir = Vector2.RIGHT
			if kind == "flame":
				var ok = []
				for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var free = true
					for k in range(1, 4):
						var q = c + dd * k
						if not r.rect.has_point(q) or d.grid[q.y * d.w + q.x] != 1:
							free = false
					if free:
						ok.append(dd)
				if ok.is_empty():
					kind = "spike"
				else:
					dir = Vector2(ok[rng.randi() % ok.size()])
			taken[c] = true
			d.traps.append({kind = kind, pos = Vector2(c.x * 16 + 8, c.y * 16 + 8), t = rng.randf() * 3.0, dir = dir, tick = 0.0, st = "idle"})
			break

# ---- simulation ------------------------------------------------------------------

static func dist(tr: Dictionary, pos: Vector2) -> float:
	if tr.kind == "flame":
		return Geometry2D.get_closest_point_to_segment(pos, tr.pos, tr.pos + tr.dir * FLAME_LEN).distance_to(pos)
	return tr.pos.distance_to(pos)

static func zap(g, tr: Dictionary, r: float, el: String) -> void:
	for pl in g.players:
		if pl.down or dist(tr, pl.pos) >= r:
			continue
		g.bind(pl)
		var before = pl.hp + pl.ar + (pl.mount.hp if pl.mount != null else 0)
		g.hurt_player(1, el)
		if g.state != "play":
			return
		if pl.hp + pl.ar + (pl.mount.hp if pl.mount != null else 0) < before:
			g.tip("trap", NAME[tr.kind], "TRAPS HURT FOES TOO. LURE THEM IN.")
	g.bind(g.players[0])
	for e in g.enemies:
		if e.dead or e.d.ai == "dummy":
			continue
		if tr.kind == "spike" and e.d.get("fly", false):
			continue
		if dist(tr, e.pos) < r + e.r:
			g.hurt_enemy(e, 3.0 + g.floor_i * 1.5, el, Vector2.ZERO, true)

static func update(g, dt: float) -> void:
	for tr in g.traps:
		tr.tick -= dt
		if tr.kind == "rune":
			tr.t -= dt
			if tr.st == "idle":
				if tr.t <= 0.0:
					for pl in g.players:
						if not pl.down and pl.pos.distance_to(tr.pos) < 28.0:
							tr.st = "charge"
							tr.t = 0.8
							Sfx.play("warn")
							break
			elif tr.t <= 0.0:
				tr.st = "idle"
				tr.t = 2.5
				var col: Color = D.EL_COL["bolt"]
				g.bolt(tr.pos + Vector2(g.rng.randf_range(-16, 16), -130), tr.pos, col)
				g.rings.append({pos = tr.pos, r = 30.0, t = 0.0, col = col})
				g.flash(tr.pos, 80.0, col, 0.25)
				Sfx.play("shoot_bolt", 0.8)
				zap(g, tr, 30.0, "bolt")
		else:
			var c = CYCLE[tr.kind]
			var was: String = tr.st
			tr.t = fmod(tr.t + dt, c[2])
			tr.st = "idle" if tr.t < c[0] else ("warn" if tr.t < c[1] else "on")
			if tr.st == "on":
				if was != "on":
					tr.tick = 0.0
					if g.on_screen(tr.pos, 0.0):
						Sfx.play({"spike": "slash", "spore": "shoot_tox", "flame": "shoot_fire"}[tr.kind], 0.8, -8.0)
				if tr.tick <= 0.0:
					tr.tick = 0.5
					match tr.kind:
						"spike": zap(g, tr, 8.0, "")
						"spore": zap(g, tr, 20.0, "tox")
						"flame": zap(g, tr, 7.0, "fire")
		if g.state != "play":
			return

# ---- drawing ---------------------------------------------------------------------

static func draw(g, ci: CanvasItem) -> void:
	var t: float = g.time
	for tr in g.traps:
		var p: Vector2 = tr.pos
		if not g.on_screen(p, 60.0):
			continue
		match tr.kind:
			"spike":
				ci.draw_rect(Rect2(p - Vector2(7, 7), Vector2(14, 14)), Color(0.07, 0.05, 0.1, 0.75))
				ci.draw_rect(Rect2(p - Vector2(7, 7), Vector2(14, 14)), Color(0.55, 0.52, 0.62, 0.7), false, 1.0)
				for i in 4:
					var q = p + Vector2(-4 + (i % 2) * 7, -4 + (i / 2) * 7)
					var h = 0.0 if tr.st == "idle" else (2.0 if tr.st == "warn" else 7.0)
					ci.draw_rect(Rect2(q, Vector2(2, 2)), Color("120e18"))
					if h > 0.0:
						ci.draw_rect(Rect2(q.x, q.y + 2.0 - h, 2, h), Color("d9d4c7") if tr.st == "on" else Color("ff6a6a"))
						ci.draw_rect(Rect2(q.x, q.y + 2.0 - h, 1, h), Color.WHITE)
			"spore":
				ci.draw_circle(p, 6.0, Color("2b6a40"))
				ci.draw_circle(p, 4.0, Color("16121d"))
				ci.draw_arc(p, 6.0, 0.0, TAU, 12, Color("a9e150"), 1.0)
				if tr.st == "warn":
					for i in 3:
						ci.draw_circle(p + Vector2(sin(t * 9.0 + i * 2.0) * 4.0, -2.0 - fmod(t * 14.0 + i * 3.0, 8.0)), 1.5, Color("a9e150"))
					ci.draw_arc(p, 20.0, 0.0, TAU, 20, Color(0.65, 0.9, 0.3, 0.5), 1.0)
				elif tr.st == "on":
					ci.draw_circle(p, 20.0 + sin(t * 6.0) * 1.5, Color(0.55, 0.85, 0.3, 0.22))
					ci.draw_circle(p, 13.0 + cos(t * 5.0) * 2.0, Color(0.65, 0.9, 0.3, 0.25))
					ci.draw_arc(p, 20.0, 0.0, TAU, 20, Color(0.65, 0.9, 0.3, 0.8), 1.0)
					if g.rng.randf() < 0.4:
						g.parts.append({pos = p + Vector2.from_angle(g.rng.randf() * TAU) * g.rng.randf() * 18.0, vel = Vector2(0, -16), life = 0.6, max = 0.6, col = Color("a9e150"), size = 1, grav = 0.0})
			"flame":
				var e: Vector2 = p + tr.dir * FLAME_LEN
				ci.draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), Color("3a3346"))
				ci.draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), Color("a8a7b8"), false, 1.0)
				ci.draw_rect(Rect2(p + tr.dir * 3.0 - Vector2(2, 2), Vector2(4, 4)), Color("f2812f") if tr.st != "idle" else Color("8c2136"))
				if tr.st == "warn":
					ci.draw_line(p, e, Color(1.0, 0.5, 0.2, 0.25 + 0.25 * sin(t * 30.0)), 5.0)
					ci.draw_line(p, e, Color(1.0, 0.6, 0.3, 0.8), 1.0)
				elif tr.st == "on":
					var w = 9.0 + sin(t * 40.0) * 2.0
					ci.draw_line(p + tr.dir * 5.0, e, Color(1.0, 0.45, 0.15, 0.85), w)
					ci.draw_line(p + tr.dir * 5.0, e - tr.dir * 4.0, Color(1.0, 0.85, 0.35), w * 0.45)
					ci.draw_circle(e, w * 0.5, Color(1.0, 0.45, 0.15, 0.85))
					if g.rng.randf() < 0.5:
						g.parts.append({pos = p + tr.dir * g.rng.randf() * FLAME_LEN, vel = Vector2(g.rng.randf_range(-12, 12), -26), life = 0.4, max = 0.4, col = Color("ffb347"), size = 1, grav = 0.0})
			"rune":
				var col = Color("e8fbff") if tr.st == "idle" else Color("ffe45c")
				var a = 0.75 + 0.25 * sin(t * 3.0 + p.x)
				if tr.st == "idle" and tr.t > 0.0:
					a = 0.3
				col.a = a if tr.st == "idle" else 1.0
				ci.draw_arc(p, 7.0, 0.0, TAU, 14, col, 1.0)
				ci.draw_line(p + Vector2(-5, 0), p + Vector2(0, -5), col, 1.0)
				ci.draw_line(p + Vector2(0, -5), p + Vector2(5, 0), col, 1.0)
				ci.draw_line(p + Vector2(5, 0), p + Vector2(0, 5), col, 1.0)
				ci.draw_line(p + Vector2(0, 5), p + Vector2(-5, 0), col, 1.0)
				ci.draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), col)
				if tr.st == "charge":
					var k = 1.0 - tr.t / 0.8
					ci.draw_circle(p, 30.0, Color(1.0, 0.9, 0.3, 0.1))
					ci.draw_circle(p, 30.0 * k, Color(1.0, 0.9, 0.3, 0.2))
					ci.draw_arc(p, 30.0, 0.0, TAU, 26, Color(1.0, 0.9, 0.4, 0.95), 1.0)

static func lights(g, l: Callable) -> void:
	for tr in g.traps:
		if not g.on_screen(tr.pos, 60.0):
			continue
		match tr.kind:
			"spore":
				if tr.st == "on":
					l.call(tr.pos, 44.0, D.EL_COL["tox"] * 0.3)
			"flame":
				if tr.st == "on":
					l.call(tr.pos + tr.dir * FLAME_LEN * 0.5, 60.0, D.EL_COL["fire"] * 0.5)
			"rune":
				l.call(tr.pos, 22.0 if tr.st == "idle" else 50.0, (D.EL_COL["ice"] if tr.st == "idle" else D.EL_COL["bolt"]) * 0.3)
