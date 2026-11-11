extends RefCounted
# Weather of a floor. Decided by the run seed alone, so a seed (and the daily run) always
# has the same forecast. The first floor is always clear.
#   rain     more mire; lightning through mire hits 50% harder; fire dies fast and spreads slowly
#   drought  dry brush everywhere; fire spreads twice as fast and burns longer
#   fog      short sight; steam and blizzards last twice as long
#   gale     lightning strikes the room on its own (it hits foes too, and runs through mire)

const D = preload("res://src/data.gd")
const Sfx = preload("res://src/sfx.gd")

const KINDS = ["rain", "drought", "fog", "gale", "clear"]
const NAME = {"clear": "CLEAR", "rain": "RAIN", "drought": "DROUGHT", "fog": "FOG", "gale": "GALE"}
const NOTE = {
	"clear": "", "rain": "MIRE CARRIES LIGHTNING. FIRE DIES FAST.", "drought": "BRUSH EVERYWHERE. FIRE RUNS.",
	"fog": "SHORT SIGHT. STEAM LINGERS.", "gale": "LIGHTNING STRIKES AT RANDOM.",
}

static func weather_for(seed: int, floor_i: int) -> String:
	if floor_i == 0:
		return "clear"
	var rng = RandomNumberGenerator.new()
	rng.seed = hash([seed, floor_i, "sky"])
	return KINDS[rng.randi() % KINDS.size()]

static func forecast(seed: int) -> String:
	var out = []
	for fl in range(1, 6):
		out.append(NAME[weather_for(seed, fl)])
	return " ".join(out)

static func now(g) -> String:
	return "clear" if g.in_lobby else str(g.dg.get("weather", "clear"))

# ---- multipliers the other systems ask for ----------------------------------------

static func zone_life(g, el: String) -> float:
	if el == "fire":
		return {"rain": 0.45, "drought": 1.6}.get(now(g), 1.0)
	return 1.0

static func field_life(g, key: String) -> float:
	var w = now(g)
	if w == "fog" and key == "fire+ice":
		return 2.0
	if w == "rain" and key == "fire+tox":
		return 0.6
	if w == "drought" and key == "fire+tox":
		return 1.5
	return 1.0

# Seconds for fire to step to the next brush tile.
static func spread_delay(g) -> float:
	return {"rain": 0.5, "drought": 0.11}.get(now(g), 0.22)

# Tail of the floor banner.
static func sub(g) -> String:
	var w = now(g)
	return "" if w == "clear" else "   " + NAME[w] + ". " + NOTE[w]

static func conduct_mult(g) -> float:
	return 1.5 if now(g) == "rain" else 1.0

static func sight(g) -> float:
	return 0.62 if now(g) == "fog" else 1.0

# ---- gale: the sky fights too -----------------------------------------------------

static func update(g, dt: float) -> void:
	if now(g) != "gale" or g.lock == null:
		return
	g.sky_t -= dt
	if g.sky_t > 0.0:
		return
	g.sky_t = g.rng.randf_range(2.6, 4.2)
	var pos: Vector2 = g.random_room_pos(g.lock, 0.0)
	if g.rng.randf() < 0.4:
		pos = g.p.pos + Vector2(g.rng.randf_range(-40, 40), g.rng.randf_range(-40, 40))
	g.tele_circle(pos, 20.0, 0.9)
	g.after(0.9, func():
		var col: Color = D.EL_COL["bolt"]
		g.bolt(pos + Vector2(g.rng.randf_range(-16, 16), -150), pos, col)
		g.rings.append({pos = pos, r = 20.0, t = 0.0, col = col})
		g.flash(pos, 110.0, col, 0.3)
		Sfx.play("boom", 1.6, -6.0)
		g.Env.touch(g, pos, 14.0, "bolt")
		for e in g.enemies:
			if not e.dead and e.pos.distance_to(pos) < 20.0 + e.r:
				g.hurt_enemy(e, 10.0 + g.floor_i * 3.0, "bolt", Vector2.ZERO, true)
		var keep = g.p
		for pl in g.players:
			if not pl.down and pl.pos.distance_to(pos) < 20.0:
				g.bind(pl)
				g.hurt_player(1, "bolt")
		g.bind(keep))

# ---- drawing (screen space, on the HUD layer) --------------------------------------

static func draw(g, ci: CanvasItem) -> void:
	var w = now(g)
	if w == "clear" or g.state == "title":
		return
	var t: float = g.time
	match w:
		"rain":
			ci.draw_rect(g.full(), Color(0.1, 0.16, 0.3, 0.12))
			for i in 46:
				var x = fmod(i * 53.7 + t * 90.0 + float(int(g.cam_tl.x) % 480), g.VW + 20.0) - 10.0 - g.hud_off.x
				var y = fmod(i * 31.3 + t * (260.0 + (i % 5) * 30.0), g.VH + 20.0) - 10.0 - g.hud_off.y
				ci.draw_line(Vector2(x, y), Vector2(x - 3, y + 8), Color(0.6, 0.78, 1.0, 0.35), 1.0)
		"drought":
			ci.draw_rect(g.full(), Color(0.5, 0.3, 0.05, 0.1))
			for i in 22:
				var x = fmod(i * 71.3 + t * 26.0, 500.0) - 10.0
				var y = fmod(i * 43.1 + sin(t * 0.7 + i) * 8.0 + 400.0, g.VH) - g.hud_off.y
				ci.draw_rect(Rect2(x, y, 1, 1), Color(1.0, 0.82, 0.4, 0.5))
		"fog":
			for i in 7:
				var x = fmod(i * 97.0 + t * (7.0 + i * 2.0), 640.0) - 150.0
				var y = 20.0 + i * 36.0 + sin(t * 0.4 + i) * 8.0
				ci.draw_rect(Rect2(x, y, 170, 22), Color(0.8, 0.85, 0.95, 0.07))
				ci.draw_rect(Rect2(x + 30, y + 6, 190, 14), Color(0.8, 0.85, 0.95, 0.06))
		"gale":
			ci.draw_rect(g.full(), Color(0.05, 0.03, 0.12, 0.14))
			for i in 16:
				var x = fmod(i * 61.0 - t * 240.0 + 9000.0, 520.0) - 20.0
				var y = fmod(i * 47.0 + t * 30.0, g.VH) - g.hud_off.y
				ci.draw_line(Vector2(x, y), Vector2(x + 14, y + 2), Color(0.85, 0.85, 1.0, 0.22), 1.0)
