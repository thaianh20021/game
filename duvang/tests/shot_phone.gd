extends SceneTree
# Run without --headless and with --resolution 1866x840 (a 20:9 phone at x2). Writes shots/17_phone_*.png:
# play beside a villager, the shop and the skill tree, with the phone controls on.
const D = preload("res://src/data.gd")
var g

func snap(name: String) -> void:
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/17_phone_%s.png" % name))

func _init() -> void:
	D.SAVE_PATH = "user://duvang_shot.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await process_frame
	g.new_game()
	g.sim.no_spawns = true
	g.touch_on = true
	g.mode = "play"
	g.enter_zone("town", Vector2.ZERO)
	g.fresh_hero()
	var near = null
	for n in g.zone.npcs:
		near = n
		break
	if near != null:
		g.p.pos = near.pos + Vector2(20, 6)
	g.sim.move = Vector2.ZERO
	await snap("play")
	g.inv.append(D.make_item("armor", 0, 0))
	g.inv.append(D.make_item("weapon", 0, 0))
	g.open_inv(true)
	g.isel = 0
	g.inv_pad = true
	await snap("shop")
	g.mode = "tree"
	g.tab = 0
	g.tsel = "spin"
	g.tree_pad = true
	await snap("tree")
	quit()
