class_name Checkin
extends RefCounted
## Điểm danh: one claim per calendar day (device clock, like Nhiệm Vụ), a
## 7-day reward cycle that never resets: a missed day just waits.
## h.checkin = {day: last claimed Daily.today(), n: days claimed in total}

## Reward per cycle day; gold "g" is per hero level (g × level + 300).
const CYCLE := [
	{"g": 40},
	{"mats": {"iron": 6}},
	{"jade": 10},
	{"mats": {"wash": 2}, "g": 30},
	{"mats": {"charm": 1, "iron": 4}},
	{"mats": {"star": 2}},
	{"jade": 30, "mats": {"star": 1, "charm": 1}},
]

static func state(h: Dictionary) -> Dictionary:
	if not (h.get("checkin") is Dictionary):
		h.checkin = {"day": "", "n": 0}
	return h.checkin

static func days(h: Dictionary) -> int:
	return int(state(h).get("n", 0))

static func can_claim(h: Dictionary) -> bool:
	return str(state(h).get("day", "")) != Daily.today()

## Index 0..6 of the day that is (or was today) being claimed.
static func cycle_day(h: Dictionary) -> int:
	var n := days(h)
	return n % 7 if can_claim(h) else (n - 1) % 7

## Plain reward {gold, jade, mats} for cycle day i at this hero level.
static func reward(h: Dictionary, i: int) -> Dictionary:
	var c: Dictionary = CYCLE[i]
	var gold := int(c.g) * int(h.level) + 300 if c.has("g") else 0
	return {"gold": gold, "jade": int(c.get("jade", 0)), "mats": Dictionary(c.get("mats", {})).duplicate(), "exp": 0}

## Claims today's reward; {} if already claimed.
static func claim(h: Dictionary) -> Dictionary:
	if not can_claim(h):
		return {}
	var st := state(h)
	var rw := reward(h, int(st.n) % 7)
	st.n = int(st.n) + 1
	st.day = Daily.today()
	h.gold = int(h.gold) + int(rw.gold)
	h.jade = int(h.jade) + int(rw.jade)
	Mats.give(h, rw.mats)
	return rw

## One line, e.g. "1.500 Vàng · 6 Huyền Thiết".
static func text(rw: Dictionary) -> String:
	var parts := []
	if int(rw.get("gold", 0)) > 0:
		parts.append("%s Vàng" % UI.fmt(int(rw.gold)))
	if int(rw.get("jade", 0)) > 0:
		parts.append("%d Ngọc" % int(rw.jade))
	var m: Dictionary = rw.get("mats", {})
	for id in m:
		parts.append("%d %s" % [int(m[id]), Mats.name_of(id)])
	return " · ".join(parts)
