extends SceneTree

const RELEASE_AUDIT_PATH := "res://scripts/assets/release_audit.gd"

func _init() -> void:
	var failures: Array[String] = []
	_check_release_audit(failures)
	if failures.is_empty():
		print("Release audit smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_release_audit(failures: Array[String]) -> void:
	if not ResourceLoader.exists(RELEASE_AUDIT_PATH):
		failures.append("ReleaseAudit should exist for combined asset/audio/VFX release decisions")
		return
	var script: Variant = load(RELEASE_AUDIT_PATH)
	for method_name in ["runtime_report", "public_release_decision", "summary_text",
			"replacement_backlog", "replacement_backlog_summary",
			"review_replacement_candidate", "source_policy_summary",
			"missing_asset_strategy", "balance_playtest_summary",
			"playtest_objective_summary", "balance_playtest_evidence_summary",
			"tuning_patch_summary", "balance_tuning_experiment_patch",
			"next_release_action", "release_candidate_summary"]:
		if not script.has_method(method_name):
			failures.append("ReleaseAudit should expose %s" % method_name)
			return
	var report: Dictionary = script.call("runtime_report")
	if not bool(report.get("ready_for_internal_playtest", false)):
		failures.append("release audit should allow internal playtest when assets are stable")
	if not bool(report.get("public_ready", false)):
		failures.append("release audit should pass public release when procedural audio and reviewed art are ready")
	var report_source_policy := str(report.get("asset_source_policy", ""))
	for token in ["Missing assets:", "free itch.io", "AI", "Self-review:", "polygon", "no copy"]:
		if not report_source_policy.contains(token):
			failures.append("runtime report source policy missing token: %s" % token)
	if int(report.get("checked_sprite_count", 0)) <= 0:
		failures.append("release audit should count checked sprites")
	if int(report.get("checked_audio_count", 0)) <= 0:
		failures.append("release audit should count checked audio cues")
	var audio_cues: Dictionary = Dictionary(Dictionary(report.get("categories", {})).get("audio", {})).get("cues", {})
	for boss_cue_id in ["boss_phase_shift", "boss_bullet_hell", "boss_trap_wave"]:
		if not audio_cues.has(boss_cue_id):
			failures.append("release audit should include boss audio cue: %s" % boss_cue_id)
	for damage_cue_id in [
		"player_damage_enemy",
		"player_damage_trap",
		"player_damage_status",
		"player_damage_boss",
	]:
		if not audio_cues.has(damage_cue_id):
			failures.append("release audit should include player damage audio cue: %s" % damage_cue_id)
	for hit_cue_id in [
		"enemy_hit_normal",
		"enemy_hit_weak",
		"enemy_hit_resist",
		"enemy_hit_critical",
	]:
		if not audio_cues.has(hit_cue_id):
			failures.append("release audit should include enemy hit audio cue: %s" % hit_cue_id)
	if not audio_cues.has("enemy_death"):
		failures.append("release audit should include enemy death audio cue")
	for pickup_cue_id in ["pickup_gold", "pickup_heal", "pickup_key", "pickup_weapon", "pickup_meta"]:
		if not audio_cues.has(pickup_cue_id):
			failures.append("release audit should include pickup audio cue: %s" % pickup_cue_id)
	for shop_cue_id in ["shop_buy", "shop_leave"]:
		if not audio_cues.has(shop_cue_id):
			failures.append("release audit should include shop audio cue: %s" % shop_cue_id)
	if not audio_cues.has("objective_blocked"):
		failures.append("release audit should include objective blocked audio cue")
	for cue_id in audio_cues.keys():
		var cue: Dictionary = audio_cues.get(cue_id, {})
		if str(cue.get("source", "")) != "project_owned_procedural_audio":
			failures.append("%s should use project-owned procedural audio" % str(cue_id))
		if str(cue.get("release_decision", "")) != "public_ok":
			failures.append("%s procedural audio should be public_ok" % str(cue_id))
		if bool(cue.get("needs_replacement_before_public", true)):
			failures.append("%s procedural audio should not remain in public replacement backlog" % str(cue_id))
	if int(report.get("checked_fx_count", 0)) <= 0:
		failures.append("release audit should count checked procedural VFX")
	if int(report.get("animation_frame_grid_checked_count", 0)) <= 0:
		failures.append("release audit should count animation frame-grid checks")
	if int(report.get("unstable_animation_count", 0)) != 0:
		failures.append("release audit should block unstable animation frame grids")
	if str(report.get("animation_review_status", "")) != "stable":
		failures.append("release audit should mark critical animation frame grids stable")
	if int(report.get("collision_shape_checked_count", 0)) <= 0:
		failures.append("release audit should count critical collision shape checks")
	if int(report.get("collision_polygon_checked_count", 0)) <= 0:
		failures.append("release audit should count critical polygon visual checks")
	if str(report.get("collision_review_status", "")) != "stable":
		failures.append("release audit should mark collision/polygon review stable")
	var collision_entries: Dictionary = Dictionary(
		Dictionary(Dictionary(report.get("categories", {})).get("collision", {})).get("entries", {}))
	for entry_id in ["player", "enemy"]:
		var entry: Dictionary = collision_entries.get(entry_id, {})
		if float(entry.get("polygon_area_px", 0.0)) <= 0.0:
			failures.append("%s collision polygon should expose non-zero area" % entry_id)
	if int(report.get("object_visual_checked_count", 0)) <= 0:
		failures.append("release audit should count gameplay object visual checks")
	if str(report.get("object_visual_review_status", "")) != "stable":
		failures.append("release audit should mark gameplay object sprite/polygon review stable")
	if int(report.get("checked_balance_enemy_count", 0)) <= 0:
		failures.append("release audit should count balance-checked enemies")
	if int(report.get("balance_warning_count", -1)) < 0:
		failures.append("release audit should expose balance warning count")
	if int(report.get("balance_tuning_backlog_count", -1)) != 0:
		failures.append("release audit should have no static balance tuning backlog after data tuning")
	if int(report.get("balance_playtest_focus_count", -1)) != 0:
		failures.append("release audit should have no prioritized tuning focus after data tuning")
	if str(report.get("balance_review_status", "")) != "stable":
		failures.append("release audit should mark balance hard gates stable")
	var balance_playtest_summary := str(report.get("balance_playtest_summary", ""))
	for token in ["Tuning Focus: None", "Pace evidence ready"]:
		if not balance_playtest_summary.contains(token):
			failures.append("release audit balance playtest summary missing token: %s" % token)
	var playtest_objective := str(report.get("balance_playtest_objective", ""))
	for token in ["Playtest Objective: None", "Target met", "Pace evidence ready"]:
		if not playtest_objective.contains(token):
			failures.append("release audit playtest objective missing token: %s" % token)
	if str(script.call("playtest_objective_summary")) != playtest_objective:
		failures.append("release audit objective helper should match runtime report")
	var tuning_patch: Dictionary = report.get("balance_tuning_patch_preview", {})
	if not tuning_patch.is_empty():
		failures.append("release audit tuning patch preview should be empty when balance is inside guardrails")
	var experiment_patch: Dictionary = report.get("balance_tuning_experiment_patch", {})
	if experiment_patch.is_empty():
		failures.append("release audit should expose balance tuning experiment patch state")
	elif bool(experiment_patch.get("enabled", true)):
		failures.append("release audit tuning experiment patch should stay disabled before evidence")
	elif str(experiment_patch.get("reason", "")) != "no_tuning_backlog":
		failures.append("release audit disabled experiment patch should explain no tuning backlog")
	var evidence_meta := {
		"recent_runs": [
			{"boss_variant": "cave_golem", "biome_id": "ancient_cave", "pace_boss_sec": 85.0},
			{"boss_variant": "spore_golem", "biome_id": "fungal_depths", "pace_boss_sec": 85.0},
			{"boss_variant": "forge_golem", "biome_id": "ember_forge", "pace_boss_sec": 85.0},
			{"boss_variant": "archive_golem", "biome_id": "crystal_archive", "pace_boss_sec": 85.0},
		],
	}
	var measured_report: Dictionary = script.call("runtime_report", evidence_meta)
	if int(measured_report.get("balance_playtest_evidence_count", 0)) <= 0:
		failures.append("release audit should still count historical pace evidence")
	var measured_patch: Dictionary = measured_report.get("balance_tuning_patch_preview", {})
	if not measured_patch.is_empty():
		failures.append("release audit should not create a measured patch without a tuning backlog")
	var measured_experiment: Dictionary = measured_report.get("balance_tuning_experiment_patch", {})
	if bool(measured_experiment.get("enabled", true)):
		failures.append("release audit should not enable a tuning experiment without backlog")
	if str(measured_experiment.get("reason", "")) != "no_tuning_backlog":
		failures.append("release audit measured experiment should explain no tuning backlog")
	var direct_experiment: Dictionary = script.call("balance_tuning_experiment_patch", evidence_meta)
	if direct_experiment != measured_experiment:
		failures.append("release audit experiment helper should match runtime report")
	var measured_summary := str(script.call("tuning_patch_summary", evidence_meta))
	for token in ["Tuning Patch: None", "Evidence ready"]:
		if not measured_summary.contains(token):
			failures.append("release audit measured tuning patch summary missing token: %s" % token)
	var evidence_summary := str(script.call("balance_playtest_evidence_summary", evidence_meta))
	for token in ["Playtest Evidence:", "None"]:
		if not evidence_summary.contains(token):
			failures.append("release audit playtest evidence summary missing token: %s" % token)
	var measured_next_action := str(script.call("next_release_action", evidence_meta))
	for token in ["Next Action:", "Release gate clear"]:
		if not measured_next_action.contains(token):
			failures.append("release audit measured next action missing token: %s" % token)
	var tuning_patch_summary := str(script.call("tuning_patch_summary"))
	for token in ["Tuning Patch: None", "Evidence ready"]:
		if not tuning_patch_summary.contains(token):
			failures.append("release audit tuning patch summary missing token: %s" % token)
	var next_action := str(script.call("next_release_action"))
	for token in ["Next Action:", "Release gate clear"]:
		if not next_action.contains(token):
			failures.append("release audit next action missing token: %s" % token)
	_check_release_candidate_summary(script, failures)
	var balance_report: Dictionary = Dictionary(
		Dictionary(report.get("categories", {})).get("balance", {}))
	if balance_report.is_empty():
		failures.append("release audit should expose balance drilldown")
	else:
		if not bool(balance_report.get("ready", false)):
			failures.append("balance report should pass hard gates before public release")
		var targets: Dictionary = balance_report.get("gdd_targets", {})
		if targets.get("normal_ttk_sec", Vector2.ZERO) != Vector2(1.0, 3.0):
			failures.append("balance report should preserve normal enemy TTK target")
		if targets.get("boss_ttk_sec", Vector2.ZERO) != Vector2(120.0, 240.0):
			failures.append("balance report should preserve boss fight target")
		if Dictionary(balance_report.get("starter_dps", {})).is_empty():
			failures.append("balance report should expose starter DPS estimates")
		if Dictionary(balance_report.get("normal_enemy_ttk_sec", {})).is_empty():
			failures.append("balance report should expose normal enemy TTK estimates")
		if Dictionary(balance_report.get("boss_ttk_sec", {})).is_empty():
			failures.append("balance report should expose boss TTK estimates")
		if not Array(balance_report.get("warnings", [])).is_empty():
			failures.append("balance report should have no static TTK warnings after data tuning")
		var tuning_backlog: Array = balance_report.get("tuning_backlog", [])
		if not tuning_backlog.is_empty():
			failures.append("balance report should have no static tuning backlog after data tuning")
	var runtime_objects: Dictionary = Dictionary(Dictionary(report.get("categories", {})).get("runtime_objects", {}))
	if runtime_objects.is_empty():
		failures.append("release audit should expose runtime object visual drilldown")
	else:
		var entries: Dictionary = runtime_objects.get("entries", {})
		for entry_id in ["interactable:chest", "interactable:element_altar",
				"interactable:blood_altar", "interactable:rune_cache",
				"interactable:cursed_chest", "interactable:trap_cache",
				"interactable:secret_cache", "trap:spike", "prop:crate",
				"pickup:silver_key", "portal:next_floor"]:
			if not entries.has(entry_id):
				failures.append("runtime object visual audit missing entry: %s" % entry_id)
				continue
			var entry: Dictionary = entries.get(entry_id, {})
			for key in ["sprite", "source_script", "fallback_polygon_points",
					"fallback_polygon_area_px", "polygon_ok", "sprite_release_decision",
					"frame_grid_ok", "origin_alignment_reviewed",
					"needs_replacement_before_public", "runtime_geometry_reviewed",
					"runtime_shape_ok", "runtime_shape_size", "runtime_polygon_ok",
					"runtime_polygon_points", "runtime_polygon_area_px"]:
				if not entry.has(key):
					failures.append("runtime object visual entry missing %s: %s" % [entry_id, key])
			if int(entry.get("fallback_polygon_points", 0)) < 3:
				failures.append("%s should keep a reviewed polygon fallback" % entry_id)
			if float(entry.get("fallback_polygon_area_px", 0.0)) <= 0.0:
				failures.append("%s should keep a non-zero fallback polygon area" % entry_id)
			if not bool(entry.get("polygon_ok", false)):
				failures.append("%s polygon fallback should be release-reviewed" % entry_id)
			if str(entry.get("sprite", "")) == "":
				failures.append("%s should name its runtime sprite" % entry_id)
			if str(entry.get("sprite_release_decision", "")) == "blocked":
				failures.append("%s should not use blocked runtime sprite art" % entry_id)
			if not bool(entry.get("frame_grid_ok", false)):
				failures.append("%s should use stable sprite frame grid" % entry_id)
			if not bool(entry.get("origin_alignment_reviewed", false)):
				failures.append("%s should use reviewed sprite origin alignment" % entry_id)
			if not bool(entry.get("runtime_geometry_reviewed", false)):
				failures.append("%s should review actual runtime geometry before release" % entry_id)
			if not bool(entry.get("runtime_shape_ok", false)):
				failures.append("%s should expose a valid runtime interaction shape" % entry_id)
			if entry.get("runtime_shape_size", Vector2.ZERO) == Vector2.ZERO:
				failures.append("%s should expose non-zero runtime shape size" % entry_id)
			if not bool(entry.get("runtime_polygon_ok", false)):
				failures.append("%s should expose a valid runtime fallback polygon" % entry_id)
			if int(entry.get("runtime_polygon_points", 0)) < 3:
				failures.append("%s should expose actual runtime polygon point count" % entry_id)
			if float(entry.get("runtime_polygon_area_px", 0.0)) <= 0.0:
				failures.append("%s should expose actual runtime polygon area" % entry_id)
		var silver_key: Dictionary = entries.get("pickup:silver_key", {})
		if str(silver_key.get("sprite_release_decision", "")) != "public_ok":
			failures.append("silver key project-owned sprite should be public_ok")
		if bool(silver_key.get("needs_replacement_before_public", true)):
			failures.append("silver key project-owned sprite should not remain in public replacement backlog")
		var blueprint: Dictionary = entries.get("pickup:blueprint", {})
		if str(blueprint.get("sprite_release_decision", "")) != "public_ok":
			failures.append("blueprint project-owned sprite should be public_ok")
		if bool(blueprint.get("needs_replacement_before_public", true)):
			failures.append("blueprint project-owned sprite should not remain in public replacement backlog")
		var sprite_category: Dictionary = Dictionary(Dictionary(report.get("categories", {})).get("sprites", {}))
		var sprite_entries: Dictionary = sprite_category.get("sprites", {})
		for tile_sprite in [
			"floor_1", "floor_2", "floor_3", "floor_4",
			"floor_5", "floor_6", "floor_7", "floor_8",
			"wall_top_left", "wall_top_mid", "wall_top_right",
			"wall_left", "wall_mid", "wall_right",
			"doors_leaf_open", "doors_leaf_closed",
			"hole", "edge_down",
		]:
			var tile_entry: Dictionary = sprite_entries.get(tile_sprite, {})
			if tile_entry.is_empty():
				failures.append("release audit should include runtime tile sprite: %s" % tile_sprite)
				continue
			if str(tile_entry.get("source_policy_id", "")) != "0x72_dungeontileset_ii":
				failures.append("%s tile sprite should keep 0x72 source metadata" % tile_sprite)
			if str(tile_entry.get("release_decision", "")) != "public_ok":
				failures.append("%s tile sprite should be public_ok" % tile_sprite)
			if not bool(tile_entry.get("frame_grid_ok", false)):
				failures.append("%s tile sprite should pass frame grid review" % tile_sprite)
			if not bool(tile_entry.get("origin_alignment_reviewed", false)):
				failures.append("%s tile sprite should pass origin alignment review" % tile_sprite)
		var unknown_pickup: Dictionary = sprite_entries.get("pickup_unknown_generated", {})
		if str(unknown_pickup.get("release_decision", "")) != "public_ok":
			failures.append("unknown pickup project-owned sprite should be public_ok")
		if bool(unknown_pickup.get("needs_replacement_before_public", true)):
			failures.append("unknown pickup project-owned sprite should not remain in public replacement backlog")
		var fire_patch: Dictionary = sprite_entries.get("fire_patch_generated", {})
		if str(fire_patch.get("release_decision", "")) != "public_ok":
			failures.append("fire patch project-owned VFX sprite should be public_ok")
		if bool(fire_patch.get("needs_replacement_before_public", true)):
			failures.append("fire patch project-owned VFX sprite should not remain in public replacement backlog")
		for boss_sprite in ["big_demon_idle_anim", "big_demon_run_anim"]:
			var boss_entry: Dictionary = sprite_entries.get(boss_sprite, {})
			if boss_entry.is_empty():
				failures.append("release audit should include boss runtime sprite: %s" % boss_sprite)
				continue
			if str(boss_entry.get("release_decision", "")) != "public_ok":
				failures.append("%s boss sprite should be public_ok" % boss_sprite)
			if bool(boss_entry.get("needs_replacement_before_public", true)):
				failures.append("%s boss sprite should not remain in public replacement backlog" % boss_sprite)
			if not bool(boss_entry.get("frame_grid_ok", false)):
				failures.append("%s boss sprite should pass frame grid review" % boss_sprite)
			if not bool(boss_entry.get("origin_alignment_reviewed", false)):
				failures.append("%s boss sprite should pass origin alignment review" % boss_sprite)
		var class_runtime_sprites := {}
		for class_data in PlayerClassDB.all():
			var class_id := str(class_data.get("id", ""))
			var names := Player.class_sprite_names(class_id)
			if names.is_empty():
				failures.append("%s should expose class runtime sprites for release audit" % class_id)
				continue
			for role in ["idle", "run"]:
				var sprite_name := str(names.get(role, ""))
				if sprite_name == "" or class_runtime_sprites.has(sprite_name):
					continue
				class_runtime_sprites[sprite_name] = true
				var class_entry: Dictionary = sprite_entries.get(sprite_name, {})
				if class_entry.is_empty():
					failures.append("release audit should include %s class %s sprite: %s" % [
						class_id, role, sprite_name,
					])
					continue
				if str(class_entry.get("release_decision", "")) != "public_ok":
					failures.append("%s class sprite should be public_ok" % sprite_name)
				if bool(class_entry.get("needs_replacement_before_public", true)):
					failures.append("%s class sprite should not remain in public replacement backlog" % sprite_name)
				if not bool(class_entry.get("frame_grid_ok", false)):
					failures.append("%s class sprite should pass frame grid review" % sprite_name)
				if not bool(class_entry.get("origin_alignment_reviewed", false)):
					failures.append("%s class sprite should pass origin alignment review" % sprite_name)
		var weapon_runtime_sprites := {}
		for weapon_id in WeaponDB.all_ids():
			var sprite_name := WeaponDB.preview_sprite_name_for_weapon(str(weapon_id))
			if sprite_name == "" or weapon_runtime_sprites.has(sprite_name):
				continue
			weapon_runtime_sprites[sprite_name] = true
			var weapon_entry: Dictionary = sprite_entries.get(sprite_name, {})
			if weapon_entry.is_empty():
				failures.append("release audit should include weapon preview sprite for %s: %s" % [
					str(weapon_id), sprite_name,
				])
				continue
			if str(weapon_entry.get("release_decision", "")) != "public_ok":
				failures.append("%s weapon sprite should be public_ok" % sprite_name)
			if bool(weapon_entry.get("needs_replacement_before_public", true)):
				failures.append("%s weapon sprite should not remain in public replacement backlog" % sprite_name)
			if not bool(weapon_entry.get("frame_grid_ok", false)):
				failures.append("%s weapon sprite should pass frame grid review" % sprite_name)
			if not bool(weapon_entry.get("origin_alignment_reviewed", false)):
				failures.append("%s weapon sprite should pass origin alignment review" % sprite_name)
		var enemy_runtime_sprites := {}
		for enemy_id in RoomRenderer.ENEMY_SPRITES.keys():
			var mapping: Dictionary = RoomRenderer.ENEMY_SPRITES.get(enemy_id, {})
			for role in ["idle", "run"]:
				var sprite_name := SpriteDB.first_existing(mapping.get(role, []))
				if sprite_name == "" or enemy_runtime_sprites.has(sprite_name):
					continue
				enemy_runtime_sprites[sprite_name] = true
				var enemy_entry: Dictionary = sprite_entries.get(sprite_name, {})
				if enemy_entry.is_empty():
					failures.append("release audit should include enemy %s sprite for %s: %s" % [
						role, str(enemy_id), sprite_name,
					])
					continue
				if str(enemy_entry.get("release_decision", "")) != "public_ok":
					failures.append("%s enemy sprite should be public_ok" % sprite_name)
				if bool(enemy_entry.get("needs_replacement_before_public", true)):
					failures.append("%s enemy sprite should not remain in public replacement backlog" % sprite_name)
				if not bool(enemy_entry.get("frame_grid_ok", false)):
					failures.append("%s enemy sprite should pass frame grid review" % sprite_name)
				if not bool(enemy_entry.get("origin_alignment_reviewed", false)):
					failures.append("%s enemy sprite should pass origin alignment review" % sprite_name)
		var skill_runtime_sprites := {
			"player_projectile_arrow": "zerie_arrow_projectile",
			"enemy_projectile_arrow": "zerie_arrow_projectile",
			"mini_turret": "weapon_bow_2",
			"floating_gun": "weapon_red_magic_staff",
			"rolling_grenade": "bomb",
			"snare_trap": "floor_spikes_anim",
			"summon_wisp": "angel_idle_anim",
			"soul_kingdom_spirit": "necromancer_anim",
			"fire_patch": "fire_patch_generated",
		}
		for runtime_id in skill_runtime_sprites.keys():
			var sprite_name := str(skill_runtime_sprites[runtime_id])
			var skill_entry: Dictionary = sprite_entries.get(sprite_name, {})
			if skill_entry.is_empty():
				failures.append("release audit should include skill runtime sprite for %s: %s" % [
					str(runtime_id), sprite_name,
				])
				continue
			if str(skill_entry.get("release_decision", "")) != "public_ok":
				failures.append("%s skill runtime sprite should be public_ok" % sprite_name)
			if bool(skill_entry.get("needs_replacement_before_public", true)):
				failures.append("%s skill runtime sprite should not remain in public replacement backlog" % sprite_name)
			if not bool(skill_entry.get("frame_grid_ok", false)):
				failures.append("%s skill runtime sprite should pass frame grid review" % sprite_name)
			if not bool(skill_entry.get("origin_alignment_reviewed", false)):
				failures.append("%s skill runtime sprite should pass origin alignment review" % sprite_name)
		var ui_runtime_sprites := {
			"hud_hp_full": "ui_heart_full",
			"hud_hp_half": "ui_heart_half",
			"hud_hp_empty": "ui_heart_empty",
			"hud_resource": "flask_big_blue",
			"hud_status_damage": "flask_big_green",
			"hud_boss_damage": "skull",
			"element_fire": "flask_red",
			"element_ice": "flask_blue",
			"element_lightning": "flask_yellow",
			"element_poison": "flask_green",
			"upgrade_vital_core": "flask_big_red",
			"route_treasure": "flask_big_yellow",
			"upgrade_power": "weapon_red_gem_sword",
			"upgrade_aegis": "weapon_knight_sword",
			"cooldown_roar": "weapon_mace",
			"route_exit": "floor_ladder",
			"portal_finale": "floor_stairs",
			"trap_saw": "weapon_saw_sword",
			"prop_crate": "crate",
		}
		for runtime_id in ui_runtime_sprites.keys():
			var sprite_name := str(ui_runtime_sprites[runtime_id])
			var ui_entry: Dictionary = sprite_entries.get(sprite_name, {})
			if ui_entry.is_empty():
				failures.append("release audit should include UI runtime sprite for %s: %s" % [
					str(runtime_id), sprite_name,
				])
				continue
			if str(ui_entry.get("release_decision", "")) != "public_ok":
				failures.append("%s UI runtime sprite should be public_ok" % sprite_name)
			if bool(ui_entry.get("needs_replacement_before_public", true)):
				failures.append("%s UI runtime sprite should not remain in public replacement backlog" % sprite_name)
			if not bool(ui_entry.get("frame_grid_ok", false)):
				failures.append("%s UI runtime sprite should pass frame grid review" % sprite_name)
			if not bool(ui_entry.get("origin_alignment_reviewed", false)):
				failures.append("%s UI runtime sprite should pass origin alignment review" % sprite_name)
		var portal: Dictionary = entries.get("portal:next_floor", {})
		if str(portal.get("sprite_release_decision", "")) != "public_ok":
			failures.append("portal ladder sprite should be public_ok licensed atlas art")
	var missing_script_object: Dictionary = script.call("_runtime_object_entry", {
		"id": "object:missing_source_script",
		"sprite": "coin_anim",
		"source_script": "res://scripts/rooms/missing_object_source.gd",
		"fallback_polygon_points": 4,
		"fallback_polygon_area_px": 64.0,
	})
	if not Array(missing_script_object.get("issues", [])).has("source_script_missing"):
		failures.append("runtime object audit should fail when source_script is missing")
	var broken_runtime_object: Dictionary = script.call("_runtime_object_entry", {
		"id": "object:broken_runtime_geometry",
		"sprite": "coin_anim",
		"source_script": "res://scripts/tests/fixtures/broken_runtime_object.gd",
		"fallback_polygon_points": 4,
		"fallback_polygon_area_px": 64.0,
	})
	var broken_runtime_issues: Array = broken_runtime_object.get("issues", [])
	if bool(broken_runtime_object.get("runtime_geometry_reviewed", true)):
		failures.append("runtime object audit should reject broken runtime geometry contracts")
	if not broken_runtime_issues.has("runtime_shape_missing"):
		failures.append("runtime object audit should catch missing runtime shapes")
	if not broken_runtime_issues.has("runtime_polygon_too_small"):
		failures.append("runtime object audit should catch undersized runtime polygons")
	if bool(broken_runtime_object.get("polygon_ok", true)):
		failures.append("runtime object polygon_ok should include actual runtime geometry")
	var blockers: Array = report.get("public_release_blockers", [])
	if not blockers.is_empty():
		failures.append("release audit should not keep public release blockers after asset review")
	var replacements: Array = report.get("replace_before_public", [])
	if not replacements.is_empty():
		failures.append("release audit should not list replacement work after asset review")
	var backlog: Array = script.call("replacement_backlog")
	if not backlog.is_empty():
		failures.append("release audit should not expose runtime replacement backlog when assets are reviewed")
	var collision_backlog: Array = script.call("_replacement_backlog_from_report", {
		"categories": {
			"collision": {
				"entries": {
					"missing_polygon_scene": {
						"path": "res://scenes/missing_polygon_fixture.tscn",
						"shape_ok": true,
						"polygon_ok": false,
						"polygon_points": 0,
						"issues": ["polygon_visual_missing"],
					},
				},
			},
		},
	})
	var saw_collision := false
	for item in collision_backlog:
		if item is Dictionary and str((item as Dictionary).get("kind", "")) == "collision":
			saw_collision = true
			var entry := item as Dictionary
			if bool(entry.get("polygon_ok", true)):
				failures.append("collision backlog should preserve polygon review status")
			if int(entry.get("polygon_points", -1)) != 0:
				failures.append("collision backlog should preserve polygon point count")
			if not Array(entry.get("acceptance_gate", [])).has("collision_shape_or_polygon_ok"):
				failures.append("collision backlog should require collision/polygon acceptance")
			if not Array(entry.get("allowed_replacement_sources", [])).has("project_owned_collision_polygon"):
				failures.append("collision backlog should allow project-owned polygon replacement")
			if not Array(entry.get("allowed_replacement_sources", [])).has("free_itchio") \
					or not Array(entry.get("allowed_replacement_sources", [])).has("ai_generated"):
				failures.append("collision backlog should allow free itch.io and AI polygon replacements")
			if not Array(entry.get("release_review_checklist", [])).has("collision_polygon_points"):
				failures.append("collision backlog should require polygon point review")
	if not saw_collision:
		failures.append("replacement backlog should include missing collision polygon work")
	var flat_runtime_object_replacements: Array = script.call("_runtime_object_replacements", {
		"entries": {
			"trap:flat_spike": {
				"sprite": "floor_spikes_anim",
				"sprite_release_decision": "public_ok",
				"replacement_policy": "licensed_ok",
				"needs_replacement_before_public": false,
				"fallback_polygon_points": 4,
				"fallback_polygon_area_px": 0.0,
				"polygon_ok": false,
				"frame_grid_ok": true,
				"issues": ["fallback_polygon_area_empty"],
			},
		},
	})
	if flat_runtime_object_replacements.is_empty() \
			or not str(flat_runtime_object_replacements[0]).contains(
				"fix_runtime_object_polygon_before_public"):
		failures.append("runtime object replacements should list area fixes for flat polygons")
	var runtime_object_backlog: Array = script.call("_replacement_backlog_from_report", {
		"categories": {
			"runtime_objects": {
				"entries": {
					"trap:broken_spike": {
						"sprite": "floor_spikes_anim",
						"source_script": "res://scripts/rooms/trap.gd",
						"sprite_source": "0x72_dungeontileset_ii",
						"sprite_release_decision": "public_ok",
						"replacement_policy": "fix_runtime_object_polygon_before_public",
						"fallback_polygon_points": 2,
						"fallback_polygon_area_px": 0.0,
						"polygon_ok": false,
						"frame_grid_ok": true,
						"issues": ["fallback_polygon_too_small"],
					},
				},
			},
		},
	})
	var saw_runtime_object := false
	for item in runtime_object_backlog:
		if item is Dictionary and str((item as Dictionary).get("kind", "")) == "object_visual":
			saw_runtime_object = true
			var entry := item as Dictionary
			if str(entry.get("id", "")) != "trap:broken_spike":
				failures.append("runtime object backlog should preserve object id")
			if bool(entry.get("polygon_ok", true)):
				failures.append("runtime object backlog should preserve broken polygon status")
			if int(entry.get("fallback_polygon_points", -1)) != 2:
				failures.append("runtime object backlog should preserve fallback polygon point count")
			if float(entry.get("fallback_polygon_area_px", -1.0)) != 0.0:
				failures.append("runtime object backlog should preserve fallback polygon area")
			if not Array(entry.get("acceptance_gate", [])).has("runtime_object_sprite_ok"):
				failures.append("runtime object backlog should require sprite acceptance")
			if not Array(entry.get("acceptance_gate", [])).has("fallback_polygon_points"):
				failures.append("runtime object backlog should require fallback polygon review")
			if not Array(entry.get("allowed_replacement_sources", [])).has("project_owned_collision_polygon"):
				failures.append("runtime object backlog should allow project-owned polygon fixes")
			if not Array(entry.get("allowed_replacement_sources", [])).has("free_itchio") \
					or not Array(entry.get("allowed_replacement_sources", [])).has("ai_generated"):
				failures.append("runtime object backlog should allow licensed itch.io or AI object fixes")
			if not Array(entry.get("release_review_checklist", [])).has("frame_grid_stable"):
				failures.append("runtime object backlog should require stable animation frame review")
			var source_plan: Dictionary = entry.get("source_plan", {})
			if str(source_plan.get("fanmade_policy", "")) != "reference_only_pattern_study":
				failures.append("runtime object backlog should keep fanmade repos reference-only")
	if not saw_runtime_object:
		failures.append("replacement backlog should include runtime object polygon/fallback work")
	var runtime_object_replacements: Array = script.call("_runtime_object_replacements", {
		"entries": {
			"trap:broken_spike": {
				"sprite": "floor_spikes_anim",
				"sprite_release_decision": "public_ok",
				"replacement_policy": "licensed_ok",
				"needs_replacement_before_public": false,
				"fallback_polygon_points": 2,
				"fallback_polygon_area_px": 0.0,
				"polygon_ok": false,
				"frame_grid_ok": true,
				"issues": ["fallback_polygon_too_small"],
			},
		},
	})
	if runtime_object_replacements.is_empty() \
			or not str(runtime_object_replacements[0]).contains("fix_runtime_object_polygon_before_public"):
		failures.append("runtime object replacements should list polygon fixes even when sprite art is public-ready")
	var backlog_summary := str(script.call("replacement_backlog_summary", 3))
	if backlog_summary != "No replacement backlog":
		failures.append("replacement backlog summary should report no runtime backlog")
	if not Dictionary(report.get("categories", {})).has("sprites") \
			or not Dictionary(report.get("categories", {})).has("audio") \
			or not Dictionary(report.get("categories", {})).has("vfx") \
			or not Dictionary(report.get("categories", {})).has("collision") \
			or not Dictionary(report.get("categories", {})).has("runtime_objects") \
			or not Dictionary(report.get("categories", {})).has("balance"):
		failures.append("release audit should keep category reports for review drilldown")
	if str(report.get("reference_policy", "")) != "fanmade_reference_only_no_copy":
		failures.append("release audit should retain fanmade reference-only policy")
	var decision := str(script.call("public_release_decision"))
	if decision != "public_ok":
		failures.append("release audit decision should be public_ok after asset review")
	var summary := str(script.call("summary_text"))
	for token in ["Internal playtest", "Public release", "replace", "fanmade", "Frame grid",
			"Collision", "Objects", "Balance", "warnings", "tune", "Playtest"]:
		if not summary.contains(token):
			failures.append("release audit summary missing token: %s" % token)
	var source_summary := str(script.call("source_policy_summary"))
	for token in ["Sources:", "0x72", "free itch.io", "Godot Asset Library", "AI", "Fanmade refs:",
			"pattern only", "Self-review:", "frame", "polygon", "no copy",
			"origin", "CalvinWan0101/soul-knight", "leoyin1127/Soul-knights",
			"Missing assets:"]:
		if not source_summary.contains(token):
			failures.append("release audit source policy summary missing token: %s" % token)
	var collision_strategy: Dictionary = script.call("missing_asset_strategy", "collision")
	if collision_strategy.is_empty():
		failures.append("release audit should expose missing asset strategy for collision")
	else:
		if collision_strategy.get("kind", "") != "collision":
			failures.append("collision missing asset strategy should preserve kind")
		if collision_strategy.get("source_priority", []) != _expected_source_priority("collision"):
			failures.append("collision missing asset strategy should expose runtime source priority")
		if Array(collision_strategy.get("runtime_source_priority", [])).has("fanmade_direct_copy"):
			failures.append("collision missing asset strategy should not allow fanmade runtime copy")
		if not Array(collision_strategy.get("reference_pattern_sources", [])).has(
				"CalvinWan0101/soul-knight"):
			failures.append("collision missing asset strategy should keep fanmade refs for pattern study")
		var collision_gate: Array = collision_strategy.get("release_self_review_gate", [])
		for gate in ["collision_polygon_points", "polygon_points", "polygon_area_px",
				"no_direct_fanmade_copy"]:
			if not collision_gate.has(gate):
				failures.append("collision missing asset strategy release gate missing %s" % gate)
		if not Array(collision_strategy.get("manifest_required_fields", [])).has("polygon_points"):
			failures.append("collision missing asset strategy should require polygon manifest points")
		if not Array(collision_strategy.get("resolution_steps", [])).has(
				"release_only_after_frame_polygon_motion_review"):
			failures.append("collision missing asset strategy should hold release until self-review passes")
	var object_strategy: Dictionary = script.call("missing_asset_strategy", "object_visual")
	if not Array(object_strategy.get("release_self_review_gate", [])).has("frame_grid_ok") \
			or not Array(object_strategy.get("release_self_review_gate", [])).has(
				"fallback_polygon_points") \
			or not Array(object_strategy.get("release_self_review_gate", [])).has(
				"fallback_polygon_area_px"):
		failures.append("object visual missing asset strategy should gate frame grid and fallback polygon area")
	for manifest_kind in ["sprite", "audio", "vfx", "collision", "object_visual"]:
		_expect_manifest_fields(script.call("_source_plan", manifest_kind, [
			"no_direct_fanmade_copy",
		]), manifest_kind, _expected_manifest_fields(manifest_kind), failures)
	_check_replacement_candidate_review(script, failures)

func _expected_manifest_fields(kind: String) -> Array[String]:
	match kind:
		"sprite":
			return ["asset_kind", "license", "generation_tool", "frame_size",
				"expected_frame_size", "frame_count", "frame_grid_ok", "stable_size",
				"fps", "animation_stability_reviewed", "motion_reviewed",
				"origin_alignment_reviewed", "origin_px", "review_notes"]
		"audio":
			return ["asset_kind", "license", "generation_tool", "waveform_ok",
				"duration", "review_notes"]
		"vfx":
			return ["asset_kind", "license", "generation_tool", "frame_size",
				"expected_frame_size", "frame_count", "frame_grid_ok", "fps",
				"animation_stability_reviewed", "motion_reviewed",
				"origin_alignment_reviewed", "origin_px", "geometry_ok", "duration", "review_notes"]
		"collision":
			return ["asset_kind", "license", "generation_tool", "shape_ok", "polygon_ok",
				"polygon_points", "polygon_area_px", "review_notes"]
		"object_visual":
			return ["asset_kind", "license", "generation_tool", "runtime_object_sprite_ok",
				"frame_size", "expected_frame_size", "frame_count", "frame_grid_ok", "fps",
				"animation_stability_reviewed", "motion_reviewed",
				"origin_alignment_reviewed", "origin_px", "polygon_ok",
				"fallback_polygon_points", "fallback_polygon_area_px", "review_notes"]
	return ["asset_kind", "license", "generation_tool"]

func _expect_manifest_fields(
		source_plan: Dictionary,
		kind: String,
		expected_fields: Array[String],
		failures: Array[String],
) -> void:
	var fields: Array = source_plan.get("manifest_required_fields", [])
	if fields.is_empty():
		failures.append("%s source plan should expose manifest_required_fields" % kind)
	for field in expected_fields:
		if not fields.has(field):
			failures.append("%s manifest_required_fields missing %s" % [kind, field])

func _check_replacement_candidate_review(script: Variant, failures: Array[String]) -> void:
	var stable_ai: Dictionary = script.call("review_replacement_candidate", "sprite",
		"blade_idle_ai", "ai_generated", {
			"license": "project_owned_ai_generated",
			"source_url": "res://docs/asset_generation/blade_idle_ai.json",
			"generation_tool": "gpt-image",
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(32, 32),
			"expected_frame_size": Vector2(32, 32),
			"sheet_size": Vector2(128, 32),
			"columns": 4,
			"rows": 1,
			"stable_size": true,
			"fps": 8.0,
			"animation_stability_reviewed": true,
			"motion_reviewed": true,
			"origin_alignment_reviewed": true,
			"origin_px": Vector2(16, 16),
		})
	if str(stable_ai.get("release_decision", "")) != "public_ok":
		failures.append("stable AI sprite candidate should be public_ok after provenance and sheet review")
	if not bool(stable_ai.get("approved_for_public_release", false)):
		failures.append("stable AI sprite candidate should be approved for public release")
	if not Array(stable_ai.get("release_review_checklist", [])).has("frame_grid_stable"):
		failures.append("sprite candidate review should require stable frame-grid checklist")
	_expect_candidate_self_review(stable_ai, "sprite", true, failures)
	_expect_candidate_source_plan(stable_ai, "sprite", failures)
	var stable_contract: Dictionary = stable_ai.get("frame_contract", {})
	if stable_contract.get("expected_frame_size", Vector2.ZERO) != Vector2(32, 32) \
			or int(stable_contract.get("frame_count", 0)) != 4 \
			or int(stable_contract.get("grid_cell_count", 0)) != 4 \
			or float(stable_contract.get("fps", 0.0)) <= 0.0 \
			or not bool(stable_contract.get("motion_reviewed", false)) \
			or not bool(stable_contract.get("origin_alignment_reviewed", false)) \
			or stable_contract.get("origin_px", Vector2.ZERO) != Vector2(16, 16):
		failures.append("sprite candidate review should preserve expected frame contract")
	var manifest_only_ai: Dictionary = script.call("review_replacement_candidate", "sprite",
		"blade_idle_manifest_only", "ai_generated", {
			"generation_manifest": "res://docs/asset_generation/valid_ai_sprite_manifest.json",
		})
	if str(manifest_only_ai.get("release_decision", "")) != "public_ok":
		failures.append("manifest-only AI sprite candidate should pass from reviewed manifest metadata")
	if not bool(manifest_only_ai.get("manifest_reviewed", false)):
		failures.append("manifest-only AI sprite candidate should mark manifest_reviewed")
	var manifest_contract: Dictionary = manifest_only_ai.get("frame_contract", {})
	if manifest_contract.get("frame_size", Vector2.ZERO) != Vector2(16, 16) \
			or manifest_contract.get("expected_frame_size", Vector2.ZERO) != Vector2(16, 16) \
			or int(manifest_contract.get("frame_count", 0)) != 4 \
			or manifest_contract.get("sheet_size", Vector2.ZERO) != Vector2(64, 16) \
			or int(manifest_contract.get("columns", 0)) != 4 \
			or int(manifest_contract.get("rows", 0)) != 1 \
			or int(manifest_contract.get("grid_cell_count", 0)) != 4 \
			or manifest_contract.get("origin_px", Vector2.ZERO) != Vector2(8, 8):
		failures.append("manifest-only AI sprite candidate should expose manifest-derived frame contract")
	var image_path := "user://release_candidate_sheet_ok.png"
	var image := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for frame_index in 4:
		for x in range(2, 14):
			for y in range(3, 13):
				image.set_pixel(frame_index * 16 + x, y, Color(0.2, 0.4, 0.8, 1.0))
	if image.save_png(image_path) != OK:
		failures.append("release candidate image fixture should save")
	else:
		var manifest_path := "user://release_candidate_sheet_ok.json"
		var file := FileAccess.open(manifest_path, FileAccess.WRITE)
		if file == null:
			failures.append("release candidate manifest fixture should open")
		else:
			file.store_string(JSON.stringify({
				"asset_id": "release_candidate_sheet_ok",
				"asset_kind": "sprite",
				"license": "project_owned_ai_generated",
				"generation_tool": "gpt-image",
				"review_notes": "Grid is 4x1, each frame is 16x16, PNG size and origin reviewed.",
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
				"sheet_size": [64, 16],
				"columns": 4,
				"rows": 1,
			}, "\t"))
			file.close()
			var manifest_image_ai: Dictionary = script.call("review_replacement_candidate", "sprite",
				"release_candidate_sheet_ok", "ai_generated", {
					"generation_manifest": manifest_path,
				})
			if str(manifest_image_ai.get("release_decision", "")) != "public_ok":
				failures.append("manifest image AI sprite candidate should pass after PNG/grid review")
			var image_contract: Dictionary = manifest_image_ai.get("frame_contract", {})
			if image_contract.get("image_size", Vector2.ZERO) != Vector2(64, 16) \
					or int(image_contract.get("image_columns", 0)) != 4 \
					or int(image_contract.get("image_rows", 0)) != 1 \
					or int(image_contract.get("image_grid_cell_count", 0)) != 4:
				failures.append("frame contract should expose reviewed PNG grid details for release")
			if Array(image_contract.get("frame_content_bounds_px", [])).size() != 4:
				failures.append("frame contract should expose per-frame content bounds for release review")
	var stable_sheet: Dictionary = script.call("review_replacement_candidate", "sprite",
		"wizard_cast_ai", "ai_generated", {
			"license": "project_owned_ai_generated",
			"source_url": "res://docs/asset_generation/wizard_cast_ai.json",
			"generation_tool": "gpt-image",
			"frame_grid_ok": true,
			"frame_count": 6,
			"frame_size": Vector2(32, 32),
			"expected_frame_size": Vector2(32, 32),
			"sheet_size": Vector2(96, 64),
		"columns": 3,
		"rows": 2,
		"stable_size": true,
		"fps": 8.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": Vector2(8, 8),
	})
	if str(stable_sheet.get("release_decision", "")) != "public_ok":
		failures.append("stable generated sprite sheet should pass when sheet grid matches frame contract")
	var sheet_contract: Dictionary = stable_sheet.get("frame_contract", {})
	if sheet_contract.get("sheet_size", Vector2.ZERO) != Vector2(96, 64) \
			or int(sheet_contract.get("columns", 0)) != 3 \
			or int(sheet_contract.get("rows", 0)) != 2 \
			or int(sheet_contract.get("grid_cell_count", 0)) != 6:
		failures.append("sprite candidate frame contract should preserve sheet grid metadata")

	var bad_sheet: Dictionary = script.call("review_replacement_candidate", "sprite",
		"bad_ai_sheet", "ai_generated", {
			"license": "project_owned_ai_generated",
			"source_url": "res://docs/asset_generation/bad_ai_sheet.json",
			"generation_tool": "gpt-image",
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(32, 32),
			"expected_frame_size": Vector2(32, 32),
			"sheet_size": Vector2(96, 32),
			"columns": 3,
			"rows": 1,
			"stable_size": true,
			"fps": 8.0,
		})
	if str(bad_sheet.get("release_decision", "")) != "blocked":
		failures.append("generated sprite sheet should block when frame count exceeds sheet cells")
	if not Array(bad_sheet.get("issues", [])).has("frame_grid_cell_count_mismatch"):
		failures.append("generated sprite sheet should explain frame-count/sheet-cell mismatch")
	if str(bad_sheet.get("replacement_policy", "")) != "fix_frame_grid_before_release":
		failures.append("generated sprite sheet should ask for frame-grid fix before release")
	var missing_sheet_grid: Dictionary = script.call("review_replacement_candidate", "sprite",
		"missing_sheet_grid_ai", "ai_generated", {
			"license": "project_owned_ai_generated",
			"source_url": "res://docs/asset_generation/missing_sheet_grid_ai.json",
			"generation_tool": "gpt-image",
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(32, 32),
			"expected_frame_size": Vector2(32, 32),
			"stable_size": true,
			"fps": 8.0,
			"animation_stability_reviewed": true,
			"motion_reviewed": true,
		})
	if str(missing_sheet_grid.get("release_decision", "")) != "blocked":
		failures.append("multi-frame AI sprite should block until sheet grid dimensions are reviewed")
	if not Array(missing_sheet_grid.get("issues", [])).has("frame_sheet_grid_missing"):
		failures.append("multi-frame AI sprite should explain missing sheet grid review")
	var missing_sheet_contract: Dictionary = missing_sheet_grid.get("frame_contract", {})
	if int(missing_sheet_contract.get("grid_cell_count", 0)) != 0:
		failures.append("missing sheet grid candidate should expose zero reviewed grid cells")

	var placeholder_license_itch: Dictionary = script.call("review_replacement_candidate", "sprite",
		"placeholder_license_itch_slash", "free_itchio", {
			"license": "license_required",
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
	if str(placeholder_license_itch.get("release_decision", "")) != "blocked":
		failures.append("itch.io sprite candidate should block placeholder license metadata")
	if not Array(placeholder_license_itch.get("issues", [])).has("license_placeholder"):
		failures.append("itch.io sprite candidate should explain placeholder license metadata")
	if str(placeholder_license_itch.get("replacement_policy", "")) != "add_license_before_public":
		failures.append("itch.io placeholder license should ask for concrete license before public release")

	var unstable_itch: Dictionary = script.call("review_replacement_candidate", "sprite",
		"bad_itch_slash", "free_itchio", {
			"license": "CC0",
			"source_url": "https://example.itch.io/free-pack",
			"frame_grid_ok": false,
			"frame_count": 4,
			"frame_size": Vector2(32, 16),
			"expected_frame_size": Vector2(16, 16),
			"fps": 8.0,
		})
	if str(unstable_itch.get("release_decision", "")) != "blocked":
		failures.append("itch.io sprite candidate should block until frame grid and size contract are stable")
	var itch_issues: Array = unstable_itch.get("issues", [])
	if not itch_issues.has("frame_grid_not_reviewed") or not itch_issues.has("frame_size_mismatch"):
		failures.append("itch.io candidate review should explain unstable frame grid and size mismatch")
	if bool(unstable_itch.get("approved_for_public_release", true)):
		failures.append("unstable itch.io sprite candidate should not be public-release approved")
	if str(unstable_itch.get("replacement_policy", "")) != "fix_frame_grid_before_release":
		failures.append("unstable itch.io sprite candidate should ask for frame-grid fix before release")
	var untimed_itch: Dictionary = script.call("review_replacement_candidate", "sprite",
		"untimed_itch_slash", "free_itchio", {
			"license": "CC0",
			"source_url": "https://example.itch.io/free-pack",
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(16, 16),
			"expected_frame_size": Vector2(16, 16),
			"stable_size": true,
		})
	if str(untimed_itch.get("release_decision", "")) != "blocked":
		failures.append("itch.io sprite candidate should block until animation fps is reviewed")
	if not Array(untimed_itch.get("issues", [])).has("animation_fps_missing"):
		failures.append("itch.io sprite candidate should explain missing animation fps")
	if not Array(untimed_itch.get("release_self_review_blockers", [])).has("animation_fps_missing"):
		failures.append("itch.io sprite candidate should expose fps as a self-review blocker")

	var stable_vfx: Dictionary = script.call("review_replacement_candidate", "vfx",
		"dash_trail_ai", "ai_generated", {
			"license": "project_owned_ai_generated",
			"source_url": "res://docs/asset_generation/dash_trail_ai.json",
			"generation_tool": "gpt-image",
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(32, 16),
			"expected_frame_size": Vector2(32, 16),
			"sheet_size": Vector2(128, 16),
			"columns": 4,
			"rows": 1,
		"stable_size": true,
		"fps": 12.0,
		"animation_stability_reviewed": true,
		"motion_reviewed": true,
		"origin_alignment_reviewed": true,
		"origin_px": Vector2(16, 8),
		"geometry_ok": true,
		"duration": 0.22,
	})
	if str(stable_vfx.get("release_decision", "")) != "public_ok":
		failures.append("stable AI VFX candidate should pass after provenance, frame, and geometry review")
	if not bool(stable_vfx.get("approved_for_public_release", false)):
		failures.append("stable AI VFX candidate should be approved for public release")
	_expect_candidate_source_plan(stable_vfx, "vfx", failures)
	var manifest_vfx: Dictionary = script.call("review_replacement_candidate", "vfx",
		"dash_trail_manifest_ai", "ai_generated", {
			"generation_manifest": "res://docs/asset_generation/valid_ai_vfx_manifest.json",
		})
	if str(manifest_vfx.get("release_decision", "")) != "public_ok":
		failures.append("manifest-only VFX should pass after manifest frame/geometry/duration review")
	if not bool(manifest_vfx.get("manifest_reviewed", false)):
		failures.append("manifest-only VFX should mark manifest_reviewed")
	var manifest_vfx_frame: Dictionary = manifest_vfx.get("frame_contract", {})
	if manifest_vfx_frame.get("frame_size", Vector2.ZERO) != Vector2(32, 16) \
			or int(manifest_vfx_frame.get("frame_count", 0)) != 4 \
			or int(manifest_vfx_frame.get("grid_cell_count", 0)) != 4:
		failures.append("manifest-only VFX should expose manifest-derived frame contract")
	var bad_vfx: Dictionary = script.call("review_replacement_candidate", "vfx",
		"bad_itch_dash_trail", "free_itchio", {
			"license": "CC0",
			"source_url": "https://example.itch.io/free-vfx-pack",
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(32, 16),
			"expected_frame_size": Vector2(32, 16),
			"fps": 12.0,
		})
	if str(bad_vfx.get("release_decision", "")) != "blocked":
		failures.append("itch.io VFX candidate should block until geometry and duration are reviewed")
	var bad_vfx_issues: Array = bad_vfx.get("issues", [])
	if not bad_vfx_issues.has("vfx_geometry_not_reviewed") \
			or not bad_vfx_issues.has("vfx_duration_missing"):
		failures.append("itch.io VFX candidate should explain missing geometry/duration review")
	if str(bad_vfx.get("replacement_policy", "")) != "fix_vfx_geometry_before_release":
		failures.append("itch.io VFX candidate should ask for geometry/duration fix before release")

	var stable_audio: Dictionary = script.call("review_replacement_candidate", "audio",
		"blade_cast_ai", "ai_generated", {
			"license": "project_owned_ai_generated",
			"source_url": "res://docs/asset_generation/blade_cast_ai.json",
			"generation_tool": "gpt-audio",
			"waveform_ok": true,
			"duration": 0.08,
		})
	if str(stable_audio.get("release_decision", "")) != "public_ok":
		failures.append("stable AI audio candidate should pass after provenance and waveform review")
	if not bool(stable_audio.get("approved_for_public_release", false)):
		failures.append("stable AI audio candidate should be approved for public release")
	_expect_candidate_source_plan(stable_audio, "audio", failures)
	var audio_contract: Dictionary = stable_audio.get("audio_contract", {})
	if not bool(audio_contract.get("waveform_ok", false)) \
			or float(audio_contract.get("duration", 0.0)) <= 0.0:
		failures.append("audio candidate review should preserve waveform/duration contract")
	var manifest_audio: Dictionary = script.call("review_replacement_candidate", "audio",
		"blade_cast_manifest_ai", "ai_generated", {
			"generation_manifest": "res://docs/asset_generation/valid_ai_audio_manifest.json",
		})
	if str(manifest_audio.get("release_decision", "")) != "public_ok":
		failures.append("manifest-only audio should pass after manifest waveform/duration review")
	if not bool(manifest_audio.get("manifest_reviewed", false)):
		failures.append("manifest-only audio should mark manifest_reviewed")
	var manifest_audio_contract: Dictionary = manifest_audio.get("audio_contract", {})
	if not bool(manifest_audio_contract.get("waveform_ok", false)) \
			or float(manifest_audio_contract.get("duration", 0.0)) <= 0.0:
		failures.append("manifest-only audio should expose manifest-derived waveform/duration contract")
	var bad_audio: Dictionary = script.call("review_replacement_candidate", "audio",
		"bad_itch_hit", "free_itchio", {
			"license": "CC0",
			"source_url": "https://example.itch.io/free-sfx-pack",
		})
	if str(bad_audio.get("release_decision", "")) != "blocked":
		failures.append("itch.io audio candidate should block until waveform and duration are reviewed")
	var bad_audio_issues: Array = bad_audio.get("issues", [])
	if not bad_audio_issues.has("audio_waveform_not_reviewed") \
			or not bad_audio_issues.has("audio_duration_missing"):
		failures.append("itch.io audio candidate should explain missing waveform/duration review")
	if str(bad_audio.get("replacement_policy", "")) != "fix_waveform_before_release":
		failures.append("itch.io audio candidate should ask for waveform fix before release")

	var weak_polygon: Dictionary = script.call("review_replacement_candidate", "collision",
		"player_body_polygon", "project_owned_collision_polygon", {
			"shape_ok": true,
			"polygon_ok": false,
			"polygon_points": 2,
		})
	if str(weak_polygon.get("release_decision", "")) != "blocked":
		failures.append("collision candidate should block when polygon has fewer than 3 points")
	if not Array(weak_polygon.get("issues", [])).has("collision_polygon_not_reviewed"):
		failures.append("collision candidate review should explain missing polygon review")
	var polygon_contract: Dictionary = weak_polygon.get("collision_contract", {})
	if int(polygon_contract.get("polygon_points", 0)) != 2:
		failures.append("collision candidate review should preserve polygon point count")
	if str(weak_polygon.get("replacement_policy", "")) != "fix_collision_polygon_before_public":
		failures.append("collision candidate should ask for polygon fix before public release")
	var ai_polygon: Dictionary = script.call("review_replacement_candidate", "collision",
		"trap_room_polygon_ai", "ai_generated", {
			"license": "project_owned_ai_generated",
			"source_url": "res://docs/asset_generation/trap_room_polygon_ai.json",
			"generation_tool": "gpt-image",
			"shape_ok": true,
			"polygon_ok": true,
			"polygon_points": 5,
			"polygon_area_px": 96.0,
		})
	if str(ai_polygon.get("release_decision", "")) != "public_ok":
		failures.append("AI polygon candidate should pass after provenance and polygon review")
	if not bool(ai_polygon.get("approved_for_public_release", false)):
		failures.append("AI polygon candidate should be approved after polygon review")
	_expect_candidate_source_plan(ai_polygon, "collision", failures)
	var ai_polygon_contract: Dictionary = ai_polygon.get("collision_contract", {})
	if float(ai_polygon_contract.get("polygon_area_px", 0.0)) <= 0.0:
		failures.append("AI polygon candidate should preserve reviewed polygon area")
	if not Array(ai_polygon.get("allowed_replacement_sources", [])).has("free_itchio") \
			or not Array(ai_polygon.get("allowed_replacement_sources", [])).has("ai_generated"):
		failures.append("collision candidate should list free itch.io and AI as legal replacement sources")
	var ai_polygon_gate: Array = ai_polygon.get("acceptance_gate", [])
	if not ai_polygon_gate.has("license_or_ownership_metadata") \
			or not ai_polygon_gate.has("source_url_or_generation_manifest"):
		failures.append("AI/free collision candidates should require provenance metadata")
	var flat_polygon: Dictionary = script.call("review_replacement_candidate", "collision",
		"flat_polygon_ai", "ai_generated", {
			"license": "project_owned_ai_generated",
			"source_url": "res://docs/asset_generation/flat_polygon_ai.json",
			"generation_tool": "gpt-image",
			"shape_ok": true,
			"polygon_ok": true,
			"polygon_points": 5,
			"polygon_area_px": 0.0,
		})
	if str(flat_polygon.get("release_decision", "")) != "blocked":
		failures.append("AI collision polygon should block when reviewed area is zero")
	if not Array(flat_polygon.get("issues", [])).has("collision_polygon_area_not_reviewed"):
		failures.append("AI collision polygon should explain missing polygon area review")
	var itch_polygon: Dictionary = script.call("review_replacement_candidate", "collision",
		"trap_room_polygon_itch", "free_itchio", {
			"license": "CC0",
			"source_url": "https://example.itch.io/free-collision-pack",
			"shape_ok": true,
			"polygon_ok": false,
			"polygon_points": 2,
		})
	if str(itch_polygon.get("release_decision", "")) != "blocked":
		failures.append("itch.io polygon candidate should block until polygon points are reviewed")
	if not Array(itch_polygon.get("issues", [])).has("collision_polygon_not_reviewed"):
		failures.append("itch.io polygon candidate should explain missing polygon review")
	if str(itch_polygon.get("replacement_policy", "")) != "fix_collision_polygon_before_public":
		failures.append("itch.io polygon candidate should ask for polygon fix before public release")

	var stable_object_visual: Dictionary = script.call("review_replacement_candidate",
		"object_visual", "trap_spike_ai", "ai_generated", {
			"license": "project_owned_ai_generated",
			"source_url": "res://docs/asset_generation/trap_spike_ai.json",
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
		"fallback_polygon_points": 5,
		"fallback_polygon_area_px": 128.0,
		"polygon_ok": true,
	})
	if str(stable_object_visual.get("release_decision", "")) != "public_ok":
		failures.append("stable AI object visual should pass after provenance, frame, and polygon review")
	if not bool(stable_object_visual.get("approved_for_public_release", false)):
		failures.append("stable AI object visual should be approved for public release")
	_expect_candidate_self_review(stable_object_visual, "object_visual", true, failures)
	_expect_candidate_source_plan(stable_object_visual, "object_visual", failures)
	var object_contract: Dictionary = stable_object_visual.get("object_visual_contract", {})
	if not bool(object_contract.get("runtime_object_sprite_ok", false)) \
			or not bool(object_contract.get("polygon_ok", false)) \
			or int(object_contract.get("fallback_polygon_points", 0)) != 5 \
			or float(object_contract.get("fallback_polygon_area_px", 0.0)) <= 0.0:
		failures.append("object visual candidate review should preserve sprite/polygon contract")
	if not Array(stable_object_visual.get("acceptance_gate", [])).has("fallback_polygon_points"):
		failures.append("object visual candidate should require fallback polygon acceptance")
	var manifest_object_visual: Dictionary = script.call("review_replacement_candidate",
		"object_visual", "trap_spike_manifest_ai", "ai_generated", {
			"generation_manifest": "res://docs/asset_generation/valid_ai_object_visual_manifest.json",
		})
	if str(manifest_object_visual.get("release_decision", "")) != "public_ok":
		failures.append("manifest-only object visual should pass after manifest sprite/frame/polygon review")
	if not bool(manifest_object_visual.get("manifest_reviewed", false)):
		failures.append("manifest-only object visual should mark manifest_reviewed")
	var manifest_object_contract: Dictionary = manifest_object_visual.get("object_visual_contract", {})
	if not bool(manifest_object_contract.get("runtime_object_sprite_ok", false)) \
			or not bool(manifest_object_contract.get("polygon_ok", false)) \
			or int(manifest_object_contract.get("fallback_polygon_points", 0)) != 5 \
			or float(manifest_object_contract.get("fallback_polygon_area_px", 0.0)) <= 0.0:
		failures.append("manifest-only object visual should expose manifest-derived sprite/polygon contract")
	var manifest_object_frame: Dictionary = manifest_object_visual.get("frame_contract", {})
	if manifest_object_frame.get("frame_size", Vector2.ZERO) != Vector2(32, 32) \
			or int(manifest_object_frame.get("frame_count", 0)) != 4 \
			or int(manifest_object_frame.get("grid_cell_count", 0)) != 4 \
			or manifest_object_frame.get("origin_px", Vector2.ZERO) != Vector2(16, 16):
		failures.append("manifest-only object visual should expose manifest-derived frame contract")
	var flat_object_visual: Dictionary = script.call("review_replacement_candidate",
		"object_visual", "flat_object_ai", "ai_generated", {
			"license": "project_owned_ai_generated",
			"source_url": "res://docs/asset_generation/flat_object_ai.json",
			"generation_tool": "gpt-image",
			"runtime_object_sprite_ok": true,
			"frame_grid_ok": true,
			"frame_count": 4,
			"frame_size": Vector2(32, 32),
			"expected_frame_size": Vector2(32, 32),
			"stable_size": true,
			"fps": 8.0,
			"animation_stability_reviewed": true,
			"motion_reviewed": true,
			"origin_alignment_reviewed": true,
			"origin_px": Vector2(16, 16),
			"fallback_polygon_points": 5,
			"fallback_polygon_area_px": 0.0,
			"polygon_ok": true,
		})
	if str(flat_object_visual.get("release_decision", "")) != "blocked":
		failures.append("AI object visual should block when fallback polygon area is zero")
	if not Array(flat_object_visual.get("issues", [])).has("fallback_polygon_area_not_reviewed"):
		failures.append("AI object visual should explain missing fallback polygon area review")

	var bad_object_visual: Dictionary = script.call("review_replacement_candidate",
		"object_visual", "broken_trap_itch", "free_itchio", {
			"license": "CC0",
			"source_url": "https://example.itch.io/free-dungeon-object-pack",
			"runtime_object_sprite_ok": false,
			"frame_grid_ok": false,
			"frame_count": 4,
			"frame_size": Vector2(32, 32),
			"expected_frame_size": Vector2(32, 32),
			"stable_size": false,
			"fallback_polygon_points": 2,
			"polygon_ok": false,
		})
	if str(bad_object_visual.get("release_decision", "")) != "blocked":
		failures.append("itch.io object visual should block until sprite, frame, and polygon review pass")
	var object_issues: Array = bad_object_visual.get("issues", [])
	if not object_issues.has("runtime_object_sprite_not_reviewed") \
			or not object_issues.has("frame_grid_not_reviewed") \
			or not object_issues.has("fallback_polygon_not_reviewed"):
		failures.append("object visual candidate should explain missing sprite/frame/polygon review")
	if str(bad_object_visual.get("replacement_policy", "")) != "fix_runtime_object_polygon_before_public":
		failures.append("object visual candidate should ask for polygon fix before public release")
	if bool(bad_object_visual.get("approved_for_public_release", true)):
		failures.append("unstable object visual candidate should not be public-release approved")
	var object_blockers: Array = bad_object_visual.get("release_self_review_blockers", [])
	if not object_blockers.has("runtime_object_sprite_not_reviewed") \
			or not object_blockers.has("fallback_polygon_not_reviewed"):
		failures.append("object visual candidate should expose sprite/polygon self-review blockers")
	_expect_candidate_self_review(bad_object_visual, "object_visual", false, failures)

	var fan_reference: Dictionary = script.call("review_replacement_candidate", "sprite",
		"soul_knight_reference", "fanmade_reference_only", {
			"source_url": "https://github.com/CalvinWan0101/soul-knight",
		})
	if str(fan_reference.get("release_decision", "")) != "reference_only":
		failures.append("fanmade source candidate should stay reference_only")
	if bool(fan_reference.get("approved_for_public_release", true)):
		failures.append("fanmade reference candidate should never be approved as runtime release art")
	if bool(fan_reference.get("usable_runtime_asset", true)):
		failures.append("fanmade reference candidate should not be usable runtime asset")
	var fan_blockers: Array = fan_reference.get("release_self_review_blockers", [])
	if not fan_blockers.has("release_decision:reference_only") \
			or not fan_blockers.has("runtime_asset_not_usable"):
		failures.append("fanmade reference candidate should expose why it cannot become runtime release art")

func _check_release_candidate_summary(script: Variant, failures: Array[String]) -> void:
	var candidate: Dictionary = script.call("release_candidate_summary")
	if not bool(candidate.get("code_gate_ready", false)):
		failures.append("release candidate summary should expose ready code release gate")
	if not script.has_method("release_asset_self_review"):
		failures.append("ReleaseAudit should expose release_asset_self_review for headless asset contract review")
	if not candidate.has("export_preset_ready"):
		failures.append("release candidate summary should expose export preset readiness")
	if str(candidate.get("export_preset_name", "")) != "Windows Desktop":
		failures.append("release candidate summary should use the Windows Desktop export preset")
	if str(candidate.get("export_path", "")).find("build/windows") < 0:
		failures.append("release candidate summary should expose the Windows export path")
	if not FileAccess.file_exists("res://export_presets.cfg"):
		failures.append("release candidate should keep export_presets.cfg in the project")
	var gitignore := FileAccess.get_file_as_string("res://.gitignore")
	var ignores_build_output := false
	for raw_ignore in gitignore.split("\n"):
		var ignore_rule := str(raw_ignore).strip_edges()
		if ignore_rule == "export_presets.cfg":
			failures.append("release candidate export preset should be versioned, not ignored")
		if ["build/", "/build/", "build/windows/", "/build/windows/"].has(ignore_rule):
			ignores_build_output = true
	if not ignores_build_output:
		failures.append("release candidate should ignore local packaged build output")
	var preset_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	if not preset_text.contains("assets/dungeon_tileset/tile_list_v1.7"):
		failures.append("release candidate export preset should include the extensionless 0x72 tile list")
	if bool(candidate.get("release_candidate_ready", true)):
		failures.append("release candidate summary should require smoke and playtest evidence")
	var blockers: Array = candidate.get("blockers", [])
	for blocker in [
		"full_smoke_suite_missing",
		"playtest_notes_missing",
		"manual_scenarios_missing",
		"scenario_rehearsal_missing",
		"asset_self_review_missing",
		"export_package_missing",
	]:
		if not blockers.has(blocker):
			failures.append("release candidate summary should block without %s" % blocker)
	var required_fields: Array = candidate.get("required_playtest_fields", [])
	for field_id in ["seed", "class_id", "mode", "asset_animation_notes",
			"polygon_collision_notes", "wave_hud_audio_notes", "release_decision"]:
		if not required_fields.has(field_id):
			failures.append("release candidate summary missing required playtest field %s" % field_id)
	if str(candidate.get("next_action", "")).find("Record playtest notes") < 0:
		failures.append("release candidate summary should name the next missing evidence action")
	if str(candidate.get("next_action", "")).find("wave/HUD/audio") < 0:
		failures.append("release candidate summary should name wave/HUD/audio notes in next action")
	if not script.has_method("release_candidate_manual_recording_plan"):
		failures.append("ReleaseAudit should expose release_candidate_manual_recording_plan")
	else:
		var empty_plan: Dictionary = script.call("release_candidate_manual_recording_plan")
		if bool(empty_plan.get("playtest_notes_ready", true)):
			failures.append("manual recording plan should show missing playtest notes")
		if int(empty_plan.get("missing_manual_scenario_count", 0)) != 6:
			failures.append("manual recording plan should show all six missing manual scenarios")
		var plan_commands: Dictionary = empty_plan.get("commands", {})
		if not str(plan_commands.get("playtest_notes", "")).contains(
				"record_playtest_notes_evidence.gd"):
			failures.append("manual recording plan should include playtest notes recorder command")
		if not str(empty_plan.get("next_missing_manual_launch_command", "")).contains(
				"ScenarioIndex 1"):
			failures.append("manual recording plan should expose the next missing scenario launch command")
		if not str(empty_plan.get("next_missing_manual_launch_command", "")).contains(
				"-Detached"):
			failures.append("manual recording plan should launch visible scenarios detached")
		if not str(empty_plan.get("next_missing_manual_launch_dry_run_command", "")).contains(
				"-DryRun"):
			failures.append("manual recording plan should expose launcher dry-run command")
		if not str(empty_plan.get("next_missing_manual_dry_run_command", "")).contains(
				"--dry-run=true"):
			failures.append("manual recording plan should expose the next missing scenario dry-run command")
		var status_tool := FileAccess.get_file_as_string(
			"res://scripts/tools/release_candidate_status.gd")
		if not status_tool.contains("next_missing_manual_launch_command"):
			failures.append("release candidate status should print the next missing manual launch command")
		var scenario_statuses: Array = empty_plan.get("scenario_statuses", [])
		if scenario_statuses.size() != 6:
			failures.append("manual recording plan should list six scenario statuses")
		elif str(Dictionary(scenario_statuses[0]).get("status", "")) != "missing":
			failures.append("manual recording plan should mark unrecorded scenario missing")
		elif not str(Dictionary(scenario_statuses[0]).get("command", "")).contains(
				"--confirm-human-playtest=true"):
			failures.append("manual scenario command should require human confirmation")
		elif str(Dictionary(scenario_statuses[0]).get("command", "")).contains(
				"headless_rehearsal"):
			failures.append("manual scenario command should not suggest headless evidence")
		elif not str(Dictionary(scenario_statuses[0]).get("launch_command", "")).contains(
				"ScenarioIndex 1"):
			failures.append("manual recording plan should include scenario launch command")
		elif not str(Dictionary(scenario_statuses[0]).get("launch_command", "")).contains(
				"launch_manual_scenario.ps1"):
			failures.append("manual recording plan should use the manual scenario launcher script")
		elif not str(Dictionary(scenario_statuses[0]).get("launch_command", "")).contains(
				"-Detached"):
			failures.append("manual scenario launch command should detach visible Godot")
		elif not str(Dictionary(scenario_statuses[0]).get("launch_dry_run_command", "")).contains(
				"-ScenarioIndex 1 -Detached -DryRun"):
			failures.append("manual recording plan should include scenario launcher dry-run command")
	var launcher_path := "res://scripts/tools/launch_manual_scenario.ps1"
	if not FileAccess.file_exists(launcher_path):
		failures.append("release workflow should include a manual scenario launcher script")
	else:
		var launcher_source := FileAccess.get_file_as_string(launcher_path)
		for token in ["manual-scenario", "scenario-index", "Godot_v4.7-stable_win64_console.exe",
				"release_candidate_status.gd", "Manual Scenario Checklist",
				"Wave/HUD/Audio", "wave_hud_audio_notes",
				"asset_animation_notes", "polygon_collision_notes",
				"record_manual_scenario_evidence.gd", "-List", "Manual Scenarios",
				"No Godot window launched"]:
			if not launcher_source.contains(token):
				failures.append("manual scenario launcher missing token: %s" % token)

	var notes := {}
	for field in required_fields:
		notes[str(field)] = _release_candidate_note_value(str(field))
	var manual: Dictionary = script.call("manual_playtest_checklist")
	var unpackaged_candidate: Dictionary = script.call("release_candidate_summary", {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": notes,
		"manual_scenario_results": Array(manual.get("scenario_runs", [])).duplicate(true),
		"headless_scenario_rehearsal": script.call("release_candidate_rehearsal_results"),
	})
	if bool(unpackaged_candidate.get("release_candidate_ready", true)):
		failures.append("release candidate summary should require successful export package evidence")
	if bool(unpackaged_candidate.get("export_package_ready", false)):
		failures.append("release candidate summary should not accept preset-only package evidence")
	if not Array(unpackaged_candidate.get("blockers", [])).has("export_package_missing"):
		failures.append("release candidate summary should explain missing export package evidence")
	var thin_candidate: Dictionary = script.call("release_candidate_summary", {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": notes,
		"manual_scenario_results": Array(manual.get("scenario_runs", [])).duplicate(true),
		"headless_scenario_rehearsal": script.call("release_candidate_rehearsal_results"),
		"asset_self_review": _release_candidate_asset_self_review(),
		"export_package": {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		},
	})
	if bool(thin_candidate.get("manual_scenarios_ready", true)):
		failures.append("release candidate summary should reject scenario evidence without result notes")
	if not Array(thin_candidate.get("blockers", [])).has("manual_scenarios_missing"):
		failures.append("release candidate summary should keep manual_scenarios_missing for thin scenario evidence")
	var headless_as_manual_candidate: Dictionary = script.call("release_candidate_summary", {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": notes,
		"manual_scenario_results": _release_candidate_completed_scenarios(
			Array(manual.get("scenario_runs", [])), "headless_rehearsal"),
		"headless_scenario_rehearsal": script.call("release_candidate_rehearsal_results"),
		"asset_self_review": _release_candidate_asset_self_review(),
		"export_package": {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		},
	})
	if bool(headless_as_manual_candidate.get("manual_scenarios_ready", true)):
		failures.append("release candidate summary should reject headless evidence as manual scenario evidence")
	if not Array(headless_as_manual_candidate.get("blockers", [])).has("manual_scenarios_missing"):
		failures.append("release candidate summary should keep manual blocker for headless manual evidence")
	var pending_manual_candidate: Dictionary = script.call("release_candidate_summary", {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": notes,
		"manual_scenario_results": _release_candidate_completed_scenarios(
			Array(manual.get("scenario_runs", [])), "manual_playtest", "pending"),
		"headless_scenario_rehearsal": script.call("release_candidate_rehearsal_results"),
		"asset_self_review": _release_candidate_asset_self_review(),
		"export_package": {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		},
	})
	if bool(pending_manual_candidate.get("manual_scenarios_ready", true)):
		failures.append("release candidate summary should reject pending manual scenario evidence")
	if not Array(pending_manual_candidate.get("blockers", [])).has("manual_scenarios_missing"):
		failures.append("release candidate summary should keep manual blocker for pending scenario evidence")
	var missing_screenshot_manual_candidate: Dictionary = script.call("release_candidate_summary", {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": notes,
		"manual_scenario_results": _release_candidate_completed_scenarios(
			Array(manual.get("scenario_runs", [])), "manual_playtest", "pass", false),
		"headless_scenario_rehearsal": script.call("release_candidate_rehearsal_results"),
		"asset_self_review": _release_candidate_asset_self_review(),
		"export_package": {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		},
	})
	if bool(missing_screenshot_manual_candidate.get("manual_scenarios_ready", true)):
		failures.append("release candidate summary should reject manual scenario evidence without screenshot/seed")
	if not Array(missing_screenshot_manual_candidate.get("blockers", [])).has(
			"manual_scenarios_missing"):
		failures.append("release candidate summary should keep manual blocker for missing screenshot/seed evidence")
	var placeholder_notes_manual_candidate: Dictionary = script.call("release_candidate_summary", {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": notes,
		"manual_scenario_results": _release_candidate_completed_scenarios(
			Array(manual.get("scenario_runs", [])), "manual_playtest", "pass", true,
			"<human notes>"),
		"headless_scenario_rehearsal": script.call("release_candidate_rehearsal_results"),
		"asset_self_review": _release_candidate_asset_self_review(),
		"export_package": {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		},
	})
	if bool(placeholder_notes_manual_candidate.get("manual_scenarios_ready", true)):
		failures.append("release candidate summary should reject manual scenario placeholder notes")
	if not Array(placeholder_notes_manual_candidate.get("blockers", [])).has(
			"manual_scenarios_missing"):
		failures.append("release candidate summary should keep manual blocker for placeholder scenario notes")
	var duplicate_manual_candidate: Dictionary = script.call("release_candidate_summary", {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": notes,
		"manual_scenario_results": _release_candidate_duplicate_scenarios(
			Array(manual.get("scenario_runs", []))),
		"headless_scenario_rehearsal": script.call("release_candidate_rehearsal_results"),
		"asset_self_review": _release_candidate_asset_self_review(),
		"export_package": {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		},
	})
	if bool(duplicate_manual_candidate.get("manual_scenarios_ready", true)):
		failures.append("release candidate summary should require each manual checklist scenario, not just six results")
	if int(duplicate_manual_candidate.get("manual_scenario_count", 0)) >= int(
			duplicate_manual_candidate.get("required_manual_scenario_count", 0)):
		failures.append("release candidate summary should count unique required manual scenarios")
	var unreviewed_candidate: Dictionary = script.call("release_candidate_summary", {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": notes,
		"manual_scenario_results": _release_candidate_completed_scenarios(
			Array(manual.get("scenario_runs", []))),
		"headless_scenario_rehearsal": script.call("release_candidate_rehearsal_results"),
		"export_package": {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		},
	})
	if bool(unreviewed_candidate.get("release_candidate_ready", true)):
		failures.append("release candidate summary should require asset self-review evidence")
	if not Array(unreviewed_candidate.get("blockers", [])).has("asset_self_review_missing"):
		failures.append("release candidate summary should explain missing asset self-review evidence")
	var zero_count_asset_review := _release_candidate_asset_self_review()
	zero_count_asset_review["animation_frame_grid_checked_count"] = 0
	zero_count_asset_review["collision_polygon_checked_count"] = 0
	zero_count_asset_review["object_visual_checked_count"] = 0
	var zero_count_candidate: Dictionary = script.call("release_candidate_summary", {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": notes,
		"manual_scenario_results": _release_candidate_completed_scenarios(
			Array(manual.get("scenario_runs", []))),
		"headless_scenario_rehearsal": script.call("release_candidate_rehearsal_results"),
		"asset_self_review": zero_count_asset_review,
		"export_package": {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		},
	})
	if bool(zero_count_candidate.get("asset_self_review_ready", true)):
		failures.append("release candidate summary should reject asset review with zero frame/polygon coverage")
	var missing_asset_review_fields: Array = zero_count_candidate.get(
		"missing_asset_self_review_fields", [])
	for field_id in ["animation_frame_grid_checked_count", "collision_polygon_checked_count",
			"object_visual_checked_count"]:
		if not missing_asset_review_fields.has(field_id):
			failures.append("release candidate asset review should require coverage field %s" % field_id)
	var ready_candidate: Dictionary = script.call("release_candidate_summary", {
		"full_smoke_suite": {"passed": true, "count": 74},
		"playtest_notes": notes,
		"manual_scenario_results": _release_candidate_completed_scenarios(
			Array(manual.get("scenario_runs", []))),
		"headless_scenario_rehearsal": script.call("release_candidate_rehearsal_results"),
		"asset_self_review": _release_candidate_asset_self_review(),
		"export_package": {
			"passed": true,
			"booted": true,
			"preset_name": "Windows Desktop",
			"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
		},
	})
	if not bool(ready_candidate.get("release_candidate_ready", false)):
		failures.append("release candidate summary should pass when smoke, notes, scenarios, package, asset review, and code gate pass")
	if not bool(ready_candidate.get("asset_self_review_ready", false)):
		failures.append("release candidate summary should accept complete asset self-review evidence")
	if not bool(ready_candidate.get("smoke_suite_ready", false)):
		failures.append("release candidate summary should accept full smoke evidence")
	if not bool(ready_candidate.get("playtest_notes_ready", false)):
		failures.append("release candidate summary should accept complete playtest notes")
	if not bool(ready_candidate.get("manual_scenarios_ready", false)):
		failures.append("release candidate summary should accept completed scenario evidence")
	if not bool(ready_candidate.get("scenario_rehearsal_ready", false)):
		failures.append("release candidate summary should accept headless scenario rehearsal evidence")
	if not bool(ready_candidate.get("export_preset_ready", false)):
		failures.append("release candidate summary should require a valid export preset")
	if not bool(ready_candidate.get("export_package_ready", false)):
		failures.append("release candidate summary should accept packaged build evidence")
	if str(ready_candidate.get("export_package_path", "")) == "":
		failures.append("release candidate summary should expose packaged build path")
	if not Array(ready_candidate.get("blockers", [])).is_empty():
		failures.append("ready release candidate summary should not keep blockers")
	if str(ready_candidate.get("next_action", "")).find("Release review") < 0:
		failures.append("ready release candidate summary should move to release review")
	if script.has_method("release_candidate_manual_recording_plan"):
		var ready_plan: Dictionary = script.call("release_candidate_manual_recording_plan", {
			"full_smoke_suite": {"passed": true, "count": 74},
			"playtest_notes": notes,
			"manual_scenario_results": _release_candidate_completed_scenarios(
				Array(manual.get("scenario_runs", []))),
			"headless_scenario_rehearsal": script.call("release_candidate_rehearsal_results"),
			"asset_self_review": _release_candidate_asset_self_review(),
			"export_package": {
				"passed": true,
				"booted": true,
				"preset_name": "Windows Desktop",
				"executable_path": "build/windows/DungeonCoreElementalRebirth.exe",
			},
		})
		if not bool(ready_plan.get("playtest_notes_ready", false)):
			failures.append("manual recording plan should mark notes ready when present")
		if int(ready_plan.get("missing_manual_scenario_count", -1)) != 0:
			failures.append("manual recording plan should show no missing scenarios when all are recorded")
		for raw_status in Array(ready_plan.get("scenario_statuses", [])):
			if raw_status is Dictionary and str((raw_status as Dictionary).get("status", "")) != "recorded":
				failures.append("manual recording plan should mark completed scenarios recorded")
				break

func _release_candidate_asset_self_review() -> Dictionary:
	return {
		"passed": true,
		"review_type": "headless_asset_contract_review",
		"animation_reviewed": true,
		"polygon_reviewed": true,
		"motion_reviewed": true,
		"origin_reviewed": true,
		"source_policy_ok": true,
		"no_direct_fanmade_copy": true,
		"animation_frame_grid_checked_count": 12,
		"collision_polygon_checked_count": 2,
		"object_visual_checked_count": 8,
		"notes": "headless audit checked frame grid, motion/origin metadata, collision polygons, and source policy",
	}

func _release_candidate_note_value(field_id: String) -> Variant:
	match field_id:
		"seed":
			return 420101
		"class_id":
			return "blade_warden"
		"mode":
			return "normal"
		"replay_last_run_result":
			return "same seed/class/mode verified"
		"daily_fingerprint_hash":
			return "daily-420101-ok"
		"pace_avg_sec":
			return 42.0
		"pace_boss_sec":
			return 85.0
		"asset_animation_notes":
			return "idle/run/dash/attack frames stable"
		"polygon_collision_notes":
			return "sprite silhouettes match runtime collision polygons"
		"wave_hud_audio_notes":
			return "wave counter, enemies left, and wave cues verified"
		"blocker_screenshot_or_seed":
			return "none"
		"release_decision":
			return "public_ok"
	return "ok"

func _release_candidate_completed_scenarios(
		scenarios: Array,
		evidence_source: String = "manual_playtest",
		result: String = "pass",
		include_screenshot_or_seed: bool = true,
		notes: String = "objective completed; animation stable, polygon collision fair, wave HUD audio clear",
) -> Array:
	var out: Array = []
	for raw in scenarios:
		if not (raw is Dictionary):
			continue
		var scenario: Dictionary = raw
		var result_data := {
			"seed": int(scenario.get("seed", 0)),
			"mode": str(scenario.get("mode", "")),
			"class_id": str(scenario.get("class_id", "")),
			"goal": str(scenario.get("goal", "")),
			"result": result,
			"evidence_source": evidence_source,
			"notes": notes,
		}
		if include_screenshot_or_seed:
			result_data["screenshot_or_seed"] = "seed_%d_manual_pass" % int(
				scenario.get("seed", 0))
		out.append(result_data)
	return out

func _release_candidate_duplicate_scenarios(scenarios: Array) -> Array:
	if scenarios.is_empty() or not (scenarios[0] is Dictionary):
		return []
	var first: Dictionary = scenarios[0]
	var out: Array = []
	for _i in range(scenarios.size()):
		out.append({
			"seed": int(first.get("seed", 0)),
			"mode": str(first.get("mode", "")),
			"class_id": str(first.get("class_id", "")),
			"goal": str(first.get("goal", "")),
			"result": "pass",
			"evidence_source": "manual_playtest",
			"notes": "same scenario repeated; should not satisfy full manual checklist",
		})
	return out

func _expect_candidate_self_review(
		candidate: Dictionary,
		kind: String,
		should_pass: bool,
		failures: Array[String],
) -> void:
	if bool(candidate.get("release_self_review_ok", false)) != should_pass:
		failures.append("%s candidate should expose release_self_review_ok=%s" % [
			kind, str(should_pass),
		])
	var expected_status := "ready" if should_pass else "blocked"
	if str(candidate.get("release_self_review_status", "")) != expected_status:
		failures.append("%s candidate should expose release_self_review_status=%s" % [
			kind, expected_status,
		])
	var blockers: Array = candidate.get("release_self_review_blockers", [])
	if should_pass and not blockers.is_empty():
		failures.append("%s approved candidate should not keep self-review blockers" % kind)
	if not should_pass and blockers.is_empty():
		failures.append("%s blocked candidate should expose self-review blockers" % kind)
	var gate: Array = candidate.get("release_self_review_gate", [])
	if not gate.has("no_direct_fanmade_copy"):
		failures.append("%s candidate self-review gate should forbid direct fanmade copies" % kind)
	if ["sprite", "vfx", "object_visual"].has(kind):
		for required in ["frame_grid_ok", "expected_frame_size", "fps_reviewed",
				"animation_stability_reviewed", "motion_reviewed",
				"origin_alignment_reviewed", "origin_px"]:
			if not gate.has(required):
				failures.append("%s candidate self-review gate missing %s" % [kind, required])
	if kind == "object_visual" and not gate.has("fallback_polygon_points"):
		failures.append("object visual candidate self-review gate should include fallback polygon points")
	if kind == "object_visual" and not gate.has("fallback_polygon_area_px"):
		failures.append("object visual candidate self-review gate should include fallback polygon area")

func _expect_candidate_source_plan(candidate: Dictionary, kind: String, failures: Array[String]) -> void:
	var source_plan: Dictionary = candidate.get("source_plan", {})
	if source_plan.is_empty():
		failures.append("%s candidate review should expose source_plan" % kind)
		return
	if str(source_plan.get("fanmade_policy", "")) != "reference_only_pattern_study":
		failures.append("%s candidate source_plan should keep fanmade repos reference-only" % kind)
	if Array(source_plan.get("preferred_sources", [])).is_empty():
		failures.append("%s candidate source_plan should list preferred legal sources" % kind)
	if not Array(source_plan.get("approval_gate", [])).has("no_direct_fanmade_copy"):
		failures.append("%s candidate source_plan should require no direct fanmade copy" % kind)
	_expect_missing_asset_strategy(source_plan, kind, failures)
	_expect_source_priority(source_plan, kind, failures)
	_expect_manifest_fields(source_plan, kind, _expected_manifest_fields(kind), failures)

func _expect_missing_asset_strategy(
		source_plan: Dictionary,
		kind: String,
		failures: Array[String],
) -> void:
	var strategy: Dictionary = source_plan.get("missing_asset_strategy", {})
	if strategy.is_empty():
		failures.append("%s source plan should expose missing_asset_strategy" % kind)
		return
	var runtime_sources: Array = strategy.get("runtime_source_priority", [])
	if runtime_sources != source_plan.get("source_priority", []):
		failures.append("%s missing asset strategy should mirror runtime source priority" % kind)
	if runtime_sources.has("fanmade_direct_copy") or runtime_sources.has("fanmade_reference_only"):
		failures.append("%s missing asset strategy should keep fanmade sources out of runtime priority" % kind)
	var reference_sources: Array = strategy.get("reference_pattern_sources", [])
	if not reference_sources.has("CalvinWan0101/soul-knight") \
			or not reference_sources.has("leoyin1127/Soul-knights"):
		failures.append("%s missing asset strategy should list fanmade repos as pattern references" % kind)
	var review_gate: Array = strategy.get("release_self_review_gate", [])
	if not review_gate.has("no_direct_fanmade_copy"):
		failures.append("%s missing asset strategy release gate missing no_direct_fanmade_copy" % kind)
	if ["collision", "object_visual"].has(kind) and not review_gate.has("polygon_points"):
		failures.append("%s missing asset strategy should require polygon point review" % kind)
	if kind == "collision" and not review_gate.has("polygon_area_px"):
		failures.append("collision missing asset strategy should require polygon area review")
	if kind == "object_visual" and not review_gate.has("fallback_polygon_area_px"):
		failures.append("object visual missing asset strategy should require fallback polygon area review")
	if ["sprite", "vfx", "object_visual"].has(kind):
		for gate in ["frame_grid_ok", "expected_frame_size", "fps_reviewed",
				"animation_stability_reviewed", "motion_reviewed", "origin_alignment_reviewed",
				"origin_px"]:
			if not review_gate.has(gate):
				failures.append("%s missing asset strategy release gate missing %s" % [kind, gate])
	if kind == "audio":
		for gate in ["waveform_ok", "duration_reviewed"]:
			if not review_gate.has(gate):
				failures.append("%s missing asset strategy release gate missing %s" % [kind, gate])
	if not bool(strategy.get("release_requires_self_review", false)):
		failures.append("%s missing asset strategy should require self review before release" % kind)

func _expect_source_priority(source_plan: Dictionary, kind: String, failures: Array[String]) -> void:
	var priority: Array = source_plan.get("source_priority", [])
	if priority.is_empty():
		failures.append("%s source plan should expose source_priority for missing/replacement assets" % kind)
		return
	if priority.has("fanmade_direct_copy"):
		failures.append("%s source priority should never allow direct fanmade copy" % kind)
	var expected := _expected_source_priority(kind)
	if not expected.is_empty() and priority != expected:
		failures.append("%s source priority should be %s" % [kind, expected])

func _expected_source_priority(kind: String) -> Array[String]:
	match kind:
		"sprite":
			return ["0x72_dungeontileset_ii", "user_local_assets", "free_itchio",
				"godot_asset_library", "ai_generated"]
		"audio":
			return ["user_local_assets", "free_itchio", "godot_asset_library",
				"ai_generated"]
		"vfx":
			return ["procedural_godot_shapes", "user_local_assets", "free_itchio",
				"godot_asset_library", "ai_generated"]
		"collision":
			return ["project_owned_collision_polygon", "procedural_godot_shapes",
				"0x72_dungeontileset_ii", "user_local_assets", "free_itchio",
				"godot_asset_library", "ai_generated"]
		"object_visual":
			return ["0x72_dungeontileset_ii", "project_owned_collision_polygon",
				"procedural_godot_shapes", "user_local_assets", "free_itchio",
				"godot_asset_library", "ai_generated"]
	return ["user_local_assets", "free_itchio", "godot_asset_library", "ai_generated"]
