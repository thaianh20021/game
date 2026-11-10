extends SceneTree
# Local two-player co-op: player two is driven through the same input path a second gamepad uses.
const Meta = preload("res://src/meta.gd")
var g
var fails = 0
var p2_shots = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func step(n = 1):
	for i in n:
		if g.state == "play" and not g.in_lobby and g.players.size() > 1:
			var a = g.players[0]
			var b = g.players[1]
			a.hp = a.mhp
			var f = Engine.get_process_frames()
			var tgt = b.pos + b.aim * 50.0
			if not g.enemies.is_empty():
				g.sim["mouse"] = g.center(g.enemies[0]) - g.cam_tl
				tgt = g.center(g.enemies[0])
			g.sim["fire"] = true
			g.sim_p2 = {mv = (a.pos - b.pos).limit_length(1.0) if a.pos.distance_to(b.pos) > 30.0 else Vector2.ZERO, mw = tgt, fire = true, jp = {}}
			if f % 80 == 0: g.sim_p2.jp["m2"] = true
			if f % 100 == 0: g.sim_p2.jp[KEY_F] = true
			if f % 60 == 0: g.sim_p2.jp[KEY_SPACE] = true
			for bl in g.bullets:
				if bl.team == 0 and bl.get("own", 0) == 1:
					p2_shots += 1
		await process_frame
func _init():
	Meta.PATH = "user://rebirth_test.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await step(5)
	g.goto_lobby()
	await step(5)
	g.set_local2(true)
	check(g.players.size() == 2 and g.players[1].idx == 1, "player two should join in the lobby")
	var h2 = g.players[1].name
	for it in g.inter:
		if it.kind == "gate":
			g.interact(it)
	await step(3)
	check(not g.in_lobby and g.players.size() == 2, "both players should enter the dungeon")
	check(g.players[0].pos.distance_to(g.players[1].pos) < 40.0, "players should start together")
	var revived = false
	var downed = false
	var rooms = g.dg.rooms.filter(func(r): return r.type == "fight")
	for r in rooms:
		g.players[0].pos = g.rc(r) + Vector2(0, 20)
		await step(15)
		check(r.rect.has_point(Vector2i((g.players[1].pos / 16.0).floor())), "player two should be pulled into the locked room")
		if not downed:
			g.bind(g.players[1])
			g.p.mount = null
			g.p.feather = false
			g.p.wind2 = false
			g.p.inv = 0.0
			g.p.dash_t = 0.0
			g.hurt_player(99)
			downed = g.players[1].down
			check(downed and g.state == "play", "player two should go down without ending the run")
		var n = 0
		while not r.cleared and n < 5000 and g.state == "play":
			if n % 45 == 0 and not g.enemies.is_empty():
				for off in [Vector2(14, 0), Vector2(-14, 0), Vector2(0, 14)]:
					if g.box_free(g.enemies[0].pos + off, 4.0):
						g.players[0].pos = g.enemies[0].pos + off
						break
			await step(1)
			n += 1
		check(r.cleared, "room should clear in co-op")
		if downed and not revived:
			revived = not g.players[1].down and g.players[1].hp > 0
			check(revived, "player two should revive when the room is cleared")
	check(p2_shots > 0, "player two should fire bullets of its own")
	for it in g.inter:
		if it.kind == "portal":
			g.interact(it)
	await step(2)
	check(g.state == "buff", "portal should offer a blessing")
	var bid = g.buff_choices[0].id
	g.pick_buff(0)
	await step(3)
	check(g.players[0].buffs.has(bid) and g.players[1].buffs.has(bid), "both players should get the blessing")
	check(g.floor_i == 1 and g.players[1].name == h2, "second floor with the same partner")
	# both down ends the run
	for pl in g.players:
		g.bind(pl)
		pl.mount = null
		pl.inv = 0.0
		pl.feather = false
		pl.wind2 = false
		g.hurt_player(99)
	await step(3)
	check(g.state == "dead", "run should end when both players are down")
	g.goto_lobby()
	await step(3)
	check(g.players.size() == 2, "player two should still be there back in the lobby")
	print("p2 bullet-frames=", p2_shots, " kills=", g.kills)
	print("COOP ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
