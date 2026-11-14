class_name ResultScreen
extends Screen
## Post-fight summary with rewards.

var out: Dictionary

func _init(p_out: Dictionary) -> void:
	out = p_out

func _ready() -> void:
	var h := Game.hero
	var theme := "temple"
	if out.mode == "stage":
		theme = Journey.REGIONS[out.r].theme
	_init_ui(theme)
	var s := Hero.sect(h)
	show.set_focus(1.3)
	var b := show.add_body(Hero.look(h), s.style, 0.0, -0.4)
	if out.won:
		show.hold[0] = {"clip": "b/Idle_FoldArms", "frac": -1.0}
	else:
		show.hold[0] = {"clip": "b/Idle_No", "frac": -1.0}
	shade(false, 0.6, 0.9)
	Game.music("menu")
	var right := UI.vbox(12)
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.anchor_bottom = 1.0
	right.offset_left = -560
	right.offset_right = -36
	right.offset_top = 40
	right.offset_bottom = -30
	ui.add_child(right)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc)
	var body := UI.vbox(8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(body)
	var title := UI.heading("Chiến Thắng" if out.won else "Thất Bại", 64)
	if not out.won:
		title.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	body.add_child(title)
	if out.mode == "stage":
		var foe: Array = Journey.REGIONS[out.r].foes[out.s]
		body.add_child(UI.label(("Đã hạ " if out.won else "Không địch nổi ") + "%s — %s" % [foe[0], foe[1]], 24))
		if out.won:
			var stars: int = out.stars
			var srow := UI.hbox(14)
			srow.add_child(UI.label("★".repeat(stars) + "☆".repeat(3 - stars), 40, UI.GOLD))
			var leg := UI.label("★ thắng · ★★ còn ≥50% sinh lực · ★★★ thắng tuyệt đối", 15, Color(0.75, 0.72, 0.66))
			leg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			leg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			leg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			srow.add_child(leg)
			body.add_child(srow)
	elif out.mode == "duel":
		var dl := int(out.delta)
		body.add_child(UI.label("Tỉ Võ với %s" % out.foe, 24))
		body.add_child(UI.label("Điểm tỉ võ %s%d  →  %d (%s)" % ["+" if dl >= 0 else "", dl, int(h.duel.score), Duel.tier(int(h.duel.score))[0]], 26, Color(0.6, 1, 0.6) if dl >= 0 else Color(1, 0.6, 0.5), UI.bold))
	elif out.mode == "tower":
		body.add_child(UI.label("Tháp Thí Luyện — Tầng %d" % int(out.f) + (" · vượt tầng mới!" if out.won and int(out.f) == Tower.best(h) else ""), 26, UI.GOLD, UI.bold))
	elif out.mode == "arena":
		body.add_child(UI.label("Lôi Đài — liên thắng %d trận" % int(out.streak), 26, UI.GOLD, UI.bold))
	var res: Dictionary = out.res
	body.add_child(UI.label("Liên kích cao nhất: %d   ·   Thời gian: %ds" % [int(res.max_combo), int(res.seconds)], 18, Color(0.85, 0.82, 0.76)))
	var rw: Dictionary = out.get("rewards", {})
	var rp := UI.panel(Color(0.08, 0.05, 0.04, 0.85))
	var rv := UI.vbox(6)
	rp.add_child(rv)
	rv.add_child(UI.label("Phần thưởng", 22, UI.GOLD, UI.bold))
	var wrow := UI.hbox(22)
	rv.add_child(wrow)
	wrow.add_child(UI.label("Kinh nghiệm +%d" % int(rw.get("exp", 0)), 22))
	if int(rw.get("gold", 0)) > 0:
		wrow.add_child(UI.label("Vàng +%d" % int(rw.gold), 22, UI.GOLD))
	if int(rw.get("jade", 0)) > 0:
		wrow.add_child(UI.label("Ngọc +%d" % int(rw.jade), 22, Color(0.5, 1.0, 0.8)))
	if out.has("drop"):
		var it: Dictionary = out.drop
		var l := UI.label("Chiến lợi phẩm: %s (%s)" % [Items.item_name(it, s.style), Items.RARITY[int(it.rar)]], 22, Items.RARITY_COL[int(it.rar)], UI.bold)
		rv.add_child(l)
	if out.has("book"):
		rv.add_child(UI.label("%s: %s" % [Books.name_of(out.book), Books.KINDS[out.book][1]], 21, Books.COLOR[out.book], UI.bold))
	var gained: Dictionary = res.get("insight", {})
	if not gained.is_empty() and res.has("learned"):
		var parts := []
		for k in gained:
			var m := Insight.skill_of(k)
			if not m.is_empty():
				parts.append("%s +%d" % [m.name, mini(int(gained[k]), Insight.PER_FIGHT)])
		var il := UI.label("Lĩnh ngộ: " + ", ".join(parts), 19, Color(0.75, 0.85, 1.0))
		il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(il)
	for l in res.get("learned", []):
		var lm := Insight.skill_of(str(l[0]))
		var ls := Sects.get_sect(Insight.parse(str(l[0]))[0])
		var txt := ("Ngộ ra chiêu mới: %s (%s)!" if int(l[1]) == 1 else "%s (%s) đột phá tầng %d!") 
		var ll := UI.label(txt % [lm.name, ls.name] if int(l[1]) == 1 else txt % [lm.name, ls.name, int(l[1])], 22, Color(0.55, 0.85, 1.0), UI.bold)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(ll)
	body.add_child(rp)
	# rewarded ad: double the experience and gold of a won fight
	if out.won and (int(rw.get("exp", 0)) > 0 or int(rw.get("gold", 0)) > 0):
		var dbl := UI.gold_button("▶ Xem quảng cáo: x2 kinh nghiệm & vàng", func(): pass, 19)
		dbl.disabled = not Ads.is_ready()
		dbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dbl.pressed.connect(_double.bind(dbl, rw))
		Ads.ready_changed.connect(func():
			if is_instance_valid(dbl) and dbl.text.begins_with("▶"):
				dbl.disabled = not Ads.is_ready())
		rp.get_child(0).add_child(dbl)
	if int(out.get("levels", 0)) > 0:
		var lv := UI.label("Thăng cấp! Đạt cấp %d  (+%d điểm tiềm năng, +%d điểm võ công)" % [int(h.level), int(out.levels) * Build.POINTS_PER_LEVEL, int(out.levels)], 22, Color(0.6, 1.0, 0.6), UI.bold)
		lv.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(lv)
		Game.sfx("levelup")
	if out.has("unlock"):
		body.add_child(UI.label("Mở khóa vùng mới: %s" % out.unlock, 22, UI.GOLD, UI.bold))
	if not out.won and out.mode == "stage":
		var tip := UI.label("Mẹo: cộng điểm tiềm năng, nâng võ công, cường hóa trang bị hoặc lên Lôi Đài rèn luyện thêm.", 18, Color(0.85, 0.8, 0.7))
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(tip)
	for c in body.get_children() + rv.get_children():
		if c is Label:
			(c as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var row := UI.hbox(12)
	right.add_child(row)
	if out.mode == "stage":
		row.add_child(UI.button("Đấu lại", func(): Flow.start_stage(out.r, out.s), 24, 160))
		var next_ok: bool = out.won and out.s < 5
		if next_ok:
			row.add_child(UI.gold_button("Trận kế", func(): Flow.start_stage(out.r, out.s + 1), 24, 170))
		row.add_child(UI.button("Bản đồ", func(): Game.goto(MapScreen.new()), 24, 150))
	elif out.mode == "duel":
		row.add_child(UI.gold_button("Tỉ võ tiếp", func(): Game.goto(DuelScreen.new()), 24, 190))
		row.add_child(UI.button("Về sảnh", func(): Game.goto(HubScreen.new()), 24, 170))
	elif out.mode == "tower":
		if out.won:
			row.add_child(UI.gold_button("Tầng kế", func(): Flow.start_tower(int(out.f) + 1), 24, 170))
		else:
			row.add_child(UI.button("Đấu lại", func(): Flow.start_tower(int(out.f)), 24, 160))
		row.add_child(UI.button("Về tháp", func(): Game.goto(TowerScreen.new()), 24, 150))
	else:
		if out.won:
			row.add_child(UI.gold_button("Đấu tiếp", func(): Flow.start_arena(int(out.n) + 1, out.get("revived", false)), 24, 190))
		elif not out.get("revived", false) and int(out.n) >= 3:
			# once per run: watch an ad to retry this fight and keep the streak
			var rv_b := UI.gold_button("▶ Hồi sinh (quảng cáo)", func(): pass, 22, 230)
			rv_b.disabled = not Ads.is_ready()
			rv_b.pressed.connect(_revive)
			row.add_child(rv_b)
		row.add_child(UI.button("Về sảnh", func(): Game.goto(HubScreen.new()), 24, 170))
	if out.won:
		Game.sfx("coin")
	if Game.autoplay:
		print("FLOWTEST result: mode=%s won=%s stars=%s rewards=%s level=%d daily=%s" % [out.mode, out.won, out.get("stars", 0), out.get("rewards", {}), int(h.level), h.get("daily", {}).get("prog", {})])
		get_tree().create_timer(0.5).timeout.connect(get_tree().quit)

func back() -> void:
	Game.goto(HubScreen.new())

func _double(dbl: Button, rw: Dictionary) -> void:
	dbl.disabled = true
	var ok := Ads.show_rewarded(func(): _doubled(dbl, rw))
	if not ok:
		dbl.disabled = false
		toast("Chưa có quảng cáo, thử lại sau", Color(1, 0.7, 0.5))

func _doubled(dbl: Button, rw: Dictionary) -> void:
	var extra := {"exp": int(rw.get("exp", 0)), "gold": int(rw.get("gold", 0))}
	var lv_up := Flow._grant(extra)
	Game.save()
	refresh_wallet()
	if is_instance_valid(dbl):
		dbl.text = "Đã nhân đôi: +%d kinh nghiệm, +%d vàng" % [extra.exp, extra.gold]
	if lv_up > 0:
		toast("Thăng cấp! Đạt cấp %d" % int(Game.hero.level), Color(0.6, 1.0, 0.6))

func _revive() -> void:
	if not Ads.show_rewarded(func(): Flow.start_arena(int(out.n), true)):
		toast("Chưa có quảng cáo, thử lại sau", Color(1, 0.7, 0.5))
