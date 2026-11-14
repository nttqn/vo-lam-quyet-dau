class_name Books
extends RefCounted
## Bí kíp: one book can be bound to each skill, changing how it works.
## h.books = {kind: count}, h.skill_mod = [kind or "" per sect skill].

const KINDS := {
	"manh": ["Mãnh Lực", "Uy lực +25%", 3],
	"toc": ["Tốc Thành", "Hồi chiêu nhanh hơn 25%", 3],
	"tinh": ["Tinh Khí", "Tốn ít nội lực hơn 30%", 3],
	"doc": ["Độc Kinh", "Đòn đánh gây độc", 2],
	"ha": ["Đảo Sơn", "Đòn đánh hất ngã đối thủ", 2],
	"pha": ["Phá Giáp", "Đối thủ không thể đỡ", 1],
	"diem": ["Điểm Huyệt", "Đòn đánh điểm huyệt, dễ phong bế đối thủ", 2],
}
const COLOR := {"manh": Color(1, 0.55, 0.35), "toc": Color(0.5, 0.85, 1.0), "tinh": Color(0.55, 1, 0.75),
	"doc": Color(0.6, 1, 0.35), "ha": Color(1, 0.85, 0.35), "pha": Color(0.9, 0.55, 1.0), "diem": Color(1.0, 0.45, 0.6)}
const PRICE := 30   # jade, random book

static func name_of(kind: String) -> String:
	return "Bí kíp " + String(KINDS[kind][0]) if KINDS.has(kind) else ""

static func random_kind(rng: RandomNumberGenerator) -> String:
	var total := 0
	for k in KINDS:
		total += int(KINDS[k][2])
	var r := rng.randi_range(1, total)
	for k in KINDS:
		r -= int(KINDS[k][2])
		if r <= 0:
			return k
	return "manh"

static func give(h: Dictionary, kind: String, n := 1) -> void:
	var b: Dictionary = h.get("books", {})
	b[kind] = int(b.get(kind, 0)) + n
	h.books = b

static func count(h: Dictionary, kind: String) -> int:
	return int(Dictionary(h.get("books", {})).get(kind, 0))

static func mod_of(h: Dictionary, i: int) -> String:
	var m: Array = h.get("skill_mod", [])
	return str(m[i]) if i < m.size() else ""

## Binds a book to skill i (the one there before is lost).
static func bind(h: Dictionary, i: int, kind: String) -> bool:
	if count(h, kind) <= 0:
		return false
	var m: Array = h.get("skill_mod", ["", "", "", "", "", ""])
	while m.size() <= i:
		m.append("")
	m[i] = kind
	h.skill_mod = m
	h.books[kind] = count(h, kind) - 1
	return true

## Skill dictionary with the book's effect applied.
static func apply(m: Dictionary, kind: String) -> Dictionary:
	match kind:
		"manh": m.dmg = float(m.dmg) * 1.25
		"toc": m.cd = int(int(m.cd) * 0.75)
		"tinh": m.cost = int(round(int(m.cost) * 0.7))
		"doc": m.poison = maxf(float(m.get("poison", 0.0)), 0.06)
		"ha": m.kd = true
		"pha": m.unblockable = true
		"diem":
			if str(m.get("seal", "")) == "":
				m.seal = ["tay", "chan", "dan"][Fighter.zone_of(m)]
				m.seal_amt = 55.0
			else:
				m.seal_amt = float(m.get("seal_amt", 75.0)) * 1.4
	if kind != "":
		m["book"] = kind
	return m
