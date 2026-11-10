extends RefCounted
# Procedural sound effects and chiptune loops, synthesized at boot. No audio files.

const RATE = 22050

static var S = {}
static var pool = []
static var pi = 0
static var last = {}
static var music: AudioStreamPlayer
static var cur_track = -1
static var tracks = {}

# name: [duration, freq start, freq end, wave (0 square, 1 saw, 2 sine), volume, noise mix]
const DEFS = {
	"shoot": [0.09, 880.0, 240.0, 0, 0.30, 0.0],
	"shoot_fire": [0.16, 320.0, 90.0, 1, 0.34, 0.5],
	"shoot_ice": [0.12, 1500.0, 700.0, 2, 0.36, 0.1],
	"shoot_bolt": [0.10, 1900.0, 320.0, 0, 0.26, 0.3],
	"shoot_tox": [0.14, 250.0, 430.0, 2, 0.36, 0.2],
	"slash": [0.12, 700.0, 150.0, 2, 0.34, 0.85],
	"hit": [0.06, 230.0, 110.0, 0, 0.30, 0.4],
	"die": [0.22, 320.0, 50.0, 1, 0.40, 0.5],
	"hurt": [0.28, 190.0, 60.0, 0, 0.55, 0.3],
	"coin": [0.08, 1300.0, 1900.0, 0, 0.20, 0.0],
	"orb": [0.08, 700.0, 1250.0, 2, 0.28, 0.0],
	"dash": [0.14, 500.0, 950.0, 2, 0.22, 0.9],
	"boom": [0.45, 130.0, 30.0, 2, 0.75, 0.7],
	"react": [0.30, 520.0, 1560.0, 0, 0.34, 0.1],
	"freeze": [0.22, 2100.0, 900.0, 2, 0.36, 0.3],
	"door": [0.30, 95.0, 60.0, 0, 0.36, 0.2],
	"chest": [0.30, 500.0, 1000.0, 2, 0.36, 0.0],
	"ui": [0.05, 900.0, 900.0, 0, 0.16, 0.0],
	"pick": [0.15, 600.0, 1200.0, 0, 0.26, 0.0],
	"portal": [0.60, 200.0, 800.0, 2, 0.36, 0.1],
	"skill": [0.35, 300.0, 1100.0, 1, 0.34, 0.2],
	"warn": [0.12, 1000.0, 1000.0, 0, 0.16, 0.0],
	"roar": [0.70, 115.0, 50.0, 1, 0.60, 0.4],
	"deny": [0.12, 160.0, 120.0, 0, 0.26, 0.0],
}

static func init(host: Node) -> void:
	pool.clear()
	for i in 12:
		var a = AudioStreamPlayer.new()
		host.add_child(a)
		pool.append(a)
	music = AudioStreamPlayer.new()
	music.volume_db = -15.0
	host.add_child(music)
	if S.is_empty():
		for k in DEFS:
			S[k] = synth(DEFS[k])

static func synth(a: Array) -> AudioStreamWAV:
	var n = int(a[0] * RATE)
	var data = PackedByteArray()
	data.resize(n * 2)
	var ph = 0.0
	var rs = 22222
	for i in n:
		var t = float(i) / n
		ph += lerpf(a[1], a[2], t) / RATE
		var fr = ph - floorf(ph)
		var v = 0.0
		match a[3]:
			0: v = 1.0 if fr < 0.5 else -1.0
			1: v = fr * 2.0 - 1.0
			2: v = sin(ph * TAU)
		if a[5] > 0.0:
			rs = (rs * 1103515245 + 12345) & 0x7fffffff
			v = lerpf(v, rs / 1073741824.0 - 1.0, a[5])
		var env = (1.0 - t) * (1.0 - t) * minf(1.0, i / 40.0)
		data.encode_s16(i * 2, int(clampf(v * env * a[4], -1.0, 1.0) * 32000.0))
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w

static func play(name: String, pitch: float = 1.0, db: float = 0.0) -> void:
	if not S.has(name) or pool.is_empty():
		return
	var now = Time.get_ticks_msec()
	if now - int(last.get(name, -1000)) < 45:
		return
	last[name] = now
	var a: AudioStreamPlayer = pool[pi]
	pi = (pi + 1) % pool.size()
	a.stream = S[name]
	a.pitch_scale = pitch * randf_range(0.93, 1.07)
	a.volume_db = db - 7.0
	a.play()

# track: 0..2 biomes, 3 boss, 4 title
static func play_music(track: int) -> void:
	if track == cur_track or music == null:
		return
	cur_track = track
	if not tracks.has(track):
		tracks[track] = gen_music(track)
	music.stream = tracks[track]
	music.play()

static func gen_music(track: int) -> AudioStreamWAV:
	var R = 11025.0
	var bpm = [92.0, 104.0, 98.0, 138.0, 78.0][track]
	var root = [45, 43, 47, 45, 50][track]
	var prog = [[0, 3], [-4, 4], [3, 4], [-2, 4]]
	if track == 3:
		prog = [[0, 3], [0, 3], [1, 4], [-2, 4]]
	if track == 2:
		prog = [[0, 3], [5, 3], [-4, 4], [-2, 4]]
	var brh = [1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0]
	var apat = [0, 1, 2, 3, 2, 1, 2, 3, 0, 2, 1, 3, 2, 3, 1, 2]
	var kick_every = 4 if track == 3 else 8
	var sps = 60.0 / bpm / 4.0
	var per = int(sps * R)
	var steps = 128
	var data = PackedByteArray()
	data.resize(steps * per * 2)
	var pb = 0.0
	var pa = 0.0
	var rs = 4242
	for step in steps:
		var ch = prog[(step / 16) % 4]
		var tones = [0, ch[1], 7, 12]
		var s16 = step % 16
		var bf = 440.0 * pow(2.0, (root - 12 + ch[0] - 69) / 12.0) / R
		var an = root + 12 + ch[0] + tones[apat[s16]] + (12 if (step >= 64 and s16 % 2 == 0) else 0)
		var af = 440.0 * pow(2.0, (an - 69) / 12.0) / R
		var bass_hit = float(brh[s16])
		var hat = s16 % 4 == 2
		var kick = step % kick_every == 0
		var arp_vol = 0.085 if track != 4 else 0.06
		for i in per:
			var fr = float(i) / per
			pb += bf
			pa += af
			var v = (absf((pb - floorf(pb)) * 4.0 - 2.0) - 1.0) * 0.30 * (0.35 + 0.65 * bass_hit * (1.0 - fr))
			v += (arp_vol if (pa - floorf(pa)) < 0.25 else -arp_vol) * (1.0 - fr * 0.8)
			if hat and fr < 0.3:
				rs = (rs * 1103515245 + 12345) & 0x7fffffff
				v += (rs / 1073741824.0 - 1.0) * 0.06 * (1.0 - fr / 0.3)
			if kick:
				var tk = fr * sps
				v += sin(TAU * (42.0 * tk + 2.4 * (1.0 - exp(-30.0 * tk)))) * exp(-tk * 13.0) * 0.42
			data.encode_s16((step * per + i) * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = int(R)
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = steps * per
	return w
