class_name MonPhaiScreen
extends Screen
## Môn Phái Tranh Hùng: this week's sect standings by Uy Danh, the hero's
## công, last week's reward and how công is earned; the board of top
## contributors opens on top.

var _right: VBoxContainer
var _rows_box: VBoxContainer
var _rows: Array = []
var _state := -2              # -2 loading, -1 offline / error, 0 loaded
var fake_rows: Array = []     # --screen=monphai: demo standings (store shots)
var fake_board: Array = []

func _ready() -> void:
	_init_ui("peak")
	var h := Game.hero
	show.add_body(Hero.look(h), Hero.sect(h).style, -1.5, -0.5)
	show.set_focus(0.9)
	shade(false, 0.64, 0.92)
	top_bar("Môn Phái Tranh Hùng", back)
	var card := UI.panel(Color(0.06, 0.05, 0.07, 0.9))
	card.anchor_left = 1.0
	card.anchor_right = 1.0
	card.anchor_bottom = 1.0
	card.offset_left = -640
	card.offset_right = -24
	card.offset_top = 88
	card.offset_bottom = -18
	ui.add_child(card)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(sc)
	_right = UI.vbox(10)
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_right)
	_build()
	_load()

func _week_no() -> int:
	return int(Duel.season().get_slice("w", 1))

func _build() -> void:
	var h := Game.hero
	var m := MonPhai.ensure(h)
	refresh_wallet()
	for c in _right.get_children():
		c.queue_free()
	var head := UI.hbox(10)
	_right.add_child(head)
	var t := UI.heading(L.f("Tuần %d", _week_no()), 36)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UI.label(L.f("Còn %d ngày", Duel.days_left()), 20, Color(0.85, 0.82, 0.75), UI.bold))
	if MonPhai.buffed(h):
		var bl := UI.label(L.f("%s đứng đầu tuần trước: tuần này +%d%% kinh nghiệm và vàng mọi trận!", [Hero.sect(h).name, int(MonPhai.BUFF * 100)]), 18, Color(0.6, 1.0, 0.65), UI.bold)
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_right.add_child(bl)
	if MonPhai.claimable(h):
		var cb := UI.gold_button("Nhận thưởng Tranh Hùng tuần trước", _claim, 21)
		cb.custom_minimum_size.y = 58
		_right.add_child(cb)
	# the hero's own part
	var mine := UI.vbox(2)
	_right.add_child(mine)
	if not MonPhai.unlocked(h):
		mine.add_child(UI.label("Đạt cấp 5 để góp công trạng cho môn phái.", 19, Color(1, 0.7, 0.5), UI.bold))
	else:
		var today := int(m.today)
		var mr := UI.hbox(16)
		mine.add_child(mr)
		mr.add_child(UI.label(L.f("Công trạng của bạn tuần này: %d", int(m.pts)), 21, UI.PAPER, UI.bold))
		mr.add_child(UI.label(L.f("Hôm nay: %d / %d", [today, MonPhai.DAY_CAP]), 18, Color(0.6, 1, 0.6) if today < MonPhai.DAY_CAP else Color(1, 0.8, 0.45)))
		if int(m.pts) < MonPhai.MIN_CLAIM:
			var need := UI.label(L.f("Góp đủ %d công trong tuần để nhận thưởng khi tuần kết thúc.", MonPhai.MIN_CLAIM), 16, Color(0.85, 0.8, 0.7))
			need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			mine.add_child(need)
		if Ban.active():
			mine.add_child(UI.label("Tài khoản bị khóa: công trạng không được tính cho môn phái.", 16, Color(1.0, 0.5, 0.45)))
	# standings
	var sp := UI.panel(Color(0.1, 0.06, 0.05, 0.9), UI.GOLD_D)
	_right.add_child(sp)
	var sv := UI.vbox(6)
	sp.add_child(sv)
	sv.add_child(UI.label("Bảng Uy Danh các phái", 20, UI.GOLD, UI.bold))
	_rows_box = UI.vbox(4)
	sv.add_child(_rows_box)
	_show_rows()
	# how it works
	var how := UI.label(L.f("Thắng trận để góp công: Hành Tẩu +%d, Ác Mộng +%d, Lôi Đài +%d, Tháp tầng mới +%d, vượt Phó Bản +%d, Tỉ Võ +%d (thua +%d), Boss Thế Giới +4–16, Kỳ Ngộ +%d. Tối đa %d công mỗi ngày.",
		[MonPhai.PTS.stage, MonPhai.PTS.nm, MonPhai.PTS.arena, MonPhai.PTS.tower_new, MonPhai.PTS.dungeon, MonPhai.PTS.duel_win, MonPhai.PTS.duel_loss, MonPhai.PTS.kyngo, MonPhai.DAY_CAP]), 15, Color(0.8, 0.77, 0.7))
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(how)
	var how2 := UI.label(L.f("Uy Danh = tổng công của phái ÷ (số đệ tử + %d), nên phái đông chưa chắc thắng. Hết tuần, mỗi người góp từ %d công nhận thưởng theo hạng của phái; phái hạng nhất được thêm +%d%% kinh nghiệm và vàng suốt tuần sau.", [int(MonPhai.DAMP), MonPhai.MIN_CLAIM, int(MonPhai.BUFF * 100)]), 15, Color(0.8, 0.77, 0.7))
	how2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(how2)
	var row := UI.hbox(10)
	_right.add_child(row)
	row.add_child(UI.button("Phần thưởng", _rewards, 19, 170))
	var bb := UI.gold_button("Công Thần tuần này", _board, 19)
	bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bb)

func _load(fresh := false) -> void:
	if not fake_rows.is_empty():
		_rows = fake_rows
		_state = 0
		_show_rows()
		return
	if not Cloud.enabled():
		_state = -1
		_show_rows()
		return
	var h := Game.hero
	if MonPhai.pts(h) >= MonPhai.MIN_DOC:
		await MonPhai.publish(h, Game.slot)   # catch up after offline fights
	var rows := await MonPhai.standings("", fresh)
	if not is_inside_tree():
		return
	_rows = rows
	_state = 0 if not rows.is_empty() else -1
	_show_rows()

func _show_rows() -> void:
	if not is_instance_valid(_rows_box):
		return
	for c in _rows_box.get_children():
		c.queue_free()
	if _state == -2:
		_rows_box.add_child(UI.label("Đang tải…", 18, Color(0.8, 0.77, 0.7)))
		return
	if _state == -1:
		var off := UI.label("Cần kết nối mạng để xem Uy Danh. Công trạng vẫn được ghi và gửi khi có mạng.", 17, Color(0.85, 0.8, 0.7))
		off.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_rows_box.add_child(off)
		return
	var own := str(Game.hero.sect)
	for i in _rows.size():
		var r: Dictionary = _rows[i]
		var s := Sects.get_sect(str(r.sect))
		var me := str(r.sect) == own
		var bg := UI.panel(Color(0.3, 0.22, 0.08, 0.92) if me else Color(0.09, 0.07, 0.07, 0.85), UI.GOLD if me else Color(0.35, 0.28, 0.2))
		var line := UI.hbox(12)
		bg.add_child(line)
		var no := UI.label("%d" % (i + 1), 26, UI.GOLD if i == 0 else UI.PAPER, UI.title)
		no.custom_minimum_size.x = 34
		line.add_child(no)
		var nv := UI.vbox(0)
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(nv)
		var nm := UI.label(("♛ " if i == 0 and int(r.sum) > 0 else "") + L.t(s.name) + (L.t("  (phái bạn)") if me else ""), 22, s.elem.lightened(0.15), UI.bold)
		nm.clip_text = true
		nv.add_child(nm)
		nv.add_child(UI.label(L.f("%d đệ tử  ·  tổng %s công", [int(r.n), UI.fmt(int(r.sum))]), 15, Color(0.78, 0.75, 0.68)))
		var sc := UI.vbox(0)
		line.add_child(sc)
		var v := UI.label(UI.fmt(int(r.score)), 26, Color(1, 0.85, 0.35), UI.title)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sc.add_child(v)
		var u := UI.label("Uy Danh", 14, Color(0.78, 0.75, 0.68))
		u.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sc.add_child(u)
		_rows_box.add_child(bg)

func _claim() -> void:
	var r := await MonPhai.claim(Game.hero)
	if not is_inside_tree():
		return
	if r.has("err"):
		toast("Cần kết nối mạng để nhận thưởng", Color(1, 0.7, 0.5))
		return
	if r.is_empty():
		return
	Game.save()
	Game.sfx("coin")
	var sname: String = Sects.get_sect(str(r.sect)).name
	toast(L.f("%s hạng %d: %s", [sname, int(r.place), MonPhai.rewards_text(r.rewards)]), Color(0.6, 1, 0.7))
	if r.buff:
		get_tree().create_timer(2.2).timeout.connect(func():
			if is_inside_tree():
				toast(L.f("Đệ nhất môn phái! +%d%% kinh nghiệm và vàng cả tuần này", int(MonPhai.BUFF * 100)), UI.GOLD))
	_build()

# ------------------------------------------------------------- modals
func _modal(title: String) -> VBoxContainer:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_to_group("modal")
	ui.add_child(dim)
	var p := UI.panel()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 140
	p.offset_right = -140
	p.offset_top = 40
	p.offset_bottom = -30
	dim.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	var top := UI.hbox(12)
	v.add_child(top)
	var hd := UI.heading(title, 34)
	hd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hd)
	top.add_child(UI.button("Đóng", func(): dim.queue_free(), 22, 120))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var list := UI.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	return list

func _rewards() -> void:
	var list := _modal("Thưởng Tranh Hùng theo hạng phái")
	for i in MonPhai.PLACE.size():
		var line := UI.hbox(12)
		var no := UI.label(L.f("Hạng %d", i + 1), 22, UI.GOLD if i == 0 else UI.PAPER, UI.bold)
		no.custom_minimum_size.x = 110
		line.add_child(no)
		var txt := MonPhai.rewards_text(MonPhai.PLACE[i])
		if i == 0:
			txt += L.f(" + %d%% kinh nghiệm, vàng cả tuần sau", int(MonPhai.BUFF * 100))
		var l := UI.label(txt, 20, UI.PAPER)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(l)
		list.add_child(line)
	var note := UI.label(L.f("Nhận ở màn này khi tuần mới bắt đầu, nếu bạn góp từ %d công. Danh hiệu: «Đệ Nhất Môn Phái» khi phái đứng đầu, «Công Thần Môn Phái» khi góp 500 công trong một tuần.", MonPhai.MIN_CLAIM), 17, Color(0.8, 0.77, 0.7))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(note)

func _board() -> void:
	var list := _modal("Công Thần tuần này")
	var wait := UI.label("Đang tải…" if Cloud.enabled() or not fake_board.is_empty() else "Cần kết nối mạng để xem bảng.", 18, Color(0.8, 0.77, 0.7))
	list.add_child(wait)
	var rows: Array = fake_board if not fake_board.is_empty() else await MonPhai.board()
	if not is_instance_valid(list):
		return
	wait.queue_free()
	if rows.is_empty() and (Cloud.enabled() or not fake_board.is_empty()):
		list.add_child(UI.label("Chưa ai góp công tuần này. Hãy là người đầu tiên!", 18, Color(0.8, 0.77, 0.7)))
	var mine := "%s_%d" % [Cloud.uid, Game.slot]
	for i in rows.size():
		var r: Dictionary = rows[i]
		var me := str(r.get("_id", "")) == mine
		var s := Sects.get_sect(str(r.get("sect", "vo_dang")))
		var bg := UI.panel(Color(0.3, 0.22, 0.08, 0.9) if me else Color(0.1, 0.08, 0.07, 0.8), UI.GOLD if me else UI.GOLD_D)
		var line := UI.hbox(10)
		bg.add_child(line)
		var no := UI.label("%d" % (i + 1), 22, UI.GOLD if i < 3 else UI.PAPER, UI.title)
		no.custom_minimum_size.x = 44
		line.add_child(no)
		var who := str(r.get("name", ""))
		var nm := UI.label(L.f("%s  ·  Cấp %d", [Chat.safe_name(who) if who != "" else L.t("Ẩn danh"), int(r.get("level", 1))]), 18, UI.PAPER)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		line.add_child(nm)
		line.add_child(UI.label(s.name, 18, s.elem.lightened(0.15), UI.bold))
		var pv := UI.label(L.f("%d công", int(r.get("pts", 0))), 20, Color(1, 0.85, 0.35), UI.bold)
		pv.custom_minimum_size.x = 110
		pv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(pv)
		list.add_child(bg)

func back() -> void:
	Game.goto(HubScreen.new())
