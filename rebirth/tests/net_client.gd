extends SceneTree
const Meta = preload("res://src/meta.gd")
const Net = preload("res://src/net.gd")
var g
func _init():
	Meta.PATH = "user://rebirth_netclient.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 10: await process_frame
	Meta.S.hero = 2
	g.goto_lobby()
	g.open_menu("coop")
	var t0 = Time.get_ticks_msec()
	while g.net.hosts.is_empty() and Time.get_ticks_msec() - t0 < 6000:
		await process_frame
	print("CLIENT discovered hosts=", g.net.hosts)
	g.set_state("play")
	Net.join(g, "127.0.0.1")
	t0 = Time.get_ticks_msec()
	while g.in_lobby and Time.get_ticks_msec() - t0 < 25000:
		await process_frame
	print("CLIENT status=", g.net.status, " in_lobby=", g.in_lobby, " me=", g.me, " players=", g.players.size())
	if g.in_lobby:
		quit(1)
		return
	var start = g.p.pos
	g.sim[KEY_D] = true
	g.sim["fire"] = true
	g.sim["mouse"] = Vector2(400, 135)
	var max_en = 0
	var max_bul = 0
	var locked = false
	t0 = Time.get_ticks_msec()
	while g.state == "play" and Time.get_ticks_msec() - t0 < 12000:
		max_en = max(max_en, g.enemies.size())
		max_bul = max(max_bul, g.bullets.size())
		locked = locked or g.lock != null
		if Time.get_ticks_msec() - t0 > 1200:
			g.sim.erase(KEY_D)
		await process_frame
	print("CLIENT name=", g.p.name, " moved=", snapped(g.p.pos.distance_to(start), 1.0), " max_enemies=", max_en, " max_bullets=", max_bul, " saw_lock=", locked, " floor_seed=", g.run_seed)
	print("CLIENT end state=", g.state, " gems_won=", g.gems_won)
	quit(0)
