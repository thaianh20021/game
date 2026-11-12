extends RefCounted
# The three places of the first chapter. A zone is a dictionary:
#   grid[y][x]: 0 water, 1 grass, 2 mud, 3 plank       decor: [{tex, pos, solid}]
#   lanterns: [pos]   portals: [{rect, to, at, label, need}]   spawns: [{kind, pos}]
#   npcs: [{id, pos}]   start: where a new hero or a respawn appears   dark, tier, mult
# Layout depends only on the zone id, so it is the same every visit.

const Art = preload("res://src/art.gd")
const TS = 16

static func empty(id: String, name: String, w: int, h: int) -> Dictionary:
	var grid = []
	for y in h:
		var row = []
		row.resize(w)
		row.fill(0)
		grid.append(row)
	return {"id": id, "name": name, "w": w, "h": h, "grid": grid, "decor": [], "lanterns": [], "portals": [], "spawns": [], "npcs": [], "things": [], "scenes": [], "gates": [], "theme": "", "respawn": false, "start": Vector2.ZERO, "dark": false, "tier": 0, "mult": 1.0}

static func fill(z: Dictionary, x0: int, y0: int, x1: int, y1: int, v: int) -> void:
	for y in range(maxi(0, y0), mini(z.h, y1 + 1)):
		for x in range(maxi(0, x0), mini(z.w, x1 + 1)):
			z.grid[y][x] = v

static func tp(x: float, y: float) -> Vector2:
	return Vector2(x * TS, y * TS)

static func lantern(z: Dictionary, x: float, y: float) -> void:
	var lp = tp(x, y)
	z.decor.append({"tex": "lantern", "pos": lp, "solid": false})
	z.lanterns.append(lp + Vector2(4, -20))

# reeds along the shore, a few stones inland
static func dress(z: Dictionary, seed: int) -> void:
	for y in range(1, z.h - 1):
		for x in range(1, z.w - 1):
			if z.grid[y][x] != 1:
				continue
			var k = Art.hsh(x, y, seed)
			var shore = z.grid[y - 1][x] == 0 or z.grid[y + 1][x] == 0 or z.grid[y][x - 1] == 0 or z.grid[y][x + 1] == 0
			var pos = Vector2(x * TS + 4 + k % 8, y * TS + 6 + (k >> 4) % 8)
			if (shore and k % 100 < 45) or k % 100 < 2:
				z.decor.append({"tex": "reeds%d" % ((k >> 8) % 3), "pos": pos, "solid": false})
			elif k % 1000 < 12:
				z.decor.append({"tex": "stone%d" % ((k >> 8) % 2), "pos": pos, "solid": false})

static func build(id: String) -> Dictionary:
	match id:
		"field": return field()
		"dungeon": return dungeon()
		"forest": return forest()
		"heart": return heart()
	return town()

# ---------------------------------------------------------------- Woodclapper Town

static func town() -> Dictionary:
	var z = empty("town", "TRẤN MÕ GỖ", 46, 30)
	fill(z, 3, 3, 42, 26, 1)
	for y in range(3, 27):
		for x in range(3, 43):
			var k = int(Art.noise(x * 0.27, y * 0.3, 5) * 100.0) - 30
			var edge = Art.hsh(x, y, 9) % 3
			if (x < 4 + edge or x > 41 - edge or y < 4 + edge or y > 25 - edge):
				z.grid[y][x] = 0
			elif k < 14:
				z.grid[y][x] = 2
	fill(z, 6, 14, 45, 15, 2)      # main street, runs out of the east gate
	fill(z, 40, 14, 45, 15, 3)
	fill(z, 18, 11, 27, 18, 3)     # the square
	fill(z, 21, 6, 24, 11, 2)      # path up to the hall
	z.decor.append({"tex": "house_hall", "pos": tp(22.5, 7.5), "solid": true})
	z.decor.append({"tex": "house_shop", "pos": tp(33.0, 11.5), "solid": true})
	z.decor.append({"tex": "house_home", "pos": tp(11.0, 11.0), "solid": true})
	z.decor.append({"tex": "house_home", "pos": tp(12.5, 22.5), "solid": true})
	z.decor.append({"tex": "house_home", "pos": tp(32.0, 22.5), "solid": true})
	z.decor.append({"tex": "clapper", "pos": tp(22.5, 14.0), "solid": true})
	for q in [[17.5, 13.5], [28.0, 13.5], [17.5, 17.5], [28.0, 17.5], [38.5, 13.5], [8.0, 13.5]]:
		lantern(z, q[0], q[1])
	z.npcs = [
		{"id": "say", "pos": tp(22.5, 10.0)},
		{"id": "kham", "pos": tp(33.0, 13.2)},
		{"id": "ngai", "pos": tp(25.5, 16.5)},
		{"id": "dien", "pos": tp(39.0, 13.4)},
	]
	z.portals.append({"rect": Rect2(tp(44.5, 13), Vector2(TS * 2, TS * 4)), "to": "field", "at": tp(3.0, 23.0), "label": "RA ĐẦM LAU", "need": ""})
	z.start = tp(22.5, 16.5)
	for q in [[7.5, 7.5], [38.5, 7.5], [7.0, 23.5], [39.0, 24.0]]:
		z.decor.append({"tex": "tree_willow", "pos": tp(q[0], q[1]), "solid": true, "bw": 14.0})
	z.decor.append({"tex": "well", "pos": tp(15.0, 18.6), "solid": true})
	z.decor.append({"tex": "crates", "pos": tp(37.2, 12.6), "solid": true})
	z.decor.append({"tex": "cart", "pos": tp(9.5, 17.6), "solid": true})
	z.decor.append({"tex": "netrack", "pos": tp(27.0, 23.0), "solid": true, "bw": 40.0})
	z.decor.append({"tex": "shrine", "pos": tp(38.0, 18.6), "solid": true})
	z.decor.append({"tex": "grave", "pos": tp(17.0, 7.6), "solid": true})
	z.decor.append({"tex": "fence", "pos": tp(14.5, 7.4), "solid": false})
	z.decor.append({"tex": "fence", "pos": tp(19.5, 7.4), "solid": false})
	z.things = [
		{"id": "clapper", "pos": tp(22.5, 14.3)},
		{"id": "well", "pos": tp(15.0, 18.9), "h": 58.0},
		{"id": "shrine", "pos": tp(38.0, 18.9), "h": 54.0},
		{"id": "grave", "pos": tp(17.0, 7.9), "h": 48.0},
	]
	dress(z, 201)
	return z

# put `count` props of one kind on open grass, away from foes and from each other
static func scatter(z: Dictionary, tex: String, count: int, seed: int, bw: float) -> void:
	var placed = 0
	for i in 4000:
		if placed >= count:
			break
		var k = Art.hsh(i, seed, 911)
		var x = 4 + k % (z.w - 8)
		var y = 4 + (k >> 8) % (z.h - 8)
		if z.grid[y][x] != 1 or z.grid[y + 1][x] != 1 or z.grid[y][x - 1] != 1 or z.grid[y][x + 1] != 1:
			continue
		var pos = tp(x + 0.5, y + 0.9)
		var ok = true
		for s in z.spawns:
			if s.pos.distance_to(pos) < 46.0:
				ok = false
		for dc in z.decor:
			if dc.solid and dc.pos.distance_to(pos) < 70.0:
				ok = false
		if ok:
			z.decor.append({"tex": tex, "pos": pos, "solid": true, "bw": bw})
			placed += 1

# a grass tile with water just south of it, inside the given box
static func shore(z: Dictionary, x0: int, x1: int, y0: int, y1: int) -> Vector2:
	for x in range(x0, x1):
		for y in range(y0, y1):
			if z.grid[y][x] == 1 and z.grid[y + 1][x] == 0 and z.grid[y - 1][x] != 0:
				return tp(x + 0.5, y + 0.9)
	return Vector2.ZERO

# ---------------------------------------------------------------- Ashreed Marsh

static func field() -> Dictionary:
	var z = empty("field", "ĐẦM LAU TRO", 76, 46)
	for y in z.h:
		for x in z.w:
			var dx = (x - 38.0) / 33.0
			var dy = (y - 24.0) / 18.0
			var a = atan2(dy, dx)
			var d = sqrt(dx * dx + dy * dy) + sin(a * 3.0 + 1.3) * 0.07 + sin(a * 7.0 + 0.4) * 0.05 + sin(a * 13.0) * 0.025
			if d < 1.0:
				var n = int(Art.noise(x * 0.21, y * 0.26, 17) * 100.0) - 28
				z.grid[y][x] = 2 if (n < 22 or absf(y - 22.5) < 2.5) else 1
	for pond in [[52, 12, 3.4, 2.2], [20, 33, 2.8, 1.9], [30, 11, 2.4, 1.6], [58, 34, 3.0, 2.0]]:
		for y in z.h:
			for x in z.w:
				if Vector2((x - pond[0]) / pond[2], (y - pond[1]) / pond[3]).length() < 1.0:
					z.grid[y][x] = 0
	fill(z, 0, 22, 70, 23, 3)      # the dyke
	fill(z, 62, 0, 63, 22, 3)      # the ferry road, a pier running north
	for x in [8, 18, 30, 44, 56]:
		lantern(z, x + 0.5, 21.9)
	lantern(z, 61.4, 9.0)
	z.portals.append({"rect": Rect2(tp(0, 21), Vector2(TS * 1.2, TS * 4)), "to": "town", "at": tp(43.0, 15.0), "label": "VỀ TRẤN", "need": ""})
	z.portals.append({"rect": Rect2(tp(61, 0), Vector2(TS * 4, TS * 1.5)), "to": "dungeon", "at": tp(5.0, 15.5), "label": "BẾN PHÀ CŨ", "need": "m5"})
	z.portals.append({"rect": Rect2(tp(69.6, 21), Vector2(TS * 1.4, TS * 4)), "to": "forest", "at": tp(3.0, 26.0), "label": "RỪNG THỞ", "need": "m7"})
	z.respawn = true
	z.start = tp(3.0, 23.0)
	# foes: reeds in the west and middle, herons east and south, the porter on the ferry road
	var reeds = 0
	var herons = 0
	for i in 4000:
		var k = Art.hsh(i, 7, 301)
		var x = 12 + k % 56
		var y = 8 + (k >> 7) % 32
		if z.grid[y][x] == 0 or z.grid[y][x] == 3 or z.grid[y + 1][x] == 0 or z.grid[y][x + 1] == 0 or z.grid[y][x - 1] == 0:
			continue
		var pos = tp(x + 0.5, y + 0.5)
		var near = false
		for s in z.spawns:
			if s.pos.distance_to(pos) < 70.0:
				near = true
		if near:
			continue
		if x < 46 and reeds < 12:
			z.spawns.append({"kind": "reed", "pos": pos})
			reeds += 1
		elif x >= 40 and herons < 7:
			z.spawns.append({"kind": "heron", "pos": pos})
			herons += 1
	z.spawns.append({"kind": "porter", "pos": tp(63.0, 15.0)})
	for q in [[30, 36], [44, 38], [50, 30]]:
		z.spawns.append({"kind": "leech", "pos": land(z, q[0], q[1])})
	for q in [[52, 26], [66, 30]]:
		z.spawns.append({"kind": "netter", "pos": land(z, q[0], q[1])})
	z.spawns.append({"kind": "reed", "pos": land(z, 36, 14), "elite": "volatile"})
	z.spawns.append({"kind": "heron", "pos": land(z, 56, 36), "elite": "warding"})
	# scavengers who walk into a hollow leave their sandals on the shore, toes to the water
	var boxes = [[8, 18], [34, 46], [56, 68]]
	var ids = ["sandal_a", "sandal_b", "sandal_c"]
	for i in 3:
		var sp = shore(z, boxes[i][0], boxes[i][1], 26, 44)
		if sp != Vector2.ZERO:
			z.decor.append({"tex": "sandals", "pos": sp, "solid": false})
			z.things.append({"id": ids[i], "pos": sp, "h": 26.0})
	# the net-mender's boat
	var bp = shore(z, 22, 32, 27, 44)
	if bp != Vector2.ZERO:
		z.decor.append({"tex": "boat", "pos": bp + Vector2(0, -2), "solid": true, "bw": 40.0})
		z.things.append({"id": "widow", "pos": bp + Vector2(0, 4), "h": 50.0})
	z.decor.append({"tex": "sign", "pos": tp(5.5, 21.9), "solid": false})
	z.decor.append({"tex": "sign", "pos": tp(60.6, 21.9), "solid": false})
	z.things.append({"id": "sign", "pos": tp(60.6, 22.6), "h": 54.0})
	for x in [13.0, 25.0, 38.0, 51.0]:
		z.decor.append({"tex": "fence", "pos": tp(x, 21.9), "solid": false})
	scatter(z, "tree_willow", 8, 1, 14.0)
	scatter(z, "tree_dead", 4, 2, 12.0)
	scatter(z, "boulder", 5, 3, 44.0)
	dress(z, 123)
	return z

# ---------------------------------------------------------------- The Old Ferry

# the nearest grass or mud tile to (x, y), searched in widening squares
static func land(z: Dictionary, x: int, y: int) -> Vector2:
	for r in 12:
		for j in range(-r, r + 1):
			for i in range(-r, r + 1):
				var xx = x + i
				var yy = y + j
				if xx > 1 and yy > 1 and xx < z.w - 2 and yy < z.h - 2 and (z.grid[yy][xx] == 1 or z.grid[yy][xx] == 2) and z.grid[yy + 1][xx] != 0 and z.grid[yy][xx + 1] != 0:
					return tp(xx + 0.5, yy + 0.5)
	return tp(x, y)

# Five islands joined by plank bridges, west to east:
# landing, reed bank, drowned market, toll yard (the Keeper, and a gate he holds shut), net lofts, ferry deck.
static func dungeon() -> Dictionary:
	var z = empty("dungeon", "BẾN PHÀ CŨ", 110, 32)
	z.dark = true
	z.tier = 1
	z.mult = 1.35
	fill(z, 2, 12, 10, 19, 2)       # landing
	fill(z, 10, 15, 17, 16, 3)
	fill(z, 17, 9, 28, 22, 1)       # reed bank
	fill(z, 19, 11, 26, 20, 2)
	fill(z, 28, 15, 34, 16, 3)
	fill(z, 34, 8, 47, 23, 1)       # drowned market
	fill(z, 36, 11, 45, 20, 2)
	fill(z, 47, 15, 53, 16, 3)
	fill(z, 53, 8, 66, 23, 2)       # toll yard
	fill(z, 55, 10, 64, 21, 3)
	fill(z, 66, 15, 72, 16, 3)
	fill(z, 72, 7, 85, 24, 3)       # net lofts, with two holes in the floor
	fill(z, 76, 11, 78, 13, 0)
	fill(z, 80, 18, 82, 20, 0)
	fill(z, 85, 15, 90, 16, 3)
	fill(z, 90, 5, 105, 26, 3)      # ferry deck
	for y in range(5, 27):
		for x in range(90, 106):
			if Vector2((x - 97.5) / 8.0, (y - 15.5) / 11.0).length() > 1.0:
				z.grid[y][x] = 0
	for q in [[4.0, 12.5], [9.0, 19.5], [18.5, 9.5], [27.5, 22.5], [35.0, 8.5], [46.5, 23.5], [54.0, 8.5], [65.5, 23.5], [73.0, 7.6], [84.5, 24.4], [92.0, 9.0], [103.5, 9.0], [92.0, 23.5], [103.5, 23.5]]:
		lantern(z, q[0], q[1])
	z.portals.append({"rect": Rect2(tp(2, 12), Vector2(TS * 1.2, TS * 8)), "to": "field", "at": tp(63.0, 3.5), "label": "VỀ ĐẦM LAU", "need": ""})
	z.start = tp(5.0, 15.5)
	for q in [[21, 12], [24, 18], [20, 17], [25, 13]]:
		z.spawns.append({"kind": "reed", "pos": tp(q[0], q[1])})
	for q in [[38, 12], [43, 19], [40, 16]]:
		z.spawns.append({"kind": "leech", "pos": tp(q[0], q[1])})
	for q in [[44, 11], [37, 20]]:
		z.spawns.append({"kind": "netter", "pos": tp(q[0], q[1])})
	z.spawns.append({"kind": "reed", "pos": tp(41.5, 13.0), "elite": "volatile"})
	z.spawns.append({"kind": "keeper", "pos": tp(60.5, 15.8), "once": "keeper_dead"})
	for q in [[56, 10.5], [63, 21]]:
		z.spawns.append({"kind": "heron", "pos": tp(q[0], q[1])})
	for q in [[79.5, 9], [83.5, 22]]:
		z.spawns.append({"kind": "wisp", "pos": tp(q[0], q[1])})
	for q in [[74, 10], [75, 21.5], [84, 16]]:
		z.spawns.append({"kind": "reed", "pos": tp(q[0], q[1])})
	z.spawns.append({"kind": "porter", "pos": tp(78.5, 16.0)})
	z.spawns.append({"kind": "leech", "pos": tp(80.5, 15.0)})
	z.spawns.append({"kind": "netter", "pos": tp(82.5, 12.0), "elite": "warding"})
	z.spawns.append({"kind": "boss", "pos": tp(99.0, 15.5)})
	z.gates.append({"rect": Rect2(tp(67, 14.5), Vector2(TS, TS * 3)), "flag": "keeper_dead"})
	z.decor.append({"tex": "boat", "pos": tp(8.0, 13.2), "solid": true, "bw": 40.0})
	z.decor.append({"tex": "tree_dead", "pos": tp(18.2, 21.8), "solid": true, "bw": 12.0})
	z.decor.append({"tex": "tree_dead", "pos": tp(27.2, 10.6), "solid": true, "bw": 12.0})
	z.decor.append({"tex": "crates", "pos": tp(36.0, 9.6), "solid": true})
	z.decor.append({"tex": "cart", "pos": tp(44.0, 22.4), "solid": true})
	z.decor.append({"tex": "crates", "pos": tp(46.0, 10.0), "solid": true})
	z.decor.append({"tex": "boulder", "pos": tp(35.6, 22.6), "solid": true, "bw": 44.0})
	z.decor.append({"tex": "crates", "pos": tp(65.0, 9.6), "solid": true})
	z.decor.append({"tex": "netrack", "pos": tp(74.5, 23.6), "solid": true, "bw": 40.0})
	z.decor.append({"tex": "netrack", "pos": tp(83.5, 8.4), "solid": true, "bw": 40.0})
	# the night Van died replays at the mouth of the toll yard
	z.scenes.append({"id": "van", "rect": Rect2(tp(52.5, 13), Vector2(TS * 3, TS * 6)), "at": tp(57.5, 15.4)})
	dress(z, 77)
	return z

# ---------------------------------------------------------------- chapter two: the Breathing Forest

# Whisper Village sits in the north-west clearing; the Remembering Tree is entered from the east.
static func forest() -> Dictionary:
	var z = empty("forest", "RỪNG THỞ", 84, 52)
	z.theme = "forest"
	z.respawn = true
	z.tier = 1
	z.mult = 1.7
	for y in z.h:
		for x in z.w:
			var dx = (x - 42.0) / 38.0
			var dy = (y - 26.0) / 23.0
			var a = atan2(dy, dx)
			var d = sqrt(dx * dx + dy * dy) + sin(a * 4.0 + 0.7) * 0.06 + sin(a * 9.0 + 2.1) * 0.04
			if d < 1.0:
				var n = int(Art.noise(x * 0.19, y * 0.23, 41) * 100.0) - 30
				z.grid[y][x] = 2 if n < 20 else 1
	for pond in [[30, 36, 4.0, 2.4], [56, 14, 3.4, 2.2], [62, 38, 3.0, 2.0], [40, 22, 2.2, 1.5]]:
		for y in z.h:
			for x in z.w:
				if Vector2((x - pond[0]) / pond[2], (y - pond[1]) / pond[3]).length() < 1.0:
					z.grid[y][x] = 0
	fill(z, 0, 25, 12, 26, 3)       # the way in from the marsh
	fill(z, 12, 25, 72, 26, 2)      # the forest road
	fill(z, 72, 25, 83, 26, 3)      # root bridge to the Remembering Tree
	fill(z, 14, 9, 30, 19, 2)       # the village clearing
	fill(z, 21, 19, 22, 25, 2)
	z.portals.append({"rect": Rect2(tp(0, 24), Vector2(TS * 1.2, TS * 4)), "to": "field", "at": tp(67.0, 23.0), "label": "VỀ ĐẦM LAU", "need": ""})
	z.portals.append({"rect": Rect2(tp(82, 24), Vector2(TS * 2, TS * 4)), "to": "heart", "at": tp(5.0, 17.5), "label": "LÒNG CÂY GHI NHỚ", "need": "m10"})
	z.start = tp(3.0, 26.0)
	z.decor.append({"tex": "hut", "pos": tp(17.0, 12.4), "solid": true})
	z.decor.append({"tex": "hut", "pos": tp(27.5, 12.0), "solid": true})
	z.decor.append({"tex": "hut", "pos": tp(22.0, 10.4), "solid": true})
	z.decor.append({"tex": "gate", "pos": tp(21.5, 19.6), "solid": false})
	z.decor.append({"tex": "npc_kid", "pos": tp(19.5, 16.0), "solid": false})
	for q in [[15.0, 15.0], [29.5, 17.0], [24.5, 13.2]]:
		lantern(z, q[0], q[1])
	for x in [36.0, 50.0, 64.0]:
		lantern(z, x, 24.8)
	z.npcs = [{"id": "reu", "pos": tp(22.0, 14.0)}, {"id": "man", "pos": tp(25.5, 16.2)}]
	z.things.append({"id": "verdict", "pos": tp(21.5, 20.4), "h": 60.0})
	# foes: wolves in threes, sowers by the pools, stags on open ground
	for q in [[44, 14], [60, 30], [36, 42], [70, 20]]:
		for i in 3:
			z.spawns.append({"kind": "wolf", "pos": land(z, q[0] + i * 2 - 2, q[1] + (i % 2) * 2)})
	for q in [[52, 17], [34, 33], [64, 42], [46, 36], [70, 34]]:
		z.spawns.append({"kind": "sower", "pos": land(z, q[0], q[1])})
	for q in [[50, 44], [58, 22], [28, 44]]:
		z.spawns.append({"kind": "deer", "pos": land(z, q[0], q[1])})
	z.spawns.append({"kind": "wolf", "pos": land(z, 48, 30), "elite": "volatile"})
	z.spawns.append({"kind": "sower", "pos": land(z, 66, 26), "elite": "warding"})
	# three trunks where a name was cut away, low down
	var ids = ["trunk_a", "trunk_b", "trunk_c"]
	var at = [[12, 34], [44, 8], [74, 40]]
	for i in 3:
		var tpos = land(z, at[i][0], at[i][1])
		z.decor.append({"tex": "trunk", "pos": tpos, "solid": true, "bw": 18.0})
		z.things.append({"id": ids[i], "pos": tpos + Vector2(0, 6), "h": 56.0})
	scatter(z, "tree_giant", 9, 11, 26.0)
	scatter(z, "shrooms", 12, 12, 16.0)
	scatter(z, "log", 5, 13, 40.0)
	dress(z, 301)
	return z

# Inside the tree: groves joined by roots, a hall where the tree remembers, and the Mother at the heart.
static func heart() -> Dictionary:
	var z = empty("heart", "LÒNG CÂY GHI NHỚ", 92, 34)
	z.theme = "forest"
	z.dark = true
	z.tier = 2
	z.mult = 2.1
	fill(z, 2, 14, 10, 21, 2)       # the hollow at the entrance
	fill(z, 10, 17, 17, 18, 3)
	fill(z, 17, 10, 31, 25, 1)      # first grove
	fill(z, 19, 12, 29, 23, 2)
	fill(z, 31, 17, 37, 18, 3)
	fill(z, 37, 8, 52, 27, 1)       # second grove
	fill(z, 40, 11, 49, 24, 2)
	fill(z, 52, 17, 57, 18, 3)
	fill(z, 57, 13, 65, 22, 3)      # the hall of rings
	fill(z, 65, 17, 69, 18, 3)
	fill(z, 69, 6, 89, 29, 2)       # the heart
	for y in range(6, 30):
		for x in range(69, 90):
			if Vector2((x - 79.0) / 10.0, (y - 17.5) / 11.5).length() > 1.0:
				z.grid[y][x] = 0
	fill(z, 65, 17, 71, 18, 3)
	for q in [[4.0, 14.5], [9.0, 21.5], [18.5, 10.5], [30.5, 25.5], [38.5, 8.5], [51.5, 27.5], [58.0, 13.6], [64.5, 22.4], [72.0, 12.0], [86.0, 12.0], [72.0, 24.0], [86.0, 24.0]]:
		lantern(z, q[0], q[1])
	z.portals.append({"rect": Rect2(tp(2, 14), Vector2(TS * 1.2, TS * 8)), "to": "forest", "at": tp(80.0, 26.0), "label": "RA RỪNG THỞ", "need": ""})
	z.start = tp(5.0, 17.5)
	for q in [[21, 13], [27, 22], [24, 17]]:
		z.spawns.append({"kind": "wolf", "pos": tp(q[0], q[1])})
	z.spawns.append({"kind": "sower", "pos": tp(28.0, 12.5)})
	z.spawns.append({"kind": "sower", "pos": tp(20.5, 22.5)})
	for q in [[42, 13], [47, 22]]:
		z.spawns.append({"kind": "deer", "pos": tp(q[0], q[1])})
	for q in [[41, 21], [48, 12], [45, 17]]:
		z.spawns.append({"kind": "wolf", "pos": tp(q[0], q[1])})
	z.spawns.append({"kind": "sower", "pos": tp(50.0, 25.0), "elite": "warding"})
	z.spawns.append({"kind": "deer", "pos": tp(39.5, 9.5), "elite": "volatile"})
	z.spawns.append({"kind": "mother", "pos": tp(80.0, 16.5)})
	z.decor.append({"tex": "shrooms", "pos": tp(18.4, 24.6), "solid": true, "bw": 16.0})
	z.decor.append({"tex": "shrooms", "pos": tp(30.2, 11.0), "solid": true, "bw": 16.0})
	z.decor.append({"tex": "log", "pos": tp(38.6, 26.4), "solid": true, "bw": 40.0})
	z.decor.append({"tex": "shrooms", "pos": tp(51.0, 9.4), "solid": true, "bw": 16.0})
	z.decor.append({"tex": "trunk", "pos": tp(58.4, 14.6), "solid": true, "bw": 18.0})
	z.decor.append({"tex": "trunk", "pos": tp(64.0, 14.6), "solid": true, "bw": 18.0})
	# what the tree remembers of the bell plays in the hall of rings
	z.scenes.append({"id": "bell", "rect": Rect2(tp(58.5, 15.5), Vector2(TS * 5, TS * 5)), "at": tp(61.0, 15.6)})
	dress(z, 302)
	return z

# ---------------------------------------------------------------- after the verdict (m11)
# The choice at the village gate shows on the map once chapter two is over. village: 0 sealed, 1 kept.
static func fate(z: Dictionary, village: int) -> void:
	if z.id == "forest":
		var yard = Rect2(tp(14, 9), tp(17, 11))
		z.things = z.things.filter(func(th): return th.id != "verdict")
		z.things.append({"id": "stone_set" if village == 0 else "stone_down", "pos": tp(21.5, 20.4), "h": 60.0})
		if village == 0:
			z.decor = z.decor.filter(func(dc): return dc.tex != "npc_kid" and not (dc.tex == "lantern" and yard.has_point(dc.pos)))
			z.lanterns = z.lanterns.filter(func(lp): return not yard.has_point(lp - Vector2(4, -20)))
			z.npcs = z.npcs.filter(func(n): return n.id != "man")
			z.things.append({"id": "yard_empty", "pos": tp(20.0, 15.5), "h": 30.0})
		else:
			z.decor.append({"tex": "npc_kid", "pos": tp(26.5, 15.2), "solid": false})
			z.decor.append({"tex": "npc_kid", "pos": tp(17.5, 17.0), "solid": false})
			lantern(z, 20.0, 18.0)
			z.things.append({"id": "yard_play", "pos": tp(20.0, 15.5), "h": 30.0})
	elif z.id == "town":
		if village == 0:
			z.decor.append({"tex": "fence", "pos": tp(26.0, 15.4), "solid": false})
			z.things.append({"id": "silence_notice", "pos": tp(26.0, 15.8), "h": 30.0})
		else:
			z.decor.append({"tex": "cart", "pos": tp(39.5, 21.0), "solid": true})
			z.decor.append({"tex": "crates", "pos": tp(41.5, 19.6), "solid": true})
			z.things.append({"id": "refugee_cart", "pos": tp(39.5, 22.2), "h": 30.0})
