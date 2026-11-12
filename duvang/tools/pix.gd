extends SceneTree
# Turns an AI-generated sheet (figures on a magenta or transparent background) into real sprites:
# find each connected figure, shrink it to a true pixel grid by taking the commonest colour of
# every cell, and pad it so the feet sit at the bottom centre.
# The first figure (leftmost) sets the scale; the others keep it, so a raised arm makes a taller sprite.
# Usage: <godot> --headless --path duvang --script res://tools/pix.gd -- <in.png> <height> <name1,name2,...> [fit]
# With "fit" every figure is scaled on its own into a square of that size (for icons).
# Writes res://assets/<name>.png and res://shots/pix_<name1>.png (enlarged preview).

const STEP = 4   # the figure search works on a coarse mask of STEP x STEP blocks

var src: Image
var label = PackedInt32Array()
var gw = 0
var gh = 0

func is_bg(c: Color) -> bool:
	return c.a < 0.5 or (c.r > 0.75 and c.b > 0.75 and c.g < 0.35)

func _init() -> void:
	var a = OS.get_cmdline_user_args()
	src = Image.load_from_file(a[0])
	src.convert(Image.FORMAT_RGBA8)
	var th = int(a[1])
	var names = a[2].split(",")
	var fit = a.size() > 3 and a[3] == "fit"
	gw = src.get_width() / STEP
	gh = src.get_height() / STEP
	var solid = PackedByteArray()
	solid.resize(gw * gh)
	for gy in gh:
		for gx in gw:
			solid[gy * gw + gx] = 0 if is_bg(src.get_pixel(gx * STEP + STEP / 2, gy * STEP + STEP / 2)) else 1
	label.resize(gw * gh)
	label.fill(0)
	var comps = []   # [id, cells, x0, y0, x1, y1]
	for start in gw * gh:
		if solid[start] == 0 or label[start] != 0:
			continue
		var id = comps.size() + 1
		var c = [id, 0, gw, gh, 0, 0]
		var stack = [start]
		label[start] = id
		while not stack.is_empty():
			var cur = stack.pop_back()
			var cx = cur % gw
			var cy = cur / gw
			c[1] += 1
			c[2] = mini(c[2], cx)
			c[3] = mini(c[3], cy)
			c[4] = maxi(c[4], cx)
			c[5] = maxi(c[5], cy)
			for d in [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, -1], [1, -1], [-1, 1]]:
				var nx = cx + d[0]
				var ny = cy + d[1]
				if nx < 0 or ny < 0 or nx >= gw or ny >= gh:
					continue
				var ni = ny * gw + nx
				if solid[ni] == 1 and label[ni] == 0:
					label[ni] = id
					stack.append(ni)
		comps.append(c)
	# big pieces are figures; small loose bits (sparks, drips) join the nearest figure or are dropped
	var big = comps.filter(func(c): return c[1] >= 150)
	big.sort_custom(func(p, q): return p[2] < q[2])
	for c in comps:
		if c[1] >= 150:
			continue
		var best = null
		var bd = 14
		for b in big:
			var dx = maxi(0, maxi(b[2] - c[4], c[2] - b[4]))
			var dy = maxi(0, maxi(b[3] - c[5], c[3] - b[5]))
			if maxi(dx, dy) < bd:
				bd = maxi(dx, dy)
				best = b
		if best != null:
			for i in gw * gh:
				if label[i] == c[0]:
					label[i] = best[0]
			best[2] = mini(best[2], c[2])
			best[3] = mini(best[3], c[3])
			best[4] = maxi(best[4], c[4])
			best[5] = maxi(best[5], c[5])
	# more figures than names: the smallest extras are loose bits (a thrown pod, a dropped toy) and are left out
	while big.size() > names.size():
		var least = big[0]
		for b in big:
			if b[1] < least[1]:
				least = b
		big.erase(least)
	if big.size() != names.size():
		print("ERROR: found %d figures, expected %d" % [big.size(), names.size()])
		quit(1)
		return
	var cell = 0.0
	var outs = []
	for i in big.size():
		var b = big[i]
		if fit:
			# icons: every figure is scaled by itself to fill a square of the asked size
			cell = float(maxi(b[4] - b[2] + 1, b[5] - b[3] + 1) * STEP) / th
		elif i == 0:
			cell = float((b[5] - b[3] + 1) * STEP) / th
		var im = shrink(b[0], b[2] * STEP, b[3] * STEP, (b[4] + 1) * STEP - 1, (b[5] + 1) * STEP - 1, cell, fit)
		if fit:
			var sq = Image.create_empty(th, th, false, Image.FORMAT_RGBA8)
			sq.blit_rect(im, Rect2i(0, 0, mini(th, im.get_width()), mini(th, im.get_height())), Vector2i(maxi(0, (th - im.get_width()) / 2), maxi(0, (th - im.get_height()) / 2)))
			im = sq
		outs.append(im)
		im.save_png(ProjectSettings.globalize_path("res://assets/%s.png" % names[i]))
		print("%s %dx%d" % [names[i], im.get_width(), im.get_height()])
	var tw = 0
	var mh = 0
	for im in outs:
		tw += im.get_width() + 4
		mh = maxi(mh, im.get_height())
	var sheet = Image.create_empty(tw, mh + 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("5b7b4a"))
	var ox = 2
	for im in outs:
		sheet.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(ox, mh + 1 - im.get_height()))
		ox += im.get_width() + 4
	var zoom = 5 if tw < 300 else 3
	sheet.resize(sheet.get_width() * zoom, sheet.get_height() * zoom, Image.INTERPOLATE_NEAREST)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	sheet.save_png(ProjectSettings.globalize_path("res://shots/pix_%s.png" % names[0]))
	quit()

# a source pixel counts only if it belongs to figure `id`
func mine(id: int, sx: int, sy: int) -> bool:
	var gx = clampi(sx / STEP, 0, gw - 1)
	var gy = clampi(sy / STEP, 0, gh - 1)
	if label[gy * gw + gx] == id:
		return true
	# edge pixels fall in blocks whose centre is background; accept them next to an owned block
	for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
		var nx = gx + d[0]
		var ny = gy + d[1]
		if nx >= 0 and ny >= 0 and nx < gw and ny < gh and label[ny * gw + nx] == id:
			return true
	return false

func shrink(id: int, x0: int, y0: int, x1: int, y1: int, cell: float, raw: bool = false) -> Image:
	var tw = int(ceil((x1 - x0 + 1) / cell))
	var th = int(ceil((y1 - y0 + 1) / cell))
	var out = Image.create_empty(tw, th, false, Image.FORMAT_RGBA8)
	# rows are measured from the bottom so the feet land on a cell boundary
	for ty in th:
		for tx in tw:
			var votes = {}
			var bg = 0
			var n = 0
			for j in 5:
				for i in 5:
					var sx = int(x0 + (tx + 0.2 + 0.15 * i) * cell)
					var sy = int(y1 + 1 - (th - ty) * cell + (0.2 + 0.15 * j) * cell)
					if sx > x1 or sy > y1 or sy < 0:
						continue
					var c = src.get_pixel(sx, sy)
					n += 1
					if is_bg(c) or not mine(id, sx, sy):
						bg += 1
						continue
					var key = Color(snappedf(c.r, 0.08), snappedf(c.g, 0.08), snappedf(c.b, 0.08))
					if not votes.has(key):
						votes[key] = [0, Color(0, 0, 0)]
					votes[key][0] += 1
					votes[key][1] += c
			if n == 0 or bg * 2 > n:
				continue
			var best = null
			for k in votes:
				if best == null or votes[k][0] > votes[best][0]:
					best = k
			var s = votes[best][1] / float(votes[best][0])
			if s.r > s.g + 0.18 and s.b > s.g + 0.18:
				continue   # pink fringe from the background
			out.set_pixel(tx, ty, Color(s.r, s.g, s.b, 1.0))
	if raw:
		return out
	# the feet (bottom rows) go to the horizontal centre
	var sum = 0.0
	var cnt = 0
	for ty in range(maxi(0, th - maxi(2, th / 8)), th):
		for tx in tw:
			if out.get_pixel(tx, ty).a > 0.5:
				sum += tx
				cnt += 1
	var ax = int(round(sum / maxi(cnt, 1)))
	var half = maxi(ax, tw - 1 - ax) + 1
	var pad = Image.create_empty(half * 2 + 1, th + 1, false, Image.FORMAT_RGBA8)
	pad.blit_rect(out, Rect2i(0, 0, tw, th), Vector2i(half - ax, 0))
	return pad
