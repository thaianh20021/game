extends SceneTree
# Chapters three to five and what came with them: zones, bosses, story choices, the side chains and secrets,
# the Echo Tide, tone stones, reforging and Ngải's bond. Run with --fixed-fps 60.
const D = preload("res://src/data.gd")
var g
var fails = 0

func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1

func frames(n: int) -> void:
	for i in n:
		await process_frame

func fresh(done_to: int) -> void:
	g.new_game()
	g.lvl = 50
	g.recompute()
	g.fresh_hero()
	for i in range(1, done_to + 1):
		g.qs["m%d" % i] = "done"
	g.mode = "play"

func boss(kind: String):
	for o in g.foes:
		if o.kind == kind and o.state != "dead":
			return o
	return null

func slay(f) -> void:
	g.hit_foe(f, f.hp * 3.0 + 10.0, true, 0.0, 0.0)
	await frames(3)

func uniq_drops(u: String) -> int:
	return g.drops.filter(func(d): return d.kind == "item" and d.item.uniq == u).size()

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_late.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)

	# --- chapter three
	fresh(11)
	g.enter_zone("field", Vector2.ZERO)
	check("the marsh has a way south to the salt sea", g.zone.portals.any(func(po): return po.to == "salt" and po.need == "m12"))
	g.enter_zone("salt", Vector2.ZERO)
	var kinds = {}
	for o in g.foes:
		kinds[o.kind] = true
	check("the salt sea has crabs, gulls and divers, and the salvagers' camp", kinds.has("crab") and kinds.has("gull") and kinds.has("diver") and g.zone.npcs.size() == 2)
	g.enter_zone("fleet", Vector2.ZERO)
	var adm = boss("admiral")
	check("the Admiral waits on the flagship", adm != null and adm.hp > 3000.0)
	g.p.hp = 99999.0
	g.stats.mhp = 99999.0
	g.p.pos = adm.pos + Vector2(-80, 0)
	g.hit_foe(adm, adm.hp * 0.7, true, 0.0, 0.0)
	await frames(240)
	check("below two thirds he calls drowned divers", g.foes.filter(func(o): return o.kind == "diver" and o.state == "spawn" or o.kind == "diver").size() > 5)
	await slay(adm)
	check("he drops his salt charm and does not come back", uniq_drops("salt") == 1 and g.flags.has("admiral_dead"))
	g.enter_zone("fleet", Vector2.ZERO)
	check("the flagship stays empty", boss("admiral") == null)
	for q in ["m12", "m13", "m14", "m15", "m16"]:
		g.qs[q] = "done"
	g.enter_zone("town", Vector2.ZERO)
	check("after chapter three Kham has left town and Ngải keeps the shop", not g.zone.npcs.any(func(n): return n.id == "kham") and g.service("ngai") == "heal_shop")

	# --- chapter four
	fresh(16)
	g.accept("m17")
	g.enter_zone("town", Vector2.ZERO)
	check("To Dien has gone up the mountain", not g.zone.npcs.any(func(n): return n.id == "dien"))
	g.enter_zone("mines", Vector2.ZERO)
	check("the mute mines have slag, smiths and moths", g.foes.any(func(o): return o.kind == "slag") and g.foes.any(func(o): return o.kind == "smith") and g.foes.any(func(o): return o.kind == "moth"))
	g.enter_zone("foundry", Vector2.ZERO)
	var fm = boss("forgemaster")
	var mold = boss("mold")
	check("Bach Lo and the Living Mould share the pit", fm != null and mold != null)
	await slay(fm)
	await slay(mold)
	check("Bach Lo drops his hammer; both stay down", uniq_drops("forge") == 1 and g.flags.has("forgemaster_dead") and g.flags.has("mold_dead"))

	# --- chapter five
	fresh(21)
	g.accept("m22")
	g.enter_zone("maw", Vector2.ZERO)
	check("the First Toll sleeps until Ô Kha falls", boss("okhab") != null and boss("first") == null)
	g.p.hp = 99999.0
	g.stats.mhp = 99999.0
	await slay(boss("okhab"))
	await frames(40)
	check("when Ô Kha falls the First Toll rises", boss("first") != null)
	await slay(boss("first"))
	check("then Van's voice can be chosen", g.zone.things.any(func(t): return t.id == "voice"))
	g.look("voice")
	g.choose(0)
	for q in ["m22", "m23", "m24", "m25"]:
		g.qs[q] = "done"
	g.qc["m26"] = {}
	g.qs["m26"] = "ready"
	g.turnin("m26")
	check("the ending follows the choice", g.talk.get("story", false) and g.talk.lines[1].begins_with("MẢNH CHUÔNG TRONG NGỰC BẠN IM"))
	g.mode = "play"
	g.enter_zone("archive", Vector2.ZERO)
	check("Kham waits in the Hall of Records", g.zone.npcs.any(func(n): return n.id == "kham"))

	# --- the Echo Tide
	fresh(26)
	g.enter_zone("fleet", Vector2.ZERO)
	check("after the ending the cleared dungeons have a tide", g.zone.get("tide", 0) >= 1 and g.zone.mult > 3.0)
	g.enter_zone("salt", Vector2.ZERO)
	check("open zones have none", g.zone.get("tide", 0) == 0)

	# --- the Debts of the Dead
	fresh(2)
	g.accept("s6")
	g.look("debt_potter")
	g.choose(1)
	var g0 = g.gold
	g.turnin("s6")
	check("collecting a debt pays gold", g.gold - g0 == 60 and g.flags.debt1 == 1)

	# --- the Eight Mute Clappers
	fresh(0)
	g.look("mute_3")
	check("a clapper out of turn stays silent", int(g.flags.get("mutes", 0)) == 0)
	g.mode = "play"
	for k in range(1, 9):
		g.look("mute_%d" % k)
		g.mode = "play"
	check("eight in turn give the Eight-Tone Clapper", g.flags.mutes == 8 and uniq_drops("eight") == 1)

	# --- the Counting Lighthouse
	fresh(0)
	g.sim.no_spawns = true
	g.enter_zone("salt", Vector2.ZERO)
	g.look("lighthouse")
	check("one look shows only a number", not g.zone.things.any(func(t): return t.id == "lamp_keeper"))
	g.flags.lh_days.append("1")
	g.mode = "play"
	g.look("lighthouse")
	check("a second day brings out the keeper", g.zone.things.any(func(t): return t.id == "lamp_keeper"))
	g.sim.erase("no_spawns")

	# --- tone stones and reforging
	fresh(0)
	g.eq.weapon = D.make_item("weapon", 1, 2, 0)
	g.recompute()
	var a0 = g.stats.atk
	g.inv = [D.rune_item("steel"), D.rune_item("steel"), D.rune_item("blood")]
	g.equip(0)
	check("a stone is not worn like an item", g.inv.size() == 3)
	g.open_inv(true)
	g.sell(0)
	g.sell(0)
	g.sell(0)
	check("a rare weapon takes two stones and no more", g.eq.weapon.runes.size() == 2 and g.inv.size() == 1 and int(g.stats.atk - a0) == 8)
	g.gold = 5000
	g.scrap = 200
	var a1 = g.stats.atk
	g.reforge(g.BAG)
	check("reforging adds a tenth of the base stat", g.eq.weapon.plus == 1 and g.stats.atk > a1)
	for i in 6:
		g.reforge(g.BAG)
	check("and stops at +5", g.eq.weapon.plus == 5)
	g.save_game()
	g.new_game()
	check("stones, reforge level and slag are saved", g.load_game() and g.eq.weapon.runes.size() == 2 and int(g.eq.weapon.plus) == 5 and g.scrap >= 0)

	# --- Ngải's bond
	fresh(24)
	g.flags["bond"] = 3
	g.accept("m25")
	g.enter_zone("maw", Vector2.ZERO)
	check("with bond 3 Ngải comes down the pit", g.zone.npcs.any(func(n): return n.id == "ngai"))
	g.flags["bond"] = 1
	g.enter_zone("maw", Vector2.ZERO)
	check("without it she stays in town", not g.zone.npcs.any(func(n): return n.id == "ngai"))

	print("DONE %d failed" % fails)
	quit(1 if fails > 0 else 0)
