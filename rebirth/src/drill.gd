extends RefCounted
# The Training Grounds: one short floor of six fight rooms, each teaching one thing the Hearth
# lesson does not: charging and releasing, pure and trinity, wards, the perfect release, the
# mirror, boss armor and seal. Each room is scripted here instead of by the normal waves; it
# lets you go on once you have done the thing (or after a while, so nobody is stuck). Nobody
# dies here, nothing is saved as a run, and the exit portal leads home.

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")
const Px = preload("res://src/font.gd")

const SEED = 4242
const GIVE_UP = 75.0
# id, title, keyboard text, touch text
const ROOMS = [
	["charge", "CHARGE AND RELEASE", "", ""],
	["shape", "PURE AND TRINITY",
		"THREE CHARGES OF ONE REACTION MAKE A PURE RELEASE. THREE DIFFERENT ONES, A TRINITY. FILL ALL THREE, ARM, DASH.",
		"THREE CHARGES OF ONE REACTION MAKE A PURE RELEASE. THREE DIFFERENT ONES, A TRINITY. FILL ALL THREE, ARM, DASH."],
	["ward", "WARDS",
		"A BLUE RING IS A WARD: IT SHRUGS OFF HITS. ONLY A RELEASE BREAKS IT. BREAK BOTH.",
		"A BLUE RING IS A WARD: IT SHRUGS OFF HITS. ONLY A RELEASE BREAKS IT. BREAK BOTH."],
	["perfect", "PERFECT RELEASE",
		"A RED LINE MEANS A FAST SHOT. WHILE ARMED, DASH THROUGH A SHOT: PERFECT. MORE DAMAGE AND A CHARGE BACK.",
		"A RED LINE MEANS A FAST SHOT. WHILE ARMED, DASH THROUGH A SHOT: PERFECT. MORE DAMAGE AND A CHARGE BACK."],
	["mirror", "THE MIRROR",
		"GOLD ELITES ARE MIRRORS: THEY DRINK YOUR REACTIONS CLOSE BY, AND AT THREE THEY BLAST. KILL IT, OR REACT FAR FROM IT.",
		"GOLD ELITES ARE MIRRORS: THEY DRINK YOUR REACTIONS CLOSE BY, AND AT THREE THEY BLAST. KILL IT, OR REACT FAR FROM IT."],
	["armor", "BOSS ARMOR",
		"BOSSES WEAR ARMOR: ONLY RELEASES BREAK IT, THEN THEY ARE STUNNED. AT HALF HEALTH THEY SEAL: THE ASKED RELEASE BREAKS IT.",
		"BOSSES WEAR ARMOR: ONLY RELEASES BREAK IT, THEN THEY ARE STUNNED. AT HALF HEALTH THEY SEAL: THE ASKED RELEASE BREAKS IT."],
]

static func active(g) -> bool:
	return not g.drill.is_empty() and not g.in_lobby

static func start(g) -> void:
	g.drill = {i = 0, room = -1, t = 0.0, done = false}
	g.start_run(SEED, false)
	g.banner = {text = "TRAINING GROUNDS", sub = "SIX ROOMS, SIX LESSONS. NOBODY DIES HERE.", t = 3.5}

# The current room's lesson, or [] between rooms.
static func lesson(g) -> Array:
	if not active(g) or g.drill.room < 0 or g.drill.room >= ROOMS.size():
		return []
	return ROOMS[g.drill.room]

static func put(g, id: String, pos: Vector2, fn: Callable) -> void:
	g.pending += 1
	g.teles.append({kind = "spawn", pos = pos, t = 0.0, dur = 0.8, r = 7.0})
	g.after(0.8, func():
		g.pending -= 1
		if g.lock == null:
			return
		var e = g.spawn_enemy(id, pos)
		e.mhp *= 1.6
		e.hp = e.mhp
		fn.call(e)
		g.burst(g.center(e), 10, Color("ff5a6a"), 70.0, 0.35))

# Spawns the room's lesson instead of its waves. Returns false outside the grounds.
static func wave(g, r: Dictionary) -> bool:
	if not active(g):
		return false
	if g.drill.i >= ROOMS.size() and r.wave == 0 and not r.has("drill"):
		return false
	if r.wave >= 1:
		return true
	r.drill = true
	r.wave = 1
	r.waves = 1
	g.drill.room = g.drill.i
	g.drill.i += 1
	g.drill.t = 0.0
	g.drill.done = false
	var id: String = ROOMS[g.drill.room][0]
	g.banner = {text = ROOMS[g.drill.room][1], sub = "LESSON %d OF %d" % [g.drill.room + 1, ROOMS.size()], t = 2.4}
	match id:
		"charge", "shape":
			feed(g, r, 3)
		"ward":
			for k in 2:
				put(g, "goblin", g.random_room_pos(r, 60.0), func(e): g.Stage.affix(g, e, "ward"))
		"perfect":
			for k in 2:
				put(g, "goblin", g.random_room_pos(r, 80.0), func(e):
					g.Stage.affix(g, e, "mark")
					e.aim_t = 1.0 + k * 1.2)
		"mirror":
			put(g, "goblin", g.random_room_pos(r, 70.0), func(e):
				e.elite = true
				e.mhp *= 2.0
				e.hp = e.mhp
				e.sc *= 1.3
				e.h2 *= 1.3
				e.hr *= 1.3
				g.Stage.affix(g, e, "mirror"))
			feed(g, r, 2)
		"armor":
			var pos: Vector2 = g.rc(r) + Vector2(0, -34)
			g.pending += 1
			g.tele_circle(pos, 26.0, 1.2)
			g.after(1.2, func():
				g.pending -= 1
				var b = g.spawn_enemy(g.dg.boss_id, pos)
				b.mhp *= 0.35
				b.hp = b.mhp
				b.t = 1.2
				g.boss = b
				Sfx.play("roar"))
	# a fresh hand for every lesson
	if g.p.has("sat"):
		g.p.sat = [1.0, 1.0, 1.0]
		g.p.spent = [false, false, false]
		g.mana_total(g.p)
	return true

static func feed(g, r: Dictionary, n: int) -> void:
	for k in n:
		put(g, "goblin", g.random_room_pos(r, 60.0), func(e): pass)

# True while the room must not clear: the lesson is not done yet.
static func busy(g) -> bool:
	var l = lesson(g)
	return not l.is_empty() and g.lock != null and not g.drill.done and l[0] in ["charge", "shape", "perfect"]

static func passed(g, id: String) -> bool:
	var rs: Dictionary = g.rs
	match id:
		"charge": return int(rs.get("rel", 0)) >= int(g.drill.get("rel0", 0)) + 1
		"shape": return int(rs.get("pure", 0)) + int(rs.get("trinity", 0)) >= 1
		"perfect": return int(rs.get("perf", 0)) >= 1
	return false

static func update(g, dt: float) -> void:
	if not active(g):
		return
	var l = lesson(g)
	if l.is_empty() or g.lock == null:
		g.drill.rel0 = int(g.rs.get("rel", 0))
		return
	if g.drill.done:
		return
	g.drill.t += dt
	var id: String = l[0]
	if passed(g, id) or (g.drill.t > GIVE_UP and busy(g)):
		g.drill.done = true
		g.label(g.p.pos + Vector2(0, -34), "LESSON DONE" if passed(g, id) else "MOVING ON", Color("a6e84e"), true)
		Sfx.play("pick", 1.3)
		g.Stage.sweep(g)
		return
	# a lesson that needs foes keeps some coming
	if id in ["charge", "shape", "perfect"] and g.enemies.is_empty() and g.pending == 0:
		if id == "perfect":
			for k in 2:
				put(g, "goblin", g.random_room_pos(g.lock, 80.0), func(e):
					g.Stage.affix(g, e, "mark")
					e.aim_t = 1.0)
		else:
			feed(g, g.lock, 3)

# Nobody dies in the grounds.
static func spare(g) -> bool:
	if not active(g) or g.p.hp > 0:
		return false
	g.p.hp = g.p.mhp
	g.p.inv = 1.5
	g.label(g.p.pos + Vector2(0, -26), "TRAINING: BACK ON YOUR FEET", Color("a6e84e"), true)
	return true

# The exit portal, or leaving from the pause menu.
static func finish(g, done: bool) -> void:
	g.drill = {}
	if done and not Meta.S.get("drill", false):
		Meta.S["drill"] = true
		Meta.S.gems += 20
		Meta.save()
		g.goto_lobby()
		g.banner = {text = "TRAINING DONE", sub = "+20 GEMS. THE GATE AT THE TOP STARTS A REAL RUN.", t = 4.0}
		return
	g.goto_lobby()

# What to do now, as one line: the charge lesson follows what you have in hand.
static func text(g, l: Array) -> String:
	if l[0] != "charge":
		return l[3] if g.tin.on else g.Pad.hint(g, l[2])
	var p = g.p
	if p.get("inf", []).is_empty():
		return "PAINT ONE FOE WITH TWO DIFFERENT ELEMENTS: THE REACTION CHARGES YOUR WEAPON."
	if float(p.get("inf_arm", 0.0)) <= 0.0:
		return "CHARGED. HOLD THE ELEMENT BUTTON, THEN LET GO: THAT ARMS THE WEAPON." if g.tin.on else g.Pad.hint(g, "CHARGED. HOLD 1 2 3 (OR TAB), THEN LET GO: THAT ARMS THE WEAPON.")
	return "ARMED! DASH AT THE FOES: THE CHARGE BURSTS OUT." if g.tin.on else g.Pad.hint(g, "ARMED! DASH (SPACE) AT THE FOES: THE CHARGE BURSTS OUT.")

static func draw(g, ci: CanvasItem, hud) -> void:
	if not active(g) or g.state != "play":
		return
	var l = lesson(g)
	if l.is_empty() or g.lock == null or g.banner.t > 0.0:
		if g.lock == null and g.drill.i >= ROOMS.size():
			hud.panel(ci, Rect2(150, 60, 180, 16), Color(0.05, 0.03, 0.1, 0.9), Color("a6e84e"))
			Px.ctext(ci, Vector2(240, 65), "ALL DONE: THE PORTAL LEADS HOME", Color("a6e84e"))
		return
	var ok: bool = g.drill.done
	var lines: Array = hud.wrap_text("GOOD. GO ON TO THE NEXT ROOM." if ok else text(g, l), 46)
	var h = 24.0 + lines.size() * 9.0
	var r = Rect2(86, 60, 308, h)
	hud.panel(ci, r, Color(0.05, 0.03, 0.1, 0.92), Color("a6e84e") if ok else Color("5cd3f2"))
	Px.text(ci, r.position + Vector2(6, 5), "%d/%d" % [g.drill.room + 1, ROOMS.size()], Color("6b6779"))
	Px.ctext(ci, Vector2(240, r.position.y + 5), "DONE!" if ok else l[1], Color("a6e84e") if ok else Color("5cd3f2"))
	for k in lines.size():
		Px.ctext(ci, Vector2(240, r.position.y + 17 + k * 9), lines[k], Color("f1ead8"))
	if busy(g) and g.drill.t > GIVE_UP * 0.5:
		Px.ctext(ci, Vector2(240, r.end.y + 3), "STUCK? IT MOVES ON BY ITSELF IN %d S" % int(GIVE_UP - g.drill.t), Color("6b6779"))
