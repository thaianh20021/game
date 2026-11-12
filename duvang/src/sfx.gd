extends RefCounted
# Sound effects and four music loops, all synthesized. No audio files.

const RATE = 22050

# name: [duration, freq start, freq end, wave (0 square, 1 saw, 2 sine), volume, noise mix]
const DEFS = {
	"sw1": [0.10, 520.0, 260.0, 2, 0.22, 0.85],
	"sw3": [0.16, 420.0, 140.0, 2, 0.30, 0.9],
	"spin": [0.30, 300.0, 700.0, 2, 0.30, 0.9],
	"hit": [0.07, 240.0, 100.0, 0, 0.30, 0.45],
	"heavy": [0.14, 150.0, 55.0, 1, 0.45, 0.55],
	"break": [0.20, 900.0, 200.0, 1, 0.32, 0.4],
	"dash": [0.14, 500.0, 950.0, 2, 0.20, 0.9],
	"hurt": [0.26, 190.0, 60.0, 0, 0.50, 0.3],
	"die": [0.25, 500.0, 90.0, 2, 0.34, 0.5],
	"tele_lo": [0.34, 150.0, 230.0, 0, 0.16, 0.0],
	"tele_mid": [0.22, 420.0, 620.0, 0, 0.13, 0.0],
	"tele_hi": [0.28, 900.0, 1400.0, 2, 0.16, 0.0],
	"slam": [0.40, 120.0, 30.0, 2, 0.70, 0.7],
	"spit": [0.10, 1200.0, 500.0, 2, 0.24, 0.3],
	"orb": [0.08, 700.0, 1250.0, 2, 0.20, 0.0],
	"clap": [0.07, 300.0, 180.0, 0, 0.40, 0.3],
	"deny": [0.12, 160.0, 120.0, 0, 0.22, 0.0],
	"parry": [0.09, 1800.0, 1200.0, 0, 0.20, 0.1],
}

static var S = {}
static var pool = []
static var pi = 0
static var last = {}
static var vol_sfx = 1.0
static var vol_music = 1.0

static func set_volume(sfx: float, mus: float) -> void:
	vol_sfx = sfx
	vol_music = mus
	if music != null and is_instance_valid(music):
		music.volume_db = MUSIC_DB + linear_to_db(maxf(mus, 0.0001))

static func init(host: Node) -> void:
	pool.clear()
	for i in 12:
		var a = AudioStreamPlayer.new()
		host.add_child(a)
		pool.append(a)
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
	if not S.has(name) or pool.is_empty() or vol_sfx <= 0.0:
		return
	var now = Time.get_ticks_msec()
	if now - int(last.get(name, -1000)) < 40:
		return
	last[name] = now
	var a: AudioStreamPlayer = pool[pi]
	pi = (pi + 1) % pool.size()
	a.stream = S[name]
	a.pitch_scale = pitch * randf_range(0.95, 1.05)
	a.volume_db = db - 7.0 + linear_to_db(vol_sfx)
	a.play()

# ---------------------------------------------------------------- music
# Four loops synthesized on first use: town, marsh, dungeon, boss.
# [bpm, root note, chord steps, bass rhythm, kick every n steps, wood click, arp volume, arp octave lift]
const TRACKS = [
	[84.0, 50, [[0, 4], [5, 4], [-3, 3], [-5, 4]], [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0], 0, true, 0.07, 12],
	[96.0, 45, [[0, 3], [-4, 4], [3, 4], [-2, 4]], [1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0], 8, false, 0.075, 12],
	[72.0, 41, [[0, 3], [0, 3], [1, 3], [-2, 3]], [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0], 16, false, 0.05, 0],
	[138.0, 43, [[0, 3], [0, 3], [1, 4], [-2, 4]], [1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0], 4, false, 0.085, 12],
	[88.0, 47, [[0, 3], [3, 4], [-2, 3], [5, 4]], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0], 0, true, 0.065, 12],
]
const MUSIC_DB = -17.0

static var music: AudioStreamPlayer
static var cur_track = -1
static var tracks = {}

static var builder: Thread
static var stop_build = false

# Tracks take seconds to synthesize, so they are built on a thread started at boot.
# Until a track is ready play_music does nothing; the game asks again every frame.
static func build_tracks() -> void:
	for i in TRACKS.size():
		if stop_build:
			return
		var w = gen_music(TRACKS[i])
		if w != null:
			tracks[i] = w

static func start_music() -> void:
	if builder == null and tracks.size() < TRACKS.size():
		stop_build = false
		builder = Thread.new()
		builder.start(build_tracks)

# call before the program ends: a running thread must be joined
static func stop_music() -> void:
	stop_build = true
	if builder != null and builder.is_started():
		builder.wait_to_finish()
	builder = null
	cur_track = -1

static func play_music(track: int) -> void:
	if track == cur_track or pool.is_empty() or not tracks.has(track):
		return
	cur_track = track
	if music == null or not is_instance_valid(music):
		music = AudioStreamPlayer.new()
		music.volume_db = MUSIC_DB + linear_to_db(maxf(vol_music, 0.0001))
		pool[0].get_parent().add_child(music)
	music.stream = tracks[track]
	music.play()

static func gen_music(T: Array) -> AudioStreamWAV:
	var R = 11025.0
	var prog = T[2]
	var apat = [0, 1, 2, 3, 2, 1, 2, 3, 0, 2, 1, 3, 2, 3, 1, 2]
	var sps = 60.0 / T[0] / 4.0
	var per = int(sps * R)
	var steps = 128
	var data = PackedByteArray()
	data.resize(steps * per * 2)
	var pb = 0.0
	var pa = 0.0
	var rs = 4242
	for step in steps:
		if stop_build:
			return null
		var ch = prog[(step / 16) % 4]
		var tones = [0, ch[1], 7, 12]
		var s16 = step % 16
		var bf = 440.0 * pow(2.0, (T[1] - 12 + ch[0] - 69) / 12.0) / R
		var an = T[1] + T[7] + ch[0] + tones[apat[s16]] + (12 if (step >= 64 and s16 % 2 == 0) else 0)
		var af = 440.0 * pow(2.0, (an - 69) / 12.0) / R
		var bass_hit = float(T[3][s16])
		var hat = s16 % 4 == 2
		var kick = T[4] > 0 and step % T[4] == 0
		var arp_on = T[4] != 16 or s16 % 4 == 0   # the dungeon plays one note in four
		for i in per:
			var fr = float(i) / per
			pb += bf
			pa += af
			var v = (absf((pb - floorf(pb)) * 4.0 - 2.0) - 1.0) * 0.30 * (0.35 + 0.65 * bass_hit * (1.0 - fr))
			if arp_on:
				v += (T[6] if (pa - floorf(pa)) < 0.25 else -T[6]) * (1.0 - fr * 0.8)
			if hat and fr < 0.3:
				rs = (rs * 1103515245 + 12345) & 0x7fffffff
				if T[5]:
					# a wooden clapper: a short pitched knock instead of a hiss
					v += sin(TAU * 900.0 * fr * sps) * 0.16 * (1.0 - fr / 0.3) * (1.0 - fr / 0.3)
				else:
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
