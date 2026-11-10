extends RefCounted
# Weapon extras: traits a fused weapon inherits from the weapon that was melted into it,
# and the steering of homing and returning projectiles.

const D = preload("res://src/data.gd")

const TRAIT_NAME = {
	"multi": "SPLITTING", "pierce": "PIERCING", "bounce": "REBOUND", "blast": "BLASTING",
	"zap": "ARCING", "homing": "SEEKING", "swift": "HASTE", "keen": "THE EDGE",
}
const TRAIT_DESC = {
	"multi": "+2 PROJECTILES", "pierce": "PIERCES 2 MORE FOES", "bounce": "BOUNCES TWICE MORE", "blast": "HITS EXPLODE",
	"zap": "HITS ARC TO A SECOND FOE", "homing": "SHOTS SEEK FOES", "swift": "25% FASTER", "keen": "+25% DAMAGE",
}

# What a weapon passes on when it is the one consumed by a fusion.
static func trait_of(id: String) -> String:
	var w = D.WEAPONS[id]
	if w.get("homing", 0.0) > 0.0:
		return "homing"
	if w.type == "chain":
		return "zap"
	if w.type == "lob" or w.get("aoe", 0.0) > 0.0 or w.get("slam", 0.0) > 0.0:
		return "blast"
	if w.get("n", 1) > 1:
		return "multi"
	if w.get("bounce", 0) > 0:
		return "bounce"
	if w.get("pierce", 0) > 0:
		return "pierce"
	if w.type == "melee":
		return "keen"
	return "swift"

# Applies a trait to a private copy of a weapon definition (never to D.WEAPONS itself).
static func apply(w: Dictionary, tr: String) -> void:
	if tr == "":
		return
	var bullet = w.type == "bullet"
	match tr:
		"multi":
			if bullet:
				w.n = w.get("n", 1) + 2
				w.fan = maxf(w.get("fan", 0.0), 0.3)
			elif w.type == "melee":
				w.arc = minf(w.arc * 1.35, 5.5)
			else:
				w.dmg *= 1.25
		"blast":
			if bullet:
				w.aoe = maxf(w.get("aoe", 0.0), 14.0)
			elif w.type == "melee":
				w.slam = maxf(w.get("slam", 0.0), 18.0)
			elif w.type == "lob":
				w.aoe *= 1.3
			else:
				w.dmg *= 1.25
		"pierce":
			if bullet:
				w.pierce = w.get("pierce", 0) + 2
			else:
				w.dmg *= 1.25
		"bounce":
			if bullet:
				w.bounce = w.get("bounce", 0) + 2
			else:
				w.dmg *= 1.25
		"homing":
			if bullet:
				w.homing = maxf(w.get("homing", 0.0), 3.0)
				w.life = maxf(w.get("life", 1.4), 1.8)
			else:
				w.dmg *= 1.25
		"zap":
			if bullet:
				w.zap = true
			else:
				w.dmg *= 1.25
		"keen":
			w.dmg *= 1.25

# Called for every flying player bullet before it moves.
static func steer(g, b: Dictionary, dt: float) -> void:
	var hm: float = b.get("homing", 0.0)
	if hm > 0.0:
		var best = null
		var bd = 120.0
		for e in g.enemies:
			if e.dead or b.hit.has(e.uid):
				continue
			var d = g.center(e).distance_to(b.pos)
			if d < bd:
				bd = d
				best = e
		if best != null:
			var spd: float = b.vel.length()
			b.vel = b.vel.normalized().slerp((g.center(best) - b.pos).normalized(), minf(1.0, dt * hm)) * spd
	if b.get("boomer", false):
		if not b.get("back", false) and b.age > 0.42:
			b.back = true
			b.hit = []
		if b.get("back", false):
			var owner: Dictionary = g.players[mini(int(b.get("own", 0)), g.players.size() - 1)]
			var to: Vector2 = owner.pos + Vector2(0, -3) - b.pos
			if to.length() < 9.0:
				b.dead = true
			else:
				b.vel = b.vel.lerp(to.normalized() * 280.0, minf(1.0, dt * 9.0))
				b.life = 1.0
