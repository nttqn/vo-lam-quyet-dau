class_name TowerScreen
extends Screen
## Tháp Thí Luyện: the next floor's guardian, its rule and reward, milestones.

func _ready() -> void:
	var h := Game.hero
	var f := Tower.best(h) + 1
	_init_ui("snow")
	shade(false, 0.6, 0.85)
	top_bar("Tháp Thí Luyện", back)
	var foe := Tower.side(f)
	show.add_body(foe.look, Sects.get_sect(foe.sect).style, -1.4, -0.9)
	show.set_focus(-0.6)
	var card := UI.panel(Color(0.06, 0.05, 0.07, 0.86))
	card.anchor_left = 1.0
	card.anchor_right = 1.0
	card.anchor_bottom = 1.0
	card.offset_left = -580
	card.offset_right = -24
	card.offset_top = 92
	card.offset_bottom = -20
	ui.add_child(card)
	var right := UI.vbox(10)
	card.add_child(right)
	right.add_child(UI.heading("Tầng %d" % f, 64))
	var fl := UI.label("%s  ·  %s  ·  Cấp %d" % [foe.name, Sects.get_sect(foe.sect).name, int(foe.level)], 21, UI.PAPER, UI.bold)
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(fl)
	var r := Tower.rule(f)
	if Tower.is_boss(f):
		right.add_child(UI.label("Thủ tháp: đối thủ mạnh, thưởng trang bị quý.", 19, Color(1, 0.6, 0.35), UI.bold))
	if r != "":
		var rp := UI.panel(Color(0.1, 0.06, 0.12, 0.9), Color(0.75, 0.5, 1.0))
		var rv := UI.vbox(2)
		rp.add_child(rv)
		rv.add_child(UI.label("Luật tầng: " + Tower.RULES[r][0], 20, Color(0.85, 0.7, 1.0), UI.bold))
		var d := UI.label(Tower.RULES[r][1], 18)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(d)
		right.add_child(rp)
	var rw := Tower.reward(f)
	var parts := ["Vàng +%d" % int(rw.gold), "KN +%d" % int(rw.exp)]
	if int(rw.jade) > 0:
		parts.append("Ngọc +%d" % int(rw.jade))
	if int(rw.item) >= 0:
		parts.append("Trang bị %s" % Items.RARITY[int(rw.item)])
	var rl := UI.label("Thưởng vượt tầng: " + "  ·  ".join(parts), 19, UI.GOLD)
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(rl)
	right.add_child(UI.label("Lực chiến của bạn: %d   ·   Đối thủ: %d" % [Hero.power(h), Build.power(foe.stats)], 18, Color(0.85, 0.82, 0.75)))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(sp)
	var hl := UI.label("Cao nhất đã vượt: tầng %d.  Cứ 5 tầng thưởng Ngọc, 10 tầng gặp Thủ Tháp." % Tower.best(h), 17, Color(0.8, 0.78, 0.72))
	hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(hl)
	var go := UI.gold_button("Khiêu Chiến", func(): Flow.start_tower(f), 30)
	go.custom_minimum_size.y = 76
	right.add_child(go)

func back() -> void:
	Game.goto(HubScreen.new())
