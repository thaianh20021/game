extends RefCounted
# Systems layered on the core game: skills, pets, mounts, elemental burst,
# weapon workshop (upgrade / transmute / fusion) and the second set of bosses.
# Every function takes the game node as g.

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")

# ---- weapons ---------------------------------------------------------------------

static func wdmg(w: Dictionary) -> float:
	return 1.0 + 0.25 * int(w.get("lv", 0))

static func wname(w: Dictionary) -> String:
	var s = ""
	if int(w.get("lv", 0)) > 0:
		s = "+%d " % int(w.lv)
	var el2 = w.get("el2", "")
	if el2 != "":
		s += D.EL_NAME[w.el] + "-" + D.EL_NAME[el2] + " "
	else:
		s += D.EL_PREFIX[w.el]
	return s + D.WEAPONS[w.id].name

static func station_cost(g, it: Dictionary) -> int:
	var w = g.p.weapons[g.p.wi]
	match it.kind:
		"smith": return 18 + 14 * int(w.get("lv", 0))
		"alch": return 15
		"fuse": return 30
	return 0

static func _pay(g, cost: int) -> bool:
	if g.p.gold < cost:
		Sfx.play("deny")
		g.label(g.p.pos + Vector2(0, -22), "NOT ENOUGH GOLD", Color("ff6a6a"))
		return false
	g.p.gold -= cost
	return true

static func station(g, it: Dictionary) -> void:
	var p = g.p
	var w = p.weapons[p.wi]
	var at = p.pos + Vector2(0, -22)
	match it.kind:
		"smith":
			if int(w.get("lv", 0)) >= 5:
				g.label(at, "ALREADY PERFECT", Color("d9d4c7"))
				return
			if not _pay(g, station_cost(g, it)):
				return
			w.lv = int(w.get("lv", 0)) + 1
		"alch":
			if not _pay(g, 15):
				return
			var opts = []
			for el in D.EL:
				if el != w.el and el != w.get("el2", ""):
					opts.append(el)
			w.el = opts[g.rng.randi() % opts.size()]
		"fuse":
			var o = p.weapons[1 - p.wi]
			if o == null:
				Sfx.play("deny")
				g.label(at, "NEEDS TWO WEAPONS", Color("ff6a6a"))
				return
			if not _pay(g, 30):
				return
			var els = []
			for k in [w.el, w.get("el2", ""), o.el, o.get("el2", "")]:
				if k != "" and k != "prism" and not els.has(k):
					els.append(k)
			var id = w.id if D.WEAPONS[w.id].rar >= D.WEAPONS[o.id].rar else o.id
			var res = {id = id, el = els[0] if els.size() > 0 else "", el2 = els[1] if els.size() > 1 else "",
				lv = mini(5, maxi(int(w.get("lv", 0)), int(o.get("lv", 0))) + 1)}
			p.weapons = [res, null]
			p.wi = 0
			w = res
			g.rings.append({pos = it.pos, r = 50.0, t = 0.0, col = Color("e58cff")})
	Sfx.play("chest")
	g.burst(it.pos + Vector2(0, -8), 16, D.EL_COL[w.el], 90.0, 0.5)
	g.flash(it.pos, 70.0, D.EL_COL[w.el], 0.4)
	g.label(at, wname(w), D.EL_COL[w.el])

# ---- skills ----------------------------------------------------------------------

static func hit(g, e: Dictionary, dmg: float, el: String, kb: Vector2) -> void:
	g.hurt_enemy(e, dmg * g.p.sk.dmg, el, kb)
	if g.p.sk.attune and el != "" and not e.dead:
		g.apply_el(e, el, 0.0)

static func add_zone(g, pos: Vector2, r: float, el: String, life: float, extra: Dictionary = {}) -> void:
	zone_touch(g, pos, r, el)
	var z = {pos = pos, r = r, el = el, life = life, team = 0, tick = 0.3}
	for k in extra:
		z[k] = extra[k]
	g.zones.append(z)

# A player-made element pool hit by a different element detonates as that reaction.
static func zone_touch(g, pos: Vector2, r: float, el: String) -> void:
	if el == "":
		return
	for z in g.zones:
		if z.team != 0 or z.el == "" or z.el == el or z.life <= 0.0:
			continue
		if z.pos.distance_to(pos) < z.r + r:
			z.life = 0.0
			var pair = [el, z.el]
			pair.sort()
			var info = D.REACT[pair[0] + "+" + pair[1]]
			g.label(z.pos + Vector2(0, -14), info[0], info[1], true)
			Sfx.play("react")
			g.charge_res(0.5)
			g.explode(z.pos, z.r + 22.0, (9.0 + g.floor_i * 3.0) * g.st.react * 1.2, "", 0, info[1])
			return

static func cast(g, slot: int, mw: Vector2) -> void:
	var p = g.p
	var key = "skill_cd" if slot == 0 else "skill2_cd"
	if p[key] > 0.0:
		return
	var id: String = p.skills[slot]
	var el: String = g.cur_el()
	p[key] = D.SKILLS[id].cd * p.sk.cdm
	Sfx.play("skill")
	g.label(p.pos + Vector2(0, -24), D.SKILLS[id].name, D.EL_COL[el])
	do_skill(g, id, mw, el)
	if (slot == 0 and p.sk.twice) or (slot == 1 and p.sk.echo):
		g.after(0.5, func(): do_skill(g, id, g.mouse() + g.cam_tl, el))
	if p.sk.siphon:
		p.en = minf(p.men, p.en + 15.0)
	if p.sk.fleet:
		p.haste_t = 2.0
	if p.sk.guard:
		p.inv = maxf(p.inv, 0.6)
		p.ar = min(p.mar, p.ar + 1)
	if p.sk.spark:
		g.charge_res(0.6)
	if p.sk.pack and p.pet != null:
		for i in 6:
			g.add_bullet(p.pet.pos + Vector2(0, -3), Vector2.from_angle(i / 6.0 * TAU) * 220.0, {dmg = 3.0 + g.floor_i, el = Meta.PETS[p.pet.id].el, r = 2.0, life = 0.6})
	if p.sk.residue and el != "":
		add_zone(g, p.pos, 24.0, el, 3.0)

static func do_skill(g, id: String, mw: Vector2, el: String) -> void:
	var p = g.p
	var sk = p.sk
	var col: Color = D.EL_COL[el]
	var pc: Vector2 = g.pcenter()
	var fl: int = g.floor_i
	match id:
		"whirl":
			p.spin = 0.7
			p.spin_tick = 0.0
			p.inv = maxf(p.inv, 0.3)
		"nova":
			for e in g.enemies:
				if e.dead:
					continue
				var d = g.center(e) - pc
				if d.length() < 66.0 * sk.area:
					hit(g, e, 8.0 + fl * 2.0, el, d.normalized() * 170.0)
			for i in 20:
				g.add_bullet(pc, Vector2.from_angle(i / 20.0 * TAU) * 125.0,
					{dmg = (4.0 + fl) * sk.dmg, el = el, life = 0.9 * sk.area, pierce = 2, r = 3.0, attune = sk.attune})
			g.rings.append({pos = pc, r = 70.0 * sk.area, t = 0.0, col = col})
			g.flash(pc, 120.0, col, 0.35)
			g.shake_add(5.0)
		"volley":
			var n = 9 if sk.area > 1.0 else 7
			for k in 3:
				g.after(k * 0.12, func():
					var c = g.pcenter()
					for i in n:
						g.add_bullet(c + g.p.aim * 6.0, Vector2.from_angle(g.p.aim.angle() + (i - (n - 1) / 2.0) * 0.11) * 330.0,
							{dmg = (6.0 + fl) * sk.dmg, el = el, pierce = 2 + g.st.pierce, kind = "arrow", bounce = g.st.bounce, attune = sk.attune})
					Sfx.play("shoot")
					g.shake_add(2.0))
		"blink":
			var d = mw - p.pos
			var rg = 125.0 * sk.area
			if d.length() > rg:
				d = d.normalized() * rg
			var dest: Vector2 = p.pos
			for i in 26:
				var cand = p.pos + d * (1.0 - i / 26.0)
				if g.box_free(cand, p.r):
					dest = cand
					break
			for e in g.enemies:
				if e.dead:
					continue
				var c = g.center(e)
				if Geometry2D.get_closest_point_to_segment(c, p.pos, dest).distance_to(c) < e.hr + 12.0 * sk.area:
					hit(g, e, 14.0 + fl * 3.0, el, d.normalized() * 60.0)
			g.bolts.append({a = pc, b = dest + Vector2(0, -3), col = col, t = 0.2, straight = true})
			g.burst(p.pos, 12, Color("9352cb"), 70.0, 0.4)
			p.pos = dest
			g.burst(p.pos, 12, col, 70.0, 0.4)
			p.inv = maxf(p.inv, 0.5)
			g.flash(dest, 70.0, col, 0.3)
		"bulwark":
			p.shield_t = 2.4 * sk.area
			g.rings.append({pos = pc, r = 30.0, t = 0.0, col = col})
			g.flash(pc, 80.0, col, 0.3)
		"rift":
			var d = mw - p.pos
			if d.length() > 130.0:
				d = d.normalized() * 130.0
			add_zone(g, p.pos + d, 30.0 * sk.area, el, 2.8, {pull = 85.0 * sk.area, sdmg = 2.5 * sk.dmg + fl})
			g.flash(p.pos + d, 90.0, col, 0.4)
		"mines":
			for i in 3:
				var to = mw + Vector2.from_angle(i * TAU / 3.0 + 0.5) * 22.0
				var d = to - p.pos
				if d.length() > 150.0:
					to = p.pos + d.normalized() * 150.0
				g.bullets.append({lob = true, pos = pc, from = pc, to = to, t = 0.0, dur = 0.45 + i * 0.08, z = 0.0, team = 0,
					dmg = (10.0 + fl * 2.0) * sk.dmg, el = el, aoe = 30.0 * sk.area, puddle = true, dead = false, r = 3.0, kind = "orb", age = 0.0, vel = Vector2.ZERO})
		"transmute":
			for e in g.enemies:
				if e.dead:
					continue
				var d = g.center(e) - pc
				if d.length() < 80.0 * sk.area:
					hit(g, e, 5.0 + fl, el, Vector2.ZERO)
					if not e.dead:
						# force a second, different element so whatever is on the foe reacts
						var other: String = D.EL[g.rng.randi() % 4]
						if other == el:
							other = D.WEAK[other]
						e.react_cd = 0.0
						g.apply_el(e, other, 0.0)
			g.rings.append({pos = pc, r = 80.0 * sk.area, t = 0.0, col = Color("e58cff")})
			g.flash(pc, 130.0, Color("e58cff"), 0.35)
		"elixir":
			p.en = minf(p.men, p.en + 50.0)
			p.ar = min(p.mar, p.ar + 2)
			p.noregen = 0.0
			p.slow = 0.0
			g.burst(pc, 16, Color("7adfff"), 60.0, 0.6, -60.0)
			g.flash(pc, 70.0, Color("7adfff"), 0.3)
			if el != "":
				add_zone(g, p.pos, 28.0 * sk.area, el, 4.0)
		"leap":
			var d = mw - p.pos
			if d.length() > 110.0 * sk.area:
				d = d.normalized() * 110.0 * sk.area
			var dest: Vector2 = p.pos
			for i in 22:
				var cand = p.pos + d * (1.0 - i / 22.0)
				if g.box_free(cand, p.r):
					dest = cand
					break
			g.burst(p.pos, 8, Color("a8a7b8"), 60.0, 0.3)
			p.pos = dest
			p.inv = maxf(p.inv, 0.5)
			g.explode(dest, 44.0 * sk.area, (12.0 + fl * 3.0) * sk.dmg, el, 0)
		"rage":
			p.rage_t = 5.0 * sk.area
			g.rings.append({pos = pc, r = 34.0, t = 0.0, col = Color("d43b42")})
			g.flash(pc, 90.0, Color("d43b42"), 0.4)
			Sfx.play("roar", 1.5, -4.0)
		"knives":
			for i in 16:
				g.add_bullet(pc, Vector2.from_angle(p.aim.angle() + i / 16.0 * TAU) * 300.0,
					{dmg = (5.0 + fl) * sk.dmg, el = el, pierce = 1, kind = "arrow", life = 0.5 * sk.area, attune = sk.attune})
			g.rings.append({pos = pc, r = 40.0, t = 0.0, col = col})
			g.shake_add(3.0)

static func whirl_tick(g) -> void:
	var p = g.p
	var el: String = g.cur_el()
	var pc: Vector2 = g.pcenter()
	var rg = 34.0 * p.sk.area
	for e in g.enemies:
		if e.dead:
			continue
		var d = g.center(e) - pc
		if d.length() < rg + e.hr:
			hit(g, e, 4.0 + g.floor_i, el, d.normalized() * 120.0)
	for b in g.bullets:
		if b.team == 1 and not b.lob and b.pos.distance_to(pc) < rg + 4.0:
			b.dead = true
			g.burst(b.pos, 3, Color.WHITE, 60.0, 0.2)
	for pr in g.props:
		if pr.pos.distance_to(pc) < rg + 2.0:
			g.hurt_prop(pr, 4.0)
	g.slashes.append({pos = pc, ang = g.time * 28.0, arc = 4.5, r = rg, t = 0.0, col = D.EL_COL[el]})
	Sfx.play("slash", 1.2, -4.0)

# Bulwark: while the shield is up, enemy bullets that touch it are sent back.
static func shield_tick(g) -> void:
	var pc: Vector2 = g.pcenter()
	for b in g.bullets:
		if b.team == 1 and not b.lob and not b.dead and b.pos.distance_to(pc) < 20.0:
			b.team = 0
			b.vel = -b.vel * 1.4
			b.dmg = 6.0 + g.floor_i * 2.0
			b.life = 1.5
			b.hit = []
			g.burst(b.pos, 3, Color.WHITE, 60.0, 0.2)

# Elemental burst: spend a full resonance bar to hit everything on screen with every
# element you carry, which sets off reactions everywhere at once.
static func burst(g) -> void:
	var p = g.p
	if p.res < 1.0:
		return
	p.res = 0.0
	var els = []
	for w in p.weapons:
		if w != null:
			for k in [w.el, w.get("el2", "")]:
				if k != "" and k != "prism" and not els.has(k):
					els.append(k)
	if p.pet != null and not els.has(Meta.PETS[p.pet.id].el):
		els.append(Meta.PETS[p.pet.id].el)
	if els.is_empty():
		els = [D.EL[g.rng.randi() % 4]]
	var pc: Vector2 = g.pcenter()
	Sfx.play("react", 0.7)
	Sfx.play("boom")
	g.label(p.pos + Vector2(0, -30), "ELEMENTAL BURST", D.EL_COL[els[0]], true)
	g.flash(pc, 420.0, Color.WHITE, 0.5)
	g.rings.append({pos = pc, r = 200.0, t = 0.0, col = D.EL_COL[els[0]]})
	g.shake_add(8.0)
	g.hitstop = maxf(g.hitstop, 0.08)
	for e in g.enemies.duplicate():
		if e.dead or not g.on_screen(e.pos):
			continue
		g.bolt(pc, g.center(e), D.EL_COL[els[0]])
		g.hurt_enemy(e, 8.0 + g.floor_i * 3.0, els[0])
		for k in range(1, els.size()):
			if not e.dead:
				g.apply_el(e, els[k], 0.0)
	for b in g.bullets:
		if b.team == 1:
			b.dead = true

# ---- pets & mounts ---------------------------------------------------------------

static func update_pet(g, dt: float) -> void:
	var p = g.p
	if p.pet == null:
		return
	var pet = p.pet
	var target = p.pos + Vector2(-16.0 * p.face, 8.0)
	if pet.pos.distance_to(target) > 160.0:
		pet.pos = target
	pet.moving = pet.pos.distance_to(target) > 6.0
	pet.pos = pet.pos.lerp(target, minf(1.0, dt * 4.0))
	pet.t -= dt
	if pet.t <= 0.0:
		var e = g.nearest_enemy(pet.pos, 110.0, [])
		if e != null:
			pet.t = 0.55 if p.buffs.has("pack") else 1.1
			var dir = (g.center(e) - pet.pos).normalized()
			pet.face = 1 if dir.x >= 0.0 else -1
			g.add_bullet(pet.pos + Vector2(0, -3), dir * 230.0, {dmg = 2.0 + g.floor_i * 0.8, el = Meta.PETS[pet.id].el, r = 2.0, life = 0.7, pierce = 2 if p.syn.has("beastlord") else 0})
		else:
			pet.face = p.face

static func mount_dash(g) -> void:
	var p = g.p
	if p.mount.id == "boar":
		var pc: Vector2 = g.pcenter()
		for e in g.enemies:
			if e.dead or p.dash_hit.has(e.uid):
				continue
			var d = g.center(e) - pc
			if d.length() < 16.0 + e.hr:
				p.dash_hit.append(e.uid)
				g.hurt_enemy(e, 6.0 + g.floor_i * 2.0, "", d.normalized() * 220.0)
				g.shake_add(3.0)
	elif g.rng.randf() < 0.4:
		add_zone(g, p.pos, 11.0, "bolt", 1.6)

# ---- second boss set -------------------------------------------------------------

static func boss(g, e: Dictionary, rage: bool, dir: Vector2) -> void:
	match e.d.boss:
		3: _queen(g, e, rage)
		4: _iron(g, e, rage, dir)
		5: _void(g, e, rage)

static func _queen(g, e: Dictionary, rage: bool) -> void:
	match e.atk:
		0:
			var tp: Vector2 = g.p.pos
			if g.lock != null:
				var rc: Rect2i = g.lock.rect.grow(-2)
				tp = tp.clamp(Vector2(rc.position) * 16.0, Vector2(rc.end) * 16.0)
			g.tele_circle(tp, 42.0, 0.8)
			e.state = "hop"
			e.t = 0.8
			e.hop_from = e.pos
			e.hop_to = tp
		1:
			e.t = 1.2
			if g.enemies.size() < 7 and g.lock != null:
				for i in (4 if rage else 3):
					g.spawn_tele("slime", g.random_room_pos(g.lock, 50.0))
				Sfx.play("roar", 1.5, -4.0)
		2:
			var n = 10 if rage else 7
			e.t = n * 0.22 + 1.0
			for i in n:
				g.after(i * 0.22, func():
					if e.dead:
						return
					var tp = g.p.pos + Vector2(g.rng.randf_range(-50, 50), g.rng.randf_range(-50, 50))
					g.tele_circle(tp, 20.0, 0.8)
					g.after(0.8, func():
						g.explode(tp, 20.0, 1.0, "tox", 1)
						g.zones.append({pos = tp, r = 18.0, el = "tox", life = 3.5, team = 1, tick = 0.5})))

static func _iron(g, e: Dictionary, rage: bool, dir: Vector2) -> void:
	match e.atk:
		0:
			var n = 44
			var arms = 5 if rage else 4
			var base = g.rng.randf() * TAU
			e.t = n * 0.08 + 0.6
			for i in n:
				g.after(i * 0.08, func():
					if e.dead:
						return
					for a in arms:
						g.ebullet(g.center(e), Vector2.from_angle(base + i * 0.17 + a * TAU / arms) * 90.0, "bolt"))
		1:
			var n = 6 if rage else 4
			e.t = n * 0.4 + 0.7
			for k in n:
				g.after(k * 0.4, func():
					if e.dead:
						return
					g.fan(g.center(e), g.aim_dir(g.center(e), 150.0, 1), 3, 0.3, 150.0, "bolt")
					Sfx.play("shoot_bolt"))
		2:
			e.dir = dir
			e.face = 1 if dir.x > 0.0 else -1
			g.teles.append({kind = "line", pos = e.pos, to = e.pos + dir * 220.0, t = 0.0, dur = 0.7, r = 0.0})
			e.state = "aim"
			e.t = 0.7
			Sfx.play("roar", 1.3, -4.0)
		3:
			var n = 10 if rage else 8
			e.t = 1.8
			var c: Vector2 = g.p.pos
			for i in n:
				var tp = c + Vector2.from_angle(i * TAU / n) * 52.0
				g.tele_circle(tp, 15.0, 0.9)
				g.after(0.9, func():
					if not e.dead:
						g.explode(tp, 15.0, 2.0, "bolt", 1))

static func _void(g, e: Dictionary, rage: bool) -> void:
	match e.atk:
		0:
			e.t = 1.2
			g.burst(g.center(e), 16, Color("55307f"), 90.0, 0.4)
			var cand = g.p.pos - g.p.aim * 46.0
			if g.box_free(cand, e.r):
				e.pos = cand
			g.burst(g.center(e), 16, Color("d43b42"), 90.0, 0.4)
			g.after(0.35, func():
				if not e.dead:
					g.fan(g.center(e), (g.pcenter() - g.center(e)).normalized(), 9 if rage else 7, 1.2, 130.0, ""))
		1:
			e.t = 1.0
			if g.enemies.size() < 6 and g.lock != null:
				for i in (3 if rage else 2):
					g.spawn_tele("shade", g.random_room_pos(g.lock, 50.0))
				Sfx.play("roar", 1.6, -4.0)
		2:
			var n = 18 if rage else 14
			e.t = 2.4
			var c: Vector2 = g.p.pos
			g.tele_circle(c, 110.0, 0.6)
			g.after(0.6, func():
				if e.dead:
					return
				var off = g.rng.randf() * TAU
				for i in n:
					var q = c + Vector2.from_angle(off + i * TAU / n) * 110.0
					g.add_bullet(q, (c - q).normalized() * 58.0, {team = 1, el = "", r = 3.0, life = 2.4, ghost = true}))
		3:
			var n = 9 if rage else 6
			e.t = n * 0.2 + 0.8
			for i in n:
				g.after(i * 0.2, func():
					if e.dead:
						return
					g.ebullet(g.center(e), g.aim_dir(g.center(e), 210.0, 1) * 210.0, "ice")
					Sfx.play("shoot_ice"))
