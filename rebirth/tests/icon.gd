extends SceneTree
# Paints the app icon from code (like every other picture in the game) and saves
#   res://icon.png      192 x 192, rounded, used by the project and old launchers
#   res://icon_fg.png   432 x 432 adaptive foreground (the core and its orbit)
#   res://icon_bg.png   432 x 432 adaptive background
# The picture: the dungeon core, a crystal cut into the four old elements around a white
# heart, with a ring of sparks circling it. Run headless; rerun after changing it.

const G = 48
const OUT = Color("120e18")
const FIRE = Color("ff8a3a")
const BOLT = Color("ffe45c")
const TOX = Color("a6e84e")
const ICE = Color("7adfff")

func bg() -> Image:
	var im = Image.create(G, G, false, Image.FORMAT_RGBA8)
	for y in G:
		for x in G:
			var d = Vector2(x - 23.5, y - 23.5).length() / 34.0
			var c = Color("4a2a7a").lerp(Color("140b24"), clampf(d * 1.15, 0.0, 1.0))
			# stepped bands keep it pixel art instead of a smooth gradient
			var band = floorf(clampf(1.0 - d, 0.0, 1.0) * 6.0) / 6.0
			c = Color("140b24").lerp(Color("55318c"), band * band)
			# faint flagstones
			if (x % 12 == 0 or y % 12 == (6 if (x / 12) % 2 == 0 else 0)) and d > 0.45:
				c = c.darkened(0.18)
			im.set_pixel(x, y, c)
	return im

func put(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < G and y < G:
		im.set_pixel(x, y, c)

func fg(k: float) -> Image:
	var im = Image.create(G, G, false, Image.FORMAT_RGBA8)
	var cx = 23.5
	var cy = 23.5
	var hw = 9.0 * k
	var hh = 13.0 * k
	var rx = 15.5 * k
	var ry = 5.5 * k
	# glow behind the crystal
	for y in G:
		for x in G:
			var d = Vector2((x - cx) / (hw * 1.9), (y - cy) / (hh * 1.5)).length()
			if d < 1.0:
				var a = floorf((1.0 - d) * 4.0) / 4.0 * 0.5
				im.set_pixel(x, y, Color(0.75, 0.6, 1.0, a))
	# back half of the orbit
	ring(im, cx, cy, rx, ry, false)
	# the crystal
	for y in G:
		for x in G:
			var dx = x - cx
			var dy = y - cy
			var m = absf(dx) / hw + absf(dy) / hh
			if m > 1.0:
				continue
			var base = (FIRE if dy < 0 else TOX) if dx < 0 else (BOLT if dy < 0 else ICE)
			var c = base
			if m > 0.86:
				c = OUT
			elif m < 0.22:
				c = Color.WHITE
			elif m < 0.36:
				c = base.lightened(0.6)
			elif absf(dx) < 0.8 or absf(dy) < 0.8:
				c = base.darkened(0.35)  # the cuts between facets
			elif dx > 0:
				c = base.darkened(0.12 + 0.22 * m)
			else:
				c = base.lightened(0.18 * (1.0 - m))
			im.set_pixel(x, y, c)
	# a glint on the upper left facet
	for i in int(3 * k):
		put(im, int(cx - hw * 0.45) + i, int(cy - hh * 0.38) - i, Color.WHITE)
	# front half of the orbit and its four sparks
	ring(im, cx, cy, rx, ry, true)
	var cols = [FIRE, BOLT, ICE, TOX]
	var angs = [2.75, 0.55, -0.45, -2.6]
	for i in 4:
		var p = Vector2(cx + cos(angs[i]) * rx, cy + sin(angs[i]) * ry)
		orb(im, int(round(p.x)), int(round(p.y)), cols[i], 2 if k > 1.1 else 1)
	return im

func ring(im: Image, cx: float, cy: float, rx: float, ry: float, front: bool) -> void:
	for i in 220:
		var a = i / 220.0 * TAU
		if (sin(a) > 0.0) != front:
			continue
		var x = int(round(cx + cos(a) * rx))
		var y = int(round(cy + sin(a) * ry))
		put(im, x, y, Color("fff2ae") if front else Color("8a6ad0"))
		if front:
			put(im, x, y + 1, OUT)

func orb(im: Image, x: int, y: int, c: Color, r: int) -> void:
	for dy in range(-r - 1, r + 2):
		for dx in range(-r - 1, r + 2):
			var d = absi(dx) + absi(dy)
			if d <= r - 1:
				put(im, x + dx, y + dy, Color.WHITE if d == 0 else c.lightened(0.3))
			elif d <= r:
				put(im, x + dx, y + dy, c)
			elif d == r + 1:
				put(im, x + dx, y + dy, OUT)

func _initialize():
	var b = bg()
	var back = b.duplicate()
	back.resize(432, 432, Image.INTERPOLATE_NEAREST)
	back.save_png("res://icon_bg.png")
	var f = fg(1.0)
	var front = f.duplicate()
	front.resize(432, 432, Image.INTERPOLATE_NEAREST)
	front.save_png("res://icon_fg.png")
	# the plain icon: bigger crystal, rounded corners, a dark rim
	var big = fg(1.32)
	var full: Image = b.duplicate()
	full.blend_rect(big, Rect2i(0, 0, G, G), Vector2i.ZERO)
	var rad = 10.0
	for y in G:
		for x in G:
			var qx = maxf(0.0, maxf(rad - x - 0.5, x + 0.5 - (G - rad)))
			var qy = maxf(0.0, maxf(rad - y - 0.5, y + 0.5 - (G - rad)))
			var d = Vector2(qx, qy).length()
			if d > rad:
				full.set_pixel(x, y, Color(0, 0, 0, 0))
			elif d > rad - 1.2 or x == 0 or y == 0 or x == G - 1 or y == G - 1:
				full.set_pixel(x, y, OUT)
	full.resize(192, 192, Image.INTERPOLATE_NEAREST)
	full.save_png("res://icon.png")
	print("ICON OK")
	quit()
