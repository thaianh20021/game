extends Node2D
## Game flow controller: runs floors 1..MAX_FLOORS, shows death/victory
## overlays and restarts the run (fresh random seed) on R.
## Next milestones: hub scene, meta progression save, class loadouts.

const MAX_FLOORS := 3

@onready var player: Player = $Player

var run_seed := 0
var current_floor := 1
var run_over := false

var _floor_ctrl: FloorController
var _overlay: RunOverlay


func _ready() -> void:
	run_seed = randi()
	print("=== New run | seed %d ===" % run_seed)

	_floor_ctrl = FloorController.new()
	add_child(_floor_ctrl)
	move_child(_floor_ctrl, 0)
	_floor_ctrl.floor_completed.connect(_on_floor_completed)
	_floor_ctrl.start(run_seed, current_floor, player)

	var hud := HUD.new()
	add_child(hud)
	hud.bind(player, _floor_ctrl)

	_overlay = RunOverlay.new()
	add_child(_overlay)

	player.died.connect(_on_player_died)


func _unhandled_input(event: InputEvent) -> void:
	if run_over and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _on_floor_completed() -> void:
	if run_over:
		return
	current_floor += 1
	if current_floor > MAX_FLOORS:
		run_over = true
		_disable_player()
		_overlay.show_message("RUN COMPLETE!",
			"Gold: %d  |  Press R for a new run" % player.gold)
		return
	print("--- Descending to floor %d ---" % current_floor)
	_floor_ctrl.start(run_seed, current_floor, player)


func _on_player_died() -> void:
	if run_over:
		return
	run_over = true
	_disable_player()
	_overlay.show_message("YOU DIED",
		"Floor %d  |  Gold: %d  |  Press R to retry" % [current_floor, player.gold])


func _disable_player() -> void:
	player.set_physics_process(false)
	player.hide()
	player.get_node("CollisionShape2D").set_deferred("disabled", true)
