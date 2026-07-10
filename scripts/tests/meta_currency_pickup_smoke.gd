extends SceneTree

class DummyPlayer:
	extends Node2D
	var rewards := {}
	var silver_keys := 0
	var gold := 0
	var hp := 100
	var max_hp := 100
	var pickup_history: Array[String] = []

	func add_gold(amount: int) -> void:
		gold += amount

	func add_meta_currency(currency_id: String, amount: int) -> void:
		rewards[currency_id] = int(rewards.get(currency_id, 0)) + amount

	func add_key(amount: int) -> void:
		silver_keys += amount

	func pickup_weapon(_weapon_id: String) -> void:
		pass

	func heal(amount: int) -> void:
		hp = mini(hp + amount, max_hp)

	func run_rewards() -> Dictionary:
		return rewards

	func record_pickup(label: String) -> void:
		pickup_history.append(label)

	func pickup_history_summary(_max_items: int = 6) -> String:
		return " -> ".join(pickup_history)

func _init() -> void:
	var failures: Array[String] = []

	await _check_meta_currency_pickups(failures)
	await _check_pickup_sfx_feedback(failures)
	await _check_pickup_toast_feedback(failures)
	await _check_weapon_pickup_toast_rarity(failures)
	await _check_pickup_toast_cleanup(failures)
	await _check_pickup_history_hooks(failures)
	await _check_pickup_magnet_feedback(failures)
	await _check_meta_currency_pickup_sprites(failures)
	await _check_full_hp_potion_is_not_wasted(failures)
	await _check_meta_currency_hud_flash(failures)

	if failures.is_empty():
		print("Meta currency pickup smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_meta_currency_pickups(failures: Array[String]) -> void:
	var player := DummyPlayer.new()
	root.add_child(player)

	var shard := Pickup.new()
	shard.configure({"type": "meta_currency", "id": "soul_shards", "value": 3}, player)
	shard.call("_collect")
	await process_frame
	if int(player.run_rewards().get("soul_shards", 0)) != 3:
		failures.append("meta_currency pickup should add soul shards to run rewards")

	var dust := Pickup.new()
	dust.configure({"type": "rune_dust", "value": 5}, player)
	dust.call("_collect")
	await process_frame
	if int(player.run_rewards().get("rune_dust", 0)) != 5:
		failures.append("direct currency pickup type should add rune dust")

	var key := Pickup.new()
	key.configure({"type": "silver_key", "value": 1}, player)
	key.call("_collect")
	await process_frame
	if player.silver_keys != 1:
		failures.append("silver key pickup should add an in-run chest key")

	player.queue_free()
	await process_frame

func _check_pickup_sfx_feedback(failures: Array[String]) -> void:
	var player := DummyPlayer.new()
	root.add_child(player)
	var cases: Array[Dictionary] = [
		{"type": "gold", "value": 10, "cue": "pickup_gold"},
		{"type": "potion", "value": 10, "cue": "pickup_heal", "hp": 50},
		{"type": "silver_key", "value": 1, "cue": "pickup_key"},
		{"type": "weapon", "id": "scrap_pistol", "cue": "pickup_weapon"},
		{"type": "rune_dust", "value": 2, "cue": "pickup_meta"},
	]
	for c in cases:
		var pickup := Pickup.new()
		var data := c.duplicate(true)
		var expected := str(data.get("cue", ""))
		data.erase("cue")
		if data.has("hp"):
			player.hp = int(data.get("hp", player.hp))
			data.erase("hp")
		pickup.configure(data, player)
		pickup.global_position = Vector2(16, 16)
		root.add_child(pickup)
		await process_frame
		pickup.call("_collect")
		var sfx := root.get_node_or_null("PickupSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("%s pickup should create a pickup sound placeholder" % str(data.get("type", "")))
		else:
			if str(sfx.get_meta("pickup_sound_id", "")) != expected:
				failures.append("%s pickup should use %s cue" % [str(data.get("type", "")), expected])
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("%s pickup sound should come from AudioCueDB" % str(data.get("type", "")))
			if str(sfx.get_meta("pickup_type", "")) != str(data.get("type", "")):
				failures.append("%s pickup sound should store pickup type metadata" % str(data.get("type", "")))
			if str(sfx.get_meta("pickup_label", "")) == "":
				failures.append("%s pickup sound should store readable pickup label metadata" % str(data.get("type", "")))
			if str(sfx.get_meta("pickup_category", "")) == "":
				failures.append("%s pickup sound should store pickup category metadata" % str(data.get("type", "")))
			if str(sfx.get_meta("pickup_feedback_tier", "")) == "":
				failures.append("%s pickup sound should store pickup feedback tier metadata" % str(data.get("type", "")))
			if data.has("value") and int(sfx.get_meta("pickup_value", -999)) != int(data.get("value", 0)):
				failures.append("%s pickup sound should store pickup value metadata" % str(data.get("type", "")))
			if sfx.stream == null:
				failures.append("%s pickup sound should assign a placeholder stream" % str(data.get("type", "")))
			if not bool(sfx.get_meta("playback_requested", false)):
				failures.append("%s pickup sound should mark playback requested" % str(data.get("type", "")))
			if DisplayServer.get_name() == "headless" \
					and not bool(sfx.get_meta("headless_playback_skipped", false)):
				failures.append("%s pickup sound should skip playback in headless smoke" % str(data.get("type", "")))
			sfx.queue_free()
		if is_instance_valid(pickup):
			pickup.queue_free()
		for toast in root.find_children("PickupToast", "Label", false, false):
			toast.queue_free()
		await process_frame
	player.queue_free()
	await process_frame

func _check_pickup_toast_feedback(failures: Array[String]) -> void:
	var player := DummyPlayer.new()
	root.add_child(player)
	var pickup := Pickup.new()
	pickup.configure({"type": "rune_dust", "value": 2}, player)
	pickup.global_position = Vector2(24, 24)
	root.add_child(pickup)
	await process_frame
	pickup.call("_collect")
	await process_frame
	var toast := root.get_node_or_null("PickupToast") as Label
	if toast == null:
		failures.append("pickup should spawn a pickup toast label")
	elif not toast.text.contains("Rune Dust") or not toast.text.contains("+2"):
		failures.append("pickup toast should show readable pickup type and value")
	if toast != null:
		if str(toast.get_meta("pickup_label", "")) != "Rune Dust":
			failures.append("pickup toast should store readable label metadata")
		if int(toast.get_meta("pickup_value", 0)) != 2:
			failures.append("pickup toast should store value metadata")
		if str(toast.get_meta("pickup_category", "")) != "meta_currency":
			failures.append("pickup toast should store meta currency category")
		if str(toast.get_meta("pickup_feedback_tier", "")) == "":
			failures.append("pickup toast should store feedback tier metadata")
	if toast != null:
		toast.queue_free()
	player.queue_free()
	await process_frame

func _check_weapon_pickup_toast_rarity(failures: Array[String]) -> void:
	var player := DummyPlayer.new()
	root.add_child(player)
	var pickup := Pickup.new()
	pickup.configure({"type": "weapon", "id": "scrap_pistol"}, player)
	pickup.global_position = Vector2(30, 30)
	root.add_child(pickup)
	await process_frame
	pickup.call("_collect")
	await process_frame
	var toast := root.get_node_or_null("PickupToast") as Label
	if toast == null:
		failures.append("weapon pickup should spawn a pickup toast")
	elif not toast.text.contains("Weapon:") or not toast.text.contains("["):
		failures.append("weapon pickup toast should show weapon label and rarity")
	if toast != null:
		if str(toast.get_meta("pickup_category", "")) != "weapon":
			failures.append("weapon pickup toast should store weapon category metadata")
		if str(toast.get_meta("pickup_rarity", "")) == "":
			failures.append("weapon pickup toast should store weapon rarity metadata")
		if str(toast.get_meta("pickup_label", "")) == "":
			failures.append("weapon pickup toast should store weapon label metadata")
	if toast != null:
		toast.queue_free()
	player.queue_free()
	await process_frame

func _check_pickup_toast_cleanup(failures: Array[String]) -> void:
	var player := DummyPlayer.new()
	root.add_child(player)
	var pickup := Pickup.new()
	pickup.configure({"type": "gold", "value": 10}, player)
	pickup.global_position = Vector2(12, 12)
	root.add_child(pickup)
	await process_frame
	pickup.call("_collect")
	await process_frame
	var toast := root.get_node_or_null("PickupToast") as Label
	if toast == null:
		failures.append("pickup toast cleanup check needs a spawned toast")
	else:
		if not toast.has_meta("auto_cleanup_seconds"):
			failures.append("pickup toast should declare its auto cleanup lifetime")
		if not toast.has_meta("float_offset"):
			failures.append("pickup toast should declare its float-up offset")
		await create_timer(0.85).timeout
		if is_instance_valid(toast) and toast.is_inside_tree():
			failures.append("pickup toast should auto-expire after its feedback animation")
	player.queue_free()
	await process_frame

func _check_pickup_history_hooks(failures: Array[String]) -> void:
	var player := DummyPlayer.new()
	player.hp = 50
	root.add_child(player)
	var cases: Array[Dictionary] = [
		{"type": "silver_key", "value": 1, "token": "Key +1"},
		{"type": "rune_dust", "value": 2, "token": "Rune Dust +2"},
		{"type": "potion", "value": 20, "token": "Potion +20 HP"},
		{"type": "weapon", "id": "scrap_pistol", "token": "Weapon:"},
	]
	for c in cases:
		var pickup := Pickup.new()
		var data := c.duplicate(true)
		var token := str(data.get("token", ""))
		data.erase("token")
		pickup.configure(data, player)
		pickup.global_position = Vector2(1000, 1000)
		root.add_child(pickup)
		await process_frame
		if str(data.get("type", "")) == "potion":
			player.hp = 50
		pickup.call("_collect")
		await process_frame
		if not str(player.pickup_history_summary()).contains(token):
			failures.append("%s pickup should record loot history" % str(data.get("type", "")))
		if is_instance_valid(pickup):
			pickup.queue_free()
		for toast in root.find_children("PickupToast", "Label", false, false):
			toast.queue_free()
	player.queue_free()
	await process_frame

func _check_pickup_magnet_feedback(failures: Array[String]) -> void:
	var player := DummyPlayer.new()
	player.global_position = Vector2.ZERO
	root.add_child(player)
	var gold := Pickup.new()
	gold.configure({"type": "gold", "value": 1}, player)
	gold.global_position = Vector2(30, 0)
	root.add_child(gold)
	await process_frame
	var before := gold.global_position.distance_to(player.global_position)
	gold.call("_physics_process", 0.1)
	await process_frame
	var after := gold.global_position.distance_to(player.global_position)
	if after >= before:
		failures.append("nearby gold pickup should move toward the player")
	if not bool(gold.get_meta("magnet_active", false)):
		failures.append("magneting pickup should expose active magnet metadata")
	if float(gold.get_meta("magnet_distance_before", 0.0)) <= 0.0:
		failures.append("magneting pickup should store distance metadata")
	var trail := gold.get_node_or_null("PickupMagnetTrail") as Line2D
	if trail == null:
		failures.append("magneting pickup should show a lightweight trail")
	elif trail.points.size() < 2:
		failures.append("pickup magnet trail should point toward the player")

	var weapon := Pickup.new()
	weapon.configure({"type": "weapon", "id": "scrap_pistol"}, player)
	weapon.global_position = Vector2(30, 0)
	root.add_child(weapon)
	await process_frame
	weapon.call("_physics_process", 0.1)
	if bool(weapon.get_meta("magnet_active", false)):
		failures.append("weapon pickup should not auto-magnet")
	if weapon.get_node_or_null("PickupMagnetTrail") != null:
		failures.append("weapon pickup should not show magnet trail")

	if is_instance_valid(gold):
		gold.queue_free()
	if is_instance_valid(weapon):
		weapon.queue_free()
	player.queue_free()
	await process_frame

func _check_meta_currency_pickup_sprites(failures: Array[String]) -> void:
	var player := DummyPlayer.new()
	player.global_position = Vector2(1000, 1000)
	root.add_child(player)
	for spec in [
		{"data": {"type": "gold", "value": 1}, "sprite": "coin_anim"},
		{"data": {"type": "potion", "value": 10}, "sprite": "flask_red"},
		{"data": {"type": "silver_key", "value": 1}, "sprite": "pickup_silver_key_generated"},
		{"data": {"type": "weapon", "id": "warden_sword"}, "sprite": "weapon_regular_sword"},
		{"data": {"type": "weapon", "id": "scrap_pistol"}, "sprite": "weapon_pistol_generated"},
		{"data": {"type": "meta_currency", "id": "soul_shards", "value": 1}, "sprite": "skull"},
		{"data": {"type": "element_cores", "value": 1}, "sprite": "flask_big_yellow"},
		{"data": {"type": "rune_dust", "value": 1}, "sprite": "flask_big_blue"},
		{"data": {"type": "blueprints", "value": 1}, "sprite": "pickup_blueprint_generated"},
		{"data": {"type": "crafting_part", "value": 1}, "sprite": "pickup_unknown_generated"},
	]:
		var pickup := Pickup.new()
		pickup.configure(spec["data"], player)
		pickup.global_position = Vector2.ZERO
		root.add_child(pickup)
		await process_frame
		var sprite := pickup.get_node_or_null("PickupSprite") as AnimatedSprite2D
		if sprite == null:
			failures.append("%s pickup should expose a named sprite" % str(spec["sprite"]))
		elif str(sprite.get_meta("sprite_name", "")) != str(spec["sprite"]):
			failures.append("%s pickup should store sprite metadata" % str(spec["sprite"]))
		_assert_pickup_sprite_metadata(sprite, str(spec["sprite"]), failures)
		for child in pickup.get_children():
			if child is Polygon2D and child.visible:
				failures.append("%s pickup should hide polygon fallback when generated sprite exists" % str(spec["sprite"]))
		pickup.queue_free()
		await process_frame
	player.queue_free()
	await process_frame

func _assert_pickup_sprite_metadata(sprite: AnimatedSprite2D, sprite_name: String, failures: Array[String]) -> void:
	if sprite == null:
		return
	var report := SpriteDB.animation_report(sprite_name)
	var release_report := SpriteDB.release_report([sprite_name])
	var release_sprites: Dictionary = release_report.get("sprites", {})
	var release_entry: Dictionary = release_sprites.get(sprite_name, {})
	if int(sprite.get_meta("frame_count", 0)) != int(report.get("frame_count", 0)):
		failures.append("%s pickup should store frame_count metadata" % sprite_name)
	if sprite.get_meta("frame_size", Vector2.ZERO) != report.get("frame_size", Vector2.ZERO):
		failures.append("%s pickup should store frame_size metadata" % sprite_name)
	if bool(sprite.get_meta("stable_size", false)) != bool(report.get("stable_size", false)):
		failures.append("%s pickup should store stable_size metadata" % sprite_name)
	if float(sprite.get_meta("fps", 0.0)) != float(report.get("fps", 0.0)):
		failures.append("%s pickup should store fps metadata" % sprite_name)
	if str(sprite.get_meta("asset_source", "")) != str(release_entry.get("source", "")):
		failures.append("%s pickup should store asset_source release metadata" % sprite_name)
	if str(sprite.get_meta("release_decision", "")) != str(release_entry.get("release_decision", "")):
		failures.append("%s pickup should store release_decision metadata" % sprite_name)
	if str(sprite.get_meta("review_status", "")) != str(release_entry.get("review_status", "")):
		failures.append("%s pickup should store review_status metadata" % sprite_name)
	if str(sprite.get_meta("replacement_policy", "")) != str(release_entry.get("replacement_policy", "")):
		failures.append("%s pickup should store replacement_policy metadata" % sprite_name)
	if bool(sprite.get_meta("needs_replacement_before_public", false)) != bool(release_entry.get("needs_replacement_before_public", false)):
		failures.append("%s pickup should store public replacement gate metadata" % sprite_name)
	if bool(sprite.get_meta("frame_grid_ok", false)) != bool(release_entry.get("frame_grid_ok", false)):
		failures.append("%s pickup should store frame_grid_ok metadata" % sprite_name)
	if bool(sprite.get_meta("animation_stability_reviewed", false)) != bool(report.get("animation_stability_reviewed", false)):
		failures.append("%s pickup should store animation stability review metadata" % sprite_name)
	if bool(sprite.get_meta("motion_reviewed", false)) != bool(report.get("motion_reviewed", false)):
		failures.append("%s pickup should store motion review metadata" % sprite_name)
	if bool(sprite.get_meta("origin_alignment_reviewed", false)) != bool(report.get("origin_alignment_reviewed", false)):
		failures.append("%s pickup should store origin alignment review metadata" % sprite_name)
	if ["weapon_pistol_generated", "pickup_silver_key_generated",
			"pickup_blueprint_generated", "pickup_unknown_generated"].has(sprite_name):
		if str(sprite.get_meta("release_decision", "")) != "public_ok":
			failures.append("%s project-owned pickup should be public_ok" % sprite_name)
	elif sprite_name.ends_with("_generated") and str(sprite.get_meta("release_decision", "")) != "internal_only":
		failures.append("%s generated pickup should stay internal-only before public release" % sprite_name)
	elif not sprite_name.ends_with("_generated") and str(sprite.get_meta("release_decision", "")) != "public_ok":
		failures.append("%s atlas pickup should be public_ok" % sprite_name)

func _check_full_hp_potion_is_not_wasted(failures: Array[String]) -> void:
	var player := DummyPlayer.new()
	player.hp = player.max_hp
	root.add_child(player)
	var pickup := Pickup.new()
	pickup.configure({"type": "potion", "value": 20}, player)
	pickup.global_position = Vector2(20, 20)
	root.add_child(pickup)
	await process_frame
	pickup.call("_collect")
	await process_frame
	if not is_instance_valid(pickup) or not pickup.is_inside_tree():
		failures.append("full-hp potion should stay on floor instead of being wasted")
	if not bool(pickup.get_meta("blocked_full_hp", false)):
		failures.append("full-hp potion should mark blocked pickup feedback")
	var toast := root.get_node_or_null("PickupToast") as Label
	if toast == null or not toast.text.contains("Full HP"):
		failures.append("full-hp potion should show Full HP feedback")
	if toast != null:
		toast.queue_free()
	if is_instance_valid(pickup):
		pickup.queue_free()
	player.queue_free()
	await process_frame

func _check_meta_currency_hud_flash(failures: Array[String]) -> void:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	var floor := FloorController.new()
	var hud := HUD.new()
	root.add_child(player)
	root.add_child(floor)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	hud.bind(player, floor)
	await process_frame

	if not _has_signal(player, "meta_currency_changed"):
		failures.append("player should expose meta_currency_changed for HUD pickup feedback")
	else:
		player.add_meta_currency("soul_shards", 3)
		await process_frame
		var flash := hud.get_node_or_null("MetaCurrencyFlashLabel") as Label
		if flash == null:
			failures.append("HUD should create a meta currency flash label")
		elif not flash.visible:
			failures.append("meta currency flash should become visible")
		elif not flash.text.contains("Soul Shards +3"):
			failures.append("meta currency flash should show readable currency and gained amount")

	hud.queue_free()
	floor.queue_free()
	player.queue_free()
	await process_frame

func _has_signal(node: Object, signal_name: String) -> bool:
	for info in node.get_signal_list():
		if str(info.get("name", "")) == signal_name:
			return true
	return false
