extends SceneTree
# Cuts the square middle of an image and writes the launcher icons: icon.png (192), icon_fg.png and icon_bg.png (432,
# the adaptive icon: the picture shrunk into the safe middle, and the background colour around it).
# Usage: <godot> --headless --path duvang --script res://tools/icon.gd -- <in.png or jpg>
func _init() -> void:
	var path = OS.get_cmdline_user_args()[0]
	var bytes = FileAccess.get_file_as_bytes(path)
	var im = Image.new()
	if bytes[0] == 0xFF and bytes[1] == 0xD8:
		im.load_jpg_from_buffer(bytes)
	else:
		im.load_png_from_buffer(bytes)
	im.convert(Image.FORMAT_RGBA8)
	var s = mini(im.get_width(), im.get_height())
	var sq = im.get_region(Rect2i((im.get_width() - s) / 2, (im.get_height() - s) / 2, s, s))
	var main = sq.duplicate()
	main.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	main.save_png("res://icon.png")
	var bg_col = sq.get_pixel(4, 4)
	var bg = Image.create(432, 432, false, Image.FORMAT_RGBA8)
	bg.fill(bg_col)
	bg.save_png("res://icon_bg.png")
	var fg = Image.create(432, 432, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))
	var inner = sq.duplicate()
	inner.resize(288, 288, Image.INTERPOLATE_LANCZOS)
	fg.blit_rect(inner, Rect2i(0, 0, 288, 288), Vector2i(72, 72))
	fg.save_png("res://icon_fg.png")
	print("ICON written, background ", bg_col.to_html(false))
	quit()
