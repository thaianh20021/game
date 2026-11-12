extends Node2D
# Du Vang - single player action RPG, first chapter.
# The whole simulation lives here. Actors are plain dictionaries; positions are feet on the ground plane.
# Content is in data.gd, places in world.gd, panels in ui.gd.

const Art = preload("res://src/art.gd")
const Txt = preload("res://src/font.gd")
const Sfx = preload("res://src/sfx.gd")
const D = preload("res://src/data.gd")
const World = preload("res://src/world.gd")
const Ui = preload("res://src/ui.gd")
const Menu = preload("res://src/menu.gd")
const Sk = preload("res://src/skills.gd")
const Touch = preload("res://src/touch.gd")

const TS = 16
const F = 1.0 / 12.0
const RED = Color("ff4b2b")   # reserved: "leave this area". Nothing else may use it.
const VONG = Color("9fe3e0")
const AMBER = Color("ffc83d")  # reserved: "this cast can be interrupted"
const IVORY = Color("f4ebd0")

const SPEED = 88.0
const DODGE_T = 4 * F
const DODGE_SPEED = 192.0
const DODGE_INV = 0.25
const DODGE_RECHARGE = 1.6
const BAG = 24
const MUSIC = {"town": 0, "field": 1, "dungeon": 2, "forest": 4, "heart": 2, "salt": 1, "fleet": 2, "mines": 4, "foundry": 3, "capital": 0, "archive": 2, "maw": 3}

# [startup, active, recovery, damage x attack, reach, half angle, lunge speed, hitstop, shake]
const ATK = [
	[2 * F, F, 2 * F, 1.0, 36.0, 55.0, 60.0, 0.05, 1.5],
	[2 * F, F, 2 * F, 1.0, 36.0, 55.0, 60.0, 0.05, 1.5],
	[3 * F, F, 3 * F, 1.8, 42.0, 75.0, 110.0, 0.09, 3.0],
	[3 * F, F, 4 * F, 2.4, 46.0, 100.0, 110.0, 0.10, 3.0],   # only with the Fourth Strike keystone
]
const KEYS = ["atk", "dodge", "use", "inv", "potion", "buy", "opt1", "opt2", "s1", "s2", "s3", "s4", "s5", "s6", "ult", "tree", "reset", "filter", "menu", "tabn", "salv", "upg"]

# place
var zone = {}
var maps = {}
var blocks = []
var foes = []
var dead = []
var shots = []
var waves = []
var bolts = []
var rings = []
var zaps = []
var bursting = false
var blasts = []
var clouds = []
var tab = 0             # which tree the skill screen shows
var loot_filter = 0     # 0 all, 1 magic and better, 2 rare and better
var drops = []
var parts = []
var nums = []
var toasts = []
var motes = []
var next_id = 1

# hero, kept between sessions
var lvl = 1
var xp = 0
var gold = 0
var potions = 2
var inv = []
var eq = {"weapon": null, "armor": null, "charm": null}
var qs = {}             # quest id -> "active", "ready" (hand it in) or "done"
var qc = {}             # quest id -> {what: how many so far}
var flags = {}          # choices made, and "seen_<id>" for things and scenes
var tree = {}           # skill node id -> rank
var bar = ["", "", "", "", ""]   # active skills on keys 1 to 5
var buf_id = ""
var stats = {"atk": 10.0, "def": 0.0, "mhp": 100.0, "rage": 0.0, "spd": 0.0, "leech": 0.0, "reach": 0.0, "haste": 0.0, "stag": 0.0, "crit": 0.0, "cdr": 0.0, "regen": 0.0, "gold": 0.0}
var p = {}

var mode = "play"      # play, talk, inv, tree, fade, and the menu screens in menu.gd
var main_m = 0         # the mastery chosen at creation
var second_m = -1      # the one chosen when the shard woke; -1 means the default partner (see sec())
var ult = ""           # the ultimate on the R key
var has_save = false
var msel = 0
var csel = 0
var menu_back = "title"
var nav_prev = 0
var isel = 0           # the inventory cursor for keys and pads
var inv_pad = false    # true while the cursor, not the mouse, picks the item shown
var tsel = ""          # the skill tree cursor for keys and pads
var tree_pad = false
var mouse_prev = Vector2.ZERO
var hold_block = false
var fields = []        # fire walls and lightning cages the hero has put down
var ghosts = []        # echoes the hero has called
var chain_ids = []     # foes joined by a soul chain
var chain_t = 0.0
var sharing = false
var hitter = null      # the foe whose blow is landing, while hurt() runs
var pets = []          # the Hunter's hounds
var traps = []         # snares, mines and soul traps on the ground
var ranged = false     # true while an arrow, bolt or arrow rain is landing
var pet_hit = false    # true while a hound's bite is landing
var holy_hit = false   # true while holy damage is landing
var ghost_hit = false  # true while an echo's blow is landing
var devices = []       # the Artificer's turrets, mines and bell machine
var proto = ""         # the sixth skill slot (key 6) that the Prototype keystone opens
var scrap = 0          # bronze slag from taken-apart items, spent to reforge
var pulses = []
var opt = {"sfx": 100.0, "music": 100.0, "shake": 100.0, "flash": true, "nums": true, "full": false}
var talk = {}
var shop = false
var fade_t = 0.0
var pending = []
var t = 0.0
var hitstop = 0.0
var shake = 0.0
var cam = Vector2.ZERO
var cam_tl = Vector2.ZERO
var banner_t = 0.0
var warn_t = 0.0

var sim = {}           # tests drive the hero through this
var prev = {}
var buf = ""
var buf_t = 0.0
var pad = false
var pad_aim = Vector2.RIGHT
var touch_on = false     # a finger has touched the screen: show and read the touch controls
var touch_fingers = {}   # finger index -> the button it holds, or "stick"
var touch_stick = {}     # {"centre", "at"} while a finger drives the stick
var back_t = 0           # frames left of a phone Back press, read as "menu"

func _notification(what: int) -> void:
	# the phone's Back button opens or closes the menu instead of leaving the game
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back_t = 3

func _ready() -> void:
	get_tree().set_quit_on_go_back(false)
	Txt.build()
	Art.build()
	Sfx.init(self)
	Sfx.start_music()
	p = {"pos": Vector2.ZERO}
	load_opt()
	has_save = load_game()
	if not has_save:
		new_game()
	recompute()
	fresh_hero()
	if menus_on():
		mode = "title"   # set first: nothing is saved while the title is up
	enter_zone("town", Vector2.ZERO)
	if mode != "title" and not has_save:
		say("", "", D.INTRO, "", "")
		talk["story"] = true

func _input(ev: InputEvent) -> void:
	Touch.event(self, ev)
	if (ev is InputEventMouseMotion or ev is InputEventMouseButton) and not touch_on:
		pad = false
	elif ev is InputEventJoypadButton or (ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.4):
		pad = true

# ---------------------------------------------------------------- progress

func new_game() -> void:
	main_m = 0
	second_m = -1
	ult = ""
	proto = ""
	scrap = 0
	tab = 0
	lvl = 1
	xp = 0
	gold = 0
	potions = 2
	inv = []
	eq = {"weapon": D.make_item("weapon", 0, 0, 0), "armor": null, "charm": null}
	qs = {}
	qc = {}
	flags = {}
	tree = {}
	bar = ["", "", "", "", ""]

func fresh_hero() -> void:
	p = {
		"pos": p.get("pos", Vector2.ZERO), "vel": Vector2.ZERO, "hp": stats.mhp, "rage": 0.0, "rage_t": 0.0,
		"aim": Vector2.DOWN, "dir": Vector2.DOWN, "state": "idle", "st": 0.0, "combo": 0, "combo_t": 0.0, "idx": 0,
		"skill": "", "hit": [], "swung": false, "dodges": max_dodges(), "dodge_cd": 0.0, "inv": 0.0, "flash": 0.0, "moving": false,
		"pot_cd": 0.0, "cds": {}, "guard": 0.0, "riposte": 0.0, "mult": 1.0, "cry": 0.0, "dash": {},
		"charged": 0, "zap": false, "elem": "", "elem_t": 0.0, "cond_cd": 0.0, "slow": 0.0, "free": false, "icearm": 0.0, "smult": 1.0, "cp": 0, "fin": 0, "cp_got": false, "surecp": false, "sure_crit": false,
		"souls": 0, "soulform": 0.0, "form_n": 0, "night": 0.0, "hunger_t": 4.0, "raise_t": 0.0, "proxy_t": 0.0, "cheat_t": 0.0, "ash_t": 0.0, "ghstep_t": 0.0,
		"smoke": 0.0, "venom": 0.0, "follow_t": 0.0, "fallen_t": 0.0, "mark_t": 0.0,
		"shield": 0.0, "shield_hit": 0.0, "bronze": 0.0, "debt": false, "bash_more": false, "bash_t": -9.0, "break_t": 0.0, "fake_t": 0.0, "die_t": 0.0,
		"focus_t": 0.0, "focused": false, "focus_until": 0.0, "aim_need": 0.6, "chop_t": 0.0, "idle_t": 0.0, "signal_t": 0.0, "track_t": 0.0,
		"still_t": 0.0, "post": false, "hunt_all": 0.0, "reso_t": -9.0,
		"cast_t": 0.0, "cast_kind": "throw",
		"devo": 0.0, "bless_t": 0.0, "vow_t": 0.0, "vigil_t": 0.0, "zeal_t": 0.0, "hots": [], "rise_t": 0.0, "linked": false, "nqlit_t": 0.0,
		"parry_ext": false, "iron_n": 0, "iron_t": 0.0, "lastrun": 0, "longx": false, "reap2": false, "deep_t": 0.0,
		"heat": 0.0, "over": 0.0, "over_max": 4.0, "boost_t": 0.0, "hook_t": -9.0, "hookslam_t": 0.0, "tkmine_t": 0.0, "plcool_t": 0.0, "scrap_t": 0.0, "clpet_t": 0.0,
	}

func recompute() -> void:
	stats = {"atk": 8.0 + lvl * 2.0, "def": 0.0, "mhp": 90.0 + lvl * 10.0, "rage": 0.0, "spd": 0.0, "leech": 0.0, "reach": 0.0, "haste": 0.0, "stag": 0.0, "crit": 0.0, "cdr": 0.0, "regen": 0.0, "gold": 0.0}
	stats.def += 3.0 * tree.get("iron", 0)
	stats.mhp += 12.0 * tree.get("steady", 0)
	stats.leech += 1.5 * tree.get("bloodlust", 0)
	stats.rage += 15.0 * tree.get("hotblood", 0)
	stats.spd += 3.0 * tree.get("light", 0)
	stats.crit += 3.0 * tree.get("keen", 0)
	for slot in D.SLOTS:
		var it = eq[slot]
		if it == null:
			continue
		for k in it.stats:
			if k == "hp":
				stats.mhp += D.stat_of(it, k)
			else:
				stats[k] += D.stat_of(it, k)
		for rid in it.get("runes", []):
			for k in D.RUNES[rid].stats:
				if k == "hp":
					stats.mhp += D.RUNES[rid].stats[k]
				else:
					stats[k] += D.RUNES[rid].stats[k]
		for k in it.get("bonus", {}):
			if k == "hp":
				stats.mhp += it.bonus[k]
			else:
				stats[k] += it.bonus[k]
	var sc = set_counts()
	for sid in sc:
		var bonus = {}
		if sc[sid] >= 2:
			bonus.merge(D.SETS[sid].two)
		if sc[sid] >= 3:
			for k in D.SETS[sid].three:
				bonus[k] = bonus.get(k, 0) + D.SETS[sid].three[k]
		for k in bonus:
			if k == "hp":
				stats.mhp += bonus[k]
			else:
				stats[k] += bonus[k]
	if tree.has("ost_ghost"):
		stats.mhp *= 0.9
	if tree.has("unseen"):
		stats.mhp *= 0.8
	if p.has("hp"):
		p.hp = minf(p.hp, stats.mhp)

func give_xp(n: int) -> void:
	xp += n
	while xp >= D.xp_need(lvl):
		xp -= D.xp_need(lvl)
		lvl += 1
		recompute()
		p.hp = stats.mhp
		toast("CẤP %d" % lvl, Color("ffe9a3"))
		toast("NHẬN 1 ĐIỂM KỸ NĂNG. BẤM T ĐỂ MỞ CÂY.", VONG)
		Sfx.play("break", 1.4)
		for i in 16:
			parts.append({"pos": p.pos + Vector2(randf_range(-8, 8), -randf_range(0, 30)), "vel": Vector2(randf_range(-20, 20), randf_range(-70, -30)), "life": 0.8, "max": 0.8, "col": Color("ffe9a3"), "g": 0.0, "size": 1 + i % 2})

func toast(txt: String, col: Color = IVORY) -> void:
	toasts.append({"txt": txt, "t": 3.0, "col": col})
	if toasts.size() > 4:
		toasts.pop_front()

func save_game() -> void:
	if mode == "title" or mode == "create":
		return
	var f = FileAccess.open(D.SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"v": 2, "lvl": lvl, "xp": xp, "gold": gold, "potions": potions, "inv": inv, "eq": eq, "qs": qs, "qc": qc, "flags": flags, "tree": tree, "bar": bar, "filter": loot_filter, "main": main_m, "ult": ult, "second": second_m, "proto": proto, "scrap": scrap}))

func fix_item(it):
	if it == null:
		return null
	it.rar = int(it.rar)
	it.tier = int(it.tier)
	if it.has("bonus"):
		for k in it.bonus:
			it.bonus[k] = int(it.bonus[k])
	if it.has("plus"):
		it.plus = int(it.plus)
	if it.has("runes"):
		it.runes = Array(it.runes)
	for k in it.stats:
		it.stats[k] = int(it.stats[k])
	return it

func load_game() -> bool:
	if not FileAccess.file_exists(D.SAVE_PATH):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(D.SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY or int(d.get("v", 0)) != 2:
		return false
	lvl = int(d.lvl)
	xp = int(d.xp)
	gold = int(d.gold)
	potions = int(d.potions)
	inv = []
	for it in d.inv:
		inv.append(fix_item(it))
	for slot in D.SLOTS:
		eq[slot] = fix_item(d.eq.get(slot))
	qs = d.qs
	qc = {}
	for id in d.qc:
		qc[id] = {}
		for k in d.qc[id]:
			qc[id][k] = int(d.qc[id][k])
	flags = {}
	for k in d.flags:
		flags[k] = int(d.flags[k])
	tree = {}
	for k in d.get("tree", {}):
		if Sk.NODES.has(k):
			tree[k] = int(d.tree[k])
	bar = ["", "", "", "", ""]
	loot_filter = int(d.get("filter", 0))
	main_m = int(d.get("main", 0))
	second_m = int(d.get("second", -1))
	ult = d.get("ult", "")
	proto = d.get("proto", "")
	scrap = int(d.get("scrap", 0))
	if not tree.has(proto):
		proto = ""
	tab = main_m
	var sb = d.get("bar", [])
	for i in mini(sb.size(), 5):
		if tree.has(sb[i]):
			bar[i] = sb[i]
	return true

# ---------------------------------------------------------------- place

func enter_zone(id: String, at: Vector2) -> void:
	zone = World.build(id)
	if qs.get("m11", "") == "done":
		World.fate(zone, flags.get("village", 0))
	if qs.has("m17") and zone.id == "town":
		zone.npcs = zone.npcs.filter(func(n): return n.id != "dien")
	if zone.id == "maw" and qs.has("m25") and qs.get("m26", "") != "done" and int(flags.get("bond", 0)) >= 3:
		zone.npcs.append({"id": "ngai", "pos": Vector2(9 * TS, 17 * TS)})
	if zone.id == "capital" and qs.get("m26", "") == "done":
		zone.npcs.append({"id": "ngai", "pos": Vector2(47 * TS, 36 * TS)})
	if zone.id == "maw" and flags.has("first_dead") and not flags.has("van"):
		zone.things.append({"id": "voice", "pos": tp_maw_voice(), "h": 60.0})
	if zone.id == "salt" and flags.get("lh_days", []).size() >= 2 and not flags.has("lamp"):
		zone.things.append({"id": "lamp_keeper", "pos": lighthouse_pos() + Vector2(0, 10), "h": 40.0})
	if qs.get("s5", "") == "done" and zone.id == "mines":
		World.lantern(zone, 18.5, 24.2)
	if qs.get("m16", "") == "done" and zone.id == "town":
		zone.npcs = zone.npcs.filter(func(n): return n.id != "kham")
	if not maps.has(id):
		maps[id] = [Art.bake(zone.grid, 0, zone.theme), Art.bake(zone.grid, 1, zone.theme)]
	blocks.clear()
	for dc in zone.decor:
		if dc.solid:
			var tx: Texture2D = Art.T[dc.tex]
			var w = tx.get_width()
			var h = tx.get_height()
			if dc.has("bw"):
				blocks.append(Rect2(dc.pos.x - dc.bw / 2.0, dc.pos.y - 9, dc.bw, 11))
			else:
				blocks.append(Rect2(dc.pos.x - w / 2.0 + 3, dc.pos.y - h * 0.42, w - 6, h * 0.42 + 2))
	for n in zone.npcs:
		blocks.append(Rect2(n.pos.x - 6, n.pos.y - 5, 12, 7))
	for gt in zone.gates:
		if not flags.has(gt.flag):
			blocks.append(gt.rect)
	foes.clear()
	dead.clear()
	shots.clear()
	waves.clear()
	bolts.clear()
	rings.clear()
	zaps.clear()
	ghosts.clear()
	traps.clear()
	devices.clear()
	chain_ids = []
	fields.clear()
	pulses.clear()
	blasts.clear()
	clouds.clear()
	drops.clear()
	parts.clear()
	nums.clear()
	tide_zone()
	if not sim.get("no_spawns", false):
		for s in zone.spawns:
			if (s.has("once") and flags.has(s.once)) or (s.has("req") and not flags.has(s.req)):
				continue
			var nf = spawn(s.kind, s.pos)
			if s.has("elite"):
				make_elite(nf, s.elite)
			elif zone.get("tide", 0) > 0 and not D.FOES[s.kind].get("big", false) and randf() < 0.08 * zone.tide:
				make_elite(nf, ["volatile", "warding"][randi() % 2])
	p.pos = at if at != Vector2.ZERO else zone.start
	p.vel = Vector2.ZERO
	p.state = "idle"
	cam = p.pos
	banner_t = 2.5
	Sfx.play_music(MUSIC[id])
	buf = ""
	save_game()

func go(to: String, at: Vector2) -> void:
	mode = "fade"
	fade_t = 0.0
	pending = [to, at]

func walk(pos: Vector2) -> bool:
	var tx = int(floor(pos.x / TS))
	var ty = int(floor(pos.y / TS))
	if tx < 0 or ty < 0 or tx >= zone.w or ty >= zone.h or zone.grid[ty][tx] == 0:
		return false
	for b in blocks:
		if b.has_point(pos):
			return false
	return true

func free_at(pos: Vector2, r: float) -> bool:
	return walk(pos + Vector2(r, 0)) and walk(pos - Vector2(r, 0)) and walk(pos + Vector2(0, r * 0.6)) and walk(pos - Vector2(0, r * 0.6))

func move_actor(a: Dictionary, d: Vector2, r: float) -> void:
	if free_at(a.pos + Vector2(d.x, 0), r):
		a.pos.x += d.x
	if free_at(a.pos + Vector2(0, d.y), r):
		a.pos.y += d.y

func spawn(kind: String, pos: Vector2) -> Dictionary:
	var K = D.FOES[kind]
	var hp = K.hp * zone.mult
	var f = {
		"id": next_id, "kind": kind, "pos": pos, "home": pos, "hp": hp, "mhp": hp, "r": K.r, "state": "idle", "st": 0.0,
		"dir": Vector2.RIGHT, "tpos": pos, "flip": next_id % 2 == 0, "flash": 0.0, "kb": Vector2.ZERO, "poise": K.poise, "poise_t": 0.0,
		"cd": randf_range(0.3, 1.0), "stun": 0.0, "moving": false, "at": randf() * 4.0, "side": 1.0 if next_id % 2 == 0 else -1.0,
		"wind": K.wind, "atk": "", "n": 0, "sum": 0, "wt": randf_range(0.5, 3.0), "wdir": Vector2.ZERO, "burn": 0.0, "burn_dps": 0.0, "chill": 0.0, "shock": 0.0,
	}
	next_id += 1
	foes.append(f)
	return f

# ---------------------------------------------------------------- input

func held(n: String) -> bool:
	if sim.has(n):
		return sim[n]
	if Touch.held(self, n) or (n == "menu" and back_t > 0):
		return true
	match n:
		"atk":
			return (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not (touch_on and mode == "play")) or Input.is_key_pressed(KEY_J) or Input.is_joy_button_pressed(0, JOY_BUTTON_X)
		"dodge":
			return Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
		"s1":
			return Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_1) or Input.is_joy_button_pressed(0, JOY_BUTTON_B)
		"s2":
			return Input.is_key_pressed(KEY_2) or Input.is_key_pressed(KEY_Q) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER)
		"s3":
			return Input.is_key_pressed(KEY_3)
		"s4":
			return Input.is_key_pressed(KEY_4)
		"s6":
			return Input.is_key_pressed(KEY_6)
		"s5":
			return Input.is_key_pressed(KEY_5)
		"ult":
			return Input.is_key_pressed(KEY_R) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_STICK)
		"tree":
			return Input.is_key_pressed(KEY_T) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP)
		"reset":
			return Input.is_key_pressed(KEY_X) or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_STICK)
		"use":
			return Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_ENTER) or Input.is_joy_button_pressed(0, JOY_BUTTON_Y)
		"inv":
			return Input.is_key_pressed(KEY_I) or Input.is_key_pressed(KEY_TAB) or Input.is_joy_button_pressed(0, JOY_BUTTON_BACK)
		"menu":
			return Input.is_key_pressed(KEY_ESCAPE) or Input.is_joy_button_pressed(0, JOY_BUTTON_START)
		"potion":
			return Input.is_key_pressed(KEY_F) or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER)
		"salv":
			return Input.is_key_pressed(KEY_K) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN)
		"upg":
			return Input.is_key_pressed(KEY_U) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT)
		"tabn":
			return Input.is_key_pressed(KEY_G) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT)
		"filter":
			return Input.is_key_pressed(KEY_L)
		"buy":
			return Input.is_key_pressed(KEY_B) or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER)
		"opt1":
			return Input.is_key_pressed(KEY_1)
		"opt2":
			return Input.is_key_pressed(KEY_2)
	return false

func pressed(n: String) -> bool:
	return held(n) and not prev.get(n, false)

func move_dir() -> Vector2:
	if sim.has("move"):
		return sim.move
	var v = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1
	var j = Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if j.length() > 0.25:
		v = j
	var tm = Touch.move(self)
	if tm.length() > 0.15:
		v = tm
	return v.limit_length(1.0)

func ui_mouse() -> Vector2:
	if sim.has("ui_mouse"):
		return sim.ui_mouse
	return get_viewport().get_mouse_position()

func aim_pos() -> Vector2:
	if sim.has("mouse"):
		return sim.mouse
	if touch_on:
		return Touch.aim(self)
	if pad:
		var j = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
		if j.length() > 0.3:
			pad_aim = j.normalized()
		elif move_dir().length() > 0.3:
			pad_aim = move_dir().normalized()
		return p.pos + pad_aim * 60.0
	return get_viewport().get_mouse_position() + cam_tl

# ---------------------------------------------------------------- frame

func _process(delta: float) -> void:
	delta = minf(delta, 1.0 / 30.0)
	t += delta
	back_t = maxi(0, back_t - 1)
	banner_t -= delta
	warn_t -= delta
	if not held("atk"):
		hold_block = false
	for q in toasts:
		q.t -= delta
	toasts = toasts.filter(func(q): return q.t > 0.0)
	match mode:
		"play":
			# presses are buffered so one made during hit-stop or recovery is not lost
			if pressed("dodge"):
				buf = "dodge"
				buf_t = 0.2
			elif pressed_skill() != "":
				buf = "skill"
				buf_id = pressed_skill()
				buf_t = 0.2
			elif pressed("atk") or (held("atk") and buf == "" and not hold_block):
				buf = "atk"
				buf_t = 0.2
			if pressed("filter"):
				loot_filter = (loot_filter + 1) % 3
				toast("LỌC ĐỒ: " + D.FILTER_NAME[loot_filter], VONG)
			if pressed("potion"):
				drink()
			if pressed("menu"):
				Menu.open(self, "pause")
			elif pressed("tree"):
				mode = "tree"
				p.vel = Vector2.ZERO
				p.moving = false
				buf = ""
			elif pressed("inv"):
				open_inv(false)
			elif pressed("use"):
				interact()
			if hitstop > 0.0:
				hitstop -= delta
			elif mode == "play":
				step(delta)
		"title", "create", "second", "pause", "settings", "journal":
			Menu.update(self)
		"talk":
			Ui.talk_update(self)
		"tree":
			Ui.tree_update(self)
			if pressed("tree") or pressed("inv") or pressed("menu"):
				mode = "play"
				save_game()
		"inv":
			Ui.inv_update(self)
			if pressed("inv") or pressed("use") or pressed("menu"):
				mode = "play"
				save_game()
		"fade":
			var was = fade_t
			fade_t += delta
			if was < 0.25 and fade_t >= 0.25:
				enter_zone(pending[0], pending[1])
			if fade_t >= 0.5:
				mode = "play"
	shake = maxf(0.0, shake - delta * 18.0)
	# ash on the wind
	var vsz = get_viewport_rect().size
	if motes.is_empty():
		for i in 44:
			motes.append({"pos": Vector2(randf() * vsz.x, randf() * vsz.y), "vel": Vector2(randf_range(4, 14), randf_range(-7, 3)), "ph": randf() * TAU})
	for m in motes:
		m.pos += (m.vel + Vector2(0, sin(t + m.ph) * 4.0)) * delta
		m.pos = Vector2(fposmod(m.pos.x, vsz.x), fposmod(m.pos.y, vsz.y))
	update_cam(delta)
	for n in KEYS:
		prev[n] = held(n)
	queue_redraw()

func step(dt: float) -> void:
	var h0 = p.hp
	update_player(dt)
	update_foes(dt)
	update_shots(dt)
	update_fx(dt)
	update_ghosts(dt)
	update_shield(dt)
	update_hunter(dt)
	update_priest(dt)
	update_devices(dt)
	if tree.has("standin") and p.state != "dead" and h0 > 0.0 and p.hp > h0:
		# the price of the stand-in: every heal is weaker
		p.hp = h0 + (p.hp - h0) * 0.7

func update_cam(dt: float) -> void:
	var view = get_viewport_rect().size
	var look = (aim_pos() - p.pos).limit_length(120.0) * 0.2 if mode == "play" else Vector2.ZERO
	cam = cam.lerp(p.pos + look + Vector2(0, -14), 1.0 - exp(-10.0 * dt))
	var tl = cam - view / 2.0
	tl.x = clampf(tl.x, 0.0, maxf(0.0, zone.w * TS - view.x))
	tl.y = clampf(tl.y, 0.0, maxf(0.0, zone.h * TS - view.y))
	if shake > 0.0:
		tl += Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) * opt.shake / 100.0
	cam_tl = tl.floor()

# ---------------------------------------------------------------- talk, quests, shop

func open_inv(as_shop: bool) -> void:
	mode = "inv"
	shop = as_shop
	p.vel = Vector2.ZERO
	p.moving = false
	buf = ""

func equip(i: int) -> void:
	var it = inv[i]
	if it.slot == "rune":
		toast("ĐÁ ÂM CHỈ GHÉP ĐƯỢC Ở CỬA HÀNG.", Color("ff9a8a"))
		Sfx.play("deny")
		return
	var old = eq[it.slot]
	eq[it.slot] = it
	inv.remove_at(i)
	if old != null:
		inv.insert(i, old)
	recompute()
	Sfx.play("clap", 1.5, -4.0)

func unequip(slot: String) -> void:
	if eq[slot] == null or inv.size() >= BAG:
		return
	inv.append(eq[slot])
	eq[slot] = null
	recompute()

func sell(i: int) -> void:
	if inv[i].slot == "rune":
		set_rune(i)
		return
	gold += D.value(inv[i])
	inv.remove_at(i)
	Sfx.play("orb", 1.3)

func buy_potion() -> void:
	if gold >= D.POTION_COST:
		gold -= D.POTION_COST
		potions += 1
		Sfx.play("orb", 0.9)
	else:
		Sfx.play("deny")

func drink() -> void:
	if tree.has("otl_lich") or potions <= 0 or p.pot_cd > 0.0 or p.hp >= stats.mhp or p.state == "dead":
		Sfx.play("deny")
		return
	potions -= 1
	p.pot_cd = D.POTION_CD
	var heal = stats.mhp * D.POTION_HEAL
	p.hp = minf(stats.mhp, p.hp + heal)
	nums.append({"pos": p.pos + Vector2(0, -44), "txt": "+%d" % int(heal), "life": 0.8, "col": Color("8fe08a")})
	Sfx.play("orb", 0.8)

# ---------------------------------------------------------------- hero

func max_dodges() -> int:
	return 1 if tree.has("unbroken") else 2

func chain_len() -> int:
	return 4 if tree.has("fourth") else 3

func cur_atk() -> Array:
	var a: Array = (Sk.SWING[p.skill] if p.skill != "" else ATK[p.idx]).duplicate()
	a[4] += 3.0 * tree.get("reach", 0)
	a[4] += stats.reach
	if p.skill == "slash":
		a[3] *= 1.0 + p.fin
	elif p.skill == "exec":
		a[3] *= maxf(1.0, p.fin)
	if p.skill == "" and tree.has("lb_twin"):
		a[0] *= 0.8
		a[2] *= 0.8
	if p.skill == "" and tree.has("ocb_wide"):
		a[4] += 6.0
		a[5] += 20.0
	if p.skill == "" and D.is_bow(eq.weapon):
		a[6] = 0.0   # an archer does not step into the shot
	if p.skill == "":
		# the weapon's style: daggers quick and short, spears long and narrow, mauls slow and wide
		var W = D.WSTYLE[D.wstyle(eq.weapon)]
		a[0] *= W.speed
		a[2] *= W.speed
		a[3] *= W.dmg
		a[4] += W.reach
		a[5] = maxf(20.0, a[5] + W.arc)
		if W.last == "pierce" and p.idx == chain_len() - 1:
			a[4] += 16.0
			a[5] = 22.0
	if p.skill == "" and tree.has("fourth"):
		a[0] += F
	var haste = stats.haste + (25.0 if p.boost_t > 0.0 else 0.0) + (20.0 if (tree.has("tk_armor") and hot()) else 0.0)
	if p.skill == "" and haste != 0.0:
		# faster or slower strikes: only the wind-up and the recovery change, never the hit itself
		var hs = 1.0 / (1.0 + haste / 100.0)
		a[0] *= hs
		a[2] *= hs
	return a

# ---------------------------------------------------------------- skill tree

func points_left() -> int:
	return lvl - Sk.spent(tree)

func learn(id: String) -> bool:
	if Sk.blocked(tree, id, lvl, has_second(), main_m, sec()) != "":
		Sfx.play("deny")
		return false
	tree[id] = tree.get(id, 0) + 1
	if Sk.NODES[id].kind == "u" and cur_ult() == id:
		ult = id
	if Sk.NODES[id].kind == "a" and not bar.has(id):
		var i = bar.find("")
		if i >= 0:
			bar[i] = id
		elif tree.has("prototype") and proto == "" and Sk.NODES[id].get("m", 0) == 28:
			proto = id
	recompute()
	p.dodges = mini(p.dodges, max_dodges())
	Sfx.play("orb", 0.7)
	return true

func reset_tree() -> void:
	ult = ""
	proto = ""
	tree = {}
	bar = ["", "", "", "", ""]
	recompute()
	Sfx.play("clap", 0.8)

func assign(id: String, slot: int) -> void:
	if not tree.has(id) or Sk.NODES[id].kind != "a":
		return
	for i in bar.size():
		if bar[i] == id:
			bar[i] = bar[slot]
	bar[slot] = id

func pressed_skill() -> String:
	for i in Sk.BAR:
		if bar[i] != "" and pressed("s%d" % (i + 1)):
			return bar[i]
	if tree.has("prototype") and proto != "" and pressed("s6"):
		return proto
	if cur_ult() != "" and pressed("ult"):
		return cur_ult()
	return ""

func can_cast(id: String) -> bool:
	if (id == "bulwark" and tree.has("lb_twin")) or (id == "exec" and p.cp < 1):
		return false
	if soul_block(id) or (id == "verdict" and p.shield < 1.0):
		return false
	if not tree.has(id) or p.cds.has(id) or p.state == "dead":
		return false
	var cost = skill_cost(id)
	if p.free:
		cost = 0.0
	if cost > 0.0:
		if tree.has("price"):
			return p.hp > stats.mhp * 0.08 + 1.0
		return p.rage >= cost or (id == "spin" and tree.has("kt_spin") and p.souls >= 1)
	return true

func cast(id: String) -> bool:
	if not can_cast(id):
		Sfx.play("deny")
		return false
	if (id == "shadow" and shadow_target() == null) or (id == "cuts" and cuts_targets().is_empty()):
		Sfx.play("deny")
		return false
	if id == "spark" and foe_near(p.pos, 130.0, []) == null:
		Sfx.play("deny")
		return false
	if hunter_block(id) or priest_block(id) or artificer_block(id):
		Sfx.play("deny")
		return false
	var track = id == "shadow" and tree.has("ta_track") and t >= p.track_t and shadow_target().get("hunt", 0.0) > 0.0
	var N = Sk.NODES[id]
	var cost = skill_cost(id)
	if cost > 0.0 and p.free:
		p.free = false
		cost = 0.0
	if cost > 0.0:
		if tree.has("price"):
			p.hp -= stats.mhp * 0.08
		elif id == "spin" and tree.has("kt_spin") and p.rage < cost:
			p.souls -= 1
		else:
			p.rage -= cost
	var cd = skill_cd(id)
	if cd > 0.0:
		p.cds[id] = cd
	if tree.has("th_fire") and N.has("el") and p.souls >= 3:
		p.souls -= 1
		p.cds.erase(id)
	# resonance: a spell of another element than the last one, cast within 6 seconds, is a fifth stronger
	var el = N.get("el", "")
	p.smult = 1.0
	if el != "":
		if p.elem != "" and p.elem != el and p.elem_t > 0.0:
			p.smult = 1.4 if ((tree.has("lc_reso") and p.boost_t > 0.0) or tree.has("ont_triad")) else 1.2
			nums.append({"pos": p.pos + Vector2(0, -52), "txt": "CỘNG HƯỞNG", "life": 0.7, "col": Sk.MARK_COL[el]})
		elif tree.has("ont_triad") and p.elem == el and p.elem_t > 0.0:
			p.smult = 0.8
		if el == "shock" and cost > 0.0 and not tree.has("price") and randf() < 0.05 * tree.get("surge", 0):
			p.rage = minf(100.0, p.rage + cost)
	if el != "" and tree.has("th_reso") and p.soulform > 0.0:
		p.smult = 1.2
	if N.kind == "u" and has_uniq("eight"):
		p.hp = minf(stats.mhp, p.hp + stats.mhp * 0.08)
		p.rage = minf(100.0, p.rage + 8.0)
	if N.has("heat"):
		add_heat(float(N.heat))
	if el != "":
		if tree.has("lc_heat"):
			add_heat({"burn": 10.0, "shock": -10.0, "chill": -20.0}.get(el, 0.0))
		if tree.has("lc_reactor"):
			add_heat(15.0)
	if id == "spin" and tree.has("tk_spin") and p.boost_t > 0.0:
		add_heat(20.0)
	if id == "slash" and tree.has("tb_slash") and p.boost_t > 0.0:
		p.cds.erase("slash")
		add_heat(10.0)
	if id == "spark" and tree.has("lc_charge"):
		for d in devices:
			if d.pos.distance_to(p.pos) < 150.0:
				d.haste_t = 3.0
	if p.smult > 1.0 and tree.has("ls_shell"):
		add_shield(12.0)
	if el != "" and tree.has("nq_noon") and p.devo >= 100.0:
		p.smult *= 2.0
		p.devo = 0.0
		nums.append({"pos": p.pos + Vector2(0, -60), "txt": "CHÍNH NGỌ", "life": 0.9, "col": Sk.MARK_COL.lit})
	if p.smult > 1.0:
		p.reso_t = t + 6.0
	if track:
		p.track_t = t + 2.0
		p.cds.erase("shadow")
	if id != "hunt" and id != "bighunt" and id != "aimed":
		use_focus()
	match id:
		"raise", "wall", "bash", "verdict", "taunt", "cover", "bronze":
			guard_cast(id)
		"turret", "bellmine", "vent", "boost", "hook", "mute", "bellwork":
			artificer_cast(id)
		"knell", "holy", "seal", "purge", "bless", "vow", "vigil":
			priest_cast(id)
		"aimed", "rain", "snare", "mine", "sic", "hunt", "bighunt":
			hunter_cast(id)
		"ember":
			bolts.append({"pos": p.pos + p.aim * 10.0, "vel": p.aim * 260.0, "life": 0.45 if tree.has("ls_eye") else 0.9, "mult": 1.2 * p.smult})
			spell("burn")
			Sfx.play("spit", 1.4)
		"ring":
			if tree.has("ont_frostguard"):
				add_shield(15.0)
			rings.append({"pos": p.pos, "r": eye_r(62.0), "life": 0.35, "max": 0.35, "col": Sk.MARK_COL.chill})
			for f in foes:
				if f.state != "dead" and f.state != "spawn" and f.pos.distance_to(p.pos) < eye_r(62.0) + f.r:
					hit_foe(f, stats.atk * (1.2 if tree.has("ls_eye") else 1.0) * p.smult, false, 0.04, 1.5)
					mark(f, "chill")
			spell("chill")
			Sfx.play("spit", 0.5)
		"spark":
			var first_f = foe_near(p.pos, 130.0, [])
			if tree.has("ont_arc") and first_f != null:
				hit_foe(first_f, stats.atk * p.smult, false, 0.02, 1.0)
			spark_chain(p.pos, (6 if tree.has("overload") else 3) + (1 if (tree.has("tn_jump") and pet_up() != null) else 0), [])
			if tree.has("th_chain"):
				for o in foes:
					if chain_ids.has(o.id) and o.state != "dead":
						hit_foe(o, stats.atk * p.smult, false, 0.0, 0.0)
						mark(o, "shock")
			spell("shock")
			Sfx.play("parry", 1.5)
		"firewall":
			var fc = p.pos + p.aim * 46.0
			var fn = p.aim.orthogonal() * 44.0
			fields.append({"kind": "fire", "a": fc - fn, "b": fc + fn, "t": 4.0, "tick": 0.0})
			burn_wall(fields.back())
			spell("burn")
			Sfx.play("spit", 0.9)
		"shard":
			bolts.append({"pos": p.pos + p.aim * 10.0, "vel": p.aim * 320.0, "life": 0.35 if tree.has("ls_eye") else 0.7, "ice": true, "hit": [], "mult": 1.3 * p.smult})
			spell("chill")
			Sfx.play("spit", 1.8)
		"cage":
			cage_at(p.pos + (aim_pos() - p.pos).limit_length(140.0))
			spell("shock")
			Sfx.play("parry", 1.2)
		"tam":
			var tp = p.pos if tree.has("ls_eye") else p.pos + (aim_pos() - p.pos).limit_length(150.0)
			var kinds = ["burn", "chill", "shock"]
			for i in 3:
				pulses.append({"pos": tp, "t": 0.5 * i, "kind": kinds[i], "r": eye_r(60.0)})
			spell("shock")
			Sfx.play("tele_hi", 0.6)
		"bulwark":
			p.guard = 1.2
			p.parry_ext = false
			Sfx.play("parry", 0.6)
		"cry":
			p.cry = 6.0
			p.rage = minf(100.0, p.rage + 30.0)
			p.rage_t = 5.0
			Sfx.play("clap", 0.6)
			burst(p.pos + Vector2(0, -20), Color("ffe9a3"), 14, 120.0)
			nums.append({"pos": p.pos + Vector2(0, -52), "txt": "HÉT TRẬN", "life": 0.9, "col": Color("ffe9a3")})
		"summon":
			if tree.has("kl_heat") and p.souls < summon_cost():
				add_heat(30.0)
			else:
				p.souls -= summon_cost()
			add_ghost(p.pos + p.aim * 24.0, 20.0 + 4.0 * tree.get("lasting", 0) + (floorf(p.shield / 10.0) if tree.has("mv_coat") else 0.0), false)
			Sfx.play("orb", 0.5)
		"sacrifice":
			if ghosts.is_empty():
				pet_tithe()
			else:
				sacrifice(ghost_near(p.pos + (aim_pos() - p.pos).limit_length(160.0)))
		"weaken":
			var wp = p.pos + (aim_pos() - p.pos).limit_length(140.0)
			rings.append({"pos": wp, "r": 70.0, "life": 0.4, "max": 0.4, "col": Sk.MARK_COL.curse})
			if tree.has("oneword"):
				var one = foe_near(wp, 90.0, [])
				if one != null:
					curse(one)
			else:
				for f in foes:
					if f.state != "dead" and f.state != "spawn" and f.pos.distance_to(wp) < 70.0 + f.r:
						curse(f)
			Sfx.play("tele_lo", 0.7)
		"chain":
			chain_ids = []
			var cat = p.pos + (aim_pos() - p.pos).limit_length(140.0)
			for i in (5 if tree.has("otl_bind") else 3):
				var cf = foe_near(cat, 150.0 if i == 0 else 110.0, chain_ids)
				if cf == null:
					break
				chain_ids.append(cf.id)
				cat = cf.pos
			chain_t = 6.0
			if tree.has("gh_link"):
				var most = 0
				for f in foes:
					if chain_ids.has(f.id):
						most = maxi(most, f.get("poison", 0))
				for f in foes:
					if chain_ids.has(f.id) and most > f.get("poison", 0):
						poison(f, most - f.get("poison", 0))
			Sfx.play("parry", 0.5)
		"soulform":
			p.form_n = p.souls
			p.souls = 0
			p.soulform = 8.0
			if tree.has("gh_points"):
				add_cp(p.form_n)
			burst(p.pos + Vector2(0, -18), VONG, 16, 110.0)
			Sfx.play("orb", 0.4)
		"night":
			p.night = 8.0
			rings.append({"pos": p.pos, "r": 150.0, "life": 0.6, "max": 0.6, "col": VONG})
			Sfx.play("slam", 0.5)
		"shadow":
			var tgt = shadow_target()
			var from = p.pos
			var side = Vector2(1.0 if tgt.flip else -1.0, 0.0)
			var dest = tgt.pos + side * (tgt.r + 14.0)
			if not free_at(dest, 4.0):
				dest = tgt.pos - side * (tgt.r + 14.0)
			if free_at(dest, 4.0):
				p.pos = dest
			p.state = "idle"
			p.vel = Vector2.ZERO
			p.surecp = true
			if tree.has("dv_step"):
				add_shield(15.0)
			burst(from + Vector2(0, -16), Color("7a5c9e"), 10, 80.0)
			burst(p.pos + Vector2(0, -16), Color("7a5c9e"), 10, 80.0)
			Sfx.play("dash", 1.4)
			if tree.has("dl_step"):
				for o in foes:
					if o.state != "dead" and o.state != "spawn" and (o.pos.distance_to(from) < 30.0 + o.r or o.pos.distance_to(p.pos) < 30.0 + o.r):
						mark(o, "shock")
		"smoke":
			p.smoke = 6.0 if (tree.has("dv_smoke") and in_cover()) else 3.0
			if tree.has("ost_shadow"):
				p.smoke += 1.5
			burst(p.pos + Vector2(0, -14), Color("b9b2a3"), 16, 70.0)
			Sfx.play("spit", 0.4)
		"venom":
			p.venom = 8.0
			nums.append({"pos": p.pos + Vector2(0, -52), "txt": "TẨM ĐỘC", "life": 0.9, "col": Sk.MARK_COL.poison})
			Sfx.play("orb", 0.5)
		"darts":
			for da in [-0.25, 0.0, 0.25]:
				bolts.append({"pos": p.pos + p.aim * 10.0, "vel": p.aim.rotated(da) * 300.0, "life": 0.6, "dart": true, "mult": 0.6})
			Sfx.play("spit", 1.6)
		"slash", "exec":
			if id == "slash" and tree.has("dv_cut") and t - p.bash_t < 1.5:
				add_cp(1)
			p.fin = p.cp
			if not (tree.has("pq_grace") and p.vow_t > 0.0):
				p.cp = 0
			if tree.has("tb_fin"):
				add_heat(-6.0 * p.fin)
			if tree.has("pq_exec"):
				add_devo(4.0 * p.fin)
			if id == "slash" and tree.has("pq_slash"):
				heal(stats.mhp * 0.01 * p.fin)
			begin_swing(id)
			if p.fin >= 6:
				p.sure_crit = true
			if tree.has("ost_ghost"):
				p.smoke = maxf(p.smoke, 1.5)
			if tree.has("unseen"):
				p.smoke = maxf(p.smoke, 1.5)
		"cuts":
			var at = p.pos
			for f in cuts_targets():
				zaps.append({"a": at + Vector2(0, -14), "b": f.pos + Vector2(0, -14), "life": 0.3})
				hit_foe(f, stats.atk * 1.8, true, 0.04, 2.0)
				add_cp(1)
				at = f.pos
			if free_at(at + Vector2(0, 14), 4.0):
				p.pos = at + Vector2(0, 14)
			p.state = "idle"
			p.inv = maxf(p.inv, 0.6)
			Sfx.play("sw3", 1.4)
		"rush", "lunge":
			p.state = "dash"
			p.st = 0.0
			p.dir = p.aim
			p.hit = []
			p.skill = ""
			p.guard = 0.0
			p.dash = {"mult": (1.5 * (1.0 + minf(p.shield, 100.0) / 100.0 if tree.has("tt_rush") else 1.5)) if id == "rush" else 1.6, "stun": id == "rush"}
			Sfx.play("dash", 0.7)
		_:
			begin_swing(id)
	p.smult = 1.0
	if p.state == "idle":
		cast_fx(id)
	if id == "shadow" and tree.has("gh_step") and t >= p.ghstep_t:
		p.ghstep_t = t + 6.0
		add_ghost(p.pos, 5.0, true)
	if id == "lunge":
		p.follow_t = t + 3.0
	if id == "cry" and tree.has("ocb_cry"):
		p.cry += 3.0
	if id == "cry" and tree.has("kn_link") and p.bless_t > 0.0 and not p.linked:
		p.linked = true
		p.cry += 3.0
		p.bless_t += 3.0
	if id == "cry" and p.smoke > 0.0 and tree.has("lb_cry"):
		p.smoke += 2.0
	return true

func dmg_mult(f: Dictionary) -> float:
	var m = 1.0
	if p.soulform > 0.0:
		m *= 1.0 + 0.12 * p.form_n
	if tree.has("hunger"):
		m *= 1.0 + 0.06 * p.souls
	if p.debt:
		m *= 1.0 + 0.08 * tree.get("debt", 0)
	if t < p.focus_until:
		m *= 1.6 if tree.has("ots_deadeye") else 1.4
	if f.get("hunt", 0.0) > 0.0:
		m *= 1.25 if tree.has("ots_mark") else 1.15
		if tree.has("tp_big") and (f.get("elite", "") != "" or D.FOES[f.kind].get("big", false)):
			m *= 1.25
	if f.get("root", 0.0) > 0.0:
		m *= 1.0 + 0.06 * tree.get("spring", 0)
	if tree.has("hawk") and f.pos.distance_to(p.pos) > 100.0:
		m *= 1.0 + 0.04 * tree.hawk
	if ranged and p.post:
		m *= 1.3
	if f.get("lit", 0.0) > 0.0:
		m *= 1.05 + 0.03 * tree.get("lumen", 0) + (0.05 if tree.has("ott_bright") else 0.0)
		if tree.has("ch_lit") and f.get("curse", 0.0) > 0.0:
			m *= 1.1
	if holy_hit:
		m *= 1.0 + 0.05 * tree.get("sacred", 0)
	if p.bless_t > 0.0:
		if pet_hit or ghost_hit:
			m *= 1.0 + (0.25 if tree.has("ott_grace") else 0.15) * (1.5 if tree.has("devote") else 1.0) * (2.0 if (ghost_hit and tree.has("ch_bless")) else 1.0)
		elif not tree.has("devote"):
			m *= 1.25 if tree.has("ott_grace") else 1.15
	if tree.has("kn_oath") and p.hp < stats.mhp * 0.5:
		m *= 1.15
	if f.state == "wind":
		m *= 1.0 + 0.05 * tree.get("lens", 0)
	if hot():
		m *= 1.0 + 0.04 * tree.get("core", 0)
	if t < p.rise_t:
		m *= 1.3
	if f.get("chill", 0.0) > 0.0 and tree.has("ont_frostbite"):
		m *= 1.1
	if f.get("shock", 0.0) > 0.0 and tree.has("ont_charge"):
		m *= 1.1
	if tree.has("ost_seep"):
		m *= 1.0 + 0.03 * f.get("poison", 0)
	if tree.has("otl_lich"):
		m *= 1.0 + 0.03 * p.souls
	if tree.has("ots_lone"):
		m *= 1.25
	if tree.has("ott_saint"):
		m *= 0.9
	if tree.has("sv_martyr"):
		m *= 0.8
	if f.get("curse", 0.0) > 0.0:
		m *= 1.0 + 0.04 * tree.get("rot", 0) * (2.0 if tree.has("oneword") else 1.0)
	if p.cry > 0.0:
		m *= 1.3
	if p.hp < stats.mhp * 0.35:
		m *= 1.0 + 0.12 * tree.get("laststand", 0)
	if tree.has("price"):
		m *= 1.0 + 0.3 * p.rage / 100.0
	if f.get("burn", 0.0) > 0.0:
		m *= 1.0 + 0.04 * tree.get("heat", 0)
	if f.get("shock", 0.0) > 0.0:
		m *= 1.15 + 0.05 * tree.get("static", 0)
	if tree.has("brittle") and f.get("chill", 0.0) > 0.0:
		m *= 1.25
	if f.state == "stun":
		m *= 1.0 + 0.1 * tree.get("sunder", 0)
	if f.hp < f.mhp * 0.35:
		m *= 1.0 + 0.05 * tree.get("ruthless", 0)
	if has_uniq("seed"):
		var marks = 0
		for mk in ["burn", "chill", "shock"]:
			if f.get(mk, 0.0) > 0.0:
				marks += 1
		m *= 1.0 + 0.08 * marks
	return m

# ---------------------------------------------------------------- hero update

func update_player(dt: float) -> void:
	p.inv = maxf(0.0, p.inv - dt)
	p.flash = maxf(0.0, p.flash - dt)
	p.cast_t = maxf(0.0, p.cast_t - dt)
	p.pot_cd = maxf(0.0, p.pot_cd - dt)
	p.guard = maxf(0.0, p.guard - dt)
	p.slow = maxf(0.0, p.slow - dt)
	p.icearm = maxf(0.0, p.icearm - dt)
	p.venom = maxf(0.0, p.venom - dt)
	p.soulform = maxf(0.0, p.soulform - dt)
	p.night = maxf(0.0, p.night - dt)
	if p.souls > 0:
		p.hp = minf(stats.mhp, p.hp + 0.3 * tree.get("feed", 0) * p.souls * dt)
		if tree.has("hunger"):
			p.hunger_t -= dt
			if p.hunger_t <= 0.0:
				p.hunger_t = 4.0
				p.souls -= 1
	if p.smoke > 0.0:
		p.smoke = maxf(0.0, p.smoke - dt)
		if int(t * 12.0) != int((t - dt) * 12.0):
			parts.append({"pos": p.pos + Vector2(randf_range(-10, 10), -randf_range(0, 26)), "vel": Vector2(0, -10), "life": 0.5, "max": 0.5, "col": Color("b9b2a3"), "g": 0.0, "size": 2})
	p.riposte = maxf(0.0, p.riposte - dt)
	p.cry = maxf(0.0, p.cry - dt)
	for id in p.cds.keys():
		p.cds[id] -= dt
		if p.cds[id] <= 0.0:
			p.cds.erase(id)
	if p.dodges < max_dodges():
		p.dodge_cd -= dt * (0.5 if tree.has("brittle") else 1.0) * (1.0 + 0.15 * tree.get("escape", 0))
		if p.dodge_cd <= 0.0:
			p.dodges += 1
			p.dodge_cd = DODGE_RECHARGE
	buf_t -= dt
	if buf_t <= 0.0:
		buf = ""
	p.st += dt
	if p.state == "dead":
		if p.st > 2.2:
			var lost = gold / 10
			gold -= lost
			recompute()
			fresh_hero()
			go("town", Vector2.ZERO)
			toast("BẠN TỈNH LẠI TRONG TRẤN. MẤT %d VÀNG." % lost, Color("ff9a8a"))
		return
	p.elem_t = maxf(0.0, p.elem_t - dt)
	p.cond_cd = maxf(0.0, p.cond_cd - dt)
	if tree.has("furnace"):
		var lit = 0
		for f in foes:
			if f.state != "dead" and f.get("burn", 0.0) > 0.0:
				lit += 1
		if lit > 0:
			p.rage = minf(100.0, p.rage + 2.0 * mini(lit, 3) * dt)
			p.rage_t = 5.0
	if stats.regen > 0.0:
		p.hp = minf(stats.mhp, p.hp + stats.regen * dt)
	p.rage_t -= dt
	if p.rage_t <= 0.0:
		p.rage = maxf(0.0, p.rage - 4.0 * dt * (2.0 if tree.has("ocb_master") else 1.0))
	var mv = move_dir()
	var aim = aim_pos() - p.pos
	if aim.length() > 1.0:
		p.aim = aim.normalized()
	p.moving = false
	match p.state:
		"idle":
			p.vel = mv * SPEED * (1.0 + stats.spd / 100.0) * (0.5 if p.guard > 0.0 else 1.0) * (0.45 if (p.slow > 0.0 and not (tree.get("stand", 0) >= 2 and p.shield > 0.0)) else 1.0) * (1.3 if p.smoke > 0.0 else 1.0) * (0.85 if tree.has("fortress") else 1.0) * (1.15 if blessed() else 1.0) * (0.9 if tree.has("ohv_bulwark") else 1.0)
			p.moving = mv.length() > 0.1
			p.combo_t -= dt
			if p.combo_t <= 0.0:
				p.combo = 0
			try_actions(mv)
		"atk":
			var a = cur_atk()
			if p.st < a[0]:
				p.vel = p.dir * a[6]
				if buf == "dodge":
					start_dodge(mv)
			elif p.st < a[0] + a[1]:
				p.vel = p.dir * a[6] * 0.5
				if not p.swung:
					p.swung = true
					if p.skill == "spin":
						Sfx.play("spin")
					elif p.skill != "":
						Sfx.play("slam", 1.0 if p.skill == "slam" else 0.6)
						shake = maxf(shake, 3.0)
						slam_fx(p.pos, a[4] * 0.8)
					elif D.is_bow(eq.weapon):
						fire_basic()
					else:
						Sfx.play("sw3" if p.idx >= 2 else "sw1", 1.0 + p.idx * 0.08)
						if p.idx == 2 and eq.weapon != null and eq.weapon.uniq == "wave":
							waves.append({"pos": p.pos + p.dir * 20.0, "vel": p.dir * 230.0, "life": 0.55, "hit": []})
				if not (p.skill == "" and D.is_bow(eq.weapon)):
					swing_hits(a)
			else:
				p.vel = Vector2.ZERO
				var rt = p.st - a[0] - a[1]
				if buf == "dodge":
					start_dodge(mv)
				elif rt >= F and (buf == "atk" or buf == "skill"):
					try_actions(mv)
				elif rt >= a[2]:
					p.state = "idle"
					p.combo_t = 0.5
		"dash":
			p.vel = p.dir * 300.0
			if int(p.st / 0.04) != int((p.st - dt) / 0.04):
				parts.append({"pos": p.pos + Vector2(0, -12), "vel": Vector2.ZERO, "life": 0.25, "max": 0.25, "col": IVORY, "g": 0.0, "size": 2})
			for f in foes:
				if f.state == "dead" or f.state == "spawn" or p.hit.has(f.id):
					continue
				if f.pos.distance_to(p.pos) < f.r + 14.0:
					p.hit.append(f.id)
					hit_foe(f, stats.atk * p.dash.mult, true, 0.06, 2.0)
					if tree.has("conduct") and f.get("shock", 0.0) > 0.0 and p.cond_cd <= 0.0:
						p.cond_cd = 2.0
						spark_chain(f.pos, 6 if tree.has("overload") else 3, [f.id])
					if p.dash.stun and tree.has("tp_toss") and f.state != "dead":
						f.kb = p.dir * 260.0
						f.tossed_t = t + 0.8
					if p.dash.stun and f.state != "dead":
						stagger(f, 0.7)
			if p.st >= 0.3:
				p.state = "idle"
				p.vel = Vector2.ZERO
		"dodge":
			p.vel = p.dir * DODGE_SPEED
			if int(p.st / 0.05) != int((p.st - dt) / 0.05):
				parts.append({"pos": p.pos + Vector2(0, -2), "vel": Vector2(0, -8), "life": 0.3, "max": 0.3, "col": Color("d8cfb8"), "g": 0.0, "size": 2})
			if p.st >= DODGE_T:
				p.state = "idle"
				p.vel = Vector2.ZERO
		"aim":
			# standing still and drawing the bow; a dodge gives the shot up
			p.vel = Vector2.ZERO
			p.dir = p.aim
			if buf == "dodge":
				start_dodge(mv)
			elif p.st >= p.aim_need:
				fire_arrow()
				p.state = "idle"
	# a strike's step forward stops at the target instead of sliding through it
	if p.state == "atk":
		for f in foes:
			var d = f.pos - p.pos
			if f.state != "dead" and f.state != "spawn" and d.length() < f.r + 14.0 and d.dot(p.dir) > 0.0:
				p.vel = Vector2.ZERO
				break
	move_actor(p, p.vel * dt, 4.0)
	for po in zone.portals:
		if po.rect.has_point(p.pos):
			if po.need != "" and not qs.has(po.need):
				if warn_t <= 0.0:
					warn_t = 2.5
					toast("ĐƯỜNG BỊ CHẶN. HÃY GẶP BÀ CẢ SẬY.", Color("ff9a8a"))
			else:
				go(po.to, po.at)
			break
	for sc in zone.scenes:
		var S = D.SCENES[sc.id]
		if not flags.has("seen_" + sc.id) and qs.get(S.quest, "") == "active" and sc.rect.has_point(p.pos):
			scene(sc)
			break

func try_actions(mv: Vector2) -> void:
	if buf == "dodge":
		start_dodge(mv)
	elif buf == "skill":
		buf = ""
		cast(buf_id)
	elif buf == "atk":
		buf = ""
		begin_swing("")

# skill "" is the next strike of the chain
func begin_swing(skill: String) -> void:
	p.state = "atk"
	p.st = 0.0
	p.dir = p.aim
	p.skill = skill
	p.hit = []
	p.swung = false
	p.guard = 0.0
	p.mult = 2.0 if p.riposte > 0.0 else 1.0
	p.cp_got = false
	p.sure_crit = false
	if p.smoke > 0.0:
		p.sure_crit = true   # the first blow out of the smoke is a critical one
		p.smoke = 0.0
	p.zap = false
	if skill == "" and p.charged > 0:
		p.charged -= 1
		p.zap = true
	p.riposte = 0.0
	if skill == "":
		use_focus()
		if tree.has("ocb_surge") and p.rage >= 100.0:
			p.rage -= 30.0
			p.mult *= 2.0
	p.reap2 = false
	p.longx = false
	if skill == "bash" and tree.has("tt_beat"):
		pass   # the shield bash keeps the chain going
	elif skill != "":
		p.combo = 0
	else:
		p.idx = p.combo
		if p.idx == chain_len() - 1 and tree.has("ocb_long"):
			p.lastrun += 1
			p.longx = p.lastrun >= 3
			if p.longx:
				p.lastrun = 0
		p.combo = (p.combo + 1) % chain_len()

func start_dodge(mv: Vector2) -> void:
	buf = ""
	if p.dodges <= 0:
		Sfx.play("deny")
		return
	if p.dodges == max_dodges():
		p.dodge_cd = DODGE_RECHARGE
	p.dodges -= 1
	p.dir = mv.normalized() if mv.length() > 0.1 else p.aim
	p.state = "dodge"
	p.st = 0.0
	p.inv = DODGE_INV
	p.guard = 0.0
	Sfx.play("dash")

func in_arc(a: Array, d: Vector2, r: float) -> bool:
	if d.length() > a[4] + r:
		return false
	if a[5] < 180.0 and d.length() > 4.0 and absf(rad_to_deg(p.dir.angle_to(d))) > a[5]:
		return false
	return true

func swing_hits(a: Array) -> void:
	var big = p.skill != "" or p.idx >= 2
	var mult = a[3] * p.mult
	if p.skill == "scythe" and tree.has("kt_scythe"):
		mult *= 1.0 + 0.12 * tree.get("heavy", 0)
	var last = p.skill == "" and p.idx == chain_len() - 1
	if p.skill == "" and p.idx == chain_len() - 1:
		mult *= 1.0 + 0.12 * tree.get("heavy", 0)
	elif p.skill == "" and tree.has("tt_true") and p.shield > 0.0:
		mult *= 1.0 + 0.12 * tree.get("heavy", 0)
	if p.longx and last:
		mult *= 2.0
	if tree.has("ocb_master"):
		mult *= 1.15
	if p.skill == "bash":
		if p.bash_more:
			mult *= 2.4 / 1.4
		if tree.has("tt_beat"):
			mult *= 1.0 + 0.12 * tree.get("heavy", 0)
	for f in foes:
		if f.state == "dead" or f.state == "spawn" or p.hit.has(f.id):
			continue
		if in_arc(a, f.pos - p.pos, f.r):
			p.hit.append(f.id)
			var fm = mult
			var broke = false
			if last and tree.has("shatter") and f.get("chill", 0.0) > 0.0:
				fm *= 1.8
				broke = true
				f.chill = 0.0
			var behind = is_behind(f)
			var was_chill = f.get("chill", 0.0) > 0.0
			var keep_crit = p.sure_crit
			if p.skill == "scythe" and tree.has("gh_back") and behind:
				p.sure_crit = true
			var soft = f.state == "stun" or f.get("chill", 0.0) > 0.0
			var was_stun = f.state == "stun"
			var was_shock = f.get("shock", 0.0) > 0.0
			var fin = p.skill == "slash" or p.skill == "exec"
			var cracked = false
			if p.skill == "bash" and tree.has("ls_crack") and f.get("chill", 0.0) > 0.0:
				fm *= 1.6
				f.chill = 0.0
				cracked = true
			if p.skill == "":
				if behind:
					fm *= 1.0 + 0.08 * tree.get("backstab", 0)
				if tree.has("six"):
					fm *= 0.85
			elif fin:
				if tree.has("dl_three") and f.get("burn", 0.0) > 0.0 and f.get("chill", 0.0) > 0.0 and was_shock:
					fm *= 1.6
					f.burn = 0.0
					f.chill = 0.0
					f.shock = 0.0
				if p.skill == "slash" and tree.has("dl_rupture") and f.get("burn", 0.0) > 0.0:
					f.hp -= f.burn * f.burn_dps
					f.burn = 0.0
				if p.skill == "exec" and f.get("elite", "") == "" and not D.FOES[f.kind].get("big", false) and f.hp < f.mhp * 0.06 * p.fin:
					fm = maxf(fm, f.hp * 3.0 / stats.atk)
			hit_foe(f, stats.atk * fm, big, a[7], a[8])
			p.sure_crit = keep_crit
			if f.state != "dead":
				if p.skill == "bash" and (not D.FOES[f.kind].get("big", false) or cracked):
					if tree.has("pl_bash") and t - p.hook_t < 1.5:
						stagger(f, 2.4 if cracked else 1.2)
					else:
						stagger(f, 1.2 if cracked else 0.6)
				if p.skill == "spin" and tree.has("tt_pull") and f.get("taunt", 0.0) > 0.0:
					var pull = p.pos + (f.pos - p.pos).normalized() * (f.r + 12.0)
					if free_at(pull, f.r * 0.6):
						f.pos = pull
					stagger(f, 0.5)
			if p.skill == "scythe":
				p.hp = minf(stats.mhp, p.hp + stats.mhp * 0.02 * (2.0 if (tree.has("th_cold") and was_chill) else 1.0) * (2.0 if (tree.has("ch_scythe") and in_holy()) else 1.0))
				if f.state == "dead":
					add_soul(1)
			if f.state != "dead":
				if (p.skill == "slam" and tree.has("kn_slam")) or (p.skill == "bash" and tree.has("sv_bash")):
					f.purge = 4.0
				if last and tree.has("kn_lit") and f.get("lit", 0.0) > 0.0:
					f.lit = 0.0
					holy_burst(f.pos, 40.0, 0.8, -1)
			if last and tree.has("kn_strike"):
				add_devo(8.0)
			if f.state != "dead" and f.get("hunt", 0.0) > 0.0:
				if last and tree.has("tp_signal") and t >= p.signal_t and pet_up() != null:
					p.signal_t = t + 3.0
					f.hunt = 10.0
					pet_pounce(pet_up(), f, 1.0, 0.0)
				if p.skill == "bash" and tree.has("bv_bash"):
					root(f, 1.5)
			if last and f.state == "dead" and tree.has("kt_reap"):
				add_soul(1)
			if fin and f.state == "dead":
				if tree.has("ost_reset"):
					add_cp(2)
				if tree.has("gh_take"):
					add_soul(p.fin / 2)
				if p.skill == "exec" and tree.has("gh_raise") and t >= p.raise_t:
					p.raise_t = t + 6.0
					add_ghost(f.pos, 20.0, true)
			if p.skill == "":
				# a danger point: from behind, on a foe that is stunned or chilled, or when a skill promised one
				if not p.cp_got and (behind or soft or p.surecp or (last and tree.has("lb_last"))):
					p.cp_got = true
					p.surecp = false
					add_cp(1)
				if f.state != "dead":
					if p.venom > 0.0 or (tree.has("lb_twin") and p.idx % 2 == 1):
						poison(f, 1)
					if p.venom > 0.0 and tree.has("dl_coat") and p.elem != "" and t >= f.get("coat_t", 0.0):
						f.coat_t = t + 4.0
						mark(f, p.elem)
			elif fin:
				if tree.has("burst") and f.state != "dead" and f.get("poison", 0) > 0:
					f.hp -= f.poison * f.poison_t * poison_dps()
					f.poison = 0
					if f.hp <= 0.0:
						kill(f)
				if p.skill == "slash" and was_stun and tree.has("lb_fallen") and t >= p.fallen_t:
					p.fallen_t = t + 4.0
					p.cp = p.fin
				if p.skill == "exec":
					if f.state == "dead" and tree.has("lb_boil"):
						p.rage = minf(100.0, p.rage + 30.0)
					if was_shock and tree.has("dl_judge"):
						spark_chain(f.pos, 3, [f.id])
			if f.state != "dead":
				if broke:
					stagger(f, 0.7)
					nums.append({"pos": f.pos + Vector2(0, -foe_h(f) - 8), "txt": "VỠ BĂNG", "life": 0.8, "col": Sk.MARK_COL.chill})
				if p.skill == "":
					if p.zap:
						mark(f, "shock")
					if tree.has("tempest") and p.elem_t > 0.0:
						mark(f, p.elem)
				if last and has_uniq("forge"):
					mark(f, "burn")
				if last:
					match D.WSTYLE[D.wstyle(eq.weapon)].last:
						"poison":
							poison(f, 1)
						"stun":
							if not D.FOES[f.kind].get("big", false):
								stagger(f, 0.6)
				elif p.skill == "toll" and tree.has("afterglow"):
					for mk in ["burn", "chill", "shock"]:
						mark(f, mk)
			if p.skill == "toll" and tree.has("kt_toll"):
				curse(f)
			if p.skill == "toll" and f.state != "dead":
				stagger(f, 3.0 if (tree.has("tk_toll") and in_mute(p.pos)) else 1.5)
			if p.skill == "":
				p.rage = minf(100.0, p.rage + (14.0 if p.idx >= 2 else 8.0) * (1.0 + stats.rage / 100.0) * (2.0 if (tree.has("ocb_blood") and p.hp < stats.mhp * 0.5) else 1.0))
				if tree.has("tk_chop"):
					add_heat(-8.0 if last else -3.0)
	if p.skill == "spin" and tree.has("lb_ring"):
		var most = 0
		for f in foes:
			if p.hit.has(f.id) and f.state != "dead":
				most = maxi(most, f.get("poison", 0))
		if most > 0:
			for f in foes:
				if p.hit.has(f.id) and f.state != "dead" and f.get("poison", 0) < most:
					poison(f, most - f.get("poison", 0))
	if p.skill == "spin" and tree.has("kn_spin") and in_holy() and not p.hit.is_empty():
		heal(stats.mhp * minf(0.1, 0.02 * p.hit.size()))
	if p.skill == "scythe" and tree.has("otl_reap") and not p.reap2 and p.hit.size() >= 3:
		p.reap2 = true
		add_soul(1)
	if p.skill == "slam" and tree.has("tp_quake"):
		for tr in traps.duplicate():
			if tr.pos.distance_to(p.pos) < a[4] + 10.0:
				spring_trap(tr, 1.5)
	if p.skill == "spin" and tree.has("tp_spin"):
		for fd in fields:
			if fd.kind == "rain" and not fd.get("grown", false) and fd.pos.distance_to(p.pos) < fd.r:
				fd.grown = true
				fd.r *= 1.4
	if p.skill == "slam" and tree.has("tt_topple"):
		topple_walls()
	if p.skill == "slam" and tree.has("kt_curse"):
		var any_cursed = false
		for f in foes:
			if p.hit.has(f.id) and f.get("curse", 0.0) > 0.0:
				any_cursed = true
		if any_cursed:
			for f in foes:
				if p.hit.has(f.id) and f.state != "dead":
					curse(f)
	if p.skill == "spin" and tree.has("stoke"):
		var lit = false
		for f in foes:
			if p.hit.has(f.id) and f.get("burn", 0.0) > 0.0:
				lit = true
		if lit:
			for f in foes:
				if p.hit.has(f.id) and f.get("burn", 0.0) <= 0.0:
					mark(f, "burn")
	# a well-timed swing knocks spit out of the air
	for s in shots:
		if s.life > 0.0 and in_arc(a, s.pos - p.pos, 3.0):
			s.life = 0.0
			burst(s.pos + Vector2(0, -18), IVORY, 6, 60.0)
			Sfx.play("parry")
			p.rage = minf(100.0, p.rage + 5.0)
			p.rage_t = 5.0

func foe_h(f: Dictionary) -> float:
	return Art.T[f.kind + "_i"].get_height() * f.get("scale", 1.0)

func hit_foe(f: Dictionary, base: float, big: bool, stop: float, shk: float) -> void:
	var K = D.FOES[f.kind]
	var dmg = base * randf_range(0.9, 1.1) * dmg_mult(f)
	var crit = p.sure_crit or (stats.crit > 0.0 and randf() < stats.crit / 100.0)
	if crit and has_uniq("salt") and f.state != "dead":
		mark(f, "chill")
	if crit:
		dmg *= 2.0 + 0.1 * tree.get("vital", 0)
	if warded(f) and not (tree.has("pq_purge") and p.state == "atk" and p.skill == "exec"):
		dmg *= 0.5
	f.hp -= dmg
	if p.debt:
		p.debt = false
	if chain_ids.has(f.id) and not sharing:
		# soul chain: a third of the damage is shared with the other linked foes, and never passed on again
		sharing = true
		for o in foes:
			if o != f and chain_ids.has(o.id) and o.state != "dead" and o.state != "spawn":
				o.hp -= dmg * 0.3
				o.flash = F
				if o.hp <= 0.0:
					kill(o)
		sharing = false
	if uses_souls() and K.get("big", false):
		# a boss gives up a soul for every tenth of its life
		var step10 = int(ceil(10.0 * maxf(f.hp, 0.0) / f.mhp))
		if step10 < f.get("soul_step", 10):
			f.soul_step = step10
			add_soul(1)
	if tree.has("kt_shroud"):
		p.hp = minf(stats.mhp, p.hp + dmg * 0.02 * p.souls)
	f.flash = F * 1.5
	var d = f.pos - p.pos
	var kd = d.normalized() if d.length() > 1.0 else p.dir
	f.kb = kd * (150.0 if big else 80.0) * (0.35 if K.poise > 0.0 else 1.0)
	if K.get("fixed", false):
		f.kb = Vector2.ZERO
	hitstop = maxf(hitstop, stop)
	shake = maxf(shake, shk)
	nums.append({"pos": f.pos + Vector2(randf_range(-4, 4), -foe_h(f) * 0.75), "txt": str(int(round(dmg))) + ("!" if crit else ""), "life": 0.6, "col": IVORY if not big else Color("ffe9a3")})
	burst(f.pos + Vector2(0, -foe_h(f) * 0.4), foe_col(f.kind), 5 if not big else 9, 70.0 if not big else 110.0)
	Sfx.play("heavy" if big else "hit", 1.0 + p.idx * 0.1)
	p.rage_t = 5.0
	if stats.leech > 0.0:
		p.hp = minf(stats.mhp, p.hp + dmg * stats.leech / 100.0)
	if f.state == "idle" or f.state == "home":
		f.state = "chase"
	if f.hp <= 0.0:
		kill(f)
		return
	if f.state == "wind" and f.get("amber", false) and (big or K.poise <= 0.0):
		# an amber cast can be cut short: any hit on a light foe, a heavy hit on a heavy one
		f.amber = false
		stagger(f, 1.0)
		f.cd = K.cd
		nums.append({"pos": f.pos + Vector2(0, -foe_h(f) - 8), "txt": "NGẮT ĐÒN", "life": 0.9, "col": AMBER})
		Sfx.play("break", 1.3)
		if has_uniq("box"):
			p.hp = minf(stats.mhp, p.hp + stats.mhp * 0.1)
			p.rage = minf(100.0, p.rage + 30.0)
		return
	if K.poise <= 0.0:
		stagger(f, 0.3)
	else:
		if f.get("guard", 0.0) <= 0.0:
			f.poise -= dmg * (2.0 if (p.state == "atk" and p.skill == "slam") else 1.0) * (1.0 + stats.stag / 100.0) * (1.0 + 0.2 * tree.get("hammer", 0) if (p.state == "atk" and p.skill == "bash") else 1.0) * (1.0 + 0.15 * tree.get("pierce", 0) if ranged else 1.0)
		f.poise_t = 1.5
		if f.poise <= 0.0:
			f.poise = K.poise
			stagger(f, 1.2 if K.get("big", false) else 0.9)
			f.guard = 7.0 if K.get("big", false) else 3.0   # no second break right after the first
			Sfx.play("break")
			nums.append({"pos": f.pos + Vector2(0, -foe_h(f)), "txt": "VỠ THẾ", "life": 0.8, "col": Color("ffe9a3")})

func stagger(f: Dictionary, dur: float) -> void:
	f.state = "stun"
	f.st = 0.0
	f.stun = dur

func kill(f: Dictionary) -> void:
	var K = D.FOES[f.kind]
	var elite = f.get("elite", "")
	soul_kill(f)
	hunter_kill(f)
	priest_kill(f)
	if tree.has("pyre") and f.get("burn", 0.0) > 0.0 and not bursting:
		# a burst can kill, but what it kills does not burst again
		bursting = true
		rings.append({"pos": f.pos, "r": 50.0, "life": 0.3, "max": 0.3, "col": Sk.MARK_COL.burn})
		Sfx.play("slam", 1.4)
		for o in foes:
			if o != f and o.state != "dead" and o.state != "spawn" and o.pos.distance_to(f.pos) < 50.0 + o.r:
				hit_foe(o, stats.atk * 1.5, true, 0.05, 2.0)
		bursting = false
	f.state = "dead"
	f.st = 0.0
	hitstop += 0.03
	Sfx.play("die", 0.7 if K.poise > 0.0 else 1.1)
	for i in 10:
		parts.append({"pos": f.pos + Vector2(randf_range(-6, 6), randf_range(-24, 0)), "vel": Vector2(randf_range(-10, 10), randf_range(-40, -15)), "life": 0.7, "max": 0.7, "col": VONG, "g": 0.0, "size": 1 + i % 2})
	give_xp(K.xp * (3 if elite != "" else 1))
	count_kill(f.kind)
	var g = randi_range(K.gold[0], K.gold[1]) * (3 if elite != "" else 1)
	g = int(g * (1.0 + stats.gold / 100.0))
	var coins = clampi(g / 4, 1, 8)
	for i in coins:
		drop(f.pos, "gold", g / coins + (g % coins if i == 0 else 0), null)
	if K.get("big", false) or (elite != "" and randf() < 0.3):
		drop(f.pos, "item", 0, D.random_rune())
	if zone.tier >= 1 and randf() < (0.25 if K.get("big", false) else (0.08 if elite != "" else 0.0)):
		drop(f.pos, "item", 0, D.random_set_piece())
	if D.SIGS.has(f.kind) and randf() < (0.12 if elite != "" else 0.03):
		drop(f.pos, "item", 0, D.sig_item(f.kind))
	if randf() < 0.08 or f.kind == "boss":
		drop(f.pos, "potion", 1, null)
	if randf() < K.loot + 0.06 * zone.get("tide", 0) or elite != "":
		drop(f.pos, "item", 0, D.roll_item(mini(2, zone.tier + (1 if (K.poise > 0.0 or elite != "") else 0))))
	if f.kind == "boss":
		drop(f.pos, "item", 0, D.ferry_oar())
		shake = 4.0
		toast("CHUYẾN PHÀ ĐÃ KẾT THÚC.", VONG)
	if elite != "":
		# the hunt for an elite's unique: the chance climbs until it drops
		if randf() < D.PITY_BASE + D.PITY_STEP * flags.get("pity", 0):
			flags["pity"] = 0
			drop(f.pos, "item", 0, D.elite_unique(elite))
		else:
			flags["pity"] = flags.get("pity", 0) + 1
	if f.get("burn", 0.0) > 0.0 and tree.has("ash"):
		p.rage = minf(100.0, p.rage + 3.0 * tree.ash)
	if tree.has("ont_spread") and f.get("burn", 0.0) > 0.0:
		var nb = foe_near(f.pos, 90.0, [f.id])
		if nb != null:
			mark(nb, "burn")
	if has_uniq("wick") and f.get("burn", 0.0) > 0.0:
		p.hp = minf(stats.mhp, p.hp + stats.mhp * 0.04)
	if elite == "volatile" and f.get("purge", 0.0) <= 0.0:
		# it does not go quietly: step away
		blasts.append({"pos": f.pos, "t": 1.0, "r": 46.0, "dmg": K.dmg * 1.5 * (1.0 + (zone.mult - 1.0) * 0.7)})
		Sfx.play("tele_lo")
	if f.kind == "keeper":
		flags["keeper_dead"] = 1
		for gt in zone.gates:
			blocks.erase(gt.rect)
		drop(f.pos, "item", 0, D.toll_box())
		toast("CỔNG THU PHÍ MỞ RA.", VONG)
		save_game()
	elif zone.respawn:
		dead.append({"kind": f.kind, "pos": f.home, "t": 45.0, "elite": elite})
	if f.kind == "okhab":
		flags["okha_dead"] = 1
		shake = 5.0
		toast("Ô KHA BUÔNG QUẢ LẮC. DƯỚI HỐ, CÓ THỨ GÌ ĐÓ THỨC DẬY.", VONG)
		var fp = f.pos + Vector2(14 * TS, 0)
		for s in zone.spawns:
			if s.kind == "first":
				fp = s.pos
		spawn("first", fp).state = "spawn"
		save_game()
	if f.kind == "first":
		flags["first_dead"] = 1
		shake = 6.0
		clouds.clear()
		toast("TIẾNG ĐẦU TIÊN IM BẶT. MẢNH CHUÔNG TRONG NGỰC BẠN LÀ TIẾNG DUY NHẤT CÒN LẠI.", VONG)
		zone.things.append({"id": "voice", "pos": f.pos + Vector2(0, 30), "h": 60.0})
		save_game()
	if f.kind == "forgemaster":
		flags["forgemaster_dead"] = 1
		drop(f.pos, "item", 0, D.forge_unique())
		shake = 4.0
		toast("BẠCH LÔ BUÔNG BÚA. LÒ RÈN NGUỘI DẦN.", VONG)
		save_game()
	if f.kind == "mold":
		flags["mold_dead"] = 1
		clouds.clear()
		shake = 5.0
		toast("KHUÔN SỐNG VỠ. HÀNG TRĂM TIẾNG BAY RA, TRONG ĐÓ CÓ MỘT TIẾNG BẠN BIẾT.", VONG)
		save_game()
	if f.kind == "admiral":
		flags["admiral_dead"] = 1
		drop(f.pos, "item", 0, D.admiral_unique())
		shake = 4.0
		toast("ĐÔ ĐỐC ĐÃ ĐƯỢC BÁO TIN: HẠM ĐỘI ĐÃ CHẾT.", VONG)
		save_game()
	if f.kind == "mother":
		drop(f.pos, "item", 0, D.seed_unique())
		shake = 4.0
		clouds.clear()
		toast("MẸ RỄ ĐÃ LẶNG.", VONG)

func drop(pos: Vector2, kind: String, n: int, item) -> void:
	drops.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(30, 80), "t": 0.0, "kind": kind, "n": n, "item": item})

func foe_col(kind: String) -> Color:
	match kind:
		"reed": return Color("d9c27a")
		"heron": return Color("c2bbab")
		"boss": return Color("3d4a6a")
	return Color("4b7265")

func burst(pos: Vector2, col: Color, n: int, spd: float) -> void:
	for i in n:
		parts.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(spd * 0.4, spd), "life": 0.3, "max": 0.3, "col": col, "g": 220.0, "size": 1 + i % 2})

func hurt(raw: float) -> void:
	if p.state == "dead":
		return
	if p.inv > 0.0:
		if p.state == "dodge":
			if has_uniq("free") and not p.free:
				p.free = true
				nums.append({"pos": p.pos + Vector2(0, -56), "txt": "KỸ NĂNG KẾ MIỄN PHÍ", "life": 0.9, "col": D.RAR_COL[3]})
			nums.append({"pos": p.pos + Vector2(0, -46), "txt": "NÉ", "life": 0.7, "col": VONG})
			add_cp(1)
			if tree.has("dv_dodge"):
				add_shield(15.0)
			p.rage = minf(100.0, p.rage + 10.0)
			p.rage_t = 5.0
		return
	var dmg = maxf(1.0, raw * (1.2 if (p.cry > 0.0 and not (tree.has("tt_order") and in_cover())) else 1.0) * 60.0 / (60.0 + (stats.def + watch_def() + (3.0 * p.souls if tree.has("kt_shroud") else 0.0) + (3.0 * tree.get("icearmor", 0) if p.icearm > 0.0 else 0.0)) * 4.0))
	dmg *= guard_taken()
	if p.guard > 0.0:
		# a blocked hit: a fifth of the damage, no flinch, and the next strike is doubled
		p.hp -= maxf(1.0, dmg * 0.2)
		p.riposte = 3.0
		p.inv = 0.3
		p.rage = minf(100.0, p.rage + 15.0 * tree.get("counter", 0))
		p.rage_t = 5.0
		if tree.has("charged"):
			p.charged = 3
		if tree.has("coldiron"):
			for o in foes:
				if o.state != "dead" and o.state != "spawn" and o.pos.distance_to(p.pos) < 70.0:
					mark(o, "chill")
		if tree.has("unbroken"):
			p.hp = minf(stats.mhp, p.hp + stats.mhp * 0.05)
		hitstop = maxf(hitstop, 0.05)
		Sfx.play("parry", 0.8)
		nums.append({"pos": p.pos + Vector2(0, -46), "txt": "ĐỠ", "life": 0.7, "col": Color("8fb0d6")})
		if tree.has("kt_proxy") and t >= p.proxy_t and not ghosts.is_empty():
			p.proxy_t = t + 6.0
			sacrifice(ghost_near(p.pos))
		if tree.has("lb_open"):
			add_cp(2)
		if tree.has("ocb_parry") and not p.parry_ext:
			p.parry_ext = true
			p.guard += 0.6
		if tree.has("ocb_iron"):
			p.iron_n = mini(5, p.iron_n + 1)
			p.iron_t = 8.0
		if tree.has("tk_mine") and hitter != null and t >= p.tkmine_t:
			p.tkmine_t = t + 5.0
			place_device("mine", hitter.pos, true)
		if tree.has("kn_block"):
			heal(stats.mhp * 0.04)
			heal_pets(0.04, 80.0)
		if tree.has("tt_block"):
			add_shield(25.0)
		burst(p.pos + p.aim * 10.0 + Vector2(0, -18), Color("cfd6dc"), 6, 80.0)
	else:
		if tree.has("ohv_bulwark") and p.shield >= shield_cap() - 0.5 and dmg < stats.mhp * 0.1:
			dmg = 0.0
		var had = p.shield > 0.0
		dmg = shield_take(dmg)
		if dmg > stats.mhp * 0.2 and tree.has("mv_die") and not ghosts.is_empty() and t >= p.die_t:
			# an echo dies in your place
			p.die_t = t + 10.0
			var gd = ghost_near(p.pos)
			ghosts.erase(gd)
			burst(gd.pos + Vector2(0, -16), VONG, 12, 90.0)
			nums.append({"pos": p.pos + Vector2(0, -56), "txt": "CHẾT THAY", "life": 1.0, "col": VONG})
			dmg = 0.0
		if dmg <= 0.0:
			p.inv = 0.3
			hitstop = maxf(hitstop, 0.03)
			Sfx.play("parry", 1.3)
		else:
			p.hp -= dmg
			p.lastrun = 0
			p.flash = 0.12
			p.inv = 0.5
			shake = maxf(shake, 3.0)
			hitstop = maxf(hitstop, 0.06)
			Sfx.play("hurt")
			nums.append({"pos": p.pos + Vector2(0, -46), "txt": "-" + str(int(round(dmg))), "life": 0.7, "col": Color("ff9a8a")})
			if tree.has("oneshot") and not (tree.has("tl_calm") and blessed()):
				p.focused = false
				p.focus_t = 0.0
			if (p.state == "atk" or p.state == "dash" or p.state == "aim") and not (had and tree.has("stand")) and not (tree.has("tk_armor") and hot()):
				p.state = "idle"
	if p.hp <= 0.0 and p.vow_t > 0.0:
		p.hp = 1.0
		if tree.has("kn_rise"):
			p.rise_t = t + 4.0
	if p.hp <= 0.0 and p.vigil_t > 0.0:
		p.vigil_t = 0.0
		p.hp = stats.mhp * 0.4
		p.inv = 1.0
		burst(p.pos + Vector2(0, -18), Sk.MARK_COL.lit, 20, 120.0)
		nums.append({"pos": p.pos + Vector2(0, -56), "txt": "SỐNG LẠI", "life": 1.2, "col": Sk.MARK_COL.lit})
	if p.hp <= 0.0 and tree.has("gh_cheat") and p.souls >= 3 and t >= p.cheat_t:
		p.cheat_t = t + 60.0
		p.souls -= 3
		p.hp = 1.0
		p.smoke = 2.0
		p.inv = 1.0
		nums.append({"pos": p.pos + Vector2(0, -56), "txt": "THẾ MẠNG", "life": 1.0, "col": VONG})
	if p.hp <= 0.0:
		p.hp = 0.0
		p.state = "dead"
		p.st = 0.0
		p.vel = Vector2.ZERO

# ---------------------------------------------------------------- foes

func update_foes(dt: float) -> void:
	var alive = p.state != "dead"
	for f in foes:
		var K = D.FOES[f.kind]
		f.at += dt
		f.moving = false
		f.st += dt
		f.flash = maxf(0.0, f.flash - dt)
		f.cd -= dt
		if f.get("bite", false):
			if f.kb.length() < 60.0 or f.state == "stun" or f.state == "dead":
				f.bite = false
			elif f.pos.distance_to(p.pos) < f.r + 9.0:
				f.bite = false
				hitter = f
				hurt(K.dmg * (1.0 + (zone.mult - 1.0) * 0.7))
				hitter = null
		if f.state != "dead" and f.state != "spawn" and f.hp <= 0.0:
			kill(f)   # struck down by its own blow (thorns, payback)
			continue
		# marks left by spells
		f.chill = maxf(0.0, f.get("chill", 0.0) - dt)
		f.shock = maxf(0.0, f.get("shock", 0.0) - dt)
		f.taunt = maxf(0.0, f.get("taunt", 0.0) - dt)
		f.hunt = maxf(0.0, f.get("hunt", 0.0) - dt)
		var slow = 0.5 if f.chill > 0.0 else 1.0
		if f.get("root", 0.0) > 0.0:
			f.root = maxf(0.0, f.root - dt)
			slow = 0.0
		if f.get("drag", 0.0) > 0.0:
			f.drag = maxf(0.0, f.drag - dt)
			slow *= 0.7
		if f.get("curse", 0.0) > 0.0:
			if tree.has("otl_wither") and f.state != "dead" and f.state != "spawn":
				f.hp -= stats.atk * 0.2 * dt
			if not tree.has("oneword"):
				f.curse = maxf(0.0, f.curse - dt)
			if tree.has("th_eternal") and f.get("burn", 0.0) > 0.0:
				f.burn = maxf(f.burn, 0.5)
		if f.get("poison", 0) > 0 and f.state != "dead" and f.state != "spawn":
			f.poison_t -= dt
			f.hp -= f.poison * poison_dps() * dt
			if f.poison_t <= 0.0:
				f.poison = 0
			if f.hp <= 0.0:
				kill(f)
				continue
		if f.get("burn", 0.0) > 0.0 and f.state != "dead" and f.state != "spawn":
			f.burn -= dt
			f.hp -= f.burn_dps * dt
			if int(f.at * 8.0) != int((f.at - dt) * 8.0):
				parts.append({"pos": f.pos + Vector2(randf_range(-5, 5), -randf_range(4, 20)), "vel": Vector2(0, -26), "life": 0.35, "max": 0.35, "col": Sk.MARK_COL.burn, "g": 0.0, "size": 2})
			if f.hp <= 0.0:
				kill(f)
				continue
		f.guard = maxf(0.0, f.get("guard", 0.0) - dt)
		if f.kb.length() > 1.0:
			move_actor(f, f.kb * dt, f.r * 0.6)
			f.kb = f.kb.move_toward(Vector2.ZERO, 500.0 * dt)
		if K.poise > 0.0:
			f.poise_t -= dt
			if f.poise_t <= 0.0:
				f.poise = minf(K.poise, f.poise + 10.0 * dt)
		var d = p.pos - f.pos
		var dist = d.length()
		var to = d / dist if dist > 0.01 else Vector2.RIGHT
		if ai(f) == "boss" and f.state != "dead" and f.state != "idle":
			boss_summon(f)
		match f.state:
			"spawn":
				if f.st >= 0.6:
					f.state = "chase"
			"idle":
				f.wt -= dt
				if f.wt <= 0.0:
					f.wt = randf_range(1.5, 4.0)
					f.wdir = Vector2.from_angle(randf() * TAU) if (randf() < 0.55 and f.kind != "boss") else Vector2.ZERO
					if f.pos.distance_to(f.home) > 40.0:
						f.wdir = (f.home - f.pos).normalized()
				if f.wdir != Vector2.ZERO:
					f.moving = true
					f.flip = f.wdir.x < 0.0
					move_actor(f, f.wdir * K.spd * slow * 0.35 * dt, f.r * 0.6)
				if dist < K.aggro and alive and (p.smoke <= 0.0 or K.get("big", false)):
					f.state = "chase"
					f.cd = maxf(f.cd, 0.5)
			"home":
				var hd = f.home - f.pos
				f.hp = minf(f.mhp, f.hp + f.mhp * 0.5 * dt)
				if hd.length() < 8.0:
					f.state = "idle"
				else:
					f.moving = true
					f.flip = hd.x < 0.0
					f.pos += hd.normalized() * K.spd * slow * 1.6 * dt
			"stun":
				if f.st >= f.stun:
					f.state = "chase"
					f.cd = maxf(f.cd, 0.4)
			"chase":
				if p.smoke > 0.0 and not K.get("big", false) and f.get("taunt", 0.0) <= 0.0:
					# lost in the smoke: ordinary foes give up the chase
					f.state = "idle"
					f.wt = 1.0
					f.wdir = Vector2.ZERO
					continue
				if not alive or (f.kind != "boss" and f.pos.distance_to(f.home) > 330.0):
					f.state = "home"
					continue
				f.flip = d.x < 0.0
				var mv = Vector2.ZERO
				if ai(f) == "heron" or ai(f) == "wisp" or ai(f) == "netter" or ai(f) == "sower":
					if dist < 80.0:
						mv = -to
					elif dist > K.range:
						mv = to
					else:
						mv = to.orthogonal() * f.side * 0.4
					if f.cd <= 0.0 and dist < 220.0:
						ranged_pick(f, to, K)
				elif ai(f) == "leech":
					# circles to your side, then lunges in a straight line
					if dist > 76.0:
						mv = to
					else:
						mv = to.orthogonal() * f.side + to * 0.15
					if f.cd <= 0.0 and dist < 90.0:
						f.atk = "dash"
						wind_up(f, to, "tele_mid", K.wind)
				elif ai(f) == "deer":
					# keeps its distance, lowers its antlers, then runs a long straight line
					if dist > 150.0:
						mv = to
					elif f.cd <= 0.0:
						f.atk = "charge"
						wind_up(f, to, "tele_lo", K.wind)
				elif ai(f) == "mother":
					if f.cd <= 0.0:
						mother_pick(f, to)
				elif ai(f) == "keeper":
					if dist > K.range * 0.75:
						mv = to
					if f.cd <= 0.0:
						keeper_pick(f, to, dist, K)
				elif ai(f) == "boss":
					if dist > K.range * 0.75:
						mv = to
					if f.cd <= 0.0:
						boss_pick(f, to, dist, K)
				else:
					if dist > K.range * 0.8:
						mv = to
					elif f.cd <= 0.0:
						f.tpos = f.pos + to * minf(dist, 30.0)
						wind_up(f, to, "tele_lo" if ai(f) == "porter" else "tele_mid", K.wind)
				for o in foes:
					if o == f or o.state == "dead":
						continue
					var sd = f.pos - o.pos
					if sd.length() < f.r + o.r + 2.0 and sd.length() > 0.01:
						mv += sd.normalized() * 0.8
				f.moving = mv.length() > 0.1
				move_actor(f, mv.limit_length(1.0) * K.spd * slow * dt, f.r * 0.6)
			"wind":
				if (ai(f) == "heron" or ai(f) == "wisp" or f.atk == "volley") and f.st < f.wind - 0.25:
					f.dir = to
					f.flip = d.x < 0.0
				if f.st >= f.wind:
					hitter = f
					strike(f, K)
					pets_struck(f, K)
					hitter = null
					f.state = "act"
					f.st = 0.0
			"act":
				if f.st >= 2 * F:
					f.state = "rec"
					f.st = 0.0
			"rec":
				if f.st >= K.rec:
					f.state = "chase"
					f.cd = K.cd
	for i in range(foes.size() - 1, -1, -1):
		if foes[i].state == "dead" and foes[i].st > 0.5:
			foes.remove_at(i)
	# music follows the place, and turns to the boss theme while a big foe is awake
	var big_fight = foes.any(func(o): return D.FOES[o.kind].get("big", false) and o.state != "idle" and o.state != "dead" and o.state != "home")
	Sfx.play_music(3 if big_fight else MUSIC[zone.id])
	# the marsh refills behind you
	for q in dead:
		q.t -= dt
		if q.t <= 0.0 and q.pos.distance_to(p.pos) > 260.0:
			var nf = spawn(q.kind, q.pos)
			nf.state = "spawn"
			if q.get("elite", "") != "":
				make_elite(nf, q.elite)
			q.t = -999.0
	dead = dead.filter(func(q): return q.t > -900.0)

func wind_up(f: Dictionary, to: Vector2, snd: String, dur: float) -> void:
	f.state = "wind"
	f.st = 0.0
	f.dir = to
	f.wind = dur
	Sfx.play(snd)

# The Ferryman: a sweep up close, a slam where you stand, and below half life a spread of lantern fire.
func boss_pick(f: Dictionary, to: Vector2, dist: float, K: Dictionary) -> void:
	var phase2 = f.hp < f.mhp * 0.5
	if phase2 and not f.get("p2", false):
		f.p2 = true   # the first thing he does below half life is the lantern volley
		f.n = 2
	var pick = f.n % (3 if phase2 else 2)
	f.n += 1
	if pick == 0 and dist > K.range:
		pick = 1
	match pick:
		0:
			f.atk = "sweep"
			wind_up(f, to, "tele_mid", 0.8)
		1:
			f.atk = "slam"
			f.tpos = p.pos
			wind_up(f, to, "tele_lo", 1.0)
		2:
			f.atk = "volley"
			wind_up(f, to, "tele_hi", 0.9)

func boss_summon(f: Dictionary) -> void:
	var marks = [0.66, 0.33]
	if f.sum < 2 and f.hp < f.mhp * marks[f.sum]:
		f.sum += 1
		Sfx.play("clap", 0.7)
		toast(D.FOES[f.kind].get("call_text", "KẺ CHẾT ĐUỐI ĐÁP LỜI NGỌN ĐÈN."), VONG)
		for i in 2:
			var q = f.pos + Vector2.from_angle(randf() * TAU) * 60.0
			if free_at(q, 8.0):
				spawn(D.FOES[f.kind].get("summon", "reed"), q).state = "spawn"

func strike(f: Dictionary, K: Dictionary) -> void:
	var dmg = K.dmg * (1.0 + (zone.mult - 1.0) * 0.7)
	if f.get("curse", 0.0) > 0.0:
		dmg *= 1.0 - 0.25 * (2.0 if tree.has("oneword") else 1.0) - (0.1 if tree.has("otl_curse2") else 0.0)
	if f.get("chill", 0.0) > 0.0:
		dmg *= 1.0 - 0.05 * tree.get("bitter", 0)
	if f.get("poison", 0) > 0:
		dmg *= 1.0 - 0.05 * tree.get("infect", 0)
	var d = p.pos - f.pos
	match ai(f):
		"reed":
			if d.length() < 36.0 + 4.0 and (d.length() < 4.0 or absf(rad_to_deg(f.dir.angle_to(d))) <= 50.0):
				hurt(dmg)
			Sfx.play("sw1", 0.7)
		"porter":
			if p.pos.distance_to(f.tpos) < 48.0:
				hurt(dmg)
			slam_fx(f.tpos, 38.0)
		"heron":
			shots.append({"pos": f.pos + f.dir * 16.0, "vel": f.dir * 190.0, "life": 1.6, "dmg": dmg})
			Sfx.play("spit")
		"wisp":
			if f.atk == "heal":
				for o in foes:
					if o.id == f.target and o.state != "dead":
						o.hp = minf(o.mhp, o.hp + o.mhp * 0.35)
						nums.append({"pos": o.pos + Vector2(0, -foe_h(o)), "txt": "HỒI MÁU", "life": 0.8, "col": Color("8fe08a")})
				Sfx.play("orb", 0.6)
			else:
				shots.append({"pos": f.pos + f.dir * 16.0, "vel": f.dir * 170.0, "life": 1.6, "dmg": dmg})
				Sfx.play("spit", 1.3)
		"netter":
			var h0 = p.hp
			if p.pos.distance_to(f.tpos) < 30.0 + 4.0:
				hurt(dmg)
				if p.hp < h0 and p.state != "dead":
					p.slow = 2.0 * (1.0 - 0.25 * tree.get("firm", 0))
					nums.append({"pos": p.pos + Vector2(0, -56), "txt": "DÍNH LƯỚI", "life": 0.9, "col": Color("ff9a8a")})
			Sfx.play("sw3", 0.8)
		"wolf":
			if d.length() < 34.0 + 4.0 and (d.length() < 4.0 or absf(rad_to_deg(f.dir.angle_to(d))) <= 45.0):
				hurt(dmg)
			Sfx.play("sw1", 1.2)
		"sower":
			clouds.append({"pos": f.tpos, "r": 34.0, "t": 4.0, "tick": 0.0, "dmg": dmg * 0.6, "col": Color("e8e4dc") if f.kind == "diver" else Color("c9e36a")})
			Sfx.play("spit", 0.6)
		"deer":
			f.kb = f.dir * 520.0
			f.bite = true
			Sfx.play("dash", 0.6)
		"mother":
			match f.atk:
				"roots":
					for i in f.lines:
						var rd = Vector2.from_angle(f.ang + TAU * i / f.lines)
						var along = d.dot(rd)
						if along > 10.0 and along < 255.0 and absf(d.cross(rd)) < 10.0:
							hurt(dmg)
					slam_fx(f.pos, 60.0)
				"spores":
					for q in f.pods:
						clouds.append({"pos": q, "r": 34.0, "t": 5.0, "tick": 0.0, "dmg": dmg * 0.5, "col": D.FOES[f.kind].get("cloud", Color("c9e36a"))})
					Sfx.play("spit", 0.5)
				"call":
					Sfx.play("clap", 0.5)
					toast(D.FOES[f.kind].get("call_text", "RỪNG NHỚ LẠI BẦY SÓI."), VONG)
					for i in 3:
						var q = f.pos + Vector2.from_angle(randf() * TAU) * 70.0
						if free_at(q, 8.0):
							spawn(D.FOES[f.kind].get("summon", "wolf"), q).state = "spawn"
		"leech":
			f.kb = f.dir * 300.0
			f.bite = true
			Sfx.play("dash", 0.8)
		"keeper":
			match f.atk:
				"sweep":
					if d.length() < 66.0 + 4.0 and (d.length() < 6.0 or absf(rad_to_deg(f.dir.angle_to(d))) <= 55.0):
						hurt(dmg)
					Sfx.play("sw3", 0.5)
				"slam":
					if p.pos.distance_to(f.tpos) < 50.0:
						hurt(dmg * 1.2)
					slam_fx(f.tpos, 42.0)
				"call":
					f.hp = minf(f.mhp, f.hp + f.mhp * 0.12)
					nums.append({"pos": f.pos + Vector2(0, -foe_h(f)), "txt": D.FOES[f.kind].get("heal_text", "ĐÃ THU PHÍ"), "life": 1.0, "col": Color("8fe08a")})
					Sfx.play("clap", 0.6)
					if foes.size() < 6:
						for i in 2:
							var q = f.pos + Vector2.from_angle(randf() * TAU) * 56.0
							if free_at(q, 8.0):
								spawn(D.FOES[f.kind].get("summon", "reed"), q).state = "spawn"
		"boss":
			match f.atk:
				"sweep":
					if d.length() < 74.0 + 4.0 and (d.length() < 6.0 or absf(rad_to_deg(f.dir.angle_to(d))) <= 60.0):
						hurt(dmg)
					Sfx.play("sw3", 0.6)
					shake = maxf(shake, 2.0)
				"slam":
					if p.pos.distance_to(f.tpos) < 56.0:
						hurt(dmg * 1.2)
					slam_fx(f.tpos, 46.0)
				"volley":
					for a in [-0.32, 0.0, 0.32]:
						var dir = f.dir.rotated(a)
						shots.append({"pos": f.pos + dir * 20.0, "vel": dir * 170.0, "life": 2.0, "dmg": dmg * 0.6})
					Sfx.play("spit", 0.7)

func slam_fx(at: Vector2, r: float) -> void:
	shake = maxf(shake, 2.5)
	Sfx.play("slam")
	for i in 14:
		var a = TAU * i / 14.0
		parts.append({"pos": at + Vector2.from_angle(a) * r, "vel": Vector2.from_angle(a) * 40.0 + Vector2(0, -30), "life": 0.4, "max": 0.4, "col": Color("8d7c5e"), "g": 160.0, "size": 2})

func update_shots(dt: float) -> void:
	for s in shots:
		s.pos += s.vel * dt * (0.5 if in_mute(s.pos) else 1.0)
		if tree.has("pl_ring"):
			for fd in fields:
				if fd.kind == "cover" and s.pos.distance_to(fd.pos) < fd.r and fields.any(func(o): return o.kind == "mute" and o.pos.distance_to(fd.pos) < o.r + fd.r):
					s.life = 0.0
		for fd in fields:
			if fd.kind == "wall" and fd.rect.has_point(s.pos):
				s.life = 0.0
		s.life -= dt
		if s.life > 0.0 and s.pos.distance_to(p.pos) < 7.0 and p.state != "dead":
			hurt(s.dmg)
			s.life = 0.0
	shots = shots.filter(func(s): return s.life > 0.0)
	for w in waves:
		w.pos += w.vel * dt
		w.life -= dt
		for f in foes:
			if f.state != "dead" and f.state != "spawn" and not w.hit.has(f.id) and f.pos.distance_to(w.pos) < 14.0 + f.r:
				w.hit.append(f.id)
				hit_foe(f, stats.atk * 1.2, false, 0.03, 1.0)
	waves = waves.filter(func(w): return w.life > 0.0)
	# spore clouds: stay out, or be hurt twice a second
	for cl in clouds:
		cl.t -= dt
		cl.tick -= dt
		if cl.tick <= 0.0:
			cl.tick = 0.5
			if p.pos.distance_to(cl.pos) < cl.r:
				hurt(cl.dmg)
			for i in 3:
				parts.append({"pos": cl.pos + Vector2.from_angle(randf() * TAU) * randf() * cl.r, "vel": Vector2(0, -14), "life": 0.6, "max": 0.6, "col": cl.get("col", Color("c9e36a")), "g": 0.0, "size": 2})
	clouds = clouds.filter(func(cl): return cl.t > 0.0)
	for b in blasts:
		b.t -= dt
		if b.t <= 0.0:
			if p.pos.distance_to(b.pos) < b.r:
				hurt(b.dmg)
			slam_fx(b.pos, b.r * 0.8)
	blasts = blasts.filter(func(b): return b.t > 0.0)
	ranged = true
	for b in bolts:
		b.pos += b.vel * dt
		b.life -= dt
		if int(b.life / 0.04) != int((b.life + dt) / 0.04):
			parts.append({"pos": b.pos + Vector2(0, -16), "vel": Vector2.ZERO, "life": 0.2, "max": 0.2, "col": IVORY if (b.get("arrow", false) or b.get("dev", false) or b.get("shot", false)) else Sk.MARK_COL.burn, "g": 0.0, "size": 2})
		for f in foes:
			if b.get("shot", false):
				if b.life > 0.0 and not b.hit.has(f.id) and f.state != "dead" and f.state != "spawn" and f.pos.distance_to(b.pos) < f.r + 7.0:
					b.hit.append(f.id)
					if not b.pierce:
						b.life = 0.0
					shot_hit(f, b)
				continue
			if b.get("dev", false):
				if b.life > 0.0 and f.state != "dead" and f.state != "spawn" and f.pos.distance_to(b.pos) < f.r + 7.0:
					b.life = 0.0
					dev_bolt_hit(f, b)
				continue
			if b.get("arrow", false):
				if not b.hit.has(f.id) and f.state != "dead" and f.state != "spawn" and f.pos.distance_to(b.pos) < f.r + 8.0:
					b.hit.append(f.id)
					arrow_hit(f, b)
				continue
			if b.get("ice", false):
				# an ice shard goes through everything, hitting each foe once; a foe already chilled freezes
				if not b.hit.has(f.id) and f.state != "dead" and f.state != "spawn" and f.pos.distance_to(b.pos) < f.r + 8.0:
					b.hit.append(f.id)
					var cold = f.get("chill", 0.0) > 0.0
					hit_foe(f, stats.atk * b.mult, false, 0.03, 1.0)
					if f.state != "dead":
						if cold and not D.FOES[f.kind].get("big", false):
							stagger(f, 1.0)
						mark(f, "chill")
				continue
			if b.life > 0.0 and f.state != "dead" and f.state != "spawn" and f.pos.distance_to(b.pos) < f.r + 7.0:
				b.life = 0.0
				hit_foe(f, stats.atk * b.get("mult", 1.2), false, 0.03, 1.0)
				if b.get("dart", false):
					poison(f, 2 if tree.has("ost_dart") else 1)
				else:
					mark(f, "burn")
				burst(f.pos + Vector2(0, -16), Sk.MARK_COL.burn, 8, 90.0)
	ranged = false
	bolts = bolts.filter(func(b): return b.life > 0.0)
	for fd in fields:
		fd.t -= dt
		fd.tick -= dt
		var beat = fd.tick <= 0.0
		if beat:
			fd.tick = 0.5
		if fd.kind == "holy" or fd.kind == "mute":
			continue
		if fd.kind == "rain" or fd.kind == "pool":
			if beat:
				rain_tick(fd)
			continue
		for f in foes:
			if f.state == "dead" or f.state == "spawn":
				continue
			if fd.kind == "fire":
				if Geometry2D.get_closest_point_to_segment(f.pos, fd.a, fd.b).distance_to(f.pos) < f.r + 8.0 and f.get("burn", 0.0) < 1.0:
					mark(f, "burn")
			elif fd.kind == "wall":
				if fd.get("fire", false) and fd.rect.grow(f.r + 4.0).has_point(f.pos) and f.get("burn", 0.0) < 1.0:
					mark(f, "burn")
			elif fd.kind == "cover":
				if tree.has("mv_ring") and f.pos.distance_to(fd.pos) < fd.r + f.r:
					f.curse = maxf(f.get("curse", 0.0), 4.0)
			elif f.pos.distance_to(fd.pos) < fd.r + f.r:
				f.shock = maxf(f.get("shock", 0.0), 0.6)
				if beat:
					f.hp -= stats.atk * 0.15 * fd.mult * dmg_mult(f)
					f.flash = F
					if f.state == "idle":
						f.state = "chase"
					if f.hp <= 0.0:
						kill(f)
	for fd in fields:
		if fd.kind == "wall" and fd.t <= 0.0:
			blocks.erase(fd.rect)
	fields = fields.filter(func(fd): return fd.t > 0.0)
	for pu in pulses:
		pu.t -= dt
		if pu.t <= 0.0:
			rings.append({"pos": pu.pos, "r": pu.get("r", 60.0), "life": 0.35, "max": 0.35, "col": Sk.MARK_COL[pu.kind]})
			Sfx.play("slam", 1.3)
			shake = maxf(shake, 2.5)
			for f in foes:
				if f.state != "dead" and f.state != "spawn" and f.pos.distance_to(pu.pos) < pu.get("r", 60.0) + f.r:
					hit_foe(f, stats.atk * (2.4 if tree.has("ls_eye") else 2.0), true, 0.05, 2.0)
					mark(f, pu.kind)
	pulses = pulses.filter(func(pu): return pu.t > 0.0)
	for r in rings:
		r.life -= dt
	rings = rings.filter(func(r): return r.life > 0.0)
	for z in zaps:
		z.life -= dt
	zaps = zaps.filter(func(z): return z.life > 0.0)

func update_fx(dt: float) -> void:
	for q in parts:
		q.life -= dt
		q.vel.y += q.g * dt
		q.pos += q.vel * dt
	parts = parts.filter(func(q): return q.life > 0.0)
	for n in nums:
		n.life -= dt
		n.pos.y -= 22.0 * dt
	nums = nums.filter(func(n): return n.life > 0.0)
	for o in drops:
		o.t += dt
		var d = p.pos - o.pos
		if o.t < 0.4 or p.state == "dead":
			o.pos += o.vel * dt
			o.vel = o.vel.move_toward(Vector2.ZERO, 220.0 * dt)
		elif o.kind == "item":
			if d.length() < 14.0 and o.item.rar >= loot_filter:
				if inv.size() < BAG:
					inv.append(o.item)
					toast("NHẶT ĐƯỢC " + o.item.name, D.RAR_COL[o.item.rar])
					Sfx.play("orb", 0.6 if o.item.rar >= 2 else 1.0)
					o.t = -1.0
				elif warn_t <= 0.0:
					warn_t = 2.5
					toast("TÚI ĐẦY", Color("ff9a8a"))
		elif d.length() < 70.0:
			o.pos += d.normalized() * minf(d.length(), (80.0 + o.t * 260.0) * dt)
			if d.length() < 8.0:
				o.t = -1.0
				if o.kind == "gold":
					gold += o.n
				else:
					potions += 1
					toast("NHẶT ĐƯỢC BÌNH MÁU", Color("8fe08a"))
				Sfx.play("orb")
	drops = drops.filter(func(o): return o.t >= 0.0)

# ---------------------------------------------------------------- draw

func _draw() -> void:
	var view = get_viewport_rect().size
	draw_set_transform(-cam_tl)
	draw_texture(maps[zone.id][int(t * 1.5) % 2], Vector2.ZERO)
	for po in zone.portals:
		var open = po.need == "" or qs.has(po.need)
		var c = po.rect.get_center()
		Txt.ctext(self, Vector2(clampf(c.x, 60.0, zone.w * TS - 60.0), clampf(c.y - 30.0 + sin(t * 3.0) * 2.0, 12.0, zone.h * TS - 20.0)), po.label, IVORY if open else Color("8c8577"))
	for f in foes:
		if f.state == "wind":
			var k = clampf(f.st / f.wind, 0.0, 1.0)
			match ai(f):
				"reed": tele(cone_pts(f.pos, f.dir, 36.0, 50.0), f.pos, k)
				"porter": tele(circle_pts(f.tpos, 48.0), f.tpos, k)
				"heron": tele(line_pts(f.pos + f.dir * 12.0, f.dir, 210.0, 3.0), f.pos + f.dir * 12.0, k)
				"leech": tele(line_pts(f.pos, f.dir, 96.0, 6.0), f.pos, k)
				"netter": tele(circle_pts(f.tpos, 30.0), f.tpos, k)
				"wolf": tele(cone_pts(f.pos, f.dir, 34.0, 45.0), f.pos, k)
				"sower": tele(circle_pts(f.tpos, 34.0), f.tpos, k)
				"deer": tele(line_pts(f.pos, f.dir, 250.0, 11.0), f.pos, k)
				"mother":
					match f.atk:
						"roots":
							for i in f.lines:
								var rd = Vector2.from_angle(f.ang + TAU * i / f.lines)
								tele(line_pts(f.pos + rd * 20.0, rd, 230.0, 8.0), f.pos + rd * 20.0, k)
						"spores":
							for q in f.pods:
								tele(circle_pts(q, 34.0), q, k)
						"call": amber(f, k)
				"wisp":
					if f.atk == "heal":
						amber(f, k)
					else:
						tele(line_pts(f.pos + f.dir * 12.0, f.dir, 210.0, 3.0), f.pos + f.dir * 12.0, k)
				"keeper":
					match f.atk:
						"sweep": tele(cone_pts(f.pos, f.dir, 66.0, 55.0), f.pos, k)
						"slam": tele(circle_pts(f.tpos, 50.0), f.tpos, k)
						"call": amber(f, k)
				"boss":
					match f.atk:
						"sweep": tele(cone_pts(f.pos, f.dir, 74.0, 60.0), f.pos, k)
						"slam": tele(circle_pts(f.tpos, 56.0), f.tpos, k)
						"volley":
							for a in [-0.32, 0.0, 0.32]:
								var dir = f.dir.rotated(a)
								tele(line_pts(f.pos + dir * 16.0, dir, 240.0, 3.0), f.pos + dir * 16.0, k)
	for cl in clouds:
		tele(circle_pts(cl.pos, cl.r), cl.pos, 1.0)
	for b in blasts:
		tele(circle_pts(b.pos, b.r), b.pos, 1.0 - b.t)
	for gt in zone.gates:
		if not flags.has(gt.flag):
			var gc = gt.rect.get_center()
			var ft: Texture2D = Art.T["fence"]
			draw_texture(ft, (gc - Vector2(ft.get_width() / 2.0, ft.get_height() - 10)).floor())
			Txt.ctext(self, gc + Vector2(0, -34), "NIÊM PHONG", Color("8c8577"))
	var items = []
	var vr = Rect2(cam_tl - Vector2(80, 120), view + Vector2(160, 240))
	for dc in zone.decor:
		if vr.has_point(dc.pos):
			items.append([dc.pos.y, 0, dc])
	for n in zone.npcs:
		items.append([n.pos.y, 3, n])
	for f in foes:
		items.append([f.pos.y, 1, f])
	for o in drops:
		items.append([o.pos.y - 1.0, 4, o])
	items.append([p.pos.y, 2, p])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		match it[1]:
			0:
				var tx: Texture2D = Art.T[it[2].tex]
				draw_texture(tx, (it[2].pos - Vector2(tx.get_width() / 2.0, tx.get_height() - 2)).floor())
			1: draw_foe(it[2])
			2: draw_player()
			3: draw_npc(it[2])
			4: draw_drop(it[2])
	for s in shots:
		draw_texture(Art.T["shadow"], (s.pos - Vector2(8, 3)).floor(), Color(1, 1, 1, 0.6))
		draw_texture(Art.T["spit"], (s.pos - Vector2(4, 22)).floor())
	draw_hunter()
	draw_artificer()
	for gh in ghosts:
		var gt: Texture2D = Art.T["wolf_i"] if (tree.has("hl_wolf") and Art.T.has("wolf_i")) else Art.W["h_idle"]
		var gc = Sk.MARK_COL[gh.el] if gh.el != "" else VONG
		draw_texture_rect(gt, Rect2(floor(gh.pos.x - gt.get_width() / 2.0), floor(gh.pos.y - gt.get_height() + 3 + sin(t * 5.0 + gh.pos.x) * 1.5), -gt.get_width() if gh.flip else gt.get_width(), gt.get_height()), false, Color(gc.r, gc.g, gc.b, 0.4 if gh.t > 2.0 else 0.2))
	var linked = foes.filter(func(o): return chain_ids.has(o.id) and o.state != "dead")
	for i in range(1, linked.size()):
		draw_line(linked[i - 1].pos + Vector2(0, -12), linked[i].pos + Vector2(0, -12), Sk.MARK_COL.curse, 1.0)
	for b in bolts:
		if b.get("arrow", false) or b.get("shot", false):
			var ad: Vector2 = b.vel.normalized()
			draw_line(b.pos + Vector2(0, -16) - ad * 9.0, b.pos + Vector2(0, -16), Color("8a6a42"), 2.0)
			draw_line(b.pos + Vector2(0, -16) - ad * 3.0, b.pos + Vector2(0, -16) + ad * 2.0, IVORY, 2.0)
			continue
		if b.get("dev", false):
			var dc = Sk.MARK_COL[b.el] if b.get("el", "") != "" else Color("e0b04a")
			draw_rect(Rect2((b.pos + Vector2(-1, -17)).floor(), Vector2(3, 3)), dc)
			continue
		draw_rect(Rect2((b.pos + Vector2(-3, -19)).floor(), Vector2(6, 6)), Sk.MARK_COL.poison if b.get("dart", false) else (Sk.MARK_COL.chill if b.get("ice", false) else Sk.MARK_COL.burn))
		draw_rect(Rect2((b.pos + Vector2(-1, -17)).floor(), Vector2(2, 2)), Color("ffe9a3"))
	for fd in fields:
		if fd.kind == "fire":
			for i in 12:
				var fp: Vector2 = fd.a.lerp(fd.b, i / 11.0)
				var fh = 6 + int(absf(sin(t * 9.0 + i * 1.7)) * 8.0)
				draw_rect(Rect2(floor(fp.x) - 3, floor(fp.y) - fh, 6, fh), Sk.MARK_COL.burn)
				draw_rect(Rect2(floor(fp.x) - 1, floor(fp.y) - fh / 2, 2, fh / 2), Color("ffe9a3"))
		elif fd.kind == "cage":
			draw_arc(fd.pos + Vector2(0, -4), fd.r, 0.0, TAU, 32, Sk.MARK_COL.shock, 1.0)
			for i in 3:
				var za = t * 5.0 + i * 2.1
				draw_line(fd.pos + Vector2.from_angle(za) * fd.r, fd.pos + Vector2.from_angle(za + 2.4) * fd.r, Color(1, 1, 1, 0.7), 1.0)
		elif fd.kind == "wall":
			var wr: Rect2 = fd.rect
			var wc = Sk.MARK_COL.burn if fd.get("fire", false) else Color("c9b98a")
			draw_rect(Rect2(wr.position + Vector2(0, -14), wr.size + Vector2(0, 14)), Color(0.18, 0.16, 0.13, 0.9))
			draw_rect(Rect2(wr.position + Vector2(1, -13), wr.size + Vector2(-2, 12)), Color(wc.r, wc.g, wc.b, 0.75 if fd.t > 1.0 else 0.4))
			draw_rect(Rect2(wr.position + Vector2(1, -13), Vector2(wr.size.x - 2, 2)), Color("f4ebd0"))
		elif fd.kind == "cover":
			var cc = Color("e0b04a")
			draw_arc(fd.pos + Vector2(0, -4), fd.r, 0.0, TAU, 40, Color(cc.r, cc.g, cc.b, 0.8 if fd.t > 1.0 else 0.4), 1.0)
			draw_arc(fd.pos + Vector2(0, -4), fd.r - 3.0, t * 2.0, t * 2.0 + 1.2, 10, Color(cc.r, cc.g, cc.b, 0.6), 1.0)
			draw_arc(fd.pos + Vector2(0, -4), fd.r - 3.0, t * 2.0 + PI, t * 2.0 + PI + 1.2, 10, Color(cc.r, cc.g, cc.b, 0.6), 1.0)
	for pu in pulses:
		draw_arc(pu.pos + Vector2(0, -4), pu.get("r", 60.0), 0.0, TAU, 32, Sk.MARK_COL[pu.kind], 1.0)
	for r in rings:
		var rk = 1.0 - r.life / r.max
		draw_arc(r.pos + Vector2(0, -6), r.r * (0.3 + 0.7 * rk), 0.0, TAU, 32, Color(r.col.r, r.col.g, r.col.b, 1.0 - rk * 0.8), 3.0)
	for z in zaps:
		var zm = (z.a + z.b) / 2.0 + (z.b - z.a).orthogonal().normalized() * 6.0
		var zp = PackedVector2Array([z.a, zm, z.b])
		draw_polyline(zp, Sk.MARK_COL.shock, 3.0)
		draw_polyline(zp, Color.WHITE, 1.0)
	for w in waves:
		draw_arc_fx(w.pos - w.vel.normalized() * 14.0 + Vector2(0, -14), w.vel.angle() - 0.9, w.vel.angle() + 0.9, 18.0, clampf(w.life * 3.0, 0.0, 1.0))
	for q in parts:
		var c: Color = q.col
		c.a = clampf(q.life / q.max * 1.5, 0.0, 1.0)
		draw_rect(Rect2(q.pos.floor(), Vector2(q.size, q.size)), c)
	for n in nums:
		if opt.nums:
			Txt.ctext(self, n.pos, n.txt, Color(n.col.r, n.col.g, n.col.b, clampf(n.life * 3.0, 0.0, 1.0)))
	if mode == "talk" and talk.has("ghost"):
		var gt: Texture2D = Art.W["h_idle"]
		draw_texture(gt, (talk.ghost - Vector2(gt.get_width() / 2.0, gt.get_height() - 3)).floor(), Color(VONG.r, VONG.g, VONG.b, 0.45 + 0.2 * sin(t * 9.0)))
	var near = near_target()
	if near != null and mode == "play":
		Txt.ctext(self, near.pos + Vector2(0, -near.h), near.name, Color("ffe9a3"))
		Txt.ctext(self, near.pos + Vector2(0, -near.h + 10), "E: NÓI CHUYỆN" if near.kind == "npc" else "E: XEM", IVORY)
	draw_set_transform(Vector2.ZERO)
	if zone.dark:
		draw_rect(Rect2(Vector2.ZERO, view), Color(0.03, 0.06, 0.16, 0.34))
	draw_set_transform(-cam_tl)
	for lp in zone.lanterns:
		draw_texture(Art.T["glow"], lp - Vector2(48, 30))
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(Art.T["vignette"], Rect2(Vector2.ZERO, view), false)
	for m in motes:
		var ma = 0.25 + 0.2 * sin(t * 2.0 + m.ph)
		draw_rect(Rect2(m.pos.floor(), Vector2(1, 1)), Color(VONG.r, VONG.g, VONG.b, ma) if zone.dark else Color(0.96, 0.92, 0.82, ma))
	if mode != "title" and mode != "create":
		Ui.hud(self, view)
		Touch.draw(self, view)
	if mode == "talk":
		if talk.get("story", false):
			Menu.story(self, view)
		else:
			Ui.talk_box(self, view)
	elif mode == "inv":
		Ui.inv_draw(self, view)
	elif mode == "tree":
		Ui.tree_draw(self, view)
	elif Menu.MODES.has(mode):
		Menu.draw(self, view)
	elif mode == "fade":
		draw_rect(Rect2(Vector2.ZERO, view), Color(0.04, 0.03, 0.07, 1.0 - absf(fade_t - 0.25) / 0.25))

func cone_pts(o: Vector2, dir: Vector2, r: float, half: float) -> PackedVector2Array:
	var pts = PackedVector2Array([o])
	var a0 = dir.angle() - deg_to_rad(half)
	for i in 13:
		pts.append(o + Vector2.from_angle(a0 + deg_to_rad(half * 2.0) * i / 12.0) * r)
	return pts

func circle_pts(o: Vector2, r: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in 28:
		pts.append(o + Vector2.from_angle(TAU * i / 28.0) * r)
	return pts

func line_pts(o: Vector2, dir: Vector2, length: float, hw: float) -> PackedVector2Array:
	var n = dir.orthogonal() * hw
	return PackedVector2Array([o + n, o + dir * length + n, o + dir * length - n, o - n])

# Vermilion ground warning: full outline at once, the fill grows until the blow lands.
func tele(pts: PackedVector2Array, origin: Vector2, k: float) -> void:
	draw_colored_polygon(pts, Color(RED.r, RED.g, RED.b, 0.16))
	if k > 0.05:
		var inner = PackedVector2Array()
		for q in pts:
			inner.append(origin + (q - origin) * k)
		draw_colored_polygon(inner, Color(RED.r, RED.g, RED.b, 0.30))
	var edge = pts.duplicate()
	edge.append(pts[0])
	var late = k > 0.75 and int(t * 20.0) % 2 == 0
	draw_polyline(edge, Color.WHITE if late else RED, 1.0)

func draw_npc(n: Dictionary) -> void:
	var tex: Texture2D = Art.T[D.NPCS[n.id].tex]
	var w = tex.get_width()
	var h = tex.get_height()
	var squash = 1 if int(t * 2.0 + n.pos.x) % 2 == 0 else 0
	draw_texture_rect(Art.T["shadow"], Rect2(n.pos.x - 10, n.pos.y - 3, 20, 7), false)
	draw_texture_rect(tex, Rect2(floor(n.pos.x - w / 2.0), floor(n.pos.y - h + 3 + squash), w, h - squash), false)
	# a mark over the quest giver when she has something to say
	var mk = npc_mark(n.id)
	if mk != "":
		Txt.ctext(self, n.pos + Vector2(0, -h - 10 + sin(t * 4.0) * 2.0), mk, Color("ffe9a3"), 2)

func draw_drop(o: Dictionary) -> void:
	var bob = sin(t * 6.0 + o.pos.x) * 1.5
	match o.kind:
		"gold": draw_texture(Art.T["coin"], (o.pos - Vector2(3, 6 + bob)).floor())
		"potion": draw_texture(Art.T["potion"], (o.pos - Vector2(3, 9 + bob)).floor())
		"item":
			var col: Color = D.RAR_COL[o.item.rar]
			if o.item.rar < loot_filter:
				# below the filter: left on the ground, drawn faint, no label
				draw_texture(Art.T["bag"], (o.pos - Vector2(5, 11)).floor(), Color(1, 1, 1, 0.3))
			else:
				draw_texture(Art.T["shadow"], (o.pos - Vector2(8, 3)).floor(), Color(1, 1, 1, 0.7))
				draw_texture(Art.T["bag"], (o.pos - Vector2(5, 11 + bob)).floor(), col.lerp(Color.WHITE, 0.35))
				Txt.ctext(self, o.pos + Vector2(0, -24), o.item.name, col)

# Characters are single still pictures. Everything that moves is done here:
# breathing, a hop while walking, a shiver before a blow, a lunge with it.
func draw_foe(f: Dictionary) -> void:
	var K = D.FOES[f.kind]
	var fr = "i"
	if f.state == "wind":
		fr = "w"
	elif f.state == "act" or (f.state == "rec" and f.st < 0.15):
		fr = "k"
	var name = f.kind + "_" + fr
	var tex: Texture2D = Art.T[name]
	var w = tex.get_width()
	var h = tex.get_height()
	var sc = f.get("scale", 1.0)
	w = int(w * sc)
	h = int(h * sc)
	var heavy = K.poise > 0.0
	var lift = 0.0
	var squash = 0
	if fr == "i":
		if f.moving:
			lift = absf(sin(f.at * (6.0 if heavy else 9.0))) * (2.0 if heavy else 3.0)
		elif int(f.at * 2.5) % 2 == 0:
			squash = 1
	var pos = Vector2(f.pos.x - w / 2.0, f.pos.y - h + 3 - lift + squash)
	if f.state == "stun":
		pos.x += sin(f.st * 60.0) * 1.0
	elif f.state == "wind":
		pos.x += sin(f.st * 50.0) * (0.6 + f.st)
	elif fr == "k":
		pos += f.dir * 3.0
	var col = Color.WHITE
	if f.get("chill", 0.0) > 0.0:
		col = Color(0.72, 0.9, 1.0)
	if f.state == "dead":
		tex = Art.W[name]
		col = Color(VONG.r, VONG.g, VONG.b, 1.0 - f.st / 0.5)
		pos.y -= f.st * 12.0
	elif f.state == "spawn":
		tex = Art.W[name]
		col = Color(VONG.r, VONG.g, VONG.b, f.st / 0.6)
	elif f.flash > 0.0 and opt.flash:
		tex = Art.W[name]
	if f.state != "dead":
		if f.get("elite", "") == "warding":
			draw_arc(f.pos + Vector2(0, -4), 110.0, 0.0, TAU, 48, Color(0.72, 0.78, 1.0, 0.22 + 0.08 * sin(t * 4.0)), 1.0)
		var sw = f.r * 2.6
		draw_texture_rect(Art.T["shadow"], Rect2(f.pos.x - sw / 2.0, f.pos.y - 3, sw, 7), false)
	draw_texture_rect(tex, Rect2(pos.floor(), Vector2(-w if f.flip else w, h - squash)), false, col)
	if f.state != "dead":
		var mx = f.pos.x - 7.0
		for mk in ["burn", "chill", "shock", "poison", "curse", "taunt", "hunt", "root", "lit"]:
			if f.get(mk, 0.0) > 0.0:
				var up = 1 if (mk == "burn" and int(t * 10.0) % 2 == 0) else 0
				draw_texture(Art.T["mk_" + mk], Vector2(floor(mx) - 1, floor(f.pos.y - foe_h(f) - 11 - up)))
				mx += 7.0
	if (f.hp < f.mhp or f.get("elite", "") != "") and f.state != "dead" and not K.get("big", false):
		var bw = 16.0 if not heavy else 28.0
		var bp = Vector2(f.pos.x - bw / 2.0, f.pos.y - foe_h(f) - 3).floor()
		draw_rect(Rect2(bp - Vector2(1, 1), Vector2(bw + 2, 4)), Color("1a1420"))
		draw_rect(Rect2(bp, Vector2(bw * f.hp / f.mhp, 2)), Color("d9c27a"))
	if f.get("elite", "") != "" and f.state != "dead":
		Txt.ctext(self, Vector2(f.pos.x, f.pos.y - foe_h(f) - 22), D.ELITE[f.elite].name, D.ELITE[f.elite].col)

func draw_arc_fx(o: Vector2, a0: float, a1: float, r: float, alpha: float) -> void:
	if absf(a1 - a0) < 0.15:
		return
	var n = maxi(10, int(r / 3.0))
	var outer = PackedVector2Array()
	var inner = PackedVector2Array()
	for i in n + 1:
		var k = float(i) / n
		var a = lerpf(a0, a1, k)
		outer.append(o + Vector2.from_angle(a) * r)
		inner.append(o + Vector2.from_angle(a) * (r - 2.0 - 8.0 * sin(PI * k)))
	inner.reverse()
	outer.append_array(inner)
	draw_colored_polygon(outer, Color(IVORY.r, IVORY.g, IVORY.b, 0.75 * alpha))

# ---------------------------------------------------------------- talk, quests, things to look at

func main_done() -> int:
	var n = 0
	for id in D.ORDER:
		if D.QUESTS[id].main and qs.get(id, "") == "done":
			n += 1
	return n

func q_open(id: String) -> bool:
	if qs.has(id):
		return false
	for a in D.QUESTS[id].after:
		if qs.get(a, "") != "done":
			return false
	return true

func q_ender(id: String) -> String:
	var Q = D.QUESTS[id]
	return Q.get("ender", Q.giver)

# "?" someone is waiting for you, "!" someone has work
func npc_mark(npc: String) -> String:
	for id in D.ORDER:
		var st = qs.get(id, "")
		if (st == "ready" and q_ender(id) == npc) or (st == "active" and D.QUESTS[id].need.get("talk", "") == npc):
			return "?"
	for id in D.ORDER:
		if q_open(id) and D.QUESTS[id].giver == npc and not D.QUESTS[id].get("auto", false):
			return "!"
	return ""

func needs_met(id: String, talking: bool) -> bool:
	var need = D.QUESTS[id].need
	var c = qc.get(id, {})
	for k in need.get("kill", {}):
		if c.get(k, 0) < need.kill[k]:
			return false
	if need.has("loot") and c.get("loot", 0) < need.loot[1]:
		return false
	for s in need.get("see", []):
		if not flags.has("seen_" + s):
			return false
	if need.has("talk") and not talking:
		return false
	return true

func refresh_quests() -> void:
	for id in D.ORDER:
		if qs.get(id, "") == "active" and needs_met(id, false):
			qs[id] = "ready"
			toast("XONG NHIỆM VỤ. QUAY VỀ GẶP %s." % D.NPCS[q_ender(id)].name, Color("ffe9a3"))
			Sfx.play("break", 1.6, -4.0)

func accept(id: String) -> void:
	qs[id] = "active"
	qc[id] = {}
	toast("NHIỆM VỤ: " + D.QUESTS[id].name, Color("ffe9a3"))
	refresh_quests()

func turnin(id: String) -> void:
	var Q = D.QUESTS[id]
	var R = Q
	if Q.has("branch"):
		R = Q.reward[flags.get(Q.branch, 0)]
	gold += R.gold
	potions += R.potions
	if R.gold > 0:
		toast("+%d VÀNG" % R.gold, Color("ffd24a"))
	if R.item != null:
		var it = D.make_item(R.item[0], R.item[1], R.item[2])
		if inv.size() < BAG:
			inv.append(it)
			toast("NHẬN ĐƯỢC " + it.name, D.RAR_COL[it.rar])
		else:
			drops.append({"pos": p.pos + Vector2(0, 14), "vel": Vector2.ZERO, "t": 0.0, "kind": "item", "n": 0, "item": it})
	qs[id] = "done"
	if id == "m6" and second_m < 0:
		# the second face of the shard: the player picks which mastery wakes
		if menus_on():
			Menu.open(self, "second")
			for i in Menu.CLASSES.size():
				if Menu.pickable(self, i):
					csel = i
					msel = i
					break
		else:
			second_m = sec()
	if Q.has("toast"):
		toast(Q.toast, VONG)
	if id == "m26":
		var ending = D.EPILOGUE[flags.get("van", 0)].duplicate()
		ending.insert(ending.size() - 1, D.EPILOGUE_NGAI[1 if int(flags.get("bond", 0)) >= 3 else 0])
		say("", "", ending, "", "")
		talk["story"] = true
	give_xp(R.xp)
	for nid in D.ORDER:
		if q_open(nid) and D.QUESTS[nid].get("auto", false):
			accept(nid)

func count_kill(kind: String) -> void:
	for id in D.ORDER:
		if qs.get(id, "") != "active":
			continue
		var need = D.QUESTS[id].need
		var c = qc[id]
		if need.get("kill", {}).has(kind):
			c[kind] = mini(need.kill[kind], c.get(kind, 0) + 1)
		if need.has("loot") and need.loot[2] == kind and c.get("loot", 0) < need.loot[1]:
			c["loot"] = c.get("loot", 0) + 1
			toast("%s %d/%d" % [need.loot[0], c.loot, need.loot[1]], VONG)
	refresh_quests()

# the nearest person or thing the hero can use
func near_target():
	var best = null
	var bd = 34.0
	for n in zone.npcs:
		var d = n.pos.distance_to(p.pos)
		if d < bd:
			bd = d
			best = {"kind": "npc", "id": n.id, "pos": n.pos, "name": D.NPCS[n.id].name, "h": 62.0}
	for th in zone.things:
		var T = D.THINGS[th.id]
		if T.has("quest") and qs.get(T.quest, "") != "active":
			continue
		if T.has("flag") and flags.has(T.flag):
			continue
		var d = th.pos.distance_to(p.pos)
		if d < bd:
			bd = d
			best = {"kind": "thing", "id": th.id, "pos": th.pos, "name": T.name, "h": th.get("h", 34.0)}
	return best

func interact() -> void:
	var n = near_target()
	if n == null or p.state == "dead":
		return
	if n.kind == "npc":
		start_talk(n.id)
	else:
		look(n.id)

# name "" is the narrator. after: what happens when the last line is dismissed; arg goes with it.
func say(name: String, tex: String, lines: Array, after: String, arg: String) -> void:
	lines = lines.map(func(s): return s.replace("{2}", wake_text()))
	talk = {"name": name, "tex": tex, "lines": lines, "i": 0, "after": after, "arg": arg, "opts": []}
	mode = "talk"
	p.vel = Vector2.ZERO
	p.moving = false
	buf = ""
	Sfx.play("clap", 1.2, -6.0)

func service(npc: String) -> String:
	if npc == "ngai":
		return "heal_shop" if qs.get("m16", "") == "done" else "heal"
	return "shop" if npc == "kham" else ""

func start_talk(npc: String) -> void:
	var who = D.NPCS[npc]
	for id in D.ORDER:
		var Q = D.QUESTS[id]
		var st = qs.get(id, "")
		if (st == "ready" and q_ender(id) == npc) or (st == "active" and Q.need.get("talk", "") == npc and needs_met(id, true)):
			var lines = Q.done
			if Q.has("branch"):
				lines = Q.done[flags.get(Q.branch, 0)]
			say(who.name, who.tex, lines, "turnin", id)
			return
	for id in D.ORDER:
		var Q = D.QUESTS[id]
		if q_open(id) and Q.giver == npc and not Q.get("auto", false):
			say(who.name, who.tex, Q.offer, "accept", id)
			return
	for id in D.ORDER:
		var Q = D.QUESTS[id]
		if qs.get(id, "") == "active" and (Q.giver == npc or q_ender(id) == npc):
			say(who.name, who.tex, Q.wait, service(npc), "")
			return
	if npc == "ngai" and zone.id == "maw":
		say(who.name, who.tex, D.NGAI_PIT, "", "")
		return
	if npc == "ngai" and qs.get("m26", "") != "done":
		# an idle talk with Ngải, once a chapter, brings her closer
		var ch = chapter()
		if int(flags.get("bond_ch", -1)) != ch:
			flags["bond_ch"] = ch
			flags["bond"] = int(flags.get("bond", 0)) + 1
	if npc == "ngai" and qs.get("m26", "") == "done":
		var tl = tide_level()
		say(who.name, who.tex, [D.TIDE_TALK[tl - 1], "MÌNH ĐO MỖI SÁNG. VÃN TỪNG NÓI NGƯỜI NHẶT VỌNG GIỎI LÀ NGƯỜI BIẾT KHI NÀO KHÔNG NÊN XUỐNG HẦM. MÌNH THÌ NGHĨ NGƯỢC LẠI."], service(npc), "")
		return
	if qs.get("m11", "") == "done" and D.AFTER_CHAT.has(npc):
		say(who.name, who.tex, D.AFTER_CHAT[npc][flags.get("village", 0)], service(npc), "")
		return
	var c = D.CHAT[npc]
	say(who.name, who.tex, c[mini(c.size() - 1, main_done() / 2)], service(npc), "")

func look(id: String) -> void:
	if id.begins_with("mute_"):
		mute_clapper(int(id.substr(5)))
		return
	if id == "lighthouse":
		lighthouse()
		return
	var T = D.THINGS[id]
	say(T.name, "", T.lines, "seen", id)
	if T.has("opts"):
		talk.opts = T.opts

func scene(sc: Dictionary) -> void:
	var S = D.SCENES[sc.id]
	say(S.name, S.tex, S.lines, "seen", sc.id)
	talk["ghost"] = sc.at
	Sfx.play("tele_hi", 0.5)

func choose(k: int) -> void:
	var T = D.THINGS[talk.arg]
	flags[T.flag] = k
	if T.has("xp"):
		give_xp(T.xp)
	flags["seen_" + talk.arg] = 1
	say(T.name, "", T.after[k], "", "")
	refresh_quests()
	save_game()

func talk_next() -> void:
	if talk.i + 1 < talk.lines.size():
		talk.i += 1
		Sfx.play("clap", 1.2, -8.0)
		return
	if not talk.opts.is_empty():
		return   # the last line is a choice; ui.gd calls choose()
	mode = "play"
	match talk.after:
		"accept":
			accept(talk.arg)
		"turnin":
			turnin(talk.arg)
		"seen":
			flags["seen_" + talk.arg] = 1
			refresh_quests()
		"heal":
			p.hp = stats.mhp
			toast("MẢNH CHUÔNG NGÂN ĐÚNG TIẾNG. MÁU ĐÃ HỒI ĐẦY.", VONG)
			Sfx.play("orb", 0.7)
		"shop":
			open_inv(true)
		"heal_shop":
			p.hp = stats.mhp
			toast("NGẢI LÊN DÂY MẢNH CHUÔNG. MÁU ĐÃ HỒI ĐẦY.", VONG)
			Sfx.play("orb", 0.7)
			open_inv(true)
	save_game()

# The hero has six pictures from one sheet: idle, three walk steps, wind-up, slash.
# They face right and are mirrored; the lean, hop and roll are added here.
func draw_player() -> void:
	var facing = p.dir if (p.state == "atk" or p.state == "dodge") else p.aim
	if absf(facing.x) > 0.2:
		p.flip = facing.x < 0.0
	if p.state == "idle" and p.moving and absf(p.vel.x) > 20.0:
		p.flip = p.vel.x < 0.0
	var flip = p.get("flip", false)
	var name = "h_idle"
	var off = Vector2.ZERO
	var rot = 0.0
	var squash = 0
	var arc = null
	if p.state == "idle":
		if p.moving:
			name = ["h_w1", "h_w2", "h_w3", "h_w2"][int(t * 9.0) % 4]
			off.y = -1.0 if int(t * 9.0) % 2 == 1 else 0.0
		elif int(t * 2.5) % 2 == 0:
			squash = 1
	elif p.state == "dash":
		name = "h_slash"
		off = p.dir * 2.0
	elif p.state == "atk":
		var a = cur_atk()
		var sgn = 1.0 if p.idx % 2 == 0 else -1.0
		var half = deg_to_rad(minf(a[5], 110.0))
		var base = p.dir.angle()
		if p.st < a[0]:
			name = "h_wind"
			off = -p.dir * 2.0
		elif p.st < a[0] + a[1]:
			name = "h_slash"
			off = p.dir * 4.0
			var k = (p.st - a[0]) / a[1]
			arc = [base - sgn * half, base + sgn * lerpf(-half, half, k), 1.0, a[4]]
		else:
			var rt = p.st - a[0] - a[1]
			name = "h_slash" if rt < a[2] * 0.6 else "h_idle"
			off = p.dir * 2.0
			if rt < 2 * F:
				arc = [base - sgn * half, base + sgn * half, 1.0 - rt / (2 * F), a[4]]
		if p.skill != "":
			# the spin: the slash picture whips from side to side
			name = "h_slash"
			flip = int(p.st / (F * 0.75)) % 2 == 0
			if p.st >= a[0] and arc != null:
				arc = [base, base + TAU * 0.999, arc[2], a[4]]
	if p.state == "atk" and p.skill == "" and D.is_bow(eq.weapon):
		arc = null   # an arrow, not a blade
	if p.state == "aim":
		# drawing the bow
		name = "h_wind"
		off = -p.aim * 1.5 + Vector2(0, -1)
	elif p.state == "idle" and p.cast_t > 0.0:
		# the casting gesture (cast_fx): k runs from 0 to 1 over the gesture
		var k = 1.0 - p.cast_t / 0.35
		match p.cast_kind:
			"channel":
				name = "h_wind"
				off = Vector2(0, -2.0 * sin(k * PI))
			"roar":
				name = "h_slash"
				squash = -int(3.0 * sin(k * PI))
			"pray":
				name = "h_idle"
				off = Vector2(0, -4.0 * sin(k * PI))
			"kneel":
				name = "h_wind"
				squash = int(4.0 * sin(k * PI))
			_:
				name = "h_slash" if k > 0.3 else "h_wind"
				off = p.aim * (4.0 * sin(k * PI))
				rot = 0.12 * sin(k * PI) * (1.0 if p.aim.x >= 0.0 else -1.0)
	if p.flash > 0.0 and p.state != "dead":
		# struck: the body jerks back from the blow
		rot = 0.18 * (1.0 if flip else -1.0)
		off += Vector2(2.0 if flip else -2.0, 0)
	# three facings: side pictures are mirrored, front and back ones are not
	if absf(facing.x) < absf(facing.y) * 0.9:
		var alt = ("hd" if facing.y > 0.0 else "hu") + name.substr(1)
		if Art.T.has(alt):
			name = alt
			flip = false
	# each mastery has its own look (Art.LOOKS); the Warrior and any look not made yet use the plain pictures
	var look = "k%d_%s" % [main_m, name]
	if Art.T.has(look):
		name = look
	var tex: Texture2D = Art.T[name]
	var w = tex.get_width()
	var h = tex.get_height()
	draw_texture_rect(Art.T["shadow"], Rect2(p.pos.x - 11, p.pos.y - 3, 22, 7), false)
	if p.state == "dead":
		# the hero topples over, then the echo of the body fades upward
		var fall = clampf(p.st / 0.35, 0.0, 1.0)
		var side = -1.0 if flip else 1.0
		draw_set_transform((p.pos - cam_tl).floor(), side * fall * PI * 0.5)
		draw_texture_rect(tex, Rect2(-w / 2.0, -h + 3, -w if flip else w, h), false, Color(1, 1, 1, clampf(1.6 - p.st, 0.0, 1.0)))
		draw_set_transform(-cam_tl)
		if p.st > 0.6:
			var fade = clampf(1.0 - (p.st - 0.6) / 1.2, 0.0, 1.0)
			draw_texture(Art.W[name], Vector2(p.pos.x - w / 2.0, p.pos.y - h + 3 - (p.st - 0.6) * 14.0).floor(), Color(VONG.r, VONG.g, VONG.b, fade * 0.7))
		return
	if p.state != "dodge" and p.inv > 0.0 and int(t * 20.0) % 2 == 0:
		return
	var use: Texture2D = Art.W[name] if (p.flash > 0.0 and opt.flash) else tex
	var fw = -w if flip else w
	if p.state == "dodge":
		var k3 = clampf(p.st / DODGE_T, 0.0, 1.0)
		var mid = p.pos + Vector2(0, -h * 0.4 - sin(k3 * PI) * 4.0)
		draw_set_transform((mid - cam_tl).floor(), (TAU * k3) * (-1.0 if p.dir.x < 0.0 else 1.0), Vector2(0.85, 0.85))
		draw_texture_rect(use, Rect2(-w / 2.0, -h * 0.6, fw, h), false)
		draw_set_transform(-cam_tl)
		return
	draw_set_transform((p.pos + off - cam_tl).floor(), rot)
	draw_texture_rect(use, Rect2(-w / 2.0, -h + 3 + squash, fw, h - squash), false)
	draw_set_transform(-cam_tl)
	if p.guard > 0.0:
		draw_arc(p.pos + Vector2(0, -16), 17.0, p.aim.angle() - 1.1, p.aim.angle() + 1.1, 10, Color("cfe3f4"), 2.0)
	if arc != null:
		draw_arc_fx(p.pos + Vector2(0, -16), arc[0], arc[1], arc[3], arc[2])

# ---------------------------------------------------------------- second mastery: marks and spells

func has_second() -> bool:
	return qs.get("m6", "") == "done"

func skill_cost(id: String) -> float:
	var c = float(Sk.NODES[id].get("rage", 0))
	if id == "shadow" and tree.has("lb_follow") and t < p.follow_t:
		c = 0.0
	if id == "spark" and tree.has("overload"):
		c += 10.0
	if (id == "spin" and tree.has("tk_spin") and p.boost_t > 0.0) or (id == "slam" and tree.has("tk_pull") and t < p.hookslam_t):
		c = 0.0
	if tree.has("lc_reactor") and Sk.NODES[id].has("el") and hot():
		c = 0.0
	return c * (1.0 - 0.05 * tree.get("battery", 0))

func skill_cd(id: String) -> float:
	var N = Sk.NODES[id]
	var cd = float(N.get("cd", 0.0))
	if id == "snare" or id == "mine":
		cd *= 1.0 - 0.1 * tree.get("trapper", 0)
	if id == "seal" and tree.has("pq_doom"):
		cd += 3.0
	if id == "sic" and tree.has("tl_beast"):
		cd += 5.0
	if id == "hunt" and tree.has("tp_big"):
		cd *= 2.0
	if id == "bronze" and tree.has("mv_tomb"):
		cd += 30.0
	if id == "bulwark" and tree.has("unbroken"):
		cd *= 0.5
	if N.get("m", 0) == 1 and tree.has("tempest"):
		cd *= 1.3
	if id == "shadow" and tree.has("ost_step"):
		cd *= 0.7
	if id == "hook" and tree.has("oks_hook"):
		cd *= 0.6
	if N.kind == "a" and tree.get(id, 0) > N.max:
		cd *= 1.0 - 0.06 * (tree[id] - N.max)
	if id == "wall" and tree.has("pl_bunker"):
		cd += 8.0
	if N.kind == "u" and tree.has("prototype"):
		cd *= 2.0
	return cd * (1.0 - minf(stats.cdr, 40.0) / 100.0)

# leave a mark on a foe. Marks never trigger anything by themselves.
func mark(f: Dictionary, kind: String) -> void:
	if f.state == "dead":
		return
	var had = f.get(kind, 0.0) > 0.0
	match kind:
		"burn":
			f.burn = 4.0 * (0.5 if tree.has("pyre") else 1.0) + (2.0 if tree.has("ont_hot") else 0.0)
			f.burn_dps = stats.atk * 0.3 * (1.0 + 0.2 * tree.get("kindle", 0))
		"chill":
			if had and tree.has("ont_deepcold") and not D.FOES[f.kind].get("big", false) and t >= f.get("deep_t", 0.0):
				f.deep_t = t + 3.0
				stagger(f, 1.0)
			f.chill = (4.0 + tree.get("deep", 0)) * (2.0 if (p.smoke > 0.0 and tree.has("dl_fog")) else 1.0)
		"shock":
			f.shock = 5.0
	if tree.has("nq_lit") and f.get("lit", 0.0) > 0.0 and t >= p.nqlit_t:
		p.nqlit_t = t + 0.5
		add_devo(4.0)
	if tree.has("tn_layer") and f.get("hunt", 0.0) > 0.0 and kind != "poison":
		f[kind] *= 1.5
	if tree.has("dl_three"):
		f[kind] *= 0.7
	if not had and tree.has("dl_mark") and t >= p.mark_t:
		p.mark_t = t + 1.5
		add_cp(1)

func spell(kind: String) -> void:
	if kind == "chill" and tree.has("icearmor"):
		p.icearm = 4.0
	p.elem = kind
	p.elem_t = 6.0
	p.guard = 0.0

func foe_near(at: Vector2, reach: float, skip: Array):
	var best = null
	var bd = reach
	for f in foes:
		if f.state == "dead" or f.state == "spawn" or skip.has(f.id):
			continue
		var d = f.pos.distance_to(at)
		if d < bd:
			bd = d
			best = f
	return best

# lightning from `from` to the nearest foe, then on to `jumps` more. Returns how many it hit.
func spark_chain(from: Vector2, jumps: int, skip: Array) -> int:
	var hit = skip.duplicate()
	var at = from
	var reach = 130.0
	var mult = 1.4
	var n = 0
	for i in jumps + 1:
		var f = foe_near(at, reach, hit)
		if f == null:
			break
		zaps.append({"a": at + Vector2(0, -16), "b": f.pos + Vector2(0, -14), "life": 0.22})
		hit.append(f.id)
		hit_foe(f, stats.atk * mult * p.smult, false, 0.03, 1.0)
		mark(f, "shock")
		at = f.pos
		reach = 90.0 + 15.0 * tree.get("relay", 0)
		mult = 1.0
		n += 1
	return n

# ---------------------------------------------------------------- more foes, elites

func has_uniq(u: String) -> bool:
	for slot in D.SLOTS:
		if eq[slot] != null and eq[slot].uniq == u:
			return true
	return false

func make_elite(f: Dictionary, mod: String) -> void:
	f.elite = mod
	f.scale = 1.2
	f.r *= 1.15
	f.hp *= 1.8
	f.mhp = f.hp

# true when another living foe with the warding mark stands close to this one
func warded(f: Dictionary) -> bool:
	for o in foes:
		if f.get("purge", 0.0) <= 0.0 and o != f and o.state != "dead" and o.state != "spawn" and o.get("elite", "") == "warding" and o.get("purge", 0.0) <= 0.0 and o.pos.distance_to(f.pos) < 110.0:
			return true
	return false

func ranged_pick(f: Dictionary, to: Vector2, K: Dictionary) -> void:
	f.amber = false
	f.atk = ""
	match ai(f):
		"netter", "sower":
			f.tpos = p.pos
			wind_up(f, to, "tele_mid", K.wind)
		"wisp":
			var best = null
			for o in foes:
				if o == f or o.kind == "wisp" or o.state == "dead" or o.state == "spawn" or o.hp >= o.mhp * 0.8 or o.pos.distance_to(f.pos) > 170.0:
					continue
				if best == null or o.hp / o.mhp < best.hp / best.mhp:
					best = o
			if best != null:
				f.atk = "heal"
				f.target = best.id
				wind_up(f, to, "tele_hi", 1.6)
				f.amber = true
			else:
				wind_up(f, to, "tele_hi", K.wind)
		_:
			wind_up(f, to, "tele_hi", K.wind)

# The Toll Keeper: a chain sweep, a slam, and a long amber call that heals him unless it is cut short.
func keeper_pick(f: Dictionary, to: Vector2, dist: float, K: Dictionary) -> void:
	f.amber = false
	var pick = f.n % 3
	f.n += 1
	if pick == 2 and f.hp > f.mhp * 0.85:
		pick = 0
	if pick == 0 and dist > K.range:
		pick = 1
	match pick:
		0:
			f.atk = "sweep"
			wind_up(f, to, "tele_mid", 0.8)
		1:
			f.atk = "slam"
			f.tpos = p.pos
			wind_up(f, to, "tele_lo", 1.0)
		2:
			f.atk = "call"
			wind_up(f, to, "tele_hi", 2.4)
			f.amber = true

# amber means "this can be interrupted": a turning ring of dots and an arc that fills as the cast runs
func amber(f: Dictionary, k: float) -> void:
	var c = f.pos + Vector2(0, -foe_h(f) * 0.5)
	var r = foe_h(f) * 0.6 + 6.0
	for i in 10:
		var a = TAU * i / 10.0 + t * 3.0
		draw_rect(Rect2((c + Vector2.from_angle(a) * r).floor() - Vector2(1, 1), Vector2(3, 3)), AMBER)
	draw_arc(c, r - 4.0, -PI / 2.0, -PI / 2.0 + TAU * k, 24, AMBER, 2.0)

# sell every item below the filter (commons at least); uniques are never sold this way
func sell_junk() -> int:
	var n = 0
	for i in range(inv.size() - 1, -1, -1):
		if inv[i].rar < maxi(loot_filter, 1) and inv[i].slot != "rune":
			gold += D.value(inv[i])
			inv.remove_at(i)
			n += 1
	if n > 0:
		Sfx.play("orb", 1.3)
		toast("ĐÃ BÁN %d MÓN" % n, Color("ffd24a"))
	return n

func _exit_tree() -> void:
	Sfx.stop_music()

# The tree-mother never moves. Root lines burst out from her, the first one aimed at you; spore pods land
# where you stand; and a long amber call brings wolves unless a heavy hit cuts it short. Below half life
# there are five lines instead of three and three pods instead of two.
func mother_pick(f: Dictionary, to: Vector2) -> void:
	f.amber = false
	var late = f.hp < f.mhp * 0.5
	var pick = f.n % 3
	f.n += 1
	if pick == 2 and foes.size() >= 5:
		pick = 0
	match pick:
		0:
			f.atk = "roots"
			f.lines = 5 if late else 3
			f.ang = to.angle()
			wind_up(f, to, "tele_mid", 1.0)
		1:
			f.atk = "spores"
			f.pods = [p.pos]
			for i in (2 if late else 1):
				f.pods.append(p.pos + Vector2.from_angle(randf() * TAU) * 64.0)
			wind_up(f, to, "tele_hi", 0.9)
		2:
			f.atk = "call"
			wind_up(f, to, "tele_hi", 2.6)
			f.amber = true

# ---------------------------------------------------------------- menus, settings, new characters

func menus_on() -> bool:
	return D.MENUS == 1 or (D.MENUS == -1 and D.SAVE_PATH == D.DEFAULT_SAVE)

func opt_path() -> String:
	return D.SAVE_PATH.replace(".json", "_opt.json")

func load_opt() -> void:
	if FileAccess.file_exists(opt_path()):
		var d = JSON.parse_string(FileAccess.get_file_as_string(opt_path()))
		if typeof(d) == TYPE_DICTIONARY:
			for k in opt:
				if d.has(k) and typeof(d[k]) == typeof(opt[k]):
					opt[k] = d[k]
	apply_opt()
	if opt.full:
		apply_window()

func save_opt() -> void:
	var f = FileAccess.open(opt_path(), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(opt))

func apply_opt() -> void:
	Sfx.set_volume(opt.sfx / 100.0, opt.music / 100.0)

func apply_window() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if opt.full else DisplayServer.WINDOW_MODE_WINDOWED)

# a new character whose first mastery is m; the other one wakes at the end of chapter one
func start_new(m: int) -> void:
	new_game()
	main_m = m
	tab = m
	recompute()
	fresh_hero()
	mode = "play"
	enter_zone("town", Vector2.ZERO)
	has_save = true
	say("", "", D.INTRO, "", "")
	talk["story"] = true

# the ultimate on the R key: the chosen one, or else the first one learned
func cur_ult() -> String:
	if ult != "" and tree.has(ult):
		return ult
	for id in ["toll", "tam", "cuts", "night", "bronze", "bighunt", "vigil", "bellwork"]:
		if tree.has(id):
			return id
	return ""

# ---------------------------------------------------------------- Assassin: danger points, poison, second mastery

# the second mastery: the one chosen when the shard woke, or else the default partner of the first
func sec() -> int:
	if second_m >= 0:
		return second_m
	return 1 if main_m == 0 else 0

func tabs() -> Array:
	return [main_m, sec(), Sk.link_of(main_m, sec()), Sk.solo_of(main_m)]

func wake_text() -> String:
	if second_m < 0 and menus_on():
		return "NÓ ĐANG CHỜ BẠN CHỌN MỘT TAY NGHỀ THỨ HAI"
	return Sk.WAKES[sec()]

func uses_cp() -> bool:
	return main_m == 3 or (sec() == 3 and has_second())

func cp_cap() -> int:
	var cap = (6 if tree.has("six") else 5) + (1 if tree.has("ost_six") else 0)
	if tree.has("ta_night") and not foes.any(func(o): return o.get("hunt", 0.0) > 0.0 and o.state != "dead"):
		cap = mini(cap, 3)
	return cap

func add_cp(n: int) -> void:
	p.cp = mini(cp_cap(), p.cp + n)

# a foe's back: it faces left when flipped
func is_behind(f: Dictionary) -> bool:
	if tree.has("ta_night") and f.get("hunt", 0.0) > 0.0:
		return true
	if tree.has("dv_open") and t < f.get("open_t", -9.0):
		return true
	if tree.has("dl_frozen") and f.get("chill", 0.0) > 0.0:
		return true
	return (p.pos.x - f.pos.x) * (-1.0 if f.flip else 1.0) < 0.0

func poison_dps() -> float:
	return stats.atk * 0.2 * (1.0 + 0.1 * tree.get("potent", 0))

func poison(f: Dictionary, n: int) -> void:
	if tree.has("pq_holy") and p.bless_t > 0.0:
		lit(f, 6.0)
	if f.state == "dead":
		return
	f.poison = mini((3 if tree.has("burst") else 5) + (2 if tree.has("ost_toxic") else 0) + (2 if (tree.has("gh_plague") and f.get("curse", 0.0) > 0.0) else 0), f.get("poison", 0) + n)
	f.poison_t = 4.0 + tree.get("linger", 0)

func shadow_target():
	var tgt = foe_near(p.pos + (aim_pos() - p.pos).limit_length(120.0), 70.0, [])
	if tgt == null:
		tgt = foe_near(p.pos, 120.0, [])
	return tgt

func cuts_targets() -> Array:
	var list = foes.filter(func(f): return f.state != "dead" and f.state != "spawn" and f.pos.distance_to(p.pos) < 170.0)
	list.sort_custom(func(a, b): return a.pos.distance_to(p.pos) < b.pos.distance_to(p.pos))
	return list.slice(0, 6)

# ---------------------------------------------------------------- Soul Warlock: souls, echoes, curses
# Echoes (ghosts) cannot be hit. What they deal never gives rage or danger points.

func uses_souls() -> bool:
	return main_m == 6 or (sec() == 6 and has_second())

func soul_cap() -> int:
	return (8 if tree.has("otl_eight") else 5) + tree.get("jar", 0) - (1 if tree.has("gh_cheat") else 0)

func add_soul(n: int) -> void:
	if uses_souls():
		p.souls = mini(soul_cap(), p.souls + n)
		if tree.has("mv_soul") and n > 0:
			add_shield(8.0 * n)

func summon_cost() -> int:
	return 2 if tree.has("kt_shroud") else 1

func ghost_cap() -> int:
	if tree.has("kl_puppet"):
		return maxi(0, 3 - devices.filter(func(d): return not d.free).size())
	return ((4 if tree.get("horde", 0) >= 3 else 3) + (1 if tree.has("otl_host") else 0)) * (2 if tree.has("legion") else 1)

# true when a soul skill cannot be used right now
func soul_block(id: String) -> bool:
	match id:
		"summon":
			return tree.has("th_fire") or (p.souls < summon_cost() and not (tree.has("kl_heat") and p.heat < hot_line() and p.over <= 0.0)) or ghosts.filter(func(gh): return not gh.free).size() >= ghost_cap()
		"sacrifice":
			return tree.has("ch_send") or (ghosts.is_empty() and not (tree.has("hl_tithe") and pet_up() != null))
		"soulform":
			return p.souls < 1
		"chain":
			return foe_near(p.pos, 220.0, []) == null
	return false

# free: does not count against the limit
func add_ghost(pos: Vector2, life: float, free: bool) -> void:
	ghosts.append({"pos": pos, "t": life * (0.5 if tree.has("hl_wolf") else 1.0), "cd": 0.5, "free": free, "flip": false, "el": p.elem if tree.has("th_tint") else ""})
	burst(pos + Vector2(0, -16), VONG, 10, 70.0)

func ghost_near(at: Vector2):
	var best = null
	for gh in ghosts:
		if best == null or gh.pos.distance_to(at) < best.pos.distance_to(at):
			best = gh
	return best

func sacrifice(gh) -> void:
	if gh == null:
		return
	if not (tree.has("ch_vow") and p.vow_t > 0.0):
		ghosts.erase(gh)
	if tree.has("kl_sac"):
		for d in devices.duplicate():
			if d.kind == "mine" and d.pos.distance_to(gh.pos) < 60.0:
				mine_blast(d, 1.5)
	if tree.has("mv_tithe"):
		add_shield(20.0)
	rings.append({"pos": gh.pos, "r": 55.0, "life": 0.35, "max": 0.35, "col": VONG})
	Sfx.play("slam", 1.2)
	for f in foes:
		if f.state != "dead" and f.state != "spawn" and f.pos.distance_to(gh.pos) < 55.0 + f.r:
			hit_foe(f, stats.atk * 2.2, true, 0.05, 2.0)
			if tree.has("th_sac") and gh.el != "":
				mark(f, gh.el)

func curse(f: Dictionary) -> void:
	if f.state == "dead":
		return
	if tree.has("oneword"):
		for o in foes:
			o.curse = 0.0
		f.curse = 99999.0
	else:
		f.curse = 8.0 + 1.5 * tree.get("deepcurse", 0)

# called when a foe dies, before it is marked dead
func soul_kill(f: Dictionary) -> void:
	chain_ids.erase(f.id)
	if not uses_souls():
		return
	if f.pos.distance_to(p.pos) < 120.0 or (pet_hit and tree.has("hl_reap")):
		add_soul(2 if randf() < 0.1 * tree.get("harvest", 0) else 1)
	if tree.has("th_ash") and t >= p.ash_t and (f.get("burn", 0.0) > 0.0 or f.get("chill", 0.0) > 0.0 or f.get("shock", 0.0) > 0.0):
		p.ash_t = t + 2.0
		add_soul(1)
	if f.get("curse", 0.0) > 0.0 and tree.has("spread"):
		var skip = [f.id]
		for i in (1 if tree.has("oneword") else tree.spread):
			var o = foe_near(f.pos, 90.0, skip)
			if o == null:
				break
			skip.append(o.id)
			curse(o)
	if p.night > 0.0 and f.pos.distance_to(p.pos) < 150.0 and ghosts.size() < 12:
		add_ghost(f.pos, maxf(p.night, 1.0), true)

func update_ghosts(dt: float) -> void:
	chain_t -= dt
	if chain_t <= 0.0:
		chain_ids = []
	for gh in ghosts:
		if not (tree.has("kl_puppet") and not gh.free):
			gh.t -= dt
		gh.cd -= dt
		var tgt = foe_near(gh.pos, 200.0, [])
		if tgt == null:
			var home = p.pos - gh.pos
			if home.length() > 44.0:
				gh.pos += home.normalized() * 95.0 * dt
				gh.flip = home.x < 0.0
			continue
		var d = tgt.pos - gh.pos
		gh.flip = d.x < 0.0
		if d.length() > tgt.r + 16.0:
			gh.pos += d.normalized() * 95.0 * (1.4 if tree.has("hl_wolf") else 1.0) * dt
		elif gh.cd <= 0.0:
			gh.cd = 1.0 / ((1.0 + 0.08 * tree.get("horde", 0)) * (1.3 if (p.cry > 0.0 and tree.has("kt_rally")) else 1.0))
			ghost_hit = true
			hit_foe(tgt, stats.atk * 0.35 * (1.0 + 0.1 * tree.get("sharp", 0)) * (0.5 if tree.has("legion") else 1.0) * (1.25 if tree.has("otl_strong") else 1.0), false, 0.0, 0.0)
			ghost_hit = false
			if tree.has("nq_tint") and p.bless_t > 0.0 and p.elem != "" and tgt.state != "dead" and t >= tgt.get("tint3_t", 0.0):
				tgt.tint3_t = t + 3.0
				mark(tgt, p.elem)
			if tree.has("hl_wolf") and not gh.get("pounced", false) and tgt.state != "dead":
				gh.pounced = true
				root(tgt, 1.0)
			if gh.el != "" and tgt.state != "dead" and t >= tgt.get("tint_t", 0.0):
				tgt.tint_t = t + 2.0
				mark(tgt, gh.el)
	if tree.has("ch_tend"):
		for gh in ghosts:
			if gh.t <= 0.0:
				add_devo(10.0)
	ghosts = ghosts.filter(func(gh): return gh.t > 0.0)

# ---------------------------------------------------------------- Guardian: the shield
# KHIÊN is taken before life. It fades 5 a second once 4 seconds pass without a blow landing on it.
# What it sends back to the striker (thorns, payback) is secondary damage: it never triggers anything.

func uses_shield() -> bool:
	return main_m == 10 or (sec() == 10 and has_second())

func shield_cap() -> float:
	var c = 100.0 + 10.0 * tree.get("thick", 0) + (30.0 if tree.has("ohv_cap") else 0.0)
	if tree.has("fortress"):
		c *= 2.0
	if tree.has("payback"):
		c *= 0.7
	if tree.has("dv_fake"):
		c *= 0.75
	return c

func add_shield(n: float) -> void:
	if n <= 0.0 or p.state == "dead":
		return
	p.shield = minf(shield_cap(), p.shield + n)
	p.shield_hit = t   # a fresh shield waits its four seconds too
	if tree.has("share"):
		p.hp = minf(stats.mhp, p.hp + n * 0.1 * tree.share)
	if tree.has("pl_share"):
		for d in devices:
			d.t += 1.0
	if tree.has("bv_pet"):
		for pt in pets:
			if pt.down <= 0.0:
				pt.hp = minf(pt.mhp, pt.hp + n * 0.3)

# takes a blow on the shield; returns what is left for the life bar
func shield_take(dmg: float) -> float:
	if p.shield <= 0.0:
		return dmg
	var a = minf(p.shield, dmg)
	p.shield -= a
	p.shield_hit = t
	if p.bronze > 0.0:
		p.shield = shield_cap()
	nums.append({"pos": p.pos + Vector2(0, -46), "txt": "-" + str(int(round(a))), "life": 0.6, "col": Color("e0d6a0")})
	if tree.has("tt_rage"):
		p.rage = minf(100.0, p.rage + a * 0.4)
		p.rage_t = 5.0
	if tree.has("pl_cool") and t >= p.plcool_t:
		p.plcool_t = t + 0.5
		add_heat(-5.0)
	if tree.has("sv_pray"):
		add_devo(a * 0.3 * (2.0 if tree.has("sv_martyr") else 1.0))
	if tree.get("debt", 0) > 0:
		p.debt = true
	var h = hitter
	if h != null and h.state != "dead" and h.state != "spawn":
		var back = stats.atk * 0.1 * tree.get("thorns", 0) * (2.0 if tree.has("ohv_spikes") else 1.0) + (a * 0.3 if tree.has("payback") else 0.0)
		if back > 0.0:
			h.hp -= back
			h.flash = F
			nums.append({"pos": h.pos + Vector2(0, -foe_h(h) * 0.75), "txt": str(int(round(back))), "life": 0.5, "col": Color("c9b98a")})
		if tree.has("dv_thorn") and tree.has("thorns") and t >= h.get("thorn_t", 0.0):
			h.thorn_t = t + 1.0
			poison(h, 1)
		if tree.has("ls_volt") and t >= h.get("volt_t", 0.0):
			h.volt_t = t + 2.0
			mark(h, "shock")
			h.shock = 3.0
		if tree.has("dv_open"):
			h.open_t = t + 2.0
	if p.shield <= 0.0:
		# the shield broke
		burst(p.pos + Vector2(0, -18), Color("e0d6a0"), 10, 100.0)
		Sfx.play("break", 1.4)
		if tree.has("dv_dodge") and t >= p.break_t:
			p.break_t = t + 8.0
			add_cp(2)
		if tree.has("dv_fake") and t >= p.fake_t:
			p.fake_t = t + 12.0
			p.smoke = maxf(p.smoke, 2.0)
			burst(p.pos + Vector2(0, -16), Color("7a5c9e"), 14, 80.0)
			nums.append({"pos": p.pos + Vector2(0, -56), "txt": "KHIÊN GIẢ", "life": 0.9, "col": Color("b9b2a3")})
	return dmg - a

func update_shield(dt: float) -> void:
	if p.bronze > 0.0:
		p.bronze -= dt
		p.shield = shield_cap()
		if p.bronze <= 0.0:
			rings.append({"pos": p.pos, "r": 80.0, "life": 0.4, "max": 0.4, "col": Color("e0b04a")})
			slam_fx(p.pos, 64.0)
			Sfx.play("slam", 0.7)
			shake = maxf(shake, 4.0)
			for f in foes:
				if f.state != "dead" and f.state != "spawn" and f.pos.distance_to(p.pos) < 80.0 + f.r:
					hit_foe(f, stats.atk * 3.0, true, 0.08, 4.0)
	p.shield = minf(p.shield, shield_cap())
	if tree.has("ohv_regen") and p.shield < 15.0 and p.state != "dead":
		p.shield += 3.0 * dt
	if p.shield > 0.0 and p.bronze <= 0.0 and not tree.has("fortress") and not p.post and t - p.shield_hit > 4.0:
		p.shield = maxf(0.0, p.shield - 5.0 * dt * (1.0 - 0.2 * tree.get("endure", 0)))

func in_cover() -> bool:
	for fd in fields:
		if fd.kind == "cover" and p.pos.distance_to(fd.pos) < fd.r:
			return true
	return false

func allies_near(reach: float) -> int:
	return ghosts.filter(func(gh): return gh.pos.distance_to(p.pos) < reach).size()

func watch_def() -> float:
	var iron = 2.0 * p.iron_n if p.iron_t > 0.0 else 0.0
	var w = tree.get("watch", 0)
	if w == 0:
		return iron
	return iron + (4.0 if allies_near(80.0) > 0 else 2.0) * w

# what share of a blow still lands after cover, the stand-in and the price of the true heart
func guard_taken() -> float:
	var k = 1.0
	if in_cover():
		k *= 0.7
	if tree.has("standin"):
		k *= 1.0 - 0.08 * mini(allies_near(100.0), 4)
	if blessed():
		k *= 1.0 - 0.05 * tree.get("shelter", 0)
	if tree.has("sv_martyr"):
		k *= 0.85
	if tree.has("tt_true") and p.shield <= 0.0:
		k *= 1.15
	return k

func eye_r(r: float) -> float:
	return r * 1.4 if tree.has("ls_eye") else r

# a fire wall and a shield wall put close together: the shield wall burns, both stand 3 seconds longer
func burn_wall(fd: Dictionary) -> void:
	if not tree.has("ls_wall") or fd.get("joined", false):
		return
	var at = fd.pos if fd.kind == "wall" else (fd.a + fd.b) / 2.0
	for o in fields:
		if o == fd or o.get("joined", false):
			continue
		if o.kind != "wall" and o.kind != "fire":
			continue
		if (o.kind == "wall") == (fd.kind == "wall"):
			continue
		var oat = o.pos if o.kind == "wall" else (o.a + o.b) / 2.0
		if oat.distance_to(at) < 70.0:
			o.joined = true
			fd.joined = true
			o.t += 3.0
			fd.t += 3.0
			if o.kind == "wall":
				o.fire = true
			else:
				fd.fire = true
			burst(at + Vector2(0, -12), Sk.MARK_COL.burn, 12, 90.0)
			return

func cage_at(pos: Vector2) -> void:
	var cg = {"kind": "cage", "pos": pos, "r": 50.0, "t": 4.0, "tick": 0.0, "mult": p.smult}
	if tree.has("ls_cage"):
		for fd in fields:
			if fd.kind == "cover" and pos.distance_to(fd.pos) < fd.r:
				cg.pos = fd.pos
				cg.r = fd.r
				cg.t = maxf(fd.t, 0.5)
				break
	if tree.has("ls_eye") and pos.distance_to(p.pos) < 40.0:
		cg.r *= 1.4
		cg.mult *= 1.2
	fields.append(cg)

# a slam next to your own shield wall: the wall falls forward
func topple_walls() -> void:
	for fd in fields:
		if fd.kind != "wall" or fd.t <= 0.0 or fd.pos.distance_to(p.pos) > 70.0:
			continue
		fd.t = 0.0
		var dir: Vector2 = p.dir
		slam_fx(fd.pos + dir * 50.0, 40.0)
		for f in foes:
			if f.state == "dead" or f.state == "spawn":
				continue
			var rel = f.pos - fd.pos
			var along = rel.dot(dir)
			if along >= -8.0 and along <= 100.0 and absf(rel.cross(dir)) < 24.0 + f.r:
				hit_foe(f, stats.atk * 2.0, true, 0.06, 3.0)
	for fd in fields:
		if fd.kind == "wall" and fd.t <= 0.0:
			blocks.erase(fd.rect)
	fields = fields.filter(func(fd): return fd.t > 0.0)

func guard_cast(id: String) -> void:
	match id:
		"raise":
			add_shield(40.0)
			rings.append({"pos": p.pos, "r": 26.0, "life": 0.3, "max": 0.3, "col": Color("e0d6a0")})
			Sfx.play("parry", 0.7)
		"wall":
			var c = p.pos + p.aim * 30.0
			var r = Rect2(c.x - 4, c.y - 24, 8, 48) if absf(p.aim.x) > absf(p.aim.y) else Rect2(c.x - 24, c.y - 4, 48, 8)
			var fd = {"kind": "wall", "rect": r, "pos": c, "t": 5.0, "tick": 0.0}
			fields.append(fd)
			blocks.append(r)
			burn_wall(fd)
			if tree.has("pl_bunker"):
				place_device("drum" if tree.has("tc_drum") else "turret", c, true)
				add_heat(30.0)
			slam_fx(c, 20.0)
			Sfx.play("slam", 1.1)
		"bash":
			p.bash_more = p.shield >= (25.0 if tree.has("ohv_bash") else 50.0)
			if p.bash_more:
				p.shield -= 25.0
			p.bash_t = t
			begin_swing("bash")
		"verdict":
			var vr = 98.0 if tree.has("ohv_verdict") else 70.0
			var s = p.shield
			p.shield = 0.0
			rings.append({"pos": p.pos, "r": vr, "life": 0.4, "max": 0.4, "col": Color("e0d6a0")})
			slam_fx(p.pos, 56.0)
			Sfx.play("slam", 0.8)
			for f in foes:
				if f.state == "dead" or f.state == "spawn" or f.pos.distance_to(p.pos) > vr + f.r:
					continue
				var fm = 0.03 * s
				if tree.has("mv_judge") and f.get("curse", 0.0) > 0.0:
					fm *= 1.4
					curse(f)
				hit_foe(f, stats.atk * fm, true, 0.06, 3.0)
				if tree.has("sv_lit"):
					lit(f, 6.0)
				if tree.has("ls_mark") and p.elem != "":
					mark(f, p.elem)
				if tree.has("dv_verdict") and int(s / 25.0) > 0:
					poison(f, int(s / 25.0))
		"taunt":
			var n = 0
			var linked = []
			for f in foes:
				if f.state == "dead" or f.state == "spawn" or f.pos.distance_to(p.pos) > 90.0 + f.r:
					continue
				f.taunt = 4.0
				if f.state == "idle" or f.state == "home":
					f.state = "chase"
				n += 1
				if tree.has("ls_freeze") and f.get("chill", 0.0) > 0.0 and not D.FOES[f.kind].get("big", false):
					stagger(f, 1.0)
					nums.append({"pos": f.pos + Vector2(0, -foe_h(f) - 8), "txt": "ĐÓNG BĂNG", "life": 0.8, "col": Sk.MARK_COL.chill})
				if tree.has("mv_tchain") and linked.size() < 3:
					linked.append(f.id)
			if not linked.is_empty():
				chain_ids = linked
				chain_t = 6.0
			var gain = 20.0 * mini(n, 5 if tree.has("ohv_taunt") else 3)
			if tree.has("standin") and allies_near(100.0) == 0:
				gain *= 2.0
			add_shield(gain)
			rings.append({"pos": p.pos, "r": 90.0, "life": 0.4, "max": 0.4, "col": Sk.MARK_COL.taunt})
			nums.append({"pos": p.pos + Vector2(0, -52), "txt": "KHIÊU KHÍCH", "life": 0.8, "col": Sk.MARK_COL.taunt})
			Sfx.play("clap", 0.9)
		"cover":
			fields.append({"kind": "cover", "pos": p.pos, "r": 78.0 if tree.has("ohv_cover") else 60.0, "t": 7.0 if tree.has("ohv_cover") else 5.0, "tick": 0.0})
			join_rings(fields.back())
			Sfx.play("orb", 0.8)
		"bronze":
			p.bronze = 5.0
			p.shield = shield_cap()
			if tree.has("mv_tomb"):
				var k = 0
				while ghosts.filter(func(gh): return not gh.free).size() < ghost_cap() and k < 12:
					k += 1
					add_ghost(p.pos + Vector2.from_angle(TAU * k / 6.0) * 26.0, 20.0, false)
			burst(p.pos + Vector2(0, -18), Color("e0b04a"), 18, 120.0)
			nums.append({"pos": p.pos + Vector2(0, -52), "txt": "THÀNH ĐỒNG", "life": 1.0, "col": Color("e0b04a")})
			Sfx.play("tele_hi", 0.5)

# ---------------------------------------------------------------- Hunter: focus, the hound, traps
# TẬP TRUNG: two seconds with no foe within 80 and the next blow or skill (for one second) is 40% stronger.
# The hound is an ally. Its bites are secondary damage, like an echo's.

func uses_focus() -> bool:
	return main_m == 15 or (sec() == 15 and has_second())

func focus_need() -> float:
	return 1.2 if tree.has("ots_quick") else 2.0

func pet_count() -> int:
	if not uses_focus():
		return 0
	if tree.has("ots_lone"):
		return 0
	return 2 if tree.has("pack") else 1

func pet_mhp() -> float:
	if tree.has("tl_beast"):
		return stats.mhp * 0.6 * (1.0 + 0.15 * tree.get("sturdy", 0)) * (0.6 if tree.has("pack") else 1.0) * (1.3 if tree.has("ots_alpha") else 1.0)
	return stats.mhp * 0.4 * (1.0 + 0.15 * tree.get("sturdy", 0)) * (0.6 if tree.has("pack") else 1.0) * (1.3 if tree.has("ots_alpha") else 1.0)

func pet_dmg() -> float:
	return stats.atk * 0.3 * (1.0 + 0.1 * tree.get("fangs", 0)) * (0.6 if tree.has("pack") else 1.0) * (1.3 if tree.has("ots_alpha") else 1.0)

# the first hound that is standing, or null
func pet_up():
	for pt in pets:
		if pt.down <= 0.0:
			return pt
	return null

func aim_point(reach: float) -> Vector2:
	return p.pos + (aim_pos() - p.pos).limit_length(reach)

func root(f: Dictionary, dur: float) -> void:
	if f.state == "dead":
		return
	if D.FOES[f.kind].get("big", false):
		dur *= 0.5
	f.root = maxf(f.get("root", 0.0), dur)

func use_focus() -> void:
	if not p.focused:
		return
	p.focused = false
	p.focus_t = 0.0
	p.focus_until = t + 1.0
	nums.append({"pos": p.pos + Vector2(0, -52), "txt": "TẬP TRUNG", "life": 0.6, "col": Color("d9c27a")})
	if tree.has("ta_eye"):
		add_cp(2)

func near_own_wall(reach: float) -> bool:
	for fd in fields:
		if fd.kind == "wall" and fd.pos.distance_to(p.pos) < reach + 24.0:
			return true
	return false

func trap_cap() -> int:
	return (4 if tree.get("trapper", 0) >= 3 else 3) + (3 if tree.has("cl_field") else 0)

func hunter_block(id: String) -> bool:
	match id:
		"sic":
			return pet_up() == null or foe_near(aim_point(180.0), 90.0, []) == null
		"hunt":
			return foe_near(aim_point(180.0), 100.0, []) == null
	return false

func update_hunter(dt: float) -> void:
	if uses_focus() and p.state != "dead":
		if p.hunt_all > 0.0:
			p.hunt_all -= dt
			p.focused = true
			for f in foes:
				if f.state != "dead" and f.pos.distance_to(p.pos) < 220.0:
					f.hunt = maxf(f.get("hunt", 0.0), 0.5)
		var rate = 1.0 + 0.2 * tree.get("steadyh", 0)
		var walled = tree.has("bv_behind") and near_own_wall(40.0)
		if walled:
			rate *= 2.0
		if walled or foe_near(p.pos, 80.0, []) == null or (tree.has("tl_calm") and blessed()):
			p.focus_t += dt * rate
		else:
			p.focus_t = 0.0
		if p.focus_t >= focus_need() and not p.focused:
			p.focused = true
			Sfx.play("orb", 1.6)
		if tree.has("tp_rhythm"):
			if p.state == "atk" and p.skill == "":
				p.chop_t += dt
				p.idle_t = 0.0
			else:
				p.idle_t += dt
				if p.idle_t > 0.6:
					p.chop_t = 0.0
			if p.chop_t >= 3.0:
				p.chop_t = 0.0
				p.focused = true
	if tree.has("bv_post"):
		if p.moving:
			if p.post:
				p.post = false
				p.shield = maxf(0.0, p.shield - 10.0)
			p.still_t = 0.0
		else:
			p.still_t += dt
			p.post = p.still_t >= 2.0
	else:
		p.post = false
	update_pets(dt)
	update_traps(dt)

func update_pets(dt: float) -> void:
	var n = pet_count()
	while pets.size() < n:
		pets.append({"pos": p.pos + Vector2(-16, 8), "hp": pet_mhp(), "mhp": pet_mhp(), "down": 0.0, "cd": 0.5, "flip": false, "moving": false, "sic_id": -1, "at": 0.0})
	while pets.size() > n:
		pets.pop_back()
	var i = 0
	for pt in pets:
		i += 1
		pt.mhp = pet_mhp()
		pt.hp = minf(pt.hp, pt.mhp)
		pt.at += dt
		pt.moving = false
		if pt.down > 0.0:
			pt.down -= dt
			if pt.down <= 0.0:
				pt.hp = pt.mhp
				pt.pos = p.pos + Vector2(-14 * i, 8)
				burst(pt.pos + Vector2(0, -8), VONG, 8, 60.0)
			continue
		pt.cd -= dt
		if pt.pos.distance_to(p.pos) > 320.0:
			pt.pos = p.pos + Vector2(-14 * i, 8)
		var tg = null
		for f in foes:
			if f.id == pt.sic_id and f.state != "dead":
				tg = f
		if tg == null:
			for f in foes:
				if f.get("hunt", 0.0) > 0.0 and f.state != "dead" and f.state != "spawn" and f.pos.distance_to(p.pos) < 220.0:
					tg = f
		if tg == null:
			tg = foe_near(p.pos, 140.0, [])
		if tg != null:
			var d = tg.pos - pt.pos
			pt.flip = d.x < 0.0
			if d.length() > tg.r + 12.0:
				move_actor(pt, d.normalized() * 125.0 * dt, 3.0)
				pt.moving = true
			elif pt.cd <= 0.0:
				pt.cd = 1.0
				pet_bite(tg, pet_dmg())
		else:
			var home = p.pos + Vector2(-16 * i, 10) - pt.pos
			if home.length() > 10.0:
				pt.flip = home.x < 0.0
				move_actor(pt, home.normalized() * minf(110.0, home.length() * 4.0) * dt, 3.0)
				pt.moving = true

func pet_bite(f: Dictionary, base: float) -> void:
	pet_hit = true
	holy_hit = tree.has("tl_beast")
	hit_foe(f, base, false, 0.0, 0.0)
	holy_hit = false
	pet_hit = false
	add_devo(2.0 if tree.has("tl_pray") else 0.0)
	if f.state == "dead":
		return
	if tree.has("tl_beast"):
		lit(f, 6.0)
	if tree.has("nq_tint") and p.bless_t > 0.0 and p.elem != "" and t >= f.get("tint3_t", 0.0):
		f.tint3_t = t + 3.0
		mark(f, p.elem)
	if tree.has("ta_fang") and f.get("poison", 0) > 0 and t >= f.get("fang_t", 0.0):
		f.fang_t = t + 2.0
		f.poison_t += 2.0
	if tree.has("tp_pack") and p.cry > 0.0:
		p.rage = minf(100.0, p.rage + 3.0)
		p.rage_t = 5.0

func pet_pounce(pt, f: Dictionary, mult: float, hold: float) -> void:
	if pt == null or f == null:
		return
	var at = f.pos - (f.pos - p.pos).normalized() * (f.r + 10.0)
	burst(pt.pos + Vector2(0, -8), VONG, 6, 60.0)
	if free_at(at, 3.0):
		pt.pos = at
	pt.sic_id = f.id
	pt.cd = 0.8
	pt.flip = f.pos.x < pt.pos.x
	pet_bite(f, stats.atk * mult * (1.0 + 0.1 * tree.get("fangs", 0)) * (0.6 if tree.has("pack") else 1.0))
	if hold > 0.0:
		root(f, hold)
	Sfx.play("dash", 1.6)

# a foe's blow lands: a hound biting it is caught in it too
func pets_struck(f: Dictionary, K: Dictionary) -> void:
	var dmg = K.dmg * (1.0 + (zone.mult - 1.0) * 0.7)
	for pt in pets:
		if pt.down <= 0.0 and pt.pos.distance_to(f.pos) < f.r + 22.0:
			pt.hp -= dmg * 0.6
			if tree.has("tl_vow") and p.vow_t > 0.0:
				pt.hp = maxf(pt.hp, 1.0)
			if pt.hp <= 0.0:
				pet_down(pt)

func pet_down(pt: Dictionary) -> void:
	pt.down = 12.0 * (1.0 - 0.25 * tree.get("bond", 0))
	pt.hp = 0.0
	pt.sic_id = -1
	burst(pt.pos + Vector2(0, -8), VONG, 12, 80.0)
	toast("CHÓ SĂN GỤC. NÓ SẼ DẬY SAU %d GIÂY." % int(ceil(pt.down)), VONG)
	if tree.has("hl_reap"):
		add_soul(2)
	if tree.has("hl_stand"):
		add_ghost(pt.pos, pt.down, true)

# Sacrifice with no echo: the hound bursts, falls for 4 seconds, and does not give souls for it
func pet_tithe() -> void:
	var pt = pet_up()
	if pt == null:
		return
	rings.append({"pos": pt.pos, "r": 55.0, "life": 0.35, "max": 0.35, "col": VONG})
	Sfx.play("slam", 1.2)
	for f in foes:
		if f.state != "dead" and f.state != "spawn" and f.pos.distance_to(pt.pos) < 55.0 + f.r:
			hit_foe(f, stats.atk * 1.5, true, 0.05, 2.0)
	pt.down = 4.0
	pt.sic_id = -1

func hunter_cast(id: String) -> void:
	match id:
		"aimed":
			var tg = foe_near(aim_pos(), 40.0, [])
			if tree.has("tp_down") and tg != null and tg.state == "stun":
				fire_arrow()
			else:
				p.state = "aim"
				p.st = 0.0
				p.vel = Vector2.ZERO
				p.aim_need = 0.6 + (0.3 if tree.has("tn_tri") else 0.0)
				if tree.has("cl_aim") and hot():
					p.aim_need *= 0.5
				Sfx.play("tele_hi", 1.4)
		"rain":
			var rp = aim_point(160.0)
			var fd = {"kind": "rain", "pos": rp, "r": 50.0, "t": 3.0, "tick": 0.25}
			for o in fields:
				if o.kind == "fire" and tree.has("tn_burnrain") and Geometry2D.get_closest_point_to_segment(rp, o.a, o.b).distance_to(rp) < 58.0:
					fd.fire = true
				if o.kind == "cover" and tree.has("bv_rain") and o.pos.distance_to(rp) < o.r + 20.0:
					fd.drag = true
			fields.append(fd)
			Sfx.play("spit", 1.2)
		"snare", "mine":
			place_trap(id)
		"sic":
			var sg = foe_near(aim_point(180.0), 90.0, [])
			pet_pounce(pet_up(), sg, 1.6, 1.5 * (2.0 if (tree.has("bv_gate") and sg.get("taunt", 0.0) > 0.0) else 1.0))
		"hunt":
			var hg = foe_near(aim_point(180.0), 100.0, [])
			for o in foes:
				o.hunt = 0.0
			hg.hunt = 10.0
			if tree.has("tl_lit"):
				lit(hg, 10.0)
			if tree.has("hl_curse"):
				curse(hg)
			nums.append({"pos": hg.pos + Vector2(0, -foe_h(hg) - 10), "txt": "DẤU SĂN", "life": 0.8, "col": Sk.MARK_COL.hunt})
			Sfx.play("tele_mid", 1.3)
		"bighunt":
			p.hunt_all = 8.0
			p.focused = true
			for f in foes:
				if f.state != "dead" and f.state != "spawn" and f.pos.distance_to(p.pos) < 220.0:
					f.hunt = 8.0
					if tree.has("tl_lit"):
						lit(f, 8.0)
					if tree.has("hl_curse"):
						curse(f)
			rings.append({"pos": p.pos, "r": 160.0, "life": 0.6, "max": 0.6, "col": Sk.MARK_COL.hunt})
			nums.append({"pos": p.pos + Vector2(0, -52), "txt": "CUỘC SĂN", "life": 1.0, "col": Sk.MARK_COL.hunt})
			Sfx.play("clap", 0.7)

func fire_arrow() -> void:
	use_focus()
	var m = 2.2
	if tree.has("bv_loop") and near_own_wall(40.0):
		m *= 1.3
	if tree.has("tn_focus") and t < p.reso_t:
		m *= 1.2
	if tree.has("ta_shot") and p.cp > 0:
		m *= 1.0 + 0.25 * p.cp
		p.cp = 0
	bolts.append({"pos": p.pos + p.aim * 10.0, "vel": p.aim * 380.0, "life": 0.75, "arrow": true, "hit": [], "mult": m})
	p.vel = -p.aim * 40.0
	shake = maxf(shake, 1.5)
	Sfx.play("spit", 2.0)

# one foe pierced by an aimed arrow (ranged is already on)
func arrow_hit(f: Dictionary, b: Dictionary) -> void:
	var dm = b.mult
	if tree.has("oneshot") and f.hp >= f.mhp - 0.5:
		dm *= 2.0
	var tri = tree.has("tn_tri") and f.get("burn", 0.0) > 0.0 and f.get("chill", 0.0) > 0.0 and f.get("shock", 0.0) > 0.0
	hit_foe(f, stats.atk * dm, true, 0.05, 2.0)
	if tree.has("tl_arrow"):
		heal(stats.mhp * 0.03)
	if f.state != "dead" and tree.has("tn_tint") and p.elem != "":
		mark(f, p.elem)
	if tri:
		rings.append({"pos": f.pos, "r": 50.0, "life": 0.35, "max": 0.35, "col": Color("ffe9a3")})
		Sfx.play("slam", 1.3)
		for o in foes:
			if o == f or o.state == "dead" or o.state == "spawn" or o.pos.distance_to(f.pos) > 50.0 + o.r:
				continue
			hit_foe(o, stats.atk * 1.5, true, 0.04, 2.0)
			for mk in ["burn", "chill", "shock"]:
				mark(o, mk)
	if tree.has("hl_chain") and chain_ids.has(f.id):
		for o in foes:
			if o != f and chain_ids.has(o.id) and o.state != "dead" and not b.hit.has(o.id):
				b.hit.append(o.id)
				zaps.append({"a": f.pos + Vector2(0, -14), "b": o.pos + Vector2(0, -14), "life": 0.3})
				hit_foe(o, stats.atk * dm * 0.6, false, 0.0, 0.0)

func rain_tick(fd: Dictionary) -> void:
	var inside = foes.filter(func(f): return f.state != "dead" and f.state != "spawn" and f.pos.distance_to(fd.pos) < fd.r + f.r)
	if fd.kind == "pool":
		for f in inside:
			if f.get("burn", 0.0) < 1.0:
				mark(f, "burn")
		return
	var cursed = tree.has("hl_rain") and inside.any(func(f): return f.get("curse", 0.0) > 0.0)
	ranged = true
	for f in inside:
		hit_foe(f, stats.atk * 0.4, false, 0.0, 0.0)
		if f.state == "dead":
			continue
		if fd.get("fire", false):
			mark(f, "burn")
		if fd.get("drag", false):
			f.drag = 0.6
		if cursed:
			curse(f)
	ranged = false

func place_trap(kind: String) -> void:
	var pos = p.pos
	var far = tree.get("far", 0)
	if far > 0:
		pos = aim_point(90.0 if far == 1 else 150.0)
	var mine = traps.filter(func(tr): return tr.kind != "soul")
	if mine.size() >= trap_cap():
		traps.erase(mine[0])
	traps.append({"kind": kind, "pos": pos, "arm": 0.4, "t": 8.0 if tree.has("linkup") else 9999.0, "smoke": p.smoke > 0.0 and tree.has("ta_smoke"), "rearm": 1 if (tree.has("tl_trap") and in_holy()) else 0})
	if kind == "snare" and tree.has("ots_traps"):
		var t2 = traps.back().duplicate()
		t2.pos = pos + p.aim.orthogonal() * 16.0
		traps.append(t2)
	Sfx.play("parry", 1.6)

func update_traps(dt: float) -> void:
	for tr in traps.duplicate():
		if not traps.has(tr):
			continue
		tr.arm -= dt
		tr.t -= dt
		if tr.t <= 0.0:
			traps.erase(tr)
			continue
		if tr.arm > 0.0:
			continue
		if foe_near(tr.pos, 38.0 if tr.kind == "mine" else 18.0, []) != null:
			spring_trap(tr, 1.0)

func trap_hit(f: Dictionary, mult: float) -> void:
	var m = mult
	if tree.has("bv_lure") and f.get("taunt", 0.0) > 0.0:
		m *= 1.4
	hit_foe(f, stats.atk * m, true, 0.04, 2.0)

func spring_trap(tr: Dictionary, k: float) -> void:
	if not traps.has(tr):
		return
	traps.erase(tr)
	if tr.get("rearm", 0) > 0:
		var again = tr.duplicate()
		again.rearm = 0
		again.arm = 1.0
		traps.append(again)
	if tr.smoke:
		k *= 1.3
	var caught = false
	match tr.kind:
		"snare":
			var tg = foe_near(tr.pos, 30.0, [])
			if tg != null:
				caught = true
				trap_hit(tg, 1.2 * k)
				if tg.state != "dead":
					var cold = tg.get("chill", 0.0) > 0.0
					root(tg, (3.0 if tree.has("ots_jaw") else 2.0) * (2.0 if t < tg.get("tossed_t", 0.0) else 1.0))
					if tree.has("tn_ice"):
						if cold and not D.FOES[tg.kind].get("big", false):
							stagger(tg, 1.5)
						else:
							mark(tg, "chill")
			Sfx.play("parry", 1.1)
		"mine":
			var mr = 56.0 if tree.has("ots_boom") else 40.0
			rings.append({"pos": tr.pos, "r": mr, "life": 0.3, "max": 0.3, "col": Sk.MARK_COL.burn})
			slam_fx(tr.pos, 32.0)
			Sfx.play("slam", 1.3)
			for o in foes:
				if o.state != "dead" and o.state != "spawn" and o.pos.distance_to(tr.pos) < mr + o.r:
					caught = true
					trap_hit(o, 2.0 * k)
			if tree.has("tn_pool"):
				fields.append({"kind": "pool", "pos": tr.pos, "r": 28.0, "t": 3.0, "tick": 0.0})
		"soul":
			var sg = foe_near(tr.pos, 30.0, [])
			if sg != null:
				root(sg, 1.0)
			burst(tr.pos + Vector2(0, -6), VONG, 8, 60.0)
	if tree.has("cl_trap"):
		add_heat(-10.0)
	if tree.has("cl_field") and tr.kind != "soul" and p.pos.distance_to(tr.pos) < 40.0:
		hurt(stats.atk * 0.5)
	if caught and tree.has("ta_snap"):
		add_cp(1)
	if tree.has("linkup") and tr.kind != "soul":
		for o in traps.duplicate():
			if o.kind != "soul" and o.pos.distance_to(tr.pos) < 100.0:
				spring_trap(o, k)

# called when a foe dies, before it is marked dead
func hunter_kill(f: Dictionary) -> void:
	for pt in pets:
		if pt.sic_id == f.id:
			pt.sic_id = -1
	if f.get("hunt", 0.0) > 0.0 and tree.has("ta_pass"):
		var o = foe_near(f.pos, 150.0, [f.id])
		if o != null:
			o.hunt = 10.0
			add_cp(1)
	if f.get("root", 0.0) > 0.0 and tree.has("hl_soul"):
		traps.append({"kind": "soul", "pos": f.pos, "arm": 0.3, "t": 15.0, "smoke": false})
	f.hunt = 0.0
	f.root = 0.0

func draw_hunter() -> void:
	for fd in fields:
		if fd.kind == "rain":
			var rc = Sk.MARK_COL.burn if fd.get("fire", false) else IVORY
			draw_arc(fd.pos + Vector2(0, -4), fd.r, 0.0, TAU, 32, Color(rc.r, rc.g, rc.b, 0.6), 1.0)
			for i in 10:
				var rx = fd.pos.x + sin(i * 7.3 + floor(t * 6.0) * 1.9) * fd.r * 0.8
				var ry = fd.pos.y + cos(i * 3.1 + floor(t * 6.0) * 2.3) * fd.r * 0.6
				draw_line(Vector2(rx, ry - 10), Vector2(rx + 1, ry - 4), rc, 1.0)
		elif fd.kind == "holy":
			var hc = Sk.MARK_COL.lit
			draw_circle(fd.pos, fd.r, Color(hc.r, hc.g, hc.b, 0.10 if fd.t > 1.0 else 0.05))
			draw_arc(fd.pos, fd.r, 0.0, TAU, 40, Color(hc.r, hc.g, hc.b, 0.7 if fd.t > 1.0 else 0.35), 1.0)
			for i in 4:
				var ha = t * 0.8 + i * TAU / 4.0
				var hp: Vector2 = fd.pos + Vector2.from_angle(ha) * (fd.r - 6.0)
				draw_rect(Rect2(hp.floor() - Vector2(1, 3), Vector2(2, 6)), hc)
				draw_rect(Rect2(hp.floor() - Vector2(3, 1), Vector2(6, 2)), hc)
		elif fd.kind == "pool":
			draw_circle(fd.pos, fd.r * 0.8, Color(0.91, 0.54, 0.18, 0.25 if fd.t > 0.8 else 0.12))
			draw_arc(fd.pos, fd.r, 0.0, TAU, 24, Color(Sk.MARK_COL.burn.r, Sk.MARK_COL.burn.g, Sk.MARK_COL.burn.b, 0.6), 1.0)
	for tr in traps:
		var dim = 0.5 if tr.arm > 0.0 else 1.0
		var tp: Vector2 = tr.pos.floor()
		match tr.kind:
			"snare":
				draw_rect(Rect2(tp + Vector2(-5, -2), Vector2(10, 3)), Color(0.42, 0.33, 0.22, dim))
				for k in 3:
					draw_rect(Rect2(tp + Vector2(-4 + k * 3, -4), Vector2(1, 2)), Color(0.85, 0.82, 0.75, dim))
			"mine":
				draw_circle(tp + Vector2(0, -2), 4.0, Color(0.2, 0.18, 0.16, dim))
				draw_rect(Rect2(tp + Vector2(-1, -3), Vector2(2, 2)), Color(0.88, 0.3, 0.2, dim if int(t * 3.0) % 2 == 0 else dim * 0.4))
			"soul":
				draw_arc(tp + Vector2(0, -2), 5.0, 0.0, TAU, 12, Color(VONG.r, VONG.g, VONG.b, 0.7 * dim), 1.0)
	if p.state == "aim":
		var k = clampf(p.st / p.aim_need, 0.0, 1.0)
		draw_line(p.pos + Vector2(0, -14), p.pos + Vector2(0, -14) + p.aim * (40.0 + 140.0 * k), Color(1.0, 0.95, 0.8, 0.25 + 0.5 * k), 1.0)
	var wt = Art.T.get("wolf_i")
	for pt in pets:
		if pt.down > 0.0 or wt == null:
			continue
		var tex: Texture2D = Art.T["wolf_k"] if (pt.cd > 0.7 and Art.T.has("wolf_k")) else wt
		var psc = 1.05 if tree.has("tl_beast") else 0.7
		var w = int(tex.get_width() * psc)
		var h = int(tex.get_height() * psc)
		var lift = absf(sin(pt.at * 10.0)) * 2.0 if pt.moving else 0.0
		draw_texture_rect(Art.T["shadow"], Rect2(pt.pos.x - 8, pt.pos.y - 3, 16, 6), false)
		draw_texture_rect(tex, Rect2(Vector2(pt.pos.x - w / 2.0, pt.pos.y - h + 3 - lift).floor(), Vector2(-w if pt.flip else w, h)), false, Color(0.62, 0.95, 0.9, 0.95))
		if pt.hp < pt.mhp:
			var bp = Vector2(pt.pos.x - 8, pt.pos.y - h - 2).floor()
			draw_rect(Rect2(bp, Vector2(16, 2)), Color("1a1420"))
			draw_rect(Rect2(bp, Vector2(16 * pt.hp / pt.mhp, 2)), VONG)

# ---------------------------------------------------------------- Priest: devotion, heals, blessings, the holy light
# THÀNH KÍNH 0-100 grows when the Priest's own heals land and while standing on holy ground.
# heal() is only for the Priest's heals; potions, life steal and the scythe go straight to p.hp.

func uses_devo() -> bool:
	return main_m == 21 or (sec() == 21 and has_second())

func add_devo(n: float) -> void:
	if not uses_devo() or n <= 0.0:
		return
	p.devo = minf(100.0, p.devo + n * (1.0 + 0.2 * tree.get("patience", 0)))
	if p.devo >= 100.0 and tree.has("zeal") and p.zeal_t <= 0.0:
		p.zeal_t = 5.0
		nums.append({"pos": p.pos + Vector2(0, -56), "txt": "CUỒNG TÍN", "life": 1.0, "col": Sk.MARK_COL.lit})

func in_holy() -> bool:
	for fd in fields:
		if fd.kind == "holy" and p.pos.distance_to(fd.pos) < fd.r:
			return true
	return false

func blessed() -> bool:
	return p.bless_t > 0.0 and not tree.has("devote")

func lit(f: Dictionary, dur: float) -> void:
	if f.state != "dead":
		f.lit = maxf(f.get("lit", 0.0), dur)

func knell_reach() -> float:
	return 80.0 + 20.0 * tree.get("radiance", 0)

# a Priest heal on yourself
func heal(n: float) -> void:
	if n <= 0.0 or p.state == "dead":
		return
	if tree.has("kn_oath"):
		if p.hp > stats.mhp * 0.5:
			return
		n *= 1.5
	if tree.has("zeal") and p.devo < 50.0:
		return
	n *= 1.0 + 0.08 * tree.get("warm", 0)
	if tree.has("vein"):
		p.hots.append({"left": 4.0, "rate": n * 1.6 / 4.0})
		return
	apply_heal(n)

func apply_heal(n: float) -> void:
	var got = minf(stats.mhp - p.hp, n)
	p.hp += got
	var over = n - got
	if over > 0.0:
		if tree.has("sv_over"):
			add_shield(over)
		elif tree.get("resound", 0) > 0:
			add_shield(minf(over * tree.resound / 3.0, stats.mhp * 0.05))
	if not tree.has("nq_noon"):
		add_devo(got / stats.mhp * 50.0)
	if tree.has("tc_cool"):
		add_heat(-got / stats.mhp * 100.0)

func heal_pets(frac: float, reach: float) -> void:
	for pt in pets:
		if pt.down <= 0.0 and pt.pos.distance_to(p.pos) < reach:
			pt.hp = minf(pt.mhp, pt.hp + pt.mhp * frac)

func holy_burst(at: Vector2, r: float, mult: float, skip_id: int) -> void:
	rings.append({"pos": at, "r": r, "life": 0.35, "max": 0.35, "col": Sk.MARK_COL.lit})
	holy_hit = true
	for o in foes:
		if o.id != skip_id and o.state != "dead" and o.state != "spawn" and o.pos.distance_to(at) < r + o.r:
			hit_foe(o, stats.atk * mult, true, 0.04, 2.0)
	holy_hit = false

func priest_block(id: String) -> bool:
	if id == "seal":
		return foe_near(aim_point(200.0), 70.0, []) == null
	return false

# a fresh holy ground or cover ring next to the other: both stand 3 seconds longer
func join_rings(fd: Dictionary) -> void:
	if not tree.has("sv_ring"):
		return
	for o in fields:
		if o != fd and not o.get("joined", false) and ((o.kind == "holy" and fd.kind == "cover") or (o.kind == "cover" and fd.kind == "holy")) and o.pos.distance_to(fd.pos) < 50.0:
			o.joined = true
			fd.joined = true
			o.t += 3.0
			fd.t += 3.0
			return

func priest_cast(id: String) -> void:
	match id:
		"knell":
			var reach = knell_reach()
			rings.append({"pos": p.pos, "r": reach, "life": 0.45, "max": 0.45, "col": Sk.MARK_COL.lit})
			Sfx.play("clap", 1.5)
			heal(stats.mhp * (0.35 if tree.has("ott_bigheal") else 0.25))
			heal_pets(0.25, reach)
			if tree.has("tc_knell"):
				for d in devices:
					if d.kind == "turret" or d.kind == "drum":
						heal(stats.mhp * 0.05)
						rings.append({"pos": d.pos, "r": 40.0, "life": 0.4, "max": 0.4, "col": Sk.MARK_COL.lit})
			if tree.has("tl_knell"):
				for pt in pets:
					if pt.down > 0.0:
						pt.down = 0.0
						pt.hp = pt.mhp * 0.5
						pt.pos = p.pos + Vector2(-14, 8)
			if tree.has("ch_keep"):
				for gh in ghosts:
					if not gh.get("kept", false) and gh.pos.distance_to(p.pos) < reach:
						gh.kept = true
						gh.t += 5.0
			if tree.has("nq_frost"):
				p.slow = 0.0
			for f in foes:
				if f.state == "dead" or f.state == "spawn" or f.pos.distance_to(p.pos) > reach + f.r:
					continue
				if tree.has("nq_frost"):
					mark(f, "chill")
				if tree.has("sv_knell"):
					f.taunt = maxf(f.get("taunt", 0.0), 2.0)
					if f.state == "idle" or f.state == "home":
						f.state = "chase"
		"holy":
			var fd = {"kind": "holy", "pos": p.pos, "r": 84.0 if tree.has("ott_ground") else 60.0, "t": 8.0 if tree.has("ott_ground") else 6.0, "tick": 0.0}
			fields.append(fd)
			join_rings(fd)
			Sfx.play("orb", 0.6)
		"seal":
			var f = foe_near(aim_point(200.0), 70.0, [])
			zaps.append({"a": p.pos + Vector2(0, -16), "b": f.pos + Vector2(0, -14), "life": 0.25})
			var m = 1.3 * (1.2 if tree.has("ott_brand") else 1.0)
			if tree.has("nq_seal"):
				for mk in ["burn", "chill", "shock"]:
					if f.get(mk, 0.0) > 0.0:
						m *= 1.15
			var casting = f.state == "wind"
			holy_hit = true
			hit_foe(f, stats.atk * m, false, 0.04, 1.5)
			holy_hit = false
			if f.state != "dead":
				lit(f, 10.0 if tree.has("ott_brand") else 6.0)
				var heavy = D.FOES[f.kind].poise > 0.0
				if casting and f.state == "wind" and tree.get("rebuke", 0) >= (2 if heavy else 1):
					stagger(f, 0.8)
					f.cd = D.FOES[f.kind].cd
					nums.append({"pos": f.pos + Vector2(0, -foe_h(f) - 8), "txt": "NGẮT ĐÒN", "life": 0.9, "col": Sk.MARK_COL.lit})
				if tree.has("pq_doom"):
					for o in foes:
						o.doom = 0.0
					f.doom = 8.0
			if p.zeal_t > 0.0:
				p.cds.erase("seal")
			Sfx.play("parry", 1.8)
		"purge":
			var pr = 91.0 if tree.has("ott_cleanse") else 70.0
			rings.append({"pos": p.pos, "r": pr, "life": 0.4, "max": 0.4, "col": Sk.MARK_COL.lit})
			Sfx.play("tele_hi", 1.2)
			holy_hit = true
			for f in foes:
				if f.state == "dead" or f.state == "spawn" or f.pos.distance_to(p.pos) > pr + f.r:
					continue
				var elite = f.get("elite", "") != ""
				hit_foe(f, stats.atk * 1.0, true, 0.05, 2.0)
				f.purge = 4.0
				if elite and tree.has("nq_purge"):
					spark_chain(f.pos, 3, [f.id])
			holy_hit = false
			if tree.has("ch_send"):
				for gh in ghosts.duplicate():
					heal(stats.mhp * 0.1)
					holy_burst(gh.pos, 55.0, 1.5, -1)
				ghosts.clear()
		"bless":
			p.bless_t = 8.0 + tree.get("abide", 0)
			if tree.has("kn_link") and p.cry > 0.0 and not p.linked:
				p.linked = true
				p.cry += 3.0
				p.bless_t += 3.0
			burst(p.pos + Vector2(0, -18), Sk.MARK_COL.lit, 14, 100.0)
			nums.append({"pos": p.pos + Vector2(0, -52), "txt": "CHÚC LÀNH", "life": 0.9, "col": Sk.MARK_COL.lit})
			Sfx.play("orb", 1.2)
		"vow":
			p.vow_t = 5.0 if tree.has("ott_vow") else 3.0
			if tree.has("sv_vow"):
				add_shield(40.0)
			nums.append({"pos": p.pos + Vector2(0, -52), "txt": "LỜI NGUYỆN", "life": 0.9, "col": Sk.MARK_COL.lit})
			Sfx.play("tele_hi", 0.8)
		"vigil":
			var raised = false
			for pt in pets:
				if pt.down > 0.0:
					pt.down = 0.0
					pt.hp = pt.mhp
					pt.pos = p.pos + Vector2(-14, 8)
					raised = true
			if not raised:
				p.vigil_t = 6.0
			rings.append({"pos": p.pos, "r": 90.0, "life": 0.6, "max": 0.6, "col": Sk.MARK_COL.lit})
			nums.append({"pos": p.pos + Vector2(0, -52), "txt": "CANH BA", "life": 1.0, "col": Sk.MARK_COL.lit})
			Sfx.play("clap", 0.5)

func update_priest(dt: float) -> void:
	p.bless_t = maxf(0.0, p.bless_t - dt)
	p.vow_t = maxf(0.0, p.vow_t - dt)
	p.vigil_t = maxf(0.0, p.vigil_t - dt)
	if p.cry <= 0.0 and p.bless_t <= 0.0:
		p.linked = false
	if p.zeal_t > 0.0:
		p.zeal_t -= dt
		if p.zeal_t <= 0.0:
			p.devo = 0.0
	if p.state == "dead":
		return
	if tree.has("ott_saint") and p.devo >= 80.0:
		p.hp = minf(stats.mhp, p.hp + stats.mhp * 0.02 * dt)
	if in_holy():
		var k = 1.0
		if tree.has("nq_fire"):
			for fd in fields:
				if fd.kind == "holy" and p.pos.distance_to(fd.pos) < fd.r:
					for o in fields:
						if o.kind == "fire" and Geometry2D.get_closest_point_to_segment(fd.pos, o.a, o.b).distance_to(fd.pos) < fd.r:
							k = 2.0
		if tree.has("pq_smoke") and p.smoke > 0.0:
			k *= 2.0
		heal(stats.mhp * 0.03 * k * dt)
		add_devo(6.0 * dt)
	for h in p.hots:
		var a = minf(h.left, dt)
		h.left -= dt
		apply_heal(h.rate * a)
	p.hots = p.hots.filter(func(h): return h.left > 0.0)
	if tree.has("nq_cage"):
		for fd in fields:
			if fd.kind == "cage":
				for f in foes:
					if f.state != "dead" and f.pos.distance_to(fd.pos) < fd.r + f.r:
						lit(f, 1.0)
	for f in foes:
		if f.get("lit", 0.0) > 0.0:
			f.lit = maxf(0.0, f.lit - dt)
		if f.get("purge", 0.0) > 0.0:
			f.purge = maxf(0.0, f.purge - dt)
		if f.get("doom", 0.0) > 0.0:
			f.doom = maxf(0.0, f.doom - dt)

# called when a foe dies, before it is marked dead
func priest_kill(f: Dictionary) -> void:
	if f.get("doom", 0.0) > 0.0:
		f.doom = 0.0
		heal(stats.mhp * 0.06)
		add_cp(2)
	if tree.has("ch_ground") and uses_souls():
		for fd in fields:
			if fd.kind == "holy" and f.pos.distance_to(fd.pos) < fd.r + f.r:
				add_soul(1)
				break
	f.lit = 0.0

# ---------------------------------------------------------------- Artificer: heat and devices
# NHIỆT: Artificer skills add heat instead of costing rage. Above 70 devices are 20% stronger; at 100 the kit overheats
# (p.over) and none of its skills can be used. Devices (turrets, mines, the bell machine) deal secondary damage.

func uses_heat() -> bool:
	return main_m == 28 or (sec() == 28 and has_second())

func heat_cap() -> float:
	return 150.0 if tree.has("overdrive") else 100.0

func add_heat(n: float) -> void:
	if not uses_heat() or p.over > 0.0:
		return
	p.heat = clampf(p.heat + n, 0.0, heat_cap())
	if p.heat >= 100.0 and not tree.has("overdrive"):
		p.over = maxf(1.0, 4.0 - 0.5 * tree.get("valve", 0) - (1.0 if tree.has("oks_cool") else 0.0) + (2.0 if tree.has("tk_armor") else 0.0))
		p.over_max = p.over
		burst(p.pos + Vector2(0, -20), Color("ff8a3a"), 16, 110.0)
		nums.append({"pos": p.pos + Vector2(0, -56), "txt": "QUÁ NHIỆT", "life": 1.2, "col": Color("ff8a3a")})
		Sfx.play("break", 0.7)
		if tree.has("tc_cool"):
			add_devo(30.0)

func hot() -> bool:
	return p.heat > hot_line()

func hot_line() -> float:
	return 60.0 if tree.has("oks_hot") else 70.0

func dev_mult() -> float:
	return (1.0 + 0.1 * tree.get("skilled", 0)) * (1.2 if hot() else 1.0) * (1.15 if (tree.has("tc_bless") and p.bless_t > 0.0) else 1.0)

func dev_cap() -> int:
	return (4 if tree.has("oks_four") else 3) - (1 if tree.has("workshop") else 0)

func in_mute(at: Vector2) -> bool:
	for fd in fields:
		if fd.kind == "mute" and at.distance_to(fd.pos) < fd.r:
			return true
	return false

func artificer_block(id: String) -> bool:
	if Sk.NODES[id].get("m", 0) == 28 and p.over > 0.0:
		return true
	if id == "vent":
		return p.heat < 1.0
	return false

func place_device(kind: String, at: Vector2, free: bool) -> Dictionary:
	if not free:
		var mine = devices.filter(func(d): return not d.free)
		var cap = dev_cap()
		if tree.has("kl_puppet"):
			cap = maxi(1, 3 - ghosts.filter(func(gh): return not gh.free).size())
		while mine.size() >= cap and not mine.is_empty():
			device_gone(mine[0])
			mine.remove_at(0)
	var life = (20.0 if kind == "mine" else 12.0) + 3.0 * tree.get("durable", 0)
	if tree.has("tb_sabo"):
		life *= 0.7
	var d = {"kind": kind, "pos": at, "t": life, "cd": 0.3, "arm": 0.4, "first": true, "haste_t": 0.0, "free": free,
		"el": p.elem if tree.has("lc_tint") else "", "follow": tree.has("workshop") and kind != "mine", "range": 150.0}
	if kind != "mine" and tree.has("pl_wall") and near_own_wall(40.0):
		d.t += 3.0
		d.range = 190.0
	if (kind == "turret" or kind == "drum") and tree.has("kl_post"):
		var gh = ghost_near(p.pos)
		if gh != null and gh.pos.distance_to(p.pos) < 60.0:
			ghosts.erase(gh)
			d.follow = true
			burst(gh.pos + Vector2(0, -16), VONG, 10, 70.0)
	devices.append(d)
	if tree.has("oks_four") and not free:
		add_heat(10.0)
	burst(at + Vector2(0, -6), Color("c98a4a"), 6, 60.0)
	return d

func device_gone(d: Dictionary) -> void:
	devices.erase(d)
	burst(d.pos + Vector2(0, -6), Color("8a8a96"), 6, 60.0)
	if d.free:
		return
	var sk = "bellmine" if d.kind == "mine" else "turret"
	if tree.get("salvage", 0) > 0 and p.cds.has(sk):
		p.cds[sk] = maxf(0.01, p.cds[sk] - skill_cd(sk) * 0.25 * tree.salvage)
	if tree.has("kl_scrap") and t >= p.scrap_t and d.t <= 0.0:
		p.scrap_t = t + 4.0
		add_soul(1)

func mine_blast(d: Dictionary, k: float) -> void:
	if not devices.has(d):
		return
	devices.erase(d)
	var times = 1
	if tree.has("lc_cage"):
		for fd in fields:
			if fd.kind == "cage" and d.pos.distance_to(fd.pos) < fd.r:
				times = 2
	var caught = false
	ranged = true
	for n in times:
		rings.append({"pos": d.pos, "r": 40.0, "life": 0.3, "max": 0.3, "col": Color("e0b04a")})
		slam_fx(d.pos, 30.0)
		Sfx.play("slam", 1.5)
		for f in foes:
			if f.state == "dead" or f.state == "spawn" or f.pos.distance_to(d.pos) > 40.0 + f.r:
				continue
			caught = true
			var m = 1.8 * dev_mult() * k * (1.4 if tree.has("oks_mine") else 1.0)
			if f.get("taunt", 0.0) > 0.0:
				if tree.has("pl_lure"):
					m *= 1.5
				if tree.has("cl_mine") and tree.has("bv_lure"):
					m *= 1.4
			var keep = p.sure_crit
			p.sure_crit = tree.has("tb_sabo")
			hit_foe(f, stats.atk * m, true, 0.04, 2.0)
			p.sure_crit = keep
			if f.state == "dead":
				continue
			if not D.FOES[f.kind].get("big", false):
				stagger(f, 0.5)
			if tree.has("cl_mine"):
				root(f, 1.0)
			if tree.has("tc_lit"):
				lit(f, 6.0)
	ranged = false
	if caught and tree.has("cl_mine") and tree.has("ta_snap"):
		add_cp(1)
	if tree.has("tb_smoke") and p.pos.distance_to(d.pos) < 60.0:
		p.smoke = maxf(p.smoke, 1.5)
	if tree.has("cl_trap"):
		add_heat(-10.0)
	if tree.has("cl_field") and p.pos.distance_to(d.pos) < 44.0:
		hurt(stats.atk * 0.5)

func turret_target(d: Dictionary):
	var best = null
	var bd = d.range
	for f in foes:
		if f.state == "dead" or f.state == "spawn":
			continue
		var dist = f.pos.distance_to(d.pos)
		if dist > d.range:
			continue
		if tree.has("cl_mark") and f.get("hunt", 0.0) > 0.0:
			return f
		if tree.has("tk_stun") and f.state == "stun":
			dist -= 1000.0
		if dist < bd:
			bd = dist
			best = f
	return best

func update_devices(dt: float) -> void:
	p.boost_t = maxf(0.0, p.boost_t - dt)
	if p.over > 0.0:
		p.over -= dt
		p.heat = maxf(0.0, 100.0 * p.over / maxf(p.over_max, 0.1))
		if p.over <= 0.0:
			p.heat = 0.0
	elif p.heat > 0.0:
		var cool = 1.0 if p.rage_t > 0.0 else 10.0 * (1.0 + 0.2 * tree.get("radiator", 0))
		p.heat = maxf(0.0, p.heat - cool * dt)
	if p.heat > 100.0 and p.state != "dead":
		p.hp = maxf(1.0, p.hp - stats.mhp * 0.03 * dt)
	if tree.get("toolkit", 0) > 0:
		p.pot_cd = maxf(0.0, p.pot_cd - dt * 0.15 * tree.toolkit)
	# the mute bell
	for fd in fields:
		if fd.kind != "mute":
			continue
		if p.pos.distance_to(fd.pos) < fd.r:
			if tree.has("cl_quiet") and uses_focus():
				p.focused = true
			if tree.has("tb_quiet"):
				p.smoke = maxf(p.smoke, 0.2)
		for f in foes:
			if f.state == "dead" or f.state == "spawn" or f.pos.distance_to(fd.pos) > fd.r + f.r:
				continue
			if f.state == "wind":
				f.state = "chase"
				f.cd = 1.0
				f.amber = false
				nums.append({"pos": f.pos + Vector2(0, -foe_h(f) - 8), "txt": "IM LẶNG", "life": 0.6, "col": Color("d0d0d8")})
			if tree.has("lc_frost") and f.get("chill", 0.0) > 0.0:
				f.chill = maxf(f.chill, 0.5)
			if tree.has("kl_curse"):
				f.curse = maxf(f.get("curse", 0.0), 1.0)
	# the hounds carry a small crossbow while the boost lasts
	if tree.has("cl_pet") and p.boost_t > 0.0:
		p.clpet_t -= dt
		if p.clpet_t <= 0.0:
			p.clpet_t = 1.0
			for pt in pets:
				if pt.down <= 0.0:
					var pf = foe_near(pt.pos, 150.0, [])
					if pf != null:
						bolts.append({"pos": pt.pos, "vel": (pf.pos - pt.pos).normalized() * 300.0, "life": 0.6, "dev": true, "mult": 0.2, "el": "", "crit": false})
	var i = 0
	for d in devices.duplicate():
		if not devices.has(d):
			continue
		i += 1
		var held = tree.has("tc_holy") and in_holy_at(d.pos)
		if not held:
			d.t -= dt
		d.haste_t = maxf(0.0, d.haste_t - dt)
		if d.t <= 0.0:
			device_gone(d)
			continue
		if d.follow:
			var want = p.pos + Vector2.from_angle(t * 1.5 + i * TAU / 3.0) * 26.0
			d.pos = d.pos.lerp(want, minf(1.0, dt * 6.0))
		match d.kind:
			"turret":
				d.cd -= dt
				if d.cd <= 0.0:
					var tg = turret_target(d)
					if tg != null:
						d.cd = 0.5 / (1.3 if d.haste_t > 0.0 else 1.0)
						var m = 0.3 * dev_mult()
						bolts.append({"pos": d.pos, "vel": (tg.pos - d.pos).normalized() * 320.0, "life": 0.7, "dev": true, "mult": m, "el": d.el, "crit": d.first and tree.has("tb_sabo")})
						if tree.has("oks_turret"):
							bolts.append({"pos": d.pos, "vel": (tg.pos - d.pos).normalized().rotated(0.12) * 320.0, "life": 0.7, "dev": true, "mult": m, "el": d.el, "crit": false})
						d.first = false
						Sfx.play("hit", 2.0)
			"drum":
				if p.pos.distance_to(d.pos) < 70.0:
					heal(stats.mhp * 0.02 * dt)
					add_devo(3.0 * dt)
			"mine":
				d.arm -= dt
				if d.arm <= 0.0 and foe_near(d.pos, 26.0, []) != null:
					mine_blast(d, 1.0)
			"bell":
				d.cd -= dt
				for f in foes:
					if f.state != "dead" and f.state != "spawn" and not D.FOES[f.kind].get("big", false) and f.pos.distance_to(d.pos) < 140.0 and f.pos.distance_to(d.pos) > 20.0:
						f.kb = (d.pos - f.pos).normalized() * 70.0
				if d.cd <= 0.0:
					d.cd = 1.0
					rings.append({"pos": d.pos, "r": 70.0, "life": 0.4, "max": 0.4, "col": Color("e0b04a")})
					Sfx.play("clap", 1.8)
					for f in foes:
						if f.state != "dead" and f.state != "spawn" and f.pos.distance_to(d.pos) < 70.0 + f.r:
							hit_foe(f, stats.atk * 1.0 * dev_mult(), false, 0.02, 1.0)

func in_holy_at(at: Vector2) -> bool:
	for fd in fields:
		if fd.kind == "holy" and at.distance_to(fd.pos) < fd.r:
			return true
	return false

# a device bolt reaching a foe (ranged is on)
func dev_bolt_hit(f: Dictionary, b: Dictionary) -> void:
	var m = b.mult
	if tree.has("tk_stun") and f.state == "stun":
		m *= 1.5
	if tree.has("cl_mark") and f.get("hunt", 0.0) > 0.0:
		m *= 1.25
	var keep = p.sure_crit
	p.sure_crit = b.get("crit", false)
	hit_foe(f, stats.atk * m, false, 0.0, 0.0)
	p.sure_crit = keep
	if f.state == "dead":
		return
	if b.get("el", "") != "" and t >= f.get("devmark_t", 0.0):
		f.devmark_t = t + 2.0
		mark(f, b.el)
	if tree.has("tb_venom") and p.venom > 0.0 and t >= f.get("devpois_t", 0.0):
		f.devpois_t = t + 1.0
		poison(f, 1)

func artificer_cast(id: String) -> void:
	match id:
		"turret":
			place_device("drum" if tree.has("tc_drum") else "turret", p.pos + p.aim * 24.0, false)
			Sfx.play("parry", 0.9)
		"bellmine":
			place_device("mine", p.pos + p.aim * 12.0, false)
			Sfx.play("parry", 1.3)
		"vent":
			vent()
		"boost":
			p.boost_t = 5.0
			burst(p.pos + Vector2(0, -20), Color("ff8a3a"), 12, 100.0)
			nums.append({"pos": p.pos + Vector2(0, -52), "txt": "TĂNG ÁP", "life": 0.8, "col": Color("ff8a3a")})
			Sfx.play("dash", 0.6)
		"hook":
			hook_cast()
		"mute":
			var fd = {"kind": "mute", "pos": aim_point(120.0), "r": 84.0 if tree.has("oks_mute") else 60.0, "t": 4.0, "tick": 0.0}
			fields.append(fd)
			if tree.has("tc_purge"):
				for f in foes:
					if f.state != "dead" and f.pos.distance_to(fd.pos) < fd.r + f.r:
						f.purge = 4.0
			Sfx.play("tele_lo", 1.4)
		"bellwork":
			var d = place_device("bell", p.pos + p.aim * 20.0, true)
			d.t = 10.0
			d.follow = false
			nums.append({"pos": p.pos + Vector2(0, -52), "txt": "CỖ MÁY CHUÔNG", "life": 1.0, "col": Color("e0b04a")})
			Sfx.play("slam", 0.6)

func vent() -> void:
	var h = p.heat
	p.heat = 0.0
	var el = p.elem if (tree.has("lc_vent") and p.elem_t > 3.0) else ""
	for k in 14:
		var a = p.aim.rotated(randf_range(-0.8, 0.8))
		parts.append({"pos": p.pos + Vector2(0, -12), "vel": a * randf_range(90, 200), "life": 0.4, "max": 0.4, "col": Color("e8e4dc"), "g": 0.0, "size": 2})
	Sfx.play("spit", 0.3)
	shake = maxf(shake, 2.5)
	var m = 0.03 * h * (1.0 + 0.12 * tree.get("heavy", 0) if tree.has("tk_vent") else 1.0)
	for f in foes:
		if f.state == "dead" or f.state == "spawn":
			continue
		var d = f.pos - p.pos
		if d.length() > (98.0 if tree.has("oks_vent") else 70.0) + f.r or (d.length() > 6.0 and absf(p.aim.angle_to(d)) > 0.9):
			continue
		if tree.has("tk_vent") and D.FOES[f.kind].poise > 0.0:
			f.poise -= stats.atk * m
		hit_foe(f, stats.atk * m, true, 0.05, 2.0)
		if f.state == "dead":
			if tree.has("kl_reap"):
				add_soul(1)
			continue
		if el != "":
			mark(f, el)
		if el != "chill" and not D.FOES[f.kind].get("fixed", false):
			f.kb = d.normalized() * 240.0
	if tree.has("pl_shield"):
		add_shield(h * 0.5)
	if tree.has("tb_vent") and h > hot_line():
		add_cp(2)

func hook_cast() -> void:
	var at = aim_point(160.0)
	var tg = foe_near(at, 30.0, [])
	zaps.append({"a": p.pos + Vector2(0, -14), "b": at + Vector2(0, -14), "life": 0.2})
	Sfx.play("dash", 1.2)
	if tree.has("tk_pull"):
		p.hookslam_t = t + 2.0
	if tg == null and tree.has("tc_hook"):
		for pt in pets:
			if pt.down <= 0.0 and pt.pos.distance_to(at) < 30.0:
				pt.pos = p.pos + Vector2(-14, 8)
				pt.hp = minf(pt.mhp, pt.hp + pt.mhp * 0.1)
				return
	if tg == null:
		# no foe there: the hook pulls you to the point, stopping at walls
		var step = (at - p.pos) / 12.0
		for k in 12:
			move_actor(p, step, 4.0)
		p.inv = maxf(p.inv, 0.2)
		return
	p.hook_t = t
	var light = D.FOES[tg.kind].poise <= 0.0 and not D.FOES[tg.kind].get("big", false)
	if light:
		var pulled = [tg]
		if tree.has("kl_chain") and chain_ids.has(tg.id):
			for o in foes:
				if o != tg and chain_ids.has(o.id) and o.state != "dead" and D.FOES[o.kind].poise <= 0.0 and not D.FOES[o.kind].get("big", false):
					pulled.append(o)
		var k = 0
		for o in pulled:
			var from = o.pos
			var dest = p.pos + (o.pos - p.pos).normalized().rotated(0.5 * k) * (o.r + 14.0)
			k += 1
			if free_at(dest, o.r * 0.6):
				o.pos = dest
			stagger(o, 0.3)
			if tree.has("cl_hook"):
				for tr in traps.duplicate():
					if Geometry2D.get_closest_point_to_segment(tr.pos, from, o.pos).distance_to(tr.pos) < 20.0:
						traps.erase(tr)
						trap_hit(o, 2.0 if tr.kind == "mine" else 1.2)
						if tr.kind == "snare" and o.state != "dead":
							root(o, 2.0)
	else:
		var dest = tg.pos - (tg.pos - p.pos).normalized() * (tg.r + 14.0)
		if tree.has("tb_hook"):
			dest = tg.pos + Vector2(1.0 if tg.flip else -1.0, 0.0) * (tg.r + 14.0)
			add_cp(1)
		if free_at(dest, 4.0):
			p.pos = dest
		p.state = "idle"
		p.vel = Vector2.ZERO
		p.inv = maxf(p.inv, 0.2)

func draw_artificer() -> void:
	for fd in fields:
		if fd.kind == "mute":
			var mc = Color("d0d0d8")
			draw_arc(fd.pos + Vector2(0, -4), fd.r, 0.0, TAU, 40, Color(mc.r, mc.g, mc.b, 0.6 if fd.t > 1.0 else 0.3), 1.0)
			for k in 3:
				var rr = fmod(t * 30.0 + k * 20.0, fd.r)
				draw_arc(fd.pos + Vector2(0, -4), rr, 0.0, TAU, 24, Color(mc.r, mc.g, mc.b, 0.25 * (1.0 - rr / fd.r)), 1.0)
	for d in devices:
		var dp: Vector2 = d.pos.floor()
		var blink = d.t > 2.0 or int(t * 8.0) % 2 == 0
		if not blink:
			continue
		match d.kind:
			"turret", "drum":
				draw_texture_rect(Art.T["shadow"], Rect2(dp.x - 7, dp.y - 3, 14, 6), false)
				draw_rect(Rect2(dp + Vector2(-4, -10), Vector2(8, 10)), Color("5a4a3a"))
				draw_rect(Rect2(dp + Vector2(-3, -9), Vector2(6, 2)), Color("c98a4a") if d.kind == "turret" else Color("fff0b0"))
				if d.kind == "turret":
					draw_rect(Rect2(dp + Vector2(-6, -14), Vector2(12, 3)), Color("8a6a42"))
					draw_rect(Rect2(dp + Vector2(-1, -15), Vector2(2, 5)), IVORY)
				else:
					draw_circle(dp + Vector2(0, -14), 4.0, Color("c98a4a"))
					draw_arc(dp + Vector2(0, -14), 6.0 + 2.0 * sin(t * 4.0), 0.0, TAU, 16, Color(1.0, 0.94, 0.69, 0.5), 1.0)
				if hot():
					draw_rect(Rect2(dp + Vector2(-1, -12), Vector2(2, 2)), Color("ff8a3a"))
			"mine":
				draw_circle(dp + Vector2(0, -3), 4.0, Color(0.3, 0.26, 0.2, 0.6 if d.arm > 0.0 else 1.0))
				draw_rect(Rect2(dp + Vector2(-1, -6), Vector2(2, 2)), Color("e0b04a"))
			"bell":
				draw_texture_rect(Art.T["shadow"], Rect2(dp.x - 10, dp.y - 3, 20, 7), false)
				draw_rect(Rect2(dp + Vector2(-6, -8), Vector2(12, 8)), Color("5a4a3a"))
				draw_circle(dp + Vector2(0, -16), 7.0, Color("c9a04a"))
				draw_rect(Rect2(dp + Vector2(-1, -10), Vector2(2, 3)), Color("3a2a1a"))

# ---------------------------------------------------------------- bows
# With a bow the chain of strikes is a chain of arrows: the same timing, the third arrow goes through.
# Melee-only nodes (the chain's last-hit effects on a swing arc, spit parrying) do not apply to arrows.

func fire_basic() -> void:
	var last = p.idx == chain_len() - 1
	var m = ATK[p.idx][3] * 0.8 * p.mult
	if last:
		m *= 1.0 + 0.12 * tree.get("heavy", 0)
	var reach = stats.reach + 3.0 * tree.get("reach", 0)
	bolts.append({"pos": p.pos + p.aim * 10.0, "vel": p.aim * 340.0, "life": 0.55 + reach / 340.0, "shot": true, "pierce": last,
		"hit": [], "mult": m, "zap": p.zap, "crit": p.sure_crit, "cp": false, "last": last})
	p.sure_crit = false
	Sfx.play("spit", 1.8 + p.idx * 0.1)

func shot_hit(f: Dictionary, b: Dictionary) -> void:
	var behind = is_behind(f)
	var soft = f.state == "stun" or f.get("chill", 0.0) > 0.0
	var m = b.mult
	if behind:
		m *= 1.0 + 0.08 * tree.get("backstab", 0)
	var keep = p.sure_crit
	p.sure_crit = b.crit
	hit_foe(f, stats.atk * m, b.last, 0.03, 1.5 if b.last else 1.0)
	p.sure_crit = keep
	p.rage = minf(100.0, p.rage + (14.0 if b.last else 8.0) * (1.0 + stats.rage / 100.0))
	p.rage_t = 5.0
	if not b.cp and (behind or soft or p.surecp):
		b.cp = true
		p.surecp = false
		add_cp(1)
	if f.state == "dead":
		if b.last and tree.has("kt_reap"):
			add_soul(1)
		return
	if p.venom > 0.0:
		poison(f, 1)
	if b.last and has_uniq("forge"):
		mark(f, "burn")
	if b.zap:
		mark(f, "shock")
	if tree.has("tempest") and p.elem_t > 0.0:
		mark(f, p.elem)
	if tree.has("tk_chop"):
		add_heat(-8.0 if b.last else -3.0)
	if b.last and tree.has("kn_strike"):
		add_devo(8.0)

# ---------------------------------------------------------------- chapter three
# a foe's way of fighting: its own kind, or the kind named by "ai" in data.gd
func ai(f: Dictionary) -> String:
	return D.FOES[f.kind].get("ai", f.kind)

# ---------------------------------------------------------------- chapter five
func tp_maw_voice() -> Vector2:
	return Vector2(44 * TS, 22 * TS)

# ---------------------------------------------------------------- the Counting Lighthouse (a secret, no one gives it)
# It blinks a number that drops by one every real day. Look at it on two different days and its keeper shows.
func lighthouse_pos() -> Vector2:
	for th in zone.things:
		if th.id == "lighthouse":
			return th.pos
	return Vector2.ZERO

func lighthouse() -> void:
	var day = int(Time.get_unix_time_from_system() / 86400.0)
	var key = str(day)   # strings survive the JSON save unchanged
	var seen: Array = flags.get("lh_days", [])
	if not seen.has(key):
		seen.append(key)
	flags["lh_days"] = seen
	var count = maxi(0, 21000 - day)
	var lines = ["NGỌN ĐÈN TRÊN THÁP CHỚP MỘT DÃY DÀI, NGẮN. BẠN ĐẾM ĐƯỢC MỘT CON SỐ: %d." % count]
	if flags.has("lamp"):
		lines = ["THÁP ĐÈN TỐI." if flags.lamp == 0 else "NGỌN ĐÈN VẪN CHỚP THEO NHỊP CỦA ÔNG GIÀ: %d." % count]
	elif seen.size() >= 2:
		lines.append("HÔM QUA NÓ CHỚP MỘT SỐ KHÁC. CÓ AI ĐÓ TRÊN ĐỈNH THÁP ĐANG ĐẾM.")
		if not zone.things.any(func(th): return th.id == "lamp_keeper"):
			zone.things.append({"id": "lamp_keeper", "pos": lighthouse_pos() + Vector2(0, 10), "h": 40.0})
	else:
		lines.append("KHÔNG CÓ TÀU NÀO. KHÔNG CÓ NƯỚC. NGỌN ĐÈN VẪN CHỚP.")
	say("NGỌN HẢI ĐĂNG GIỮA ĐẤT KHÔ", "", lines, "", "")

# ---------------------------------------------------------------- the Eight Mute Clappers
# Only the next clapper in the chain speaks (flags.mutes counts those heard). The eighth gives the charm.
func mute_clapper(k: int) -> void:
	var n = int(flags.get("mutes", 0))
	var lines = []
	if k == n + 1:
		flags["mutes"] = k
		var M = D.MUTES[k - 1]
		lines = ["BẠN GÕ VÀO CHIẾC MÕ GỖ. NÓ KHÔNG KÊU. NHƯNG MẢNH CHUÔNG TRONG NGỰC BẠN NGHE THẤY MỘT GIỌNG, ÂM GỐC %s. (%d/8)" % [M[0], k], M[1]]
		if M[2] != "":
			lines.append(M[2])
		Sfx.play("clap", 0.5 + 0.1 * k)
		if k == 8:
			lines.append("TÁM CHIẾC MÕ ĐÃ NÓI XONG. CHIẾC CUỐI CÙNG RỜI KHỎI GIÁ, NHẸ NHƯ MỘT CHIẾC LÁ, VÀ NẰM GỌN TRONG TAY BẠN.")
			drop(p.pos + Vector2(0, 10), "item", 0, D.eight_unique())
		save_game()
	elif k <= n:
		lines = ["CHIẾC MÕ ĐÃ NÓI HẾT NHỮNG GÌ NÓ GIỮ."]
	else:
		lines = ["MỘT CHIẾC MÕ GỖ CŨ, KHẮC TAY. GÕ VÀO KHÔNG KÊU. CÓ LẼ NÓ ĐANG CHỜ MỘT CHIẾC KHÁC NÓI TRƯỚC."]
	say("MÕ CÂM", "", lines, "", "")

# ---------------------------------------------------------------- the Echo Tide (endgame)
# Once the bell is silent, echoes rise and fall with the days: tide 1 to 5. The dungeons already cleared feel it:
# foes are stronger, elites more common, loot more frequent.
const TIDE_ZONES = ["dungeon", "heart", "fleet", "foundry", "archive"]

func tide_level() -> int:
	var day = int(Time.get_unix_time_from_system() / 86400.0)
	return [1, 2, 3, 4, 5, 4, 3, 2][day % 8]

func tide_zone() -> void:
	if qs.get("m26", "") != "done" or not TIDE_ZONES.has(zone.id):
		return
	zone.tide = tide_level()
	zone.mult *= 1.0 + 0.15 * zone.tide
	toast("TRIỀU VỌNG MỨC %d: QUÁI MẠNH HƠN, ĐỒ RƠI NHIỀU HƠN." % zone.tide, VONG)

# ---------------------------------------------------------------- tone stones
# set the stone at bag cell i into the first worn item with a free socket: weapon, then armour, then charm
func set_rune(i: int) -> void:
	var r = inv[i]
	for slot in D.SLOTS:
		var it = eq[slot]
		if it == null:
			continue
		var held: Array = it.get("runes", [])
		if held.size() < D.sockets(it):
			held.append(r.rune)
			if held.count(r.rune) == 2 and not it.has("bonus"):
				it.bonus = D.RUNE_BONUS[r.rune][randi() % 3].duplicate()
				toast("HAI %s CỘNG HƯỞNG: %s." % [r.name, D.STAT_NAME[it.bonus.keys()[0]]], Color("9fe3e0"))
			it.runes = held
			inv.remove_at(i)
			recompute()
			toast("%s GHÉP VÀO %s." % [r.name, it.name], Color("9fe3e0"))
			Sfx.play("orb", 0.8)
			return
	toast("KHÔNG MÓN NÀO ĐANG MẶC CÒN Ô TRỐNG.", Color("ff9a8a"))
	Sfx.play("deny")

# which chapter the story is in (0 to 4), counted from the main quests done
func chapter() -> int:
	for q in [["m26", 5], ["m21", 4], ["m16", 3], ["m11", 2], ["m6", 1]]:
		if qs.get(q[0], "") == "done":
			return q[1]
	return 0

# ---------------------------------------------------------------- reforging
# cell: 0..BAG-1 a bag cell, BAG..BAG+2 a worn slot (the same numbering as the inventory cursor)
func item_at(cell: int):
	if cell >= BAG:
		return eq[D.SLOTS[cell - BAG]]
	return inv[cell] if cell >= 0 and cell < inv.size() else null

func salvage(cell: int) -> void:
	var it = item_at(cell)
	if it == null or cell >= BAG or it.slot == "rune" or it.uniq != "":
		toast("CHỈ RÃ ĐƯỢC ĐỒ THƯỜNG, PHÉP HAY HIẾM TRONG TÚI.", Color("ff9a8a"))
		Sfx.play("deny")
		return
	var n = D.salvage_of(it)
	scrap += n
	inv.remove_at(cell)
	toast("RÃ %s: +%d XỈ ĐỒNG." % [it.name, n], Color("c98a4a"))
	Sfx.play("break", 1.4)

func reforge(cell: int) -> void:
	var it = item_at(cell)
	if it == null or it.slot == "rune":
		Sfx.play("deny")
		return
	if int(it.get("plus", 0)) >= D.PLUS_MAX:
		toast("MÓN NÀY ĐÃ RÈN TỚI +%d." % D.PLUS_MAX, Color("ff9a8a"))
		Sfx.play("deny")
		return
	var cost = D.reforge_cost(it)
	if scrap < cost[0] or gold < cost[1]:
		toast("CẦN %d XỈ ĐỒNG VÀ %d VÀNG." % [cost[0], cost[1]], Color("ff9a8a"))
		Sfx.play("deny")
		return
	scrap -= cost[0]
	gold -= cost[1]
	it.plus = int(it.get("plus", 0)) + 1
	recompute()
	toast("%s RÈN LÊN +%d." % [it.name, it.plus], Color("ffe9a3"))
	Sfx.play("slam", 1.6)

# how many pieces of each set are worn
func set_counts() -> Dictionary:
	var n = {}
	for slot in D.SLOTS:
		var it = eq[slot]
		if it != null and it.has("set"):
			n[it.set] = n.get(it.set, 0) + 1
	return n

# ---------------------------------------------------------------- how each skill is cast
# Swings, dashes and the aimed shot have their own motion. Every other skill falls in one of five casting gestures.
const CAST_ANIM = {
	"roar": ["cry", "taunt", "bighunt", "boost"],
	"pray": ["summon", "sacrifice", "soulform", "night", "knell", "holy", "bless", "vow", "vigil", "raise", "bronze", "bellwork"],
	"kneel": ["snare", "mine", "turret", "bellmine", "wall", "cover"],
	"throw": ["darts", "seal", "hook", "sic", "hunt", "weaken", "chain", "mute", "purge", "vent", "rain", "venom", "smoke", "verdict"],
}

func cast_kind(id: String) -> String:
	if Sk.NODES[id].has("el"):
		return "channel"
	for k in CAST_ANIM:
		if CAST_ANIM[k].has(id):
			return k
	return "throw"

# starts the gesture and its burst of light
func cast_fx(id: String) -> void:
	var k = cast_kind(id)
	p.cast_kind = k
	p.cast_t = 0.35
	var col = Color("ffe9a3")
	match k:
		"channel":
			col = Sk.MARK_COL[Sk.NODES[id].el]
			rings.append({"pos": p.pos, "r": 20.0, "life": 0.3, "max": 0.3, "col": col})
			for i in 8:
				parts.append({"pos": p.pos + Vector2(randf_range(-8, 8), -randf_range(4, 24)), "vel": Vector2(0, -randf_range(30, 60)), "life": 0.4, "max": 0.4, "col": col, "g": 0.0, "size": 2})
		"roar":
			rings.append({"pos": p.pos, "r": 46.0, "life": 0.3, "max": 0.3, "col": col})
			shake = maxf(shake, 1.5)
		"pray":
			col = VONG if Sk.NODES[id].get("m", 0) in [6, 25, 32] else Color("fff0b0")
			rings.append({"pos": p.pos, "r": 26.0, "life": 0.45, "max": 0.45, "col": col})
		"kneel":
			col = Color("c98a4a")
			for i in 6:
				parts.append({"pos": p.pos + Vector2(randf_range(-10, 10), -2), "vel": Vector2(randf_range(-30, 30), -randf_range(10, 30)), "life": 0.3, "max": 0.3, "col": Color("8d7c5e"), "g": 160.0, "size": 2})
		"throw":
			parts.append({"pos": p.pos + p.aim * 10.0 + Vector2(0, -16), "vel": p.aim * 80.0, "life": 0.2, "max": 0.2, "col": IVORY, "g": 0.0, "size": 2})
