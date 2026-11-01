class_name SkillScreen
extends Screen
## Learn / upgrade / equip sect skills.

var _list: VBoxContainer
var _slots: HBoxContainer

func _ready() -> void:
	_init_ui("bamboo")
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	top_bar("Võ Công", back)
	var v := UI.vbox(10)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 24
	v.offset_right = -24
	v.offset_top = 92
	v.offset_bottom = -16
	ui.add_child(v)
	_slots = UI.hbox(12)
	v.add_child(_slots)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	_list = UI.vbox(8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_list)
	_build()

static func describe(m: Dictionary) -> String:
	var kind: String = m.get("kind", "strike")
	var parts := []
	match kind:
		"strike", "rush":
			var hits: int = m.get("hits", 1)
			parts.append("Cận chiến%s, uy lực %d%%" % [" %d đòn" % hits if hits > 1 else "", int(m.dmg * hits * 100)])
		"proj":
			var n: int = m.proj.get("n", 1)
			parts.append("Đánh xa%s, uy lực %d%%" % [" %d phát" % n if n > 1 else "", int(m.dmg * n * 100)])
		"rain":
			parts.append("Mưa ám khí %d phát, uy lực %d%%" % [int(m.proj.n), int(m.dmg * m.proj.n * 100)])
		"buff":
			var bf: Dictionary = m.buff
			var b := []
			if bf.has("atk"): b.append("Công +%d%%" % int((bf.atk - 1.0) * 100))
			if bf.has("def"): b.append("Thủ +%d%%" % int((bf.def - 1.0) * 100))
			if bf.has("spd"): b.append("Tốc +%d%%" % int((bf.spd - 1.0) * 100))
			if bf.has("armor"): b.append("Bá thể (không bị khựng)")
			if bf.has("regen_en"): b.append("Hồi nội lực nhanh")
			parts.append(", ".join(b) + " trong %ds" % int(bf.t / 60))
		"heal":
			parts.append("Hồi %d%% sinh lực" % int(m.heal * 100))
		"counter":
			parts.append("Thế thủ: đỡ đòn kế tiếp rồi phản kích %d%%" % int(m.dmg * 100))
		"blink":
			parts.append("Thuấn di ra sau lưng đối thủ rồi đánh %d%%" % int(m.dmg * m.get("hits", 1) * 100))
		"leap":
			parts.append("Tung người lên không rồi bổ xuống, uy lực %d%%" % int(m.dmg * 100))
	if m.get("kd", false) or m.get("launch", 0.0) > 0.0:
		parts.append("hất ngã")
	if m.get("unblockable", false):
		parts.append("không thể đỡ")
	if m.get("armor", false):
		parts.append("bá thể khi xuất chiêu")
	if m.get("poison", 0.0) > 0.0:
		parts.append("gây độc")
	if m.get("heal", 0.0) > 0.0 and kind != "heal":
		parts.append("hồi %d%% sinh lực" % int(m.heal * 100))
	return "; ".join(parts) + ".  Nội lực %d · Hồi chiêu %ds" % [int(m.cost), int(m.cd / 60)]

static func up_cost(lv: int) -> int:
	return 120 * lv * lv

func _build() -> void:
	var h := Game.hero
	var s := Hero.sect(h)
	for c in _slots.get_children():
		c.queue_free()
	_slots.add_child(UI.label("Ô chiêu:", 22, UI.GOLD, UI.bold))
	for k in 3:
		var i := int(h.equip[k])
		var t := "%d. %s" % [k + 1, s.skills[i].name if i >= 0 else "(trống)"]
		var l := UI.panel(Color(0.12, 0.08, 0.14, 0.9))
		l.add_child(UI.label(t, 20))
		_slots.add_child(l)
	var spl := UI.label("   Điểm võ công: %d" % int(h.skill_pts), 22, Color(0.6, 1, 0.6) if int(h.skill_pts) > 0 else UI.PAPER, UI.bold)
	_slots.add_child(spl)
	for c in _list.get_children():
		c.queue_free()
	for i in s.skills.size():
		var m: Dictionary = s.skills[i]
		var lv := int(h.skill_lv[i])
		var p := UI.panel(Color(0.07, 0.05, 0.06, 0.9), UI.GOLD if m.get("ult", false) else UI.GOLD_D)
		var row := UI.hbox(12)
		p.add_child(row)
		var info := UI.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var title := "%s%s" % [m.name, ("   Tầng %d/%d" % [lv, Hero.SKILL_MAX]) if lv > 0 else ("   (mở ở cấp %d)" % int(m.lvl))]
		info.add_child(UI.label(title, 24, UI.GOLD if lv > 0 else Color(0.6, 0.58, 0.55), UI.bold))
		var d := UI.label(describe(Hero.skill_scaled(m, maxi(1, lv))), 17, Color(0.88, 0.85, 0.78) if lv > 0 else Color(0.55, 0.53, 0.5))
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(d)
		if lv > 0:
			var eq: int = h.equip.find(i)
			for k in 3:
				var kk := k
				var b := UI.button(str(k + 1), func(): _equip(i, kk), 20)
				b.custom_minimum_size = Vector2(52, 52)
				b.toggle_mode = true
				b.button_pressed = eq == k
				row.add_child(b)
			var cost := up_cost(lv)
			var ub := UI.gold_button("Nâng (%s)" % UI.fmt(cost), func(): _up(i), 18, 150) if lv < Hero.SKILL_MAX else UI.button("Tối đa", func(): pass, 18, 150)
			ub.disabled = lv >= Hero.SKILL_MAX or int(h.skill_pts) < 1 or int(h.gold) < cost
			row.add_child(ub)
		_list.add_child(p)

func _equip(i: int, k: int) -> void:
	var h := Game.hero
	var cur: int = h.equip.find(i)
	if cur == k:
		h.equip[k] = -1
	else:
		if cur >= 0:
			h.equip[cur] = h.equip[k]
		h.equip[k] = i
	Game.save()
	_build()

func _up(i: int) -> void:
	var h := Game.hero
	var lv := int(h.skill_lv[i])
	var cost := up_cost(lv)
	if int(h.skill_pts) < 1 or int(h.gold) < cost or lv >= Hero.SKILL_MAX:
		return
	h.skill_pts = int(h.skill_pts) - 1
	h.gold = int(h.gold) - cost
	h.skill_lv[i] = lv + 1
	Game.sfx("levelup")
	Game.save()
	refresh_wallet()
	_build()

func back() -> void:
	Game.goto(HubScreen.new())
