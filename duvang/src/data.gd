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
	# chapter three. "ai" borrows the way another foe fights.
	"crab": {"name": "CUA MUỐI", "hp": 110.0, "spd": 34.0, "r": 12.0, "poise": 35.0, "range": 44.0, "wind": 0.8, "rec": 1.0, "dmg": 22.0, "cd": 1.0, "xp": 70, "gold": [8, 16], "aggro": 130.0, "loot": 0.5, "ai": "porter"},
	"gull": {"name": "HẢI ÂU TRO", "hp": 32.0, "spd": 96.0, "r": 7.0, "poise": 0.0, "range": 80.0, "wind": 0.4, "rec": 0.7, "dmg": 14.0, "cd": 1.3, "xp": 34, "gold": [3, 8], "aggro": 160.0, "loot": 0.16, "ai": "leech"},
	"diver": {"name": "THỢ LẶN CHÌM", "hp": 60.0, "spd": 40.0, "r": 8.0, "poise": 0.0, "range": 140.0, "wind": 0.9, "rec": 0.8, "dmg": 15.0, "cd": 3.2, "xp": 48, "gold": [5, 12], "aggro": 170.0, "loot": 0.24, "ai": "sower"},
	"admiral": {"name": "ĐÔ ĐỐC SẢNH MUỐI", "hp": 1500.0, "spd": 40.0, "r": 18.0, "poise": 110.0, "range": 70.0, "wind": 0.8, "rec": 0.9, "dmg": 26.0, "cd": 0.7, "xp": 1400, "gold": [300, 420], "aggro": 270.0, "loot": 1.0, "big": true, "ai": "boss", "summon": "diver", "call_text": "THỦY THỦ CHÌM NGHE LỆNH ĐÔ ĐỐC."},
	# chapter four
	"slag": {"name": "NGƯỜI XỈ", "hp": 160.0, "spd": 40.0, "r": 13.0, "poise": 45.0, "range": 150.0, "wind": 1.0, "rec": 1.5, "dmg": 30.0, "cd": 1.8, "xp": 160, "gold": [14, 26], "aggro": 180.0, "loot": 0.8, "ai": "deer"},
	"smith": {"name": "THỢ RÈN VỌNG", "hp": 60.0, "spd": 80.0, "r": 8.0, "poise": 0.0, "range": 32.0, "wind": 0.4, "rec": 0.5, "dmg": 18.0, "cd": 0.9, "xp": 60, "gold": [5, 12], "aggro": 150.0, "loot": 0.2, "ai": "wolf"},
	"moth": {"name": "BƯỚM ĐỒNG", "hp": 40.0, "spd": 52.0, "r": 7.0, "poise": 0.0, "range": 140.0, "wind": 0.8, "rec": 0.6, "dmg": 12.0, "cd": 2.6, "xp": 50, "gold": [4, 10], "aggro": 170.0, "loot": 0.22, "ai": "wisp"},
	"forgemaster": {"name": "TỔNG THỢ CẢ BẠCH LÔ", "hp": 1300.0, "spd": 38.0, "r": 17.0, "poise": 100.0, "range": 60.0, "wind": 0.8, "rec": 0.9, "dmg": 30.0, "cd": 0.8, "xp": 2000, "gold": [400, 520], "aggro": 260.0, "loot": 1.0, "big": true, "ai": "keeper", "summon": "smith", "heal_text": "LÒ RÈN ĐỎ LẠI"},
	"mold": {"name": "KHUÔN SỐNG", "hp": 1400.0, "spd": 0.0, "r": 26.0, "poise": 140.0, "range": 80.0, "wind": 1.0, "rec": 1.0, "dmg": 30.0, "cd": 1.0, "xp": 2000, "gold": [300, 400], "aggro": 240.0, "loot": 1.0, "big": true, "fixed": true, "ai": "mother", "summon": "smith", "call_text": "KHUÔN SỐNG GỌI NHỮNG TIẾNG ĐÃ NUỐT.", "cloud": Color("e8862e")},
	# chapter five
	"scribe": {"name": "THƯ LẠI CHÉP", "hp": 70.0, "spd": 52.0, "r": 7.0, "poise": 0.0, "range": 160.0, "wind": 0.7, "rec": 0.5, "dmg": 20.0, "cd": 2.0, "xp": 90, "gold": [8, 16], "aggro": 180.0, "loot": 0.22, "ai": "heron"},
	"guard": {"name": "CẤM VỆ KIM", "hp": 200.0, "spd": 32.0, "r": 14.0, "poise": 55.0, "range": 48.0, "wind": 0.9, "rec": 1.1, "dmg": 40.0, "cd": 0.9, "xp": 220, "gold": [18, 30], "aggro": 140.0, "loot": 0.9, "ai": "porter"},
	"censer": {"name": "LƯ HƯƠNG SỐNG", "hp": 80.0, "spd": 44.0, "r": 8.0, "poise": 0.0, "range": 130.0, "wind": 0.9, "rec": 0.7, "dmg": 16.0, "cd": 3.0, "xp": 90, "gold": [8, 16], "aggro": 170.0, "loot": 0.24, "ai": "netter"},
	"okhab": {"name": "Ô KHA, NGƯỜI ĐÚC CHUÔNG", "hp": 1800.0, "spd": 46.0, "r": 16.0, "poise": 120.0, "range": 70.0, "wind": 0.8, "rec": 0.9, "dmg": 34.0, "cd": 0.7, "xp": 4000, "gold": [600, 800], "aggro": 280.0, "loot": 1.0, "big": true, "ai": "boss", "summon": "scribe", "call_text": "THƯ LẠI CHÉP LẠI LỆNH CỦA Ô KHA."},
	"first": {"name": "TIẾNG ĐẦU TIÊN", "hp": 2200.0, "spd": 0.0, "r": 30.0, "poise": 160.0, "range": 90.0, "wind": 1.0, "rec": 1.0, "dmg": 36.0, "cd": 0.9, "xp": 6000, "gold": [800, 1000], "aggro": 300.0, "loot": 1.0, "big": true, "fixed": true, "ai": "mother", "summon": "scribe", "call_text": "TIẾNG ĐẦU TIÊN GỌI NHỮNG NGƯỜI NÓ ĐÃ XAY.", "cloud": Color("f0d060")},
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
const SLOT_NAME = {"weapon": "VŨ KHÍ", "armor": "GIÁP", "charm": "BÙA", "rune": "ĐÁ ÂM"}
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
	if it.slot == "rune":
		return "it_r_" + it.rune
	if it.uniq != "":
		return "it_u_" + it.uniq
	var list = BASES[it.slot]
	for i in list.size():
		if it.name.begins_with(list[i][0]):
			return "it_%s%d" % [it.slot[0], i]
	return "ic_" + (it.slot if it.slot != "rune" else "charm")

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
	"salt": "ĐÒN CHÍ MẠNG LÀM KẺ ĐỊCH LẠNH",
	"forge": "ĐÒN CUỐI CHUỖI ĐỂ LẠI CHÁY",
	"eight": "DÙNG TUYỆT KỸ: HỒI 8% MÁU VÀ 8 NỘ",
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
	"vanh": {"name": "CHỊ VÀNH", "tex": "npc_vanh"},
	"buyer": {"name": "LẠC, NGƯỜI MUA CỦA LÒ ĐÚC", "tex": "npc_buyer"},
	"than": {"name": "BÁC THAN", "tex": "npc_than"},
	"okha": {"name": "Ô KHA, NGƯỜI ĐÚC CHUÔNG", "tex": "npc_okha"},
	"kimyen": {"name": "KIM YẾN", "tex": "npc_kimyen"},
	"archivist": {"name": "BÀ GIỮ SỬ", "tex": "npc_archivist"},
}

const INTRO = [
	"BA TRĂM MƯỜI HAI NĂM TRƯỚC, CHUÔNG MẸ NỨT VÀ RƠI. TỪ ĐÊM ẤY, KÝ ỨC CỦA NGƯỜI CHẾT KHÔNG CÒN TAN ĐI. NÓ LẮNG XUỐNG, NHƯ TRO.",
	"NƠI NÀO NÓ LẮNG DÀY, NƠI ẤY LẶP LẠI MÃI GIỜ KHẮC CUỐI CỦA MÌNH. NGƯỜI TA GỌI ĐÓ LÀ HẦM VỌNG, VÀ GỌI NHỮNG THỨ ĐI LẠI TRONG ĐÓ LÀ DƯ ẢNH.",
	"VÃN, NGƯỜI NUÔI BẠN LỚN, BƯỚC VÀO BẾN PHÀ CŨ BA NĂM TRƯỚC VÀ KHÔNG TRỞ RA. KHÔNG AI BIẾT VÌ SAO VÃN ĐI MỘT MÌNH.",
	"TRONG NGỰC BẠN CÓ MỘT MẢNH CHUÔNG. NÓ TỪNG LÀ CỦA VÃN. ĐÊM QUA, LẦN ĐẦU TIÊN, NÓ KÊU.",
]

# What each person says when they have no quest business with you. Indexed by main quests finished.
const CHAT = {
	"kimyen": [
		["TRIỀU TÀN KIM KHÔNG TÀN. NÓ CHỈ CHỜ. TA LÀ CÁI NÓ CHỜ."],
		["TA ĐẾM NẾP NHĂN MỖI SÁNG. HÔM NAY THÊM BA. NGƯƠI BIẾT KHÔNG, NÓ CŨNG KHÔNG ĐÁNG SỢ NHƯ TA TƯỞNG."],
	],
	"archivist": [
		["ĐỪNG CHẠM VÀO GIÁ SÁCH. CHÚNG NHỚ AI ĐÃ CHẠM."],
		["TA ĐÃ CHÉP CHUYỆN CỦA NGƯƠI. KẾT THÚC THẾ NÀO THÌ TA CHƯA BIẾT. TA ĐỂ TRỐNG MỘT TRANG."],
	],
	"than": [
		["NGƯỜI TA GỌI ĐÂY LÀ DÃY MỎ CÂM VÌ TRONG HẦM KHÔNG AI ĐƯỢC NÓI TO. ĐÁ NGHE. ĐÁ NHỚ."],
		["LÒ SẬP RỒI MÀ TRONG HẦM VẪN CÒN TIẾNG BÚA. KHÔNG PHẢI NGƯỜI CỦA TA. TA KHÔNG XUỐNG XEM."],
	],
	"okha": [
		["NGỒI ĐI. TRÀ CÒN NÓNG. TA KHÔNG ĐẦU ĐỘC KHÁCH. TA CẦN KHÁCH SỐNG."],
		["TA VẪN ĐÚC TIẾP. LÒ SẬP MỘT NỬA THÌ ĐÚC BẰNG NỬA CÒN LẠI. NGƯƠI SẼ GẶP LẠI TA Ở MIỆNG CHUÔNG."],
	],
	"vanh": [
		["NGƯỜI TA BẢO PHƯỜNG ĐÀO MỒ. CHÚNG TÔI ĐÀO ĐỒNG. MỒ THÌ NGƯỜI TA ĐÃ ĐÀO HỘ CHÚNG TÔI TỪ BA TRĂM NĂM TRƯỚC."],
		["HẠM ĐỘI VẪN NẰM ĐÓ. TÔI VẪN ĐÀO. CÓ NHỮNG NGÀY TÔI TỰ HỎI MÌNH ĐANG LẤY ĐỒNG HAY ĐANG LẤY NGƯỜI."],
	],
	"buyer": [
		["LÒ ĐÚC KHÔNG HỎI ĐỒNG TỪ ĐÂU RA. LÒ ĐÚC CHỈ CÂN. TÔI CŨNG CHỈ CÂN."],
		["Ô KHA ĐANG MUA MỌI TIẾNG NGƯỜI TA BÁN. CÔ NÊN BIẾT ĐIỀU ĐÓ TRƯỚC KHI CÓ AI BÁN TIẾNG CỦA CÔ."],
	],
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

const ORDER = ["m1", "m2", "m3", "m4", "m5", "m6", "m7", "m8", "m9", "m10", "m11", "m12", "m13", "m14", "m15", "m16", "m17", "m18", "m19", "m20", "m21", "m22", "m23", "m24", "m25", "m26", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10"]

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
	# ---------------- chapter three: the Silver Salt Sea
	"m12": {
		"name": "BIỂN KHÔNG NƯỚC", "main": true, "giver": "kham", "ender": "vanh", "after": ["m11"], "need": {"talk": "vanh"},
		"goal": "TÌM CHỊ VÀNH Ở TRẠI CỦA PHƯỜNG, BIỂN MUỐI NGÂN",
		"offer": ["NGƯƠI VỀ RỒI. NGƯƠI MANG VỀ CHO TA BAO NHIÊU TIẾNG RỒI NHỈ? TA ĐẾM CẢ ĐẤY. TA SƯU TẦM MÀ.", "PHÍA NAM ĐẦM LAU CÓ MỘT CÁI BIỂN ĐÃ CẠN TỪ ĐỜI ÔNG CỐ TA. MỘT HẠM ĐỘI MẮC CẠN Ở ĐÓ, TỪNG CHỞ 'HÀNG CỦA CHUÔNG' VỀ KINH. TA MUỐN BIẾT HÀNG ĐÓ LÀ GÌ.", "TÌM CHỊ VÀNH Ở TRẠI CỦA PHƯỜNG. NÓI LÀ LÃO KHÂM GỬI."],
		"wait": ["BIỂN MUỐI NGÂN. ĐI XUỐNG CON ĐÊ Ở BỜ NAM ĐẦM LAU."],
		"done": ["LÃO KHÂM GỬI À. LÃO VẪN CÒN SỐNG, VẪN CÒN SƯU TẦM. TỐT.", "Ở ĐÂY PHƯỜNG ĐÀO XÁC TÀU LẤY ĐỒNG. MỖI CÂN ĐỒNG LÒ ĐÚC TRẢ MỘT ĐỒNG BẠC. MỖI MẢNH CHUÔNG, LÒ ĐÚC TRẢ GẤP BA.", "CẨN THẬN CÁI THỨ TRONG NGỰC CÔ. Ở ĐÂY NGƯỜI TA ĐÃ BẮT ĐẦU BÁN MẢNH CỦA NGƯỜI THÂN."],
		"gold": 50, "xp": 700, "potions": 1, "item": null,
	},
	"m13": {
		"name": "ĐỒNG TRONG MUỐI", "main": true, "giver": "vanh", "after": ["m12"], "need": {"kill": {"crab": 6}},
		"goal": "HẠ CUA MUỐI QUANH ĐÁM XÁC TÀU",
		"offer": ["LŨ CUA MUỐI ĐÓNG Ổ TRONG MẤY THÂN TÀU. CHÚNG ĂN ĐINH ĐỒNG, VÀ THÁNG NÀY CHÚNG KẸP GÃY TAY BA THỢ CỦA TÔI.", "HẠ SÁU CON. TÔI SẼ CHO CÔ ĐI CÙNG CHUYẾN ĐÀO KẾ TIẾP."],
		"wait": ["SÁU CON CUA MUỐI QUANH ĐÁM XÁC TÀU. CHÚNG GIƠ CÀNG LÊN TRƯỚC KHI ĐẬP. LÚC ĐÓ LÙI RA."],
		"done": ["SÁU CÁI CÀNG. ĐỦ ĐỔI BA BỮA CƠM CHO CẢ TRẠI.", "CÒN ĐÂY LÀ PHẦN CỦA CÔ. ĐỪNG HỎI NÓ ĐÀO TỪ XÁC NGƯỜI NÀO RA."],
		"gold": 80, "xp": 900, "potions": 2, "item": ["weapon", 2, 1],
	},
	"m14": {
		"name": "THẺ HÀNG", "main": true, "giver": "buyer", "after": ["m13"], "need": {"loot": ["THẺ HÀNG", 4, "diver"]},
		"goal": "LẤY THẺ HÀNG TỪ THỢ LẶN CHÌM",
		"offer": ["NGƯỜI NHẶT VỌNG. LÒ ĐÚC TRẢ GẤP BA CHO MẢNH CHUÔNG. CÔ KHÔNG BÁN À. TIẾC THẬT.", "VẬY THÌ LÀM VIỆC CHO TÔI. LŨ THỢ LẶN CHÌM VẪN ĐEO THẺ HÀNG CỦA HẠM ĐỘI. MANG CHO TÔI BỐN CÁI. LÒ ĐÚC MUỐN BIẾT TÀU NÀO CHỞ CÁI GÌ."],
		"wait": ["BỐN THẺ HÀNG. LŨ THỢ LẶN Ở QUANH CÁC VŨNG NƯỚC MẶN. CHÚNG NÉM MUỐI. ĐỪNG ĐỨNG TRONG ĐÁM MUỐI."],
		"done": ["CẢ BỐN THẺ ĐỀU GHI MỘT CHỖ: 'KỲ HẠM. HẦM HAI. HÀNG CỦA CHUÔNG. KHÔNG MỞ.'", "LÒ ĐÚC SẼ TRẢ CÔ ĐỦ. VÀ NẾU CÔ VÀO ĐƯỢC KỲ HẠM, LÒ ĐÚC SẼ TRẢ GẤP BA CHO CUỐN SỔ HÀNG."],
		"gold": 150, "xp": 1000, "potions": 1, "item": ["charm", 2, 1],
	},
	"m15": {
		"name": "SỔ HÀNG", "main": true, "giver": "vanh", "after": ["m14"], "need": {"see": ["manifest"], "kill": {"admiral": 1}},
		"goal": "ĐỌC SỔ HÀNG TRONG HẠM ĐỘI MẮC CẠN, HẠ ĐÔ ĐỐC",
		"offer": ["LẠC NÓI VỚI CÔ RỒI À. CUỐN SỔ HÀNG Ở TRÊN KỲ HẠM. ĐÔ ĐỐC VẪN CÒN Ở ĐÓ, VẪN ĐI TUẦN TRÊN BOONG NHƯ CHƯA AI BÁO CHO ÔNG TA LÀ HẠM ĐỘI ĐÃ CHẾT.", "CHỒNG TÔI MẤT Ở HẦM HAI. ANH ẤY CHỈ XUỐNG LẤY MỘT CÁI ĐINH. NẾU CÔ ĐỌC ĐƯỢC CUỐN SỔ, ĐỌC CHO TÔI NGHE ANH ẤY CHẾT VÌ CÁI GÌ."],
		"wait": ["LỐI XUỐNG HẠM ĐỘI Ở CUỐI CON ĐƯỜNG VÁN, PHÍA NAM BÃI MUỐI."],
		"done": ["VỌNG TINH. KÝ ỨC NGƯỜI CHẾT, NGHIỀN RA, ĐÓNG HÒM, CHỞ VỀ KINH. HẠM ĐỘI NÀY CHỞ NGƯỜI CHẾT ĐI BÁN.", "VẬY LÀ ANH ẤY CHẾT VÌ MỘT HÒM NGƯỜI CHẾT KHÁC. ... CÔ VỀ TRẤN ĐI. LÃO KHÂM CẦN NGHE CHUYỆN NÀY. VÀ CÔ CẦN NGHE LÃO NÓI GÌ."],
		"gold": 300, "xp": 1800, "potions": 3, "item": null,
	},
	"m16": {
		"name": "NGƯỜI SƯU TẦM TIẾNG", "main": true, "giver": "vanh", "ender": "ngai", "after": ["m15"], "need": {"talk": "ngai"},
		"goal": "VỀ TRẤN MÕ GỖ, KỂ CHO THẦY KHÂM",
		"offer": ["CÔ ĐI ĐI. TÔI Ở LẠI ĐÀO TIẾP. KHÔNG CÒN CÁCH NÀO KHÁC ĐỂ CÓ CƠM."],
		"wait": ["VỀ TRẤN. NẾU KHÔNG THẤY LÃO KHÂM, HỎI CON BÉ CẦM ÂM THOA."],
		"done": ["THẦY KHÂM ĐI RỒI. ĐÊM QUA. THẦY MANG THEO CÁI HÒM GỖ, CÁI HÒM ĐỰNG MỌI TIẾNG BẠN MANG VỀ TỪ ĐẦU. CẢ BẢN SAO TIẾNG VÃN.", "THẦY ĐỂ LẠI MỘT DÒNG: 'Ô KHA TRẢ GIÁ CAO NHẤT. NGƯỜI SƯU TẦM CŨNG PHẢI ĂN.' ... THẦY NUÔI MÌNH TỪ NĂM MÌNH LÊN BA.", "VÀ Ô KHA GIỜ BIẾT MẢNH CỦA BẠN NGÂN HAI TIẾNG. TỪ GIỜ MÌNH SẼ LÊN DÂY MẢNH CHO BẠN, VÀ BÁN ĐỒ NỮA. MÌNH KHÔNG GIỎI MẶC CẢ BẰNG THẦY. NHƯNG MÌNH Ở LẠI."],
		"gold": 0, "xp": 1200, "potions": 2, "item": ["weapon", 2, 2],
		"toast": "HẾT CHƯƠNG BA",
	},
	"s4": {
		"name": "TÊN TRÊN MỎ NEO", "main": false, "giver": "vanh", "after": ["m13"], "need": {"see": ["marker_a", "marker_b", "marker_c"]},
		"goal": "CẠO MUỐI KHỎI BA MỎ NEO CỦA PHƯỜNG",
		"offer": ["THỢ CỦA PHƯỜNG CHẾT NGOÀI BÃI, CHÚNG TÔI CẮM MỘT MỎ NEO VÀ KHẮC TÊN LÊN ĐÓ. BA CÁI NEO GẦN ĐÂY ĐÃ BỊ MUỐI PHỦ KÍN.", "CÔ CẠO MUỐI ĐI GIÚP TÔI. TÔI KHÔNG MUỐN TÊN HỌ BỊ QUÊN NHƯ HÀNG TRONG HẦM."],
		"wait": ["BA MỎ NEO: MỘT PHÍA TÂY, MỘT PHÍA ĐÔNG, MỘT GẦN LỐI XUỐNG HẠM ĐỘI."],
		"done": ["BA CÁI TÊN. MỘT CÁI LÀ CỦA CHỒNG TÔI. TÔI BIẾT MÀ. TÔI CHỈ MUỐN NGHE AI ĐÓ ĐỌC NÓ LÊN.", "CẦM LẤY. ANH ẤY KHÔNG CẦN NỮA."],
		"gold": 100, "xp": 800, "potions": 1, "item": ["armor", 2, 2],
	},
	# ---------------- chapter four: the Mute Mines
	"m17": {
		"name": "DÃY MỎ CÂM", "main": true, "giver": "ngai", "ender": "than", "after": ["m16"], "need": {"talk": "than"},
		"goal": "TỚI LÀNG THỢ Ở DÃY MỎ CÂM, GẶP BÁC THAN",
		"offer": ["LẠC GỬI THƯ VỀ. THẦY KHÂM ĐÃ GIAO CÁI HÒM CHO Ô KHA Ở LÒ TÁI THANH, TRÊN DÃY MỎ CÂM. TIẾNG VÃN ĐANG Ở ĐÓ.", "MÌNH KHÔNG ĐI ĐƯỢC. MÌNH PHẢI TRÔNG CỬA HÀNG. NHƯNG MÌNH SẼ LÊN DÂY MẢNH CHO BẠN TRƯỚC KHI ĐI. ĐỨNG YÊN.", "ĐI QUA BIỂN MUỐI, THEO CON ĐƯỜNG VÁN VỀ PHÍA ĐÔNG. Ở LÀNG THỢ, HỎI BÁC THAN."],
		"wait": ["DÃY MỎ CÂM Ở CUỐI CON ĐƯỜNG VÁN, PHÍA ĐÔNG BIỂN MUỐI. BÁC THAN LÀ TRƯỞNG THỢ."],
		"done": ["NGƯỜI CỦA NGẢI À. CON BÉ ĐÓ TỪNG Ở ĐÂY HỒI CÒN NHỎ XÍU. THẦY KHÂM MANG NÓ XUỐNG NÚI. TA KHÔNG BAO GIỜ HỎI TỪ ĐÂU RA.", "NGƯƠI MUỐN VÀO LÒ. CẢ DÃY NÚI NÀY SỐNG NHỜ CÁI LÒ ĐÓ. KHÔNG CÓ LÒ THÌ MÙA ĐÔNG NÀY CẢ LÀNG CHẾT RÉT.", "NÊN ĐỪNG MONG AI Ở ĐÂY GIÚP NGƯƠI. NHƯNG NẾU NGƯƠI GIÚP LÀNG TRƯỚC, TA SẼ NÓI CHO NGƯƠI CỬA NÀO KHÔNG KHÓA."],
		"gold": 80, "xp": 2000, "potions": 1, "item": null,
	},
	"m18": {
		"name": "BÁT CƠM CỦA LÒ", "main": true, "giver": "than", "after": ["m17"], "need": {"kill": {"slag": 5}},
		"goal": "HẠ NGƯỜI XỈ QUANH CÁC ĐỐNG XỈ",
		"offer": ["TỪ KHI HAI PHE KÉO QUÂN TỚI TRƯỚC CỔNG LÒ, KHÔNG AI ĐƯỢC CHỞ XỈ RA NỮA. XỈ CHẤT ĐỐNG, VÀ VỌNG TRONG XỈ ĐỨNG DẬY.", "NĂM CON NGƯỜI XỈ ĐANG LẢNG VẢNG GẦN LÀNG. CHÚNG CÚI XUỐNG RỒI LAO THẲNG. ĐỪNG ĐỨNG TRÊN ĐƯỜNG CHÚNG LAO."],
		"wait": ["NĂM NGƯỜI XỈ, Ở CÁC ĐỐNG XỈ PHÍA NAM. CHÚNG LAO THEO ĐƯỜNG THẲNG. BƯỚC SANG BÊN."],
		"done": ["NĂM ĐỐNG XỈ NẰM YÊN. LŨ TRẺ LẠI DÁM RA NHẶT THAN VỤN.", "TA HỨA RỒI. CỬA PHỤ PHÍA ĐÔNG LÒ KHÔNG KHÓA. NHƯNG TRƯỚC CỔNG CÓ HAI ĐẠO QUÂN, VÀ CẢ HAI ĐỀU MUỐN NGƯƠI ĐỨNG VỀ PHÍA MÌNH."],
		"gold": 160, "xp": 2600, "potions": 2, "item": ["armor", 2, 2],
	},
	"m19": {
		"name": "HAI PHE TRƯỚC CỔNG", "main": true, "giver": "dien", "after": ["m18"], "need": {"see": ["standoff"], "kill": {"smith": 6}},
		"goal": "GẶP TỐ DIÊN TRƯỚC CỔNG LÒ, DẸP THỢ RÈN VỌNG Ở CÁC CỬA HẦM",
		"offer": ["NGƯƠI TỚI ĐÚNG LÚC. HỘI GIỮ LẶNG MUỐN NIÊM CẢ CÁI LÒ. DÒNG VỌNG THÂN MUỐN 'GIẢI THOÁT' MỌI TIẾNG TRONG ĐÓ. HAI BÊN CÁCH NHAU MỘT CON ĐƯỜNG XE.", "NẾU MỘT MŨI TÊN BAY, THỢ MỎ SẼ ĐỨNG GIỮA. RA XEM ĐI. RỒI DẸP LŨ THỢ RÈN VỌNG Ở CÁC CỬA HẦM PHÍA BẮC. CHÚNG ĐANG CHỌC CẢ HAI BÊN NỔI ĐIÊN."],
		"wait": ["ĐỨNG GIỮA HAI TRẠI MỘT LÚC. RỒI SÁU THỢ RÈN VỌNG Ở CÁC CỬA HẦM PHÍA BẮC."],
		"done": ["KHÔNG AI BẮN. LẦN NÀY.", "VÀ CÓ CHUYỆN LẠ: Ô KHA GỬI NGƯỜI RA MỜI NGƯƠI VÀO LÒ. KHÔNG PHẢI MỜI ĐÁNH. MỜI LÀM KHÁCH. TA KHÔNG BIẾT LÃO MUỐN GÌ. TA KHÔNG THÍCH KHÔNG BIẾT."],
		"gold": 200, "xp": 3000, "potions": 2, "item": ["charm", 2, 2],
	},
	"m20": {
		"name": "NGƯỜI ĐÚC CHUÔNG", "main": true, "giver": "dien", "ender": "okha", "after": ["m19"], "need": {"see": ["ledger"]},
		"goal": "VÀO LÒ TÁI THANH LÀM KHÁCH CỦA Ô KHA",
		"offer": ["ĐI ĐI. NẾU LÃO ĐỊNH GIẾT NGƯƠI, LÃO ĐÃ KHÔNG CẦN MỜI.", "VÀ NGHE CHO KỸ. LÃO LÀ NGƯỜI DUY NHẤT CÒN SỐNG BIẾT CHUÔNG MẸ ĐƯỢC ĐÚC RA ĐỂ LÀM GÌ."],
		"wait": ["CỔNG LÒ Ở CUỐI CON ĐƯỜNG XE, PHÍA ĐÔNG, SAU HAI TRẠI."],
		"done": ["TA ĐÃ NÓI HẾT. TA KHÔNG CẦN NGƯƠI ĐỒNG Ý. TA CHỈ CẦN NGƯƠI HIỂU RẰNG TA KHÔNG NÓI DỐI.", "TIẾNG CỦA VÃN Ở DƯỚI HỐ ĐÚC. BẠCH LÔ ĐANG GIỮ NÓ ĐỂ THỬ KHUÔN. TA SẼ KHÔNG CẢN NGƯƠI. BẠCH LÔ THÌ CÓ."],
		"gold": 0, "xp": 3200, "potions": 3, "item": null,
	},
	"m21": {
		"name": "LÒ TÁI THANH", "main": true, "giver": "okha", "ender": "dien", "after": ["m20"], "need": {"kill": {"forgemaster": 1, "mold": 1}},
		"goal": "LẤY LẠI TIẾNG VÃN TỪ HỐ ĐÚC",
		"offer": ["ĐI XUỐNG HỐ ĐÚC. BẠCH LÔ ĐÃ ĐÚC CHUÔNG CHO TA BỐN MƯƠI NĂM. ÔNG ẤY SẼ KHÔNG ĐỂ AI LẤY ĐI THỨ ĐANG NUÔI KHUÔN.", "VÀ KHI NGƯƠI ĐỨNG TRƯỚC KHUÔN SỐNG, HÃY NHỚ: NÓ KHÔNG ÁC. NÓ CHỈ ĐÓI."],
		"wait": ["HỐ ĐÚC Ở CUỐI LÒ, SAU HÀNH LANG ỐNG BỄ."],
		"done": ["NGƯƠI CÒN SỐNG. TỐT. NGƯƠI NGHE THẤY TIẾNG NỔ CHỨ? NỬA CÁI LÒ ĐÃ SẬP. LÀNG THỢ MẤT LÒ SƯỞI GIỮA MÙA TUYẾT. ĐÓ LÀ VIỆC NGƯƠI LÀM. TA CHỈ NÓI ĐỂ NGƯƠI KHÔNG GIẢ VỜ LÀ KHÔNG.", "CÒN TA... KHI LÒ NỔ, TA DÙNG MẢNH CHUÔNG CỦA HỘI ĐỂ GIỮ ĐÁ KHÔNG ĐÈ QUÂN TA. HỘI GỌI ĐÓ LÀ DÙNG VỌNG. SÁNG MAI TA KHÔNG CÒN LÀ GIÁM LẶNG NỮA.", "ĐỪNG NHÌN TA NHƯ THẾ. TA CỨU ĐƯỢC BA MƯƠI NGƯỜI. LÀM LẠI TA VẪN LÀM THẾ."],
		"gold": 500, "xp": 5000, "potions": 3, "item": null,
		"toast": "HẾT CHƯƠNG BỐN",
	},
	"s5": {
		"name": "LÒ SƯỞI CHO LÀNG", "main": false, "giver": "than", "after": ["m21"], "need": {"loot": ["THAN ẤM", 5, "slag"]},
		"goal": "GOM THAN ẤM TỪ NGƯỜI XỈ CHO LÒ SƯỞI CỦA LÀNG",
		"offer": ["LÒ SẬP RỒI. TA KHÔNG TRÁCH NGƯƠI. TA CŨNG KHÔNG CẢM ƠN NGƯƠI.", "LŨ NGƯỜI XỈ CÒN GIỮ LỬA TRONG BỤNG. MANG CHO TA NĂM CỤC THAN ẤM, LÒ SƯỞI CỦA LÀNG SẼ CHÁY QUA MÙA ĐÔNG."],
		"wait": ["NĂM CỤC THAN ẤM, TỪ NGƯỜI XỈ."],
		"done": ["LÒ SƯỞI CHÁY LẠI RỒI. LŨ TRẺ NGỦ ĐƯỢC.", "NGƯƠI LÀM SẬP MỘT CÁI LÒ VÀ THẮP LẠI MỘT CÁI LÒ. TA KHÔNG BIẾT CỘNG TRỪ THẾ NÀO. CẦM LẤY CÁI NÀY."],
		"gold": 150, "xp": 2400, "potions": 2, "item": ["weapon", 2, 2],
	},
	# ---------------- chapter five: the First Toll
	"m22": {
		"name": "KINH THÀNH KIM THƯỢNG", "main": true, "giver": "dien", "ender": "kimyen", "after": ["m21"], "need": {"talk": "kimyen"},
		"goal": "LÊN KINH THÀNH KIM THƯỢNG, GẶP KIM YẾN",
		"offer": ["TA KHÔNG CÒN LÀ GIÁM LẶNG. NHƯNG TA VẪN CÒN TAI. Ô KHA ĐÃ LÊN KINH, MANG THEO CÁI CHUÔNG ĐÚC DỞ.", "MIỆNG CHUÔNG LÀ CÁI HỐ GIỮA KINH THÀNH KIM THƯỢNG, CHỖ CHUÔNG MẸ RƠI XUỐNG. LÃO SẼ TREO CHUÔNG MỚI Ở ĐÓ. ĐI QUA ĐÈO PHÍA BẮC DÃY MỎ.", "Ở KINH CÓ MỘT NGƯỜI NGƯƠI PHẢI GẶP: KIM YẾN, NGƯỜI CUỐI CÙNG CỦA TRIỀU TÀN KIM. CÔ TA TRẢ TIỀN CHO Ô KHA. VÀ KHINH ÔNG TA."],
		"wait": ["ĐÈO PHÍA BẮC DÃY MỎ CÂM. KIM YẾN Ở TRƯỚC BẬC THỀM CUNG ĐIỆN."],
		"done": ["NGƯỜI NHẶT VỌNG. NGƯƠI TỚI ĐỂ NGĂN Ô KHA À. TA CŨNG VẬY. TA ĐÃ MỞ CỔNG KINH CHO LÃO, VÀ TA HỐI HẬN TỪ ĐÊM ĐẦU.", "NHÌN TAY TA ĐI. BA TRĂM MƯỜI NĂM TA KHÔNG GIÀ MỘT NGÀY. TỪ KHI HẠM ĐỘI KHÔNG VỀ, MỖI THÁNG TA GIÀ MỘT NĂM.", "TA CẦN CHUÔNG ĐÓ XAY LẠI. NGƯƠI CẦN NÓ IM. CHÚNG TA ĐI CÙNG NHAU MỘT ĐOẠN, CHO TỚI KHI KHÔNG ĐI CÙNG ĐƯỢC NỮA."],
		"gold": 200, "xp": 6000, "potions": 2, "item": null,
	},
	"m23": {
		"name": "NHỮNG KẺ CHÉP LẠI", "main": true, "giver": "kimyen", "after": ["m22"], "need": {"kill": {"scribe": 6}},
		"goal": "HẠ THƯ LẠI CHÉP TRÊN PHỐ KINH",
		"offer": ["DƯ ẢNH CỦA BỌN THƯ LẠI ĐANG ĐI KHẮP PHỐ, CHÉP ĐI CHÉP LẠI NHỮNG TỜ CHIẾU KHÔNG AI ĐỌC. MỰC CỦA CHÚNG BỎNG NHƯ VÔI.", "HẠ SÁU ĐỨA. TA CẦN ĐƯỜNG VÀO ĐIỆN CHÉP SỬ. Ở ĐÓ CÓ BẢN CHÉP CỦA MỌI CUỐN SỔ TỪNG BỊ ĐỐT TRONG NƯỚC NÀY."],
		"wait": ["SÁU THƯ LẠI. CHÚNG VẨY MỰC THEO ĐƯỜNG THẲNG. BƯỚC SANG BÊN."],
		"done": ["PHỐ IM RỒI. TA THÍCH PHỐ IM.", "ĐIỆN CHÉP SỬ Ở PHÍA TÂY BẮC. BÀ GIỮ SỬ VẪN CÒN TRONG ĐÓ. BÀ ẤY GIỮ CẢ NHỮNG THỨ TA RA LỆNH ĐỐT."],
		"gold": 250, "xp": 7000, "potions": 2, "item": ["armor", 2, 2],
	},
	"m24": {
		"name": "BẢN CHÉP CUỐN SỔ CHÁY", "main": true, "giver": "kimyen", "ender": "kham", "after": ["m23"], "need": {"see": ["list"]},
		"goal": "TÌM BẢN CHÉP CUỐN SỔ VÃN ĐÃ ĐỐT, TRONG ĐIỆN CHÉP SỬ",
		"offer": ["VÀO ĐIỆN, TÌM BẢN CHÉP CUỐN SỔ VÃN ĐÃ ĐỐT. TA BIẾT VÃN. VÃN TỪNG LÀM VIỆC CHO TA TRƯỚC KHI LÀM VIỆC CHO LÃO KHÂM.", "VÀ NẾU NGƯƠI GẶP KHÂM TRONG ĐÓ, ĐỪNG NGẠC NHIÊN. LÃO TỚI KINH CÙNG Ô KHA, RỒI BỊ BỎ LẠI NHƯ MỘT CÁI HÒM RỖNG."],
		"wait": ["ĐIỆN CHÉP SỬ, PHÍA TÂY BẮC. BẢN CHÉP Ở PHÒNG ĐỌC."],
		"done": ["NGƯƠI ĐỌC RỒI. DANH SÁCH CỦA VÃN. VÃN LẬP NÓ CHO TA: NHỮNG KẺ NGHE ĐƯỢC HAI TIẾNG. TA MUA TIẾNG CỦA HỌ. TA BÁN CHO Ô KHA.", "CÁI TÊN CUỐI CÙNG LÀ NGƯƠI. VÃN ĐỐT CUỐN SỔ ĐỂ TA KHÔNG ĐỌC ĐƯỢC TÊN ĐÓ. VÃN CHẾT VÌ GIẤU NGƯƠI KHỎI TA.", "CON GÁI TA ĐANG PHAI. Ô KHA HỨA CHỪA RIÊNG NÓ KHỎI CỐI XAY. LÃO NÓI DỐI. TA BIẾT LÃO NÓI DỐI. TA VẪN BÁN.", "NGƯƠI MUỐN LÀM GÌ VỚI TA THÌ LÀM. NHƯNG XUỐNG HỐ TRƯỚC ĐÃ. LÃO SẮP TREO CHUÔNG."],
		"gold": 0, "xp": 7500, "potions": 3, "item": null,
	},
	"m25": {
		"name": "MIỆNG CHUÔNG", "main": true, "giver": "kham", "ender": "kimyen", "after": ["m24"], "need": {"kill": {"okhab": 1, "first": 1}},
		"goal": "XUỐNG TẦNG LƯỠI CHUÔNG, NGĂN Ô KHA TREO CHUÔNG",
		"offer": ["CẦU THANG XUỐNG TẦNG LƯỠI CHUÔNG Ở CUỐI ĐIỆN NÀY. NGÀY XƯA THƯ LẠI DÙNG NÓ ĐỂ GHI NHỮNG TIẾNG CHUÔNG CUỐI.", "Ô KHA Ở DƯỚI ĐÓ. VÀ KHI NGƯƠI XUỐNG, KIM YẾN SẼ ĐEM QUÂN VÂY MIỆNG HỐ. CÔ TA KHÔNG MUỐN CHUÔNG IM. CÔ TA MUỐN CÁI CỐI XAY CỦA RIÊNG MÌNH."],
		"wait": ["XUỐNG CẦU THANG Ở CUỐI ĐIỆN CHÉP SỬ."],
		"done": ["TA ĐÃ ĐEM QUÂN XUỐNG. TA ĐÃ ĐỊNH CƯỚP NÓ KHỎI TAY NGƯƠI. RỒI TIẾNG ĐẦU TIÊN IM, VÀ QUÂN CỦA TA CHỈ ĐỨNG ĐÓ, NHƯ NGƯỜI VỪA TỈNH NGỦ.", "KHÔNG CÒN VỌNG TINH NÀO NỮA. TA SẼ GIÀ NHƯ MỌI NGƯỜI. CÓ LẼ CHẾT TRƯỚC MÙA XUÂN.", "Ô KHA BƯỚC VÀO LÀM QUẢ LẮC KHI NGƯƠI TỪ CHỐI LÃO. LÃO KHÔNG OÁN AI. PHÉP TÍNH CỦA LÃO VẪN CÒN ĐÓ, CHƯA AI GIẢI.", "VỀ ĐI. NGƯƠI CÒN MỘT TIẾNG PHẢI QUYẾT. CON BÉ CẦM ÂM THOA ĐANG ĐỢI NGƯƠI Ở TRẤN."],
		"gold": 800, "xp": 12000, "potions": 3, "item": ["weapon", 2, 2],
	},
	"m26": {
		"name": "TIẾNG CỦA VÃN", "main": true, "giver": "ngai", "after": ["m25"], "need": {"see": ["voice"]}, "branch": "van", "auto": true,
		"goal": "QUYẾT ĐỊNH TIẾNG VÃN, RỒI VỀ GẶP NGẢI",
		"offer": [], "wait": ["BẠN ĐÃ QUYẾT CHƯA? MÌNH KHÔNG HỎI LÀ GÌ. MÌNH CHỈ HỎI LÀ ĐÃ CHƯA."],
		"done": [
			["MẢNH CỦA BẠN IM RỒI. MÌNH LÊN DÂY MÃI MÀ NÓ KHÔNG NGÂN NỮA.", "VÃN ĐI RỒI. LẦN NÀY LÀ ĐI THẬT, KHÔNG PHẢI CHÌM THEO CON PHÀ. BẠN VẪN ĐÁNH ĐƯỢC NHƯ CŨ. TAY NGHỀ LÀ CỦA BẠN, KHÔNG PHẢI CỦA VÃN."],
			["MẢNH CỦA BẠN VẪN NGÂN. MỎNG HƠN. MỖI TRẬN NÓ SẼ MỎNG HƠN NỮA.", "BẠN GIỮ VÃN LẠI. MÌNH HIỂU. MÌNH CŨNG MUỐN GIỮ THẦY KHÂM LẠI, DÙ THẦY LÀ NGƯỜI NHƯ THẾ."],
		],
		"reward": [{"gold": 0, "xp": 6000, "potions": 3, "item": ["charm", 2, 2]}, {"gold": 0, "xp": 6000, "potions": 3, "item": ["charm", 2, 2]}],
		"toast": "HẾT CHƯƠNG NĂM",
	},
	# ---------------- side chain: the Debts of the Dead (Bà Cả Sậy). Each debtor is an echo still trying to pay.
	# A choice at each: forgive the debt (flag 0) or collect it (flag 1). The last debtor is Bà Cả Sậy, and the creditor is Vãn.
	"s6": {
		"name": "SỔ NỢ: NGƯỜI THỢ GỐM", "main": false, "giver": "say", "after": ["m2"], "need": {"see": ["debt_potter"]}, "branch": "debt1",
		"goal": "ĐÒI NỢ NGƯỜI THỢ GỐM Ở ĐẦM LAU",
		"offer": ["PHƯỜNG CÓ MỘT CUỐN SỔ NỢ. CON NỢ TRONG ĐÓ CHẾT GẦN HẾT RỒI. CHẾT KHÔNG CÓ NGHĨA LÀ HẾT NỢ.", "NGƯỜI THỢ GỐM Ở BỜ TÂY ĐẦM LAU NỢ PHƯỜNG MƯỜI LẠNG. DƯ ẢNH CỦA Y VẪN NUNG BÌNH NGOÀI ĐÓ. ĐI ĐÒI. HOẶC ĐỪNG ĐÒI. TA MUỐN BIẾT NGƯƠI LÀ NGƯỜI THẾ NÀO."],
		"wait": ["NGƯỜI THỢ GỐM, BỜ TÂY ĐẦM LAU. Y KHÔNG BIẾT MÌNH ĐÃ CHẾT. ĐỪNG NÓI VỚI Y NẾU KHÔNG CẦN."],
		"done": [["XÓA À. ĐƯỢC. TA GẠCH TÊN Y. SỔ NHẸ ĐI MỘT DÒNG, KÉT CỦA PHƯỜNG CŨNG NHẸ ĐI MƯỜI LẠNG."], ["THU À. ĐƯỢC. MƯỜI LẠNG, ĐÚNG SỐ. NGƯƠI CẦM LẤY MỘT PHẦN. ĐÒI NỢ NGƯỜI CHẾT CŨNG LÀ MỘT NGHỀ."]],
		"reward": [{"gold": 0, "xp": 120, "potions": 1, "item": null}, {"gold": 60, "xp": 80, "potions": 0, "item": null}],
	},
	"s7": {
		"name": "SỔ NỢ: NGƯỜI MẸ ĐẾM TIỀN", "main": false, "giver": "say", "after": ["s6", "m5"], "need": {"see": ["debt_mother"]}, "branch": "debt2",
		"goal": "ĐÒI NỢ NGƯỜI MẸ Ở CHỢ CHÌM, BẾN PHÀ CŨ",
		"offer": ["DÒNG THỨ HAI. MỘT NGƯỜI MẸ Ở CHỢ CHÌM TRONG BẾN PHÀ. BÀ VAY ĐỂ MUA THUỐC CHO CON.", "BÀ VẪN NGỒI ĐẾM TIỀN TRONG CÁI TÚI ĐÓ. ĐẾM ĐI ĐẾM LẠI. LẦN NÀO CŨNG THIẾU MỘT ĐỒNG."],
		"wait": ["CHỢ CHÌM, GIỮA BẾN PHÀ CŨ. BÀ NGỒI CẠNH ĐỐNG THÙNG."],
		"done": [["NGƯƠI ĐỂ BÀ ẤY GIỮ CÁI TÚI. TA KHÔNG NÓI NGƯƠI SAI."], ["NGƯƠI LẤY CÁI TÚI. BÀ ẤY CÓ CẢM ƠN NGƯƠI KHÔNG? DƯ ẢNH HAY CẢM ƠN KẺ LẤY ĐI THỨ HỌ KHÔNG BỎ XUỐNG ĐƯỢC."]],
		"reward": [{"gold": 0, "xp": 300, "potions": 1, "item": null}, {"gold": 120, "xp": 200, "potions": 0, "item": null}],
	},
	"s8": {
		"name": "SỔ NỢ: NGƯỜI LÁI ĐÒ", "main": false, "giver": "say", "after": ["s7", "m7"], "need": {"see": ["debt_ferry"]}, "branch": "debt3",
		"goal": "ĐÒI NỢ NGƯỜI LÁI ĐÒ Ở RỪNG THỞ",
		"offer": ["DÒNG THỨ BA. MỘT NGƯỜI LÁI ĐÒ CHẠY LÊN RỪNG THỞ TRỐN NỢ, RỒI CHẾT Ở ĐÓ. RỪNG GIỮ Y LẠI.", "Y NỢ PHƯỜNG MỘT CON ĐÒ. Y VẪN ĐANG ĐẼO MỘT CON ĐÒ MỚI BÊN VŨNG NƯỚC PHÍA NAM ĐƯỜNG RỪNG."],
		"wait": ["VŨNG NƯỚC PHÍA NAM ĐƯỜNG RỪNG. Y ĐẼO GỖ, KHÔNG NGẨNG LÊN."],
		"done": [["NGƯƠI ĐỂ Y ĐẼO TIẾP. CON ĐÒ ĐÓ SẼ KHÔNG BAO GIỜ XONG. CÓ LẼ Y CŨNG KHÔNG MUỐN NÓ XONG."], ["NGƯƠI MANG VỀ CÁI MÁI CHÈO Y ĐẼO DỞ. TA SẼ TREO NÓ LÊN TƯỜNG. NỢ LÀ NỢ."]],
		"reward": [{"gold": 0, "xp": 700, "potions": 2, "item": null}, {"gold": 220, "xp": 500, "potions": 0, "item": ["weapon", 2, 1]}],
	},
	"s9": {
		"name": "SỔ NỢ: NGƯỜI THỢ LẶN", "main": false, "giver": "say", "after": ["s8", "m13"], "need": {"see": ["debt_diver"]}, "branch": "debt4",
		"goal": "ĐÒI NỢ NGƯỜI THỢ LẶN Ở BIỂN MUỐI NGÂN",
		"offer": ["DÒNG THỨ TƯ. MỘT THỢ LẶN CỦA PHƯỜNG VAY TIỀN MUA MŨ ĐỒNG, RỒI XUỐNG HẦM TÀU VÀ KHÔNG LÊN NỮA.", "Y VẪN NGỒI TRÊN BỜ MỘT VŨNG MẶN, ĐÁNH BÓNG CÁI MŨ ĐÓ. Y ĐỊNH BÁN NÓ ĐỂ TRẢ NỢ."],
		"wait": ["MỘT VŨNG MẶN PHÍA TÂY NAM BIỂN MUỐI. Y NGỒI ĐÁNH BÓNG MŨ."],
		"done": [["XÓA NỮA À. NGƯƠI XÓA NHIỀU HƠN TA TƯỞNG. TA BẮT ĐẦU NGHĨ LÀ NGƯƠI ĐANG XÓA HỘ TA."], ["CÁI MŨ ĐỒNG. LÒ ĐÚC SẼ TRẢ GIÁ TỐT. TA GHÉT LÀ TA BIẾT GIÁ CỦA NÓ."]],
		"reward": [{"gold": 0, "xp": 1500, "potions": 2, "item": null}, {"gold": 400, "xp": 1000, "potions": 0, "item": null}],
	},
	"s10": {
		"name": "SỔ NỢ CUỐI CÙNG", "main": false, "giver": "say", "after": ["s9", "m15"], "need": {"see": ["debt_say"]}, "branch": "debt5",
		"goal": "ĐỌC DÒNG CUỐI CỦA SỔ NỢ, Ở BÀN CỦA BÀ CẢ SẬY",
		"offer": ["CÒN MỘT DÒNG. TA KHÔNG ĐỌC NÓ CHO NGƯƠI NGHE ĐƯỢC.", "CUỐN SỔ Ở TRÊN BÀN TA, TRONG NHÀ PHƯỜNG. TỰ ĐỌC ĐI. RỒI LÀM ĐIỀU NGƯƠI ĐÃ LÀM VỚI BỐN DÒNG KIA."],
		"wait": ["CUỐN SỔ Ở TRÊN BÀN, TRƯỚC CỬA NHÀ PHƯỜNG."],
		"done": [["NGƯƠI XÓA. VÃN CŨNG SẼ XÓA. VÃN VẪN LUÔN XÓA CHO TA, TA CHỈ KHÔNG BAO GIỜ CHỊU GẠCH DÒNG ĐÓ.", "CẦM LẤY CÁI NÀY. NÓ LÀ CỦA VÃN. TA GIỮ NÓ BA NĂM VÌ TA KHÔNG DÁM TRẢ."], ["NGƯƠI THU. ĐÚNG. TA NỢ VÃN, VÀ NGƯƠI LÀ NGƯỜI DUY NHẤT CÒN ĐÒI ĐƯỢC.", "ĐÂY LÀ TẤT CẢ NHỮNG GÌ TA CÓ. VÀ CÁI NÀY NỮA. NÓ LÀ CỦA VÃN. GIỜ NỢ HẾT RỒI. TA NHẸ NGƯỜI MỘT CÁCH ĐÁNG XẤU HỔ."]],
		"reward": [{"gold": 0, "xp": 3000, "potions": 3, "item": ["charm", 2, 2]}, {"gold": 900, "xp": 2000, "potions": 0, "item": ["charm", 2, 2]}],
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
	"mute_1": {"name": "MÕ CÂM", "lines": []},
	"mute_2": {"name": "MÕ CÂM", "lines": []},
	"mute_3": {"name": "MÕ CÂM", "lines": []},
	"mute_4": {"name": "MÕ CÂM", "lines": []},
	"mute_5": {"name": "MÕ CÂM", "lines": []},
	"mute_6": {"name": "MÕ CÂM", "lines": []},
	"mute_7": {"name": "MÕ CÂM", "lines": []},
	"mute_8": {"name": "MÕ CÂM", "lines": []},
	"lighthouse": {"name": "NGỌN HẢI ĐĂNG GIỮA ĐẤT KHÔ", "lines": []},
	"lamp_keeper": {"name": "NGƯỜI GÁC ĐÈN", "lines": ["TRÊN ĐỈNH THÁP, MỘT ÔNG GIÀ NGỒI CẠNH NGỌN ĐÈN, TAY CẦM CUỐN LỊCH ĐÃ XÉ GẦN HẾT. 'HÔM NAY BỚT MỘT NGÀY. TÀU SẮP VỀ RỒI.'", "'HẠM ĐỘI ĐI BA TRĂM NĂM TRƯỚC. HỌ HỨA VỀ KHI TÔI ĐẾM HẾT. TÔI ĐẾM CHẬM LẠI MỘT CHÚT, ĐỂ HỌ KỊP.'", "ÔNG KHÔNG BIẾT BIỂN ĐÃ CẠN. ÔNG KHÔNG BIẾT HẠM ĐỘI NẰM CÁCH ĐÂY MỘT DẶM, TRONG MUỐI."],
		"opts": ["NÓI THẬT", "THẮP ĐÈN THEO NHỊP"], "flag": "lamp", "xp": 3000,
		"after": [["BẠN KỂ VỀ HẠM ĐỘI MẮC CẠN. ÔNG NGHE HẾT, GẬT ĐẦU, RỒI ĐẶT CUỐN LỊCH XUỐNG. 'VẬY TÔI ĐƯỢC NGHỈ RỒI.' NGỌN ĐÈN TẮT, LẦN ĐẦU SAU BA TRĂM NĂM."], ["BẠN CẦM ĐÈN, CHỚP THEO NHỊP ÔNG ĐẾM. ÔNG CƯỜI, XÉ THÊM MỘT TỜ LỊCH. ĐÊM NAY CON SỐ VẪN SẼ BỚT ĐI MỘT, VÀ ĐÊM MAI CŨNG VẬY."]]},
	"debt_potter": {"name": "NGƯỜI THỢ GỐM", "lines": ["MỘT DƯ ẢNH NGỒI BÊN LÒ GỐM NGUỘI, NUNG MÃI MỘT CÁI BÌNH. CÁI BÌNH NỨT, Y ĐẬP ĐI, NẶN LẠI.", "'BÌNH NÀY BÁN ĐƯỢC LÀ TÔI TRẢ ĐỦ. MƯỜI LẠNG. CHỈ CẦN MỘT CÁI KHÔNG NỨT.'"],
		"opts": ["XÓA NỢ", "THU NỢ"], "flag": "debt1",
		"after": [["BẠN NÓI NỢ ĐÃ ĐƯỢC TRẢ. Y DỪNG TAY, NHÌN CÁI BÌNH NỨT, RỒI ĐẶT NÓ XUỐNG THẬT NHẸ. LẦN ĐẦU TIÊN Y KHÔNG NẶN LẠI."], ["Y ĐƯA CHO BẠN MƯỜI LẠNG ĐỒNG ĐÃ XANH RỈ, RỒI QUAY LẠI NẶN TIẾP. NỢ HẾT, NHƯNG CÁI BÌNH VẪN NỨT."]]},
	"debt_mother": {"name": "NGƯỜI MẸ ĐẾM TIỀN", "lines": ["MỘT NGƯỜI ĐÀN BÀ NGỒI XỔ CÁI TÚI VẢI RA ĐẾM. 'MỘT, HAI, BA... THIẾU MỘT ĐỒNG.' BÀ GOM LẠI, ĐẾM LẠI.", "'CON TÔI UỐNG THUỐC XONG RỒI. TÔI CHỈ CẦN TRẢ ĐỦ LÀ VỀ.'"],
		"opts": ["XÓA NỢ", "THU NỢ"], "flag": "debt2",
		"after": [["BẠN ĐẶT MỘT ĐỒNG CỦA MÌNH VÀO TÚI. BÀ ĐẾM LẠI, ĐỦ, VÀ MỈM CƯỜI. RỒI BÀ TAN NHƯ HƠI NƯỚC TRÊN BẾN."], ["BẠN CẦM LẤY CÁI TÚI. BÀ NHÌN HAI BÀN TAY TRỐNG CỦA MÌNH, RỒI BẮT ĐẦU ĐẾM NGÓN TAY."]]},
	"debt_ferry": {"name": "NGƯỜI LÁI ĐÒ", "lines": ["MỘT DƯ ẢNH ĐẼO GỖ BÊN VŨNG NƯỚC. CON ĐÒ ĐÃ CÓ SỐNG THUYỀN, CHƯA CÓ MẠN. VỎ BÀO BAY RỒI TAN TRƯỚC KHI CHẠM ĐẤT.", "'MỘT CON ĐÒ ĐỔI MỘT CON ĐÒ. XONG CON NÀY LÀ TÔI VỀ BẾN.'"],
		"opts": ["XÓA NỢ", "THU NỢ"], "flag": "debt3",
		"after": [["BẠN BẢO Y CỨ ĐẼO TIẾP. Y GẬT ĐẦU, KHÔNG NGẨNG LÊN, VÀ HUÝT SÁO MỘT ĐIỆU ĐÒ ĐƯA."], ["BẠN CẦM LẤY MÁI CHÈO Y ĐẼO DỞ. Y NHÌN BẠN RẤT LÂU, RỒI LẤY MỘT KHÚC GỖ KHÁC, BẮT ĐẦU LẠI TỪ ĐẦU."]]},
	"debt_diver": {"name": "NGƯỜI THỢ LẶN", "lines": ["MỘT DƯ ẢNH NGỒI BÊN VŨNG MẶN, LẤY TAY ÁO ĐÁNH BÓNG CÁI MŨ ĐỒNG. MŨ ĐÃ BÓNG LOÁNG TỪ LÂU.", "'BÁN CÁI NÀY LÀ ĐỦ TRẢ. NHƯNG BÁN RỒI THÌ LẤY GÌ MÀ LẶN. MÀ KHÔNG LẶN THÌ LẤY GÌ MÀ TRẢ.'"],
		"opts": ["XÓA NỢ", "THU NỢ"], "flag": "debt4",
		"after": [["BẠN NÓI PHƯỜNG ĐÃ GẠCH TÊN Y. Y ĐỘI MŨ LÊN, ĐỨNG DẬY, VÀ ĐI THẲNG XUỐNG VŨNG MẶN. MẶT NƯỚC KHÔNG GỢN."], ["Y ĐƯA BẠN CÁI MŨ. KHÔNG CÓ MŨ, Y CHỈ CÒN LÀ MỘT CÁI BÓNG NGỒI BÊN VŨNG, NHÌN XUỐNG NƯỚC."]]},
	"debt_say": {"name": "SỔ NỢ CỦA PHƯỜNG", "lines": ["DÒNG CUỐI, NÉT CHỮ CỦA CHÍNH BÀ CẢ SẬY: 'CON NỢ: CẢ SẬY. CHỦ NỢ: VÃN. KHOẢN NỢ: MỘT ĐÊM Ở BẾN PHÀ, KHI VÃN ĐI THAY TA.'", "BÊN DƯỚI LÀ MỘT CHIẾC NHẪN ĐỒNG BUỘC CHỈ ĐỎ, VÀ MỘT KHOẢNG TRỐNG ĐỂ GHI 'ĐÃ TRẢ'."],
		"opts": ["XÓA NỢ", "THU NỢ"], "flag": "debt5",
		"after": [["BẠN GẠCH DÒNG ĐÓ. MỰC CÒN ƯỚT. ĐÂU ĐÓ SAU LƯNG, BÀ CẢ SẬY KHỊT MŨI THẬT TO."], ["BẠN VIẾT 'ĐÃ TRẢ' VÀO KHOẢNG TRỐNG. BÀ CẢ SẬY SẼ PHẢI TRẢ BẰNG THỨ GÌ ĐÓ. CẢ HAI NGƯỜI ĐỀU BIẾT ĐÓ LÀ ĐIỀU BÀ MUỐN."]]},
	"voice": {"name": "TIẾNG CỦA VÃN", "quest": "m26",
		"lines": ["TRONG IM LẶNG CỦA HỐ, MẢNH CHUÔNG TRONG NGỰC BẠN NGÂN MỘT MÌNH. TIẾNG VÃN RÕ HƠN BAO GIỜ HẾT.", "'ĐỪNG ĐỂ HỌ BIẾT EM NGHE ĐƯỢC HAI TIẾNG. ĐỪNG ĐI TÌM.' RỒI MỘT CÂU MỚI, RẤT NHỎ: 'EM ĐÃ ĐI TÌM. VẬY THÌ CHỌN ĐI.'", "MỖI TRẬN BẠN ĐÁNH BẰNG MẢNH NÀY, VÃN MÒN ĐI MỘT CHÚT. BẠN CÓ THỂ THẢ VÃN ĐI. HOẶC GIỮ LẠI."],
		"opts": ["THẢ TIẾNG VÃN", "GIỮ TIẾNG VÃN"], "flag": "van",
		"after": [["BẠN NỚI TAY. MẢNH CHUÔNG NGÂN MỘT TIẾNG CUỐI, DÀI, RỒI IM. LẦN ĐẦU TIÊN TỪ ĐÊM VÃN CHẾT, TRONG ĐẦU BẠN CHỈ CÓ TIẾNG CỦA BẠN."], ["BẠN SIẾT TAY QUANH MẢNH CHUÔNG. NÓ VẪN NGÂN, NHỎ HƠN TRƯỚC. Ở ĐÂU ĐÓ TRONG TIẾNG NGÂN, VÃN THỞ DÀI, NHƯ NGÀY XƯA MỖI LẦN BẠN BƯỚNG."]]},
	"kham_choice": {"name": "THẦY KHÂM",
		"lines": ["KHÂM NGỒI BÊN CÁI HÒM RỖNG. ÔNG KHÔNG NGẨNG LÊN. 'TA KHÔNG XIN GÌ. TA CHỈ MUỐN NGƯƠI BIẾT LÀ TA BIẾT.'"],
		"opts": ["THA CHO THẦY", "QUAY LƯNG"], "flag": "kham",
		"after": [["BẠN NGỒI XUỐNG CẠNH ÔNG MỘT LÚC. ÔNG KHÓC, KHÔNG THÀNH TIẾNG."], ["BẠN QUAY LƯNG. SAU LƯNG BẠN, ÔNG GÕ NHẸ VÀO NẮP HÒM, NHƯ GÕ MÕ. LẦN ĐẦU TIÊN BẠN NGHE ÔNG GÕ."]]},
	"marker_a": {"name": "MỎ NEO CỦA PHƯỜNG", "lines": ["BẠN CẠO LỚP MUỐI. TÊN KHẮC BÊN DƯỚI: 'BẢY. THỢ LẶN. TÌM ĐƯỢC MƯỜI HAI CÂN ĐỒNG TRONG MỘT NGÀY.'"]},
	"marker_b": {"name": "MỎ NEO CỦA PHƯỜNG", "lines": ["BẠN CẠO LỚP MUỐI. TÊN KHẮC BÊN DƯỚI: 'MẬN CON. MƯỜI BỐN TUỔI. ĐI THEO MẸ RA BÃI.'"]},
	"marker_c": {"name": "MỎ NEO CỦA PHƯỜNG", "lines": ["BẠN CẠO LỚP MUỐI. TÊN KHẮC BÊN DƯỚI: 'TÙNG. CHỒNG CỦA VÀNH. XUỐNG HẦM HAI LẤY MỘT CÁI ĐINH.'"]},
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
	"list": {
		"name": "BẢN CHÉP CUỐN SỔ CHÁY", "tex": "npc_archivist", "quest": "m24",
		"lines": ["BÀ GIỮ SỬ ĐẶT MỘT CUỐN SỔ LÊN BÀN. BÌA DA, GIỐNG HỆT SỔ HÀNG CỦA THẦY KHÂM. 'MỌI THỨ BỊ ĐỐT TRONG NƯỚC NÀY ĐỀU ĐƯỢC CHÉP LẠI TRƯỚC. ĐÓ LÀ VIỆC CỦA TA.'", "MỖI TRANG MỘT CÁI TÊN, KÈM MỘT DÒNG: 'NGHE HAI TIẾNG. CHƯA BIẾT. ĐỪNG ĐỂ HỌ BIẾT.' CÓ NHỮNG CÁI TÊN BẠN NHẬN RA TỪ BIA MỘ Ở BẾN PHÀ.", "TRANG CUỐI CHỈ CÓ MỘT DÒNG, NÉT CHỮ RUN: TÊN CỦA BẠN. BÊN DƯỚI, VÃN VIẾT: 'ĐỨA NÀY THÌ KHÔNG BÁN. ĐỨA NÀY LÀ CỦA TÔI.'", "BÀ GIỮ SỬ LẬT THÊM MỘT TỜ RỜI, VIẾT BẰNG MỰC MỚI. 'MẢNH CỦA NGƯƠI NGÂN BẰNG TIẾNG VÃN. MỖI LẦN NGƯƠI ĐÁNH, NGƯƠI DÙNG VÃN. NGƯƠI ĐÃ MÀI MÒN VÃN SUỐT ĐƯỜNG TỚI ĐÂY.'", "'TA GHI LẠI VÌ KHÔNG AI KHÁC GHI. NGƯỜI TA ĐỐT SỔ CHỨ KHÔNG ĐỐT ĐƯỢC CHUYỆN.'"],
	},
	"standoff": {
		"name": "HAI PHE TRƯỚC CỔNG", "tex": "", "quest": "m19",
		"lines": ["BÊN BẮC CON ĐƯỜNG, NGƯỜI CỦA HỘI GIỮ LẶNG ĐỨNG THÀNH HÀNG, ĐÁ NIÊM BUỘC SAU LƯNG. BÊN NAM, DÒNG VỌNG THÂN NGỒI QUANH NHỮNG NGỌN NẾN, MIỆNG LẨM NHẨM TÊN NGƯỜI CHẾT.", "'MỞ LÒ RA. ĐỂ HỌ ĐI.' 'NIÊM NÓ LẠI. ĐỂ HỌ YÊN.' HAI CÂU NÓI CÙNG MỘT ĐIỀU, VÀ CẢ HAI ĐỀU KHÔNG HỎI NHỮNG NGƯỜI TRONG LÒ MUỐN GÌ.", "GIỮA ĐƯỜNG, MỘT TỐP THỢ MỎ ĐỨNG KHOANH TAY, CUỐC TRÊN VAI. HỌ KHÔNG ĐỨNG VỀ BÊN NÀO. HỌ ĐỨNG TRƯỚC BÁT CƠM CỦA MÌNH.", "MỘT CÂY CUNG BÊN BẮC KÉO CĂNG, RỒI HẠ XUỐNG. TỐ DIÊN ĐẶT TAY LÊN VAI NGƯỜI LÍNH. KHÔNG AI THỞ MẠNH."],
	},
	"ledger": {
		"name": "SỔ ĐO CỦA Ô KHA", "tex": "npc_okha", "quest": "m20",
		"lines": ["Ô KHA RÓT TRÀ CHO BẠN NHƯ RÓT CHO MỘT NGƯỜI BẠN CŨ. RỒI ÔNG MỞ MỘT CUỐN SỔ DÀY BẰNG CẢ GANG TAY.", "'NHÀ TA ĐÚC CHUÔNG MẸ. TỔ TIÊN TA ĐẬP VỠ NÓ. CẢ HAI ĐỀU LÀ VIỆC ĐÚNG. NGƯƠI MUỐN NGHE VÌ SAO KHÔNG?'", "'CHUÔNG MẸ LÀ CỐI XAY. NÓ NGHIỀN KÝ ỨC NGƯỜI CHẾT THÀNH VỌNG TINH. VỌNG TINH NUÔI TRIỀU ĐÌNH SỐNG HÀNG TRĂM NĂM. TỔ TIÊN TA THẤY VẬY, NÊN ĐẬP NÓ.'", "'TỪ ĐÊM RẠN, NGƯỜI CHẾT KHÔNG TAN NỮA. HẦM VỌNG MỌC KHẮP NƠI. TA ĐANG ĐÚC MỘT CÁI CHUÔNG MỚI: KHÔNG XAY, CHỈ RU. TA CẦN TIẾNG CỦA NHỮNG KẺ NGHE ĐƯỢC HAI ÂM ĐỂ LÊN DÂY NÓ. NHƯ VÃN. NHƯ NGƯƠI.'", "SAU LƯNG ÔNG, KHUÔN CHUÔNG THỬ RUNG LÊN KHI BẠN NHẮC TỚI NGẢI. Ô KHA NHÌN NÓ RẤT LÂU. 'CON BÉ ĐÓ KHÔNG ĐIẾC VỌNG. NÓ LÀ VỌNG. KHÂM ĐÃ GIẤU NÓ KHỎI TA MƯỜI LĂM NĂM.'"],
	},
	"manifest": {
		"name": "SỔ HÀNG CỦA HẠM ĐỘI", "tex": "", "quest": "m15",
		"lines": ["GIỮA HẦM HAI, MỘT CUỐN SỔ BỌC DA NẰM TRÊN NẮP HÒM, KHÔ NGUYÊN NHƯ VỪA ĐƯỢC ĐẶT XUỐNG.", "'HÀNG CỦA CHUÔNG. BỐN TRĂM HÒM. VỌNG TINH, LOẠI MỘT. GIAO TẬN TAY TRIỀU ĐÌNH.' DÒNG NÀO CŨNG ĐƯỢC KÝ BẰNG CÙNG MỘT DẤU: MỘT CÁI CHUÔNG CÓ VẾT NỨT.", "BẠN MỞ MỘT CÁI HÒM. BÊN TRONG LÀ NHỮNG HẠT SÁNG NHƯ MUỐI. MẢNH CHUÔNG TRONG NGỰC BẠN KÊU LÊN, VÀ BẠN NGHE THẤY HÀNG TRĂM GIỌNG NÓI CÙNG LÚC, KHÔNG GIỌNG NÀO NÓI HẾT CÂU.", "CHUÔNG MẸ KHÔNG CHỈ XÓA TÊN. NÓ NGHIỀN NGƯỜI CHẾT THÀNH THỨ GÌ ĐÓ CÓ THỂ ĐÓNG HÒM VÀ CHỞ ĐI.", "TRÊN BOONG KỲ HẠM, MỘT NGỌN ĐÈN NHÚC NHÍCH. ĐÔ ĐỐC VẪN CÒN ĐI TUẦN."],
	},
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
	"m22": "Ô KHA ĐÃ LÊN KINH. KIM YẾN, NGƯỜI THỪA KẾ BA TRĂM MƯỜI TUỔI ĐANG GIÀ ĐI TỪNG THÁNG, CHO BẠN ĐI CÙNG MỘT ĐOẠN.",
	"m23": "BẠN DẸP BỌN THƯ LẠI CHÉP TRÊN PHỐ KINH.",
	"m24": "CUỐN SỔ VÃN ĐỐT LÀ DANH SÁCH NHỮNG KẺ NGHE HAI TIẾNG. TÊN CUỐI LÀ BẠN. BẠN ĐÃ MÀI MÒN VÃN SUỐT ĐƯỜNG ĐI.",
	"m25": "Ô KHA NGÃ VÀ BƯỚC VÀO LÀM QUẢ LẮC. TIẾNG ĐẦU TIÊN IM. KIM YẾN ĐỊNH CƯỚP CHUÔNG RỒI BUÔNG TAY.",
	"m26": ["BẠN ĐÃ THẢ TIẾNG VÃN. MẢNH CHUÔNG IM.", "BẠN ĐÃ GIỮ TIẾNG VÃN. MẢNH CHUÔNG VẪN NGÂN, MỎNG DẦN."],
	"m17": "TIẾNG VÃN ĐANG Ở LÒ TÁI THANH, TRÊN DÃY MỎ CÂM. BÁC THAN NÓI CẢ DÃY NÚI SỐNG NHỜ CÁI LÒ ĐÓ.",
	"m18": "BẠN DẸP NGƯỜI XỈ QUANH LÀNG THỢ. BÁC THAN CHỈ CHO BẠN CỬA KHÔNG KHÓA.",
	"m19": "HỘI GIỮ LẶNG VÀ DÒNG VỌNG THÂN SUÝT ĐÁNH NHAU TRƯỚC CỔNG LÒ. Ô KHA MỜI BẠN VÀO LÀM KHÁCH.",
	"m20": "Ô KHA NÓI HẾT: CHUÔNG MẸ LÀ CỐI XAY NGƯỜI CHẾT, VÀ ÔNG ĐANG ĐÚC CÁI CHUÔNG MỚI. NGẢI KHÔNG ĐIẾC VỌNG: CÔ LÀ VỌNG.",
	"m21": "BẠN LẤY LẠI TIẾNG VÃN VÀ NGHE THÊM BA CHỮ: 'ĐỪNG ĐI TÌM.' LÒ SẬP MỘT NỬA. TỐ DIÊN DÙNG MẢNH CHUÔNG CỨU QUÂN VÀ BỊ HỘI TƯỚC CHỨC.",
	"m12": "LÃO KHÂM GỬI BẠN XUỐNG BIỂN MUỐI NGÂN TÌM 'HÀNG CỦA CHUÔNG'. Ở ĐÓ, LÒ ĐÚC TRẢ GẤP BA CHO MỖI MẢNH CHUÔNG.",
	"m13": "BẠN DỌN LŨ CUA MUỐI CHO PHƯỜNG CỦA CHỊ VÀNH.",
	"m14": "THẺ HÀNG CỦA HẠM ĐỘI CHỈ CÙNG MỘT CHỖ: KỲ HẠM, HẦM HAI, 'HÀNG CỦA CHUÔNG. KHÔNG MỞ.'",
	"m15": "SỔ HÀNG GHI VỌNG TINH: NGƯỜI CHẾT BỊ NGHIỀN RA, ĐÓNG HÒM, CHỞ VỀ KINH. ĐÔ ĐỐC SẢNH MUỐI ĐÃ NGÃ.",
	"m16": "THẦY KHÂM BỎ ĐI CÙNG HÒM TIẾNG, CẢ TIẾNG VÃN, ĐỂ BÁN CHO Ô KHA. NGẢI Ở LẠI LÊN DÂY MẢNH CHO BẠN.",
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

# The Admiral always drops this: a charm of salt from his coat. Critical hits chill.
static func admiral_unique() -> Dictionary:
	return {"name": "MUỐI ÁO ĐÔ ĐỐC", "slot": "charm", "rar": 3, "tier": 2, "stats": {"hp": 45, "crit": 6}, "uniq": "salt"}

# Bach Lo always drops his hammer: the last strike of every chain sets the foe burning.
static func forge_unique() -> Dictionary:
	return {"name": "BÚA BẠCH LÔ", "slot": "weapon", "rar": 3, "tier": 2, "stats": {"atk": 18, "stag": 40}, "uniq": "forge"}

# The ending, shown full screen after m26, by flags.van: [0] the voice was released, [1] it was kept.
const EPILOGUE = [
	["CHUÔNG MẸ KHÔNG ĐƯỢC ĐÚC LẠI. PHẦN CÒN SỐNG CỦA NÓ ĐÃ IM. VỌNG KHÔNG CÒN DÀY LÊN ĐỀU NỮA MÀ DÂNG RỒI RÚT, NHƯ THỦY TRIỀU. NGƯỜI TA GỌI ĐÓ LÀ TRIỀU VỌNG.", "MẢNH CHUÔNG TRONG NGỰC BẠN IM. BẠN VẪN ĐÁNH NHƯ CŨ, BẰNG ĐÔI TAY VÃN ĐÃ DẠY VÀ BẠN ĐÃ LUYỆN. CÓ ĐÊM BẠN TỈNH DẬY, CHỜ MỘT TIẾNG NÓI, VÀ CHỈ CÓ TIẾNG MÕ TRẤN.", "NGẢI RA VÀNH HỐ ĐO TRIỀU VỌNG MỖI SÁNG. PHÉP TÍNH CỦA Ô KHA VẪN TREO ĐÓ: NẾU KHÔNG XAY NGƯỜI CHẾT, THÌ LÀM GÌ VỚI HỌ. CHƯA AI GIẢI.", "HẾT."],
	["CHUÔNG MẸ KHÔNG ĐƯỢC ĐÚC LẠI. PHẦN CÒN SỐNG CỦA NÓ ĐÃ IM. VỌNG KHÔNG CÒN DÀY LÊN ĐỀU NỮA MÀ DÂNG RỒI RÚT, NHƯ THỦY TRIỀU. NGƯỜI TA GỌI ĐÓ LÀ TRIỀU VỌNG.", "MẢNH CHUÔNG TRONG NGỰC BẠN VẪN NGÂN. MỖI LẦN BẠN LÊN CẤP, VÃN NÓI MỘT CÂU, NGẮN HƠN LẦN TRƯỚC. MỘT NGÀY NÀO ĐÓ VÃN SẼ CHỈ CÒN LÀ MỘT TIẾNG THỞ. BẠN BIẾT, VÀ BẠN VẪN GIỮ.", "NGẢI RA VÀNH HỐ ĐO TRIỀU VỌNG MỖI SÁNG. PHÉP TÍNH CỦA Ô KHA VẪN TREO ĐÓ: NẾU KHÔNG XAY NGƯỜI CHẾT, THÌ LÀM GÌ VỚI HỌ. CHƯA AI GIẢI.", "HẾT."],
]

# ---------------------------------------------------------------- the Eight Mute Clappers (a hunt, no one gives it)
# A carpenter of the Night of Cracking carved eight wooden clappers, each holding the last words of someone of one root tone.
# Only the next clapper in the chain speaks; its words are the riddle for the one after. [where, the last words, the riddle]
const MUTES = [
	["CHIẾN BINH", "'TÔI ĐỨNG GIỮ CỔNG TRẤN CẢ ĐÊM. KHI TIẾNG CHUÔNG LĂN QUA, TÔI KHÔNG LÙI. TÔI KHÔNG BIẾT LÀ PHẢI LÙI.'", "'ĐI TÌM CHỖ CÒ ĐỨNG MỘT CHÂN, NƠI ĐẦM LAU GẶP NƯỚC Ở BỜ ĐÔNG NAM.'"],
	["NGUYÊN TỐ SƯ", "'TÔI GỌI LỬA, GỌI SƯƠNG, GỌI SÉT. ĐÊM ĐÓ TÔI GỌI CẢ BA CÙNG LÚC, VÀ KHÔNG CÁI NÀO TRẢ LỜI.'", "'NƠI NGƯỜI GÁC PHÀ PHƠI LƯỚI, TRÊN GÁC CAO, TRƯỚC KHI LÊN BOONG.'"],
	["SÁT THỦ", "'TÔI GIẾT BẰNG MỘT NHÁT. ĐÊM ĐÓ TÔI HỌC RẰNG CÓ NHỮNG THỨ KHÔNG CÓ LƯNG ĐỂ ĐÂM.'", "'ĐI TỚI NƠI RỪNG THỞ RA, Ở GÓC ĐÔNG BẮC, NƠI SÓI KHÔNG BAO GIỜ ĐI MỘT MÌNH.'"],
	["THỢ SĂN", "'TÔI THEO DẤU MỌI THỨ. ĐÊM ĐÓ TÔI THEO DẤU TIẾNG CHUÔNG, VÀ NÓ DẪN TÔI VỀ CHÍNH NHÀ MÌNH.'", "'XUỐNG NƠI BIỂN ĐÃ CẠN, PHÍA TÂY BẮC, NƠI MUỐI CHẤT THÀNH ĐỐNG NHƯ MỘ.'"],
	["HỘ VỆ", "'TÔI CHE CHO BA ĐỨA NHỎ BẰNG TẤM KHIÊN CỦA TÔI. KHIÊN CHẶN ĐƯỢC ĐÁ. KHÔNG CHẶN ĐƯỢC TIẾNG.'", "'VÀO HẦM TÀU, TỚI BOONG SĨ QUAN, NƠI ĐÔ ĐỐC TỪNG ĐỨNG NHÌN XUỐNG.'"],
	["THUẬT SĨ LINH HỒN", "'TÔI NÓI CHUYỆN VỚI NGƯỜI CHẾT CẢ ĐỜI. ĐÊM ĐÓ HỌ IM, VÀ TÔI HIỂU LÀ HỌ ĐANG BỊ ĐEM ĐI.'", "'LÊN NÚI TUYẾT, TỚI SÂN TRƯỚC CỔNG LÒ, NƠI HAI PHE ĐỨNG NHÌN NHAU.'"],
	["KỸ SƯ CỔ VẬT", "'TÔI SỬA ĐƯỢC MỌI CỖ MÁY. TÔI ĐÃ THỬ SỬA CÁI CHUÔNG. TÔI CHỈ LÀM NÓ KÊU TO HƠN.'", "'LÊN KINH, TỚI GÓC ĐÔNG NAM, NƠI CỔNG KHÔNG AI CANH NỮA.'"],
	["TƯ TẾ", "'TÔI CẦU NGUYỆN CHO NHỮNG NGƯỜI SẮP ĐI. ĐÊM ĐÓ TÔI CẦU NGUYỆN CHO CẢ NHỮNG NGƯỜI KHÔNG ĐƯỢC ĐI. TÔI LÀ NGƯỜI CUỐI CÙNG. NGƯƠI ĐÃ NGHE ĐỦ TÁM TIẾNG.'", ""],
]

# The eighth clapper gives this: the charm of eight tones. Every ultimate heals and fills a little.
static func eight_unique() -> Dictionary:
	return {"name": "MÕ TÁM TIẾNG", "slot": "charm", "rar": 3, "tier": 2, "stats": {"hp": 50, "cdr": 8}, "uniq": "eight"}

# what Ngải says of the Echo Tide, by its level (1 to 5)
const TIDE_TALK = [
	"TRIỀU VỌNG HÔM NAY MỨC MỘT. HẦM YÊN NHƯ GIẾNG CẠN. ĐI NHẶT THÌ ÍT ĐỒ, NHƯNG VỀ ĐƯỢC.",
	"TRIỀU VỌNG MỨC HAI. DƯ ẢNH THỨC DẬY TỪNG ĐÁM. BẠN SẼ THẤY VÀI KẺ MANG DẤU.",
	"TRIỀU VỌNG MỨC BA. HẦM ĐANG THỞ MẠNH. ĐỒ TỐT HƠN, VÀ CHÚNG ĐÁNH ĐAU HƠN.",
	"TRIỀU VỌNG MỨC BỐN. ÂM THOA CỦA MÌNH RUNG KHÔNG NGỪNG. NẾU XUỐNG, ĐỪNG XUỐNG MỘT MÌNH. MÀ BẠN THÌ LÚC NÀO CŨNG MỘT MÌNH.",
	"TRIỀU VỌNG MỨC NĂM. ĐỈNH TRIỀU. HẦM NÀO CŨNG ĐẦY. KẺ NÀO VỀ ĐƯỢC HÔM NAY SẼ GIÀU. KẺ KHÔNG VỀ THÌ MÌNH SẼ GHI TÊN.",
]

# ---------------------------------------------------------------- tone stones (runes)
# Each stone gives one thing and takes another, and once set it stays: the choice is which item deserves it.
# Magic items have one socket, rare items two, uniques one. Only a shop (Kham, later Ngải) can set a stone.
const RUNES = {
	"steel": {"name": "ĐÁ ÂM THÉP", "stats": {"atk": 4, "haste": -6}},
	"thorn": {"name": "ĐÁ ÂM GAI", "stats": {"crit": 6, "def": -2}},
	"blood": {"name": "ĐÁ ÂM MÁU", "stats": {"leech": 3, "hp": -12}},
	"wind": {"name": "ĐÁ ÂM GIÓ", "stats": {"spd": 8, "def": -2}},
	"stone": {"name": "ĐÁ ÂM ĐÁ", "stats": {"def": 5, "spd": -5}},
	"ember": {"name": "ĐÁ ÂM LỬA", "stats": {"rage": 30, "hp": -10}},
	"bell": {"name": "ĐÁ ÂM CHUÔNG", "stats": {"cdr": 8, "atk": -2}},
	"gold": {"name": "ĐÁ ÂM VÀNG", "stats": {"gold": 40, "crit": -3}},
}

static func rune_item(id: String) -> Dictionary:
	return {"name": RUNES[id].name, "slot": "rune", "rar": 2, "tier": 0, "stats": RUNES[id].stats.duplicate(), "uniq": "", "rune": id}

static func random_rune() -> Dictionary:
	var ids = RUNES.keys()
	return rune_item(ids[randi() % ids.size()])

static func sockets(it: Dictionary) -> int:
	if it.slot == "rune":
		return 0
	return 1 if it.rar == 3 else it.rar
