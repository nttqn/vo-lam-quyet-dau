class_name ProfilePanel
extends Control
## Another player's card, opened from a rank row or a chat message: name,
## title, boards, and (when they have a Tỉ Võ shadow this season) their
## stats, skills and weapon plus "Đấu thử", a friendly duel with no rewards.
## r: a rank row ({_id: uid_slot, name, sect, level, power, tower, stars,
## title}) or a chat message ({uid, name, sect, level}).
## Costs at most 2 reads: the rank row (chat only) and the Tỉ Võ doc.

var r: Dictionary
var back_to: Callable
var _v: VBoxContainer
var _body: VBoxContainer
var _status: Label
var _spar: Button
var _shadow := {}
static var fake_duel := {}   # test hook (--screen=profile)

func _init(p_r: Dictionary, p_back: Callable) -> void:
	r = p_r.duplicate()
	back_to = p_back

func _ready() -> void:
	add_to_group("modal")   # Android back closes it
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			queue_free())
	add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	var p := UI.panel()
	c.add_child(p)
	_v = UI.vbox(10)
	_v.custom_minimum_size = Vector2(760, 0)
	p.add_child(_v)
	_body = UI.vbox(8)
	_v.add_child(_body)
	_status = UI.label("", 18, Color(0.75, 0.72, 0.66))
	_v.add_child(_status)
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_v.add_child(row)
	_spar = UI.gold_button("Đấu thử", _do_spar, 22, 200)
	_spar.visible = false
	row.add_child(_spar)
	row.add_child(UI.button("Đóng", queue_free, 22, 160))
	_render()
	_load()

func _uid() -> String:
	if r.has("uid"):
		return str(r.uid)
	var id := str(r.get("_id", ""))
	var k := id.rfind("_")
	return id.substr(0, k) if k > 0 else ""

func _mine() -> bool:
	return _uid() != "" and _uid() == Cloud.uid

func _render() -> void:
	for c in _body.get_children():
		c.queue_free()
	var head := UI.hbox(14)
	_body.add_child(head)
	var nm := UI.heading(Chat.safe_name(r.get("name", "?")), 40)
	nm.clip_text = true
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nm)
	var tid := str(r.get("title", ""))
	if Titles.LIST.has(tid):
		head.add_child(UI.label(L.f("« %s »", Titles.name_of(tid)), 22, Titles.color(tid), UI.bold))
	var sect := Sects.get_sect(str(r.get("sect", "vo_dang")))
	_body.add_child(UI.label(L.f("%s  ·  Cấp %d", [sect.name, int(r.get("level", 1))]), 22, UI.PAPER, UI.bold))
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 28)
	_body.add_child(g)
	var cells := []
	if r.has("power"):
		cells.append(["Lực chiến", UI.fmt(int(r.power))])
		cells.append(["Tháp", L.f("Tầng %d", int(r.get("tower", 0)))])
		cells.append(["Giang Hồ", "★ %d" % int(r.get("stars", 0))])
	if not _shadow.is_empty():
		cells.append(["Tỉ Võ", L.f("%d (%s)", [int(_shadow.get("score", Duel.START)), Duel.tier(int(_shadow.get("score", Duel.START)))[0]])])
	for cl in cells:
		g.add_child(UI.label(cl[0], 18, Color(0.8, 0.77, 0.7)))
		g.add_child(UI.label(cl[1], 20, UI.GOLD, UI.bold))
	if _shadow.is_empty():
		return
	var snap = JSON.parse_string(str(_shadow.get("data", "")))
	if not snap is Dictionary:
		return
	var st: Dictionary = snap.get("stats", {})
	var sg := GridContainer.new()
	sg.columns = 6
	sg.add_theme_constant_override("h_separation", 20)
	var sp := UI.panel(Color(0.07, 0.05, 0.05, 0.85))
	sp.add_child(sg)
	_body.add_child(sp)
	for s2 in [["Sinh lực", UI.fmt(float(st.get("hp_max", 0)))], ["Công", UI.fmt(float(st.get("atk", 0)))], ["Phòng", UI.fmt(float(st.get("def", 0)))],
			["Nội công", UI.fmt(float(st.get("qi", 0)))], ["Tốc độ", "%d%%" % int(float(st.get("spd", 1)) * 100)], ["Bạo kích", "%.1f%%" % (float(st.get("crit", 0)) * 100)]]:
		sg.add_child(UI.label(s2[0], 16, Color(0.8, 0.77, 0.7)))
		sg.add_child(UI.label(s2[1], 18, UI.PAPER, UI.bold))
	var sk_names := []
	var skills: Array = Sects.get_sect(str(snap.get("sect", r.get("sect", "vo_dang")))).skills
	for e in snap.get("skills", []):
		var i := int(e[0])
		if i >= 0 and i < skills.size():
			sk_names.append(L.f("%s (tầng %d)", [skills[i].name, int(e[1])]))
	var ult: Array = snap.get("ult", [])
	if ult.size() > 0:
		sk_names.append(L.f("Tuyệt kỹ %s (tầng %d)", [skills[Hero.ULT].name, int(ult[0])]))
	if not sk_names.is_empty():
		var l := UI.label(L.f("Võ công: %s", ", ".join(sk_names)), 17, Color(0.88, 0.85, 0.78))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(l)
	var wr := int(snap.get("wrar", 0))
	_body.add_child(UI.label(L.f("Binh khí: bậc %d · %s · +%d", [int(snap.get("wtier", 1)), Items.RARITY[clampi(wr, 0, Items.RARITY.size() - 1)], int(snap.get("wplus", 0))]), 17, Items.RARITY_COL[clampi(wr, 0, Items.RARITY_COL.size() - 1)]))

func _load() -> void:
	var uid := _uid()
	if not fake_duel.is_empty():
		_shadow = fake_duel
		_after_load()
		return
	if uid == "" or not Cloud.enabled():
		_status.text = "" if Cloud.enabled() else "Cần kết nối mạng để xem thêm."
		return
	_status.text = "Đang tải…"
	# from chat: find their rank row by name, keep the one that is theirs
	if not r.has("power"):
		var rows: Array = await Cloud.find_eq(Ranks.COLLECTION, "name", str(r.get("name", "")), 6)
		if not is_inside_tree():
			return
		for row in rows:
			if str(row.get("_id", "")).begins_with(uid + "_"):
				for k in row:
					r[k] = row[k]
				break
	var doc := await Cloud.get_doc(Duel.collection() + "/" + uid)
	if not is_inside_tree():
		return
	# the account's Tỉ Võ shadow is its last-played hero: only if it is this one
	if not doc.is_empty() and Build.shadow_ok(doc) and str(doc.get("name", "")) == str(r.get("name", "")) and str(doc.get("sect", "")) == str(r.get("sect", "")):
		_shadow = doc
	_after_load()

func _after_load() -> void:
	_status.text = "" if not _shadow.is_empty() else "Chưa vào Tỉ Võ tuần này: chưa xem được võ công và chưa đấu thử được."
	_spar.visible = not _shadow.is_empty() and not _mine() and not Game.hero.is_empty()
	_render()

func _do_spar() -> void:
	var side := Duel.side(_shadow)
	if side.is_empty():
		_status.text = "Không đọc được dữ liệu người chơi này."
		return
	side.ai = Duel.AI
	Flow.start_spar(side, back_to)
