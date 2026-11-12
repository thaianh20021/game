extends SceneTree
# Run without --headless. Writes shots/18_summons.png: the warlock with three ghosts and in Hồn Thể,
# the artificer's turret, drum, bell and mine, the hunter's snare and pot bomb.
const D = preload("res://src/data.gd")
var g

func _init() -> void:
	D.SAVE_PATH = "user://duvang_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await process_frame
	g.new_game()
	g.main_m = 6
	g.recompute()
	g.sim.no_spawns = true
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.enter_zone("field", Vector2(34 * 16, 23 * 16))
	g.mode = "play"
	g.fresh_hero()
	var o = g.p.pos
	g.sim.mouse = o + Vector2(60, 0)
	for i in 3:
		g.add_ghost(o + Vector2(-40 + i * 26, 30), 20.0, false)
	g.ghosts[2].cd = 0.9
	g.p.soulform = 8.0
	for k in ["turret", "drum", "bell", "mine"]:
		var i = ["turret", "drum", "bell", "mine"].find(k)
		g.devices.append({"kind": k, "pos": o + Vector2(50 + i * 30, -10), "t": 20.0, "cd": 9.0, "arm": 0.0, "first": true, "haste_t": 0.0, "free": true, "el": "", "follow": false, "range": 0.0})
	g.traps.append({"kind": "snare", "pos": o + Vector2(60, 30), "arm": 0.0, "t": 999.0, "smoke": false})
	g.traps.append({"kind": "mine", "pos": o + Vector2(90, 30), "arm": 0.0, "t": 999.0, "smoke": false})
	for j in 3:
		await process_frame
	var im = root.get_texture().get_image()
	var c = o - g.cam_tl
	var cut = im.get_region(Rect2i(int(c.x) - 80, int(c.y) - 70, 260, 120))
	cut.resize(cut.get_width() * 3, cut.get_height() * 3, Image.INTERPOLATE_NEAREST)
	cut.save_png(ProjectSettings.globalize_path("res://shots/18_summons.png"))
	quit()
