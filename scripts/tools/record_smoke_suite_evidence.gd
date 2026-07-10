extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")

func _init() -> void:
	var count := _smoke_count_arg()
	if count < 70:
		push_error("Full smoke suite count is too low: %d" % count)
		quit(1)
		return
	var data := MetaProgressionScript.record_release_candidate_smoke_suite_result({
		"passed": true,
		"count": count,
	})
	var evidence := MetaProgressionScript.release_candidate_evidence(data)
	var smoke: Dictionary = evidence.get("full_smoke_suite", {})
	if int(smoke.get("count", 0)) != count:
		push_error("Smoke suite evidence was not recorded")
		quit(1)
		return
	if not Array(evidence.get("manual_scenario_results", [])).is_empty():
		push_error("Smoke suite tool must not create manual_scenario_results")
		quit(1)
		return
	print("Full smoke suite evidence recorded: %d" % count)
	quit(0)

func _smoke_count_arg() -> int:
	for arg in OS.get_cmdline_user_args():
		var text := str(arg).strip_edges()
		if text.begins_with("--count="):
			return maxi(int(text.trim_prefix("--count=")), 0)
	return 0
