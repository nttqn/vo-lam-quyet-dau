extends SceneTree
## App Review demo hero: level 60, regions 1-7 of the story + all Ác Mộng cleared,
## all skills at max, +15 legendary gear, plenty of currency and materials,
## so a reviewer signed in to the demo account can open every feature.
## Writes the save JSON; tools/review_demo.mjs signs up the account and
## uploads it as cloud slot 2 (Ô lưu 3).
##   godot --headless --path . --script res://tools/review_demo.gd -- <out.json>

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://review_demo.json"
	var h := Hero.create("Khách Thử", "vo_dang")
	Hero.add_exp(h, 5_000_000)
	var rng := RandomNumberGenerator.new()
	rng.seed = 60
	h.pts = Build.auto_points(int(h.level), Sects.get_sect("vo_dang"), rng)
	h.free_pts = 0
	for i in h.skill_lv.size():
		h.skill_lv[i] = Hero.SKILL_MAX
	Hero._fill_slots(h)
	for slot in Items.SLOTS:
		h.gear[slot] = Items.drop(slot, 7, 4)
		h.gear[slot].plus = 15
	for k in 4:
		h.bag.append(Items.drop(Items.SLOTS[k], 6, 3))
	var story := []
	# story: the 7 regions every build has (the reviewed 1.0.1 shows 42/42; newer
	# builds open region 8 to play); Ác Mộng cleared everywhere
	for r in Journey.REGIONS.size():
		for s in 6:
			if r < 7:
				h.stars[Journey.stage_id(r, s)] = 3
			h.nstars[Journey.stage_id(r, s)] = 3
		for part in (["intro", "boss", "after"] if r < 7 else []):
			story.append("%d_%s" % [r, part])
	h.story = story
	h.tower = {"best": 60}
	h.arena_best = 20
	h.wins = 320
	h.fights = 360
	h.losses = 40
	h.gold = 500000
	h.jade = 5000
	h.mats = {"iron": 500, "star": 100, "wash": 100, "charm": 50}
	for k in ["manh", "nhanh", "doc", "diem"]:
		Books.give(h, k, 3)
	Titles.refresh(h)
	h.title = "giang_ho"
	h["saved_at"] = Time.get_unix_time_from_system()
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(h))
	f.close()
	print("DEMO level=%d power=%d titles=%d -> %s" % [int(h.level), Hero.power(h), h.titles.size(), out])
	quit()
