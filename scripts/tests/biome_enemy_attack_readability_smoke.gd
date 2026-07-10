extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

class DummyPlayer:
	extends Node2D
	var statuses := {}
	var damage_taken := 0

	func take_damage(amount: int, _from: Vector2 = Vector2.ZERO) -> void:
		damage_taken += amount

	func add_status(status_name: String, duration: float) -> void:
		statuses[status_name] = duration

	func has_status(status_name: String) -> bool:
		return statuses.has(status_name)

func _init() -> void:
	var failures: Array[String] = []
	await _check_projectile_profile("mycelium_archer", "ranged", "spore_shot", "poisoned", "SPORE", failures)
	await _check_projectile_profile("ember_acolyte", "caster", "ember_bolt", "burning", "EMBER", failures)
	await _check_projectile_profile("glyph_archer", "ranged", "archive_bolt", "chilled", "ARCHIVE", failures)
	await _check_telegraph_profile("coal_imp", "melee_charger", "hot_charge", "HOT", failures)
	await _check_telegraph_profile("puffcap_bomber", "exploder", "spore_bloom", "SPORE", failures)
	await _check_telegraph_profile("glass_bomber", "exploder", "glass_burst", "GLASS", failures)
	await _check_ranged_projectile_windup(failures)
	await _check_contact_damage_windup(failures)
	await _check_contact_damage_source_label(failures)
	if failures.is_empty():
		print("Biome enemy attack readability smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_projectile_profile(
		enemy_id: String,
		kind: String,
		expected_attack: String,
		expected_status: String,
		expected_label: String,
		failures: Array[String],
) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var enemy := _make_enemy(enemy_id, kind)
	scene.add_child(enemy)
	await process_frame
	enemy.call("_shoot", Vector2.RIGHT, 120.0, 3, 120.0)
	await process_frame
	var projectile := _first_projectile(scene)
	if projectile == null:
		failures.append("%s should fire a projectile" % enemy_id)
	else:
		if str(projectile.get_meta("enemy_attack", "")) != expected_attack:
			failures.append("%s projectile should tag enemy_attack=%s" % [enemy_id, expected_attack])
		if str(projectile.get_meta("hit_status", "")) != expected_status:
			failures.append("%s projectile should carry %s status" % [enemy_id, expected_status])
		if not str(projectile.get_meta("enemy_attack_label", "")).contains(expected_label):
			failures.append("%s projectile label should include %s" % [enemy_id, expected_label])
		if not projectile.has_meta("enemy_projectile_color"):
			failures.append("%s projectile should expose enemy_projectile_color" % enemy_id)
		_assert_enemy_projectile_sprite(projectile, enemy_id, failures)
		var player := Player.new()
		scene.add_child(player)
		await process_frame
		player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
		projectile.call("_on_body_entered", player)
		var damage_summary := str(player.call("damage_taken_summary"))
		if not damage_summary.contains("Enemy: %s 3" % expected_label):
			failures.append("%s projectile should record Enemy: %s damage source" % [
				enemy_id,
				expected_label,
			])
	scene.queue_free()
	await process_frame

func _check_telegraph_profile(
		enemy_id: String,
		kind: String,
		expected_attack: String,
		expected_label: String,
		failures: Array[String],
) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var target := DummyPlayer.new()
	target.global_position = Vector2(24, 0)
	scene.add_child(target)
	var enemy := _make_enemy(enemy_id, kind)
	enemy.target = target
	scene.add_child(enemy)
	await process_frame
	enemy.call("_physics_process", 1.0 / 60.0)
	await process_frame
	var fx := _first_attack_fx(scene, expected_attack)
	if fx == null:
		failures.append("%s should telegraph %s" % [enemy_id, expected_attack])
	else:
		var label := fx.get_node_or_null("AttackCueLabel") as Label
		if label == null or not label.text.contains(expected_label):
			failures.append("%s telegraph label should include %s" % [enemy_id, expected_label])
		if str(fx.get_meta("enemy_id", "")) != enemy_id:
			failures.append("%s telegraph should tag enemy id" % enemy_id)
	scene.queue_free()
	await process_frame

func _check_contact_damage_source_label(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := Player.new()
	scene.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	var enemy := _make_enemy("cave_slime", "melee")
	enemy.target = player
	enemy.global_position = player.global_position
	scene.add_child(enemy)
	await process_frame
	enemy.call("_try_contact_damage")
	enemy.call("_physics_process", 0.51)
	var damage_summary := str(player.call("damage_taken_summary"))
	if not damage_summary.contains("Enemy: Cave Slime 4"):
		failures.append("enemy contact should record readable enemy damage source")
	scene.queue_free()
	await process_frame

func _check_contact_damage_windup(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := Player.new()
	scene.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	var start_hp := player.hp
	var enemy := _make_enemy("cave_slime", "melee")
	enemy.target = player
	enemy.global_position = player.global_position
	scene.add_child(enemy)
	await process_frame
	enemy.call("_try_contact_damage")
	if player.hp != start_hp:
		failures.append("enemy contact should telegraph before first damage")
	if float(enemy.get_meta("contact_telegraph_seconds", 0.0)) < 0.5:
		failures.append("enemy contact should expose >=0.5s contact telegraph metadata")
	if scene.find_child("CombatFxTelegraph", true, false) == null:
		failures.append("enemy contact should spawn readable telegraph FX")
	enemy.call("_physics_process", 0.49)
	if player.hp != start_hp:
		failures.append("enemy contact should not damage before readable windup completes")
	enemy.call("_physics_process", 0.02)
	if player.hp >= start_hp:
		failures.append("enemy contact should damage after readable windup")
	scene.queue_free()
	await process_frame

func _check_ranged_projectile_windup(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var target := DummyPlayer.new()
	target.global_position = Vector2(100, 0)
	scene.add_child(target)
	var enemy := _make_enemy("mycelium_archer", "ranged")
	enemy.target = target
	scene.add_child(enemy)
	await process_frame
	enemy.call("_physics_process", 1.0 / 60.0)
	await process_frame
	if _first_projectile(scene) != null:
		failures.append("ranged enemy should not fire before readable projectile windup")
	if float(enemy.get_meta("projectile_telegraph_seconds", 0.0)) < 0.5:
		failures.append("ranged enemy should expose >=0.5s projectile telegraph metadata")
	var fx := _first_attack_fx(scene, "spore_shot")
	if fx == null:
		failures.append("ranged enemy should spawn projectile telegraph FX before firing")
	else:
		var label := fx.get_node_or_null("AttackCueLabel") as Label
		if label == null or not label.text.contains("SPORE"):
			failures.append("ranged projectile telegraph label should name the incoming shot")
	enemy.call("_physics_process", 0.40)
	await process_frame
	if _first_projectile(scene) != null:
		failures.append("ranged enemy should wait the full readable windup before projectile spawn")
	enemy.call("_physics_process", 0.20)
	await process_frame
	var projectile := _first_projectile(scene)
	if projectile == null:
		failures.append("ranged enemy should fire after readable projectile windup")
	elif str(projectile.get_meta("enemy_attack", "")) != "spore_shot":
		failures.append("windup-fired projectile should preserve attack metadata")
	scene.queue_free()
	await process_frame

func _make_enemy(enemy_id: String, kind: String) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.kind = kind
	enemy.set_meta("enemy_id", enemy_id)
	enemy.max_hp = 20
	enemy.contact_damage = 4
	return enemy

func _first_projectile(parent: Node) -> EnemyProjectile:
	for child in parent.get_children():
		if child is EnemyProjectile:
			return child
	return null

func _first_attack_fx(parent: Node, attack_id: String) -> Node:
	for child in parent.get_children():
		if child.has_meta("enemy_attack") and str(child.get_meta("enemy_attack", "")) == attack_id:
			return child
		var nested := _first_attack_fx(child, attack_id)
		if nested != null:
			return nested
	return null

func _assert_enemy_projectile_sprite(
		projectile: EnemyProjectile,
		enemy_id: String,
		failures: Array[String],
) -> void:
	var sprite := projectile.get_node_or_null("EnemyProjectileSprite") as AnimatedSprite2D
	if sprite == null or not sprite.visible:
		failures.append("%s projectile should use EnemyProjectileSprite visual" % enemy_id)
		return
	if str(sprite.get_meta("sprite_name", "")) != "zerie_arrow_projectile":
		failures.append("%s projectile sprite metadata should prefer reviewed Zerie arrow" % enemy_id)
	if int(sprite.get_meta("frame_count", 0)) != 1:
		failures.append("%s projectile sprite should store 1 frame count metadata" % enemy_id)
	if not bool(sprite.get_meta("stable_size", false)):
		failures.append("%s projectile sprite should expose stable frame grid metadata" % enemy_id)
	if not sprite.has_meta("projectile_color"):
		failures.append("%s projectile sprite should keep readability color metadata" % enemy_id)
	_assert_runtime_sprite_release_metadata(sprite, "zerie_arrow_projectile", "%s projectile" % enemy_id, failures)
	for child in projectile.get_children():
		if child is Polygon2D and child.visible:
			failures.append("%s projectile should hide polygon placeholder when sprite exists" % enemy_id)

func _assert_runtime_sprite_release_metadata(
		sprite: AnimatedSprite2D,
		sprite_name: String,
		label: String,
		failures: Array[String],
) -> void:
	var release := SpriteDB.release_report([sprite_name])
	var sprites: Dictionary = release.get("sprites", {})
	var entry: Dictionary = sprites.get(sprite_name, {})
	if str(sprite.get_meta("asset_source", "")) != str(entry.get("source", "")):
		failures.append("%s should expose asset_source release metadata" % label)
	if str(sprite.get_meta("release_decision", "")) != str(entry.get("release_decision", "")):
		failures.append("%s should expose release_decision metadata" % label)
	if str(sprite.get_meta("review_status", "")) != str(entry.get("review_status", "")):
		failures.append("%s should expose review_status metadata" % label)
	if str(sprite.get_meta("replacement_policy", "")) != str(entry.get("replacement_policy", "")):
		failures.append("%s should expose replacement_policy metadata" % label)
	if bool(sprite.get_meta("needs_replacement_before_public", true)) != bool(entry.get("needs_replacement_before_public", false)):
		failures.append("%s should expose replacement gate metadata" % label)
	if bool(sprite.get_meta("frame_grid_ok", false)) != bool(entry.get("frame_grid_ok", false)):
		failures.append("%s should expose frame_grid_ok metadata" % label)
