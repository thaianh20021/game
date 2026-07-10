class_name SnareTrapSkill
extends RefCounted

const PlayerSnareTrapScript := preload("res://scripts/skills/player_snare_trap.gd")
const MAX_TRAPS := 2
const ROOT_DURATION := 1.5
const TRAP_DURATION := 12.0

static func execute(ctx: Dictionary) -> void:
	var player: Player = ctx["player"]
	var scene: Node = ctx["scene"]
	var aim_dir := Vector2(ctx["aim_dir"])
	if aim_dir.length_squared() <= 0.0:
		aim_dir = Vector2.RIGHT
	_trim_old_traps(scene, player)
	var trap := PlayerSnareTrapScript.new()
	trap.name = "SnareTrap"
	trap.set_meta("trap_type", "snare_trap")
	trap.set_meta("owner_id", player.get_instance_id())
	trap.configure(maxi(1, int(float(ctx["base_damage"]) * 0.35)), ROOT_DURATION, TRAP_DURATION)
	scene.add_child(trap)
	trap.global_position = player.global_position + aim_dir.normalized() * 48.0

static func _trim_old_traps(scene: Node, player: Player) -> void:
	var traps: Array[Node] = []
	for child in scene.get_children():
		if child.is_in_group("player_traps") \
				and int(child.get_meta("owner_id", player.get_instance_id())) == player.get_instance_id():
			traps.append(child)
	while traps.size() >= MAX_TRAPS:
		var oldest: Node = traps.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
