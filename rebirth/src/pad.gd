extends RefCounted
# Gamepad support. Twin-stick layout with auto-aim when the right stick is idle.
#   left stick move, right stick aim (also fires when pushed far), RT fire, A dash,
#   LB skill one, RB skill two, R3 or d-pad up burst, B item, Y swap, X interact, START pause.
# Player 1 uses keyboard and mouse plus the first pad; player 2 uses the second pad
# (or the first one, when "one gamepad plays player 2" is switched on).

const BTN = {
	JOY_BUTTON_A: KEY_SPACE, JOY_BUTTON_B: KEY_TAB, JOY_BUTTON_X: KEY_E, JOY_BUTTON_Y: KEY_Q,
	JOY_BUTTON_LEFT_SHOULDER: "m2", JOY_BUTTON_RIGHT_SHOULDER: KEY_F,
	JOY_BUTTON_RIGHT_STICK: KEY_R, JOY_BUTTON_DPAD_UP: KEY_R,
	JOY_BUTTON_DPAD_LEFT: KEY_1, JOY_BUTTON_DPAD_DOWN: KEY_2, JOY_BUTTON_DPAD_RIGHT: KEY_3,
}
const MENU = {
	JOY_BUTTON_A: KEY_ENTER, JOY_BUTTON_B: KEY_ESCAPE, JOY_BUTTON_X: KEY_E, JOY_BUTTON_Y: KEY_Q, JOY_BUTTON_START: KEY_ESCAPE,
	JOY_BUTTON_DPAD_UP: KEY_UP, JOY_BUTTON_DPAD_DOWN: KEY_DOWN, JOY_BUTTON_DPAD_LEFT: KEY_LEFT, JOY_BUTTON_DPAD_RIGHT: KEY_RIGHT,
}

static func device_for(g, idx: int) -> int:
	var ps = Input.get_connected_joypads()
	ps.sort()
	if g.pad_p2_first:
		return ps[0] if (idx == 1 and ps.size() > 0) else -1
	return ps[idx] if idx < ps.size() else -1

static func handle(g, ev: InputEvent) -> void:
	if ev is InputEventJoypadButton:
		if ev.pressed:
			if not g.pad_jp.has(ev.device):
				g.pad_jp[ev.device] = {}
			g.pad_jp[ev.device][ev.button_index] = true
			g.pad_used = true
			if ev.device == device_for(g, 0):
				g.p1_pad = true
	elif ev is InputEventJoypadMotion:
		if absf(ev.axis_value) > 0.5 and ev.device == device_for(g, 0):
			g.p1_pad = true
			g.pad_used = true

static func stick(dev: int, ax: int, ay: int, dead: float) -> Vector2:
	var v = Vector2(Input.get_joy_axis(dev, ax), Input.get_joy_axis(dev, ay))
	return v.limit_length(1.0) if v.length() > dead else Vector2.ZERO

# The input of one pad for one player, in the same shape a remote player sends.
static func read(g, pl: Dictionary, dev: int) -> Dictionary:
	var pc: Vector2 = pl.pos + Vector2(0, -3)
	var out = {mv = Vector2.ZERO, mw = pc + pl.aim * 80.0, fire = false, jp = {}}
	if dev == -1:
		return out
	out.mv = stick(dev, JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, 0.25)
	var aim = stick(dev, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, 0.35)
	var dir: Vector2 = pl.aim
	if aim != Vector2.ZERO:
		dir = aim.normalized()
	else:
		var e = g.nearest_enemy(pc, 190.0, [])
		if e != null:
			dir = (g.center(e) - pc).normalized()
		elif out.mv != Vector2.ZERO:
			dir = out.mv.normalized()
	out.mw = pc + dir * 80.0
	out.fire = Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_RIGHT) > 0.3 or aim.length() > 0.8
	if Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_LEFT) > 0.5:
		if not g.pad_lt.get(dev, false):
			out.jp[KEY_SPACE] = true
		g.pad_lt[dev] = true
	else:
		g.pad_lt[dev] = false
	for b in g.pad_jp.get(dev, {}):
		if BTN.has(b):
			out.jp[BTN[b]] = true
	out.elh = Input.is_joy_button_pressed(dev, JOY_BUTTON_B) or Input.is_joy_button_pressed(dev, JOY_BUTTON_DPAD_LEFT) or Input.is_joy_button_pressed(dev, JOY_BUTTON_DPAD_DOWN) or Input.is_joy_button_pressed(dev, JOY_BUTTON_DPAD_RIGHT)
	return out

# Once per frame: turns pad presses into menu keys, pause, and "player 2 joins".
static func frame(g) -> void:
	var d2 = device_for(g, 1)
	for dev in g.pad_jp:
		var pressed: Dictionary = g.pad_jp[dev]
		if g.state == "play":
			if pressed.has(JOY_BUTTON_START):
				if dev == d2 and g.in_lobby and not g.local2 and g.net.mode == "":
					g.set_local2(true)
				else:
					g.jp[KEY_ESCAPE] = true
			if g.in_lobby and dev != d2:
				for b in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
					if pressed.has(b):
						g.jp[MENU[b]] = true
		else:
			for b in pressed:
				if MENU.has(b):
					g.jp[MENU[b]] = true
	# flicking the left stick also moves through menus
	if g.state != "play":
		for dev in Input.get_connected_joypads():
			var v = stick(dev, JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, 0.6)
			var dirn = 0
			if v != Vector2.ZERO:
				dirn = (1 if v.x > 0.0 else 2) if absf(v.x) > absf(v.y) else (3 if v.y > 0.0 else 4)
			if dirn != g.pad_flick.get(dev, 0):
				g.pad_flick[dev] = dirn
				if dirn > 0:
					g.jp[[KEY_RIGHT, KEY_LEFT, KEY_DOWN, KEY_UP][dirn - 1]] = true

# Player two on the same keyboard: arrows move, aim is automatic.
#   L or numpad 0 fire, K or numpad Enter dash, I / O skills, P burst, U item, J interact, H swap.
const KB2 = {
	KEY_K: KEY_SPACE, KEY_KP_ENTER: KEY_SPACE, KEY_I: "m2", KEY_KP_1: "m2", KEY_O: KEY_F, KEY_KP_2: KEY_F,
	KEY_P: KEY_R, KEY_KP_3: KEY_R, KEY_U: KEY_C, KEY_KP_4: KEY_C, KEY_J: KEY_E, KEY_KP_5: KEY_E, KEY_H: KEY_Q, KEY_KP_6: KEY_Q, KEY_Y: KEY_TAB, KEY_KP_7: KEY_1, KEY_KP_8: KEY_2, KEY_KP_9: KEY_3,
}

static func read_kb(g, pl: Dictionary) -> Dictionary:
	var pc: Vector2 = pl.pos + Vector2(0, -3)
	var mv = Vector2(
		float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP)))
	if mv != Vector2.ZERO:
		mv = mv.normalized()
	var dir: Vector2 = pl.aim
	var e = g.nearest_enemy(pc, 190.0, [])
	if e != null:
		dir = (g.center(e) - pc).normalized()
	elif mv != Vector2.ZERO:
		dir = mv
	var out = {mv = mv, mw = pc + dir * 80.0, jp = {},
		fire = Input.is_physical_key_pressed(KEY_L) or Input.is_physical_key_pressed(KEY_KP_0)}
	for k in KB2:
		if g.jp.has(k):
			out.jp[KB2[k]] = true
	out.elh = false
	for k in [KEY_Y, KEY_KP_7, KEY_KP_8, KEY_KP_9]:
		if Input.is_physical_key_pressed(k):
			out.elh = true
	return out

# ---- prompts ---------------------------------------------------------------------
# While player one is on a pad every key name on screen becomes the name printed on
# that pad's buttons. Godot numbers buttons by position, so a Nintendo pad swaps letters.

const NAMES = {
	"xbox": {"SPACE": "A", "ENTER": "A", "ESC": "B", "E": "X", "Q": "Y", "RMB": "LB", "F": "RB", "LMB": "RT", "R": "R3"},
	"ps": {"SPACE": "CROSS", "ENTER": "CROSS", "ESC": "CIRCLE", "E": "SQUARE", "Q": "TRIANGLE", "RMB": "L1", "F": "R1", "LMB": "R2", "R": "R3"},
	"nin": {"SPACE": "B", "ENTER": "B", "ESC": "A", "E": "Y", "Q": "X", "RMB": "L", "F": "R", "LMB": "ZR", "R": "R3"},
}
const COMMON = {"WASD": "L-STICK", "MOUSE": "R-STICK", "W/S": "D-PAD", "1 2 3": "D-PAD", "ENTER OR CLICK": "", "O": "O"}
static var _rx: RegEx = null
static var _cache = {}

# Which family of pad player one holds: "" (keyboard), "xbox", "ps" or "nin".
static func style(g) -> String:
	if not g.p1_pad:
		return ""
	if g.sim.has("pad_style"):
		return g.sim.pad_style
	var dev = device_for(g, 0)
	if dev == -1:
		return "xbox"
	var n = Input.get_joy_name(dev).to_lower()
	for w in ["ps3", "ps4", "ps5", "playstation", "dualshock", "dualsense", "sony"]:
		if n.contains(w):
			return "ps"
	for w in ["nintendo", "switch", "joy-con", "joycon", "pro controller"]:
		if n.contains(w):
			return "nin"
	return "xbox"

# Name of one key ("E", "SPACE", "RMB"...) on what player one is holding.
static func key_name(g, k: String) -> String:
	var st = style(g)
	return k if st == "" else str(NAMES[st].get(k, k))

# A whole hint line with every key name in it swapped.
static func hint(g, text: String) -> String:
	var st = style(g)
	if st == "":
		return text
	var id = st + text
	if _cache.has(id):
		return _cache[id]
	if _rx == null:
		_rx = RegEx.new()
		_rx.compile("(?<![A-Z0-9])(ENTER OR CLICK|1 2 3|W/S|WASD|MOUSE|SPACE|ENTER|ESC|RMB|LMB|E|Q|F|R)(?![A-Z0-9'])")
	var out = ""
	var at = 0
	for m in _rx.search_all(text):
		var k = m.get_string()
		var rep = str(COMMON[k]) if COMMON.has(k) else str(NAMES[st][k])
		if k == "ENTER OR CLICK":
			rep = str(NAMES[st]["ENTER"])
		out += text.substr(at, m.get_start() - at) + rep
		at = m.get_end()
	out += text.substr(at)
	if _cache.size() > 400:
		_cache.clear()
	_cache[id] = out
	return out
