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
		st.hp_max *= 1.25 if level >= 6 else 1.1
	var sk := []
	var avail := []
	for i in s.skills.size():
		var m: Dictionary = s.skills[i]
		if int(m.lvl) <= level and not m.get("ult", false):
			avail.append(i)
	avail.shuffle()
	# tutorial ramp: lvl 1-2 foes fight with basic moves only, lvl 3 gets one
	# skill (a new hero owns one), bosses two; full kit from lvl 4
	var n_sk := (2 if not boss else 3) if level >= 4 else ((1 if level >= 3 else 0) if not boss else 2)
	for i in avail.slice(0, n_sk):
		sk.append(Hero.skill_scaled(s.skills[i], clampi(1 + level / 10, 1, Hero.SKILL_MAX)))
	if (boss or level >= 30) and level >= int(s.skills[5].lvl):
		if sk.size() >= 3:
			sk[2] = Hero.skill_scaled(s.skills[5], clampi(1 + level / 10, 1, Hero.SKILL_MAX))
		else:
			sk.append(Hero.skill_scaled(s.skills[5], 1))
	while sk.size() < 3:
		sk.append(null)
	var nlook := Appearance.apply(Looks.npc(sect_id, faction, rng), random_look(sect_id, rng, faction))
	nlook["wtier"] = clampi(1 + int((level - 1) / 5.5), 1, 7)
	return {
		"sect": sect_id, "name": name, "title": title, "level": level, "stats": st,
		"skills": sk, "look": nlook, "ai": ai, "boss": boss,
	}

static func random_look(sect_id: String, rng: RandomNumberGenerator, faction: String) -> Dictionary:
	var female := rng.randf() < (0.8 if sect_id == "nga_mi" else 0.18)
	var a := Appearance.default_for(sect_id, female)
	a.skin = rng.randi_range(0, 4)
	a.hair_col = 4 if faction == "elder" else (rng.randi_range(0, 3) if rng.randf() < 0.4 else 0)
	a.eye = rng.randi_range(0, 3)
	a.face = rng.randi_range(0, Appearance.FACE_SCALE.size() - 1)
	a.height = rng.randi_range(0, 2)
	if sect_id != "thieu_lam" and rng.randf() < 0.5:
		a.hair = rng.randi_range(0, 3)
	if not female:
		a.beard = rng.randf() < (0.7 if faction in ["bandit", "elder"] else 0.3)
	else:
		a.lip = rng.randi_range(1, 4)
	if faction == "demon":
		a.eye = 5
	return a
