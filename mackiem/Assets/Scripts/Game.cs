using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

// Mac Kiem Luc: the whole game is built from code at runtime (no scene objects, no prefabs).
// Game.cs: boot, input, the player, rooms and the run. GameFoes.cs: foes and combat.
// GameDraw.cs: sprites, ink meshes, HUD and menus. Logic space is pixels, y up, 100 px = 1 unit.

public class Foe {
	public FoeDef d;
	public Vector2 pos, kb, aim, aimPos, from;
	public float hp, maxHp, posv, posMax, posT, broken, stun, flash, spawn, cd, stT, z, dmgMul = 1, scale = 1;
	public Move mv;
	public int si, mark = -1;
	public bool resolved, dead, elite;
	public float markT, bleed, poison, poisonD, slow, burn, burnD, dotT, deadT;
	public float[] mcd;
	public bool[] used;
	public SpriteRenderer sr;
	// frame animation (null when the foe only has its single picture)
	public Sprite[] walk;
	public Sprite wind, hit;
	public bool moving;
	public float animT;
}
public class Ghost { public SpriteRenderer sr; public float life, max; }
public class Shot { public Vector2 pos, vel; public float dmg, r = 9, life = 3; public bool mine, pool; public int el = -1, lvl, pierce; public List<Foe> hit; }
public class Wave { public Vector2 pos; public float r, spd, dmg, max; public bool hit; public Color col = new Color(0.07f, 0.06f, 0.06f); }
public class Blast { public Vector2 pos; public float r, t, wind, dmg; }
public class Pool { public Vector2 pos; public float r, t, tick; }
public class Part { public Vector2 pos, vel; public float r, life, max, grav; public Color col; }
public class Slash { public Vector2 pos, dir; public float r, w, t, len, wid; public bool line; public Color col; }
public class FText { public Vector2 pos; public string s; public Color col; public float t; public int size; }
public class Door { public Vector2 pos; public string kind; }
public class Item { public Vector2 pos; public string kind, label; public int cost; public Boon boon; public bool gone; public SpriteRenderer sr; }
public class Prop { public Vector2 pos; public float r; public SpriteRenderer sr; }
public class Offer { public Boon b; public int lvl; public bool replace; }

[Serializable]
public class MetaSave {
	public int ngo, wins, kiep, runs, best;
	public List<string> upIds = new List<string>();
	public List<int> upLv = new List<int>();
	public List<string> unl = new List<string> { "kiem" };
}

public struct Inp {
	public Vector2 mv, aim;
	public bool atk, parry, dash, skill, use, up, down, left, right, ok, back;
}

public partial class Game : MonoBehaviour {
	public const float AW = 1920, AH = 1288, VIEW_H = 640;
	public static Rect PR = new Rect(390, 130, 1150, 720);
	// the open floor of each chapter's painting
	static readonly Rect[] CH_PR = { new Rect(390, 130, 1150, 720), new Rect(330, 260, 1310, 760), new Rect(410, 400, 1110, 560) };

	[RuntimeInitializeOnLoadMethod]
	static void Boot() {
		if (FindObjectOfType<Game>() == null) new GameObject("Game").AddComponent<Game>();
	}

	// --- shared state
	public string state = "title";   // title, weapon, meta, help, play, pick, event, pause, dead, win
	public float T;
	public bool bot, cheat;
	int speed = 1;
	string shotDir, savePath;
	float botEnd = 0;
	MetaSave meta = new MetaSave();
	Inp inp, prev;
	int menuI;
	Camera cam;
	Sfx sfx;
	System.Random rng = new System.Random();

	// --- run
	string weaponId = "kiem";
	WeaponDef weapon;
	int ch, step, coins, kills, rooms, bossKills, earned;
	bool reviveLeft;
	float runTime;
	Dictionary<string, int> boons = new Dictionary<string, int>();
	Dictionary<string, Boon> slot = new Dictionary<string, Boon>();
	int seed;

	// --- room
	string roomKind = "";
	int wave, waves;
	bool cleared;
	float spawnT, pickT, roomT;
	string pickKind = "";
	int pickBonus;
	List<Offer> offers = new List<Offer>();
	string banner = "", bannerSub = "";
	float bannerT;
	string toast = "";
	float toastT;

	// --- player
	Vector2 ppos, aimDir = Vector2.right, adir, ddir;
	float hp, maxHp, bonusHp, qi, inv, pflash, acd, pcd, comboT, buf, at, dashCd, gt, whirlT, whirlTick, hurtFx, moveAmt;
	int ci, dashes, dashMax, face = 1;
	string act = "";
	bool hitDone, guard, riposte, moving;
	float dmgMul, qiMul, pwin, crit, coinMul;

	// --- world lists
	List<Foe> foes = new List<Foe>();
	List<Shot> shots = new List<Shot>();
	List<Wave> wavesFx = new List<Wave>();
	List<Blast> blasts = new List<Blast>();
	List<Pool> pools = new List<Pool>();
	List<Part> parts = new List<Part>();
	List<Slash> slashes = new List<Slash>();
	List<FText> texts = new List<FText>();
	List<Door> doors = new List<Door>();
	List<Item> items = new List<Item>();
	List<Prop> props = new List<Prop>();
	List<Vector3> stains = new List<Vector3>();   // x, y, radius
	float stop, slow, shake, ghostT;
	int lastStep;
	List<Ghost> ghosts = new List<Ghost>();

	void Awake() {
		var args = Environment.GetCommandLineArgs();
		for (int i = 0; i < args.Length; i++) {
			if (args[i] == "-bot") bot = true;
			if (args[i] == "-cheat") cheat = true;
			if (args[i] == "-speed" && i + 1 < args.Length) speed = int.Parse(args[i + 1]);
			if (args[i] == "-shots" && i + 1 < args.Length) shotDir = args[i + 1];
			if (args[i] == "-end" && i + 1 < args.Length) botEnd = float.Parse(args[i + 1]);
		}
		savePath = Path.Combine(Application.persistentDataPath, bot ? "test.json" : "mackiem.json");
		if (bot && File.Exists(savePath)) File.Delete(savePath);
		Application.targetFrameRate = 120;
		cam = Camera.main;
		if (cam == null) {
			var go = new GameObject("Camera");
			go.tag = "MainCamera";
			cam = go.AddComponent<Camera>();
			go.AddComponent<AudioListener>();
		}
		cam.orthographic = true;
		cam.orthographicSize = VIEW_H * 0.005f;
		cam.clearFlags = CameraClearFlags.SolidColor;
		cam.backgroundColor = new Color(0.08f, 0.08f, 0.09f);
		cam.transform.position = new Vector3(AW * 0.005f, AH * 0.005f, -10);
		sfx = new GameObject("Sfx").AddComponent<Sfx>();
		if (bot) sfx.volume = 0.0f;
		InitDraw();
		LoadMeta();
		weapon = D.Weapon(weaponId);
		Recalc();
	}

	// --- meta
	void LoadMeta() {
		try { if (File.Exists(savePath)) meta = JsonUtility.FromJson<MetaSave>(File.ReadAllText(savePath)); } catch (Exception) { meta = new MetaSave(); }
		if (meta == null) meta = new MetaSave();
		if (!meta.unl.Contains("kiem")) meta.unl.Add("kiem");
	}
	void SaveMeta() { try { File.WriteAllText(savePath, JsonUtility.ToJson(meta)); } catch (Exception) { } }
	int Up(string id) { int i = meta.upIds.IndexOf(id); return i < 0 ? 0 : meta.upLv[i]; }
	void SetUp(string id, int v) { int i = meta.upIds.IndexOf(id); if (i < 0) { meta.upIds.Add(id); meta.upLv.Add(v); } else meta.upLv[i] = v; }
	int Lv(string id) { int v; return boons.TryGetValue(id, out v) ? v : 0; }
	int SlotEl(string s) { Boon b; return slot.TryGetValue(s, out b) ? b.el : -1; }
	int SlotLv(string s) { Boon b; return slot.TryGetValue(s, out b) ? Lv(b.id) : 0; }
	float Rnd() { return (float)rng.NextDouble(); }
	float Rnd(float a, float b) { return a + (b - a) * (float)rng.NextDouble(); }
	Vector2 RndDir() { float a = Rnd(0, Mathf.PI * 2); return new Vector2(Mathf.Cos(a), Mathf.Sin(a)); }

	void Recalc() {
		maxHp = 100 + Up("hp") * 12 + Lv("hp") * 25 + bonusHp;
		dmgMul = 1 + Up("dmg") * 0.05f;
		qiMul = 1 + Up("qi") * 0.12f + Lv("qi") * 0.35f;
		dashMax = 1 + Lv("dash");
		pwin = 0.2f * (1 + Lv("calm") * 0.3f);
		crit = Lv("crit") * 0.12f;
		coinMul = 1 + Lv("coin") * 0.4f;
		hp = Mathf.Min(hp, maxHp);
	}

	// --- input
	bool P(bool now, bool before) { return now && !before; }
	Vector2 lastMouse;
	bool padAim;

	void ReadInput() {
		prev = inp;
		var i = new Inp();
		if (bot) { BotInput(ref i); inp = i; return; }
		i.mv = new Vector2((Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow) ? 1 : 0) - (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow) ? 1 : 0),
			(Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow) ? 1 : 0) - (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow) ? 1 : 0));
		i.atk = Input.GetMouseButton(0) || Input.GetKey(KeyCode.J);
		i.parry = Input.GetMouseButton(1) || Input.GetKey(KeyCode.K) || Input.GetKey(KeyCode.LeftShift);
		i.dash = Input.GetKey(KeyCode.Space);
		i.skill = Input.GetKey(KeyCode.Q) || Input.GetKey(KeyCode.L);
		i.use = Input.GetKey(KeyCode.E) || Input.GetKey(KeyCode.F);
		i.ok = Input.GetKey(KeyCode.Return) || Input.GetKey(KeyCode.Space) || Input.GetKey(KeyCode.E);
		i.back = Input.GetKey(KeyCode.Escape);
		// gamepad (Xbox layout): left stick move, right stick aim, X attack, A dash, LB/RB guard, Y skill, B use
		bool pad = Input.GetJoystickNames().Length > 0;
		Vector2 rs = Vector2.zero;
		if (pad) {
			Vector2 ls = new Vector2(Input.GetAxisRaw("Horizontal"), Input.GetAxisRaw("Vertical"));
			if (ls.magnitude > 0.3f && i.mv == Vector2.zero) i.mv = ls;
			i.atk |= Input.GetKey(KeyCode.JoystickButton2);
			i.dash |= Input.GetKey(KeyCode.JoystickButton0);
			i.parry |= Input.GetKey(KeyCode.JoystickButton4) || Input.GetKey(KeyCode.JoystickButton5);
			i.skill |= Input.GetKey(KeyCode.JoystickButton3);
			i.use |= Input.GetKey(KeyCode.JoystickButton1);
			i.ok |= Input.GetKey(KeyCode.JoystickButton0);
			i.back |= Input.GetKey(KeyCode.JoystickButton7);
			if (Input.GetKey(KeyCode.JoystickButton0) || Input.GetKey(KeyCode.JoystickButton2) || ls.magnitude > 0.5f) padAim = true;
		}
		if ((Vector2)Input.mousePosition != lastMouse || Input.GetMouseButton(0)) padAim = false;
		lastMouse = Input.mousePosition;
		i.up = i.mv.y > 0.5f; i.down = i.mv.y < -0.5f; i.left = i.mv.x < -0.5f; i.right = i.mv.x > 0.5f;
		if (i.mv.sqrMagnitude > 1) i.mv.Normalize();
		if (padAim) i.aim = ppos + (i.mv.sqrMagnitude > 0.1f ? i.mv.normalized : aimDir) * 200;
		else {
			Vector3 w = cam.ScreenToWorldPoint(Input.mousePosition);
			i.aim = new Vector2(w.x, w.y) * 100f;
		}
		inp = i;
	}

	void Update() {
		float rdt = Mathf.Min(Time.unscaledDeltaTime, 0.05f);
		for (int k = 0; k < speed; k++) Tick(rdt);
		Render(rdt);
		if (bot) BotShots();
	}

	void Tick(float rdt) {
		T += rdt;
		if (state != lastState) { lastState = state; stateT = T; }
		ReadInput();
		toastT -= rdt; bannerT -= rdt;
		switch (state) {
			case "play": {
				if (P(inp.back, prev.back)) { state = "pause"; menuI = 0; break; }
				float dt = rdt;
				if (stop > 0) { stop -= rdt; dt = 0; } else if (slow > 0) { slow -= rdt; dt = rdt * 0.3f; }
				if (dt > 0) Sim(dt);
				break;
			}
			case "title": Menu(4, TitleAct); break;
			case "weapon": Menu(D.WEAPONS.Length, WeaponAct, true); if (P(inp.back, prev.back)) state = "title"; break;
			case "meta": Menu(D.META.Length, MetaAct); if (P(inp.back, prev.back)) { state = "title"; menuI = 1; } break;
			case "help": if (P(inp.back, prev.back) || P(inp.ok, prev.ok)) { state = "title"; menuI = 2; } break;
			case "pick": Menu(offers.Count, PickAct, true); break;
			case "event": Menu(3, EventAct); break;
			case "pause": Menu(2, PauseAct); if (P(inp.back, prev.back)) state = "play"; break;
			case "dead":
			case "win": if (T - endT > 1.2f && P(inp.ok, prev.ok)) { state = "title"; menuI = 0; ClearRoom(); sfx.Battle(false); } break;
		}
	}
	float endT, stateT;
	string lastState = "";

	void Menu(int n, Action<int> act, bool horiz = false) {
		if (n <= 0) return;
		if (P(horiz ? inp.left : inp.up, horiz ? prev.left : prev.up)) { menuI = (menuI + n - 1) % n; sfx.Play("ui", 0.5f); }
		if (P(horiz ? inp.right : inp.down, horiz ? prev.right : prev.down)) { menuI = (menuI + 1) % n; sfx.Play("ui", 0.5f); }
		menuI = Mathf.Clamp(menuI, 0, n - 1);
		if (P(inp.ok, prev.ok) && T - stateT > 0.3f) act(menuI);
	}

	void TitleAct(int i) {
		sfx.Play("pick", 0.7f);
		if (i == 0) { state = "weapon"; menuI = Mathf.Max(0, Array.FindIndex(D.WEAPONS, w => w.id == weaponId)); }
		else if (i == 1) { state = "meta"; menuI = 0; }
		else if (i == 2) state = "help";
		else Application.Quit();
	}
	void WeaponAct(int i) {
		if (!meta.unl.Contains(D.WEAPONS[i].id)) { sfx.Play("block", 0.6f); return; }
		weaponId = D.WEAPONS[i].id;
		StartRun();
	}
	void MetaAct(int i) {
		var m = D.META[i];
		int lv = Up(m.id);
		if (lv >= m.cost.Length || meta.ngo < m.cost[lv]) { sfx.Play("block", 0.6f); return; }
		meta.ngo -= m.cost[lv];
		SetUp(m.id, lv + 1);
		SaveMeta();
		sfx.Play("pick");
	}
	void PauseAct(int i) {
		if (i == 0) state = "play";
		else { state = "title"; menuI = 0; ClearRoom(); sfx.Battle(false); }
	}

	// --- run flow
	void StartRun() {
		weapon = D.Weapon(weaponId);
		ch = 0; step = 0; kills = 0; rooms = 0; bossKills = 0; runTime = 0; bonusHp = 0;
		coins = Up("coin") * 25;
		reviveLeft = Up("revive") > 0;
		boons.Clear(); slot.Clear();
		seed = rng.Next();
		hp = 9999; qi = 0;
		Recalc();
		hp = maxHp;
		meta.runs++;
		stains.Clear();
		EnterRoom("bikip");
		state = "play";
		Banner(D.CH_NAME[0], "Dùng chuột trái đánh · chuột phải đỡ · SPACE khinh công");
	}

	void Banner(string a, string b = "") { banner = a; bannerSub = b; bannerT = 3.2f; }
	void Toast(string s) { toast = s; toastT = 2.4f; }

	void ClearRoom() {
		foreach (var f in foes) if (f.sr != null) Destroy(f.sr.gameObject);
		foreach (var it in items) if (it.sr != null) Destroy(it.sr.gameObject);
		foreach (var pr in props) if (pr.sr != null) Destroy(pr.sr.gameObject);
		foes.Clear(); items.Clear(); props.Clear(); shots.Clear(); wavesFx.Clear(); blasts.Clear(); pools.Clear();
		parts.Clear(); slashes.Clear(); texts.Clear(); doors.Clear(); stains.Clear();
		foreach (var g in ghosts) if (g.sr != null) Destroy(g.sr.gameObject);
		ghosts.Clear();
	}

	void EnterRoom(string kind) {
		ClearRoom();
		roomKind = kind;
		cleared = false; wave = 0; roomT = 0; pickT = 0; pickKind = "";
		SetBg(ch);
		PR = CH_PR[ch];
		ppos = new Vector2(PR.center.x, PR.yMin + 80);
		act = ""; guard = false; whirlT = 0; inv = 0.5f;
		dashes = dashMax;
		var r = new System.Random(seed + ch * 100 + step * 7);
		int np = kind == "boss" || kind == "shop" || kind == "tra" || kind == "ky" ? 0 : 2 + r.Next(3);
		for (int i = 0; i < np; i++) {
			string n = D.CH_PROPS[ch][r.Next(D.CH_PROPS[ch].Length)];
			Vector2 p = Vector2.zero;
			for (int tries = 0; tries < 20; tries++) {
				p = new Vector2(PR.xMin + 90 + (float)r.NextDouble() * (PR.width - 180), PR.yMin + 190 + (float)r.NextDouble() * (PR.height - 380));
				bool ok = Mathf.Abs(p.x - PR.center.x) > 170 || Mathf.Abs(p.y - PR.center.y) > 150;
				foreach (var o in props) if ((o.pos - p).magnitude < 220) ok = false;
				if (ok) break;
			}
			float h = n == "bamboo" || n == "pine" ? 190 : (n == "jar" ? 80 : 120);
			var pr = new Prop { pos = p, r = n == "bamboo" ? 30 : (n == "jar" ? 30 : 46), sr = NewSpr(n, h) };
			props.Add(pr);
		}
		if (kind == "boss") {
			var b = Spawn("boss" + (ch + 1), new Vector2(PR.center.x, PR.yMax - 190), false);
			b.spawn = 1.3f;
			Banner(b.d.name, D.CH_NAME[ch]);
			sfx.Play("gong");
			sfx.Battle(true);
		} else if (kind == "shop" || kind == "tra" || kind == "ky") {
			cleared = true;
			Vector2 c = PR.center + new Vector2(0, 110);
			string npc = kind == "shop" ? "merchant" : (kind == "tra" ? "tea" : "hermit");
			var nsr = NewSpr(npc, kind == "tra" ? 95 : 130);
			items.Add(new Item { pos = c, kind = "npc", label = "", sr = nsr });
			if (kind == "shop") {
				AddItem(c + new Vector2(-240, -130), "heal", "KIM SANG DƯỢC\nHồi 40 sinh lực", 35, "jar", null);
				AddItem(c + new Vector2(-80, -160), "dan", "LINH ĐAN\n+15 sinh lực tối đa", 60, "jar", null);
				var o = MakeOffers(1);
				if (o.Count > 0) AddItem(c + new Vector2(80, -160), "boon", o[0].b.name + " · CẤP " + o[0].lvl + "\n" + D.Desc(o[0].b, o[0].lvl), 70, "chest", o[0].b);
				AddItem(c + new Vector2(240, -130), "luyen", "LUYỆN KHÍ\nNâng cấp một chiêu đã học", 80, "shrine", null);
			} else if (kind == "tra") {
				AddItem(c + new Vector2(0, -120), "tea", "THƯỞNG TRÀ\nHồi 40% sinh lực", 0, null, null);
			} else {
				AddItem(c + new Vector2(0, -120), "ky", "BÁI KIẾN CAO NHÂN", 0, null, null);
			}
			MakeDoors();
			sfx.Battle(false);
			Banner(D.RewardName(kind), D.RewardHint(kind));
		} else {
			waves = 2 + (step >= 2 ? 1 : 0);
			spawnT = 0.9f;
			sfx.Battle(true);
		}
	}

	void AddItem(Vector2 p, string kind, string label, int cost, string spr, Boon b) {
		items.Add(new Item { pos = p, kind = kind, label = label, cost = cost, boon = b, sr = spr == null ? null : NewSpr(spr, kind == "luyen" ? 100 : 70) });
	}

	void SpawnWave() {
		wave++;
		float budget = 2.6f + ch * 1.3f + step * 0.7f + meta.kiep * 0.6f + wave * 0.4f;
		var pool = D.POOLS[ch];
		int n = 0;
		while (budget > 0.4f && n < 7) {
			var d = D.Foe(pool[rng.Next(pool.Length)]);
			if (d.cost > budget + 0.6f) { if (n > 0 && Rnd() < 0.5f) break; d = D.Foe(pool[0]); }
			bool elite = Rnd() < 0.08f + ch * 0.05f && budget > d.cost * 2;
			Vector2 p = Vector2.zero;
			for (int tries = 0; tries < 15; tries++) {
				p = new Vector2(Rnd(PR.xMin + 60, PR.xMax - 60), Rnd(PR.yMin + 60, PR.yMax - 60));
				if ((p - ppos).magnitude > 330) break;
			}
			Spawn(d.id, p, elite);
			budget -= d.cost * (elite ? 2 : 1);
			n++;
		}
		sfx.Play("drum", 0.8f);
	}

	Foe Spawn(string id, Vector2 p, bool elite) {
		var d = D.Foe(id);
		float kiep = 1 + meta.kiep * 0.2f;
		var f = new Foe { d = d, pos = Confine(p, d.r), elite = elite, spawn = 0.75f, cd = Rnd(0.3f, 1.2f) };
		f.maxHp = d.hp * (d.boss ? 1 : D.CH_HP[ch]) * kiep * (elite ? 2.3f : 1);
		f.hp = f.maxHp;
		f.posMax = d.pos * (elite ? 1.6f : 1) * (d.boss ? 1 : 1 + ch * 0.25f);
		f.dmgMul = (d.boss ? 1 : D.CH_DMG[ch]) * (1 + meta.kiep * 0.12f) * (elite ? 1.3f : 1);
		f.scale = elite ? 1.22f : 1;
		f.mcd = new float[d.moves.Length];
		f.used = new bool[d.moves.Length];
		f.sr = NewSpr(d.id, d.h * f.scale);
		var wf = Frames(d.id + "_walk");
		if (wf.Length > 0) {
			f.walk = wf; f.wind = Spr(d.id + "_wind"); f.hit = Spr(d.id + "_hit");
			f.sr.sprite = wf[0];
			f.sr.transform.localScale = Vector3.one * f.scale;
		}
		foes.Add(f);
		Puff(f.pos, D.INK, 14, 180);
		return f;
	}

	void RoomCleared() {
		cleared = true;
		rooms++;
		sfx.Battle(false);
		sfx.Play("gong", 0.7f);
		shots.RemoveAll(s => !s.mine);
		Heal(Up("heal") * 3);
		slow = 0.5f;
		if (roomKind == "boss") {
			bossKills++;
			Heal(maxHp * 0.3f);
			AddCoins(60);
			if (ch == 0 && !meta.unl.Contains("thuong")) { meta.unl.Add("thuong"); Toast("MỞ KHÓA: PHÁ QUÂN THƯƠNG"); }
			if (ch == 1 && !meta.unl.Contains("phien")) { meta.unl.Add("phien"); Toast("MỞ KHÓA: THIẾT PHIẾN"); }
			SaveMeta();
			pickKind = "bikip"; pickBonus = 1; pickT = 1.4f;
			Banner("ĐẠI THẮNG", "Trùm đã ngã");
		} else if (roomKind == "bikip" || roomKind == "luyen") { pickKind = roomKind; pickBonus = 0; pickT = 0.9f; }
		else if (roomKind == "dan") { bonusHp += 15; Recalc(); Heal(25); Toast("LINH ĐAN: +15 sinh lực tối đa"); }
		else if (roomKind == "ngan") { int c = 45 + ch * 15 + rng.Next(20); AddCoins(c); Toast("NHẶT ĐƯỢC TÚI NGÂN LƯỢNG"); }
		MakeDoors();
	}

	void MakeDoors() {
		doors.Clear();
		var kinds = new List<string>();
		if (roomKind == "boss") kinds.Add(ch >= 2 ? "end" : "next");
		else if (step >= 4) kinds.Add("boss");
		else if (step == 3) { kinds.Add("shop"); kinds.Add("tra"); }
		else {
			string[] pool = { "bikip", "bikip", "bikip", "luyen", "dan", "ngan" };
			string a = pool[rng.Next(pool.Length)], b = a;
			while (b == a) b = pool[rng.Next(pool.Length)];
			if (boons.Count == 0) { if (a == "luyen") a = "bikip"; if (b == "luyen") b = "ngan"; if (a == b) b = "dan"; }
			if (step >= 1 && Rnd() < 0.3f) b = "ky";
			kinds.Add(a); kinds.Add(b);
		}
		for (int i = 0; i < kinds.Count; i++) {
			float x = PR.center.x + (i - (kinds.Count - 1) * 0.5f) * 420;
			doors.Add(new Door { pos = new Vector2(x, PR.yMax - 10), kind = kinds[i] });
		}
	}

	void UseDoor(Door d) {
		sfx.Play("drum");
		if (d.kind == "end") { Win(); return; }
		if (d.kind == "next") { ch++; step = 0; Banner(D.CH_NAME[ch]); EnterRoom("bikip"); return; }
		step++;
		EnterRoom(d.kind);
	}

	void Heal(float v) {
		if (v <= 0 || hp <= 0) return;
		float before = hp;
		hp = Mathf.Min(maxHp, hp + v);
		if (hp - before >= 1) Text(ppos + new Vector2(0, 130), "+" + Mathf.RoundToInt(hp - before), new Color(0.5f, 0.9f, 0.5f), 22);
	}
	void AddCoins(int c) { coins += Mathf.RoundToInt(c * coinMul); sfx.Play("coin", 0.6f); }

	// --- offers
	List<Offer> MakeOffers(int n, int bonus = 0) {
		var cand = new List<Boon>();
		var wt = new List<float>();
		foreach (var b in D.BOONS) {
			int lv = Lv(b.id);
			if (lv >= 3) continue;
			float w = 2;
			if (b.slot != "pas") {
				Boon cur;
				if (!slot.TryGetValue(b.slot, out cur)) w = 3;
				else if (cur.id == b.id) w = 2.2f;
				else w = 0.5f;
			} else if (lv > 0) w = 1.5f;
			// the first manuals of a run should put phases in the hands: reactions need two of them
			if (b.slot == "pas" && slot.Count < 2) w = 0.35f;
			cand.Add(b); wt.Add(w);
		}
		var res = new List<Offer>();
		while (res.Count < n && cand.Count > 0) {
			float tot = 0;
			foreach (var w in wt) tot += w;
			float x = Rnd() * tot;
			int k = 0;
			for (; k < cand.Count - 1; k++) { x -= wt[k]; if (x <= 0) break; }
			var b = cand[k];
			Boon cur;
			bool rep = b.slot != "pas" && slot.TryGetValue(b.slot, out cur) && cur.id != b.id;
			res.Add(new Offer { b = b, lvl = Mathf.Min(3, Lv(b.id) + 1 + bonus), replace = rep });
			cand.RemoveAt(k); wt.RemoveAt(k);
		}
		return res;
	}

	void OpenPick(string kind, int bonus) {
		offers.Clear();
		if (kind == "luyen") {
			var own = new List<string>(boons.Keys);
			own.RemoveAll(id => boons[id] >= 3);
			while (own.Count > 3) own.RemoveAt(rng.Next(own.Count));
			foreach (var id in own) offers.Add(new Offer { b = D.BoonById(id), lvl = boons[id] + 1 });
			if (offers.Count == 0) { AddCoins(40); Toast("Không còn gì để luyện: nhận ngân lượng"); return; }
		} else offers = MakeOffers(3, bonus);
		if (offers.Count == 0) return;
		pickKind = kind;
		state = "pick";
		menuI = 0;
		sfx.Play("pick", 0.8f);
	}

	void PickAct(int i) {
		if (i < 0 || i >= offers.Count) return;
		Learn(offers[i].b, offers[i].lvl);
		state = "play";
		prev.atk = true; inp.atk = false; buf = 0;
	}

	void Learn(Boon b, int lvl) {
		if (b.slot != "pas") {
			Boon cur;
			if (slot.TryGetValue(b.slot, out cur) && cur.id != b.id) boons.Remove(cur.id);
			slot[b.slot] = b;
		}
		boons[b.id] = Mathf.Clamp(lvl, 1, 3);
		float before = maxHp;
		Recalc();
		if (maxHp > before) hp += maxHp - before;
		sfx.Play("pick");
		Toast("LĨNH NGỘ: " + b.name + " · CẤP " + boons[b.id]);
	}

	void EventAct(int i) {
		if (i == 0) {
			if (hp <= 21) { sfx.Play("block"); return; }
			hp -= 20;
			state = "play";
			OpenPick("bikip", 1);
		} else if (i == 1) {
			if (coins < 40 || boons.Count == 0) { sfx.Play("block"); return; }
			coins -= 40;
			var own = new List<string>(boons.Keys);
			own.RemoveAll(id => boons[id] >= 3);
			for (int k = 0; k < 2 && own.Count > 0; k++) {
				int j = rng.Next(own.Count);
				Learn(D.BoonById(own[j]), boons[own[j]] + 1);
				own.RemoveAt(j);
			}
			state = "play";
		} else state = "play";
	}

	void UseItem(Item it) {
		if (it.kind == "npc" || it.gone) return;
		if (coins < it.cost) { sfx.Play("block"); Toast("Không đủ ngân lượng"); return; }
		if (it.kind == "luyen") {
			bool any = false;
			foreach (var kv in boons) if (kv.Value < 3) any = true;
			if (!any) { sfx.Play("block"); Toast("Chưa có chiêu nào để luyện"); return; }
		}
		coins -= it.cost;
		it.gone = true;
		if (it.sr != null) { Destroy(it.sr.gameObject); it.sr = null; }
		switch (it.kind) {
			case "heal": Heal(40); sfx.Play("pick"); break;
			case "dan": bonusHp += 15; Recalc(); Heal(15); sfx.Play("pick"); break;
			case "boon": Learn(it.boon, Lv(it.boon.id) + 1); break;
			case "luyen": OpenPick("luyen", 0); break;
			case "tea": Heal(maxHp * 0.4f); sfx.Play("pick"); Toast("Trà ấm, lòng tĩnh."); break;
			case "ky": state = "event"; menuI = 0; sfx.Play("pick"); break;
		}
	}

	void Die() {
		if (cheat) { hp = maxHp; return; }
		if (reviveLeft) {
			reviveLeft = false;
			hp = maxHp * 0.4f; inv = 2f;
			Burst(ppos, 320, 40, -1, 0, false);
			Banner("BẤT TỬ PHÙ", "Đứng dậy lần nữa");
			return;
		}
		EndRun(false);
	}
	void Win() { EndRun(true); }

	void EndRun(bool win) {
		earned = rooms * 2 + bossKills * 10 + (win ? 25 : 0);
		meta.ngo += earned;
		meta.best = Mathf.Max(meta.best, ch * 6 + step + (win ? 6 : 0));
		if (win) { meta.wins++; meta.kiep = Mathf.Min(meta.kiep + 1, 9); }
		SaveMeta();
		state = win ? "win" : "dead";
		endT = T;
		sfx.Battle(false);
		sfx.Play("gong");
	}

	// --- simulation
	void Sim(float dt) {
		runTime += dt;
		roomT += dt;
		UpPlayer(dt);
		UpFoes(dt);
		UpShots(dt);
		UpFx(dt);
		// room logic
		if (!cleared) {
			bool any = false;
			foreach (var f in foes) if (!f.dead) any = true;
			if (roomKind == "boss") {
				bool bossAlive = false;
				foreach (var f in foes) if (!f.dead && f.d.boss) bossAlive = true;
				if (!bossAlive) { foreach (var f in foes) if (!f.dead) Kill(f); RoomCleared(); }
			} else if (!any) {
				if (wave < waves) { spawnT -= dt; if (spawnT <= 0) { SpawnWave(); spawnT = 0.8f; } }
				else RoomCleared();
			}
		} else {
			if (pickKind != "" && pickT > 0) { pickT -= dt; if (pickT <= 0) { string k = pickKind; pickKind = ""; OpenPick(k, pickBonus); } }
			if (P(inp.use, prev.use) && pickT <= 0) {
				foreach (var d in doors) if ((d.pos - ppos).magnitude < 120) { UseDoor(d); return; }
				foreach (var it in items) if (!it.gone && it.kind != "npc" && (it.pos - ppos).magnitude < 90) { UseItem(it); break; }
			}
		}
		if (hp <= 0 && state == "play") Die();
	}

	public Vector2 Confine(Vector2 p, float r) {
		p.x = Mathf.Clamp(p.x, PR.xMin + r, PR.xMax - r);
		p.y = Mathf.Clamp(p.y, PR.yMin + r * 0.5f, PR.yMax - r * 0.5f);
		foreach (var pr in props) {
			Vector2 d = p - pr.pos;
			d.y *= 1.6f;   // props block an ellipse wider than deep
			float m = d.magnitude, need = pr.r + r;
			if (m < need && m > 0.01f) { Vector2 push = d / m * (need - m); push.y /= 1.6f; p += push; }
		}
		return p;
	}

	void UpPlayer(float dt) {
		inv -= dt; pflash -= dt; acd -= dt; pcd -= dt; comboT -= dt; hurtFx -= dt;
		if (comboT <= 0 && act != "atk") ci = 0;
		if (dashes < dashMax) { dashCd -= dt; if (dashCd <= 0) { dashes++; dashCd = 0.75f; } }
		Vector2 av = inp.aim - ppos;
		if (av.sqrMagnitude > 4) aimDir = av.normalized;
		if (inp.atk) buf = 0.18f; else buf -= dt;
		bool canGuard = act != "dash" && act != "skill";
		if (P(inp.parry, prev.parry) && canGuard && pcd <= 0) { guard = true; gt = 0; pcd = 0.42f; if (act == "atk") act = ""; }
		if (!inp.parry || !canGuard) guard = false;
		if (guard) gt += dt;
		if (P(inp.dash, prev.dash) && dashes > 0 && act != "skill") {
			ddir = inp.mv.sqrMagnitude > 0.1f ? inp.mv.normalized : aimDir;
			if (dashes == dashMax) dashCd = 0.75f;
			dashes--;
			act = "dash"; at = 0; guard = false;
			inv = Mathf.Max(inv, 0.3f);
			sfx.Play("dash", 0.7f);
			DashBurst();
		}
		if (P(inp.skill, prev.skill) && qi >= 50 && act != "dash" && act != "skill") StartSkill();
		moving = false;
		switch (act) {
			case "dash":
				at += dt;
				ppos += ddir * 1250 * dt;
				ghostT -= dt;
				if (ghostT <= 0) { ghostT = 0.028f; AddGhost(heroSr, ppos, new Color(0.07f, 0.06f, 0.08f, 0.55f), 0.22f); }
				if (Rnd() < 0.8f) parts.Add(new Part { pos = ppos + new Vector2(0, 50) + RndDir() * 20, vel = -ddir * 60, r = Rnd(8, 18), life = 0.3f, max = 0.3f, col = new Color(0.07f, 0.06f, 0.06f, 0.5f) });
				if (ddir.x != 0) face = ddir.x > 0 ? 1 : -1;
				if (at >= 0.17f) { act = ""; DashBurst(); }
				break;
			case "atk": {
				var s = weapon.combo[ci];
				at += dt;
				if (at < s.dur * 0.5f) ppos += adir * s.lunge * (1 - at / s.dur) * dt * 2;
				if (!hitDone && at >= s.dur * 0.3f) { hitDone = true; Strike(s); }
				if (at >= s.dur) {
					act = ""; comboT = 0.55f; ci++;
					if (ci >= weapon.combo.Length) { ci = 0; acd = 0.16f; }
				}
				break;
			}
			case "skill":
				at += dt;
				if (weapon.skill == "charge") {
					ppos += adir * 2300 * dt;
					AddGhost(heroSr, ppos, new Color(0.07f, 0.06f, 0.08f, 0.6f), 0.3f);
					inv = Mathf.Max(inv, 0.1f);
					parts.Add(new Part { pos = ppos + new Vector2(0, 50), vel = Vector2.zero, r = 22, life = 0.3f, max = 0.3f, col = new Color(0.07f, 0.06f, 0.06f, 0.5f) });
					if (at >= 0.2f) act = "";
				} else if (at >= 0.28f) act = "";
				break;
			default:
				if (buf > 0 && acd <= 0 && !guard) {
					act = "atk"; at = 0; hitDone = false; adir = aimDir;
					face = adir.x >= 0 ? 1 : -1;
					break;
				}
				Vector2 v = inp.mv * 370 * (guard ? 0.45f : 1);
				ppos += v * dt;
				moving = v.sqrMagnitude > 100;
				if (moving) {
					moveAmt += dt * (guard ? 0.5f : 1);
					// a puff of dust each time a foot lands (frames 0 and 4 of the run cycle)
					int fr = (int)(moveAmt * 15) % 8;
					if (fr != lastStep && (fr == 0 || fr == 4)) parts.Add(new Part { pos = ppos + new Vector2(-face * 14, 4), vel = new Vector2(-face * 40, 30), r = Rnd(7, 11), life = 0.32f, max = 0.32f, col = new Color(0.07f, 0.06f, 0.06f, 0.22f) });
					lastStep = fr;
				}
				if (guard || !moving) face = aimDir.x >= 0 ? 1 : -1;
				else if (Mathf.Abs(v.x) > 10) face = v.x > 0 ? 1 : -1;
				break;
		}
		if (whirlT > 0) {
			whirlT -= dt; whirlTick -= dt;
			if (whirlTick <= 0) {
				whirlTick = 0.22f;
				float mult = dmgMul * (1 + SlotLv("skill") * 0.3f);
				foreach (var f in foes) {
					if (f.dead || f.spawn > 0) continue;
					Vector2 d = ppos - f.pos;
					if (d.magnitude < 250 + f.d.r) {
						if (!f.d.boss) f.kb += d.normalized * 260;
						HurtFoe(f, 9 * mult, SlotEl("skill"), SlotLv("skill"), 1, -d.normalized, true, false);
					}
				}
				sfx.Play("slash", 0.4f, 1.3f);
			}
		}
		ppos = Confine(ppos, 22);
	}

	void DashBurst() {
		int el = SlotEl("dash");
		if (el < 0) return;
		Burst(ppos, 125, 16 * SlotLv("dash") * dmgMul, el, SlotLv("dash"), true);
	}

	void StartSkill() {
		qi -= 50;
		act = "skill"; at = 0; guard = false;
		adir = aimDir;
		face = adir.x >= 0 ? 1 : -1;
		int el = SlotEl("skill"), lv = SlotLv("skill");
		float mult = dmgMul * (1 + lv * 0.3f);
		Color col = el >= 0 ? D.EL_COL[el] : D.INK;
		sfx.Play("skill");
		shake = Mathf.Max(shake, 6);
		Text(ppos + new Vector2(0, 150), weapon.skillName, D.PAPER, 24);
		if (weapon.skill == "fan") {
			for (int i = 0; i < 7; i++) {
				float a = Mathf.Atan2(adir.y, adir.x) + (i - 3) * 0.15f;
				shots.Add(new Shot { pos = ppos + new Vector2(0, 55), vel = new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 1050, dmg = 22 * mult, mine = true, el = el, lvl = lv, pierce = 3, r = 14, life = 0.9f, hit = new List<Foe>() });
			}
		} else if (weapon.skill == "charge") {
			inv = Mathf.Max(inv, 0.35f);
			slashes.Add(new Slash { pos = ppos + new Vector2(0, 45), dir = adir, line = true, len = 540, wid = 90, col = col });
			foreach (var f in foes) {
				if (f.dead || f.spawn > 0) continue;
				if (LineHit(ppos, adir, 540, 90, f.pos, f.d.r)) HurtFoe(f, 55 * mult, el, lv, 1.5f, adir);
			}
		} else {
			whirlT = 2.2f; whirlTick = 0;
		}
	}

	void Strike(AtkStep s) {
		int el = SlotEl("atk"), lv = SlotLv("atk");
		float mult = dmgMul * (1 + lv * 0.15f);
		bool last = ci == weapon.combo.Length - 1;
		if (last) mult *= 1 + Lv("fin") * 0.4f;
		if (riposte) { mult *= 1 + Lv("ripo") * 1.0f; riposte = false; }
		Color col = el >= 0 ? D.EL_COL[el] : D.INK;
		Vector2 o = ppos;
		sfx.Play("slash", 0.55f, last ? 0.85f : 1.1f);
		if (s.t == "shot") {
			for (int i = 0; i < s.n; i++) {
				float a = Mathf.Atan2(adir.y, adir.x) + (s.n == 1 ? 0 : Mathf.Lerp(-s.spread, s.spread, i / (float)(s.n - 1)));
				shots.Add(new Shot { pos = o + new Vector2(0, 55), vel = new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * s.spd, dmg = s.dmg * mult, mine = true, el = el, lvl = lv, pierce = 1, r = 12, life = 0.62f, hit = new List<Foe>() });
			}
			return;
		}
		bool arc = s.t == "arc";
		slashes.Add(new Slash { pos = o + new Vector2(0, 45), dir = adir, r = s.r, w = s.w, line = !arc, len = s.len, wid = s.wid, col = col });
		bool any = false;
		foreach (var f in foes) {
			if (f.dead || f.spawn > 0) continue;
			bool h = arc ? ArcHit(o, adir, s.r, s.w, f.pos, f.d.r * f.scale) : LineHit(o, adir, s.len, s.wid, f.pos, f.d.r * f.scale);
			if (h) { HurtFoe(f, s.dmg * mult, el, lv, 1, adir); any = true; }
		}
		// blades cut arrows out of the air
		foreach (var sh in shots) {
			if (sh.mine || sh.life <= 0) continue;
			bool h = arc ? ArcHit(o, adir, s.r, s.w, sh.pos - new Vector2(0, 50), 10) : LineHit(o, adir, s.len, s.wid, sh.pos - new Vector2(0, 50), 10);
			if (h) { sh.life = 0; Puff(sh.pos, D.INK, 4, 120); }
		}
		if (any) { stop = Mathf.Max(stop, last ? 0.07f : 0.035f); shake = Mathf.Max(shake, last ? 7 : 3); }
	}

	public static bool ArcHit(Vector2 o, Vector2 dir, float r, float w, Vector2 t, float tr) {
		Vector2 d = t - o;
		float m = d.magnitude;
		if (m > r + tr) return false;
		if (w >= 6.2f || m < tr + 20) return true;
		return Vector2.Angle(dir, d) * Mathf.Deg2Rad <= w * 0.5f + Mathf.Atan2(tr, m);
	}
	public static bool LineHit(Vector2 o, Vector2 dir, float len, float wid, Vector2 t, float tr) {
		Vector2 d = t - o;
		float along = Vector2.Dot(d, dir);
		if (along < -tr || along > len + tr) return false;
		return Mathf.Abs(d.x * dir.y - d.y * dir.x) <= wid * 0.5f + tr;
	}

	void Text(Vector2 p, string s, Color c, int size = 20) { texts.Add(new FText { pos = p + new Vector2(Rnd(-14, 14), 0), s = s, col = c, size = size }); }

	public void Puff(Vector2 p, Color c, int n, float spd) {
		for (int i = 0; i < n; i++) {
			float l = Rnd(0.25f, 0.6f);
			parts.Add(new Part { pos = p + new Vector2(0, 40) + RndDir() * 8, vel = RndDir() * Rnd(spd * 0.3f, spd), r = Rnd(3, 9), life = l, max = l, col = c, grav = 300 });
		}
	}
}
