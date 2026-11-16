extends RefCounted
# Foes that answer weapon mechanics (owner, 2026-11-16). Every floor from the first on has one
# kind of answer, chosen from the run seed like the weather, worn by part of its foes. The Word
# Forge marks each fusion that is strong or weak against it, so the floor shapes the pick.
#
#   shell   SHELLED    weapon hits do a quarter; a gathered or heavy hit (or a release) cracks it
#   anchor  ANCHORED   cannot be pushed; big single hits (gathered, heavy) are halved
#   purge   PURIFIER   wipes hexes and elements off itself and the foes around it
#   net     NETTER     catches spirits that come near
#   damp    DAMPER     hitting it builds no rally, and rally drains while you stand close
#
# Weather is never cut by any of these: fields and storms still do the killing.

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")
const Px = preload("res://src/font.gd")

# name, colour, what to do about it, mechanics that do well, mechanics that do badly
const KIND = {
	"shell": ["SHELLED", Color("c9c3b4"), "GATHERED OR HEAVY HITS CRACK SHELLS", ["charge", "heavy"], ["rally", "summon"]],
	"anchor": ["ANCHORED", Color("8fa3c8"), "NO PUSH. BIG HITS ARE HALVED", ["rally", "summon"], ["heavy", "charge"]],
	"purge": ["PURIFIER", Color("f4f0ff"), "IT WIPES HEXES AND ELEMENTS. KILL IT FIRST", ["heavy", "charge"], ["hex"]],
	"net": ["NETTER", Color("e0b040"), "IT CATCHES SPIRITS. HEX OR RALLY INSTEAD", ["hex", "rally"], ["summon"]],
	"damp": ["DAMPER", Color("7a8cff"), "IT DRAINS RALLY NEARBY. HIT IT HARD", ["hex", "heavy"], ["rally"]],
}
const ORDER = ["shell", "anchor", "purge", "net", "damp"]

# The answer of a floor: a pure function of the seed, so LAN guests and seeded runs agree.
static func of(seed: int, floor_i: int) -> String:
	if floor_i < 1:
		return ""
	var rng = RandomNumberGenerator.new()
	rng.seed = hash([seed, floor_i, "ctr"])
	return ORDER[rng.randi() % ORDER.size()]

static func now(g) -> String:
	if g.in_lobby or not g.drill.is_empty():
		return ""
	return of(g.run_seed, g.floor_i)

# +1 if the mechanic does well on this floor, -1 if badly, 0 if neither.
static func fit(g, mech: String) -> int:
	var k = now(g)
	if k == "":
		return 0
	if KIND[k][3].has(mech):
		return 1
	if KIND[k][4].has(mech):
		return -1
	return 0

# Shown a moment after the floor's own banner.
static func floor_start(g) -> void:
	var k = now(g)
	if k == "":
		return
	var f = g.floor_i
	g.after(4.8, func():
		if g.floor_i == f and not g.in_lobby and g.banner.t <= 0.3:
			g.banner = {text = KIND[k][0] + " FOES", sub = KIND[k][2], t = 3.0})

# Called from Stage.mark for every ordinary foe or elite that spawns in a locked room.
static func mark(g, e: Dictionary) -> void:
	var k = now(g)
	if k == "" or e.is_boss or e.has("ctr") or e.has("eats"):
		return
	if g.rng.randf() > minf(D.WMOD.ctr_max, D.WMOD.ctr + D.WMOD.ctr_floor * g.floor_i):
		return
	put(g, e, k)

static func put(g, e: Dictionary, k: String) -> void:
	e.ctr = k
	match k:
		"shell": e.shell = true
		"purge": e.purge_t = D.WMOD.purge_cd
		"net": e.net_t = 0.5

# A hit, after Stage.amount. big: a gathered shot, a heavy hit or a release.
static func amount(g, e: Dictionary, amt: float, weather: bool, big: bool) -> float:
	if weather or not e.has("ctr"):
		return amt
	var c: Vector2 = g.center(e)
	match e.ctr:
		"shell":
			if e.get("shell", false):
				if big:
					e.shell = false
					g.label(c + Vector2(0, -e.h2 - 16.0), "SHELL CRACKED", KIND.shell[1], true)
					g.burst(c, 16, KIND.shell[1], 130.0, 0.45, 200.0)
					g.shake_add(2.5)
					Sfx.play("thud", 1.4)
				else:
					amt *= D.WMOD.shell_cut
					g.tip("shell", "SHELLED", "SMALL HITS BOUNCE OFF. A GATHERED OR HEAVY HIT CRACKS IT.")
		"anchor":
			if big:
				amt *= D.WMOD.anchor_cut
				g.tip("anchor", "ANCHORED", "IT CANNOT BE PUSHED AND SOAKS UP BIG HITS. MANY SMALL ONES WORK.")
	return amt

# Whether the hit being dealt right now counts as big.
static func big_hit(g, rel: bool) -> bool:
	if rel or g.hit_big:
		return true
	var p: Dictionary = g.p
	if p.is_empty() or not p.has("weapons"):
		return false
	return float(p.get("wk", 0.0)) >= 0.5 or g.WMods.has(p, "heavy")

# Per foe, every frame (from Stage.tick_foe).
static func tick(g, e: Dictionary, dt: float) -> void:
	if not e.has("ctr"):
		return
	match e.ctr:
		"anchor":
			e.kb = Vector2.ZERO
		"purge":
			# it cannot be hexed itself, and every few seconds it cleans those around it
			e.erase("hex")
			e.vuln = 0.0
			if e.frz > 0.0 or e.stun > 0.0:
				return
			e.purge_t -= dt
			if e.purge_t <= 0.0:
				e.purge_t = D.WMOD.purge_cd
				var c: Vector2 = g.center(e)
				var n = 0
				for o in g.enemies:
					if o.dead or g.center(o).distance_to(c) > D.WMOD.purge_r:
						continue
					if o.has("hex") or o.vuln > 0.0 or not o.st.is_empty():
						n += 1
					o.erase("hex")
					o.vuln = 0.0
					o.st.clear()
					o.tox_n = 0
					o.chill = 0
				if n > 0:
					g.rings.append({pos = c, r = D.WMOD.purge_r, t = 0.0, col = KIND.purge[1]})
					g.label(c + Vector2(0, -e.h2 - 16.0), "PURGED", KIND.purge[1])
					Sfx.play("fx_bless", 0.7)
					g.tip("purge", "PURIFIER", "IT WIPES HEXES AND ELEMENTS AROUND IT. KILL IT FIRST.")
		"net":
			e.net_t -= dt
			if e.net_t <= 0.0:
				e.net_t = 0.3
				var c2: Vector2 = g.center(e)
				for s in g.spirits:
					if s.pos.distance_to(c2) < D.WMOD.net_r:
						g.spirits.erase(s)
						e.net_t = D.WMOD.net_cd
						g.bolt(c2, s.pos, KIND.net[1])
						g.burst(s.pos, 8, KIND.net[1], 60.0, 0.3)
						g.label(c2 + Vector2(0, -e.h2 - 16.0), "CAUGHT", KIND.net[1])
						Sfx.play("deny", 1.6)
						g.tip("net", "NETTER", "IT CATCHES SPIRITS. KILL IT OR KEEP THEM AWAY.")
						break
		"damp":
			e.damp_t = float(e.get("damp_t", 0.0)) - dt
			if e.damp_t <= 0.0:
				e.damp_t = D.WMOD.damp_cd
				for pl in g.players:
					if int(pl.get("rally", 0)) > 0 and pl.pos.distance_to(e.pos) < D.WMOD.damp_r:
						pl.rally -= 1
						g.label(pl.pos + Vector2(0, -24), "DAMPED", KIND.damp[1])
						g.tip("damp", "DAMPER", "IT DRAINS RALLY CLOSE BY AND HITS ON IT BUILD NONE.")

static func draw_foe(g, ci: CanvasItem, e: Dictionary, topy: float) -> void:
	if not e.has("ctr"):
		return
	var col: Color = KIND[e.ctr][1]
	var c: Vector2 = g.center(e)
	var at = Vector2(roundf(e.pos.x), roundf(topy - 19.0))
	match e.ctr:
		"shell":
			if e.get("shell", false):
				# plates around the body
				for i in 4:
					var a = i * TAU / 4.0 + 0.4
					ci.draw_arc(c, e.hr + 3.0, a, a + 1.0, 5, col, 2.0)
				ci.draw_rect(Rect2(at - Vector2(3, 2), Vector2(6, 4)), col)
				ci.draw_rect(Rect2(at - Vector2(1, 1), Vector2(2, 2)), Color("16121d"))
		"anchor":
			ci.draw_line(at + Vector2(0, -3), at + Vector2(0, 3), col, 1.0)
			ci.draw_line(at + Vector2(-3, -1), at + Vector2(3, -1), col, 1.0)
			ci.draw_arc(at + Vector2(0, 0), 3.0, 0.3, PI - 0.3, 5, col, 1.0)
			ci.draw_line(e.pos + Vector2(-e.r, e.r), e.pos + Vector2(e.r, e.r), Color(col.r, col.g, col.b, 0.6), 1.0)
		"purge":
			var k = 1.0 - clampf(float(e.get("purge_t", 0.0)) / D.WMOD.purge_cd, 0.0, 1.0)
			ci.draw_arc(at, 3.0, 0.0, TAU, 8, col, 1.0)
			ci.draw_arc(c, e.hr + 4.0 + 8.0 * k, 0.0, TAU, 16, Color(col.r, col.g, col.b, 0.15 + 0.4 * k), 1.0)
		"net":
			for i in 3:
				ci.draw_line(at + Vector2(-3 + i * 3, -3), at + Vector2(-3 + i * 3, 3), col, 1.0)
				ci.draw_line(at + Vector2(-3, -3 + i * 3), at + Vector2(3, -3 + i * 3), col, 1.0)
		"damp":
			ci.draw_line(at + Vector2(0, -3), at + Vector2(0, 3), col, 1.0)
			ci.draw_line(at + Vector2(-3, 0), at + Vector2(0, 3), col, 1.0)
			ci.draw_line(at + Vector2(3, 0), at + Vector2(0, 3), col, 1.0)
			if int(g.time * 3.0) % 2 == 0:
				ci.draw_arc(e.pos, D.WMOD.damp_r, 0.0, TAU, 28, Color(col.r, col.g, col.b, 0.18), 1.0)

# The forge's word on a fusion: "GOOD HERE" or "POOR HERE".
static func draw_fit(g, ci: CanvasItem, at: Vector2, mechs: Array) -> void:
	var f = 0
	for m in mechs:
		f += fit(g, m)
	if f == 0:
		return
	var k = now(g)
	Px.ctext(ci, at, ("GOOD VS " if f > 0 else "POOR VS ") + KIND[k][0], Color("8be07a") if f > 0 else Color("ff6a6a"))
