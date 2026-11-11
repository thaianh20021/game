extends RefCounted
# The alchemy notebook. Nothing is listed until the player has made it happen once;
# every discovery is written down, pays a few gems, and can be renamed at the Archive.
# The player's own names are then used everywhere in the game.
# Keys: "a+b" a field, "s_<storm key>" a storm, "cata", "e_*" room chemistry, "hijack",
# "r_<el>" a resonance burst. Fields and storms of the new elements come from chem.gd.

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")
const Chem = preload("res://src/chem.gd")

# key -> [default name, what it does]
const DEF = {
	"fire+ice": ["STEAM", "FIRE + ICE. SWALLOWS ENEMY BULLETS."],
	"fire+tox": ["WILDFIRE", "FIRE + VENOM. BURNS HARD."],
	"bolt+fire": ["PLASMA", "STORM + FIRE. STUNS."],
	"bolt+ice": ["HAIL", "STORM + ICE. CHILLS AND CUTS."],
	"ice+tox": ["ROT", "ICE + VENOM. FOES TAKE +50% DAMAGE."],
	"bolt+tox": ["MIASMA", "STORM + VENOM. POISONS EVERYTHING INSIDE."],
	"s_tox": ["THUNDERSTORM", "FIRE + ICE + STORM. LIGHTNING HUNTS FOES."],
	"s_bolt": ["ACID RAIN", "FIRE + ICE + VENOM. MELTS HEALTH."],
	"s_ice": ["FIRESTORM", "FIRE + STORM + VENOM. ROLLING EXPLOSIONS."],
	"s_fire": ["BLIZZARD", "ICE + STORM + VENOM. FREEZES AND EATS BULLETS."],
	"cata": ["CATACLYSM", "FOUR ELEMENTS IN ONE PLACE. CLEARS THE SCREEN."],
	"e_ice": ["FROZEN GROUND", "ICE HARDENS MIRE AND BRIDGES PITS."],
	"e_fire": ["BRUSHFIRE", "FIRE BURNS CRATES AND WALKS THROUGH BRUSH."],
	"e_bolt": ["LIVE WATER", "LIGHTNING RUNS THROUGH A WHOLE MIRE."],
	"e_tox": ["CORROSION", "VENOM EATS CRACKED WALLS."],
	"e_stone": ["RUBBLE", "STONE FILLS PITS."],
	"e_earth": ["LANDFILL", "EARTH FILLS PITS AND FIRMS UP MIRE."],
	"e_water": ["FLOOD", "WATER FLOODS PITS INTO MIRE AND PUTS OUT FIRE."],
	"e_leaf": ["OVERGROWTH", "LEAF TURNS MIRE INTO DRY BRUSH."],
	"e_wood": ["FOOTBRIDGE", "WOOD LAYS PLANKS ACROSS PITS."],
	"e_metal": ["CLEAN CUT", "METAL CUTS CRATES AND CRACKED WALLS."],
	"e_mech": ["SABOTAGE", "GEARS JAM TRAPS FOR GOOD."],
	"hijack": ["HIJACK", "AN ENEMY POOL HIT BY ANOTHER ELEMENT IS YOURS."],
	"r_fire": ["ERUPTION", "FIRE FIVE TIMES ON ONE FOE."],
	"r_ice": ["GLACIER", "ICE FIVE TIMES ON ONE FOE."],
	"r_bolt": ["THUNDERSTRIKE", "STORM FIVE TIMES ON ONE FOE."],
	"r_tox": ["BLOOM", "VENOM FIVE TIMES ON ONE FOE."],
	"r_stone": ["LANDSLIDE", "STONE FIVE TIMES ON ONE FOE."],
	"r_wind": ["CYCLONE", "WIND FIVE TIMES ON ONE FOE."],
	"r_light": ["SUNFLARE", "LIGHT FIVE TIMES ON ONE FOE."],
	"r_void": ["IMPLOSION", "VOID FIVE TIMES ON ONE FOE."],
}
const PAGE = 7

static func default_name(key: String) -> String:
	if DEF.has(key):
		return DEF[key][0]
	if key.begins_with("s_"):
		return Chem.storm_name(key.substr(2))
	return Chem.field_name(key)

static func note(key: String) -> String:
	if DEF.has(key):
		return DEF[key][1]
	if key.begins_with("s_"):
		return Chem.storm_note(key.substr(2))
	return Chem.field_note(key)

static func known(key: String) -> bool:
	return Meta.S.book.has(key)

static func name(key: String) -> String:
	var custom = str(Meta.S.book.get(key, ""))
	return custom if custom != "" else default_name(key)

# What to print where a name would be a spoiler.
static func shown(key: String) -> String:
	return name(key) if known(key) else "???"

# Everything the notebook can hold a page for: the fixed entries, every field, and the
# generated storms found so far (there are 52 of those; unknown ones are not listed).
static func keys() -> Array:
	var out = DEF.keys()
	for k in Chem.pair_keys():
		if not out.has(k):
			out.append(k)
	for k in Meta.S.book:
		if not out.has(k):
			out.append(k)
	return out

static func total() -> int:
	return DEF.size() + 22 + 52

# Called whenever something on the list happens. Returns its name.
static func find(g, key: String) -> String:
	if not known(key) and not g.in_lobby:
		Meta.S.book[key] = ""
		Meta.S.gems += 3
		g.label(g.p.pos + Vector2(0, -34), "NEW NOTE %d/%d: %s  +3 GEMS" % [Meta.S.book.size(), total(), default_name(key)], Color("ffd24a"), true)
		g.tip("book", "WRITTEN IN YOUR NOTEBOOK", "RENAME YOUR DISCOVERIES AT THE ARCHIVE")
		Sfx.play("chest", 1.3, -4.0)
	return name(key)

static func rows(g) -> Array:
	var ks = keys()
	var pages = int(ceil(ks.size() / float(PAGE)))
	g.book_page = clampi(g.book_page, 0, pages - 1)
	var out = []
	for i in range(g.book_page * PAGE, mini(ks.size(), (g.book_page + 1) * PAGE)):
		var key: String = ks[i]
		if known(key):
			out.append({name = name(key), desc = note(key), cost = 0, state = "owned", tag = "RENAME", fn = func(): g.pending_say = key})
		else:
			out.append({name = "???", desc = "NOT DISCOVERED YET", cost = 0, state = "locked", tag = "", fn = func(): pass})
	out.append({name = "PAGE %d OF %d" % [g.book_page + 1, pages], desc = "%d OF %d NOTES WRITTEN" % [Meta.S.book.size(), total()], cost = 0, state = "owned", tag = "NEXT",
		fn = func():
			g.book_page = (g.book_page + 1) % pages
			g.menu_next = "book"})
	return out
