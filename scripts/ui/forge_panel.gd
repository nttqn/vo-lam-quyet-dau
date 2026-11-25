class_name ForgePanel
extends ColorRect
## Lò Rèn: modal over the gear screen for one equipped item.
## Tabs: Cường Hóa (+level with odds), Thăng Phẩm (rarity), Tẩy Luyện (bonus lines).

signal changed

var slot: String
var tab := 0
var use_charm := false
var _pending: Array = []   # rerolled lines waiting for "keep new / keep old"
var _left: VBoxContainer
var _right: VBoxContainer
var _tile: Panel
var _wallet: HBoxContainer
var _rng := RandomNumberGenerator.new()

func _init(p_slot: String, p_tab := 0) -> void:
	slot = p_slot
	tab = p_tab
	_rng.randomize()

func _ready() -> void:
	add_to_group("modal")
	color = Color(0, 0, 0, 0.72)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var p := UI.panel(Color(0.08, 0.05, 0.05, 0.97), UI.GOLD_D)
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 60
	p.offset_right = -60
	p.offset_top = 24
	p.offset_bottom = -24
	add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	var top := UI.hbox(14)
	v.add_child(top)
	top.add_child(UI.heading("Lò Rèn", 40))
	_wallet = UI.hbox(14)
	_wallet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wallet.alignment = BoxContainer.ALIGNMENT_END
	_wallet.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_wallet)
	top.add_child(UI.button("Đóng", close, 22, 110))
	var cols := UI.hbox(20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cols)
	_left = UI.vbox(8)
	_left.custom_minimum_size.x = 400
	cols.add_child(_left)
	var sep := ColorRect.new()
	sep.color = Color(UI.GOLD_D, 0.5)
	sep.custom_minimum_size.x = 2
	cols.add_child(sep)
	var rsc := ScrollContainer.new()
	rsc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(rsc)
	_right = UI.vbox(12)
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.add_child(_right)
	_build()

func _item() -> Dictionary:
	return Game.hero.gear.get(slot, {})

func _style() -> String:
	return Hero.sect(Game.hero).style

## Also reached via Android back (Game frees the newest "modal" node), so the
## gear screen is told from _exit_tree, not here.
func close() -> void:
	queue_free()

func _exit_tree() -> void:
	changed.emit()

func _keep_old() -> void:
	_pending = []
	_build()

func _clear(c: Node) -> void:
	for ch in c.get_children():
		c.remove_child(ch)
		ch.queue_free()

func _build() -> void:
	var h := Game.hero
	var it := _item()
	if it.is_empty():
		close()
		return
	Items.ensure_aff(it)
	_clear(_wallet)
	var gl := UI.label(L.f("Vàng %s  ·  Ngọc %d", [UI.fmt(h.gold), int(h.jade)]), 20, UI.GOLD, UI.bold)
	gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_wallet.add_child(gl)
	for id in Mats.IDS:
		_wallet.add_child(Mats.chip(h, id, -1, 32))
	_build_left(it)
	_clear(_right)
	var tabs := UI.hbox(8)
	_right.add_child(tabs)
	var names := ["Cường Hóa", "Thăng Phẩm", "Tẩy Luyện"]
	for i in names.size():
		var idx := i
		var b := UI.gold_button(names[i], func(): _set_tab(idx), 22, 170) if i == tab else UI.button(names[i], func(): _set_tab(idx), 22, 170)
		tabs.add_child(b)
	match tab:
		0: _tab_enhance(it)
		1: _tab_ascend(it)
		2: _tab_wash(it)

func _set_tab(i: int) -> void:
	if not _pending.is_empty():
		return   # decide on the rerolled lines first
	tab = i
	_build()

# ------------------------------------------------------------- item card
func _build_left(it: Dictionary) -> void:
	_clear(_left)
	var rar := int(it.rar)
	var rc: Color = Items.RARITY_COL[rar]
	var head := UI.hbox(14)
	_left.add_child(head)
	_tile = Panel.new()
	_tile.custom_minimum_size = Vector2(128, 128)
	_tile.add_theme_stylebox_override("panel", UI.box(rc.darkened(0.7), rc, 3, 14, 0))
	head.add_child(_tile)
	var tex := Items.icon(it, _style())
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = 8
		tr.offset_top = 8
		tr.offset_right = -8
		tr.offset_bottom = -8
		_tile.add_child(tr)
	var pl := UI.label("+%d" % int(it.get("plus", 0)), 30, Color(1, 0.95, 0.75), UI.title)
	pl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	pl.add_theme_constant_override("outline_size", 6)
	pl.position = Vector2(8, 84)
	_tile.add_child(pl)
	var hv := UI.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	var nl := UI.label(Items.item_name(it, _style()), 26, rc, UI.bold)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hv.add_child(nl)
	hv.add_child(UI.label(L.f("%s  ·  %s", [Items.SLOT_NAMES[it.slot], Items.RARITY[rar]]), 19, Color(0.85, 0.82, 0.75)))
	var gl := Items.glow_level(int(it.get("plus", 0)))
	if it.slot == "weapon" and gl > 0:
		hv.add_child(UI.label(["", "Linh quang", "Tử quang", "Kim quang", "Thần quang"][gl], 18, _glow_col(gl), UI.bold))
	_left.add_child(UI.label("Chỉ số chính", 20, UI.GOLD, UI.bold))
	var bs := Items.base_stats(it)
	for k in bs:
		if float(bs[k]) != 0.0:
			_left.add_child(UI.label("  " + Items.one_stat(k, float(bs[k])), 20))
	_left.add_child(UI.label("Thuộc tính phụ", 20, UI.GOLD, UI.bold))
	var aff: Array = it.get("aff", [])
	if aff.is_empty():
		_left.add_child(UI.label("  Không có (đồ Phàm phẩm). Thăng phẩm để mở dòng.", 17, Color(0.65, 0.62, 0.58)))
	for a in aff:
		_left.add_child(_aff_row(it, a))
	var lk := float(it.get("luck", 0.0))
	if lk > 0.0:
		_left.add_child(UI.label(L.f("Phúc khí: +%d%% tỉ lệ cường hóa lần tới", int(round(lk * 100))), 18, Color(0.6, 0.9, 1.0), UI.bold))

func _aff_row(it: Dictionary, a: Dictionary) -> Control:
	var row := UI.hbox(8)
	var col := Items.aff_color(a)
	var l := UI.label("  ◆ " + Items.aff_text(it, a), 20, col, UI.bold)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	# quality bar
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(90, 10)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.max_value = 1.0
	bar.step = 0.01
	bar.value = float(a.get("q", 0.0))
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	fill.set_corner_radius_all(4)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	row.add_child(bar)
	return row

static func _glow_col(g: int) -> Color:
	return [Color.WHITE, Color(0.5, 0.8, 1.0), Color(0.8, 0.5, 1.0), Color(1.0, 0.8, 0.3), Color(1.0, 0.45, 0.3)][clampi(g, 0, 4)]

func _cost_row(parts: Array) -> HBoxContainer:
	var row := UI.hbox(18)
	row.add_child(UI.label("Tiêu hao:", 20, Color(0.85, 0.82, 0.75)))
	for p in parts:
		row.add_child(p)
	return row

func _gold_chip(need: int) -> Label:
	var ok := int(Game.hero.gold) >= need
	return UI.label(L.f("Vàng %s", UI.fmt(need)), 20, UI.GOLD if ok else Color(1, 0.45, 0.4), UI.bold)

func _wrap(t: String, size := 18, col := Color(0.8, 0.77, 0.7)) -> Label:
	var l := UI.label(t, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

# ------------------------------------------------------------- Cường Hóa
func _tab_enhance(it: Dictionary) -> void:
	var h := Game.hero
	var p := int(it.get("plus", 0))
	if p >= Items.MAX_PLUS:
		_right.add_child(UI.heading(L.f("+%d — Tối đa", p), 44))
		_right.add_child(_wrap("Trang bị đã đạt cảnh giới cao nhất. Vũ khí +15 tỏa Thần quang trong trận."))
		return
	_right.add_child(UI.heading("+%d  →  +%d" % [p, p + 1], 48))
	# stat preview
	var nx := it.duplicate(true)
	nx.plus = p + 1
	var a := Items.base_stats(it)
	var b := Items.base_stats(nx)
	for k in a:
		if float(a[k]) != 0.0:
			var t := L.f("%s  →  %s", [Items.one_stat(k, float(a[k])), Items.one_stat(k, float(b[k])).split(" +")[1]])
			_right.add_child(UI.label(t, 21, Color(0.7, 1.0, 0.7)))
	var r := Items.rate(it)
	var rl := UI.label(L.f("Tỉ lệ thành công: %d%%", int(round(r * 100))), 30, _rate_col(r), UI.title)
	_right.add_child(rl)
	if float(it.get("luck", 0.0)) > 0.0:
		_right.add_child(UI.label(L.f("(gồm +%d%% phúc khí từ các lần thất bại trước)", int(round(float(it.luck) * 100))), 17, Color(0.6, 0.9, 1.0)))
	var gold := Items.upgrade_cost(it)
	var iron := Items.iron_cost(it)
	_right.add_child(_cost_row([_gold_chip(gold), Mats.chip(h, "iron", iron, 34)]))
	if p >= Items.DROP_FROM:
		_right.add_child(_wrap(L.f("Thất bại sẽ tụt về +%d. Mỗi lần thất bại cộng %d%% phúc khí.", [p - 1, int(Items.LUCK_STEP * 100)]), 18, Color(1, 0.65, 0.5)))
		var cb := CheckBox.new()
		cb.text = "Dùng 1 Hộ Phù (giữ cấp nếu thất bại)"
		cb.add_theme_font_size_override("font_size", 20)
		cb.button_pressed = use_charm and Mats.count(h, "charm") > 0
		cb.disabled = Mats.count(h, "charm") <= 0
		cb.toggled.connect(func(on: bool): use_charm = on)
		var crow := UI.hbox(10)
		crow.add_child(cb)
		crow.add_child(Mats.chip(h, "charm", -1, 30))
		_right.add_child(crow)
	elif p >= 5:
		_right.add_child(_wrap(L.f("Thất bại giữ nguyên cấp, cộng %d%% phúc khí. Từ +%d trở lên thất bại sẽ tụt cấp.", [int(Items.LUCK_STEP * 100), Items.DROP_FROM]), 18))
	else:
		_right.add_child(_wrap("+1 đến +5 luôn thành công. Vũ khí +7 trở lên phát sáng trong trận.", 18))
	var go := UI.gold_button("Cường Hóa", _do_enhance, 30, 260)
	go.custom_minimum_size.y = 70
	go.disabled = int(h.gold) < gold or Mats.count(h, "iron") < iron
	_right.add_child(go)
	if Mats.count(h, "iron") < iron:
		_right.add_child(_wrap(L.f("Thiếu Huyền Thiết: %s.", Mats.INFO.iron[3]), 17, Color(1, 0.7, 0.55)))

static func _rate_col(r: float) -> Color:
	if r >= 0.99: return Color(0.6, 1.0, 0.6)
	if r >= 0.6: return Color(0.9, 1.0, 0.5)
	if r >= 0.4: return Color(1.0, 0.8, 0.4)
	return Color(1.0, 0.5, 0.4)

func _do_enhance() -> void:
	var h := Game.hero
	var it := _item()
	var gold := Items.upgrade_cost(it)
	var iron := Items.iron_cost(it)
	if int(it.get("plus", 0)) >= Items.MAX_PLUS or int(h.gold) < gold or Mats.count(h, "iron") < iron:
		return
	var charm := use_charm and int(it.get("plus", 0)) >= Items.DROP_FROM and Mats.count(h, "charm") > 0
	h.gold = int(h.gold) - gold
	Mats.spend(h, "iron", iron)
	var res := Items.enhance(it, charm, _rng)
	if charm and not res.ok:
		Mats.spend(h, "charm", 1)   # the charm only burns when it saved the level
	Daily.track(h, "upgrade")
	Game.save()
	_build()
	if res.ok:
		Game.sfx("levelup")
		_burst(L.f("Thành công!  +%d", int(res.to)), Color(1, 0.85, 0.35))
	else:
		Game.sfx("lose", 0.05, 0.8)
		var msg := L.t("Thất bại")
		if int(res.to) < int(res.from):
			msg += L.f(" — tụt về +%d", int(res.to))
		elif charm:
			msg += L.t(" — Hộ Phù giữ cấp")
		_burst(msg, Color(1, 0.45, 0.4), true)

## Big pop-up text over the item tile, plus a flash (success) or shake (failure).
func _burst(text: String, col: Color, fail := false) -> void:
	var l := UI.label(text, 44, col, UI.title)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.offset_left = -500
	l.offset_right = 500
	l.offset_top = -60
	l.offset_bottom = 0
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.pivot_offset = Vector2(500, 30)
	l.scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)
	if is_instance_valid(_tile):
		var t2 := create_tween()
		if fail:
			var x := _tile.position.x
			for i in 4:
				t2.tween_property(_tile, "position:x", x + (10 if i % 2 == 0 else -10), 0.04)
			t2.tween_property(_tile, "position:x", x, 0.04)
		else:
			_tile.modulate = Color(2.2, 2.0, 1.4)
			t2.tween_property(_tile, "modulate", Color.WHITE, 0.6)

# ------------------------------------------------------------- Thăng Phẩm
func _tab_ascend(it: Dictionary) -> void:
	var h := Game.hero
	var r := int(it.rar)
	if r >= Items.MAX_RAR:
		_right.add_child(UI.heading("Truyền Thuyết", 44))
		_right.add_child(_wrap("Đã đạt phẩm cao nhất."))
		return
	var row := UI.hbox(16)
	row.add_child(UI.label(Items.RARITY[r], 40, Items.RARITY_COL[r], UI.title))
	row.add_child(UI.label("→", 40, UI.PAPER, UI.title))
	row.add_child(UI.label(Items.RARITY[r + 1], 40, Items.RARITY_COL[r + 1], UI.title))
	_right.add_child(row)
	var nx := it.duplicate(true)
	nx.rar = r + 1
	var a := Items.base_stats(it)
	var b := Items.base_stats(nx)
	for k in a:
		if float(a[k]) != 0.0:
			_right.add_child(UI.label(L.f("%s  →  %s", [Items.one_stat(k, float(a[k])), Items.one_stat(k, float(b[k])).split(" +")[1]]), 21, Color(0.7, 1.0, 0.7)))
	_right.add_child(_wrap(L.f("Giữ nguyên cấp cường hóa +%d. Mở thêm 1 dòng thuộc tính phụ (ngẫu nhiên).", int(it.get("plus", 0))), 19, Color(0.85, 0.82, 0.75)))
	var c := Items.ascend_cost(it)
	_right.add_child(_cost_row([_gold_chip(int(c.gold)), Mats.chip(h, "star", int(c.star), 34)]))
	var go := UI.gold_button("Thăng Phẩm", _do_ascend, 30, 260)
	go.custom_minimum_size.y = 70
	go.disabled = int(h.gold) < int(c.gold) or Mats.count(h, "star") < int(c.star)
	_right.add_child(go)
	if Mats.count(h, "star") < int(c.star):
		_right.add_child(_wrap(L.f("Thiếu Thiên Tinh Thạch: %s.", Mats.INFO.star[3]), 17, Color(1, 0.7, 0.55)))

func _do_ascend() -> void:
	var h := Game.hero
	var it := _item()
	var c := Items.ascend_cost(it)
	if int(it.rar) >= Items.MAX_RAR or int(h.gold) < int(c.gold) or Mats.count(h, "star") < int(c.star):
		return
	h.gold = int(h.gold) - int(c.gold)
	Mats.spend(h, "star", int(c.star))
	Items.ascend(it)
	Daily.track(h, "upgrade")
	Game.save()
	_build()
	Game.sfx("levelup")
	_burst(L.f("Thăng phẩm: %s!", Items.RARITY[int(it.rar)]), Items.RARITY_COL[int(it.rar)])

# ------------------------------------------------------------- Tẩy Luyện
func _tab_wash(it: Dictionary) -> void:
	var h := Game.hero
	var aff: Array = it.get("aff", [])
	if aff.is_empty():
		_right.add_child(_wrap("Đồ Phàm phẩm chưa có thuộc tính phụ. Hãy Thăng Phẩm trước.", 21, Color(0.85, 0.82, 0.75)))
		return
	if not _pending.is_empty():
		var cols := UI.hbox(24)
		_right.add_child(cols)
		for side in 2:
			var v := UI.vbox(6)
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cols.add_child(v)
			v.add_child(UI.label("Hiện tại" if side == 0 else "Kết quả mới", 22, UI.GOLD, UI.bold))
			for a in (aff if side == 0 else _pending):
				v.add_child(_aff_row(it, a))
			v.add_child(UI.label(L.f("Điểm: %d", _aff_score(aff if side == 0 else _pending)), 18, Color(0.8, 0.78, 0.7)))
		var br := UI.hbox(14)
		_right.add_child(br)
		br.add_child(UI.button("Giữ cũ", _keep_old, 24, 200))
		br.add_child(UI.gold_button("Nhận mới", _keep_new, 24, 220))
		return
	_right.add_child(_wrap(L.f("Tẩy luyện ngẫu nhiên lại toàn bộ %d dòng thuộc tính phụ (loại và độ tốt). Sau khi tẩy được chọn giữ dòng cũ hoặc nhận dòng mới.", aff.size()), 19, Color(0.85, 0.82, 0.75)))
	_right.add_child(UI.label("Màu dòng: xám < lục < lam < tím < vàng (càng gần tối đa càng quý).", 17, Color(0.7, 0.68, 0.62)))
	var c := Items.wash_cost(it)
	_right.add_child(_cost_row([_gold_chip(int(c.gold)), Mats.chip(h, "wash", int(c.wash), 34)]))
	var go := UI.gold_button("Tẩy Luyện", _do_wash, 30, 260)
	go.custom_minimum_size.y = 70
	go.disabled = int(h.gold) < int(c.gold) or Mats.count(h, "wash") < int(c.wash)
	_right.add_child(go)
	if Mats.count(h, "wash") < int(c.wash):
		_right.add_child(_wrap(L.f("Thiếu Tẩy Luyện Thạch: %s.", Mats.INFO.wash[3]), 17, Color(1, 0.7, 0.55)))

static func _aff_score(lines: Array) -> int:
	var s := 0.0
	for a in lines:
		s += float(a.get("q", 0.0)) * 100.0
	return int(s)

func _do_wash() -> void:
	var h := Game.hero
	var it := _item()
	var c := Items.wash_cost(it)
	if int(h.gold) < int(c.gold) or Mats.count(h, "wash") < int(c.wash):
		return
	h.gold = int(h.gold) - int(c.gold)
	Mats.spend(h, "wash", int(c.wash))
	_pending = Items.roll_aff(Array(it.get("aff", [])).size(), _rng)
	Daily.track(h, "upgrade")
	Game.save()
	Game.sfx("skill")
	_build()

func _keep_new() -> void:
	var it := _item()
	if _pending.is_empty():
		return
	it.aff = _pending
	_pending = []
	Game.save()
	Game.sfx("levelup")
	_build()
