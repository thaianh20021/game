using System.Collections.Generic;
using UnityEngine;

// Tuyet ky: four great arts on [F] with a cooldown, each with a tree of three upgrades bought for good
// with NGO TINH. Also the weapon mechanics that need state (bow charge, twin-blade frenzy).
public class PBlast { public Vector2 pos; public float t, wind, r, dmg; public bool big; }

public partial class Game {
	readonly List<PBlast> pblasts = new List<PBlast>();
	float tkCd, bellT, bellTick, kvT, chargeT, frenzy, frenzyT, chainT;
	int chain;
	float skidT, recallT, catchT, castT;   // short pose timers for the hero's frames
	int bellL;
	Vector2 kvPos;
	int skCol, skRow;

	int SkLv(string id) { int i = meta.skIds.IndexOf(id); return i < 0 ? 0 : meta.skLv[i]; }
	void SetSk(string id, int v) { int i = meta.skIds.IndexOf(id); if (i < 0) { meta.skIds.Add(id); meta.skLv.Add(v); } else meta.skLv[i] = v; }

	void CastTK() {
		var sd = D.Skill(meta.tk);
		int L = SkLv(sd.id);
		if (L <= 0) return;
		tkCd = sd.cd * (Has("ngoctuy") ? 0.7f : 1);
		castT = 0.42f;
		int el = SlotEl("atk"), lv = SlotLv("atk");
		Text(ppos + new Vector2(0, 170), sd.name, new Color(1f, 0.9f, 0.55f), 28);
		sfx.Play("skill"); sfx.Play("gong", 0.5f, 1.4f);
		shake = Mathf.Max(shake, 9);
		guard = false;
		switch (sd.id) {
			case "kiemvu": {
				Vector2 c = ppos + Vector2.ClampMagnitude(inp.aim - ppos, 620);
				int n = L >= 2 ? 28 : 14;
				float R = L >= 3 ? 390 : 260;
				for (int i = 0; i < n; i++) pblasts.Add(new PBlast { pos = Confine(c + RndDir() * Rnd(0, R), 6), wind = 0.3f + i * (1.3f / n), r = 78, dmg = 18 * dmgMul });
				if (L >= 3) { kvT = 1.7f; kvPos = c; }
				if (L >= 4) pblasts.Add(new PBlast { pos = Confine(c, 6), wind = 1.9f, r = 240, dmg = 150 * dmgMul, big = true });
				break;
			}
			case "chi": {
				float a0 = Mathf.Atan2(aimDir.y, aimDir.x);
				float[] offs = L >= 3 ? new[] { -0.24f, 0f, 0.24f } : new[] { 0f };
				foreach (float o in offs) {
					Vector2 d = new Vector2(Mathf.Cos(a0 + o), Mathf.Sin(a0 + o));
					slashes.Add(new Slash { pos = ppos + new Vector2(0, 55), dir = d, line = true, len = 950, wid = 70, col = new Color(1f, 0.85f, 0.4f) });
					foreach (var f in new List<Foe>(foes)) {
						if (f.dead || f.spawn > 0 || !LineHit(ppos, d, 950, 70, f.pos, f.d.r * f.scale)) continue;
						HurtFoe(f, 70 * (L >= 2 ? 2 : 1) * dmgMul, el, lv, 3, d);
						if (f.dead) continue;
						if (L >= 2) f.bleed = 6;
						if (L >= 4) AddPosture(f, f.d.boss ? f.posMax * 0.5f : f.posMax * 2);
					}
				}
				stop = Mathf.Max(stop, 0.08f);
				break;
			}
			case "chung":
				bellL = L; bellT = L >= 2 ? 4f : 2.5f; bellTick = 0.5f;
				Burst(ppos, 260, 30 * dmgMul, -1, 0, false);
				break;
			case "anh": {
				var list = new List<Foe>();
				foreach (var f in foes) if (!f.dead && f.spawn <= 0 && (f.pos - ppos).magnitude < 900) list.Add(f);
				if (list.Count == 0) { tkCd = 0.5f; break; }
				Vector2 from = ppos;
				list.Sort((a, b) => (a.pos - from).sqrMagnitude.CompareTo((b.pos - from).sqrMagnitude));
				int n = Mathf.Min(list.Count, L >= 2 ? 10 : 5);
				for (int i = 0; i < n; i++) {
					var f = list[i];
					Vector2 d = (f.pos - ppos).sqrMagnitude > 1 ? (f.pos - ppos).normalized : aimDir;
					AddGhost(heroSr, ppos, new Color(0.07f, 0.06f, 0.08f, 0.7f), 0.35f + i * 0.04f);
					slashes.Add(new Slash { pos = ppos + new Vector2(0, 50), dir = d, line = true, len = (f.pos - ppos).magnitude + 90, wid = 46, col = D.INK });
					ppos = Confine(f.pos + d * 60, 22);
					face = d.x >= 0 ? 1 : -1;
					if (L >= 4 && !f.d.boss && f.hp < f.maxHp * 0.25f) { Kill(f); tkCd -= 2; continue; }
					HurtFoe(f, 35 * dmgMul, el, lv, 1.5f, d);
					if (L >= 3 && SlotEl("dash") >= 0 && !f.dead) ApplyEl(f, SlotEl("dash"), SlotLv("dash"), true);
				}
				inv = Mathf.Max(inv, 0.6f);
				stop = Mathf.Max(stop, 0.1f);
				break;
			}
		}
	}

	void UpSkills(float dt) {
		tkCd -= dt;
		frenzyT -= dt;
		if (frenzyT <= 0) frenzy = 0;
		chainT -= dt;
		skidT -= dt; recallT -= dt; catchT -= dt; castT -= dt; throwT -= dt;
		if (chainT <= 0) chain = 0;
		if (P(inp.tk, prev.tk) && tkCd <= 0 && act != "dash") CastTK();
		for (int i = pblasts.Count - 1; i >= 0; i--) {
			var b = pblasts[i];
			b.t += dt;
			if (b.t < b.wind) continue;
			pblasts.RemoveAt(i);
			Burst(b.pos, b.r, b.dmg, SlotEl("atk"), SlotLv("atk"), true);
			if (b.big) {
				foreach (var f in foes) if (!f.dead && (f.pos - b.pos).magnitude < b.r + f.d.r) AddPosture(f, f.d.boss ? f.posMax * 0.6f : f.posMax * 2);
				shake = Mathf.Max(shake, 16); stop = Mathf.Max(stop, 0.1f);
				sfx.Play("gong");
			} else sfx.Play("hit", 0.35f, 1.4f);
		}
		if (kvT > 0) {
			kvT -= dt;
			foreach (var f in foes) {
				if (f.dead || f.d.boss || f.spawn > 0) continue;
				Vector2 d = kvPos - f.pos;
				if (d.magnitude < 520 && d.magnitude > 30) f.pos += d.normalized * 240 * dt;
			}
		}
		if (bellT > 0) {
			bellT -= dt;
			inv = Mathf.Max(inv, 0.12f);
			if (bellL >= 2) foreach (var s in shots) {
				if (s.mine || (s.pos - new Vector2(0, 55) - ppos).magnitude > 115) continue;
				s.mine = true; s.vel = -s.vel * 1.4f; s.dmg *= 3; s.life = 2; s.pool = false; s.hit = new List<Foe>();
			}
			if (bellL >= 3) {
				bellTick -= dt;
				if (bellTick <= 0) { bellTick = 0.5f; Burst(ppos, 220, 14 * dmgMul, D.THO, 1, false); }
			}
			if (bellT <= 0 && bellL >= 4) { Burst(ppos, 430, 120 * dmgMul, -1, 0, false); Heal(15); shake = 16; sfx.Play("gong"); }
		}
	}

	// the bow: hold to draw, let go to loose
	void FireBow() {
		float u = Mathf.Clamp01(chargeT / 1.1f);
		int el = SlotEl("atk"), lv = SlotLv("atk");
		float mult = dmgMul * (1 + lv * 0.15f) * (riposte ? 1 + Lv("ripo") : 1);
		riposte = false;
		bool full = u >= 0.99f;
		shots.Add(new Shot { pos = ppos + new Vector2(0, 55), vel = aimDir * (1200 + 700 * u), dmg = (10 + 62 * u * u) * mult * (full ? 1.3f : 1), mine = true, el = el, lvl = lv,
			pierce = full ? 50 : (u > 0.5f ? 2 : 0), r = 11 + 7 * u, life = 0.9f, hit = new List<Foe>() });
		face = aimDir.x >= 0 ? 1 : -1;
		sfx.Play("shoot", 0.5f + 0.4f * u, 1.2f - 0.4f * u);
		if (full) { shake = Mathf.Max(shake, 6); ppos = Confine(ppos - aimDir * 30, 22); }
		chargeT = 0;
		acd = 0.12f;
	}

	void DrawSkills() {
		foreach (var b in pblasts) {
			float u = Mathf.Clamp01(b.t / b.wind), k = b.big ? 3 : 1;
			ground.Ring(b.pos, b.r, 3, new Color(0.93f, 0.9f, 0.8f, 0.25f + 0.4f * u), 28);
			if (u < 0.55f) continue;
			float fall = (1 - (u - 0.55f) / 0.45f) * 900;
			Vector2 tip = b.pos + new Vector2(fall * 0.25f, fall), top = tip + new Vector2(22, 90) * k;
			fxInk.Brush(top, tip, 14 * k, D.INK);
			fxInk.Brush(top - new Vector2(2, 8), tip + new Vector2(2, 8), 5 * k, new Color(0.93f, 0.95f, 0.97f));
		}
		if (bellT > 0) {
			float a = Mathf.Clamp01(bellT) * (0.6f + 0.2f * Mathf.Sin(T * 9));
			Color g = new Color(1f, 0.85f, 0.4f, a);
			fxInk.Ring(ppos + new Vector2(0, 55), 78, 7, g, 32);
			fxInk.Ring(ppos + new Vector2(0, 55), 62, 3, g, 32);
			ground.Ellipse(ppos, 86, 34, new Color(1f, 0.85f, 0.4f, a * 0.3f));
		}
		if (chargeT > 0) {
			float u = Mathf.Clamp01(chargeT / 1.1f);
			fxInk.Ring(ppos + new Vector2(0, 55), 50, u >= 0.99f ? 8 : 5, u >= 0.99f ? new Color(1f, 0.9f, 0.5f) : new Color(0.93f, 0.9f, 0.8f, 0.8f), 24, 0, Mathf.PI * 2 * u);
			ground.Line(ppos + aimDir * 60, ppos + aimDir * (200 + 600 * u), 3, new Color(0.07f, 0.06f, 0.06f, 0.35f));
		}
	}

	void GuiSkillHud() {
		var sd = D.Skill(meta.tk);
		if (SkLv(sd.id) <= 0) return;
		float w = 250, x = (GW - w) / 2, y = GH - 46;
		Box(new Rect(x - 3, y - 3, w + 6, 34), D.INK);
		Box(new Rect(x, y, w, 28), new Color(0.2f, 0.17f, 0.16f));
		float u = tkCd <= 0 ? 1 : 1 - Mathf.Clamp01(tkCd / sd.cd);
		Box(new Rect(x, y, w * u, 28), tkCd <= 0 ? new Color(0.7f, 0.5f, 0.15f) : new Color(0.35f, 0.3f, 0.26f));
		Lab(new Rect(x, y, w, 28), "[F] " + sd.name + (tkCd > 0 ? "  " + Mathf.CeilToInt(tkCd) : ""), 15, tkCd <= 0 ? Color.white : new Color(0.8f, 0.78f, 0.72f));
		if (chain >= 3) Lab(new Rect(GW - 330, 250, 300, 44), "LIÊN TRẢM ×" + chain, 24 + Mathf.Min(14, chain / 3), new Color(1f, 0.6f, 0.3f, Mathf.Clamp01(chainT)), TextAnchor.MiddleRight, true);
		Lab(new Rect(GW - 520, 90, 496, 22), D.Sect(meta.sect).name, 14, D.PAPER, TextAnchor.MiddleRight);
		if (frenzy > 0) Lab(new Rect(x, y - 30, w, 24), "CUỒNG ĐAO ×" + (int)frenzy, 16, new Color(1f, 0.6f, 0.3f));
	}

	void GuiSect() {
		Dim(0.6f);
		Lab(new Rect(0, 40, GW, 60), "CHỌN MÔN PHÁI", 44, D.PAPER, TextAnchor.MiddleCenter, true);
		Lab(new Rect(0, 96, GW, 26), "KIẾM HỒN: " + meta.hon + "   ·   rơi ra khi hạ trùm", 17, new Color(0.75f, 0.85f, 1f));
		int n = D.SECTS.Length;
		float w = Mathf.Min(290, (GW - 60) / n - 16), gap = 16, x0 = (GW - (w * n + gap * (n - 1))) / 2;
		for (int i = 0; i < n; i++) {
			var sd = D.SECTS[i];
			bool sel = menuI == i;
			var r = new Rect(x0 + i * (w + gap), sel ? 140 : 155, w, 400);
			Panel(r, sel);
			Lab(new Rect(r.x, r.y + 24, w, 44), sd.name, 21, D.INK, TextAnchor.MiddleCenter, true, false);
			Box(new Rect(r.x + 40, r.y + 74, w - 80, 2), D.RED);
			Lab(new Rect(r.x + 20, r.y + 84, w - 40, 60), "“" + sd.motto + "”", 15, new Color(0.3f, 0.27f, 0.25f), TextAnchor.MiddleCenter, true, false);
			Lab(new Rect(r.x + 22, r.y + 160, w - 44, 220), sd.desc, 17, D.INK, TextAnchor.UpperCenter, false, false);
			if (!SectOpen(i)) {
				Box(r, new Color(0.07f, 0.06f, 0.06f, 0.45f));
				Lab(new Rect(r.x, r.yMax - 70, w, 50), "KHÓA · " + J.SECT_COST[i] + " KIẾM HỒN\nENTER để mở", 17, meta.hon >= J.SECT_COST[i] ? new Color(1f, 0.85f, 0.5f) : D.PAPER, TextAnchor.MiddleCenter, true);
			}
			if (Hit(r, i)) SectAct(i);
		}
		Lab(new Rect(0, GH - 80, GW, 30), "A / D chọn   ·   ENTER chọn (hoặc mở khóa)   ·   ESC quay lại", 18, D.PAPER);
	}

	void GuiElites() {
		foreach (var f in foes) {
			if (!f.elite || f.dead || f.spawn > 0) continue;
			Vector2 g = W2G(f.pos + new Vector2(0, f.z + f.d.h * f.scale + 46));
			Lab(new Rect(g.x - 120, g.y - 12, 240, 24), "TINH ANH · " + D.AfxName(f.afx), 13, new Color(1f, 0.45f, 0.35f));
		}
	}

	// --- the skill tree screen (title menu)
	void SkillsTick() {
		int n = D.SKILLS.Length;
		if (P(inp.left, prev.left)) { skCol = (skCol + n - 1) % n; sfx.Play("ui", 0.5f); }
		if (P(inp.right, prev.right)) { skCol = (skCol + 1) % n; sfx.Play("ui", 0.5f); }
		if (P(inp.up, prev.up)) { skRow = (skRow + 3) % 4; sfx.Play("ui", 0.5f); }
		if (P(inp.down, prev.down)) { skRow = (skRow + 1) % 4; sfx.Play("ui", 0.5f); }
		if (P(inp.ok, prev.ok) && T - stateT > 0.3f) SkillAct();
		if (P(inp.back, prev.back)) { state = "title"; menuI = 1; }
	}

	void SkillAct() {
		var sd = D.SKILLS[skCol];
		int L = SkLv(sd.id);
		if (skRow == 0) {
			if (L == 0) {
				if (meta.ngo < D.SK_COST[0]) { sfx.Play("block", 0.6f); return; }
				meta.ngo -= D.SK_COST[0];
				SetSk(sd.id, 1);
			}
			meta.tk = sd.id;
		} else {
			if (L != skRow || meta.ngo < D.SK_COST[skRow]) { sfx.Play("block", 0.6f); return; }
			meta.ngo -= D.SK_COST[skRow];
			SetSk(sd.id, L + 1);
		}
		SaveMeta();
		sfx.Play("pick");
	}

	void GuiSkills() {
		Dim(0.62f);
		Lab(new Rect(0, 22, GW, 54), "TUYỆT KỸ", 42, D.PAPER, TextAnchor.MiddleCenter, true);
		Lab(new Rect(0, 74, GW, 28), "NGỘ TÍNH: " + meta.ngo, 20, new Color(1f, 0.85f, 0.5f));
		int n = D.SKILLS.Length;
		float w = Mathf.Min(300, (GW - 60) / n - 14), gap = 14, x0 = (GW - (w * n + gap * (n - 1))) / 2;
		for (int c = 0; c < n; c++) {
			var sd = D.SKILLS[c];
			int L = SkLv(sd.id);
			bool used = meta.tk == sd.id && L > 0;
			float x = x0 + c * (w + gap);
			var head = new Rect(x, 112, w, 176);
			Panel(head, skCol == c && skRow == 0);
			Lab(new Rect(x, 120, w, 34), sd.name, 22, L > 0 ? D.INK : new Color(0.4f, 0.38f, 0.36f), TextAnchor.MiddleCenter, true, false);
			Lab(new Rect(x + 14, 156, w - 28, 74), sd.desc, 14, D.INK, TextAnchor.UpperCenter, false, false);
			Lab(new Rect(x, 232, w, 22), "Hồi chiêu " + sd.cd + " giây", 13, new Color(0.3f, 0.27f, 0.25f), TextAnchor.MiddleCenter, false, false);
			if (used) Seal(new Rect(x + w / 2 - 60, 256, 120, 24), "ĐANG DÙNG", D.RED, 13);
			else Lab(new Rect(x, 256, w, 24), L > 0 ? "ENTER: dùng chiêu này" : "MỞ: " + D.SK_COST[0] + " NGỘ", 14, L > 0 || meta.ngo >= D.SK_COST[0] ? D.RED : new Color(0.45f, 0.42f, 0.4f), TextAnchor.MiddleCenter, false, false);
			for (int k = 1; k <= 3; k++) {
				var r = new Rect(x, 300 + (k - 1) * 122, w, 110);
				bool own = L > k, next = L == k;
				Panel(r, skCol == c && skRow == k);
				if (!own && !next) Box(r, new Color(0.07f, 0.06f, 0.06f, 0.35f));
				Lab(new Rect(x + 10, r.y + 6, w - 20, 26), sd.node[k - 1], 17, own ? D.RED : D.INK, TextAnchor.MiddleCenter, true, false);
				Lab(new Rect(x + 12, r.y + 32, w - 24, 52), sd.nodeDesc[k - 1], 13, D.INK, TextAnchor.UpperCenter, false, false);
				Lab(new Rect(x, r.y + 84, w, 22), own ? "ĐÃ LUYỆN" : D.SK_COST[k] + " NGỘ", 13, own ? new Color(0.3f, 0.5f, 0.3f) : (next && meta.ngo >= D.SK_COST[k] ? D.RED : new Color(0.45f, 0.42f, 0.4f)), TextAnchor.MiddleCenter, false, false);
			}
		}
		Lab(new Rect(0, GH - 44, GW, 28), "A / D đổi chiêu   ·   W / S chọn tầng   ·   ENTER luyện hoặc dùng   ·   ESC quay lại", 16, D.PAPER);
	}
}
