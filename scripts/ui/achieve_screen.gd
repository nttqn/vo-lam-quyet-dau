class_name AchieveScreen
extends Screen
## Thành tựu: one row per line (Achieve.LINES), its next tier, progress and
## the claim button; claimable rows first.

var _list: VBoxContainer
var _head: Label

func _ready() -> void:
	_init_ui("")
	painted_bg("peak")
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	var bar := top_bar("Thành Tựu", back)
	_head = UI.label("", 20, Color(0.85, 0.82, 0.75), UI.bold)
	bar.add_child(_head)
	bar.move_child(_head, 2)
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.offset_left = 24
	sc.offset_right = -24
	sc.offset_top = 90
	sc.offset_bottom = -12
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(sc)
	_list = UI.vbox(8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_list)
	_build()

func _build() -> void:
	var h := Game.hero
	for c in _list.get_children():
		c.queue_free()
	var pr := Achieve.progress(h)
	_head.text = "   %d/%d bậc" % [pr.x, pr.y]
	var ids: Array = Achieve.LINES.keys()
	# claimable first, finished lines last
	var rank := func(id) -> int:
		if Achieve.ready(h, id): return 0
		if Achieve.next_tier(h, id) < 0: return 2
		return 1
	ids.sort_custom(func(a, b): return rank.call(a) < rank.call(b))
	for id in ids:
		_list.add_child(_row(h, id))

func _row(h: Dictionary, id: String) -> Control:
	var k := Achieve.next_tier(h, id)
	var done := k < 0
	var ok := Achieve.ready(h, id)
	var p := UI.panel(Color(0.07, 0.05, 0.06, 0.92), UI.GOLD if ok else UI.GOLD_D)
	var row := UI.hbox(14)
	p.add_child(row)
	# tier pips
	var n: int = Achieve.tiers(id).size()
	var got := Achieve.claimed(h, id)
	var pips := UI.label("◆".repeat(got) + "◇".repeat(n - got), 18, UI.GOLD)
	pips.custom_minimum_size.x = 150
	pips.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var info := UI.vbox(3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var t := UI.hbox(10)
	info.add_child(t)
	t.add_child(UI.label(Achieve.title(id), 22, UI.GOLD if not done else Color(0.6, 0.58, 0.55), UI.title))
	t.add_child(pips)
	if done:
		info.add_child(UI.label("Đã hoàn thành mọi bậc", 18, Color(0.6, 1, 0.6)))
		return p
	var v := Achieve.value(h, id)
	var tg := Achieve.target(id, k)
	info.add_child(UI.label(Achieve.text(id, k), 19, UI.PAPER))
	var bar := ProgressBar.new()
	bar.max_value = tg
	bar.value = mini(v, tg)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.add_theme_stylebox_override("background", UI.box(Color(0.15, 0.12, 0.1), Color(0, 0, 0, 0), 0, 4, 0))
	bar.add_theme_stylebox_override("fill", UI.box(Color(0.45, 0.85, 0.4) if ok else UI.GOLD, Color(0, 0, 0, 0), 0, 4, 0))
	info.add_child(bar)
	var rw := Achieve.reward(id, k)
	info.add_child(UI.label("%d/%d   ·   Ngọc +%d  ·  Vàng +%s" % [mini(v, tg), tg, int(rw.jade), UI.fmt(int(rw.gold))], 15, Color(0.85, 0.82, 0.75)))
	var b := UI.gold_button("Nhận", func(): _claim(id), 20, 120)
	b.disabled = not ok
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	return p

func _claim(id: String) -> void:
	var rw := Achieve.claim(Game.hero, id)
	if rw.is_empty():
		return
	Game.sfx("levelup")
	toast("%s: Ngọc +%d · Vàng +%s" % [Achieve.title(id), int(rw.jade), UI.fmt(int(rw.gold))], Color(0.5, 1, 0.8))
	Game.save()
	refresh_wallet()
	_build()

func back() -> void:
	Game.goto(DailyScreen.new())
