extends RefCounted
# Every sprite and tile is painted from code at boot. No asset files.
# Sprites keep a 1 px margin so the outline pass has room.

const TS = 16

static var T = {}   # name -> ImageTexture
static var W = {}   # name -> white silhouette (hit flash, dissolve)
static var I = {}   # tile images used when baking the map
static var OUT = Color("1a1420")

static var TH = ""       # tile theme being painted ("" is the marsh)
static var REMAP = {}    # that theme's colour swaps

# The Breathing Forest: deeper greens, dark loam, teal water, purple flowers.
const THEMES = {
	"forest": {
		"5b7b4a": "2f5d46", "4f6d42": "25503c", "6b8b55": "3f7a5a", "86a565": "58a07a", "6e8e57": "478a66", "47633c": "1f4634",
		"7a6a4f": "4a4a52", "6b5c44": "3e3e47", "8d7c5e": "5c5a66",
		"8b6b45": "7a5f48", "5f4630": "4a3a30", "a17f55": "94775a", "6e5238": "5a4636",
		"2f5560": "1f4a55", "29495a": "1a4050", "4f8a8f": "3fa796", "3d6f77": "2f8a80", "6aa3a6": "63c7b5", "26444e": "183a44",
		"4a3f33": "33402f", "352c26": "232d22", "5d5042": "45553f", "f4ebd0": "b79be0", "c9a227": "7a5c9e",
	},
}

static func c(hex: String) -> Color:
	return Color(REMAP.get(hex, hex))

static func hsh(a: int, b: int, s: int) -> int:
	var n = (a * 374761393 + b * 668265263 + s * 982451653) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	return n ^ (n >> 16)

static func blank(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)

static func px(im: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, col)

static func rect(im: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for j in h:
		for i in w:
			px(im, x + i, y + j, col)

static func ell(im: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var dx = (x - cx) / rx
			var dy = (y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(im, x, y, col)

static func line(im: Image, x0: int, y0: int, x1: int, y1: int, col: Color, th: int = 1) -> void:
	var dx = absi(x1 - x0)
	var dy = -absi(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var e = dx + dy
	while true:
		for k in th:
			px(im, x0 + k, y0, col)
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * e
		if e2 >= dy:
			e += dy
			x0 += sx
		if e2 <= dx:
			e += dx
			y0 += sy

static func outline(im: Image) -> Image:
	var o: Image = im.duplicate()
	var w = im.get_width()
	var h = im.get_height()
	for y in h:
		for x in w:
			if im.get_pixel(x, y).a > 0.1:
				continue
			for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
				var nx = x + d[0]
				var ny = y + d[1]
				if nx >= 0 and ny >= 0 and nx < w and ny < h and im.get_pixel(nx, ny).a > 0.5:
					o.set_pixel(x, y, OUT)
					break
	return o

static func put(name: String, im: Image, ol: bool = true) -> void:
	if ol:
		im = outline(im)
	T[name] = ImageTexture.create_from_image(im)
	var wi = blank(im.get_width(), im.get_height())
	for y in im.get_height():
		for x in im.get_width():
			if im.get_pixel(x, y).a > 0.5:
				wi.set_pixel(x, y, Color.WHITE)
	W[name] = ImageTexture.create_from_image(wi)

static func build() -> void:
	if not T.is_empty():
		return
	load_sprites()
	build_props()
	build_tiles()
	build_icons()
	build_vignette()
	load_optional()

# ---------------------------------------------------------------- characters
# Hero and foes are AI-generated pictures cleaned up by tools/pix.gd into res://assets/.
# Each is one still pose with the feet at the bottom centre; game.gd adds the motion.

const SPRITES = ["tree_giant", "shrooms", "trunk", "hut", "gate", "log", "wolf_i", "wolf_w", "wolf_k", "sower_i", "sower_w", "sower_k", "deer_i", "deer_w", "deer_k",
	"mother_i", "mother_w", "mother_k", "npc_reu", "npc_man", "npc_kid",
	"leech_i", "leech_w", "leech_k", "netter_i", "netter_w", "netter_k", "wisp_i", "wisp_w", "wisp_k", "keeper_i", "keeper_w", "keeper_k",
	"h_idle", "h_w1", "h_w2", "h_w3", "h_wind", "h_slash", "tree_willow", "tree_dead", "boulder", "boat", "fence", "sign", "well", "crates", "cart", "netrack", "shrine", "grave",
	"reed_i", "reed_w", "reed_k", "heron_i", "heron_w", "heron_k", "porter_i", "porter_w", "porter_k",
	"boss_i", "boss_w", "boss_k", "npc_ngai", "npc_kham", "npc_say", "npc_dien", "house_home", "house_shop", "house_hall"]

# ---------------------------------------------------------------- small icons

static func build_icons() -> void:
	var coin = blank(8, 8)
	ell(coin, 3.0, 3.0, 2.2, 2.2, c("ffd24a"))
	px(coin, 2, 2, c("fff2ae"))
	px(coin, 4, 4, c("b8862a"))
	put("coin", coin)
	var pot = blank(8, 11)
	rect(pot, 3, 1, 2, 2, c("c9a674"))
	rect(pot, 2, 3, 4, 1, c("d8e4f0"))
	ell(pot, 3.5, 6.5, 2.4, 2.4, c("b3263a"))
	px(pot, 2, 5, c("f08a9a"))
	put("potion", pot)
	var bag = blank(12, 13)
	ell(bag, 5.5, 7.5, 4.0, 3.8, c("c9b08a"))
	rect(bag, 4, 2, 4, 2, c("c9b08a"))
	rect(bag, 3, 4, 6, 1, c("6b4a2e"))
	px(bag, 4, 6, c("f4ebd0"))
	put("bag", bag)
	var w = blank(18, 18)
	line(w, 3, 14, 13, 4, c("e6edf2"), 2)
	line(w, 12, 3, 14, 3, c("ffffff"))
	line(w, 2, 11, 6, 15, c("c9b08a"))
	px(w, 2, 15, c("8b6b45"))
	put("ic_weapon", w)
	var a = blank(18, 18)
	rect(a, 4, 4, 10, 10, c("d8d2c4"))
	rect(a, 2, 4, 2, 5, c("d8d2c4"))
	rect(a, 14, 4, 2, 5, c("d8d2c4"))
	rect(a, 7, 4, 4, 2, c("3a3046"))
	rect(a, 4, 11, 10, 1, c("9a9488"))
	put("ic_armor", a)
	var ch = blank(18, 18)
	line(ch, 5, 2, 8, 7, c("c9b08a"))
	line(ch, 12, 2, 9, 7, c("c9b08a"))
	ell(ch, 8.5, 11.0, 3.4, 3.6, c("e6edf2"))
	px(ch, 7, 9, c("ffffff"))
	rect(ch, 8, 13, 1, 2, c("9a9488"))
	put("ic_charm", ch)
	# the boss weapon, held like the sword: points right, grip at (4, 4)
	var oar = blank(36, 9)
	rect(oar, 1, 4, 22, 1, c("8b6b45"))
	rect(oar, 1, 3, 22, 1, c("b08a5c"))
	rect(oar, 22, 1, 11, 7, c("a8845a"))
	rect(oar, 22, 1, 11, 2, c("c9a674"))
	rect(oar, 22, 6, 11, 1, c("6e5238"))
	px(oar, 27, 4, c("9fe3e0"))
	px(oar, 30, 3, c("9fe3e0"))
	put("oar", oar)

static func load_sprites() -> void:
	for n in SPRITES:
		var im: Image = (load("res://assets/%s.png" % n) as Texture2D).get_image()
		im.convert(Image.FORMAT_RGBA8)
		if n.begins_with("reed"):
			# pull the reeds back to dry straw; bright amber is too close to a reserved warning colour
			for y in im.get_height():
				for x in im.get_width():
					var px_c = im.get_pixel(x, y)
					if px_c.a > 0.5 and px_c.r > 0.6 and px_c.g > 0.5 and px_c.b < 0.4:
						var g = px_c.get_luminance()
						im.set_pixel(x, y, Color(lerpf(px_c.r, g, 0.3) * 0.86, lerpf(px_c.g, g, 0.3) * 0.84, lerpf(px_c.b, g, 0.3) + 0.12, 1.0))
		put(n, im, false)
	# sword: points right, grip at (4, 4)
	var sw = blank(32, 9)
	rect(sw, 1, 4, 5, 1, c("3a2c2a"))
	rect(sw, 6, 1, 2, 7, c("c8873d"))
	rect(sw, 6, 1, 2, 1, c("f0c070"))
	rect(sw, 8, 3, 19, 3, c("cfd6dc"))
	rect(sw, 8, 3, 19, 1, c("f6fbff"))
	rect(sw, 8, 5, 19, 1, c("8b97a3"))
	rect(sw, 27, 4, 2, 1, c("f6fbff"))
	px(sw, 27, 3, c("cfd6dc"))
	px(sw, 27, 5, c("8b97a3"))
	put("sword", sw)

# ---------------------------------------------------------------- props

static func build_props() -> void:
	# reed clump
	for v in 3:
		var im = blank(18, 26)
		for i in 7:
			var k = hsh(i, v, 11)
			var x0 = 6 + k % 6
			var x1 = x0 + (k >> 3) % 7 - 3
			var top = 3 + (k >> 6) % 9
			var col = [c("86a565"), c("c9a227"), c("6e8e57"), c("9a7b1e")][(k >> 9) % 4]
			line(im, x0, 24, x1, top, col)
			if (k >> 11) % 2 == 0:
				rect(im, x1, top - 3, 1, 4, c("6b4a2e"))
				px(im, x1, top - 4, c("8a6342"))
		put("reeds%d" % v, im)
	# lantern post
	var lp = blank(18, 36)
	rect(lp, 5, 6, 2, 28, c("5f4630"))
	rect(lp, 5, 6, 1, 28, c("7d5e42"))
	rect(lp, 4, 33, 4, 2, c("3d2e22"))
	rect(lp, 5, 6, 9, 2, c("5f4630"))
	rect(lp, 12, 8, 1, 3, c("3d2e22"))
	rect(lp, 10, 11, 5, 1, c("3d2e22"))
	rect(lp, 10, 12, 5, 6, c("f2a65a"))
	rect(lp, 11, 13, 3, 4, c("ffe2a8"))
	rect(lp, 10, 18, 5, 1, c("3d2e22"))
	put("lantern", lp)
	# a pair of sandals left facing the water
	var sd = blank(12, 8)
	ell(sd, 3.5, 3.5, 1.6, 2.6, c("c9a227"))
	ell(sd, 8.0, 3.5, 1.6, 2.6, c("c9a227"))
	rect(sd, 2, 2, 3, 1, c("6b4a2e"))
	rect(sd, 7, 2, 3, 1, c("6b4a2e"))
	put("sandals", sd)
	# stones
	for v in 2:
		var st = blank(14, 11)
		ell(st, 6.5, 6.0, 4.5 + v, 3.2, c("8c8577"))
		ell(st, 5.5, 4.8, 2.6 + v, 1.4, c("b3ac9c"))
		rect(st, 4, 8, 6, 1, c("6a655c"))
		put("stone%d" % v, st)
	# wooden clapper stand: the town signals with wood, never with bells
	var mo = blank(22, 28)
	rect(mo, 3, 4, 2, 22, c("5f4630"))
	rect(mo, 17, 4, 2, 22, c("5f4630"))
	rect(mo, 2, 3, 18, 2, c("7d5e42"))
	rect(mo, 10, 5, 1, 4, c("3d2e22"))
	ell(mo, 10.5, 13.0, 4.5, 4.0, c("a0703c"))
	ell(mo, 9.5, 11.5, 2.5, 1.5, c("c58e52"))
	rect(mo, 8, 14, 6, 1, c("3d2e22"))
	px(mo, 13, 12, c("3d2e22"))
	put("clapper", mo)
	# soft shadow and lantern glow (stepped alpha keeps the pixel look)
	var sh = blank(16, 7)
	ell(sh, 7.5, 3.0, 7.0, 2.8, Color(0.05, 0.04, 0.09, 0.38))
	T["shadow"] = ImageTexture.create_from_image(sh)
	var gl = blank(96, 96)
	for y in 96:
		for x in 96:
			var d = Vector2(x - 47.5, (y - 47.5) * 1.5).length() / 48.0
			if d < 1.0:
				var a = 0.20 if d < 0.35 else (0.13 if d < 0.6 else (0.07 if d < 0.82 else 0.03))
				gl.set_pixel(x, y, Color(1.0, 0.72, 0.38, a))
	T["glow"] = ImageTexture.create_from_image(gl)
	var orb = blank(7, 7)
	ell(orb, 3.0, 3.0, 2.0, 2.0, c("9fe3e0"))
	px(orb, 2, 2, c("f4ffff"))
	put("orb", orb)
	var sp = blank(9, 9)
	ell(sp, 4.0, 4.0, 2.6, 2.6, c("b9b2a3"))
	ell(sp, 3.5, 3.5, 1.2, 1.2, c("f4ebd0"))
	put("spit", sp)

# ---------------------------------------------------------------- tiles

static func speck(im: Image, n: int, col: Color, seed: int) -> void:
	for i in n:
		var k = hsh(i, seed, 5)
		px(im, k % TS, (k >> 5) % TS, col)

static func build_tiles() -> void:
	for v in 4:
		var g = blank(TS, TS)
		g.fill(c("5b7b4a"))
		speck(g, 16, c("4f6d42"), v * 3 + 1)
		speck(g, 9, c("6b8b55"), v * 3 + 2)
		for i in 3:
			var k = hsh(i, v, 31)
			var x = k % TS
			var y = 2 + (k >> 5) % 12
			px(g, x, y, c("86a565"))
			px(g, x, y + 1, c("6e8e57"))
		if v == 3:
			speck(g, 4, c("c9a227"), 77)
		I[TH + "grass%d" % v] = g
	for v in 3:
		var m = blank(TS, TS)
		m.fill(c("7a6a4f"))
		speck(m, 14, c("6b5c44"), v * 5 + 3)
		speck(m, 8, c("8d7c5e"), v * 5 + 4)
		speck(m, 2, c("9a9488"), v * 5 + 6)
		I[TH + "mud%d" % v] = m
	for v in 2:
		var pl = blank(TS, TS)
		pl.fill(c("8b6b45"))
		for y in TS:
			for x in TS:
				if y % 4 == 3:
					pl.set_pixel(x, y, c("5f4630"))
				elif y % 4 == 0:
					pl.set_pixel(x, y, c("a17f55"))
		for r in 4:
			var k = hsh(r, v, 13)
			var jx = k % TS
			rect(pl, jx, r * 4, 1, 3, c("6e5238"))
			px(pl, (jx + 2) % TS, r * 4 + 1, c("4a3a2c"))
		I[TH + "plank%d" % v] = pl
	for f in 2:
		for v in 2:
			var w = blank(TS, TS)
			w.fill(c("2f5560"))
			speck(w, 10, c("29495a"), v + 20)
			for i in 3:
				var k = hsh(i, v, 41)
				var x = (k % TS + f * 2) % TS
				var y = (k >> 5) % TS
				for j in 3:
					px(w, (x + j) % TS, y, c("4f8a8f"))
			speck(w, 1, c("8c8577"), v + 50 + f)
			I[TH + "water%d_%d" % [f, v]] = w
			var wd: Image = w.duplicate()
			for yy in TS:
				for xx in TS:
					wd.set_pixel(xx, yy, wd.get_pixel(xx, yy).darkened(0.16))
			I[TH + "waterd%d_%d" % [f, v]] = wd

# grid[y][x]: 0 water, 1 grass, 2 mud, 3 plank
static func bake(grid: Array, frame: int, theme: String = "") -> ImageTexture:
	# a theme swaps the tile colours; its tiles are painted the first time it is used
	TH = theme
	REMAP = THEMES.get(theme, {})
	if not I.has(TH + "grass0"):
		build_tiles()
	var mh = grid.size()
	var mw = grid[0].size()
	var im = blank(mw * TS, mh * TS)
	for y in mh:
		for x in mw:
			var k = hsh(x, y, 99)
			var t = grid[y][x]
			var src: Image
			match t:
				1: src = I[TH + "grass%d" % (k % 4)]
				2: src = I[TH + "mud%d" % (k % 3)]
				3: src = I[TH + "plank%d" % (k % 2)]
				_: src = I[TH + "water%s%d_%d" % ["d" if deep(grid, x, y) else "", frame, k % 2]]
			im.blit_rect(src, Rect2i(0, 0, TS, TS), Vector2i(x * TS, y * TS))
			var ox = x * TS
			var oy = y * TS
			if t == 1:
				# small flowers and darker tufts break up the lawn
				if k % 19 == 0:
					var fx = ox + 3 + (k >> 6) % 10
					var fy = oy + 3 + (k >> 10) % 10
					px(im, fx, fy, c("f4ebd0") if (k >> 3) % 2 == 0 else c("e8d36b"))
					px(im, fx, fy + 1, c("4f6d42"))
				elif k % 11 == 0:
					var gx = ox + 2 + (k >> 5) % 11
					var gy = oy + 4 + (k >> 9) % 9
					rect(im, gx, gy, 1, 3, c("47633c"))
					rect(im, gx + 2, gy + 1, 1, 2, c("47633c"))
					px(im, gx + 1, gy - 1, c("86a565"))
			elif t == 2 or t == 3:
				# grass creeps over the edge of paths and planks, hiding the tile grid
				var gcol = [c("5b7b4a"), c("4f6d42"), c("6b8b55")]
				if y > 0 and grid[y - 1][x] == 1:
					for i in TS:
						var hh = 1 + hsh(ox + i, y, 7) % 3
						rect(im, ox + i, oy, 1, hh, gcol[hsh(ox + i, y, 8) % 3])
				if y + 1 < mh and grid[y + 1][x] == 1:
					for i in TS:
						var hh = 1 + hsh(ox + i, y, 9) % 3
						rect(im, ox + i, oy + TS - hh, 1, hh, gcol[hsh(ox + i, y, 10) % 3])
				if x > 0 and grid[y][x - 1] == 1:
					for i in TS:
						var ww = 1 + hsh(x, oy + i, 11) % 3
						rect(im, ox, oy + i, ww, 1, gcol[hsh(x, oy + i, 12) % 3])
				if x + 1 < mw and grid[y][x + 1] == 1:
					for i in TS:
						var ww = 1 + hsh(x, oy + i, 13) % 3
						rect(im, ox + TS - ww, oy + i, ww, 1, gcol[hsh(x, oy + i, 14) % 3])
			else:
				# a broken line of foam where water meets land
				var foam = c("6aa3a6")
				if x > 0 and grid[y][x - 1] != 0:
					for i in TS:
						if (hsh(x, oy + i, 21) + frame) % 3 != 0:
							px(im, ox, oy + i, foam)
				if x + 1 < mw and grid[y][x + 1] != 0:
					for i in TS:
						if (hsh(x, oy + i, 22) + frame) % 3 != 0:
							px(im, ox + TS - 1, oy + i, foam)
				if k % 29 == 0 and not deep(grid, x, y) and y > 0 and grid[y - 1][x] == 0:
					# lily pad
					ell(im, ox + 7.0, oy + 8.0, 3.0, 2.0, c("4f8a5a"))
					px(im, ox + 6, oy + 7, c("7fb87a"))
					px(im, ox + 9, oy + 8, c("2f5560"))
			if t == 0 and y > 0 and grid[y - 1][x] != 0:
				# earth bank under the shore, or posts under the planks
				var up = grid[y - 1][x]
				if up == 3:
					rect(im, x * TS, y * TS, TS, 2, c("3d2e22"))
					rect(im, x * TS + 3, y * TS + 2, 2, 7, c("4a3a2c"))
					rect(im, x * TS + 11, y * TS + 2, 2, 7, c("4a3a2c"))
				else:
					rect(im, x * TS, y * TS, TS, 5, c("4a3f33"))
					rect(im, x * TS, y * TS, TS, 1, c("352c26"))
					rect(im, x * TS, y * TS + 5, TS, 1, c("26444e"))
					px(im, x * TS + k % TS, y * TS + 2, c("5d5042"))
			if t == 0 and y > 0 and grid[y - 1][x] == 0 and y + 1 < mh and grid[y + 1][x] != 0 and grid[y + 1][x] != 3:
				rect(im, x * TS, y * TS + TS - 1, TS, 1, c("4f8a8f") if (k + frame) % 3 == 0 else c("3d6f77"))
			if t == 1:
				# soften the border with mud
				if x + 1 < mw and grid[y][x + 1] == 2 and k % 2 == 0:
					rect(im, x * TS + TS - 2, y * TS + (k >> 3) % 12, 2, 3, c("7a6a4f"))
				if y + 1 < mh and grid[y + 1][x] == 2 and k % 2 == 1:
					rect(im, x * TS + (k >> 3) % 12, y * TS + TS - 2, 3, 2, c("7a6a4f"))
	TH = ""
	REMAP = {}
	return ImageTexture.create_from_image(im)

# ---------------------------------------------------------------- terrain helpers

# water with no land within two tiles
static func deep(grid: Array, x: int, y: int) -> bool:
	for j in range(-2, 3):
		for i in range(-2, 3):
			var yy = y + j
			var xx = x + i
			if yy >= 0 and xx >= 0 and yy < grid.size() and xx < grid[0].size() and grid[yy][xx] != 0:
				return false
	return true

# smooth value noise in 0..1, for patches with natural outlines
static func noise(x: float, y: float, seed: int) -> float:
	var x0 = int(floor(x))
	var y0 = int(floor(y))
	var fx = x - x0
	var fy = y - y0
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a = (hsh(x0, y0, seed) % 1000) / 1000.0
	var b = (hsh(x0 + 1, y0, seed) % 1000) / 1000.0
	var cc = (hsh(x0, y0 + 1, seed) % 1000) / 1000.0
	var d = (hsh(x0 + 1, y0 + 1, seed) % 1000) / 1000.0
	return lerpf(lerpf(a, b, fx), lerpf(cc, d, fx), fy)

# darkened corners, in a few flat steps so it stays pixel art when stretched over the view
static func build_vignette() -> void:
	var im = blank(160, 90)
	for y in 90:
		for x in 160:
			var d = Vector2((x - 79.5) / 80.0, (y - 44.5) / 45.0).length()
			var a = 0.0
			if d > 1.22:
				a = 0.34
			elif d > 1.08:
				a = 0.22
			elif d > 0.94:
				a = 0.12
			elif d > 0.82:
				a = 0.05
			im.set_pixel(x, y, Color(0.03, 0.02, 0.07, a))
	T["vignette"] = ImageTexture.create_from_image(im)

# ---------------------------------------------------------------- icons and extra frames from assets/
# Loaded when the file is there, so a missing picture falls back to the old drawing instead of stopping the game.
const SKILL_IDS = ["bulwark", "iron", "steady", "rush", "counter", "unbroken", "spin", "bloodlust", "hotblood", "cry", "laststand", "price",
	"lunge", "reach", "heavy", "slam", "sunder", "fourth", "toll", "ember", "kindle", "pyre", "ring", "deep", "brittle", "spark", "static", "overload",
	"charged", "coldiron", "stoke", "furnace", "afterglow", "shatter", "conduct", "tempest",
	"firewall", "heat", "ash", "shard", "bitter", "icearmor", "cage", "relay", "surge", "tam",
	"shadow", "smoke", "light", "backstab", "escape", "unseen", "venom", "darts", "potent", "linger", "infect", "burst",
	"slash", "exec", "keen", "vital", "ruthless", "six", "cuts", "lb_last", "lb_open", "lb_follow", "lb_ring", "lb_fallen",
	"lb_boil", "lb_cry", "lb_twin", "dl_mark", "dl_rupture", "dl_coat", "dl_frozen", "dl_fog", "dl_step", "dl_judge", "dl_three",
	"summon", "sacrifice", "horde", "sharp", "lasting", "legion", "weaken", "chain", "deepcurse", "rot", "spread", "oneword",
	"scythe", "soulform", "harvest", "feed", "jar", "hunger", "night", "kt_reap", "kt_spin", "kt_rally", "kt_proxy", "kt_scythe",
	"kt_curse", "kt_toll", "kt_shroud", "th_ash", "th_eternal", "th_cold", "th_tint", "th_sac", "th_chain", "th_reso", "th_fire",
	"gh_take", "gh_raise", "gh_plague", "gh_link", "gh_points", "gh_step", "gh_back", "gh_cheat",
	"raise", "thick", "endure", "wall", "stand", "fortress", "bash", "thorns", "debt", "verdict", "hammer", "payback",
	"taunt", "share", "watch", "cover", "firm", "standin", "bronze", "tt_block", "tt_rush", "tt_rage", "tt_pull", "tt_order",
	"tt_topple", "tt_beat", "tt_true", "ls_shell", "ls_wall", "ls_mark", "ls_freeze", "ls_crack", "ls_volt", "ls_cage", "ls_eye",
	"dv_dodge", "dv_step", "dv_smoke", "dv_thorn", "dv_verdict", "dv_open", "dv_cut", "dv_fake", "mv_coat", "mv_die",
	"mv_tchain", "mv_judge", "mv_ring", "mv_soul", "mv_tithe", "mv_tomb",
	"aimed", "hawk", "steadyh", "rain", "pierce", "oneshot", "snare", "trapper", "spring", "mine", "far", "linkup",
	"sic", "sturdy", "fangs", "hunt", "bond", "pack", "bighunt", "tp_toss", "tp_down", "tp_pack", "tp_spin", "tp_rhythm",
	"tp_quake", "tp_signal", "tp_big", "tn_burnrain", "tn_pool", "tn_tint", "tn_ice", "tn_layer", "tn_jump", "tn_focus", "tn_tri",
	"ta_track", "ta_smoke", "ta_eye", "ta_fang", "ta_snap", "ta_shot", "ta_pass", "ta_night", "hl_stand", "hl_tithe",
	"hl_curse", "hl_rain", "hl_chain", "hl_reap", "hl_soul", "hl_wolf", "bv_behind", "bv_loop", "bv_bash", "bv_lure",
	"bv_gate", "bv_pet", "bv_rain", "bv_post",
	"knell", "warm", "resound", "holy", "patience", "vein", "seal", "sacred", "lumen", "purge", "rebuke", "zeal",
	"bless", "radiance", "abide", "vow", "shelter", "devote", "vigil", "kn_block", "kn_rise", "kn_link", "kn_spin", "kn_strike",
	"kn_lit", "kn_slam", "kn_oath", "nq_fire", "nq_lit", "nq_seal", "nq_frost", "nq_tint", "nq_purge", "nq_cage", "nq_noon",
	"pq_lit", "pq_smoke", "pq_grace", "pq_holy", "pq_slash", "pq_exec", "pq_purge", "pq_doom", "ch_tend", "ch_keep", "ch_bless",
	"ch_lit", "ch_vow", "ch_ground", "ch_scythe", "ch_send", "sv_pray", "sv_over", "sv_lit", "sv_bash", "sv_knell", "sv_ring",
	"sv_vow", "sv_martyr", "tl_calm", "tl_arrow", "tl_trap", "tl_vow", "tl_pray", "tl_knell", "tl_lit", "tl_beast",
	"turret", "skilled", "durable", "bellmine", "salvage", "workshop", "vent", "valve", "core", "boost", "radiator", "overdrive",
	"hook", "lens", "battery", "mute", "toolkit", "prototype", "bellwork", "tk_mine", "tk_stun", "tk_spin", "tk_toll", "tk_chop",
	"tk_vent", "tk_pull", "tk_armor", "lc_heat", "lc_vent", "lc_tint", "lc_frost", "lc_reso", "lc_cage", "lc_charge", "lc_reactor",
	"tb_hook", "tb_smoke", "tb_quiet", "tb_venom", "tb_slash", "tb_fin", "tb_vent", "tb_sabo", "kl_heat", "kl_post", "kl_sac",
	"kl_chain", "kl_curse", "kl_reap", "kl_scrap", "kl_puppet", "pl_cool", "pl_wall", "pl_shield", "pl_lure", "pl_bash", "pl_ring",
	"pl_share", "pl_bunker", "cl_aim", "cl_quiet", "cl_trap", "cl_mine", "cl_hook", "cl_mark", "cl_pet", "cl_field", "tc_cool",
	"tc_knell", "tc_holy", "tc_lit", "tc_purge", "tc_bless", "tc_hook", "tc_drum",
	"ocb_parry", "ocb_iron", "ocb_surge", "ocb_blood", "ocb_cry", "ocb_long", "ocb_wide", "ocb_master", "ont_hot", "ont_spread", "ont_deepcold", "ont_frostbite", "ont_frostguard", "ont_arc", "ont_charge", "ont_triad", "ost_shadow", "ost_step", "ost_toxic", "ost_seep", "ost_dart", "ost_six", "ost_reset", "ost_ghost", "otl_host", "otl_strong", "otl_curse2", "otl_wither", "otl_bind", "otl_eight", "otl_reap", "otl_lich", "ohv_cap", "ohv_regen", "ohv_spikes", "ohv_bash", "ohv_verdict", "ohv_taunt", "ohv_cover", "ohv_bulwark", "ots_quick", "ots_deadeye", "ots_traps", "ots_jaw", "ots_boom", "ots_alpha", "ots_mark", "ots_lone", "ott_bigheal", "ott_ground", "ott_brand", "ott_bright", "ott_cleanse", "ott_grace", "ott_vow", "ott_saint", "oks_turret", "oks_mine", "oks_vent", "oks_cool", "oks_hot", "oks_hook", "oks_mute", "oks_four"]
const ITEM_KEYS = ["w0", "w1", "w2", "w3", "w4", "w5", "w6", "w7", "w8", "w9", "w10", "a0", "a1", "a2", "a3", "a4", "a5", "c0", "c1", "c2", "c3", "c4", "c5",
	"u_wave", "u_box", "u_free", "u_wick", "u_seed"]
const HERO_FRAMES = ["idle", "w1", "w2", "w3", "wind", "slash"]

static func load_optional() -> void:
	var names = []
	for id in SKILL_IDS:
		names.append("sk_" + id)
	for k in ITEM_KEYS:
		names.append("it_" + k)
	for fr in HERO_FRAMES:
		names.append("hd_" + fr)
		names.append("hu_" + fr)
	for n in names:
		var path = "res://assets/%s.png" % n
		if ResourceLoader.exists(path):
			var im: Image = (load(path) as Texture2D).get_image()
			im.convert(Image.FORMAT_RGBA8)
			put(n, im, false)
	# the three marks are too small to generate: five by five pixels, drawn by hand
	var marks = {
		"burn": [".#...", ".##..", "#o#.#", "#oo##", ".###."],
		"chill": ["#.#.#", ".###.", "##o##", ".###.", "#.#.#"],
		"shock": ["..##.", ".##..", "####.", "..##.", ".#..."],
		"poison": ["..#..", ".###.", "#o###", "#####", ".###."],
		"curse": ["#...#", ".#o#.", "..#..", ".#o#.", "#...#"],
		"taunt": ["..#..", "..#..", "..#..", ".....", "..#.."],
		"hunt": [".###.", "#...#", "#.o.#", "#...#", ".###."],
		"root": ["#.#.#", ".###.", "..#..", ".###.", "#.#.#"],
		"lit": ["#.#.#", ".ooo.", "#ooo#", ".ooo.", "#.#.#"],
	}
	var cols = {"lit": [c("f0d060"), c("fffbe0")], "taunt": [c("e0b04a"), c("fff0c0")], "hunt": [c("e05a3a"), c("ffd0c0")], "root": [c("b08a5a"), c("f0d8b0")], "curse": [c("b07fd6"), c("f0d8ff")], "poison": [c("8fd66a"), c("e4ffc8")], "burn": [c("e98a2e"), c("ffe9a3")], "chill": [c("7fd4e8"), c("f4ffff")], "shock": [c("9db4ff"), c("ffffff")]}
	for k in marks:
		var im = blank(7, 7)
		for y in 5:
			for x in 5:
				var ch = marks[k][y][x]
				if ch != ".":
					px(im, x + 1, y + 1, cols[k][0] if ch == "#" else cols[k][1])
		put("mk_" + k, im)
