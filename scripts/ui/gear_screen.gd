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
	# painted icon on a tile tinted by rarity (no icon yet: slot name instead)
	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(64, 64)
	tile.add_theme_stylebox_override("panel", UI.box(Items.RARITY_COL[rar].darkened(0.7), Items.RARITY_COL[rar], 2, 10, 0))
	row.add_child(tile)
	if not tex:
		var sl := UI.label(Items.SLOT_NAMES[it.slot].replace(" ", "\n"), 15, Items.RARITY_COL[rar].lightened(0.3), UI.bold)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tile.add_child(sl)
	else:
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
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UI.label("%s  ·  %s" % [Items.item_name(it, _style()), Items.RARITY[rar]], 21, Items.RARITY_COL[rar], UI.bold))
	# wrapped so long stat lines (bonus lines) never push the column off screen
	var stl := UI.label("[%s] %s" % [Items.SLOT_NAMES[it.slot], Items.stat_text(Items.stats(it))], 17, Color(0.88, 0.85, 0.78))
	stl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(stl)
	(info.get_child(0) as Label).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.custom_minimum_size.x = 120
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
	var lh := UI.hbox(12)
	_left.add_child(lh)
	var lt := UI.label("Đang mặc", 24, UI.GOLD, UI.bold)
	lt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lh.add_child(lt)
	for id in Mats.IDS:
		lh.add_child(Mats.chip(h, id, -1, 30))
	for slot in Items.SLOTS:
		var it = h.gear.get(slot)
		if it is Dictionary and not it.is_empty():
			Items.ensure_aff(it)
			var up := UI.gold_button("Rèn", func(): _forge(slot), 22, 100)
			if _forge_ready(it):
				up.text = "Rèn ●"
			_left.add_child(_card(it, [up]))
		else:
			var p := UI.panel(Color(0.07, 0.05, 0.06, 0.7))
			p.add_child(UI.label("[%s] — trống" % Items.SLOT_NAMES[slot], 20, Color(0.6, 0.58, 0.55)))
			_left.add_child(p)
	if shop:
		_right.add_child(UI.label("Nguyên liệu rèn", 24, UI.GOLD, UI.bold))
		for m in _mat_stock():
			_right.add_child(_mat_card(m))
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
		else:
			_right.add_child(UI.label("Đồ thừa có thể Phân giải lấy vàng + Huyền Thiết.", 16, Color(0.75, 0.72, 0.66)))
		for i in h.bag.size():
			var it: Dictionary = h.bag[i]
			Items.ensure_aff(it)
			var idx: int = i
			var eb := UI.gold_button("Mặc", func(): _equip(idx), 18, 90)
			var sv := Items.salvage(it)
			var sb := UI.button("Phân giải\n+%d HT" % int(sv.mats.iron), func(): _salvage(idx), 15, 96)
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
	Items.ensure_aff(n)
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

func _salvage(i: int) -> void:
	var h := Game.hero
	var it: Dictionary = h.bag[i]
	var sv := Items.salvage(it)
	var go := func():
		h.gold = int(h.gold) + int(sv.gold)
		Mats.give(h, sv.mats)
		h.bag.erase(it)
		Game.sfx("coin")
		Game.save()
		toast("+%s vàng  ·  %s" % [UI.fmt(sv.gold), Mats.text(sv.mats)])
		_build()
	# ask before breaking anything valuable
	if int(it.rar) >= 3 or int(it.get("plus", 0)) >= 5:
		confirm("Phân giải %s?\nNhận %s vàng, %s." % [Items.item_name(it, _style()), UI.fmt(sv.gold), Mats.text(sv.mats, ", ")], go, "Phân giải")
	else:
		go.call()

func _forge(slot: String) -> void:
	var fp := ForgePanel.new(slot)
	fp.changed.connect(func():
		if is_inside_tree() and not is_queued_for_deletion():
			_build.call_deferred())
	ui.add_child(fp)

## Something can be done right now (a red dot on the button).
func _forge_ready(it: Dictionary) -> bool:
	var h := Game.hero
	if int(it.get("plus", 0)) < Items.MAX_PLUS and int(h.gold) >= Items.upgrade_cost(it) and Mats.count(h, "iron") >= Items.iron_cost(it):
		return true
	if int(it.rar) < Items.MAX_RAR:
		var c := Items.ascend_cost(it)
		if int(h.gold) >= int(c.gold) and Mats.count(h, "star") >= int(c.star):
			return true
	return false

## Materials on sale: Huyền Thiết for gold, the rarer ones for Ngọc.
func _mat_stock() -> Array:
	var tier := 1
	for r in Journey.REGIONS.size():
		if Journey.region_unlocked(Game.hero, r):
			tier = r + 1
	return [
		{"id": "iron", "n": 10, "gold": 30 * 10 * tier, "jade": 0},
		{"id": "charm", "n": 1, "gold": 0, "jade": 12},
		{"id": "wash", "n": 1, "gold": 0, "jade": 6},
	]

func _mat_card(m: Dictionary) -> Control:
	var h := Game.hero
	var id: String = m.id
	var p := UI.panel(Color(0.07, 0.05, 0.06, 0.9), Mats.color(id).darkened(0.3))
	var row := UI.hbox(10)
	p.add_child(row)
	row.add_child(Mats.gem(id, 56))
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UI.label("%s ×%d   (đang có %d)" % [Mats.name_of(id), int(m.n), Mats.count(h, id)], 21, Mats.color(id), UI.bold))
	var d := UI.label(Mats.INFO[id][1], 16, Color(0.85, 0.82, 0.75))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(d)
	var by_jade := int(m.jade) > 0
	var b := UI.gold_button("Mua\n%s" % (("%d Ngọc" % int(m.jade)) if by_jade else UI.fmt(int(m.gold))), func(): _buy_mat(m), 17, 120)
	b.disabled = (int(h.jade) < int(m.jade)) if by_jade else (int(h.gold) < int(m.gold))
	row.add_child(b)
	return p

func _buy_mat(m: Dictionary) -> void:
	var h := Game.hero
	if int(h.jade) < int(m.jade) or int(h.gold) < int(m.gold):
		return
	h.jade = int(h.jade) - int(m.jade)
	h.gold = int(h.gold) - int(m.gold)
	Mats.add(h, str(m.id), int(m.n))
	Game.sfx("coin")
	Game.save()
	toast("Đã mua %s ×%d" % [Mats.name_of(str(m.id)), int(m.n)])
	_build()

func back() -> void:
	Game.goto(HubScreen.new())
