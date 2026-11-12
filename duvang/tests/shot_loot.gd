extends SceneTree
# Run without --headless. Writes shots/13_loot.png and 14_filter.png.
const D = preload("res://src/data.gd")
var g

func shot(n: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + n + ".png"))

func _init() -> void:
	D.SAVE_PATH = "user://duvang_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await process_frame
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.sim.mouse = g.p.pos + Vector2(40, 0)
	seed(11)
	g.lvl = 9
	g.gold = 240
	g.eq.weapon = D.make_item("weapon", 1, 1, 0)
	g.eq.armor = D.make_item("armor", 1, 0, 1)
	g.inv = [D.make_item("weapon", 1, 2, 2), D.make_item("weapon", 2, 1, 1), D.elite_unique("volatile"), D.make_item("charm", 2, 2, 1),
		D.make_item("armor", 0, 0), D.toll_box(), D.make_item("weapon", 0, 1, 1), D.elite_unique("warding"), D.make_item("charm", 0, 0)]
	g.recompute()
	g.open_inv(false)
	g.sim.ui_mouse = g.Ui.bag_cell(g.get_viewport_rect().size, 0).get_center()
	await shot("13_loot")
	g.mode = "play"
	g.sim.no_spawns = true
	g.enter_zone("field", Vector2(34 * 16, 23 * 16))
	g.fresh_hero()
	g.mode = "play"
	g.loot_filter = 1
	var offs = [Vector2(-70, -20), Vector2(-30, 26), Vector2(30, -30), Vector2(70, 20), Vector2(0, 50)]
	var rars = [0, 1, 0, 2, 0]
	for i in 5:
		g.drops.append({"pos": g.p.pos + offs[i], "vel": Vector2.ZERO, "t": 1.0, "kind": "item", "n": 0, "item": D.make_item(D.SLOTS[i % 3], 1, rars[i])})
	g.drops.append({"pos": g.p.pos + Vector2(40, 56), "vel": Vector2.ZERO, "t": 1.0, "kind": "item", "n": 0, "item": D.elite_unique("warding")})
	await shot("14_filter")
	quit()
