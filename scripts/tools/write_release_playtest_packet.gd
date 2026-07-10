extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

const DEFAULT_OUTPUT := "res://docs/playtest/release_candidate_manual_playtest.md"

func _init() -> void:
	var output := _arg("output")
	if output == "":
		output = DEFAULT_OUTPUT
	var before := MetaProgressionScript.release_candidate_evidence(
		MetaProgressionScript.load_data())
	var packet: Dictionary = ReleaseAuditScript.release_candidate_playtest_packet(
		MetaProgressionScript.load_data())
	var path := _global_output_path(output)
	var err := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if err != OK:
		push_error("Could not create playtest packet directory: %s" % path.get_base_dir())
		quit(1)
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write playtest packet: %s" % path)
		quit(1)
		return
	file.store_string(str(packet.get("markdown", "")))
	file.close()
	var after := MetaProgressionScript.release_candidate_evidence(
		MetaProgressionScript.load_data())
	if Array(after.get("manual_scenario_results", [])).size() \
			!= Array(before.get("manual_scenario_results", [])).size():
		push_error("Playtest packet tool must not create manual scenario evidence")
		quit(1)
		return
	print("Release playtest packet written: %s" % path)
	quit(0)

func _arg(name: String) -> String:
	var prefix := "--%s=" % name
	for raw_arg in OS.get_cmdline_user_args():
		var text := str(raw_arg).strip_edges()
		if text.begins_with(prefix):
			return text.trim_prefix(prefix).strip_edges()
	return ""

func _global_output_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	if path.contains(":") or path.begins_with("/") or path.begins_with("\\"):
		return path
	return ProjectSettings.globalize_path("res://%s" % path)
