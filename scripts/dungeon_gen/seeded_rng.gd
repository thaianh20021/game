class_name SeededRNG
extends RefCounted
## Deterministic RNG wrapper. ALL generation randomness must go through this
## so that the same (seed, stream) always reproduces the same floor.
## Required for the Daily Seed mode (see docs/gdd/10-dungeon-gen.md).

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int, stream: int = 0) -> void:
	_rng.seed = hash("%d:%d" % [seed_value, stream])


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func randf() -> float:
	return _rng.randf()


func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


func pick(arr: Array) -> Variant:
	assert(not arr.is_empty(), "SeededRNG.pick: array is empty")
	return arr[_rng.randi_range(0, arr.size() - 1)]


## Picks one item where items[i] has probability weights[i] / sum(weights).
func weighted_pick(items: Array, weights: Array) -> Variant:
	assert(items.size() == weights.size() and not items.is_empty())
	var total := 0.0
	for w in weights:
		total += w
	var roll := _rng.randf() * total
	for i in items.size():
		roll -= weights[i]
		if roll <= 0.0:
			return items[i]
	return items[items.size() - 1]
