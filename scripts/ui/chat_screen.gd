class_name ChatScreen
extends Screen
## Kênh Thế Giới: the input row sits at the top (the phone keyboard covers the
## lower half of a landscape screen), messages below, newest at the bottom.
## Polls for new messages every Chat.POLL seconds while open.

var fake_msgs: Array = []   # test hook (--screen=chat): show these, never touch the server

var _msgs: Array = []       # everything loaded, oldest first
var _list: VBoxContainer
var _sc: ScrollContainer
var _edit: LineEdit
var _send: Button
var _status: Label
var _unblock: Button
var _timer: Timer
var _polling := false
var _st := {}

func _ready() -> void:
	_init_ui("")
	painted_bg("peak")
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	top_bar("Kênh Thế Giới", back)
	var card := UI.panel(Color(0.07, 0.05, 0.06, 0.92))
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 120
	card.offset_right = -120
	card.offset_top = 92
	card.offset_bottom = -16
	ui.add_child(card)
	var v := UI.vbox(8)
	card.add_child(v)
	# input row
	var row := UI.hbox(10)
	v.add_child(row)
	_edit = LineEdit.new()
	_edit.max_length = Chat.MAX_LEN
	_edit.placeholder_text = "Nói gì đó với cả giang hồ…"
	_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit.custom_minimum_size.y = 52
	_edit.add_theme_font_size_override("font_size", 20)
	_edit.add_theme_stylebox_override("normal", UI.box(Color(0.14, 0.11, 0.1), UI.GOLD_D, 2, 10, 6))
	_edit.add_theme_stylebox_override("focus", UI.box(Color(0.16, 0.12, 0.1), UI.GOLD, 2, 10, 6))
	_edit.text_submitted.connect(func(_t): _do_send())
	row.add_child(_edit)
	_send = UI.gold_button("Gửi", _do_send, 22, 110)
	_send.custom_minimum_size.y = 52
	row.add_child(_send)
	var srow := UI.hbox(10)
	v.add_child(srow)
	_status = UI.label("", 16, Color(0.8, 0.78, 0.72))
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	srow.add_child(_status)
	_unblock = UI.button("", func():
		Chat.unblock_all()
		_refresh_unblock()
		_render(), 16)
	_unblock.custom_minimum_size.y = 34
	srow.add_child(_unblock)
	_refresh_unblock()
	# message list
	_sc = ScrollContainer.new()
	_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_sc)
	_list = UI.vbox(6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.mouse_filter = Control.MOUSE_FILTER_PASS
	_sc.add_child(_list)
	for k in ["me", "row"]:
		var s := UI.box(Color(0.13, 0.11, 0.06, 0.95) if k == "me" else Color(0.09, 0.07, 0.08, 0.9),
			UI.GOLD if k == "me" else Color(0.3, 0.24, 0.16), 1, 10, 8)
		s.content_margin_top = 6
		s.content_margin_bottom = 6
		s.shadow_size = 0
		_st[k] = s
	_timer = Timer.new()
	_timer.wait_time = Chat.POLL
	_timer.timeout.connect(_poll)
	add_child(_timer)
	_update_send()
	if not Chat.rules_accepted() and fake_msgs.is_empty():
		ui.add_child(_rules_panel())
	else:
		_start()

func _start() -> void:
	if not fake_msgs.is_empty():
		_msgs = fake_msgs
		_status.text = "Thử nghiệm"
		_render()
		return
	if not Cloud.enabled():
		_status.text = "Cần kết nối mạng để dùng Kênh Thế Giới."
		return
	_status.text = "Đang tải…"
	var rows = await Chat.load_latest()
	if not is_inside_tree():
		return
	if rows == null:
		_status.text = "Không tải được tin nhắn. Kiểm tra kết nối mạng."
	else:
		_msgs = rows
		_status.text = "" if not rows.is_empty() else "Chưa có ai lên tiếng. Hãy là người đầu tiên!"
		_render()
	_timer.start()

func _poll() -> void:
	if _polling or not is_inside_tree():
		return
	_polling = true
	var rows
	if _msgs.is_empty():
		rows = await Chat.load_latest()
	else:
		rows = await Chat.load_after(str(_msgs[-1].get("at", "")))
	_polling = false
	if not is_inside_tree() or rows == null or rows.is_empty():
		return
	var known := {}
	for m in _msgs:
		known[str(m._id)] = true
	var added := false
	for m in rows:
		if not known.has(str(m._id)):
			_msgs.append(m)
			added = true
	if added:
		if _msgs.size() > Chat.SHOWN * 2:
			_msgs = _msgs.slice(_msgs.size() - Chat.SHOWN)
		if _status.text.begins_with("Chưa có ai"):
			_status.text = ""
		_render()

# ------------------------------------------------------------------ list
func _render() -> void:
	var at_bottom := _sc.scroll_vertical >= int(_sc.get_v_scroll_bar().max_value - _sc.size.y - 40)
	for c in _list.get_children():
		c.queue_free()
	for m in Chat.visible(_msgs):
		_list.add_child(_msg_row(m))
	if at_bottom or _list.get_child_count() <= 8:
		_scroll_end.call_deferred()

func _scroll_end() -> void:
	await get_tree().process_frame
	if is_inside_tree():
		_sc.scroll_vertical = int(_sc.get_v_scroll_bar().max_value)

func _msg_row(m: Dictionary) -> Control:
	var me := str(m.get("uid", "")) == Cloud.uid and Cloud.uid != ""
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _st["me" if me else "row"])
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	var v := UI.vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var head := UI.hbox(8)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(head)
	var nm := UI.label(str(m.get("name", "?")), 18, Color(0.6, 1, 0.6) if me else UI.GOLD, UI.bold)
	head.add_child(nm)
	var sect := Sects.get_sect(str(m.get("sect", "vo_dang")))
	head.add_child(UI.label("%s · Cấp %d" % [sect.get("name", ""), int(m.get("level", 1))], 14, Color(0.72, 0.7, 0.64)))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UI.label(Chat.clock(str(m.get("at", ""))), 14, Color(0.6, 0.58, 0.54)))
	var t := UI.label(str(m.get("text", "")), 19, UI.PAPER)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	for c in [nm, t]:
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in head.get_children():
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	# transparent button over the content: tap = actions; PASS keeps swipes scrolling
	var b := Button.new()
	b.flat = true
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	var empty := StyleBoxEmpty.new()
	for k in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, empty)
	b.pressed.connect(func(): ui.add_child(_actions(m, me)))
	p.add_child(b)
	return p

# ------------------------------------------------------------------ send
func _do_send() -> void:
	if _send.disabled:
		return
	var txt := _edit.text
	if Chat.clean(txt) == "":
		return
	if not fake_msgs.is_empty():
		_msgs.append({"_id": "local%d" % _msgs.size(), "uid": Cloud.uid, "name": Game.hero.name, "sect": Game.hero.sect,
			"level": Game.hero.level, "text": Chat.clean(txt), "at": Time.get_datetime_string_from_system(true) + "Z"})
		_edit.text = ""
		_render()
		_scroll_end.call_deferred()
		return
	_send.disabled = true
	_status.text = "Đang gửi…"
	var err: String = await Chat.send(txt)
	if not is_inside_tree():
		return
	_status.text = err
	if err == "":
		Game.sfx("click")
		_edit.text = ""
		_edit.release_focus()
		DisplayServer.virtual_keyboard_hide()
		await _poll()
		_scroll_end.call_deferred()
	_update_send()

## The send button counts down the cooldown; below MIN_LEVEL it explains why.
func _update_send() -> void:
	if not is_inside_tree():
		return
	if Game.hero.is_empty() or int(Game.hero.level) < Chat.MIN_LEVEL:
		_send.disabled = true
		_edit.editable = false
		_edit.placeholder_text = "Đạt cấp %d để nói chuyện (vẫn xem được tin nhắn)" % Chat.MIN_LEVEL
		return
	var w := Chat.wait_left()
	_send.disabled = w > 0.0
	_send.text = "%ds" % ceili(w) if w > 0.0 else "Gửi"
	if w > 0.0:
		get_tree().create_timer(minf(1.0, w)).timeout.connect(_update_send)

func _refresh_unblock() -> void:
	var n := Chat.blocked().size()
	_unblock.visible = n > 0
	_unblock.text = "Bỏ chặn (%d)" % n

# ---------------------------------------------------------------- modals
func _modal(title: String, width := 560.0) -> Array:
	var root := Control.new()
	root.add_to_group("modal")   # Android back closes it
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(c)
	var p := UI.panel()
	c.add_child(p)
	var v := UI.vbox(12)
	v.custom_minimum_size.x = width
	p.add_child(v)
	v.add_child(UI.heading(title, 36))
	return [root, v]

func _rules_panel() -> Control:
	var mv := _modal("Quy tắc Kênh Thế Giới", 720)
	var root: Control = mv[0]
	var v: VBoxContainer = mv[1]
	var l := UI.label(Chat.RULES_TEXT, 19)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("Để sau", root.queue_free, 22, 180))
	row.add_child(UI.gold_button("Tôi đồng ý", func():
		Chat.accept_rules()
		root.queue_free()
		_start(), 22, 220))
	# back while the rules are open leaves the chat entirely
	root.tree_exiting.connect(func():
		if not Chat.rules_accepted() and is_inside_tree():
			back.call_deferred())
	return root

func _actions(m: Dictionary, me: bool) -> Control:
	var mv := _modal(str(m.get("name", "?")))
	var root: Control = mv[0]
	var v: VBoxContainer = mv[1]
	var t := UI.label("“%s”" % str(m.get("text", "")), 18, Color(0.85, 0.82, 0.75))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	if me:
		v.add_child(UI.button("Xóa tin nhắn", func():
			root.queue_free()
			_msgs.erase(m)
			_render()
			if fake_msgs.is_empty():
				await Chat.delete_msg(str(m._id)), 22))
	else:
		v.add_child(UI.button("Báo cáo vi phạm", func():
			root.queue_free()
			_status.text = "Đã gửi báo cáo. Cảm ơn bạn!"
			_render.call_deferred()
			Chat.report(m), 22))
		v.add_child(UI.button("Chặn người này", func():
			root.queue_free()
			Chat.block(str(m.get("uid", "")))
			_refresh_unblock()
			_render(), 22))
	v.add_child(UI.gold_button("Đóng", root.queue_free, 22))
	return root

func back() -> void:
	Game.goto(HubScreen.new())
