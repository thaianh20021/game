extends RefCounted
# LAN co-op for two players. The host runs the whole simulation; the guest sends its
# input and draws what the host tells it, predicting only its own movement.
# Hosts announce themselves with a UDP broadcast so guests can find them without typing an IP.

const D = preload("res://src/data.gd")
const Art = preload("res://src/art.gd")
const Sfx = preload("res://src/sfx.gd")
const Dungeon = preload("res://src/dungeon.gd")

const PORT = 24242
const BEACON = 24243
const RATE = 1.0 / 20.0

static func fresh() -> Dictionary:
	return {mode = "", status = "", joined = false, udp = null, beacon_t = 0.0, hosts = [], snap_t = 0.0,
		rin = {mv = Vector2.ZERO, mw = Vector2.ZERO, fire = false, jp = {}}, guest = null, pred = Vector2.ZERO,
		blog = [], uids = {}, cracks = [], lock_id = -1, ip_in = ""}

static func local_ip() -> String:
	var best = "127.0.0.1"
	for a in IP.get_local_addresses():
		if a.contains(":") or a.begins_with("127.") or a.begins_with("169.254"):
			continue
		if a.begins_with("192.168.") or a.begins_with("10."):
			return a
		best = a
	return best

static func host(g) -> void:
	leave(g)
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(PORT, 1) != OK:
		g.net.status = "COULD NOT OPEN PORT %d" % PORT
		return
	g.multiplayer.multiplayer_peer = peer
	g.net.mode = "host"
	g.net.status = "HOSTING ON " + local_ip()
	var udp = PacketPeerUDP.new()
	udp.set_broadcast_enabled(true)
	udp.set_dest_address("255.255.255.255", BEACON)
	g.net.udp = udp

static func listen(g) -> void:
	if g.net.udp != null or g.net.mode != "":
		return
	var udp = PacketPeerUDP.new()
	if udp.bind(BEACON) == OK:
		g.net.udp = udp

static func join(g, ip: String) -> void:
	leave(g)
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(ip, PORT) != OK:
		g.net.status = "BAD ADDRESS"
		return
	g.multiplayer.multiplayer_peer = peer
	g.net.mode = "client"
	g.net.status = "CONNECTING TO " + ip

static func leave(g) -> void:
	if g.net.mode != "":
		g.multiplayer.multiplayer_peer = null
	if g.net.udp != null:
		g.net.udp.close()
	Sfx.logging = false
	var hosts = g.net.hosts
	g.net = fresh()
	g.net.hosts = hosts
	if g.players.size() > 1:
		g.players = [g.players[g.me]]
		g.players[0].idx = 0
		g.me = 0

# ---- connection events (wired to the multiplayer signals by the game node) --------

static func on_connected(g) -> void:
	g.net.status = "CONNECTED. WAITING FOR THE HOST TO START."
	g.net.joined = true
	g.rpc_id(1, "net_hello", g.p)
	refresh_menu(g)

static func on_failed(g) -> void:
	leave(g)
	g.net.status = "CONNECTION FAILED"
	refresh_menu(g)

static func on_peer_left(g) -> void:
	if g.net.mode == "host":
		g.net.guest = null
		g.net.joined = false
		g.net.status = "PARTNER LEFT. HOSTING ON " + local_ip()
		if g.players.size() > 1:
			g.players = [g.players[0]]
			g.banner = {text = "PARTNER DISCONNECTED", sub = "", t = 3.0}
	elif g.net.mode == "client":
		leave(g)
		g.net.status = "HOST DISCONNECTED"
		g.goto_lobby()

static func on_hello(g, pd: Dictionary) -> void:
	pd.idx = 1
	pd.remote = true
	pd.down = false
	g.net.guest = pd
	g.net.joined = true
	g.net.status = "PARTNER READY: " + str(pd.name)
	refresh_menu(g)

static func refresh_menu(g) -> void:
	if g.state == "menu" and g.menu.kind == "coop":
		var keep = g.menu.sel
		g.menu.rows = g.Lobby.rows(g, "coop")
		g.menu.sel = mini(keep, g.menu.rows.size() - 1)

# Called every frame regardless of state.
static func poll(g, dt: float) -> void:
	var n = g.net
	if n.udp != null:
		if n.mode == "host":
			n.beacon_t -= dt
			if n.beacon_t <= 0.0:
				n.beacon_t = 1.0
				n.udp.put_packet("DCORE".to_utf8_buffer())
		elif n.mode == "":
			while n.udp.get_available_packet_count() > 0:
				var pk = n.udp.get_packet()
				var ip = n.udp.get_packet_ip()
				if pk.get_string_from_utf8() == "DCORE" and ip != "" and not n.hosts.has(ip):
					n.hosts.append(ip)
					refresh_menu(g)
	# a guest waiting in its own lobby keeps the host up to date on which hero it plays
	if n.mode == "client" and n.joined and g.in_lobby and not g.p.is_empty():
		n.beacon_t -= dt
		if n.beacon_t <= 0.0:
			n.beacon_t = 1.0
			g.rpc_id(1, "net_hello", g.p)
	if n.mode == "host" and g.players.size() > 1 and g.players[1].get("remote", false) and g.state == "play" and not g.in_lobby:
		n.snap_t -= dt
		if n.snap_t <= 0.0:
			n.snap_t = RATE
			g.rpc("net_snap", snapshot(g))

# ---- host: starting a shared run -------------------------------------------------

static func start(g) -> void:
	g.local2 = false
	g.players = g.players.slice(0, 1)
	Sfx.logging = true
	Sfx.log.clear()
	g.start_run(0, false)
	var guest: Dictionary = g.net.guest
	g.bind(guest)
	g.calc_stats()
	guest.pos = g.players[0].pos + Vector2(14, 0)
	if guest.pet != null:
		guest.pet.pos = guest.pos
	g.players.append(guest)
	build_looks(g)
	g.bind(g.players[0])
	g.rpc("net_event", "start", {seed = g.run_seed, floor = g.floor_i, boss = g.dg.boss_id, heat = g.run_heat, host = g.players[0]})

# Each player's sprite is built locally from a small description, so fused and woven
# heroes look the same on both screens.
static func build_looks(g) -> void:
	for pl in g.players:
		pl.spr = Art.look(pl.look)

# ---- snapshots -------------------------------------------------------------------

static func snapshot(g) -> PackedByteArray:
	var en = []
	for e in g.enemies:
		if e.dead:
			continue
		var c = e.duplicate()
		c.erase("d")
		en.append(c)
	var bu = []
	for b in g.bullets:
		if not b.dead:
			bu.append([b.pos, b.vel, b.team, b.el, b.kind, b.r, b.lob, b.get("z", 0.0), b.age])
	var pr = []
	for q in g.props:
		pr.append([q.pos, q.kind, q.el, q.flash])
	var pk = []
	for k in g.pickups:
		pk.append([k.pos, k.kind, k.t])
	var cr = []
	for c in g.dg.cracks:
		cr.append(c.open)
	var rooms = []
	for r in g.dg.rooms:
		rooms.append([r.cleared, r.seen, r.wave])
	var snap = {
		fl = g.floor_i, pl = g.players, en = en, bu = bu, pr = pr, pk = pk, zo = g.zones, it = g.inter, te = g.teles, al = g.allies, tr = g.traps,
		lock = g.lock.id if g.lock != null else -1, rooms = rooms, cr = cr, nums = g.nums, rings = g.rings, bolts = g.bolts,
		sl = g.slashes, fla = g.flashes, bn = g.banner, boss = g.boss.uid if g.boss != null else 0, kills = g.kills, rt = g.run_time,
		sfx = Sfx.log.duplicate(), bl = g.net.blog.duplicate(), bk = g.boss_kills,
	}
	Sfx.log.clear()
	g.net.blog.clear()
	return var_to_bytes(snap).compress(FileAccess.COMPRESSION_GZIP)

static func apply(g, data: PackedByteArray) -> void:
	if g.net.mode != "client" or g.in_lobby:
		return
	var snap = bytes_to_var(data.decompress_dynamic(1 << 22, FileAccess.COMPRESSION_GZIP))
	if not (snap is Dictionary) or snap.fl != g.floor_i:
		return
	var n = g.net
	g.players = snap.pl
	for pl in g.players:
		pl.spr = Art.look(pl.look)
	var mine: Dictionary = g.players[g.me]
	if g.p.has("hp") and (mine.hp < g.p.hp or mine.ar < g.p.ar):
		g.dmg_flash = 1.0
		g.shake_add(4.0)
	# keep our own predicted position unless it drifted from the host's
	if n.pred.distance_to(mine.pos) > 22.0 or mine.dash_t > 0.0:
		n.pred = mine.pos
	else:
		n.pred = n.pred.lerp(mine.pos, 0.15)
	g.bind(mine)
	var en = []
	g.boss = null
	for e in snap.en:
		e.d = D.ENEMIES[e.id]
		en.append(e)
		if e.uid == snap.boss:
			g.boss = e
	g.enemies = en
	var bu = []
	for b in snap.bu:
		bu.append({pos = b[0], vel = b[1], team = b[2], el = b[3], kind = b[4], r = b[5], lob = b[6], z = b[7], age = b[8], dead = false})
	g.bullets = bu
	var pr = []
	for q in snap.pr:
		pr.append({pos = q[0], kind = q[1], el = q[2], flash = q[3], dead = false, hp = 1.0})
	g.props = pr
	var pk = []
	for k in snap.pk:
		pk.append({pos = k[0], kind = k[1], t = k[2], dead = false, vel = Vector2.ZERO})
	g.pickups = pk
	g.zones = snap.zo
	g.inter = snap.it
	g.teles = snap.te
	g.allies = snap.al
	g.traps = snap.tr
	g.nums = snap.nums
	g.rings = snap.rings
	g.bolts = snap.bolts
	g.slashes = snap.sl
	g.flashes = snap.fla
	g.kills = snap.kills
	g.boss_kills = snap.bk
	g.run_time = snap.rt
	if snap.bn.t > g.banner.t + 0.5 or snap.bn.text != g.banner.text:
		g.banner = snap.bn
	for s in snap.sfx:
		Sfx.play(s)
	for q in snap.bl:
		g.burst(q[0], q[1], q[2], q[3], q[4], q[5])
	# gates and secret walls change the collision grid
	if snap.lock != n.lock_id:
		if n.lock_id >= 0:
			for c in g.dg.rooms[n.lock_id].gates:
				g.dg.grid[c.y * g.dg.w + c.x] = 1
		n.lock_id = snap.lock
		g.lock = g.dg.rooms[n.lock_id] if n.lock_id >= 0 else null
		if g.lock != null:
			for c in g.lock.gates:
				g.dg.grid[c.y * g.dg.w + c.x] = 2
	for i in snap.rooms.size():
		var r = g.dg.rooms[i]
		r.cleared = snap.rooms[i][0]
		r.seen = r.seen or snap.rooms[i][1]
		r.wave = snap.rooms[i][2]
	var dirty = false
	for i in snap.cr.size():
		var c = g.dg.cracks[i]
		if snap.cr[i] and not c.open:
			c.open = true
			g.dg.grid[c.cell.y * g.dg.w + c.cell.x] = 1
			dirty = true
	if dirty:
		g.rebake()

static func on_event(g, kind: String, data: Dictionary) -> void:
	match kind:
		"start":
			g.in_lobby = false
			g.world.visible = true
			g.post.visible = true
			var mine: Dictionary = g.p
			mine.idx = 1
			g.players = [data.host, mine]
			g.me = 1
			g.run_seed = data.seed
			g.run_heat = data.heat
			g.run_daily = false
			g.kills = 0
			g.boss_kills = 0
			floor_event(g, data)
			g.set_state("play")
		"floor":
			floor_event(g, data)
		"end":
			g.floor_i = data.floor
			g.end_run(data.won)

static func floor_event(g, data: Dictionary) -> void:
	g.clear_world()
	g.floor_i = data.floor
	var bi = g.floor_i / 2
	g.drng.seed = hash([g.run_seed, g.floor_i])
	g.dg = Dungeon.generate(g.drng, g.floor_i, g.floor_i % 2 == 1)
	g.dg.boss_id = data.boss
	g.rebake()
	g.props = []
	g.light_bg.color = D.BIOMES[bi].ambient * 1.2
	g.net.lock_id = -1
	for r in g.dg.rooms:
		if r.type == "start":
			g.net.pred = g.rc(r)
			g.players[g.me].pos = g.net.pred
	g.cam = g.net.pred
	g.fade = 1.0
	g.banner = {text = D.BIOMES[bi].name, sub = "FLOOR %d-%d" % [bi + 1, g.floor_i % 2 + 1], t = 3.2}
	Sfx.play_music(bi)

# ---- guest: per-frame work -------------------------------------------------------

const KEYS = [KEY_SPACE, KEY_SHIFT, KEY_F, KEY_R, KEY_C, KEY_G, KEY_Q, KEY_E, "m2", "m4", "m5"]

static func client_tick(g, dt: float) -> void:
	var n = g.net
	var p = g.p
	var mv = Vector2(
		float(g.key(KEY_D) or g.key(KEY_RIGHT)) - float(g.key(KEY_A) or g.key(KEY_LEFT)),
		float(g.key(KEY_S) or g.key(KEY_DOWN)) - float(g.key(KEY_W) or g.key(KEY_UP)))
	if mv.length() > 0.0:
		mv = mv.normalized()
	if g.tin.on:
		if g.tin.mv != Vector2.ZERO:
			mv = g.tin.mv
		var td = g.Touch.aim_dir(g)
		if td != Vector2.ZERO:
			p.aim = td
	var mw: Vector2 = g.mouse() + g.cam_tl
	if not g.tin.on and (mw - g.pcenter()).length() > 1.0:
		p.aim = (mw - g.pcenter()).normalized()
	g.rpc_id(1, "net_input", mv, mw, g.firing())
	for k in KEYS:
		if g.jpk(k):
			g.rpc_id(1, "net_press", k)
	# predict our own walking so movement feels immediate
	if not p.get("down", false):
		var spd = 92.0 * p.st.spd * (0.6 if p.slow > 0.0 else 1.0) * (p.mount.spd if (p.mount != null and p.mount.hp > 0) else 1.0)
		var body = {pos = n.pred, r = p.r}
		g.move(body, mv * spd * dt)
		n.pred = body.pos
	p.pos = n.pred
	p.face = 1 if p.aim.x >= 0.0 else -1
	for b in g.bullets:
		if not b.lob:
			b.pos += b.vel * dt
		b.age += dt
	for e in g.enemies:
		e.anim += dt
	# which room are we in (for our own minimap)
	var t = Vector2i((p.pos / 16.0).floor())
	for r in g.dg.rooms:
		if r.rect.has_point(t):
			g.room = r
			r.seen = true
	g.find_near()
