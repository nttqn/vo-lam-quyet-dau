extends SceneTree
## Headless AI-vs-AI balance runner:
##   godot --headless --path . --script res://tools/sim.gd -- --n=20 --lvl=10

func _init() -> void:
	var n := 10
	var lvl := 10
	var ai_a := 0.6
	var ai_b := 0.6
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="): n = int(a.substr(4))
		if a.begins_with("--lvl="): lvl = int(a.substr(6))
		if a.begins_with("--ai="): ai_a = float(a.substr(5)); ai_b = ai_a
	var ids: Array = Sects.IDS
	var table := {}
	var total_frames := 0
	var matches := 0
	var seed_ := 1
	for i in ids:
		for j in ids:
			if i == j: continue
			var w := 0
			for k in n:
				var res := run_match(i, j, lvl, ai_a, ai_b, seed_)
				seed_ += 1
				if res.winner == 0: w += 1
				total_frames += res.frames
				matches += 1
			table[i + " vs " + j] = w
	var score := {}
	for id in ids: score[id] = 0
	for key in table:
		var p: PackedStringArray = key.split(" vs ")
		score[p[0]] += table[key]
		score[p[1]] += n - table[key]
	print("avg match seconds: %.1f" % (total_frames / 60.0 / matches))
	for k in counts:
		print("%s per match: %.2f" % [k, float(counts[k]) / matches])
	for id in ids:
		print("%-10s win%% %.0f" % [id, 100.0 * score[id] / (n * 2 * (ids.size() - 1))])
	for key in table:
		print("  %s : %d/%d" % [key, table[key], n])
	quit()

func make(id: String, lvl: int, seed_: int) -> Fighter:
	var s := Sects.get_sect(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var f := Fighter.new()
	var sk := []
	if "--noskill" in OS.get_cmdline_user_args():
		sk = [null, null, null]
		f.setup(s, Build.stats(lvl, Build.auto_points(lvl, s, rng), s), sk)
		return f
	for m in s.skills:
		if m.lvl <= lvl and sk.size() < 3 and not m.get("ult", false):
			sk.append(m)
	if lvl >= 20:
		sk[2] = s.skills[5]
	f.setup(s, Build.stats(lvl, Build.auto_points(lvl, s, rng), s), sk)
	f.name = s.name
	return f

var counts := {}

func run_match(a: String, b: String, lvl: int, la: float, lb: float, seed_: int) -> Dictionary:
	var fa := make(a, lvl, seed_)
	var fb := make(b, lvl, seed_ + 1000)
	var sim := FightSim.new(fa, fb, seed_)
	var ia := FightAI.new(fa, la, seed_ * 3)
	var ib := FightAI.new(fb, lb, seed_ * 7)
	var frames := 0
	while sim.phase != FightSim.MATCH_END and frames < 60 * 60 * 5:
		sim.tick(ia.decide(sim), ib.decide(sim))
		for e in sim.events:
			if e.t in ["seal", "insight", "cleanse"]:
				counts[e.t] = int(counts.get(e.t, 0)) + 1
		sim.events.clear()
		frames += 1
	return {"winner": sim.winner, "frames": frames}
