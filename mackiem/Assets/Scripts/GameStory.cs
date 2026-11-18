using System;
using System.Collections.Generic;
using UnityEngine;

// The story route (text in Resources/story.json, written with Gemini):
// prologue on the first run, a line opening every run that goes deeper each time, chapter intros,
// boss words that change with how often you beat them, NPC lines per chapter, a line on death,
// milestones by number of runs, and two endings (the true one needs all nine KÝ ỨC).
[Serializable] public class ChapterStory { public string name, intro; public string[] boss_intro, boss_defeat; }
[Serializable] public class NpcStory { public string[] merchant, tea, hermit; }
[Serializable] public class Milestone { public int runs; public string text; }
[Serializable] public class StoryData {
	public string[] prologue, run_intro, death, ending_normal, ending_true;
	public ChapterStory[] chapters;
	public NpcStory npc;
	public Milestone[] milestones;
}

public partial class Game {
	StoryData story;
	string[] storyLines;
	string storyTitle = "";
	string storyNext = "play";
	float storyT;
	string deathLine = "", milestoneLine = "";

	void LoadStory() {
		var ta = Resources.Load<TextAsset>("story");
		if (ta != null) story = JsonUtility.FromJson<StoryData>(ta.text);
	}

	static string Pick(string[] a, int i) { return a == null || a.Length == 0 ? "" : a[Mathf.Clamp(i, 0, a.Length - 1)]; }

	int BossBeaten(int c) { return meta.bk != null && c < meta.bk.Count ? meta.bk[c] : 0; }

	void ShowStory(string title, string[] lines, string next) {
		if (lines == null || lines.Length == 0) { state = next; return; }
		storyTitle = title; storyLines = lines; storyNext = next; storyT = 0;
		state = "story";
	}

	void StoryTick(float dt) {
		storyT += dt;
		if (T - stateT > 1.0f && (P(inp.ok, prev.ok) || P(inp.back, prev.back) || (bot && storyT > 3))) {
			state = storyNext;
			if (state == "win" || state == "dead") endT = T;
		}
	}

	void GuiStory() {
		Dim(0.88f);
		Lab(new Rect(0, 90, GW, 60), storyTitle, 40, new Color(0.91f, 0.86f, 0.75f), TextAnchor.MiddleCenter, true);
		Box(new Rect(GW / 2 - 140, 156, 280, 2), D.RED);
		for (int i = 0; i < storyLines.Length; i++) {
			float a = Mathf.Clamp01(storyT * 1.2f - i * 0.6f);
			Lab(new Rect(GW / 2 - 460, 190 + i * 52, 920, 48), storyLines[i], 22, new Color(0.91f, 0.86f, 0.75f, a), TextAnchor.MiddleCenter, true);
		}
		if (T - stateT > 1.0f) Lab(new Rect(0, GH - 70, GW, 30), "ENTER tiếp tục", 17, new Color(1f, 0.9f, 0.5f, 0.6f + 0.4f * Mathf.Sin(T * 4)));
	}

	// --- hooks
	void StoryRunStart() {
		if (story == null) return;
		if (meta.runs == 1) ShowStory("MẶC KIẾM LỤC", story.prologue, "play");
		else Banner(D.CH_NAME[0], Pick(story.run_intro, meta.runs - 2));
	}

	string StoryChapterIntro(int c) { return story == null ? "Đường còn dài" : story.chapters[c].intro; }
	string StoryBossIntro(int c) { return story == null ? D.CH_NAME[c] : Pick(story.chapters[c].boss_intro, BossBeaten(c)); }

	string StoryBossDefeat(int c) {
		while (meta.bk.Count < 3) meta.bk.Add(0);
		string s = story == null ? "Trùm đã ngã" : Pick(story.chapters[c].boss_defeat, meta.bk[c]);
		meta.bk[c]++;
		return s;
	}

	string StoryNpc(string who) {
		if (story == null || story.npc == null) return "";
		string[] a = who == "merchant" ? story.npc.merchant : (who == "tea" ? story.npc.tea : story.npc.hermit);
		return Pick(a, ch * 3 + meta.runs % 3);
	}

	// called by EndRun before the result screen
	void StoryEnd(bool win) {
		deathLine = ""; milestoneLine = "";
		if (story == null) return;
		if (!win) deathLine = Pick(story.death, meta.runs % Mathf.Max(1, story.death.Length));
		if (story.milestones != null) foreach (var m in story.milestones) if (m.runs == meta.runs) milestoneLine = m.text;
		if (win) {
			bool trueEnd = meta.mem.Count >= 9;
			ShowStory(trueEnd ? "TRANG CUỐI" : "HẠ SƠN", trueEnd ? story.ending_true : story.ending_normal, "win");
		}
	}
}
