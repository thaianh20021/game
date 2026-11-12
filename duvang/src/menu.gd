extends RefCounted
# Screens outside play: title, character creation, pause, settings, journal, and the full-screen story text.
# `g` is the game node; it holds the state (mode, msel, csel, opt). Mouse or W/S + E both work.

const Art = preload("res://src/art.gd")
const Txt = preload("res://src/font.gd")
const D = preload("res://src/data.gd")
const Sk = preload("res://src/skills.gd")
const Ui = preload("res://src/ui.gd")

const MODES = ["title", "create", "second", "pause", "settings", "journal"]
const IVORY = Color("f4ebd0")
const DIM = Color("8c8577")
const GOLD = Color("ffe9a3")

# The eight masteries of the design. m is the index in skills.gd, or -1 while it is not built.
const CLASSES = [
	{"n": "CHIẾN BINH", "m": 0, "line": "CHUỖI CHÉM NẶNG, ĐỠ ĐÚNG LÚC ĐỂ PHẢN CÔNG.", "icon": "sk_spin"},
	{"n": "NGUYÊN TỐ SƯ", "m": 1, "line": "BA HỆ PHÉP, BA DẤU. ĐỔI HỆ LIÊN TỤC ĐỂ CỘNG HƯỞNG.", "icon": "sk_spark"},
	{"n": "HỘ VỆ", "m": 10, "line": "KHIÊN DÀY, KÉO ĐÒN VỀ MÌNH, CHE CHO ĐỒNG ĐỘI.", "icon": "sk_raise"},
	{"n": "SÁT THỦ", "m": 3, "line": "TÍCH ĐIỂM HIỂM RỒI KẾT LIỄU. NHANH VÀ MỎNG.", "icon": "sk_slash"},
	{"n": "THỢ SĂN", "m": 15, "line": "GIỮ KHOẢNG CÁCH, ĐẶT BẪY, ĐI CÙNG MỘT CON CHÓ SĂN.", "icon": "sk_aimed"},
	{"n": "THUẬT SĨ LINH HỒN", "m": 6, "line": "GẶT HỒN KẺ CHẾT ĐỂ GỌI DƯ ẢNH.", "icon": "sk_scythe"},
	{"n": "TƯ TẾ", "m": 21, "line": "HỒI MÁU, BAN PHƯỚC, THANH TẨY. GÕ MÕ GIỮ MẠNG CHO MÌNH VÀ THÚ.", "icon": "sk_knell"},
	{"n": "KỸ SƯ CỔ VẬT", "m": 28, "line": "ĐẶT THIẾT BỊ VÀ GIỮ NHIỆT Ở MỨC VỪA ĐỦ.", "icon": "sk_turret"},
]

static func open(g, mode: String) -> void:
	g.mode = mode
	g.msel = 0
	g.p.vel = Vector2.ZERO
	g.p.moving = false
	g.buf = ""

static func on_off(b: bool) -> String:
	return "BẬT" if b else "TẮT"

# [label, action] for the list screens
static func items(g) -> Array:
	match g.mode:
		"title":
			var a = []
			if g.has_save:
				a.append(["TIẾP TỤC", "continue"])
			a.append_array([["CHƠI MỚI", "new"], ["CÀI ĐẶT", "settings"], ["THOÁT", "quit"]])
			return a
		"pause":
			return [["TIẾP TỤC", "resume"], ["CÂY KỸ NĂNG", "tree"], ["TÚI ĐỒ", "inv"], ["NHẬT KÝ", "journal"], ["CÀI ĐẶT", "settings"], ["VỀ MÀN HÌNH CHÍNH", "title"]]
		"settings":
			var o = g.opt
			return [["ÂM THANH   %d" % int(o.sfx), "sfx"], ["NHẠC   %d" % int(o.music), "music"], ["RUNG MÀN HÌNH   %d" % int(o.shake), "shake"],
				["CHỚP TRẮNG KHI TRÚNG   " + on_off(o.flash), "flash"], ["SỐ SÁT THƯƠNG   " + on_off(o.nums), "nums"],
				["TOÀN MÀN HÌNH   " + on_off(o.full), "full"], ["QUAY LẠI", "back"]]
	return []

static func item_rect(g, view: Vector2, i: int, n: int) -> Rect2:
	var y0 = 176.0 if g.mode == "title" else view.y / 2.0 - n * 9.0 + 8.0
	return Rect2(view.x / 2.0 - 110, y0 + i * 18, 220, 15)

static func card_rect(view: Vector2, i: int) -> Rect2:
	return Rect2(view.x / 2.0 - 290 + (i % 4) * 146, 62 + (i / 4) * 84, 140, 78)

static func start_rect(view: Vector2) -> Rect2:
	return Rect2(view.x / 2.0 - 80, 240, 160, 18)

# moves g.msel with the keys or the mouse; returns the index that was chosen this frame, or -1
static func pick(g, rects: Array) -> int:
	var mv = g.move_dir()
	var nav = 0
	if absf(mv.y) > 0.5:
		nav = 1 if mv.y > 0.0 else -1
	elif absf(mv.x) > 0.5 and (g.mode == "create" or g.mode == "second"):
		nav = 1 if mv.x > 0.0 else -1
	if nav != 0 and nav != g.nav_prev:
		g.msel = wrapi(g.msel + nav, 0, rects.size())
	g.nav_prev = nav
	var m = g.ui_mouse()
	var over = -1
	for i in rects.size():
		if rects[i].has_point(m):
			over = i
	if over >= 0 and m != g.mouse_prev:
		g.msel = over
	g.mouse_prev = m
	if over >= 0 and g.pressed("atk"):
		g.msel = over
		return over
	if g.pressed("use"):
		return g.msel
	return -1

static func update(g) -> void:
	var view = g.get_viewport_rect().size
	if g.mode == "journal":
		if g.pressed("menu") or g.pressed("use") or g.pressed("atk"):
			open(g, "pause")
			g.msel = 3
		return
	if g.mode == "create" or g.mode == "second":
		var rects = []
		for i in CLASSES.size():
			rects.append(card_rect(view, i))
		var k = pick(g, rects)
		if not pickable(g, g.msel):
			g.msel = g.csel
		g.csel = g.msel
		if g.pressed("menu") and g.mode == "create":
			open(g, "title")
		elif g.mode == "second" and ((k >= 0 and pickable(g, k) and g.pressed("use")) or (g.pressed("atk") and start_rect(view).has_point(g.ui_mouse()))):
			g.second_m = CLASSES[g.csel].m
			g.tab = g.second_m
			g.hold_block = true
			g.mode = "play"
			g.toast("GIỌNG THỨ HAI: " + CLASSES[g.csel].n, GOLD)
			g.save_game()
		elif g.mode == "create" and ((k >= 0 and pickable(g, k) and g.pressed("use")) or (g.pressed("atk") and start_rect(view).has_point(g.ui_mouse()))):
			g.start_new(CLASSES[g.csel].m)
		return
	var its = items(g)
	var rects = []
	for i in its.size():
		rects.append(item_rect(g, view, i, its.size()))
	var k = pick(g, rects)
	if g.pressed("menu"):
		if g.mode == "pause":
			act(g, "resume")
		elif g.mode == "settings":
			act(g, "back")
	elif k >= 0:
		act(g, its[k][1])

static func act(g, what: String) -> void:
	var o = g.opt
	g.hold_block = true
	match what:
		"continue", "resume":
			g.mode = "play"
			if what == "continue":
				g.banner_t = 2.5
		"new":
			open(g, "create")
			g.csel = 0
		"settings":
			g.menu_back = g.mode
			open(g, "settings")
		"quit":
			g.get_tree().quit()
		"tree":
			g.mode = "tree"
		"inv":
			g.open_inv(false)
		"journal":
			g.mode = "journal"
		"title":
			g.mode = "play"
			g.save_game()
			g.has_save = true
			open(g, "title")
		"back":
			var back = g.menu_back
			open(g, back)
			g.msel = 4 if back == "pause" else maxi(0, items(g).size() - 2)
		"sfx":
			o.sfx = float((int(o.sfx) + 10) % 110)
		"music":
			o.music = float((int(o.music) + 10) % 110)
		"shake":
			o.shake = {100: 50.0, 50: 0.0, 0: 100.0}[int(o.shake)]
		"flash":
			o.flash = not o.flash
		"nums":
			o.nums = not o.nums
		"full":
			o.full = not o.full
			g.apply_window()
	if ["sfx", "music", "shake", "flash", "nums", "full"].has(what):
		g.apply_opt()
		g.save_opt()
		g.Sfx.play("clap", 1.4, -6.0)

# ---------------------------------------------------------------- drawing

static func list(g, view: Vector2) -> void:
	var its = items(g)
	for i in its.size():
		var r = item_rect(g, view, i, its.size())
		var on = i == g.msel
		if on:
			g.draw_rect(r, Color("7a4b2a"))
			g.draw_rect(Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 2)), Color("3a3046"))
		Txt.ctext(g, r.position + Vector2(r.size.x / 2.0, 4), its[i][0], GOLD if on else IVORY)

static func draw(g, view: Vector2) -> void:
	match g.mode:
		"title":
			g.draw_rect(Rect2(Vector2.ZERO, view), Color(0.04, 0.03, 0.07, 0.62))
			Txt.ctext(g, Vector2(view.x / 2.0, 62), "DƯ VANG", GOLD, 6)
			Txt.ctext(g, Vector2(view.x / 2.0, 122), "TIẾNG CÒN LẠI SAU KHI CHUÔNG ĐÃ NGỪNG", IVORY)
			list(g, view)
			Txt.ctext(g, Vector2(view.x / 2.0, view.y - 16), "CHẠM ĐỂ CHỌN." if g.touch_on else "W S HOẶC CHUỘT ĐỂ CHỌN.   E HOẶC BẤM CHUỘT ĐỂ XÁC NHẬN.", DIM)
		"pause", "settings":
			g.draw_rect(Rect2(Vector2.ZERO, view), Color(0.04, 0.03, 0.07, 0.6))
			var n = items(g).size()
			var top = item_rect(g, view, 0, n).position.y
			Ui.frame(g, Rect2(view.x / 2.0 - 130, top - 30, 260, n * 18 + 44))
			Txt.ctext(g, Vector2(view.x / 2.0, top - 20), "TẠM DỪNG" if g.mode == "pause" else "CÀI ĐẶT", GOLD)
			list(g, view)
			if g.mode == "settings":
				Txt.ctext(g, Vector2(view.x / 2.0, top + n * 18 + 22), "CHẠM ĐỂ ĐỔI GIÁ TRỊ." if g.touch_on else "E HOẶC BẤM CHUỘT ĐỂ ĐỔI GIÁ TRỊ.   ESC ĐỂ QUAY LẠI.", DIM)
		"create", "second":
			create(g, view)
		"journal":
			journal(g, view)

static func create(g, view: Vector2) -> void:
	g.draw_rect(Rect2(Vector2.ZERO, view), Color(0.04, 0.03, 0.07, 0.82))
	var sec2 = g.mode == "second"
	Txt.ctext(g, Vector2(view.x / 2.0, 14), "GIỌNG THỨ HAI CỦA MẢNH CHUÔNG LÀ AI?" if sec2 else "MẢNH CHUÔNG CỦA VÃN MANG TAY NGHỀ NÀO?", GOLD, 2)
	Txt.ctext(g, Vector2(view.x / 2.0, 40), "HAI DÒNG NGHỀ HỢP THÀNH MỘT HỢP ÂM, CÓ CÂY GIAO THOA RIÊNG. KHÔNG ĐỔI LẠI ĐƯỢC." if sec2 else "ĐÂY LÀ DÒNG NGHỀ ĐẦU CỦA BẠN. DÒNG THỨ HAI MỞ Ở CUỐI CHƯƠNG MỘT.", IVORY)
	for i in CLASSES.size():
		var C = CLASSES[i]
		var r = card_rect(view, i)
		var ok = pickable(g, i)
		var on = i == g.csel
		g.draw_rect(r, GOLD if on else (Color("7a4b2a") if ok else Color("3a3046")))
		g.draw_rect(Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 2)), Color("3a3046") if on else (Color("2a2030") if ok else Color("1d1723")))
		if Art.T.has(C.icon):
			g.draw_texture(Art.T[C.icon], r.position + Vector2(5, 5), Color.WHITE if ok else Color(0.35, 0.35, 0.4))
		Txt.text(g, r.position + Vector2(30, 6), C.n.substr(0, 17), (GOLD if on else IVORY) if ok else DIM)
		if not ok:
			Txt.text(g, r.position + Vector2(30, 17), "CHƯA MỞ" if C.m < 0 else "DÒNG NGHỀ ĐẦU", Color("5a4e66"))
		elif C.m >= 0:
			Txt.text(g, r.position + Vector2(30, 17), " ".join(Sk.BRANCHES[C.m]).substr(0, 17), Sk.COLS[C.m][1])
		var lines = Ui.wrap_text(C.line, 22)
		for j in lines.size():
			Txt.text(g, r.position + Vector2(6, 32 + j * 10), lines[j], IVORY if ok else Color("5a4e66"))
	# the chosen mastery's look, twice the size, under the start button
	var cm = CLASSES[g.csel].m
	var pic = "hd_idle"
	if Art.T.has("k%d_hd_idle" % cm):
		pic = "k%d_hd_idle" % cm
	if Art.T.has(pic):
		var tex: Texture2D = Art.T[pic]
		var sz = tex.get_size() * 2.0
		g.draw_texture_rect(tex, Rect2(Vector2(view.x / 2.0 - sz.x / 2.0, 264.0).floor(), sz), false)
	var sr = start_rect(view)
	g.draw_rect(sr, GOLD)
	g.draw_rect(Rect2(sr.position + Vector2(1, 1), sr.size - Vector2(2, 2)), Color("7a4b2a") if sr.has_point(g.ui_mouse()) else Color("3a3046"))
	Txt.ctext(g, sr.position + Vector2(sr.size.x / 2.0, 5), ("CHỌN: " if sec2 else "BẮT ĐẦU: ") + CLASSES[g.csel].n, GOLD)
	Txt.ctext(g, Vector2(view.x / 2.0, view.y - 16), "CHỌN MỘT THẺ RỒI CHẠM NÚT." if g.touch_on else "CHỌN MỘT THẺ RỒI BẤM NÚT HOẶC E." + ("" if sec2 else "   ESC ĐỂ QUAY LẠI."), DIM)

static func journal(g, view: Vector2) -> void:
	g.draw_rect(Rect2(Vector2.ZERO, view), Color(0.04, 0.03, 0.07, 0.6))
	var r = Rect2(view.x / 2.0 - 250, 30, 500, 300)
	Ui.frame(g, r)
	Txt.text(g, r.position + Vector2(12, 8), "NHẬT KÝ", GOLD)
	var who = "%s  CẤP %d" % [Sk.MASTERY[g.main_m], g.lvl]
	Txt.text(g, Vector2(r.end.x - 12 - Txt.width(who), r.position.y + 8), who, DIM)
	var y = r.position.y + 26
	var rows = []
	for id in D.ORDER:
		if D.QUESTS[id].main and g.qs.get(id, "") == "done" and D.RECAP.has(id):
			var txt = D.RECAP[id]
			if typeof(txt) == TYPE_ARRAY:
				txt = txt[g.flags.get(D.QUESTS[id].get("branch", ""), 0)]
			rows.append(txt)
	if rows.is_empty():
		rows.append("CHƯA CÓ GÌ ĐỂ KỂ. HÃY GẶP BÀ CẢ SẬY Ở NHÀ PHƯỜNG.")
	# the newest entries, as many as fit
	var shown = []
	var used = 0
	for i in range(rows.size() - 1, -1, -1):
		var w = Ui.wrap_text(rows[i], 78)
		if used + w.size() + 1 > 19:
			break
		used += w.size() + 1
		shown.push_front(w)
	for w in shown:
		for line in w:
			Txt.text(g, Vector2(r.position.x + 14, y), line, IVORY)
			y += 10
		y += 5
	for id in D.ORDER:
		if g.qs.get(id, "") == "active" or g.qs.get(id, "") == "ready":
			Txt.text(g, Vector2(r.position.x + 14, r.end.y - 34), "ĐANG LÀM: %s. %s." % [D.QUESTS[id].name, D.QUESTS[id].goal], GOLD)
			break
	Txt.ctext(g, Vector2(view.x / 2.0, r.end.y - 14), "ESC HOẶC E ĐỂ QUAY LẠI.", DIM)

# narration with no speaker: the whole screen goes dark and the text stands alone
static func story(g, view: Vector2) -> void:
	g.draw_rect(Rect2(Vector2.ZERO, view), Color(0.04, 0.03, 0.07, 0.9))
	var lines = Ui.wrap_text(g.talk.lines[g.talk.i], 62)
	var y = view.y / 2.0 - lines.size() * 7.0
	for i in lines.size():
		Txt.ctext(g, Vector2(view.x / 2.0, y + i * 14), lines[i], IVORY)
	for i in g.talk.lines.size():
		g.draw_rect(Rect2(view.x / 2.0 - g.talk.lines.size() * 5.0 + i * 10, view.y - 44, 6, 2), GOLD if i <= g.talk.i else Color("3a3046"))
	if int(g.t * 2.0) % 2 == 0:
		Txt.ctext(g, Vector2(view.x / 2.0, view.y - 30), "E", GOLD)

# can card i be chosen on the screen that is up: built, and not the first mastery again when picking the second
static func pickable(g, i: int) -> bool:
	var C = CLASSES[i]
	return C.m >= 0 and (g.mode != "second" or C.m != g.main_m)
