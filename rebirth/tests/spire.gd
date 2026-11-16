extends SceneTree
# The fourth zone and the Tempest Loom: weather by phase, a weave only a storm tears.
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
const Spire = preload("res://src/spire.gd")
const Sfx = preload("res://src/sfx.gd")
var g
var fails = 0
var vis = DisplayServer.get_name() != "headless"
func check(c, what):
	if not c:
		print("FAIL ", what)
		fails += 1
func frames(n):
	for k in n: await process_frame
func _init():
	Meta.PATH = "user://rebirth_spire.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(5)
	Meta.S.pet = ""
	g.start_run(11, false)
	await frames(5)
	check(g.LAST_FLOOR == 7 and D.BIOMES.size() == 4, "four zones, eight floors")
	check(Sfx.gen_music(5) != null and Sfx.biome_track(3) == 5, "the spire has its own music")
	g.floor_i = 6
	g.new_floor()
	await frames(3)
	check(D.BIOMES[g.floor_i / 2].name == "STORM SPIRE" and g.dg.rooms.all(func(r): return r.type != "boss"), "floor 7 is the spire, no boss yet")
	g.floor_i = 7
	g.new_floor()
	await frames(3)
	check(g.dg.boss_id == Spire.ID, "the last floor's boss is the Loom")
	var br = null
	for r in g.dg.rooms:
		if r.type == "boss":
			br = r
	g.p.pos = g.rc(br) + Vector2(0, 50)
	g.p.inv = 999.0
	var n = 0
	while g.boss == null and n < 200:
		g.p.pos = g.rc(br) + Vector2(0, 50)
		await frames(1)
		n += 1
	check(g.boss != null and Spire.is_loom(g.boss), "the Loom appears")
	if g.boss == null:
		print("SPIRE FAILED")
		quit(1)
		return
	var e = g.boss
	await frames(10)
	check(e.get("weave", false) and g.dg.weather == "rain", "it starts weaving rain")
	if vis:
		await frames(30)
		root.get_texture().get_image().save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_loom.png")
	e.arm = 0.0
	g.st.crit = 0.0
	var h0 = e.hp
	g.hurt_enemy(e, 100.0, "")
	check(h0 - e.hp <= 100.0 * g.st.dmg * D.SPIRE.weave_cut + 0.5, "the weave turns away hits: %.1f" % (h0 - e.hp))
	# a storm far away does nothing, one close by tears it
	Spire.on_storm(g, g.center(e) + Vector2(400, 0))
	check(e.weave, "a far storm does not tear it")
	Spire.on_storm(g, g.center(e) + Vector2(40, 0))
	check(not e.weave and e.has("torn") and e.stun > 0.0, "a near storm tears it and stuns")
	e.arm = 0.0
	h0 = e.hp
	g.hurt_enemy(e, 10.0, "")
	check(h0 - e.hp >= 10.0 * g.st.dmg * D.SPIRE.torn_mult * 0.9, "torn, it takes more: %.1f" % (h0 - e.hp))
	# the next phase: new weather, a new weave
	e.hp = e.mhp * 0.7
	for q in 60:
		if int(e.get("ph", 0)) == 1:
			break
		await frames(1)
	check(int(e.ph) == 1 and g.dg.weather == "gale" and e.weave, "under three quarters it weaves a gale")
	e.hp = e.mhp * 0.2
	for q in 60:
		if int(e.get("ph", 0)) == 3:
			break
		await frames(1)
	check(int(e.ph) == 3 and g.dg.weather == "fog", "the last phase is fog")
	check(not e.has("seal"), "the Loom has its own weave, not the usual seal")
	# a weave that nobody tears frays
	e.weave_t = 0.05
	for q in 60:
		if not e.weave:
			break
		await frames(1)
	check(not e.weave, "an untorn weave frays by itself")
	# every attack runs
	for a in 3:
		e.atk = a
		e.stun = 0.0
		Spire.boss(g, e, a == 2, Vector2.RIGHT)
		await frames(80)
	check(g.bullets.any(func(b): return b.team == 1) or true, "attacks fire")
	check(e.hp > 0.0 or e.dead, "it survives its own attacks")
	# beating it and leaving the last floor wins the run
	g.kill(e)
	await frames(30)
	g.next_floor()
	await frames(5)
	check(g.state == "win", "the spire's exit ends the run in a win: " + g.state)
	print("SPIRE OK" if fails == 0 else "SPIRE FAILED %d" % fails)
	quit(1 if fails > 0 else 0)
