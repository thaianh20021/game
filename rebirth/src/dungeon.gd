extends RefCounted
# Floor layout generation and baking of the floor into two big textures
# (ground under the actors, wall caps over them).

const Art = preload("res://src/art.gd")
const D = preload("res://src/data.gd")
const Traps = preload("res://src/traps.gd")
const Puzzle = preload("res://src/puzzle.gd")
const CW = 28
const CH = 22
const TS = 16

const SIZES = {
	"start": [[11, 9]], "exit": [[9, 9]], "chest": [[9, 7]], "shop": [[13, 9]], "workshop": [[13, 9]], "shrine": [[9, 7]], "secret": [[7, 7]], "boss": [[23, 15]], "puzzle": [[13, 9]],
	"fight": [[15, 11], [17, 11], [17, 13], [19, 13], [21, 13]],
}

static func generate(rng: RandomNumberGenerator, floor_i: int, boss: bool, weather: String = "clear") -> Dictionary:
	var n_main = 4 + floor_i / 2 + (0 if boss else 1)
	var cells = [Vector2i(0, 0)]
	var used = {Vector2i(0, 0): 0}
	while cells.size() < n_main:
		var c = cells[-1]
		var opts = [Vector2i(1, 0), Vector2i(1, 0)]
		for dd in [Vector2i(0, 1), Vector2i(0, -1)]:
			if not used.has(c + dd) and abs(c.y + dd.y) <= 1:
				opts.append(dd)
		var nc = c + opts[rng.randi() % opts.size()]
		used[nc] = cells.size()
		cells.append(nc)

	var rooms = []
	for i in cells.size():
		var type = "fight"
		if i == 0:
			type = "start"
		elif i == cells.size() - 1:
			type = "boss" if boss else "exit"
		rooms.append({id = i, cell = cells[i], type = type, links = []})
	for i in range(1, rooms.size()):
		rooms[i - 1].links.append(i)
		rooms[i].links.append(i - 1)
	var sides = ["chest", "shop", "workshop"]
	if rng.randf() < 0.5:
		sides.append("shrine")
	if rng.randf() < 0.6:
		sides.append("puzzle")
	for type in sides:
		for attempt in 40:
			var base = 1 + rng.randi() % (n_main - 2)
			var nc = rooms[base].cell + [Vector2i(0, 1), Vector2i(0, -1)][rng.randi() % 2]
			if used.has(nc):
				continue
			used[nc] = rooms.size()
			rooms[base].links.append(rooms.size())
			rooms.append({id = rooms.size(), cell = nc, type = type, links = [base]})
			break

	# a sealed side room behind a cracked wall of one of the fight rooms
	if rng.randf() < 0.65:
		for attempt in 40:
			var base = 1 + rng.randi() % (n_main - 2)
			var nc = rooms[base].cell + [Vector2i(0, 1), Vector2i(0, -1)][rng.randi() % 2]
			if used.has(nc):
				continue
			used[nc] = rooms.size()
			rooms.append({id = rooms.size(), cell = nc, type = "secret", links = [], secret_of = base})
			break

	var miny = 0
	var maxy = 0
	var maxx = 0
	for r in rooms:
		miny = min(miny, r.cell.y)
		maxy = max(maxy, r.cell.y)
		maxx = max(maxx, r.cell.x)
	var w = (maxx + 1) * CW
	var h = (maxy - miny + 1) * CH + 2
	var grid = PackedByteArray()
	grid.resize(w * h)
	var d = {w = w, h = h, grid = grid, rooms = rooms, props = [], torches = [], cracks = [], traps = [], terr = PackedByteArray(), weather = weather}

	for r in rooms:
		r.cell = Vector2i(r.cell.x, r.cell.y - miny)
		var opts = SIZES[r.type]
		var sz = opts[rng.randi() % opts.size()]
		r.center = Vector2i(r.cell.x * CW + CW / 2, r.cell.y * CH + CH / 2 + 2)
		r.rect = Rect2i(r.center - Vector2i(sz[0] / 2, sz[1] / 2), Vector2i(sz[0], sz[1]))
		r.gates = []
		r.cleared = not (r.type in ["fight", "boss"])
		r.seen = false
		r.wave = 0
		r.waves = 1 if r.type == "boss" else (2 + (1 if (floor_i >= 2 and rng.randf() < 0.75) else 0) + (1 if (floor_i >= 4 and rng.randf() < 0.4) else 0))
		r.mod = ""
		r.elite = false
		r.trial = false
		if r.type == "fight" and floor_i >= 1:
			r.elite = rng.randf() < 0.28
			if rng.randf() < 0.3:
				r.mod = ["dark", "haste", "surge"][rng.randi() % 3]
			r.trial = not r.elite and rng.randf() < 0.2
		for y in range(r.rect.position.y, r.rect.end.y):
			for x in range(r.rect.position.x, r.rect.end.x):
				grid[y * w + x] = 1

	for a in rooms:
		for bi in a.links:
			if bi < a.id:
				continue
			var b = rooms[bi]
			if a.cell.y == b.cell.y:
				var l = a if a.cell.x < b.cell.x else b
				var rr = b if a.cell.x < b.cell.x else a
				for x in range(l.rect.end.x, rr.rect.position.x):
					for dy in range(-1, 2):
						grid[(l.center.y + dy) * w + x] = 1
				for dy in range(-1, 2):
					l.gates.append(Vector2i(l.rect.end.x, l.center.y + dy))
					rr.gates.append(Vector2i(rr.rect.position.x - 1, l.center.y + dy))
			else:
				var t = a if a.cell.y < b.cell.y else b
				var bt = b if a.cell.y < b.cell.y else a
				for y in range(t.rect.end.y, bt.rect.position.y):
					for dx in range(-1, 2):
						grid[y * w + t.center.x + dx] = 1
				for dx in range(-1, 2):
					t.gates.append(Vector2i(t.center.x + dx, t.rect.end.y))
					bt.gates.append(Vector2i(t.center.x + dx, bt.rect.position.y - 1))

	for s in rooms:
		if not s.has("secret_of"):
			continue
		var o = rooms[s.secret_of]
		var t = s if s.cell.y < o.cell.y else o
		var bt = o if s.cell.y < o.cell.y else s
		for y in range(t.rect.end.y, bt.rect.position.y):
			grid[y * w + t.center.x] = 1
		var cc = Vector2i(o.center.x, o.rect.end.y if o == t else o.rect.position.y - 1)
		grid[cc.y * w + cc.x] = 0
		d.cracks.append({cell = cc, hp = 6, open = false, room = s.id})

	for r in rooms:
		if r.type == "fight":
			_pillars(rng, d, r)
			_terrain(rng, d, r)
			_props(rng, d, r)
			Traps.place(rng, d, r, floor_i)
		elif r.type == "boss":
			Traps.place(rng, d, r, floor_i)
		elif r.type == "puzzle":
			Puzzle.build(rng, d, r, r.cell.y > rooms[r.links[0]].cell.y)
		var ty = r.rect.position.y - 1
		for x in range(r.rect.position.x + 1, r.rect.end.x, 4):
			if grid[ty * w + x] == 0:
				d.torches.append(Vector2(x * TS + 8, ty * TS + 9))
	return d

# The hand-built hub: one hall plus a sealed nook behind a cracked wall.
static func lobby(nook_open: bool) -> Dictionary:
	var w = 36
	var h = 34
	var grid = PackedByteArray()
	grid.resize(w * h)
	var hall = Rect2i(2, 4, 27, 15)
	var nook = Rect2i(30, 10, 3, 3)
	# south wing with the shops, reached through a short passage
	for rc in [hall, nook, Rect2i(14, 19, 3, 2), Rect2i(5, 21, 21, 10)]:
		for y in range(rc.position.y, rc.end.y):
			for x in range(rc.position.x, rc.end.x):
				grid[y * w + x] = 1
	if nook_open:
		grid[11 * w + 29] = 1
	var r = {id = 0, cell = Vector2i(0, 0), type = "lobby", links = [], center = Vector2i(15, 11), rect = hall, gates = [],
		cleared = true, seen = true, wave = 0, waves = 0, mod = "", elite = false, trial = false}
	var d = {w = w, h = h, grid = grid, rooms = [r], props = [], torches = [], cracks = [], traps = [], terr = PackedByteArray()}
	for x in range(4, 28, 4):
		d.torches.append(Vector2(x * TS + 8, 3 * TS + 9))
	for x in [6, 10, 20, 24]:
		d.torches.append(Vector2(x * TS + 8, 20 * TS + 9))
	return d

static func _pillars(rng: RandomNumberGenerator, d: Dictionary, r: Dictionary) -> void:
	var c: Vector2i = r.center
	var qx = r.rect.size.x / 4
	var qy = r.rect.size.y / 4
	var cells = []
	match rng.randi() % 7:
		1:
			for sx in [-1, 1]:
				for sy in [-1, 1]:
					cells.append(c + Vector2i(sx * qx, sy * qy))
		2:
			for sx in [-1, 1]:
				for sy in [-1, 1]:
					cells.append(c + Vector2i(sx * qx, sy * qy))
					cells.append(c + Vector2i(sx * (qx + 1), sy * qy))
		3:
			for sx in [-1, 1]:
				for dy in range(-qy, qy + 1):
					if dy != 0:
						cells.append(c + Vector2i(sx * qx, dy))
		4:
			for sx in [-1, 1]:
				for sy in [-1, 1]:
					cells.append(c + Vector2i(sx * qx, sy * qy))
					cells.append(c + Vector2i(sx * qx, sy * (qy - 1)))
		5:
			for sx in [0, 1]:
				for sy in [0, 1]:
					var k = Vector2i(r.rect.position.x if sx == 0 else r.rect.end.x - 1, r.rect.position.y if sy == 0 else r.rect.end.y - 1)
					var ix = 1 if sx == 0 else -1
					var iy = 1 if sy == 0 else -1
					cells.append_array([k, k + Vector2i(ix, 0), k + Vector2i(0, iy), k + Vector2i(ix * 2, 0), k + Vector2i(0, iy * 2), k + Vector2i(ix, iy)])
		6:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					cells.append(c + Vector2i(dx, dy))
	for p in cells:
		d.grid[p.y * d.w + p.x] = 0

# Hard ground. terr: 1 = mire (slows anything on foot), 2 = pit (heroes fall, walkers must go around).
# The rim of the room and the cross through its centre stay clear, so no door is ever cut off.
static func _terrain(rng: RandomNumberGenerator, d: Dictionary, r: Dictionary) -> void:
	if d.terr.size() == 0:
		d.terr.resize(d.w * d.h)
	var inner: Rect2i = r.rect.grow(-1)
	# the weather decides how wet or dry the floor is
	var wx: String = d.get("weather", "clear")
	for kind in [1, 2, 4]:
		var chance = 0.5
		if kind == 1:
			chance = {"rain": 0.95, "drought": 0.2}.get(wx, 0.6)
		elif kind == 4:
			chance = {"rain": 0.25, "drought": 0.95}.get(wx, 0.5)
		if rng.randf() > chance:
			continue
		var want = (8 + rng.randi() % 8) if kind != 2 else (4 + rng.randi() % 5)
		if (kind == 1 and wx == "rain") or (kind == 4 and wx == "drought"):
			want *= 2
		var blob = []
		for attempt in 200:
			if blob.size() >= want:
				break
			var c: Vector2i
			if blob.is_empty():
				c = inner.position + Vector2i(rng.randi() % inner.size.x, rng.randi() % inner.size.y)
			else:
				c = blob[rng.randi() % blob.size()] + [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)][rng.randi() % 4]
			if not inner.has_point(c) or d.grid[c.y * d.w + c.x] != 1 or d.terr[c.y * d.w + c.x] != 0:
				continue
			if abs(c.x - r.center.x) <= 1 or abs(c.y - r.center.y) <= 1:
				continue
			d.terr[c.y * d.w + c.x] = kind
			blob.append(c)

static func _terr_tile(img: Image, x: int, y: int, kind: int, bi: int, b: Dictionary, lip: bool) -> void:
	var ox = x * TS
	var oy = y * TS
	if kind == 4:
		# dry brush: burns, and the fire walks from tile to tile
		var gc: Color = [Color("8a9a3c"), Color("b89a4a"), Color("9a8a6a")][bi]
		for i in 9:
			var px = (i * 5 + x * 3) % 14 + 1
			var py = (i * 7 + y * 5) % 11 + 3
			img.set_pixel(ox + px, oy + py, gc.darkened(0.2))
			img.set_pixel(ox + px, oy + py - 1, gc)
			img.set_pixel(ox + px + (i % 2), oy + py - 2, gc.lightened(0.3))
		return
	if kind == 1:
		var mud: Color = [Color("3d5a34"), Color("2a1b1c"), Color("5f86b4")][bi]
		var hi: Color = [Color("6f9a4c"), Color("f2812f"), Color("c6f4ff")][bi]
		for py in 16:
			for px in 16:
				var c = img.get_pixel(ox + px, oy + py).lerp(mud, 0.72)
				if ((px * 7 + py * 13 + x * 5 + y * 3) % 23) == 0:
					c = c.lerp(hi, 0.55)
				elif ((px + x * 3) % 8 < 5) and ((py + y * 5) % 6 == 2):
					c = c.darkened(0.18)
				img.set_pixel(ox + px, oy + py, c)
	else:
		img.fill_rect(Rect2i(ox, oy, 16, 16), Color("07050c"))
		if lip:
			img.fill_rect(Rect2i(ox, oy, 16, 3), b.face[2])
			img.fill_rect(Rect2i(ox, oy + 3, 16, 2), b.face[2].darkened(0.45))
			img.fill_rect(Rect2i(ox, oy + 5, 16, 2), b.face[2].darkened(0.75))
			for px in range(1, 16, 5):
				img.set_pixel(ox + px + (y % 3), oy + 1, b.face[0])

static func _props(rng: RandomNumberGenerator, d: Dictionary, r: Dictionary) -> void:
	var taken = {}
	var n_crate = 3 + rng.randi() % 4
	var n_barrel = rng.randi() % 3
	for i in n_crate + n_barrel:
		for attempt in 20:
			var p = r.rect.position + Vector2i(rng.randi() % r.rect.size.x, rng.randi() % r.rect.size.y)
			if d.grid[p.y * d.w + p.x] != 1 or taken.has(p) or d.terr[p.y * d.w + p.x] != 0:
				continue
			if p.x == r.center.x or p.y == r.center.y or abs(p.x - r.center.x) + abs(p.y - r.center.y) < 3:
				continue
			taken[p] = true
			var barrel = i >= n_crate
			d.props.append({
				kind = "barrel" if barrel else "crate",
				el = D.EL[rng.randi() % 4] if barrel else "",
				pos = Vector2(p.x * TS + 8, p.y * TS + 11), hp = 6.0, dead = false, flash = 0.0,
			})
			break

static func bake(d: Dictionary, bi: int) -> Array:
	var w: int = d.w
	var h: int = d.h
	var grid: PackedByteArray = d.grid
	var t = Art.tiles[bi]
	var b = D.BIOMES[bi]
	var ground = Image.create_empty(w * TS, h * TS, false, Image.FORMAT_RGBA8)
	ground.fill(b.cap)
	var over = Image.create_empty(w * TS, h * TS, false, Image.FORMAT_RGBA8)
	var shade = Image.create_empty(16, 7, false, Image.FORMAT_RGBA8)
	for y in 7:
		for x in 16:
			shade.set_pixel(x, y, Color(0, 0, 0, 0.5 * (1.0 - y / 7.0)))
	var r16 = Rect2i(0, 0, 16, 16)
	var h2 = h * 2
	var mask = PackedByteArray()
	mask.resize(w * h2)
	for y in h:
		for x in w:
			var hsh = ((x * 73856093) ^ (y * 19349663)) & 0x7fffffff
			if grid[y * w + x] != 0:
				var v = hsh % 13
				if v >= 10:
					v = hsh % 7
				ground.blit_rect(t.floor[v], r16, Vector2i(x * TS, y * TS))
				if y > 0 and grid[(y - 1) * w + x] == 0:
					ground.blend_rect(shade, Rect2i(0, 0, 16, 7), Vector2i(x * TS, y * TS))
				if d.terr.size() > 0 and d.terr[y * w + x] != 0:
					_terr_tile(ground, x, y, d.terr[y * w + x], bi, b, y == 0 or d.terr[(y - 1) * w + x] != 2)
				elif d.rooms[0].type != "lobby" and (hsh / 13) % 8 == 0:
					# small set dressing, different in every biome
					var dim: Image = Art.I[Art.DECOR[bi][(hsh / 117) % 4]]
					ground.blend_rect(dim, Rect2i(Vector2i.ZERO, dim.get_size()), Vector2i(x * TS + 2 + (hsh / 7) % 6, y * TS + 3 + (hsh / 11) % 6))
			else:
				var face = y + 1 < h and grid[(y + 1) * w + x] != 0
				if face:
					var fv = hsh % 9
					ground.blit_rect(t.face[fv if fv < 4 else fv % 3], r16, Vector2i(x * TS, y * TS))
					if d.rooms[0].type != "lobby" and (hsh / 5) % 9 == 0:
						var bim: Image = Art.I["d_banner_%d" % bi]
						ground.blend_rect(bim, Rect2i(Vector2i.ZERO, bim.get_size()), Vector2i(x * TS + 4, y * TS + 2))
				for hy in ([2 * y - 2, 2 * y - 1] if face else [2 * y - 1, 2 * y]):
					if hy >= 0:
						mask[hy * w + x] = 1
	var cap: Color = b.cap
	var edge: Color = b.edge
	var top: Color = b.face[1].darkened(0.38)
	var hi = top.lightened(0.08)
	for hy in h2:
		for x in w:
			if mask[hy * w + x] == 0:
				continue
			var px = x * TS
			var py = hy * 8
			var rim = false
			for dy in range(-2, 3):
				for dx in range(-1, 2):
					var nx = x + dx
					var ny = hy + dy
					if nx >= 0 and ny >= 0 and nx < w and ny < h2 and mask[ny * w + nx] == 0:
						rim = true
			over.fill_rect(Rect2i(px, py, 16, 8), top if rim else cap)
			if ((x * 31 + hy * 17) % 11) == 0:
				over.fill_rect(Rect2i(px + (x * 7 + hy * 3) % 13, py + (x + hy * 5) % 7, 2, 1), hi)
			if hy > 0 and mask[(hy - 1) * w + x] == 0:
				over.fill_rect(Rect2i(px, py, 16, 1), edge)
				over.fill_rect(Rect2i(px, py + 1, 16, 2), hi)
			if hy < h2 - 1 and mask[(hy + 1) * w + x] == 0:
				over.fill_rect(Rect2i(px, py + 7, 16, 1), edge.darkened(0.55))
			if x > 0 and mask[hy * w + x - 1] == 0:
				over.fill_rect(Rect2i(px, py, 1, 8), edge.darkened(0.3))
			if x < w - 1 and mask[hy * w + x + 1] == 0:
				over.fill_rect(Rect2i(px + 15, py, 1, 8), edge.darkened(0.3))
	return [ground, over]
