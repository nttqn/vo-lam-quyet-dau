extends Node
## -- --forgetest: logic checks for the forge (cường hóa / thăng phẩm / tẩy
## luyện / phân giải), materials and Phó Bản entries, plus the won-run path
## (Flow._dungeon_done) ending on the result screen.

var ok := true

func _check(what: String, cond: bool) -> void:
	print("FORGETEST %s %s" % ["PASS" if cond else "FAIL", what])
	ok = ok and cond

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	Game.slot = 2
	Game.hero = Hero.create("Kiểm Thử", "vo_dang")
	var h := Game.hero
	# materials
	Mats.give(h, {"iron": 5, "star": 2})
	_check("mats add", Mats.count(h, "iron") == 5 and Mats.count(h, "star") == 2)
	_check("mats spend refuses when short", not Mats.spend(h, "iron", 6) and Mats.count(h, "iron") == 5)
	_check("mats spend", Mats.spend(h, "iron", 3) and Mats.count(h, "iron") == 2)
	# +1..+5 always succeed
	var it := Items.drop("weapon", 3, 2)
	_check("Bảo item rolls 2 bonus lines", Array(it.aff).size() == 2 and it.aff[0].k != it.aff[1].k)
	for i in 5:
		Items.enhance(it, false, rng)
	_check("+5 after five safe tries", int(it.plus) == 5)
	# a failure from +7 drops a level, a charm keeps it; luck grows
	it.plus = 9
	it.luck = 0.0
	var fails := 0
	var drops := 0
	for i in 400:
		var c := it.duplicate(true)
		var r := Items.enhance(c, false, rng)
		if not r.ok:
			fails += 1
			if int(c.plus) == 8 and float(c.luck) > 0.0:
				drops += 1
	_check("+9 succeeds about half the time (%d/400 failed)" % fails, fails > 150 and fails < 250)
	_check("failure from +9 drops to +8 with luck", drops == fails)
	var kept := true
	for i in 100:
		var c := it.duplicate(true)
		var r := Items.enhance(c, true, rng)
		if not r.ok and int(c.plus) != 9:
			kept = false
	_check("Hộ Phù keeps the level", kept)
	var lucky := it.duplicate(true)
	lucky.luck = 0.6
	_check("luck adds to the rate", is_equal_approx(Items.rate(lucky), 1.0))
	it.plus = 15
	_check("+15 is the cap", Items.rate(it) == 0.0)
	_check("+15 weapon glows at level 4", Items.glow_level(15) == 4 and Items.glow_level(6) == 0)
	_check("+15 stats = ×2.4", is_equal_approx(Items.plus_mult(15), 2.4))
	# ascend + bonus lines
	var a := Items.drop("armor", 2, 0)
	_check("Phàm has no lines", Array(a.get("aff", [])).is_empty())
	Items.ascend(a)
	_check("ascend: Tinh + 1 line", int(a.rar) == 1 and Array(a.aff).size() == 1)
	var before := Items.score(a)
	for i in 3:
		Items.ascend(a)
	_check("ascend to Truyền Thuyết: 4 distinct lines", int(a.rar) == 4 and Array(a.aff).size() == 4)
	_check("ascend raises the score", Items.score(a) > before)
	Items.ascend(a)
	_check("rarity caps at 4", int(a.rar) == 4)
	var washed := Items.roll_aff(4, rng)
	_check("reroll keeps the line count", washed.size() == 4)
	# old saves get their lines
	var old := {"slot": "hat", "tier": 2, "rar": 3, "plus": 4, "uid": 77}
	var mig := Hero.create("Cũ", "nga_mi")
	mig.bag.append(old)
	mig.erase("mats")
	Hero.migrate(mig)
	_check("migrate: old Thần item gets 3 lines", Array(mig.bag[0].aff).size() == 3)
	_check("migrate: mats added", mig.has("mats"))
	var again := (mig.bag[0].aff as Array).duplicate(true)
	Items.ensure_aff(mig.bag[0])
	_check("ensure_aff is stable", str(again) == str(mig.bag[0].aff))
	# salvage
	var sv := Items.salvage(Items.make("boots", 4, 3, 6))
	_check("salvage gives iron + star", int(sv.mats.iron) > 10 and int(sv.mats.star) == 1 and int(sv.gold) > 0)
	# Phó Bản entries
	h.level = 20
	_check("dungeon: 4 entries a day", Dungeon.left(h) == 4)
	_check("dungeon: diff 1 locked before diff 0 cleared", not Dungeon.unlocked(h, 0, 1))
	Dungeon.record_clear(h, 0, 0)
	_check("dungeon: clear spends an entry and unlocks next", Dungeon.left(h) == 3 and Dungeon.unlocked(h, 0, 1))
	_check("dungeon: diff 2 needs lvl 20", Dungeon.unlocked(h, 0, 1) and not Dungeon.unlocked(h, 0, 3))
	var sw := Flow.sweep_dungeon(0, 0)
	_check("sweep cleared difficulty gives iron", int(sw.mats.get("iron", 0)) >= 8 and Dungeon.left(h) == 2)
	_check("sweep refused above best", Flow.sweep_dungeon(0, 3).is_empty())
	Dungeon.add_ad_entry(h)
	_check("ad entry +1", Dungeon.left(h) == 3)
	var arena := Flow.arena_mats(10, 30)
	_check("arena streak 10: charm+star+wash", int(arena.charm) == 1 and int(arena.star) == 1 and int(arena.wash) == 1)
	# Phó Bản HP carry and the won path
	var p := Dungeon.side(1, 2, 2)
	_check("dungeon boss is a boss", p.boss and int(p.level) == Dungeon.foe_level(2, 2))
	print("FORGETEST %s" % ("ALL PASS" if ok else "SOME FAILED"))
	Mats.add(h, "star", -Mats.count(h, "star"))
	var star0 := Mats.count(h, "star")
	h.dungeon.best = {"ice": 0}
	Flow._dungeon_done(1, 1, 2, {"won": true, "hp_left": 0.4, "max_combo": 5, "seconds": 40, "perfect": false})
	print("FORGETEST %s won run grants Thiên Tinh (%d -> %d)" % ["PASS" if Mats.count(h, "star") > star0 else "FAIL", star0, Mats.count(h, "star")])
	print("FORGETEST %s first clear raises best" % ("PASS" if Dungeon.best(h, 1) == 1 else "FAIL"))
	get_tree().create_timer(3.0).timeout.connect(get_tree().quit)
