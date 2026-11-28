class_name ResultScreen
extends Screen
## Post-fight summary with rewards.

var out: Dictionary
var _again := false   # shown again after Xem lại: no jingles, no prompts

func _init(p_out: Dictionary) -> void:
	out = p_out
	_again = out.get("_shown", false)
	out["_shown"] = true

func _ready() -> void:
	var h := Game.hero
	var theme := "temple"
	if out.mode == "stage" or out.mode == "kyngo":
		theme = Journey.REGIONS[out.r].theme
	elif out.mode == "dungeon":
		theme = Dungeon.LIST[int(out.i)].theme
	elif out.mode == "wboss":
		theme = WBoss.today_boss().theme
	_init_ui(theme)
	var s := Hero.sect(h)
	show.set_focus(1.3)
	var b := show.add_body(Hero.look(h), s.style, 0.0, -0.4)
	if out.won or out.mode == "wboss":
		show.hold[0] = {"clip": "b/Idle_FoldArms", "frac": -1.0}
	else:
		show.hold[0] = {"clip": "b/Idle_No", "frac": -1.0}
	shade(false, 0.6, 0.9)
	Game.music("menu")
	if out.won and out.mode == "stage" and int(h.wins) >= 1 and not _again:
		# first won duel: a good moment for the Android 13+ reminder prompt (once)
		get_tree().create_timer(1.5).timeout.connect(Notify.ask_once)
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
	if out.mode == "wboss":
		title.text = "Hạ Gục Boss!" if out.won else "Kết Thúc Lượt"
	elif not out.won:
		title.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	body.add_child(title)
	if out.mode == "stage":
		var foe: Array = Journey.REGIONS[out.r].foes[out.s]
		if out.get("nm", false):
			body.add_child(UI.label(L.f("Ác Mộng · %s · Cấp %d", [Journey.REGIONS[out.r].name, Journey.nm_level(out.r, out.s)]), 21, Color(0.85, 0.6, 1.0), UI.bold))
		body.add_child(UI.label(L.f("Đã hạ %s — %s" if out.won else "Không địch nổi %s — %s", [foe[0], foe[1]]), 24))
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
		body.add_child(UI.label(L.f("Tỉ Võ với %s", out.foe), 24))
		body.add_child(UI.label(L.f("Điểm tỉ võ %s%d  →  %d (%s)", ["+" if dl >= 0 else "", dl, int(h.duel.score), Duel.tier(int(h.duel.score))[0]]), 26, Color(0.6, 1, 0.6) if dl >= 0 else Color(1, 0.6, 0.5), UI.bold))
	elif out.mode == "wboss":
		var wb := WBoss.ensure(h)
		body.add_child(UI.label(L.f("%s — sát thương %s (%d%% sinh lực lượt này)", [out.boss, UI.fmt(int(out.dmg)), int(round(float(out.ratio) * 100))]), 24, UI.GOLD, UI.bold))
		body.add_child(UI.label(L.f("Hôm nay: %s sát thương  ·  còn %d lượt", [UI.fmt(int(wb.dmg)), WBoss.left(h)]), 20, Color(0.85, 0.82, 0.76)))
	elif out.mode == "tower":
		body.add_child(UI.label(L.f("Tháp Thí Luyện — Tầng %d", int(out.f)) + (" · vượt tầng mới!" if out.won and int(out.f) == Tower.best(h) else ""), 26, UI.GOLD, UI.bold))
	elif out.mode == "arena":
		body.add_child(UI.label(L.f("Lôi Đài — liên thắng %d trận", int(out.streak)), 26, UI.GOLD, UI.bold))
	elif out.mode == "kyngo":
		body.add_child(UI.label(L.f("Kỳ Ngộ · %s — %s", [KyNgo.title(str(out.kind)), out.foe]), 24, Color(0.6, 0.9, 1.0), UI.bold))
		if out.won:
			body.add_child(UI.label("Kỳ ngộ đã thành. Giang hồ rộng lớn, ngày mai biết đâu lại gặp người mới.", 19, Color(0.85, 0.82, 0.76)))
		elif int(out.get("tries_left", 0)) > 0:
			body.add_child(UI.label(L.f("Người lạ vẫn chờ. Còn %d lần thử.", int(out.tries_left)), 20, Color(1, 0.85, 0.5)))
		else:
			body.add_child(UI.label("Người lạ đã rời đi. Kỳ ngộ khác sẽ đến vào ngày mai.", 20, Color(0.8, 0.75, 0.75)))
	elif out.mode == "dungeon":
		var dg: Dictionary = Dungeon.LIST[int(out.i)]
		body.add_child(UI.label(L.f("%s · %s — Ải %d/%d", [dg.name, Dungeon.DIFFS[int(out.d)][0], int(out.k) + 1, Dungeon.FIGHTS]), 24, UI.GOLD, UI.bold))
		if out.has("next_hp"):
			body.add_child(UI.label(L.f("Sinh lực mang sang ải kế: %d%% (đã hồi %d%%)", [int(round(float(out.next_hp) * 100)), int(Dungeon.HEAL_BETWEEN * 100)]), 21, Color(0.6, 1, 0.6)))
		elif out.get("cleared", false):
			body.add_child(UI.label(L.f("Đã vượt Phó Bản!  Lượt còn lại hôm nay: %d", Dungeon.left(h)), 22, Color(0.6, 1, 0.6), UI.bold))
		elif out.get("no_entry", false):
			body.add_child(UI.label("Hết lượt Phó Bản hôm nay — không nhận được thưởng.", 21, Color(1, 0.6, 0.5)))
		elif not out.won:
			body.add_child(UI.label("Thất bại không tốn lượt. Cường hóa trang bị rồi thử lại!", 20, Color(0.85, 0.8, 0.7)))
	var res: Dictionary = out.res
	body.add_child(UI.label(L.f("Liên kích cao nhất: %d   ·   Thời gian: %ds", [int(res.max_combo), int(res.seconds)]), 18, Color(0.85, 0.82, 0.76)))
	if not Replay.last.is_empty():
		var rrow := UI.hbox(10)
		body.add_child(rrow)
		rrow.add_child(UI.button("▶ Xem lại trận", _watch, 19, 200))
		var sv := UI.button("Lưu trận", func(): pass, 19, 150)
		sv.pressed.connect(_save_replay.bind(sv))
		if Replay.last.has("saved_id"):
			sv.text = "Đã lưu"
			sv.disabled = true
		rrow.add_child(sv)
	var rw: Dictionary = out.get("rewards", {})
	var rp := UI.panel(Color(0.08, 0.05, 0.04, 0.85))
	var rv := UI.vbox(6)
	rp.add_child(rv)
	rv.add_child(UI.label("Phần thưởng", 22, UI.GOLD, UI.bold))
	var wrow := UI.hbox(22)
	rv.add_child(wrow)
	wrow.add_child(UI.label(L.f("Kinh nghiệm +%d", int(rw.get("exp", 0))), 22))
	if int(rw.get("gold", 0)) > 0:
		wrow.add_child(UI.label(L.f("Vàng +%d", int(rw.gold)), 22, UI.GOLD))
	if int(rw.get("jade", 0)) > 0:
		wrow.add_child(UI.label(L.f("Ngọc +%d", int(rw.jade)), 22, Color(0.5, 1.0, 0.8)))
	if rw.get("buff", false):
		rv.add_child(UI.label(L.f("Đã gồm +%d%% của Đệ Nhất Môn Phái", int(MonPhai.BUFF * 100)), 17, Color(0.6, 1.0, 0.65)))
	if out.has("mp") and MonPhai.unlocked(h):
		var got := int(out.mp)
		var mtxt := L.f("Môn phái +%d công trạng  (hôm nay %d/%d)", [got, MonPhai.today(h), MonPhai.DAY_CAP]) if got > 0 \
			else L.f("Đã đủ %d công trạng hôm nay cho môn phái", MonPhai.DAY_CAP)
		rv.add_child(UI.label(mtxt, 18, Hero.sect(h).elem.lightened(0.2) if got > 0 else Color(0.8, 0.75, 0.7), UI.bold))
	if out.has("taught"):
		var tm := Insight.skill_of(str(out.taught[0]))
		var tl := UI.label(L.f("Cao nhân truyền thụ: %s +%d điểm lĩnh ngộ", [str(tm.get("name", "")), int(out.taught[1])]), 20, Color(0.6, 0.85, 1.0), UI.bold)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(tl)
	var mats: Dictionary = rw.get("mats", {})
	if not mats.is_empty():
		var mrow := HFlowContainer.new()
		mrow.add_theme_constant_override("h_separation", 18)
		mrow.add_child(UI.label("Nguyên liệu:", 21, Color(0.85, 0.82, 0.75)))
		for id in Mats.IDS:
			if int(mats.get(id, 0)) > 0:
				var c := UI.hbox(6)
				c.add_child(Mats.gem(id, 30))
				c.add_child(UI.label(L.f("%s +%d", [Mats.name_of(id), int(mats[id])]), 21, Mats.color(id), UI.bold))
				mrow.add_child(c)
		rv.add_child(mrow)
	if out.has("drop"):
		var it: Dictionary = out.drop
		var l := UI.label(L.f("Chiến lợi phẩm: %s (%s)", [Items.item_name(it, s.style), Items.RARITY[int(it.rar)]]), 22, Items.RARITY_COL[int(it.rar)], UI.bold)
		rv.add_child(l)
		if out.get("worn", false):
			rv.add_child(UI.label("Đã tự mặc vào — lực chiến tăng!", 19, Color(0.6, 1.0, 0.6)))
	if out.has("book"):
		rv.add_child(UI.label(L.f("%s: %s", [Books.name_of(out.book), Books.KINDS[out.book][1]]), 21, Books.COLOR[out.book], UI.bold))
	var gained: Dictionary = res.get("insight", {})
	if not gained.is_empty() and res.has("learned"):
		var parts := []
		for k in gained:
			var m := Insight.skill_of(k)
			if not m.is_empty():
				parts.append(L.f("%s +%d", [m.name, mini(int(gained[k]), Insight.PER_FIGHT)]))
		var il := UI.label(L.f("Lĩnh ngộ: %s", ", ".join(parts)), 19, Color(0.75, 0.85, 1.0))
		il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(il)
	for l in res.get("learned", []):
		var lm := Insight.skill_of(str(l[0]))
		var ls := Sects.get_sect(Insight.parse(str(l[0]))[0])
		var txt := ("Ngộ ra chiêu mới: %s (%s)!" if int(l[1]) == 1 else "%s (%s) đột phá tầng %d!") 
		var ll := UI.label(L.f(txt, [lm.name, ls.name]) if int(l[1]) == 1 else L.f(txt, [lm.name, ls.name, int(l[1])]), 22, Color(0.55, 0.85, 1.0), UI.bold)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(ll)
	if out.has("unlocked_sect"):
		var us := UI.label(L.f("Phái ẩn %s đã mở! Tạo nhân vật mới để bái sư.", Sects.get_sect(str(out.unlocked_sect)).name), 22, Color(0.5, 0.75, 1.0), UI.bold)
		us.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(us)
	if out.get("kn_new", false):
		var kc := KyNgo.current(h)
		if not kc.is_empty():
			var kl := UI.label(L.f("✦ Kỳ ngộ! %s xuất hiện ở %s — mở Hành Tẩu để gặp.", [KyNgo.title(str(kc.kind)), KyNgo.region_name(kc)]), 21, Color(0.6, 0.9, 1.0), UI.bold)
			kl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			rv.add_child(kl)
	body.add_child(rp)
	# rewarded ad: double the experience and gold of a won fight
	if out.get("doubled", "") != "":
		var dl := UI.label(str(out.doubled), 19, Color(0.6, 1.0, 0.6))
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rp.get_child(0).add_child(dl)
	elif (out.won or out.mode == "wboss") and (int(rw.get("exp", 0)) > 0 or int(rw.get("gold", 0)) > 0):
		var dbl := UI.gold_button("▶ Xem quảng cáo: x2 kinh nghiệm & vàng", func(): pass, 19)
		dbl.disabled = not Ads.is_ready()
		dbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dbl.pressed.connect(_double.bind(dbl, rw))
		Ads.ready_changed.connect(func():
			if is_instance_valid(dbl) and dbl.text.begins_with("▶"):
				dbl.disabled = not Ads.is_ready())
		rp.get_child(0).add_child(dbl)
	if int(out.get("levels", 0)) > 0:
		var lv := UI.label(L.f("Thăng cấp! Đạt cấp %d  (+%d điểm tiềm năng, +%d điểm võ công)", [int(h.level), int(out.levels) * Build.POINTS_PER_LEVEL, int(out.levels)]), 22, Color(0.6, 1.0, 0.6), UI.bold)
		lv.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(lv)
		if not _again:
			Game.sfx("levelup")
	if out.has("unlock"):
		body.add_child(UI.label(L.f("Mở khóa vùng mới: %s", out.unlock), 22, UI.GOLD, UI.bold))
	if not out.won and out.mode == "stage":
		var tip_txt := "Mẹo: cộng điểm tiềm năng, nâng võ công, cường hóa trang bị hoặc lên Lôi Đài rèn luyện thêm."
		if int(out.r) == 0 and not out.get("nm", false):
			tip_txt = ["Mẹo: thấy đối thủ vung đòn thì kéo cần về phía SAU để đỡ, rồi phản công ngay.",
				"Mẹo: bấm Quyền liên tục để ra cả chuỗi combo, đừng bấm từng cái một.",
				"Mẹo: dùng chiêu thức (nút tím) khi Nội Lực đủ — sát thương lớn hơn đòn thường nhiều.",
				"Mẹo: thua vẫn được kinh nghiệm. Lên cấp rồi đấu lại sẽ dễ hơn."][int(h.losses) % 4]
		var tip := UI.label(tip_txt, 18, Color(0.85, 0.8, 0.7))
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(tip)
	for c in body.get_children() + rv.get_children():
		if c is Label:
			(c as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var row := UI.hbox(12)
	right.add_child(row)
	if out.mode == "stage":
		var nm: bool = out.get("nm", false)
		row.add_child(UI.button("Đấu lại", func(): Flow.start_any(out.r, out.s, nm), 24, 160))
		var next_ok: bool = out.won and out.s < 5
		if next_ok:
			row.add_child(UI.gold_button("Trận kế", func(): Flow.start_any(out.r, out.s + 1, nm), 24, 170))
		row.add_child(UI.button("Bản đồ", func():
			MapScreen.last_nm = nm
			Game.goto(MapScreen.new()), 24, 150))
	elif out.mode == "duel":
		row.add_child(UI.gold_button("Tỉ võ tiếp", func(): Game.goto(DuelScreen.new()), 24, 190))
		row.add_child(UI.button("Về sảnh", func(): Game.goto(HubScreen.new()), 24, 170))
	elif out.mode == "dungeon":
		if out.has("next_hp"):
			row.add_child(UI.gold_button("Ải kế", func(): Flow.start_dungeon(int(out.i), int(out.d), int(out.k) + 1, float(out.next_hp)), 24, 170))
		elif not out.won and Dungeon.left(h) > 0:
			row.add_child(UI.button("Thử lại", func(): Flow.start_dungeon(int(out.i), int(out.d)), 24, 160))
		row.add_child(UI.button("Về Phó Bản", func(): Game.goto(DungeonScreen.new(int(out.i))), 24, 190))
	elif out.mode == "wboss":
		if WBoss.left(h) > 0:
			row.add_child(UI.gold_button(L.f("Đánh tiếp (%d)", WBoss.left(h)), Flow.start_wboss, 24, 210))
		row.add_child(UI.button("Về Boss", func(): Game.goto(WBossScreen.new()), 24, 160))
	elif out.mode == "kyngo":
		if not out.won and int(out.get("tries_left", 0)) > 0:
			row.add_child(UI.gold_button("Đấu lại", Flow.start_kyngo, 24, 160))
		row.add_child(UI.button("Bản đồ", func():
			MapScreen.last_nm = false
			MapScreen.last_region = int(out.r)
			Game.goto(MapScreen.new()), 24, 150))
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
	if out.won and not _again:
		Game.sfx("coin")
	if not _again and not Game.autoplay:
		_perf_prompts()
	if Game.autoplay:
		print("FLOWTEST result: mode=%s won=%s stars=%s rewards=%s level=%d daily=%s" % [out.mode, out.won, out.get("stars", 0), out.get("rewards", {}), int(h.level), h.get("daily", {}).get("prog", {})])
		print("FLOWTEST 1.5: mp=%s mp_today=%d kn=%s replay=%s books=%s taught=%s" % [out.get("mp", "-"), MonPhai.today(h), h.get("kn", {}), not Replay.last.is_empty(), h.get("books", {}), out.get("taught", "-")])
		get_tree().create_timer(0.5).timeout.connect(get_tree().quit)

func back() -> void:
	Game.goto(HubScreen.new())

## After the screen is built: the fight still lagged at the lowest render
## scale (Perf) → offer Thấp, at most every 10 fights; otherwise a smooth won
## fight may ask for a Play review (Review.due).
func _perf_prompts() -> void:
	var res: Dictionary = out.get("res", {})
	var h := Game.hero
	if res.get("perf_low", false) and Gfx.level() > 0 \
			and int(h.get("fights", 0)) >= int(Game.settings.get("gfx_ask_after", 0)):
		Game.settings["gfx_ask_after"] = int(h.get("fights", 0)) + 10
		Game.save_settings()
		Funnel.device("f_gfx_ask")
		get_tree().create_timer(0.8).timeout.connect(func():
			confirm("Máy đang chạy chưa mượt. Chuyển đồ họa sang Thấp để trận đấu mượt hơn? (Đổi lại trong Cài đặt)", func():
				Game.settings["gfx"] = 0
				Gfx.set_level(0)
				Gfx.reset_scale(Game.settings)
				Game.save_settings()
				Gfx.apply(get_tree())
				Funnel.device("f_gfx_yes")
				toast("Đã chuyển đồ họa Thấp", Color(0.6, 1.0, 0.6)), "Chuyển Thấp"))
		return
	if out.won and Review.due(h):
		get_tree().create_timer(1.5).timeout.connect(Review.ask)

func _double(dbl: Button, rw: Dictionary) -> void:
	dbl.disabled = true
	var ok := Ads.show_rewarded(func(): _doubled(dbl, rw), Callable(), "x2")
	if not ok:
		dbl.disabled = false
		toast("Chưa có quảng cáo, thử lại sau", Color(1, 0.7, 0.5))

func _doubled(dbl: Button, rw: Dictionary) -> void:
	var extra := {"exp": int(rw.get("exp", 0)), "gold": int(rw.get("gold", 0))}
	var lv_up := Flow._grant(extra, false)
	Game.save()
	refresh_wallet()
	out["doubled"] = L.f("Đã nhân đôi: +%d kinh nghiệm, +%d vàng", [extra.exp, extra.gold])
	if is_instance_valid(dbl):
		dbl.text = out.doubled
	if lv_up > 0:
		toast(L.f("Thăng cấp! Đạt cấp %d", int(Game.hero.level)), Color(0.6, 1.0, 0.6))

## Xem lại trận: watch the fight just played, then come back to this summary.
func _watch() -> void:
	var o := out
	Flow.watch(Replay.last, func(_res: Dictionary): Game.goto(ResultScreen.new(o)))

func _save_replay(b: Button) -> void:
	if Replay.save(Replay.last):
		b.text = "Đã lưu"
		b.disabled = true
		toast(L.f("Đã lưu — xem ở «Trận Đã Lưu» ngoài sảnh (%d/%d)", [Replay.count(), Replay.KEEP]), Color(0.6, 1, 0.7))
	else:
		toast(L.f("Kho đã đủ %d trận — xóa bớt ở «Trận Đã Lưu» ngoài sảnh", Replay.KEEP), Color(1, 0.7, 0.5))

func _revive() -> void:
	if not Ads.show_rewarded(func(): Flow.start_arena(int(out.n), true), Callable(), "arena"):
		toast("Chưa có quảng cáo, thử lại sau", Color(1, 0.7, 0.5))

## Leaving for a menu (not straight into the next fight or its story
## dialogue, and not quitting) may show an interstitial.
func _exit_tree() -> void:
	var nxt = Game._current
	if nxt == self or nxt == null or not is_instance_valid(nxt):
		return
	if nxt is FightScene or nxt is DialogScreen:
		return
	Ads.maybe_interstitial()
