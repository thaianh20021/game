extends RefCounted
# Puzzle rooms: no foes, a sealed reward, and a problem the room's own chemistry solves.
# Each room carries a barrel of the element it needs, so any build can solve it by
# shooting the barrel; bringing the right element yourself is the elegant way.
#   chasm     the chest sits beyond a pit too wide to dash: freeze a bridge
#   braziers  the chest is sealed until three braziers are lit with fire
#   conduit   the chest is sealed until lightning reaches the rod through the mire

const TS = 16
const KINDS = ["chasm", "braziers", "conduit"]

# ---- generation (seeded; called from dungeon.gd) ----------------------------------

static func build(rng: RandomNumberGenerator, d: Dictionary, r: Dictionary, door_up: bool) -> void:
	if d.terr.size() == 0:
		d.terr.resize(d.w * d.h)
	r.puzzle = KINDS[rng.randi() % KINDS.size()]
	var c: Vector2i = r.center
	# the reward stands on the side away from the door
	var far = 3 if door_up else -3
	r.pz_chest = Vector2(c.x * TS + 8, (c.y + far) * TS + 8)
	r.pz_things = []
	match r.puzzle:
		"chasm":
			for y in range(c.y - 2, c.y + 2):
				for x in range(r.rect.position.x, r.rect.end.x):
					d.terr[y * d.w + x] = 2
			_barrel(d, Vector2i(c.x - 3, c.y - 3 if door_up else c.y + 2), "ice")
		"braziers":
			# a line of dry brush joins the braziers, so one fire walks to all three
			var by = c.y + (1 if door_up else -1)
			for x in range(c.x - 5, c.x + 6):
				d.terr[by * d.w + x] = 4
			for dx in [-4, 0, 4]:
				r.pz_things.append({kind = "brazier", pos = Vector2((c.x + dx) * TS + 8, by * TS + 8), lit = false})
			_barrel(d, Vector2i(c.x - 5, c.y), "fire")
		"conduit":
			for x in range(c.x - 4, c.x + 4):
				d.terr[c.y * d.w + x] = 1
			r.pz_things.append({kind = "rod", pos = Vector2((c.x + 4) * TS + 8, c.y * TS + 8), on = false})
			_barrel(d, Vector2i(c.x - 5, c.y), "bolt")

static func _barrel(d: Dictionary, c: Vector2i, el: String) -> void:
	d.props.append({kind = "barrel", el = el, pos = Vector2(c.x * TS + 8, c.y * TS + 11), hp = 6.0, dead = false, flash = 0.0, pz = true})

# ---- runtime ---------------------------------------------------------------------

static func place(g, r: Dictionary) -> void:
	g.inter.append({kind = "chest", pos = r.pz_chest, loot = "puzzle", open = false, sealed = r.puzzle != "chasm", room = r.id, pz = r.puzzle})
	for th in r.pz_things:
		var it = th.duplicate()
		it.room = r.id
		g.inter.append(it)

# An element touched the room at pos.
static func touch(g, pos: Vector2, rad: float, el: String) -> void:
	if el != "fire":
		return
	for it in g.inter:
		if it.kind == "brazier" and not it.lit and it.pos.distance_to(pos) < rad + 9.0:
			it.lit = true
			g.burst(it.pos + Vector2(0, -8), 8, g.D.EL_COL["fire"], 50.0, 0.5, -60.0)
			g.Sfx.play("shoot_fire", 0.8)
			check(g, it.room)

# Lightning ran through these mire cells.
static func conducted(g, cells: Dictionary) -> void:
	for it in g.inter:
		if it.kind != "rod" or it.on:
			continue
		var c = Vector2i((it.pos / TS).floor())
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if cells.has(c + d):
				it.on = true
				g.bolt(it.pos + Vector2(0, -60), it.pos + Vector2(0, -10), g.D.EL_COL["bolt"])
				check(g, it.room)
				break

static func check(g, room_id: int) -> void:
	for it in g.inter:
		if it.get("room", -1) == room_id and ((it.kind == "brazier" and not it.lit) or (it.kind == "rod" and not it.on)):
			return
	for it in g.inter:
		if it.kind == "chest" and it.get("room", -1) == room_id and it.get("sealed", false):
			it.sealed = false
			g.banner = {text = "SOLVED", sub = "THE SEAL BREAKS", t = 2.4}
			g.rings.append({pos = it.pos, r = 40.0, t = 0.0, col = Color("ffd24a")})
			g.flash(it.pos, 120.0, Color("ffd24a"), 0.5)
			g.Sfx.play("chest")

static func sealed_text(it: Dictionary) -> String:
	return {"braziers": "SEALED. LIGHT THE THREE BRAZIERS.", "conduit": "SEALED. SEND LIGHTNING TO THE ROD."}.get(it.get("pz", ""), "SEALED.")

static func open(g, it: Dictionary) -> void:
	g.Meta.stat("puzzles")
	g.inter.append({kind = "relic", id = g.More.random_relic(g), pos = it.pos + Vector2(0, 18)})
	g.drop("coin", it.pos, 12 + g.floor_i * 2)
	g.drop("m_ess", it.pos, 2)

static func draw(g, ci: CanvasItem, it: Dictionary) -> void:
	var p: Vector2 = it.pos
	if it.kind == "brazier":
		ci.draw_rect(Rect2(p + Vector2(-5, -2), Vector2(10, 7)), Color("3a3346"))
		ci.draw_rect(Rect2(p + Vector2(-6, -4), Vector2(12, 3)), Color("a8a7b8"))
		ci.draw_rect(Rect2(p + Vector2(-2, 5), Vector2(4, 3)), Color("6b6779"))
		if it.lit:
			var f = sin(g.time * 12.0 + p.x) * 1.5
			ci.draw_rect(Rect2(p + Vector2(-3, -11 + f), Vector2(6, 8 - f)), Color("f2812f"))
			ci.draw_rect(Rect2(p + Vector2(-1, -8 + f), Vector2(3, 5 - f)), Color("fff2ae"))
		else:
			ci.draw_rect(Rect2(p + Vector2(-3, -5), Vector2(6, 1)), Color("16121d"))
	else:
		var col = Color("ffe45c") if it.on else Color("6b6779")
		ci.draw_rect(Rect2(p + Vector2(-4, 2), Vector2(8, 4)), Color("3a3346"))
		ci.draw_rect(Rect2(p + Vector2(-1, -16), Vector2(2, 19)), Color("a8a7b8"))
		ci.draw_rect(Rect2(p + Vector2(-3, -19), Vector2(6, 4)), col)
		if it.on and int(g.time * 10.0) % 2 == 0:
			ci.draw_rect(Rect2(p + Vector2(-5, -21), Vector2(10, 1)), Color.WHITE)
