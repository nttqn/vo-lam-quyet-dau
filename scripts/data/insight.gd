class_name Insight
extends RefCounted
## Ngộ chiêu: learning other sects' techniques by reading them in a fight.
## Blocking a foreign skill gives 1 insight point, dodging or countering it 2
## (at most PER_FIGHT per skill per fight). Enough points and the hero "ngộ"
## the skill and can bind ONE foreign skill into a slot, at reduced power.
##   h.insight = {"<sect>:<slot>": points}
##   h.foreign = {"slot": 0..2, "key": "<sect>:<slot>"}  (or {})

const TIERS := [6, 16, 30]      # points for tầng 1 / 2 / 3
const PER_FIGHT := 3
const POWER := 0.85             # not the hero's own school

static func key(sect_id: String, slot: int) -> String:
	return "%s:%d" % [sect_id, slot]

static func parse(k: String) -> Array:
	var p := k.split(":")
	return [p[0], int(p[1])] if p.size() == 2 else ["", -1]

static func skill_of(k: String) -> Dictionary:
	var p := parse(k)
	if not p[0] in Sects.IDS:
		return {}
	var s := Sects.get_sect(p[0])
	return s.skills[p[1]] if p[1] >= 0 and p[1] < s.skills.size() else {}

static func points(h: Dictionary, k: String) -> int:
	return int(Dictionary(h.get("insight", {})).get(k, 0))

## Tầng reached (0 = not learned yet).
static func tier(pts: int) -> int:
	var t := 0
	for need in TIERS:
		if pts >= need:
			t += 1
	return t

static func next_need(pts: int) -> int:
	for need in TIERS:
		if pts < need:
			return need
	return -1

## Adds the points a fight earned ({key: pts}); returns keys newly learned or
## raised a tầng, as [key, tier] pairs.
static func apply(h: Dictionary, gained: Dictionary) -> Array:
	var ins: Dictionary = h.get("insight", {})
	var out := []
	for k in gained:
		if skill_of(k).is_empty():
			continue
		var before := int(ins.get(k, 0))
		var after := before + mini(int(gained[k]), PER_FIGHT)
		ins[k] = after
		if tier(after) > tier(before):
			out.append([k, tier(after)])
	h.insight = ins
	return out

## Learned foreign skills, best first: [[key, tier, pts], ...]
static func learned(h: Dictionary) -> Array:
	var out := []
	var ins: Dictionary = h.get("insight", {})
	for k in ins:
		var t := tier(int(ins[k]))
		if t > 0 and not skill_of(k).is_empty():
			out.append([k, t, int(ins[k])])
	out.sort_custom(func(a, b): return a[2] > b[2])
	return out

## Skills with some progress but not learned yet.
static func progress(h: Dictionary) -> Array:
	var out := []
	var ins: Dictionary = h.get("insight", {})
	for k in ins:
		if tier(int(ins[k])) == 0 and int(ins[k]) > 0 and not skill_of(k).is_empty():
			out.append([k, 0, int(ins[k])])
	out.sort_custom(func(a, b): return a[2] > b[2])
	return out

static func foreign_slot(h: Dictionary) -> int:
	var f: Dictionary = h.get("foreign", {})
	if f.is_empty() or tier(points(h, str(f.get("key", "")))) == 0:
		return -1
	return int(f.get("slot", -1))

static func foreign_key(h: Dictionary) -> String:
	return str(Dictionary(h.get("foreign", {})).get("key", "")) if foreign_slot(h) >= 0 else ""

## Fight-ready dictionary of a learned foreign skill.
static func scaled(k: String, t: int) -> Dictionary:
	var base := skill_of(k)
	if base.is_empty():
		return {}
	var m := Hero.skill_scaled(base, t)
	m.dmg = float(m.dmg) * POWER
	if m.has("heal"):
		m.heal = float(m.heal) * POWER
	m["from"] = parse(k)[0]
	m["foreign"] = true
	return m

## Binds learned skill k into slot (the sect skill there is unequipped).
static func equip(h: Dictionary, k: String, slot: int) -> void:
	h.foreign = {"slot": slot, "key": k}
	h.equip[slot] = -1

static func unequip(h: Dictionary) -> void:
	h.foreign = {}
