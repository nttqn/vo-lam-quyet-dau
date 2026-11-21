extends SceneTree
## Level 61-80 check: exp road, and AI-vs-AI win rate of an NPC-geared hero
## against the new Phó Bản difficulties and high Tháp floors.
##   godot --headless --path . --script res://tools/cap_check.gd -- --n=12

func _init() -> void:
	var n := 12
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="): n = int(a.substr(4))
	var tot := 0
	for l in range(1, Hero.MAX_LEVEL):
		tot += Hero.exp_need(l)
		if l in [30, 59, 60, 69, 70, 79]:
			var per: int = Dungeon.rewards({}, 0, clampi(int(l / 10) - 0, 0, Dungeon.DIFFS.size() - 1), false, RandomNumberGenerator.new()).exp
			print("lvl %d need %d  (to here %d)  ~%.1f Phó Bản clears per level" % [l, Hero.exp_need(l), tot, float(Hero.exp_need(l)) / per])
	var road := 0
	for l in range(Hero.OLD_CAP, Hero.MAX_LEVEL):
		road += Hero.exp_need(l)
	print("60 -> 80 total exp %d" % road)
	# a hero who sat at the old cap: banked exp carries over, at most BANK_LEVELS levels
	for bank in [0, 2000, 9000, 900000]:
		var h := Hero.create("Cu", "vo_dang")
		Hero.add_exp(h, road)
		h.level = Hero.OLD_CAP
		h.exp = bank
		var d: Dictionary = h
		Hero.carry_bank(d)
		print("old cap + %d banked exp -> level %d, exp %d" % [bank, d.level, d.exp])
	if "--exp-only" in OS.get_cmdline_user_args():
		quit()
		return
	for diff in [5, 6, 7]:
		var lvl := int(Dungeon.DIFFS[diff][1])
		var line := "Phó Bản %-9s hero L%d: " % [Dungeon.DIFFS[diff][0], lvl]
		for i in Dungeon.LIST.size():
			var w := 0
			for k in n:
				var hs := Npc.side(Sects.IDS[k % 5], lvl, "Hero", 0.6, "", false, 11 + k)
				if _match(hs, Dungeon.side(i, diff, Dungeon.FIGHTS - 1), k) == 0:
					w += 1
			line += "%s %d%%  " % [Dungeon.LIST[i].id, w * 100 / n]
		print(line)
	for f in [60, 80, 95]:
		var lvl := mini(Hero.MAX_LEVEL, Tower.level(f))
		var w := 0
		for k in n:
			var hs := Npc.side(Sects.IDS[k % 5], lvl, "Hero", 0.6, "", false, 11 + k)
			if _match(hs, Tower.side(f), k) == 0:
				w += 1
		print("Tháp tầng %d (foe L%d) hero L%d: %d%%" % [f, Tower.level(f), lvl, w * 100 / n])
	quit()

func _fighter(side: Dictionary) -> Fighter:
	var f := Fighter.new()
	f.setup(Sects.get_sect(side.sect), side.stats, side.skills)
	return f

func _match(p: Dictionary, e: Dictionary, seed_: int) -> int:
	var fa := _fighter(p)
	var fb := _fighter(e)
	var sim := FightSim.new(fa, fb, seed_ + 1)
	var ia := FightAI.new(fa, 0.6, seed_ * 3 + 1)
	var ib := FightAI.new(fb, e.ai, seed_ * 7 + 2)
	var frames := 0
	while sim.phase != FightSim.MATCH_END and frames < 60 * 60 * 5:
		sim.tick(ia.decide(sim), ib.decide(sim))
		sim.events.clear()
		frames += 1
	return sim.winner
