extends SceneTree

const REQUIRED_MENU_ACTIONS := [
	"menu_prev",
	"menu_next",
	"menu_confirm",
	"menu_back",
]

func _init() -> void:
	var failures: Array[String] = []
	_check_menu_bindings(failures)
	await _check_class_select_menu_actions(failures)
	_check_readiness_menu_contract(failures)
	if failures.is_empty():
		print("Controller menu smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_menu_bindings(failures: Array[String]) -> void:
	for action in REQUIRED_MENU_ACTIONS:
		if not InputMap.has_action(action):
			failures.append("project input map should include %s" % action)
		elif not _action_has_gamepad_button(action):
			failures.append("%s should expose a gamepad button binding" % action)

func _check_class_select_menu_actions(failures: Array[String]) -> void:
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame

	_press_action(screen, "menu_next")
	await process_frame
	if str(screen.get("_selected_class")) != "blade_warden":
		failures.append("menu_next should select the first class when no class is selected")

	_press_action(screen, "menu_prev")
	await process_frame
	if str(screen.get("_selected_class")) != "tinkerer":
		failures.append("menu_prev should wrap from first class to the last class")

	_press_action(screen, "menu_next")
	await process_frame
	if str(screen.get("_selected_class")) != "blade_warden":
		failures.append("menu_next should wrap from last class to the first class")

	_press_action(screen, "route_choice_2")
	await process_frame
	if str(screen.get("_selected_element")) != "ice":
		failures.append("route_choice_2 should select ice on class select")
	_press_action(screen, "route_choice_4")
	await process_frame
	if str(screen.get("_selected_element")) != "poison":
		failures.append("route_choice_4 should select poison on class select")

	var emitted := {"count": 0, "class": "", "element": "", "seed": -2, "mode": ""}
	screen.confirmed.connect(func(class_id: String, element: String, seed: int, mode: String) -> void:
		emitted["count"] = int(emitted["count"]) + 1
		emitted["class"] = class_id
		emitted["element"] = element
		emitted["seed"] = seed
		emitted["mode"] = mode)
	_press_action(screen, "menu_confirm")
	await process_frame
	if int(emitted["count"]) != 1:
		failures.append("menu_confirm should start once class and element are selected")
	if str(emitted["class"]) != "blade_warden" or str(emitted["element"]) != "poison":
		failures.append("menu_confirm should emit selected class and element")
	if str(emitted["mode"]) != "normal":
		failures.append("menu_confirm should preserve selected run mode")

func _check_readiness_menu_contract(failures: Array[String]) -> void:
	var release_audit = load("res://scripts/assets/release_audit.gd")
	var report: Dictionary = release_audit.call("game_readiness_report")
	var controls: Dictionary = Dictionary(report.get("milestones", {})).get("input_controls", {})
	if int(controls.get("menu_gamepad_action_count", 0)) < REQUIRED_MENU_ACTIONS.size():
		failures.append("readiness should count gamepad bindings for menu actions")
	if not bool(controls.get("class_select_gamepad_menu_contract", false)):
		failures.append("readiness should verify class select gamepad menu contract")
	if not bool(controls.get("class_select_gamepad_element_contract", false)):
		failures.append("readiness should verify class select gamepad element contract")

func _press_action(screen: ClassSelectScreen, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	if screen.has_method("_unhandled_input"):
		screen.call("_unhandled_input", event)

func _action_has_gamepad_button(action: String) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return true
	return false
