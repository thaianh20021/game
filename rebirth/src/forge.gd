extends RefCounted
# The Word Forge: melt both carried weapons into one stronger, partly random weapon,
# steered by a command. The command is plain words in English or Vietnamese (with or
# without accents), or a sequence of gamepad buttons. Rule-based keyword matching, no model.

const D = preload("res://src/data.gd")
const Art = preload("res://src/art.gd")
const Px = preload("res://src/font.gd")
const Sfx = preload("res://src/sfx.gd")
const Arms = preload("res://src/arms.gd")

const COST = 30
const MAXLEN = 40

const ELEMENTS = {
	"fire": ["fire", "flame", "burn", "hot", "ember", "lua", "chay", "nong"],
	"ice": ["ice", "frost", "cold", "freeze", "snow", "bang", "lanh", "tuyet"],
	"bolt": ["storm", "bolt", "lightning", "thunder", "shock", "electric", "set", "sam", "dien"],
	"tox": ["poison", "venom", "toxic", "acid", "doc", "axit"],
	"stone": ["stone", "rock", "boulder", "da"],
	"wind": ["wind", "air", "gale", "breeze", "gio", "phong"],
	"light": ["light", "sun", "holy", "radiant", "sang", "quang", "nang"],
	"void": ["void", "dark", "shadow", "night", "toi", "bong", "hu"],
	"water": ["water", "tide", "sea", "river", "aqua", "nuoc", "thuy", "song"],
	"leaf": ["leaf", "grass", "vine", "herb", "la", "co"],
	"earth": ["earth", "soil", "mud", "sand", "clay", "dat", "tho", "cat"],
	"metal": ["metal", "iron", "steel", "kim", "sat", "thep"],
	"wood": ["wood", "tree", "timber", "log", "go", "moc", "cay"],
	"mech": ["mech", "gear", "machine", "clock", "robot", "engine", "khi", "cokhi", "banhrang"],
	"x": ["x", "chaos", "unknown", "wild", "loan", "bian"],
}
const TRAITS = {
	"multi": ["many", "multi", "spread", "split", "triple", "double", "nhieu", "chum", "toa"],
	"pierce": ["pierce", "piercing", "sharp", "through", "xuyen", "nhon", "sac"],
	"bounce": ["bounce", "bouncing", "ricochet", "nay", "bat"],
	"blast": ["bomb", "blast", "explode", "explosive", "explosion", "boom", "bom", "~no"],
	"homing": ["homing", "seek", "seeking", "track", "follow", "duoi", "tim", "theo"],
	"swift": ["fast", "quick", "rapid", "speed", "nhanh", "toc", "le"],
	"keen": ["strong", "power", "powerful", "big", "heavy", "deadly", "manh", "~to", "khung", "lon"],
	"zap": ["chain", "arc", "arcing", "lan", "giat"],
}
const SHAPES = {
	"BLADE": [["sword", "blade", "melee", "axe", "hammer", "spear", "kiem", "dao", "riu", "bua", "giao"], ["blade", "greatblade", "axe", "hammer", "spear"]],
	"BOW": [["bow", "arrow", "cung", "ten", "no~"], ["bow", "crossbow", "kunai"]],
	"SHOOTER": [["gun", "shoot", "shooter", "horn", "sung", "ban"], ["pistol", "repeater", "twins", "needle", "scatter"]],
	"BEAM": [["beam", "laser", "ray", "lens", "tia"], ["beam"]],
	"MAGIC": [["staff", "magic", "wand", "spell", "gay", "phep", "truong"], ["wand", "nova", "grimoire", "coil"]],
	"BOMBER": [["cannon", "launcher", "mortar", "drum", "phao", "luu"], ["mortar", "launcher", "flask"]],
	"RING": [["ring", "disc", "halo", "boomerang", "vong", "dia"], ["chakram", "boomerang"]],
}
# gamepad: d-pad picks elements, face buttons pick traits
const PAD = {
	JOY_BUTTON_DPAD_UP: ["UP", "el", "fire"], JOY_BUTTON_DPAD_RIGHT: ["RIGHT", "el", "bolt"],
	JOY_BUTTON_DPAD_DOWN: ["DOWN", "el", "ice"], JOY_BUTTON_DPAD_LEFT: ["LEFT", "el", "tox"],
	JOY_BUTTON_A: ["A", "tr", "multi"], JOY_BUTTON_B: ["B", "tr", "blast"], JOY_BUTTON_X: ["X", "tr", "pierce"],
	JOY_BUTTON_Y: ["Y", "tr", "homing"], JOY_BUTTON_RIGHT_SHOULDER: ["RB", "tr", "swift"], JOY_BUTTON_RIGHT_STICK: ["R3", "tr", "keen"],
}
const PREFIX = ["ANCIENT", "HOWLING", "STARFORGED", "HOLLOW", "RADIANT", "GRIM", "WILD", "SILENT", "ROYAL", "FERAL", "LOST", "DREAD"]

const FOLD = {
	"a": "àáảãạăằắẳẵặâầấẩẫậ", "e": "èéẻẽẹêềếểễệ", "i": "ìíỉĩị", "o": "òóỏõọôồốổỗộơờớởỡợ",
	"u": "ùúủũụưừứửữự", "y": "ỳýỷỹỵ", "d": "đ",
}

# Lower-case and strip Vietnamese accents so "lửa", "LUA" and "lua" all match.
static func fold(s: String) -> String:
	var out = ""
	for ch in s.to_lower():
		var r = ch
		for base in FOLD:
			if FOLD[base].contains(ch):
				r = base
				break
		out += r
	return out

static func parse(text: String, pad: Array) -> Dictionary:
	var res = {els = [], traits = [], shape = ""}
	var raw = text.to_lower().replace(",", " ").replace(".", " ").replace("-", " ")
	for word in raw.split(" ", false):
		var f = fold(word)
		var accented = f != word
		for el in ELEMENTS:
			if ELEMENTS[el].has(f) and not res.els.has(el):
				res.els.append(el)
		for tr in TRAITS:
			# "~word" only counts when it was typed with an accent (no / to are English words too)
			if (TRAITS[tr].has(f) or (accented and TRAITS[tr].has("~" + f))) and not res.traits.has(tr):
				res.traits.append(tr)
		for sh in SHAPES:
			if res.shape == "" and (SHAPES[sh][0].has(f) or (accented and SHAPES[sh][0].has(f + "~"))):
				res.shape = sh
	for b in pad:
		if not PAD.has(b):
			continue
		var t = PAD[b]
		var list: Array = res.els if t[1] == "el" else res.traits
		if not list.has(t[2]):
			list.append(t[2])
	return res

# ---- the screen ------------------------------------------------------------------

static func open(g, it: Dictionary) -> void:
	var p = g.p
	var at = p.pos + Vector2(0, -22)
	if p.weapons[1] == null:
		Sfx.play("deny")
		g.label(at, "NEEDS TWO WEAPONS", Color("ff6a6a"))
		return
	if p.gold < COST:
		Sfx.play("deny")
		g.label(at, "NOT ENOUGH GOLD", Color("ff6a6a"))
		return
	g.forge = {text = "", pad = [], it = it, idx = p.idx}
	g.set_state("forge")
	Sfx.play("ui")
	if g.tin.on:
		DisplayServer.virtual_keyboard_show("")

static func close(g) -> void:
	if g.tin.on:
		DisplayServer.virtual_keyboard_hide()
	g.set_state("play")

static func key_input(g, ev: InputEventKey) -> void:
	var f = g.forge
	if ev.keycode == KEY_BACKSPACE:
		if f.text != "":
			f.text = f.text.substr(0, f.text.length() - 1)
		elif not f.pad.is_empty():
			f.pad.pop_back()
	elif ev.unicode >= 32 and ev.unicode != 127 and f.text.length() < MAXLEN:
		f.text += char(ev.unicode)

static func update(g) -> void:
	var f = g.forge
	if not g.pad_jp.is_empty():
		for dev in g.pad_jp:
			for b in g.pad_jp[dev]:
				if b == JOY_BUTTON_START:
					confirm(g)
					return
				elif b == JOY_BUTTON_BACK:
					close(g)
					return
				elif b == JOY_BUTTON_LEFT_SHOULDER:
					if not f.pad.is_empty():
						f.pad.pop_back()
				elif PAD.has(b) and f.pad.size() < 8:
					f.pad.append(b)
					Sfx.play("ui")
		return
	if g.state_t < 0.15:
		return
	if g.jpk(KEY_ESCAPE):
		close(g)
	elif g.jpk(KEY_ENTER) or g.jpk(KEY_KP_ENTER):
		confirm(g)
	elif g.tin.on and g.jpk("m1"):
		if Rect2(140, 196, 90, 18).has_point(g.mouse()):
			confirm(g)
		elif Rect2(250, 196, 90, 18).has_point(g.mouse()):
			close(g)

static func build(g, text: String, pad: Array) -> Dictionary:
	var p = g.p
	var rng: RandomNumberGenerator = g.rng
	var w = p.weapons[p.wi]
	var o = p.weapons[1 - p.wi]
	var k = parse(text, pad)
	var base: String = [w.id, o.id][rng.randi() % 2]
	if k.shape != "":
		var opts: Array = SHAPES[k.shape][1]
		base = opts[rng.randi() % opts.size()]
	var els: Array = k.els.duplicate()
	if els.is_empty():
		for q in [w.el, w.get("el2", ""), o.el, o.get("el2", "")]:
			if q != "" and q != "prism" and not els.has(q):
				els.append(q)
	if els.is_empty():
		els.append(D.EL[rng.randi() % 4])
	# one trait is inherited from whichever parent the result is not shaped after
	var inherit: String = Arms.trait_of(o.id if base == w.id else w.id)
	var extra = []
	for t in k.traits:
		if t != inherit and extra.size() < 2:
			extra.append(t)
	if extra.is_empty():
		var pool = Arms.TRAIT_NAME.keys()
		pool.erase(inherit)
		extra.append(pool[rng.randi() % pool.size()])
	return {
		"id": base, "el": els[0], "el2": els[1] if els.size() > 1 else "",
		"lv": mini(5, maxi(int(w.get("lv", 0)), int(o.get("lv", 0))) + 1),
		"trait": inherit, "traits": extra, "pow": snappedf(rng.randf_range(1.3, 1.6), 0.01),
		"fname": PREFIX[rng.randi() % PREFIX.size()] + " " + D.WEAPONS[base].name,
	}

static func confirm(g) -> void:
	var f = g.forge
	g.bind(g.players[mini(int(f.idx), g.players.size() - 1)])
	var p = g.p
	if p.weapons[1] == null or p.gold < COST:
		close(g)
		return
	var res = build(g, f.text, f.pad)
	p.gold -= COST
	p.weapons = [res, null]
	p.wi = 0
	g.Meta.record("weapons", res.id)
	close(g)
	var names = [Arms.TRAIT_NAME[res.trait]]
	for t in res.traits:
		names.append(Arms.TRAIT_NAME[t])
	g.banner = {text = res.fname, sub = "+%d%% DAMAGE. %s" % [int((res.pow - 1.0) * 100.0), ", ".join(names)], t = 4.5}
	var pos: Vector2 = f.it.pos if f.it != null else p.pos
	g.rings.append({pos = pos, r = 60.0, t = 0.0, col = Color("ffd24a")})
	g.rings.append({pos = pos, r = 36.0, t = 0.0, col = D.EL_COL[res.el]})
	g.burst(pos + Vector2(0, -8), 24, D.EL_COL[res.el], 110.0, 0.6)
	g.flash(pos, 120.0, Color("ffd24a"), 0.5)
	g.shake_add(5.0)
	Sfx.play("chest")
	Sfx.play("react", 0.7)

static func draw(g, ci: CanvasItem, Hud) -> void:
	var f = g.forge
	var p = g.p
	ci.draw_rect(Rect2(0, 0, 480, 270), Color(0.02, 0.01, 0.05, 0.78))
	Hud.panel(ci, Rect2(60, 34, 360, 196), Color(0.07, 0.05, 0.12, 0.97), Color("ffd24a"))
	Px.ctext(ci, Vector2(240, 42), "WORD FORGE", Color("ffd24a"), 2)
	if p.weapons[1] != null:
		for i in 2:
			var w = p.weapons[i]
			var t: Texture2D = Art.T[Art.wtex(w)]
			var x = 150 + i * 180
			ci.draw_texture(t, Vector2(x - t.get_width() / 2.0, 70 - t.get_height() / 2.0).round())
			Px.ctext(ci, Vector2(x, 80), g.wname(w).substr(0, 26), D.EL_COL[w.el])
		Px.ctext(ci, Vector2(240, 66), "+", Color("ffd24a"), 2)
	Px.ctext(ci, Vector2(240, 96), "DESCRIBE THE WEAPON YOU WANT. ENGLISH OR VIETNAMESE.", Color("d9d4c7"))
	# the command line
	var line = fold(f.text).to_upper()
	for b in f.pad:
		line += (" " if line != "" else "") + PAD[b][0]
	Hud.panel(ci, Rect2(90, 108, 300, 18), Color(0.02, 0.01, 0.05, 1.0), Color("7adfff"))
	Px.text(ci, Vector2(96, 114), line + ("_" if int(g.time * 3.0) % 2 == 0 else ""), Color.WHITE)
	# what the forge understood
	var k = parse(f.text, f.pad)
	var x0 = 96.0
	Px.text(ci, Vector2(x0, 134), "ELEMENT", Color("6b6779"))
	if k.els.is_empty():
		Px.text(ci, Vector2(x0 + 60, 134), "FROM BOTH WEAPONS", Color("6b6779"))
	for i in mini(2, k.els.size()):
		ci.draw_texture(Art.T["ic_" + k.els[i]], Vector2(x0 + 60 + i * 60, 132))
		Px.text(ci, Vector2(x0 + 70 + i * 60, 134), D.EL_NAME[k.els[i]], D.EL_COL[k.els[i]])
	Px.text(ci, Vector2(x0, 146), "SHAPE", Color("6b6779"))
	Px.text(ci, Vector2(x0 + 60, 146), k.shape if k.shape != "" else "ONE OF THE TWO", Color("d9d4c7") if k.shape != "" else Color("6b6779"))
	Px.text(ci, Vector2(x0, 158), "TRAITS", Color("6b6779"))
	var names = []
	for t in k.traits.slice(0, 2):
		names.append(Arms.TRAIT_NAME[t])
	Px.text(ci, Vector2(x0 + 60, 158), ", ".join(names) if not names.is_empty() else "A RANDOM ONE", Color("ffd24a") if not names.is_empty() else Color("6b6779"))
	Px.ctext(ci, Vector2(240, 174), "TRY: FAST FIRE BOW   /   CUNG LUA NHANH   /   KIEM BANG MANH", Color("6b6779"))
	Px.ctext(ci, Vector2(240, 184), "PAD: D-PAD ELEMENT, A MANY, B BLAST, X PIERCE, Y SEEK, RB FAST", Color("6b6779"))
	if g.tin.on:
		Hud.panel(ci, Rect2(140, 196, 90, 18), Color(0.1, 0.2, 0.1, 0.95), Color("a6e84e"))
		Px.ctext(ci, Vector2(185, 202), "FORGE", Color("a6e84e"))
		Hud.panel(ci, Rect2(250, 196, 90, 18), Color(0.2, 0.08, 0.08, 0.95), Color("ff6a6a"))
		Px.ctext(ci, Vector2(295, 202), "CANCEL", Color("ff6a6a"))
	else:
		Px.ctext(ci, Vector2(240, 202), "ENTER OR START: FORGE FOR %d GOLD      ESC OR BACK: CANCEL" % COST, Color("ffd24a"))
	Px.ctext(ci, Vector2(240, 216), "BOTH WEAPONS ARE CONSUMED. THE RESULT IS ALWAYS STRONGER.", Color("d9d4c7"))
