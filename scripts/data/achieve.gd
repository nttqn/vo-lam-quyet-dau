class_name Achieve
extends RefCounted
## Thành tựu: lines of tiered goals; each tier claimed once for Ngọc (and gold).
## State in the hero:
##   h.ach    = {line_id: tiers claimed}
##   h.ach_c  = counters the hero data does not keep elsewhere
##              {perfect, ults, combo (best), duels, duel_wins}
## Everything else is read from the hero as it is (level, stars, tower…), so
## heroes from before 1.1.0 find the tiers they already passed ready to claim.

## id -> [title, text with %d (or %s for named tiers), tiers]
const LINES := {
	"level": ["Danh Chấn Giang Hồ", "Đạt cấp %d", [10, 20, 30, 40, 50, 60, 70, 80]],
	"region": ["Hành Hiệp Trượng Nghĩa", "Hạ thủ lĩnh %s", [1, 2, 3, 4, 5, 6, 7, 8]],
	"stars3": ["Tuyệt Thế Phong Thái", "Đạt 3 sao ở %d trận Giang Hồ", [5, 15, 30, 42, 48]],
	"wins": ["Bách Chiến Bách Thắng", "Thắng tổng cộng %d trận", [10, 50, 150, 400, 1000]],
	"perfect": ["Vô Khuyết", "Thắng tuyệt đối %d trận (không mất hiệp)", [5, 25, 100, 300]],
	"combo": ["Liên Hoàn Chiêu", "Đạt liên kích %d đòn trong một trận", [8, 12, 16, 20]],
	"ults": ["Tuyệt Kỹ Kinh Thiên", "Thi triển tuyệt kỹ %d lần", [10, 50, 200, 500]],
	"arena": ["Lôi Đài Bá Chủ", "Thắng liền %d trận Lôi Đài", [5, 10, 20, 30]],
	"tower": ["Đăng Phong Tạo Cực", "Vượt tầng %d Tháp Thí Luyện", [10, 20, 30, 50, 75, 100]],
	"dungeon": ["Phá Trận Phó Bản", "Vượt Phó Bản độ khó %s", [1, 2, 3, 4, 5, 6, 7, 8]],
	"duel": ["Luận Kiếm Thiên Hạ", "Thắng %d trận Tỉ Võ", [5, 25, 100, 300]],
	"forge": ["Thần Binh Lợi Khí", "Cường hóa một món trang bị lên +%d", [5, 10, 13, 15]],
	"insight": ["Bách Gia Võ Học", "Ngộ được %d chiêu thức của phái khác", [1, 3, 6]],
	"outfit": ["Phong Lưu Hiệp Khách", "Sở hữu %d bộ Y Phục", [1, 3, 5]],
}
## Ngọc for tier k (0-based), gold = 200 × (k + 1) × the hero's region band.
const JADE := [5, 10, 15, 25, 40, 60, 80, 100]

static func value(h: Dictionary, id: String) -> int:
	var c: Dictionary = h.get("ach_c", {})
	match id:
		"level": return int(h.level)
		"region":
			var n := 0
			for r in Journey.REGIONS.size():
				if Dictionary(h.get("stars", {})).has(Journey.stage_id(r, 5)):
					n += 1
			return n
		"stars3":
			var n := 0
			for k in h.get("stars", {}):
				if int(h.stars[k]) >= 3:
					n += 1
			return n
		"wins": return int(h.get("wins", 0))
		"perfect": return int(c.get("perfect", 0))
		"combo": return int(c.get("combo", 0))
		"ults": return int(c.get("ults", 0))
		"arena": return int(h.get("arena_best", 0))
		"tower": return Tower.best(h)
		"dungeon":
			var b := -1
			for i in Dungeon.LIST.size():
				b = maxi(b, Dungeon.best(h, i))
			return b + 1
		"duel": return int(c.get("duel_wins", 0))
		"forge": return max_plus(h)
		"insight": return Insight.learned(h).size()
		"outfit": return Array(h.get("outfits", [])).size()
	return 0

static func max_plus(h: Dictionary) -> int:
	var m := 0
	for s in h.get("gear", {}):
		if h.gear[s] is Dictionary:
			m = maxi(m, int(h.gear[s].get("plus", 0)))
	for it in h.get("bag", []):
		if it is Dictionary:
			m = maxi(m, int(it.get("plus", 0)))
	return m

static func tiers(id: String) -> Array:
	return LINES[id][2]

static func claimed(h: Dictionary, id: String) -> int:
	return int(Dictionary(h.get("ach", {})).get(id, 0))

## Next tier index to claim, or -1 when the line is complete.
static func next_tier(h: Dictionary, id: String) -> int:
	var k := claimed(h, id)
	return k if k < tiers(id).size() else -1

static func target(id: String, k: int) -> int:
	return int(tiers(id)[k])

static func ready(h: Dictionary, id: String) -> bool:
	var k := next_tier(h, id)
	return k >= 0 and value(h, id) >= target(id, k)

static func text(id: String, k: int) -> String:
	var t: String = LINES[id][1]
	match id:
		"region": return L.f(t, Journey.REGIONS[target(id, k) - 1].name)
		"dungeon": return L.f(t, Dungeon.DIFFS[target(id, k) - 1][0])
	return L.f(t, target(id, k))

static func title(id: String) -> String:
	return LINES[id][0]

static func reward(id: String, k: int) -> Dictionary:
	var tier_n: int = tiers(id).size()
	# lines with few tiers pay like the top of a long line at their last tier
	var j: int = clampi(k + maxi(0, 4 - tier_n), 0, JADE.size() - 1)
	return {"jade": JADE[j], "gold": 200 * (j + 1)}

static func claim(h: Dictionary, id: String) -> Dictionary:
	if not ready(h, id):
		return {}
	var k := next_tier(h, id)
	var rw := reward(id, k)
	var a: Dictionary = h.get("ach", {})
	a[id] = k + 1
	h["ach"] = a
	h.jade = int(h.jade) + int(rw.jade)
	h.gold = int(h.gold) + int(rw.gold)
	return rw

## Claimable tiers right now (badges).
static func pending(h: Dictionary) -> int:
	var n := 0
	for id in LINES:
		if ready(h, id):
			n += 1
	return n

## Done tiers over all tiers, for the header.
static func progress(h: Dictionary) -> Vector2i:
	var done := 0
	var all := 0
	for id in LINES:
		done += claimed(h, id)
		all += tiers(id).size()
	return Vector2i(done, all)

## Counters from a finished fight (Daily.on_fight calls this).
static func on_fight(h: Dictionary, mode: String, res: Dictionary) -> void:
	if mode == "train":
		return
	var c: Dictionary = h.get("ach_c", {})
	c["ults"] = int(c.get("ults", 0)) + int(res.get("ults", 0))
	c["combo"] = maxi(int(c.get("combo", 0)), int(res.get("max_combo", 0)))
	if res.get("won", false) and res.get("perfect", false):
		c["perfect"] = int(c.get("perfect", 0)) + 1
	if mode == "duel":
		c["duels"] = int(c.get("duels", 0)) + 1
		if res.get("won", false):
			c["duel_wins"] = int(c.get("duel_wins", 0)) + 1
	h["ach_c"] = c
