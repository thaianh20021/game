extends SceneTree

const TrapScript := preload("res://scripts/rooms/trap.gd")
const BreakablePropScript := preload("res://scripts/rooms/breakable_prop.gd")
const RoomInteractableScript := preload("res://scripts/rooms/room_interactable.gd")
const FloatingGunScript := preload("res://scripts/enemies/floating_gun.gd")

class DummyPlayer:
	extends Node2D
	signal hp_changed(current: int, max_value: int)
	signal gold_changed(total: int)

	var hp := 60
	var max_hp := 100
	var gold := 30
	var damage_taken := 0
	var room_decisions: Array[String] = []
	var damage_sources := {}

	func take_damage(amount: int) -> void:
		damage_taken += amount
		hp = maxi(hp - amount, 0)
		hp_changed.emit(hp, max_hp)

	func heal(amount: int) -> void:
		hp = mini(hp + amount, max_hp)
		hp_changed.emit(hp, max_hp)

	func add_gold(amount: int) -> void:
		gold += amount
		gold_changed.emit(gold)

	func record_room_decision(label: String, reason: String = "") -> void:
		room_decisions.append("%s (%s)" % [label, reason] if reason != "" else label)

	func room_decision_history_summary(_max_items: int = 6) -> String:
		return "None" if room_decisions.is_empty() else " -> ".join(room_decisions)

	func record_damage_taken(source_label: String, amount: int) -> void:
		damage_sources[source_label] = int(damage_sources.get(source_label, 0)) + amount

	func damage_taken_summary(_max_items: int = 4) -> String:
		var parts: Array[String] = []
		for source in damage_sources.keys():
			parts.append("%s %d" % [str(source), int(damage_sources[source])])
		parts.sort()
		return "None" if parts.is_empty() else " / ".join(parts)

func _init() -> void:
	var failures: Array[String] = []
	await _check_traps_and_props(failures)
	await _check_interactables(failures)
	await _check_renderer_room_features(failures)
	_check_weapon_patterns(failures)
	await _check_boss_floating_guns(failures)

	if failures.is_empty():
		print("Soul-like expansion smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_traps_and_props(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	parent.add_child(dummy)

	var trap := TrapScript.new()
	trap.configure("spike", 7, 0.5, 0.1)
	parent.add_child(trap)
	if float(trap.get_meta("telegraph_seconds", 0.0)) < 0.5:
		failures.append("trap should clamp telegraph readability to at least 0.5s")
	if trap.apply_to(dummy, 0.0):
		failures.append("trap should telegraph before first damage")
	var armed_warning := trap.get_node_or_null("TrapArmedWarning") as Label
	if armed_warning == null:
		failures.append("trap should show arming warning during telegraph")
	elif not armed_warning.text.contains("!"):
		failures.append("trap arming warning should be compact and readable")
	if not bool(trap.get_meta("armed_feedback", false)):
		failures.append("trap should mark arming feedback metadata")
	var arm_sfx := trap.get_node_or_null("TrapArmedSfx") as AudioStreamPlayer
	if arm_sfx == null:
		failures.append("trap arming should create sound placeholder")
	else:
		if str(arm_sfx.get_meta("trap_sound_id", "")) != "trap_arm":
			failures.append("trap arming sound should expose arm cue id")
		if str(arm_sfx.get_meta("trap_kind", "")) != "spike":
			failures.append("trap arming sound should store trap kind metadata")
		if str(arm_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("trap arming sound should come from AudioCueDB")
		if arm_sfx.stream == null:
			failures.append("trap arming sound should assign an audio stream")
		if DisplayServer.get_name() == "headless" \
				and not bool(arm_sfx.get_meta("headless_playback_skipped", false)):
			failures.append("trap arming sound should skip playback in headless smoke")
	if trap.apply_to(dummy, 0.49):
		failures.append("trap should not damage before the minimum readable telegraph")
	if not trap.apply_to(dummy, 0.51):
		failures.append("trap should damage after telegraph")
	if dummy.damage_taken != 7:
		failures.append("trap should deal configured damage once")
	var trap_history := str(dummy.call("room_decision_history_summary"))
	if not trap_history.contains("Trap Hit") or not trap_history.contains("Spike") \
			or not trap_history.contains("-7 HP"):
		failures.append("trap damage should be recorded in room decision history")
	var damage_history := str(dummy.call("damage_taken_summary"))
	if not damage_history.contains("Trap: Spike 7"):
		failures.append("trap damage should be recorded with a readable damage source")
	var trap_feedback := trap.get_node_or_null("TrapTriggeredFeedback") as Label
	if trap_feedback == null:
		failures.append("trap should show trigger feedback after dealing damage")
	elif not trap_feedback.text.contains("-7"):
		failures.append("trap trigger feedback should show damage dealt")
	if not bool(trap.get_meta("triggered_feedback", false)):
		failures.append("trap should mark that trigger feedback was shown")
	var sfx := trap.get_node_or_null("TrapTriggeredSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("trap trigger should create sound placeholder")
	else:
		if str(sfx.get_meta("trap_sound_id", "")) != "trap_trigger":
			failures.append("trap trigger sound should expose trigger cue id")
		if str(sfx.get_meta("trap_kind", "")) != "spike":
			failures.append("trap trigger sound should store trap kind metadata")
		if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("trap trigger sound should come from AudioCueDB")
		if sfx.stream == null:
			failures.append("trap trigger sound should assign an audio stream")
		if DisplayServer.get_name() == "headless" \
				and not bool(sfx.get_meta("headless_playback_skipped", false)):
			failures.append("trap trigger sound should skip playback in headless smoke")
	if trap.apply_to(dummy, 0.2):
		failures.append("trap should respect cooldown")

	var prop := BreakablePropScript.new()
	prop.configure("crate", 2, {"type": "gold", "value": 3}, dummy)
	prop.position = Vector2(64, 0)
	parent.add_child(prop)
	if prop.hit(1):
		failures.append("prop should survive first partial hit")
	await process_frame
	var prop_hit_feedback := prop.get_node_or_null("PropHitFeedback") as Label
	if prop_hit_feedback == null:
		failures.append("damaged prop should show hit feedback")
	elif not prop_hit_feedback.text.contains("-1"):
		failures.append("prop hit feedback should show damage amount")
	if not prop.hit(1):
		failures.append("prop should break at zero hp")
	await process_frame
	if parent.get_tree().get_nodes_in_group("room_pickups").is_empty():
		failures.append("broken prop should spawn a pickup")
	var prop_feedback := parent.get_node_or_null("PropBreakFeedback") as Label
	if prop_feedback == null:
		failures.append("broken prop should spawn break feedback")
	elif not prop_feedback.text.contains("Break"):
		failures.append("prop break feedback should describe the break")
	parent.queue_free()
	await process_frame

func _check_interactables(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	parent.add_child(dummy)

	var chest := RoomInteractableScript.new()
	chest.configure("chest", dummy)
	parent.add_child(chest)
	if not chest.use():
		failures.append("chest should be usable once")
	await process_frame
	var chest_feedback := chest.get_node_or_null("CompletedFeedback") as Label
	if chest_feedback == null:
		failures.append("chest should show completion feedback")
	elif not chest_feedback.text.contains("Opened"):
		failures.append("chest completion feedback should say Opened")
	if chest.use():
		failures.append("chest should not be reusable")

	var shrine := RoomInteractableScript.new()
	shrine.configure("shrine", dummy)
	parent.add_child(shrine)
	dummy.hp = 40
	if not shrine.use() or dummy.hp <= 40:
		failures.append("shrine should heal the player")
	await process_frame
	var shrine_feedback := shrine.get_node_or_null("CompletedFeedback") as Label
	if shrine_feedback == null:
		failures.append("shrine should show completion feedback")
	elif not shrine_feedback.text.contains("Healed"):
		failures.append("shrine completion feedback should say Healed")

	var shop := RoomInteractableScript.new()
	shop.configure("shop", dummy)
	parent.add_child(shop)
	var before_gold := dummy.gold
	if shop.use():
		failures.append("shop use should open choice flow before buying")
	if dummy.gold != before_gold:
		failures.append("shop request should not spend gold")
	if not shop.buy_choice(0) or dummy.gold >= before_gold:
		failures.append("shop should spend gold after selecting a choice")
	parent.queue_free()
	await process_frame

func _check_renderer_room_features(failures: Array[String]) -> void:
	var grid := _basic_grid()
	var renderer := RoomRenderer.new()
	root.add_child(renderer)
	var dummy := DummyPlayer.new()
	renderer.setup(grid, [], null, dummy, RoomNode.RoomType.TREASURE)
	await process_frame
	if _child_group_count(renderer, "room_interactables") != 1:
		failures.append("treasure room should spawn one interactable")
	renderer.queue_free()
	await process_frame

	renderer = RoomRenderer.new()
	root.add_child(renderer)
	renderer.setup(grid, [], null, dummy, RoomNode.RoomType.COMBAT)
	await process_frame
	if _child_group_count(renderer, "room_traps") == 0:
		failures.append("combat room should spawn traps")
	if _child_group_count(renderer, "breakable_props") == 0:
		failures.append("combat room should spawn breakable props")
	renderer.queue_free()
	await process_frame
	dummy.free()

func _check_weapon_patterns(failures: Array[String]) -> void:
	var bow := Weapon.new()
	bow.equip("hardwood_bow")
	if bow.projectile_count() < 3:
		failures.append("bow should expose spread projectile count")
	var pistol := Weapon.new()
	pistol.equip("scrap_pistol")
	if pistol.burst_count() < 2:
		failures.append("pistol should expose burst count")
	bow.free()
	pistol.free()

func _check_boss_floating_guns(failures: Array[String]) -> void:
	var boss := BossGolem.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(boss)
	boss.target = dummy
	boss.spawn_floating_guns(2)
	await process_frame
	if _child_group_count(boss, "floating_guns") != 2:
		failures.append("boss should spawn requested floating guns")
	for gun in boss.get_children():
		if gun.is_in_group("floating_guns"):
			_assert_floating_gun_sprite(gun, failures)
	boss.queue_free()
	dummy.queue_free()
	await process_frame

func _assert_floating_gun_sprite(gun: Node, failures: Array[String]) -> void:
	var sprite := gun.get_node_or_null("FloatingGunSprite") as AnimatedSprite2D
	if sprite == null or not sprite.visible:
		failures.append("floating gun should use FloatingGunSprite visual")
		return
	var sprite_name := "weapon_red_magic_staff"
	var report := SpriteDB.animation_report(sprite_name)
	if str(sprite.get_meta("sprite_name", "")) != sprite_name:
		failures.append("floating gun sprite metadata should name %s" % sprite_name)
	if int(sprite.get_meta("frame_count", 0)) != int(report.get("frame_count", 0)):
		failures.append("floating gun sprite should store frame count metadata")
	if not bool(sprite.get_meta("stable_size", false)) or not bool(report.get("stable_size", false)):
		failures.append("floating gun sprite should expose stable frame grid metadata")
	var release := SpriteDB.release_report([sprite_name])
	var entry: Dictionary = Dictionary(release.get("sprites", {})).get(sprite_name, {})
	if str(sprite.get_meta("asset_source", "")) != str(entry.get("source", "")):
		failures.append("floating gun sprite should expose asset_source release metadata")
	if str(sprite.get_meta("release_decision", "")) != str(entry.get("release_decision", "")):
		failures.append("floating gun sprite should expose release_decision metadata")
	if str(sprite.get_meta("review_status", "")) != str(entry.get("review_status", "")):
		failures.append("floating gun sprite should expose review_status metadata")
	if str(sprite.get_meta("replacement_policy", "")) != str(entry.get("replacement_policy", "")):
		failures.append("floating gun sprite should expose replacement_policy metadata")
	if bool(sprite.get_meta("needs_replacement_before_public", true)) \
			!= bool(entry.get("needs_replacement_before_public", false)):
		failures.append("floating gun sprite should expose replacement gate metadata")
	if bool(sprite.get_meta("frame_grid_ok", false)) != bool(entry.get("frame_grid_ok", false)):
		failures.append("floating gun sprite should expose frame_grid_ok metadata")
	for child in gun.get_children():
		if child is Polygon2D and child.visible:
			failures.append("floating gun should hide polygon placeholder when sprite exists")

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

func _child_group_count(parent: Node, group_name: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.is_in_group(group_name):
			count += 1
	return count
