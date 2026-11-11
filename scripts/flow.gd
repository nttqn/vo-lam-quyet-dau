class_name Flow
extends RefCounted
## Starts fights for each mode and applies their results.

static func _launch(cfg: Dictionary, on_done: Callable) -> void:
	var fs := FightScene.new(cfg)
	fs.finished.connect(on_done)
	Game.goto(fs)

# ------------------------------------------------------------- story
static func start_stage(r: int, s: int) -> void:
	var h := Game.hero
	var cfg := {
		"p": Hero.side(h), "e": Journey.stage_side(r, s),
		"theme": Journey.REGIONS[r].theme, "rounds": 2, "seed": randi(),
	}
	_launch(cfg, func(res: Dictionary): _stage_done(r, s, res))

static func _stage_done(r: int, s: int, res: Dictionary) -> void:
	var h := Game.hero
	h.fights = int(h.fights) + 1
	var out := {"mode": "stage", "r": r, "s": s, "won": res.won, "res": res}
	Daily.on_fight(h, "stage", res)
	if res.won:
		h.wins = int(h.wins) + 1
		var stars := 1
		if res.hp_left >= 0.5:
			stars = 2
		if res.perfect and res.hp_left >= 0.5:
			stars = 3
		var sid := Journey.stage_id(r, s)
		var prev := int(h.stars.get(sid, 0))
		var first := prev == 0
		var rw := Journey.rewards(r, s, first, stars)
		h.stars[sid] = maxi(prev, stars)
		out.stars = stars
		out.rewards = rw
		out.levels = _grant(rw)
		if first and s == 5:
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var it := Journey.boss_drop(r, rng)
			h.bag.append(it)
			out.drop = it
		if first and s == 5 and r + 1 < Journey.REGIONS.size():
			out.unlock = Journey.REGIONS[r + 1].name
	else:
		h.losses = int(h.losses) + 1
		# consolation: a little experience so the player always progresses
		var rw2 := {"exp": int(Journey.rewards(r, s, false, 1).exp * 0.25), "gold": 0, "jade": 0}
		out.rewards = rw2
		out.levels = _grant(rw2)
	Game.save()
	Game.goto(ResultScreen.new(out))

static func _grant(rw: Dictionary) -> int:
	var h := Game.hero
	h.gold = int(h.gold) + int(rw.get("gold", 0))
	h.jade = int(h.jade) + int(rw.get("jade", 0))
	return Hero.add_exp(h, int(rw.get("exp", 0)))

# ------------------------------------------------------------- arena
static func start_arena(n: int, revived := false) -> void:
	var h := Game.hero
	var themes := ["night", "temple", "bamboo", "river", "snow", "desert", "demon", "peak"]
	var cfg := {
		"p": Hero.side(h), "e": Journey.arena_side(int(h.level), n),
		"theme": themes[n % themes.size()], "rounds": 1, "seed": randi(), "arena_n": n,
	}
	_launch(cfg, func(res: Dictionary): _arena_done(n, res, revived))

static func _arena_done(n: int, res: Dictionary, revived := false) -> void:
	var h := Game.hero
	var out := {"mode": "arena", "n": n, "won": res.won, "res": res, "revived": revived}
	Daily.on_fight(h, "arena", res)
	var lvl := int(h.level) - 3 + n
	if res.won:
		var streak := n + 1
		h.arena_best = maxi(int(h.arena_best), streak)
		var rw := {"exp": int((20 + 7 * lvl) * (1.0 + n * 0.1)), "gold": int((15 + 6 * lvl) * (1.0 + n * 0.15)), "jade": 1 if streak % 5 == 0 else 0}
		out.rewards = rw
		out.levels = _grant(rw)
		out.streak = streak
	else:
		out.rewards = {"exp": 0, "gold": 0, "jade": 0}
		out.levels = 0
		out.streak = n
	Game.save()
	Game.goto(ResultScreen.new(out))

# ------------------------------------------------------------- training
static func start_training() -> void:
	var h := Game.hero
	var sects: Array = Sects.IDS.duplicate()
	sects.shuffle()
	var e := Npc.side(sects[0], int(h.level), "Mộc Nhân Luyện Công", 0.0, "", false, 77, "Luyện tập")
	e.stats.hp_max *= 3.0
	var cfg := {"p": Hero.side(h), "e": e, "theme": "temple", "rounds": 99, "training": true, "seed": randi()}
	_launch(cfg, func(_res: Dictionary):
		Daily.track(Game.hero, "train")
		Daily.on_fight(Game.hero, "train", _res)
		Game.save()
		Game.goto(HubScreen.new()))
