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
		// from the design review with Gemini: relics that change how a build plays, not just its numbers
		R("nghichhanh", 1, "NGHỊCH HÀNH ẤN", "Đảo ngũ hành: cặp khắc nhau nổ TƯƠNG SINH (+40%), cặp sinh nhau gây TƯƠNG KHẮC."),
		R("tumau", 1, "TỬ MẪU KIẾM HẠP", "Đỡ chuẩn phóng 2 phi kiếm vào kẻ đánh và gọi mọi phi kiếm về; kiếm về mạnh hơn 50%."),
		R("thienquan", 1, "THIÊN QUÂN XÍCH", "Địch bị PHÁ THẾ truyền 80% THẾ sang địch quanh nó và kéo chúng lại gần."),
		R("thaicuc", 1, "THÁI CỰC NGỌC BỘI", "Nhát cuối liên hoàn tự mang hành KHẮC với ẤN trên địch."),
		R("thoathe", 0, "THỔ THẦN GIÁP", "TƯƠNG SINH kết thúc bằng THỔ cho một lớp giáp chặn 1 đòn."),
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
	int rerolls;
	bool spreading;
	float thietT = -9, shieldT;

	static int KhacOf(int el) {
		for (int k = 0; k < 5; k++) if (k != el && D.Relation(el, k) == 2) return k;
		return (el + 2) % 5;
	}

	// what the finishing element of a TƯƠNG SINH adds to the burst
	void SinhExtra(Foe f, int el, int lvl) {
		switch (el) {
			case D.KIM:   // three blades of sword energy fly out of the burst
				for (int k = 0; k < 3; k++) {
					float a = Rnd(0, Mathf.PI * 2);
					shots.Add(new Shot { pos = f.pos + new Vector2(0, 55), vel = new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 900, dmg = 18 * dmgMul, mine = true, pierce = 3, r = 12, life = 0.6f, hit = new List<Foe>() });
				}
				break;
			case D.MOC: Heal(3); break;   // the burst draws life
			case D.THUY: tkCd = Mathf.Max(0, tkCd - 1.5f); qi = Mathf.Min(100, qi + 15); break;
			case D.HOA: pblasts.Add(new PBlast { pos = f.pos, wind = 0.6f, r = 110, dmg = 45 * dmgMul }); break;   // a pillar of fire a moment later
			case D.THO:
				if (Has("thoathe") || lvl >= 2) { shieldT = 4; Text(ppos + new Vector2(0, 160), "THỔ GIÁP", D.EL_COL[D.THO], 20); }
				break;
		}
	}

	void Reroll() {
		if (rerolls <= 0) { sfx.Play("block", 0.5f); return; }
		rerolls--;
		if (state == "relic") OpenRelic();
		else OpenPick(pickKind, pickBonus);
		Toast("NGHỊCH MỆNH: còn " + rerolls + " lần đổi");
	}

	bool Has(string id) { return relics.Contains(id); }
	bool HeatAt(int n) { return meta.kiep >= n; }

	// --- effects that other files call
	float HurtTakenMul() {
		if (shieldT > 0) { shieldT = 0; Text(ppos + new Vector2(0, 150), "CHẶN", D.EL_COL[D.THO], 22); return 0; }
		return (Has("kimcang") ? 0.85f : 1) * (Has("cuongbao") ? 1.15f : 1);
	}
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
		Lab(new Rect(0, 94, GW, 28), "A / D chọn   ·   ENTER nhận" + (rerolls > 0 ? "   ·   R đổi lựa chọn (" + rerolls + ")" : ""), 16, D.PAPER);
		float w = 300, gap = 28, x0 = (GW - (w * relicOffers.Count + gap * (relicOffers.Count - 1))) / 2;
		for (int i = 0; i < relicOffers.Count; i++) {
			var r = relicOffers[i];
			bool sel = menuI == i;
			var rc = new Rect(x0 + i * (w + gap), sel ? 150 : 166, w, 360);
			Panel(rc, sel);
			var ric = Spr("icon_" + r.id);
			if (ric != null) DrawIcon(ric, new Rect(rc.x + w / 2 - 46, rc.y + 14, 92, 80));
			else Seal(new Rect(rc.x + w / 2 - 40, rc.y + 26, 80, 62), r.name.Substring(0, 1), r.rare > 0 ? new Color(0.55f, 0.32f, 0.7f) : new Color(0.62f, 0.45f, 0.2f), 18);
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
			var hic = Spr("icon_" + r.id);
			Box(rc, new Color(0.07f, 0.06f, 0.06f, 0.55f));
			if (hic != null) DrawIcon(hic, new Rect(rc.x + 1, rc.y + 1, rc.width - 2, rc.height - 2));
			else Seal(rc, r.name.Substring(0, 1), r.rare > 0 ? new Color(0.55f, 0.32f, 0.7f) : new Color(0.62f, 0.45f, 0.2f), 14);
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
		if (P(inp.up, prev.up)) { vaultI = (vaultI + n - 5) % n; sfx.Play("ui", 0.5f); }
		if (P(inp.down, prev.down)) { vaultI = (vaultI + 5) % n; sfx.Play("ui", 0.5f); }
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
		float w = 220, h = 106, gap = 10, x0 = (GW - (w * 5 + gap * 4)) / 2;
		for (int i = 0; i < J.RELICS.Length; i++) {
			var r = J.RELICS[i];
			bool open = meta.relics.Contains(r.id), sel = vaultI == i;
			var rc = new Rect(x0 + (i % 5) * (w + gap), 108 + (i / 5) * (h + gap), w, h);
			Panel(rc, sel);
			if (!open) Box(rc, new Color(0.07f, 0.06f, 0.06f, 0.3f));
			DrawIcon(Spr("icon_" + r.id), new Rect(rc.x + 6, rc.y + 6, 34, 34));
			Lab(new Rect(rc.x + 40, rc.y + 8, w - 46, 28), r.name, 16, open ? D.INK : new Color(0.35f, 0.33f, 0.31f), TextAnchor.MiddleCenter, true, false);
			Lab(new Rect(rc.x + 10, rc.y + 34, w - 20, 50), r.desc, 12, open ? D.INK : new Color(0.3f, 0.28f, 0.27f), TextAnchor.UpperCenter, false, false);
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

	// --- sect manuals (see Data.cs, "sect manuals")
	bool inParry, inSectBurst;
	float lienT;

	// a heal can become a blast instead (HUYẾT NGUYỆT) or spill over into one (THIẾT Y); true = the heal was used up
	bool SectHeal(float v) {
		if (inSectBurst) return false;
		if (Lv("c_hien") > 0 && hp < maxHp * 0.5f) {
			inSectBurst = true;
			Burst(ppos, 145, v * 5 * Lv("c_hien"), -1, 1, false);
			inSectBurst = false;
			return true;
		}
		float over = hp + v - maxHp;
		if (Lv("t_huyet") > 0 && over > 0.5f) {
			inSectBurst = true;
			Burst(ppos, 150, over * 4 * Lv("t_huyet"), -1, 1, false);
			inSectBurst = false;
		}
		return false;
	}

	void SectParry(Foe src) {
		if (Lv("t_tinh") > 0) { tkCd = Mathf.Max(0, tkCd - 2 * Lv("t_tinh")); qi = Mathf.Min(100, qi + 6 * Lv("t_tinh")); }
		if (Lv("t_xuyen") > 0 && src != null && !src.dead) {
			bool was = src.broken > 0;
			AddPosture(src, 20 * Lv("t_xuyen"));
			if (!was && src.broken > 0) Heal(5 * Lv("t_xuyen"));
		}
		if (Lv("k_phan") > 0) { inParry = true; RecallSwords(); inParry = false; }
	}

	void SectKill(Foe f) {
		if (Lv("k_truy") > 0) {
			foreach (var s in swords) {
				if (s.st != 1 || s.host != f) continue;
				Foe next = null;
				foreach (var o in foes) if (!o.dead && o != f && o.spawn <= 0 && (next == null || (o.pos - f.pos).sqrMagnitude < (next.pos - f.pos).sqrMagnitude)) next = o;
				s.host = null;
				if (next == null) continue;
				s.st = 0; s.t = 0; s.hit.Clear();
				s.vel = (next.pos - f.pos).normalized * 1700;
				qi = Mathf.Min(100, qi + 4 * Lv("k_truy"));
			}
		}
		if (Lv("h_truyen") > 0 && f.mark >= 0) {
			var near = new List<Foe>();
			foreach (var o in foes) if (!o.dead && o != f) near.Add(o);
			near.Sort((a, b) => (a.pos - f.pos).sqrMagnitude.CompareTo((b.pos - f.pos).sqrMagnitude));
			for (int k = 0; k < near.Count && k < 2 * Lv("h_truyen"); k++) ApplyEl(near[k], f.mark, 1, true);
			qi = Mathf.Min(100, qi + 5 * Lv("h_truyen"));
		}
	}

	// before the element lands: hitting a mark with the same element resonates
	void SectElement(Foe f, int el, int lvl) {
		if (Lv("h_dong") <= 0 || f.mark != el || inSectBurst) return;
		inSectBurst = true;
		Burst(f.pos, 90, 12 * Lv("h_dong") * dmgMul, -1, lvl, false);
		AddPosture(f, 15 * Lv("h_dong"));
		inSectBurst = false;
	}

	// after a direct hit (not splash): kill-streak shockwaves and last-stand inner force
	void SectHit(Foe f) {
		if (Lv("c_lien") > 0 && chain > 0 && !inSectBurst && T - lienT > 0.35f) {
			lienT = T;
			int c = Mathf.Min(chain, 15);
			inSectBurst = true;
			Burst(f.pos, 80 + c * 8, 4 * c * Lv("c_lien") * dmgMul, -1, 1, false);
			inSectBurst = false;
		}
		if (Lv("c_tuyet") > 0 && hp <= maxHp * 0.35f) { qi = Mathf.Min(100, qi + 3 * Lv("c_tuyet")); tkCd = Mathf.Max(0, tkCd - 1 * Lv("c_tuyet")); }
	}

	// --- icons drawn with Gemini (tools/icons.sh); manuals of the sects share one
	Sprite BoonIcon(Boon b) { return b.sect != "" ? Spr("icon_sect") : Spr("icon_" + b.id); }

	Sprite GateIcon(string kind) {
		switch (kind) {
			case "bikip": return Spr("icon_bikip");
			case "luyen": return Spr("icon_lantern");
			case "dan": return Spr("icon_hp");
			case "ngan": return Spr("icon_ngan");
			case "bao": return Spr("icon_thaicuc");
			case "binh": return WeaponIcon("kiem");
			case "ky": return Spr("icon_tra");
		}
		return null;
	}
}
