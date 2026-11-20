class_name Titles
extends RefCounted
## Danh hiệu: earned by milestones, one worn at a time (h.title = id, "" = none).
## Earned ids stick in h.titles once met, so a new Tỉ Võ season or a reset
## never takes one away. Only the id travels to the rank board; the name is
## looked up here, so no player text is involved.

## id -> [name, colour, how to earn it]
const LIST := {
	"tan_hiep": ["Tân Hiệp Khách", Color(0.75, 0.9, 0.75), "Đạt cấp 10"],
	"chuyen_can": ["Chuyên Cần", Color(0.6, 0.85, 1.0), "Điểm danh đủ 30 ngày"],
	"giang_ho": ["Danh Chấn Giang Hồ", Color(1.0, 0.8, 0.4), "Hạ Vô Danh Lão Nhân trên Thiên Trụ Phong"],
	"nguyet_cung": ["Phá Nguyệt Cung", Color(0.75, 0.8, 1.0), "Hạ Nguyệt Cung Chủ ở Nguyệt Ảnh Cốc"],
	"ac_mong": ["Ác Mộng Hành Giả", Color(0.85, 0.6, 1.0), "Hạ một thủ lĩnh Ác Mộng"],
	"ac_mong_chu": ["Chúa Tể Ác Mộng", Color(0.95, 0.45, 1.0), "Hạ cả 8 thủ lĩnh Ác Mộng"],
	"thap_chu": ["Thủ Tháp Nhân", Color(0.7, 0.6, 1.0), "Vượt tầng 30 Tháp Thí Luyện"],
	"thap_vuong": ["Tháp Vương", Color(0.85, 0.5, 1.0), "Vượt tầng 60 Tháp Thí Luyện"],
	"loi_dai": ["Lôi Đài Bá Chủ", Color(1.0, 0.6, 0.3), "Thắng liền 20 trận Lôi Đài"],
	"tong_su": ["Tông Sư Tỉ Võ", Color(1.0, 0.55, 0.25), "Đạt 1.400 điểm Tỉ Võ trong một mùa"],
	"diet_ma": ["Diệt Ma Anh Hùng", Color(1.0, 0.4, 0.4), "Gây 20.000 sát thương lên Boss Thế Giới trong một ngày"],
	"than_binh": ["Thần Binh Chủ", Color(1.0, 0.85, 0.3), "Cường hóa một món trang bị lên +15"],
	"bach_chien": ["Bách Chiến Bách Thắng", Color(1.0, 0.7, 0.5), "Thắng tổng cộng 300 trận"],
}

static func met(h: Dictionary, id: String) -> bool:
	match id:
		"tan_hiep": return int(h.level) >= 10
		"chuyen_can": return Checkin.days(h) >= 30
		"giang_ho": return Dictionary(h.get("stars", {})).has("6_5")
		"nguyet_cung": return Dictionary(h.get("stars", {})).has("7_5")
		"ac_mong": return Journey.nm_bosses(h) >= 1
		"ac_mong_chu": return Journey.nm_bosses(h) >= Journey.REGIONS.size()
		"thap_chu": return Tower.best(h) >= 30
		"thap_vuong": return Tower.best(h) >= 60
		"loi_dai": return int(h.get("arena_best", 0)) >= 20
		"tong_su":
			var d: Dictionary = h.get("duel", {})
			return maxi(int(d.get("score", 0)), int(d.get("last_score", 0))) >= 1400
		"diet_ma":
			var w: Dictionary = h.get("wboss", {})
			return maxi(int(w.get("dmg", 0)), int(w.get("best", 0))) >= 20000
		"than_binh": return Achieve.max_plus(h) >= 15
		"bach_chien": return int(h.get("wins", 0)) >= 300
	return false

## Adds newly met titles to h.titles; returns their ids.
static func refresh(h: Dictionary) -> Array:
	if not (h.get("titles") is Array):
		h.titles = []
	var got: Array = h.titles
	var fresh := []
	for id in LIST:
		if not id in got and met(h, id):
			got.append(id)
			fresh.append(id)
	return fresh

static func owned(h: Dictionary) -> Array:
	refresh(h)
	return h.titles

static func name_of(id) -> String:
	return str(LIST[id][0]) if LIST.has(str(id)) else ""

static func color(id) -> Color:
	return LIST[id][1] if LIST.has(str(id)) else UI.PAPER

## The worn title's id ("" if none or not owned any more).
static func worn(h: Dictionary) -> String:
	var id := str(h.get("title", ""))
	return id if LIST.has(id) and id in owned(h) else ""

static func wear(h: Dictionary, id: String) -> void:
	h.title = id if (id == "" or id in owned(h)) else ""
