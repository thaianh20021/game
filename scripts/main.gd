extends Node2D
## Game flow: class/element select -> floors 1..MAX_FLOORS -> death/victory
## overlay, R restarts the scene (fresh seed, back to class select).
## Next milestones: hub scene, meta progression save, more bosses/biomes.

const MAX_FLOORS := 4
const DEBUG_WINDOW_SIZE := Vector2i(1280, 720)
const DEBUG_CONTENT_SCALE_SIZE := Vector2i(640, 360)
const DEBUG_CONTENT_SCALE_FACTOR := 1.0
const UpgradeDBScript := preload("res://scripts/progression/upgrade_db.gd")
const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const RunSummaryScript := preload("res://scripts/ui/run_summary.gd")
const RunModifierDBScript := preload("res://scripts/progression/run_modifier_db.gd")
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")
const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")
const AccessibilitySettingsScript := preload("res://scripts/ui/accessibility_settings.gd")

@onready var player: Player = $Player

var run_seed := 0
var _run_mode := "normal"
var _run_modifier: Dictionary = {}
var _run_goal_progress := {}
var current_floor := 1
var run_over := false

var _floor_ctrl: FloorController
var _hud: HUD
var _overlay: RunOverlay
var _pending_upgrades: Array[Dictionary] = []
var _pending_reward_room_id := 0
var _pending_reward_room_type := 0
var _reward_rerolled := false
var _pending_shop: RoomInteractable = null
var _banked_run := false
var _paused_by_menu := false
var _last_floor_summary := ""
var _floor_start_snapshot := {}
var _reward_pick_count := 0
var _reward_skip_count := 0
var _reward_reroll_count := 0
var _shop_buy_count := 0
var _shop_leave_count := 0
var _boss_story_events: Array[String] = []
var _boss_pressure_events: Array[String] = []
var _boss_phase_timing_events: Array[String] = []
var _boss_attack_timing_events: Array[String] = []
var _manual_playtest_overlay_request := {}
var _accessibility_settings := {
	"master_volume": 1.0,
	"damage_flash_enabled": true,
	"damage_vignette_enabled": true,
	"screen_shake_scale": 1.0,
	"hit_pause_scale": 1.0,
	"high_contrast_cues": false,
}


func _ready() -> void:
	_apply_debug_window_scale()
	_accessibility_settings = AccessibilitySettingsScript.load_data()
	player.hide()
	player.set_physics_process(false)
	var select := ClassSelectScreen.new()
	add_child(select)
	select.confirmed.connect(_start_run)
	select.settings_changed.connect(_on_accessibility_settings_changed)
	select.apply_accessibility_settings(_accessibility_settings)
	var launch_request := _manual_playtest_launch_request_from_args(OS.get_cmdline_user_args())
	if not launch_request.is_empty():
		select.queue_free()
		set_meta("manual_playtest_launch_request", launch_request.duplicate(true))
		_start_run(
			str(launch_request.get("class_id", "blade_warden")),
			str(launch_request.get("element", "fire")),
			int(launch_request.get("seed", -1)),
			str(launch_request.get("mode", "normal")))
		_show_manual_playtest_overlay(launch_request)

func _apply_debug_window_scale(dry_run: bool = false) -> Dictionary:
	var state := {
		"window_size": DEBUG_WINDOW_SIZE,
		"content_scale_size": DEBUG_CONTENT_SCALE_SIZE,
		"content_scale_mode": Window.CONTENT_SCALE_MODE_VIEWPORT,
		"content_scale_aspect": Window.CONTENT_SCALE_ASPECT_KEEP,
		"content_scale_factor": DEBUG_CONTENT_SCALE_FACTOR,
		"dry_run": dry_run,
	}
	if dry_run or DisplayServer.get_name() == "headless":
		set_meta("debug_window_scale_state", state.duplicate(true))
		return state
	var window := get_window()
	if window == null:
		state["error"] = "window_missing"
		set_meta("debug_window_scale_state", state.duplicate(true))
		return state
	window.content_scale_size = DEBUG_CONTENT_SCALE_SIZE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_factor = DEBUG_CONTENT_SCALE_FACTOR
	window.size = DEBUG_WINDOW_SIZE
	DisplayServer.window_set_size(DEBUG_WINDOW_SIZE)
	set_meta("debug_window_scale_state", state.duplicate(true))
	return state

func _manual_playtest_launch_request_from_args(args: Array) -> Dictionary:
	var scenario_index := _manual_playtest_arg_int(args, "--manual-scenario=")
	if scenario_index <= 0:
		scenario_index = _manual_playtest_arg_int(args, "--scenario-index=")
	if scenario_index <= 0:
		return {}
	var scenarios := Array(ReleaseAuditScript.manual_playtest_checklist().get("scenario_runs", []))
	var scenario_offset := scenario_index - 1
	if scenario_offset < 0 or scenario_offset >= scenarios.size() \
			or not (scenarios[scenario_offset] is Dictionary):
		return {}
	var scenario: Dictionary = scenarios[scenario_offset]
	var request := {
		"seed": int(scenario.get("seed", 0)),
		"mode": str(scenario.get("mode", "")),
		"class_id": str(scenario.get("class_id", "")),
		"goal": str(scenario.get("goal", "")),
		"element": _manual_playtest_element_from_args(args),
		"source": "manual_scenario_arg",
		"scenario_index": scenario_index,
	}
	if int(request.get("seed", 0)) <= 0 \
			or str(request.get("mode", "")).strip_edges() == "" \
			or str(request.get("class_id", "")).strip_edges() == "":
		return {}
	return request

func _manual_playtest_arg_int(args: Array, prefix: String) -> int:
	var value := _manual_playtest_arg_value(args, prefix)
	return int(value) if value.is_valid_int() else 0

func _manual_playtest_arg_value(args: Array, prefix: String, fallback: String = "") -> String:
	for raw_arg in args:
		var text := str(raw_arg).strip_edges()
		if text.begins_with(prefix):
			var value := text.trim_prefix(prefix).strip_edges()
			return value if value != "" else fallback
	return fallback

func _manual_playtest_element_from_args(args: Array) -> String:
	var element := _manual_playtest_arg_value(args, "--element=", "fire")
	return element if ["fire", "ice", "lightning", "poison"].has(element) else "fire"

func _manual_playtest_overlay_text(request: Dictionary) -> String:
	if request.is_empty():
		return ""
	var scenario_index := int(request.get("scenario_index", 0))
	var screenshot_name := _manual_playtest_overlay_screenshot_path(scenario_index).get_file()
	return "Scenario %d | seed %d | %s | %s | element %s\nGoal: %s\nCheck: anim, collision, wave, HUD | %s\nF2 Capture: %s | %s\nF1 hide | F3 copy | human-only" % [
		scenario_index,
		int(request.get("seed", 0)),
		str(request.get("mode", "")),
		str(request.get("class_id", "")),
		str(request.get("element", "")),
		str(request.get("goal", "")),
		_manual_playtest_overlay_compact_room_context(),
		screenshot_name,
		_manual_playtest_overlay_compact_evidence_hint(request),
	]

func _manual_playtest_overlay_evidence_hint(request: Dictionary) -> String:
	var evidence_seed := run_seed if run_seed > 0 else int(request.get("seed", 0))
	return "screenshot or seed_%d" % evidence_seed if evidence_seed > 0 else "screenshot or seed"

func _manual_playtest_overlay_compact_evidence_hint(request: Dictionary) -> String:
	var evidence_seed := run_seed if run_seed > 0 else int(request.get("seed", 0))
	return "seed_%d" % evidence_seed if evidence_seed > 0 else "seed"

func _manual_playtest_overlay_room_context() -> String:
	if _floor_ctrl == null or not is_instance_valid(_floor_ctrl) or _floor_ctrl.current_room == null:
		return "pending launch"
	var context := {}
	if _floor_ctrl.has_method("current_room_objective_context"):
		context = _floor_ctrl.call("current_room_objective_context")
	var room_id := int(context.get("room_id", _floor_ctrl.current_room.id))
	var room_type := str(context.get("room_type_name", _floor_ctrl.current_room.type_name()))
	var next_action := str(context.get("next_action_text", "")).strip_edges()
	if next_action == "":
		next_action = str(context.get("objective_text", "")).strip_edges()
	var progress := "%d/%d" % [_floor_ctrl.cleared_room_count(), _floor_ctrl.total_room_count()]
	if next_action == "":
		return "%s #%d | rooms %s" % [room_type.capitalize(), room_id, progress]
	return "%s #%d | rooms %s | %s" % [room_type.capitalize(), room_id, progress, next_action]

func _manual_playtest_overlay_compact_room_context() -> String:
	var context := _manual_playtest_overlay_room_context()
	context = context.replace("Entrance", "Ent")
	context = context.replace("Combat", "Fight")
	if context.length() <= 34:
		return context
	return "%s..." % context.left(31)

func _manual_playtest_issue_type_summary() -> String:
	return ReleaseAuditScript.manual_playtest_issue_type_summary()

func _manual_playtest_overlay_asset_review_hints() -> String:
	var polygon: Dictionary = ReleaseAuditScript.manual_playtest_issue_remediation(
		"polygon_collision")
	var animation: Dictionary = ReleaseAuditScript.manual_playtest_issue_remediation(
		"asset_animation")
	var missing: Dictionary = ReleaseAuditScript.manual_playtest_issue_remediation(
		"missing_asset_source")
	return "Asset Review: polygon %s | animation %s | vfx %s | audio %s | missing asset %s" % [
		str(polygon.get("asset_review_command", "")),
		str(animation.get("asset_review_command", "")),
		str(ReleaseAuditScript.asset_review_commands().get("vfx_checklist", "")),
		str(ReleaseAuditScript.asset_review_commands().get("audio_checklist", "")),
		str(missing.get("asset_review_command", "")),
	]

func _manual_playtest_overlay_notes_skeleton() -> String:
	return "asset_animation_notes=<human animation notes> | polygon_collision_notes=<human polygon notes> | wave_hud_audio_notes=<human wave hud audio notes>"

func _manual_playtest_overlay_screenshot_path(scenario_index: int) -> String:
	var temp_dir := OS.get_environment("TEMP")
	if temp_dir.strip_edges() == "":
		temp_dir = OS.get_environment("TMP")
	if temp_dir.strip_edges() == "":
		temp_dir = ProjectSettings.globalize_path("user://")
	temp_dir = temp_dir.replace("\\", "/")
	while temp_dir.ends_with("/"):
		temp_dir = temp_dir.substr(0, temp_dir.length() - 1)
	return "%s/dungeon_core_manual_scenario_%d.png" % [temp_dir, scenario_index]

func _manual_playtest_overlay_capture_command(scenario_index: int) -> String:
	var path := _manual_playtest_overlay_screenshot_path(scenario_index).replace("'", "''")
	return "powershell -NoProfile -ExecutionPolicy Bypass -Command \"Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $bounds.Width,$bounds.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size); $bmp.Save('%s',[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); Write-Output '%s'\"" % [path, path]

func _capture_manual_playtest_screenshot(dry_run: bool = false) -> Dictionary:
	var scenario_index := int(_manual_playtest_overlay_request.get("scenario_index", 0))
	var path := _manual_playtest_overlay_screenshot_path(scenario_index)
	var result := {
		"path": path,
		"dry_run": dry_run,
		"saved": false,
		"records_release_evidence": false,
		"policy": "human_only_no_auto_evidence",
	}
	if scenario_index <= 0:
		result["error"] = "manual_scenario_missing"
		_update_manual_capture_metadata(result)
		return result
	if dry_run:
		_update_manual_capture_metadata(result)
		return result
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		result["error"] = "viewport_image_empty"
		_update_manual_capture_metadata(result)
		_show_manual_capture_feedback(result)
		return result
	var dir_error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if dir_error != OK:
		result["error"] = "mkdir_failed:%d" % dir_error
		_update_manual_capture_metadata(result)
		_show_manual_capture_feedback(result)
		return result
	var save_error := image.save_png(path)
	if save_error != OK:
		result["error"] = "save_failed:%d" % save_error
	else:
		result["saved"] = true
	_update_manual_capture_metadata(result)
	_show_manual_capture_feedback(result)
	return result

func _update_manual_capture_metadata(result: Dictionary) -> void:
	var label := find_child("ManualPlaytestScenarioLabel", true, false) as Label
	if label == null:
		return
	label.set_meta("manual_last_capture_path", str(result.get("path", "")))
	label.set_meta("manual_last_capture_saved", bool(result.get("saved", false)))
	label.set_meta("manual_last_capture_dry_run", bool(result.get("dry_run", false)))
	label.set_meta("manual_last_capture_error", str(result.get("error", "")))

func _show_manual_capture_feedback(result: Dictionary) -> void:
	var path := str(result.get("path", ""))
	var saved := bool(result.get("saved", false))
	var text := "Screenshot saved | %s" % path.get_file() if saved \
		else "Screenshot failed | F2"
	_show_floating_toast(
		"ManualScenarioCaptureToast",
		text,
		Vector2(22, 154),
		Color(0.72, 1.0, 0.82) if saved else Color(1.0, 0.56, 0.36),
		result)

func _copy_manual_playtest_record_command(dry_run: bool = false) -> Dictionary:
	var scenario_index := int(_manual_playtest_overlay_request.get("scenario_index", 0))
	var path := _manual_playtest_overlay_screenshot_path(scenario_index)
	var command := _manual_playtest_overlay_pass_command(scenario_index)
	if scenario_index > 0:
		command = command.replace("<screenshot or seed>", path)
	var result := {
		"command": command,
		"path": path,
		"dry_run": dry_run,
		"copied": false,
		"records_release_evidence": false,
		"policy": "human_only_no_auto_evidence",
	}
	if scenario_index <= 0:
		result["error"] = "manual_scenario_missing"
		_update_manual_copy_metadata(result)
		return result
	if not dry_run:
		DisplayServer.clipboard_set(command)
		result["copied"] = true
		_show_manual_copy_feedback(result)
	_update_manual_copy_metadata(result)
	return result

func _update_manual_copy_metadata(result: Dictionary) -> void:
	var label := find_child("ManualPlaytestScenarioLabel", true, false) as Label
	if label == null:
		return
	label.set_meta("manual_last_copied_command", str(result.get("command", "")))
	label.set_meta("manual_last_copy_dry_run", bool(result.get("dry_run", false)))
	label.set_meta("manual_last_copy_copied", bool(result.get("copied", false)))
	label.set_meta("manual_last_copy_error", str(result.get("error", "")))

func _show_manual_copy_feedback(result: Dictionary) -> void:
	_show_floating_toast(
		"ManualScenarioCopyToast",
		"Record command copied | human notes required",
		Vector2(22, 154),
		Color(0.72, 1.0, 0.82),
		result)

func _manual_playtest_overlay_final_notes_command(request: Dictionary) -> String:
	return "godot --headless --path . --script res://scripts/tools/record_playtest_notes_evidence.gd -- --seed=%d --class_id=%s --mode=%s --replay_last_run_result=<human result> --daily_fingerprint_hash=<daily hash> --pace_avg_sec=<avg sec> --pace_boss_sec=<boss sec> --asset_animation_notes=<human animation notes> --polygon_collision_notes=<human polygon notes> --wave_hud_audio_notes=<human wave hud audio notes> --blocker_screenshot_or_seed=<screenshot or seed> --release_decision=<hold or ready>" % [
		int(request.get("seed", 0)),
		str(request.get("class_id", "")),
		str(request.get("mode", "")),
	]

func _manual_playtest_overlay_pass_command(scenario_index: int) -> String:
	return "godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=%d --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>" % scenario_index

func _manual_playtest_overlay_issue_command(scenario_index: int) -> String:
	return "godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=%d --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=<screenshot or seed>" % scenario_index

func _manual_playtest_overlay_resolve_command(scenario_index: int) -> String:
	return "godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=%d --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=<screenshot or seed>" % scenario_index

func _show_manual_playtest_overlay(request: Dictionary) -> void:
	_manual_playtest_overlay_request = request.duplicate(true)
	if _hud != null and _hud.has_method("set_clean_playtest_mode"):
		_hud.call("set_clean_playtest_mode", true)
	var text := _manual_playtest_overlay_text(request)
	if text == "":
		return
	var layer := get_node_or_null("ManualPlaytestScenarioLayer") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "ManualPlaytestScenarioLayer"
		layer.layer = 42
		add_child(layer)
	var label := layer.get_node_or_null("ManualPlaytestScenarioLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "ManualPlaytestScenarioLabel"
		label.position = Vector2(154, 64)
		label.size = Vector2(304, 78)
		label.scale = Vector2(0.5, 0.5)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 7)
		label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.62))
		label.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.01, 1.0))
		label.add_theme_constant_override("outline_size", 4)
		layer.add_child(label)
	label.text = text
	label.visible = false
	label.set_meta("manual_scenario_index", int(request.get("scenario_index", 0)))
	label.set_meta("manual_scenario_seed", int(request.get("seed", 0)))
	label.set_meta("manual_scenario_mode", str(request.get("mode", "")))
	label.set_meta("manual_scenario_class_id", str(request.get("class_id", "")))
	label.set_meta("manual_scenario_element", str(request.get("element", "")))
	label.set_meta("manual_scenario_goal", str(request.get("goal", "")))
	label.set_meta("manual_scenario_evidence_source", "manual_playtest")
	label.set_meta("manual_overlay_toggle_key", "F1")
	label.set_meta("manual_capture_key", "F2")
	label.set_meta("manual_copy_key", "F3")
	label.set_meta("records_release_evidence", false)
	label.set_meta("manual_asset_review_hints", _manual_playtest_overlay_asset_review_hints())
	label.set_meta("manual_evidence_notes_skeleton", _manual_playtest_overlay_notes_skeleton())
	label.set_meta("manual_issue_type_summary", _manual_playtest_issue_type_summary())
	label.set_meta("manual_issue_alias_summary", ReleaseAuditScript.manual_playtest_issue_type_alias_summary())
	label.set_meta("manual_screenshot_path", _manual_playtest_overlay_screenshot_path(int(request.get("scenario_index", 0))))
	label.set_meta("manual_capture_command", _manual_playtest_overlay_capture_command(int(request.get("scenario_index", 0))))
	label.set_meta("manual_recording_policy", "human_only_no_auto_evidence")
	label.set_meta("manual_final_notes_command", _manual_playtest_overlay_final_notes_command(request))
	label.set_meta("manual_pass_command", _manual_playtest_overlay_pass_command(int(request.get("scenario_index", 0))))
	label.set_meta("manual_issue_command", _manual_playtest_overlay_issue_command(int(request.get("scenario_index", 0))))
	label.set_meta("manual_resolve_command", _manual_playtest_overlay_resolve_command(int(request.get("scenario_index", 0))))

func _toggle_manual_playtest_overlay() -> void:
	var label := find_child("ManualPlaytestScenarioLabel", true, false) as Label
	if label != null:
		if not label.visible and not _manual_playtest_overlay_request.is_empty():
			label.text = _manual_playtest_overlay_text(_manual_playtest_overlay_request)
		label.visible = not label.visible


func _start_run(class_id: String, element: String, selected_seed: int = -1, run_mode: String = "normal") -> void:
	run_seed = selected_seed if selected_seed > 0 else randi()
	_run_mode = _normalized_run_mode(run_mode)
	_run_modifier = _modifier_for_run(run_seed, _run_mode)
	_banked_run = false
	_reset_run_decision_counts()
	_run_goal_progress = RunModifierDBScript.initial_goal_progress(_run_modifier)
	print("=== New run | seed %d | mode %s ===" % [run_seed, _run_mode])

	player.apply_class(
		PlayerClassDB.get_class_data(class_id),
		element,
		WeaponDB.starter_weapon_for_class(class_id))
	var meta := MetaProgressionScript.load_data()
	player.apply_meta_bonuses(meta)
	player.show()
	player.set_physics_process(true)
	player.died.connect(_on_player_died)

	_floor_ctrl = FloorController.new()
	add_child(_floor_ctrl)
	move_child(_floor_ctrl, 0)
	_floor_ctrl.floor_completed.connect(_on_floor_completed)
	_floor_ctrl.room_reward_pending.connect(_on_room_reward_pending)
	_floor_ctrl.room_mastery_awarded.connect(_on_room_mastery_awarded)
	_floor_ctrl.shop_choice_requested.connect(_on_shop_choice_requested)
	_floor_ctrl.boss_phase_changed.connect(_on_boss_phase_changed)
	_floor_ctrl.boss_attack_cued.connect(_on_boss_attack_cued)
	_floor_ctrl.route_choice_requested.connect(_on_route_choice_requested)
	_floor_ctrl.start(run_seed, current_floor, player, _run_mode, _run_modifier)
	var biome_mastery_applied := _apply_current_biome_mastery(meta)
	_record_floor_start_snapshot()

	_hud = HUD.new()
	add_child(_hud)
	_hud.bind(player, _floor_ctrl)
	_hud.set_run_seed_label(_run_seed_context_label())
	_hud.set_run_seed(run_seed)
	_hud.set_run_mode(_run_mode_label())
	_hud.set_run_modifier(_run_modifier)
	_hud.set_run_modifier_goals(_run_goal_progress_summary(), _run_goal_progress)
	_hud.show_meta_bonus_summary(
		MetaProgressionScript.active_bonus_summary(meta, _floor_ctrl.current_biome), meta)
	_apply_accessibility_settings_to_runtime()
	if biome_mastery_applied:
		_show_current_biome_mastery_feedback()

	_overlay = RunOverlay.new()
	add_child(_overlay)
	_overlay.upgrade_chosen.connect(_on_upgrade_chosen)
	_overlay.reward_skipped.connect(_on_upgrade_reward_skipped)
	_overlay.reward_reroll_requested.connect(_on_upgrade_reward_reroll_requested)
	_overlay.shop_choice_chosen.connect(_on_shop_choice_chosen)
	_overlay.resume_requested.connect(_on_pause_resume_requested)
	_overlay.restart_requested.connect(_on_pause_restart_requested)
	_overlay.class_select_requested.connect(_on_class_select_requested)
	_overlay.settings_changed.connect(_on_accessibility_settings_changed)
	_overlay.apply_accessibility_settings(_accessibility_settings)
	_show_floor_transition_card(true)

func boot_status() -> Dictionary:
	var player_ready := player != null and is_instance_valid(player) \
		and player.visible and player.is_physics_processing()
	var floor_ready := _floor_ctrl != null and is_instance_valid(_floor_ctrl) \
		and _floor_ctrl.current_room != null and _floor_ctrl.total_room_count() > 0
	return {
		"run_started": player_ready and floor_ready,
		"player_ready": player_ready,
		"floor_ready": floor_ready,
		"hud_ready": _hud != null and is_instance_valid(_hud),
		"overlay_ready": _overlay != null and is_instance_valid(_overlay),
		"class_id": player.class_id if player != null else "",
		"element": player.equipped_element if player != null else "",
		"seed": run_seed,
		"floor": current_floor,
		"release_decision": ReleaseAuditScript.public_release_decision(),
		"first_run_readiness": _first_run_readiness_status(player_ready, floor_ready),
	}

func _first_run_readiness_status(player_ready: bool, floor_ready: bool) -> Dictionary:
	var objective_label := _hud.get_node_or_null("ObjectiveNextActionLabel") as Label \
		if _hud != null and is_instance_valid(_hud) else null
	var route_label := _hud.get_node_or_null("RunRouteLabel") as Label \
		if _hud != null and is_instance_valid(_hud) else null
	var controls_label := _hud.get_node_or_null("ControlsHintLabel") as Label \
		if _hud != null and is_instance_valid(_hud) else null
	var seed_label := _hud.get_node_or_null("RunSeedLabel") as Label \
		if _hud != null and is_instance_valid(_hud) else null
	var mode_label := _hud.get_node_or_null("RunModeLabel") as Label \
		if _hud != null and is_instance_valid(_hud) else null
	var route_options: Array = _floor_ctrl.call("current_room_route_options") \
		if floor_ready and _floor_ctrl.has_method("current_room_route_options") else []
	var route_summary := str(_floor_ctrl.call("current_room_route_options_summary")) \
		if floor_ready and _floor_ctrl.has_method("current_room_route_options_summary") else ""
	var objective_text := str(objective_label.text).strip_edges() if objective_label != null else ""
	var visible_control_hint_text := str(controls_label.text).strip_edges() \
		if controls_label != null else ""
	var control_hint_text := ""
	if controls_label != null:
		control_hint_text = str(controls_label.get_meta(
			"full_control_hint",
			controls_label.tooltip_text if controls_label.tooltip_text != "" else visible_control_hint_text
		)).strip_edges()
	var mode_text := str(mode_label.text).strip_edges() if mode_label != null else _run_mode_label()
	var readiness := {
		"player_ready": player_ready,
		"floor_ready": floor_ready,
		"hud_ready": _hud != null and is_instance_valid(_hud),
		"objective_visible": objective_label != null and objective_text != "",
		"objective_text": objective_text,
		"next_action_key": str(objective_label.get_meta("next_action_key", "")) \
			if objective_label != null else "",
		"route_options_count": route_options.size(),
		"route_options_summary": route_summary,
		"route_label_text": str(route_label.text).strip_edges() if route_label != null else "",
		"control_hint_visible": controls_label != null and controls_label.visible \
			and visible_control_hint_text != "",
		"control_hint_text": control_hint_text,
		"run_seed": int(seed_label.get_meta("run_seed", run_seed)) if seed_label != null else run_seed,
		"run_seed_label": str(seed_label.get_meta("run_seed_label", "Seed")) \
			if seed_label != null else _run_seed_context_label(),
		"run_mode": mode_text,
	}
	readiness["ready"] = bool(readiness["player_ready"]) \
		and bool(readiness["floor_ready"]) \
		and bool(readiness["hud_ready"]) \
		and bool(readiness["objective_visible"]) \
		and int(readiness["route_options_count"]) > 0 \
		and bool(readiness["control_hint_visible"]) \
		and int(readiness["run_seed"]) > 0 \
		and str(readiness["run_mode"]) != ""
	return readiness


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F1:
			_toggle_manual_playtest_overlay()
			get_viewport().set_input_as_handled()
			return
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F2:
			if not _manual_playtest_overlay_request.is_empty():
				_capture_manual_playtest_screenshot()
				get_viewport().set_input_as_handled()
				return
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F3:
			if not _manual_playtest_overlay_request.is_empty():
				_copy_manual_playtest_record_command()
				get_viewport().set_input_as_handled()
				return
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F4:
			_toggle_clean_playtest_hud()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("pause_menu"):
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if run_over and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if _handle_route_choice_input(event):
		get_viewport().set_input_as_handled()

func _toggle_clean_playtest_hud() -> void:
	if _hud == null or not is_instance_valid(_hud) \
			or not _hud.has_method("set_clean_playtest_mode"):
		return
	var enabled := not bool(_hud.get_meta("clean_playtest_mode", false))
	_hud.call("set_clean_playtest_mode", enabled)
	set_meta("clean_playtest_hud_enabled", enabled)
	set_meta("clean_playtest_hud_toggle_key", "F4")

func _handle_route_choice_input(event: InputEvent) -> bool:
	for i in range(1, 5):
		var action := "route_choice_%d" % i
		if event.is_action_pressed(action):
			return _request_route_choice(i, "hotkey")
	return false

func _on_route_choice_requested(choice_index: int) -> void:
	_request_route_choice(choice_index, "door_marker")

func _request_route_choice(choice_index: int, request_source: String) -> bool:
	if run_over or _floor_ctrl == null or not is_instance_valid(_floor_ctrl):
		return false
	if _overlay != null and (_overlay.visible or not _pending_upgrades.is_empty() or _pending_shop != null):
		return false
	var result: Dictionary = _floor_ctrl.call("choose_current_route", choice_index, request_source)
	if bool(result.get("accepted", false)):
		player.record_room_decision("Route", str(result.get("summary", "")))
		_show_route_choice_accepted_feedback(result)
	else:
		_show_route_choice_feedback(result)
	return true

func _show_route_choice_accepted_feedback(result: Dictionary) -> void:
	var summary := str(result.get("summary", "")).strip_edges()
	if summary == "":
		summary = "next room"
	_show_floating_toast(
		"RouteChoiceAcceptedToast",
		"Entering %s" % summary,
		Vector2(22, 136),
		Color(0.72, 1.0, 0.82),
		{
			"route_choice_feedback_kind": "accepted",
			"route_choice_index": int(result.get("choice_index", 0)),
			"request_source": str(result.get("request_source", "")),
			"from_room_id": int(result.get("from_room_id", -1)),
			"to_room_id": int(result.get("to_room_id", -1)),
			"route_summary": summary,
		})
	_play_route_choice_accepted_sfx(result)

func _show_route_choice_feedback(result: Dictionary) -> void:
	var reason := str(result.get("blocked_reason", "blocked"))
	_show_floating_toast(
		"RouteChoiceFeedbackToast",
		_route_choice_blocked_text(reason),
		Vector2(22, 136),
		Color(1.0, 0.82, 0.38),
		{
			"route_choice_feedback_kind": "blocked",
			"blocked_reason": reason,
			"route_choice_index": int(result.get("choice_index", 0)),
			"route_option_count": int(result.get("option_count", 0)),
		})
	_play_route_choice_blocked_sfx(result, reason)

func _play_route_choice_blocked_sfx(result: Dictionary, reason: String) -> void:
	var cue: Dictionary = AudioCueDBScript.objective_blocked_cue(reason)
	var sfx := get_node_or_null("RouteChoiceBlockedSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "RouteChoiceBlockedSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("route_choice_sound_id", str(cue.get("id", "objective_blocked")))
	sfx.set_meta("blocked_reason", reason)
	sfx.set_meta("route_choice_index", int(result.get("choice_index", 0)))
	sfx.set_meta("route_option_count", int(result.get("option_count", 0)))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "blocked")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "objective_blocked")))
	sfx.set_meta("route_choice_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _play_route_choice_accepted_sfx(result: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.objective_complete_cue("Route accepted")
	var sfx := get_node_or_null("RouteChoiceAcceptedSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "RouteChoiceAcceptedSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("route_choice_sound_id", str(cue.get("id", "objective_complete")))
	sfx.set_meta("route_choice_index", int(result.get("choice_index", 0)))
	sfx.set_meta("request_source", str(result.get("request_source", "")))
	sfx.set_meta("to_room_id", int(result.get("to_room_id", -1)))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "objective")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "objective_complete")))
	sfx.set_meta("route_choice_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _route_choice_blocked_text(reason: String) -> String:
	match reason:
		"room_locked":
			return "Route locked | Clear room first"
		"reward_unclaimed":
			return "Pick reward first"
		"invalid_choice":
			return "No route in that slot"
		"transitioning":
			return "Entering room..."
	return "Route unavailable"


func _on_floor_completed() -> void:
	if run_over:
		return
	_last_floor_summary = _floor_delta_summary()
	current_floor += 1
	if current_floor > _run_floor_cap() and not _run_continues_after_floor_cap():
		run_over = true
		_disable_player()
		var rewards := player.run_rewards()
		rewards = _run_rewards_for_banking(current_floor - 1)
		var meta := _bank_run_rewards("victory", current_floor - 1, rewards)
		_overlay.show_message("RUN COMPLETE!",
			RunSummaryScript.end_message("victory", current_floor - 1,
				rewards, meta, _run_summary_context()))
		return
	print("--- Descending to floor %d ---" % current_floor)
	_floor_ctrl.start(run_seed, current_floor, player, _run_mode, _run_modifier)
	if _apply_current_biome_mastery(MetaProgressionScript.load_data()):
		_show_current_biome_mastery_feedback()
	_record_floor_start_snapshot()
	_show_floor_transition_card(false)

func _apply_current_biome_mastery(meta: Dictionary) -> bool:
	if player == null or _floor_ctrl == null:
		return false
	var before_total := float(player.get_meta("biome_mastery_total_bonus", 0.0))
	player.apply_biome_mastery(meta, _floor_ctrl.current_biome)
	return float(player.get_meta("biome_mastery_total_bonus", 0.0)) > before_total

func _show_current_biome_mastery_feedback() -> void:
	if _hud == null or player == null:
		return
	var label := str(player.get_meta("biome_mastery_label", "")).strip_edges()
	var bonus := float(player.get_meta("biome_mastery_bonus", 0.0))
	if label != "" and bonus > 0.0:
		_hud.show_biome_mastery_feedback(label, bonus)

func _on_room_reward_pending(room_id: int, room_type: int) -> void:
	if run_over or _overlay == null:
		return
	_pending_reward_room_id = room_id
	_pending_reward_room_type = room_type
	_reward_rerolled = false
	_pending_upgrades = UpgradeDBScript.roll_available_synergy_room_choices(
		run_seed, room_id, current_floor, room_type, player.upgrade_build_tags(), player)
	player.set_physics_process(false)
	_show_pending_upgrade_choices()

func _on_upgrade_chosen(upgrade_id: String) -> void:
	if run_over:
		return
	var effect_preview := UpgradeDBScript.upgrade_effect_preview(player, upgrade_id)
	var decision_context: Dictionary = _overlay.get_meta("last_reward_decision_context", {}) \
		if _overlay != null else {}
	var decision_reason := _reward_decision_reason(decision_context)
	var applied := UpgradeDBScript.apply_upgrade(
		player,
		upgrade_id,
		decision_reason)
	_pending_upgrades.clear()
	_overlay.hide_overlay()
	if applied:
		_reward_pick_count += 1
		_show_upgrade_taken_feedback(
			UpgradeDBScript.upgrade_name(upgrade_id),
			player.upgrade_stack_count(upgrade_id),
			UpgradeDBScript.upgrade_tags(upgrade_id),
			_upgrade_taken_context(upgrade_id, effect_preview, decision_reason))
		_show_reward_claimed_feedback()
		if _pending_reward_room_type == RoomNode.RoomType.BOSS:
			_show_boss_reward_claimed_feedback()
		_mark_pending_reward_claimed()
	player.set_physics_process(true)

func _reward_decision_reason(context: Dictionary) -> String:
	if _overlay != null:
		var overlay_reason := str(_overlay.get_meta("last_reward_decision_reason", "")).strip_edges()
		if overlay_reason != "":
			return overlay_reason
	var reasons: Array[String] = []
	var raw_reasons: Variant = context.get("fit_reasons", [])
	var reason_items: Array = raw_reasons if raw_reasons is Array else [raw_reasons]
	for raw in reason_items:
		var text := str(raw).strip_edges()
		if text != "" and not reasons.has(text):
			reasons.append(text)
	if str(context.get("synergy_reason", "")).strip_edges() != "" and not reasons.has("Synergy"):
		reasons.append("Synergy")
	if str(context.get("effect_preview", "")).strip_edges() != "" and not reasons.has("Preview"):
		reasons.append("Preview")
	if bool(context.get("best_fit", false)) and not reasons.has("Best Fit"):
		reasons.append("Best Fit")
	return " / ".join(reasons)

func _shop_decision_reason() -> String:
	if _overlay == null:
		return ""
	var reason := str(_overlay.get_meta("last_shop_decision_reason", "")).strip_edges()
	return "" if reason == "Baseline" else reason

func _on_upgrade_reward_skipped(gold: int) -> void:
	if run_over:
		return
	player.add_gold(gold)
	_reward_skip_count += 1
	player.record_room_decision("Reward", "Skipped +%d Gold" % gold)
	_pending_upgrades.clear()
	_overlay.hide_overlay()
	_show_reward_economy_feedback("Skip reward", gold)
	_mark_pending_reward_claimed()
	player.set_physics_process(true)

func _mark_pending_reward_claimed() -> void:
	if _floor_ctrl != null and _floor_ctrl.has_method("mark_room_reward_claimed"):
		_floor_ctrl.call("mark_room_reward_claimed", _pending_reward_room_id)

func _on_upgrade_reward_reroll_requested(cost: int) -> void:
	if run_over or _pending_upgrades.is_empty() or _reward_rerolled:
		return
	if player.gold < cost:
		var missing := maxi(cost - player.gold, 0)
		player.record_room_decision("Reward", "Blocked: Need %d Gold" % missing)
		_show_reward_economy_feedback("Reroll needs %d Gold" % missing, 0, "blocked", {
			"reward_gold_missing": missing,
		})
		return
	player.add_gold(-cost)
	_reward_reroll_count += 1
	player.record_room_decision("Reward", "Rerolled -%d Gold" % cost)
	_show_reward_economy_feedback("Reroll", -cost)
	_pending_upgrades = UpgradeDBScript.reroll_available_synergy_room_choices(
		run_seed,
		_pending_reward_room_id,
		current_floor,
		_pending_reward_room_type,
		_pending_upgrades,
		player.upgrade_build_tags(),
		player)
	_reward_rerolled = true
	_show_pending_upgrade_choices()

func _on_shop_choice_requested(shop: RoomInteractable, choices: Array) -> void:
	if run_over or _overlay == null:
		return
	_pending_shop = shop
	player.set_physics_process(false)
	_overlay.show_shop_choices(choices, player.gold, player.upgrade_build_tags(),
		_shop_weapon_context(), _run_goal_progress_summary(), _run_modifier_bonus_status_summary())

func _on_shop_choice_chosen(index: int) -> void:
	if run_over or _pending_shop == null or not is_instance_valid(_pending_shop):
		return
	if index < 0:
		_pending_shop.skip_shop()
		player.record_room_decision("Shop", _shop_decision_reason())
		_shop_leave_count += 1
		_show_shop_leave_feedback()
	else:
		var choices := _pending_shop.get_shop_choices()
		var choice: Dictionary = choices[index] if index < choices.size() else {}
		if not _pending_shop.buy_choice(index):
			_show_shop_buy_failed_feedback(str(choice.get("name", "Item")), int(choice.get("cost", 0)))
			_overlay.show_shop_choices(_pending_shop.get_shop_choices(), player.gold,
				player.upgrade_build_tags(), _shop_weapon_context(),
				_run_goal_progress_summary(), _run_modifier_bonus_status_summary())
			return # keep pending shop open
		player.record_shop_purchase(str(choice.get("name", "Item")), _shop_decision_reason())
		_show_shop_purchase_feedback(
			str(choice.get("name", "Item")),
			int(choice.get("cost", 0)),
			choice)
		_shop_buy_count += 1
		_advance_run_goal("buy_shop")
	_pending_shop = null
	_overlay.hide_overlay()
	player.set_physics_process(true)


func _toggle_pause_menu() -> void:
	if run_over or _overlay == null:
		return
	if _paused_by_menu:
		_resume_from_pause()
		return
	if _overlay.visible or not _pending_upgrades.is_empty() or _pending_shop != null:
		return
	_paused_by_menu = true
	player.set_physics_process(false)
	var biome := _floor_ctrl.current_biome_label() if _floor_ctrl != null else "Unknown"
	_overlay.apply_accessibility_settings(_accessibility_settings)
	_overlay.show_pause_menu(current_floor, biome,
		player.upgrade_summary(),
		player.upgrade_history_summary(),
		player.upgrade_tag_summary(),
		_pause_run_snapshot(),
		player.rune_socket_summary(),
		player.build_archetype_summary(),
		player.run_power_arc_summary(),
		player.power_milestone_summary(),
		_room_mastery_summary(),
		ReleaseAuditScript.summary_text(),
		ReleaseAuditScript.public_release_decision(),
		_release_audit_replacement_count(),
		_daily_seed_fingerprint_context())

func _pause_run_snapshot() -> String:
	var resource_label := "MP" if player.resource_type == "mana" else "EN"
	var modifier := _run_modifier_summary()
	var goals := _run_goal_progress_summary()
	var route := _room_path_summary()
	var decisions := _run_decision_summary()
	return "%s | %s | Threat %s%s%s | Seed %d | Gold %d | Keys %d | HP %d/%d | %s %.0f/%.0f%s" % [
		_run_mode_label(),
		_run_difficulty_label(),
		_run_threat_label(),
		" | Challenge: %s" % modifier if modifier != "" else "",
		" | %s" % goals if goals != "" else "",
		run_seed,
		player.gold,
		player.silver_keys,
		player.hp,
		player.max_hp,
		resource_label,
		player.resource,
		player.max_resource,
		"%s%s" % [
			" | %s" % route if route != "" and route != "Path: -" else "",
			" | %s" % decisions if decisions != "" else "",
		],
	]

func _on_pause_resume_requested() -> void:
	if _paused_by_menu:
		_resume_from_pause()

func _on_pause_restart_requested() -> void:
	get_tree().reload_current_scene()

func _on_class_select_requested() -> void:
	get_tree().reload_current_scene()

func _on_accessibility_settings_changed(settings: Dictionary) -> void:
	_accessibility_settings = AccessibilitySettingsScript.normalized(settings)
	AccessibilitySettingsScript.save_data(_accessibility_settings)
	_apply_accessibility_settings_to_runtime()

func _apply_accessibility_settings_to_runtime() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.apply_accessibility_settings(_accessibility_settings)
	if player != null and is_instance_valid(player):
		player.apply_accessibility_settings(_accessibility_settings)

func _resume_from_pause() -> void:
	_paused_by_menu = false
	_overlay.hide_overlay()
	player.set_physics_process(true)

func _on_player_died() -> void:
	if run_over:
		return
	run_over = true
	_disable_player()
	var rewards := _run_rewards_for_banking(current_floor)
	var meta := _bank_run_rewards("defeat", current_floor, rewards)
	_overlay.show_message("YOU DIED",
		RunSummaryScript.end_message("defeat", current_floor,
			rewards, meta, _run_summary_context()))


func _upgrade_stack_counts(choices: Array) -> Dictionary:
	var out := {}
	for choice in choices:
		var id := str(choice.get("id", ""))
		if id != "":
			out[id] = player.upgrade_stack_count(id)
	return out

func _upgrade_tag_stack_counts(choices: Array) -> Dictionary:
	var out := {}
	for choice in choices:
		for raw_tag in choice.get("tags", []):
			var tag := str(raw_tag)
			if tag == "" or out.has(tag):
				continue
			out[tag] = player.upgrade_tag_stack_count(tag)
	return out

func _upgrade_effect_previews(choices: Array) -> Dictionary:
	var out := {}
	for choice in choices:
		if not (choice is Dictionary):
			continue
		var id := str((choice as Dictionary).get("id", ""))
		if id == "":
			continue
		var preview := UpgradeDBScript.upgrade_effect_preview(player, id)
		if preview != "":
			out[id] = preview
	return out

func _shop_weapon_context() -> Dictionary:
	if player == null:
		return {}
	var weapon := player.current_weapon()
	if weapon == null:
		return {}
	return weapon.data.duplicate(true)

func _show_pending_upgrade_choices() -> void:
	_overlay.show_room_upgrade_choices(_annotated_pending_upgrades(),
		_pending_reward_room_type,
		_upgrade_stack_counts(_pending_upgrades),
		not _reward_rerolled and player.gold >= RunOverlay.UPGRADE_REROLL_COST,
		player.upgrade_build_tags(),
		_reward_reroll_state(),
		player.upgrade_history_summary(),
		_upgrade_effect_previews(_pending_upgrades),
		player.rune_socket_summary(),
		player.build_archetype_summary(),
		player.run_power_arc_summary(),
		_run_modifier_summary(),
		player.next_power_milestone_hint(),
		_upgrade_tag_stack_counts(_pending_upgrades),
		_run_goal_progress_summary(),
		_run_modifier_bonus_status_summary())

func _reward_reroll_state() -> String:
	if _reward_rerolled:
		return "used"
	if player.gold < RunOverlay.UPGRADE_REROLL_COST:
		return "need_gold"
	return "available"

func _show_upgrade_taken_feedback(
		upgrade_name: String,
		stack_count: int,
		tags: Array = [],
		context: Dictionary = {},
) -> void:
	var build := player.upgrade_summary()
	var archetype := player.build_archetype_summary()
	var rune_socket := player.rune_socket_summary()
	var text := _upgrade_taken_text(upgrade_name, stack_count, tags, build, archetype, rune_socket)
	var effect_preview := str(context.get("effect_preview", ""))
	if effect_preview != "":
		text += " | Preview: %s" % effect_preview
	var decision_reason := str(context.get("decision_reason", "")).strip_edges()
	if decision_reason != "":
		text += " | Reason: %s" % decision_reason
	var room_type_name := str(context.get("room_type_name", ""))
	if room_type_name != "":
		text += " | Room: %s" % room_type_name
	_show_floating_toast(
		"UpgradeTakenToast",
		text,
		Vector2(22, 76),
		Color(0.72, 0.95, 1.0),
		{
			"upgrade_name": upgrade_name,
			"upgrade_stack": stack_count,
			"upgrade_tags": _readable_tags(tags),
			"upgrade_build": build,
			"upgrade_archetype": archetype,
			"upgrade_rune_socket": rune_socket,
			"upgrade_id": str(context.get("upgrade_id", "")),
			"upgrade_effect_preview": effect_preview,
			"upgrade_decision_reason": decision_reason,
			"reward_room_id": int(context.get("room_id", -1)),
			"reward_room_type": int(context.get("room_type", -1)),
			"reward_room_type_name": room_type_name,
		})

func _upgrade_taken_context(upgrade_id: String, effect_preview: String, decision_reason: String = "") -> Dictionary:
	return {
		"upgrade_id": upgrade_id,
		"effect_preview": effect_preview,
		"decision_reason": decision_reason,
		"room_id": _pending_reward_room_id,
		"room_type": _pending_reward_room_type,
		"room_type_name": _reward_room_label(_pending_reward_room_type),
	}

func _upgrade_taken_text(
		upgrade_name: String,
		stack_count: int,
		tags: Array = [],
		build: String = "",
		archetype: String = "",
		rune_socket: String = "",
) -> String:
	var text := "%s x%d" % [upgrade_name, maxi(stack_count, 1)]
	var tag_text := _readable_tags(tags)
	if tag_text != "":
		text += " | Tags: %s" % tag_text
	var build_text := build.strip_edges()
	if build_text != "" and build_text != "None":
		text += " | Build: %s" % build_text
	var archetype_text := archetype.strip_edges()
	if archetype_text != "" and archetype_text != "Fresh Run":
		text += " | Archetype: %s" % archetype_text
	var rune_socket_text := rune_socket.strip_edges()
	if rune_socket_text != "" and rune_socket_text != "None":
		text += " | Rune/Socket: %s" % rune_socket_text
	return text

func _readable_tags(tags: Array) -> String:
	var parts: Array[String] = []
	var seen := {}
	for raw_tag in tags:
		var tag := str(raw_tag)
		if tag == "" or seen.has(tag):
			continue
		seen[tag] = true
		parts.append(tag.replace("_", " ").capitalize())
	return " / ".join(parts)

func _show_reward_claimed_feedback() -> void:
	var build := player.upgrade_summary()
	if build == "":
		build = "No upgrades"
	var tags := player.upgrade_tag_summary()
	if tags == "":
		tags = "None"
	var rune_socket := player.rune_socket_summary()
	if rune_socket == "":
		rune_socket = "None"
	var power_arc := player.run_power_arc_summary()
	var metadata := _reward_claimed_metadata(build, tags, rune_socket, power_arc)
	_show_floating_toast(
		"RewardClaimedToast",
		"Reward claimed | %s | Build: %s | Power Arc: %s | Tags: %s | Rune/Socket: %s" % [
			_reward_room_label(_pending_reward_room_type),
			build,
			power_arc,
			tags,
			rune_socket,
		],
		Vector2(22, 96),
		Color(0.74, 1.0, 0.72),
		metadata)

func _reward_claimed_metadata(
		build: String,
		tags: String,
		rune_socket: String,
		power_arc: String,
) -> Dictionary:
	var metadata := {
		"room_id": _pending_reward_room_id,
		"room_type": _pending_reward_room_type,
		"room_type_name": _reward_room_label(_pending_reward_room_type),
		"reward_build": build,
		"reward_tags": tags,
		"reward_rune_socket": rune_socket,
		"run_power_arc": power_arc,
		"run_power_pick_count": player.upgrade_count(),
		"run_power_tier": player.run_power_tier(),
		"run_power_archetype": player.build_archetype_summary(),
		"run_power_tags": tags,
	}
	if _floor_ctrl != null and _floor_ctrl.has_method("current_room_objective_context"):
		var context: Dictionary = _floor_ctrl.call("current_room_objective_context")
		for key in context.keys():
			metadata[str(key)] = context[key]
	return metadata

func _reward_room_label(room_type: int) -> String:
	if room_type >= 0 and room_type < RoomNode.RoomType.keys().size():
		return str(RoomNode.RoomType.keys()[room_type]).capitalize()
	return "Room"

func _show_boss_reward_claimed_feedback() -> void:
	var finale := _is_run_finale_reward()
	var metadata := _boss_reward_claimed_metadata(finale)
	_show_floating_toast(
		"BossRewardClaimedToast",
		"Final boss reward claimed | Run complete portal ready" if finale \
			else "Boss reward claimed | Portal ready",
		Vector2(22, 116),
		Color(1.0, 0.86, 0.42) if finale else Color(1.0, 0.72, 0.92),
		metadata)

func _boss_reward_claimed_metadata(finale: bool) -> Dictionary:
	var metadata := {
		"run_finale": finale,
		"room_id": _pending_reward_room_id,
		"room_type": _pending_reward_room_type,
		"room_type_name": _reward_room_label(_pending_reward_room_type),
	}
	if _floor_ctrl != null and _floor_ctrl.has_method("current_room_objective_context"):
		var context: Dictionary = _floor_ctrl.call("current_room_objective_context")
		for key in context.keys():
			metadata[str(key)] = context[key]
	return metadata

func _is_run_finale_reward() -> bool:
	if _floor_ctrl == null:
		return false
	if _run_mode != "normal":
		return false
	return bool(_floor_ctrl.current_biome.get("run_finale", false))

func _show_shop_purchase_feedback(item_name: String, cost: int, choice: Dictionary = {}) -> void:
	var metadata := _shop_purchase_metadata(item_name, cost, choice)
	_show_floating_toast(
		"ShopPurchaseToast",
		_shop_purchase_text(item_name, cost, metadata),
		Vector2(22, 96),
		Color(1.0, 0.82, 0.36),
		metadata)

func _shop_purchase_text(item_name: String, cost: int, metadata: Dictionary) -> String:
	var text := "Bought %s | -%d Gold" % [item_name, cost]
	var tags := str(metadata.get("shop_choice_tags", ""))
	if tags != "" and tags != "None":
		text += " | Tags: %s" % tags
	var recommendation := str(metadata.get("shop_recommendation", ""))
	if recommendation != "":
		text += " | Recommended: %s" % recommendation
	text += " | Fit: %d%% | %s" % [
		int(metadata.get("shop_fit_score", 0)),
		str(metadata.get("shop_fit_reasons", "Baseline")),
	]
	var comparison := str(metadata.get("shop_weapon_comparison", ""))
	if comparison != "":
		text += " | %s" % comparison
	return text

func _shop_purchase_metadata(item_name: String, cost: int, choice: Dictionary) -> Dictionary:
	var reward: Dictionary = {}
	var raw_reward: Variant = choice.get("reward", {})
	if raw_reward is Dictionary:
		reward = raw_reward as Dictionary
	var tags := _readable_tags(_choice_tag_array(choice))
	if tags == "":
		tags = "None"
	var recommendation := _shop_purchase_recommendation(choice)
	var comparison := _shop_purchase_weapon_comparison(choice)
	var fit_reasons := _shop_purchase_fit_reasons(choice, recommendation, comparison)
	return {
		"shop_item_name": item_name,
		"shop_cost": cost,
		"shop_choice_rarity": str(choice.get("rarity", "")),
		"shop_choice_category": str(choice.get("category", "")),
		"shop_choice_tags": tags,
		"shop_reward_type": str(reward.get("type", "")),
		"shop_reward_id": str(reward.get("id", "")),
		"shop_recommendation": recommendation,
		"shop_weapon_comparison": comparison,
		"shop_fit_score": _shop_purchase_fit_score(choice, recommendation, comparison),
		"shop_fit_reasons": _readable_list(fit_reasons),
	}

func _shop_purchase_recommendation(choice: Dictionary) -> String:
	var explicit := str(choice.get("recommendation", ""))
	if explicit != "":
		return explicit
	if player == null or not player.has_method("upgrade_build_tags"):
		return ""
	var build_tags: Array = player.call("upgrade_build_tags")
	var choice_tags := _choice_tag_array(choice)
	var matches: Array = []
	for raw_tag in choice_tags:
		var tag := str(raw_tag)
		if tag != "" and build_tags.has(tag):
			matches.append(tag)
	return _readable_tags(matches)

func _shop_purchase_weapon_comparison(choice: Dictionary) -> String:
	var explicit := str(choice.get("weapon_comparison", ""))
	if explicit != "":
		return explicit
	var reward: Dictionary = choice.get("reward", {})
	if str(reward.get("type", "")) != "weapon":
		return ""
	var new_weapon := WeaponDB.get_weapon(str(reward.get("id", "")))
	if new_weapon.is_empty() or player == null or not player.has_method("current_weapon"):
		return ""
	var current := player.current_weapon()
	if current == null:
		return ""
	var current_weapon := current.data
	var parts: Array[String] = [
		"Dmg %s" % _signed_delta(int(new_weapon.get("dmg", 0)) - int(current_weapon.get("dmg", 0))),
		"Speed %s" % _signed_delta(int(new_weapon.get("speed", 0)) - int(current_weapon.get("speed", 0))),
		"Range %s" % _signed_delta(int(new_weapon.get("range", 0)) - int(current_weapon.get("range", 0))),
		"Sockets %s" % _signed_delta(int(new_weapon.get("sockets", 0)) - int(current_weapon.get("sockets", 0))),
	]
	return "Vs %s: %s" % [str(current_weapon.get("name", "Current")), " / ".join(parts)]

func _shop_purchase_fit_score(choice: Dictionary, recommendation: String, comparison: String) -> int:
	var score := 35
	if recommendation.strip_edges() != "":
		score += 46
	score += _shop_purchase_rarity_bonus(str(choice.get("rarity", "common")))
	if comparison.strip_edges() != "":
		score += 5
	if str(choice.get("disabled_reason", "")).strip_edges() != "":
		score -= 45
	return clampi(score, 0, 100)

func _shop_purchase_fit_reasons(choice: Dictionary, recommendation: String, comparison: String) -> Array[String]:
	var reasons: Array[String] = []
	if str(choice.get("disabled_reason", "")).strip_edges() != "":
		reasons.append("Blocked")
	if recommendation.strip_edges() != "":
		reasons.append("Build match")
	var rarity := str(choice.get("rarity", "common"))
	if rarity != "" and rarity != "common":
		reasons.append(rarity.capitalize())
	if comparison.strip_edges() != "":
		reasons.append("Weapon compare")
	if reasons.is_empty():
		reasons.append("Baseline")
	return reasons

func _shop_purchase_rarity_bonus(rarity: String) -> int:
	match rarity:
		"uncommon":
			return 4
		"rare":
			return 8
		"epic":
			return 12
		"legendary":
			return 16
		"mythic":
			return 20
	return 0

func _readable_list(items: Array) -> String:
	var out: Array[String] = []
	var seen := {}
	for item in items:
		var text := str(item).strip_edges()
		if text == "" or seen.has(text):
			continue
		seen[text] = true
		out.append(text)
	return "Baseline" if out.is_empty() else " / ".join(out)

func _signed_delta(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)

func _choice_tag_array(choice: Dictionary) -> Array:
	var tags: Array = []
	var raw_tags: Variant = choice.get("tags", [])
	if raw_tags is Array:
		for tag in raw_tags:
			tags.append(tag)
	return tags

func _show_shop_leave_feedback() -> void:
	_show_floating_toast(
		"ShopLeaveToast",
		"Shop left",
		Vector2(22, 96),
		Color(0.78, 0.86, 1.0))

func _show_shop_buy_failed_feedback(item_name: String, cost: int = 0) -> void:
	var current_gold := player.gold if player != null else 0
	var missing := maxi(cost - current_gold, 0)
	_show_floating_toast(
		"ShopBuyFailedToast",
		"Cannot buy %s | Need %d Gold" % [item_name, missing] if missing > 0 \
			else "Cannot buy %s | Gold %d" % [item_name, current_gold],
		Vector2(22, 96),
		Color(1.0, 0.56, 0.34),
		{
			"shop_feedback_kind": "blocked",
			"shop_item_name": item_name,
			"shop_cost": cost,
			"shop_gold": current_gold,
			"shop_gold_missing": missing,
		})

func _show_reward_economy_feedback(
		reason: String,
		gold_delta: int,
		economy_kind: String = "",
		extra_metadata: Dictionary = {},
) -> void:
	var sign := "+" if gold_delta >= 0 else "-"
	var delta_text := "" if gold_delta == 0 else " | %s%d Gold" % [sign, absi(gold_delta)]
	var kind := economy_kind
	if kind == "":
		kind = "neutral" if gold_delta == 0 else "gain" if gold_delta > 0 else "spend"
	var metadata := {
		"reward_economy_reason": reason,
		"reward_gold_delta": gold_delta,
		"reward_economy_kind": kind,
	}
	for key in extra_metadata.keys():
		metadata[str(key)] = extra_metadata[key]
	_show_floating_toast(
		"RewardEconomyToast",
		"%s%s" % [reason, delta_text],
		Vector2(22, 116),
		Color(1.0, 0.88, 0.28) if gold_delta >= 0 else Color(1.0, 0.56, 0.36),
		metadata)

func _show_floor_transition_card(initial: bool = false) -> void:
	_play_floor_transition_sfx(initial)
	var build := player.upgrade_summary()
	if build == "":
		build = "No upgrades"
	var prefix := "Run start" if initial else "Descending"
	var resource_label := "MP" if player.resource_type == "mana" else "EN"
	var text := "%s | Floor %d | %s\nBuild: %s\nGold %d | Keys %d | HP %d/%d | %s %.0f/%.0f" % [
		prefix,
		current_floor,
		_floor_ctrl.current_biome_label(),
		build,
		player.gold,
		player.silver_keys,
		player.hp,
		player.max_hp,
		resource_label,
		player.resource,
		player.max_resource,
	]
	var modifier := _run_modifier_summary()
	if modifier != "":
		text += "\nChallenge: %s" % modifier
	if not initial and _last_floor_summary != "":
		text += "\nLast floor: %s" % _last_floor_summary
	var compact_text := "%s F%d | %s | HP %d/%d | Gold %d Keys %d" % [
		prefix,
		current_floor,
		_floor_ctrl.current_biome_label(),
		player.hp,
		player.max_hp,
		player.gold,
		player.silver_keys,
	]
	var metadata := {
		"floor_transition_full_text": text,
		"floor_transition_initial": initial,
		"floor_transition_floor": current_floor,
		"floor_transition_biome": _floor_ctrl.current_biome_label(),
	}
	_show_floating_toast(
		"FloorTransitionCard",
		compact_text,
		Vector2(22, 54 if initial else 74),
		Color(0.78, 0.9, 1.0),
		metadata)

func _play_floor_transition_sfx(initial: bool) -> void:
	var cue: Dictionary = AudioCueDBScript.floor_transition_cue(initial)
	var sfx := get_node_or_null("FloorTransitionSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "FloorTransitionSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("floor_transition_initial", initial)
	sfx.set_meta("floor_transition", "start" if initial else "descend")
	sfx.set_meta("floor_sound_id", str(cue.get("id", "floor_descend")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "floor_transition")))
	sfx.set_meta("floor_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _show_floating_toast(
		toast_name: String,
		text: String,
		position: Vector2,
		color: Color,
		metadata: Dictionary = {},
) -> void:
	var toast := Label.new()
	toast.name = toast_name
	toast.text = text
	toast.position = position
	toast.add_theme_font_size_override("font_size", 12)
	toast.add_theme_color_override("font_color", color)
	toast.z_index = 60
	for key in metadata.keys():
		toast.set_meta(str(key), metadata[key])
	add_child(toast)
	var tween := toast.create_tween()
	tween.set_parallel(true)
	tween.tween_property(toast, "position", toast.position + Vector2(0, -18), 0.75)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(toast, "modulate:a", 0.0, 0.75)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(Callable(toast, "queue_free"))

func _annotated_pending_upgrades() -> Array[Dictionary]:
	var annotated: Array[Dictionary] = []
	for choice in _pending_upgrades:
		if not (choice is Dictionary):
			continue
		var copy := (choice as Dictionary).duplicate()
		var reason := UpgradeDBScript.upgrade_block_reason(player, str(copy.get("id", "")))
		if reason != "":
			copy["disabled"] = true
			copy["disabled_reason"] = reason
		annotated.append(copy)
	return annotated

func _run_summary_context() -> Dictionary:
	var class_data := PlayerClassDB.get_class_data(player.class_id)
	var timing := _room_timing_context()
	var economy := _run_economy_context()
	var context := {
		"seed": run_seed,
		"seed_label": _run_seed_context_label(),
		"daily_fingerprint": _daily_seed_fingerprint_context(),
		"mode": _run_mode_label(),
		"difficulty": _run_difficulty_label(),
		"threat": _run_threat_label(),
		"run_finale": _is_run_finale_summary(),
		"modifier": _run_modifier_summary(),
		"challenge_bonus": _run_modifier_bonus_summary(),
		"challenge_bonus_status": _run_modifier_bonus_status_summary(),
		"challenge_goals": _run_goal_progress_summary(),
		"challenge_goal_completed_count": _run_goal_completed_count(),
		"challenge_goal_count": _run_goal_count(),
		"meta_bonuses": MetaProgressionScript.active_bonus_summary(
			MetaProgressionScript.load_data(), _floor_ctrl.current_biome),
		"class_id": player.class_id,
		"class": str(class_data.get("name", player.class_id)),
		"element": player.equipped_element,
		"biome_id": _current_biome_id(),
		"biome": _current_biome_label(),
		"boss_variant": _current_boss_variant(),
		"boss": _current_boss_label(),
		"weapons": player.weapon_loadout_summary(),
		"power_arc": player.run_power_arc_summary(),
		"power_milestones": player.power_milestone_summary(),
		"archetype": player.build_archetype_summary(),
		"build": player.upgrade_summary(),
		"tags": player.upgrade_tag_summary(),
		"rune_socket": player.rune_socket_summary(),
		"stat_summary": player.run_stat_summary(),
		"history": player.upgrade_history_summary(),
		"decision_history": player.upgrade_decision_history_summary(),
		"shop_history": player.shop_purchase_history_summary(),
		"loot_history": player.pickup_history_summary(),
		"room_history": player.room_decision_history_summary(),
		"skill_history": player.skill_usage_summary(),
		"combo_history": player.element_combo_summary(),
		"boss_story": _boss_story_summary(),
		"boss_pressure": _boss_pressure_summary(),
		"boss_phase_timing": _boss_phase_timing_summary(),
		"boss_attack_timing": _boss_attack_timing_summary(),
		"damage_taken": player.damage_taken_summary(),
		"survival": player.survival_summary(),
		"final_hit": player.final_hit_summary(),
		"stats": _run_stats_summary(),
		"decisions": _run_decision_summary(),
		"floor_recap": _run_floor_recap_summary(),
		"path": _room_path_summary(),
		"mastery": _room_mastery_summary(),
		"pace": _room_timing_summary(),
		"tuning_focus": ReleaseAuditScript.balance_playtest_summary(),
		"playtest_objective": ReleaseAuditScript.playtest_objective_summary(),
		"tuning_patch": ReleaseAuditScript.tuning_patch_summary(),
		"balance_experiment": _balance_experiment_summary(),
		"release_audit": ReleaseAuditScript.summary_text(),
		"release_decision": ReleaseAuditScript.public_release_decision(),
		"release_replacements": _release_audit_replacement_count(),
		"release_backlog": ReleaseAuditScript.replacement_backlog_summary(),
		"release_next_action": ReleaseAuditScript.next_release_action(),
	}
	if not timing.is_empty():
		context["pace_timed_rooms"] = int(timing.get("timed_room_count", 0))
		context["pace_avg_sec"] = float(timing.get("avg_clear_time_sec", 0.0))
		var boss_sec := float(timing.get("boss_clear_time_sec", -1.0))
		if boss_sec >= 0.0:
			context["pace_boss_sec"] = boss_sec
		context["pace_slowest_sec"] = float(timing.get("slowest_clear_time_sec", 0.0))
		context["pace_slowest_room"] = str(timing.get("slowest_room_type_name", "")).strip_edges()
		context["pace_fast_count"] = int(timing.get("fast_room_count", 0))
		context["pace_target_count"] = int(timing.get("target_room_count", 0))
		context["pace_slow_count"] = int(timing.get("slow_room_count", 0))
	for key in economy.keys():
		context[key] = economy[key]
	if player != null and player.has_method("enemy_codex_context"):
		var enemy_codex_context: Dictionary = player.call("enemy_codex_context")
		for key in enemy_codex_context.keys():
			context[key] = enemy_codex_context[key]
	var balance_context := _balance_experiment_context()
	for key in balance_context.keys():
		context[key] = balance_context[key]
	var release_candidate := _release_candidate_context()
	for key in release_candidate.keys():
		context[key] = release_candidate[key]
	return context

func _current_biome_id() -> String:
	if _floor_ctrl == null:
		return ""
	return str(_floor_ctrl.current_biome.get("id", "")).strip_edges()

func _current_biome_label() -> String:
	if _floor_ctrl == null:
		return ""
	return str(_floor_ctrl.current_biome.get("name", "")).strip_edges()

func _current_boss_variant() -> String:
	if _floor_ctrl == null:
		return ""
	var status := _floor_ctrl.current_boss_status()
	var variant := str(status.get("variant", "")).strip_edges()
	return variant if variant != "" else str(_floor_ctrl.current_biome.get("boss_variant", "")).strip_edges()

func _current_boss_label() -> String:
	var variant := _current_boss_variant()
	return "" if variant == "" else variant.replace("_", " ").capitalize()

func _run_seed_context_label() -> String:
	return "Daily Seed" if _is_daily_seed(run_seed) else "Seed"

func _daily_seed_fingerprint_context() -> Dictionary:
	if not _is_daily_seed(run_seed) or _floor_ctrl == null:
		return {}
	if _floor_ctrl.has_method("current_floor_fingerprint"):
		return _floor_ctrl.call("current_floor_fingerprint")
	var floor_index := maxi(current_floor, 1)
	return FloorController.daily_seed_fingerprint(run_seed, floor_index, _run_mode)

func _modifier_for_run(seed: int, mode: String = "normal") -> Dictionary:
	if mode == "balance_lab":
		return RunModifierDBScript.balance_lab_modifier(
			ReleaseAuditScript.balance_tuning_experiment_patch(MetaProgressionScript.load_data()))
	return RunModifierDBScript.daily_modifier_for_seed(seed) if _is_daily_seed(seed) else {}

func _run_modifier_summary() -> String:
	return RunModifierDBScript.summary(_run_modifier)

func _balance_experiment_context() -> Dictionary:
	var patch: Dictionary = _run_modifier.get("boss_tuning_patch", {})
	if patch.is_empty() or not bool(patch.get("enabled", false)):
		return {}
	var patch_id := str(patch.get("id", "")).strip_edges()
	var multiplier := float(patch.get("hp_multiplier", 1.0))
	if patch_id == "" or multiplier <= 0.0:
		return {}
	var source := str(patch.get("source", "playtest_evidence")).strip_edges()
	return {
		"balance_experiment_id": str(_run_modifier.get("id", "balance_lab")).strip_edges(),
		"balance_experiment_patch_id": patch_id,
		"balance_experiment_hp_multiplier": multiplier,
		"balance_experiment_source": source if source != "" else "playtest_evidence",
	}

func _balance_experiment_summary() -> String:
	var context := _balance_experiment_context()
	if context.is_empty():
		return ""
	return "Balance Lab: %s HP %.2fx from %s" % [
		str(context.get("balance_experiment_patch_id", "")),
		float(context.get("balance_experiment_hp_multiplier", 1.0)),
		str(context.get("balance_experiment_source", "playtest_evidence")),
	]

func _run_modifier_bonus_summary() -> String:
	return RunModifierDBScript.reward_bonus_summary(_run_modifier)

func _run_modifier_bonus_status_summary() -> String:
	return RunModifierDBScript.earned_reward_bonus_summary(_run_modifier, _run_goal_progress)

func _run_goal_progress_summary() -> String:
	return RunModifierDBScript.goal_progress_summary(_run_modifier, _run_goal_progress)

func _run_goal_completed_count() -> int:
	return RunModifierDBScript.completed_goal_count(_run_goal_progress)

func _run_goal_count() -> int:
	return _run_goal_progress.size()

func _sync_run_goal_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.set_run_modifier_goals(_run_goal_progress_summary(), _run_goal_progress)

func _advance_run_goal(event_id: String, amount: int = 1) -> void:
	if _run_modifier.is_empty():
		return
	var before := _run_goal_progress.duplicate(true)
	var completed_before := RunModifierDBScript.completed_goal_count(_run_goal_progress)
	_run_goal_progress = RunModifierDBScript.advance_goal_progress(
		_run_modifier, _run_goal_progress, event_id, amount)
	_sync_run_goal_hud()
	var completed_after := RunModifierDBScript.completed_goal_count(_run_goal_progress)
	if completed_after > completed_before:
		_show_run_goal_completed_feedback(before)

func _show_run_goal_completed_feedback(previous_progress: Dictionary) -> void:
	if _hud == null or not is_instance_valid(_hud):
		return
	var completed_label := ""
	for goal_id in _run_goal_progress.keys():
		var current: Dictionary = _run_goal_progress.get(goal_id, {})
		var previous: Dictionary = previous_progress.get(goal_id, {})
		var was_done := bool(previous.get("completed", false)) \
			or int(previous.get("current", 0)) >= int(previous.get("target", 1))
		var now_done := bool(current.get("completed", false)) \
			or int(current.get("current", 0)) >= int(current.get("target", 1))
		if now_done and not was_done:
			completed_label = str(current.get("label", goal_id))
			break
	_hud.show_run_goal_completed(
		completed_label,
		_run_goal_progress_summary(),
		_run_goal_completed_count(),
		_run_goal_count())

func _normalized_run_mode(mode: String) -> String:
	return mode if ["boss_rush", "endless", "hardcore", "elemental_chaos", "balance_lab"].has(mode) else "normal"

func _run_mode_label() -> String:
	match _run_mode:
		"boss_rush":
			return "Boss Rush"
		"endless":
			return "Endless"
		"hardcore":
			return "Hardcore"
		"elemental_chaos":
			return "Elemental Chaos"
		"balance_lab":
			return "Balance Lab"
		_:
			return "Normal"

func _run_continues_after_floor_cap() -> bool:
	return _run_mode == "endless"

func _run_floor_cap() -> int:
	return FloorController.BOSS_RUSH_CHAIN_FLOORS if _run_mode == "boss_rush" else MAX_FLOORS

func _run_difficulty_label() -> String:
	if _floor_ctrl != null and _floor_ctrl.has_method("current_difficulty_label"):
		return str(_floor_ctrl.call("current_difficulty_label"))
	return "x1.00"

func _run_threat_label() -> String:
	if _floor_ctrl != null and _floor_ctrl.has_method("current_threat_label"):
		var label := str(_floor_ctrl.call("current_threat_label")).strip_edges()
		return label.trim_prefix("Threat").strip_edges() if label.begins_with("Threat") else label
	return "x1.00"

func _is_run_finale_summary() -> bool:
	if _run_mode == "endless":
		return false
	if current_floor > _run_floor_cap():
		return true
	if _floor_ctrl != null:
		return bool(_floor_ctrl.current_biome.get("run_finale", false))
	return false

func _is_daily_seed(seed: int) -> bool:
	var date := Time.get_date_dict_from_system()
	var today_seed := int(date.get("year", 0)) * 10000 \
		+ clampi(int(date.get("month", 1)), 1, 12) * 100 \
		+ clampi(int(date.get("day", 1)), 1, 31)
	return seed == today_seed

func _run_stats_summary() -> String:
	var rooms_cleared := 0
	var rooms_total := 0
	if _floor_ctrl != null:
		rooms_cleared = _floor_ctrl.cleared_room_count()
		rooms_total = _floor_ctrl.total_room_count()
	return "Rooms %d/%d | Kills %d | Upgrades %d" % [
		rooms_cleared,
		rooms_total,
		player.run_kill_count(),
		player.upgrade_count(),
	]

func _record_floor_start_snapshot() -> void:
	_floor_start_snapshot = _floor_progress_snapshot()

func _floor_progress_snapshot() -> Dictionary:
	var rooms_cleared := 0
	var rooms_total := 0
	if _floor_ctrl != null:
		rooms_cleared = _floor_ctrl.cleared_room_count()
		rooms_total = _floor_ctrl.total_room_count()
	var rewards := player.run_rewards() if player != null else {}
	return {
		"floor": current_floor,
		"rooms_cleared": rooms_cleared,
		"rooms_total": rooms_total,
		"kills": player.run_kill_count() if player != null else 0,
		"upgrades": player.upgrade_count() if player != null else 0,
		"gold": int(rewards.get("gold", 0)),
		"soul_shards": int(rewards.get("soul_shards", 0)),
		"element_cores": int(rewards.get("element_cores", 0)),
		"rune_dust": int(rewards.get("rune_dust", 0)),
		"blueprints": int(rewards.get("blueprints", 0)),
		"reward_picks": _reward_pick_count,
		"reward_skips": _reward_skip_count,
		"reward_rerolls": _reward_reroll_count,
		"shop_buys": _shop_buy_count,
		"shop_leaves": _shop_leave_count,
	}

func _run_economy_context() -> Dictionary:
	var snapshot := _floor_progress_snapshot()
	return {
		"economy_gold_earned": int(snapshot.get("gold", 0)),
		"economy_soul_shards": int(snapshot.get("soul_shards", 0)),
		"economy_element_cores": int(snapshot.get("element_cores", 0)),
		"economy_rune_dust": int(snapshot.get("rune_dust", 0)),
		"economy_blueprints": int(snapshot.get("blueprints", 0)),
		"decision_reward_picks": int(snapshot.get("reward_picks", 0)),
		"decision_reward_skips": int(snapshot.get("reward_skips", 0)),
		"decision_reward_rerolls": int(snapshot.get("reward_rerolls", 0)),
		"decision_shop_buys": int(snapshot.get("shop_buys", 0)),
		"decision_shop_leaves": int(snapshot.get("shop_leaves", 0)),
	}

func _floor_delta_summary() -> String:
	if _floor_start_snapshot.is_empty():
		return _run_stats_summary()
	var now := _floor_progress_snapshot()
	var floor_number := int(_floor_start_snapshot.get("floor", current_floor))
	var parts: Array[String] = [
		"Floor %d recap: Rooms %d/%d" % [
			floor_number,
			int(now.get("rooms_cleared", 0)),
			int(now.get("rooms_total", 0)),
		],
		_delta_part("Kills", now, "kills"),
		_delta_part("Upgrades", now, "upgrades"),
		_delta_part("Gold", now, "gold"),
		_delta_part("Rewards", now, "reward_picks"),
		_delta_part("Skips", now, "reward_skips"),
	]
	var shop_delta := _int_delta(now, "shop_buys")
	var shop_leave_delta := _int_delta(now, "shop_leaves")
	if shop_delta != 0 or shop_leave_delta != 0:
		parts.append("Shops +%d/%d leaves" % [shop_delta, shop_leave_delta])
	var meta_parts: Array[String] = []
	for spec in [
		["Shard", "soul_shards"],
		["Core", "element_cores"],
		["Dust", "rune_dust"],
		["BP", "blueprints"],
	]:
		var delta := _int_delta(now, str(spec[1]))
		if delta > 0:
			meta_parts.append("%s +%d" % [str(spec[0]), delta])
	if not meta_parts.is_empty():
		parts.append("Meta %s" % " / ".join(meta_parts))
	var mastery := _room_mastery_summary()
	if mastery != "":
		parts.append("Mastery: %s" % mastery)
	return " | ".join(parts)

func _run_floor_recap_summary() -> String:
	if _last_floor_summary != "":
		return _last_floor_summary
	return _floor_delta_summary()

func _delta_part(label: String, now: Dictionary, key: String) -> String:
	var delta := _int_delta(now, key)
	return "%s +%d" % [label, delta] if delta >= 0 else "%s -%d" % [label, absi(delta)]

func _int_delta(now: Dictionary, key: String) -> int:
	return int(now.get(key, 0)) - int(_floor_start_snapshot.get(key, 0))

func _reset_run_decision_counts() -> void:
	_reward_pick_count = 0
	_reward_skip_count = 0
	_reward_reroll_count = 0
	_shop_buy_count = 0
	_shop_leave_count = 0
	_boss_story_events.clear()
	_boss_pressure_events.clear()
	_boss_phase_timing_events.clear()
	_boss_attack_timing_events.clear()
	_last_floor_summary = ""
	_floor_start_snapshot.clear()

func _on_room_mastery_awarded(context: Dictionary) -> void:
	_advance_run_goal("clear_room")
	match int(context.get("room_type", -1)):
		RoomNode.RoomType.ELITE:
			_advance_run_goal("clear_elite")
		RoomNode.RoomType.MINIBOSS:
			_advance_run_goal("clear_miniboss")
		RoomNode.RoomType.BOSS:
			_advance_run_goal("clear_boss")
		RoomNode.RoomType.EVENT:
			_advance_run_goal("clear_event")
		RoomNode.RoomType.SECRET:
			_advance_run_goal("clear_secret")
	if bool(context.get("perfect_clear", false)):
		_advance_run_goal("perfect_clear")
	_apply_elemental_chaos_shift()

func _apply_elemental_chaos_shift() -> void:
	if _run_mode != "elemental_chaos" or player == null or not is_instance_valid(player):
		return
	var before := str(player.equipped_element)
	player.cycle_element()
	var after := str(player.equipped_element)
	if after == before:
		return
	if player.has_method("activate_chaos_surge"):
		player.activate_chaos_surge(after)
	player.record_room_decision(
		"Elemental Chaos",
		"%s -> %s" % [before.capitalize(), after.capitalize()])
	if is_inside_tree():
		_show_floating_toast(
			"ElementalChaosToast",
			"Element: %s" % after.capitalize(),
			player.global_position + Vector2(-34, -38),
			Color(0.55, 0.9, 1.0, 1.0),
			{"run_mode": "elemental_chaos", "from": before, "to": after})

func _run_decision_summary() -> String:
	return "Rewards %d | Skips %d | Rerolls %d | Shop buys %d | Shop leaves %d" % [
		_reward_pick_count,
		_reward_skip_count,
		_reward_reroll_count,
		_shop_buy_count,
		_shop_leave_count,
	]

func _room_path_summary() -> String:
	if _floor_ctrl == null or not _floor_ctrl.has_method("visited_room_path_summary"):
		return ""
	return str(_floor_ctrl.call("visited_room_path_summary"))

func _room_mastery_summary() -> String:
	if _floor_ctrl == null or not _floor_ctrl.has_method("room_mastery_summary"):
		return ""
	return str(_floor_ctrl.call("room_mastery_summary"))

func _room_timing_summary() -> String:
	if _floor_ctrl == null or not _floor_ctrl.has_method("room_timing_summary"):
		return ""
	return str(_floor_ctrl.call("room_timing_summary"))

func _room_timing_context() -> Dictionary:
	if _floor_ctrl == null or not _floor_ctrl.has_method("room_timing_context"):
		return {}
	var raw: Variant = _floor_ctrl.call("room_timing_context")
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}

func _release_audit_replacement_count() -> int:
	var report := ReleaseAuditScript.runtime_report()
	return Array(report.get("replace_before_public", [])).size()

func _release_candidate_context() -> Dictionary:
	var meta := MetaProgressionScript.load_data(MetaProgressionScript.SAVE_PATH)
	var summary := ReleaseAuditScript.release_candidate_summary(meta)
	return {
		"release_candidate_status": str(summary.get("status", "evidence_required")),
		"release_candidate_evidence": MetaProgressionScript.release_candidate_evidence_summary(meta),
		"playtest_notes_record_command": _playtest_notes_record_command(),
		"manual_scenario_evidence_draft": _manual_scenario_evidence_draft(),
		"manual_scenario_record_command": _manual_scenario_record_command(),
		"manual_scenario_issue_record_command": _manual_scenario_issue_record_command(),
		"manual_scenario_issue_resolve_command": _manual_scenario_issue_resolve_command(),
		"manual_scenario_issue_type_suggestions": _manual_playtest_issue_type_summary(),
		"release_candidate_next_action": str(summary.get("next_action", "")),
		"release_candidate_blockers": _release_candidate_blocker_summary(
			Array(summary.get("blockers", []))),
	}

func _playtest_notes_record_command(class_id: String = "") -> String:
	var current_class_id := class_id.strip_edges()
	if current_class_id == "" and player != null:
		current_class_id = player.class_id
	if run_seed <= 0 or _run_mode == "" or current_class_id == "":
		return ""
	return "godot --headless --path . --script res://scripts/tools/record_playtest_notes_evidence.gd -- --seed=%d --class_id=%s --mode=%s --replay_last_run_result=<replay_last_run_result> --daily_fingerprint_hash=<daily_fingerprint_hash> --pace_avg_sec=<pace_avg_sec> --pace_boss_sec=<pace_boss_sec> --asset_animation_notes=<asset_animation_notes> --polygon_collision_notes=<polygon_collision_notes> --wave_hud_audio_notes=<wave_hud_audio_notes> --blocker_screenshot_or_seed=<blocker_screenshot_or_seed> --release_decision=<release_decision>" % [
		run_seed,
		current_class_id,
		_run_mode,
	]

func _manual_scenario_evidence_draft(class_id: String = "") -> String:
	var scenario := _manual_scenario_checklist_match(class_id)
	if scenario.is_empty():
		return ""
	var goal := str(scenario.get("goal", "")).strip_edges()
	if goal == "":
		return ""
	return "seed=%d | mode=%s | class_id=%s | goal=%s | result=pending | evidence_source=manual_playtest" % [
		run_seed,
		_run_mode,
		str(scenario.get("class_id", "")),
		goal,
	]

func _manual_scenario_record_command(class_id: String = "") -> String:
	var scenario := _manual_scenario_checklist_match(class_id)
	if scenario.is_empty():
		return ""
	return "godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=%d --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>" % int(
		scenario.get("scenario_index", 0))

func _manual_scenario_issue_record_command(class_id: String = "") -> String:
	var scenario := _manual_scenario_checklist_match(class_id)
	if scenario.is_empty():
		return ""
	return "godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=%d --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=<screenshot or seed>" % int(
		scenario.get("scenario_index", 0))

func _manual_scenario_issue_resolve_command(class_id: String = "") -> String:
	var scenario := _manual_scenario_checklist_match(class_id)
	if scenario.is_empty():
		return ""
	return "godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=%d --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=<screenshot or seed>" % int(
		scenario.get("scenario_index", 0))

func _manual_scenario_checklist_match(class_id: String = "") -> Dictionary:
	var current_class_id := class_id.strip_edges()
	if current_class_id == "" and player != null:
		current_class_id = player.class_id
	if run_seed <= 0 or _run_mode == "" or current_class_id == "":
		return {}
	var checklist := ReleaseAuditScript.manual_playtest_checklist()
	var scenario_index := 1
	for raw_scenario in Array(checklist.get("scenario_runs", [])):
		if not (raw_scenario is Dictionary):
			scenario_index += 1
			continue
		var scenario: Dictionary = raw_scenario
		if int(scenario.get("seed", 0)) != run_seed:
			scenario_index += 1
			continue
		if str(scenario.get("mode", "")).strip_edges() != _run_mode:
			scenario_index += 1
			continue
		if str(scenario.get("class_id", "")).strip_edges() != current_class_id:
			scenario_index += 1
			continue
		var matched := scenario.duplicate(true)
		matched["scenario_index"] = scenario_index
		matched["class_id"] = current_class_id
		return matched
	return {}

func _release_candidate_blocker_summary(blockers: Array) -> String:
	var visible: Array[String] = []
	for blocker in blockers:
		var text := str(blocker).strip_edges()
		if text == "" or text.contains(":"):
			continue
		if not visible.has(text):
			visible.append(text)
		if visible.size() >= 4:
			break
	return "clear" if visible.is_empty() else ", ".join(visible)

func _on_boss_phase_changed(status: Dictionary) -> void:
	var phase := int(status.get("phase", 0))
	var label := _clean_boss_story_label(str(status.get("pattern_label", "")))
	if label == "":
		label = str(status.get("phase_text", "")).strip_edges()
	if label == "":
		label = "Phase"
	var prefix := "Enrage" if bool(status.get("enraged", false)) else "Phase %d" % phase
	_boss_story_events.append("%s: %s" % [prefix, label])
	_record_boss_pressure(status)
	_record_boss_phase_timing(status, prefix)

func _on_boss_attack_cued(status: Dictionary) -> void:
	var label := str(status.get("variant_attack_label", "")).strip_edges()
	if label == "":
		label = str(status.get("attack_label", "")).strip_edges()
	if label == "":
		label = str(status.get("attack", "Attack")).replace("_", " ").capitalize()
	var count := int(status.get("projectile_count", status.get("hazard_count", 0)))
	var text := "%s x%d" % [label, count] if count > 0 else label
	var warning := str(status.get("variant_warning", "")).strip_edges()
	if warning == "":
		warning = str(status.get("warning", "")).strip_edges()
	if warning != "":
		text += " (%s)" % warning
	var counter := str(status.get("variant_counter_hint", status.get("counter_hint", ""))).strip_edges()
	if counter != "":
		text += " | Counter: %s" % counter
	var punish := float(status.get("punish_window_seconds", 0.0))
	if punish > 0.0:
		text += " | Punish %.1fs" % punish
	var safe_window := str(status.get("safe_window_hint", "")).strip_edges()
	if safe_window != "":
		text += " | Safe: %s" % safe_window
	_boss_story_events.append(text)
	_record_boss_pressure(status)
	_record_boss_attack_timing(status, label)

func _boss_story_summary(max_items: int = 6) -> String:
	if _boss_story_events.is_empty():
		return "None"
	var start := maxi(_boss_story_events.size() - max_items, 0)
	return " -> ".join(_boss_story_events.slice(start))

func _record_boss_pressure(status: Dictionary) -> void:
	var pressure := str(status.get("arena_pressure_summary", "")).strip_edges()
	if pressure != "":
		_boss_pressure_events.append(pressure)

func _boss_pressure_summary(max_items: int = 6) -> String:
	if _boss_pressure_events.is_empty():
		return "None"
	var start := maxi(_boss_pressure_events.size() - max_items, 0)
	return " -> ".join(_boss_pressure_events.slice(start))

func _record_boss_phase_timing(status: Dictionary, label: String) -> void:
	var elapsed := float(status.get("elapsed_seconds", -1.0))
	if elapsed < 0.0:
		elapsed = float(Time.get_ticks_msec()) / 1000.0
	_boss_phase_timing_events.append("%s %.1fs" % [label, elapsed])

func _boss_phase_timing_summary(max_items: int = 6) -> String:
	if _boss_phase_timing_events.is_empty():
		return "None"
	var start := maxi(_boss_phase_timing_events.size() - max_items, 0)
	return " -> ".join(_boss_phase_timing_events.slice(start))

func _record_boss_attack_timing(status: Dictionary, label: String) -> void:
	var elapsed := float(status.get("elapsed_seconds", -1.0))
	if elapsed < 0.0:
		return
	_boss_attack_timing_events.append("%s %.1fs" % [label, elapsed])

func _boss_attack_timing_summary(max_items: int = 6) -> String:
	if _boss_attack_timing_events.is_empty():
		return "None"
	var start := maxi(_boss_attack_timing_events.size() - max_items, 0)
	return " -> ".join(_boss_attack_timing_events.slice(start))

func _clean_boss_story_label(text: String) -> String:
	var clean := text.strip_edges()
	if clean.begins_with("Pattern:"):
		return clean.trim_prefix("Pattern:").strip_edges()
	return clean

func _bank_run_rewards(
		result: String,
		floor_reached: int,
		prepared_rewards: Dictionary = {},
) -> Dictionary:
	if _banked_run:
		return MetaProgressionScript.load_data()
	_banked_run = true
	var rewards := prepared_rewards if not prepared_rewards.is_empty() \
		else _run_rewards_for_banking(floor_reached)
	return MetaProgressionScript.bank_run_rewards(
		rewards, result, MetaProgressionScript.SAVE_PATH, _run_summary_context())

func _run_rewards_for_banking(floor_reached: int) -> Dictionary:
	var rewards := player.run_rewards()
	rewards["floor"] = floor_reached
	_apply_run_modifier_reward_bonus(rewards)
	_apply_hardcore_clear_bonus(rewards, floor_reached)
	_apply_elemental_chaos_bonus(rewards, floor_reached)
	_apply_endless_depth_bonus(rewards, floor_reached)
	return rewards

func _apply_run_modifier_reward_bonus(rewards: Dictionary) -> void:
	var bonus := RunModifierDBScript.earned_reward_bonus(_run_modifier, _run_goal_progress)
	if bonus.is_empty():
		return
	for key in bonus.keys():
		rewards[key] = int(rewards.get(key, 0)) + int(bonus[key])
	var summary := _run_modifier_bonus_summary()
	if summary != "":
		rewards["challenge_bonus"] = summary

func _apply_endless_depth_bonus(rewards: Dictionary, floor_reached: int) -> void:
	if _run_mode != "endless":
		return
	var extra_depth := maxi(floor_reached - MAX_FLOORS, 0)
	if extra_depth <= 0:
		return
	var dust := extra_depth
	var shards := extra_depth / 2
	rewards["rune_dust"] = int(rewards.get("rune_dust", 0)) + dust
	if shards > 0:
		rewards["soul_shards"] = int(rewards.get("soul_shards", 0)) + shards
	rewards["endless_depth_bonus"] = _endless_depth_bonus_summary(extra_depth, dust, shards)

func _apply_hardcore_clear_bonus(rewards: Dictionary, floor_reached: int) -> void:
	if _run_mode != "hardcore":
		return
	var floor := maxi(floor_reached, 1)
	var dust := floor
	var shards := 1 if floor >= MAX_FLOORS else 0
	rewards["rune_dust"] = int(rewards.get("rune_dust", 0)) + dust
	if shards > 0:
		rewards["soul_shards"] = int(rewards.get("soul_shards", 0)) + shards
	rewards["hardcore_clear_bonus"] = _hardcore_clear_bonus_summary(floor, dust, shards)

func _apply_elemental_chaos_bonus(rewards: Dictionary, floor_reached: int) -> void:
	if _run_mode != "elemental_chaos":
		return
	var floor := maxi(floor_reached, 1)
	var cores := floor
	var dust := 1 if floor >= MAX_FLOORS else 0
	rewards["element_cores"] = int(rewards.get("element_cores", 0)) + cores
	if dust > 0:
		rewards["rune_dust"] = int(rewards.get("rune_dust", 0)) + dust
	rewards["elemental_chaos_bonus"] = _elemental_chaos_bonus_summary(floor, cores, dust)

func _hardcore_clear_bonus_summary(floor_reached: int, dust: int, shards: int) -> String:
	var parts: Array[String] = ["Dust +%d" % dust]
	if shards > 0:
		parts.append("Shard +%d" % shards)
	return "Floor %d: %s" % [floor_reached, " / ".join(parts)]

func _elemental_chaos_bonus_summary(floor_reached: int, cores: int, dust: int) -> String:
	var parts: Array[String] = ["Core +%d" % cores]
	if dust > 0:
		parts.append("Dust +%d" % dust)
	return "Floor %d: %s" % [floor_reached, " / ".join(parts)]

func _endless_depth_bonus_summary(extra_depth: int, dust: int, shards: int) -> String:
	var parts: Array[String] = ["Dust +%d" % dust]
	if shards > 0:
		parts.append("Shard +%d" % shards)
	return "Depth +%d: %s" % [extra_depth, " / ".join(parts)]

func _disable_player() -> void:
	player.set_physics_process(false)
	player.hide()
	player.get_node("CollisionShape2D").set_deferred("disabled", true)
