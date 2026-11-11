extends RefCounted
# All tunable game content: elements, weapons, heroes, enemies, biomes, buffs.

# The four old elements: foes, traps and barrels use only these.
const EL = ["fire", "ice", "bolt", "tox"]
# The newer ones, painted only by heroes. chem.gd builds their reactions.
const EL2 = ["stone", "wind", "light", "void", "water", "leaf", "earth", "metal", "wood", "mech", "x"]
const ALL = ["fire", "ice", "bolt", "tox", "stone", "wind", "light", "void", "water", "leaf", "earth", "metal", "wood", "mech", "x"]
const EL_NAME = {"": "NEUTRAL", "fire": "FIRE", "ice": "ICE", "bolt": "STORM", "tox": "VENOM", "prism": "PRISM",
	"stone": "STONE", "wind": "WIND", "light": "LIGHT", "void": "VOID",
	"water": "WATER", "leaf": "LEAF", "earth": "EARTH", "metal": "METAL", "wood": "WOOD", "mech": "GEAR", "x": "X"}
const EL_PREFIX = {"": "", "fire": "EMBER ", "ice": "FROST ", "bolt": "STORM ", "tox": "VENOM ", "prism": "PRISM ",
	"stone": "STONE ", "wind": "WIND ", "light": "LIGHT ", "void": "VOID ",
	"water": "TIDE ", "leaf": "LEAF ", "earth": "EARTH ", "metal": "IRON ", "wood": "TIMBER ", "mech": "GEAR ", "x": "X "}

static var EL_COL = {
	"": Color("f1ead8"), "fire": Color("ff8a3a"), "ice": Color("7adfff"),
	"bolt": Color("ffe45c"), "tox": Color("a6e84e"), "prism": Color("e58cff"),
	"stone": Color("c99b5c"), "wind": Color("b8f0d0"), "light": Color("fff2ae"), "void": Color("9352cb"),
	"water": Color("4aa8ff"), "leaf": Color("6fd66a"), "earth": Color("b5562f"), "metal": Color("b8c8d8"),
	"wood": Color("8f6a34"), "mech": Color("e0b040"), "x": Color("ff5fb0"),
}

# Mana. Each of the three carried elements has its own pool (a third of the hero's max mana).
# Painting drains the chosen one ("drain" seconds of steady fire at 160 max mana), resting
# ones refill in "rest" seconds, the chosen one in "idle" when not firing. An empty pool
# paints nothing until it is back above "back". A reaction takes "react" of both pools, the
# element that completes a three-element effect pays "storm", a gathered cast (hold the
# element key for "charge" seconds) pays "cast". Costs shrink as max mana grows.
# Close weapons are the way to earn mana back: painting with one drains at "melee" of the
# rate, and each strike that lands gives "strike" to both resting pools (up to three foes).
const SAT = {drain = 7.0, rest = 4.0, idle = 9.0, back = 0.35, react = 0.15, storm = 0.35, cast = 0.4, charge = 0.8, base = 160.0, melee = 0.5, strike = 0.06}
# seconds a foe cannot be stunned, frozen or rooted again after it gets free
const CC_FREE = 1.5
# reaction fields that may lie on the floor at once; only one three-element effect exists at a time
const FIELDS_MAX = 3

# reaction key = the two elements sorted and joined with "+"
static var REACT = {
	"fire+ice": ["MELT", Color("d8f6ff")],
	"fire+tox": ["BLAST", Color("ffb347")],
	"bolt+fire": ["OVERLOAD", Color("ff7ad9")],
	"bolt+ice": ["SHATTER", Color("b8c8ff")],
	"ice+tox": ["BLIGHT", Color("6fe0b0")],
	"bolt+tox": ["PLAGUE", Color("d4f04a")],
	# pairs with a new element: effects are generated in chem.gd from the two aspects
	"bolt+light": ["FLARE", Color("fff7c2")],
	"bolt+stone": ["MAGNET", Color("d9b36a")],
	"bolt+void": ["RIFT", Color("c58cff")],
	"bolt+wind": ["TEMPEST", Color("d8f7a0")],
	"fire+light": ["SUNBURST", Color("ffd98a")],
	"fire+stone": ["MAGMA", Color("ff7a3a")],
	"fire+void": ["HELLFIRE", Color("d9506a")],
	"fire+wind": ["FIREWHIRL", Color("ffb05a")],
	"ice+light": ["AURORA", Color("c8fff0")],
	"ice+stone": ["FROSTROCK", Color("a8c8d8")],
	"ice+void": ["DEEP COLD", Color("8a9cff")],
	"ice+wind": ["WHITEOUT", Color("e0f6ff")],
	"light+stone": ["CRYSTAL", Color("f0e0b0")],
	"light+tox": ["PURGE", Color("e0ff9a")],
	"light+void": ["ECLIPSE", Color("b8a0e0")],
	"light+wind": ["MIRAGE", Color("f0ffd8")],
	"stone+tox": ["TAR", Color("8a9a4a")],
	"stone+void": ["GRAVITY", Color("a070b0")],
	"stone+wind": ["SANDSTORM", Color("e0c890")],
	"tox+void": ["DECAY", Color("9a70c0")],
	"tox+wind": ["SPORES", Color("c0f080")],
	"void+wind": ["VACUUM", Color("b0a0f0")],
	# pairs with the seven newest elements
	"bolt+earth": ["GROUNDING", Color("e3b573")],
	"bolt+leaf": ["SPARKLEAF", Color("c9e58a")],
	"bolt+mech": ["OVERCLOCK", Color("f3d77a")],
	"bolt+metal": ["CONDUCTOR", Color("e4e0b3")],
	"bolt+water": ["LIVE TIDE", Color("bbd4c1")],
	"bolt+wood": ["SPLINTER", Color("d5bd75")],
	"bolt+x": ["GLITCH", Color("ffb8a4")],
	"earth+fire": ["KILN", Color("e39367")],
	"earth+ice": ["PERMAFROST", Color("b1b3b1")],
	"earth+leaf": ["MEADOW", Color("adb079")],
	"earth+light": ["HARVEST", Color("e3ba92")],
	"earth+mech": ["EXCAVATE", Color("d7a269")],
	"earth+metal": ["ORE VEIN", Color("c8aba2")],
	"earth+stone": ["BEDROCK", Color("cf9a73")],
	"earth+tox": ["FALLOW", Color("c1b76e")],
	"earth+void": ["SINKHOLE", Color("ba7e9d")],
	"earth+water": ["MUDSLIDE", Color("9f9fb1")],
	"earth+wind": ["DUSTBOWL", Color("c8ba9f")],
	"earth+wood": ["ROOTBED", Color("b98764")],
	"earth+x": ["FAULTLINE", Color("e38393")],
	"fire+leaf": ["ASHFALL", Color("c9c37d")],
	"fire+mech": ["FURNACE", Color("f3b56d")],
	"fire+metal": ["SLAG", Color("e4bea6")],
	"fire+water": ["GEYSER", Color("bbb2b5")],
	"fire+wood": ["BONFIRE", Color("d59b69")],
	"fire+x": ["NOVA", Color("ff9797")],
	"ice+leaf": ["HOARFROST", Color("97e3c7")],
	"ice+mech": ["JAMMED", Color("c1d5b7")],
	"ice+metal": ["BRITTLE", Color("b2def0")],
	"ice+water": ["ICEBERG", Color("89d2ff")],
	"ice+wood": ["FROSTBARK", Color("a3bbb2")],
	"ice+x": ["ABSOLUTE", Color("cdb7e1")],
	"leaf+light": ["BLOSSOM", Color("c9eaa8")],
	"leaf+mech": ["GRAFT", Color("bdd27f")],
	"leaf+metal": ["RAZORLEAF", Color("aedbb8")],
	"leaf+stone": ["LICHEN", Color("b4ca8a")],
	"leaf+tox": ["NETTLE", Color("a7e784")],
	"leaf+void": ["WITHER", Color("a0aeb3")],
	"leaf+water": ["LOTUS", Color("85cfc7")],
	"leaf+wind": ["PETALSTORM", Color("aeeab5")],
	"leaf+wood": ["CANOPY", Color("9fb77b")],
	"leaf+x": ["MUTATION", Color("c9b3a9")],
	"light+mech": ["BEACON", Color("f3dc99")],
	"light+metal": ["MIRROR", Color("e4e5d2")],
	"light+water": ["RAINBOW", Color("bbd9e0")],
	"light+wood": ["SUNDIAL", Color("d5c294")],
	"light+x": ["HALO", Color("ffbec3")],
	"mech+metal": ["PISTON", Color("d8cca8")],
	"mech+stone": ["GRINDER", Color("dfbb7a")],
	"mech+tox": ["EXHAUST", Color("d2d875")],
	"mech+void": ["DARK ENGINE", Color("caa0a3")],
	"mech+water": ["TURBINE", Color("afc0b7")],
	"mech+wind": ["WINDMILL", Color("d8dba5")],
	"mech+wood": ["CATAPULT", Color("c9a96b")],
	"mech+x": ["ANOMALY", Color("f3a599")],
	"metal+stone": ["ANVIL", Color("d0c4b3")],
	"metal+tox": ["RUST", Color("c3e1ae")],
	"metal+void": ["BLACK IRON", Color("bba9dc")],
	"metal+water": ["QUENCH", Color("a0c9f0")],
	"metal+wind": ["SHRAPNEL", Color("c9e4de")],
	"metal+wood": ["HATCHET", Color("bab2a4")],
	"metal+x": ["ALLOY", Color("e4aed2")],
	"stone+water": ["EROSION", Color("a6b8c1")],
	"stone+wood": ["PETRIFY", Color("c0a175")],
	"stone+x": ["MONOLITH", Color("ea9da4")],
	"tox+water": ["SWAMP", Color("99d5bc")],
	"tox+wood": ["FUNGUS", Color("b3be70")],
	"tox+x": ["PANDEMIC", Color("ddba9f")],
	"void+water": ["ABYSS", Color("929deb")],
	"void+wood": ["DEADWOOD", Color("ac869f")],
	"void+x": ["OBLIVION", Color("d682cd")],
	"water+wind": ["MONSOON", Color("a0d8ed")],
	"water+wood": ["DRIFTWOOD", Color("91a6b2")],
	"water+x": ["MAELSTROM", Color("bba2e1")],
	"wind+wood": ["SAWDUST", Color("bac1a1")],
	"wind+x": ["JETSTREAM", Color("e4bdcf")],
	"wood+x": ["HEARTWOOD", Color("d58b95")],
}

static var RAR_COL = [Color("d9d4c7"), Color("6fb7ff"), Color("ffb84a")]

const WEAPONS = {
	"pistol": {name = "SPARK HORN", spr = "pistol", type = "bullet", dmg = 4.0, cd = 0.28, cost = 0.0, speed = 270.0, spread = 0.04, rar = 0},
	"kunai": {name = "THORN DART", spr = "kunai", type = "bullet", dmg = 3.5, cd = 0.19, cost = 0.0, speed = 320.0, spread = 0.03, kind = "arrow", rar = 0},
	"blade": {name = "FANG BLADE", spr = "blade", type = "melee", dmg = 9.0, cd = 0.36, cost = 0.0, range = 30.0, arc = 2.4, rar = 0},
	"wand": {name = "WISP ROD", spr = "staff", type = "bullet", dmg = 6.0, cd = 0.42, cost = 0.0, speed = 210.0, aoe = 16.0, r = 3, rar = 0},
	"bow": {name = "SINEW BOW", spr = "bow", type = "bullet", dmg = 7.0, cd = 0.46, cost = 0.0, speed = 330.0, pierce = 1, kind = "arrow", rar = 0},
	"flask": {name = "GOURD", spr = "flask", type = "lob", dmg = 6.0, cd = 0.55, cost = 0.0, range = 130.0, aoe = 20.0, puddle = true, rar = 0},
	"axe": {name = "CLEAVER", spr = "axe", type = "melee", dmg = 12.0, cd = 0.5, cost = 0.0, range = 32.0, arc = 2.8, rar = 0},
	"crossbow": {name = "TRIPLE REED", spr = "crossbow", type = "bullet", dmg = 5.0, cd = 0.5, cost = 0.0, speed = 340.0, n = 3, fan = 0.16, kind = "arrow", rar = 0},
	"boomerang": {name = "WISHBONE", spr = "boomerang", type = "bullet", dmg = 6.0, cd = 0.6, cost = 0.0, speed = 230.0, life = 1.1, pierce = 99, boomer = true, r = 3, rar = 0},
	"spear": {name = "STINGER", spr = "spear", type = "melee", dmg = 8.0, cd = 0.26, cost = 0.0, range = 48.0, arc = 0.7, rar = 0},
	"twins": {name = "CASTANETS", spr = "twins", type = "bullet", dmg = 3.2, cd = 0.2, cost = 0.6, speed = 280.0, n = 2, fan = 0.1, spread = 0.05, rar = 0},
	"hammer": {name = "BELL HAMMER", spr = "hammer", type = "melee", dmg = 18.0, cd = 0.75, cost = 1.5, range = 34.0, arc = 2.6, slam = 26.0, rar = 1},
	"chakram": {name = "HALO", spr = "chakram", type = "bullet", dmg = 5.0, cd = 0.4, cost = 1.5, speed = 260.0, bounce = 4, pierce = 2, r = 3, rar = 1},
	"grimoire": {name = "MOTH JAR", spr = "grimoire", type = "bullet", dmg = 4.5, cd = 0.34, cost = 1.6, speed = 170.0, homing = 4.0, life = 2.0, r = 3, rar = 1},
	"launcher": {name = "COMET HORN", spr = "launcher", type = "bullet", dmg = 14.0, cd = 0.95, cost = 5.0, speed = 210.0, aoe = 30.0, r = 3, rar = 2},
	# blueprint weapons: never found as loot, only crafted
	"stormcaller": {name = "TEMPEST FORK", spr = "coil", type = "chain", dmg = 8.0, cd = 0.36, cost = 2.5, range = 160.0, n = 6, rar = 2, bp = true, bpdesc = "LIGHTNING THAT JUMPS SIX TIMES"},
	"sunlance": {name = "DAWN LENS", spr = "lance", type = "beam", dmg = 2.6, cd = 0.06, cost = 0.6, range = 185.0, rar = 2, bp = true, bpdesc = "A LONGER, HOTTER BEAM"},
	"swarm": {name = "MOTH LANTERN", spr = "grimoire", type = "bullet", dmg = 3.6, cd = 0.3, cost = 2.0, speed = 180.0, homing = 5.0, life = 2.2, n = 3, fan = 0.7, r = 3, rar = 2, bp = true, bpdesc = "THREE SEEKING SHOTS AT ONCE"},
	"phoenix": {name = "PHOENIX BOW", spr = "bow", type = "bullet", dmg = 7.0, cd = 0.42, cost = 1.5, speed = 340.0, n = 3, fan = 0.2, pierce = 2, kind = "arrow", rar = 2, bp = true, bpdesc = "THREE PIERCING ARROWS"},
	"quake": {name = "QUAKE BELL", spr = "hammer", type = "melee", dmg = 22.0, cd = 0.7, cost = 2.0, range = 38.0, arc = 3.2, slam = 44.0, rar = 2, bp = true, bpdesc = "EVERY SWING SHAKES THE ROOM"},
	"voidring": {name = "VOID HALO", spr = "chakram", type = "bullet", dmg = 7.0, cd = 0.36, cost = 2.0, speed = 280.0, bounce = 8, pierce = 5, r = 3, rar = 2, bp = true, bpdesc = "BOUNCES EIGHT TIMES"},
	"scatter": {name = "SEED POD", spr = "shotgun", type = "bullet", dmg = 3.0, cd = 0.7, cost = 3.0, speed = 250.0, n = 6, fan = 0.55, spread = 0.05, life = 0.42, rar = 0},
	"needle": {name = "HORNET HIVE", spr = "smg", type = "bullet", dmg = 2.2, cd = 0.08, cost = 0.7, speed = 300.0, spread = 0.12, rar = 0},
	"repeater": {name = "RATTLE", spr = "smg", type = "bullet", dmg = 3.4, cd = 0.14, cost = 1.0, speed = 330.0, spread = 0.05, bounce = 1, rar = 1},
	"sprayer": {name = "CENSER", spr = "sprayer", type = "bullet", dmg = 1.6, cd = 0.05, cost = 0.45, speed = 175.0, spread = 0.26, life = 0.34, pierce = 99, kind = "flame", rar = 1},
	"coil": {name = "TUNING FORK", spr = "coil", type = "chain", dmg = 6.0, cd = 0.42, cost = 2.5, range = 135.0, n = 3, rar = 1},
	"mortar": {name = "WAR DRUM", spr = "mortar", type = "lob", dmg = 13.0, cd = 0.9, cost = 4.0, range = 150.0, aoe = 34.0, puddle = true, rar = 1},
	"greatblade": {name = "SLAB", spr = "greatblade", type = "melee", dmg = 16.0, cd = 0.55, cost = 1.0, range = 38.0, arc = 3.0, rar = 1},
	"beam": {name = "PRISM LENS", spr = "lance", type = "beam", dmg = 1.5, cd = 0.06, cost = 0.5, range = 140.0, rar = 2},
	"rail": {name = "OBELISK", spr = "railgun", type = "bullet", dmg = 20.0, cd = 0.85, cost = 4.0, speed = 560.0, pierce = 5, r = 3, kind = "arrow", rar = 2},
	"nova": {name = "STAR CHIME", spr = "starstaff", type = "bullet", dmg = 4.0, cd = 0.6, cost = 4.0, speed = 190.0, n = 10, fan = 5.6, pierce = 1, rar = 2},
}

const SKILLS = {
	"whirl": {name = "WHIRLWIND", cd = 7.0},
	"nova": {name = "ELEMENT NOVA", cd = 9.0},
	"volley": {name = "ARROW STORM", cd = 8.0},
	"blink": {name = "SHADOW STEP", cd = 5.0},
	"bulwark": {name = "BULWARK", cd = 11.0},
	"rift": {name = "RIFT", cd = 11.0},
	"mines": {name = "ELEMENT MINES", cd = 9.0},
	"knives": {name = "KNIFE FAN", cd = 7.0},
	"transmute": {name = "TRANSMUTE", cd = 9.0},
	"elixir": {name = "ELIXIR", cd = 12.0},
	"leap": {name = "SKY LEAP", cd = 6.0},
	"rage": {name = "BLOOD RAGE", cd = 13.0},
	"turret": {name = "SENTRY", cd = 10.0},
	"pulse": {name = "MAGNET PULSE", cd = 8.0},
	"vines": {name = "GRASPING VINES", cd = 9.0},
	"spirits": {name = "WILD SPIRITS", cd = 7.0},
}

# each element is weak to one other element
const WEAK = {"fire": "ice", "ice": "fire", "bolt": "tox", "tox": "bolt", "stone": "wind", "wind": "stone", "light": "void", "void": "light"}

const HEROES = [
	{id = "warden", name = "BRASSHEART", hp = 7, ar = 5, en = 160, start = "blade", start2 = "pistol", skill = "whirl", skill2 = "bulwark", skill_name = "WHIRLWIND", skill_cd = 7.0,
		desc = "A CLOCKWORK GUARDIAN WITH A FURNACE FOR A HEART. SPINS TO SHRED FOES AND SWAT BULLETS."},
	{id = "arcanist", name = "LANTERN", hp = 5, ar = 4, en = 240, start = "wand", start2 = "kunai", skill = "nova", skill2 = "rift", skill_name = "ELEMENT NOVA", skill_cd = 9.0,
		desc = "A WALKING LAMP IN A ROBE. FRAGILE, BUT ITS NOVA FLOODS THE ROOM WITH ITS ELEMENT."},
	{id = "ranger", name = "KESTREL", hp = 6, ar = 4, en = 190, start = "bow", start2 = "blade", skill = "volley", skill2 = "mines", skill_name = "ARROW STORM", skill_cd = 8.0,
		desc = "SHARP-EYED BIRD-FOLK. PIERCING SHOTS FROM AFAR AND THREE FANS OF ARROWS."},
	{id = "nightblade", name = "VEIL", hp = 5, ar = 5, en = 180, start = "kunai", start2 = "pistol", skill = "blink", skill2 = "knives", skill_name = "SHADOW STEP", skill_cd = 5.0,
		desc = "A MASKED FOX SPIRIT. STEPS THROUGH FOES, CUTTING ALL IN THE PATH."},
	{id = "alchemist", name = "CROAK", hp = 5, ar = 4, en = 220, start = "flask", start2 = "pistol", skill = "transmute", skill2 = "elixir", skill_name = "TRANSMUTE", skill_cd = 9.0,
		desc = "A TOAD BREWER. LOBS GOURDS AND TURNS ANY STATUS INTO A REACTION."},
	{id = "berserker", name = "RAMSKULL", hp = 8, ar = 3, en = 140, start = "axe", start2 = "kunai", skill = "leap", skill2 = "rage", skill_name = "SKY LEAP", skill_cd = 6.0,
		desc = "HORNED AND STUBBORN. ALL HEALTH, LITTLE ARMOR. LEAPS IN AND RAGES."},
	{id = "engineer", name = "RIVET", hp = 5, ar = 5, en = 200, start = "crossbow", start2 = "blade", skill = "turret", skill2 = "pulse", skill_name = "SENTRY", skill_cd = 10.0,
		desc = "A SMALL MACHINE THAT BUILDS BIGGER ONES. ITS PULSE STUNS FOES AND PULLS IN LOOT."},
	{id = "wildheart", name = "MOSSCAP", hp = 6, ar = 4, en = 190, start = "boomerang", start2 = "pistol", skill = "vines", skill2 = "spirits", skill_name = "GRASPING VINES", skill_cd = 9.0,
		desc = "A MUSHROOM THAT WALKS. ROOTS FOES IN PLACE AND SENDS SPIRITS THAT HUNT."},
]

# ai: chase bat shoot spread charge bomb turret blink boss
const ENEMIES = {
	"slime": {spr = "slime", hp = 14, spd = 38, ai = "chase", touch = 1, r = 5, cost = 1, squash = true},
	"bat": {spr = "bat", hp = 8, spd = 74, ai = "bat", touch = 1, r = 4, cost = 1, fly = true},
	"goblin": {spr = "goblin", hp = 16, spd = 44, ai = "shoot", rate = 1.7, bspd = 115, r = 5, cost = 2, walk = true},
	"boar": {spr = "boar", hp = 30, spd = 34, ai = "charge", touch = 2, r = 6, cost = 3, walk = true},
	"shroom": {spr = "shroom", hp = 24, spd = 16, ai = "spread", rate = 2.6, n = 8, bspd = 70, el = "tox", r = 6, cost = 3, squash = true},
	"imp": {spr = "imp", hp = 10, spd = 80, ai = "bomb", el = "fire", r = 4, cost = 2, walk = true},
	"magma": {spr = "slime", swap = {"n": "o", "l": "y", "N": "R"}, hp = 28, spd = 34, ai = "chase", touch = 1, el = "fire", r = 6, cost = 3, squash = true, child = "cinder", sc = 1.25},
	"cinder": {spr = "slime", swap = {"n": "o", "l": "y", "N": "R"}, hp = 8, spd = 58, ai = "chase", touch = 1, el = "fire", r = 4, cost = 1, squash = true, sc = 0.7},
	"pyro": {spr = "mage", swap = {"p": "r", "P": "R"}, hp = 22, spd = 26, ai = "spread", aimed = true, rate = 2.1, n = 3, bspd = 105, el = "fire", r = 5, cost = 3, fly = true},
	"guard": {spr = "guard", hp = 42, spd = 30, ai = "shoot", rate = 2.3, burst = 3, bspd = 125, r = 6, cost = 4, walk = true},
	"turret": {spr = "turret", hp = 30, spd = 0, ai = "turret", el = "bolt", r = 6, cost = 3},
	"wisp": {spr = "wisp", hp = 14, spd = 48, ai = "shoot", rate = 1.9, bspd = 100, el = "ice", r = 5, cost = 2, fly = true},
	"skel": {spr = "skel", hp = 34, spd = 46, ai = "charge", touch = 2, r = 5, cost = 3, walk = true},
	"necro": {spr = "mage", hp = 28, spd = 22, ai = "spread", spiral = true, rate = 2.8, n = 12, bspd = 75, el = "tox", r = 5, cost = 4, fly = true},
	"shade": {spr = "wisp", swap = {"c": "P", "C": "p", "w": "m"}, hp = 18, spd = 62, ai = "blink", touch = 1, r = 5, cost = 3, fly = true},
	"golem": {spr = "golem", name = "MOSSBACK COLOSSUS", hp = 520, spd = 24, ai = "boss", boss = 0, touch = 1, r = 14, sc = 2.0, cost = 0},
	"tyrant": {spr = "tyrant", name = "THE FORGE TYRANT", hp = 780, spd = 28, ai = "boss", boss = 1, touch = 1, el = "fire", r = 14, sc = 2.0, cost = 0},
	"lich": {spr = "lich", name = "KEEPER OF THE CORE", hp = 1050, spd = 30, ai = "boss", boss = 2, touch = 1, r = 14, sc = 2.0, cost = 0, fly = true},
	"queen": {spr = "queen_b", name = "THE BROOD QUEEN", hp = 560, spd = 20, ai = "boss", boss = 3, touch = 1, el = "tox", r = 14, sc = 2.0, cost = 0, squash = true},
	"iron": {spr = "iron_b", name = "IRON WARDEN MK II", hp = 820, spd = 24, ai = "boss", boss = 4, touch = 1, el = "bolt", r = 14, sc = 2.0, cost = 0},
	"void": {spr = "void_b", name = "THE HOLLOW SHADE", hp = 1000, spd = 34, ai = "boss", boss = 5, touch = 1, r = 14, sc = 2.0, cost = 0, fly = true},
	"rootking": {spr = "rootking_b", name = "THE ROOT KING", hp = 600, spd = 18, ai = "boss", boss = 6, touch = 1, r = 14, sc = 2.0, cost = 0},
	"wyrm": {spr = "wyrm_b", name = "THE CINDER WYRM", hp = 860, spd = 30, ai = "boss", boss = 7, touch = 1, el = "fire", r = 14, sc = 2.0, cost = 0},
	"sentinel": {spr = "sentinel_b", name = "THE PRISM SENTINEL", hp = 1100, spd = 22, ai = "boss", boss = 8, touch = 1, r = 14, sc = 2.0, cost = 0, fly = true},
	"dummy": {spr = "dummy", hp = 99999, spd = 0, ai = "dummy", r = 5, cost = 0},
}

static var BIOMES = [
	{name = "ANCIENT CAVE", roster = ["slime", "slime", "bat", "goblin", "boar", "shroom"], bosses = ["golem", "queen", "rootking"],
		ambient = Color(0.20, 0.20, 0.31), floor = [Color("57516a"), Color("4e4960"), Color("605a74")], grout = Color("38334a"),
		accent = Color("4f8a50"), face = [Color("8479a0"), Color("6a5f86"), Color("4a4263")], cap = Color("1b1726"), edge = Color("9d93b8")},
	{name = "EMBER FORGE", roster = ["imp", "magma", "pyro", "guard", "turret", "bat", "goblin"], bosses = ["tyrant", "iron", "wyrm"],
		ambient = Color(0.28, 0.18, 0.17), floor = [Color("5c4038"), Color("523931"), Color("684a40")], grout = Color("35211f"),
		accent = Color("ff8a2a"), face = [Color("98563f"), Color("7a4133"), Color("552b27")], cap = Color("1d1216"), edge = Color("c0704c")},
	{name = "CRYSTAL ARCHIVE", roster = ["wisp", "skel", "necro", "shade", "turret", "guard", "pyro"], bosses = ["lich", "void", "sentinel"],
		ambient = Color(0.17, 0.22, 0.34), floor = [Color("3b4c70"), Color("344364"), Color("44577e")], grout = Color("232d48"),
		accent = Color("7fe3ff"), face = [Color("6780b6"), Color("4d6194"), Color("35446c")], cap = Color("111626"), edge = Color("95afe0")},
]

const BUFFS = [
	{id = "vital", name = "IRON HEART", desc = "+2 MAX HEALTH AND HEAL 3"},
	{id = "plating", name = "RUNE PLATING", desc = "+2 MAX ARMOR"},
	{id = "battery", name = "DEEP CELL", desc = "+80 MAX MANA, FULL REFILL"},
	{id = "catalyst", name = "CATALYST", desc = "REACTIONS DEAL +60% DAMAGE"},
	{id = "linger", name = "LINGERING HEX", desc = "ELEMENT EFFECTS LAST 60% LONGER"},
	{id = "crit", name = "KEEN EYE", desc = "+15% CRITICAL CHANCE"},
	{id = "bounce", name = "RICOCHET", desc = "BULLETS BOUNCE OFF WALLS ONCE MORE"},
	{id = "pierce", name = "DRILL TIPS", desc = "BULLETS PIERCE ONE MORE ENEMY"},
	{id = "swift", name = "WINDSTEP", desc = "MOVE FASTER, DASH RECHARGES QUICKER"},
	{id = "vamp", name = "SOUL SIPHON", desc = "KILLS OFTEN RESTORE 1 ARMOR"},
	{id = "free", name = "RECYCLER", desc = "30% OF SHOTS COST NO MANA"},
	{id = "cond", name = "CONTAGION", desc = "SLAIN FOES PASS THEIR ELEMENT ON"},
	{id = "fury", name = "FURY", desc = "+20% ALL WEAPON DAMAGE"},
	{id = "magnet", name = "LODESTONE", desc = "PULL PICKUPS FROM AFAR, +30% GOLD"},
	{id = "thorns", name = "SPITE", desc = "WHEN HURT, BLAST NEARBY FOES"},
	{id = "pack", name = "PACK BOND", desc = "YOUR PET ATTACKS TWICE AS FAST"},
	{id = "wind2", name = "SECOND WIND", desc = "ONCE PER FLOOR, SURVIVE A FATAL HIT"},
	{id = "surge", name = "RESONANCE", desc = "BURST CHARGES 50% FASTER"},
]
const BOSS_ATKS = [3, 4, 4, 3, 4, 4, 3, 3, 3]

# ---- synergies: hidden bonuses for carrying the right combination ----------------
const SYNERGIES = [
	{id = "thunder", name = "THUNDER ARROW", desc = "ARROWS AND KUNAI ARC LIGHTNING TO A SECOND FOE"},
	{id = "wildfire", name = "WILDFIRE", desc = "BURNING FOES LEAVE A VENOM POOL WHEN THEY DIE"},
	{id = "permafrost", name = "PERMAFROST", desc = "FREEZES LAST 60% LONGER"},
	{id = "stormfront", name = "STORM FRONT", desc = "SHOCK ARCS DEAL TRIPLE DAMAGE"},
	{id = "plaguedoc", name = "PLAGUE DOCTOR", desc = "VENOM STACKS UP TO 8"},
	{id = "duelist", name = "DUELIST", desc = "MELEE SWINGS SEND BULLETS BACK AT FOES"},
	{id = "arsenal", name = "ARSENAL", desc = "+15% CRITICAL CHANCE"},
	{id = "prismatic", name = "PRISMATIC", desc = "REACTIONS DEAL +40% DAMAGE"},
	{id = "gunslinger", name = "GUNSLINGER", desc = "+15% DAMAGE, 20% OF SHOTS ARE FREE"},
	{id = "beastlord", name = "BEASTLORD", desc = "PET SHOTS PIERCE, MOUNT GAINS 2 HEALTH"},
]

# sw = palette letters [mid, light, dark] used to tint the relic sprite
const RELICS = {
	"glass": {name = "GLASS CANNON", desc = "+40% DAMAGE, -2 MAX HEALTH", sw = ["r", "m", "R"]},
	"coin": {name = "LUCKY COIN", desc = "HALF OF ALL COINS COUNT DOUBLE", sw = ["y", "Y", "o"]},
	"feather": {name = "PHOENIX FEATHER", desc = "REVIVE ONCE WITH FULL HEALTH", sw = ["o", "y", "r"]},
	"boots": {name = "HEAVY BOOTS", desc = "IMMUNE TO CHILL, POISON AND DRAIN", sw = ["t", "e", "T"]},
	"split": {name = "SPLIT SHOT", desc = "+1 PROJECTILE, -15% DAMAGE", sw = ["c", "C", "b"]},
	"fang": {name = "VAMPIRE FANG", desc = "HEAL 1 EVERY 25 KILLS", sw = ["R", "r", "k"]},
	"clock": {name = "OVERCLOCK", desc = "FIRE 15% FASTER", sw = ["b", "c", "B"]},
	"lens": {name = "ELEMENT LENS", desc = "WEAPON HITS APPLY ELEMENTS TWICE", sw = ["p", "m", "P"]},
	"skin": {name = "THICK SKIN", desc = "IGNORE THE FIRST HIT IN EVERY ROOM", sw = ["g", "G", "K"]},
	"greed": {name = "GREED", desc = "+50% GOLD, SHOPS COST 25% MORE", sw = ["y", "l", "n"]},
	"cell": {name = "DEEP BATTERY", desc = "MANA ORBS GIVE DOUBLE", sw = ["c", "w", "b"]},
	"compass": {name = "COMPASS", desc = "REVEALS THE WHOLE MAP AND ITS SECRETS", sw = ["n", "l", "N"]},
}

const ACTIVES = {
	"bomb": {name = "POWDER BOMB", desc = "HUGE EXPLOSION AROUND YOU", icon = "sk_mines", max = 2},
	"flask": {name = "RED FLASK", desc = "HEAL 2 HEALTH", icon = "sk_elixir", max = 1},
	"glass": {name = "HOURGLASS", desc = "FREEZE EVERY FOE IN SIGHT", icon = "br_1", max = 1},
	"turret": {name = "POCKET TURRET", desc = "DEPLOY A TURRET FOR 8 SECONDS", icon = "sk_rift", max = 1},
}

const HEAT = [
	"FOES HAVE +25% HEALTH", "ENEMY BULLETS FLY 20% FASTER", "SHOPS COST 30% MORE",
	"EVERY FIGHT ROOM HAS AN ELITE", "START WITH -2 MAX HEALTH",
]

const SEEDS = {
	"bloom": {name = "EMBER BLOOM", desc = "HARVEST: NEXT RUN STARTS WITH +1 MAX HEALTH", cost = 10, sw = {"c": "r", "C": "o"}},
	"vine": {name = "COIN VINE", desc = "HARVEST: +25 GEMS", cost = 8, sw = {"c": "y", "C": "Y"}},
	"root": {name = "RELIC ROOT", desc = "HARVEST: NEXT RUN STARTS WITH A RANDOM RELIC", cost = 20, sw = {"c": "p", "C": "m"}},
	"berry": {name = "PET BERRY", desc = "HARVEST: 2 TREATS FOR THE PET BOWL", cost = 8, sw = {"c": "r", "C": "m"}},
	"gleam": {name = "GLEAM MOSS", desc = "HARVEST: 4 ESSENCE FOR THE WORKBENCH", cost = 8, sw = {"c": "m", "C": "Y"}},
	"flax": {name = "IRON FLAX", desc = "HARVEST: 3 ORE AND 3 FIBER", cost = 8, sw = {"c": "g", "C": "G"}},
}

# ---- crafting materials -----------------------------------------------------------
const MATS = {"ore": "ORE", "ess": "ESSENCE", "fib": "FIBER"}
# what a blueprint weapon costs at the hub workbench, on top of scrap
const RECIPES = {
	"stormcaller": {"ess": 5, "ore": 2}, "sunlance": {"ess": 6, "fib": 1}, "swarm": {"ess": 4, "fib": 3},
	"phoenix": {"fib": 6, "ess": 2}, "quake": {"ore": 7, "fib": 1}, "voidring": {"ore": 4, "ess": 3},
}
