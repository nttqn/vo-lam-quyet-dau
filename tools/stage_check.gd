extends SceneTree
## Fresh hero vs the first region's duels: stats + AI-vs-AI win rate.
##   godot --headless --path . --script res://tools/stage_check.gd -- --n=20 --hai=0.35 --r=0

func _init() -> void:
	var n := 20
	var hai := 0.35       # stand-in for a new human player on a touch screen
	var r := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="): n = int(a.substr(4))
		if a.begins_with("--hai="): hai = float(a.substr(6))
		if a.begins_with("--r="): r = int(a.substr(4))
	for sid in Sects.IDS:
		var h := Hero.create("Test", sid)
		var hs := Hero.side(h)
		var line := "%-10s hp %d atk %d def %d | " % [sid, hs.stats.hp_max, hs.stats.get("atk", 0), hs.stats.get("def", 0)]
		for s in 6:
			# hero as it would be after first-clearing the previous stages
			if s > 0:
				Hero.add_exp(h, Journey.rewards(r, s - 1, true, 2).exp)
				var rng := RandomNumberGenerator.new()
				rng.seed = 7
				h.pts = Build.auto_points(int(h.level), Sects.get_sect(sid), rng)
				hs = Hero.side(h)
			var es := Journey.stage_side(r, s)
			var w := 0
			for k in n:
				if _match(hs, es, hai, k) == 0:
					w += 1
			line += "s%d(%d hp%d ai%.2f) %d%%  " % [s + 1, es.level, es.stats.hp_max, es.ai, w * 100 / n]
		print(line)
	quit()

func _fighter(side: Dictionary) -> Fighter:
	var f := Fighter.new()
	f.setup(Sects.get_sect(side.sect), side.stats, side.skills)
	return f

func _match(p: Dictionary, e: Dictionary, hai: float, seed_: int) -> int:
	var fa := _fighter(p)
	var fb := _fighter(e)
	var sim := FightSim.new(fa, fb, seed_ + 1)
	var ia := FightAI.new(fa, hai, seed_ * 3 + 1)
	var ib := FightAI.new(fb, e.ai, seed_ * 7 + 2)
	var frames := 0
	while sim.phase != FightSim.MATCH_END and frames < 60 * 60 * 5:
		sim.tick(ia.decide(sim), ib.decide(sim))
		sim.events.clear()
		frames += 1
	return sim.winner
