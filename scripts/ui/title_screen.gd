class_name TitleScreen
extends Screen
## Title + save slot selection.

var _slots_box: Control
var _cloud_lbl: Label

func _ready() -> void:
	Game.hero = {}
	Game.slot = -1
	_init_ui("peak")
	show.set_focus(0.0)
	show.add_body(Sects.get_sect("vo_dang").look, "sword", -1.0, -0.4)
	show.add_body(Sects.get_sect("nga_mi").look, "dual", 1.0, PI + 0.4)
	show.cam.position = Vector3(0, 1.1, 4.6)
	show.cam.look_at(Vector3(0, 1.25, 0))
	Game.music("menu")
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0, 0, 0, 0.5))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.3)
	gt.fill_to = Vector2(0.5, 1.0)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(tr)
	var v := UI.vbox(6)
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	v.offset_top = 26
	v.offset_left = -500
	v.offset_right = 500
	ui.add_child(v)
	var t: Control
	var logo_p := "res://assets/art/logo.png"
	if ResourceLoader.exists(logo_p):
		# painted calligraphy title (assets/art/logo.png)
		var lr := TextureRect.new()
		lr.texture = load(logo_p)
		lr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lr.custom_minimum_size = Vector2(0, 170)
		t = lr
	else:
		var hl := UI.heading("Võ Lâm Quyết Đấu", 92)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t = hl
	v.add_child(t)
	var sub := UI.label("Ngũ phái tranh hùng  ·  Một kiếm định giang hồ", 24, UI.PAPER, UI.med)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	_slots_box = UI.hbox(18)
	_slots_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_slots_box.offset_bottom = -110
	_slots_box.offset_top = -290
	_slots_box.offset_left = -560
	_slots_box.offset_right = 560
	_slots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	ui.add_child(_slots_box)
	_build_slots()
	var bottom := UI.hbox(16)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.offset_top = -86
	bottom.offset_bottom = -26
	bottom.offset_left = -300
	bottom.offset_right = 300
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	ui.add_child(bottom)
	bottom.add_child(UI.button("Cài đặt", func(): ui.add_child(SettingsPanel.new()), 22, 180))
	bottom.add_child(UI.button("Hướng dẫn", func(): ui.add_child(HelpPanel.new()), 22, 180))
	if Cloud.enabled():
		bottom.offset_left = -420
		bottom.offset_right = 420
		bottom.add_child(UI.button("Tài khoản", _account, 22, 180))
		_cloud_lbl = UI.label("", 18, Color(0.85, 0.82, 0.75))
		_cloud_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		_cloud_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_cloud_lbl.clip_text = true
		_cloud_lbl.offset_left = -640
		_cloud_lbl.offset_right = -16
		_cloud_lbl.offset_top = 8
		_cloud_lbl.offset_bottom = 34
		_cloud_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ui.add_child(_cloud_lbl)
		_sync()

func _build_slots() -> void:
	for c in _slots_box.get_children():
		c.queue_free()
	for i in Game.SLOTS:
		var info := Game.slot_info(i)
		var p := UI.panel(Color(0.08, 0.05, 0.05, 0.85))
		p.custom_minimum_size = Vector2(340, 170)
		var v := UI.vbox(6)
		p.add_child(v)
		if info.is_empty():
			var l := UI.label("Ô lưu %d — Trống" % (i + 1), 22, Color(0.8, 0.75, 0.7))
			v.add_child(l)
			var sp := Control.new()
			sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			v.add_child(sp)
			v.add_child(UI.gold_button("Tạo nhân vật", func(): _new(i), 24))
		else:
			var s := Sects.get_sect(info.get("sect", "vo_dang"))
			var name := UI.label(str(info.get("name", "?")), 28, UI.GOLD, UI.title)
			v.add_child(name)
			v.add_child(UI.label("%s  ·  Cấp %d" % [s.name, int(info.get("level", 1))], 22))
			var prog: int = (info.get("stars", {}) as Dictionary).size()
			v.add_child(UI.label("Giang hồ: %d/42 trận" % prog, 18, Color(0.8, 0.78, 0.72)))
			if Cloud.conflicts.has(i):
				v.add_child(UI.label("Bản trên mây khác bản trong máy", 17, Color(1, 0.7, 0.45)))
				v.add_child(UI.gold_button("Chọn bản lưu", func(): _resolve(i), 22))
				_slots_box.add_child(p)
				continue
			var h := UI.hbox(8)
			v.add_child(h)
			var play := UI.gold_button("Vào game", func(): _play(i), 22)
			play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(play)
			h.add_child(UI.button("Xóa", func(): confirm("Xóa nhân vật %s? Bản lưu trên mây cũng bị xóa." % info.get("name", ""), func():
				Game.delete_slot(i)
				_build_slots(), "Xóa"), 20))
		_slots_box.add_child(p)

func _new(i: int) -> void:
	Game.goto(CreateScreen.new(i))

func _play(i: int) -> void:
	if Game.load_slot(i):
		Game.goto(HubScreen.new())

func back() -> void:
	get_tree().quit()

# ------------------------------------------------------------- cloud
func _status_text() -> String:
	return "☁ " + (Cloud.email if Cloud.email != "" else "Khách (chưa liên kết email)")

func _sync() -> void:
	_cloud_lbl.text = _status_text() + "  ·  Đang đồng bộ…"
	var msg: String = await Cloud.sync_all()
	if not is_inside_tree():
		return
	_cloud_lbl.text = _status_text() + "  ·  " + msg
	_build_slots()

func _account() -> void:
	var p := AccountPanel.new()
	ui.add_child(p)
	p.tree_exited.connect(func():
		if is_inside_tree():
			_sync())

func _when(t: float) -> String:
	if t <= 0:
		return "?"
	var d := Time.get_datetime_dict_from_unix_time(int(t + Time.get_time_zone_from_system().bias * 60))
	return "%02d:%02d %02d/%02d" % [d.hour, d.minute, d.day, d.month]

func _resolve(i: int) -> void:
	var c: Dictionary = Cloud.conflicts.get(i, {})
	var l := Game.slot_info(i)
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
	var v := UI.vbox(14)
	v.custom_minimum_size.x = 640
	p.add_child(v)
	v.add_child(UI.heading("Ô lưu %d: chọn bản giữ lại" % (i + 1), 34))
	var t := UI.label("Bản không chọn sẽ bị thay thế (bản trong máy vẫn được cất dự phòng).", 18, Color(0.85, 0.82, 0.75))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var h := UI.hbox(14)
	v.add_child(h)
	for side in ["local", "cloud"]:
		var info: Dictionary = l if side == "local" else c
		var box := UI.panel(Color(0.08, 0.05, 0.05, 0.9))
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(box)
		var bv := UI.vbox(6)
		box.add_child(bv)
		bv.add_child(UI.label("Trong máy này" if side == "local" else "Trên mây", 20, UI.GOLD, UI.bold))
		bv.add_child(UI.label(str(info.get("name", "?")), 24, UI.PAPER, UI.title))
		bv.add_child(UI.label("%s  ·  Cấp %d" % [Sects.get_sect(str(info.get("sect", "vo_dang"))).name, int(info.get("level", 1))], 19))
		bv.add_child(UI.label("Lưu lúc " + _when(float(info.get("saved_at", 0))), 17, Color(0.8, 0.78, 0.72)))
		bv.add_child(UI.gold_button("Giữ bản này", func():
			dim.queue_free()
			if side == "local":
				await Cloud.resolve_keep_local(i)
			else:
				Cloud.resolve_take_cloud(i)
			if is_inside_tree():
				_build_slots(), 20))
	v.add_child(UI.button("Để sau", dim.queue_free, 20))
