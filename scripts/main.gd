extends Node
## Entry point. Test flags (after "--"):
##   --posetest, --fighttest [--p=sect --e=sect --theme=x]
##   --screen=title|create|hub|map|char|skill|gear|shop|result  --shot=path --delay=frames

var _shot := ""
var _delay := 30
var _n := 0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var screen := ""
	for a in args:
		if a.begins_with("--shot="): _shot = a.substr(7)
		if a.begins_with("--delay="): _delay = int(a.substr(8))
		if a.begins_with("--screen="): screen = a.substr(9)
	for a in args:
		if a.begins_with("--iconshot"):
			add_child(load("res://tools/icon_shot.gd").new())
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
			p.skills = [Sects.get_sect(ps).skills[0], Sects.get_sect(ps).skills[2], Sects.get_sect(ps).skills[5]]
			var e := Npc.side(es, 20, "Đối Thủ", 0.7, "bandit", true, 9)
			var fs := FightScene.new({"p": p, "e": e, "theme": th, "autoplay": true, "seed": 3})
			Game.goto(fs)
			return
	if "--flowtest" in args:
		Game.autoplay = true
		Game.slot = 2
		Game.hero = Hero.create("Kiểm Thử", "nga_mi")
		Flow.start_stage(0, 0)
		return
	if screen != "":
		_demo_screen(screen, args)
		return
	Game.goto(TitleScreen.new())

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
		"create": Game.goto(CreateScreen.new(0))
		"hub": Game.goto(HubScreen.new())
		"map": Game.goto(MapScreen.new())
		"char": Game.goto(CharacterScreen.new())
		"skill": Game.goto(SkillScreen.new())
		"gear": Game.goto(GearScreen.new(false))
		"shop": Game.goto(GearScreen.new(true))
		"help":
			var t := TitleScreen.new()
			Game.goto(t)
			t.ui.add_child.call_deferred(HelpPanel.new())
		"result":
			Game.goto(ResultScreen.new({"mode": "stage", "r": 1, "s": 5, "won": true, "stars": 2,
				"res": {"max_combo": 7, "seconds": 74}, "rewards": {"exp": 420, "gold": 380, "jade": 3},
				"levels": 1, "drop": Items.make("weapon", 3, 2, 0), "unlock": "Trường Giang Độ Khẩu"}))

func _process(_d: float) -> void:
	if _shot == "":
		return
	_n += 1
	if _n == _delay:
		get_viewport().get_texture().get_image().save_png(_shot)
		print("shot ", _shot)
		get_tree().quit()
