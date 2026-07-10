extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

class DummyPlayer:
	extends Node2D
	var combo_events: Array = []
	func take_damage(_amount: int) -> void:
		pass
	func record_element_combo(info: Dictionary) -> void:
		combo_events.append(info.duplicate(true))

func _init() -> void:
	var failures: Array[String] = []

	await _check_enemy_affinity_damage(failures)
	await _check_enemy_status_feedback(failures)
	await _check_enemy_status_stack_readability(failures)
	await _check_enemy_status_expire_feedback(failures)
	await _check_element_combo_feedback(failures)
	_check_element_combo_codex(failures)
	_check_element_preview_data(failures)
	_check_element_icon_mapping(failures)
	await _check_renderer_passes_affinity(failures)
	await _check_renderer_records_element_combos(failures)

	if failures.is_empty():
		print("Element affinity smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_enemy_affinity_damage(failures: Array[String]) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.max_hp = 100
	enemy.hp = 100
	if not enemy.has_method("configure_element_affinity"):
		failures.append("enemy should expose configure_element_affinity")
		enemy.queue_free()
		await process_frame
		return
	enemy.call("configure_element_affinity", ["fire"], ["ice"])
	enemy.hit(10, "fire")
	await process_frame
	var weak_damage := 100 - enemy.hp
	if weak_damage <= 10:
		failures.append("weak element should increase hit damage")
	if str(enemy.get_meta("weak", "")) == "":
		failures.append("enemy should store weakness metadata for UI/debug")
	if str(enemy.get_meta("last_hit_effectiveness", "")) != "weak":
		failures.append("weak element hit should store effectiveness metadata")
	var weak_number := enemy.get_node_or_null("DamageNumber") as Label
	if weak_number == null or not weak_number.text.contains("WEAK"):
		failures.append("weak element hit should show WEAK damage feedback")
	elif str(weak_number.get_meta("damage_kind", "")) != "weak" \
			or str(weak_number.get_meta("element", "")) != "fire" \
			or int(weak_number.get_meta("damage_amount", 0)) != weak_damage:
		failures.append("weak damage number should store kind, element, and amount metadata")
	var weak_sfx := enemy.get_node_or_null("EnemyHitSfx") as AudioStreamPlayer
	if weak_sfx == null:
		failures.append("weak element hit should create hit sound feedback")
	else:
		if str(weak_sfx.get_meta("enemy_hit_sound_id", "")) != "enemy_hit_weak":
			failures.append("weak element hit should use weak hit cue")
		if str(weak_sfx.get_meta("enemy_hit_kind", "")) != "weak":
			failures.append("weak element hit sound should store hit kind")
		if str(weak_sfx.get_meta("enemy_hit_element", "")) != "fire":
			failures.append("weak element hit sound should store element")
	enemy.queue_free()
	await process_frame

	enemy = ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.max_hp = 100
	enemy.hp = 100
	enemy.call("configure_element_affinity", ["fire"], ["ice"])
	enemy.hit(10, "ice")
	await process_frame
	var resist_damage := 100 - enemy.hp
	if resist_damage >= 10:
		failures.append("resisted element should reduce hit damage")
	if str(enemy.get_meta("last_hit_effectiveness", "")) != "resist":
		failures.append("resisted element hit should store effectiveness metadata")
	var resist_number := enemy.get_node_or_null("DamageNumber") as Label
	if resist_number == null or not resist_number.text.contains("RESIST"):
		failures.append("resisted element hit should show RESIST damage feedback")
	elif str(resist_number.get_meta("damage_kind", "")) != "resist" \
			or str(resist_number.get_meta("element", "")) != "ice" \
			or float(resist_number.scale.x) >= 1.0:
		failures.append("resist damage number should store metadata and render quieter than normal")
	var resist_sfx := enemy.get_node_or_null("EnemyHitSfx") as AudioStreamPlayer
	if resist_sfx == null:
		failures.append("resisted element hit should create hit sound feedback")
	else:
		if str(resist_sfx.get_meta("enemy_hit_sound_id", "")) != "enemy_hit_resist":
			failures.append("resisted element hit should use resist hit cue")
		if str(resist_sfx.get_meta("enemy_hit_kind", "")) != "resist":
			failures.append("resisted element hit sound should store hit kind")
		if str(resist_sfx.get_meta("enemy_hit_element", "")) != "ice":
			failures.append("resisted element hit sound should store element")
	enemy.queue_free()
	await process_frame

func _check_enemy_status_feedback(failures: Array[String]) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.apply_element("fire")
	await process_frame
	var element_feedback := enemy.get_node_or_null("EnemyStatusFeedback") as Label
	if element_feedback == null or not element_feedback.text.contains("Fire"):
		failures.append("applying enemy element should show readable EnemyStatusFeedback")
	enemy.add_status("rooted", 1.0)
	await process_frame
	var status_feedback := enemy.get_node_or_null("EnemyStatusFeedback") as Label
	if status_feedback == null or not status_feedback.text.contains("Rooted"):
		failures.append("adding enemy status should refresh EnemyStatusFeedback")
	enemy.queue_free()
	await process_frame

func _check_enemy_status_stack_readability(failures: Array[String]) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.add_status("rooted", 0.2)
	await process_frame
	var stack := enemy.get_node_or_null("EnemyStatusStack") as Node2D
	if stack == null:
		failures.append("active enemy statuses should render a persistent EnemyStatusStack")
	else:
		if int(stack.get_meta("status_count", 0)) != 1:
			failures.append("EnemyStatusStack should expose active status_count metadata")
		if not str(stack.get_meta("active_statuses", "")).contains("rooted"):
			failures.append("EnemyStatusStack should expose active status ids metadata")
		var badge := stack.get_child(0) as Label if stack.get_child_count() > 0 else null
		if badge == null:
			failures.append("EnemyStatusStack should contain readable status badges")
		else:
			if not badge.text.contains("Rooted"):
				failures.append("enemy status badge should show readable status text")
			if str(badge.get_meta("status_id", "")) != "rooted":
				failures.append("enemy status badge should store status_id metadata")
			if float(badge.get_meta("status_seconds_left", 0.0)) <= 0.0:
				failures.append("enemy status badge should store seconds-left metadata")
			if str(badge.get_meta("status_color_role", "")) != "rooted":
				failures.append("enemy status badge should expose color role metadata")
	await create_timer(0.28).timeout
	stack = enemy.get_node_or_null("EnemyStatusStack") as Node2D
	if stack != null and int(stack.get_meta("status_count", 0)) != 0:
		failures.append("EnemyStatusStack should clear expired status badges")
	enemy.queue_free()
	await process_frame

func _check_enemy_status_expire_feedback(failures: Array[String]) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.add_status("rooted", 0.01)
	await create_timer(0.08).timeout
	var expired_feedback := enemy.get_node_or_null("EnemyStatusFeedback") as Label
	if expired_feedback == null or not expired_feedback.text.contains("Rooted ended"):
		failures.append("expired enemy status should show ended EnemyStatusFeedback")
	enemy.queue_free()
	await process_frame

func _check_element_combo_feedback(failures: Array[String]) -> void:
	var script: Script = load("res://scripts/elements/element_system.gd")
	var audio_db: Script = load("res://scripts/audio/audio_cue_db.gd")
	if not _script_has_method(script, "combo_info"):
		failures.append("ElementSystem should expose combo_info for readable combo feedback")
	else:
		var info: Dictionary = script.call("combo_info", "fire", "ice")
		if str(info.get("name", "")) != "Thermal Shock":
			failures.append("combo_info should map fire+ice to Thermal Shock")
		if str(info.get("id", "")) != "thermal_shock":
			failures.append("combo_info should expose stable combo id")
		if not str(info.get("effect", "")).contains("burst"):
			failures.append("combo_info should expose readable combo effect")
	if not _script_has_method(audio_db, "element_combo_cue"):
		failures.append("AudioCueDB should expose element_combo_cue")
	else:
		var cue: Dictionary = audio_db.call("element_combo_cue", "thermal_shock")
		if str(cue.get("id", "")) != "element_combo_thermal_shock":
			failures.append("element_combo_cue should map thermal_shock to stable cue id")
		if str(cue.get("kind", "")) != "element_combo":
			failures.append("element_combo_cue should expose element_combo kind")
		if str(cue.get("source", "")) != "AudioCueDB":
			failures.append("element_combo_cue should come from AudioCueDB")
	if not bool(audio_db.call("cue_exists", "element_combo_thermal_shock")):
		failures.append("AudioCueDB should report known element combo cue ids")

	var enemy: Enemy = ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame
	if not _has_signal(enemy, "element_combo_triggered"):
		failures.append("Enemy should emit element_combo_triggered for run combo tracking")
	enemy.max_hp = 100
	enemy.hp = 100
	enemy.apply_element("fire")
	await process_frame
	enemy.apply_element("ice")
	await process_frame
	var combo_feedback := enemy.get_node_or_null("EnemyComboFeedback") as Label
	if combo_feedback == null:
		failures.append("triggering an element combo should show EnemyComboFeedback")
	else:
		if not combo_feedback.text.contains("Thermal Shock"):
			failures.append("combo feedback should show readable combo name")
		if str(combo_feedback.get_meta("combo_id", "")) != "thermal_shock":
			failures.append("combo feedback should store stable combo id metadata")
		if str(combo_feedback.get_meta("combo_name", "")) != "Thermal Shock":
			failures.append("combo feedback should store readable combo name metadata")
		if not str(combo_feedback.get_meta("combo_elements", "")).contains("fire") \
				or not str(combo_feedback.get_meta("combo_elements", "")).contains("ice"):
			failures.append("combo feedback should store source element pair metadata")
		if not str(combo_feedback.get_meta("combo_effect", "")).contains("burst"):
			failures.append("combo feedback should store readable combo effect metadata")
		if str(enemy.get_meta("last_combo_id", "")) != "thermal_shock":
			failures.append("enemy should remember last combo id for HUD/debug hooks")
	var combo_sfx := enemy.get_node_or_null("EnemyComboSfx") as AudioStreamPlayer
	if combo_sfx == null:
		failures.append("triggering an element combo should create EnemyComboSfx placeholder")
	else:
		if str(combo_sfx.get_meta("combo_id", "")) != "thermal_shock":
			failures.append("combo SFX should store combo id metadata")
		if str(combo_sfx.get_meta("combo_sound_id", "")) != "element_combo_thermal_shock":
			failures.append("combo SFX should store stable cue id metadata")
		if str(combo_sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("combo SFX should come from AudioCueDB")
		if str(combo_sfx.get_meta("audio_cue_kind", "")) != "element_combo":
			failures.append("combo SFX should tag element_combo cue kind")
		if not bool(combo_sfx.get_meta("placeholder_audio_stream", false)):
			failures.append("combo SFX should use generated placeholder stream")
		if not bool(combo_sfx.get_meta("playback_requested", false)):
			failures.append("combo SFX should request playback")
	enemy.queue_free()
	await process_frame

func _check_renderer_records_element_combos(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [
		{
			"enemy": {
				"id": "combo_smoke",
				"kind": "melee",
				"hp": 80,
				"dmg": 2,
				"weak": [],
				"resist": [],
			},
			"wave": 1,
			"tile": Vector2i(4, 4),
			"elite": false,
			"modifier": "",
		},
	]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.COMBAT)
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("renderer should spawn combo tracking enemy")
	else:
		enemy.apply_element("fire")
		await process_frame
		enemy.apply_element("ice")
		await process_frame
		if dummy.combo_events.is_empty():
			failures.append("RoomRenderer should forward enemy element combos to the player run tracker")
		else:
			var combo: Dictionary = dummy.combo_events[0]
			if str(combo.get("id", "")) != "thermal_shock":
				failures.append("forwarded combo should preserve stable combo id")
			if str(combo.get("name", "")) != "Thermal Shock":
				failures.append("forwarded combo should preserve readable combo name")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _check_element_combo_codex(failures: Array[String]) -> void:
	var script: Script = load("res://scripts/elements/element_system.gd")
	if not _script_has_method(script, "combo_codex_entries"):
		failures.append("ElementSystem should expose combo_codex_entries")
		return
	var entries: Array = script.call("combo_codex_entries")
	if entries.size() != 6:
		failures.append("combo codex should expose six MVP element combos")
	var labels: Array[String] = []
	for entry in entries:
		if not (entry is Dictionary):
			failures.append("combo codex entries should be dictionaries")
			continue
		labels.append(str((entry as Dictionary).get("name", "")))
	for expected in ["Thermal Shock", "Plasma", "Burning Smog", "Deep Freeze", "Frostbane", "Toxic Current"]:
		if not labels.has(expected):
			failures.append("combo codex missing %s" % expected)

func _check_element_preview_data(failures: Array[String]) -> void:
	var script: Script = load("res://scripts/elements/element_system.gd")
	if not _script_has_method(script, "element_preview"):
		failures.append("ElementSystem should expose element_preview for class select")
		return
	var preview: Dictionary = script.call("element_preview", "fire")
	if str(preview.get("name", "")) != "Fire":
		failures.append("fire element preview should expose readable name")
	if not str(preview.get("status", "")).contains("Burn DoT"):
		failures.append("fire element preview should describe Burn DoT")
	if not is_equal_approx(float(preview.get("duration", 0.0)), 4.0):
		failures.append("fire element preview should expose status duration")
	var combos: Array = preview.get("combos", [])
	if combos.size() != 3:
		failures.append("fire element preview should include three related combos")
	var names: Array[String] = []
	for combo in combos:
		if combo is Dictionary:
			names.append(str((combo as Dictionary).get("name", "")))
	for expected in ["Thermal Shock", "Plasma", "Burning Smog"]:
		if not names.has(expected):
			failures.append("fire element preview missing combo %s" % expected)

func _check_element_icon_mapping(failures: Array[String]) -> void:
	var script: Script = load("res://scripts/elements/element_system.gd")
	if not _script_has_method(script, "element_icon_sprite"):
		failures.append("ElementSystem should expose element_icon_sprite for class select buttons")
		return
	var expected := {
		"fire": "flask_red",
		"ice": "flask_blue",
		"lightning": "flask_yellow",
		"poison": "flask_green",
	}
	for element in expected.keys():
		if str(script.call("element_icon_sprite", str(element))) != str(expected[element]):
			failures.append("%s element icon should use %s" % [element, expected[element]])

func _script_has_method(script: Script, method_name: String) -> bool:
	for method in script.get_script_method_list():
		if String(method.get("name", "")) == method_name:
			return true
	return false

func _has_signal(node: Object, signal_name: String) -> bool:
	for info in node.get_signal_list():
		if str(info.get("name", "")) == signal_name:
			return true
	return false

func _check_renderer_passes_affinity(failures: Array[String]) -> void:
	var renderer := RoomRenderer.new()
	var dummy := DummyPlayer.new()
	root.add_child(dummy)
	root.add_child(renderer)
	var plan: Array[Dictionary] = [
		{
			"enemy": {
				"id": "affinity_smoke",
				"kind": "melee",
				"hp": 30,
				"dmg": 2,
				"weak": ["fire"],
				"resist": ["ice"],
			},
			"wave": 1,
			"tile": Vector2i(4, 4),
			"elite": false,
			"modifier": "",
		},
	]
	renderer.setup(_basic_grid(), plan, ENEMY_SCENE, dummy, RoomNode.RoomType.COMBAT)
	await process_frame
	var enemy := _first_enemy(renderer)
	if enemy == null:
		failures.append("renderer should spawn affinity enemy")
	else:
		enemy.hit(10, "fire")
		if enemy.hp >= 20:
			failures.append("renderer should pass enemy weakness from data")
		if str(enemy.get_meta("resist", "")) == "":
			failures.append("renderer should pass enemy resistance metadata")
	renderer.queue_free()
	dummy.queue_free()
	await process_frame

func _first_enemy(parent: Node) -> Enemy:
	for child in parent.get_children():
		if child is Enemy:
			return child
	return null

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
