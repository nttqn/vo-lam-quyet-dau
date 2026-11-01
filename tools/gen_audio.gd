extends SceneTree
## Synthesises every sound effect and the two music loops into
## res://assets/audio/*.wav.  Run:
##   godot --headless --path . --script res://tools/gen_audio.gd

const SR := 22050
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 42
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/audio"))
	save("hit", hit(0.16, 140.0, 0.9))
	save("hit_heavy", mix([hit(0.32, 80.0, 1.0), noise_burst(0.25, 0.5, 900.0)]))
	save("slash", mix([sweep_noise(0.18, 5000.0, 1800.0, 0.7), hit(0.12, 180.0, 0.5)]))
	save("swing", sweep_noise(0.2, 900.0, 2600.0, 0.35))
	save("block", metal(0.35, [820.0, 1240.0, 1975.0], 0.5))
	save("gong", gong(2.6, 98.0, 0.8))
	save("click", pluck(0.12, 1046.0, 0.35))
	save("ko", mix([gong(2.0, 73.0, 0.8), hit(0.5, 55.0, 1.0)]))
	save("boom", mix([noise_burst(0.7, 0.9, 400.0), hit(0.6, 45.0, 1.0)]))
	save("throw", sweep_noise(0.14, 3000.0, 6000.0, 0.3))
	save("skill", shimmer(0.7, [523.0, 659.0, 784.0, 1046.0], 0.45))
	save("heal", shimmer(0.9, [784.0, 988.0, 1175.0, 1568.0], 0.4))
	save("land", hit(0.22, 70.0, 0.7))
	save("counter", mix([metal(0.4, [1200.0, 1800.0], 0.5), sweep_noise(0.2, 2000.0, 5000.0, 0.3)]))
	save("start", mix([drum(0.5, 0.9), drum_at(0.5, 0.12, 0.8)]))
	save("coin", shimmer(0.4, [1318.0, 1760.0], 0.4))
	save("levelup", arp(1.2, [523.0, 659.0, 784.0, 1046.0, 1318.0], 0.11, 0.45))
	save("win", arp(1.8, [392.0, 440.0, 587.0, 659.0, 784.0], 0.16, 0.5))
	save("lose", arp(1.8, [440.0, 392.0, 330.0, 294.0], 0.28, 0.45))
	save("music_menu", music_menu(), true)
	save("music_fight", music_fight(), true)
	print("audio done")
	quit()

# ------------------------------------------------------------- primitives
func buf(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * SR))
	return b

func env(t: float, a: float, d: float) -> float:
	if t < a:
		return t / a
	return exp(-(t - a) / d)

func hit(sec: float, f0: float, amp: float) -> PackedFloat32Array:
	var b := buf(sec)
	var ph := 0.0
	var lp := 0.0
	for i in b.size():
		var t := float(i) / SR
		var f := f0 * (1.0 + 2.5 * exp(-t * 40.0))
		ph += TAU * f / SR
		var n := rng.randf_range(-1, 1)
		lp += (n - lp) * 0.25
		b[i] = (sin(ph) * 0.8 + lp * exp(-t * 30.0) * 0.9) * env(t, 0.002, sec * 0.3) * amp
	return b

func noise_burst(sec: float, amp: float, cutoff: float) -> PackedFloat32Array:
	var b := buf(sec)
	var lp := 0.0
	var k := clampf(cutoff / SR * 6.0, 0.01, 1.0)
	for i in b.size():
		var t := float(i) / SR
		lp += (rng.randf_range(-1, 1) - lp) * k
		b[i] = lp * env(t, 0.003, sec * 0.35) * amp * 2.0
	return b

func sweep_noise(sec: float, f_a: float, f_b: float, amp: float) -> PackedFloat32Array:
	var b := buf(sec)
	var lp := 0.0
	var lp2 := 0.0
	for i in b.size():
		var t := float(i) / SR
		var f := lerpf(f_a, f_b, t / sec)
		var k := clampf(f / SR * 6.0, 0.01, 1.0)
		var n := rng.randf_range(-1, 1)
		lp += (n - lp) * k
		lp2 += (lp - lp2) * k
		var bp := lp - lp2
		var e := sin(PI * t / sec)
		b[i] = bp * e * e * amp * 3.0
	return b

func metal(sec: float, freqs: Array, amp: float) -> PackedFloat32Array:
	var b := buf(sec)
	for i in b.size():
		var t := float(i) / SR
		var s := 0.0
		for k in freqs.size():
			s += sin(TAU * freqs[k] * t) * exp(-t * (8.0 + k * 4.0))
		b[i] = s / freqs.size() * amp * env(t, 0.001, 1.0) * 1.6 + rng.randf_range(-1, 1) * exp(-t * 80.0) * 0.3
	return b

func gong(sec: float, f0: float, amp: float) -> PackedFloat32Array:
	var b := buf(sec)
	var partials := [1.0, 1.52, 2.0, 2.74, 3.43, 4.17]
	for i in b.size():
		var t := float(i) / SR
		var s := 0.0
		for k in partials.size():
			var f: float = f0 * partials[k] * (1.0 + 0.01 * exp(-t * 3.0))
			s += sin(TAU * f * t + k) * exp(-t * (1.2 + k * 0.6)) / (1.0 + k * 0.5)
		b[i] = s * amp * 0.6 * env(t, 0.004, 9.0)
	return b

func pluck(sec: float, f: float, amp: float) -> PackedFloat32Array:
	# Karplus-Strong string (guzheng-like)
	var b := buf(sec)
	var n := int(SR / f)
	var line := PackedFloat32Array()
	line.resize(n)
	for i in n:
		line[i] = rng.randf_range(-1, 1)
	var idx := 0
	for i in b.size():
		var nxt := (idx + 1) % n
		var v := (line[idx] + line[nxt]) * 0.5 * 0.996
		b[i] = line[idx] * amp
		line[idx] = v
		idx = nxt
	return b

func shimmer(sec: float, freqs: Array, amp: float) -> PackedFloat32Array:
	var b := buf(sec)
	for i in b.size():
		var t := float(i) / SR
		var s := 0.0
		for k in freqs.size():
			var on: float = t - k * 0.05
			if on > 0:
				s += sin(TAU * freqs[k] * t) * exp(-on * 5.0)
		b[i] = s / freqs.size() * amp * 1.5
	return b

func arp(sec: float, notes: Array, step: float, amp: float) -> PackedFloat32Array:
	var b := buf(sec)
	for k in notes.size():
		var p := pluck(minf(1.2, sec - k * step), notes[k], amp)
		var off := int(k * step * SR)
		for i in p.size():
			if off + i < b.size():
				b[off + i] += p[i]
	return b

func drum(sec: float, amp: float) -> PackedFloat32Array:
	return mix([hit(sec, 60.0, amp), noise_burst(sec * 0.4, amp * 0.3, 1500.0)])

func drum_at(sec: float, at: float, amp: float) -> PackedFloat32Array:
	var b := buf(sec)
	var d := drum(sec - at, amp)
	var off := int(at * SR)
	for i in d.size():
		if off + i < b.size():
			b[off + i] = d[i]
	return b

func mix(parts: Array) -> PackedFloat32Array:
	var n := 0
	for p in parts:
		n = maxi(n, p.size())
	var b := PackedFloat32Array()
	b.resize(n)
	for p in parts:
		for i in p.size():
			b[i] += p[i]
	return b

func add_at(dst: PackedFloat32Array, src: PackedFloat32Array, at: float, gain := 1.0) -> void:
	var off := int(at * SR)
	for i in src.size():
		var j := off + i
		if j >= dst.size():
			j -= dst.size()     # wrap so the loop seam stays seamless
		dst[j] += src[i] * gain

# ------------------------------------------------------------- music
const PENTA := [0, 2, 4, 7, 9]

func note_f(root: float, deg: int) -> float:
	var octv := deg / 5 if deg >= 0 else (deg - 4) / 5
	var d := deg - octv * 5
	return root * pow(2.0, octv + PENTA[d] / 12.0)

func music_menu() -> PackedFloat32Array:
	# slow guzheng melody over a drone, 32 beats at 72 bpm
	var beat := 60.0 / 72.0
	var sec := beat * 32
	var b := buf(sec)
	var root := 293.66   # D
	var melody := [0, 2, 3, 4, 3, 2, 1, 0, -1, 0, 2, 4, 5, 4, 3, 2, 3, 4, 6, 5, 4, 3, 2, 1, 0, 1, 2, 1, 0, -1, -2, 0]
	for i in melody.size():
		var p := pluck(beat * 2.2, note_f(root, melody[i]), 0.32)
		add_at(b, p, i * beat)
		if i % 4 == 0:
			add_at(b, pluck(beat * 3.0, note_f(root * 0.5, [0, -2, 0, 1][(i / 4) % 4]), 0.22), i * beat)
		if i % 2 == 1:
			add_at(b, pluck(beat * 1.0, note_f(root * 2.0, melody[i] + 2), 0.08), i * beat + beat * 0.5)
	# soft drone
	for i in b.size():
		var t := float(i) / SR
		b[i] += (sin(TAU * root * 0.5 * t) * 0.05 + sin(TAU * root * 0.75 * t) * 0.03) * (0.7 + 0.3 * sin(TAU * t / sec))
	return _norm(b, 0.6)

func music_fight() -> PackedFloat32Array:
	# driving drums + plucked ostinato, 32 beats at 132 bpm
	var beat := 60.0 / 132.0
	var sec := beat * 32
	var b := buf(sec)
	var root := 220.0   # A
	var kick := hit(0.3, 55.0, 0.8)
	var snare := noise_burst(0.18, 0.45, 2500.0)
	var tom := hit(0.25, 110.0, 0.5)
	for i in 32:
		var t := i * beat
		if i % 4 == 0 or i % 8 == 3:
			add_at(b, kick, t)
		if i % 4 == 2:
			add_at(b, snare, t)
		if i % 8 == 7:
			add_at(b, tom, t + beat * 0.5)
		add_at(b, noise_burst(0.04, 0.12, 7000.0), t + beat * 0.5)
	var ost := [0, 0, 2, 0, 3, 0, 2, 1]
	var bass := [0, 0, -2, -2, 1, 1, -1, -1]
	for i in 64:
		var deg: int = ost[i % 8] + (2 if (i / 16) % 2 == 1 else 0)
		add_at(b, pluck(beat * 0.9, note_f(root, deg), 0.18), i * beat * 0.5)
	for i in 8:
		add_at(b, pluck(beat * 4.0, note_f(root * 0.25, bass[i]), 0.35), i * beat * 4)
	var mel := [4, -9, 5, 4, 3, -9, 2, 3, 4, -9, 6, 5, 4, 3, 2, 0]
	for i in mel.size():
		if mel[i] > -9:
			add_at(b, pluck(beat * 2.0, note_f(root * 2.0, mel[i]), 0.16), i * beat * 2)
	return _norm(b, 0.65)

func _norm(b: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var m := 0.0001
	for v in b:
		m = maxf(m, absf(v))
	var k := peak / m
	for i in b.size():
		b[i] *= k
	return b

# ------------------------------------------------------------- output
func save(name: String, data: PackedFloat32Array, loop := false) -> void:
	var pk := 0.0
	for v in data:
		pk = maxf(pk, absf(v))
	var k := 0.9 / pk if pk > 0.9 else 1.0
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		var s := int(clampf(data[i] * k, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, s)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size()
	w.save_to_wav("res://assets/audio/%s.wav" % name)
