extends RefCounted
# Pet skills, pet hearts (bond) and the exclusive passive each pet unlocks at 3 hearts.
#
# Every pet casts its own skill by itself when a foe is near and the cooldown is up.
# Hearts are earned by feeding treats (grown in the garden) at the pet bowl in the Hearth.
# Each heart shortens the skill cooldown by 10%; the third unlocks the passive.

const D = preload("res://src/data.gd")
const Meta = preload("res://src/meta.gd")
const Sfx = preload("res://src/sfx.gd")

const CD = 9.0
const MAX_HEARTS = 3
const SKILL = {"pup": "FLAME POUNCE", "owl": "FROST GUST", "mote": "OVERCHARGE", "toad": "SPORE BELCH"}
const PASSIVE = {
	"pup": ["EMBER HEART", "ITS SHOTS EXPLODE"],
	"owl": ["WATCHFUL", "BLOCKS ONE HIT ON YOU PER ROOM"],
	"mote": ["CONDUCTOR", "YOUR KILLS RESTORE 3 ENERGY"],
	"toad": ["TOXIC SKIN", "WHEN YOU ARE HURT, A VENOM CLOUD BURSTS OUT"],
}

static func hearts(id: String) -> int:
	return int(Meta.S.bond.get(id, 0))

static func has_passive(pl: Dictionary, id: String) -> bool:
	return pl.pet != null and pl.pet.id == id and int(pl.pet.get("hearts", 0)) >= MAX_HEARTS

# Called once per frame for the hero bound as g.p.
static func update(g, dt: float) -> void:
	var p = g.p
	if p.pet == null:
		return
	var pet = p.pet
	pet.sk = float(pet.get("sk", 4.0)) - dt
	if pet.sk > 0.0:
		return
	var e = g.nearest_enemy(pet.pos, 120.0, [])
	if e == null:
		return
	pet.sk = CD * (1.0 - 0.1 * int(pet.get("hearts", 0)))
	var c: Vector2 = g.center(e)
	var fl: int = g.floor_i
	var el: String = Meta.PETS[pet.id].el
	var col: Color = D.EL_COL[el]
	g.label(pet.pos + Vector2(0, -14), SKILL[pet.id], col)
	Sfx.play("skill", 1.5, -6.0)
	match pet.id:
		"pup":
			g.bolts.append({a = pet.pos, b = e.pos, col = col, t = 0.18, straight = true})
			pet.pos = e.pos
			g.explode(c, 34.0, 8.0 + fl * 2.0, "fire", 0)
		"owl":
			var done = []
			for i in 3:
				var o = g.nearest_enemy(c, 90.0, done)
				if o == null:
					break
				done.append(o)
				g.hurt_enemy(o, 3.0 + fl, "ice")
				if not o.dead:
					o.frz = maxf(o.frz, 0.5 if o.is_boss else 1.4)
			g.rings.append({pos = c, r = 60.0, t = 0.0, col = col})
			Sfx.play("freeze", 1.0, -4.0)
		"mote":
			var done = []
			var from: Vector2 = pet.pos
			for i in 4:
				var o = g.nearest_enemy(from, 100.0, done)
				if o == null:
					break
				done.append(o)
				g.bolt(from, g.center(o), col)
				from = g.center(o)
				g.hurt_enemy(o, 5.0 + fl * 1.5, "bolt")
			p.en = minf(p.men, p.en + 15.0)
		"toad":
			g.hurt_enemy(e, 4.0 + fl, "tox")
			g.Ext.add_zone(g, e.pos, 26.0, "tox", 4.0)

# ---- passives --------------------------------------------------------------------

static func on_kill(g) -> void:
	if has_passive(g.p, "mote"):
		g.p.en = minf(g.p.men, g.p.en + 3.0)

# True when the owl took the hit instead of its owner.
static func guard(g) -> bool:
	var p = g.p
	if has_passive(p, "owl") and p.pet.get("guard", true):
		p.pet.guard = false
		p.inv = 0.6
		Sfx.play("slash", 0.7)
		g.label(p.pos + Vector2(0, -22), "OWL GUARD", D.EL_COL["ice"])
		g.rings.append({pos = g.pcenter(), r = 18.0, t = 0.0, col = D.EL_COL["ice"]})
		return true
	return false

static func on_hurt(g) -> void:
	if has_passive(g.p, "toad"):
		g.Ext.add_zone(g, g.p.pos, 30.0, "tox", 3.0)

# ---- the bowl --------------------------------------------------------------------

static func feed(g, it: Dictionary) -> void:
	var at = g.p.pos + Vector2(0, -24)
	var id: String = Meta.S.pet
	if id == "" or not Meta.PETS.has(id):
		g.label(at, "YOU HAVE NO PET WITH YOU", Color("a8a7b8"))
		return
	var h = hearts(id)
	if h >= MAX_HEARTS:
		g.label(at, "%s: %s" % [PASSIVE[id][0], PASSIVE[id][1]], Color("ff6a7a"))
		return
	if int(Meta.S.treats) <= 0:
		Sfx.play("deny")
		g.label(at, "NO TREATS. GROW PET BERRIES IN THE GARDEN.", Color("ff6a6a"))
		return
	Meta.S.treats = int(Meta.S.treats) - 1
	Meta.S.bond[id] = h + 1
	Meta.save()
	if g.p.pet != null:
		g.p.pet.hearts = h + 1
	Sfx.play("pick")
	g.burst(it.pos + Vector2(0, -6), 10, Color("ff6a7a"), 50.0, 0.7, -50.0)
	if h + 1 >= MAX_HEARTS:
		g.banner = {text = Meta.PETS[id].name + ": " + PASSIVE[id][0], sub = PASSIVE[id][1], t = 4.0}
		Sfx.play("chest")
	else:
		g.label(at, "%s LOVES IT! HEARTS %d/%d" % [Meta.PETS[id].name, h + 1, MAX_HEARTS], Color("ff6a7a"))
