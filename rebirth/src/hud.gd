extends RefCounted
# All screen-space drawing: title, in-run HUD, minimap, hub menus, overlays.

const Art = preload("res://src/art.gd")
const Px = preload("res://src/font.gd")
const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Touch = preload("res://src/touch.gd")
const Hub = preload("res://src/hub.gd")
const Reso = preload("res://src/reso.gd")
const Pets = preload("res://src/pets.gd")
const Forge = preload("res://src/forge.gd")
const Combo = preload("res://src/combo.gd")
const Wish = preload("res://src/wish.gd")
const Nemesis = preload("res://src/nemesis.gd")
const Book = preload("res://src/book.gd")
const Spell = preload("res://src/spell.gd")
const Wx = preload("res://src/sky.gd")

const VW = 480.0
const VH = 270.0

static var INK = Color("120e18")
static var DIM = Color("6b6779")
static var PALE = Color("d9d4c7")
static var GOLD = Color("ffd24a")
static var GEM = Color("e56db2")

const REACT_HELP = [
	["fire", "ice", "MELT - LEAVES STEAM: EATS ENEMY BULLETS"],
	["fire", "tox", "BLAST - LEAVES WILDFIRE: BURNS HARD"],
	["bolt", "fire", "OVERLOAD - LEAVES PLASMA: STUNS"],
	["bolt", "ice", "SHATTER - LEAVES HAIL: CHILLS AND CUTS"],
	["ice", "tox", "BLIGHT - LEAVES ROT: +50% DAMAGE TAKEN"],
	["bolt", "tox", "PLAGUE - LEAVES MIASMA: POISONS ALL"],
]
const MENU_TITLE = {"tree": "SKILL TREE", "armor": "HERO UPGRADES", "beast": "PETS AND MOUNTS", "fuse": "SOUL ALTAR", "loom": "SOUL LOOM", "board": "RUN BOARD", "codex": "ARCHIVE", "garden": "GARDEN", "coop": "CO-OP", "quest": "BOUNTY BOARD", "trophy": "TROPHY CASE", "armory": "QUARTERMASTER", "brew": "KITCHEN", "tailor": "TAILOR", "opts": "SETTINGS", "bench": "WORKBENCH", "prep": "QUARTERMASTER", "book": "ALCHEMY NOTEBOOK", "spell": "LECTERN"}

static func buff_rect(i: int) -> Rect2:
	return Rect2(55 + i * 127, 84, 116, 112)

static func menu_rect(kind: String, i: int) -> Rect2:
	if kind == "tree":
		return Rect2(98 + (i / 3) * 98, 80 + (i % 3) * 40, 88, 30)
	return Rect2(100, 52 + i * 21, 280, 20)

static func Hud_self():
	return load("res://src/hud.gd")

static func panel(ci: CanvasItem, r: Rect2, fill: Color = Color(0.07, 0.05, 0.12, 0.9), border: Color = Color("6b6779")) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 2)), fill)
	ci.draw_rect(Rect2(r.position.x + 1, r.position.y, r.size.x - 2, 1), border)
	ci.draw_rect(Rect2(r.position.x + 1, r.end.y - 1, r.size.x - 2, 1), border.darkened(0.3))
	ci.draw_rect(Rect2(r.position.x, r.position.y + 1, 1, r.size.y - 2), border)
	ci.draw_rect(Rect2(r.end.x - 1, r.position.y + 1, 1, r.size.y - 2), border.darkened(0.3))

static func wrap_text(s: String, n: int) -> Array:
	var lines = []
	var cur = ""
	for word in s.split(" "):
		if cur.length() + word.length() + 1 > n and cur != "":
			lines.append(cur)
			cur = word
		else:
			cur = word if cur == "" else cur + " " + word
	if cur != "":
		lines.append(cur)
	return lines

static func big(ci: CanvasItem, tex: Texture2D, pos: Vector2, sc: float, mod: Color = Color.WHITE) -> void:
	ci.draw_texture_rect(tex, Rect2(pos.round(), tex.get_size() * sc), false, mod)

static func draw(g, ci: CanvasItem) -> void:
	match g.state:
		"title":
			draw_title(g, ci)
		_:
			Wx.draw(g, ci)
			draw_play(g, ci)
			g.Tutor.draw(g, ci, Hud_self())
			match g.state:
				"pause": draw_pause(g, ci)
				"buff": draw_buff(g, ci)
				"menu": draw_menu(g, ci)
				"forge": Forge.draw(g, ci, Hud_self())
				"say": Wish.draw_say(g, ci, Hud_self())
				"talk": draw_talk(g, ci)
				"dead": draw_end(g, ci, false)
				"win": draw_end(g, ci, true)
	if g.fade > 0.0:
		ci.draw_rect(g.full(), Color(0.02, 0.01, 0.04, minf(1.0, g.fade)))
	if g.tin.on:
		Touch.draw(g, ci)
		if g.state == "menu":
			panel(ci, Rect2(368, 31, 20, 16), Color(0.2, 0.08, 0.08, 0.95), Color("ff6a6a"))
			Px.text(ci, Vector2(375, 36), "X", Color("ff6a6a"))
		return
	var m = g.mouse().round()
	var cc = Color("f6f2e6")
	if g.state == "play" and not g.p.is_empty():
		cc = D.EL_COL[g.act_el(g.p)]
	for d in [Vector2(-5, 0), Vector2(3, 0), Vector2(0, -5), Vector2(0, 3)]:
		ci.draw_rect(Rect2(m + d + Vector2(-1, -1), Vector2(5, 3) if d.y == 0.0 else Vector2(3, 5)), INK)
	for d in [Vector2(-5, 0), Vector2(3, 0), Vector2(0, -5), Vector2(0, 3)]:
		ci.draw_rect(Rect2(m + d, Vector2(3, 1) if d.y == 0.0 else Vector2(1, 3)), cc)
	ci.draw_rect(Rect2(m, Vector2(1, 1)), Color.WHITE)

# ---- title -----------------------------------------------------------------------

static func draw_title(g, ci: CanvasItem) -> void:
	var t = g.time
	ci.draw_rect(g.full(), Color("160f24"))
	for i in 9:
		ci.draw_rect(Rect2(-g.hud_off.x, i * 30, g.VW, 30), Color("0d0a16").lerp(Color("241a38"), i / 9.0))
	for i in 70:
		var s = float(i) * 12.9898
		var x = fmod(absf(sin(s) * 43758.5) * VW + sin(t * 0.3 + i) * 12.0, VW)
		var y = VH - fmod(t * (8.0 + fmod(i * 7.3, 22.0)) + i * 37.0, VH + 20.0)
		var c: Color = D.EL_COL[D.EL[i % 4]]
		ci.draw_rect(Rect2(x, y, 1 + i % 2, 1 + i % 2), Color(c.r, c.g, c.b, 0.25 + 0.5 * absf(sin(t * 2.0 + i))))
	var ec: Color = D.EL_COL[D.EL[int(t * 0.5) % 4]]
	ci.draw_circle(Vector2(240, 80), 110.0, Color(ec.r, ec.g, ec.b, 0.05))
	ci.draw_circle(Vector2(240, 80), 70.0, Color(ec.r, ec.g, ec.b, 0.06))
	Px.ctext(ci, Vector2(240, 54 + sin(t * 2.0) * 2.0), "DUNGEON CORE", GOLD, 5)
	Px.ctext(ci, Vector2(240, 100), "ELEMENTAL REBIRTH", ec, 2)
	for i in D.HEROES.size():
		var id: String = D.HEROES[i].id
		var tex: Texture2D = Art.T[["h_" + id + "_1", "h_" + id, "h_" + id + "_2", "h_" + id][int(t * 7.0 + i) % 4]]
		big(ci, tex, Vector2(150 + i * 50, 140), 3.0)
	var pulse = 0.5 + 0.5 * sin(t * 4.0)
	Px.ctext(ci, Vector2(240, 208), g.Pad.hint(g, "PRESS ENTER"), GOLD.lerp(Color.WHITE, pulse), 2)
	Px.ctext(ci, Vector2(240, 256), g.Pad.hint(g, "WASD MOVE  MOUSE AIM  LMB FIRE  RMB + F SKILLS  R BURST  SPACE DASH  Q SWAP  E USE"), DIM)
	if Meta.S.best > 0:
		Px.text(ci, Vector2(6, 6), "BEST FLOOR %d" % Meta.S.best, DIM)
	if Meta.S.wins > 0:
		Px.text(ci, Vector2(6, 16), "CLEARS %d" % Meta.S.wins, GOLD)
	big(ci, Art.T["gem"], Vector2(440, 5), 1.0)
	Px.text(ci, Vector2(451, 6), str(Meta.S.gems), GEM)

# ---- in-run hud ------------------------------------------------------------------

static func bar(ci: CanvasItem, pos: Vector2, w: float, v: float, mx: float, col: Color, ticks: bool) -> void:
	ci.draw_rect(Rect2(pos - Vector2(1, 1), Vector2(w + 2, 8)), INK)
	ci.draw_rect(Rect2(pos, Vector2(w, 6)), Color(col.r * 0.22, col.g * 0.22, col.b * 0.22))
	var fw = roundf(w * clampf(v / maxf(mx, 1.0), 0.0, 1.0))
	ci.draw_rect(Rect2(pos, Vector2(fw, 6)), col)
	ci.draw_rect(Rect2(pos, Vector2(fw, 2)), col.lightened(0.35))
	if ticks and mx <= 20:
		for i in range(1, int(mx)):
			ci.draw_rect(Rect2(pos.x + roundf(w * i / mx), pos.y, 1, 6), INK)

static func skill_box(g, ci: CanvasItem, y: float, slot: int, keyname: String, ecol: Color) -> void:
	var p = g.p
	var cd: float = p.skill_cd if slot == 0 else p.skill2_cd
	var def = D.SKILLS[p.skills[slot]]
	var sr = Rect2(3, y, 20, 20)
	var ready = cd <= 0.0
	panel(ci, sr, Color(0.07, 0.05, 0.12, 0.9), ecol if ready else DIM)
	big(ci, Art.T["sk_" + p.skills[slot]], sr.position + Vector2(4, 4), 1.0, ecol if ready else Color(0.4, 0.4, 0.48))
	if not ready:
		ci.draw_rect(Rect2(sr.position.x + 1, sr.position.y + 1, 18, 18.0 * clampf(cd / (def.cd * p.sk.cdm), 0.0, 1.0)), Color(0.02, 0.01, 0.05, 0.75))
		Px.ctext(ci, sr.position + Vector2(10, 7), str(int(ceil(cd))), PALE)
	Px.text(ci, Vector2(26, y + 2), keyname, GOLD if ready else DIM)
	Px.text(ci, Vector2(26, y + 11), g.skill_name(slot), ecol if ready else DIM)

# The shape a weapon gives to whatever element passes through it.
static func form_name(def: Dictionary) -> String:
	match def.type:
		"melee": return "ARC"
		"beam": return "BEAM"
		"chain": return "CHAIN"
		"lob": return "LOB"
	if int(def.get("n", 1)) > 1:
		return "FAN"
	if float(def.get("aoe", 0.0)) > 0.0:
		return "BURST"
	if int(def.get("pierce", 0)) > 0:
		return "LANCE"
	if float(def.get("homing", 0.0)) > 0.0:
		return "SEEKER"
	return "BOLT"

static func weapon_els(w) -> Array:
	var out = []
	if w != null:
		for k in [w.el, w.get("el2", "")]:
			if k != "" and k != "prism" and not out.has(k):
				out.append(k)
	return out

static func draw_play(g, ci: CanvasItem) -> void:
	var p = g.p
	if p.is_empty():
		return
	var t = g.time
	# On a screen wider than the 480 sheet the status block hugs the left edge, the map (and,
	# without touch buttons, the weapon panel) the right edge; banners stay in the middle.
	var edge = Vector2(g.hud_edge, 0)
	ci.draw_set_transform(-edge)
	panel(ci, Rect2(3, 3, 104, 36))
	big(ci, Art.T["heart"], Vector2(6, 5), 1.0)
	bar(ci, Vector2(18, 7), 60, p.hp, p.mhp, Color("e0444c"), true)
	Px.text(ci, Vector2(82, 6), "%d/%d" % [p.hp, p.mhp], PALE)
	ci.draw_rect(Rect2(7, 16, 7, 6), Color("a8a7b8"))
	ci.draw_rect(Rect2(8, 22, 5, 1), Color("a8a7b8"))
	ci.draw_rect(Rect2(9, 17, 3, 3), Color("f6f2e6"))
	bar(ci, Vector2(18, 17), 60, p.ar, p.mar, Color("a8a7b8") if p.noregen <= 0.0 else Color("8fb060"), true)
	Px.text(ci, Vector2(82, 16), "%d/%d" % [p.ar, p.mar], PALE)
	big(ci, Art.T["orb"], Vector2(7, 25), 1.0)
	if p.has("sat"):
		# mana: one pool for each carried element
		for i in 3:
			bar(ci, Vector2(18 + i * 20.5, 27), 19, p.sat[i], 1.0, Color("6b6779") if p.spent[i] else D.EL_COL[p.els[i]], false)
			if i == p.eli:
				ci.draw_rect(Rect2(18 + i * 20.5, 33, 19, 1), Color.WHITE)
	else:
		bar(ci, Vector2(18, 27), 60, p.en, p.men, Color("4aa8f0"), false)
	Px.text(ci, Vector2(82, 26), str(int(p.en)), PALE)
	var sx = 110.0
	if p.slow > 0.0:
		big(ci, Art.T["ic_ice"], Vector2(sx, 5), 1.0)
		sx += 10.0
	if p.noregen > 0.0:
		big(ci, Art.T["ic_tox"], Vector2(sx, 5), 1.0)
	if p.pet != null:
		# pet: skill cooldown and hearts
		big(ci, Art.T["pet_" + p.pet.id], Vector2(111, 16), 1.0)
		var ph = int(p.pet.get("hearts", 0))
		var pk = clampf(1.0 - float(p.pet.get("sk", 0.0)) / (Pets.CD * (1.0 - 0.1 * ph)), 0.0, 1.0)
		ci.draw_rect(Rect2(122, 17, 22, 4), INK)
		ci.draw_rect(Rect2(123, 18, 20.0 * pk, 2), D.EL_COL[Meta.PETS[p.pet.id].el] if pk < 1.0 else Color.WHITE)
		for i in Pets.MAX_HEARTS:
			ci.draw_rect(Rect2(122 + i * 6, 23, 5, 4), INK)
			ci.draw_rect(Rect2(123 + i * 6, 24, 3, 2), Color("ff6a7a") if i < ph else Color("3a3346"))
		if g.in_lobby:
			big(ci, Art.T["treat"], Vector2(146, 21), 1.0)
			Px.text(ci, Vector2(153, 22), str(int(Meta.S.treats)), Color("ff6a7a"))

	if g.in_lobby:
		big(ci, Art.T["gem"], Vector2(5, 42), 1.0)
		Px.text(ci, Vector2(16, 43), str(Meta.S.gems), GEM)
		big(ci, Art.T["scrap"], Vector2(78, 41), 1.0)
		Px.text(ci, Vector2(89, 43), str(int(Meta.S.scrap)), PALE)
	else:
		big(ci, Art.T["coin"], Vector2(5, 42), 1.0)
		Px.text(ci, Vector2(16, 43), str(p.gold), GOLD)
		if p.keys > 0:
			big(ci, Art.T["key"], Vector2(76, 40), 1.0)
			Px.text(ci, Vector2(86, 43), str(p.keys), GOLD)
	if p.mount != null:
		for i in p.mount.mhp:
			ci.draw_rect(Rect2(46 + i * 6, 43, 5, 6), INK)
			ci.draw_rect(Rect2(47 + i * 6, 44, 3, 4), Color("c99b5c") if i < p.mount.hp else Color("3a3346"))

	var wel: String = g.act_el(p)
	var ecol: Color = D.EL_COL[wel]
	skill_box(g, ci, 54, 0, "LB" if g.p1_pad else ("1" if g.tin.on else "RMB"), ecol)
	skill_box(g, ci, 76, 1, "RB" if g.p1_pad else ("2" if g.tin.on else "F"), ecol)
	# resonance: fills from reactions, R spends it
	ci.draw_rect(Rect2(3, 99, 62, 6), INK)
	var full = p.res >= 1.0
	var rcol = Color("e58cff") if not full else Color("e58cff").lerp(Color.WHITE, 0.5 + 0.5 * sin(t * 10.0))
	ci.draw_rect(Rect2(4, 100, 60.0 * p.res, 4), rcol)
	for i in range(1, 5):
		ci.draw_rect(Rect2(4 + i * 12, 100, 1, 4), INK)
	Px.text(ci, Vector2(68, 98), "R BURST" if full else "BURST", rcol if full else DIM)
	Spell.draw_hud(g, ci)
	ci.draw_rect(Rect2(3, 108, 22, 3), INK)
	ci.draw_rect(Rect2(4, 109, 20.0 * (1.0 - clampf(p.dash_cd / 0.75, 0.0, 1.0)), 1), Color("c6f4ff"))

	# active item and relics
	if p.active != null:
		var ad = D.ACTIVES[p.active.id]
		var ar = Rect2(3, 114, 20, 20)
		var has = p.active.n > 0
		panel(ci, ar, Color(0.07, 0.05, 0.12, 0.9), Color("5cd3f2") if has else DIM)
		var at: Texture2D = Art.T[ad.icon]
		big(ci, at, ar.position + Vector2(10 - at.get_width() / 2.0, 10 - at.get_height() / 2.0), 1.0, Color.WHITE if has else Color(0.4, 0.4, 0.48))
		Px.text(ci, Vector2(26, 116), "C", GOLD if has else DIM)
		for i in ad.max:
			ci.draw_rect(Rect2(34 + i * 6, 117, 4, 4), Color("5cd3f2") if i < p.active.n else Color("3a3346"))
		Px.text(ci, Vector2(26, 125), ad.name, Color("5cd3f2") if has else DIM)
	# the other hero in a co-op game
	for q in g.players:
		if q.idx == p.idx:
			continue
		panel(ci, Rect2(3, 140, 104, 42))
		Px.text(ci, Vector2(7, 143), "P%d %s" % [q.idx + 1, "DOWN" if q.down else str(q.name).substr(0, 9)], Color("ff6a6a") if q.down else Color("ffb84a"))
		bar(ci, Vector2(7, 153), 68, q.hp, q.mhp, Color("e0444c"), true)
		ci.draw_rect(Rect2(7, 162, 68.0 * clampf(float(q.ar) / maxf(q.mar, 1.0), 0.0, 1.0), 2), Color("a8a7b8"))
		ci.draw_rect(Rect2(7, 165, 68.0 * clampf(q.en / maxf(q.men, 1.0), 0.0, 1.0), 2), Color("4aa8f0"))
		var qw = q.weapons[q.wi]
		Px.text(ci, Vector2(7, 171), str(D.WEAPONS[qw.id].name).substr(0, 10), D.EL_COL[qw.el])
		for k in 2:
			var qcd: float = q.skill_cd if k == 0 else q.skill2_cd
			big(ci, Art.T["sk_" + q.skills[k]], Vector2(80 + k * 13, 150), 1.0, Color.WHITE if qcd <= 0.0 else Color(0.35, 0.35, 0.42))
		big(ci, Art.T["coin"], Vector2(80, 169), 1.0)
		Px.text(ci, Vector2(89, 171), str(q.gold), GOLD)
	for i in p.relics.size():
		big(ci, Art.T["relic_" + p.relics[i]], Vector2(4 + i * 11, 246), 1.0)

	if not g.in_lobby:
		ci.draw_set_transform(edge)
		draw_minimap(g, ci)

	# weapons
	ci.draw_set_transform(Vector2.ZERO if g.tin.on else edge)
	var wx = 182.0 if g.tin.on else 360.0
	var wr = Rect2(wx, 231, 117, 36)
	var w = p.weapons[p.wi]
	var def = D.WEAPONS[w.id]
	panel(ci, wr, Color(0.07, 0.05, 0.12, 0.9), ecol)
	var wt: Texture2D = Art.T[Art.wtex(w)]
	var sc = 2.0 if wt.get_height() <= 9 else 1.0
	big(ci, wt, wr.position + Vector2(20 - wt.get_width() * sc / 2.0, 16 - wt.get_height() * sc / 2.0), sc)
	var els = weapon_els(w)
	var ex = wr.position.x + 40.0
	if els.is_empty():
		Px.text(ci, Vector2(ex, wr.position.y + 5), "PRISM" if w.el == "prism" else "PLAIN", ecol)
	for k in els:
		big(ci, Art.T["ic_" + k], Vector2(ex, wr.position.y + 3), 1.0)
		Px.text(ci, Vector2(ex + 10, wr.position.y + 5), D.EL_NAME[k], D.EL_COL[k])
		ex += 14 + Px.width(D.EL_NAME[k])
	var lv = int(w.get("lv", 0))
	Px.text(ci, wr.position + Vector2(40, 15), ("+%d " % lv if lv > 0 else "") + def.name, GOLD if w.has("fname") else D.RAR_COL[def.rar])
	if def.cost > 0.0:
		Px.text(ci, wr.position + Vector2(40, 25), form_name(def) + "  COST " + str(def.cost).trim_suffix(".0"), Color("4aa8f0") if p.en >= def.cost else Color("ff6a6a"))
	else:
		Px.text(ci, wr.position + Vector2(40, 25), form_name(def), DIM)
	var o = p.weapons[1 - p.wi]
	if o != null:
		var odef = D.WEAPONS[o.id]
		var orr = Rect2(wx + 70, 211, 47, 18)
		panel(ci, orr, Color(0.07, 0.05, 0.12, 0.8), DIM)
		var ot: Texture2D = Art.T[Art.wtex(o)]
		big(ci, ot, orr.position + Vector2(28 - ot.get_width() / 2.0, 9 - ot.get_height() / 2.0), 1.0, Color(0.8, 0.8, 0.85))
		Px.text(ci, orr.position + Vector2(4, 6), "Q", GOLD)
	# which reaction the carried elements make together
	var all = els.duplicate()
	for k in weapon_els(o):
		if not all.has(k):
			all.append(k)
	# an element carried twice is attuned: its resonance needs one stack fewer
	var att = Reso.attuned(g)
	for i in att.size():
		big(ci, Art.T["ic_" + att[i]], Vector2(wx - 22, 204 - i * 11), 1.0)
		Px.text(ci, Vector2(wx - 12, 206 - i * 11), "X2 ATTUNED", D.EL_COL[att[i]])
	# the three elements you carry: 1 2 3 pick what the weapon paints; a bar marks the weapon's own
	if p.has("els"):
		var nat = weapon_els(w)
		for i in p.els.size():
			var slx = wx - 4 + i * 22
			var on = i == p.eli
			panel(ci, Rect2(slx, 211, 20, 18), Color(0.07, 0.05, 0.12, 0.9), D.EL_COL[p.els[i]] if on else DIM)
			big(ci, Art.T["ic_" + p.els[i]], Vector2(slx + 9, 216), 1.0, Color.WHITE if on else Color(1, 1, 1, 0.45))
			Px.text(ci, Vector2(slx + 2, 213), str(i + 1), GOLD if on else DIM)
			if p.has("sat"):
				# how much of this element is left: it drains while you paint with it, refills while it rests
				var spent: bool = p.spent[i]
				ci.draw_rect(Rect2(slx + 2, 227, 16, 2), INK)
				ci.draw_rect(Rect2(slx + 2, 227, 16.0 * clampf(p.sat[i], 0.0, 1.0), 2), (Color("ff6a6a") if int(t * 8.0) % 2 == 0 else Color("6b6779")) if spent else D.EL_COL[p.els[i]])

	ci.draw_set_transform(-edge)
	if g.in_lobby:
		Px.text(ci, Vector2(5, 259), "THE HEARTH - " + p.name, DIM)
		Px.text(ci, Vector2(5, 249), Hub.boon_text(), Color("a6e84e"))
	else:
		var bi = g.floor_i / 2
		Px.text(ci, Vector2(5, 259), "%s %d-%d" % [D.BIOMES[bi].name, bi + 1, g.floor_i % 2 + 1] + ("" if Wx.now(g) == "clear" else "  " + Wx.NAME[Wx.now(g)]), DIM)

	ci.draw_set_transform(Vector2.ZERO)
	if g.boss != null:
		var b = g.boss
		var bw = 220.0
		var bx = (VW - bw) / 2.0
		ci.draw_rect(Rect2(bx - 2, 9, bw + 4, 9), INK)
		ci.draw_rect(Rect2(bx, 11, bw, 5), Color("3a1020"))
		var k = clampf(b.hp / b.mhp, 0.0, 1.0)
		var bc = Color("e0444c") if k > 0.5 else Color("ff8a3a").lerp(Color("ffe45c"), 0.5 + 0.5 * sin(t * 10.0))
		ci.draw_rect(Rect2(bx, 11, bw * k, 5), bc)
		ci.draw_rect(Rect2(bx, 11, bw * k, 2), bc.lightened(0.4))
		ci.draw_rect(Rect2(bx + bw / 2.0, 11, 1, 5), INK)
		Px.ctext(ci, Vector2(VW / 2.0, 20), b.get("nem_name", b.d.name), Color("ff4a5e") if b.has("nem_name") else PALE)
		if b.el != "":
			Px.text(ci, Vector2(bx, 30), "RESISTS", DIM)
			big(ci, Art.T["ic_" + b.el], Vector2(bx + 44, 28), 1.0)
			Px.text(ci, Vector2(bx + bw - 40, 30), "WEAK", GOLD)
			big(ci, Art.T["ic_" + D.WEAK[b.el]], Vector2(bx + bw - 12, 28), 1.0)

	if g.banner.t > 0.0 and g.state == "play":
		var a = clampf(g.banner.t * 2.0, 0.0, 1.0)
		var by = 58.0 if g.boss == null else 78.0
		Px.ctext(ci, Vector2(VW / 2.0, by), g.banner.text, Color(GOLD.r, GOLD.g, GOLD.b, a), 2)
		if g.banner.sub != "":
			Px.ctext(ci, Vector2(VW / 2.0, by + 18.0), g.banner.sub, Color(PALE.r, PALE.g, PALE.b, a))
	if g.floor_i == 0 and not g.in_lobby and g.run_time < 14.0 and g.state == "play" and not g.tin.on:
		var a = clampf(14.0 - g.run_time, 0.0, 1.0)
		Px.ctext(ci, Vector2(190, 246), g.Pad.hint(g, "TWO WEAPONS: Q SWAPS - RMB, F SKILLS - SPACE DASH"), Color(PALE.r, PALE.g, PALE.b, a))

static func draw_minimap(g, ci: CanvasItem) -> void:
	var rooms = g.dg.rooms
	var maxx = 0
	var maxy = 0
	for r in rooms:
		maxx = max(maxx, r.cell.x)
		maxy = max(maxy, r.cell.y)
	var cw = 13.0
	var chh = 10.0
	var ox = VW - 6.0 - (maxx + 1) * cw
	var oy = 6.0
	var known = {}
	for r in rooms:
		if g.p.relics.has("compass"):
			known[r.id] = true
		if r.seen:
			known[r.id] = true
			for l in r.links:
				known[l] = true
	if known.is_empty():
		return
	ci.draw_rect(Rect2(ox - 3, oy - 3, (maxx + 1) * cw + 4, (maxy + 1) * chh + 4), Color(0.05, 0.03, 0.09, 0.55))
	for r in rooms:
		if not known.has(r.id):
			continue
		var c = Vector2(ox + r.cell.x * cw, oy + r.cell.y * chh)
		for l in r.links:
			if l > r.id and known.has(l):
				var o = rooms[l]
				var c2 = Vector2(ox + o.cell.x * cw, oy + o.cell.y * chh)
				ci.draw_line(c + Vector2(4.5, 3.5), c2 + Vector2(4.5, 3.5), DIM, 1.0)
	for r in rooms:
		if not known.has(r.id):
			continue
		var c = Vector2(ox + r.cell.x * cw, oy + r.cell.y * chh)
		var col = Color("57516a")
		match r.type:
			"boss": col = Color("e0444c")
			"shop": col = GOLD
			"chest": col = Color("4fae4c")
			"exit": col = Color("9352cb")
			"workshop": col = Color("5cd3f2")
			"shrine": col = GEM
			"puzzle": col = Color("e58cff")
			"secret": col = Color("f6f2e6")
		if r.type == "fight":
			col = Color("8479a0") if r.cleared else Color("c0704c")
		if not r.seen:
			col = col.darkened(0.45)
		ci.draw_rect(Rect2(c - Vector2(1, 1), Vector2(11, 9)), INK)
		ci.draw_rect(Rect2(c, Vector2(9, 7)), col)
		if r.elite and not r.cleared:
			ci.draw_rect(Rect2(c + Vector2(3, 2), Vector2(3, 3)), GOLD)
		if r == g.room:
			ci.draw_rect(Rect2(c - Vector2(1, 1), Vector2(11, 9)), Color.WHITE, false, 1.0)
			ci.draw_rect(Rect2(c + Vector2(3, 2), Vector2(3, 3)), Color.WHITE)

# ---- overlays --------------------------------------------------------------------

static func state_text(row: Dictionary) -> Array:
	if row.has("tag"):
		return [row.tag, GOLD if row.state != "locked" else DIM]
	match row.state:
		"on": return ["ACTIVE", Color("a6e84e")]
		"owned": return ["OWNED", PALE]
		"locked": return ["LOCKED", DIM]
	return [str(row.cost), GEM if Meta.S.gems >= row.cost else Color("ff6a6a")]

static func draw_menu(g, ci: CanvasItem) -> void:
	ci.draw_rect(g.full(), Color(0.02, 0.01, 0.05, 0.72))
	var kind: String = g.menu.kind
	panel(ci, Rect2(88, 28, 304, 218), Color(0.07, 0.05, 0.12, 0.97), GOLD)
	Px.text(ci, Vector2(98, 37), MENU_TITLE[kind] + " - " + g.p.name, GOLD)
	big(ci, Art.T["gem"], Vector2(350, 36), 1.0)
	Px.text(ci, Vector2(361, 37), str(Meta.S.gems), GEM)
	var rows: Array = g.menu.rows
	if kind == "tree":
		for b in 3:
			big(ci, Art.T["br_%d" % b], Vector2(102 + b * 98, 63), 1.0)
			Px.ctext(ci, Vector2(146 + b * 98, 66), Meta.BRANCH[b], PALE)
			for t in 2:
				ci.draw_rect(Rect2(142 + b * 98, 110 + t * 40, 1, 10), GOLD if rows[b * 3 + t].state == "owned" else DIM)
		for i in rows.size():
			var row = rows[i]
			var r = menu_rect(kind, i)
			var sel = i == g.menu.sel
			var own = row.state == "owned"
			panel(ci, r, Color(0.2, 0.14, 0.05, 0.97) if own else Color(0.09, 0.06, 0.15, 0.97), Color.WHITE if sel else (GOLD if own else (Color("9352cb") if row.state == "buy" else DIM)))
			Px.ctext(ci, r.position + Vector2(44, 5), row.name, GOLD if own else (PALE if row.state == "buy" else DIM))
			var stx = state_text(row)
			if row.state == "buy":
				big(ci, Art.T["gem"], r.position + Vector2(30, 16), 1.0)
				Px.text(ci, r.position + Vector2(41, 17), stx[0], stx[1])
			else:
				Px.ctext(ci, r.position + Vector2(44, 17), stx[0], stx[1])
		Px.ctext(ci, Vector2(240, 204), rows[g.menu.sel].desc, PALE)
	else:
		for i in rows.size():
			var row = rows[i]
			var r = menu_rect(kind, i)
			var sel = i == g.menu.sel
			panel(ci, r, Color(0.16, 0.1, 0.24, 0.97) if sel else Color(0.09, 0.06, 0.15, 0.9), Color.WHITE if sel else (Color("a6e84e") if row.state == "on" else DIM))
			var tx = 6.0
			if row.has("icon"):
				var tex: Texture2D = Art.T[row.icon]
				ci.draw_texture_rect_region(tex, Rect2(r.position + Vector2(4, 3), Vector2(14, 14)), Rect2(0, 0, 14, 14))
				tx = 22.0
			Px.text(ci, r.position + Vector2(tx, 2), row.name, PALE if row.state != "locked" else DIM)
			Px.text(ci, r.position + Vector2(tx, 11), row.desc, DIM, 1, false)
			var stx = state_text(row)
			if row.state == "buy":
				big(ci, Art.T["gem"], Vector2(r.end.x - 34, r.position.y + 5), 1.0)
				Px.text(ci, Vector2(r.end.x - 23, r.position.y + 6), stx[0], stx[1])
			else:
				Px.text(ci, Vector2(r.end.x - 6 - Px.width(stx[0]), r.position.y + 6), stx[0], stx[1])
	if g.menu.msg != "":
		Px.ctext(ci, Vector2(240, 224), g.menu.msg, Color("ff6a6a"))
	Px.ctext(ci, Vector2(240, 235), "TAP TO CHOOSE   TAP AGAIN TO CONFIRM   X CLOSES" if g.tin.on else g.Pad.hint(g, "W/S CHOOSE   ENTER OR CLICK CONFIRM   ESC CLOSE"), DIM)

static func draw_talk(g, ci: CanvasItem) -> void:
	var tk = g.talk
	if tk.i >= tk.lines.size():
		return
	var r = Rect2(20, 190, 440, 66)
	panel(ci, r, Color(0.07, 0.05, 0.12, 0.96), GOLD)
	panel(ci, Rect2(26, 196, 54, 54), Color(0.13, 0.09, 0.2, 1.0), DIM)
	var tex: Texture2D = Art.T[tk.spr]
	var sc = 3.0 if tex.get_height() <= 16 else 2.0
	big(ci, tex, Vector2(53 - tex.get_width() * sc / 2.0, 223 - tex.get_height() * sc / 2.0), sc)
	Px.text(ci, Vector2(88, 197), tk.name, GOLD)
	var shown: String = tk.lines[tk.i].substr(0, int(tk.t * 55.0))
	var ls = wrap_text(tk.lines[tk.i], 60)
	var left = shown.length()
	for k in ls.size():
		var part: String = ls[k].substr(0, max(0, left))
		Px.text(ci, Vector2(88, 211 + k * 11), part, PALE)
		left -= ls[k].length() + 1
	if left >= 0 and int(g.time * 3.0) % 2 == 0:
		Px.text(ci, Vector2(438, 244), g.Pad.key_name(g, "E") + " >", GOLD)
	Px.text(ci, Vector2(88, 244), "%d/%d" % [tk.i + 1, tk.lines.size()], DIM)

static func draw_pause(g, ci: CanvasItem) -> void:
	ci.draw_rect(g.full(), Color(0.02, 0.01, 0.05, 0.78))
	Px.ctext(ci, Vector2(240, 18), "PAUSED", GOLD, 3)
	Px.text(ci, Vector2(30, 52), "ELEMENT REACTIONS", PALE)
	for i in REACT_HELP.size():
		var rh = REACT_HELP[i]
		var y = 64 + i * 12
		big(ci, Art.T["ic_" + rh[0]], Vector2(30, y - 2), 1.0)
		Px.text(ci, Vector2(41, y), "+", DIM)
		big(ci, Art.T["ic_" + rh[1]], Vector2(48, y - 2), 1.0)
		Px.text(ci, Vector2(62, y), rh[2] if Book.known(rh[0] + "+" + rh[1]) else "??? NOT IN YOUR NOTEBOOK YET", D.REACT[rh[0] + "+" + rh[1]][1])
	Px.text(ci, Vector2(30, 138), "A THIRD ELEMENT ON A FIELD MAKES A STORM. THE FOURTH: CATACLYSM.", GOLD)
	var si = 0
	for miss in Combo.STORM:
		var sx2 = 30 + (si % 2) * 150
		var sy2 = 149 + (si / 2) * 10
		var ex2 = sx2
		for el in D.EL:
			if el != miss:
				big(ci, Art.T["ic_" + el], Vector2(ex2, sy2 - 2), 1.0)
				ex2 += 9
		Px.text(ci, Vector2(sx2 + 30, sy2), Book.shown("s_" + miss), Color(Combo.STORM[miss][1]))
		si += 1
	Px.text(ci, Vector2(320, 52), "BLESSINGS", PALE)
	var counts = {}
	for b in g.p.buffs:
		counts[b] = counts.get(b, 0) + 1
	var y2 = 64
	for b in D.BUFFS:
		if counts.has(b.id):
			Px.text(ci, Vector2(320, y2), b.name + (" X%d" % counts[b.id] if counts[b.id] > 1 else ""), Color("e58cff"))
			y2 += 10
	if counts.is_empty():
		Px.text(ci, Vector2(320, 64), "NONE YET", DIM)
		y2 += 10
	for s in D.SYNERGIES:
		if g.p.syn.has(s.id) and y2 < 160:
			Px.text(ci, Vector2(320, y2), "* " + s.name, GOLD)
			y2 += 10
	if not g.in_lobby:
		Px.text(ci, Vector2(30, 248), "SEED %d   HEAT %d%s" % [g.run_seed, g.run_heat, "   DAILY" if g.run_daily else ""], DIM)
	Px.ctext(ci, Vector2(240, 170), g.Pad.hint(g, "WASD MOVE   MOUSE AIM   LMB FIRE   SPACE DASH   Q SWAP   E USE"), PALE)
	Px.ctext(ci, Vector2(240, 182), g.Pad.hint(g, "RMB SKILL ONE   F SKILL TWO   R ELEMENTAL BURST WHEN CHARGED"), PALE)
	Px.ctext(ci, Vector2(240, 200), "THE FOES LEARN. CUNNING %d%%. THEY LEAD THEIR SHOTS %d%% OF THE TIME." % [int(Meta.cunning() * 100.0), int(Meta.lead_share() * 100.0)], Color("ff8a6a"))
	if g.tin.on:
		panel(ci, Rect2(120, 226, 110, 20), Color(0.1, 0.2, 0.1, 0.95), Color("a6e84e"))
		Px.ctext(ci, Vector2(175, 233), "RESUME", Color("a6e84e"))
		panel(ci, Rect2(250, 226, 110, 20), Color(0.2, 0.08, 0.08, 0.95), Color("ff6a6a"))
		Px.ctext(ci, Vector2(305, 233), "QUIT TO TITLE" if g.in_lobby else "ABANDON RUN", Color("ff6a6a"))
		panel(ci, Rect2(185, 204, 110, 18), Color(0.1, 0.1, 0.2, 0.95), PALE)
		Px.ctext(ci, Vector2(240, 210), "SETTINGS", PALE)
	else:
		Px.ctext(ci, Vector2(240, 236), g.Pad.hint(g, "ESC RESUME    O SETTINGS    Q " + ("QUIT TO TITLE" if g.in_lobby else "ABANDON RUN")), GOLD)

static func draw_buff(g, ci: CanvasItem) -> void:
	ci.draw_rect(g.full(), Color(0.02, 0.01, 0.05, 0.8))
	Px.ctext(ci, Vector2(240, 36), ("P%d: CHOOSE A BLESSING" % (g.buff_turn + 1)) if g.local_coop() else "CHOOSE A BLESSING", GOLD if g.buff_turn == 0 else Color("ffb84a"), 2)
	Px.ctext(ci, Vector2(240, 58), "THE CORE REWARDS THOSE WHO DESCEND", DIM)
	var m = g.mouse()
	for i in g.buff_choices.size():
		var b = g.buff_choices[i]
		var r = buff_rect(i)
		var hov = r.has_point(m) or (g.pad_used and i == g.buff_sel)
		panel(ci, r, Color(0.16, 0.1, 0.24, 0.97) if hov else Color(0.09, 0.06, 0.15, 0.95), GOLD if hov else Color("9352cb"))
		var bic = "bl_" + str(b.get("id", ""))
		if Art.T.has(bic):
			# its own emblem on a small plate that lights up under the pointer
			ci.draw_rect(Rect2(r.position + Vector2(58 - 16, 8), Vector2(32, 32)), Color(0.04, 0.03, 0.08, 0.9))
			ci.draw_rect(Rect2(r.position + Vector2(58 - 16, 8), Vector2(32, 32)), GOLD if hov else Color("55307f"), false, 1.0)
			big(ci, Art.T[bic], r.position + Vector2(58 - 13.5, 10.5 + (sin(g.time * 4.0 + i) if hov else 0.0)), 3.0)
		else:
			big(ci, Art.T["tome"], r.position + Vector2(58 - 15, 10), 3.0)
		Px.ctext(ci, r.position + Vector2(58, 44), b.name, GOLD)
		var lines = wrap_text(b.desc, 17)
		for k in lines.size():
			Px.ctext(ci, r.position + Vector2(58, 60 + k * 10), lines[k], PALE)
		Px.ctext(ci, r.position + Vector2(58, 99), "PRESS %d" % (i + 1), DIM)
	Wish.draw_buff_line(g, ci, Hud_self())

static func draw_end(g, ci: CanvasItem, win: bool) -> void:
	var a = clampf(g.state_t, 0.0, 1.0)
	ci.draw_rect(g.full(), Color(0.02, 0.01, 0.05, 0.8 * a))
	if win:
		Px.ctext(ci, Vector2(240, 44), "THE CORE IS YOURS", GOLD, 3)
		Px.ctext(ci, Vector2(240, 76), "THE DUNGEON FALLS SILENT. FOR NOW.", PALE)
	else:
		Px.ctext(ci, Vector2(240, 44), "YOU HAVE FALLEN", Color("e0444c"), 3)
		Px.ctext(ci, Vector2(240, 76), "THE DUNGEON CLAIMS ANOTHER SOUL.", PALE)
	var bi = g.floor_i / 2
	var rows = [
		["HERO", g.p.name],
		["REACHED", "%s %d-%d" % [D.BIOMES[bi].name, bi + 1, g.floor_i % 2 + 1]],
		["FOES SLAIN", str(g.kills)],
		["BOSSES", str(g.boss_kills)],
		["TIME", "%d:%02d" % [int(g.run_time) / 60, int(g.run_time) % 60]],
		["GEMS EARNED", "+%d" % g.gems_won],
		["NEMESIS", Nemesis.title(Nemesis.current()) if not Nemesis.current().is_empty() else "NONE"],
		["SCORE", "%d   SEED %d%s" % [g.run_score, g.run_seed, "  DAILY" if g.run_daily else ("  HEAT %d" % g.run_heat)]],
	]
	for i in rows.size():
		Px.text(ci, Vector2(130, 96 + i * 13), rows[i][0], DIM)
		Px.text(ci, Vector2(230, 96 + i * 13), rows[i][1], GEM if i == 5 else PALE)
	if g.state_t > 1.0:
		Px.ctext(ci, Vector2(240, 214), g.Pad.hint(g, "PRESS ENTER TO RETURN TO THE HEARTH"), GOLD.lerp(Color.WHITE, 0.5 + 0.5 * sin(g.time * 4.0)))
