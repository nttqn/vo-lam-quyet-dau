extends SceneTree
## Edited-save guards: Hero.sanitize, Build.max_power, Build.shadow_ok.
##   godot --headless --path . --script res://tools/cheat_check.gd -- [duel docs json]
## The optional json is {"duel": {key: doc}} (e.g. dumped from Firestore).

func _initialize() -> void:
	var bad := 0
	# 1. edited points: 800 in Thể at level 60 -> all back as free points
	var h := Hero.create("Sua", "cai_bang")
	Hero.add_exp(h, 5_000_000)
	h.level = 60
	h.pts = {"luc": 300, "than": 0, "noi": 300, "the": 800}
	h.free_pts = 999
	h.skill_lv[0] = 99
	h.gear["weapon"] = Items.make("weapon", 9, 7, 60)
	h.gear.weapon["aff"] = [{"k": "atk", "q": 5.0}, {"k": "atk", "q": 1.0}, {"k": "qi", "q": 1}, {"k": "hp", "q": 1}, {"k": "def", "q": 1}, {"k": "crit", "q": 1}, {"k": "zzz", "q": 1}]
	print("before power %d" % Hero.power(h))
	Hero.sanitize(h)
	var tot := 0
	for k in h.pts:
		tot += int(h.pts[k])
	print("after  power %d pts %d free %d skill0 %d weapon t%d r%d +%d aff %d" % [Hero.power(h), tot, h.free_pts, h.skill_lv[0], h.gear.weapon.tier, h.gear.weapon.rar, h.gear.weapon.plus, h.gear.weapon.aff.size()])
	if tot != 0 or int(h.free_pts) != 59 * 4 or int(h.gear.weapon.plus) != 15 or h.gear.weapon.aff.size() != 4:
		bad += 1
		print("FAIL sanitize")
	# 2. an honest save is untouched
	var g := Hero.create("Thuong", "nga_mi")
	Hero.add_exp(g, 200_000)
	g.pts = {"luc": 10, "than": 20, "noi": 30, "the": int(g.level - 1) * 4 - 70}
	g.free_pts = 10
	g.pts.the -= 10
	var before := JSON.stringify(g)
	Hero.sanitize(g)
	if JSON.stringify(g) != before:
		bad += 1
		print("FAIL honest save changed")
	# 3. a perfect real hero at every level stays under max_power: legendary +15
	# in every slot at the highest tier its story progress allows (boss drops,
	# shop, tower and dailies all follow it), maxed skills
	for lv in [1, 2, 5, 8, 10, 12, 15, 20, 25, 28, 30, 40, 60, 80]:
		for sid in Sects.IDS:
			for build in ["luc", "the", "noi", "than"]:
				var p := Hero.create("P", sid)
				p.level = lv
				p.pts = {build: (lv - 1) * 4}
				for slot in Items.SLOTS:
					var it := Items.make(slot, clampi(2 + (lv + 4) / 5, 2, 7), 4, 15)
					it["aff"] = [{"k": "atk", "q": 1.0}, {"k": "qi", "q": 1.0}, {"k": "def", "q": 1.0}, {"k": "en", "q": 1.0}]
					p.gear[slot] = it
				var doc := {"data": JSON.stringify({"level": lv, "stats": Hero.stats(p)}), "power": Hero.power(p)}
				if Hero.power(p) > Build.max_power(lv) or not Build.shadow_ok(doc):
					bad += 1
					print("FAIL perfect L%d %s %s power %d" % [lv, sid, build, Hero.power(p)])
	# 3b. the lv2 hero at 2,664 power seen on the board (2026-11-22) is refused
	if 2664 <= Build.max_power(2):
		bad += 1
		print("FAIL lv2 2664 still listed (cap %d)" % Build.max_power(2))
	# 4. real shadows from the boards
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var o = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
		for k in o.duel:
			var d: Dictionary = o.duel[k]
			print("shadow %-14s power %5d  legit %s" % [d.name, int(d.power), Build.shadow_ok(d)])
	print("cheat_check: %s" % ("OK" if bad == 0 else "%d FAIL" % bad))
	quit()
