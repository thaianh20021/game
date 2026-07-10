extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"

func _init() -> void:
	var failures: Array[String] = []
	await _check_pause_settings_controls(failures)
	_check_hud_player_settings_contract(failures)
	_check_main_settings_hook(failures)
	_check_readiness_settings_gate(failures)
	if failures.is_empty():
		print("Accessibility settings smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_pause_settings_controls(failures: Array[String]) -> void:
	var overlay := RunOverlay.new()
	root.add_child(overlay)
	await process_frame
	if not _has_signal(overlay, "settings_changed"):
		failures.append("pause overlay should expose settings_changed signal")
	var changes: Array[Dictionary] = []
	if _has_signal(overlay, "settings_changed"):
		overlay.connect("settings_changed", func(settings: Dictionary) -> void:
			changes.append(settings.duplicate(true)))
	overlay.show_pause_menu(1, "Ancient Cave", "None")
	await process_frame
	var summary := overlay.find_child("PauseAccessibilitySettings", true, false) as Label
	if summary == null:
		failures.append("pause overlay should expose accessibility settings summary")
	else:
		for token in ["Settings", "Vol", "Flash", "Shake", "Contrast"]:
			if not summary.text.contains(token):
				failures.append("pause settings summary missing token %s" % token)
		if not summary.has_meta("accessibility_settings"):
			failures.append("pause settings summary should keep settings metadata")
	var flash := overlay.find_child("PauseToggleFlash", true, false) as Button
	var shake := overlay.find_child("PauseToggleShake", true, false) as Button
	var contrast := overlay.find_child("PauseToggleContrast", true, false) as Button
	var volume_down := overlay.find_child("PauseVolumeDown", true, false) as Button
	var volume_up := overlay.find_child("PauseVolumeUp", true, false) as Button
	for pair in {
		"flash": flash,
		"shake": shake,
		"contrast": contrast,
		"volume_down": volume_down,
		"volume_up": volume_up,
	}.keys():
		var button := {
			"flash": flash,
			"shake": shake,
			"contrast": contrast,
			"volume_down": volume_down,
			"volume_up": volume_up,
		}[pair] as Button
		if button == null:
			failures.append("pause settings should create %s button" % pair)
		elif button.tooltip_text.strip_edges() == "":
			failures.append("pause settings %s button should expose tooltip" % pair)
	if flash != null:
		flash.emit_signal("pressed")
		await process_frame
		if changes.is_empty() or bool(changes[-1].get("damage_flash_enabled", true)):
			failures.append("flash toggle should emit settings with damage flash disabled")
	if shake != null:
		shake.emit_signal("pressed")
		await process_frame
		if changes.is_empty() or float(changes[-1].get("screen_shake_scale", 1.0)) > 0.0:
			failures.append("shake toggle should emit settings with screen shake disabled")
	if contrast != null:
		contrast.emit_signal("pressed")
		await process_frame
		if changes.is_empty() or not bool(changes[-1].get("high_contrast_cues", false)):
			failures.append("contrast toggle should emit high contrast cue setting")
	if volume_down != null:
		volume_down.emit_signal("pressed")
		await process_frame
		if changes.is_empty() or float(changes[-1].get("master_volume", 1.0)) >= 1.0:
			failures.append("volume down should emit lower master volume")
	if volume_up != null:
		volume_up.emit_signal("pressed")
		await process_frame
		if changes.is_empty() or float(changes[-1].get("master_volume", 0.0)) <= 0.0:
			failures.append("volume up should emit clamped positive master volume")
	overlay.queue_free()
	await process_frame

func _check_hud_player_settings_contract(failures: Array[String]) -> void:
	var hud := HUD.new()
	root.add_child(hud)
	if not hud.has_method("apply_accessibility_settings"):
		failures.append("HUD should expose apply_accessibility_settings")
	else:
		hud.call("apply_accessibility_settings", {
			"damage_flash_enabled": false,
			"damage_vignette_enabled": false,
			"high_contrast_cues": true,
			"master_volume": 0.6,
		})
		if bool(hud.get_meta("damage_flash_enabled", true)):
			failures.append("HUD should store disabled damage flash setting")
		if not bool(hud.get_meta("high_contrast_cues", false)):
			failures.append("HUD should store high contrast cue setting")
	hud.queue_free()
	var player := Player.new()
	root.add_child(player)
	if not player.has_method("apply_accessibility_settings"):
		failures.append("Player should expose apply_accessibility_settings")
	else:
		player.call("apply_accessibility_settings", {
			"screen_shake_scale": 0.0,
			"hit_pause_scale": 0.75,
		})
		if float(player.get_meta("screen_shake_scale", 1.0)) > 0.0:
			failures.append("Player should store disabled screen shake setting")
		if float(player.get_meta("hit_pause_accessibility_scale", 1.0)) > 0.75:
			failures.append("Player should store reduced hit pause setting")
	player.queue_free()

func _check_main_settings_hook(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("settings_changed.connect(_on_accessibility_settings_changed)"):
		failures.append("Main should listen for pause settings changes")
	if not source.contains("func _on_accessibility_settings_changed"):
		failures.append("Main should handle accessibility settings changes")
	if not source.contains("_hud.apply_accessibility_settings"):
		failures.append("Main should apply accessibility settings to HUD")
	if not source.contains("player.apply_accessibility_settings"):
		failures.append("Main should apply accessibility settings to Player")

func _check_readiness_settings_gate(failures: Array[String]) -> void:
	var release_audit = load(RELEASE_AUDIT_PATH)
	var report: Dictionary = release_audit.call("game_readiness_report")
	var milestones: Dictionary = report.get("milestones", {})
	var settings: Dictionary = milestones.get("settings_accessibility", {})
	if settings.is_empty():
		failures.append("readiness should expose settings_accessibility milestone")
	elif not bool(settings.get("ready", false)):
		failures.append("settings_accessibility milestone should be ready")
	if not bool(settings.get("pause_controls_contract", false)):
		failures.append("readiness should verify pause settings controls")
	if not bool(settings.get("hud_settings_contract", false)):
		failures.append("readiness should verify HUD accessibility settings")
	if not bool(settings.get("player_settings_contract", false)):
		failures.append("readiness should verify Player accessibility settings")
	if int(settings.get("settings_control_count", 0)) < 5:
		failures.append("readiness should count pause settings controls")

func _has_signal(node: Object, signal_name: String) -> bool:
	for info in node.get_signal_list():
		if str(info.get("name", "")) == signal_name:
			return true
	return false
