class_name KyNgo
extends RefCounted
## Kỳ Ngộ (1.5.0): chance meetings on the Hành Tẩu map. One appears each day
## in a region whose boss the hero has beaten, and a won story / Ác Mộng duel
## may bring another (at most MAX_DAY a day, one waiting at a time). Each is
## a single-round duel with its own twist and reward:
##   cao_nhan  Ẩn Thế Cao Nhân of another sect: teaches one of their techniques
##             (INSIGHT Ngộ chiêu points at once) + Ngọc
##   bi_kip    a book thief, Tốc Chiến (30 s): a random Bí kíp + gold
##   bao_tang  a stone guardian, Cự Nhân: Thiên Tinh, Tẩy Luyện, Hộ Phù + Ngọc
##   ma_dau    a demon cultist, Bất Tử Thân (regenerates): lots of exp + Ngọc
## Losing costs nothing; after TRIES losses the stranger leaves.
## h.kn = {day, n (appeared today), cur: {kind, r, sect, slot, seed, name, tries}, done}

const MAX_DAY := 2
const AFTER_WIN := 0.2
const TRIES := 3
const INSIGHT := 8
const REGEN := 0.003          # ma_dau: share of max health regained per second (Tháp's Bất Tử Thân: 0.012)

## kind -> [title, rule, level bonus, ai, faction, weight]
## (tools/kn_check.gd: a hero with NPC gear at AI 0.5 should win roughly half to two thirds)
const KINDS := {
	"cao_nhan": ["Ẩn Thế Cao Nhân", "", 0, 0.5, "elder", 35],
	"bi_kip": ["Kẻ Trộm Bí Kíp", "time", 0, 0.45, "bandit", 25],
	"bao_tang": ["Canh Giữ Bảo Tàng", "giant", 0, 0.45, "", 20],
	"ma_dau": ["Ma Đầu Luyện Tà Công", "regen", 0, 0.45, "demon", 20],
}
const NAMES := {
	"cao_nhan": ["Thanh Phong Ẩn Sĩ", "Bạch Vân Lão Nhân", "Tùng Hạc Cư Sĩ", "Lãnh Nguyệt Sư Thái", "Mộc Thạch Đạo Nhân", "Vân Du Lão Tăng"],
	"bi_kip": ["Hắc Thử", "Phi Hồ", "Quỷ Ảnh", "Tiểu Yến Tử", "Độc Nhãn Long", "Xích Cước Tặc"],
	"bao_tang": ["Thạch Tướng", "Đồng Nhân Thủ Hộ", "Thiết Giáp Vệ", "Kim Thân Thạch Vệ"],
	"ma_dau": ["Huyết Thủ Ma", "Âm Sát Lão Quái", "Cuồng Đao Ma", "Lệ Quỷ", "Hắc Sát Ma Quân", "Thiên Ma Cuồng Nhân"],
}

static func ensure(h: Dictionary) -> Dictionary:
	var k: Dictionary = h.get("kn", {})
	if k.is_empty():
		k = {"day": "", "n": 0, "cur": {}, "done": 0}
	var c := Daily.cmp(str(k.get("day", "")), Daily.today())
	if c > 0:
		k["day"] = Daily.today()
	elif c < 0:
		k["day"] = Daily.today()
		k["n"] = 0
	h.kn = k
	return k

## Regions whose boss is down: where strangers turn up.
static func regions(h: Dictionary) -> Array:
	var out := []
	for r in Journey.REGIONS.size():
		if Dictionary(h.get("stars", {})).has(Journey.stage_id(r, 5)):
			out.append(r)
	return out

static func unlocked(h: Dictionary) -> bool:
	return not regions(h).is_empty()

static func current(h: Dictionary) -> Dictionary:
	return ensure(h).cur

## The day's first stranger (hub / map open). Returns true if one appeared.
static func daily(h: Dictionary) -> bool:
	var k := ensure(h)
	if not unlocked(h) or not Dictionary(k.cur).is_empty() or int(k.n) > 0:
		return false
	spawn(h)
	return true

## After a won story duel: sometimes another one. Returns true if one appeared.
static func after_win(h: Dictionary, roll := -1.0) -> bool:
	var k := ensure(h)
	if not unlocked(h) or not Dictionary(k.cur).is_empty() or int(k.n) >= MAX_DAY:
		return false
	if (randf() if roll < 0.0 else roll) >= AFTER_WIN:
		return false
	spawn(h)
	return true

static func spawn(h: Dictionary, kind := "", seed_ := 0) -> Dictionary:
	var k := ensure(h)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ if seed_ != 0 else randi()
	if kind == "":
		var total := 0
		for id in KINDS:
			total += int(KINDS[id][5])
		var roll := rng.randi_range(1, total)
		for id in KINDS:
			roll -= int(KINDS[id][5])
			if roll <= 0:
				kind = id
				break
	var rs := regions(h)
	var r: int = rs[rng.randi_range(0, rs.size() - 1)] if not rs.is_empty() else 0
	var others: Array = Sects.IDS.filter(func(s): return s != str(h.get("sect", "")))
	var sect: String = others[rng.randi_range(0, others.size() - 1)]
	if kind == "bao_tang":
		sect = ["thieu_lam", "cai_bang"][rng.randi_range(0, 1)]   # a heavy, armoured style for a statue
	var names: Array = NAMES[kind]
	var cur := {"kind": kind, "r": r, "sect": sect, "slot": rng.randi_range(0, Hero.ULT - 1),
		"seed": rng.randi(), "name": names[rng.randi_range(0, names.size() - 1)], "tries": 0}
	k.cur = cur
	k.n = int(k.n) + 1
	return cur

static func title(kind: String) -> String:
	return str(KINDS[kind][0]) if KINDS.has(kind) else ""

static func rule(kind: String) -> String:
	return str(KINDS[kind][1]) if KINDS.has(kind) else ""

## The technique a master shows (cao_nhan): "sect:slot" Ngộ chiêu key.
static func insight_key(cur: Dictionary) -> String:
	return Insight.key(str(cur.sect), int(cur.slot))

## Fight side of the stranger.
static func side(h: Dictionary, cur: Dictionary) -> Dictionary:
	var kind := str(cur.kind)
	var kd: Array = KINDS[kind]
	var lvl := mini(Hero.MAX_LEVEL + 5, int(h.level) + int(kd[2]))
	var e := Npc.side(str(cur.sect), lvl, str(cur.name), float(kd[3]), str(kd[4]), false, int(cur.seed), str(kd[0]))
	match kind:
		"cao_nhan":
			# the technique he means to show is always in his hands
			var s := Sects.get_sect(str(cur.sect))
			var m: Dictionary = Hero.skill_scaled(s.skills[int(cur.slot)], clampi(1 + lvl / 10, 1, Hero.SKILL_MAX))
			var have := false
			for x in e.skills.slice(0, 3):
				if x != null and x.name == m.name:
					have = true
			if not have:
				e.skills[0] = m
		"bao_tang":
			# a stone body: lots of health, slow, but its blows are no harder
			e.stats.hp_max *= 1.2
			e.stats.spd *= 0.9
			e.look["height"] = 1.12
			e.look["bulk"] = float(e.look.get("bulk", 1.0)) * 1.2
			e.look["tint"] = Color(0.78, 0.76, 0.7)
		"ma_dau":
			e.look["tint"] = Color(1.0, 0.7, 0.7)
	return e

## Lines before the duel ("" narrator, "@" the hero, "boss" the stranger),
## already translated (they carry names).
static func lines(cur: Dictionary) -> Array:
	match str(cur.kind):
		"cao_nhan":
			var m := Insight.skill_of(insight_key(cur))
			return [
				["", L.t("Bên gốc tùng già, một người áo vải ngồi tĩnh tọa. Chiếc lá rơi chưa chạm đất đã bị chỉ phong chẻ làm đôi.")],
				["boss", L.f("Người trẻ, ta thấy ngươi có căn cơ. Đỡ được chiêu %s của %s, ta sẽ cho ngươi thấy ý cảnh của nó.", [str(m.get("name", "")), Sects.get_sect(str(cur.sect)).name])],
				["@", L.t("Vãn bối xin lĩnh giáo!")],
			]
		"bi_kip":
			return [
				["", L.t("Một bóng đen ôm gói vải vụt qua mái nhà. Trong gói lộ ra góc một cuốn sách cũ.")],
				["boss", L.t("Hắc hắc, bí kíp này ta trộm từ Tàng Thư Các. Muốn lấy lại thì hạ ta trong ba mươi hơi thở!")],
				["@", L.t("Đứng lại!")],
			]
		"bao_tang":
			return [
				["", L.t("Sau thác nước lộ ra một hang đá. Giữa hang là chiếc rương phủ rêu, bên cạnh một pho tượng đá bỗng mở mắt.")],
				["boss", L.t("Kẻ nào… dám… chạm vào bảo vật?")],
				["@", L.t("Thì ra là cơ quan canh giữ. Phá được nó, rương báu là của ta.")],
			]
		"ma_dau":
			return [
				["", L.t("Gió mang mùi máu tanh. Một kẻ tóc rối, mắt đỏ ngầu đứng giữa đám người ngã gục.")],
				["boss", L.t("Ma công của ta sắp đại thành! Thêm một cao thủ nữa là đủ!")],
				["@", L.t("Luyện tà công hại người, hôm nay ngươi gặp phải ta rồi.")],
			]
	return []

## What the meeting promises, for the map card.
static func promise(cur: Dictionary) -> String:
	match str(cur.kind):
		"cao_nhan":
			var m := Insight.skill_of(insight_key(cur))
			return L.f("Thắng: lĩnh ngộ ngay %d điểm chiêu %s (%s), Ngọc.", [INSIGHT, str(m.get("name", "")), Sects.get_sect(str(cur.sect)).name])
		"bi_kip":
			return L.t("Tốc Chiến 30 giây. Thắng: một quyển Bí kíp ngẫu nhiên và vàng.")
		"bao_tang":
			return L.t("Cự Nhân: đối thủ to lớn. Thắng: Thiên Tinh Thạch, Tẩy Luyện Thạch, Hộ Phù, Ngọc.")
		"ma_dau":
			return L.t("Bất Tử Thân: đối thủ liên tục hồi sinh lực. Thắng: rất nhiều kinh nghiệm và Ngọc.")
	return ""

## Rewards of a won meeting (books / insight handled by the caller).
static func rewards(h: Dictionary, kind: String) -> Dictionary:
	var lvl := int(h.level)
	var rw := {"exp": int((30 + 11 * lvl) * 1.5), "gold": 30 + 10 * lvl, "jade": 0}
	match kind:
		"cao_nhan":
			rw.jade = 6
		"bi_kip":
			rw.gold = int(rw.gold) * 2
		"bao_tang":
			rw.jade = 4
			rw["mats"] = {"star": 1, "wash": 2, "charm": 1}
		"ma_dau":
			rw.exp = int(rw.exp) * 2
			rw.jade = 10
	return rw

static func region_name(cur: Dictionary) -> String:
	return Journey.REGIONS[clampi(int(cur.get("r", 0)), 0, Journey.REGIONS.size() - 1)].name
