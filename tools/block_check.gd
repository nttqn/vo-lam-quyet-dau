extends SceneTree
## How often the AI blocks a player who just walks in and mashes punch / kick
## (what a new player does). Counts hits vs blocks on the AI, split into the
## first hit of an exchange and the follow-ups.
##   godot --headless --path . --script res://tools/block_check.gd -- --ai=0.1,0.75 --lvl=1

func _init() -> void:
	var ais := [0.1, 0.25, 0.5, 0.75]
	var lvl := 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ai="):
			ais = Array(a.substr(5).split(",")).map(func(x): return float(x))
		if a.begins_with("--lvl="): lvl = int(a.substr(6))
	for btn in ["p", "k"]:
		for ai in ais:
			var tot := {"hit1": 0, "blk1": 0, "hitN": 0, "blkN": 0}
			for sid in Sects.IDS:
				for k in 6:
					var r := _run(sid, ai, lvl, btn, k)
					for key in tot:
						tot[key] += r[key]
			var f1: float = tot.blk1 * 100.0 / maxf(1, tot.hit1 + tot.blk1)
			var fn: float = tot.blkN * 100.0 / maxf(1, tot.hitN + tot.blkN)
			var fa: float = (tot.blk1 + tot.blkN) * 100.0 / maxf(1, tot.hit1 + tot.blk1 + tot.hitN + tot.blkN)
			print("mash %s  ai %.2f  first-hit blocked %4.1f%%  follow-up blocked %4.1f%%  all %4.1f%%  (n=%d)" % [btn, ai, f1, fn, fa, tot.hit1 + tot.blk1 + tot.hitN + tot.blkN])
	quit()

func _fighter(side: Dictionary) -> Fighter:
	var f := Fighter.new()
	f.setup(Sects.get_sect(side.sect), side.stats, side.skills)
	return f

func _run(sid: String, ai: float, lvl: int, btn: String, seed_: int) -> Dictionary:
	var hs := Npc.side(sid, lvl, "Hero", 0.5, "", false, 11)
	var es := Npc.side(Sects.IDS[(Sects.IDS.find(sid) + 1 + seed_) % Sects.IDS.size()], lvl, "Foe", ai, "", false, 7 + seed_)
	var fa := _fighter(hs)
	var fb := _fighter(es)
	var sim := FightSim.new(fa, fb, seed_ + 1)
	var ib := FightAI.new(fb, ai, seed_ * 7 + 2)
	var out := {"hit1": 0, "blk1": 0, "hitN": 0, "blkN": 0}
	var quiet := 99          # frames since the last contact: >40 = a new exchange
	var frames := 0
	while sim.phase != FightSim.MATCH_END and frames < 60 * 60 * 2:
		var inp := {"mx": 0, "up": false, "down": false, "btn": ""}
		var dist := absf(fb.x - fa.x)
		if dist > 1.6:
			inp.mx = fa.facing
		elif frames % 6 == 0:
			inp.btn = btn
		sim.tick(inp, ib.decide(sim))
		quiet += 1
		for e in sim.events:
			if e.get("i", -1) != 1:
				continue
			if e.t == "hit" and e.get("by", -1) == 0:
				out["hit1" if quiet > 40 else "hitN"] += 1
				quiet = 0
			elif e.t == "block":
				out["blk1" if quiet > 40 else "blkN"] += 1
				quiet = 0
		sim.events.clear()
		frames += 1
	return out
