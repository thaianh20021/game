extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var before := MetaProgressionScript.release_candidate_evidence(
		MetaProgressionScript.load_data())
	var manual_count_before := Array(before.get("manual_scenario_results", [])).size()
	var template: Dictionary = ReleaseAuditScript.playtest_notes_template()
	var notes := {}
	var missing: Array[String] = []
	var placeholders: Array[String] = []
	for raw_field in Array(template.get("required_fields", [])):
		var field := str(raw_field)
		var value := _arg(field)
		if value == "":
			missing.append(field)
		elif ReleaseAuditScript.manual_evidence_value_placeholder(value):
			placeholders.append(field)
		else:
			notes[field] = value
	if not missing.is_empty():
		push_error("Missing playtest note args: %s" % ", ".join(missing))
		push_error(str(template.get("template_text", "")))
		quit(1)
		return
	if not placeholders.is_empty():
		push_error("Placeholder evidence is not valid for playtest notes: %s" % ", ".join(placeholders))
		quit(1)
		return
	if _dry_run():
		print("Playtest notes dry run OK: seed %s, class %s, mode %s" % [
			str(notes.get("seed", "")),
			str(notes.get("class_id", "")),
			str(notes.get("mode", "")),
		])
		_print_notes_summary(notes)
		print("No release evidence recorded")
		quit(0)
		return
	var data := MetaProgressionScript.record_release_candidate_playtest_notes_result(notes)
	var evidence := MetaProgressionScript.release_candidate_evidence(data)
	if Dictionary(evidence.get("playtest_notes", {})).is_empty():
		push_error("Playtest notes evidence was not recorded")
		quit(1)
		return
	if Array(evidence.get("manual_scenario_results", [])).size() != manual_count_before:
		push_error("Playtest notes tool must not create manual_scenario_results")
		quit(1)
		return
	print("Playtest notes evidence recorded: seed %s, class %s, mode %s" % [
		str(notes.get("seed", "")),
		str(notes.get("class_id", "")),
		str(notes.get("mode", "")),
	])
	_print_notes_summary(notes)
	quit(0)

func _arg(name: String) -> String:
	var prefix := "--%s=" % name
	for raw_arg in OS.get_cmdline_user_args():
		var text := str(raw_arg).strip_edges()
		if text.begins_with(prefix):
			return text.trim_prefix(prefix).strip_edges()
	return ""

func _dry_run() -> bool:
	return ["true", "1", "yes"].has(_arg("dry-run").to_lower()) \
		or ["true", "1", "yes"].has(_arg("dry_run").to_lower())

func _print_notes_summary(notes: Dictionary) -> void:
	print("Coverage: animation, polygon, wave, HUD, audio")
	print("Release decision: %s" % str(notes.get("release_decision", "")))
