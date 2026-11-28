class_name SettingsPanel
extends Control
## Modal settings overlay (sound, music, vibration).

func _ready() -> void:
	add_to_group("modal")   # Android back closes it (Game._go_back)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var p := UI.panel()
	c.add_child(p)
	var v := UI.vbox(14)
	v.custom_minimum_size.x = 560
	p.add_child(v)
	v.add_child(UI.heading("Cài Đặt", 46))
	v.add_child(_slider("Âm thanh", "sfx"))
	v.add_child(_slider("Nhạc nền", "music"))
	var vib := CheckButton.new()
	vib.text = "Rung khi đánh trúng"
	vib.button_pressed = Game.settings.vibrate
	vib.add_theme_font_size_override("font_size", 22)
	vib.toggled.connect(func(on: bool):
		Game.settings.vibrate = on
		Game.save_settings())
	v.add_child(vib)
	if OS.get_name() == "Android":
		var nt := CheckButton.new()
		nt.text = "Nhắc nhở (Boss Thế Giới, điểm danh)"
		nt.button_pressed = Notify.enabled()
		nt.add_theme_font_size_override("font_size", 22)
		nt.toggled.connect(func(on: bool):
			Game.settings["notify"] = on
			Game.save_settings()
			if on and not Notify.allowed():
				Notify.ask())
		v.add_child(nt)
	v.add_child(_gfx_row())
	if not Game._current is FightScene:
		v.add_child(_lang_row())
	var cr := UI.label(L.f("Võ Lâm Quyết Đấu  ·  phiên bản %s\nÂm thanh trận đấu: thư viện CC0 OpenGameArt (artisticdude, StarNinjas,\nrubberduck, Kenney, HaelDB). Giọng nữ: Marti Topmade (topmademarti).\nPhông chữ: Be Vietnam Pro, Playfair Display (SIL OFL).", ProjectSettings.get_setting("application/config/version", "1.0.0")), 16, Color(0.75, 0.72, 0.66))
	v.add_child(cr)
	if OS.get_name() in ["Android", "iOS"]:
		v.add_child(UI.button("Khôi phục giao dịch", Iap.restore, 20))
	if Ads.privacy_options_required():
		v.add_child(UI.button("Quyền riêng tư quảng cáo", Ads.show_privacy_options, 20))
	v.add_child(UI.gold_button("Đóng", queue_free, 24))

## Đồ họa: Thấp / Thường / Cao picker + one-line hint.
func _gfx_row() -> Control:
	var box := UI.vbox(6)
	var h := UI.hbox(10)
	var l := UI.label("Đồ họa", 22)
	l.custom_minimum_size.x = 140
	h.add_child(l)
	var hint := UI.label(Gfx.choice_hint(), 16, Color(0.75, 0.72, 0.66))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 560
	var group := ButtonGroup.new()
	for c in Gfx.CHOICES:
		var i: int = c[0]
		var b := UI.button(c[1], func():
			Game.settings["gfx"] = i
			Gfx.set_level(i)
			Gfx.reset_scale(Game.settings)
			Game.save_settings()
			Gfx.apply(get_tree())
			hint.text = Gfx.choice_hint()
			Game.sfx("click"), 20, 120)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = Gfx.choice() == i
		b.custom_minimum_size.y = 44
		# the theme's pressed look is darker than normal: dim the others instead
		b.toggled.connect(func(on: bool): b.modulate = Color.WHITE if on else Color(0.55, 0.55, 0.55))
		b.modulate = Color.WHITE if b.button_pressed else Color(0.55, 0.55, 0.55)
		h.add_child(b)
	box.add_child(h)
	box.add_child(hint)
	return box

## Ngôn ngữ: one button per language, each label in its own language.
func _lang_row() -> Control:
	var h := UI.hbox(8)
	var l := UI.label("Ngôn ngữ", 22)
	l.custom_minimum_size.x = 140
	h.add_child(l)
	for code in L.LANGS:
		var b := UI.button(L.LABELS[code], func():
			Game.sfx("click")
			queue_free()
			Game.set_lang(code), 18, 100)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size.y = 44
		b.modulate = Color.WHITE if L.lang == code else Color(0.55, 0.55, 0.55)
		h.add_child(b)
	return h

func _slider(label: String, key: String) -> Control:
	var h := UI.hbox(12)
	var l := UI.label(label, 22)
	l.custom_minimum_size.x = 140
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Game.settings[key])
	s.custom_minimum_size = Vector2(360, 40)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(x: float):
		Game.settings[key] = x
		Game.apply_volume()
		Game.save_settings()
		if key == "sfx":
			Game.sfx("click"))
	h.add_child(s)
	return h
