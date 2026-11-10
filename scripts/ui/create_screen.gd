class_name CreateScreen
extends Screen
## Character creation: pick a sect and a name. Looks come from the sect model.

var slot := 0
var sect_id := "vo_dang"
var _name_edit: LineEdit
var _auto_name := true
var _panel: VBoxContainer
var _sect_btns := {}

const FIRST := ["Lăng", "Tiêu", "Mộ Dung", "Lý", "Vân", "Tạ", "Lam", "Bạch", "Hạ", "Tần", "Diệp", "Thẩm", "Tô", "Lục"]
const LAST_M := ["Phong", "Thiên Vũ", "Hàn", "Kiếm Minh", "Trường Ca", "Dật", "Thanh Vân", "Lăng Tiêu", "Tử Hiên", "Bất Phàm"]
const LAST_F := ["Tuyết", "Nguyệt Hoa", "Thanh Y", "Tiểu Mai", "Uyển Nhi", "Linh Lung", "Băng Tâm", "Như Yên"]

func _init(p_slot: int) -> void:
	slot = p_slot

func _ready() -> void:
	_init_ui("temple")
	show.set_focus(-1.6)
	shade(false, 0.58, 0.92)
	top_bar("Bái Sư Nhập Môn", back)
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

func _female() -> bool:
	return Sects.get_sect(sect_id).look.get("female", false)

func _pick(id: String) -> void:
	sect_id = id
	for k in _sect_btns:
		(_sect_btns[k] as Button).button_pressed = k == id
	show.clear()
	show.add_body(Sects.get_sect(id).look.duplicate(), Sects.get_sect(id).style, -1.6, -0.55)
	show.spin = true
	show.set_focus(-1.6)
	_build()

func _build() -> void:
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
	var keep := _name_edit.text if is_instance_valid(_name_edit) else ""
	var nh := UI.hbox(8)
	_panel.add_child(nh)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Danh xưng hiệp khách"
	_name_edit.max_length = 16
	_name_edit.custom_minimum_size = Vector2(260, 56)
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.add_theme_font_size_override("font_size", 24)
	_name_edit.text_changed.connect(func(_t): _auto_name = false)
	nh.add_child(_name_edit)
	nh.add_child(UI.button("Đặt tên khác", _random_name, 18))
	if _auto_name or keep == "":
		_random_name()
	else:
		_name_edit.text = keep
	_panel.add_child(UI.gold_button("Nhập môn", _create, 28))

func _random_name() -> void:
	var last: Array = LAST_F if _female() else LAST_M
	_name_edit.text = FIRST[randi() % FIRST.size()] + " " + last[randi() % last.size()]
	_auto_name = true

func _create() -> void:
	var n := _name_edit.text.strip_edges()
	if n.length() < 2:
		toast("Hãy đặt danh xưng (ít nhất 2 ký tự)", Color(1, 0.6, 0.5))
		return
	Game.slot = slot
	Game.hero = Hero.create(n, sect_id)
	Game.save()
	Game.sfx("gong")
	Game.goto(HubScreen.new())

func back() -> void:
	Game.goto(TitleScreen.new())
