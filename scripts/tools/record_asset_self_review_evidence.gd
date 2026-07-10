extends SceneTree

const MetaProgressionScript := preload("res://scripts/progression/meta_progression.gd")
const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

func _init() -> void:
	var review: Dictionary = ReleaseAuditScript.release_asset_self_review()
	if not bool(review.get("passed", false)):
		push_error("Asset self-review failed: %s" % str(review))
		quit(1)
		return
	var data := MetaProgressionScript.record_release_candidate_asset_self_review_result(review)
	var evidence := MetaProgressionScript.release_candidate_evidence(data)
	var stored_review: Dictionary = evidence.get("asset_self_review", {})
	if not bool(stored_review.get("passed", false)):
		push_error("Asset self-review evidence was not recorded")
		quit(1)
		return
	if int(stored_review.get("animation_frame_grid_checked_count", 0)) <= 0 \
			or int(stored_review.get("collision_polygon_checked_count", 0)) <= 0 \
			or int(stored_review.get("object_visual_checked_count", 0)) <= 0:
		push_error("Asset self-review evidence is missing frame/polygon coverage counts")
		quit(1)
		return
	if not Array(evidence.get("manual_scenario_results", [])).is_empty():
		push_error("Asset self-review tool must not create manual_scenario_results")
		quit(1)
		return
	print("Asset self-review evidence recorded: animations %d, polygons %d, objects %d" % [
		int(stored_review.get("animation_frame_grid_checked_count", 0)),
		int(stored_review.get("collision_polygon_checked_count", 0)),
		int(stored_review.get("object_visual_checked_count", 0)),
	])
	quit(0)
