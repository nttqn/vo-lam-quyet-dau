extends SceneTree
## Per-move damage breakdown for one sect pair set.

func _init() -> void:
	var lvl := 20
	var n := 6
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lvl="): lvl = int(a.substr(6))
		if a.begins_with("--n="): n = int(a.substr(4))
		if a.begins_with("--sect="): only = a.substr(7)
	var simt = load("res://tools/sim.gd")
	var dmg := {}
	var counts := {}
	var blocked := {}
	var seed_ := 1
	for i in Sects.IDS:
		for j in Sects.IDS:
			if i == j: continue
			if only != "" and i != only and j != only: continue
			for k in n:
				var fa := _make(i, lvl, seed_)
				var fb := _make(j, lvl, seed_ + 99)
				var sim := FightSim.new(fa, fb, seed_)
				var ia := FightAI.new(fa, 0.6, seed_ * 3)
				var ib := FightAI.new(fb, 0.6, seed_ * 7)
				seed_ += 1
				var fr := 0
				while sim.phase != FightSim.MATCH_END and fr < 18000:
					sim.tick(ia.decide(sim), ib.decide(sim))
					for e in sim.events:
						if e.t == "hit":
							var key: String = sim.f[e.by].sect.id + " " + e.move
							dmg[key] = dmg.get(key, 0.0) + e.dmg
							counts[key] = counts.get(key, 0) + 1
						elif e.t == "block":
							var key2: String = sim.f[1 - e.i].sect.id
							blocked[key2] = blocked.get(key2, 0) + 1
					sim.events.clear()
					fr += 1
	var keys := dmg.keys()
	keys.sort()
	for key in keys:
		print("%-40s dmg %7d  hits %4d" % [key, dmg[key], counts[key]])
	print(blocked)
	quit()

func _make(id: String, lvl: int, seed_: int) -> Fighter:
	var s := Sects.get_sect(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var f := Fighter.new()
	var sk := []
	for m in s.skills:
		if m.lvl <= lvl and sk.size() < 3 and not m.get("ult", false):
			sk.append(m)
	if lvl >= 20:
		sk[2] = s.skills[5]
	f.setup(s, Build.stats(lvl, Build.auto_points(lvl, s, rng), s), sk)
	return f
