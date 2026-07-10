extends SceneTree

const SAVE_PATH := "user://meta_upgrade_smoke.json"
const CAP_SAVE_PATH := "user://meta_upgrade_cap_smoke.json"

func _init() -> void:
	var failures: Array[String] = []

	await _check_meta_upgrade_purchase(failures)
	_check_meta_upgrade_caps(failures)
	await _check_player_meta_bonus_application(failures)
	_check_main_applies_meta_bonuses(failures)

	if failures.is_empty():
		print("Meta upgrade smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_meta_upgrade_purchase(failures: Array[String]) -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var script = load("res://scripts/progression/meta_progression.gd")
	script.bank_run_rewards({
		"gold": 120,
		"soul_shards": 10,
		"element_cores": 1,
		"rune_dust": 6,
		"blueprints": 1,
	}, "victory", SAVE_PATH)
	if not script.has_method("buy_upgrade"):
		failures.append("MetaProgression should expose buy_upgrade")
		return
	if not script.has_method("upgrade_costs"):
		failures.append("MetaProgression should expose multi-currency upgrade_costs")
		return
	var bought: Dictionary = script.call("buy_upgrade", "training_hp", SAVE_PATH)
	if int(bought.get("banked_gold", -1)) != 90:
		failures.append("training_hp should cost 30 banked gold")
	if int(bought.get("upgrades", {}).get("training_hp", 0)) != 1:
		failures.append("buy_upgrade should increment training_hp")
	var damaged: Dictionary = script.call("buy_upgrade", "training_damage", SAVE_PATH)
	if int(damaged.get("banked_gold", 0)) != 40:
		failures.append("training_damage should spend remaining 50 gold")
	var core: Dictionary = script.call("buy_upgrade", "core_affinity", SAVE_PATH)
	if int(core.get("element_cores", -1)) != 0:
		failures.append("core_affinity should spend an element core")
	if int(core.get("soul_shards", -1)) != 6:
		failures.append("core_affinity should spend soul shards")
	if int(core.get("upgrades", {}).get("core_affinity", 0)) != 1:
		failures.append("core_affinity should increment upgrade level")
	var rune: Dictionary = script.call("buy_upgrade", "rune_stability", SAVE_PATH)
	if int(rune.get("rune_dust", -1)) != 0:
		failures.append("rune_stability should spend rune dust")
	if int(rune.get("soul_shards", -1)) != 3:
		failures.append("rune_stability should spend soul shards")
	var socket: Dictionary = script.call("buy_upgrade", "blueprint_socket", SAVE_PATH)
	if int(socket.get("blueprints", -1)) != 0:
		failures.append("blueprint_socket should spend blueprints")
	if int(socket.get("banked_gold", -1)) != 0:
		failures.append("blueprint_socket should spend gold side cost")
	var poor: Dictionary = script.call("buy_upgrade", "blueprint_socket", SAVE_PATH)
	if int(poor.get("upgrades", {}).get("training_damage", 0)) != 1:
		failures.append("previous upgrades should remain after failed buy")
	if int(poor.get("upgrades", {}).get("blueprint_socket", 0)) != 1:
		failures.append("buy_upgrade should not buy when a currency is too low")
	if int(poor.get("banked_gold", 0)) != 0:
		failures.append("failed buy should not change banked gold")
	var fresh_key_path := "user://meta_upgrade_key_smoke.json"
	if FileAccess.file_exists(fresh_key_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(fresh_key_path))
	script.bank_run_rewards({"gold": 100, "rune_dust": 8}, "victory", fresh_key_path)
	var key_buy: Dictionary = script.call("buy_upgrade", "starter_key", fresh_key_path)
	if int(key_buy.get("banked_gold", -1)) != 65:
		failures.append("starter_key should cost 35 banked gold")
	if int(key_buy.get("rune_dust", -1)) != 6:
		failures.append("starter_key should cost 2 rune dust")
	if int(key_buy.get("upgrades", {}).get("starter_key", 0)) != 1:
		failures.append("starter_key should increment upgrade level")
	var fresh_gold_path := "user://meta_upgrade_gold_pouch_smoke.json"
	if FileAccess.file_exists(fresh_gold_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(fresh_gold_path))
	script.bank_run_rewards({"gold": 90, "soul_shards": 4}, "victory", fresh_gold_path)
	var gold_buy: Dictionary = script.call("buy_upgrade", "gold_pouch", fresh_gold_path)
	if int(gold_buy.get("banked_gold", -1)) != 65:
		failures.append("gold_pouch should cost 25 banked gold")
	if int(gold_buy.get("soul_shards", -1)) != 3:
		failures.append("gold_pouch should cost 1 soul shard")
	if int(gold_buy.get("upgrades", {}).get("gold_pouch", 0)) != 1:
		failures.append("gold_pouch should increment upgrade level")
	var fresh_revive_path := "user://meta_upgrade_revive_charm_smoke.json"
	if FileAccess.file_exists(fresh_revive_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(fresh_revive_path))
	script.bank_run_rewards({"gold": 140, "element_cores": 1, "blueprints": 1}, "victory", fresh_revive_path)
	var revive_buy: Dictionary = script.call("buy_upgrade", "revive_charm", fresh_revive_path)
	if int(revive_buy.get("banked_gold", -1)) != 60:
		failures.append("revive_charm should cost 80 banked gold")
	if int(revive_buy.get("element_cores", -1)) != 0:
		failures.append("revive_charm should cost 1 element core")
	if int(revive_buy.get("blueprints", -1)) != 0:
		failures.append("revive_charm should cost 1 blueprint")
	if int(revive_buy.get("upgrades", {}).get("revive_charm", 0)) != 1:
		failures.append("revive_charm should increment upgrade level")

func _check_meta_upgrade_caps(failures: Array[String]) -> void:
	if FileAccess.file_exists(CAP_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CAP_SAVE_PATH))
	var script = load("res://scripts/progression/meta_progression.gd")
	script.bank_run_rewards({"gold": 999}, "victory", CAP_SAVE_PATH)
	if not script.has_method("upgrade_max_level"):
		failures.append("MetaProgression should expose upgrade_max_level")
		return
	if not script.has_method("upgrade_next_effect"):
		failures.append("MetaProgression should expose upgrade_next_effect")
		return
	var max_hp := int(script.call("upgrade_max_level", "training_hp"))
	if max_hp < 2:
		failures.append("training_hp should have a real max level")
	var next_effect := str(script.call("upgrade_next_effect", "training_hp", 0))
	if not next_effect.contains("+10 HP"):
		failures.append("training_hp next effect should preview +10 HP")
	var data := {}
	for _i in max_hp:
		data = script.call("buy_upgrade", "training_hp", CAP_SAVE_PATH)
	var gold_after_cap := int(data.get("banked_gold", -1))
	var blocked: Dictionary = script.call("buy_upgrade", "training_hp", CAP_SAVE_PATH)
	if int(blocked.get("upgrades", {}).get("training_hp", 0)) != max_hp:
		failures.append("buy_upgrade should not exceed max level")
	if int(blocked.get("banked_gold", -2)) != gold_after_cap:
		failures.append("maxed buy should not spend currency")
	var max_effect := str(script.call("upgrade_next_effect", "training_hp", max_hp))
	if not max_effect.contains("MAX"):
		failures.append("maxed upgrade next effect should read MAX")
	if not script.call("all_upgrade_ids").has("starter_key"):
		failures.append("starter_key should be listed in meta upgrade order")
	if int(script.call("upgrade_max_level", "starter_key")) != 2:
		failures.append("starter_key should cap at 2 levels")
	var key_effect := str(script.call("upgrade_next_effect", "starter_key", 0))
	if not key_effect.contains("+1 silver key"):
		failures.append("starter_key next effect should preview starting key")
	if not script.call("all_upgrade_ids").has("gold_pouch"):
		failures.append("gold_pouch should be listed in meta upgrade order")
	if int(script.call("upgrade_max_level", "gold_pouch")) != 3:
		failures.append("gold_pouch should cap at 3 levels")
	var gold_effect := str(script.call("upgrade_next_effect", "gold_pouch", 0))
	if not gold_effect.contains("+10 starting gold"):
		failures.append("gold_pouch next effect should preview starting gold")
	if not script.call("all_upgrade_ids").has("revive_charm"):
		failures.append("revive_charm should be listed in meta upgrade order")
	if int(script.call("upgrade_max_level", "revive_charm")) != 1:
		failures.append("revive_charm should cap at 1 level")
	var revive_effect := str(script.call("upgrade_next_effect", "revive_charm", 0))
	if not revive_effect.contains("Revive once"):
		failures.append("revive_charm next effect should preview second chance")
	if not script.has_method("active_bonus_summary"):
		failures.append("MetaProgression should expose active_bonus_summary")
	else:
		var summary := str(script.call("active_bonus_summary", {
			"upgrades": {
				"training_hp": 2,
				"training_damage": 1,
				"core_affinity": 1,
				"rune_stability": 1,
				"blueprint_socket": 1,
				"starter_key": 1,
				"gold_pouch": 1,
				"revive_charm": 1,
			},
			"element_records": {
				"fire": {"label": "Fire", "victories": 2},
				"ice": {"label": "Ice", "victories": 1},
				"lightning": {"label": "Lightning", "victories": 0},
			},
			"biome_records": {
				"ember_forge": {"label": "Ember Forge", "victories": 1},
			},
		}, {"id": "ember_forge", "name": "Ember Forge"}))
		for token in ["+20 HP", "+4% damage", "+3% elemental", "-0.04s dash",
				"+1 projectile", "Key +1", "Gold +10", "Revive x1",
				"Element Mastery Fire/Ice +2%", "Biome Mastery Ember Forge +3%"]:
			if not summary.contains(token):
				failures.append("active_bonus_summary missing token: %s" % token)
		var empty_summary := str(script.call("active_bonus_summary", script.call("default_data")))
		if empty_summary != "None":
			failures.append("empty active_bonus_summary should read None")
	if not script.has_method("upgrade_purchase_hint"):
		failures.append("MetaProgression should expose upgrade_purchase_hint for hub recommendations")
	else:
		var ready_hint := str(script.call("upgrade_purchase_hint", {
			"banked_gold": 30,
			"upgrades": {},
		}, ["training_hp"]))
		if not ready_hint.contains("Ready: +HP") or not ready_hint.contains("30 Gold"):
			failures.append("upgrade_purchase_hint should name the next affordable upgrade and cost")
		var missing_hint := str(script.call("upgrade_purchase_hint", {
			"banked_gold": 10,
			"upgrades": {},
		}, ["training_hp"]))
		if not missing_hint.contains("Next: +HP needs 20 Gold"):
			failures.append("upgrade_purchase_hint should explain missing currency for the next upgrade")
		var maxed_hint := str(script.call("upgrade_purchase_hint", {
			"banked_gold": 999,
			"upgrades": {"training_hp": script.call("upgrade_max_level", "training_hp")},
		}, ["training_hp"]))
		if maxed_hint != "All upgrades maxed":
			failures.append("upgrade_purchase_hint should report maxed candidate groups")

func _check_player_meta_bonus_application(failures: Array[String]) -> void:
	var base := await _make_player()
	var base_hp := base.max_hp
	var base_damage := base.damage_mult
	var base_element_damage := base.element_damage_multiplier("fire")
	var base_dash_cooldown := base.dash_cooldown
	var base_projectile_bonus := base.projectile_bonus
	var base_silver_keys := base.silver_keys
	var base_gold := base.gold
	base.queue_free()
	await process_frame

	var boosted := await _make_player()
	if not boosted.has_method("apply_meta_bonuses"):
		failures.append("player should expose apply_meta_bonuses")
	else:
		boosted.call("apply_meta_bonuses", {
			"upgrades": {
				"training_hp": 2,
				"training_damage": 1,
				"core_affinity": 1,
				"rune_stability": 1,
				"blueprint_socket": 1,
				"starter_key": 2,
				"gold_pouch": 3,
				"revive_charm": 1,
			},
			"element_records": {
				"fire": {"label": "Fire", "victories": 2},
				"ice": {"label": "Ice", "victories": 1},
				"poison": {"label": "Poison", "victories": 1},
				"lightning": {"label": "Lightning", "victories": 0},
			}
		})
		if boosted.max_hp <= base_hp:
			failures.append("training_hp meta upgrade should increase max hp")
		if boosted.damage_mult <= base_damage:
			failures.append("training_damage meta upgrade should increase damage_mult")
		if boosted.element_damage_multiplier("fire") <= base_element_damage:
			failures.append("core_affinity meta upgrade should increase elemental damage")
		var fire_damage := boosted.element_damage_multiplier("fire")
		var ice_damage := boosted.element_damage_multiplier("ice")
		var poison_damage := boosted.element_damage_multiplier("poison")
		var lightning_damage := boosted.element_damage_multiplier("lightning")
		if not is_equal_approx(fire_damage, ice_damage) \
				or not is_equal_approx(fire_damage, poison_damage):
			failures.append("element mastery should apply the same capped bonus to each mastered element")
		if lightning_damage >= fire_damage:
			failures.append("element mastery should not buff elements without victories")
		if not is_equal_approx(fire_damage - lightning_damage, 0.02):
			failures.append("each mastered element should gain a small +2 percent damage bonus")
		if boosted.dash_cooldown >= base_dash_cooldown:
			failures.append("rune_stability meta upgrade should reduce dash cooldown")
		if boosted.projectile_bonus <= base_projectile_bonus:
			failures.append("blueprint_socket meta upgrade should increase projectile bonus")
		if boosted.silver_keys != base_silver_keys + 2:
			failures.append("starter_key meta upgrade should add starting silver keys")
		if boosted.gold != base_gold + 30:
			failures.append("gold_pouch meta upgrade should add starting gold")
		if not boosted.has_method("apply_biome_mastery"):
			failures.append("player should expose apply_biome_mastery")
		else:
			var before_biome_mastery := boosted.damage_mult
			boosted.call("apply_biome_mastery", {
				"biome_records": {
					"ember_forge": {"label": "Ember Forge", "victories": 1},
					"fungal_depths": {"label": "Fungal Depths", "victories": 0},
				},
			}, {"id": "ember_forge", "name": "Ember Forge"})
			if boosted.damage_mult <= before_biome_mastery:
				failures.append("biome mastery should increase damage_mult in mastered biome")
			if not is_equal_approx(float(boosted.get_meta("biome_mastery_bonus", 0.0)), 0.03):
				failures.append("biome mastery should store +3 percent bonus metadata")
			if str(boosted.get_meta("biome_mastery_label", "")) != "Ember Forge":
				failures.append("biome mastery should store readable biome label")
			var after_mastered_biome := boosted.damage_mult
			boosted.call("apply_biome_mastery", {
				"biome_records": {
					"fungal_depths": {"label": "Fungal Depths", "victories": 0},
				},
			}, {"id": "fungal_depths", "name": "Fungal Depths"})
			if not is_equal_approx(boosted.damage_mult, after_mastered_biome):
				failures.append("biome mastery should not buff biomes without victories")
		var death_events := {"count": 0}
		boosted.died.connect(func() -> void: death_events["count"] = int(death_events["count"]) + 1)
		boosted.take_damage(boosted.max_hp * 2)
		if int(death_events["count"]) > 0:
			failures.append("revive_charm should prevent the first lethal death signal")
		if boosted.hp != int(round(float(boosted.max_hp) * 0.35)):
			failures.append("revive_charm should restore 35 percent max hp")
		boosted.take_damage(boosted.max_hp * 2)
		if int(death_events["count"]) != 1:
			failures.append("revive_charm should be consumed after one save")
	boosted.queue_free()
	await process_frame

func _check_main_applies_meta_bonuses(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if not source.contains("apply_meta_bonuses"):
		failures.append("Main should apply meta bonuses when starting a run")
	if not source.contains("show_meta_bonus_summary") \
			or not source.contains("active_bonus_summary"):
		failures.append("Main should surface active meta bonuses on the HUD when starting a run")
	if not source.contains("apply_biome_mastery"):
		failures.append("Main should apply biome mastery after the floor biome is known")
	if not source.contains("show_biome_mastery_feedback"):
		failures.append("Main should surface biome mastery activation on the HUD")

func _make_player() -> Player:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	return player
