extends SceneTree

const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var root := _arg("root")
	if root == "":
		root = "E:/AI/asset"
	var inventory: Dictionary = ReleaseAuditScript.local_asset_folder_inventory(root)
	print("Local Asset Inventory: root=%s exists=%s" % [
		str(inventory.get("root", "")),
		str(inventory.get("root_exists", false)),
	])
	_print_array("Usable Runtime Packs", Array(inventory.get("usable_runtime_packs", [])))
	_print_array("Reference Only Packs", Array(inventory.get("reference_only_packs", [])))
	_print_array("Unknown Packs", Array(inventory.get("unknown_packs", [])))
	print("Reviewed Manifests: %d" % int(inventory.get("reviewed_manifest_count", 0)))
	print("Policy: %s" % str(inventory.get("policy", "")))
	print("No release evidence recorded")
	quit(0)

func _print_array(label: String, values: Array) -> void:
	print("%s: %s" % [label, _join(values)])

func _join(values: Array) -> String:
	var parts: Array[String] = []
	for value in values:
		var text := str(value).strip_edges()
		if text != "" and not parts.has(text):
			parts.append(text)
	if parts.is_empty():
		return "none"
	return ", ".join(parts)

func _arg(name: String) -> String:
	var prefix := "--%s=" % name
	for raw_arg in OS.get_cmdline_user_args():
		var text := str(raw_arg).strip_edges()
		if text.begins_with(prefix):
			return text.trim_prefix(prefix).strip_edges()
	return ""
