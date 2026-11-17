using System.Collections.Generic;
using UnityEngine;

// Foes, bosses, the five-phase reactions, shots and the test bot.
public partial class Game {

	void UpFoes(float dt) {
		for (int i = foes.Count - 1; i >= 0; i--) {
			var f = foes[i];
			if (f.dead) {
				f.deadT += dt;
				if (f.deadT > 0.45f) { if (f.sr != null) Destroy(f.sr.gameObject); foes.RemoveAt(i); }
				continue;
			}
			f.flash -= dt;
			f.moving = false;
			if (f.spawn > 0) { f.spawn -= dt; continue; }
			// statuses
			f.bleed -= dt; f.slow -= dt; f.markT -= dt;
			if (f.markT <= 0) f.mark = -1;
			f.dotT -= dt;
			if (f.dotT <= 0) {
				f.dotT = 0.5f;
				float dot = 0;
				if (f.poison > 0) dot += f.poisonD * 0.5f;
				if (f.burn > 0) dot += f.burnD * 0.5f;
				if (dot > 0) {
					f.hp -= dot;
					Text(f.pos + new Vector2(0, f.d.h * 0.8f), Mathf.CeilToInt(dot).ToString(), f.burn > 0 ? D.EL_COL[3] : D.EL_COL[1], 15);
					if (f.hp <= 0) { Kill(f); continue; }
				}
			}
			f.poison -= dt; f.burn -= dt;
			// posture recovers when left alone
			f.posT -= dt;
			if (f.posT <= 0 && f.broken <= 0) f.posv = Mathf.Max(0, f.posv - f.posMax * 0.25f * dt);
			f.pos += f.kb * dt;
			f.kb = Vector2.MoveTowards(f.kb, Vector2.zero, 1800 * dt);
			if (f.broken > 0) {
				f.broken -= dt;
				if (f.broken <= 0) f.posv = 0;
				f.pos = Confine(f.pos, f.d.r);
				continue;
			}
			if (f.stun > 0) { f.stun -= dt; f.pos = Confine(f.pos, f.d.r); continue; }
			for (int m = 0; m < f.mcd.Length; m++) f.mcd[m] -= dt;
			f.cd -= dt;
			Vector2 to = ppos - f.pos;
			float dist = to.magnitude;
			Vector2 dir = dist > 0.01f ? to / dist : Vector2.right;
			float sp = f.d.spd * (f.slow > 0 ? 0.55f : 1) * (f.elite ? 1.1f : 1) * (f.afx == "toc" ? 1.45f : 1);
			if (f.mv != null) { RunStep(f, dt, dir); f.pos = Confine(f.pos, f.d.r); continue; }
			// choose a move
			// only a few foes wind up at once, so a crowd stays readable
			if (f.cd <= 0 && (f.d.boss || Busy() < 4 + ch)) {
				int pick = -1, seen = 0;
				float hpF = f.hp / f.maxHp;
				for (int m = 0; m < f.d.moves.Length; m++) {
					var mv = f.d.moves[m];
					if (f.mcd[m] > 0 || dist > mv.rng || dist < mv.min || hpF > mv.hpBelow || (mv.once && f.used[m])) continue;
					if (mv.once) { pick = m; break; }
					seen++;
					if (rng.Next(seen) == 0) pick = m;
				}
				if (pick >= 0) {
					var mv = f.d.moves[pick];
					f.used[pick] = true;
					float rage = f.d.boss && hpF < 0.5f ? 0.7f : 1;
					f.mcd[pick] = mv.cd * rage * Rnd(0.9f, 1.2f);
					f.mv = mv; f.si = 0;
					StartStep(f);
					continue;
				}
			}
			// walk
			Vector2 want;
			if (f.d.keep > 0) {
				if (dist < f.d.keep * 0.7f) want = -dir;
				else if (dist > f.d.keep * 1.15f) want = dir;
				else want = new Vector2(-dir.y, dir.x) * (((foes.IndexOf(f) & 1) == 0) ? 1 : -1) * 0.6f;
			} else {
				float near = f.d.moves[f.d.moves.Length > 1 && f.d.boss ? 0 : f.d.moves.Length - 1].rng * 0.75f;
				if (f.d.boss) near = 150;
				want = dist > near ? dir : Vector2.zero;
			}
			foreach (var o in foes) {
				if (o == f || o.dead) continue;
				Vector2 d = f.pos - o.pos;
				float need = f.d.r + o.d.r + 14;
				if (d.sqrMagnitude < need * need && d.sqrMagnitude > 0.01f) want += d.normalized * 0.9f;
			}
			f.pos += Vector2.ClampMagnitude(want, 1) * sp * dt;
			f.moving = want.sqrMagnitude > 0.04f;
			if (f.moving) f.animT += dt * sp / 150f;
			f.pos = Confine(f.pos, f.d.r);
		}
	}

	void StartStep(Foe f) {
		var s = f.mv.steps[f.si];
		f.stT = 0; f.resolved = false;
		f.from = f.pos;
		Vector2 to = ppos - f.pos;
		f.aim = to.sqrMagnitude > 1 ? to.normalized : Vector2.right;
		f.aimPos = ppos;
		if (s.t == "blink") {
			Puff(f.pos, D.INK, 12, 200);
			AddGhost(f.sr, f.pos, new Color(0.07f, 0.06f, 0.08f, 0.6f), 0.35f);
			Vector2 side = RndDir();
			f.pos = Confine(ppos + side * 230, f.d.r);
			Puff(f.pos, D.INK, 12, 200);
			sfx.Play("dash", 0.5f, 1.4f);
		} else if (s.t == "slam") {
			Vector2 at = s.leap ? ppos : f.pos + f.aim * 60;
			f.aimPos = Confine(at, f.d.r);
			blasts.Add(new Blast { pos = f.aimPos, r = s.r, wind = s.wind, dmg = s.dmg * f.dmgMul });
		}
	}

	void RunStep(Foe f, float dt, Vector2 dirNow) {
		var s = f.mv.steps[f.si];
		f.stT += dt * (f.slow > 0 ? 0.75f : 1);
		if (f.stT < s.wind * 0.65f && (s.t == "arc" || s.t == "line" || s.t == "shoot")) f.aim = dirNow;
		if (s.t == "slam" && s.leap && f.stT < s.wind) {
			float u = f.stT / s.wind;
			f.pos = Vector2.Lerp(f.from, f.aimPos, u * u * (3 - 2 * u));
			f.z = Mathf.Sin(u * Mathf.PI) * 220;
		} else f.z = 0;
		if (!f.resolved && f.stT >= s.wind) {
			f.resolved = true;
			Resolve(f, s);
			if (f.dead) return;
		}
		if (f.resolved && s.t == "arc" && s.lunge > 0 && f.stT < s.wind + 0.12f) f.pos += f.aim * s.lunge * dt;
		if (f.stT >= s.wind + s.rec) {
			f.si++;
			if (f.si >= f.mv.steps.Length) { f.mv = null; f.cd = f.d.boss ? (f.hp < f.maxHp * 0.5f ? 0.35f : 0.6f) : Rnd(0.4f, 0.9f); }
			else StartStep(f);
		}
	}

	void Resolve(Foe f, Step s) {
		float dmg = s.dmg * f.dmgMul;
		float a0 = Mathf.Atan2(f.aim.y, f.aim.x);
		switch (s.t) {
			case "arc":
				slashes.Add(new Slash { pos = f.pos + new Vector2(0, 45), dir = f.aim, r = s.r, w = s.w, col = D.RED });
				sfx.Play("slash", 0.4f, 0.8f);
				if (ArcHit(f.pos, f.aim, s.r, s.w, ppos, 18)) HitPlayer(dmg, f, true, f.pos);
				break;
			case "line":
				slashes.Add(new Slash { pos = f.pos + new Vector2(0, 45), dir = f.aim, line = true, len = s.len, wid = s.wid, col = D.RED });
				sfx.Play("slash", 0.45f, 0.7f);
				if (LineHit(f.pos, f.aim, s.len, s.wid, ppos, 18)) HitPlayer(dmg, f, true, f.pos);
				if (s.dash && !f.dead && f.broken <= 0) {
					Vector2 end = Confine(f.pos + f.aim * (s.len - 50), f.d.r);
					for (int gi = 0; gi < 5; gi++) AddGhost(f.sr, Vector2.Lerp(f.pos, end, gi / 5f), new Color(0.07f, 0.06f, 0.08f, 0.2f + gi * 0.08f), 0.2f + gi * 0.05f);
					f.pos = end;
				}
				break;
			case "shoot":
				for (int i = 0; i < s.n; i++) {
					float a = a0 + (s.n == 1 ? 0 : Mathf.Lerp(-s.spread, s.spread, i / (float)(s.n - 1)));
					shots.Add(new Shot { pos = f.pos + new Vector2(0, 55), vel = new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * s.spd, dmg = dmg, pool = s.pool });
				}
				sfx.Play("shoot", 0.5f);
				break;
			case "radial":
				for (int i = 0; i < s.n; i++) {
					float a = a0 + f.si * 0.22f + i * Mathf.PI * 2 / s.n;
					shots.Add(new Shot { pos = f.pos + new Vector2(0, 55), vel = new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * s.spd, dmg = dmg, life = 4 });
				}
				sfx.Play("shoot", 0.6f, 0.7f);
				break;
			case "ring":
				wavesFx.Add(new Wave { pos = f.pos, r = 30, spd = s.spd, dmg = dmg, max = s.r });
				sfx.Play("gong", 0.5f, 1.3f);
				shake = Mathf.Max(shake, 5);
				break;
			case "rain":
				for (int i = 0; i < s.n; i++) {
					Vector2 p = i == 0 ? ppos : ppos + RndDir() * Rnd(60, 330);
					blasts.Add(new Blast { pos = Confine(p, 10), r = s.r, wind = 0.75f + i * 0.14f, dmg = dmg });
				}
				break;
			case "summon":
				for (int i = 0; i < s.n; i++) Spawn(s.id, f.pos + RndDir() * 180, false);
				sfx.Play("gong", 0.7f);
				Banner(f.d.name, "gọi viện binh!");
				break;
		}
	}

	// returns true when the hit landed on the body
	bool HitPlayer(float dmg, Foe src, bool parryable, Vector2 from) {
		if (inv > 0 || act == "dash" || state != "play") return false;
		if (act == "atk" && weapon.mech == "heavy") dmg *= 0.6f;   // the mace does not flinch
		if (parryable && guard) {
			if (gt <= pwin) { Parried(src); return false; }
			dmg *= 0.3f;
			sfx.Play("block", 0.7f);
			Text(ppos + new Vector2(0, 140), "ĐỠ", D.PAPER, 18);
			qi = Mathf.Min(100, qi + 3 * qiMul);
			if (src != null) AddPosture(src, src.posMax * 0.1f);
		} else {
			sfx.Play("hurt", 0.8f);
			shake = Mathf.Max(shake, 10);
			stop = Mathf.Max(stop, 0.06f);
			hurtFx = 0.4f;
			Puff(ppos, D.RED, 8, 220);
		}
		hp -= dmg;
		inv = 0.55f;
		pflash = 0.15f;
		Text(ppos + new Vector2(0, 120), "-" + Mathf.CeilToInt(dmg), new Color(1f, 0.4f, 0.3f), 22);
		return true;
	}

	void Parried(Foe src) {
		sfx.Play("clang", 0.9f);
		stop = Mathf.Max(stop, 0.09f);
		slow = 0.25f;
		shake = Mathf.Max(shake, 8);
		qi = Mathf.Min(100, qi + 15 * qiMul);
		inv = Mathf.Max(inv, 0.3f);
		riposte = Lv("ripo") > 0;
		if (meta.sect == "thiet") Heal(4);
		Text(ppos + new Vector2(0, 150), "PHẢN!", new Color(1f, 0.9f, 0.5f), 30);
		for (int i = 0; i < 10; i++) {
			float l = Rnd(0.15f, 0.35f);
			parts.Add(new Part { pos = ppos + new Vector2(0, 60) + aimDir * 30, vel = RndDir() * Rnd(200, 520), r = Rnd(2, 5), life = l, max = l, col = new Color(1f, 0.92f, 0.6f) });
		}
		if (src != null && !src.dead) {
			AddPosture(src, src.posMax * (src.d.boss ? 0.24f : 0.5f));
			if (!src.d.boss && src.broken <= 0) { src.stun = 0.5f; src.mv = null; src.z = 0; }
		}
		int el = SlotEl("parry");
		if (el >= 0) Burst(ppos, 210, 26 * SlotLv("parry") * dmgMul, el, SlotLv("parry"), true);
	}

	void AddPosture(Foe f, float v) {
		if (f.dead || f.broken > 0) return;
		f.posv += v;
		f.posT = 2.2f;
		if (f.posv >= f.posMax) {
			f.broken = f.d.boss ? 3.0f : 2.2f;
			f.mv = null; f.z = 0;
			f.posv = f.posMax;
			sfx.Play("gong", 0.8f, 1.5f);
			Text(f.pos + new Vector2(0, f.d.h + 40), "PHÁ THẾ!", new Color(1f, 0.85f, 0.4f), 28);
			Puff(f.pos, D.PAPER, 12, 260);
			stop = Mathf.Max(stop, 0.08f);
		}
	}

	public void HurtFoe(Foe f, float dmg, int el, int lvl, float posMul, Vector2 dir, bool react = true, bool gain = true) {
		if (f.dead || f.spawn > 0) return;
		bool isCrit = crit > 0 && Rnd() < crit;
		if (isCrit) dmg *= 2;
		if (meta.sect == "cuong") dmg *= 1 + 0.6f * (1 - Mathf.Clamp01(hp / maxHp));
		if (f.afx == "giap" && f.broken <= 0) dmg *= 0.45f;   // armoured elites must be broken first
		if (f.broken > 0) dmg *= 1.6f + Lv("break") * 0.4f;
		if (f.bleed > 0) dmg *= 1.25f;
		float pos = dmg * posMul;
		if (f.d.guard && f.broken <= 0 && f.stun <= 0) {
			// shield bearers shrug off blows from the side they face (they always face the player)
			if (Vector2.Dot(dir, (f.pos - ppos).normalized) > 0.2f) { dmg *= 0.3f; pos *= 1.6f; sfx.Play("block", 0.4f); }
		}
		f.hp -= dmg;
		f.flash = 0.12f;
		if (!f.d.boss) f.kb += dir * 150;
		AddPosture(f, pos * (el == D.THO ? 2 : 1));
		if (gain) qi = Mathf.Min(100, qi + 4 * qiMul);
		sfx.Play("hit", 0.5f, isCrit ? 0.8f : 1f);
		Text(f.pos + new Vector2(0, f.d.h * f.scale + 10), Mathf.CeilToInt(dmg).ToString(), isCrit ? new Color(1f, 0.8f, 0.2f) : Color.white, isCrit ? 26 : 18);
		Puff(f.pos, D.INK, 3, 200);
		if (el >= 0) ApplyEl(f, el, Mathf.Max(1, lvl), react);
		if (f.hp <= 0) Kill(f);
	}

	void ApplyEl(Foe f, int el, int lvl, bool react) {
		if (f.dead) return;
		switch (el) {
			case D.KIM: f.bleed = 4; break;
			case D.MOC: f.poison = 4; f.poisonD = 5 + 4 * lvl; break;
			case D.THUY: f.slow = 3; break;
			case D.HOA: f.burn = 3; f.burnD = 8 + 5 * lvl; break;
			case D.THO: if (!f.d.boss && f.broken <= 0 && f.mv == null) f.stun = Mathf.Max(f.stun, 0.2f); break;
		}
		if (!react) return;
		if (f.mark < 0 || f.mark == el) { f.mark = el; f.markT = meta.sect == "hanh" ? 12 : 6; return; }
		int rel = D.Relation(f.mark, el);
		int old = f.mark;
		f.mark = -1;
		if (rel == 1) {
			// tuong sinh: the two phases feed each other and burst
			Text(f.pos + new Vector2(0, f.d.h + 60), "TƯƠNG SINH", Color.Lerp(D.EL_COL[old], D.EL_COL[el], 0.5f), 26);
			float dmg = (26 + 12 * lvl) * dmgMul * (1 + Lv("sinh") * 0.5f) * (meta.sect == "hanh" ? 1.5f : 1);
			qi = Mathf.Min(100, qi + 8 * qiMul);
			Heal(Lv("sinh") * 3);
			Burst(f.pos, 165, dmg, el, lvl, false);
			sfx.Play("burst", 0.8f);
		} else {
			// tuong khac: one phase overcomes the other and shatters the stance
			Text(f.pos + new Vector2(0, f.d.h + 60), "TƯƠNG KHẮC", D.EL_COL[el], 26);
			AddPosture(f, f.posMax * (f.d.boss ? 0.3f : 0.6f) * (meta.sect == "hanh" ? 1.5f : 1));
			if (!f.d.boss && f.broken <= 0) { f.stun = Mathf.Max(f.stun, 0.6f); f.mv = null; f.z = 0; }
			wavesFx.Add(new Wave { pos = f.pos, r = 10, spd = 500, dmg = 0, max = 110, hit = true });
			sfx.Play("clang", 0.6f, 0.7f);
			if (Lv("khac") > 0 && !f.dead) {
				f.hp -= Lv("khac") * 35 * dmgMul;
				if (f.hp <= 0) Kill(f);
			}
		}
	}

	// a round blast from the player's side
	public void Burst(Vector2 p, float r, float dmg, int el, int lvl, bool react) {
		Color c = el >= 0 ? D.EL_COL[el] : D.INK;
		wavesFx.Add(new Wave { pos = p, r = r * 0.3f, spd = r * 4, max = r, hit = true, col = c });
		Puff(p, c, 10, 300);
		var list = new List<Foe>(foes);
		foreach (var f in list) {
			if (f.dead || f.spawn > 0) continue;
			Vector2 d = f.pos - p;
			if (d.magnitude <= r + f.d.r) HurtFoe(f, dmg, el, lvl, 1, d.sqrMagnitude > 1 ? d.normalized : Vector2.up, react, false);
		}
	}

	void Kill(Foe f) {
		if (f.dead) return;
		f.dead = true; f.deadT = 0; f.mv = null;
		kills++;
		Puff(f.pos, D.INK, f.d.boss ? 40 : 14, f.d.boss ? 420 : 260);
		Puff(f.pos, D.RED, 5, 200);
		if (stains.Count < 60) stains.Add(new Vector3(f.pos.x, f.pos.y, f.d.r * 1.6f));
		int c = f.d.boss ? 0 : (f.elite ? 12 : 2 + rng.Next(4));
		if (c > 0) { coins += Mathf.RoundToInt(c * coinMul); }
		Heal(Lv("leech") * 2 + (meta.sect == "cuong" ? 1 : 0));
		if (f.afx == "bao") blasts.Add(new Blast { pos = f.pos, r = 190, wind = 0.9f, dmg = 20 * f.dmgMul });
		// a streak of quick kills pays out every tenth
		chain++; chainT = 3.2f;
		if (chain % 10 == 0) { Heal(2); qi = Mathf.Min(100, qi + 12); Text(ppos + new Vector2(0, 190), "LIÊN TRẢM ×" + chain, new Color(1f, 0.6f, 0.3f), 30); }
		if (f.d.boss) { stop = 0.25f; slow = 1.2f; shake = 18; sfx.Play("gong"); }
		else sfx.Play("hit", 0.7f, 0.6f);
	}

	void UpShots(float dt) {
		for (int i = shots.Count - 1; i >= 0; i--) {
			var s = shots[i];
			s.life -= dt;
			s.pos += s.vel * dt;
			Vector2 g = s.pos - new Vector2(0, 55);   // where it is over the ground
			bool gone = s.life <= 0 || g.x < PR.xMin - 60 || g.x > PR.xMax + 60 || g.y < PR.yMin - 60 || g.y > PR.yMax + 80;
			if (!gone && s.mine) {
				foreach (var f in foes) {
					if (f.dead || f.spawn > 0 || s.hit.Contains(f)) continue;
					if ((f.pos - g).magnitude < f.d.r * f.scale + s.r + 8) {
						s.hit.Add(f);
						HurtFoe(f, s.dmg, s.el, s.lvl, 1, s.vel.normalized);
						if (s.bounce > 0) {
							// the fan's darts skip on to the nearest foe not yet hit
							Foe nb = null;
							foreach (var o in foes) if (!o.dead && o.spawn <= 0 && !s.hit.Contains(o) && (o.pos - g).magnitude < 400 && (nb == null || (o.pos - g).sqrMagnitude < (nb.pos - g).sqrMagnitude)) nb = o;
							if (nb != null) { s.bounce--; s.vel = (nb.pos - g).normalized * s.vel.magnitude; s.life = Mathf.Max(s.life, 0.45f); break; }
						}
						s.pierce--;
						if (s.pierce < 0) { gone = true; break; }
					}
				}
			} else if (!gone) {
				if ((ppos - g).magnitude < 20 + s.r) {
					if (guard && gt <= pwin && inv <= 0 && act != "dash") {
						// a clean parry sends it back
						Parried(null);
						s.mine = true; s.vel = -s.vel * 1.5f; s.dmg *= 3; s.life = 2; s.hit = new List<Foe>(); s.pool = false;
						s.el = SlotEl("parry"); s.lvl = SlotLv("parry");
					} else {
						if (HitPlayer(s.dmg, null, true, s.pos) || guard) gone = true;
					}
				}
			}
			if (gone) {
				if (s.pool && !s.mine) pools.Add(new Pool { pos = g, r = 70, t = 4 });
				shots.RemoveAt(i);
			}
		}
	}

	void UpFx(float dt) {
		for (int i = wavesFx.Count - 1; i >= 0; i--) {
			var w = wavesFx[i];
			w.r += w.spd * dt;
			if (!w.hit && Mathf.Abs((ppos - w.pos).magnitude - w.r) < 20) { w.hit = true; HitPlayer(w.dmg, null, true, w.pos); }
			if (w.r >= w.max) wavesFx.RemoveAt(i);
		}
		for (int i = blasts.Count - 1; i >= 0; i--) {
			var b = blasts[i];
			b.t += dt;
			if (b.t >= b.wind) {
				if ((ppos - b.pos).magnitude < b.r + 12) HitPlayer(b.dmg, null, false, b.pos);
				Puff(b.pos, D.INK, 10, 320);
				wavesFx.Add(new Wave { pos = b.pos, r = b.r * 0.5f, spd = b.r * 3, max = b.r * 1.15f, hit = true });
				shake = Mathf.Max(shake, 7);
				sfx.Play("drum", 0.7f);
				blasts.RemoveAt(i);
			}
		}
		for (int i = pools.Count - 1; i >= 0; i--) {
			var p = pools[i];
			p.t -= dt; p.tick -= dt;
			if (p.tick <= 0 && (ppos - p.pos).magnitude < p.r && act != "dash") {
				p.tick = 0.5f;
				hp -= 3; pflash = 0.1f;
				Text(ppos + new Vector2(0, 120), "-3", D.EL_COL[1], 16);
			}
			if (p.t <= 0) pools.RemoveAt(i);
		}
		for (int i = parts.Count - 1; i >= 0; i--) {
			var p = parts[i];
			p.life -= dt;
			p.pos += p.vel * dt;
			p.vel *= 1 - 3 * dt;
			p.vel.y -= p.grav * dt;
			if (p.life <= 0) parts.RemoveAt(i);
		}
		for (int i = slashes.Count - 1; i >= 0; i--) { slashes[i].t += dt; if (slashes[i].t > 0.26f) slashes.RemoveAt(i); }
		for (int i = texts.Count - 1; i >= 0; i--) { texts[i].t += dt; texts[i].pos.y += 50 * dt; if (texts[i].t > 0.9f) texts.RemoveAt(i); }
		shake = Mathf.Max(0, shake - 40 * dt);
		for (int i = ghosts.Count - 1; i >= 0; i--) {
			ghosts[i].life -= dt;
			if (ghosts[i].life <= 0) { Destroy(ghosts[i].sr.gameObject); ghosts.RemoveAt(i); }
		}
	}

	// --- test bot: plays the game by itself (used with -bot on the command line)
	float botShotT;
	int botShotN;
	string botLast = "";

	void BotInput(ref Inp i) {
		bool pulse = ((int)(T * 6)) % 2 == 0;
		if (state != "play") {
			i.ok = pulse && T > 3f && T - stateT > 4.5f && state != "dead" && state != "win";
			if (state == "event") menuI = 2;
			return;
		}
		Foe best = null;
		float bd = 1e9f;
		foreach (var f in foes) {
			if (f.dead) continue;
			float d = (f.pos - ppos).magnitude;
			if (d < bd) { bd = d; best = f; }
		}
		if (best != null) {
			Vector2 to = best.pos - ppos;
			i.aim = best.pos;
			float want = weaponId == "phien" ? 330 : 95;
			i.mv = bd > want ? to.normalized : (bd < want * 0.6f ? -to.normalized : new Vector2(-to.y, to.x).normalized * 0.5f);
			i.atk = bd < want + 90;
			i.skill = qi >= 50 && pulse;
			i.thr = pulse && bd > 140 && bd < 700;
			i.tk = pulse && bd < 500;
			if (weapon.mech == "charge") { i.atk = ((int)(T * 1.2f)) % 2 == 0; i.mv = bd < 300 ? -to.normalized : Vector2.zero; }
			bool threat = false;
			foreach (var f in foes) if (!f.dead && f.mv != null && !f.resolved && f.stT > f.mv.steps[f.si].wind - 0.14f && (f.pos - ppos).magnitude < 320) threat = true;
			i.parry = threat;
			if (threat) i.atk = false;
			foreach (var b in blasts) if ((b.pos - ppos).magnitude < b.r + 30 && b.t > b.wind - 0.25f) { i.dash = pulse; i.mv = (ppos - b.pos).normalized; }
		} else if (cleared && pickT <= 0) {
			Vector2 target = ppos;
			bool found = false;
			foreach (var it in items) if (!it.gone && it.kind != "npc" && coins >= it.cost && it.kind != "luyen") { target = it.pos; found = true; break; }
			if (!found && doors.Count > 0) target = doors[(int)(seed & 1) % doors.Count].pos;
			else if (!found) target = new Vector2(SegAt(ppos.y + 260).r.center.x + Mathf.Sin(T * 1.7f) * 150, ppos.y + 260);
			Vector2 to = target - ppos;
			i.mv = to.magnitude > 40 ? to.normalized : Vector2.zero;
			i.aim = target;
			i.use = pulse && to.magnitude < 85;
		}
	}

	void BotShots() {
		if (shotDir == null) return;
		botShotT -= Time.unscaledDeltaTime;
		string key = state + ":" + ch + ":" + roomKind;
		bool newState = key != botLast;
		if ((newState && botShotT < 1.2f && T > 1.0f) || botShotT <= 0) {
			if (newState) { botLast = key; botShotT = 0.9f; return; }
			botShotT = 7f;
			botShotN++;
			System.IO.Directory.CreateDirectory(shotDir);
			ScreenCapture.CaptureScreenshot(System.IO.Path.Combine(shotDir, string.Format("s{0:00}_{1}_{2}_{3}.png", botShotN, state, ch, roomKind)));
		}
		if ((botEnd > 0 && Time.realtimeSinceStartup > botEnd) || ((state == "win" || state == "dead") && T - endT > 4)) {
			Debug.Log(string.Format("BOT END state={0} ch={1} step={2} rooms={3} kills={4} boons={5} hp={6}", state, ch, step, rooms, kills, boons.Count, hp));
			Application.Quit();
		}
	}
}
