extends RefCounted
# Words as rewards. Two uses of typed commands (English or Vietnamese, accents optional):
#   1. On the blessing screen you may type a wish instead of taking one of the three
#      offers: "more health", "xuyen", "hoi sinh" ... grants the matching blessing.
#   2. At the Mentor you can name skill one and shape it with words:
#      an element word locks its element, "big/rong" widens it, "fast/nhanh" shortens the
#      cooldown, "strong/manh" hits harder. Every gain has a price.

const D = preload("res://src/data.gd")
const Px = preload("res://src/font.gd")
const Sfx = preload("res://src/sfx.gd")
const Forge = preload("res://src/forge.gd")
const Meta = preload("res://src/meta.gd")

const MAXLEN = 28
const BUFF_WORDS = {
	"vital": ["health", "heart", "hp", "life", "mau", "tim", "song"],
	"plating": ["armor", "armour", "shield", "giap", "khien"],
	"battery": ["energy", "mana", "battery", "pin", "nang", "luong"],
	"catalyst": ["reaction", "react", "catalyst", "phan", "ung"],
	"linger": ["long", "longer", "last", "linger", "lau", "dai"],
	"crit": ["crit", "critical", "lucky", "luck", "chi", "mang", "may"],
	"bounce": ["bounce", "ricochet", "nay", "bat"],
	"pierce": ["pierce", "sharp", "through", "xuyen"],
	"swift": ["fast", "speed", "quick", "swift", "nhanh", "toc"],
	"vamp": ["vampire", "steal", "siphon", "hut"],
	"free": ["free", "save", "cheap", "mien", "phi", "re"],
	"cond": ["spread", "contagion", "infect", "lay"],
	"fury": ["damage", "strong", "power", "fury", "manh", "dame"],
	"magnet": ["magnet", "gold", "loot", "rich", "vang", "giau"],
	"thorns": ["thorn", "thorns", "spite", "revenge", "gai", "tra"],
	"pack": ["pet", "pack", "beast", "thu"],
	"wind2": ["revive", "second", "again", "hoi", "sinh"],
	"surge": ["burst", "resonance", "surge", "bung"],
}
const SHAPE_WORDS = {
	"big": ["big", "wide", "huge", "area", "rong", "lon", "~to"],
	"fast": ["fast", "quick", "often", "nhanh", "lien"],
	"strong": ["strong", "power", "deadly", "heavy", "manh", "nang~"],
}

static func wish_buff(text: String) -> String:
	for word in text.to_lower().split(" ", false):
		var f = Forge.fold(word)
		for id in BUFF_WORDS:
			if BUFF_WORDS[id].has(f):
				return id
	return ""

static func buff_name(id: String) -> String:
	for b in D.BUFFS:
		if b.id == id:
			return b.name
	return id

static func key_input(g, ev: InputEventKey) -> void:
	if ev.keycode == KEY_BACKSPACE:
		if g.say != "":
			g.say = g.say.substr(0, g.say.length() - 1)
	elif ev.unicode >= 32 and ev.unicode != 127 and g.say.length() < MAXLEN:
		# digits pick an offer while nothing has been typed yet
		if g.state == "buff" and g.say == "" and ev.unicode >= 48 and ev.unicode <= 57:
			return
		g.say += char(ev.unicode)

# ---- blessing screen -------------------------------------------------------------

static func draw_buff_line(g, ci: CanvasItem, Hud) -> void:
	Hud.panel(ci, Rect2(110, 206, 260, 16), Color(0.02, 0.01, 0.05, 1.0), Color("7adfff"))
	var id = wish_buff(g.say)
	if g.say == "":
		Px.text(ci, Vector2(116, 211), "OR TYPE A WISH: HEALTH, XUYEN, HOI SINH...", Color("6b6779"))
	else:
		Px.text(ci, Vector2(116, 211), Forge.fold(g.say).to_upper() + ("_" if int(g.time * 3.0) % 2 == 0 else ""), Color.WHITE)
	if id != "":
		Px.ctext(ci, Vector2(240, 228), "ENTER: THE CORE GRANTS " + buff_name(id), Color("ffd24a"))
	elif g.say != "":
		Px.ctext(ci, Vector2(240, 228), "THE CORE DOES NOT UNDERSTAND", Color("ff6a6a"))

# ---- naming a skill --------------------------------------------------------------

static func parse_skill(text: String) -> Dictionary:
	var m = {name = Forge.fold(text).to_upper().strip_edges().substr(0, 16), el = "", area = 1.0, cdm = 1.0, dmg = 1.0, notes = []}
	for word in text.to_lower().split(" ", false):
		var f = Forge.fold(word)
		var accented = f != word
		for el in Forge.ELEMENTS:
			if m.el == "" and Forge.ELEMENTS[el].has(f):
				m.el = el
		for k in SHAPE_WORDS:
			if not (SHAPE_WORDS[k].has(f) or (accented and (SHAPE_WORDS[k].has("~" + f) or SHAPE_WORDS[k].has(f + "~")))) or m.notes.has(k):
				continue
			m.notes.append(k)
			match k:
				"big":
					m.area *= 1.25
					m.cdm *= 1.15
				"fast":
					m.cdm *= 0.75
					m.dmg *= 0.85
				"strong":
					m.dmg *= 1.3
					m.cdm *= 1.2
	return m

static func open_skill(g) -> void:
	g.say = ""
	g.say_mode = ""
	g.set_state("say")
	Sfx.play("ui")
	if g.tin.on:
		DisplayServer.virtual_keyboard_show("")

static func update_say(g) -> void:
	if g.state_t < 0.15:
		return
	if g.say_mode != "":
		# naming a notebook entry
		if g.jpk(KEY_ESCAPE) or g.jpk(KEY_ENTER) or g.jpk(KEY_KP_ENTER):
			if not g.jpk(KEY_ESCAPE):
				Meta.S.book[g.say_mode] = clean(g.say)
				Meta.save()
				Sfx.play("chest")
			g.say_mode = ""
			g.open_menu("book")
		return
	if g.jpk(KEY_ESCAPE):
		g.set_state("play")
	elif g.jpk(KEY_ENTER) or g.jpk(KEY_KP_ENTER):
		if g.say.strip_edges() == "":
			Meta.S.skillmod.erase(g.p.hkey)
		else:
			var m = parse_skill(g.say)
			m.erase("notes")
			Meta.S.skillmod[g.p.hkey] = m
		Meta.save()
		g.set_state("play")
		g.Lobby.refresh_player(g)
		Sfx.play("chest")
		g.flash(g.pcenter(), 120.0, Color("7adfff"), 0.4)
		g.banner = {text = g.skill_name(0), sub = "YOUR SKILL, YOUR WORDS", t = 3.0}
	if g.state != "say" and g.tin.on:
		DisplayServer.virtual_keyboard_hide()

# Capitals, digits and spaces only (the pixel font has nothing else), at most 14 long.
static func clean(text: String) -> String:
	var out = ""
	for ch in Forge.fold(text).to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == " ":
			out += ch
	return out.strip_edges().substr(0, 14)

static func draw_say(g, ci: CanvasItem, Hud) -> void:
	ci.draw_rect(Rect2(0, 0, 480, 270), Color(0.02, 0.01, 0.05, 0.78))
	if g.say_mode != "":
		var def = g.Book.DEF[g.say_mode]
		Hud.panel(ci, Rect2(70, 70, 340, 110), Color(0.07, 0.05, 0.12, 0.97), Color("ffd24a"))
		Px.ctext(ci, Vector2(240, 78), "NAME THIS DISCOVERY", Color("ffd24a"), 2)
		Px.ctext(ci, Vector2(240, 102), def[1], Color("a8a7b8"))
		Hud.panel(ci, Rect2(100, 116, 280, 18), Color(0.02, 0.01, 0.05, 1.0), Color("ffd24a"))
		Px.text(ci, Vector2(106, 122), clean(g.say) + ("_" if int(g.time * 3.0) % 2 == 0 else ""), Color.WHITE)
		Px.ctext(ci, Vector2(240, 144), "IT IS CALLED " + g.Book.name(g.say_mode) + " NOW. EMPTY RESTORES " + def[0] + ".", Color("6b6779"))
		Px.ctext(ci, Vector2(240, 162), "ENTER: WRITE IT DOWN     ESC: CANCEL", Color("d9d4c7"))
		return
	Hud.panel(ci, Rect2(70, 60, 340, 150), Color(0.07, 0.05, 0.12, 0.97), Color("7adfff"))
	Px.ctext(ci, Vector2(240, 68), "NAME YOUR SKILL", Color("7adfff"), 2)
	Px.ctext(ci, Vector2(240, 92), "IT REPLACES: " + D.SKILLS[g.p.skills[0]].name, Color("6b6779"))
	Hud.panel(ci, Rect2(100, 104, 280, 18), Color(0.02, 0.01, 0.05, 1.0), Color("7adfff"))
	Px.text(ci, Vector2(106, 110), Forge.fold(g.say).to_upper() + ("_" if int(g.time * 3.0) % 2 == 0 else ""), Color.WHITE)
	var m = parse_skill(g.say)
	var y = 130
	if m.el != "":
		ci.draw_texture(g.Art.T["ic_" + m.el], Vector2(106, y - 2))
		Px.text(ci, Vector2(118, y), "ALWAYS " + D.EL_NAME[m.el], D.EL_COL[m.el])
		y += 11
	for k in m.notes:
		Px.text(ci, Vector2(106, y), {"big": "WIDER AREA, SLOWER RECHARGE", "fast": "QUICKER RECHARGE, LESS DAMAGE", "strong": "MORE DAMAGE, SLOWER RECHARGE"}[k], Color("ffd24a"))
		y += 11
	if m.el == "" and m.notes.is_empty():
		Px.text(ci, Vector2(106, y), "WORDS LIKE FIRE, BIG, FAST, STRONG / LUA, RONG, NHANH, MANH SHAPE IT", Color("6b6779"))
	Px.ctext(ci, Vector2(240, 180), "TRY: FROST COMET BIG   /   BAO LUA MANH", Color("6b6779"))
	Px.ctext(ci, Vector2(240, 194), "ENTER: KEEP    EMPTY + ENTER: RESET    ESC: CANCEL", Color("ffd24a"))
