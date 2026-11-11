extends RefCounted
# Elemental resonance: the answer for builds that stick to ONE element.
#
# Reactions need two different elements. Resonance rewards the opposite: every hit of the
# same element on a foe adds a stack (shown as motes circling it). At 5 stacks the element
# erupts in its own way. If the party carries the element twice (two weapons, a weapon and
# a pet, or one each in co-op) it is "attuned" and needs only 4. Bosses need 2 more.
# Stacks fade after 4 seconds without a hit, and hitting with another element resets them.

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")
const Meta = preload("res://src/meta.gd")

const NAME = {"fire": "ERUPTION", "ice": "GLACIER", "bolt": "THUNDERSTRIKE", "tox": "BLOOM",
	"stone": "LANDSLIDE", "wind": "CYCLONE", "light": "SUNFLARE", "void": "IMPLOSION",
	"water": "DELUGE", "leaf": "OVERGROWTH", "earth": "EARTHQUAKE", "metal": "BLADESTORM", "wood": "THORNWALL", "mech": "CLOCKBURST", "x": "PARADOX"}

static func count(g, el: String) -> int:
	var n = 0
	for pl in g.players:
		for w in pl.weapons:
			if w != null:
				if w.el == el:
					n += 1
				if w.get("el2", "") == el:
					n += 1
		if pl.pet != null and Meta.PETS[pl.pet.id].el == el:
			n += 1
	return n

static func attuned(g) -> Array:
	var out = []
	for el in D.EL:
		if count(g, el) >= 2:
			out.append(el)
	return out

static func need(g, e: Dictionary, el: String) -> int:
	return 5 - (1 if count(g, el) >= 2 else 0) + (2 if e.is_boss else 0)

static func tick(e: Dictionary, dt: float) -> void:
	var rs = e.get("rs", null)
	if rs != null:
		rs.t -= dt
		if rs.t <= 0.0:
			e.rs = null

static func add(g, e: Dictionary, el: String) -> void:
	if e.d.ai == "dummy" and not g.in_lobby:
		return
	var rs = e.get("rs", null)
	if rs == null or rs.el != el:
		rs = {el = el, n = 0, t = 0.0, need = need(g, e, el)}
		e.rs = rs
	rs.n += 1
	rs.t = 4.0
	if rs.n >= rs.need:
		e.rs = null
		burst(g, e, el)

static func burst(g, e: Dictionary, el: String) -> void:
	var c: Vector2 = g.center(e)
	var col: Color = D.EL_COL[el]
	var base = (8.0 + g.floor_i * 2.5) * g.st.react
	g.label(c + Vector2(0, -e.h2 - 14.0), g.Book.find(g, "r_" + el) if g.Book.DEF.has("r_" + el) else NAME[el], col, true)
	g.tip("reso", "RESONANCE: " + NAME[el], "SAME ELEMENT, SAME FOE, AGAIN AND AGAIN")
	g.charge_res(0.5)
	g.hitstop = maxf(g.hitstop, 0.03)
	g.shake_add(3.0)
	g.flash(c, 80.0, col, 0.3)
	Sfx.play("react", 0.8)
	match el:
		"fire":
			# the ground itself catches fire
			g.explode(c, 44.0, base * 1.2, "", 0, col)
			g.Ext.add_zone(g, e.pos, 22.0, "fire", 3.0)
			for i in 10:
				g.parts.append({pos = c, vel = Vector2(g.rng.randf_range(-30, 30), g.rng.randf_range(-140, -60)), life = 0.6, max = 0.6, col = Color("ffd24a"), size = 2, grav = 160.0})
		"ice":
			# freezes the target solid and chills everything around it
			g.hurt_enemy(e, base, "", Vector2.ZERO, true, col)
			for o in g.enemies:
				if o.dead or g.center(o).distance_to(c) > 54.0:
					continue
				o.frz = maxf(o.frz, (0.6 if o.is_boss else 1.6) if o.uid == e.uid else (0.3 if o.is_boss else 0.9))
				o.st["ice"] = 4.0
			for i in 8:
				var a = i * TAU / 8.0
				g.bolts.append({a = c + Vector2.from_angle(a) * 8.0, b = c + Vector2.from_angle(a) * 30.0, col = Color("e8fbff"), t = 0.25, straight = true})
			g.rings.append({pos = c, r = 54.0, t = 0.0, col = col})
			Sfx.play("freeze")
		"bolt":
			# a strike from above that jumps to five more foes
			g.bolt(c + Vector2(g.rng.randf_range(-14, 14), -140), c, col)
			g.hurt_enemy(e, base * 1.5, "", Vector2.ZERO, true, col)
			var hitl = [e]
			var cur = e
			for i in 5:
				var o = g.nearest_enemy(g.center(cur), 90.0, hitl)
				if o == null:
					break
				g.bolt(g.center(cur), g.center(o), col)
				hitl.append(o)
				cur = o
			for o in hitl:
				if o.uid != e.uid:
					g.hurt_enemy(o, base * 0.6, "", Vector2.ZERO, true, col)
				if not o.dead:
					o.stun = maxf(o.stun, 0.2 if o.is_boss else 0.6)
			Sfx.play("boom", 1.5, -4.0)
		"tox":
			# a cloud that maxes out poison on everything inside
			g.Ext.add_zone(g, e.pos, 30.0, "tox", 4.0)
			for o in g.enemies:
				if not o.dead and g.center(o).distance_to(c) < 50.0:
					o.st["tox"] = 6.0
					o.tox_n = 8 if g.p.syn.has("plaguedoc") else 5
			g.hurt_enemy(e, base * 0.8, "", Vector2.ZERO, true, col)
			g.rings.append({pos = c, r = 50.0, t = 0.0, col = col})
			for i in 12:
				g.parts.append({pos = c + Vector2(g.rng.randf_range(-24, 24), g.rng.randf_range(-10, 10)), vel = Vector2(0, -16), life = 0.9, max = 0.9, col = col, size = 2, grav = -20.0})
		_:
			# the new elements: a blast that lays the element's aspect on everything close, twice over
			g.explode(c, 44.0, base * 1.4, "", 0, col)
			for o in g.enemies:
				if not o.dead and g.center(o).distance_to(c) < 50.0:
					g.Chem.touch(g, o, el, base, c, col)
					g.Chem.touch(g, o, el, base, c, col)

# Stacks circle the foe; the ring closes as the burst gets near.
static func draw(g, ci: CanvasItem, e: Dictionary) -> void:
	var rs = e.get("rs", null)
	if rs == null:
		return
	var c: Vector2 = g.center(e)
	var col: Color = D.EL_COL[rs.el]
	var k = float(rs.n) / float(rs.need)
	var rad = e.h2 + 7.0
	ci.draw_arc(c, rad, -PI / 2.0, -PI / 2.0 + TAU * k, 18, Color(col.r, col.g, col.b, 0.35 + 0.4 * k), 1.0)
	for i in int(rs.n):
		var a = g.time * (2.0 + 3.0 * k) + i * TAU / float(rs.need)
		var q = (c + Vector2(cos(a) * rad, sin(a) * rad * 0.6)).round()
		ci.draw_rect(Rect2(q - Vector2(1, 1), Vector2(3, 3)), col)
		ci.draw_rect(Rect2(q, Vector2(1, 1)), Color.WHITE)
