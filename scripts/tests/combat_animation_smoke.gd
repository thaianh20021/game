extends SceneTree

const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")

func _init() -> void:
	var failures: Array[String] = []

	await _check_direct_fx_spawns(failures)
	await _check_weapon_and_dash_hooks(failures)
	await _check_weapon_identity_feedback_hooks(failures)
	await _check_local_sprite_action_hooks(failures)
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
	else:
		_assert_procedural_fx_review(parent.get_node_or_null("CombatFxSlash"), failures)
	if parent.get_node_or_null("CombatFxMuzzleFlash") == null:
		failures.append("spawn_muzzle_flash should create CombatFxMuzzleFlash")
	else:
		_assert_procedural_fx_review(parent.get_node_or_null("CombatFxMuzzleFlash"), failures)
	if parent.get_node_or_null("CombatFxDashGhost") == null:
		failures.append("spawn_dash_ghost should create CombatFxDashGhost")
	else:
		_assert_procedural_fx_review(parent.get_node_or_null("CombatFxDashGhost"), failures)
	if parent.get_node_or_null("CombatFxTelegraph") == null:
		failures.append("spawn_telegraph should create CombatFxTelegraph")
	else:
		var telegraph := parent.get_node_or_null("CombatFxTelegraph") as Node2D
		_assert_procedural_fx_review(telegraph, failures)
		if float(telegraph.get_meta("telegraph_seconds", 0.0)) < 0.5:
			failures.append("spawn_telegraph should tag readable >=0.5s telegraph duration")
		if float(telegraph.get_meta("requested_telegraph_seconds", 0.0)) < 0.19:
			failures.append("spawn_telegraph should keep requested telegraph duration metadata")
	await create_timer(0.45).timeout
	if parent.get_node_or_null("CombatFxSlash") != null:
		failures.append("CombatFxSlash should clean itself up")
	parent.free()

func _assert_procedural_fx_review(fx: Node, failures: Array[String]) -> void:
	if str(fx.get_meta("asset_source", "")) != "procedural_godot_shapes":
		failures.append("%s should mark procedural Godot shape source" % fx.name)
	if str(fx.get_meta("reference_policy", "")) != "fanmade_reference_only_no_copy":
		failures.append("%s should forbid copied fanmade source assets" % fx.name)
	if str(fx.get_meta("review_status", "")) != "stable_procedural_ok":
		failures.append("%s should mark procedural animation as stability-reviewed" % fx.name)
	if str(fx.get_meta("release_decision", "")) != "public_ok":
		failures.append("%s should be public-ok because it is project-owned procedural VFX" % fx.name)
	if not bool(fx.get_meta("frame_grid_ok", false)):
		failures.append("%s should not depend on mismatched sprite frame grids" % fx.name)

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
	var melee_sfx := weapon.get_node_or_null("WeaponAttackSfx") as AudioStreamPlayer
	if melee_sfx == null:
		failures.append("melee weapon attack should create attack sound placeholder")
	else:
		if str(melee_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("melee attack sound should come from AudioCueDB")
		if str(melee_sfx.get_meta("weapon_sound_id", "")) != "melee_attack":
			failures.append("melee attack sound should use melee_attack cue")
		if str(melee_sfx.get_meta("weapon_group", "")) == "":
			failures.append("melee attack sound should store weapon group metadata")
		if melee_sfx.stream == null:
			failures.append("melee attack sound should assign a placeholder stream")
	await process_frame
	if scene.get_node_or_null("CombatFxSlash") == null:
		failures.append("melee attack should spawn CombatFxSlash")

	await create_timer(0.65).timeout
	weapon.equip("scrap_pistol")
	if not weapon.try_attack(player.global_position, Vector2.RIGHT):
		failures.append("ranged weapon should attack for hook smoke")
	var ranged_sfx := weapon.get_node_or_null("WeaponAttackSfx") as AudioStreamPlayer
	if ranged_sfx == null:
		failures.append("ranged weapon attack should create attack sound placeholder")
	else:
		if str(ranged_sfx.get_meta("weapon_sound_id", "")) != "ranged_attack":
			failures.append("ranged attack sound should use ranged_attack cue")
		if str(ranged_sfx.get_meta("weapon_group", "")) != "pistol":
			failures.append("ranged attack sound should store pistol weapon group metadata")
	await process_frame
	if scene.get_node_or_null("CombatFxMuzzleFlash") == null:
		failures.append("ranged attack should spawn CombatFxMuzzleFlash")
	var projectile := _first_projectile(scene)
	if projectile == null:
		failures.append("ranged attack should spawn a projectile")
	else:
		_assert_projectile_sprite(projectile, failures)

	player.call("_start_dash", Vector2.RIGHT)
	await process_frame
	if scene.get_node_or_null("CombatFxDashGhost") == null:
		failures.append("dash should spawn CombatFxDashGhost")
	var dash_events: Array[Dictionary] = []
	if not player.has_signal("dash_cooldown_changed"):
		failures.append("dash should expose cooldown feedback signal")
	else:
		player.dash_cooldown_changed.connect(func(left: float, total: float) -> void:
			dash_events.append({"left": left, "total": total}))
		player.call("_start_dash", Vector2.RIGHT)
		player.call("_physics_process", player.dash_cooldown + 0.05)
		if dash_events.is_empty():
			failures.append("dash should emit cooldown feedback")
		elif float(dash_events[0].get("left", 0.0)) <= 0.0:
			failures.append("dash cooldown feedback should include active cooldown")
		if dash_events.is_empty() or float(dash_events.back().get("left", 1.0)) > 0.0:
			failures.append("dash cooldown feedback should emit ready state")

	scene.free()

func _first_projectile(parent: Node) -> Projectile:
	for child in parent.get_children():
		if child is Projectile:
			return child
	return null

func _assert_projectile_sprite(projectile: Projectile, failures: Array[String]) -> void:
	var sprite := projectile.get_node_or_null("ProjectileSprite") as AnimatedSprite2D
	if sprite == null or not sprite.visible:
		failures.append("player projectile should use ProjectileSprite visual")
		return
	if str(sprite.get_meta("sprite_name", "")) != "zerie_arrow_projectile":
		failures.append("player projectile sprite metadata should prefer reviewed Zerie arrow")
	if int(sprite.get_meta("frame_count", 0)) != 1:
		failures.append("player projectile sprite should store 1 frame count metadata")
	if not bool(sprite.get_meta("stable_size", false)):
		failures.append("player projectile sprite should expose stable frame grid metadata")
	_assert_runtime_sprite_release_metadata(sprite, "zerie_arrow_projectile", "player projectile", failures)
	for child in projectile.get_children():
		if child is Polygon2D and child.visible:
			failures.append("player projectile should hide polygon placeholder when sprite exists")

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

func _check_weapon_identity_feedback_hooks(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "WeaponIdentityFeedbackScene"
	root.add_child(scene)
	current_scene = scene

	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	scene.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("ranger"), "fire", "hardwood_bow")
	var weapon := player.current_weapon()
	if weapon == null:
		failures.append("weapon feedback smoke needs a starter weapon")
		scene.free()
		return

	if not player.has_method("_update_weapon_charge_feedback"):
		failures.append("player should expose weapon charge feedback updater")
	else:
		player.call("_update_weapon_charge_feedback", 0.75)
		var meter := player.get_node_or_null("WeaponChargeMeter")
		if meter == null:
			failures.append("bow charge should show WeaponChargeMeter")
		elif float(meter.get_meta("charge_ratio", 0.0)) < 0.74:
			failures.append("WeaponChargeMeter should store charge_ratio for HUD/debug")

	if not bool(weapon.call("try_charged_attack", player.global_position, Vector2.RIGHT,
			float(weapon.call("charge_time_full")))):
		failures.append("charged bow should fire for feedback check")
	await process_frame
	if scene.get_node_or_null("CombatFxWeaponCharge") == null:
		failures.append("full charge release should spawn CombatFxWeaponCharge")

	await create_timer(0.65).timeout
	weapon.equip("hunting_crossbow")
	weapon.call("_process", weapon.cooldown() + 0.05)
	player.velocity = Vector2.ZERO
	if not weapon.try_attack(player.global_position, Vector2.RIGHT):
		failures.append("stationary crossbow should attack for feedback check")
	await process_frame
	if scene.get_node_or_null("CombatFxStationaryFocus") == null:
		failures.append("stationary crossbow shot should spawn CombatFxStationaryFocus")

	await create_timer(0.75).timeout
	weapon.equip("spiked_board")
	player.set_meta("block_facing_dir", Vector2.RIGHT)
	player.call("take_damage", 10, player.global_position + Vector2.RIGHT * 20.0)
	await process_frame
	if scene.get_node_or_null("CombatFxBlockSpark") == null:
		failures.append("spiked board front block should spawn CombatFxBlockSpark")

	scene.free()

func _check_local_sprite_action_hooks(failures: Array[String]) -> void:
	var scene := Node2D.new()
	scene.name = "LocalSpriteActionScene"
	root.add_child(scene)
	current_scene = scene

	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	scene.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	var player_sprite := player.get_node("Sprite") as AnimatedSprite2D
	if not player_sprite.sprite_frames.has_animation("attack"):
		failures.append("local Blade Warden sprite should include attack animation")
	if not player_sprite.sprite_frames.has_animation("hurt"):
		failures.append("local Blade Warden sprite should include hurt animation")
	var weapon := player.current_weapon()
	if weapon == null or not weapon.try_attack(player.global_position, Vector2.RIGHT):
		failures.append("local Blade Warden should attack for sprite action smoke")
	else:
		await process_frame
		if player_sprite.animation != "attack":
			failures.append("weapon attack should briefly play local player attack animation")
	await create_timer(0.22).timeout
	player.take_damage(1, player.global_position + Vector2.RIGHT * 20.0)
	await process_frame
	if player_sprite.animation != "hurt":
		failures.append("player damage should briefly play local player hurt animation")

	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy: Enemy = enemy_scene.instantiate()
	scene.add_child(enemy)
	await process_frame
	enemy.configure_visual("zerie_orc_idle", "zerie_orc_walk")
	var enemy_sprite := enemy.get_node("Sprite") as AnimatedSprite2D
	if not enemy_sprite.sprite_frames.has_animation("hurt"):
		failures.append("local Orc sprite should include hurt animation")
	if not enemy_sprite.sprite_frames.has_animation("death"):
		failures.append("local Orc sprite should include death animation")
	enemy.call("_begin_projectile_windup", Vector2.RIGHT)
	await process_frame
	if enemy_sprite.animation != "attack":
		failures.append("enemy windup should briefly play local enemy attack animation")
	await create_timer(0.22).timeout
	enemy.take_damage(1)
	await process_frame
	if enemy_sprite.animation != "hurt":
		failures.append("enemy damage should briefly play local enemy hurt animation")
	enemy.take_damage(999)
	if enemy_sprite.animation != "death":
		failures.append("enemy lethal damage should play local enemy death animation before queue_free")
	if not bool(enemy.get_meta("death_animation_hold_active", false)):
		failures.append("local enemy lethal damage should hold the death animation briefly")
	await process_frame
	if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
		failures.append("local enemy should remain visible for at least one frame of death animation")

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
	var telegraph := scene.get_node_or_null("CombatFxTelegraph")
	if telegraph == null:
		failures.append("charger telegraph should spawn CombatFxTelegraph")
	else:
		if str(telegraph.get_meta("enemy_attack", "")) != "charge":
			failures.append("charger telegraph should tag enemy_attack=charge")
		if str(telegraph.get_meta("enemy_kind", "")) != "melee_charger":
			failures.append("charger telegraph should tag enemy kind")
		if float(telegraph.get_meta("telegraph_seconds", 0.0)) < 0.5:
			failures.append("charger telegraph should expose readable >=0.5s duration metadata")
		var label := telegraph.get_node_or_null("AttackCueLabel") as Label
		if label == null or not label.text.contains("CHARGE"):
			failures.append("charger telegraph should show readable attack cue label")

	scene.free()
