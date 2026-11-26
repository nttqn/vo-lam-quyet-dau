class_name ReplayScreen
extends Screen
## Trận Đã Lưu: the fights the player kept (Replay.save), newest first, each
## with Xem (watch again) and Xóa.

var _list: VBoxContainer
var _count: Label

func _ready() -> void:
	_init_ui()
	painted_bg("temple")
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	ui.move_child(dim, 1)
	var bar := top_bar("Trận Đã Lưu", back)
	_count = UI.label("", 20, Color(0.85, 0.82, 0.75), UI.bold)
	bar.add_child(_count)
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.offset_left = 60
	sc.offset_right = -60
	sc.offset_top = 92
	sc.offset_bottom = -20
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(sc)
	_list = UI.vbox(8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_list)
	_build()

func _build() -> void:
	for c in _list.get_children():
		c.queue_free()
	var rows := Replay.list()
	_count.text = L.f("%d / %d trận", [rows.size(), Replay.KEEP])
	if rows.is_empty():
		var e := UI.label("Chưa lưu trận nào. Sau mỗi trận, bấm «Lưu trận» ở màn kết quả để giữ lại những trận đáng nhớ.", 22, Color(0.85, 0.8, 0.7))
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(e)
		return
	for m in rows:
		_list.add_child(_row(m))

func _row(m: Dictionary) -> Control:
	var won := bool(m.get("won", false))
	var p := UI.panel(Color(0.08, 0.06, 0.06, 0.9), UI.GOLD_D if won else Color(0.35, 0.3, 0.3))
	var row := UI.hbox(14)
	p.add_child(row)
	var res := UI.label("Thắng" if won else "Thua", 24, UI.GOLD if won else Color(0.7, 0.7, 0.75), UI.title)
	res.custom_minimum_size.x = 90
	row.add_child(res)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var ps := Sects.get_sect(str(m.get("ps", "vo_dang")))
	var es := Sects.get_sect(str(m.get("es", "vo_dang")))
	var vs := UI.label(L.f("%s (%s, cấp %d)  vs  %s (%s, cấp %d)", [str(m.get("p", "?")), ps.name, int(m.get("pl", 1)), str(m.get("e", "?")), es.name, int(m.get("el", 1))]), 20, UI.PAPER, UI.bold)
	vs.clip_text = true
	info.add_child(vs)
	var when := Time.get_datetime_string_from_unix_time(int(m.get("t", 0)) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60, true)
	var sub := L.f("%s  ·  %d giây  ·  %s", [Replay.mode_name(str(m.get("mode", ""))), int(m.get("secs", 0)), when.substr(0, 16)])
	if str(m.get("ver", "")) != Replay.version():
		sub += "  ·  " + L.f("bản %s", str(m.get("ver", "?")))
	info.add_child(UI.label(sub, 16, Color(0.78, 0.75, 0.68)))
	var id := str(m.get("id", ""))
	row.add_child(UI.gold_button("▶ Xem", func(): _watch(id), 22, 130))
	row.add_child(UI.button("Xóa", func(): confirm("Xóa trận đã lưu này?", func():
		Replay.delete(id)
		_build(), "Xóa"), 20, 100))
	return p

func _watch(id: String) -> void:
	var rp := Replay.load_one(id)
	if rp.is_empty():
		toast("Không mở được trận này", Color(1, 0.6, 0.5))
		return
	Flow.watch(rp, func(_res: Dictionary): Game.goto(ReplayScreen.new()))

func back() -> void:
	Game.goto(HubScreen.new())
