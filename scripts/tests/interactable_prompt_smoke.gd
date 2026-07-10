extends SceneTree

const RoomInteractableScript := preload("res://scripts/rooms/room_interactable.gd")

class DummyPlayer:
	extends Node2D
	signal gold_changed(total: int)
	signal key_changed(total: int)

	var gold := 30
	var silver_keys := 0

	func heal(_amount: int) -> void:
		pass

	func spend_key(amount: int = 1) -> bool:
		if silver_keys < amount:
			return false
		silver_keys -= amount
		key_changed.emit(silver_keys)
		return true

	func add_key(amount: int = 1) -> void:
		silver_keys += amount
		key_changed.emit(silver_keys)

func _init() -> void:
	var failures: Array[String] = []

	await _check_interact_requires_input(failures)
	await _check_blocked_interactable_prompt(failures)
	_check_input_action(failures)

	Input.action_release("interact")

	if failures.is_empty():
		print("Interactable prompt smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_interact_requires_input(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	parent.add_child(dummy)
	var chest := RoomInteractableScript.new()
	chest.configure("chest", dummy)
	parent.add_child(chest)
	await process_frame
	await physics_frame

	if chest.used:
		failures.append("nearby interactable should not auto-use without interact input")
	if chest.get_node_or_null("Prompt") == null:
		failures.append("nearby interactable should show an input prompt")
	elif not chest.get_node("Prompt").visible:
		failures.append("interact prompt should be visible while player is in range")
	elif str(chest.get_node("Prompt").text) != "F":
		failures.append("usable interactable prompt should show the interact key")
	else:
		_assert_prompt_contract(chest.get_node("Prompt") as Label, {
			"kind": "chest",
			"role": "interact",
			"state": "available",
			"uses": 1,
			"reward": "Gold + Potion",
			"tokens": ["F", "Chest", "Gold + Potion"],
		}, failures)

	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")
	await process_frame
	if not chest.used:
		failures.append("interact input should use a nearby interactable")

	parent.queue_free()
	await process_frame

func _check_blocked_interactable_prompt(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var dummy := DummyPlayer.new()
	parent.add_child(dummy)
	var chest := RoomInteractableScript.new()
	chest.configure("locked_chest", dummy)
	parent.add_child(chest)
	await process_frame
	await physics_frame

	var prompt := chest.get_node_or_null("Prompt") as Label
	if prompt == null:
		failures.append("locked chest should expose a prompt")
	elif not str(prompt.text).contains("Need key"):
		failures.append("locked chest prompt should explain missing key")
	elif not str(prompt.text).contains("x1"):
		failures.append("locked chest prompt should show required key count")
	else:
		_assert_prompt_contract(prompt, {
			"kind": "locked_chest",
			"role": "blocked",
			"state": "blocked",
			"uses": 1,
			"reward": "Gold + Weapon",
			"blocked_reason": "Need key x1",
			"tokens": ["F", "Locked Chest", "Need key x1", "Gold + Weapon"],
		}, failures)

	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")
	await process_frame
	if chest.used:
		failures.append("locked chest should stay unused when player has no key")
	var blocked := chest.get_node_or_null("BlockedFeedback") as Label
	if blocked == null:
		failures.append("blocked locked chest use should show feedback")
	elif not str(blocked.text).contains("Need key"):
		failures.append("blocked locked chest feedback should explain the missing key")
	elif not str(blocked.text).contains("x1"):
		failures.append("blocked locked chest feedback should show required key count")
	if str(chest.get_meta("last_blocked_reason", "")) != "Need key x1":
		failures.append("blocked locked chest should store readable block reason")
	var sfx := chest.get_node_or_null("InteractableBlockedSfx") as AudioStreamPlayer
	if sfx == null:
		failures.append("blocked interactable should create sound placeholder")
	else:
		if str(sfx.get_meta("interactable_kind", "")) != "locked_chest":
			failures.append("blocked interactable sound should store kind metadata")
		if str(sfx.get_meta("blocked_reason", "")) != "Need key x1":
			failures.append("blocked interactable sound should store compact reason metadata")
		if str(sfx.get_meta("objective_sound_id", "")) != "objective_blocked":
			failures.append("blocked interactable sound should expose blocked cue id")
		if str(sfx.get_meta("audio_cue_source", "")) != "AudioCueDB":
			failures.append("blocked interactable sound should come from AudioCueDB")
		if sfx.stream == null:
			failures.append("blocked interactable sound should assign an audio stream")
		if DisplayServer.get_name() == "headless" \
				and not bool(sfx.get_meta("headless_playback_skipped", false)):
			failures.append("blocked interactable sound should skip playback in headless smoke")

	dummy.add_key(1)
	await process_frame
	if prompt != null and str(prompt.text) != "F":
		failures.append("locked chest prompt should return to interact key after player gains a key")
	elif prompt != null:
		_assert_prompt_contract(prompt, {
			"kind": "locked_chest",
			"role": "interact",
			"state": "available",
			"uses": 1,
			"reward": "Gold + Weapon",
			"blocked_reason": "",
			"tokens": ["F", "Locked Chest", "Gold + Weapon"],
		}, failures)

	parent.queue_free()
	await process_frame

func _check_input_action(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://project.godot")
	if not source.contains("interact={"):
		failures.append("project input map should include interact action")
	if not source.contains("physical_keycode\":70"):
		failures.append("interact should bind F")

func _assert_prompt_contract(prompt: Label, expected: Dictionary, failures: Array[String]) -> void:
	if str(prompt.get_meta("interactable_kind", "")) != str(expected.get("kind", "")):
		failures.append("prompt should tag interactable kind %s" % str(expected.get("kind", "")))
	if str(prompt.get_meta("prompt_role", "")) != str(expected.get("role", "")):
		failures.append("prompt should tag prompt role %s" % str(expected.get("role", "")))
	if str(prompt.get_meta("objective_state", "")) != str(expected.get("state", "")):
		failures.append("prompt should tag objective state %s" % str(expected.get("state", "")))
	if int(prompt.get_meta("uses_remaining", -1)) != int(expected.get("uses", -1)):
		failures.append("prompt should tag remaining uses")
	if str(prompt.get_meta("interact_input_action", "")) != "interact":
		failures.append("prompt should tag interact input action")
	if str(prompt.get_meta("interact_key_label", "")) != "F":
		failures.append("prompt should tag interact key label")
	if str(prompt.get_meta("reward_preview", "")) != str(expected.get("reward", "")):
		failures.append("prompt should tag reward preview")
	if str(prompt.get_meta("blocked_reason", "")) != str(expected.get("blocked_reason", "")):
		failures.append("prompt should tag blocked reason")
	if prompt.tooltip_text.strip_edges() == "":
		failures.append("prompt should expose tooltip text")
	for token in Array(expected.get("tokens", [])):
		if not prompt.tooltip_text.contains(str(token)):
			failures.append("prompt tooltip should include %s" % str(token))
