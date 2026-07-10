extends SceneTree

const RoomInteractableScript := preload("res://scripts/rooms/room_interactable.gd")
const BreakablePropScript := preload("res://scripts/rooms/breakable_prop.gd")
const TrapScript := preload("res://scripts/rooms/trap.gd")

func _init() -> void:
	var failures: Array[String] = []
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(
		PlayerClassDB.get_class_data("blade_warden"),
		"ice",
		"warden_sword"
	)
	if player.class_id != "blade_warden":
		failures.append("player class_id not applied: %s" % player.class_id)
	if not SpriteDB.has_sprite("knight_m_idle_anim"):
		failures.append("SpriteDB cannot resolve knight_m_idle_anim")
	if SpriteDB.first_existing(["knight_m_idle_anim"]) == "":
		failures.append("first_existing cannot resolve knight_m_idle_anim")
	if player._sprite == null:
		failures.append("player cached _sprite is null")
	if player._body == null:
		failures.append("player cached _body is null")
	var player_sprite := player.get_node("Sprite") as AnimatedSprite2D
	var player_body := player.get_node("Body") as Polygon2D
	if not player_sprite.visible:
		failures.append("player sprite stays hidden after apply_class")
	if player_body.visible:
		failures.append("player placeholder body stays visible after apply_class")
	var blade_sprites := Player.class_sprite_names("blade_warden")
	if str(blade_sprites.get("idle", "")) != "zerie_soldier_idle":
		failures.append("blade_warden should prefer reviewed Zerie Soldier idle when local asset exists")
	if str(blade_sprites.get("run", "")) != "zerie_soldier_walk":
		failures.append("blade_warden should prefer reviewed Zerie Soldier walk when local asset exists")
	if str(player_sprite.get_meta("asset_source", "")) != "user_local_assets":
		failures.append("blade_warden runtime sprite should expose user_local_assets metadata")
	if player_sprite.scale.x < 0.6 or player_sprite.scale.x > 0.75:
		failures.append("blade_warden Zerie Soldier sprite should be readable without filling the camera, got %s" % player_sprite.scale)
	if player_sprite.offset.y < -24.0 or player_sprite.offset.y > -6.0:
		failures.append("blade_warden Zerie Soldier sprite should align reviewed origin, got offset %s" % player_sprite.offset)

	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy: Enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.configure_visual("imp_idle_anim", "imp_run_anim")
	var enemy_sprite := enemy.get_node("Sprite") as AnimatedSprite2D
	var enemy_body := enemy.get_node("Body") as Polygon2D
	if not enemy_sprite.visible:
		failures.append("enemy sprite stays hidden after configure_visual")
	if enemy_body.visible:
		failures.append("enemy placeholder body stays visible after configure_visual")
	var local_enemy: Enemy = enemy_scene.instantiate()
	root.add_child(local_enemy)
	await process_frame
	local_enemy.configure_visual("zerie_orc_idle", "zerie_orc_walk")
	var local_sprite := local_enemy.get_node("Sprite") as AnimatedSprite2D
	if not local_sprite.visible:
		failures.append("local manifest enemy sprite should be visible")
	if str(local_sprite.get_meta("asset_source", "")) != "user_local_assets":
		failures.append("local manifest enemy sprite should expose user_local_assets metadata")
	if local_sprite.scale.x <= 0.0 or local_sprite.scale.x >= 1.0:
		failures.append("local manifest enemy sprite should be downscaled from 100px art")
	if local_sprite.sprite_frames == null \
			or local_sprite.sprite_frames.get_frame_count("run") != 8:
		failures.append("local manifest enemy should expose 8-frame run animation")
	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	var mapped_enemy: Enemy = enemy_scene.instantiate()
	renderer.add_child(mapped_enemy)
	await process_frame
	renderer.call("_apply_enemy_sprite", mapped_enemy, "anvil_guard")
	var mapped_sprite := mapped_enemy.get_node("Sprite") as AnimatedSprite2D
	if str(mapped_sprite.get_meta("asset_source", "")) != "user_local_assets":
		failures.append("anvil_guard should prefer reviewed Zerie Orc local visual")
	if mapped_sprite.sprite_frames == null \
			or mapped_sprite.sprite_frames.get_frame_count("run") != 8:
		failures.append("anvil_guard local visual should keep Orc walk run frames")

	await _check_chest_interactable_sprites(failures)
	await _check_utility_interactable_sprites(failures)
	await _check_room_object_sprites(failures)

	if failures.is_empty():
		print("Visual sprite smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_chest_interactable_sprites(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	for spec in [
		{"kind": "chest", "sprite": "chest_full_open_anim"},
		{"kind": "locked_chest", "sprite": "chest_full_open_anim"},
		{"kind": "cursed_chest", "sprite": "chest_mimic_open_anim"},
	]:
		var interactable := RoomInteractableScript.new()
		var kind := str(spec["kind"])
		interactable.configure(kind)
		parent.add_child(interactable)
		await process_frame
		_assert_object_sprite(interactable, kind, str(spec["sprite"]), failures)
		interactable.queue_free()
		await process_frame
	parent.queue_free()

func _check_utility_interactable_sprites(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	for spec in [
		{"kind": "shrine", "sprite": "flask_big_red", "label": "heal shrine"},
		{"kind": "shop", "sprite": "coin_anim", "label": "shop"},
		{"kind": "element_altar", "sprite": "flask_big_yellow", "label": "element altar"},
		{"kind": "blood_altar", "sprite": "skull", "label": "blood altar"},
	]:
		var interactable := RoomInteractableScript.new()
		interactable.configure(str(spec["kind"]))
		parent.add_child(interactable)
		await process_frame
		_assert_object_sprite(interactable, str(spec["label"]), str(spec["sprite"]), failures)
		interactable.queue_free()
		await process_frame
	parent.queue_free()

func _check_room_object_sprites(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var prop := BreakablePropScript.new()
	prop.configure("crate", 2, {"type": "gold", "value": 2})
	parent.add_child(prop)
	await process_frame
	_assert_object_sprite(prop, "crate prop", "crate", failures)
	var vase := BreakablePropScript.new()
	vase.configure("vase", 2, {"type": "potion", "value": 12})
	parent.add_child(vase)
	await process_frame
	_assert_object_sprite(vase, "vase prop", "flask_big_blue", failures)
	for trap_spec in [
		{"kind": "spike", "sprite": "floor_spikes_anim", "label": "spike trap"},
		{"kind": "fire", "sprite": "bomb", "label": "fire trap"},
		{"kind": "saw", "sprite": "weapon_saw_sword", "label": "saw trap"},
		{"kind": "arrow", "sprite": "weapon_arrow", "label": "arrow trap"},
	]:
		var trap := TrapScript.new()
		trap.configure(str(trap_spec["kind"]), 6, 0.7, 0.5)
		parent.add_child(trap)
		await process_frame
		_assert_object_sprite(trap, str(trap_spec["label"]), str(trap_spec["sprite"]), failures)
		_assert_sprite_metadata(trap, str(trap_spec["label"]), str(trap_spec["sprite"]), failures)
		trap.queue_free()
		await process_frame
	parent.queue_free()

func _assert_object_sprite(node: Node, label: String, sprite_name: String, failures: Array[String]) -> void:
	var sprite := node.get_node_or_null("ObjectSprite") as AnimatedSprite2D
	var placeholder := node.get_node_or_null("Visual") as Polygon2D
	if sprite == null or not sprite.visible:
		failures.append("%s should use a sprite visual" % label)
	elif str(sprite.get_meta("sprite_name", "")) != sprite_name:
		failures.append("%s should store sprite metadata %s" % [label, sprite_name])
	else:
		_assert_sprite_metadata(node, label, sprite_name, failures)
	if placeholder != null and placeholder.visible:
		failures.append("%s should hide placeholder polygon when sprite exists" % label)

func _assert_sprite_metadata(node: Node, label: String, sprite_name: String, failures: Array[String]) -> void:
	var sprite := node.get_node_or_null("ObjectSprite") as AnimatedSprite2D
	if sprite == null:
		return
	var report := SpriteDB.animation_report(sprite_name)
	if int(sprite.get_meta("frame_count", 0)) != int(report.get("frame_count", 0)):
		failures.append("%s should store frame_count metadata for %s" % [label, sprite_name])
	if sprite.get_meta("frame_size", Vector2.ZERO) != report.get("frame_size", Vector2.ZERO):
		failures.append("%s should store frame_size metadata for %s" % [label, sprite_name])
	if bool(sprite.get_meta("stable_size", false)) != bool(report.get("stable_size", false)):
		failures.append("%s should store stable_size metadata for %s" % [label, sprite_name])
	if float(sprite.get_meta("fps", 0.0)) != float(report.get("fps", 0.0)):
		failures.append("%s should store fps metadata for %s" % [label, sprite_name])
	var release := SpriteDB.release_report([sprite_name])
	var sprites: Dictionary = release.get("sprites", {})
	var entry: Dictionary = sprites.get(sprite_name, {})
	if str(sprite.get_meta("asset_source", "")) != str(entry.get("source", "")):
		failures.append("%s should store asset_source metadata for %s" % [label, sprite_name])
	if str(sprite.get_meta("release_decision", "")) != str(entry.get("release_decision", "")):
		failures.append("%s should store release_decision metadata for %s" % [label, sprite_name])
	if str(sprite.get_meta("review_status", "")) != str(entry.get("review_status", "")):
		failures.append("%s should store review_status metadata for %s" % [label, sprite_name])
	if str(sprite.get_meta("replacement_policy", "")) != str(entry.get("replacement_policy", "")):
		failures.append("%s should store replacement_policy metadata for %s" % [label, sprite_name])
	if bool(sprite.get_meta("needs_replacement_before_public", true)) \
			!= bool(entry.get("needs_replacement_before_public", false)):
		failures.append("%s should store replacement gate metadata for %s" % [label, sprite_name])
	if bool(sprite.get_meta("frame_grid_ok", false)) != bool(entry.get("frame_grid_ok", false)):
		failures.append("%s should store frame_grid_ok metadata for %s" % [label, sprite_name])
