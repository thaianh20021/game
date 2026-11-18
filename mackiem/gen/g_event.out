using System;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public class EventChoice {
	public string text, effect, result;
	public int cost_hp, cost_coin;
	public float value;
}

[Serializable]
public class EventDef {
	public string id, title, text;
	public int chapter;
	public EventChoice[] choices;
}

[Serializable]
public class EventRoot {
	public EventDef[] events;
}

public partial class Game {
	EventDef[] kyNgoEvents = new EventDef[0];
	readonly HashSet<string> seenEvents = new HashSet<string>();
	EventDef curEvent;
	EventChoice eventPicked;
	float eventPickedT;
	float runCurseDmg;

	void LoadEvents() {
		var ta = Resources.Load<TextAsset>("events");
		if (ta == null) return;
		var root = JsonUtility.FromJson<EventRoot>(ta.text);
		if (root != null && root.events != null) kyNgoEvents = root.events;
	}

	void ResetEvents() {
		seenEvents.Clear();
		curEvent = null;
		eventPicked = null;
		runCurseDmg = 0;
	}

	void OpenEvent() {
		if (kyNgoEvents == null || kyNgoEvents.Length == 0) { state = "play"; return; }
		var cand = new List<EventDef>();
		for (int i = 0; i < kyNgoEvents.Length; i++) {
			var ev = kyNgoEvents[i];
			if ((ev.chapter == -1 || ev.chapter == ch) && !seenEvents.Contains(ev.id)) cand.Add(ev);
		}
		if (cand.Count == 0) {
			for (int i = 0; i < kyNgoEvents.Length; i++) {
				var ev = kyNgoEvents[i];
				if (ev.chapter == -1 || ev.chapter == ch) cand.Add(ev);
			}
		}
		if (cand.Count == 0) { state = "play"; return; }
		curEvent = cand[rng.Next(cand.Count)];
		seenEvents.Add(curEvent.id);
		eventPicked = null;
		state = "kyngo";
		menuI = 0;
		sfx.Play("pick", 0.8f);
	}

	bool CanAffordChoice(EventChoice c) {
		if (c.cost_hp > 0 && hp <= c.cost_hp + 1) return false;
		if (c.cost_coin > 0 && coins < c.cost_coin) return false;
		return true;
	}

	void EventTick() {
		if (curEvent == null || curEvent.choices == null || curEvent.choices.Length == 0) { state = "play"; return; }
		if (eventPicked == null) Menu(curEvent.choices.Length, KyNgoAct);
		else if (P(inp.ok, prev.ok) && T - eventPickedT > 0.15f) CloseKyNgo();
	}

	void KyNgoAct(int i) {
		if (curEvent == null || curEvent.choices == null || i < 0 || i >= curEvent.choices.Length) return;
		var c = curEvent.choices[i];
		if (!CanAffordChoice(c)) { sfx.Play("block"); return; }

		if (c.cost_hp > 0) hp -= c.cost_hp;
		if (c.cost_coin > 0) coins -= c.cost_coin;

		switch (c.effect) {
			case "boon_up": {
				var own = new List<string>();
				foreach (var kv in boons) if (kv.Value < 3) own.Add(kv.Key);
				int n = Mathf.RoundToInt(c.value);
				for (int k = 0; k < n && own.Count > 0; k++) {
					int j = rng.Next(own.Count);
					string id = own[j];
					own.RemoveAt(j);
					Learn(D.BoonById(id), boons[id] + 1);
				}
				break;
			}
			case "heal_pct":
				Heal(maxHp * c.value / 100f);
				break;
			case "maxhp":
				bonusHp += c.value;
				Recalc();
				Heal(c.value);
				break;
			case "coins":
				coins = Mathf.Max(0, coins + (int)c.value);
				break;
			case "curse_dmg":
				runCurseDmg += c.value / 100f;
				break;
			case "curse_hp":
				bonusHp -= c.value;
				Recalc();
				hp = Mathf.Min(hp, maxHp);
				break;
			case "boon":
			case "relic":
			case "weapon":
			case "memory_hint":
			case "nothing":
			default:
				break;
		}

		sfx.Play("pick", 0.7f);
		eventPicked = c;
		eventPickedT = T;
	}

	void CloseKyNgo() {
		string eff = eventPicked != null ? eventPicked.effect : "";
		float val = eventPicked != null ? eventPicked.value : 0;
		curEvent = null;
		eventPicked = null;
		state = "play";
		prev.ok = true;
		inp.ok = false;
		if (eff == "boon") OpenPick("bikip", 1);
		else if (eff == "relic") OpenRelic();
		else if (eff == "weapon") OpenWeaponChoice(1, (int)val);
	}

	void GuiKyNgo() {
		if (curEvent == null) return;
		Dim(0.6f);
		int n = curEvent.choices != null ? curEvent.choices.Length : 0;
		float h = eventPicked != null ? 360 : Mathf.Max(400, 210 + n * 76);
		var r = new Rect((GW - 780) / 2f, (GH - h) / 2f, 780, h);
		Panel(r);
		Lab(new Rect(r.x, r.y + 18, r.width, 44), curEvent.title, 30, D.INK, TextAnchor.MiddleCenter, true, false);

		if (eventPicked == null) {
			Lab(new Rect(r.x + 50, r.y + 70, r.width - 100, 96), curEvent.text, 18, new Color(0.2f, 0.18f, 0.17f), TextAnchor.MiddleCenter, true, false);
			for (int i = 0; i < n; i++) {
				var c = curEvent.choices[i];
				var b = new Rect(r.x + 50, r.y + 180 + i * 74, r.width - 100, 60);
				bool sel = menuI == i;
				bool ok = CanAffordChoice(c);
				Box(new Rect(b.x - 3, b.y - 3, b.width + 6, b.height + 6), sel ? D.RED : new Color(0.07f, 0.06f, 0.06f, 0.5f));
				Box(b, sel ? new Color(0.97f, 0.93f, 0.84f) : D.PAPER);
				Lab(b, c.text, 18, ok ? D.INK : new Color(0.45f, 0.42f, 0.4f), TextAnchor.MiddleCenter, false, false);
				if (Hit(b, i)) KyNgoAct(i);
			}
		} else {
			Lab(new Rect(r.x + 50, r.y + 84, r.width - 100, 150), eventPicked.result, 19, new Color(0.2f, 0.18f, 0.17f), TextAnchor.MiddleCenter, true, false);
			var b = new Rect(r.x + 220, r.yMax - 82, r.width - 440, 52);
			Box(new Rect(b.x - 3, b.y - 3, b.width + 6, b.height + 6), D.RED);
			Box(b, new Color(0.97f, 0.93f, 0.84f));
			Lab(b, "TIẾP TỤC  [ENTER]", 18, D.INK, TextAnchor.MiddleCenter, false, false);
			if (Hit(b, 0)) CloseKyNgo();
		}
	}
}

// --- HOOK LINES IN OTHER FILES ---
// 1. Game.cs Awake() (after LoadStory();):
//    LoadEvents();
// 2. Game.cs StartRun():
//    ResetEvents();
// 3. UseDoor(...) case "ky":
//    case "ky": OpenEvent(); break;
// 4. Game.cs Tick(float rdt) switch (state):
//    case "kyngo": EventTick(); break;
// 5. GameDraw.cs OnGUI() (after case "event": GuiEvent();):
//    else if (state == "kyngo") GuiKyNgo();
// 6. InWorld (where state == "event" is checked):
//    || state == "kyngo"
// 7. GameFoes.cs HitPlayer(...) (damage-taken multiplier):
//    dmg *= 1f + runCurseDmg;
