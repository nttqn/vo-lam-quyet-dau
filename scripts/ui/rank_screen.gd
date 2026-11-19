class_name RankScreen
extends Screen
## Bảng xếp hạng: top 50 of each board, "Xem thêm 50" pages further down,
## "Vị trí của tôi" jumps to the 10 rows above and below the player's place.
## Kept light for long lists on phones: painted backdrop instead of the live 3D
## arena, one shared StyleBox per row kind (no shadows), and rows that pass
## touches up so the list can be swiped anywhere.

const PAGE := 50
const MAX_ROWS := 500    # "Xem thêm" stops here
const SPAN := 10         # rows above / below the player in "Vị trí của tôi"

var _board := "power"
var _tabs: HBoxContainer
var _list: VBoxContainer
var _mine: Label
var _me_btn: Button
var _sc: ScrollContainer
var fake_rows: Array = []   # test hook (--screen=rank): show these instead of querying
var _st := {}               # shared row styleboxes

var _req := 0               # bumped on every board load; stale answers are dropped
var _rows: Array = []
var _start := 1             # place of the first row shown
var _around := false        # showing the rows around the player
var _next := {}             # last row of a full page: "Xem thêm" continues after it
var _place := -1            # the player's place on this board (-1 unknown / hidden)
var _busy := false
var _footer: Control

func _ready() -> void:
	_init_ui("")
	painted_bg("peak")
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
	var mh := UI.hbox(12)
	v.add_child(mh)
	_mine = UI.label("", 19, Color(0.6, 1, 0.6), UI.bold)
	_mine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mine.clip_text = true
	_mine.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	mh.add_child(_mine)
	_me_btn = UI.button("Vị trí của tôi", _show_me, 17)
	_me_btn.custom_minimum_size = Vector2(0, 40)
	_me_btn.visible = false
	mh.add_child(_me_btn)
	var hide_btn := CheckButton.new()
	hide_btn.text = "Ẩn tôi khỏi bảng"
	hide_btn.button_pressed = Ranks.hidden()
	hide_btn.add_theme_font_size_override("font_size", 18)
	hide_btn.toggled.connect(func(on: bool):
		hide_btn.disabled = true
		_mine.text = "Đang cập nhật…"
		await Ranks.set_hidden(on)
		if is_inside_tree():
			hide_btn.disabled = false
			_show(_board))
	mh.add_child(hide_btn)
	_sc = ScrollContainer.new()
	_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_sc)
	_list = UI.vbox(4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.mouse_filter = Control.MOUSE_FILTER_PASS
	_sc.add_child(_list)
	for k in ["me", "top", "row"]:
		var s := UI.box({"me": Color(0.12, 0.1, 0.06, 0.95), "top": Color(0.09, 0.07, 0.08, 0.9), "row": Color(0.09, 0.07, 0.08, 0.9)}[k],
			UI.GOLD if k != "row" else UI.GOLD_D, 2, 12, 12)
		s.shadow_size = 0
		_st[k] = s
	# make sure the current hero is on the board before reading it
	if fake_rows.is_empty() and Game.slot >= 0 and not Game.hero.is_empty():
		Ranks._last.erase(Game.slot)
		Ranks.publish(Game.hero, Game.slot)
	_show(_board)

# ------------------------------------------------------------------ loading
## Top page of `board`, with the player's own place on the line above.
func _show(board: String) -> void:
	_board = board
	_req += 1
	var req := _req
	for c in _tabs.get_children():
		c.queue_free()
	for b in Ranks.BOARDS:
		var bb: String = b[0]
		var t := UI.gold_button(b[1], func(): _show(bb), 19) if bb == board else UI.button(b[1], func(): _show(bb), 19)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tabs.add_child(t)
	_rows = []
	_start = 1
	_around = false
	_next = {}
	_place = -1
	_busy = false
	_me_btn.visible = false
	_clear_list()
	_sc.scroll_vertical = 0
	if fake_rows.is_empty() and not Cloud.enabled():
		_mine.text = "Cần kết nối mạng để xem bảng xếp hạng."
		return
	_mine.text = "Đang tải…"
	var rows: Array = await _page(board, {})
	if not is_inside_tree() or req != _req:
		return
	var h := Game.hero
	if not h.is_empty():
		var my_v := Ranks.value(h, board)
		var above := await _count_above(board, my_v)
		if not is_inside_tree() or req != _req:
			return
		_place = -1 if above < 0 or Ranks.hidden() else above + 1
		_mine.text = "%s: %s%d%s" % [str(h.name), UNIT[board], my_v, ("  ·  hạng %d" % (above + 1)) if above >= 0 else ""]
		if Ranks.hidden():
			_mine.text += "  ·  đang ẩn"
			_mine.add_theme_color_override("font_color", Color(0.8, 0.78, 0.72))
		else:
			_mine.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	else:
		_mine.text = "Thử nghiệm" if not fake_rows.is_empty() else ""
	if rows.is_empty():
		_list.add_child(UI.label("Chưa có ai trên bảng này." if Cloud.last_error == "" or not fake_rows.is_empty() else "Không tải được bảng xếp hạng.", 18, Color(0.8, 0.78, 0.72)))
		return
	# the player's row is already in the top page: no need to jump
	_me_btn.visible = _place > rows.size()
	_add_rows(rows)

## "Xem thêm 50": the next page under the rows shown.
func _load_more() -> void:
	if _busy or _next.is_empty():
		return
	var req := _req
	_busy = true
	_set_footer()
	var rows: Array = await _page(_board, _next)
	if not is_inside_tree() or req != _req:
		return
	_busy = false
	if rows.is_empty() and Cloud.last_error != "" and fake_rows.is_empty():
		_set_footer()
		_footer.add_child(UI.label("Không tải thêm được, thử lại sau.", 16, Color(0.9, 0.6, 0.5)))
		return
	_add_rows(rows)

## "Vị trí của tôi": up to SPAN rows above the player's place, then theirs
## and SPAN below, scrolled so their row sits mid-list.
func _show_me() -> void:
	if _busy or _place < 1:
		return
	var req := _req
	_busy = true
	_me_btn.disabled = true
	var v := Ranks.value(Game.hero, _board)
	var parts: Array = await _around_rows(_board, v)
	if not is_inside_tree() or req != _req:
		return
	_busy = false
	_me_btn.disabled = false
	var above: Array = parts[0]
	var rest: Array = parts[1]
	if above.is_empty() and rest.is_empty():
		return
	_clear_list()
	_rows = []
	_start = maxi(1, _place - above.size())
	_around = true
	_next = {}
	_me_btn.visible = false
	_add_rows(above + rest)
	var me_row := _mine_row()
	if me_row == null:
		_mine.text += "  ·  chưa lên bảng, mở lại sau ít phút"
		me_row = _list.get_child(mini(above.size(), _list.get_child_count() - 1)) as Control
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(me_row) and is_inside_tree():
		_sc.scroll_vertical = int(me_row.position.y - _sc.size.y * 0.4)

## One page of the board from the top, or continuing after row `after`.
func _page(board: String, after: Dictionary) -> Array:
	if not fake_rows.is_empty():
		var all := _fake_sorted(board)
		var from := 0 if after.is_empty() else all.find(after) + 1
		return all.slice(from, from + PAGE)
	return await Cloud.query(Ranks.COLLECTION, board, PAGE, null, null, false, after)

## [rows above value v (nearest last), rows at or below v].
func _around_rows(board: String, v: int) -> Array:
	if not fake_rows.is_empty():
		var all := _fake_sorted(board)
		var up := all.filter(func(r): return int(r.get(board, 0)) > v)
		var down := all.filter(func(r): return int(r.get(board, 0)) <= v)
		return [up.slice(maxi(0, up.size() - SPAN)), down.slice(0, SPAN + 1)]
	var hi: Array = await Cloud.query(Ranks.COLLECTION, board, SPAN, v + 1, null, true)
	hi.reverse()
	var lo: Array = await Cloud.query(Ranks.COLLECTION, board, SPAN + 1, null, v)
	return [hi, lo]

func _count_above(board: String, v: int) -> int:
	if not fake_rows.is_empty():
		return _fake_sorted(board).filter(func(r): return int(r.get(board, 0)) > v).size()
	return await Cloud.count_above(Ranks.COLLECTION, board, v)

func _fake_sorted(board: String) -> Array:
	var all := fake_rows.duplicate()
	all.sort_custom(func(a, b): return int(a.get(board, 0)) > int(b.get(board, 0)))
	return all

# --------------------------------------------------------------------- rows
const UNIT := {"power": "", "level": "", "tower": "tầng ", "stars": "★ "}
const MEDAL := [Color(1, 0.8, 0.3), Color(0.85, 0.85, 0.9), Color(0.9, 0.6, 0.35)]

func _clear_list() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_footer = null

func _mine_id() -> String:
	return "%s_%d" % [Cloud.uid, Game.slot]

func _mine_row() -> Control:
	for c in _list.get_children():
		if c.has_meta("mine"):
			return c as Control
	return null

## Append rows under those shown, then the footer button.
func _add_rows(rows: Array) -> void:
	if _footer:
		_list.remove_child(_footer)
		_footer.queue_free()
		_footer = null
	var mine_id := _mine_id()
	for r in rows:
		var place := _start + _rows.size()
		_rows.append(r)
		_list.add_child(_row(r, place, str(r.get("_id", "")) == mine_id))
	if not _around:
		_next = rows.back() if rows.size() == PAGE and _rows.size() < MAX_ROWS else {}
	_set_footer()

## Footer under the list: "Xem thêm 50", "Về top", or a loading line.
func _set_footer() -> void:
	if _footer:
		_list.remove_child(_footer)
		_footer.queue_free()
	_footer = CenterContainer.new()
	_footer.mouse_filter = Control.MOUSE_FILTER_PASS
	_footer.custom_minimum_size.y = 56
	_list.add_child(_footer)
	if _busy:
		_footer.add_child(UI.label("Đang tải…", 17, Color(0.8, 0.78, 0.72)))
	elif _around:
		var b := UI.button("Về top", func(): _show(_board), 18)
		b.custom_minimum_size = Vector2(200, 44)
		_footer.add_child(b)
	elif not _next.is_empty():
		var b := UI.gold_button("Xem thêm %d" % PAGE, _load_more, 18)
		b.custom_minimum_size = Vector2(240, 44)
		_footer.add_child(b)

func _row(r: Dictionary, place: int, me: bool) -> Control:
	var top := place <= 3
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _st["me" if me else ("top" if top else "row")])
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	if me:
		p.set_meta("mine", true)
	var row := UI.hbox(12)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(row)
	var rk := UI.label("%d" % place, 24 if place < 1000 else 19, MEDAL[place - 1] if top else UI.PAPER, UI.title)
	rk.custom_minimum_size.x = 64
	rk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(rk)
	var info := UI.vbox(0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(info)
	var nm := UI.label(str(r.get("name", "?")), 20, Color(0.6, 1, 0.6) if me else UI.GOLD, UI.bold)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(nm)
	info.add_child(UI.label("%s  ·  Cấp %d" % [Sects.get_sect(str(r.get("sect", "vo_dang"))).name, int(r.get("level", 1))], 15, Color(0.82, 0.8, 0.74)))
	row.add_child(UI.label("%s%d" % [UNIT[_board], int(r.get(_board, 0))], 22, UI.PAPER, UI.bold))
	return p

func back() -> void:
	Game.goto(HubScreen.new())
