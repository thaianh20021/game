extends SceneTree
# The five masteries written after the first three: Soul Warlock, Guardian, Hunter, Priest, Artificer,
# and the solo trees (Độc Tấu). Each rhythm, every active skill, the main keystones and the ultimates.
# Run with --fixed-fps 60.
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

# a hero of mastery `main` with `second` as the other one, the given ranks, in the open marsh with nothing around
func hero(main: int, ranks: Dictionary, second: int = 0) -> void:
	g.new_game()
	g.main_m = main
	g.second_m = second
	g.qs["m6"] = "done"
	g.lvl = 60
	g.tree = ranks.duplicate()
	g.bar = ["", "", "", "", ""]
	for id in ranks:
		if Sk.NODES[id].kind == "a" and g.bar.find("") >= 0:
			g.bar[g.bar.find("")] = id
	g.recompute()
	g.sim.no_spawns = true
	g.mode = "play"
	g.enter_zone("field", Vector2.ZERO)
	g.fresh_hero()
	g.p.pos = Vector2(34 * 16, 23 * 16)
	g.p.aim = Vector2.RIGHT
	g.p.rage = 100.0
	for k in g.KEYS:
		g.sim[k] = false
	g.sim.move = Vector2.ZERO
	g.sim.mouse = g.p.pos + Vector2(60, 0)
	g.sim.ui_mouse = Vector2(-50, -50)
	g.hitstop = 0.0
	g.buf = ""

# a foe that stands still and never attacks
func dummy(kind: String, off: Vector2, hp: float = 5000.0) -> Dictionary:
	var f = g.spawn(kind, g.p.pos + off)
	f.cd = 9999.0
	f.state = "rec"
	f.st = -9999.0
	f.hp = hp
	f.mhp = hp
	f.flip = false
	f.guard = 99999.0
	return f

func cast(id: String) -> bool:
	g.p.state = "idle"
	if Sk.NODES[id].get("rage", 0) > 0:
		g.p.rage = 100.0
	g.p.cds.erase(id)
	var ok = g.cast(id)
	await frames(30)
	return ok

func _init() -> void:
	D.SAVE_PATH = "user://duvang_test_masteries.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(D.SAVE_PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(3)

	# ================================================================ Soul Warlock (m 6)
	await hero(6, {"summon": 1, "sacrifice": 1, "weaken": 1, "chain": 1, "scythe": 1, "soulform": 1, "jar": 2})
	check("warlock: souls shown, up to 5 plus a jar of 2", g.uses_souls() and g.soul_cap() == 7)
	var a = dummy("reed", Vector2(40, 0), 1.0)
	g.hit_foe(a, 50.0, false, 0.0, 0.0)
	check("warlock: a foe dying close gives a soul", g.p.souls == 1)
	check("warlock: Call Echo spends a soul and calls an echo", await cast("summon") and g.p.souls == 0 and g.ghosts.size() == 1)
	g.p.souls = 5
	await cast("summon")
	await cast("summon")
	g.p.souls = 5
	check("warlock: no more than three echoes", not g.can_cast("summon") and g.ghosts.size() == 3)
	a = dummy("porter", Vector2(30, 0))
	g.sim.mouse = g.ghosts[0].pos
	var n0 = g.ghosts.size()
	await cast("sacrifice")
	check("warlock: Sacrifice bursts an echo and hurts what stands by it", g.ghosts.size() == n0 - 1)
	g.sim.mouse = a.pos
	await cast("weaken")
	check("warlock: Weakening Curse curses the foes around the aim", a.get("curse", 0.0) > 0.0)
	var b = dummy("porter", Vector2(50, 20))
	var c = dummy("porter", Vector2(60, -20))
	await cast("chain")
	check("warlock: Soul Chain links three foes", g.chain_ids.size() == 3)
	var hb = b.hp
	g.hit_foe(a, 100.0, false, 0.0, 0.0)
	check("warlock: a blow on one linked foe is shared with the others", b.hp < hb)
	g.p.hp = g.stats.mhp * 0.5
	var h0 = g.p.hp
	g.p.aim = Vector2.RIGHT
	g.sim.mouse = a.pos
	await cast("scythe")
	check("warlock: Scythe heals for each foe it hits", g.p.hp > h0)
	g.p.souls = 4
	await cast("soulform")
	check("warlock: Soul Form spends every soul for 12% each", g.p.souls == 0 and absf(g.dmg_mult(dummy("reed", Vector2(200, 0))) - 1.48) < 0.06)

	await hero(6, {"hunger": 1})
	g.p.souls = 3
	check("warlock keystone Hunger: 6% per soul held", absf(g.dmg_mult(dummy("reed", Vector2(200, 0))) - 1.18) < 0.02)
	await frames(250)
	check("warlock keystone Hunger: one soul fades every 4 seconds", g.p.souls == 2)
	await hero(6, {"night": 1})
	await cast("night")
	a = dummy("reed", Vector2(30, 0), 1.0)
	g.hit_foe(a, 50.0, false, 0.0, 0.0)
	check("warlock ultimate Little Night: a foe that dies near you rises as a free echo", g.ghosts.size() == 1 and g.ghosts[0].free)

	# ================================================================ Guardian (m 10)
	await hero(10, {"raise": 1, "bash": 1, "verdict": 1, "taunt": 1, "cover": 1, "wall": 1, "thorns": 3})
	check("guardian: the shield is shown", g.uses_shield() and absf(g.shield_cap() - 100.0) < 0.01)
	await cast("raise")
	check("guardian: Raise Shield gives 40", absf(g.p.shield - 40.0) < 0.5)
	var hp0 = g.p.hp
	g.hurt(10.0)
	check("guardian: a blow lands on the shield before life", g.p.hp == hp0 and g.p.shield < 40.0)
	g.p.inv = 0.0
	var s1 = g.p.shield
	await frames(300)
	check("guardian: after 4 quiet seconds it fades about 5 a second", g.p.shield < s1 and g.p.shield > s1 - 8.0)
	g.p.shield = 80.0
	g.p.shield_hit = g.t
	a = dummy("reed", Vector2(28, 0))
	g.sim.mouse = a.pos
	await cast("bash")
	check("guardian: Shield Bash with 50 or more spends 25 and stuns", absf(g.p.shield - 55.0) < 1.0 and a.state == "stun")
	g.p.shield = 50.0
	var ha = a.hp
	await cast("verdict")
	check("guardian: Verdict spends the whole shield as damage around you", g.p.shield == 0.0 and ha - a.hp > g.stats.atk * 1.2)
	b = dummy("reed", Vector2(-30, 0))
	c = dummy("reed", Vector2(0, 30))
	var d = dummy("reed", Vector2(0, -30))
	await cast("taunt")
	check("guardian: Taunt gives 20 shield per foe, at most 3", absf(g.p.shield - 60.0) < 0.5 and b.get("taunt", 0.0) > 0.0)
	await cast("cover")
	check("guardian: standing in Cover takes 30% less", g.in_cover() and absf(g.guard_taken() - 0.7) < 0.01)
	await cast("wall")
	check("guardian: Shield Wall puts a wall in the way", g.fields.any(func(fd): return fd.kind == "wall") and g.blocks.size() > 0)
	g.p.shield = 50.0
	g.p.inv = 0.0
	ha = a.hp
	g.hitter = a
	g.hurt(10.0)
	g.hitter = null
	check("guardian: Thorns hurts what strikes the shield", a.hp < ha)
	await hero(10, {"fortress": 1})
	check("guardian keystone Fortress: twice the shield", absf(g.shield_cap() - 200.0) < 0.01)
	g.p.shield = 100.0
	await frames(330)
	check("guardian keystone Fortress: and it never fades", g.p.shield == 100.0)
	await hero(10, {"bronze": 1})
	a = dummy("reed", Vector2(30, 0))
	g.p.state = "idle"
	g.cast("bronze")
	await frames(60)
	check("guardian ultimate Bronze Gate: the shield stays full", absf(g.p.shield - g.shield_cap()) < 0.5)
	ha = a.hp
	await frames(260)
	check("guardian ultimate Bronze Gate: then it bursts around you", a.hp < ha)

	# ================================================================ Hunter (m 15)
	await hero(15, {"aimed": 1, "rain": 1, "snare": 1, "mine": 1, "sic": 1, "hunt": 1})
	await frames(10)
	check("hunter: one hound follows you", g.pets.size() == 1)
	g.p.focus_t = 0.0
	g.p.focused = false
	await frames(130)
	check("hunter: two seconds with no foe near fill the focus", g.p.focused)
	g.sim.atk = true
	await frames(3)
	g.sim.atk = false
	check("hunter: the next blow spends it for 40%", not g.p.focused and g.t < g.p.focus_until)
	await frames(60)
	a = dummy("porter", Vector2(60, 0))
	b = dummy("porter", Vector2(100, 0))
	g.sim.mouse = a.pos
	g.p.state = "idle"
	g.cast("aimed")
	check("hunter: Aimed Shot stands and draws first", g.p.state == "aim")
	await frames(60)
	check("hunter: then the arrow goes through both foes", a.hp < 5000.0 and b.hp < 5000.0)
	g.p.state = "idle"
	g.p.cds.erase("aimed")
	g.cast("aimed")
	g.p.inv = 0.0
	g.hurt(5.0)
	check("hunter: a blow while drawing loses the shot", g.p.state != "aim")
	await frames(40)
	g.p.focused = false
	g.sim.mouse = a.pos
	await cast("rain")
	ha = a.hp
	await frames(80)
	check("hunter: Arrow Rain keeps hitting the area", a.hp < ha)
	await hero(15, {"snare": 1, "mine": 1})
	await cast("snare")
	await cast("snare")
	await cast("snare")
	await cast("snare")
	check("hunter: at most three traps, the oldest goes", g.traps.size() == 3)
	a = dummy("reed", Vector2(0, 0))
	a.pos = g.traps[2].pos
	await frames(10)
	check("hunter: a snare roots what steps on it", a.get("root", 0.0) > 0.0 and g.traps.size() < 3)
	await hero(15, {"sic": 1, "hunt": 1})
	await frames(5)
	a = dummy("porter", Vector2(80, 0))
	g.sim.mouse = a.pos
	await cast("hunt")
	check("hunter: Hunter's Mark marks one foe for 15% more", a.get("hunt", 0.0) > 0.0 and absf(g.dmg_mult(a) - 1.15) < 0.02)
	g.p.state = "idle"
	ha = a.hp
	g.cast("sic")
	await frames(2)
	check("hunter: Sic pounces, bites and holds the foe", a.hp < ha and a.get("root", 0.0) > 0.0)
	var pt = g.pets[0]
	pt.hp = 1.0
	g.pet_down(pt)
	check("hunter: a fallen hound is down for 12 seconds", absf(pt.down - 12.0) < 0.5)
	await hero(15, {"pack": 1})
	await frames(5)
	check("hunter keystone Pack: two hounds, each 60%", g.pets.size() == 2 and absf(g.pet_mhp() - g.stats.mhp * 0.4 * 0.6) < 1.0)
	await hero(15, {"oneshot": 1})
	a = dummy("porter", Vector2(60, 0))
	var full = a.hp
	g.ranged = true
	g.arrow_hit(a, {"mult": 1.0, "hit": []})
	var first_hit = full - a.hp
	var h2 = a.hp
	g.arrow_hit(a, {"mult": 1.0, "hit": []})
	g.ranged = false
	check("hunter keystone One Shot: an arrow on a foe at full life hits twice as hard", first_hit > (h2 - a.hp) * 1.6)
	a = dummy("porter", Vector2(60, 0))
	await hero(15, {"bighunt": 1})
	await frames(5)
	a = dummy("reed", Vector2(60, 0))
	b = dummy("reed", Vector2(-60, 40))
	await cast("bighunt")
	check("hunter ultimate The Hunt: every foe near is marked and focus is full", a.get("hunt", 0.0) > 0.0 and b.get("hunt", 0.0) > 0.0 and g.p.focused)

	# ================================================================ Priest (m 21)
	await hero(21, {"knell": 1, "holy": 1, "seal": 1, "purge": 1, "bless": 1, "vow": 1})
	check("priest: devotion is shown", g.uses_devo())
	g.p.hp = g.stats.mhp * 0.4
	await cast("knell")
	check("priest: Temple Drum heals a quarter, and healing feeds devotion", absf(g.p.hp - g.stats.mhp * 0.65) < 2.0 and g.p.devo > 5.0)
	g.p.hp = g.stats.mhp * 0.5
	var dv = g.p.devo
	await cast("holy")
	await frames(60)
	check("priest: Holy Ground heals 3% a second and feeds devotion while you stand in it", g.p.hp > g.stats.mhp * 0.52 and g.p.devo > dv + 5.0)
	a = dummy("porter", Vector2(60, 0))
	g.sim.mouse = a.pos
	ha = a.hp
	await cast("seal")
	check("priest: Seal hits with holy light and lights the foe", a.hp < ha and a.get("lit", 0.0) > 0.0)
	check("priest: a lit foe takes 5% more", absf(g.dmg_mult(a) - 1.05) < 0.01)
	a.elite = "warding"
	b = dummy("porter", Vector2(40, 30))
	check("priest: a warding elite shields the foes near it", g.warded(b))
	a.pos = g.p.pos + Vector2(40, 0)
	await cast("purge")
	check("priest: Purge strips its mark for a while", a.get("purge", 0.0) > 0.0 and not g.warded(b))
	await cast("bless")
	check("priest: Blessing gives 15% more damage", absf(g.dmg_mult(dummy("reed", Vector2(200, 0))) - 1.15) < 0.01)
	await cast("vow")
	g.p.hp = 5.0
	g.p.inv = 0.0
	g.hurt(500.0)
	check("priest: under the Vow you cannot fall below 1 life", g.p.hp >= 1.0 and g.p.state != "dead")
	await hero(21, {"vigil": 1})
	await cast("vigil")
	g.p.hp = 5.0
	g.p.inv = 0.0
	g.hurt(500.0)
	check("priest ultimate Third Watch: you come back at 40%", absf(g.p.hp - g.stats.mhp * 0.4) < 1.0 and g.p.state != "dead")
	await hero(21, {"vein": 1, "knell": 1})
	g.p.hp = g.stats.mhp * 0.3
	await cast("knell")
	var mid = g.p.hp
	await frames(240)
	check("priest keystone One Vein: heals spread over time and come out stronger", mid < g.stats.mhp * 0.5 and g.p.hp > g.stats.mhp * 0.6)
	await hero(21, {"zeal": 1, "seal": 1})
	g.p.devo = 99.0
	g.add_devo(5.0)
	a = dummy("porter", Vector2(60, 0))
	g.sim.mouse = a.pos
	g.p.state = "idle"
	g.cast("seal")
	check("priest keystone Zeal: with full devotion the Seal has no cooldown", not g.p.cds.has("seal"))

	# ================================================================ Artificer (m 28)
	await hero(28, {"turret": 1, "bellmine": 1, "vent": 1, "boost": 1, "hook": 1, "mute": 1})
	check("artificer: heat is shown", g.uses_heat())
	var r0 = g.p.rage
	await cast("turret")
	check("artificer: Crossbow Turret costs no rage, adds 25 heat and stands", g.p.rage > r0 - 5.0 and g.p.heat > 18.0 and g.p.heat <= 25.0 and g.devices.size() == 1)
	a = dummy("porter", Vector2(80, 0))
	ha = a.hp
	await frames(60)
	check("artificer: the turret shoots the nearest foe", a.hp < ha)
	await cast("bellmine")
	await cast("turret")
	await cast("turret")
	check("artificer: at most three devices", g.devices.filter(func(dd): return not dd.free).size() == 3)
	g.p.heat = 60.0
	ha = a.hp
	a.pos = g.p.pos + Vector2(30, 0)
	g.p.aim = Vector2.RIGHT
	g.sim.mouse = a.pos
	await cast("vent")
	check("artificer: Vent spends all heat as damage in a cone", g.p.heat < 1.0 and ha - a.hp > g.stats.atk * 1.2)
	g.p.heat = 50.0
	await cast("boost")
	check("artificer: Boost adds 40 heat and speeds the strikes", g.p.heat > 85.0 and g.p.boost_t > 0.0)
	g.add_heat(20.0)
	check("artificer: at 100 the kit overheats and its skills stop", g.p.over > 0.0 and not g.can_cast("turret"))
	await hero(28, {"hook": 1, "mute": 1})
	a = dummy("reed", Vector2(110, 0))
	g.sim.mouse = a.pos
	await cast("hook")
	check("artificer: Grapple Hook pulls a light foe to you", a.pos.distance_to(g.p.pos) < 40.0)
	var heavy = dummy("porter", Vector2(-120, 0))
	var from = g.p.pos
	g.sim.mouse = heavy.pos
	g.p.cds.erase("hook")
	g.p.heat = 0.0
	await cast("hook")
	check("artificer: or pulls you to a heavy one", g.p.pos.distance_to(heavy.pos) < 40.0 and from.distance_to(g.p.pos) > 60.0)
	b = dummy("reed", Vector2(60, 0))
	b.state = "wind"
	b.st = 0.0
	b.wind = 9.0
	g.sim.mouse = b.pos
	g.p.heat = 0.0
	await cast("mute")
	check("artificer: Mute Bell cuts short a wind-up inside it", b.state != "wind")
	await hero(28, {"overdrive": 1})
	g.p.heat = 140.0
	var hpo = g.p.hp
	await frames(60)
	check("artificer keystone Overdrive: heat past 100 without overheating, at a cost in life", g.p.over <= 0.0 and g.p.hp < hpo)
	await hero(28, {"prototype": 1, "turret": 1, "spin": 1, "lunge": 1, "slam": 1, "rush": 1, "bulwark": 1, "hook": 1}, 0)
	g.proto = "hook"
	check("artificer keystone Prototype: a sixth slot for an Artificer skill", g.tree.has("prototype") and g.proto == "hook")
	g.sim.s6 = true
	await frames(2)
	g.sim.s6 = false
	await frames(20)
	check("artificer keystone Prototype: key 6 casts it", g.p.cds.has("hook"))

	# ================================================================ solo trees (Độc Tấu)
	await hero(0, {"spin": 1}, 1)
	check("solo: the fourth tab is the solo tree of the main mastery", g.tabs()[3] == 36)
	check("solo: a mastery skill can take three more ranks while the second is empty", Sk.max_rank(g.tree, "spin", true, 0, g.sec()) == 4)
	g.tree = {"lunge": 4}
	check("solo: each extra rank makes the cooldown 6% shorter", absf(g.skill_cd("lunge") - Sk.NODES.lunge.cd * 0.82) < 0.01)
	check("solo: and then the second mastery is locked", Sk.blocked(g.tree, "ember", 60, true, 0, 1) == Sk.SOLO_TAKEN)
	g.tree = {"ember": 1, "spin": 1, "lunge": 1, "slam": 1}
	check("solo: a point in the second mastery locks the solo tree", Sk.blocked(g.tree, "ocb_parry", 60, true, 0, 1) == Sk.SOLO_LOCKED)
	g.tree = {"spin": 1, "lunge": 1, "slam": 1}
	check("solo: three points in the main mastery open the solo tree", Sk.blocked(g.tree, "ocb_parry", 60, true, 0, 1) == "")
	check("solo: its keystone needs six", Sk.blocked(g.tree, "ocb_master", 60, true, 0, 1) != "")

	print("DONE %d failed" % fails)
	quit(1 if fails > 0 else 0)
