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
	v.add_child(_gfx_row())
	var cr := UI.label("Võ Lâm Quyết Đấu  ·  phiên bản %s\nÂm thanh trận đấu: thư viện CC0 OpenGameArt (artisticdude, StarNinjas,\nrubberduck, Kenney, HaelDB). Giọng nữ: Marti Topmade (topmademarti).\nPhông chữ: Be Vietnam Pro, Playfair Display (SIL OFL)." % ProjectSettings.get_setting("application/config/version", "1.0.0"), 16, Color(0.75, 0.72, 0.66))
	v.add_child(cr)
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
	var hint := UI.label(Gfx.HINTS[Gfx.level()], 16, Color(0.75, 0.72, 0.66))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 560
	var group := ButtonGroup.new()
	for i in Gfx.NAMES.size():
		var b := UI.button(Gfx.NAMES[i], func():
			Game.settings["gfx"] = i
			Game.save_settings()
			Gfx.set_level(i)
			Gfx.apply(get_tree())
			hint.text = Gfx.HINTS[i]
			Game.sfx("click"), 20, 120)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = Gfx.level() == i
		b.custom_minimum_size.y = 44
		# the theme's pressed look is darker than normal: dim the others instead
		b.toggled.connect(func(on: bool): b.modulate = Color.WHITE if on else Color(0.55, 0.55, 0.55))
		b.modulate = Color.WHITE if b.button_pressed else Color(0.55, 0.55, 0.55)
		h.add_child(b)
	box.add_child(h)
	box.add_child(hint)
	return box

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
