extends RefCounted
# NPC dialogue. Lines are picked by simple rules that read the current run:
# gold, health, carried elements, the floor's boss, how cunning the foes have become.

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")

const WHO = {
	"merchant": {name = "PIP THE PEDDLER", spr = "npc_merchant"},
	"smith": {name = "BRANNA THE SMITH", spr = "npc_smith"},
	"alch": {name = "OLD FENWICK", spr = "npc_alch"},
	"tree": {name = "MENTOR SOLENNE", spr = "npc_mentor"},
	"armor": {name = "ARMORER HOLT", spr = "npc_armorer"},
	"beast": {name = "KEEPER MOSSY", spr = "npc_keeper"},
	"fuse": {name = "THE SOUL ALTAR", spr = "altar"},
	"brew": {name = "COOK DUMPLE", spr = "npc_cook"},
	"tailor": {name = "TAILOR VESS", spr = "npc_tailor"},
	"armory": {name = "QUARTERMASTER ODD", spr = "npc_quarter"},
	"loom": {name = "THE SOUL LOOM", spr = "loom"},
}

static func carried(g) -> Array:
	var els = []
	for w in g.p.weapons:
		if w != null:
			for k in [w.el, w.get("el2", "")]:
				if k != "" and k != "prism" and not els.has(k):
					els.append(k)
	return els

static func pick(g, arr: Array) -> String:
	return arr[g.rng.randi() % arr.size()]

static func lines(g, who: String) -> Array:
	var p = g.p
	var out = []
	var els = carried(g)
	match who:
		"merchant":
			var bi = g.floor_i / 2
			out.append(pick(g, [
				"WELCOME, WELCOME! FINEST WARES THIS SIDE OF THE %s." % D.BIOMES[bi].name,
				"A CUSTOMER! AND STILL BREATHING. MY FAVORITE KIND.",
				"PSST. YOU. YES, YOU WITH THE %s. COME LOOK." % D.WEAPONS[p.weapons[p.wi].id].name,
			]))
			if p.hp <= p.mhp / 2:
				out.append("YOU LOOK HALF DEAD, FRIEND. THE RED FLASK. DRINK FIRST, HAGGLE LATER.")
			elif p.gold < 15:
				out.append("YOUR PURSE SOUNDS EMPTY. SMASH SOME CRATES AND COME BACK, EH?")
			elif p.gold >= 80:
				out.append("OHO, THAT PURSE JINGLES! THE TOME ON THE RIGHT IS WORTH EVERY COIN.")
			if els.size() < 2:
				out.append("ONLY ONE ELEMENT ON YOU? BUY A SECOND. TWO ELEMENTS ON ONE FOE GO BOOM.")
			else:
				var pair = [els[0], els[1]]
				pair.sort()
				out.append("%s AND %s... THAT MAKES %s. NASTY. I LIKE IT." % [D.EL_NAME[els[0]], D.EL_NAME[els[1]], D.REACT[pair[0] + "+" + pair[1]][0]])
			if g.floor_i % 2 == 1:
				var b = D.ENEMIES[g.dg.boss_id]
				if b.get("el", "") != "":
					out.append("WORD IS %s WAITS AHEAD. IT SHRUGS OFF %s BUT HATES %s." % [b.name, D.EL_NAME[b.el], D.EL_NAME[D.WEAK[b.el]]])
				else:
					out.append("WORD IS %s WAITS AHEAD. NO WEAKNESS I KNOW OF. KEEP MOVING." % b.name)
			elif Meta.cunning() > 0.5:
				out.append("THE FOES WHISPER ABOUT YOU. THEY HAVE LEARNED YOUR STEPS. CHANGE THEM.")
			else:
				out.append("NO BIG ONE ON THIS FLOOR. BREATHE WHILE YOU CAN.")
		"smith":
			var w = p.weapons[p.wi]
			var lv = int(w.get("lv", 0))
			if lv >= 5:
				out.append("THAT %s IS PERFECT. I WILL NOT TOUCH IT." % D.WEAPONS[w.id].name)
			elif lv == 0:
				out.append("A PLAIN %s? PUT IT ON THE ANVIL. EVERY RANK ADDS A QUARTER MORE BITE." % D.WEAPONS[w.id].name)
			else:
				out.append("A PLUS %d %s. GOOD STEEL. I CAN PUSH IT FURTHER." % [lv, D.WEAPONS[w.id].name])
			if p.weapons[1 - p.wi] != null:
				out.append("TWO WEAPONS? THE ALTAR ON THE RIGHT MELTS THEM INTO ONE. BOTH ELEMENTS, ONE GRIP.")
			else:
				out.append("FIND A SECOND WEAPON AND THE ALTAR CAN FUSE THEM.")
		"alch":
			out.append(pick(g, [
				"HEE HEE. FIRE FEARS ICE, ICE FEARS FIRE. STORM AND VENOM BITE EACH OTHER TOO.",
				"A PUDDLE OF ONE ELEMENT, A SPLASH OF ANOTHER. STAND BACK.",
			]))
			if els.is_empty():
				out.append("NO ELEMENT AT ALL? DROP THAT WEAPON IN MY POT. FIFTEEN COINS.")
			else:
				out.append("TIRED OF %s? THE POT WILL TURN IT INTO SOMETHING ELSE." % D.EL_NAME[els[0]])
		"tree":
			var owned = Meta.S.tree.get(p.tkey, []).size()
			if owned == 0:
				out.append("EVERY SOUL GROWS ITS OWN TREE, %s. YOURS HAS NOT SPROUTED YET." % p.name)
			elif owned >= 9:
				out.append("YOUR TREE IS IN FULL BLOOM. I HAVE NOTHING LEFT TO TEACH YOU.")
			else:
				out.append("%d OF 9 BRANCHES, %s. THE DEEP ONES CHANGE HOW YOUR SKILLS BEHAVE." % [owned, p.name])
			if p.tkey.contains("+"):
				out.append("A FUSED SOUL... ITS TREE IS UNLIKE EITHER HALF. FASCINATING.")
		"armor":
			var lv = Meta.hero_lv(p.hkey)
			out.append("RANK %d OF 5. " % lv + ("COME BACK WITH GEMS AND I WILL REFORGE YOU." if lv < 5 else "YOU ARE AS TOUGH AS I CAN MAKE YOU."))
			if Meta.S.runs >= 3 and Meta.S.wins == 0:
				out.append("%d RUNS AND NO CORE YET. MORE HEALTH WOULD NOT HURT, WOULD IT?" % Meta.S.runs)
		"beast":
			out.append(pick(g, ["THEY BITE. MOSTLY THE ENEMY.", "A PET BRINGS ITS OWN ELEMENT. THAT IS A FREE REACTION, FRIEND."]))
			if Meta.S.mount == "":
				out.append("STILL WALKING? A MOUNT TAKES THE HITS FOR YOU.")
		"brew":
			out.append("EAT BEFORE YOU DELVE. A MEAL LASTS ONE RUN, SO CHOOSE WELL.")
			if Meta.S.runs >= 2 and Meta.S.wins == 0:
				out.append("YOU KEEP COMING BACK HUNGRY. TRY THE STEW.")
		"tailor":
			out.append("SAME HERO, NEW COLOURS. THE FOES WILL NOT KNOW WHAT HIT THEM." if Meta.S.dyes.is_empty() else "BACK FOR ANOTHER SHADE? I KNEW YOU HAD TASTE.")
		"armory":
			var nw = Meta.codex_count("weapons")
			out.append("YOU HAVE HANDLED %d KINDS OF WEAPON. I KEEP A FEW OF THEM ON THE RACK." % nw if nw > 0 else "BRING ME STORIES OF WEAPONS AND I WILL STOCK THEM.")
		"fuse":
			out.append("TWO SOULS. ONE BODY. THE BEST OF BOTH, AND A SKILL TREE ALL ITS OWN." if Meta.S.fuse_unlocked else "THE ALTAR SLEEPS. GEMS WILL WAKE IT.")
		"loom":
			if Meta.S.gen_seed == 0:
				out.append("THE LOOM IS EMPTY. THE FIRST WEAVING IS FREE.")
			else:
				var h = Meta.gen_hero(Meta.S.gen_seed)
				out.append("%s STANDS IN THE HALL. %s" % [h.name, h.desc])
			out.append("EACH THREAD IS A DIFFERENT SOUL: BODY, WEAPON, SKILLS, EVEN ITS SKILL TREE.")
	return out
