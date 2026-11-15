extends SceneTree
# Eaters, the boss echo, cursed blessings, element shards and trial rules.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Twist = preload("res://src/twist.gd")
const Combo = preload("res://src/combo.gd")
const Hud = preload("res://src/hud.gd")
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
	e.mhp = 1000.0
	e.hp = 500.0
	e.born = 0.0
	e.stun = 99.0
	return e
func _init():
	Meta.PATH = "user://rebirth_twist.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.start_run(5, false)
	g.floor_i = 2
	g.new_floor()
	await frames(5)
	var room = null
	for r in g.dg.rooms:
		if r.type == "fight":
			room = r
			break
	room.cleared = true
	var c: Vector2 = g.rc(room)
	g.p.pos = c + Vector2(-70, 20)
	g.p.els = ["fire", "ice", "bolt"]
	g.enemies.clear()

	# ---- eaters ----
	var n = 0
	for i in 400:
		var t = {is_boss = false, elite = false, d = {ai = "walk"}}
		Twist.mark(g, t)
		if t.has("eats"):
			n += 1
			check(g.p.els.has(t.eats) and Twist.EAT.has(t.eat_kind), "an eater eats something you carry")
	check(n > 50 and n < 140, "about a fifth of foes are eaters: %d of 400" % n)
	var e = foe(c)
	e.eats = "fire"
	e.eat_kind = "grow"
	e.eat_n = 3
	var sc0 = e.sc
	g.hurt_enemy(e, 50.0, "fire")
	check(e.hp > 500.0 and e.sc > sc0, "fire feeds a fire-grower: hp %.0f" % e.hp)
	var hp1 = e.hp
	g.hurt_enemy(e, 50.0, "ice")
	check(e.hp < hp1, "another element hurts it")
	g.hurt_enemy(e, 50.0, "fire")
	g.hurt_enemy(e, 50.0, "fire")
	check(not e.has("eats"), "after three meals it is full")
	var hp2 = e.hp
	g.hurt_enemy(e, 50.0, "fire")
	check(e.hp < hp2, "and fire hurts it again")
	g.enemies.clear()
	var s = foe(c)
	s.eats = "ice"
	s.eat_kind = "split"
	s.eat_n = 1
	g.lock = room
	g.hurt_enemy(s, 50.0, "ice")
	await frames(6)
	check(g.enemies.size() == 2 and not s.has("eats") and absf(g.enemies[1].hp - s.hp) < 20.0, "ice splits an ice-splitter in two: %d %s %s" % [g.enemies.size(), str(s.hp), str(g.enemies.map(func(q): return q.hp))])
	g.lock = null
	g.enemies.clear()
	g.fields.clear()
	var h = foe(c)
	h.eats = "fire"
	h.eat_kind = "feed"
	h.eat_n = 6
	Combo.spawn(g, c, "fire+ice")
	g.fields[0].life = 99.0
	h.hp = 300.0
	var low = 300.0
	for k in 40:
		await frames(1)
		low = minf(low, h.hp)
	check(h.hp > low + 60.0, "a feeder heals inside a field of its element: low %.0f now %.0f" % [low, h.hp])
	g.enemies.clear()
	g.fields.clear()

	# ---- boss echo ----
	var b = g.spawn_enemy(g.dg.boss_id, c + Vector2(40, 0))
	b.born = 0.0
	b.stun = 0.0
	g.boss = b
	Combo.spawn(g, g.center(b), "stone+wind")
	Combo.touch(g, g.center(b), "light")
	await frames(5)
	check(b.has("echo") and b.echo.fam == "fan" and g.banner.text.begins_with("IT LEARNS"), "the boss learns the effect that touched it: " + str(b.get("echo", {})))
	g.fields.clear()
	g.bullets.clear()
	b.echo.t = 0.05
	b.stun = 0.0
	b.frz = 0.0
	await frames(6)
	check(g.bullets.filter(func(q): return q.team == 1).size() >= 18, "and casts it back as bullets: %d" % g.bullets.size())
	for fam in ["ring", "fall", "pool"]:
		b.echo.fam = fam
		b.echo.t = 0.01
		b.stun = 0.0
		g.zones.clear()
		await frames(50)
		if fam == "pool":
			check(g.zones.any(func(z): return z.team == 1), "the pool echo leaves an enemy pool")
	g.boss = null
	g.enemies.clear()
	g.bullets.clear()
	g.zones.clear()

	# ---- cursed blessings ----
	g.offer_buffs(true)
	check(g.buff_choices.size() == 4 and g.buff_choices[3].has("curse"), "a fourth, cursed offer")
	check(Hud.buff_rect(3, 4).end.x <= 480.0 and Hud.buff_rect(0, 4).position.x >= 0.0, "four cards fit the sheet")
	g.buff_choices[3] = {id = "vital", name = "IRON HEART X2", desc = "", curse = "waves"}
	var mhp = g.p.mhp
	await frames(12)
	g.pick_buff(3)
	check(g.p.mhp == mhp + 4 and g.curses == ["waves"], "the blessing counts twice and the curse sticks: %d %s" % [g.p.mhp, str(g.curses)])
	var w0 = room.waves
	Twist.lock_room(g, room)
	check(room.waves == w0 + 1, "one more wave")
	g.offer_buffs(true)
	g.buff_choices[3] = {id = "crit", name = "", desc = "", curse = "lock"}
	await frames(12)
	g.pick_buff(3)
	check(g.curse_lock.floor == g.floor_i, "a sealed element for this floor")
	g.p.sat = [1.0, 1.0, 1.0]
	g.p.spent = [false, false, false]
	await frames(3)
	check(g.p.spent[g.curse_lock.slot] and g.p.sat[g.curse_lock.slot] == 0.0, "the sealed slot stays empty")
	g.curse_lock = {}
	g.curses = ["dry"]
	check(not Twist.dry(g), "dry only bites in a boss room")
	g.lock = {type = "boss", id = 99}
	check(Twist.dry(g), "there mana does not return")
	g.lock = null
	g.curses = []

	# ---- shards ----
	var found = false
	for k in 30:
		g.inter = g.inter.filter(func(it): return it.kind != "shard")
		Twist.floor_start(g)
		if g.inter.any(func(it): return it.kind == "shard"):
			found = true
			break
	check(found, "shards turn up")
	var sh = g.inter.filter(func(it): return it.kind == "shard")[0]
	check(not ["fire", "ice", "bolt"].has(sh.el), "a shard is an element you do not carry")
	g.interact(sh)
	check(g.p.els[2] == sh.el and g.p.els_home == ["fire", "ice", "bolt"] and g.p.sat[2] == 1.0, "it replaces the third slot: " + str(g.p.els))
	g.new_floor()
	check(g.p.els == ["fire", "ice", "bolt"] and not g.p.has("els_home"), "until the floor ends")

	# ---- trials ----
	await frames(5)
	room = null
	for r in g.dg.rooms:
		if r.type == "fight":
			room = r
			break
	g.p.pos = g.rc(room)
	room.trial = true
	var rules = {}
	for k in 60:
		Twist.lock_room(g, room)
		rules[room.rule] = true
	check(rules.size() == 3, "three trial rules")
	check(Twist.passed({trial = true, rule = "flawless"}, 0) and not Twist.passed({trial = true, rule = "flawless"}, 1) and Twist.passed({trial = true, rule = "dry"}, 3) and not Twist.passed({trial = false}, 0), "who earns the relic")
	g.enemies.clear()
	var d1 = foe(g.p.pos + Vector2(50, 0))
	g.st.crit = 0.0
	g.lock = room
	room.rule = "restless"
	g.p.hp = g.p.mhp
	g.p.ar = 0
	g.p.inv = 0.0
	var hp0 = g.p.hp
	for k in 80:
		d1.stun = 99.0
		await frames(1)
	check(g.p.hp < hp0, "restless trial: standing still hurts")
	room.rule = "dry"
	check(Twist.dry(g), "drought trial: no mana by itself")
	g.lock = null
	await frames(10)
	print("TWIST OK" if fails == 0 else "TWIST FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
