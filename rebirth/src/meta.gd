extends RefCounted
# Persistent progress (gems, unlocks, skill trees), the hero and skill-tree generators,
# and the enemy learning model.

const D = preload("res://src/data.gd")

static var PATH = "user://rebirth_save.json"

static var S = {}

# ---- skill tree effects ------------------------------------------------------------
# Every tree node is one of these effects. b = branch (0 power, 1 flow, 2 element),
# cap = can only sit at the bottom tier.
const EFFECTS = {
	"might": {b = 0, cap = false, name = "MIGHT", desc = "SKILLS DEAL +30% DAMAGE"},
	"reach": {b = 0, cap = false, name = "REACH", desc = "SKILLS COVER A 25% WIDER AREA"},
	"brutal": {b = 0, cap = false, name = "BRUTALITY", desc = "SKILLS DEAL +20% DAMAGE"},
	"twice": {b = 0, cap = true, name = "MASTERY", desc = "SKILL ONE UNLEASHES TWICE"},
	"echo": {b = 0, cap = true, name = "ECHO", desc = "SKILL TWO UNLEASHES TWICE"},
	"tempo": {b = 1, cap = false, name = "TEMPO", desc = "SKILL COOLDOWNS -15%"},
	"rhythm": {b = 1, cap = false, name = "RHYTHM", desc = "SKILL COOLDOWNS -15%"},
	"siphon": {b = 1, cap = false, name = "SIPHON", desc = "CASTING A SKILL RESTORES 15 ENERGY"},
	"fleet": {b = 1, cap = false, name = "FLEET", desc = "MOVE 35% FASTER FOR 2S AFTER A SKILL"},
	"rush": {b = 1, cap = true, name = "BLOODRUSH", desc = "EVERY KILL CUTS COOLDOWNS BY 0.4S"},
	"guard": {b = 1, cap = true, name = "AEGIS", desc = "CASTING GRANTS 1 ARMOR AND BRIEF INVULNERABILITY"},
	"attune": {b = 2, cap = false, name = "ATTUNE", desc = "SKILLS APPLY THEIR ELEMENT TWICE"},
	"residue": {b = 2, cap = false, name = "RESIDUE", desc = "SKILLS LEAVE AN ELEMENT POOL"},
	"spark": {b = 2, cap = false, name = "SPARK", desc = "EACH SKILL CAST CHARGES THE BURST BAR"},
	"cat": {b = 2, cap = true, name = "CATALYSIS", desc = "REACTIONS CHARGE BURST TWICE AS FAST"},
	"pack": {b = 2, cap = true, name = "PACK CALL", desc = "YOUR PET FIRES A VOLLEY WHEN YOU CAST"},
}
const BASE_TREE = ["might", "reach", "twice", "tempo", "rhythm", "rush", "attune", "residue", "cat"]
const OLD_IDS = {"a1": "might", "a2": "reach", "a3": "twice", "b1": "tempo", "b2": "rhythm", "b3": "rush", "c1": "attune", "c2": "residue", "c3": "cat"}
const BRANCH = ["POWER", "FLOW", "ELEMENT"]
const TREE_COST = [20, 45, 90]

static var tree_cache = {}

# The 9 nodes (3 branches x 3 tiers, index = b * 3 + t) for a hero or fusion key.
# The four original heroes share the classic tree; everyone else gets one rolled from the key.
static func tree(key: String) -> Array:
	if tree_cache.has(key):
		return tree_cache[key]
	var ids = []
	if key in ["warden", "arcanist", "ranger", "nightblade"]:
		ids = BASE_TREE.duplicate()
	else:
		var rng = RandomNumberGenerator.new()
		rng.seed = hash(key)
		for b in 3:
			var basic = []
			var caps = []
			for id in EFFECTS:
				if EFFECTS[id].b == b:
					if EFFECTS[id].cap:
						caps.append(id)
					else:
						basic.append(id)
			for t in 2:
				var k = rng.randi() % basic.size()
				ids.append(basic[k])
				basic.remove_at(k)
			ids.append(caps[rng.randi() % caps.size()])
	var out = []
	for i in ids.size():
		var e = EFFECTS[ids[i]]
		out.append({id = ids[i], b = i / 3, t = i % 3, name = e.name, desc = e.desc})
	tree_cache[key] = out
	return out

static func has_node(key: String, node: String) -> bool:
	return S.tree.get(key, []).has(node)

# Skill modifiers from the owned nodes of a tree.
static func calc_sk(key: String) -> Dictionary:
	var sk = {dmg = 1.0, area = 1.0, cdm = 1.0, twice = false, echo = false, rush = false, attune = false, residue = false,
		cat = false, siphon = false, fleet = false, guard = false, spark = false, pack = false}
	for id in S.tree.get(key, []):
		match id:
			"might": sk.dmg += 0.3
			"brutal": sk.dmg += 0.2
			"reach": sk.area += 0.25
			"tempo", "rhythm": sk.cdm -= 0.15
			_:
				if sk.has(id):
					sk[id] = true
	return sk

# ---- heroes ------------------------------------------------------------------------

const ARCH = {
	"BULWARK": {hp = [7, 8], ar = [5, 6], en = [130, 160], weapons = ["blade", "axe", "pistol"], skills = ["whirl", "bulwark", "leap", "rage"]},
	"SAGE": {hp = [4, 5], ar = [3, 4], en = [230, 270], weapons = ["wand", "flask"], skills = ["nova", "rift", "transmute", "elixir"]},
	"STRIKER": {hp = [5, 6], ar = [4, 5], en = [170, 200], weapons = ["bow", "kunai", "pistol"], skills = ["volley", "blink", "mines", "knives"]},
}
const SYL_A = ["VEL", "KOR", "ASH", "MIR", "THAL", "ZEN", "ORU", "BRY", "NYX", "CAEL", "DRU", "ISK"]
const SYL_B = ["DRAK", "WYN", "ISSA", "GOR", "LETH", "VANE", "RIK", "MOTH", "ARA", "THOS", "ELL", "USK"]
const LOOM_COST = 40

static var gen_cache = {}

# Weaves a hero from a seed: archetype decides stat ranges, weapon and skill pool;
# the second skill sometimes crosses over from another archetype, paid for with stats.
static func gen_hero(seed: int) -> Dictionary:
	if gen_cache.has(seed):
		return gen_cache[seed]
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	var names = ARCH.keys()
	var an: String = names[rng.randi() % names.size()]
	var a = ARCH[an]
	var hp = rng.randi_range(a.hp[0], a.hp[1])
	var ar = rng.randi_range(a.ar[0], a.ar[1])
	var en = rng.randi_range(a.en[0] / 10, a.en[1] / 10) * 10
	var pool: Array = a.skills.duplicate()
	var s1: String = pool[rng.randi() % pool.size()]
	pool.erase(s1)
	var s2: String = pool[rng.randi() % pool.size()]
	var twist = ""
	if rng.randf() < 0.4:
		var other: String = names[rng.randi() % names.size()]
		if other != an:
			s2 = ARCH[other].skills[rng.randi() % 4]
			twist = other
			# a borrowed skill costs a little of what the archetype is good at
			if an == "BULWARK":
				hp -= 1
			elif an == "SAGE":
				en -= 30
			else:
				ar -= 1
	if hp + ar >= 13:
		en -= 20
	elif hp + ar <= 8:
		en += 20
	var h = {
		id = "gen", key = "gen%d" % seed, gen = true, arch = an,
		name = SYL_A[rng.randi() % SYL_A.size()] + SYL_B[rng.randi() % SYL_B.size()],
		hp = hp, ar = ar, en = en, start = a.weapons[rng.randi() % a.weapons.size()],
		skill = s1, skill2 = s2,
		desc = "WOVEN %s%s." % [an, (" WITH A TOUCH OF " + twist) if twist != "" else ""],
	}
	gen_cache[seed] = h
	return h

static func hero_count() -> int:
	return D.HEROES.size() + (1 if int(S.get("gen_seed", 0)) != 0 else 0)

static func hero(i: int) -> Dictionary:
	if i >= 0 and i < D.HEROES.size():
		return D.HEROES[i]
	if int(S.get("gen_seed", 0)) != 0:
		return gen_hero(int(S.gen_seed))
	return D.HEROES[0]

static func hero_key(h: Dictionary) -> String:
	return h.get("key", h.id)

static func hero_lv(key: String) -> int:
	return int(S.hero_lv.get(key, 0))

# fused heroes are named by splicing the two names together
const FUSE_NAMES = {}

static func fuse_key(a: Dictionary, b: Dictionary) -> String:
	var pair = [hero_key(a), hero_key(b)]
	pair.sort()
	return pair[0] + "+" + pair[1]

static func fuse_name(a: Dictionary, b: Dictionary) -> String:
	var pair = [a.id, b.id]
	pair.sort()
	var k = pair[0] + "+" + pair[1]
	if FUSE_NAMES.has(k):
		return FUSE_NAMES[k]
	# unknown pairing (a woven hero): splice the two names together
	var na: String = a.name
	var nb: String = b.name
	return na.substr(0, (na.length() + 1) / 2) + nb.substr(nb.length() / 2)

# ---- shop data ---------------------------------------------------------------------

const PETS = {
	"pup": {name = "EMBER PUP", el = "fire", cost = 0, desc = "SPITS FIRE AT NEARBY FOES"},
	"owl": {name = "FROST OWL", el = "ice", cost = 60, desc = "CHILLS FOES FROM AFAR"},
	"mote": {name = "VOLT MOTE", el = "bolt", cost = 60, desc = "ZAPS FOES WITH SPARKS"},
	"toad": {name = "MOSS TOAD", el = "tox", cost = 60, desc = "SPITS STACKING VENOM"},
}
const MOUNTS = {
	"boar": {name = "STONE BOAR", hp = 4, spd = 1.22, cost = 120, desc = "ABSORBS 4 HITS. DASH TRAMPLES FOES."},
	"strider": {name = "STORM STRIDER", hp = 2, spd = 1.45, cost = 120, desc = "VERY FAST. DASH LEAVES LIGHTNING."},
}
const HERO_UP = ["+1 MAX HEALTH", "+1 MAX ARMOR", "+40 MAX ENERGY", "+10% DAMAGE", "+1 HEALTH AND +1 ARMOR"]
const FUSE_COST = 150
const FORTUNES = [
	"FIRE AND ICE MAKE STEAM. STEAM HURTS.", "POISON LOVES A SPARK.", "A FROZEN FOE CANNOT DODGE.",
	"SWAP WEAPONS. SWAP OFTEN.", "THE FOES REMEMBER HOW YOU FIGHT.", "TWO ELEMENTS, ONE BLADE. ASK THE ANVIL.",
	"SHOOT A PUDDLE WITH ANOTHER ELEMENT.", "THE WALL TO THE EAST SOUNDS HOLLOW.", "CATS LIKE PATIENCE.",
	"THE LOOM WEAVES SOULS THAT NEVER WERE.",
]

# ---- save --------------------------------------------------------------------------

static func defaults() -> Dictionary:
	return {
		gems = 0, best = 0, wins = 0, runs = 0, hero = 0, el = 0, hero_lv = {}, tree = {},
		pets = ["pup"], pet = "pup", mounts = [], mount = "", fuse_unlocked = false, fuse = -1, eggs = {},
		gen_seed = 0, weaves = 0, codex = {}, heat = 0, heat_max = 0, daily = {}, boons = {hp = 0, relic = 0},
		garden = [{kind = "", left = 0}, {kind = "", left = 0}, {kind = "", left = 0}, {kind = "", left = 0}, {kind = "", left = 0}], last_seed = 0,
		stats = {}, quests = {day = 0, list = []}, trophies = {}, dyes = [], dye = -1, gift_day = 0, streak = 0,
		skillmod = {}, nemesis = {}, book = {}, graves = [], ally = {}, recipes = [],
		blueprints = [], scrap = 0, mats = {ore = 0, ess = 0, fib = 0}, seeds = {}, treats = 0, bond = {},
		opts = {music = 4, sfx = 4, full = false, shake = true}, tips = {}, run = {},
		ai = {cunning = 0.25, lead = [2.0, 1.0, 2.0, 1.0], bw = {}},
	}

static func load_save() -> void:
	S = defaults()
	if not FileAccess.file_exists(PATH):
		return
	var f = FileAccess.open(PATH, FileAccess.READ)
	var v = JSON.parse_string(f.get_as_text())
	if not (v is Dictionary):
		return
	for k in v:
		if k == "ai" and v[k] is Dictionary:
			for k2 in v[k]:
				S.ai[k2] = v[k][k2]
		else:
			S[k] = v[k]
	for k in ["gems", "best", "wins", "runs", "hero", "el", "fuse", "gen_seed", "weaves", "heat", "heat_max", "last_seed", "scrap", "treats"]:
		S[k] = int(S[k])
	# saves from before trees were effect-based
	for key in S.tree:
		var fixed = []
		for id in S.tree[key]:
			fixed.append(OLD_IDS.get(id, id))
		S.tree[key] = fixed
	while S.garden.size() < 5:
		S.garden.append({kind = "", left = 0})
	if S.hero >= hero_count():
		S.hero = 0
	if S.fuse >= hero_count():
		S.fuse = -1

# Codex: remembers everything the player has met. Returns true the first time.
static func record(cat: String, id: String) -> bool:
	if not S.codex.has(cat):
		S.codex[cat] = {}
	if S.codex[cat].has(id):
		return false
	S.codex[cat][id] = true
	return true

static func codex_count(cat: String) -> int:
	return S.codex.get(cat, {}).size()

# Lifetime counters; also feeds today's bounties.
static func stat(name: String, n: int = 1) -> void:
	S.stats[name] = int(S.stats.get(name, 0)) + n
	for q in S.quests.get("list", []):
		if q.id == name and int(q.have) < int(q.need):
			q.have = int(q.have) + n

static func mat(k: String) -> int:
	return int(S.mats.get(k, 0))

static func add_mat(k: String, n: int) -> void:
	S.mats[k] = mat(k) + n

static func today() -> int:
	var d = Time.get_date_dict_from_system()
	return d.year * 10000 + d.month * 100 + d.day

static func save() -> void:
	var f = FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(S))

# ---- enemy learning ----------------------------------------------------------------
# lead = [tries without lead, hits without, tries with lead, hits with]. Shooters keep
# score of which way of aiming actually lands on this player and favour it.

static func lead_share() -> float:
	var l = S.ai.lead
	var r0 = float(l[1]) / maxf(float(l[0]), 1.0)
	var r1 = float(l[3]) / maxf(float(l[2]), 1.0)
	return clampf(0.5 + (r1 - r0) * 4.0, 0.15, 0.9)

static func lead_pick(rng: RandomNumberGenerator) -> int:
	return 1 if rng.randf() < lead_share() else 0

static func lead_result(arm: int, hit: bool) -> void:
	var l = S.ai.lead
	l[arm * 2] = float(l[arm * 2]) + 1.0
	if hit:
		l[arm * 2 + 1] = float(l[arm * 2 + 1]) + 1.0
	if float(l[arm * 2]) > 150.0:
		for i in 4:
			l[i] = float(l[i]) * 0.5

# Bosses weight each attack by how much it has hurt this player before.
static func boss_weights(bid: String, n: int) -> Array:
	var w = S.ai.bw.get(bid, [])
	if not (w is Array) or w.size() != n:
		w = []
		for i in n:
			w.append(1.0)
		S.ai.bw[bid] = w
	return w

static func boss_pick(rng: RandomNumberGenerator, bid: String, n: int, last: int) -> int:
	var w = boss_weights(bid, n)
	var total = 0.0
	for i in n:
		w[i] = lerpf(float(w[i]), 1.0, 0.03)
		if i != last:
			total += w[i]
	var roll = rng.randf() * total
	for i in n:
		if i == last:
			continue
		roll -= w[i]
		if roll <= 0.0:
			return i
	return (last + 1) % n

static func boss_credit(bid: String, n: int, atk: int, dmg: float) -> void:
	var w = boss_weights(bid, n)
	if atk >= 0 and atk < n:
		w[atk] = minf(4.0, float(w[atk]) + 0.3 * dmg)

static func cunning() -> float:
	return float(S.ai.cunning)

static func add_cunning(v: float) -> void:
	S.ai.cunning = clampf(float(S.ai.cunning) + v, 0.1, 0.9)
