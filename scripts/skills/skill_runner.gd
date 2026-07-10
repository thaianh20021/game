class_name SkillRunner
extends RefCounted
## Dispatches active skill ids to focused skill scripts.

const WindEdgeSkillScript := preload("res://scripts/skills/wind_edge_skill.gd")
const ElementOrbSkillScript := preload("res://scripts/skills/element_orb_skill.gd")
const ArrowRainSkillScript := preload("res://scripts/skills/arrow_rain_skill.gd")
const EarthbreakerSkillScript := preload("res://scripts/skills/earthbreaker_skill.gd")
const ShadowStepSkillScript := preload("res://scripts/skills/shadow_step_skill.gd")
const ShieldBastionSkillScript := preload("res://scripts/skills/shield_bastion_skill.gd")
const RollingGrenadeSkillScript := preload("res://scripts/skills/rolling_grenade_skill.gd")
const SummonWispSkillScript := preload("res://scripts/skills/summon_wisp_skill.gd")
const LightRaySkillScript := preload("res://scripts/skills/light_ray_skill.gd")
const MiniTurretSkillScript := preload("res://scripts/skills/mini_turret_skill.gd")
const LungeSkillScript := preload("res://scripts/skills/lunge_skill.gd")
const IronWillSkillScript := preload("res://scripts/skills/iron_will_skill.gd")
const PoisonKnifeSkillScript := preload("res://scripts/skills/poison_knife_skill.gd")
const BattleRoarSkillScript := preload("res://scripts/skills/battle_roar_skill.gd")
const NullRingSkillScript := preload("res://scripts/skills/null_ring_skill.gd")
const SnareTrapSkillScript := preload("res://scripts/skills/snare_trap_skill.gd")
const SpecialRoundsSkillScript := preload("res://scripts/skills/special_rounds_skill.gd")
const SacrificeSkillScript := preload("res://scripts/skills/sacrifice_skill.gd")
const SanctuarySkillScript := preload("res://scripts/skills/sanctuary_skill.gd")
const HackSkillScript := preload("res://scripts/skills/hack_skill.gd")

const SKILLS := {
	"wind_edge": WindEdgeSkillScript,
	"element_orb": ElementOrbSkillScript,
	"arrow_rain": ArrowRainSkillScript,
	"earthbreaker": EarthbreakerSkillScript,
	"shadow_step": ShadowStepSkillScript,
	"shield_bastion": ShieldBastionSkillScript,
	"rolling_grenade": RollingGrenadeSkillScript,
	"summon_wisp": SummonWispSkillScript,
	"light_ray": LightRaySkillScript,
	"mini_turret": MiniTurretSkillScript,
	"lunge": LungeSkillScript,
	"iron_will": IronWillSkillScript,
	"poison_knife": PoisonKnifeSkillScript,
	"battle_roar": BattleRoarSkillScript,
	"null_ring": NullRingSkillScript,
	"snare_trap": SnareTrapSkillScript,
	"special_rounds": SpecialRoundsSkillScript,
	"sacrifice": SacrificeSkillScript,
	"sanctuary": SanctuarySkillScript,
	"hack": HackSkillScript,
}

static func has_skill(skill_id: String) -> bool:
	return SKILLS.has(skill_id)

static func execute(skill_id: String, ctx: Dictionary) -> bool:
	if not SKILLS.has(skill_id):
		return false
	SKILLS[skill_id].execute(ctx)
	return true
