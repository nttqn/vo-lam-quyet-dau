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
