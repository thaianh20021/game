extends SceneTree

const TOOL_PATH := "res://scripts/tools/print_local_asset_inventory.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_inventory_api(failures)
	_check_inventory_tool(failures)
	if failures.is_empty():
		print("Local asset inventory tool smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_inventory_api(failures: Array[String]) -> void:
	var release_audit = load("res://scripts/assets/release_audit.gd")
	if not release_audit.has_method("local_asset_folder_inventory"):
		failures.append("ReleaseAudit should expose local_asset_folder_inventory")
		return
	var inventory: Dictionary = release_audit.call(
		"local_asset_folder_inventory", "E:/AI/asset")
	if str(inventory.get("root", "")) != "E:/AI/asset":
		failures.append("local asset inventory should preserve requested root")
	if not bool(inventory.get("root_exists", false)):
		failures.append("local asset inventory should confirm E:/AI/asset exists")
	if not Array(inventory.get("usable_runtime_packs", [])).has(
			"Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc"):
		failures.append("local asset inventory should mark Zerie pack as usable runtime candidate")
	for blocked in ["src", "src2"]:
		if not Array(inventory.get("reference_only_packs", [])).has(blocked):
			failures.append("local asset inventory should keep %s reference-only" % blocked)
	if int(inventory.get("reviewed_manifest_count", 0)) < 11:
		failures.append("local asset inventory should count reviewed Zerie manifests")
	if not str(inventory.get("policy", "")).contains("no_direct_fanmade_copy"):
		failures.append("local asset inventory should explain no-direct-copy policy")

func _check_inventory_tool(failures: Array[String]) -> void:
	if not ResourceLoader.exists(TOOL_PATH):
		failures.append("local asset inventory print tool should exist")
		return
	var source := FileAccess.get_file_as_string(TOOL_PATH)
	for token in [
			"local_asset_folder_inventory",
			"Usable Runtime Packs",
			"Reference Only Packs",
			"Reviewed Manifests",
			"No release evidence recorded",
	]:
		if not source.contains(token):
			failures.append("local asset inventory tool missing token: %s" % token)
