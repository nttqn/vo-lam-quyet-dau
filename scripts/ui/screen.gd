class_name Screen
extends Node
## Base for menu screens: optional 3D showcase + themed UI root.

var show: Showcase
var ui: Control
var layer: CanvasLayer

func _init_ui(theme_3d := "") -> void:
	if theme_3d != "":
		show = Showcase.new(theme_3d)
		add_child(show)
	layer = CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.theme = UI.theme()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	if show:
		ui.add_child(UI.vignette(0.45))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()

func back() -> void:
	pass

## Gradient shade so text stays readable over the 3D scene.
func shade(left: bool, width := 0.55, alpha := 0.82) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.05, 0.03, 0.04, alpha))
	g.set_color(1, Color(0.05, 0.03, 0.04, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0 if left else 1, 0.5)
	gt.fill_to = Vector2(1 if left else 0, 0.5)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if left:
		tr.anchor_left = 0.0
		tr.anchor_right = width
	else:
		tr.anchor_left = 1.0 - width
		tr.anchor_right = 1.0
	tr.anchor_top = 0.0
	tr.anchor_bottom = 1.0
	ui.add_child(tr)

func toast(msg: String, col := UI.GOLD) -> void:
	var l := UI.label(msg, 26, col, UI.bold)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	l.offset_top = 90
	l.offset_left = -400
	l.offset_right = 400
	ui.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "offset_top", 70.0, 0.25)
	tw.tween_interval(1.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)

## Modal confirm dialog.
func confirm(text: String, yes: Callable, yes_text := "Đồng ý") -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(c)
	var p := UI.panel()
	c.add_child(p)
	var v := UI.vbox(18)
	p.add_child(v)
	var l := UI.label(text, 26)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 520
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var h := UI.hbox(16)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	h.add_child(UI.button("Hủy", func(): dim.queue_free(), 24, 180))
	h.add_child(UI.gold_button(yes_text, func():
		dim.queue_free()
		yes.call(), 24, 200))

func top_bar(title: String, on_back: Callable) -> HBoxContainer:
	var bar := UI.hbox(14)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 20
	bar.offset_right = -20
	bar.offset_top = 14
	bar.offset_bottom = 74
	ui.add_child(bar)
	var b := UI.button("‹ Quay lại", on_back, 22)
	b.custom_minimum_size = Vector2(150, 56)
	bar.add_child(b)
	var h := UI.heading(title, 40)
	bar.add_child(h)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(sp)
	if not Game.hero.is_empty():
		var g := UI.label("Vàng %s   ·   Ngọc %d" % [UI.fmt(Game.hero.gold), int(Game.hero.jade)], 22, UI.GOLD, UI.bold)
		g.name = "Wallet"
		bar.add_child(g)
	return bar

func refresh_wallet() -> void:
	var w := ui.find_child("Wallet", true, false) as Label
	if w:
		w.text = "Vàng %s   ·   Ngọc %d" % [UI.fmt(Game.hero.gold), int(Game.hero.jade)]
