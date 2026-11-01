class_name CreateScreen
extends Screen
## Character creation: step 1 pick a sect, step 2 customise appearance + name.

var slot := 0
var sect_id := "vo_dang"
var color := 0
var app := {}
var step := 1
var _name_edit: LineEdit
var _panel: VBoxContainer
var _left: VBoxContainer
var _sect_btns := {}
var _title: Label

const FIRST := ["Lăng", "Tiêu", "Mộ Dung", "Lý", "Vân", "Tạ", "Lam", "Bạch", "Hạ", "Tần", "Diệp", "Thẩm", "Tô", "Lục"]
const LAST_M := ["Phong", "Thiên Vũ", "Hàn", "Kiếm Minh", "Trường Ca", "Dật", "Thanh Vân", "Lăng Tiêu", "Tử Hiên", "Bất Phàm"]
const LAST_F := ["Tuyết", "Nguyệt Hoa", "Thanh Y", "Tiểu Mai", "Uyển Nhi", "Linh Lung", "Băng Tâm", "Như Yên"]

func _init(p_slot: int) -> void:
	slot = p_slot

func _ready() -> void:
	_init_ui("temple")
	show.set_focus(-1.6)
	shade(false, 0.58, 0.92)
	var bar := top_bar("Bái Sư Nhập Môn", back)
	_title = bar.get_child(1) as Label
	_left = UI.vbox(10)
	_left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_left.offset_left = 20
	_left.offset_right = 250
	_left.offset_top = 96
	_left.offset_bottom = -20
	ui.add_child(_left)
	for s in Sects.all():
		var b := UI.button(s.name + "  ·  " + s.weapon_name, func(): _pick(s.id), 22)
		b.custom_minimum_size.y = 64
		b.toggle_mode = true
		_left.add_child(b)
		_sect_btns[s.id] = b
	var sc := ScrollContainer.new()
	sc.anchor_left = 0.56
	sc.anchor_right = 1.0
	sc.anchor_bottom = 1.0
	sc.offset_left = 6
	sc.offset_right = -24
	sc.offset_top = 92
	sc.offset_bottom = -16
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(sc)
	_panel = UI.vbox(8)
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_panel)
	_pick("vo_dang")

# ------------------------------------------------------------- shared
func _look() -> Dictionary:
	var s := Sects.get_sect(sect_id)
	var lk: Dictionary = s.look.duplicate()
	var alt := Looks.palette(sect_id, color)
	for k in alt:
		lk[k] = alt[k]
	return Appearance.apply(lk, app)

func _refresh_model() -> void:
	show.clear()
	var s := Sects.get_sect(sect_id)
	show.add_body(_look(), s.style, -1.6, -0.55 if step == 1 else -0.25)
	show.spin = step == 1
	if step == 2:
		show.cam.position = Vector3(-1.6 + 0.75, 1.4, 2.9)
		show.cam.look_at(Vector3(-1.6 + 0.75, 1.2, 0))
	else:
		show.set_focus(-1.6)

func _pick(id: String) -> void:
	sect_id = id
	color = 0
	app = Appearance.default_for(id, id == "nga_mi")
	for k in _sect_btns:
		(_sect_btns[k] as Button).button_pressed = k == id
	step = 1
	_build_step1()
	_refresh_model()

# ------------------------------------------------------------- step 1
func _build_step1() -> void:
	_left.visible = true
	_title.text = "Bái Sư Nhập Môn"
	for c in _panel.get_children():
		c.queue_free()
	var s := Sects.get_sect(sect_id)
	_panel.add_child(UI.heading(s.name, 56))
	var d := UI.label(s.desc, 22)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(d)
	var names := {"luc": "Lực", "than": "Thân pháp", "noi": "Nội công", "the": "Thể chất"}
	var bl := UI.hbox(18)
	for k in ["luc", "than", "noi", "the"]:
		var v: int = int(s.bias[k])
		var col := UI.PAPER if v == 0 else (Color(0.5, 1, 0.5) if v > 0 else Color(1, 0.5, 0.45))
		bl.add_child(UI.label("%s %s%d" % [names[k], "+" if v >= 0 else "", v], 20, col, UI.bold))
	_panel.add_child(bl)
	_panel.add_child(UI.label("Võ công trấn phái:", 22, UI.GOLD, UI.bold))
	for m in s.skills:
		var t := "• %s  (cấp %d)" % [m.name, m.lvl]
		if m.get("ult", false):
			t += "  — Tuyệt kỹ"
		_panel.add_child(UI.label(t, 19, Color(0.92, 0.88, 0.8)))
	var sp := Control.new()
	sp.custom_minimum_size.y = 10
	_panel.add_child(sp)
	_panel.add_child(UI.gold_button("Tiếp: Tạo ngoại hình  ›", _to_step2, 28))

# ------------------------------------------------------------- step 2
func _to_step2() -> void:
	step = 2
	_left.visible = false
	_title.text = "Ngoại Hình"
	_refresh_model()
	_build_step2()
	if _name_edit and _name_edit.text == "":
		_random_name()

func _build_step2() -> void:
	var keep_name := _name_edit.text if is_instance_valid(_name_edit) else ""
	for c in _panel.get_children():
		c.queue_free()
	var female: bool = app.get("female", false)
	_row_text("Giới tính", ["Nam", "Nữ"], 1 if female else 0, func(i):
		app.female = i == 1
		app.brow = 1 if app.female else 0
		app.beard = false
		if app.female and int(app.lip) == 0:
			app.lip = 1
		_changed())
	_row_text("Vóc dáng", Appearance.HEIGHT_NAMES, int(app.height), func(i):
		app.height = i
		_changed())
	_row_text("Khuôn mặt", Appearance.FACE_NAMES, int(app.face), func(i):
		app.face = i
		_changed())
	_row_color("Màu da", Appearance.SKIN, Appearance.SKIN_NAMES, int(app.skin), func(i):
		app.skin = i
		_changed())
	var hl := Appearance.hair_list(female)
	var hn := []
	for h in hl:
		hn.append(Appearance.HAIR_NAMES[h])
	_row_text("Kiểu tóc", hn, int(app.hair), func(i):
		app.hair = i
		_changed())
	_row_color("Màu tóc", Appearance.HAIR_COL, Appearance.HAIR_COL_NAMES, int(app.hair_col), func(i):
		app.hair_col = i
		_changed())
	_row_text("Chân mày", Appearance.BROW_NAMES, int(app.brow), func(i):
		app.brow = i
		_changed())
	_row_color("Màu mắt", Appearance.EYE, Appearance.EYE_NAMES, int(app.eye), func(i):
		app.eye = i
		_changed())
	var lips := Appearance.LIP.duplicate()
	lips[0] = Color(0.7, 0.5, 0.45)
	_row_color("Môi", lips, Appearance.LIP_NAMES, int(app.lip), func(i):
		app.lip = i
		_changed())
	if not female:
		_row_text("Râu", ["Không", "Có"], 1 if app.get("beard", false) else 0, func(i):
			app.beard = i == 1
			_changed())
	_row_text("Y phục", Looks.PALETTE_NAMES, color, func(i):
		color = i
		_changed())
	var nh := UI.hbox(8)
	_panel.add_child(nh)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Danh xưng hiệp khách"
	_name_edit.max_length = 16
	_name_edit.text = keep_name
	_name_edit.custom_minimum_size = Vector2(260, 56)
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.add_theme_font_size_override("font_size", 24)
	nh.add_child(_name_edit)
	nh.add_child(UI.button("Đặt tên khác", _random_name, 18))
	var row := UI.hbox(10)
	_panel.add_child(row)
	row.add_child(UI.button("‹ Chọn phái", func():
		step = 1
		_build_step1()
		_refresh_model(), 20))
	row.add_child(UI.button("Ngẫu nhiên", _random_look, 20))
	var go := UI.gold_button("Nhập môn", _create, 28)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(go)

func _changed() -> void:
	_refresh_model()
	_build_step2()

func _row_label(t: String) -> HBoxContainer:
	var r := UI.hbox(6)
	var l := UI.label(t, 19, UI.GOLD, UI.bold)
	l.custom_minimum_size.x = 112
	r.add_child(l)
	_panel.add_child(r)
	return r

func _row_text(t: String, opts: Array, cur: int, cb: Callable) -> void:
	var r := _row_label(t)
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	r.add_child(flow)
	for i in opts.size():
		var b := UI.button(opts[i], func(): cb.call(i), 17)
		b.toggle_mode = true
		b.button_pressed = i == cur
		b.custom_minimum_size.y = 44
		flow.add_child(b)

func _row_color(t: String, cols: Array, names: Array, cur: int, cb: Callable) -> void:
	var r := _row_label(t)
	for i in cols.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(46, 46)
		b.tooltip_text = names[i]
		var c: Color = cols[i]
		b.add_theme_stylebox_override("normal", UI.box(c, UI.GOLD if i == cur else Color(0, 0, 0, 0.6), 4 if i == cur else 2, 23, 0))
		b.add_theme_stylebox_override("hover", UI.box(c.lightened(0.1), UI.GOLD, 3, 23, 0))
		b.add_theme_stylebox_override("pressed", UI.box(c, UI.GOLD, 4, 23, 0))
		b.pressed.connect(func():
			Game.sfx("click")
			cb.call(i))
		r.add_child(b)

func _random_look() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var female: bool = app.female
	app = Appearance.default_for(sect_id, female)
	app.skin = rng.randi_range(0, Appearance.SKIN.size() - 1)
	app.hair = rng.randi_range(0, Appearance.hair_list(female).size() - 1)
	app.hair_col = rng.randi_range(0, Appearance.HAIR_COL.size() - 1)
	app.eye = rng.randi_range(0, Appearance.EYE.size() - 1)
	app.face = rng.randi_range(0, Appearance.FACE_SCALE.size() - 1)
	app.height = rng.randi_range(0, 2)
	app.lip = rng.randi_range(1, 4) if female else 0
	app.beard = not female and rng.randf() < 0.4
	color = rng.randi_range(0, Looks.PALETTE_NAMES.size() - 1)
	_changed()

func _random_name() -> void:
	var last: Array = LAST_F if app.get("female", false) else LAST_M
	_name_edit.text = FIRST[randi() % FIRST.size()] + " " + last[randi() % last.size()]

func _create() -> void:
	var n := _name_edit.text.strip_edges()
	if n.length() < 2:
		toast("Hãy đặt danh xưng (ít nhất 2 ký tự)", Color(1, 0.6, 0.5))
		return
	Game.slot = slot
	Game.hero = Hero.create(n, sect_id)
	Game.hero.color = color
	Game.hero.appearance = app.duplicate()
	Game.save()
	Game.sfx("gong")
	Game.goto(HubScreen.new())

func back() -> void:
	if step == 2:
		step = 1
		_build_step1()
		_refresh_model()
		return
	Game.goto(TitleScreen.new())
