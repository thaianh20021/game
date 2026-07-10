extends SceneTree

const SETTINGS_PATH := "res://scripts/ui/accessibility_settings.gd"
const TEST_SAVE_PATH := "user://accessibility_settings_smoke.json"
const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_settings_persistence(failures)
	_check_main_persistence_hook(failures)
	_check_readiness_persistence_gate(failures)
	_cleanup_test_file()
	if failures.is_empty():
		print("Accessibility settings persistence smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_settings_persistence(failures: Array[String]) -> void:
	if not ResourceLoader.exists(SETTINGS_PATH):
		failures.append("AccessibilitySettings script should exist")
		return
	var settings_db = load(SETTINGS_PATH)
	if not settings_db.has_method("normalized"):
		failures.append("AccessibilitySettings should expose normalized")
	if not settings_db.has_method("save_data"):
		failures.append("AccessibilitySettings should expose save_data")
	if not settings_db.has_method("load_data"):
		failures.append("AccessibilitySettings should expose load_data")
	if not failures.is_empty():
		return
	var normalized: Dictionary = settings_db.call("normalized", {
		"master_volume": 2.0,
		"damage_flash_enabled": false,
		"damage_vignette_enabled": false,
		"screen_shake_scale": -1.0,
		"hit_pause_scale": 0.7,
		"high_contrast_cues": true,
	})
	if not is_equal_approx(float(normalized.get("master_volume", 0.0)), 1.0):
		failures.append("settings normalization should clamp master volume")
	if float(normalized.get("screen_shake_scale", 1.0)) != 0.0:
		failures.append("settings normalization should clamp screen shake")
	if bool(normalized.get("damage_flash_enabled", true)):
		failures.append("settings normalization should preserve disabled flash")
	if not bool(normalized.get("high_contrast_cues", false)):
		failures.append("settings normalization should preserve high contrast")
	if not settings_db.call("save_data", normalized, TEST_SAVE_PATH):
		failures.append("settings save_data should return true for user path")
	var loaded: Dictionary = settings_db.call("load_data", TEST_SAVE_PATH)
	if loaded != normalized:
		failures.append("settings load_data should roundtrip normalized settings")
	var summary := str(settings_db.call("summary", loaded))
	for token in ["Vol 100%", "Flash Off", "Shake Off", "Contrast High"]:
		if not summary.contains(token):
			failures.append("settings summary missing token %s" % token)

func _check_main_persistence_hook(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("AccessibilitySettingsScript.load_data()"):
		failures.append("Main should load saved accessibility settings")
	if not source.contains("AccessibilitySettingsScript.save_data(_accessibility_settings)"):
		failures.append("Main should save changed accessibility settings")

func _check_readiness_persistence_gate(failures: Array[String]) -> void:
	var release_audit = load(RELEASE_AUDIT_PATH)
	var report: Dictionary = release_audit.call("game_readiness_report")
	var milestones: Dictionary = report.get("milestones", {})
	var settings: Dictionary = milestones.get("settings_accessibility", {})
	if not bool(settings.get("settings_persistence_contract", false)):
		failures.append("readiness should verify settings persistence contract")
	if str(settings.get("settings_save_path", "")) != "user://accessibility_settings.json":
		failures.append("readiness should expose accessibility settings save path")

func _cleanup_test_file() -> void:
	var user_dir := DirAccess.open("user://")
	if user_dir != null and user_dir.file_exists("accessibility_settings_smoke.json"):
		user_dir.remove("accessibility_settings_smoke.json")
