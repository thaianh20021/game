extends RefCounted
# Skill trees: the Warrior mastery (19 nodes), the Elementalist mastery (19) and their link tree (8).
# "el" on a spell is the mark it leaves; casting a spell of another element than the last one resonates (+20%).
# kind: "a" active skill, "p" passive (ranks), "k" keystone (changes a rule, with a price), "u" ultimate.
# m: 0 Warrior, 1 Elementalist, 2 link tree. b: branch, -1 for the node under the branches.
# pos: [column, row] inside the branch. Row 1 needs 2 points in the branch, row 2 needs 5.
# One point per level. Every rank costs one point. Resetting is free.
# Text is Vietnamese; ids, comments and abbr stay ASCII. abbr is two letters shown on the node.

const F = 1.0 / 12.0
const ROW_NEED = [0, 2, 5]
const ULT_NEED = 8
const BAR = 5

const NODES = {
	# --- Thủ (guard): block, answer, hold the line
	"bulwark": {"n": "THỦ THẾ", "b": 0, "pos": [0, 0], "kind": "a", "max": 1, "cd": 6.0, "rage": 0, "abbr": "TT",
		"desc": "GIỮ THẾ THỦ 1,2 GIÂY. ĐÒN BỊ ĐỠ CHỈ GÂY MỘT PHẦN NĂM SÁT THƯƠNG, VÀ NHÁT CHÉM KẾ TIẾP TRONG 3 GIÂY MẠNH GẤP ĐÔI."},
	"iron": {"n": "DA SẮT", "b": 0, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "DS", "desc": "+3 GIÁP MỖI BẬC."},
	"steady": {"n": "VỮNG CHÃI", "b": 0, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "VC", "desc": "+12 MÁU MỖI BẬC."},
	"rush": {"n": "XÔ KHIÊN", "b": 0, "pos": [0, 1], "kind": "a", "max": 1, "cd": 7.0, "rage": 20, "abbr": "XK",
		"desc": "LAO TỚI 90 BƯỚC. MỌI KẺ TRÊN ĐƯỜNG CHỊU 150% TẤN CÔNG VÀ BỊ CHOÁNG, KỂ CẢ KẺ NẶNG."},
	"counter": {"n": "PHẢN LỰC", "b": 0, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "PL", "desc": "MỖI ĐÒN ĐỠ ĐƯỢC CHO 15 NỘ MỖI BẬC."},
	"unbroken": {"n": "BẤT KHUẤT", "b": 0, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "BK",
		"desc": "THỦ THẾ HỒI NHANH GẤP ĐÔI VÀ MỖI ĐÒN ĐỠ ĐƯỢC HỒI 5% MÁU. CÁI GIÁ: CHỈ CÒN MỘT LẦN NÉ."},
	# --- Nộ (fury): rage, blood, risk
	"spin": {"n": "XOÁY", "b": 1, "pos": [0, 0], "kind": "a", "max": 1, "cd": 0.0, "rage": 40, "abbr": "XO",
		"desc": "XOAY TRỌN MỘT VÒNG KIẾM. 240% TẤN CÔNG LÊN MỌI THỨ QUANH NGƯỜI."},
	"bloodlust": {"n": "KHÁT MÁU", "b": 1, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "KM", "desc": "+1,5% HÚT MÁU MỖI BẬC."},
	"hotblood": {"n": "MÁU NÓNG", "b": 1, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "MN", "desc": "+15% NỘ NHẬN ĐƯỢC MỖI BẬC."},
	"cry": {"n": "HÉT TRẬN", "b": 1, "pos": [0, 1], "kind": "a", "max": 1, "cd": 14.0, "rage": 0, "abbr": "HT",
		"desc": "NHẬN 30 NỘ. TRONG 6 GIÂY GÂY THÊM 30% SÁT THƯƠNG VÀ CHỊU THÊM 20%."},
	"laststand": {"n": "TỬ THỦ", "b": 1, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "TU", "desc": "DƯỚI 35% MÁU, GÂY THÊM 12% SÁT THƯƠNG MỖI BẬC."},
	"price": {"n": "GIÁ MÁU", "b": 1, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "GM",
		"desc": "NỘ KHÔNG CÒN BỊ TIÊU. NỘ ĐẦY CỘNG TỚI 30% SÁT THƯƠNG. CÁI GIÁ: KỸ NĂNG TỐN NỘ NAY TỐN 8% MÁU."},
	# --- Binh khí (arms): reach, weight, control
	"lunge": {"n": "ĐÂM XUYÊN", "b": 2, "pos": [0, 0], "kind": "a", "max": 1, "cd": 5.0, "rage": 15, "abbr": "DX",
		"desc": "ĐÂM XUYÊN 90 BƯỚC QUA HÀNG ĐỊCH. 160% TẤN CÔNG LÊN MỌI KẺ BẠN LƯỚT QUA."},
	"reach": {"n": "TẦM DÀI", "b": 2, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "TD", "desc": "+3 TẦM ĐÁNH CHO MỌI NHÁT CHÉM MỖI BẬC."},
	"heavy": {"n": "TAY NẶNG", "b": 2, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "TN", "desc": "ĐÒN CUỐI CỦA CHUỖI GÂY THÊM 12% MỖI BẬC."},
	"slam": {"n": "DẬP ĐẤT", "b": 2, "pos": [0, 1], "kind": "a", "max": 1, "cd": 8.0, "rage": 30, "abbr": "DD",
		"desc": "180% TẤN CÔNG TRONG MỘT VÒNG RỘNG. PHÁ THẾ CỦA KẺ NẶNG NHANH GẤP ĐÔI."},
	"sunder": {"n": "BỔ GIÁP", "b": 2, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "BG", "desc": "+10% SÁT THƯƠNG LÊN KẺ ĐANG CHOÁNG MỖI BẬC."},
	"fourth": {"n": "ĐÒN THỨ TƯ", "b": 2, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "D4",
		"desc": "CHUỖI CHÉM CÓ THÊM ĐÒN THỨ TƯ: 240% TẤN CÔNG, CUNG RỘNG. CÁI GIÁ: MỌI NHÁT CHÉM LẤY ĐÀ CHẬM HƠN MỘT NHỊP."},
	# --- needs 8 points spent anywhere
	"toll": {"n": "HỒI CHUÔNG", "b": -1, "pos": [0, 0], "kind": "u", "max": 1, "cd": 45.0, "rage": 0, "abbr": "HC",
		"desc": "MẢNH CHUÔNG NGÂN THÀNH TIẾNG. 400% TẤN CÔNG LÊN MỌI THỨ GẦN ĐÓ, TẤT CẢ BỊ CHOÁNG 1,5 GIÂY."},

	# ================= second mastery: Nguyên Tố Sư (m 1). Opens when the shard shows its second face.
	# Three marks it leaves on foes: CHÁY (damage over time), LẠNH (half speed), GIẬT (takes more damage).
	"ember": {"n": "TIA THAN", "m": 1, "el": "burn", "b": 0, "pos": [0, 0], "kind": "a", "max": 1, "cd": 1.5, "rage": 10, "abbr": "TH",
		"desc": "PHÓNG MỘT TIA LỬA GÂY 120% TẤN CÔNG. KẺ TRÚNG ĐÒN BỊ CHÁY 4 GIÂY, MỖI GIÂY 30% TẤN CÔNG."},
	"kindle": {"n": "MỒI LỬA", "m": 1, "b": 0, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "ML", "desc": "CHÁY GÂY THÊM 20% MỖI BẬC."},
	"pyre": {"n": "GIÀN THIÊU", "m": 1, "b": 0, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "GT",
		"desc": "KẺ CHẾT KHI ĐANG CHÁY SẼ NỔ, GÂY 150% TẤN CÔNG QUANH NÓ. VỤ NỔ KHÔNG KÍCH NỔ TIẾP. CÁI GIÁ: CHÁY CHỈ KÉO DÀI MỘT NỬA."},
	"ring": {"n": "VÒNG SƯƠNG", "m": 1, "el": "chill", "b": 1, "pos": [0, 0], "kind": "a", "max": 1, "cd": 8.0, "rage": 20, "abbr": "VS",
		"desc": "MỘT VÒNG GIÁ BUỐT QUANH NGƯỜI. 100% TẤN CÔNG, MỌI KẺ CHẠM PHẢI BỊ LẠNH 4 GIÂY."},
	"deep": {"n": "RÉT SÂU", "m": 1, "b": 1, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "RS", "desc": "LẠNH KÉO DÀI THÊM 1 GIÂY MỖI BẬC."},
	"brittle": {"n": "GIÒN", "m": 1, "b": 1, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "GI",
		"desc": "KẺ BỊ LẠNH NHẬN THÊM 25% SÁT THƯƠNG TỪ ĐÒN CỦA BẠN. CÁI GIÁ: NÉ HỒI CHẬM GẤP ĐÔI."},
	"spark": {"n": "SÉT CHUYỀN", "m": 1, "el": "shock", "b": 2, "pos": [0, 0], "kind": "a", "max": 1, "cd": 5.0, "rage": 25, "abbr": "SC",
		"desc": "SÉT ĐÁNH KẺ GẦN NHẤT 140% TẤN CÔNG RỒI NHẢY SANG 3 KẺ NỮA, MỖI KẺ 100%. TẤT CẢ BỊ GIẬT 5 GIÂY, NHẬN THÊM 15% SÁT THƯƠNG."},
	"static": {"n": "TĨNH ĐIỆN", "m": 1, "b": 2, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "TI", "desc": "KẺ BỊ GIẬT NHẬN THÊM 5% SÁT THƯƠNG NỮA MỖI BẬC."},
	"overload": {"n": "QUÁ TẢI", "m": 1, "b": 2, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "QT",
		"desc": "SÉT CHUYỀN NHẢY SANG 6 KẺ THAY VÌ 3. CÁI GIÁ: TỐN THÊM 10 NỘ."},
	"firewall": {"n": "TƯỜNG LỬA", "m": 1, "el": "burn", "b": 0, "pos": [0, 1], "kind": "a", "max": 1, "cd": 9.0, "rage": 20, "abbr": "TF",
		"desc": "DỰNG MỘT VỆT LỬA NGANG TRƯỚC MẶT TRONG 4 GIÂY. KẺ NÀO BƯỚC QUA ĐỀU BỊ CHÁY."},
	"heat": {"n": "HƠI NÓNG", "m": 1, "b": 0, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "HN", "desc": "+4% SÁT THƯƠNG LÊN KẺ ĐANG CHÁY MỖI BẬC."},
	"ash": {"n": "TRO TÀN", "m": 1, "b": 0, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "TR", "desc": "KẺ CHẾT KHI ĐANG CHÁY TRẢ 3 NỘ MỖI BẬC."},
	"shard": {"n": "MŨI BĂNG", "m": 1, "el": "chill", "b": 1, "pos": [0, 1], "kind": "a", "max": 1, "cd": 6.0, "rage": 15, "abbr": "MB",
		"desc": "PHÓNG MỘT MŨI BĂNG XUYÊN THẲNG, 130% TẤN CÔNG VÀ GÂY LẠNH. KẺ ĐANG LẠNH BỊ ĐÓNG BĂNG 1 GIÂY (TRỪ BOSS)."},
	"bitter": {"n": "GIÁ BUỐT", "m": 1, "b": 1, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "GB", "desc": "KẺ ĐANG LẠNH GÂY ÍT HƠN 5% SÁT THƯƠNG MỖI BẬC."},
	"icearmor": {"n": "BĂNG GIÁP", "m": 1, "b": 1, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "BA", "desc": "DÙNG PHÉP BĂNG CHO +3 GIÁP MỖI BẬC TRONG 4 GIÂY."},
	"cage": {"n": "LỒNG SÉT", "m": 1, "el": "shock", "b": 2, "pos": [0, 1], "kind": "a", "max": 1, "cd": 12.0, "rage": 25, "abbr": "LS",
		"desc": "ĐẶT MỘT LỒNG SÉT TẠI ĐIỂM NGẮM TRONG 4 GIÂY. KẺ BÊN TRONG BỊ GIẬT LIÊN TỤC VÀ NHẬN 30% TẤN CÔNG MỖI GIÂY."},
	"relay": {"n": "DẪN TRUYỀN", "m": 1, "b": 2, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "DT", "desc": "SÉT NHẢY XA HƠN 15 MỖI BẬC."},
	"surge": {"n": "QUÁ ÁP", "m": 1, "b": 2, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "QA", "desc": "5% CƠ HỘI MỖI BẬC ĐỂ PHÉP SÉT KHÔNG TỐN NỘ."},
	# needs 8 points in this mastery. Only one ultimate fits on the bar: R over a learned one in the tree picks it.
	"tam": {"n": "TAM TAI", "m": 1, "b": -1, "pos": [0, 0], "kind": "u", "max": 1, "cd": 55.0, "rage": 0, "abbr": "3T",
		"desc": "TẠI ĐIỂM NGẮM, BA NHỊP CÁCH NHAU NỬA GIÂY: LỬA, BĂNG, SÉT. MỖI NHỊP 200% TẤN CÔNG VÀ ĐỂ LẠI DẤU CỦA HỆ ĐÓ."},

	# ================= link tree: Chiến Binh + Nguyên Tố Sư = Kiếm Bão (m 2).
	# Every node makes a skill of one mastery change how the other behaves. Needs 3 points in each mastery.
	"charged": {"n": "THỦ TÍCH ĐIỆN", "m": 2, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TC",
		"desc": "THỦ THẾ + SÉT. ĐỠ ĐƯỢC MỘT ĐÒN THÌ LƯỠI KIẾM TÍCH ĐIỆN: 3 NHÁT CHÉM KẾ TIẾP GÂY GIẬT."},
	"coldiron": {"n": "SẮT LẠNH", "m": 2, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "SL",
		"desc": "THỦ THẾ + BĂNG. KHI ĐỠ ĐƯỢC MỘT ĐÒN, MỌI KẺ ĐỨNG GẦN BẠN BỊ LẠNH."},
	"stoke": {"n": "THỔI LỬA", "m": 2, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TL",
		"desc": "XOÁY + LỬA. NẾU XOÁY TRÚNG MỘT KẺ ĐANG CHÁY, MỌI KẺ KHÁC TRÚNG ĐÒN CŨNG BỐC CHÁY."},
	"furnace": {"n": "TIM LÒ", "m": 2, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TM",
		"desc": "NỘ + LỬA. MỖI KẺ ĐANG CHÁY CHO BẠN 2 NỘ MỖI GIÂY. CHỈ TÍNH TỐI ĐA 3 KẺ."},
	"afterglow": {"n": "DƯ QUANG", "m": 2, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "DQ",
		"desc": "HỒI CHUÔNG + CẢ BA. MỌI THỨ TRÚNG HỒI CHUÔNG ĐỀU BỊ CHÁY, LẠNH VÀ GIẬT."},
	"shatter": {"n": "VỠ BĂNG", "m": 2, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "VB",
		"desc": "CHUỖI CHÉM + BĂNG. ĐÒN CUỐI CỦA CHUỖI PHÁ VỠ LẠNH: THÊM 80% SÁT THƯƠNG LÊN KẺ ĐÓ VÀ LÀM NÓ CHOÁNG, KỂ CẢ KẺ NẶNG."},
	"conduct": {"n": "DẪN ĐIỆN", "m": 2, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DN",
		"desc": "ĐÂM XUYÊN HOẶC XÔ KHIÊN + SÉT. LƯỚT QUA MỘT KẺ ĐANG BỊ GIẬT SẼ PHÓNG SÉT CHUYỀN TỪ NÓ. NHIỀU NHẤT 2 GIÂY MỘT LẦN."},
	"tempest": {"n": "KIẾM BÃO", "m": 2, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "KB",
		"desc": "TRONG 6 GIÂY SAU MỘT PHÉP, MỖI NHÁT CHÉM ĐỂ LẠI DẤU CỦA PHÉP ĐÓ. CÁI GIÁ: PHÉP HỒI CHẬM HƠN 30%. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= third mastery: Sát Thủ (m 3). Danger points (0 to 5) come from striking a foe from behind,
	# a foe that is stunned or chilled, or from a dodge that made a hit miss. Finishers spend them all.
	"shadow": {"n": "BƯỚC BÓNG", "m": 3, "b": 0, "pos": [0, 0], "kind": "a", "max": 1, "cd": 6.0, "rage": 10, "abbr": "BB",
		"desc": "HIỆN RA SAU LƯNG MỘT KẺ GẦN ĐIỂM NGẮM (TẦM 120). NHÁT CHÉM KẾ TIẾP CHẮC CHẮN CHO 1 ĐIỂM HIỂM."},
	"light": {"n": "NHẸ CHÂN", "m": 3, "b": 0, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "NC", "desc": "+3% TỐC CHẠY MỖI BẬC."},
	"backstab": {"n": "ĐÁNH LÉN", "m": 3, "b": 0, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "DL", "desc": "NHÁT CHÉM TỪ SAU LƯNG GÂY THÊM 8% MỖI BẬC."},
	"smoke": {"n": "MÀN KHÓI", "m": 3, "b": 0, "pos": [0, 1], "kind": "a", "max": 1, "cd": 14.0, "rage": 0, "abbr": "MK",
		"desc": "3 GIÂY KẺ ĐỊCH THƯỜNG MẤT DẤU BẠN, BẠN CHẠY NHANH HƠN 30%. NHÁT CHÉM ĐẦU TIÊN RA KHỎI KHÓI CHÍ MẠNG. BOSS KHÔNG BỊ LỪA."},
	"escape": {"n": "THOÁT HIỂM", "m": 3, "b": 0, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "TO", "desc": "NÉ HỒI NHANH HƠN 15% MỖI BẬC."},
	"unseen": {"n": "VÔ HÌNH", "m": 3, "b": 0, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "VH",
		"desc": "SAU MỖI ĐÒN KẾT LIỄU, BẠN MẤT DẤU 1,5 GIÂY. CÁI GIÁ: MÁU TỐI ĐA GIẢM 20%."},
	"venom": {"n": "TẨM ĐỘC", "m": 3, "b": 1, "pos": [0, 0], "kind": "a", "max": 1, "cd": 12.0, "rage": 0, "abbr": "TA",
		"desc": "TRONG 8 GIÂY, MỖI NHÁT CHÉM GÂY 1 CỘNG DỒN ĐỘC: 20% TẤN CÔNG MỖI GIÂY, 4 GIÂY, TỐI ĐA 5 CỘNG DỒN."},
	"potent": {"n": "ĐỘC ĐẬM", "m": 3, "b": 1, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "DA", "desc": "ĐỘC GÂY THÊM 10% MỖI BẬC."},
	"linger": {"n": "NGẤM SÂU", "m": 3, "b": 1, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "NS", "desc": "ĐỘC KÉO DÀI THÊM 1 GIÂY MỖI BẬC."},
	"darts": {"n": "PHI TIÊU ĐỘC", "m": 3, "b": 1, "pos": [0, 1], "kind": "a", "max": 1, "cd": 4.0, "rage": 10, "abbr": "PT",
		"desc": "NÉM 3 PHI TIÊU HÌNH QUẠT. MỖI CÁI 60% TẤN CÔNG VÀ 1 CỘNG DỒN ĐỘC."},
	"infect": {"n": "NHIỄM TRÙNG", "m": 3, "b": 1, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "NT", "desc": "KẺ TRÚNG ĐỘC GÂY ÍT HƠN 5% SÁT THƯƠNG MỖI BẬC."},
	"burst": {"n": "BÙNG ĐỘC", "m": 3, "b": 1, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "BD",
		"desc": "ĐÒN KẾT LIỄU LÀM TOÀN BỘ ĐỘC CÒN LẠI TRÊN KẺ ĐÓ PHÁT TÁC NGAY. CÁI GIÁ: ĐỘC CHỈ CỘNG DỒN TỚI 3."},
	"slash": {"n": "RẠCH", "m": 3, "b": 2, "pos": [0, 0], "kind": "a", "max": 1, "cd": 3.0, "rage": 0, "abbr": "RA",
		"desc": "KẾT LIỄU. TIÊU HẾT ĐIỂM HIỂM: 60% TẤN CÔNG, CỘNG THÊM 60% CHO MỖI ĐIỂM."},
	"keen": {"n": "SẮC LẸM", "m": 3, "b": 2, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "SE", "desc": "+3% CHÍ MẠNG MỖI BẬC."},
	"vital": {"n": "CHỖ HIỂM", "m": 3, "b": 2, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "CH", "desc": "ĐÒN CHÍ MẠNG GÂY THÊM 10% MỖI BẬC."},
	"exec": {"n": "HÀNH QUYẾT", "m": 3, "b": 2, "pos": [0, 1], "kind": "a", "max": 1, "cd": 10.0, "rage": 0, "abbr": "HQ",
		"desc": "KẾT LIỄU, CẦN ÍT NHẤT 1 ĐIỂM HIỂM. 100% TẤN CÔNG MỖI ĐIỂM. KẺ THƯỜNG CÒN DƯỚI 6% MÁU MỖI ĐIỂM THÌ CHẾT NGAY. BOSS VÀ TINH NHUỆ CHỈ NHẬN SÁT THƯƠNG."},
	"ruthless": {"n": "TÀN NHẪN", "m": 3, "b": 2, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "TB", "desc": "+5% SÁT THƯƠNG LÊN KẺ CÒN DƯỚI 35% MÁU MỖI BẬC."},
	"six": {"n": "SÁU ĐIỂM", "m": 3, "b": 2, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "S6",
		"desc": "GIỮ ĐƯỢC 6 ĐIỂM HIỂM. KẾT LIỄU Ở 6 ĐIỂM CHẮC CHẮN CHÍ MẠNG. CÁI GIÁ: NHÁT CHÉM THƯỜNG GÂY ÍT HƠN 15%."},
	"cuts": {"n": "NGÀN VẾT CẮT", "m": 3, "b": -1, "pos": [0, 0], "kind": "u", "max": 1, "cd": 50.0, "rage": 0, "abbr": "NV",
		"desc": "LƯỚT QUA TỐI ĐA 6 KẺ GẦN NHẤT. MỖI KẺ NHẬN 180% TẤN CÔNG VÀ CHO BẠN 1 ĐIỂM HIỂM. KHÔNG THỂ BỊ ĐÁNH KHI ĐANG LƯỚT."},

	# ================= link tree: Chiến Binh + Sát Thủ = Lưỡi Bóng (m 4)
	"lb_open": {"n": "MỞ SƠ HỞ", "m": 4, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "MS",
		"desc": "THỦ THẾ + ĐIỂM HIỂM. ĐỠ ĐƯỢC MỘT ĐÒN CHO 2 ĐIỂM HIỂM."},
	"lb_fallen": {"n": "CHÉM KẺ NGÃ", "m": 4, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "CN",
		"desc": "CHOÁNG + RẠCH. RẠCH LÊN KẺ ĐANG CHOÁNG KHÔNG TIÊU ĐIỂM HIỂM. NHIỀU NHẤT 4 GIÂY MỘT LẦN."},
	"lb_ring": {"n": "VÒNG ĐỘC", "m": 4, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "VD",
		"desc": "XOÁY + ĐỘC. XOÁY ĐƯA MỌI KẺ TRÚNG ĐÒN LÊN BẰNG SỐ CỘNG DỒN ĐỘC CAO NHẤT TRONG SỐ CHÚNG."},
	"lb_boil": {"n": "MÁU SÔI", "m": 4, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MO",
		"desc": "NỘ + HÀNH QUYẾT. HÀNH QUYẾT GIẾT ĐƯỢC KẺ ĐỊCH TRẢ 30 NỘ."},
	"lb_cry": {"n": "HÉT TRONG KHÓI", "m": 4, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "HK",
		"desc": "HÉT TRẬN + MÀN KHÓI. DÙNG HÉT TRẬN KHI ĐANG TRONG KHÓI KÉO DÀI KHÓI THÊM 2 GIÂY."},
	"lb_last": {"n": "NHÁT KẾT", "m": 4, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "NK",
		"desc": "CHUỖI CHÉM + ĐIỂM HIỂM. ĐÒN CUỐI CỦA CHUỖI LUÔN CHO 1 ĐIỂM HIỂM."},
	"lb_follow": {"n": "THEO BÓNG", "m": 4, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TG",
		"desc": "ĐÂM XUYÊN + BƯỚC BÓNG. TRONG 3 GIÂY SAU ĐÂM XUYÊN, BƯỚC BÓNG KHÔNG TỐN NỘ."},
	"lb_twin": {"n": "SONG THỦ", "m": 4, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "ST",
		"desc": "CHUỖI CHÉM NHANH HƠN 20% VÀ MỖI NHÁT THỨ HAI GÂY 1 CỘNG DỒN ĐỘC. CÁI GIÁ: KHÔNG DÙNG ĐƯỢC THỦ THẾ. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Nguyên Tố Sư + Sát Thủ = Dạ Lôi (m 5)
	"dl_rupture": {"n": "RẠCH BÙNG", "m": 5, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "RB",
		"desc": "RẠCH + CHÁY. RẠCH LÊN KẺ ĐANG CHÁY GÂY NGAY TOÀN BỘ PHẦN CHÁY CÒN LẠI VÀ DẬP LỬA."},
	"dl_coat": {"n": "ĐỘC MANG HỆ", "m": 5, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DH",
		"desc": "TẨM ĐỘC + DẤU. KHI TẨM ĐỘC ĐANG BẬT, NHÁT CHÉM ĐẶT THÊM DẤU CỦA PHÉP CUỐI BẠN DÙNG. 4 GIÂY MỘT LẦN MỖI KẺ."},
	"dl_frozen": {"n": "LẠNH LÀ HỞ", "m": 5, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "LH",
		"desc": "LẠNH + ĐÁNH LÉN. KẺ ĐANG LẠNH LUÔN BỊ COI LÀ HỞ LƯNG."},
	"dl_fog": {"n": "SƯƠNG GIÁ", "m": 5, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "SG",
		"desc": "MÀN KHÓI + BĂNG. PHÉP BĂNG DÙNG KHI ĐANG TRONG KHÓI GÂY LẠNH DÀI GẤP ĐÔI."},
	"dl_mark": {"n": "DẤU MỞ ĐƯỜNG", "m": 5, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "DM",
		"desc": "DẤU + ĐIỂM HIỂM. ĐẶT MỘT DẤU MÀ KẺ ĐÓ CHƯA CÓ CHO 1 ĐIỂM HIỂM. NHIỀU NHẤT 1,5 GIÂY MỘT LẦN."},
	"dl_step": {"n": "BƯỚC SÉT", "m": 5, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "BS",
		"desc": "BƯỚC BÓNG + SÉT. BƯỚC BÓNG ĐỂ LẠI TIA SÉT Ở NƠI ĐI VÀ NƠI ĐẾN: KẺ ĐỨNG GẦN BỊ GIẬT."},
	"dl_judge": {"n": "XỬ BẰNG SÉT", "m": 5, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "XS",
		"desc": "HÀNH QUYẾT + GIẬT. HÀNH QUYẾT LÊN KẺ ĐANG GIẬT PHÓNG SÉT CHUYỀN TỪ NÓ SANG 3 KẺ KHÁC."},
	"dl_three": {"n": "TAM ĐỘC", "m": 5, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "T3",
		"desc": "KẾT LIỄU LÊN KẺ MANG ĐỦ CHÁY, LẠNH, GIẬT GÂY THÊM 60% VÀ XÓA CẢ BA DẤU. CÁI GIÁ: DẤU CỦA BẠN NGẮN HƠN 30%. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= fourth mastery: Thuật Sĩ Linh Hồn (m 6). Souls (0 to 5): one for each foe that dies within 120,
	# one for every tenth of a boss's life. Echoes fight for you, cannot be hit, and what they deal gives no rage.
	"summon": {"n": "GỌI DƯ ẢNH", "m": 6, "b": 0, "pos": [0, 0], "kind": "a", "max": 1, "cd": 3.0, "rage": 0, "abbr": "GD",
		"desc": "TỐN 1 HỒN. GỌI MỘT DƯ ẢNH CHIẾN ĐẤU 20 GIÂY, TỐI ĐA 3. MỖI ĐÒN CỦA NÓ GÂY 35% TẤN CÔNG."},
	"horde": {"n": "ĐÔNG QUÂN", "m": 6, "b": 0, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "DG", "desc": "DƯ ẢNH ĐÁNH NHANH HƠN 8% MỖI BẬC. BẬC 3: TỐI ĐA 4 DƯ ẢNH."},
	"sharp": {"n": "SẮC BÓNG", "m": 6, "b": 0, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "SB", "desc": "DƯ ẢNH GÂY THÊM 10% MỖI BẬC."},
	"sacrifice": {"n": "HIẾN TẾ", "m": 6, "b": 0, "pos": [0, 1], "kind": "a", "max": 1, "cd": 6.0, "rage": 0, "abbr": "HE",
		"desc": "CHO DƯ ẢNH GẦN ĐIỂM NGẮM NHẤT NỔ TUNG: 220% TẤN CÔNG QUANH NÓ."},
	"lasting": {"n": "DAI DẲNG", "m": 6, "b": 0, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "DI", "desc": "DƯ ẢNH TỒN TẠI THÊM 4 GIÂY MỖI BẬC."},
	"legion": {"n": "QUÂN ĐOÀN", "m": 6, "b": 0, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "QD",
		"desc": "SỐ DƯ ẢNH TỐI ĐA GẤP ĐÔI. CÁI GIÁ: MỖI DƯ ẢNH CHỈ GÂY MỘT NỬA SÁT THƯƠNG."},
	"weaken": {"n": "LỜI NGUYỀN YẾU", "m": 6, "b": 1, "pos": [0, 0], "kind": "a", "max": 1, "cd": 10.0, "rage": 15, "abbr": "NY",
		"desc": "NGUYỀN MỌI KẺ TRONG MỘT VÙNG TẠI ĐIỂM NGẮM 8 GIÂY: CHÚNG GÂY ÍT HƠN 25% SÁT THƯƠNG."},
	"deepcurse": {"n": "NGUYỀN SÂU", "m": 6, "b": 1, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "NU", "desc": "NGUYỀN KÉO DÀI THÊM 1,5 GIÂY MỖI BẬC."},
	"rot": {"n": "MỤC RỮA", "m": 6, "b": 1, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "MR", "desc": "KẺ BỊ NGUYỀN NHẬN THÊM 4% SÁT THƯƠNG MỖI BẬC."},
	"chain": {"n": "XIỀNG HỒN", "m": 6, "b": 1, "pos": [0, 1], "kind": "a", "max": 1, "cd": 12.0, "rage": 20, "abbr": "XH",
		"desc": "NỐI TỐI ĐA 3 KẺ GẦN ĐIỂM NGẮM TRONG 6 GIÂY. SÁT THƯƠNG LÊN MỘT KẺ CHIA 30% SANG NHỮNG KẺ CÒN LẠI. PHẦN ĐƯỢC CHIA KHÔNG CHIA TIẾP."},
	"spread": {"n": "LÂY LAN", "m": 6, "b": 1, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "LL", "desc": "KẺ BỊ NGUYỀN CHẾT TRUYỀN LỜI NGUYỀN SANG 1 KẺ GẦN ĐÓ MỖI BẬC."},
	"oneword": {"n": "MỘT LỜI", "m": 6, "b": 1, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "M1",
		"desc": "CHỈ MỘT KẺ MANG LỜI NGUYỀN, NHƯNG HIỆU LỰC GẤP ĐÔI VÀ KHÔNG HẾT HẠN. CÁI GIÁ: LỜI NGUYỀN YẾU CHỈ TRÚNG KẺ GẦN ĐIỂM NGẮM NHẤT."},
	"scythe": {"n": "LƯỠI HÁI", "m": 6, "b": 2, "pos": [0, 0], "kind": "a", "max": 1, "cd": 5.0, "rage": 15, "abbr": "LI",
		"desc": "QUÉT MỘT CUNG RỘNG, 150% TẤN CÔNG. MỖI KẺ TRÚNG HỒI 2% MÁU. GIẾT BẰNG ĐÒN NÀY CHO THÊM 1 HỒN."},
	"harvest": {"n": "GẶT HÁI", "m": 6, "b": 2, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "GA", "desc": "10% CƠ HỘI MỖI BẬC ĐỂ KẺ CHẾT CHO 2 HỒN."},
	"feed": {"n": "HỒN NUÔI", "m": 6, "b": 2, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "HO", "desc": "MỖI HỒN ĐANG GIỮ HỒI 0,3 MÁU MỖI GIÂY MỖI BẬC."},
	"soulform": {"n": "HÓA HỒN", "m": 6, "b": 2, "pos": [0, 1], "kind": "a", "max": 1, "cd": 15.0, "rage": 0, "abbr": "HH",
		"desc": "TIÊU HẾT HỒN. TRONG 8 GIÂY, GÂY THÊM 12% SÁT THƯƠNG CHO MỖI HỒN ĐÃ TIÊU."},
	"jar": {"n": "BÌNH HỒN", "m": 6, "b": 2, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "BI", "desc": "GIỮ ĐƯỢC THÊM 1 HỒN MỖI BẬC."},
	"hunger": {"n": "ĐÓI HỒN", "m": 6, "b": 2, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "DO",
		"desc": "MỖI HỒN ĐANG GIỮ CHO +6% SÁT THƯƠNG. CÁI GIÁ: CỨ 4 GIÂY MẤT 1 HỒN."},
	"night": {"n": "ĐÊM RẠN NHỎ", "m": 6, "b": -1, "pos": [0, 0], "kind": "u", "max": 1, "cd": 70.0, "rage": 0, "abbr": "DR",
		"desc": "TRONG 8 GIÂY, MỌI KẺ ĐỊCH CHẾT GẦN BẠN ĐỨNG DẬY LÀM DƯ ẢNH, KHÔNG TÍNH VÀO GIỚI HẠN. CHÚNG TAN KHI HẾT GIỜ."},

	# ================= link tree: Chiến Binh + Thuật Sĩ = Kiếm Tang (m 7)
	"kt_proxy": {"n": "THẾ MẠNG", "m": 7, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TE",
		"desc": "THỦ THẾ + HIẾN TẾ. ĐỠ ĐƯỢC MỘT ĐÒN LÀM DƯ ẢNH GẦN BẠN NHẤT TỰ NỔ NHƯ HIẾN TẾ. 6 GIÂY MỘT LẦN."},
	"kt_curse": {"n": "RẢI NGUYỀN", "m": 7, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "RN",
		"desc": "DẬP ĐẤT + NGUYỀN. DẬP ĐẤT TRÚNG MỘT KẺ BỊ NGUYỀN THÌ MỌI KẺ TRÚNG ĐÒN ĐỀU BỊ NGUYỀN."},
	"kt_spin": {"n": "XOÁY HỒN", "m": 7, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "XN",
		"desc": "XOÁY + HỒN. KHI THIẾU NỘ, XOÁY TIÊU 1 HỒN THAY CHO NỘ."},
	"kt_rally": {"n": "THÚC QUÂN", "m": 7, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TQ",
		"desc": "HÉT TRẬN + DƯ ẢNH. KHI HÉT TRẬN CÒN HIỆU LỰC, DƯ ẢNH ĐÁNH NHANH HƠN 30%."},
	"kt_reap": {"n": "NHÁT GẶT", "m": 7, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "NG",
		"desc": "CHUỖI CHÉM + HỒN. KẺ CHẾT VÌ ĐÒN CUỐI CỦA CHUỖI CHO THÊM 1 HỒN."},
	"kt_scythe": {"n": "HÁI THEO NHỊP", "m": 7, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "HP",
		"desc": "TAY NẶNG + LƯỠI HÁI. LƯỠI HÁI HƯỞNG TAY NẶNG NHƯ ĐÒN CUỐI CỦA CHUỖI."},
	"kt_toll": {"n": "CHUÔNG GỌI HỒN", "m": 7, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "CG",
		"desc": "HỒI CHUÔNG + NGUYỀN. MỌI KẺ TRÚNG HỒI CHUÔNG ĐỀU BỊ NGUYỀN."},
	"kt_shroud": {"n": "ÁO TANG", "m": 7, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "AT",
		"desc": "MỖI HỒN ĐANG GIỮ CHO +3 GIÁP VÀ +2% HÚT MÁU. CÁI GIÁ: GỌI DƯ ẢNH TỐN 2 HỒN. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Nguyên Tố Sư + Thuật Sĩ = Tro Hồn (m 8)
	"th_ash": {"n": "TRO THÀNH HỒN", "m": 8, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TO",
		"desc": "DẤU + HỒN. KẺ CHẾT KHI ĐANG MANG CHÁY, LẠNH HOẶC GIẬT CHO THÊM 1 HỒN. 2 GIÂY MỘT LẦN."},
	"th_eternal": {"n": "LỬA KHÔNG TẮT", "m": 8, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "LK",
		"desc": "CHÁY + NGUYỀN. CHÁY TRÊN KẺ BỊ NGUYỀN KHÔNG HẾT HẠN CHỪNG NÀO LỜI NGUYỀN CÒN."},
	"th_cold": {"n": "HÁI KẺ LẠNH", "m": 8, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "HL",
		"desc": "LƯỠI HÁI + LẠNH. LƯỠI HÁI TRÚNG KẺ ĐANG LẠNH HỒI MÁU GẤP ĐÔI."},
	"th_tint": {"n": "BÓNG MANG HỆ", "m": 8, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "BM",
		"desc": "GỌI DƯ ẢNH + DẤU. DƯ ẢNH MANG HỆ CỦA PHÉP CUỐI BẠN DÙNG LÚC GỌI; ĐÒN CỦA NÓ ĐỂ LẠI DẤU ĐÓ. 2 GIÂY MỘT LẦN MỖI KẺ."},
	"th_sac": {"n": "TẾ THEO HỆ", "m": 8, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "TY",
		"desc": "HIẾN TẾ + DẤU. VỤ NỔ HIẾN TẾ ĐỂ LẠI DẤU CỦA DƯ ẢNH ĐÓ (CẦN BÓNG MANG HỆ)."},
	"th_chain": {"n": "SÉT THEO XIỀNG", "m": 8, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "SX",
		"desc": "SÉT CHUYỀN + XIỀNG HỒN. SÉT CHUYỀN ĐÁNH THÊM MỌI KẺ ĐANG BỊ XIỀNG, 100% TẤN CÔNG VÀ GIẬT."},
	"th_reso": {"n": "HỒN CỘNG HƯỞNG", "m": 8, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "HG",
		"desc": "HÓA HỒN + CỘNG HƯỞNG. TRONG LÚC HÓA HỒN, MỌI PHÉP ĐỀU CỘNG HƯỞNG."},
	"th_fire": {"n": "HỒN LỬA", "m": 8, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "HU",
		"desc": "KHI GIỮ TỪ 3 HỒN, MỖI PHÉP NGUYÊN TỐ TỰ TIÊU 1 HỒN VÀ KHÔNG HỒI CHIÊU. CÁI GIÁ: KHÔNG GỌI ĐƯỢC DƯ ẢNH. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Sát Thủ + Thuật Sĩ = Gặt Hồn (m 9)
	"gh_step": {"n": "BÓNG Ở LẠI", "m": 9, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "BO",
		"desc": "BƯỚC BÓNG + DƯ ẢNH. BƯỚC BÓNG GỌI MỘT DƯ ẢNH 5 GIÂY Ở NƠI BẠN ĐẾN, KHÔNG TỐN HỒN. 6 GIÂY MỘT LẦN."},
	"gh_back": {"n": "HÁI SAU LƯNG", "m": 9, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "HS",
		"desc": "LƯỠI HÁI + ĐÁNH LÉN. LƯỠI HÁI TRÚNG TỪ SAU LƯNG LUÔN CHÍ MẠNG."},
	"gh_plague": {"n": "ĐỘC KẺ BỊ NGUYỀN", "m": 9, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "DK",
		"desc": "ĐỘC + NGUYỀN. KẺ BỊ NGUYỀN CHỊU ĐƯỢC THÊM 2 CỘNG DỒN ĐỘC."},
	"gh_link": {"n": "ĐỘC THEO XIỀNG", "m": 9, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DX",
		"desc": "XIỀNG HỒN + ĐỘC. KHI NỐI XIỀNG, MỌI KẺ BỊ NỐI LÊN BẰNG SỐ CỘNG DỒN ĐỘC CAO NHẤT."},
	"gh_points": {"n": "HỒN THÀNH ĐIỂM", "m": 9, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "HD",
		"desc": "HÓA HỒN + ĐIỂM HIỂM. HÓA HỒN CHO SỐ ĐIỂM HIỂM BẰNG SỐ HỒN ĐÃ TIÊU."},
	"gh_take": {"n": "THU HỒN", "m": 9, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TU",
		"desc": "KẾT LIỄU + HỒN. KẾT LIỄU GIẾT ĐƯỢC CHO THÊM 1 HỒN CHO MỖI 2 ĐIỂM HIỂM ĐÃ TIÊU."},
	"gh_raise": {"n": "DỰNG XÁC", "m": 9, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DC",
		"desc": "HÀNH QUYẾT + DƯ ẢNH. KẺ BỊ HÀNH QUYẾT GIẾT ĐỨNG DẬY LÀM DƯ ẢNH 20 GIÂY, KHÔNG TỐN HỒN. 6 GIÂY MỘT LẦN."},
	"gh_cheat": {"n": "LỪA TỬ THẦN", "m": 9, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "LT",
		"desc": "KHI NHẬN ĐÒN CHÍ TỬ, TIÊU 3 HỒN ĐỂ CÒN 1 MÁU VÀ MẤT DẤU 2 GIÂY. 60 GIÂY MỘT LẦN. CÁI GIÁ: GIỮ ĐƯỢC ÍT HƠN 1 HỒN. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= Hộ Vệ (m 10). Rhythm: KHIÊN 0-100, taken before life; fades 5 a second after 4 seconds without being hit.
	"raise": {"n": "DỰNG KHIÊN", "m": 10, "b": 0, "pos": [0, 0], "kind": "a", "max": 1, "cd": 8.0, "rage": 0, "abbr": "DK",
		"desc": "NHẬN NGAY 40 KHIÊN. KHIÊN ĐỠ SÁT THƯƠNG TRƯỚC MÁU."},
	"thick": {"n": "DÀY DẠN", "m": 10, "b": 0, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "DY", "desc": "KHIÊN TỐI ĐA +10 MỖI BẬC."},
	"endure": {"n": "BỀN BỈ", "m": 10, "b": 0, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "BB", "desc": "KHIÊN TỰ MẤT CHẬM HƠN 20% MỖI BẬC."},
	"wall": {"n": "TƯỜNG CHẮN", "m": 10, "b": 0, "pos": [0, 1], "kind": "a", "max": 1, "cd": 14.0, "rage": 20, "abbr": "TC",
		"desc": "CẮM MỘT BỨC TƯỜNG RỘNG 3 Ô TRƯỚC MẶT TRONG 5 GIÂY. TƯỜNG CHẶN ĐẠN VÀ CHẶN ĐƯỜNG ĐI."},
	"stand": {"n": "ĐỨNG VỮNG", "m": 10, "b": 0, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "DV",
		"desc": "CÒN KHIÊN THÌ ĐÒN TRÚNG KHÔNG NGẮT ĐÒN ĐÁNH CỦA BẠN. BẬC 2: CÒN KHIÊN THÌ KHÔNG BỊ LÀM CHẬM."},
	"fortress": {"n": "PHÁO ĐÀI", "m": 10, "b": 0, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "PD",
		"desc": "KHIÊN TỐI ĐA GẤP ĐÔI VÀ KHÔNG TỰ MẤT. CÁI GIÁ: TỐC CHẠY GIẢM 15%."},
	"bash": {"n": "ĐẬP KHIÊN", "m": 10, "b": 1, "pos": [0, 0], "kind": "a", "max": 1, "cd": 4.0, "rage": 10, "abbr": "DP",
		"desc": "140% TẤN CÔNG, CHOÁNG 0,6 GIÂY. CÓ TỪ 50 KHIÊN THÌ TIÊU 25 KHIÊN ĐỂ GÂY THÊM 100%."},
	"thorns": {"n": "GAI KHIÊN", "m": 10, "b": 1, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "GK",
		"desc": "KẺ ĐÁNH VÀO KHIÊN CỦA BẠN NHẬN 10% TẤN CÔNG MỖI BẬC. SÁT THƯƠNG PHỤ, KHÔNG KÍCH HOẠT GÌ THÊM."},
	"debt": {"n": "NỢ MÁU", "m": 10, "b": 1, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "NM", "desc": "SAU KHI KHIÊN ĐỠ MỘT ĐÒN, ĐÒN KẾ CỦA BẠN GÂY THÊM 8% MỖI BẬC."},
	"verdict": {"n": "PHÁN QUYẾT", "m": 10, "b": 1, "pos": [0, 1], "kind": "a", "max": 1, "cd": 12.0, "rage": 0, "abbr": "PQ",
		"desc": "TIÊU HẾT KHIÊN. MỌI KẺ QUANH BẠN NHẬN 3% TẤN CÔNG CHO MỖI ĐIỂM KHIÊN ĐÃ TIÊU."},
	"hammer": {"n": "BÚA TẠ", "m": 10, "b": 1, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "BT", "desc": "ĐẬP KHIÊN PHÁ THẾ NHANH HƠN 20% MỖI BẬC."},
	"payback": {"n": "ĂN MIẾNG TRẢ MIẾNG", "m": 10, "b": 1, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "AM",
		"desc": "30% SÁT THƯƠNG KHIÊN ĐỠ ĐƯỢC DỘI LẠI KẺ ĐÁNH. CÁI GIÁ: KHIÊN TỐI ĐA GIẢM 30%."},
	"taunt": {"n": "KHIÊU KHÍCH", "m": 10, "b": 2, "pos": [0, 0], "kind": "a", "max": 1, "cd": 10.0, "rage": 0, "abbr": "KK",
		"desc": "KẺ ĐỊCH TRONG 90 BỊ KHIÊU KHÍCH 4 GIÂY VÀ LAO VÀO BẠN. +20 KHIÊN CHO MỖI KẺ, TỐI ĐA 3 KẺ."},
	"share": {"n": "CHIA KHIÊN", "m": 10, "b": 2, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "CK", "desc": "10% KHIÊN BẠN NHẬN ĐƯỢC MỖI BẬC CŨNG HỒI THÀNH MÁU."},
	"watch": {"n": "CANH GÁC", "m": 10, "b": 2, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "CG", "desc": "+2 GIÁP MỖI BẬC; +4 MỖI BẬC KHI CÓ DƯ ẢNH HAY ĐỒNG MINH TRONG 80."},
	"cover": {"n": "VÒNG CHE", "m": 10, "b": 2, "pos": [0, 1], "kind": "a", "max": 1, "cd": 16.0, "rage": 25, "abbr": "VC",
		"desc": "VẼ MỘT VÒNG CHE DƯỚI CHÂN TRONG 5 GIÂY. ĐỨNG TRONG VÒNG, BẠN NHẬN ÍT HƠN 30% SÁT THƯƠNG."},
	"firm": {"n": "KIÊN ĐỊNH", "m": 10, "b": 2, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "KD", "desc": "THỜI GIAN BỊ LÀM CHẬM HAY TRÓI NGẮN HƠN 25% MỖI BẬC."},
	"standin": {"n": "THẾ THÂN", "m": 10, "b": 2, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "TT",
		"desc": "MỖI DƯ ẢNH HAY ĐỒNG MINH TRONG 100 GIẢM 8% SÁT THƯƠNG BẠN NHẬN, TỐI ĐA 32%; KHÔNG CÓ AI THÌ KHIÊU KHÍCH CHO GẤP ĐÔI KHIÊN. CÁI GIÁ: MỌI NGUỒN HỒI MÁU GIẢM 30%."},
	"bronze": {"n": "THÀNH ĐỒNG", "m": 10, "b": -1, "pos": [0, 0], "kind": "u", "max": 1, "cd": 60.0, "rage": 0, "abbr": "TD",
		"desc": "TRONG 5 GIÂY KHIÊN LUÔN ĐẦY VÀ KHÔNG GIẢM. KHI HẾT GIỜ, NỔ 300% TẤN CÔNG QUANH NGƯỜI."},

	# ================= link tree: Chiến Binh + Hộ Vệ = Trấn Thủ (m 11)
	"tt_block": {"n": "ĐỠ DÀY", "m": 11, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "DY",
		"desc": "THỦ THẾ + KHIÊN. MỖI ĐÒN ĐỠ ĐƯỢC BẰNG THỦ THẾ CHO +25 KHIÊN."},
	"tt_rush": {"n": "ĐÀ KHIÊN", "m": 11, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DA",
		"desc": "XÔ KHIÊN + KHIÊN. XÔ KHIÊN GÂY THÊM 1% CHO MỖI ĐIỂM KHIÊN ĐANG CÓ, TỐI ĐA THÊM 100%."},
	"tt_rage": {"n": "KHIÊN NỘ", "m": 11, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "KN",
		"desc": "NỘ + KHIÊN. CỨ 10 KHIÊN BỊ ĐÁNH MẤT CHO 4 NỘ."},
	"tt_pull": {"n": "KÉO VÀO", "m": 11, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "KV",
		"desc": "XOÁY + KHIÊU KHÍCH. XOÁY TRÚNG KẺ ĐANG BỊ KHIÊU KHÍCH KÉO NÓ SÁT BẠN VÀ CHOÁNG NÓ 0,5 GIÂY."},
	"tt_order": {"n": "HIỆU LỆNH", "m": 11, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "HL",
		"desc": "HÉT TRẬN + VÒNG CHE. ĐỨNG TRONG VÒNG CHE, HÉT TRẬN KHÔNG LÀM BẠN CHỊU THÊM SÁT THƯƠNG."},
	"tt_topple": {"n": "XÔ TƯỜNG", "m": 11, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "XT",
		"desc": "DẬP ĐẤT + TƯỜNG CHẮN. DẬP ĐẤT CẠNH TƯỜNG CHẮN LÀM TƯỜNG ĐỔ VỀ PHÍA TRƯỚC: 200% TẤN CÔNG THEO VỆT, TƯỜNG MẤT."},
	"tt_beat": {"n": "NHỊP KHIÊN", "m": 11, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "NK",
		"desc": "CHUỖI CHÉM + ĐẬP KHIÊN. ĐẬP KHIÊN HƯỞNG TAY NẶNG NHƯ ĐÒN CUỐI CHUỖI VÀ KHÔNG NGẮT CHUỖI CHÉM."},
	"tt_true": {"n": "CHÂN THÀNH", "m": 11, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "CT",
		"desc": "KHI CÒN KHIÊN, MỌI NHÁT CHÉM ĐỀU HƯỞNG TAY NẶNG. CÁI GIÁ: KHI HẾT KHIÊN BẠN CHỊU THÊM 15% SÁT THƯƠNG. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Nguyên Tố Sư + Hộ Vệ = Lũy Sấm (m 12)
	"ls_shell": {"n": "VỎ CỘNG HƯỞNG", "m": 12, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "VO",
		"desc": "CỘNG HƯỞNG + KHIÊN. MỖI PHÉP ĐƯỢC CỘNG HƯỞNG CHO +12 KHIÊN."},
	"ls_wall": {"n": "TƯỜNG CHÁY", "m": 12, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TY",
		"desc": "TƯỜNG CHẮN + TƯỜNG LỬA. ĐẶT GẦN NHAU THÌ TƯỜNG CHẮN BỐC CHÁY, ĐỐT KẺ CHẠM VÀO, VÀ CẢ HAI TỒN TẠI THÊM 3 GIÂY."},
	"ls_mark": {"n": "ÁN THEO HỆ", "m": 12, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "AH",
		"desc": "PHÁN QUYẾT + DẤU. PHÁN QUYẾT ĐỂ LẠI DẤU CỦA PHÉP CUỐI BẠN DÙNG."},
	"ls_freeze": {"n": "GỌI KẺ LẠNH", "m": 12, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "GL",
		"desc": "KHIÊU KHÍCH + LẠNH. KHIÊU KHÍCH TRÚNG KẺ ĐANG LẠNH ĐÓNG BĂNG NÓ 1 GIÂY (TRỪ BOSS)."},
	"ls_crack": {"n": "ĐẬP VỠ", "m": 12, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DV",
		"desc": "ĐẬP KHIÊN + LẠNH. ĐẬP KHIÊN LÊN KẺ ĐANG LẠNH TIÊU LẠNH: THÊM 60% VÀ CHOÁNG 1,2 GIÂY."},
	"ls_volt": {"n": "KHIÊN ĐIỆN", "m": 12, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "KD",
		"desc": "KHIÊN + SÉT. KẺ ĐÁNH VÀO KHIÊN CỦA BẠN BỊ GIẬT 3 GIÂY. 2 GIÂY MỘT LẦN MỖI KẺ."},
	"ls_cage": {"n": "LỒNG TRONG VÒNG", "m": 12, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "LV",
		"desc": "LỒNG SÉT + VÒNG CHE. LỒNG SÉT ĐẶT VÀO VÒNG CHE RỘNG BẰNG VÒNG VÀ TỒN TẠI LÂU BẰNG VÒNG."},
	"ls_eye": {"n": "TÂM BÃO", "m": 12, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "TB",
		"desc": "VÒNG SƯƠNG, TAM TAI VÀ LỒNG SÉT ĐẶT DƯỚI CHÂN RỘNG THÊM 40% VÀ MẠNH THÊM 20%; TAM TAI NỔ QUANH BẠN. CÁI GIÁ: TIA THAN VÀ MŨI BĂNG CHỈ BAY NỬA TẦM. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Sát Thủ + Hộ Vệ = Dạ Vệ (m 13)
	"dv_dodge": {"n": "NÉ THÀNH KHIÊN", "m": 13, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "NK",
		"desc": "NÉ + KHIÊN + ĐIỂM HIỂM. NÉ TRÚNG MỘT ĐÒN CHO +15 KHIÊN. KHIÊN BỊ ĐÁNH VỠ HẾT CHO +2 ĐIỂM HIỂM, 8 GIÂY MỘT LẦN."},
	"dv_step": {"n": "BƯỚC CÓ KHIÊN", "m": 13, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "BK",
		"desc": "BƯỚC BÓNG + KHIÊN. BƯỚC BÓNG CHO +15 KHIÊN."},
	"dv_smoke": {"n": "KHÓI TRONG VÒNG", "m": 13, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "KV",
		"desc": "MÀN KHÓI + VÒNG CHE. MÀN KHÓI DÙNG KHI ĐỨNG TRONG VÒNG CHE KÉO DÀI GẤP ĐÔI."},
	"dv_thorn": {"n": "GAI ĐỘC", "m": 13, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "GD",
		"desc": "GAI KHIÊN + ĐỘC. KẺ ĐÁNH VÀO KHIÊN CỦA BẠN NHẬN 1 CỘNG DỒN ĐỘC. 1 GIÂY MỘT LẦN MỖI KẺ."},
	"dv_verdict": {"n": "ÁN ĐỘC", "m": 13, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "AD",
		"desc": "PHÁN QUYẾT + ĐỘC. PHÁN QUYẾT GÂY 1 CỘNG DỒN ĐỘC CHO MỖI 25 KHIÊN ĐÃ TIÊU."},
	"dv_open": {"n": "HỞ SƯỜN", "m": 13, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "HS",
		"desc": "KHIÊN + ĐIỂM HIỂM. KẺ VỪA ĐÁNH VÀO KHIÊN CỦA BẠN BỊ COI LÀ HỞ LƯNG TRONG 2 GIÂY."},
	"dv_cut": {"n": "ĐẬP RỒI RẠCH", "m": 13, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DR",
		"desc": "ĐẬP KHIÊN + RẠCH. RẠCH TRONG 1,5 GIÂY SAU ĐẬP KHIÊN ĐƯỢC TÍNH THÊM 1 ĐIỂM HIỂM."},
	"dv_fake": {"n": "KHIÊN GIẢ", "m": 13, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "KG",
		"desc": "KHI KHIÊN VỠ, BẠN TAN VÀO BÓNG 2 GIÂY: KẺ ĐỊCH MẤT DẤU BẠN. 12 GIÂY MỘT LẦN. CÁI GIÁ: KHIÊN TỐI ĐA GIẢM 25%. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Thuật Sĩ Linh Hồn + Hộ Vệ = Mộ Vệ (m 14)
	"mv_coat": {"n": "ÁO CHO BÓNG", "m": 14, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "AB",
		"desc": "GỌI DƯ ẢNH + KHIÊN. DƯ ẢNH MỚI GỌI SỐNG THÊM 1 GIÂY CHO MỖI 10 KHIÊN BẠN ĐANG CÓ."},
	"mv_die": {"n": "CHẾT THAY", "m": 14, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "CT",
		"desc": "DƯ ẢNH + MÁU. KHI MỘT ĐÒN SẮP LẤY HƠN 20% MÁU CỦA BẠN, MỘT DƯ ẢNH TAN THAY VÀ BẠN KHÔNG MẤT MÁU. 10 GIÂY MỘT LẦN."},
	"mv_tchain": {"n": "XIỀNG KẺ BỊ GỌI", "m": 14, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "XG",
		"desc": "KHIÊU KHÍCH + XIỀNG HỒN. KẺ BỊ KHIÊU KHÍCH TỰ BỊ NỐI XIỀNG HỒN 6 GIÂY, TỐI ĐA 3 KẺ."},
	"mv_judge": {"n": "ÁN KẺ BỊ NGUYỀN", "m": 14, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "AN",
		"desc": "PHÁN QUYẾT + NGUYỀN. PHÁN QUYẾT LÊN KẺ BỊ NGUYỀN GÂY THÊM 40% VÀ LÀM MỚI LỜI NGUYỀN."},
	"mv_ring": {"n": "VÒNG NGUYỀN", "m": 14, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "VN",
		"desc": "VÒNG CHE + LỜI NGUYỀN YẾU. KẺ ĐỊCH BƯỚC VÀO VÒNG CHE BỊ NGUYỀN 4 GIÂY."},
	"mv_soul": {"n": "HỒN HÓA KHIÊN", "m": 14, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "HK",
		"desc": "HỒN + KHIÊN. MỖI HỒN NHẬN ĐƯỢC CHO +8 KHIÊN."},
	"mv_tithe": {"n": "TẾ LẤY KHIÊN", "m": 14, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TK",
		"desc": "HIẾN TẾ + KHIÊN. MỖI LẦN HIẾN TẾ TRẢ CHO BẠN 20 KHIÊN."},
	"mv_tomb": {"n": "LĂNG MỘ", "m": 14, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "LM",
		"desc": "THÀNH ĐỒNG ĐỒNG THỜI GỌI ĐỦ SỐ DƯ ẢNH TỐI ĐA, KHÔNG TỐN HỒN. CÁI GIÁ: THÀNH ĐỒNG HỒI CHẬM THÊM 30 GIÂY. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= Thợ Săn (m 15). Rhythm: TẬP TRUNG. Two seconds with no foe within 80 and the next blow or skill is 40% stronger.
	# The hound (Chó Săn Vọng) has 40% of your life and bites for 30% attack; when it falls it gets up 12 seconds later.
	"aimed": {"n": "PHÁT NGẮM", "m": 15, "b": 0, "pos": [0, 0], "kind": "a", "max": 1, "cd": 5.0, "rage": 15, "abbr": "PN",
		"desc": "ĐỨNG NGẮM 0,6 GIÂY RỒI BẮN MỘT MŨI TÊN XUYÊN, 220% TẤN CÔNG. BỊ ĐÁNH TRÚNG LÚC ĐANG NGẮM THÌ MẤT PHÁT BẮN."},
	"hawk": {"n": "MẮT ƯNG", "m": 15, "b": 0, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "MU", "desc": "+4% SÁT THƯƠNG LÊN KẺ CÁCH BẠN TRÊN 100 MỖI BẬC."},
	"steadyh": {"n": "TAY VỮNG", "m": 15, "b": 0, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "TV", "desc": "TẬP TRUNG TÍCH NHANH HƠN 20% MỖI BẬC."},
	"rain": {"n": "MƯA TÊN", "m": 15, "b": 0, "pos": [0, 1], "kind": "a", "max": 1, "cd": 10.0, "rage": 25, "abbr": "MT",
		"desc": "MƯA TÊN TRÚT XUỐNG MỘT VÙNG TẠI ĐIỂM NGẮM TRONG 3 GIÂY. MỖI NỬA GIÂY 40% TẤN CÔNG."},
	"pierce": {"n": "XUYÊN GIÁP", "m": 15, "b": 0, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "XG", "desc": "ĐÒN TẦM XA PHÁ THẾ NHANH HƠN 15% MỖI BẬC."},
	"oneshot": {"n": "MỘT PHÁT", "m": 15, "b": 0, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "1P",
		"desc": "PHÁT NGẮM LÊN KẺ CÒN ĐẦY MÁU GÂY THÊM 100%. CÁI GIÁ: BỊ ĐÁNH TRÚNG LÀ MẤT HẾT TẬP TRUNG, PHẢI TÍCH LẠI TỪ ĐẦU."},
	"snare": {"n": "BẪY KẸP", "m": 15, "b": 1, "pos": [0, 0], "kind": "a", "max": 1, "cd": 6.0, "rage": 0, "abbr": "BK",
		"desc": "ĐẶT MỘT BẪY KẸP DƯỚI CHÂN (TỐI ĐA 3 BẪY). KẺ DẪM PHẢI BỊ TRÓI 2 GIÂY VÀ NHẬN 120% TẤN CÔNG."},
	"trapper": {"n": "THỢ BẪY", "m": 15, "b": 1, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "TB", "desc": "BẪY HỒI NHANH HƠN 10% MỖI BẬC. BẬC 3: ĐẶT ĐƯỢC TỐI ĐA 4 BẪY."},
	"spring": {"n": "SẬP BẪY", "m": 15, "b": 1, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "SB", "desc": "KẺ ĐANG BỊ TRÓI NHẬN THÊM 6% SÁT THƯƠNG MỖI BẬC."},
	"mine": {"n": "BẪY NỔ", "m": 15, "b": 1, "pos": [0, 1], "kind": "a", "max": 1, "cd": 10.0, "rage": 15, "abbr": "BN",
		"desc": "ĐẶT MỘT BẪY NỔ. KHI CÓ KẺ TỚI GẦN, NÓ NỔ 200% TẤN CÔNG TRONG MỘT VÙNG NHỎ."},
	"far": {"n": "GIĂNG XA", "m": 15, "b": 1, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "GX", "desc": "NÉM BẪY TỚI ĐIỂM NGẮM THAY VÌ ĐẶT DƯỚI CHÂN: XA 90, BẬC 2 XA 150."},
	"linkup": {"n": "LIÊN HOÀN", "m": 15, "b": 1, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "LH",
		"desc": "MỘT BẪY SẬP THÌ MỌI BẪY KHÁC TRONG 100 SẬP THEO. CÁI GIÁ: BẪY TỰ BIẾN MẤT SAU 8 GIÂY."},
	"sic": {"n": "XUA THÚ", "m": 15, "b": 2, "pos": [0, 0], "kind": "a", "max": 1, "cd": 7.0, "rage": 0, "abbr": "XT",
		"desc": "CHÓ SĂN VỒ KẺ GẦN ĐIỂM NGẮM: 160% TẤN CÔNG VÀ GIỮ CHÂN NÓ 1,5 GIÂY."},
	"sturdy": {"n": "THÚ KHỎE", "m": 15, "b": 2, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "TK", "desc": "MÁU CỦA THÚ +15% MỖI BẬC."},
	"fangs": {"n": "NANH VUỐT", "m": 15, "b": 2, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "NV", "desc": "SÁT THƯƠNG CỦA THÚ +10% MỖI BẬC."},
	"hunt": {"n": "DẤU SĂN", "m": 15, "b": 2, "pos": [0, 1], "kind": "a", "max": 1, "cd": 8.0, "rage": 0, "abbr": "DS",
		"desc": "ĐÁNH DẤU KẺ GẦN ĐIỂM NGẮM 10 GIÂY. NÓ NHẬN THÊM 15% SÁT THƯƠNG TỪ BẠN VÀ THÚ, VÀ THÚ ƯU TIÊN NÓ. MỖI LÚC CHỈ MỘT KẺ."},
	"bond": {"n": "GẮN BÓ", "m": 15, "b": 2, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "GB", "desc": "THÚ GỤC THÌ ĐỨNG DẬY NHANH HƠN 25% MỖI BẬC."},
	"pack": {"n": "BẦY ĐÔI", "m": 15, "b": 2, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "BD",
		"desc": "BẠN CÓ HAI CON CHÓ SĂN. CÁI GIÁ: MỖI CON CHỈ CÓ 60% MÁU VÀ SÁT THƯƠNG."},
	"bighunt": {"n": "CUỘC SĂN", "m": 15, "b": -1, "pos": [0, 0], "kind": "u", "max": 1, "cd": 60.0, "rage": 0, "abbr": "CS",
		"desc": "TRONG 8 GIÂY, MỌI KẺ ĐỊCH GẦN BẠN MANG DẤU SĂN VÀ TẬP TRUNG LUÔN ĐẦY."},

	# ================= link tree: Chiến Binh + Thợ Săn = Tiên Phong (m 16)
	"tp_toss": {"n": "HẤT VÀO BẪY", "m": 16, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "HB",
		"desc": "XÔ KHIÊN + BẪY KẸP. KẺ BỊ XÔ KHIÊN TRÚNG VĂNG RA 40; VĂNG VÀO BẪY THÌ BỊ TRÓI DÀI GẤP ĐÔI."},
	"tp_down": {"n": "BẮN KẺ NGÃ", "m": 16, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "BN",
		"desc": "PHÁT NGẮM + CHOÁNG. PHÁT NGẮM NHẮM VÀO KẺ ĐANG CHOÁNG THÌ BẮN NGAY, KHÔNG CẦN ĐỨNG NGẮM."},
	"tp_pack": {"n": "THÚ TRẬN", "m": 16, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TT",
		"desc": "HÉT TRẬN + THÚ. THÚ CŨNG HƯỞNG HÉT TRẬN, VÀ MỖI CÚ CẮN CỦA NÓ LÚC ĐÓ CHO BẠN 3 NỘ."},
	"tp_spin": {"n": "HẤT TÊN", "m": 16, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "HT",
		"desc": "XOÁY + MƯA TÊN. XOÁY TRONG VÙNG MƯA TÊN LÀM VÙNG ĐÓ RỘNG THÊM 40% CHO TỚI KHI HẾT."},
	"tp_rhythm": {"n": "GIỮ NHỊP", "m": 16, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "GN",
		"desc": "CHUỖI CHÉM + TẬP TRUNG. CHÉM LIÊN TỤC 3 GIÂY KHÔNG BỊ NGẮT CŨNG LÀM ĐẦY TẬP TRUNG, KHÔNG CẦN KHOẢNG CÁCH."},
	"tp_quake": {"n": "RUNG BẪY", "m": 16, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "RB",
		"desc": "DẬP ĐẤT + BẪY. DẬP ĐẤT LÀM MỌI BẪY TRONG VÙNG SẬP NGAY VÀ GÂY THÊM 50%."},
	"tp_signal": {"n": "RA HIỆU", "m": 16, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "RH",
		"desc": "CHUỖI CHÉM + DẤU SĂN. ĐÒN CUỐI CHUỖI LÊN KẺ MANG DẤU SĂN LÀM MỚI DẤU VÀ GỌI THÚ VỒ NÓ. 3 GIÂY MỘT LẦN."},
	"tp_big": {"n": "ĐI SĂN LỚN", "m": 16, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "SL",
		"desc": "BẠN VÀ THÚ GÂY THÊM 25% LÊN TINH ANH VÀ BOSS MANG DẤU SĂN. CÁI GIÁ: DẤU SĂN HỒI CHẬM GẤP ĐÔI. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Nguyên Tố Sư + Thợ Săn = Thiên Tiễn (m 17)
	"tn_burnrain": {"n": "TÊN CHÁY", "m": 17, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TC",
		"desc": "MƯA TÊN + TƯỜNG LỬA. MƯA TÊN ĐẶT CHẠM TƯỜNG LỬA LÀM MỌI KẺ TRÚNG TÊN BỊ CHÁY."},
	"tn_pool": {"n": "VŨNG LỬA", "m": 17, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "VL",
		"desc": "BẪY NỔ + LỬA. BẪY NỔ ĐỂ LẠI MỘT VŨNG LỬA 3 GIÂY, KẺ BƯỚC VÀO BỊ CHÁY."},
	"tn_tint": {"n": "TÊN MANG HỆ", "m": 17, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "TH",
		"desc": "PHÁT NGẮM + DẤU. PHÁT NGẮM ĐỂ LẠI DẤU CỦA PHÉP CUỐI BẠN DÙNG."},
	"tn_ice": {"n": "BẪY BĂNG", "m": 17, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "BB",
		"desc": "BẪY KẸP + BĂNG. KẺ DÍNH BẪY KẸP BỊ LẠNH; KẺ ĐANG LẠNH DÍNH BẪY BỊ ĐÓNG BĂNG 1,5 GIÂY (TRỪ BOSS)."},
	"tn_layer": {"n": "DẤU TRÊN DẤU", "m": 17, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DD",
		"desc": "DẤU SĂN + DẤU. CHÁY, LẠNH VÀ GIẬT TRÊN KẺ MANG DẤU SĂN KÉO DÀI THÊM 50%."},
	"tn_jump": {"n": "SÉT QUA THÚ", "m": 17, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "SQ",
		"desc": "SÉT CHUYỀN + THÚ. KHI THÚ CÒN ĐỨNG, SÉT CHUYỀN NHẢY THÊM 1 LẦN."},
	"tn_focus": {"n": "NGẮM TRONG PHÉP", "m": 17, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "NP",
		"desc": "TẬP TRUNG + CỘNG HƯỞNG. PHÁT NGẮM BẮN TRONG 6 GIÂY SAU MỘT PHÉP ĐƯỢC CỘNG HƯỞNG (+20%)."},
	"tn_tri": {"n": "MŨI TÊN BA HỆ", "m": 17, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "3H",
		"desc": "PHÁT NGẮM TRÚNG KẺ MANG ĐỦ CHÁY, LẠNH VÀ GIẬT NỔ 150% QUANH NÓ VÀ LAN CẢ BA DẤU. CÁI GIÁ: PHÁT NGẮM NGẮM LÂU HƠN 0,3 GIÂY. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Sát Thủ + Thợ Săn = Truy Ảnh (m 18)
	"ta_track": {"n": "BÁM DẤU", "m": 18, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "BD",
		"desc": "BƯỚC BÓNG + DẤU SĂN. BƯỚC BÓNG TỚI KẺ MANG DẤU SĂN KHÔNG HỒI CHIÊU. 2 GIÂY MỘT LẦN."},
	"ta_smoke": {"n": "BẪY TRONG KHÓI", "m": 18, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "BK",
		"desc": "MÀN KHÓI + BẪY. BẪY ĐẶT LÚC ĐANG TRONG MÀN KHÓI GÂY THÊM 30%."},
	"ta_eye": {"n": "NGẮM CHỖ HIỂM", "m": 18, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "NH",
		"desc": "TẬP TRUNG + ĐIỂM HIỂM. ĐÒN TIÊU TẬP TRUNG CHO +2 ĐIỂM HIỂM."},
	"ta_fang": {"n": "NANH ĐỘC", "m": 18, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "ND",
		"desc": "THÚ + ĐỘC. THÚ CẮN KẺ ĐANG TRÚNG ĐỘC KÉO DÀI ĐỘC THÊM 2 GIÂY. 2 GIÂY MỘT LẦN MỖI KẺ."},
	"ta_snap": {"n": "SẬP LÀ HỞ", "m": 18, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "SH",
		"desc": "BẪY + ĐIỂM HIỂM. MỖI KẺ DẪM BẪY CỦA BẠN CHO +1 ĐIỂM HIỂM."},
	"ta_shot": {"n": "PHÁT KẾT LIỄU", "m": 18, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "PK",
		"desc": "PHÁT NGẮM + ĐIỂM HIỂM. PHÁT NGẮM TIÊU HẾT ĐIỂM HIỂM, THÊM 25% CHO MỖI ĐIỂM."},
	"ta_pass": {"n": "CHUYỀN DẤU", "m": 18, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "CD",
		"desc": "KẾT LIỄU + DẤU SĂN. KẺ MANG DẤU SĂN CHẾT THÌ DẤU CHUYỂN SANG KẺ GẦN NHẤT VÀ BẠN NHẬN 1 ĐIỂM HIỂM."},
	"ta_night": {"n": "SĂN ĐÊM", "m": 18, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "SD",
		"desc": "KẺ MANG DẤU SĂN LUÔN BỊ COI LÀ HỞ LƯNG. CÁI GIÁ: KHI KHÔNG CÓ DẤU SĂN NÀO, ĐIỂM HIỂM TỐI ĐA CHỈ LÀ 3. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Thuật Sĩ Linh Hồn + Thợ Săn = Hồn Lạp (m 19)
	"hl_stand": {"n": "BÓNG THẾ CHỖ", "m": 19, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "BT",
		"desc": "THÚ + DƯ ẢNH. KHI THÚ GỤC, MỘT DƯ ẢNH ĐỨNG THAY CHO TỚI KHI THÚ DẬY, KHÔNG TÍNH VÀO GIỚI HẠN."},
	"hl_tithe": {"n": "TẾ THÚ", "m": 19, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TT",
		"desc": "HIẾN TẾ + THÚ. KHÔNG CÓ DƯ ẢNH THÌ HIẾN TẾ NHẮM VÀO THÚ: THÚ NỔ 150%, KHÔNG CHẾT NHƯNG GỤC 4 GIÂY."},
	"hl_curse": {"n": "DẤU NGUYỀN", "m": 19, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "DN",
		"desc": "DẤU SĂN + NGUYỀN. KẺ MANG DẤU SĂN TỰ BỊ NGUYỀN."},
	"hl_rain": {"n": "MƯA NGUYỀN", "m": 19, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MN",
		"desc": "MƯA TÊN + NGUYỀN. MƯA TÊN TRÚNG MỘT KẺ BỊ NGUYỀN THÌ MỌI KẺ TRONG VÙNG ĐỀU BỊ NGUYỀN."},
	"hl_chain": {"n": "TÊN THEO XIỀNG", "m": 19, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "TX",
		"desc": "PHÁT NGẮM + XIỀNG HỒN. PHÁT NGẮM TRÚNG KẺ BỊ XIỀNG THÌ BAY TIẾP THEO XIỀNG TỚI CÁC KẺ BỊ NỐI, MỖI KẺ 60%."},
	"hl_reap": {"n": "THÚ GẶT", "m": 19, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TG",
		"desc": "THÚ + HỒN. KẺ BỊ THÚ GIẾT CHO HỒN DÙ Ở XA BẠN; THÚ GỤC CHO 2 HỒN."},
	"hl_soul": {"n": "BẪY HỒN", "m": 19, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "BH",
		"desc": "BẪY + HỒN. KẺ CHẾT KHI ĐANG BỊ TRÓI ĐỂ LẠI MỘT BẪY HỒN: KẺ KẾ TIẾP DẪM PHẢI BỊ TRÓI 1 GIÂY."},
	"hl_wolf": {"n": "BẦY MA", "m": 19, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "BM",
		"desc": "DƯ ẢNH MANG HÌNH SÓI: NHANH HƠN 40% VÀ GIỮ CHÂN MỤC TIÊU 1 GIÂY Ở CÚ VỒ ĐẦU. CÁI GIÁ: DƯ ẢNH CHỈ TỒN TẠI NỬA THỜI GIAN. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Hộ Vệ + Thợ Săn = Biên Vệ (m 20)
	"bv_behind": {"n": "SAU TƯỜNG", "m": 20, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "ST",
		"desc": "TƯỜNG CHẮN + TẬP TRUNG. ĐỨNG TRONG 40 QUANH TƯỜNG CHẮN CỦA MÌNH THÌ TẬP TRUNG TÍCH NHANH GẤP ĐÔI, KHÔNG CẦN KHOẢNG CÁCH."},
	"bv_loop": {"n": "LỖ CHÂU MAI", "m": 20, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "LC",
		"desc": "PHÁT NGẮM + TƯỜNG CHẮN. PHÁT NGẮM BẮN KHI ĐỨNG CẠNH TƯỜNG CHẮN CỦA MÌNH GÂY THÊM 30%."},
	"bv_bash": {"n": "ĐẬP CON MỒI", "m": 20, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "DC",
		"desc": "ĐẬP KHIÊN + DẤU SĂN. ĐẬP KHIÊN LÊN KẺ MANG DẤU SĂN TRÓI NÓ 1,5 GIÂY."},
	"bv_lure": {"n": "DỤ VÀO BẪY", "m": 20, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DB",
		"desc": "KHIÊU KHÍCH + BẪY. KẺ ĐANG BỊ KHIÊU KHÍCH DẪM BẪY NHẬN THÊM 40%."},
	"bv_gate": {"n": "THÚ GIỮ CỬA", "m": 20, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "TC",
		"desc": "XUA THÚ + KHIÊU KHÍCH. XUA THÚ LÊN KẺ ĐANG BỊ KHIÊU KHÍCH GIỮ CHÂN NÓ GẤP ĐÔI THỜI GIAN."},
	"bv_pet": {"n": "KHIÊN CHO THÚ", "m": 20, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "KT",
		"desc": "CHIA KHIÊN + THÚ. MỖI LẦN BẠN NHẬN KHIÊN, THÚ HỒI LƯỢNG MÁU BẰNG 30% SỐ KHIÊN ĐÓ."},
	"bv_rain": {"n": "MƯA TRÊN VÒNG", "m": 20, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MV",
		"desc": "MƯA TÊN + VÒNG CHE. MƯA TÊN ĐẶT CHỒNG LÊN VÒNG CHE LÀM KẺ ĐỊCH TRONG ĐÓ CHẬM 30%."},
	"bv_post": {"n": "CHỐT GÁC", "m": 20, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "CG",
		"desc": "ĐỨNG YÊN 2 GIÂY: ĐÒN TẦM XA GÂY THÊM 30% VÀ KHIÊN KHÔNG TỰ MẤT. CÁI GIÁ: BƯỚC ĐI LÀ MẤT HIỆU ỨNG VÀ MẤT 10 KHIÊN. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= Tư Tế (m 21). Rhythm: THÀNH KÍNH 0-100, from healing and from standing on holy ground.
	# Mark: SOI (lit by holy light): the foe takes 5% more damage. Holy damage is what the seal, the purge and holy bursts deal.
	"knell": {"n": "TIẾNG MÕ", "m": 21, "b": 0, "pos": [0, 0], "kind": "a", "max": 1, "cd": 10.0, "rage": 20, "abbr": "TM",
		"desc": "GÕ MÕ: HỒI 25% MÁU CHO BẠN VÀ CHO THÚ, DƯ ẢNH TRONG 80."},
	"warm": {"n": "TAY ẤM", "m": 21, "b": 0, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "TA", "desc": "HỒI MÁU CỦA BẠN MẠNH HƠN 8% MỖI BẬC."},
	"resound": {"n": "DƯ ÂM", "m": 21, "b": 0, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "DA",
		"desc": "MÁU HỒI THỪA THÀNH KHIÊN: MỖI BẬC MỘT PHẦN BA LƯỢNG THỪA, MỖI LẦN HỒI TỐI ĐA 5% MÁU."},
	"holy": {"n": "ĐẤT THIÊNG", "m": 21, "b": 0, "pos": [0, 1], "kind": "a", "max": 1, "cd": 14.0, "rage": 20, "abbr": "DT",
		"desc": "VẼ MỘT VÒNG ĐẤT THIÊNG DƯỚI CHÂN TRONG 6 GIÂY. ĐỨNG TRONG ĐÓ, BẠN HỒI 3% MÁU MỖI GIÂY VÀ TÍCH THÀNH KÍNH."},
	"patience": {"n": "KIÊN NHẪN", "m": 21, "b": 0, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "KN", "desc": "THÀNH KÍNH TÍCH NHANH HƠN 20% MỖI BẬC."},
	"vein": {"n": "MỘT MẠCH", "m": 21, "b": 0, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "MM",
		"desc": "MỌI LẦN HỒI MÁU CỦA BẠN TRẢI RA 4 GIÂY NHƯNG MẠNH HƠN 60%. CÁI GIÁ: KHÔNG CÒN HỒI MÁU TỨC THÌ."},
	"seal": {"n": "ẤN TRỪNG", "m": 21, "b": 1, "pos": [0, 0], "kind": "a", "max": 1, "cd": 3.0, "rage": 10, "abbr": "AT",
		"desc": "PHÓNG MỘT ẤN SÁNG VÀO KẺ GẦN ĐIỂM NGẮM: 130% SÁT THƯƠNG THÁNH, ĐỂ DẤU SOI 6 GIÂY."},
	"sacred": {"n": "LỬA THIÊNG", "m": 21, "b": 1, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "LT", "desc": "SÁT THƯƠNG THÁNH +5% MỖI BẬC."},
	"lumen": {"n": "SÁNG SOI", "m": 21, "b": 1, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "SS", "desc": "KẺ BỊ SOI NHẬN THÊM 3% SÁT THƯƠNG NỮA MỖI BẬC."},
	"purge": {"n": "TRỪ TÀ", "m": 21, "b": 1, "pos": [0, 1], "kind": "a", "max": 1, "cd": 12.0, "rage": 25, "abbr": "TR",
		"desc": "100% SÁT THƯƠNG THÁNH QUANH NGƯỜI. KẺ TRÚNG MẤT DẤU TINH ANH 4 GIÂY: KHÔNG CHE CHỞ ĐƯỢC AI, CHẾT KHÔNG NỔ."},
	"rebuke": {"n": "PHÁN XÉT", "m": 21, "b": 1, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "PX",
		"desc": "ẤN TRỪNG NGẮT ĐÒN NIỆM CỦA KẺ NHẸ; BẬC 2: CẢ KẺ NẶNG."},
	"zeal": {"n": "CUỒNG TÍN", "m": 21, "b": 1, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "CT",
		"desc": "KHI THÀNH KÍNH ĐẦY, ẤN TRỪNG KHÔNG HỒI CHIÊU TRONG 5 GIÂY, RỒI THÀNH KÍNH VỀ 0. CÁI GIÁ: DƯỚI 50 THÀNH KÍNH, PHÉP HỒI CỦA BẠN KHÔNG HỒI CHO CHÍNH BẠN."},
	"bless": {"n": "CHÚC LÀNH", "m": 21, "b": 2, "pos": [0, 0], "kind": "a", "max": 1, "cd": 16.0, "rage": 20, "abbr": "CL",
		"desc": "TRONG 8 GIÂY, BẠN VÀ THÚ, DƯ ẢNH TRONG 60 GÂY THÊM 15% SÁT THƯƠNG; BẠN CHẠY NHANH HƠN 15%."},
	"radiance": {"n": "LAN TỎA", "m": 21, "b": 2, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "LO", "desc": "TẦM PHƯỚC VÀ TẦM MÕ +20 MỖI BẬC."},
	"abide": {"n": "BỀN LÂU", "m": 21, "b": 2, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "BL", "desc": "CHÚC LÀNH DÀI THÊM 1 GIÂY MỖI BẬC."},
	"vow": {"n": "LỜI NGUYỆN", "m": 21, "b": 2, "pos": [0, 1], "kind": "a", "max": 1, "cd": 40.0, "rage": 0, "abbr": "LN",
		"desc": "TRONG 3 GIÂY BẠN KHÔNG THỂ XUỐNG DƯỚI 1 MÁU."},
	"shelter": {"n": "CHỞ CHE", "m": 21, "b": 2, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "CC", "desc": "KHI ĐANG MANG PHƯỚC, BẠN NHẬN ÍT HƠN 5% SÁT THƯƠNG MỖI BẬC."},
	"devote": {"n": "HIẾN DÂNG", "m": 21, "b": 2, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "HD",
		"desc": "PHƯỚC BẠN BAN CHO THÚ VÀ DƯ ẢNH MẠNH GẤP RƯỠI. CÁI GIÁ: BẠN KHÔNG NHẬN PHƯỚC CỦA CHÍNH MÌNH."},
	"vigil": {"n": "CANH BA", "m": 21, "b": -1, "pos": [0, 0], "kind": "u", "max": 1, "cd": 90.0, "rage": 0, "abbr": "C3",
		"desc": "GỌI DẬY THÚ ĐÃ GỤC. NẾU KHÔNG CÓ AI GỤC, TRONG 6 GIÂY TỚI NẾU BẠN CHẾT THÌ SỐNG LẠI VỚI 40% MÁU."},

	# ================= link tree: Chiến Binh + Tư Tế = Kiếm Nguyện (m 22)
	"kn_block": {"n": "ĐỠ THAY", "m": 22, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "DT",
		"desc": "THỦ THẾ + HỒI MÁU. MỖI ĐÒN ĐỠ ĐƯỢC HỒI 4% MÁU CHO BẠN VÀ THÚ TRONG 80."},
	"kn_rise": {"n": "SỐNG LẠI ĐỂ CHÉM", "m": 22, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "SL",
		"desc": "LỜI NGUYỆN + TỬ THỦ. KHI LỜI NGUYỆN GIỮ BẠN Ở 1 MÁU, 4 GIÂY KẾ TIẾP BẠN GÂY THÊM 30%."},
	"kn_link": {"n": "NỐI PHƯỚC", "m": 22, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "NP",
		"desc": "HÉT TRẬN + CHÚC LÀNH. DÙNG CÁI NÀY KHI CÁI KIA CÒN HIỆU LỰC THÌ CẢ HAI DÀI THÊM 3 GIÂY, MỖI LẦN MỘT LẦN."},
	"kn_spin": {"n": "XOÁY THIÊNG", "m": 22, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "XT",
		"desc": "XOÁY + ĐẤT THIÊNG. XOÁY KHI ĐỨNG TRONG ĐẤT THIÊNG HỒI 2% MÁU CHO MỖI KẺ TRÚNG, TỐI ĐA 10%."},
	"kn_strike": {"n": "NHÁT NGUYỆN", "m": 22, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "NN",
		"desc": "CHUỖI CHÉM + THÀNH KÍNH. ĐÒN CUỐI CHUỖI CHO 8 THÀNH KÍNH."},
	"kn_lit": {"n": "CHÉM KẺ BỊ SOI", "m": 22, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "CS",
		"desc": "CHUỖI CHÉM + ẤN TRỪNG. ĐÒN CUỐI CHUỖI LÊN KẺ BỊ SOI NỔ THÁNH QUANG 80% QUANH NÓ VÀ TIÊU DẤU SOI."},
	"kn_slam": {"n": "DẬP TÀ", "m": 22, "b": 2, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "DP",
		"desc": "DẬP ĐẤT + TRỪ TÀ. KẺ TRÚNG DẬP ĐẤT KHÔNG ĐƯỢC CHE CHỞ TRONG 4 GIÂY."},
	"kn_oath": {"n": "LỜI THỀ", "m": 22, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "LT",
		"desc": "DƯỚI NỬA MÁU: PHÉP HỒI CỦA BẠN MẠNH GẤP RƯỠI VÀ BẠN GÂY THÊM 15%. CÁI GIÁ: TRÊN NỬA MÁU, PHÉP HỒI KHÔNG HỒI CHO BẠN. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Nguyên Tố Sư + Tư Tế = Nhật Quang (m 23)
	"nq_fire": {"n": "LỬA LÀNH", "m": 23, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "LL",
		"desc": "TƯỜNG LỬA + ĐẤT THIÊNG. ĐẤT THIÊNG CHẠM TƯỜNG LỬA HỒI GẤP ĐÔI."},
	"nq_lit": {"n": "SOI RỒI ĐỐT", "m": 23, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "SD",
		"desc": "DẤU + SOI + THÀNH KÍNH. ĐẶT DẤU NGUYÊN TỐ LÊN KẺ BỊ SOI CHO 4 THÀNH KÍNH."},
	"nq_seal": {"n": "ẤN THEO DẤU", "m": 23, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "AD",
		"desc": "ẤN TRỪNG + DẤU. ẤN TRỪNG GÂY THÊM 15% CHO MỖI DẤU NGUYÊN TỐ TRÊN MỤC TIÊU."},
	"nq_frost": {"n": "MÕ SƯƠNG", "m": 23, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "MS",
		"desc": "TIẾNG MÕ + BĂNG. TIẾNG MÕ GỠ CHẬM KHỎI BẠN VÀ LÀM LẠNH KẺ ĐỊCH TRONG TẦM MÕ."},
	"nq_tint": {"n": "PHƯỚC MANG HỆ", "m": 23, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "PH",
		"desc": "CHÚC LÀNH + DẤU. KHI CÒN PHƯỚC, CÚ CẮN CỦA THÚ VÀ ĐÒN CỦA DƯ ẢNH ĐỂ LẠI DẤU CỦA PHÉP CUỐI BẠN DÙNG. 3 GIÂY MỘT LẦN MỖI KẺ."},
	"nq_purge": {"n": "SÉT TRỪ TÀ", "m": 23, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "ST",
		"desc": "TRỪ TÀ + SÉT CHUYỀN. TRỪ TÀ TRÚNG MỘT TINH ANH THÌ PHÓNG SÉT CHUYỀN TỪ NÓ."},
	"nq_cage": {"n": "LỒNG SÁNG", "m": 23, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "LS",
		"desc": "LỒNG SÉT + SOI. KẺ Ở TRONG LỒNG SÉT BỊ SOI."},
	"nq_noon": {"n": "CHÍNH NGỌ", "m": 23, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "CN",
		"desc": "KHI THÀNH KÍNH ĐẦY, PHÉP NGUYÊN TỐ KẾ TIẾP GÂY GẤP ĐÔI, RỒI THÀNH KÍNH VỀ 0. CÁI GIÁ: HỒI MÁU KHÔNG CÒN TÍCH THÀNH KÍNH. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Sát Thủ + Tư Tế = Phán Quan (m 24)
	"pq_lit": {"n": "SOI CHỖ HIỂM", "m": 24, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "SH",
		"desc": "ẤN TRỪNG + ĐIỂM HIỂM. KẺ BỊ SOI LUÔN BỊ COI LÀ HỞ LƯNG."},
	"pq_smoke": {"n": "ẨN TRONG ĐẤT THIÊNG", "m": 24, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "AT",
		"desc": "MÀN KHÓI + ĐẤT THIÊNG. KHI ĐANG TRONG KHÓI VÀ ĐỨNG TRONG ĐẤT THIÊNG, BẠN HỒI MÁU GẤP ĐÔI."},
	"pq_grace": {"n": "GIỜ ÂN XÁ", "m": 24, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "GA",
		"desc": "LỜI NGUYỆN + KẾT LIỄU. KHI LỜI NGUYỆN ĐANG CHE BẠN, ĐÒN KẾT LIỄU KHÔNG TIÊU ĐIỂM HIỂM."},
	"pq_holy": {"n": "ĐỘC THIÊNG", "m": 24, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "DT",
		"desc": "CHÚC LÀNH + ĐỘC. KHI CÒN PHƯỚC, KẺ TRÚNG ĐỘC CỦA BẠN BỊ SOI."},
	"pq_slash": {"n": "RẠCH LẤY MÁU", "m": 24, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "RM",
		"desc": "RẠCH + HỒI MÁU. RẠCH HỒI 1% MÁU CHO MỖI ĐIỂM HIỂM ĐÃ TIÊU."},
	"pq_exec": {"n": "THI HÀNH", "m": 24, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TH",
		"desc": "KẾT LIỄU + THÀNH KÍNH. ĐÒN KẾT LIỄU CHO 4 THÀNH KÍNH MỖI ĐIỂM HIỂM ĐÃ TIÊU."},
	"pq_purge": {"n": "KHÔNG AI CHE", "m": 24, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "KC",
		"desc": "HÀNH QUYẾT + TRỪ TÀ. HÀNH QUYẾT BỎ QUA SỰ CHE CHỞ CỦA TINH ANH."},
	"pq_doom": {"n": "ÁN TỬ", "m": 24, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "AN",
		"desc": "ẤN TRỪNG ĐẶT ÁN 8 GIÂY LÊN MỤC TIÊU; KẺ MANG ÁN CHẾT THÌ BẠN HỒI 6% MÁU VÀ NHẬN 2 ĐIỂM HIỂM. CÁI GIÁ: CHỈ MỘT ÁN, ẤN TRỪNG HỒI 6 GIÂY. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Thuật Sĩ Linh Hồn + Tư Tế = Chiêu Hồn (m 25)
	"ch_tend": {"n": "CHĂM NGƯỜI CHẾT", "m": 25, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "CN",
		"desc": "DƯ ẢNH + THÀNH KÍNH. DƯ ẢNH TAN VÌ HẾT GIỜ CHO 10 THÀNH KÍNH."},
	"ch_keep": {"n": "MÕ GIỮ BÓNG", "m": 25, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MG",
		"desc": "TIẾNG MÕ + DƯ ẢNH. TIẾNG MÕ KÉO DÀI DƯ ẢNH TRONG TẦM THÊM 5 GIÂY. MỖI DƯ ẢNH MỘT LẦN."},
	"ch_bless": {"n": "PHƯỚC CHO BÓNG", "m": 25, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "PB",
		"desc": "CHÚC LÀNH + DƯ ẢNH. CHÚC LÀNH MẠNH GẤP ĐÔI TRÊN DƯ ẢNH."},
	"ch_lit": {"n": "SOI VÀ NGUYỀN", "m": 25, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "SN",
		"desc": "ẤN TRỪNG + NGUYỀN. KẺ VỪA BỊ SOI VỪA BỊ NGUYỀN NHẬN THÊM 10%."},
	"ch_vow": {"n": "TẾ MÀ KHÔNG MẤT", "m": 25, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TK",
		"desc": "LỜI NGUYỆN + HIẾN TẾ. KHI LỜI NGUYỆN ĐANG BẬT, DƯ ẢNH BỊ HIẾN TẾ NỔ MÀ KHÔNG TAN."},
	"ch_ground": {"n": "CHẾT TRÊN ĐẤT THIÊNG", "m": 25, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "CD",
		"desc": "ĐẤT THIÊNG + HỒN. KẺ CHẾT TRONG ĐẤT THIÊNG CHO 2 HỒN."},
	"ch_scythe": {"n": "HÁI TRÊN ĐẤT THIÊNG", "m": 25, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "HT",
		"desc": "LƯỠI HÁI + HỒI MÁU. LƯỠI HÁI KHI ĐỨNG TRONG ĐẤT THIÊNG HỒI MÁU GẤP ĐÔI."},
	"ch_send": {"n": "ĐƯA TIỄN", "m": 25, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "DT",
		"desc": "TRỪ TÀ GIẢI THOÁT MỌI DƯ ẢNH: MỖI CÁI HỒI CHO BẠN 10% MÁU VÀ NỔ THÁNH 150%. CÁI GIÁ: KHÔNG DÙNG ĐƯỢC HIẾN TẾ. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Hộ Vệ + Tư Tế = Thánh Vệ (m 26)
	"sv_pray": {"n": "CHỊU ĐÒN LÀ CẦU NGUYỆN", "m": 26, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "CN",
		"desc": "KHIÊN + THÀNH KÍNH. CỨ 10 SÁT THƯƠNG KHIÊN ĐỠ ĐƯỢC CHO 3 THÀNH KÍNH."},
	"sv_over": {"n": "MÁU THỪA THÀNH KHIÊN", "m": 26, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MK",
		"desc": "DƯ ÂM + KHIÊN. MỌI LƯỢNG MÁU HỒI THỪA THÀNH KHIÊN, TỚI TRẦN KHIÊN."},
	"sv_lit": {"n": "ÁN SOI", "m": 26, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "AS",
		"desc": "PHÁN QUYẾT + SOI. PHÁN QUYẾT ĐỂ DẤU SOI LÊN MỌI KẺ TRÚNG."},
	"sv_bash": {"n": "ĐẬP TAN CHE CHỞ", "m": 26, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DC",
		"desc": "ĐẬP KHIÊN + TRỪ TÀ. KẺ TRÚNG ĐẬP KHIÊN MẤT DẤU TINH ANH 4 GIÂY."},
	"sv_knell": {"n": "MÕ GỌI", "m": 26, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "MG",
		"desc": "TIẾNG MÕ + KHIÊU KHÍCH. KẺ ĐỊCH TRONG TẦM MÕ BỊ KHIÊU KHÍCH 2 GIÂY."},
	"sv_ring": {"n": "MỘT VÒNG", "m": 26, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MV",
		"desc": "VÒNG CHE + ĐẤT THIÊNG. ĐẶT CHỒNG NHAU THÌ CẢ HAI TỒN TẠI THÊM 3 GIÂY."},
	"sv_vow": {"n": "NGUYỆN CÓ KHIÊN", "m": 26, "b": 2, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "NK",
		"desc": "LỜI NGUYỆN + KHIÊN. LỜI NGUYỆN CHO NGAY 40 KHIÊN."},
	"sv_martyr": {"n": "TỬ VÌ ĐẠO", "m": 26, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "TV",
		"desc": "BẠN NHẬN ÍT HƠN 15% SÁT THƯƠNG VÀ KHIÊN ĐỠ ĐÒN CHO THÀNH KÍNH GẤP ĐÔI. CÁI GIÁ: BẠN GÂY ÍT HƠN 20% SÁT THƯƠNG. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Thợ Săn + Tư Tế = Tuần Lâm (m 27)
	"tl_calm": {"n": "VỮNG TÂM", "m": 27, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "VT",
		"desc": "CHÚC LÀNH + TẬP TRUNG. KHI CÒN PHƯỚC, TẬP TRUNG KHÔNG BỊ MẤT KHI BẠN TRÚNG ĐÒN VÀ VẪN TÍCH KHI KẺ ĐỊCH Ở GẦN."},
	"tl_arrow": {"n": "TÊN LÀNH", "m": 27, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TL",
		"desc": "PHÁT NGẮM + HỒI MÁU. MỖI KẺ PHÁT NGẮM XUYÊN QUA HỒI CHO BẠN 3% MÁU."},
	"tl_trap": {"n": "BẪY TRÊN ĐẤT THIÊNG", "m": 27, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "BT",
		"desc": "ĐẤT THIÊNG + BẪY. BẪY ĐẶT TRONG ĐẤT THIÊNG TỰ DỰNG LẠI MỘT LẦN SAU KHI SẬP."},
	"tl_vow": {"n": "NGUYỆN CHO THÚ", "m": 27, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "NT",
		"desc": "LỜI NGUYỆN + THÚ. KHI LỜI NGUYỆN ĐANG BẬT, THÚ CŨNG KHÔNG THỂ GỤC."},
	"tl_pray": {"n": "THÚ CẦU NGUYỆN", "m": 27, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TC",
		"desc": "THÚ + THÀNH KÍNH. MỖI CÚ CẮN TRÚNG CỦA THÚ CHO 2 THÀNH KÍNH."},
	"tl_knell": {"n": "MÕ GỌI THÚ", "m": 27, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MT",
		"desc": "TIẾNG MÕ + THÚ. TIẾNG MÕ DỰNG THÚ ĐÃ GỤC DẬY NGAY VỚI 50% MÁU."},
	"tl_lit": {"n": "DẤU SOI", "m": 27, "b": 2, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "DS",
		"desc": "DẤU SĂN + SOI. KẺ MANG DẤU SĂN CŨNG BỊ SOI."},
	"tl_beast": {"n": "THẦN THÚ", "m": 27, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "TT",
		"desc": "THÚ TO GẤP RƯỠI, THÊM 50% MÁU; CÚ CẮN LÀ SÁT THƯƠNG THÁNH VÀ ĐỂ DẤU SOI. CÁI GIÁ: XUA THÚ HỒI CHẬM THÊM 5 GIÂY. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= Kỹ Sư Cổ Vật (m 28). Rhythm: NHIỆT 0-100. Artificer skills cost no rage: they add heat ("heat").
	# Above 70 heat devices are 20% stronger. At 100 the kit overheats for 4 seconds and its skills cannot be used. At most 3 devices.
	"turret": {"n": "TRỤ NỎ", "m": 28, "b": 0, "pos": [0, 0], "kind": "a", "max": 1, "cd": 8.0, "rage": 0, "heat": 25, "abbr": "TN",
		"desc": "DỰNG MỘT TRỤ NỎ TRƯỚC MẶT TRONG 12 GIÂY. NÓ BẮN KẺ GẦN NHẤT MỖI NỬA GIÂY, 30% TẤN CÔNG. +25 NHIỆT."},
	"skilled": {"n": "THỢ GIỎI", "m": 28, "b": 0, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "TG", "desc": "SÁT THƯƠNG THIẾT BỊ +10% MỖI BẬC."},
	"durable": {"n": "BỀN MÁY", "m": 28, "b": 0, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "BM", "desc": "THIẾT BỊ TỒN TẠI THÊM 3 GIÂY MỖI BẬC."},
	"bellmine": {"n": "MÌN CHUÔNG", "m": 28, "b": 0, "pos": [0, 1], "kind": "a", "max": 1, "cd": 5.0, "rage": 0, "heat": 15, "abbr": "MC",
		"desc": "ĐẶT MỘT MÌN CHUÔNG. KẺ TỚI GẦN LÀM NÓ NỔ 180% TẤN CÔNG VÀ CHOÁNG 0,5 GIÂY. +15 NHIỆT."},
	"salvage": {"n": "THÁO LẮP", "m": 28, "b": 0, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "TL", "desc": "THIẾT BỊ HẾT GIỜ HAY BỊ THAY TRẢ LẠI 25% HỒI CHIÊU MỖI BẬC."},
	"workshop": {"n": "XƯỞNG DI ĐỘNG", "m": 28, "b": 0, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "XD",
		"desc": "TRỤ NỎ BAY THEO BẠN. CÁI GIÁ: TỐI ĐA 2 THIẾT BỊ."},
	"vent": {"n": "XẢ HƠI", "m": 28, "b": 1, "pos": [0, 0], "kind": "a", "max": 1, "cd": 6.0, "rage": 0, "abbr": "XH",
		"desc": "XẢ HẾT NHIỆT THÀNH MỘT LUỒNG HƠI HÌNH NÓN: 3% TẤN CÔNG CHO MỖI ĐIỂM NHIỆT, ĐẨY LÙI."},
	"valve": {"n": "VAN AN TOÀN", "m": 28, "b": 1, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "VA", "desc": "QUÁ NHIỆT NGẮN HƠN 0,5 GIÂY MỖI BẬC."},
	"core": {"n": "LÕI NÓNG", "m": 28, "b": 1, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "LN", "desc": "TRÊN 70 NHIỆT, BẠN GÂY THÊM 4% SÁT THƯƠNG MỖI BẬC."},
	"boost": {"n": "TĂNG ÁP", "m": 28, "b": 1, "pos": [0, 1], "kind": "a", "max": 1, "cd": 12.0, "rage": 0, "heat": 40, "abbr": "TA",
		"desc": "+40 NHIỆT NGAY. TRONG 5 GIÂY BẠN CHÉM NHANH HƠN 25%."},
	"radiator": {"n": "TẢN NHIỆT", "m": 28, "b": 1, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "TN", "desc": "NHIỆT GIẢM NHANH HƠN 20% MỖI BẬC KHI KHÔNG GIAO CHIẾN."},
	"overdrive": {"n": "CHẠY QUÁ TẢI", "m": 28, "b": 1, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "QT",
		"desc": "KHÔNG BAO GIỜ QUÁ NHIỆT, NHIỆT LÊN ĐƯỢC TỚI 150. CÁI GIÁ: TRÊN 100 NHIỆT MẤT 3% MÁU MỖI GIÂY CHO TỚI KHI XẢ."},
	"hook": {"n": "MÓC KÉO", "m": 28, "b": 2, "pos": [0, 0], "kind": "a", "max": 1, "cd": 7.0, "rage": 0, "heat": 10, "abbr": "MK",
		"desc": "PHÓNG MÓC TỚI ĐIỂM NGẮM: KÉO MỘT KẺ NHẸ VỀ PHÍA BẠN, HOẶC KÉO BẠN TỚI KẺ NẶNG HAY TỚI CHỖ ĐÓ. +10 NHIỆT."},
	"lens": {"n": "KÍNH SOI", "m": 28, "b": 2, "pos": [1, 0], "kind": "p", "max": 3, "abbr": "KS", "desc": "+5% SÁT THƯƠNG LÊN KẺ ĐANG LẤY ĐÀ MỖI BẬC."},
	"battery": {"n": "PIN VỌNG", "m": 28, "b": 2, "pos": [2, 0], "kind": "p", "max": 3, "abbr": "PV", "desc": "KỸ NĂNG TỐN ÍT NỘ HƠN 5% MỖI BẬC."},
	"mute": {"n": "CHUÔNG CÂM", "m": 28, "b": 2, "pos": [0, 1], "kind": "a", "max": 1, "cd": 16.0, "rage": 0, "heat": 30, "abbr": "CC",
		"desc": "ĐẶT MỘT VÙNG IM LẶNG 4 GIÂY TẠI ĐIỂM NGẮM: QUÁI BÊN TRONG KHÔNG LẤY ĐÀ ĐƯỢC, ĐẠN BAY CHẬM MỘT NỬA. +30 NHIỆT."},
	"toolkit": {"n": "TÚI ĐỒ NGHỀ", "m": 28, "b": 2, "pos": [1, 1], "kind": "p", "max": 2, "abbr": "TD", "desc": "BÌNH MÁU HỒI NHANH HƠN 15% MỖI BẬC."},
	"prototype": {"n": "NGUYÊN MẪU", "m": 28, "b": 2, "pos": [1, 2], "kind": "k", "max": 1, "abbr": "NM",
		"desc": "THÊM Ô KỸ NĂNG THỨ SÁU (PHÍM 6), CHỈ NHẬN KỸ NĂNG CỦA KỸ SƯ. CÁI GIÁ: TUYỆT KỸ HỒI CHẬM GẤP ĐÔI."},
	"bellwork": {"n": "CỖ MÁY CHUÔNG", "m": 28, "b": -1, "pos": [0, 0], "kind": "u", "max": 1, "cd": 70.0, "rage": 0, "abbr": "MC",
		"desc": "GỌI MỘT CỖ MÁY CHUÔNG 10 GIÂY. MỖI GIÂY NÓ PHÁT SÓNG ÂM 100% TẤN CÔNG QUANH MÌNH VÀ KÉO QUÁI LẠI GẦN."},

	# ================= link tree: Chiến Binh + Kỹ Sư = Thiết Thủ (m 29)
	"tk_mine": {"n": "MÌN PHẢN", "m": 29, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "MP",
		"desc": "THỦ THẾ + MÌN CHUÔNG. ĐỠ ĐƯỢC ĐÒN THẢ MỘT MÌN CHUÔNG DƯỚI CHÂN KẺ ĐÁNH, KHÔNG CỘNG NHIỆT. 5 GIÂY MỘT LẦN."},
	"tk_stun": {"n": "BẮN KẺ CHOÁNG", "m": 29, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "BC",
		"desc": "TRỤ NỎ + CHOÁNG. TRỤ ƯU TIÊN KẺ ĐANG CHOÁNG VÀ GÂY THÊM 50% LÊN CHÚNG."},
	"tk_spin": {"n": "XOÁY HƠI", "m": 29, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "XH",
		"desc": "TĂNG ÁP + XOÁY. KHI TĂNG ÁP CÒN HIỆU LỰC, XOÁY KHÔNG TỐN NỘ MÀ CỘNG 20 NHIỆT."},
	"tk_toll": {"n": "CHUÔNG TRONG LẶNG", "m": 29, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "CL",
		"desc": "HỒI CHUÔNG + CHUÔNG CÂM. HỒI CHUÔNG ĐÁNH KHI BẠN ĐỨNG TRONG VÙNG CHUÔNG CÂM LÀM CHOÁNG DÀI GẤP ĐÔI."},
	"tk_chop": {"n": "CHÉM XẢ", "m": 29, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "CX",
		"desc": "CHUỖI CHÉM + NHIỆT. MỖI NHÁT CHÉM TRÚNG XẢ 3 NHIỆT, ĐÒN CUỐI CHUỖI XẢ 8."},
	"tk_vent": {"n": "HƠI BÚA", "m": 29, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "HB",
		"desc": "CHUỖI CHÉM + XẢ HƠI. XẢ HƠI HƯỞNG TAY NẶNG NHƯ ĐÒN CUỐI CHUỖI VÀ PHÁ THẾ GẤP ĐÔI."},
	"tk_pull": {"n": "KÉO RỒI DẬP", "m": 29, "b": 2, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "KD",
		"desc": "MÓC KÉO + DẬP ĐẤT. TRONG 2 GIÂY SAU MÓC KÉO, DẬP ĐẤT KHÔNG TỐN NỘ."},
	"tk_armor": {"n": "GIÁP HƠI", "m": 29, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "GH",
		"desc": "TRÊN 70 NHIỆT: ĐÒN TRÚNG KHÔNG NGẮT ĐÒN ĐÁNH CỦA BẠN VÀ BẠN CHÉM NHANH HƠN 20%. CÁI GIÁ: QUÁ NHIỆT DÀI THÊM 2 GIÂY. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Nguyên Tố Sư + Kỹ Sư = Lôi Công (m 30)
	"lc_heat": {"n": "BA HỆ BA HƯỚNG", "m": 30, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "BH",
		"desc": "PHÉP + NHIỆT. PHÉP LỬA CỘNG 10 NHIỆT, PHÉP SÉT XẢ 10, PHÉP BĂNG XẢ 20."},
	"lc_vent": {"n": "HƠI THEO HỆ", "m": 30, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "HH",
		"desc": "XẢ HƠI + DẤU. XẢ HƠI NGAY SAU PHÉP LỬA GÂY CHÁY; SAU PHÉP BĂNG GÂY LẠNH VÀ KHÔNG ĐẨY LÙI; SAU PHÉP SÉT GÂY GIẬT."},
	"lc_tint": {"n": "TRỤ MANG HỆ", "m": 30, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "TM",
		"desc": "TRỤ NỎ + DẤU. TRỤ BẮN ĐẠN MANG HỆ CỦA PHÉP CUỐI BẠN DÙNG LÚC ĐẶT, ĐỂ LẠI DẤU ĐÓ. 2 GIÂY MỘT LẦN MỖI KẺ."},
	"lc_frost": {"n": "LẶNG GIÁ", "m": 30, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "LG",
		"desc": "CHUÔNG CÂM + BĂNG. LẠNH TRÊN KẺ ĐỨNG TRONG VÙNG CHUÔNG CÂM KHÔNG HẾT HẠN."},
	"lc_reso": {"n": "ÁP CỘNG HƯỞNG", "m": 30, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "AC",
		"desc": "TĂNG ÁP + CỘNG HƯỞNG. KHI TĂNG ÁP CÒN HIỆU LỰC, CỘNG HƯỞNG CHO THÊM 40% THAY VÌ 20%."},
	"lc_cage": {"n": "MÌN TRONG LỒNG", "m": 30, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "ML",
		"desc": "MÌN CHUÔNG + LỒNG SÉT. MÌN NỔ TRONG LỒNG SÉT NỔ HAI LẦN."},
	"lc_charge": {"n": "SÉT NẠP MÁY", "m": 30, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "SN",
		"desc": "SÉT CHUYỀN + THIẾT BỊ. DÙNG SÉT CHUYỀN LÀM TRỤ CỦA BẠN TRONG 150 BẮN NHANH HƠN 30% TRONG 3 GIÂY."},
	"lc_reactor": {"n": "LÒ PHẢN ỨNG", "m": 30, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "LP",
		"desc": "TRÊN 70 NHIỆT, PHÉP KHÔNG TỐN NỘ. CÁI GIÁ: MỖI PHÉP CỘNG THÊM 15 NHIỆT. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Sát Thủ + Kỹ Sư = Thợ Bóng (m 31)
	"tb_hook": {"n": "MÓC RA SAU", "m": 31, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "MS",
		"desc": "MÓC KÉO + ĐIỂM HIỂM. MÓC KÉO TỚI MỘT KẺ NẶNG ĐẶT BẠN SAU LƯNG NÓ VÀ CHO +1 ĐIỂM HIỂM."},
	"tb_smoke": {"n": "MÌN KHÓI", "m": 31, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MK",
		"desc": "MÌN CHUÔNG + MÀN KHÓI. MÌN NỔ TRONG 60 QUANH BẠN CHO BẠN 1,5 GIÂY TRONG KHÓI."},
	"tb_quiet": {"n": "LẶNG VÀ TỐI", "m": 31, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "LT",
		"desc": "CHUÔNG CÂM + MÀN KHÓI. ĐỨNG TRONG VÙNG CHUÔNG CÂM, BẠN NHƯ ĐANG Ở TRONG KHÓI: QUÁI THƯỜNG MẤT DẤU BẠN."},
	"tb_venom": {"n": "TÊN TẨM", "m": 31, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TT",
		"desc": "TRỤ NỎ + TẨM ĐỘC. KHI TẨM ĐỘC CÒN HIỆU LỰC, TRỤ GÂY 1 CỘNG DỒN ĐỘC MỖI GIÂY LÊN MỤC TIÊU."},
	"tb_slash": {"n": "RẠCH MÁY", "m": 31, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "RM",
		"desc": "TĂNG ÁP + RẠCH. KHI TĂNG ÁP CÒN HIỆU LỰC, RẠCH KHÔNG HỒI CHIÊU NHƯNG MỖI LẦN CỘNG 10 NHIỆT."},
	"tb_fin": {"n": "KẾT LIỄU XẢ HƠI", "m": 31, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "KX",
		"desc": "KẾT LIỄU + NHIỆT. ĐÒN KẾT LIỄU XẢ 6 NHIỆT CHO MỖI ĐIỂM HIỂM ĐÃ TIÊU."},
	"tb_vent": {"n": "XẢ LẤY ĐIỂM", "m": 31, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "XD",
		"desc": "XẢ HƠI + ĐIỂM HIỂM. XẢ HƠI KHI TRÊN 70 NHIỆT CHO +2 ĐIỂM HIỂM."},
	"tb_sabo": {"n": "PHÁ HOẠI", "m": 31, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "PH",
		"desc": "PHÁT BẮN ĐẦU CỦA MỖI TRỤ VÀ MỖI MÌN ĐỀU CHÍ MẠNG. CÁI GIÁ: THIẾT BỊ TỒN TẠI NGẮN HƠN 30%. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Thuật Sĩ Linh Hồn + Kỹ Sư = Khôi Lỗi Sư (m 32)
	"kl_heat": {"n": "NHIỆT THAY HỒN", "m": 32, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "NH",
		"desc": "GỌI DƯ ẢNH + NHIỆT. DƯỚI 70 NHIỆT VÀ KHÔNG CÓ HỒN, GỌI DƯ ẢNH CỘNG 30 NHIỆT THAY VÌ TỐN HỒN."},
	"kl_post": {"n": "HỒN NHẬP TRỤ", "m": 32, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "HT",
		"desc": "TRỤ NỎ + DƯ ẢNH. ĐẶT TRỤ KHI CÓ DƯ ẢNH GẦN: DƯ ẢNH TAN VÀO TRỤ, TRỤ BAY THEO BẠN TỚI KHI HẾT GIỜ."},
	"kl_sac": {"n": "TẾ BÊN MÌN", "m": 32, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "TB",
		"desc": "HIẾN TẾ + MÌN CHUÔNG. HIẾN TẾ CẠNH MÌN LÀM MÌN NỔ THEO, MẠNH THÊM 50%."},
	"kl_chain": {"n": "KÉO CẢ XIỀNG", "m": 32, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "KX",
		"desc": "MÓC KÉO + XIỀNG HỒN. MÓC KÉO MỘT KẺ NHẸ BỊ XIỀNG KÉO THEO CẢ CÁC KẺ NHẸ BỊ NỐI."},
	"kl_curse": {"n": "LẶNG VÀ NGUYỀN", "m": 32, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "LN",
		"desc": "CHUÔNG CÂM + NGUYỀN. KẺ Ở TRONG VÙNG CHUÔNG CÂM BỊ NGUYỀN."},
	"kl_reap": {"n": "HƠI GẶT", "m": 32, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "HG",
		"desc": "XẢ HƠI + HỒN. KẺ CHẾT VÌ XẢ HƠI CHO THÊM 1 HỒN."},
	"kl_scrap": {"n": "MÁY VỠ NHẢ HỒN", "m": 32, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MV",
		"desc": "THIẾT BỊ + HỒN. THIẾT BỊ HẾT GIỜ ĐỂ LẠI 1 HỒN. 4 GIÂY MỘT LẦN."},
	"kl_puppet": {"n": "RỐI SẮT", "m": 32, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "RS",
		"desc": "DƯ ẢNH KHÔNG HẾT GIỜ. CÁI GIÁ: DƯ ẢNH VÀ THIẾT BỊ DÙNG CHUNG GIỚI HẠN 3. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Hộ Vệ + Kỹ Sư = Pháo Lũy (m 33)
	"pl_cool": {"n": "KHIÊN TẢN NHIỆT", "m": 33, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "KT",
		"desc": "KHIÊN + NHIỆT. MỖI ĐÒN KHIÊN ĐỠ ĐƯỢC XẢ 5 NHIỆT. NỬA GIÂY MỘT LẦN."},
	"pl_wall": {"n": "TRỤ SAU TƯỜNG", "m": 33, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TS",
		"desc": "TƯỜNG CHẮN + TRỤ NỎ. TRỤ ĐẶT SÁT TƯỜNG CHẮN CỦA MÌNH TỒN TẠI THÊM 3 GIÂY VÀ BẮN XA HƠN."},
	"pl_shield": {"n": "HƠI THÀNH KHIÊN", "m": 33, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "HK",
		"desc": "XẢ HƠI + KHIÊN. XẢ HƠI CHO KHIÊN BẰNG NỬA SỐ NHIỆT ĐÃ XẢ."},
	"pl_lure": {"n": "DỤ QUA MÌN", "m": 33, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "DM",
		"desc": "KHIÊU KHÍCH + MÌN CHUÔNG. KẺ ĐANG BỊ KHIÊU KHÍCH DẪM MÌN NHẬN THÊM 50%."},
	"pl_bash": {"n": "KÉO TỚI ĐẬP", "m": 33, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "KD",
		"desc": "MÓC KÉO + ĐẬP KHIÊN. ĐẬP KHIÊN TRONG 1,5 GIÂY SAU MÓC KÉO LÀM CHOÁNG DÀI GẤP ĐÔI."},
	"pl_ring": {"n": "VÒNG LẶNG", "m": 33, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "VL",
		"desc": "VÒNG CHE + CHUÔNG CÂM. ĐẠN CỦA ĐỊCH BAY VÀO VÒNG CHE KHI VÒNG ĐANG CHẠM VÙNG CHUÔNG CÂM THÌ BIẾN MẤT."},
	"pl_share": {"n": "KHIÊN CHO MÁY", "m": 33, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "KM",
		"desc": "CHIA KHIÊN + THIẾT BỊ. MỖI LẦN BẠN NHẬN KHIÊN, MỌI THIẾT BỊ ĐANG ĐỨNG SỐNG THÊM 1 GIÂY."},
	"pl_bunker": {"n": "LÔ CỐT", "m": 33, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "LC",
		"desc": "TƯỜNG CHẮN CÓ SẴN MỘT TRỤ NỎ GẮN TRÊN, KHÔNG TÍNH VÀO GIỚI HẠN. CÁI GIÁ: TƯỜNG CHẮN HỒI CHẬM THÊM 8 GIÂY VÀ CỘNG 30 NHIỆT. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Thợ Săn + Kỹ Sư = Cơ Lạp (m 34)
	"cl_aim": {"n": "NGẮM NÓNG", "m": 34, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "NN",
		"desc": "PHÁT NGẮM + NHIỆT. TRÊN 70 NHIỆT, PHÁT NGẮM NGẮM NHANH GẤP ĐÔI."},
	"cl_quiet": {"n": "LẶNG ĐỂ NGẮM", "m": 34, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "LN",
		"desc": "CHUÔNG CÂM + TẬP TRUNG. ĐỨNG TRONG VÙNG CHUÔNG CÂM THÌ TẬP TRUNG LUÔN ĐẦY."},
	"cl_trap": {"n": "BẪY TẢN NHIỆT", "m": 34, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "BT",
		"desc": "BẪY + NHIỆT. MỖI BẪY HAY MÌN SẬP XẢ 10 NHIỆT."},
	"cl_mine": {"n": "MÌN LÀ BẪY", "m": 34, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "ML",
		"desc": "MÌN CHUÔNG + BẪY. MÌN CHUÔNG CŨNG TRÓI KẺ TRÚNG 1 GIÂY VÀ HƯỞNG CÁC NÚT VỀ BẪY (SẬP LÀ HỞ, DỤ VÀO BẪY)."},
	"cl_hook": {"n": "KÉO QUA BẪY", "m": 34, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "KB",
		"desc": "MÓC KÉO + BẪY. KẺ NHẸ BỊ MÓC KÉO LÔI ĐI LÀM SẬP MỌI BẪY TRÊN ĐƯỜNG."},
	"cl_mark": {"n": "TRỤ THEO DẤU", "m": 34, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TD",
		"desc": "TRỤ NỎ + DẤU SĂN. TRỤ LUÔN BẮN KẺ MANG DẤU SĂN VÀ GÂY THÊM 25% LÊN NÓ."},
	"cl_pet": {"n": "THÚ MANG NỎ", "m": 34, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TN",
		"desc": "THÚ + TĂNG ÁP. KHI TĂNG ÁP CÒN HIỆU LỰC, THÚ BẮN MỘT MŨI NỎ NHỎ 20% TẤN CÔNG MỖI GIÂY."},
	"cl_field": {"n": "BÃI MÌN", "m": 34, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "BM",
		"desc": "ĐẶT ĐƯỢC THÊM 3 BẪY. CÁI GIÁ: BẪY VÀ MÌN NỔ GẦN BẠN CŨNG LÀM BẠN MẤT MÁU. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= link tree: Tư Tế + Kỹ Sư = Thợ Chuông (m 35)
	"tc_cool": {"n": "HỒI MÁU TẢN NHIỆT", "m": 35, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "HT",
		"desc": "HỒI MÁU + NHIỆT + THÀNH KÍNH. MỖI 1% MÁU PHÉP HỒI CỦA BẠN HỒI ĐƯỢC XẢ 1 NHIỆT; QUÁ NHIỆT CHO 30 THÀNH KÍNH."},
	"tc_knell": {"n": "MÕ VỌNG", "m": 35, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MV",
		"desc": "TIẾNG MÕ + TRỤ NỎ. TIẾNG MÕ VỌNG LẠI TỪ MỖI TRỤ: MỖI TRỤ HỒI THÊM CHO BẠN 5% MÁU."},
	"tc_holy": {"n": "MÁY TRÊN ĐẤT THIÊNG", "m": 35, "b": 0, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "MD",
		"desc": "ĐẤT THIÊNG + THIẾT BỊ. THIẾT BỊ ĐỨNG TRONG ĐẤT THIÊNG KHÔNG HẾT GIỜ CHỪNG NÀO VÒNG CÒN."},
	"tc_lit": {"n": "MÌN SOI", "m": 35, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "MS",
		"desc": "MÌN CHUÔNG + SOI. MÌN NỔ ĐỂ DẤU SOI LÊN MỌI KẺ TRÚNG."},
	"tc_purge": {"n": "LẶNG MÀ SẠCH", "m": 35, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "LS",
		"desc": "CHUÔNG CÂM + TRỪ TÀ. CHUÔNG CÂM KHI ĐẶT LÀM KẺ TRONG VÙNG MẤT DẤU TINH ANH 4 GIÂY."},
	"tc_bless": {"n": "PHƯỚC CHO MÁY", "m": 35, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "PM",
		"desc": "CHÚC LÀNH + THIẾT BỊ. KHI CÒN PHƯỚC, THIẾT BỊ GÂY THÊM 15%."},
	"tc_hook": {"n": "KÉO NGƯỜI VỀ", "m": 35, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "KN",
		"desc": "MÓC KÉO + ĐỒNG MINH. MÓC KÉO NHẮM VÀO THÚ THÌ KÉO NÓ VỀ CHỖ BẠN VÀ HỒI CHO NÓ 10% MÁU."},
	"tc_drum": {"n": "MÕ MÁY", "m": 35, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "MM",
		"desc": "TRỤ NỎ THÀNH TRỤ MÕ: KHÔNG BẮN, MÀ HỒI CHO BẠN 2% MÁU MỖI GIÂY KHI Ở TRONG 70 VÀ TÍCH THÀNH KÍNH. CÁI GIÁ: KHÔNG CÒN TRỤ NỎ. CẦN 6 ĐIỂM Ở MỖI DÒNG NGHỀ."},

	# ================= Độc Tấu (solo trees, m 36-43): for a hero who puts no point in the second mastery.
	# Same opening rule as a link tree (3 points, keystone 6), counted in the main mastery alone.
	"ocb_parry": {"n": "ĐỠ LIÊN HOÀN", "m": 36, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "DL",
		"desc": "THỦ THẾ ĐỠ ĐƯỢC MỘT ĐÒN THÌ KÉO DÀI THÊM 0,6 GIÂY, MỖI LẦN DÙNG MỘT LẦN."},
	"ocb_iron": {"n": "THÂN THÉP", "m": 36, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TT",
		"desc": "MỖI ĐÒN ĐỠ ĐƯỢC CHO +2 GIÁP TRONG 8 GIÂY, CỘNG DỒN TỚI +10."},
	"ocb_surge": {"n": "NỘ TRÀO", "m": 36, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "NT",
		"desc": "KHI NỘ ĐẦY, NHÁT CHÉM KẾ TIẾP GÂY GẤP ĐÔI VÀ TIÊU 30 NỘ."},
	"ocb_blood": {"n": "MÁU CHIẾN", "m": 36, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MC",
		"desc": "DƯỚI NỬA MÁU, NỘ NHẬN ĐƯỢC TỪ NHÁT CHÉM GẤP ĐÔI."},
	"ocb_cry": {"n": "TIẾNG THÉT DÀI", "m": 36, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "TD",
		"desc": "HÉT TRẬN KÉO DÀI THÊM 3 GIÂY."},
	"ocb_long": {"n": "CHUỖI DÀI", "m": 36, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "CD",
		"desc": "ĐÒN CUỐI CHUỖI LẦN THỨ BA LIÊN TIẾP MÀ KHÔNG BỊ ĐÁNH TRÚNG GÂY GẤP ĐÔI."},
	"ocb_wide": {"n": "LƯỠI RỘNG", "m": 36, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "LR",
		"desc": "NHÁT CHÉM THƯỜNG RỘNG THÊM 20 ĐỘ VÀ XA THÊM 6."},
	"ocb_master": {"n": "KIẾM SƯ", "m": 36, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "KS",
		"desc": "MỌI NHÁT CHÉM GÂY THÊM 15%. CÁI GIÁ: NGOÀI GIAO CHIẾN, NỘ TỰ GIẢM NHANH GẤP ĐÔI. CẦN 6 ĐIỂM Ở CHIẾN BINH."},

	"ont_hot": {"n": "LỬA ÂM Ỉ", "m": 37, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "LA",
		"desc": "CHÁY KÉO DÀI THÊM 2 GIÂY."},
	"ont_spread": {"n": "BÉN LỬA", "m": 37, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "BL",
		"desc": "KẺ CHẾT KHI ĐANG CHÁY TRUYỀN CHÁY SANG KẺ GẦN NHẤT."},
	"ont_deepcold": {"n": "BĂNG SÂU", "m": 37, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "BS",
		"desc": "KẺ BỊ LẠNH LẦN NỮA KHI CÒN ĐANG LẠNH BỊ ĐÓNG BĂNG 1 GIÂY (TRỪ BOSS). 3 GIÂY MỘT LẦN MỖI KẺ."},
	"ont_frostbite": {"n": "CẮN GIÁ", "m": 37, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "CG",
		"desc": "KẺ ĐANG LẠNH NHẬN THÊM 10% SÁT THƯƠNG."},
	"ont_frostguard": {"n": "GIÁP SƯƠNG", "m": 37, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "GS",
		"desc": "VÒNG SƯƠNG CHO 15 KHIÊN."},
	"ont_arc": {"n": "SÉT ĐÁNH HAI", "m": 37, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "SH",
		"desc": "SÉT CHUYỀN ĐÁNH KẺ ĐẦU TIÊN THÊM MỘT LẦN NỮA, 100% TẤN CÔNG."},
	"ont_charge": {"n": "TÍCH ĐIỆN", "m": 37, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TD",
		"desc": "KẺ BỊ GIẬT NHẬN THÊM 10% SÁT THƯƠNG NỮA."},
	"ont_triad": {"n": "TAM HỢP", "m": 37, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "TH",
		"desc": "CỘNG HƯỞNG CHO THÊM 40% THAY VÌ 20%. CÁI GIÁ: PHÉP CÙNG HỆ VỚI PHÉP VỪA DÙNG GÂY ÍT HƠN 20%. CẦN 6 ĐIỂM Ở NGUYÊN TỐ SƯ."},

	"ost_shadow": {"n": "BÓNG DÀI", "m": 38, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "BD",
		"desc": "MÀN KHÓI KÉO DÀI THÊM 1,5 GIÂY."},
	"ost_step": {"n": "BƯỚC KÉP", "m": 38, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "BK",
		"desc": "BƯỚC BÓNG HỒI CHIÊU NHANH HƠN 30%."},
	"ost_toxic": {"n": "ĐỘC ĐẬM", "m": 38, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "DD",
		"desc": "ĐỘC CỘNG DỒN THÊM ĐƯỢC 2 LẦN."},
	"ost_seep": {"n": "THẤM ĐỘC", "m": 38, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TD",
		"desc": "MỖI CỘNG DỒN ĐỘC TRÊN MỤC TIÊU, ĐÒN CỦA BẠN LÊN NÓ GÂY THÊM 3%."},
	"ost_dart": {"n": "PHI TIÊU TẨM", "m": 38, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "PT",
		"desc": "PHI TIÊU ĐỘC GÂY 2 CỘNG DỒN THAY VÌ 1."},
	"ost_six": {"n": "SÁU NHÁT", "m": 38, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "SN",
		"desc": "ĐIỂM HIỂM TỐI ĐA THÊM 1."},
	"ost_reset": {"n": "KẾT LIỄU NỐI", "m": 38, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "KN",
		"desc": "ĐÒN KẾT LIỄU GIẾT ĐƯỢC MỤC TIÊU TRẢ LẠI 2 ĐIỂM HIỂM."},
	"ost_ghost": {"n": "VÔ ẢNH", "m": 38, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "VA",
		"desc": "SAU MỖI ĐÒN KẾT LIỄU, BẠN TAN VÀO KHÓI 1,5 GIÂY. CÁI GIÁ: MÁU TỐI ĐA GIẢM 10%. CẦN 6 ĐIỂM Ở SÁT THỦ."},

	"otl_host": {"n": "ĐẠO QUÂN", "m": 39, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "DQ",
		"desc": "GỌI ĐƯỢC THÊM 1 DƯ ẢNH."},
	"otl_strong": {"n": "BÓNG ĐẬM", "m": 39, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "BD",
		"desc": "DƯ ẢNH GÂY THÊM 25% SÁT THƯƠNG."},
	"otl_curse2": {"n": "NGUYỀN ĐẬM", "m": 39, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "ND",
		"desc": "KẺ BỊ NGUYỀN GÂY ÍT HƠN THÊM 10% SÁT THƯƠNG."},
	"otl_wither": {"n": "HÉO MÒN", "m": 39, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "HM",
		"desc": "KẺ BỊ NGUYỀN MẤT 20% TẤN CÔNG CỦA BẠN MỖI GIÂY."},
	"otl_bind": {"n": "XIỀNG DÀI", "m": 39, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "XD",
		"desc": "XIỀNG HỒN NỐI THÊM 2 KẺ."},
	"otl_eight": {"n": "TÁM HỒN", "m": 39, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TH",
		"desc": "GIỮ ĐƯỢC TỚI 8 HỒN."},
	"otl_reap": {"n": "GẶT ĐÔI", "m": 39, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "GD",
		"desc": "LƯỠI HÁI TRÚNG TỪ 3 KẺ TRỞ LÊN CHO THÊM 1 HỒN."},
	"otl_lich": {"n": "VUA HỒN", "m": 39, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "VH",
		"desc": "MỖI HỒN ĐANG GIỮ CHO THÊM 3% SÁT THƯƠNG. CÁI GIÁ: KHÔNG UỐNG ĐƯỢC BÌNH MÁU. CẦN 6 ĐIỂM Ở THUẬT SĨ LINH HỒN."},

	"ohv_cap": {"n": "THÀNH CAO", "m": 40, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TC",
		"desc": "KHIÊN TỐI ĐA THÊM 30."},
	"ohv_regen": {"n": "TỰ VÁ", "m": 40, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TV",
		"desc": "KHI KHIÊN DƯỚI 15, MỖI GIÂY BẠN NHẬN LẠI 3 KHIÊN."},
	"ohv_spikes": {"n": "GAI DÀY", "m": 40, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "GD",
		"desc": "GAI KHIÊN PHẢN LẠI GẤP ĐÔI."},
	"ohv_bash": {"n": "ĐẬP NẶNG", "m": 40, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DN",
		"desc": "ĐẬP KHIÊN CHỈ CẦN 25 KHIÊN ĐỂ GÂY THÊM 100%."},
	"ohv_verdict": {"n": "PHÁN QUYẾT LỚN", "m": 40, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "PL",
		"desc": "PHÁN QUYẾT RỘNG THÊM 40%."},
	"ohv_taunt": {"n": "GỌI ĐÀN", "m": 40, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "GD",
		"desc": "KHIÊU KHÍCH CHO KHIÊN TỪ TỐI ĐA 5 KẺ THAY VÌ 3."},
	"ohv_cover": {"n": "VÒNG RỘNG", "m": 40, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "VR",
		"desc": "VÒNG CHE RỘNG THÊM 30% VÀ TỒN TẠI THÊM 2 GIÂY."},
	"ohv_bulwark": {"n": "TƯỜNG THÀNH", "m": 40, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "TT",
		"desc": "KHI KHIÊN ĐẦY, ĐÒN NHỎ HƠN 10% MÁU CỦA BẠN KHÔNG LÀM MẤT GÌ. CÁI GIÁ: TỐC CHẠY GIẢM 10%. CẦN 6 ĐIỂM Ở HỘ VỆ."},

	"ots_quick": {"n": "TẬP TRUNG NHANH", "m": 41, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TN",
		"desc": "TẬP TRUNG CHỈ CẦN 1,2 GIÂY THAY VÌ 2."},
	"ots_deadeye": {"n": "NHẮM TRÚNG", "m": 41, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "NT",
		"desc": "ĐÒN TIÊU TẬP TRUNG MẠNH HƠN 60% THAY VÌ 40%."},
	"ots_traps": {"n": "BẪY KÉP", "m": 41, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "BK",
		"desc": "BẪY KẸP ĐẶT HAI BẪY MỘT LÚC."},
	"ots_jaw": {"n": "HÀM SẮT", "m": 41, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "HS",
		"desc": "TRÓI TỪ BẪY KẸP DÀI THÊM 1 GIÂY."},
	"ots_boom": {"n": "NỔ TO", "m": 41, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "NT",
		"desc": "BẪY NỔ RỘNG THÊM 40%."},
	"ots_alpha": {"n": "ĐẦU ĐÀN", "m": 41, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "DD",
		"desc": "THÚ THÊM 30% MÁU VÀ SÁT THƯƠNG."},
	"ots_mark": {"n": "DẤU SÂU", "m": 41, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DS",
		"desc": "KẺ MANG DẤU SĂN NHẬN THÊM 10% NỮA."},
	"ots_lone": {"n": "SÓI ĐƠN", "m": 41, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "SD",
		"desc": "BẠN GÂY THÊM 25% SÁT THƯƠNG. CÁI GIÁ: KHÔNG CÒN THÚ ĐI CÙNG. CẦN 6 ĐIỂM Ở THỢ SĂN."},

	"ott_bigheal": {"n": "MÕ LỚN", "m": 42, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "ML",
		"desc": "TIẾNG MÕ HỒI 35% MÁU THAY VÌ 25%."},
	"ott_ground": {"n": "ĐẤT RỘNG", "m": 42, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "DR",
		"desc": "ĐẤT THIÊNG RỘNG THÊM 40% VÀ TỒN TẠI THÊM 2 GIÂY."},
	"ott_brand": {"n": "ẤN SÂU", "m": 42, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "AS",
		"desc": "ẤN TRỪNG GÂY THÊM 20% VÀ ĐỂ SOI 10 GIÂY."},
	"ott_bright": {"n": "SOI RỰC", "m": 42, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "SR",
		"desc": "KẺ BỊ SOI NHẬN THÊM 5% SÁT THƯƠNG NỮA."},
	"ott_cleanse": {"n": "QUÉT SẠCH", "m": 42, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "QS",
		"desc": "TRỪ TÀ RỘNG THÊM 30%."},
	"ott_grace": {"n": "PHƯỚC DÀY", "m": 42, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "PD",
		"desc": "CHÚC LÀNH CHO THÊM 25% SÁT THƯƠNG THAY VÌ 15%."},
	"ott_vow": {"n": "NGUYỆN DÀI", "m": 42, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "ND",
		"desc": "LỜI NGUYỆN KÉO DÀI 5 GIÂY THAY VÌ 3."},
	"ott_saint": {"n": "THÁNH NHÂN", "m": 42, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "TN",
		"desc": "KHI THÀNH KÍNH TỪ 80 TRỞ LÊN, MỖI GIÂY BẠN HỒI 2% MÁU. CÁI GIÁ: BẠN GÂY ÍT HƠN 10% SÁT THƯƠNG. CẦN 6 ĐIỂM Ở TƯ TẾ."},

	"oks_turret": {"n": "TRỤ ĐÔI", "m": 43, "b": 0, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "TD",
		"desc": "TRỤ NỎ BẮN HAI MŨI MỖI LẦN."},
	"oks_mine": {"n": "MÌN NẶNG", "m": 43, "b": 0, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "MN",
		"desc": "MÌN CHUÔNG GÂY THÊM 40%."},
	"oks_vent": {"n": "XẢ SẠCH", "m": 43, "b": 1, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "XS",
		"desc": "XẢ HƠI XA THÊM 40%."},
	"oks_cool": {"n": "TẢN NHANH", "m": 43, "b": 1, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "TN",
		"desc": "QUÁ NHIỆT NGẮN HƠN 1 GIÂY."},
	"oks_hot": {"n": "VÙNG NÓNG", "m": 43, "b": 1, "pos": [2, 0], "kind": "p", "max": 1, "abbr": "VN",
		"desc": "MỌI HIỆU ỨNG \"TRÊN 70 NHIỆT\" BẮT ĐẦU TỪ 60 NHIỆT."},
	"oks_hook": {"n": "MÓC NHANH", "m": 43, "b": 2, "pos": [0, 0], "kind": "p", "max": 1, "abbr": "MN",
		"desc": "MÓC KÉO HỒI CHIÊU NHANH HƠN 40%."},
	"oks_mute": {"n": "CHUÔNG LỚN", "m": 43, "b": 2, "pos": [1, 0], "kind": "p", "max": 1, "abbr": "CL",
		"desc": "CHUÔNG CÂM RỘNG THÊM 40%."},
	"oks_four": {"n": "BỐN MÁY", "m": 43, "b": -1, "pos": [0, 0], "kind": "k", "max": 1, "abbr": "BM",
		"desc": "ĐẶT ĐƯỢC TỚI 4 THIẾT BỊ. CÁI GIÁ: MỖI THIẾT BỊ CỘNG THÊM 10 NHIỆT KHI ĐẶT. CẦN 6 ĐIỂM Ở KỸ SƯ CỔ VẬT."},
}

# Indexed by a node's "m". Masteries: 0, 1, 3, 6, 10. The others are the link trees of the pairs in LINKS.
const MASTERY = ["CHIẾN BINH", "NGUYÊN TỐ SƯ", "KIẾM BÃO", "SÁT THỦ", "LƯỠI BÓNG", "DẠ LÔI", "THUẬT SĨ LINH HỒN", "KIẾM TANG", "TRO HỒN", "GẶT HỒN",
	"HỘ VỆ", "TRẤN THỦ", "LŨY SẤM", "DẠ VỆ", "MỘ VỆ", "THỢ SĂN", "TIÊN PHONG", "THIÊN TIỄN", "TRUY ẢNH", "HỒN LẠP", "BIÊN VỆ",
	"TƯ TẾ", "KIẾM NGUYỆN", "NHẬT QUANG", "PHÁN QUAN", "CHIÊU HỒN", "THÁNH VỆ", "TUẦN LÂM",
	"KỸ SƯ CỔ VẬT", "THIẾT THỦ", "LÔI CÔNG", "THỢ BÓNG", "KHÔI LỖI SƯ", "PHÁO LŨY", "CƠ LẠP", "THỢ CHUÔNG",
	"ĐỘC TẤU KIẾM", "ĐỘC TẤU PHÉP", "ĐỘC TẤU BÓNG", "ĐỘC TẤU HỒN", "ĐỘC TẤU KHIÊN", "ĐỘC TẤU SĂN", "ĐỘC TẤU MÕ", "ĐỘC TẤU MÁY"]
# the solo tree (Độc Tấu) of each mastery, by the solo tree's index
const SOLO = {36: 0, 37: 1, 38: 3, 39: 6, 40: 10, 41: 15, 42: 21, 43: 28}
# extra ranks a pure-mastery hero can put in each active skill of the main mastery (each: 6% faster cooldown)
const MASTER_RANKS = 3
const LINKS = {2: [0, 1], 4: [0, 3], 5: [1, 3], 7: [0, 6], 8: [1, 6], 9: [3, 6], 11: [0, 10], 12: [1, 10], 13: [3, 10], 14: [6, 10], 16: [0, 15], 17: [1, 15], 18: [3, 15], 19: [6, 15], 20: [10, 15],
	22: [0, 21], 23: [1, 21], 24: [3, 21], 25: [6, 21], 26: [10, 21], 27: [15, 21],
	29: [0, 28], 30: [1, 28], 31: [3, 28], 32: [6, 28], 33: [10, 28], 34: [15, 28], 35: [21, 28]}
# what Ngải names when the second face of the shard opens, by the mastery that wakes
const WAKES = {0: "THỦ, NỘ VÀ BINH KHÍ", 1: "LỬA, BĂNG VÀ SÉT", 3: "BÓNG, ĐỘC VÀ KẾT LIỄU", 6: "TRIỆU HỒI, NGUYỀN VÀ GẶT", 10: "THÀNH LŨY, TRỪNG PHẠT VÀ HỘ TỐNG", 15: "THIỆN XẠ, BẪY VÀ THÚ", 21: "CHỮA LÀNH, THANH TẨY VÀ BAN PHƯỚC", 28: "CƠ QUAN, HƠI NƯỚC VÀ CỔ VẬT"}
const BRANCHES = [["THỦ", "NỘ", "BINH KHÍ"], ["LỬA", "BĂNG", "SÉT"], ["VỚI THỦ", "VỚI NỘ", "VỚI BINH KHÍ"],
	["BÓNG", "ĐỘC", "KẾT LIỄU"], ["VỚI THỦ", "VỚI NỘ", "VỚI BINH KHÍ"], ["VỚI LỬA", "VỚI BĂNG", "VỚI SÉT"],
	["TRIỆU HỒI", "NGUYỀN", "GẶT"], ["VỚI THỦ", "VỚI NỘ", "VỚI BINH KHÍ"], ["VỚI LỬA", "VỚI BĂNG", "VỚI SÉT"], ["VỚI BÓNG", "VỚI ĐỘC", "VỚI KẾT LIỄU"],
	["THÀNH LŨY", "TRỪNG PHẠT", "HỘ TỐNG"], ["VỚI THỦ", "VỚI NỘ", "VỚI BINH KHÍ"], ["VỚI LỬA", "VỚI BĂNG", "VỚI SÉT"],
	["VỚI BÓNG", "VỚI ĐỘC", "VỚI KẾT LIỄU"], ["VỚI TRIỆU HỒI", "VỚI NGUYỀN", "VỚI GẶT"],
	["THIỆN XẠ", "BẪY", "THÚ"], ["VỚI THỦ", "VỚI NỘ", "VỚI BINH KHÍ"], ["VỚI LỬA", "VỚI BĂNG", "VỚI SÉT"],
	["VỚI BÓNG", "VỚI ĐỘC", "VỚI KẾT LIỄU"], ["VỚI TRIỆU HỒI", "VỚI NGUYỀN", "VỚI GẶT"], ["VỚI THÀNH LŨY", "VỚI TRỪNG PHẠT", "VỚI HỘ TỐNG"],
	["CHỮA LÀNH", "THANH TẨY", "BAN PHƯỚC"], ["VỚI THỦ", "VỚI NỘ", "VỚI BINH KHÍ"], ["VỚI LỬA", "VỚI BĂNG", "VỚI SÉT"], ["VỚI BÓNG", "VỚI ĐỘC", "VỚI KẾT LIỄU"],
	["VỚI TRIỆU HỒI", "VỚI NGUYỀN", "VỚI GẶT"], ["VỚI THÀNH LŨY", "VỚI TRỪNG PHẠT", "VỚI HỘ TỐNG"], ["VỚI THIỆN XẠ", "VỚI BẪY", "VỚI THÚ"],
	["CƠ QUAN", "HƠI NƯỚC", "CỔ VẬT"], ["VỚI THỦ", "VỚI NỘ", "VỚI BINH KHÍ"], ["VỚI LỬA", "VỚI BĂNG", "VỚI SÉT"], ["VỚI BÓNG", "VỚI ĐỘC", "VỚI KẾT LIỄU"],
	["VỚI TRIỆU HỒI", "VỚI NGUYỀN", "VỚI GẶT"], ["VỚI THÀNH LŨY", "VỚI TRỪNG PHẠT", "VỚI HỘ TỐNG"], ["VỚI THIỆN XẠ", "VỚI BẪY", "VỚI THÚ"],
	["VỚI CHỮA LÀNH", "VỚI THANH TẨY", "VỚI BAN PHƯỚC"],
	["THỦ", "NỘ", "BINH KHÍ"], ["LỬA", "BĂNG", "SÉT"], ["BÓNG", "ĐỘC", "KẾT LIỄU"], ["TRIỆU HỒI", "NGUYỀN", "GẶT"],
	["THÀNH LŨY", "TRỪNG PHẠT", "HỘ TỐNG"], ["THIỆN XẠ", "BẪY", "THÚ"], ["CHỮA LÀNH", "THANH TẨY", "BAN PHƯỚC"], ["CƠ QUAN", "HƠI NƯỚC", "CỔ VẬT"]]
const COLS = [
	[Color("8fb0d6"), Color("c4566a"), Color("d9a05b")],
	[Color("e98a2e"), Color("7fd4e8"), Color("9db4ff")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("9a7fc9"), Color("8fd66a"), Color("d94a5a")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("9fe3e0"), Color("b07fd6"), Color("6fc9a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("c9b98a"), Color("d97a4a"), Color("e0b04a")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("d9c27a"), Color("a8a29a"), Color("6fc9a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("8fe08a"), Color("fff0b0"), Color("f0c8e0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("c98a4a"), Color("d0d0d8"), Color("8ac0b0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("a9d6a0"), Color("a9d6a0"), Color("a9d6a0")],
	[Color("8fb0d6"), Color("c4566a"), Color("d9a05b")],
	[Color("e98a2e"), Color("7fd4e8"), Color("9db4ff")],
	[Color("9a7fc9"), Color("8fd66a"), Color("d94a5a")],
	[Color("9fe3e0"), Color("b07fd6"), Color("6fc9a0")],
	[Color("c9b98a"), Color("d97a4a"), Color("e0b04a")],
	[Color("d9c27a"), Color("a8a29a"), Color("6fc9a0")],
	[Color("8fe08a"), Color("fff0b0"), Color("f0c8e0")],
	[Color("c98a4a"), Color("d0d0d8"), Color("8ac0b0")],
]
const LINK_NEED = 3
const LINK_KEY_NEED = 6
const MARK_COL = {"burn": Color("e98a2e"), "chill": Color("7fd4e8"), "shock": Color("9db4ff"), "poison": Color("8fd66a"), "curse": Color("b07fd6"), "taunt": Color("e0b04a"), "hunt": Color("e05a3a"), "root": Color("b08a5a"), "lit": Color("fff0b0")}

# what blocked() answers; ui.gd compares against these
const FULL = "ĐÃ HỌC ĐỦ"
const NO_POINTS = "HẾT ĐIỂM"
const NO_SECOND = "MẢNH CHUÔNG MỚI CÓ MỘT GIỌNG"
const NOT_YOURS = "KHÔNG THUỘC DÒNG NGHỀ CỦA BẠN"
const SOLO_LOCKED = "ĐÃ ĐẶT ĐIỂM VÀO DÒNG NGHỀ THỨ HAI"
const SOLO_TAKEN = "ĐANG ĐI ĐỘC TẤU (X ĐỂ HOÀN ĐIỂM)"

# swing-type skills use the same row layout as game.ATK:
# [startup, active, recovery, damage x attack, reach, half angle, lunge speed, hitstop, shake]
const SWING = {
	"spin": [3 * F, 2 * F, 3 * F, 2.4, 48.0, 180.0, 0.0, 0.10, 3.0],
	"slam": [4 * F, 2 * F, 4 * F, 1.8, 58.0, 180.0, 0.0, 0.12, 3.5],
	"toll": [5 * F, 2 * F, 5 * F, 4.0, 100.0, 180.0, 0.0, 0.18, 4.0],
	"slash": [2 * F, F, 2 * F, 0.6, 38.0, 70.0, 80.0, 0.07, 2.0],
	"exec": [3 * F, F, 4 * F, 1.0, 40.0, 60.0, 100.0, 0.12, 3.5],
	"scythe": [3 * F, F, 3 * F, 1.5, 50.0, 110.0, 0.0, 0.08, 2.5],
	"bash": [2 * F, F, 3 * F, 1.4, 40.0, 70.0, 60.0, 0.09, 2.5],
}

static func col(id: String) -> Color:
	var N = NODES[id]
	if N.b < 0:
		return Color("ffe9a3")
	return COLS[N.get("m", 0)][N.b]

static func mastery_points(tree: Dictionary, m: int) -> int:
	var n = 0
	for id in tree:
		if NODES[id].get("m", 0) == m:
			n += tree[id]
	return n

static func spent(tree: Dictionary) -> int:
	var n = 0
	for id in tree:
		n += tree[id]
	return n

static func branch_points(tree: Dictionary, m: int, b: int) -> int:
	var n = 0
	for id in tree:
		if NODES[id].get("m", 0) == m and NODES[id].b == b:
			n += tree[id]
	return n

# "" when a rank can be bought now, otherwise the reason it cannot.
# second: whether the hero's shard has opened its second face.
# the link tree of two masteries, or -1
static func link_of(a: int, b: int) -> int:
	for k in LINKS:
		if (LINKS[k][0] == a and LINKS[k][1] == b) or (LINKS[k][0] == b and LINKS[k][1] == a):
			return k
	return -1

# main: the mastery chosen at character creation. sec: the second one (-1: the default partner).
# second: whether the shard has opened its second face yet.
static func blocked(tree: Dictionary, id: String, lvl: int, second: bool, main: int = 0, sec: int = -1) -> String:
	var N = NODES[id]
	var m = N.get("m", 0)
	if sec < 0:
		sec = 1 if main == 0 else 0
	if tree.get(id, 0) >= max_rank(tree, id, second, main, sec):
		return FULL
	if LINKS.has(m):
		if m != link_of(main, sec):
			return NOT_YOURS
		if not second:
			return NO_SECOND
		if went_solo(tree, main):
			return SOLO_TAKEN
		var need = LINK_KEY_NEED if N.kind == "k" else LINK_NEED
		if mastery_points(tree, LINKS[m][0]) < need or mastery_points(tree, LINKS[m][1]) < need:
			return "CẦN %d ĐIỂM Ở MỖI DÒNG NGHỀ" % need
	elif SOLO.has(m):
		if SOLO[m] != main:
			return NOT_YOURS
		if not second:
			return NO_SECOND
		if mastery_points(tree, sec) > 0:
			return SOLO_LOCKED
		var need2 = LINK_KEY_NEED if N.kind == "k" else LINK_NEED
		if mastery_points(tree, main) < need2:
			return "CẦN %d ĐIỂM Ở %s" % [need2, MASTERY[main]]
	else:
		if m != main and m != sec:
			return NOT_YOURS
		if m == sec and not second:
			return NO_SECOND
		if m == sec and went_solo(tree, main):
			return SOLO_TAKEN
		if N.kind == "u":
			if mastery_points(tree, m) < ULT_NEED:
				return "CẦN %d ĐIỂM Ở %s" % [ULT_NEED, MASTERY[m]]
		elif branch_points(tree, m, N.b) < ROW_NEED[N.pos[1]]:
			return "CẦN %d ĐIỂM Ở NHÁNH %s" % [ROW_NEED[N.pos[1]], BRANCHES[m][N.b]]
	if lvl - spent(tree) <= 0:
		return NO_POINTS
	return ""

# the solo tree of a mastery, or -1
static func solo_of(main: int) -> int:
	for k in SOLO:
		if SOLO[k] == main:
			return k
	return -1

# a point in the solo tree, or a mastery rank above the first in an active skill, means the hero went solo
static func went_solo(tree: Dictionary, main: int) -> bool:
	for id in tree:
		var N = NODES[id]
		if N.get("m", 0) == solo_of(main) or (N.get("m", 0) == main and N.kind == "a" and tree[id] > N.max):
			return true
	return false

# an active skill of the main mastery takes 3 more ranks while the second mastery stays empty
static func max_rank(tree: Dictionary, id: String, second: bool, main: int, sec: int) -> int:
	var N = NODES[id]
	if N.kind == "a" and N.get("m", 0) == main and second and mastery_points(tree, sec) == 0:
		return N.max + MASTER_RANKS
	return N.max
