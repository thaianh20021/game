extends SceneTree
# boots the game, waits for the music thread, checks the right track plays in each place
const D = preload("res://src/data.gd")
func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_music.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	var t0 = Time.get_ticks_msec()
	for i in 3:
		await process_frame
	print("boot frames took %d ms" % (Time.get_ticks_msec() - t0))
	g.mode = "play"
	while g.Sfx.tracks.size() < 4 and Time.get_ticks_msec() - t0 < 90000:
		await process_frame
	print("tracks ready after %d ms" % (Time.get_ticks_msec() - t0))
	await process_frame
	var a = g.Sfx.cur_track
	g.enter_zone("field", Vector2.ZERO)
	await process_frame
	var b = g.Sfx.cur_track
	g.sim.no_spawns = true
	g.enter_zone("dungeon", Vector2.ZERO)
	await process_frame
	var c = g.Sfx.cur_track
	var f = g.spawn("keeper", g.p.pos + Vector2(60, 0))
	f.state = "chase"
	await process_frame
	await process_frame
	var d = g.Sfx.cur_track
	f.state = "dead"
	await process_frame
	await process_frame
	var e = g.Sfx.cur_track
	print("town %d, marsh %d, dungeon %d, boss fight %d, after %d" % [a, b, c, d, e])
	print("RESULT: %s" % ("OK" if [a, b, c, d, e] == [0, 1, 2, 3, 2] else "FAILED"))
	quit()
