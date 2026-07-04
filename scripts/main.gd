extends Node2D
## Game entry point. Starts a full floor run with HUD: walk through doors to
## move between rooms, collect loot, clear the boss room to finish the floor.
## Next milestones: floor-to-floor progression, death/restart flow, hub scene.

const DEMO_SEED := 20260704
const FLOOR_INDEX := 1

@onready var player: Player = $Player


func _ready() -> void:
	var floor_ctrl := FloorController.new()
	add_child(floor_ctrl)
	move_child(floor_ctrl, 0)
	floor_ctrl.start(DEMO_SEED, FLOOR_INDEX, player)

	var hud := HUD.new()
	add_child(hud)
	hud.bind(player, floor_ctrl)

	player.died.connect(func() -> void: print("YOU DIED - run over."))
