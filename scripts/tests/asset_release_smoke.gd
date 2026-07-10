extends SceneTree

const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")
const ASSET_SOURCE_REGISTRY_PATH := "res://scripts/assets/asset_source_registry.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_asset_source_registry(failures)
	var sprite_db := SpriteDB.new()
	if not sprite_db.has_method("release_report"):
		failures.append("SpriteDB should expose release_report for pre-release animation checks")
	else:
		_check_release_ready_report(sprite_db, failures)
		_check_release_missing_report(sprite_db, failures)
	var audio_db := AudioCueDBScript.new()
	if not audio_db.has_method("release_report"):
		failures.append("AudioCueDB should expose release_report for pre-release audio checks")
	else:
		_check_audio_release_report(audio_db, failures)
		_check_audio_missing_report(audio_db, failures)
	var combat_fx := CombatFxScript.new()
	if not combat_fx.has_method("release_report"):
		failures.append("CombatFx should expose release_report for procedural VFX release checks")
	else:
		_check_combat_fx_release_report(combat_fx, failures)

	if failures.is_empty():
		print("Asset release smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_asset_source_registry(failures: Array[String]) -> void:
	if not ResourceLoader.exists(ASSET_SOURCE_REGISTRY_PATH):
		failures.append("AssetSourceRegistry should exist for asset/license/release policy checks")
		return
	var registry = load(ASSET_SOURCE_REGISTRY_PATH)
	for method_name in ["policy_for", "public_release_gate", "source_exists"]:
		if not registry.has_method(method_name):
			failures.append("AssetSourceRegistry should expose %s" % method_name)
			return

	var atlas: Dictionary = registry.call("policy_for", "0x72_dungeontileset_ii", "sprite")
	if str(atlas.get("license", "")) != "0x72 DungeonTilesetII":
		failures.append("0x72 policy should expose the licensed tileset source")
	if str(atlas.get("release_decision", "")) != "public_ok":
		failures.append("0x72 policy should be public_ok")
	if bool(atlas.get("needs_replacement_before_public", true)):
		failures.append("0x72 policy should not require replacement before public release")
	if not bool(atlas.get("usable_runtime_asset", false)):
		failures.append("0x72 policy should be usable as runtime art")

	var generated: Dictionary = registry.call("policy_for", "internal_generated_placeholder", "sprite")
	if str(generated.get("release_decision", "")) != "internal_only":
		failures.append("generated placeholder policy should be internal_only")
	if str(generated.get("replacement_policy", "")) != "replace_before_public":
		failures.append("generated placeholder policy should require replacement before public release")
	if not bool(generated.get("generated_placeholder", false)):
		failures.append("generated placeholder policy should tag generated_placeholder")

	var procedural: Dictionary = registry.call("policy_for", "procedural_godot_shapes", "vfx")
	if str(procedural.get("license", "")) != "project_owned_procedural":
		failures.append("procedural VFX policy should be project owned")
	if str(procedural.get("release_decision", "")) != "public_ok":
		failures.append("procedural VFX policy should be public_ok")
	if str(procedural.get("reference_policy", "")) != "fanmade_reference_only_no_copy":
		failures.append("procedural VFX policy should retain fanmade reference-only rule")
	var unreviewed_procedural_collision: Dictionary = registry.call(
		"policy_for", "procedural_godot_shapes", "collision")
	if str(unreviewed_procedural_collision.get("release_decision", "")) != "blocked":
		failures.append("procedural collision policy should block until polygon review passes")
	if not Array(unreviewed_procedural_collision.get("issues", [])).has("collision_polygon_not_reviewed"):
		failures.append("procedural collision policy should explain missing polygon review")
	var reviewed_procedural_collision: Dictionary = registry.call(
		"policy_for", "procedural_godot_shapes", "collision", [], {
			"shape_ok": true,
			"polygon_ok": true,
			"polygon_points": 4,
			"polygon_area_px": 32.0,
		})
	if str(reviewed_procedural_collision.get("release_decision", "")) != "public_ok":
		failures.append("reviewed procedural collision policy should be public_ok")
	var unreviewed_atlas_collision: Dictionary = registry.call(
		"policy_for", "0x72_dungeontileset_ii", "collision")
	if str(unreviewed_atlas_collision.get("release_decision", "")) != "blocked":
		failures.append("0x72 collision policy should still require polygon review")

	var procedural_audio: Dictionary = registry.call(
		"policy_for", "project_owned_procedural_audio", "audio")
	if str(procedural_audio.get("license", "")) != "project_owned_procedural_audio":
		failures.append("procedural audio policy should expose project-owned audio license")
	if str(procedural_audio.get("release_decision", "")) != "public_ok":
		failures.append("procedural audio policy should be public_ok")
	if bool(procedural_audio.get("needs_replacement_before_public", true)):
		failures.append("procedural audio policy should not require replacement")
	if str(procedural_audio.get("reference_policy", "")) != "fanmade_reference_only_no_copy":
		failures.append("procedural audio policy should retain fanmade reference-only rule")

	var pixel_art: Dictionary = registry.call("policy_for", "project_owned_pixel_art", "sprite")
	if str(pixel_art.get("license", "")) != "project_owned_pixel_art":
		failures.append("project-owned pixel art policy should expose owned sprite license")
	if str(pixel_art.get("release_decision", "")) != "public_ok":
		failures.append("project-owned pixel art should be public_ok")
	if bool(pixel_art.get("needs_replacement_before_public", true)):
		failures.append("project-owned pixel art should not require replacement before public release")
	if str(pixel_art.get("reference_policy", "")) != "fanmade_reference_only_no_copy":
		failures.append("project-owned pixel art should retain fanmade reference-only rule")

	if not bool(registry.call("source_exists", "project_owned_collision_polygon")):
		failures.append("project-owned collision polygon source should be registered")
	var unreviewed_polygon: Dictionary = registry.call(
		"policy_for", "project_owned_collision_polygon", "collision")
	if str(unreviewed_polygon.get("release_decision", "")) != "blocked":
		failures.append("project-owned polygon policy should block until collision review passes")
	if not Array(unreviewed_polygon.get("issues", [])).has("collision_polygon_not_reviewed"):
		failures.append("project-owned polygon policy should explain missing polygon review")
	var reviewed_polygon: Dictionary = registry.call(
		"policy_for", "project_owned_collision_polygon", "collision", [], {
			"shape_ok": true,
			"polygon_ok": true,
			"polygon_points": 4,
			"polygon_area_px": 32.0,
		})
	if str(reviewed_polygon.get("release_decision", "")) != "public_ok":
		failures.append("reviewed project-owned polygon policy should be public_ok")
	if bool(reviewed_polygon.get("needs_replacement_before_public", true)):
		failures.append("reviewed project-owned polygon should not require replacement")
	if str(reviewed_polygon.get("source_kind", "")) != "project_owned":
		failures.append("reviewed project-owned polygon should keep owned source metadata")

	var fan_reference: Dictionary = registry.call("policy_for", "fanmade_reference_only", "reference")
	if bool(fan_reference.get("usable_runtime_asset", true)):
		failures.append("fanmade reference policy should not be a runtime asset source")
	if str(fan_reference.get("release_decision", "")) != "reference_only":
		failures.append("fanmade reference policy should stay reference_only")
	if str(fan_reference.get("replacement_policy", "")) != "do_not_copy_assets_or_code":
		failures.append("fanmade reference policy should forbid copied assets/code")

	var fan_copy: Dictionary = registry.call("policy_for", "fanmade_direct_copy", "sprite")
	if str(fan_copy.get("release_decision", "")) != "blocked":
		failures.append("direct fanmade copy policy should be blocked")
	if not Array(fan_copy.get("issues", [])).has("direct_copy_not_allowed"):
		failures.append("direct fanmade copy policy should explain copy blocker")
	if not bool(fan_copy.get("needs_replacement_before_public", false)):
		failures.append("direct fanmade copy policy should require replacement before public release")
	var disguised_fanmade_itch: Dictionary = registry.call("policy_for", "free_itchio", "sprite", [], {
		"license": "MIT",
		"source_url": "https://github.com/CalvinWan0101/soul-knight",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"sheet_size": Vector2(64, 16),
		"columns": 4,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
	})
	if str(disguised_fanmade_itch.get("release_decision", "")) != "blocked":
		failures.append("free itch.io policy should block fanmade repo URLs disguised as licensed runtime assets")
	if not Array(disguised_fanmade_itch.get("issues", [])).has("fanmade_runtime_source_forbidden"):
		failures.append("free itch.io policy should explain fanmade repo URLs are reference-only")
	var disguised_fanmade_ai: Dictionary = registry.call("policy_for", "ai_generated", "sprite", [], {
		"license": "project_owned_ai_generated",
		"source_url": "https://github.com/leoyin1127/Soul-knights",
		"generation_tool": "gpt-image",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"sheet_size": Vector2(64, 16),
		"columns": 4,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": Vector2(8, 8),
	})
	if str(disguised_fanmade_ai.get("release_decision", "")) != "blocked":
		failures.append("AI-generated policy should block fanmade repo URLs disguised as generated runtime assets")
	if not Array(disguised_fanmade_ai.get("issues", [])).has("fanmade_runtime_source_forbidden"):
		failures.append("AI-generated policy should explain fanmade repo URLs are reference-only")
	var local_fanmade_image: Dictionary = registry.call("policy_for", "ai_generated", "sprite", [], {
		"license": "project_owned_ai_generated",
		"source_url": "local_generation_manifest",
		"generation_tool": "gpt-image",
		"image_path": "C:\\refs\\CalvinWan0101\\soul-knight\\sprites\\hero.png",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"stable_size": true,
	})
	if str(local_fanmade_image.get("release_decision", "")) != "blocked":
		failures.append("AI-generated policy should block local fanmade image paths")
	if not Array(local_fanmade_image.get("issues", [])).has("fanmade_runtime_source_forbidden"):
		failures.append("AI-generated policy should explain local fanmade image paths are reference-only")
	var local_fanmade_manifest: Dictionary = registry.call("policy_for", "ai_generated", "sprite", [], {
		"license": "project_owned_ai_generated",
		"generation_manifest": "C:\\refs\\leoyin1127\\Soul-knights\\copied_sprite.json",
		"generation_tool": "gpt-image",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"stable_size": true,
	})
	if not Array(local_fanmade_manifest.get("issues", [])).has("fanmade_runtime_source_forbidden"):
		failures.append("AI-generated policy should block local fanmade generation manifest paths")

	if not bool(registry.call("source_exists", "user_local_assets")):
		failures.append("user local asset source should be registered")
	var unreviewed_local_asset: Dictionary = registry.call("policy_for", "user_local_assets", "sprite", [], {
		"source_path": "E:/AI/asset/Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc/Characters(100x100 split)/Soldier/Soldier/Soldier_Idle.png",
	})
	if str(unreviewed_local_asset.get("release_decision", "")) != "blocked":
		failures.append("user local assets should block until license/provenance metadata is reviewed")
	if not Array(unreviewed_local_asset.get("issues", [])).has("license_missing"):
		failures.append("user local assets should explain missing license metadata")
	if not Array(unreviewed_local_asset.get("issues", [])).has("local_asset_provenance_not_reviewed"):
		failures.append("user local assets should require local provenance review")
	var local_fanmade_named_asset: Dictionary = registry.call(
		"policy_for", "user_local_assets", "sprite", [], {
			"license": "user_owned_local_asset",
			"source_path": "E:/AI/gameasset/main/Resources/boss/zulan_the_colossus/idle.png",
			"provenance_reviewed": true,
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(100, 100),
			"expected_frame_size": Vector2(100, 100),
			"sheet_size": Vector2(400, 100),
			"columns": 4,
			"rows": 1,
			"stable_size": true,
			"fps": 8.0,
			"animation_stability_reviewed": true,
			"motion_reviewed": true,
			"origin_alignment_reviewed": true,
			"origin_px": Vector2(50, 72),
		})
	if str(local_fanmade_named_asset.get("release_decision", "")) != "blocked":
		failures.append("user local assets should block suspicious fanmade/rip-named local paths")
	if not Array(local_fanmade_named_asset.get("issues", [])).has("fanmade_runtime_source_forbidden"):
		failures.append("user local assets should explain suspicious fanmade/rip local paths")
	var local_reference_clone_asset: Dictionary = registry.call(
		"policy_for", "user_local_assets", "sprite", [], {
			"license": "MIT",
			"source_url": "https://example.com/elemental-dungeons-replication",
			"source_path": "E:/AI/asset/src/Resources/ember/floor_1/goblin_guard/idle/1.bmp",
			"provenance_reviewed": true,
			"frame_grid_ok": true,
			"frame_count": 1,
			"frame_size": Vector2(24, 24),
			"expected_frame_size": Vector2(24, 24),
			"sheet_size": Vector2(24, 24),
			"columns": 1,
			"rows": 1,
			"stable_size": true,
			"fps": 8.0,
			"animation_stability_reviewed": true,
			"motion_reviewed": true,
			"origin_alignment_reviewed": true,
			"origin_px": Vector2(12, 18),
		})
	if str(local_reference_clone_asset.get("release_decision", "")) != "blocked":
		failures.append("user local assets should block reference-only replication source folders")
	if not Array(local_reference_clone_asset.get("issues", [])).has("fanmade_runtime_source_forbidden"):
		failures.append("reference-only replication source folders should explain runtime copy ban")
	var local_reference_identity_asset: Dictionary = registry.call(
		"policy_for", "user_local_assets", "sprite", [], {
			"license": "MIT",
			"source_url": "https://example.com/elemental-dungeons-replication",
			"source_path": "E:/AI/asset/Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc/Characters(100x100 split)/Soldier/Soldier/Soldier_Idle.png",
			"provenance_reviewed": true,
			"frame_grid_ok": true,
			"frame_count": 6,
			"frame_size": Vector2(100, 100),
			"expected_frame_size": Vector2(100, 100),
			"sheet_size": Vector2(600, 100),
			"columns": 6,
			"rows": 1,
			"stable_size": true,
			"fps": 8.0,
			"animation_stability_reviewed": true,
			"motion_reviewed": true,
			"origin_alignment_reviewed": true,
			"origin_px": Vector2(50, 72),
		})
	if str(local_reference_identity_asset.get("release_decision", "")) != "blocked":
		failures.append("user local assets should block replication source identity even outside src folders")
	if not Array(local_reference_identity_asset.get("issues", [])).has("fanmade_runtime_source_forbidden"):
		failures.append("replication source identity should explain runtime copy ban")
	var reviewed_local_asset: Dictionary = registry.call("policy_for", "user_local_assets", "sprite", [], {
		"license": "Zerie Tiny RPG Character Asset Pack free license",
		"source_url": "https://zerie.itch.io/tiny-rpg-character-asset-pack",
		"source_path": "E:/AI/asset/Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc/Characters(100x100 split)/Soldier/Soldier/Soldier_Idle.png",
		"provenance_reviewed": true,
		"frame_grid_ok": true,
		"frame_count": 6,
		"frame_size": Vector2(100, 100),
		"expected_frame_size": Vector2(100, 100),
		"sheet_size": Vector2(600, 100),
		"columns": 6,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": Vector2(50, 72),
	})
	if str(reviewed_local_asset.get("release_decision", "")) != "public_ok":
		failures.append("reviewed user local asset policy should be public_ok")
	if bool(reviewed_local_asset.get("needs_replacement_before_public", true)):
		failures.append("reviewed user local asset should not require replacement")
	if str(reviewed_local_asset.get("source_path", "")) == "":
		failures.append("reviewed user local asset should expose source_path metadata")

	var unlicensed_itch: Dictionary = registry.call("policy_for", "free_itchio", "sprite")
	if str(unlicensed_itch.get("release_decision", "")) != "blocked":
		failures.append("free itch.io policy should block until license metadata is present")
	if str(unlicensed_itch.get("replacement_policy", "")) != "add_license_before_public":
		failures.append("free itch.io policy should require license proof before public release")
	var licensed_itch: Dictionary = registry.call("policy_for", "free_itchio", "sprite", [], {
		"license": "CC0",
		"source_url": "https://example.itch.io/free-pack",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"sheet_size": Vector2(64, 16),
		"columns": 4,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": Vector2(8, 8),
	})
	if str(licensed_itch.get("release_decision", "")) != "public_ok":
		failures.append("licensed free itch.io policy should be public_ok")
	if bool(licensed_itch.get("needs_replacement_before_public", true)):
		failures.append("licensed free itch.io policy should not require replacement")
	if not bool(registry.call("source_exists", "godot_asset_library")):
		failures.append("Godot Asset Library source should be registered")
	var unlicensed_godot_asset: Dictionary = registry.call("policy_for",
		"godot_asset_library", "sprite")
	if str(unlicensed_godot_asset.get("release_decision", "")) != "blocked":
		failures.append("Godot Asset Library policy should block until license metadata is present")
	var licensed_godot_asset: Dictionary = registry.call("policy_for",
		"godot_asset_library", "sprite", [], {
			"license": "MIT",
			"source_url": "https://godotengine.org/asset-library/asset/1234",
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(16, 16),
			"expected_frame_size": Vector2(16, 16),
			"sheet_size": Vector2(64, 16),
			"columns": 4,
			"rows": 1,
			"stable_size": true,
			"fps": 8.0,
			"animation_stability_reviewed": true,
			"motion_reviewed": true,
			"origin_alignment_reviewed": true,
			"origin_px": Vector2(8, 8),
		})
	if str(licensed_godot_asset.get("release_decision", "")) != "public_ok":
		failures.append("licensed Godot Asset Library policy should be public_ok")
	if str(licensed_godot_asset.get("source_kind", "")) != "third_party_free":
		failures.append("Godot Asset Library policy should keep third-party free metadata")
	var non_godot_asset_source: Dictionary = registry.call("policy_for",
		"godot_asset_library", "sprite", [], {
			"license": "MIT",
			"source_url": "https://example.com/free-godot-pack",
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(16, 16),
			"expected_frame_size": Vector2(16, 16),
			"stable_size": true,
			"fps": 8.0,
			"animation_stability_reviewed": true,
			"motion_reviewed": true,
			"origin_alignment_reviewed": true,
			"origin_px": Vector2(8, 8),
		})
	if str(non_godot_asset_source.get("release_decision", "")) != "blocked":
		failures.append("Godot Asset Library policy should block non-Godot asset URLs")
	if not Array(non_godot_asset_source.get("issues", [])).has(
			"godot_asset_library_source_url_required"):
		failures.append("Godot Asset Library policy should explain missing official source URL")
	var non_itch_free_source: Dictionary = registry.call("policy_for", "free_itchio", "sprite", [], {
		"license": "CC0",
		"source_url": "https://example.com/free-pack",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
	})
	if str(non_itch_free_source.get("release_decision", "")) != "blocked":
		failures.append("free itch.io policy should block non-itch.io source URLs")
	if not Array(non_itch_free_source.get("issues", [])).has("itchio_source_url_required"):
		failures.append("free itch.io policy should explain missing itch.io source URL")
	var size_missing_itch: Dictionary = registry.call("policy_for", "free_itchio", "sprite", [], {
		"license": "CC0",
		"source_url": "https://example.itch.io/free-pack",
		"frame_grid_ok": true,
	})
	if str(size_missing_itch.get("release_decision", "")) != "blocked":
		failures.append("free itch.io sprite policy should block without frame size/count contract")
	if not Array(size_missing_itch.get("issues", [])).has("frame_size_missing") \
			or not Array(size_missing_itch.get("issues", [])).has("frame_count_missing"):
		failures.append("free itch.io sprite policy should explain missing frame contract")
	var expected_size_missing_itch: Dictionary = registry.call(
		"policy_for", "free_itchio", "sprite", [], {
			"license": "CC0",
			"source_url": "https://example.itch.io/free-pack",
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(16, 16),
			"sheet_size": Vector2(64, 16),
			"columns": 4,
			"rows": 1,
			"stable_size": true,
			"fps": 8.0,
			"animation_stability_reviewed": true,
			"motion_reviewed": true,
			"origin_alignment_reviewed": true,
		})
	if str(expected_size_missing_itch.get("release_decision", "")) != "blocked":
		failures.append("free itch.io sprite policy should block without expected frame size contract")
	if not Array(expected_size_missing_itch.get("issues", [])).has("expected_frame_size_missing"):
		failures.append("free itch.io sprite policy should explain missing expected frame size")
	var mismatched_itch: Dictionary = registry.call("policy_for", "free_itchio", "sprite", [], {
		"license": "CC0",
		"source_url": "https://example.itch.io/free-pack",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(32, 16),
		"expected_frame_size": Vector2(16, 16),
		"stable_size": true,
		"fps": 8.0,
	})
	if str(mismatched_itch.get("release_decision", "")) != "blocked":
		failures.append("free itch.io sprite policy should block mismatched frame dimensions")
	if not Array(mismatched_itch.get("issues", [])).has("frame_size_mismatch"):
		failures.append("free itch.io sprite policy should explain frame size mismatch")
	var mismatched_grid_itch: Dictionary = registry.call("policy_for", "free_itchio", "sprite", [], {
		"license": "CC0",
		"source_url": "https://example.itch.io/free-pack",
		"frame_grid_ok": true,
		"frame_count": 5,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"columns": 4,
		"rows": 1,
	})
	if str(mismatched_grid_itch.get("release_decision", "")) != "blocked":
		failures.append("free itch.io sprite policy should block declared grid cell mismatches")
	if not Array(mismatched_grid_itch.get("issues", [])).has("frame_grid_cell_count_mismatch"):
		failures.append("free itch.io sprite policy should explain declared grid cell mismatch")
	var unreviewed_itch: Dictionary = registry.call("policy_for", "free_itchio", "sprite", [], {
		"license": "CC0",
		"source_url": "https://example.itch.io/free-pack",
	})
	if str(unreviewed_itch.get("release_decision", "")) != "blocked":
		failures.append("free itch.io sprite policy should block until frame_grid_ok is reviewed")
	if not Array(unreviewed_itch.get("issues", [])).has("frame_grid_not_reviewed"):
		failures.append("free itch.io sprite policy should explain missing frame-grid review")
	var unstable_size_itch: Dictionary = registry.call("policy_for", "free_itchio", "sprite", [], {
		"license": "CC0",
		"source_url": "https://example.itch.io/free-pack",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"stable_size": false,
		"fps": 8.0,
	})
	if str(unstable_size_itch.get("release_decision", "")) != "blocked":
		failures.append("free itch.io sprite policy should block unstable animation frame sizes")
	if not Array(unstable_size_itch.get("issues", [])).has("animation_size_not_stable"):
		failures.append("free itch.io sprite policy should explain unstable animation frame size")
	var unreviewed_motion_itch: Dictionary = registry.call("policy_for", "free_itchio", "sprite", [], {
		"license": "CC0",
		"source_url": "https://example.itch.io/free-pack",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"stable_size": true,
		"fps": 8.0,
	})
	if str(unreviewed_motion_itch.get("release_decision", "")) != "blocked":
		failures.append("free itch.io sprite policy should block until animation stability is reviewed")
	if not Array(unreviewed_motion_itch.get("issues", [])).has("animation_stability_not_reviewed"):
		failures.append("free itch.io sprite policy should explain missing animation stability review")
	var unreviewed_motion_path_itch: Dictionary = registry.call("policy_for", "free_itchio", "sprite", [], {
		"license": "CC0",
		"source_url": "https://example.itch.io/free-pack",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
	})
	if str(unreviewed_motion_path_itch.get("release_decision", "")) != "blocked":
		failures.append("free itch.io sprite policy should block until animation motion is reviewed")
	if not Array(unreviewed_motion_path_itch.get("issues", [])).has("animation_motion_not_reviewed"):
		failures.append("free itch.io sprite policy should explain missing motion review")
	var unreviewed_origin_itch: Dictionary = registry.call("policy_for", "free_itchio", "sprite", [], {
		"license": "CC0",
		"source_url": "https://example.itch.io/free-pack",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"sheet_size": Vector2(64, 16),
		"columns": 4,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
	})
	if str(unreviewed_origin_itch.get("release_decision", "")) != "blocked":
		failures.append("free itch.io sprite policy should block until origin alignment is reviewed")
	if not Array(unreviewed_origin_itch.get("issues", [])).has("origin_alignment_not_reviewed"):
		failures.append("free itch.io sprite policy should explain missing origin alignment review")

	var ai_unreviewed: Dictionary = registry.call("policy_for", "ai_generated", "sprite")
	if str(ai_unreviewed.get("release_decision", "")) != "blocked":
		failures.append("AI-generated sprite policy should block without provenance and frame review")
	var ai_issues: Array = ai_unreviewed.get("issues", [])
	if not ai_issues.has("generation_tool_missing") or not ai_issues.has("frame_grid_not_reviewed"):
		failures.append("AI-generated sprite policy should list provenance and frame-grid blockers")
	var ai_missing_frame_contract: Dictionary = registry.call("policy_for", "ai_generated", "sprite", [], {
		"license": "project_owned_ai_generated",
		"source_url": "local_generation_manifest",
		"generation_tool": "gpt-image",
		"frame_grid_ok": true,
	})
	if str(ai_missing_frame_contract.get("release_decision", "")) != "blocked":
		failures.append("AI-generated sprite policy should block without frame size/count contract")
	var ai_missing_timing: Dictionary = registry.call("policy_for", "ai_generated", "sprite", [], {
		"license": "project_owned_ai_generated",
		"source_url": "local_generation_manifest",
		"generation_tool": "gpt-image",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"stable_size": true,
	})
	if str(ai_missing_timing.get("release_decision", "")) != "blocked":
		failures.append("AI-generated sprite policy should block reviewed frame grids without fps/timing")
	if not Array(ai_missing_timing.get("issues", [])).has("animation_fps_missing"):
		failures.append("AI-generated sprite policy should explain missing animation fps")
	var ai_manifest_reviewed: Dictionary = registry.call("policy_for", "ai_generated", "sprite", [], {
		"license": "project_owned_ai_generated",
		"generation_manifest": "res://docs/asset_generation/valid_ai_sprite_manifest.json",
		"generation_tool": "gpt-image",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
	})
	if str(ai_manifest_reviewed.get("release_decision", "")) != "public_ok":
		failures.append("AI-generated sprite policy should accept a saved generation_manifest instead of source_url")
	if str(ai_manifest_reviewed.get("generation_manifest", "")) != "res://docs/asset_generation/valid_ai_sprite_manifest.json":
		failures.append("AI-generated sprite policy should preserve generation_manifest metadata")
	if Array(ai_manifest_reviewed.get("issues", [])).has("source_url_missing"):
		failures.append("AI-generated sprite policy should not require source_url when generation_manifest is present")
	if not registry.has_method("generation_manifest_report"):
		failures.append("AssetSourceRegistry should expose generation_manifest_report")
	else:
		var manifest_report: Dictionary = registry.call(
			"generation_manifest_report",
			"res://docs/asset_generation/valid_ai_sprite_manifest.json")
		if not bool(manifest_report.get("ready", false)):
			failures.append("valid AI generation manifest should pass manifest review")
		var manifest_metadata: Dictionary = manifest_report.get("metadata", {})
		if str(manifest_metadata.get("generation_tool", "")) != "gpt-image":
			failures.append("generation manifest should preserve generation tool metadata")
		if manifest_metadata.get("frame_size", Vector2.ZERO) != Vector2(16, 16):
			failures.append("generation manifest should parse frame_size into Vector2")
		if float(manifest_metadata.get("fps", 0.0)) <= 0.0:
			failures.append("generation manifest should preserve reviewed animation fps")
		if not bool(manifest_metadata.get("motion_reviewed", false)):
			failures.append("generation manifest should preserve reviewed animation motion")
		if not bool(manifest_metadata.get("origin_alignment_reviewed", false)):
			failures.append("generation manifest should preserve reviewed origin alignment")
		if manifest_metadata.get("origin_px", Vector2.ZERO) != Vector2(8, 8):
			failures.append("generation manifest should preserve numeric sprite origin_px")
		if str(manifest_metadata.get("review_notes", "")).strip_edges() == "":
			failures.append("generation manifest should preserve self-review notes for release decisions")
		var manifest_policy: Dictionary = registry.call("policy_for", "ai_generated", "sprite", [], {
			"generation_manifest": "res://docs/asset_generation/valid_ai_sprite_manifest.json",
		})
		if str(manifest_policy.get("release_decision", "")) != "public_ok":
			failures.append("AI-generated sprite policy should pass from a complete manifest alone")
		if not bool(manifest_policy.get("manifest_reviewed", false)):
			failures.append("AI-generated sprite policy should mark reviewed manifests")
		var mismatched_manifest_policy: Dictionary = registry.call("policy_for", "ai_generated", "vfx", [], {
			"generation_manifest": "res://docs/asset_generation/valid_ai_sprite_manifest.json",
		})
		if str(mismatched_manifest_policy.get("release_decision", "")) != "blocked":
			failures.append("AI-generated VFX policy should block sprite manifests with mismatched asset_kind")
		if not Array(mismatched_manifest_policy.get("issues", [])).has("manifest_asset_kind_mismatch"):
			failures.append("AI-generated VFX policy should explain manifest asset_kind mismatches")
		var invalid_manifest_report: Dictionary = registry.call(
			"generation_manifest_report",
			"res://docs/asset_generation/invalid_ai_sprite_manifest.json")
		if bool(invalid_manifest_report.get("ready", true)):
			failures.append("invalid AI generation manifest should fail manifest review")
		var invalid_issues: Array = invalid_manifest_report.get("issues", [])
		if not invalid_issues.has("manifest_generation_tool_missing") \
				or not invalid_issues.has("manifest_frame_size_missing") \
				or not invalid_issues.has("manifest_animation_fps_missing") \
				or not invalid_issues.has("manifest_review_notes_missing"):
			failures.append("invalid generation manifest should explain missing required fields")
		var invalid_object_manifest: Dictionary = registry.call(
			"generation_manifest_report",
			"res://docs/asset_generation/invalid_ai_object_visual_manifest.json")
		if bool(invalid_object_manifest.get("ready", true)):
			failures.append("invalid object visual manifest should fail sprite/polygon manifest review")
		var invalid_object_issues: Array = invalid_object_manifest.get("issues", [])
		if not invalid_object_issues.has("manifest_runtime_object_sprite_missing") \
				or not invalid_object_issues.has("manifest_fallback_polygon_missing"):
			failures.append("invalid object visual manifest should explain missing sprite/polygon review")
		var invalid_collision_manifest: Dictionary = registry.call(
			"generation_manifest_report",
			"res://docs/asset_generation/invalid_ai_collision_manifest.json")
		if bool(invalid_collision_manifest.get("ready", true)):
			failures.append("invalid collision manifest should fail polygon manifest review")
		var invalid_collision_issues: Array = invalid_collision_manifest.get("issues", [])
		if not invalid_collision_issues.has("manifest_collision_polygon_missing"):
			failures.append("invalid collision manifest should explain missing polygon review")
		var invalid_kind_manifest: Dictionary = registry.call(
			"generation_manifest_report",
			"res://docs/asset_generation/invalid_ai_unknown_kind_manifest.json")
		if bool(invalid_kind_manifest.get("ready", true)):
			failures.append("unknown asset_kind manifest should fail manifest review")
		var invalid_kind_issues: Array = invalid_kind_manifest.get("issues", [])
		if not invalid_kind_issues.has("manifest_asset_kind_unknown"):
			failures.append("unknown asset_kind manifest should explain unsupported asset_kind")
		_check_generation_manifest_image_contract(registry, failures)
	var ai_reviewed: Dictionary = registry.call("policy_for", "ai_generated", "sprite", [], {
		"license": "project_owned_ai_generated",
		"source_url": "local_generation_manifest",
		"generation_tool": "gpt-image",
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": Vector2(16, 16),
		"expected_frame_size": Vector2(16, 16),
		"sheet_size": Vector2(64, 16),
		"columns": 4,
		"rows": 1,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": Vector2(8, 8),
	})
	if str(ai_reviewed.get("release_decision", "")) != "public_ok":
		failures.append("reviewed AI-generated sprite policy should be public_ok")
	if str(ai_reviewed.get("source_kind", "")) != "project_owned_generated":
		failures.append("reviewed AI-generated sprite policy should keep generated ownership metadata")
	if bool(ai_reviewed.get("needs_replacement_before_public", true)):
		failures.append("reviewed AI-generated sprite policy should not require replacement")
	var ai_object_unreviewed: Dictionary = registry.call(
		"policy_for", "ai_generated", "object_visual", [], {
			"license": "project_owned_ai_generated",
			"source_url": "local_generation_manifest",
			"generation_tool": "gpt-image",
		})
	if str(ai_object_unreviewed.get("release_decision", "")) != "blocked":
		failures.append("AI-generated object visual policy should block without sprite/frame/polygon review")
	var ai_object_issues: Array = ai_object_unreviewed.get("issues", [])
	if not ai_object_issues.has("runtime_object_sprite_not_reviewed") \
			or not ai_object_issues.has("frame_grid_not_reviewed") \
			or not ai_object_issues.has("fallback_polygon_not_reviewed"):
		failures.append("AI-generated object visual policy should explain missing sprite/frame/polygon review")
	var itch_object_unreviewed: Dictionary = registry.call(
		"policy_for", "free_itchio", "object_visual", [], {
			"license": "CC0",
			"source_url": "https://example.itch.io/free-dungeon-object-pack",
		})
	if str(itch_object_unreviewed.get("release_decision", "")) != "blocked":
		failures.append("free itch.io object visual policy should block without frame/polygon review")
	var reviewed_object_visual: Dictionary = registry.call(
		"policy_for", "ai_generated", "object_visual", [], {
			"license": "project_owned_ai_generated",
			"source_url": "local_generation_manifest",
			"generation_tool": "gpt-image",
			"runtime_object_sprite_ok": true,
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(32, 32),
			"expected_frame_size": Vector2(32, 32),
			"sheet_size": Vector2(64, 64),
			"columns": 2,
			"rows": 2,
			"stable_size": true,
			"fps": 8.0,
			"animation_stability_reviewed": true,
			"motion_reviewed": true,
			"origin_alignment_reviewed": true,
			"origin_px": Vector2(16, 16),
			"polygon_ok": true,
			"fallback_polygon_points": 5,
			"fallback_polygon_area_px": 128.0,
		})
	if str(reviewed_object_visual.get("release_decision", "")) != "public_ok":
		failures.append("reviewed object visual policy should pass after sprite/frame/polygon review")

	var gate: Dictionary = registry.call("public_release_gate", [atlas, generated, fan_copy])
	if bool(gate.get("public_ready", true)):
		failures.append("public release gate should block generated/fanmade copied assets")
	var blockers: Array = gate.get("public_release_blockers", [])
	if blockers.is_empty() or not str(blockers).contains("generated_placeholder") \
			or not str(blockers).contains("direct_copy_not_allowed"):
		failures.append("public release gate should list generated and copy blockers")

func _check_generation_manifest_image_contract(registry: Variant, failures: Array[String]) -> void:
	var image_path := "user://asset_manifest_sheet_ok.png"
	var image := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for frame_index in 4:
		for x in range(2, 14):
			for y in range(3, 13):
				image.set_pixel(frame_index * 16 + x, y, Color(0.1, 0.2, 0.3, 1.0))
	if image.save_png(image_path) != OK:
		failures.append("test fixture should save manifest image")
		return
	var valid_manifest_path := "user://asset_manifest_sheet_ok.json"
	_write_manifest(valid_manifest_path, {
		"asset_id": "temp_sheet_ok",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": [16, 16],
		"expected_frame_size": [16, 16],
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": [8, 8],
		"review_notes": "Frame grid, fps, motion, and origin reviewed against 16x16 cells.",
		"sheet_size": [64, 16],
		"columns": 4,
		"rows": 1,
	})
	var valid_report: Dictionary = registry.call("generation_manifest_report", valid_manifest_path)
	if not bool(valid_report.get("ready", false)):
		failures.append("manifest image contract should pass when PNG size matches sheet grid")
	var valid_metadata: Dictionary = valid_report.get("metadata", {})
	if valid_metadata.get("image_size", Vector2.ZERO) != Vector2(64, 16):
		failures.append("manifest image contract should expose actual PNG image_size")

	var bad_manifest_path := "user://asset_manifest_sheet_bad.json"
	_write_manifest(bad_manifest_path, {
		"asset_id": "temp_sheet_bad",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": 4,
		"frame_size": [16, 16],
		"expected_frame_size": [16, 16],
		"stable_size": true,
		"fps": 8.0,
		"sheet_size": [32, 16],
		"columns": 2,
		"rows": 1,
	})
	var bad_report: Dictionary = registry.call("generation_manifest_report", bad_manifest_path)
	if bool(bad_report.get("ready", true)):
		failures.append("manifest image contract should fail when PNG size disagrees with sheet_size")
	if not Array(bad_report.get("issues", [])).has("manifest_image_size_mismatch"):
		failures.append("manifest image contract should explain PNG/sheet_size mismatch")

	var bad_grid_manifest_path := "user://asset_manifest_grid_bad.json"
	_write_manifest(bad_grid_manifest_path, {
		"asset_id": "temp_grid_bad",
		"asset_kind": "sprite",
		"license": "project_owned_ai_generated",
		"generation_tool": "gpt-image",
		"image_path": image_path,
		"frame_grid_ok": true,
		"frame_count": 3,
		"frame_size": [16, 16],
		"expected_frame_size": [16, 16],
		"stable_size": true,
		"fps": 8.0,
		"sheet_size": [64, 16],
		"columns": 4,
		"rows": 1,
	})
	var bad_grid_report: Dictionary = registry.call(
		"generation_manifest_report", bad_grid_manifest_path)
	if bool(bad_grid_report.get("ready", true)):
		failures.append("manifest image contract should fail when frame_count disagrees with grid cells")
	if not Array(bad_grid_report.get("issues", [])).has("manifest_frame_grid_cell_count_mismatch"):
		failures.append("manifest image contract should explain frame_count/grid cell mismatch")

func _write_manifest(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _check_release_ready_report(sprite_db: SpriteDB, failures: Array[String]) -> void:
	var critical_sprites := [
		"knight_m_idle_anim",
		"knight_m_run_anim",
		"imp_idle_anim",
		"floor_spikes_anim",
		"chest_full_open_anim",
		"chest_empty_open_anim",
		"coin_anim",
		"bomb",
		"weapon_pistol_generated",
		"pickup_silver_key_generated",
		"pickup_blueprint_generated",
		"fire_patch_generated",
		"pickup_unknown_generated",
	]
	var report: Dictionary = sprite_db.call("release_report", critical_sprites)
	if not bool(report.get("ready", false)):
		failures.append("release report should pass for critical sprite set: %s" % report.get("failures", []))
	if not bool(report.get("public_ready", false)):
		failures.append("release report should mark critical sprite set public-ready after project-owned art review")
	if int(report.get("checked_count", 0)) != critical_sprites.size():
		failures.append("release report should count checked sprites")
	var generated_placeholders: Array = report.get("generated_placeholders", [])
	if not generated_placeholders.is_empty():
		failures.append("critical sprite report should not list project-owned sprites as generated placeholders")
	var public_blockers: Array = report.get("public_release_blockers", [])
	if not public_blockers.is_empty():
		failures.append("critical sprite report should not keep public release blockers after sprite review")
	var sprites: Dictionary = report.get("sprites", {})
	for sprite_name in critical_sprites:
		var sprite_report: Dictionary = sprites.get(sprite_name, {})
		if sprite_report.is_empty():
			failures.append("%s should have release report metadata" % sprite_name)
			continue
		var source := str(sprite_report.get("source", ""))
		if source == "":
			failures.append("%s release report should expose source" % sprite_name)
		_assert_source_policy_fields(sprite_report, sprite_name, failures)
		var license := str(sprite_report.get("license", ""))
		if license == "":
			failures.append("%s release report should expose license/replacement policy" % sprite_name)
		var decision := str(sprite_report.get("release_decision", ""))
		if not ["public_ok", "internal_only", "blocked"].has(decision):
			failures.append("%s release report should expose release_decision" % sprite_name)
		var expected_source := "atlas"
		if ["weapon_pistol_generated", "pickup_silver_key_generated",
				"pickup_blueprint_generated", "pickup_unknown_generated",
				"fire_patch_generated"].has(sprite_name):
			expected_source = "project_owned_pixel_art"
		elif sprite_name.ends_with("_generated"):
			expected_source = "generated"
		if source != expected_source:
			failures.append("%s should be marked as %s source" % [sprite_name, expected_source])
		if source == "generated":
			if license != "internal_generated_placeholder":
				failures.append("%s generated placeholder should mark internal-only license policy" % sprite_name)
			if decision != "internal_only":
				failures.append("%s generated placeholder should be internal-only before public release" % sprite_name)
			if not bool(sprite_report.get("needs_replacement_before_public", false)):
				failures.append("%s generated placeholder should require replacement before public release" % sprite_name)
		elif source == "atlas":
			if license != "0x72 DungeonTilesetII":
				failures.append("%s atlas sprite should mark 0x72 license source" % sprite_name)
			if decision != "public_ok":
				failures.append("%s atlas sprite should be public_ok" % sprite_name)
			if bool(sprite_report.get("needs_replacement_before_public", true)):
				failures.append("%s atlas sprite should not require replacement before public release" % sprite_name)
		if int(sprite_report.get("frame_count", 0)) <= 0:
			failures.append("%s release report should expose frame_count" % sprite_name)
		if sprite_report.get("frame_size", Vector2.ZERO) == Vector2.ZERO:
			failures.append("%s release report should expose frame_size" % sprite_name)
		if not bool(sprite_report.get("stable_size", false)):
			failures.append("%s release report should require stable frame size" % sprite_name)
		if float(sprite_report.get("fps", 0.0)) <= 0.0:
			failures.append("%s release report should expose fps" % sprite_name)
		if not bool(sprite_report.get("frame_grid_ok", false)):
			failures.append("%s release report should mark stable frame grid as reviewed" % sprite_name)
		if not bool(sprite_report.get("animation_stability_reviewed", false)):
			failures.append("%s release report should mark animation stability as reviewed" % sprite_name)
		if not bool(sprite_report.get("origin_alignment_reviewed", false)):
			failures.append("%s release report should mark origin alignment as reviewed" % sprite_name)
		var review_status := str(sprite_report.get("review_status", ""))
		var replacement_policy := str(sprite_report.get("replacement_policy", ""))
		if not bool(sprite_report.get("ready", false)):
			failures.append("%s should be marked release-ready" % sprite_name)
		if source == "generated":
			if review_status != "stable_internal_only":
				failures.append("%s generated placeholder should pass stability review as internal-only" % sprite_name)
			if replacement_policy != "replace_before_public":
				failures.append("%s generated placeholder should require replacement policy before public release" % sprite_name)
		elif source == "atlas":
			if review_status != "stable_public_ok":
				failures.append("%s atlas sprite should pass stability review as public-ready" % sprite_name)
			if replacement_policy != "licensed_ok":
				failures.append("%s atlas sprite should expose licensed_ok replacement policy" % sprite_name)
		elif source == "project_owned_pixel_art":
			if license != "project_owned_pixel_art":
				failures.append("%s project-owned pixel art should expose owned license" % sprite_name)
			if decision != "public_ok":
				failures.append("%s project-owned pixel art should be public_ok" % sprite_name)
			if review_status != "stable_project_owned_ok":
				failures.append("%s project-owned pixel art should pass stability review" % sprite_name)
			if replacement_policy != "owned_ok":
				failures.append("%s project-owned pixel art should not need replacement policy" % sprite_name)
			if bool(sprite_report.get("needs_replacement_before_public", true)):
				failures.append("%s project-owned pixel art should not require public replacement" % sprite_name)

func _check_release_missing_report(sprite_db: SpriteDB, failures: Array[String]) -> void:
	if not sprite_db.has_method("release_report_quiet"):
		failures.append("SpriteDB should expose release_report_quiet for intentional missing release probes")
		return
	var report: Dictionary = sprite_db.call(
		"release_report_quiet", ["__missing_sprite_for_release__"])
	if bool(report.get("ready", true)):
		failures.append("release report should fail when a sprite is missing")
	if bool(report.get("public_ready", true)):
		failures.append("missing sprite report should fail public release")
	var report_failures: Array = report.get("failures", [])
	if report_failures.is_empty() or not str(report_failures[0]).contains("missing"):
		failures.append("release report should explain missing sprite failures")
	var sprites: Dictionary = report.get("sprites", {})
	var missing: Dictionary = sprites.get("__missing_sprite_for_release__", {})
	if str(missing.get("source", "")) != "missing":
		failures.append("missing sprite report should mark source as missing")
	if bool(missing.get("ready", true)):
		failures.append("missing sprite should not be marked release-ready")
	if not Array(missing.get("issues", [])).has("missing"):
		failures.append("missing sprite report should include missing issue")
	if bool(missing.get("frame_grid_ok", true)):
		failures.append("missing sprite should fail frame grid review")
	if bool(missing.get("animation_stability_reviewed", true)):
		failures.append("missing sprite should fail animation stability review")
	if str(missing.get("review_status", "")) != "blocked":
		failures.append("missing sprite should mark review_status blocked")
	if str(missing.get("replacement_policy", "")) != "add_asset_before_public":
		failures.append("missing sprite should ask for asset replacement before public release")
	_assert_source_policy_fields(missing, "missing sprite", failures)

func _check_audio_release_report(audio_db: RefCounted, failures: Array[String]) -> void:
	var critical_cues := [
		"blade_cast",
		"melee_attack",
		"skill_ready",
		"objective_complete",
		"room_clear_finale",
		"boss_enrage",
		"class_resource_full",
	]
	var report: Dictionary = audio_db.call("release_report", critical_cues)
	if not bool(report.get("ready", false)):
		failures.append("audio release report should pass for procedural cue set: %s" % report.get("failures", []))
	if not bool(report.get("public_ready", false)):
		failures.append("audio release report should mark procedural audio public-ready")
	if int(report.get("checked_count", 0)) != critical_cues.size():
		failures.append("audio release report should count checked cues")
	var placeholders: Array = report.get("generated_placeholders", [])
	if not placeholders.is_empty():
		failures.append("audio release report should not list procedural audio as placeholders")
	var blockers: Array = report.get("public_release_blockers", [])
	if not blockers.is_empty():
		failures.append("audio release report should not keep public release blockers")
	var cues: Dictionary = report.get("cues", {})
	for cue_id in critical_cues:
		var cue_report: Dictionary = cues.get(cue_id, {})
		if cue_report.is_empty():
			failures.append("%s should have audio release report metadata" % cue_id)
			continue
		_assert_source_policy_fields(cue_report, cue_id, failures)
		if str(cue_report.get("source", "")) != "project_owned_procedural_audio":
			failures.append("%s should mark project-owned procedural audio source" % cue_id)
		if str(cue_report.get("license", "")) != "project_owned_procedural_audio":
			failures.append("%s should mark project-owned procedural audio license" % cue_id)
		if str(cue_report.get("release_decision", "")) != "public_ok":
			failures.append("%s procedural audio should be public_ok" % cue_id)
		if str(cue_report.get("review_status", "")) != "stable_procedural_audio_ok":
			failures.append("%s should pass procedural audio stability review" % cue_id)
		if str(cue_report.get("replacement_policy", "")) != "owned_ok":
			failures.append("%s should not require audio replacement before public release" % cue_id)
		if bool(cue_report.get("needs_replacement_before_public", true)):
			failures.append("%s should not require replacement before public release" % cue_id)
		if float(cue_report.get("frequency", 0.0)) <= 0.0:
			failures.append("%s should expose procedural frequency" % cue_id)
		if float(cue_report.get("duration", 0.0)) <= 0.0:
			failures.append("%s should expose procedural duration" % cue_id)
		if not bool(cue_report.get("waveform_ok", false)):
			failures.append("%s should mark procedural waveform as stable" % cue_id)

func _check_audio_missing_report(audio_db: RefCounted, failures: Array[String]) -> void:
	var report: Dictionary = audio_db.call("release_report", ["__missing_audio_for_release__"])
	if bool(report.get("ready", true)):
		failures.append("audio release report should fail when a cue is missing")
	if bool(report.get("public_ready", true)):
		failures.append("missing audio report should fail public release")
	var report_failures: Array = report.get("failures", [])
	if report_failures.is_empty() or not str(report_failures[0]).contains("missing"):
		failures.append("audio release report should explain missing cue failures")
	var cues: Dictionary = report.get("cues", {})
	var missing: Dictionary = cues.get("__missing_audio_for_release__", {})
	if str(missing.get("source", "")) != "missing":
		failures.append("missing audio report should mark source as missing")
	if bool(missing.get("ready", true)):
		failures.append("missing audio should not be marked release-ready")
	if not Array(missing.get("issues", [])).has("missing"):
		failures.append("missing audio report should include missing issue")
	if bool(missing.get("waveform_ok", true)):
		failures.append("missing audio should fail waveform review")
	if str(missing.get("review_status", "")) != "blocked":
		failures.append("missing audio should mark review_status blocked")
	if str(missing.get("replacement_policy", "")) != "add_audio_before_public":
		failures.append("missing audio should ask for audio replacement before public release")
	_assert_source_policy_fields(missing, "missing audio", failures)

func _check_combat_fx_release_report(combat_fx: RefCounted, failures: Array[String]) -> void:
	var critical_fx := [
		"slash",
		"muzzle_flash",
		"dash_ghost",
		"telegraph",
		"skill_cast",
		"weapon_charge",
		"block_spark",
		"stationary_focus",
	]
	var report: Dictionary = combat_fx.call("release_report", critical_fx)
	if not bool(report.get("ready", false)):
		failures.append("combat fx release report should pass for critical procedural VFX: %s" % report.get("failures", []))
	if not bool(report.get("public_ready", false)):
		failures.append("combat fx procedural VFX should be public-ready project-owned shapes")
	if int(report.get("checked_count", 0)) != critical_fx.size():
		failures.append("combat fx release report should count checked VFX")
	if not Array(report.get("generated_placeholders", [])).is_empty():
		failures.append("combat fx procedural VFX should not be treated as generated asset placeholders")
	if not Array(report.get("public_release_blockers", [])).is_empty():
		failures.append("combat fx procedural VFX should not have public release blockers")
	var fx_reports: Dictionary = report.get("fx", {})
	for fx_id in critical_fx:
		var fx_report: Dictionary = fx_reports.get(fx_id, {})
		if fx_report.is_empty():
			failures.append("%s should have combat fx release metadata" % fx_id)
			continue
		_assert_source_policy_fields(fx_report, fx_id, failures)
		if str(fx_report.get("source", "")) != "procedural_godot_shapes":
			failures.append("%s should mark procedural Godot shape source" % fx_id)
		if str(fx_report.get("reference_policy", "")) != "fanmade_reference_only_no_copy":
			failures.append("%s should forbid copied fanmade source assets" % fx_id)
		if str(fx_report.get("license", "")) != "project_owned_procedural":
			failures.append("%s should mark project-owned procedural license" % fx_id)
		if str(fx_report.get("release_decision", "")) != "public_ok":
			failures.append("%s should be public_ok as project-owned procedural VFX" % fx_id)
		if str(fx_report.get("review_status", "")) != "stable_procedural_ok":
			failures.append("%s should pass procedural VFX stability review" % fx_id)
		if str(fx_report.get("replacement_policy", "")) != "owned_ok":
			failures.append("%s should not require replacement before public release" % fx_id)
		if bool(fx_report.get("needs_replacement_before_public", true)):
			failures.append("%s should not need replacement before public release" % fx_id)
		if int(fx_report.get("layer_count", 0)) <= 0:
			failures.append("%s should expose VFX layer count" % fx_id)
		if not bool(fx_report.get("geometry_ok", false)):
			failures.append("%s should pass geometry review" % fx_id)
		if not bool(fx_report.get("frame_grid_ok", false)):
			failures.append("%s should pass frame-grid stability review" % fx_id)
		if float(fx_report.get("duration", 0.0)) <= 0.0:
			failures.append("%s should expose reviewed animation duration" % fx_id)

	var missing_report: Dictionary = combat_fx.call("release_report", ["__missing_fx_for_release__"])
	if bool(missing_report.get("ready", true)):
		failures.append("combat fx release report should fail when a VFX id is missing")
	var missing_fx: Dictionary = Dictionary(missing_report.get("fx", {})).get("__missing_fx_for_release__", {})
	if str(missing_fx.get("source", "")) != "missing":
		failures.append("missing combat fx should mark source as missing")
	if str(missing_fx.get("review_status", "")) != "blocked":
		failures.append("missing combat fx should mark review_status blocked")
	if str(missing_fx.get("replacement_policy", "")) != "add_procedural_fx_before_release":
		failures.append("missing combat fx should request a replacement implementation")
	_assert_source_policy_fields(missing_fx, "missing combat fx", failures)

func _assert_source_policy_fields(entry: Dictionary, label: String, failures: Array[String]) -> void:
	if str(entry.get("source_policy_id", "")) == "":
		failures.append("%s should expose source_policy_id" % label)
	if str(entry.get("source_kind", "")) == "":
		failures.append("%s should expose source_kind" % label)
	if not entry.has("usable_runtime_asset"):
		failures.append("%s should expose usable_runtime_asset policy metadata" % label)
