class_name DungeonScreen
extends Screen
## Phó Bản: pick a dungeon (left) and a difficulty, see the master and the
## loot (right); fight a 3-duel run or sweep a cleared difficulty.

var sel := 0
var diff := -1
var _shown := -1   # difficulty whose master stands in the 3D view
var _right: VBoxContainer
var _list: VBoxContainer

func _init(p_sel := 0) -> void:
	sel = p_sel

func _ready() -> void:
	_init_ui(Dungeon.LIST[sel].theme)
	shade(true, 0.5, 0.85)
	shade(false, 0.6, 0.85)
	top_bar("Phó Bản", back)
	_list = UI.vbox(12)
	_list.position = Vector2(24, 96)
	_list.custom_minimum_size.x = 380
	ui.add_child(_list)
	var card := UI.panel(Color(0.06, 0.05, 0.07, 0.88))
	card.anchor_left = 1.0
	card.anchor_right = 1.0
	card.anchor_bottom = 1.0
	card.offset_left = -600
	card.offset_right = -24
	card.offset_top = 92
	card.offset_bottom = -20
	ui.add_child(card)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(sc)
	_right = UI.vbox(10)
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_right)
	_default_diff()
	_build()

## Highest difficulty open to the hero.
func _default_diff() -> void:
	diff = 0
	for d in Dungeon.DIFFS.size():
		if Dungeon.unlocked(Game.hero, sel, d):
			diff = d

func _build() -> void:
	var h := Game.hero
	refresh_wallet()
	for c in _list.get_children():
		c.queue_free()
	for c in _right.get_children():
		c.queue_free()
	var lb := UI.label("Lượt hôm nay: %d/%d" % [Dungeon.left(h), Dungeon.PER_DAY + int(Dungeon.ensure(h).ads)], 22, UI.GOLD, UI.bold)
	_list.add_child(lb)
	for i in Dungeon.LIST.size():
		_list.add_child(_dg_button(i))
	if Dungeon.can_ad(h):
		var ad := UI.button("▶ Quảng cáo: +1 lượt", _ad_entry, 19)
		ad.disabled = not Ads.is_ready()
		_list.add_child(ad)
	_list.add_child(_note("Mỗi lượt gồm 3 ải liên tiếp, sinh lực mang sang ải sau (hồi 25%). Thua không mất lượt. Độ khó đã vượt có thể Quét ngay."))
	_build_right(h)

func _note(t: String) -> Label:
	var l := UI.label(t, 16, Color(0.78, 0.75, 0.68))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 380
	return l

func _dg_button(i: int) -> Button:
	var dg: Dictionary = Dungeon.LIST[i]
	var col: Color = dg.col
	var b := Button.new()
	b.custom_minimum_size = Vector2(380, 96)
	var on := i == sel
	b.add_theme_stylebox_override("normal", UI.box(col.darkened(0.6 if not on else 0.35), UI.GOLD if on else col.darkened(0.2), 3 if on else 2, 14, 0))
	b.add_theme_stylebox_override("hover", UI.box(col.darkened(0.3), UI.GOLD, 3, 14, 0))
	b.add_theme_stylebox_override("pressed", UI.box(col.darkened(0.5), UI.GOLD, 3, 14, 0))
	b.pressed.connect(func():
		Game.sfx("click")
		if sel != i:
			Game.goto(DungeonScreen.new(i)))
	var row := UI.hbox(12)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var gm := Mats.gem(dg.mat, 60)
	gm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(gm)
	var v := UI.vbox(2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(v)
	var t := UI.label(dg.name, 22, Color(1, 0.95, 0.85), UI.bold)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	var best := Dungeon.best(Game.hero, i)
	var s := UI.label("Rơi: %s  ·  %s" % [Mats.name_of(dg.mat), ("Đã vượt " + Dungeon.DIFFS[best][0]) if best >= 0 else "Chưa vượt"], 16, UI.GOLD.lightened(0.2))
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(s)
	return b

func _build_right(h: Dictionary) -> void:
	var dg: Dictionary = Dungeon.LIST[sel]
	_right.add_child(UI.heading(dg.name, 44))
	var d := UI.label(dg.desc, 18, Color(0.85, 0.82, 0.75))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(d)
	# difficulty chips
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_right.add_child(grid)
	for k in Dungeon.DIFFS.size():
		var kk := k
		var ok := Dungeon.unlocked(h, sel, k)
		var cleared := Dungeon.best(h, sel) >= k
		var txt: String = Dungeon.DIFFS[k][0] + (" ✓" if cleared else "")
		if not ok:
			txt = "🔒 Cấp %d" % int(Dungeon.DIFFS[k][1]) if int(h.level) < int(Dungeon.DIFFS[k][1]) else "🔒 " + Dungeon.DIFFS[k][0]
		var b := UI.gold_button(txt, func(): _pick(kk), 19, 170) if k == diff else UI.button(txt, func(): _pick(kk), 19, 170)
		b.disabled = not ok
		grid.add_child(b)
	var boss := Dungeon.side(sel, diff, Dungeon.FIGHTS - 1)
	if show and _shown != diff:
		_shown = diff
		show.clear()
		show.add_body(boss.look, Sects.get_sect(boss.sect).style, -0.2, -0.6)
		show.set_focus(0.2)
	_right.add_child(UI.label("Chủ ải: %s  ·  %s  ·  Cấp %d" % [boss.name, Sects.get_sect(boss.sect).name, int(boss.level)], 20, UI.PAPER, UI.bold))
	_right.add_child(UI.label("Lực chiến của bạn: %s   ·   Chủ ải: %s" % [UI.fmt(Hero.power(h)), UI.fmt(Build.power(boss.stats))], 18, Color(0.85, 0.82, 0.75)))
	# loot
	var lp := UI.panel(Color(0.1, 0.07, 0.05, 0.9), Mats.color(dg.mat).darkened(0.3))
	var lv := UI.vbox(6)
	lp.add_child(lv)
	lv.add_child(UI.label("Phần thưởng mỗi lượt", 20, UI.GOLD, UI.bold))
	var mrow := UI.hbox(10)
	mrow.add_child(Mats.gem(dg.mat, 40))
	mrow.add_child(UI.label("%s ×%d" % [Mats.name_of(dg.mat), Dungeon.main_amount(dg.mat, diff)], 24, Mats.color(dg.mat), UI.bold))
	lv.add_child(mrow)
	var rw := Dungeon.rewards(h, sel, diff, false, RandomNumberGenerator.new())
	var extra := "Vàng +%d  ·  KN +%d  ·  có cơ hội rơi thêm nguyên liệu khác hoặc Hộ Phù" % [int(rw.gold), int(rw.exp)]
	if Dungeon.best(h, sel) < diff:
		extra += "  ·  Lần đầu: Ngọc +%d" % (5 + 2 * diff)
	var el := UI.label(extra, 17, Color(0.85, 0.82, 0.75))
	el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_child(el)
	_right.add_child(lp)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right.add_child(sp)
	var row := UI.hbox(12)
	_right.add_child(row)
	var can := Dungeon.left(h) > 0 and Dungeon.unlocked(h, sel, diff)
	var sw := UI.button("Quét", _sweep, 26, 150)
	sw.disabled = not can or Dungeon.best(h, sel) < diff
	sw.custom_minimum_size.y = 72
	row.add_child(sw)
	var go := UI.gold_button("Khiêu Chiến", func(): Flow.start_dungeon(sel, diff), 30)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.custom_minimum_size.y = 72
	go.disabled = not can
	row.add_child(go)
	if Dungeon.left(h) <= 0:
		_right.add_child(UI.label("Hết lượt hôm nay. Quay lại vào ngày mai!", 18, Color(1, 0.65, 0.5)))

func _pick(k: int) -> void:
	diff = k
	_build()

func _sweep() -> void:
	var rw := Flow.sweep_dungeon(sel, diff)
	if rw.is_empty():
		return
	Game.sfx("coin")
	var msg := Mats.text(rw.mats) + "  ·  Vàng +%d" % int(rw.gold)
	_build()
	toast("Quét xong: " + msg, Color(0.6, 1, 0.7))
	if int(rw.get("levels", 0)) > 0:
		Game.sfx("levelup")

func _ad_entry() -> void:
	if not Ads.show_rewarded(func():
		Dungeon.add_ad_entry(Game.hero)
		Game.save()
		if is_inside_tree():
			_build(), Callable(), "dungeon"):
		toast("Chưa có quảng cáo, thử lại sau", Color(1, 0.7, 0.5))

func back() -> void:
	Game.goto(HubScreen.new())
