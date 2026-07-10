extends SceneTree

class DummyPlayer:
	extends Node2D

func _init() -> void:
	var failures: Array[String] = []

	await _check_exit_portal_feedback(failures)
	await _check_final_exit_portal_feedback(failures)
	_check_boss_objective_after_clear(failures)
	_check_final_boss_objective_after_clear(failures)
	_check_main_floor_transition_feedback(failures)

	if failures.is_empty():
		print("Floor exit smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_exit_portal_feedback(failures: Array[String]) -> void:
	var player := DummyPlayer.new()
	player.global_position = Vector2(100, 0)
	root.add_child(player)
	var portal := ExitPortal.new()
	portal.configure(player)
	root.add_child(portal)
	await process_frame

	var prompt := portal.get_node_or_null("PortalPrompt") as Label
	if prompt == null:
		failures.append("exit portal should expose a prompt label")
	elif not prompt.text.contains("Next Floor"):
		failures.append("exit portal prompt should say Next Floor")
	if not bool(portal.get_meta("ready_for_next_floor", false)):
		failures.append("exit portal should expose ready_for_next_floor metadata")
	var sprite := portal.get_node_or_null("PortalSprite") as Sprite2D
	if sprite == null:
		failures.append("exit portal should expose a named portal sprite")
	elif sprite.texture == null or str(sprite.get_meta("portal_sprite", "")) != "floor_ladder":
		failures.append("exit portal should use the ladder sprite")
	else:
		_assert_portal_sprite_metadata(sprite, "floor_ladder", failures)

	var entered_count := {"count": 0}
	portal.entered.connect(func() -> void:
		entered_count["count"] += 1)
	player.global_position = Vector2.ZERO
	await process_frame
	await process_frame
	if int(entered_count["count"]) != 1:
		failures.append("exit portal should emit entered exactly once")

	portal.queue_free()
	player.queue_free()
	await process_frame

func _check_final_exit_portal_feedback(failures: Array[String]) -> void:
	var player := DummyPlayer.new()
	player.global_position = Vector2(100, 0)
	root.add_child(player)
	var portal := ExitPortal.new()
	portal.configure(player)
	if portal.has_method("set_run_finale"):
		portal.call("set_run_finale", true)
	else:
		failures.append("final exit portal should support run finale mode")
	root.add_child(portal)
	await process_frame

	var prompt := portal.get_node_or_null("PortalPrompt") as Label
	if prompt == null:
		failures.append("final exit portal should expose a prompt label")
	elif not prompt.text.contains("Run Complete"):
		failures.append("final exit portal prompt should say Run Complete")
	if not bool(portal.get_meta("ready_for_run_complete", false)):
		failures.append("final exit portal should expose ready_for_run_complete metadata")
	var sprite := portal.get_node_or_null("PortalSprite") as Sprite2D
	if sprite == null:
		failures.append("final exit portal should expose a named portal sprite")
	elif sprite.texture == null or str(sprite.get_meta("portal_sprite", "")) != "floor_stairs":
		failures.append("final exit portal should use the stairs sprite")
	else:
		_assert_portal_sprite_metadata(sprite, "floor_stairs", failures)

	portal.queue_free()
	player.queue_free()
	await process_frame

func _check_boss_objective_after_clear(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var boss := RoomNode.new()
	boss.id = 7
	boss.type = RoomNode.RoomType.BOSS
	ctrl.current_room = boss
	ctrl.cleared_rooms[boss.id] = true
	var objective := ctrl.current_room_objective()
	if not objective.contains("Boss reward"):
		failures.append("cleared boss objective should mention boss reward")
	if not objective.contains("Enter exit portal"):
		failures.append("cleared boss objective should point to exit portal")
	var context: Dictionary = ctrl.call("current_room_objective_context")
	if str(context.get("next_action_chain", "")) != "reward -> portal":
		failures.append("cleared boss context should expose reward -> portal action chain")
	if str(context.get("next_action_priority", "")) != "reward":
		failures.append("cleared boss context should prioritize reward before portal")
	ctrl.free()

func _check_final_boss_objective_after_clear(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var boss := RoomNode.new()
	boss.id = 9
	boss.type = RoomNode.RoomType.BOSS
	ctrl.current_room = boss
	ctrl.current_biome = {"id": "crystal_archive", "run_finale": true}
	ctrl.cleared_rooms[boss.id] = true
	var objective := ctrl.current_room_objective()
	if not objective.contains("Final boss reward"):
		failures.append("final cleared boss objective should mention final boss reward")
	if not objective.contains("run complete portal"):
		failures.append("final cleared boss objective should point to run complete portal")
	var next_action := ctrl.current_room_next_action()
	if not next_action.contains("Pick reward") or not next_action.contains("run complete portal"):
		failures.append("final cleared boss next action should chain reward into run complete portal")
	var completion := ctrl.room_objective_completed_text(boss)
	if not completion.contains("FINAL BOSS"):
		failures.append("final boss completion text should say FINAL BOSS")
	if not completion.contains("Run complete portal"):
		failures.append("final boss completion text should mention run complete portal")
	ctrl.call("mark_room_reward_claimed", boss.id)
	next_action = ctrl.current_room_next_action()
	if not next_action.contains("Enter run complete portal"):
		failures.append("final reward claimed next action should enter run complete portal")
	var context: Dictionary = ctrl.call("current_room_objective_context")
	if str(context.get("next_action_text", "")) != next_action:
		failures.append("final reward claimed context should mirror run complete next action text")
	ctrl.free()

func _check_main_floor_transition_feedback(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("_show_floor_transition_card"):
		failures.append("Main should show a floor transition card after descending")
	if not source.contains("FloorTransitionCard"):
		failures.append("floor transition feedback should create a named card")
	if not source.contains("_show_floor_transition_card(true)"):
		failures.append("Main should show the floor transition card on run start")
	if not source.contains("_show_floor_transition_card(false)"):
		failures.append("Main should show the floor transition card after later descents")
	if not source.contains("_floor_ctrl.current_biome_label()"):
		failures.append("floor transition feedback should include the active biome label")
	if not source.contains("player.upgrade_summary()"):
		failures.append("floor transition feedback should include current build summary")
	if not source.contains("_last_floor_summary"):
		failures.append("Main should keep the previous floor summary for descent feedback")
	if not source.contains("Last floor:"):
		failures.append("floor transition card should recap the previous floor")
	if not source.contains("Gold %d"):
		failures.append("floor transition card should include current gold")
	if not source.contains("Keys %d"):
		failures.append("floor transition card should include current key count")
	if not source.contains("HP %d/%d"):
		failures.append("floor transition card should include current hp")
	if not source.contains("%s %.0f/%.0f"):
		failures.append("floor transition card should include current resource")
	if not source.contains("AudioCueDBScript"):
		failures.append("Main floor transition SFX should use AudioCueDB")
	if not source.contains("_play_floor_transition_sfx"):
		failures.append("Main should play a floor transition sound with the transition card")
	if not source.contains("FloorTransitionSfx"):
		failures.append("floor transition feedback should create a named sound placeholder")
	if not source.contains("floor_transition_cue(initial)"):
		failures.append("floor transition sound should use the initial/descending cue")
	if not source.contains("headless_playback_skipped"):
		failures.append("floor transition sound should skip playback in headless smoke")

func _assert_portal_sprite_metadata(sprite: Sprite2D, sprite_name: String, failures: Array[String]) -> void:
	var report := SpriteDB.animation_report(sprite_name)
	if int(sprite.get_meta("frame_count", 0)) != int(report.get("frame_count", 0)):
		failures.append("%s portal should store frame_count metadata" % sprite_name)
	if sprite.get_meta("frame_size", Vector2.ZERO) != report.get("frame_size", Vector2.ZERO):
		failures.append("%s portal should store frame_size metadata" % sprite_name)
	if bool(sprite.get_meta("stable_size", false)) != bool(report.get("stable_size", false)):
		failures.append("%s portal should store stable_size metadata" % sprite_name)
	if float(sprite.get_meta("fps", 0.0)) != float(report.get("fps", 0.0)):
		failures.append("%s portal should store fps metadata" % sprite_name)
	if not bool(sprite.get_meta("frame_grid_ok", false)):
		failures.append("%s portal should pass frame grid review" % sprite_name)
	if bool(sprite.get_meta("animation_stability_reviewed", false)) != bool(report.get("animation_stability_reviewed", false)):
		failures.append("%s portal should store animation stability review metadata" % sprite_name)
	if bool(sprite.get_meta("motion_reviewed", false)) != bool(report.get("motion_reviewed", false)):
		failures.append("%s portal should store motion review metadata" % sprite_name)
	if bool(sprite.get_meta("origin_alignment_reviewed", false)) != bool(report.get("origin_alignment_reviewed", false)):
		failures.append("%s portal should store origin alignment review metadata" % sprite_name)
	if str(sprite.get_meta("asset_source", "")) == "":
		failures.append("%s portal should expose asset source metadata" % sprite_name)
	if str(sprite.get_meta("release_decision", "")) != "public_ok":
		failures.append("%s portal should be public_ok for release" % sprite_name)
	if bool(sprite.get_meta("needs_replacement_before_public", true)):
		failures.append("%s portal should not need replacement before public release" % sprite_name)
