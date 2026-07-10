extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

class DummyTarget:
	extends Node2D
	var damage_taken := 0

	func take_damage(amount: int) -> void:
		damage_taken += amount

func _init() -> void:
	var failures: Array[String] = []

	await _check_boss_variant_api(failures)
	await _check_boss_tuning_patch_api(failures)
	await _check_variant_next_attack_preview(failures)
	await _check_variant_projectile_statuses(failures)
	await _check_variant_attack_identity(failures)
	await _check_renderer_passes_biome_variant(failures)

	if failures.is_empty():
		print("Boss variant smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_boss_variant_api(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var target := DummyTarget.new()
	target.global_position = Vector2(96, 0)
	scene.add_child(target)
	var boss := BossGolem.new()
	boss.max_hp = 100
	boss.hp = 100
	boss.contact_damage = 10
	boss.target = target
	scene.add_child(boss)
	await process_frame
	if not boss.has_method("configure_variant"):
		failures.append("boss should expose configure_variant")
	else:
		boss.call("configure_variant", "forge_golem")
		if str(boss.get_meta("boss_variant", "")) != "forge_golem":
			failures.append("boss variant should be stored as metadata")
		boss.hp = 60
		boss.call("_update_phase")
		if str(boss.call("phase_pattern")).find("forge") == -1:
			failures.append("boss phase pattern should reflect active variant")
		var before := _child_type_count(scene, "EnemyProjectile")
		boss.call("spawn_bullet_hell")
		await process_frame
		if _child_type_count(scene, "EnemyProjectile") != before:
			failures.append("forge boss should not spawn bullet hell projectiles before telegraph")
		await _wait_readable_attack_telegraph()
		if _child_type_count(scene, "EnemyProjectile") - before < 10:
			failures.append("forge boss should spawn denser default bullet hell after telegraph")
	scene.queue_free()
	await process_frame

func _check_boss_tuning_patch_api(failures: Array[String]) -> void:
	var boss := BossGolem.new()
	var boss_ref: WeakRef = weakref(boss)
	boss.configure_variant("cave_golem")
	boss.max_hp = 100
	boss.hp = 100
	if not boss.has_method("apply_tuning_patch"):
		failures.append("boss should expose apply_tuning_patch for explicit tuning experiments")
		boss.free()
		return
	boss.call("apply_tuning_patch", {
		"enabled": true,
		"boss_variant": "cave_golem",
		"hp_multiplier": 1.4,
		"source": "playtest_evidence",
	})
	if boss.max_hp != 140 or boss.hp != 140:
		failures.append("boss tuning patch should scale max hp and current hp")
	if str(boss.get_meta("tuning_patch_source", "")) != "playtest_evidence":
		failures.append("boss tuning patch should expose source metadata")
	if not is_equal_approx(float(boss.get_meta("tuning_hp_multiplier", 0.0)), 1.4):
		failures.append("boss tuning patch should expose hp multiplier metadata")
	var unchanged_hp := boss.max_hp
	boss.call("apply_tuning_patch", {
		"enabled": true,
		"boss_variant": "spore_golem",
		"hp_multiplier": 1.5,
		"source": "wrong_variant",
	})
	if boss.max_hp != unchanged_hp:
		failures.append("boss tuning patch should ignore mismatched variants")
	boss.call("apply_tuning_patch", {
		"enabled": false,
		"boss_variant": "cave_golem",
		"hp_multiplier": 1.5,
		"source": "disabled",
	})
	if boss.max_hp != unchanged_hp:
		failures.append("boss tuning patch should ignore disabled patches")
	boss.free()
	if boss_ref.get_ref() != null:
		failures.append("boss tuning patch smoke should free standalone boss fixture")

func _check_variant_next_attack_preview(failures: Array[String]) -> void:
	var cases := [
		{
			"variant": "spore_golem",
			"attack": "spore_bloom",
			"label": "Spore Bloom",
			"warning": "Poison",
		},
		{
			"variant": "forge_golem",
			"attack": "forge_overheat",
			"label": "Forge Overheat",
			"warning": "Burn",
		},
		{
			"variant": "archive_golem",
			"attack": "archive_prism",
			"label": "Archive Prism",
			"warning": "Chill",
		},
	]
	for c in cases:
		var scene := Node2D.new()
		root.add_child(scene)
		current_scene = scene
		var target := DummyTarget.new()
		target.global_position = Vector2(96, 0)
		scene.add_child(target)
		var boss := BossGolem.new()
		boss.max_hp = 100
		boss.hp = 25
		boss.phase = 3
		boss.contact_damage = 10
		boss.target = target
		boss.configure_variant(str(c["variant"]))
		scene.add_child(boss)
		await process_frame
		boss.phase = 3
		var status: Dictionary = boss.call("boss_status")
		if str(status.get("next_attack_id", "")) != "bullet_hell":
			failures.append("%s next attack should keep base bullet_hell id" % c["variant"])
		if str(status.get("next_variant_attack", "")) != str(c["attack"]):
			failures.append("%s next attack should expose variant attack id" % c["variant"])
		if str(status.get("next_attack_label", "")) != str(c["label"]):
			failures.append("%s next attack label should preview variant identity" % c["variant"])
		if not str(status.get("next_attack_warning", "")).contains(str(c["warning"])):
			failures.append("%s next attack warning should preview variant pressure" % c["variant"])
		if not str(status.get("next_attack", "")).contains(str(c["label"])):
			failures.append("%s next attack text should use variant label" % c["variant"])
		scene.queue_free()
		await process_frame

func _check_variant_projectile_statuses(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var target := DummyTarget.new()
	target.global_position = Vector2(96, 0)
	scene.add_child(target)
	var spore := BossGolem.new()
	spore.max_hp = 100
	spore.hp = 100
	spore.contact_damage = 10
	spore.target = target
	spore.configure_variant("spore_golem")
	scene.add_child(spore)
	await process_frame
	spore.spawn_bullet_hell(4)
	await process_frame
	if _has_projectile_status(scene, "poisoned"):
		failures.append("spore boss projectiles should wait until telegraph resolves")
	await _wait_readable_attack_telegraph()
	if not _has_projectile_status(scene, "poisoned"):
		failures.append("spore boss projectiles should apply poisoned status")
	if not _has_projectile_readability(scene, "spore_golem"):
		failures.append("spore boss projectiles should expose readability metadata")
	scene.queue_free()
	await process_frame

	scene = Node2D.new()
	root.add_child(scene)
	current_scene = scene
	target = DummyTarget.new()
	target.global_position = Vector2(96, 0)
	scene.add_child(target)
	var forge := BossGolem.new()
	forge.max_hp = 100
	forge.hp = 100
	forge.contact_damage = 10
	forge.target = target
	forge.configure_variant("forge_golem")
	scene.add_child(forge)
	await process_frame
	forge.spawn_bullet_hell(4)
	await process_frame
	if _has_projectile_status(scene, "burning"):
		failures.append("forge boss projectiles should wait until telegraph resolves")
	await _wait_readable_attack_telegraph()
	if not _has_projectile_status(scene, "burning"):
		failures.append("forge boss projectiles should apply burning status")
	if not _has_projectile_readability(scene, "forge_golem"):
		failures.append("forge boss projectiles should expose readability metadata")
	scene.queue_free()
	await process_frame

func _check_variant_attack_identity(failures: Array[String]) -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var target := DummyTarget.new()
	target.global_position = Vector2(96, 0)
	scene.add_child(target)
	var spore := BossGolem.new()
	spore.max_hp = 100
	spore.hp = 100
	spore.contact_damage = 10
	spore.target = target
	spore.configure_variant("spore_golem")
	scene.add_child(spore)
	await process_frame
	var events: Array[Dictionary] = []
	spore.connect("boss_attack_cued", func(status: Dictionary) -> void:
		events.append(status))
	spore.spawn_bullet_hell(4)
	await process_frame
	if events.is_empty():
		failures.append("spore boss should emit attack cue for bullet bloom")
	else:
		var spore_event: Dictionary = events.back()
		if str(spore_event.get("attack", "")) != "bullet_hell":
			failures.append("spore boss should keep base bullet_hell attack id")
		if str(spore_event.get("variant_attack", "")) != "spore_bloom":
			failures.append("spore boss bullet hell should expose spore_bloom variant attack")
		if not str(spore_event.get("variant_attack_label", "")).contains("Spore"):
			failures.append("spore boss variant attack cue should include readable label")
		if not str(spore_event.get("variant_warning", "")).contains("Poison"):
			failures.append("spore boss variant warning should explain poison bloom pressure")
		if not str(spore_event.get("variant_pressure", "")).contains("Poison"):
			failures.append("spore boss attack cue should include variant pressure")
		if not str(spore_event.get("variant_counter_hint", "")).contains("moving"):
			failures.append("spore boss attack cue should include variant counterplay")
	var attack_label := spore.find_child("BossAttackWarning", true, false) as Label
	if attack_label == null or not attack_label.text.contains("Spore"):
		failures.append("spore boss attack label should show variant attack identity")
	elif not str(attack_label.get_meta("variant_counter_hint", "")).contains("moving") \
			or not str(attack_label.get_meta("variant_pressure", "")).contains("Poison"):
		failures.append("spore boss attack label should store variant pressure and counterplay")
	if _all_projectiles_have_variant_attack(scene, "spore_bloom"):
		failures.append("spore boss projectiles should not spawn before telegraph resolves")
	await _wait_readable_attack_telegraph()
	if not _all_projectiles_have_variant_attack(scene, "spore_bloom"):
		failures.append("spore boss projectiles should tag spore_bloom variant attack")
	spore.phase = 2
	spore.call("summon_phase_traps", 2)
	await process_frame
	if not _all_group_children_have_variant_attack(spore, "room_traps", "spore_root_wave"):
		failures.append("spore boss trap wave should tag spore_root_wave variant attack")
	scene.queue_free()
	await process_frame

	scene = Node2D.new()
	root.add_child(scene)
	current_scene = scene
	target = DummyTarget.new()
	target.global_position = Vector2(96, 0)
	scene.add_child(target)
	var forge := BossGolem.new()
	forge.max_hp = 100
	forge.hp = 100
	forge.contact_damage = 10
	forge.target = target
	forge.configure_variant("forge_golem")
	scene.add_child(forge)
	await process_frame
	events.clear()
	forge.connect("boss_attack_cued", func(status: Dictionary) -> void:
		events.append(status))
	forge.spawn_bullet_hell(4)
	await process_frame
	if events.is_empty():
		failures.append("forge boss should emit attack cue for overheat")
	else:
		var forge_event: Dictionary = events.back()
		if str(forge_event.get("attack", "")) != "bullet_hell":
			failures.append("forge boss should keep base bullet_hell attack id")
		if str(forge_event.get("variant_attack", "")) != "forge_overheat":
			failures.append("forge boss bullet hell should expose forge_overheat variant attack")
		if not str(forge_event.get("variant_attack_label", "")).contains("Forge"):
			failures.append("forge boss variant attack cue should include readable label")
		if not str(forge_event.get("variant_warning", "")).contains("Burn"):
			failures.append("forge boss variant warning should explain burn pressure")
		if not str(forge_event.get("variant_pressure", "")).contains("Burn"):
			failures.append("forge boss attack cue should include variant pressure")
		if not str(forge_event.get("variant_counter_hint", "")).contains("hot"):
			failures.append("forge boss attack cue should include variant counterplay")
	attack_label = forge.find_child("BossAttackWarning", true, false) as Label
	if attack_label == null or not attack_label.text.contains("Forge"):
		failures.append("forge boss attack label should show variant attack identity")
	elif not str(attack_label.get_meta("variant_counter_hint", "")).contains("hot") \
			or not str(attack_label.get_meta("variant_pressure", "")).contains("Burn"):
		failures.append("forge boss attack label should store variant pressure and counterplay")
	if _all_projectiles_have_variant_attack(scene, "forge_overheat"):
		failures.append("forge boss projectiles should not spawn before telegraph resolves")
	await _wait_readable_attack_telegraph()
	if not _all_projectiles_have_variant_attack(scene, "forge_overheat"):
		failures.append("forge boss projectiles should tag forge_overheat variant attack")
	forge.phase = 2
	forge.call("summon_phase_traps", 2)
	await process_frame
	if not _all_group_children_have_variant_attack(forge, "room_traps", "forge_hazard_wave"):
		failures.append("forge boss trap wave should tag forge_hazard_wave variant attack")
	scene.queue_free()
	await process_frame

func _check_renderer_passes_biome_variant(failures: Array[String]) -> void:
	var biome_db: Variant = load("res://scripts/dungeon_gen/biome_db.gd")
	var renderer := RoomRenderer.new()
	var target := DummyTarget.new()
	root.add_child(target)
	root.add_child(renderer)
	var biome: Dictionary = biome_db.floor_biome(2).duplicate(true)
	biome["boss_tuning_patch"] = {
		"enabled": true,
		"id": "spore_golem_boss",
		"boss_variant": "spore_golem",
		"hp_multiplier": 1.25,
		"source": "smoke",
	}
	var plan: Array[Dictionary] = [
		{
			"enemy": {"id": "cave_golem_boss", "kind": "boss", "hp": 100, "dmg": 10},
			"wave": 1,
			"tile": Vector2i(4, 4),
			"elite": false,
			"modifier": "",
		},
	]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, target, RoomNode.RoomType.BOSS, {}, biome)
	await process_frame
	var boss := _first_boss(renderer)
	if boss == null:
		failures.append("boss room should spawn BossGolem")
	else:
		if str(boss.get_meta("boss_variant", "")) != "spore_golem":
			failures.append("renderer should pass biome boss variant to boss")
		var expected_hp := ceili(100.0 * float(biome.get("enemy_hp_mult", 1.0)) * 1.25)
		if boss.max_hp != expected_hp:
			failures.append("renderer should apply explicit biome boss tuning patch")
		if str(boss.get_meta("tuning_patch_source", "")) != "smoke":
			failures.append("renderer boss tuning patch should expose source metadata")
		_assert_renderer_boss_visual(boss, failures)
		if not renderer.has_method("boss_status"):
			failures.append("renderer should expose boss_status for HUD")
		else:
			var status: Dictionary = renderer.call("boss_status")
			if str(status.get("variant", "")) != "spore_golem":
				failures.append("renderer boss_status should include boss variant")
			if int(status.get("max_hp", 0)) <= 0:
				failures.append("renderer boss_status should include boss max hp")
			if not str(status.get("variant_pressure", "")).contains("Poison"):
				failures.append("renderer boss_status should expose spore variant pressure")
			if not str(status.get("variant_counter_hint", "")).contains("moving"):
				failures.append("renderer boss_status should expose spore counterplay")
			if str(status.get("variant_status", "")) != "poisoned":
				failures.append("renderer boss_status should expose spore status identity")
		if not renderer.has_signal("boss_phase_changed"):
			failures.append("renderer should forward boss_phase_changed for FloorController/HUD")
		else:
			var events: Array[Dictionary] = []
			renderer.connect("boss_phase_changed", func(status: Dictionary) -> void:
				events.append(status))
			boss.hp = 60
			boss.call("_update_phase")
			await process_frame
			if events.is_empty():
				failures.append("renderer should emit when boss phase changes")
			elif int(events.back().get("phase", 0)) != 2:
				failures.append("renderer forwarded boss phase event should include phase")
		if not renderer.has_signal("boss_attack_cued"):
			failures.append("renderer should forward boss_attack_cued for FloorController/HUD")
		else:
			var attack_events: Array[Dictionary] = []
			renderer.connect("boss_attack_cued", func(status: Dictionary) -> void:
				attack_events.append(status))
			boss.spawn_bullet_hell(4)
			await process_frame
			if attack_events.is_empty():
				failures.append("renderer should emit when boss cues an attack")
			elif str(attack_events.back().get("attack", "")) != "bullet_hell":
				failures.append("renderer forwarded boss attack event should include attack id")
	renderer.queue_free()
	target.queue_free()
	await process_frame

func _assert_renderer_boss_visual(boss: BossGolem, failures: Array[String]) -> void:
	var sprite := boss.get_node_or_null("Sprite") as AnimatedSprite2D
	var body := boss.get_node_or_null("Body") as Polygon2D
	if sprite == null:
		failures.append("renderer boss should expose AnimatedSprite2D Sprite")
		return
	if body == null:
		failures.append("renderer boss should expose named Body polygon fallback")
	elif body.visible:
		failures.append("renderer boss should hide polygon fallback when sprite exists")
	if not sprite.visible:
		failures.append("renderer boss should use a sprite visual")
	if str(sprite.get_meta("sprite_name", "")) == "":
		failures.append("renderer boss sprite should store sprite_name metadata")
	if int(sprite.get_meta("frame_count", 0)) < 4:
		failures.append("renderer boss sprite should store animation frame count metadata")
	if not bool(sprite.get_meta("frame_grid_ok", false)):
		failures.append("renderer boss sprite should pass frame grid review before release")
	if not bool(sprite.get_meta("animation_stability_reviewed", false)):
		failures.append("renderer boss sprite should store animation stability review metadata")
	if not bool(sprite.get_meta("origin_alignment_reviewed", false)):
		failures.append("renderer boss sprite should store origin alignment review metadata")
	if str(sprite.get_meta("asset_source", "")) == "":
		failures.append("renderer boss sprite should store asset source metadata")
	if str(sprite.get_meta("release_decision", "")) != "public_ok":
		failures.append("renderer boss sprite should be public release safe")
	if bool(sprite.get_meta("needs_replacement_before_public", true)):
		failures.append("renderer boss sprite should not require replacement before public release")

func _wait_readable_attack_telegraph() -> void:
	await create_timer(0.55).timeout

func _basic_grid() -> TileGrid:
	var grid := TileGrid.new(12, 8, TileGrid.Tile.FLOOR)
	for x in grid.width:
		grid.set_tile(x, 0, TileGrid.Tile.WALL)
		grid.set_tile(x, grid.height - 1, TileGrid.Tile.WALL)
	for y in grid.height:
		grid.set_tile(0, y, TileGrid.Tile.WALL)
		grid.set_tile(grid.width - 1, y, TileGrid.Tile.WALL)
	grid.set_tile(5, 0, TileGrid.Tile.DOOR)
	grid.set_tile(6, 0, TileGrid.Tile.DOOR)
	return grid

func _first_boss(parent: Node) -> BossGolem:
	for child in parent.get_children():
		if child is BossGolem:
			return child
	return null

func _child_type_count(parent: Node, class_name_text: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.get_class() == class_name_text or child.get_script() != null \
				and child.get_script().get_global_name() == class_name_text:
			count += 1
	return count

func _has_projectile_status(parent: Node, status_name: String) -> bool:
	for child in parent.get_children():
		if child is EnemyProjectile and str(child.get_meta("hit_status", "")) == status_name:
			return true
	return false

func _has_projectile_readability(parent: Node, variant_id: String) -> bool:
	for child in parent.get_children():
		if child is EnemyProjectile \
				and str(child.get_meta("boss_projectile_variant", "")) == variant_id \
				and child.has_meta("boss_projectile_color"):
			return true
	return false

func _all_projectiles_have_variant_attack(parent: Node, expected: String) -> bool:
	var saw := false
	for child in parent.get_children():
		if child is EnemyProjectile:
			saw = true
			if str(child.get_meta("boss_variant_attack", "")) != expected:
				return false
			if str(child.get_meta("boss_variant_attack_label", "")) == "":
				return false
	return saw

func _all_group_children_have_variant_attack(
		parent: Node,
		group_name: String,
		expected: String,
) -> bool:
	var saw := false
	for child in parent.get_children():
		if child.is_in_group(group_name):
			saw = true
			if str(child.get_meta("boss_variant_attack", "")) != expected:
				return false
			if str(child.get_meta("boss_variant_attack_label", "")) == "":
				return false
	return saw
