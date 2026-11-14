class_name SkillScreen
extends Screen
## Learn / upgrade / equip sect skills: illustrated skill cards on the left,
## the selected skill's details and actions on the right.

const PIC := "res://assets/ui/skills/%s_%d.png"

var _sel := 0
var _slots: HBoxContainer
var _grid: GridContainer
var _detail: VBoxContainer

func _ready() -> void:
	_init_ui("bamboo")
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	top_bar("Võ Công", back)
	var root := UI.vbox(10)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_right = -24
	root.offset_top = 88
	root.offset_bottom = -14
	ui.add_child(root)
	_slots = UI.hbox(10)
	root.add_child(_slots)
	var body := UI.hbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	body.add_child(_grid)
	var dp := UI.panel(Color(0.07, 0.05, 0.06, 0.92))
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(dp)
	_detail = UI.vbox(8)
	dp.add_child(_detail)
	var h := Game.hero
	_sel = maxi(0, int(h.equip[0]))
	_build()

static func pic(sect_id: String, i: int) -> Texture2D:
	var p := PIC % [sect_id, i]
	return load(p) if ResourceLoader.exists(p) else null

## Round skill icon (painted, from assets/ui/skills); until a sect's icons
## exist, a disc in the sect colour with the skill's initials.
static func icon(sect: Dictionary, i: int, side: float, dim := false) -> Control:
	var tex := pic(sect.id, i)
	var box := CenterContainer.new()
	box.custom_minimum_size = Vector2(side, side)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex:
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.custom_minimum_size = Vector2(side, side)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if dim:
			r.self_modulate = Color(0.35, 0.35, 0.38)
		box.add_child(r)
		return box
	var col: Color = sect.elem
	var disc := Panel.new()
	disc.custom_minimum_size = Vector2(side, side)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := col.darkened(0.55) if not dim else Color(0.18, 0.17, 0.17)
	disc.add_theme_stylebox_override("panel", UI.box(bg, col if not dim else Color(0.35, 0.33, 0.3), maxi(2, int(side / 30)), int(side / 2), 0))
	box.add_child(disc)
	var words: PackedStringArray = String(sect.skills[i].name).split(" ")
	var ini := ""
	for wd in words.slice(0, 2):
		ini += wd.substr(0, 1)
	var l := UI.label(ini, int(side * 0.36), col.lightened(0.3) if not dim else Color(0.55, 0.53, 0.5), UI.title)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	disc.add_child(l)
	return box

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
	if str(m.get("seal", "")) != "":
		parts.append("điểm huyệt %s" % Fighter.ZONE_NAMES[Fighter.zone_of(m)])
	if m.get("heal", 0.0) > 0.0 and kind != "heal":
		parts.append("hồi %d%% sinh lực" % int(m.heal * 100))
	return "; ".join(parts) + ".  Nội lực %d · Hồi chiêu %ds" % [int(m.cost), int(m.cd / 60)]

static func up_cost(lv: int) -> int:
	return 120 * lv * lv

func _build() -> void:
	var h := Game.hero
	var s := Hero.sect(h)
	# --- equipped slots
	for c in _slots.get_children():
		c.queue_free()
	# (no "Ô chiêu" caption: the numbered chips 1-2-3-TK speak for themselves and the row must fit 16:9)
	var fslot := Insight.foreign_slot(h)
	for k in 3:
		var i := int(h.equip[k])
		if k == fslot:
			var fk := Insight.foreign_key(h)
			var fp := Insight.parse(fk)
			var fsl := UI.panel(Color(0.06, 0.08, 0.12, 0.92), Color(0.55, 0.8, 1.0))
			var fh := UI.hbox(8)
			fsl.add_child(fh)
			fh.add_child(UI.label(str(k + 1), 24, Color(0.6, 0.85, 1.0), UI.title))
			fh.add_child(icon(Sects.get_sect(fp[0]), fp[1], 44))
			fh.add_child(_slot_name(Insight.skill_of(fk).name, Color(0.75, 0.9, 1.0)))
			_slots.add_child(fsl)
			continue
		var slot := UI.panel(Color(0.1, 0.07, 0.09, 0.92), UI.GOLD if i == _sel and i >= 0 else UI.GOLD_D)
		var sh := UI.hbox(8)
		slot.add_child(sh)
		sh.add_child(UI.label(str(k + 1), 24, UI.GOLD, UI.title))
		if i >= 0:
			sh.add_child(icon(s, i, 44))
		sh.add_child(_slot_name(s.skills[i].name if i >= 0 else "(trống)", UI.PAPER if i >= 0 else Color(0.6, 0.58, 0.55)))
		_slots.add_child(slot)
	# fixed Tuyệt Kỹ slot: the ultimate, once learned
	var ul := int(h.skill_lv[Hero.ULT]) > 0
	var us := UI.panel(Color(0.14, 0.1, 0.04, 0.92), UI.GOLD if _sel == Hero.ULT else Color(0.75, 0.55, 0.1))
	var uh := UI.hbox(8)
	us.add_child(uh)
	uh.add_child(UI.label("TK", 22, Color(1.0, 0.8, 0.3), UI.title))
	uh.add_child(icon(s, Hero.ULT, 44, not ul))
	uh.add_child(_slot_name(s.skills[Hero.ULT].name if ul else "Cấp %d" % int(s.skills[Hero.ULT].lvl), UI.PAPER if ul else Color(0.6, 0.58, 0.55)))
	_slots.add_child(us)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots.add_child(sp)
	_slots.add_child(UI.button("Ngộ Chiêu (%d)" % Insight.learned(h).size(), _foreign, 18))
	_slots.add_child(UI.label("%d điểm" % int(h.skill_pts), 22, Color(0.6, 1, 0.6) if int(h.skill_pts) > 0 else UI.PAPER, UI.bold))
	# --- skill cards
	for c in _grid.get_children():
		c.queue_free()
	for i in s.skills.size():
		_grid.add_child(_card(s, i))
	_build_detail(s)

func _card(s: Dictionary, i: int) -> Control:
	var h := Game.hero
	var m: Dictionary = s.skills[i]
	var lv := int(h.skill_lv[i])
	var b := Button.new()
	b.custom_minimum_size = Vector2(224, 214)
	b.focus_mode = Control.FOCUS_NONE
	var border := UI.GOLD if i == _sel else (Color(0.95, 0.55, 0.2) if m.get("ult", false) else UI.GOLD_D)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, UI.box(Color(0.08, 0.06, 0.07, 0.95), border, 4 if i == _sel else 2, 10, 6))
	b.pressed.connect(func():
		Game.sfx("click")
		_sel = i
		_build())
	var v := UI.vbox(4)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6
	v.offset_right = -6
	v.offset_top = 6
	v.offset_bottom = -6
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var img := Control.new()   # icon + badge/lock overlay
	img.custom_minimum_size = Vector2(212, 150)
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := icon(s, i, 140, lv == 0)
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img.add_child(ic)
	v.add_child(img)
	var eq: int = h.equip.find(i)
	var ult_on := i == Hero.ULT and lv > 0
	if eq >= 0 or ult_on:
		var badge := UI.label("TK" if ult_on else str(eq + 1), 22 if not ult_on else 17, UI.INK, UI.title)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_stylebox_override("normal", UI.box(UI.GOLD, UI.INK, 2, 16, 0))
		badge.custom_minimum_size = Vector2(32, 32)
		badge.position = Vector2(176, 4)
		img.add_child(badge)
	if lv == 0:
		var lock := UI.label("Cấp %d" % int(m.lvl), 22, UI.PAPER, UI.bold)
		lock.add_theme_color_override("font_outline_color", Color.BLACK)
		lock.add_theme_constant_override("outline_size", 6)
		lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock.offset_left = -60
		lock.offset_right = 60
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		img.add_child(lock)
	var nm := UI.label(m.name, 17, UI.GOLD if lv > 0 else Color(0.62, 0.6, 0.56), UI.bold)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.clip_text = true
	v.add_child(nm)
	var pp := _pips(lv, 12)
	pp.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(pp)
	return b

func _pips(lv: int, sz: int) -> Control:
	var hb := UI.hbox(4)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in Hero.SKILL_MAX:
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(sz * 2, sz * 0.6)
		d.color = UI.GOLD if k < lv else Color(0.25, 0.22, 0.2)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(d)
	return hb

func _build_detail(s: Dictionary) -> void:
	for c in _detail.get_children():
		c.queue_free()
	var h := Game.hero
	var i := _sel
	var m: Dictionary = s.skills[i]
	var lv := int(h.skill_lv[i])
	var head := UI.hbox(16)
	_detail.add_child(head)
	head.add_child(icon(s, i, 150, lv == 0))
	var hv := UI.vbox(6)
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	var t := UI.heading(m.name, 34)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hv.add_child(t)
	var row := UI.hbox(10)
	hv.add_child(row)
	if m.get("ult", false):
		row.add_child(UI.label("Tuyệt kỹ", 18, Color(1, 0.6, 0.3), UI.bold))
	if lv > 0:
		row.add_child(UI.label("Tầng %d/%d" % [lv, Hero.SKILL_MAX], 18, UI.PAPER, UI.bold))
		row.add_child(_pips(lv, 10))
	else:
		row.add_child(UI.label("Mở khi đạt cấp %d" % int(m.lvl), 18, Color(1, 0.7, 0.5), UI.bold))
	var d := UI.label(describe(Hero.skill_scaled(m, maxi(1, lv), Books.mod_of(h, i))), 18, Color(0.9, 0.87, 0.8))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_child(d)
	if lv == 0:
		return
	var eq: int = h.equip.find(i)
	var er := UI.hbox(8)
	_detail.add_child(er)
	if i == Hero.ULT:
		er.add_child(UI.label("Luôn ở ô TK riêng, không chiếm ô chiêu.", 17, Color(1.0, 0.82, 0.4)))
	else:
		er.add_child(UI.label("Lắp vào ô", 18, UI.GOLD, UI.bold))
	for k in (0 if i == Hero.ULT else 3):
		var kk := k
		var b := UI.button(str(k + 1), func(): _equip(i, kk), 20)
		b.custom_minimum_size = Vector2(52, 48)
		b.toggle_mode = true
		b.button_pressed = eq == k
		er.add_child(b)
	var cost := up_cost(lv)
	var ub: Button
	if lv < Hero.SKILL_MAX:
		ub = UI.gold_button("Nâng tầng  ·  1 điểm + %s vàng" % UI.fmt(cost), func(): _up(i), 18)
		ub.disabled = int(h.skill_pts) < 1 or int(h.gold) < cost
	else:
		ub = UI.button("Đã đạt tầng tối đa", func(): pass, 18)
		ub.disabled = true
	_detail.add_child(ub)
	# bí kíp bound to this skill
	var bk := Books.mod_of(h, i)
	var br := UI.hbox(8)
	_detail.add_child(br)
	var bl := UI.label((Books.name_of(bk) + ": " + Books.KINDS[bk][1]) if bk != "" else "Chưa gắn bí kíp", 17, Books.COLOR.get(bk, Color(0.7, 0.68, 0.62)), UI.bold)
	bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	br.add_child(bl)
	br.add_child(UI.button("Bí kíp", func(): _books(i), 18, 110))

func _books(i: int) -> void:
	var h := Game.hero
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(cc)
	var p := UI.panel()
	cc.add_child(p)
	var v := UI.vbox(8)
	v.custom_minimum_size.x = 620
	p.add_child(v)
	v.add_child(UI.heading("Tàng Kinh Các", 36))
	var note := UI.label("Gắn một bí kíp vào %s. Bí kíp đang gắn (nếu có) sẽ mất." % Hero.sect(h).skills[i].name, 17, Color(0.85, 0.82, 0.75))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)
	for k in Books.KINDS:
		var row := UI.hbox(10)
		v.add_child(row)
		var l := UI.label("%s  ·  %s" % [Books.KINDS[k][0], Books.KINDS[k][1]], 18, Books.COLOR[k], UI.bold)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		row.add_child(UI.label("có %d" % Books.count(h, k), 17, UI.PAPER))
		var kk: String = k
		var b := UI.gold_button("Gắn", func():
			if Books.bind(h, i, kk):
				Game.sfx("skill")
				Game.save()
				dim.queue_free()
				_build(), 18, 90)
		b.disabled = Books.count(h, k) <= 0
		row.add_child(b)
	var hb := UI.hbox(10)
	v.add_child(hb)
	var buy := UI.gold_button("Mua bí kíp ngẫu nhiên (%d Ngọc)" % Books.PRICE, func():
		if int(h.jade) < Books.PRICE:
			return
		h.jade = int(h.jade) - Books.PRICE
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var got := Books.random_kind(rng)
		Books.give(h, got)
		Game.sfx("coin")
		Game.save()
		refresh_wallet()
		dim.queue_free()
		toast("Nhận " + Books.name_of(got), Books.COLOR[got])
		_books(i), 18)
	buy.disabled = int(h.jade) < Books.PRICE
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(buy)
	hb.add_child(UI.button("Đóng", dim.queue_free, 18, 110))

func _equip(i: int, k: int) -> void:
	var h := Game.hero
	if Insight.foreign_slot(h) == k:
		Insight.unequip(h)
	var cur: int = h.equip.find(i)
	if cur == k:
		h.equip[k] = -1
	else:
		if cur >= 0:
			h.equip[cur] = h.equip[k]
		h.equip[k] = i
	Game.save()
	_build()

## Ngộ Chiêu: foreign techniques read in fights; one can be bound to a slot.
func _foreign() -> void:
	var h := Game.hero
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_to_group("modal")
	ui.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(cc)
	var p := UI.panel()
	cc.add_child(p)
	var v := UI.vbox(8)
	v.custom_minimum_size = Vector2(860, 0)
	p.add_child(v)
	var hd := UI.hbox(10)
	v.add_child(hd)
	var tl := UI.heading("Ngộ Chiêu", 36)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(tl)
	hd.add_child(UI.button("Đóng", dim.queue_free, 18, 110))
	var note := UI.label("Đỡ (+1), né hoặc phản (+2) tuyệt chiêu của phái khác để lĩnh ngộ, tối đa +%d mỗi chiêu mỗi trận. Đủ %d điểm ngộ ra chiêu (tầng 2: %d, tầng 3: %d). Chỉ lắp được 1 chiêu ngoại môn, uy lực %d%%; Tuyệt Kỹ không thể học lén." % [Insight.PER_FIGHT, Insight.TIERS[0], Insight.TIERS[1], Insight.TIERS[2], int(Insight.POWER * 100)], 16, Color(0.85, 0.82, 0.75))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 380)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := UI.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	var rows: Array = Insight.learned(h) + Insight.progress(h)
	if rows.is_empty():
		var e := UI.label("Chưa lĩnh ngộ chiêu nào. Hãy đỡ và né tuyệt chiêu của đối thủ khác phái!", 18, Color(0.7, 0.68, 0.62))
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(e)
	var cur := Insight.foreign_key(h)
	for r in rows:
		var k: String = r[0]
		var t: int = r[1]
		var pts: int = r[2]
		var pr := Insight.parse(k)
		var fsect := Sects.get_sect(pr[0])
		var row := UI.panel(Color(0.07, 0.07, 0.1, 0.9), Color(0.55, 0.8, 1.0) if k == cur else UI.GOLD_D)
		list.add_child(row)
		var rh := UI.hbox(10)
		row.add_child(rh)
		rh.add_child(icon(fsect, pr[1], 64, t == 0))
		var info := UI.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rh.add_child(info)
		info.add_child(UI.label("%s  ·  %s" % [Insight.skill_of(k).name, fsect.name], 20, UI.GOLD if t > 0 else Color(0.7, 0.68, 0.62), UI.bold))
		var nxt := Insight.next_need(pts)
		var prog := ("Tầng %d" % t if t > 0 else "Chưa ngộ") + ("  ·  %d/%d điểm" % [pts, nxt] if nxt > 0 else "  ·  viên mãn")
		info.add_child(UI.label(prog, 16, Color(0.75, 0.85, 1.0)))
		if t > 0:
			var d := UI.label(describe(Insight.scaled(k, t)), 15, Color(0.85, 0.82, 0.75))
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.add_child(d)
			var bh := UI.hbox(6)
			rh.add_child(bh)
			for slot in 3:
				var ss := slot
				var b := UI.button(str(slot + 1), func():
					Insight.equip(h, k, ss)
					Game.sfx("skill")
					Game.save()
					dim.queue_free()
					_build(), 18)
				b.custom_minimum_size = Vector2(48, 46)
				b.toggle_mode = true
				b.button_pressed = k == cur and Insight.foreign_slot(h) == slot
				bh.add_child(b)
			if k == cur:
				bh.add_child(UI.button("Gỡ", func():
					Insight.unequip(h)
					Game.save()
					dim.queue_free()
					_build(), 16, 64))

func _up(i: int) -> void:
	var h := Game.hero
	var lv := int(h.skill_lv[i])
	var cost := up_cost(lv)
	if int(h.skill_pts) < 1 or int(h.gold) < cost or lv >= Hero.SKILL_MAX:
		return
	h.skill_pts = int(h.skill_pts) - 1
	h.gold = int(h.gold) - cost
	h.skill_lv[i] = lv + 1
	Daily.track(h, "upgrade")
	Game.sfx("levelup")
	Game.save()
	refresh_wallet()
	_build()

func back() -> void:
	Game.goto(HubScreen.new())

## Skill name inside an equipped-slot chip: fixed width, trimmed with "…" so the
## 3 slots + Tuyệt Kỹ + Ngộ Chiêu + points fit one row on 16:9 screens.
static func _slot_name(t: String, col: Color) -> Label:
	var l := UI.label(t, 16, col)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = 112
	return l
