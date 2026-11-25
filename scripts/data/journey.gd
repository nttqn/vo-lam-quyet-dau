class_name Journey
extends RefCounted
## Story map: 7 regions × 6 duels (the 6th is the region boss).

const REGIONS := [
	{"name": "Thiếu Thất Sơn Cước", "theme": "temple", "lvl": 1, "faction": "bandit",
		"intro": "Chân núi Thiếu Thất, sơn tặc hoành hành. Bước chân đầu tiên của kẻ hành hiệp.",
		"foes": [
			["Lưu Tam", "Sơn tặc lâu la", "cai_bang"],
			["Mạnh Thiết Ngưu", "Lực sĩ trại Hắc Phong", "thieu_lam"],
			["Hồ Lão Lục", "Đao phỉ", "vo_dang"],
			["Tiêu Phi Yến", "Nữ tặc khinh công", "nga_mi"],
			["Đồ Bách Xuyên", "Quân sư sơn trại", "duong_mon"],
			["Hắc Phong Trại Chủ", "Lôi Bưu", "cai_bang"],
		]},
	{"name": "Trúc Lâm Thâm Xứ", "theme": "bamboo", "lvl": 6, "faction": "wanderer",
		"intro": "Rừng trúc mờ sương, nơi các lãng khách ẩn mình thử kiếm.",
		"foes": [
			["Mục Thanh Phong", "Kiếm khách lang thang", "vo_dang"],
			["Diệp Trúc Quân", "Ẩn sĩ rừng trúc", "nga_mi"],
			["Viên Đại Thạch", "Tiều phu thần lực", "thieu_lam"],
			["Kha Ảnh", "Thích khách vô danh", "duong_mon"],
			["Tửu Cuồng Tống Tứ", "Túy hiệp", "cai_bang"],
			["Trúc Lâm Lão Nhân", "Bích Ngọc Tiêu", "vo_dang"],
		]},
	{"name": "Trường Giang Độ Khẩu", "theme": "river", "lvl": 11, "faction": "official",
		"intro": "Bến sông tấp nập thuyền buôn. Quan binh và thủy tặc tranh giành đường thủy.",
		"foes": [
			["Lý Lãng", "Thủy tặc", "duong_mon"],
			["Châu Bảo Thủy", "Tiêu sư", "cai_bang"],
			["Hà Tĩnh Ba", "Nữ hiệp đò ngang", "nga_mi"],
			["Tổng Bổ Đầu Vương", "Thiết Diện", "vo_dang"],
			["Long Vương Hồ Thanh", "Thủy trại phó chủ", "thieu_lam"],
			["Trường Giang Long Vương", "Cao Hải Lãng", "cai_bang"],
		]},
	{"name": "Thiên Sơn Tuyết Lĩnh", "theme": "snow", "lvl": 16, "faction": "snow",
		"intro": "Đỉnh tuyết quanh năm giá lạnh, tu luyện nội công phải vượt qua cái lạnh thấu xương.",
		"foes": [
			["Bạch Tuyết Hành", "Đệ tử Thiên Sơn", "nga_mi"],
			["Băng Phách Tẩu", "Lão quái băng sơn", "thieu_lam"],
			["Hàn Mai", "Hàn Mai kiếm", "vo_dang"],
			["Tuyết Lang Đồ Chiến", "Thợ săn tuyết", "cai_bang"],
			["Ảnh Băng", "Sát thủ tuyết", "duong_mon"],
			["Tuyết Sơn Thánh Mẫu", "Băng Hồn", "nga_mi"],
		]},
	{"name": "Đại Mạc Cô Thành", "theme": "desert", "lvl": 21, "faction": "bandit",
		"intro": "Cát vàng mênh mông, thành cổ hoang phế. Mã tặc và độc nhân chiếm cứ.",
		"foes": [
			["Sa Mạc Lang", "Mã tặc", "cai_bang"],
			["Hoàng Sa Khách", "Đao khách sa mạc", "vo_dang"],
			["Độc Hạt Tử", "Kẻ nuôi bò cạp", "duong_mon"],
			["Thiết Đà", "Lạc đà quái nhân", "thieu_lam"],
			["Lâu Lan Vũ Cơ", "Vũ nữ cô thành", "nga_mi"],
			["Đại Mạc Cuồng Đao", "Hạ Hầu Liệt", "cai_bang"],
		]},
	{"name": "Ma Giáo Tổng Đàn", "theme": "demon", "lvl": 26, "faction": "demon",
		"intro": "Hắc Nguyệt Thần Giáo âm mưu thống nhất giang hồ. Phải xông thẳng vào hang ổ.",
		"foes": [
			["Hắc Y Hộ Pháp", "Môn hạ Ma giáo", "duong_mon"],
			["Huyết Thủ", "Đường chủ Huyết Đường", "cai_bang"],
			["U Linh Tiên Tử", "Thánh nữ Ma giáo", "nga_mi"],
			["Thiết La Hán", "Phản đồ Thiếu Lâm", "thieu_lam"],
			["Âm Dương Sứ Giả", "Hộ pháp tả sứ", "vo_dang"],
			["Hắc Nguyệt Giáo Chủ", "Tư Đồ Bá", "duong_mon"],
		]},
	{"name": "Thiên Trụ Phong Luận Võ", "theme": "peak", "lvl": 31, "faction": "elder",
		"intro": "Đỉnh Thiên Trụ mây phủ, nơi quần hùng luận võ định ngôi Thiên Hạ Đệ Nhất.",
		"foes": [
			["Lạc Thiên Hà", "Kiếm Thánh", "vo_dang"],
			["Mạc Tà Y", "Độc Vương", "duong_mon"],
			["Tịnh Tâm Sư Thái", "Thần Ni", "nga_mi"],
			["Thạch Kiên", "Quyền Hoàng", "cai_bang"],
			["Tuệ Viễn Đại Sư", "Phương trượng ẩn thế", "thieu_lam"],
			["Vô Danh Lão Nhân", "Thiên Hạ Đệ Nhất", "vo_dang"],
		]},
	{"name": "Nguyệt Ảnh Cốc", "theme": "night", "lvl": 36, "faction": "demon",
		"intro": "Thung lũng chỉ hiện ra dưới trăng tròn. Tàn dư Hắc Nguyệt tụ về đây quanh một chủ nhân mới.",
		"foes": [
			["Dạ Xoa Lục", "Ám vệ Nguyệt Cung", "duong_mon"],
			["Mộng Điệp", "Nữ sứ mê hồn", "nga_mi"],
			["Lê Thiết Quyền", "Võ sư phương Nam lạc bước", "vovinam"],
			["Phá Giới Tăng", "Tăng nhân bị trục xuất", "thieu_lam"],
			["Nguyệt Ảnh Kiếm", "Tả hộ pháp Nguyệt Cung", "vo_dang"],
			["Nguyệt Cung Chủ", "Hàn Nguyệt Cơ", "nga_mi"],
		]},
]

# ------------------------------------------------------------- Ác Mộng
## The story duels replayed at level 30-60 once the region's boss has fallen.
## Stars in h.nstars (same "r_s" ids as h.stars).
const NM_MIN_LEVEL := 30
const NM_TINT := Color(0.82, 0.72, 0.9)

static func nm_level(r: int, s: int) -> int:
	return mini(Hero.MAX_LEVEL, NM_MIN_LEVEL + r * 4 + int(round(s * 0.6)))

static func nm_ai(r: int, s: int) -> float:
	# sim (tools/nm_check.gd): +0.2 up to 0.98 made bosses ~0% for an equally geared hero
	return minf(0.72, 0.5 + r * 0.025 + s * 0.01 + (0.02 if s == 5 else 0.0))

static func nm_stars(h: Dictionary, r: int, s: int) -> int:
	return int(Dictionary(h.get("nstars", {})).get(stage_id(r, s), 0))

## Why an Ác Mộng duel is closed ("" = open).
static func nm_lock(h: Dictionary, r: int, s: int) -> String:
	if int(h.level) < NM_MIN_LEVEL:
		return L.f("Cấp %d mở Ác Mộng", NM_MIN_LEVEL)
	if not Dictionary(h.get("stars", {})).has(stage_id(r, 5)):
		return "Hạ thủ lĩnh vùng này trước"
	if s > 0 and nm_stars(h, r, s - 1) == 0:
		return "Thắng trận trước ở Ác Mộng"
	return ""

static func nm_region_open(h: Dictionary, r: int) -> bool:
	return nm_lock(h, r, 0) == ""

static func nm_region_stars(h: Dictionary, r: int) -> int:
	var t := 0
	for s in 6:
		t += nm_stars(h, r, s)
	return t

## Number of Ác Mộng region bosses beaten.
static func nm_bosses(h: Dictionary) -> int:
	var n := 0
	for r in REGIONS.size():
		if nm_stars(h, r, 5) > 0:
			n += 1
	return n

static func nm_side(r: int, s: int) -> Dictionary:
	var reg: Dictionary = REGIONS[r]
	var foe: Array = reg.foes[s]
	var boss := s == 5
	# regular gear even for the boss (boss gear + ×1.25 HP was unbeatable at 0.85 AI)
	var side := Npc.side(foe[2], nm_level(r, s), foe[0], nm_ai(r, s), reg.faction, false, 5000 + r * 10 + s, L.f("Ác Mộng · %s", str(foe[1])))
	side.look["tint"] = NM_TINT
	if boss:
		side.boss = true
		side.look["height"] = 1.06
	return side

static func nm_rewards(r: int, s: int, first: bool, stars: int) -> Dictionary:
	var lvl := nm_level(r, s)
	var boss := s == 5
	var exp := int((30 + 11 * lvl) * (2.0 if boss else 1.3) * (1.0 if first else 0.45))
	var gold := int((25 + 9 * lvl) * (3.0 if boss else 1.3) * (1.0 if first else 0.5))
	var jade := (6 if boss else 2) if first else 0
	if stars == 3 and first:
		jade += 2
	var mats := {}
	if first:
		mats = {"iron": 6 + r, "wash": 1}
		if boss:
			mats["star"] = 2 + r / 3
			mats["charm"] = 1
	elif randf() < 0.35:
		mats = {"iron": 2 + r / 2}
	return {"exp": exp, "gold": gold, "jade": jade, "mats": mats}

## Ác Mộng boss first-clear gear: higher tier and rarity than the story drop.
static func nm_boss_drop(r: int, slot_rng: RandomNumberGenerator) -> Dictionary:
	var slot: String = Items.SLOTS[slot_rng.randi_range(0, Items.SLOTS.size() - 1)]
	return Items.drop(slot, clampi(r + 4, 1, 7), clampi(2 + r / 3, 1, 4))

static func stage_id(r: int, s: int) -> String:
	return "%d_%d" % [r, s]

static func stage_level(r: int, s: int) -> int:
	if r == 0:
		return [1, 1, 2, 2, 2, 3][s]   # tracks a hero levelling from scratch (double exp here)
	return int(REGIONS[r].lvl) + int(round(s * 0.85))

## AI skill 0..1 for a stage
static func stage_ai(r: int, s: int) -> float:
	if r == 0:
		# tutorial region: slow, rarely blocks; ramps toward the region-2 level
		# (1.3.0: a touch softer, the funnel lost half the players by the 3rd duel)
		return 0.08 + s * 0.03 + (0.04 if s == 5 else 0.0)
	return clampf(0.22 + r * 0.11 + s * 0.025 + (0.08 if s == 5 else 0.0), 0.0, 0.98)

static func stage_side(r: int, s: int) -> Dictionary:
	var reg: Dictionary = REGIONS[r]
	var foe: Array = reg.foes[s]
	var boss := s == 5
	var side := Npc.side(foe[2], stage_level(r, s), foe[0], stage_ai(r, s), reg.faction, boss, 1000 + r * 10 + s, foe[1])
	if boss:
		side.look["bulk"] = float(side.look.get("bulk", 1.0)) * 1.06
		side.look["height"] = 1.04
		if r == 5:
			side.look["trim"] = Color(0.85, 0.15, 0.1)
	return side

static func unlocked(h: Dictionary, r: int, s: int) -> bool:
	if r == 0 and s == 0:
		return true
	if s == 0:
		return h.stars.has(stage_id(r - 1, 5))
	return h.stars.has(stage_id(r, s - 1))

static func region_unlocked(h: Dictionary, r: int) -> bool:
	return unlocked(h, r, 0)

static func region_stars(h: Dictionary, r: int) -> int:
	var t := 0
	for s in 6:
		t += int(h.stars.get(stage_id(r, s), 0))
	return t

## Region 0 pays double experience: one win = level 2, and the hero
## out-levels the first boss instead of meeting it at level 3.
const FIRST_REGION_EXP := 2.0

static func rewards(r: int, s: int, first: bool, stars: int) -> Dictionary:
	var lvl := stage_level(r, s)
	var boss := s == 5
	var exp := int((30 + 11 * lvl) * (1.6 if boss else 1.0) * (1.0 if first else 0.45) * (FIRST_REGION_EXP if r == 0 else 1.0))
	var gold := int((25 + 9 * lvl) * (2.5 if boss else 1.0) * (1.0 if first else 0.5))
	var jade := (3 if boss else 1) if first else 0
	if stars == 3 and first:
		jade += 1
	return {"exp": exp, "gold": gold, "jade": jade}

## Starter gear: the first clears of duels 2 and 4 in region 0 hand over the
## slot a new hero lacks (hat, boots), put on at once. "" = no gift.
static func starter_gift(r: int, s: int) -> String:
	if r != 0:
		return ""
	return {1: "hat", 3: "boots"}.get(s, "")

## Boss first-clear gear drop
static func boss_drop(r: int, slot_rng: RandomNumberGenerator) -> Dictionary:
	var slot: String = Items.SLOTS[slot_rng.randi_range(0, Items.SLOTS.size() - 1)]
	return Items.drop(slot, clampi(r + 2, 1, 7), clampi(1 + r / 2, 1, 4))

## Endless "Lôi Đài" opponent n (0-based) for a hero level.
static func arena_side(hlvl: int, n: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hlvl * 7919 + n * 104729 + int(Time.get_unix_time_from_system() / 86400.0)
	var sect_id: String = Sects.IDS[rng.randi_range(0, Sects.IDS.size() - 1)]
	var lvl := maxi(1, hlvl - 3 + n)
	var first := ["Vương", "Lý", "Trần", "Triệu", "Tôn", "Chu", "Lâm", "Tạ", "Hàn", "Mộ Dung", "Âu Dương", "Công Tôn", "Thượng Quan", "Tư Mã"]
	var last := ["Phong", "Vân", "Hổ", "Long", "Kiếm", "Hàn", "Liệt", "Thanh", "Ngạo", "Tuyết", "Khuê", "Bá", "Thiên", "Dật"]
	var name: String = first[rng.randi_range(0, first.size() - 1)] + " " + last[rng.randi_range(0, last.size() - 1)]
	var factions := ["bandit", "wanderer", "official", "snow", "demon", "elder", ""]
	var boss := (n + 1) % 5 == 0
	return Npc.side(sect_id, lvl, name, clampf(0.35 + n * 0.04, 0.0, 0.95), factions[rng.randi_range(0, factions.size() - 1)], boss, rng.randi(), L.f("Lôi đài thủ #%d", (n + 1)))
