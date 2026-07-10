class_name AccessibilitySettings
extends RefCounted

const PATH := "user://accessibility_settings.json"
const DEFAULTS := {
	"master_volume": 1.0,
	"damage_flash_enabled": true,
	"damage_vignette_enabled": true,
	"screen_shake_scale": 1.0,
	"hit_pause_scale": 1.0,
	"high_contrast_cues": false,
}

static func normalized(settings: Dictionary = {}) -> Dictionary:
	return {
		"master_volume": clampf(float(settings.get("master_volume", DEFAULTS["master_volume"])),
			0.0, 1.0),
		"damage_flash_enabled": bool(settings.get(
			"damage_flash_enabled", DEFAULTS["damage_flash_enabled"])),
		"damage_vignette_enabled": bool(settings.get(
			"damage_vignette_enabled",
			settings.get("damage_flash_enabled", DEFAULTS["damage_vignette_enabled"]))),
		"screen_shake_scale": clampf(float(settings.get(
			"screen_shake_scale", DEFAULTS["screen_shake_scale"])), 0.0, 1.0),
		"hit_pause_scale": clampf(float(settings.get(
			"hit_pause_scale", DEFAULTS["hit_pause_scale"])), 0.0, 1.0),
		"high_contrast_cues": bool(settings.get(
			"high_contrast_cues", DEFAULTS["high_contrast_cues"])),
	}

static func load_data(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return DEFAULTS.duplicate(true)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return normalized(parsed if parsed is Dictionary else {})

static func save_data(settings: Dictionary, path: String = PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(normalized(settings), "\t"))
	return true

static func summary(settings: Dictionary = {}) -> String:
	var clean := normalized(settings)
	return "Vol %d%% | Flash %s | Shake %s | Contrast %s" % [
		roundi(float(clean.get("master_volume", 1.0)) * 100.0),
		"On" if bool(clean.get("damage_flash_enabled", true)) else "Off",
		"On" if float(clean.get("screen_shake_scale", 1.0)) > 0.0 else "Off",
		"High" if bool(clean.get("high_contrast_cues", false)) else "Std",
	]
