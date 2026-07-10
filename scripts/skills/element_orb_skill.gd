class_name ElementOrbSkill
extends RefCounted

const SPEED := 240.0
const RANGE := 170.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx["scene"]
	var aim_dir := Vector2(ctx["aim_dir"])
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	var base_damage := int(ctx["base_damage"])
	var element := str(ctx["element"])
	var damage := int(base_damage * 1.2)

	var orb := Projectile.new()
	orb.name = "ElementOrbProjectile"
	orb.setup(aim_dir, SPEED, damage, RANGE, Color(0.5, 0.9, 1.0), element, player)
	orb.set_meta("skill_id", "element_orb")
	orb.set_meta("shape", "orb_projectile")
	orb.set_meta("range_px", RANGE)
	orb.set_meta("speed_px", SPEED)
	orb.set_meta("damage", damage)
	orb.set_meta("element", element)
	scene.add_child(orb)
	orb.global_position = player.global_position + aim_dir * 10.0
