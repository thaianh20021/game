class_name MetaProgression
extends RefCounted
## Persistent meta layer: banks run rewards after win/death.

const SAVE_PATH := "user://meta_progression.json"
const META_CURRENCY_KEYS := ["soul_shards", "element_cores", "rune_dust", "blueprints"]
const RELEASE_CANDIDATE_NOTE_KEYS := [
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
]
const RELEASE_CANDIDATE_MANUAL_RESULT_KEYS := [
	"seed",
	"mode",
	"class_id",
	"goal",
	"result",
	"evidence_source",
	"notes",
	"screenshot_or_seed",
]
const RELEASE_CANDIDATE_MANUAL_ISSUE_KEYS := [
	"scenario_index",
	"seed",
	"mode",
	"class_id",
	"goal",
	"result",
	"issue_type",
	"evidence_source",
	"notes",
	"screenshot_or_seed",
]
const RELEASE_CANDIDATE_MANUAL_RESOLVED_ISSUE_KEYS := [
	"scenario_index",
	"seed",
	"mode",
	"class_id",
	"goal",
	"issue_type",
	"resolution_result",
	"evidence_source",
	"resolution_notes",
	"screenshot_or_seed",
]
const RELEASE_CANDIDATE_REHEARSAL_RESULT_KEYS := [
	"seed",
	"mode",
	"class_id",
	"goal",
	"result",
	"notes",
	"evidence_source",
]
const RELEASE_CANDIDATE_ASSET_REVIEW_BOOL_KEYS := [
	"passed",
	"animation_reviewed",
	"polygon_reviewed",
	"motion_reviewed",
	"origin_reviewed",
	"source_policy_ok",
	"no_direct_fanmade_copy",
]
const RELEASE_CANDIDATE_ASSET_REVIEW_COUNT_KEYS := [
	"animation_frame_grid_checked_count",
	"collision_polygon_checked_count",
	"object_visual_checked_count",
]
const UPGRADE_ORDER := [
	"training_hp",
	"training_damage",
	"core_affinity",
	"rune_stability",
	"blueprint_socket",
	"starter_key",
	"gold_pouch",
	"revive_charm",
]
const UPGRADE_DEFS := {
	"training_hp": {
		"label": "+HP",
		"costs": {"banked_gold": 30},
		"max_level": 3,
		"effect": "+10 HP",
	},
	"training_damage": {
		"label": "+DMG",
		"costs": {"banked_gold": 50},
		"max_level": 3,
		"effect": "+4% damage",
	},
	"core_affinity": {
		"label": "Core Affinity",
		"costs": {"soul_shards": 4, "element_cores": 1},
		"max_level": 3,
		"effect": "+3% elemental damage",
	},
	"rune_stability": {
		"label": "Rune Stability",
		"costs": {"soul_shards": 3, "rune_dust": 6},
		"max_level": 3,
		"effect": "-0.04s dash cooldown",
	},
	"blueprint_socket": {
		"label": "Blueprint Socket",
		"costs": {"banked_gold": 40, "blueprints": 1},
		"max_level": 2,
		"effect": "+1 projectile",
	},
	"starter_key": {
		"label": "Starter Key",
		"costs": {"banked_gold": 35, "rune_dust": 2},
		"max_level": 2,
		"effect": "+1 silver key",
	},
	"gold_pouch": {
		"label": "Gold Pouch",
		"costs": {"banked_gold": 25, "soul_shards": 1},
		"max_level": 3,
		"effect": "+10 starting gold",
	},
	"revive_charm": {
		"label": "Revive Charm",
		"costs": {"banked_gold": 80, "element_cores": 1, "blueprints": 1},
		"max_level": 1,
		"effect": "Revive once at 35% HP",
	},
}

static func default_data() -> Dictionary:
	return {
		"banked_gold": 0,
		"soul_shards": 0,
		"element_cores": 0,
		"rune_dust": 0,
		"blueprints": 0,
		"runs_finished": 0,
		"victories": 0,
		"defeats": 0,
		"last_floor": 0,
		"best_floor": 0,
		"current_win_streak": 0,
		"best_win_streak": 0,
		"last_result": "",
		"last_gold": 0,
		"last_seed": 0,
		"last_seed_label": "",
		"last_class_id": "",
		"last_class": "",
		"last_element": "",
		"last_mode": "",
		"last_path": "",
		"last_build_archetype": "",
		"last_build_summary": "",
		"last_build_tags": "",
		"last_daily_seed": 0,
		"last_daily_fingerprint_hash": "",
		"last_daily_fingerprint": {},
		"daily_seed_attempts": 0,
		"daily_seed_victories": 0,
		"class_records": {},
		"mode_records": {},
		"element_records": {},
		"biome_records": {},
		"boss_records": {},
		"enemy_records": {},
		"recent_runs": [],
		"last_rewards": {},
		"release_candidate_evidence": {},
		"upgrades": {},
	}

static func load_data(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return default_data()
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		var data := default_data()
		for key in (parsed as Dictionary).keys():
			data[key] = parsed[key]
		return data
	return default_data()

static func recent_run_playtest_summary(data: Dictionary) -> String:
	var runs: Array = data.get("recent_runs", [])
	var run_count := 0
	var win_count := 0
	var pace_total := 0.0
	var pace_count := 0
	var boss_total := 0.0
	var boss_count := 0
	var gold_total := 0.0
	var gold_count := 0
	var decision_count := 0
	var reward_pick_total := 0
	var reward_skip_total := 0
	var reroll_total := 0
	var shop_buy_total := 0
	var shop_leave_total := 0
	for raw in runs:
		if not (raw is Dictionary):
			continue
		var run := raw as Dictionary
		run_count += 1
		if str(run.get("result", "")).strip_edges().to_lower() == "victory":
			win_count += 1
		if run.has("pace_avg_sec"):
			pace_total += float(run.get("pace_avg_sec", 0.0))
			pace_count += 1
		if run.has("pace_boss_sec"):
			boss_total += float(run.get("pace_boss_sec", 0.0))
			boss_count += 1
		if run.has("economy_gold_earned"):
			gold_total += float(run.get("economy_gold_earned", 0))
			gold_count += 1
		if run.has("decision_reward_picks") or run.has("decision_shop_buys"):
			decision_count += 1
			reward_pick_total += int(run.get("decision_reward_picks", 0))
			reward_skip_total += int(run.get("decision_reward_skips", 0))
			reroll_total += int(run.get("decision_reward_rerolls", 0))
			shop_buy_total += int(run.get("decision_shop_buys", 0))
			shop_leave_total += int(run.get("decision_shop_leaves", 0))
	if run_count <= 0:
		return "Playtest Trend: No recent runs"
	var parts: Array[String] = [
		"Playtest Trend: Runs %d" % run_count,
		"Win %d/%d" % [win_count, run_count],
	]
	if pace_count > 0:
		parts.append("Avg Pace %.1fs" % (pace_total / float(pace_count)))
	if boss_count > 0:
		parts.append("Boss %.1fs" % (boss_total / float(boss_count)))
	if gold_count > 0:
		parts.append("Gold %.1f" % (gold_total / float(gold_count)))
	if decision_count > 0:
		var decision_denominator := float(decision_count)
		parts.append("Rewards %.1f/%.1f" % [
			float(reward_pick_total) / decision_denominator,
			float(reward_skip_total) / decision_denominator,
		])
		parts.append("Rerolls %.1f" % (float(reroll_total) / decision_denominator))
		parts.append("Shop %.1f/%.1f" % [
			float(shop_buy_total) / decision_denominator,
			float(shop_leave_total) / decision_denominator,
		])
	return " | ".join(parts)

static func balance_playtest_evidence(data: Dictionary) -> Dictionary:
	var buckets := {}
	for raw in Array(data.get("recent_runs", [])):
		if not (raw is Dictionary):
			continue
		var run := raw as Dictionary
		var boss_id := _boss_balance_id_from_run(run)
		var boss_sec := float(run.get("pace_boss_sec", 0.0))
		if boss_id == "" or boss_sec <= 0.0:
			continue
		var bucket: Dictionary = buckets.get(boss_id, {})
		if bucket.is_empty():
			bucket = {
				"boss_variant": str(run.get("boss_variant", "")).strip_edges(),
				"biome_id": str(run.get("biome_id", "")).strip_edges(),
				"pace_boss_total": 0.0,
				"pace_avg_total": 0.0,
				"pace_avg_count": 0,
				"sample_runs": 0,
			}
		bucket["pace_boss_total"] = float(bucket.get("pace_boss_total", 0.0)) + boss_sec
		bucket["sample_runs"] = int(bucket.get("sample_runs", 0)) + 1
		if run.has("pace_avg_sec"):
			bucket["pace_avg_total"] = float(bucket.get("pace_avg_total", 0.0)) \
					+ maxf(float(run.get("pace_avg_sec", 0.0)), 0.0)
			bucket["pace_avg_count"] = int(bucket.get("pace_avg_count", 0)) + 1
		buckets[boss_id] = bucket
	var out := {}
	for boss_id in buckets.keys():
		var bucket: Dictionary = buckets[boss_id]
		var samples := maxi(int(bucket.get("sample_runs", 0)), 1)
		var evidence := {
			"boss_variant": str(bucket.get("boss_variant", "")),
			"biome_id": str(bucket.get("biome_id", "")),
			"pace_boss_sec": float(bucket.get("pace_boss_total", 0.0)) / float(samples),
			"sample_runs": samples,
		}
		var avg_count := int(bucket.get("pace_avg_count", 0))
		if avg_count > 0:
			evidence["pace_avg_sec"] = float(bucket.get("pace_avg_total", 0.0)) / float(avg_count)
		out[str(boss_id)] = evidence
	return out

static func balance_playtest_evidence_summary(data: Dictionary, max_items: int = 3) -> String:
	var evidence := balance_playtest_evidence(data)
	if evidence.is_empty():
		return "Playtest Evidence: None"
	var keys := evidence.keys()
	keys.sort()
	var parts: Array[String] = []
	for key in keys.slice(0, maxi(max_items, 0)):
		var entry: Dictionary = evidence.get(key, {})
		parts.append("%s %.1fs x%d" % [
			str(key),
			float(entry.get("pace_boss_sec", 0.0)),
			int(entry.get("sample_runs", 0)),
		])
	return "Playtest Evidence: %s" % " | ".join(parts)

static func reset_profile(path: String = SAVE_PATH) -> Dictionary:
	var data := default_data()
	save_data(data, path)
	return data

static func release_candidate_evidence(data: Dictionary) -> Dictionary:
	var raw: Variant = data.get("release_candidate_evidence", {})
	if raw is Dictionary:
		return _normalized_release_candidate_evidence(raw)
	return {}

static func release_candidate_evidence_summary(
		data: Dictionary,
		minimum_smoke_count: int = 70,
		required_scenarios: int = 6,
) -> String:
	var evidence := release_candidate_evidence(data)
	var smoke: Dictionary = evidence.get("full_smoke_suite", {})
	var smoke_count := int(smoke.get("count", 0))
	var smoke_ok := bool(smoke.get("passed", false)) and smoke_count >= minimum_smoke_count
	var notes_ready := _release_candidate_notes_ready(Dictionary(evidence.get("playtest_notes", {})))
	var scenario_count := _release_candidate_manual_scenario_count(
		Array(evidence.get("manual_scenario_results", [])))
	var rehearsal: Dictionary = evidence.get("headless_scenario_rehearsal", {})
	var rehearsal_ok := _release_candidate_rehearsal_ready(rehearsal)
	var asset_review_ready := _release_candidate_asset_self_review_ready(
		Dictionary(evidence.get("asset_self_review", {})))
	var package: Dictionary = evidence.get("export_package", {})
	var package_ok := _release_candidate_export_package_ready(package)
	return "Release Evidence: Smoke %d/%d %s | Notes %s | Scenarios %d/%d | Rehearsal %s | Asset %s | Package %s" % [
		smoke_count,
		minimum_smoke_count,
		"OK" if smoke_ok else "Missing",
		"OK" if notes_ready else "Missing",
		scenario_count,
		maxi(required_scenarios, 0),
		"OK" if rehearsal_ok else "Missing",
		"OK" if asset_review_ready else "Missing",
		"OK" if package_ok else "Missing",
	]

static func record_release_candidate_evidence(
		evidence: Dictionary,
		path: String = SAVE_PATH,
) -> Dictionary:
	var data := load_data(path)
	data["release_candidate_evidence"] = _normalized_release_candidate_evidence(evidence)
	save_data(data, path)
	return data

static func record_release_candidate_manual_scenario_result(
		result: Dictionary,
		path: String = SAVE_PATH,
) -> Dictionary:
	var data := load_data(path)
	var evidence := release_candidate_evidence(data)
	var normalized := _normalized_release_candidate_evidence({
		"manual_scenario_results": [result],
	})
	var incoming: Array = normalized.get("manual_scenario_results", [])
	if incoming.is_empty():
		return data
	var incoming_result: Dictionary = incoming[0]
	if not _release_candidate_manual_result_ready(incoming_result):
		return data
	var incoming_key := _release_candidate_scenario_key(incoming_result)
	var results: Array = []
	var replaced := false
	for raw in Array(evidence.get("manual_scenario_results", [])):
		if not (raw is Dictionary):
			continue
		var existing: Dictionary = raw
		if _release_candidate_scenario_key(existing) == incoming_key:
			results.append(incoming_result)
			replaced = true
		else:
			results.append(existing)
	if not replaced:
		results.append(incoming_result)
	evidence["manual_scenario_results"] = results
	data["release_candidate_evidence"] = _normalized_release_candidate_evidence(evidence)
	save_data(data, path)
	return data

static func record_release_candidate_manual_playtest_issue(
		issue: Dictionary,
		path: String = SAVE_PATH,
) -> Dictionary:
	var data := load_data(path)
	var evidence := release_candidate_evidence(data)
	var normalized := _normalized_release_candidate_evidence({
		"manual_playtest_issues": [issue],
	})
	var incoming: Array = normalized.get("manual_playtest_issues", [])
	if incoming.is_empty():
		return data
	var incoming_issue: Dictionary = incoming[0]
	if not _release_candidate_manual_issue_ready(incoming_issue):
		return data
	var issues: Array = Array(evidence.get("manual_playtest_issues", []))
	issues.append(incoming_issue)
	evidence["manual_playtest_issues"] = issues
	data["release_candidate_evidence"] = _normalized_release_candidate_evidence(evidence)
	save_data(data, path)
	return data

static func resolve_release_candidate_manual_playtest_issue(
		resolution: Dictionary,
		path: String = SAVE_PATH,
) -> Dictionary:
	var data := load_data(path)
	var evidence := release_candidate_evidence(data)
	var normalized := _normalized_release_candidate_evidence({
		"manual_playtest_resolved_issues": [resolution],
	})
	var incoming: Array = normalized.get("manual_playtest_resolved_issues", [])
	if incoming.is_empty():
		return data
	var resolved_issue: Dictionary = incoming[0]
	if not _release_candidate_manual_issue_resolution_ready(resolved_issue):
		return data
	var issue_key := _release_candidate_manual_issue_key(resolved_issue)
	var open_issues: Array = []
	var matched := false
	for raw in Array(evidence.get("manual_playtest_issues", [])):
		if not (raw is Dictionary):
			continue
		var issue: Dictionary = raw
		if _release_candidate_manual_issue_key(issue) == issue_key:
			matched = true
		else:
			open_issues.append(issue)
	if not matched:
		return data
	var resolved_issues := Array(evidence.get("manual_playtest_resolved_issues", []))
	resolved_issues.append(resolved_issue)
	evidence["manual_playtest_issues"] = open_issues
	evidence["manual_playtest_resolved_issues"] = resolved_issues
	data["release_candidate_evidence"] = _normalized_release_candidate_evidence(evidence)
	save_data(data, path)
	return data

static func record_release_candidate_playtest_notes_result(
		result: Dictionary,
		path: String = SAVE_PATH,
) -> Dictionary:
	var data := load_data(path)
	var evidence := release_candidate_evidence(data)
	var normalized := _normalized_release_candidate_evidence({
		"playtest_notes": result,
	})
	var notes: Dictionary = normalized.get("playtest_notes", {})
	if not _release_candidate_notes_ready(notes):
		return data
	evidence["playtest_notes"] = notes
	data["release_candidate_evidence"] = _normalized_release_candidate_evidence(evidence)
	save_data(data, path)
	return data

static func record_release_candidate_smoke_suite_result(
		result: Dictionary,
		path: String = SAVE_PATH,
) -> Dictionary:
	var data := load_data(path)
	var evidence := release_candidate_evidence(data)
	var normalized := _normalized_release_candidate_evidence({
		"full_smoke_suite": result,
	})
	var smoke: Dictionary = normalized.get("full_smoke_suite", {})
	if not _release_candidate_smoke_suite_ready(smoke):
		return data
	evidence["full_smoke_suite"] = smoke
	data["release_candidate_evidence"] = _normalized_release_candidate_evidence(evidence)
	save_data(data, path)
	return data

static func record_release_candidate_export_package_result(
		result: Dictionary,
		path: String = SAVE_PATH,
) -> Dictionary:
	var data := load_data(path)
	var evidence := release_candidate_evidence(data)
	var normalized := _normalized_release_candidate_evidence({
		"export_package": result,
	})
	var package: Dictionary = normalized.get("export_package", {})
	if not _release_candidate_export_package_ready(package):
		return data
	evidence["export_package"] = package
	data["release_candidate_evidence"] = _normalized_release_candidate_evidence(evidence)
	save_data(data, path)
	return data

static func record_release_candidate_asset_self_review_result(
		result: Dictionary,
		path: String = SAVE_PATH,
) -> Dictionary:
	var data := load_data(path)
	var evidence := release_candidate_evidence(data)
	var normalized := _normalized_release_candidate_evidence({
		"asset_self_review": result,
	})
	var review: Dictionary = normalized.get("asset_self_review", {})
	if not _release_candidate_asset_self_review_ready(review):
		return data
	evidence["asset_self_review"] = review
	data["release_candidate_evidence"] = _normalized_release_candidate_evidence(evidence)
	save_data(data, path)
	return data

static func record_release_candidate_headless_rehearsal_result(
		result: Dictionary,
		path: String = SAVE_PATH,
) -> Dictionary:
	var data := load_data(path)
	var evidence := release_candidate_evidence(data)
	var normalized := _normalized_release_candidate_evidence({
		"headless_scenario_rehearsal": result,
	})
	var rehearsal: Dictionary = normalized.get("headless_scenario_rehearsal", {})
	if not _release_candidate_rehearsal_ready(rehearsal):
		return data
	evidence["headless_scenario_rehearsal"] = rehearsal
	data["release_candidate_evidence"] = _normalized_release_candidate_evidence(evidence)
	save_data(data, path)
	return data

static func bank_run(gold: int, result: String, path: String = SAVE_PATH) -> Dictionary:
	return bank_run_rewards({"gold": gold}, result, path)

static func bank_run_rewards(
		rewards: Dictionary,
		result: String,
		path: String = SAVE_PATH,
		context: Dictionary = {},
) -> Dictionary:
	var data := load_data(path)
	var banked := {
		"gold": _banked_gold(int(rewards.get("gold", 0)), result),
	}
	data["banked_gold"] = int(data.get("banked_gold", 0)) + int(banked["gold"])
	for key in META_CURRENCY_KEYS:
		var amount := maxi(int(rewards.get(key, 0)), 0)
		data[key] = int(data.get(key, 0)) + amount
		banked[key] = amount
	var challenge_bonus := str(rewards.get("challenge_bonus", "")).strip_edges()
	if challenge_bonus != "":
		banked["challenge_bonus"] = challenge_bonus
	var endless_depth_bonus := str(rewards.get("endless_depth_bonus", "")).strip_edges()
	if endless_depth_bonus != "":
		banked["endless_depth_bonus"] = endless_depth_bonus
	var hardcore_clear_bonus := str(rewards.get("hardcore_clear_bonus", "")).strip_edges()
	if hardcore_clear_bonus != "":
		banked["hardcore_clear_bonus"] = hardcore_clear_bonus
	var elemental_chaos_bonus := str(rewards.get("elemental_chaos_bonus", "")).strip_edges()
	if elemental_chaos_bonus != "":
		banked["elemental_chaos_bonus"] = elemental_chaos_bonus
	data["runs_finished"] = int(data.get("runs_finished", 0)) + 1
	data["last_result"] = result
	data["last_gold"] = int(banked["gold"])
	data["last_rewards"] = banked
	var floor := maxi(int(rewards.get("floor", 0)), 0)
	data["last_floor"] = floor
	data["best_floor"] = maxi(int(data.get("best_floor", 0)), floor)
	_record_run_context(data, context, result, floor)
	_record_recent_run(data, context, result, floor, banked)
	if result == "victory":
		data["victories"] = int(data.get("victories", 0)) + 1
		data["current_win_streak"] = int(data.get("current_win_streak", 0)) + 1
		data["best_win_streak"] = maxi(
			int(data.get("best_win_streak", 0)),
			int(data.get("current_win_streak", 0)))
	else:
		data["defeats"] = int(data.get("defeats", 0)) + 1
		data["current_win_streak"] = 0
	save_data(data, path)
	return data

static func _record_run_context(
		data: Dictionary,
		context: Dictionary,
		result: String,
		floor: int,
) -> void:
	if context.is_empty() or not context.has("seed"):
		return
	var seed := int(context.get("seed", 0))
	data["last_seed"] = seed
	data["last_seed_label"] = str(context.get("seed_label", "Seed"))
	data["last_class_id"] = str(context.get("class_id", ""))
	data["last_class"] = str(context.get("class", ""))
	data["last_element"] = str(context.get("element", ""))
	var mode_label := _context_mode_label(context)
	data["last_mode"] = mode_label
	data["last_path"] = str(context.get("path", "")).strip_edges()
	data["last_build_archetype"] = str(context.get("archetype", "")).strip_edges()
	data["last_build_summary"] = str(context.get("build", "")).strip_edges()
	data["last_build_tags"] = str(context.get("tags", "")).strip_edges()
	_record_class_run(data, context, result, floor, seed)
	_record_mode_run(data, context, mode_label, result, floor, seed)
	_record_element_run(data, context, result, floor, seed)
	_record_biome_run(data, context, result, floor, seed)
	_record_boss_run(data, context, result, floor, seed)
	_record_enemy_codex_run(data, context, floor, seed)
	if str(data["last_seed_label"]) != "Daily Seed" or seed <= 0:
		return
	data["last_daily_seed"] = seed
	data["daily_seed_attempts"] = int(data.get("daily_seed_attempts", 0)) + 1
	var daily_fingerprint := _daily_fingerprint_from_context(context)
	if not daily_fingerprint.is_empty():
		data["last_daily_fingerprint"] = daily_fingerprint
		data["last_daily_fingerprint_hash"] = str(daily_fingerprint.get("hash", ""))
	if result == "victory":
		data["daily_seed_victories"] = int(data.get("daily_seed_victories", 0)) + 1

static func _record_class_run(
		data: Dictionary,
		context: Dictionary,
		result: String,
		floor: int,
		seed: int,
) -> void:
	var class_id := str(context.get("class_id", ""))
	if class_id == "":
		return
	var class_records: Dictionary = data.get("class_records", {})
	var record: Dictionary = class_records.get(class_id, {})
	record["label"] = str(context.get("class", class_id))
	record["runs"] = int(record.get("runs", 0)) + 1
	record["last_floor"] = floor
	record["last_seed"] = seed
	var run_path := str(context.get("path", "")).strip_edges()
	if run_path != "":
		record["last_path"] = run_path
	if result == "victory":
		record["victories"] = int(record.get("victories", 0)) + 1
	if floor >= int(record.get("best_floor", 0)):
		record["best_floor"] = floor
		record["best_seed"] = seed
		if run_path != "":
			record["best_path"] = run_path
	class_records[class_id] = record
	data["class_records"] = class_records

static func _record_mode_run(
		data: Dictionary,
		context: Dictionary,
		mode_label: String,
		result: String,
		floor: int,
		seed: int,
) -> void:
	var mode_id := _mode_record_id(mode_label)
	if mode_id == "":
		return
	var mode_records: Dictionary = data.get("mode_records", {})
	var record: Dictionary = mode_records.get(mode_id, {})
	record["label"] = mode_label
	record["runs"] = int(record.get("runs", 0)) + 1
	record["last_floor"] = floor
	record["last_seed"] = seed
	var run_path := str(context.get("path", "")).strip_edges()
	if run_path != "":
		record["last_path"] = run_path
	if result == "victory":
		record["victories"] = int(record.get("victories", 0)) + 1
	if floor >= int(record.get("best_floor", 0)):
		record["best_floor"] = floor
		record["best_seed"] = seed
		if run_path != "":
			record["best_path"] = run_path
	mode_records[mode_id] = record
	data["mode_records"] = mode_records

static func _record_element_run(
		data: Dictionary,
		context: Dictionary,
		result: String,
		floor: int,
		seed: int,
) -> void:
	var element_id := str(context.get("element", "")).strip_edges().to_lower()
	if element_id == "":
		return
	var element_records: Dictionary = data.get("element_records", {})
	var record: Dictionary = element_records.get(element_id, {})
	record["label"] = _element_record_label(element_id)
	record["runs"] = int(record.get("runs", 0)) + 1
	record["victories"] = int(record.get("victories", 0))
	record["last_floor"] = floor
	record["last_seed"] = seed
	var run_path := str(context.get("path", "")).strip_edges()
	if run_path != "":
		record["last_path"] = run_path
	if result == "victory":
		record["victories"] = int(record.get("victories", 0)) + 1
	if floor >= int(record.get("best_floor", 0)):
		record["best_floor"] = floor
		record["best_seed"] = seed
		if run_path != "":
			record["best_path"] = run_path
	element_records[element_id] = record
	data["element_records"] = element_records

static func _record_biome_run(
		data: Dictionary,
		context: Dictionary,
		result: String,
		floor: int,
		seed: int,
) -> void:
	var biome_id := str(context.get("biome_id", "")).strip_edges()
	var biome_label := str(context.get("biome", context.get("biome_label", ""))).strip_edges()
	if biome_id == "" and biome_label != "":
		biome_id = _mode_record_id(biome_label)
	if biome_id == "":
		return
	var biome_records: Dictionary = data.get("biome_records", {})
	var record: Dictionary = biome_records.get(biome_id, {})
	record["label"] = biome_label if biome_label != "" else _element_record_label(biome_id)
	record["runs"] = int(record.get("runs", 0)) + 1
	record["victories"] = int(record.get("victories", 0))
	record["last_floor"] = floor
	record["last_seed"] = seed
	var boss_variant := str(context.get("boss_variant", "")).strip_edges()
	if boss_variant != "":
		record["last_boss_variant"] = boss_variant
	var run_path := str(context.get("path", "")).strip_edges()
	if run_path != "":
		record["last_path"] = run_path
	if result == "victory":
		record["victories"] = int(record.get("victories", 0)) + 1
	if floor >= int(record.get("best_floor", 0)):
		record["best_floor"] = floor
		record["best_seed"] = seed
		if boss_variant != "":
			record["best_boss_variant"] = boss_variant
		if run_path != "":
			record["best_path"] = run_path
	biome_records[biome_id] = record
	data["biome_records"] = biome_records

static func _record_boss_run(
		data: Dictionary,
		context: Dictionary,
		result: String,
		floor: int,
		seed: int,
) -> void:
	var boss_id := str(context.get("boss_variant", context.get("boss_id", ""))).strip_edges()
	if boss_id == "":
		return
	var boss_records: Dictionary = data.get("boss_records", {})
	var record: Dictionary = boss_records.get(boss_id, {})
	record["label"] = _boss_record_label(context, boss_id)
	record["runs"] = int(record.get("runs", 0)) + 1
	record["victories"] = int(record.get("victories", 0))
	record["last_floor"] = floor
	record["last_seed"] = seed
	var biome_id := str(context.get("biome_id", "")).strip_edges()
	if biome_id != "":
		record["biome_id"] = biome_id
	var biome_label := str(context.get("biome", context.get("biome_label", ""))).strip_edges()
	if biome_label != "":
		record["biome"] = biome_label
	var run_path := str(context.get("path", "")).strip_edges()
	if run_path != "":
		record["last_path"] = run_path
	if result == "victory":
		record["victories"] = int(record.get("victories", 0)) + 1
	if floor >= int(record.get("best_floor", 0)):
		record["best_floor"] = floor
		record["best_seed"] = seed
		if run_path != "":
			record["best_path"] = run_path
	boss_records[boss_id] = record
	data["boss_records"] = boss_records

static func _record_recent_run(
		data: Dictionary,
		context: Dictionary,
		result: String,
		floor: int,
		banked: Dictionary,
) -> void:
	var runs: Array = data.get("recent_runs", [])
	var entry := {
		"result": result,
		"floor": floor,
		"seed": int(context.get("seed", data.get("last_seed", 0))),
		"seed_label": str(context.get("seed_label", data.get("last_seed_label", ""))),
		"class_id": str(context.get("class_id", "")),
		"class": str(context.get("class", data.get("last_class", ""))),
		"element": str(context.get("element", data.get("last_element", ""))),
		"mode": _context_mode_label(context) if not context.is_empty()
			else str(data.get("last_mode", "")),
		"path": str(context.get("path", data.get("last_path", ""))).strip_edges(),
		"archetype": str(context.get("archetype", data.get("last_build_archetype", ""))).strip_edges(),
		"build": str(context.get("build", data.get("last_build_summary", ""))).strip_edges(),
		"tags": str(context.get("tags", data.get("last_build_tags", ""))).strip_edges(),
		"banked_gold": int(banked.get("gold", 0)),
	}
	for key in ["biome_id", "biome", "boss_variant", "boss"]:
		var value := str(context.get(key, "")).strip_edges()
		if value != "":
			entry[key] = value
	var daily_fingerprint := _daily_fingerprint_from_context(context)
	if not daily_fingerprint.is_empty():
		entry["daily_fingerprint"] = daily_fingerprint
		entry["daily_fingerprint_hash"] = str(daily_fingerprint.get("hash", ""))
	for key in [
			"boss_story", "damage_taken", "survival", "floor_recap", "mastery",
			"pace", "tuning_focus", "playtest_objective", "tuning_patch",
			"balance_experiment", "release_audit",
			"release_decision", "release_backlog", "release_next_action",
			"release_candidate_status", "release_candidate_next_action",
			"release_candidate_blockers"]:
		var value := str(context.get(key, "")).strip_edges()
		if value != "":
			entry[key] = value
	for key in ["balance_experiment_id", "balance_experiment_patch_id", "balance_experiment_source"]:
		var value := str(context.get(key, "")).strip_edges()
		if value != "":
			entry[key] = value
	if context.has("balance_experiment_hp_multiplier"):
		entry["balance_experiment_hp_multiplier"] = maxf(
			float(context.get("balance_experiment_hp_multiplier", 0.0)), 0.0)
	for key in ["pace_timed_rooms", "pace_fast_count", "pace_target_count", "pace_slow_count"]:
		if context.has(key):
			entry[key] = maxi(int(context.get(key, 0)), 0)
	for key in ["pace_avg_sec", "pace_boss_sec", "pace_slowest_sec"]:
		if context.has(key):
			entry[key] = maxf(float(context.get(key, 0.0)), 0.0)
	var slowest_room := str(context.get("pace_slowest_room", "")).strip_edges()
	if slowest_room != "":
		entry["pace_slowest_room"] = slowest_room
	for key in [
			"economy_gold_earned", "economy_soul_shards", "economy_element_cores",
			"economy_rune_dust", "economy_blueprints", "decision_reward_picks",
			"decision_reward_skips", "decision_reward_rerolls", "decision_shop_buys",
			"decision_shop_leaves"]:
		if context.has(key):
			entry[key] = maxi(int(context.get(key, 0)), 0)
	if context.has("release_replacements"):
		entry["release_replacements"] = maxi(int(context.get("release_replacements", 0)), 0)
	var enemy_codex_preview := _enemy_codex_preview_from_context(context)
	if enemy_codex_preview != "":
		entry["enemy_codex"] = enemy_codex_preview
	for key in META_CURRENCY_KEYS:
		var amount := int(banked.get(key, 0))
		if amount > 0:
			entry[key] = amount
	for key in ["challenge_bonus", "endless_depth_bonus", "hardcore_clear_bonus",
			"elemental_chaos_bonus"]:
		var bonus := str(banked.get(key, "")).strip_edges()
		if bonus != "":
			entry[key] = bonus
	runs.push_front(entry)
	while runs.size() > 5:
		runs.pop_back()
	data["recent_runs"] = runs

static func _daily_fingerprint_from_context(context: Dictionary) -> Dictionary:
	if not (context.get("daily_fingerprint", {}) is Dictionary):
		return {}
	var raw: Dictionary = context.get("daily_fingerprint", {})
	var hash_text := str(raw.get("hash", "")).strip_edges()
	if hash_text == "":
		return {}
	return {
		"hash": hash_text,
		"floor_index": maxi(int(raw.get("floor_index", 0)), 0),
		"room_count": maxi(int(raw.get("room_count", 0)), 0),
		"spawn_count": maxi(int(raw.get("spawn_count", 0)), 0),
		"boss_variant": str(raw.get("boss_variant", "")).strip_edges(),
	}

static func enemy_record_preview(data: Dictionary, max_items: int = 3) -> String:
	var records: Dictionary = data.get("enemy_records", data)
	if records.is_empty():
		return ""
	var parts: Array[String] = []
	var keys := records.keys()
	keys.sort()
	for key in keys:
		var record: Dictionary = records.get(key, {})
		if record.is_empty():
			continue
		var biome := str(record.get("biome", "")).strip_edges()
		parts.append("%s D%d/S%d%s" % [
			str(record.get("label", key)),
			int(record.get("defeated", 0)),
			int(record.get("seen", 0)),
			" %s" % biome if biome != "" else "",
		])
		if parts.size() >= max_items:
			break
	return " / ".join(parts)

static func _record_enemy_codex_run(
		data: Dictionary,
		context: Dictionary,
		floor: int,
		seed: int,
) -> void:
	var seen_entries: Array = context.get("enemy_codex_seen", [])
	var defeated_entries: Array = context.get("enemy_codex_defeated", [])
	if seen_entries.is_empty() and defeated_entries.is_empty():
		return
	var records: Dictionary = data.get("enemy_records", {})
	_merge_enemy_codex_entries(records, seen_entries, "seen", context, floor, seed)
	_merge_enemy_codex_entries(records, defeated_entries, "defeated", context, floor, seed)
	data["enemy_records"] = records

static func _merge_enemy_codex_entries(
		records: Dictionary,
		entries: Array,
		counter_key: String,
		context: Dictionary,
		floor: int,
		seed: int,
) -> void:
	for raw in entries:
		if not (raw is Dictionary):
			continue
		var entry := raw as Dictionary
		var enemy_id := _enemy_record_id(entry)
		if enemy_id == "":
			continue
		var record: Dictionary = records.get(enemy_id, {})
		record["label"] = _enemy_record_label(entry, enemy_id)
		record["kind"] = _enemy_record_kind(entry)
		var biome_id := str(entry.get("biome_id", context.get("biome_id", ""))).strip_edges()
		if biome_id != "":
			record["biome_id"] = biome_id
		var biome := str(entry.get("biome", context.get("biome", ""))).strip_edges()
		if biome != "":
			record["biome"] = biome
		record[counter_key] = int(record.get(counter_key, 0)) \
				+ maxi(int(entry.get("count", 1)), 1)
		record["last_floor"] = floor
		record["last_seed"] = seed
		if floor >= int(record.get("best_floor", 0)):
			record["best_floor"] = floor
			record["best_seed"] = seed
		records[enemy_id] = record

static func _enemy_codex_preview_from_context(context: Dictionary, max_items: int = 3) -> String:
	var defeated_entries: Array = context.get("enemy_codex_defeated", [])
	if defeated_entries.is_empty():
		return ""
	var seen_counts := _enemy_codex_count_map(Array(context.get("enemy_codex_seen", [])))
	var parts: Array[String] = []
	for raw in defeated_entries:
		if not (raw is Dictionary):
			continue
		var entry := raw as Dictionary
		var enemy_id := _enemy_record_id(entry)
		if enemy_id == "":
			continue
		var defeated := maxi(int(entry.get("count", 1)), 1)
		var seen := maxi(int(seen_counts.get(enemy_id, defeated)), defeated)
		parts.append("%s D%d/S%d" % [_enemy_record_label(entry, enemy_id), defeated, seen])
		if parts.size() >= max_items:
			break
	return " / ".join(parts)

static func _enemy_codex_count_map(entries: Array) -> Dictionary:
	var counts := {}
	for raw in entries:
		if not (raw is Dictionary):
			continue
		var entry := raw as Dictionary
		var enemy_id := _enemy_record_id(entry)
		if enemy_id == "":
			continue
		counts[enemy_id] = int(counts.get(enemy_id, 0)) + maxi(int(entry.get("count", 1)), 1)
	return counts

static func _enemy_record_id(entry: Dictionary) -> String:
	for key in ["enemy_id", "id"]:
		var enemy_id := str(entry.get(key, "")).strip_edges()
		if enemy_id != "":
			return enemy_id
	return ""

static func _enemy_record_label(entry: Dictionary, enemy_id: String) -> String:
	for key in ["enemy_name", "name", "label"]:
		var label := str(entry.get(key, "")).strip_edges()
		if label != "":
			return label
	return enemy_id.replace("_", " ").capitalize()

static func _enemy_record_kind(entry: Dictionary) -> String:
	for key in ["enemy_kind", "kind"]:
		var kind_text := str(entry.get(key, "")).strip_edges()
		if kind_text != "":
			return kind_text
	return "enemy"

static func _context_mode_label(context: Dictionary) -> String:
	var mode := str(context.get("mode", "Normal")).strip_edges()
	return mode if mode != "" else "Normal"

static func _mode_record_id(mode_label: String) -> String:
	var id := mode_label.strip_edges().to_lower().replace(" ", "_")
	return id

static func _element_record_label(element_id: String) -> String:
	return element_id.replace("_", " ").capitalize()

static func _boss_record_label(context: Dictionary, boss_id: String) -> String:
	var explicit := str(context.get("boss", context.get("boss_label", ""))).strip_edges()
	return explicit if explicit != "" else boss_id.replace("_", " ").capitalize()

static func _boss_balance_id_from_run(run: Dictionary) -> String:
	var boss_id := str(run.get("boss_id", "")).strip_edges()
	if boss_id == "":
		boss_id = str(run.get("boss_variant", "")).strip_edges()
	if boss_id == "":
		return ""
	return boss_id if boss_id.ends_with("_boss") else "%s_boss" % boss_id

static func _banked_gold(gold: int, result: String) -> int:
	var safe_gold := maxi(gold, 0)
	if result == "victory":
		return safe_gold
	return floori(float(safe_gold) * 0.5)

static func buy_upgrade(upgrade_id: String, path: String = SAVE_PATH) -> Dictionary:
	var data := load_data(path)
	var costs := upgrade_costs(upgrade_id)
	var upgrades: Dictionary = data.get("upgrades", {})
	if int(upgrades.get(upgrade_id, 0)) >= upgrade_max_level(upgrade_id):
		return data
	if not _can_afford(data, costs):
		return data
	upgrades[upgrade_id] = int(upgrades.get(upgrade_id, 0)) + 1
	data["upgrades"] = upgrades
	for key in costs.keys():
		data[key] = int(data.get(key, 0)) - int(costs[key])
	save_data(data, path)
	return data

static func all_upgrade_ids() -> Array:
	return UPGRADE_ORDER.duplicate()

static func upgrade_label(upgrade_id: String) -> String:
	var def: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	return str(def.get("label", upgrade_id))

static func upgrade_cost(upgrade_id: String) -> int:
	return int(upgrade_costs(upgrade_id).get("banked_gold", 999999))

static func upgrade_costs(upgrade_id: String) -> Dictionary:
	var def: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	var costs: Dictionary = def.get("costs", {})
	return costs.duplicate()

static func upgrade_max_level(upgrade_id: String) -> int:
	var def: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	return int(def.get("max_level", 0))

static func upgrade_next_effect(upgrade_id: String, current_level: int) -> String:
	var max_level := upgrade_max_level(upgrade_id)
	if current_level >= max_level:
		return "MAX"
	var def: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	return "Lv%d -> Lv%d: %s" % [
		current_level,
		current_level + 1,
		str(def.get("effect", "Upgrade")),
	]

static func active_bonus_summary(meta: Dictionary, current_biome: Dictionary = {}) -> String:
	var upgrades: Dictionary = meta.get("upgrades", {})
	var parts: Array[String] = []
	var hp := int(upgrades.get("training_hp", 0))
	if hp > 0:
		parts.append("+%d HP" % (hp * 10))
	var damage := int(upgrades.get("training_damage", 0))
	if damage > 0:
		parts.append("+%d%% damage" % (damage * 4))
	var core := int(upgrades.get("core_affinity", 0))
	if core > 0:
		parts.append("+%d%% elemental" % (core * 3))
	var rune := int(upgrades.get("rune_stability", 0))
	if rune > 0:
		parts.append("-%.2fs dash" % (float(rune) * 0.04))
	var sockets := int(upgrades.get("blueprint_socket", 0))
	if sockets > 0:
		parts.append("+%d projectile" % sockets)
	var keys := int(upgrades.get("starter_key", 0))
	if keys > 0:
		parts.append("Key +%d" % keys)
	var gold := int(upgrades.get("gold_pouch", 0))
	if gold > 0:
		parts.append("Gold +%d" % (gold * 10))
	var revives := int(upgrades.get("revive_charm", 0))
	if revives > 0:
		parts.append("Revive x%d" % revives)
	var mastered := _mastered_element_labels(meta)
	if not mastered.is_empty():
		parts.append("Element Mastery %s +2%%" % "/".join(mastered))
	var biome_mastery := _biome_mastery_label(meta, current_biome)
	if biome_mastery != "":
		parts.append("Biome Mastery %s +3%%" % biome_mastery)
	return "None" if parts.is_empty() else " / ".join(parts)

static func _mastered_element_labels(meta: Dictionary) -> Array[String]:
	var records: Dictionary = meta.get("element_records", {})
	var labels: Array[String] = []
	for element in ["fire", "ice", "lightning", "poison"]:
		var record: Dictionary = records.get(element, {})
		if int(record.get("victories", 0)) <= 0:
			continue
		labels.append(str(record.get("label", _element_record_label(element))))
	return labels

static func _biome_mastery_label(meta: Dictionary, current_biome: Dictionary) -> String:
	var biome_id := str(current_biome.get("id", "")).strip_edges()
	if biome_id == "":
		return ""
	var records: Dictionary = meta.get("biome_records", {})
	var record: Dictionary = records.get(biome_id, {})
	if int(record.get("victories", 0)) <= 0:
		return ""
	var label := str(record.get("label", current_biome.get("name", biome_id))).strip_edges()
	return label if label != "" else biome_id.replace("_", " ").capitalize()

static func upgrade_purchase_hint(meta: Dictionary, upgrade_ids: Array = []) -> String:
	var upgrades: Dictionary = meta.get("upgrades", {})
	var first_missing_label := ""
	var first_missing_costs := {}
	for raw_id in _purchase_hint_candidates(upgrade_ids):
		var upgrade_id := str(raw_id)
		var max_level := upgrade_max_level(upgrade_id)
		if max_level <= 0 or int(upgrades.get(upgrade_id, 0)) >= max_level:
			continue
		var costs := upgrade_costs(upgrade_id)
		if _can_afford(meta, costs):
			return "Ready: %s (%s)" % [upgrade_label(upgrade_id), _format_costs(costs)]
		if first_missing_label == "":
			first_missing_label = upgrade_label(upgrade_id)
			first_missing_costs = _missing_costs(meta, costs)
	if first_missing_label != "":
		return "Next: %s needs %s" % [first_missing_label, _format_costs(first_missing_costs)]
	return "All upgrades maxed"

static func _purchase_hint_candidates(upgrade_ids: Array) -> Array:
	if upgrade_ids.is_empty():
		return UPGRADE_ORDER.duplicate()
	return upgrade_ids.duplicate()

static func _missing_costs(data: Dictionary, costs: Dictionary) -> Dictionary:
	var missing := {}
	for key in costs.keys():
		var amount := int(costs[key]) - int(data.get(key, 0))
		if amount > 0:
			missing[key] = amount
	return missing

static func _format_costs(costs: Dictionary) -> String:
	var parts: Array[String] = []
	for key in ["banked_gold", "soul_shards", "element_cores", "rune_dust", "blueprints"]:
		var amount := int(costs.get(key, 0))
		if amount > 0:
			parts.append("%d %s" % [amount, _currency_label(key)])
	return "0" if parts.is_empty() else " + ".join(parts)

static func _currency_label(key: String) -> String:
	match key:
		"banked_gold":
			return "Gold"
		"soul_shards":
			return "Shard"
		"element_cores":
			return "Core"
		"rune_dust":
			return "Dust"
		"blueprints":
			return "BP"
	return key

static func _normalized_release_candidate_evidence(evidence: Dictionary) -> Dictionary:
	var out := {}
	if evidence.has("full_smoke_suite") and evidence["full_smoke_suite"] is Dictionary:
		var smoke: Dictionary = evidence["full_smoke_suite"]
		out["full_smoke_suite"] = {
			"passed": bool(smoke.get("passed", false)),
			"count": maxi(int(smoke.get("count", 0)), 0),
		}
	if evidence.has("minimum_smoke_count"):
		out["minimum_smoke_count"] = maxi(int(evidence.get("minimum_smoke_count", 0)), 0)
	if evidence.has("playtest_notes") and evidence["playtest_notes"] is Dictionary:
		var notes: Dictionary = evidence["playtest_notes"]
		var normalized_notes := {}
		for key in RELEASE_CANDIDATE_NOTE_KEYS:
			if not notes.has(key):
				continue
			var value: Variant = _normalized_release_candidate_value(str(key), notes[key])
			if _release_candidate_value_has_evidence(value):
				normalized_notes[str(key)] = value
		if not normalized_notes.is_empty():
			out["playtest_notes"] = normalized_notes
	if evidence.has("manual_scenario_results") and evidence["manual_scenario_results"] is Array:
		var results: Array = []
		for raw in Array(evidence["manual_scenario_results"]):
			if not (raw is Dictionary):
				continue
			var result := {}
			for key in RELEASE_CANDIDATE_MANUAL_RESULT_KEYS:
				if not raw.has(key):
					continue
				var value: Variant = _normalized_release_candidate_value(str(key), raw[key])
				if _release_candidate_value_has_evidence(value):
					result[str(key)] = value
			if not result.is_empty():
				results.append(result)
		if not results.is_empty():
			out["manual_scenario_results"] = results
	if evidence.has("manual_playtest_issues") and evidence["manual_playtest_issues"] is Array:
		var issues: Array = []
		for raw in Array(evidence["manual_playtest_issues"]):
			if not (raw is Dictionary):
				continue
			var issue := {}
			for key in RELEASE_CANDIDATE_MANUAL_ISSUE_KEYS:
				if not raw.has(key):
					continue
				var value: Variant = _normalized_release_candidate_value(str(key), raw[key])
				if _release_candidate_value_has_evidence(value):
					issue[str(key)] = value
			if not issue.is_empty():
				issues.append(issue)
		if not issues.is_empty():
			out["manual_playtest_issues"] = issues
	if evidence.has("manual_playtest_resolved_issues") \
			and evidence["manual_playtest_resolved_issues"] is Array:
		var resolved_issues: Array = []
		for raw in Array(evidence["manual_playtest_resolved_issues"]):
			if not (raw is Dictionary):
				continue
			var issue := {}
			for key in RELEASE_CANDIDATE_MANUAL_RESOLVED_ISSUE_KEYS:
				if not raw.has(key):
					continue
				var value: Variant = _normalized_release_candidate_value(str(key), raw[key])
				if _release_candidate_value_has_evidence(value):
					issue[str(key)] = value
			if not issue.is_empty():
				resolved_issues.append(issue)
		if not resolved_issues.is_empty():
			out["manual_playtest_resolved_issues"] = resolved_issues
	if evidence.has("headless_scenario_rehearsal") \
			and evidence["headless_scenario_rehearsal"] is Dictionary:
		var rehearsal: Dictionary = evidence["headless_scenario_rehearsal"]
		var normalized_rehearsal := {}
		for key in ["passed", "manual_playtest_replacement"]:
			if rehearsal.has(key):
				normalized_rehearsal[key] = bool(rehearsal.get(key, false))
		for key in ["review_type"]:
			if not rehearsal.has(key):
				continue
			var value := str(rehearsal.get(key, "")).strip_edges()
			if value != "":
				normalized_rehearsal[key] = value
		var rehearsal_results: Array = []
		for raw in Array(rehearsal.get("results", [])):
			if not (raw is Dictionary):
				continue
			var item := {}
			for key in RELEASE_CANDIDATE_REHEARSAL_RESULT_KEYS:
				if raw.has(key):
					var value: Variant = _normalized_release_candidate_value(str(key), raw[key])
					if _release_candidate_value_has_evidence(value):
						item[str(key)] = value
			for key in ["class_contract_ok", "mode_contract_ok", "seed_contract_ok"]:
				if raw.has(key):
					item[key] = bool(raw.get(key, false))
			if not item.is_empty():
				rehearsal_results.append(item)
		if not rehearsal_results.is_empty():
			normalized_rehearsal["results"] = rehearsal_results
		var completed_count := maxi(int(rehearsal.get(
			"completed_count", rehearsal_results.size())), 0)
		var required_count := maxi(int(rehearsal.get(
			"required_count", rehearsal_results.size())), 0)
		if completed_count > 0:
			normalized_rehearsal["completed_count"] = completed_count
		if required_count > 0:
			normalized_rehearsal["required_count"] = required_count
		if not normalized_rehearsal.is_empty():
			out["headless_scenario_rehearsal"] = normalized_rehearsal
	if evidence.has("asset_self_review") and evidence["asset_self_review"] is Dictionary:
		var review: Dictionary = evidence["asset_self_review"]
		var normalized_review := {}
		for key in RELEASE_CANDIDATE_ASSET_REVIEW_BOOL_KEYS:
			if review.has(key):
				normalized_review[str(key)] = bool(review.get(key, false))
		for key in ["review_type", "notes"]:
			if not review.has(key):
				continue
			var value := str(review.get(key, "")).strip_edges()
			if value != "":
				normalized_review[key] = value
		for key in RELEASE_CANDIDATE_ASSET_REVIEW_COUNT_KEYS:
			if review.has(key):
				normalized_review[key] = maxi(int(review.get(key, 0)), 0)
		if not normalized_review.is_empty():
			out["asset_self_review"] = normalized_review
	if evidence.has("export_package") and evidence["export_package"] is Dictionary:
		var package: Dictionary = evidence["export_package"]
		var normalized_package := {}
		for key in ["passed", "booted"]:
			if package.has(key):
				normalized_package[key] = bool(package.get(key, false))
		for key in ["preset_name", "executable_path"]:
			if not package.has(key):
				continue
			var value := str(package.get(key, "")).strip_edges()
			if value != "":
				normalized_package[key] = value
		if not normalized_package.is_empty():
			out["export_package"] = normalized_package
	return out

static func _normalized_release_candidate_value(key: String, value: Variant) -> Variant:
	match key:
		"seed", "scenario_index":
			return maxi(int(value), 0)
		"pace_avg_sec", "pace_boss_sec":
			return maxf(float(value), 0.0)
	return str(value).strip_edges()

static func _release_candidate_value_has_evidence(value: Variant) -> bool:
	if value is int or value is float:
		return float(value) > 0.0
	if value is Array:
		return not value.is_empty()
	if value is Dictionary:
		return not value.is_empty()
	return str(value).strip_edges() != ""

static func _release_candidate_notes_ready(notes: Dictionary) -> bool:
	for key in RELEASE_CANDIDATE_NOTE_KEYS:
		if not notes.has(key) or not _release_candidate_value_has_evidence(notes[key]):
			return false
	return true

static func _release_candidate_asset_self_review_ready(review: Dictionary) -> bool:
	for key in RELEASE_CANDIDATE_ASSET_REVIEW_BOOL_KEYS:
		if not bool(review.get(key, false)):
			return false
	for key in RELEASE_CANDIDATE_ASSET_REVIEW_COUNT_KEYS:
		if int(review.get(key, 0)) <= 0:
			return false
	return str(review.get("review_type", "")).strip_edges() != "" \
			and str(review.get("notes", "")).strip_edges() != ""

static func _release_candidate_smoke_suite_ready(smoke: Dictionary) -> bool:
	return bool(smoke.get("passed", false)) and int(smoke.get("count", 0)) >= 70

static func _release_candidate_export_package_ready(package: Dictionary) -> bool:
	return bool(package.get("passed", false)) and bool(package.get("booted", false)) \
			and str(package.get("executable_path", "")).strip_edges() != ""

static func _release_candidate_rehearsal_ready(rehearsal: Dictionary) -> bool:
	if not bool(rehearsal.get("passed", false)):
		return false
	if bool(rehearsal.get("manual_playtest_replacement", true)):
		return false
	if str(rehearsal.get("review_type", "")) != "headless_scenario_contract_rehearsal":
		return false
	for raw in Array(rehearsal.get("results", [])):
		if not (raw is Dictionary):
			continue
		var result: Dictionary = raw
		if str(result.get("result", "")).strip_edges().to_lower() == "pass" \
				and str(result.get("evidence_source", "")) == "headless_rehearsal":
			return true
	return false

static func _release_candidate_manual_scenario_count(results: Array) -> int:
	var completed_keys := {}
	for raw in results:
		if not (raw is Dictionary):
			continue
		var result: Dictionary = raw
		if _release_candidate_manual_result_ready(result):
			completed_keys[_release_candidate_scenario_key(result)] = true
	return completed_keys.size()

static func _release_candidate_manual_result_ready(result: Dictionary) -> bool:
	return int(result.get("seed", 0)) > 0 \
			and str(result.get("mode", "")).strip_edges() != "" \
			and str(result.get("class_id", "")).strip_edges() != "" \
			and str(result.get("goal", "")).strip_edges() != "" \
			and _release_candidate_manual_result_passed(str(
				result.get("result", "")).strip_edges()) \
			and _release_candidate_manual_evidence_source_ok(str(
				result.get("evidence_source", "")).strip_edges()) \
			and str(result.get("notes", "")).strip_edges() != ""

static func _release_candidate_manual_result_passed(result: String) -> bool:
	return ["pass", "passed", "ok", "success"].has(result.strip_edges().to_lower())

static func _release_candidate_manual_issue_ready(issue: Dictionary) -> bool:
	return int(issue.get("seed", 0)) > 0 \
			and str(issue.get("mode", "")).strip_edges() != "" \
			and str(issue.get("class_id", "")).strip_edges() != "" \
			and str(issue.get("goal", "")).strip_edges() != "" \
			and _release_candidate_manual_issue_result_open(str(
				issue.get("result", "")).strip_edges()) \
			and str(issue.get("issue_type", "")).strip_edges() != "" \
			and _release_candidate_manual_evidence_source_ok(str(
				issue.get("evidence_source", "")).strip_edges()) \
			and str(issue.get("notes", "")).strip_edges() != ""

static func _release_candidate_manual_issue_result_open(result: String) -> bool:
	return ["fail", "failed", "blocked", "bug", "needs_fix", "regression"].has(
		result.strip_edges().to_lower())

static func _release_candidate_manual_issue_resolution_ready(resolution: Dictionary) -> bool:
	return int(resolution.get("seed", 0)) > 0 \
			and str(resolution.get("mode", "")).strip_edges() != "" \
			and str(resolution.get("class_id", "")).strip_edges() != "" \
			and str(resolution.get("goal", "")).strip_edges() != "" \
			and str(resolution.get("issue_type", "")).strip_edges() != "" \
			and _release_candidate_manual_issue_resolved(str(
				resolution.get("resolution_result", "")).strip_edges()) \
			and _release_candidate_manual_evidence_source_ok(str(
				resolution.get("evidence_source", "")).strip_edges()) \
			and str(resolution.get("resolution_notes", "")).strip_edges() != ""

static func _release_candidate_manual_issue_resolved(result: String) -> bool:
	return ["fixed", "fixed_retest_pass", "resolved", "verified"].has(
		result.strip_edges().to_lower())

static func _release_candidate_manual_evidence_source_ok(source: String) -> bool:
	return ["manual_playtest", "human_playtest", "recorded_playtest"].has(source)

static func _release_candidate_manual_issue_key(issue: Dictionary) -> String:
	return "%d|%s|%s|%s|%s" % [
		int(issue.get("seed", 0)),
		str(issue.get("mode", "")).strip_edges(),
		str(issue.get("class_id", "")).strip_edges(),
		str(issue.get("goal", "")).strip_edges(),
		str(issue.get("issue_type", "")).strip_edges(),
	]

static func _release_candidate_scenario_key(result: Dictionary) -> String:
	return "%d|%s|%s|%s" % [
		int(result.get("seed", 0)),
		str(result.get("mode", "")).strip_edges(),
		str(result.get("class_id", "")).strip_edges(),
		str(result.get("goal", "")).strip_edges(),
	]

static func _can_afford(data: Dictionary, costs: Dictionary) -> bool:
	if costs.is_empty():
		return false
	for key in costs.keys():
		if int(data.get(key, 0)) < int(costs[key]):
			return false
	return true

static func save_data(data: Dictionary, path: String = SAVE_PATH) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("MetaProgression: cannot save %s" % path)
		return
	file.store_string(JSON.stringify(data))
