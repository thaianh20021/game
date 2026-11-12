extends SceneTree
# Run without --headless. Writes shots/16_looks.png: every class in game, walking down, up, sideways and striking.
const D = preload("res://src/data.gd")
var g
func _init() -> void:
	D.SAVE_PATH = "user://duvang_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await process_frame
	var classes = [0, 1, 3, 6, 10, 15, 21, 28]
	var W = 80
	var H = 70
	var strip = Image.create_empty(W * 4, H * classes.size(), false, Image.FORMAT_RGBA8)
	for row in classes.size():
		g.new_game()
		g.main_m = classes[row]
		g.recompute()
		for k in g.KEYS:
			g.sim[k] = false
		g.sim.no_spawns = true
		g.enter_zone("field", Vector2(34 * 16, 23 * 16))
		g.mode = "play"
		g.fresh_hero()
		var dirs = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.RIGHT]
		for i in 4:
			g.sim.move = dirs[i] * 0.01 if i < 3 else Vector2.ZERO
			g.sim.mouse = g.p.pos + dirs[i] * 60.0
			g.sim.atk = i == 3
			for j in (6 if i < 3 else 9):
				await process_frame
			var im = root.get_texture().get_image()
			var c = (g.p.pos - g.cam_tl)
			strip.blit_rect(im, Rect2i(int(c.x) - W / 2, int(c.y) - H + 12, W, H), Vector2i(i * W, row * H))
		g.sim.atk = false
		await process_frame
	strip.resize(strip.get_width() * 3, strip.get_height() * 3, Image.INTERPOLATE_NEAREST)
	strip.save_png(ProjectSettings.globalize_path("res://shots/16_looks.png"))
	quit()
