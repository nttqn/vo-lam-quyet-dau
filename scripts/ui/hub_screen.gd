class_name HubScreen
extends Screen
## Main hub: hero on stage + menu.

func _ready() -> void:
	_init_ui("temple")
	Game.music("menu")
	var h := Game.hero
	var s := Hero.sect(h)
	show.set_focus(1.4)
	show.add_body(Hero.look(h), s.style, 0.2, -0.5)
	shade(false, 0.6, 0.88)
	shade(true, 0.32, 0.6)
	# --- header (left)
	var head := UI.vbox(4)
	head.position = Vector2(24, 18)
	ui.add_child(head)
	head.add_child(UI.heading(h.name, 46))
	head.add_child(UI.label("%s  ·  Cấp %d" % [s.name, int(h.level)], 24, UI.PAPER, UI.bold))
	var need := Hero.exp_need(int(h.level))
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(300, 14)
	bar.max_value = need
	bar.value = int(h.exp)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.4, 0.8, 0.4)
	fill.set_corner_radius_all(6)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	head.add_child(bar)
	head.add_child(UI.label("Kinh nghiệm %d / %d" % [int(h.exp), need], 16, Color(0.8, 0.8, 0.75)))
	head.add_child(UI.label("Lực chiến %s" % UI.fmt(Hero.power(h)), 26, UI.GOLD, UI.title))
	head.add_child(UI.label("Vàng %s   ·   Ngọc %d" % [UI.fmt(h.gold), int(h.jade)], 20, UI.GOLD, UI.bold))
	# --- menu (right)
	var right := UI.vbox(12)
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.anchor_top = 0.0
	right.anchor_bottom = 1.0
	right.offset_left = -440
	right.offset_right = -28
	right.offset_top = 28
	right.offset_bottom = -24
	ui.add_child(right)
	var b1 := UI.gold_button("Hành Tẩu Giang Hồ", func(): Game.goto(MapScreen.new()), 32)
	b1.custom_minimum_size.y = 86
	right.add_child(b1)
	var row := UI.hbox(12)
	right.add_child(row)
	var b2 := UI.button("Lôi Đài", func(): Flow.start_arena(0), 26)
	b2.custom_minimum_size.y = 72
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(b2)
	var b3 := UI.button("Luyện Công", func(): Flow.start_training(), 26)
	b3.custom_minimum_size.y = 72
	b3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(b3)
	right.add_child(UI.label("Lôi đài kỷ lục: %d trận liên thắng" % int(h.arena_best), 18, Color(0.85, 0.82, 0.75)))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(sp)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	right.add_child(grid)
	var pts := int(h.free_pts)
	var spts := int(h.skill_pts)
	var items := [
		["Nhân Vật" + (" (%d)" % pts if pts > 0 else ""), func(): Game.goto(CharacterScreen.new())],
		["Võ Công" + (" (%d)" % spts if spts > 0 else ""), func(): Game.goto(SkillScreen.new())],
		["Trang Bị", func(): Game.goto(GearScreen.new(false))],
		["Tiệm Binh Khí", func(): Game.goto(GearScreen.new(true))],
		["Cài Đặt", func(): ui.add_child(SettingsPanel.new())],
		["Rời Đi", back],
	]
	for it in items:
		var b := UI.button(it[0], it[1], 23)
		b.custom_minimum_size = Vector2(200, 62)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if (it[0] as String).contains("("):
			b.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		grid.add_child(b)

func back() -> void:
	Game.save()
	Game.goto(TitleScreen.new())
