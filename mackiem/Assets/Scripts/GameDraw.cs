using System.Collections.Generic;
using UnityEngine;

// Everything visible: sprites, the two ink meshes (ground and effects), HUD and menus (IMGUI).
public partial class Game {
	Shader inkShader;
	readonly Dictionary<string, Sprite> sprites = new Dictionary<string, Sprite>();
	Ink ground, fxInk;
	SpriteRenderer bgSr, titleSr, heroSr;
	Sprite[] hRun, hAtk, hIdleF, hAct;
	bool heroAnim;
	readonly Dictionary<string, Sprite[]> frameSets = new Dictionary<string, Sprite[]>();
	float heroK = 1;
	Font fTitle, fBody;
	Texture2D white;
	GUIStyle st;
	Vector2 camPos = new Vector2(AW / 2, AH / 2);
	float gs = 1, GW = 1280;
	const float GH = 720;
	Vector2 guiMouse;
	bool mouseMoved;

	void InitDraw() {
		inkShader = Resources.Load<Shader>("InkSprite");
		if (inkShader == null) inkShader = Shader.Find("Sprites/Default");
		ground = new Ink("ground", -50);
		fxInk = new Ink("fx", 30000);
		bgSr = new GameObject("bg").AddComponent<SpriteRenderer>();
		bgSr.sortingOrder = -100;
		titleSr = new GameObject("title").AddComponent<SpriteRenderer>();
		titleSr.sprite = Spr("title");
		titleSr.sortingOrder = -90;
		heroSr = NewSpr("hero_idle", 125);
		heroSr.gameObject.name = "hero";
		heroK = heroSr.transform.localScale.x;
		hRun = Frames("hero_run"); hAtk = Frames("hero_atk");
		hIdleF = Frames("hero_idle"); hAct = Frames("hero_act");
		heroAnim = hRun.Length >= 8 && hAtk.Length >= 12 && hIdleF.Length >= 4 && hAct.Length >= 12;
		if (heroAnim) heroK = 1;
		InitRig();   // frames are drawn at twice the logic size and imported at 200 px per unit
		fTitle = Font.CreateDynamicFontFromOSFont(new[] { "Palatino Linotype", "Georgia", "Times New Roman", "Noto Serif", "serif" }, 40);
		fBody = Font.CreateDynamicFontFromOSFont(new[] { "Segoe UI", "Tahoma", "Roboto", "Noto Sans", "Arial" }, 20);
		white = new Texture2D(1, 1);
		white.SetPixel(0, 0, Color.white);
		white.Apply();
	}

	Sprite Spr(string n) {
		Sprite s;
		if (!sprites.TryGetValue(n, out s)) { s = Resources.Load<Sprite>("Art/" + n); sprites[n] = s; }
		return s;
	}

	// name_0, name_1, ... until one is missing
	Sprite[] Frames(string prefix) {
		Sprite[] f;
		if (frameSets.TryGetValue(prefix, out f)) return f;
		var l = new List<Sprite>();
		for (int i = 0; i < 16; i++) { var s = Resources.Load<Sprite>("Art/" + prefix + "_" + i); if (s == null) break; l.Add(s); }
		f = l.ToArray();
		frameSets[prefix] = f;
		return f;
	}

	// the frame of the hero for what he is doing right now
	// the hero's frames when he holds something other than the sword: hero_<weapon>_run/idle/atk/act
	Sprite[][] WSet() {
		string k = "hero_" + weapon.id;
		var run = Frames(k + "_run");
		if (run.Length < 8) return null;
		var idle = Frames(k + "_idle"); var atk = Frames(k + "_atk"); var ac = Frames(k + "_act");
		if (idle.Length < 4 || atk.Length < 8 || ac.Length < 4) return null;
		return new[] { run, idle, atk, ac };
	}

	Sprite PoseW(Sprite[][] w) {
		Sprite[] run = w[0], idle = w[1], atk = w[2], ac = w[3];   // ac: guard, hurt, dash, gather
		if (state == "dead") return ac[1];
		if (act == "dash") return ac[2];
		if (castT > 0) return ac[3];
		if (act == "skill") return weapon.skill == "charge" ? atk[2] : ac[3];
		if (whirlT > 0) return atk[5];
		if (act == "atk") {
			var s = weapon.combo[ci];
			float u = at / s.dur;
			int k = u < 0.2f ? 0 : (u < 0.48f ? 1 : (u < 0.82f ? 2 : 3));
			bool last = (ci == weapon.combo.Length - 1 && weapon.combo.Length > 1) || s.w > 3;
			return atk[(last ? 4 : 0) + k];
		}
		if (hurtFx > 0.22f) return ac[1];
		if (guard) return ac[0];
		if (chargeT > 0) return atk[chargeT < 0.5f ? 1 : 2];
		if (weapon.mech == "charge" && acd > 0) return atk[3];
		if (thrCd > 0.02f || catchT > 0) return atk[2];
		if (moving) return run[(int)(moveAmt * 15) % 8];
		int b = (int)(T * 3.2f) % 6;
		return idle[b < 4 ? b : 6 - b];
	}

	Sprite HeroPose() {
		if (!heroAnim) return Spr(act == "dash" ? "hero_dash" : (act == "atk" || act == "skill" || whirlT > 0 ? "hero_slash" : (moving ? "hero_run" : "hero_idle")));
		var ws = WSet();
		if (ws != null) return PoseW(ws);
		if (state == "dead") return hAct[3];
		if (act == "dash") return at < 0.035f ? hAct[4] : hAct[5];
		if (castT > 0) return castT > 0.26f ? hAct[10] : hAct[11];
		if (act == "skill") return weapon.skill == "charge" ? hAtk[10] : (at < 0.1f ? hAct[10] : hAct[11]);
		if (whirlT > 0) return hAtk[9];
		if (act == "atk") {
			var s = weapon.combo[ci];
			float u = at / s.dur;
			int k = u < 0.2f ? 0 : (u < 0.48f ? 1 : (u < 0.82f ? 2 : 3));
			if (s.t == "shot") return k == 0 ? hAct[4] : hAct[7];
			bool last = ci == weapon.combo.Length - 1 && weapon.combo.Length > 1;
			if (s.t == "line") return k == 0 ? hAtk[0] : (k == 3 ? hAtk[11] : hAtk[10]);
			return hAtk[(last || s.w > 3 ? 8 : (ci % 2) * 4) + k];
		}
		if (hurtFx > 0.22f) return hAct[2];
		if (guard) return pflash > 0 ? hAct[1] : hAct[0];
		var th = Frames("hero_throw");
		if (th.Length >= 12) {
			// throw: step and cock (0-1), whip (2), release (3), follow through (4); call (8-9), catch (10-11)
			if (throwT > 0) { float u = 1 - throwT / 0.2f; return th[u < 0.25f ? 1 : (u < 0.5f ? 2 : (u < 0.75f ? 3 : 4))]; }
			if (thrCd > -0.12f && swords.Count > 0 && recallT <= 0 && catchT <= 0 && !moving) return th[thrCd > -0.05f ? 4 : 5];
			if (catchT > 0) return th[catchT > 0.07f ? 10 : 11];
			if (recallT > 0) return th[recallT > 0.12f ? 8 : 9];
		} else {
			if (thrCd > 0.02f) return hAct[7];
			if (catchT > 0) return hAct[9];
			if (recallT > 0) return hAct[8];
		}
		if (chargeT > 0) return hAct[10];
		if (skidT > 0) return hAct[6];
		if (moving) return hRun[(int)(moveAmt * 15) % hRun.Length];
		int b = (int)(T * 3.2f) % 6;   // breathe in and out: 0 1 2 3 2 1
		return hIdleF[b < 4 ? b : 6 - b];
	}

	// an ink afterimage of a sprite, left behind by fast moves
	void AddGhost(SpriteRenderer src, Vector2 at, Color c, float life) {
		if (src == null || src.sprite == null || ghosts.Count > 60) return;
		var go = new GameObject("ghost");
		var sr = go.AddComponent<SpriteRenderer>();
		sr.sprite = src.sprite; sr.flipX = src.flipX;
		sr.material = new Material(inkShader);
		sr.material.SetFloat("_Flash", 1);
		sr.material.SetColor("_FlashColor", c);
		sr.color = new Color(1, 1, 1, c.a);
		go.transform.localScale = src.transform.localScale;
		go.transform.rotation = src.transform.rotation;
		Place(sr, at);
		sr.sortingOrder -= 1;
		ghosts.Add(new Ghost { sr = sr, life = life, max = life });
	}

	// a standing sprite `h` logic pixels tall, feet at its position
	SpriteRenderer NewSpr(string name, float h) {
		var go = new GameObject(name);
		var sr = go.AddComponent<SpriteRenderer>();
		sr.sprite = Spr(name);
		sr.material = new Material(inkShader);
		float sh = sr.sprite != null ? sr.sprite.bounds.size.y * 100f : h;
		go.transform.localScale = Vector3.one * (h / sh);
		return sr;
	}


	void Place(SpriteRenderer sr, Vector2 p, float z = 0) {
		sr.transform.position = new Vector3(p.x * 0.01f, (p.y + z) * 0.01f, 0);
		sr.sortingOrder = 22000 - (int)p.y;
	}

	bool InWorld() { return state == "play" || state == "pick" || state == "event" || state == "pause" || state == "dead" || state == "win"; }

	void Render(float rdt) {
		bool world = InWorld();
		float hh = VIEW_H / 2, hw = hh * cam.aspect;
		bgSr.enabled = false;
		titleSr.enabled = !world;
		heroSr.enabled = world && (state != "dead" || heroAnim);
		ground.Clear(); fxInk.Clear();
		if (!world) {
			cam.transform.position = new Vector3(0, 0, -10);
			if (titleSr.sprite != null) {
				var b = titleSr.sprite.bounds.size;
				float k = Mathf.Max(hw * 0.02f / b.x, VIEW_H * 0.01f / b.y);
				titleSr.transform.localScale = new Vector3(k, k, 1);
				titleSr.transform.position = new Vector3(Mathf.Sin(T * 0.1f) * 0.05f, 0, 0);
			}
			ground.Apply(); fxInk.Apply();
			return;
		}
		// camera
		Vector2 target = ppos + aimDir * 40 + new Vector2(0, 50);
		camPos = Vector2.Lerp(camPos, target, 1 - Mathf.Exp(-7 * rdt));
		camPos.x = hw * 2 >= VR.width ? VR.center.x : Mathf.Clamp(camPos.x, VR.xMin + hw, VR.xMax - hw);
		camPos.y = hh * 2 >= VR.height ? VR.center.y : Mathf.Clamp(camPos.y, VR.yMin + hh, VR.yMax - hh);
		Vector2 sh = Random.insideUnitCircle * shake;
		cam.transform.position = new Vector3((camPos.x + sh.x) * 0.01f, (camPos.y + sh.y) * 0.01f, -10);

		// --- hero
		var hs = HeroPose();
		if (hs != null) heroSr.sprite = hs;
		heroSr.flipX = face < 0;
		float bob = moving && act == "" && !heroAnim ? Mathf.Abs(Mathf.Sin(moveAmt * 13)) * 9 : 0;
		foreach (var g in ghosts) { var gc = g.sr.color; gc.a = g.life / g.max * 0.6f; g.sr.color = gc; }
		float breathe = 1 + Mathf.Sin(T * 2.6f) * 0.012f;
		Place(heroSr, ppos, bob);
		float stretch = act == "dash" ? 1.12f : 1;
		if (act != "" || moving) breathe = 1;
		heroSr.transform.localScale = new Vector3(heroK * stretch, heroK * breathe / stretch, 1);
		float lean = 0;
		if (act == "atk") lean = -face * (heroAnim ? 3 : 7) * Mathf.Sin(Mathf.Clamp01(at / weapon.combo[ci].dur) * Mathf.PI);
		else if (moving && !heroAnim) lean = -face * 3;
		if (whirlT > 0) heroSr.flipX = ((int)(T * 12)) % 2 == 0;
		heroSr.transform.rotation = Quaternion.Euler(0, 0, lean);
		heroSr.color = new Color(1, 1, 1, inv > 0 && pflash <= 0 && act != "dash" && ((int)(T * 20)) % 2 == 0 ? 0.55f : 1);
		heroSr.material.SetFloat("_Flash", pflash > 0 ? 0.8f : (guard && gt <= pwin ? 0.35f : 0));
		heroSr.material.SetColor("_FlashColor", pflash > 0 ? new Color(1f, 0.3f, 0.25f) : new Color(1f, 0.92f, 0.6f));
		RenderRig(rdt, bob);

		// --- ground layer
		for (int i = 0; i < stains.Count; i++) ground.Blot(new Vector2(stains[i].x, stains[i].y), stains[i].z, new Color(0.07f, 0.06f, 0.06f, 0.32f), i * 31 + 5);
		foreach (var p in pools) {
			float a = Mathf.Clamp01(p.t) * 0.35f;
			ground.Blot(p.pos, p.r, new Color(0.25f, 0.5f, 0.2f, a), (int)(p.pos.x * 7));
			ground.Ring(p.pos, p.r, 3, new Color(0.15f, 0.35f, 0.12f, a * 1.5f));
		}
		foreach (var d in doors) {
			Color c = D.RewardCol(d.kind);
			float pulse = 0.5f + 0.2f * Mathf.Sin(T * 4);
			bool near = (d.pos - ppos).magnitude < 120;
			ground.Ellipse(d.pos, 95, 34, new Color(c.r, c.g, c.b, near ? 0.75f : pulse * 0.6f));
			ground.Ring(d.pos, 0, 0, c);
			ground.Rect(d.pos.x - 78, d.pos.y, 12, 150, D.INK);
			ground.Rect(d.pos.x + 66, d.pos.y, 12, 150, D.INK);
			ground.Rect(d.pos.x - 96, d.pos.y + 138, 192, 14, D.INK);
			ground.Rect(d.pos.x - 84, d.pos.y + 118, 168, 8, D.INK);
			ground.Rect(d.pos.x - 22, d.pos.y + 60, 44, 56, c);
			ground.Rect(d.pos.x - 22, d.pos.y + 60, 44, 4, D.INK);
		}
		foreach (var it in items) {
			if (it.gone) continue;
			if (it.kind != "npc") {
				bool near = (it.pos - ppos).magnitude < 90;
				ground.Ellipse(it.pos, 46, 18, new Color(0.91f, 0.86f, 0.75f, near ? 0.8f : 0.4f));
				ground.Ring(it.pos, 0, 0, D.INK);
			} else ground.Ellipse(it.pos, 50, 16, new Color(0, 0, 0, 0.25f));
			if (it.sr != null) {
				if (it.kind == "npc") {
					var nf = Frames(it.sr.gameObject.name + "_idle");
					if (nf.Length > 0) { it.sr.sprite = nf[(int)(T * 2.5f + it.pos.x) % nf.Length]; it.sr.transform.localScale = Vector3.one; }
					Place(it.sr, it.pos);
				} else Place(it.sr, it.pos, 3 + Mathf.Sin(T * 2.5f + it.pos.x) * 3);
			}
		}
		DrawLife(rdt);
		foreach (var pr in props) { ground.Ellipse(pr.pos, pr.r * 1.3f, pr.r * 0.5f, new Color(0, 0, 0, 0.28f)); Place(pr.sr, pr.pos); }
		foreach (var b in blasts) {
			float u = Mathf.Clamp01(b.t / b.wind);
			ground.Circle(b.pos, b.r, new Color(0.78f, 0.18f, 0.12f, 0.16f), 32);
			ground.Circle(b.pos, b.r * u, new Color(0.78f, 0.18f, 0.12f, 0.32f), 32);
			ground.Ring(b.pos, b.r, 5, new Color(0.78f, 0.18f, 0.12f, 0.85f));
		}
		foreach (var f in foes) {
			if (f.dead || f.mv == null || f.resolved) continue;
			var s = f.mv.steps[f.si];
			float u = Mathf.Clamp01(f.stT / Mathf.Max(0.01f, s.wind));
			float a0 = Mathf.Atan2(f.aim.y, f.aim.x);
			Color soft = new Color(0.07f, 0.06f, 0.06f, 0.16f), hot = new Color(0.78f, 0.18f, 0.12f, 0.2f + 0.25f * u);
			if (s.t == "arc") {
				ground.Sector(f.pos, s.r, a0 - s.w / 2, a0 + s.w / 2, soft);
				ground.Sector(f.pos, s.r * u, a0 - s.w / 2, a0 + s.w / 2, hot);
				ground.Ring(f.pos, s.r, 4, new Color(0.78f, 0.18f, 0.12f, 0.7f), 32, a0 - s.w / 2, a0 + s.w / 2);
			} else if (s.t == "line") {
				Vector2 n = new Vector2(-f.aim.y, f.aim.x) * s.wid * 0.5f;
				ground.Quad(f.pos - n, f.pos + n, f.pos + f.aim * s.len + n, f.pos + f.aim * s.len - n, soft);
				ground.Quad(f.pos - n, f.pos + n, f.pos + f.aim * s.len * u + n, f.pos + f.aim * s.len * u - n, hot);
				ground.Line(f.pos + f.aim * s.len - n, f.pos + f.aim * s.len + n, 4, new Color(0.78f, 0.18f, 0.12f, 0.7f));
			} else if (s.t == "shoot") {
				ground.Line(f.pos, f.pos + f.aim * 620, 3 + 3 * u, new Color(0.78f, 0.18f, 0.12f, 0.15f + 0.35f * u));
			} else if (s.t == "ring" || s.t == "radial" || s.t == "summon" || s.t == "rain") {
				ground.Ring(f.pos, 110 - 70 * u, 6, new Color(0.78f, 0.18f, 0.12f, 0.3f + 0.5f * u));
			}
		}
		foreach (var w in wavesFx) {
			float a = 1 - Mathf.Clamp01(w.r / w.max) * (w.hit ? 1 : 0.3f);
			if (w.dmg > 0) { ground.Ring(w.pos, w.r, 16, new Color(0.07f, 0.06f, 0.06f, a * 0.8f), 64); ground.Ring(w.pos, w.r, 5, new Color(0.9f, 0.3f, 0.2f, a), 64); }
			else ground.Ring(w.pos, w.r, 10, new Color(w.col.r, w.col.g, w.col.b, a * 0.8f), 48);
		}
		ground.Ellipse(ppos, 30, 11, new Color(0, 0, 0, 0.32f));
		if (state == "play") ground.Brush(ppos + aimDir * 62, ppos + aimDir * 96, 9, new Color(0.07f, 0.06f, 0.06f, 0.5f));
		if (guard) {
			float a0 = Mathf.Atan2(aimDir.y, aimDir.x);
			Color gc = gt <= pwin ? new Color(1f, 0.9f, 0.5f, 0.95f) : new Color(0.91f, 0.86f, 0.75f, 0.7f);
			fxInk.Ring(ppos + new Vector2(0, 50), 58, gt <= pwin ? 9 : 6, gc, 20, a0 - 1.1f, a0 + 1.1f);
		}
		if (whirlT > 0) {
			int el = SlotEl("skill");
			Color wc = el >= 0 ? D.EL_COL[el] : D.INK;
			for (int i = 0; i < 4; i++) {
				float a = T * 14 + i * Mathf.PI / 2;
				fxInk.Crescent(ppos + new Vector2(0, 40), 250 - i * 35, a, a + 1.5f, 34, new Color(wc.r, wc.g, wc.b, 0.7f));
			}
		}

		// --- foes
		foreach (var f in foes) {
			ground.Ellipse(f.pos, f.d.r * f.scale * 1.15f, f.d.r * f.scale * 0.42f, new Color(0, 0, 0, f.dead ? 0.1f : 0.3f));
			if (f.elite && !f.dead) ground.Ring(f.pos, f.d.r * 1.5f, 4, new Color(0.78f, 0.18f, 0.12f, 0.6f + 0.2f * Mathf.Sin(T * 6)), 24);
			if (f.sr == null) continue;
			float walkBob = 0;
			if (f.walk != null) {
				Sprite fs = f.walk[0];
				if (f.mv != null && f.mv.steps[f.si].t != "wait" && f.mv.steps[f.si].t != "blink") fs = f.resolved ? (f.hit != null ? f.hit : fs) : (f.wind != null ? f.wind : fs);
				else if (f.moving) fs = f.walk[(int)(f.animT * 7) % f.walk.Length];
				f.sr.sprite = fs;
			} else if (f.moving) walkBob = Mathf.Abs(Mathf.Sin(f.animT * 9)) * 7;
			float k = f.walk != null ? f.scale : f.d.h * f.scale / (f.sr.sprite != null ? f.sr.sprite.bounds.size.y * 100f : f.d.h);
			float sx = 1, sy = 1 + Mathf.Sin(T * 2.4f + f.pos.x) * 0.012f, rot = 0, flash = 0, alpha = 1;
			Color fc = Color.white;
			bool right = ppos.x >= f.pos.x;
			if (f.spawn > 0) alpha = 1 - f.spawn / 0.75f;
			if (f.mv != null && !f.resolved) {
				float u = Mathf.Clamp01(f.stT / Mathf.Max(0.01f, f.mv.steps[f.si].wind));
				sy *= 1 - 0.07f * u; sx = 1 + 0.06f * u;
				rot = (right ? 1 : -1) * 6 * u;
				if (u > 0.7f) { flash = 0.4f; fc = new Color(1f, 0.25f, 0.2f); }
			} else if (f.mv != null && f.stT < f.mv.steps[f.si].wind + 0.12f) rot = (right ? -1 : 1) * 9;
			if (f.broken > 0) { rot = 14 + Mathf.Sin(T * 12) * 4; flash = 0.25f; fc = new Color(1f, 0.9f, 0.5f); }
			if (f.flash > 0) { flash = 0.6f; fc = Color.white; }
			if (f.dead) { alpha = 1 - f.deadT / 0.45f; flash = 0.9f; fc = D.INK; sy *= 1 - f.deadT; sx *= 1 + f.deadT * 0.6f; }
			if (f.walk == null && f.moving && rot == 0) rot = Mathf.Sin(f.animT * 9) * 4;
			Place(f.sr, f.pos, f.z + walkBob);
			f.sr.flipX = !right;
			f.sr.transform.localScale = new Vector3(k * sx, k * sy, 1);
			f.sr.transform.rotation = Quaternion.Euler(0, 0, rot);
			Color tint = f.slow > 0 ? new Color(0.7f, 0.85f, 1f) : (f.burn > 0 ? new Color(1f, 0.8f, 0.7f) : (f.poison > 0 ? new Color(0.8f, 1f, 0.75f) : Color.white));
			tint.a = alpha;
			f.sr.color = tint;
			f.sr.material.SetFloat("_Flash", flash);
			f.sr.material.SetColor("_FlashColor", fc);
			// bars
			if (!f.dead && f.spawn <= 0 && !f.d.boss) {
				float top = f.pos.y + f.z + f.d.h * f.scale + 12, x0 = f.pos.x - 30;
				if (f.hp < f.maxHp || f.posv > 0) {
					fxInk.Rect(x0 - 2, top - 2, 64, 13, new Color(0.07f, 0.06f, 0.06f, 0.85f));
					fxInk.Rect(x0, top + 3, 60 * Mathf.Clamp01(f.hp / f.maxHp), 6, new Color(0.82f, 0.2f, 0.14f));
					fxInk.Rect(x0, top, 60 * Mathf.Clamp01(f.posv / f.posMax), 3, f.broken > 0 ? Color.white : new Color(0.95f, 0.8f, 0.35f));
				}
				if (f.mark >= 0) { fxInk.Circle(new Vector2(x0 - 14, top + 5), 9, D.INK, 12); fxInk.Circle(new Vector2(x0 - 14, top + 5), 6.5f, D.EL_COL[f.mark], 12); }
			}
		}

		// --- effects layer
		foreach (var s in slashes) {
			float a = 1 - s.t / 0.26f, reveal = Mathf.Clamp01(s.t / 0.06f);
			Color ink = new Color(0.07f, 0.06f, 0.06f, a * 0.9f);
			Color inner = s.col == D.INK ? new Color(0.95f, 0.93f, 0.88f, a) : new Color(s.col.r, s.col.g, s.col.b, a);
			if (s.line) {
				fxInk.Brush(s.pos, s.pos + s.dir * s.len * reveal, s.wid * 0.9f, ink);
				fxInk.Brush(s.pos + s.dir * 10, s.pos + s.dir * s.len * reveal * 0.96f, s.wid * 0.35f, inner);
			} else {
				float a0 = Mathf.Atan2(s.dir.y, s.dir.x) - s.w / 2;
				fxInk.Crescent(s.pos, s.r, a0, a0 + s.w * reveal, s.r * 0.4f, ink);
				fxInk.Crescent(s.pos, s.r * 0.97f, a0 + 0.05f, a0 + s.w * reveal - 0.05f, s.r * 0.14f, inner);
			}
		}
		foreach (var s in shots) {
			Vector2 vn = s.vel.normalized;
			if (s.mine) {
				Color c = s.el >= 0 ? D.EL_COL[s.el] : new Color(0.95f, 0.93f, 0.88f);
				fxInk.Brush(s.pos - vn * 56, s.pos + vn * 18, s.r * 1.5f, D.INK);
				fxInk.Brush(s.pos - vn * 40, s.pos + vn * 12, s.r * 0.6f, c);
			} else {
				fxInk.Brush(s.pos - vn * 34, s.pos, s.r * 1.3f, new Color(0.07f, 0.06f, 0.06f, 0.7f));
				fxInk.Circle(s.pos, s.r + 3, D.INK, 12);
				fxInk.Circle(s.pos, s.r - 1, s.pool ? new Color(0.45f, 0.75f, 0.3f) : new Color(0.92f, 0.3f, 0.2f), 12);
			}
		}
		DrawStage();
		foreach (var p in parts) {
			float u = p.life / p.max;
			fxInk.Circle(p.pos, p.r * (0.4f + 0.6f * u), new Color(p.col.r, p.col.g, p.col.b, p.col.a * Mathf.Min(1, u * 2)), 8);
		}
		ground.Apply(); fxInk.Apply();
	}

	// ------------------------------------------------------------------ GUI
	void Box(Rect r, Color c) { GUI.color = c; GUI.DrawTexture(r, white); GUI.color = Color.white; }

	void Lab(Rect r, string s, int size, Color c, TextAnchor a = TextAnchor.MiddleCenter, bool title = false, bool outline = true) {
		if (st == null) st = new GUIStyle(GUI.skin.label) { richText = false, wordWrap = true };
		st.font = title ? fTitle : fBody;
		st.fontSize = size;
		st.alignment = a;
		st.fontStyle = title ? FontStyle.Bold : FontStyle.Normal;
		if (outline) {
			st.normal.textColor = new Color(0, 0, 0, c.a * 0.8f);
			float o = Mathf.Max(1f, size * 0.06f);
			GUI.Label(new Rect(r.x - o, r.y, r.width, r.height), s, st);
			GUI.Label(new Rect(r.x + o, r.y, r.width, r.height), s, st);
			GUI.Label(new Rect(r.x, r.y - o, r.width, r.height), s, st);
			GUI.Label(new Rect(r.x, r.y + o, r.width, r.height), s, st);
		}
		st.normal.textColor = c;
		GUI.Label(r, s, st);
	}

	void Panel(Rect r, bool sel = false) {
		Box(new Rect(r.x - 4, r.y - 4, r.width + 8, r.height + 8), sel ? D.RED : D.INK);
		Box(r, D.PAPER);
		Box(new Rect(r.x + 6, r.y + 6, r.width - 12, 2), new Color(0.07f, 0.06f, 0.06f, 0.35f));
		Box(new Rect(r.x + 6, r.yMax - 8, r.width - 12, 2), new Color(0.07f, 0.06f, 0.06f, 0.35f));
	}

	void Seal(Rect r, string s, Color c, int size = 15) {
		Box(r, D.INK);
		Box(new Rect(r.x + 2, r.y + 2, r.width - 4, r.height - 4), c);
		Lab(r, s, size, Color.white, TextAnchor.MiddleCenter, true);
	}

	Vector2 W2G(Vector2 p) {
		Vector3 s = cam.WorldToScreenPoint(new Vector3(p.x * 0.01f, p.y * 0.01f, 0));
		return new Vector2(s.x / gs, (Screen.height - s.y) / gs);
	}

	// a menu entry that the mouse can also point at and click
	bool Hit(Rect r, int idx) {
		if (bot) return false;
		var e = Event.current;
		if (mouseMoved && r.Contains(e.mousePosition)) menuI = idx;
		if (e.type == EventType.MouseDown && e.button == 0 && r.Contains(e.mousePosition)) { menuI = idx; e.Use(); return true; }
		return false;
	}

	void OnGUI() {
		gs = Screen.height / GH;
		GW = Screen.width / gs;
		GUI.matrix = Matrix4x4.Scale(new Vector3(gs, gs, 1));
		if (Event.current.type == EventType.Repaint) {
			mouseMoved = (Event.current.mousePosition - guiMouse).sqrMagnitude > 0.5f;
			guiMouse = Event.current.mousePosition;
		}
		switch (state) {
			case "title": GuiTitle(); return;
			case "skills": GuiSkills(); return;
			case "sect": GuiSect(); return;
			case "weapon": GuiWeapon(); return;
			case "meta": GuiMeta(); return;
			case "help": GuiHelp(); return;
		}
		GuiWorld();
		if (state == "play") GuiElites();
		GuiHud();
		GuiSkillHud();
		if (state == "pick") GuiPick();
		else if (state == "event") GuiEvent();
		else if (state == "pause") GuiPause();
		else if (state == "dead" || state == "win") GuiEnd();
	}

	void GuiTitle() {
		Color ink = D.INK;
		Lab(new Rect(70, 70, 700, 110), "MẶC KIẾM LỤC", 86, ink, TextAnchor.MiddleLeft, true, false);
		Seal(new Rect(768, 92, 56, 56), "MẶC", D.RED, 17);
		Lab(new Rect(76, 176, 700, 34), "một kiếm · một nón lá · ngũ hành trong tay", 22, new Color(0.2f, 0.18f, 0.17f), TextAnchor.MiddleLeft, true, false);
		string[] m = { "KHỞI HÀNH", "TUYỆT KỸ", "TU LUYỆN", "CÁCH CHƠI", "THOÁT" };
		for (int i = 0; i < m.Length; i++) {
			var r = new Rect(76, 256 + i * 58, 320, 50);
			bool sel = menuI == i;
			if (sel) { Box(new Rect(r.x - 14, r.y + 8, 6, 36), D.RED); Box(new Rect(r.x - 4, r.y + 46, 250, 3), new Color(0.07f, 0.06f, 0.06f, 0.6f)); }
			Lab(r, m[i], sel ? 36 : 30, sel ? D.RED : ink, TextAnchor.MiddleLeft, true, false);
			if (Hit(r, i)) TitleAct(i);
		}
		Lab(new Rect(76, GH - 70, 800, 30), string.Format("NGỘ TÍNH {0}   ·   HẠ SƠN {1} LẦN   ·   KIẾP NẠN {2}   ·   CHUYẾN ĐI {3}", meta.ngo, meta.wins, meta.kiep, meta.runs), 17, new Color(0.25f, 0.22f, 0.2f), TextAnchor.MiddleLeft, false, false);
	}

	void Dim(float a) { Box(new Rect(0, 0, GW, GH), new Color(0.05f, 0.04f, 0.04f, a)); }

	void GuiWeapon() {
		Dim(0.55f);
		Lab(new Rect(0, 40, GW, 60), "CHỌN BINH KHÍ", 44, D.PAPER, TextAnchor.MiddleCenter, true);
		float w = 330, gap = 30, x0 = (GW - (w * 3 + gap * 2)) / 2;
		int w0 = Mathf.Clamp(menuI - 1, 0, D.WEAPONS.Length - 3);
		for (int i = w0; i < w0 + 3; i++) {
			var wd = D.WEAPONS[i];
			bool unl = meta.unl.Contains(wd.id), sel = menuI == i;
			var r = new Rect(x0 + (i - w0) * (w + gap), sel ? 140 : 155, w, 420);
			Panel(r, sel);
			Lab(new Rect(r.x, r.y + 24, w, 44), wd.name, 28, unl ? D.INK : new Color(0.4f, 0.38f, 0.36f), TextAnchor.MiddleCenter, true, false);
			Box(new Rect(r.x + 40, r.y + 76, w - 80, 2), D.RED);
			if (unl) {
				Lab(new Rect(r.x + 24, r.y + 92, w - 48, 90), wd.desc, 18, D.INK, TextAnchor.UpperCenter, false, false);
				Seal(new Rect(r.x + w / 2 - 70, r.y + 200, 140, 30), "TUYỆT CHIÊU", D.RED, 15);
				Lab(new Rect(r.x + 16, r.y + 240, w - 32, 36), wd.skillName, 22, D.INK, TextAnchor.MiddleCenter, true, false);
				Lab(new Rect(r.x + 24, r.y + 280, w - 48, 80), wd.skillDesc, 17, new Color(0.2f, 0.18f, 0.17f), TextAnchor.UpperCenter, false, false);
			} else {
				Lab(new Rect(r.x + 24, r.y + 150, w - 48, 120), "CHƯA MỞ\n\n" + wd.unlock, 19, new Color(0.35f, 0.33f, 0.3f), TextAnchor.UpperCenter, false, false);
			}
			if (Hit(r, i)) WeaponAct(i);
		}
		Lab(new Rect(0, GH - 80, GW, 30), "A / D chọn (6 binh khí)   ·   ENTER xuất phát   ·   ESC quay lại", 18, D.PAPER);
	}

	void GuiMeta() {
		Dim(0.6f);
		Lab(new Rect(0, 30, GW, 60), "TU LUYỆN", 44, D.PAPER, TextAnchor.MiddleCenter, true);
		Lab(new Rect(0, 88, GW, 30), "NGỘ TÍNH: " + meta.ngo, 22, new Color(1f, 0.85f, 0.5f));
		float w = 760, x = (GW - w) / 2;
		for (int i = 0; i < D.META.Length; i++) {
			var m = D.META[i];
			int lv = Up(m.id);
			bool sel = menuI == i, full = lv >= m.cost.Length;
			var r = new Rect(x, 140 + i * 82, w, 70);
			Panel(r, sel);
			Lab(new Rect(r.x + 24, r.y + 6, 300, 34), m.name, 24, D.INK, TextAnchor.MiddleLeft, true, false);
			Lab(new Rect(r.x + 24, r.y + 38, 480, 26), m.desc, 16, new Color(0.25f, 0.22f, 0.2f), TextAnchor.MiddleLeft, false, false);
			for (int k = 0; k < m.cost.Length; k++) Box(new Rect(r.x + 430 + k * 26, r.y + 18, 18, 18), k < lv ? D.RED : new Color(0.07f, 0.06f, 0.06f, 0.25f));
			Lab(new Rect(r.xMax - 170, r.y, 150, 70), full ? "VIÊN MÃN" : m.cost[lv] + " NGỘ", 20, full ? new Color(0.3f, 0.5f, 0.3f) : (meta.ngo >= m.cost[lv] ? D.RED : new Color(0.45f, 0.42f, 0.4f)), TextAnchor.MiddleRight, true, false);
			if (Hit(r, i)) MetaAct(i);
		}
		Lab(new Rect(0, GH - 60, GW, 30), "W / S chọn   ·   ENTER luyện   ·   ESC quay lại", 18, D.PAPER);
	}

	void GuiHelp() {
		Dim(0.6f);
		var r = new Rect((GW - 900) / 2, 50, 900, 620);
		Panel(r);
		Lab(new Rect(r.x, r.y + 16, r.width, 50), "CÁCH CHƠI", 36, D.INK, TextAnchor.MiddleCenter, true, false);
		string a = "WASD  di chuyển          CHUỘT TRÁI  đánh (giữ để liên hoàn)\nSHIFT  đỡ đòn          SPACE  khinh công (né xuyên đòn)          CHUỘT PHẢI  phóng phi kiếm          R  thu kiếm\nQ  tuyệt chiêu của binh khí (50 nội lực)          F  TUYỆT KỸ (hồi chiêu)          E  vào cửa, mua, trò chuyện          ESC  tạm dừng";
		Lab(new Rect(r.x + 40, r.y + 76, r.width - 80, 96), a, 18, D.INK, TextAnchor.UpperLeft, false, false);
		string b = "ĐỠ CHUẨN: bấm đỡ ngay trước khi đòn chạm. Không mất máu, đánh bật THẾ của địch, phản ám khí về chủ.\n" +
			"THẾ: thanh vàng trên đầu địch. Đầy thanh là PHÁ THẾ: địch choáng và nhận thêm 60% sát thương.\n" +
			"VÙNG ĐỎ TRÒN (nện đất, kiếm vũ) không đỡ được: phải khinh công né.\n" +
			"PHI KIẾM: cắm vào địch hoặc mặt đất; thu về thì chém mọi thứ trên đường bay. Lúc đi mang hành của ĐÒN ĐÁNH, lúc về mang hành của TUYỆT CHIÊU.\n\n" +
			"NGŨ HÀNH: bí kíp gắn một hành vào đòn đánh, khinh công, đỡ đòn hoặc tuyệt chiêu. Trúng địch sẽ để lại ẤN của hành đó.\n" +
			"Đánh tiếp bằng một hành KHÁC lên địch đang mang ẤN:\n" +
			"   ·  TƯƠNG SINH (Kim-Thủy, Thủy-Mộc, Mộc-Hỏa, Hỏa-Thổ, Thổ-Kim): nổ lan ra chung quanh, hồi nội lực.\n" +
			"   ·  TƯƠNG KHẮC (các cặp còn lại): đánh sập THẾ, làm địch khựng.\n\n" +
			"Ba chương nối liền nhau: mỗi chương bốn ải, một trạm dừng và một trùm; cứ đi lên là tới. Ngã xuống thì mất chiêu thức, nhưng NGỘ TÍNH còn lại để TU LUYỆN.";
		Lab(new Rect(r.x + 40, r.y + 180, r.width - 80, 400), b, 17, new Color(0.15f, 0.13f, 0.12f), TextAnchor.UpperLeft, false, false);
		Lab(new Rect(r.x, r.yMax - 44, r.width, 30), "ENTER / ESC quay lại", 16, D.RED, TextAnchor.MiddleCenter, false, false);
	}

	void GuiWorld() {
		foreach (var t in texts) {
			Vector2 g = W2G(t.pos);
			float a = 1 - Mathf.Clamp01((t.t - 0.5f) / 0.4f);
			int size = t.size + (t.t < 0.1f ? (int)((0.1f - t.t) * 80) : 0);
			Lab(new Rect(g.x - 150, g.y - 20, 300, 40), t.s, size, new Color(t.col.r, t.col.g, t.col.b, a), TextAnchor.MiddleCenter, t.size >= 24);
		}
		if (state != "play") return;
		foreach (var d in doors) {
			Vector2 g = W2G(d.pos + new Vector2(0, 175));
			bool near = (d.pos - ppos).magnitude < 120;
			Lab(new Rect(g.x - 150, g.y - 20, 300, 34), D.RewardName(d.kind), near ? 24 : 20, near ? Color.white : D.PAPER, TextAnchor.MiddleCenter, true);
			if (near) {
				Lab(new Rect(g.x - 200, g.y + 10, 400, 26), D.RewardHint(d.kind), 16, D.PAPER);
				Vector2 e = W2G(d.pos + new Vector2(0, -40));
				Lab(new Rect(e.x - 100, e.y - 14, 200, 28), d.kind == "end" ? "[E] HẠ SƠN" : "[E] NHẬN", 18, new Color(1f, 0.9f, 0.5f));
			}
		}
		foreach (var it in items) {
			if (it.gone || it.kind == "npc") continue;
			Vector2 g = W2G(it.pos + new Vector2(0, it.sr != null ? 110 : 50));
			bool near = (it.pos - ppos).magnitude < 90;
			if (it.cost > 0) Lab(new Rect(g.x - 100, g.y - 4, 200, 26), it.cost + " lượng", 17, coins >= it.cost ? new Color(1f, 0.85f, 0.4f) : new Color(0.8f, 0.4f, 0.35f));
			if (near) {
				var r = new Rect(g.x - 190, g.y - 96, 380, 84);
				Panel(r);
				Lab(new Rect(r.x + 10, r.y + 4, r.width - 20, r.height - 8), it.label, 16, D.INK, TextAnchor.MiddleCenter, false, false);
				Vector2 e = W2G(it.pos + new Vector2(0, -36));
				Lab(new Rect(e.x - 100, e.y - 14, 200, 28), it.cost > 0 ? "[E] MUA" : "[E] CHỌN", 18, new Color(1f, 0.9f, 0.5f));
			}
		}
	}

	void GuiHud() {
		// hurt vignette
		if (hurtFx > 0) {
			float a = hurtFx * 0.6f;
			Box(new Rect(0, 0, GW, 26), new Color(0.7f, 0.1f, 0.08f, a)); Box(new Rect(0, GH - 26, GW, 26), new Color(0.7f, 0.1f, 0.08f, a));
			Box(new Rect(0, 0, 26, GH), new Color(0.7f, 0.1f, 0.08f, a)); Box(new Rect(GW - 26, 0, 26, GH), new Color(0.7f, 0.1f, 0.08f, a));
		}
		// life and inner force
		float bw = 280;
		Box(new Rect(24, 22, bw + 8, 30), D.INK);
		Box(new Rect(28, 26, bw, 22), new Color(0.2f, 0.17f, 0.16f));
		Box(new Rect(28, 26, bw * Mathf.Clamp01(hp / maxHp), 22), new Color(0.78f, 0.18f, 0.12f));
		Lab(new Rect(28, 26, bw, 22), Mathf.CeilToInt(Mathf.Max(0, hp)) + " / " + Mathf.RoundToInt(maxHp), 15, Color.white);
		Box(new Rect(24, 56, 228, 18), D.INK);
		Box(new Rect(28, 60, 220, 10), new Color(0.2f, 0.17f, 0.16f));
		Box(new Rect(28, 60, 220 * qi / 100f, 10), qi >= 50 ? new Color(0.95f, 0.8f, 0.35f) : new Color(0.45f, 0.65f, 0.8f));
		Box(new Rect(28 + 110, 58, 2, 14), D.INK);
		if (qi >= 50) Lab(new Rect(258, 52, 60, 26), "[Q]", 17, new Color(1f, 0.9f, 0.5f, 0.7f + 0.3f * Mathf.Sin(T * 6)), TextAnchor.MiddleLeft);
		for (int i = 0; i < dashMax; i++) {
			Box(new Rect(26 + i * 30, 82, 24, 12), D.INK);
			Box(new Rect(28 + i * 30, 84, 20, 8), i < dashes ? D.PAPER : new Color(0.3f, 0.28f, 0.26f));
		}
		for (int i = 0; i < swordMax; i++) {
			Box(new Rect(27 + i * 13, 100, 8, 20), D.INK);
			Box(new Rect(29 + i * 13, 102, 4, 16), i < swordsHeld ? new Color(0.93f, 0.95f, 0.97f) : new Color(0.3f, 0.28f, 0.26f));
		}
		if (swordsHeld == 0) Lab(new Rect(34 + swordMax * 13, 97, 200, 26), "[R] THU KIẾM", 15, new Color(1f, 0.9f, 0.5f, 0.7f + 0.3f * Mathf.Sin(T * 6)), TextAnchor.MiddleLeft);
		Lab(new Rect(28, 124, 300, 26), coins + " lượng", 18, new Color(1f, 0.85f, 0.4f), TextAnchor.MiddleLeft);
		// chapter
		string where = D.CH_NAME[ch] + "   ·   " + (roomKind == "boss" ? "TRÙM" : (SegAt(ppos.y).kind == "rest" ? "TRẠM DỪNG" : "ẢI " + Mathf.Min(step + 1, 4) + "/4"));
		Lab(new Rect(GW - 520, 18, 496, 30), where, 18, D.PAPER, TextAnchor.MiddleRight, true);
		if (!cleared && roomKind != "boss" && waves > 0) Lab(new Rect(GW - 520, 46, 496, 24), "ĐỢT " + Mathf.Max(1, wave) + "/" + waves, 15, D.PAPER, TextAnchor.MiddleRight);
		if (meta.kiep > 0) Lab(new Rect(GW - 520, 68, 496, 22), "KIẾP NẠN " + meta.kiep, 14, new Color(0.9f, 0.5f, 0.4f), TextAnchor.MiddleRight);
		// learned manuals
		int row = 0;
		foreach (var key in D.SLOT_NAME_KEYS) {
			if (key == "pas") continue;
			Boon b;
			float y = GH - 152 + row * 36;
			if (slot.TryGetValue(key, out b)) {
				Seal(new Rect(24, y, 50, 30), D.EL[b.el], D.EL_COL[b.el] * 0.85f, 14);
				Lab(new Rect(82, y, 420, 30), D.SlotName(key) + ": " + b.name + "  " + new string('●', Lv(b.id)), 15, D.PAPER, TextAnchor.MiddleLeft);
			} else {
				Box(new Rect(24, y, 50, 30), new Color(0.07f, 0.06f, 0.06f, 0.5f));
				Lab(new Rect(82, y, 420, 30), D.SlotName(key) + ": —", 15, new Color(0.91f, 0.86f, 0.75f, 0.6f), TextAnchor.MiddleLeft);
			}
			row++;
		}
		int pc = 0;
		foreach (var kv in boons) {
			var b = D.BoonById(kv.Key);
			if (b == null || b.slot != "pas") continue;
			Lab(new Rect(GW - 424, GH - 40 - pc * 24, 400, 24), b.name + "  " + new string('●', kv.Value), 14, D.PAPER, TextAnchor.MiddleRight);
			pc++;
		}
		// boss
		foreach (var f in foes) {
			if (!f.d.boss || f.dead) continue;
			float w = 520, x = (GW - w) / 2 + 40;
			Lab(new Rect(x, 26, w, 34), f.d.name, 24, D.PAPER, TextAnchor.MiddleCenter, true);
			Box(new Rect(x - 4, 62, w + 8, 26), D.INK);
			Box(new Rect(x, 66, w, 12), new Color(0.2f, 0.17f, 0.16f));
			Box(new Rect(x, 66, w * Mathf.Clamp01(f.hp / f.maxHp), 12), new Color(0.78f, 0.18f, 0.12f));
			Box(new Rect(x + w / 2 - 1, 64, 2, 16), D.INK);
			Box(new Rect(x, 80, w * Mathf.Clamp01(f.posv / f.posMax), 5), f.broken > 0 ? Color.white : new Color(0.95f, 0.8f, 0.35f));
			if (f.mark >= 0) Seal(new Rect(x - 62, 60, 50, 28), D.EL[f.mark], D.EL_COL[f.mark] * 0.85f, 13);
			break;
		}
		if (bannerT > 0 && state == "play") {
			float a = Mathf.Clamp01(bannerT) * Mathf.Clamp01((3.2f - bannerT) * 3);
			Box(new Rect(0, 150, GW, 96), new Color(0.05f, 0.04f, 0.04f, 0.55f * a));
			Lab(new Rect(0, 152, GW, 60), banner, 44, new Color(0.91f, 0.86f, 0.75f, a), TextAnchor.MiddleCenter, true);
			Lab(new Rect(0, 208, GW, 30), bannerSub, 17, new Color(0.91f, 0.86f, 0.75f, a));
		}
		if (fight == null && doors.Count == 0 && pickT <= 0 && bannerT <= 0 && state == "play" && SegAt(ppos.y).kind != "rest" && SegAt(ppos.y + 160).state == 0)
			Lab(new Rect(0, 110, GW, 30), "TIẾN LÊN ▲", 20, new Color(1f, 0.9f, 0.5f, 0.6f + 0.4f * Mathf.Sin(T * 5)), TextAnchor.MiddleCenter, true);
		if (toastT > 0) Lab(new Rect(0, GH - 150, GW, 34), toast, 20, new Color(1f, 0.9f, 0.55f, Mathf.Clamp01(toastT)), TextAnchor.MiddleCenter, true);
		if (cleared && doors.Count > 0 && state == "play" && pickT <= 0 && roomKind != "shop" && roomKind != "tra" && roomKind != "ky" && bannerT <= 0)
			Lab(new Rect(0, 110, GW, 30), "ẢI ĐÃ QUANG · nhận một trong hai phần thưởng phía trên", 17, new Color(0.91f, 0.86f, 0.75f, 0.7f + 0.3f * Mathf.Sin(T * 4)));
	}

	void GuiPick() {
		Dim(0.6f);
		Lab(new Rect(0, 40, GW, 56), pickKind == "luyen" ? "LUYỆN KHÍ" : "LĨNH NGỘ BÍ KÍP", 42, D.PAPER, TextAnchor.MiddleCenter, true);
		Lab(new Rect(0, 94, GW, 28), "A / D chọn   ·   ENTER nhận", 16, D.PAPER);
		float w = 320, gap = 28, x0 = (GW - (w * offers.Count + gap * (offers.Count - 1))) / 2;
		for (int i = 0; i < offers.Count; i++) {
			var o = offers[i];
			bool sel = menuI == i;
			var r = new Rect(x0 + i * (w + gap), sel ? 140 : 156, w, 460);
			Panel(r, sel);
			Color ec = o.b.el >= 0 ? D.EL_COL[o.b.el] * 0.85f : new Color(0.3f, 0.28f, 0.27f);
			ec.a = 1;
			Seal(new Rect(r.x + w / 2 - 38, r.y + 22, 76, 60), o.b.el >= 0 ? D.EL[o.b.el] : "TÂM", ec, 22);
			Lab(new Rect(r.x, r.y + 90, w, 24), D.SlotName(o.b.slot), 14, D.RED, TextAnchor.MiddleCenter, false, false);
			Lab(new Rect(r.x + 10, r.y + 114, w - 20, 40), o.b.name, 25, D.INK, TextAnchor.MiddleCenter, true, false);
			Lab(new Rect(r.x, r.y + 154, w, 24), "CẤP " + o.lvl + (Lv(o.b.id) > 0 ? "  (đang cấp " + Lv(o.b.id) + ")" : ""), 15, new Color(0.3f, 0.27f, 0.25f), TextAnchor.MiddleCenter, false, false);
			Box(new Rect(r.x + 40, r.y + 184, w - 80, 2), new Color(0.07f, 0.06f, 0.06f, 0.4f));
			Lab(new Rect(r.x + 24, r.y + 196, w - 48, 90), D.Desc(o.b, o.lvl), 17, D.INK, TextAnchor.UpperCenter, false, false);
			float y = r.y + 290;
			if (o.b.el >= 0) {
				Lab(new Rect(r.x + 20, y, w - 40, 44), D.EL_TEXT[o.b.el], 14, new Color(0.25f, 0.22f, 0.2f), TextAnchor.UpperCenter, false, false);
				y += 46;
				// how this phase combines with what is already carried
				foreach (var key in D.SLOT_NAME_KEYS) {
					Boon cur;
					if (key == o.b.slot || !slot.TryGetValue(key, out cur) || cur.el == o.b.el) continue;
					bool sinh = D.Relation(cur.el, o.b.el) == 1;
					Lab(new Rect(r.x + 16, y, w - 32, 22), (sinh ? "TƯƠNG SINH với " : "TƯƠNG KHẮC với ") + D.EL[cur.el] + " (" + D.SlotName(key).ToLower() + ")", 13, sinh ? new Color(0.2f, 0.45f, 0.25f) : new Color(0.6f, 0.2f, 0.15f), TextAnchor.MiddleCenter, false, false);
					y += 22;
				}
			}
			if (o.replace) {
				Boon cur;
				slot.TryGetValue(o.b.slot, out cur);
				Lab(new Rect(r.x + 16, r.yMax - 40, w - 32, 26), "THAY THẾ: " + (cur != null ? cur.name : ""), 14, D.RED, TextAnchor.MiddleCenter, false, false);
			}
			if (Hit(r, i)) PickAct(i);
		}
	}

	void GuiEvent() {
		Dim(0.6f);
		var r = new Rect((GW - 760) / 2, 130, 760, 440);
		Panel(r);
		Lab(new Rect(r.x, r.y + 18, r.width, 44), "CAO NHÂN ẨN THẾ", 32, D.INK, TextAnchor.MiddleCenter, true, false);
		Lab(new Rect(r.x + 50, r.y + 70, r.width - 100, 70), "“Kiếm của ngươi còn vội. Muốn học thì phải trả giá: bằng máu, hoặc bằng rượu.”", 18, new Color(0.2f, 0.18f, 0.17f), TextAnchor.MiddleCenter, true, false);
		string[] o = { "THỌ GIÁO  ·  mất 20 sinh lực, chọn một bí kíp cao hơn một cấp", "DÂNG RƯỢU  ·  trả 40 lượng, nâng cấp hai chiêu ngẫu nhiên", "CÁO TỪ" };
		for (int i = 0; i < 3; i++) {
			var b = new Rect(r.x + 50, r.y + 170 + i * 78, r.width - 100, 62);
			bool sel = menuI == i;
			Box(new Rect(b.x - 3, b.y - 3, b.width + 6, b.height + 6), sel ? D.RED : new Color(0.07f, 0.06f, 0.06f, 0.5f));
			Box(b, sel ? new Color(0.97f, 0.93f, 0.84f) : D.PAPER);
			Lab(b, o[i], 18, D.INK, TextAnchor.MiddleCenter, false, false);
			if (Hit(b, i)) EventAct(i);
		}
	}

	void GuiPause() {
		Dim(0.6f);
		Lab(new Rect(0, 200, GW, 70), "TẠM DỪNG", 52, D.PAPER, TextAnchor.MiddleCenter, true);
		string[] o = { "TIẾP TỤC", "BỎ CHUYẾN ĐI", "HÌNH NHÂN VẬT: " + (meta.rig ? "GHÉP XƯƠNG" : "KHUNG VẼ") };
		for (int i = 0; i < 3; i++) {
			var b = new Rect((GW - 360) / 2, 320 + i * 70, 360, 54);
			Lab(b, o[i], menuI == i ? 32 : 26, menuI == i ? new Color(1f, 0.85f, 0.5f) : D.PAPER, TextAnchor.MiddleCenter, true);
			if (Hit(b, i)) PauseAct(i);
		}
	}

	void GuiEnd() {
		bool win = state == "win";
		float a = Mathf.Clamp01((T - endT) / 1.0f);
		Dim(0.7f * a);
		Lab(new Rect(0, 150, GW, 90), win ? "HẠ SƠN" : "KIẾM GÃY", 76, win ? new Color(1f, 0.88f, 0.55f, a) : new Color(0.85f, 0.25f, 0.18f, a), TextAnchor.MiddleCenter, true);
		Lab(new Rect(0, 240, GW, 34), win ? "Ba ngọn núi đã ở lại sau lưng. Giang hồ thêm một cái tên." : "Mực chưa khô, đường còn dài. Mang NGỘ TÍNH về mà luyện tiếp.", 19, new Color(0.91f, 0.86f, 0.75f, a));
		string s = string.Format("Tới: {0}  ·  ải thứ {1}\nHạ {2} địch  ·  qua {3} ải  ·  {4} trùm\nThời gian {5}:{6:00}\n\n+{7} NGỘ TÍNH", D.CH_NAME[ch], Mathf.Min(step + 1, 6), kills, rooms, bossKills, (int)(runTime / 60), (int)(runTime % 60), earned);
		Lab(new Rect(0, 300, GW, 190), s, 21, new Color(0.91f, 0.86f, 0.75f, a));
		if (win) Lab(new Rect(0, 500, GW, 30), "KIẾP NẠN tăng lên " + meta.kiep + ": chuyến sau địch mạnh hơn.", 17, new Color(0.9f, 0.5f, 0.4f, a));
		if (T - endT > 1.2f) Lab(new Rect(0, 560, GW, 30), "ENTER về sơn môn", 18, new Color(1f, 0.9f, 0.5f, 0.6f + 0.4f * Mathf.Sin(T * 4)));
	}
}
