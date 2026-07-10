class_name BalanceGuardrail
extends RefCounted

const NORMAL_TTK_TARGET_SEC := Vector2(1.0, 3.0)
const BOSS_TTK_TARGET_SEC := Vector2(120.0, 240.0)
const BOSS_SUSTAIN_DPS_MULT := 0.65
const BiomeDBScript := preload("res://scripts/dungeon_gen/biome_db.gd")
const PlayerClassDBScript := preload("res://scripts/classes/player_class_db.gd")
const WeaponDBScript := preload("res://scripts/weapons/weapon_db.gd")

const FRONTLINE_KINDS := ["melee", "melee_charger", "tanker", "armored_melee"]
const RANGED_KINDS := ["ranged", "caster"]
const SPECIAL_KINDS := ["exploder", "ambusher", "flyer"]
const BOSS_KINDS := ["miniboss", "boss"]

static func starter_dps_for_class(class_id: String) -> float:
	var class_data := PlayerClassDBScript.get_class_data(class_id)
	if class_data.is_empty():
		return 0.0
	var weapon_id := WeaponDBScript.starter_weapon_for_class(class_id)
	var weapon := WeaponDBScript.get_weapon(weapon_id)
	if weapon.is_empty():
		return 0.0
	return _weapon_dps(weapon, class_data)

static func report() -> Dictionary:
	var hard_failures: Array[String] = []
	var warnings: Array[String] = []
	var tuning_backlog: Array = []
	var starter_dps := _starter_dps_report(hard_failures)
	var median_dps := _median(starter_dps.values())
	if median_dps <= 0.0:
		hard_failures.append("median starter DPS should be positive")
	var normal_ttk := {}
	var boss_ttk := {}
	var role_coverage := {}
	var enemy_count := 0
	for floor_index in range(1, BiomeDBScript.BIOMES.size() + 1):
		var biome: Dictionary = BiomeDBScript.floor_biome(floor_index)
		var biome_id := str(biome.get("id", "biome_%d" % floor_index))
		var pool := _load_pool(str(biome.get("enemy_pool", "")), biome_id, hard_failures)
		if pool.is_empty():
			continue
		var coverage := _empty_role_coverage()
		var hp_mult := maxf(float(biome.get("enemy_hp_mult", 1.0)), 0.01)
		for enemy in Array(pool.get("enemies", [])):
			if not (enemy is Dictionary):
				hard_failures.append("%s enemy entry should be a Dictionary" % biome_id)
				continue
			enemy_count += 1
			_review_enemy_entry(enemy, biome_id, hard_failures)
			_mark_role_coverage(coverage, str(enemy.get("kind", "")))
			if median_dps <= 0.0:
				continue
			var enemy_id := str(enemy.get("id", ""))
			var kind := str(enemy.get("kind", ""))
			var scaled_hp := float(enemy.get("hp", 0)) * hp_mult
			if kind == "boss":
				var ttk := scaled_hp / maxf(median_dps * BOSS_SUSTAIN_DPS_MULT, 0.01)
				boss_ttk[enemy_id] = ttk
				if ttk < BOSS_TTK_TARGET_SEC.x or ttk > BOSS_TTK_TARGET_SEC.y:
					var warning := "%s boss raw TTK %.1fs outside GDD %.0f-%.0fs; tune with phase downtime/playtest" % [
						enemy_id,
						ttk,
						BOSS_TTK_TARGET_SEC.x,
						BOSS_TTK_TARGET_SEC.y,
					]
					warnings.append(warning)
					_append_tuning_item(tuning_backlog, enemy_id, biome_id, "boss_ttk",
						ttk, BOSS_TTK_TARGET_SEC, warning)
			elif not BOSS_KINDS.has(kind):
				var ttk := scaled_hp / median_dps
				normal_ttk[enemy_id] = ttk
				_warn_normal_ttk(enemy, biome_id, ttk, warnings, tuning_backlog)
		role_coverage[biome_id] = coverage
		_review_role_coverage(coverage, biome_id, hard_failures)
	if enemy_count <= 0:
		hard_failures.append("balance guardrail should load at least one enemy")
	var focus_plan := playtest_plan(5, {"tuning_backlog": tuning_backlog})
	return {
		"ready": hard_failures.is_empty(),
		"hard_failures": hard_failures,
		"warnings": warnings,
		"gdd_targets": {
			"normal_ttk_sec": NORMAL_TTK_TARGET_SEC,
			"boss_ttk_sec": BOSS_TTK_TARGET_SEC,
		},
		"starter_dps": starter_dps,
		"median_starter_dps": median_dps,
		"normal_enemy_ttk_sec": normal_ttk,
		"boss_ttk_sec": boss_ttk,
		"biome_role_coverage": role_coverage,
		"tuning_backlog": tuning_backlog,
		"playtest_plan": focus_plan,
		"playtest_summary": playtest_summary(3, {"tuning_backlog": tuning_backlog}),
		"playtest_objective_summary": playtest_objective_summary({"tuning_backlog": tuning_backlog}),
		"summary": "TTK median starter DPS %.1f | normal enemies %d | boss estimates %d | warnings %d | tune %d" % [
			median_dps,
			normal_ttk.size(),
			boss_ttk.size(),
			warnings.size(),
			tuning_backlog.size(),
		],
	}

static func _starter_dps_report(hard_failures: Array[String]) -> Dictionary:
	var out := {}
	for class_data in PlayerClassDBScript.all():
		if not (class_data is Dictionary):
			hard_failures.append("class entry should be a Dictionary")
			continue
		var class_id := str((class_data as Dictionary).get("id", ""))
		var weapon_id := WeaponDBScript.starter_weapon_for_class(class_id)
		var weapon := WeaponDBScript.get_weapon(weapon_id)
		if class_id == "":
			hard_failures.append("class id should not be empty")
			continue
		if weapon.is_empty():
			hard_failures.append("%s starter weapon missing: %s" % [class_id, weapon_id])
			out[class_id] = 0.0
			continue
		var dps := _weapon_dps(weapon, class_data)
		out[class_id] = dps
		if dps <= 0.0:
			hard_failures.append("%s starter DPS should be positive" % class_id)
	return out

static func _weapon_dps(weapon: Dictionary, class_data: Dictionary) -> float:
	var base_damage := float(weapon.get("dmg", 0)) * 3.0
	var stats: Dictionary = class_data.get("stats", {})
	var damage_mult := 1.0 + (float(stats.get("damage", 5)) - 5.0) * 0.08
	var crit_chance := float(stats.get("crit", 0)) * 0.02
	var expected_damage := base_damage * damage_mult * (1.0 + crit_chance * 0.5)
	expected_damage *= _projectile_pattern_factor(weapon)
	var cooldown := maxf(1.2 - float(weapon.get("speed", 5)) * 0.09, 0.15)
	return expected_damage / cooldown

static func _projectile_pattern_factor(weapon: Dictionary) -> float:
	var group := str(weapon.get("group", ""))
	var volley_count := 1
	if group == "pistol":
		volley_count = 2
	elif ["bow", "crossbow"].has(group):
		volley_count = 3
	elif group == "orb":
		volley_count = 2
	if volley_count <= 1:
		return 1.0
	var spread_hit_rate := 0.75 if ["bow", "crossbow"].has(group) else 0.85
	return lerpf(1.0, sqrt(float(volley_count)), spread_hit_rate)

static func _load_pool(path: String, biome_id: String, hard_failures: Array[String]) -> Dictionary:
	if path.strip_edges() == "":
		hard_failures.append("%s enemy pool path should not be empty" % biome_id)
		return {}
	if not FileAccess.file_exists(path):
		hard_failures.append("%s enemy pool missing: %s" % [biome_id, path])
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		hard_failures.append("%s enemy pool should parse as Dictionary" % biome_id)
		return {}
	var pool := parsed as Dictionary
	if str(pool.get("biome", "")) != biome_id:
		hard_failures.append("%s enemy pool biome id mismatch" % biome_id)
	return pool

static func _review_enemy_entry(
		enemy: Dictionary,
		biome_id: String,
		hard_failures: Array[String],
) -> void:
	var enemy_id := str(enemy.get("id", ""))
	var kind := str(enemy.get("kind", ""))
	if enemy_id == "":
		hard_failures.append("%s enemy id should not be empty" % biome_id)
	if kind == "":
		hard_failures.append("%s:%s kind should not be empty" % [biome_id, enemy_id])
	if int(enemy.get("hp", 0)) <= 0:
		hard_failures.append("%s:%s hp should be positive" % [biome_id, enemy_id])
	if int(enemy.get("dmg", 0)) <= 0:
		hard_failures.append("%s:%s dmg should be positive" % [biome_id, enemy_id])
	if not BOSS_KINDS.has(kind) and int(enemy.get("cost", 0)) <= 0:
		hard_failures.append("%s:%s budget enemy cost should be positive" % [biome_id, enemy_id])

static func _warn_normal_ttk(
		enemy: Dictionary,
		biome_id: String,
		ttk: float,
		warnings: Array[String],
		tuning_backlog: Array,
) -> void:
	var kind := str(enemy.get("kind", ""))
	var enemy_id := str(enemy.get("id", ""))
	var cost := int(enemy.get("cost", 0))
	var min_ttk := 0.55 if cost <= 2 or SPECIAL_KINDS.has(kind) else NORMAL_TTK_TARGET_SEC.x
	var max_ttk := 6.0 if ["tanker", "armored_melee"].has(kind) else NORMAL_TTK_TARGET_SEC.y
	if ttk < min_ttk or ttk > max_ttk:
		var target := Vector2(min_ttk, max_ttk)
		var warning := "%s:%s normal TTK %.1fs outside guardrail %.1f-%.1fs" % [
			biome_id,
			enemy_id,
			ttk,
			min_ttk,
			max_ttk,
		]
		warnings.append(warning)
		_append_tuning_item(tuning_backlog, enemy_id, biome_id, "normal_ttk",
			ttk, target, warning)

static func _append_tuning_item(
		backlog: Array,
		id: String,
		biome_id: String,
		kind: String,
		current_ttk: float,
		target: Vector2,
		warning: String,
) -> void:
	var direction := "too_fast" if current_ttk < target.x else "too_slow"
	backlog.append({
		"id": id,
		"biome": biome_id,
		"kind": kind,
		"severity": _ttk_severity(current_ttk, target),
		"direction": direction,
		"current_ttk_sec": current_ttk,
		"target_ttk_sec": target,
		"recommendation": _tuning_recommendation(kind, direction),
		"source_warning": warning,
	})

static func playtest_plan(max_items: int = 5, source_report: Dictionary = {}) -> Array[Dictionary]:
	var backlog: Array = source_report.get("tuning_backlog", [])
	if backlog.is_empty() and source_report.is_empty():
		backlog = report().get("tuning_backlog", [])
	var ranked: Array[Dictionary] = []
	for item in backlog:
		if not (item is Dictionary):
			continue
		var entry := (item as Dictionary).duplicate(true)
		entry["priority"] = _priority_for_severity(str(entry.get("severity", "")))
		entry["evidence_required"] = _playtest_evidence_required(str(entry.get("kind", "")))
		entry["playtest_instruction"] = _playtest_instruction(entry)
		ranked.append(entry)
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _compare_playtest_items(a, b))
	return ranked.slice(0, maxi(max_items, 0))

static func playtest_summary(max_items: int = 3, source_report: Dictionary = {}) -> String:
	var plan := playtest_plan(max_items, source_report)
	if plan.is_empty():
		return "Tuning Focus: None | Pace evidence ready"
	var parts: Array[String] = []
	for item in plan:
		parts.append("%s %s %s" % [
			str(item.get("priority", "P3")),
			str(item.get("id", "")),
			str(item.get("kind", "")),
		])
	return "Tuning Focus: %s | Pace evidence needed" % " | ".join(parts)

static func playtest_objective_summary(source_report: Dictionary = {}) -> String:
	var plan := playtest_plan(1, source_report)
	if plan.is_empty():
		return "Playtest Objective: None | Current stable | Target met | Pace evidence ready"
	var item: Dictionary = plan[0]
	var target: Vector2 = item.get("target_ttk_sec", Vector2.ZERO)
	return "Playtest Objective: %s %s %s | Current %.1fs | Target %.1f-%.1fs | %s" % [
		str(item.get("priority", "P3")),
		str(item.get("id", "")),
		str(item.get("kind", "")),
		float(item.get("current_ttk_sec", 0.0)),
		target.x,
		target.y,
		str(item.get("evidence_required", "")),
	]

static func review_playtest_evidence(item: Dictionary, evidence: Dictionary) -> Dictionary:
	var kind := str(item.get("kind", ""))
	var target: Vector2 = item.get("target_ttk_sec", Vector2.ZERO)
	var measured_key := _measured_ttk_key(kind, evidence)
	var measured := 0.0
	if measured_key != "":
		measured = float(evidence.get(measured_key, 0.0))
	var ready := measured > 0.0
	var multiplier := _suggested_tuning_multiplier(measured, target) if ready else 1.0
	return {
		"id": str(item.get("id", "")),
		"kind": kind,
		"target_ttk_sec": target,
		"measured_ttk_sec": measured,
		"suggested_multiplier": multiplier,
		"decision": _playtest_tuning_decision(kind, measured, target) if ready else "collect_more_evidence",
		"evidence_ready": ready,
		"requires_more_evidence": not ready,
		"evidence_source": measured_key if ready else _playtest_evidence_required(kind),
		"sample_runs": int(evidence.get("sample_runs", 0)),
	}

static func tuning_patch_preview(source_report: Dictionary = {}) -> Dictionary:
	var plan := playtest_plan(1, source_report)
	if plan.is_empty():
		return {}
	var item: Dictionary = plan[0]
	var target: Vector2 = item.get("target_ttk_sec", Vector2.ZERO)
	var current := float(item.get("current_ttk_sec", 0.0))
	var kind := str(item.get("kind", ""))
	var multiplier := _suggested_tuning_multiplier(current, target)
	var patch := {
		"priority": str(item.get("priority", "P3")),
		"id": str(item.get("id", "")),
		"biome": str(item.get("biome", "")),
		"kind": kind,
		"target_field": _tuning_target_field(kind),
		"suggested_multiplier": multiplier,
		"current_ttk_sec": current,
		"target_ttk_sec": target,
		"requires_playtest_evidence": true,
		"evidence_required": str(item.get("evidence_required", "")),
		"patch_instruction": "Capture pace evidence, then test %.2fx %s for %s." % [
			multiplier,
			_tuning_target_field(kind),
			str(item.get("id", "")),
		],
	}
	var evidence_map: Dictionary = source_report.get("playtest_evidence", {})
	var item_id := str(item.get("id", ""))
	if evidence_map.has(item_id) and evidence_map[item_id] is Dictionary:
		var evidence_review := review_playtest_evidence(item, evidence_map[item_id])
		if bool(evidence_review.get("evidence_ready", false)):
			patch["suggested_multiplier"] = float(evidence_review.get("suggested_multiplier", multiplier))
			patch["measured_ttk_sec"] = float(evidence_review.get("measured_ttk_sec", current))
			patch["playtest_decision"] = str(evidence_review.get("decision", ""))
			patch["evidence_ready"] = true
			patch["evidence_source"] = str(evidence_review.get("evidence_source", ""))
			patch["requires_playtest_evidence"] = false
			patch["patch_instruction"] = "Test %.2fx %s for %s from measured %s." % [
				float(patch.get("suggested_multiplier", multiplier)),
				_tuning_target_field(kind),
				item_id,
				str(evidence_review.get("evidence_source", "")),
			]
	return patch

static func tuning_experiment_patch(source_report: Dictionary = {}) -> Dictionary:
	var patch := tuning_patch_preview(source_report)
	if patch.is_empty():
		return {"enabled": false, "reason": "no_tuning_backlog"}
	if bool(patch.get("requires_playtest_evidence", true)):
		return {
			"enabled": false,
			"requires_playtest_evidence": true,
			"id": str(patch.get("id", "")),
			"reason": "playtest_evidence_required",
		}
	if str(patch.get("kind", "")) != "boss_ttk":
		return {
			"enabled": false,
			"requires_playtest_evidence": false,
			"id": str(patch.get("id", "")),
			"reason": "boss_only_experiment",
		}
	var multiplier := clampf(float(patch.get("suggested_multiplier", 1.0)), 0.75, 1.5)
	if is_equal_approx(multiplier, 1.0):
		return {
			"enabled": false,
			"requires_playtest_evidence": false,
			"id": str(patch.get("id", "")),
			"source": "playtest_evidence",
			"reason": "hold",
		}
	var boss_id := str(patch.get("id", ""))
	return {
		"enabled": true,
		"id": boss_id,
		"biome": str(patch.get("biome", "")),
		"kind": str(patch.get("kind", "")),
		"boss_variant": _boss_variant_from_id(boss_id),
		"hp_multiplier": multiplier,
		"phase_downtime_multiplier": 1.0,
		"target_field": str(patch.get("target_field", "")),
		"source": "playtest_evidence",
		"requires_playtest_evidence": false,
		"measured_ttk_sec": float(patch.get("measured_ttk_sec", 0.0)),
		"target_ttk_sec": patch.get("target_ttk_sec", Vector2.ZERO),
		"decision": str(patch.get("playtest_decision", "")),
	}

static func _compare_playtest_items(a: Dictionary, b: Dictionary) -> bool:
	var priority_a := _priority_rank(str(a.get("priority", "P3")))
	var priority_b := _priority_rank(str(b.get("priority", "P3")))
	if priority_a != priority_b:
		return priority_a < priority_b
	var boss_a := str(a.get("kind", "")) == "boss_ttk"
	var boss_b := str(b.get("kind", "")) == "boss_ttk"
	if boss_a != boss_b:
		return boss_a
	return str(a.get("id", "")) < str(b.get("id", ""))

static func _priority_for_severity(severity: String) -> String:
	match severity:
		"critical":
			return "P0"
		"high":
			return "P1"
		"medium":
			return "P2"
	return "P3"

static func _priority_rank(priority: String) -> int:
	match priority:
		"P0":
			return 0
		"P1":
			return 1
		"P2":
			return 2
	return 3

static func _playtest_evidence_required(kind: String) -> String:
	if kind == "boss_ttk":
		return "RunSummary Pace boss clear time, phase story, damage taken, and class/weapon."
	return "RunSummary Pace room clear time, mastery badges, damage taken, and class/weapon."

static func _playtest_instruction(item: Dictionary) -> String:
	return "%s Capture Pace evidence before changing HP/damage." % str(
		item.get("recommendation", "Review timed playtest evidence."))

static func _ttk_severity(current_ttk: float, target: Vector2) -> String:
	if current_ttk < target.x:
		var ratio := current_ttk / maxf(target.x, 0.01)
		if ratio < 0.25:
			return "critical"
		if ratio < 0.5:
			return "high"
		if ratio < 0.8:
			return "medium"
		return "low"
	var ratio := current_ttk / maxf(target.y, 0.01)
	if ratio > 4.0:
		return "critical"
	if ratio > 2.0:
		return "high"
	if ratio > 1.25:
		return "medium"
	return "low"

static func _tuning_recommendation(kind: String, direction: String) -> String:
	if kind == "boss_ttk":
		if direction == "too_fast":
			return "After timed playtest, raise boss effective HP or add phase downtime."
		return "After timed playtest, lower boss effective HP or shorten downtime."
	if direction == "too_fast":
		return "After room playtest, raise HP/cost or reduce player burst exposure."
	return "After room playtest, lower HP/cost or improve enemy vulnerability windows."

static func _suggested_tuning_multiplier(current_ttk: float, target: Vector2) -> float:
	if current_ttk <= 0.0 or target == Vector2.ZERO:
		return 1.0
	if current_ttk < target.x:
		return target.x / current_ttk
	if current_ttk > target.y:
		return target.y / current_ttk
	return 1.0

static func _tuning_target_field(kind: String) -> String:
	if kind == "boss_ttk":
		return "boss_effective_hp_or_phase_downtime"
	return "enemy_hp_or_cost"

static func _boss_variant_from_id(boss_id: String) -> String:
	if boss_id.ends_with("_boss"):
		return boss_id.trim_suffix("_boss")
	return boss_id

static func _measured_ttk_key(kind: String, evidence: Dictionary) -> String:
	var keys := ["pace_boss_sec", "boss_clear_time_sec", "measured_ttk_sec"] \
			if kind == "boss_ttk" \
			else ["pace_room_sec", "pace_avg_sec", "avg_clear_time_sec", "measured_ttk_sec"]
	for key in keys:
		if evidence.has(key) and float(evidence.get(key, 0.0)) > 0.0:
			return key
	return ""

static func _playtest_tuning_decision(kind: String, measured_ttk: float, target: Vector2) -> String:
	if measured_ttk <= 0.0 or target == Vector2.ZERO:
		return "collect_more_evidence"
	if measured_ttk >= target.x and measured_ttk <= target.y:
		return "hold"
	var prefix := "increase" if measured_ttk < target.x else "decrease"
	return "%s_%s" % [prefix, _tuning_target_field(kind)]

static func _empty_role_coverage() -> Dictionary:
	return {
		"frontline": false,
		"ranged": false,
		"special": false,
		"miniboss": false,
		"boss": false,
	}

static func _mark_role_coverage(coverage: Dictionary, kind: String) -> void:
	if FRONTLINE_KINDS.has(kind):
		coverage["frontline"] = true
	if RANGED_KINDS.has(kind):
		coverage["ranged"] = true
	if SPECIAL_KINDS.has(kind):
		coverage["special"] = true
	if kind == "miniboss":
		coverage["miniboss"] = true
	if kind == "boss":
		coverage["boss"] = true

static func _review_role_coverage(
		coverage: Dictionary,
		biome_id: String,
		hard_failures: Array[String],
) -> void:
	for role in coverage.keys():
		if not bool(coverage.get(role, false)):
			hard_failures.append("%s enemy pool missing %s role" % [biome_id, str(role)])

static func _median(values: Array) -> float:
	var nums: Array[float] = []
	for value in values:
		var number := float(value)
		if number > 0.0:
			nums.append(number)
	if nums.is_empty():
		return 0.0
	nums.sort()
	var middle := int(nums.size() / 2)
	if nums.size() % 2 == 1:
		return nums[middle]
	return (nums[middle - 1] + nums[middle]) * 0.5
