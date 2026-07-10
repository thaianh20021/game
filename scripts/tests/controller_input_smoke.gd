extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"
const REQUIRED_GAMEPAD_ACTIONS := [
	"move_left",
	"move_right",
	"move_up",
	"move_down",
	"dash",
	"attack",
	"swap_weapon",
	"active_reload",
	"skill",
	"skill_alt",
	"cycle_element",
	"ultimate",
	"interact",
	"pause_menu",
	"restart",
	"route_choice_1",
	"route_choice_2",
	"route_choice_3",
	"route_choice_4",
]

func _init() -> void:
	var failures: Array[String] = []
	_check_gamepad_bindings(failures)
	_check_gamepad_hints(failures)
	_check_readiness_gate(failures)
	if failures.is_empty():
		print("Controller input smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_gamepad_bindings(failures: Array[String]) -> void:
	for action in REQUIRED_GAMEPAD_ACTIONS:
		if not InputMap.has_action(action):
			failures.append("project input map should include %s" % action)
		elif not _action_has_gamepad_event(action):
			failures.append("%s should expose a gamepad binding" % action)

func _check_gamepad_hints(failures: Array[String]) -> void:
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	for token in ["Pad:", "LS move", "RB attack", "A dash", "X/Y skills", "RT ultimate"]:
		if not hud_source.contains(token):
			failures.append("HUD controls hint should mention gamepad token %s" % token)
	var select_source := FileAccess.get_file_as_string("res://scripts/ui/class_select.gd")
	for token in ["Pad:", "LS move", "RB attack", "A dash", "X/Y skills", "RT ultimate"]:
		if not select_source.contains(token):
			failures.append("class select controls hint should mention gamepad token %s" % token)

func _check_readiness_gate(failures: Array[String]) -> void:
	var release_audit = load(RELEASE_AUDIT_PATH)
	var report: Dictionary = release_audit.call("game_readiness_report")
	var controls: Dictionary = Dictionary(report.get("milestones", {})).get("input_controls", {})
	if int(controls.get("gamepad_action_count", 0)) < REQUIRED_GAMEPAD_ACTIONS.size():
		failures.append("readiness should count gamepad bindings for all critical actions")
	if not bool(controls.get("hud_gamepad_hint_contract", false)):
		failures.append("readiness should verify HUD gamepad hint contract")
	if not bool(controls.get("onboarding_gamepad_hint_contract", false)):
		failures.append("readiness should verify onboarding gamepad hint contract")

func _action_has_gamepad_event(action: String) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false
