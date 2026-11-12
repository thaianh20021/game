extends SceneTree
# Writes every icon found in assets/ (skills, items) enlarged to shots/icons.png. Run after --import.
const Art = preload("res://src/art.gd")
func _init() -> void:
	Art.build()
	var names = []
	for id in Art.SKILL_IDS:
		names.append("sk_" + id)
	for k in Art.ITEM_KEYS:
		names.append("it_" + k)
	var cols = 12
	var sheet = Image.create_empty(cols * 26, ((names.size() + cols - 1) / cols) * 26, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3a3046"))
	var missing = []
	for i in names.size():
		if not Art.T.has(names[i]):
			missing.append(names[i])
			continue
		var im: Image = Art.T[names[i]].get_image()
		sheet.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i((i % cols) * 26 + 3, (i / cols) * 26 + 3))
	sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	sheet.save_png(ProjectSettings.globalize_path("res://shots/icons.png"))
	print("icons %d, missing %s" % [names.size() - missing.size(), str(missing)])
	quit()
