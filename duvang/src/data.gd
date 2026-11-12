extends RefCounted
# Tunable content: foes, items, quests, dialogue. On-screen text is Vietnamese capitals; ids and comments stay ASCII.

const F = 1.0 / 12.0   # one animation frame

const DEFAULT_SAVE = "user://duvang_save.json"
static var SAVE_PATH = DEFAULT_SAVE   # tests point this elsewhere
# title screen and menus: -1 only with the real save file (so tests boot straight into play), 1 always
static var MENUS = -1

# aggro: distance at which a foe notices the hero. gold: [min, max].
const FOES = {
	"reed": {"name": "LAU ẢNH", "hp": 34.0, "spd": 46.0, "r": 7.0, "poise": 0.0, "range": 30.0, "wind": 0.5, "rec": 0.6, "dmg": 10.0, "cd": 0.5, "xp": 12, "gold": [1, 4], "aggro": 110.0, "loot": 0.16},
	"heron": {"name": "CÒ TRO", "hp": 24.0, "spd": 54.0, "r": 7.0, "poise": 0.0, "range": 150.0, "wind": 0.7, "rec": 0.5, "dmg": 9.0, "cd": 2.2, "xp": 14, "gold": [1, 5], "aggro": 170.0, "loot": 0.18},
	"porter": {"name": "PHU PHÀ CHÌM", "hp": 150.0, "spd": 30.0, "r": 14.0, "poise": 30.0, "range": 46.0, "wind": 0.9, "rec": 1.1, "dmg": 24.0, "cd": 0.8, "xp": 60, "gold": [8, 16], "aggro": 120.0, "loot": 1.0},
	"boss": {"name": "NGƯỜI GÁC PHÀ KHÔNG BỜ", "hp": 900.0, "spd": 42.0, "r": 16.0, "poise": 70.0, "range": 62.0, "wind": 0.8, "rec": 0.9, "dmg": 26.0, "cd": 0.7, "xp": 300, "gold": [80, 120], "aggro": 260.0, "loot": 1.0, "big": true},
	"leech": {"name": "ĐỈA BÙN", "hp": 30.0, "spd": 78.0, "r": 7.0, "poise": 0.0, "range": 76.0, "wind": 0.45, "rec": 0.7, "dmg": 12.0, "cd": 1.4, "xp": 16, "gold": [1, 5], "aggro": 130.0, "loot": 0.16},
	"netter": {"name": "KẺ THẢ LƯỚI", "hp": 40.0, "spd": 44.0, "r": 7.0, "poise": 0.0, "range": 130.0, "wind": 0.9, "rec": 0.7, "dmg": 8.0, "cd": 3.0, "xp": 18, "gold": [2, 6], "aggro": 170.0, "loot": 0.2},
	"wisp": {"name": "MA ĐÈN LỒNG", "hp": 26.0, "spd": 50.0, "r": 6.0, "poise": 0.0, "range": 140.0, "wind": 0.8, "rec": 0.6, "dmg": 8.0, "cd": 2.6, "xp": 18, "gold": [2, 6], "aggro": 170.0, "loot": 0.2},
	"keeper": {"name": "NGƯỜI THU PHÍ", "hp": 520.0, "spd": 36.0, "r": 15.0, "poise": 60.0, "range": 56.0, "wind": 0.8, "rec": 0.9, "dmg": 22.0, "cd": 0.8, "xp": 180, "gold": [40, 60], "aggro": 200.0, "loot": 1.0, "big": true},
	"wolf": {"name": "SÓI KÝ ỨC", "hp": 46.0, "spd": 84.0, "r": 7.0, "poise": 0.0, "range": 30.0, "wind": 0.35, "rec": 0.5, "dmg": 13.0, "cd": 0.9, "xp": 30, "gold": [3, 8], "aggro": 150.0, "loot": 0.16},
	"sower": {"name": "KẺ GIEO BÀO TỬ", "hp": 60.0, "spd": 40.0, "r": 8.0, "poise": 0.0, "range": 130.0, "wind": 0.9, "rec": 0.8, "dmg": 14.0, "cd": 3.4, "xp": 40, "gold": [4, 10], "aggro": 170.0, "loot": 0.22},
	"deer": {"name": "HƯƠU RỖNG", "hp": 240.0, "spd": 44.0, "r": 13.0, "poise": 40.0, "range": 150.0, "wind": 1.0, "rec": 1.6, "dmg": 30.0, "cd": 1.6, "xp": 110, "gold": [12, 24], "aggro": 190.0, "loot": 1.0},
	"mother": {"name": "MẸ RỄ NGÀN TÊN", "hp": 2400.0, "spd": 0.0, "r": 24.0, "poise": 120.0, "range": 80.0, "wind": 1.0, "rec": 1.0, "dmg": 30.0, "cd": 0.9, "xp": 900, "gold": [200, 300], "aggro": 230.0, "loot": 1.0, "big": true, "fixed": true},
}

# Elite marks change how a foe must be fought, not just its numbers.
# volatile: bursts a second after it dies. warding: foes near it take half damage, so it dies first.
const ELITE = {"volatile": {"name": "DỄ NỔ", "col": Color("ff9a6a")}, "warding": {"name": "CHE CHỞ", "col": Color("b8c8ff")}}

const RAR_NAME = ["THƯỜNG", "PHÉP", "HIẾM", "ĐỘC NHẤT"]
const RAR_COL = [Color("f4ebd0"), Color("6fb7ff"), Color("ffd24a"), Color("ff8fc2")]
const STAT_NAME = {
	"atk": "TẤN CÔNG", "def": "GIÁP", "hp": "MÁU", "rage": "NỘ NHẬN %", "spd": "TỐC CHẠY %", "leech": "HÚT MÁU %",
	"reach": "TẦM ĐÁNH", "haste": "TỐC ĐÁNH %", "stag": "PHÁ THẾ %", "crit": "CHÍ MẠNG %", "cdr": "GIẢM HỒI CHIÊU %",
	"regen": "MÁU MỖI GIÂY", "gold": "VÀNG RƠI %",
}
const SLOTS = ["weapon", "armor", "charm"]
const SLOT_NAME = {"weapon": "VŨ KHÍ", "armor": "GIÁP", "charm": "BÙA"}
const FILTER_NAME = ["MỌI MÓN", "TỪ PHÉP TRỞ LÊN", "TỪ HIẾM TRỞ LÊN"]

# Twenty base items: [name, tier, what it always has]. The tier a zone drops is set in world.gd.
# A base is a way of fighting, not just a bigger number: dirks are fast, spears are long,
# mauls are slow and break stances.
const BASES = {
	"weapon": [
		["DAO CẮT LAU", 0, {"atk": 4}], ["DAO GĂM ĐẦM", 0, {"atk": 3, "haste": 12}],
		["MÓC PHÀ", 1, {"atk": 7}], ["GIÁO BẾN", 1, {"atk": 6, "reach": 8}], ["VỒ ĐÊ", 1, {"atk": 9, "haste": -12, "stag": 40}],
		["ĐAO ĐỒNG", 2, {"atk": 11}], ["SÀO THU PHÍ", 2, {"atk": 10, "reach": 10}], ["BÚA CHUÔNG", 2, {"atk": 14, "haste": -14, "stag": 50}],
		# bows: the chain of strikes becomes three arrows, the third goes through (see is_bow)
		["CUNG TRE", 0, {"atk": 3}], ["CUNG SỪNG", 1, {"atk": 6, "crit": 3}], ["CUNG ĐỒNG", 2, {"atk": 10, "crit": 4}],
	],
	"armor": [
		["ÁO LAU", 0, {"def": 3}], ["KHỐ LỘI NƯỚC", 0, {"def": 2, "spd": 4}],
		["ÁO ĐÊ", 1, {"def": 6}], ["GIÁP LƯỚI", 1, {"def": 5, "hp": 12}],
		["GIÁP TRẠM", 2, {"def": 10, "spd": -4}], ["ÁO CHOÀNG PHÀ", 2, {"def": 6, "spd": 6}],
	],
	"charm": [
		["BÙA MÕ", 0, {"hp": 15}], ["NHÚM TRO", 0, {"rage": 15}],
		["HỘP MẢNH CHUÔNG", 1, {"hp": 25}], ["LÔNG CÒ", 1, {"hp": 10, "spd": 5}],
		["DẰM CHUÔNG", 2, {"hp": 40}], ["ÂM THOA", 2, {"hp": 15, "cdr": 8}],
	],
}
# Twelve properties: [stat, word added after the name, min, max, slots that can roll it].
# Magic items roll one, rare items two different ones. Values grow with the item's tier.
const AFFIX = [
	["atk", "SẮC", 2, 4, ["weapon"]], ["leech", "KHÁT MÁU", 2, 4, ["weapon"]], ["haste", "LẸ", 6, 10, ["weapon"]],
	["stag", "NGHIỀN", 20, 30, ["weapon"]], ["crit", "CHUẨN", 4, 8, ["weapon", "charm"]], ["rage", "CUỒNG", 20, 40, ["weapon", "armor", "charm"]],
	["def", "BỀN", 2, 4, ["armor"]], ["hp", "TRÁNG", 10, 20, ["armor", "charm"]], ["spd", "NHANH", 4, 8, ["armor"]],
	["regen", "HỒI SINH", 1, 2, ["armor", "charm"]], ["cdr", "KHÉO", 4, 8, ["charm"]], ["gold", "MAY", 15, 30, ["charm"]],
]

# pick: index among the bases of that slot and tier; -1 chooses one at random
static func make_item(slot: String, tier: int, rar: int, pick: int = -1) -> Dictionary:
	var same = BASES[slot].filter(func(b): return b[1] == clampi(tier, 0, 2))
	var b = same[pick if pick >= 0 else randi() % same.size()]
	var it = {"name": b[0], "slot": slot, "rar": rar, "tier": tier, "stats": b[2].duplicate(), "uniq": ""}
	var pool = AFFIX.filter(func(a): return a[4].has(slot))
	pool.shuffle()
	for i in rar:
		var a = pool[i]
		it.stats[a[0]] = it.stats.get(a[0], 0) + randi_range(a[2], a[3]) * (1 + tier) / 2
		if i == 0:
			it.name = it.name + " " + a[1]
	return it

static func roll_item(tier: int) -> Dictionary:
	var r = randf()
	var rar = 2 if r < 0.08 else (1 if r < 0.38 else 0)
	return make_item(SLOTS[randi() % 3], tier, rar)

# the picture for an item: uniques by their effect, the rest by their base (found from the start of the name)
static func icon(it: Dictionary) -> String:
	if it.uniq != "":
		return "it_u_" + it.uniq
	var list = BASES[it.slot]
	for i in list.size():
		if it.name.begins_with(list[i][0]):
			return "it_%s%d" % [it.slot[0], i]
	return "ic_" + it.slot

static func value(it: Dictionary) -> int:
	return 4 * (it.tier + 1) * (it.rar + 1) + (30 if it.rar == 3 else 0)

# ---- the four uniques. Each changes what you do, and each has one place to hunt it.
# The Ferryman always drops this: the third strike of the chain throws a wave down the line of the swing.
static func ferry_oar() -> Dictionary:
	return {"name": "MÁI CHÈO NGƯỜI GÁC PHÀ", "slot": "weapon", "rar": 3, "tier": 2, "stats": {"atk": 13, "rage": 20}, "uniq": "wave"}

# The Toll Keeper drops this once: it rewards cutting a cast short.
static func toll_box() -> Dictionary:
	return {"name": "HÒM THU PHÍ", "slot": "charm", "rar": 3, "tier": 2, "stats": {"hp": 30, "def": 3}, "uniq": "box"}

# The tree-mother drops this: it pays for stacking marks, so it suits a two-mastery build.
static func seed_unique() -> Dictionary:
	return {"name": "HẠT NGÀN TÊN", "slot": "charm", "rar": 3, "tier": 2, "stats": {"hp": 35, "cdr": 6}, "uniq": "seed"}

# Elites drop one of these by their mark: volatile the wrap, warding the wick.
static func elite_unique(mark: String) -> Dictionary:
	if mark == "volatile":
		return {"name": "ÁO NGƯỜI ĐI TRO", "slot": "armor", "rar": 3, "tier": 2, "stats": {"def": 5, "spd": 6}, "uniq": "free"}
	return {"name": "BẤC ĐÈN", "slot": "charm", "rar": 3, "tier": 2, "stats": {"hp": 20, "regen": 2}, "uniq": "wick"}

# The chance rises with every elite that drops none, so a hunt always ends: 12%, 18%, 24% ... certain at the 16th.
const PITY_BASE = 0.12
const PITY_STEP = 0.06

const UNIQ_TEXT = {
	"wave": "ĐÒN THỨ BA NÉM MỘT LÀN SÓNG", "box": "NGẮT ĐÒN: HỒI 10% MÁU, +30 NỘ",
	"free": "NÉ TRÚNG ĐÒN: KỸ NĂNG KẾ MIỄN PHÍ", "wick": "GIẾT KẺ ĐANG CHÁY HỒI 4% MÁU",
	"seed": "MỖI DẤU TRÊN KẺ ĐỊCH: +8% SÁT THƯƠNG",
}

const POTION_COST = 15
const POTION_HEAL = 0.45
const POTION_CD = 6.0

static func xp_need(lvl: int) -> int:
	return int(40.0 * pow(lvl, 1.5))

# ---------------------------------------------------------------- people

const NPCS = {
	"say": {"name": "BÀ CẢ SẬY", "tex": "npc_say"},
	"ngai": {"name": "NGẢI", "tex": "npc_ngai"},
	"kham": {"name": "THẦY KHÂM", "tex": "npc_kham"},
	"dien": {"name": "GIÁM LẶNG TỐ DIÊN", "tex": "npc_dien"},
	"reu": {"name": "LÃO RÊU", "tex": "npc_reu"},
	"man": {"name": "BÀ MẬN", "tex": "npc_man"},
}

const INTRO = [
	"BA TRĂM MƯỜI HAI NĂM TRƯỚC, CHUÔNG MẸ NỨT VÀ RƠI. TỪ ĐÊM ẤY, KÝ ỨC CỦA NGƯỜI CHẾT KHÔNG CÒN TAN ĐI. NÓ LẮNG XUỐNG, NHƯ TRO.",
	"NƠI NÀO NÓ LẮNG DÀY, NƠI ẤY LẶP LẠI MÃI GIỜ KHẮC CUỐI CỦA MÌNH. NGƯỜI TA GỌI ĐÓ LÀ HẦM VỌNG, VÀ GỌI NHỮNG THỨ ĐI LẠI TRONG ĐÓ LÀ DƯ ẢNH.",
	"VÃN, NGƯỜI NUÔI BẠN LỚN, BƯỚC VÀO BẾN PHÀ CŨ BA NĂM TRƯỚC VÀ KHÔNG TRỞ RA. KHÔNG AI BIẾT VÌ SAO VÃN ĐI MỘT MÌNH.",
	"TRONG NGỰC BẠN CÓ MỘT MẢNH CHUÔNG. NÓ TỪNG LÀ CỦA VÃN. ĐÊM QUA, LẦN ĐẦU TIÊN, NÓ KÊU.",
]

# What each person says when they have no quest business with you. Indexed by main quests finished.
const CHAT = {
	"say": [
		["PHƯỜNG NUÔI CẢ TRẤN NÀY BẰNG NHỮNG GÌ HẦM VỌNG NHẢ RA. NHỚ LẤY ĐIỀU ĐÓ KHI BỌN GIỮ LẶNG GIẢNG ĐẠO."],
		["VÃN CHƯA TỪNG NÓI VỚI TA VÌ SAO. TA ĐÃ CÓ BA NĂM ĐỂ GIẬN CHUYỆN ĐÓ."],
		["CẢ TRẤN ĐÃ NGHE MẢNH CHUÔNG CỦA NGƯƠI KÊU. BỌN GIỮ LẶNG CŨNG VẬY."],
	],
	"ngai": [
		["MÌNH KHÔNG NGHE ĐƯỢC NGƯỜI CHẾT. KHÔNG MỘT CHỮ. NHƯNG MÌNH LÊN DÂY ĐƯỢC THỨ MANG TIẾNG HỌ. ĐỨNG YÊN NÀO."],
		["BẠN VỀ NGUYÊN VẸN RỒI. ĐỂ MÌNH LÊN DÂY LẠI. THẦY KHÂM BẢO MÌNH HAY LO QUÁ."],
		["VÃN HAY MANG MÕ VỠ TỪ BẾN PHÀ VỀ CHO MÌNH. MÌNH VẪN GIỮ HẾT."],
		["BẠN NGHE ĐƯỢC MỘT GIỌNG TRONG MẢNH CHUÔNG Ư? MÌNH SẴN SÀNG ĐỔI MỌI THỨ ĐỂ NGHE ĐƯỢC MỘT GIỌNG. BẤT KỲ AI."],
	],
	"kham": [
		["ĐỨA NHỎ CỦA VÃN. TA MUA THỨ ĐẦM LẦY NHẢ RA VÀ BÁN THỨ GIỮ CHO NGƯƠI CÒN THỞ."],
		["MANG CHO TA NHỮNG GÌ LŨ DƯ ẢNH ĐÁNH RƠI. TA TRẢ SÒNG PHẲNG. THỨ NÀO CÓ TÊN THÌ TRẢ HẬU HƠN."],
		["NẾU NGƯỜI GÁC PHÀ ĐỂ LẠI MỘT DƯ ÂM, MANG ĐẾN CHO TA TRƯỚC. NÓI TA NGHE HẮN TỰ XƯNG LÀ GÌ."],
		["VẬY LÀ HẮN ĐI RỒI. CÒN CUỐN SỔ? ... SỔ NÀO Ư. THÔI BỎ ĐI. XEM TÚI NGƯƠI CÓ GÌ NÀO."],
	],
	"dien": [
		["MỖI KẺ NHẶT VỌNG KHUẤY ĐẦM LẦY LÀ MỘT LẦN NÓ RỘNG THÊM. NHỚ LẤY KHI NGƯƠI ĐẾM TIỀN."],
		["TA ĐÃ TỰ TAY HẠ EM TRAI MÌNH KHI MẢNH CHUÔNG CỦA NÓ NHẬN GIỌNG THỨ BA. VỚI NGƯƠI TA CŨNG SẼ LÀM VẬY."],
		["NGƯƠI XONG VIỆC Ở BẾN PHÀ THÌ TA NIÊM NÓ. MUỐN NÓI GÌ VỚI BÀ CẢ SẬY THÌ CỨ NÓI."],
		["BẾN PHÀ ĐÃ IM. RẠNG SÁNG TA NIÊM. ĐÓ LÀ LÒNG TỐT, DÙ BÀ TA CÓ NÓI GÌ VỚI NGƯƠI."],
	],
	"reu": [
		["BỐN MƯƠI NĂM TA SỐNG VỚI BÀ NHÀ TA SAU KHI BÀ ẤY MẤT. CÓ NGƯỜI GỌI ĐÓ LÀ BỆNH. TA GỌI ĐÓ LÀ HÔN NHÂN."],
	],
	"man": [
		["ÔNG NHÀ TÔI CỨ NHÌN TÔI NHƯ THỂ TÔI SẮP ĐI ĐÂU. TÔI CÓ ĐI ĐÂU ĐÂU. TÔI CÒN PHẢI NẤU CƠM."],
	],
}

# ---------------------------------------------------------------- quests
# need: any of  kill {kind: n} | loot [name, n, kind] (drops from that kind while the quest is active)
#               see [ids of things or scenes] | talk npc id (the quest ends by talking to that person)
# after: quests that must be finished first. ender: who takes the hand-in (default: the giver).
# branch: a flag set by a choice; done and reward are then lists picked by its value.
# ORDER is the order quests are offered in; main quests come before side ones.

const ORDER = ["m1", "m2", "m3", "m4", "m5", "m6", "m7", "m8", "m9", "m10", "m11", "s1", "s2", "s3"]

const QUESTS = {
	"m1": {
		"name": "MẢNH CHUÔNG ĐÃ KÊU", "main": true, "giver": "say", "ender": "ngai", "after": [], "need": {"talk": "ngai"},
		"goal": "ĐỂ NGẢI LÊN DÂY MẢNH CHUÔNG",
		"offer": ["VẬY RA NGƯƠI LÀ ĐỨA NHỎ CỦA VÃN. MẢNH CHUÔNG TRONG NGỰC NGƯƠI KÊU ĐÊM QUA, PHẢI KHÔNG. NỬA CON PHỐ ĐÃ NGHE THẤY.", "ĐẾN CHỖ NGẢI NGOÀI SÂN TRẤN TRƯỚC KHI NÓ KÊU LẦN NỮA. MẢNH CHUÔNG LẠC DÂY LẤY ĐI NHIỀU HƠN NÓ CHO."],
		"wait": ["NGẢI. CON BÉ CẦM ÂM THOA, NGOÀI SÂN TRẤN."],
		"done": ["ĐỨNG YÊN. MẢNH CỦA BẠN NGÂN BỊ TRẦM. ... ĐƯỢC RỒI.", "BẠN CÓ NGHE THẤY KHÔNG? MẶT BẠN TRẮNG BỆCH. MỘT GIỌNG NÓI Ư? NÓ NÓI GÌ?", "... 'ĐỪNG ĐỂ HỌ BIẾT EM'... RỒI IM BẶT. NỬA CÂU. MÌNH XIN LỖI. MÌNH CHỈ LÊN DÂY ĐƯỢC THÔI, KHÔNG BẮT NÓ NÓI HẾT CÂU ĐƯỢC."],
		"gold": 0, "xp": 25, "potions": 1, "item": null,
	},
	"m2": {
		"name": "LAU KHÔ", "main": true, "giver": "say", "after": ["m1"], "need": {"kill": {"reed": 6}},
		"goal": "HẠ LAU ẢNH NGOÀI ĐẦM",
		"offer": ["NỬA CÂU CỦA VÃN. VẪN HƠN TA ĐƯỢC NỬA CÂU.", "MUỐN NGHE NỐT THÌ NGƯƠI PHẢI ĐI NƠI VÃN ĐÃ ĐI. CHỨNG TỎ NGƯƠI ĐI ĐƯỢC ĐÃ. LAU ẢNH ĐANG DÀY ĐẶC NGOÀI ĐẦM. HẠ SÁU CON."],
		"wait": ["SÁU LAU ẢNH. ĐẦM Ở PHÍA ĐÔNG, QUA CỔNG TRẤN. CHÚNG GIƠ TAY LÊN TRƯỚC KHI QUẤT. LÚC ĐÓ BƯỚC TRÁNH RA."],
		"done": ["TỐT. NGƯƠI VUNG KIẾM GIỐNG VÃN. CẦM LẤY CÁI ÁO NÀY. NÓ ĐƯỢC CẮT CHO MỘT KẺ NHẶT VỌNG KHÔNG BAO GIỜ QUAY VỀ LẤY."],
		"gold": 30, "xp": 60, "potions": 2, "item": ["armor", 0, 1],
	},
	"m3": {
		"name": "THỨ ĐẦM LẦY GIỮ LẠI", "main": true, "giver": "kham", "after": ["m2"], "need": {"loot": ["TRO VỌNG", 4, "heron"]},
		"goal": "GOM TRO VỌNG TỪ CÒ TRO",
		"offer": ["NGƯƠI MUỐN ĐI ĐƯỜNG RA BẾN PHÀ. AI MUỐN ĐI ĐƯỜNG ĐÓ CŨNG CẦN MỘT LƯỠI KIẾM CẮN ĐƯỢC DƯ ẢNH.", "MANG CHO TA BỐN NHÚM TRO VỌNG. LŨ CÒ BỜ ĐÔNG MANG NÓ TRONG NGƯỜI. TA SẼ TÔI CHO NGƯƠI THỨ TỐT HƠN CON DAO ĐÓ."],
		"wait": ["BỐN NHÚM TRO VỌNG, TỪ LŨ CÒ. CHÚNG PHUN THEO ĐƯỜNG THẲNG. CHÉM ĐÚNG LÚC LÀ GẠT ĐƯỢC."],
		"done": ["TRO MỊN. NHẠT MÀU. LŨ CHIM NÀY NHỚ NHIỀU THẬT.", "ĐÂY. VÀ KHI NGƯƠI GẶP THỨ GÌ TRONG BẾN PHÀ CÒN BIẾT TÊN MÌNH, HÃY NÓI CHO TA CÁI TÊN ĐÓ. TA SƯU TẦM TÊN. THÚ VUI CỦA LÃO GIÀ."],
		"gold": 20, "xp": 110, "potions": 1, "item": ["weapon", 1, 1],
	},
	"m4": {
		"name": "LẰN RANH CỦA GIÁM LẶNG", "main": true, "giver": "dien", "after": ["m2"], "need": {"kill": {"porter": 1}},
		"goal": "HẠ PHU PHÀ TRÊN ĐƯỜNG RA BẾN",
		"offer": ["BÀ CẢ SẬY ĐANG SAI NGƯƠI RA BẾN PHÀ. ĐỪNG CHỐI. TA KHÔNG CẢN NGƯƠI. TA SẼ DÙNG NGƯƠI.", "MỘT PHU PHÀ CHÌM ĐỨNG CHẮN ĐƯỜNG RA BẾN, PHÍA BẮC ĐẦU ĐÊ ĐÔNG. CÒN NÓ THÌ TA KHÔNG MANG NIÊM RA ĐƯỢC. HẠ NÓ ĐI."],
		"wait": ["PHU PHÀ. KIẾM CỦA NGƯƠI KHÔNG LÀM NÓ KHỰNG ĐƯỢC CHO TỚI KHI THẾ CỦA NÓ VỠ. ĐÁNH MẠNH, RỒI ĐÁNH NỮA."],
		"done": ["VẬY LÀ ĐƯỜNG ĐÃ THÔNG, CHO NGƯƠI VÀ CHO NIÊM CỦA TA. NGƯƠI CÓ MỘT CHUYẾN. SAU ĐÓ BẾN PHÀ ĐÓNG VĨNH VIỄN."],
		"gold": 60, "xp": 130, "potions": 2, "item": ["charm", 1, 1],
	},
	"m5": {
		"name": "BẾN PHÀ CŨ", "main": true, "giver": "say", "after": ["m3", "m4"], "need": {"see": ["van"], "kill": {"boss": 1}},
		"goal": "TÌM THỨ VÃN ĐỂ LẠI, KẾT THÚC CHUYẾN PHÀ",
		"offer": ["RẠNG SÁNG GIÁM LẶNG SẼ NIÊM BẾN PHÀ. Ả TƯỞNG TA KHÔNG BIẾT.", "HẦM VỌNG ĐÓ LẶP LẠI CÁI ĐÊM PHÀ CHÌM. VÃN ĐÃ BƯỚC VÀO ĐÊM ĐÓ MỘT MÌNH VÀ TA MUỐN BIẾT VÌ SAO. ĐI XEM TRƯỚC KHI NÓ BỊ ĐÓNG. NGƯỜI GÁC PHÀ SẼ KHÔNG ĐỂ NGƯƠI RA YÊN ỔN ĐÂU."],
		"wait": ["ĐƯỜNG RA BẾN CHẠY LÊN PHÍA BẮC TỪ ĐẦU ĐÊ ĐÔNG. ĐỪNG VÀO KHI ĐANG MỆT."],
		"done": ["NGƯƠI ĐÃ THẤY VÃN. ĐANG ĐỐT MỘT CUỐN SỔ. ... MỘT DANH SÁCH TÊN Ư?", "LÃO KHÂM GIỮ MỘT CUỐN SỔ CÓ BÌA Y NHƯ VẬY. TA NỢ TIỀN LÃO HAI MƯƠI NĂM MÀ CHƯA MỘT LẦN HỎI LÃO GHI GÌ TRONG ĐÓ.", "ĐỪNG NÓI GÌ VỚI LÃO. CHƯA PHẢI LÚC. ĐI ĐỂ NGẢI XEM MẢNH CHUÔNG CỦA NGƯƠI. NÓ CHƯA NGỪNG NGÂN TỪ LÚC NGƯƠI BƯỚC VÀO."],
		"gold": 150, "xp": 400, "potions": 3, "item": ["charm", 2, 2],
	},
	"m6": {
		"name": "HAI GIỌNG", "main": true, "giver": "say", "ender": "ngai", "after": ["m5"], "need": {"talk": "ngai"},
		"goal": "ĐỂ NGẢI XEM LẠI MẢNH CHUÔNG", "auto": true,
		"offer": [], "wait": ["NGẢI ĐANG ĐỢI NGƯƠI NGOÀI SÂN TRẤN."],
		"done": ["NÓ ĐANG KÊU TỪ MẶT TRONG. MÌNH KHÔNG BIẾT LÀ CHÚNG LÀM ĐƯỢC THẾ.", "CHUÔNG CÓ HAI MẶT. MỘT MẶT CHO TIẾNG GÕ, MỘT MẶT CHO TIẾNG NGÂN. MẢNH CỦA BẠN XƯA NAY CHỈ DÙNG MẶT ĐẦU. DƯ ÂM CỦA NGƯỜI GÁC PHÀ ĐÃ ĐÁNH THỨC MẶT KIA.", "NÓ MUỐN MỘT GIỌNG THỨ HAI. MỘT TAY NGHỀ THỨ HAI. ĐỨNG YÊN, MÌNH MỞ NÓ RA. ... ĐƯỢC RỒI. {2}. GIẤU KỸ VÀO. BỌN GIỮ LẶNG GIẾT NGƯỜI MANG HAI GIỌNG. ĐÓ LÀ ĐIỀU VÃN CỐ NÓI VỚI BẠN, PHẢI KHÔNG.", "'ĐỪNG ĐỂ HỌ BIẾT EM NGHE ĐƯỢC HAI TIẾNG.'"],
		"gold": 0, "xp": 200, "potions": 0, "item": null, "toast": "GIỌNG THỨ HAI THỨC DẬY. BẤM T ĐỂ MỞ CÂY KỸ NĂNG.",
	},
	"s1": {
		"name": "MÓN NỢ CỦA NGƯỜI CHẾT", "main": false, "giver": "say", "after": ["m2"], "need": {"see": ["widow"]}, "branch": "debt",
		"goal": "TÌM NGƯỜI VÁ LƯỚI BÊN XÁC THUYỀN",
		"offer": ["PHƯỜNG CHO MỘT NGƯỜI VÁ LƯỚI TÊN LỤA MƯỢN THUYỀN. THUYỀN GIỜ LÀ CÁI XÁC Ở ĐẦM NAM, CÒN LỤA ĐÃ CHẾT SÁU NĂM.", "DƯ ẢNH CỦA Ả VẪN NGỒI ĐÓ MÀ VÁ. NỢ LÀ NỢ. ĐI XEM CÒN THU ĐƯỢC GÌ."],
		"wait": ["XÁC THUYỀN, PHÍA NAM CON ĐÊ. Ả SẼ KHÔNG ĐÁNH NGƯƠI. CÁI KHÓ LÀ Ở CHỖ ĐÓ."],
		"done": [
			["NGƯƠI GẠCH NÓ KHỎI SỔ RỒI. ... HỪM. VÃN CŨNG SẼ LÀM THẾ, VÀ TA CŨNG SẼ MẮNG VÃN. ĐÂY. Ả NHỜ TA GIỮ THỨ NÀY CHO KẺ NÀO TỬ TẾ."],
			["TRẢ ĐỦ. Ả GIẤU TIỀN TRONG PHAO LƯỚI Ư. TỐT. PHƯỜNG CÓ CƠM ĂN MÙA ĐÔNG NÀY. ĐỪNG NHÌN TA NHƯ THẾ."],
		],
		"reward": [{"gold": 0, "xp": 120, "potions": 0, "item": ["charm", 1, 2]}, {"gold": 90, "xp": 60, "potions": 0, "item": null}],
	},
	"s2": {
		"name": "DÉP TRÊN ĐÊ", "main": false, "giver": "ngai", "after": ["m1"], "need": {"see": ["sandal_a", "sandal_b", "sandal_c"]},
		"goal": "TÌM DÉP BỎ LẠI VEN BỜ",
		"offer": ["KHI MỘT NGƯỜI NHẶT VỌNG BƯỚC VÀO HẦM, HỌ ĐỂ DÉP LẠI TRÊN BỜ, MŨI HƯỚNG RA NƯỚC. ĐỂ NGƯỜI NHÀ BIẾT HỌ VÀO HẦM NÀO.", "MÙA NÀY CÓ BA ĐÔI CHƯA AI NHẬN. BẠN TÌM GIÚP MÌNH ĐƯỢC KHÔNG? MÌNH GIỮ SỔ ĐẾM. PHẢI CÓ AI ĐÓ GIỮ CHỨ."],
		"wait": ["BA ĐÔI DÉP, ĐÂU ĐÓ DỌC BỜ ĐẦM."],
		"done": ["BA ĐÔI. VẬY LÀ KHÔNG AI TRONG SỐ HỌ QUAY VỀ LẤY DÉP.", "MỘT ĐÔI VỪA CỠ CHÂN VÃN, PHẢI KHÔNG. MÌNH CỐ Ý ĐỂ NÓ Ở ĐÓ. MÌNH KHÔNG MUỐN LÀ NGƯỜI DỜI NÓ ĐI."],
		"gold": 25, "xp": 90, "potions": 1, "item": ["armor", 1, 1],
	},
	"m7": {
		"name": "GÓC TRANG CHÁY DỞ", "main": true, "giver": "say", "ender": "reu", "after": ["m6"], "need": {"talk": "reu"},
		"goal": "TÌM LÃO RÊU Ở RỪNG THỞ",
		"offer": ["TRONG ĐÁM TRO Ở SÂN THU PHÍ CÒN SÓT MỘT GÓC TRANG. BA CHỮ THÔI: 'LÒNG CÂY GHI'.", "Ở RỪNG THỞ CÓ MỘT CÁI CÂY MANG TÊN ĐÓ. DÂN DÒNG VỌNG THÂN SỐNG QUANH NÓ. TÌM LÃO RÊU, TRƯỞNG LÃO CỦA HỌ. ĐƯỜNG VÀO RỪNG Ở CUỐI CON ĐÊ, PHÍA ĐÔNG."],
		"wait": ["CUỐI CON ĐÊ, PHÍA ĐÔNG. LÃO RÊU Ở LÀNG THÌ THẦM. ĐỪNG NÓI VỚI LÃO LÀ NGƯƠI QUEN GIÁM LẶNG."],
		"done": ["MỘT KẺ NGÂN TỪ TRẤN MÕ GỖ. MẢNH CHUÔNG CỦA CON ĐANG KÊU HAI GIỌNG. Ở ĐÂY KHÔNG AI GIẾT CON VÌ CHUYỆN ĐÓ.", "LÀNG NÀY CÓ HAI TRĂM NGƯỜI. KHÔNG AI TRONG SỐ HỌ CÒN SỐNG, VÀ KHÔNG AI TRONG SỐ HỌ BIẾT ĐIỀU ĐÓ. ĐI NHẸ CHÂN THÔI."],
		"gold": 0, "xp": 150, "potions": 2, "item": null,
	},
	"m8": {
		"name": "BẦY SÓI KÝ ỨC", "main": true, "giver": "reu", "after": ["m7"], "need": {"kill": {"wolf": 5}},
		"goal": "HẠ SÓI KÝ ỨC QUANH LÀNG",
		"offer": ["CON MUỐN VÀO LÒNG CÂY. CÂY KHÔNG MỞ CHO NGƯỜI LẠ. NHƯNG NÓ NHỚ AI ĐÃ GIÚP LÀNG.", "RỪNG ĐANG NHỚ QUÁ NHIỀU. NÓ NHỚ CẢ NHỮNG BẦY SÓI ĐÃ CHẾT TỪ ĐỜI ÔNG TA, VÀ CHÚNG ĐI SĂN LẠI. HẠ NĂM CON."],
		"wait": ["NĂM CON SÓI. CHÚNG ĐI BA CON MỘT, VÀ CẮN RẤT NHANH. ĐỪNG ĐỨNG YÊN."],
		"done": ["LŨ TRẺ LẠI RA SÂN CHƠI ĐƯỢC RỒI. CHÚNG CHƠI MÃI MỘT TRÒ SUỐT BỐN MƯƠI NĂM NAY. TA VẪN THÍCH NHÌN."],
		"gold": 80, "xp": 260, "potions": 2, "item": ["armor", 2, 1],
	},
	"m9": {
		"name": "HẠ LƯU", "main": true, "giver": "dien", "after": ["m7"], "need": {"kill": {"sower": 4, "deer": 2}},
		"goal": "DIỆT NGUỒN LAN VỌNG TRONG RỪNG",
		"offer": ["NGƯƠI ĐÃ VÀO RỪNG THỞ. ĐỪNG CHỐI, ÁO NGƯƠI CÒN DÍNH BÀO TỬ.", "BA LÀNG NGƯỜI SỐNG Ở HẠ LƯU ĐANG NGẤM VỌNG TỪ KHU RỪNG ĐÓ. ĐÃ CÓ HAI ĐỨA TRẺ LOẠN ÂM. KẺ GIEO BÀO TỬ VÀ HƯƠU RỖNG MANG NÓ ĐI XA NHẤT. HẠ BỐN KẺ GIEO, HAI CON HƯƠU."],
		"wait": ["BỐN KẺ GIEO BÀO TỬ, HAI HƯƠU RỖNG. ĐỪNG ĐỨNG TRONG ĐÁM BÀO TỬ. HƯƠU THÌ CHỈ LAO THẲNG, BƯỚC NGANG LÀ XONG."],
		"done": ["TỐT. HẠ LƯU SẼ CÓ THÊM VÀI TUẦN.", "LÃO RÊU SẼ NÓI VỚI NGƯƠI RẰNG NHỮNG THỨ TRONG LÀNG LÃO LÀ NGƯỜI. HÃY HỎI LÃO HAI ĐỨA TRẺ KIA LÀ GÌ."],
		"gold": 120, "xp": 300, "potions": 2, "item": ["weapon", 2, 1],
	},
	"m10": {
		"name": "LÒNG CÂY GHI NHỚ", "main": true, "giver": "reu", "after": ["m8", "m9"], "need": {"see": ["bell"], "kill": {"mother": 1}},
		"goal": "XEM ĐIỀU CÂY NHỚ, ĐỐI MẶT MẸ RỄ",
		"offer": ["CÂY ĐÃ CHỊU MỞ. NÓ LÀ THỨ GIÀ NHẤT CÒN NHỚ TIẾNG CHUÔNG MẸ. VÃN CỦA CON TỪNG ĐẾN ĐÂY HỎI NÓ MỘT CÂU, RỒI BỎ ĐI MÀ MẶT TRẮNG BỆCH.", "Ở GIỮA LÒNG CÂY LÀ MẸ RỄ NGÀN TÊN. BÀ ẤY GIỮ MỌI CÁI TÊN RỪNG CÒN NHỚ, VÀ BÀ ẤY KHÔNG CÒN PHÂN BIỆT ĐƯỢC KHÁCH VỚI KẺ TRỘM. TA XIN LỖI."],
		"wait": ["CỬA VÀO Ở CUỐI CON ĐƯỜNG RỪNG, PHÍA ĐÔNG, QUA CÂY CẦU RỄ."],
		"done": ["CON ĐÃ THẤY RỒI. MỖI TIẾNG CHUÔNG, MỘT CÁI TÊN BIẾN MẤT. CHUÔNG MẸ KHÔNG ĐƯA AI VỀ YÊN NGHỈ. NÓ XÓA HỌ.", "VÀ BÂY GIỜ MẸ RỄ ĐÃ LẶNG, RỪNG SẼ THÔI GIỮ TÊN. BÀ NHÀ TA... BÀ ẤY ĐANG NHẠT DẦN TỪ SÁNG. TA BIẾT CHUYỆN NÀY SẼ ĐẾN. TA VẪN ĐỂ CON ĐI.", "GIÁM LẶNG ĐÃ ĐẶT ĐÁ NIÊM Ở CỔNG LÀNG. Ả NÓI QUYỀN CHỌN LÀ CỦA KẺ ĐÃ MỞ LÒNG CÂY. LÀ CON."],
		"gold": 200, "xp": 600, "potions": 3, "item": ["charm", 2, 2],
	},
	"m11": {
		"name": "PHÁN QUYẾT", "main": true, "giver": "reu", "after": ["m10"], "need": {"see": ["verdict"]}, "branch": "village", "auto": true,
		"goal": "QUYẾT ĐỊNH SỐ PHẬN LÀNG THÌ THẦM Ở CỔNG LÀNG",
		"offer": [], "wait": ["ĐÁ NIÊM Ở CỔNG LÀNG. TA SẼ KHÔNG NÓI CON NÊN CHỌN GÌ. TA KHÔNG CÔNG BẰNG ĐƯỢC TRONG CHUYỆN NÀY."],
		"done": [
			["HAI TRĂM NGƯỜI. CON ĐÃ XÓA HAI TRĂM NGƯỜI, VÀ HẠ LƯU SẼ NGỦ YÊN. TA HIỂU PHÉP TÍNH ĐÓ. TA SẼ KHÔNG BAO GIỜ THA THỨ CHO NÓ.", "CẦM LẤY TIỀN CỦA HỘI GIỮ LẶNG RỒI ĐI ĐI."],
			["LÀNG CÒN ĐÓ. LŨ TRẺ VẪN CHƠI. BA LÀNG HẠ LƯU SẼ PHẢI DỜI ĐI, VÀ GIÁM LẶNG ĐÃ GHI TÊN CON VÀO SỔ.", "BÀ NHÀ TA VẪN ĐI RỒI. CÓ NHỮNG THỨ CON KHÔNG GIỮ ĐƯỢC DÙ CHỌN GÌ. NHƯNG CÁM ƠN CON."],
		],
		"reward": [{"gold": 300, "xp": 500, "potions": 0, "item": null}, {"gold": 0, "xp": 500, "potions": 0, "item": ["charm", 2, 2]}],
		"toast": "HẾT CHƯƠNG HAI",
	},
	"s3": {
		"name": "TÊN BỊ ĐỤC", "main": false, "giver": "man", "after": ["m7"], "need": {"see": ["trunk_a", "trunk_b", "trunk_c"]},
		"goal": "TÌM NHỮNG THÂN CÂY BỊ ĐỤC MẤT TÊN",
		"offer": ["CHÁU LÀ KHÁCH CỦA ÔNG NHÀ TÔI À. NGỒI ĐI. ... À, TÔI QUÊN, GHẾ KHÔNG CÒN NỮA.", "MỖI ĐỨA TRẺ SINH RA Ở ĐÂY ĐƯỢC KHẮC TÊN LÊN MỘT THÂN CÂY. CÓ BA THÂN CÂY BỊ AI ĐÓ ĐỤC MẤT TÊN. TÔI ĐẾM ĐI ĐẾM LẠI MÀ KHÔNG NHỚ RA LÀ CỦA ĐỨA NÀO. CHÁU TÌM GIÚP TÔI NHÉ."],
		"wait": ["BA THÂN CÂY, RẢI RÁC TRONG RỪNG. CHỖ BỊ ĐỤC LÚC NÀO CŨNG THẤP, NGANG TẦM TAY TRẺ CON."],
		"done": ["CẢ BA ĐỀU BỊ ĐỤC TỪ BÊN TRONG RA. KHÔNG PHẢI AI ĐÓ XÓA TÊN CHÚNG. LÀ CÂY TỰ QUÊN.", "CÁI CUỐI CÒN SÓT MỘT NÉT ĐẦU, CHÁU BẢO THẾ À? MỘT CHỮ N. ... TÔI TỪNG BIẾT MỘT CON BÉ HAY CẦM ÂM THOA GÕ VÀO MỌI THỨ. TÔI KHÔNG NHỚ TÊN NÓ NỮA."],
		"gold": 60, "xp": 220, "potions": 1, "item": ["charm", 2, 1],
	},
}

# ---------------------------------------------------------------- things to look at, and scenes
# Text shown when the hero examines a thing (E). `opts` turns the last line into a choice that sets a flag.

const THINGS = {
	"stone_set": {"name": "ĐÁ NIÊM", "lines": ["PHIẾN ĐÁ NIÊM NẰM YÊN GIỮA CỔNG. ĐÁ ẤM, NHƯ VỪA CÓ AI NGỒI LÊN."]},
	"stone_down": {"name": "ĐÁ NIÊM", "lines": ["PHIẾN ĐÁ NIÊM NẰM ÚP MẶT XUỐNG ĐẤT, CHỖ BẠN ĐỂ NÓ. RÊU ĐÃ BẮT ĐẦU MỌC LÊN LƯNG ĐÁ."]},
	"yard_empty": {"name": "SÂN LÀNG", "lines": ["SÂN LÀNG TRỐNG. MỘT QUẢ CẦU MÂY CÒN NẰM GIỮA SÂN, KHÔNG AI ĐÁ.", "TRÊN NỀN ĐẤT CÒN VẠCH Ô CHƠI NHẢY LÒ CÒ. MƯA CHƯA KỊP XÓA."]},
	"yard_play": {"name": "SÂN LÀNG", "lines": ["LŨ TRẺ CHƠI NHẢY LÒ CÒ. ĐỨA NÀO CŨNG NHẢY TỚI Ô THỨ BẢY RỒI DỪNG, RỒI BẮT ĐẦU LẠI.", "CHÚNG ĐÃ CHƠI VÁN NÀY BỐN MƯƠI NĂM. CHÚNG VẪN CƯỜI Ở ĐÚNG CHỖ ĐÓ."]},
	"silence_notice": {"name": "CÁO THỊ CỦA HỘI GIỮ LẶNG", "lines": ["'LÀNG THÌ THẦM ĐÃ ĐƯỢC NIÊM. HẠ LƯU AN TOÀN. HỘI CẢM TẠ NGƯỜI NHẶT VỌNG ĐÃ GIÚP.'", "AI ĐÓ ĐÃ LẤY THAN VIẾT THÊM BÊN DƯỚI: 'HAI TRĂM.'"]},
	"refugee_cart": {"name": "XE CỦA NGƯỜI HẠ LƯU", "lines": ["MỘT CHIẾC XE CHẤT ĐẦY NỒI NIÊU, CHĂN MÀN VÀ MỘT CÁI LỒNG GÀ RỖNG.", "TRÊN THÀNH XE CÓ KHẮC TÊN BA LÀNG. MỘT CÁI TÊN ĐÃ BỊ GẠCH, RỒI VIẾT LẠI."]},
	"clapper": {"name": "MÕ TRẤN", "lines": ["MỘT CON CÁ GỖ, GÕ CHO MỖI CANH GIỜ VÀ MỖI LẦN BÁO ĐỘNG. Ở ĐÂY NGƯỜI TA KHÔNG ƯA CHUÔNG.", "AI TRONG TRẤN CŨNG ĐẾN LƯỢT GÕ. AI CŨNG GÕ, TRỪ THẦY KHÂM."]},
	"grave": {"name": "BIA MỘ", "lines": ["'VÃN. BA NĂM.' HOA CÒN TƯƠI. BÊN DƯỚI KHÔNG CÓ THI THỂ NÀO."]},
	"shrine": {"name": "MIẾU VEN ĐƯỜNG", "lines": ["MỘT NGỌN NẾN CHO NHỮNG NGƯỜI ĐẦM LẦY GIỮ LẠI. AI ĐÓ ĐÃ KHẮC MỘT HÀNG TÊN LÊN GỖ, RỒI CẠO ĐI MỘT CÁI."]},
	"well": {"name": "GIẾNG", "lines": ["NƯỚC TRONG. DÂY GÀU CÒN MỚI. SỢI CŨ ĐÃ ĐƯỢC DÙNG ĐỂ KÉO MỘT THỨ KHÁC LÊN, BA NĂM TRƯỚC."]},
	"sign": {"name": "BIỂN CHỈ ĐƯỜNG", "lines": ["TÂY: TRẤN MÕ GỖ. BẮC, QUA ĐẦU ĐÊ ĐÔNG: BẾN PHÀ CŨ. AI ĐÓ ĐÃ ĐÓNG MỘT TẤM NIÊM CỦA HỘI GIỮ LẶNG NGANG DÒNG THỨ HAI."]},
	"sandal_a": {"name": "MỘT ĐÔI DÉP", "lines": ["XẾP NGAY NGẮN, MŨI HƯỚNG RA NƯỚC. NHỎ. QUAI ĐƯỢC VÁ BẰNG DÂY CÂU."]},
	"sandal_b": {"name": "MỘT ĐÔI DÉP", "lines": ["MŨI HƯỚNG RA NƯỚC. MỖI CHIẾC ĐƯỢC CHẶN MỘT VIÊN SỎI ĐỂ GIÓ KHÔNG CUỐN ĐI."]},
	"sandal_c": {"name": "MỘT ĐÔI DÉP", "lines": ["MŨI HƯỚNG RA NƯỚC. MÒN THỦNG Ở GÓT TRÁI, ĐÚNG KIỂU VÃN HAY ĐI."]},
	"widow": {
		"name": "DƯ ẢNH CỦA LỤA", "lines": ["MỘT CÁI BÓNG NGỒI BÊN XÁC THUYỀN, VÁ MỘT TẤM LƯỚI KHÔNG CÓ Ở ĐÓ. Ả KHÔNG NGẨNG LÊN.", "'SẮP XONG RỒI. NÓI VỚI BÀ CẢ SẬY LÀ CÓ MẺ CÁ THÌ TÔI TRẢ TIỀN. SẮP XONG RỒI.'", "NHỮNG CÁI PHAO LƯỚI BÊN CẠNH Ả LÀ THẬT, VÀ NẶNG TRĨU TIỀN XU."],
		"opts": ["NÓI RẰNG NỢ ĐÃ TRẢ XONG", "LẤY SỐ TIỀN XU"], "flag": "debt",
		"after": [["Ả NGỪNG VÁ. LẦN ĐẦU TIÊN SAU SÁU NĂM, ĐÔI TAY Ả YÊN LẶNG. RỒI CHỈ CÒN LẠI CON THUYỀN."], ["BẠN NHẤC NHỮNG CÁI PHAO LÊN. Ả VẪN VÁ. 'SẮP XONG RỒI,' Ả NÓI, CHẲNG VỚI AI CẢ."]],
	},
	"trunk_a": {"name": "THÂN CÂY KHẮC TÊN", "lines": ["VỎ CÂY BỊ ĐỤC MẤT MỘT MẢNG, THẤP, NGANG TẦM TAY MỘT ĐỨA TRẺ. VẾT ĐỤC CÒN MỚI HƠN CÁI CÂY CẢ TRĂM NĂM."]},
	"trunk_b": {"name": "THÂN CÂY KHẮC TÊN", "lines": ["LẠI MỘT CÁI TÊN BỊ ĐỤC, CŨNG Ở ĐỘ CAO ẤY. THỚ GỖ QUANH VẾT ĐỤC LỒI RA NGOÀI, NHƯ THỂ NÓ BỊ ĐẨY TỪ BÊN TRONG."]},
	"trunk_c": {"name": "THÂN CÂY KHẮC TÊN", "lines": ["CÁI TÊN THỨ BA. LẦN NÀY CÒN SÓT LẠI NÉT ĐẦU TIÊN: MỘT CHỮ N."]},
	"verdict": {
		"name": "ĐÁ NIÊM CỦA HỘI GIỮ LẶNG", "quest": "m11",
		"lines": ["MỘT PHIẾN ĐÁ NIÊM ĐẶT GIỮA CỔNG LÀNG. ĐẶT TAY LÊN, LÀNG THÌ THẦM SẼ IM. HAI TRĂM DƯ ẢNH, CÓ CẢ LŨ TRẺ ĐANG CHƠI NGOÀI SÂN, SẼ TAN.", "ĐỂ YÊN, VỌNG TỪ LÀNG TIẾP TỤC NGẤM XUỐNG BA LÀNG NGƯỜI SỐNG Ở HẠ LƯU. ĐÃ CÓ HAI ĐỨA TRẺ LOẠN ÂM.", "KHÔNG CÓ CÁCH THỨ BA."],
		"opts": ["NIÊM LÀNG", "GIỮ LÀNG"], "flag": "village",
		"after": [["BẠN ĐẶT TAY LÊN ĐÁ. TIẾNG TRẺ CON NGOÀI SÂN TẮT GIỮA CHỪNG MỘT CÂU HÁT. RỪNG RẤT YÊN."], ["BẠN LẬT ÚP PHIẾN ĐÁ XUỐNG ĐẤT. NGOÀI SÂN, LŨ TRẺ VẪN CHƠI TRÒ CHÚNG ĐÃ CHƠI BỐN MƯƠI NĂM."]],
	},
}

const SCENES = {
	"van": {
		"name": "DƯ ẢNH CỦA VÃN", "tex": "h_idle", "quest": "m5",
		"lines": ["KHÔNG KHÍ ĐẶC LẠI. CÓ AI ĐÓ ĐANG QUỲ BÊN MỘT LÒ THAN GIỮA SÂN THU PHÍ. BẠN NHẬN RA ĐÔI VAI ẤY.", "LÀ VÃN. LÀ CÁI ĐÊM VÃN CHẾT, VÀ NÓ ĐANG DIỄN RA LẦN NỮA.", "VÃN KHÔNG NHẶT VỌNG. VÃN ĐANG XÉ TỪNG TRANG CỦA MỘT CUỐN SỔ VÀ THẢ VÀO LỬA.", "'KHÔNG PHẢI TRANG NÀY. KHÔNG PHẢI CÁI TÊN NÀY. NẾU LÃO HỎI, CUỐN SỔ ĐÃ CHÌM THEO CON PHÀ.'", "VÃN NGẨNG LÊN, NHÌN XUYÊN QUA BẠN, VỀ PHÍA BOONG PHÀ. MỘT NGỌN ĐÈN ĐANG TỚI GẦN. DƯ ẢNH TAN RA NHƯ TRO."],
	},
	"bell": {
		"name": "ĐIỀU CÂY NHỚ", "tex": "", "quest": "m10",
		"lines": ["NHỮNG VÒNG GỖ QUANH BẠN SÁNG LÊN. CÁI CÂY ĐANG NHỚ, VÀ BẠN ĐỨNG GIỮA TRÍ NHỚ CỦA NÓ.", "BA TRĂM NĂM TRƯỚC. MỘT TIẾNG CHUÔNG LĂN QUA RỪNG. TRÊN MỌI THÂN CÂY, MỘT CÁI TÊN MỜ ĐI RỒI BIẾN MẤT, NHƯ CHƯA TỪNG ĐƯỢC KHẮC.", "MỘT NGƯỜI MẸ ĐỨNG TRƯỚC THÂN CÂY CỦA CON MÌNH, TAY SỜ LÊN LỚP VỎ NHẴN. BÀ KHÔNG KHÓC. BÀ KHÔNG NHỚ MÌNH TỪNG CÓ CON.", "SÁCH DẠY RẰNG CHUÔNG MẸ ĐƯA NGƯỜI CHẾT VỀ NƠI YÊN NGHỈ. CÁI CÂY NHỚ KHÁC. KHÔNG AI ĐƯỢC ĐƯA ĐI ĐÂU CẢ. HỌ BỊ XÓA.", "TIẾNG CHUÔNG CUỐI CÙNG TRONG TRÍ NHỚ CỦA CÂY BỊ CẮT NGANG. ĐÊM RẠN. TỪ ĐÓ, KHÔNG CÁI TÊN NÀO BIẾN MẤT NỮA. Ở GIỮA LÒNG CÂY, CÓ THỨ GÌ ĐÓ CỰA MÌNH."],
	},
}

# One line per finished main quest, shown in the journal. A list is picked by that quest's choice.
const RECAP = {
	"m1": "MẢNH CHUÔNG CỦA VÃN KÊU LẦN ĐẦU. NGẢI LÊN DÂY NÓ VÀ BẠN NGHE ĐƯỢC NỬA CÂU: 'ĐỪNG ĐỂ HỌ BIẾT EM...'",
	"m2": "BẠN HẠ SÁU LAU ẢNH ĐỂ CHỨNG TỎ MÌNH ĐI ĐƯỢC NƠI VÃN ĐÃ ĐI.",
	"m3": "THẦY KHÂM TÔI CHO BẠN MỘT MÓN VŨ KHÍ, VÀ DẶN MANG VỀ TÊN CỦA NHỮNG THỨ CÒN NHỚ TÊN MÌNH.",
	"m4": "BẠN DỌN ĐƯỜNG RA BẾN PHÀ CHO GIÁM LẶNG TỐ DIÊN. Ả SẼ NIÊM NÓ SAU CHUYẾN CỦA BẠN.",
	"m5": "TRONG BẾN PHÀ CŨ, DƯ ẢNH CỦA VÃN ĐỐT MỘT CUỐN SỔ GHI TÊN. NGƯỜI GÁC PHÀ ĐÃ NGÃ.",
	"m6": "MẢNH CHUÔNG MỞ MẶT THỨ HAI. TRỌN CÂU CỦA VÃN: 'ĐỪNG ĐỂ HỌ BIẾT EM NGHE ĐƯỢC HAI TIẾNG.'",
	"m7": "MỘT GÓC TRANG CHÁY DỞ DẪN BẠN TỚI LÀNG THÌ THẦM, NƠI HAI TRĂM DƯ ẢNH SỐNG NHƯ NGƯỜI.",
	"m8": "BẠN ĐUỔI BẦY SÓI KÝ ỨC KHỎI LÀNG.",
	"m9": "TỐ DIÊN CHO BẠN THẤY MẶT KIA CỦA CHUYỆN: VỌNG TỪ LÀNG ĐANG NGẤM XUỐNG BA LÀNG HẠ LƯU.",
	"m10": "CÁI CÂY NHỚ RẰNG MỖI TIẾNG CHUÔNG XÓA ĐI MỘT CÁI TÊN. CHUÔNG MẸ KHÔNG ĐƯA AI VỀ YÊN NGHỈ. MẸ RỄ ĐÃ LẶNG.",
	"m11": ["BẠN ĐÃ NIÊM LÀNG THÌ THẦM. HẠ LƯU NGỦ YÊN. LÃO RÊU KHÔNG THA THỨ.", "BẠN ĐÃ GIỮ LÀNG THÌ THẦM. HẠ LƯU PHẢI DỜI ĐI. TÊN BẠN NẰM TRONG SỔ CỦA HỘI GIỮ LẶNG."],
}

# a bow shoots instead of swinging. Every bow base name starts with CUNG.
static func is_bow(it) -> bool:
	return it != null and it.slot == "weapon" and it.uniq == "" and it.name.begins_with("CUNG")

# ---------------------------------------------------------------- after the verdict (m11)
# What the people say once chapter two is over, by flags.village: [0] the village was sealed, [1] it was kept.
const AFTER_CHAT = {
	"say": [["HỘI GIỮ LẶNG GỬI TIỀN TỚI TRẤN, KÈM MỘT LÁ THƯ KHEN. TA ĐỐT LÁ THƯ, GIỮ TIỀN. NGƯƠI NÊN BIẾT TA LÀ NGƯỜI NHƯ THẾ."],
		["BA LÀNG HẠ LƯU ĐANG DỜI LÊN ĐÂY. TRẤN CHẬT RỒI, CHẬT NỮA CŨNG ĐƯỢC. NGƯƠI ĐÃ CHỌN THÌ NGƯƠI PHỤ TA DỰNG LỀU."]],
	"ngai": [["MẢNH CHUÔNG CỦA BẠN NGÂN THẤP HƠN TỪ HÔM ĐÓ. NHƯ THỂ NÓ BỚT ĐI HAI TRĂM GIỌNG.", "MÌNH KHÔNG TRÁCH BẠN. MÌNH CHỈ KHÔNG LÊN DÂY ĐƯỢC CHỖ ĐÓ NỮA."],
		["MẢNH CHUÔNG CỦA BẠN ỒN HƠN TỪ HÔM ĐÓ. NHƯ CÓ LŨ TRẺ CHẠY QUA CHẠY LẠI TRONG NÓ.", "MÌNH THÍCH TIẾNG ĐÓ. ĐỪNG NÓI VỚI GIÁM LẶNG LÀ MÌNH THÍCH."]],
	"kham": [["TA ĐÃ GHI HAI TRĂM CÁI TÊN VÀO SỔ, TRƯỚC KHI CHÚNG TAN. KHÔNG AI BẢO TA LÀM. TA SƯU TẦM TÊN, NHỚ CHỨ."],
		["LÀNG ĐÓ CÒN, NÊN TÊN CHÚNG KHÔNG CẦN TA GIỮ. TA THẤY NHẸ NGƯỜI MỘT CÁCH LẠ LÙNG."]],
	"dien": [["SỔ CỦA HỘI GHI NGƯƠI LÀ NGƯỜI BIẾT TÍNH. TA KHÔNG CHẮC ĐÓ LÀ LỜI KHEN.", "LẦN SAU HỘI GỌI, NGƯƠI SẼ ĐƯỢC GỌI TRƯỚC."],
		["SỔ CỦA HỘI GHI TÊN NGƯƠI Ở TRANG KHÁC. TRANG CỦA NHỮNG KẺ PHẢI ĐỂ MẮT TỚI.", "TA KHÔNG BẮT NGƯƠI. CHƯA. HẠ LƯU SẼ TÍNH SỔ BẰNG NƯỚC LŨ, KHÔNG PHẢI BẰNG TA."]],
	"reu": [["TA VẪN NGỒI ĐÂY MỖI CHIỀU. SÂN TRỐNG THÌ NGHE RÕ TIẾNG LÁ HƠN. TA GHÉT CÁI RÕ ĐÓ."],
		["LŨ TRẺ VẪN HỎI BÀ NHÀ TA ĐÂU. TA BẢO BÀ ĐI CHỢ. BỐN MƯƠI NĂM RỒI, BÀ ĐI CHỢ LÂU THẬT."]],
	"man": [["..."], ["CHÁU LẠI TỚI À. NGỒI ĐI. ... À, TÔI QUÊN, GHẾ KHÔNG CÒN NỮA. CHÁU CÓ THẤY ÔNG NHÀ TÔI CƯỜI KHÔNG? DẠO NÀY ÔNG CƯỜI."]],
}
