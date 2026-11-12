extends RefCounted
# Panels drawn over the world: HUD, talk box, bag and shop. `g` is the game node.

const Art = preload("res://src/art.gd")
const Txt = preload("res://src/font.gd")
const D = preload("res://src/data.gd")
const Sk = preload("res://src/skills.gd")

const INK = Color("1a1420")
const PANEL = Color("2a2030")
const TRIM = Color("7a4b2a")
const IVORY = Color("f4ebd0")
const DIM = Color("8c8577")
const GOLD = Color("ffd24a")
const CELL = 26
const COLS = 6

static func frame(g, r: Rect2) -> void:
	g.draw_rect(Rect2(r.position - Vector2(2, 2), r.size + Vector2(4, 4)), INK)
	g.draw_rect(Rect2(r.position - Vector2(1, 1), r.size + Vector2(2, 2)), TRIM)
	g.draw_rect(r, PANEL)

static func wrap_text(s: String, n: int) -> Array:
	var out = []
	var line = ""
	for w in s.split(" "):
		if line.length() + w.length() + 1 > n and line != "":
			out.append(line)
			line = w
		else:
			line = w if line == "" else line + " " + w
	if line != "":
		out.append(line)
	return out

# ---------------------------------------------------------------- HUD

static func hud(g, view: Vector2) -> void:
	var p = g.p
	var x = 8.0
	var y = view.y - 34.0
	g.draw_rect(Rect2(x - 2, y - 2, 124, 13), INK)
	g.draw_rect(Rect2(x - 1, y - 1, 122, 11), TRIM)
	g.draw_rect(Rect2(x, y, 120, 9), PANEL)
	var hk = clampf(p.hp / g.stats.mhp, 0.0, 1.0)
	g.draw_rect(Rect2(x, y, 120 * hk, 9), Color("b3263a"))
	g.draw_rect(Rect2(x, y, 120 * hk, 2), Color("d9566a"))
	if p.get("shield", 0.0) > 0.0:
		# the shield: a pale band over the bottom of the life bar, its number on the right
		var sk = clampf(p.shield / g.shield_cap(), 0.0, 1.0)
		g.draw_rect(Rect2(x, y + 6, 120 * sk, 3), Color("e0d6a0") if p.bronze <= 0.0 else Color("e0b04a"))
		Txt.text(g, Vector2(x + 117 - Txt.width(str(int(ceil(p.shield)))), y + 1), str(int(ceil(p.shield))), Color("e0d6a0"))
	Txt.text(g, Vector2(x + 3, y + 1), "%d/%d" % [int(ceil(p.hp)), int(g.stats.mhp)], IVORY)
	g.draw_rect(Rect2(x - 2, y + 12, 124, 8), INK)
	g.draw_rect(Rect2(x, y + 14, 120, 4), PANEL)
	g.draw_rect(Rect2(x, y + 14, 120 * p.rage / 100.0, 4), Color("d9772b"))
	# experience
	g.draw_rect(Rect2(x - 2, y + 21, 124, 6), INK)
	g.draw_rect(Rect2(x, y + 23, 120, 2), PANEL)
	g.draw_rect(Rect2(x, y + 23, 120.0 * g.xp / D.xp_need(g.lvl), 2), g.VONG)
	Txt.text(g, Vector2(x + 126, y + 20), "CẤP %d" % g.lvl, IVORY)
	for i in g.max_dodges():
		var dp = Vector2(x + 128 + i * 10, y + 1)
		g.draw_rect(Rect2(dp - Vector2(1, 1), Vector2(8, 8)), INK)
		g.draw_rect(Rect2(dp, Vector2(6, 6)), g.VONG if i < p.dodges else PANEL)
	if g.uses_cp():
		# danger points, above the life bar
		for i in g.cp_cap():
			var cpp = Vector2(x + i * 9, y - 10)
			g.draw_rect(Rect2(cpp - Vector2(1, 1), Vector2(8, 7)), INK)
			g.draw_rect(Rect2(cpp, Vector2(6, 5)), Color("d94a5a") if i < p.cp else PANEL)
	if g.uses_souls():
		# souls, above the life bar (above the danger points when both show)
		var sy = y - (19 if g.uses_cp() else 10)
		for i in g.soul_cap():
			g.draw_rect(Rect2(x + i * 9 - 1, sy - 1, 8, 7), INK)
			g.draw_rect(Rect2(x + i * 9, sy, 6, 5), g.VONG if i < p.souls else PANEL)
	if g.uses_heat():
		# heat, above the life bar on the left (above dots when there are any); a tick at 70, red while overheated
		var hy = y - 10 - (9 if g.uses_cp() else 0) - (9 if g.uses_souls() else 0)
		var hk2 = clampf(p.heat / 100.0, 0.0, 1.5)
		g.draw_rect(Rect2(x - 1, hy - 1, 62, 6), INK)
		g.draw_rect(Rect2(x, hy, 60, 4), PANEL)
		var hc = Color("d94a3a") if p.over > 0.0 else (Color("ff8a3a") if g.hot() else Color("c98a4a"))
		g.draw_rect(Rect2(x, hy, 60 * minf(hk2, 1.0), 4), hc)
		if hk2 > 1.0:
			g.draw_rect(Rect2(x, hy, 60 * (hk2 - 1.0) * 2.0, 1), Color("ffe9a3"))
		g.draw_rect(Rect2(x + 60.0 * g.hot_line() / 100.0, hy - 1, 1, 6), IVORY)
		Txt.text(g, Vector2(x + 64, hy - 2), "QUÁ NHIỆT" if p.over > 0.0 else str(int(p.heat)), hc)
	if g.uses_devo():
		# devotion: a pale gold bar to the right of the life bar, bright while zeal or a blessing is on
		var dv = Vector2(x + 127, y - 18 if g.uses_focus() else y - 10)
		g.draw_rect(Rect2(dv - Vector2(1, 1), Vector2(42, 6)), INK)
		g.draw_rect(Rect2(dv, Vector2(40, 4)), PANEL)
		g.draw_rect(Rect2(dv, Vector2(40 * p.devo / 100.0, 4)), Color("fff0b0") if (p.zeal_t > 0.0 or p.devo >= 100.0) else Color("c9b06a"))
		if p.bless_t > 0.0:
			g.draw_rect(Rect2(dv + Vector2(44, 0), Vector2(4, 4)), Color("fff0b0"))
		if p.vow_t > 0.0 or p.vigil_t > 0.0:
			g.draw_rect(Rect2(dv + Vector2(50, 0), Vector2(4, 4)), Color("ffd84a"))
	if g.uses_focus():
		# focus: fills over two seconds away from foes, gold when the next blow is stronger
		var fp = Vector2(x + 127, y - 10)
		g.draw_rect(Rect2(fp - Vector2(1, 1), Vector2(20, 7)), INK)
		g.draw_rect(Rect2(fp, Vector2(18, 5)), PANEL)
		var fk = 1.0 if p.focused else clampf(p.focus_t / g.focus_need(), 0.0, 1.0)
		g.draw_rect(Rect2(fp, Vector2(18 * fk, 5)), Color("ffd84a") if p.focused else Color("8a7a4a"))
		# the hounds: a small life bar each, empty while one is down
		for i in g.pets.size():
			var pt = g.pets[i]
			var hp2 = Vector2(x + 150 + i * 14, y - 9)
			g.draw_rect(Rect2(hp2 - Vector2(1, 1), Vector2(14, 5)), INK)
			g.draw_rect(Rect2(hp2, Vector2(12 * (pt.hp / pt.mhp if pt.down <= 0.0 else 0.0), 3)), g.VONG)
	if p.dodges < g.max_dodges():
		g.draw_rect(Rect2(x + 127, y + 10, 18 * (1.0 - clampf(p.dodge_cd / g.DODGE_RECHARGE, 0.0, 1.0)), 2), g.VONG)
	g.draw_texture(Art.T["potion"], Vector2(x + 154, y), Color.WHITE if p.pot_cd <= 0.0 else Color(1, 1, 1, 0.4))
	Txt.text(g, Vector2(x + 164, y + 2), "%d  F" % g.potions, IVORY if g.potions > 0 else DIM)
	# gold and quests, top right
	g.draw_texture(Art.T["coin"], Vector2(view.x - 56, 7))
	if g.loot_filter > 0:
		Txt.text(g, Vector2(view.x - 62 - Txt.width("LỌC: " + D.FILTER_NAME[g.loot_filter]), 8), "LỌC: " + D.FILTER_NAME[g.loot_filter], DIM)
	Txt.text(g, Vector2(view.x - 46, 8), str(g.gold), GOLD)
	var lines = []
	var shown = 0
	for id in D.ORDER:
		var st = g.qs.get(id, "")
		if (st != "active" and st != "ready") or shown >= 3:
			continue
		shown += 1
		var Q = D.QUESTS[id]
		lines.append([Q.name, Color("ffe9a3")])
		if st == "ready":
			lines.append(["QUAY VỀ GẶP " + D.NPCS[g.q_ender(id)].name, IVORY])
			continue
		var c = g.qc.get(id, {})
		var need = Q.need
		for k in need.get("kill", {}):
			lines.append(["%s %d/%d" % [D.FOES[k].name, c.get(k, 0), need.kill[k]], IVORY if c.get(k, 0) < need.kill[k] else DIM])
		if need.has("loot"):
			lines.append(["%s %d/%d" % [need.loot[0], c.get("loot", 0), need.loot[1]], IVORY])
		if need.has("see"):
			var seen = 0
			for s in need.see:
				if g.flags.has("seen_" + s):
					seen += 1
			if need.see.size() > 1:
				lines.append(["%s %d/%d" % [Q.goal, seen, need.see.size()], IVORY])
			else:
				lines.append([Q.goal, IVORY if seen == 0 else DIM])
		if need.has("talk"):
			lines.append([Q.goal, IVORY])
	if shown == 0:
		for id in D.ORDER:
			if g.q_open(id) and not D.QUESTS[id].get("auto", false):
				lines.append(["GẶP " + D.NPCS[D.QUESTS[id].giver].name, Color("ffe9a3")])
				break
	for i in lines.size():
		Txt.text(g, Vector2(view.x - 8 - Txt.width(lines[i][0]), 22 + i * 10), lines[i][0], lines[i][1])
	# boss bar
	for f in g.foes:
		if D.FOES[f.kind].get("big", false) and f.state != "idle" and f.state != "dead":
			var bw = 260.0
			var bx = (view.x - bw) / 2.0
			g.draw_rect(Rect2(bx - 2, 20, bw + 4, 9), INK)
			g.draw_rect(Rect2(bx, 22, bw, 5), PANEL)
			g.draw_rect(Rect2(bx, 22, bw * clampf(f.hp / f.mhp, 0.0, 1.0), 5), Color("6f8fc9"))
			g.draw_rect(Rect2(bx + bw * 0.5, 21, 1, 7), IVORY)
			Txt.ctext(g, Vector2(view.x / 2.0, 9), D.FOES[f.kind].name, IVORY)
	if g.banner_t > 0.0:
		Txt.ctext(g, Vector2(view.x / 2.0, 60), g.zone.name, Color(IVORY.r, IVORY.g, IVORY.b, clampf(g.banner_t, 0.0, 1.0)), 2)
	for i in g.toasts.size():
		var q = g.toasts[i]
		Txt.ctext(g, Vector2(view.x / 2.0, 92 + i * 11), q.txt, Color(q.col.r, q.col.g, q.col.b, clampf(q.t, 0.0, 1.0)))
	if g.lvl == 1 and g.qs.size() <= 1 and g.mode == "play":
		Txt.ctext(g, Vector2(view.x / 2.0, view.y - 50), "WASD ĐI   CHUỘT TRÁI CHÉM   SPACE NÉ   E NÓI   I TÚI   T KỸ NĂNG   F BÌNH MÁU   ESC TẠM DỪNG", Color(IVORY.r, IVORY.g, IVORY.b, 0.8))
	if g.mode != "tree":
		skill_bar(g, view)
	if g.p.state == "dead":
		Txt.ctext(g, Vector2(view.x / 2.0, 150), "BẠN GỤC NGÃ", Color("ff9a8a"), 3)

# ---------------------------------------------------------------- talk

static func talk_rect(view: Vector2) -> Rect2:
	return Rect2(view.x / 2.0 - 220, view.y - 112, 440, 66)

static func opt_rect(view: Vector2, i: int) -> Rect2:
	var r = talk_rect(view)
	return Rect2(r.position.x + 60 + i * 190, r.position.y - 20, 180, 15)

static func choosing(g) -> bool:
	return not g.talk.opts.is_empty() and g.talk.i == g.talk.lines.size() - 1

static func talk_update(g) -> void:
	if choosing(g):
		var view = g.get_viewport_rect().size
		for i in g.talk.opts.size():
			if g.pressed("opt%d" % (i + 1)) or (g.pressed("atk") and opt_rect(view, i).has_point(g.ui_mouse())):
				g.choose(i)
				return
	elif g.pressed("use") or g.pressed("atk"):
		g.talk_next()

static func talk_box(g, view: Vector2) -> void:
	var r = talk_rect(view)
	frame(g, r)
	var tx = r.position.x + 12
	if g.talk.tex != "":
		var tex: Texture2D = Art.T[g.talk.tex]
		if g.talk.has("ghost"):
			g.draw_texture_rect(Art.W[g.talk.tex], Rect2(r.position.x + 8, r.position.y + 58 - tex.get_height(), tex.get_width(), tex.get_height()), false, Color(0.62, 0.89, 0.88, 0.8))
		else:
			g.draw_texture_rect(tex, Rect2(r.position.x + 8, r.position.y + 58 - tex.get_height(), tex.get_width(), tex.get_height()), false)
		tx = r.position.x + 52
	var ty = r.position.y + 7
	if g.talk.name != "":
		Txt.text(g, Vector2(tx, ty), g.talk.name, Color("ffe9a3"))
		ty += 12
	var lines = wrap_text(g.talk.lines[g.talk.i], int((r.end.x - tx - 10) / 6))
	for i in lines.size():
		Txt.text(g, Vector2(tx, ty + i * 10), lines[i], IVORY)
	if choosing(g):
		for i in g.talk.opts.size():
			var o = opt_rect(view, i)
			frame(g, o)
			if o.has_point(g.ui_mouse()):
				g.draw_rect(o, Color(1, 1, 1, 0.12))
			Txt.text(g, o.position + Vector2(5, 4), "%d  %s" % [i + 1, g.talk.opts[i]], Color("ffe9a3"))
	elif int(g.t * 2.0) % 2 == 0:
		Txt.text(g, Vector2(r.end.x - 14, r.end.y - 11), "E", IVORY)

# ---------------------------------------------------------------- bag and shop

static func panel_rect(view: Vector2) -> Rect2:
	return Rect2(view.x / 2.0 - 190, view.y / 2.0 - 132, 380, 256)

static func bag_cell(view: Vector2, i: int) -> Rect2:
	var r = panel_rect(view)
	return Rect2(r.position.x + 132 + (i % COLS) * (CELL + 2), r.position.y + 26 + (i / COLS) * (CELL + 2), CELL, CELL)

static func eq_cell(view: Vector2, i: int) -> Rect2:
	var r = panel_rect(view)
	return Rect2(r.position.x + 12, r.position.y + 26 + i * (CELL + 6), CELL, CELL)

static func inv_update(g) -> void:
	var view = g.get_viewport_rect().size
	var m = g.ui_mouse()
	if g.shop and g.pressed("reset"):
		g.sell_junk()
	if g.shop and g.pressed("buy"):
		g.buy_potion()
	if not g.pressed("atk"):
		return
	for i in g.inv.size():
		if bag_cell(view, i).has_point(m):
			if g.shop:
				g.sell(i)
			else:
				g.equip(i)
			return
	if not g.shop:
		for i in 3:
			if eq_cell(view, i).has_point(m):
				g.unequip(D.SLOTS[i])
				return

static func draw_item(g, r: Rect2, it) -> void:
	g.draw_rect(r, INK)
	g.draw_rect(Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 2)), Color("3a3046"))
	if it == null:
		return
	var col: Color = D.RAR_COL[it.rar]
	g.draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), col)
	g.draw_rect(Rect2(r.position + Vector2(1, r.size.y - 2), Vector2(r.size.x - 2, 1)), col)
	var key = D.icon(it)
	if Art.T.has(key):
		var pic: Texture2D = Art.T[key]
		g.draw_texture(pic, (r.position + (r.size - Vector2(pic.get_size())) / 2.0).floor())
	else:
		var tex: Texture2D = Art.T["ic_" + it.slot]
		g.draw_texture(tex, (r.position + (r.size - Vector2(tex.get_size())) / 2.0).floor(), col.lerp(Color.WHITE, 0.5))

static func inv_draw(g, view: Vector2) -> void:
	g.draw_rect(Rect2(Vector2.ZERO, view), Color(0.04, 0.03, 0.07, 0.55))
	var r = panel_rect(view)
	frame(g, r)
	Txt.text(g, r.position + Vector2(12, 8), "CỬA HÀNG THẦY KHÂM" if g.shop else "TÚI ĐỒ", Color("ffe9a3"))
	g.draw_texture(Art.T["coin"], Vector2(r.end.x - 60, r.position.y + 7))
	Txt.text(g, Vector2(r.end.x - 50, r.position.y + 8), str(g.gold), GOLD)
	var m = g.ui_mouse()
	var hover = null
	var hover_eq = false
	for i in 3:
		var c = eq_cell(view, i)
		var it = g.eq[D.SLOTS[i]]
		draw_item(g, c, it)
		Txt.text(g, c.position + Vector2(CELL + 5, 3), D.SLOT_NAME[D.SLOTS[i]], DIM)
		if it != null:
			Txt.text(g, c.position + Vector2(CELL + 5, 13), it.name.substr(0, 14), D.RAR_COL[it.rar])
			if c.has_point(m):
				hover = it
				hover_eq = true
	for i in g.BAG:
		var c = bag_cell(view, i)
		var it = g.inv[i] if i < g.inv.size() else null
		draw_item(g, c, it)
		if it != null and c.has_point(m):
			hover = it
			g.draw_rect(c, Color(1, 1, 1, 0.18))
	# hero numbers
	var sy = r.position.y + 126
	var rows = [["CẤP", g.lvl], ["TẤN CÔNG", g.stats.atk], ["GIÁP", g.stats.def], ["MÁU", g.stats.mhp]]
	for k in ["rage", "spd", "leech"]:
		if g.stats[k] > 0:
			rows.append([D.STAT_NAME[k], g.stats[k]])
	for i in rows.size():
		Txt.text(g, Vector2(r.position.x + 12, sy + i * 10), "%s %d" % [rows[i][0], int(rows[i][1])], IVORY)
	# what the pointer is on, compared with what is worn
	var ty = r.position.y + 142
	var tx = r.position.x + 132
	if hover != null:
		Txt.text(g, Vector2(tx, ty), hover.name, D.RAR_COL[hover.rar])
		Txt.text(g, Vector2(tx, ty + 10), "%s %s" % [D.SLOT_NAME[hover.slot], D.RAR_NAME[hover.rar]], DIM)
		var worn = g.eq[hover.slot]
		var keys = hover.stats.keys()
		if worn != null and not hover_eq:
			for k in worn.stats:
				if not keys.has(k):
					keys.append(k)
		var n = 0
		for k in keys:
			var v = hover.stats.get(k, 0)
			var line = "%s %d" % [D.STAT_NAME[k], v]
			var col = IVORY
			if not hover_eq:
				var diff = v - (worn.stats.get(k, 0) if worn != null else 0)
				if diff != 0:
					line += "  (%s%d)" % ["+" if diff > 0 else "", diff]
					col = Color("8fe08a") if diff > 0 else Color("ff9a8a")
			Txt.text(g, Vector2(tx, ty + 22 + n * 10), line, col)
			n += 1
		if hover.uniq != "":
			Txt.text(g, Vector2(tx, ty + 24 + n * 10), D.UNIQ_TEXT[hover.uniq], D.RAR_COL[3])
		Txt.text(g, Vector2(r.end.x - 12 - Txt.width("BÁN ĐƯỢC 000"), ty), "BÁN ĐƯỢC %d" % D.value(hover), GOLD)
	var hint = "BẤM VÀO MÓN ĐỒ ĐỂ MẶC.  I ĐỂ ĐÓNG."
	if g.shop:
		hint = "BẤM ĐỂ BÁN.  X BÁN HẾT ĐỒ THƯỜNG.  B MUA BÌNH MÁU (%d VÀNG).  I ĐỂ ĐÓNG." % D.POTION_COST
	Txt.ctext(g, Vector2(view.x / 2.0, r.end.y - 12), hint, DIM)

# ---------------------------------------------------------------- skill bar and skill tree

static func slot_rect(view: Vector2, i: int) -> Rect2:
	# five skills, a gap, then the ultimate
	var x0 = view.x / 2.0 - 78.0
	return Rect2(x0 + i * 25 + (8 if i == 5 else (16 if i == 6 else 0)), view.y - 27, 22, 22)

static func skill_bar(g, view: Vector2) -> void:
	if g.tree.is_empty():
		if g.points_left() > 0 and g.mode == "play" and int(g.t * 2.0) % 2 == 0:
			Txt.ctext(g, Vector2(view.x / 2.0, view.y - 20), "T: CÂY KỸ NĂNG  (%d ĐIỂM)" % g.points_left(), Color("ffe9a3"))
		return
	for i in (7 if g.tree.has("prototype") else 6):
		var id = g.bar[i] if i < 5 else (g.cur_ult() if i == 5 else g.proto)
		var r = slot_rect(view, i)
		g.draw_rect(Rect2(r.position - Vector2(1, 1), r.size + Vector2(2, 2)), INK)
		g.draw_rect(r, Color("3a3046"))
		Txt.text(g, r.position + Vector2(1, -9), "R" if i == 5 else str(mini(i + 1, 6)), DIM)
		if id == "":
			continue
		var N = Sk.NODES[id]
		var col: Color = Sk.col(id)
		var ok = g.can_cast(id)
		g.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), col)
		if Art.T.has("sk_" + id):
			g.draw_texture(Art.T["sk_" + id], r.position + Vector2(1, 1), Color.WHITE if ok else Color(0.45, 0.45, 0.5))
		else:
			Txt.ctext(g, r.position + Vector2(11, 8), N.abbr, col if ok else DIM)
		if g.p.cds.has(id):
			var cd = g.skill_cd(id)
			var k = clampf(g.p.cds[id] / cd, 0.0, 1.0)
			g.draw_rect(Rect2(r.position.x, r.position.y + r.size.y * (1.0 - k), r.size.x, r.size.y * k), Color(0.04, 0.03, 0.07, 0.7))
			Txt.ctext(g, r.position + Vector2(11, 8), str(int(ceil(g.p.cds[id]))), IVORY)
	if g.points_left() > 0 and g.mode == "play":
		Txt.text(g, Vector2(slot_rect(view, 6 if g.tree.has("prototype") else 5).end.x + 6, view.y - 19), "T +%d" % g.points_left(), Color("ffe9a3"))

static func tree_panel(view: Vector2) -> Rect2:
	return Rect2(view.x / 2.0 - 300, 14, 600, 302)

static func tab_rect(view: Vector2, i: int) -> Rect2:
	var r = tree_panel(view)
	return Rect2(r.position.x + 12 + i * 116, r.position.y + 6, 112, 15)

static func tree_cell(view: Vector2, id: String) -> Rect2:
	var r = tree_panel(view)
	var N = Sk.NODES[id]
	if N.b < 0:
		return Rect2(r.position.x + 260, r.position.y + 180, 80, 26)
	return Rect2(r.position.x + 12 + N.b * 196 + N.pos[0] * 62, r.position.y + 48 + N.pos[1] * 42, 58, 30)

static func tree_hover(g, view: Vector2) -> String:
	var m = g.ui_mouse()
	for id in Sk.NODES:
		if Sk.NODES[id].get("m", 0) == g.tab and tree_cell(view, id).has_point(m):
			return id
	return ""

static func tree_update(g) -> void:
	var view = g.get_viewport_rect().size
	var id = tree_hover(g, view)
	if g.pressed("reset"):
		g.reset_tree()
	elif g.pressed("atk"):
		for i in 4:
			if tab_rect(view, i).has_point(g.ui_mouse()):
				g.tab = g.tabs()[i]
				return
		if id != "":
			g.learn(id)
	elif id != "" and g.pressed("ult") and Sk.NODES[id].kind == "u" and g.tree.has(id):
		g.ult = id
	elif id != "":
		for i in Sk.BAR:
			if g.pressed("s%d" % (i + 1)):
				g.assign(id, i)
		if g.pressed("s6") and g.tree.has("prototype") and g.tree.has(id) and Sk.NODES[id].kind == "a" and Sk.NODES[id].get("m", 0) == 28:
			g.proto = id

static func tree_draw(g, view: Vector2) -> void:
	g.draw_rect(Rect2(Vector2.ZERO, view), Color(0.04, 0.03, 0.07, 0.6))
	var r = tree_panel(view)
	frame(g, r)
	var second = g.has_second()
	var tabs = g.tabs()
	if not tabs.has(g.tab):
		g.tab = g.main_m
	for i in 4:
		var tr = tab_rect(view, i)
		var on = tabs[i] == g.tab
		g.draw_rect(tr, Color("ffe9a3") if on else Color("5a4e66"))
		g.draw_rect(Rect2(tr.position + Vector2(1, 1), tr.size - Vector2(2, 2)), Color("3a3046") if on else Color("221b29"))
		var label = Sk.MASTERY[tabs[i]] if (tabs[i] == g.main_m or second) else "???"
		Txt.ctext(g, tr.position + Vector2(tr.size.x / 2.0, 4), "%s  %d" % [label, Sk.mastery_points(g.tree, tabs[i])], Color("ffe9a3") if on else DIM)
	var left = "CÒN %d ĐIỂM" % g.points_left()
	Txt.text(g, Vector2(r.end.x - 12 - Txt.width(left), r.position.y + 10), left, Color("ffe9a3") if g.points_left() > 0 else DIM)
	for b in 3:
		var bx = r.position.x + 12 + b * 196
		var bc: Color = Sk.COLS[g.tab][b]
		Txt.text(g, Vector2(bx, r.position.y + 31), "%s  %d" % [Sk.BRANCHES[g.tab][b], Sk.branch_points(g.tree, g.tab, b)], bc)
		g.draw_rect(Rect2(bx, r.position.y + 41, 182, 1), bc.darkened(0.4))
		if b > 0:
			g.draw_rect(Rect2(bx - 7, r.position.y + 29, 1, 146), Color("3a3046"))
	var hover = tree_hover(g, view)
	for id in Sk.NODES:
		var N = Sk.NODES[id]
		if N.get("m", 0) != g.tab:
			continue
		var c = tree_cell(view, id)
		var rank = g.tree.get(id, 0)
		var col: Color = Sk.col(id)
		var why = Sk.blocked(g.tree, id, g.lvl, second, g.main_m, g.sec())
		var open = why == "" or why == Sk.NO_POINTS or rank > 0
		g.draw_rect(c, Color("ffd24a") if N.kind == "k" else (IVORY if (N.kind == "a" or N.kind == "u") else Color("5a4e66")))
		g.draw_rect(Rect2(c.position + Vector2(1, 1), c.size - Vector2(2, 2)), col.darkened(0.55) if rank > 0 else (Color("3a3046") if open else Color("221b29")))
		if Art.T.has("sk_" + id):
			g.draw_texture(Art.T["sk_" + id], c.position + Vector2(5, 5), Color.WHITE if open else Color(0.4, 0.4, 0.46))
		else:
			Txt.text(g, c.position + Vector2(5, 8), N.abbr, col if open else Color("5a4e66"), 2)
		var mr = Sk.max_rank(g.tree, id, g.has_second(), g.main_m, g.sec())
		Txt.text(g, Vector2(c.end.x - 5 - Txt.width("%d/%d" % [rank, mr]), c.end.y - 11), "%d/%d" % [rank, mr], IVORY if rank > 0 else DIM)
		if id == hover:
			g.draw_rect(c, Color(1, 1, 1, 0.14))
	var ty = r.position.y + 214
	g.draw_rect(Rect2(r.position.x + 12, ty - 6, r.size.x - 24, 1), Color("3a3046"))
	if hover != "":
		var N = Sk.NODES[hover]
		var kind = {"a": "KỸ NĂNG CHỦ ĐỘNG", "p": "NỘI TẠI", "k": "THEN CHỐT", "u": "TUYỆT KỸ"}[N.kind]
		if Sk.LINKS.has(N.get("m", 0)) and N.kind == "p":
			kind = "GIAO THOA"
		if Sk.SOLO.has(N.get("m", 0)) and N.kind == "p":
			kind = "ĐỘC TẤU"
		Txt.text(g, Vector2(r.position.x + 12, ty), N.n, Color("ffe9a3"))
		var meta = kind
		if N.has("cd") and N.cd > 0.0:
			meta += "   HỒI %.1f GIÂY" % g.skill_cd(hover)
		if N.has("heat"):
			meta += "   +%d NHIỆT" % N.heat
		if N.get("rage", 0) > 0:
			meta += "   NỘ %d" % int(g.skill_cost(hover))
		Txt.text(g, Vector2(r.position.x + 12 + Txt.width(N.n) + 12, ty), meta, DIM)
		var lines = wrap_text(N.desc, 95)
		for i in lines.size():
			Txt.text(g, Vector2(r.position.x + 12, ty + 13 + i * 10), lines[i], IVORY)
		var why = Sk.blocked(g.tree, hover, g.lvl, second, g.main_m, g.sec())
		var ny = ty + 17 + lines.size() * 10
		if why == "":
			Txt.text(g, Vector2(r.position.x + 12, ny), "BẤM ĐỂ HỌC", Color("8fe08a"))
		else:
			Txt.text(g, Vector2(r.position.x + 12, ny), why, Color("ff9a8a") if why != Sk.FULL else DIM)
		if N.kind == "a" and g.tree.has(hover):
			Txt.text(g, Vector2(r.position.x + 150, ny), "BẤM 1 ĐẾN 5 ĐỂ GÁN VÀO PHÍM ĐÓ", DIM)
		if N.kind == "u" and g.tree.has(hover):
			Txt.text(g, Vector2(r.position.x + 150, ny), "ĐANG DÙNG" if g.cur_ult() == hover else "BẤM R ĐỂ DÙNG TUYỆT KỸ NÀY", DIM)
	elif g.tab != g.main_m and not second:
		Txt.text(g, Vector2(r.position.x + 12, ty), "MẢNH CHUÔNG CỦA BẠN MỚI CÓ MỘT GIỌNG. HOÀN THÀNH CHƯƠNG MỘT ĐỂ ĐÁNH THỨC GIỌNG THỨ HAI.", DIM)
	elif Sk.SOLO.has(g.tab):
		Txt.text(g, Vector2(r.position.x + 12, ty), "ĐỘC TẤU: CHỈ DÀNH CHO NGƯỜI KHÔNG ĐẶT ĐIỂM NÀO VÀO DÒNG NGHỀ THỨ HAI. CẦN 3 ĐIỂM, THEN CHỐT CẦN 6.", DIM)
		Txt.text(g, Vector2(r.position.x + 12, ty + 12), "ĐI THUẦN, MỖI KỸ NĂNG CHỦ ĐỘNG CÒN HỌC THÊM ĐƯỢC 3 BẬC TINH THÔNG: MỖI BẬC HỒI CHIÊU NHANH HƠN 6%.", DIM)
	elif Sk.LINKS.has(g.tab):
		Txt.text(g, Vector2(r.position.x + 12, ty), "NÚT GIAO THOA KHIẾN KỸ NĂNG CỦA DÒNG NGHỀ NÀY ĐỔI CÁCH DÒNG KIA HOẠT ĐỘNG. CẦN 3 ĐIỂM Ở MỖI DÒNG NGHỀ.", DIM)
		Txt.text(g, Vector2(r.position.x + 12, ty + 12), "CHÁY: SÁT THƯƠNG THEO GIÂY.   LẠNH: CHẬM MỘT NỬA.   GIẬT: NHẬN THÊM SÁT THƯƠNG.", DIM)
	elif g.tab == 28:
		Txt.text(g, Vector2(r.position.x + 12, ty), "NHIỆT: KỸ NĂNG KỸ SƯ KHÔNG TỐN NỘ MÀ CỘNG NHIỆT. TRÊN 70, THIẾT BỊ MẠNH HƠN 20%. CHẠM 100 THÌ QUÁ NHIỆT.", DIM)
		Txt.text(g, Vector2(r.position.x + 12, ty + 12), "QUÁ NHIỆT: KHÔNG DÙNG ĐƯỢC KỸ NĂNG KỸ SƯ TRONG 4 GIÂY. TỐI ĐA 3 THIẾT BỊ; THIẾT BỊ GÂY SÁT THƯƠNG PHỤ.", DIM)
	elif g.tab == 21:
		Txt.text(g, Vector2(r.position.x + 12, ty), "THÀNH KÍNH (TỐI ĐA 100): TĂNG KHI PHÉP HỒI CỦA BẠN HỒI ĐƯỢC MÁU, VÀ KHI ĐỨNG TRONG ĐẤT THIÊNG.", DIM)
		Txt.text(g, Vector2(r.position.x + 12, ty + 12), "SOI: KẺ BỊ SOI NHẬN THÊM 5% SÁT THƯƠNG. PHƯỚC CŨNG ĐẾN VỚI THÚ VÀ DƯ ẢNH CỦA BẠN.", DIM)
	elif g.tab == 15:
		Txt.text(g, Vector2(r.position.x + 12, ty), "TẬP TRUNG: 2 GIÂY KHÔNG CÓ KẺ ĐỊCH NÀO TRONG 80 THÌ ĐÒN HAY KỸ NĂNG KẾ TIẾP MẠNH HƠN 40%.", DIM)
		Txt.text(g, Vector2(r.position.x + 12, ty + 12), "CHÓ SĂN VỌNG: 40% MÁU CỦA BẠN, CẮN 30% TẤN CÔNG, GỤC THÌ 12 GIÂY SAU DẬY. TRÓI: KHÔNG ĐI ĐƯỢC.", DIM)
	elif g.tab == 10:
		Txt.text(g, Vector2(r.position.x + 12, ty), "KHIÊN (TỐI ĐA 100): ĐỠ SÁT THƯƠNG TRƯỚC MÁU. SAU 4 GIÂY KHÔNG BỊ ĐÁNH, MỖI GIÂY MẤT 5 KHIÊN.", DIM)
		Txt.text(g, Vector2(r.position.x + 12, ty + 12), "KHIÊU KHÍCH: KẺ ĐỊCH LAO VÀO BẠN, KỂ CẢ KHI BẠN ĐANG TRONG KHÓI. ĐỒNG MINH GỒM CẢ DƯ ẢNH.", DIM)
	elif g.tab == 6:
		Txt.text(g, Vector2(r.position.x + 12, ty), "HỒN (TỐI ĐA 5): +1 CHO MỖI KẺ CHẾT GẦN BẠN, +1 CHO MỖI MỘT PHẦN MƯỜI MÁU CỦA BOSS.", DIM)
		Txt.text(g, Vector2(r.position.x + 12, ty + 12), "DƯ ẢNH KHÔNG THỂ BỊ ĐÁNH. NGUYỀN: KẺ ĐỊCH GÂY ÍT HƠN 25% SÁT THƯƠNG.", DIM)
	elif g.tab == 3:
		Txt.text(g, Vector2(r.position.x + 12, ty), "ĐIỂM HIỂM (TỐI ĐA 5): +1 KHI CHÉM TỪ SAU LƯNG, CHÉM KẺ ĐANG CHOÁNG HOẶC LẠNH, HOẶC NÉ TRÚNG MỘT ĐÒN.", DIM)
		Txt.text(g, Vector2(r.position.x + 12, ty + 12), "RẠCH VÀ HÀNH QUYẾT LÀ ĐÒN KẾT LIỄU: CHÚNG TIÊU HẾT ĐIỂM HIỂM.   ĐỘC: SÁT THƯƠNG THEO GIÂY, CỘNG DỒN.", DIM)
	elif g.tab == 1:
		Txt.text(g, Vector2(r.position.x + 12, ty), "CỘNG HƯỞNG: DÙNG MỘT PHÉP KHÁC HỆ VỚI PHÉP VỪA DÙNG (TRONG 6 GIÂY) THÌ PHÉP ĐÓ MẠNH HƠN 20%.", DIM)
		Txt.text(g, Vector2(r.position.x + 12, ty + 12), "CHÁY: SÁT THƯƠNG THEO GIÂY.   LẠNH: CHẬM MỘT NỬA.   GIẬT: NHẬN THÊM SÁT THƯƠNG.", DIM)
	else:
		Txt.text(g, Vector2(r.position.x + 12, ty), "MỖI CẤP MỘT ĐIỂM. HÀNG HAI CỦA NHÁNH CẦN 2 ĐIỂM TRONG NHÁNH, THEN CHỐT CẦN 5.", DIM)
		Txt.text(g, Vector2(r.position.x + 12, ty + 12), "VIỀN SÁNG: KỸ NĂNG ĐỂ BẤM. VIỀN VÀNG: THEN CHỐT, ĐỔI MỘT LUẬT VÀ CÓ CÁI GIÁ.", DIM)
	Txt.ctext(g, Vector2(view.x / 2.0, r.end.y - 12), "BẤM VÀO THẺ HOẶC NÚT.   X LẤY LẠI TOÀN BỘ ĐIỂM, MIỄN PHÍ.   T ĐỂ ĐÓNG.", DIM)
	skill_bar(g, view)
