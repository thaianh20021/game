using System;
using System.Collections.Generic;
using UnityEngine;

// Weapons found during a run, with rarity and affixes (data in Resources/loot.json, designed with Gemini).
// Rarity: 0 THƯỜNG, 1 HIẾM (+10%, 1 affix), 2 QUÝ (+20%, 2 affixes), 3 TRUYỀN THUYẾT (+30%, 2 affixes + legendary mechanic).
[Serializable] public class AffixDef { public string id, name, desc, hook; public int[] n; public int el = -1; }
[Serializable] public class LegendDef { public string weapon, name, desc; }
[Serializable] public class NameList { public string weapon; public string[] list; }
[Serializable] public class LootData { public AffixDef[] affixes; public LegendDef[] legendary; public NameList[] names; }

public class WeaponItem {
	public string id, name;
	public int rar;
	public List<AffixDef> afx = new List<AffixDef>();
}

public partial class Game {
	public static readonly string[] RAR_NAME = { "THƯỜNG", "HIẾM", "QUÝ", "TRUYỀN THUYẾT" };
	public static readonly Color[] RAR_COL = { new Color(0.72f, 0.7f, 0.66f), new Color(0.35f, 0.6f, 0.95f), new Color(0.72f, 0.42f, 0.95f), new Color(1f, 0.75f, 0.25f) };
	LootData loot;
	WeaponItem wItem;
	readonly List<WeaponItem> wOffers = new List<WeaponItem>();
	bool wHit;           // the HurtFoe in progress comes straight from the weapon (not a splash)
	float stealT;

	void LoadLoot() {
		var ta = Resources.Load<TextAsset>("loot");
		if (ta != null) loot = JsonUtility.FromJson<LootData>(ta.text);
	}

	// sum of one affix kind on the held weapon, at its rarity
	float Afx(string hook) {
		if (wItem == null) return 0;
		float v = 0;
		foreach (var a in wItem.afx) if (a.hook == hook) v += a.n[Mathf.Clamp(wItem.rar, 0, 3)];
		return v;
	}
	bool Legend() { return wItem != null && wItem.rar >= 3; }
	LegendDef LegendOf(string id) { if (loot != null) foreach (var l in loot.legendary) if (l.weapon == id) return l; return null; }

	WeaponItem RollWeapon(int minRar) {
		var types = new List<string>();
		foreach (var w in D.WEAPONS) types.Add(w.id);
		string id = types[rng.Next(types.Count)];
		// better finds deeper in the journey and on higher KIẾP NẠN
		float[] wt = ch == 0 ? new[] { 55f, 32, 11, 2 } : (ch == 1 ? new[] { 35f, 38, 21, 6 } : new[] { 20f, 38, 30, 12 });
		wt[3] += meta.kiep * 0.8f; wt[2] += meta.kiep;
		float tot = 0;
		for (int i = minRar; i < 4; i++) tot += wt[i];
		float x = Rnd() * tot;
		int rar = minRar;
		for (int i = minRar; i < 4; i++) { x -= wt[i]; if (x <= 0) { rar = i; break; } }
		var it = new WeaponItem { id = id, rar = rar, name = D.Weapon(id).name };
		if (loot != null) {
			foreach (var nl in loot.names) if (nl.weapon == id && nl.list.Length > 0 && rar > 0) it.name = nl.list[rng.Next(nl.list.Length)];
			var pool = new List<AffixDef>(loot.affixes);
			int n = rar == 0 ? 0 : (rar == 1 ? 1 : 2);
			for (int k = 0; k < n && pool.Count > 0; k++) { int j = rng.Next(pool.Count); it.afx.Add(pool[j]); pool.RemoveAt(j); }
		}
		return it;
	}

	void EquipWeapon(WeaponItem it) {
		wItem = it;
		weaponId = it.id;
		weapon = D.Weapon(it.id);
		ci = 0; comboT = 0; buf = 0; acd = 0; act = ""; chargeT = 0; frenzy = 0;
		float before = maxHp;
		Recalc();
		swordsHeld = Mathf.Min(swordsHeld + 99, swordMax);
		Toast("CẦM " + it.name + " · " + RAR_NAME[it.rar]);
		sfx.Play("clang", 0.6f, 1.2f);
	}

	// --- where weapons come from
	void OpenWeaponChoice(int n, int minRar) {
		wOffers.Clear();
		for (int i = 0; i < n; i++) wOffers.Add(RollWeapon(minRar));
		state = "wpick"; menuI = 0;
		sfx.Play("pick", 0.8f);
	}

	void DropWeapon(Vector2 at, int minRar) {
		var it = RollWeapon(minRar);
		string spr = it.id == "kiem" ? "rig_sword" : "rigw_" + new Dictionary<string, string> { { "thuong", "spear" }, { "dao", "saber" }, { "chuy", "mace" }, { "phien", "fan" }, { "cung", "bow" } }[it.id];
		AddItem(at, "weapon", it.name + "\n" + RAR_NAME[it.rar], 0, Spr(spr) != null ? spr : "chest", null);
		items[items.Count - 1].wi = it;
		Text(at + new Vector2(0, 150), RAR_NAME[it.rar] + "!", RAR_COL[it.rar], 24);
	}

	void PickWeaponItem(Item it) {
		wOffers.Clear();
		wOffers.Add(it.wi);
		state = "wpick"; menuI = 0;
		pendingGround = it;
	}
	Item pendingGround;

	void WeaponPickAct(int i) {
		if (i < wOffers.Count) {
			var old = wItem;
			EquipWeapon(wOffers[i]);
			// a weapon picked from the ground swaps places with the one in hand
			if (pendingGround != null && old != null) {
				pendingGround.wi = old;
				pendingGround.label = old.name + "\n" + RAR_NAME[old.rar];
				if (pendingGround.sr != null) pendingGround.sr.sprite = WeaponIcon(old.id);
			}
		}
		pendingGround = null;
		state = "play";
		prev.atk = true; inp.atk = false; buf = 0;
	}

	Sprite WeaponIcon(string id) {
		return Spr(id == "kiem" ? "rig_sword" : "rigw_" + new Dictionary<string, string> { { "thuong", "spear" }, { "dao", "saber" }, { "chuy", "mace" }, { "phien", "fan" }, { "cung", "bow" } }[id]);
	}

	void DrawIcon(Sprite s, Rect r, float rot = 0) {
		if (s == null) return;
		var tex = s.texture;
		Rect uv = new Rect(s.textureRect.x / tex.width, s.textureRect.y / tex.height, s.textureRect.width / tex.width, s.textureRect.height / tex.height);
		float k = Mathf.Min(r.width / s.textureRect.width, r.height / s.textureRect.height);
		float w = s.textureRect.width * k, h = s.textureRect.height * k;
		var m = GUI.matrix;
		if (rot != 0) GUIUtility.RotateAroundPivot(rot, r.center);
		GUI.DrawTextureWithTexCoords(new Rect(r.center.x - w / 2, r.center.y - h / 2, w, h), tex, uv);
		GUI.matrix = m;
	}

	void WeaponCard(Rect r, WeaponItem it, bool sel, string head) {
		Panel(r, sel);
		Box(new Rect(r.x, r.y, r.width, 6), RAR_COL[it.rar]);
		Lab(new Rect(r.x, r.y + 12, r.width, 22), head, 14, D.RED, TextAnchor.MiddleCenter, false, false);
		DrawIcon(WeaponIcon(it.id), new Rect(r.x + r.width / 2 - 70, r.y + 30, 140, 96));
		Lab(new Rect(r.x + 8, r.y + 126, r.width - 16, 32), it.name, 22, D.INK, TextAnchor.MiddleCenter, true, false);
		Seal(new Rect(r.x + r.width / 2 - 70, r.y + 160, 140, 24), RAR_NAME[it.rar], RAR_COL[it.rar] * 0.8f, 13);
		var wd = D.Weapon(it.id);
		Lab(new Rect(r.x + 16, r.y + 188, r.width - 32, 78), wd.desc + (it.rar > 0 ? "\nSát thương +" + (it.rar * 10) + "%" : ""), 13, new Color(0.25f, 0.22f, 0.2f), TextAnchor.UpperCenter, false, false);
		float y = r.y + 268;
		foreach (var a in it.afx) {
			string d = a.desc.Replace("{N}", a.n[Mathf.Clamp(it.rar, 0, 3)].ToString());
			Lab(new Rect(r.x + 14, y, r.width - 28, 20), a.name, 14, RAR_COL[Mathf.Max(1, it.rar)] * 0.75f, TextAnchor.MiddleCenter, true, false);
			Lab(new Rect(r.x + 14, y + 19, r.width - 28, 36), d, 13, D.INK, TextAnchor.UpperCenter, false, false);
			y += 58;
		}
		if (it.rar >= 3) {
			var l = LegendOf(it.id);
			if (l != null) {
				Box(new Rect(r.x + 10, y, r.width - 20, 66), new Color(1f, 0.85f, 0.45f, 0.35f));
				Lab(new Rect(r.x + 14, y + 2, r.width - 28, 20), l.name, 15, new Color(0.6f, 0.38f, 0.05f), TextAnchor.MiddleCenter, true, false);
				Lab(new Rect(r.x + 14, y + 22, r.width - 28, 44), l.desc, 13, D.INK, TextAnchor.UpperCenter, false, false);
			}
		}
	}

	void GuiWeaponPick() {
		Dim(0.62f);
		Lab(new Rect(0, 30, GW, 50), "BINH KHÍ", 40, D.PAPER, TextAnchor.MiddleCenter, true);
		Lab(new Rect(0, 78, GW, 26), "A / D chọn   ·   ENTER cầm lấy" + (pendingGround != null ? " (vũ khí đang cầm sẽ để lại chỗ này)" : "") + "   ·   ESC giữ vũ khí cũ", 16, D.PAPER);
		int n = wOffers.Count;
		float w = 300, gap = 26, x0 = (GW - (w * (n + 1) + gap * n)) / 2;
		if (wItem != null) { WeaponCard(new Rect(x0, 120, w, 470), wItem, false, "ĐANG CẦM"); Box(new Rect(x0, 120, w, 470), new Color(0.07f, 0.06f, 0.06f, 0.18f)); }
		for (int i = 0; i < n; i++) {
			var r = new Rect(x0 + (i + 1) * (w + gap), menuI == i ? 108 : 120, w, 470);
			WeaponCard(r, wOffers[i], menuI == i, "TÌM THẤY");
			if (Hit(r, i)) WeaponPickAct(i);
		}
	}

	void GuiWeaponHud() {
		if (wItem == null) return;
		Lab(new Rect(GW / 2 - 260, GH - 76, 520, 24), wItem.name + (wItem.rar > 0 ? " · " + RAR_NAME[wItem.rar] : ""), 15, RAR_COL[wItem.rar], TextAnchor.MiddleCenter, true);
	}

	// --- affix effects on the weapon's own hits (called from HurtFoe with the damage before it is applied)
	float WeaponHitMul(Foe f, ref float posMul) {
		float m = 1 + wItem.rar * 0.1f;
		if (hp < maxHp * 0.5f) m *= 1 + Afx("low_hp_dmg") / 100f;
		posMul *= 1 + Afx("posture_mul") / 100f;
		return m;
	}

	void WeaponHitAfter(Foe f, float dmg) {
		foreach (var a in wItem.afx) {
			if (a.hook == "on_hit_elem" && a.el >= 0 && !f.dead && Rnd() * 100 < a.n[wItem.rar]) ApplyEl(f, a.el, 1, true);
		}
		float ls = Afx("lifesteal_pct");
		if (ls > 0 && T - stealT > 0.15f) { stealT = T; Heal(Mathf.Min(4, dmg * ls / 100f)); }
	}

	// --- legendary mechanics, one per weapon type
	void LegendStrike(bool last) {
		if (!Legend()) return;
		int el = SlotEl("atk"), lv = Mathf.Max(1, SlotLv("atk"));
		switch (weapon.id) {
			case "kiem":
				if (!last) break;
				for (int k = -1; k <= 1; k++) swords.Add(new FSword { pos = ppos + new Vector2(0, 55), vel = (Vector2)(Quaternion.Euler(0, 0, k * 12) * adir) * 1700 });
				Burst(ppos + adir * 95, 115, 24 * dmgMul, D.KIM, lv, true);
				break;
			case "thuong":
				shots.Add(new Shot { pos = ppos + new Vector2(0, 55), vel = adir * 1150, dmg = 16 * dmgMul, mine = true, pierce = 3, el = el, lvl = lv, r = 12, life = 0.5f, hit = new List<Foe>() });
				if (last) Burst(ppos + adir * 140, 130, 28 * dmgMul, D.THO, lv, true);
				break;
			case "dao":
				if (ci % 2 == 1) shots.Add(new Shot { pos = ppos + new Vector2(0, 55), vel = adir * 980, dmg = 12 * dmgMul, mine = true, pierce = 1, el = D.HOA, lvl = lv, r = 12, life = 0.45f, hit = new List<Foe>() });
				if (last) Burst(ppos, 140, 30 * dmgMul, D.HOA, lv, true);
				break;
			case "chuy":
				Burst(ppos + adir * 100, last ? 195 : 110, (last ? 40 : 16) * dmgMul, D.THO, lv, true);
				break;
			case "phien":
				if (!last) break;
				for (int k = -1; k <= 1; k += 2) shots.Add(new Shot { pos = ppos + new Vector2(0, 55), vel = (Vector2)(Quaternion.Euler(0, 0, k * 14) * adir) * 980, dmg = 14 * dmgMul, mine = true, pierce = 1, el = D.THUY, lvl = lv, r = 12, life = 0.6f, hit = new List<Foe>() });
				Burst(ppos + adir * 160, 130, 24 * dmgMul, D.THUY, lv, true);
				break;
		}
	}

	void LegendBow() {
		if (!Legend() || weapon.id != "cung") return;
		for (int k = -1; k <= 1; k++) shots.Add(new Shot { pos = ppos + new Vector2(0, 55), vel = (Vector2)(Quaternion.Euler(0, 0, k * 8) * aimDir) * 1250, dmg = 15 * dmgMul, mine = true, pierce = 2, el = D.MOC, lvl = 1, r = 11, life = 0.8f, hit = new List<Foe>() });
		Burst(ppos + aimDir * 220, 115, 22 * dmgMul, D.MOC, 1, true);
	}
}
