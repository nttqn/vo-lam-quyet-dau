class_name Build
extends RefCounted
## Character stat formulas shared by the hero and generated opponents.

const POINTS_PER_LEVEL := 4
const BASE_ATTR := 5

static func attrs(level: int, pts: Dictionary, sect: Dictionary) -> Dictionary:
	var b: Dictionary = sect.bias
	var out := {}
	for k in ["luc", "than", "noi", "the"]:
		out[k] = BASE_ATTR + int(b.get(k, 0)) + int(pts.get(k, 0))
	return out

static func stats(level: int, pts: Dictionary, sect: Dictionary, gear: Dictionary = {}) -> Dictionary:
	var a := attrs(level, pts, sect)
	var g := func(k: String) -> float: return float(gear.get(k, 0.0))
	return {
		"hp_max": 460.0 + level * 48.0 + a.the * 22.0 + g.call("hp"),
		"atk": 22.0 + level * 3.2 + a.luc * 3.2 + g.call("atk"),
		"def": 14.0 + level * 2.5 + a.the * 1.2 + g.call("def"),
		"qi": 22.0 + level * 3.2 + a.noi * 3.4 + g.call("qi"),
		"spd": 1.0 + minf(0.16, a.than * 0.004) + g.call("spd"),
		"crit": minf(0.4, 0.04 + a.than * 0.004 + g.call("crit")),
		"en_gain": 1.0 + a.noi * 0.01 + g.call("en"),
		"heal_mult": 1.0 + a.noi * 0.006,
	}

## Highest power a real hero of this level can show, with margin: every slot
## Thiên Truyền Thuyết +15 with four perfect bonus lines is ~6,640 at 60 and
## ~7,420 at 80. Anything above is an edited save: it is kept off the boards and
## Tỉ Võ, and firestore.rules (goodRank, goodDuel) refuses it with the SAME
## formula. Raise both together if gear or stats ever grow.
## Low levels also get 160 × level + 1900 (1.3.0): gear tier follows story
## progress, and progress forces levels, so a lv2 hero tops out near 1,500 even
## with legendary +15 tier-3 gear in every slot (tool: cheat_check). A lv2 hero
## at 2,664 had slipped under the flat cap. The two lines cross near level 28.
static func max_power(level: int) -> int:
	return mini(45 * level + 5200, 160 * level + 1900)

## False for a shadow from an edited save: its power, recomputed from the
## snapshot stats (the rules can only check the plain power field), is above
## what a real hero of that level can reach. Such shadows are never fought.
static func shadow_ok(doc: Dictionary) -> bool:
	if doc.get("bot", false):
		return true
	var snap = JSON.parse_string(str(doc.get("data", "")))
	if not snap is Dictionary or not snap.get("stats") is Dictionary:
		return false
	var lv := int(snap.get("level", 1))
	if lv < 1 or lv > Hero.MAX_LEVEL:
		return false
	var st: Dictionary = snap.stats
	for k in ["hp_max", "atk", "def", "qi", "spd", "crit"]:
		if not st.has(k):
			return false
	if float(st.get("en_gain", 1.0)) > 8.0 or float(st.get("heal_mult", 1.0)) > 4.0:
		return false
	var mx := Build.max_power(lv)
	return Build.power(st) <= mx and int(doc.get("power", 0)) <= mx

static func power(st: Dictionary) -> int:
	return int(st.hp_max * 0.12 + st.atk * 1.6 + st.def * 1.4 + st.qi * 1.3 + (st.spd - 1.0) * 400.0 + st.crit * 300.0)

## Auto-distribute points for AI opponents following the sect's bias.
static func auto_points(level: int, sect: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var pts := {"luc": 0, "than": 0, "noi": 0, "the": 0}
	var total := (level - 1) * POINTS_PER_LEVEL
	var b: Dictionary = sect.bias
	var w := {}
	var sum := 0.0
	for k in pts:
		w[k] = maxf(0.5, 2.0 + float(b.get(k, 0)))
		sum += w[k]
	for i in total:
		var r := rng.randf() * sum
		for k in pts:
			r -= w[k]
			if r <= 0.0:
				pts[k] += 1
				break
	return pts
