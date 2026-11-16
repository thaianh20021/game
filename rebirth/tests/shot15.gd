extends SceneTree
# Screenshots: the controls page, foes that answer mechanics, the forge with its fourth choice.
const Meta = preload("res://src/meta.gd")
const Counter = preload("res://src/counter.gd")
var g
func frames(n):
	for k in n: await process_frame
func shot(name):
	await frames(2)
	root.get_texture().get_image().save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_" + name + ".png")
func _init():
	Meta.PATH = "user://rebirth_shot15.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	Meta.S.tut = true
	g.goto_lobby()
	await frames(5)
	g.open_menu("keys")
	g.set_bind(KEY_SPACE, KEY_K)
	g.menu.rows = g.Lobby.rows(g, "keys")
	g.menu.sel = 4
	await frames(5)
	await shot("keys")
	g.Meta.S.opts.binds = {}
	g.rebuild_binds()
	g.set_state("play")
	g.start_run(5, false)
	await frames(5)
	g.floor_i = 2
	var room = null
	for r in g.dg.rooms:
		if r.type == "fight":
			room = r
			break
	room.cleared = true
	g.p.pos = g.rc(room) + Vector2(-70, 0)
	g.p.inv = 999.0
	g.enemies.clear()
	var i = 0
	for k in Counter.ORDER:
		var e = g.spawn_enemy(["goblin", "skel", "imp", "boar", "slime"][i], g.rc(room) + Vector2(-20 + (i % 3) * 40, -30 + (i / 3) * 50))
		e.stun = 99.0
		e.born = 0.0
		Counter.put(g, e, k)
		i += 1
	g.spirits.append({pos = g.p.pos, t = 9.0, cd = 9.0, el = "fire", own = 0, seed = 0.0})
	g.p.rally = 3
	g.p.rally_t = 99.0
	g.banner.t = 0.0
	await frames(60)
	g.fade = 0.0
	await shot("counter")
	g.p.weapons = [{id = "pistol", el = "tox", el2 = "", lv = 1}, {id = "blade", el = "fire", el2 = "", lv = 0}]
	g.p.gold = 100
	g.interact({kind = "fuse", pos = g.p.pos})
	await frames(10)
	g.forge.opts[1].traits.append("hex")
	g.forge.opts[1].fname = "TWIN BLADE"
	g.forge.sel = 3
	await shot("forge2")
	quit(0)
