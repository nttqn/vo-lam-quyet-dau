class_name DialogScreen
extends Screen
## Story dialogue over the region's scene: hero on the left, the speaker
## opposite. Tap to advance (a tap while the line is still typing shows it all).

var r: int
var part: String
var foe: Dictionary       # side of the opponent (boss lines), or {}
var on_done: Callable
var _lines: Array
var _i := -1
var _name: Label
var _text: Label
var _shown := 0.0

func _init(p_r: int, p_part: String, p_foe: Dictionary, p_done: Callable) -> void:
	r = p_r
	part = p_part
	foe = p_foe
	on_done = p_done
	_lines = Story.lines(r, part)

func _ready() -> void:
	var h := Game.hero
	_init_ui(Journey.REGIONS[r].theme)
	show.add_body(Hero.look(h), Hero.sect(h).style, -1.3, -0.3)
	if not foe.is_empty():
		show.add_body(foe.look, Sects.get_sect(foe.sect).style, 1.3, PI + 0.3)
	show.set_focus(0.0)
	var top := UI.label(Journey.REGIONS[r].name, 30, UI.GOLD, UI.title)
	top.position = Vector2(28, 20)
	top.add_theme_color_override("font_outline_color", Color.BLACK)
	top.add_theme_constant_override("outline_size", 8)
	ui.add_child(top)
	var skip := UI.button("Bỏ qua ›", _finish, 20, 140)
	skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip.offset_left = -164
	skip.offset_right = -24
	skip.offset_top = 18
	skip.offset_bottom = 70
	ui.add_child(skip)
	var band := UI.panel(Color(0.04, 0.03, 0.04, 0.88))
	band.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_left = 24
	band.offset_right = -24
	band.offset_top = -190
	band.offset_bottom = -20
	ui.add_child(band)
	var v := UI.vbox(6)
	band.add_child(v)
	_name = UI.label("", 26, UI.GOLD, UI.title)
	v.add_child(_name)
	_text = UI.label("", 24, UI.PAPER)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.y = 96
	v.add_child(_text)
	var hint := UI.label("Chạm để tiếp tục", 15, Color(0.7, 0.68, 0.62))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(hint)
	# whole screen (under the skip button) advances the dialogue
	var tap := Button.new()
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap.pressed.connect(_next)
	ui.add_child(tap)
	ui.move_child(tap, skip.get_index())
	_next()

func _speaker(who: String) -> String:
	match who:
		"": return ""
		"@": return str(Game.hero.name)
		"boss": return "%s — %s" % [foe.get("name", "?"), foe.get("title", "")] if not foe.is_empty() else "?"
	return who

func _next() -> void:
	if _i >= 0 and _shown < float(String(_lines[_i][1]).length()):
		_shown = 1e9   # finish the line first
		return
	_i += 1
	if _i >= _lines.size():
		_finish()
		return
	var ln: Array = _lines[_i]
	_name.text = _speaker(ln[0])
	_name.add_theme_color_override("font_color", UI.GOLD if ln[0] != "" else Color(0.75, 0.85, 1.0))
	_text.text = ln[1]
	_text.add_theme_color_override("font_color", UI.PAPER if ln[0] != "" else Color(0.85, 0.88, 0.95))
	_shown = 0.0
	_text.visible_characters = 0
	Game.sfx("click", 0.02)

func _process(delta: float) -> void:
	if _i >= 0 and _i < _lines.size():
		_shown += delta * 45.0
		_text.visible_characters = int(_shown)

func _finish() -> void:
	if not on_done.is_valid():
		return
	Story.mark(Game.hero, r, part)
	Game.save()
	var cb := on_done
	on_done = Callable()
	cb.call()

func back() -> void:
	_finish()
