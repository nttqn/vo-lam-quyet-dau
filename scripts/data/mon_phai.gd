class_name MonPhai
extends RefCounted
## Môn Phái Tranh Hùng (1.5.0): a weekly race between the sects. Every fight
## a hero wins (and a Tỉ Võ or Boss Thế Giới try even when lost) adds Công
## Trạng to their sect, up to DAY_CAP a day. The week follows the Tỉ Võ
## season (Duel.season, Monday to Sunday). Standing = Uy Danh:
##   sum of the members' công / (members + DAMP)
## so a big sect can't win on numbers alone and a sect of three can't win
## on one player either. Next week every hero who earned MIN_CLAIM công gets
## the reward of their sect's place; the winning sect also fights the whole
## following week with +BUFF experience and gold (Flow._grant).
##
## Firestore: mp_<yyyy>w<ww>/{uid}_{slot} {name, sect, level, pts}; written
## once the hero has MIN_DOC công that week (so one stray fight doesn't
## count as a member), pts only grows (firestore.rules).
## h.mp = {week, pts, day, today, prev: {week, pts, sect}, claimed, buff, best, wins}

const DAY_CAP := 120
const MIN_DOC := 10
const MIN_CLAIM := 20
const DAMP := 5.0
const BUFF := 0.10
const WEEK_MAX := 900          # firestore.rules refuses more (7 × DAY_CAP + slack)

## Công per kind of fight.
const PTS := {"stage": 3, "nm": 4, "arena": 2, "tower_new": 4, "tower": 1, "dungeon": 6, "sweep": 4,
	"duel_win": 6, "duel_loss": 2, "kyngo": 8}

## Place 1..6 -> rewards.
const PLACE := [
	{"jade": 40, "mats": {"star": 2, "wash": 2, "charm": 1}},
	{"jade": 28, "mats": {"star": 1, "wash": 2}},
	{"jade": 20, "mats": {"star": 1, "wash": 1}},
	{"jade": 14, "mats": {"wash": 1, "iron": 12}},
	{"jade": 10, "mats": {"iron": 10}},
	{"jade": 8, "mats": {"iron": 8}},
]

static func collection(week := "") -> String:
	return "mp_" + (week if week != "" else Duel.season())

## Brings h.mp up to date: a new week keeps the last one's total for its reward.
static func ensure(h: Dictionary) -> Dictionary:
	var m: Dictionary = h.get("mp", {})
	if m.is_empty():
		m = {"week": Duel.season(), "pts": 0, "day": "", "today": 0, "prev": {"week": "", "pts": 0, "sect": ""},
			"claimed": "", "buff": "", "best": 0, "wins": 0}
	var wk := Duel.season()
	var wc := Daily.cmp(str(m.get("week", "")), wk)
	if wc > 0:
		m["week"] = wk   # a week reached by setting the phone ahead: its công is void
		m["pts"] = 0
	elif wc < 0:
		if int(m.get("pts", 0)) > 0:
			m["prev"] = {"week": str(m.week), "pts": int(m.pts), "sect": str(h.get("sect", ""))}
		m["week"] = wk
		m["pts"] = 0
	var dc := Daily.cmp(str(m.get("day", "")), Daily.today())
	if dc > 0:
		m["day"] = Daily.today()
	elif dc < 0:
		m["day"] = Daily.today()
		m["today"] = 0
	h.mp = m
	return m

static func unlocked(h: Dictionary) -> bool:
	return int(h.get("level", 1)) >= 5

## Adds công for a fight; returns what was really added (the day's cap).
static func add(h: Dictionary, n: int) -> int:
	if n <= 0 or not unlocked(h):
		return 0
	var m := ensure(h)
	var got := mini(n, DAY_CAP - int(m.today))
	if got <= 0:
		return 0
	m.today = int(m.today) + got
	m.pts = mini(WEEK_MAX, int(m.pts) + got)
	m.best = maxi(int(m.get("best", 0)), int(m.pts))
	return got

static func pts(h: Dictionary) -> int:
	return int(ensure(h).pts)

static func today(h: Dictionary) -> int:
	return int(ensure(h).today)

## Công of a Boss Thế Giới try: 4..12 by the share of the boss's health taken, +4 for a kill.
static func wboss_pts(ratio: float, killed: bool) -> int:
	return 4 + int(clampf(ratio, 0.0, 1.0) * 8.0) + (4 if killed else 0)

## The winning sect's members fight this week with more experience and gold.
static func buffed(h: Dictionary) -> bool:
	return str(Dictionary(h.get("mp", {})).get("buff", "")) == Duel.season()

# ------------------------------------------------------------- cloud
static func fields(h: Dictionary) -> Dictionary:
	var m := ensure(h)
	# hidden from the boards: the công still counts for the sect, nameless
	var nm := "" if Ranks.hidden() else str(h.name).substr(0, 24)
	return {"name": nm, "sect": str(h.sect), "level": int(h.level), "pts": int(m.pts)}

static func publish(h: Dictionary, slot: int) -> bool:
	if not Cloud.enabled() or Ban.active() or not Ranks.honest(h) or pts(h) < MIN_DOC:
		return false
	return await Cloud.put_doc(collection(), "_%d" % slot, fields(h))

static func remove(slot: int) -> void:
	if Cloud.enabled():
		Cloud.delete_doc(collection(), "_%d" % slot)

static var _cache := {}   # week -> {at, rows}

## The sects of that week, best first: [{sect, sum, n, score}], [] offline.
static func standings(week := "", fresh := false) -> Array:
	var wk := week if week != "" else Duel.season()
	var c: Dictionary = _cache.get(wk, {})
	var now := Time.get_ticks_msec()
	if not fresh and not c.is_empty() and now - int(c.at) < 60000:
		return c.rows
	if not Cloud.enabled():
		return []
	var rows := []
	for sid in Sects.IDS:
		var r: Dictionary = await Cloud.sum_count_eq(collection(wk), "sect", sid, "pts")
		if r.is_empty():
			return []
		rows.append({"sect": sid, "sum": int(r.sum), "n": int(r.n), "score": score(int(r.sum), int(r.n))})
	rows.sort_custom(func(a, b): return a.score > b.score if a.score != b.score else a.sum > b.sum)
	_cache[wk] = {"at": now, "rows": rows}
	return rows

static func score(total: int, members: int) -> int:
	return int(round(total / (members + DAMP))) if total > 0 else 0

## 1-based place of a sect in standings rows (-1 if missing).
static func place_of(rows: Array, sid: String) -> int:
	for i in rows.size():
		if rows[i].sect == sid:
			return i + 1
	return -1

## Top công of the week across every sect.
static func board(week := "", n := 30) -> Array:
	if not Cloud.enabled():
		return []
	return await Cloud.query(collection(week), "pts", n)

# ------------------------------------------------------------- weekly reward
static func claimable(h: Dictionary) -> bool:
	var m := ensure(h)
	var p: Dictionary = m.prev
	return str(p.week) != "" and int(p.pts) >= MIN_CLAIM and str(m.claimed) != str(p.week) and str(p.week) < Duel.season()

static func place_rewards(place: int) -> Dictionary:
	return PLACE[clampi(place, 1, PLACE.size()) - 1].duplicate(true)

## Last week's reward: looks up where the hero's sect finished.
## {place, rewards, buff} | {} nothing to claim | {err: "offline"}.
static func claim(h: Dictionary) -> Dictionary:
	if not claimable(h):
		return {}
	var m := ensure(h)
	var p: Dictionary = m.prev
	var rows := await standings(str(p.week))
	if rows.is_empty():
		return {"err": "offline"}
	if not claimable(h):   # double tap meanwhile
		return {}
	var place := place_of(rows, str(p.sect))
	if int(rows[0].sum) <= 0:
		place = PLACE.size()   # nobody's công reached the server that week: no real standing
	var rw := place_rewards(place)
	m.claimed = str(p.week)
	h.jade = int(h.jade) + int(rw.get("jade", 0))
	Mats.give(h, rw.get("mats", {}))
	var buff := place == 1
	if buff:
		m.buff = Duel.season()
		m.wins = int(m.get("wins", 0)) + 1
	return {"place": place, "rewards": rw, "buff": buff, "sect": str(p.sect)}

static func rewards_text(rw: Dictionary) -> String:
	var parts := []
	if int(rw.get("jade", 0)) > 0:
		parts.append(L.f("Ngọc %d", int(rw.jade)))
	var mm: Dictionary = rw.get("mats", {})
	for id in Mats.IDS:
		if int(mm.get(id, 0)) > 0:
			parts.append(L.f("%s %d", [Mats.name_of(id), int(mm[id])]))
	return ", ".join(parts)
