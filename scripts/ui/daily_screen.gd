class_name DailyScreen
extends Screen
## Daily missions + 7-day check-in.

var _left: VBoxContainer
var _right: VBoxContainer

func _ready() -> void:
	_init_ui("river")
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	top_bar("Nhiệm Vụ", back)
	var body := UI.hbox(16)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 24
	body.offset_right = -24
	body.offset_top = 92
	body.offset_bottom = -16
	ui.add_child(body)
	var lp := UI.panel(Color(0.07, 0.05, 0.06, 0.92))
	lp.custom_minimum_size.x = 470
	body.add_child(lp)
	_left = UI.vbox(10)
	lp.add_child(_left)
	var rp := UI.panel(Color(0.07, 0.05, 0.06, 0.92))
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rp)
	_right = UI.vbox(10)
	rp.add_child(_right)
	_build()

static func _rw_text(rw: Dictionary) -> String:
	var p := []
	if int(rw.get("gold", 0)) > 0: p.append("Vàng +%s" % UI.fmt(int(rw.gold)))
	if int(rw.get("exp", 0)) > 0: p.append("KN +%d" % int(rw.exp))
	if int(rw.get("jade", 0)) > 0: p.append("Ngọc +%d" % int(rw.jade))
	if int(rw.get("item", -1)) >= 0: p.append("Trang bị %s" % Items.RARITY[int(rw.item)])
	return "  ·  ".join(p)

func _build() -> void:
	var h := Game.hero
	Daily.ensure(h)
	for c in _left.get_children():
		c.queue_free()
	for c in _right.get_children():
		c.queue_free()
	# --- check-in
	_left.add_child(UI.heading("Điểm Danh", 34))
	_left.add_child(UI.label("Mỗi ngày vào game nhận một phần quà, quà ngày 7 lớn nhất.", 17, Color(0.85, 0.82, 0.75)))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_left.add_child(grid)
	var next := Daily.checkin_day(h)
	var ready := Daily.checkin_ready(h)
	var n_all := int(Dictionary(h.get("checkin", {})).get("n", 0))
	var cnt := n_all % 7
	if n_all > 0 and cnt == 0 and not ready:
		cnt = 7   # day 7 claimed today: show the whole week done
	for d in Daily.CHECKIN.size():
		var rw: Dictionary = Daily.CHECKIN[d]
		var got := d < cnt
		var is_next := d == next and ready
		var cell := UI.panel(Color(0.12, 0.09, 0.08, 0.95) if not got else Color(0.08, 0.12, 0.08, 0.95), UI.GOLD if is_next else UI.GOLD_D)
		cell.custom_minimum_size = Vector2(102, 104)
		var cv := UI.vbox(2)
		cell.add_child(cv)
		cv.add_child(UI.label("Ngày %d" % (d + 1), 17, UI.GOLD if is_next else UI.PAPER, UI.bold))
		var rl := UI.label(_rw_text(rw).replace("  ·  ", "\n"), 15, Color(0.6, 1, 0.6) if got else Color(0.9, 0.87, 0.8))
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(rl)
		if got:
			cv.add_child(UI.label("✓ Đã nhận", 14, Color(0.6, 1, 0.6)))
		grid.add_child(cell)
	var cb := UI.gold_button("Nhận quà hôm nay" if ready else "Đã điểm danh hôm nay", _checkin, 22)
	cb.disabled = not ready
	_left.add_child(cb)
	# --- missions
	_right.add_child(UI.heading("Nhiệm Vụ Hôm Nay", 34))
	var d2: Dictionary = h.daily
	for id in d2.ids:
		var row := UI.hbox(12)
		_right.add_child(row)
		var info := UI.vbox(4)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var claimed: bool = id in d2.claimed
		var ok := Daily.done(h, id)
		info.add_child(UI.label(Daily.text(id), 20, UI.PAPER if not claimed else Color(0.6, 0.58, 0.55), UI.bold))
		var bar := ProgressBar.new()
		bar.max_value = Daily.target(id)
		bar.value = Daily.progress(h, id)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 12)
		bar.add_theme_stylebox_override("background", UI.box(Color(0.15, 0.12, 0.1), Color(0, 0, 0, 0), 0, 4, 0))
		bar.add_theme_stylebox_override("fill", UI.box(UI.GOLD if not ok else Color(0.45, 0.85, 0.4), Color(0, 0, 0, 0), 0, 4, 0))
		info.add_child(bar)
		info.add_child(UI.label("%d/%d   ·   %s" % [Daily.progress(h, id), Daily.target(id), _rw_text(Daily.reward(h, id))], 16, Color(0.85, 0.82, 0.75)))
		var b: Button
		if claimed:
			b = UI.button("Đã nhận", func(): pass, 18, 120)
			b.disabled = true
		else:
			b = UI.gold_button("Nhận", func(): _claim(id), 20, 120)
			b.disabled = not ok
		row.add_child(b)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right.add_child(sp)
	var chest := UI.gold_button("Hoàn thành cả %d nhiệm vụ: Rương +%d Ngọc" % [d2.ids.size(), Daily.CHEST_JADE] if not d2.chest else "Đã mở rương hôm nay", _chest, 20)
	chest.disabled = not Daily.chest_ready(h)
	_right.add_child(chest)
	_right.add_child(UI.label("Nhiệm vụ mới mỗi ngày lúc 0 giờ.", 15, Color(0.7, 0.68, 0.62)))

func _checkin() -> void:
	var rw := Daily.claim_checkin(Game.hero)
	if rw.is_empty():
		return
	Game.sfx("coin")
	var t := _rw_text(rw)
	if rw.has("drop"):
		t = t.replace("Trang bị %s" % Items.RARITY[int(rw.item)], Items.item_name(rw.drop, Hero.sect(Game.hero).style) + " (%s)" % Items.RARITY[int(rw.item)])
	toast("Điểm danh: " + t)
	Game.save()
	refresh_wallet()
	_build()

func _claim(id: String) -> void:
	var rw := Daily.claim(Game.hero, id)
	if rw.is_empty():
		return
	Game.sfx("coin")
	toast(_rw_text(rw))
	Game.save()
	refresh_wallet()
	_build()

func _chest() -> void:
	if Daily.claim_chest(Game.hero):
		Game.sfx("levelup")
		toast("Rương nhiệm vụ: Ngọc +%d" % Daily.CHEST_JADE, Color(0.5, 1, 0.8))
		Game.save()
		refresh_wallet()
		_build()

func back() -> void:
	Game.goto(HubScreen.new())
