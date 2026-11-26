class_name Dungeon
extends RefCounted
## Phó Bản: three material dungeons × six difficulties. A run is three
## one-round duels in a row (two guards, then the master); HP carries over
## with 25% healed between fights. A clear spends one daily entry, a loss
## costs nothing. A cleared difficulty can be swept (Quét) for the same loot
## without fighting.
## h.dungeon = {date, used, ads, best: {id: highest difficulty cleared (-1 none)}}

const PER_DAY := 4
const AD_MAX := 2
const FIGHTS := 3
const HEAL_BETWEEN := 0.25

const LIST := [
	{"id": "mine", "name": "Hắc Phong Khoáng Động", "mat": "iron", "theme": "night", "col": Color(0.45, 0.55, 0.75),
		"desc": "Mỏ quặng cổ bị bọn Hắc Phong chiếm giữ. Huyền Thiết chất đống trong hang.",
		"guards": ["Khoáng Tặc", "Hắc Phong Đao Khách"], "faction": "bandit",
		"boss": ["Thiết Bối Lão Quái", "cai_bang", "Chủ mỏ"]},
	{"id": "ice", "name": "Hàn Băng Động", "mat": "star", "theme": "snow", "col": Color(0.85, 0.7, 0.35),
		"desc": "Hang băng nghìn năm, nơi sao rơi kết thành Thiên Tinh Thạch.",
		"guards": ["Băng Phách Kiếm Thủ", "Tuyết Sơn Thích Khách"], "faction": "snow",
		"boss": ["Hàn Băng Tiên Tử", "nga_mi", "Chủ động"]},
	{"id": "poison", "name": "Độc Long Cốc", "mat": "wash", "theme": "bamboo", "col": Color(0.35, 0.7, 0.45),
		"desc": "Thung lũng sương độc, suối đá tẩy luyện mọc đầy Tẩy Luyện Thạch.",
		"guards": ["Độc Cốc Đệ Tử", "Xà Hạt Sứ Giả"], "faction": "demon",
		"boss": ["Độc Long Cốc Chủ", "duong_mon", "Cốc chủ"]},
]

## [name, hero level needed]
const DIFFS := [["Sơ Nhập", 1], ["Tiểu Thành", 10], ["Đại Thành", 20], ["Tinh Thông", 30], ["Đăng Phong", 40], ["Hóa Cảnh", 50], ["Tông Sư", 60], ["Phản Phác", 70]]

static func ensure(h: Dictionary) -> Dictionary:
	var d: Dictionary = h.get("dungeon", {})
	if not d.has("best"):
		d["best"] = {}
	var c := Daily.cmp(str(d.get("date", "")), Daily.today())
	if c > 0:
		d["date"] = Daily.today()   # ran ahead: keep what that day used
	elif c < 0:
		d["date"] = Daily.today()
		d["used"] = 0
		d["ads"] = 0
	h.dungeon = d
	return d

static func left(h: Dictionary) -> int:
	var d := ensure(h)
	return maxi(0, PER_DAY + int(d.ads) - int(d.used))

static func can_ad(h: Dictionary) -> bool:
	return int(ensure(h).ads) < AD_MAX

static func add_ad_entry(h: Dictionary) -> void:
	var d := ensure(h)
	d.ads = int(d.ads) + 1

static func best(h: Dictionary, i: int) -> int:
	return int(Dictionary(ensure(h).best).get(LIST[i].id, -1))

static func unlocked(h: Dictionary, i: int, diff: int) -> bool:
	return int(h.level) >= int(DIFFS[diff][1]) and (diff == 0 or best(h, i) >= diff - 1)

static func foe_level(diff: int, k: int) -> int:
	return maxi(2, int(DIFFS[diff][1]) + 1) + (1 if k == FIGHTS - 1 else 0)

## Opponent k (0, 1 guards; 2 master) of a run.
static func side(i: int, diff: int, k: int) -> Dictionary:
	var dg: Dictionary = LIST[i]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5300 + i * 977 + diff * 131 + k * 17
	var ai := clampf(0.25 + 0.1 * diff + 0.05 * k, 0.2, 0.9)
	var lvl := foe_level(diff, k)
	if k == FIGHTS - 1:
		var b: Array = dg.boss
		return Npc.side(b[1], lvl, b[0], ai + 0.05, "elder", true, rng.randi(), L.f("%s · %s", [b[2], DIFFS[diff][0]]))
	var sects := []
	for id in Sects.IDS:
		if not id in Sects.HIDDEN:
			sects.append(id)
	var sect_id: String = sects[rng.randi_range(0, sects.size() - 1)]
	var gname: String = dg.guards[k % dg.guards.size()]
	return Npc.side(sect_id, lvl, gname, ai, dg.faction, false, rng.randi(), L.f("Ải %d/%d", [k + 1, FIGHTS]))

## Main material yield of a clear.
static func main_amount(mat: String, diff: int) -> int:
	if mat == "iron":
		return 8 + 6 * diff
	return 1 + int(diff * 0.6)

## Loot of one clear (fight or sweep). first = first clear of that difficulty.
static func rewards(h: Dictionary, i: int, diff: int, first: bool, rng: RandomNumberGenerator) -> Dictionary:
	var dg: Dictionary = LIST[i]
	var mats := {dg.mat: main_amount(dg.mat, diff)}
	# a chance at something extra
	var r := rng.randf()
	if r < 0.12:
		mats["charm"] = int(mats.get("charm", 0)) + 1
	elif r < 0.4:
		var others := []
		for id in ["iron", "star", "wash"]:
			if id != dg.mat:
				others.append(id)
		var o: String = others[rng.randi_range(0, others.size() - 1)]
		mats[o] = int(mats.get(o, 0)) + maxi(1, main_amount(o, diff) / 3)
	var lvl := foe_level(diff, FIGHTS - 1)
	return {"mats": mats, "gold": 40 + 35 * diff, "exp": 30 + 12 * lvl, "jade": (5 + 2 * diff) if first else 0}

## Records a clear: spends an entry, raises best. Returns false with no entry.
static func record_clear(h: Dictionary, i: int, diff: int) -> bool:
	if left(h) <= 0:
		return false
	var d := ensure(h)
	d.used = int(d.used) + 1
	if diff > best(h, i):
		d.best[LIST[i].id] = diff
	return true

## What the info panel lists: main material and the extra chances.
static func loot_text(i: int, diff: int) -> String:
	var dg: Dictionary = LIST[i]
	return L.f("%s ×%d  ·  có thể rơi thêm nguyên liệu khác, Hộ Phù", [Mats.name_of(dg.mat), main_amount(dg.mat, diff)])
