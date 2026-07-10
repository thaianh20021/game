extends SceneTree

const ReleaseAuditScript := preload("res://scripts/assets/release_audit.gd")

const MANIFESTS := [
	"res://docs/asset_generation/zerie_soldier_idle_manifest.json",
	"res://docs/asset_generation/zerie_soldier_walk_manifest.json",
	"res://docs/asset_generation/zerie_soldier_attack_manifest.json",
	"res://docs/asset_generation/zerie_soldier_hurt_manifest.json",
	"res://docs/asset_generation/zerie_soldier_death_manifest.json",
	"res://docs/asset_generation/zerie_orc_idle_manifest.json",
	"res://docs/asset_generation/zerie_orc_walk_manifest.json",
	"res://docs/asset_generation/zerie_orc_attack_manifest.json",
	"res://docs/asset_generation/zerie_orc_hurt_manifest.json",
	"res://docs/asset_generation/zerie_orc_death_manifest.json",
	"res://docs/asset_generation/zerie_arrow_projectile_manifest.json",
]
const EXPECTED_FRAME_COUNTS := {
	"zerie_soldier_idle": 6,
	"zerie_soldier_walk": 8,
	"zerie_soldier_attack": 6,
	"zerie_soldier_hurt": 4,
	"zerie_soldier_death": 4,
	"zerie_orc_idle": 6,
	"zerie_orc_walk": 8,
	"zerie_orc_attack": 6,
	"zerie_orc_hurt": 4,
	"zerie_orc_death": 4,
	"zerie_arrow_projectile": 1,
}

func _init() -> void:
	var failures: Array[String] = []
	for manifest_path in MANIFESTS:
		var candidate: Dictionary = ReleaseAuditScript.review_manifest_candidate(
			manifest_path, "user_local_assets")
		if str(candidate.get("release_decision", "")) != "public_ok":
			failures.append("%s should be public_ok: %s" % [
				manifest_path, candidate.get("issues", [])])
		if not bool(candidate.get("release_self_review_ok", false)):
			failures.append("%s should pass local asset self-review: %s" % [
				manifest_path, candidate.get("release_self_review_blockers", [])])
		if not bool(candidate.get("manifest_report_ready", false)):
			failures.append("%s should pass image-backed manifest review: %s" % [
				manifest_path, candidate.get("manifest_issues", [])])
		var frame_contract: Dictionary = candidate.get("frame_contract", {})
		if int(frame_contract.get("image_grid_cell_count", 0)) != int(
				frame_contract.get("grid_cell_count", -1)):
			failures.append("%s should have matching declared/image frame grid" % manifest_path)
		if Array(frame_contract.get("frame_nontransparent_px", [])).is_empty():
			failures.append("%s should expose non-empty frame occupancy review" % manifest_path)
	for sprite_name in EXPECTED_FRAME_COUNTS.keys():
		_check_sprite_db_runtime_candidate(
			str(sprite_name), int(EXPECTED_FRAME_COUNTS[sprite_name]), failures)
	if failures.is_empty():
		print("Local asset manifest smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_sprite_db_runtime_candidate(
		sprite_name: String,
		expected_frame_count: int,
		failures: Array[String],
) -> void:
	if not SpriteDB.has_sprite(sprite_name):
		failures.append("SpriteDB should expose local manifest sprite %s" % sprite_name)
	var frames := SpriteDB.frames(sprite_name)
	if frames.size() != expected_frame_count:
		failures.append("%s should expose %d reviewed local animation frames" % [
			sprite_name, expected_frame_count])
	if SpriteDB.texture(sprite_name) == null:
		failures.append("%s should expose a first-frame texture for single-sprite callers" % sprite_name)
	var report := SpriteDB.animation_report(sprite_name)
	if str(report.get("source", "")) != "user_local_assets":
		failures.append("%s should report user_local_assets source" % sprite_name)
	if str(report.get("source_path", "")) == "":
		failures.append("%s should expose local source_path" % sprite_name)
	var release := SpriteDB.release_report([sprite_name])
	var entry: Dictionary = Dictionary(release.get("sprites", {})).get(sprite_name, {})
	if str(entry.get("release_decision", "")) != "public_ok":
		failures.append("%s local release report should be public_ok: %s" % [
			sprite_name, entry.get("issues", [])])
	if not bool(entry.get("public_ready", false)):
		failures.append("%s local release report should be public_ready" % sprite_name)
