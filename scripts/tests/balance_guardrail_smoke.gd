extends SceneTree

const BALANCE_GUARDRAIL_PATH := "res://scripts/balance/balance_guardrail.gd"
const PlayerClassDBScript := preload("res://scripts/classes/player_class_db.gd")

func _init() -> void:
	var failures: Array[String] = []

	_check_balance_guardrail(failures)

	if failures.is_empty():
		print("Balance guardrail smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_balance_guardrail(failures: Array[String]) -> void:
	if not ResourceLoader.exists(BALANCE_GUARDRAIL_PATH):
		failures.append("BalanceGuardrail should exist for GDD KPI pacing checks")
		return
	var script: Variant = load(BALANCE_GUARDRAIL_PATH)
	for method_name in ["report", "starter_dps_for_class", "playtest_plan",
			"playtest_summary", "playtest_objective_summary", "review_playtest_evidence",
			"tuning_patch_preview", "tuning_experiment_patch"]:
		if not script.has_method(method_name):
			failures.append("BalanceGuardrail should expose %s" % method_name)
			return
	var report: Dictionary = script.call("report")
	if not bool(report.get("ready", false)):
		failures.append("balance guardrail hard failures: %s" % report.get("hard_failures", []))
	var targets: Dictionary = report.get("gdd_targets", {})
	if targets.get("normal_ttk_sec", Vector2.ZERO) != Vector2(1.0, 3.0):
		failures.append("balance guardrail should encode GDD normal TTK target 1-3s")
	if targets.get("boss_ttk_sec", Vector2.ZERO) != Vector2(120.0, 240.0):
		failures.append("balance guardrail should encode GDD boss target 2-4 minutes")
	var starter_dps: Dictionary = report.get("starter_dps", {})
	if starter_dps.size() < PlayerClassDBScript.all().size():
		failures.append("balance guardrail should estimate starter DPS for every class")
	for class_id in starter_dps.keys():
		if float(starter_dps[class_id]) <= 0.0:
			failures.append("%s starter DPS should be positive" % str(class_id))
	var normal_ttk: Dictionary = report.get("normal_enemy_ttk_sec", {})
	if normal_ttk.is_empty():
		failures.append("balance guardrail should estimate normal enemy TTK")
	for enemy_id in ["stone_rat", "glyph_archer", "slag_thrower", "mycelium_archer"]:
		if not normal_ttk.has(enemy_id):
			failures.append("balance guardrail should include representative enemy TTK: %s" % enemy_id)
	var boss_ttk: Dictionary = report.get("boss_ttk_sec", {})
	for boss_id in ["cave_golem_boss", "spore_golem_boss", "forge_golem_boss", "archive_golem_boss"]:
		if not boss_ttk.has(boss_id):
			failures.append("balance guardrail should include boss pacing estimate: %s" % boss_id)
		else:
			var boss_target: Vector2 = targets.get("boss_ttk_sec", Vector2.ZERO)
			var ttk := float(boss_ttk.get(boss_id, 0.0))
			if ttk < boss_target.x or ttk > boss_target.y:
				failures.append("%s boss TTK should be inside GDD target %.0f-%.0fs, got %.1fs" % [
					boss_id,
					boss_target.x,
					boss_target.y,
					ttk,
				])
	var role_coverage: Dictionary = report.get("biome_role_coverage", {})
	if role_coverage.size() < 4:
		failures.append("balance guardrail should cover every biome pool")
	for biome_id in role_coverage.keys():
		var coverage: Dictionary = role_coverage[biome_id]
		for role in ["frontline", "ranged", "special", "miniboss", "boss"]:
			if not bool(coverage.get(role, false)):
				failures.append("%s should cover %s enemy role" % [str(biome_id), role])
	var warnings: Array = report.get("warnings", [])
	if not warnings.is_empty():
		failures.append("static balance data should be inside guardrails before playtest: %s" % str(warnings))
	var tuning_backlog: Array = report.get("tuning_backlog", [])
	if not tuning_backlog.is_empty():
		failures.append("static balance tuning backlog should be empty before playtest: %s" % str(tuning_backlog))
	var playtest_plan: Array = report.get("playtest_plan", [])
	if not playtest_plan.is_empty():
		failures.append("playtest tuning plan should be empty when static balance is inside guardrails")
	var direct_plan: Array = script.call("playtest_plan", 2, report)
	if not direct_plan.is_empty():
		failures.append("playtest_plan should return no items when no tuning backlog exists")
	var playtest_summary := str(report.get("playtest_summary", ""))
	for token in ["Tuning Focus: None", "Pace evidence ready"]:
		if not playtest_summary.contains(token):
			failures.append("playtest summary missing token: %s" % token)
	var playtest_objective := str(report.get("playtest_objective_summary", ""))
	for token in ["Playtest Objective: None", "Target met", "Pace evidence ready"]:
		if not playtest_objective.contains(token):
			failures.append("playtest objective missing token: %s" % token)
	var direct_objective := str(script.call("playtest_objective_summary", report))
	if direct_objective != playtest_objective:
		failures.append("playtest_objective_summary should match report objective summary")
	var patch_preview: Dictionary = script.call("tuning_patch_preview", report)
	if not patch_preview.is_empty():
		failures.append("tuning patch preview should be empty when static balance is inside guardrails")
	var boss_item := {
		"id": "cave_golem_boss",
		"biome": "ancient_cave",
		"kind": "boss_ttk",
		"current_ttk_sec": 85.0,
		"target_ttk_sec": Vector2(120.0, 240.0),
		"direction": "too_fast",
		"severity": "medium",
	}
	var boss_review: Dictionary = script.call("review_playtest_evidence", boss_item, {
		"pace_boss_sec": 85.0,
		"sample_runs": 2,
	})
	if not bool(boss_review.get("evidence_ready", false)):
		failures.append("playtest evidence review should accept measured boss pace evidence")
	if bool(boss_review.get("requires_more_evidence", true)):
		failures.append("playtest evidence review should unblock when measured evidence exists")
	if str(boss_review.get("decision", "")) != "increase_boss_effective_hp_or_phase_downtime":
		failures.append("fast boss evidence should recommend increasing effective boss durability")
	if not is_equal_approx(float(boss_review.get("measured_ttk_sec", 0.0)), 85.0):
		failures.append("playtest evidence review should preserve measured boss TTK")
	if boss_review.get("target_ttk_sec", Vector2.ZERO) != Vector2(120.0, 240.0):
		failures.append("playtest evidence review should preserve boss target TTK")
	if not is_equal_approx(float(boss_review.get("suggested_multiplier", 0.0)), 120.0 / 85.0):
		failures.append("playtest evidence review should calculate multiplier from measured boss pace")
	if not str(boss_review.get("evidence_source", "")).contains("pace_boss_sec"):
		failures.append("playtest evidence review should explain the measured evidence source")
	var stable_review: Dictionary = script.call("review_playtest_evidence", boss_item, {
		"pace_boss_sec": 150.0,
		"sample_runs": 2,
	})
	if str(stable_review.get("decision", "")) != "hold":
		failures.append("in-range boss evidence should hold tuning")
	if not is_equal_approx(float(stable_review.get("suggested_multiplier", 0.0)), 1.0):
		failures.append("in-range boss evidence should keep multiplier at 1.0")
	var missing_review: Dictionary = script.call("review_playtest_evidence", boss_item, {})
	if bool(missing_review.get("evidence_ready", true)):
		failures.append("missing playtest evidence should not be ready")
	if not bool(missing_review.get("requires_more_evidence", false)):
		failures.append("missing playtest evidence should require more evidence")
	var measured_patch: Dictionary = script.call("tuning_patch_preview", {
		"tuning_backlog": [boss_item],
		"playtest_evidence": {
			"cave_golem_boss": {
				"pace_boss_sec": 85.0,
				"sample_runs": 2,
			},
		},
	})
	if str(measured_patch.get("playtest_decision", "")) != "increase_boss_effective_hp_or_phase_downtime":
		failures.append("tuning patch preview should expose measured playtest decision")
	if not bool(measured_patch.get("evidence_ready", false)):
		failures.append("tuning patch preview should expose ready measured evidence")
	if not is_equal_approx(float(measured_patch.get("measured_ttk_sec", 0.0)), 85.0):
		failures.append("tuning patch preview should use measured TTK when evidence exists")
	if not is_equal_approx(float(measured_patch.get("suggested_multiplier", 0.0)), 120.0 / 85.0):
		failures.append("tuning patch preview should calculate multiplier from measured evidence")
	var experiment_patch: Dictionary = script.call("tuning_experiment_patch", {
		"tuning_backlog": [boss_item],
		"playtest_evidence": {
			"cave_golem_boss": {
				"pace_boss_sec": 85.0,
				"sample_runs": 2,
			},
		},
	})
	if not bool(experiment_patch.get("enabled", false)):
		failures.append("tuning experiment patch should enable when boss evidence is ready")
	if str(experiment_patch.get("source", "")) != "playtest_evidence":
		failures.append("tuning experiment patch should preserve playtest evidence source")
	if str(experiment_patch.get("boss_variant", "")) != "cave_golem":
		failures.append("tuning experiment patch should map boss id to boss variant")
	if bool(experiment_patch.get("requires_playtest_evidence", true)):
		failures.append("tuning experiment patch should not require more evidence")
	if not is_equal_approx(float(experiment_patch.get("hp_multiplier", 0.0)), 120.0 / 85.0):
		failures.append("tuning experiment patch should convert measured pace into hp multiplier")
	var clamped_experiment: Dictionary = script.call("tuning_experiment_patch", {
		"tuning_backlog": [boss_item],
		"playtest_evidence": {
			"cave_golem_boss": {
				"pace_boss_sec": 20.0,
				"sample_runs": 1,
			},
		},
	})
	if not is_equal_approx(float(clamped_experiment.get("hp_multiplier", 0.0)), 1.5):
		failures.append("tuning experiment patch should clamp aggressive hp multipliers")
	var gated_experiment: Dictionary = script.call("tuning_experiment_patch", {
		"tuning_backlog": [boss_item],
	})
	if bool(gated_experiment.get("enabled", true)):
		failures.append("tuning experiment patch should stay disabled without measured evidence")
	if not bool(gated_experiment.get("requires_playtest_evidence", false)):
		failures.append("disabled tuning experiment patch should explain evidence gate")
	var no_patch: Dictionary = script.call("tuning_patch_preview", {"tuning_backlog": []})
	if not no_patch.is_empty():
		failures.append("tuning_patch_preview should be empty when no tuning backlog exists")
	var summary := str(report.get("summary", ""))
	for token in ["TTK", "boss", "warnings", "tune"]:
		if not summary.contains(token):
			failures.append("balance summary missing token: %s" % token)
