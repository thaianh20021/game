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
	for s in D.SLOTS:
		g.inv.append(D.make_item(s, 1, 1))
	g.bag_add(D.rune_item("steel"))
	g.bag_add(D.rune_item("steel"))
	g.bag_add(D.rune_item("steel"))
	g.eq.helm = D.make_item("helm", 2, 2)
	g.eq.ring = D.make_item("ring", 0, 1)
	g.recompute()
	g.open_inv(false)
	g.isel = 3
	g.inv_pad = true
	await snap("bag")
	g.open_inv(true)
	g.isel = 0
	g.inv_pad = true
	await snap("shop")
	g.mode = "tree"
	g.tab = 0
	g.tsel = "spin"
	g.tree_pad = true
	await snap("tree")
	# the guild ledger in town and the potter's echo in the marsh (they had no picture before)
	for zid in ["town", "field"]:
		g.mode = "play"
		g.enter_zone(zid, Vector2.ZERO)
		for th in g.zone.things:
			if th.id.begins_with("debt_"):
				g.p.pos = th.pos + Vector2(26, 8)
		await snap("debt_" + zid)
	quit()
