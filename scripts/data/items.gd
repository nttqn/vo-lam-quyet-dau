class_name Items
extends RefCounted
## Gear: 5 slots × 7 tiers × 5 rarities, upgradable +0..+10.

const SLOTS := ["weapon", "armor", "hat", "boots", "jade"]
const SLOT_NAMES := {"weapon": "Vũ Khí", "armor": "Y Phục", "hat": "Đầu Quan", "boots": "Hài", "jade": "Ngọc Bội"}
const RARITY := ["Phàm", "Tinh", "Bảo", "Thần", "Truyền Thuyết"]
const RARITY_COL := [Color(0.85, 0.85, 0.85), Color(0.45, 0.9, 0.45), Color(0.4, 0.65, 1.0), Color(0.78, 0.45, 1.0), Color(1.0, 0.72, 0.2)]
const RARITY_MULT := [1.0, 1.25, 1.55, 1.9, 2.4]
const TIER_BASE := [8.0, 16.0, 26.0, 38.0, 52.0, 68.0, 86.0]
const MAX_PLUS := 10

const TIER_WORD := ["Mộc", "Đồng", "Thiết", "Cương", "Ngân", "Huyền", "Thiên"]

const WEAPON_NAMES := {
	"staff": "Côn", "sword": "Kiếm", "dual": "Song Kiếm", "palm": "Hộ Thủ", "dagger": "Chủy Thủ",
}
const OTHER_NAMES := {"armor": "Bào", "hat": "Quan", "boots": "Hài", "jade": "Ngọc Bội"}

static func item_name(it: Dictionary, style := "sword") -> String:
	var t: int = int(it.tier) - 1
	var base: String
	if it.slot == "weapon":
		base = WEAPON_NAMES.get(style, "Binh Khí")
	else:
		base = OTHER_NAMES[it.slot]
	var n := "%s %s" % [TIER_WORD[t] + (" " if true else ""), base]
	n = base + " " + TIER_WORD[t]
	if int(it.get("plus", 0)) > 0:
		n += " +%d" % int(it.plus)
	return n

## Stats an item gives.
static func stats(it: Dictionary) -> Dictionary:
	var t: int = clampi(int(it.tier), 1, 7)
	var base: float = TIER_BASE[t - 1] * RARITY_MULT[clampi(int(it.get("rar", 0)), 0, 4)] * (1.0 + 0.08 * int(it.get("plus", 0)))
	match it.slot:
		"weapon":
			return {"atk": round(base)}
		"armor":
			return {"def": round(base * 0.7), "hp": round(base * 6.0)}
		"hat":
			return {"hp": round(base * 5.0), "def": round(base * 0.3)}
		"boots":
			return {"def": round(base * 0.3), "spd": snappedf(minf(0.08, base * 0.0007), 0.001), "crit": snappedf(base * 0.0006, 0.001)}
		"jade":
			return {"qi": round(base * 0.9), "en": snappedf(base * 0.003, 0.01)}
	return {}

static func stat_text(s: Dictionary) -> String:
	var parts := []
	var names := {"atk": "Công", "def": "Thủ", "hp": "Sinh lực", "qi": "Nội công", "spd": "Tốc", "crit": "Bạo kích", "en": "Hồi nội lực"}
	for k in ["atk", "qi", "hp", "def", "spd", "crit", "en"]:
		if s.has(k) and float(s[k]) != 0.0:
			var v: float = s[k]
			if k in ["spd", "crit", "en"]:
				parts.append("%s +%.1f%%" % [names[k], v * 100.0])
			else:
				parts.append("%s +%d" % [names[k], int(v)])
	return "  ".join(parts)

static func price(it: Dictionary) -> int:
	var t: int = int(it.tier)
	var r: float = RARITY_MULT[int(it.get("rar", 0))]
	return int(60.0 * pow(t, 1.7) * r * r / 10.0) * 10

static func sell_price(it: Dictionary) -> int:
	return int(price(it) * 0.3 + upgrade_spent(it) * 0.3)

static func upgrade_cost(it: Dictionary) -> int:
	var p: int = int(it.get("plus", 0))
	return int((p + 1) * 22 * pow(int(it.tier), 1.3) * (1.0 + 0.25 * int(it.get("rar", 0))))

static func upgrade_spent(it: Dictionary) -> int:
	var s := 0
	var c := it.duplicate()
	for p in int(it.get("plus", 0)):
		c.plus = p
		s += upgrade_cost(c)
	return s

static func make(slot: String, tier: int, rar := 0, plus := 0) -> Dictionary:
	return {"slot": slot, "tier": tier, "rar": rar, "plus": plus, "uid": randi()}

static func score(it: Dictionary) -> float:
	var s := stats(it)
	return float(s.get("atk", 0)) * 1.6 + float(s.get("def", 0)) * 1.4 + float(s.get("hp", 0)) * 0.12 + float(s.get("qi", 0)) * 1.3 + float(s.get("spd", 0)) * 400.0 + float(s.get("crit", 0)) * 300.0 + float(s.get("en", 0)) * 200.0

## Combined bonus of a gear set {slot: item}.
static func total(gear: Dictionary) -> Dictionary:
	var out := {}
	for slot in gear:
		var it = gear[slot]
		if it is Dictionary and not it.is_empty():
			var s := stats(it)
			for k in s:
				out[k] = float(out.get(k, 0.0)) + float(s[k])
	return out

## Gear an NPC of this level would wear.
static func npc_gear(level: int, boss: bool, rng: RandomNumberGenerator) -> Dictionary:
	var tier := clampi(1 + int((level - 1) / 5.5), 1, 7)
	var g := {}
	for slot in SLOTS:
		var rar := clampi(int(level / 9.0) + (1 if boss else 0) + (1 if rng.randf() < 0.2 else 0) - 1, 0, 4)
		g[slot] = make(slot, tier, rar, clampi(int(level / 4.0) + (2 if boss else 0), 0, MAX_PLUS))
	return g
