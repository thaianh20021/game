extends Node2D
## Demo entry point: generates one floor from a fixed seed, validates it and
## prints the layout, then runs a 500-seed sweep. Replace with the real game
## flow (hub -> dungeon) in the next milestone.

const DEMO_SEED := 20260704


func _ready() -> void:
	var builder := GraphBuilder.new()
	var rooms := builder.build(DEMO_SEED, 1)
	var errors := FloorValidator.validate(rooms)

	print("=== Dungeon Core: floor demo (seed %d) ===" % DEMO_SEED)
	print("Rooms: %d | Validation: %s" % [rooms.size(), "OK" if errors.is_empty() else str(errors)])
	for r in rooms:
		var marker := "*" if r.on_critical_path else " "
		print(" %s[%02d] %-9s depth=%d -> %s" % [marker, r.id, r.type_name(), r.depth, r.neighbors])

	var failures := FloorValidator.run_seed_sweep(500)
	print("Seed sweep (500 floors): %d failures" % failures)
