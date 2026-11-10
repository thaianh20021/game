extends SceneTree
# Foes drop energy and gold but never health; crates are the gamble; every shop sells one potion.
const Meta = preload("res://src/meta.gd")
var fails = 0
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func _init():
	Meta.PATH = "user://rebirth_drops.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 5: await process_frame
	g.goto_lobby()
	g.start_run(17, false)
	var count = func(kind): return g.pickups.filter(func(k): return k.kind == kind).size()
	var c = g.p.pos
	for i in 200:
		var e = g.spawn_enemy("slime", c + Vector2(300, 0))
		g.kill(e)
	check(count.call("heart") == 0, "foes must not drop hearts")
	check(count.call("orb") >= 200 and count.call("coin") >= 200, "every foe drops energy and gold")
	print("200 foes -> orbs ", count.call("orb"), " coins ", count.call("coin"), " hearts ", count.call("heart"))
	g.pickups.clear()
	g.enemies.clear()
	for i in 400:
		var pr = {kind = "crate", el = "", pos = c + Vector2(300, 0), hp = 1.0, dead = false, flash = 0.0}
		g.hurt_prop(pr, 5.0)
	var hearts = count.call("heart")
	print("400 crates -> hearts ", hearts, " coins ", count.call("coin"), " orbs ", count.call("orb"))
	check(hearts >= 30 and hearts <= 90, "roughly one crate in seven holds a heart")
	for fl in 6:
		g.floor_i = fl
		g.new_floor()
		var potions = g.inter.filter(func(it): return it.kind == "shop" and it.item.type == "potion").size()
		var shops = g.dg.rooms.filter(func(r): return r.type == "shop").size()
		var crates = g.props.filter(func(pr): return pr.kind == "crate").size()
		check(potions == shops and shops == 1, "floor %d should sell exactly one potion" % fl)
		check(crates >= 6, "floor %d should have crates to gamble on" % fl)
	for it in g.inter:
		if it.kind == "shop" and it.item.type == "potion":
			g.p.gold = 500
			g.p.mhp = 9
			g.p.hp = 3
			g.interact(it)
			check(g.p.hp == 5, "potion heals 2")
	print("DROPS ", "OK" if fails == 0 else "FAILED %d" % fails)
	quit(0 if fails == 0 else 1)
