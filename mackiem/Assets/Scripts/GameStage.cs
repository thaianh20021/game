using System.Collections.Generic;
using UnityEngine;

// The world is one continuous map walked from the bottom up: for each chapter four fight grounds,
// a rest stop and a painted boss arena, joined without loading. Also the flying swords.
public class Seg {
	public string kind;         // fight, rest, pass, boss
	public int ch, step, state; // state: 0 untouched, 1 being fought, 2 done
	public Rect r;
}

public class FSword {
	public Vector2 pos, vel, off;
	public int st;              // 0 flying out, 1 stuck (in a foe or the ground), 2 flying home
	public Foe host;
	public float t;
	public List<Foe> hit = new List<Foe>();
}

public partial class Game {
	public const float CX = 2000;                          // every segment is centred on this x
	public static Rect VR = new Rect(0, 0, 1920, 1288);   // what the camera may show
	bool stage = true;
	float capY = 1e9f;
	float yLo, yHi = 1e9f, worldTop;                      // how far down and up anyone may walk right now
	readonly List<Seg> segs = new List<Seg>();
	readonly List<Rect> paints = new List<Rect>();
	Seg fight;                                             // the segment being fought, or null
	readonly List<SpriteRenderer> deco = new List<SpriteRenderer>();
	readonly List<SpriteRenderer> tiles = new List<SpriteRenderer>();
	readonly List<FSword> swords = new List<FSword>();
	int swordMax = 4, swordsHeld = 4;
	float thrCd;

	int Busy() { int n = 0; foreach (var f in foes) if (!f.dead && f.mv != null) n++; return n; }

	int SegIndex(float y) {
		for (int i = 0; i < segs.Count; i++) if (y < segs[i].r.yMax) return i;
		return segs.Count - 1;
	}
	Seg SegAt(float y) { return segs[SegIndex(y)]; }

	void ClearStage() {
		foreach (var d in deco) if (d != null) Destroy(d.gameObject);
		foreach (var t in tiles) if (t != null) Destroy(t.gameObject);
		deco.Clear(); tiles.Clear(); swords.Clear(); segs.Clear(); paints.Clear(); pblasts.Clear();
		swordsHeld = swordMax;
		fight = null;
		bellT = 0; kvT = 0; chargeT = 0; frenzy = 0;
	}

	void AddProp(string n, Vector2 p) {
		float h = n == "bamboo" || n == "pine" ? 190 : (n == "jar" ? 80 : 120);
		props.Add(new Prop { pos = p, r = n == "bamboo" || n == "jar" ? 30 : 46, sr = NewSpr(n, h) });
	}

	// scenery answers a blade: jars break and spill coins, plants shake and shed leaves
	void HitProp(int i) {
		var pr = props[i];
		string n = pr.sr.gameObject.name;
		pr.shake = 0.35f;
		if (n == "jar") {
			int c = Mathf.RoundToInt((2 + rng.Next(4)) * coinMul);
			coins += c;
			Text(pr.pos + new Vector2(0, 90), "+" + c + " lượng", new Color(1f, 0.85f, 0.4f), 17);
			Puff(pr.pos, new Color(0.45f, 0.36f, 0.28f), 12, 280);
			sfx.Play("hit", 0.6f, 0.7f); sfx.Play("coin", 0.5f);
			Destroy(pr.sr.gameObject);
			props.RemoveAt(i);
		} else if (n == "bamboo" || n == "pine") {
			Color leaf = n == "bamboo" ? new Color(0.4f, 0.55f, 0.3f) : new Color(0.85f, 0.9f, 0.95f);
			for (int k = 0; k < 6; k++) parts.Add(new Part { pos = pr.pos + new Vector2(Rnd(-40, 40), Rnd(90, 180)), vel = new Vector2(Rnd(-90, 90), Rnd(20, 90)), r = Rnd(3, 6), life = 0.9f, max = 0.9f, col = leaf, grav = 240 });
			sfx.Play("slash", 0.25f, 1.6f);
		} else sfx.Play("block", 0.25f, 1.3f);
	}

	// wind in the plants, flame in the lanterns, smoke from the shrines
	void DrawLife(float rdt) {
		foreach (var pr in props) {
			string n = pr.sr.gameObject.name;
			float rot = 0;
			if (n == "bamboo" || n == "pine") rot = Mathf.Sin(T * 1.4f + pr.pos.x * 0.013f) * 1.8f + Mathf.Sin(T * 3.1f + pr.pos.y * 0.02f) * 0.6f;
			if (pr.shake > 0) { pr.shake -= rdt; rot += Mathf.Sin(T * 55) * pr.shake * 16; }
			pr.sr.transform.rotation = Quaternion.Euler(0, 0, rot);
			if (Mathf.Abs(pr.pos.y - camPos.y) > 700) continue;
			if (n == "lantern") {
				float f = 0.75f + 0.15f * Mathf.Sin(T * 9 + pr.pos.x) + 0.1f * Mathf.Sin(T * 23);
				ground.Ellipse(pr.pos, 120, 60, new Color(1f, 0.75f, 0.35f, 0.10f * f));
				fxInk.Circle(pr.pos + new Vector2(0, 76), 13 * f, new Color(1f, 0.7f, 0.3f, 0.35f), 12);
				fxInk.Circle(pr.pos + new Vector2(0, 76), 6 * f, new Color(1f, 0.92f, 0.65f, 0.8f), 10);
			} else if (n == "shrine" && Random.value < rdt * 5)
				parts.Add(new Part { pos = pr.pos + new Vector2(Random.Range(-6f, 6f), 20), vel = new Vector2(Random.Range(-14f, 14f), 55), r = Random.Range(5f, 9f), life = 1.6f, max = 1.6f, col = new Color(0.8f, 0.8f, 0.8f, 0.25f), grav = -25 });
		}
		foreach (var d in deco) {
			if (d == null) continue;
			string n = d.gameObject.name;
			if (n != "bamboo" && n != "pine") continue;
			Vector3 p = d.transform.position;
			if (Mathf.Abs(p.y * 100 - camPos.y) > 800) continue;
			d.transform.rotation = Quaternion.Euler(0, 0, Mathf.Sin(T * 1.2f + p.x * 1.3f) * 2.2f + Mathf.Sin(T * 2.7f + p.y * 2f) * 0.7f);
		}
	}

	void Deco(string[] set, System.Random r, Vector2 p) {
		string n = set[r.Next(set.Length)];
		float h = n == "bamboo" || n == "pine" ? 200 + r.Next(70) : (n == "pillar" ? 150 : 130);
		var sr = NewSpr(n, h);
		sr.flipX = r.Next(2) == 0;
		sr.color = new Color(0.8f, 0.8f, 0.83f);
		Place(sr, p);
		deco.Add(sr);
	}

	// Lays out the whole run. Depends only on `seed`.
	void BuildWorld() {
		var r = new System.Random(seed);
		float y = 500;
		for (int c = 0; c < 3; c++) {
			float y0 = y - (c == 0 ? 500 : 0);
			string[] tall = c == 0 ? new[] { "bamboo", "bamboo", "bamboo", "boulder" } : (c == 1 ? new[] { "pillar", "pillar", "lantern", "boulder" } : new[] { "pine", "pine", "boulder" });
			var set = D.CH_PROPS[c];
			for (int s = 0; s < 5; s++) {
				bool rest = s == 4;
				float w = rest ? 1300 : 1700 + r.Next(4) * 120, h = rest ? 650 : 950;
				var sg = new Seg { kind = rest ? "rest" : "fight", ch = c, step = s, r = new Rect(CX - w / 2, y, w, h) };
				segs.Add(sg);
				for (float yy = y + h - 20; yy > y - 40; yy -= 100) {
					Deco(tall, r, new Vector2(sg.r.xMin - 75 - r.Next(40), yy));
					Deco(tall, r, new Vector2(sg.r.xMax + 75 + r.Next(40), yy));
					Deco(tall, r, new Vector2(sg.r.xMin - 200 - r.Next(50), yy + 40));
					Deco(tall, r, new Vector2(sg.r.xMax + 200 + r.Next(50), yy + 40));
				}
				if (c == 0 && s == 0) for (float x = sg.r.xMin - 40; x < sg.r.xMax + 60; x += 115) Deco(tall, r, new Vector2(x, y - 95 - r.Next(40)));
				if (!rest) {
					// inside: scatter, a colonnade of three lanes, or a ring around the middle
					int layout = r.Next(3), scatter = layout == 0 ? 7 + r.Next(4) : 3 + r.Next(3);
					int first = props.Count;
					if (layout == 1) {
						for (float yy = y + 260; yy < y + h - 200; yy += 240) {
							AddProp(set[0], new Vector2(CX - 330, yy));
							AddProp(set[0], new Vector2(CX + 330, yy));
						}
					} else if (layout == 2) {
						for (int k = 0; k < 6; k++) {
							float a = k * Mathf.PI / 3 + 0.5f;
							AddProp(set[k % set.Length], new Vector2(CX + Mathf.Cos(a) * 330, y + h / 2 + Mathf.Sin(a) * 250));
						}
					}
					for (int i = 0; i < scatter; i++) {
						Vector2 p = Vector2.zero;
						bool ok = false;
						for (int tries = 0; tries < 20 && !ok; tries++) {
							p = new Vector2(sg.r.xMin + 110 + (float)r.NextDouble() * (w - 220), y + 200 + (float)r.NextDouble() * (h - 400));
							ok = true;
							for (int k = first; k < props.Count; k++) if ((props[k].pos - p).magnitude < 230) ok = false;
						}
						if (ok) AddProp(set[r.Next(set.Length)], p);
					}
				}
				y += h;
			}
			// the boss arena is the chapter's painting laid into the map, entered and left by a narrow pass
			Rect pr = CH_PR[c];
			var paint = new GameObject("paint").AddComponent<SpriteRenderer>();
			paint.sprite = Spr("bg" + (c + 1));
			paint.sortingOrder = -99;
			if (paint.sprite != null) {
				float k = AW * 0.01f / paint.sprite.bounds.size.x;
				paint.transform.localScale = new Vector3(k, k, 1);
			}
			paint.transform.position = new Vector3(CX * 0.01f, (y + AH / 2) * 0.01f, 0);
			deco.Add(paint);
			paints.Add(new Rect(CX - AW / 2, y, AW, AH));
			segs.Add(new Seg { kind = "pass", ch = c, step = 5, state = 2, r = new Rect(CX - 210, y, 420, pr.yMin) });
			segs.Add(new Seg { kind = "boss", ch = c, step = 5, r = new Rect(CX - AW / 2 + pr.x, y + pr.yMin, pr.width, pr.height) });
			segs.Add(new Seg { kind = "pass", ch = c, step = 5, state = 2, r = new Rect(CX - 210, y + pr.yMax, 420, AH - pr.yMax) });
			y += AH;
			// ground of the chapter: the tile mirrored on every other column and row, so the joins never show
			var gs = Spr("bg_g" + (c + 1));
			if (gs != null) {
				float tw = gs.bounds.size.x * 100, th = gs.bounds.size.y * 100;
				int ix = 0;
				for (float x = CX - 1650; x < CX + 1650; x += tw, ix++) {
					int iy = 0;
					for (float yy = y0; yy < y; yy += th, iy++) {
						var sr = new GameObject("tile").AddComponent<SpriteRenderer>();
						sr.sprite = gs; sr.sortingOrder = -100;
						sr.flipX = (ix & 1) == 1; sr.flipY = (iy & 1) == 1;
						sr.transform.position = new Vector3((x + tw / 2) * 0.01f, (yy + th / 2) * 0.01f, 0);
						tiles.Add(sr);
					}
				}
			}
		}
		worldTop = y;
		yLo = segs[0].r.yMin; yHi = worldTop;
		VR = new Rect(CX - 1250, segs[0].r.yMin - 200, 2500, worldTop - segs[0].r.yMin + 200);
		PR = segs[0].r;
	}

	// Walls: stay inside the segment you are in; cross to the next only where the two overlap.
	public Vector2 Confine(Vector2 p, float r) {
		if (segs.Count == 0) return p;
		p.y = Mathf.Clamp(p.y, yLo + r * 0.5f, yHi - r * 0.5f);
		int i = SegIndex(p.y);
		Rect s = segs[i].r;
		if (p.x < s.xMin + r || p.x > s.xMax - r) {
			float cx = Mathf.Clamp(p.x, s.xMin + r, s.xMax - r);
			float best = Mathf.Abs(cx - p.x);
			Vector2 q = new Vector2(cx, p.y);
			for (int k = -1; k <= 1; k += 2) {
				int j = i + k;
				if (j < 0 || j >= segs.Count) continue;
				Rect n = segs[j].r;
				if (p.x < n.xMin + r || p.x > n.xMax - r) continue;
				float ny = k < 0 ? n.yMax - 0.5f : n.yMin;
				if (ny < yLo || ny > yHi) continue;
				if (Mathf.Abs(ny - p.y) < best) { best = Mathf.Abs(ny - p.y); q = new Vector2(p.x, ny); }
			}
			p = q;
		}
		foreach (var pr in props) {
			if (Mathf.Abs(pr.pos.y - p.y) > 150) continue;
			Vector2 d = p - pr.pos;
			d.y *= 1.6f;   // props block an ellipse wider than deep
			float m = d.magnitude, need = pr.r + r;
			if (m < need && m > 0.01f) { Vector2 push = d / m * (need - m); push.y /= 1.6f; p += push; }
		}
		return p;
	}

	void StartFight(Seg s) {
		fight = s; s.state = 1;
		step = s.step;
		roomKind = s.kind == "boss" ? "boss" : "fight";
		PR = s.r;
		yLo = s.r.yMin; yHi = s.r.yMax;
		cleared = false; wave = 0; roomT = 0;
		waves = 2 + (s.step >= 1 ? 1 : 0) + (s.ch >= 1 && s.step >= 3 ? 1 : 0);
		spawnT = 0.4f;
		stains.Clear(); doors.Clear();
		sfx.Battle(true);
		if (s.kind == "boss") {
			var b = Spawn("boss" + (s.ch + 1), new Vector2(s.r.center.x, s.r.yMax - 190), false);
			b.spawn = 1.3f;
			Banner(b.d.name, D.CH_NAME[s.ch]);
			sfx.Play("gong");
		} else sfx.Play("drum");
	}

	void Populate(Seg s) {
		Vector2 c = new Vector2(s.r.center.x - 260, s.r.center.y + 110);
		items.Add(new Item { pos = c, kind = "npc", label = "", sr = NewSpr("merchant", 130) });
		AddItem(c + new Vector2(-200, -150), "heal", "KIM SANG DƯỢC\nHồi 40 sinh lực", 35, "jar", null);
		AddItem(c + new Vector2(-65, -185), "dan", "LINH ĐAN\n+15 sinh lực tối đa", 60, "jar", null);
		var o = MakeOffers(1);
		if (o.Count > 0) AddItem(c + new Vector2(70, -185), "boon", o[0].b.name + " · CẤP " + o[0].lvl + "\n" + D.Desc(o[0].b, o[0].lvl), 70, "chest", o[0].b);
		AddItem(c + new Vector2(205, -150), "luyen", "LUYỆN KHÍ\nNâng cấp một chiêu đã học", 80, "shrine", null);
		Vector2 t = new Vector2(s.r.center.x + 330, s.r.center.y + 110);
		items.Add(new Item { pos = t, kind = "npc", label = "", sr = NewSpr("tea", 95) });
		AddItem(t + new Vector2(0, -120), "tea", "THƯỞNG TRÀ\nHồi 40% sinh lực", 0, null, null);
		Banner("TRẠM DỪNG", "Thương nhân và trà quán trước cửa ải cuối");
	}

	void UpWorld(float dt) {
		if (fight != null) {
			bool any = false;
			foreach (var f in foes) if (!f.dead) any = true;
			if (fight.kind == "boss") {
				bool bossAlive = false;
				foreach (var f in foes) if (!f.dead && f.d.boss) bossAlive = true;
				if (!bossAlive) { foreach (var f in foes) if (!f.dead) Kill(f); RoomCleared(); }
			} else if (!any) {
				if (wave < waves) { spawnT -= dt; if (spawnT <= 0) { SpawnWave(); spawnT = 0.7f; } }
				else RoomCleared();
			}
			return;
		}
		var s = SegAt(ppos.y);
		PR = s.r;
		if (s.ch != ch) { ch = s.ch; Banner(D.CH_NAME[ch], "Đường còn dài"); sfx.Play("gong", 0.6f); }
		if (s.state == 0) {
			if (s.kind == "rest") { s.state = 2; Populate(s); }
			else if (ppos.y > s.r.yMin + 150 && pickT <= 0) { StartFight(s); return; }
		}
		if (pickKind != "" && pickT > 0) { pickT -= dt; if (pickT <= 0) { string k = pickKind; pickKind = ""; OpenPick(k, pickBonus); } }
		if (P(inp.use, prev.use) && pickT <= 0) {
			foreach (var d in doors) if ((d.pos - ppos).magnitude < 120) { UseDoor(d); return; }
			foreach (var it in items) if (!it.gone && it.kind != "npc" && (it.pos - ppos).magnitude < 90) { UseItem(it); break; }
		}
	}

	void RoomCleared() {
		var s = fight;
		fight = null; s.state = 2;
		cleared = true;
		rooms++;
		sfx.Battle(false);
		sfx.Play("gong", 0.7f);
		shots.RemoveAll(x => !x.mine);
		Heal(Up("heal") * 3);
		slow = 0.5f;
		yLo = segs[0].r.yMin; yHi = s.r.yMax;
		doors.Clear();
		if (s.kind == "boss") {
			bossKills++;
			Heal(maxHp * 0.3f);
			AddCoins(60);
			string[] unl = s.ch == 0 ? new[] { "thuong", "dao" } : (s.ch == 1 ? new[] { "phien", "chuy" } : new[] { "cung" });
			foreach (var id in unl) if (!meta.unl.Contains(id)) { meta.unl.Add(id); Toast("MỞ KHÓA: " + D.Weapon(id).name); }
			SaveMeta();
			pickKind = "bikip"; pickBonus = 1; pickT = 1.4f;
			Banner("ĐẠI THẮNG", "Trùm đã ngã");
			if (s.ch >= 2) doors.Add(new Door { pos = new Vector2(s.r.center.x, s.r.yMax - 10), kind = "end" });
			else yHi = worldTop;
			return;
		}
		// two offerings at the far end: take one and the seal opens
		string[] pool = { "bikip", "bikip", "bikip", "luyen", "dan", "ngan" };
		string a = pool[rng.Next(pool.Length)], b = a;
		while (b == a) b = pool[rng.Next(pool.Length)];
		if (boons.Count == 0) { a = "bikip"; if (b == "luyen" || b == "bikip") b = "ngan"; }
		if (s.step >= 1 && Rnd() < 0.25f) b = "ky";
		doors.Add(new Door { pos = new Vector2(s.r.center.x - 210, s.r.yMax - 10), kind = a });
		doors.Add(new Door { pos = new Vector2(s.r.center.x + 210, s.r.yMax - 10), kind = b });
	}

	void UseDoor(Door d) {
		string k = d.kind;
		sfx.Play("drum");
		doors.Clear();
		if (k == "end") { Win(); return; }
		yHi = worldTop;
		switch (k) {
			case "bikip": case "luyen": OpenPick(k, 0); break;
			case "dan": bonusHp += 15; Recalc(); Heal(25); Toast("LINH ĐAN: +15 sinh lực tối đa"); break;
			case "ngan": AddCoins(45 + ch * 15 + rng.Next(20)); Toast("NHẬN MỘT TÚI NGÂN LƯỢNG"); break;
			case "ky": state = "event"; menuI = 0; sfx.Play("pick"); break;
		}
	}

	// --- flying swords: thrown one at a time, they stay in what they hit until called home
	void ThrowSword() {
		swordsHeld--;
		thrCd = 0.13f;
		swords.Add(new FSword { pos = ppos + new Vector2(0, 55), vel = aimDir * 1700 });
		face = aimDir.x >= 0 ? 1 : -1;
		sfx.Play("shoot", 0.45f, 1.35f);
	}

	void RecallSwords() {
		bool any = false;
		foreach (var s in swords) {
			if (s.st != 1) continue;
			s.st = 2; s.hit.Clear(); any = true;
			if (s.host != null && !s.host.dead) { s.hit.Add(s.host); s.vel = (ppos - s.host.pos).normalized; SwordHit(s, s.host, true); }
			s.host = null;
		}
		if (any) { sfx.Play("dash", 0.6f, 1.5f); recallT = 0.25f; }
	}

	void SwordHit(FSword s, Foe f, bool back) {
		int el = SlotEl("atk"), lv = SlotLv("atk");
		// going out a sword carries the element of the attack, coming home that of the ultimate: one throw can react
		if (back && SlotEl("skill") >= 0) { el = SlotEl("skill"); lv = SlotLv("skill"); }
		float dmg = (back ? 15 * (1 + Lv("hoi") * 0.4f) : 8) * dmgMul * (meta.sect == "kiem" ? 1.3f : 1);
		HurtFoe(f, dmg, el, lv, back ? 1.4f : 0.8f, s.vel.sqrMagnitude > 0.01f ? s.vel.normalized : Vector2.up);
	}

	void UpSwords(float dt) {
		thrCd -= dt;
		bool can = act != "dash" && act != "skill" && !guard;
		if (inp.thr && can && thrCd <= 0 && swordsHeld > 0) ThrowSword();
		else if (P(inp.thr, prev.thr) && swordsHeld == 0) RecallSwords();
		if (P(inp.recall, prev.recall)) RecallSwords();
		Vector2 up = new Vector2(0, 55);
		for (int i = swords.Count - 1; i >= 0; i--) {
			var s = swords[i];
			s.t += dt;
			if (s.st == 0) {
				s.pos += s.vel * dt;
				Vector2 g = s.pos - up;
				Foe hitF = null;
				foreach (var f in foes) if (!f.dead && f.spawn <= 0 && (f.pos - g).magnitude < f.d.r * f.scale + 16) { hitF = f; break; }
				if (hitF != null) {
					SwordHit(s, hitF, false);
					s.st = 1; s.t = 0;
					s.host = hitF.dead ? null : hitF;
					s.off = (g - hitF.pos) * 0.5f;
				} else if (s.t > 0.4f || g.y < yLo || g.y > yHi || (Confine(g, 4) - g).sqrMagnitude > 1) { s.st = 1; s.t = 0; }
			} else if (s.st == 1) {
				if (s.host != null) {
					if (s.host.dead) s.host = null;
					else s.pos = s.host.pos + s.off + new Vector2(0, 55 + s.host.z);
				}
				if (s.t > (meta.sect == "kiem" ? 2f : 8f)) {
					s.st = 2; s.hit.Clear();
					if (s.host != null && !s.host.dead) { s.hit.Add(s.host); s.vel = (ppos - s.host.pos).normalized; SwordHit(s, s.host, true); }
					s.host = null;
				}
			} else {
				Vector2 to = ppos + up - s.pos;
				float m = to.magnitude;
				if (m < 46 + 2300 * dt) {
					swords.RemoveAt(i);
					catchT = 0.14f; recallT = 0;
					swordsHeld = Mathf.Min(swordMax, swordsHeld + 1);
					qi = Mathf.Min(100, qi + 1.5f * qiMul);
					continue;
				}
				s.vel = to / m * 2300;
				s.pos += s.vel * dt;
				Vector2 g = s.pos - up;
				foreach (var f in foes) {
					if (f.dead || f.spawn > 0 || s.hit.Contains(f) || (f.pos - g).magnitude > f.d.r * f.scale + 28) continue;
					s.hit.Add(f);
					SwordHit(s, f, true);
				}
			}
		}
	}

	void Seal(float y, float x0, float x1) {
		float a = 0.55f + 0.15f * Mathf.Sin(T * 5);
		for (float x = x0; x < x1; x += 150) {
			ground.Brush(new Vector2(x - 20, y + Mathf.Sin(x) * 8), new Vector2(x + 170, y + Mathf.Sin(x + 2) * 8), 34, new Color(0.07f, 0.06f, 0.06f, a));
			ground.Brush(new Vector2(x, y), new Vector2(x + 150, y), 7, new Color(0.78f, 0.18f, 0.12f, a));
		}
	}

	// called from Render
	void DrawStage() {
		Color dark = new Color(0.05f, 0.05f, 0.06f, 0.5f), clear = new Color(0.05f, 0.05f, 0.06f, 0), black = new Color(0.05f, 0.05f, 0.06f, 0.94f);
		foreach (var s in segs) {
			if (s.kind == "pass" || s.kind == "boss" || Mathf.Abs(s.r.center.y - camPos.y) > s.r.height / 2 + 700) continue;
			Rect r = s.r;
			ground.Rect(CX - 3000, r.yMin, r.xMin - 30 - (CX - 3000), r.height, dark);
			ground.Rect(r.xMax + 30, r.yMin, CX + 3000 - r.xMax - 30, r.height, dark);
			ground.Quad(new Vector2(r.xMin - 30, r.yMin), new Vector2(r.xMin - 30, r.yMax), new Vector2(r.xMin + 110, r.yMax), new Vector2(r.xMin + 110, r.yMin), dark, clear);
			ground.Quad(new Vector2(r.xMax + 30, r.yMin), new Vector2(r.xMax + 30, r.yMax), new Vector2(r.xMax - 110, r.yMax), new Vector2(r.xMax - 110, r.yMin), dark, clear);
		}
		foreach (var p in paints) {
			if (Mathf.Abs(p.center.y - camPos.y) > p.height / 2 + 700) continue;
			ground.Rect(CX - 3000, p.yMin, p.xMin - (CX - 3000), p.height, black);
			ground.Rect(p.xMax, p.yMin, CX + 3000 - p.xMax, p.height, black);
			// ink mist over the joins between the painting and the tiled ground
			for (int k = 0; k < 2; k++) {
				float ey = k == 0 ? p.yMin : p.yMax;
				ground.Quad(new Vector2(p.xMin, ey), new Vector2(p.xMax, ey), new Vector2(p.xMax, ey + 170), new Vector2(p.xMin, ey + 170), black, clear);
				ground.Quad(new Vector2(p.xMin, ey), new Vector2(p.xMax, ey), new Vector2(p.xMax, ey - 170), new Vector2(p.xMin, ey - 170), black, clear);
			}
		}
		if (segs.Count > 0) ground.Rect(CX - 3000, segs[0].r.yMin - 900, 6000, 860, dark);
		if (fight != null) {
			if (yLo > segs[0].r.yMin + 1) Seal(yLo - 16, fight.r.xMin, fight.r.xMax);
			if (fight.kind != "boss" || fight.ch < 2) Seal(yHi + 16, fight.r.xMin, fight.r.xMax);
		} else if (doors.Count > 0 && yHi < worldTop - 1) Seal(yHi + 16, PR.xMin, PR.xMax);

		foreach (var s in swords) {
			Vector2 d = s.st == 1 ? new Vector2(0.35f, -0.94f) : s.vel.normalized;
			Vector2 c = s.st == 1 && s.host == null ? s.pos - new Vector2(0, 28) : s.pos;
			Vector2 n = new Vector2(-d.y, d.x), tip = c + d * 30, tail = c - d * 34;
			if (s.st != 1) fxInk.Brush(c - d * 130, c, 9, new Color(0.07f, 0.06f, 0.06f, 0.3f));
			fxInk.Brush(tail, tip, 13, D.INK);
			fxInk.Brush(tail + d * 8, tip - d * 4, 5, new Color(0.93f, 0.95f, 0.97f));
			fxInk.Line(tail + d * 10 - n * 9, tail + d * 10 + n * 9, 4, D.INK);
		}
		DrawSkills();
	}
}
