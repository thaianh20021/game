extends SceneTree
# Run without --headless. Writes PNGs of the main screens to res://shots/.
const Bot = preload("res://tests/bot.gd")
const D = preload("res://src/data.gd")
var g

func shot(n: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/" + n + ".png"))

func frames(n: int) -> void:
	for i in n:
		await process_frame

func quiet() -> void:
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.sim.mouse = g.p.pos + Vector2(40, 10)
	g.sim.ui_mouse = Vector2.ZERO

func _init() -> void:
	D.SAVE_PATH = "user://duvang_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await process_frame
	quiet()
	await frames(20)
	await shot("0_intro")
	g.mode = "play"
	g.sim.move = Vector2.RIGHT
	await frames(24)
	await shot("1_town")
	quiet()
	g.p.pos = g.zone.npcs[0].pos + Vector2(0, 18)
	await frames(10)
	g.start_talk("say")
	await shot("2_talk")
	g.mode = "play"
	g.qs = {"m1": "done", "m2": "done", "m3": "active", "m4": "active", "s1": "active", "s2": "active"}
	g.qc = {"m3": {"loot": 2}, "m4": {}, "s1": {}, "s2": {}}
	g.inv = [D.make_item("armor", 0, 1), D.make_item("weapon", 1, 2), D.make_item("charm", 0, 0), D.ferry_oar()]
	g.gold = 87
	g.open_inv(false)
	g.sim.ui_mouse = g.Ui.bag_cell(g.get_viewport_rect().size, 1).get_center()
	await shot("3_bag")
	g.mode = "play"
	g.enter_zone("field", Vector2(30 * 16, 23 * 16))
	quiet()
	var n = 0
	var done = false
	while not done and n < 60 * 40:
		Bot.drive(g)
		g.p.hp = maxf(g.p.hp, 50.0)
		await process_frame
		n += 1
		done = g.p.state == "atk" and g.p.st > g.ATK[0][0] and g.foes.any(func(f): return f.state == "wind")
	await shot("4_marsh")
	for th in g.zone.things:
		if th.id == "widow":
			g.foes.clear()
			g.p.pos = th.pos + Vector2(-20, 6)
			g.cam = g.p.pos
			quiet()
			g.look("widow")
			g.talk.i = 2
			await shot("5_choice")
	g.mode = "play"
	g.qs["m5"] = "active"
	g.lvl = 5
	g.recompute()
	g.enter_zone("dungeon", Vector2(33 * 16, 15.5 * 16))
	g.foes = g.foes.filter(func(f): return f.kind == "boss")
	quiet()
	g.sim.move = Vector2.RIGHT
	await frames(40)
	await shot("6_van")
	g.mode = "play"
	g.p.pos = Vector2(52 * 16, 15.5 * 16)
	quiet()
	n = 0
	done = false
	while not done and n < 60 * 40:
		Bot.drive(g)
		g.p.hp = maxf(g.p.hp, 80.0)
		await process_frame
		n += 1
		done = g.foes.any(func(f): return f.kind == "boss" and f.state == "wind" and f.st > 0.5)
	await shot("7_boss")
	quit()
