class_name Hud
extends Control
## Fight HUD: health/energy bars, timer, round pips, combo counters, banners.

var sim: FightSim
var names := ["", ""]
var levels := [1, 1]
var _ghost := [1.0, 1.0]    # delayed damage bar
var _combo := [0, 0]
var _combo_t := [0.0, 0.0]
var _banner := ""
var _banner_sub := ""
var _banner_t := 0.0
var _banner_col := UI.GOLD
var _skill_name := ["", ""]
var _skill_t := [0.0, 0.0]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.init_fonts()

func banner(t: String, sub := "", dur := 1.4, col := UI.GOLD) -> void:
	_banner = t
	_banner_sub = sub
	_banner_t = dur
	_banner_col = col

func combo(i: int, n: int) -> void:
	_combo[i] = n
	_combo_t[i] = 1.3

func skill(i: int, n: String) -> void:
	_skill_name[i] = n
	_skill_t[i] = 1.4

func _process(delta: float) -> void:
	if sim == null:
		return
	for i in 2:
		var f: Fighter = sim.f[i]
		var r: float = f.hp / f.st.hp_max
		if _ghost[i] > r:
			_ghost[i] = maxf(r, _ghost[i] - delta * 0.35)
		else:
			_ghost[i] = r
		_combo_t[i] -= delta
		_skill_t[i] -= delta
	_banner_t -= delta
	queue_redraw()

func _text(pos: Vector2, s: String, fs: int, col: Color, font: Font = null, align := 0, outline := 5) -> void:
	var fnt := font if font else UI.bold
	var w := fnt.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := pos
	if align == 1:
		p.x -= w * 0.5
	elif align == 2:
		p.x -= w
	if outline > 0:
		draw_string_outline(fnt, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, Color(0, 0, 0, 0.75))
	draw_string(fnt, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

func _draw() -> void:
	if sim == null:
		return
	var W := size.x
	var bw := minf(480.0, W * 0.36)
	var top := 22.0
	for i in 2:
		var f: Fighter = sim.f[i]
		var left := i == 0
		var x0 := 24.0 if left else W - 24.0 - bw
		# frame
		draw_rect(Rect2(x0 - 4, top - 4, bw + 8, 34), Color(0, 0, 0, 0.55))
		var r: float = clampf(f.hp / f.st.hp_max, 0.0, 1.0)
		var g: float = _ghost[i]
		var gx := x0 if left else x0 + bw * (1.0 - g)
		var hx := x0 if left else x0 + bw * (1.0 - r)
		draw_rect(Rect2(gx, top, bw * g, 26), Color(1, 0.9, 0.7, 0.85))
		var hp_col := Color(0.85, 0.15, 0.1).lerp(Color(0.95, 0.75, 0.15), clampf((r - 0.25) * 2.0, 0.0, 1.0))
		draw_rect(Rect2(hx, top, bw * r, 26), hp_col)
		draw_rect(Rect2(hx, top, bw * r, 8), Color(1, 1, 1, 0.22))
		draw_rect(Rect2(x0 - 4, top - 4, bw + 8, 34), UI.GOLD, false, 2.0)
		if f.poison_t > 0:
			draw_rect(Rect2(x0, top + 20, bw, 6), Color(0.3, 0.9, 0.2, 0.7))
		# energy (nội lực)
		var ew := bw * 0.62
		var ex := x0 if left else x0 + bw - ew
		draw_rect(Rect2(ex, top + 36, ew, 12), Color(0, 0, 0, 0.6))
		var e: float = f.en / Fighter.EN_MAX
		var exx := ex if left else ex + ew * (1.0 - e)
		var ecol := Color(0.25, 0.55, 1.0) if e < 1.0 else Color(0.5, 0.85, 1.0).lerp(Color.WHITE, 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01))
		draw_rect(Rect2(exx, top + 36, ew * e, 12), ecol)
		for q in [0.25, 0.5, 0.75]:
			var qx: float = ex + ew * q
			draw_line(Vector2(qx, top + 36), Vector2(qx, top + 48), Color(0, 0, 0, 0.6), 2)
		draw_rect(Rect2(ex, top + 36, ew, 12), Color(0.6, 0.75, 1.0, 0.6), false, 1.5)
		# name + level
		var nm := "%s  ·  Cấp %d" % [names[i], levels[i]]
		_text(Vector2(x0 if left else x0 + bw, top + 72), nm, 20, UI.PAPER, null, 0 if left else 2)
		# round pips
		for k in sim.rounds_to_win:
			var px := (x0 + bw - 14 - k * 26) if left else (x0 + 14 + k * 26)
			var c := Vector2(px, top + 60)
			draw_circle(c, 9, Color(0, 0, 0, 0.6))
			if sim.wins[i] > k:
				draw_circle(c, 7, UI.GOLD)
			draw_arc(c, 9, 0, TAU, 20, UI.GOLD_D, 2.0)
		# combo
		if _combo_t[i] > 0 and _combo[i] >= 2:
			var a := clampf(_combo_t[i] * 2.0, 0.0, 1.0)
			var cx := 60.0 if i == 1 else W - 60.0
			_text(Vector2(cx, 210), "%d" % _combo[i], 64, Color(1, 0.85, 0.3, a), UI.title, 1 if true else 0, 8)
			_text(Vector2(cx, 240), "LIÊN KÍCH", 20, Color(1, 1, 1, a), null, 1)
		if _skill_t[i] > 0:
			var a2 := clampf(_skill_t[i] * 2.0, 0.0, 1.0)
			var sx := 40.0 if left else W - 40.0
			var col: Color = f.sect.elem
			_text(Vector2(sx, 150), _skill_name[i], 34, Color(col.r, col.g, col.b, a2), UI.title, 0 if left else 2, 7)
	# timer
	var secs := int(ceil(sim.timer / 60.0))
	draw_circle(Vector2(W * 0.5, top + 22), 34, Color(0, 0, 0, 0.6))
	draw_arc(Vector2(W * 0.5, top + 22), 34, 0, TAU, 40, UI.GOLD, 2.5)
	_text(Vector2(W * 0.5, top + 36), str(maxi(0, secs)), 36, UI.PAPER if secs > 10 else Color(1, 0.4, 0.3), UI.title, 1)
	# banner
	if _banner_t > 0:
		var a3 := clampf(_banner_t * 3.0, 0.0, 1.0)
		var H := size.y
		draw_rect(Rect2(0, H * 0.36, W, H * 0.2), Color(0, 0, 0, 0.35 * a3))
		# zoom-in by transform, NOT by font size: every distinct font size builds
		# its own glyph cache that is never freed (~500 MB after a few fights)
		var sc := 1.0 + maxf(0.0, (_banner_t - 1.2)) * 0.8
		var c := Vector2(W * 0.5, H * 0.48)
		draw_set_transform(c * (1.0 - sc), 0.0, Vector2(sc, sc))
		_text(c, _banner, 86, Color(_banner_col.r, _banner_col.g, _banner_col.b, a3), UI.title, 1, 12)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if _banner_sub != "":
			_text(Vector2(W * 0.5, H * 0.54), _banner_sub, 26, Color(1, 1, 1, a3), null, 1)
