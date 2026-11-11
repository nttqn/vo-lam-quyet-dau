class_name Tower
extends RefCounted
## Tháp Thí Luyện: endless floors, each a single-round duel. Every third floor
## has a rule that changes the fight; every tenth is a guardian (boss).
## h.tower = {best: highest floor cleared}

const RULES := {
	"no_skill": ["Phong Ấn Võ Công", "Không được dùng võ công, chỉ quyền cước và binh khí."],
	"time": ["Tốc Chiến", "Hiệp đấu chỉ có 30 giây."],
	"regen": ["Bất Tử Thân", "Đối thủ liên tục hồi sinh lực."],
	"low_hp": ["Trọng Thương", "Bạn vào trận với 60% sinh lực."],
	"giant": ["Cự Nhân", "Đối thủ to lớn: sinh lực ×1,6, uy lực ×1,15."],
	"glass": ["Nhất Kích", "Cả hai chỉ còn một nửa sinh lực."],
}
const RULE_ORDER := ["no_skill", "time", "regen", "low_hp", "giant", "glass"]

static func best(h: Dictionary) -> int:
	return int(Dictionary(h.get("tower", {})).get("best", 0))

static func is_boss(f: int) -> bool:
	return f % 10 == 0

static func rule(f: int) -> String:
	if is_boss(f) or f % 3 != 0:
		return ""
	return RULE_ORDER[(f / 3) % RULE_ORDER.size()]

static func level(f: int) -> int:
	return clampi(1 + int(f * 0.85), 1, 75)

static func side(f: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7700 + f * 131
	var sect_id: String = Sects.IDS[rng.randi_range(0, Sects.IDS.size() - 1)]
	var boss := is_boss(f)
	var first := ["Thạch", "Thiết", "Huyền", "Bạch", "Hắc", "Xích", "Thanh", "Kim", "Ngân", "Ngọc"]
	var last := ["Vệ", "Tướng", "Sứ", "Lão", "Khách", "Tăng", "Đạo Nhân", "Nữ Hiệp", "Cuồng Đồ", "Ẩn Sĩ"]
	var name: String = first[rng.randi_range(0, first.size() - 1)] + " " + last[rng.randi_range(0, last.size() - 1)]
	var title := "Thủ Tháp Tầng %d" % f if boss else "Tầng %d" % f
	var s := Npc.side(sect_id, level(f), name, clampf(0.3 + f * 0.012, 0.3, 0.95), "elder" if boss else "", boss, 9100 + f, title)
	match rule(f):
		"giant":
			s.stats.hp_max *= 1.6
			s.stats.atk *= 1.15
			s.look["height"] = 1.12
			s.look["bulk"] = float(s.look.get("bulk", 1.0)) * 1.15
		"glass":
			s.stats.hp_max *= 0.5
	return s

## First-clear reward of floor f.
static func reward(f: int) -> Dictionary:
	var rw := {"gold": 30 + 10 * f, "exp": 20 + 8 * f, "jade": 3 if f % 5 == 0 else 0, "item": -1}
	if is_boss(f):
		rw.item = 3 if f >= 30 else 2
		rw.jade = 6
	return rw
