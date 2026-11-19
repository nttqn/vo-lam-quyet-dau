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
		if a.begins_with("--gfx="):
			Gfx.set_level(int(a.substr(6)))
			Gfx.apply(get_tree())
		if a.begins_with("--screen="): screen = a.substr(9)
		if a.begins_with("--wb="): WBoss.test_pick = int(a.substr(5))
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
			var fcfg := {"p": p, "e": e, "theme": th, "autoplay": true, "seed": 3, "rounds": rounds}
			if "--boss" in args:   # Boss Thế Giới giant (pick with --wb=i)
				var bh := Hero.create("Thử", ps)
				bh.level = 20
				fcfg.e = WBoss.side(bh)
				fcfg.theme = WBoss.today_boss().theme
				fcfg.rounds = 1
				fcfg["time"] = WBoss.FIGHT_SECONDS
				fcfg["wboss"] = true
			var fs := FightScene.new(fcfg)
			Game.goto(fs)
			return
	if "--backtest" in args:
		_back_test()
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
		elif tw > 0:
			Flow.start_tower(tw)
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
			var hub := HubScreen.new()
			Game.goto(hub)
			if "--turntest" in args:
				_turn_test.call_deferred(hub)
		"settings":
			var hs := HubScreen.new()
			Game.goto(hs)
			hs.ui.add_child.call_deferred(SettingsPanel.new())
		"map": Game.goto(MapScreen.new())
		"char": Game.goto(CharacterScreen.new())
		"wbossresult":
			var wr := {"max_combo": 9, "seconds": 90.0}
			WBoss.ensure(Game.hero).dmg = 2480
			Game.goto(ResultScreen.new({"mode": "wboss", "won": false, "res": wr, "dmg": 2480, "ratio": 0.31, "boss": WBoss.today_boss().name, "rewards": WBoss.try_rewards(int(Game.hero.level), 0.31, false), "levels": 0}))
		"wboss", "wbossboard":
			var wbs := WBossScreen.new()
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
				rs.fake_rows.append({"_id": "f%d" % n, "name": "Hiệp Khách %d" % (n + 1), "sect": Sects.IDS[n % 6], "level": 60 - n / 3, "power": 9000 - n * (70 if rt else 97), "tower": 80 - n / 2, "stars": 120 - n})
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
				"res": {"max_combo": 7, "seconds": 74}, "rewards": {"exp": 420, "gold": 380, "jade": 3},
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
