class_name MapScreen
extends Screen
## Journey: region tabs + duel list.

static var last_region := -1
var region := 0
var _tabs: VBoxContainer
var _list: VBoxContainer
var _title: Label
var _intro: Label

func _ready() -> void:
	var h := Game.hero
	region = last_region
	if region < 0 or not Journey.region_unlocked(h, region):
		region = 0
		for r in Journey.REGIONS.size():
			if Journey.region_unlocked(h, r):
				region = r
	_init_ui(Journey.REGIONS[region].theme)
	show.set_focus(0.0)
	show.cam.position = Vector3(0, 2.4, 8)
	show.cam.look_at(Vector3(0, 1.5, -6))
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	top_bar("Hành Tẩu Giang Hồ", back)
	var tabs_scroll := ScrollContainer.new()
	tabs_scroll.anchor_bottom = 1.0
	tabs_scroll.offset_left = 20
	tabs_scroll.offset_right = 330
	tabs_scroll.offset_top = 92
	tabs_scroll.offset_bottom = -16
	tabs_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(tabs_scroll)
	_tabs = UI.vbox(8)
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs_scroll.add_child(_tabs)
	var right := UI.vbox(8)
	right.anchor_right = 1.0
	right.anchor_bottom = 1.0
	right.offset_left = 350
	right.offset_right = -24
	right.offset_top = 92
	right.offset_bottom = -16
	ui.add_child(right)
	_title = UI.heading("", 40)
	right.add_child(_title)
	_intro = UI.label("", 20, Color(0.9, 0.86, 0.78))
	_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_intro)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc)
	_list = UI.vbox(8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_list)
	_build()

func _build() -> void:
	var h := Game.hero
	for c in _tabs.get_children():
		c.queue_free()
	for r in Journey.REGIONS.size():
		var reg: Dictionary = Journey.REGIONS[r]
		var ok := Journey.region_unlocked(h, r)
		var t := "%d. %s" % [r + 1, reg.name] if ok else "%d. ???" % (r + 1)
		var b := UI.button(t, func(): _select(r), 20)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not ok
		b.toggle_mode = true
		b.button_pressed = r == region
		b.custom_minimum_size.y = 58
		var stars := Journey.region_stars(h, r)
		if ok:
			b.text += "\n     ★ %d/18   ·   Cấp %d+" % [stars, reg.lvl]
			b.custom_minimum_size.y = 76
		_tabs.add_child(b)
	var reg2: Dictionary = Journey.REGIONS[region]
	_title.text = reg2.name
	_intro.text = reg2.intro
	for c in _list.get_children():
		c.queue_free()
	for s in 6:
		_list.add_child(_stage_card(region, s))

func _select(r: int) -> void:
	if r == region:
		_build()
		return
	last_region = r
	Game.goto(MapScreen.new())

func _stage_card(r: int, s: int) -> Control:
	var h := Game.hero
	var reg: Dictionary = Journey.REGIONS[r]
	var foe: Array = reg.foes[s]
	var ok := Journey.unlocked(h, r, s)
	var sid := Journey.stage_id(r, s)
	var stars := int(h.stars.get(sid, 0))
	var boss := s == 5
	var p := UI.panel(Color(0.12, 0.06, 0.05, 0.9) if boss else Color(0.07, 0.06, 0.07, 0.88), UI.GOLD if boss else UI.GOLD_D)
	var row := UI.hbox(14)
	p.add_child(row)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var lvl := Journey.stage_level(r, s)
	var sect := Sects.get_sect(foe[2])
	if ok:
		var nm := UI.label(("☠ " if boss else "") + "%s  —  %s" % [foe[0], foe[1]], 24, UI.GOLD if boss else UI.PAPER, UI.bold)
		info.add_child(nm)
		var col := Color(0.6, 1, 0.6) if lvl <= int(h.level) else (Color(1, 0.85, 0.4) if lvl <= int(h.level) + 2 else Color(1, 0.45, 0.4))
		info.add_child(UI.label("Võ công %s  ·  Cấp %d" % [sect.name, lvl], 19, col))
	else:
		info.add_child(UI.label("??? — Chưa mở", 22, Color(0.55, 0.52, 0.5)))
	var st := UI.label("★".repeat(stars) + "☆".repeat(3 - stars), 30, UI.GOLD if stars > 0 else Color(0.5, 0.48, 0.45))
	row.add_child(st)
	var b := UI.gold_button("Khiêu chiến" if stars == 0 else "Đấu lại", func(): Flow.start_stage(r, s), 22, 170) if ok else UI.button("Khóa", func(): pass, 22, 170)
	b.disabled = not ok
	row.add_child(b)
	return p

func back() -> void:
	Game.goto(HubScreen.new())
