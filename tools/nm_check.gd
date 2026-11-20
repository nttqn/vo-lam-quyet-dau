extends SceneTree
## Ác Mộng balance: a hero geared like an NPC of the same level (Npc gear,
## auto points) vs the Ác Mộng duels, AI-vs-AI win rate per sect.
##   godot --headless --path . --script res://tools/nm_check.gd -- --n=16 --hai=0.5 --rs=0,3,7

func _init() -> void:
	var n := 16
	var hai := 0.5
	var regions := [0, 3, 7]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="): n = int(a.substr(4))
		if a.begins_with("--hai="): hai = float(a.substr(6))
		if a.begins_with("--rs="):
			regions = Array(a.substr(5).split(",")).map(func(x): return int(x))
	for r in regions:
		print("== region %d (%s)" % [r, Journey.REGIONS[r].name])
		for sid in Sects.IDS:
			var line := "%-10s " % sid
			for s in [0, 2, 5]:
				var lvl := Journey.nm_level(r, s)
				var hs := Npc.side(sid, lvl, "Hero", hai, "", false, 11)
				var es := Journey.nm_side(r, s)
				var w := 0
				for k in n:
					if _match(hs, es, hai, k) == 0:
						w += 1
				line += "s%d(L%d ai%.2f) %3d%%   " % [s + 1, lvl, es.ai, w * 100 / n]
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
