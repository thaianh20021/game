using System.Collections.Generic;
using UnityEngine;

// Progression between and during runs:
// - BẢO VẬT: relics taken during a run (reward gates, bosses, elites); the pool grows in the BẢO KHỐ.
// - KIẾP NẠN: difficulty tiers chosen before a run; each adds one rule and pays more NGỘ TÍNH.
// - KIẾM HỒN: dropped by bosses, opens the other sects.
// - KÝ ỨC: nine fragments of the story, one per boss kill, three per boss.
public class Relic { public string id, name, desc; public int rare; }
public class Heat { public string name, desc; }

public static class J {
	static Relic R(string id, int rare, string name, string desc) { return new Relic { id = id, rare = rare, name = name, desc = desc }; }
	public static readonly Relic[] RELICS = {
		R("huyetngoc", 0, "HUYẾT NGỌC", "Hạ một địch hồi 1 sinh lực."),
		R("phonghai", 0, "THANH PHONG HÀI", "Chạy nhanh hơn 15%."),
		R("kimcang", 0, "KIM CANG PHÙ", "Nhận ít hơn 15% sát thương."),
		R("phongan", 0, "PHONG ẤN TỬ", "Thêm 1 lần khinh công."),
		R("thattinh", 0, "THẤT TINH HẠP", "Mang thêm 2 phi kiếm."),
		R("dandien", 0, "ĐAN ĐIỀN LÔ", "Vào mỗi bãi chiến với ít nhất 50 nội lực."),
		R("toaithach", 0, "TOÁI THẠCH QUYỀN", "Mọi đòn phá THẾ mạnh hơn 30%."),
		R("hoalinh", 0, "HỎA LINH CHÂU", "Mỗi đòn có 12% cơ hội gây THIÊU."),
		R("bangtam", 1, "BĂNG TÂM KÍNH", "Đỡ chuẩn làm chậm mọi địch quanh mình."),
		R("ngoctuy", 1, "NGỌC TỦY", "TUYỆT KỸ hồi nhanh hơn 30%."),
		R("satky", 1, "HUYẾT SÁT KỲ", "Mỗi 10 LIÊN TRẢM: +5% sát thương tới hết bãi (tối đa 30%)."),
		R("phuongvu", 1, "PHƯỢNG VŨ LINH", "Gục ngã thì đứng dậy một lần với 30% sinh lực."),
		R("thamlang", 1, "THAM LANG ẤN", "Ngân lượng +50%, sinh lực tối đa -10."),
		R("lieudiep", 1, "LIỄU DIỆP TIÊU", "Khinh công xuyên qua địch, chém 14 sát thương."),
		R("amduong", 1, "ÂM DƯƠNG BÀN", "TƯƠNG SINH và TƯƠNG KHẮC mạnh hơn 35%."),
		R("cuongbao", 1, "CUỒNG BẠO ĐAN", "Gây thêm 25% sát thương, nhận thêm 15%."),
	};
	// open from the first run; the rest are bought in the BẢO KHỐ
	public static readonly string[] START = { "huyetngoc", "phonghai", "kimcang", "phongan", "thattinh", "dandien", "toaithach", "hoalinh" };
	public const int RELIC_COST = 25;
	public static Relic Get(string id) { foreach (var r in RELICS) if (r.id == id) return r; return null; }

	public static readonly Heat[] HEAT = {
		new Heat { name = "THANH TỊNH", desc = "Không thêm gì." },
		new Heat { name = "KIẾP I", desc = "Địch thường thêm 25% sinh lực." },
		new Heat { name = "KIẾP II", desc = "Tinh anh xuất hiện nhiều gấp đôi." },
		new Heat { name = "KIẾP III", desc = "Địch gây thêm 15% sát thương." },
		new Heat { name = "KIẾP IV", desc = "Không còn hồi sinh lực sau mỗi bãi chiến." },
		new Heat { name = "KIẾP V", desc = "Thương nhân bán đắt hơn 50%." },
		new Heat { name = "KIẾP VI", desc = "Trùm thêm 30% sinh lực." },
		new Heat { name = "KIẾP VII", desc = "Địch ra đòn dồn dập hơn 20%." },
		new Heat { name = "KIẾP VIII", desc = "Mỗi đợt phục kích có thêm một tinh anh." },
		new Heat { name = "KIẾP IX", desc = "Mọi cách hồi sinh lực chỉ còn một nửa." },
	};
	public const float HEAT_PAY = 0.15f;   // extra NGỘ TÍNH per tier

	public static readonly int[] SECT_COST = { 0, 2, 3, 4 };   // KIẾM HỒN, same order as D.SECTS

	public static readonly string[] MEM_TITLE = {
		"TRANG ĐẦU", "ĐỆ TỬ NGOẠI MÔN", "NÉT KHỞI BÚT",
		"BẠN CỜ", "LỬA TRONG THƯ PHÒNG", "CHỖ TÂM DỪNG",
		"BỨC HỌA CHÍNH ĐIỆN", "NGƯỜI ĐỐT NÚI", "TRANG ĐỂ TRỐNG",
	};
	public static readonly string[] MEM = {
		"Đêm Mặc Kiếm Môn cháy, ta thấy một gã khoác da hổ ôm đi trang đầu của bộ kiếm phổ. Mực trên trang ấy còn ướt.",
		"Hắc Hổ vốn là đệ tử ngoại môn. Sư phụ đuổi hắn xuống núi vì hắn học kiếm chỉ để cướp. Hắn chưa từng quên ngày đó.",
		"Trang giấy hắn giữ chỉ có một nét mực, đậm ở đầu và nhạt dần. Đó là nét khởi đầu của mọi chiêu trong Mặc Kiếm Lục.",
		"Lão thiền sư mù từng là bạn cờ của sư phụ. Mười năm, mỗi mùa xuân, hai người đánh đúng một ván rồi chia tay.",
		"Lão nói lửa không do người ngoài mang tới. Nó bắt đầu trong thư phòng, nơi chỉ sư phụ có chìa khóa.",
		"Trang thứ hai viết: kiếm không ở trong tay, kiếm ở chỗ tâm dừng lại. Ai chưa dừng được thì kiếm chỉ là sắt.",
		"Mái tóc bạc ấy ta đã thấy trong bức họa treo ở chính điện. Người trong tranh trẻ hơn, nhưng cách cầm kiếm thì không đổi.",
		"Kiếm Thánh là sư phụ. Người tự tay đốt môn phái để giấu kiếm phổ khỏi thiên hạ, rồi đợi xem ai đủ sức đi hết ba ngọn núi.",
		"Trang cuối để trống. Người bảo: phần còn lại ngươi tự viết, bằng mực của chính mình.",
	};
}

public partial class Game {
	readonly List<string> relics = new List<string>();
	readonly List<Relic> relicOffers = new List<Relic>();
	bool relicPending, phoenixUsed;
	float satky;              // HUYẾT SÁT KỲ bonus for the current fight
	int heatI;                // cursor on the heat screen
	int vaultI, memI;
	readonly HashSet<Foe> dashHit = new HashSet<Foe>();

	bool Has(string id) { return relics.Contains(id); }
	bool HeatAt(int n) { return meta.kiep >= n; }

	// --- effects that other files call
	float HurtTakenMul() { return (Has("kimcang") ? 0.85f : 1) * (Has("cuongbao") ? 1.15f : 1); }
	float HealMul() { return HeatAt(9) ? 0.5f : 1; }
	float PriceMul() { return HeatAt(5) ? 1.5f : 1; }
	float DealMul() { return (Has("cuongbao") ? 1.25f : 1) * (1 + satky); }

	void RelicRecalc() {
		if (Has("thamlang")) { maxHp -= 10; coinMul *= 1.5f; }
		if (Has("phongan")) dashMax += 1;
	}

	void RelicKill(Foe f) {
		if (Has("huyetngoc")) Heal(1);
		if (Has("satky") && chain % 10 == 0) satky = Mathf.Min(0.3f, satky + 0.05f);
		// elites sometimes drop a relic shrine
		if (f.elite && Rnd() < 0.22f && state == "play") {
			AddItem(f.pos, "relic", "BẢO VẬT\nNhặt để chọn một trong ba", 0, "chest", null);
			Text(f.pos + new Vector2(0, 140), "BẢO VẬT!", new Color(1f, 0.85f, 0.4f), 22);
		}
	}

	void RelicParry() {
		if (!Has("bangtam")) return;
		foreach (var f in foes) if (!f.dead && (f.pos - ppos).magnitude < 260) f.slow = 3;
		wavesFx.Add(new Wave { pos = ppos, r = 30, spd = 900, max = 260, hit = true, col = D.EL_COL[D.THUY] });
	}

	void RelicDash() {
		if (!Has("lieudiep")) return;
		foreach (var f in foes) {
			if (f.dead || f.spawn > 0 || dashHit.Contains(f) || (f.pos - ppos).magnitude > f.d.r + 40) continue;
			dashHit.Add(f);
			HurtFoe(f, 14 * dmgMul, SlotEl("dash"), SlotLv("dash"), 1, ddir);
		}
	}

	bool RelicRevive() {
		if (!Has("phuongvu") || phoenixUsed) return false;
		phoenixUsed = true;
		hp = maxHp * 0.3f; inv = 2f;
		Burst(ppos, 300, 30, D.HOA, 1, false);
		Banner("PHƯỢNG VŨ LINH", "Lửa không tắt");
		return true;
	}

	// --- relic choice (gate reward, boss, elite drop)
	void OpenRelic() {
		var pool = new List<Relic>();
		foreach (var r in J.RELICS) if (meta.relics.Contains(r.id) && !Has(r.id)) pool.Add(r);
		relicOffers.Clear();
		while (relicOffers.Count < 3 && pool.Count > 0) { int k = rng.Next(pool.Count); relicOffers.Add(pool[k]); pool.RemoveAt(k); }
		if (relicOffers.Count == 0) { AddCoins(60); Toast("Đã có đủ bảo vật: nhận ngân lượng"); return; }
		state = "relic";
		menuI = 0;
		sfx.Play("pick", 0.8f);
	}

	void RelicAct(int i) {
		if (i < 0 || i >= relicOffers.Count) return;
		var r = relicOffers[i];
		relics.Add(r.id);
		if (!meta.seen.Contains(r.id)) meta.seen.Add(r.id);
		float before = maxHp;
		Recalc();
		if (maxHp > before) hp += maxHp - before;
		hp = Mathf.Min(hp, maxHp);
		Toast("BẢO VẬT: " + r.name);
		sfx.Play("pick");
		state = "play";
		prev.atk = true; inp.atk = false; buf = 0;
	}

	void GuiRelic() {
		Dim(0.6f);
		Lab(new Rect(0, 40, GW, 56), "CHỌN BẢO VẬT", 42, D.PAPER, TextAnchor.MiddleCenter, true);
		Lab(new Rect(0, 94, GW, 28), "A / D chọn   ·   ENTER nhận", 16, D.PAPER);
		float w = 300, gap = 28, x0 = (GW - (w * relicOffers.Count + gap * (relicOffers.Count - 1))) / 2;
		for (int i = 0; i < relicOffers.Count; i++) {
			var r = relicOffers[i];
			bool sel = menuI == i;
			var rc = new Rect(x0 + i * (w + gap), sel ? 150 : 166, w, 360);
			Panel(rc, sel);
			Seal(new Rect(rc.x + w / 2 - 40, rc.y + 26, 80, 62), r.name.Substring(0, r.name.IndexOf(' ') > 0 ? r.name.IndexOf(' ') : r.name.Length), r.rare > 0 ? new Color(0.55f, 0.32f, 0.7f) : new Color(0.62f, 0.45f, 0.2f), 18);
			Lab(new Rect(rc.x, rc.y + 96, w, 26), r.rare > 0 ? "QUÝ" : "THƯỜNG", 14, D.RED, TextAnchor.MiddleCenter, false, false);
			Lab(new Rect(rc.x + 10, rc.y + 122, w - 20, 40), r.name, 24, D.INK, TextAnchor.MiddleCenter, true, false);
			Box(new Rect(rc.x + 40, rc.y + 170, w - 80, 2), new Color(0.07f, 0.06f, 0.06f, 0.4f));
			Lab(new Rect(rc.x + 24, rc.y + 186, w - 48, 120), r.desc, 18, D.INK, TextAnchor.UpperCenter, false, false);
			if (Hit(rc, i)) RelicAct(i);
		}
	}

	void GuiRelicHud() {
		for (int i = 0; i < relics.Count; i++) {
			var r = J.Get(relics[i]);
			var rc = new Rect(28 + (i % 8) * 34, 154 + (i / 8) * 34, 30, 30);
			Seal(rc, r.name.Substring(0, 1), r.rare > 0 ? new Color(0.55f, 0.32f, 0.7f) : new Color(0.62f, 0.45f, 0.2f), 14);
		}
	}

	// --- heat (KIẾP NẠN) choice before a run
	void HeatTick() {
		int n = Mathf.Min(meta.heatMax, J.HEAT.Length - 1) + 1;
		if (P(inp.up, prev.up)) { heatI = (heatI + n - 1) % n; sfx.Play("ui", 0.5f); }
		if (P(inp.down, prev.down)) { heatI = (heatI + 1) % n; sfx.Play("ui", 0.5f); }
		if (P(inp.ok, prev.ok) && T - stateT > 0.3f) { meta.kiep = heatI; SaveMeta(); StartRun(); }
		if (P(inp.back, prev.back)) { state = "sect"; menuI = Mathf.Max(0, System.Array.FindIndex(D.SECTS, k => k.id == meta.sect)); }
	}

	void GuiHeat() {
		Dim(0.65f);
		Lab(new Rect(0, 26, GW, 56), "KIẾP NẠN", 42, D.PAPER, TextAnchor.MiddleCenter, true);
		Lab(new Rect(0, 78, GW, 26), "Mỗi tầng giữ mọi luật của các tầng trước. Thắng ở tầng cao nhất để mở tầng kế.", 16, D.PAPER);
		float w = 760, x = (GW - w) / 2;
		int n = Mathf.Min(meta.heatMax, J.HEAT.Length - 1);
		for (int i = 0; i < J.HEAT.Length; i++) {
			bool open = i <= n, sel = heatI == i, on = i <= heatI;
			var r = new Rect(x, 116 + i * 54, w, 48);
			Box(new Rect(r.x - 3, r.y - 3, r.width + 6, r.height + 6), sel ? D.RED : new Color(0.07f, 0.06f, 0.06f, 0.6f));
			Box(r, open ? (on ? new Color(0.97f, 0.9f, 0.78f) : D.PAPER) : new Color(0.35f, 0.33f, 0.31f));
			Lab(new Rect(r.x + 18, r.y, 170, 48), J.HEAT[i].name, 20, open ? D.INK : new Color(0.55f, 0.52f, 0.5f), TextAnchor.MiddleLeft, true, false);
			Lab(new Rect(r.x + 190, r.y, 430, 48), open ? J.HEAT[i].desc : "Chưa mở", 16, open ? D.INK : new Color(0.55f, 0.52f, 0.5f), TextAnchor.MiddleLeft, false, false);
			if (i > 0) Lab(new Rect(r.xMax - 150, r.y, 132, 48), "+" + Mathf.RoundToInt(i * J.HEAT_PAY * 100) + "% NGỘ", 15, open ? D.RED : new Color(0.55f, 0.52f, 0.5f), TextAnchor.MiddleRight, true, false);
			if (open && Hit(r, i)) { heatI = i; meta.kiep = i; SaveMeta(); StartRun(); }
		}
		Lab(new Rect(0, GH - 40, GW, 28), "W / S chọn tầng   ·   ENTER khởi hành   ·   ESC quay lại", 16, D.PAPER);
	}

	// --- sect unlocks with KIẾM HỒN (on the sect screen)
	bool SectOpen(int i) { return meta.sects.Contains(D.SECTS[i].id); }
	bool TryUnlockSect(int i) {
		if (SectOpen(i)) return true;
		int c = J.SECT_COST[Mathf.Min(i, J.SECT_COST.Length - 1)];
		if (meta.hon < c) { sfx.Play("block", 0.6f); Toast("Cần " + c + " KIẾM HỒN"); return false; }
		meta.hon -= c;
		meta.sects.Add(D.SECTS[i].id);
		SaveMeta();
		sfx.Play("gong", 0.7f);
		Toast("MỞ MÔN PHÁI: " + D.SECTS[i].name);
		return false;   // a fresh unlock is shown before the run starts
	}

	// --- BẢO KHỐ: the relic codex; buy relics into the pool
	void VaultTick() {
		int n = J.RELICS.Length;
		if (P(inp.left, prev.left)) { vaultI = (vaultI + n - 1) % n; sfx.Play("ui", 0.5f); }
		if (P(inp.right, prev.right)) { vaultI = (vaultI + 1) % n; sfx.Play("ui", 0.5f); }
		if (P(inp.up, prev.up)) { vaultI = (vaultI + n - 4) % n; sfx.Play("ui", 0.5f); }
		if (P(inp.down, prev.down)) { vaultI = (vaultI + 4) % n; sfx.Play("ui", 0.5f); }
		if (P(inp.ok, prev.ok) && T - stateT > 0.3f) VaultAct(vaultI);
		if (P(inp.back, prev.back)) { state = "title"; menuI = 3; }
	}

	void VaultAct(int i) {
		var r = J.RELICS[i];
		if (meta.relics.Contains(r.id)) return;
		if (meta.ngo < J.RELIC_COST) { sfx.Play("block", 0.6f); return; }
		meta.ngo -= J.RELIC_COST;
		meta.relics.Add(r.id);
		SaveMeta();
		sfx.Play("pick");
	}

	void GuiVault() {
		Dim(0.62f);
		Lab(new Rect(0, 22, GW, 54), "BẢO KHỐ", 42, D.PAPER, TextAnchor.MiddleCenter, true);
		Lab(new Rect(0, 72, GW, 26), "NGỘ TÍNH: " + meta.ngo + "   ·   mở một bảo vật vào kho: " + J.RELIC_COST + " NGỘ", 18, new Color(1f, 0.85f, 0.5f));
		float w = 250, h = 120, gap = 14, x0 = (GW - (w * 4 + gap * 3)) / 2;
		for (int i = 0; i < J.RELICS.Length; i++) {
			var r = J.RELICS[i];
			bool open = meta.relics.Contains(r.id), sel = vaultI == i;
			var rc = new Rect(x0 + (i % 4) * (w + gap), 112 + (i / 4) * (h + gap), w, h);
			Panel(rc, sel);
			if (!open) Box(rc, new Color(0.07f, 0.06f, 0.06f, 0.3f));
			Lab(new Rect(rc.x + 8, rc.y + 8, w - 16, 28), r.name, 18, open ? D.INK : new Color(0.35f, 0.33f, 0.31f), TextAnchor.MiddleCenter, true, false);
			Lab(new Rect(rc.x + 12, rc.y + 38, w - 24, 56), r.desc, 13, open ? D.INK : new Color(0.3f, 0.28f, 0.27f), TextAnchor.UpperCenter, false, false);
			Lab(new Rect(rc.x, rc.y + h - 26, w, 22), open ? (meta.seen.Contains(r.id) ? "ĐÃ DÙNG" : "TRONG KHO") : "MỞ: " + J.RELIC_COST + " NGỘ", 13, open ? new Color(0.3f, 0.5f, 0.3f) : D.RED, TextAnchor.MiddleCenter, false, false);
			if (Hit(rc, i)) VaultAct(i);
		}
		Lab(new Rect(0, GH - 40, GW, 28), "WASD chọn   ·   ENTER mở   ·   ESC quay lại", 16, D.PAPER);
	}

	// --- KÝ ỨC: story fragments
	void UnlockMemory(int bossCh) {
		for (int k = 0; k < 3; k++) {
			int id = bossCh * 3 + k;
			if (meta.mem.Contains(id)) continue;
			meta.mem.Add(id);
			Toast("KÝ ỨC MỚI: " + J.MEM_TITLE[id]);
			return;
		}
	}

	void MemoryTick() {
		if (P(inp.up, prev.up)) { memI = (memI + 8) % 9; sfx.Play("ui", 0.5f); }
		if (P(inp.down, prev.down)) { memI = (memI + 1) % 9; sfx.Play("ui", 0.5f); }
		if (P(inp.back, prev.back) || (P(inp.ok, prev.ok) && T - stateT > 0.3f)) { state = "title"; menuI = 4; }
	}

	void GuiMemory() {
		Dim(0.68f);
		Lab(new Rect(0, 22, GW, 54), "KÝ ỨC", 42, D.PAPER, TextAnchor.MiddleCenter, true);
		Lab(new Rect(0, 72, GW, 26), meta.mem.Count + " / 9 mảnh   ·   mỗi lần hạ một trùm mở một mảnh", 16, D.PAPER);
		float lx = (GW - 980) / 2;
		for (int i = 0; i < 9; i++) {
			bool open = meta.mem.Contains(i), sel = memI == i;
			var r = new Rect(lx, 110 + i * 54, 300, 46);
			Box(new Rect(r.x - 3, r.y - 3, r.width + 6, r.height + 6), sel ? D.RED : new Color(0.07f, 0.06f, 0.06f, 0.6f));
			Box(r, open ? D.PAPER : new Color(0.35f, 0.33f, 0.31f));
			Lab(r, open ? J.MEM_TITLE[i] : "· · ·", 17, open ? D.INK : new Color(0.55f, 0.52f, 0.5f), TextAnchor.MiddleCenter, true, false);
			if (!bot && Event.current.type == EventType.MouseDown && r.Contains(Event.current.mousePosition)) memI = i;
		}
		var page = new Rect(lx + 330, 110, 650, 480);
		Panel(page);
		bool o = meta.mem.Contains(memI);
		Lab(new Rect(page.x, page.y + 24, page.width, 44), o ? J.MEM_TITLE[memI] : "CHƯA MỞ", 28, D.INK, TextAnchor.MiddleCenter, true, false);
		Box(new Rect(page.x + 120, page.y + 76, page.width - 240, 2), D.RED);
		Lab(new Rect(page.x + 50, page.y + 100, page.width - 100, 340), o ? J.MEM[memI] : "Hạ " + D.Foe("boss" + (memI / 3 + 1)).name + " để đọc trang này.", 21, D.INK, TextAnchor.UpperLeft, true, false);
		Lab(new Rect(0, GH - 40, GW, 28), "W / S chọn   ·   ESC quay lại", 16, D.PAPER);
	}
}
