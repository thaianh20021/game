using System.Collections.Generic;
using UnityEngine;

// One new mechanic per chapter, invented and written by Gemini (gen/mech.json); unlocked the first time the chapter is entered.
public partial class Game {
	readonly List<Vector2> mech0Mist = new List<Vector2>();
	float mech0Hide;
	bool mech0Charged;
	void MechInit0(int c) {
		if (c != 0) return;
		mech0Mist.Clear(); mech0Hide = 0; mech0Charged = false;
		for (int i = 0; i < 3; i++) mech0Mist.Add(new Vector2(Rnd(PR.xMin + 160, PR.xMax - 160), Rnd(PR.yMin + 140, PR.yMax - 140)));
	}
	void MechUpdate0(float dt) {
		if (ch != 0 || fight == null) return;
		bool inside = false;
		for (int i = 0; i < mech0Mist.Count; i++) {
			if ((ppos - mech0Mist[i]).sqrMagnitude < 130 * 130) inside = true;
			foreach (var f in foes) if (!f.dead && (f.pos - mech0Mist[i]).sqrMagnitude < 130 * 130) f.cd -= dt * 0.25f;
		}
		if (inside && act != "atk") {
			mech0Hide += dt;
			if (mech0Hide >= 0.85f && !mech0Charged) {
				mech0Charged = true;
				Text(ppos + new Vector2(0, 145), "ẨN SÁT", new Color(0.5f, 0.9f, 0.65f), 22);
			}
		} else if (!inside) mech0Hide = Mathf.Max(0, mech0Hide - dt * 0.5f);
		if (mech0Charged && act == "atk" && hitDone) {
			mech0Charged = false; mech0Hide = 0;
			Burst(ppos + adir * 95, 140, 26 * dmgMul, D.MOC, 1, true);
		}
	}
	void MechDraw0() {
		if (ch != 0 || fight == null) return;
		foreach (var m in mech0Mist) {
			float r = 130 + Mathf.Sin(T * 2f + m.x) * 6;
			ground.Circle(m, r, new Color(0.18f, 0.28f, 0.22f, 0.28f));
			ground.Ring(m, r, 4, new Color(0.45f, 0.65f, 0.5f, 0.45f));
		}
		if (mech0Charged) fxInk.Ring(ppos + new Vector2(0, 45), 38, 4, new Color(0.5f, 0.95f, 0.65f, 0.85f));
	}
}

public partial class Game {
	Vector2 mech1Bell;
	float mech1T, mech1Wave = -1;
	bool mech1Hit;
	void MechInit1(int c) {
		if (c != 1) return;
		mech1Bell = PR.center; mech1T = 3.2f; mech1Wave = -1; mech1Hit = false;
	}
	void MechUpdate1(float dt) {
		if (ch != 1 || fight == null) return;
		mech1T -= dt;
		if (mech1T <= 0) { mech1T = 5.5f; mech1Wave = 20; mech1Hit = false; sfx.Play("gong", 0.6f, 0.9f); }
		if (mech1Wave >= 0) {
			mech1Wave += 520 * dt;
			float d = (ppos - mech1Bell).magnitude;
			if (!mech1Hit && Mathf.Abs(d - mech1Wave) < 28) {
				mech1Hit = true;
				if (guard && gt <= pwin + 0.12f) {
					qi = Mathf.Min(100, qi + 25 * qiMul); Heal(4);
					Text(ppos + new Vector2(0, 150), "TỊNH TÂM!", new Color(1f, 0.85f, 0.4f), 26);
					foreach (var f in foes) if (!f.dead) AddPosture(f, f.posMax * 0.25f);
				} else if (act != "dash" && inv <= 0) HitPlayer(10, null, false, mech1Bell);
			}
			if (mech1Wave > 950) mech1Wave = -1;
		}
	}
	void MechDraw1() {
		if (ch != 1 || fight == null) return;
		ground.Circle(mech1Bell, 36, new Color(0.55f, 0.42f, 0.18f, 0.5f));
		if (mech1T < 1.0f) ground.Ring(mech1Bell, 36 + (1 - mech1T) * 25, 4, new Color(0.95f, 0.75f, 0.3f, 0.7f));
		if (mech1Wave >= 0) fxInk.Ring(mech1Bell, mech1Wave, 8, new Color(0.95f, 0.8f, 0.35f, 0.75f));
	}
}

public partial class Game {
	Vector2 mech2Brazier;
	float mech2Chill;
	void MechInit2(int c) {
		if (c != 2) return;
		mech2Brazier = PR.center + new Vector2(Rnd(-180, 180), Rnd(-100, 100));
		mech2Chill = 0;
	}
	void MechUpdate2(float dt) {
		if (ch != 2 || fight == null) return;
		bool warm = (ppos - mech2Brazier).sqrMagnitude < 165 * 165 || act == "atk" || act == "skill";
		foreach (var f in foes) if (!f.dead && f.burn > 0 && (f.pos - ppos).sqrMagnitude < 180 * 180) warm = true;
		if (warm) {
			if (mech2Chill >= 65 && act == "atk" && hitDone) {
				mech2Chill = 0;
				Burst(ppos, 170, 28 * dmgMul, D.HOA, 1, true);
				Text(ppos + new Vector2(0, 145), "PHÁ HÀN!", D.EL_COL[D.HOA], 24);
			}
			mech2Chill = Mathf.Max(0, mech2Chill - dt * 32);
		} else {
			mech2Chill += dt * 16;
			if (mech2Chill >= 100) {
				mech2Chill = 40; dashes = 0;
				HitPlayer(12, null, false, ppos);
				Text(ppos + new Vector2(0, 145), "ĐÓNG BĂNG!", D.EL_COL[D.THUY], 24);
			}
		}
	}
	void MechDraw2() {
		if (ch != 2 || fight == null) return;
		ground.Circle(mech2Brazier, 165, new Color(0.95f, 0.45f, 0.15f, 0.16f));
		fxInk.Circle(mech2Brazier, 22 + Mathf.Sin(T * 12) * 3, new Color(1f, 0.55f, 0.15f, 0.85f));
		if (mech2Chill > 5) fxInk.Ring(ppos + new Vector2(0, 45), 34, 5 * (mech2Chill / 100f), new Color(0.45f, 0.8f, 1f, 0.8f));
	}
}

public partial class Game {
	struct Mech3Line { public Vector2 a, b; public float t; }
	readonly List<Mech3Line> mech3Ink = new List<Mech3Line>();
	Vector2 mech3DashStart;
	bool mech3WasDash;
	void MechInit3(int c) {
		if (c != 3) return;
		mech3Ink.Clear(); mech3WasDash = false;
	}
	void MechUpdate3(float dt) {
		if (ch != 3 || fight == null) return;
		if (act == "dash" && !mech3WasDash) { mech3WasDash = true; mech3DashStart = ppos; }
		else if (act != "dash" && mech3WasDash) {
			mech3WasDash = false;
			mech3Ink.Add(new Mech3Line { a = mech3DashStart, b = ppos, t = 5.5f });
			if (mech3Ink.Count >= 3) {
				Vector2 mid = (mech3Ink[0].a + mech3Ink[1].b + ppos) / 3f;
				Burst(mid, 240, 42 * dmgMul, -1, 1, false);
				Text(mid + new Vector2(0, 120), "MẶC TRẬN!", D.INK, 28);
				mech3Ink.Clear();
			}
		}
		for (int i = mech3Ink.Count - 1; i >= 0; i--) {
			var ln = mech3Ink[i]; ln.t -= dt; mech3Ink[i] = ln;
			Vector2 dir = ln.b - ln.a; float len = dir.magnitude;
			if (len > 5) {
				dir /= len;
				foreach (var sh in shots) if (!sh.mine && LineHit(ln.a, dir, len, 26, sh.pos - new Vector2(0, 55), sh.r)) sh.life = 0;
				if (((int)(T * 10)) != ((int)((T - dt) * 10))) foreach (var f in foes) if (!f.dead && LineHit(ln.a, dir, len, 28, f.pos, f.d.r)) HurtFoe(f, 7 * dmgMul, -1, 0, 0.5f, dir, false, false);
			}
			if (ln.t <= 0) mech3Ink.RemoveAt(i);
		}
	}
	void MechDraw3() {
		if (ch != 3 || fight == null) return;
		foreach (var ln in mech3Ink) ground.Brush(ln.a, ln.b, 24, new Color(0.06f, 0.05f, 0.06f, Mathf.Min(0.85f, ln.t)));
	}
}

public partial class Game {
	public static readonly string[] MECH_NAME = { "TRÚC VỤ ẨN SÁT", "CHUÔNG VỌNG TỊNH TÂM", "HÀN PHONG NHẬP CỐT", "MẶC HỌA KIẾM NGẤN" };
	public static readonly string[] MECH_DESC = { "Các bụi sương mù trong rừng trúc che khuất tầm nhìn nhưng nạp sát ý cho người bước vào. Đứng trong sương đủ lâu giúp đòn đánh kế tiếp của ngươi hóa thành nhát chém bạo kích phá thế.", "Chuông cổ định kỳ ngân vang phát ra sóng âm chấn động toàn bộ bãi chiến. Đỡ đòn đúng nhịp chuông điểm sẽ hóa giải sát thương, hồi nội lực và làm choáng kẻ địch xung quanh.", "Gió tuyết liên tục tích tụ Hàn Khí làm tê cóng gân cốt nếu ngươi đứng yên chịu trận. Đứng gần lò lửa hoặc liên tục tung kiếm vung chiêu sẽ đốt cháy Hàn Khí thành Hỏa Kình bùng nổ.", "Mỗi lần khinh công lướt đi trên trang giấy trắng sẽ để lại một vệt mực ướt chặn đạn và cắt xé kẻ địch đi ngang. Gom đủ ba nét mực trên mặt đất sẽ tự động kết ấn nổ tung thành Mặc Trận." };
	void MechInit(int c) { switch (c) { case 0: MechInit0(0); break; case 1: MechInit1(1); break; case 2: MechInit2(2); break; case 3: MechInit3(3); break; } }
	void MechUpdate(float dt) { switch (ch) { case 0: MechUpdate0(dt); break; case 1: MechUpdate1(dt); break; case 2: MechUpdate2(dt); break; case 3: MechUpdate3(dt); break; } }
	void MechDraw() { switch (ch) { case 0: MechDraw0(); break; case 1: MechDraw1(); break; case 2: MechDraw2(); break; case 3: MechDraw3(); break; } }
	// first time in a chapter: the mechanic is introduced
	void MechIntro(int c) {
		if (c < 0 || c >= MECH_NAME.Length || meta.mechs.Contains(c)) return;
		meta.mechs.Add(c); SaveMeta();
		StartCoroutineLike(MECH_NAME[c], MECH_DESC[c]);
	}
	void StartCoroutineLike(string a, string b) { Banner("CƠ CHẾ MỚI · " + a, b); sfx.Play("gong", 0.8f, 1.2f); }
}
