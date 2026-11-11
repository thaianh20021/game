extends RefCounted
# The room reacts to elements, so every room is a small chemistry problem.
#   ice   freezes mire into firm ground and bridges pits
#   fire  burns crates and sets dry brush alight (it spreads tile to tile)
#   storm runs through a whole patch of mire and shocks everything standing in it
#   venom eats through cracked walls
# and any element thrown into an ENEMY pool of a different element steals it: the pool
# becomes one of your reaction fields (fire pool + ice = steam that swallows bullets).

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")
const TS = 16
const N4 = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

static func cell_pos(c: Vector2i) -> Vector2:
	return Vector2(c.x * TS + 8, c.y * TS + 8)

static func terr(g, c: Vector2i) -> int:
	if g.dg.terr.size() == 0 or c.x < 0 or c.y < 0 or c.x >= g.dg.w or c.y >= g.dg.h:
		return 0
	return g.dg.terr[c.y * g.dg.w + c.x]

static func patch(g, c: Vector2i, kind: String) -> void:
	g.dg.terr[c.y * g.dg.w + c.x] = 0
	g.patches.append({cell = c, kind = kind})

# Something of element el happened at pos with radius rad.
static func touch(g, pos: Vector2, rad: float, el: String) -> void:
	if el == "" or el == "prism" or g.in_lobby:
		return
	hijack(g, pos, rad, el)
	g.Puzzle.touch(g, pos, rad, el)
	if el == "tox":
		for c in g.dg.cracks:
			if not c.open and cell_pos(c.cell).distance_to(pos) < rad + 14.0:
				c.hp = 1
				g.More.hit_crack(g, c.cell.x, c.cell.y)
				g.tip("env_tox", "CORRODED", "VENOM EATS THROUGH CRACKED WALLS")
				g.Book.find(g, "e_tox")
		return
	if el == "fire":
		for pr in g.props:
			if not pr.dead and pr.kind == "crate" and pr.pos.distance_to(pos) < rad + 7.0:
				g.hurt_prop(pr, 99.0)
				g.zones.append({pos = pr.pos, r = 10.0, el = "fire", life = 2.0, team = 0, tick = 0.2})
				g.tip("env_fire", "FIRE SPREADS", "IT BURNS CRATES AND DRY BRUSH")
				g.Book.find(g, "e_fire")
	if g.dg.terr.size() == 0:
		return
	var reach = int(ceil(rad / TS))
	var c0 = Vector2i((pos / TS).floor())
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var c = c0 + Vector2i(dx, dy)
			var t = terr(g, c)
			if t == 0 or cell_pos(c).distance_to(pos) > rad + 9.0:
				continue
			match el:
				"ice":
					if t == 1 or t == 2:
						patch(g, c, "ice" if t == 1 else "bridge")
						g.burst(cell_pos(c), 4, D.EL_COL["ice"], 40.0, 0.4)
						Sfx.play("freeze", 1.3, -8.0)
						g.tip("env_ice", "FROZEN SOLID", "ICE HARDENS MIRE AND BRIDGES PITS")
						g.Book.find(g, "e_ice")
				"fire":
					if t == 4:
						ignite(g, c)
				"bolt":
					if t == 1:
						conduct(g, c)
						return

static func ignite(g, c: Vector2i) -> void:
	if terr(g, c) != 4:
		return
	patch(g, c, "ash")
	var p = cell_pos(c)
	g.zones.append({pos = p, r = 10.0, el = "fire", life = 2.2, team = 0, tick = 0.1})
	g.burst(p, 4, D.EL_COL["fire"], 40.0, 0.5, -60.0)
	g.Puzzle.touch(g, p, 10.0, "fire")
	g.tip("env_fire", "FIRE SPREADS", "IT BURNS CRATES AND DRY BRUSH")
	g.Book.find(g, "e_fire")
	for d in N4:
		var n = c + d
		if terr(g, n) == 4:
			g.after(g.Wx.spread_delay(g), func(): ignite(g, n))

# Lightning runs through every connected tile of mire.
static func conduct(g, c: Vector2i) -> void:
	if g.time < g.env_cd:
		return
	g.env_cd = g.time + 0.8
	var seen = {c: true}
	var q = [c]
	var i = 0
	while i < q.size() and q.size() < 60:
		var cur = q[i]
		i += 1
		for d in N4:
			var n = cur + d
			if not seen.has(n) and terr(g, n) == 1:
				seen[n] = true
				q.append(n)
	var col: Color = D.EL_COL["bolt"]
	for k in q.size():
		if k % 2 == 0:
			g.bolts.append({a = cell_pos(q[k]), b = cell_pos(q[(k + 1) % q.size()]), col = col, t = 0.2, straight = false})
	g.flash(cell_pos(c), 90.0, col, 0.3)
	Sfx.play("shoot_bolt", 0.6)
	g.tip("env_bolt", "CONDUCTED", "LIGHTNING RUNS THROUGH MIRE. STAY OUT OF IT.")
	g.Book.find(g, "e_bolt")
	g.Puzzle.conducted(g, seen)
	for e in g.enemies:
		if e.dead or e.d.get("fly", false):
			continue
		if seen.has(Vector2i((e.pos / TS).floor())):
			g.hurt_enemy(e, (8.0 + g.floor_i * 3.0) * g.st.react * g.Wx.conduct_mult(g), "", Vector2.ZERO, true, col)
			if not e.dead:
				e.stun = maxf(e.stun, 0.3 if e.is_boss else 0.9)
				e.st["bolt"] = 4.0
	var keep = g.p
	for pl in g.players:
		if not pl.down and pl.dash_t <= 0.0 and seen.has(Vector2i((pl.pos / TS).floor())):
			g.bind(pl)
			g.hurt_player(1, "bolt")
	g.bind(keep)

# An enemy pool hit by a different element becomes yours.
static func hijack(g, pos: Vector2, rad: float, el: String) -> void:
	for z in g.zones:
		if z.team != 1 or z.life <= 0.0 or z.el == "" or z.el == el:
			continue
		if z.pos.distance_to(pos) < z.r + rad:
			z.life = 0.0
			var pair = [el, z.el]
			pair.sort()
			g.Combo.spawn(g, z.pos, pair[0] + "+" + pair[1])
			g.label(z.pos + Vector2(0, -20), "HIJACKED", Color("ffd24a"), true)
			g.rings.append({pos = z.pos, r = z.r + 10.0, t = 0.0, col = Color("ffd24a")})
			g.charge_res(0.5)
			Sfx.play("react", 1.2)
			g.tip("hijack", "HIJACKED", "ENEMY POOLS BECOME YOUR FIELDS")
			g.Book.find(g, "hijack")

static func draw(g, ci: CanvasItem) -> void:
	for q in g.patches:
		var o = Vector2(q.cell) * TS
		if not g.on_screen(o, 20.0):
			continue
		match q.kind:
			"ice", "bridge":
				ci.draw_rect(Rect2(o, Vector2(16, 16)), Color("9fdcf2") if q.kind == "ice" else Color("6fb7e0"))
				ci.draw_rect(Rect2(o, Vector2(16, 1)), Color.WHITE)
				ci.draw_rect(Rect2(o + Vector2(0, 15), Vector2(16, 1)), Color("3f76dc"))
				ci.draw_line(o + Vector2(3, 4), o + Vector2(8, 9), Color(1, 1, 1, 0.8), 1.0)
				ci.draw_line(o + Vector2(10, 3), o + Vector2(13, 6), Color(1, 1, 1, 0.6), 1.0)
			"ash":
				ci.draw_rect(Rect2(o + Vector2(1, 1), Vector2(14, 14)), Color(0.06, 0.05, 0.07, 0.75))
				for i in 4:
					ci.draw_rect(Rect2(o + Vector2(3 + (i * 5 + q.cell.x) % 10, 3 + (i * 7 + q.cell.y) % 10), Vector2(1, 1)), Color("6b6779"))
