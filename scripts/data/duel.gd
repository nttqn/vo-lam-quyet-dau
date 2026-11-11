class_name Duel
extends RefCounted
## Tỉ Võ: asynchronous duels against other players' "shadows" (their hero
## snapshot, played by the AI). Weekly seasons, one Firestore collection each:
## duel_<yyyy>w<ww>/{uid} = {data (snapshot JSON), score, name, sect, level, power}.
## h.duel = {season, score, tickets, day, wins, losses, last_season, last_score}

const START := 1000
const TICKETS := 10
const K := 32.0
const AI := 0.75

static func season(t := -1.0) -> String:
	# ISO-like week number, counted from Monday
	var now := Time.get_unix_time_from_system() if t < 0.0 else t
	var d := Time.get_datetime_dict_from_unix_time(int(now))
	var monday := int(now) - ((int(d.weekday) + 6) % 7) * 86400
	var md := Time.get_datetime_dict_from_unix_time(monday)
	var jan1 := Time.get_unix_time_from_datetime_dict({"year": md.year, "month": 1, "day": 1})
	return "%dw%02d" % [md.year, int((monday - jan1) / (7 * 86400)) + 1]

static func collection(s := "") -> String:
	return "duel_" + (s if s != "" else season())

## Days left in the season (until next Monday).
static func days_left() -> int:
	var d := Time.get_datetime_dict_from_system()
	return 7 - (int(d.weekday) + 6) % 7

## Brings h.duel up to date: new day refills tickets, new season resets the
## score (remembering the last one for its reward).
static func ensure(h: Dictionary) -> Dictionary:
	var d: Dictionary = h.get("duel", {})
	if d.is_empty():
		d = {"season": season(), "score": START, "tickets": TICKETS, "day": Daily.today(), "wins": 0, "losses": 0, "last_season": "", "last_score": 0, "paid": ""}
		h.duel = d
	if d.get("day", "") != Daily.today():
		d.day = Daily.today()
		d.tickets = TICKETS
	if d.get("season", "") != season():
		if int(d.wins) + int(d.losses) > 0:
			d.last_season = d.season
			d.last_score = int(d.score)
		d.season = season()
		d.score = START
		d.wins = 0
		d.losses = 0
	return d

static func tier(score: int) -> Array:
	# [name, colour, season reward jade]
	if score >= 1400: return ["Tông Sư", Color(1.0, 0.55, 0.25), 40]
	if score >= 1250: return ["Cao Thủ", Color(0.85, 0.5, 1.0), 25]
	if score >= 1100: return ["Hiệp Khách", Color(0.45, 0.75, 1.0), 15]
	if score >= 1000: return ["Võ Sinh", Color(0.55, 0.9, 0.55), 8]
	return ["Tân Thủ", Color(0.75, 0.72, 0.66), 4]

## Season reward for the previous season, once.
static func season_reward(h: Dictionary) -> int:
	var d := ensure(h)
	if d.last_season == "" or d.get("paid", "") == d.last_season:
		return 0
	return int(tier(int(d.last_score))[2])

static func claim_season_reward(h: Dictionary) -> int:
	var j := season_reward(h)
	if j > 0:
		h.jade = int(h.jade) + j
		h.duel.paid = h.duel.last_season
	return j

## What other players fight: stats, equipped skills and looks of this hero.
static func snapshot(h: Dictionary) -> Dictionary:
	var sk := []
	for k in 3:
		var i := int(h.equip[k])
		if i >= 0 and int(h.skill_lv[i]) > 0:
			sk.append([i, int(h.skill_lv[i])])
	var w: Dictionary = h.gear.get("weapon", {})
	return {"sect": h.sect, "name": h.name, "level": int(h.level), "stats": Hero.stats(h), "skills": sk,
		"color": int(h.get("color", 0)), "wrar": int(w.get("rar", 0))}

static func fields(h: Dictionary) -> Dictionary:
	var d := ensure(h)
	return {"data": JSON.stringify(snapshot(h)), "score": int(d.score), "name": str(h.name), "sect": str(h.sect),
		"level": int(h.level), "power": Hero.power(h), "t": int(Time.get_unix_time_from_system())}

## Fighter side for a shadow (doc from Cloud.query, or a bot).
static func side(doc: Dictionary) -> Dictionary:
	var snap = JSON.parse_string(str(doc.get("data", "")))
	if not snap is Dictionary:
		return {}
	var s := Sects.get_sect(str(snap.sect))
	var sk := []
	for p in snap.get("skills", []):
		var i := int(p[0])
		if i >= 0 and i < s.skills.size():
			sk.append(Hero.skill_scaled(s.skills[i], int(p[1])))
	while sk.size() < 3:
		sk.append(null)
	var lk: Dictionary = s.look.duplicate()
	var c := int(snap.get("color", 0))
	if c > 0:
		var alt := Looks.palette(str(snap.sect), c)
		for k in alt:
			lk[k] = alt[k]
	if int(snap.get("wrar", 0)) >= 3:
		lk["trim"] = Color(0.9, 0.72, 0.3)
	var st: Dictionary = snap.stats
	for k in st:
		st[k] = float(st[k])
	return {"sect": str(snap.sect), "name": str(snap.name), "level": int(snap.level), "stats": st, "skills": sk,
		"look": lk, "ai": AI, "boss": false, "title": "%s · %d điểm" % [tier(int(doc.get("score", START)))[0], int(doc.get("score", START))]}

## Offline / empty-season fallback: generated rivals around the hero's level.
static func bots(h: Dictionary, n := 4) -> Array:
	var d := ensure(h)
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Daily.today() + str(h.get("created", 0)) + str(d.score))
	var first := ["Vô Danh", "Ẩn", "Tiêu Dao", "Lãng", "Cô", "Phiêu"]
	var last := ["Khách", "Kiếm", "Tử", "Sinh", "Hiệp", "Nhân"]
	for i in n:
		var sid: String = Sects.IDS[rng.randi_range(0, Sects.IDS.size() - 1)]
		var lvl := maxi(1, int(h.level) + rng.randi_range(-2, 2))
		var npc := Npc.side(sid, lvl, first[rng.randi_range(0, 5)] + " " + last[rng.randi_range(0, 5)], AI, "", false, rng.randi())
		var sk := []
		var all_sk: Array = Sects.get_sect(sid).skills
		for m in npc.skills:
			if m == null:
				continue
			for j in all_sk.size():
				if all_sk[j].name == m.name:
					sk.append([j, int(m.get("lv", 1))])
					break
		var snap := {"sect": sid, "name": npc.name, "level": lvl, "stats": npc.stats, "skills": sk, "color": 0, "wrar": 0}
		var sc := int(d.score) + rng.randi_range(-80, 80)
		out.append({"_id": "bot%d" % i, "data": JSON.stringify(snap), "score": sc, "name": npc.name, "sect": sid, "level": lvl, "power": Build.power(npc.stats), "bot": true})
	return out

static func expected(a: int, b: int) -> float:
	return 1.0 / (1.0 + pow(10.0, (b - a) / 400.0))

## Applies a result; returns the score change.
static func apply(h: Dictionary, opp_score: int, won: bool) -> int:
	var d := ensure(h)
	var e := expected(int(d.score), opp_score)
	var delta := int(round(K * ((1.0 if won else 0.0) - e)))
	if won:
		delta = maxi(delta, 4)
		d.wins = int(d.wins) + 1
	else:
		delta = mini(delta, -2)
		d.losses = int(d.losses) + 1
	d.score = maxi(0, int(d.score) + delta)
	return delta
