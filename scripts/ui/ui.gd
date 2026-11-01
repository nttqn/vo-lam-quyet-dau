class_name UI
extends RefCounted
## Shared look: fonts, colours, styled widgets (lacquer red + gold + paper).

const RED := Color(0.55, 0.1, 0.08)
const RED_D := Color(0.3, 0.05, 0.04)
const GOLD := Color(0.93, 0.76, 0.36)
const GOLD_D := Color(0.6, 0.45, 0.18)
const PAPER := Color(0.96, 0.91, 0.8)
const INK := Color(0.12, 0.08, 0.06)
const DARK := Color(0.07, 0.06, 0.08, 0.92)

static var bold: Font
static var med: Font
static var title: Font

static func init_fonts() -> void:
	if bold:
		return
	bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf")
	med = load("res://assets/fonts/BeVietnamPro-Medium.ttf")
	var t := FontVariation.new()
	t.base_font = load("res://assets/fonts/PlayfairDisplay.ttf")
	t.variation_opentype = {"wght": 800}
	title = t

static func theme() -> Theme:
	init_fonts()
	var th := Theme.new()
	th.default_font = med
	th.default_font_size = 24
	th.set_color("font_color", "Label", PAPER)
	th.set_stylebox("normal", "Button", box(RED, GOLD_D, 2, 10))
	th.set_stylebox("hover", "Button", box(RED.lightened(0.12), GOLD, 2, 10))
	th.set_stylebox("pressed", "Button", box(RED_D, GOLD, 2, 10))
	th.set_stylebox("disabled", "Button", box(Color(0.25, 0.22, 0.22), Color(0.35, 0.32, 0.3), 2, 10))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_font("font", "Button", bold)
	th.set_font_size("font_size", "Button", 26)
	th.set_color("font_color", "Button", PAPER)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", GOLD)
	th.set_color("font_disabled_color", "Button", Color(0.55, 0.52, 0.5))
	th.set_stylebox("panel", "PanelContainer", box(DARK, GOLD_D, 2, 14))
	th.set_stylebox("panel", "Panel", box(DARK, GOLD_D, 2, 14))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.15)
	sb.set_corner_radius_all(4)
	th.set_stylebox("grabber_area", "VScrollBar", sb)
	th.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	return th

static func box(bg: Color, border: Color, bw := 2, r := 10, pad := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(r)
	s.content_margin_left = pad + 4
	s.content_margin_right = pad + 4
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 4
	return s

static func label(text: String, size := 24, col := PAPER, font: Font = null) -> Label:
	init_fonts()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if font:
		l.add_theme_font_override("font", font)
	return l

static func heading(text: String, size := 48) -> Label:
	init_fonts()
	var l := label(text, size, GOLD, title)
	l.add_theme_color_override("font_outline_color", RED_D)
	l.add_theme_constant_override("outline_size", 10)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_y", 4)
	return l

static func button(text: String, cb: Callable, size := 26, min_w := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	if min_w > 0:
		b.custom_minimum_size.x = min_w
	b.pressed.connect(func():
		Game.sfx("click")
		cb.call())
	return b

static func gold_button(text: String, cb: Callable, size := 28, min_w := 0) -> Button:
	var b := button(text, cb, size, min_w)
	b.add_theme_stylebox_override("normal", box(GOLD_D.darkened(0.1), GOLD, 3, 12))
	b.add_theme_stylebox_override("hover", box(GOLD_D, Color(1, 0.9, 0.6), 3, 12))
	b.add_theme_stylebox_override("pressed", box(GOLD_D.darkened(0.3), GOLD, 3, 12))
	b.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	return b

static func panel(bg := DARK, border := GOLD_D) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border, 2, 14, 16))
	return p

static func vbox(sep := 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep := 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func full(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c

static func backdrop(col_top := Color(0.16, 0.05, 0.05), col_bot := Color(0.04, 0.03, 0.05)) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, col_top)
	g.set_color(1, col_bot)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0)
	gt.fill_to = Vector2(0.5, 1)
	gt.width = 8
	gt.height = 256
	var tr := TextureRect.new()
	tr.texture = gt
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	full(tr)
	return tr

static func fmt(n: float) -> String:
	var s := str(int(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0 and s[i - 1] != "-":
			out = "." + out
	return out
