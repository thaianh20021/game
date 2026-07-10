extends SceneTree

const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")

const CASES := [
	{"class": "breaker", "skill": "earthbreaker"},
	{"class": "nightblade", "skill": "shadow_step"},
	{"class": "bulwark", "skill": "shield_bastion"},
	{"class": "gunner", "skill": "rolling_grenade"},
	{"class": "soulbinder", "skill": "summon_wisp"},
	{"class": "lightkeeper", "skill": "light_ray"},
	{"class": "tinkerer", "skill": "mini_turret"},
]

func _init() -> void:
	var failures: Array[String] = []

	_check_audio_cue_db_contract(failures)
	await _check_all_active_skills_have_feedback_profiles(failures)
	await _check_skill_cast_feedback(failures)
	await _check_skill_blocked_feedback(failures)
	await _check_sacrifice_no_pet_block(failures)
	await _check_hack_no_trap_block(failures)
	await _check_dash_blocked_feedback(failures)
	await _check_weapon_attack_blocked_feedback(failures)
	await _check_hud_cooldown_icon(failures)
	await _check_hud_class_resource_summary(failures)
	await _check_hud_active_reload_window_feedback(failures)
	Engine.time_scale = 1.0

	if failures.is_empty():
		print("Skill feedback smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_audio_cue_db_contract(failures: Array[String]) -> void:
	var path := "res://scripts/audio/audio_cue_db.gd"
	if not ResourceLoader.exists(path):
		failures.append("AudioCueDB should exist as a central placeholder SFX registry")
		return
	var db = load(path)
	var blade: Dictionary = db.call("skill_cast_cue", "wind_edge")
	if str(blade.get("id", "")) != "blade_cast":
		failures.append("AudioCueDB should map wind_edge to blade_cast")
	if str(blade.get("family", "")) != "blade":
		failures.append("AudioCueDB should expose cue family metadata")
	if float(blade.get("frequency", 0.0)) <= 0.0:
		failures.append("AudioCueDB should expose generated placeholder frequency")
	if str(blade.get("label", "")) == "":
		failures.append("AudioCueDB should expose a readable cue label")
	var unknown: Dictionary = db.call("skill_cast_cue", "__missing_skill__")
	if str(unknown.get("id", "")) != "generic_cast":
		failures.append("AudioCueDB should fall back to generic_cast")
	if not db.has_method("weapon_attack_cue"):
		failures.append("AudioCueDB should expose weapon_attack_cue")
	else:
		var melee: Dictionary = db.call("weapon_attack_cue", {"group": "sword_1h"})
		if str(melee.get("id", "")) != "melee_attack":
			failures.append("AudioCueDB should map melee weapon groups to melee_attack")
		var ranged: Dictionary = db.call("weapon_attack_cue", {"group": "pistol"})
		if str(ranged.get("id", "")) != "ranged_attack":
			failures.append("AudioCueDB should map pistol weapon groups to ranged_attack")
		var magic: Dictionary = db.call("weapon_attack_cue", {"group": "staff"})
		if str(magic.get("id", "")) != "magic_attack":
			failures.append("AudioCueDB should map magic weapon groups to magic_attack")
		if float(melee.get("frequency", 0.0)) <= 0.0 \
				or float(ranged.get("frequency", 0.0)) <= 0.0 \
				or float(magic.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB weapon cues should expose generated frequencies")
	if not db.call("cue_exists", "blade_cast"):
		failures.append("AudioCueDB should report known cue ids")
	if not db.call("cue_exists", "melee_attack"):
		failures.append("AudioCueDB should report known weapon cue ids")
	if not db.has_method("pickup_cue"):
		failures.append("AudioCueDB should expose pickup_cue")
	else:
		var gold: Dictionary = db.call("pickup_cue", {"type": "gold"})
		if str(gold.get("id", "")) != "pickup_gold":
			failures.append("AudioCueDB should map gold pickups to pickup_gold")
		var heal: Dictionary = db.call("pickup_cue", {"type": "potion"})
		if str(heal.get("id", "")) != "pickup_heal":
			failures.append("AudioCueDB should map potion pickups to pickup_heal")
		var key: Dictionary = db.call("pickup_cue", {"type": "silver_key"})
		if str(key.get("id", "")) != "pickup_key":
			failures.append("AudioCueDB should map silver keys to pickup_key")
		var weapon: Dictionary = db.call("pickup_cue", {"type": "weapon"})
		if str(weapon.get("id", "")) != "pickup_weapon":
			failures.append("AudioCueDB should map weapon pickups to pickup_weapon")
		var meta: Dictionary = db.call("pickup_cue", {"type": "rune_dust"})
		if str(meta.get("id", "")) != "pickup_meta":
			failures.append("AudioCueDB should map meta currency pickups to pickup_meta")
		if float(gold.get("frequency", 0.0)) <= 0.0 \
				or float(meta.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB pickup cues should expose generated frequencies")
	if not db.call("cue_exists", "pickup_gold"):
		failures.append("AudioCueDB should report known pickup cue ids")
	if not db.has_method("boss_attack_cue"):
		failures.append("AudioCueDB should expose boss_attack_cue")
	else:
		var bullet_hell: Dictionary = db.call("boss_attack_cue", {"attack": "bullet_hell"})
		if str(bullet_hell.get("id", "")) != "boss_bullet_hell":
			failures.append("AudioCueDB should map boss bullet hell to boss_bullet_hell")
		if str(bullet_hell.get("kind", "")) != "boss_attack":
			failures.append("AudioCueDB boss cues should expose boss_attack kind")
		if float(bullet_hell.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB boss cues should expose generated frequencies")
		var trap_wave: Dictionary = db.call("boss_attack_cue", {"attack": "trap_wave"})
		if str(trap_wave.get("id", "")) != "boss_trap_wave":
			failures.append("AudioCueDB should map boss trap wave to boss_trap_wave")
		var spore: Dictionary = db.call("boss_attack_cue", {
			"attack": "bullet_hell",
			"variant_attack": "spore_bloom",
		})
		if str(spore.get("id", "")) != "boss_spore_bloom":
			failures.append("AudioCueDB should map spore bloom variants to boss_spore_bloom")
	if not db.call("cue_exists", "boss_bullet_hell"):
		failures.append("AudioCueDB should report known boss cue ids")
	if not db.has_method("boss_phase_cue"):
		failures.append("AudioCueDB should expose boss_phase_cue")
	else:
		var phase_shift: Dictionary = db.call("boss_phase_cue", {"phase": 2})
		if str(phase_shift.get("id", "")) != "boss_phase_shift":
			failures.append("AudioCueDB should map normal boss phase changes to boss_phase_shift")
		if str(phase_shift.get("kind", "")) != "boss_phase":
			failures.append("AudioCueDB boss phase cues should expose boss_phase kind")
		var enrage: Dictionary = db.call("boss_phase_cue", {"phase": 3, "enraged": true})
		if str(enrage.get("id", "")) != "boss_enrage":
			failures.append("AudioCueDB should map enraged boss phase changes to boss_enrage")
		if float(enrage.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB boss phase cues should expose generated frequencies")
	if not db.call("cue_exists", "boss_enrage"):
		failures.append("AudioCueDB should report known boss phase cue ids")
	if not db.has_method("reward_decision_cue"):
		failures.append("AudioCueDB should expose reward_decision_cue")
	else:
		var choose_reward: Dictionary = db.call("reward_decision_cue", "choose")
		if str(choose_reward.get("id", "")) != "reward_choose":
			failures.append("AudioCueDB should map reward choose to reward_choose")
		if str(choose_reward.get("kind", "")) != "reward_decision":
			failures.append("AudioCueDB reward cues should expose reward_decision kind")
		var reroll_reward: Dictionary = db.call("reward_decision_cue", "reroll")
		if str(reroll_reward.get("id", "")) != "reward_reroll":
			failures.append("AudioCueDB should map reward reroll to reward_reroll")
		var skip_reward: Dictionary = db.call("reward_decision_cue", "skip")
		if str(skip_reward.get("id", "")) != "reward_skip":
			failures.append("AudioCueDB should map reward skip to reward_skip")
		if float(skip_reward.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB reward cues should expose generated frequencies")
	if not db.call("cue_exists", "reward_choose"):
		failures.append("AudioCueDB should report known reward cue ids")
	if not db.has_method("shop_decision_cue"):
		failures.append("AudioCueDB should expose shop_decision_cue")
	else:
		var shop_buy: Dictionary = db.call("shop_decision_cue", "buy")
		if str(shop_buy.get("id", "")) != "shop_buy":
			failures.append("AudioCueDB should map shop buy to shop_buy")
		if str(shop_buy.get("kind", "")) != "shop_decision":
			failures.append("AudioCueDB shop cues should expose shop_decision kind")
		var shop_leave: Dictionary = db.call("shop_decision_cue", "leave")
		if str(shop_leave.get("id", "")) != "shop_leave":
			failures.append("AudioCueDB should map shop leave to shop_leave")
		if float(shop_leave.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB shop cues should expose generated frequencies")
	if not db.call("cue_exists", "shop_buy"):
		failures.append("AudioCueDB should report known shop cue ids")
	if not db.has_method("overlay_action_cue"):
		failures.append("AudioCueDB should expose overlay_action_cue")
	else:
		var resume: Dictionary = db.call("overlay_action_cue", "resume")
		if str(resume.get("id", "")) != "overlay_resume":
			failures.append("AudioCueDB should map overlay resume to overlay_resume")
		if str(resume.get("kind", "")) != "overlay_action":
			failures.append("AudioCueDB overlay cues should expose overlay_action kind")
		var restart: Dictionary = db.call("overlay_action_cue", "restart")
		if str(restart.get("id", "")) != "overlay_restart":
			failures.append("AudioCueDB should map overlay restart to overlay_restart")
		if float(restart.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB overlay cues should expose generated frequencies")
	if not db.call("cue_exists", "overlay_resume"):
		failures.append("AudioCueDB should report known overlay cue ids")
	if not db.has_method("objective_complete_cue"):
		failures.append("AudioCueDB should expose objective_complete_cue")
	else:
		var objective: Dictionary = db.call("objective_complete_cue", "COMBAT complete | Reward ready")
		if str(objective.get("id", "")) != "objective_reward_ready":
			failures.append("AudioCueDB should map reward-ready objectives to objective_reward_ready")
		if str(objective.get("kind", "")) != "objective_complete":
			failures.append("AudioCueDB objective cues should expose objective_complete kind")
		if float(objective.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB objective cues should expose generated frequencies")
		var final_objective: Dictionary = db.call("objective_complete_cue",
			"FINAL BOSS complete | Run complete portal ready")
		if str(final_objective.get("family", "")) != "finale":
			failures.append("AudioCueDB should mark run-complete objective cues as finale")
		if not bool(final_objective.get("finale", false)):
			failures.append("run-complete objective cues should expose finale metadata")
	if not db.call("cue_exists", "objective_reward_ready"):
		failures.append("AudioCueDB should report known objective cue ids")
	var finale_clear: Dictionary = db.call("room_clear_cue", "BOSS", false,
		"Final Boss defeated | Run complete portal ready")
	if str(finale_clear.get("id", "")) != "room_clear_finale":
		failures.append("AudioCueDB should map final boss clears to room_clear_finale")
	if str(finale_clear.get("family", "")) != "finale":
		failures.append("final boss clear cue should expose finale family metadata")
	if not db.call("cue_exists", "room_clear_finale"):
		failures.append("AudioCueDB should report final boss room clear cue id")
	if not db.has_method("floor_transition_cue"):
		failures.append("AudioCueDB should expose floor_transition_cue")
	else:
		var run_start: Dictionary = db.call("floor_transition_cue", true)
		if str(run_start.get("id", "")) != "floor_run_start":
			failures.append("AudioCueDB should map initial floor cards to floor_run_start")
		if str(run_start.get("kind", "")) != "floor_transition":
			failures.append("AudioCueDB floor transition cues should expose floor_transition kind")
		var descend: Dictionary = db.call("floor_transition_cue", false)
		if str(descend.get("id", "")) != "floor_descend":
			failures.append("AudioCueDB should map descents to floor_descend")
		if float(descend.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB floor transition cues should expose generated frequencies")
	if not db.call("cue_exists", "floor_run_start"):
		failures.append("AudioCueDB should report known floor transition cue ids")
	if not db.has_method("run_end_cue"):
		failures.append("AudioCueDB should expose run_end_cue")
	else:
		var victory: Dictionary = db.call("run_end_cue", "RUN COMPLETE!")
		if str(victory.get("id", "")) != "run_victory":
			failures.append("AudioCueDB should map run complete messages to run_victory")
		if str(victory.get("kind", "")) != "run_end":
			failures.append("AudioCueDB run end cues should expose run_end kind")
		var defeat: Dictionary = db.call("run_end_cue", "YOU DIED")
		if str(defeat.get("id", "")) != "run_defeat":
			failures.append("AudioCueDB should map death messages to run_defeat")
		if float(defeat.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB run end cues should expose generated frequencies")
	if not db.call("cue_exists", "run_victory"):
		failures.append("AudioCueDB should report known run end cue ids")
	if not db.has_method("class_select_cue"):
		failures.append("AudioCueDB should expose class_select_cue")
	else:
		var class_pick: Dictionary = db.call("class_select_cue", "select_class")
		if str(class_pick.get("id", "")) != "class_select":
			failures.append("AudioCueDB should map class select actions to class_select")
		if str(class_pick.get("kind", "")) != "class_select":
			failures.append("AudioCueDB class select cues should expose class_select kind")
		var run_confirm: Dictionary = db.call("class_select_cue", "confirm_run")
		if str(run_confirm.get("id", "")) != "class_confirm":
			failures.append("AudioCueDB should map run confirmation to class_confirm")
		var meta_buy: Dictionary = db.call("class_select_cue", "meta_buy")
		if str(meta_buy.get("id", "")) != "meta_buy":
			failures.append("AudioCueDB should map meta buys to meta_buy")
		var meta_reset: Dictionary = db.call("class_select_cue", "meta_reset_confirm")
		if str(meta_reset.get("id", "")) != "meta_reset":
			failures.append("AudioCueDB should map confirmed resets to meta_reset")
		if float(meta_reset.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB class select cues should expose generated frequencies")
	if not db.call("cue_exists", "class_confirm"):
		failures.append("AudioCueDB should report known class select cue ids")
	if not db.has_method("revive_cue"):
		failures.append("AudioCueDB should expose revive_cue")
	else:
		var revive: Dictionary = db.call("revive_cue", {"source": "Boss: Smash"})
		if str(revive.get("id", "")) != "player_revive":
			failures.append("AudioCueDB should map revive events to player_revive")
		if str(revive.get("kind", "")) != "player_revive":
			failures.append("AudioCueDB revive cues should expose player_revive kind")
		if str(revive.get("source", "")) != "AudioCueDB":
			failures.append("AudioCueDB revive cues should expose registry source metadata")
		if str(revive.get("revive_source", "")) != "Boss: Smash":
			failures.append("AudioCueDB revive cues should preserve lethal source metadata")
		if float(revive.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB revive cues should expose generated frequencies")
	if not db.call("cue_exists", "player_revive"):
		failures.append("AudioCueDB should report known revive cue id")
	if not db.has_method("skill_blocked_cue"):
		failures.append("AudioCueDB should expose skill_blocked_cue")
	else:
		var blocked: Dictionary = db.call("skill_blocked_cue", "cooldown")
		if str(blocked.get("id", "")) != "skill_blocked":
			failures.append("AudioCueDB should map blocked skills to skill_blocked")
		if str(blocked.get("kind", "")) != "skill_blocked":
			failures.append("AudioCueDB blocked skill cues should expose skill_blocked kind")
		if str(blocked.get("blocked_reason", "")) != "cooldown":
			failures.append("AudioCueDB blocked skill cues should store blocked reason")
		if float(blocked.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB blocked skill cues should expose generated frequencies")
	if not db.call("cue_exists", "skill_blocked"):
		failures.append("AudioCueDB should report known blocked skill cue id")
	if not db.has_method("class_resource_full_cue"):
		failures.append("AudioCueDB should expose class_resource_full_cue")
	else:
		var full_resource: Dictionary = db.call("class_resource_full_cue", "rounds", "Rounds 6/6")
		if str(full_resource.get("id", "")) != "class_resource_full":
			failures.append("AudioCueDB should map full class resources to class_resource_full")
		if str(full_resource.get("kind", "")) != "class_resource_full":
			failures.append("AudioCueDB class resource cues should expose class_resource_full kind")
		if str(full_resource.get("resource_kind", "")) != "rounds":
			failures.append("AudioCueDB class resource cues should store resource kind")
		if str(full_resource.get("summary", "")) != "Rounds 6/6":
			failures.append("AudioCueDB class resource cues should store readable summary")
		if float(full_resource.get("frequency", 0.0)) <= 0.0:
			failures.append("AudioCueDB class resource cues should expose generated frequencies")
	if not db.call("cue_exists", "class_resource_full"):
		failures.append("AudioCueDB should report known class resource cue id")
	var player_source := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	if not player_source.contains("AudioCueDBScript"):
		failures.append("Player skill SFX should use AudioCueDB")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	if not hud_source.contains("AudioCueDBScript"):
		failures.append("HUD skill SFX labels should use AudioCueDB")

func _check_all_active_skills_have_feedback_profiles(failures: Array[String]) -> void:
	var scene := _make_scene("SkillFeedbackProfileScene")
	for skill_id in _all_active_skill_ids():
		var profile: Dictionary = CombatFxScript.skill_feedback_profile(skill_id)
		var fx := CombatFxScript.spawn_skill_cast(scene, Vector2.ZERO, skill_id)
		var style := str(fx.get_meta("skill_style", ""))
		var family := str(fx.get_meta("skill_family", ""))
		if style == "" or style == "generic":
			failures.append("%s should use a non-generic skill VFX style" % skill_id)
		if family == "":
			failures.append("%s should expose a feedback family for HUD/audio hooks" % skill_id)
		if str(profile.get("cast_label", "")) == "":
			failures.append("%s should expose a cast label for HUD/audio copy" % skill_id)
		if str(profile.get("telegraph_shape", "")) == "":
			failures.append("%s should expose a telegraph shape for readable casts" % skill_id)
		if str(profile.get("impact_shape", "")) == "":
			failures.append("%s should expose an impact shape for readable casts" % skill_id)
		if str(profile.get("cooldown_icon", "")) == "":
			failures.append("%s should expose a cooldown icon token" % skill_id)
		if str(profile.get("feedback_hint", "")) == "":
			failures.append("%s should expose a short feedback hint" % skill_id)
		if str(profile.get("impact_cue", "")) == "":
			failures.append("%s should expose a readable impact cue" % skill_id)
		if str(profile.get("feel_tier", "")) == "":
			failures.append("%s should expose a feel_tier for animation/audio tuning" % skill_id)
		if str(profile.get("cooldown_hint", "")) == "":
			failures.append("%s should expose a cooldown_hint for HUD tooltips" % skill_id)
		if str(fx.get_meta("skill_cast_label", "")) != str(profile.get("cast_label", "")):
			failures.append("%s skill VFX should tag cast label metadata" % skill_id)
		if str(fx.get_meta("skill_telegraph_shape", "")) != str(profile.get("telegraph_shape", "")):
			failures.append("%s skill VFX should tag telegraph shape metadata" % skill_id)
		if str(fx.get_meta("skill_impact_shape", "")) != str(profile.get("impact_shape", "")):
			failures.append("%s skill VFX should tag impact shape metadata" % skill_id)
		if str(fx.get_meta("skill_impact_cue", "")) != str(profile.get("impact_cue", "")):
			failures.append("%s skill VFX should tag readable impact cue metadata" % skill_id)
		if str(fx.get_meta("skill_feel_tier", "")) != str(profile.get("feel_tier", "")):
			failures.append("%s skill VFX should tag feel tier metadata" % skill_id)
		if str(fx.get_meta("skill_cooldown_hint", "")) != str(profile.get("cooldown_hint", "")):
			failures.append("%s skill VFX should tag cooldown hint metadata" % skill_id)
		if int(fx.get_meta("skill_layer_count", 0)) < 3:
			failures.append("%s skill VFX should tag layered cast count" % skill_id)
		if fx.get_child_count() < 2:
			failures.append("%s skill VFX should include layered visuals" % skill_id)
		if int(fx.get_meta("frame_count", 0)) != 1:
			failures.append("%s skill VFX should expose stable procedural frame count" % skill_id)
		if fx.get_meta("frame_size", Vector2.ZERO) == Vector2.ZERO:
			failures.append("%s skill VFX should expose procedural frame size metadata" % skill_id)
		if not bool(fx.get_meta("animation_stability_reviewed", false)):
			failures.append("%s skill VFX should expose animation stability review metadata" % skill_id)
		if not bool(fx.get_meta("origin_alignment_reviewed", false)):
			failures.append("%s skill VFX should expose origin alignment review metadata" % skill_id)
	scene.queue_free()
	await process_frame

func _check_skill_cast_feedback(failures: Array[String]) -> void:
	for c in CASES:
		var scene := _make_scene("SkillFeedback%sScene" % c["skill"])
		var player := await _make_player(scene, str(c["class"]))
		player.skill = {"id": str(c["skill"]), "cost": 0, "cooldown": 2.0}

		var seen := {"cast": false, "cooldown": false}
		player.skill_cast.connect(func(id: String, cooldown: float) -> void:
			if id == str(c["skill"]) and cooldown > 0.0:
				seen["cast"] = true)
		player.skill_cooldown_changed.connect(func(id: String, left: float, total: float) -> void:
			if id == str(c["skill"]) and left > 0.0 and total == 2.0:
				seen["cooldown"] = true)

		Engine.time_scale = 1.0
		player.call("_try_skill")
		if not player.has_method("skill_usage_summary"):
			failures.append("Player should expose skill_usage_summary for run summary skill tracking")
		else:
			var usage := str(player.call("skill_usage_summary"))
			var profile: Dictionary = CombatFxScript.skill_feedback_profile(str(c["skill"]))
			var cast_label := str(profile.get("cast_label", ""))
			if not usage.contains("%s x1" % cast_label):
				failures.append("%s cast should record skill usage summary" % c["skill"])
		var sfx := player.get_node_or_null("SkillCastSfx")
		var profile: Dictionary = CombatFxScript.skill_feedback_profile(str(c["skill"]))
		var impact_cue := str(profile.get("impact_cue", ""))
		if sfx == null:
			failures.append("%s should create cast sound placeholder" % c["skill"])
		else:
			if str(sfx.get_meta("skill_sound_id", "")) == "":
				failures.append("%s cast sound placeholder should expose sound id metadata" % c["skill"])
			if str(sfx.get_meta("audio_cue_label", "")) == "":
				failures.append("%s cast sound placeholder should expose readable cue label metadata" % c["skill"])
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("%s cast sound placeholder should come from AudioCueDB" % c["skill"])
			if str(sfx.get_meta("skill_family", "")) == "":
				failures.append("%s cast sound placeholder should expose skill family metadata" % c["skill"])
			if str(sfx.get_meta("skill_style", "")) == "":
				failures.append("%s cast sound placeholder should expose skill style metadata" % c["skill"])
			if str(sfx.get_meta("skill_cast_label", "")) == "":
				failures.append("%s cast sound placeholder should expose cast label metadata" % c["skill"])
			if str(sfx.get_meta("skill_impact_shape", "")) == "":
				failures.append("%s cast sound placeholder should expose impact shape metadata" % c["skill"])
			if str(sfx.get_meta("skill_impact_cue", "")) != impact_cue:
				failures.append("%s cast sound placeholder should expose readable impact cue metadata" % c["skill"])
			if str(sfx.get_meta("skill_audio_intensity", "")) == "":
				failures.append("%s cast sound placeholder should expose audio intensity metadata" % c["skill"])
			if str(sfx.get_meta("skill_feel_tier", "")) == "":
				failures.append("%s cast sound placeholder should expose feel tier metadata" % c["skill"])
			if str(sfx.get_meta("skill_cooldown_hint", "")) == "":
				failures.append("%s cast sound placeholder should expose cooldown hint metadata" % c["skill"])
			if str(player.get_meta("last_skill_sound_id", "")) != str(sfx.get_meta("skill_sound_id", "")):
				failures.append("%s should store last skill sound id for HUD/audio hooks" % c["skill"])
			if str(player.get_meta("last_skill_cast_label", "")) != str(sfx.get_meta("skill_cast_label", "")):
				failures.append("%s should store last skill cast label for HUD/audio hooks" % c["skill"])
			if str(player.get_meta("last_skill_feel_tier", "")) != str(sfx.get_meta("skill_feel_tier", "")):
				failures.append("%s should store last skill feel tier for HUD/audio hooks" % c["skill"])
			if str(player.get_meta("last_skill_impact_cue", "")) != impact_cue:
				failures.append("%s should store last readable impact cue metadata" % c["skill"])
			if str(sfx.get_meta("skill_slot", "")) != "primary":
				failures.append("%s cast sound placeholder should tag primary skill slot" % c["skill"])
			if str(player.get_meta("last_skill_cast_slot", "")) != "primary":
				failures.append("%s should store last primary skill cast slot metadata" % c["skill"])
			if sfx.stream == null:
				failures.append("%s cast sound placeholder should assign an audio stream" % c["skill"])
			if not bool(sfx.get_meta("placeholder_audio_stream", false)):
				failures.append("%s cast sound placeholder should mark generated audio stream metadata" % c["skill"])
			if float(sfx.get_meta("skill_sound_frequency", 0.0)) <= 0.0:
				failures.append("%s cast sound placeholder should expose generated pitch metadata" % c["skill"])
			if not bool(sfx.get_meta("playback_requested", false)):
				failures.append("%s cast sound placeholder should request playback" % c["skill"])
			if DisplayServer.get_name() != "headless" and not sfx.playing:
				failures.append("%s cast sound placeholder should start playback" % c["skill"])
		if Engine.time_scale >= 1.0:
			failures.append("%s should pulse a light hit pause" % c["skill"])
		if not is_equal_approx(float(player.get_meta("hit_pause_seconds", 0.0)), 0.08):
			failures.append("%s should expose skill hit pause duration metadata" % c["skill"])
		if not is_equal_approx(float(player.get_meta("hit_pause_scale", 0.0)), 0.82):
			failures.append("%s should expose skill hit pause scale metadata" % c["skill"])
		if str(player.get_meta("hit_pause_source", "")) != "skill":
			failures.append("%s should expose skill hit pause source metadata" % c["skill"])
		if str(player.get_meta("hit_pause_skill_style", "")) == "":
			failures.append("%s should expose skill hit pause style metadata" % c["skill"])
		if str(player.get_meta("hit_pause_skill_feel_tier", "")) == "":
			failures.append("%s should expose skill hit pause feel tier metadata" % c["skill"])
		if str(player.get_meta("hit_pause_skill_impact_cue", "")) != impact_cue:
			failures.append("%s should expose skill hit pause impact cue metadata" % c["skill"])

		await process_frame
		if not bool(seen["cast"]):
			failures.append("%s should emit skill_cast feedback" % c["skill"])
		if not bool(seen["cooldown"]):
			failures.append("%s should emit skill cooldown feedback" % c["skill"])
		var fx := _child_named(scene, "CombatFxSkillCast")
		if fx == null:
			failures.append("%s should spawn skill cast VFX" % c["skill"])
		elif str(fx.get_meta("skill_slot", "")) != "primary":
			failures.append("%s skill cast VFX should tag primary skill slot" % c["skill"])
		elif str(fx.get_meta("skill_impact_cue", "")) != impact_cue:
			failures.append("%s skill cast VFX should tag impact cue" % c["skill"])

		await create_timer(0.12, true, false, true).timeout
		if not is_equal_approx(Engine.time_scale, 1.0):
			failures.append("%s should restore hit pause time scale" % c["skill"])
			Engine.time_scale = 1.0
		await process_frame
		if player.get_node_or_null("SkillCastSfx") != null:
			failures.append("%s cast sound placeholder should self-clean after playback" % c["skill"])
		scene.queue_free()
		await process_frame
	await _check_secondary_skill_cast_slot_feedback(failures)

func _check_secondary_skill_cast_slot_feedback(failures: Array[String]) -> void:
	var scene := _make_scene("SecondarySkillSlotFeedbackScene")
	var player := await _make_player(scene, "blade_warden")
	player.skill_alt = {"id": "lunge", "cost": 0, "cooldown": 1.5}
	var sprite := player.get_node("Sprite") as AnimatedSprite2D
	player.call("_try_skill_alt")
	if sprite.animation != "attack":
		failures.append("secondary skill cast should briefly play the local player attack animation")
	if str(player.get_meta("last_sprite_action_anim", "")) != "attack":
		failures.append("secondary skill cast should tag player sprite action metadata")
	var sfx := player.get_node_or_null("SkillCastSfx")
	if sfx == null:
		failures.append("secondary skill cast should create sound placeholder")
	else:
		if str(sfx.get_meta("skill_slot", "")) != "secondary":
			failures.append("secondary skill cast sound should tag secondary slot")
		if str(player.get_meta("last_skill_cast_slot", "")) != "secondary":
			failures.append("secondary skill cast should store last skill cast slot metadata")
	var fx := _child_named(scene, "CombatFxSkillCast")
	if fx == null:
		failures.append("secondary skill should spawn cast VFX")
	elif str(fx.get_meta("skill_slot", "")) != "secondary":
		failures.append("secondary skill cast VFX should tag secondary slot")
	scene.queue_free()
	await process_frame

func _check_skill_blocked_feedback(failures: Array[String]) -> void:
	var scene := _make_scene("SkillBlockedFeedbackScene")
	var player := await _make_player(scene, "blade_warden")
	if not _has_signal(player, "skill_blocked"):
		failures.append("Player should expose skill_blocked for blocked skill input feedback")
	else:
		var blocked_events: Array[Dictionary] = []
		player.connect("skill_blocked", func(skill_id: String, reason: String, detail: Dictionary) -> void:
			blocked_events.append({
				"skill_id": skill_id,
				"reason": reason,
				"detail": detail,
			}))
		player.skill = {"id": "wind_edge", "cost": 999, "cooldown": 2.0}
		player.resource = 0.0
		player.call("_try_skill")
		await process_frame
		if blocked_events.is_empty():
			failures.append("blocked skill input should emit skill_blocked")
		else:
			var event: Dictionary = blocked_events[0]
			if str(event.get("skill_id", "")) != "wind_edge":
				failures.append("skill_blocked should include skill id")
			if str(event.get("reason", "")) != "resource":
				failures.append("skill_blocked should explain missing resource")
			var detail: Dictionary = event.get("detail", {})
			if int(detail.get("cost", 0)) != 999:
				failures.append("skill_blocked resource detail should include skill cost")
			if str(player.get_meta("last_skill_blocked_reason", "")) != "resource":
				failures.append("Player should store last blocked skill reason metadata")
			if str(player.get_meta("last_skill_blocked_id", "")) != "wind_edge":
				failures.append("Player should store last blocked skill id metadata")

		blocked_events.clear()
		player.resource = 999.0
		player.skill = {"id": "wind_edge", "cost": 0, "cooldown": 2.0}
		player.call("_try_skill")
		player.call("_try_skill")
		await process_frame
		if blocked_events.is_empty():
			failures.append("skill input during cooldown should emit skill_blocked")
		else:
			var event: Dictionary = blocked_events[0]
			if str(event.get("reason", "")) != "cooldown":
				failures.append("skill_blocked should explain active cooldown")
			var detail: Dictionary = event.get("detail", {})
			if float(detail.get("cooldown_left", 0.0)) <= 0.0:
				failures.append("skill_blocked cooldown detail should include time left")
	Engine.time_scale = 1.0

	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(hud)
	await process_frame
	hud.bind(player, ctrl)
	await process_frame
	if not hud.has_method("_on_skill_blocked"):
		failures.append("HUD should handle blocked skill feedback")
	else:
		hud.call("_on_skill_blocked", "wind_edge", "cooldown", {
			"cooldown_left": 1.3,
			"cooldown_total": 2.0,
			"slot": "primary",
		})
		await process_frame
		var flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("blocked skill should show HUD flash feedback")
		elif not flash.text.contains("Blocked: Wind Edge") or not flash.text.contains("1.3s"):
			failures.append("blocked skill flash should name skill and cooldown time")
		var sfx := hud.get_node_or_null("SkillBlockedSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("blocked skill should create sound placeholder")
		else:
			if str(sfx.get_meta("skill_blocked_id", "")) != "wind_edge":
				failures.append("blocked skill sound should store skill id metadata")
			if str(sfx.get_meta("skill_blocked_reason", "")) != "cooldown":
				failures.append("blocked skill sound should store blocked reason metadata")
			if str(sfx.get_meta("skill_blocked_sound_id", "")) != "skill_blocked":
				failures.append("blocked skill sound should expose blocked cue id")
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("blocked skill sound should come from AudioCueDB")
			if sfx.stream == null:
				failures.append("blocked skill sound should assign an audio stream")
			if DisplayServer.get_name() == "headless" \
					and not bool(sfx.get_meta("headless_playback_skipped", false)):
				failures.append("blocked skill sound should skip playback in headless smoke")
		hud.call("_on_skill_blocked", "summon_wisp", "soul_slots", {
			"slots_used": 4,
			"slot_limit": 4,
			"slot": "primary",
		})
		await process_frame
		flash = hud.get_node_or_null("SkillCastFlashLabel") as Label
		if flash == null or not flash.text.contains("Soul Slots 4/4"):
			failures.append("full Soul Slots should show readable blocked skill feedback")
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	scene.queue_free()
	await process_frame

func _check_sacrifice_no_pet_block(failures: Array[String]) -> void:
	for summon in root.get_tree().get_nodes_in_group("player_summons"):
		if is_instance_valid(summon):
			summon.queue_free()
	await process_frame
	var scene := _make_scene("SacrificeNoPetBlockScene")
	var player := await _make_player(scene, "soulbinder")
	player.set_physics_process(false)
	player.resource = 20.0
	player.skill_alt = {"id": "sacrifice", "cost": 5, "cooldown": 3.0}
	var blocked_events: Array[Dictionary] = []
	var cast_events: Array[String] = []
	player.skill_blocked.connect(func(skill_id: String, reason: String, detail: Dictionary) -> void:
		blocked_events.append({
			"skill_id": skill_id,
			"reason": reason,
			"detail": detail,
		}))
	player.skill_cast.connect(func(skill_id: String, _cooldown: float) -> void:
		cast_events.append(skill_id))
	player.call("_try_skill_alt")
	await process_frame
	if blocked_events.is_empty():
		failures.append("sacrifice with no summons should emit skill_blocked")
	else:
		var event: Dictionary = blocked_events[0]
		var detail: Dictionary = event.get("detail", {})
		if str(event.get("skill_id", "")) != "sacrifice":
			failures.append("no-pet sacrifice block should identify sacrifice")
		if str(event.get("reason", "")) != "no_summon":
			failures.append("no-pet sacrifice block should use no_summon reason")
		if str(detail.get("slot", "")) != "secondary":
			failures.append("no-pet sacrifice block should tag secondary slot")
		if int(detail.get("summon_count", -1)) != 0:
			failures.append("no-pet sacrifice block should expose zero summons")
	if not cast_events.is_empty():
		failures.append("blocked sacrifice should not emit skill_cast")
	if not is_equal_approx(player.resource, 20.0):
		failures.append("blocked sacrifice should not spend resource")
	if str(player.get_meta("last_skill_blocked_reason", "")) != "no_summon":
		failures.append("Player should store no_summon blocked reason metadata")

	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.call("_on_skill_blocked", "sacrifice", "no_summon", {
		"slot": "secondary",
		"summon_count": 0,
	})
	await process_frame
	var flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
	if flash == null or not flash.text.contains("Need summon"):
		failures.append("no-pet sacrifice should show readable HUD blocked feedback")
	hud.queue_free()
	scene.queue_free()
	await process_frame

func _check_hack_no_trap_block(failures: Array[String]) -> void:
	for trap in root.get_tree().get_nodes_in_group("room_traps"):
		if is_instance_valid(trap):
			trap.queue_free()
	await process_frame
	var scene := _make_scene("HackNoTrapBlockScene")
	var player := await _make_player(scene, "tinkerer")
	player.set_physics_process(false)
	player.resource = 20.0
	player.skill_alt = {"id": "hack", "cost": 5, "cooldown": 3.0}
	var blocked_events: Array[Dictionary] = []
	var cast_events: Array[String] = []
	player.skill_blocked.connect(func(skill_id: String, reason: String, detail: Dictionary) -> void:
		blocked_events.append({
			"skill_id": skill_id,
			"reason": reason,
			"detail": detail,
		}))
	player.skill_cast.connect(func(skill_id: String, _cooldown: float) -> void:
		cast_events.append(skill_id))
	player.call("_try_skill_alt")
	await process_frame
	if blocked_events.is_empty():
		failures.append("hack with no nearby traps should emit skill_blocked")
	else:
		var event: Dictionary = blocked_events[0]
		var detail: Dictionary = event.get("detail", {})
		if str(event.get("skill_id", "")) != "hack":
			failures.append("no-trap hack block should identify hack")
		if str(event.get("reason", "")) != "no_trap":
			failures.append("no-trap hack block should use no_trap reason")
		if str(detail.get("slot", "")) != "secondary":
			failures.append("no-trap hack block should tag secondary slot")
		if int(detail.get("trap_count", -1)) != 0:
			failures.append("no-trap hack block should expose zero traps")
	if not cast_events.is_empty():
		failures.append("blocked hack should not emit skill_cast")
	if not is_equal_approx(player.resource, 20.0):
		failures.append("blocked hack should not spend resource")
	if str(player.get_meta("last_skill_blocked_reason", "")) != "no_trap":
		failures.append("Player should store no_trap blocked reason metadata")

	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.call("_on_skill_blocked", "hack", "no_trap", {
		"slot": "secondary",
		"trap_count": 0,
	})
	await process_frame
	var flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
	if flash == null or not flash.text.contains("Need trap"):
		failures.append("no-trap hack should show readable HUD blocked feedback")
	hud.queue_free()
	scene.queue_free()
	await process_frame

func _check_dash_blocked_feedback(failures: Array[String]) -> void:
	var scene := _make_scene("DashBlockedFeedbackScene")
	var player := await _make_player(scene, "blade_warden")
	if not _has_signal(player, "dash_blocked"):
		failures.append("Player should expose dash_blocked for blocked dash input feedback")
	elif not player.has_method("_try_dash"):
		failures.append("Player should route dash input through _try_dash for blocked dash feedback")
	else:
		var blocked_events: Array[Dictionary] = []
		player.connect("dash_blocked", func(reason: String, detail: Dictionary) -> void:
			blocked_events.append({
				"reason": reason,
				"detail": detail,
			}))
		player.set("_dash_cd_left", 0.8)
		player.call("_try_dash", Vector2.RIGHT)
		await process_frame
		if blocked_events.is_empty():
			failures.append("dash input during cooldown should emit dash_blocked")
		else:
			var event: Dictionary = blocked_events[0]
			if str(event.get("reason", "")) != "cooldown":
				failures.append("dash_blocked should explain active cooldown")
			var detail: Dictionary = event.get("detail", {})
			if float(detail.get("cooldown_left", 0.0)) <= 0.0:
				failures.append("dash_blocked cooldown detail should include time left")
			if str(player.get_meta("last_dash_blocked_reason", "")) != "cooldown":
				failures.append("Player should store last blocked dash reason metadata")

	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(hud)
	await process_frame
	if not hud.has_method("_on_dash_blocked"):
		failures.append("HUD should handle blocked dash feedback")
	else:
		hud.call("_on_dash_blocked", "cooldown", {
			"cooldown_left": 0.8,
			"cooldown_total": 1.2,
		})
		await process_frame
		var flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("blocked dash should show HUD flash feedback")
		elif not flash.text.contains("Dash blocked") or not flash.text.contains("0.8s"):
			failures.append("blocked dash flash should name dash and cooldown time")
		var sfx := hud.get_node_or_null("DashBlockedSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("blocked dash should create sound placeholder")
		else:
			if str(sfx.get_meta("dash_blocked_reason", "")) != "cooldown":
				failures.append("blocked dash sound should store blocked reason metadata")
			if str(sfx.get_meta("dash_blocked_sound_id", "")) != "skill_blocked":
				failures.append("blocked dash sound should reuse blocked cue id")
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("blocked dash sound should come from AudioCueDB")
			if sfx.stream == null:
				failures.append("blocked dash sound should assign an audio stream")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	if not hud_source.contains("player.dash_blocked.connect(_on_dash_blocked)"):
		failures.append("HUD bind should connect player dash_blocked signal")
	hud.queue_free()
	ctrl.queue_free()
	player.queue_free()
	scene.queue_free()
	await process_frame

func _check_weapon_attack_blocked_feedback(failures: Array[String]) -> void:
	var scene := _make_scene("WeaponAttackBlockedFeedbackScene")
	var magic_player := await _make_player(scene, "arcanist")
	magic_player.apply_class(PlayerClassDB.get_class_data("arcanist"), "fire", "apprentice_staff")
	if not _has_signal(magic_player, "weapon_attack_blocked"):
		failures.append("Player should expose weapon_attack_blocked for blocked weapon input feedback")
	else:
		var blocked_events: Array[Dictionary] = []
		magic_player.connect("weapon_attack_blocked",
				func(weapon_id: String, reason: String, detail: Dictionary) -> void:
			blocked_events.append({
				"weapon_id": weapon_id,
				"reason": reason,
				"detail": detail,
			}))
		var magic_weapon := magic_player.current_weapon()
		var cost := float(magic_weapon.call("resource_cost")) if magic_weapon != null else 0.0
		magic_player.resource = maxf(cost - 1.0, 0.0)
		if magic_weapon != null and magic_weapon.try_attack(magic_player.global_position, Vector2.RIGHT):
			failures.append("magic weapon should stay blocked without enough resource")
		await process_frame
		if blocked_events.is_empty():
			failures.append("blocked magic weapon attack should emit weapon_attack_blocked")
		else:
			var event: Dictionary = blocked_events[0]
			if str(event.get("weapon_id", "")) != "apprentice_staff":
				failures.append("weapon_attack_blocked should include weapon id")
			if str(event.get("reason", "")) != "resource":
				failures.append("weapon_attack_blocked should explain missing resource")
			var detail: Dictionary = event.get("detail", {})
			if float(detail.get("cost", 0.0)) <= 0.0:
				failures.append("weapon_attack_blocked resource detail should include weapon cost")
			if str(detail.get("resource_type", "")) != "mana":
				failures.append("weapon_attack_blocked should include readable resource type")
			if str(magic_player.get_meta("last_weapon_attack_blocked_reason", "")) != "resource":
				failures.append("Player should store last blocked weapon reason metadata")
			if str(magic_player.get_meta("last_weapon_attack_blocked_id", "")) != "apprentice_staff":
				failures.append("Player should store last blocked weapon id metadata")

	var cooldown_player := await _make_player(scene, "blade_warden")
	if _has_signal(cooldown_player, "weapon_attack_blocked"):
		var cooldown_events: Array[Dictionary] = []
		cooldown_player.connect("weapon_attack_blocked",
				func(weapon_id: String, reason: String, detail: Dictionary) -> void:
			cooldown_events.append({
				"weapon_id": weapon_id,
				"reason": reason,
				"detail": detail,
			}))
		var cooldown_weapon := cooldown_player.current_weapon()
		if cooldown_weapon != null:
			cooldown_weapon.try_attack(cooldown_player.global_position, Vector2.RIGHT)
			cooldown_weapon.try_attack(cooldown_player.global_position, Vector2.RIGHT)
			cooldown_weapon.try_attack(cooldown_player.global_position, Vector2.RIGHT)
			await process_frame
			if cooldown_events.is_empty():
				failures.append("weapon attack during cooldown should emit weapon_attack_blocked")
			else:
				var event: Dictionary = cooldown_events[0]
				if str(event.get("reason", "")) != "cooldown":
					failures.append("weapon_attack_blocked should explain weapon cooldown")
				var detail: Dictionary = event.get("detail", {})
				if float(detail.get("cooldown_left", 0.0)) <= 0.0:
					failures.append("weapon_attack_blocked cooldown detail should include time left")
				if cooldown_events.size() > 1:
					failures.append("weapon cooldown blocked feedback should throttle repeated held attack")

	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(hud)
	await process_frame
	if not hud.has_method("_on_weapon_attack_blocked"):
		failures.append("HUD should handle blocked weapon attack feedback")
	else:
		hud.call("_on_weapon_attack_blocked", "apprentice_staff", "resource", {
			"weapon_name": "Gay Hoc Do",
			"cost": 12.0,
			"resource": 4.0,
			"resource_type": "mana",
		})
		await process_frame
		var flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
		if flash == null or not flash.visible:
			failures.append("blocked weapon attack should show HUD flash feedback")
		elif not flash.text.contains("Blocked: Gay Hoc Do") or not flash.text.contains("Need 12 MP"):
			failures.append("blocked weapon resource flash should name weapon and resource cost")
		var sfx := hud.get_node_or_null("WeaponBlockedSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("blocked weapon attack should create sound placeholder")
		else:
			if str(sfx.get_meta("weapon_blocked_id", "")) != "apprentice_staff":
				failures.append("blocked weapon sound should store weapon id metadata")
			if str(sfx.get_meta("weapon_blocked_reason", "")) != "resource":
				failures.append("blocked weapon sound should store blocked reason metadata")
			if str(sfx.get_meta("weapon_blocked_sound_id", "")) != "skill_blocked":
				failures.append("blocked weapon sound should reuse blocked cue id")
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("blocked weapon sound should come from AudioCueDB")
			if sfx.stream == null:
				failures.append("blocked weapon sound should assign an audio stream")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	if not hud_source.contains("player.weapon_attack_blocked.connect(_on_weapon_attack_blocked)"):
		failures.append("HUD bind should connect player weapon_attack_blocked signal")
	hud.queue_free()
	ctrl.queue_free()
	magic_player.queue_free()
	cooldown_player.queue_free()
	scene.queue_free()
	await process_frame

func _check_hud_cooldown_icon(failures: Array[String]) -> void:
	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	var player := Player.new()
	var hud := HUD.new()
	root.add_child(ctrl)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	hud.bind(player, ctrl)
	await process_frame
	var icon := hud.get_node_or_null("SkillCooldownIcon") as ColorRect
	var fill := hud.get_node_or_null("SkillCooldownFill") as ColorRect
	var badge := hud.get_node_or_null("SkillCooldownBadge") as Label
	var alt_badge := hud.get_node_or_null("SecondarySkillCooldownBadge") as Label
	var skill_label := hud.get_node_or_null("SkillLabel") as Label
	var alt_skill_label := hud.get_node_or_null("SecondarySkillLabel") as Label
	if icon == null:
		failures.append("HUD should expose a skill cooldown icon")
	if fill == null:
		failures.append("HUD should expose a skill cooldown fill")
	if badge == null or badge.text != "E":
		failures.append("HUD should expose an E badge for the primary skill cooldown")
	if alt_badge == null or alt_badge.text != "C":
		failures.append("HUD should expose a C badge for the secondary skill cooldown")
	if skill_label == null:
		failures.append("HUD should expose a named primary SkillLabel node")
	if alt_skill_label == null:
		failures.append("HUD should expose a named SecondarySkillLabel node")
	var cast_profile: Dictionary = CombatFxScript.skill_feedback_profile("wind_edge")
	var cast_impact_cue := str(cast_profile.get("impact_cue", ""))
	hud.call("_on_skill_cast", "wind_edge", 1.2)
	await process_frame
	var cast_flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
	if cast_flash == null or not cast_flash.visible:
		failures.append("skill cast should show HUD impact flash")
	else:
		if not cast_flash.text.contains(cast_impact_cue):
			failures.append("skill cast HUD flash should show readable impact cue")
		if str(cast_flash.get_meta("skill_impact_cue", "")) != cast_impact_cue:
			failures.append("skill cast HUD flash should tag readable impact cue")
	var cast_pulse := hud.get_node_or_null("SkillCastPulse") as ColorRect
	if cast_pulse == null:
		failures.append("skill cast should show HUD pulse")
	elif str(cast_pulse.get_meta("skill_impact_cue", "")) != cast_impact_cue:
		failures.append("skill cast HUD pulse should tag readable impact cue")
	hud.call("_on_skill_cooldown_changed", "wind_edge", 3.0, 6.0)
	await process_frame
	if skill_label != null:
		if not skill_label.text.contains("Cost 20") or not skill_label.text.contains("CD 6.0s"):
			failures.append("primary skill label should show skill cost and cooldown contract")
		_assert_skill_cooldown_label_contract(
			skill_label, "wind_edge", "primary", "E", 20, 3.0, 6.0, false, failures)
	hud.call("_on_skill_cooldown_changed", "lunge", 0.0, 4.0)
	await process_frame
	if alt_skill_label != null:
		if not alt_skill_label.text.contains("READY") or not alt_skill_label.text.contains("Cost 15"):
			failures.append("secondary skill label should show ready state and skill cost")
		_assert_skill_cooldown_label_contract(
			alt_skill_label, "lunge", "secondary", "C", 15, 0.0, 4.0, true, failures)
	hud.call("_on_skill_cooldown_changed", "earthbreaker", 1.0, 2.0)
	await process_frame
	if not _has_label_containing(hud, "Earthbreaker"):
		failures.append("HUD should show readable active skill cooldown text")
	var profile: Dictionary = CombatFxScript.skill_feedback_profile("earthbreaker")
	for node in [icon, fill]:
		if node == null:
			continue
		if str(node.get_meta("skill_id", "")) != "earthbreaker":
			failures.append("%s should tag the active cooldown skill id" % node.name)
		if str(node.get_meta("skill_input_action", "")) != "skill":
			failures.append("%s should tag primary skill input action" % node.name)
		if str(node.get_meta("skill_key_label", "")) != "E":
			failures.append("%s should tag primary skill key label" % node.name)
		if str(node.get_meta("skill_ready_text", "")) != "1.0s":
			failures.append("%s should expose readable primary cooldown text" % node.name)
		if str(node.get_meta("skill_family", "")) != str(profile.get("family", "")):
			failures.append("%s should tag the active cooldown skill family" % node.name)
		if str(node.get_meta("skill_style", "")) != str(profile.get("style", "")):
			failures.append("%s should tag the active cooldown skill style" % node.name)
		if str(node.get_meta("skill_slot", "")) != "primary":
			failures.append("%s should tag the primary skill slot" % node.name)
		if str(node.get_meta("skill_cast_label", "")) != str(profile.get("cast_label", "")):
			failures.append("%s should tag skill cast label metadata" % node.name)
		if str(node.get_meta("skill_cooldown_icon", "")) != str(profile.get("cooldown_icon", "")):
			failures.append("%s should tag skill cooldown icon metadata" % node.name)
		if str(node.get_meta("skill_feedback_hint", "")) != str(profile.get("feedback_hint", "")):
			failures.append("%s should tag skill feedback hint metadata" % node.name)
		if str(node.get_meta("skill_feel_tier", "")) != str(profile.get("feel_tier", "")):
			failures.append("%s should tag skill feel tier metadata" % node.name)
		if str(node.get_meta("skill_cooldown_hint", "")) != str(profile.get("cooldown_hint", "")):
			failures.append("%s should tag skill cooldown hint metadata" % node.name)
		if str(node.get_meta("cooldown_state", "")) != "cooling":
			failures.append("%s should tag cooling state while cooldown is active" % node.name)
		if not is_equal_approx(float(node.get_meta("cooldown_ratio", -1.0)), 0.5):
			failures.append("%s should tag active cooldown ratio" % node.name)
	if fill != null and not _colors_close(fill.color, profile.get("color", Color.WHITE)):
		failures.append("HUD skill cooldown fill should use the skill feedback profile color")
	for node in [icon, fill, badge, skill_label]:
		if node != null:
			_assert_tooltip_tokens(node, ["E", "Earthbreaker", "1.0s"], failures)
	_assert_cooldown_sprite_icon(icon, "SkillCooldownSprite", "hammer", "weapon_hammer", failures)
	hud.call("_on_skill_cooldown_changed", "earthbreaker", 0.0, 2.0)
	await process_frame
	if icon != null and str(icon.get_meta("cooldown_state", "")) != "ready":
		failures.append("HUD primary skill icon should tag ready state when cooldown reaches zero")
	if fill != null and not is_equal_approx(float(fill.get_meta("cooldown_ratio", -1.0)), 0.0):
		failures.append("HUD primary skill fill should tag zero cooldown ratio when ready")
	var ready_flash := hud.get_node_or_null("SkillCastFlashLabel") as Label
	if ready_flash == null or not ready_flash.visible:
		failures.append("skill cooldown completion should show HUD ready flash")
	else:
		if not ready_flash.text.contains("E Ready") or not ready_flash.text.contains("Earthbreaker"):
			failures.append("primary skill ready flash should include E slot and readable skill name")
		if str(ready_flash.get_meta("hud_flash_kind", "")) != "skill_ready":
			failures.append("skill ready flash should store skill_ready kind metadata")
		if str(ready_flash.get_meta("skill_ready_id", "")) != "earthbreaker":
			failures.append("skill ready flash should store ready skill id metadata")
		if str(ready_flash.get_meta("skill_ready_slot", "")) != "primary":
			failures.append("skill ready flash should store primary slot metadata")
		if str(ready_flash.get_meta("skill_ready_input_action", "")) != "skill":
			failures.append("skill ready flash should store primary input action metadata")
		if str(ready_flash.get_meta("skill_ready_key_label", "")) != "E":
			failures.append("skill ready flash should store primary key label metadata")
		if str(ready_flash.get_meta("skill_ready_cooldown_hint", "")) != str(profile.get("cooldown_hint", "")):
			failures.append("skill ready flash should store cooldown hint metadata")
		if str(ready_flash.get_meta("skill_ready_feel_tier", "")) != str(profile.get("feel_tier", "")):
			failures.append("skill ready flash should store feel tier metadata")
		if str(ready_flash.get_meta("skill_ready_sound_id", "")) != "skill_ready":
			failures.append("skill ready flash should expose ready sound cue id")
	var ready_sfx := hud.get_node_or_null("SkillReadySfx") as AudioStreamPlayer
	if ready_sfx == null:
		failures.append("skill cooldown completion should create ready sound placeholder")
	else:
		if str(ready_sfx.get_meta("skill_ready_input_action", "")) != "skill":
			failures.append("skill ready sound should store input action metadata")
		if str(ready_sfx.get_meta("skill_ready_key_label", "")) != "E":
			failures.append("skill ready sound should store key label metadata")
		if str(ready_sfx.get_meta("skill_ready_cooldown_hint", "")) != str(profile.get("cooldown_hint", "")):
			failures.append("skill ready sound should store cooldown hint metadata")
	hud.call("_on_skill_cooldown_changed", "lunge", 0.8, 4.0)
	await process_frame
	var alt_icon := hud.get_node_or_null("SecondarySkillCooldownIcon") as ColorRect
	var alt_fill := hud.get_node_or_null("SecondarySkillCooldownFill") as ColorRect
	_assert_cooldown_sprite_icon(alt_icon, "SecondarySkillCooldownSprite", "dash", "weapon_spear", failures)
	for node in [alt_icon, alt_fill, alt_badge]:
		if node == null:
			continue
		if str(node.get_meta("skill_slot", "")) != "secondary":
			failures.append("%s should tag the secondary skill slot" % node.name)
		if str(node.get_meta("skill_input_action", "")) != "skill_alt":
			failures.append("%s should tag secondary skill input action" % node.name)
		if str(node.get_meta("skill_key_label", "")) != "C":
			failures.append("%s should tag secondary skill key label" % node.name)
		if str(node.get_meta("skill_ready_text", "")) != "0.8s":
			failures.append("%s should expose readable secondary cooldown text" % node.name)
		if str(node.get_meta("cooldown_state", "")) != "cooling":
			failures.append("%s should tag cooling state for secondary cooldown" % node.name)
	if alt_fill != null and not is_equal_approx(float(alt_fill.get_meta("cooldown_ratio", -1.0)), 0.2):
		failures.append("HUD secondary fill should tag secondary cooldown ratio")
	for node in [alt_icon, alt_fill, alt_badge, alt_skill_label]:
		if node != null:
			_assert_tooltip_tokens(node, ["C", "Lunge", "0.8s"], failures)
	hud.call("_on_dash_cooldown_changed", 0.5, 1.0)
	await process_frame
	var dash_icon := hud.get_node_or_null("DashCooldownIcon") as ColorRect
	var dash_fill := hud.get_node_or_null("DashCooldownFill") as ColorRect
	_assert_cooldown_sprite_icon(dash_icon, "DashCooldownSprite", "dash", "weapon_spear", failures)
	for node in [dash_icon, dash_fill]:
		if node != null:
			_assert_tooltip_tokens(node, ["Space", "Dash", "0.5s"], failures)
	hud.queue_free()
	player.queue_free()
	ctrl.queue_free()
	await process_frame

func _assert_skill_cooldown_label_contract(
		label: Label,
		skill_id: String,
		slot: String,
		input_label: String,
		cost: int,
		left: float,
		total: float,
		ready: bool,
		failures: Array[String],
) -> void:
	if str(label.get_meta("skill_id", "")) != skill_id:
		failures.append("%s should tag skill id %s" % [label.name, skill_id])
	if str(label.get_meta("skill_slot", "")) != slot:
		failures.append("%s should tag skill slot %s" % [label.name, slot])
	if str(label.get_meta("skill_input_label", "")) != input_label:
		failures.append("%s should tag input label %s" % [label.name, input_label])
	if str(label.get_meta("skill_input_action", "")) != ("skill_alt" if slot == "secondary" else "skill"):
		failures.append("%s should tag input action for %s" % [label.name, slot])
	if str(label.get_meta("skill_key_label", "")) != input_label:
		failures.append("%s should tag key label %s" % [label.name, input_label])
	var expected_ready_text := "READY" if ready else "%.1fs" % left
	if str(label.get_meta("skill_ready_text", "")) != expected_ready_text:
		failures.append("%s should tag ready text %s" % [label.name, expected_ready_text])
	if int(label.get_meta("skill_cost", -1)) != cost:
		failures.append("%s should tag skill cost %d" % [label.name, cost])
	if not is_equal_approx(float(label.get_meta("skill_cooldown_left", -1.0)), left):
		failures.append("%s should tag cooldown left %.1f" % [label.name, left])
	if not is_equal_approx(float(label.get_meta("skill_cooldown_total", -1.0)), total):
		failures.append("%s should tag cooldown total %.1f" % [label.name, total])
	if bool(label.get_meta("skill_ready", not ready)) != ready:
		failures.append("%s should tag skill_ready %s" % [label.name, ready])

func _assert_cooldown_sprite_icon(
		parent: Node,
		node_name: String,
		expected_token: String,
		expected_sprite: String,
		failures: Array[String],
) -> void:
	if parent == null:
		return
	var sprite := parent.get_node_or_null(node_name) as TextureRect
	if sprite == null:
		failures.append("%s should expose a sprite child" % node_name)
		return
	if sprite.texture == null:
		failures.append("%s should assign a sprite texture" % node_name)
	if str(sprite.get_meta("cooldown_icon_token", "")) != expected_token:
		failures.append("%s should store cooldown icon token metadata" % node_name)
	if str(sprite.get_meta("icon_sprite_name", "")) != expected_sprite:
		failures.append("%s should use %s" % [node_name, expected_sprite])

func _assert_tooltip_tokens(node: Control, tokens: Array[String], failures: Array[String]) -> void:
	if node.tooltip_text.strip_edges() == "":
		failures.append("%s should expose a HUD tooltip" % node.name)
		return
	for token in tokens:
		if not node.tooltip_text.contains(token):
			failures.append("%s tooltip should include %s" % [node.name, token])

func _check_hud_class_resource_summary(failures: Array[String]) -> void:
	var scene := _make_scene("ClassResourceHUDSmoke")
	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	scene.add_child(ctrl)
	var player := await _make_player(scene, "soulbinder")
	player.skill = {"id": "summon_wisp", "cost": 0, "cooldown": 0.1}
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, ctrl)
	await process_frame
	var label := hud.get_node_or_null("ClassResourceLabel") as Label
	if label == null:
		failures.append("HUD should expose a class resource label for Soul Slots")
	else:
		if not label.visible:
			failures.append("Soul Slot class resource label should be visible for Soulbinder")
		if not label.text.contains("Soul Slots 0/4"):
			failures.append("HUD should show empty Soul Slots before summoning")
		_expect_class_resource_api(player, label, "soul_slots", "Soul Slots 0/4", 0, 4, failures)
		if int(label.get_meta("soul_slots_used", -1)) != 0:
			failures.append("Soul Slot HUD metadata should start at 0 used")
		if int(label.get_meta("soul_slot_limit", -1)) != 4:
			failures.append("Soul Slot HUD metadata should expose limit 4")
	player.call("_try_skill")
	await process_frame
	var wisp := scene.get_node_or_null("SummonedWisp")
	if wisp == null:
		failures.append("summon_wisp should spawn a readable summon node")
	else:
		if float(wisp.get_meta("attack_radius_px", 0.0)) < 100.0:
			failures.append("summon_wisp should expose attack radius metadata for playtest readability")
		if float(wisp.get_meta("attack_interval_seconds", 0.0)) <= 0.0:
			failures.append("summon_wisp should expose attack interval metadata for balance review")
	if label != null:
		if not label.text.contains("Soul Slots 1/4"):
			failures.append("HUD should refresh Soul Slots after summon_wisp")
		_expect_class_resource_api(player, label, "soul_slots", "Soul Slots 1/4", 1, 4, failures)
		if int(label.get_meta("soul_slots_used", -1)) != 1:
			failures.append("Soul Slot HUD metadata should update after summon_wisp")
	hud.queue_free()
	scene.queue_free()
	await process_frame

	scene = _make_scene("TurretResourceHUDSmoke")
	ctrl = FloorController.new()
	room = RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	scene.add_child(ctrl)
	player = await _make_player(scene, "tinkerer")
	player.skill = {"id": "mini_turret", "cost": 0, "cooldown": 0.1}
	hud = HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, ctrl)
	await process_frame
	label = hud.get_node_or_null("ClassResourceLabel") as Label
	if label == null:
		failures.append("HUD should expose a class resource label for Turrets")
	else:
		if not label.visible:
			failures.append("Turret class resource label should be visible for Tinkerer")
		if not label.text.contains("Turrets 0/2"):
			failures.append("HUD should show empty Turrets before deploying")
		_expect_class_resource_api(player, label, "turrets", "Turrets 0/2", 0, 2, failures)
		if int(label.get_meta("turrets_used", -1)) != 0:
			failures.append("Turret HUD metadata should start at 0 used")
		if int(label.get_meta("turret_limit", -1)) != 2:
			failures.append("Turret HUD metadata should expose limit 2")
	player.call("_try_skill")
	await process_frame
	var turret := scene.get_node_or_null("MiniTurret")
	if turret == null:
		failures.append("mini_turret should spawn a readable summon node")
	else:
		if float(turret.get_meta("attack_radius_px", 0.0)) < 120.0:
			failures.append("mini_turret should expose attack radius metadata for playtest readability")
		if float(turret.get_meta("attack_interval_seconds", 0.0)) <= 0.0:
			failures.append("mini_turret should expose attack interval metadata for balance review")
	if label != null:
		if not label.text.contains("Turrets 1/2"):
			failures.append("HUD should refresh Turrets after mini_turret")
		_expect_class_resource_api(player, label, "turrets", "Turrets 1/2", 1, 2, failures)
		if int(label.get_meta("turrets_used", -1)) != 1:
			failures.append("Turret HUD metadata should update after mini_turret")
	hud.queue_free()
	scene.queue_free()
	await process_frame

	scene = _make_scene("SnareResourceHUDSmoke")
	ctrl = FloorController.new()
	room = RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	scene.add_child(ctrl)
	player = await _make_player(scene, "ranger")
	player.skill = {"id": "snare_trap", "cost": 0, "cooldown": 0.1}
	hud = HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, ctrl)
	await process_frame
	label = hud.get_node_or_null("ClassResourceLabel") as Label
	if label == null:
		failures.append("HUD should expose a class resource label for Snares")
	else:
		if not label.visible:
			failures.append("Snare class resource label should be visible for Ranger")
		if not label.text.contains("Snares 0/2"):
			failures.append("HUD should show empty Snares before placing")
		_expect_class_resource_api(player, label, "snares", "Snares 0/2", 0, 2, failures)
		if int(label.get_meta("snares_used", -1)) != 0:
			failures.append("Snare HUD metadata should start at 0 used")
		if int(label.get_meta("snare_limit", -1)) != 2:
			failures.append("Snare HUD metadata should expose limit 2")
	player.call("_try_skill")
	await process_frame
	if label != null:
		if not label.text.contains("Snares 1/2"):
			failures.append("HUD should refresh Snares after snare_trap")
		_expect_class_resource_api(player, label, "snares", "Snares 1/2", 1, 2, failures)
		if int(label.get_meta("snares_used", -1)) != 1:
			failures.append("Snare HUD metadata should update after snare_trap")
	hud.queue_free()
	scene.queue_free()
	await process_frame

	scene = _make_scene("GunnerRoundsResourceHUDSmoke")
	ctrl = FloorController.new()
	room = RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	scene.add_child(ctrl)
	player = await _make_player(scene, "gunner")
	player.pickup_weapon("scrap_pistol")
	player.skill_alt = {"id": "special_rounds", "cost": 0, "cooldown": 0.1}
	hud = HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, ctrl)
	await process_frame
	label = hud.get_node_or_null("ClassResourceLabel") as Label
	if label == null:
		failures.append("HUD should expose a class resource label for Gunner rounds")
	else:
		if not label.visible:
			failures.append("Rounds class resource label should be visible for Gunner")
		if not label.text.contains("Rounds 0/6"):
			failures.append("HUD should show empty Rounds before arming")
		_expect_class_resource_api(player, label, "rounds", "Rounds 0/6", 0, 6, failures)
		if int(label.get_meta("rounds_left", -1)) != 0:
			failures.append("Rounds HUD metadata should start at 0")
		if int(label.get_meta("round_limit", -1)) != 6:
			failures.append("Rounds HUD metadata should expose limit 6")
	player.call("_try_skill_alt")
	await process_frame
	if label != null:
		if not label.text.contains("Rounds 6/6"):
			failures.append("HUD should refresh Rounds after special_rounds")
		_expect_class_resource_api(player, label, "rounds", "Rounds 6/6", 6, 6, failures)
		if int(label.get_meta("rounds_left", -1)) != 6:
			failures.append("Rounds HUD metadata should update after special_rounds")
	var weapon := player.current_weapon()
	if weapon != null:
		weapon.set("_cd_left", 0.0)
		weapon.try_attack(player.global_position, Vector2.RIGHT)
		await process_frame
		if label != null:
			if not label.text.contains("Rounds 5/6"):
				failures.append("HUD should refresh Rounds after one shot")
			_expect_class_resource_api(player, label, "rounds", "Rounds 5/6", 5, 6, failures)
			if int(label.get_meta("rounds_left", -1)) != 5:
				failures.append("Rounds HUD metadata should decrement after one shot")
	hud.queue_free()
	scene.queue_free()
	await process_frame

func _expect_class_resource_api(
	player: Node,
	label: Label,
	kind: String,
	text: String,
	used: int,
	limit: int,
	failures: Array[String]
) -> void:
	if not player.has_method("class_resource_summary"):
		failures.append("Player should expose class_resource_summary for HUD")
		return
	if not player.has_method("class_resource_status"):
		failures.append("Player should expose class_resource_status for HUD")
		return
	var status := player.call("class_resource_status") as Dictionary
	var expected_state := "available"
	if limit > 0 and used >= limit:
		expected_state = "full"
	elif used <= 0:
		expected_state = "empty"
	if str(player.call("class_resource_summary")) != text:
		failures.append("%s summary API should return %s" % [kind, text])
	if str(status.get("kind", "")) != kind:
		failures.append("%s status API should expose kind metadata" % kind)
	if str(status.get("text", "")) != text:
		failures.append("%s status API should expose text metadata" % kind)
	if str(status.get("state", "")) != expected_state:
		failures.append("%s status API should expose %s state metadata" % [kind, expected_state])
	if int(status.get("used", -1)) != used:
		failures.append("%s status API should expose used metadata" % kind)
	if int(status.get("limit", -1)) != limit:
		failures.append("%s status API should expose limit metadata" % kind)
	if str(label.get_meta("class_resource_kind", "")) != kind:
		failures.append("HUD should mirror %s class resource kind metadata" % kind)
	if str(label.get_meta("class_resource_text", "")) != text:
		failures.append("HUD should mirror %s class resource text metadata" % kind)
	if str(label.get_meta("class_resource_state", "")) != expected_state:
		failures.append("HUD should mirror %s class resource state metadata" % kind)
	if str(label.get_meta("class_resource_color_role", "")) != expected_state:
		failures.append("HUD should mirror %s class resource color role metadata" % kind)
	var expected_color := _expected_class_resource_color(expected_state)
	var actual_color := label.get_theme_color("font_color")
	if not _colors_close(actual_color, expected_color):
		failures.append("HUD should color %s class resource label for %s state" % [kind, expected_state])
	if expected_state == "full":
		if str(label.get_meta("class_resource_pulse_state", "")) != "full":
			failures.append("HUD should pulse %s class resource label when full" % kind)
		if int(label.get_meta("class_resource_pulse_count", 0)) <= 0:
			failures.append("HUD should count %s class resource full pulses" % kind)
		var sfx := label.get_parent().get_node_or_null("ClassResourceFullSfx") as AudioStreamPlayer
		if sfx == null:
			failures.append("HUD should create class resource full sound placeholder")
		else:
			if str(sfx.get_meta("class_resource_sound_id", "")) != "class_resource_full":
				failures.append("HUD class resource sound should expose cue id")
			if str(sfx.get_meta("class_resource_kind", "")) != kind:
				failures.append("HUD class resource sound should store resource kind")
			if str(sfx.get_meta("class_resource_summary", "")) != text:
				failures.append("HUD class resource sound should store readable summary")
			if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
				failures.append("HUD class resource sound should come from AudioCueDB")
			if str(sfx.get_meta("audio_cue_kind", "")) != "class_resource_full":
				failures.append("HUD class resource sound should expose cue kind")
			if float(sfx.get_meta("class_resource_sound_frequency", 0.0)) <= 0.0:
				failures.append("HUD class resource sound should expose generated frequency")
			if not bool(sfx.get_meta("placeholder_audio_stream", false)):
				failures.append("HUD class resource sound should assign a placeholder stream")
			if not bool(sfx.get_meta("headless_playback_skipped", false)):
				failures.append("HUD class resource sound should skip playback in headless smoke")
	else:
		if str(label.get_meta("class_resource_pulse_state", "")) == "full":
			failures.append("HUD should clear %s full pulse metadata when no longer full" % kind)

func _expected_class_resource_color(state: String) -> Color:
	match state:
		"empty":
			return Color(0.55, 0.68, 0.76)
		"full":
			return Color(1.0, 0.84, 0.42)
		_:
			return Color(0.58, 0.95, 1.0)

func _check_hud_active_reload_window_feedback(failures: Array[String]) -> void:
	var scene := _make_scene("ActiveReloadHUDSmoke")
	var ctrl := FloorController.new()
	var room := RoomNode.new()
	room.id = 0
	room.type = RoomNode.RoomType.ENTRANCE
	ctrl.rooms = [room]
	ctrl.current_room = room
	scene.add_child(ctrl)
	var player := await _make_player(scene, "gunner")
	player.pickup_weapon("scrap_pistol")
	var weapon := player.current_weapon()
	if weapon == null:
		failures.append("Active Reload HUD smoke needs a gunner pistol")
		scene.queue_free()
		await process_frame
		return
	weapon.data["magazine_size"] = 2
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	if not player.has_signal("active_reload_window_changed"):
		failures.append("Player should emit active_reload_window_changed for HUD timing feedback")
	if not player.has_signal("active_reload_performed"):
		failures.append("Player should emit active_reload_performed for HUD success feedback")
	var window_events := {"count": 0, "last": {}}
	if player.has_signal("active_reload_window_changed"):
		player.connect("active_reload_window_changed", func(status: Dictionary) -> void:
			window_events["count"] = int(window_events["count"]) + 1
			window_events["last"] = status)
	hud.bind(player, ctrl)
	await process_frame
	var label := hud.get_node_or_null("ActiveReloadWindowLabel") as Label
	if label == null:
		failures.append("HUD should expose ActiveReloadWindowLabel")
	else:
		if label.visible:
			failures.append("Active Reload window label should start hidden")
	var total := float(weapon.cooldown())
	if total <= 0.0:
		failures.append("Active Reload HUD smoke needs a weapon cooldown")
	else:
		weapon.set("_cd_left", total * 0.25)
		player.call("_physics_process", 0.0)
		await process_frame
		if int(window_events["count"]) <= 0:
			failures.append("Player should signal when Active Reload enters the timing window")
		var last_status := window_events["last"] as Dictionary
		if not bool(last_status.get("in_window", false)):
			failures.append("Active Reload window signal should mark in_window=true")
		if label != null:
			if not label.visible:
				failures.append("HUD should show Active Reload label during the timing window")
			if not label.text.contains("Active Reload") or not label.text.contains("X"):
				failures.append("Active Reload HUD label should name the X input")
			if not bool(label.get_meta("active_reload_in_window", false)):
				failures.append("Active Reload HUD label should mirror in_window metadata")
			if float(label.get_meta("active_reload_cooldown_left", 0.0)) <= 0.0:
				failures.append("Active Reload HUD label should store cooldown_left metadata")
			if float(label.get_meta("active_reload_window_seconds", 0.0)) <= 0.0:
				failures.append("Active Reload HUD label should store window_seconds metadata")
			if float(label.get_meta("active_reload_damage_mult", 0.0)) < 1.09:
				failures.append("Active Reload HUD label should store damage multiplier metadata")
		if not bool(player.call("try_active_reload")):
			failures.append("Active Reload should succeed from the HUD timing window")
		player.call("_physics_process", 0.0)
		await process_frame
		if label != null and label.visible:
			failures.append("Active Reload HUD label should hide after a successful reload")
		var weapon_flash := hud.get_node_or_null("WeaponSwapFlashLabel") as Label
		if weapon_flash == null or not weapon_flash.visible:
			failures.append("Active Reload success should reuse HUD flash feedback")
		elif not weapon_flash.text.contains("Active Reload"):
			failures.append("Active Reload success flash should name Active Reload")
	hud.queue_free()
	scene.queue_free()
	await process_frame

func _make_scene(name: String) -> Node2D:
	var scene := Node2D.new()
	scene.name = name
	root.add_child(scene)
	current_scene = scene
	return scene

func _make_player(scene: Node2D, class_id: String) -> Player:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	scene.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data(class_id), "fire", "warden_sword")
	player.resource = 999.0
	player.global_position = Vector2.ZERO
	return player

func _all_active_skill_ids() -> Array[String]:
	var ids: Array[String] = []
	for class_data in PlayerClassDB.all():
		for active in class_data.get("actives", []):
			var skill_id := str(active.get("id", ""))
			if skill_id != "" and not ids.has(skill_id):
				ids.append(skill_id)
	return ids

func _child_named(parent: Node, child_name: String) -> Node:
	for child in parent.get_children():
		if child.name == child_name:
			return child
	return null

func _has_signal(node: Object, signal_name: String) -> bool:
	for info in node.get_signal_list():
		if str(info.get("name", "")) == signal_name:
			return true
	return false

func _has_label_containing(parent: Node, text: String) -> bool:
	for child in parent.find_children("*", "Label", true, false):
		if str(child.text).contains(text):
			return true
	return false

func _colors_close(actual: Color, expected: Color) -> bool:
	return absf(actual.r - expected.r) < 0.01 \
		and absf(actual.g - expected.g) < 0.01 \
		and absf(actual.b - expected.b) < 0.01
