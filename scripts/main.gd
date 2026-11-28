extends Node
## Entry point. Test flags (after "--"):
##   --posetest, --fighttest [--p=sect --e=sect --theme=x --skills=1,3,5 --fullen]
##   --screen=title|create|hub|map|char|skill|gear|shop|result  --shot=path --delay=frames

var _shot := ""
var _delay := 30
var _n := 0

func _ready() -> void:
	if Diag.on("empty"):
		return   # blank scene: is the leak in the engine itself?
	var args := OS.get_cmdline_user_args()
	var screen := ""
	for a in args:
		if a.begins_with("--shot="): _shot = a.substr(7)
		if a == "--unlockall":
			for hid in Sects.HIDDEN:
				Game.settings["unlock_" + hid] = true
		if a.begins_with("--delay="): _delay = int(a.substr(8))
		if a == "--nomusic": Game.settings["music"] = 0.0   # promo capture: music added later
		if a == "--rankhidden": Game.settings["rank_hidden"] = true   # not saved
		if a == "--banned":   # khóa tài khoản look (not saved); --banned --until=days
			Game.settings["ban"] = {"why": "Sửa dữ liệu nhân vật", "until": 0}
		if a.begins_with("--until=") and Game.settings.has("ban"):
			Game.settings.ban.until = int(Time.get_unix_time_from_system()) + int(a.substr(8)) * 86400
		if a.begins_with("--gfx="):
			Gfx.set_level(int(a.substr(6)))
			Gfx.apply(get_tree())
		if a.begins_with("--screen="): screen = a.substr(9)
		if a.begins_with("--wb="): WBoss.test_pick = int(a.substr(5))
		if a.begins_with("--lang="): L.use(a.substr(7))   # not saved
	for a in args:
		if a.begins_with("--facetest"):
			add_child(load("res://tools/face_test.gd").new())
			return
		if a.begins_with("--clipsheet"):
			add_child(load("res://tools/clip_sheet.gd").new())
			return
		if a.begins_with("--modeltest"):
			add_child(load("res://tools/model_test.gd").new())
			return
		if a.begins_with("--iconshot"):
			add_child(load("res://tools/icon_shot.gd").new())
			return
		if a == "--skillshots":
			add_child(load("res://tools/skill_shots.gd").new())
			return
		if a == "--feetprobe":
			add_child(load("res://tools/feet_probe.gd").new())
			return
		if a == "--forgetest":
			add_child(load("res://tools/forge_test.gd").new())
			return
		if a == "--memmodels":
			add_child(load("res://tools/mem_models.gd").new())
			return
		if a == "--soak":
			add_child(load("res://tools/soak.gd").new())
			return
		if a == "--iaptest":
			add_child(load("res://tools/iap_test.gd").new())
			return
		if a == "--wbsim":
			add_child(load("res://tools/wboss_sim.gd").new())
			return
		if a == "--notifycheck":
			add_child(load("res://tools/notify_check.gd").new())
			return
		if a == "--chattest":
			add_child(load("res://tools/chat_test.gd").new())
			return
		if a == "--cloudtest" and screen == "":
			add_child(load("res://tools/cloud_test.gd").new())
			return
		if a.begins_with("--posetest"):
			add_child(load("res://tools/pose_test.gd").new())
			return
		if a.begins_with("--fighttest"):
			_shot = ""
			var ps := "vo_dang"
			var es := "cai_bang"
			var th := "temple"
			for b in args:
				if b.begins_with("--p="): ps = b.substr(4)
			var pn := "Thử Nghiệm"
			var en := "Đối Thủ"
			for b in args:
				if b.begins_with("--pname="): pn = b.substr(8)
				if b.begins_with("--ename="): en = b.substr(8)
				if b.begins_with("--e="): es = b.substr(4)
				if b.begins_with("--theme="): th = b.substr(8)
			var p := Npc.side(ps, 20, pn, 0.7, "", false, 5)
			for b in args:
				if b.begins_with("--wglow="): p.look["wglow"] = int(b.substr(8))
				if b.begins_with("--model="): p.look["model"] = b.substr(8)   # any assets/models/chars file
				if b.begins_with("--outfit="):
					p.look["model"] = Outfits.model_for(ps, b.substr(9))
			p.skills = [Sects.get_sect(ps).skills[0], Sects.get_sect(ps).skills[2], Sects.get_sect(ps).skills[3], Sects.get_sect(ps).skills[5]]
			for b in args:
				if b.begins_with("--skills="):   # e.g. --skills=1,3,5 (sect skill slots 0-5)
					p.skills = []
					for si in b.substr(9).split(","): p.skills.append(Sects.get_sect(ps).skills[int(si)])
			var e := Npc.side(es, 20, en, 0.7, "bandit", true, 9)
			var rounds := 2
			for b in args:
				if b.begins_with("--ehp="): e.stats.hp_max *= float(b.substr(6))   # quick KO for finisher shots
				if b.begins_with("--rounds="): rounds = int(b.substr(9))
			if "--nm" in args:   # Ác Mộng look: violet tint + title
				e.look["tint"] = Journey.NM_TINT
				e.title = "Ác Mộng · Nguyệt Ảnh Cốc"
			var fcfg := {"p": p, "e": e, "theme": th, "autoplay": true, "seed": 3, "rounds": rounds}
			if "--boss" in args:   # Boss Thế Giới giant (pick with --wb=i)
				var bh := Hero.create("Thử", ps)
				bh.level = 20
				fcfg.e = WBoss.side(bh)
				fcfg.theme = WBoss.today_boss().theme
				fcfg.rounds = 1
				fcfg["time"] = WBoss.FIGHT_SECONDS
				fcfg["wboss"] = true
			if "--tutorial" in args:   # trận nhập môn overlay (lessons time out after 2.5 s under autoplay)
				fcfg["tutorial"] = true
				fcfg.rounds = 1
			var fs := FightScene.new(fcfg)
			Game.goto(fs)
			return
	if "--backtest" in args:
		_back_test()
		return
	if "--clocktest" in args:
		_clock_test()
		return
	if "--replaytest" in args:
		_replay_test(0, 0)
		return
	if "--flowtest" in args:
		Game.autoplay = true
		Game.slot = 2
		Game.hero = Hero.create("Kiểm Thử", "nga_mi")
		Game.hero.skill_mod = ["doc", "", "", "", "", ""]
		var tw := -1
		for a in args:
			if a.begins_with("--tower="): tw = int(a.substr(8))
		var dgn := ""
		for a in args:
			if a.begins_with("--dungeon="): dgn = a.substr(10)   # --dungeon=i,diff,k
		if dgn != "":
			var p := dgn.split(",")
			Hero.add_exp(Game.hero, 4000)
			Flow.start_dungeon(int(p[0]), int(p[1]), int(p[2]) if p.size() > 2 else 0, 0.7)
		elif "--wboss" in args:
			Hero.add_exp(Game.hero, 4000)
			Flow.start_wboss()
		elif "--duel" in args:
			Flow.start_duel(Duel.bots(Game.hero, 1)[0])
		elif _arg(args, "--kyngo=") != "":   # --kyngo=cao_nhan|bi_kip|bao_tang|ma_dau
			Hero.add_exp(Game.hero, 20000)
			Game.hero.stars["0_5"] = 3
			var kc := KyNgo.spawn(Game.hero, _arg(args, "--kyngo="))
			if "--fakewin" in args:   # the win path without a fight
				Flow._kyngo_done(kc, {"won": true, "max_combo": 5, "seconds": 30.0, "hp_left": 0.5, "insight": {}})
			else:
				Flow.start_kyngo()
		elif tw > 0:
			Flow.start_tower(tw)
		elif _arg(args, "--nm=") != "" or _arg(args, "--stage=") != "":
			# --nm=r,s Ác Mộng duel / --stage=r,s story duel, hero lvl 45 with the story cleared
			Hero.add_exp(Game.hero, 600000)
			for r in Journey.REGIONS.size():
				for s2 in 6:
					if _arg(args, "--nm=") != "" or r < 7:
						Game.hero.stars[Journey.stage_id(r, s2)] = 3
			var nm := _arg(args, "--nm=") != ""
			var rs := (_arg(args, "--nm=") if nm else _arg(args, "--stage=")).split(",")
			Flow.start_any(int(rs[0]), int(rs[1]), nm)
		elif "--spar" in args:
			Hero.add_exp(Game.hero, 20000)
			var other := Hero.create("Bóng Thử", "cai_bang")
			Hero.add_exp(other, 20000)
			Flow.start_spar(Duel.side(Duel.fields(other)), func():
				print("SPAR back ok")
				Game.goto(HubScreen.new()))
		else:
			Flow.start_stage(0, 0)
		return
	if screen != "":
		_demo_screen(screen, args)
		return
	Game.goto(TitleScreen.new())

## -- --backtest: the Android back key (KEY_BACK, as Godot delivers it) leaves a
## sub-screen, closes a modal before the screen, and pauses / resumes a fight.
func _back_test() -> void:
	Game.slot = 2
	Game.hero = Hero.create("Kiểm Thử", "vo_dang")
	var ok := true
	Game.goto(GearScreen.new(false))
	await get_tree().process_frame
	await _press_back()
	ok = _check("gear -> hub", Game._current is HubScreen) and ok
	var hub: Screen = Game._current
	var sp := SettingsPanel.new()
	hub.ui.add_child(sp)
	await get_tree().process_frame
	await _press_back()
	ok = _check("back closes settings first", not is_instance_valid(sp) and Game._current == hub) and ok
	Game.autoplay = true   # skip the story dialogue
	Flow.start_stage(0, 0)
	await get_tree().create_timer(0.5).timeout
	var fs := Game._current as FightScene
	await _press_back()
	ok = _check("fight pauses", fs != null and fs.paused) and ok
	await _press_back()
	ok = _check("fight resumes", fs != null and not fs.paused) and ok
	Game._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	ok = _check("predictive back pauses", fs != null and fs.paused) and ok
	# interruptions (call, lock screen): focus loss, or a frozen app with no notification at all
	fs.toggle_pause()
	fs.ai_p = null
	fs._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await get_tree().process_frame
	await get_tree().process_frame
	ok = _check("focus loss pauses with the menu", fs.paused and fs._pause_layer != null) and ok
	fs.toggle_pause()
	fs._frame_ms -= 3000
	await get_tree().process_frame
	await get_tree().process_frame
	ok = _check("frozen app pauses with the menu", fs.paused and fs._pause_layer != null) and ok
	await _real_wait(450)
	# one press delivered twice (key + WM) must act once: hub -> title, not quit
	Game.goto(HubScreen.new())
	await get_tree().process_frame
	await _press_back(true)
	ok = _check("double-delivered back: hub -> title only", Game._current is TitleScreen) and ok
	await _press_back()
	ok = _check("single back on title only warns", Game._current is TitleScreen and not get_tree().paused) and ok
	print("BACKTEST ", "ALL PASS" if ok else "FAILED")
	get_tree().quit(0 if ok else 1)

## twice: the same press also arrives as WM_GO_BACK_REQUEST right after the key.
func _press_back(twice := false) -> void:
	for down in [true, false]:
		var k := InputEventKey.new()
		k.keycode = KEY_BACK
		k.pressed = down
		Input.parse_input_event(k)
	await get_tree().process_frame
	if twice:
		Game._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await _real_wait(450)

## Headless timers run on game time; the back debounce uses wall-clock ticks.
func _real_wait(ms: int) -> void:
	var end := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < end:
		await get_tree().process_frame

func _check(what: String, cond: bool) -> bool:
	print("BACKTEST %s %s" % ["PASS" if cond else "FAIL", what])
	return cond

func _demo_screen(screen: String, args: PackedStringArray) -> void:
	var sect := "thieu_lam"
	for a in args:
		if a.begins_with("--sect="): sect = a.substr(7)
	Game.slot = 2
	Game.hero = Hero.create("Lăng Phong", sect)
	Hero.add_exp(Game.hero, 4000)
	Game.hero.gold = 5400
	Game.hero.jade = 32
	for s in 9:
		Game.hero.stars[Journey.stage_id(s / 6, s % 6)] = 1 + s % 3
	Game.hero.bag.append(Items.make("hat", 2, 2, 0))
	Game.hero.bag.append(Items.make("jade", 2, 1, 3))
	match screen:
		"title": Game.goto(TitleScreen.new())
		"account":
			var ts := TitleScreen.new()
			Game.goto(ts)
			(func(): ts.ui.add_child(AccountPanel.new())).call_deferred()
		"create": Game.goto(CreateScreen.new(0))
		"create2":
			var cs := CreateScreen.new(0)
			Game.goto(cs)
			cs._pick.call_deferred(sect if sect != "thieu_lam" else "nga_mi")
		"hub":
			if "--notoast" in args:
				Titles.refresh(Game.hero)   # store shots: no "new title" toast
			var hub := HubScreen.new()
			Game.goto(hub)
			if "--turntest" in args:
				_turn_test.call_deferred(hub)
		"settings":
			var hs := HubScreen.new()
			Game.goto(hs)
			hs.ui.add_child.call_deferred(SettingsPanel.new())
		"map", "mapnm":
			# --screen=mapnm: Ác Mộng tab with a lvl-45 hero who cleared the story
			if screen == "mapnm":
				Hero.add_exp(Game.hero, 600000)
				for r in Journey.REGIONS.size():
					for s2 in 6:
						Game.hero.stars[Journey.stage_id(r, s2)] = 3
				Game.hero.nstars = {"0_0": 3, "0_1": 2, "1_0": 1}
				MapScreen.last_nm = true
				MapScreen.last_region = int(_arg(args, "--region=", "0"))
			Game.goto(MapScreen.new())
		"checkin":
			Game.hero.checkin = {"day": "", "n": int(_arg(args, "--days=", "3"))}
			Titles.refresh(Game.hero)   # no "new title" toast over the panel
			var hc := HubScreen.new()
			Game.goto(hc)
			hc._open_checkin.call_deferred()
		"titles":
			Game.hero.titles = ["tan_hiep", "giang_ho", "ac_mong", "loi_dai"]
			Game.hero.title = "giang_ho"
			var cs2 := CharacterScreen.new()
			Game.goto(cs2)
			cs2._title_dialog.call_deferred()
		"profile":
			# a strong rival: lvl 60, legendary +15 weapon, skills levelled
			var rv := Hero.create("Tiêu Dao Khách", "thieu_lam")
			Hero.add_exp(rv, 900000)
			rv.pts = Build.auto_points(int(rv.level), Sects.get_sect("thieu_lam"), RandomNumberGenerator.new())
			rv.gear["weapon"] = Items.make("weapon", 7, 4, 15)
			rv.gear["armor"] = Items.make("armor", 7, 3, 12)
			for i in rv.skill_lv.size():
				rv.skill_lv[i] = 5
			Hero._fill_slots(rv)
			ProfilePanel.fake_duel = Duel.fields(rv)
			ProfilePanel.fake_duel.score = 1462
			var rs2 := RankScreen.new()
			rs2.fake_rows.append({"_id": "x_0", "name": rv.name, "sect": rv.sect, "level": int(rv.level), "power": Hero.power(rv), "tower": 64, "stars": 186, "title": "ac_mong_chu"})
			Game.goto(rs2)
			(func(): rs2.ui.add_child(ProfilePanel.new(rs2.fake_rows[0], func(): Game.goto(RankScreen.new())))).call_deferred()
		"char": Game.goto(CharacterScreen.new())
		# 1.5.0: Môn Phái Tranh Hùng / Kỳ Ngộ / Trận Đã Lưu demo screens
		"monphai", "monphaiboard", "monphaireward":
			var h := Game.hero
			Hero.add_exp(h, 20000)
			MonPhai.ensure(h)
			h.mp.pts = 186
			h.mp.today = 42
			if "--claim" in args:
				h.mp.prev = {"week": "2000w01", "pts": 300, "sect": str(h.sect)}
			if "--buff" in args:
				h.mp.buff = Duel.season()
			var mps := MonPhaiScreen.new()
			var demo := [["thieu_lam", 61420, 412], ["nga_mi", 48810, 298], ["vo_dang", 52110, 377], ["cai_bang", 30240, 231], ["duong_mon", 27720, 246], ["vovinam", 6200, 41]]
			for d in demo:
				mps.fake_rows.append({"sect": d[0], "sum": d[1], "n": d[2], "score": MonPhai.score(d[1], d[2])})
			mps.fake_rows.sort_custom(func(a, b): return a.score > b.score)
			var names := ["Tiêu Dao Khách", "Nguyệt Ảnh", "Bạch Vân", "", "Thiết Quyền", "Hàn Băng", "Phi Yến", "Cuồng Đao"]
			for n in 12:
				mps.fake_board.append({"_id": "f%d" % n, "name": names[n % names.size()], "sect": Sects.IDS[n % 5], "level": 62 - n * 3, "pts": 840 - n * 41})
			Game.goto(mps)
			if screen == "monphaiboard":
				mps._board.call_deferred()
			elif screen == "monphaireward":
				mps._rewards.call_deferred()
		"hubkn", "mapkn":
			var h := Game.hero
			Hero.add_exp(h, 20000)
			for s2 in 6:
				h.stars[Journey.stage_id(0, s2)] = 3
				h.stars[Journey.stage_id(1, s2)] = 2
			h.kn = {}
			KyNgo.spawn(h, _arg(args, "--kind=", "cao_nhan"), 4242)
			h.kn.cur.r = 1
			MonPhai.ensure(h)
			h.mp.pts = 64
			h.mp.today = 18
			if screen == "mapkn":
				MapScreen.last_nm = false
				MapScreen.last_region = 1
				Game.goto(MapScreen.new())
			else:
				Titles.refresh(h)
				Game.goto(HubScreen.new())
		"kndialog":
			var h := Game.hero
			Hero.add_exp(h, 20000)
			h.stars["0_5"] = 3
			h.kn = {}
			var kc := KyNgo.spawn(h, _arg(args, "--kind=", "cao_nhan"), 4242)
			Game.goto(DialogScreen.new(int(kc.r), "", KyNgo.side(h, kc), func(): pass, KyNgo.lines(kc)))
		"knresult":
			var h := Game.hero
			Hero.add_exp(h, 20000)
			MonPhai.ensure(h)
			h.mp.today = 30
			var kc := KyNgo.spawn(h, "cao_nhan", 4242)
			Replay.last = {"cfg": {}, "p": [], "e": []}
			Game.goto(ResultScreen.new({"mode": "kyngo", "won": true, "res": {"max_combo": 11, "seconds": 41.0}, "kind": "cao_nhan",
				"foe": kc.name, "r": 0, "rewards": KyNgo.rewards(h, "cao_nhan"), "levels": 0, "mp": 8, "taught": [KyNgo.insight_key(kc), KyNgo.INSIGHT], "kn_new": false}))
		"replays":
			for k in 3:
				var m := {"mode": ["duel", "wboss", "kyngo"][k], "p": "Kiểm Thử", "e": ["Tiêu Dao Khách", "Đồng Giáp La Hán", "Bạch Vân Lão Nhân"][k],
					"ps": "vo_dang", "es": ["nga_mi", "thieu_lam", "duong_mon"][k], "pl": 32, "el": [33, 32, 34][k], "won": k != 1, "secs": [74, 90, 41][k],
					"t": int(Time.get_unix_time_from_system()) - k * 7200, "title": ""}
				Replay.save({"ver": Replay.version(), "cfg": {"p": {}, "e": {}}, "p": [], "e": [], "meta": m})
			Game.goto(ReplayScreen.new())
		"wbossresult":
			var wr := {"max_combo": 9, "seconds": 90.0}
			WBoss.ensure(Game.hero).dmg = 2480
			Game.goto(ResultScreen.new({"mode": "wboss", "won": false, "res": wr, "dmg": 2480, "ratio": 0.31, "boss": WBoss.today_boss().name, "rewards": WBoss.try_rewards(int(Game.hero.level), 0.31, false), "levels": 0}))
		"wboss", "wbossboard":
			var wbs := WBossScreen.new()
			var pool_arg := _arg(args, "--pool=")
			if pool_arg != "":   # promo: boss pool part-way down, this hero's damage today
				wbs.fake_pool = int(pool_arg)
				WBoss.ensure(Game.hero).dmg = 24800
				WBoss.ensure(Game.hero).best = 24800
			Game.goto(wbs)
			if screen == "wbossboard":
				var names := ["Tiêu Dao Khách", "Nguyệt Ảnh", "Bạch Vân", "Lãng Tử", "Thiết Quyền", "Hàn Băng", "Phi Yến", "Cuồng Đao"]
				for n in 12:
					wbs.fake_rows.append({"_id": "f%d" % n, "name": names[n % names.size()], "sect": Sects.IDS[n % 5], "level": 58 - n * 3, "dmg": 412000 - n * 27300})
				wbs._board.call_deferred()
		"rename":
			var cs := CharacterScreen.new()
			Game.goto(cs)
			cs._rename_dialog.call_deferred()
			if "--renametest" in args:
				# swear → refused, same → refused, ok → renamed + 7-day lock
				var h := Game.hero
				var old := str(h.name)
				h.rename_at = 0
				print("RENAME swear: ", Hero.name_problem(h, Hero.tidy_name("  đm   abc ")))
				print("RENAME same: ", Hero.name_problem(h, old))
				print("RENAME tidy: [", Hero.tidy_name("  Tiêu   Dao\tKhách  "), "]")
				cs._renamed(Hero.tidy_name("  Tiêu   Dao\tKhách  "))
				print("RENAME now: ", h.name, " left_days=", Hero.rename_left(h) / 86400.0)
				print("RENAME saved: ", Game.slot_info(Game.slot).get("name", "?"))
				get_tree().quit()
		"renamewait":
			Game.hero.rename_at = Time.get_unix_time_from_system() - 86400 * 2.4
			Game.goto(CharacterScreen.new())
		"skill": Game.goto(SkillScreen.new())
		"rank":
			# 50 fake rows; with --dragtest a real touch swipe is injected and the scroll offset printed
			var rs := RankScreen.new()
			# --ranktest: 140 rows + this hero's own, then "Xem thêm" and "Vị trí của tôi"
			var rt := "--ranktest" in args
			var live := "--live" in args   # --ranktest --live: real Firestore rows
			for n in (0 if live else 140 if rt else 50):
				rs.fake_rows.append({"_id": "f%d" % n, "name": L.f("Hiệp Khách %d", (n + 1)), "sect": Sects.IDS[n % 6], "level": 60 - n / 3, "power": 9000 - n * (70 if rt else 97), "tower": 80 - n / 2, "stars": 120 - n})
			if rt and not live and not Game.hero.is_empty():
				var mine := Ranks.fields(Game.hero)
				mine["_id"] = "%s_%d" % [Cloud.uid, Game.slot]
				rs.fake_rows.append(mine)
			if live:
				# read-only: no RankScreen (it would publish the test hero)
				_rank_live_test.call_deferred()
				return
			Game.goto(rs)
			if "--dragtest" in args:
				_drag_test.call_deferred(rs)
			if rt:
				_rank_test.call_deferred(rs)
		"foreign", "foreign2":
			Game.hero.insight = {"cai_bang:0": 18, "nga_mi:1": 7, "duong_mon:2": 3, "vo_dang:3": 1}
			Insight.equip(Game.hero, "cai_bang:0", 2)
			var ss := SkillScreen.new()
			Game.goto(ss)
			if screen == "foreign2":
				ss._foreign.call_deferred()
		"tower": Game.goto(TowerScreen.new())
		"chat":
			var cs := ChatScreen.new()
			var names := ["Tiêu Dao Khách", "Nguyệt Ảnh", "Bạch Vân", "Lãng Tử", "Thiết Quyền", "Hàn Băng"]
			var lines := ["Ai đi Phó Bản cấp 30 không?", "Nga Mi đánh Tháp tầng 40 khó quá", "Mới lên +12 vũ khí, đỏ như lửa luôn!", "đm thua hoài", "Vovinam mở bằng cách nào vậy mọi người?", "Đánh boss vùng 3 xong là mở phái ẩn đó bạn", "Tỉ Võ tuần này ai top 1 vậy, lực chiến cao ghê", "Chúc mọi người buổi tối vui vẻ, luyện công thuận lợi nha"]
			for n in lines.size():
				cs.fake_msgs.append({"_id": "f%d" % n, "uid": "me" if n == 2 else "u%d" % n, "name": Game.hero.name if n == 2 else names[n % names.size()], "sect": Game.hero.sect if n == 2 else Sects.IDS[n % 6], "level": 12 + n * 5, "text": Chat.censor(lines[n]), "at": "2026-11-18T%02d:%02d:00Z" % [6 + n / 3, (n * 7) % 60]})
			Cloud.uid = "me"
			Game.goto(cs)
		"rank": Game.goto(RankScreen.new())
		"wardrobe": Game.goto(WardrobeScreen.new())
		"dialog": Game.goto(DialogScreen.new(5, "boss", Journey.stage_side(5, 5), func(): pass))
		"duel": Game.goto(DuelScreen.new())
		"daily":
			Daily.track(Game.hero, "fight", 3)
			Game.goto(DailyScreen.new())
		"gear": Game.goto(GearScreen.new(false))
		"topup": Game.goto(TopupScreen.new())
		"achieve":
			Game.hero.wins = 64
			Game.hero.arena_best = 7
			Game.hero.ach = {"wins": 1, "level": 1}
			Game.hero.ach_c = {"perfect": 9, "ults": 12, "combo": 11, "duel_wins": 2}
			Game.goto(AchieveScreen.new())
		"dungeon", "forge", "forge2", "forge3":
			# demo forge state: materials, a +8 weapon with luck, a Bảo hat
			Game.hero.mats = {"iron": 46, "star": 5, "wash": 3, "charm": 2}
			Game.hero.gear["weapon"] = Items.drop("weapon", 3, 2)
			Game.hero.gear.weapon.plus = 8
			Game.hero.gear.weapon.luck = 0.16
			Game.hero.gear["hat"] = Items.drop("hat", 3, 3)
			Game.hero.dungeon = {"date": Daily.today(), "used": 1, "ads": 0, "best": {"mine": 1}}
			if screen == "dungeon":
				Game.goto(DungeonScreen.new())
			else:
				var gs := GearScreen.new(false)
				Game.goto(gs)
				var tb: int = {"forge": 0, "forge2": 1, "forge3": 2}[screen]
				(func(): gs.ui.add_child(ForgePanel.new("weapon", tb))).call_deferred()
		"shop": Game.goto(GearScreen.new(true))
		"help":
			var t := TitleScreen.new()
			Game.goto(t)
			t.ui.add_child.call_deferred(HelpPanel.new())
		"result":
			Game.goto(ResultScreen.new({"mode": "stage", "r": 1, "s": 5, "won": true, "stars": 2,
				"res": {"max_combo": 7, "seconds": 74, "perf_low": "--perflow" in args}, "rewards": {"exp": 420, "gold": 380, "jade": 3},
				"levels": 1, "book": "manh", "drop": Items.make("weapon", 3, 2, 0), "unlock": "Trường Giang Độ Khẩu"}))

func _process(_d: float) -> void:
	if _shot == "":
		return
	_n += 1
	if _n == _delay:
		get_viewport().get_texture().get_image().save_png(_shot)
		print("shot ", _shot)
		get_tree().quit()

## Swipe up on the rank list with real touch events; the list must scroll.
func _drag_test(rs: RankScreen) -> void:
	for i in 20:
		await get_tree().process_frame
	var sc: ScrollContainer = rs._sc
	var start := sc.get_global_rect().get_center() + Vector2(0, 150)
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = start
	t.pressed = true
	Input.parse_input_event(t)
	var p := start
	for k in 20:
		await get_tree().process_frame
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.relative = Vector2(0, -18)
		p += d.relative
		d.position = p
		d.velocity = Vector2(0, -900)
		Input.parse_input_event(d)
	await get_tree().process_frame
	t = InputEventScreenTouch.new()
	t.index = 0
	t.position = p
	t.pressed = false
	Input.parse_input_event(t)
	for i in 10:
		await get_tree().process_frame
	print("DRAGTEST scroll_vertical=%d max=%d draw_calls=%d prims=%d" % [sc.scroll_vertical, int(sc.get_v_scroll_bar().max_value), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	get_tree().quit()

## Swipe across the hub hero with real touch events; the hero must turn.
func _turn_test(hs: HubScreen) -> void:
	for i in 20:
		await get_tree().process_frame
	var start := Vector2(500, 400)
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = start
	t.pressed = true
	Input.parse_input_event(t)
	var p := start
	for k in 15:
		await get_tree().process_frame
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.relative = Vector2(20, 0)
		p += d.relative
		d.position = p
		d.velocity = Vector2(1200, 0)
		Input.parse_input_event(d)
	await get_tree().process_frame
	t = InputEventScreenTouch.new()
	t.index = 0
	t.position = p
	t.pressed = false
	Input.parse_input_event(t)
	var after_drag := hs.show.turn
	for i in 40:
		await get_tree().process_frame
	print("TURNTEST after_drag=%.2f after_fling=%.2f" % [after_drag, hs.show.turn])

## Rank paging: top page, "Xem thêm", then "Vị trí của tôi" (screenshot after).
func _rank_test(rs: RankScreen) -> void:
	for i in 15:
		await get_tree().process_frame
	print("RANKTEST top rows=%d place=%d me_btn=%s more=%s" % [rs._rows.size(), rs._place, rs._me_btn.visible, not rs._next.is_empty()])
	await rs._load_more()
	print("RANKTEST more rows=%d next=%s" % [rs._rows.size(), not rs._next.is_empty()])
	await rs._load_more()
	print("RANKTEST more2 rows=%d next=%s" % [rs._rows.size(), not rs._next.is_empty()])
	await rs._show_me()
	var me := rs._mine_row()
	print("RANKTEST around start=%d rows=%d mine_at=%d scroll=%d" % [rs._start, rs._rows.size(), me.get_index() if me else -1, rs._sc.scroll_vertical])

## --ranktest --live: cursor paging and the ascending "above me" query
## against the real rank collection (pages of 3 must equal one page of 6).
func _rank_live_test() -> void:
	for i in 600:
		await get_tree().process_frame
		if Cloud.enabled() and Cloud.uid != "":
			break
	var six: Array = await Cloud.query(Ranks.COLLECTION, "power", 6)
	var a: Array = await Cloud.query(Ranks.COLLECTION, "power", 3)
	var b: Array = await Cloud.query(Ranks.COLLECTION, "power", 3, null, null, false, a.back() if a.size() > 0 else {})
	var ids := func(rows: Array) -> Array: return rows.map(func(r): return "%s=%d" % [r._id.substr(0, 6), int(r.power)])
	print("LIVE six  ", ids.call(six), " err=", Cloud.last_error)
	print("LIVE 3+3  ", ids.call(a + b))
	var v := int(six[3].power) if six.size() > 3 else 0
	var up: Array = await Cloud.query(Ranks.COLLECTION, "power", 2, v + 1, null, true)
	var dn: Array = await Cloud.query(Ranks.COLLECTION, "power", 2, null, v)
	print("LIVE around v=%d up(asc)=%s down=%s above=%d err=%s" % [v, ids.call(up), ids.call(dn), await Cloud.count_above(Ranks.COLLECTION, "power", v), Cloud.last_error])
	get_tree().quit()

## -- --replaytest [--n=N]: plays N fights of different kinds with the AI on
## both sides, keeps each through Replay.save / load_one (the file format),
## plays it back and checks the replay ends on the same frame with the same
## health. Also checks Môn Phái / Kỳ Ngộ bookkeeping. Prints REPLAYTEST lines.
func _replay_test(i: int, bad: int) -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(_arg(args, "--n=", "8"))
	if i == 0:
		Game.autoplay = true
		Game.slot = 2
		var sects: Array = Sects.IDS
		Game.hero = Hero.create("Kiểm Thử", sects[randi() % sects.size()])
		Hero.add_exp(Game.hero, 60000)
		Game.hero.stars["0_5"] = 3
		Game.hero.stars["1_5"] = 3
		_mp_ky_checks()
	if i >= n:
		print("REPLAYTEST done: %d/%d replays matched" % [n - bad, n])
		get_tree().quit(1 if bad > 0 else 0)
		return
	var h := Game.hero
	var cfg: Dictionary
	match (i % 6) if not "--only3" in args else 3:
		0: cfg = {"p": Hero.side(h), "e": Duel.side(Duel.bots(h, 1)[0]), "theme": "temple", "rounds": 2, "seed": randi(), "mode": "duel"}
		1:
			var f := 9 + 3 * (i / 6)   # floors with rules (no_skill / time / regen ...)
			cfg = {"p": Hero.side(h), "e": Tower.side(f), "theme": "peak", "rounds": 1, "seed": randi(), "rule": Tower.rule(f), "mode": "tower"}
		2: cfg = {"p": Hero.side(h), "e": Dungeon.side(0, 1, 2), "theme": "temple", "rounds": 1, "seed": randi(), "p_hp": 0.6, "mode": "dungeon"}
		3: cfg = {"p": Hero.side(h), "e": WBoss.side(h), "theme": "snow", "rounds": 1, "seed": randi(), "time": 20, "wboss": true, "mode": "wboss"}
		4:
			var kc := KyNgo.spawn(h, ["cao_nhan", "bi_kip", "bao_tang", "ma_dau"][(i / 6) % 4])
			cfg = {"p": Hero.side(h), "e": KyNgo.side(h, kc), "theme": "bamboo", "rounds": 1, "seed": randi(), "rule": KyNgo.rule(str(kc.kind)), "mode": "kyngo"}
		5: cfg = {"p": Hero.side(h), "e": Journey.stage_side(3, 5), "theme": "snow", "rounds": 2, "seed": randi(), "mode": "stage"}
	var fs := FightScene.new(cfg)
	fs.finished.connect(func(res: Dictionary):
		var rp: Dictionary = Replay.last
		if rp.is_empty():
			print("REPLAYTEST %d %s: NO REPLAY" % [i, cfg.mode])
			_replay_test.call_deferred(i + 1, bad + 1)
			return
		# through the file format, like a saved fight
		var ok_save := Replay.save(rp) if not "--nofile" in args else false
		var back := Replay.load_one(str(rp.get("saved_id", ""))) if ok_save else rp
		Replay.delete(str(rp.get("saved_id", "")))
		print("REPLAYTEST %d %s: won=%s frames=%d inputs=%d+%d saved=%s" % [i, cfg.mode, res.won, int(rp.end_frame), rp.p.size(), rp.e.size(), ok_save])
		Flow.watch(back, func(wr: Dictionary):
			print("REPLAYTEST %d %s: replay same=%s" % [i, cfg.mode, wr.get("same", false)])
			_replay_test.call_deferred(i + 1, bad + (0 if wr.get("same", false) else 1))))
	Game.goto(fs)

## -- --clocktest: GameClock (server time, offline day hold) and the daily
## resets against phones set ahead, plus the old double check-in.
func _clock_test() -> void:
	var fails := []
	var ok := func(cond: bool, what: String):
		if not cond:
			fails.append(what)
	ok.call(GameClock.parse_http_date(" Thu, 26 Nov 2026 10:01:07 GMT") == 1795687267.0, "http date")
	ok.call(GameClock.parse_http_date("garbage") < 0.0, "bad http date")
	var real := 1795687267.0   # 2026-11-26 10:01 UTC
	var real_day := Time.get_date_string_from_unix_time(int(real) + GameClock.bias_s())
	# never online: the phone's clock
	GameClock.reset()
	GameClock.device_override = real + 9 * 86400
	ok.call(GameClock.today() != real_day and not GameClock.day_held(), "never online uses phone")
	# offline after a trusted time: the day holds
	GameClock.reset()
	GameClock.set_floor(real)
	GameClock.device_override = real + 9 * 86400
	ok.call(GameClock.today() == real_day and GameClock.day_held(), "offline day hold")
	GameClock.device_override = real - 3 * 86400
	ok.call(GameClock.now() >= real and GameClock.today() == real_day, "never back before the floor")
	# online: the server's time whatever the phone says
	GameClock.reset()
	GameClock.device_override = real + 9 * 86400
	GameClock.synced(real)
	ok.call(GameClock.today() == real_day and absf(GameClock.skew() - 9 * 86400) < 5, "server time")
	ok.call(Duel.season() == Duel.season(real), "season by server time")
	# the pasted top player's check-in: both old fields, claimed today
	var h := Hero.create("Kiểm Thử", "duong_mon")
	Hero.add_exp(h, 60000)
	h.checkin = {"day": real_day, "last": real_day, "n": 19}
	ok.call(not Checkin.can_claim(h) and not h.checkin.has("last"), "old check-in merged")
	h.checkin = {"day": "2026-11-20", "last": real_day, "n": 5}
	ok.call(not Checkin.can_claim(h), "old screen's claim counts today")
	h.checkin = {"day": "2026-11-25", "n": 5}
	ok.call(Checkin.can_claim(h) and not Checkin.claim(h).is_empty() and Checkin.claim(h).is_empty() and Checkin.days(h) == 6, "one claim a day")
	# saved while the phone ran ahead
	h.checkin = {"day": "2026-12-09", "n": 30}
	ok.call(not Checkin.can_claim(h) and str(h.checkin.day) == real_day, "future check-in day")
	h.daily = {"date": "2026-12-09", "ids": ["fight"], "prog": {"fight": 3}, "claimed": ["fight"], "chest": true}
	Daily.ensure(h)
	ok.call(h.daily.date == real_day and h.daily.claimed == ["fight"] and h.daily.chest, "future missions kept")
	h.dungeon = {"best": {}, "date": "2026-12-09", "used": 4, "ads": 0}
	var used_left := Dungeon.left(h)
	h.dungeon = {"best": {}, "date": real_day, "used": 4, "ads": 0}
	ok.call(used_left == Dungeon.left(h), "future dungeon entries stay used")
	h.duel = {"season": "2099w01", "score": 1900, "tickets": 0, "day": "2026-12-09", "wins": 40, "losses": 0, "last_season": "2099w00", "last_score": 1500, "paid": ""}
	var d := Duel.ensure(h)
	ok.call(int(d.score) == Duel.START and int(d.tickets) == 0 and Duel.season_reward(h) == 0, "future duel season void")
	h.wboss = {"date": "2026-12-09", "tries": 4, "ads": 1, "dmg": 90000, "best": 20000, "prev": {"date": "2026-12-08", "dmg": 80000}, "claimed": ""}
	WBoss.ensure(h)
	ok.call(WBoss.left(h) == 0 and int(h.wboss.dmg) == 0 and not WBoss.claimable(h), "future boss day")
	h.mp = {"week": "2099w01", "pts": 700, "day": "2026-12-09", "today": 120, "prev": {"week": "2099w00", "pts": 500, "sect": "duong_mon"}, "claimed": "", "buff": "", "best": 0, "wins": 0}
	MonPhai.ensure(h)
	ok.call(MonPhai.pts(h) == 0 and MonPhai.today(h) == MonPhai.DAY_CAP and not MonPhai.claimable(h), "future sect week")
	h.kn = {"day": "2026-12-09", "n": 2, "cur": {}, "done": 0}
	h.stars["0_5"] = 3
	ok.call(not KyNgo.daily(h) and not KyNgo.after_win(h, 0.0), "future encounter day")
	# a real new day after all that
	GameClock.synced(real + 86400)
	ok.call(Checkin.can_claim(h) and Dungeon.left(h) > 0 and WBoss.left(h) > 0 and int(Duel.ensure(h).tickets) == Duel.TICKETS, "next real day opens")
	GameClock.reset()
	print("CLOCKTEST %s" % ("ALL PASS" if fails.is_empty() else "FAIL: " + ", ".join(fails)))
	get_tree().quit(0 if fails.is_empty() else 1)

func _mp_ky_checks() -> void:
	var h := Game.hero
	var fails := []
	var got := 0
	for k in 30:
		got += MonPhai.add(h, 6)
	if got != MonPhai.DAY_CAP or MonPhai.today(h) != MonPhai.DAY_CAP: fails.append("day cap %d" % got)
	h.mp.week = "2000w01"   # a new week: last week's total becomes claimable
	MonPhai.ensure(h)
	if int(h.mp.prev.pts) != MonPhai.DAY_CAP or not MonPhai.claimable(h) or MonPhai.pts(h) != 0: fails.append("week roll %s" % h.mp)
	h.mp.day = "2000-01-01"
	if MonPhai.add(h, 6) != 6: fails.append("new day")
	if MonPhai.score(300, 5) != 30 or MonPhai.score(0, 0) != 0: fails.append("score")
	var rw := {"exp": 100, "gold": 50}
	h.mp.buff = Duel.season()
	Flow._grant(rw)
	if int(rw.exp) != 110 or int(rw.gold) != 55: fails.append("buff %s" % rw)
	var rw2 := {"exp": 100, "gold": 50}
	Flow._grant(rw2, false)
	if int(rw2.exp) != 100: fails.append("no buff on x2")
	h.mp.buff = ""
	h.kn = {}
	if not KyNgo.daily(h) or KyNgo.daily(h): fails.append("daily spawn")
	var kc := KyNgo.current(h)
	if not int(kc.r) in [0, 1] or str(kc.sect) == str(h.sect): fails.append("spawn place %s" % kc)
	if KyNgo.after_win(h, 0.0): fails.append("spawn while one waits")
	h.kn.cur = {}
	if not KyNgo.after_win(h, 0.0) or int(h.kn.n) != 2: fails.append("after win")
	h.kn.cur = {}
	if KyNgo.after_win(h, 0.0): fails.append("day max")
	for kind in KyNgo.KINDS:
		var c := KyNgo.spawn(h, kind)
		var e := KyNgo.side(h, c)
		if e.is_empty() or KyNgo.lines(c).size() != 3 or KyNgo.promise(c) == "": fails.append("kind " + kind)
		if kind == "cao_nhan":
			var names: Array = e.skills.filter(func(x): return x != null).map(func(x): return x.name)
			if not Insight.skill_of(KyNgo.insight_key(c)).name in names: fails.append("master lacks his technique")
	var k := KyNgo.insight_key(KyNgo.spawn(h, "cao_nhan"))
	var before := Insight.points(h, k)
	Insight.grant(h, k, KyNgo.INSIGHT)
	if Insight.points(h, k) != before + KyNgo.INSIGHT: fails.append("insight grant")
	print("REPLAYTEST checks: %s" % ("ok" if fails.is_empty() else ", ".join(fails)))

## Value of a "--key=value" test flag (or `default`).
func _arg(args: PackedStringArray, key: String, default := "") -> String:
	for a in args:
		if a.begins_with(key):
			return a.substr(key.length())
	return default
