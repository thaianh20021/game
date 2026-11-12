extends SceneTree
# Checks the Vietnamese font and writes a specimen to shots/font.png.
const Txt = preload("res://src/font.gd")
func _init() -> void:
	Txt.build()
	var all = "AĂÂBCDĐEÊGHIKLMNOÔƠPQRSTUƯVXY ÁÀẢÃẠ ẮẰẲẴẶ ẤẦẨẪẬ ÉÈẺẼẸ ẾỀỂỄỆ ÍÌỈĨỊ ÓÒỎÕỌ ỐỒỔỖỘ ỚỜỞỠỢ ÚÙỦŨỤ ỨỪỬỮỰ ÝỲỶỸỴ"
	var missing = ""
	for ch in all:
		if ch != " " and not Txt.idx.has(ch):
			missing += ch
	var lower = "đừng để họ biết em nghe được hai tiếng".to_upper()
	for ch in lower:
		if ch != " " and not Txt.idx.has(ch):
			missing += ch
	print("glyphs %d, missing '%s'" % [Txt.idx.size(), missing])
	print("RESULT: %s" % ("OK" if (missing == "" and Txt.idx.size() == 134 + 0) or missing == "" else "FAILED"))
	var lines = ["TRẤN MÕ GỖ   ĐẦM LAU TRO   BẾN PHÀ CŨ", "ĐỪNG ĐỂ HỌ BIẾT EM NGHE ĐƯỢC HAI TIẾNG.", "BÀ CẢ SẬY: MẢNH CHUÔNG TRONG NGỰC NGƯƠI ĐÃ KÊU ĐÊM QUA.",
		"NGƯỜI GÁC PHÀ KHÔNG BỜ   KẺ THẢ LƯỚI   ĐỈA BÙN", "ÁÀẢÃẠ ẮẰẲẴẶ ẤẦẨẪẬ ÉÈẺẼẸ ẾỀỂỄỆ ÍÌỈĨỊ", "ÓÒỎÕỌ ỐỒỔỖỘ ỚỜỞỠỢ ÚÙỦŨỤ ỨỪỬỮỰ ÝỲỶỸỴ Đ"]
	var src: Image = Txt.tex.get_image()
	var im = Image.create_empty(360, lines.size() * 14 + 8, false, Image.FORMAT_RGBA8)
	im.fill(Color("2a2030"))
	for li in lines.size():
		var x = 6
		for ch in lines[li]:
			if Txt.idx.has(ch):
				im.blend_rect(src, Rect2i(Txt.idx[ch] * 7, 0, 6, 11), Vector2i(x, 4 + li * 14))
			x += 6
	im.resize(im.get_width() * 3, im.get_height() * 3, Image.INTERPOLATE_NEAREST)
	im.save_png(ProjectSettings.globalize_path("res://shots/font.png"))
	quit()
