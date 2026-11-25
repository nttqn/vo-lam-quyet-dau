class_name CharacterScreen
extends Screen
## Attribute points + derived stats.

var _box: VBoxContainer
const ATTR := [
	["luc", "Lực", "Tăng công lực đòn thường (Công)."],
	["than", "Thân pháp", "Tăng tốc độ di chuyển và tỉ lệ bạo kích."],
	["noi", "Nội công", "Tăng sát thương võ công, hồi nội lực, trị thương."],
	["the", "Thể chất", "Tăng sinh lực và phòng thủ."],
]
const RESET_COST := 10

func _ready() -> void:
	_init_ui("temple")
	enable_turn()
	var h := Game.hero
	show.set_focus(1.6)
	show.add_body(Hero.look(h), Hero.sect(h).style, 0.2, -0.6)
	shade(false, 0.62, 0.9)
	top_bar("Nhân Vật", back)
	_box = UI.vbox(10)
	_box.anchor_left = 1.0
	_box.anchor_right = 1.0
	_box.anchor_bottom = 1.0
	_box.offset_left = -620
	_box.offset_right = -30
	_box.offset_top = 96
	_box.offset_bottom = -20
	ui.add_child(_box)
	_build()

func _build() -> void:
	for c in _box.get_children():
		c.queue_free()
	var h := Game.hero
	var s := Hero.sect(h)
	var a := Build.attrs(int(h.level), h.pts, s)
	var free := int(h.free_pts)
	_box.add_child(_name_row())
	_box.add_child(UI.label(L.f("Điểm tiềm năng: %d", free), 26, Color(0.6, 1, 0.6) if free > 0 else UI.PAPER, UI.bold))
	for at in ATTR:
		var row := UI.hbox(10)
		var name := UI.label(at[1], 24, UI.GOLD, UI.bold)
		name.custom_minimum_size.x = 150
		row.add_child(name)
		var val := UI.label(str(a[at[0]]), 26, UI.PAPER, UI.bold)
		val.custom_minimum_size.x = 50
		row.add_child(val)
		var d := UI.label(at[2], 16, Color(0.8, 0.77, 0.7))
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(d)
		var k: String = at[0]
		var b1 := UI.button("+1", func(): _add(k, 1), 22)
		b1.disabled = free <= 0
		b1.custom_minimum_size = Vector2(64, 52)
		row.add_child(b1)
		var b5 := UI.button("+5", func(): _add(k, 5), 22)
		b5.disabled = free < 5
		b5.custom_minimum_size = Vector2(64, 52)
		row.add_child(b5)
		_box.add_child(row)
	var st := Hero.stats(h)
	var p := UI.panel(Color(0.07, 0.05, 0.05, 0.85))
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 26)
	p.add_child(g)
	var rows := [
		["Sinh lực", UI.fmt(st.hp_max)], ["Công", UI.fmt(st.atk)],
		["Phòng thủ", UI.fmt(st.def)], ["Nội công", UI.fmt(st.qi)],
		["Tốc độ", "%d%%" % int(st.spd * 100)], ["Bạo kích", "%.1f%%" % (st.crit * 100)],
		["Hồi nội lực", "%d%%" % int(st.en_gain * 100)], ["Lực chiến", UI.fmt(Build.power(st))],
	]
	for r in rows:
		g.add_child(UI.label(r[0], 20, Color(0.82, 0.78, 0.7)))
		g.add_child(UI.label(r[1], 22, UI.PAPER, UI.bold))
	_box.add_child(p)
	var stats_l := UI.label(L.f("Thắng %d  ·  Thua %d  ·  Lôi đài kỷ lục %d", [int(h.wins), int(h.losses), int(h.arena_best)]), 18, Color(0.8, 0.77, 0.7))
	_box.add_child(stats_l)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(sp)
	var rb := UI.button(L.f("Tẩy điểm (%d Ngọc)", RESET_COST), func(): confirm(L.f("Hoàn lại toàn bộ điểm tiềm năng với giá %d Ngọc?", RESET_COST), _reset), 20)
	rb.disabled = int(h.jade) < RESET_COST
	_box.add_child(rb)

func _add(k: String, n: int) -> void:
	var h := Game.hero
	n = mini(n, int(h.free_pts))
	if n <= 0:
		return
	h.pts[k] = int(h.pts[k]) + n
	h.free_pts = int(h.free_pts) - n
	Game.save()
	_build()

func _reset() -> void:
	var h := Game.hero
	var total := 0
	for k in h.pts:
		total += int(h.pts[k])
		h.pts[k] = 0
	h.free_pts = int(h.free_pts) + total
	h.jade = int(h.jade) - RESET_COST
	Game.save()
	refresh_wallet()
	_build()

# ------------------------------------------------------------ danh hiệu
func _title_dialog() -> void:
	var h := Game.hero
	var root := Control.new()
	root.add_to_group("modal")
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var p := UI.panel()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 180
	p.offset_right = -180
	p.offset_top = 40
	p.offset_bottom = -40
	root.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	v.add_child(UI.heading("Danh Hiệu", 40))
	v.add_child(UI.label("Danh hiệu hiện dưới tên ở sảnh, bảng xếp hạng và khi người khác xem thông tin của bạn.", 17, Color(0.8, 0.77, 0.7)))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := UI.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	var owned := Titles.owned(h)
	var worn := Titles.worn(h)
	for id in Titles.LIST:
		var has: bool = id in owned
		var r := UI.hbox(12)
		var info := UI.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(info)
		info.add_child(UI.label(Titles.name_of(id), 22, Titles.color(id) if has else Color(0.5, 0.48, 0.45), UI.bold))
		info.add_child(UI.label(Titles.LIST[id][2], 16, Color(0.8, 0.77, 0.7) if has else Color(0.55, 0.52, 0.5)))
		var tid: String = id
		var b: Button
		if id == worn:
			b = UI.button("Đang đeo", func(): pass, 18, 140)
			b.disabled = true
		elif has:
			b = UI.gold_button("Đeo", func():
				Titles.wear(h, tid)
				Game.save()
				root.queue_free()
				_build(), 18, 140)
		else:
			b = UI.button("Chưa đạt", func(): pass, 18, 140)
			b.disabled = true
		r.add_child(b)
		list.add_child(r)
	var br := UI.hbox(12)
	br.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(br)
	if worn != "":
		br.add_child(UI.button("Bỏ danh hiệu", func():
			Titles.wear(h, "")
			Game.save()
			root.queue_free()
			_build(), 20, 200))
	br.add_child(UI.gold_button("Đóng", root.queue_free, 20, 160))
	ui.add_child(root)

# ------------------------------------------------------------ đổi tên
func _name_row() -> HBoxContainer:
	var h := Game.hero
	var row := UI.hbox(10)
	var nv := UI.vbox(0)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nv)
	var n := UI.label(str(h.name), 30, UI.GOLD, UI.bold)
	n.clip_text = true
	nv.add_child(n)
	# worn danh hiệu under the name; the button opens the list
	var tid := Titles.worn(h)
	var tl := UI.label(L.f("« %s »", Titles.name_of(tid)) if tid != "" else "Chưa đeo danh hiệu", 17, Titles.color(tid) if tid != "" else Color(0.7, 0.67, 0.6), UI.bold)
	tl.clip_text = true
	nv.add_child(tl)
	var tb := UI.button(L.f("Danh hiệu %d/%d", [Titles.owned(h).size(), Titles.LIST.size()]), _title_dialog, 18)
	tb.custom_minimum_size.y = 50
	row.add_child(tb)
	var left := Hero.rename_left(h)
	var b: Button
	if left > 0.0:
		b = UI.button(L.f("Đổi tên sau %s", _wait_text(left)), func(): pass, 18)
		b.disabled = true
	else:
		b = UI.button("Đổi tên  ▶ QC", _rename_dialog, 20)
	b.custom_minimum_size.y = 50
	row.add_child(b)
	return row

static func _wait_text(sec: float) -> String:
	var s := int(ceil(sec))
	if s >= 86400:
		return L.f("%d ngày %d giờ", [s / 86400, (s % 86400) / 3600])
	if s >= 3600:
		return L.f("%d giờ %d phút", [s / 3600, (s % 3600) / 60])
	return L.f("%d phút", maxi(1, s / 60))

## Top-anchored, so the phone keyboard doesn't cover the field.
func _rename_dialog() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(dim)
	var p := UI.panel()
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.offset_left = -330
	p.offset_right = 330
	p.offset_top = 40
	dim.add_child(p)
	var v := UI.vbox(14)
	p.add_child(v)
	v.add_child(UI.heading("Đổi danh xưng", 34))
	var info := UI.label("Xem một quảng cáo để đổi tên. Mỗi nhân vật được đổi 1 lần mỗi 7 ngày.", 20, Color(0.85, 0.82, 0.75))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size.x = 620
	v.add_child(info)
	var ed := LineEdit.new()
	ed.text = str(Game.hero.name)
	ed.placeholder_text = "Danh xưng mới"
	ed.max_length = Hero.NAME_MAX
	ed.custom_minimum_size = Vector2(620, 56)
	ed.add_theme_font_size_override("font_size", 26)
	v.add_child(ed)
	var hb := UI.hbox(16)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(hb)
	hb.add_child(UI.button("Hủy", func(): dim.queue_free(), 24, 180))
	hb.add_child(UI.gold_button("Xem QC & đổi", func(): _rename(ed.text, dim), 24, 240))
	ed.text_submitted.connect(func(t): _rename(t, dim))
	ed.call_deferred("grab_focus")
	ed.call_deferred("select_all")

func _rename(raw: String, dim: Control) -> void:
	var h := Game.hero
	var n := Hero.tidy_name(raw)
	var why := Hero.name_problem(h, n)
	if why != "":
		toast(why, Color(1, 0.6, 0.5))
		return
	if Hero.rename_left(h) > 0.0:
		dim.queue_free()
		return
	if not Ads.show_rewarded(func(): _renamed(n), Callable(), "rename"):
		toast("Chưa có quảng cáo, thử lại sau", Color(1, 0.7, 0.5))
		return
	dim.queue_free()

func _renamed(n: String) -> void:
	var h := Game.hero
	h.name = n
	h.rename_at = Time.get_unix_time_from_system()
	Game.save()   # also republishes the Bảng Xếp Hạng row
	if is_inside_tree():
		toast(L.t("Đã đổi danh xưng: ") + n, Color(0.6, 1, 0.7))
		_build()

func back() -> void:
	Game.goto(HubScreen.new())
