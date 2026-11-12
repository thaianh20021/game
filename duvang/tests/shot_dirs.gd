extends SceneTree
# Run without --headless. Writes shots/15_dirs.png: the hero walking down, up and sideways, and marks on a foe.
const D = preload("res://src/data.gd")
var g
func _init() -> void:
	D.SAVE_PATH = "user://duvang_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await process_frame
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.no_spawns = true
	g.enter_zone("field", Vector2(34 * 16, 23 * 16))
	g.mode = "play"
	g.fresh_hero()
	var f = g.spawn("porter", g.p.pos + Vector2(70, 10))
	f.cd = 999.0
	f.state = "rec"
	f.st = -999.0
	for mk in ["burn", "chill", "shock"]:
		g.mark(f, mk)
	var strip = Image.create_empty(120 * 3, 110, false, Image.FORMAT_RGBA8)
	var dirs = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT]
	for i in 3:
		g.sim.move = dirs[i] * 0.01
		g.sim.mouse = g.p.pos + dirs[i] * 60.0
		for j in 6:
			await process_frame
		var im = root.get_texture().get_image()
		var c = (g.p.pos - g.cam_tl)
		strip.blit_rect(im, Rect2i(int(c.x) - 30, int(c.y) - 80, 120, 110), Vector2i(i * 120, 0))
	strip.resize(strip.get_width() * 3, strip.get_height() * 3, Image.INTERPOLATE_NEAREST)
	strip.save_png(ProjectSettings.globalize_path("res://shots/15_dirs.png"))
	quit()
