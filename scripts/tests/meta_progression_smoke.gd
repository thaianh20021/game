extends SceneTree

const SAVE_PATH := "user://meta_progression_smoke.json"

func _init() -> void:
	var failures: Array[String] = []

	await _check_meta_progression_save(failures)
	_check_main_banks_run_rewards(failures)

	if failures.is_empty():
		print("Meta progression smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_meta_progression_save(failures: Array[String]) -> void:
	if not ResourceLoader.exists("res://scripts/progression/meta_progression.gd"):
		failures.append("MetaProgression script missing")
		return
	var script = load("res://scripts/progression/meta_progression.gd")
	if not _script_has_method(script, "recent_run_playtest_summary"):
		failures.append("MetaProgression should expose recent_run_playtest_summary")
	else:
		var trend_meta: Dictionary = script.default_data()
		trend_meta["recent_runs"] = [
			{
				"result": "victory",
				"pace_avg_sec": 12.0,
				"pace_boss_sec": 80.0,
				"economy_gold_earned": 64,
				"decision_reward_picks": 3,
				"decision_reward_skips": 1,
				"decision_reward_rerolls": 2,
				"decision_shop_buys": 2,
				"decision_shop_leaves": 1,
			},
			{
				"result": "defeat",
				"pace_avg_sec": 16.0,
				"pace_boss_sec": 90.0,
				"economy_gold_earned": 56,
				"decision_reward_picks": 2,
				"decision_reward_skips": 0,
				"decision_reward_rerolls": 0,
				"decision_shop_buys": 1,
				"decision_shop_leaves": 0,
			},
		]
		var trend := str(script.call("recent_run_playtest_summary", trend_meta))
		for token in [
			"Playtest Trend: Runs 2",
			"Win 1/2",
			"Avg Pace 14.0s",
			"Boss 85.0s",
			"Gold 60.0",
			"Rewards 2.5/0.5",
			"Rerolls 1.0",
			"Shop 1.5/0.5",
		]:
			if not trend.contains(token):
				failures.append("recent_run_playtest_summary missing token: %s" % token)
	if not _script_has_method(script, "balance_playtest_evidence"):
		failures.append("MetaProgression should expose balance_playtest_evidence")
	if not _script_has_method(script, "balance_playtest_evidence_summary"):
		failures.append("MetaProgression should expose balance_playtest_evidence_summary")
	else:
		var evidence_meta: Dictionary = script.default_data()
		evidence_meta["recent_runs"] = [
			{
				"boss_variant": "cave_golem",
				"biome_id": "ancient_cave",
				"pace_boss_sec": 80.0,
				"pace_avg_sec": 12.0,
			},
			{
				"boss_variant": "cave_golem",
				"biome_id": "ancient_cave",
				"pace_boss_sec": 90.0,
				"pace_avg_sec": 16.0,
			},
			{
				"boss_variant": "forge_golem",
				"biome_id": "ember_forge",
				"pace_boss_sec": 150.0,
				"pace_avg_sec": 14.0,
			},
		]
		var evidence: Dictionary = script.call("balance_playtest_evidence", evidence_meta)
		var cave_evidence: Dictionary = evidence.get("cave_golem_boss", {})
		if cave_evidence.is_empty():
			failures.append("balance playtest evidence should key boss variant as cave_golem_boss")
		else:
			if not is_equal_approx(float(cave_evidence.get("pace_boss_sec", 0.0)), 85.0):
				failures.append("balance playtest evidence should average boss pace")
			if int(cave_evidence.get("sample_runs", 0)) != 2:
				failures.append("balance playtest evidence should count boss samples")
			if str(cave_evidence.get("boss_variant", "")) != "cave_golem":
				failures.append("balance playtest evidence should preserve boss variant")
			if str(cave_evidence.get("biome_id", "")) != "ancient_cave":
				failures.append("balance playtest evidence should preserve biome id")
		var forge_evidence: Dictionary = evidence.get("forge_golem_boss", {})
		if not is_equal_approx(float(forge_evidence.get("pace_boss_sec", 0.0)), 150.0):
			failures.append("balance playtest evidence should keep separate boss variant samples")
		if script.has_method("balance_playtest_evidence_summary"):
			var evidence_summary := str(script.call(
				"balance_playtest_evidence_summary", evidence_meta, 2))
			for token in ["Playtest Evidence:", "cave_golem_boss 85.0s x2",
					"forge_golem_boss 150.0s x1"]:
				if not evidence_summary.contains(token):
					failures.append("balance playtest evidence summary missing token: %s" % token)
	if not script.default_data().has("release_candidate_evidence"):
		failures.append("default meta data should keep release candidate evidence")
	if not _script_has_method(script, "release_candidate_evidence"):
		failures.append("MetaProgression should expose release_candidate_evidence")
	if not _script_has_method(script, "record_release_candidate_evidence"):
		failures.append("MetaProgression should expose record_release_candidate_evidence")
	if not _script_has_method(script, "release_candidate_evidence_summary"):
		failures.append("MetaProgression should expose release_candidate_evidence_summary")
	else:
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		var candidate_evidence := _release_candidate_evidence_sample()
		candidate_evidence["ignored_raw_asset_source"] = "fanmade runtime copy"
		var recorded: Dictionary = script.call(
			"record_release_candidate_evidence", candidate_evidence, SAVE_PATH)
		var stored: Dictionary = script.call("release_candidate_evidence", recorded)
		if stored.has("ignored_raw_asset_source"):
			failures.append("release candidate evidence should drop unknown raw asset fields")
		var smoke_suite: Dictionary = stored.get("full_smoke_suite", {})
		if not bool(smoke_suite.get("passed", false)) or int(smoke_suite.get("count", 0)) != 74:
			failures.append("release candidate evidence should persist full smoke count")
		var notes: Dictionary = stored.get("playtest_notes", {})
		if str(notes.get("asset_animation_notes", "")) != "idle/run/dash/attack frames stable":
			failures.append("release candidate evidence should persist animation review notes")
		if str(notes.get("polygon_collision_notes", "")) != "runtime polygons match sprite silhouettes":
			failures.append("release candidate evidence should persist polygon review notes")
		if str(notes.get("wave_hud_audio_notes", "")) \
				!= "wave counter, enemies left, and wave cues verified":
			failures.append("release candidate evidence should persist wave/HUD/audio notes")
		if Array(stored.get("manual_scenario_results", [])).size() != 6:
			failures.append("release candidate evidence should persist manual scenario results")
		var first_scenario: Dictionary = Array(stored.get("manual_scenario_results", []))[0]
		if str(first_scenario.get("goal", "")) == "":
			failures.append("release candidate scenario evidence should persist scenario goal")
		if str(first_scenario.get("result", "")) != "pass":
			failures.append("release candidate scenario evidence should persist scenario result")
		if str(first_scenario.get("notes", "")) == "":
			failures.append("release candidate scenario evidence should persist scenario notes")
		if str(first_scenario.get("evidence_source", "")) != "manual_playtest":
			failures.append("release candidate scenario evidence should persist manual evidence source")
		var rehearsal: Dictionary = stored.get("headless_scenario_rehearsal", {})
		if not bool(rehearsal.get("passed", false)) \
				or str(rehearsal.get("review_type", "")) != "headless_scenario_contract_rehearsal":
			failures.append("release candidate evidence should persist headless scenario rehearsal")
		if bool(rehearsal.get("manual_playtest_replacement", true)):
			failures.append("headless scenario rehearsal should persist as non-manual evidence")
		var asset_review: Dictionary = stored.get("asset_self_review", {})
		if not bool(asset_review.get("passed", false)) \
				or str(asset_review.get("review_type", "")) != "headless_asset_contract_review":
			failures.append("release candidate evidence should persist asset self-review evidence")
		if not bool(asset_review.get("polygon_reviewed", false)) \
				or not bool(asset_review.get("no_direct_fanmade_copy", false)):
			failures.append("release candidate evidence should persist polygon/source review flags")
		var export_package: Dictionary = stored.get("export_package", {})
		if not bool(export_package.get("passed", false)) or not bool(export_package.get("booted", false)):
			failures.append("release candidate evidence should persist successful package and boot evidence")
		if str(export_package.get("executable_path", "")) != "build/windows/DungeonCoreElementalRebirth.exe":
			failures.append("release candidate evidence should persist packaged executable path")
		var reloaded: Dictionary = script.load_data(SAVE_PATH)
		var reloaded_evidence: Dictionary = script.call("release_candidate_evidence", reloaded)
		if int(Dictionary(reloaded_evidence.get("full_smoke_suite", {})).get("count", 0)) != 74:
			failures.append("release candidate evidence should reload from disk")
		var release_audit = load("res://scripts/assets/release_audit.gd")
		var candidate_summary: Dictionary = release_audit.call("release_candidate_summary", reloaded)
		if not bool(candidate_summary.get("release_candidate_ready", false)):
			failures.append("release audit should accept persisted release candidate evidence")
		if script.has_method("release_candidate_evidence_summary"):
			var evidence_line := str(script.call("release_candidate_evidence_summary", reloaded))
			for token in ["Release Evidence:", "Smoke 74/70 OK", "Notes OK",
					"Scenarios 6/6", "Rehearsal OK", "Asset OK", "Package OK"]:
				if not evidence_line.contains(token):
					failures.append("release candidate evidence summary missing token: %s" % token)
			var zero_count_evidence := _release_candidate_evidence_sample()
			zero_count_evidence["asset_self_review"]["animation_frame_grid_checked_count"] = 0
			zero_count_evidence["asset_self_review"]["collision_polygon_checked_count"] = 0
			zero_count_evidence["asset_self_review"]["object_visual_checked_count"] = 0
			var zero_count_recorded: Dictionary = script.call(
				"record_release_candidate_evidence", zero_count_evidence, SAVE_PATH)
			var zero_count_line := str(script.call(
				"release_candidate_evidence_summary", zero_count_recorded))
			if not zero_count_line.contains("Asset Missing"):
				failures.append("release candidate evidence should reject asset review without frame/polygon coverage counts")
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	if not _script_has_method(script, "record_release_candidate_playtest_notes_result"):
		failures.append("MetaProgression should expose record_release_candidate_playtest_notes_result")
	else:
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		script.call("record_release_candidate_evidence", {
			"full_smoke_suite": {"passed": true, "count": 75},
		}, SAVE_PATH)
		var notes_result: Dictionary = Dictionary(
			_release_candidate_evidence_sample().get("playtest_notes", {})).duplicate(true)
		var recorded_notes: Dictionary = script.call(
			"record_release_candidate_playtest_notes_result", notes_result, SAVE_PATH)
		var notes_evidence: Dictionary = script.call(
			"release_candidate_evidence", recorded_notes)
		if int(Dictionary(notes_evidence.get("full_smoke_suite", {})).get("count", 0)) != 75:
			failures.append("playtest notes recorder should preserve existing release evidence")
		var stored_notes: Dictionary = notes_evidence.get("playtest_notes", {})
		if str(stored_notes.get("asset_animation_notes", "")) \
				!= "idle/run/dash/attack frames stable":
			failures.append("playtest notes recorder should persist complete notes")
		if str(stored_notes.get("wave_hud_audio_notes", "")) \
				!= "wave counter, enemies left, and wave cues verified":
			failures.append("playtest notes recorder should persist wave/HUD/audio notes")
		var incomplete_notes := notes_result.duplicate(true)
		incomplete_notes.erase("polygon_collision_notes")
		incomplete_notes["asset_animation_notes"] = "incomplete notes should not overwrite"
		var rejected_notes: Dictionary = script.call(
			"record_release_candidate_playtest_notes_result", incomplete_notes, SAVE_PATH)
		var rejected_notes_evidence: Dictionary = script.call(
			"release_candidate_evidence", rejected_notes)
		var rejected_stored_notes: Dictionary = rejected_notes_evidence.get("playtest_notes", {})
		if str(rejected_stored_notes.get("asset_animation_notes", "")) \
				!= "idle/run/dash/attack frames stable":
			failures.append("playtest notes recorder should reject incomplete notes without overwriting a pass")
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var notes_tool_path := "res://scripts/tools/record_playtest_notes_evidence.gd"
	if not ResourceLoader.exists(notes_tool_path):
		failures.append("release workflow should include a playtest notes evidence recorder tool")
	else:
		var notes_tool_source := FileAccess.get_file_as_string(notes_tool_path)
		for token in ["record_release_candidate_playtest_notes_result",
				"playtest_notes_template", "manual_scenario_results",
				"OS.get_cmdline_user_args"]:
			if not notes_tool_source.contains(token):
				failures.append("playtest notes recorder tool missing token: %s" % token)

	var manual_tool_path := "res://scripts/tools/record_manual_scenario_evidence.gd"
	if not ResourceLoader.exists(manual_tool_path):
		failures.append("release workflow should include a manual scenario evidence recorder tool")
	else:
		var manual_tool_source := FileAccess.get_file_as_string(manual_tool_path)
		for token in ["record_release_candidate_manual_scenario_result",
				"manual_playtest_checklist", "scenario-index", "evidence_source",
				"headless_rehearsal"]:
			if not manual_tool_source.contains(token):
				failures.append("manual scenario recorder tool missing token: %s" % token)
	var status_tool_path := "res://scripts/tools/release_candidate_status.gd"
	if not ResourceLoader.exists(status_tool_path):
		failures.append("release workflow should include a release candidate status tool")
	else:
		var status_tool_source := FileAccess.get_file_as_string(status_tool_path)
		for token in ["release_candidate_manual_recording_plan",
				"release_candidate_evidence_summary", "Notes Command",
				"manual_scenario_results"]:
			if not status_tool_source.contains(token):
				failures.append("release candidate status tool missing token: %s" % token)

	if not _script_has_method(script, "record_release_candidate_asset_self_review_result"):
		failures.append("MetaProgression should expose record_release_candidate_asset_self_review_result")
	else:
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		script.call("record_release_candidate_evidence", {
			"full_smoke_suite": {"passed": true, "count": 75},
		}, SAVE_PATH)
		var asset_result: Dictionary = Dictionary(
			_release_candidate_evidence_sample().get("asset_self_review", {})).duplicate(true)
		var recorded_asset: Dictionary = script.call(
			"record_release_candidate_asset_self_review_result", asset_result, SAVE_PATH)
		var asset_evidence: Dictionary = script.call(
			"release_candidate_evidence", recorded_asset)
		if int(Dictionary(asset_evidence.get("full_smoke_suite", {})).get("count", 0)) != 75:
			failures.append("asset self-review recorder should preserve existing release evidence")
		var stored_asset: Dictionary = asset_evidence.get("asset_self_review", {})
		if not bool(stored_asset.get("passed", false)) \
				or int(stored_asset.get("collision_polygon_checked_count", 0)) <= 0:
			failures.append("asset self-review recorder should persist passing frame/polygon evidence")
		var failed_asset := asset_result.duplicate(true)
		failed_asset["passed"] = false
		failed_asset["animation_frame_grid_checked_count"] = 0
		failed_asset["collision_polygon_checked_count"] = 0
		failed_asset["object_visual_checked_count"] = 0
		var rejected_asset: Dictionary = script.call(
			"record_release_candidate_asset_self_review_result", failed_asset, SAVE_PATH)
		var rejected_evidence: Dictionary = script.call(
			"release_candidate_evidence", rejected_asset)
		var rejected_stored: Dictionary = rejected_evidence.get("asset_self_review", {})
		if int(rejected_stored.get("collision_polygon_checked_count", 0)) \
				!= int(asset_result.get("collision_polygon_checked_count", 0)):
			failures.append("asset self-review recorder should reject failed asset evidence without overwriting a pass")
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var asset_tool_path := "res://scripts/tools/record_asset_self_review_evidence.gd"
	if not ResourceLoader.exists(asset_tool_path):
		failures.append("release workflow should include an asset self-review evidence recorder tool")
	else:
		var asset_tool_source := FileAccess.get_file_as_string(asset_tool_path)
		for token in ["record_release_candidate_asset_self_review_result",
				"release_asset_self_review", "animation_frame_grid_checked_count",
				"collision_polygon_checked_count", "manual_scenario_results"]:
			if not asset_tool_source.contains(token):
				failures.append("asset self-review recorder tool missing token: %s" % token)

	if not _script_has_method(script, "record_release_candidate_headless_rehearsal_result"):
		failures.append("MetaProgression should expose record_release_candidate_headless_rehearsal_result")
	else:
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		script.call("record_release_candidate_evidence", {
			"export_package": {
				"passed": true,
				"booted": true,
				"preset_name": "Windows Desktop",
				"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
			},
		}, SAVE_PATH)
		var rehearsal_result: Dictionary = Dictionary(
			_release_candidate_evidence_sample().get("headless_scenario_rehearsal", {})).duplicate(true)
		var recorded_rehearsal: Dictionary = script.call(
			"record_release_candidate_headless_rehearsal_result",
			rehearsal_result, SAVE_PATH)
		var rehearsal_evidence: Dictionary = script.call(
			"release_candidate_evidence", recorded_rehearsal)
		if str(Dictionary(rehearsal_evidence.get("export_package", {})).get(
				"executable_path", "")) != "build/windows/DungeonCoreElementalRebirth.exe":
			failures.append("headless rehearsal recorder should preserve existing release evidence")
		var stored_rehearsal: Dictionary = rehearsal_evidence.get("headless_scenario_rehearsal", {})
		if not bool(stored_rehearsal.get("passed", false)) \
				or bool(stored_rehearsal.get("manual_playtest_replacement", true)):
			failures.append("headless rehearsal recorder should persist non-manual contract evidence")
		if int(stored_rehearsal.get("completed_count", 0)) <= 0 \
				or int(stored_rehearsal.get("required_count", 0)) <= 0:
			failures.append("headless rehearsal recorder should persist scenario coverage counts")
		var failed_rehearsal := rehearsal_result.duplicate(true)
		failed_rehearsal["manual_playtest_replacement"] = true
		failed_rehearsal["passed"] = false
		var rejected_rehearsal: Dictionary = script.call(
			"record_release_candidate_headless_rehearsal_result",
			failed_rehearsal, SAVE_PATH)
		var rejected_rehearsal_evidence: Dictionary = script.call(
			"release_candidate_evidence", rejected_rehearsal)
		var rejected_rehearsal_stored: Dictionary = rejected_rehearsal_evidence.get(
			"headless_scenario_rehearsal", {})
		if bool(rejected_rehearsal_stored.get("manual_playtest_replacement", true)):
			failures.append("headless rehearsal recorder should reject manual-replacement evidence without overwriting a pass")
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var rehearsal_tool_path := "res://scripts/tools/record_headless_rehearsal_evidence.gd"
	if not ResourceLoader.exists(rehearsal_tool_path):
		failures.append("release workflow should include a headless rehearsal evidence recorder tool")
	else:
		var rehearsal_tool_source := FileAccess.get_file_as_string(rehearsal_tool_path)
		for token in ["record_release_candidate_headless_rehearsal_result",
				"release_candidate_rehearsal_results", "manual_playtest_replacement",
				"manual_scenario_results"]:
			if not rehearsal_tool_source.contains(token):
				failures.append("headless rehearsal recorder tool missing token: %s" % token)

	if not _script_has_method(script, "record_release_candidate_smoke_suite_result"):
		failures.append("MetaProgression should expose record_release_candidate_smoke_suite_result")
	else:
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		script.call("record_release_candidate_evidence", {
			"export_package": {
				"passed": true,
				"booted": true,
				"preset_name": "Windows Desktop",
				"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
			},
		}, SAVE_PATH)
		var smoke_result := {
			"passed": true,
			"count": 75,
		}
		var recorded_smoke: Dictionary = script.call(
			"record_release_candidate_smoke_suite_result", smoke_result, SAVE_PATH)
		var smoke_evidence: Dictionary = script.call(
			"release_candidate_evidence", recorded_smoke)
		var stored_smoke: Dictionary = smoke_evidence.get("full_smoke_suite", {})
		if not bool(stored_smoke.get("passed", false)) or int(stored_smoke.get("count", 0)) != 75:
			failures.append("smoke suite recorder should persist full smoke count")
		var preserved_package: Dictionary = smoke_evidence.get("export_package", {})
		if str(preserved_package.get("executable_path", "")) \
				!= "build/windows/DungeonCoreElementalRebirth.exe":
			failures.append("smoke suite recorder should preserve package evidence")
		var failed_smoke := smoke_result.duplicate(true)
		failed_smoke["passed"] = false
		failed_smoke["count"] = 12
		var rejected_smoke: Dictionary = script.call(
			"record_release_candidate_smoke_suite_result", failed_smoke, SAVE_PATH)
		var rejected_evidence: Dictionary = script.call(
			"release_candidate_evidence", rejected_smoke)
		var rejected_stored: Dictionary = rejected_evidence.get("full_smoke_suite", {})
		if int(rejected_stored.get("count", 0)) != 75:
			failures.append("smoke suite recorder should reject failed smoke evidence without overwriting a pass")
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var smoke_tool_path := "res://scripts/tools/record_smoke_suite_evidence.gd"
	if not ResourceLoader.exists(smoke_tool_path):
		failures.append("release workflow should include a smoke suite evidence recorder tool")
	else:
		var smoke_tool_source := FileAccess.get_file_as_string(smoke_tool_path)
		for token in ["record_release_candidate_smoke_suite_result", "full_smoke_suite",
				"manual_scenario_results"]:
			if not smoke_tool_source.contains(token):
				failures.append("smoke evidence recorder tool missing token: %s" % token)
	var smoke_runner_path := "res://scripts/tools/run_full_smoke_suite_and_record.ps1"
	if not FileAccess.file_exists(smoke_runner_path):
		failures.append("release workflow should include a full smoke suite runner script")
	else:
		var smoke_runner_source := FileAccess.get_file_as_string(smoke_runner_path)
		for token in ["Get-ChildItem 'scripts/tests'", "ALL_SMOKE_OK",
				"record_smoke_suite_evidence.gd",
				"record_asset_self_review_evidence.gd",
				"record_headless_rehearsal_evidence.gd",
				"record_export_package_evidence.gd"]:
			if not smoke_runner_source.contains(token):
				failures.append("full smoke suite runner missing token: %s" % token)

	if not _script_has_method(script, "record_release_candidate_export_package_result"):
		failures.append("MetaProgression should expose record_release_candidate_export_package_result")
	else:
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		script.call("record_release_candidate_evidence", {
			"full_smoke_suite": {"passed": true, "count": 75},
		}, SAVE_PATH)
		var package_result := {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		}
		var recorded_package: Dictionary = script.call(
			"record_release_candidate_export_package_result", package_result, SAVE_PATH)
		var package_evidence: Dictionary = script.call(
			"release_candidate_evidence", recorded_package)
		if int(Dictionary(package_evidence.get("full_smoke_suite", {})).get("count", 0)) != 75:
			failures.append("export package recorder should preserve existing release evidence")
		var stored_package: Dictionary = package_evidence.get("export_package", {})
		if not bool(stored_package.get("passed", false)) \
				or not bool(stored_package.get("booted", false)):
			failures.append("export package recorder should persist successful boot evidence")
		if str(stored_package.get("executable_path", "")) \
				!= "build/windows/DungeonCoreElementalRebirth.exe":
			failures.append("export package recorder should persist packaged executable path")
		var failed_package := package_result.duplicate(true)
		failed_package["booted"] = false
		failed_package["executable_path"] = "build/windows/broken.exe"
		var rejected_package: Dictionary = script.call(
			"record_release_candidate_export_package_result", failed_package, SAVE_PATH)
		var rejected_evidence: Dictionary = script.call(
			"release_candidate_evidence", rejected_package)
		var rejected_stored: Dictionary = rejected_evidence.get("export_package", {})
		if str(rejected_stored.get("executable_path", "")) \
				!= "build/windows/DungeonCoreElementalRebirth.exe":
			failures.append("export package recorder should reject failed boot evidence without overwriting a pass")
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var package_tool_path := "res://scripts/tools/record_export_package_evidence.gd"
	if not ResourceLoader.exists(package_tool_path):
		failures.append("release workflow should include a package evidence recorder tool")
	else:
		var package_tool_source := FileAccess.get_file_as_string(package_tool_path)
		for token in ["record_release_candidate_export_package_result",
				"FileAccess.file_exists", "DungeonCoreElementalRebirth.exe",
				"manual_scenario_results"]:
			if not package_tool_source.contains(token):
				failures.append("package evidence recorder tool missing token: %s" % token)

	if not _script_has_method(script, "record_release_candidate_manual_scenario_result"):
		failures.append("MetaProgression should expose record_release_candidate_manual_scenario_result")
	else:
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		script.call("record_release_candidate_evidence", {
			"full_smoke_suite": {"passed": true, "count": 75},
		}, SAVE_PATH)
		var manual_result := {
			"seed": 420101,
			"mode": "normal",
			"class_id": "blade_warden",
			"goal": "clear floor 1 and choose one upgrade",
			"result": "pass",
			"evidence_source": "manual_playtest",
			"notes": "human playtest completed with no blocker",
			"screenshot_or_seed": "seed_420101_manual_pass",
		}
		var recorded_manual: Dictionary = script.call(
			"record_release_candidate_manual_scenario_result", manual_result, SAVE_PATH)
		var manual_evidence: Dictionary = script.call(
			"release_candidate_evidence", recorded_manual)
		if int(Dictionary(manual_evidence.get("full_smoke_suite", {})).get("count", 0)) != 75:
			failures.append("manual scenario recorder should preserve existing release evidence")
		var manual_results: Array = manual_evidence.get("manual_scenario_results", [])
		if manual_results.size() != 1:
			failures.append("manual scenario recorder should append one valid manual result")
		else:
			var stored_manual: Dictionary = manual_results[0]
			if str(stored_manual.get("evidence_source", "")) != "manual_playtest":
				failures.append("manual scenario recorder should persist manual evidence source")
			if str(stored_manual.get("notes", "")) != "human playtest completed with no blocker":
				failures.append("manual scenario recorder should persist manual notes")
			if str(stored_manual.get("screenshot_or_seed", "")) != "seed_420101_manual_pass":
				failures.append("manual scenario recorder should persist screenshot/seed evidence")
		var updated_manual := manual_result.duplicate(true)
		updated_manual["notes"] = "human playtest rerun updated notes"
		var replaced_manual: Dictionary = script.call(
			"record_release_candidate_manual_scenario_result", updated_manual, SAVE_PATH)
		var replaced_evidence: Dictionary = script.call(
			"release_candidate_evidence", replaced_manual)
		var replaced_results: Array = replaced_evidence.get("manual_scenario_results", [])
		if replaced_results.size() != 1:
			failures.append("manual scenario recorder should replace duplicate scenario evidence")
		elif str(Dictionary(replaced_results[0]).get("notes", "")) \
				!= "human playtest rerun updated notes":
			failures.append("manual scenario recorder should keep the latest duplicate notes")
		var headless_result := manual_result.duplicate(true)
		headless_result["evidence_source"] = "headless_rehearsal"
		headless_result["notes"] = "headless evidence should not overwrite human notes"
		var rejected_headless: Dictionary = script.call(
			"record_release_candidate_manual_scenario_result", headless_result, SAVE_PATH)
		var rejected_evidence: Dictionary = script.call(
			"release_candidate_evidence", rejected_headless)
		var rejected_results: Array = rejected_evidence.get("manual_scenario_results", [])
		if rejected_results.size() != 1 \
				or str(Dictionary(rejected_results[0]).get("notes", "")) \
				!= "human playtest rerun updated notes":
			failures.append("manual scenario recorder should reject headless rehearsal as manual evidence")
		var pending_result := manual_result.duplicate(true)
		pending_result["result"] = "pending"
		pending_result["notes"] = "pending evidence should not overwrite human notes"
		var rejected_pending: Dictionary = script.call(
			"record_release_candidate_manual_scenario_result", pending_result, SAVE_PATH)
		var pending_evidence: Dictionary = script.call(
			"release_candidate_evidence", rejected_pending)
		var pending_results: Array = pending_evidence.get("manual_scenario_results", [])
		if pending_results.size() != 1 \
				or str(Dictionary(pending_results[0]).get("notes", "")) \
				!= "human playtest rerun updated notes":
			failures.append("manual scenario recorder should reject pending as completed manual evidence")
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	var fresh: Dictionary = script.load_data(SAVE_PATH)
	if int(fresh.get("banked_gold", -1)) != 0:
		failures.append("fresh meta save should start with 0 banked gold")
	for key in ["best_floor", "last_floor", "current_win_streak", "best_win_streak",
			"last_seed", "last_seed_label", "last_class_id", "last_class", "last_element",
			"last_daily_seed", "daily_seed_attempts", "daily_seed_victories",
			"last_build_archetype", "last_build_summary", "last_build_tags",
			"last_mode", "last_path", "class_records", "mode_records",
			"element_records", "biome_records", "boss_records", "recent_runs"]:
		if not fresh.has(key):
			failures.append("fresh meta save missing run record %s" % key)
	for key in ["soul_shards", "element_cores", "rune_dust", "blueprints"]:
		if not fresh.has(key):
			failures.append("fresh meta save missing currency %s" % key)

	var first: Dictionary = script.bank_run(80, "defeat", SAVE_PATH)
	if int(first.get("banked_gold", 0)) != 40:
		failures.append("defeat should bank 50 percent of earned gold")
	if int(first.get("runs_finished", 0)) != 1:
		failures.append("bank_run should count finished runs")
	var second: Dictionary = script.bank_run(10, "victory", SAVE_PATH)
	if int(second.get("banked_gold", 0)) != 50:
		failures.append("bank_run should persist and accumulate gold")
	if int(second.get("victories", 0)) != 1:
		failures.append("bank_run should count victories")
	var reloaded: Dictionary = script.load_data(SAVE_PATH)
	if int(reloaded.get("banked_gold", 0)) != 50:
		failures.append("meta save should reload accumulated gold")

	if not _script_has_method(script, "bank_run_rewards"):
		failures.append("MetaProgression should expose bank_run_rewards")
		return
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var defeat_rewards := {
		"gold": 80,
		"floor": 2,
		"soul_shards": 3,
		"element_cores": 1,
		"rune_dust": 7,
		"blueprints": 2,
	}
	var defeat_data: Dictionary = script.bank_run_rewards(defeat_rewards, "defeat", SAVE_PATH)
	if int(defeat_data.get("banked_gold", 0)) != 40:
		failures.append("bank_run_rewards should halve gold on defeat")
	if int(defeat_data.get("soul_shards", 0)) != 3:
		failures.append("bank_run_rewards should keep all soul shards")
	if int(defeat_data.get("element_cores", 0)) != 1:
		failures.append("bank_run_rewards should keep all element cores")
	if int(defeat_data.get("rune_dust", 0)) != 7:
		failures.append("bank_run_rewards should keep all rune dust")
	if int(defeat_data.get("blueprints", 0)) != 2:
		failures.append("bank_run_rewards should keep all blueprints")
	if int(defeat_data.get("best_floor", 0)) != 2 or int(defeat_data.get("last_floor", 0)) != 2:
		failures.append("bank_run_rewards should record defeat floor")
	if int(defeat_data.get("current_win_streak", -1)) != 0:
		failures.append("defeat should reset win streak")
	var victory_data: Dictionary = script.bank_run_rewards({
		"gold": 10,
		"floor": 3,
		"soul_shards": 4,
	}, "victory", SAVE_PATH)
	if int(victory_data.get("banked_gold", 0)) != 50:
		failures.append("victory should bank all gold")
	if int(victory_data.get("soul_shards", 0)) != 7:
		failures.append("meta currencies should accumulate across runs")
	if int(victory_data.get("best_floor", 0)) != 3:
		failures.append("victory should update best floor")
	if int(victory_data.get("current_win_streak", 0)) != 1:
		failures.append("victory should increment current win streak")
	var streak_data: Dictionary = script.bank_run_rewards({"gold": 0, "floor": 3}, "victory", SAVE_PATH)
	if int(streak_data.get("best_win_streak", 0)) != 2:
		failures.append("consecutive victories should update best win streak")
	var daily_data: Dictionary = script.bank_run_rewards(
		{
			"gold": 5,
			"floor": 3,
			"rune_dust": 2,
			"challenge_bonus": "+12 gold, Dust +2",
		},
		"victory",
		SAVE_PATH,
		{
			"seed": 20260705,
			"seed_label": "Daily Seed",
			"daily_fingerprint": {
				"hash": "daily-abc",
				"floor_index": 3,
				"room_count": 19,
				"spawn_count": 42,
				"boss_variant": "forge_golem",
			},
			"class_id": "blade_warden",
			"class": "Blade Warden",
			"element": "fire",
			"mode": "Boss Rush",
			"path": "Path: Entrance -> Combat -> Boss",
			"biome_id": "ember_forge",
			"biome": "Ember Forge",
			"boss_variant": "forge_golem",
			"boss": "Forge Golem",
			"archetype": "Fire Duelist",
			"build": "Power Rune x2, Dash Spring",
			"tags": "damage/fire/dash",
			"boss_story": "Phase 2: Rock Volley -> Bullet Hell x8",
			"damage_taken": "Trap: Spike 10 / Enemy 5",
			"survival": "Revived x1 / Blocked 40",
			"floor_recap": "Floor 4 recap: Rooms 7/12 | Kills +18",
			"mastery": "Perfect 2 | Close Call 1",
			"pace": "Avg 12.5s | Boss 85.0s | Slowest Boss 85.0s | Target 2 | Slow 1",
			"pace_timed_rooms": 3,
			"pace_avg_sec": 12.5,
			"pace_boss_sec": 85.0,
			"pace_slowest_sec": 85.0,
			"pace_slowest_room": "Boss",
			"pace_fast_count": 0,
			"pace_target_count": 2,
			"pace_slow_count": 1,
			"economy_gold_earned": 64,
			"economy_soul_shards": 4,
			"economy_element_cores": 1,
			"economy_rune_dust": 6,
			"economy_blueprints": 1,
			"decision_reward_picks": 3,
			"decision_reward_skips": 1,
			"decision_reward_rerolls": 2,
			"decision_shop_buys": 2,
			"decision_shop_leaves": 1,
			"tuning_focus": "Tuning Focus: P1 cave_golem_boss boss_ttk | Pace evidence needed",
			"playtest_objective": "Playtest Objective: P1 cave_golem_boss boss_ttk | Current 85.0s | Target 120.0-240.0s | RunSummary Pace boss clear time",
			"tuning_patch": "Tuning Patch: P1 cave_golem_boss | test 1.41x boss_effective_hp_or_phase_downtime | Evidence required: RunSummary Pace boss clear time",
			"balance_experiment": "Balance Lab: cave_golem_boss HP 1.25x from playtest_evidence",
			"balance_experiment_id": "balance_lab",
			"balance_experiment_patch_id": "cave_golem_boss",
			"balance_experiment_hp_multiplier": 1.25,
			"balance_experiment_source": "playtest_evidence",
			"release_audit": "Internal playtest: ready | Public release: blocked | replace before public: 1 | fanmade: reference-only no copy",
			"release_decision": "blocked",
			"release_replacements": 1,
			"release_backlog": "collision:breakable_prop:add_or_fix_collision_polygon_before_public",
			"release_next_action": "Next Action: Fix collision:breakable_prop | add_or_fix_collision_polygon_before_public",
			"release_candidate_status": "evidence_required",
			"release_candidate_next_action": "Next Action: Record playtest notes | seed/class/mode/animation/polygon evidence",
			"release_candidate_blockers": "playtest_notes_missing, manual_scenarios_missing",
		})
	if int(daily_data.get("last_seed", 0)) != 20260705:
		failures.append("meta progression should persist last run seed")
	if str(daily_data.get("last_seed_label", "")) != "Daily Seed":
		failures.append("meta progression should persist readable seed label")
	if str(daily_data.get("last_class", "")) != "Blade Warden":
		failures.append("meta progression should persist last class label")
	if str(daily_data.get("last_class_id", "")) != "blade_warden":
		failures.append("meta progression should persist last class id")
	if str(daily_data.get("last_element", "")) != "fire":
		failures.append("meta progression should persist last element")
	if str(daily_data.get("last_mode", "")) != "Boss Rush":
		failures.append("meta progression should persist last run mode")
	if str(daily_data.get("last_path", "")) != "Path: Entrance -> Combat -> Boss":
		failures.append("meta progression should persist last room route")
	if str(daily_data.get("last_build_archetype", "")) != "Fire Duelist":
		failures.append("meta progression should persist last build archetype")
	if str(daily_data.get("last_build_summary", "")) != "Power Rune x2, Dash Spring":
		failures.append("meta progression should persist last build summary")
	if str(daily_data.get("last_build_tags", "")) != "damage/fire/dash":
		failures.append("meta progression should persist readable build tags")
	if int(daily_data.get("last_daily_seed", 0)) != 20260705:
		failures.append("meta progression should persist last daily seed")
	if int(daily_data.get("daily_seed_attempts", 0)) != 1:
		failures.append("daily seed runs should increment attempt count")
	if int(daily_data.get("daily_seed_victories", 0)) != 1:
		failures.append("daily seed victories should increment win count")
	if str(daily_data.get("last_daily_fingerprint_hash", "")) != "daily-abc":
		failures.append("meta progression should persist last Daily Seed fingerprint hash")
	var saved_daily_fingerprint: Dictionary = daily_data.get("last_daily_fingerprint", {})
	if int(saved_daily_fingerprint.get("room_count", 0)) != 19 \
			or int(saved_daily_fingerprint.get("spawn_count", 0)) != 42:
		failures.append("meta progression should persist structured Daily Seed fingerprint")
	var daily_rewards: Dictionary = daily_data.get("last_rewards", {})
	if str(daily_rewards.get("challenge_bonus", "")) != "+12 gold, Dust +2":
		failures.append("meta progression should persist daily challenge bonus summary")
	if int(daily_data.get("rune_dust", 0)) < 2:
		failures.append("daily challenge bonus rune dust should be banked")
	var daily_recent: Array = daily_data.get("recent_runs", [])
	if daily_recent.is_empty():
		failures.append("meta progression should keep a recent run history")
	else:
		var latest_daily: Dictionary = daily_recent[0]
		if str(latest_daily.get("result", "")) != "victory":
			failures.append("recent run should store result")
		if int(latest_daily.get("floor", 0)) != 3:
			failures.append("recent run should store floor")
		if int(latest_daily.get("seed", 0)) != 20260705:
			failures.append("recent run should store seed")
		if str(latest_daily.get("class", "")) != "Blade Warden":
			failures.append("recent run should store class label")
		if str(latest_daily.get("element", "")) != "fire":
			failures.append("recent run should store element")
		if str(latest_daily.get("mode", "")) != "Boss Rush":
			failures.append("recent run should store mode")
		if str(latest_daily.get("path", "")) != "Path: Entrance -> Combat -> Boss":
			failures.append("recent run should store room path")
		if str(latest_daily.get("archetype", "")) != "Fire Duelist":
			failures.append("recent run should store build archetype")
		if str(latest_daily.get("build", "")) != "Power Rune x2, Dash Spring":
			failures.append("recent run should store build summary")
		if str(latest_daily.get("tags", "")) != "damage/fire/dash":
			failures.append("recent run should store build tags")
		if str(latest_daily.get("biome_id", "")) != "ember_forge":
			failures.append("recent run should store biome id for balance evidence")
		if str(latest_daily.get("biome", "")) != "Ember Forge":
			failures.append("recent run should store biome label for balance evidence")
		if str(latest_daily.get("boss_variant", "")) != "forge_golem":
			failures.append("recent run should store boss variant for balance evidence")
		if str(latest_daily.get("boss", "")) != "Forge Golem":
			failures.append("recent run should store boss label for balance evidence")
		if str(latest_daily.get("challenge_bonus", "")) != "+12 gold, Dust +2":
			failures.append("recent run should store daily challenge bonus summary")
		if str(latest_daily.get("daily_fingerprint_hash", "")) != "daily-abc":
			failures.append("recent run should store Daily Seed fingerprint hash")
		var recent_fingerprint: Dictionary = latest_daily.get("daily_fingerprint", {})
		if int(recent_fingerprint.get("floor_index", 0)) != 3 \
				or int(recent_fingerprint.get("room_count", 0)) != 19 \
				or int(recent_fingerprint.get("spawn_count", 0)) != 42 \
				or str(recent_fingerprint.get("boss_variant", "")) != "forge_golem":
			failures.append("recent run should store structured Daily Seed fingerprint")
		var expected_review_fields := {
			"boss_story": "Phase 2: Rock Volley -> Bullet Hell x8",
			"damage_taken": "Trap: Spike 10 / Enemy 5",
			"survival": "Revived x1 / Blocked 40",
			"floor_recap": "Floor 4 recap: Rooms 7/12 | Kills +18",
			"mastery": "Perfect 2 | Close Call 1",
			"pace": "Avg 12.5s | Boss 85.0s | Slowest Boss 85.0s | Target 2 | Slow 1",
			"tuning_focus": "Tuning Focus: P1 cave_golem_boss boss_ttk | Pace evidence needed",
			"playtest_objective": "Playtest Objective: P1 cave_golem_boss boss_ttk | Current 85.0s | Target 120.0-240.0s | RunSummary Pace boss clear time",
			"tuning_patch": "Tuning Patch: P1 cave_golem_boss | test 1.41x boss_effective_hp_or_phase_downtime | Evidence required: RunSummary Pace boss clear time",
			"balance_experiment": "Balance Lab: cave_golem_boss HP 1.25x from playtest_evidence",
			"release_audit": "Internal playtest: ready | Public release: blocked | replace before public: 1 | fanmade: reference-only no copy",
			"release_decision": "blocked",
			"release_backlog": "collision:breakable_prop:add_or_fix_collision_polygon_before_public",
			"release_next_action": "Next Action: Fix collision:breakable_prop | add_or_fix_collision_polygon_before_public",
			"release_candidate_status": "evidence_required",
			"release_candidate_next_action": "Next Action: Record playtest notes | seed/class/mode/animation/polygon evidence",
			"release_candidate_blockers": "playtest_notes_missing, manual_scenarios_missing",
		}
		for key in expected_review_fields:
			if str(latest_daily.get(key, "")) != str(expected_review_fields[key]):
				failures.append("recent run should store review telemetry: %s" % key)
		var expected_balance_experiment_fields := {
			"balance_experiment_id": "balance_lab",
			"balance_experiment_patch_id": "cave_golem_boss",
			"balance_experiment_source": "playtest_evidence",
			"balance_experiment_hp_multiplier": 1.25,
		}
		for key in expected_balance_experiment_fields:
			if latest_daily.get(key) != expected_balance_experiment_fields[key]:
				failures.append("recent run should store Balance Lab experiment telemetry: %s" % key)
		var expected_pace_fields := {
			"pace_timed_rooms": 3,
			"pace_avg_sec": 12.5,
			"pace_boss_sec": 85.0,
			"pace_slowest_sec": 85.0,
			"pace_slowest_room": "Boss",
			"pace_fast_count": 0,
			"pace_target_count": 2,
			"pace_slow_count": 1,
		}
		for key in expected_pace_fields:
			if latest_daily.get(key) != expected_pace_fields[key]:
				failures.append("recent run should store structured pace telemetry: %s" % key)
		var expected_economy_fields := {
			"economy_gold_earned": 64,
			"economy_soul_shards": 4,
			"economy_element_cores": 1,
			"economy_rune_dust": 6,
			"economy_blueprints": 1,
			"decision_reward_picks": 3,
			"decision_reward_skips": 1,
			"decision_reward_rerolls": 2,
			"decision_shop_buys": 2,
			"decision_shop_leaves": 1,
		}
		for key in expected_economy_fields:
			if latest_daily.get(key) != expected_economy_fields[key]:
				failures.append("recent run should store structured economy telemetry: %s" % key)
		if int(latest_daily.get("release_replacements", -1)) != 1:
			failures.append("recent run should store release replacement count")
	var class_records: Dictionary = daily_data.get("class_records", {})
	var blade_record: Dictionary = class_records.get("blade_warden", {})
	if blade_record.is_empty():
		failures.append("meta progression should store per-class records")
	else:
		if int(blade_record.get("runs", 0)) != 1:
			failures.append("class record should count runs")
		if int(blade_record.get("victories", 0)) != 1:
			failures.append("class record should count victories")
		if int(blade_record.get("best_floor", 0)) != 3:
			failures.append("class record should track best floor")
		if int(blade_record.get("best_seed", 0)) != 20260705:
			failures.append("class record should track seed for best floor")
		if str(blade_record.get("label", "")) != "Blade Warden":
			failures.append("class record should store readable class label")
		if str(blade_record.get("last_path", "")) != "Path: Entrance -> Combat -> Boss":
			failures.append("class record should track last room route")
		if str(blade_record.get("best_path", "")) != "Path: Entrance -> Combat -> Boss":
			failures.append("class record should track route for best floor")
	var mode_records: Dictionary = daily_data.get("mode_records", {})
	var boss_rush_record: Dictionary = mode_records.get("boss_rush", {})
	if boss_rush_record.is_empty():
		failures.append("meta progression should store per-mode records")
	else:
		if str(boss_rush_record.get("label", "")) != "Boss Rush":
			failures.append("mode record should store readable mode label")
		if int(boss_rush_record.get("runs", 0)) != 1:
			failures.append("mode record should count runs")
		if int(boss_rush_record.get("victories", 0)) != 1:
			failures.append("mode record should count victories")
		if int(boss_rush_record.get("best_floor", 0)) != 3:
			failures.append("mode record should track best floor")
		if int(boss_rush_record.get("best_seed", 0)) != 20260705:
			failures.append("mode record should track best seed")
		if str(boss_rush_record.get("last_path", "")) != "Path: Entrance -> Combat -> Boss":
			failures.append("mode record should track last room route")
		if str(boss_rush_record.get("best_path", "")) != "Path: Entrance -> Combat -> Boss":
			failures.append("mode record should track route for best floor")
	var element_records: Dictionary = daily_data.get("element_records", {})
	var fire_record: Dictionary = element_records.get("fire", {})
	if fire_record.is_empty():
		failures.append("meta progression should store per-element records")
	else:
		if str(fire_record.get("label", "")) != "Fire":
			failures.append("element record should store readable element label")
		if int(fire_record.get("runs", 0)) != 1:
			failures.append("element record should count runs")
		if int(fire_record.get("victories", 0)) != 1:
			failures.append("element record should count victories")
		if int(fire_record.get("best_floor", 0)) != 3:
			failures.append("element record should track best floor")
		if int(fire_record.get("best_seed", 0)) != 20260705:
			failures.append("element record should track best seed")
		if str(fire_record.get("last_path", "")) != "Path: Entrance -> Combat -> Boss":
			failures.append("element record should track last room route")
		if str(fire_record.get("best_path", "")) != "Path: Entrance -> Combat -> Boss":
			failures.append("element record should track route for best floor")
	var boss_records: Dictionary = daily_data.get("boss_records", {})
	var forge_record: Dictionary = boss_records.get("forge_golem", {})
	if forge_record.is_empty():
		failures.append("meta progression should store per-boss records")
	else:
		if str(forge_record.get("label", "")) != "Forge Golem":
			failures.append("boss record should store readable boss label")
		if str(forge_record.get("biome", "")) != "Ember Forge":
			failures.append("boss record should store readable biome label")
		if str(forge_record.get("biome_id", "")) != "ember_forge":
			failures.append("boss record should store biome id")
		if int(forge_record.get("runs", 0)) != 1:
			failures.append("boss record should count runs")
		if int(forge_record.get("victories", 0)) != 1:
			failures.append("boss record should count victories")
		if int(forge_record.get("best_floor", 0)) != 3:
			failures.append("boss record should track best floor")
		if int(forge_record.get("best_seed", 0)) != 20260705:
			failures.append("boss record should track best seed")
		if str(forge_record.get("last_path", "")) != "Path: Entrance -> Combat -> Boss":
			failures.append("boss record should track last room route")
		if str(forge_record.get("best_path", "")) != "Path: Entrance -> Combat -> Boss":
			failures.append("boss record should track route for best floor")
	var biome_records: Dictionary = daily_data.get("biome_records", {})
	var ember_record: Dictionary = biome_records.get("ember_forge", {})
	if ember_record.is_empty():
		failures.append("meta progression should store per-biome records")
	else:
		if str(ember_record.get("label", "")) != "Ember Forge":
			failures.append("biome record should store readable biome label")
		if str(ember_record.get("last_boss_variant", "")) != "forge_golem":
			failures.append("biome record should track last boss variant")
		if int(ember_record.get("runs", 0)) != 1:
			failures.append("biome record should count runs")
		if int(ember_record.get("victories", 0)) != 1:
			failures.append("biome record should count victories")
		if int(ember_record.get("best_floor", 0)) != 3:
			failures.append("biome record should track best floor")
		if int(ember_record.get("best_seed", 0)) != 20260705:
			failures.append("biome record should track best seed")
		if str(ember_record.get("last_path", "")) != "Path: Entrance -> Combat -> Boss":
			failures.append("biome record should track last room route")
		if str(ember_record.get("best_path", "")) != "Path: Entrance -> Combat -> Boss":
			failures.append("biome record should track route for best floor")
	var endless_data: Dictionary = script.bank_run_rewards(
		{
			"gold": 0,
			"floor": 6,
			"rune_dust": 2,
			"soul_shards": 1,
			"endless_depth_bonus": "Depth +2: Dust +2 / Shard +1",
		},
		"defeat",
		SAVE_PATH,
		{
			"seed": 888,
			"seed_label": "Seed",
			"class_id": "ranger",
			"class": "Ranger",
			"element": "ice",
			"mode": "Endless",
			"path": "Path: Entrance -> Boss -> Depth 6",
		})
	var endless_rewards: Dictionary = endless_data.get("last_rewards", {})
	if str(endless_rewards.get("endless_depth_bonus", "")) != "Depth +2: Dust +2 / Shard +1":
		failures.append("meta progression should persist endless depth bonus summary")
	if int(endless_data.get("rune_dust", 0)) < 4 or int(endless_data.get("soul_shards", 0)) < 8:
		failures.append("endless depth bonus currencies should be banked")
	var recent_runs: Array = endless_data.get("recent_runs", [])
	if recent_runs.is_empty() or str(Dictionary(recent_runs[0]).get("mode", "")) != "Endless":
		failures.append("recent run history should keep newest run first")
	elif str(Dictionary(recent_runs[0]).get("endless_depth_bonus", "")) != "Depth +2: Dust +2 / Shard +1":
		failures.append("recent run should store endless depth bonus summary")
	if recent_runs.size() > 5:
		failures.append("recent run history should keep only the last five runs")
	if recent_runs.size() >= 2 and str(Dictionary(recent_runs[1]).get("mode", "")) != "Boss Rush":
		failures.append("recent run history should preserve previous run order")
	var endless_record: Dictionary = Dictionary(endless_data.get("mode_records", {})).get("endless", {})
	if endless_record.is_empty():
		failures.append("meta progression should store Endless mode records")
	else:
		if str(endless_record.get("label", "")) != "Endless":
			failures.append("Endless mode record should store readable mode label")
		if int(endless_record.get("best_floor", 0)) != 6:
			failures.append("Endless mode record should track best depth")
	var ice_record: Dictionary = Dictionary(endless_data.get("element_records", {})).get("ice", {})
	if ice_record.is_empty():
		failures.append("meta progression should store Ice element records")
	else:
		if str(ice_record.get("label", "")) != "Ice":
			failures.append("Ice element record should store readable element label")
		if int(ice_record.get("runs", 0)) != 1:
			failures.append("Ice element record should count runs")
		if int(ice_record.get("victories", -1)) != 0:
			failures.append("Ice element defeat record should not count victories")
		if int(ice_record.get("best_floor", 0)) != 6:
			failures.append("Ice element record should track Endless best depth")
	if not _script_has_method(script, "reset_profile"):
		failures.append("MetaProgression should expose reset_profile")
		return
	var reset_data: Dictionary = script.reset_profile(SAVE_PATH)
	if int(reset_data.get("banked_gold", -1)) != 0:
		failures.append("reset_profile should clear banked gold")
	if int(reset_data.get("soul_shards", -1)) != 0:
		failures.append("reset_profile should clear soul shards")
	if not reset_data.get("upgrades", {}).is_empty():
		failures.append("reset_profile should clear upgrades")
	var reset_reloaded: Dictionary = script.load_data(SAVE_PATH)
	if int(reset_reloaded.get("runs_finished", -1)) != 0:
		failures.append("reset_profile should persist a fresh profile")

func _check_main_banks_run_rewards(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var player_source := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	if not source.contains("MetaProgressionScript"):
		failures.append("Main should preload MetaProgression")
	if not source.contains("bank_run_rewards"):
		failures.append("Main should bank full run rewards on run end")
	if not source.contains("_run_rewards_for_banking"):
		failures.append("Main should pass floor reached into meta banking")
	if not source.contains("_apply_run_modifier_reward_bonus"):
		failures.append("Main should apply run modifier reward bonus before banking")
	if not source.contains("_apply_endless_depth_bonus"):
		failures.append("Main should apply Endless depth bonus before banking")
	if not source.contains("MetaProgressionScript.SAVE_PATH, _run_summary_context()"):
		failures.append("Main should pass run seed/class context into meta banking")
	if not source.contains("\"class_id\": player.class_id"):
		failures.append("Main should include class_id in run summary context")
	if not source.contains("\"biome_id\":") or not source.contains("\"boss_variant\":"):
		failures.append("Main should include biome and boss variant in run summary context")
	if not player_source.contains("run_rewards"):
		failures.append("Player should expose current run rewards")

func _release_candidate_evidence_sample() -> Dictionary:
	return {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": {
			"seed": 420101,
			"class_id": "blade_warden",
			"mode": "normal",
			"replay_last_run_result": "same seed/class/mode verified",
			"daily_fingerprint_hash": "daily-420101-ok",
			"pace_avg_sec": 42.0,
			"pace_boss_sec": 85.0,
			"asset_animation_notes": "idle/run/dash/attack frames stable",
			"polygon_collision_notes": "runtime polygons match sprite silhouettes",
			"wave_hud_audio_notes": "wave counter, enemies left, and wave cues verified",
			"blocker_screenshot_or_seed": "none",
			"release_decision": "public_ok",
		},
		"manual_scenario_results": [
			{"seed": 420101, "mode": "normal", "class_id": "blade_warden",
				"goal": "clear floor 1 and choose one upgrade", "result": "pass",
				"evidence_source": "manual_playtest",
				"notes": "objective completed; animation stable; polygon collision matched; wave HUD audio clear",
				"screenshot_or_seed": "seed_420101_manual_pass"},
			{"seed": 420102, "mode": "boss_rush", "class_id": "bulwark",
				"goal": "survive boss phase shift and enrage", "result": "pass",
				"evidence_source": "manual_playtest",
				"notes": "objective completed; animation stable; polygon collision matched; wave HUD audio clear",
				"screenshot_or_seed": "seed_420102_manual_pass"},
			{"seed": 420103, "mode": "endless", "class_id": "arcanist",
				"goal": "reach post-finale biome transition", "result": "pass",
				"evidence_source": "manual_playtest",
				"notes": "objective completed; animation stable; polygon collision matched; wave HUD audio clear",
				"screenshot_or_seed": "seed_420103_manual_pass"},
			{"seed": 420104, "mode": "hardcore", "class_id": "nightblade",
				"goal": "verify lethal damage/readability feels fair", "result": "pass",
				"evidence_source": "manual_playtest",
				"notes": "objective completed; animation stable; polygon collision matched; wave HUD audio clear",
				"screenshot_or_seed": "seed_420104_manual_pass"},
			{"seed": 420105, "mode": "elemental_chaos", "class_id": "ranger",
				"goal": "verify element swaps and combo feedback", "result": "pass",
				"evidence_source": "manual_playtest",
				"notes": "objective completed; animation stable; polygon collision matched; wave HUD audio clear",
				"screenshot_or_seed": "seed_420105_manual_pass"},
			{"seed": 420106, "mode": "balance_lab", "class_id": "gunner",
				"goal": "record TTK/pace notes for weapon and economy tuning", "result": "pass",
				"evidence_source": "manual_playtest",
				"notes": "objective completed; animation stable; polygon collision matched; wave HUD audio clear",
				"screenshot_or_seed": "seed_420106_manual_pass"},
		],
		"headless_scenario_rehearsal": {
			"passed": true,
			"review_type": "headless_scenario_contract_rehearsal",
			"manual_playtest_replacement": false,
			"results": [
				{"seed": 420101, "mode": "normal", "class_id": "blade_warden",
					"goal": "clear floor 1 and choose one upgrade", "result": "pass",
					"evidence_source": "headless_rehearsal",
					"class_contract_ok": true, "mode_contract_ok": true,
					"seed_contract_ok": true,
					"notes": "headless contract valid; human playtest still required"},
				{"seed": 420102, "mode": "boss_rush", "class_id": "bulwark",
					"goal": "survive boss phase shift and enrage", "result": "pass",
					"evidence_source": "headless_rehearsal",
					"class_contract_ok": true, "mode_contract_ok": true,
					"seed_contract_ok": true,
					"notes": "headless contract valid; human playtest still required"},
				{"seed": 420103, "mode": "endless", "class_id": "arcanist",
					"goal": "reach post-finale biome transition", "result": "pass",
					"evidence_source": "headless_rehearsal",
					"class_contract_ok": true, "mode_contract_ok": true,
					"seed_contract_ok": true,
					"notes": "headless contract valid; human playtest still required"},
				{"seed": 420104, "mode": "hardcore", "class_id": "nightblade",
					"goal": "verify lethal damage/readability feels fair", "result": "pass",
					"evidence_source": "headless_rehearsal",
					"class_contract_ok": true, "mode_contract_ok": true,
					"seed_contract_ok": true,
					"notes": "headless contract valid; human playtest still required"},
				{"seed": 420105, "mode": "elemental_chaos", "class_id": "ranger",
					"goal": "verify element swaps and combo feedback", "result": "pass",
					"evidence_source": "headless_rehearsal",
					"class_contract_ok": true, "mode_contract_ok": true,
					"seed_contract_ok": true,
					"notes": "headless contract valid; human playtest still required"},
				{"seed": 420106, "mode": "balance_lab", "class_id": "gunner",
					"goal": "record TTK/pace notes for weapon and economy tuning",
					"result": "pass", "evidence_source": "headless_rehearsal",
					"class_contract_ok": true, "mode_contract_ok": true,
					"seed_contract_ok": true,
					"notes": "headless contract valid; human playtest still required"},
			],
		},
		"asset_self_review": {
			"passed": true,
			"review_type": "headless_asset_contract_review",
			"animation_reviewed": true,
			"polygon_reviewed": true,
			"motion_reviewed": true,
			"origin_reviewed": true,
			"source_policy_ok": true,
			"no_direct_fanmade_copy": true,
			"animation_frame_grid_checked_count": 12,
			"collision_polygon_checked_count": 2,
			"object_visual_checked_count": 8,
			"notes": "headless audit checked frame grid, motion/origin metadata, collision polygons, and source policy",
		},
		"export_package": {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		},
	}

func _script_has_method(script: Script, method_name: String) -> bool:
	for method in script.get_script_method_list():
		if String(method.get("name", "")) == method_name:
			return true
	return false
