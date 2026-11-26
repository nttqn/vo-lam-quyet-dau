class_name MapScreen
extends Screen
## Journey: region tabs + duel list, story (Thường) or Ác Mộng.

static var last_region := -1
static var last_nm := false
const NM_COL := Color(0.85, 0.6, 1.0)
var region := 0
var nm := false
var _tabs: VBoxContainer
var _list: VBoxContainer
var _title: Label
var _intro: Label
var _mode_row: HBoxContainer

func _ready() -> void:
	var h := Game.hero
	nm = last_nm and int(h.level) >= Journey.NM_MIN_LEVEL
	region = last_region
	if region < 0 or not _region_ok(h, region):
		region = 0
		for r in Journey.REGIONS.size():
			if _region_ok(h, r):
				region = r
	_init_ui(Journey.REGIONS[region].theme)
	show.set_focus(0.0)
	show.cam.position = Vector3(0, 2.4, 8)
	show.cam.look_at(Vector3(0, 1.5, -6))
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.55) if not nm else Color(0.06, 0.02, 0.08, 0.66)
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
	var head := UI.hbox(12)
	right.add_child(head)
	_title = UI.heading("", 40)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	head.add_child(_title)
	_mode_row = UI.hbox(6)
	head.add_child(_mode_row)
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

func _region_ok(h: Dictionary, r: int) -> bool:
	return Journey.nm_region_open(h, r) if nm else Journey.region_unlocked(h, r)

func _build() -> void:
	var h := Game.hero
	for c in _mode_row.get_children():
		c.queue_free()
	var nm_open := int(h.level) >= Journey.NM_MIN_LEVEL
	for m in [[false, "Thường"], [true, "Ác Mộng" if nm_open else L.f("Ác Mộng · Cấp %d", Journey.NM_MIN_LEVEL)]]:
		var want: bool = m[0]
		var b := UI.button(m[1], func(): _set_mode(want), 19)
		b.toggle_mode = true
		b.button_pressed = want == nm
		b.custom_minimum_size = Vector2(0, 46)
		b.disabled = want and not nm_open
		if want and nm_open:
			b.add_theme_color_override("font_color", NM_COL)
		_mode_row.add_child(b)
	for c in _tabs.get_children():
		c.queue_free()
	for r in Journey.REGIONS.size():
		var reg: Dictionary = Journey.REGIONS[r]
		var ok := _region_ok(h, r)
		var seen := Journey.region_unlocked(h, r)
		var t := L.f("%d. %s", [r + 1, reg.name]) if seen else L.f("%d. ???", (r + 1))
		var b := UI.button(t, func(): _select(r), 20)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not ok
		b.toggle_mode = true
		b.button_pressed = r == region
		b.custom_minimum_size.y = 58
		if ok:
			if nm:
				b.text += L.f("\n     ★ %d/18   ·   Cấp %d+", [Journey.nm_region_stars(h, r), Journey.nm_level(r, 0)])
			else:
				b.text += L.f("\n     ★ %d/18   ·   Cấp %d+", [Journey.region_stars(h, r), reg.lvl])
			b.custom_minimum_size.y = 76
		if not nm and seen and int(KyNgo.current(h).get("r", -1)) == r:
			b.text = L.f("%d. %s", [r + 1, reg.name]) + "  ✦" + b.text.substr(L.f("%d. %s", [r + 1, reg.name]).length())
			b.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
		_tabs.add_child(b)
	var reg2: Dictionary = Journey.REGIONS[region]
	_title.text = reg2.name
	_title.add_theme_color_override("font_color", NM_COL if nm else UI.GOLD)
	_intro.text = reg2.intro if not nm else L.f("Ác Mộng: đối thủ cấp %d–%d, ra đòn hiểm hơn. Lần đầu thắng mỗi trận nhận Ngọc, Huyền Thiết, Tẩy Luyện Thạch; thủ lĩnh rơi trang bị bậc cao và Thiên Tinh Thạch.", [Journey.nm_level(region, 0), Journey.nm_level(region, 5)])
	for c in _list.get_children():
		c.queue_free()
	if nm and not _region_ok(h, region):
		_list.add_child(UI.label(Journey.nm_lock(h, region, 0), 22, Color(0.8, 0.75, 0.7)))
		return
	var kc := KyNgo.current(h)
	if not nm and not kc.is_empty() and int(kc.r) == region:
		_list.add_child(_kyngo_card(kc))
	for s in 6:
		_list.add_child(_stage_card(region, s))

## Kỳ Ngộ waiting in this region: who, the twist, the prize.
func _kyngo_card(kc: Dictionary) -> Control:
	var col := Color(0.6, 0.9, 1.0)
	var p := UI.panel(Color(0.04, 0.1, 0.14, 0.92), col)
	var row := UI.hbox(14)
	p.add_child(row)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UI.label(L.f("✦ Kỳ Ngộ: %s — %s", [kc.name, KyNgo.title(str(kc.kind))]), 23, col, UI.bold))
	var lvl := mini(Hero.MAX_LEVEL + 5, int(Game.hero.level) + int(KyNgo.KINDS[str(kc.kind)][2]))
	var sub := L.f("Võ công %s  ·  Cấp %d", [Sects.get_sect(str(kc.sect)).name, lvl])
	if int(kc.get("tries", 0)) > 0:
		sub += "  ·  " + L.f("còn %d lần thử", KyNgo.TRIES - int(kc.tries))
	info.add_child(UI.label(sub, 18, Color(0.85, 0.9, 0.95)))
	var pr := UI.label(KyNgo.promise(kc), 16, Color(0.8, 0.85, 0.85))
	pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(pr)
	var b := UI.gold_button("Gặp gỡ", Flow.start_kyngo, 22, 170)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	return p

func _set_mode(want: bool) -> void:
	if want == nm:
		_build()
		return
	last_nm = want
	Game.goto(MapScreen.new())

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
	var lock := Journey.nm_lock(h, r, s) if nm else ("" if Journey.unlocked(h, r, s) else "Chưa mở")
	var ok := lock == ""
	var stars := Journey.nm_stars(h, r, s) if nm else int(h.stars.get(Journey.stage_id(r, s), 0))
	var boss := s == 5
	var bg := Color(0.12, 0.06, 0.05, 0.9) if boss else Color(0.07, 0.06, 0.07, 0.88)
	if nm:
		bg = Color(0.12, 0.05, 0.14, 0.9) if boss else Color(0.08, 0.05, 0.1, 0.88)
	var p := UI.panel(bg, (NM_COL if nm else UI.GOLD) if boss else UI.GOLD_D)
	var row := UI.hbox(14)
	p.add_child(row)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var lvl := Journey.nm_level(r, s) if nm else Journey.stage_level(r, s)
	var sect := Sects.get_sect(foe[2])
	if ok or (nm and stars > 0):
		var nm_col := NM_COL if nm else UI.GOLD
		var nml := UI.label(("☠ " if boss else "") + L.f("%s  —  %s", [foe[0], foe[1]]), 24, nm_col if boss else UI.PAPER, UI.bold)
		info.add_child(nml)
		var col := Color(0.6, 1, 0.6) if lvl <= int(h.level) else (Color(1, 0.85, 0.4) if lvl <= int(h.level) + 2 else Color(1, 0.45, 0.4))
		info.add_child(UI.label(L.f("Võ công %s  ·  Cấp %d", [sect.name, lvl]), 19, col))
	else:
		info.add_child(UI.label("??? — " + L.t(lock), 22, Color(0.55, 0.52, 0.5)))
	var st := UI.label("★".repeat(stars) + "☆".repeat(3 - stars), 30, (NM_COL if nm else UI.GOLD) if stars > 0 else Color(0.5, 0.48, 0.45))
	row.add_child(st)
	var b: Button
	if ok:
		var is_nm := nm
		b = UI.gold_button("Khiêu chiến" if stars == 0 else "Đấu lại", func(): Flow.start_any(r, s, is_nm), 22, 170)
	else:
		b = UI.button("Khóa", func(): pass, 22, 170)
		b.disabled = true
	row.add_child(b)
	return p

func back() -> void:
	Game.goto(HubScreen.new())
