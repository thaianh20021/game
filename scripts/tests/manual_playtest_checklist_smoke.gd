extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_manual_playtest_checklist(failures)
	if failures.is_empty():
		print("Manual playtest checklist smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_manual_playtest_checklist(failures: Array[String]) -> void:
	var release_audit = load(RELEASE_AUDIT_PATH)
	if not release_audit.has_method("manual_playtest_checklist"):
		failures.append("ReleaseAudit should expose manual_playtest_checklist before release")
		return
	var checklist: Dictionary = release_audit.call("manual_playtest_checklist")
	if not release_audit.has_method("playtest_notes_template"):
		failures.append("ReleaseAudit should expose playtest_notes_template for required playtest notes")
		return
	var notes_template: Dictionary = release_audit.call("playtest_notes_template")
	if str(checklist.get("status", "")) != "ready_for_human_playtest":
		failures.append("manual playtest checklist should be ready for human playtest")
	if not Array(checklist.get("required_before_release", [])).has("run_full_smoke_suite"):
		failures.append("manual playtest checklist should require full smoke before release")
	if not Array(checklist.get("required_before_release", [])).has("record_playtest_notes"):
		failures.append("manual playtest checklist should require recorded playtest notes")
	if not Array(checklist.get("required_before_release", [])).has("verify_export_preset"):
		failures.append("manual playtest checklist should require export preset verification")
	var sections: Dictionary = checklist.get("sections", {})
	for section_id in [
			"boot_controls",
			"combat_readability",
			"room_objectives",
			"progression_economy",
			"class_coverage",
			"asset_animation_review",
			"export_package",
			"performance_stability",
	]:
		if not sections.has(section_id):
			failures.append("manual playtest checklist missing section %s" % section_id)
			continue
		var steps: Array = Dictionary(sections.get(section_id, {})).get("steps", [])
		if steps.is_empty():
			failures.append("manual playtest section should include steps: %s" % section_id)
	var scenarios: Array = checklist.get("scenario_runs", [])
	if scenarios.size() < 6:
		failures.append("manual playtest checklist should cover at least six scenario runs")
	var modes := {}
	var classes := {}
	for raw_scenario in scenarios:
		if not (raw_scenario is Dictionary):
			continue
		var scenario: Dictionary = raw_scenario
		modes[str(scenario.get("mode", ""))] = true
		classes[str(scenario.get("class_id", ""))] = true
		if int(scenario.get("seed", 0)) <= 0:
			failures.append("manual playtest scenario should use a fixed positive seed")
		if str(scenario.get("goal", "")) == "":
			failures.append("manual playtest scenario should state a goal")
	for mode in ["normal", "boss_rush", "endless", "hardcore", "elemental_chaos", "balance_lab"]:
		if not modes.has(mode):
			failures.append("manual playtest scenarios should include %s mode" % mode)
	if classes.size() < 6:
		failures.append("manual playtest scenarios should cover at least six classes")
	if str(checklist.get("notes_template_status", "")) != "ready_for_notes":
		failures.append("manual playtest checklist should expose ready notes template status")
	if str(notes_template.get("status", "")) != "ready_for_notes":
		failures.append("playtest notes template should be ready for notes")
	var required_fields: Array = notes_template.get("required_fields", [])
	for field_id in [
			"seed",
			"class_id",
			"mode",
			"replay_last_run_result",
			"daily_fingerprint_hash",
			"pace_avg_sec",
			"pace_boss_sec",
			"asset_animation_notes",
			"polygon_collision_notes",
			"wave_hud_audio_notes",
			"blocker_screenshot_or_seed",
			"release_decision",
	]:
		if not required_fields.has(field_id):
			failures.append("playtest notes template missing field %s" % field_id)
	var note_scenarios: Array = notes_template.get("scenario_notes", [])
	if note_scenarios.size() < scenarios.size():
		failures.append("playtest notes template should include every manual scenario")
	for raw_note in note_scenarios:
		if not (raw_note is Dictionary):
			continue
		var note: Dictionary = raw_note
		if int(note.get("seed", 0)) <= 0 or str(note.get("mode", "")) == "" \
				or str(note.get("class_id", "")) == "":
			failures.append("playtest scenario note should preserve seed/mode/class")
		var prompts: Array = note.get("prompts", [])
		for prompt_id in ["replay_last_run", "pace", "asset_animation",
				"wave_hud_audio", "blockers"]:
			if not prompts.has(prompt_id):
				failures.append("playtest scenario note missing prompt %s" % prompt_id)
	var template_text := str(notes_template.get("template_text", ""))
	for token in ["Replay Last Run", "Daily Hash", "Pace", "Animation", "Polygon",
			"Wave/HUD/Audio", "No fanmade runtime copy"]:
		if not template_text.contains(token):
			failures.append("playtest notes template text missing %s" % token)
	var progression_steps: Array = Dictionary(sections.get("progression_economy", {})).get("steps", [])
	if not progression_steps.has("replay_last_run_same_seed_class_mode"):
		failures.append("progression economy playtest should verify replay last run reproducibility")
	var asset_steps: Array = Dictionary(sections.get("asset_animation_review", {})).get("steps", [])
	for required in [
			"watch_player_idle_run_dash_no_offset_pop",
			"watch_attack_vfx_frame_grid_and_origin",
			"verify_no_blank_or_cropped_generated_frames",
			"verify_object_polygon_matches_visible_sprite",
			"confirm_no_fanmade_runtime_copy",
	]:
		if not asset_steps.has(required):
			failures.append("asset animation playtest steps missing %s" % required)
	var export_steps: Array = Dictionary(sections.get("export_package", {})).get("steps", [])
	for required in [
			"verify_windows_export_preset",
			"package_candidate_debug_build",
			"boot_packaged_build_once",
	]:
		if not export_steps.has(required):
			failures.append("export package playtest steps missing %s" % required)
