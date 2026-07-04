extends Node2D
## Game flow: class/element select -> floors 1..MAX_FLOORS -> death/victory
## overlay, R restarts the scene (fresh seed, back to class select).
## Next milestones: hub scene, meta progression save, more bosses/biomes.

const MAX_FLOORS := 3
const STARTER_WEAPONS := {
	"blade_warden": "warden_sword",
	"breaker": "pioneer_axe",
	"nightblade": "bone_knife",
	"bulwark": "spiked_board",
	"arcanist": "apprentice_staff",
	"ranger": "hardwood_bow",
	"gunner": "scrap_pistol",
	"soulbinder": "cinder_orb",
	"lightkeeper": "nightwatch_mace",
	"tinkerer": "scrap_pistol",
}

@onready var player: Player = $Player

var run_seed := 0
var current_floor := 1
var run_over := false

var _floor_ctrl: FloorController
var _overlay: RunOverlay


func _ready() -> void:
	player.hide()
	player.set_physics_process(false)
	var select := ClassSelectScreen.new()
	add_child(select)
	select.confirmed.connect(_start_run)


func _start_run(class_id: String, element: String) -> void:
	run_seed = randi()
	print("=== New run | seed %d ===" % run_seed)

	player.apply_class(
		PlayerClassDB.get_class_data(class_id),
		element,
		STARTER_WEAPONS.get(class_id, "warden_sword"))
	player.show()
	player.set_physics_process(true)
	player.died.connect(_on_player_died)

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
