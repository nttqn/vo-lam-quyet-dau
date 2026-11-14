class_name HubScreen
extends Screen
## Main hub: hero on stage, big story banner + mode tiles on the right,
## an icon dock along the bottom for the hero / shop / social screens.

const DOCK_H := 128.0

func _ready() -> void:
	_init_ui("temple")
	Game.music("menu")
	var h := Game.hero
	var s := Hero.sect(h)
	show.set_focus(1.4)
	show.add_body(Hero.look(h), s.style, 0.2, -0.5)
	shade(false, 0.55, 0.85)
	shade(true, 0.3, 0.55)
	_header(h, s)
	_right(h)
	_dock(h, s)

# ------------------------------------------------------------------ header
func _header(h: Dictionary, s: Dictionary) -> void:
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

# ------------------------------------------------------------- right column
func _right(h: Dictionary) -> void:
	var right := UI.vbox(14)
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.anchor_bottom = 1.0
	right.offset_left = -520
	right.offset_right = -24
	right.offset_top = 22
	right.offset_bottom = -DOCK_H - 10
	ui.add_child(right)
	# story banner
	var nx := _next_stage(h)
	var sub := "Toàn bộ giang hồ đã chinh phục" if nx.is_empty() else \
		"%s  ·  Trận %d/6" % [Journey.REGIONS[nx[0]].name, int(nx[1]) + 1]
	var b1 := _tile("Hành Tẩu Giang Hồ", sub, "journey", Color(0.78, 0.5, 0.12), func(): Game.goto(MapScreen.new()), 132, 32)
	right.add_child(b1)
	_glow(b1)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	right.add_child(grid)
	var dl := Duel.ensure(h)
	var tb := Tower.best(h)
	var modes := [
		["Tỉ Võ", "%s điểm" % UI.fmt(dl.score), "duel", Color(0.72, 0.14, 0.12), func(): Game.goto(DuelScreen.new())],
		["Tháp Thí Luyện", "Tầng %d" % tb if tb > 0 else "Chưa leo", "tower", Color(0.38, 0.22, 0.62), func(): Game.goto(TowerScreen.new())],
		["Lôi Đài", "Kỷ lục %d trận" % int(h.arena_best), "arena", Color(0.8, 0.36, 0.1), func(): Flow.start_arena(0)],
		["Luyện Công", "Tập chiêu", "train", Color(0.1, 0.48, 0.45), func(): Flow.start_training()],
	]
	for m in modes:
		var t := _tile(m[0], m[1], m[2], m[3], m[4], 112, 20)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(t)

func _next_stage(h: Dictionary) -> Array:
	for r in Journey.REGIONS.size():
		for st in 6:
			if Journey.unlocked(h, r, st) and not h.stars.has(Journey.stage_id(r, st)):
				return [r, st]
	return []

## Big lacquer tile: colour gradient, gold rim, emblem icon, title + subtitle.
func _tile(title: String, sub: String, ic: String, col: Color, cb: Callable, hgt: float, fs: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, hgt)
	b.clip_contents = true
	var rim := UI.GOLD if hgt > 120 else UI.GOLD_D.lightened(0.15)
	b.add_theme_stylebox_override("normal", _tile_box(col.darkened(0.35), rim, 3))
	b.add_theme_stylebox_override("hover", _tile_box(col.darkened(0.2), Color(1, 0.9, 0.6), 3))
	b.add_theme_stylebox_override("pressed", _tile_box(col.darkened(0.5), UI.GOLD, 3))
	b.pressed.connect(func():
		Game.sfx("click")
		cb.call())
	_press_bounce(b)
	# lighter band across the top half: reads as lacquer sheen
	var g := Gradient.new()
	g.set_color(0, Color(col.lightened(0.25), 0.55))
	g.set_color(1, Color(col, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 0.75)
	var sheen := TextureRect.new()
	sheen.texture = gt
	sheen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheen.stretch_mode = TextureRect.STRETCH_SCALE
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheen.offset_left = 3
	sheen.offset_right = -3
	sheen.offset_top = 3
	sheen.offset_bottom = -3
	b.add_child(sheen)
	var row := UI.hbox(8)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -10
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	b.add_child(row)
	var isz := hgt - 30.0 if hgt > 120 else 62.0
	var em := _emblem(ic, title, col, isz)
	em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(em)
	var tv := UI.vbox(0)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tv)
	var tl := UI.label(title, fs, Color(1, 0.96, 0.86), UI.title if hgt > 120 else UI.bold)
	tl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	tl.add_theme_constant_override("shadow_offset_y", 2)
	tl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(tl)
	var sl := UI.label(sub, 18 if hgt > 120 else 16, UI.GOLD.lightened(0.2), UI.med)
	sl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(sl)
	if hgt > 120:
		var chev := UI.label("›", 56, UI.GOLD, UI.title)
		chev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(chev)
	for c in [tl, sl]:
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _tile_box(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := UI.box(bg, border, bw, 16, 0)
	s.shadow_size = 8
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_offset = Vector2(0, 3)
	return s

## Menu art from assets/ui/menu/<key>.png; else a round lacquer emblem with
## the first letter.
func _emblem(key: String, title: String, col: Color, side: float) -> Control:
	var box := CenterContainer.new()
	box.custom_minimum_size = Vector2(side, side)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := "res://assets/ui/menu/%s.png" % key
	if ResourceLoader.exists(path):
		var r := TextureRect.new()
		r.texture = load(path)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.custom_minimum_size = Vector2(side, side)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(r)
		return box
	var disc := Panel.new()
	disc.custom_minimum_size = Vector2(side, side)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := UI.box(col.darkened(0.55), UI.GOLD, maxi(2, int(side / 26)), int(side / 2), 0)
	st.shadow_size = 0
	disc.add_theme_stylebox_override("panel", st)
	box.add_child(disc)
	var l := UI.label(title.substr(0, 1), int(side * 0.5), UI.GOLD.lightened(0.15), UI.title)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	return box

func _press_bounce(b: Control) -> void:
	b.resized.connect(func(): b.pivot_offset = b.size * 0.5)
	b.button_down.connect(func():
		create_tween().tween_property(b, "scale", Vector2(0.95, 0.95), 0.06))
	b.button_up.connect(func():
		create_tween().tween_property(b, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))

## Slow breathing glow on the main call to action.
func _glow(b: Control) -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(b, "self_modulate", Color(1.18, 1.1, 0.95), 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "self_modulate", Color.WHITE, 1.1).set_trans(Tween.TRANS_SINE)

# --------------------------------------------------------------- icon dock
func _dock(h: Dictionary, _s: Dictionary) -> void:
	var bar := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.05, 0.05, 0.86)
	sb.border_color = UI.GOLD_D
	sb.border_width_top = 2
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	bar.add_theme_stylebox_override("panel", sb)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.anchor_top = 1.0
	bar.anchor_right = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_top = -DOCK_H
	ui.add_child(bar)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -16
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(row)
	var dq := Daily.pending(h)
	var items := [
		["Nhân Vật", "hero", int(h.free_pts), Color(0.75, 0.3, 0.2), func(): Game.goto(CharacterScreen.new())],
		["Võ Công", "skill", int(h.skill_pts), Color(0.2, 0.45, 0.75), func(): Game.goto(SkillScreen.new())],
		["Trang Bị", "gear", 0, Color(0.55, 0.5, 0.45), func(): Game.goto(GearScreen.new(false))],
		["Tiệm Binh Khí", "shop", 0, Color(0.75, 0.55, 0.15), func(): Game.goto(GearScreen.new(true))],
		["Y Phục", "outfit", 0, Color(0.7, 0.3, 0.55), func(): Game.goto(WardrobeScreen.new())],
		["Nhiệm Vụ", "quest", dq, Color(0.3, 0.6, 0.3), func(): Game.goto(DailyScreen.new())],
		["Xếp Hạng", "rank", 0, Color(0.8, 0.65, 0.2), func(): Game.goto(RankScreen.new())],
		["Cài Đặt", "settings", 0, Color(0.45, 0.45, 0.5), func(): ui.add_child(SettingsPanel.new())],
		["Rời Đi", "exit", 0, Color(0.5, 0.2, 0.2), back],
	]
	for it in items:
		row.add_child(_dock_btn(it[0], it[1], it[2], it[3], it[4]))

func _dock_btn(title: String, ic: String, badge: int, col: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.flat = true
	var empty := StyleBoxEmpty.new()
	for k in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, empty)
	b.pressed.connect(func():
		Game.sfx("click")
		cb.call())
	_press_bounce(b)
	var v := UI.vbox(2)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 8
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(76, 76)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(holder)
	holder.add_child(_emblem(ic, title, col, 76))
	if badge > 0:
		var bd := Panel.new()
		var bs := UI.box(Color(0.85, 0.12, 0.1), Color(1, 0.85, 0.6), 2, 14, 0)
		bs.shadow_size = 0
		bd.add_theme_stylebox_override("panel", bs)
		bd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var txt := str(badge) if badge < 100 else "99+"
		var w := maxf(28.0, 14.0 + 11.0 * txt.length())
		bd.size = Vector2(w, 28)
		bd.position = Vector2(76 - w * 0.6, -4)
		var bl := UI.label(txt, 16, Color.WHITE, UI.bold)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bd.add_child(bl)
		holder.add_child(bd)
	var l := UI.label(title, 18, UI.PAPER, UI.bold)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	return b

func back() -> void:
	Game.save()
	Game.goto(TitleScreen.new())
