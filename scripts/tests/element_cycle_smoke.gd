extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	await _check_player_element_cycle(failures)
	await _check_hud_element_update(failures)
	_check_input_action(failures)

	if failures.is_empty():
		print("Element cycle smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_player_element_cycle(failures: Array[String]) -> void:
	var player := await _make_player()
	var seen := {"element": ""}
	if not _has_signal(player, "element_changed"):
		failures.append("player should expose element_changed signal")
	else:
		player.connect("element_changed", func(element: String) -> void:
			seen["element"] = element)
	if not player.has_method("cycle_element"):
		failures.append("player should expose cycle_element")
	else:
		var before := player.equipped_element
		player.call("cycle_element")
		if player.equipped_element == before:
			failures.append("cycle_element should change equipped element")
		if str(seen["element"]) != player.equipped_element:
			failures.append("cycle_element should emit element_changed")
		for i in ElementSystem.ELEMENTS.size():
			player.call("cycle_element")
		if player.equipped_element != player.equipped_element:
			failures.append("cycle_element should stay on a valid element")
		if not ElementSystem.ELEMENTS.has(player.equipped_element):
			failures.append("cycle_element should keep element inside ElementSystem.ELEMENTS")
	player.queue_free()
	await process_frame

func _check_hud_element_update(failures: Array[String]) -> void:
	var player := await _make_player()
	var floor := FloorController.new()
	root.add_child(floor)
	var hud := HUD.new()
	root.add_child(hud)
	await process_frame
	hud.bind(player, floor)
	player.cycle_element()
	await process_frame
	if not _has_label_containing(hud, "[%s]" % player.equipped_element):
		failures.append("HUD should update weapon label after element cycle")
	hud.queue_free()
	floor.queue_free()
	player.queue_free()
	await process_frame

func _check_input_action(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://project.godot")
	if not source.contains("cycle_element={"):
		failures.append("project input map should include cycle_element action")
	if not source.contains("physical_keycode\":81"):
		failures.append("cycle_element should bind Q")

func _make_player() -> Player:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	player.apply_class(PlayerClassDB.get_class_data("blade_warden"), "fire", "warden_sword")
	return player

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
