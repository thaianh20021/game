class_name RunSummary
extends RefCounted
## Formats end-of-run reward banking text for the overlay.

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const CURRENCY_LABELS := {
	"soul_shards": "Shard",
	"element_cores": "Core",
	"rune_dust": "Dust",
	"blueprints": "BP",
}

static func end_message(
		result: String,
		floor: int,
		run_rewards: Dictionary,
		meta: Dictionary,
		context: Dictionary = {},
) -> String:
	var banked: Dictionary = meta.get("last_rewards", {})
	var parts := _banked_parts(banked)
	var totals := "Total: %dg | Shard %d | Core %d | Dust %d | BP %d" % [
		int(meta.get("banked_gold", 0)),
		int(meta.get("soul_shards", 0)),
		int(meta.get("element_cores", 0)),
		int(meta.get("rune_dust", 0)),
		int(meta.get("blueprints", 0)),
	]
	var records := _record_line(meta)
	var class_record := _class_record_line(meta, context)
	var mode_record := _mode_record_line(meta, context)
	var record_block := records
	if class_record != "":
		record_block += "\n" + class_record
	if mode_record != "":
		record_block += "\n" + mode_record
	var intro := _context_block(context, result, floor)
	var shop_hint := _meta_shop_hint(meta)
	if result == "victory":
		return "%sBanked this run: %s\n%s\n%s\n%s\nPress R for Class Select / Meta Shop" % [
			intro, parts, totals, record_block, shop_hint]
	var kept_block := "%s | %s | %s" % [parts, totals, records]
	if class_record != "":
		kept_block += "\n" + class_record
	if mode_record != "":
		kept_block += "\n" + mode_record
	return "%sFloor %d | Kept: %s of %dg run gold\n%s\n%s\nPress R for Class Select / Meta Shop" % [
		intro,
		floor,
		"+%dg" % int(banked.get("gold", 0)),
		int(run_rewards.get("gold", 0)),
		kept_block,
		shop_hint,
	]

static func _record_line(meta: Dictionary) -> String:
	return "Runs %d | Best F%d | Streak %d | Best Streak %d" % [
		int(meta.get("runs_finished", 0)),
		int(meta.get("best_floor", 0)),
		int(meta.get("current_win_streak", 0)),
		int(meta.get("best_win_streak", 0)),
	]

static func _class_record_line(meta: Dictionary, context: Dictionary) -> String:
	var class_id := str(context.get("class_id", "")).strip_edges()
	var class_label := str(context.get("class", "")).strip_edges()
	if class_id == "" and class_label != "":
		class_id = _mode_record_id(class_label)
	if class_id == "":
		return ""
	var records: Dictionary = meta.get("class_records", {})
	var record: Dictionary = records.get(class_id, {})
	if record.is_empty():
		return ""
	var line := "Class Record: %s | Runs %d | Wins %d | Best F%d | Seed %d" % [
		str(record.get("label", class_label if class_label != "" else class_id)),
		int(record.get("runs", 0)),
		int(record.get("victories", 0)),
		int(record.get("best_floor", 0)),
		int(record.get("best_seed", 0)),
	]
	var best_path := _readable_path(str(record.get("best_path", "")))
	if best_path != "":
		line += "\nClass Best Path: %s" % best_path
	return line

static func _mode_record_line(meta: Dictionary, context: Dictionary) -> String:
	var mode := str(context.get("mode", "")).strip_edges()
	if mode == "":
		return ""
	var records: Dictionary = meta.get("mode_records", {})
	var record: Dictionary = records.get(_mode_record_id(mode), {})
	if record.is_empty():
		return ""
	var line := "Mode Record: %s | Runs %d | Wins %d | Best F%d | Seed %d" % [
		str(record.get("label", mode)),
		int(record.get("runs", 0)),
		int(record.get("victories", 0)),
		int(record.get("best_floor", 0)),
		int(record.get("best_seed", 0)),
	]
	var best_path := _readable_path(str(record.get("best_path", "")))
	if best_path != "":
		line += "\nMode Best Path: %s" % best_path
	return line

static func _readable_path(path: String) -> String:
	var clean := path.strip_edges()
	if clean.begins_with("Path: "):
		return clean.trim_prefix("Path: ").strip_edges()
	return clean

static func _mode_record_id(mode_label: String) -> String:
	return mode_label.strip_edges().to_lower().replace(" ", "_")

static func _context_block(context: Dictionary, result: String = "", floor: int = 0) -> String:
	if context.is_empty():
		return ""
	var lines: Array[String] = []
	if context.has("seed"):
		var seed_label := str(context.get("seed_label", "Seed"))
		lines.append("%s: %s" % [seed_label if seed_label != "" else "Seed", str(context.get("seed", ""))])
	var daily_fingerprint := _daily_fingerprint_line(context.get("daily_fingerprint", {}))
	if daily_fingerprint != "":
		lines.append(daily_fingerprint)
	var mode := str(context.get("mode", ""))
	if mode != "":
		lines.append("Mode: %s" % mode)
	var difficulty := str(context.get("difficulty", ""))
	if difficulty != "":
		lines.append("Difficulty: %s" % difficulty)
	var threat := str(context.get("threat", "")).strip_edges()
	if threat != "":
		lines.append("Threat: %s" % threat)
	if result == "victory" and bool(context.get("run_finale", false)):
		var final_floor := int(context.get("final_floor", floor))
		var floor_label := "Floor %d" % final_floor if final_floor > 0 else "Final Floor"
		lines.append("Finale: %s | Final Boss defeated | Run Complete" % floor_label)
	var modifier := str(context.get("modifier", "")).strip_edges()
	if modifier != "":
		lines.append("Challenge: %s" % modifier)
	var challenge_bonus := str(context.get("challenge_bonus", "")).strip_edges()
	if challenge_bonus != "":
		lines.append("Challenge Bonus: %s" % challenge_bonus)
	var challenge_bonus_status := str(context.get("challenge_bonus_status", "")).strip_edges()
	if challenge_bonus_status != "":
		lines.append("Challenge Bonus Status: %s" % challenge_bonus_status)
	var challenge_goals := str(context.get("challenge_goals", "")).strip_edges()
	if challenge_goals != "":
		lines.append("Challenge %s" % challenge_goals)
	var challenge_goal_count := int(context.get("challenge_goal_count", 0))
	if challenge_goal_count > 0:
		lines.append("Challenge Goal Clear: %d/%d" % [
			int(context.get("challenge_goal_completed_count", 0)),
			challenge_goal_count,
		])
	var meta_bonuses := str(context.get("meta_bonuses", "")).strip_edges()
	if meta_bonuses != "" and meta_bonuses != "None":
		lines.append("Meta Bonuses: %s" % meta_bonuses)
	var class_label := str(context.get("class", ""))
	var element := str(context.get("element", ""))
	if class_label != "" or element != "":
		lines.append("Class: %s | Element: %s" % [
			class_label if class_label != "" else "-",
			element if element != "" else "-",
		])
	var weapons := str(context.get("weapons", "")).strip_edges()
	if weapons != "" and weapons != "None":
		lines.append("Weapons: %s" % weapons)
	var power_arc := str(context.get("power_arc", "")).strip_edges()
	if power_arc != "":
		lines.append("Power Arc: %s" % power_arc)
	var power_milestones := str(context.get("power_milestones", "")).strip_edges()
	if power_milestones != "" and power_milestones != "None":
		lines.append("Power Milestones: %s" % power_milestones)
	var archetype := str(context.get("archetype", ""))
	if archetype != "":
		lines.append("Archetype: %s" % archetype)
	var build := str(context.get("build", ""))
	if build != "":
		lines.append("Build: %s" % build)
	var tags := str(context.get("tags", ""))
	if tags != "":
		lines.append("Tags: %s" % tags)
	var rune_socket := str(context.get("rune_socket", ""))
	if rune_socket != "":
		lines.append("Sockets: %s" % rune_socket)
	var stat_summary := str(context.get("stat_summary", "")).strip_edges()
	if stat_summary != "":
		lines.append("Power Stats: %s" % stat_summary)
	var history := str(context.get("history", ""))
	if history != "":
		lines.append("History: %s" % history)
	var decision_history := str(context.get("decision_history", ""))
	if decision_history != "":
		lines.append("Pick Reasons: %s" % decision_history)
	var shop_history := str(context.get("shop_history", "")).strip_edges()
	if shop_history != "" and shop_history != "None":
		lines.append("Shop Picks: %s" % shop_history)
	var loot_history := str(context.get("loot_history", "")).strip_edges()
	if loot_history != "" and loot_history != "None":
		lines.append("Loot Picks: %s" % loot_history)
	var room_history := str(context.get("room_history", "")).strip_edges()
	if room_history != "" and room_history != "None":
		lines.append("Room Decisions: %s" % room_history)
	var skill_history := str(context.get("skill_history", "")).strip_edges()
	if skill_history != "" and skill_history != "None":
		lines.append("Skill Use: %s" % skill_history)
	var combo_history := str(context.get("combo_history", "")).strip_edges()
	if combo_history != "" and combo_history != "None":
		lines.append("Element Combos: %s" % combo_history)
	var boss_story := str(context.get("boss_story", "")).strip_edges()
	if boss_story != "" and boss_story != "None":
		lines.append("Boss Story: %s" % boss_story)
	var boss_pressure := str(context.get("boss_pressure", "")).strip_edges()
	if boss_pressure != "" and boss_pressure != "None":
		lines.append("Boss Pressure: %s" % boss_pressure)
	var boss_phase_timing := str(context.get("boss_phase_timing", "")).strip_edges()
	if boss_phase_timing != "" and boss_phase_timing != "None":
		lines.append("Boss Phase Timing: %s" % boss_phase_timing)
	var boss_attack_timing := str(context.get("boss_attack_timing", "")).strip_edges()
	if boss_attack_timing != "" and boss_attack_timing != "None":
		lines.append("Boss Attack Timing: %s" % boss_attack_timing)
	var damage_taken := str(context.get("damage_taken", "")).strip_edges()
	if damage_taken != "" and damage_taken != "None":
		lines.append("Damage Taken: %s" % damage_taken)
	var survival := str(context.get("survival", "")).strip_edges()
	if survival != "" and survival != "None":
		lines.append("Survival: %s" % survival)
	var final_hit := str(context.get("final_hit", "")).strip_edges()
	if final_hit != "" and final_hit != "None":
		lines.append("Final Hit: %s" % final_hit)
	var stats := str(context.get("stats", ""))
	if stats != "":
		lines.append("Stats: %s" % stats)
	var decisions := str(context.get("decisions", ""))
	if decisions != "":
		lines.append("Decisions: %s" % decisions)
	var floor_recap := str(context.get("floor_recap", "")).strip_edges()
	if floor_recap != "":
		lines.append("Floor Recap: %s" % floor_recap)
	var path := str(context.get("path", "")).strip_edges()
	if path != "":
		lines.append(path)
	var mastery := str(context.get("mastery", "")).strip_edges()
	if mastery != "":
		lines.append("Mastery: %s" % mastery)
	var pace := str(context.get("pace", "")).strip_edges()
	if pace != "":
		lines.append("Pace: %s" % pace)
	var tuning_focus := str(context.get("tuning_focus", "")).strip_edges()
	if tuning_focus != "":
		lines.append(tuning_focus)
	var playtest_objective := str(context.get("playtest_objective", "")).strip_edges()
	if playtest_objective != "":
		lines.append(playtest_objective)
	var tuning_patch := str(context.get("tuning_patch", "")).strip_edges()
	if tuning_patch != "":
		lines.append(tuning_patch)
	var balance_experiment := str(context.get("balance_experiment", "")).strip_edges()
	if balance_experiment != "":
		lines.append("Balance Experiment: %s" % balance_experiment)
	var release_audit := str(context.get("release_audit", "")).strip_edges()
	if release_audit != "":
		lines.append("Release Audit: %s" % release_audit)
	var release_decision := str(context.get("release_decision", "")).strip_edges()
	var release_replacements := int(context.get("release_replacements", 0))
	if release_decision != "" or release_replacements > 0:
		var gate_text := "Replace %d assets before public" % release_replacements \
			if release_replacements > 0 else "No replacements required"
		lines.append("Public Gate: %s | %s" % [
			release_decision if release_decision != "" else "review_required",
			gate_text,
		])
	var release_backlog := str(context.get("release_backlog", "")).strip_edges()
	if release_backlog != "":
		lines.append("Release Backlog: %s" % release_backlog)
	var release_next_action := str(context.get("release_next_action", "")).strip_edges()
	if release_next_action != "":
		lines.append("Release Next: %s" % release_next_action)
	var release_candidate_status := str(context.get("release_candidate_status", "")).strip_edges()
	var release_candidate_blockers := str(context.get("release_candidate_blockers", "")).strip_edges()
	if release_candidate_status != "" or release_candidate_blockers != "":
		lines.append("Release Candidate: %s | %s" % [
			release_candidate_status if release_candidate_status != "" else "review_required",
			release_candidate_blockers if release_candidate_blockers != "" else "clear",
		])
	var release_candidate_evidence := str(context.get("release_candidate_evidence", "")).strip_edges()
	if release_candidate_evidence != "":
		lines.append(release_candidate_evidence)
	var playtest_notes_record_command := str(
		context.get("playtest_notes_record_command", "")).strip_edges()
	if playtest_notes_record_command != "":
		lines.append("Playtest Notes Command: %s" % playtest_notes_record_command)
	var manual_scenario_evidence_draft := str(
		context.get("manual_scenario_evidence_draft", "")).strip_edges()
	if manual_scenario_evidence_draft != "":
		lines.append("Manual Evidence Draft: %s" % manual_scenario_evidence_draft)
	var manual_scenario_record_command := str(
		context.get("manual_scenario_record_command", "")).strip_edges()
	if manual_scenario_record_command != "":
		lines.append("Manual Evidence Command: %s" % manual_scenario_record_command)
	var manual_scenario_issue_record_command := str(
		context.get("manual_scenario_issue_record_command", "")).strip_edges()
	if manual_scenario_issue_record_command != "":
		lines.append("Manual Issue Command: %s" % manual_scenario_issue_record_command)
	var manual_scenario_issue_types := str(
		context.get("manual_scenario_issue_type_suggestions", "")).strip_edges()
	if manual_scenario_issue_types != "":
		lines.append("Manual Issue Types: %s" % manual_scenario_issue_types)
	var manual_scenario_issue_resolve_command := str(
		context.get("manual_scenario_issue_resolve_command", "")).strip_edges()
	if manual_scenario_issue_resolve_command != "":
		lines.append("Manual Resolve Command: %s" % manual_scenario_issue_resolve_command)
	var release_candidate_next := str(context.get("release_candidate_next_action", "")).strip_edges()
	if release_candidate_next != "":
		lines.append("Candidate Next: %s" % release_candidate_next)
	return "%s\n" % "\n".join(lines) if not lines.is_empty() else ""

static func _daily_fingerprint_line(value: Variant) -> String:
	if value is Dictionary:
		var data: Dictionary = value
		var hash_text := str(data.get("hash", "")).strip_edges()
		if hash_text == "":
			return ""
		var parts: Array[String] = ["Hash %s" % hash_text]
		var floor_index := int(data.get("floor_index", 0))
		if floor_index > 0:
			parts.append("Floor %d" % floor_index)
		var room_count := int(data.get("room_count", 0))
		if room_count > 0:
			parts.append("Rooms %d" % room_count)
		var spawn_count := int(data.get("spawn_count", 0))
		if spawn_count > 0:
			parts.append("Spawns %d" % spawn_count)
		var boss_variant := str(data.get("boss_variant", "")).strip_edges()
		if boss_variant != "":
			parts.append("Boss %s" % boss_variant)
		return "Daily Fingerprint: %s" % " | ".join(parts)
	var text := str(value).strip_edges()
	if text == "":
		return ""
	return text if text.begins_with("Daily Fingerprint:") else "Daily Fingerprint: %s" % text

static func _banked_parts(banked: Dictionary) -> String:
	var parts: Array[String] = ["+%dg" % int(banked.get("gold", 0))]
	for key in ["soul_shards", "element_cores", "rune_dust", "blueprints"]:
		var amount := int(banked.get(key, 0))
		if amount <= 0:
			continue
		parts.append("%s +%d" % [CURRENCY_LABELS.get(key, key), amount])
	var challenge_bonus := str(banked.get("challenge_bonus", "")).strip_edges()
	if challenge_bonus != "":
		parts.append("Challenge Bonus %s" % challenge_bonus)
	var endless_depth_bonus := str(banked.get("endless_depth_bonus", "")).strip_edges()
	if endless_depth_bonus != "":
		parts.append("Endless Depth Bonus %s" % endless_depth_bonus)
	var hardcore_clear_bonus := str(banked.get("hardcore_clear_bonus", "")).strip_edges()
	if hardcore_clear_bonus != "":
		parts.append("Hardcore Bonus %s" % hardcore_clear_bonus)
	var elemental_chaos_bonus := str(banked.get("elemental_chaos_bonus", "")).strip_edges()
	if elemental_chaos_bonus != "":
		parts.append("Elemental Chaos Bonus %s" % elemental_chaos_bonus)
	return ", ".join(parts)

static func _meta_shop_hint(meta: Dictionary) -> String:
	var affordable: Array[String] = []
	var upgrades: Dictionary = meta.get("upgrades", {})
	var purchase_hint := MetaProgressionScript.upgrade_purchase_hint(meta)
	for upgrade_id in MetaProgressionScript.all_upgrade_ids():
		var current_level := int(upgrades.get(upgrade_id, 0))
		if current_level >= MetaProgressionScript.upgrade_max_level(upgrade_id):
			continue
		if _can_afford_meta_upgrade(meta, MetaProgressionScript.upgrade_costs(upgrade_id)):
			affordable.append(MetaProgressionScript.upgrade_label(upgrade_id))
	if affordable.is_empty():
		return "Meta Shop: Need more currency for next upgrade\nNext Hub Upgrade: %s" % purchase_hint
	return "Meta Shop: Affordable: %s\nNext Hub Upgrade: %s" % [
		", ".join(affordable.slice(0, 3)),
		purchase_hint,
	]

static func _can_afford_meta_upgrade(meta: Dictionary, costs: Dictionary) -> bool:
	if costs.is_empty():
		return false
	for key in costs.keys():
		if int(meta.get(key, 0)) < int(costs[key]):
			return false
	return true
