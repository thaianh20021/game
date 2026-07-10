class_name UltimateRunner
extends RefCounted

const PhantomSlashUltimateScript := preload("res://scripts/ultimates/phantom_slash_ultimate.gd")
const SkyfallUltimateScript := preload("res://scripts/ultimates/skyfall_ultimate.gd")
const SkypiercerUltimateScript := preload("res://scripts/ultimates/skypiercer_ultimate.gd")
const DeathDanceUltimateScript := preload("res://scripts/ultimates/death_dance_ultimate.gd")
const FortressUltimateScript := preload("res://scripts/ultimates/fortress_ultimate.gd")
const ElementalFuryUltimateScript := preload("res://scripts/ultimates/elemental_fury_ultimate.gd")
const SuppressingFireUltimateScript := preload("res://scripts/ultimates/suppressing_fire_ultimate.gd")
const SoulKingdomUltimateScript := preload("res://scripts/ultimates/soul_kingdom_ultimate.gd")
const VerdictUltimateScript := preload("res://scripts/ultimates/verdict_ultimate.gd")
const MobileFortressUltimateScript := preload("res://scripts/ultimates/mobile_fortress_ultimate.gd")

const ULTIMATES := {
	"phantom_slash": PhantomSlashUltimateScript,
	"skyfall": SkyfallUltimateScript,
	"skypiercer": SkypiercerUltimateScript,
	"death_dance": DeathDanceUltimateScript,
	"fortress": FortressUltimateScript,
	"elemental_fury": ElementalFuryUltimateScript,
	"suppressing_fire": SuppressingFireUltimateScript,
	"soul_kingdom": SoulKingdomUltimateScript,
	"verdict": VerdictUltimateScript,
	"mobile_fortress": MobileFortressUltimateScript,
}

static func has_ultimate(ultimate_id: String) -> bool:
	return ULTIMATES.has(ultimate_id)

static func execute(ultimate_id: String, ctx: Dictionary) -> bool:
	if not ULTIMATES.has(ultimate_id):
		return false
	ULTIMATES[ultimate_id].execute(ctx)
	return true
