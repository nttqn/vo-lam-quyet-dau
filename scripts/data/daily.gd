class_name Daily
extends RefCounted
## Daily missions (4 a day, picked by date). State lives in the hero:
## h.daily = {date, ids, prog, claimed, chest}. (The 7-day check-in is
## data/checkin.gd; this file had an older one of its own until 1.5.0.)

const PER_DAY := 4
const CHEST_JADE := 5

## id -> [text with %d, target, min hero level]
const POOL := {
	"fight": ["Đánh %d trận bất kỳ", 5, 1],
	"win_story": ["Thắng %d trận Hành Tẩu Giang Hồ", 3, 1],
	"win_arena": ["Thắng %d trận Lôi Đài", 3, 1],
	"skill": ["Thi triển võ công %d lần", 15, 1],
	"combo": ["Đạt liên kích %d đòn trong một trận", 6, 1],
	"perfect": ["Thắng tuyệt đối %d trận (không mất hiệp)", 2, 1],
	"train": ["Luyện công với mộc nhân %d lần", 1, 1],
	"upgrade": ["Nâng tầng võ công hoặc cường hóa trang bị %d lần", 1, 2],
	"ult": ["Thi triển tuyệt kỹ %d lần", 2, 20],
	"tower": ["Vượt %d tầng Tháp Thí Luyện", 2, 5],
	"duel": ["Tỉ võ với cao thủ khác %d lần", 2, 5],
	"dungeon": ["Vượt Phó Bản %d lần (đánh hoặc quét)", 2, 3],
}

## Today's date by GameClock (server time when known; scripts/clock.gd).
static func today() -> String:
	return GameClock.today()

## A stored day / week ("YYYY-MM-DD", "YYYYwWW": both sort as text) against
## the current one: -1 before it (a new day has come), 0 same, 1 after it
## (saved while the phone's clock ran ahead: nothing new until it is reached).
static func cmp(stored: String, cur: String) -> int:
	return -1 if stored < cur else (1 if stored > cur else 0)

## Rolls a new set of missions when the date changed.
static func ensure(h: Dictionary) -> Dictionary:
	var d: Dictionary = h.get("daily", {})
	var c := cmp(str(d.get("date", "")), today())
	if c > 0:
		d.date = today()   # ran ahead: keep that day's missions and progress
	if c < 0:
		var lv := int(h.level)
		var ids: Array = []
		for id in POOL:
			if lv >= int(POOL[id][2]):
				ids.append(id)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(today() + str(h.get("created", 0)))
		# "fight" is always there; the rest are drawn
		ids.erase("fight")
		var pick: Array = ["fight"]
		while pick.size() < PER_DAY and not ids.is_empty():
			pick.append(ids.pop_at(rng.randi_range(0, ids.size() - 1)))
		d = {"date": today(), "ids": pick, "prog": {}, "claimed": [], "chest": false}
		h.daily = d
	return d

static func target(id: String) -> int:
	return int(POOL[id][1])

static func text(id: String) -> String:
	return L.f(String(POOL[id][0]), target(id))

static func progress(h: Dictionary, id: String) -> int:
	return mini(target(id), int(ensure(h).prog.get(id, 0)))

static func done(h: Dictionary, id: String) -> bool:
	return progress(h, id) >= target(id)

static func reward(h: Dictionary, _id: String) -> Dictionary:
	var lv := int(h.level)
	return {"gold": 40 + 12 * lv, "exp": 25 + 9 * lv, "jade": 1}

static func track(h: Dictionary, id: String, n := 1) -> void:
	var d := ensure(h)
	if id in d.ids:
		d.prog[id] = int(d.prog.get(id, 0)) + n

static func track_max(h: Dictionary, id: String, v: int) -> void:
	var d := ensure(h)
	if id in d.ids:
		d.prog[id] = maxi(int(d.prog.get(id, 0)), v)

## Everything a finished fight counts toward. mode: stage / arena / tower / duel.
static func on_fight(h: Dictionary, mode: String, res: Dictionary) -> void:
	Achieve.on_fight(h, mode, res)
	if mode != "train":
		track(h, "fight")
	track(h, "skill", int(res.get("skills", 0)))
	track(h, "ult", int(res.get("ults", 0)))
	track_max(h, "combo", int(res.get("max_combo", 0)))
	if res.get("won", false):
		if res.get("perfect", false):
			track(h, "perfect")
		match mode:
			"stage": track(h, "win_story")
			"arena": track(h, "win_arena")
			"tower": track(h, "tower")
	if mode == "duel":
		track(h, "duel")

static func claim(h: Dictionary, id: String) -> Dictionary:
	var d := ensure(h)
	if not done(h, id) or id in d.claimed:
		return {}
	d.claimed.append(id)
	var rw := reward(h, id)
	Flow._grant(rw)
	return rw

static func chest_ready(h: Dictionary) -> bool:
	var d := ensure(h)
	return not d.chest and d.claimed.size() >= d.ids.size()

static func claim_chest(h: Dictionary) -> bool:
	if not chest_ready(h):
		return false
	h.daily.chest = true
	h.jade = int(h.jade) + CHEST_JADE
	return true

## Things waiting to be collected (hub badge).
static func pending(h: Dictionary) -> int:
	var d := ensure(h)
	var n := 0
	for id in d.ids:
		if done(h, id) and not id in d.claimed:
			n += 1
	if chest_ready(h):
		n += 1
	return n
