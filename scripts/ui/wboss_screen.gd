class_name WBossScreen
extends Screen
## Boss Thế Giới: today's giant (with the hero beside it for scale), the
## server-wide health pool, this hero's damage and rank, tries, the day-reward
## claim and the damage board.

var boss: Dictionary
var _right: VBoxContainer
var _pool_bar: ColorRect
var _pool_lbl: Label
var _rank_lbl: Label
var _pool := -2            # -2 loading, -1 offline
var _rank := -1
var fake_rows: Array = []  # --screen=wbossboard
var fake_pool := -1        # --screen=wboss --pool=N: damage already dealt today

func _ready() -> void:
	boss = WBoss.today_boss()
	_init_ui(boss.theme)
	var h := Game.hero
	# the giant and the hero side by side, so the size reads at a glance
	show.cam_d = 8.4
	show.cam_y = 2.0
	show.look_y = 1.55
	show.add_body(Hero.look(h), Hero.sect(h).style, -2.2, -0.5)
	var bs := WBoss.side(h, boss)
	show.add_body(bs.look, Sects.get_sect(bs.sect).style, -0.2, -0.7)
	show.set_focus(0.9)
	shade(false, 0.6, 0.9)
	top_bar("Boss Thế Giới", back)
	var card := UI.panel(Color(0.06, 0.05, 0.07, 0.88))
	card.anchor_left = 1.0
	card.anchor_right = 1.0
	card.anchor_bottom = 1.0
	card.offset_left = -600
	card.offset_right = -24
	card.offset_top = 92
	card.offset_bottom = -20
	ui.add_child(card)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(sc)
	_right = UI.vbox(10)
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_right)
	_build()
	_load()

func _build() -> void:
	var h := Game.hero
	var w := WBoss.ensure(h)
	refresh_wallet()
	for c in _right.get_children():
		c.queue_free()
	_right.add_child(UI.heading(boss.name, 42))
	_right.add_child(UI.label("%s  ·  Võ công %s" % [boss.title, Sects.get_sect(boss.sect).name], 19, boss.aura.lightened(0.3), UI.bold))
	var d := UI.label(boss.desc, 17, Color(0.85, 0.82, 0.75))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(d)
	# server-wide health
	var pp := UI.panel(Color(0.1, 0.05, 0.05, 0.9), boss.aura.darkened(0.3))
	var pv := UI.vbox(6)
	pp.add_child(pv)
	pv.add_child(UI.label("Sinh lực Boss — cả giang hồ cùng đánh", 18, UI.GOLD, UI.bold))
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0, 0, 0, 0.7)
	bar_bg.custom_minimum_size = Vector2(0, 22)
	pv.add_child(bar_bg)
	_pool_bar = ColorRect.new()
	_pool_bar.color = Color(0.85, 0.18, 0.12)
	_pool_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_bg.add_child(_pool_bar)
	_pool_lbl = UI.label("", 17, UI.PAPER)
	_pool_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(_pool_lbl)
	_right.add_child(pp)
	_show_pool()
	if not WBoss.unlocked(h):
		_right.add_child(UI.label("Cần đạt cấp %d để khiêu chiến Boss Thế Giới." % WBoss.MIN_LEVEL, 21, Color(1, 0.65, 0.5), UI.bold))
	else:
		_right.add_child(UI.label("Sát thương hôm nay: %s   ·   Cao nhất 1 lượt: %s" % [UI.fmt(int(w.dmg)), UI.fmt(int(w.best))], 19, UI.PAPER, UI.bold))
		_rank_lbl = UI.label("", 17, Color(0.85, 0.82, 0.75))
		_right.add_child(_rank_lbl)
		_show_rank()
	if WBoss.claimable(h):
		var p: Dictionary = w.prev
		var cb := UI.gold_button("Nhận thưởng xếp hạng ngày %s" % _short(str(p.date)), _claim, 21)
		cb.custom_minimum_size.y = 58
		_right.add_child(cb)
	var note := UI.label("Mỗi ngày một Boss. Mỗi lượt %d giây: gây càng nhiều sát thương càng nhiều thưởng. Đánh liên tục để Phá Thế (thanh vàng) — Boss sẽ choáng. Boss quá to để Cầm Nã. Hôm sau nhận thưởng theo hạng; nếu cả giang hồ hạ được Boss, ai tham gia cũng được thêm quà." % WBoss.FIGHT_SECONDS, 15, Color(0.75, 0.72, 0.66))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(note)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right.add_child(sp)
	var row := UI.hbox(10)
	_right.add_child(row)
	row.add_child(UI.button("Bảng xếp hạng", _board, 19, 150))
	if WBoss.unlocked(h) and WBoss.can_ad(h):
		var ad := UI.button("▶ QC: +1 lượt", _ad_try, 19, 150)
		ad.disabled = not Ads.is_ready()
		row.add_child(ad)
	var n := WBoss.left(h)
	var go := UI.gold_button("Khiêu Chiến (%d)" % n, Flow.start_wboss, 24)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.custom_minimum_size.y = 64
	go.disabled = not WBoss.unlocked(h) or n <= 0
	row.add_child(go)
	if WBoss.unlocked(h) and n <= 0:
		_right.add_child(UI.label("Hết lượt hôm nay. Boss mới xuất hiện vào ngày mai!", 17, Color(1, 0.65, 0.5)))

static func _short(date: String) -> String:
	var p := date.split("-")
	return "%s/%s" % [p[2], p[1]] if p.size() == 3 else date

func _load() -> void:
	if fake_pool >= 0:   # promo / store shots: a pool already part-way down
		_pool = fake_pool
		_show_pool()
		return
	if not Cloud.enabled():
		_pool = -1
		_show_pool()
		return
	var h := Game.hero
	if int(WBoss.ensure(h).dmg) > 0:
		await WBoss.publish(h, Game.slot)   # catch up after an offline try
	await WBoss.load_pool()
	var total := await WBoss.pool_dmg()
	var rk := await WBoss.rank_of(int(WBoss.ensure(h).dmg))
	if not is_inside_tree():
		return
	_pool = total
	_rank = rk
	_show_pool()
	_show_rank()

func _show_pool() -> void:
	if not is_instance_valid(_pool_lbl):
		return
	if _pool == -2:
		_pool_lbl.text = "Đang tải…"
		return
	if _pool < 0:
		_pool_lbl.text = "Ngoại tuyến — không xem được sinh lực chung. Sát thương vẫn được tính khi có mạng."
		return
	var left := maxi(0, WBoss.pool() - _pool)
	var r := float(left) / WBoss.pool()
	_pool_bar.anchor_right = r
	_pool_bar.offset_right = 0
	if left <= 0:
		_pool_lbl.text = "ĐÃ BỊ HẠ! Mọi người tham gia hôm nay được thêm: %s" % WBoss.rewards_text(WBoss.KILL_BONUS)
		_pool_lbl.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	else:
		_pool_lbl.text = "%s / %s  (%d%%)" % [UI.fmt(left), UI.fmt(WBoss.pool()), int(ceil(r * 100))]

func _show_rank() -> void:
	if not is_instance_valid(_rank_lbl):
		return
	var w := WBoss.ensure(Game.hero)
	if int(w.dmg) <= 0:
		_rank_lbl.text = "Chưa đánh hôm nay."
	elif Ranks.hidden():
		_rank_lbl.text = "Bạn đang ẩn khỏi bảng xếp hạng — vẫn nhận thưởng tham gia."
	elif _rank > 0:
		var t := WBoss.tier(_rank)
		_rank_lbl.text = "Hạng hiện tại: %d  →  thưởng ngày mai: %s" % [_rank, WBoss.rewards_text(t[2])]
	else:
		_rank_lbl.text = "Thưởng ngày mai: theo hạng sát thương."

func _claim() -> void:
	var r := await WBoss.claim(Game.hero)
	if r.is_empty() or not is_inside_tree():
		return
	Game.save()
	Game.sfx("coin")
	var rk := int(r.rank)
	var head := ("Hạng %d" % rk) if rk > 0 else "Tham gia"
	toast("%s%s: %s" % [head, " · Boss bị hạ" if r.killed else "", WBoss.rewards_text(r.rewards)], Color(0.6, 1, 0.7))
	_build()

func _ad_try() -> void:
	if not Ads.show_rewarded(func():
		WBoss.add_ad_try(Game.hero)
		Game.save()
		if is_inside_tree():
			_build(), Callable(), "wboss"):
		toast("Chưa có quảng cáo, thử lại sau", Color(1, 0.7, 0.5))

# ------------------------------------------------------------- board
func _board() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(dim)
	var p := UI.panel()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 120
	p.offset_right = -120
	p.offset_top = 40
	p.offset_bottom = -30
	dim.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	var top := UI.hbox(12)
	v.add_child(top)
	var hd := UI.heading("Bảng Sát Thương — %s" % boss.name, 34)
	hd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hd)
	top.add_child(UI.button("Đóng", func(): dim.queue_free(), 22, 120))
	var cols := UI.hbox(20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cols)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(sc)
	var list := UI.vbox(4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	# reward tiers
	var tv := UI.vbox(6)
	tv.custom_minimum_size.x = 330
	cols.add_child(tv)
	tv.add_child(UI.label("Thưởng theo hạng (nhận hôm sau)", 18, UI.GOLD, UI.bold))
	for t in WBoss.TIERS:
		var l := UI.label("%s: %s" % [t[1], WBoss.rewards_text(t[2])], 16, UI.PAPER)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(l)
	var kb := UI.label("Boss bị hạ: mọi người thêm %s" % WBoss.rewards_text(WBoss.KILL_BONUS), 16, Color(0.6, 1, 0.6))
	kb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(kb)
	var wait := UI.label("Đang tải…" if Cloud.enabled() or not fake_rows.is_empty() else "Cần kết nối mạng để xem bảng.", 18, Color(0.8, 0.77, 0.7))
	list.add_child(wait)
	var rows: Array = fake_rows if not fake_rows.is_empty() else await WBoss.board()
	if not is_instance_valid(list):
		return
	wait.queue_free()
	if rows.is_empty() and Cloud.enabled():
		list.add_child(UI.label("Chưa ai đánh Boss hôm nay. Hãy là người đầu tiên!", 18, Color(0.8, 0.77, 0.7)))
	var mine := "%s_%d" % [Cloud.uid, Game.slot]
	for i in rows.size():
		var r: Dictionary = rows[i]
		var me := str(r.get("_id", "")) == mine
		var line := UI.hbox(10)
		var bg := UI.panel(Color(0.3, 0.22, 0.08, 0.9) if me else Color(0.1, 0.08, 0.07, 0.8), UI.GOLD if me else UI.GOLD_D)
		bg.add_child(line)
		var no := UI.label("%d" % (i + 1), 22, UI.GOLD if i < 3 else UI.PAPER, UI.title)
		no.custom_minimum_size.x = 44
		line.add_child(no)
		var nm := UI.label("%s  ·  %s  ·  Cấp %d" % [Chat.safe_name(r.get("name", "?")), Sects.get_sect(str(r.get("sect", "vo_dang"))).name, int(r.get("level", 1))], 18, UI.PAPER)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		line.add_child(nm)
		line.add_child(UI.label(UI.fmt(int(r.get("dmg", 0))), 20, Color(1, 0.85, 0.35), UI.bold))
		list.add_child(bg)

func back() -> void:
	Game.goto(HubScreen.new())
