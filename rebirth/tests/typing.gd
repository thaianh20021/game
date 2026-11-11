extends SceneTree
# Touch-only use of the menus and typing screens: tap to choose, tap again to confirm,
# name a skill with the on-screen keyboard and the OK button, Back is Escape.
const Meta = preload("res://src/meta.gd")
const Hud = preload("res://src/hud.gd")
const Touch = preload("res://src/touch.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for k in n: await process_frame
func tap(pos: Vector2):
	# pos is on the HUD sheet; the event arrives in screen coordinates
	var ev = InputEventScreenTouch.new()
	ev.index = 0
	ev.position = pos + g.hud.position
	ev.pressed = true
	g._input(ev)
	await frames(2)
	var up = InputEventScreenTouch.new()
	up.index = 0
	up.position = pos + g.hud.position
	up.pressed = false
	g._input(up)
	await frames(2)
func type(text: String):
	# what an on-screen keyboard sends: a unicode character and no physical key
	for ch in text:
		var ev = InputEventKey.new()
		ev.pressed = true
		ev.unicode = ch.unicode_at(0)
		g._input(ev)
func _init():
	Meta.PATH = "user://rebirth_typing.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	Meta.S.gems = 500
	g.goto_lobby()
	g.tin.on = true
	await frames(10)

	# ---- skill tree: the first tap only chooses ----
	g.open_menu("tree")
	await frames(10)
	var owned0 = Meta.S.tree.get(g.p.tkey, []).size()
	var gems0 = Meta.S.gems
	await tap(Hud.menu_rect("tree", 3).get_center())
	check(g.menu.sel == 3 and Meta.S.gems == gems0, "the first tap chooses and buys nothing")
	await tap(Hud.menu_rect("tree", 0).get_center())
	check(g.menu.sel == 0 and Meta.S.gems == gems0, "another row: still only chosen")
	await tap(Hud.menu_rect("tree", 0).get_center())
	check(Meta.S.gems < gems0 and Meta.S.tree.get(g.p.tkey, []).size() == owned0 + 1, "the second tap on the same node buys it")
	await tap(Vector2(378, 38))
	check(g.state == "play", "the X closes the menu")

	# ---- training a skill with touch only ----
	g.open_menu("spell")
	await frames(10)
	var g0 = Meta.S.gems
	await tap(Hud.menu_rect("spell", 1).get_center())
	check(Meta.S.gems == g0, "first tap on a training row only chooses")
	await tap(Hud.menu_rect("spell", 1).get_center())
	check(Meta.S.gems == g0 - 15 and g.p.sk1[1] > 1.1 and g.state == "menu" and g.menu.sel == 1, "second tap trains reach and the menu stays put: " + str(g.p.sk1))
	await tap(Hud.menu_rect("spell", 6).get_center())
	await tap(Hud.menu_rect("spell", 6).get_center())
	check(g.Spell.recipes().size() == 1 and g.menu.rows[6].name.begins_with("REACTION SPELL: FIRE"), "the reaction spell is chosen from the menu: " + g.menu.rows[6].name)
	await tap(Vector2(378, 38))

	# ---- naming a discovery with the on-screen keyboard ----
	Meta.S.book["fire+ice"] = ""
	g.open_menu("book")
	await frames(10)
	await tap(Hud.menu_rect("book", 0).get_center())
	await tap(Hud.menu_rect("book", 0).get_center())
	check(g.state == "say", "the notebook opens the naming prompt")
	await frames(8)
	check(g.kb_lift() > 40.0 and g.hud.position.y < g.hud_off.y - 40.0, "the prompt slides up above the keyboard")
	type("sao choi")
	await frames(3)
	check(g.say == "sao choi", "keys without a physical code still type: " + g.say)
	await tap(Vector2(240, 120))
	check(g.state == "say", "a stray tap keeps the prompt open")
	await tap(Touch.ok_rect(g).get_center())
	await frames(3)
	check(g.state == "menu" and Meta.S.book["fire+ice"] == "SAO CHOI", "OK saves the name: " + str(Meta.S.book["fire+ice"]))
	check(g.hud.position == g.hud_off, "the sheet comes back down")
	await tap(Hud.menu_rect("book", 0).get_center())
	await tap(Hud.menu_rect("book", 0).get_center())
	type("xyz")
	await frames(8)
	await tap(Touch.no_rect(g).get_center())
	await frames(3)
	check(Meta.S.book["fire+ice"] == "SAO CHOI", "CANCEL keeps the old name")
	g.set_state("play")

	# ---- the phone's Back button is Escape ----
	g.open_menu("tree")
	await frames(10)
	g._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(3)
	check(g.state == "play", "Back closes a menu instead of quitting")

	# ---- the name is used in a run ----
	g.start_run(3, false)
	await frames(5)
	check(g.p.sk1[1] > 1.1, "training follows into the dungeon")
	print("TYPING OK" if fails == 0 else "TYPING FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
