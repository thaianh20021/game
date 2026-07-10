extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"

func _init() -> void:
	var failures: Array[String] = []
	await _check_class_select_settings_controls(failures)
	_check_main_class_select_settings_hook(failures)
	_check_readiness_class_select_settings_gate(failures)
	if failures.is_empty():
		print("Class select accessibility smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_class_select_settings_controls(failures: Array[String]) -> void:
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	var panel := screen.find_child("ClassSelectMainPanel", true, false) as PanelContainer
	if panel == null:
		failures.append("class select should use a fixed main panel instead of fullscreen scrollbars")
	else:
		if panel.anchor_left != 0.0 or panel.anchor_top != 0.0 \
				or panel.anchor_right != 1.0 or panel.anchor_bottom != 1.0:
			failures.append("class select panel should use full-rect anchors with margins")
		var viewport_size := Vector2(
			float(ProjectSettings.get_setting("display/window/size/viewport_width")),
			float(ProjectSettings.get_setting("display/window/size/viewport_height")))
		var expected_size := Vector2(
			viewport_size.x + panel.offset_right - panel.offset_left,
			viewport_size.y + panel.offset_bottom - panel.offset_top)
		if expected_size.x < 560.0 or expected_size.y < 320.0:
			failures.append("class select main panel should fit the 640x360 viewport")
	if screen.has_method("_select_class_by_index"):
		screen.call("_select_class_by_index", 0)
		await process_frame
		var selected_class := screen.find_child("Class_*", true, false) as Button
		if selected_class == null:
			failures.append("class select should expose class buttons")
		elif selected_class.disabled:
			failures.append("selected class button should stay enabled so selection does not look broken")
	var class_scroll := screen.find_child("ClassScroll", true, false) as ScrollContainer
	var class_grid := screen.find_child("ClassGrid", true, false) as GridContainer
	var hub_row := screen.find_child("HubServicesRow", true, false) as HBoxContainer
	var meta_bank := screen.find_child("MetaBankLabel", true, false) as Label
	var start := screen.find_child("StartRunButton", true, false) as Button
	if class_scroll == null or class_grid == null or hub_row == null or meta_bank == null or start == null:
		failures.append("class select should expose class/start/hub/meta controls")
	else:
		if class_grid.columns != 1:
			failures.append("class select should use one stable class column until the two-column layout is rebuilt")
		if class_scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			failures.append("class select should not show a horizontal scrollbar in the class list")
		if class_scroll.custom_minimum_size.x > 420.0:
			failures.append("class list should stay inside the 640x360 viewport")
		var first_button := screen.find_child("Class_*", true, false) as Button
		if first_button != null and first_button.custom_minimum_size.x > 400.0:
			failures.append("class buttons should not stretch offscreen in the 640x360 viewport")
		for node in screen.find_children("Class_*", "Button", true, false):
			var button := node as Button
			if button == null:
				continue
			if button.tooltip_text.contains("\n") or button.tooltip_text.length() > 56:
				failures.append("class button tooltips should stay one-line compact popups")
			if str(button.get_meta("class_tooltip_detail", "")).strip_edges() == "":
				failures.append("class buttons should store full detail in metadata instead of large tooltip popups")
		var title := screen.find_child("ClassSelectTitle", true, false) as Label
		var detail := screen.find_child("ClassDetailPanel", true, false) as PanelContainer
		for control in [title, class_scroll, detail, start]:
			if control == null:
				continue
			var rect := (control as Control).get_global_rect()
			if rect.position.x < 0.0 or rect.end.x > 640.0 or rect.position.y < 0.0 or rect.end.y > 360.0:
				failures.append("%s should fit inside the 640x360 viewport" % (control as Control).name)
		if class_scroll.get_index() > hub_row.get_index() or class_scroll.get_index() > meta_bank.get_index():
			failures.append("class choices should appear before hub/meta controls")
		if start.get_index() > meta_bank.get_index():
			failures.append("start button should appear before meta progression controls")
		if hub_row.visible or meta_bank.visible:
			failures.append("hub/meta controls should be hidden from the primary class-pick screen")
		if screen.has_method("_select_element"):
			screen.call("_select_element", "fire")
			await process_frame
			if start.disabled:
				failures.append("start button should enable after selecting class and element")
	if not _has_signal(screen, "settings_changed"):
		failures.append("class select should expose settings_changed signal")
	var changes: Array[Dictionary] = []
	if _has_signal(screen, "settings_changed"):
		screen.connect("settings_changed", func(settings: Dictionary) -> void:
			changes.append(settings.duplicate(true)))
	if not screen.has_method("apply_accessibility_settings"):
		failures.append("class select should expose apply_accessibility_settings")
	else:
		screen.call("apply_accessibility_settings", {
			"master_volume": 0.8,
			"damage_flash_enabled": true,
			"damage_vignette_enabled": true,
			"screen_shake_scale": 1.0,
			"hit_pause_scale": 1.0,
			"high_contrast_cues": false,
		})
	var summary := screen.find_child("ClassSelectAccessibilitySettings", true, false) as Label
	if summary == null:
		failures.append("class select should expose accessibility settings summary")
	else:
		for token in ["Settings", "Vol 80%", "Flash On", "Shake On", "Contrast Std"]:
			if not summary.text.contains(token):
				failures.append("class select settings summary missing token %s" % token)
		if not summary.has_meta("accessibility_settings"):
			failures.append("class select settings summary should keep settings metadata")
	var flash := screen.find_child("ClassSelectToggleFlash", true, false) as Button
	var shake := screen.find_child("ClassSelectToggleShake", true, false) as Button
	var contrast := screen.find_child("ClassSelectToggleContrast", true, false) as Button
	var volume_down := screen.find_child("ClassSelectVolumeDown", true, false) as Button
	var volume_up := screen.find_child("ClassSelectVolumeUp", true, false) as Button
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
			failures.append("class select settings should create %s button" % pair)
		elif button.tooltip_text.strip_edges() == "":
			failures.append("class select settings %s button should expose tooltip" % pair)
	if flash != null:
		flash.emit_signal("pressed")
		await process_frame
		if changes.is_empty() or bool(changes[-1].get("damage_flash_enabled", true)):
			failures.append("class select flash toggle should emit disabled flash setting")
	if shake != null:
		shake.emit_signal("pressed")
		await process_frame
		if changes.is_empty() or float(changes[-1].get("screen_shake_scale", 1.0)) > 0.0:
			failures.append("class select shake toggle should emit disabled shake setting")
	if contrast != null:
		contrast.emit_signal("pressed")
		await process_frame
		if changes.is_empty() or not bool(changes[-1].get("high_contrast_cues", false)):
			failures.append("class select contrast toggle should emit high contrast setting")
	if volume_down != null:
		volume_down.emit_signal("pressed")
		await process_frame
		if changes.is_empty() or float(changes[-1].get("master_volume", 1.0)) >= 0.8:
			failures.append("class select volume down should lower master volume")
	if volume_up != null:
		volume_up.emit_signal("pressed")
		await process_frame
		if changes.is_empty() or float(changes[-1].get("master_volume", 0.0)) <= 0.0:
			failures.append("class select volume up should emit positive master volume")
	screen.queue_free()
	await process_frame

func _check_main_class_select_settings_hook(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("select.settings_changed.connect(_on_accessibility_settings_changed)"):
		failures.append("Main should listen for class select settings changes")
	if not source.contains("select.apply_accessibility_settings(_accessibility_settings)"):
		failures.append("Main should seed class select with saved accessibility settings")

func _check_readiness_class_select_settings_gate(failures: Array[String]) -> void:
	var release_audit = load(RELEASE_AUDIT_PATH)
	var report: Dictionary = release_audit.call("game_readiness_report")
	var milestones: Dictionary = report.get("milestones", {})
	var settings: Dictionary = milestones.get("settings_accessibility", {})
	if not bool(settings.get("class_select_controls_contract", false)):
		failures.append("readiness should verify class select settings controls")
	if int(settings.get("class_select_settings_control_count", 0)) < 5:
		failures.append("readiness should count class select settings controls")

func _has_signal(node: Object, signal_name: String) -> bool:
	for info in node.get_signal_list():
		if str(info.get("name", "")) == signal_name:
			return true
	return false
