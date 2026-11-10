extends RefCounted
# All tunable game content: elements, weapons, heroes, enemies, biomes, buffs.

const EL = ["fire", "ice", "bolt", "tox"]
const EL_NAME = {"": "NEUTRAL", "fire": "FIRE", "ice": "ICE", "bolt": "STORM", "tox": "VENOM", "prism": "PRISM"}
const EL_PREFIX = {"": "", "fire": "EMBER ", "ice": "FROST ", "bolt": "STORM ", "tox": "VENOM ", "prism": "PRISM "}

static var EL_COL = {
	"": Color("f1ead8"), "fire": Color("ff8a3a"), "ice": Color("7adfff"),
	"bolt": Color("ffe45c"), "tox": Color("a6e84e"), "prism": Color("e58cff"),
}

# reaction key = the two elements sorted and joined with "+"
static var REACT = {
	"fire+ice": ["MELT", Color("d8f6ff")],
	"fire+tox": ["BLAST", Color("ffb347")],
	"bolt+fire": ["OVERLOAD", Color("ff7ad9")],
	"bolt+ice": ["SHATTER", Color("b8c8ff")],
	"ice+tox": ["BLIGHT", Color("6fe0b0")],
	"bolt+tox": ["PLAGUE", Color("d4f04a")],
}

static var RAR_COL = [Color("d9d4c7"), Color("6fb7ff"), Color("ffb84a")]

const WEAPONS = {
	"pistol": {name = "PISTOL", spr = "pistol", type = "bullet", dmg = 4.0, cd = 0.28, cost = 0.0, speed = 270.0, spread = 0.04, rar = 0},
	"kunai": {name = "KUNAI", spr = "kunai", type = "bullet", dmg = 3.5, cd = 0.19, cost = 0.0, speed = 320.0, spread = 0.03, kind = "arrow", rar = 0},
	"blade": {name = "BLADE", spr = "blade", type = "melee", dmg = 9.0, cd = 0.36, cost = 0.0, range = 30.0, arc = 2.4, rar = 0},
	"wand": {name = "WAND", spr = "staff", type = "bullet", dmg = 6.0, cd = 0.42, cost = 0.0, speed = 210.0, aoe = 16.0, r = 3, rar = 0},
	"bow": {name = "LONGBOW", spr = "bow", type = "bullet", dmg = 7.0, cd = 0.46, cost = 0.0, speed = 330.0, pierce = 1, kind = "arrow", rar = 0},
	"flask": {name = "FLASK", spr = "cannon", type = "lob", dmg = 6.0, cd = 0.55, cost = 0.0, range = 130.0, aoe = 20.0, puddle = true, rar = 0},
	"axe": {name = "WAR AXE", spr = "blade", type = "melee", dmg = 12.0, cd = 0.5, cost = 0.0, range = 32.0, arc = 2.8, rar = 0},
	"scatter": {name = "SCATTERGUN", spr = "cannon", type = "bullet", dmg = 3.0, cd = 0.7, cost = 3.0, speed = 250.0, n = 6, fan = 0.55, spread = 0.05, life = 0.42, rar = 0},
	"needle": {name = "NEEDLER", spr = "rifle", type = "bullet", dmg = 2.2, cd = 0.08, cost = 0.7, speed = 300.0, spread = 0.12, rar = 0},
	"repeater": {name = "REPEATER", spr = "rifle", type = "bullet", dmg = 3.4, cd = 0.14, cost = 1.0, speed = 330.0, spread = 0.05, bounce = 1, rar = 1},
	"sprayer": {name = "SPRAYER", spr = "cannon", type = "bullet", dmg = 1.6, cd = 0.05, cost = 0.45, speed = 175.0, spread = 0.26, life = 0.34, pierce = 99, kind = "flame", rar = 1},
	"coil": {name = "ARC COIL", spr = "staff", type = "chain", dmg = 6.0, cd = 0.42, cost = 2.5, range = 135.0, n = 3, rar = 1},
	"mortar": {name = "MORTAR", spr = "cannon", type = "lob", dmg = 13.0, cd = 0.9, cost = 4.0, range = 150.0, aoe = 34.0, puddle = true, rar = 1},
	"greatblade": {name = "GREATBLADE", spr = "blade", type = "melee", dmg = 16.0, cd = 0.55, cost = 1.0, range = 38.0, arc = 3.0, rar = 1},
	"beam": {name = "BEAM LANCE", spr = "rifle", type = "beam", dmg = 1.5, cd = 0.06, cost = 0.5, range = 140.0, rar = 2},
	"rail": {name = "RAILGUN", spr = "rifle", type = "bullet", dmg = 20.0, cd = 0.85, cost = 4.0, speed = 560.0, pierce = 5, r = 3, kind = "arrow", rar = 2},
	"nova": {name = "STAR STAFF", spr = "staff", type = "bullet", dmg = 4.0, cd = 0.6, cost = 4.0, speed = 190.0, n = 10, fan = 5.6, pierce = 1, rar = 2},
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
}

# each element is weak to one other element
const WEAK = {"fire": "ice", "ice": "fire", "bolt": "tox", "tox": "bolt"}

const HEROES = [
	{id = "warden", name = "WARDEN", hp = 7, ar = 5, en = 160, start = "blade", skill = "whirl", skill2 = "bulwark", skill_name = "WHIRLWIND", skill_cd = 7.0,
		desc = "TANKY BLADE MASTER. SPIN TO SHRED FOES AND SWAT BULLETS."},
	{id = "arcanist", name = "ARCANIST", hp = 5, ar = 4, en = 240, start = "wand", skill = "nova", skill2 = "rift", skill_name = "ELEMENT NOVA", skill_cd = 9.0,
		desc = "GLASS CANNON MAGE. NOVA BLASTS YOUR ELEMENT IN ALL DIRECTIONS."},
	{id = "ranger", name = "RANGER", hp = 6, ar = 4, en = 190, start = "bow", skill = "volley", skill2 = "mines", skill_name = "ARROW STORM", skill_cd = 8.0,
		desc = "PIERCING SHOTS FROM AFAR. UNLEASH THREE FANS OF ARROWS."},
	{id = "nightblade", name = "NIGHTBLADE", hp = 5, ar = 5, en = 180, start = "kunai", skill = "blink", skill2 = "knives", skill_name = "SHADOW STEP", skill_cd = 5.0,
		desc = "FAST ASSASSIN. BLINK THROUGH ENEMIES, CUTTING ALL IN THE PATH."},
	{id = "alchemist", name = "ALCHEMIST", hp = 5, ar = 4, en = 220, start = "flask", skill = "transmute", skill2 = "elixir", skill_name = "TRANSMUTE", skill_cd = 9.0,
		desc = "LOBS ELEMENT FLASKS. TURNS ANY STATUS INTO A REACTION."},
	{id = "berserker", name = "BERSERKER", hp = 8, ar = 3, en = 140, start = "axe", skill = "leap", skill2 = "rage", skill_name = "SKY LEAP", skill_cd = 6.0,
		desc = "ALL HEALTH, LITTLE ARMOR. LEAPS IN AND RAGES."},
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
	"dummy": {spr = "dummy", hp = 99999, spd = 0, ai = "dummy", r = 5, cost = 0},
}

static var BIOMES = [
	{name = "ANCIENT CAVE", roster = ["slime", "slime", "bat", "goblin", "boar", "shroom"], bosses = ["golem", "queen"],
		ambient = Color(0.20, 0.20, 0.31), floor = [Color("57516a"), Color("4e4960"), Color("605a74")], grout = Color("38334a"),
		accent = Color("4f8a50"), face = [Color("8479a0"), Color("6a5f86"), Color("4a4263")], cap = Color("1b1726"), edge = Color("9d93b8")},
	{name = "EMBER FORGE", roster = ["imp", "magma", "pyro", "guard", "turret", "bat", "goblin"], bosses = ["tyrant", "iron"],
		ambient = Color(0.28, 0.18, 0.17), floor = [Color("5c4038"), Color("523931"), Color("684a40")], grout = Color("35211f"),
		accent = Color("ff8a2a"), face = [Color("98563f"), Color("7a4133"), Color("552b27")], cap = Color("1d1216"), edge = Color("c0704c")},
	{name = "CRYSTAL ARCHIVE", roster = ["wisp", "skel", "necro", "shade", "turret", "guard", "pyro"], bosses = ["lich", "void"],
		ambient = Color(0.17, 0.22, 0.34), floor = [Color("3b4c70"), Color("344364"), Color("44577e")], grout = Color("232d48"),
		accent = Color("7fe3ff"), face = [Color("6780b6"), Color("4d6194"), Color("35446c")], cap = Color("111626"), edge = Color("95afe0")},
]

const BUFFS = [
	{id = "vital", name = "IRON HEART", desc = "+2 MAX HEALTH AND HEAL 3"},
	{id = "plating", name = "RUNE PLATING", desc = "+2 MAX ARMOR"},
	{id = "battery", name = "DEEP CELL", desc = "+80 MAX ENERGY, FULL REFILL"},
	{id = "catalyst", name = "CATALYST", desc = "REACTIONS DEAL +60% DAMAGE"},
	{id = "linger", name = "LINGERING HEX", desc = "ELEMENT EFFECTS LAST 60% LONGER"},
	{id = "crit", name = "KEEN EYE", desc = "+15% CRITICAL CHANCE"},
	{id = "bounce", name = "RICOCHET", desc = "BULLETS BOUNCE OFF WALLS ONCE MORE"},
	{id = "pierce", name = "DRILL TIPS", desc = "BULLETS PIERCE ONE MORE ENEMY"},
	{id = "swift", name = "WINDSTEP", desc = "MOVE FASTER, DASH RECHARGES QUICKER"},
	{id = "vamp", name = "SOUL SIPHON", desc = "KILLS OFTEN RESTORE 1 ARMOR"},
	{id = "free", name = "RECYCLER", desc = "30% OF SHOTS COST NO ENERGY"},
	{id = "cond", name = "CONTAGION", desc = "SLAIN FOES PASS THEIR ELEMENT ON"},
	{id = "fury", name = "FURY", desc = "+20% ALL WEAPON DAMAGE"},
	{id = "magnet", name = "LODESTONE", desc = "PULL PICKUPS FROM AFAR, +30% GOLD"},
	{id = "thorns", name = "SPITE", desc = "WHEN HURT, BLAST NEARBY FOES"},
	{id = "pack", name = "PACK BOND", desc = "YOUR PET ATTACKS TWICE AS FAST"},
	{id = "wind2", name = "SECOND WIND", desc = "ONCE PER FLOOR, SURVIVE A FATAL HIT"},
	{id = "surge", name = "RESONANCE", desc = "BURST CHARGES 50% FASTER"},
]
const BOSS_ATKS = [3, 4, 4, 3, 4, 4]

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
	"cell": {name = "DEEP BATTERY", desc = "ENERGY ORBS GIVE DOUBLE", sw = ["c", "w", "b"]},
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
}
