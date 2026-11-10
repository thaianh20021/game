extends RefCounted
# The south wing of the Hearth: daily bounties, trophies, quartermaster, cook, tailor,
# capsule machine, mailbox, and idle NPC chatter. Everything here feeds "boons":
# one-shot bonuses that are applied at the start of the next run.

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")

const KINDS = ["quest", "trophy", "armory", "brew", "tailor", "bench"]
const CRAFT_COST = 15

const QUESTS = [
	{id = "kills", name = "SLAY %d FOES", need = [60, 90, 120], reward = [15, 20, 25]},
	{id = "reacts", name = "TRIGGER %d REACTIONS", need = [15, 25, 40], reward = [15, 20, 25]},
	{id = "bosses", name = "DEFEAT %d BOSSES", need = [1, 2, 3], reward = [20, 30, 40]},
	{id = "floors", name = "CLEAR %d FLOORS", need = [3, 5, 6], reward = [15, 22, 30]},
	{id = "chests", name = "OPEN %d CHESTS", need = [8, 12, 16], reward = [12, 18, 24]},
	{id = "gold", name = "COLLECT %d GOLD", need = [100, 160, 220], reward = [12, 18, 24]},
]
const TROPHIES = [
	{id = "kill1", name = "MONSTER HUNTER", stat = "kills", need = 500, reward = 40},
	{id = "kill2", name = "EXTERMINATOR", stat = "kills", need = 3000, reward = 120},
	{id = "react", name = "ALCHEMY ADEPT", stat = "reacts", need = 300, reward = 50},
	{id = "boss", name = "GIANT SLAYER", stat = "bosses", need = 10, reward = 60},
	{id = "floor", name = "DEEP DELVER", stat = "floors", need = 50, reward = 60},
	{id = "gold", name = "TREASURER", stat = "gold", need = 3000, reward = 50},
	{id = "chest", name = "LOCKPICK", stat = "chests", need = 150, reward = 40},
	{id = "wins", name = "CORE BREAKER", stat = "wins", need = 5, reward = 100},
]
const MEALS = [
	{id = "hp", name = "IRON STEW", desc = "NEXT RUN: +1 MAX HEALTH", cost = 10},
	{id = "armor", name = "GUARD TEA", desc = "NEXT RUN: +1 MAX ARMOR", cost = 10},
	{id = "gold", name = "LUCKY PIE", desc = "NEXT RUN: START WITH 30 GOLD", cost = 8},
	{id = "key", name = "KEY BISCUIT", desc = "NEXT RUN: START WITH A KEY", cost = 8},
	{id = "active", name = "PACKED LUNCH", desc = "NEXT RUN: START WITH A RANDOM ITEM", cost = 12},
]
const DYES = [["EMBER DYE", 0.12], ["MOSS DYE", 0.3], ["TIDE DYE", 0.45], ["DUSK DYE", 0.62], ["ROSE DYE", 0.8]]
const DYE_COST = 25
const CAPSULE_COST = 12
const CHAT = {
	"npc_mentor": ["EVERY SOUL GROWS ITS OWN TREE.", "PRACTICE ON THE DUMMY."],
	"npc_armorer": ["DENTS BUILD CHARACTER.", "ARMOR COMES BACK. HEALTH DOES NOT."],
	"npc_keeper": ["WHO IS A GOOD PUP?", "THE BOAR ATE MY HAT AGAIN."],
	"npc_cook": ["SOUP IS READY!", "NEVER DELVE ON AN EMPTY STOMACH."],
	"npc_tailor": ["THAT COLOUR? IN THIS DUNGEON?", "A STITCH IN TIME."],
	"npc_quarter": ["FOUND IT ONCE? I CAN FIND IT AGAIN.", "MIND THE POINTY END."],
}

static var chat_t = 5.0

static func boon(k: String) -> int:
	return int(Meta.S.boons.get(k, 0))

static func dye_shift() -> float:
	var i = int(Meta.S.get("dye", -1))
	return DYES[i][1] if (i >= 0 and i < DYES.size()) else 0.0

# ---- daily bounties ---------------------------------------------------------------

static func ensure_quests() -> void:
	var day = Meta.today()
	if int(Meta.S.quests.get("day", 0)) == day:
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = day
	var pool = range(QUESTS.size())
	var list = []
	for i in 3:
		var k = rng.randi() % pool.size()
		var q = QUESTS[pool[k]]
		pool.remove_at(k)
		var tier = rng.randi() % 3
		list.append({id = q.id, need = q.need[tier], have = 0, reward = q.reward[tier], claimed = false})
	Meta.S.quests = {day = day, list = list}

static func quest_name(q: Dictionary) -> String:
	for d in QUESTS:
		if d.id == q.id:
			return d.name % int(q.need)
	return str(q.id)

# ---- menus ------------------------------------------------------------------------

static func rows(g, kind: String) -> Array:
	var out = []
	match kind:
		"quest":
			ensure_quests()
			out.append({name = "BOUNTIES FOR " + str(int(Meta.S.quests.day)), desc = "THREE NEW TASKS EVERY DAY, COUNTED IN ANY RUN", cost = 0, state = "owned", tag = "", fn = func(): pass})
			for q in Meta.S.quests.list:
				var done = int(q.have) >= int(q.need)
				out.append({name = quest_name(q), desc = "REWARD %d GEMS" % int(q.reward), cost = 0,
					state = "on" if q.claimed else ("owned" if done else "locked"),
					tag = "DONE" if q.claimed else ("CLAIM" if done else "%d/%d" % [int(q.have), int(q.need)]),
					fn = func():
						q.claimed = true
						Meta.S.gems += int(q.reward)})
		"trophy":
			for t in TROPHIES:
				var have = int(Meta.S.wins) if t.stat == "wins" else int(Meta.S.stats.get(t.stat, 0))
				var claimed = Meta.S.trophies.has(t.id)
				var done = have >= t.need
				out.append({name = t.name, desc = "%s %d. REWARD %d GEMS" % [{"kills": "SLAY", "reacts": "REACTIONS", "bosses": "BOSSES", "floors": "FLOORS", "gold": "GOLD", "chests": "CHESTS", "wins": "CLEARS"}[t.stat], t.need, t.reward], cost = 0,
					state = "on" if claimed else ("owned" if done else "locked"),
					tag = "DONE" if claimed else ("CLAIM" if done else "%d/%d" % [mini(have, t.need), t.need]),
					fn = func():
						Meta.S.trophies[t.id] = true
						Meta.S.gems += t.reward})
		"armory":
			var found = []
			for id in Meta.S.codex.get("weapons", {}):
				if D.WEAPONS.has(id):
					found.append(id)
			found.sort()
			var rng = RandomNumberGenerator.new()
			rng.seed = int(Meta.S.runs) * 7 + 3
			if found.is_empty():
				out.append({name = "THE RACK IS EMPTY", desc = "WEAPONS YOU FIND IN THE DUNGEON SHOW UP HERE", cost = 0, state = "locked", tag = "", fn = func(): pass})
			for i in mini(4, found.size()):
				var k = rng.randi() % found.size()
				var id: String = found[k]
				found.remove_at(k)
				var w = D.WEAPONS[id]
				out.append({name = w.name, desc = "NEXT RUN: CARRY IT AS YOUR SECOND WEAPON", cost = [12, 30, 60][w.rar], icon = "w_%s_" % w.spr,
					state = "on" if str(Meta.S.boons.get("weapon", "")) == id else "buy",
					fn = func(): Meta.S.boons["weapon"] = id})
			out.append({name = "THE RACK CHANGES AFTER EVERY RUN", desc = "ONLY ONE WEAPON CAN BE PACKED AT A TIME", cost = 0, state = "locked", tag = "", fn = func(): pass})
		"brew":
			for m in MEALS:
				var has = (str(Meta.S.boons.get("active", "")) != "") if m.id == "active" else boon(m.id) > 0
				out.append({name = m.name, desc = m.desc, cost = m.cost, state = "on" if has else "buy",
					fn = func(): eat(g, m.id)})
		"bench":
			out.append({name = "SCRAP %d  ORE %d  ESSENCE %d  FIBER %d" % [int(Meta.S.scrap), Meta.mat("ore"), Meta.mat("ess"), Meta.mat("fib")], desc = "MATERIALS DROP FROM FOES AND CHESTS", cost = 0, state = "owned", tag = "", fn = func(): pass})
			for id in D.WEAPONS:
				var w = D.WEAPONS[id]
				if not w.get("bp", false):
					continue
				if not Meta.S.blueprints.has(id):
					out.append({name = "UNKNOWN BLUEPRINT", desc = "NOT FOUND YET", cost = 0, state = "locked", tag = "", fn = func(): pass})
					continue
				var packed = str(Meta.S.boons.get("weapon", "")) == id
				var can = int(Meta.S.scrap) >= CRAFT_COST
				var rec: Dictionary = D.RECIPES[id]
				var need = "%d SCRAP" % CRAFT_COST
				for k in rec:
					need += ", %d %s" % [rec[k], D.MATS[k]]
					if Meta.mat(k) < rec[k]:
						can = false
				out.append({name = w.name, desc = w.bpdesc if packed else "NEEDS " + need, cost = 0, icon = "w_%s_" % w.spr,
					state = "on" if packed else ("owned" if can else "locked"), tag = "PACKED" if packed else ("CRAFT" if can else "NEED MORE"),
					fn = func():
						for k in rec:
							Meta.add_mat(k, -rec[k])
						Meta.S.scrap = int(Meta.S.scrap) - CRAFT_COST
						Meta.S.boons["weapon"] = id})
		"tailor":
			for i in DYES.size():
				var own = Meta.S.dyes.has(i) or Meta.S.dyes.has(float(i))
				out.append({name = DYES[i][0], desc = "RECOLOURS THE CLOTH OF EVERY HERO YOU PLAY", cost = DYE_COST,
					state = "on" if int(Meta.S.dye) == i else ("owned" if own else "buy"),
					fn = func():
						if not own:
							Meta.S.dyes.append(i)
						Meta.S.dye = i})
			out.append({name = "NO DYE", desc = "ORIGINAL COLOURS", cost = 0, state = "on" if int(Meta.S.dye) < 0 else "owned", fn = func(): Meta.S.dye = -1})
	return out

static func eat(g, id: String) -> void:
	match id:
		"hp": Meta.S.boons["hp"] = boon("hp") + 1
		"armor": Meta.S.boons["armor"] = 1
		"gold": Meta.S.boons["gold"] = 30
		"key": Meta.S.boons["key"] = boon("key") + 1
		"active": Meta.S.boons["active"] = D.ACTIVES.keys()[g.rng.randi() % D.ACTIVES.size()]

# ---- things you poke --------------------------------------------------------------

static func prize(g, text: String, col: Color) -> void:
	Meta.save()
	g.label(g.p.pos + Vector2(0, -24), text, col, true)
	g.burst(g.pcenter(), 14, col, 90.0, 0.6)
	Sfx.play("chest")

static func egg(g, it: Dictionary) -> void:
	var at = g.p.pos + Vector2(0, -24)
	var pink = Color("e56db2")
	match it.egg:
		"capsule":
			if Meta.S.gems < CAPSULE_COST:
				Sfx.play("deny")
				g.label(at, "NEEDS %d GEMS" % CAPSULE_COST, Color("ff6a6a"))
				return
			Meta.S.gems -= CAPSULE_COST
			g.flash(it.pos, 60.0, pink, 0.4)
			var roll = g.rng.randf()
			if roll < 0.3:
				var n = g.rng.randi_range(5, 10)
				Meta.S.gems += n
				prize(g, "SMALL PRIZE +%d" % n, pink)
			elif roll < 0.45:
				var n = g.rng.randi_range(25, 40)
				Meta.S.gems += n
				prize(g, "JACKPOT +%d" % n, Color("ffd24a"))
			elif roll < 0.6:
				Meta.S.boons["relic"] = boon("relic") + 1
				prize(g, "A RELIC FOR YOUR NEXT RUN", Color("ffd24a"))
			elif roll < 0.7:
				Meta.S.boons["hp"] = boon("hp") + 1
				prize(g, "+1 MAX HEALTH NEXT RUN", Color("ff6a7a"))
			elif roll < 0.8:
				Meta.S.boons["key"] = boon("key") + 1
				prize(g, "A KEY FOR YOUR NEXT RUN", Color("ffd24a"))
			elif roll < 0.9:
				Meta.S.boons["active"] = D.ACTIVES.keys()[g.rng.randi() % D.ACTIVES.size()]
				prize(g, D.ACTIVES[Meta.S.boons.active].name + " NEXT RUN", Color("5cd3f2"))
			else:
				var missing = []
				for id in Meta.PETS:
					if not Meta.S.pets.has(id):
						missing.append(id)
				if missing.is_empty():
					Meta.S.gems += 30
					prize(g, "JACKPOT +30", Color("ffd24a"))
				else:
					var id: String = missing[g.rng.randi() % missing.size()]
					Meta.S.pets.append(id)
					prize(g, "NEW PET: " + Meta.PETS[id].name, Color("a6e84e"))
		"mail":
			var day = Meta.today()
			if int(Meta.S.gift_day) == day:
				g.label(at, "EMPTY. COME BACK TOMORROW.", Color("a8a7b8"))
				return
			Meta.S.streak = int(Meta.S.streak) + 1 if day - int(Meta.S.gift_day) == 1 else 1
			Meta.S.gift_day = day
			var n = 8 + 2 * mini(int(Meta.S.streak), 6)
			Meta.S.gems += n
			prize(g, "DAILY GIFT +%d  (DAY %d)" % [n, int(Meta.S.streak)], pink)

# ---- boons ------------------------------------------------------------------------

static func boon_text() -> String:
	var parts = []
	if boon("hp") > 0:
		parts.append("+%d HEALTH" % boon("hp"))
	if boon("armor") > 0:
		parts.append("+1 ARMOR")
	if boon("gold") > 0:
		parts.append("%d GOLD" % boon("gold"))
	if boon("key") > 0:
		parts.append("%d KEY" % boon("key"))
	if boon("relic") > 0:
		parts.append("%d RELIC" % boon("relic"))
	if str(Meta.S.boons.get("active", "")) != "":
		parts.append(D.ACTIVES[Meta.S.boons.active].name)
	if str(Meta.S.boons.get("weapon", "")) != "":
		parts.append(D.WEAPONS[Meta.S.boons.weapon].name)
	return "" if parts.is_empty() else "NEXT RUN: " + ", ".join(parts)

# Spends every stored boon on the hero currently bound as g.p.
static func apply_boons(g, More) -> void:
	var p = g.p
	p.mhp += boon("hp")
	p.hp = p.mhp
	p.mar += boon("armor")
	p.ar = p.mar
	p.gold += boon("gold")
	p.keys += boon("key")
	for i in boon("relic"):
		More.take_relic(g, More.random_relic(g))
	var act = str(Meta.S.boons.get("active", ""))
	if D.ACTIVES.has(act):
		p.active = {id = act, n = D.ACTIVES[act].max}
	var wid = str(Meta.S.boons.get("weapon", ""))
	if D.WEAPONS.has(wid):
		p.weapons[1] = {id = wid, el = D.EL[(int(Meta.S.el) + 1) % 4], el2 = "", lv = 0}
	Meta.S.boons = {}

# ---- idle chatter -----------------------------------------------------------------

static func chatter(g, dt: float) -> void:
	chat_t -= dt
	if chat_t > 0.0:
		return
	chat_t = g.rng.randf_range(5.0, 9.0)
	var who = []
	for it in g.inter:
		if CHAT.has(it.get("spr", "")) and g.on_screen(it.pos, -20.0) and it.pos.distance_to(g.p.pos) > 30.0:
			who.append(it)
	if who.is_empty():
		return
	var it = who[g.rng.randi() % who.size()]
	var lines = CHAT[it.spr]
	g.label(it.pos + Vector2(0, -26), lines[g.rng.randi() % lines.size()], Color("d9d4c7"))
