extends SceneTree
const Art = preload("res://src/art.gd")
func _init() -> void:
	Art.build()
	Art.sheet(3).save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_sheet.png")
	print("sheet ok ", Art.T.size())
	quit(0)
