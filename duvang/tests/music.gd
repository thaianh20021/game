extends SceneTree
const Sfx = preload("res://src/sfx.gd")
func _init() -> void:
	var ok = true
	for i in 4:
		var t0 = Time.get_ticks_msec()
		var w = Sfx.gen_music(Sfx.TRACKS[i])
		var secs = w.data.size() / 2.0 / w.mix_rate
		var peak = 0
		var loud = 0
		for j in range(0, w.data.size(), 2):
			var v = absi(w.data.decode_s16(j))
			peak = maxi(peak, v)
			if v > 800:
				loud += 1
		print("track %d: %.1f s, peak %d, built in %d ms" % [i, secs, peak, Time.get_ticks_msec() - t0])
		ok = ok and secs > 12.0 and peak > 6000 and peak < 30000 and loud > w.data.size() / 8 and w.loop_mode == AudioStreamWAV.LOOP_FORWARD
	print("RESULT: %s" % ("OK" if ok else "FAILED"))
	quit()
