extends Node
## Entry point. Test flags (after "--"):
##   --posetest, --fighttest [--p=sect --e=sect --theme=x]
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
			p.skills = [Sects.get_sect(ps).skills[0], Sects.get_sect(ps).skills[2], Sects.get_sect(ps).skills[5]]
			var e := Npc.side(es, 20, "Đối Thủ", 0.7, "bandit", true, 9)
			var fs := FightScene.new({"p": p, "e": e, "theme": th, "autoplay": true, "seed": 3})
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
			cs._pick.call_deferred("nga_mi")
		"hub": Game.goto(HubScreen.new())
		"map": Game.goto(MapScreen.new())
		"char": Game.goto(CharacterScreen.new())
		"skill": Game.goto(SkillScreen.new())
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
