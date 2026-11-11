class_name Hero
extends RefCounted
## Player character data helpers (the hero itself is a plain Dictionary so it
## serialises straight to JSON).

const MAX_LEVEL := 60
const SKILL_MAX := 5

static func create(name: String, sect_id: String) -> Dictionary:
	var h := {
		"v": 1, "name": name, "sect": sect_id, "level": 1, "exp": 0,
		"pts": {"luc": 0, "than": 0, "noi": 0, "the": 0}, "free_pts": 0,
		"gold": 150, "jade": 5, "skill_pts": 0,
		"skill_lv": [1, 0, 0, 0, 0, 0], "equip": [0, -1, -1],
		"gear": {}, "bag": [],
		"stars": {}, "region": 0,
		"arena_best": 0, "wins": 0, "losses": 0, "fights": 0,
		"color": 0, "created": Time.get_unix_time_from_system(),
		"appearance": Appearance.default_for(sect_id, sect_id == "nga_mi"),
	}
	var s := Sects.get_sect(sect_id)
	h.gear["weapon"] = Items.make("weapon", 1, 0, 0)
	h.gear["armor"] = Items.make("armor", 1, 0, 0)
	return h

static func migrate(d: Dictionary) -> Dictionary:
	var base := create(d.get("name", "Vô Danh"), d.get("sect", "vo_dang"))
	for k in base:
		if not d.has(k):
			d[k] = base[k]
	# JSON numbers come back as floats
	d.level = int(d.level)
	d.exp = int(d.exp)
	d.gold = int(d.gold)
	d.jade = int(d.jade)
	for i in d.skill_lv.size():
		d.skill_lv[i] = int(d.skill_lv[i])
	for i in d.equip.size():
		d.equip[i] = int(d.equip[i])
	return d

static func sect(h: Dictionary) -> Dictionary:
	return Sects.get_sect(h.sect)

static func exp_need(level: int) -> int:
	return 45 + 15 * level + int(0.6 * level * level)

## Returns the number of levels gained.
static func add_exp(h: Dictionary, amt: int) -> int:
	var gained := 0
	h.exp = int(h.exp) + amt
	while int(h.level) < MAX_LEVEL and int(h.exp) >= exp_need(int(h.level)):
		h.exp = int(h.exp) - exp_need(int(h.level))
		h.level = int(h.level) + 1
		h.free_pts = int(h.free_pts) + Build.POINTS_PER_LEVEL
		h.skill_pts = int(h.skill_pts) + 1
		gained += 1
	_unlock_skills(h)
	return gained

static func _unlock_skills(h: Dictionary) -> void:
	var s := sect(h)
	for i in s.skills.size():
		if int(h.skill_lv[i]) == 0 and int(h.level) >= int(s.skills[i].lvl):
			h.skill_lv[i] = 1
			# auto-equip into an empty slot
			for k in 3:
				if int(h.equip[k]) == -1:
					h.equip[k] = i
					break

static func stats(h: Dictionary) -> Dictionary:
	return Build.stats(int(h.level), h.pts, sect(h), Items.total(h.gear))

static func skill_scaled(m: Dictionary, lv: int, book := "") -> Dictionary:
	var c := m.duplicate(true)
	c.dmg = float(m.dmg) * (1.0 + 0.12 * (lv - 1))
	if c.has("heal"):
		c.heal = float(m.heal) * (1.0 + 0.08 * (lv - 1))
	c["lv"] = lv
	return Books.apply(c, book)

static func equipped_skills(h: Dictionary) -> Array:
	var s := sect(h)
	var out := []
	for k in 3:
		var i: int = int(h.equip[k])
		if i >= 0 and int(h.skill_lv[i]) > 0:
			out.append(skill_scaled(s.skills[i], int(h.skill_lv[i]), Books.mod_of(h, i)))
		else:
			out.append(null)
	return out

static func look(h: Dictionary) -> Dictionary:
	var lk: Dictionary = sect(h).look.duplicate()
	var c := int(h.get("color", 0))
	if c > 0:
		var alt := Looks.palette(h.sect, c)
		for k in alt:
			lk[k] = alt[k]
	# better weapons get a gilded trim
	var w: Dictionary = h.gear.get("weapon", {})
	if not w.is_empty() and int(w.get("rar", 0)) >= 3:
		lk["trim"] = Color(0.9, 0.72, 0.3)
	return Appearance.apply(lk, h.get("appearance", {}))

static func side(h: Dictionary) -> Dictionary:
	return {
		"sect": h.sect, "name": h.name, "level": int(h.level),
		"stats": stats(h), "skills": equipped_skills(h), "look": look(h),
	}

static func power(h: Dictionary) -> int:
	return Build.power(stats(h))
