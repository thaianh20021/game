extends RefCounted
# Element combinations you can see.
#
# Two elements meeting on a foe is a reaction (game.gd). Every reaction now leaves a FIELD on
# the ground for a few seconds: fire + ice leaves STEAM, and so on. Hitting a foe inside a
# field (or blasting the field) with a THIRD element turns it into a STORM: steam struck by
# lightning becomes a THUNDERSTORM. A storm struck by the fourth element ends in a CATACLYSM.

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")
const Px = preload("res://src/font.gd")
const Book = preload("res://src/book.gd")
const Chem = preload("res://src/chem.gd")
const Storm = preload("res://src/storm.gd")

# pair key (sorted, as in D.REACT) -> [name, colour, what it does]
const FIELD = {
	"fire+ice": ["STEAM", "e8fbff", "EATS ENEMY BULLETS"],
	"fire+tox": ["WILDFIRE", "ff8a3a", "BURNS HARD"],
	"bolt+fire": ["PLASMA", "ff7ad9", "STUNS"],
	"bolt+ice": ["HAIL", "b8c8ff", "CHILLS AND CUTS"],
	"ice+tox": ["ROT", "6fe0b0", "FOES TAKE +50% DAMAGE"],
	"bolt+tox": ["MIASMA", "d4f04a", "POISONS EVERYTHING INSIDE"],
}
# the element that is NOT part of the triple -> [name, colour, what it does]
const STORM = {
	"tox": ["THUNDERSTORM", "ffe45c", "LIGHTNING HUNTS FOES"],
	"bolt": ["ACID RAIN", "a6e84e", "MELTS ARMOR AND HEALTH"],
	"ice": ["FIRESTORM", "ff6a3a", "ROLLING EXPLOSIONS"],
	"fire": ["BLIZZARD", "7adfff", "FREEZES AGAIN AND AGAIN"],
}
const FIELD_R = 30.0
const STORM_R = 72.0

static func name_of(f: Dictionary) -> String:
	if f.has("form"):
		# not a storm but an effect of its own: named after the field it grew from and its form
		# ("MAGMA TORNADO"), unless the player wrote a name for this triple in the notebook
		var own = str(Book.Meta.S.book.get("s_" + f.key, ""))
		return own if own != "" else Chem.field_name(Chem.pair_key(f.els[0], f.els[1])) + " " + Storm.FORM[f.form][0]
	return Book.name(f.key if f.tier == 2 else "s_" + f.key)

static func col_of(f: Dictionary) -> Color:
	if f.tier == 2:
		return Color(FIELD[f.key][1]) if FIELD.has(f.key) else D.REACT[f.key][1]
	return Color(STORM[f.key][1]) if STORM.has(f.key) else Chem.storm_col(f.key)

# A reaction happened at pos.
static func spawn(g, pos: Vector2, key: String) -> void:
	if g.in_lobby and false:
		return
	Book.find(g, key)
	var life = 5.0 * g.Wx.field_life(g, key)
	for f in g.fields:
		if f.tier == 2 and f.key == key and f.pos.distance_to(pos) < 26.0:
			f.life = life
			return
	if g.fields.size() >= D.FIELDS_MAX:
		# the oldest plain field makes room (a three-element effect is never pushed out by a field)
		for i in g.fields.size():
			if g.fields[i].tier == 2:
				g.fields.remove_at(i)
				break
	if g.fields.size() >= D.FIELDS_MAX:
		return
	g.fields.append({pos = pos, r = FIELD_R, key = key, els = Array(key.split("+")), life = life, tick = 0.0, tier = 2, t = 0.0})

# Something of element el struck at pos: fields it touches move up a tier.
static func touch(g, pos: Vector2, el: String, rad: float = 0.0) -> void:
	if el == "" or el == "prism":
		return
	for f in g.fields:
		if f.life <= 0.0 or f.els.has(el) or f.pos.distance_to(pos) > f.r + rad:
			continue
		var col: Color
		if f.tier == 2:
			# only one three-element effect at a time: the new one replaces the old
			for o in g.fields:
				if o.tier == 3 and o.life > 0.0:
					o.life = 0.0
					o.boom = true
			g.mana_cost([el], D.SAT.storm)
			f.els.append(el)
			f.tier = 3
			f.key = Chem.storm_key(f.els)
			f.r = STORM_R
			f.life = 6.0
			f.tick = 0.0
			col = col_of(f)
			# storms of the newer elements take their shape from the element that completed them
			if not STORM.has(f.key):
				Storm.pick(g, f)
			var found = Book.find(g, "s_" + f.key)
			g.banner = {text = found if STORM.has(f.key) else name_of(f), sub = STORM[f.key][2] if STORM.has(f.key) else Storm.FORM[f.form][1], t = 2.6}
			g.charge_res(1.0)
			Sfx.play("roar", 1.6, -4.0)
		else:
			# all four elements: one enormous blast, and every enemy bullet is gone
			f.life = 0.0
			col = Color.WHITE
			g.banner = {text = Book.find(g, "cata"), sub = "ALL FOUR ELEMENTS", t = 2.6}
			g.explode(f.pos, 110.0, (30.0 + g.floor_i * 8.0) * g.st.react, "", 0, Color.WHITE)
			for b in g.bullets:
				if b.team == 1:
					b.dead = true
			g.hitstop = maxf(g.hitstop, 0.12)
		g.rings.append({pos = f.pos, r = f.r, t = 0.0, col = col})
		g.flash(f.pos, 220.0, col, 0.5)
		g.shake_add(6.0)
		Sfx.play("react", 0.6)
		return

static func update(g, dt: float) -> void:
	if g.fields.is_empty():
		return
	var fl: int = g.floor_i
	var m = 3.6 * g.st.react
	for f in g.fields:
		f.life -= dt
		f.t += dt
		f.tick -= dt
		var col: Color = col_of(f)
		# steam and blizzards swallow enemy bullets every frame
		if (f.tier == 2 and f.key == "fire+ice") or (f.tier == 3 and f.key == "fire"):
			for b in g.bullets:
				if b.team == 1 and not b.lob and not b.dead and b.pos.distance_to(f.pos) < f.r:
					b.dead = true
					g.parts.append({pos = b.pos, vel = Vector2(0, -20), life = 0.3, max = 0.3, col = col, size = 2, grav = 0.0})
		Chem.bullets(g, f.els, f.pos, f.r, col)
		if f.has("form"):
			Storm.frame(g, f, dt, m * (2.2 + fl * 0.7), col)
		if f.tick > 0.0:
			continue
		f.tick = 0.5 if f.tier == 2 else 0.35
		var inside = []
		for e in g.enemies:
			if not e.dead and e.d.ai != "dummy" and g.center(e).distance_to(f.pos) < f.r + e.hr:
				inside.append(e)
		if f.tier == 2:
			for e in inside:
				match f.key:
					"fire+ice":
						g.hurt_enemy(e, m * (1.0 + fl * 0.5), "", Vector2.ZERO, true, col)
					"fire+tox":
						g.hurt_enemy(e, m * (3.0 + fl), "", Vector2.ZERO, true, col)
					"bolt+fire":
						g.hurt_enemy(e, m * (1.5 + fl * 0.5), "", Vector2.ZERO, true, col)
						if not e.dead and not e.is_boss:
							e.stun = maxf(e.stun, 0.3)
					"bolt+ice":
						g.hurt_enemy(e, m * (2.0 + fl * 0.5), "", Vector2.ZERO, true, col)
						if not e.dead and not e.is_boss:
							e.frz = maxf(e.frz, 0.2)
					"ice+tox":
						g.hurt_enemy(e, m * (1.0 + fl * 0.3), "", Vector2.ZERO, true, col)
						e.vuln = maxf(e.vuln, 1.0)
					"bolt+tox":
						e.st["tox"] = 4.0
						e.tox_n = max(e.tox_n, 4)
						g.hurt_enemy(e, m * (1.0 + fl * 0.4), "", Vector2.ZERO, true, col)
					_:
						Chem.tick(g, f.els, [e], f.pos, m * (1.2 + fl * 0.4), col)
			continue
		match f.key:
			"tox":
				# thunderstorm: a bolt from the sky on one foe
				if not inside.is_empty():
					var e = inside[g.rng.randi() % inside.size()]
					var c: Vector2 = g.center(e)
					g.bolt(c + Vector2(g.rng.randf_range(-18, 18), -150), c, col)
					g.hurt_enemy(e, m * (6.0 + fl * 2.0), "", Vector2.ZERO, true, col)
					if not e.dead:
						e.stun = maxf(e.stun, 0.15 if e.is_boss else 0.4)
					Sfx.play("shoot_bolt", 0.7, -6.0)
				else:
					var q = f.pos + Vector2.from_angle(g.rng.randf() * TAU) * g.rng.randf() * f.r
					g.bolt(q + Vector2(0, -150), q, col)
			"bolt":
				for e in inside:
					g.hurt_enemy(e, m * (3.0 + fl), "", Vector2.ZERO, true, col)
					e.vuln = maxf(e.vuln, 1.0)
			"ice":
				var q = f.pos + Vector2.from_angle(g.rng.randf() * TAU) * g.rng.randf() * (f.r - 16.0)
				if not inside.is_empty() and g.rng.randf() < 0.6:
					q = inside[g.rng.randi() % inside.size()].pos
				g.explode(q, 24.0, m * (6.0 + fl * 2.0), "", 0, col)
			"fire":
				for e in inside:
					g.hurt_enemy(e, m * (2.0 + fl * 0.7), "", Vector2.ZERO, true, col)
					if not e.dead:
						e.frz = maxf(e.frz, 0.15 if e.is_boss else 0.5)
			_:
				if f.has("form"):
					var pw = m * (2.2 + fl * 0.7)
					Chem.tick(g, f.els, Storm.targets(g, f, pw, col), f.pos, pw * Storm.SCALE[f.form], col)
				else:
					Chem.tick(g, f.els, inside, f.pos, m * (2.2 + fl * 0.7), col)
	g.fields = g.fields.filter(func(f): return f.life > 0.0)

# ---- drawing ---------------------------------------------------------------------

static func draw(g, ci: CanvasItem) -> void:
	var t: float = g.time
	for f in g.fields:
		if not g.on_screen(f.pos, f.r + 20.0):
			continue
		var col: Color = col_of(f)
		var a = clampf(f.life, 0.0, 1.0) * clampf(f.t * 4.0, 0.0, 1.0)
		var p: Vector2 = f.pos
		if f.tier == 2:
			ci.draw_circle(p, f.r, Color(col.r, col.g, col.b, 0.14 * a))
			for i in 5:
				var q = p + Vector2.from_angle(t * 0.8 + i * TAU / 5.0) * f.r * 0.5
				ci.draw_circle(q, f.r * 0.42 + sin(t * 3.0 + i) * 2.0, Color(col.r, col.g, col.b, 0.13 * a))
			ci.draw_arc(p, f.r, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.75 * a), 1.0)
			if g.rng.randf() < 0.5:
				var q = p + Vector2.from_angle(g.rng.randf() * TAU) * g.rng.randf() * f.r
				g.parts.append({pos = q, vel = Vector2(g.rng.randf_range(-6, 6), -22 if f.key != "bolt+ice" else 40), life = 0.5, max = 0.5, col = col, size = 1 + g.rng.randi() % 2, grav = 0.0})
		elif f.has("form"):
			Storm.draw(g, ci, f, col, a)
		else:
			ci.draw_circle(p, f.r, Color(col.r, col.g, col.b, 0.1 * a))
			ci.draw_circle(p, f.r * 0.6, Color(0.05, 0.03, 0.1, 0.25 * a))
			for i in 6:
				var a0 = t * 1.5 + i * TAU / 6.0
				ci.draw_arc(p, f.r, a0, a0 + 0.7, 8, Color(col.r, col.g, col.b, 0.9 * a), 2.0)
				ci.draw_arc(p, f.r * 0.66, -a0, -a0 + 0.9, 8, Color(1, 1, 1, 0.35 * a), 1.0)
			# weather falling through the whole area
			for i in 3:
				var q = p + Vector2.from_angle(g.rng.randf() * TAU) * g.rng.randf() * f.r
				var fall = Vector2(-30, 150)
				if f.key == "ice":
					fall = Vector2(g.rng.randf_range(-30, 30), -80)
				g.parts.append({pos = q - fall * 0.2, vel = fall, life = 0.22, max = 0.22, col = col if i else Color.WHITE, size = 1, grav = 0.0})

static func draw_names(g, ci: CanvasItem) -> void:
	for f in g.fields:
		if not g.on_screen(f.pos, 20.0):
			continue
		var col: Color = col_of(f)
		var a = clampf(f.life, 0.0, 1.0)
		var at = f.pos + Vector2(0, -minf(f.r, 60.0) - 10.0)
		Px.ctext(ci, at, name_of(f), Color(col.r, col.g, col.b, a), 2 if f.tier == 3 else 1)
		# the elements that made it
		var x = f.pos.x - f.els.size() * 4.5
		for el in f.els:
			ci.draw_texture(g.Art.T["ic_" + el], Vector2(roundf(x), roundf(at.y - 11.0)), Color(1, 1, 1, a))
			x += 9.0

static func lights(g, l: Callable) -> void:
	for f in g.fields:
		if g.on_screen(f.pos, f.r + 40.0):
			l.call(f.pos, f.r * (2.0 if f.tier == 2 else 1.7), col_of(f) * (0.3 if f.tier == 2 else 0.4))
