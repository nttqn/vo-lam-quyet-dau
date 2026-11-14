class_name TouchPad
extends Control
## Multi-touch controls: floating joystick on the left, action buttons on
## the right. Also merges keyboard input for desktop testing.

var fighter: Fighter
var mx := 0
var up := false
var down := false
var _queue: Array[String] = []
var _stick_id := -1
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _btn_touch := {}     # touch index -> button id
var _pressed := {}       # button id -> highlight time
var _keys_prev := {}
var show_buttons := true

const STICK_R := 95.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.init_fonts()

func buttons() -> Array:
	var s := size
	var W := s.x
	var H := s.y
	var b := [
		{"id": "p", "c": Vector2(W - 150, H - 145), "r": 74.0, "t": "Quyền", "col": Color(0.75, 0.2, 0.15)},
		{"id": "k", "c": Vector2(W - 305, H - 98), "r": 60.0, "t": "Cước", "col": Color(0.7, 0.4, 0.12)},
		{"id": "d", "c": Vector2(W - 112, H - 315), "r": 52.0, "t": "Né", "col": Color(0.2, 0.45, 0.6)},
	]
	var sk_pos := [Vector2(W - 445, H - 82), Vector2(W - 345, H - 240), Vector2(W - 245, H - 345)]
	for i in 3:
		b.append({"id": "s%d" % (i + 1), "c": sk_pos[i], "r": 50.0 if i < 2 else 56.0, "t": "", "col": Color(0.35, 0.2, 0.5), "skill": i})
	# fixed ultimate slot (Tuyệt Kỹ), above the dodge button
	b.append({"id": "s4", "c": Vector2(W - 100, H - 452), "r": 58.0, "t": "", "col": Color(0.75, 0.55, 0.1), "skill": 3, "ult": true})
	return b

func pop_btn() -> String:
	if _queue.is_empty():
		return ""
	return _queue.pop_front()

func _press(id: String) -> void:
	_queue.append(id)
	_pressed[id] = 0.15
	if _queue.size() > 3:
		_queue.pop_front()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			var hit := _hit_button(e.position)
			if hit != "":
				_btn_touch[e.index] = hit
				_press(hit)
			elif e.position.x < size.x * 0.45 and e.position.y > size.y * 0.25 and _stick_id == -1:
				_stick_id = e.index
				_stick_origin = e.position
				_stick_pos = e.position
		else:
			if e.index == _stick_id:
				_stick_id = -1
			_btn_touch.erase(e.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _stick_id:
			_stick_pos = d.position
			var v := _stick_pos - _stick_origin
			if v.length() > STICK_R * 1.4:
				_stick_origin = _stick_pos - v.normalized() * STICK_R * 1.4

func _hit_button(p: Vector2) -> String:
	if not show_buttons:
		return ""
	for b in buttons():
		if p.distance_to(b.c) <= b.r * 1.12:
			return b.id
	return ""

func poll() -> Dictionary:
	# joystick
	var smx := 0
	var sup := false
	var sdown := false
	if _stick_id != -1:
		var v := (_stick_pos - _stick_origin) / STICK_R
		if v.x > 0.32: smx = 1
		elif v.x < -0.32: smx = -1
		sup = v.y < -0.6
		sdown = v.y > 0.5
	# keyboard
	var kmx := 0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): kmx -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): kmx += 1
	var kup := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_SPACE)
	var kdown := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	for pair in [[KEY_J, "p"], [KEY_K, "k"], [KEY_L, "d"], [KEY_U, "s1"], [KEY_I, "s2"], [KEY_O, "s3"], [KEY_P, "s4"]]:
		var now := Input.is_physical_key_pressed(pair[0])
		if now and not _keys_prev.get(pair[0], false):
			_press(pair[1])
		_keys_prev[pair[0]] = now
	mx = smx if smx != 0 else kmx
	up = sup or kup
	down = sdown or kdown
	return {"mx": mx, "up": up, "down": down, "btn": pop_btn()}

func _process(delta: float) -> void:
	for k in _pressed.keys():
		_pressed[k] -= delta
		if _pressed[k] <= 0:
			_pressed.erase(k)
	queue_redraw()

func _draw() -> void:
	# joystick
	if _stick_id != -1:
		draw_circle(_stick_origin, STICK_R, Color(0, 0, 0, 0.25))
		draw_arc(_stick_origin, STICK_R, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0, true)
		var v := (_stick_pos - _stick_origin).limit_length(STICK_R)
		draw_circle(_stick_origin + v, 42, Color(1, 1, 1, 0.45))
	else:
		var c := Vector2(170, size.y - 160)
		draw_arc(c, STICK_R, 0, TAU, 48, Color(1, 1, 1, 0.16), 3.0, true)
		draw_circle(c, 40, Color(1, 1, 1, 0.12))
	if not show_buttons:
		return
	for b in buttons():
		var col: Color = b.col
		var lit := _pressed.has(b.id)
		var c: Vector2 = b.c
		var r: float = b.r
		var txt: String = b.t
		var ready := true
		var frac := 0.0
		var cost_txt := ""
		if b.has("skill") and fighter:
			var i: int = b.skill
			if i >= fighter.skills.size() or fighter.skills[i] == null:
				draw_circle(c, r, Color(0, 0, 0, 0.2))
				draw_arc(c, r, 0, TAU, 40, Color(1, 1, 1, 0.15), 2.0, true)
				continue
			var m: Dictionary = fighter.skills[i]
			txt = _short(m.name)
			ready = fighter.skill_ready(i)
			var cd := int(fighter.cds.get(i, 0))
			if cd > 0:
				frac = float(cd) / float(maxi(1, m.cd))
			cost_txt = str(m.cost)
			if m.get("ult", false):
				col = Color(0.75, 0.55, 0.1)
			else:
				col = (fighter.sect.elem as Color).darkened(0.45)
		var a := 0.62 if ready else 0.3
		draw_circle(c, r, Color(col.r, col.g, col.b, a + (0.25 if lit else 0.0)))
		draw_arc(c, r, 0, TAU, 48, Color(1, 0.9, 0.6, 0.8 if ready else 0.3), 3.0, true)
		if frac > 0.0:
			var pts := PackedVector2Array([c])
			for k in 33:
				var ang := -PI * 0.5 + TAU * frac * k / 32.0
				pts.append(c + Vector2(cos(ang), sin(ang)) * r)
			draw_colored_polygon(pts, Color(0, 0, 0, 0.5))
		var fs := 24 if r > 60 else 18
		if b.has("skill"):
			fs = 15
		var lines := txt.split("\n")
		var y0 := c.y - (lines.size() - 1) * fs * 0.55 + fs * 0.35
		for li in lines.size():
			var ln: String = lines[li]
			var w := UI.bold.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string_outline(UI.bold, Vector2(c.x - w * 0.5, y0 + li * fs * 1.1), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.7))
			draw_string(UI.bold, Vector2(c.x - w * 0.5, y0 + li * fs * 1.1), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.95 if ready else 0.5))
		if cost_txt != "":
			var cw := UI.bold.get_string_size(cost_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_circle(c + Vector2(0, r - 4), 13, Color(0.15, 0.3, 0.7, 0.95))
			draw_string(UI.bold, c + Vector2(-cw * 0.5, r + 1), cost_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

static func _short(n: String) -> String:
	var w := n.split(" ")
	if w.size() <= 2:
		return n
	var half := int(ceil(w.size() / 2.0))
	return " ".join(w.slice(0, half)) + "\n" + " ".join(w.slice(half))
