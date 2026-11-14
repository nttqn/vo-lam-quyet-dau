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
		if a.begins_with("--screen="): screen = a.substr(9)
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
		if a == "--memmodels":
			add_child(load("res://tools/mem_models.gd").new())
			return
		if a == "--soak":
			add_child(load("res://tools/soak.gd").new())
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
				if b.begins_with("--e="): es = b.substr(4)
				if b.begins_with("--theme="): th = b.substr(8)
			var p := Npc.side(ps, 20, "Thử Nghiệm", 0.7, "", false, 5)
			for b in args:
				if b.begins_with("--outfit="):
					p.look["model"] = Outfits.model_for(ps, b.substr(9))
			p.skills = [Sects.get_sect(ps).skills[0], Sects.get_sect(ps).skills[2], Sects.get_sect(ps).skills[3], Sects.get_sect(ps).skills[5]]
			for b in args:
				if b.begins_with("--skills="):   # e.g. --skills=1,3,5 (sect skill slots 0-5)
					p.skills = []
					for si in b.substr(9).split(","): p.skills.append(Sects.get_sect(ps).skills[int(si)])
			var e := Npc.side(es, 20, "Đối Thủ", 0.7, "bandit", true, 9)
			var rounds := 2
			for b in args:
				if b.begins_with("--ehp="): e.stats.hp_max *= float(b.substr(6))   # quick KO for finisher shots
				if b.begins_with("--rounds="): rounds = int(b.substr(9))
			var fs := FightScene.new({"p": p, "e": e, "theme": th, "autoplay": true, "seed": 3, "rounds": rounds})
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
		if "--duel" in args:
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
		"hub": Game.goto(HubScreen.new())
		"map": Game.goto(MapScreen.new())
		"char": Game.goto(CharacterScreen.new())
		"skill": Game.goto(SkillScreen.new())
		"rank":
			# 50 fake rows; with --dragtest a real touch swipe is injected and the scroll offset printed
			var rs := RankScreen.new()
			for n in 50:
				rs.fake_rows.append({"_id": "f%d" % n, "name": "Hiệp Khách %d" % (n + 1), "sect": Sects.IDS[n % 6], "level": 60 - n, "power": 9000 - n * 97, "tower": 80 - n, "stars": 120 - n})
			Game.goto(rs)
			if "--dragtest" in args:
				_drag_test.call_deferred(rs)
		"foreign", "foreign2":
			Game.hero.insight = {"cai_bang:0": 18, "nga_mi:1": 7, "duong_mon:2": 3, "vo_dang:3": 1}
			Insight.equip(Game.hero, "cai_bang:0", 2)
			var ss := SkillScreen.new()
			Game.goto(ss)
			if screen == "foreign2":
				ss._foreign.call_deferred()
		"tower": Game.goto(TowerScreen.new())
		"rank": Game.goto(RankScreen.new())
		"wardrobe": Game.goto(WardrobeScreen.new())
		"dialog": Game.goto(DialogScreen.new(5, "boss", Journey.stage_side(5, 5), func(): pass))
		"duel": Game.goto(DuelScreen.new())
		"daily":
			Daily.track(Game.hero, "fight", 3)
			Game.goto(DailyScreen.new())
		"gear": Game.goto(GearScreen.new(false))
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
