extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var before := MetaProgressionScript.release_candidate_evidence(
		MetaProgressionScript.load_data())
	var manual_count_before := Array(before.get("manual_scenario_results", [])).size()
	var rehearsal: Dictionary = ReleaseAuditScript.release_candidate_rehearsal_results()
	if not bool(rehearsal.get("passed", false)) \
			or bool(rehearsal.get("manual_playtest_replacement", true)):
		push_error("Headless rehearsal failed or tried to replace manual playtest: %s" % str(rehearsal))
		quit(1)
		return
	var data := MetaProgressionScript.record_release_candidate_headless_rehearsal_result(
		rehearsal)
	var evidence := MetaProgressionScript.release_candidate_evidence(data)
	var stored_rehearsal: Dictionary = evidence.get("headless_scenario_rehearsal", {})
	if not bool(stored_rehearsal.get("passed", false)) \
			or bool(stored_rehearsal.get("manual_playtest_replacement", true)):
		push_error("Headless rehearsal evidence was not recorded")
		quit(1)
		return
	if Array(evidence.get("manual_scenario_results", [])).size() != manual_count_before:
		push_error("Headless rehearsal tool must not create manual_scenario_results")
		quit(1)
		return
	print("Headless rehearsal evidence recorded: %d/%d scenarios" % [
		int(stored_rehearsal.get("completed_count", 0)),
		int(stored_rehearsal.get("required_count", 0)),
	])
	quit(0)
