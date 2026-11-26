extends SceneTree
## Kỳ Ngộ balance: a hero geared like an NPC of the same level (Npc gear,
## auto points) vs each kind of stranger, one round with its rule, AI vs AI.
##   godot --headless --path . --script res://tools/kn_check.gd -- --n=12 --hai=0.5 --lv=15,35,60

func _init() -> void:
	var n := 12
	var hai := 0.5
	var lvls := [15, 35, 60]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="): n = int(a.substr(4))
		if a.begins_with("--hai="): hai = float(a.substr(6))
		if a.begins_with("--lv="):
			lvls = Array(a.substr(5).split(",")).map(func(x): return int(x))
	for kind in KyNgo.KINDS:
		print("== %s (%s)" % [kind, KyNgo.rule(kind)])
		for lvl in lvls:
			var line := "L%-3d " % lvl
			var tot := 0
			for sid in Sects.IDS:
				var hs := Npc.side(sid, lvl, "Hero", hai, "", false, 11)
				var w := 0
				for k in n:
					var others: Array = Sects.IDS.filter(func(s): return s != sid)
					var es_id: String = others[k % others.size()] if kind != "bao_tang" else ["thieu_lam", "cai_bang"][k % 2]
					var cur := {"kind": kind, "r": 0, "sect": es_id, "slot": k % 5, "seed": 500 + k, "name": "X", "tries": 0}
					var es := KyNgo.side({"level": lvl, "sect": sid}, cur)
					if _match(hs, es, hai, k, KyNgo.rule(kind)) == 0:
						w += 1
				tot += w
				line += "%s %3d%%  " % [sid.substr(0, 6), w * 100 / n]
			print(line + " | all %d%%" % (tot * 100 / (n * Sects.IDS.size())))
	quit()

func _fighter(side: Dictionary) -> Fighter:
	var f := Fighter.new()
	f.setup(Sects.get_sect(side.sect), side.stats, side.skills)
	f.size = float(side.get("size", 1.0))
	return f

func _match(p: Dictionary, e: Dictionary, hai: float, seed_: int, rule: String) -> int:
	var fa := _fighter(p)
	var fb := _fighter(e)
	var sim := FightSim.new(fa, fb, seed_ + 1)
	sim.rounds_to_win = 1
	if rule == "time":
		sim.round_frames = 30 * 60
		sim.timer = sim.round_frames
	var ia := FightAI.new(fa, hai, seed_ * 3 + 1)
	var ib := FightAI.new(fb, e.ai, seed_ * 7 + 2)
	var frames := 0
	while sim.phase != FightSim.MATCH_END and frames < 60 * 60 * 3:
		sim.tick(ia.decide(sim), ib.decide(sim))
		if rule == "regen" and sim.phase == FightSim.FIGHT and not fb.dead:
			fb.hp = minf(fb.st.hp_max, fb.hp + fb.st.hp_max * KyNgo.REGEN / 60.0)
		sim.events.clear()
		frames += 1
	return sim.winner
