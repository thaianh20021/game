extends Node2D
## Game entry point. Starts a full floor run: walk through doors to move
## between rooms, clear the boss room to finish the floor.
## Next milestones: HUD (HP/weapon), floor-to-floor progression, hub scene.

const DEMO_SEED := 20260704
const FLOOR_INDEX := 1

@onready var player: Player = $Player


func _ready() -> void:
	var floor_ctrl := FloorController.new()
	add_child(floor_ctrl)
	move_child(floor_ctrl, 0)
	floor_ctrl.start(DEMO_SEED, FLOOR_INDEX, player)
	player.died.connect(func() -> void: print("YOU DIED - run over."))
