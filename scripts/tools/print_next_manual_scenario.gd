extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var plan: Dictionary = ReleaseAuditScript.release_candidate_manual_recording_plan(
		MetaProgressionScript.load_data())
	var index := int(plan.get("next_missing_manual_index", 0))
	print("NEXT_MANUAL_SCENARIO_INDEX=%d" % index)
	if index > 0:
		print("Next missing manual scenario: %d" % index)
		var status := _next_status(plan, index)
		print("seed=%d | mode=%s | class=%s" % [
			int(status.get("seed", 0)),
			str(status.get("mode", "")),
			str(status.get("class_id", "")),
		])
		print("Goal: %s" % str(status.get("goal", "")))
		print("Manual Notes Required: %s" % ", ".join(Array(
			plan.get("manual_scenario_notes_required_tokens", []))))
		print("Launch Dry Run: %s" % str(status.get("launch_dry_run_command", "")))
		print("Launch: %s" % str(status.get("launch_command", "")))
		print("Record Pass: %s" % str(status.get("command", "")))
		print("Record Issue: %s" % str(status.get("issue_command", "")))
		print("Resolve Issue: %s" % str(status.get("resolve_command", "")))
	else:
		print("No missing manual scenarios")
	quit(0)

func _next_status(plan: Dictionary, index: int) -> Dictionary:
	for raw_status in Array(plan.get("scenario_statuses", [])):
		if raw_status is Dictionary and int(raw_status.get("index", 0)) == index:
			return Dictionary(raw_status)
	return {}
