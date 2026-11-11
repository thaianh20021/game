extends RefCounted
# The room reacts to elements, so every room is a small chemistry problem.
#   ice   freezes mire into firm ground and bridges pits
#   fire  burns crates and sets dry brush alight (it spreads tile to tile)
#   storm runs through a whole patch of mire and shocks everything standing in it
#   venom eats through cracked walls
#   stone fills pits                       earth fills pits and firms up mire
#   water floods pits into mire, puts out fire pools
#   leaf  overgrows mire into dry brush      wood  lays planks across pits
#   metal cuts crates and cracked walls      gear  jams traps for good
#   X     does what a random other element would do
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

# Patches that turn a tile into another terrain instead of plain floor.
const TURNS = {"pond": 1, "growth": 4}

static func patch(g, c: Vector2i, kind: String) -> void:
	g.dg.terr[c.y * g.dg.w + c.x] = TURNS.get(kind, 0)
	g.patches.append({cell = c, kind = kind})

# Something of element el happened at pos with radius rad.
static func touch(g, pos: Vector2, rad: float, el: String) -> void:
	if el == "" or el == "prism" or g.in_lobby:
		return
	if el == "x":
		# the unknown element behaves as any of the others
		var pool = D.ALL.filter(func(q): return q != "x")
		el = pool[g.rng.randi() % pool.size()]
	hijack(g, pos, rad, el)
	g.Puzzle.touch(g, pos, rad, el)
	if el == "tox" or el == "metal":
		for c in g.dg.cracks:
			if not c.open and cell_pos(c.cell).distance_to(pos) < rad + 14.0:
				c.hp = 1
				g.More.hit_crack(g, c.cell.x, c.cell.y)
				if el == "tox":
					g.tip("env_tox", "CORRODED", "VENOM EATS THROUGH CRACKED WALLS")
				else:
					g.tip("env_metal", "CUT THROUGH", "METAL CUTS CRATES AND CRACKED WALLS")
				g.Book.find(g, "e_" + el)
		if el == "tox":
			return
		for pr in g.props:
			if not pr.dead and pr.kind == "crate" and pr.pos.distance_to(pos) < rad + 7.0:
				g.hurt_prop(pr, 99.0)
				g.tip("env_metal", "CUT THROUGH", "METAL CUTS CRATES AND CRACKED WALLS")
				g.Book.find(g, "e_metal")
		return
	if el == "mech":
		for tr in g.traps:
			if not tr.get("off", false) and tr.pos.distance_to(pos) < rad + 14.0:
				tr.off = true
				tr.st = "idle"
				g.burst(tr.pos, 6, D.EL_COL["mech"], 50.0, 0.4)
				g.label(tr.pos + Vector2(0, -14), "JAMMED", D.EL_COL["mech"])
				Sfx.play("door", 1.6, -6.0)
				g.tip("env_mech", "JAMMED", "GEARS JAM TRAPS FOR GOOD")
				g.Book.find(g, "e_mech")
		return
	if el == "water":
		for z in g.zones:
			if z.el == "fire" and z.life > 0.0 and z.life < 9000.0 and z.pos.distance_to(pos) < z.r + rad:
				z.life = 0.0
				g.burst(z.pos, 6, Color("d8f6ff"), 30.0, 0.7, -50.0)
				Sfx.play("freeze", 0.7, -10.0)
				g.tip("env_water", "DOUSED", "WATER PUTS OUT FIRE AND FLOODS PITS")
				g.Book.find(g, "e_water")
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
				"stone":
					if t == 2:
						patch(g, c, "rubble")
						g.burst(cell_pos(c), 4, D.EL_COL["stone"], 40.0, 0.4)
						g.Book.find(g, "e_stone")
				"earth":
					if t == 1 or t == 2:
						patch(g, c, "soil" if t == 1 else "rubble")
						g.burst(cell_pos(c), 4, D.EL_COL["earth"], 40.0, 0.4)
						g.tip("env_earth", "FILLED IN", "EARTH FILLS PITS AND FIRMS UP MIRE")
						g.Book.find(g, "e_earth")
				"water":
					if t == 2:
						patch(g, c, "pond")
						g.burst(cell_pos(c), 4, D.EL_COL["water"], 40.0, 0.4)
						g.tip("env_water", "FLOODED", "WATER FLOODS PITS INTO MIRE AND PUTS OUT FIRE")
						g.Book.find(g, "e_water")
				"leaf":
					if t == 1:
						patch(g, c, "growth")
						g.burst(cell_pos(c), 4, D.EL_COL["leaf"], 40.0, 0.4)
						g.tip("env_leaf", "OVERGROWN", "LEAF TURNS MIRE INTO DRY BRUSH. BRUSH BURNS.")
						g.Book.find(g, "e_leaf")
				"wood":
					if t == 2:
						patch(g, c, "plank")
						g.burst(cell_pos(c), 4, D.EL_COL["wood"], 40.0, 0.4)
						g.tip("env_wood", "BRIDGED", "WOOD LAYS PLANKS ACROSS PITS")
						g.Book.find(g, "e_wood")
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
			"rubble":
				ci.draw_rect(Rect2(o, Vector2(16, 16)), Color("8b5b3b"))
				ci.draw_rect(Rect2(o, Vector2(16, 1)), Color("c99b5c"))
				for i in 5:
					ci.draw_rect(Rect2(o + Vector2(1 + (i * 7 + q.cell.x * 3) % 11, 2 + (i * 5 + q.cell.y) % 10), Vector2(4, 3)), Color("c99b5c") if i % 2 == 0 else Color("553423"))
			"soil":
				ci.draw_rect(Rect2(o, Vector2(16, 16)), Color("7a4a2a"))
				ci.draw_rect(Rect2(o, Vector2(16, 1)), Color("b5562f"))
				for i in 4:
					ci.draw_rect(Rect2(o + Vector2(2 + (i * 5 + q.cell.x * 3) % 11, 3 + (i * 7 + q.cell.y) % 10), Vector2(2, 1)), Color("553423"))
			"pond":
				ci.draw_rect(Rect2(o, Vector2(16, 16)), Color("234a6e"))
				ci.draw_rect(Rect2(o, Vector2(16, 1)), Color("16121d"))
				var wv = int(g.time * 3.0 + q.cell.x + q.cell.y) % 3
				ci.draw_rect(Rect2(o + Vector2(2 + wv * 3, 5), Vector2(5, 1)), Color("4aa8ff"))
				ci.draw_rect(Rect2(o + Vector2(8 - wv * 2, 11), Vector2(4, 1)), Color("9fd8ff"))
			"growth":
				ci.draw_rect(Rect2(o, Vector2(16, 16)), Color("2b6a40"))
				for i in 6:
					var bx = 1 + (i * 5 + q.cell.x * 3) % 13
					var by = 3 + (i * 7 + q.cell.y * 5) % 10
					ci.draw_rect(Rect2(o + Vector2(bx, by), Vector2(1, 4)), Color("6fd66a"))
					ci.draw_rect(Rect2(o + Vector2(bx + 1, by + 1), Vector2(1, 2)), Color("c8f5a0"))
			"plank":
				ci.draw_rect(Rect2(o, Vector2(16, 16)), Color("8f6a34"))
				for i in 4:
					ci.draw_rect(Rect2(o + Vector2(0, i * 4), Vector2(16, 1)), Color("553423"))
				ci.draw_rect(Rect2(o + Vector2(2, 1), Vector2(1, 1)), Color("c99a5a"))
				ci.draw_rect(Rect2(o + Vector2(13, 9), Vector2(1, 1)), Color("c99a5a"))
			"ash":
				ci.draw_rect(Rect2(o + Vector2(1, 1), Vector2(14, 14)), Color(0.06, 0.05, 0.07, 0.75))
				for i in 4:
					ci.draw_rect(Rect2(o + Vector2(3 + (i * 5 + q.cell.x) % 10, 3 + (i * 7 + q.cell.y) % 10), Vector2(1, 1)), Color("6b6779"))
