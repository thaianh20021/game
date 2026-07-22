extends SceneTree

const EXPECTED_IDS := [
	"blade_warden",
	"breaker",
	"nightblade",
	"bulwark",
	"arcanist",
	"ranger",
	"gunner",
	"soulbinder",
	"lightkeeper",
	"tinkerer",
]

func _init() -> void:
	var failures: Array[String] = []

	_check_class_data(failures)
	await _check_apply_class(failures)
	await _check_class_select_layout(failures)
	await _check_class_select_detail_panel(failures)

	if failures.is_empty():
		print("Ten class roster smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_class_data(failures: Array[String]) -> void:
	var classes := PlayerClassDB.all()
	if classes.size() != EXPECTED_IDS.size():
		failures.append("expected 10 classes, got %d" % classes.size())
	var seen := {}
	for data in classes:
		var id := str(data.get("id", ""))
		seen[id] = true
		for key in ["name", "role", "resource", "stats", "preferred_weapons", "actives", "passives", "ultimate"]:
			if not data.has(key):
				failures.append("%s missing key %s" % [id, key])
		var stats: Dictionary = data.get("stats", {})
		for key in ["hp", "armor", "resource", "speed", "damage", "crit"]:
			if not stats.has(key):
				failures.append("%s stats missing %s" % [id, key])
		if data.get("preferred_weapons", []).is_empty():
			failures.append("%s needs at least one preferred weapon group" % id)
		if data.get("actives", []).size() < 2:
			failures.append("%s needs two active metadata entries" % id)
	for id in EXPECTED_IDS:
		if not seen.has(id):
			failures.append("missing class id %s" % id)

func _check_apply_class(failures: Array[String]) -> void:
	var runtime_heights := {}
	for id in EXPECTED_IDS:
		var player_scene: PackedScene = load("res://scenes/player.tscn")
		var player: Player = player_scene.instantiate()
		root.add_child(player)
		await process_frame
		var data := PlayerClassDB.get_class_data(id)
		if data.is_empty():
			player.free()
			continue
		player.apply_class(data, "fire", "warden_sword")
		if player.class_id != id:
			failures.append("%s did not apply class_id" % id)
		if player.hp <= 0 or player.max_hp <= 0:
			failures.append("%s produced invalid hp" % id)
		if player.current_weapon() == null:
			failures.append("%s did not equip a starter weapon" % id)
		runtime_heights[id] = _assert_class_sprite_contract(player, id, failures)
		player.free()
	_assert_class_sprite_height_parity(runtime_heights, failures)

func _assert_class_sprite_contract(
		player: Player,
		class_id: String,
		failures: Array[String],
) -> float:
	var sprite := player.get_node_or_null("Sprite") as AnimatedSprite2D
	var body := player.get_node_or_null("Body") as Polygon2D
	if sprite == null:
		failures.append("%s should expose AnimatedSprite2D Sprite" % class_id)
		return 0.0
	if body == null:
		failures.append("%s should expose polygon fallback Body" % class_id)
	if not sprite.visible:
		failures.append("%s should use licensed/class sprite instead of polygon fallback" % class_id)
	if body != null and body.visible:
		failures.append("%s should hide polygon fallback when class sprite exists" % class_id)
	if sprite.sprite_frames == null:
		failures.append("%s should assign class SpriteFrames" % class_id)
		return 0.0
	for anim_name in ["idle", "run"]:
		if not sprite.sprite_frames.has_animation(anim_name):
			failures.append("%s class sprite should have %s animation" % [class_id, anim_name])
		elif sprite.sprite_frames.get_frame_count(anim_name) <= 0:
			failures.append("%s class sprite should have %s frames" % [class_id, anim_name])
	if str(sprite.get_meta("class_idle_sprite", "")) == "":
		failures.append("%s class sprite should store idle sprite metadata" % class_id)
	if str(sprite.get_meta("class_run_sprite", "")) == "":
		failures.append("%s class sprite should store run sprite metadata" % class_id)
	if not ["atlas", "user_local_assets"].has(str(sprite.get_meta("asset_source", ""))):
		failures.append("%s class sprite should use reviewed runtime art" % class_id)
	if str(sprite.get_meta("release_decision", "")) != "public_ok":
		failures.append("%s class sprite should be public release reviewed" % class_id)
	if not bool(sprite.get_meta("frame_grid_ok", false)):
		failures.append("%s class sprite should expose stable frame-grid metadata" % class_id)
	var idle_texture := sprite.sprite_frames.get_frame_texture("idle", 0)
	var content_rect := _texture_content_rect(idle_texture)
	var scaled_content_height := float(content_rect.size.y) * sprite.scale.y
	if scaled_content_height < 30.0 or scaled_content_height > 32.5:
		failures.append("%s runtime sprite visible height should match other classes, got %.2f from %s scale %s" % [
			class_id,
			scaled_content_height,
			content_rect,
			sprite.scale,
		])
	return scaled_content_height

func _assert_class_sprite_height_parity(heights: Dictionary, failures: Array[String]) -> void:
	if heights.size() != EXPECTED_IDS.size():
		return
	var min_height := 999.0
	var max_height := 0.0
	for raw_height in heights.values():
		var height := float(raw_height)
		min_height = minf(min_height, height)
		max_height = maxf(max_height, height)
	if max_height - min_height > 2.0:
		failures.append("runtime class sprite heights should stay visually even, got %.2f..%.2f" % [
			min_height,
			max_height,
		])
	var blade_height := float(heights.get("blade_warden", 0.0))
	if blade_height < max_height - 1.5:
		failures.append("blade_warden/Blackwarden sprite should not read smaller than other classes, got %.2f vs %.2f" % [
			blade_height,
			max_height,
		])

func _check_class_select_layout(failures: Array[String]) -> void:
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	var scroll := screen.find_child("ClassScroll", true, false) as ScrollContainer
	var grid := screen.find_child("ClassGrid", true, false) as GridContainer
	var controls := screen.find_child("ControlsLegendLabel", true, false) as Label
	if controls == null:
		failures.append("class select should expose a ControlsLegendLabel onboarding hint")
	else:
		for token in ["WASD", "Mouse", "Space", "E", "C", "Q cycle", "V ultimate", "1-4", "Esc/P", "R", "F4 clean HUD"]:
			if not controls.text.contains(token):
				failures.append("ControlsLegendLabel missing token %s" % token)
		if str(controls.get_meta("control_legend_scope", "")) != "gameplay":
			failures.append("ControlsLegendLabel should tag gameplay control scope")
		if int(controls.get_meta("control_legend_action_count", 0)) < 8:
			failures.append("ControlsLegendLabel should expose enough control action metadata")
	if scroll == null:
		failures.append("class select missing ClassScroll")
	if grid == null:
		failures.append("class select missing ClassGrid")
	else:
		var class_buttons := 0
		for child in grid.get_children():
			if child is Button:
				class_buttons += 1
		if class_buttons != EXPECTED_IDS.size():
			failures.append("expected 10 class buttons, got %d" % class_buttons)
		_check_class_button_icons(screen, failures)
	_check_element_button_icons(screen, failures)
	screen.free()

func _check_class_button_icons(screen: ClassSelectScreen, failures: Array[String]) -> void:
	var icon_heights := {}
	for class_id in EXPECTED_IDS:
		var button := screen.find_child("Class_%s" % class_id, true, false) as Button
		if button == null:
			failures.append("class select should expose Class_%s button" % class_id)
			continue
		var sprite_names := Player.class_sprite_names(class_id)
		var idle_sprite := str(sprite_names.get("idle", ""))
		if button.icon == null:
			failures.append("%s class button should assign an icon" % class_id)
		if str(button.get_meta("class_id", "")) != class_id:
			failures.append("%s class button should store class id metadata" % class_id)
		if str(button.get_meta("class_idle_sprite", "")) != idle_sprite:
			failures.append("%s class button should store idle sprite metadata" % class_id)
		if not ["atlas", "user_local_assets"].has(str(button.get_meta("asset_source", ""))):
			failures.append("%s class button should use reviewed runtime art" % class_id)
		if str(button.get_meta("release_decision", "")) != "public_ok":
			failures.append("%s class button should be public release reviewed" % class_id)
		if not bool(button.get_meta("frame_grid_ok", false)):
			failures.append("%s class button should expose stable frame-grid metadata" % class_id)
		if str(button.get_meta("class_icon_target_size", "")) != "(32.0, 32.0)":
			failures.append("%s class button should normalize icon into a 32x32 UI frame" % class_id)
		elif button.icon != null and button.icon.get_size() != Vector2(32, 32):
			failures.append("%s class button icon texture should be exactly 32x32, got %s" % [
				class_id,
				button.icon.get_size(),
			])
		elif button.icon != null:
			var content_rect := _texture_content_rect(button.icon)
			icon_heights[class_id] = float(content_rect.size.y)
			if content_rect.size.y < 28.0:
				failures.append("%s class button icon visible sprite should fill the shared UI frame, got %s" % [
					class_id,
					content_rect,
				])
		if class_id == "blade_warden":
			_assert_class_preview_texture_size(
				button.icon,
				"blade_warden class button",
				32.0,
				failures)
		var index := EXPECTED_IDS.find(class_id)
		var key_label := "0" if index == 9 else str(index + 1)
		var hotkey := KEY_0 if index == 9 else KEY_1 + index
		if str(button.get_meta("class_input_action", "")) != "select_class":
			failures.append("%s class button should expose select_class input metadata" % class_id)
		if str(button.get_meta("class_key_label", "")) != key_label:
			failures.append("%s class button should expose key label %s" % [class_id, key_label])
		if int(button.get_meta("class_hotkey", 0)) != hotkey:
			failures.append("%s class button should expose hotkey %d" % [class_id, hotkey])
		var input_hint := str(button.get_meta("class_input_hint", ""))
		if not input_hint.contains(key_label) or not input_hint.contains(str(button.text)):
			failures.append("%s class button should expose readable key tooltip" % class_id)
		_check_class_button_tooltip(class_id, button, key_label, failures)
	_assert_class_icon_height_parity(icon_heights, failures)

func _assert_class_icon_height_parity(icon_heights: Dictionary, failures: Array[String]) -> void:
	if icon_heights.size() != EXPECTED_IDS.size():
		return
	var max_height := 0.0
	for raw_height in icon_heights.values():
		max_height = maxf(max_height, float(raw_height))
	var blade_height := float(icon_heights.get("blade_warden", 0.0))
	if blade_height < max_height - 1.0:
		failures.append("blade_warden/Blackwarden class-select icon should match other class icon height, got %.2f vs %.2f" % [
			blade_height,
			max_height,
		])

func _check_element_button_icons(screen: ClassSelectScreen, failures: Array[String]) -> void:
	var expected := {
		"fire": "flask_red",
		"ice": "flask_blue",
		"lightning": "flask_yellow",
		"poison": "flask_green",
	}
	for element in expected.keys():
		var button := screen.find_child("Element_%s" % element, true, false) as Button
		if button == null:
			failures.append("class select should expose Element_%s button" % element)
			continue
		if button.icon == null:
			failures.append("%s element button should assign an icon" % element)
		if str(button.get_meta("element_icon_sprite", "")) != str(expected[element]):
			failures.append("%s element button should store icon sprite metadata" % element)
		if str(button.get_meta("asset_source", "")) != "atlas":
			failures.append("%s element button should use licensed 0x72 atlas art" % element)
		if str(button.get_meta("release_decision", "")) != "public_ok":
			failures.append("%s element button should be public release reviewed" % element)
		if not bool(button.get_meta("frame_grid_ok", false)):
			failures.append("%s element button should expose stable frame-grid metadata" % element)
		var key_label := _element_key_label(element)
		var hotkey := _element_hotkey(element)
		if str(button.get_meta("element_input_action", "")) != "select_element":
			failures.append("%s element button should expose select_element input metadata" % element)
		if str(button.get_meta("element_key_label", "")) != key_label:
			failures.append("%s element button should expose key label %s" % [element, key_label])
		if int(button.get_meta("element_hotkey", 0)) != hotkey:
			failures.append("%s element button should expose hotkey %d" % [element, hotkey])
		if not button.tooltip_text.contains(key_label) or not button.tooltip_text.contains(str(button.text)):
			failures.append("%s element button should expose readable key tooltip" % element)

func _check_class_button_tooltip(
		class_id: String,
		button: Button,
		key_label: String,
		failures: Array[String],
) -> void:
	var data := PlayerClassDB.get_class_data(class_id)
	var actives: Array = data.get("actives", [])
	var ultimate: Dictionary = data.get("ultimate", {})
	var weapon_id := WeaponDB.starter_weapon_for_class(class_id)
	var weapon := WeaponDB.get_weapon(weapon_id)
	var required_tokens: Array[String] = [
		"[%s]" % key_label,
		str(data.get("name", "")),
		str(data.get("role", "")),
		str(data.get("resource", "")),
		str(weapon.get("name", weapon_id)),
	]
	for group in Array(data.get("preferred_weapons", [])):
		required_tokens.append(str(group))
	for active in actives:
		if active is Dictionary:
			required_tokens.append(_readable_id(str((active as Dictionary).get("id", ""))))
	if not ultimate.is_empty():
		required_tokens.append(_readable_id(str(ultimate.get("id", ""))))
	var searchable_tooltip := "%s\n%s" % [
		str(button.get_meta("class_input_hint", "")),
		str(button.get_meta("class_tooltip_detail", "")),
	]
	for token in required_tokens:
		if token.strip_edges() != "" and not searchable_tooltip.contains(token):
			failures.append("%s class tooltip missing %s" % [class_id, token])

func _check_class_select_detail_panel(failures: Array[String]) -> void:
	var screen := ClassSelectScreen.new()
	root.add_child(screen)
	await process_frame
	var grid := screen.find_child("ClassGrid", true, false) as GridContainer
	if grid == null:
		screen.free()
		return
	var breaker_button: Button = null
	for child in grid.get_children():
		if child is Button and str(child.text).contains("Breaker"):
			breaker_button = child
			break
	if breaker_button == null:
		failures.append("class select should expose Breaker button")
	else:
		var blade_button := screen.find_child("Class_blade_warden", true, false) as Button
		if blade_button != null:
			blade_button.emit_signal("pressed")
			await process_frame
			var blade_preview := screen.find_child(
				"ClassDetailSpritePreview", true, false) as TextureRect
			if blade_preview != null:
				if blade_preview.custom_minimum_size != Vector2(32, 32):
					failures.append("blade_warden detail preview should use the same 32x32 UI frame as other class previews")
				_assert_class_preview_texture_size(
					blade_preview.texture,
					"blade_warden detail preview",
					32.0,
					failures)
		breaker_button.emit_signal("pressed")
		await process_frame
		_expect_class_select_sfx(
			screen,
			"select_class",
			"class_select",
			"class_select_class_id",
			"breaker",
			failures)
		var detail := screen.find_child("ClassDetailPanel", true, false)
		var name_label := screen.find_child("ClassDetailName", true, false) as Label
		var preview := screen.find_child("ClassDetailSpritePreview", true, false) as TextureRect
		var weapon_preview := screen.find_child("ClassDetailWeaponPreview", true, false) as TextureRect
		var weapon_label := screen.find_child("ClassDetailWeaponSummary", true, false) as Label
		var gameplan_label := screen.find_child("ClassDetailGameplan", true, false) as Label
		var stats_label := screen.find_child("ClassDetailStats", true, false) as Label
		var skills_label := screen.find_child("ClassDetailSkills", true, false) as Label
		if detail == null:
			failures.append("class select should show a selected class detail panel")
		if name_label == null or not name_label.text.contains("Breaker"):
			failures.append("class detail should show selected class name")
		if preview == null:
			failures.append("class detail should expose a class sprite preview")
		else:
			if preview.texture == null:
				failures.append("class detail sprite preview should assign a texture")
			if preview.custom_minimum_size != Vector2(32, 32):
				failures.append("class detail sprite preview should use a readable 32x32 frame")
			if str(preview.get_meta("class_id", "")) != "breaker":
				failures.append("class detail sprite preview should store selected class id")
			if str(preview.get_meta("class_idle_sprite", "")) != "dwarf_m_idle_anim":
				failures.append("breaker class detail sprite should use dwarf idle art")
			if str(preview.get_meta("class_run_sprite", "")) != "dwarf_m_run_anim":
				failures.append("breaker class detail sprite should store run art metadata")
			if str(preview.get_meta("asset_source", "")) != "atlas":
				failures.append("class detail sprite preview should use licensed 0x72 atlas art")
			if str(preview.get_meta("release_decision", "")) != "public_ok":
				failures.append("class detail sprite preview should be public release reviewed")
			if not bool(preview.get_meta("frame_grid_ok", false)):
				failures.append("class detail sprite preview should expose stable frame-grid metadata")
		if weapon_preview == null:
			failures.append("class detail should expose a starter weapon preview")
		else:
			if weapon_preview.texture == null:
				failures.append("starter weapon preview should assign a texture")
			if str(weapon_preview.get_meta("class_id", "")) != "breaker":
				failures.append("starter weapon preview should store selected class id")
			if str(weapon_preview.get_meta("starter_weapon_id", "")) != "pioneer_axe":
				failures.append("breaker starter weapon preview should use pioneer_axe")
			if str(weapon_preview.get_meta("starter_weapon_group", "")) != "axe":
				failures.append("breaker starter weapon preview should tag axe group")
			if str(weapon_preview.get_meta("weapon_sprite_name", "")) != "weapon_axe":
				failures.append("breaker starter weapon preview should use axe art")
			if str(weapon_preview.get_meta("asset_source", "")) != "atlas":
				failures.append("starter weapon preview should use licensed 0x72 atlas art")
			if str(weapon_preview.get_meta("release_decision", "")) != "public_ok":
				failures.append("starter weapon preview should be public release reviewed")
			if not bool(weapon_preview.get_meta("frame_grid_ok", false)):
				failures.append("starter weapon preview should expose stable frame-grid metadata")
		if weapon_label == null:
			failures.append("class detail should expose a starter weapon stat summary")
		elif not weapon_label.text.contains("Starter: Riu Khai Hoang") \
				or not weapon_label.text.contains("DMG 7") \
				or not weapon_label.text.contains("SPD 4") \
				or not weapon_label.text.contains("RNG 2") \
				or not weapon_label.text.contains("Sockets 1") \
				or not weapon_label.text.contains("vs props/crates"):
			failures.append("class detail should show selected class starter weapon stats and effect")
		if gameplan_label == null:
			failures.append("class detail should expose a class gameplan label")
		else:
			_check_compact_detail_lines(gameplan_label, "class gameplan", failures)
			if not str(gameplan_label.get_meta("class_detail_full_text", "")).contains("Upgrade Tags"):
				failures.append("class gameplan should preserve full detail in metadata")
			for token in ["Ease: Medium", "Plan:", "Risk:", "Upgrade Tags:", "slam", "slow windup"]:
				if not gameplan_label.text.contains(token):
					failures.append("class gameplan missing token %s" % token)
			if str(gameplan_label.get_meta("class_id", "")) != "breaker":
				failures.append("class gameplan should store selected class id")
			if str(gameplan_label.get_meta("class_role", "")) != "heavy_melee_burst":
				failures.append("class gameplan should store selected class role")
			if str(gameplan_label.get_meta("class_ease", "")) != "Medium":
				failures.append("class gameplan should store ease metadata")
			if not str(gameplan_label.get_meta("recommended_upgrade_tags", "")).contains("damage") \
					or not str(gameplan_label.get_meta("recommended_upgrade_tags", "")).contains("mobility"):
				failures.append("class gameplan should expose recommended upgrade tags")
		if stats_label == null or not stats_label.text.contains("HP 7") or not stats_label.text.contains("DMG 9"):
			failures.append("class detail should show selected class stat summary")
		if skills_label == null or not skills_label.text.contains("Earthbreaker") \
				or not skills_label.text.contains("Iron Will") \
				or not skills_label.text.contains("Cost 30") \
				or not skills_label.text.contains("CD 8.0s"):
			failures.append("class detail should show primary and secondary skills")
		else:
			_check_compact_detail_lines(skills_label, "class skills", failures)
			if not skills_label.text.contains("Passives") \
					or not skills_label.text.contains("Heavy Windup") \
					or not skills_label.text.contains("Iron Skin"):
				failures.append("class detail should preview class passives")
			if not str(skills_label.get_meta("class_detail_full_text", "")).contains("Passives"):
				failures.append("class skills should preserve full detail in metadata")
		screen.call("_select_element", "fire")
		await process_frame
		screen.call("_select_run_mode", "boss_rush")
		var seed_input := screen.find_child("RunSeedInput", true, false) as LineEdit
		if seed_input == null:
			failures.append("class select should expose run seed input")
		else:
			seed_input.text = "20260707"
			seed_input.emit_signal("text_changed", "20260707")
			await process_frame
		var start_button := screen.find_child("StartRunButton", true, false) as Button
		if start_button == null:
			failures.append("class select should expose start run button")
		else:
			_check_start_button_run_contract(start_button, failures)
		var loadout_preview := screen.find_child("RunLoadoutPreviewLabel", true, false) as Label
		if loadout_preview == null:
			failures.append("class select should expose run loadout metadata")
		else:
			_check_loadout_preview_contract(loadout_preview, failures)
		var element_preview := screen.find_child("ElementPreviewLabel", true, false) as Label
		if element_preview == null:
			failures.append("class select should expose selected element preview")
		else:
			for token in ["Fire", "Burn DoT", "4.0s", "Thermal Shock", "Plasma", "Burning Smog"]:
				if not element_preview.text.contains(token):
					failures.append("element preview missing token %s" % token)
			if str(element_preview.get_meta("selected_element", "")) != "fire":
				failures.append("element preview should store selected element metadata")
			if int(element_preview.get_meta("combo_count", 0)) != 3:
				failures.append("fire element preview should expose three related combos")
			if not str(element_preview.get_meta("combo_names", "")).contains("Thermal Shock"):
				failures.append("element preview should store readable combo names metadata")
		screen.call("_on_start")
		_expect_class_select_sfx(
			screen,
			"confirm_run",
			"class_confirm",
			"class_select_class_id",
			"breaker",
			failures)
	if is_instance_valid(screen):
		screen.queue_free()

func _check_start_button_run_contract(button: Button, failures: Array[String]) -> void:
	if button.disabled:
		failures.append("start button should be enabled after class and element are selected")
	var tooltip := button.tooltip_text
	for token in ["Breaker", "fire", "Boss Rush", "20260707", "Riu Khai Hoang", "Enter"]:
		if not tooltip.contains(token):
			failures.append("start button tooltip should include %s" % token)
	if str(button.get_meta("start_class_id", "")) != "breaker":
		failures.append("start button should store selected class id")
	if str(button.get_meta("start_element", "")) != "fire":
		failures.append("start button should store selected element")
	if str(button.get_meta("start_run_mode", "")) != "boss_rush":
		failures.append("start button should store selected run mode")
	if int(button.get_meta("start_seed", 0)) != 20260707:
		failures.append("start button should store selected run seed")
	if str(button.get_meta("starter_weapon_name", "")) != "Riu Khai Hoang":
		failures.append("start button should store starter weapon summary")
	if str(button.get_meta("start_disabled_reason", "")) != "":
		failures.append("ready start button should clear disabled reason")

func _assert_class_preview_texture_size(
		texture: Texture2D,
		label: String,
		max_height: float,
		failures: Array[String],
) -> void:
	if texture == null:
		failures.append("%s should assign a normalized preview texture" % label)
		return
	var size := texture.get_size()
	if size.y > max_height:
		failures.append("%s should crop transparent padding before UI scaling, got %s" % [
			label,
			size,
		])
	var content_rect := _texture_content_rect(texture)
	if content_rect.size.y < 28.0:
		failures.append("%s visible sprite should fill the normalized UI frame, got %s" % [
			label,
			content_rect,
		])

func _texture_content_rect(texture: Texture2D) -> Rect2i:
	if texture == null:
		return Rect2i()
	var image := texture.get_image()
	if image == null or image.is_empty():
		return Rect2i()
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= 0.01:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _check_loadout_preview_contract(label: Label, failures: Array[String]) -> void:
	if label.visible:
		failures.append("loadout preview should stay hidden on the compact class select screen")
	for token in ["Ready", "Breaker", "Fire", "Boss Rush", "20260707", "Riu Khai Hoang"]:
		if not label.text.contains(token):
			failures.append("loadout preview should include %s" % token)
	if str(label.get_meta("start_class_id", "")) != "breaker":
		failures.append("loadout preview should store selected class id")
	if str(label.get_meta("start_element", "")) != "fire":
		failures.append("loadout preview should store selected element")
	if str(label.get_meta("start_run_mode", "")) != "boss_rush":
		failures.append("loadout preview should store selected run mode")
	if int(label.get_meta("start_seed", 0)) != 20260707:
		failures.append("loadout preview should store selected seed")
	if str(label.get_meta("starter_weapon_name", "")) != "Riu Khai Hoang":
		failures.append("loadout preview should store starter weapon")
	if not bool(label.get_meta("loadout_ready", false)):
		failures.append("loadout preview should mark the ready state")

func _check_compact_detail_lines(label: Label, label_name: String, failures: Array[String]) -> void:
	for line in label.text.split("\n"):
		var line_text := str(line)
		if line_text.length() > 72:
			failures.append("%s visible line should stay compact, got %d chars" % [
				label_name,
				line_text.length(),
			])

func _expect_class_select_sfx(
		screen: ClassSelectScreen,
		expected_action: String,
		expected_sound_id: String,
		expected_meta_key: String,
		expected_meta_value: String,
		failures: Array[String]) -> void:
	var sfx := screen.get_node_or_null("ClassSelectSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("class select should play %s placeholder sound" % expected_action)
		return
	if str(sfx.get_meta("class_select_action", "")) != expected_action:
		failures.append("class select sound should tag %s action" % expected_action)
	if str(sfx.get_meta("class_select_sound_id", "")) != expected_sound_id:
		failures.append("class select sound should use %s cue" % expected_sound_id)
	if str(sfx.get_meta(expected_meta_key, "")) != expected_meta_value:
		failures.append("class select sound should tag %s=%s" % [
			expected_meta_key,
			expected_meta_value,
		])
	if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
		failures.append("class select sound should come from AudioCueDB")
	if str(sfx.get_meta("audio_cue_kind", "")) != "class_select":
		failures.append("class select sound should tag class_select cue kind")
	if not bool(sfx.get_meta("placeholder_audio_stream", false)):
		failures.append("class select sound should use generated placeholder stream")
	if not bool(sfx.get_meta("playback_requested", false)):
		failures.append("class select sound should request playback")
	if DisplayServer.get_name() == "headless" \
			and not bool(sfx.get_meta("headless_playback_skipped", false)):
		failures.append("class select sound should skip playback in headless smoke")

func _element_key_label(element: String) -> String:
	match element:
		"fire":
			return "F"
		"ice":
			return "I"
		"lightning":
			return "L"
		"poison":
			return "P"
	return ""

func _element_hotkey(element: String) -> int:
	match element:
		"fire":
			return KEY_F
		"ice":
			return KEY_I
		"lightning":
			return KEY_L
		"poison":
			return KEY_P
	return 0

func _readable_id(id: String) -> String:
	var clean := id.strip_edges()
	if clean == "" or clean == "-":
		return "-"
	return clean.replace("_", " ").capitalize()
