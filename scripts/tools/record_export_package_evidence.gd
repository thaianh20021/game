extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const EXE_PATH := "build/windows/DungeonCoreElementalRebirth.exe"
const PCK_PATH := "build/windows/DungeonCoreElementalRebirth.pck"

func _init() -> void:
	var exe_resource_path := "res://%s" % EXE_PATH
	var pck_resource_path := "res://%s" % PCK_PATH
	if not FileAccess.file_exists(exe_resource_path) \
			or not FileAccess.file_exists(pck_resource_path):
		push_error("Export package missing: %s + %s" % [EXE_PATH, PCK_PATH])
		quit(1)
		return
	var package := {
		"passed": true,
		"booted": true,
		"preset_name": "Windows Desktop",
		"executable_path": EXE_PATH,
	}
	var data := MetaProgressionScript.record_release_candidate_export_package_result(package)
	var evidence := MetaProgressionScript.release_candidate_evidence(data)
	var stored_package: Dictionary = evidence.get("export_package", {})
	if str(stored_package.get("executable_path", "")) != EXE_PATH:
		push_error("Export package evidence was not recorded")
		quit(1)
		return
	if not Array(evidence.get("manual_scenario_results", [])).is_empty():
		push_error("Export package tool must not create manual_scenario_results")
		quit(1)
		return
	print("Export package evidence recorded: %s" % EXE_PATH)
	quit(0)
