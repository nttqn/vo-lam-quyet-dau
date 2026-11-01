class_name Looks
extends RefCounted
## Costume palettes (hero colour choices) and NPC look generation.

const PALETTES := {
	"thieu_lam": [
		{},
		{"robe": Color(0.55, 0.32, 0.12), "trim": Color(0.85, 0.65, 0.25), "pants": Color(0.4, 0.25, 0.1), "sash": Color(0.85, 0.65, 0.25)},
		{"robe": Color(0.75, 0.15, 0.1), "trim": Color(0.95, 0.75, 0.3), "pants": Color(0.9, 0.55, 0.15), "sash": Color(0.95, 0.75, 0.3)},
	],
	"vo_dang": [
		{},
		{"robe": Color(0.9, 0.9, 0.92), "trim": Color(0.15, 0.15, 0.18), "pants": Color(0.3, 0.3, 0.35), "sash": Color(0.15, 0.15, 0.18)},
		{"robe": Color(0.15, 0.17, 0.22), "trim": Color(0.65, 0.8, 0.95), "pants": Color(0.1, 0.1, 0.14), "sash": Color(0.65, 0.8, 0.95)},
	],
	"nga_mi": [
		{},
		{"robe": Color(0.55, 0.75, 0.9), "trim": Color(0.95, 0.95, 1.0), "pants": Color(0.75, 0.85, 0.95), "sash": Color(0.35, 0.55, 0.85)},
		{"robe": Color(0.75, 0.2, 0.3), "trim": Color(0.98, 0.85, 0.5), "pants": Color(0.95, 0.85, 0.8), "sash": Color(0.98, 0.85, 0.5)},
	],
	"cai_bang": [
		{},
		{"robe": Color(0.3, 0.32, 0.36), "trim": Color(0.75, 0.35, 0.2), "pants": Color(0.25, 0.25, 0.28), "sash": Color(0.75, 0.35, 0.2)},
		{"robe": Color(0.55, 0.25, 0.12), "trim": Color(0.25, 0.4, 0.25), "pants": Color(0.35, 0.22, 0.12), "sash": Color(0.2, 0.35, 0.2)},
	],
	"duong_mon": [
		{},
		{"robe": Color(0.15, 0.25, 0.2), "trim": Color(0.6, 0.85, 0.3), "pants": Color(0.1, 0.14, 0.12), "sash": Color(0.6, 0.85, 0.3)},
		{"robe": Color(0.12, 0.12, 0.14), "trim": Color(0.75, 0.75, 0.8), "pants": Color(0.08, 0.08, 0.1), "sash": Color(0.75, 0.1, 0.1)},
	],
}

const PALETTE_NAMES := ["Môn phục", "Ẩn sĩ", "Hào hiệp"]

static func palette(sect_id: String, i: int) -> Dictionary:
	var list: Array = PALETTES.get(sect_id, [{}])
	return list[clampi(i, 0, list.size() - 1)]

## NPC look: start from the sect, then tint by faction.
static func npc(sect_id: String, faction: String, rng: RandomNumberGenerator) -> Dictionary:
	var lk: Dictionary = Sects.get_sect(sect_id).look.duplicate()
	var alt := palette(sect_id, rng.randi_range(0, 2))
	for k in alt:
		lk[k] = alt[k]
	match faction:
		"bandit":
			lk.robe = Color(0.35, 0.28, 0.22).lerp(Color(0.5, 0.2, 0.15), rng.randf())
			lk.trim = Color(0.2, 0.18, 0.15)
			lk.pants = Color(0.22, 0.2, 0.18)
			lk.sash = Color(0.6, 0.15, 0.1)
			if lk.head_style not in ["bald", "long"]:
				lk.head_style = ["wild", "headband"][rng.randi_range(0, 1)]
			lk.beard = rng.randf() < 0.5
			lk.bulk = rng.randf_range(1.05, 1.2)
		"demon":
			lk.robe = Color(0.12, 0.05, 0.06)
			lk.trim = Color(0.75, 0.1, 0.08)
			lk.pants = Color(0.08, 0.04, 0.05)
			lk.sash = Color(0.75, 0.1, 0.08)
			lk.skin = Color(0.85, 0.72, 0.68)
		"official":
			lk.robe = Color(0.2, 0.3, 0.5)
			lk.trim = Color(0.85, 0.7, 0.3)
			if lk.head_style not in ["bald", "long"]:
				lk.head_style = "crown"
		"wanderer":
			if lk.head_style not in ["bald", "hood"]:
				lk.head_style = "hat"
		"elder":
			lk.hair = Color(0.85, 0.85, 0.85)
			lk.beard = lk.head_style != "long"
		"snow":
			lk.robe = Color(0.85, 0.9, 0.95)
			lk.trim = Color(0.4, 0.6, 0.85)
			lk.pants = Color(0.6, 0.7, 0.82)
	if rng.randf() < 0.3:
		lk.skin = Color(0.93, 0.76, 0.6).darkened(rng.randf_range(0.0, 0.2))
	return lk
