class_name RankScreen
extends Screen
## Bảng xếp hạng: top 50 of each board, the player's own rank underneath.

var _board := "power"
var _tabs: HBoxContainer
var _list: VBoxContainer
var _mine: Label

func _ready() -> void:
	_init_ui("peak")
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	top_bar("Bảng Xếp Hạng", back)
	var card := UI.panel(Color(0.07, 0.05, 0.06, 0.92))
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 120
	card.offset_right = -120
	card.offset_top = 92
	card.offset_bottom = -16
	ui.add_child(card)
	var v := UI.vbox(8)
	card.add_child(v)
	_tabs = UI.hbox(8)
	v.add_child(_tabs)
	_mine = UI.label("", 19, Color(0.6, 1, 0.6), UI.bold)
	v.add_child(_mine)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	_list = UI.vbox(4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_list)
	# make sure the current hero is on the board before reading it
	if Game.slot >= 0 and not Game.hero.is_empty():
		Ranks._last.erase(Game.slot)
		Ranks.publish(Game.hero, Game.slot)
	_show(_board)

func _show(board: String) -> void:
	_board = board
	for c in _tabs.get_children():
		c.queue_free()
	for b in Ranks.BOARDS:
		var bb: String = b[0]
		var t := UI.gold_button(b[1], func(): _show(bb), 19) if bb == board else UI.button(b[1], func(): _show(bb), 19)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tabs.add_child(t)
	for c in _list.get_children():
		c.queue_free()
	if not Cloud.enabled():
		_mine.text = "Cần kết nối mạng để xem bảng xếp hạng."
		return
	_mine.text = "Đang tải…"
	var rows: Array = await Cloud.query(Ranks.COLLECTION, board, 50)
	if not is_inside_tree() or board != _board:
		return
	var h := Game.hero
	var mine_id := "%s_%d" % [Cloud.uid, Game.slot]
	var unit := {"power": "", "level": "", "tower": "tầng ", "stars": "★ "}
	if not h.is_empty():
		var my_v := Ranks.value(h, board)
		var above: int = await Cloud.count_above(Ranks.COLLECTION, board, my_v)
		if not is_inside_tree() or board != _board:
			return
		_mine.text = "%s: %s%d%s" % [str(h.name), unit[board], my_v, ("  ·  hạng %d" % (above + 1)) if above >= 0 else ""]
	else:
		_mine.text = ""
	if rows.is_empty():
		_list.add_child(UI.label("Chưa có ai trên bảng này." if Cloud.last_error == "" else "Không tải được bảng xếp hạng.", 18, Color(0.8, 0.78, 0.72)))
		return
	for i in rows.size():
		var r: Dictionary = rows[i]
		var me: bool = r._id == mine_id
		var p := UI.panel(Color(0.12, 0.1, 0.06, 0.95) if me else Color(0.09, 0.07, 0.08, 0.9), UI.GOLD if (me or i < 3) else UI.GOLD_D)
		var row := UI.hbox(12)
		p.add_child(row)
		var rk := UI.label("%d" % (i + 1), 24, [Color(1, 0.8, 0.3), Color(0.85, 0.85, 0.9), Color(0.9, 0.6, 0.35)][i] if i < 3 else UI.PAPER, UI.title)
		rk.custom_minimum_size.x = 48
		rk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(rk)
		var info := UI.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var nm := UI.label(str(r.get("name", "?")), 20, Color(0.6, 1, 0.6) if me else UI.GOLD, UI.bold)
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info.add_child(nm)
		info.add_child(UI.label("%s  ·  Cấp %d" % [Sects.get_sect(str(r.get("sect", "vo_dang"))).name, int(r.get("level", 1))], 15, Color(0.82, 0.8, 0.74)))
		row.add_child(UI.label("%s%d" % [unit[board], int(r.get(board, 0))], 22, UI.PAPER, UI.bold))
		_list.add_child(p)

func back() -> void:
	Game.goto(HubScreen.new())
