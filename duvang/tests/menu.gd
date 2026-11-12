extends SceneTree
# Title, character creation, pause, settings, journal; and the completed Elementalist mastery.
const D = preload("res://src/data.gd")
const Sk = preload("res://src/skills.gd")
var g
var fails = 0

func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1

func frames(n: int) -> void:
	for i in n:
		await process_frame

func tap(key: String) -> void:
	g.sim[key] = true
	await frames(2)
	g.sim[key] = false
	await frames(2)

func nudge(dir: Vector2) -> void:
	g.sim.move = dir
	await frames(2)
	g.sim.move = Vector2.ZERO
	await frames(2)

func quiet() -> void:
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.sim.mouse = g.p.pos + Vector2(60, 0)
	g.sim.ui_mouse = Vector2(-50, -50)
	g.hitstop = 0.0
	g.buf = ""

func read_on() -> void:
	var n = 0
	while g.mode == "talk" and n < 30:
		await tap("use")
		n += 1

# an Elementalist with the given ranks, alone on the dyke
func mage(ranks: Dictionary) -> void:
	g.new_game()
	g.main_m = 1
	g.lvl = 30
	g.tree = ranks.duplicate()
	g.bar = ["", "", "", "", ""]
	for id in ranks:
		if Sk.NODES[id].kind == "a":
			g.bar[g.bar.find("")] = id
	g.recompute()
	g.sim.no_spawns = true
	g.mode = "play"
	g.enter_zone("field", Vector2.ZERO)
	g.sim.no_spawns = false
	g.fresh_hero()
	g.p.pos = Vector2(34 * 16, 23 * 16)
	g.p.aim = Vector2.RIGHT
	g.p.rage = 100.0
	quiet()

func dummy(kind: String, off: Vector2) -> Dictionary:
	var f = g.spawn(kind, g.p.pos + off)
	f.cd = 9999.0
	f.state = "rec"
	f.st = -9999.0
	f.hp = 5000.0
	f.mhp = 5000.0
	return f

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_menu.json"
	D.MENUS = 1
	var save = ProjectSettings.globalize_path(D.SAVE_PATH)
	var optf = save.replace(".json", "_opt.json")
	DirAccess.remove_absolute(save)
	DirAccess.remove_absolute(optf)
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)
	quiet()

	# --- title and creation
	check("the game opens on the title", g.mode == "title")
	check("with no save there is no CONTINUE, and none is written by looking", g.Menu.items(g)[0][1] == "new" and not FileAccess.file_exists(D.SAVE_PATH))
	await nudge(Vector2.DOWN)
	check("S moves the cursor", g.msel == 1)
	await nudge(Vector2.UP)
	await tap("use")
	check("NEW GAME opens character creation", g.mode == "create" and g.csel == 0)
	await nudge(Vector2.RIGHT)
	check("the second card is the Elementalist", g.csel == 1 and g.Menu.CLASSES[1].m == 1)
	await nudge(Vector2.RIGHT)
	check("all eight masteries can be picked; the third card is the Guardian", g.csel == 2 and g.Menu.CLASSES[2].m == 10 and g.Menu.CLASSES.all(func(c): return c.m >= 0))
	await tap("menu")
	check("Esc goes back to the title", g.mode == "title")
	await tap("use")
	var view = g.get_viewport_rect().size
	g.sim.ui_mouse = g.Menu.card_rect(view, 1).get_center()
	await tap("atk")
	check("clicking a card selects it", g.csel == 1 and g.mode == "create")
	g.sim.ui_mouse = g.Menu.card_rect(view, 5).get_center()
	await tap("atk")
	check("clicking another card selects it too, now that every mastery is built", g.csel == 5)
	g.sim.ui_mouse = g.Menu.card_rect(view, 1).get_center()
	await tap("atk")
	g.sim.ui_mouse = g.Menu.start_rect(view).get_center()
	await tap("atk")
	g.sim.ui_mouse = Vector2(-50, -50)
	check("START begins the story as an Elementalist", g.mode == "talk" and g.talk.get("story", false) and g.main_m == 1 and g.talk.lines == D.INTRO)
	check("the new character is saved", FileAccess.file_exists(D.SAVE_PATH))
	await read_on()
	check("after the story you stand in town", g.mode == "play" and g.zone.id == "town" and g.tab == 1)
	check("your own mastery is open, the other is not", Sk.blocked(g.tree, "ember", 1, false, 1) == "" and Sk.blocked(g.tree, "spin", 1, false, 1) == Sk.NO_SECOND)
	check("learning follows that", g.learn("ember") and not g.learn("spin"))
	g.qs["m6"] = "done"
	g.lvl = 5
	check("when the shard wakes, the Warrior tree opens for an Elementalist", g.learn("spin"))
	g.second_m = 0
	g.say("X", "", ["A {2} B"], "", "")
	check("Ngai names the mastery that wakes", g.talk.lines[0] == "A THỦ, NỘ VÀ BINH KHÍ B")
	g.mode = "play"

	# --- pause, settings, journal
	await tap("menu")
	check("Esc pauses", g.mode == "pause")
	var t0 = g.p.pos
	g.sim.move = Vector2.RIGHT
	await frames(20)
	g.sim.move = Vector2.ZERO
	await frames(2)
	check("nothing moves while paused", g.p.pos == t0)
	await tap("menu")
	check("Esc resumes", g.mode == "play")
	await tap("menu")
	g.msel = 3
	await tap("use")
	check("the journal opens", g.mode == "journal")
	await tap("use")
	check("and closes back to the pause menu", g.mode == "pause")
	g.msel = 4
	await tap("use")
	check("settings open from pause", g.mode == "settings" and g.menu_back == "pause")
	g.msel = 0
	await tap("use")
	check("sound volume steps and is applied (%d)" % int(g.opt.sfx), g.opt.sfx == 0.0 and g.Sfx.vol_sfx == 0.0)
	g.msel = 2
	await tap("use")
	check("screen shake steps", g.opt.shake == 50.0)
	g.msel = 4
	await tap("use")
	check("damage numbers can be turned off", g.opt.nums == false)
	check("settings are written to their own file", FileAccess.file_exists(D.SAVE_PATH.replace(".json", "_opt.json")))
	g.opt.shake = 100.0
	g.load_opt()
	check("and read back", g.opt.shake == 50.0 and g.opt.nums == false)
	await tap("menu")
	check("Esc returns to where settings were opened", g.mode == "pause")
	g.msel = 1
	await tap("use")
	check("the skill tree opens from pause", g.mode == "tree")
	await tap("menu")
	check("Esc closes it", g.mode == "play")
	await tap("menu")
	g.sim.ui_mouse = g.Menu.item_rect(g, view, 5, 6).get_center()
	await tap("atk")
	g.sim.ui_mouse = Vector2(-50, -50)
	check("back to the title, which now offers CONTINUE", g.mode == "title" and g.Menu.items(g)[0][1] == "continue")
	g.msel = 0
	await tap("use")
	check("CONTINUE returns to play", g.mode == "play" and g.main_m == 1)
	g.save_game()
	g.new_game()
	check("the chosen mastery is saved", g.load_game() and g.main_m == 1 and g.tree.has("ember"))
	g.opt = {"sfx": 100.0, "music": 100.0, "shake": 100.0, "flash": true, "nums": true, "full": false}
	g.apply_opt()

	# --- the rest of the Elementalist
	var counts = []
	counts.resize(Sk.MASTERY.size())
	counts.fill(0)
	for id in Sk.NODES:
		counts[Sk.NODES[id].get("m", 0)] += 1
	check("19 nodes per mastery, 8 per link tree", counts == [19, 19, 8, 19, 8, 8, 19, 8, 8, 8, 19, 8, 8, 8, 8, 19, 8, 8, 8, 8, 8, 19, 8, 8, 8, 8, 8, 8, 19, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8])

	await mage({"ember": 1, "kindle": 1, "firewall": 1})
	var a = dummy("porter", Vector2(46, 20))
	var b = dummy("porter", Vector2(140, 0))
	await tap("s2")
	await frames(10)
	check("a fire wall burns what stands on it and nothing else", a.burn > 0.0 and b.burn <= 0.0 and g.fields.size() == 1)
	await frames(260)
	check("it goes out after four seconds", g.fields.is_empty())

	await mage({"ring": 1, "deep": 1, "shard": 1})
	a = dummy("reed", Vector2(50, 0))
	b = dummy("reed", Vector2(110, 0))
	g.mark(b, "chill")
	await tap("s2")
	await frames(30)
	check("an ice shard goes through the line and chills", a.hp < 5000.0 and b.hp < 5000.0 and a.chill > 0.0)
	check("a foe that was already chilled is frozen in place", b.state == "stun" and a.state != "stun" or b.stun == 1.0)
	var boss = dummy("keeper", Vector2(60, 40))
	g.mark(boss, "chill")
	boss.guard = 99.0   # no stance break, so a stun here could only be a freeze
	g.p.cds.clear()
	g.sim.mouse = boss.pos
	await frames(2)
	await tap("s2")
	await frames(30)
	check("a boss is not frozen", boss.hp < 5000.0 and boss.state != "stun")

	await mage({"spark": 1, "static": 1, "cage": 1})
	a = dummy("porter", Vector2(100, 0))
	b = dummy("porter", Vector2(-100, 0))
	g.sim.mouse = a.pos
	await frames(2)
	await tap("s2")
	await frames(70)
	var per = (5000.0 - a.hp) / (70.0 / 60.0)
	check("a lightning cage shocks and hurts what is inside (%.1f a second)" % per, a.shock > 0.0 and b.hp == 5000.0 and absf(per - g.stats.atk * 0.3 * g.dmg_mult(a)) < g.stats.atk * 0.2)

	await mage({"ember": 1, "kindle": 3, "heat": 3, "ash": 2, "ring": 1, "icearmor": 2, "tam": 1})
	a = dummy("porter", Vector2(80, 0))
	g.sim.mouse = a.pos
	await frames(2)
	check("with only Tam Tai learned it is the ultimate", g.cur_ult() == "tam")
	await tap("ult")
	await frames(80)
	check("Tam Tai lands three beats and leaves all three marks", a.burn > 0.0 and a.chill > 0.0 and a.shock > 0.0 and a.hp < 5000.0 - g.stats.atk * 5.0)
	check("hot air: 12% more to a burning foe", absf(g.dmg_mult(a) / (1.15) - 1.12) < 0.001)
	g.p.rage = 0.0
	var c = dummy("reed", Vector2(200, 0))
	g.mark(c, "burn")
	c.hp = 1.0
	g.hit_foe(c, 50.0, false, 0.0, 0.0)
	check("ashes: a foe that dies burning gives back 6 rage", absf(g.p.rage - 6.0) < 0.01)
	g.p.rage = 100.0
	g.p.elem = ""
	g.nums.clear()
	await tap("s1")
	check("the first spell does not resonate", not g.nums.any(func(n): return n.txt == "CỘNG HƯỞNG"))
	await frames(10)
	var h0 = a.hp
	g.p.pos = a.pos + Vector2(-40, 0)
	await tap("s2")
	check("a spell of another element does", g.nums.any(func(n): return n.txt == "CỘNG HƯỞNG"))
	check("ice armour is up after an ice spell", g.p.icearm > 3.0)
	var hp0 = g.p.hp
	g.hurt(40.0)
	check("and adds 6 armour while it lasts", absf((hp0 - g.p.hp) - 40.0 * 60.0 / (60.0 + (g.stats.def + 6.0) * 4.0)) < 0.01)
	g.p.cds.clear()
	g.nums.clear()
	await frames(20)
	await tap("s2")
	check("the same element twice does not resonate", not g.nums.any(func(n): return n.txt == "CỘNG HƯỞNG"))

	# --- two ultimates, one key
	await mage({"tam": 1, "toll": 1})
	check("with both learned the first one is used", g.cur_ult() == "toll")
	g.mode = "tree"
	g.tab = 1
	g.sim.ui_mouse = g.Ui.tree_cell(view, "tam").get_center()
	await tap("ult")
	check("R over the other one in the tree switches to it", g.ult == "tam" and g.cur_ult() == "tam")
	g.sim.ui_mouse = Vector2(-50, -50)
	g.mode = "play"
	DirAccess.remove_absolute(save)
	DirAccess.remove_absolute(optf)
	print("RESULT: %s" % ("OK" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
