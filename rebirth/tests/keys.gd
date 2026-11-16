extends SceneTree
# Key rebinding: Settings > CONTROLS, swaps, menus keep their keys, prompts follow.
const Meta = preload("res://src/meta.gd")
const Pad = preload("res://src/pad.gd")
var g
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for k in n: await process_frame
func press(code):
	var ev = InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = code
	ev.keycode = code
	g._input(ev)
func _init():
	Meta.PATH = "user://rebirth_keys.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.goto_lobby()
	await frames(3)
	g.open_menu("opts")
	check(g.menu.rows.any(func(r): return r.name == "CONTROLS"), "settings have a controls page")
	g.open_menu("keys")
	check(g.menu.rows.size() == g.BINDABLE.size() + 1, "one row per action and a reset")
	# choose DASH, press J
	var di = g.BINDABLE.map(func(a): return a[1]).find(KEY_SPACE)
	g.menu.rows[di].fn.call()
	check(g.bind_wait == KEY_SPACE, "the row waits for a key")
	press(KEY_J)
	check(g.bind_wait == -1 and g.phys(KEY_SPACE) == KEY_J and g.menu.rows[di].name.ends_with("J"), "dash is now J: " + g.menu.rows[di].name)
	# give J to swap: they trade keys
	var qi = g.BINDABLE.map(func(a): return a[1]).find(KEY_Q)
	g.menu.rows[qi].fn.call()
	press(KEY_SPACE)
	check(g.phys(KEY_Q) == KEY_SPACE and g.phys(KEY_SPACE) == KEY_J, "swap takes space, dash keeps J")
	g.menu.rows[qi].fn.call()
	press(KEY_J)
	check(g.phys(KEY_Q) == KEY_J and g.phys(KEY_SPACE) == KEY_SPACE, "taking a used key trades them")
	# esc keeps the old one
	g.menu.rows[di].fn.call()
	press(KEY_ESCAPE)
	check(g.phys(KEY_SPACE) == KEY_SPACE and g.bind_wait == -1, "esc keeps the key")
	g.menu.rows[di].fn.call()
	press(KEY_K)
	check(g.phys(KEY_SPACE) == KEY_K, "dash on K")
	g.set_state("play")
	# in play: K dashes, space does nothing, Q's new key J swaps
	g.jp.clear()
	press(KEY_K)
	check(g.jp.has(KEY_SPACE), "in play K reads as dash")
	g.jp.clear()
	press(KEY_SPACE)
	check(not g.jp.has(KEY_SPACE), "space no longer dashes")
	g.jp.clear()
	press(KEY_J)
	check(g.jp.has(KEY_Q), "J swaps")
	# menus keep the usual keys
	g.open_menu("opts")
	g.jp.clear()
	press(KEY_SPACE)
	check(g.jp.has(KEY_SPACE), "menus still take space")
	g.set_state("play")
	# prompts follow the new keys
	check(Pad.hint(g, "SPACE TO DASH") == "K TO DASH", "prompts name the new key: " + Pad.hint(g, "SPACE TO DASH"))
	# saved and loaded
	Meta.save()
	Meta.load_save()
	g.apply_opts()
	check(g.phys(KEY_SPACE) == KEY_K, "bindings survive a reload")
	g.open_menu("keys")
	g.menu.rows[-1].fn.call()
	check(g.phys(KEY_SPACE) == KEY_SPACE and g.bind_rev.is_empty(), "reset puts everything back")
	print("KEYS OK" if fails == 0 else "KEYS FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
