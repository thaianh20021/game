extends SceneTree
# Phone controls outside play: on the bag, shop, skill tree and talk screens a tap chooses and the buttons at
# the right edge act. Taps reach the game as an emulated mouse; here sim.atk + sim.ui_mouse stand in for that,
# and the buttons are pressed with real screen-touch events. Run with --fixed-fps 60.
const D = preload("res://src/data.gd")
const Sk = preload("res://src/skills.gd")
const Touch = preload("res://src/touch.gd")
const Ui = preload("res://src/ui.gd")
var g
var fails = 0
var passes = 0

func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if ok:
		passes += 1
	else:
		fails += 1

func frames(n: int) -> void:
	for i in n:
		await process_frame

func touch(i: int, pos: Vector2, down: bool) -> void:
	var e = InputEventScreenTouch.new()
	e.index = i
	e.position = pos
	e.pressed = down
	g._input(e)

func view() -> Vector2:
	return g.get_viewport_rect().size

# press the context button with this key: a finger down for a few frames, then up
func press(k: String) -> bool:
	var bs = Touch.ctx(g)
	for i in bs.size():
		if bs[i][0] == k:
			var c = Touch.ctx_rect(view(), i).get_center()
			touch(5, c, true)
			await frames(3)
			touch(5, c, false)
			await frames(2)
			return true
	return false

# a tap at a screen point (the emulated mouse)
func tap(pos: Vector2) -> void:
	g.sim.ui_mouse = pos
	g.sim.atk = true
	await frames(2)
	g.sim.atk = false
	await frames(2)

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_touch.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)
	g.new_game()
	g.sim.no_spawns = true
	g.enter_zone("field", Vector2.ZERO)
	g.fresh_hero()
	g.mode = "play"
	# only these two stand in for the emulated mouse; every other key comes from the touch events
	g.sim.atk = false
	g.sim.ui_mouse = Vector2(-50, -50)
	touch(0, Vector2(10, 10), true)
	touch(0, Vector2(10, 10), false)
	check("a touch turns the phone controls on", g.touch_on)
	check("no context buttons while playing", Touch.ctx(g).is_empty())

	# ---- the shop: a tap chooses, BÁN sells
	g.open_inv(true)
	g.inv.clear()
	g.inv.append(D.make_item("armor", 0, 0))
	var gold0 = g.gold
	await tap(Ui.bag_cell(view(), 0).get_center())
	check("shop: a tap on an item only chooses it", g.inv.size() == 1 and g.isel == 0 and g.inv_pad)
	check("shop: the buttons are there", Touch.ctx(g).map(func(b): return b[0]) == ["dodge", "upg", "salv", "buy", "reset", "inv"])
	await press("dodge")
	check("shop: BÁN sells the chosen item", g.inv.is_empty() and g.gold > gold0)
	g.gold = 500
	var pots = g.potions
	await press("buy")
	check("shop: MUA BÌNH buys a potion", g.potions == pots + 1)
	await press("inv")
	check("shop: ĐÓNG closes it", g.mode == "play")

	# ---- the bag: a tap chooses, MẶC / THÁO wears
	g.open_inv(false)
	g.inv.clear()
	var it = D.make_item("armor", 0, 0)
	g.inv.append(it)
	await tap(Ui.bag_cell(view(), 0).get_center())
	check("bag: a tap only chooses", g.inv.size() == 1 and g.isel == 0)
	await press("dodge")
	check("bag: MẶC / THÁO wears the chosen item", g.eq.get("armor") == it)
	var ok = await press("swap")
	check("bag: ĐỔI BỘ VŨ KHÍ is there", ok)
	await press("inv")
	check("bag: ĐÓNG closes it", g.mode == "play")

	# ---- the skill tree: a tap chooses a node, HỌC learns it, GẮN Ô 2 puts it on the bar
	g.lvl = 10
	g.main_m = 0
	g.tree = {}
	g.bar = ["", "", "", "", ""]
	g.recompute()
	g.mode = "tree"
	g.tab = 0
	await frames(2)
	await tap(Ui.tree_cell(view(), "spin").get_center())
	check("tree: a tap only chooses a node", not g.tree.has("spin") and g.tsel == "spin")
	await press("dodge")
	check("tree: HỌC learns the chosen node", g.tree.has("spin"))
	await press("s2")
	check("tree: GẮN Ô 2 puts it on the second slot", g.bar[1] == "spin")
	await tap(Ui.tab_rect(view(), 1).get_center())
	check("tree: a tap on a tab still turns the page", g.tab == g.tabs()[1])
	await press("tree")
	check("tree: ĐÓNG closes it", g.mode == "play")

	# ---- talk: TIẾP moves on
	g.say("", "", ["MỘT", "HAI"], "", "")
	await frames(2)
	check("talk: the say opened a talk", g.mode == "talk" and g.talk.i == 0)
	await press("use")
	check("talk: TIẾP moves to the next line", g.talk.i == 1 or g.mode != "talk")

	# ---- the pause menu: QUAY LẠI
	g.mode = "play"
	await frames(2)
	touch(6, Vector2(view().x - 16, 40), true)
	await frames(3)
	touch(6, Vector2(view().x - 16, 40), false)
	await frames(2)
	check("the II button opens the pause menu", g.mode == "pause")
	await press("menu")
	check("pause: QUAY LẠI goes back to play", g.mode == "play")

	print("== touch pass=%d fail=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
