extends SceneTree

const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")

func _init() -> void:
	var failures: Array[String] = []

	await _check_direct_fx_spawns(failures)
	await _check_weapon_and_dash_hooks(failures)
	await _check_enemy_telegraph_hook(failures)

	if failures.is_empty():
		print("Combat animation smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_direct_fx_spawns(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	CombatFxScript.spawn_slash(parent, Vector2(10, 10), Vector2.RIGHT)
	CombatFxScript.spawn_muzzle_flash(parent, Vector2(20, 10), Vector2.RIGHT)
	CombatFxScript.spawn_dash_ghost(parent, null, Vector2(30, 10), false)
	CombatFxScript.spawn_telegraph(parent, Vector2(40, 10), Vector2.RIGHT, 24.0, 0.2)
	await process_frame
	if parent.get_node_or_null("CombatFxSlash") == null:
		failures.append("spawn_slash should create CombatFxSlash")
	if parent.get_node_or_null("CombatFxMuzzleFlash") == null:
		failures.append("spawn_muzzle_flash should create CombatFxMuzzleFlash")
	if parent.get_node_or_null("CombatFxDashGhost") == null:
		failures.append("spawn_dash_ghost should create CombatFxDashGhost")
	if parent.get_node_or_null("CombatFxTelegraph") == null:
		failures.append("spawn_telegraph should create CombatFxTelegraph")
	await create_timer(0.45).timeout
	if parent.get_node_or_null("CombatFxSlash") != null:
		failures.append("CombatFxSlash should clean itself up")
	parent.free()

func _check_weapon_and_dash_hooks(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "CombatAnimationTestScene"
	root.add_child(scene)
	current_scene = scene

	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	scene.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	var weapon := player.current_weapon()
	if weapon == null:
		failures.append("player should have a starter weapon")
		scene.free()
		return

	if not weapon.try_attack(player.global_position, Vector2.RIGHT):
		failures.append("melee weapon should attack for hook smoke")
	await process_frame
	if scene.get_node_or_null("CombatFxSlash") == null:
		failures.append("melee attack should spawn CombatFxSlash")

	await create_timer(0.65).timeout
	weapon.equip("scrap_pistol")
	if not weapon.try_attack(player.global_position, Vector2.RIGHT):
		failures.append("ranged weapon should attack for hook smoke")
	await process_frame
	if scene.get_node_or_null("CombatFxMuzzleFlash") == null:
		failures.append("ranged attack should spawn CombatFxMuzzleFlash")

	player.call("_start_dash", Vector2.RIGHT)
	await process_frame
	if scene.get_node_or_null("CombatFxDashGhost") == null:
		failures.append("dash should spawn CombatFxDashGhost")

	scene.free()

func _check_enemy_telegraph_hook(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "CombatAnimationEnemyScene"
	root.add_child(scene)
	current_scene = scene

	var target := Node2D.new()
	target.global_position = Vector2(30, 0)
	scene.add_child(target)

	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.kind = "melee_charger"
	enemy.target = target
	enemy.global_position = Vector2.ZERO
	scene.add_child(enemy)

	await process_frame
	enemy.call("_physics_process", 1.0 / 60.0)
	await process_frame
	if scene.get_node_or_null("CombatFxTelegraph") == null:
		failures.append("charger telegraph should spawn CombatFxTelegraph")

	scene.free()
