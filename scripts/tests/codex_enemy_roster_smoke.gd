extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	_check_biome_enemy_codex(failures)
	await _check_codex_ui_enemy_roster(failures)

	if failures.is_empty():
		print("Codex enemy roster smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_biome_enemy_codex(failures: Array[String]) -> void:
	var script = load("res://scripts/dungeon_gen/biome_db.gd")
	if not _script_has_method(script, "enemy_codex_entries"):
		failures.append("BiomeDB should expose enemy_codex_entries for hub codex")
		return
	var entries: Array = script.call("enemy_codex_entries")
	if entries.size() < 40:
		failures.append("enemy codex should include all four biome enemy pools")
	var forge := _entry_by_id(entries, "forge_golem_boss")
	if forge.is_empty():
		failures.append("enemy codex should include Forge Golem boss")
	else:
		for key in ["id", "name", "kind", "biome_id", "biome_name", "floor_index",
				"weak_text", "resist_text", "is_boss", "run_finale"]:
			if not forge.has(key):
				failures.append("forge boss codex entry missing %s" % key)
		if str(forge.get("biome_id", "")) != "ember_forge":
			failures.append("forge boss codex should store biome id")
		if str(forge.get("weak_text", "")) != "water":
			failures.append("forge boss codex should summarize weakness")
		if not str(forge.get("resist_text", "")).contains("fire"):
			failures.append("forge boss codex should summarize resistances")
		if not bool(forge.get("is_boss", false)):
			failures.append("forge boss codex should flag boss entries")
	var archive := _entry_by_id(entries, "archive_golem_boss")
	if archive.is_empty() or not bool(archive.get("run_finale", false)):
		failures.append("enemy codex should flag Archive Golem as finale biome boss")
	if not _script_has_method(script, "enemy_codex_summary"):
		failures.append("BiomeDB should expose enemy_codex_summary for readable codex UI")
	else:
		var summary := str(script.call("enemy_codex_summary"))
		for token in ["Enemy Roster:", "Ancient Cave 11", "Ember Forge 10",
				"Forge Golem", "Crystal Archive 10", "Archive Golem finale"]:
			if not summary.contains(token):
				failures.append("enemy codex summary missing token: %s" % token)

func _check_codex_ui_enemy_roster(failures: Array[String]) -> void:
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	var codex := screen.find_child("HubService_Codex", true, false) as Button
	if codex == null:
		failures.append("class select should expose Codex hub button")
		screen.queue_free()
		return
	codex.emit_signal("pressed")
	await process_frame
	var detail := screen.find_child("CodexDetailLabel", true, false) as Label
	if detail == null:
		failures.append("codex UI should expose detail label")
	else:
		for token in ["Enemy Roster:", "Ancient Cave 11", "Forge Golem",
				"Archive Golem finale", "Weak water", "Resist fire"]:
			if not detail.text.contains(token):
				failures.append("codex UI enemy roster missing token: %s" % token)
	screen.queue_free()
	await process_frame

func _entry_by_id(entries: Array, id: String) -> Dictionary:
	for raw in entries:
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw as Dictionary
	return {}

func _script_has_method(script: Script, method_name: String) -> bool:
	for method in script.get_script_method_list():
		if String(method.get("name", "")) == method_name:
			return true
	return false
