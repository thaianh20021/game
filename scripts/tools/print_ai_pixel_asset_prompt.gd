extends SceneTree

const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var kind := _arg("kind")
	if kind == "":
		kind = "object_visual"
	var asset_id := _arg("asset-id")
	if asset_id == "":
		asset_id = "missing_asset"
	var frame_size := _parse_size(_arg("frame-size"), Vector2(32, 32))
	var frame_count := int(_arg("frame-count"))
	if frame_count <= 0:
		frame_count = 1
	var prompt: Dictionary = ReleaseAuditScript.ai_pixel_asset_prompt(
		kind, asset_id, frame_size, frame_count)
	print("AI Pixel Asset Prompt: %s kind=%s" % [
		str(prompt.get("asset_id", "")),
		str(prompt.get("kind", "")),
	])
	print("Frame Contract: size=%s count=%d" % [
		str(prompt.get("frame_size", Vector2.ZERO)),
		int(prompt.get("frame_count", 0)),
	])
	print("Prompt:")
	print(str(prompt.get("prompt_text", "")))
	_print_array("Manifest Required Fields", Array(prompt.get("manifest_required_fields", [])))
	print("Manifest Path: %s" % str(prompt.get("manifest_path", "")))
	print("Manifest Template:")
	var template: Dictionary = ReleaseAuditScript.ai_pixel_asset_manifest_template(
		kind, asset_id, frame_size, frame_count, str(prompt.get("manifest_path", "")).replace("_manifest.json", ".png"))
	print(JSON.stringify(_json_safe(template), "\t"))
	print("Review Command: %s" % str(prompt.get("review_command", "")))
	print("Release Rule: %s" % str(prompt.get("release_rule", "")))
	print("No release evidence recorded")
	quit(0)

func _parse_size(value: String, fallback: Vector2) -> Vector2:
	var text := value.strip_edges().to_lower().replace(",", "x")
	var parts := text.split("x", false)
	if parts.size() < 2:
		return fallback
	var width := int(parts[0])
	var height := int(parts[1])
	if width <= 0 or height <= 0:
		return fallback
	return Vector2(width, height)

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

func _json_safe(value: Variant) -> Variant:
	if value is Vector2:
		var vec := value as Vector2
		return [vec.x, vec.y]
	if value is Vector2i:
		var vec_i := value as Vector2i
		return [vec_i.x, vec_i.y]
	if value is Array:
		var out: Array = []
		for item in value:
			out.append(_json_safe(item))
		return out
	if value is Dictionary:
		var out_dict := {}
		for key in (value as Dictionary).keys():
			out_dict[key] = _json_safe((value as Dictionary)[key])
		return out_dict
	return value

func _arg(name: String) -> String:
	var prefix := "--%s=" % name
	for raw_arg in OS.get_cmdline_user_args():
		var text := str(raw_arg).strip_edges()
		if text.begins_with(prefix):
			return text.trim_prefix(prefix).strip_edges()
	return ""
