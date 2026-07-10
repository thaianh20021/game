class_name RoomAffixDB
extends RefCounted
## Deterministic combat-room affixes. Affixes add lightweight room identity
## without changing core player controls.

const AFFIXES := [
	{
		"id": "none",
		"name": "",
		"weight": 2,
	},
	{
		"id": "spike_floor",
		"name": "Spike Floor",
		"weight": 3,
		"trap_kind": "spike",
		"extra_traps": 3,
	},
	{
		"id": "ember_vents",
		"name": "Ember Vents",
		"weight": 2,
		"trap_kind": "fire",
		"extra_traps": 3,
		"enemy_damage_bonus": 1,
	},
	{
		"id": "swift_pack",
		"name": "Swift Pack",
		"weight": 2,
		"extra_traps": 1,
		"enemy_speed_mult": 1.15,
	},
	{
		"id": "cursed_mist",
		"name": "Cursed Mist",
		"weight": 1,
		"enemy_damage_bonus": 2,
		"enemy_tint": Color(1.15, 0.8, 1.25),
	},
]

static func affix(affix_id: String) -> Dictionary:
	for data in AFFIXES:
		if str(data.get("id", "")) == affix_id:
			return data.duplicate()
	return AFFIXES[0].duplicate()

static func roll_for_room(room_type: int, run_seed: int, room_id: int, floor_index: int) -> Dictionary:
	if not _can_have_affix(room_type):
		return affix("none")
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed(run_seed, room_id, floor_index)
	var total_weight := 0
	for data in AFFIXES:
		total_weight += int(data.get("weight", 1))
	var pick := rng.randi_range(1, maxi(total_weight, 1))
	var cursor := 0
	for data in AFFIXES:
		cursor += int(data.get("weight", 1))
		if pick <= cursor:
			return data.duplicate()
	return affix("none")

static func _can_have_affix(room_type: int) -> bool:
	return room_type == RoomNode.RoomType.COMBAT \
		or room_type == RoomNode.RoomType.ELITE \
		or room_type == RoomNode.RoomType.MINIBOSS

static func _seed(run_seed: int, room_id: int, floor_index: int) -> int:
	return int(abs((run_seed * 73856093) ^ (room_id * 19349663) ^ (floor_index * 83492791) ^ 0xA11F1))
