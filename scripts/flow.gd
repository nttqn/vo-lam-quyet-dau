class_name Flow
extends RefCounted
## Starts fights for each mode and applies their results.

static func _launch(cfg: Dictionary, on_done: Callable) -> void:
	var fs := FightScene.new(cfg)
	fs.finished.connect(func(res: Dictionary):
		# ngộ chiêu: techniques read during the fight (win or lose, not training/forfeit)
		if not cfg.get("training", false) and not cfg.get("spar", false) and not res.get("forfeit", false) and Game.hero:
			res["learned"] = Insight.apply(Game.hero, res.get("insight", {}))
		on_done.call(res))
	Game.goto(fs)

## Môn Phái Tranh Hùng: adds the fight's công (day cap) and sends the week's
## total; returns what was added, for the result screen.
static func _mp(h: Dictionary, n: int) -> int:
	var got := MonPhai.add(h, n)
	if got > 0 and Cloud.enabled():
		MonPhai.publish(h, Game.slot)
	return got

## Xem lại trận: plays a recorded fight; `back` gets the watch result
## ({same: replay matched the original}).
static func watch(rp: Dictionary, back: Callable) -> void:
	if rp.is_empty() or not (rp.get("cfg") is Dictionary):
		return
	var cfg: Dictionary = rp.cfg.duplicate(true)
	cfg["replay"] = rp
	var fs := FightScene.new(cfg)
	fs.finished.connect(func(res: Dictionary):
		if not res.get("forfeit", false) and not res.get("same", true):
			push_warning("replay desync")
			Funnel.event("rp_desync")
		back.call(res))
	Game.goto(fs)

# ------------------------------------------------------------- story
static func start_stage(r: int, s: int) -> void:
	var h := Game.hero
	var foe := Journey.stage_side(r, s)
	# story first: the region's intro on its first duel, the boss's words before the boss
	if not Game.autoplay:
		if s == 0 and Story.has(r, "intro") and not Story.seen(h, r, "intro"):
			Game.goto(DialogScreen.new(r, "intro", {}, func(): start_stage(r, s)))
			return
		if s == 5 and Story.has(r, "boss") and not Story.seen(h, r, "boss"):
			Game.goto(DialogScreen.new(r, "boss", foe, func(): start_stage(r, s)))
			return
	var cfg := {
		"p": Hero.side(h), "e": foe,
		"theme": Journey.REGIONS[r].theme, "rounds": 2, "seed": randi(), "mode": "stage",
	}
	if tutorial_due(h, r, s):   # trận nhập môn: one round, lessons, can't be lost
		cfg["tutorial"] = true
		cfg.rounds = 1
	_launch(cfg, func(res: Dictionary): _stage_done(r, s, res))

## The first duel of a hero that has never fought teaches the controls.
static func tutorial_due(h: Dictionary, r: int, s: int) -> bool:
	return r == 0 and s == 0 and int(h.get("fights", 0)) == 0 and not Dictionary(h.get("stars", {})).has("0_0")

## Story or Ác Mộng duel.
static func start_any(r: int, s: int, nm: bool) -> void:
	if nm:
		start_nightmare(r, s)
	else:
		start_stage(r, s)

## Ác Mộng: the same duel at level 30-60, no story dialogue.
static func start_nightmare(r: int, s: int) -> void:
	var cfg := {
		"p": Hero.side(Game.hero), "e": Journey.nm_side(r, s),
		"theme": Journey.REGIONS[r].theme, "rounds": 2, "seed": randi(), "mode": "nm",
	}
	_launch(cfg, func(res: Dictionary): _nightmare_done(r, s, res))

static func _nightmare_done(r: int, s: int, res: Dictionary) -> void:
	var h := Game.hero
	h.fights = int(h.fights) + 1
	var out := {"mode": "stage", "nm": true, "r": r, "s": s, "won": res.won, "res": res}
	Daily.on_fight(h, "stage", res)
	if res.won:
		h.wins = int(h.wins) + 1
		var stars := 1
		if res.hp_left >= 0.5:
			stars = 2
		if res.perfect and res.hp_left >= 0.5:
			stars = 3
		var sid := Journey.stage_id(r, s)
		var prev := Journey.nm_stars(h, r, s)
		var first := prev == 0
		var rw := Journey.nm_rewards(r, s, first, stars)
		if not (h.get("nstars") is Dictionary):
			h.nstars = {}
		h.nstars[sid] = maxi(prev, stars)
		out.stars = stars
		out.rewards = rw
		out.levels = _grant(rw)
		out.mp = _mp(h, MonPhai.PTS.nm)
		out.kn_new = KyNgo.after_win(h)
		if first and s == 5:
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var it := Journey.nm_boss_drop(r, rng)
			h.bag.append(it)
			out.drop = it
			out.book = Books.random_kind(rng)
			Books.give(h, out.book)
	else:
		h.losses = int(h.losses) + 1
		var rw2 := {"exp": int(Journey.nm_rewards(r, s, false, 1).exp * 0.25), "gold": 0, "jade": 0}
		out.rewards = rw2
		out.levels = _grant(rw2)
	Game.save()
	Game.goto(ResultScreen.new(out))

## Đấu thử: a friendly duel with another player's shadow (Tỉ Võ snapshot).
## No rewards, no score; `back` rebuilds the screen to return to.
static func start_spar(e: Dictionary, back: Callable) -> void:
	e = e.duplicate(true)
	e["title"] = "Đấu thử"
	var themes := ["temple", "bamboo", "river", "peak", "night"]
	var cfg := {"p": Hero.side(Game.hero), "e": e, "theme": themes[randi() % themes.size()], "rounds": 2, "seed": randi(), "spar": true, "mode": "spar"}
	_launch(cfg, func(_res: Dictionary): back.call())

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
		# forge materials: Huyền Thiết on first clears, Thiên Tinh from region bosses
		if first:
			rw["mats"] = {"iron": 2 + 2 * r}
			if s == 5:
				rw.mats["star"] = 1 + r / 2
		elif randf() < 0.3:
			rw["mats"] = {"iron": 1 + r}
		h.stars[sid] = maxi(prev, stars)
		out.stars = stars
		if r == 2 and s == 5:
			for hid in Sects.HIDDEN:
				if not Game.settings.get("unlock_" + hid, false):
					Game.settings["unlock_" + hid] = true
					Game.save_settings()
					out.unlocked_sect = hid
		out.rewards = rw
		out.levels = _grant(rw)
		out.mp = _mp(h, MonPhai.PTS.stage)
		if not (first and s == 5):   # the boss's own story comes first
			out.kn_new = KyNgo.after_win(h)
		var gift := Journey.starter_gift(r, s) if first else ""
		if gift != "":
			var git := Items.drop(gift, 1, 1)
			if Dictionary(h.gear.get(gift, {})).is_empty():
				h.gear[gift] = git
				out.worn = true
			else:
				h.bag.append(git)
			out.drop = git
		if first and s == 5:
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var it := Journey.boss_drop(r, rng)
			h.bag.append(it)
			out.drop = it
		if first and s == 5:
			var brng := RandomNumberGenerator.new()
			brng.randomize()
			out.book = Books.random_kind(brng)
			Books.give(h, out.book)
		if first and s == 5 and r + 1 < Journey.REGIONS.size():
			out.unlock = Journey.REGIONS[r + 1].name
	else:
		h.losses = int(h.losses) + 1
		# consolation: a little experience so the player always progresses
		# (half a win's worth in region 0, where a loss most often ends the game)
		var rw2 := {"exp": int(Journey.rewards(r, s, r == 0, 1).exp * (0.5 if r == 0 else 0.25)), "gold": 0, "jade": 0}
		out.rewards = rw2
		out.levels = _grant(rw2)
	Game.save()
	if res.won and s == 5 and not Game.autoplay and Story.has(r, "after") and not Story.seen(h, r, "after"):
		Game.goto(DialogScreen.new(r, "after", Journey.stage_side(r, s), func(): Game.goto(ResultScreen.new(out))))
		return
	Game.goto(ResultScreen.new(out))

## Gives a fight's rewards. The sect that won last week's Môn Phái Tranh
## Hùng fights with +10% experience and gold (written into rw, so the result
## screen shows the real numbers); `buff` false for the ad's ×2 top-up.
static func _grant(rw: Dictionary, buff := true) -> int:
	var h := Game.hero
	if buff and MonPhai.buffed(h) and (int(rw.get("exp", 0)) > 0 or int(rw.get("gold", 0)) > 0):
		rw["exp"] = int(round(int(rw.get("exp", 0)) * (1.0 + MonPhai.BUFF)))
		rw["gold"] = int(round(int(rw.get("gold", 0)) * (1.0 + MonPhai.BUFF)))
		rw["buff"] = true
	h.gold = int(h.gold) + int(rw.get("gold", 0))
	h.jade = int(h.jade) + int(rw.get("jade", 0))
	Mats.give(h, rw.get("mats", {}))
	return Hero.add_exp(h, int(rw.get("exp", 0)))

# ------------------------------------------------------------- arena
static func start_arena(n: int, revived := false) -> void:
	var h := Game.hero
	var themes := ["night", "temple", "bamboo", "river", "snow", "desert", "demon", "peak"]
	var cfg := {
		"p": Hero.side(h), "e": Journey.arena_side(int(h.level), n),
		"theme": themes[n % themes.size()], "rounds": 1, "seed": randi(), "arena_n": n, "mode": "arena",
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
		rw["mats"] = arena_mats(streak, int(h.level))
		out.rewards = rw
		out.levels = _grant(rw)
		out.streak = streak
		out.mp = _mp(h, MonPhai.PTS.arena)
	else:
		out.rewards = {"exp": 0, "gold": 0, "jade": 0}
		out.levels = 0
		out.streak = n
	Game.save()
	Game.goto(ResultScreen.new(out))

## Lôi Đài loot per win: Huyền Thiết grows with the streak; every 5th win a
## Hộ Phù, every 10th a Thiên Tinh + Tẩy Luyện Thạch.
static func arena_mats(streak: int, hlvl: int) -> Dictionary:
	var m := {"iron": 1 + streak / 3 + hlvl / 15}
	if streak % 5 == 0:
		m["charm"] = 1
	if streak % 10 == 0:
		m["star"] = 1
		m["wash"] = 1
	return m

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

# ------------------------------------------------------------- tower
static func start_tower(f: int) -> void:
	var h := Game.hero
	var p := Hero.side(h)
	var r := Tower.rule(f)
	if r == "no_skill":
		p.skills = [null, null, null, null]
	elif r == "glass":
		p.stats.hp_max *= 0.5
	var themes := ["temple", "peak", "snow", "night", "demon"]
	var cfg := {"p": p, "e": Tower.side(f), "theme": themes[(f / 10) % themes.size()], "rounds": 1, "seed": randi(), "rule": r, "mode": "tower"}
	_launch(cfg, func(res: Dictionary): _tower_done(f, res))

static func _tower_done(f: int, res: Dictionary) -> void:
	var h := Game.hero
	h.fights = int(h.fights) + 1
	var out := {"mode": "tower", "f": f, "won": res.won, "res": res}
	Daily.on_fight(h, "tower", res)
	if res.won:
		h.wins = int(h.wins) + 1
		var first := f > Tower.best(h)
		out.mp = _mp(h, MonPhai.PTS.tower_new if first else MonPhai.PTS.tower)
		var rw := Tower.reward(f) if first else {"gold": 0, "exp": int(Tower.reward(f).exp * 0.2), "jade": 0, "item": -1}
		if first:
			rw["mats"] = Tower.mats(f)
		if first:
			h.tower = {"best": f}
			if f % 5 == 0:
				var brng := RandomNumberGenerator.new()
				brng.randomize()
				out.book = Books.random_kind(brng)
				Books.give(h, out.book)
		out.rewards = rw
		out.levels = _grant(rw)
		if int(rw.get("item", -1)) >= 0:
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var slot: String = Items.SLOTS[rng.randi_range(0, Items.SLOTS.size() - 1)]
			var it := Items.drop(slot, clampi(1 + int((Tower.level(f) - 1) / 5.5), 1, 7), int(rw.item))
			h.bag.append(it)
			out.drop = it
	else:
		h.losses = int(h.losses) + 1
		out.rewards = {"exp": 0, "gold": 0, "jade": 0}
		out.levels = 0
	Game.save()
	Game.goto(ResultScreen.new(out))

# ------------------------------------------------------------- dungeon (Phó Bản)
## Fight k (0..2) of a run; hp = HP fraction carried in.
static func start_dungeon(i: int, diff: int, k := 0, hp := 1.0) -> void:
	var h := Game.hero
	if k == 0 and Dungeon.left(h) <= 0:
		return
	var cfg := {"p": Hero.side(h), "e": Dungeon.side(i, diff, k), "theme": Dungeon.LIST[i].theme,
		"rounds": 1, "seed": randi(), "p_hp": clampf(hp, 0.05, 1.0), "mode": "dungeon"}
	_launch(cfg, func(res: Dictionary): _dungeon_done(i, diff, k, res))

static func _dungeon_done(i: int, diff: int, k: int, res: Dictionary) -> void:
	var h := Game.hero
	h.fights = int(h.fights) + 1
	Daily.on_fight(h, "dungeon", res)
	var out := {"mode": "dungeon", "i": i, "d": diff, "k": k, "won": res.won, "res": res,
		"rewards": {"exp": 0, "gold": 0, "jade": 0}, "levels": 0}
	if res.won:
		h.wins = int(h.wins) + 1
		if k < Dungeon.FIGHTS - 1:
			out.next_hp = minf(1.0, float(res.hp_left) + Dungeon.HEAL_BETWEEN)
		else:
			var first := diff > Dungeon.best(h, i)
			if Dungeon.record_clear(h, i, diff):
				var rng := RandomNumberGenerator.new()
				rng.randomize()
				var rw := Dungeon.rewards(h, i, diff, first, rng)
				out.rewards = rw
				out.levels = _grant(rw)
				out.cleared = true
				out.mp = _mp(h, MonPhai.PTS.dungeon)
				Daily.track(h, "dungeon")
			else:
				out.no_entry = true
	else:
		h.losses = int(h.losses) + 1
	Game.save()
	Game.goto(ResultScreen.new(out))

## Quét: instant loot of a cleared difficulty. Returns the rewards ({} if not allowed).
static func sweep_dungeon(i: int, diff: int) -> Dictionary:
	var h := Game.hero
	if Dungeon.best(h, i) < diff or not Dungeon.record_clear(h, i, diff):
		return {}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var rw := Dungeon.rewards(h, i, diff, false, rng)
	rw.exp = int(rw.exp * 0.5)
	rw["levels"] = _grant(rw)
	rw["mp"] = _mp(h, MonPhai.PTS.sweep)
	Daily.track(h, "dungeon")
	Game.save()
	return rw

# ------------------------------------------------------------- duel (Tỉ Võ)
static func start_duel(doc: Dictionary) -> void:
	var h := Game.hero
	var d := Duel.ensure(h)
	if int(d.tickets) <= 0:
		return
	d.tickets = int(d.tickets) - 1
	Game.save()
	var themes := ["temple", "peak", "river", "night", "bamboo"]
	var cfg := {"p": Hero.side(h), "e": Duel.side(doc), "theme": themes[randi() % themes.size()], "rounds": 2, "seed": randi(), "mode": "duel"}
	_launch(cfg, func(res: Dictionary): _duel_done(doc, res))

static func _duel_done(doc: Dictionary, res: Dictionary) -> void:
	var h := Game.hero
	h.fights = int(h.fights) + 1
	Daily.on_fight(h, "duel", res)
	var delta := Duel.apply(h, int(doc.get("score", Duel.START)), res.won)
	var out := {"mode": "duel", "won": res.won, "res": res, "delta": delta, "foe": str(doc.get("name", "?"))}
	var lvl := int(h.level)
	if res.won:
		h.wins = int(h.wins) + 1
		out.rewards = {"exp": 15 + 6 * lvl, "gold": 20 + 8 * lvl, "jade": 0, "mats": {"iron": 2 + lvl / 10}}
		if randf() < 0.4:
			out.rewards.mats["wash"] = 1
	else:
		h.losses = int(h.losses) + 1
		out.rewards = {"exp": 5 + 2 * lvl, "gold": 0, "jade": 0}
	out.levels = _grant(out.rewards)
	out.mp = MonPhai.add(h, MonPhai.PTS.duel_win if res.won else MonPhai.PTS.duel_loss)
	Game.save()
	if Cloud.enabled() and int(out.mp) > 0:
		MonPhai.publish(h, Game.slot)
	# publish the new score (fire and forget)
	if Cloud.enabled():
		Duel.publish(h)
	Game.goto(ResultScreen.new(out))

# ------------------------------------------------------------- Boss Thế Giới
## One try against today's boss. The try is spent when the fight starts, so
## quitting the app mid-fight doesn't give it back.
static func start_wboss() -> void:
	var h := Game.hero
	if not WBoss.unlocked(h) or WBoss.left(h) <= 0:
		return
	var w := WBoss.ensure(h)
	w.tries = int(w.tries) + 1
	Game.save()
	var b := WBoss.today_boss()
	var cfg := {"p": Hero.side(h), "e": WBoss.side(h, b), "theme": b.theme, "rounds": 1, "seed": randi(),
		"time": WBoss.FIGHT_SECONDS, "wboss": true, "mode": "wboss"}
	_launch(cfg, func(res: Dictionary): _wboss_done(cfg, res))

static func _wboss_done(cfg: Dictionary, res: Dictionary) -> void:
	var h := Game.hero
	h.fights = int(h.fights) + 1
	Daily.on_fight(h, "wboss", res)
	var w := WBoss.ensure(h)
	var hp_max: float = cfg.e.stats.hp_max
	var dmg := int(clampf(float(res.get("dmg", 0.0)), 0.0, hp_max))
	var killed: bool = res.won and not res.get("forfeit", false)
	w.dmg = int(w.dmg) + dmg
	w.best = maxi(int(w.best), dmg)
	var rw := WBoss.try_rewards(int(h.level), dmg / hp_max, killed)
	var out := {"mode": "wboss", "won": killed, "res": res, "dmg": dmg, "ratio": dmg / hp_max,
		"boss": str(cfg.e.name), "rewards": rw}
	out.levels = _grant(rw)
	if killed:
		h.wins = int(h.wins) + 1
	if not res.get("forfeit", false):
		out.mp = MonPhai.add(h, MonPhai.wboss_pts(dmg / hp_max, killed))
	Game.save()
	if Cloud.enabled():
		WBoss.publish(h, Game.slot)
		if int(out.get("mp", 0)) > 0:
			MonPhai.publish(h, Game.slot)
	Game.goto(ResultScreen.new(out))

# ------------------------------------------------------------- Kỳ Ngộ
## The waiting stranger: a few words first (not on a retry), then the duel.
static func start_kyngo() -> void:
	var h := Game.hero
	var cur := KyNgo.current(h)
	if cur.is_empty():
		return
	var e := KyNgo.side(h, cur)
	var go := func():
		var cfg := {"p": Hero.side(h), "e": e, "theme": Journey.REGIONS[int(cur.r)].theme, "rounds": 1,
			"seed": randi(), "rule": KyNgo.rule(str(cur.kind)), "mode": "kyngo", "regen": KyNgo.REGEN}
		_launch(cfg, func(res: Dictionary): _kyngo_done(cur, res))
	if int(cur.get("tries", 0)) == 0 and not Game.autoplay:
		Game.goto(DialogScreen.new(int(cur.r), "", e, go, KyNgo.lines(cur)))
	else:
		go.call()

static func _kyngo_done(cur: Dictionary, res: Dictionary) -> void:
	var h := Game.hero
	var k := KyNgo.ensure(h)
	h.fights = int(h.fights) + 1
	Daily.on_fight(h, "kyngo", res)
	var kind := str(cur.kind)
	var out := {"mode": "kyngo", "won": res.won, "res": res, "kind": kind, "foe": str(cur.name), "r": int(cur.r)}
	if res.won:
		h.wins = int(h.wins) + 1
		var rw := KyNgo.rewards(h, kind)
		out.rewards = rw
		out.levels = _grant(rw)
		match kind:
			"cao_nhan":
				var key := KyNgo.insight_key(cur)
				out.taught = [key, KyNgo.INSIGHT]
				var up := Insight.grant(h, key, KyNgo.INSIGHT)
				if not up.is_empty():
					res["learned"] = Array(res.get("learned", [])) + [up]
			"bi_kip":
				var brng := RandomNumberGenerator.new()
				brng.randomize()
				out.book = Books.random_kind(brng)
				Books.give(h, out.book)
		out.mp = _mp(h, MonPhai.PTS.kyngo)
		k.cur = {}
		k.done = int(k.get("done", 0)) + 1
	else:
		h.losses = int(h.losses) + 1
		var rw2 := {"exp": int(KyNgo.rewards(h, kind).exp * 0.25), "gold": 0, "jade": 0}
		out.rewards = rw2
		out.levels = _grant(rw2)
		cur.tries = int(cur.get("tries", 0)) + 1   # giving up counts as a try too
		out.tries_left = maxi(0, KyNgo.TRIES - int(cur.tries))
		if int(cur.tries) >= KyNgo.TRIES:
			k.cur = {}
	Game.save()
	Game.goto(ResultScreen.new(out))
