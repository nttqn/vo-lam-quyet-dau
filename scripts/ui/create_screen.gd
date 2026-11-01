class_name CreateScreen
extends Screen
## Pick a sect, colour and name.

var slot := 0
var sect_id := "vo_dang"
var color := 0
var _name_edit: LineEdit
var _info: VBoxContainer
var _sect_btns := {}
var _color_box: HBoxContainer

const FIRST := ["Lăng", "Tiêu", "Mộ Dung", "Lý", "Vân", "Tạ", "Lam", "Bạch", "Hạ", "Tần", "Diệp", "Thẩm", "Tô", "Lục"]
const LAST_M := ["Phong", "Thiên Vũ", "Hàn", "Kiếm Minh", "Trường Ca", "Dật", "Thanh Vân", "Lăng Tiêu", "Tử Hiên", "Bất Phàm"]
const LAST_F := ["Tuyết", "Nguyệt Hoa", "Thanh Y", "Tiểu Mai", "Uyển Nhi", "Linh Lung", "Băng Tâm", "Như Yên"]

func _init(p_slot: int) -> void:
	slot = p_slot

func _ready() -> void:
	_init_ui("temple")
	show.set_focus(-1.6)
	shade(false, 0.55, 0.9)
	top_bar("Bái Sư Nhập Môn", back)
	# sect list along the left
	var left := UI.vbox(10)
	left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	left.offset_left = 20
	left.offset_right = 250
	left.offset_top = 96
	left.offset_bottom = -20
	ui.add_child(left)
	for s in Sects.all():
		var b := UI.button(s.name + "  ·  " + s.weapon_name, func(): _pick(s.id), 22)
		b.custom_minimum_size.y = 64
		b.toggle_mode = true
		left.add_child(b)
		_sect_btns[s.id] = b
	# info on the right
	var right := UI.vbox(10)
	right.anchor_left = 0.55
	right.anchor_right = 1.0
	right.anchor_top = 0.0
	right.anchor_bottom = 1.0
	right.offset_left = 10
	right.offset_right = -28
	right.offset_top = 96
	right.offset_bottom = -20
	ui.add_child(right)
	_info = UI.vbox(8)
	_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_info)
	_color_box = UI.hbox(8)
	right.add_child(_color_box)
	var nh := UI.hbox(8)
	right.add_child(nh)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Danh xưng hiệp khách"
	_name_edit.max_length = 16
	_name_edit.custom_minimum_size = Vector2(300, 56)
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.add_theme_font_size_override("font_size", 26)
	nh.add_child(_name_edit)
	nh.add_child(UI.button("Ngẫu nhiên", _random_name, 20))
	right.add_child(UI.gold_button("Nhập môn", _create, 30))
	_pick("vo_dang")
	_random_name()

func _pick(id: String) -> void:
	sect_id = id
	color = 0
	for k in _sect_btns:
		(_sect_btns[k] as Button).button_pressed = k == id
	_refresh()
	if _name_edit and _name_edit.text != "":
		pass

func _refresh() -> void:
	var s := Sects.get_sect(sect_id)
	show.clear()
	var lk: Dictionary = s.look.duplicate()
	var alt := Looks.palette(sect_id, color)
	for k in alt:
		lk[k] = alt[k]
	show.add_body(lk, s.style, -1.6, -0.55)
	show.spin = true
	for c in _info.get_children():
		c.queue_free()
	var h := UI.heading(s.name, 56)
	_info.add_child(h)
	var d := UI.label(s.desc, 22)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.add_child(d)
	var bias: Dictionary = s.bias
	var names := {"luc": "Lực", "than": "Thân pháp", "noi": "Nội công", "the": "Thể chất"}
	var bl := UI.hbox(18)
	for k in ["luc", "than", "noi", "the"]:
		var v: int = int(bias[k])
		var col := UI.PAPER if v == 0 else (Color(0.5, 1, 0.5) if v > 0 else Color(1, 0.5, 0.45))
		bl.add_child(UI.label("%s %s%d" % [names[k], "+" if v >= 0 else "", v], 20, col, UI.bold))
	_info.add_child(bl)
	_info.add_child(UI.label("Võ công trấn phái:", 22, UI.GOLD, UI.bold))
	for m in s.skills:
		var t := "• %s  (cấp %d)" % [m.name, m.lvl]
		if m.get("ult", false):
			t += "  — Tuyệt kỹ"
		_info.add_child(UI.label(t, 19, Color(0.92, 0.88, 0.8)))
	for c in _color_box.get_children():
		c.queue_free()
	_color_box.add_child(UI.label("Y phục:", 20))
	for i in Looks.PALETTE_NAMES.size():
		var b := UI.button(Looks.PALETTE_NAMES[i], func():
			color = i
			_refresh(), 18)
		b.toggle_mode = true
		b.button_pressed = i == color
		_color_box.add_child(b)

func _random_name() -> void:
	var female: bool = Sects.get_sect(sect_id).look.get("female", false)
	var last: Array = LAST_F if female else LAST_M
	_name_edit.text = FIRST[randi() % FIRST.size()] + " " + last[randi() % last.size()]

func _create() -> void:
	var n := _name_edit.text.strip_edges()
	if n.length() < 2:
		toast("Hãy đặt danh xưng (ít nhất 2 ký tự)", Color(1, 0.6, 0.5))
		return
	Game.slot = slot
	Game.hero = Hero.create(n, sect_id)
	Game.hero.color = color
	Game.save()
	Game.sfx("gong")
	Game.goto(HubScreen.new())

func back() -> void:
	Game.goto(TitleScreen.new())
