extends SceneTree
# Weapon mechanics: gathering, spirits, rally, hex, weight.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const WMods = preload("res://src/wmods.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for k in n: await process_frame
func foe(pos):
	var e = g.spawn_enemy("goblin", pos)
	e.mhp = 99999.0
	e.hp = 99999.0
	e.born = 0.0
	e.stun = 99.0
	return e
func arm_with(id, tr):
	g.p.weapons = [{"id": id, "el": "fire", "el2": "", "lv": 0, "trait": "", "traits": [tr]}, null]
	g.p.wi = 0
	g.p.cd = 0.0
	g.p.inf = []
func _init():
	Meta.PATH = "user://rebirth_wmods.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.start_run(5, false)
	await frames(5)
	var room = null
	for r in g.dg.rooms:
		if r.type == "fight":
			room = r
			break
	room.cleared = true
	var c: Vector2 = g.rc(room)
	g.p.pos = c + Vector2(-50, 0)
	g.enemies.clear()
	g.st.crit = 0.0
	g.sim["mouse"] = Vector2(340, 135)
	var e = foe(c)

	# ---- gathering: nothing while held, one big shot on letting go ----
	arm_with("pistol", "charge")
	g.bullets.clear()
	g.sim["fire"] = true
	await frames(40)
	check(g.bullets.is_empty() and float(g.p.get("wchg", 0.0)) >= D.WMOD.charge_max, "holding fire gathers, nothing flies")
	g.sim.erase("fire")
	await frames(2)
	var shots = g.bullets.filter(func(b): return b.team == 0)
	check(shots.size() >= 1 and shots[0].dmg > D.WEAPONS["pistol"].dmg * 0.7 * 2.5, "letting go fires one gathered shot: %s" % str(shots.map(func(b): return b.dmg)))
	g.bullets.clear()

	# ---- weight: slower, harder ----
	arm_with("pistol", "heavy")
	var cd0 = D.WEAPONS["pistol"].cd
	g.try_fire()
	check(absf(g.p.cd - cd0 * D.WMOD.heavy_cd * g.st.rate) < 0.01, "weight fires slower: %.2f" % g.p.cd)
	check(g.bullets[0].dmg > D.WEAPONS["pistol"].dmg * 0.7 * 1.9, "and hits twice as hard")
	g.bullets.clear()
	var kb0 = e.kb
	g.hurt_enemy(e, 1.0, "")
	check(e.kb.length() > kb0.length() + 50.0, "and pushes")
	e.kb = Vector2.ZERO

	# ---- hex: the foe takes more ----
	arm_with("pistol", "hex")
	e.vuln = 0.0
	g.hurt_enemy(e, 1.0, "")
	check(e.has("hex") and e.vuln > 1.5, "a hit hexes the foe")
	var h0 = e.hp
	g.hurt_enemy(e, 10.0, "")
	check(absf((h0 - e.hp) - 10.0 * g.st.dmg * 1.5) < 0.5, "a hexed foe takes 50%% more: %.1f" % (h0 - e.hp))
	g.pfx.clear()

	# ---- rally: stacks, faster and harder, then fades ----
	arm_with("pistol", "rally")
	for i in 7:
		g.hurt_enemy(e, 1.0, "")
	check(int(g.p.rally) == D.WMOD.rally_max, "hits stack rally up to %d" % D.WMOD.rally_max)
	g.p.cd = 0.0
	g.try_fire()
	check(g.p.cd < D.WEAPONS["pistol"].cd * g.st.rate * 0.8, "rally fires faster: %.3f" % g.p.cd)
	g.bullets.clear()
	await frames(int(D.WMOD.rally_t * 30) + 6)
	check(int(g.p.get("rally", 0)) == 0, "and fades without hits")

	# ---- spirits: every eighth hit, they shoot, they leave ----
	arm_with("pistol", "summon")
	g.spirits.clear()
	for i in D.WMOD.summon_n:
		g.hurt_enemy(e, 1.0, "")
	check(g.spirits.size() == 1, "the eighth hit calls a spirit")
	g.bullets.clear()
	var hs = e.hp
	await frames(30)
	check(e.hp < hs, "the spirit shoots: %.1f" % (hs - e.hp))
	for i in D.WMOD.summon_n * 3:
		g.hurt_enemy(e, 1.0, "")
	check(g.spirits.size() == D.WMOD.spirit_max, "at most %d at a time" % D.WMOD.spirit_max)
	for s in g.spirits:
		s.t = 0.05
	await frames(4)
	check(g.spirits.is_empty(), "and they leave")

	# ---- weather does not count as a hit ----
	g.p.sum_n = 0
	g.wx_depth += 1
	g.hurt_enemy(e, 1.0, "")
	g.wx_depth -= 1
	check(int(g.p.sum_n) == 0, "weather does not call spirits")
	# cards and effects
	for t in WMods.NEW:
		check(g.Arms.TRAIT_NAME.has(t) and g.Arms.TRAIT_DESC.has(t), "card text for " + t)
	for k in ["bless", "hex", "summon"]:
		check(g.Pfx.DUR.has(k) and g.Sfx.S.has("fx_" + k), "effect and sound: " + k)
	print("WMODS OK" if fails == 0 else "WMODS FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
