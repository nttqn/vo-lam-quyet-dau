class_name Tutorial
extends Control
## Trận nhập môn: the very first story duel teaches the controls one step at a
## time (1.3.0). The funnel showed a third of new players leaving before
## finishing a single fight, and the only help was a text box in the pause menu.
##
## While a lesson runs the foe stands still (or, in the block lesson, throws
## slow single punches), neither fighter can drop below a floor of HP and the
## round clock is frozen. After the last lesson the foe fights back at its
## stage AI, but the hero keeps a floor of HP, so the first duel is always won.
## Every lesson gives up after a while, so nobody is stuck; "Bỏ qua" ends it.
## Funnel device steps: f_tut1..f_tut5 (lesson reached), f_tut_done, f_tut_skip.

const LESSONS := [
	{"id": "move", "t": "Kéo cần điều khiển bên trái về phía đối thủ để tiến lại gần.", "hint": "stick", "max": 25.0},
	{"id": "punch", "t": "Bấm Quyền liên tục để tung cả chuỗi đòn.", "hint": "p", "need": 3, "max": 25.0},
	{"id": "kick", "t": "Cước đánh xa hơn Quyền. Bấm Cước trúng đối thủ.", "hint": "k", "need": 1, "max": 20.0},
	{"id": "block", "t": "Đối thủ sắp ra đòn! Kéo cần về phía SAU (xa đối thủ) để đỡ.", "hint": "back", "need": 2, "max": 30.0},
	{"id": "skill", "t": "Chiêu thức (nút tím) tốn Nội Lực nhưng rất mạnh. Dùng chiêu ngay!", "hint": "skill", "need": 1, "max": 20.0},
]
const FLOOR_LESSON := 0.6     # both fighters during the lessons
const FLOOR_FREE := 0.3       # the hero afterwards

var fs: FightScene
var step := -1                # -1 = waiting for "Đấu!", LESSONS.size() = done
var _t := 0.0                 # seconds in this lesson
var _count := 0
var _last_btn := ""
var _last_btn_f := -1000
var _frame := 0
var _box: PanelContainer
var _text: Label
var _num: Label
var _skip: Button
var _auto := false            # autoplay test run: lessons time out fast

func _init(p_fs: FightScene) -> void:
	fs = p_fs

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_auto = fs.ai_p != null
	_box = PanelContainer.new()
	_box.add_theme_stylebox_override("panel", UI.box(Color(0.08, 0.06, 0.05, 0.86), UI.GOLD, 3, 16, 18))
	_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_box.offset_left = -400
	_box.offset_right = 400
	_box.offset_top = 160
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.visible = false
	add_child(_box)
	var v := UI.vbox(6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(v)
	var top := UI.hbox(10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	_num = UI.label("", 20, UI.GOLD, UI.bold)
	_num.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_num)
	_skip = UI.button("Bỏ qua ›", _skip_all, 18, 130)
	top.add_child(_skip)
	_text = UI.label("", 27, Color(1, 0.96, 0.88), UI.bold)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(760, 0)
	v.add_child(_text)

func done() -> bool:
	return step >= LESSONS.size()

## Started once the fight phase begins (after the intro walk-in).
func _begin(i: int) -> void:
	step = i
	_t = 0.0
	_count = 0
	fs.pad.hint = ""
	if done():
		_box.visible = false
		fs.hud.banner("Hạ gục hắn!", "Dùng tất cả những gì vừa học", 1.6, UI.GOLD)
		Funnel.device("f_tut_done")
		return
	var l: Dictionary = LESSONS[i]
	_num.text = L.f("Nhập môn  %d / %d", [i + 1, LESSONS.size()])
	_text.text = l.t
	_box.visible = true
	_box.modulate.a = 0.0
	create_tween().tween_property(_box, "modulate:a", 1.0, 0.25)
	var hint: String = l.hint
	if hint == "skill":
		hint = "s%d" % (_skill_slot() + 1)
	fs.pad.hint = hint
	Funnel.device("f_tut%d" % (i + 1))
	Game.sfx("click")

func _skip_all() -> void:
	Funnel.device("f_tut_skip")
	_begin(LESSONS.size())

func _ok() -> void:
	Game.sfx("coin")
	_begin(step + 1)

## First skill slot holding a move (a new hero has one).
func _skill_slot() -> int:
	var f: Fighter = fs.sim.f[0]
	for i in mini(3, f.skills.size()):
		if f.skills[i] != null:
			return i
	return 0

## Enemy input for this frame (replaces the AI's while a lesson runs).
func enemy_input(ein: Dictionary) -> Dictionary:
	if done():
		return ein
	if step < 0 or str(LESSONS[step].id) != "block":
		return {}
	var me: Fighter = fs.sim.f[1]
	var him: Fighter = fs.sim.f[0]
	var dx := him.x - me.x
	if absf(dx) > 1.4:
		return {"mx": 1 if dx > 0 else -1}
	# one slow punch every ~1.5 s so the block can be read
	if _frame % 90 == 0:
		return {"btn": "p"}
	return {}

## Before the sim steps: HP floors, frozen clock, energy for the skill lesson.
func before_tick() -> void:
	_frame += 1
	var sim := fs.sim
	if sim.phase != FightSim.FIGHT:
		return
	if step < 0:
		_begin(0)
	var p: Fighter = sim.f[0]
	var e: Fighter = sim.f[1]
	var pf := FLOOR_FREE if done() else FLOOR_LESSON
	if not p.dead:
		p.hp = maxf(p.hp, p.st.hp_max * pf)
	if done():
		return
	if not e.dead:
		e.hp = maxf(e.hp, e.st.hp_max * FLOOR_LESSON)
	sim.timer = sim.round_frames
	if str(LESSONS[step].id) == "skill":
		var m = p.skills[_skill_slot()] if _skill_slot() < p.skills.size() else null
		if m != null:
			p.en = maxf(p.en, float(m.cost) + 1.0)
		p.cds.erase(_skill_slot())

## After the sim steps: the player's input and the frame's events.
func after_tick(inp: Dictionary) -> void:
	if step < 0 or done():
		return
	var btn := str(inp.get("btn", ""))
	if btn != "":
		_last_btn = btn
		_last_btn_f = _frame
	var l: Dictionary = LESSONS[step]
	var sim := fs.sim
	match str(l.id):
		"move":
			if absf(sim.f[0].x - sim.f[1].x) < 2.0:
				_ok()
				return
		"punch", "kick":
			for e in sim.events:
				if e.t == "hit" and int(e.by) == 0 and (l.id == "punch" or (_last_btn == "k" and _frame - _last_btn_f < 50)):
					_count += 1
			if _count >= int(l.need):
				_ok()
				return
		"block":
			for e in sim.events:
				if e.t == "block" and int(e.i) == 0:
					_count += 1
					fs.fx.text(Vector3(sim.f[0].x, 2.4, 0.3), "Đỡ được!", Color(0.6, 0.85, 1.0))
			if _count >= int(l.need):
				_ok()
				return
		"skill":
			for e in sim.events:
				if e.t == "skill" and int(e.i) == 0:
					_count += 1
			if _count >= int(l.need):
				_ok()
				return

func _process(delta: float) -> void:
	if fs.paused or step < 0 or done():
		return
	_t += delta
	var lim: float = 2.5 if _auto else float(LESSONS[step].max)
	if _t > lim:
		_begin(step + 1)   # never stuck: move on without the cheer
