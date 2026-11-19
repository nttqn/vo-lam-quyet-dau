extends Node
## Boss Thế Giới balance: AI heroes of every sect vs every boss, one 90 s try.
##   godot --headless --path . -- --wbsim --n=2 --lvls=10,30,60 --ai=0.7
## Prints per level: share of the try's boss HP taken, seconds survived, kills.

func _ready() -> void:
	var n := 2
	var lvls := [10, 20, 30, 45, 60]
	var ai := 0.7
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="): n = int(a.substr(4))
		if a.begins_with("--ai="): ai = float(a.substr(5))
		if a.begins_with("--lvls="):
			lvls = []
			for v in a.substr(7).split(","): lvls.append(int(v))
	var seed_ := 1
	for lvl in lvls:
		var by_boss := {}
		var by_sect := {}
		var tot_r := 0.0
		var tot_s := 0.0
		var kills := 0
		var tot_d := 0.0
		var runs := 0
		for b in WBoss.LIST:
			for sid in Sects.IDS:
				if sid in Sects.HIDDEN:
					continue
				for k in n:
					var r := run(sid, lvl, b, ai, seed_)
					seed_ += 1
					tot_r += r.ratio
					tot_s += r.secs
					tot_d += r.dmg
					kills += 1 if r.kill else 0
					runs += 1
					by_boss[b.id] = by_boss.get(b.id, 0.0) + r.ratio
					by_sect[sid] = by_sect.get(sid, 0.0) + r.ratio
		print("lvl %d: dmg %.0f%% of try HP (%.0f), survived %.0f s, kills %d/%d" % [lvl, 100.0 * tot_r / runs, tot_d / runs, tot_s / runs, kills, runs])
		var per_b := runs / WBoss.LIST.size()
		for id in by_boss:
			print("    boss %-11s %.0f%%" % [id, 100.0 * by_boss[id] / per_b])
		var per_s := runs / by_sect.size()
		for id in by_sect:
			print("    hero %-11s %.0f%%" % [id, 100.0 * by_sect[id] / per_s])
	get_tree().quit()

func run(sid: String, lvl: int, boss: Dictionary, ai: float, seed_: int) -> Dictionary:
	var ps := Npc.side(sid, lvl, "Hero", ai, "", false, seed_)
	var h := Hero.create("Hero", sid)
	h.level = lvl
	var es := WBoss.side(h, boss)
	var fp := FightScene.make_fighter(ps)
	var fe := FightScene.make_fighter(es)
	var sim := FightSim.new(fp, fe, seed_)
	sim.rounds_to_win = 1
	sim.round_frames = WBoss.FIGHT_SECONDS * 60
	sim.timer = sim.round_frames
	var a0 := FightAI.new(fp, ai)
	var a1 := FightAI.new(fe, float(es.ai))
	var guard := 0
	while sim.phase != FightSim.MATCH_END and sim.phase != FightSim.ROUND_END and guard < 60 * 140:
		sim.tick(a0.decide(sim), a1.decide(sim))
		sim.events.clear()
		guard += 1
	var hp_max: float = es.stats.hp_max
	return {"dmg": fp.stats_dealt, "ratio": minf(1.0, fp.stats_dealt / hp_max), "secs": sim.frame / 60.0, "kill": fe.dead}
