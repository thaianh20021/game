extends RefCounted
# The first lesson. A new save starts it in the Hearth beside the training dummy: ten small
# steps, each done by actually doing the thing (move, dash, paint, switch, react, storm,
# watch the element bars, skill, burst, go). It can be skipped at any time and replayed
# from Settings. Nothing here changes the rules: it only watches and tells.

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")
const Px = preload("res://src/font.gd")

# id, title, keyboard text, touch text
const STEPS = [
	["move", "MOVE", "WASD TO WALK. MOUSE TO AIM.", "LEFT STICK TO WALK."],
	["dash", "DASH", "SPACE TO DASH. NOTHING CAN HIT YOU WHILE YOU DASH.", "DASH BUTTON. NOTHING CAN HIT YOU WHILE YOU DASH."],
	["paint", "PAINT", "LMB: HIT THE DUMMY. YOUR WEAPON DOES NOT KILL, IT PAINTS AN ELEMENT.", "HOLD THE FIRE STICK NEAR THE DUMMY. YOUR WEAPON PAINTS AN ELEMENT."],
	["switch", "SWITCH", "1 2 3 PICK ONE OF YOUR THREE ELEMENTS. PICK ANOTHER NOW.", "THE BIG ELEMENT BUTTON BY THE FIRE STICK PICKS THE NEXT ELEMENT."],
	["react", "REACT", "PAINT THE DUMMY WITH TWO DIFFERENT ELEMENTS. THEY REACT AND LEAVE A FIELD.", "PAINT THE DUMMY WITH TWO DIFFERENT ELEMENTS. THEY REACT AND LEAVE A FIELD."],
	["storm", "STORM", "NOW A THIRD ELEMENT INTO THAT FIELD. THREE MAKE A STORM. STORMS DO THE KILLING.", "NOW A THIRD ELEMENT INTO THAT FIELD. THREE MAKE A STORM. STORMS DO THE KILLING."],
	["bars", "ROTATE", "THE BAR UNDER EACH ELEMENT DRAINS AS YOU PAINT AND REFILLS AS IT RESTS. KEEP SWITCHING.", "THE RING ON THE ELEMENT BUTTON DRAINS AS YOU PAINT AND REFILLS AS IT RESTS. KEEP SWITCHING."],
	["skill", "SKILL", "RMB AND F ARE YOUR HERO'S SKILLS. USE ONE.", "BUTTONS 1 AND 2 ARE YOUR HERO'S SKILLS. USE ONE."],
	["burst", "BURST", "REACTIONS FILL THE BURST BAR. IT IS FULL NOW: PRESS R.", "REACTIONS FILL THE BURST BAR. IT IS FULL NOW: PRESS R."],
	["go", "DESCEND", "CRYSTALS CHOOSE YOUR THREE ELEMENTS. THE GATE AT THE TOP STARTS A RUN. GOOD LUCK.", "CRYSTALS CHOOSE YOUR THREE ELEMENTS. THE GATE AT THE TOP STARTS A RUN. GOOD LUCK."],
]
const SKIP = Rect2(196, 110, 88, 12)

static func active(g) -> bool:
	return not g.tut.is_empty()

static func wanted(g) -> bool:
	if Meta.S.get("tut", false) or g.net.mode != "" or g.players.size() > 1:
		return false
	# test runs have no window: they ask for the lesson explicitly
	return DisplayServer.get_name() != "headless" or g.sim.has("tutor")

static func dummy(g):
	for e in g.enemies:
		if e.id == "dummy" and not e.dead:
			return e
	return null

static func start(g) -> void:
	var d = dummy(g)
	if d == null or g.p.is_empty():
		return
	g.p.pos = d.pos + Vector2(-56, 8)
	g.tut = {i = 0, t = 0.0, good = 0.0, walked = 0.0, last = g.p.pos, eli = int(g.p.get("eli", 0)), hits = g.dummy_hits}
	g.banner.t = 0.0
	Sfx.play("pick")

static func finish(g, skipped: bool) -> void:
	g.tut = {}
	if not Meta.S.get("tut", false):
		Meta.S["tut"] = true
		if not skipped:
			Meta.S.gems += 10
			g.banner = {text = "LESSON LEARNED", sub = "+10 GEMS. THE GATE IS AT THE TOP OF THE HEARTH.", t = 4.0}
		Meta.save()
	Sfx.play("chest" if not skipped else "ui")

static func done(g, id: String) -> bool:
	var t = g.tut
	var p = g.p
	match id:
		"move": return t.walked > 70.0
		"dash": return p.dash_t > 0.0
		"paint": return g.dummy_hits >= int(t.hits) + 3
		"switch": return int(p.get("eli", 0)) != int(t.eli)
		"react": return not g.fields.is_empty()
		"storm": return g.fields.any(func(f): return int(f.tier) >= 3)
		"bars": return t.t > 7.0 or (p.has("spent") and p.spent.has(true))
		"skill": return p.skill_cd > 0.0 or p.skill2_cd > 0.0
		"burst": return t.t > 0.5 and p.res < 0.5
		"go": return t.t > 7.0
	return false

static func update(g, dt: float) -> void:
	if not active(g):
		return
	if not g.in_lobby or g.p.is_empty():
		g.tut = {}
		return
	var t = g.tut
	if g.jpk(KEY_BACKSPACE) or (g.jpk("m1") and SKIP.has_point(g.mouse())) or Input.is_joy_button_pressed(maxi(0, g.Pad.device_for(g, 0)), JOY_BUTTON_BACK):
		finish(g, true)
		return
	t.t += dt
	t.walked += g.p.pos.distance_to(t.last)
	t.last = g.p.pos
	if t.good > 0.0:
		t.good -= dt
		if t.good <= 0.0:
			t.i += 1
			t.t = 0.0
			t.eli = int(g.p.get("eli", 0))
			t.hits = g.dummy_hits
			if t.i >= STEPS.size():
				finish(g, false)
				return
			if STEPS[t.i][0] == "burst":
				g.p.res = 1.0
			if STEPS[t.i][0] == "skill":
				g.p.skill_cd = 0.0
				g.p.skill2_cd = 0.0
		return
	if done(g, STEPS[t.i][0]):
		t.good = 0.7
		Sfx.play("pick", 1.3)
		g.rings.append({pos = g.pcenter(), r = 18.0, t = 0.0, col = Color("a6e84e")})

static func draw(g, ci: CanvasItem, hud) -> void:
	if not active(g) or g.state != "play":
		return
	var t = g.tut
	var st = STEPS[t.i]
	var ok: bool = t.good > 0.0
	var text: String = st[3] if g.tin.on else g.Pad.hint(g, st[2])
	var lines: Array = hud.wrap_text(text, 46)
	var h = 24.0 + lines.size() * 9.0
	var r = Rect2(120, 60, 240, h)
	hud.panel(ci, r, Color(0.05, 0.03, 0.1, 0.92), Color("a6e84e") if ok else Color("ffd24a"))
	Px.text(ci, r.position + Vector2(6, 5), "LESSON %d OF %d" % [t.i + 1, STEPS.size()], Color("6b6779"))
	Px.ctext(ci, Vector2(240, r.position.y + 5), "GOOD!" if ok else st[1], Color("a6e84e") if ok else Color("ffd24a"))
	for k in lines.size():
		Px.ctext(ci, Vector2(240, r.position.y + 17 + k * 9), lines[k], Color("f1ead8"))
	for k in STEPS.size():
		ci.draw_rect(Rect2(r.end.x - 6 - (STEPS.size() - k) * 5, r.position.y + 6, 3, 3), Color("a6e84e") if k < t.i or (k == t.i and ok) else (Color("ffd24a") if k == t.i else Color("3a3346")))
	var sk = Rect2(SKIP.position.x, r.end.y + 2, SKIP.size.x, SKIP.size.y)
	Px.ctext(ci, Vector2(240, sk.position.y + 2), "TAP HERE TO SKIP" if g.tin.on else ("BACK TO SKIP" if g.p1_pad else "BACKSPACE TO SKIP"), Color("6b6779"))
	# an arrow over the dummy while a step needs it
	if st[0] in ["paint", "react", "storm"]:
		var d = dummy(g)
		if d != null:
			var at: Vector2 = d.pos - g.cam_tl - g.hud_off + Vector2(0, -30.0 + sin(g.time * 6.0) * 2.0)
			for k in 4:
				ci.draw_rect(Rect2(at.x - 3 + k, at.y + k, 7 - k * 2, 1), Color("ffd24a"))
			ci.draw_rect(Rect2(at.x - 1, at.y - 5, 3, 5), Color("ffd24a"))
