extends SceneTree
# Foes that answer weapon mechanics: one kind per floor, and the forge says which fusion fits.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Counter = preload("res://src/counter.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for k in n: await process_frame
func foe(pos, k):
	var e = g.spawn_enemy("goblin", pos)
	e.mhp = 99999.0
	e.hp = 99999.0
	e.born = 0.0
	e.stun = 0.0
	e.frz = 0.0
	e.erase("ctr")
	Counter.put(g, e, k)
	return e
func arm_with(tr):
	g.p.weapons = [{"id": "pistol", "el": "", "el2": "", "lv": 0, "trait": "", "traits": [tr] if tr != "" else []}, {"id": "pistol", "el": "", "el2": "", "lv": 0, "trait": "", "traits": []}]
	g.p.wi = 0
	g.p.erase("wk")
func _init():
	Meta.PATH = "user://rebirth_counter.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	# a floor's answer is fixed by the seed, and none on the first floor
	check(Counter.of(77, 0) == "", "no answer on the first floor")
	check(Counter.of(77, 3) == Counter.of(77, 3), "the same seed gives the same answer")
	var seen = {}
	for f in range(1, 60):
		seen[Counter.of(f * 13, f)] = true
	check(seen.size() == Counter.ORDER.size(), "every kind turns up: %s" % str(seen.keys()))
	for k in Counter.KIND:
		for m in Counter.KIND[k][3] + Counter.KIND[k][4]:
			check(g.WMods.NEW.has(m), "%s names a real mechanic: %s" % [k, m])
	for m in g.WMods.NEW:
		check(Counter.KIND.values().any(func(v): return v[4].has(m)), "%s has a floor that answers it" % m)
	g.start_run(5, false)
	await frames(5)
	g.floor_i = 2
	var room = null
	for r in g.dg.rooms:
		if r.type == "fight":
			room = r
			break
	room.cleared = true
	var c: Vector2 = g.rc(room)
	g.p.pos = c + Vector2(-60, 0)
	g.enemies.clear()
	g.st.crit = 0.0
	g.p.inv = 99.0

	# ---- shell: small hits do a quarter, a heavy hit cracks it ----
	arm_with("")
	var e = foe(c, "shell")
	var h0 = e.hp
	g.hurt_enemy(e, 10.0, "")
	check(absf((h0 - e.hp) - 10.0 * g.st.dmg * D.WMOD.shell_cut) < 0.5, "a shell cuts plain hits: %.1f" % (h0 - e.hp))
	g.wx_depth += 1
	h0 = e.hp
	g.hurt_enemy(e, 10.0, "")
	g.wx_depth -= 1
	check(absf((h0 - e.hp) - 10.0 * D.INF.passive) < 0.5, "but never weather")
	arm_with("heavy")
	g.hurt_enemy(e, 10.0, "")
	check(not e.shell, "a heavy hit cracks the shell")
	arm_with("")
	h0 = e.hp
	g.hurt_enemy(e, 10.0, "")
	check(absf((h0 - e.hp) - 10.0 * g.st.dmg) < 0.5, "and then it takes full hits")
	g.kill(e)
	# a gathered shot cracks it too
	e = foe(c, "shell")
	arm_with("")
	g.hit_big = true
	g.hurt_enemy(e, 10.0, "")
	g.hit_big = false
	check(not e.shell, "a gathered shot cracks the shell")
	g.kill(e)

	# ---- anchor: no push, big hits halved ----
	e = foe(c, "anchor")
	g.hurt_enemy(e, 1.0, "", Vector2(300, 0))
	await frames(1)
	check(e.kb == Vector2.ZERO, "an anchor cannot be pushed")
	arm_with("heavy")
	h0 = e.hp
	g.hurt_enemy(e, 10.0, "")
	check(absf((h0 - e.hp) - 10.0 * g.st.dmg * D.WMOD.anchor_cut) < 0.5, "and soaks up big hits: %.1f" % (h0 - e.hp))
	g.kill(e)

	# ---- purifier: wipes hexes and elements around it ----
	arm_with("hex")
	e = foe(c, "purge")
	var o = foe(c + Vector2(20, 0), "")
	o.erase("ctr")
	g.hurt_enemy(o, 1.0, "")
	o.st["fire"] = 3.0
	check(o.has("hex"), "the neighbour is hexed")
	e.purge_t = 0.05
	await frames(4)
	check(not o.has("hex") and o.vuln <= 0.0 and o.st.is_empty(), "the purifier wipes it")
	g.hurt_enemy(e, 1.0, "")
	await frames(1)
	check(not e.has("hex"), "and cannot be hexed itself")
	g.kill(e)
	g.kill(o)

	# ---- netter: catches spirits ----
	arm_with("summon")
	g.spirits.clear()
	e = foe(c, "net")
	e.ai_off = true
	g.p.pos = c + Vector2(-20, 0)
	for i in D.WMOD.summon_n:
		g.hurt_enemy(e, 1.0, "")
	check(g.spirits.size() == 1, "a spirit was called")
	await frames(20)
	check(g.spirits.is_empty(), "the netter catches it")
	g.kill(e)

	# ---- damper: no rally from it, rally drains close by ----
	arm_with("rally")
	e = foe(c, "damp")
	g.p.rally = 0
	g.hurt_enemy(e, 1.0, "")
	check(int(g.p.get("rally", 0)) == 0, "hits on a damper build no rally")
	g.p.rally = 4
	g.p.rally_t = 99.0
	g.p.pos = e.pos + Vector2(-20, 0)
	await frames(int(D.WMOD.damp_cd * 30) * 2 + 4)
	check(int(g.p.rally) < 4, "rally drains near a damper: %d" % int(g.p.rally))
	g.kill(e)

	# ---- the forge tells you what fits ----
	var k = Counter.now(g)
	check(k != "", "floor 3 has an answer")
	check(Counter.fit(g, Counter.KIND[k][3][0]) == 1 and Counter.fit(g, Counter.KIND[k][4][0]) == -1, "the forge knows good from poor")
	# ---- spawning on this floor puts it on some foes ----
	var n = 0
	g.lock = room
	for i in 60:
		var q = g.spawn_enemy("goblin", c + Vector2(i % 10 * 4, 0))
		g.Stage.mark(g, q)
		if q.get("ctr", "") == k:
			n += 1
	g.lock = null
	check(n >= 8 and n <= 45, "part of the floor's foes carry it: %d/60" % n)
	print("COUNTER OK" if fails == 0 else "COUNTER FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
