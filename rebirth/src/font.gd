extends RefCounted
# 5x7 pixel font, drawn from a generated atlas.

const G = {
	"A": [14, 17, 17, 31, 17, 17, 17], "B": [30, 17, 17, 30, 17, 17, 30], "C": [14, 17, 16, 16, 16, 17, 14],
	"D": [30, 17, 17, 17, 17, 17, 30], "E": [31, 16, 16, 30, 16, 16, 31], "F": [31, 16, 16, 30, 16, 16, 16],
	"G": [14, 17, 16, 23, 17, 17, 15], "H": [17, 17, 17, 31, 17, 17, 17], "I": [14, 4, 4, 4, 4, 4, 14],
	"J": [7, 2, 2, 2, 2, 18, 12], "K": [17, 18, 20, 24, 20, 18, 17], "L": [16, 16, 16, 16, 16, 16, 31],
	"M": [17, 27, 21, 21, 17, 17, 17], "N": [17, 25, 21, 19, 17, 17, 17], "O": [14, 17, 17, 17, 17, 17, 14],
	"P": [30, 17, 17, 30, 16, 16, 16], "Q": [14, 17, 17, 17, 21, 18, 13], "R": [30, 17, 17, 30, 20, 18, 17],
	"S": [15, 16, 16, 14, 1, 1, 30], "T": [31, 4, 4, 4, 4, 4, 4], "U": [17, 17, 17, 17, 17, 17, 14],
	"V": [17, 17, 17, 17, 17, 10, 4], "W": [17, 17, 17, 21, 21, 27, 17], "X": [17, 17, 10, 4, 10, 17, 17],
	"Y": [17, 17, 10, 4, 4, 4, 4], "Z": [31, 1, 2, 4, 8, 16, 31],
	"0": [14, 17, 19, 21, 25, 17, 14], "1": [4, 12, 4, 4, 4, 4, 14], "2": [14, 17, 1, 2, 4, 8, 31],
	"3": [30, 1, 1, 14, 1, 1, 30], "4": [2, 6, 10, 18, 31, 2, 2], "5": [31, 16, 30, 1, 1, 17, 14],
	"6": [6, 8, 16, 30, 17, 17, 14], "7": [31, 1, 2, 4, 8, 8, 8], "8": [14, 17, 17, 14, 17, 17, 14],
	"9": [14, 17, 17, 15, 1, 2, 12],
	".": [0, 0, 0, 0, 0, 12, 12], ",": [0, 0, 0, 0, 4, 4, 8], "!": [4, 4, 4, 4, 4, 0, 4],
	"?": [14, 17, 1, 2, 4, 0, 4], ":": [0, 4, 4, 0, 4, 4, 0], "-": [0, 0, 0, 14, 0, 0, 0],
	"+": [0, 4, 4, 31, 4, 4, 0], "/": [1, 1, 2, 4, 8, 16, 16], "%": [25, 26, 2, 4, 8, 11, 19],
	"'": [4, 4, 0, 0, 0, 0, 0], "(": [2, 4, 8, 8, 8, 4, 2], ")": [8, 4, 2, 2, 2, 4, 8],
	">": [8, 4, 2, 1, 2, 4, 8], "<": [2, 4, 8, 16, 8, 4, 2], "=": [0, 0, 31, 0, 31, 0, 0],
	"*": [0, 21, 14, 31, 14, 21, 0],
}

static var tex: ImageTexture
static var idx = {}

static func build() -> void:
	var keys = G.keys()
	var img = Image.create_empty(keys.size() * 6, 7, false, Image.FORMAT_RGBA8)
	for i in keys.size():
		idx[keys[i]] = i
		var rows = G[keys[i]]
		for y in 7:
			for x in 5:
				if rows[y] & (16 >> x):
					img.set_pixel(i * 6 + x, y, Color.WHITE)
	tex = ImageTexture.create_from_image(img)

static func width(s: String, sc: int = 1) -> int:
	return s.length() * 6 * sc - sc

static func _run(ci: CanvasItem, pos: Vector2, s: String, col: Color, sc: int) -> void:
	var x = pos.x
	for ch in s:
		if idx.has(ch):
			ci.draw_texture_rect_region(tex, Rect2(x, pos.y, 5 * sc, 7 * sc), Rect2(idx[ch] * 6, 0, 5, 7), col)
		x += 6 * sc

static func text(ci: CanvasItem, pos: Vector2, s: String, col: Color = Color.WHITE, sc: int = 1, shadow: bool = true) -> void:
	s = s.to_upper()
	pos = pos.floor()
	if shadow:
		_run(ci, pos + Vector2(sc, sc), s, Color(0.02, 0.01, 0.05, 0.8 * col.a), sc)
	_run(ci, pos, s, col, sc)

static func ctext(ci: CanvasItem, pos: Vector2, s: String, col: Color = Color.WHITE, sc: int = 1, shadow: bool = true) -> void:
	text(ci, pos - Vector2(width(s, sc) / 2.0, 0), s, col, sc, shadow)
