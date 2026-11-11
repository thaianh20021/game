extends RefCounted
# The alchemy notebook. Nothing is listed until the player has made it happen once;
# every discovery is written down, pays a few gems, and can be renamed at the Archive.
# The player's own names are then used everywhere in the game.

const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")

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
	"cata": ["CATACLYSM", "ALL FOUR ELEMENTS. CLEARS THE SCREEN."],
	"e_ice": ["FROZEN GROUND", "ICE HARDENS MIRE AND BRIDGES PITS."],
	"e_fire": ["BRUSHFIRE", "FIRE BURNS CRATES AND WALKS THROUGH BRUSH."],
	"e_bolt": ["LIVE WATER", "LIGHTNING RUNS THROUGH A WHOLE MIRE."],
	"e_tox": ["CORROSION", "VENOM EATS CRACKED WALLS."],
	"hijack": ["HIJACK", "AN ENEMY POOL HIT BY ANOTHER ELEMENT IS YOURS."],
	"r_fire": ["ERUPTION", "FIRE FIVE TIMES ON ONE FOE."],
	"r_ice": ["GLACIER", "ICE FIVE TIMES ON ONE FOE."],
	"r_bolt": ["THUNDERSTRIKE", "STORM FIVE TIMES ON ONE FOE."],
	"r_tox": ["BLOOM", "VENOM FIVE TIMES ON ONE FOE."],
}
const PAGE = 7

static func known(key: String) -> bool:
	return Meta.S.book.has(key)

static func name(key: String) -> String:
	var custom = str(Meta.S.book.get(key, ""))
	return custom if custom != "" else DEF[key][0]

# What to print where a name would be a spoiler.
static func shown(key: String) -> String:
	return name(key) if known(key) else "???"

# Called whenever something on the list happens. Returns its name.
static func find(g, key: String) -> String:
	if not known(key) and not g.in_lobby:
		Meta.S.book[key] = ""
		Meta.S.gems += 3
		g.label(g.p.pos + Vector2(0, -34), "NEW NOTE %d/%d: %s  +3 GEMS" % [Meta.S.book.size(), DEF.size(), DEF[key][0]], Color("ffd24a"), true)
		g.tip("book", "WRITTEN IN YOUR NOTEBOOK", "RENAME YOUR DISCOVERIES AT THE ARCHIVE")
		Sfx.play("chest", 1.3, -4.0)
	return name(key)

static func rows(g) -> Array:
	var keys = DEF.keys()
	var pages = int(ceil(keys.size() / float(PAGE)))
	g.book_page = clampi(g.book_page, 0, pages - 1)
	var out = []
	for i in range(g.book_page * PAGE, mini(keys.size(), (g.book_page + 1) * PAGE)):
		var key: String = keys[i]
		if known(key):
			out.append({name = name(key), desc = DEF[key][1], cost = 0, state = "owned", tag = "RENAME", fn = func(): g.pending_say = key})
		else:
			out.append({name = "???", desc = "NOT DISCOVERED YET", cost = 0, state = "locked", tag = "", fn = func(): pass})
	out.append({name = "PAGE %d OF %d" % [g.book_page + 1, pages], desc = "%d OF %d NOTES WRITTEN" % [Meta.S.book.size(), keys.size()], cost = 0, state = "owned", tag = "NEXT",
		fn = func():
			g.book_page = (g.book_page + 1) % pages
			g.menu_next = "book"})
	return out
