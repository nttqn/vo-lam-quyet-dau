class_name DuelScreen
extends Screen
## Tỉ Võ: pick a rival's shadow near your score, weekly leaderboard.

var _rivals: VBoxContainer
var _board: VBoxContainer
var _status: Label
var _offline := false

func _ready() -> void:
	_init_ui("peak")
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	top_bar("Tỉ Võ", back)
	var h := Game.hero
	var d := Duel.ensure(h)
	var body := UI.hbox(16)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 24
	body.offset_right = -24
	body.offset_top = 92
	body.offset_bottom = -16
	ui.add_child(body)
	var lp := UI.panel(Color(0.07, 0.05, 0.06, 0.92))
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(lp)
	var lv := UI.vbox(10)
	lp.add_child(lv)
	var tr: Array = Duel.tier(int(d.score))
	var head := UI.hbox(14)
	lv.add_child(head)
	head.add_child(UI.label("%s  ·  %d điểm" % [tr[0], int(d.score)], 28, tr[1], UI.title))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.label("Lượt hôm nay: %d/%d" % [int(d.tickets), Duel.TICKETS], 20, UI.PAPER, UI.bold))
	var info := UI.label("Mùa %s · còn %d ngày · thắng %d, thua %d. Đối thủ là bóng của người chơi khác, do máy điều khiển." % [d.season, Duel.days_left(), int(d.wins), int(d.losses)], 16, Color(0.8, 0.78, 0.72))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_child(info)
	_status = UI.label("Đang tìm đối thủ…", 18, Color(0.85, 0.82, 0.75))
	lv.add_child(_status)
	_rivals = UI.vbox(8)
	_rivals.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(_rivals)
	var rb := UI.button("Đổi đối thủ", _load, 20)
	lv.add_child(rb)
	var rp := UI.panel(Color(0.07, 0.05, 0.06, 0.92))
	rp.custom_minimum_size.x = 400
	body.add_child(rp)
	var rv := UI.vbox(6)
	rp.add_child(rv)
	rv.add_child(UI.heading("Bảng Xếp Hạng", 30))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(sc)
	_board = UI.vbox(4)
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_board)
	var foot := UI.label("Cuối mùa thưởng Ngọc theo bậc: Tân Thủ 4 · Võ Sinh 8 · Hiệp Khách 15 · Cao Thủ 25 · Tông Sư 40", 14, Color(0.75, 0.72, 0.66))
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(foot)
	var j := Duel.claim_season_reward(h)
	if j > 0:
		Game.save()
		toast("Thưởng mùa %s: Ngọc +%d" % [d.last_season, j], Color(0.5, 1, 0.8))
	_load()

func _load() -> void:
	var h := Game.hero
	var d := Duel.ensure(h)
	for c in _rivals.get_children():
		c.queue_free()
	var docs: Array = []
	if Cloud.enabled():
		_status.text = "Đang tìm đối thủ…"
		await Cloud.put_my_doc(Duel.collection(), Duel.fields(h))
		var sc := int(d.score)
		docs = await Cloud.query(Duel.collection(), "score", 30, sc - 200, sc + 200)
		if docs.size() < 6:
			docs = await Cloud.query(Duel.collection(), "score", 30)
		if not is_inside_tree():
			return
		docs = docs.filter(func(x): return x._id != Cloud.uid)
		_load_board()
	docs.shuffle()
	docs = docs.slice(0, 4)
	_offline = docs.is_empty()
	if docs.size() < 4:
		docs.append_array(Duel.bots(h, 4 - docs.size()))
	_status.text = "Chưa kết nối được máy chủ: tạm đấu với cao thủ ẩn danh." if _offline and Cloud.enabled() else ("Cao thủ quanh điểm của bạn:" if not _offline else "Đấu với cao thủ ẩn danh.")
	for doc in docs:
		_rivals.add_child(_rival_row(doc))

func _rival_row(doc: Dictionary) -> Control:
	var d := Duel.ensure(Game.hero)
	var p := UI.panel(Color(0.1, 0.07, 0.08, 0.95))
	var row := UI.hbox(12)
	p.add_child(row)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var sc := int(doc.get("score", Duel.START))
	var tr: Array = Duel.tier(sc)
	info.add_child(UI.label(str(doc.get("name", "?")), 22, UI.GOLD, UI.bold))
	info.add_child(UI.label("%s  ·  Cấp %d  ·  Lực chiến %d  ·  %s %d" % [Sects.get_sect(str(doc.get("sect", "vo_dang"))).name, int(doc.get("level", 1)), int(doc.get("power", 0)), tr[0], sc], 16, Color(0.85, 0.82, 0.75)))
	var win := int(round(Duel.K * (1.0 - Duel.expected(int(d.score), sc))))
	info.add_child(UI.label("Thắng +%d điểm" % maxi(4, win), 15, Color(0.6, 1, 0.6)))
	var b := UI.gold_button("Khiêu chiến", func(): Flow.start_duel(doc), 20, 150)
	b.disabled = int(d.tickets) <= 0
	row.add_child(b)
	return p

func _load_board() -> void:
	for c in _board.get_children():
		c.queue_free()
	var top: Array = await Cloud.query(Duel.collection(), "score", 50)
	if not is_inside_tree():
		return
	if top.is_empty():
		_board.add_child(UI.label("Mùa này chưa ai tỉ võ.", 17, Color(0.8, 0.78, 0.72)))
		return
	for i in top.size():
		var t: Dictionary = top[i]
		var me: bool = t._id == Cloud.uid
		var row := UI.hbox(8)
		_board.add_child(row)
		var rk := UI.label("%d" % (i + 1), 18, UI.GOLD if i < 3 else UI.PAPER, UI.bold)
		rk.custom_minimum_size.x = 34
		row.add_child(rk)
		var nm := UI.label("%s · %s" % [str(t.get("name", "?")), Sects.get_sect(str(t.get("sect", "vo_dang"))).name], 17, Color(0.6, 1, 0.6) if me else UI.PAPER)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(nm)
		row.add_child(UI.label(str(int(t.get("score", 0))), 17, Duel.tier(int(t.get("score", 0)))[1], UI.bold))

func back() -> void:
	Game.goto(HubScreen.new())
