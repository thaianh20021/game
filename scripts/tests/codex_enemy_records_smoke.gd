extends SceneTree

const SAVE_PATH := "user://codex_enemy_records_smoke.json"
const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")

func _init() -> void:
	var failures: Array[String] = []

	_check_player_enemy_codex_context(failures)
	_check_meta_enemy_records(failures)
	await _check_codex_enemy_record_ui(failures)
	_check_runtime_wiring(failures)

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	if failures.is_empty():
		print("Codex enemy records smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_player_enemy_codex_context(failures: Array[String]) -> void:
	var player := Player.new()
	if not player.has_method("on_enemy_seen"):
		failures.append("player should record enemy seen events for Codex unlocks")
		return
	if not player.has_method("enemy_codex_context"):
		failures.append("player should expose enemy_codex_context for run banking")
		return
	var payload := _enemy_payload("flame_imp", "Flame Imp", "ranged", "ember_forge", "Ember Forge")
	player.call("on_enemy_seen", payload)
	player.call("on_enemy_seen", payload)
	player.call("on_enemy_killed", payload)
	var context: Dictionary = player.call("enemy_codex_context")
	var seen := _entry_by_id(Array(context.get("enemy_codex_seen", [])), "flame_imp")
	var defeated := _entry_by_id(Array(context.get("enemy_codex_defeated", [])), "flame_imp")
	if int(seen.get("count", 0)) != 2:
		failures.append("enemy_codex_context should count seen enemies")
	if int(defeated.get("count", 0)) != 1:
		failures.append("enemy_codex_context should count defeated enemies")
	if str(defeated.get("biome_id", "")) != "ember_forge":
		failures.append("enemy_codex_context should preserve biome id")
	player.queue_free()

func _check_meta_enemy_records(failures: Array[String]) -> void:
	var script = load("res://scripts/progression/meta_progression.gd")
	var fresh: Dictionary = script.call("default_data")
	if not fresh.has("enemy_records"):
		failures.append("default meta data should include enemy_records")
	var data: Dictionary = script.call("bank_run_rewards",
		{"gold": 0, "floor": 3},
		"victory",
		SAVE_PATH,
		{
			"seed": 20260707,
			"seed_label": "Seed",
			"biome_id": "ember_forge",
			"biome": "Ember Forge",
			"enemy_codex_seen": [
				_enemy_payload("flame_imp", "Flame Imp", "ranged", "ember_forge", "Ember Forge", 3),
				_enemy_payload("forge_golem_boss", "Forge Golem", "boss", "ember_forge", "Ember Forge", 1),
			],
			"enemy_codex_defeated": [
				_enemy_payload("flame_imp", "Flame Imp", "ranged", "ember_forge", "Ember Forge", 2),
				_enemy_payload("forge_golem_boss", "Forge Golem", "boss", "ember_forge", "Ember Forge", 1),
			],
		})
	var records: Dictionary = data.get("enemy_records", {})
	var imp: Dictionary = records.get("flame_imp", {})
	if imp.is_empty():
		failures.append("meta progression should store enemy records from run context")
	else:
		if str(imp.get("label", "")) != "Flame Imp":
			failures.append("enemy record should store readable label")
		if str(imp.get("kind", "")) != "ranged":
			failures.append("enemy record should store kind")
		if str(imp.get("biome_id", "")) != "ember_forge":
			failures.append("enemy record should store biome id")
		if int(imp.get("seen", 0)) != 3:
			failures.append("enemy record should count seen enemies")
		if int(imp.get("defeated", 0)) != 2:
			failures.append("enemy record should count defeated enemies")
	var boss: Dictionary = records.get("forge_golem_boss", {})
	if int(boss.get("seen", 0)) != 1 or int(boss.get("defeated", 0)) != 1:
		failures.append("enemy records should include boss encounters")
	var recent: Array = data.get("recent_runs", [])
	if recent.is_empty():
		failures.append("recent run should store enemy record preview")
	else:
		var latest: Dictionary = recent[0]
		if not str(latest.get("enemy_codex", "")).contains("Flame Imp D2/S3"):
			failures.append("recent run should preview enemy codex progress")

func _check_codex_enemy_record_ui(failures: Array[String]) -> void:
	var meta := MetaProgressionScript.default_data()
	meta["enemy_records"] = {
		"flame_imp": {
			"label": "Flame Imp",
			"kind": "ranged",
			"biome": "Ember Forge",
			"biome_id": "ember_forge",
			"seen": 3,
			"defeated": 2,
			"best_floor": 3,
		},
		"forge_golem_boss": {
			"label": "Forge Golem",
			"kind": "boss",
			"biome": "Ember Forge",
			"biome_id": "ember_forge",
			"seen": 1,
			"defeated": 1,
			"best_floor": 3,
		},
	}
	MetaProgressionScript.save_data(meta, MetaProgressionScript.SAVE_PATH)
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	var codex := screen.find_child("HubService_Codex", true, false) as Button
	if codex != null:
		codex.emit_signal("pressed")
		await process_frame
	var summary := screen.find_child("CodexSummaryLabel", true, false) as Label
	if summary == null:
		failures.append("Codex UI should expose summary label")
	else:
		for token in ["Enemies 2", "Enemy Records:", "Flame Imp D2/S3", "Forge Golem D1/S1"]:
			if not summary.text.contains(token):
				failures.append("codex summary should preview enemy record token: %s" % token)
	var detail := screen.find_child("CodexDetailLabel", true, false) as Label
	if detail == null:
		failures.append("Codex UI should expose detail label")
	else:
		for token in ["Enemy Records:", "Flame Imp D2/S3 Ember Forge", "Forge Golem D1/S1 Ember Forge"]:
			if not detail.text.contains(token):
				failures.append("codex detail should preview enemy record token: %s" % token)
	screen.queue_free()
	await process_frame

func _check_runtime_wiring(failures: Array[String]) -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not main_source.contains("enemy_codex_context"):
		failures.append("Main should add player enemy codex context to run banking")
	var renderer_source := FileAccess.get_file_as_string("res://scripts/rooms/room_renderer.gd")
	if not renderer_source.contains("on_enemy_seen"):
		failures.append("RoomRenderer should record enemy seen events when enemies spawn")
	if not renderer_source.contains("\"enemy_id\"") or not renderer_source.contains("\"enemy_name\""):
		failures.append("RoomRenderer should pass enemy identity into enemy kill context")

func _enemy_payload(
		id: String,
		label: String,
		kind: String,
		biome_id: String,
		biome: String,
		count: int = 1,
) -> Dictionary:
	return {
		"id": id,
		"enemy_id": id,
		"name": label,
		"enemy_name": label,
		"kind": kind,
		"enemy_kind": kind,
		"biome_id": biome_id,
		"biome": biome,
		"count": count,
	}

func _entry_by_id(entries: Array, id: String) -> Dictionary:
	for raw in entries:
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw as Dictionary
	return {}
