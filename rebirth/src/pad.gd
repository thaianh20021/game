extends RefCounted
# Gamepad support. Twin-stick layout with auto-aim when the right stick is idle.
#   left stick move, right stick aim (also fires when pushed far), RT fire, A dash,
#   LB skill one, RB skill two, R3 or d-pad up burst, B item, Y swap, X interact, START pause.
# Player 1 uses keyboard and mouse plus the first pad; player 2 uses the second pad
# (or the first one, when "one gamepad plays player 2" is switched on).

const BTN = {
	JOY_BUTTON_A: KEY_SPACE, JOY_BUTTON_B: KEY_C, JOY_BUTTON_X: KEY_E, JOY_BUTTON_Y: KEY_Q,
	JOY_BUTTON_LEFT_SHOULDER: "m2", JOY_BUTTON_RIGHT_SHOULDER: KEY_F,
	JOY_BUTTON_RIGHT_STICK: KEY_R, JOY_BUTTON_DPAD_UP: KEY_R,
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
