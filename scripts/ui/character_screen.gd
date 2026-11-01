class_name CharacterScreen
extends Screen
## Attribute points + derived stats.

var _box: VBoxContainer
const ATTR := [
	["luc", "Lực", "Tăng công lực đòn thường (Công)."],
	["than", "Thân pháp", "Tăng tốc độ di chuyển và tỉ lệ bạo kích."],
	["noi", "Nội công", "Tăng sát thương võ công, hồi nội lực, trị thương."],
	["the", "Thể chất", "Tăng sinh lực và phòng thủ."],
]
const RESET_COST := 10

func _ready() -> void:
	_init_ui("temple")
	var h := Game.hero
	show.set_focus(1.6)
	show.add_body(Hero.look(h), Hero.sect(h).style, 0.2, -0.6)
	shade(false, 0.62, 0.9)
	top_bar("Nhân Vật", back)
	_box = UI.vbox(10)
	_box.anchor_left = 1.0
	_box.anchor_right = 1.0
	_box.anchor_bottom = 1.0
	_box.offset_left = -620
	_box.offset_right = -30
	_box.offset_top = 96
	_box.offset_bottom = -20
	ui.add_child(_box)
	_build()

func _build() -> void:
	for c in _box.get_children():
		c.queue_free()
	var h := Game.hero
	var s := Hero.sect(h)
	var a := Build.attrs(int(h.level), h.pts, s)
	var free := int(h.free_pts)
	_box.add_child(UI.label("Điểm tiềm năng: %d" % free, 26, Color(0.6, 1, 0.6) if free > 0 else UI.PAPER, UI.bold))
	for at in ATTR:
		var row := UI.hbox(10)
		var name := UI.label(at[1], 24, UI.GOLD, UI.bold)
		name.custom_minimum_size.x = 150
		row.add_child(name)
		var val := UI.label(str(a[at[0]]), 26, UI.PAPER, UI.bold)
		val.custom_minimum_size.x = 50
		row.add_child(val)
		var d := UI.label(at[2], 16, Color(0.8, 0.77, 0.7))
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(d)
		var k: String = at[0]
		var b1 := UI.button("+1", func(): _add(k, 1), 22)
		b1.disabled = free <= 0
		b1.custom_minimum_size = Vector2(64, 52)
		row.add_child(b1)
		var b5 := UI.button("+5", func(): _add(k, 5), 22)
		b5.disabled = free < 5
		b5.custom_minimum_size = Vector2(64, 52)
		row.add_child(b5)
		_box.add_child(row)
	var st := Hero.stats(h)
	var p := UI.panel(Color(0.07, 0.05, 0.05, 0.85))
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 26)
	p.add_child(g)
	var rows := [
		["Sinh lực", UI.fmt(st.hp_max)], ["Công", UI.fmt(st.atk)],
		["Phòng thủ", UI.fmt(st.def)], ["Nội công", UI.fmt(st.qi)],
		["Tốc độ", "%d%%" % int(st.spd * 100)], ["Bạo kích", "%.1f%%" % (st.crit * 100)],
		["Hồi nội lực", "%d%%" % int(st.en_gain * 100)], ["Lực chiến", UI.fmt(Build.power(st))],
	]
	for r in rows:
		g.add_child(UI.label(r[0], 20, Color(0.82, 0.78, 0.7)))
		g.add_child(UI.label(r[1], 22, UI.PAPER, UI.bold))
	_box.add_child(p)
	var stats_l := UI.label("Thắng %d  ·  Thua %d  ·  Lôi đài kỷ lục %d" % [int(h.wins), int(h.losses), int(h.arena_best)], 18, Color(0.8, 0.77, 0.7))
	_box.add_child(stats_l)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(sp)
	var rb := UI.button("Tẩy điểm (%d Ngọc)" % RESET_COST, func(): confirm("Hoàn lại toàn bộ điểm tiềm năng với giá %d Ngọc?" % RESET_COST, _reset), 20)
	rb.disabled = int(h.jade) < RESET_COST
	_box.add_child(rb)

func _add(k: String, n: int) -> void:
	var h := Game.hero
	n = mini(n, int(h.free_pts))
	if n <= 0:
		return
	h.pts[k] = int(h.pts[k]) + n
	h.free_pts = int(h.free_pts) - n
	Game.save()
	_build()

func _reset() -> void:
	var h := Game.hero
	var total := 0
	for k in h.pts:
		total += int(h.pts[k])
		h.pts[k] = 0
	h.free_pts = int(h.free_pts) + total
	h.jade = int(h.jade) - RESET_COST
	Game.save()
	refresh_wallet()
	_build()

func back() -> void:
	Game.goto(HubScreen.new())
