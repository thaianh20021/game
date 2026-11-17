using System.Collections.Generic;
using UnityEngine;

// The hero as a cut-out puppet: body parts on a bone chain (forward kinematics), posed every frame and
// eased between poses, with a cloth scarf (verlet rope), a lagging ponytail and a swinging robe skirt.
// Parts and joints come from tools/parts.py (Resources/Art/rig_*.png + Resources/rig.json).
// Used for the sword; other weapons keep their drawn frames. Angles in degrees, counter-clockwise:
// a hanging limb at +90 points forward, the torso at -20 leans forward.
public partial class Game {
	class RigPart { public SpriteRenderer sr; public Vector2 top, bot; public float len, k; }

	[System.Serializable] class RigPt { public float w, h; public float[] top, bot; }

	readonly Dictionary<string, RigPart> rp = new Dictionary<string, RigPart>();
	bool rigOk;
	float rigK = 1;           // logic px per sprite px
	readonly float[] pose = new float[12], poseT = new float[12];
	// 0 torso 1 head 2 armF 3 foreF 4 armB 5 foreB 6 thighF 7 shinF 8 thighB 9 shinB 10 sword(rel) 11 hip dy
	float tailA, tailV, skirtA, skirtV, throwT;
	Vector2 lastHip;
	readonly Vector2[] scarf = new Vector2[9], scarfOld = new Vector2[9];
	Ink rigInk;
	string rigWeapon = "";
	bool wAbs;                // the weapon's angle (pose[10]) is absolute, not relative to the forearm
	readonly Dictionary<string, RigPart> wp = new Dictionary<string, RigPart>();
	// weapon id -> drawn piece and its length on screen in logic px (the sword keeps the body's scale)
	static readonly Dictionary<string, string> W_PIECE = new Dictionary<string, string> { { "thuong", "spear" }, { "dao", "saber" }, { "chuy", "mace" }, { "phien", "fan" }, { "cung", "bow" } };
	static readonly Dictionary<string, float> W_LEN = new Dictionary<string, float> { { "thuong", 175 }, { "dao", 62 }, { "chuy", 105 }, { "phien", 34 }, { "cung", 118 } };
	static readonly Dictionary<string, float> W_HOLD = new Dictionary<string, float> { { "thuong", -75 }, { "chuy", 150 }, { "phien", -40 }, { "cung", -18 } };

	void InitRig() {
		var ta = Resources.Load<TextAsset>("rig");
		if (ta == null) return;
		var names = new[] { "head", "torso", "skirt", "arm", "fore", "hand", "thigh", "shin", "sword", "tail" };
		string js = ta.text;
		foreach (var n in names) {
			var spr = Spr("rig_" + n);
			int i = js.IndexOf("\"" + n + "\"");
			if (spr == null || i < 0) return;
			int a = js.IndexOf('{', i), b = js.IndexOf('}', a);
			var pt = JsonUtility.FromJson<RigPt>(js.Substring(a, b - a + 1));
			rp[n] = new RigPart { top = new Vector2(pt.top[0] - pt.w / 2, pt.top[1]), bot = new Vector2(pt.bot[0] - pt.w / 2, pt.bot[1]) };
			rp[n].len = (rp[n].top - rp[n].bot).magnitude;
		}
		var tw = Resources.Load<TextAsset>("rigw");
		if (tw != null) foreach (var n in new[] { "spear", "saber", "mace", "fan", "bow" }) {
			int i = tw.text.IndexOf("\"" + n + "\"");
			if (i < 0 || Spr("rigw_" + n) == null) continue;
			int a = tw.text.IndexOf('{', i), b = tw.text.IndexOf('}', a);
			var pt = JsonUtility.FromJson<RigPt>(tw.text.Substring(a, b - a + 1));
			var q = new RigPart { top = new Vector2(pt.top[0] - pt.w / 2, pt.top[1]), bot = new Vector2(pt.bot[0] - pt.w / 2, pt.bot[1]) };
			q.len = (q.top - q.bot).magnitude;
			q.k = pt.h;   // full height in sprite px, used to size it
			wp[n] = q;
		}
		// the whole standing body (legs, torso, head) is about as tall as the drawn frames: 125 logic px
		float tall = rp["thigh"].len + rp["shin"].len + rp["torso"].len + rp["head"].len * 0.85f;
		rigK = 250f / tall;   // sprites are imported at 200 px per unit: one sprite px is half a logic px
		var root = new GameObject("rig");
		foreach (var key in new[] { "armB", "foreB", "thighB", "shinB", "torso", "skirt", "thighF", "shinF", "head", "armF", "foreF", "sword", "weapon2" }) {
			string src = key == "weapon2" ? "sword" : key.TrimEnd('B', 'F');
			if (key == "foreB") src = "hand";
			if (key == "foreF") src = "fore";
			var sr = new GameObject(key).AddComponent<SpriteRenderer>();
			sr.transform.SetParent(root.transform);
			sr.sprite = Spr("rig_" + src);
			sr.material = new Material(inkShader);
			sr.transform.localScale = Vector3.one * rigK;
			if (key.EndsWith("B") || key == "weapon2") sr.color = new Color(0.72f, 0.72f, 0.78f);
			var p = rp[src];
			rp[key] = new RigPart { sr = sr, top = p.top, bot = p.bot, len = p.len, k = rigK };
		}
		rigInk = new Ink("scarf", 0);
		rigOk = true;
		ResetRig();
	}

	void ResetRig() {
		for (int i = 0; i < 12; i++) pose[i] = 0;
		for (int i = 0; i < scarf.Length; i++) { scarf[i] = ppos + new Vector2(-i * 9, 100); scarfOld[i] = scarf[i]; }
		lastHip = ppos;
	}

	bool RigOn() { return rigOk && meta.rigOn && weapon != null && (weapon.id == "kiem" || (W_PIECE.ContainsKey(weapon.id) && wp.ContainsKey(W_PIECE[weapon.id]))); }

	// puts the drawn piece of the current weapon into the hand (and a second saber into the other hand)
	void SetRigWeapon() {
		rigWeapon = weapon.id;
		wAbs = W_HOLD.ContainsKey(weapon.id);
		foreach (var key in new[] { "sword", "weapon2" }) {
			var p = rp[key];
			if (weapon.id == "kiem" || !W_PIECE.ContainsKey(weapon.id)) { p.sr.sprite = Spr("rig_sword"); continue; }
			var q = wp[W_PIECE[weapon.id]];
			p.sr.sprite = Spr("rigw_" + W_PIECE[weapon.id]);
			p.top = q.top; p.bot = q.bot; p.len = q.len;
			p.k = W_LEN[weapon.id] * 2 / q.k;
			p.sr.transform.localScale = Vector3.one * p.k;
		}
		if (weapon.id == "kiem") {
			// back to the sword piece measured with the body
			var ta = Resources.Load<TextAsset>("rig").text;
			int i = ta.IndexOf("\"sword\""), a = ta.IndexOf('{', i), b = ta.IndexOf('}', a);
			var pt = JsonUtility.FromJson<RigPt>(ta.Substring(a, b - a + 1));
			foreach (var key in new[] { "sword", "weapon2" }) {
				var p = rp[key];
				p.top = new Vector2(pt.top[0] - pt.w / 2, pt.top[1]); p.bot = new Vector2(pt.bot[0] - pt.w / 2, pt.bot[1]);
				p.k = rigK; p.sr.transform.localScale = Vector3.one * rigK;
			}
		}
	}

	static float[] Pz(float t, float h, float aF, float fF, float aB, float fB, float thF, float shF, float thB, float shB, float w, float dy) {
		return new[] { t, h, aF, fF, aB, fB, thF, shF, thB, shB, w, dy };
	}
	// per weapon: wind / cut / follow for the plain hits, then wind / cut / follow for the finisher
	static readonly Dictionary<string, float[][]> W_ATK = new Dictionary<string, float[][]> {
		{ "thuong", new[] {
			Pz(8, -4, 30, 20, 50, 30, 20, -20, -25, -25, -90, -6), Pz(-28, 12, 95, 0, 85, 10, 60, -10, -50, -45, -90, -16), Pz(-28, 12, 95, 0, 85, 10, 60, -10, -50, -45, -90, -16),
			Pz(12, -6, -40, 10, 40, 20, 20, -20, -20, -25, 90, -6), Pz(-20, 8, 90, 0, 60, 10, 35, -15, -30, -20, -90, -8), Pz(-10, 4, 150, 0, 120, 10, 30, -15, -30, -20, -250, -8) } },
		{ "chuy", new[] {
			Pz(14, -8, 200, 20, 190, 20, 15, -20, -20, -25, 30, -4), Pz(-30, 14, 80, 0, 75, 0, 50, -10, -40, -35, -130, -14), Pz(-36, 16, 40, 0, 35, 0, 55, -10, -45, -40, -175, -20),
			Pz(10, -6, -60, 10, -50, 10, 15, -15, -25, -25, 100, -6), Pz(-20, 8, 90, 0, 85, 0, 40, -15, -35, -25, -90, -10), Pz(-15, 6, 160, 0, 150, 0, 35, -15, -30, -25, -260, -10) } },
		{ "phien", new[] {
			Pz(6, -4, 170, 30, -20, 20, 15, -15, -20, -20, 40, -4), Pz(-18, 8, 95, 0, -30, 20, 35, -10, -30, -20, -90, -8), Pz(-22, 10, 60, -10, -40, 20, 40, -10, -35, -20, -150, -8),
			Pz(12, -6, -50, 20, 40, 20, 15, -15, -20, -25, 120, -4), Pz(-15, 6, 100, 0, -20, 20, 30, -15, -25, -20, -90, -8), Pz(-10, 4, 170, 0, -30, 20, 30, -15, -25, -20, -280, -8) } },
		{ "dao", new[] {
			// odd hits come from the back hand
			Pz(8, -4, 40, 30, 205, 40, 20, -20, -25, -25, 0, -6), Pz(-20, 8, -20, 20, 95, 0, 35, -15, -30, -20, 0, -8), Pz(-26, 10, -30, 20, 15, -15, 40, -10, -35, -20, 0, -10),
			Pz(14, -8, 240, 30, 220, 30, 10, -25, -10, -35, 0, -4), Pz(-34, 14, 92, 0, 85, 0, 60, -10, -50, -45, 0, -18), Pz(-34, 14, 92, 0, 85, 0, 60, -10, -50, -45, 0, -18) } },
	};

	static float Ease(float u) { u = Mathf.Clamp01(u); return u * u * (3 - 2 * u); }

	void P(float t, float h, float aF, float fF, float aB, float fB, float thF, float shF, float thB, float shB, float sw, float dy) {
		poseT[0] = t; poseT[1] = h; poseT[2] = aF; poseT[3] = fF; poseT[4] = aB; poseT[5] = fB;
		poseT[6] = thF; poseT[7] = shF; poseT[8] = thB; poseT[9] = shB; poseT[10] = sw; poseT[11] = dy;
	}

	// blends the target between two poses already written as arrays
	void Mix(float[] a, float[] b, float u) { u = Ease(u); for (int i = 0; i < 12; i++) poseT[i] = Mathf.Lerp(a[i], b[i], u); }

	static readonly float[][] SLASH = {
		//            torso head  armF  foreF armB foreB thF  shF  thB  shB  sword dy
		new float[] {   8,  -4,  205,   40, -30,  20,  20, -20, -25, -25,   0,  -6 },   // 0 wind: sword up and back
		new float[] { -20,   8,   95,    0,  40,  30,  35, -15, -30, -20,   0,  -8 },   // 1 cut: arm level, sword forward
		new float[] { -26,  10,   15,  -15,  55,  35,  40, -10, -35, -20,   0, -10 },   // 2 follow: arm across and down
		new float[] {  -4,   0,  170,   20, -20,  25,  15, -15, -20, -25,  15,  -4 },   // 3 wind 2: sword overhead
		new float[] { -24,  12,   55,  -10,  45,  40,  45, -10, -35, -25,   0, -10 },   // 4 cut 2: diagonal down
		new float[] {  14,  -8,  240,   30, -50,  20,  10, -25, -10, -35,   0,  -4 },   // 5 wind 3: twisted far back
		new float[] { -34,  14,   92,    0,  70,  20,  60, -10, -50, -45,   0, -18 },   // 6 lunge: everything forward
	};

	void RigTarget(float dt) {
		float b = Mathf.Sin(T * 2.6f);
		if (state == "dead") { P(-60, 30, 40, 40, 30, 30, 95, -120, 10, -100, 30, -42); return; }
		if (act == "dash") { P(-55, 30, -70, 10, -60, 20, 70, -100, -50, -40, 0, -24); return; }
		if (castT > 0) { P(8, -10, 165, 10, 155, 10, 15, -10, -15, -10, 0, 2); return; }
		if (act == "skill" || whirlT > 0) { float sp = T * 30; P(-10, 0, 90 + Mathf.Sin(sp) * 80, 0, -90 + Mathf.Sin(sp) * 60, 20, 30, -20, -30, -20, 0, -6); return; }
		if (act == "atk" && W_ATK.ContainsKey(weapon.id)) {
			var s = weapon.combo[ci];
			float u = at / s.dur;
			bool last = ci == weapon.combo.Length - 1;
			var tb = W_ATK[weapon.id];
			float[] w, c, f;
			if (weapon.id == "dao" && !last && ci % 2 == 1) { w = tb[0]; c = tb[1]; f = tb[2]; }
			else if (weapon.id == "dao" && !last) { w = SLASH[0]; c = SLASH[1]; f = SLASH[2]; }
			else { int o = last ? 3 : 0; w = tb[o]; c = tb[o + 1]; f = tb[o + 2]; }
			if (u < 0.25f) Mix(w, w, 1);
			else if (u < 0.5f) Mix(w, c, (u - 0.25f) / 0.25f);
			else Mix(c, f, (u - 0.5f) / 0.5f);
			return;
		}
		if (weapon.id == "cung" && (chargeT > 0 || acd > 0)) {
			// bow arm straight out, the string hand draws back to the cheek, then is flung back on release
			float u = Mathf.Clamp01(chargeT / 1.1f);
			if (chargeT > 0) P(-8, 4, 92, 0, 88, 70 + 75 * u, 25, -18, -25, -22, 0, -4);
			else P(-6, 2, 92, 0, 70, 175, 25, -18, -25, -22, 0, -4);
			return;
		}
		if (act == "atk") {
			var s = weapon.combo[ci];
			float u = at / s.dur;
			bool last = ci == weapon.combo.Length - 1;
			float[] w = SLASH[last ? 5 : (ci % 2 == 0 ? 0 : 3)], c = SLASH[last ? 6 : (ci % 2 == 0 ? 1 : 4)], f = last ? SLASH[6] : SLASH[ci % 2 == 0 ? 2 : 4];
			if (u < 0.25f) Mix(w, w, 1);
			else if (u < 0.5f) Mix(w, c, (u - 0.25f) / 0.25f);
			else Mix(c, f, (u - 0.5f) / 0.5f);
			return;
		}
		if (throwT > 0) {
			// cock back for the first part, whip forward on release
			float u = 1 - throwT / 0.2f;
			if (weapon.id == "kiem") {
				if (u < 0.45f) P(12, -6, 230, 30, 70, 20, 20, -15, -25, -25, 0, -4);
				else P(-24, 10, 95, 0, -30, 20, 40, -10, -35, -20, 0, -8);
			} else {
				if (u < 0.45f) P(12, -6, 30, 30, 230, 30, 20, -15, -25, -25, 0, -4);
				else P(-24, 10, 20, 20, 95, 0, 40, -10, -35, -20, 0, -8);
			}
			return;
		}
		if (hurtFx > 0.22f) { P(18, 25, -40, 30, 60, 40, 25, -10, -15, -20, 0, -3); return; }
		if (guard) { P(-6, 0, 100, 75, 60, 60, 25, -20, -20, -25, 0, -6); return; }
		if (catchT > 0) { P(-4, -6, 170, 10, 20, 20, 15, -15, -15, -20, 0, 0); return; }
		if (recallT > 0) { P(4, -10, 150, -40, 60, 20, 15, -15, -15, -20, 0, 0); return; }
		if (moving) {
			float p = moveAmt * Mathf.PI * 2 * 1.9f, sn = Mathf.Sin(p), cs = Mathf.Cos(p);
			P(-16, 12, -40 - 18 * sn, 25, 38 * sn, 45, 42 * sn, -18 - 45 * (1 - sn) / 2, -42 * sn, -18 - 45 * (1 + sn) / 2, 10, -4 + 7 * Mathf.Abs(cs));
			return;
		}
		P(-4 + b * 1.5f, 4 - b, 25, 35, -12, 18, 10, -6, -10, -10, -20, b * 1.2f);
	}

	void PlaceBone(string key, Vector2 joint, float ang, bool jointAtTop, out Vector2 end) {
		var p = rp[key];
		Vector2 jl = (jointAtTop ? p.top : p.bot) * p.k * 0.5f, el = (jointAtTop ? p.bot : p.top) * p.k * 0.5f;
		var q = Quaternion.Euler(0, 0, ang);
		Vector2 pos = joint - (Vector2)(q * jl);
		end = pos + (Vector2)(q * el);
		p.sr.transform.position = new Vector3(pos.x * 0.01f, pos.y * 0.01f, 0);
		p.sr.transform.rotation = q;
	}

	void RenderRig(float rdt, float z) {
		bool on = RigOn() && InWorld();
		heroSr.enabled = heroSr.enabled && !on;
		if (!rigOk) return;
		foreach (var kv in rp) if (kv.Value.sr != null) kv.Value.sr.enabled = on;
		rigInk.Clear();
		if (!on) { rigInk.Apply(); return; }
		if (rigWeapon != weapon.id) SetRigWeapon();
		RigTarget(rdt);
		bool wPose = act == "atk" || (weapon.id == "cung" && (chargeT > 0 || acd > 0));
		if (wAbs && !wPose) {
			float hold = W_HOLD[weapon.id];
			if (guard) hold = weapon.id == "chuy" ? 20 : (weapon.id == "cung" ? 0 : 10);
			else if (moving && weapon.id == "thuong") hold = -95;
			poseT[10] = hold;
		}
		float rate = act == "atk" || throwT > 0 || act == "dash" ? 38 : (moving ? 22 : 12);
		float k = 1 - Mathf.Exp(-rate * rdt);
		for (int i = 0; i < 12; i++) pose[i] = Mathf.Lerp(pose[i], poseT[i], k);

		// everything is posed facing right around the hip, then mirrored when facing left
		float leg = (rp["thigh"].len + rp["shin"].len) * rigK * 0.5f;
		Vector2 hip0 = new Vector2(0, leg * 0.97f + pose[11] + z);
		var placed = new List<string>();
		Vector2 e;
		float tA = pose[0];
		PlaceBone("torso", hip0, tA, false, out e);
		Vector2 neck = e, shoulder = Vector2.Lerp(hip0, neck, 0.86f);
		PlaceBone("head", neck, tA + pose[1], false, out e);
		PlaceBone("skirt", hip0 + new Vector2(0, 6), skirtA, true, out e);
		PlaceBone("thighF", hip0, pose[6], true, out e);
		PlaceBone("shinF", e, pose[6] + pose[7], true, out e);
		PlaceBone("thighB", hip0, pose[8], true, out e);
		PlaceBone("shinB", e, pose[8] + pose[9], true, out e);
		PlaceBone("armB", shoulder, tA + pose[4], true, out e);
		float fb = tA + pose[4] + pose[5];
		PlaceBone("foreB", e, fb, true, out e);
		PlaceBone("weapon2", e, fb + 180 + pose[10], false, out e);
		PlaceBone("armF", shoulder, tA + pose[2], true, out e);
		float fa = tA + pose[2] + pose[3];
		PlaceBone("foreF", e, fa, true, out e);
		Vector2 hand = e;
		PlaceBone("sword", hand, wAbs ? pose[10] : fa + 180 + pose[10], false, out e);
		// the ponytail hangs from the back of the head and lags behind

		// secondary motion: springs driven by how fast the hip moves
		Vector2 hipW = ppos + new Vector2(0, hip0.y);
		Vector2 vel = (hipW - lastHip) / Mathf.Max(rdt, 0.001f);
		lastHip = hipW;
		if (vel.magnitude > 3000) { vel = Vector2.zero; for (int i = 0; i < scarf.Length; i++) scarf[i] = scarfOld[i] = hipW; }
		float back = -vel.x * face * 0.05f;
		tailV += ((-25 + Mathf.Clamp(back * 1.5f, -70, 10) + Mathf.Sin(T * 3) * 4 - tailA) * 120 - tailV * 14) * rdt;
		tailA += tailV * rdt;
		float swing = (pose[6] + pose[8]) * 0.35f - Mathf.Clamp(back, -30, 30) * 0.4f;
		skirtV += ((swing - skirtA) * 160 - skirtV * 16) * rdt;
		skirtA += skirtV * rdt;

		// mirror and draw order
		bool left = face < 0;
		int baseOrder = 22000 - (int)ppos.y;
		var orderOf = new Dictionary<string, int> { { "armB", -6 }, { "foreB", -5 }, { "thighB", -4 }, { "shinB", -3 }, { "torso", 0 }, { "thighF", 1 }, { "shinF", 2 }, { "skirt", 3 }, { "head", 4 }, { "armF", 5 }, { "foreF", 6 }, { "sword", pose[2] > 150 ? -1 : 7 }, { "weapon2", -4 } };
		float flash = pflash > 0 ? 0.8f : (guard && gt <= pwin ? 0.35f : 0);
		Color fc = pflash > 0 ? new Color(1f, 0.3f, 0.25f) : new Color(1f, 0.92f, 0.6f);
		float blink = inv > 0 && pflash <= 0 && act != "dash" && ((int)(T * 20)) % 2 == 0 ? 0.55f : 1;
		foreach (var kv in orderOf) {
			var sr = rp[kv.Key].sr;
			Vector3 p = sr.transform.position;
			float lx = p.x * 100;
			float ang = sr.transform.eulerAngles.z;
			if (left) { lx = -lx; ang = -ang; }
			sr.transform.position = new Vector3((ppos.x + lx) * 0.01f, (ppos.y + p.y * 100) * 0.01f, 0);
			sr.transform.rotation = Quaternion.Euler(0, 0, ang);
			sr.flipX = left;
			sr.sortingOrder = baseOrder + kv.Value;
			sr.material.SetFloat("_Flash", flash);
			sr.material.SetColor("_FlashColor", fc);
			var c = sr.color; c.a = blink; sr.color = c;
		}
		rp["sword"].sr.enabled = weapon.id != "kiem" || swordsHeld > 0 || act == "atk" || act == "skill";
		rp["weapon2"].sr.enabled = weapon.id == "dao";

		// the scarf: a rope of points pinned at the neck, pulled down by gravity and back by the wind of running
		Vector2 neckW = ppos + new Vector2(left ? -neck.x + 6 : neck.x - 6, neck.y - 6);
		scarf[0] = neckW;
		// forces in logic px/s^2 (the hero is 125 px tall): heavy enough to hang, the run lifts it behind him
		float spd = Mathf.Min(vel.magnitude, 700);
		// a wuxia scarf never just hangs: a steady breeze carries it behind him, gusting, stronger when he runs
		float gust = 0.6f + 0.4f * Mathf.Sin(T * 1.7f) * Mathf.Sin(T * 2.9f + 1);
		Vector2 wind = new Vector2(-face * (1100 * gust + spd * 2.5f), 420 * Mathf.Sin(T * 3.3f) + spd * 0.6f);
		float seg = 9;
		for (int i = 1; i < scarf.Length; i++) {
			Vector2 cur = scarf[i], v = (cur - scarfOld[i]) * 0.96f;
			scarfOld[i] = cur;
			scarf[i] = cur + v + (new Vector2(0, -950) + wind * (0.6f + 0.4f * i / scarf.Length)) * rdt * rdt;
		}
		for (int it = 0; it < 4; it++)
			for (int i = 1; i < scarf.Length; i++) {
				Vector2 d = scarf[i] - scarf[i - 1];
				float m = d.magnitude;
				if (m > 0.001f) scarf[i] = scarf[i - 1] + d / m * seg;
			}
		var mr = rigInk.go.GetComponent<MeshRenderer>();
		mr.sortingOrder = baseOrder + 3;   // over the shoulder: above the torso, under the head
		// one continuous strip: an ink edge, then the red cloth, narrowing to a ragged tip
		for (int pass = 0; pass < 2; pass++) {
			Color col = pass == 0 ? new Color(0.07f, 0.06f, 0.06f, blink) : new Color(0.78f, 0.18f, 0.12f, blink);
			for (int i = 1; i < scarf.Length; i++) {
				Vector2 a0 = scarf[i - 1], a1 = scarf[i];
				Vector2 d0 = (i > 1 ? a1 - scarf[i - 2] : a1 - a0).normalized, d1 = (i + 1 < scarf.Length ? scarf[i + 1] - a0 : a1 - a0).normalized;
				Vector2 n0 = new Vector2(-d0.y, d0.x), n1 = new Vector2(-d1.y, d1.x);
				float w0 = Mathf.Lerp(4.5f, 1.5f, (i - 1) / (float)scarf.Length) + (pass == 0 ? 1.6f : 0);
				float w1 = Mathf.Lerp(4.5f, 1.5f, i / (float)scarf.Length) + (pass == 0 ? 1.6f : 0);
				rigInk.Quad(a0 - n0 * w0, a0 + n0 * w0, a1 + n1 * w1, a1 - n1 * w1, col);
			}
		}
		rigInk.Apply();
	}
}
