extends SceneTree
const Meta = preload("res://src/meta.gd")
func _init() -> void:
	Meta.PATH = "user://rebirth_test.json"
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	for i in 5: await process_frame
	g.goto_lobby()
	for i in 30: await process_frame
	g.start_run()
	for i in 30: await process_frame
	print("BOOT OK state=", g.state)
	quit(0)
