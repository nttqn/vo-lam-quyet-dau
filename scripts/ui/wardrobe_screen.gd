class_name WardrobeScreen
extends Screen
## Y Phục: preview and wear the sect's outfits; premium ones are bought with jade.

var _list: VBoxContainer
var _preview := ""     # outfit shown on the model ("" = sect clothes)

func _ready() -> void:
	var h := Game.hero
	_preview = str(h.get("outfit", ""))
	_init_ui("temple")
	shade(false, 0.55, 0.8)
	top_bar("Y Phục", back)
	var card := UI.panel(Color(0.06, 0.05, 0.07, 0.88))
	card.anchor_left = 1.0
	card.anchor_right = 1.0
	card.anchor_bottom = 1.0
	card.offset_left = -560
	card.offset_right = -24
	card.offset_top = 92
	card.offset_bottom = -20
	ui.add_child(card)
	_list = UI.vbox(10)
	card.add_child(_list)
	_build()

func _model() -> void:
	var h := Game.hero
	show.clear()
	var lk := Hero.look(h)
	if lk.has("model"):
		lk["model"] = Outfits.model_for(h.sect, _preview)
	show.add_body(lk, Hero.sect(h).style, -1.3, -0.9)
	show.spin = true
	show.set_focus(-0.5)

func _build() -> void:
	var h := Game.hero
	_model()
	for c in _list.get_children():
		c.queue_free()
	_list.add_child(UI.heading(Hero.sect(h).name, 40))
	var wear := str(h.get("outfit", ""))
	_list.add_child(_row("", "Y phục bản môn", "Trang phục môn phái.", 0, true, wear == ""))
	for o in Outfits.of(h.sect):
		_list.add_child(_row(o.id, o.name, o.desc, int(o.price), Outfits.available(h.sect, o.id), wear == o.id))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_child(sp)
	var n := UI.label("Y phục chỉ đổi vẻ ngoài, không đổi chỉ số. Người khác thấy bộ bạn mặc khi tỉ võ.", 16, Color(0.78, 0.75, 0.7))
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(n)

func _row(id: String, nm: String, desc: String, price: int, ready: bool, worn: bool) -> Control:
	var h := Game.hero
	var p := UI.panel(Color(0.1, 0.07, 0.08, 0.95), UI.GOLD if id == _preview else UI.GOLD_D)
	var row := UI.hbox(10)
	p.add_child(row)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UI.label(nm + ("  ·  đang mặc" if worn else ""), 22, UI.GOLD, UI.bold))
	var d := UI.label(desc, 16, Color(0.85, 0.82, 0.75))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(d)
	if not ready:
		var l := UI.label("Sắp ra mắt", 18, Color(0.75, 0.72, 0.66), UI.bold)
		row.add_child(l)
		return p
	if id != _preview:
		row.add_child(UI.button("Xem", func(): _show(id), 18, 80))
	if id == "" or Outfits.owned(h, id):
		var b := UI.gold_button("Mặc", func(): _wear(id), 18, 90)
		b.disabled = worn
		row.add_child(b)
	else:
		var b := UI.gold_button("%d Ngọc" % price, func(): _buy(id, price), 18, 120)
		b.disabled = int(h.jade) < price
		row.add_child(b)
	return p

func _show(id: String) -> void:
	_preview = id
	_build()

func _wear(id: String) -> void:
	Game.hero.outfit = id
	_preview = id
	Game.sfx("click")
	Game.save()
	_build()

func _buy(id: String, price: int) -> void:
	var h := Game.hero
	if int(h.jade) < price or Outfits.owned(h, id):
		return
	confirm("Mua y phục này với %d Ngọc?" % price, func():
		h.jade = int(h.jade) - price
		var o: Array = h.get("outfits", [])
		o.append(id)
		h.outfits = o
		h.outfit = id
		_preview = id
		Game.sfx("levelup")
		Game.save()
		refresh_wallet()
		_build(), "Mua")

func back() -> void:
	Game.goto(HubScreen.new())
