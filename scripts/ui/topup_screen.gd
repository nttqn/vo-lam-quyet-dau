class_name TopupScreen
extends Screen
## Bảo Khố: Ngọc packs (first buy of each ×2), Gói Tân Thủ, Bỏ Quảng Cáo,
## Mở Ô Nhân Vật, and Khôi phục giao dịch. Purchases go through Iap.

var _body: Control

func _ready() -> void:
	_init_ui("temple")
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	top_bar("Bảo Khố", back)
	_body = Control.new()
	_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.offset_left = 24
	_body.offset_right = -24
	_body.offset_top = 90
	_body.offset_bottom = -12
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_body)
	Iap.changed.connect(_build)
	_build()

func _build() -> void:
	if not is_inside_tree():
		return
	refresh_wallet()
	for c in _body.get_children():
		c.queue_free()
	var h := Game.hero
	var row := UI.hbox(18)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(row)
	# --- left: one-time offers
	var left := UI.vbox(10)
	left.custom_minimum_size.x = 430
	row.add_child(left)
	if not h.get("starter", false):
		left.add_child(_offer(Iap.STARTER, "Gói Tân Thủ", "Mỗi nhân vật mua một lần",
			"%d Ngọc · %s Vàng\n%s" % [int(Iap.STARTER_GIFT.jade), UI.fmt(int(Iap.STARTER_GIFT.gold)), Mats.text(Iap.STARTER_GIFT.mats, " · ")],
			Color(0.8, 0.45, 0.12), false))
	left.add_child(_offer(Iap.NO_ADS, "Bỏ Quảng Cáo", "Mua một lần, dùng mãi trên tài khoản Google này",
		"Không còn quảng cáo chen ngang.\nQuà xem quảng cáo nhận ngay, không cần xem.",
		Color(0.55, 0.2, 0.2), Iap.no_ads()))
	left.add_child(_offer(Iap.SLOTS, "Mở Ô Nhân Vật 5–6", "Mua một lần, mở cho mọi nhân vật",
		"Thêm hai ô lưu để luyện thêm môn phái khác.",
		Color(0.25, 0.4, 0.62), Iap.slots_owned()))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(sp)
	var rs := UI.button("Khôi phục giao dịch", Iap.restore, 18)
	rs.custom_minimum_size.y = 46
	left.add_child(rs)
	# --- right: Ngọc packs
	var right := UI.vbox(10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	right.add_child(UI.heading("Nạp Ngọc", 34))
	var note := UI.label("Lần đầu mua mỗi gói: nhận gấp đôi Ngọc (tính theo từng nhân vật).", 17, Color(0.6, 1, 0.75))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(note)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(grid)
	var k := 0
	for id in Iap.PACKS:
		k += 1
		grid.add_child(_pack(id, k))
	var closed := Iap.closed_reason()
	if closed != "":
		var cl := UI.label(closed, 18, Color(1, 0.75, 0.55), UI.bold)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		right.add_child(cl)
	var fine := UI.label("Thanh toán qua Google Play. Ngọc dùng mua Y Phục, Bí Kíp, Hộ Phù, Tẩy Luyện Thạch và trang bị quý.", 15, Color(0.72, 0.7, 0.64))
	fine.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(fine)

func _buy_button(id: String, owned: bool) -> Button:
	var pr := Iap.price(id)
	var b := UI.gold_button("Đã sở hữu" if owned else (pr if pr != "" else "—"), func(): Iap.buy(id), 20, 150)
	b.custom_minimum_size.y = 50
	b.disabled = owned or not Iap.available() or pr == ""
	return b

func _offer(id: String, title: String, sub: String, body: String, col: Color, owned: bool) -> Control:
	var p := UI.panel(Color(col.darkened(0.7), 0.95), col.lightened(0.15))
	var row := UI.hbox(12)
	p.add_child(row)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UI.label(title, 23, UI.GOLD, UI.title))
	v.add_child(UI.label(sub, 14, Color(0.8, 0.77, 0.7)))
	var bl := UI.label(body, 16, UI.PAPER)
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(bl)
	var b := _buy_button(id, owned)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	return p

func _pack(id: String, size_k: int) -> Control:
	var h := Game.hero
	var pk: Dictionary = Iap.PACKS[id]
	var first := Iap.first_bonus(h, id)
	var p := UI.panel(Color(0.06, 0.12, 0.1, 0.95), Color(0.35, 0.8, 0.6) if first else UI.GOLD_D)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UI.hbox(10)
	p.add_child(row)
	var gem := JadePile.new()
	gem.n = size_k
	gem.custom_minimum_size = Vector2(84, 84)
	row.add_child(gem)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UI.label(str(pk.name), 21, UI.GOLD, UI.bold))
	var base := int(pk.jade) + int(pk.bonus)
	v.add_child(UI.label("%d Ngọc" % Iap.pack_jade(h, id), 26, Color(0.55, 1, 0.8), UI.title))
	var extra := []
	if int(pk.bonus) > 0:
		extra.append("gồm %d thưởng" % int(pk.bonus))
	if first:
		extra.append("lần đầu ×2 (thường %d)" % base)
	if not extra.is_empty():
		var el := UI.label(" · ".join(extra), 14, Color(0.75, 0.95, 0.8))
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(el)
	var b := _buy_button(id, false)
	b.custom_minimum_size.x = 130
	v.add_child(b)
	return p

func back() -> void:
	Game.goto(HubScreen.new())

## A little heap of jade drops: more for bigger packs.
class JadePile extends Control:
	var n := 1

	func _draw() -> void:
		var spots := [[Vector2(0.5, 0.55), 0.3], [Vector2(0.3, 0.68), 0.22], [Vector2(0.72, 0.7), 0.22], [Vector2(0.5, 0.3), 0.2]]
		var s := minf(size.x, size.y)
		for i in range(mini(n, spots.size()) - 1, -1, -1):
			var c: Vector2 = spots[i][0] * size
			var r: float = spots[i][1] * s
			_gem(c, r)

	func _gem(c: Vector2, r: float) -> void:
		var pts := PackedVector2Array()
		for k in 6:
			var a := PI / 6.0 + k * TAU / 6.0
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, Color(0.18, 0.62, 0.45))
		var inner := PackedVector2Array()
		for k in 6:
			var a := PI / 6.0 + k * TAU / 6.0
			inner.append(c + Vector2(cos(a), sin(a)) * r * 0.55 + Vector2(-r * 0.08, -r * 0.1))
		draw_colored_polygon(inner, Color(0.45, 0.92, 0.7))
		pts.append(pts[0])
		draw_polyline(pts, Color(0.9, 0.8, 0.45), maxf(1.5, r * 0.08), true)
		draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.12, Color(1, 1, 1, 0.75))
