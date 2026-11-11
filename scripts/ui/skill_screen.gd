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

## Image filling its box (cropped, never stretched).
static func _image(tex: Texture2D, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.custom_minimum_size = size
	r.clip_contents = true
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

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
	# --- equipped slots
	for c in _slots.get_children():
		c.queue_free()
	_slots.add_child(UI.label("Ô chiêu", 22, UI.GOLD, UI.bold))
	for k in 3:
		var i := int(h.equip[k])
		var slot := UI.panel(Color(0.1, 0.07, 0.09, 0.92), UI.GOLD if i == _sel and i >= 0 else UI.GOLD_D)
		var sh := UI.hbox(8)
		slot.add_child(sh)
		sh.add_child(UI.label(str(k + 1), 24, UI.GOLD, UI.title))
		if i >= 0:
			sh.add_child(_image(pic(s.id, i), Vector2(56, 42)))
		sh.add_child(UI.label(s.skills[i].name if i >= 0 else "(trống)", 18, UI.PAPER if i >= 0 else Color(0.6, 0.58, 0.55)))
		_slots.add_child(slot)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots.add_child(sp)
	_slots.add_child(UI.label("Điểm võ công: %d" % int(h.skill_pts), 22, Color(0.6, 1, 0.6) if int(h.skill_pts) > 0 else UI.PAPER, UI.bold))
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
	var img := _image(pic(s.id, i), Vector2(212, 150))
	if lv == 0:
		img.self_modulate = Color(0.35, 0.35, 0.38)
	v.add_child(img)
	var eq: int = h.equip.find(i)
	if eq >= 0:
		var badge := UI.label(str(eq + 1), 22, UI.INK, UI.title)
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
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.clip_text = true
	v.add_child(nm)
	v.add_child(_pips(lv, 12))
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
	var img := _image(pic(s.id, i), Vector2(0, 220))
	img.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_child(img)
	var t := UI.heading(m.name, 34)
	_detail.add_child(t)
	var row := UI.hbox(10)
	_detail.add_child(row)
	if m.get("ult", false):
		row.add_child(UI.label("Tuyệt kỹ", 18, Color(1, 0.6, 0.3), UI.bold))
	if lv > 0:
		row.add_child(UI.label("Tầng %d/%d" % [lv, Hero.SKILL_MAX], 18, UI.PAPER, UI.bold))
		row.add_child(_pips(lv, 10))
	else:
		row.add_child(UI.label("Mở khi đạt cấp %d" % int(m.lvl), 18, Color(1, 0.7, 0.5), UI.bold))
	var d := UI.label(describe(Hero.skill_scaled(m, maxi(1, lv))), 18, Color(0.9, 0.87, 0.8))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_child(d)
	if lv == 0:
		return
	var eq: int = h.equip.find(i)
	var er := UI.hbox(8)
	_detail.add_child(er)
	er.add_child(UI.label("Lắp vào ô", 18, UI.GOLD, UI.bold))
	for k in 3:
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
