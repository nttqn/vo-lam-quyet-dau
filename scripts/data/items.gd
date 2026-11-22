class_name Items
extends RefCounted
## Gear: 5 slots × 7 tiers × 5 rarities.
## Lò Rèn (forge):
##  - Cường hóa +0..+15: gold + Huyền Thiết. +1..+5 always succeed, then the
##    chance falls; each failure adds Phúc khí (luck) to that item until it
##    succeeds. Failing from +7 up drops one level unless a Hộ Phù is used.
##  - Thăng phẩm: Thiên Tinh Thạch raises the rarity (keeps the +level) and
##    adds one bonus line.
##  - Thuộc tính phụ: one bonus line per rarity step (Tinh 1 … Truyền Thuyết 4),
##    each {k: stat, q: quality 0..1}; Tẩy Luyện Thạch rerolls them.
##  - Phân giải: break a spare item into gold + Huyền Thiết.

const SLOTS := ["weapon", "armor", "hat", "boots", "jade"]
const SLOT_NAMES := {"weapon": "Vũ Khí", "armor": "Y Phục", "hat": "Đầu Quan", "boots": "Hài", "jade": "Ngọc Bội"}
const RARITY := ["Phàm", "Tinh", "Bảo", "Thần", "Truyền Thuyết"]
const RARITY_COL := [Color(0.85, 0.85, 0.85), Color(0.45, 0.9, 0.45), Color(0.4, 0.65, 1.0), Color(0.78, 0.45, 1.0), Color(1.0, 0.72, 0.2)]
const RARITY_MULT := [1.0, 1.25, 1.55, 1.9, 2.4]
const TIER_BASE := [8.0, 16.0, 26.0, 38.0, 52.0, 68.0, 86.0]
const MAX_PLUS := 15
const NPC_MAX_PLUS := 10
## Success chance of going from +i to +i+1.
const RATE := [1.0, 1.0, 1.0, 1.0, 1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.45, 0.4, 0.35, 0.3, 0.25]
const DROP_FROM := 7      # failing at +7 or more loses a level (Hộ Phù prevents it)
const LUCK_STEP := 0.08   # Phúc khí gained per failure
const MAX_RAR := 4

## Bonus line pool: stat -> [low, high]. atk/def/hp/qi scale with the tier's
## base value; crit/spd/en are flat fractions.
const AFF := {
	"atk": [0.15, 0.45], "qi": [0.15, 0.45], "def": [0.12, 0.36], "hp": [1.5, 4.5],
	"crit": [0.01, 0.03], "spd": [0.004, 0.012], "en": [0.02, 0.06],
}
const AFF_FLAT := ["crit", "spd", "en"]
const STAT_NAMES := {"atk": "Công", "def": "Thủ", "hp": "Sinh lực", "qi": "Nội công", "spd": "Tốc", "crit": "Bạo kích", "en": "Hồi nội lực"}

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

## Stat multiplier of a +level: +8% per level to +10, +12% per level after.
static func plus_mult(p: int) -> float:
	return 1.0 + 0.08 * mini(p, 10) + 0.12 * maxi(0, p - 10)

## Main stats only (no bonus lines).
static func base_stats(it: Dictionary) -> Dictionary:
	var t: int = clampi(int(it.tier), 1, 7)
	var base: float = TIER_BASE[t - 1] * RARITY_MULT[clampi(int(it.get("rar", 0)), 0, 4)] * plus_mult(int(it.get("plus", 0)))
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

## Stats an item gives: main stats + bonus lines.
static func stats(it: Dictionary) -> Dictionary:
	var s := base_stats(it)
	for a in it.get("aff", []):
		var k := str(a.k)
		s[k] = float(s.get(k, 0.0)) + aff_value(it, a)
	return s

static func stat_text(s: Dictionary) -> String:
	var parts := []
	for k in ["atk", "qi", "hp", "def", "spd", "crit", "en"]:
		if s.has(k) and float(s[k]) != 0.0:
			parts.append(one_stat(k, float(s[k])))
	return "  ".join(parts)

static func one_stat(k: String, v: float) -> String:
	if k in AFF_FLAT:
		return "%s +%.1f%%" % [STAT_NAMES[k], v * 100.0]
	return "%s +%d" % [STAT_NAMES[k], int(round(v))]

# ------------------------------------------------------------ bonus lines
static func aff_value(it: Dictionary, a: Dictionary) -> float:
	var k := str(a.k)
	if not AFF.has(k):
		return 0.0
	var r: Array = AFF[k]
	var v: float = lerpf(r[0], r[1], clampf(float(a.get("q", 0.5)), 0.0, 1.0))
	if k in AFF_FLAT:
		return snappedf(v, 0.001)
	return round(v * TIER_BASE[clampi(int(it.tier), 1, 7) - 1])

static func aff_text(it: Dictionary, a: Dictionary) -> String:
	return one_stat(str(a.k), aff_value(it, a))

## Colour of a line by its roll: grey / green / blue / purple / gold.
static func aff_color(a: Dictionary) -> Color:
	var q := float(a.get("q", 0.0))
	return RARITY_COL[clampi(int(q * 5.0), 0, 4)]

static func _roll_line(rng: RandomNumberGenerator, taken: Array) -> Dictionary:
	var pool := []
	for k in AFF:
		if not k in taken:
			pool.append(k)
	var k: String = pool[rng.randi_range(0, pool.size() - 1)]
	# slightly bottom-heavy: perfect rolls are a chase
	return {"k": k, "q": snappedf(pow(rng.randf(), 1.35), 0.01)}

## n fresh lines with distinct stats.
static func roll_aff(n: int, rng: RandomNumberGenerator) -> Array:
	var out := []
	var taken := []
	for i in n:
		var l := _roll_line(rng, taken)
		taken.append(l.k)
		out.append(l)
	return out

## Gives an item the bonus lines its rarity is owed (old saves, drops, shop,
## after a rarity raise). Seeded by uid so it is stable.
## Keeps an item inside what the forge can make (edited saves).
static func sanitize(it: Dictionary) -> void:
	if it.is_empty():
		return
	it["tier"] = clampi(int(it.get("tier", 1)), 1, TIER_BASE.size())
	it["rar"] = clampi(int(it.get("rar", 0)), 0, MAX_RAR)
	it["plus"] = clampi(int(it.get("plus", 0)), 0, MAX_PLUS)
	var keep := []
	var taken := []
	for a in it.get("aff", []):
		if a is Dictionary and AFF.has(str(a.get("k", ""))) and not str(a.k) in taken and keep.size() < MAX_RAR:
			taken.append(str(a.k))
			keep.append(a)
	if it.has("aff"):
		it["aff"] = keep

static func ensure_aff(it: Dictionary) -> void:
	if it.is_empty():
		return
	var want := clampi(int(it.get("rar", 0)), 0, MAX_RAR)
	var cur: Array = it.get("aff", [])
	if cur.size() >= want and it.has("aff"):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(it.get("uid", 0)) + ":" + str(cur.size()))
	var taken := []
	for a in cur:
		taken.append(str(a.k))
	while cur.size() < want:
		var l := _roll_line(rng, taken)
		taken.append(l.k)
		cur.append(l)
	it["aff"] = cur

# ---------------------------------------------------------------- forge
static func rate(it: Dictionary) -> float:
	var p := int(it.get("plus", 0))
	if p >= MAX_PLUS:
		return 0.0
	return minf(1.0, RATE[p] + float(it.get("luck", 0.0)))

static func iron_cost(it: Dictionary) -> int:
	var p := int(it.get("plus", 0))
	return int(ceil((p + 1) * (0.6 + 0.4 * int(it.tier))))

static func iron_spent(it: Dictionary) -> int:
	var s := 0
	var c := it.duplicate()
	for p in int(it.get("plus", 0)):
		c.plus = p
		s += iron_cost(c)
	return s

## Rolls one enhancement. Costs must already be paid. Returns
## {ok: bool, from: int, to: int}.
static func enhance(it: Dictionary, use_charm: bool, rng: RandomNumberGenerator) -> Dictionary:
	var p := int(it.get("plus", 0))
	var ok := rng.randf() < rate(it)
	var to := p
	if ok:
		to = p + 1
		it.luck = 0.0
	else:
		it.luck = snappedf(float(it.get("luck", 0.0)) + LUCK_STEP, 0.01)
		if p >= DROP_FROM and not use_charm:
			to = p - 1
	it.plus = to
	return {"ok": ok, "from": p, "to": to}

## Thăng phẩm cost: Thiên Tinh Thạch + gold.
static func ascend_cost(it: Dictionary) -> Dictionary:
	var r := int(it.get("rar", 0))
	var t := int(it.tier)
	var nx := it.duplicate()
	nx.rar = mini(r + 1, MAX_RAR)
	return {"star": (r + 1) * int(ceil(t / 2.0)), "gold": int((price(nx) - price(it)) * 0.6 / 10.0) * 10}

static func ascend(it: Dictionary) -> void:
	it.rar = mini(int(it.get("rar", 0)) + 1, MAX_RAR)
	ensure_aff(it)

## Tẩy luyện cost.
static func wash_cost(it: Dictionary) -> Dictionary:
	return {"wash": maxi(1, int(it.get("rar", 0)) - 1), "gold": 40 * int(it.tier)}

## What breaking an item down gives.
static func salvage(it: Dictionary) -> Dictionary:
	var r := int(it.get("rar", 0))
	var mats := {"iron": 1 + int(it.tier) + r * 2 + int(iron_spent(it) * 0.5)}
	if r >= 3:
		mats["star"] = r - 2
	return {"gold": sell_price(it), "mats": mats}

## Weapon aura level from the +level: 0 none, 1 +7, 2 +10, 3 +13, 4 +15.
static func glow_level(plus: int) -> int:
	if plus >= 15: return 4
	if plus >= 13: return 3
	if plus >= 10: return 2
	if plus >= 7: return 1
	return 0

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

## A hero-owned item: rolled bonus lines included.
static func drop(slot: String, tier: int, rar := 0) -> Dictionary:
	var it := make(slot, tier, rar, 0)
	ensure_aff(it)
	return it

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
	# early foes wear only what a new hero starts with (weapon + armor);
	# extra slots fill in over the first levels
	var n_slots := clampi(2 + int((level - 1) / 3), 2, SLOTS.size())
	for slot in SLOTS.slice(0, n_slots):
		var lucky := 1 if (level >= 6 and rng.randf() < 0.2) else 0
		var rar := clampi(int(level / 9.0) + (1 if boss else 0) + lucky - 1, 0, 4)
		g[slot] = make(slot, tier, rar, clampi(int(level / 4.0) + (2 if boss and level >= 6 else 0), 0, NPC_MAX_PLUS))
	return g

## Painted icon of an item, if the game has one (assets/ui/items/).
## Weapons depend on the sect style: weapon_<style>_<tier>.png
static func icon(it: Dictionary, style := "sword") -> Texture2D:
	var p := "res://assets/ui/items/%s_%d.png" % [("weapon_" + style) if it.slot == "weapon" else str(it.slot), clampi(int(it.tier), 1, 7)]
	return load(p) if ResourceLoader.exists(p) else null
