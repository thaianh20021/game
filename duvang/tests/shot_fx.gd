extends SceneTree
# Run without --headless. Writes shots/19_fx.png: drawn bolts of every kind, a fire wall and hit sparks.
const D = preload("res://src/data.gd")
var g
func _init() -> void:
	D.SAVE_PATH = "user://duvang_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await process_frame
	g.new_game()
	g.sim.no_spawns = true
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.enter_zone("field", Vector2(34 * 16, 23 * 16))
	g.mode = "play"
	g.fresh_hero()
	var o = g.p.pos
	g.sim.mouse = o + Vector2(60, 0)
	var kinds = [{}, {"ice": true}, {"dart": true}, {"arrow": true}, {"dev": true, "el": ""}]
	for i in kinds.size():
		var b = {"pos": o + Vector2(40 + i * 28, -30 + i * 6), "vel": Vector2(0.01, 0) .rotated(-0.3 + i * 0.15), "life": 99.0, "hit": [], "mult": 0.0}
		b.merge(kinds[i])
		g.bolts.append(b)
	g.fields.append({"kind": "fire", "a": o + Vector2(-60, 40), "b": o + Vector2(40, 40), "t": 9.0, "tick": 99.0})
	for i in 3:
		g.sparks.append({"pos": o + Vector2(60 + i * 30, 20), "t": 0.1 - i * 0.03, "big": i == 0})
	await process_frame
	await process_frame
	var im = root.get_texture().get_image()
	var c = o - g.cam_tl
	var cut = im.get_region(Rect2i(int(c.x) - 90, int(c.y) - 70, 280, 130))
	cut.resize(cut.get_width() * 3, cut.get_height() * 3, Image.INTERPOLATE_NEAREST)
	cut.save_png(ProjectSettings.globalize_path("res://shots/19_fx.png"))
	quit()
