class_name CheckinPanel
extends Control
## Điểm danh: the 7-day reward row, today's card with "Nhận".

var on_claim: Callable
var _row: HBoxContainer
var _info: Label
var _btn: Button

func _init(p_on_claim := Callable()) -> void:
	on_claim = p_on_claim

func _ready() -> void:
	add_to_group("modal")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var p := UI.panel()
	c.add_child(p)
	var v := UI.vbox(14)
	p.add_child(v)
	var t := UI.heading("Điểm Danh", 44)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	_info = UI.label("", 19, Color(0.85, 0.82, 0.75))
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_info)
	_row = UI.hbox(10)
	v.add_child(_row)
	var br := UI.hbox(14)
	br.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(br)
	_btn = UI.gold_button("Nhận quà hôm nay", _claim, 24, 260)
	br.add_child(_btn)
	br.add_child(UI.button("Đóng", queue_free, 24, 150))
	_build()

func _build() -> void:
	var h := Game.hero
	for c in _row.get_children():
		c.queue_free()
	var n := Checkin.days(h)
	var can := Checkin.can_claim(h)
	var done_upto := n % 7 if can else ((n - 1) % 7) + 1   # cards 0..done_upto-1 claimed
	var today := n % 7 if can else -1
	_info.text = "Đã điểm danh %d ngày · lỡ một ngày không mất chuỗi" % n + ("" if Checkin.days(h) >= 30 else "  ·  đủ 30 ngày nhận danh hiệu Chuyên Cần")
	for i in 7:
		var claimed := i < done_upto
		var is_today := i == today
		var bg := Color(0.16, 0.11, 0.05, 0.95) if is_today else Color(0.08, 0.06, 0.07, 0.92)
		var card := UI.panel(bg, UI.GOLD if is_today or i == 6 else UI.GOLD_D)
		card.custom_minimum_size = Vector2(150, 190)
		var cv := UI.vbox(6)
		card.add_child(cv)
		var d := UI.label("Ngày %d" % (i + 1), 22, UI.GOLD if is_today else UI.PAPER, UI.bold)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(d)
		var rw := Checkin.reward(h, i)
		var lines := Checkin.text(rw).split(" · ")
		var l := UI.label("\n".join(lines), 17, Color(0.9, 0.86, 0.78))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cv.add_child(l)
		var s := UI.label("✓ Đã nhận" if claimed else ("Hôm nay" if is_today else ""), 17, Color(0.6, 1, 0.6) if claimed else UI.GOLD, UI.bold)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(s)
		if claimed:
			card.modulate = Color(1, 1, 1, 0.55)
		_row.add_child(card)
	_btn.disabled = not can
	_btn.text = "Nhận quà hôm nay" if can else "Mai quay lại nhé"

func _claim() -> void:
	var rw := Checkin.claim(Game.hero)
	if rw.is_empty():
		return
	Game.sfx("coin")
	Titles.refresh(Game.hero)
	Game.save()
	_build()
	_info.text = "Đã nhận: " + Checkin.text(rw)
	_info.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	if on_claim.is_valid():
		on_claim.call()
