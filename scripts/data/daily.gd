class_name Daily
extends RefCounted
## Daily missions (4 a day, picked by date) and the 7-day check-in.
## State lives in the hero: h.daily = {date, ids, prog, claimed, chest},
## h.checkin = {n: days claimed so far (cycle of 7), last: date}.

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
}

## 7-day check-in: {gold, jade, item rarity (-1 none)}
const CHECKIN := [
	{"gold": 150, "jade": 0, "item": -1},
	{"gold": 0, "jade": 5, "item": -1},
	{"gold": 300, "jade": 0, "item": -1},
	{"gold": 0, "jade": 8, "item": -1},
	{"gold": 0, "jade": 0, "item": 2},
	{"gold": 500, "jade": 0, "item": -1},
	{"gold": 0, "jade": 15, "item": 3},
]

static func today() -> String:
	return Time.get_date_string_from_system()

## Rolls a new set of missions when the date changed.
static func ensure(h: Dictionary) -> Dictionary:
	var d: Dictionary = h.get("daily", {})
	if d.get("date", "") != today():
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
	return String(POOL[id][0]) % target(id)

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

# ------------------------------------------------------------- check-in
static func checkin_ready(h: Dictionary) -> bool:
	return Dictionary(h.get("checkin", {})).get("last", "") != today()

## Index (0..6) of the day the next claim gives.
static func checkin_day(h: Dictionary) -> int:
	return int(Dictionary(h.get("checkin", {})).get("n", 0)) % CHECKIN.size()

static func claim_checkin(h: Dictionary) -> Dictionary:
	if not checkin_ready(h):
		return {}
	var day := checkin_day(h)
	var rw: Dictionary = CHECKIN[day].duplicate()
	h.gold = int(h.gold) + int(rw.gold)
	h.jade = int(h.jade) + int(rw.jade)
	if int(rw.item) >= 0:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var slot: String = Items.SLOTS[rng.randi_range(0, Items.SLOTS.size() - 1)]
		var it := Items.make(slot, clampi(1 + int((int(h.level) - 1) / 5.5), 1, 7), int(rw.item), 0)
		h.bag.append(it)
		rw.drop = it
	h.checkin = {"n": int(Dictionary(h.get("checkin", {})).get("n", 0)) + 1, "last": today()}
	return rw

## Things waiting to be collected (hub badge).
static func pending(h: Dictionary) -> int:
	var d := ensure(h)
	var n := 1 if checkin_ready(h) else 0
	for id in d.ids:
		if done(h, id) and not id in d.claimed:
			n += 1
	if chest_ready(h):
		n += 1
	return n
