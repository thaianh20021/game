extends RefCounted
# A simple player used by the tests: walk to the nearest foe, strike, dodge warnings.

static func drive(g) -> void:
	var s = g.sim
	s.dodge = false
	s.s1 = false
	var best = null
	var bd = 1e9
	var danger = false
	for f in g.foes:
		if f.state == "dead" or f.state == "spawn":
			continue
		var d = f.pos.distance_to(g.p.pos)
		if d < bd:
			bd = d
			best = f
		if f.state == "wind" and f.st > f.wind - 0.15 and d < 90.0:
			danger = true
	for sh in g.shots:
		if sh.pos.distance_to(g.p.pos) < 28.0:
			danger = true
	if best == null:
		s.move = Vector2.ZERO
		s.atk = false
		return
	s.mouse = best.pos
	var to = (best.pos - g.p.pos).normalized()
	var reach = 30.0 + best.r
	s.move = to if bd > reach else Vector2.ZERO
	s.atk = bd < reach + 12.0
	if danger and not g.prev.get("dodge", false):
		s.dodge = true
		s.move = to.orthogonal()
	if not g.prev.get("s1", false) and bd < reach + 12.0 and g.bar[0] != "" and g.can_cast(g.bar[0]):
		s.s1 = true
