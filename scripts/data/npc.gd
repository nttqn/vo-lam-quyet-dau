class_name Npc
extends RefCounted
## Builds fight-side configs for computer opponents.

static func side(sect_id: String, level: int, name: String, ai: float, faction := "", boss := false, seed_ := 0, title := "") -> Dictionary:
	var s := Sects.get_sect(sect_id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ if seed_ != 0 else randi()
	var pts := Build.auto_points(level, s, rng)
	var st := Build.stats(level, pts, s, Items.total(Items.npc_gear(level, boss, rng)))
	if boss:
		st.hp_max *= 1.25
	var sk := []
	var avail := []
	for i in s.skills.size():
		var m: Dictionary = s.skills[i]
		if int(m.lvl) <= level and not m.get("ult", false):
			avail.append(i)
	avail.shuffle()
	for i in avail.slice(0, 2 if not boss else 3):
		sk.append(Hero.skill_scaled(s.skills[i], clampi(1 + level / 10, 1, Hero.SKILL_MAX)))
	if (boss or level >= 30) and level >= int(s.skills[5].lvl):
		if sk.size() >= 3:
			sk[2] = Hero.skill_scaled(s.skills[5], clampi(1 + level / 10, 1, Hero.SKILL_MAX))
		else:
			sk.append(Hero.skill_scaled(s.skills[5], 1))
	while sk.size() < 3:
		sk.append(null)
	return {
		"sect": sect_id, "name": name, "title": title, "level": level, "stats": st,
		"skills": sk, "look": Looks.npc(sect_id, faction, rng), "ai": ai, "boss": boss,
	}
