using System.Collections.Generic;
using UnityEngine;

// Every sound and the music are synthesised at boot: no audio files.
public class Sfx : MonoBehaviour {
	const int SR = 22050;
	readonly Dictionary<string, AudioClip> bank = new Dictionary<string, AudioClip>();
	readonly List<AudioSource> pool = new List<AudioSource>();
	AudioSource music, drums;
	float drumTarget;
	System.Random rnd = new System.Random(7);
	public float volume = 1f;

	float N() { return (float)(rnd.NextDouble() * 2 - 1); }

	AudioClip Clip(string name, float[] d) {
		float peak = 0.001f;
		foreach (var x in d) peak = Mathf.Max(peak, Mathf.Abs(x));
		if (peak > 0.95f) for (int i = 0; i < d.Length; i++) d[i] *= 0.95f / peak;
		var c = AudioClip.Create(name, d.Length, 1, SR, false);
		c.SetData(d, 0);
		return c;
	}

	void Awake() {
		for (int i = 0; i < 12; i++) pool.Add(gameObject.AddComponent<AudioSource>());
		music = gameObject.AddComponent<AudioSource>();
		drums = gameObject.AddComponent<AudioSource>();
		Build();
	}

	delegate float Gen(float t, float u);   // t seconds, u 0..1

	float[] Make(float dur, Gen g) {
		int n = (int)(dur * SR);
		var d = new float[n];
		for (int i = 0; i < n; i++) d[i] = g(i / (float)SR, i / (float)n);
		return d;
	}

	float[] Pluck(float f, float dur, float damp = 0.996f) {
		int n = (int)(dur * SR);
		int len = Mathf.Max(2, (int)(SR / f));
		var buf = new float[len];
		for (int i = 0; i < len; i++) buf[i] = N();
		var d = new float[n];
		int k = 0;
		for (int i = 0; i < n; i++) {
			d[i] = buf[k];
			int k2 = (k + 1) % len;
			buf[k] = damp * 0.5f * (buf[k] + buf[k2]);
			k = k2;
		}
		return d;
	}

	void Build() {
		float lp = 0;
		bank["slash"] = Clip("slash", Make(0.16f, (t, u) => { lp += (N() - lp) * (0.15f + 0.6f * u); return lp * Mathf.Sin(u * Mathf.PI) * 0.7f; }));
		lp = 0;
		bank["dash"] = Clip("dash", Make(0.24f, (t, u) => { lp += (N() - lp) * (0.35f - 0.25f * u); return lp * Mathf.Sin(u * Mathf.PI) * 0.8f; }));
		bank["hit"] = Clip("hit", Make(0.14f, (t, u) => (Mathf.Sin(2 * Mathf.PI * (170 - 110 * u) * t) * 0.8f + N() * 0.5f * (1 - u)) * Mathf.Exp(-u * 5)));
		bank["hurt"] = Clip("hurt", Make(0.3f, (t, u) => (Mathf.Sin(2 * Mathf.PI * (110 - 60 * u) * t) + N() * 0.35f) * Mathf.Exp(-u * 4) * 0.9f));
		bank["clang"] = Clip("clang", Make(0.7f, (t, u) => (Mathf.Sin(2 * Mathf.PI * 1870 * t) + 0.8f * Mathf.Sin(2 * Mathf.PI * 2530 * t) + 0.6f * Mathf.Sin(2 * Mathf.PI * 3310 * t) + 0.5f * Mathf.Sin(2 * Mathf.PI * 4170 * t) + (u < 0.02f ? N() * 2 : 0)) * Mathf.Exp(-u * 7) * 0.3f));
		bank["block"] = Clip("block", Make(0.25f, (t, u) => (Mathf.Sin(2 * Mathf.PI * 900 * t) + 0.7f * Mathf.Sin(2 * Mathf.PI * 1370 * t) + N() * 0.4f) * Mathf.Exp(-u * 9) * 0.35f));
		bank["gong"] = Clip("gong", Make(1.8f, (t, u) => (Mathf.Sin(2 * Mathf.PI * 110 * t) + 0.7f * Mathf.Sin(2 * Mathf.PI * 163.5f * t) + 0.5f * Mathf.Sin(2 * Mathf.PI * 221 * t) + 0.35f * Mathf.Sin(2 * Mathf.PI * 287 * t) + 0.2f * Mathf.Sin(2 * Mathf.PI * 441 * t)) * Mathf.Exp(-u * 4) * (1 + 0.3f * Mathf.Sin(2 * Mathf.PI * 5 * t)) * 0.3f));
		bank["drum"] = Clip("drum", Make(0.4f, (t, u) => (Mathf.Sin(2 * Mathf.PI * (95 - 45 * u) * t) + N() * 0.25f * Mathf.Exp(-u * 20)) * Mathf.Exp(-u * 5)));
		bank["coin"] = Clip("coin", Make(0.22f, (t, u) => (Mathf.Sin(2 * Mathf.PI * (u < 0.35f ? 1320 : 1760) * t)) * Mathf.Exp(-u * 4) * 0.3f));
		lp = 0;
		bank["burst"] = Clip("burst", Make(0.45f, (t, u) => { lp += (N() - lp) * 0.2f; return (lp * 1.4f + Mathf.Sin(2 * Mathf.PI * 293.7f * t) * 0.3f + Mathf.Sin(2 * Mathf.PI * 440 * t) * 0.25f) * Mathf.Exp(-u * 4); }));
		bank["shoot"] = Clip("shoot", Make(0.12f, (t, u) => (N() * 0.3f + Mathf.Sin(2 * Mathf.PI * (900 - 500 * u) * t) * 0.4f) * (1 - u)));
		bank["pick"] = Clip("pick", Pluck(587.3f, 0.7f));
		bank["ui"] = Clip("ui", Pluck(440f, 0.25f));
		bank["skill"] = Clip("skill", Make(0.6f, (t, u) => (Mathf.Sin(2 * Mathf.PI * (300 + 700 * u) * t) * 0.4f + N() * 0.3f * u) * Mathf.Sin(u * Mathf.PI)));

		// music: a slow plucked pentatonic tune (D minor pentatonic), seamless 19.2 s loop
		float[] scale = { 146.83f, 174.61f, 196f, 220f, 261.63f, 293.66f, 349.23f, 392f, 440f, 523.25f };
		int[] tune = { 5, -1, 3, 4, 5, -1, 7, 5, 4, -1, 3, 1, 2, -1, 0, -1, 5, 7, 8, -1, 7, 5, 4, 3, 5, -1, 4, 2, 3, -1, 0, -1 };
		float beat = 0.6f;
		int total = (int)(tune.Length * beat * SR);
		var m = new float[total];
		for (int i = 0; i < tune.Length; i++) {
			if (tune[i] < 0) continue;
			var p = Pluck(scale[tune[i]], 2.4f, 0.997f);
			int at = (int)(i * beat * SR);
			for (int j = 0; j < p.Length; j++) m[(at + j) % total] += p[j] * 0.35f;
			if (i % 8 == 0) {
				var bass = Pluck(scale[tune[i]] * 0.25f, 3.5f, 0.998f);
				for (int j = 0; j < bass.Length; j++) m[(at + j) % total] += bass[j] * 0.3f;
			}
		}
		music.clip = Clip("music", m);
		music.loop = true;
		music.volume = 0.5f;
		music.Play();

		// battle layer: taiko pattern in step with the tune (4 beats)
		int dn = (int)(beat * 4 * SR);
		var dr = new float[dn];
		float[] hits = { 0, 1, 1.5f, 2, 3, 3.25f, 3.5f };
		float[] acc = { 1, 0.5f, 0.5f, 0.9f, 0.6f, 0.4f, 0.7f };
		for (int h = 0; h < hits.Length; h++) {
			int at = (int)(hits[h] * beat * SR);
			int n = (int)(0.35f * SR);
			for (int j = 0; j < n; j++) {
				float t = j / (float)SR, u = j / (float)n;
				dr[(at + j) % dn] += (Mathf.Sin(2 * Mathf.PI * (88 - 40 * u) * t) + N() * 0.2f * Mathf.Exp(-u * 25)) * Mathf.Exp(-u * 5) * acc[h] * 0.7f;
			}
		}
		drums.clip = Clip("drums", dr);
		drums.loop = true;
		drums.volume = 0;
		drums.Play();
	}

	public void Battle(bool on) { drumTarget = on ? 0.55f : 0; }

	void Update() {
		drums.volume = Mathf.MoveTowards(drums.volume, drumTarget * volume, Time.unscaledDeltaTime * 0.6f);
		music.volume = 0.5f * volume;
	}

	int next;
	public void Play(string name, float vol = 1f, float pitch = 1f) {
		AudioClip c;
		if (!bank.TryGetValue(name, out c)) return;
		var s = pool[next];
		next = (next + 1) % pool.Count;
		s.pitch = pitch * Random.Range(0.94f, 1.06f);
		s.volume = vol * volume;
		s.clip = c;
		s.Play();
	}
}
