extends SceneTree
const Meta = preload("res://src/meta.gd")
const Net = preload("res://src/net.gd")
var g
func wait(ms):
	var t = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < ms:
		if g.state == "play" and not g.in_lobby:
			g.players[0].hp = g.players[0].mhp
			if not g.enemies.is_empty():
				g.sim["mouse"] = g.center(g.enemies[0]) - g.cam_tl
		await process_frame
func _init():
	Meta.PATH = "user://rebirth_nethost.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await wait(200)
	g.goto_lobby()
	Net.host(g)
	print("HOST status=", g.net.status)
	var t0 = Time.get_ticks_msec()
	while not g.net.joined and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	print("HOST joined=", g.net.joined, " guest=", g.net.guest.name if g.net.guest != null else "none")
	if not g.net.joined:
		quit(1)
		return
	Net.start(g)
	print("HOST started players=", g.players.size(), " seed=", g.run_seed)
	var gp0 = g.players[1].pos
	g.sim["fire"] = true
	await wait(1500)
	# walk into the first fight room so both sides see enemies
	for r in g.dg.rooms:
		if r.type == "fight":
			g.players[0].pos = g.rc(r) + Vector2(0, 20)
			break
	await wait(5000)
	var own1 = 0
	for b in g.bullets:
		if b.team == 0 and b.get("own", 0) == 1:
			own1 += 1
	print("HOST snapshot bytes=", Net.snapshot(g).size())
	print("HOST guest moved=", snapped(g.players[1].pos.distance_to(gp0), 1.0), " guest bullets now=", own1, " lock=", g.lock != null, " enemies=", g.enemies.size(), " kills=", g.kills)
	g.end_run(false)
	await wait(1500)
	print("HOST done state=", g.state)
	quit(0)
