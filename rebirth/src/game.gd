extends Node2D
# Dungeon Core: Elemental Rebirth - main game. Everything is simulated and drawn from here:
# no physics engine, no scene files, all actors are plain dictionaries.

const Art = preload("res://src/art.gd")
const Px = preload("res://src/font.gd")
const Sfx = preload("res://src/sfx.gd")
const D = preload("res://src/data.gd")
const Dungeon = preload("res://src/dungeon.gd")
const Hud = preload("res://src/hud.gd")
const Meta = preload("res://src/meta.gd")
const Ext = preload("res://src/ext.gd")
const Lobby = preload("res://src/lobby.gd")
const Talk = preload("res://src/talk.gd")
const More = preload("res://src/more.gd")
const Touch = preload("res://src/touch.gd")
const Pad = preload("res://src/pad.gd")
const Net = preload("res://src/net.gd")
const Hub = preload("res://src/hub.gd")
const Traps = preload("res://src/traps.gd")
const Fx = preload("res://src/fx.gd")
const Foes = preload("res://src/foes.gd")

const VW = 480.0
const VH = 270.0
const TS = 16
const LAST_FLOOR = 5
const BDEF = {team = 0, dmg = 1.0, el = "", r = 2.0, life = 1.5, pierce = 0, bounce = 0, aoe = 0.0, kind = "orb", lob = false}

const POST = """
shader_type canvas_item;
uniform sampler2D scr : hint_screen_texture, filter_nearest;
uniform sampler2D light : filter_linear;
uniform float tint_a = 0.0;
const float B[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
void fragment() {
	vec3 c = texture(scr, SCREEN_UV).rgb;
	vec3 l = texture(light, SCREEN_UV).rgb;
	ivec2 q = ivec2(FRAGCOORD.xy);
	float d = B[(q.x & 3) + (q.y & 3) * 4] / 16.0;
	float m = max(l.r, max(l.g, l.b)) + 0.0001;
	float lv = floor(m * 9.0 + d) / 9.0;
	l *= lv / m;
	c *= l * 2.0;
	vec2 v = SCREEN_UV - 0.5;
	c *= 1.0 - dot(v, v) * 0.8;
	c = mix(c, vec3(0.75, 0.05, 0.1), tint_a);
	COLOR = vec4(c, 1.0);
}
"""

class Layer extends Node2D:
	var fn: Callable
	func _draw() -> void:
		fn.call(self)

class HudLayer extends Control:
	var fn: Callable
	func _draw() -> void:
		fn.call(self)

var state = "title"
var state_t = 0.0
var rng = RandomNumberGenerator.new()
var time = 0.0
var hitstop = 0.0
var shake = 0.0
var cam = Vector2.ZERO
var cam_tl = Vector2.ZERO
var fade = 1.0
var dmg_flash = 0.0
var jp = {}
var sim = {}  # test harness input: {"mouse": Vector2, "fire": bool, KEY_*: true}
var sel_hero = 0
var sel_el = 0

var p = {}
var st = {}
var floor_i = 0
var dg = {}
var room = null
var lock = null
var pending = 0
var wave_wait = 0.0
var enemies = []
var bullets = []
var zones = []
var pickups = []
var props = []
var inter = []
var teles = []
var timers = []
var parts = []
var nums = []
var bolts = []
var rings = []
var slashes = []
var flashes = []
var ghosts = []
var near = null
var boss = null
var banner = {text = "", sub = "", t = 0.0}
var buff_choices = []
var kills = 0
var run_time = 0.0
var uid = 0
var in_lobby = false
var menu = {kind = "", sel = 0, rows = [], msg = ""}
var talk = {who = "", name = "", spr = "", lines = [], i = 0, t = 0.0, then = ""}
var buff_stay = false
var gems_won = 0
var boss_kills = 0
var prism_next = false
var session_cat = false
var juke = 4
var crack_hp = 10
var dummy_hits = 0
var code_i = 0
var allies = []
var traps = []
var tin = Touch.fresh()
# every hero in the run; p and st always point at the one currently being simulated or drawn
var players = []
var me = 0
var cin = null
var net = Net.fresh()
var local2 = false
var local2_hero = -1
var pad_p2_first = false
var pad_jp = {}
var pad_lt = {}
var pad_flick = {}
var pad_used = false
var p1_pad = false
var sim_p2 = null
var pending_coop = false
var pending_resume = false
var buff_sel = 0
var buff_turn = 0
var pending_start = null
var menu_close = false
var menu_plot = 0
var seed_in = ""
var drng = RandomNumberGenerator.new()
var run_seed = 0
var run_daily = false
var run_heat = 0
var run_score = 0

var world: Node2D
var ground: Sprite2D
var scene_layer: Layer
var over: Sprite2D
var top: Layer
var light_vp: SubViewport
var light_bg: ColorRect
var lights: Layer
var post: ColorRect
var hud: HudLayer

# ---- boot ------------------------------------------------------------------------

func _ready() -> void:
	rng.randomize()
	Art.build()
	Px.build()
	Sfx.init(self)
	world = Node2D.new()
	add_child(world)
	ground = Sprite2D.new()
	ground.centered = false
	world.add_child(ground)
	scene_layer = Layer.new()
	scene_layer.fn = draw_scene
	world.add_child(scene_layer)
	over = Sprite2D.new()
	over.centered = false
	world.add_child(over)
	top = Layer.new()
	top.fn = draw_top
	world.add_child(top)

	light_vp = SubViewport.new()
	light_vp.size = Vector2i(int(VW), int(VH))
	light_vp.disable_3d = true
	light_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(light_vp)
	light_bg = ColorRect.new()
	light_bg.size = Vector2(VW, VH)
	light_bg.color = Color(0.2, 0.2, 0.3)
	light_vp.add_child(light_bg)
	lights = Layer.new()
	lights.fn = draw_lights
	var lm = CanvasItemMaterial.new()
	lm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	lights.material = lm
	light_vp.add_child(lights)

	var cl = CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	post = ColorRect.new()
	post.size = Vector2(VW, VH)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh = Shader.new()
	sh.code = POST
	var sm = ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("light", light_vp.get_texture())
	post.material = sm
	cl.add_child(post)

	var hl = CanvasLayer.new()
	hl.layer = 10
	add_child(hl)
	hud = HudLayer.new()
	hud.fn = func(ci): Hud.draw(self, ci)
	hud.size = Vector2(VW, VH)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hl.add_child(hud)

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	tin.on = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	Meta.load_save()
	apply_opts()
	multiplayer.connected_to_server.connect(func(): Net.on_connected(self))
	multiplayer.connection_failed.connect(func(): Net.on_failed(self))
	multiplayer.server_disconnected.connect(func(): Net.on_peer_left(self))
	multiplayer.peer_disconnected.connect(func(_id): Net.on_peer_left(self))
	goto_title()

func apply_opts() -> void:
	var o = Meta.S.opts
	Sfx.set_volume(int(o.get("sfx", 4)) / 4.0, int(o.get("music", 4)) / 4.0)
	if DisplayServer.get_name() != "headless":
		var want = DisplayServer.WINDOW_MODE_FULLSCREEN if o.get("full", false) else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)

# One-time hint shown the first time something happens.
func tip(id: String, text: String, sub: String) -> void:
	if in_lobby or Meta.S.tips.has(id):
		return
	Meta.S.tips[id] = true
	banner = {text = text, sub = sub, t = 4.5}

# Picks up the run saved at the start of its last floor.
func resume_run() -> void:
	var r = Meta.S.run
	var pl = str_to_var(str(r.player))
	if not (pl is Dictionary):
		Meta.S.run = {}
		return
	in_lobby = false
	local2 = false
	pl.idx = 0
	pl.down = false
	pl.spr = Art.look(pl.look)
	players = [pl]
	me = 0
	bind(pl)
	calc_stats()
	run_seed = int(r.seed)
	run_daily = bool(r.daily)
	run_heat = int(r.heat)
	floor_i = int(r.floor)
	kills = int(r.kills)
	boss_kills = int(r.bk)
	run_time = float(r.time)
	world.visible = true
	post.visible = true
	new_floor()
	set_state("play")
	Sfx.play("portal")

func set_state(s: String) -> void:
	state = s
	state_t = 0.0

func goto_title() -> void:
	set_state("title")
	world.visible = false
	post.visible = false
	fade = 1.0
	Sfx.play_music(4)

func goto_lobby() -> void:
	world.visible = true
	post.visible = true
	fade = 1.0
	Lobby.build(self)
	set_state("play")

func start_talk(who: String, then: String = "") -> void:
	talk = {who = who, name = Talk.WHO[who].name, spr = Talk.WHO[who].spr, lines = Talk.lines(self, who), i = 0, t = 0.0, then = then}
	set_state("talk")
	Sfx.play("ui")

func open_menu(kind: String) -> void:
	if kind == "coop":
		Net.listen(self)
	menu = {kind = kind, sel = 0, rows = Lobby.rows(self, kind), msg = ""}
	set_state("menu")
	Sfx.play("ui")

func update_menu() -> void:
	var n = menu.rows.size()
	if jpk(KEY_ESCAPE) or (jpk(KEY_E) and state_t > 0.2) or (tin.on and jpk("m1") and Rect2(364, 28, 28, 18).has_point(mouse())):
		set_state("play")
		return
	var step = 3 if menu.kind == "tree" else 1
	if jpk(KEY_S) or jpk(KEY_DOWN):
		menu.sel = (menu.sel + 1) % n
	if jpk(KEY_W) or jpk(KEY_UP):
		menu.sel = (menu.sel + n - 1) % n
	if menu.kind == "tree":
		if jpk(KEY_D) or jpk(KEY_RIGHT):
			menu.sel = (menu.sel + step) % n
		if jpk(KEY_A) or jpk(KEY_LEFT):
			menu.sel = (menu.sel + n - step) % n
	if menu.kind == "coop" and net.mode == "":
		var was: String = net.ip_in
		for d in 10:
			if (jpk(KEY_0 + d) or jpk(KEY_KP_0 + d)) and net.ip_in.length() < 15:
				net.ip_in += str(d)
		if (jpk(KEY_PERIOD) or jpk(KEY_KP_PERIOD)) and net.ip_in.length() < 15:
			net.ip_in += "."
		if jpk(KEY_BACKSPACE) and net.ip_in != "":
			net.ip_in = net.ip_in.substr(0, net.ip_in.length() - 1)
		if net.ip_in != was:
			Net.refresh_menu(self)
	if menu.kind == "board":
		var before = seed_in
		for d in 10:
			if (jpk(KEY_0 + d) or jpk(KEY_KP_0 + d)) and seed_in.length() < 8:
				seed_in += str(d)
		if jpk(KEY_BACKSPACE) and seed_in != "":
			seed_in = seed_in.substr(0, seed_in.length() - 1)
		if seed_in != before:
			menu.rows = Lobby.rows(self, "board")
			menu.sel = 2
	var go = jpk(KEY_ENTER) or jpk(KEY_SPACE)
	var m = mouse()
	for i in n:
		if Hud.menu_rect(menu.kind, i).has_point(m):
			if jpk("m1"):
				menu.sel = i
				go = true
			elif sim.is_empty() and Input.get_last_mouse_velocity().length() > 1.0:
				menu.sel = i
	if go and state_t > 0.2:
		Lobby.activate(self, menu.rows[menu.sel])

# Ends a run: converts what you did into gems and teaches the foes a little.
func end_run(won: bool) -> void:
	Meta.S.run = {}
	if net.mode == "host" and players.size() > 1 and players[1].get("remote", false):
		rpc("net_event", "end", {floor = floor_i, won = won})
	gems_won = int((floor_i * 8 + kills / 5 + boss_kills * 20 + (60 if won else 0)) * (1.0 + 0.3 * run_heat))
	run_score = floor_i * 100 + kills + boss_kills * 50 + (500 if won else 0)
	Meta.S.gems += gems_won
	Meta.S.runs += 1
	Meta.S.best = max(Meta.S.best, floor_i + 1)
	if run_daily:
		var dk = str(Meta.today())
		Meta.S.daily[dk] = max(int(Meta.S.daily.get(dk, 0)), run_score)
	# plants grow one stage per finished run
	for pl in Meta.S.garden:
		if pl.kind != "" and int(pl.left) > 0:
			pl.left = int(pl.left) - 1
	if won:
		Meta.S.wins += 1
		Meta.add_cunning(0.06)
		if run_heat >= Meta.S.heat_max and not run_daily:
			Meta.S.heat_max = min(D.HEAT.size(), run_heat + 1)
	else:
		Meta.add_cunning(-0.04)
	Meta.save()
	set_state("win" if won else "dead")

# ---- input -----------------------------------------------------------------------

func _input(ev: InputEvent) -> void:
	if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
		Pad.handle(self, ev)
		return
	if ev is InputEventScreenTouch or ev is InputEventScreenDrag:
		Touch.handle(self, ev)
		return
	if tin.on and ev is InputEventMouseButton:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		jp[ev.physical_keycode] = true
		p1_pad = false
	elif ev is InputEventMouseButton and ev.pressed:
		jp["m%d" % ev.button_index] = true
		p1_pad = false

# cin is set while a pad or remote player is being simulated; it replaces keyboard and mouse.
func jpk(k) -> bool:
	if cin != null:
		return cin.jp.has(k)
	return jp.has(k)

func key(k: int) -> bool:
	if cin != null:
		return false
	return sim.has(k) or Input.is_physical_key_pressed(k)

func mouse() -> Vector2:
	if cin != null:
		return cin.mw - cam_tl
	if p1_pad and state == "play" and not p.is_empty():
		return pcenter() - cam_tl + p.aim * 60.0
	if sim.has("mouse"):
		return sim["mouse"]
	if tin.on:
		if state == "play" and not p.is_empty():
			return pcenter() - cam_tl + p.aim * 80.0
		return tin.tap
	return get_viewport().get_mouse_position()

func firing() -> bool:
	if cin != null:
		return cin.fire
	if tin.on:
		return tin.fire
	return sim.get("fire", false) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

# ---- main loop -------------------------------------------------------------------

func _process(dt: float) -> void:
	dt = minf(dt, 1.0 / 30.0)
	time += dt
	state_t += dt
	fade = maxf(0.0, fade - dt * 1.6)
	dmg_flash = maxf(0.0, dmg_flash - dt * 3.0)
	banner.t -= dt
	Pad.frame(self)
	Net.poll(self, dt)
	match state:
		"title":
			update_title()
		"play":
			if jpk(KEY_ESCAPE):
				set_state("pause")
				Sfx.play("ui")
			elif net.mode == "client" and not in_lobby:
				Net.client_tick(self, dt)
				update_fx(dt)
			elif hitstop > 0.0:
				hitstop -= dt
			else:
				update_play(dt)
				update_fx(dt)
		"pause":
			var tq = tin.on and jpk("m1") and state_t > 0.2
			if jpk(KEY_O) or jpk(KEY_E) or (tq and Rect2(185, 204, 110, 18).has_point(mouse())):
				open_menu("opts")
			elif jpk(KEY_ESCAPE) or (tq and not Rect2(250, 226, 110, 20).has_point(mouse())):
				set_state("play")
			elif jpk(KEY_Q) or tq:
				if in_lobby:
					goto_title()
				elif net.mode == "client":
					Net.leave(self)
					goto_lobby()
				else:
					end_run(false)
		"buff":
			update_buff()
		"menu":
			update_menu()
		"talk":
			talk.t += dt
			if jpk(KEY_ESCAPE):
				talk.i = talk.lines.size()
			elif state_t > 0.15 and (jpk(KEY_E) or jpk(KEY_ENTER) or jpk(KEY_SPACE) or jpk("m1")):
				if talk.t * 55.0 < talk.lines[talk.i].length():
					talk.t = 99.0
				else:
					talk.i += 1
					talk.t = 0.0
					Sfx.play("ui")
			if talk.i >= talk.lines.size():
				if talk.then != "":
					open_menu(talk.then)
				else:
					set_state("play")
		"dead", "win":
			update_fx(dt)
			if state_t > 1.0 and (jpk(KEY_ENTER) or jpk(KEY_R) or jpk(KEY_SPACE) or jpk("m1")):
				goto_lobby()
	cin = null
	if state != "title" and me < players.size():
		bind(players[me])
	if state != "title" and not p.is_empty():
		var target = p.pos + (mouse() - Vector2(VW, VH) / 2.0) * 0.16
		if local_coop():
			# shared screen: keep the camera between the heroes still standing
			var sum = Vector2.ZERO
			var cnt = 0
			for pl in players:
				if not pl.down:
					sum += pl.pos
					cnt += 1
			if cnt > 0:
				target = sum / cnt
		cam = cam.lerp(target, minf(1.0, dt * 9.0))
		shake = maxf(0.0, shake - dt * 22.0)
		var sh = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake
		cam_tl = (cam - Vector2(VW, VH) / 2.0 + sh).round()
		world.position = -cam_tl
	post.material.set_shader_parameter("tint_a", dmg_flash * 0.3)
	scene_layer.queue_redraw()
	top.queue_redraw()
	lights.queue_redraw()
	hud.queue_redraw()
	jp.clear()
	pad_jp.clear()

func update_title() -> void:
	if state_t > 0.3 and (jpk(KEY_ENTER) or jpk(KEY_SPACE) or jpk("m1") or jpk(KEY_E)):
		Sfx.play("portal")
		goto_lobby()

func update_buff() -> void:
	var pick = -1
	var nb = buff_choices.size()
	if jpk(KEY_LEFT):
		buff_sel = (buff_sel + nb - 1) % nb
	if jpk(KEY_RIGHT):
		buff_sel = (buff_sel + 1) % nb
	if pad_used and jpk(KEY_ENTER):
		pick = buff_sel % nb
	for i in buff_choices.size():
		if jpk(KEY_1 + i):
			pick = i
		if jpk("m1") and Hud.buff_rect(i).has_point(mouse()):
			pick = i
	if pick >= 0 and state_t > 0.3:
		pick_buff(pick)

# ---- run / floor setup -----------------------------------------------------------

func build_player(hi: int, fi: int, el: String, idx: int) -> Dictionary:
	var h = Meta.hero(hi)
	var hid: String = h.id
	var hkey = Meta.hero_key(h)
	var tkey = hkey
	var lv = Meta.hero_lv(hkey)
	var hp = h.hp + (1 if lv >= 1 else 0) + (1 if lv >= 5 else 0)
	var ar = h.ar + (1 if lv >= 2 else 0) + (1 if lv >= 5 else 0)
	var en = h.en + (40 if lv >= 3 else 0)
	var nm: String = h.name
	var sk2: String = h.skill2
	var look = {k = "base", a = hid, b = "", seed = Meta.S.gen_seed, dye = Hub.dye_shift()}
	if fi >= 0 and fi != hi:
		var h2 = Meta.hero(fi)
		hp = max(hp, h2.hp)
		ar = max(ar, h2.ar)
		en = (en + h2.en) / 2 + 20
		sk2 = h2.skill
		nm = Meta.fuse_name(h, h2)
		tkey = Meta.fuse_key(h, h2)
		look = {k = "fuse", a = hid, b = h2.id, seed = Meta.S.gen_seed, dye = Hub.dye_shift()}
	var pl = {
		idx = idx, down = false, hero_i = hi, look = look, spr = Art.look(look),
		hero = h, name = nm, hkey = hkey, tkey = tkey, haste_t = 0.0, rage_t = 0.0, skills = [h.skill, sk2], pos = Vector2.ZERO, r = 4.0,
		hp = hp, mhp = hp, ar = ar, mar = ar, en = float(en), men = en,
		weapons = [{id = h.start, el = el, el2 = "", lv = 0}, null], wi = 0,
		cd = 0.0, dash_t = 0.0, dash_cd = 0.0, dash_dir = Vector2.RIGHT, dash_hit = [], inv = 0.0, ar_t = 0.0, ar_tick = 0.0,
		skill_cd = 0.0, skill2_cd = 0.0, face = 1, aim = Vector2.RIGHT, walk = 0.0, moving = false, gold = 0, buffs = [],
		slow = 0.0, flash = 0.0, kick = 0.0, swing = 0.0, spin = 0.0, spin_tick = 0.0, beam_n = 0, noregen = 0.0,
		syn = [], syn_t = 0.0, relics = [], active = null, keys = 0, feather = false, skin_ready = true, fang_n = 0,
		shield_t = 0.0, res = 0.0, v = Vector2.ZERO, room_hits = 0, wind2 = false, lvdmg = lv >= 4, pet = null, mount = null,
	}
	pl.sk = Meta.calc_sk(tkey)
	if Meta.S.pet != "" and Meta.PETS.has(Meta.S.pet):
		pl.pet = {id = Meta.S.pet, pos = Vector2.ZERO, t = 1.0, face = 1, moving = false}
	if Meta.S.mount != "" and Meta.MOUNTS.has(Meta.S.mount):
		var md = Meta.MOUNTS[Meta.S.mount]
		pl.mount = {id = Meta.S.mount, hp = md.hp, mhp = md.hp, spd = md.spd}
	var keep = p
	p = pl
	calc_stats()
	if keep.has("st"):
		bind(keep)
	return pl

func make_player() -> void:
	if Meta.S.gen_seed != 0:
		Art.gen_hero(Meta.S.gen_seed)
	var pl = build_player(Meta.S.hero, Meta.S.fuse if Meta.S.fuse_unlocked else -1, "prism" if prism_next else D.EL[Meta.S.el], 0)
	if players.is_empty():
		players = [pl]
	else:
		players[0] = pl
	me = 0
	bind(pl)

func bind(pl: Dictionary) -> void:
	p = pl
	st = pl.st

# The standing hero closest to a point: who foes chase and who picks things up.
func target_for(pos: Vector2) -> Dictionary:
	var best = players[0]
	var bd = INF
	for pl in players:
		if pl.down:
			continue
		var d = pl.pos.distance_squared_to(pos)
		if d < bd:
			bd = d
			best = pl
	return best

func local_coop() -> bool:
	return players.size() > 1 and net.mode != "client" and not players[1].get("remote", false)

func set_local2(on: bool) -> void:
	local2 = on
	players = players.slice(0, 1)
	if on:
		if local2_hero < 0 or local2_hero >= Meta.hero_count():
			local2_hero = (Meta.S.hero + 1) % Meta.hero_count()
		var pl = build_player(local2_hero, -1, D.EL[(Meta.S.el + 1) % 4], 1)
		pl.pos = players[0].pos + Vector2(16, 0)
		if pl.pet != null:
			pl.pet.pos = pl.pos
		players.append(pl)
		banner = {text = "PLAYER 2 JOINED", sub = pl.name, t = 2.5}
		Sfx.play("pick")
	bind(players[0])

func kb2() -> bool:
	return local_coop() and sim_p2 == null and Pad.device_for(self, 1) == -1

func arrow(k: int) -> bool:
	return key(k) and not kb2()

func input_for(i: int):
	var pl = players[i]
	if pl.get("remote", false):
		return net.rin
	if i > 0 and sim_p2 != null:
		return sim_p2
	var dev = Pad.device_for(self, i)
	if i == 0:
		return Pad.read(self, pl, dev) if (dev != -1 and p1_pad) else null
	if dev == -1:
		return Pad.read_kb(self, pl)
	return Pad.read(self, pl, dev)

func find_near() -> void:
	near = null
	var bd = 24.0
	for it in inter:
		if (it.kind == "chest" and it.open) or it.kind == "deco" or (it.kind == "shrine" and it.used):
			continue
		var d = it.pos.distance_to(p.pos)
		if d < bd:
			bd = d
			near = it

# ---- LAN messages (see net.gd) ----------------------------------------------------

@rpc("any_peer", "call_remote", "reliable")
func net_hello(pd: Dictionary) -> void:
	if net.mode == "host":
		Net.on_hello(self, pd)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func net_input(mv: Vector2, mw: Vector2, fire: bool) -> void:
	if net.mode == "host":
		net.rin.mv = mv.limit_length(1.0)
		net.rin.mw = mw
		net.rin.fire = fire

@rpc("any_peer", "call_remote", "reliable")
func net_press(k) -> void:
	if net.mode == "host":
		net.rin.jp[k] = true

@rpc("authority", "call_remote", "unreliable_ordered")
func net_snap(data: PackedByteArray) -> void:
	Net.apply(self, data)

@rpc("authority", "call_remote", "reliable")
func net_event(kind: String, data: Dictionary) -> void:
	Net.on_event(self, kind, data)

func start_run(seed: int = 0, daily: bool = false) -> void:
	in_lobby = false
	make_player()
	prism_next = false
	run_seed = seed if seed != 0 else rng.randi_range(1, 99999999)
	run_daily = daily
	Meta.S.run = {}
	run_heat = 0 if daily else Meta.S.heat
	Meta.S.last_seed = run_seed
	if run_heat >= 5:
		p.mhp = max(1, p.mhp - 2)
		p.hp = p.mhp
	if not daily:
		Hub.apply_boons(self, More)
	Meta.record("weapons", p.weapons[0].id)
	floor_i = 0
	kills = 0
	boss_kills = 0
	run_time = 0.0
	world.visible = true
	post.visible = true
	new_floor()
	set_state("play")
	Sfx.play("portal")

func calc_stats() -> void:
	st = {dmg = 1.1 if p.lvdmg else 1.0, crit = 0.05, pierce = 0, bounce = 0, spd = 1.0, dashcd = 1.0, react = 1.0, dur = 1.0,
		free = 0.0, vamp = 0, cond = 0, magnet = 0, thorns = 0, res = 1.0, multi = 0, rate = 1.0, lens = false}
	for s in p.syn:
		match s:
			"arsenal": st.crit += 0.15
			"prismatic": st.react += 0.4
			"gunslinger":
				st.dmg += 0.15
				st.free += 0.2
	for r in p.relics:
		match r:
			"glass": st.dmg += 0.4
			"split":
				st.multi += 1
				st.dmg -= 0.15
			"clock": st.rate *= 0.85
			"lens": st.lens = true
	for b in p.buffs:
		match b:
			"catalyst": st.react += 0.6
			"linger": st.dur += 0.6
			"crit": st.crit += 0.15
			"bounce": st.bounce += 1
			"pierce": st.pierce += 1
			"swift":
				st.spd += 0.12
				st.dashcd *= 0.7
			"vamp": st.vamp += 1
			"free": st.free += 0.3
			"cond": st.cond += 1
			"fury": st.dmg += 0.2
			"magnet": st.magnet += 1
			"thorns": st.thorns += 1
			"surge": st.res += 0.5
	p.st = st

func rc(r: Dictionary) -> Vector2:
	return Vector2(r.center) * TS + Vector2(8, 8)

func clear_world() -> void:
	for l in [enemies, bullets, zones, pickups, inter, teles, timers, parts, nums, bolts, rings, slashes, flashes, ghosts]:
		l.clear()
	lock = null
	room = null
	boss = null
	near = null
	pending = 0
	allies.clear()
	traps = []

func rebake() -> void:
	var imgs = Dungeon.bake(dg, 0 if in_lobby else floor_i / 2)
	ground.texture = ImageTexture.create_from_image(imgs[0])
	over.texture = ImageTexture.create_from_image(imgs[1])

func shop_price(it: Dictionary) -> int:
	return int(it.price * (1.25 if p.relics.has("greed") else 1.0) * (1.3 if run_heat >= 3 else 1.0))

func new_floor() -> void:
	clear_world()
	var bi = floor_i / 2
	# the layout of a floor depends only on the run seed, so seeds can be shared
	drng.seed = hash([run_seed, floor_i])
	dg = Dungeon.generate(drng, floor_i, floor_i % 2 == 1)
	dg.boss_id = D.BIOMES[bi].bosses[drng.randi() % D.BIOMES[bi].bosses.size()]
	rebake()
	props = dg.props
	traps = dg.get("traps", [])
	light_bg.color = D.BIOMES[bi].ambient * 1.2
	for pl in players:
		pl.wind2 = pl.buffs.has("wind2")
		if pl.mount != null:
			pl.mount.hp = pl.mount.mhp
		if pl.down:
			pl.down = false
			pl.hp = max(1, pl.mhp / 2)
	for r in dg.rooms:
		var c = rc(r)
		match r.type:
			"start":
				for pl in players:
					pl.pos = c + Vector2(pl.idx * 14.0, 0)
				if floor_i == 0:
					var el = D.EL[(Meta.S.el + 1 + rng.randi() % 3) % 4]
					inter.append({kind = "weapon", w = {id = ["pistol", "scatter", "needle"][rng.randi() % 3], el = el, el2 = "", lv = 0}, pos = c + Vector2(34, 0)})
			"chest":
				inter.append({kind = "chest", pos = c, loot = "weapon", open = false})
				if drng.randf() < 0.6:
					inter.append({kind = "lchest", pos = c + Vector2(30, 0), open = false})
			"secret":
				inter.append({kind = "relic", id = More.random_relic(self), pos = c + Vector2(-16, 0)})
				inter.append({kind = "active", id = More.random_active(self), pos = c + Vector2(16, 0)})
			"exit":
				inter.append({kind = "portal", pos = c})
			"workshop":
				inter.append({kind = "talk", who = "smith", spr = "npc_smith", name = "TALK", pos = c + Vector2(-44, -22)})
				inter.append({kind = "smith", spr = "anvil", name = "UPGRADE WEAPON", pos = c + Vector2(-44, 4)})
				inter.append({kind = "talk", who = "alch", spr = "npc_alch", name = "TALK", pos = c + Vector2(0, -22)})
				inter.append({kind = "alch", spr = "cauldron", name = "CHANGE ELEMENT", pos = c + Vector2(0, 4)})
				inter.append({kind = "fuse", spr = "altar", name = "FUSE BOTH WEAPONS", pos = c + Vector2(44, 4)})
			"shrine":
				inter.append({kind = "shrine", spr = "altar", pos = c, used = false})
			"shop":
				inter.append({kind = "talk", who = "merchant", spr = "npc_merchant", name = "TALK", pos = c + Vector2(0, -34)})
				var items = [{type = "weapon", w = random_weapon()}, {type = "potion"}, {type = "tome", buff = D.BUFFS[rng.randi() % D.BUFFS.size()]}]
				items.append({type = "cell"})
				if rng.randf() < 0.4:
					items[2] = {type = "relic", id = More.random_relic(self)}
				for i in 4:
					var it = items[i]
					var price = 18 + floor_i * 4
					if it.type == "weapon":
						price = 24 + D.WEAPONS[it.w.id].rar * 18 + floor_i * 4
					elif it.type == "tome":
						price = 42 + floor_i * 6
					elif it.type == "cell":
						price = 9 + floor_i * 2
					elif it.type == "relic":
						price = 55 + floor_i * 6
					inter.append({kind = "shop", pos = c + Vector2((i - 1.5) * 40, -4), item = it, price = price})
	for pl in players:
		if pl.pet != null:
			pl.pet.pos = pl.pos
	cam = players[me].pos
	fade = 1.0
	banner = {text = D.BIOMES[bi].name, sub = "FLOOR %d-%d" % [bi + 1, floor_i % 2 + 1], t = 3.2}
	Sfx.play_music(bi)
	if net.mode == "host" and players.size() > 1 and players[1].get("remote", false):
		rpc("net_event", "floor", {floor = floor_i, boss = dg.boss_id})
	# solo runs are saved at the start of every floor after the first
	if players.size() == 1 and net.mode == "" and floor_i > 0:
		Meta.S.run = {seed = run_seed, daily = run_daily, heat = run_heat, floor = floor_i, kills = kills, bk = boss_kills, time = run_time, player = var_to_str(players[0])}
		Meta.save()

func random_weapon() -> Dictionary:
	var ids = []
	var wts = []
	var total = 0.0
	for id in D.WEAPONS:
		var wt = [5.0, 2.5 + floor_i * 0.5, 0.8 + floor_i * 0.5][D.WEAPONS[id].rar]
		ids.append(id)
		wts.append(wt)
		total += wt
	var roll = rng.randf() * total
	var pick = ids[0]
	for i in ids.size():
		roll -= wts[i]
		if roll <= 0.0:
			pick = ids[i]
			break
	var el = ""
	var er = rng.randf()
	if er < 0.74:
		el = D.EL[rng.randi() % 4]
	elif er < 0.80 and floor_i >= 1:
		el = "prism"
	return {id = pick, el = el, el2 = "", lv = 0}

func wname(w: Dictionary) -> String:
	return Ext.wname(w)

func offer_buffs(stay: bool) -> void:
	var pool = D.BUFFS.duplicate()
	buff_choices = []
	for i in 3:
		var k = rng.randi() % pool.size()
		buff_choices.append(pool[k])
		pool.remove_at(k)
	buff_stay = stay
	buff_sel = 0
	buff_turn = 0
	set_state("buff")

func next_floor() -> void:
	Sfx.play("portal")
	Meta.stat("floors")
	if floor_i >= LAST_FLOOR:
		end_run(true)
		return
	offer_buffs(false)

func apply_buff(id: String) -> void:
	p.buffs.append(id)
	match id:
		"vital":
			p.mhp += 2
			p.hp = min(p.mhp, p.hp + 3)
		"plating":
			p.mar += 2
			p.ar = p.mar
		"battery":
			p.men += 80
			p.en = float(p.men)
		"wind2":
			p.wind2 = true
	calc_stats()

func pick_buff(i: int) -> void:
	if local_coop():
		# same screen: each hero takes a turn and may choose differently
		bind(players[buff_turn])
		apply_buff(buff_choices[i].id)
		bind(players[me])
		if buff_turn < players.size() - 1:
			buff_turn += 1
			state_t = 0.0
			Sfx.play("pick")
			return
	else:
		# over LAN the host's choice is shared by the whole party
		for pl in players:
			bind(pl)
			apply_buff(buff_choices[i].id)
		bind(players[me])
	buff_turn = 0
	Sfx.play("pick")
	if not buff_stay:
		floor_i += 1
		new_floor()
	set_state("play")

func charge_res(mult: float = 1.0) -> void:
	p.res = minf(1.0, p.res + 0.2 * mult * st.res * (2.0 if p.sk.cat else 1.0))
	if p.res >= 1.0:
		tip("burst", "BURST READY", "PRESS R (R3 ON A PAD) TO HIT EVERYTHING ON SCREEN")

# Where an enemy should shoot. arm 1 leads the target using the player's velocity.
func aim_dir(from: Vector2, spd: float, arm: int) -> Vector2:
	var target = pcenter()
	if arm == 1:
		target += p.v * (from.distance_to(target) / maxf(spd, 1.0)) * 0.9
	return (target - from).normalized()

# ---- collision helpers -----------------------------------------------------------

func solid_at(x: float, y: float) -> bool:
	var tx = int(floor(x / TS))
	var ty = int(floor(y / TS))
	if tx < 0 or ty < 0 or tx >= dg.w or ty >= dg.h:
		return true
	return dg.grid[ty * dg.w + tx] != 1

func box_free(pos: Vector2, r: float) -> bool:
	if solid_at(pos.x - r, pos.y - r) or solid_at(pos.x + r, pos.y - r) or solid_at(pos.x - r, pos.y + r) or solid_at(pos.x + r, pos.y + r):
		return false
	if r > 7.0 and (solid_at(pos.x, pos.y - r) or solid_at(pos.x, pos.y + r) or solid_at(pos.x - r, pos.y) or solid_at(pos.x + r, pos.y)):
		return false
	return true

# Moves an actor axis by axis; returns true if a wall blocked it.
func move(a: Dictionary, d: Vector2) -> bool:
	var hit = false
	var np = a.pos + Vector2(d.x, 0)
	if box_free(np, a.r):
		a.pos = np
	else:
		hit = true
	np = a.pos + Vector2(0, d.y)
	if box_free(np, a.r):
		a.pos = np
	else:
		hit = true
	return hit

func center(e: Dictionary) -> Vector2:
	return e.pos + Vector2(0, e.r - e.h2)

func pcenter() -> Vector2:
	return p.pos + Vector2(0, -3)

func nearest_enemy(pos: Vector2, maxd: float, exclude: Array):
	var bestd = maxd
	var res = null
	for e in enemies:
		if e.dead or exclude.has(e):
			continue
		var d = center(e).distance_to(pos)
		if d < bestd:
			bestd = d
			res = e
	return res

# Delayed call; remembers which hero was acting so it runs for the same one.
func after(t: float, fn: Callable) -> void:
	timers.append([t, fn, int(p.get("idx", 0))])

# ---- play update -----------------------------------------------------------------

func update_play(dt: float) -> void:
	run_time += dt
	var due = []
	for t in timers:
		t[0] -= dt
		if t[0] <= 0.0:
			due.append(t)
	if not due.is_empty():
		timers = timers.filter(func(t): return t[0] > 0.0)
		for t in due:
			if t[2] < players.size():
				bind(players[t[2]])
			t[1].call()
			if state != "play":
				return
	var i = 0
	while i < players.size():
		var pl = players[i]
		i += 1
		bind(pl)
		if pl.down:
			# a partner standing close for a moment gets you back on your feet
			var helper = false
			for q in players:
				if not q.down and q.pos.distance_to(pl.pos) < 20.0:
					helper = true
			pl.rev = (float(pl.get("rev", 0.0)) + dt) if helper else 0.0
			if pl.rev >= 2.5:
				pl.rev = 0.0
				pl.down = false
				pl.hp = max(1, pl.mhp / 3)
				pl.inv = 2.0
				Sfx.play("pick")
				label(pl.pos + Vector2(0, -26), "REVIVED", Color("a6e84e"), true)
			continue
		cin = input_for(pl.idx)
		find_near()
		update_player(dt)
		cin = null
		if state != "play":
			return
		Ext.update_pet(self, dt)
		p.syn_t -= dt
		if p.syn_t <= 0.0:
			p.syn_t = 0.5
			More.refresh_syn(self)
	net.rin.jp.clear()
	bind(players[0])
	More.update_allies(self, dt)
	if in_lobby:
		Lobby.update(self, dt)
	else:
		update_rooms(dt)
	for e in enemies:
		if not e.dead:
			update_enemy(e, dt)
	separate()
	update_bullets(dt)
	update_zones(dt)
	if not in_lobby:
		Traps.update(self, dt)
		if state != "play":
			return
	update_pickups(dt)
	for t in teles:
		t.t += dt
	for pr in props:
		pr.flash = maxf(0.0, pr.flash - dt)
	teles = teles.filter(func(t): return t.t < t.dur)
	enemies = enemies.filter(func(e): return not e.dead)
	bullets = bullets.filter(func(b): return not b.dead)
	zones = zones.filter(func(z): return z.life > 0.0)
	pickups = pickups.filter(func(k): return not k.dead)
	props = props.filter(func(pr): return not pr.dead)
	inter = inter.filter(func(it): return not it.get("gone", false))
	bind(players[me] if me < players.size() else players[0])
	find_near()

func update_player(dt: float) -> void:
	var mv = Vector2(
		float(key(KEY_D) or arrow(KEY_RIGHT)) - float(key(KEY_A) or arrow(KEY_LEFT)),
		float(key(KEY_S) or arrow(KEY_DOWN)) - float(key(KEY_W) or arrow(KEY_UP)))
	if mv.length() > 0.0:
		mv = mv.normalized()
	if cin != null:
		mv = cin.mv
	if tin.on and cin == null:
		if tin.mv != Vector2.ZERO:
			mv = tin.mv
		var td = Touch.aim_dir(self)
		if td != Vector2.ZERO:
			p.aim = td
	var mw = mouse() + cam_tl
	var aim = mw - pcenter()
	if aim.length() > 1.0 and not (tin.on and cin == null):
		p.aim = aim.normalized()
	p.face = 1 if p.aim.x >= 0.0 else -1
	for k in ["cd", "dash_cd", "inv", "skill_cd", "skill2_cd", "shield_t", "haste_t", "rage_t", "flash", "swing", "slow", "noregen", "ar_t"]:
		p[k] = maxf(0.0, p[k] - dt)
	p.kick = maxf(0.0, p.kick - dt * 30.0)

	if jpk(KEY_SPACE) and p.dash_cd <= 0.0:
		p.dash_t = 0.17
		p.dash_cd = 0.75 * st.dashcd
		p.dash_dir = mv if mv != Vector2.ZERO else p.aim
		p.dash_hit = []
		Sfx.play("dash")
		burst(p.pos, 6, Color(0.9, 0.9, 1.0, 0.8), 40.0, 0.3)
	var riding = p.mount != null and p.mount.hp > 0
	var v = mv * 92.0 * st.spd * (0.6 if p.slow > 0.0 else 1.0) * (p.mount.spd if riding else 1.0) * (1.35 if p.haste_t > 0.0 else 1.0)
	if p.dash_t > 0.0:
		p.dash_t -= dt
		v = p.dash_dir * 310.0
		ghosts.append({pos = p.pos, flip = p.face < 0, t = 0.22, spr = p.spr})
		if riding:
			Ext.mount_dash(self)
	if p.spin > 0.0:
		p.spin -= dt
		p.spin_tick -= dt
		v *= 1.25
		if p.spin_tick <= 0.0:
			p.spin_tick = 0.1
			Ext.whirl_tick(self)
	if p.shield_t > 0.0:
		Ext.shield_tick(self)
	p.v = v
	var was: Vector2 = p.pos
	move(p, v * dt)
	if local_coop() and not in_lobby:
		# two heroes share one screen: nobody may walk off its edge
		var off = (p.pos - cam).abs()
		if (off.x > 222.0 or off.y > 118.0) and p.pos.distance_to(cam) > was.distance_to(cam):
			p.pos = was
	p.moving = mv != Vector2.ZERO
	if p.moving:
		p.walk += dt * 11.0

	if (jpk(KEY_Q) or jpk("m4") or jpk("m5")) and p.weapons[1] != null:
		p.wi = 1 - p.wi
		p.cd = maxf(p.cd, 0.12)
		Sfx.play("ui")
		label(p.pos + Vector2(0, -22), wname(p.weapons[p.wi]), D.EL_COL[p.weapons[p.wi].el])
	if firing() and p.cd <= 0.0 and p.spin <= 0.0:
		try_fire()
	if jpk("m2") or jpk(KEY_SHIFT):
		Ext.cast(self, 0, mw)
	if jpk(KEY_F):
		Ext.cast(self, 1, mw)
	if jpk(KEY_R):
		Ext.burst(self)
	if jpk(KEY_C) or jpk(KEY_G):
		More.use_active(self)
	if jpk(KEY_E) and near != null:
		interact(near)
		if state != "play":
			return
	if p.ar < p.mar and p.ar_t <= 0.0 and p.noregen <= 0.0:
		p.ar_tick += dt
		if p.ar_tick >= 0.7:
			p.ar_tick = 0.0
			p.ar += 1

func cur_el() -> String:
	var w = p.weapons[p.wi]
	var el = w.el
	if w.get("el2", "") != "":
		w.flip = not w.get("flip", false)
		if w.flip:
			el = w.el2
	if el == "prism":
		el = D.EL[rng.randi() % 4]
	return el

func try_fire() -> void:
	var wi = p.weapons[p.wi]
	var w = D.WEAPONS[wi.id]
	var cost = w.cost
	if p.en < cost:
		p.cd = 0.3
		Sfx.play("deny")
		label(p.pos + Vector2(0, -22), "NO ENERGY", Color("7adfff"))
		return
	if cost > 0.0 and rng.randf() < st.free:
		cost = 0.0
	p.en -= cost
	p.cd = w.cd * (0.6 if p.rage_t > 0.0 else 1.0) * st.rate
	p.kick = 3.0
	var lvm = Ext.wdmg(wi) * (1.4 if p.rage_t > 0.0 else 1.0)
	if lvm != 1.0:
		w = w.duplicate()
		w.dmg = w.dmg * lvm
	fire_weapon(w, cur_el(), pcenter() + p.aim * 8.0, p.aim)

func fire_weapon(w: Dictionary, el: String, origin: Vector2, dir: Vector2) -> void:
	var col = D.EL_COL[el]
	match w.type:
		"bullet":
			var n = w.get("n", 1) + st.multi
			var fanw: float = w.get("fan", 0.18)
			for i in n:
				var a = dir.angle() + rng.randf_range(-1.0, 1.0) * w.get("spread", 0.0)
				if n > 1:
					a += (i - (n - 1) / 2.0) * fanw / (n - 1)
				add_bullet(origin, Vector2.from_angle(a) * w.speed * rng.randf_range(0.95, 1.05), {
					dmg = w.dmg, el = el, r = float(w.get("r", 2)), life = w.get("life", 1.4),
					pierce = w.get("pierce", 0) + st.pierce, bounce = w.get("bounce", 0) + st.bounce,
					aoe = w.get("aoe", 0.0), kind = w.get("kind", "orb")})
			if w.get("kind", "") != "flame":
				burst(origin, 3, col, 50.0, 0.15)
				Fx.muzzle(self, origin, dir, el)
				flash(origin, 26.0, col, 0.1)
			Sfx.play("shoot" if el == "" else "shoot_" + el, 1.0, -4.0 if w.cd < 0.1 else 0.0)
		"melee":
			p.swing = 0.18
			var pc = pcenter()
			var rg = w.range
			for e in enemies:
				if e.dead:
					continue
				var d = center(e) - pc
				if d.length() < rg + e.hr and (d.length() < 10.0 or absf(angle_difference(dir.angle(), d.angle())) < w.arc / 2.0):
					hurt_enemy(e, w.dmg, el, d.normalized() * 140.0)
			for b in bullets:
				if b.team == 1 and not b.lob:
					var d = b.pos - pc
					if d.length() < rg + 6.0 and absf(angle_difference(dir.angle(), d.angle())) < w.arc / 2.0:
						if p.syn.has("duelist"):
							b.team = 0
							b.vel = -b.vel * 1.5
							b.dmg = 5.0 + floor_i * 2.0
							b.life = 1.5
							b.hit = []
						else:
							b.dead = true
						burst(b.pos, 4, Color.WHITE, 60.0, 0.2)
			for pr in props:
				var d = pr.pos - pc
				if d.length() < rg + 6.0 and absf(angle_difference(dir.angle(), d.angle())) < w.arc / 2.0:
					hurt_prop(pr, w.dmg)
			slashes.append({pos = pc, ang = dir.angle(), arc = w.arc, r = rg, t = 0.0, col = col})
			Sfx.play("slash")
		"chain":
			var target = null
			var bd = w.range
			for e in enemies:
				if e.dead:
					continue
				var d = center(e) - origin
				if d.length() < bd and absf(angle_difference(dir.angle(), d.angle())) < 0.55:
					bd = d.length()
					target = e
			Sfx.play("shoot_bolt")
			if target == null:
				bolt(origin, origin + dir * 46.0, col)
				return
			var hitl = [target]
			bolt(origin, center(target), col)
			var cur = target
			for i in w.n:
				var o = nearest_enemy(center(cur), 72.0, hitl)
				if o == null:
					break
				bolt(center(cur), center(o), col)
				hitl.append(o)
				cur = o
			for e in hitl:
				hurt_enemy(e, w.dmg, el)
		"beam":
			var end = origin
			for i in int(w.range / 4.0):
				var np = end + dir * 4.0
				if solid_at(np.x, np.y):
					break
				end = np
			p.beam_n += 1
			var bel = el if p.beam_n % 4 == 0 else ""
			for e in enemies:
				if e.dead:
					continue
				var c = center(e)
				if Geometry2D.get_closest_point_to_segment(c, origin, end).distance_to(c) < e.hr + 2.0:
					hurt_enemy(e, w.dmg, bel, Vector2.ZERO, false, col)
			for pr in props:
				if Geometry2D.get_closest_point_to_segment(pr.pos, origin, end).distance_to(pr.pos) < 7.0:
					hurt_prop(pr, w.dmg)
			bolts.append({a = origin, b = end, col = col, t = 0.07, straight = true})
			flash(end, 22.0, col, 0.08)
			if p.beam_n % 3 == 0:
				burst(end, 1, col, 50.0, 0.2)
				Sfx.play("shoot_ice" if el == "" else "shoot_" + el, 1.4, -8.0)
		"lob":
			var to = mouse() + cam_tl
			var d = to - p.pos
			if d.length() > w.range:
				to = p.pos + d.normalized() * w.range
			bullets.append({lob = true, own = p.idx, pos = origin, from = origin, to = to, t = 0.0, dur = 0.5, z = 0.0, team = 0,
				dmg = w.dmg, el = el, aoe = w.aoe, puddle = w.get("puddle", false), dead = false, r = 3.0, kind = "orb", age = 0.0, vel = Vector2.ZERO})
			Sfx.play("shoot_tox" if el == "" else "shoot_" + el, 0.8)

# ---- interaction -----------------------------------------------------------------

func interact(it: Dictionary) -> void:
	if p.get("remote", false) and it.kind in ["talk", "npc", "egg", "plot"]:
		return
	match it.kind:
		"gate", "hero", "crystal", "npc", "egg", "plot":
			Lobby.interact(self, it)
		"smith", "alch", "fuse":
			Ext.station(self, it)
		"talk":
			start_talk(it.who)
		"relic":
			it.gone = true
			More.take_relic(self, it.id)
		"active":
			More.take_active(self, it)
		"lchest":
			if p.keys <= 0:
				Sfx.play("deny")
				label(p.pos + Vector2(0, -22), "LOCKED. FIND A KEY.", Color("ff6a6a"))
				return
			p.keys -= 1
			it.gone = true
			Sfx.play("chest")
			burst(it.pos + Vector2(0, -6), 16, Color("ffd24a"), 90.0, 0.5)
			inter.append({kind = "relic", id = More.random_relic(self), pos = it.pos})
		"shrine":
			if p.mhp <= 2:
				Sfx.play("deny")
				label(p.pos + Vector2(0, -22), "TOO FRAIL TO OFFER BLOOD", Color("ff6a6a"))
				return
			it.used = true
			p.mhp -= 1
			p.hp = min(p.hp, p.mhp)
			Sfx.play("react", 0.6)
			burst(it.pos + Vector2(0, -8), 18, Color("d43b42"), 80.0, 0.6)
			offer_buffs(true)
		"chest":
			if it.open:
				return
			it.open = true
			Meta.stat("chests")
			Sfx.play("chest")
			burst(it.pos + Vector2(0, -6), 14, Color("ffd24a"), 90.0, 0.5)
			flash(it.pos, 60.0, Color("ffd24a"), 0.4)
			if it.loot == "nook":
				Lobby.open_nook_chest(self)
			elif it.loot == "weapon":
				inter.append({kind = "weapon", w = random_weapon(), pos = it.pos + Vector2(0, 18)})
			else:
				drop("coin", it.pos, 5 + rng.randi() % 4 + floor_i)
				if rng.randf() < 0.3:
					drop("key", it.pos, 1)
				drop("orb", it.pos, 4 + rng.randi() % 3)
		"weapon":
			if p.weapons[1] == null:
				p.weapons[1] = it.w
				p.wi = 1
				tip("swap", "TWO WEAPONS", "Q SWAPS. TWO ELEMENTS ON ONE FOE REACT.")
				Meta.record("weapons", it.w.id)
				it.gone = true
			else:
				var old = p.weapons[p.wi]
				p.weapons[p.wi] = it.w
				Meta.record("weapons", it.w.id)
				it.w = old
			Sfx.play("pick")
			label(p.pos + Vector2(0, -22), wname(p.weapons[p.wi]), D.EL_COL[p.weapons[p.wi].el])
		"shop":
			if p.gold < shop_price(it):
				Sfx.play("deny")
				label(p.pos + Vector2(0, -22), "NOT ENOUGH GOLD", Color("ff6a6a"))
				return
			p.gold -= shop_price(it)
			Sfx.play("pick")
			match it.item.type:
				"weapon":
					it.kind = "weapon"
					it.w = it.item.w
					interact(it)
				"relic":
					More.take_relic(self, it.item.id)
					it.gone = true
				"potion":
					p.hp = min(p.mhp, p.hp + 2)
					label(p.pos + Vector2(0, -22), "+2 HEALTH", Color("ff6a7a"))
					it.gone = true
				"cell":
					p.en = float(p.men)
					label(p.pos + Vector2(0, -22), "ENERGY FULL", Color("7adfff"))
					it.gone = true
				"tome":
					apply_buff(it.item.buff.id)
					label(p.pos + Vector2(0, -22), it.item.buff.name, Color("e58cff"))
					it.gone = true
		"portal":
			next_floor()

func drop(kind: String, pos: Vector2, n: int) -> void:
	for i in n:
		pickups.append({kind = kind, pos = pos, vel = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30.0, 90.0), t = 0.0, dead = false})

func update_pickups(dt: float) -> void:
	for k in pickups:
		bind(target_for(k.pos))
		var pc = pcenter()
		k.t += dt
		var np = k.pos + k.vel * dt
		if not solid_at(np.x, np.y):
			k.pos = np
		k.vel = k.vel.lerp(Vector2.ZERO, minf(1.0, dt * 6.0))
		var d = pc - k.pos
		var dist = d.length()
		if k.kind == "heart" and p.hp >= p.mhp:
			continue
		if k.t > 0.35 and dist < (54.0 + 60.0 * st.magnet):
			k.pos += d / maxf(dist, 0.1) * 210.0 * dt
		if dist < 8.0:
			k.dead = true
			match k.kind:
				"key":
					p.keys += 1
					Sfx.play("pick")
					label(p.pos + Vector2(0, -22), "KEY", Color("ffd24a"))
				"coin":
					p.gold += 1
					Meta.stat("gold")
					if p.relics.has("coin") and rng.randf() < 0.5:
						p.gold += 1
					if p.relics.has("greed") and rng.randf() < 0.5:
						p.gold += 1
					if st.magnet > 0 and rng.randf() < 0.3:
						p.gold += 1
					Sfx.play("coin")
				"orb":
					p.en = minf(p.men, p.en + (12.0 if p.relics.has("cell") else 6.0))
					Sfx.play("orb")
				"heart":
					p.hp = min(p.mhp, p.hp + 1)
					Sfx.play("pick")
					label(p.pos + Vector2(0, -22), "+1", Color("ff6a7a"))

# ---- rooms & waves ---------------------------------------------------------------

func update_rooms(dt: float) -> void:
	var cur = null
	var trig = null
	for pl in players:
		if pl.down:
			continue
		var t = Vector2i((pl.pos / TS).floor())
		for r in dg.rooms:
			if r.rect.has_point(t):
				r.seen = true
				if pl.idx == me:
					room = r
				if lock == null and cur == null and not r.cleared and r.rect.grow(-1).has_point(t):
					cur = r
					trig = pl
				break
	if cur != null:
		lock = cur
		for g in cur.gates:
			dg.grid[g.y * dg.w + g.x] = 2
		Sfx.play("door")
		shake_add(3.0)
		wave_wait = 0.0
		for pl in players:
			pl.room_hits = 0
			pl.skin_ready = true
			# the gates are shut: pull anyone left outside in next to whoever stepped in
			if not cur.rect.grow(-1).has_point(Vector2i((pl.pos / TS).floor())):
				pl.pos = trig.pos
		bind(trig)
		if cur.trial:
			banner = {text = "FLAWLESS TRIAL", sub = "TAKE NO DAMAGE FOR A RELIC", t = 2.4}
		if cur.mod == "surge":
			cur.surge_el = D.EL[rng.randi() % 4]
		if cur.mod != "":
			banner = {text = {"dark": "DARKNESS", "haste": "FRENZY", "surge": D.EL_NAME[cur.get("surge_el", "fire")] + " SURGE"}[cur.mod],
				sub = {"dark": "YOUR LIGHT FALTERS", "haste": "FOES MOVE FASTER", "surge": "FOES ARE INFUSED"}[cur.mod], t = 2.2}
		spawn_wave(cur)
	if lock != null and pending == 0 and enemies.is_empty():
		wave_wait += dt
		if wave_wait > 0.45:
			wave_wait = 0.0
			if lock.wave < lock.waves:
				spawn_wave(lock)
			else:
				clear_room(lock)

func random_room_pos(r: Dictionary, mind: float) -> Vector2:
	for i in 50:
		var c = r.rect.position + Vector2i(rng.randi() % r.rect.size.x, rng.randi() % r.rect.size.y)
		if dg.grid[c.y * dg.w + c.x] != 1:
			continue
		var pos = Vector2(c) * TS + Vector2(8, 8)
		if pos.distance_to(p.pos) > mind:
			return pos
	return rc(r)

func spawn_tele(id: String, pos: Vector2, delay: float = 0.8, elite: bool = false) -> void:
	pending += 1
	teles.append({kind = "spawn", pos = pos, t = 0.0, dur = delay, r = 7.0})
	after(delay, func():
		pending -= 1
		var e = spawn_enemy(id, pos)
		if lock != null and lock.mod == "surge":
			e.el = lock.surge_el
		if elite:
			e.elite = true
			e.mhp *= 3.0
			e.hp = e.mhp
			e.sc *= 1.4
			e.h2 *= 1.4
			e.hr *= 1.4
			e.smart = true
			if e.el == "":
				e.el = D.EL[rng.randi() % 4]
			label(pos + Vector2(0, -26), "ELITE", Color("ffd24a"), true)
		burst(center(e), 10, Color("ff5a6a"), 70.0, 0.35))

func spawn_wave(r: Dictionary) -> void:
	r.wave += 1
	if r.type == "boss":
		var bid: String = dg.boss_id
		var pos = rc(r) + Vector2(0, -34)
		pending += 1
		teles.append({kind = "circle", pos = pos, t = 0.0, dur = 1.2, r = 26.0})
		after(1.2, func():
			pending -= 1
			boss = spawn_enemy(bid, pos)
			boss.t = 1.2
			banner = {text = D.ENEMIES[bid].name, sub = "BOSS", t = 2.6}
			Sfx.play("roar")
			Sfx.play_music(3)
			shake_add(8.0)
			burst(pos, 30, Color("ff5a6a"), 120.0, 0.6))
		return
	var budget = (3.0 + floor_i * 1.3 + r.wave * 1.2 + rng.randf() * 2.0) * (0.85 + 0.5 * Meta.cunning())
	var roster = D.BIOMES[floor_i / 2].roster
	var n = 0
	for attempt in 60:
		if budget < 1.0 or n >= 14:
			break
		var id = roster[rng.randi() % roster.size()]
		var c = D.ENEMIES[id].cost
		if c > budget:
			continue
		budget -= c
		n += 1
		spawn_tele(id, random_room_pos(r, 60.0))
	if (r.elite or run_heat >= 4) and r.wave == r.waves:
		spawn_tele(roster[rng.randi() % roster.size()], random_room_pos(r, 70.0), 1.1, true)
	Sfx.play("warn")

func spawn_enemy(id: String, pos: Vector2) -> Dictionary:
	var d = D.ENEMIES[id]
	uid += 1
	var img: Image = Art.I["e_" + id]
	var sc: float = d.get("sc", 1.0)
	var is_boss = d.has("boss")
	var hp = float(d.hp) * (1.0 if is_boss else 1.0 + 0.22 * floor_i) * (1.25 if (run_heat >= 1 and not in_lobby) else 1.0)
	var e = {
		id = id, d = d, uid = uid, pos = pos, kb = Vector2.ZERO, hp = hp, mhp = hp, r = float(d.r),
		h2 = img.get_height() * sc / 2.0, hr = maxf(d.r, img.get_height() * sc * 0.4), el = d.get("el", ""),
		st = {}, chill = 0, tox_n = 0, frz = 0.0, stun = 0.0, vuln = 0.0, react_cd = 0.0, arc_cd = 0.0, flash = 0.0,
		tick = 0.5, t = rng.randf_range(0.6, 1.6), state = "", wind = 0.0, face = 1, dead = false,
		anim = rng.randf() * 10.0, dir = Vector2.RIGHT, av = Vector2.ZERO, av_t = 0.0, ang = rng.randf() * TAU, atk = rng.randi() % 4, is_boss = is_boss,
		col = img.get_pixel(img.get_width() / 2, img.get_height() / 2),
		sc = sc, z = 0.0, elite = false, smart = rng.randf() < Meta.cunning(), dodge_t = 0.0, dodge_dir = Vector2.ZERO, weak_t = 0.0,
		hop_from = pos, hop_to = pos, cast_t = 0.0,
	}
	enemies.append(e)
	return e

func clear_room(r: Dictionary) -> void:
	r.cleared = true
	lock = null
	var hits = 0
	var up = players[0]
	for pl in players:
		if not pl.down:
			up = pl
	for pl in players:
		hits += pl.room_hits
		if pl.active != null:
			pl.active.n = min(D.ACTIVES[pl.active.id].max, pl.active.n + 1)
		if pl.down:
			pl.down = false
			pl.hp = max(1, pl.mhp / 2)
			pl.inv = 2.0
			pl.pos = up.pos
			label(pl.pos + Vector2(0, -26), "REVIVED", Color("a6e84e"), true)
	bind(up)
	Meta.add_cunning(0.02 if hits == 0 else (-0.015 if hits >= 3 else 0.0))
	if r.elite or run_heat >= 4:
		drop("coin", rc(r), 10)
		if rng.randf() < 0.6:
			drop("key", rc(r), 1)
		else:
			inter.append({kind = "active", id = More.random_active(self), pos = random_room_pos(r, 30.0)})
	if r.trial and hits == 0:
		inter.append({kind = "relic", id = More.random_relic(self), pos = random_room_pos(r, 30.0)})
		label(p.pos + Vector2(0, -30), "FLAWLESS!", Color("ffd24a"), true)
	for g in r.gates:
		dg.grid[g.y * dg.w + g.x] = 1
	Sfx.play("door")
	var c = rc(r)
	if r.type == "boss":
		inter.append({kind = "portal", pos = c})
		inter.append({kind = "relic", id = More.random_relic(self), pos = c + Vector2(0, 34)})
		inter.append({kind = "chest", pos = c + Vector2(-40, 10), loot = "weapon", open = false})
		inter.append({kind = "chest", pos = c + Vector2(40, 10), loot = "reward", open = false})
		drop("heart", c, 1)
		Sfx.play_music(floor_i / 2)
	else:
		var cp = c
		if solid_at(cp.x, cp.y):
			cp = random_room_pos(r, 0.0)
		inter.append({kind = "chest", pos = cp, loot = "reward", open = false})
		banner = {text = "ROOM CLEAR", sub = "", t = 1.4}
	for b in bullets:
		if b.team == 1:
			b.dead = true

# ---- enemies ---------------------------------------------------------------------

func ebullet(pos: Vector2, vel: Vector2, el: String, arm: int = -1) -> void:
	if bullets.size() < 600:
		add_bullet(pos, vel * (1.2 if run_heat >= 2 else 1.0), {team = 1, el = el, r = 3.0, life = 6.0, arm = arm})

func ring(pos: Vector2, n: int, spd: float, el: String, off: float = 0.0) -> void:
	for i in n:
		ebullet(pos, Vector2.from_angle(off + i * TAU / n) * spd, el)

func fan(pos: Vector2, dir: Vector2, n: int, spread: float, spd: float, el: String) -> void:
	for i in n:
		ebullet(pos, Vector2.from_angle(dir.angle() + (i - (n - 1) / 2.0) * spread / maxf(1.0, n - 1)) * spd, el)

func update_enemy(e: Dictionary, dt: float) -> void:
	e.flash = maxf(0.0, e.flash - dt)
	e.anim += dt
	e.react_cd -= dt
	e.arc_cd -= dt
	e.vuln -= dt
	for k in e.st.keys():
		e.st[k] -= dt
		if e.st[k] <= 0.0:
			e.st.erase(k)
			if k == "tox":
				e.tox_n = 0
			if k == "ice":
				e.chill = 0
	e.tick -= dt
	if e.tick <= 0.0:
		e.tick = 0.5
		if e.st.has("fire"):
			hurt_enemy(e, 2.0 + floor_i * 0.6, "", Vector2.ZERO, true, D.EL_COL["fire"])
			burst(center(e), 2, D.EL_COL["fire"], 30.0, 0.4, -60.0)
		if e.st.has("tox") and not e.dead:
			hurt_enemy(e, (0.8 + floor_i * 0.25) * e.tox_n, "", Vector2.ZERO, true, D.EL_COL["tox"])
	if e.dead:
		return
	if e.kb.length() > 2.0:
		move(e, e.kb * dt)
		e.kb = e.kb.lerp(Vector2.ZERO, minf(1.0, dt * 9.0))
	if e.frz > 0.0:
		e.frz -= dt
		return
	if e.stun > 0.0:
		e.stun -= dt
		return
	var d = e.d
	bind(target_for(e.pos))
	var to = p.pos - e.pos
	var dist = maxf(to.length(), 0.01)
	var dir = to / dist
	if absf(dir.x) > 0.15 and e.state != "dash":
		e.face = 1 if dir.x > 0.0 else -1
	var spd = d.spd * (0.55 if e.st.has("ice") else 1.0) * (1.25 if (lock != null and lock.mod == "haste") else 1.0)
	e.t -= dt
	e.weak_t -= dt
	e.cast_t = maxf(0.0, e.cast_t - dt)
	# cunning foes sidestep shots that are about to hit them
	if e.dodge_t > 0.0:
		e.dodge_t -= dt
		move(e, e.dodge_dir * maxf(spd, 40.0) * 2.4 * dt)
	elif e.smart and not e.is_boss and (d.ai == "shoot" or d.ai == "spread") and Engine.get_process_frames() % 4 == e.uid % 4:
		var ec = center(e)
		for b in bullets:
			if b.team != 0 or b.lob:
				continue
			var tb = ec - b.pos
			if tb.length() < 52.0 and b.vel.normalized().dot(tb.normalized()) > 0.93:
				var side = Vector2(-b.vel.y, b.vel.x).normalized()
				e.dodge_dir = side if side.dot(tb) > 0.0 else -side
				e.dodge_t = 0.22
				break
	if not e.is_boss and Foes.special(self, e, dt, dir, dist):
		return
	match d.ai:
		"chase":
			steer(e, dir + Vector2(sin(e.anim * 3.0 + e.uid), cos(e.anim * 2.3 + e.uid)) * 0.35, spd, dt)
		"bat":
			var perp = Vector2(-dir.y, dir.x)
			steer(e, (dir + perp * sin(e.anim * 5.0 + e.uid) * 0.9).normalized(), spd, dt)
		"shoot":
			if e.wind > 0.0:
				e.wind -= dt
				if e.wind <= 0.0:
					var arm = Meta.lead_pick(rng)
					for i in d.get("burst", 1):
						after(i * 0.13, func():
							if not e.dead and e.frz <= 0.0:
								ebullet(center(e), aim_dir(center(e), d.bspd, arm) * d.bspd, e.el, arm)
								Sfx.play("shoot", 0.7, -8.0))
			else:
				var mvd = Vector2(-dir.y, dir.x) * (0.6 if e.uid % 2 == 0 else -0.6)
				if dist > 115.0:
					mvd = dir
				elif dist < 60.0:
					mvd = -dir
				move(e, mvd * spd * dt)
				if e.t <= 0.0 and dist < 200.0:
					e.t = d.rate * rng.randf_range(0.85, 1.2)
					e.wind = 0.4
		"spread":
			if e.wind > 0.0:
				e.wind -= dt
				if e.wind <= 0.0:
					var c = center(e)
					if d.get("aimed", false):
						fan(c, dir, d.n, 0.6, d.bspd, e.el)
					elif d.get("spiral", false):
						for i in d.n:
							after(i * 0.07, func():
								if not e.dead and e.frz <= 0.0:
									ebullet(center(e), Vector2.from_angle(e.ang + i * 0.55) * d.bspd, e.el)
									ebullet(center(e), Vector2.from_angle(e.ang + i * 0.55 + PI) * d.bspd, e.el))
					else:
						ring(c, d.n, d.bspd, e.el, rng.randf() * TAU)
					Sfx.play("shoot_tox", 0.8, -6.0)
			else:
				move(e, Vector2.from_angle(e.anim * 0.7 + e.uid) * spd * dt)
				if e.t <= 0.0 and dist < 220.0:
					e.t = d.rate * rng.randf_range(0.85, 1.2)
					e.wind = 0.5
		"charge":
			match e.state:
				"":
					steer(e, dir, spd, dt)
					if (e.t <= 0.0 and dist < 130.0) or (e.smart and e.t < 0.6 and p.dash_cd > 0.4 and dist < 150.0):
						e.state = "wind"
						e.t = 0.55
						e.dir = dir
						teles.append({kind = "line", pos = e.pos, to = e.pos + dir * 120.0, t = 0.0, dur = 0.55, r = 0.0})
				"wind":
					if e.t <= 0.0:
						e.state = "dash"
						e.t = 0.5
				"dash":
					var hit = move(e, e.dir * 250.0 * dt)
					if hit or e.t <= 0.0:
						e.state = "rest"
						e.t = 0.7
						if hit:
							burst(e.pos, 6, Color("a8a7b8"), 70.0, 0.3)
							shake_add(2.0)
				"rest":
					if e.t <= 0.0:
						e.state = ""
						e.t = rng.randf_range(0.8, 1.6)
		"bomb":
			if e.state == "":
				steer(e, dir, spd, dt)
				if dist < 22.0:
					e.state = "fuse"
					e.t = 0.55
					Sfx.play("warn")
			elif e.t <= 0.0:
				explode(e.pos, 30.0, 2.0, e.el, 1)
				kill(e)
				return
		"turret":
			if e.t <= 0.0:
				e.t = 0.6
				e.ang += 0.4
				for i in 4:
					ebullet(center(e), Vector2.from_angle(e.ang + i * PI / 2.0) * 85.0, e.el)
		"blink":
			steer(e, dir, spd, dt)
			if e.t <= 0.0:
				e.t = 2.6
				var cand = p.pos + Vector2.from_angle(rng.randf() * TAU) * 38.0
				if box_free(cand, e.r):
					burst(center(e), 8, e.col, 60.0, 0.3)
					e.pos = cand
					e.stun = 0.4
					burst(center(e), 8, e.col, 60.0, 0.3)
		"boss":
			boss_ai(e, dt, dir)
	if d.get("touch", 0) > 0 and dist < e.r + p.r + 1.0:
		hurt_player(d.touch, e.el)

# Walk toward dir; when a wall stops us, slide along it for a moment to get around pillars.
func steer(e: Dictionary, dir: Vector2, spd: float, dt: float) -> void:
	if e.av_t > 0.0:
		e.av_t -= dt
		if move(e, e.av * spd * dt):
			e.av = -e.av
		return
	var before: Vector2 = e.pos
	move(e, dir * spd * dt)
	if e.pos.distance_to(before) < spd * dt * 0.35 and spd > 0.0:
		var sgn = 1.0 if rng.randf() < 0.5 else -1.0
		e.av = Vector2(0, sgn) if absf(dir.x) > absf(dir.y) else Vector2(sgn, 0)
		e.av_t = rng.randf_range(0.5, 1.1)

func boss_ai(e: Dictionary, dt: float, dir: Vector2) -> void:
	var rage = e.hp < e.mhp * 0.5
	if rage and not e.get("raged", false):
		e.raged = true
		Fx.enrage(self, e)
	match e.state:
		"hop":
			var k = clampf(1.0 - e.t / 0.8, 0.0, 1.0)
			e.pos = e.hop_from.lerp(e.hop_to, k)
			e.z = sin(k * PI) * 44.0
			if e.t <= 0.0:
				e.z = 0.0
				e.state = "busy"
				e.t = 0.9
				explode(e.pos, 42.0, 2.0, e.el, 1)
				ring(center(e), 24 if rage else 16, 90.0, e.el, rng.randf() * TAU)
			return
		"aim":
			if e.t <= 0.0:
				e.state = "dash"
				e.t = 0.6
			return
		"dash":
			var hit = move(e, e.dir * 330.0 * dt)
			if int(e.anim * 30.0) % 2 == 0:
				burst(e.pos + Vector2(0, e.r), 1, Color("a8a7b8"), 30.0, 0.3)
			if hit or e.t <= 0.0:
				e.state = "busy"
				e.t = 0.8
				if hit:
					shake_add(6.0)
					Sfx.play("boom")
					ring(center(e), 12, 95.0, "", rng.randf() * TAU)
			return
		"busy":
			if e.t <= 0.0:
				e.state = ""
				e.t = (0.8 if rage else 1.4) * (1.15 - 0.4 * Meta.cunning())
			return
	move(e, dir * e.d.spd * (1.4 if rage else 1.0) * dt)
	if e.t > 0.0:
		return
	# pick the next attack, favouring the ones that have hurt this player before
	e.atk = Meta.boss_pick(rng, e.id, D.BOSS_ATKS[e.d.boss], e.atk)
	e.cast_t = 0.4
	rings.append({pos = center(e), r = 34.0, t = 0.0, col = D.EL_COL[e.el] if e.el != "" else Color("ff5a6a")})
	e.state = "busy"
	match e.d.boss:
		0: boss_golem(e, rage, dir)
		1: boss_tyrant(e, rage)
		2: boss_lich(e, rage)
		3, 4, 5: Ext.boss(self, e, rage, dir)
		_: Foes.boss(self, e, rage, dir)

func tele_circle(pos: Vector2, r: float, dur: float) -> void:
	teles.append({kind = "circle", pos = pos, t = 0.0, dur = dur, r = r})

func boss_golem(e: Dictionary, rage: bool, dir: Vector2) -> void:
	match e.atk % 3:
		0:
			tele_circle(e.pos, 62.0, 0.8)
			e.t = 1.5
			after(0.8, func():
				if e.dead:
					return
				explode(e.pos, 62.0, 2.0, "", 1)
				ring(center(e), 22 if rage else 14, 95.0, "", rng.randf() * TAU))
		1:
			var n = 8 if rage else 5
			e.t = n * 0.3 + 0.9
			for i in n:
				after(i * 0.3, func():
					if e.dead:
						return
					var tp = p.pos + Vector2(rng.randf_range(-24, 24), rng.randf_range(-24, 24))
					tele_circle(tp, 20.0, 0.7)
					after(0.7, func(): explode(tp, 20.0, 2.0, "", 1)))
		2:
			e.dir = dir
			e.face = 1 if dir.x > 0.0 else -1
			teles.append({kind = "line", pos = e.pos, to = e.pos + dir * 220.0, t = 0.0, dur = 0.7, r = 0.0})
			e.state = "aim"
			e.t = 0.7
			Sfx.play("roar", 1.3, -4.0)

func boss_tyrant(e: Dictionary, rage: bool) -> void:
	match e.atk % 4:
		0:
			var n = 40
			var arms = 3 if rage else 2
			var base = rng.randf() * TAU
			e.t = n * 0.07 + 0.6
			for i in n:
				after(i * 0.07, func():
					if e.dead:
						return
					for a in arms:
						ebullet(center(e), Vector2.from_angle(base + i * 0.33 + a * TAU / arms) * 85.0, "fire"))
		1:
			e.t = 2.2
			for k in (4 if rage else 3):
				after(k * 0.45, func():
					if e.dead:
						return
					fan(center(e), (pcenter() - center(e)).normalized(), 9, 1.3, 120.0, "fire")
					Sfx.play("shoot_fire"))
		2:
			var n = 9 if rage else 6
			e.t = n * 0.25 + 1.0
			for i in n:
				after(i * 0.25, func():
					if e.dead:
						return
					var tp = p.pos + Vector2(rng.randf_range(-44, 44), rng.randf_range(-44, 44))
					tele_circle(tp, 22.0, 0.8)
					after(0.8, func():
						explode(tp, 22.0, 2.0, "fire", 1)
						zones.append({pos = tp, r = 18.0, el = "fire", life = 2.5, team = 1, tick = 0.4})))
		3:
			e.t = 1.0
			if enemies.size() < 6 and lock != null:
				for i in (3 if rage else 2):
					spawn_tele("imp", random_room_pos(lock, 50.0))
				Sfx.play("roar", 1.4, -4.0)

func boss_lich(e: Dictionary, rage: bool) -> void:
	match e.atk % 4:
		0:
			e.t = 1.3
			burst(center(e), 16, Color("9352cb"), 90.0, 0.4)
			if lock != null:
				e.pos = random_room_pos(lock, 70.0)
			burst(center(e), 16, Color("7adfff"), 90.0, 0.4)
			ring(center(e), 18, 80.0, "ice", rng.randf() * TAU)
			Sfx.play("freeze")
			if rage:
				after(0.4, func():
					if not e.dead:
						ring(center(e), 18, 100.0, "ice", rng.randf() * TAU))
		1:
			var n = 10 if rage else 7
			e.t = n * 0.28 + 0.8
			for i in n:
				after(i * 0.28, func():
					if e.dead:
						return
					var tp = p.pos
					tele_circle(tp, 16.0, 0.55)
					after(0.55, func():
						bolt(tp + Vector2(rng.randf_range(-20, 20), -150), tp, D.EL_COL["bolt"])
						explode(tp, 16.0, 2.0, "bolt", 1)))
		2:
			var n = 34
			var arms = 3 if rage else 2
			var base = rng.randf() * TAU
			e.t = n * 0.08 + 0.6
			for i in n:
				after(i * 0.08, func():
					if e.dead:
						return
					for a in arms:
						ebullet(center(e), Vector2.from_angle(base - i * 0.3 + a * TAU / arms) * 70.0, "tox"))
		3:
			var n = 8 if rage else 5
			e.t = n * 0.22 + 0.8
			for i in n:
				after(i * 0.22, func():
					if e.dead:
						return
					ebullet(center(e), (pcenter() - center(e)).normalized() * 200.0, "ice")
					Sfx.play("shoot_ice"))

func separate() -> void:
	var n = enemies.size()
	for i in n:
		var a = enemies[i]
		if a.dead or a.is_boss:
			continue
		for j in range(i + 1, n):
			var b = enemies[j]
			if b.dead or b.is_boss:
				continue
			var d = b.pos - a.pos
			var l = d.length()
			var want = a.r + b.r
			if l < want and l > 0.01:
				var push = d / l * (want - l) * 0.5
				move(a, -push)
				move(b, push)
	for pr in props:
		for a in enemies + players:
			if a.get("dead", false):
				continue
			var d = a.pos - pr.pos
			var l = d.length()
			if l < a.r + 6.0 and l > 0.01:
				move(a, d / l * (a.r + 6.0 - l))

# ---- damage, elements, reactions -------------------------------------------------

func hurt_enemy(e: Dictionary, dmg: float, el: String = "", kb: Vector2 = Vector2.ZERO, dot: bool = false, col = null) -> void:
	if e.dead:
		return
	var mult = 1.0 if dot else st.dmg
	var crit = false
	var resist = el != "" and e.el == el
	if resist:
		mult *= 0.5
	if el != "" and e.el != "" and D.WEAK[e.el] == el:
		mult *= 1.5
		if e.weak_t <= 0.0:
			e.weak_t = 1.2
			label(center(e) + Vector2(0, -e.h2 - 12.0), "WEAK", Color("ffd24a"))
	if e.vuln > 0.0:
		mult *= 1.5
	if not dot and rng.randf() < st.crit:
		mult *= 2.0
		crit = true
	var amt = dmg * mult
	e.hp -= amt
	e.flash = 0.1
	if not e.is_boss:
		e.kb += kb
	var c: Color = col if col != null else D.EL_COL[el]
	num(center(e) + Vector2(rng.randf_range(-5, 5), -e.h2 - 4.0), str(max(1, int(round(amt)))) + ("!" if crit else ""), c, crit)
	if not dot:
		Sfx.play("hit", 1.0, -3.0)
		burst(center(e), 3, c, 60.0, 0.25)
		Fx.hit(self, center(e), el)
	if el != "" and not resist and e.hp > 0.0:
		apply_el(e, el, amt)
	if not dot and e.st.has("bolt") and e.arc_cd <= 0.0:
		e.arc_cd = 0.35
		var o = nearest_enemy(center(e), 64.0, [e])
		if o != null:
			bolt(center(e), center(o), D.EL_COL["bolt"])
			hurt_enemy(o, (2.0 + floor_i) * (3.0 if p.syn.has("stormfront") else 1.0), "", Vector2.ZERO, true, D.EL_COL["bolt"])
	if e.hp <= 0.0:
		kill(e)

func apply_el(e: Dictionary, el: String, dmg: float) -> void:
	var other = ""
	for k in e.st.keys():
		if k != el:
			other = k
			break
	if other != "" and e.react_cd <= 0.0:
		e.st.erase(other)
		e.st.erase(el)
		e.chill = 0
		e.tox_n = 0
		e.react_cd = 0.6
		var pair = [el, other]
		pair.sort()
		react(e, pair[0] + "+" + pair[1])
		return
	match el:
		"fire":
			e.st["fire"] = 4.0 * st.dur
		"ice":
			e.st["ice"] = 4.0 * st.dur
			e.chill += 1
			if e.chill >= (7 if e.is_boss else 3):
				e.chill = 0
				e.frz = (0.8 if e.is_boss else 1.6 * st.dur) * (1.6 if p.syn.has("permafrost") else 1.0)
				Sfx.play("freeze")
				burst(center(e), 10, D.EL_COL["ice"], 60.0, 0.4)
				label(center(e) + Vector2(0, -e.h2 - 12.0), "FROZEN", D.EL_COL["ice"])
		"bolt":
			e.st["bolt"] = 4.0 * st.dur
		"tox":
			e.st["tox"] = 5.0 * st.dur
			e.tox_n = min(8 if p.syn.has("plaguedoc") else 5, e.tox_n + 1)

func react(e: Dictionary, key: String) -> void:
	var info = D.REACT[key]
	var col: Color = info[1]
	var base = (9.0 + floor_i * 3.0) * st.react
	var c = center(e)
	label(c + Vector2(0, -e.h2 - 14.0), info[0], col, true)
	Sfx.play("react")
	charge_res()
	Meta.record("reactions", key)
	tip("react", "REACTION: " + info[0], "REACTIONS FILL THE BURST BAR")
	Fx.react(self, c, key)
	Meta.stat("reacts")
	hitstop = maxf(hitstop, 0.04)
	shake_add(3.0)
	rings.append({pos = c, r = 36.0, t = 0.0, col = col})
	flash(c, 70.0, col, 0.3)
	match key:
		"fire+ice":
			burst(c, 18, Color("eefaff"), 90.0, 0.6, -80.0)
			hurt_enemy(e, base * 2.4, "", Vector2.ZERO, true, col)
		"fire+tox":
			explode(c, 46.0, base * 1.3, "", 0, col)
		"bolt+fire":
			explode(c, 40.0, base, "", 0, col)
			for o in enemies:
				if not o.dead and center(o).distance_to(c) < 44.0:
					o.stun = maxf(o.stun, 0.3 if o.is_boss else 0.8)
		"bolt+ice":
			var hitl = [e]
			var cur = e
			for i in 4:
				var o = nearest_enemy(center(cur), 90.0, hitl)
				if o == null:
					break
				bolt(center(cur), center(o), col)
				hitl.append(o)
				cur = o
			for o in hitl:
				hurt_enemy(o, base * 0.9, "", Vector2.ZERO, true, col)
				if not o.dead and o != e:
					o.st["ice"] = 3.0
					o.chill = min(2, o.chill + 2)
		"ice+tox":
			e.frz = 1.2 if e.is_boss else 2.6
			e.vuln = 5.0
			hurt_enemy(e, base * 0.7, "", Vector2.ZERO, true, col)
		"bolt+tox":
			for o in enemies:
				if o.dead or center(o).distance_to(c) > 74.0:
					continue
				if o != e:
					bolt(c, center(o), col)
				o.st["tox"] = 5.0 * st.dur
				o.tox_n = max(o.tox_n, 3)
				o.st["bolt"] = 4.0 * st.dur
				hurt_enemy(o, base * 0.5, "", Vector2.ZERO, true, col)

func kill(e: Dictionary) -> void:
	if e.dead:
		return
	e.dead = true
	kills += 1
	Meta.stat("bosses" if e.is_boss else "kills")
	Meta.record("bosses" if e.is_boss else "foes", e.id)
	if p.syn.has("wildfire") and e.st.has("fire"):
		Ext.add_zone(self, e.pos, 18.0, "tox", 3.0)
	if p.relics.has("fang"):
		p.fang_n += 1
		if p.fang_n >= 25:
			p.fang_n = 0
			p.hp = min(p.mhp, p.hp + 1)
			label(p.pos + Vector2(0, -22), "+1", Color("ff6a7a"))
	if p.sk.rush:
		p.skill_cd = maxf(0.0, p.skill_cd - 0.4)
		p.skill2_cd = maxf(0.0, p.skill2_cd - 0.4)
	var c = center(e)
	burst(c, 12, e.col, 90.0, 0.5)
	burst(c, 5, Color.WHITE, 60.0, 0.3)
	Sfx.play("die")
	shake_add(2.0)
	var d = e.d
	drop("coin", c, d.cost + rng.randi() % 2)
	drop("orb", c, 1 + (1 if rng.randf() < 0.35 else 0))
	if d.has("child"):
		for i in 2:
			var ch = spawn_enemy(d.child, e.pos + Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)))
			ch.kb = Vector2.from_angle(rng.randf() * TAU) * 120.0
	if st.cond > 0 and not e.st.is_empty():
		var o = nearest_enemy(c, 80.0, [e])
		if o != null:
			var k = e.st.keys()[0]
			bolt(c, center(o), D.EL_COL[k])
			apply_el(o, k, 0.0)
	if st.vamp > 0 and rng.randf() < 0.3 * st.vamp and p.ar < p.mar:
		p.ar += 1
	if e.is_boss:
		boss = null
		boss_kills += 1
		hitstop = 0.25
		shake_add(10.0)
		Sfx.play("boom")
		banner = {text = d.name, sub = "DEFEATED", t = 3.0}
		drop("coin", c, 25)
		drop("orb", c, 10)
		for i in 8:
			after(i * 0.12, func():
				var q = c + Vector2(rng.randf_range(-24, 24), rng.randf_range(-24, 24))
				burst(q, 16, Color("ffd24a"), 110.0, 0.5)
				flash(q, 80.0, Color("ffb347"), 0.3)
				rings.append({pos = q, r = 30.0, t = 0.0, col = Color("fff2ae")}))
		for b in bullets:
			if b.team == 1:
				b.dead = true
		for o in enemies:
			if not o.dead:
				kill(o)

func hurt_player(dmg: int, el: String = "") -> void:
	if p.get("down", false) or p.inv > 0.0 or p.dash_t > 0.0 or state != "play":
		return
	if in_lobby or p.shield_t > 0.0:
		return
	if p.relics.has("skin") and p.skin_ready:
		p.skin_ready = false
		p.inv = 0.6
		Sfx.play("slash", 0.7)
		label(p.pos + Vector2(0, -22), "BLOCKED", Color("a8a7b8"))
		return
	if p.relics.has("boots"):
		el = ""
	p.room_hits += 1
	if boss != null:
		Meta.boss_credit(boss.id, D.BOSS_ATKS[boss.d.boss], boss.atk, float(dmg))
	if st.thorns > 0:
		p.inv = 0.1
		explode(pcenter(), 42.0, (8.0 + floor_i * 3.0) * st.thorns, "", 0)
	if p.mount != null and p.mount.hp > 0:
		p.mount.hp -= 1
		p.inv = 0.7
		p.flash = 0.2
		shake_add(4.0)
		Sfx.play("hurt", 1.3)
		burst(p.pos, 8, Color("8b5b3b"), 80.0, 0.4)
		if p.mount.hp <= 0:
			label(p.pos + Vector2(0, -22), "DISMOUNTED", Color("ff6a6a"))
		return
	var d = dmg
	var a = min(p.ar, d)
	p.ar -= a
	d -= a
	p.hp -= d
	p.inv = 0.8
	p.ar_t = 3.5
	p.flash = 0.2
	dmg_flash = 1.0 if d > 0 else 0.5
	tip("armor", "ARMOR GROWS BACK", "AVOID HITS FOR A FEW SECONDS. HEALTH DOES NOT.")
	shake_add(5.0)
	hitstop = maxf(hitstop, 0.05)
	Sfx.play("hurt")
	burst(pcenter(), 10, Color("ff5a6a") if d > 0 else Color("a8a7b8"), 90.0, 0.4)
	match el:
		"ice":
			p.slow = 1.8
			label(p.pos + Vector2(0, -22), "CHILLED", D.EL_COL["ice"])
		"tox":
			p.noregen = 5.0
			label(p.pos + Vector2(0, -22), "POISONED", D.EL_COL["tox"])
		"bolt":
			p.en = maxf(0.0, p.en - 12.0)
			label(p.pos + Vector2(0, -22), "DRAINED", D.EL_COL["bolt"])
	if p.hp <= 0 and p.wind2:
		p.wind2 = false
		p.hp = 2
		p.inv = 2.0
		label(p.pos + Vector2(0, -26), "SECOND WIND", Color("ffd24a"), true)
		explode(pcenter(), 60.0, 20.0, "", 0)
	if p.hp <= 0 and p.feather:
		p.feather = false
		p.hp = p.mhp
		p.inv = 2.5
		label(p.pos + Vector2(0, -26), "PHOENIX FEATHER", Color("ff8a3a"), true)
		explode(pcenter(), 70.0, 25.0, "fire", 0)
	if p.hp <= 0:
		p.hp = 0
		burst(pcenter(), 30, Color("ff5a6a"), 120.0, 0.8)
		Sfx.play("boom")
		p.down = true
		if players.all(func(q): return q.down):
			end_run(false)
		else:
			label(p.pos + Vector2(0, -26), "DOWN! STAND CLOSE TO REVIVE", Color("ff6a6a"), true)

func hurt_prop(pr: Dictionary, dmg: float) -> void:
	if pr.dead:
		return
	pr.hp -= dmg
	pr.flash = 0.1
	if pr.hp > 0.0:
		return
	pr.dead = true
	burst(pr.pos + Vector2(0, -5), 10, Color("c99b5c") if pr.kind == "crate" else D.EL_COL[pr.el], 80.0, 0.4)
	Sfx.play("hit", 0.6)
	if pr.kind == "crate":
		Meta.stat("crates")
		var roll = rng.randf()
		if roll < 0.14:
			drop("heart", pr.pos, 1)
			label(pr.pos + Vector2(0, -16), "LUCKY!", Color("ff6a7a"))
		elif roll < 0.20 and not in_lobby and lock != null:
			spawn_tele(D.BIOMES[floor_i / 2].roster[0], pr.pos, 0.5)
			label(pr.pos + Vector2(0, -16), "AMBUSH!", Color("ff6a6a"))
		elif roll < 0.60:
			drop("coin", pr.pos, 1 + rng.randi() % 2)
		elif roll < 0.85:
			drop("orb", pr.pos, 1)
	else:
		after(0.08, func():
			explode(pr.pos, 42.0, 12.0 + floor_i * 3.0, pr.el, 0)
			Ext.add_zone(self, pr.pos, 30.0, pr.el, 3.0)
			if p.pos.distance_to(pr.pos) < 40.0:
				hurt_player(1, pr.el))

func explode(pos: Vector2, r: float, dmg: float, el: String, team: int, col = null) -> void:
	var c: Color = col if col != null else (D.EL_COL[el] if el != "" else Color("ffb347"))
	rings.append({pos = pos, r = r, t = 0.0, col = c})
	burst(pos, int(8 + r / 3.0), c, r * 3.0, 0.4)
	burst(pos, 5, Color.WHITE, r * 2.0, 0.25)
	flash(pos, r * 2.6, c, 0.3)
	shake_add(r / 9.0)
	Sfx.play("boom", 1.3 if r < 30.0 else 1.0, -4.0 if r < 30.0 else 0.0)
	if team == 0:
		if el != "":
			Ext.zone_touch(self, pos, r * 0.6, el)
		for e in enemies:
			if e.dead:
				continue
			var d = center(e) - pos
			if d.length() < r + e.hr:
				hurt_enemy(e, dmg, el, d.normalized() * 130.0)
		for pr in props:
			if pr.pos.distance_to(pos) < r + 6.0:
				hurt_prop(pr, dmg)
	else:
		var keep = p
		for pl in players:
			if not pl.down and (pl.pos + Vector2(0, -3)).distance_to(pos) < r + 3.0:
				bind(pl)
				hurt_player(int(dmg), el)
		bind(keep)

# ---- bullets & zones -------------------------------------------------------------

func add_bullet(pos: Vector2, vel: Vector2, o: Dictionary) -> Dictionary:
	o.pos = pos
	o.vel = vel
	o.dead = false
	o.hit = []
	o.age = 0.0
	if not o.has("own"):
		o.own = int(p.get("idx", 0))
	for k in BDEF:
		if not o.has(k):
			o[k] = BDEF[k]
	bullets.append(o)
	return o

func update_bullets(dt: float) -> void:
	var pc = pcenter()
	for b in bullets:
		if b.dead:
			continue
		b.age += dt
		if b.team == 0:
			# damage, crits and synergies belong to whoever fired it
			bind(players[mini(int(b.get("own", 0)), players.size() - 1)])
		if b.lob:
			b.t += dt
			var k = b.t / b.dur
			b.pos = b.from.lerp(b.to, minf(k, 1.0))
			b.z = sin(minf(k, 1.0) * PI) * 30.0
			if k >= 1.0:
				b.dead = true
				explode(b.to, b.aoe, b.dmg, b.el, b.team)
				if b.puddle and b.el != "":
					if b.team == 0:
						Ext.add_zone(self, b.to, b.aoe * 0.8, b.el, 3.5)
					else:
						zones.append({pos = b.to, r = b.aoe * 0.8, el = b.el, life = 3.5, team = b.team, tick = 0.3})
			continue
		b.life -= dt
		if b.life <= 0.0:
			b.dead = true
			if b.get("arm", -1) >= 0:
				Meta.lead_result(b.arm, false)
			if b.aoe > 0.0:
				explode(b.pos, b.aoe, b.dmg * 0.6, b.el, b.team)
			continue
		var np = b.pos + b.vel * dt
		if solid_at(np.x, np.y) and not b.get("ghost", false):
			if b.bounce > 0:
				b.bounce -= 1
				var bx = solid_at(np.x, b.pos.y)
				var by = solid_at(b.pos.x, np.y)
				if bx or not by:
					b.vel.x = -b.vel.x
				if by or not bx:
					b.vel.y = -b.vel.y
				b.hit.clear()
			else:
				b.dead = true
				burst(b.pos, 3, D.EL_COL[b.el] if b.team == 0 else Color("ff5a6a"), 50.0, 0.2)
				if b.get("arm", -1) >= 0:
					Meta.lead_result(b.arm, false)
				if b.team == 0:
					if in_lobby:
						Lobby.hit_wall(self, int(floor(np.x / TS)), int(floor(np.y / TS)))
					else:
						More.hit_crack(self, int(floor(np.x / TS)), int(floor(np.y / TS)))
				if b.aoe > 0.0:
					explode(b.pos, b.aoe, b.dmg * 0.6, b.el, b.team)
			continue
		var prev: Vector2 = b.pos
		b.pos = np
		if b.team == 0:
			if b.kind != "flame" and Engine.get_process_frames() % 2 == 0:
				Fx.trail(self, b)
			for e in enemies:
				if e.dead or b.hit.has(e.uid):
					continue
				var rr = e.hr + b.r + 1.0
				var ec = center(e)
				if Geometry2D.get_closest_point_to_segment(ec, prev, np).distance_squared_to(ec) < rr * rr:
					hurt_enemy(e, b.dmg, b.el, b.vel.normalized() * 90.0)
					if (b.get("attune", false) or st.lens) and b.el != "" and not e.dead:
						apply_el(e, b.el, 0.0)
					if b.kind == "arrow" and p.syn.has("thunder"):
						var o2 = nearest_enemy(center(e), 70.0, [e])
						if o2 != null:
							bolt(center(e), center(o2), D.EL_COL["bolt"])
							hurt_enemy(o2, 3.0 + floor_i, "bolt", Vector2.ZERO, true)
					if b.aoe > 0.0:
						explode(b.pos, b.aoe, b.dmg * 0.6, b.el, 0)
						b.dead = true
						break
					if b.pierce > 0:
						b.pierce -= 1
						b.hit.append(e.uid)
					else:
						b.dead = true
						break
			if b.dead:
				continue
			for pr in props:
				if not pr.dead and pr.pos.distance_squared_to(b.pos + Vector2(0, 4)) < 64.0 and not b.hit.has(pr):
					hurt_prop(pr, b.dmg)
					if b.pierce > 0:
						b.hit.append(pr)
					else:
						b.dead = true
					break
		else:
			var rr = 3.0 + b.r
			var struck = false
			for pl in players:
				if pl.down or pl.inv > 0.0 or pl.dash_t > 0.0:
					continue
				var pc2: Vector2 = pl.pos + Vector2(0, -3)
				if Geometry2D.get_closest_point_to_segment(pc2, prev, np).distance_squared_to(pc2) < rr * rr:
					bind(pl)
					hurt_player(int(b.dmg), b.el)
					b.dead = true
					if b.get("arm", -1) >= 0:
						Meta.lead_result(b.arm, true)
					struck = true
					break
			if state != "play":
				return
			if struck:
				continue
			for pr in props:
				if not pr.dead and pr.kind == "crate" and pr.pos.distance_squared_to(b.pos + Vector2(0, 4)) < 49.0:
					b.dead = true
					hurt_prop(pr, 1.0)
					break

func update_zones(dt: float) -> void:
	for z in zones:
		z.life -= dt
		z.tick -= dt
		if z.has("pull"):
			for e in enemies:
				var pd = z.pos - e.pos
				if not e.dead and not e.is_boss and e.d.ai != "dummy" and pd.length() < z.pull and pd.length() > 3.0:
					move(e, pd.normalized() * 70.0 * dt)
		if rng.randf() < dt * 12.0:
			var q = z.pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf() * z.r
			parts.append({pos = q, vel = Vector2(0, -18), life = 0.5, max = 0.5, col = D.EL_COL[z.el], size = 1, grav = 0.0})
		if z.tick <= 0.0:
			z.tick = 0.5
			if z.team == 0:
				for e in enemies:
					if not e.dead and e.pos.distance_to(z.pos) < z.r + e.r:
						hurt_enemy(e, z.get("sdmg", 1.5 + floor_i * 0.5), z.el, Vector2.ZERO, true)
			else:
				for pl in players:
					if not pl.down and pl.pos.distance_to(z.pos) < z.r:
						bind(pl)
						hurt_player(1, z.el)

# ---- fx --------------------------------------------------------------------------

func burst(pos: Vector2, n: int, col: Color, spd: float = 80.0, life: float = 0.4, grav: float = 0.0) -> void:
	if net.mode == "host" and Sfx.logging and net.blog.size() < 40:
		net.blog.append([pos, n, col, spd, life, grav])
	if parts.size() > 900:
		return
	for i in n:
		var l = life * rng.randf_range(0.6, 1.2)
		parts.append({pos = pos, vel = Vector2.from_angle(rng.randf() * TAU) * spd * rng.randf_range(0.3, 1.0),
			life = l, max = l, col = col, size = 1 + rng.randi() % 2, grav = grav})

func num(pos: Vector2, text: String, col: Color, big: bool = false) -> void:
	if nums.size() < 80:
		nums.append({pos = pos, text = text, col = col, t = 0.0, big = big, dur = 0.7})

func label(pos: Vector2, text: String, col: Color, big: bool = false) -> void:
	nums.append({pos = pos, text = text, col = col, t = 0.0, big = big, dur = 1.1})

func bolt(a: Vector2, b: Vector2, col: Color) -> void:
	bolts.append({a = a, b = b, col = col, t = 0.16, straight = false})
	flash(b, 30.0, col, 0.15)

func flash(pos: Vector2, r: float, col: Color, dur: float) -> void:
	flashes.append({pos = pos, r = r, col = col, t = dur, max = dur})

func shake_add(v: float) -> void:
	if not Meta.S.opts.get("shake", true):
		return
	shake = minf(9.0, maxf(shake, v))

func update_fx(dt: float) -> void:
	for q in parts:
		q.pos += q.vel * dt
		q.vel = q.vel.lerp(Vector2.ZERO, minf(1.0, dt * 4.0))
		q.vel.y += q.grav * dt
		q.life -= dt
	parts = parts.filter(func(q): return q.life > 0.0)
	for q in nums:
		q.t += dt
		q.pos.y -= (26.0 if q.t < 0.25 else 8.0) * dt
	nums = nums.filter(func(q): return q.t < q.dur)
	for q in bolts:
		q.t -= dt
	bolts = bolts.filter(func(q): return q.t > 0.0)
	for q in rings:
		q.t += dt
	rings = rings.filter(func(q): return q.t < 0.3)
	for q in slashes:
		q.t += dt
	slashes = slashes.filter(func(q): return q.t < 0.16)
	for q in flashes:
		q.t -= dt
	flashes = flashes.filter(func(q): return q.t > 0.0)
	for q in ghosts:
		q.t -= dt
	ghosts = ghosts.filter(func(q): return q.t > 0.0)

# ---- drawing ---------------------------------------------------------------------

func spr(ci: CanvasItem, name: String, pos: Vector2, flip: bool = false, mod: Color = Color.WHITE, sc: Vector2 = Vector2.ONE, white: bool = false) -> void:
	var t: Texture2D = Art.W[name] if white else Art.T[name]
	var s = t.get_size()
	ci.draw_set_transform(pos.round(), 0.0, Vector2(-sc.x if flip else sc.x, sc.y))
	ci.draw_texture(t, Vector2(-floor(s.x / 2.0), -s.y), mod)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func on_screen(pos: Vector2, m: float = 40.0) -> bool:
	return pos.x > cam_tl.x - m and pos.y > cam_tl.y - m and pos.x < cam_tl.x + VW + m and pos.y < cam_tl.y + VH + m

func draw_scene(ci: CanvasItem) -> void:
	if state == "title" or p.is_empty():
		return
	for z in zones:
		var c: Color = D.EL_COL[z.el]
		var a = minf(1.0, z.life) * (0.8 if z.team == 0 else 1.0)
		ci.draw_circle(z.pos, z.r, Color(c.r, c.g, c.b, 0.16 * a))
		ci.draw_circle(z.pos, z.r * 0.72 + sin(time * 5.0 + z.pos.x) * 1.5, Color(c.r, c.g, c.b, 0.22 * a))
		ci.draw_arc(z.pos, z.r, 0.0, TAU, 20, Color(c.r, c.g, c.b, 0.6 * a), 1.0)
	Traps.draw(self, ci)
	for t in teles:
		var k = t.t / t.dur
		match t.kind:
			"spawn":
				ci.draw_arc(t.pos, 10.0 * (1.0 - k) + 3.0, 0.0, TAU, 12, Color(1, 0.3, 0.38, 0.9), 1.0)
				ci.draw_rect(Rect2(t.pos - Vector2(1, 1), Vector2(3, 3)), Color(1, 0.3, 0.38))
			"circle":
				ci.draw_circle(t.pos, t.r, Color(1, 0.2, 0.28, 0.14))
				ci.draw_circle(t.pos, t.r * k, Color(1, 0.2, 0.28, 0.25))
				ci.draw_arc(t.pos, t.r, 0.0, TAU, 28, Color(1, 0.4, 0.45, 0.95), 1.0)
			"line":
				ci.draw_line(t.pos, t.to, Color(1, 0.25, 0.3, 0.12 + 0.25 * k), 9.0)
				ci.draw_line(t.pos, t.to, Color(1, 0.45, 0.5, 0.8), 1.0)
	if lock != null:
		for g in lock.gates:
			var gp = Vector2(g) * TS
			ci.draw_rect(Rect2(gp, Vector2(16, 16)), Color(0.1, 0.05, 0.16, 0.55))
			for i in 3:
				var hgt = 12.0 + sin(time * 6.0 + i + g.x) * 2.0
				ci.draw_rect(Rect2(gp + Vector2(2 + i * 5, 14 - hgt), Vector2(2, hgt)), Color("ff5a8a"))
				ci.draw_rect(Rect2(gp + Vector2(2 + i * 5, 14 - hgt), Vector2(1, hgt)), Color("ffd0e0"))
	for t in dg.torches:
		if on_screen(t):
			spr(ci, "torch", t + Vector2(0, 5))
			var f = sin(time * 11.0 + t.x) * 1.0
			ci.draw_rect(Rect2(t + Vector2(-2, -7 + f), Vector2(4, 5 - f)), Color("f2812f"))
			ci.draw_rect(Rect2(t + Vector2(-1, -5 + f), Vector2(2, 3 - f)), Color("fff2ae"))
			if rng.randf() < 0.04:
				parts.append({pos = t + Vector2(rng.randf_range(-2, 2), -7), vel = Vector2(rng.randf_range(-5, 5), -22), life = 0.6, max = 0.6, col = Color("ffb347"), size = 1, grav = 0.0})
	for q in ghosts:
		spr(ci, q.get("spr", p.spr), q.pos + Vector2(0, p.r), q.flip, Color(0.6, 0.8, 1.0, q.t * 2.5), Vector2.ONE, true)

	var list = []
	for pr in props:
		list.append([pr.pos.y, 0, pr])
	for it in inter:
		list.append([it.pos.y - (20.0 if it.kind == "portal" else 0.0), 1, it])
	for k in pickups:
		list.append([k.pos.y, 2, k])
	for e in enemies:
		list.append([e.pos.y + e.r, 3, e])
	for a in allies:
		list.append([a.pos.y, 6, a])
	if state != "dead":
		for pl in players:
			list.append([pl.pos.y + pl.r, 4, pl])
			if pl.pet != null and not pl.down:
				list.append([pl.pet.pos.y + 3.0, 5, pl.pet])
	list.sort_custom(func(a, b): return a[0] < b[0])
	var sh: Texture2D = Art.T["shadow"]
	for it in list:
		var o = it[2]
		match it[1]:
			0:
				if not on_screen(o.pos):
					continue
				var nm = "crate" if o.kind == "crate" else "barrel_" + o.el
				ci.draw_texture(sh, o.pos + Vector2(-8, 1))
				spr(ci, nm, o.pos + Vector2(0, 5))
				if o.flash > 0.0:
					spr(ci, nm, o.pos + Vector2(0, 5), false, Color(1, 1, 1, 0.8), Vector2.ONE, true)
			1:
				draw_inter(ci, o)
			2:
				var bobk = absf(sin(o.t * 6.0)) * 2.0
				ci.draw_texture(sh, o.pos + Vector2(-8, 0), Color(1, 1, 1, 0.5))
				spr(ci, o.kind, o.pos + Vector2(0, 2 - bobk))
			3:
				if on_screen(o.pos, 60.0):
					draw_enemy(ci, o)
			4:
				bind(o)
				draw_player(ci)
			6:
				ci.draw_texture(sh, o.pos + Vector2(-8, 1))
				spr(ci, "e_turret", o.pos + Vector2(0, 5), false, Color(0.7, 1.0, 0.8) if (o.life > 1.5 or int(time * 10.0) % 2 == 0) else Color(1, 1, 1, 0.4))
			5:
				var hop = absf(sin(time * 9.0)) * 2.0 if o.moving else 0.0
				ci.draw_texture(sh, o.pos + Vector2(-8, 0), Color(1, 1, 1, 0.6))
				spr(ci, "pet_" + o.id, o.pos + Vector2(0, 4.0 - hop), o.face < 0)
	if me < players.size():
		bind(players[me])

func draw_inter(ci: CanvasItem, it: Dictionary) -> void:
	if not on_screen(it.pos, 60.0):
		return
	var sh: Texture2D = Art.T["shadow"]
	match it.kind:
		"relic", "active":
			var rt: Texture2D = Art.T["relic_" + it.id] if it.kind == "relic" else Art.T[D.ACTIVES[it.id].icon]
			ci.draw_texture(sh, it.pos + Vector2(-8, 2))
			ci.draw_arc(it.pos + Vector2(0, -6), 9.0 + sin(time * 4.0), 0.0, TAU, 14, Color(1.0, 0.82, 0.3, 0.5) if it.kind == "relic" else Color(0.36, 0.83, 0.95, 0.5), 1.0)
			ci.draw_texture(rt, (it.pos + Vector2(-rt.get_width() / 2.0, -6.0 - rt.get_height() / 2.0 + sin(time * 3.0 + it.pos.x) * 2.0)).round())
		"lchest":
			ci.draw_texture(sh, it.pos + Vector2(-8, 1))
			spr(ci, "chest_lock", it.pos + Vector2(0, 5))
		"plot":
			spr(ci, "plot", it.pos + Vector2(0, 6))
			var pl = Meta.S.garden[it.i]
			if pl.kind != "":
				spr(ci, "sprout" if int(pl.left) > 0 else "plant_" + pl.kind, it.pos + Vector2(0, 3))
		"hero":
			ci.draw_texture(sh, it.pos + Vector2(-8, 1))
			spr(ci, "h_" + Meta.hero(it.i).id, it.pos + Vector2(0, 5), it.pos.x > p.pos.x)
		"crystal":
			var cel: String = D.EL[it.i]
			ci.draw_texture(sh, it.pos + Vector2(-8, 1))
			spr(ci, "crystal_" + cel, it.pos + Vector2(0, 5))
			if Meta.S.el == it.i and not prism_next:
				ci.draw_arc(it.pos + Vector2(0, -2), 10.0 + sin(time * 4.0), 0.0, TAU, 16, D.EL_COL[cel], 1.0)
		"npc", "egg", "deco", "talk", "smith", "alch", "fuse", "shrine":
			ci.draw_texture(sh, it.pos + Vector2(-8, 1))
			var nb = 0.0
			if it.spr.begins_with("npc_"):
				nb = 1.0 if sin(time * 3.0 + it.pos.x) > 0.6 else 0.0
			spr(ci, it.spr, it.pos + Vector2(0, 5.0 - nb), it.spr.begins_with("npc_") and it.pos.x > p.pos.x, Color(0.5, 0.5, 0.55) if (it.kind == "shrine" and it.used) else Color.WHITE)
			if it.kind in ["smith", "alch", "fuse"]:
				var cost = Ext.station_cost(self, it)
				spr(ci, "coin", it.pos + Vector2(-9, 18))
				Px.text(ci, it.pos + Vector2(-4, 10), str(cost), Color("ffd24a") if p.gold >= cost else Color("ff6a6a"))
			if it.get("egg", "") == "fountain" and rng.randf() < 0.3:
				parts.append({pos = it.pos + Vector2(rng.randf_range(-2, 2), -6), vel = Vector2(rng.randf_range(-18, 18), -30), life = 0.6, max = 0.6, col = Color("c6f4ff"), size = 1, grav = 110.0})
			if it.get("egg", "") == "cat" and int(time) % 3 == 0:
				Px.text(ci, it.pos + Vector2(4, -16 - fmod(time, 1.0) * 4.0), "Z", Color(1, 1, 1, 1.0 - fmod(time, 1.0)))
		"chest":
			ci.draw_texture(sh, it.pos + Vector2(-8, 1))
			spr(ci, "chest_open" if it.open else "chest", it.pos + Vector2(0, 5))
		"weapon":
			var t: Texture2D = Art.T[Art.wtex(it.w)]
			var bobk = sin(time * 3.0 + it.pos.x) * 2.0
			ci.draw_texture(sh, it.pos + Vector2(-8, 2))
			ci.draw_texture(t, (it.pos + Vector2(-t.get_width() / 2.0, -6 - t.get_height() / 2.0 + bobk)).round())
			var rc2: Color = D.RAR_COL[D.WEAPONS[it.w.id].rar]
			if int(time * 4.0 + it.pos.x) % 3 == 0:
				ci.draw_rect(Rect2(it.pos + Vector2(sin(time * 2.0) * 8.0, -14 + cos(time * 3.0) * 3.0), Vector2(1, 1)), rc2)
		"shop":
			spr(ci, "pedestal", it.pos + Vector2(0, 6))
			var bobk = sin(time * 3.0 + it.pos.x) * 1.5
			match it.item.type:
				"weapon":
					var t: Texture2D = Art.T[Art.wtex(it.item.w)]
					ci.draw_texture(t, (it.pos + Vector2(-t.get_width() / 2.0, -10 - t.get_height() / 2.0 + bobk)).round())
				"relic":
					spr(ci, "relic_" + it.item.id, it.pos + Vector2(0, -3 + bobk))
				_:
					spr(ci, it.item.type, it.pos + Vector2(0, -3 + bobk))
			spr(ci, "coin", it.pos + Vector2(-9, 18))
			Px.text(ci, it.pos + Vector2(-4, 10), str(shop_price(it)), Color("ffd24a") if p.gold >= shop_price(it) else Color("ff6a6a"))
		"portal", "gate":
			var c = it.pos + Vector2(0, -8)
			for i in 5:
				var k = fmod(time * 0.8 + i / 5.0, 1.0)
				var colp = Color("9352cb").lerp(Color("7adfff"), k)
				ci.draw_set_transform(c, 0.0, Vector2(1.0, 1.35))
				ci.draw_arc(Vector2.ZERO, 3.0 + k * 11.0, time * 3.0 + i, time * 3.0 + i + 4.5, 14, Color(colp.r, colp.g, colp.b, 1.0 - k), 2.0)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			ci.draw_rect(Rect2(c - Vector2(2, 3), Vector2(4, 6)), Color("f6f2e6"))
			if rng.randf() < 0.2:
				parts.append({pos = c + Vector2(rng.randf_range(-12, 12), 14), vel = Vector2(0, -40), life = 0.6, max = 0.6, col = Color("c18cff"), size = 1, grav = 0.0})

func draw_enemy(ci: CanvasItem, e: Dictionary) -> void:
	var d = e.d
	var nm = "e_" + e.id
	var fr = nm
	if d.get("walk", false) and e.frz <= 0.0 and e.stun <= 0.0:
		fr = [nm + "_1", nm, nm + "_2", nm][int(e.anim * 8.0) % 4]
	var sc = Vector2.ONE * e.sc * (1.0 + 0.4 * e.cast_t)
	var off = -e.z
	if e.frz <= 0.0:
		if d.get("squash", false):
			var s = sin(e.anim * 6.0) * 0.09
			sc *= Vector2(1.0 + s, 1.0 - s)
		if d.get("fly", false):
			off += -3.0 + sin(e.anim * 4.0) * 2.0
		if d.ai == "bat":
			sc.y *= 0.8 + 0.3 * absf(sin(e.anim * 14.0))
	if e.state == "fuse":
		sc *= 1.0 + 0.25 * absf(sin(e.t * 30.0))
	var sh: Texture2D = Art.T["shadow"]
	var sw = e.r * 2.6
	ci.draw_texture_rect(sh, Rect2(e.pos.x - sw / 2.0, e.pos.y + e.r - 3.0, sw, 6.0 if e.r > 8.0 else 5.0), false)
	var mod = Color.WHITE
	if e.frz > 0.0:
		mod = Color(0.55, 0.85, 1.0)
	elif e.vuln > 0.0:
		mod = Color(0.8, 1.0, 0.72)
	elif e.st.has("fire"):
		mod = Color(1.0, 0.82, 0.7)
	elif e.st.has("tox"):
		mod = Color(0.82, 1.0, 0.7)
	var base = e.pos + Vector2(0, e.r + off)
	spr(ci, fr, base, e.face < 0, mod, sc)
	if e.flash > 0.0:
		spr(ci, fr, base, e.face < 0, Color(1, 1, 1, 0.85), sc, true)
	elif e.wind > 0.0 or e.state == "wind" or e.state == "fuse" or e.state == "aim":
		if int(time * 16.0) % 2 == 0:
			spr(ci, fr, base, e.face < 0, Color(1, 0.3, 0.3, 0.5), sc, true)
	var topy = base.y - e.h2 * 2.0
	if e.frz > 0.0:
		var rct = Rect2(base.x - e.h2 - 2.0, topy - 2.0, e.h2 * 2.0 + 4.0, e.h2 * 2.0 + 3.0)
		ci.draw_rect(rct, Color(0.6, 0.9, 1.0, 0.3))
		ci.draw_rect(rct, Color(0.85, 0.97, 1.0, 0.8), false, 1.0)
	var x = e.pos.x - e.st.size() * 4.5
	for k in e.st:
		ci.draw_texture(Art.T["ic_" + k], Vector2(roundf(x), roundf(topy - 12.0)))
		x += 9.0
	if e.elite:
		ci.draw_arc(e.pos + Vector2(0, e.r - 1.0), e.r * 2.0 + sin(time * 5.0), 0.0, TAU, 18, Color(1.0, 0.82, 0.3, 0.8), 1.0)
	if not e.is_boss and e.hp < e.mhp:
		ci.draw_rect(Rect2(e.pos.x - 7.0, topy - 1.0, 14, 2), Color("120e18"))
		ci.draw_rect(Rect2(e.pos.x - 7.0, topy - 1.0, 14.0 * clampf(e.hp / e.mhp, 0.0, 1.0), 2), Color("ff5a6a"))
	if e.wind > 0.0 or e.state == "wind" or e.state == "fuse":
		Px.ctext(ci, Vector2(e.pos.x, topy - 13.0), "!", Color("ffd24a"))
	Fx.status(self, ci, e, base, topy)
	Foes.draw_charge(self, ci, e)
	if e.is_boss:
		Fx.boss_fx(self, ci, e)

func draw_weapon(ci: CanvasItem) -> void:
	var w = p.weapons[p.wi]
	var def = D.WEAPONS[w.id]
	var t: Texture2D = Art.T[Art.wtex(w)]
	var hand = p.pos + Vector2(0, -2.0 - plift()) + p.aim * 3.0
	var ang = p.aim.angle()
	var flip = -1.0 if p.aim.x < 0.0 else 1.0
	if def.type == "melee":
		if p.swing > 0.0:
			ang += lerpf(-1.5, 1.5, p.swing / 0.18) * flip
		else:
			ang -= 0.7 * flip
	if p.spin > 0.0:
		ang = time * 28.0
	ci.draw_set_transform(hand.round(), ang, Vector2(1.0, flip))
	ci.draw_texture(t, Vector2(-1.0 - p.kick + (3.0 if def.spr == "bow" else 0.0), -t.get_height() / 2.0))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Fx.weapon_aura(self, ci, hand, w)

func plift() -> float:
	return 6.0 if (p.mount != null and p.mount.hp > 0) else 0.0

func draw_player(ci: CanvasItem) -> void:
	if p.get("down", false):
		spr(ci, p.spr, p.pos + Vector2(0, p.r + 1.0), p.face < 0, Color(0.45, 0.45, 0.55, 0.6))
		Px.ctext(ci, p.pos + Vector2(0, -22), "DOWN", Color("ff6a6a"))
		if float(p.get("rev", 0.0)) > 0.0:
			ci.draw_arc(p.pos, 12.0, -PI / 2.0, -PI / 2.0 + TAU * float(p.rev) / 2.5, 20, Color("a6e84e"), 2.0)
		return
	var nm: String = p.spr
	var fr = nm
	if p.moving:
		fr = [nm + "_1", nm, nm + "_2", nm][int(p.walk) % 4]
	var a = 0.45 if (p.inv > 0.0 and p.dash_t <= 0.0 and int(time * 18.0) % 2 == 0) else 1.0
	var mod = Color(1, 1, 1, a)
	if p.slow > 0.0:
		mod = Color(0.6, 0.85, 1.0, a)
	ci.draw_texture(Art.T["shadow"], p.pos + Vector2(-8, p.r - 3.0))
	Fx.fuse_aura(self, ci, p)
	var behind = p.aim.y < -0.35
	if behind:
		draw_weapon(ci)
	var base = p.pos + Vector2(0, p.r + 1.0 - plift())
	if plift() > 0.0:
		var mn = "m_" + p.mount.id
		spr(ci, [mn + "_1", mn, mn + "_2", mn][int(p.walk) % 4] if p.moving else mn, p.pos + Vector2(0, p.r + 2.0), p.face < 0)
	spr(ci, fr, base, p.face < 0, mod)
	if p.shield_t > 0.0:
		var scol: Color = D.EL_COL[p.weapons[p.wi].el]
		ci.draw_arc(pcenter(), 15.0 + sin(time * 12.0), 0.0, TAU, 20, Color(scol.r, scol.g, scol.b, 0.9), 2.0)
		ci.draw_circle(pcenter(), 14.0, Color(scol.r, scol.g, scol.b, 0.15))
	if p.rage_t > 0.0:
		spr(ci, fr, base, p.face < 0, Color(1.0, 0.2, 0.2, 0.3 + 0.2 * sin(time * 14.0)), Vector2.ONE, true)
	if p.flash > 0.0:
		spr(ci, fr, base, p.face < 0, Color(1, 1, 1, 0.8), Vector2.ONE, true)
	if not behind:
		draw_weapon(ci)
	if players.size() > 1:
		Px.ctext(ci, p.pos + Vector2(0, -25.0 - plift()), "P%d" % (p.idx + 1), Color("7adfff") if p.idx == 0 else Color("ffb84a"))

func draw_top(ci: CanvasItem) -> void:
	if state == "title" or p.is_empty():
		return
	for b in bullets:
		if not on_screen(b.pos, 16.0):
			continue
		var col: Color = D.EL_COL[b.el]
		if b.lob:
			ci.draw_texture(Art.T["shadow"], b.pos + Vector2(-8, -1), Color(1, 1, 1, 0.6))
			var t: Texture2D = Art.T["B_" + b.el]
			ci.draw_texture(t, (b.pos + Vector2(-5, -5 - b.z)).round())
		elif b.kind == "flame":
			var k = clampf(b.age / 0.34, 0.0, 1.0)
			ci.draw_circle(b.pos, 2.0 + 5.0 * k, Color(col.r, col.g, col.b, 0.75 * (1.0 - k)))
			ci.draw_circle(b.pos, 1.0 + 2.0 * k, Color(1.0, 0.96, 0.75, 0.9 * (1.0 - k)))
		elif b.kind == "arrow":
			var t: Texture2D = Art.T["arrow_" + b.el]
			ci.draw_set_transform(b.pos, b.vel.angle(), Vector2.ONE)
			ci.draw_texture(t, Vector2(-5, -1.5))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			Fx.tail(ci, b, col if b.team == 0 else Color(1.0, 0.3, 0.37))
			var nm = "eb_" + b.el if b.team == 1 else (("B_" if b.r >= 3.0 else "b_") + b.el)
			var t: Texture2D = Art.T[nm]
			ci.draw_texture(t, (b.pos - t.get_size() / 2.0).round())
	for q in bolts:
		var a = clampf(q.t / 0.08, 0.0, 1.0)
		var col = Color(q.col.r, q.col.g, q.col.b, a)
		if q.straight:
			ci.draw_line(q.a, q.b, Color(col.r, col.g, col.b, a * 0.5), 5.0)
			ci.draw_line(q.a, q.b, col, 3.0)
			ci.draw_line(q.a, q.b, Color(1, 1, 1, a), 1.0)
		else:
			var d = q.b - q.a
			var n = max(2, int(d.length() / 9.0))
			var perp = Vector2(-d.y, d.x).normalized()
			var pts = PackedVector2Array()
			for i in n + 1:
				var off = 0.0 if (i == 0 or i == n) else rng.randf_range(-4.0, 4.0)
				pts.append(q.a + d * (float(i) / n) + perp * off)
			ci.draw_polyline(pts, col, 3.0)
			ci.draw_polyline(pts, Color(1, 1, 1, a), 1.0)
	for q in rings:
		var k = q.t / 0.3
		ci.draw_arc(q.pos, q.r * (0.3 + 0.7 * k), 0.0, TAU, 24, Color(q.col.r, q.col.g, q.col.b, 1.0 - k), 2.0)
		ci.draw_arc(q.pos, q.r * (0.3 + 0.7 * k) - 2.0, 0.0, TAU, 24, Color(1, 1, 1, 0.6 * (1.0 - k)), 1.0)
	for q in slashes:
		var k = q.t / 0.16
		var a0 = q.ang - q.arc / 2.0 + q.arc * k * 0.5
		ci.draw_arc(q.pos, q.r * 0.85, a0, q.ang + q.arc / 2.0, 10, Color(q.col.r, q.col.g, q.col.b, 0.9 * (1.0 - k)), 4.0)
		ci.draw_arc(q.pos, q.r * 0.85 + 1.0, a0, q.ang + q.arc / 2.0, 10, Color(1, 1, 1, 1.0 - k), 1.0)
	for q in parts:
		var s = q.size if q.life > q.max * 0.4 else 1
		ci.draw_rect(Rect2(q.pos.round(), Vector2(s, s)), Color(q.col.r, q.col.g, q.col.b, q.col.a * minf(1.0, q.life / q.max * 2.0)))
	for q in nums:
		var a = clampf((q.dur - q.t) * 4.0, 0.0, 1.0)
		Px.ctext(ci, q.pos, q.text, Color(q.col.r, q.col.g, q.col.b, a), 2 if q.big else 1)
	for c in dg.get("cracks", []):
		var ccp = Vector2(c.cell) * TS
		if not c.open and on_screen(ccp):
			for seg in [[3, 2, 6, 7], [6, 7, 4, 12], [6, 7, 11, 9], [11, 9, 10, 14]]:
				ci.draw_line(ccp + Vector2(seg[0], seg[1]), ccp + Vector2(seg[2], seg[3]), Color(0.05, 0.03, 0.08, 0.9), 1.0)
	if in_lobby and not Meta.S.eggs.has("nook_open"):
		var cp = Vector2(Lobby.CRACK) * TS
		ci.draw_rect(Rect2(cp + Vector2(15, -56), Vector2(96, 128)), D.BIOMES[0].cap)
		for seg in [[2, 3, 5, 7], [5, 7, 3, 11], [5, 7, 9, 9], [9, 9, 8, 13]]:
			ci.draw_line(cp + Vector2(seg[0], seg[1]), cp + Vector2(seg[2], seg[3]), Color(0.05, 0.03, 0.08, 0.9), 1.0)
	# every hero on this screen gets its own prompt
	for pl in (players if local_coop() else [players[me]]):
		if not pl.down:
			bind(pl)
			find_near()
			draw_prompt(ci)
	bind(players[me])
	find_near()

func draw_prompt(ci: CanvasItem) -> void:
	if near != null and state == "play":
		var txt = ""
		var col = Color.WHITE
		match near.kind:
			"gate": txt = "ENTER THE DUNGEON"
			"relic":
				txt = D.RELICS[near.id].name
				col = Color("ffd24a")
			"active":
				txt = D.ACTIVES[near.id].name
				col = Color("5cd3f2")
			"lchest": txt = "UNLOCK" if p.keys > 0 else "LOCKED: NEEDS A KEY"
			"plot":
				var gp = Meta.S.garden[near.i]
				txt = "PLANT A SEED" if gp.kind == "" else ("GROWING" if int(gp.left) > 0 else "HARVEST " + D.SEEDS[gp.kind].name)
			"hero": txt = "PLAY AS " + Meta.hero(near.i).name
			"crystal":
				txt = D.EL_NAME[D.EL[near.i]] + " ELEMENT"
				col = D.EL_COL[D.EL[near.i]]
			"npc", "egg", "talk": txt = near.name
			"smith", "alch", "fuse": txt = near.name
			"shrine": txt = "OFFER 1 MAX HEALTH FOR A BLESSING"
			"chest": txt = "OPEN"
			"portal": txt = "DESCEND" if floor_i < LAST_FLOOR else "ESCAPE"
			"weapon":
				txt = wname(near.w)
				col = D.EL_COL[near.w.el]
			"shop":
				match near.item.type:
					"weapon":
						txt = wname(near.item.w)
						col = D.EL_COL[near.item.w.el]
					"potion": txt = "HEAL 2"
					"cell": txt = "FULL ENERGY"
					"tome": txt = near.item.buff.name
					"relic":
						txt = D.RELICS[near.item.id].name
						col = Color("ffd24a")
		var at = near.pos + Vector2(0, -44 if (near.kind == "portal" or near.kind == "gate") else -30)
		at.x = clampf(at.x, cam_tl.x + Px.width("E " + txt) / 2.0 + 6.0, cam_tl.x + VW - Px.width("E " + txt) / 2.0 - 6.0)
		var wdt = Px.width("E " + txt)
		ci.draw_rect(Rect2(at.x - wdt / 2.0 - 3, at.y - 2, wdt + 6, 11), Color(0.05, 0.03, 0.09, 0.8))
		Px.text(ci, at - Vector2(wdt / 2.0, 0), "E", Color("ffd24a"))
		Px.text(ci, at - Vector2(wdt / 2.0 - 12, 0), txt, col)

func draw_lights(ci: CanvasItem) -> void:
	if state == "title" or p.is_empty():
		return
	var lt: Texture2D = Art.T["light"]
	var off = -cam_tl
	var l = func(pos: Vector2, r: float, col: Color):
		ci.draw_texture_rect(lt, Rect2(pos + off - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false, col)
	for pl in players:
		l.call(pl.pos + Vector2(0, -6), 112.0 * (0.55 if (lock != null and lock.mod == "dark") else 1.0), Color(0.36, 0.34, 0.31))
		l.call(pl.pos + Vector2(0, -6), 44.0, Color(0.06, 0.06, 0.05))
	for t in dg.torches:
		if on_screen(t, 80.0):
			l.call(t, 66.0 + sin(time * 9.0 + t.x) * 4.0, Color(0.40, 0.24, 0.10))
	for b in bullets:
		if on_screen(b.pos, 30.0):
			var c: Color = D.EL_COL[b.el] if b.team == 0 else Color(1.0, 0.25, 0.3)
			l.call(b.pos, 24.0 if b.kind == "flame" else 17.0, c * (0.22 if b.kind == "flame" else 0.4))
	for z in zones:
		l.call(z.pos, z.r * 2.2, D.EL_COL[z.el] * 0.3)
	Traps.lights(self, l)
	for q in flashes:
		l.call(q.pos, q.r, q.col * (0.8 * q.t / q.max))
	for q in bolts:
		l.call(q.a.lerp(q.b, 0.5), 40.0, q.col * 0.35)
	for e in enemies:
		if e.is_boss:
			l.call(center(e), 70.0, (D.EL_COL[e.el] if e.el != "" else Color(0.8, 0.8, 1.0)) * 0.32)
		elif e.el != "":
			l.call(center(e), 24.0, D.EL_COL[e.el] * 0.28)
	for it in inter:
		if not on_screen(it.pos, 80.0):
			continue
		match it.kind:
			"portal", "gate": l.call(it.pos + Vector2(0, -8), 74.0 + sin(time * 4.0) * 4.0, Color(0.42, 0.25, 0.6))
			"chest":
				if not it.open:
					l.call(it.pos, 32.0, Color(0.3, 0.25, 0.1))
			"crystal": l.call(it.pos, 30.0, D.EL_COL[D.EL[it.i]] * 0.35)
			_: l.call(it.pos + Vector2(0, -6), 34.0, Color(0.3, 0.28, 0.22))
	for k in pickups:
		if on_screen(k.pos):
			l.call(k.pos, 10.0, Color(0.25, 0.22, 0.1) if k.kind == "coin" else Color(0.1, 0.22, 0.3))
	if lock != null:
		for g in lock.gates:
			l.call(Vector2(g) * TS + Vector2(8, 8), 26.0, Color(0.4, 0.12, 0.22))
