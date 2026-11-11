class_name GearScreen
extends Screen
## Equipment (equip / upgrade / sell) and the shop.

var shop := false
var _left: VBoxContainer
var _right: VBoxContainer

func _init(p_shop: bool) -> void:
	shop = p_shop

func _ready() -> void:
	_init_ui("river")
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)
	top_bar("Tiệm Binh Khí" if shop else "Trang Bị", back)
	var cols := UI.hbox(18)
	cols.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cols.offset_left = 24
	cols.offset_right = -24
	cols.offset_top = 92
	cols.offset_bottom = -16
	ui.add_child(cols)
	var lsc := ScrollContainer.new()
	lsc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(lsc)
	_left = UI.vbox(8)
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lsc.add_child(_left)
	var rsc := ScrollContainer.new()
	rsc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(rsc)
	_right = UI.vbox(8)
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.add_child(_right)
	_build()

func _style() -> String:
	return Hero.sect(Game.hero).style

func _card(it: Dictionary, buttons: Array, note := "") -> Control:
	var rar := int(it.rar)
	var p := UI.panel(Color(0.07, 0.05, 0.06, 0.9), Items.RARITY_COL[rar].darkened(0.3))
	var row := UI.hbox(10)
	p.add_child(row)
	var tex := Items.icon(it, _style())
	if tex:
		# painted icon on a tile tinted by rarity
		var tile := Panel.new()
		tile.custom_minimum_size = Vector2(64, 64)
		tile.add_theme_stylebox_override("panel", UI.box(Items.RARITY_COL[rar].darkened(0.7), Items.RARITY_COL[rar], 2, 10, 0))
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = 4
		tr.offset_top = 4
		tr.offset_right = -4
		tr.offset_bottom = -4
		tile.add_child(tr)
		row.add_child(tile)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UI.label("%s  ·  %s" % [Items.item_name(it, _style()), Items.RARITY[rar]], 21, Items.RARITY_COL[rar], UI.bold))
	info.add_child(UI.label("[%s] %s" % [Items.SLOT_NAMES[it.slot], Items.stat_text(Items.stats(it))], 17, Color(0.88, 0.85, 0.78)))
	if note != "":
		info.add_child(UI.label(note, 16, Color(0.6, 1, 0.6)))
	for b in buttons:
		row.add_child(b)
	return p

func _build() -> void:
	refresh_wallet()
	var h := Game.hero
	for c in _left.get_children():
		c.queue_free()
	for c in _right.get_children():
		c.queue_free()
	_left.add_child(UI.label("Đang mặc", 24, UI.GOLD, UI.bold))
	for slot in Items.SLOTS:
		var it = h.gear.get(slot)
		if it is Dictionary and not it.is_empty():
			var cost := Items.upgrade_cost(it)
			var up := UI.gold_button("+ (%s)" % UI.fmt(cost), func(): _upgrade(slot), 18, 130)
			up.disabled = int(it.get("plus", 0)) >= Items.MAX_PLUS or int(h.gold) < cost
			if int(it.get("plus", 0)) >= Items.MAX_PLUS:
				up.text = "+%d tối đa" % Items.MAX_PLUS
			_left.add_child(_card(it, [up]))
		else:
			var p := UI.panel(Color(0.07, 0.05, 0.06, 0.7))
			p.add_child(UI.label("[%s] — trống" % Items.SLOT_NAMES[slot], 20, Color(0.6, 0.58, 0.55)))
			_left.add_child(p)
	if shop:
		_right.add_child(UI.label("Hàng bày bán", 24, UI.GOLD, UI.bold))
		for it in _stock():
			var price := Items.price(it)
			var jade_cost := int(it.rar) >= 3
			var cost_txt := ("%d Ngọc" % _jade_price(it)) if jade_cost else UI.fmt(price)
			var b := UI.gold_button("Mua\n%s" % cost_txt, func(): _buy(it), 17, 120)
			b.disabled = (int(h.jade) < _jade_price(it)) if jade_cost else (int(h.gold) < price)
			_right.add_child(_card(it, [b], _compare(it)))
	else:
		_right.add_child(UI.label("Hành trang (%d)" % h.bag.size(), 24, UI.GOLD, UI.bold))
		if h.bag.is_empty():
			_right.add_child(UI.label("Trống. Mua đồ ở Tiệm Binh Khí hoặc đánh bại trùm vùng.", 18, Color(0.75, 0.72, 0.66)))
		for i in h.bag.size():
			var it: Dictionary = h.bag[i]
			var idx: int = i
			var eb := UI.gold_button("Mặc", func(): _equip(idx), 18, 90)
			var sb := UI.button("Bán\n%s" % UI.fmt(Items.sell_price(it)), func(): _sell(idx), 15, 90)
			_right.add_child(_card(it, [eb, sb], _compare(it)))

func _compare(it: Dictionary) -> String:
	var cur = Game.hero.gear.get(it.slot)
	if not (cur is Dictionary) or cur.is_empty():
		return "Ô trống — nên trang bị"
	var d := Items.score(it) - Items.score(cur)
	if d > 0:
		return "Mạnh hơn đồ đang mặc"
	return ""

func _jade_price(it: Dictionary) -> int:
	return 15 * int(it.tier) * (int(it.rar) - 2)

func _stock() -> Array:
	var h := Game.hero
	var max_r := 0
	for r in Journey.REGIONS.size():
		if Journey.region_unlocked(h, r):
			max_r = r
	var tier := clampi(max_r + 1, 1, 7)
	var out := []
	for slot in Items.SLOTS:
		for rar in [0, 1, 2]:
			out.append({"slot": slot, "tier": tier, "rar": rar, "plus": 0})
		if max_r >= 1:
			out.append({"slot": slot, "tier": tier, "rar": 3, "plus": 0})
	return out

func _buy(it: Dictionary) -> void:
	var h := Game.hero
	var n := it.duplicate()
	n["uid"] = randi()
	if int(it.rar) >= 3:
		var jp := _jade_price(it)
		if int(h.jade) < jp:
			return
		h.jade = int(h.jade) - jp
	else:
		var p := Items.price(it)
		if int(h.gold) < p:
			return
		h.gold = int(h.gold) - p
	var cur = h.gear.get(it.slot)
	if not (cur is Dictionary) or cur.is_empty() or Items.score(n) > Items.score(cur):
		if cur is Dictionary and not cur.is_empty():
			h.bag.append(cur)
		h.gear[it.slot] = n
		toast("Đã mua và trang bị %s" % Items.item_name(n, _style()))
	else:
		h.bag.append(n)
		toast("Đã mua %s (cất vào hành trang)" % Items.item_name(n, _style()))
	Game.sfx("coin")
	Game.save()
	_build()

func _equip(i: int) -> void:
	var h := Game.hero
	var it: Dictionary = h.bag[i]
	h.bag.remove_at(i)
	var cur = h.gear.get(it.slot)
	if cur is Dictionary and not cur.is_empty():
		h.bag.append(cur)
	h.gear[it.slot] = it
	Game.save()
	_build()

func _sell(i: int) -> void:
	var h := Game.hero
	var it: Dictionary = h.bag[i]
	h.gold = int(h.gold) + Items.sell_price(it)
	h.bag.remove_at(i)
	Game.sfx("coin")
	Game.save()
	_build()

func _upgrade(slot: String) -> void:
	var h := Game.hero
	var it: Dictionary = h.gear[slot]
	var cost := Items.upgrade_cost(it)
	if int(h.gold) < cost or int(it.get("plus", 0)) >= Items.MAX_PLUS:
		return
	h.gold = int(h.gold) - cost
	it.plus = int(it.get("plus", 0)) + 1
	Daily.track(h, "upgrade")
	Game.sfx("levelup")
	Game.save()
	_build()

func back() -> void:
	Game.goto(HubScreen.new())
