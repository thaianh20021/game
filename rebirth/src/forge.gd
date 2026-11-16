extends RefCounted
# The Word Forge: melt both carried weapons into one stronger weapon. It offers three
# ready-made fusions to choose from (it used to take a typed command). The word lists below are
# still used by wishes and skill names.

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

# ---- the screen: three ready-made fusions to choose from (owner, 2026-11-16: no typing) ------

const CARD_W = 152.0

# Three fusions of the two carried weapons: shaped after the one in hand, after the other one,
# and after a third kind; each carries one of the new weapon mechanics (src/wmods.gd), a
# trait inherited from the other parent, both parents' elements, a level more and more power.
static func options(g) -> Array:
	var p = g.p
	var rng: RandomNumberGenerator = g.rng
	var w = p.weapons[p.wi]
	var o = p.weapons[1 - p.wi]
	var els = []
	for q in [w.el, w.get("el2", ""), o.el, o.get("el2", "")]:
		if q != "" and q != "prism" and not els.has(q):
			els.append(q)
	if els.is_empty():
		els.append(D.EL[rng.randi() % 4])
	var types = [D.WEAPONS[w.id].type, D.WEAPONS[o.id].type]
	var others = D.WEAPONS.keys().filter(func(k): return not D.WEAPONS[k].get("bp", false) and not types.has(D.WEAPONS[k].type) and int(D.WEAPONS[k].rar) in [1, 2])
	if others.is_empty():
		others = D.WEAPONS.keys().filter(func(k): return k != w.id and k != o.id)
	var ids = [w.id, o.id, others[rng.randi() % others.size()]]
	if ids[1] == ids[0]:
		ids[1] = others[rng.randi() % others.size()]
	var mech: Array = g.WMods.NEW.duplicate()
	for i in range(mech.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var tmp = mech[i]
		mech[i] = mech[j]
		mech[j] = tmp
	# gathering makes no sense on a beam: it would be one tick of it
	for i in 3:
		if mech[i] == "charge" and D.WEAPONS[ids[i]].type == "beam":
			mech[i] = mech[3]
			mech[3] = "charge"
	# now and then one fusion carries two mechanics, at a lower damage bonus
	var twin = rng.randf() < D.WMOD.twin
	var ti = rng.randi() % 3
	var out = []
	for i in 3:
		var base: String = ids[i]
		var e1: String = els[i % els.size()]
		var e2: String = els[(i + 1) % els.size()] if els.size() > 1 else ""
		out.append({
			"id": base, "el": e1, "el2": e2 if e2 != e1 else "",
			"lv": mini(5, maxi(int(w.get("lv", 0)), int(o.get("lv", 0))) + 1),
			"trait": Arms.trait_of(o.id if i == 0 else w.id), "traits": [mech[i]],
			"pow": snappedf(rng.randf_range(1.3, 1.6), 0.01),
			"fname": PREFIX[rng.randi() % PREFIX.size()] + " " + D.WEAPONS[base].name,
		})
		if twin and i == ti:
			var m2: String = mech[3] if not (mech[3] == "charge" and D.WEAPONS[base].type == "beam") else mech[4]
			out[i].traits.append(m2)
			out[i].pow = snappedf(rng.randf_range(D.WMOD.twin_pow[0], D.WMOD.twin_pow[1]), 0.01)
			out[i].fname = "TWIN " + D.WEAPONS[base].name
	return out

const SALVAGE = Rect2(110, 222, 260, 13)

# Fourth choice: keep both weapons and take materials instead. Once per forge.
static func salvage(g) -> void:
	var f = g.forge
	var p = g.p
	if f.it != null and f.it.get("salv", false):
		Sfx.play("deny")
		return
	if f.it != null:
		f.it.salv = true
	for k in ["ore", "ess", "fib"]:
		g.Meta.add_mat(k, D.WMOD.salvage_mat)
	g.Meta.S.scrap = int(g.Meta.S.scrap) + D.WMOD.salvage_scrap
	close(g)
	g.label(p.pos + Vector2(0, -24), "+%d ORE ESSENCE FIBER  +%d SCRAP" % [D.WMOD.salvage_mat, D.WMOD.salvage_scrap], Color("ffd24a"))
	Sfx.play("pick")
	g.burst(p.pos + Vector2(0, -8), 12, Color("c9b27a"), 80.0, 0.5)

static func card_rect(i: int) -> Rect2:
	return Rect2(240.0 - CARD_W * 1.5 - 4.0 + i * (CARD_W + 4.0), 52, CARD_W, 168)

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
	g.forge = {opts = options(g), sel = 0, it = it, idx = p.idx}
	g.set_state("forge")
	Sfx.play("ui")

static func close(g) -> void:
	g.set_state("play")

# Typing is gone; kept so old callers do nothing.
static func key_input(g, ev: InputEventKey) -> void:
	pass

static func update(g) -> void:
	var f = g.forge
	if not g.pad_jp.is_empty():
		for dev in g.pad_jp:
			for b in g.pad_jp[dev]:
				match b:
					JOY_BUTTON_DPAD_LEFT:
						f.sel = (f.sel + 2) % 3
						Sfx.play("ui")
					JOY_BUTTON_DPAD_RIGHT:
						f.sel = (f.sel + 1) % 3
						Sfx.play("ui")
					JOY_BUTTON_DPAD_DOWN:
						f.sel = 3
						Sfx.play("ui")
					JOY_BUTTON_DPAD_UP:
						f.sel = 0 if f.sel == 3 else f.sel
						Sfx.play("ui")
					JOY_BUTTON_A, JOY_BUTTON_START:
						confirm(g, f.sel)
						return
					JOY_BUTTON_B, JOY_BUTTON_BACK:
						close(g)
						return
		return
	if g.state_t < 0.15:
		return
	var m: Vector2 = g.mouse()
	for i in 3:
		if card_rect(i).has_point(m):
			if f.sel != i and not g.tin.on:
				f.sel = i
			if g.jpk("m1"):
				confirm(g, i)
				return
	if SALVAGE.has_point(m):
		if not g.tin.on:
			f.sel = 3
		if g.jpk("m1"):
			confirm(g, 3)
			return
	for i in 4:
		if g.jpk(KEY_1 + i):
			confirm(g, i)
			return
	if g.jpk(KEY_DOWN) or g.jpk(KEY_S):
		f.sel = 3
	elif (g.jpk(KEY_UP) or g.jpk(KEY_W)) and f.sel == 3:
		f.sel = 0
	if g.jpk(KEY_LEFT) or g.jpk(KEY_A):
		f.sel = (f.sel + 2) % 3 if f.sel < 3 else 0
	elif g.jpk(KEY_RIGHT) or g.jpk(KEY_D):
		f.sel = (f.sel + 1) % 3 if f.sel < 3 else 2
	if g.jpk(KEY_ESCAPE):
		close(g)
	elif g.jpk(KEY_ENTER) or g.jpk(KEY_KP_ENTER) or g.jpk(KEY_SPACE):
		confirm(g, f.sel)

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


static func confirm(g, i: int = 0) -> void:
	var f = g.forge
	g.bind(g.players[mini(int(f.idx), g.players.size() - 1)])
	var p = g.p
	if i == 3:
		salvage(g)
		return
	if p.weapons[1] == null or p.gold < COST:
		close(g)
		return
	var res: Dictionary = f.opts[clampi(i, 0, f.opts.size() - 1)]
	p.gold -= COST
	p.weapons = [res, null]
	p.wi = 0
	g.Meta.record("weapons", res.id)
	close(g)
	var names = []
	for t in [res.trait] + res.traits:
		if t != "":
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
	ci.draw_rect(g.full(), Color(0.02, 0.01, 0.05, 0.85))
	Px.ctext(ci, Vector2(240, 24), "WORD FORGE: CHOOSE A FUSION", Color("ffd24a"), 2)
	Px.ctext(ci, Vector2(240, 40), "BOTH WEAPONS MELT INTO THE ONE YOU PICK. %d GOLD." % COST, Color("d9d4c7"))
	for i in f.opts.size():
		var w: Dictionary = f.opts[i]
		var r = card_rect(i)
		var on: bool = i == f.sel
		Hud.panel(ci, r, Color(0.12, 0.08, 0.2, 0.97) if on else Color(0.07, 0.05, 0.12, 0.95), Color("ffd24a") if on else D.RAR_COL[int(D.WEAPONS[w.id].rar)])
		var t: Texture2D = Art.T[Art.wtex(w)]
		var sc = 2.0 if t.get_height() <= 9 else 1.0
		ci.draw_texture_rect(t, Rect2((r.position + Vector2(r.size.x / 2.0, 14) - t.get_size() * sc / 2.0).round(), t.get_size() * sc), false)
		Px.text(ci, r.position + Vector2(4, 4), str(i + 1), Color("ffd24a") if on else Color("6b6779"))
		var mech: String = w.traits[0]
		Px.ctext(ci, r.position + Vector2(r.size.x / 2.0, 28), " + ".join(w.traits.map(func(t): return Arms.TRAIT_NAME[t])), Color("ffd24a") if w.traits.size() == 1 else Color("ff9ee0"))
		g.Counter.draw_fit(g, ci, Vector2(r.position.x + r.size.x / 2.0, r.end.y - 10.0), w.traits)
		var y = r.position.y + 38.0
		for l in g.Ext.wcard(g, w, g.p.weapons[g.p.wi], 24):
			if y > r.end.y - 18.0:
				break
			Px.text(ci, Vector2(r.position.x + 4, y), l[0], l[1])
			y += 9.0
	var how = "TAP A CARD TO FORGE IT" if g.tin.on else ("D-PAD TO CHOOSE (DOWN: SALVAGE), A TO FORGE, B TO LEAVE" if g.p1_pad else "1 2 3 OR CLICK TO FORGE, 4 TO SALVAGE, ESC TO LEAVE")
	var son = f.sel == 3
	var taken = f.it != null and f.it.get("salv", false)
	Hud.panel(ci, SALVAGE, Color(0.12, 0.08, 0.2, 0.97) if son else Color(0.07, 0.05, 0.12, 0.95), Color("ffd24a") if son else Color("6b6779"))
	Px.ctext(ci, SALVAGE.position + Vector2(SALVAGE.size.x / 2.0, 3), "4  SALVAGE: KEEP BOTH, TAKE MATERIALS" if not taken else "SALVAGE TAKEN AT THIS FORGE", Color("d9d4c7") if not taken else Color("6b6779"))
	Px.ctext(ci, Vector2(240, 242), how, Color("6b6779"))
