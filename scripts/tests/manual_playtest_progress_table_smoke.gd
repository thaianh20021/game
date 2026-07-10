extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"
const STATUS_TOOL_PATH := "res://scripts/tools/release_candidate_status.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_progress_table(failures)
	if failures.is_empty():
		print("Manual playtest progress table smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_progress_table(failures: Array[String]) -> void:
	var release_audit = load(RELEASE_AUDIT_PATH)
	var plan: Dictionary = release_audit.call("release_candidate_manual_recording_plan")
	var rows: Array = plan.get("progress_rows", [])
	if rows.size() != 6:
		failures.append("manual recording plan should expose six compact progress rows")
	else:
		var first: Dictionary = rows[0]
		if int(first.get("index", 0)) != 1 \
				or str(first.get("status", "")) != "missing" \
				or int(first.get("seed", 0)) != 420101 \
				or str(first.get("mode", "")) != "normal" \
				or str(first.get("class_id", "")) != "blade_warden":
			failures.append("first progress row should preserve scenario status/seed/mode/class")
		if str(first.get("next_step", "")) != "launch":
			failures.append("missing progress row should guide the next step to launch")
	var table := str(plan.get("progress_table_text", ""))
	for token in [
			"Manual Progress",
			"# | Status | Seed | Mode | Class | Next",
			"1 | missing | 420101 | normal | blade_warden | launch",
			"6 | missing | 420106 | balance_lab | gunner | launch",
	]:
		if not table.contains(token):
			failures.append("manual progress table missing token: %s" % token)
	if not ResourceLoader.exists(STATUS_TOOL_PATH):
		failures.append("release candidate status tool should exist")
	else:
		var status_source := FileAccess.get_file_as_string(STATUS_TOOL_PATH)
		if not status_source.contains("progress_table_text"):
			failures.append("release candidate status should print compact manual progress")
