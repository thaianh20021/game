extends SceneTree
# Word Forge: the word lists, three ready-made fusions, the forged weapon; two starting weapons.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Forge = preload("res://src/forge.gd")
const Arms = preload("res://src/arms.gd")
var g
var fails = 0
var vis = DisplayServer.get_name() != "headless"
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for i in n: await process_frame
func type(s):
	for ch in s:
		var ev = InputEventKey.new()
		ev.pressed = true
		ev.unicode = ch.unicode_at(0)
		g._input(ev)
func _init():
	Meta.PATH = "user://rebirth_forge.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	# parsing
	var k = Forge.parse("fast fire bow", [])
	check(k.els == ["fire"] and k.traits == ["swift"] and k.shape == "BOW", "english: " + str(k))
	k = Forge.parse("cung lửa nhanh", [])
	check(k.els == ["fire"] and k.traits == ["swift"] and k.shape == "BOW", "vietnamese with accents: " + str(k))
	k = Forge.parse("KIEM BANG MANH xuyen", [])
	check(k.els == ["ice"] and k.traits == ["keen", "pierce"] and k.shape == "BLADE", "vietnamese without accents: " + str(k))
	k = Forge.parse("súng sét độc nổ", [])
	check(k.els == ["bolt", "tox"] and k.traits == ["blast"] and k.shape == "SHOOTER", "mixed: " + str(k))
	k = Forge.parse("no", [])
	check(k.traits.is_empty(), "plain english 'no' is not 'nổ'")
	k = Forge.parse("", [JOY_BUTTON_DPAD_UP, JOY_BUTTON_A, JOY_BUTTON_Y])
	check(k.els == ["fire"] and k.traits == ["multi", "homing"], "pad combo: " + str(k))
	# two weapons from the very start
	g.goto_lobby()
	g.start_run(5, false)
	check(g.p.weapons[1] != null and g.p.weapons[1].el != g.p.weapons[0].el, "heroes start with two weapons of different elements")
	# the forge screen: three ready-made fusions, no typing
	g.p.weapons = [{id = "pistol", el = "tox", el2 = "", lv = 1}, {id = "blade", el = "", el2 = "", lv = 0}]
	g.p.gold = 10
	g.interact({kind = "fuse", pos = g.p.pos})
	check(g.state == "play", "no gold, no forge")
	g.p.gold = 100
	g.interact({kind = "fuse", pos = g.p.pos})
	check(g.state == "forge" and g.forge.opts.size() == 3, "the altar offers three fusions")
	var opts: Array = g.forge.opts
	var mechs = {}
	for o in opts:
		mechs[o.traits[0]] = true
	check(mechs.size() == 3 and mechs.keys().all(func(m): return g.WMods.NEW.has(m)), "each offers a different new mechanic: " + str(mechs.keys()))
	check(opts[0].id == "pistol" and opts[1].id == "blade" and not (opts[2].id in ["pistol", "blade"]), "shaped after the one in hand, the other, and a third kind: " + str(opts.map(func(o): return o.id)))
	check(opts.all(func(o): return o.pow >= 1.3 and int(o.lv) == 2 and o.has("fname")), "all stronger, a level more, named")
	await frames(12)
	if vis:
		var im = root.get_texture().get_image()
		im.save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_forge.png")
	g.jp[KEY_2] = true
	await frames(2)
	var w = g.p.weapons[0]
	print("forged: ", g.wname(w), " ", w)
	check(g.state == "play" and g.p.gold == 70 and g.p.weapons[1] == null and w == opts[1], "2 forges the second offer, for gold, consuming both")
	# it fires
	var e = g.spawn_enemy("goblin", g.p.pos + Vector2(40, 0))
	e.mhp = 99999.0
	e.hp = 99999.0
	e.stun = 99.0
	g.p.weapons = [opts[0], null]
	g.sim["mouse"] = Vector2(340, 135)
	g.sim["fire"] = true
	await frames(40)
	g.sim.erase("fire")
	await frames(4)
	check(e.hp < 99999.0, "the forged weapon works")
	# pad: right, then A
	g.enemies.clear()
	g.p.weapons = [{id = "wand", el = "ice", el2 = "", lv = 0}, {id = "rail", el = "bolt", el2 = "", lv = 2}]
	g.interact({kind = "fuse", pos = g.p.pos})
	var popts: Array = g.forge.opts
	for b in [JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_A]:
		var ev = InputEventJoypadButton.new()
		ev.device = 0
		ev.button_index = b
		ev.pressed = true
		g._input(ev)
		await frames(2)
	check(g.state == "play" and g.p.weapons[0] == popts[2] and int(g.p.weapons[0].lv) == 3, "the pad picks and forges")
	# empty command still gives something stronger
	g.p.weapons = [{id = "bow", el = "fire", el2 = "", lv = 0}, {id = "coil", el = "bolt", el2 = "", lv = 0}]
	var r = Forge.build(g, "", [])
	check(r.el == "fire" and r.el2 == "bolt" and r.traits.size() == 1 and r.pow >= 1.3, "no command: elements of both, a random trait")
	print("FORGE ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
